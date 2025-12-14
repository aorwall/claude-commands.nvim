# claude-commands.nvim

Use natural language to generate and execute Neovim commands via [Claude Code CLI](https://github.com/anthropics/claude-code).

## Features

- Describe what you want in plain English
- Claude generates the appropriate Neovim command
- Context-aware: sends current file, cursor position, filetype to Claude
- Ex commands (`:vsplit`) go directly to command line for review
- Normal mode commands (`gg=G`) show preview before execution

## Requirements

- Neovim 0.9+
- [Claude Code CLI](https://github.com/anthropics/claude-code) installed and authenticated

## Installation

### lazy.nvim

```lua
{
  "aorwall/claude-commands.nvim",
  config = function()
    require("claude-commands").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "aorwall/claude-commands.nvim",
  config = function()
    require("claude-commands").setup()
  end,
}
```

## Configuration

```lua
require("claude-commands").setup({
  keybind = "<leader>ai",  -- Set to false to disable default keybind
  prompt = "Claude: ",     -- Input prompt text
  timeout_ms = 120000,     -- Timeout for Claude CLI (2 minutes)
})
```

## Usage

1. Press `<leader>ai` (or your configured keybind)
2. Type what you want to do (e.g., "open a vertical split", "delete this line")
3. For Ex commands: review in command line, press Enter to execute
4. For other commands: preview window shows, press Enter to execute or `q` to cancel

### Examples

| Prompt | Generated Command |
|--------|-------------------|
| "open vertical split" | `:vsplit` |
| "show line numbers" | `:set number` |
| "delete this line" | `dd` |
| "indent entire file" | `gg=G` |
| "go to line 50" | `:50` |
| "save and quit" | `:wq` |

## Commands

- `:ClaudeCmd` - Run the Claude command prompt

## License

MIT
