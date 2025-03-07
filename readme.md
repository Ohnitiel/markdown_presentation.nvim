# Markdown Presentation in Neovim

This project provides a simple Lua script for presenting Markdown files directly within Neovim using a floating window. It allows you to navigate through slides and steps, making it ideal for presentations or tutorials.

## Features

- **Floating Window**: Displays Markdown content in a floating window.
- **Slide Navigation**: Navigate through slides and steps using keybindings.
- **Customizable**: Configure window size, borders, and separators.

## Requirements
- Neovim (v0.10.0 or higher)

## Installation

### lazy.nvim
```lua
{
  "Ohnitiel/md_presentation.nvim",
}
```

## Usage

### Basic Setup

To use the Markdown presentation script, add the following to your Neovim configuration (`init.lua` or a separate Lua file):

```lua
local md_presentation = require("md_presentation")

-- Optional: Customize the presentation settings
md_presentation.setup({
  win_config = {
    width = 80,
    height = 20,
    border = { " ", " ", " ", " ", " ", " ", " ", " " }
  },
  title_separator = "^# ",
  slide_separator = "^## ",
  step_separator = "\n$"
})

-- Start the presentation with the current buffer
:StartPresentation <optional buffer number>

vim.api.nvim_set_keymap("n", "<leader>mp", md_presentation.start_presentation, { noremap = true, silent = true })
```

### Starting a Presentation
1. Open a Markdown file in Neovim.
2. Use the keybinding you configured (e.g., <leader>mp) to start the presentation.

### Navigation

- Next Step/Slide: Press n to move to the next step or slide.
- Previous Step/Slide: Press p to move to the previous step or slide.
- Quit Presentation: Press q to exit the presentation.

## Customization

You can customize the presentation by passing options to the setup function:

- win_config: Configuration for the floating window.
- title_separator: Lua pattern for separating the title from the content.
- slide_separator: Lua pattern for separating slides.
- step_separator: Lua pattern for separating steps within a slide.

Example:
```lua
md_presentation.setup({
  win_config = {
    width = 100,
    height = 30,
    border = { "=", "=", "=", "=", "=", "=", "=", "=" },
  },
  title_separator = "^# ",
  slide_separator = "^## ",
  step_separator = "\n$"
})
```

## License
This project is released under the [MIT License](https://opensource.org/licenses/MIT).
