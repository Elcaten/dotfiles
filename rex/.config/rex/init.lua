rex.action{
  name = "new_project_session",
  title = "New Session in Directory…",

  run = function()
    local home = os.getenv("HOME")
    local directory = home .. "/src"

    while true do
      local listing, err = rex.exec({
        "/usr/bin/find", "-L", directory,
        "-mindepth", "1", "-maxdepth", "1",
        "-type", "d", "-print0",
      }, { timeout = 5 })

      if not listing then
        error(err, 0)
      end
      if not listing.ok then
        error(listing.stderr, 0)
      end

      local folders = {}
      for path in listing.stdout:gmatch("([^%z]+)%z") do
        folders[#folders + 1] = path
      end
      table.sort(folders)

      local items = {
        {
          id = "select",
          title = "Open session here",
          subtitle = directory,
          icon = "terminal",
        },
        {
          id = "parent",
          title = "Parent directory",
          icon = "folder",
        },
      }

      for _, path in ipairs(folders) do
        if #items >= 2000 then break end
        items[#items + 1] = {
          id = path,
          title = path:match("([^/]+)$"),
          icon = "folder",
        }
      end

      local choice = rex.ui.pick{
        title = directory,
        placeholder = "Filter folders or enter a path",
        items = items,
        allow_other = true,
      }

      if choice == nil then return end

      if choice == "select" then
        break
      elseif choice == "parent" then
        directory = directory:match("^(.*)/[^/]+/?$") or "/"
        if directory == "" then directory = "/" end
      elseif type(choice) == "table" then
        local path = choice.text
        if path == "~" then
          directory = home
        elseif path:sub(1, 2) == "~/" then
          directory = home .. path:sub(2)
        elseif path:sub(1, 1) == "/" then
          directory = path
        elseif path ~= "" then
          directory = directory .. "/" .. path
        end
      else
        directory = choice
      end
    end

    local model = rex.ui.pick{
      title = "Choose a model",
      items = {
        { id = "openai/gpt-6.2-sol", title = "Balanced (Sol)", detail = "Recommended" },
        { id = "openai/gpt-6.1-terra", title = "Easy (Terra)" },
        { id = "openai/gpt-6-luna", title = "Easiest (Luna)" },
        { id = "openai/gpt-6.2-astra", title = "Hard (Astra)" },
      },
    }
    if model == nil then return end

    local normalized_directory = directory:gsub("/+$", "")
    local session_label = normalized_directory:match("([^/]+)$") or "/"
    local opencode = "/opt/local/bin/opencode"
    local provider_id, model_id = model:match("^([^/]+)/(.+)$")

    -- The full-screen TUI takes a session ID, not a model flag.
    local payload = assert(rex.json.encode({
      location = { directory = directory },
      model = { providerID = provider_id, id = model_id },
    }))
    local created, create_err = rex.exec({
      opencode, "api", "post", "/api/session", "--data", payload,
    }, { cwd = directory, timeout = 15 })
    if not created then error(create_err, 0) end
    if not created.ok then
      local message = created.stderr ~= "" and created.stderr or created.stdout
      error(message ~= "" and message or "Could not create the OpenCode session", 0)
    end

    local response = rex.json.decode(created.stdout)
    local opencode_session_id = response and response.data and response.data.id
    if type(opencode_session_id) ~= "string" then
      error("OpenCode did not return a session ID", 0)
    end

    local session, err = rex.call("session.create", {
      label = session_label,
      initial_windows = {
        {
          layout = rex.layout.block{
            flavor = "com.superlogical.terminal.shell",
            options = {
              cwd = directory,
              command = { opencode, "--session", opencode_session_id },
              shell = "none",
            },
          },
        },
      },
    })

    if not session then error(err, 0) end

    rex.client.queue("session.select", {
      session_id = session.session_id,
    })
  end,
}

rex.bind("cmd+n", "new_project_session")
