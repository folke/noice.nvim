---@param opts? NoiceViewOptions
return function(opts)
  opts.type = "popup"
  return require("noice.view.nui")(opts)
end
