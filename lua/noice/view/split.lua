---@param opts? NoiceViewOptions
return function(opts)
  opts.type = "split"
  return require("noice.view.nui")(opts)
end
