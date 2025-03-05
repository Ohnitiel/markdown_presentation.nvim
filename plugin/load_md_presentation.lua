vim.api.nvim_create_user_command("MDStartPresentation", function()
  package.loaded["md_presentation"] = nil
  require("md_presentation").start_presentation({})
end, {})
