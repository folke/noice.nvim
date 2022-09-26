---@param view NoiceView
return function(view)
  view._opts.type = "split"
  return require("noice.view.nui")(view)
end
