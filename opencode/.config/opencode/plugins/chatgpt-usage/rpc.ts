import { Rpc } from "@opencode/plugin/rpc"

const windowSchema = {
  type: "object",
  properties: {
    usedPercent: { type: "number" },
    windowDurationMins: { type: "number" },
    resetsAt: {
      anyOf: [{ type: "number" }, { type: "null" }],
    },
  },
  required: ["usedPercent", "windowDurationMins", "resetsAt"],
  additionalProperties: false,
} as const

const limitSchema = {
  type: "object",
  properties: {
    id: { type: "string" },
    name: {
      anyOf: [{ type: "string" }, { type: "null" }],
    },
    primary: {
      anyOf: [windowSchema, { type: "null" }],
    },
    secondary: {
      anyOf: [windowSchema, { type: "null" }],
    },
  },
  required: ["id", "name", "primary", "secondary"],
  additionalProperties: false,
} as const

const stateSchema = {
  type: "object",
  properties: {
    status: {
      type: "string",
      enum: ["loading", "ready", "error"],
    },
    updatedAt: {
      anyOf: [{ type: "number" }, { type: "null" }],
    },
    planType: {
      anyOf: [{ type: "string" }, { type: "null" }],
    },
    limits: {
      type: "array",
      items: limitSchema,
    },
    error: {
      anyOf: [{ type: "string" }, { type: "null" }],
    },
  },
  required: ["status", "updatedAt", "planType", "limits", "error"],
  additionalProperties: false,
} as const

const emptySchema = {
  type: "object",
  properties: {},
  additionalProperties: false,
} as const

export interface UsageWindow {
  usedPercent: number
  windowDurationMins: number
  resetsAt: number | null
}

export interface UsageLimit {
  id: string
  name: string | null
  primary: UsageWindow | null
  secondary: UsageWindow | null
}

export interface UsageState {
  status: "loading" | "ready" | "error"
  updatedAt: number | null
  planType: string | null
  limits: UsageLimit[]
  error: string | null
}

export const ChatGPTUsage = Rpc.define({
  id: "chatgpt-usage",
  methods: {
    read: {
      input: emptySchema,
      output: stateSchema,
    },
    refresh: {
      input: emptySchema,
      output: stateSchema,
    },
  },
  events: {
    updated: {
      schema: stateSchema,
    },
  },
} satisfies Rpc.PortableDefinition)
