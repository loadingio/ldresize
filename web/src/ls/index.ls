ldr = new ldResize {host: svg2, root: svg}
ldr2 = new ldResize {host: svg4}
ldr2.attach svg3.childNodes.0

path = ld$.find document, 'path'
#ldr.attach [path.6, path.0]
#ldr.attach [path.2], true
/*
setInterval (->
  ldr.attach [path.2]
), 5000
*/
