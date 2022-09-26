---@param view NoiceView
return function(view)
  view.opts.type = "popup"
  return require("noice.render.nui")(view)
end
