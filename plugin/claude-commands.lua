if vim.g.loaded_claude_commands then
  return
end
vim.g.loaded_claude_commands = true

vim.api.nvim_create_user_command("ClaudeCmd", function()
  require("claude-commands").run()
end, { desc = "Ask Claude to generate a Neovim command" })
