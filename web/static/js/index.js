var ldr, path;
ldr = new ldresize({
  host: svg2,
  root: svg
});
path = ld$.find(document, 'path');
/*
setInterval (->
  ldr.attach [path.2]
), 5000
*/