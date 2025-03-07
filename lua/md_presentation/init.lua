local floating_window = require("floating_window")

---@class Presentation
---@field buf_last_line number The last line of the buffer
---@field current_slide number The current slide
---@field has_title number Defines if the presentation has a title
---@field setup fun(opts: present.Options) Function for setting up the plugin
---@field slide_separator string String for separating slides
---@field slides Presentation.Slide[] Presentation slides
---@field start_presentation fun(bufnr: number) Function for starting the presentation
---@field step_separator string String for separating steps
---@field title_separator string String for separating title
---@field update_config fun(opts: present.Options) Function for configuring the plugin
---@field win_config FloatingWindow.opts Configuration for the floating window

---@class Presentation.Slide
---@field body string[] The body of the slide
---@field steps string[] The steps of the slide

---@class present.Options
---@field win_config FloatingWindow.opts Configuration for the floating window
---@field title_separator string A Lua pattern for separating the title from the content. Defaults to `""`
---@field slide_separator string A Lua pattern for separating slides. Defaults to `^#`
---@field step_separator string A Lua pattern for separating steps. Defaults to `\n$`

---@type Presentation
local M = {
    has_title = 0,
    buf_last_line = 0,
}

---@type present.Options
local defaults = {
    win_config = {
        width = vim.o.columns,
        height = vim.o.lines,
        border = { " ", " ", " ", " ", " ", " ", " ", " " },
    },
    title_separator = "",
    slide_separator = "^#",
    step_separator = "",
}

--- Update the configuration
---@param opts present.Options
function M.update_config(opts)
    opts = opts or {}
    M.win_config = opts.win_config or defaults.win_config
    M.title_separator = opts.title_separator or defaults.title_separator
    M.slide_separator = opts.slide_separator or defaults.slide_separator
    M.step_separator = opts.step_separator or defaults.step_separator
end

---Start the presentation
---@param bufnr number The buffer number. Defaults to the current buffer
function M.start_presentation(bufnr)
    local opts = {}
    opts.bufnr = bufnr or 0
    opts.lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)

    ---@type FloatingWindow
    local floating_win = floating_window.create(M.win_config)
    vim.api.nvim_set_option_value(
        "filetype",
        "markdown",
        { buf = floating_win.buf }
    )
    vim.api.nvim_set_option_value("readonly", true, { buf = floating_win.buf })

    local user_opts = {
        cmdheight = vim.o.cmdheight,
    }
    local present_opts = {
        cmdheight = 0,
    }

    local set_slide_content = function(content, new)
        vim.api.nvim_set_option_value(
            "readonly",
            false,
            { buf = floating_win.buf }
        )
        local buf_lines = {}
        if new then
            local title = ""
            local space = M.win_config.width - #content - 2
            for i = 1, space do
                if i == space / 2 then
                    title = title .. " " .. content .. " "
                else
                    title = title .. "-"
                end
            end
            vim.api.nvim_buf_set_lines(
                floating_win.buf,
                0,
                -1,
                false,
                { title }
            )
            M.buf_last_line = 1
        else
            vim.api.nvim_buf_set_lines(
                floating_win.buf,
                M.buf_last_line,
                -1,
                false,
                content
            )
            buf_lines =
                vim.api.nvim_buf_get_lines(floating_win.buf, 0, -1, false)
            if buf_lines then
                M.buf_last_line = #buf_lines
            end
        end
        vim.api.nvim_set_option_value(
            "readonly",
            true,
            { buf = floating_win.buf }
        )
    end

    --- Takes some lines and parses them into slides
    ---@param lines string[]
    ---@return Presentation.Slide[]
    local parse_slides = function(lines)
        local slides = {}
        local current_slide = { steps = { {} } }
        local current_step = 1

        for _, line in ipairs(lines) do
            if
                M.title_separator ~= ""
                and M.title_separator ~= nil
                and line:find(M.title_separator)
            then
                M.has_title = 1
                set_slide_content(line, true)
            elseif line:find(M.slide_separator) then
                current_slide = { steps = { {} } }
                current_step = 1
                table.insert(current_slide.steps[current_step], line)
                table.insert(slides, current_slide)
            elseif line:find(M.step_separator) or M.step_separator == "" then
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

    vim.keymap.set("n", "n", function()
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
            set_slide_content(
                M.slides[current_slide].steps[current_step],
                false
            )
        else
            set_slide_content(
                M.slides[current_slide].steps[current_step],
                false
            )
        end
        vim.cmd("norm G")
        vim.cmd("norm z-")
    end, { buffer = floating_win.buf })
    vim.keymap.set("n", "p", function()
        M.buf_last_line = M.has_title
        current_step = math.max(current_step - 1, 0)
        if current_step == 0 then
            current_step = 1

            if current_slide == 1 then
                set_slide_content(
                    M.slides[current_slide].steps[current_step],
                    false
                )
                return
            end

            current_slide = math.max(current_slide - 1, 1)
            current_step = #M.slides[current_slide].steps
            for _, step in ipairs(M.slides[current_slide].steps) do
                set_slide_content(step, false)
            end
        else
            for i = 1, math.max(current_step, 1) do
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
        end,
    })

    if #M.slides > 0 then
        set_slide_content(M.slides[current_slide].steps[current_step], false)
    else
        vim.api.nvim_win_close(floating_win.win, true)
        print("No slides found in the buffer. Separator: " .. M.slide_separator)
    end
end

---Setup md_presentation
---@param opts present.Options
function M.setup(opts)
    opts = opts or {}
    ---@type Presentation
    local present = require("md_presentation")
    present.update_config(opts)

    vim.api.nvim_create_user_command("StartPresentation", function(args)
        local bufnr = tonumber(args.fargs[1])
        if bufnr == nil then
            bufnr = vim.api.nvim_get_current_buf()
        end
        if vim.api.nvim_buf_is_valid(bufnr) then
            present.start_presentation(bufnr)
        else
            print("Buffer " .. bufnr .. " is invalid")
        end
    end, { desc = "Start md_presentation", nargs = 1 })
end

return M
