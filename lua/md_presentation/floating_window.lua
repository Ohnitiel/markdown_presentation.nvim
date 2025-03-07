---@class FloatingWindow
---@field buf number Buffer number
---@field win number Window number
local M = {}

---@class FloatingWindow.opts
---@field border any: Border for the floating window
---@field width number: Width of the floating window
---@field height number: Height of the floating window

---Create a floating window
---@param opts ?FloatingWindow.opts: Configuration for the floating window
---@param bufnr ?number: Buffer number
---@return FloatingWindow {buf: number, win: number}: The buffer and window numbers
function M.create(opts, bufnr)
    ---@type number
    local buf

    opts = opts or {}

    opts.border = opts.border or "rounded"
    opts.width = opts.width or math.floor(vim.o.columns * 0.7)
    opts.height = opts.height or math.floor(vim.o.lines * 0.7)

    bufnr = bufnr or -1

    local col = math.floor((vim.o.columns - opts.width) / 2)
    local row = math.floor((vim.o.lines - opts.height) / 2)
    local win_config = {
        relative = "editor",
        style = "minimal",
        border = opts.border,
        width = opts.width,
        height = opts.height,
        row = row,
        col = col,
    }

    if bufnr == -1 then
        buf = vim.api.nvim_create_buf(false, true)
    else
        if vim.api.nvim_buf_is_valid(bufnr) then
            buf = bufnr
        else
            buf = vim.api.nvim_create_buf(false, true)
        end
    end

    local win = vim.api.nvim_open_win(buf, true, win_config)

    return { buf = buf, win = win }
end

return M
