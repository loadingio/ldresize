// Generated by LiveScript 1.3.1
var ldr, path, local;
ldr = new ldResize({
  host: svg
});
path = ld$.find(document, 'path', 0);
ldr.attach(path);
local = {};
svg.addEventListener('mousedown', function(e){
  return local.move = false;
});
svg.addEventListener('mousemove', function(e){
  return local.move = true;
});
svg.addEventListener('mouseup', function(e){
  var node;
  node = e.target;
  if (local.move) {
    return;
  }
  if (!node.classList || node.classList.contains('ctrl') || node.nodeName === 'svg') {
    return ldr.detach();
  }
  return ldr.attach(node);
});