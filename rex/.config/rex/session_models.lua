local M = {}

local session_models = (os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state")
  .. "/rex/session-models"

function M.load(session_id)
  if not session_id then return end
  local file = io.open(session_models .. "/" .. session_id, "r")
  if not file then return end
  local model = file:read("*l")
  file:close()
  return model
end

function M.prepare()
  local result, err = rex.exec({ "/bin/mkdir", "-p", session_models }, { timeout = 5 })
  if not result then error(err, 0) end
  if not result.ok then error(result.stderr, 0) end
end

function M.save(session_id, model)
  local file = assert(io.open(session_models .. "/" .. session_id, "w"))
  local written, write_err = file:write(model, "\n")
  local closed, close_err = file:close()
  assert(written, write_err)
  assert(closed, close_err)
end

return M
