---@param view NoiceView
return function(view)
  view._opts.type = "popup"
  return require("noice.render.nui")(view)
end
