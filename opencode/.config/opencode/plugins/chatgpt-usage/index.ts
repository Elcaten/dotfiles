import { Plugin } from "@opencode/plugin"
import { ChatGPTUsage } from "./rpc"
import { UsageMonitor } from "./monitor"

interface SharedMonitor {
  monitor: UsageMonitor
  references: number
}

// Version the shared instance so hot reloads do not keep the old monitor code.
const sharedKey = Symbol.for("dotfiles.opencode.chatgpt-usage.v2")
const globals = globalThis as typeof globalThis & {
  [sharedKey]?: SharedMonitor
}

function acquireMonitor() {
  const shared = globals[sharedKey] ?? {
    monitor: new UsageMonitor(),
    references: 0,
  }
  globals[sharedKey] = shared
  shared.references += 1
  shared.monitor.start()

  return {
    monitor: shared.monitor,
    release() {
      shared.references -= 1
      if (shared.references > 0) return
      shared.monitor.stop()
      delete globals[sharedKey]
    },
  }
}

export default Plugin.define({
  id: "chatgpt-usage",
  async setup(ctx) {
    const shared = acquireMonitor()
    const registration = await ctx.rpc.register(ChatGPTUsage, {
      read: async () => shared.monitor.snapshot(),
      refresh: async () => shared.monitor.refresh(),
    })
    const unsubscribe = shared.monitor.subscribe((state) =>
      registration.events.emit(
        "updated",
        state as unknown as Readonly<Record<string, unknown>>,
      ),
    )

    return async () => {
      unsubscribe()
      await registration.dispose()
      shared.release()
    }
  },
})
