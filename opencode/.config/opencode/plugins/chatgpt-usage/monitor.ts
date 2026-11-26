import { CodexAppServer } from "./codex"
import type { UsageLimit, UsageState, UsageWindow } from "./rpc"

type Listener = (state: UsageState) => void | Promise<void>

interface AccountResponse {
  account?: {
    type?: string
    planType?: string | null
  } | null
}

interface RawWindow {
  usedPercent?: number
  windowDurationMins?: number
  resetsAt?: number | null
}

interface RawLimit {
  limitId?: string
  limitName?: string | null
  primary?: RawWindow | null
  secondary?: RawWindow | null
}

interface RateLimitsResponse {
  rateLimits?: RawLimit | null
  rateLimitsByLimitId?: Record<string, RawLimit> | null
}

export class UsageMonitor {
  private readonly client = new CodexAppServer()
  private readonly listeners = new Set<Listener>()
  private timer: ReturnType<typeof setInterval> | undefined
  private refreshing: Promise<UsageState> | undefined
  private state: UsageState = {
    status: "loading",
    updatedAt: null,
    planType: null,
    limits: [],
    error: null,
  }

  start() {
    if (this.timer) return
    void this.refresh()
    this.timer = setInterval(() => void this.refresh(), 60_000)
  }

  stop() {
    if (this.timer) clearInterval(this.timer)
    this.timer = undefined
    this.client.stop()
  }

  snapshot() {
    return this.state
  }

  subscribe(listener: Listener) {
    this.listeners.add(listener)
    return () => this.listeners.delete(listener)
  }

  refresh(): Promise<UsageState> {
    if (this.refreshing) return this.refreshing

    this.refreshing = this.refreshInner().finally(() => {
      this.refreshing = undefined
    })
    return this.refreshing
  }

  private readUsage() {
    return Promise.all([
      this.client.request<AccountResponse>("account/read", {
        refreshToken: false,
      }),
      this.client.request<RateLimitsResponse>("account/rateLimits/read"),
    ])
  }

  private async refreshInner() {
    try {
      const [account, response] = await this.readUsage().catch((error: unknown) => {
        if (!(error instanceof Error) || !/\btoken_revoked\b/.test(error.message)) {
          throw error
        }

        // A long-lived app-server can retain credentials that another Codex
        // process has since refreshed. Restart it to load the current login.
        this.client.stop()
        return this.readUsage()
      })

      const rawLimits = response.rateLimitsByLimitId
        ? Object.entries(response.rateLimitsByLimitId)
        : response.rateLimits
          ? [[response.rateLimits.limitId ?? "codex", response.rateLimits] as const]
          : []

      this.state = {
        status: "ready",
        updatedAt: Date.now(),
        planType: account.account?.planType ?? null,
        limits: rawLimits.map(([id, limit]) => normalizeLimit(id, limit)),
        error: null,
      }
    } catch (error) {
      this.state = {
        ...this.state,
        status: "error",
        updatedAt: Date.now(),
        error: error instanceof Error ? error.message : String(error),
      }
    }

    await Promise.allSettled(
      [...this.listeners].map((listener) => listener(this.state)),
    )
    return this.state
  }
}

function normalizeLimit(id: string, limit: RawLimit): UsageLimit {
  return {
    id: limit.limitId ?? id,
    name: limit.limitName ?? null,
    primary: normalizeWindow(limit.primary),
    secondary: normalizeWindow(limit.secondary),
  }
}

function normalizeWindow(window: RawWindow | null | undefined): UsageWindow | null {
  if (
    !window ||
    typeof window.usedPercent !== "number" ||
    typeof window.windowDurationMins !== "number"
  ) {
    return null
  }

  return {
    usedPercent: window.usedPercent,
    windowDurationMins: window.windowDurationMins,
    resetsAt: typeof window.resetsAt === "number" ? window.resetsAt : null,
  }
}
