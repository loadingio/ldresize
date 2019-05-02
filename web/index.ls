ldr = new ldResize {host: svg}
path = ld$.find document, 'path', 0
ldr.attach path

local = {}
svg.addEventListener \mousedown, (e) ->
  local.move = false
svg.addEventListener \mousemove, (e) ->
  local.move = true
svg.addEventListener \mouseup, (e) ->
  node = e.target
  if local.move => return
  if !node.classList or node.classList.contains \ctrl or node.nodeName == \svg => return ldr.detach!
  ldr.attach node
