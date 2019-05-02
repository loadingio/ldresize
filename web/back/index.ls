svg = ld$.find document, '#svg', 0
range = ld$.create name: \rect, ns: \svg, className: <[range]>
pts = [0 to 8].map (d,i) ->
  ld$.create name: \rect, ns: \svg, className: <[ctrl t]>, attr: {px: i%3, py: Math.floor(i/3)}
cs = <[#ff0 #0ff #f0f #fff]>
rts = [0 to 3].map (d,i) ->
  ld$.create name: \rect, ns: \svg, className: <[ctrl r]>, attr: {px: 2 * (i % 2), py: 2 * Math.floor(i/2), fill: cs[i]}
g = ld$.create name: \g, ns: \svg

b = do
  x: 100
  y: 100
  a: Math.PI / 4
  w: 100
  h: 100

deg = (v) -> 180 * v / Math.PI

draw = ->
  s = 8
  h = s / 2
  sw = b.w / 2
  sh = b.h / 2
  ld$.attr range, {x: -b.w / 2, y: -b.h / 2, width: b.w, height: b.h}
  g.setAttribute \transform, "translate(#{b.x + b.w / 2}, #{b.y + b.h / 2}) rotate(#{deg(b.a or 0)})"
  for y from 0 to 2 =>
    for x from 0 to 2 =>
      #ld$.attr pts[y * 3 + x], {x: b.x - h + x * sw, y: b.y - h + y * sh, width: s, height: s }
      if (x == 1 or y == 1) and !(x == 1 and y == 1) => continue
      ld$.attr pts[y * 3 + x], {x: -b.w / 2 - h + x * sw, y: -b.h / 2 - h + y * sh, width: s, height: s }
  for y from 0 to 1 =>
    for x from 0 to 1 =>
      ld$.attr rts[y * 2 + x], do
        x: -b.w / 2 - h * 1.5 + x * b.w + (2 * x - 1) * h
        y: -b.h / 2 - h * 1.5 + y * b.h + (2 * y - 1) * h
        width: s * 1.5
        height: s * 1.5

g.appendChild range
rts.map -> g.appendChild it
pts.map -> g.appendChild it
svg.appendChild g

draw!

#blah = (p1, p2, p2p, a) ->
#  ret = r(p2p - (p1 + p2p) / 2, -a)

#n: current node
#px, py: ptr idx


mouse = do
  up: (e) ->
    document.removeEventListener \mouseup, mouse.up
    document.removeEventListener \mousemove, mouse.move
  move: (e) ->
    [cx, cy, px, py] = [e.clientX, e.clientY, mouse.px, mouse.py]
    box = svg.getBoundingClientRect!
    if px == 1 and py == 1 => 
      [dx, dy] = [cx - mouse.ix, cy - mouse.iy]
      b.x += dx
      b.y += dy
      mouse <<< ix: cx, iy: cy
      draw!
      return
    if mouse.n.classList.contains \r =>
      # 點擊的點
      p2 = [ b.x + b.w * ( px ) / 2, b.y + b.h * ( py ) / 2 ]
      # 向量
      v = [p2.0 - b.x - b.w / 2, p2.1 - b.y - b.h / 2]
      len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
      # 向量夾角
      a = Math.acos(v.0 / len)
      if v.1 < 0 => a = 2 * Math.PI - a
      # 將其夾角依當前轉動量轉動
      a += b.a
      # 期望拖到的位置
      p2p = [cx - box.x, cy - box.y]
      # 向量
      v = [p2p.0 - b.x - b.w / 2, p2p.1 - b.y - b.h / 2]
      len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
      # 向量夾角
      na = Math.acos(v.0 / len)
      if v.1 < 0 => na = 2 * Math.PI - na
      b.a = b.a + (na - a)

    if mouse.n.classList.contains \t =>
      # 對面的點
      p1 = [ b.x + b.w * ( 2 - px ) / 2, b.y + b.h * ( 2 - py ) / 2 ]
      p2 = [ b.x + b.w * ( px ) / 2, b.y + b.h * ( py ) / 2 ]
      # 對面的點與中心間的向量
      v = [
        b.w * ( 1 - px ) / 2
        b.h * ( 1 - py ) / 2
      ]
      # 向量長度
      len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
      # 對面向量的夾角
      a = Math.acos(v.0 / len)
      if v.1 < 0 => a = 2 * Math.PI - a
      # 將其夾角依當前轉動量轉動
      a += b.a
      # ... 以取得該點在螢幕上的位置
      p1p = [
        b.x + b.w / 2 + len * Math.cos(a)
        b.y + b.h / 2 + len * Math.sin(a)
      ]

      # 我們期望被拖動的點移到 p2p
      p2p = [cx - box.x, cy - box.y]

      # p2p 與 p1p 的中心為 cp
      cp = [(p1p.0 + p2p.0)/2, (p1p.1 + p2p.1)/2]

      # p2p 的中心點向量, 長度以及與中心夾角
      v = [ p2p.0 - cp.0, p2p.1 - cp.1 ]
      len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
      a = Math.acos(v.0 / len)
      if v.1 < 0 => a = 2 * Math.PI - a
      # 逆回轉以求得回轉前應在的位置
      a -= b.a
      p2 = [
        cp.0 + len * Math.cos(a)
        cp.1 + len * Math.sin(a)
      ]

      # p1p 的中心點向量, 長度以及與中心夾角
      v = [ p1p.0 - cp.0, p1p.1 - cp.1 ]
      len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
      a = Math.acos(v.0 / len)
      if v.1 < 0 => a = 2 * Math.PI - a
      # 逆回轉以求得回轉前應在的位置
      a -= b.a
      p1 = [
        cp.0 + len * Math.cos(a)
        cp.1 + len * Math.sin(a)
      ]

      if px == 0 => [b.w,b.x] = [p1.0 - p2.0 >? 0, p2.0]
      if py == 0 => [b.h,b.y] = [p1.1 - p2.1 >? 0, p2.1]
      if px == 2 => [b.w,b.x] = [p2.0 - p1.0 >? 0, p1.0]
      if py == 2 => [b.h,b.y] = [p2.1 - p1.1 >? 0, p1.1]

    draw!

  down: (e) ->
    if !(n = ld$.parent e.target, '.ctrl', svg) => return
    document.addEventListener \mouseup, mouse.up
    document.addEventListener \mousemove, mouse.move
    [px,py] = <[px py]>.map (k) -> +n.getAttribute k
    mouse <<< {ix: e.clientX, iy: e.clientY, px, py, n}

svg.addEventListener \mousedown, mouse.down
