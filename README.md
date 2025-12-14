# claude-commands.nvim

Neovim commands for the lazy - just describe what you want.

![Demo](demo.gif)

## How it works

1. Press `<leader>ai`
2. Type what you want: `"delete this line"`
3. Claude generates: `:d`

| You type | Neovim executes |
|----------|-----------------|
| "open vertical split" | `:vsplit` |
| "show line numbers" | `:set number` |
| "delete this line" | `:d` |
| "go to line 50" | `:50` |
| "save and quit" | `:wq` |
| "find foo" | `:/foo` |

Ex commands go to the command line for review. Other commands show a preview window.

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
  keybind = "<leader>ai",              -- Set to false to disable default keybind
  prompt = "Claude: ",                 -- Input prompt text
  timeout_ms = 120000,                 -- Timeout for Claude CLI (2 minutes)
  model = "claude-haiku-4-5-20251001", -- Claude model to use
})
```

## License

MIT
