# VHS Demo for claude-commands.nvim
Output demo.gif

Set FontSize 16
Set Width 900
Set Height 600
Set Theme "Dracula"

# Open the README
Type "nvim README.md"
Enter
Sleep 2s

# Go to the "delete this line" line
Type ":15"
Enter
Sleep 1s

# Use the plugin to delete this line
Type " ai"
Sleep 500ms

Type "delete this line"
Enter

# Wait for Claude to respond
Sleep 10s

# Execute the command (press Enter for :d or dd)
Enter
Sleep 2s

# Show the result
Sleep 2s
