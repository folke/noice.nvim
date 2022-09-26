---@param view NoiceView
return function(view)
  view.opts.type = "popup"
  require("noice.render.nui")(view)
end
