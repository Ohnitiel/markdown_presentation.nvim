local floating_window = require("floating_window")

---@class present
---@field slides present.Slide[]: Presentation slides
---@field title string: Presentation title
---@field current_slide number: The current slide
---@field buf_last_line number: The last line of the buffer
---@field win_config {}: Configuration for the floating window
---@field title_separator string: String for separating title
---@field slide_separator string: String for separating slides
---@field step_separator string: String for separating steps
---@field setup function: Function for setting up the presentation
---@field start_presentation function: Function for starting the presentation
---@field has_title number: Defines if the presentation has a title

---@class present.FloatingWindow
---@field buf number: Buffer number
---@field win number: Window number

---@class present.Slide
---@field body string[]: The body of the slide
---@field steps string[]: The steps of the slide

---@class present.Options
---@field win_config vim.api.keyset.win_config: Configuration for the floating window
---@field width integer: Width of the floating window, overrides `win_config.width`. Defaults to `vim.o.columns`
---@field height integer: Height of the floating window, overrides `win_config.height`. Defaults to `vim.o.lines`
---@field border string[]: Border for the floating window, overrides `win_config.border`. Defaults to 8 blank spaces
---@field title_separator string: A Lua pattern for separating the title from the content. Defaults to `""`
---@field slide_separator string: A Lua pattern for separating slides. Defaults to `^#`
---@field step_separator string: A Lua pattern for separating steps. Defaults to `\n$`


---@type present
local M = {
  has_title = 0,
  buf_last_line = 0
}

local defaults = {
  ---@type vim.api.keyset.win_config
  win_config ={
    width = vim.o.columns,
    height = vim.o.lines,
    border = { " ", " ",  " ",  " ",  " ",  " ",  " ",  " ",  }
  }
}

--- Setup the plugin
---@param opts present.Options
function M.setup(opts)
  opts = opts or {}
  M.win_config = opts.win_config or defaults.win_config
  M.win_config.width = opts.width or M.win_config.width
  M.win_config.height = opts.height or M.win_config.height
  M.win_config.border = opts.border or M.win_config.border
  M.title_separator = opts.title_separator or ""
  M.slide_separator = opts.slide_separator or "^#"
  M.step_separator = opts.step_separator or "\n$"
end

function M.start_presentation (opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0
  opts.lines = opts.lines or vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)

  local floating_win = floating_window.create(M.win_config)
  vim.api.nvim_set_option_value('filetype', 'markdown', {buf = floating_win.buf})
  vim.api.nvim_set_option_value("readonly", true, {buf = floating_win.buf})

  local user_opts = {
    cmdheight = vim.o.cmdheight
  }
  local present_opts = {
    cmdheight = 0
  }

  local set_slide_content = function (content, new)
    vim.api.nvim_set_option_value("readonly", false, {buf = floating_win.buf})
    local buf_lines = {}
    if new then
      local title = ""
      local space = M.win_config.width - #content - 2
      for i=1, space do
        if i == space / 2 then
          title = title .. " " .. content .. " "
        else
          title = title .. "-"
        end
      end
      vim.api.nvim_buf_set_lines(floating_win.buf, 0, -1, false, {title})
      M.buf_last_line = 1
    else
      vim.api.nvim_buf_set_lines(floating_win.buf, M.buf_last_line, -1, false, content)
      buf_lines = vim.api.nvim_buf_get_lines(floating_win.buf, 0, -1, false)
      if buf_lines then
        M.buf_last_line = #buf_lines
      end
    end
    vim.api.nvim_set_option_value("readonly", true, {buf = floating_win.buf})
  end

  --- Takes some lines and parses them into slides
  ---@param lines string[]
  ---@return present.Slide[]
  local parse_slides = function (lines)
    local slides = {}
    local current_slide = { steps = {{}} }
    local current_step = 1

    for _, line in ipairs(lines) do
      if M.title_separator ~= "" and M.title_separator ~= nil and line:find(M.title_separator) then
          M.has_title = 1
          set_slide_content(line, true)
      elseif line:find(M.slide_separator) then
        current_slide = { steps = {{}} }
        current_step = 1
        table.insert(current_slide.steps[current_step], line)
        table.insert(slides, current_slide)
      elseif line:find(M.step_separator) then
        current_step = current_step + 1
        current_slide.steps[current_step] = {}
        line = string.gsub(line, M.step_separator, "")
        table.insert(current_slide.steps[current_step], line)
      else
        table.insert(current_slide.steps[current_step], line)
      end
    end

    return slides
  end

  for option, value in pairs(present_opts) do
    vim.opt[option] = value
  end

  M.slides = parse_slides(opts.lines)
  local current_slide = 1
  local current_step = 1

  vim.keymap.set("n", "n", function ()
    current_step = current_step + 1
    if current_step > #M.slides[current_slide].steps then
      current_slide = current_slide + 1
      if current_slide > #M.slides then
        current_slide = #M.slides
        current_step = #M.slides[current_slide].steps
        return
      end

      M.buf_last_line = M.has_title
      current_step = 1
      set_slide_content(M.slides[current_slide].steps[current_step], false)
    else
      set_slide_content(M.slides[current_slide].steps[current_step], false)
    end
    vim.cmd("norm G")
    vim.cmd("norm z-")
  end, { buffer = floating_win.buf })
  vim.keymap.set("n", "p", function ()
    M.buf_last_line = M.has_title
    current_step = math.max(current_step - 1, 0)
    if current_step == 0 then
      current_step = 1

      if current_slide == 1 then
        set_slide_content(M.slides[current_slide].steps[current_step], false)
        return
      end

      current_slide = math.max(current_slide - 1, 1)
      current_step = #M.slides[current_slide].steps
      for _, step in ipairs(M.slides[current_slide].steps) do
        set_slide_content(step, false)
      end
    else
      for i=1, math.max(current_step, 1) do
        set_slide_content(M.slides[current_slide].steps[i], false)
      end
    end
    vim.cmd("norm G")
    vim.cmd("norm z-")
  end, { buffer = floating_win.buf })
  vim.keymap.set("n", "q", vim.cmd.quit, { buffer = floating_win.buf })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = floating_win.buf,
    callback = function()
      for option, value in pairs(user_opts) do
        vim.opt[option] = value
      end
    end
  })

  set_slide_content(M.slides[current_slide].steps[current_step], false)
end

return M
