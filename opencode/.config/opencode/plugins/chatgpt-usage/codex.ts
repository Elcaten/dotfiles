import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process"
import { constants, accessSync } from "node:fs"
import { delimiter, dirname, join } from "node:path"

interface PendingRequest {
  resolve(value: unknown): void
  reject(error: Error): void
  timer: ReturnType<typeof setTimeout>
}

interface RpcResponse {
  id?: number
  result?: unknown
  error?: {
    code?: number
    message?: string
  }
}

export class CodexAppServer {
  private child: ChildProcessWithoutNullStreams | undefined
  private starting: Promise<void> | undefined
  private nextID = 1
  private pending = new Map<number, PendingRequest>()
  private stdoutBuffer = ""
  private stderrBuffer = ""

  async request<T>(method: string, params: object = {}): Promise<T> {
    await this.start()
    return this.send<T>(method, params)
  }

  stop() {
    const error = new Error("Codex app-server stopped")
    this.rejectPending(error)
    this.starting = undefined
    this.stdoutBuffer = ""
    this.stderrBuffer = ""

    if (this.child) {
      this.child.removeAllListeners()
      this.child.stdout.removeAllListeners()
      this.child.stderr.removeAllListeners()
      this.child.kill()
      this.child = undefined
    }
  }

  private async start() {
    if (this.child && !this.child.killed && this.starting) {
      return this.starting
    }

    this.starting = this.startInner().catch((error) => {
      this.stop()
      throw error
    })
    return this.starting
  }

  private async startInner() {
    const binary = findCodexBinary()
    const path = [
      dirname(binary),
      dirname(process.execPath),
      process.env.PATH,
    ]
      .filter(Boolean)
      .join(delimiter)
    const child = spawn(binary, ["app-server"], {
      stdio: ["pipe", "pipe", "pipe"],
      env: {
        ...process.env,
        PATH: path,
      },
    })
    this.child = child

    child.stdout.setEncoding("utf8")
    child.stderr.setEncoding("utf8")

    child.stdout.on("data", (chunk: string) => this.consumeStdout(chunk))
    child.stderr.on("data", (chunk: string) => {
      this.stderrBuffer = `${this.stderrBuffer}${chunk}`.slice(-4_096)
    })
    child.on("error", (error) => this.handleExit(error))
    child.on("exit", (code, signal) => {
      const detail = this.stderrBuffer.trim()
      const suffix = detail ? `: ${detail}` : ""
      this.handleExit(
        new Error(`Codex app-server exited (${signal ?? code ?? "unknown"})${suffix}`),
      )
    })

    await this.send("initialize", {
      clientInfo: {
        name: "opencode_chatgpt_usage",
        title: "OpenCode ChatGPT Usage",
        version: "0.1.0",
      },
    })
    this.notify("initialized", {})
  }

  private send<T>(method: string, params: object): Promise<T> {
    const child = this.child
    if (!child || child.killed) {
      return Promise.reject(new Error("Codex app-server is not running"))
    }

    const id = this.nextID++
    return new Promise<T>((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id)
        reject(new Error(`Codex app-server request timed out: ${method}`))
      }, 15_000)

      this.pending.set(id, {
        resolve: resolve as (value: unknown) => void,
        reject,
        timer,
      })
      child.stdin.write(`${JSON.stringify({ method, id, params })}\n`)
    })
  }

  private notify(method: string, params: object) {
    const child = this.child
    if (!child || child.killed) return
    child.stdin.write(`${JSON.stringify({ method, params })}\n`)
  }

  private consumeStdout(chunk: string) {
    this.stdoutBuffer += chunk

    while (true) {
      const newline = this.stdoutBuffer.indexOf("\n")
      if (newline < 0) return

      const line = this.stdoutBuffer.slice(0, newline).trim()
      this.stdoutBuffer = this.stdoutBuffer.slice(newline + 1)
      if (!line) continue

      let message: RpcResponse
      try {
        message = JSON.parse(line) as RpcResponse
      } catch {
        continue
      }

      if (typeof message.id !== "number") continue
      const pending = this.pending.get(message.id)
      if (!pending) continue

      clearTimeout(pending.timer)
      this.pending.delete(message.id)

      if (message.error) {
        pending.reject(
          new Error(
            message.error.message ??
              `Codex app-server error ${message.error.code ?? "unknown"}`,
          ),
        )
      } else {
        pending.resolve(message.result)
      }
    }
  }

  private handleExit(error: Error) {
    this.rejectPending(error)
    this.child = undefined
    this.starting = undefined
  }

  private rejectPending(error: Error) {
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timer)
      pending.reject(error)
    }
    this.pending.clear()
  }
}

function findCodexBinary() {
  if (process.env.CODEX_BIN) return process.env.CODEX_BIN

  const home = process.env.HOME
  const candidates = [
    ...(process.env.PATH ?? "")
      .split(delimiter)
      .filter(Boolean)
      .map((directory) => join(directory, "codex")),
    "/opt/local/bin/codex",
    "/opt/homebrew/bin/codex",
    "/usr/local/bin/codex",
    ...(home ? [join(home, ".local", "bin", "codex")] : []),
  ]

  for (const candidate of new Set(candidates)) {
    try {
      accessSync(candidate, constants.X_OK)
      return candidate
    } catch {
      // Try the next common installation location.
    }
  }

  return "codex"
}
