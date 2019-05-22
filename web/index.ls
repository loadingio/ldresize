ldr = new ldResize {host: svg2, root: svg}

path = ld$.find document, 'path'
#ldr.attach [path.6, path.0]
#ldr.attach [path.2], true
/*
setInterval (->
  ldr.attach [path.2]
), 5000
*/
