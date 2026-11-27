local M = {}

function M.layout(directory, model)
  local command = {
    "/usr/bin/env",
    "OPENTUI_NOTIFICATION_PROTOCOL=osc777",
    "/opt/local/bin/opencode",
    "--standalone",
  }
  if model then
    local config = assert(rex.json.encode({ model = model }))
    table.insert(command, 2, "OPENCODE_CONFIG_CONTENT=" .. config)
  end

  return rex.layout.block{
    flavor = "com.superlogical.terminal.shell",
    options = {
      cwd = directory,
      command = command,
      shell = "none",
    },
  }
end

function M.pick_model()
  return rex.ui.pick{
    title = "Choose a model",
    items = {
      { id = "openai/gpt-6.2-sol", title = "Balanced (Sol)", detail = "Recommended" },
      { id = "openai/gpt-6.1-terra", title = "Easy (Terra)" },
      { id = "openai/gpt-6-luna", title = "Easiest (Luna)" },
      { id = "openai/gpt-6.2-astra", title = "Hard (Astra)" },
    },
  }
end

return M
