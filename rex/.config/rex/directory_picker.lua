return function()
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
      return directory
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
end
