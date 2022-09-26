---@param view NoiceView
return function(view)
  view.opts.type = "split"
  require("noice.render.nui")(view)
end
