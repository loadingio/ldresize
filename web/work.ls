ldResize = ->


path = ld$.find(document, 'path', 5)
svg = ld$.find(document, 'svg', 0)

_ = (n) ->
  if !n or n.nodeName.toLowerCase! == \svg => return svg.createSVGMatrix!
  mat = if n.transform.baseVal.consolidate! => that.matrix else svg.createSVGMatrix!
  ret = _(n.parentNode)
  return ret.multiply(mat)

ret = _ path #.parentNode
rret = _ path.parentNode
console.log ret

clone = path.cloneNode true
clone.setAttribute \transform, ''
svg.appendChild clone
rbox = svg.getBoundingClientRect!
box = clone.getBoundingClientRect!
box.x -= rbox.x
box.y -= rbox.y

rect = ld$.create do
  name: \rect, ns: \svg
  attr: do
    x: box.x, y: box.y, width: box.width, height: box.height
  style: opacity: 0.2

rect.transform.baseVal.initialize(svg.createSVGTransformFromMatrix(rret))
svg.appendChild rect
rect.transform.baseVal.consolidate!
path.transform.baseVal.consolidate!

t = path.transform.baseVal.consolidate!
rect.transform.baseVal.insertItemBefore(t, 1)


t = svg.createSVGTransform!
rect.transform.baseVal.insertItemBefore(t, 1)
t2 = svg.createSVGTransform!
path.transform.baseVal.insertItemBefore(t2, 0)


dim = do
  t: x: 0, y: 0
  s: x: 0, y: 0
  r: 0

box = rect.getBoundingClientRect!
box.x -= rbox.x
box.y -= rbox.y
box2 = path.getBoundingClientRect!
box2.x -= rbox.x
box2.y -= rbox.y
p = svg.createSVGPoint!
p.x = box2.x + box2.width / 2
p.y = box2.y + box2.height / 2
irr = rret.inverse!
p = p.matrixTransform irr
console.log p

setInterval (->
  #t.setRotate(dim.r, box.x + box.width / 2, box.y + box.height / 2)
  t.setRotate(dim.r, p.x, p.y)
  t2.setRotate(dim.r, p.x, p.y)
  dim.r += 1
), 10
