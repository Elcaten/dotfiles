local pick_directory = require("directory_picker")
local opencode = require("opencode")
local session_models = require("session_models")

rex.action{
  name = "new_project_session",
  title = "New Session in Directory…",

  run = function()
    local directory = pick_directory()
    if not directory then return end

    local model = opencode.pick_model()
    if model == nil then return end

    session_models.prepare()

    local normalized_directory = directory:gsub("/+$", "")
    local session_label = normalized_directory:match("([^/]+)$") or "/"
    local session, err = rex.call("session.create", {
      label = session_label,
      initial_windows = {
        { layout = opencode.layout(directory, model) },
      },
    })

    if not session then error(err, 0) end

    session_models.save(session.session_id, model)

    rex.client.queue("session.select", {
      session_id = session.session_id,
    })
  end,
}

rex.action{
  name = "new_opencode_tab",
  title = "New OpenCode Tab",

  run = function(ctx)
    local directory
    if ctx.block_id then
      local terminal = rex.block.call("com.superlogical.terminal", "process", {
        block_id = ctx.block_id,
      })
      directory = terminal and terminal.foreground and terminal.foreground.cwd
    end

    local window, err = rex.session.new_window{
      layout = opencode.layout(directory, session_models.load(ctx.session_id)),
    }
    if not window then error(err, 0) end

    if ctx.client_id and (ctx.origin == "key" or ctx.origin == "palette") then
      -- Give the app time to receive the new tab before selecting it.
      rex.exec({ "/bin/sleep", "0.1" }, { timeout = 1 })
      rex.client.queue("session.select", {
        session_id = ctx.session_id,
        window_id = window.window_id,
      })
    end
    return window
  end,
}

rex.bind("cmd+n", "new_project_session")
rex.bind("cmd+t", "new_opencode_tab")
