(->
  svg = \http://www.w3.org/2000/svg
  cs = <[#ff0 #0ff #f0f #fff]>
  deg = (v) -> 180 * v / Math.PI

  ldResize = (opt = {}) ->
    # initialization
    @ <<< do
      opt: opt, evt-handler: {}
      # host: where the resize widgets host in.
      host: host = if typeof(opt.host) == \string => document.querySelector(opt.host) else opt.host
      # dimension / affine transformation for this ldResize object.
      # set via attach, clean via detach
      dim: dim = do
        box: null       # initial target bounding box
        x: 100, y: 100  # initial bounding (x,y) ( left top corner )
        w: 100, h: 100  # initial bounding box size 
        t: x: 0, y: 0   # translation
        s: x: 0, y: 0   # scaling
        r: 0            # rotation

    # DOM for ctrl nodes
    @n = do
      s: ns = [0 to 8].map (d,i) ->
        n = document.createElementNS svg, \rect
          ..classList.add \ctrl, \s
          ..setAttribute \data-nx, i % 3
          ..setAttribute \data-ny, Math.floor(i/3)
      r: nr = [0 to 3].map (d,i) ->
        n = document.createElementNS svg, \rect
          ..classList.add \ctrl, \r
          ..setAttribute \data-nx, 2 * (i % 2)
          ..setAttribute \data-ny, 2 * Math.floor(i/2)
          ..setAttribute \fill, cs[i]
      g: ng = document.createElementNS svg, \g
    @n.b = nb = document.createElementNS svg, \rect
    nb.classList.add \range
    ng.appendChild nb
    nr.map -> ng.appendChild it
    ns.map -> ng.appendChild it
    host.appendChild ng

    # update ctrl node / bounding box position and size
    @draw = draw = ~>
      [s,r, sw,sh] = [ 8, 2, dim.w / 2, dim.h / 2 ]
      h = s / 2
      [
        [\x, -dim.w / 2], [\y, -dim.h / 2]
        [\width, dim.w],  [\height, dim.h]
      ].map -> nb.setAttribute it.0, it.1
      ng.setAttribute \transform, "translate(#{dim.x + dim.w / 2}, #{dim.y + dim.h / 2}) rotate(#{deg(dim.r or 0)})"
      for y from 0 to 2 =>
        for x from 0 to 2 =>
          if (x == 1 or y == 1) and !(x == 1 and y == 1) => continue
          [
            [\x, -dim.w / 2 - h + x * sw]
            [\y, -dim.h / 2 - h + y * sh]
            [\width, s]
            [\height, s]
          ].map -> ns[y * 3 + x].setAttribute it.0, it.1
      for y from 0 to 1 =>
        for x from 0 to 1 =>
          [
            [\x, -dim.w / 2 - h * r + x * dim.w + (2 * x - 1) * h]
            [\y, -dim.h / 2 - h * r + y * dim.h + (2 * y - 1) * h]
            [\width, s * r]
            [\height, s * r]
          ].map -> nr[y * 2 + x].setAttribute it.0, it.1

      box = dim.box
      dim.s.x = dim.w / box.w
      dim.s.y = dim.h / box.h
      dim.t.x = dim.x - box.x - (box.w / 2) * ( 1 - dim.s.x )
      dim.t.y = dim.y - box.y - (box.h / 2) * ( 1 - dim.s.y )
      [cx, cy] = [box.x + box.w / 2, box.y + box.h / 2]

      a =  dim.s.x * Math.cos(dim.r)
      b =  dim.s.x * Math.sin(dim.r)
      c = -dim.s.y * Math.sin(dim.r)
      d =  dim.s.y * Math.cos(dim.r)
      e = -dim.s.x * cx * Math.cos(dim.r) + dim.s.y * cy * Math.sin(dim.r) + cx + dim.t.x
      f = -dim.s.x * cx * Math.sin(dim.r) - dim.s.y * cy * Math.cos(dim.r) + cy + dim.t.y
      @tgt.setAttribute \transform, "matrix(#a #b #c #d #e #f)"

      /* if we don't want to calc matrix(a,b,c,d,e,f), we can set each transformation separatedly:
      @tgt.setAttribute(
        \transform,
        [
          "translate(#{dim.t.x} #{dim.t.y})"
          "translate(#cx #cy)"
          "rotate(#{deg dim.r})"
          "scale(#{dim.s.x} #{dim.s.y})"
          "translate(-#cx -#cy)"
        ].join(' ')
      )
      */
      
      # matrix(a,b,c,d,e,f) are calculated from following transformation:
      #   translate(tx ty)
      #   translate(cx cy)
      #   rotate(r)
      #   scale(sx sy)
      #   translate(cx cy)
      # The result matrix will be like:
      #   a = [sx * cos(r)]  c = [-sy * sin(r)]  e = [-sx * cx * cos(r) + sy * cy * sin(r) + cx + tx]
      #   b = [sx * sin(r)]  d = [ sy * cos(r)]  f = [-sx * cx * sin(r) - sy * cy * cos(r) + cy + ty]
      #       [    0      ]      [     0      ]      [                    1                         ]
      # We can then restore tx, ty, sx, sy, r with:
      #   sx = a^2 + b^2
      #   sy = c^2 + d^2
      #    r = acos(a / sx)
      #   tx = e + sx * cx * cos(r) - sy * cy * sin(r) - cx
      #   ty = f + sy * cy * sin(r) + sy * cy * cos(r) - cy

    # Mouse event handler
    mouse = do
      up: (e) -> [[\mouseup, mouse.p], [\mousemove, mouse.move]].map -> document.removeEventListener it.0, it.1
      down: (e) ->
        if !((n = e.target) and e.target.classList) => return
        document.addEventListener \mouseup, mouse.up
        document.addEventListener \mousemove, mouse.move
        [nx,ny] = <[data-nx data-ny]>.map (k) -> +n.getAttribute k
        mouse <<< do
          # initial mouse point when mouse down. use to calc mouse offset.
          ix: e.clientX, iy: e.clientY 
          # ctrl node idx ( x and y ). it's a simple way to identify the node's position
          # nx: 0 1 2    ny: 0 0 0
          #     0 1 2        1 1 1
          #     0 1 2        2 2 2
          nx: nx, ny: ny 
          # ctrl node
          n: n 

      move: (e) ->
        # current mouse position (cx, cy) and ctrl node idxes (nx, ny)
        [cx, cy, nx, ny] = [e.clientX, e.clientY, mouse.nx, mouse.ny]
        box = host.getBoundingClientRect!

        # nx = ny = 1 => central ctrl node, use for moving around
        if nx == 1 and ny == 1 => 
          [dim.x, dim.y] = [dim.x + cx - mouse.ix, dim.y + cy - mouse.iy]
          mouse <<< ix: cx, iy: cy
          return draw!

        # rotating ctrl nodes ( .ctrl.r )
        if mouse.n.classList.contains \r =>
          # 點擊的點
          p2 = [ dim.x + dim.w * ( nx ) / 2, dim.y + dim.h * ( ny ) / 2 ]
          # 向量
          v = [p2.0 - dim.x - dim.w / 2, p2.1 - dim.y - dim.h / 2]
          len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
          # 向量夾角
          a = Math.acos(v.0 / len)
          if v.1 < 0 => a = 2 * Math.PI - a
          # 將其夾角依當前轉動量轉動
          a += dim.r
          # 期望拖到的位置
          p2p = [cx - box.x, cy - box.y]
          # 向量
          v = [p2p.0 - dim.x - dim.w / 2, p2p.1 - dim.y - dim.h / 2]
          len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
          # 向量夾角
          na = Math.acos(v.0 / len)
          if v.1 < 0 => na = 2 * Math.PI - na
          dim.r = dim.r + (na - a)
          return draw!

        # scaling ctrl nodes ( .ctrl.s )
        if mouse.n.classList.contains \s =>
          # 對面的點
          p1 = [ dim.x + dim.w * ( 2 - nx ) / 2, dim.y + dim.h * ( 2 - ny ) / 2 ]
          p2 = [ dim.x + dim.w * ( nx ) / 2, dim.y + dim.h * ( ny ) / 2 ]
          # 對面的點與中心間的向量
          v = [
            dim.w * ( 1 - nx ) / 2
            dim.h * ( 1 - ny ) / 2
          ]
          # 向量長度
          len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
          # 對面向量的夾角
          a = Math.acos(v.0 / len)
          if v.1 < 0 => a = 2 * Math.PI - a
          # 將其夾角依當前轉動量轉動
          a += dim.r
          # ... 以取得該點在螢幕上的位置
          p1p = [
            dim.x + dim.w / 2 + len * Math.cos(a)
            dim.y + dim.h / 2 + len * Math.sin(a)
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
          a -= dim.r
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
          a -= dim.r
          p1 = [
            cp.0 + len * Math.cos(a)
            cp.1 + len * Math.sin(a)
          ]

          if nx == 0 => [dim.w,dim.x] = [p1.0 - p2.0 >? 0, p2.0]
          if ny == 0 => [dim.h,dim.y] = [p1.1 - p2.1 >? 0, p2.1]
          if nx == 2 => [dim.w,dim.x] = [p2.0 - p1.0 >? 0, p1.0]
          if ny == 2 => [dim.h,dim.y] = [p2.1 - p1.1 >? 0, p1.1]

          return draw!

    host.addEventListener \mousedown, mouse.down
    @

  ldResize.prototype = Object.create(Object.prototype) <<< do
    on: (n, cb) -> @evt-handler.[][n].push cb
    fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
    attach: (n) ->
      # store attached node n in tgt, and shorthand dim to d
      [@tgt,d] = [n, @dim]
 
      # we need a clean bbox for n without transform. store it in @dim.box
      n-alt = n.cloneNode true
      n-alt.setAttribute \transform, ''
      document.querySelector(\#svg).appendChild n-alt
      b = n-alt.getBoundingClientRect!
      n-alt.parentNode.removeChild n-alt
      rb = @host.getBoundingClientRect!
      d.box = box = {x: b.x - rb.x, y: b.y - rb.y, w: b.width, h: b.height}
      # central point of the bbox (cx, cy)
      [cx, cy] = [box.x + box.w / 2, box.y + box.h / 2]

      # consolidate makes us a matrix(a,b,c,d,e,f).
      # we then restore t,r,s from it.
      # check draw function for detail explanation
      t = n.getAttribute(\transform) or getComputedStyle(n).transform
      m = n.transform.baseVal.consolidate!matrix
      d.s <<< x: Math.sqrt(m.a ** 2 + m.b ** 2), y: Math.sqrt(m.c ** 2 + m.d ** 2)
      d.r = Math.acos(m.a / d.s.x)
      d.t <<< do
        x: m.e + d.s.x * cx * Math.cos(d.r) - d.s.y * cy * Math.sin(d.r) - cx
        y: m.f + d.s.x * cx * Math.sin(d.r) + d.s.y * cy * Math.cos(d.r) - cy

      @dim <<< do
        x: box.x + (box.w / 2) * (1 - @dim.s.x) + @dim.t.x
        y: box.y + (box.h / 2) * (1 - @dim.s.y) + @dim.t.y
        w: box.w * @dim.s.x
        h: box.h * @dim.s.y

      # draw will take care of transform by calcing it from @dim. 
      @draw!

    dim: -> @dim
    detach: -> 

  if module? => module.exports = ldResize
  if window => window.ldResize = ldResize
)!
