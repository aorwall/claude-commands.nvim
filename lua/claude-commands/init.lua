local M = {}

M.config = {
  keybind = "<leader>ai",
  prompt = "Claude: ",
  timeout_ms = 120000,
}

local system_prompt = [[You are a Neovim command generator. Respond with ONLY a valid Neovim command, no explanation, no markdown formatting, no code blocks.

ALWAYS prefer Ex commands (starting with :) when possible. Only use normal mode commands when there is no Ex command equivalent.

Examples:
- Delete line: :d (not dd)
- Go to line 50: :50 (not 50G)
- Save: :w
- Quit: :q
- Search: :/pattern
- Substitute: :s/old/new/g

Respond with exactly one command, nothing else.]]

local function get_context()
  local ctx = {}
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  ctx.file = filepath ~= "" and filepath or "[No file]"
  ctx.filename = filepath ~= "" and vim.fn.fnamemodify(filepath, ":t") or "[No file]"
  ctx.filetype = vim.bo[bufnr].filetype ~= "" and vim.bo[bufnr].filetype or "none"

  local cursor = vim.api.nvim_win_get_cursor(0)
  ctx.line = cursor[1]
  ctx.col = cursor[2] + 1
  ctx.total_lines = vim.api.nvim_buf_line_count(bufnr)
  ctx.current_line_text = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1] or ""

  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")
    ctx.visual_start = { start_pos[2], start_pos[3] }
    ctx.visual_end = { end_pos[2], end_pos[3] }
  end

  local git_branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
  if git_branch ~= "" then
    ctx.git_branch = git_branch
  end

  return ctx
end

local function format_context(ctx)
  local lines = {
    "Current context:",
    "- File: " .. ctx.file,
    "- Filetype: " .. ctx.filetype,
    "- Cursor: line " .. ctx.line .. ", col " .. ctx.col,
    "- Total lines: " .. ctx.total_lines,
    "- Current line: " .. ctx.current_line_text,
  }
  if ctx.visual_start then
    table.insert(lines, "- Visual selection: from line " .. ctx.visual_start[1] .. " to line " .. ctx.visual_end[1])
  end
  if ctx.git_branch then
    table.insert(lines, "- Git branch: " .. ctx.git_branch)
  end
  return table.concat(lines, "\n")
end

local function get_user_prompt(callback)
  vim.ui.input({ prompt = M.config.prompt }, function(input)
    if input and input ~= "" then
      callback(input)
    end
  end)
end

local function check_claude_cli()
  vim.fn.system("which claude")
  return vim.v.shell_error == 0
end

local function show_loading()
  vim.api.nvim_echo({{"Asking Claude...", "Comment"}}, false, {})
  return {
    close = function()
      vim.api.nvim_echo({{"", ""}}, false, {})
    end
  }
end

local function shell_escape(str)
  return "'" .. str:gsub("'", "'\\''") .. "'"
end

local function call_claude(user_prompt, context, on_success, on_error)
  if not check_claude_cli() then
    on_error("Claude CLI not found. Install from: https://github.com/anthropics/claude-code")
    return
  end

  local full_prompt = format_context(context) .. "\n\nUser request: " .. user_prompt

  local cmd = string.format(
    'claude -p --tools "" --system-prompt %s %s < /dev/null',
    shell_escape(system_prompt),
    shell_escape(full_prompt)
  )

  local output = {}
  local stderr_output = {}
  local job_done = false

  local job_id = vim.fn.jobstart(cmd, {
    shell = true,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_output, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      job_done = true
      vim.schedule(function()
        if exit_code == 0 then
          if #output > 0 then
            local result = table.concat(output, "\n")
            result = result:gsub("^```[%w]*\n?", ""):gsub("\n?```$", "")
            result = result:gsub("^`", ""):gsub("`$", "")
            result = vim.trim(result)
            if result ~= "" then
              on_success(result)
            else
              on_error("Claude returned empty response")
            end
          else
            on_error("Claude returned no output")
          end
        else
          local err_msg = #stderr_output > 0 and table.concat(stderr_output, "\n") or ("Exit code: " .. exit_code)
          on_error("Claude CLI failed: " .. err_msg)
        end
      end)
    end,
  })

  if job_id <= 0 then
    on_error("Failed to start Claude CLI")
    return
  end

  vim.defer_fn(function()
    if not job_done then
      vim.fn.jobstop(job_id)
    end
  end, M.config.timeout_ms)
end

local function show_preview(user_prompt, generated_cmd, context, on_execute, on_cancel)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.min(90, math.floor(vim.o.columns * 0.8))
  local height = 11

  local separator = string.rep("-", width - 4)
  local lines = {
    " Prompt: " .. user_prompt,
    "",
    " Context:",
    "   File: " .. context.filename .. " (" .. context.filetype .. ")",
    "   Cursor: line " .. context.line .. "/" .. context.total_lines,
    "",
    " Generated command:",
    "   " .. generated_cmd,
    "",
    " " .. separator,
    " [Enter] Execute  |  [q/Esc] Cancel",
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Claude Command Preview ",
    title_pos = "center",
  })

  local function close_and_execute()
    vim.api.nvim_win_close(win, true)
    on_execute()
  end

  local function close_and_cancel()
    vim.api.nvim_win_close(win, true)
    on_cancel()
  end

  vim.keymap.set("n", "<CR>", close_and_execute, { buffer = buf, silent = true })
  vim.keymap.set("n", "q", close_and_cancel, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close_and_cancel, { buffer = buf, silent = true })
end

local function execute_command(cmd)
  if cmd:match("^:") then
    vim.api.nvim_feedkeys(cmd, "n", false)
  else
    local ok, err = pcall(function()
      if cmd:match("^lua ") then
        loadstring(cmd:gsub("^lua%s+", ""))()
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), "n", false)
      end
    end)
    if not ok then
      vim.notify("Command failed: " .. tostring(err), vim.log.levels.ERROR)
    else
      vim.notify("Executed: " .. cmd, vim.log.levels.INFO)
    end
  end
end

function M.run()
  local context = get_context()

  get_user_prompt(function(user_prompt)
    local loading = show_loading()

    call_claude(
      user_prompt,
      context,
      function(generated_cmd)
        loading.close()
        if generated_cmd:match("^:") then
          execute_command(generated_cmd)
        else
          show_preview(
            user_prompt,
            generated_cmd,
            context,
            function() execute_command(generated_cmd) end,
            function() vim.notify("Cancelled", vim.log.levels.INFO) end
          )
        end
      end,
      function(error_msg)
        loading.close()
        vim.notify(error_msg, vim.log.levels.ERROR)
      end
    )
  end)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  if M.config.keybind then
    vim.keymap.set("n", M.config.keybind, M.run, { desc = "Ask Claude for command" })
  end
end

return M
