(->
  svg = \http://www.w3.org/2000/svg
  cs = <[#ff0 #0ff #f0f #fff]>
  deg = (v) -> 180 * v / Math.PI

  ldResize = (opt = {}) ->
    # initialization
    host = if !opt.host => opt.root else opt.host
    @ <<< do
      opt: opt, evt-handler: {}, tgt: []
      # host: where the resize widgets host in.
      host: host = if typeof(host) == \string => document.querySelector(host) else opt.host
      root: (root = if typeof(opt.root) == \string => document.querySelector(opt.root) else opt.root) if opt.root
      filter: filter = (opt.filter or null)
      dim: dim = {s: {x: 1, y: 1}, t: {x: 0, y: 0}, r: 0, x: 0, y: 0, w: 0, h: 0, mo: null}
    @host.classList.add \ldr-host
    if @host != @root => @host.classList.add \ldr-host-standalone

    # DOM for ctrl nodes
    @n = do
      s: ns = [0 to 8].map (d,i) ->
        n = document.createElementNS svg, \rect
          ..classList.add \ldr-ctrl, \s
          ..setAttribute \data-nx, i % 3
          ..setAttribute \data-ny, Math.floor(i/3)
      r: nr = [0 to 3].map (d,i) ->
        n = document.createElementNS svg, \rect
          ..classList.add \ldr-ctrl, \r
          ..setAttribute \data-nx, 2 * (i % 2)
          ..setAttribute \data-ny, 2 * Math.floor(i/2)
          ..setAttribute \fill, cs[i] if opt.visible-ctrl-r
          ..style.opacity 0.5 if opt.visible-ctrl-r
      g: ng = document.createElementNS svg, \g
    @n.b = nb = document.createElementNS svg, \path
    nb.classList.add \ldr-ctrl, \bbox
    ng.appendChild nb
    nr.map -> ng.appendChild it
    ns.map -> ng.appendChild it
    host.appendChild ng

    mouse = do
      up: (e) -> 
        document.removeEventListener \mouseup, mouse.up
        document.removeEventListener \mousemove, mouse.move
      down-root: (e) ~>
        if !( (n = e.target) and n.classList and !n.classList.contains(\ldr-ctrl) ) => return @detach!
        if n == root or (filter and !filter(n)) => return @detach!
        document.addEventListener \mouseup, mouse.up
        document.addEventListener \mousemove, mouse.move
        mouse <<< ix: e.clientX, iy: e.clientY, nx: 1, ny: 1, n: nr[1]
        # if nothing selected, or the selected item is not current item -> re-attach.
        # otherwise, keep working on previous attached item
        if @mouse-down => @attach @mouse-down(e)
        else if !(@tgt.length and (n in @tgt)) => @attach n, e.shiftKey


      down-host: (e) ~>
        if !((n = e.target) and e.target.classList) => return
        if n.classList.contains(\ldr-ctrl) =>
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
        else if root == host => mouse.down-root(e) # same container so we can share a common handler
        else @detach!
        # host event handled, prevent propagating to possible parent that handle event again.
        e.stopPropagation! 

      move: (e) ~>
        # current mouse position (cx, cy) and ctrl node idxes (nx, ny)
        [cx, cy, nx, ny] = [e.clientX, e.clientY, mouse.nx, mouse.ny]
        box = host.getBoundingClientRect!

        # nx = ny = 1 => central ctrl node, use for moving around
        if nx == 1 and ny == 1 =>
          [dx, dy] = [cx - mouse.ix, cy - mouse.iy]
          if e.shiftKey => [dx,dy] = if Math.abs(dx) > Math.abs(dy) => [dx, 0] else [0, dy]
          [dim.t.x, dim.t.y] = [dim.t.x + dx, dim.t.y + dy]
          mouse <<< ix: cx, iy: cy
          return @render!

        # when we use cx/cy for offset from ix/iy, we don't care where cx/cy actually are. ( moving around case )
        # but when we need the absolute position cx/cy to calculate for scaling and rotation,
        # cx/cy from clientX/clientY are then matched with root box position, which might not aligned with host box.
        # so, we have to subtract cx with the offset rbox - hbox
        d = @box-offset!
        [cx, cy] = [cx - d.dx, cy - d.dy]

        {pt,pc,pv,mc} = @pts!
        # rotating ctrl nodes ( .ldr-ctrl.r )
        if mouse.n.classList.contains \r =>
          # 點擊的點
          p2 = [
            nx * pv.0.x / 2 + ny * pv.1.x / 2 + pt.0.x,
            nx * pv.0.y / 2 + ny * pv.1.y / 2 + pt.0.y
          ]
          # 向量
          v = [p2.0 - pc.x, p2.1 - pc.y]
          len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
          # 向量夾角
          a = Math.acos(v.0 / len)
          if v.1 < 0 => a = 2 * Math.PI - a
          # 期望拖到的位置
          p2p = [cx - box.x, cy - box.y]
          # 向量
          v = [p2p.0 - pc.x, p2p.1 - pc.y]
          len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
          # 向量夾角
          na = Math.acos(v.0 / len)
          if v.1 < 0 => na = 2 * Math.PI - na
          dim.r += (na - a)
          if e.shiftKey => dim.r = Math.floor(dim.r / (Math.PI / 8)) * (Math.PI / 8)
          return @render!

        # scaling ctrl nodes ( .ldr-ctrl.s )
        if mouse.n.classList.contains \s =>
          # 對面的點
          #p1 = [ dim.x + dim.w * ( 2 - nx ) / 2, dim.y + dim.h * ( 2 - ny ) / 2 ]
          #p2 = [ dim.x + dim.w * ( nx ) / 2, dim.y + dim.h * ( ny ) / 2 ]

          p1 = [
            (2 - nx) * pv.0.x / 2 + (2 - ny) * pv.1.x / 2 + pt.0.x,
            (2 - nx) * pv.0.y / 2 + (2 - ny) * pv.1.y / 2 + pt.0.y
          ]
          p2 = [
            nx * pv.0.x / 2 + ny * pv.1.x / 2 + pt.0.x,
            nx * pv.0.y / 2 + ny * pv.1.y / 2 + pt.0.y
          ]
          # 對面的點與中心間的向量
          #v = [ dim.w * ( 1 - nx ) / 2, dim.h * ( 1 - ny ) / 2 ]
          v = [p1.0 - pc.x, p1.1 - pc.y]
          # 向量長度
          len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
          # 對面向量的夾角
          a = Math.acos(v.0 / len)
          if v.1 < 0 => a = 2 * Math.PI - a
          # 將其夾角依當前轉動量轉動
          #a += dim.r
          # ... 以取得該點在螢幕上的位置
          #p1p = [
          #  dim.x + dim.w / 2 + len * Math.cos(a)
          #  dim.y + dim.h / 2 + len * Math.sin(a)
          #]
          p1p = p1

          # 我們期望被拖動的點移到 p2p
          p2p = [cx - box.x, cy - box.y]

          # 若按住 shift, 則提供等比例縮放.
          # 或者, 若選了多個物件, 我們也強制等比例;
          #   - 因為多個物件時若縮放加上原有物件的旋轉, 會造成 shear 效果
          #   - 這個效果我們目前無法妥善的還原成 affine transformation 參數.
          #   - 事實上在 illustrator 中, 他是將 transform 即時 expand 到 shape 中來處理的.
          if e.shiftKey =>
            # 取得 p2 於螢幕上的點減中心點的單位向量
            v = [Math.cos(a + Math.PI), Math.sin(a + Math.PI)]
            # 預計移至的位置其與中心點間的距離
            #v2 = [p2p.0 - dim.x - dim.w / 2, p2p.1 - dim.y - dim.h / 2]
            v2 = [p2p.0 - pc.x, p2p.1 - pc.y]
            len2 = Math.sqrt(v2.0 ** 2 + v2.1 ** 2)
            # 用未更新的 p2 點向量乘上滑鼠點與中心的距離, 來保持比例固定
            #p2p = [ dim.x + dim.w / 2 + v.0 * len2, dim.y + dim.h / 2 + v.1 * len2 ]
            p2p = [ pc.x + v.0 * len2, pc.y + v.1 * len2 ]

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

          if nx == 0 => [dim.s.x, dim.t.x] = [(p1.0 - p2.0) / dim.w, dim.t.x + (cp.0 - pc.x)]
          if ny == 0 => [dim.s.y, dim.t.y] = [(p1.1 - p2.1) / dim.h, dim.t.y + (cp.1 - pc.y)]
          if nx == 2 => [dim.s.x, dim.t.x] = [(p2.0 - p1.0) / dim.w, dim.t.x + (cp.0 - pc.x)]
          if ny == 2 => [dim.s.y, dim.t.y] = [(p2.1 - p1.1) / dim.h, dim.t.y + (cp.1 - pc.y)]

          @fire \resize, @dim
          return @render!


    host.addEventListener \mousedown, mouse.down-host
    if root and host != root => root.addEventListener \mousedown, mouse.down-root

    @

  ldResize.prototype = Object.create(Object.prototype) <<< do
    on: (n, cb) -> @evt-handler.[][n].push cb
    fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
    set: ->
    get: -> @dim

    # if host and root box not aligned, we have to take care the offset.
    box-offset: ->
      if @host == @root => return {dx: 0, dy: 0}
      hbox = @host.getBoundingClientRect!
      rbox = @root.getBoundingClientRect!
      {dx: rbox.x - hbox.x, dy: rbox.y - hbox.y}

    attach: (n, plus = false) ->
      n = if Array.isArray(n) => n else [n]
      if !plus => @tgt = n
      else @tgt ++= n.filter ~> !(it in @tgt)
      if !@tgt.length => return @detach!
      @n.g.style.display = \block
      [hb,rb] = [@host, @root].map -> it.getBoundingClientRect!
      # now we extract expect affine transform from the target(s).
      at = s: {x: 1, y: 1}, r: 0, t: x: 0, y: 0

      _ = (n) ~>
        if !n or n.nodeName.toLowerCase! == \svg => return @host.createSVGMatrix!
        mat = if n.transform.baseVal.consolidate! => that.matrix else @host.createSVGMatrix!
        ret = _(n.parentNode)
        return ret.multiply(mat)

      if @tgt.length > 1 =>
        # multiple targets. find containing box for them while consider their transform too.
        b = {x1: null, x2: null, y1: null, y2: null}
        @tgt.map ~>
          box = it.getBoundingClientRect!
          if b.x1 == null or b.x1 > box.x => b.x1 = box.x
          if b.x2 == null or b.x2 < box.x + box.width => b.x2 = box.x + box.width
          if b.y1 == null or b.y1 > box.y => b.y1 = box.y
          if b.y2 == null or b.y2 < box.y + box.height => b.y2 = box.y + box.height
          it._mi = (it.transform.baseVal.consolidate! or {})matrix or @host.createSVGMatrix!
          it._mo = _(it.parentNode)
        @dim.box = box = {x: b.x1 - rb.x, y: b.y1 - rb.y, w: b.x2 - b.x1, h: b.y2 - b.y1}
        [cx, cy] = [box.x + box.w / 2, box.y + box.h / 2]
        @dim.mo = mo = @host.createSVGMatrix!
        # transform for this box is always identity at the beginning, so we don't change "at"
      else
        # single target. use its bounding box (before transforming) directly.
        @dim.mo = @tgt.0._mo = mo = _ @tgt.0.parentNode
        n-alt = @tgt.0.cloneNode true
        n-alt.transform.baseVal.initialize @host.createSVGTransformFromMatrix mo
        @host.appendChild n-alt
        b = n-alt.getBoundingClientRect!
        n-alt.parentNode.removeChild n-alt
        @dim.box = box = {x: b.x - hb.x, y: b.y - hb.y, w: b.width, h: b.height}
        [cx, cy] = [box.x + box.w / 2, box.y + box.h / 2]
        transform = @tgt.0.transform.baseVal
        mi = @host.createSVGMatrix!
        for i from 0 til transform.numberOfItems =>
          mi = mi.multiply(transform.getItem(i).matrix)

        #mi = (@tgt.0.transform.baseVal.consolidate! or {})matrix or @host.createSVGMatrix!
        m = @tgt.0._mo.multiply(mi.multiply(@tgt.0._mo.inverse!))
        at.s <<< x: Math.sqrt(m.a ** 2 + m.b ** 2), y: Math.sqrt(m.c ** 2 + m.d ** 2)
        at.r = Math.acos(m.a / at.s.x)

        # if skew is involved, we should reset at to identity, and expand current transform into node.
        if ((m.c - at.s.y * -Math.sin(at.r)) ** 2 + (m.d - at.s.y * Math.cos(at.r)) ** 2) > 1e-6 =>
          console.log "skewed."
          m = @tgt.0._mo.multiply(transform.getItem(0).matrix.multiply(@tgt.0._mo.inverse!))
          at.s <<< x: Math.sqrt(m.a ** 2 + m.b ** 2), y: Math.sqrt(m.c ** 2 + m.d ** 2)
          at.r = Math.acos(m.a / at.s.x)
          if ((m.c - at.s.y * -Math.sin(at.r)) ** 2 + (m.d - at.s.y * Math.cos(at.r)) ** 2) > 1e-6 =>
            console.log "skewed. 2"
            b = @tgt.0.getBoundingClientRect!
            @dim.box = box = {x: b.x - hb.x, y: b.y - hb.y, w: b.width, h: b.height}
            [cx, cy] = [box.x + box.w / 2, box.y + box.h / 2]
            at.s <<< x: 1, y: 1
            at.r = 0
            at.t <<< x: 0, y: 0
          else
            mi = @host.createSVGMatrix!
            for i from 1 til transform.numberOfItems =>
              mi = mi.multiply(transform.getItem(i).matrix)
            n-alt = @tgt.0.cloneNode true
            n-alt.transform.baseVal.initialize @host.createSVGTransformFromMatrix mo.multiply(mi)
            @host.appendChild n-alt
            b = n-alt.getBoundingClientRect!
            n-alt.parentNode.removeChild n-alt
            @dim.box = box = {x: b.x - hb.x, y: b.y - hb.y, w: b.width, h: b.height}
            [cx, cy] = [box.x + box.w / 2, box.y + box.h / 2]
            if m.b < 0 => at.r = Math.PI * 2 - at.r
            at.t <<< do
              x: m.e + at.s.x * cx * Math.cos(at.r) - at.s.y * cy * Math.sin(at.r) - cx
              y: m.f + at.s.x * cx * Math.sin(at.r) + at.s.y * cy * Math.cos(at.r) - cy


        else
          # acos range from 0 ~ Math.PI. check for sign of m.b (sin(a)) for Math.PI ~ 2 * Math.PI
          if m.b < 0 => at.r = Math.PI * 2 - at.r
          at.t <<< do
            x: m.e + at.s.x * cx * Math.cos(at.r) - at.s.y * cy * Math.sin(at.r) - cx
            y: m.f + at.s.x * cx * Math.sin(at.r) + at.s.y * cy * Math.cos(at.r) - cy
          # MI is converted to at and replaced by mc. so it should be identity from now.
          mi = @host.createSVGMatrix!
        @tgt.0._mi = mi
      @dim <<< at # affine transform ( mc )
      @dim <<< box # bounding box without any transformation ( either mo or mi )

      p = @host.createSVGPoint!
      p.x = @dim.x
      p.y = @dim.y
      @dim <<< p{x, y}

      @render!

    detach: ->
      @tgt.map -> it <<< {_mi: null, _mo: null}
      @tgt = []
      @n.g.style.display = \none
    
    # 根據目前的 tsr, 算出對應的 matrix a ~ f;
    # 另外，依據目前的長寬與原點, 算出 ctrl node 的位置, 中心點與兩側的向量.
    pts: ->
      z = @dim
      [cx, cy] = [z.x + z.w / 2, z.y + z.h / 2]
      a =  z.s.x * Math.cos(z.r)
      b =  z.s.x * Math.sin(z.r)
      c = -z.s.y * Math.sin(z.r)
      d =  z.s.y * Math.cos(z.r)
      e = -z.s.x * cx * Math.cos(z.r) + z.s.y * cy * Math.sin(z.r) + cx + z.t.x
      f = -z.s.x * cx * Math.sin(z.r) - z.s.y * cy * Math.cos(z.r) + cy + z.t.y
      mc = @host.createSVGMatrix!
      mc <<< {a, b, c, d, e, f}
      p = @host.createSVGPoint!
      pt = [
        {x: z.x, y: z.y}
        {x: z.x + z.w, y: z.y}
        {x: z.x + z.w, y: z.y + z.h}
        {x: z.x, y: z.y + z.h}
      ].map -> (p <<< it).matrixTransform(mc) #(z.mo.multiply(mc))
      #].map -> (p <<< it).matrixTransform(mc.multiply(z.mo)) #(z.mo.multiply(mc))
      p <<< x: z.x + z.w * 0.5, y: z.y + z.h * 0.5
      pc = p.matrixTransform(mc)# .multiply(z.mo))
      #pc = p.matrixTransform(mc.multiply(z.mo))
      pv = [
        {x: pt.1.x - pt.0.x, y: pt.1.y - pt.0.y}
        {x: pt.3.x - pt.0.x, y: pt.3.y - pt.0.y}
      ]
      pv.0.len = Math.sqrt(pv.0.x ** 2 + pv.0.y ** 2)
      pv.1.len = Math.sqrt(pv.1.x ** 2 + pv.1.y ** 2)
      return {a,b,c,d,e,f,pt,pc,pv}

    render: ->
      z = @dim
      [ng,nb,ns,nr] = [@n.g, @n.b, @n.s, @n.r]

      {a,b,c,d,e,f,pt,pc,pv} = @pts!

      nb.setAttribute \d, """
      M#{pt.0.x} #{pt.0.y}
      L#{pt.1.x} #{pt.1.y}
      L#{pt.2.x} #{pt.2.y}
      L#{pt.3.x} #{pt.3.y}
      Z
      """

      [s, h, r] = [8, 4, 2] # s: ctrl node size / h: half S / r: ratio of rotate ctrl node

      for y from 0 to 2 =>
        for x from 0 to 2 =>
          if (x == 1 or y == 1) and !(x == 1 and y == 1) => continue
          [
            [\width, s], [\height, s]
            [\x, x * pv.0.x / 2 + y * pv.1.x / 2 + pt.0.x - h]
            [\y, x * pv.0.y / 2 + y * pv.1.y / 2 + pt.0.y - h]
          ].map -> ns[y * 3 + x].setAttribute it.0, it.1

      for y from 0 to 1 =>
        for x from 0 to 1 =>
          px = x * pv.0.x + y * pv.1.x + pt.0.x
          py = x * pv.0.y + y * pv.1.y + pt.0.y
          vx = (px - pc.x)
          vy = (py - pc.y)
          len = Math.sqrt(vx ** 2 + vy ** 2)
          px = px + vx * s  / len - h * r
          py = py + vy * s  / len - h * r
          [
            [\x, px]
            [\y, py]
            [\width, s * r]
            [\height, s * r]
          ].map -> nr[y * 2 + x].setAttribute it.0, it.1


      mat = @host.createSVGMatrix! <<< {a,b,c,d,e,f}

      @tgt.map ~>
        mo = it._mo
        # multi-tgt -> mat is global outside mo. to apply within mo, inverse-mo x mat x mo
        if @tgt.length > 1 => m = mo.inverse!multiply(mat.multiply(mo))
        # single-tgt -> mat is mo x mc. to apply mc, simply inverse-mo x mat.
        #else => m = mo.inverse!multiply(mat)
        else => m = mo.inverse!multiply(mat.multiply(mo))
        {a,b,c,d,e,f} = m
        it.setAttribute \transform, (
          "matrix(#a #b #c #d #e #f)" +
          if it._mi => " matrix(#{that.a} #{that.b} #{that.c} #{that.d} #{that.e} #{that.f})"
          else ""
        )

  if module? => module.exports = ldResize
  if window => window.ldResize = ldResize
)!


######### Explanation of all these math ############
/*
if we don't want to calc matrix(a,b,c,d,e,f), we can set each transformation separatedly:
[
  "translate(#{dim.t.x} #{dim.t.y})"
  "translate(#cx #cy)"
  "rotate(#{deg dim.r})"
  "scale(#{dim.s.x} #{dim.s.y})"
  "translate(-#cx -#cy)"
].join(' ')
 matrix(a,b,c,d,e,f) are calculated from following transformation:
   translate(tx ty)
   translate(cx cy)
   rotate(r)
   scale(sx sy)
   translate(cx cy)
 The result matrix will be like:
   a = [sx * cos(r)]  c = [-sy * sin(r)]  e = [-sx * cx * cos(r) + sy * cy * sin(r) + cx + tx]
   b = [sx * sin(r)]  d = [ sy * cos(r)]  f = [-sx * cx * sin(r) - sy * cy * cos(r) + cy + ty]
       [    0      ]      [     0      ]      [                    1                         ]
 We can then restore tx, ty, sx, sy, r with:
   sx = a^2 + b^2
   sy = c^2 + d^2
    r = acos(a / sx)
   tx = e + sx * cx * cos(r) - sy * cy * sin(r) - cx
   ty = f + sy * cy * sin(r) + sy * cy * cos(r) - cy
*/
