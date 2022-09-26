---@param view NoiceView
return function(view)
  view.opts.type = "split"
  return require("noice.render.nui")(view)
end
