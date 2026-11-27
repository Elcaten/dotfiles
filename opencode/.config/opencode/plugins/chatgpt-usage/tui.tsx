import { Plugin } from "@opencode/plugin/tui"
import { createSignal } from "solid-js"
import { ChatGPTUsage, type UsageState } from "./rpc"

const initialState: UsageState = {
  status: "loading",
  updatedAt: null,
  planType: null,
  limits: [],
  error: null,
}

export default Plugin.define({
  id: "chatgpt-usage-tui",
  async setup(context) {
    const usage = context.client.rpc(ChatGPTUsage)
    const [state, setState] = createSignal<UsageState>(initialState)
    const unsubscribe = usage.events.on("updated", (event) => {
      setState(event.data as unknown as UsageState)
    })

    try {
      setState((await usage.read({})) as unknown as UsageState)
    } catch (error) {
      setState({
        ...initialState,
        status: "error",
        updatedAt: Date.now(),
        error: error instanceof Error ? error.message : String(error),
      })
    }

    const render = () => (
      <text fg={context.theme.text.base}>{formatState(state())}</text>
    )
    const removeHome = context.ui.slot({
      append: "home.footer.status",
      render,
    })
    const removePrompt = context.ui.slot({
      append: "prompt.footer.status",
      render,
    })

    context.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "chatgpt-usage.refresh",
          title: "Refresh ChatGPT usage",
          group: "ChatGPT",
          palette: true,
          slash: { name: "usage-refresh" },
          run: async () => {
            setState((await usage.refresh({})) as unknown as UsageState)
          },
        },
      ],
    }))

    return () => {
      unsubscribe()
      removeHome()
      removePrompt()
    }
  },
})

function formatState(state: UsageState) {
  if (state.status === "loading") return "00% left  ↻XXX"
  if (state.status === "error" && state.limits.length === 0) {
    return "ChatGPT usage unavailable"
  }

  const limit =
    state.limits.find((candidate) => candidate.id === "codex") ?? state.limits[0]
  const windows = [limit?.primary, limit?.secondary].filter(
    (window) => window != null,
  )
  const weekly =
    windows.find((window) => window.windowDurationMins === 10_080) ??
    windows.slice().sort(
      (left, right) => right.windowDurationMins - left.windowDurationMins,
    )[0]

  if (!weekly) return "ChatGPT usage unavailable"

  const left = Math.max(0, Math.min(100, 100 - weekly.usedPercent))
  const reset = formatResetDay(weekly.resetsAt)
  const display = `${Math.round(left)}% left${reset ? ` ↻${reset}` : ""}`
  return state.status === "error" ? `${display} !` : display
}

function formatResetDay(timestamp: number | null) {
  if (timestamp === null) return null

  const reset = new Date(timestamp * 1_000)
  if (Number.isNaN(reset.getTime())) return null

  return new Intl.DateTimeFormat(undefined, {
    weekday: "short",
  }).format(reset)
}
