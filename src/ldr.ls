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
      mousedown: mousedown = (opt.mousedown or null)
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
        # only left click works. leave right click for context menu
        if e.button > 0 => return
        if !( (n = e.target) and n.classList and !n.classList.contains(\ldr-ctrl) ) => return @detach!
        if n == root or (filter and !filter(n)) => return @detach!
        document.addEventListener \mouseup, mouse.up
        document.addEventListener \mousemove, mouse.move
        mouse <<< ix: e.clientX, iy: e.clientY, nx: 1, ny: 1, n: nr[1]
        # if nothing selected, or the selected item is not current item -> re-attach.
        # otherwise, keep working on previous attached item
        if @mousedown => @attach @mousedown(e)
        else if !(@tgt.length and (n in @tgt)) => @attach n, e.shiftKey


      down-host: (e) ~>
        # only left click works. leave right click for context menu
        if !((n = e.target) and e.target.classList) or e.button > 0 => return
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
        # current mouse position (cx, cy) and ctrl node indices (nx, ny)
        [cx, cy, nx, ny] = [e.clientX, e.clientY, mouse.nx, mouse.ny]
        box = host.getBoundingClientRect!

        # nx = ny = 1 => central ctrl node, use for moving around
        if nx == 1 and ny == 1 =>
          [dx, dy] = [cx - mouse.ix, cy - mouse.iy]
          if e.shiftKey => [dx,dy] = if Math.abs(dx) > Math.abs(dy) => [dx, 0] else [0, dy]
          [dim.t.x, dim.t.y] = [dim.t.x + dx, dim.t.y + dy]
          mouse <<< ix: cx, iy: cy
          @fire \resize, {dim: @dim, targets: @tgt}
          return @render!

        # when we use cx/cy for offset from ix/iy, we don't care where cx/cy actually are. ( moving around case )
        # but when we need the absolute position cx/cy to calculate for scaling and rotation,
        # cx/cy from clientX/clientY are then matched with root box position, which might not aligned with host box.
        # so, we have to subtract cx with the offset rbox - hbox
        #d = @box-offset!
        #[cx, cy] = [cx + d.dx, cy + d.dy]

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
          @fire \resize, {dim: @dim, targets: @tgt}
          return @render!

        # scaling ctrl nodes ( .ldr-ctrl.s )
        if mouse.n.classList.contains \s =>
          # 對面的點
          p1 = [
            (2 - nx) * pv.0.x / 2 + (2 - ny) * pv.1.x / 2 + pt.0.x,
            (2 - nx) * pv.0.y / 2 + (2 - ny) * pv.1.y / 2 + pt.0.y
          ]
          p2 = [
            nx * pv.0.x / 2 + ny * pv.1.x / 2 + pt.0.x,
            nx * pv.0.y / 2 + ny * pv.1.y / 2 + pt.0.y
          ]
          # 對面的點與中心間的向量
          v = [p1.0 - pc.x, p1.1 - pc.y]
          # 向量長度
          len = Math.sqrt(v.0 * v.0 + v.1 * v.1)
          # 對面向量的夾角
          a = Math.acos(v.0 / len)
          if v.1 < 0 => a = 2 * Math.PI - a
          p1p = p1

          # 我們期望被拖動的點移到 p2p
          p2p = [cx - box.x, cy - box.y]

          # 若按住 shift, 則提供等比例縮放.
          if e.shiftKey =>
            # 取得 p2 於螢幕上的點減中心點的單位向量
            v = [Math.cos(a + Math.PI), Math.sin(a + Math.PI)]
            # 預計移至的位置其與中心點間的距離
            v2 = [p2p.0 - pc.x, p2p.1 - pc.y]
            len2 = Math.sqrt(v2.0 ** 2 + v2.1 ** 2)
            # 用未更新的 p2 點向量乘上滑鼠點與中心的距離, 來保持比例固定
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

          @fire \resize, {dim: @dim, targets: @tgt}
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
      # if root viewBox is not (0,0,...) then we need to adjust offset to compensate this.
      rvb = @root.getAttribute(\viewBox)
      [rvx, rvy, w, h] = if rvb => rvb.split(' ') else [0,0,0,0]
      {dx: rbox.x - hbox.x - rvx, dy: rbox.y - hbox.y - rvy}

    attach: (n, append = false) ->
      n = if Array.isArray(n) => n else [n]
      @tgt = if !append => n else @tgt ++ n.filter ~> !(it in @tgt)
      if !@tgt.length => return @detach!
      @n.g.style.display = \block
      [hb,rb] = [@host, @root].map -> it.getBoundingClientRect!

      # combined transformations from all parents
      _ = (n) ~>
        if !n or n.nodeName.toLowerCase! == \svg => return @host.createSVGMatrix!
        mat = if n.transform.baseVal.consolidate! => that.matrix else @host.createSVGMatrix!
        return _(n.parentNode).multiply(mat)

      at = s: {x: 1, y: 1}, r: 0, t: x: 0, y: 0
      # if box is calculated based on rb, then the viewBox info is gone;
      # so we restore it manually with rvx and rvy.
      rvb = @root.getAttribute(\viewBox)
      [rvx, rvy, w, h] = if rvb => rvb.split(' ').map(->+it) else [0,0,0,0]

      if @tgt.length > 1 =>
        # multiple targets. find containing box for them while consider their transform too.
        b = {x1: null, x2: null, y1: null, y2: null}
        @tgt.map ~>
          box = it.getBoundingClientRect!
          if b.x1 == null or b.x1 > box.x => b.x1 = box.x
          if b.x2 == null or b.x2 < box.x + box.width => b.x2 = box.x + box.width
          if b.y1 == null or b.y1 > box.y => b.y1 = box.y
          if b.y2 == null or b.y2 < box.y + box.height => b.y2 = box.y + box.height
          mat = (it.transform.baseVal.consolidate! or {})matrix or {a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}
          # create new matrix since firefox reuse consolidated matrix for new transform, which cause problem
          it._mi = @host.createSVGMatrix! <<< mat{a,b,c,d,e,f}
          it._mo = _(it.parentNode)
        @dim.box = box = {x: b.x1 - rb.x + rvx, y: b.y1 - rb.y + rvy, w: b.x2 - b.x1, h: b.y2 - b.y1}
        [cx, cy] = [box.x + box.w / 2, box.y + box.h / 2]
        # transform for this box is always identity at the beginning, so we don't change "at"
        # TODO deduct common "at" from all tgts for better user experience?
      else
        # single target. use its bounding box (before transforming) directly.
        @tgt.0._mo = mo = _ @tgt.0.parentNode
        n-alt = @tgt.0.cloneNode true
        n-alt.transform.baseVal.initialize @host.createSVGTransformFromMatrix mo
        @host.appendChild n-alt
        b = n-alt.getBoundingClientRect!
        n-alt.parentNode.removeChild n-alt
        @dim.box = box = {x: b.x - hb.x, y: b.y - hb.y, w: b.width, h: b.height}
        [cx, cy] = [box.x + box.w / 2, box.y + box.h / 2]
        transform = @tgt.0.transform.baseVal
        # we don't use consolidate here because we might need standalone transform below.
        mi = @host.createSVGMatrix!
        for i from 0 til transform.numberOfItems => mi = mi.multiply(transform.getItem(i).matrix)
        m = @tgt.0._mo.multiply(mi.multiply(@tgt.0._mo.inverse!))
        at.s <<< x: Math.sqrt(m.a ** 2 + m.b ** 2), y: Math.sqrt(m.c ** 2 + m.d ** 2)
        at.r = Math.acos(m.a / at.s.x)
        # acos range from 0 ~ Math.PI. check for sign of m.b (sin(a)) for Math.PI ~ 2 * Math.PI
        if m.b < 0 => at.r = Math.PI * 2 - at.r

        # if skew is involved, we should reset at to identity, and expand current transform into node.
        if ((m.c - at.s.y * -Math.sin(at.r)) ** 2 + (m.d - at.s.y * Math.cos(at.r)) ** 2) > 1e-5 =>
          # skewed with mi. try again with mi0
          m = @tgt.0._mo.multiply(transform.getItem(0).matrix.multiply(@tgt.0._mo.inverse!))
          at.s <<< x: Math.sqrt(m.a ** 2 + m.b ** 2), y: Math.sqrt(m.c ** 2 + m.d ** 2)
          at.r = Math.acos(m.a / at.s.x)
          if m.b < 0 => at.r = Math.PI * 2 - at.r
          if ((m.c - at.s.y * -Math.sin(at.r)) ** 2 + (m.d - at.s.y * Math.cos(at.r)) ** 2) > 1e-5 =>
            # still skewed with mi0. just use identity matrix as mc.
            # box dim must contains complete transformation
            b = @tgt.0.getBoundingClientRect!
            #@dim.box = box = {x: b.x - hb.x, y: b.y - hb.y, w: b.width, h: b.height}
            @dim.box = box = {x: b.x - rb.x + rvx, y: b.y - rb.y + rvy, w: b.width, h: b.height}
            [cx, cy] = [box.x + box.w / 2, box.y + box.h / 2]
            at.s <<< x: 1, y: 1
            at.t <<< x: 0, y: 0
            at.r = 0
          else
            # remove the first transform mi0 since it's a valid affine transformation
            mi = transform.getItem(0).matrix.inverse!multiply(mi)
            # we need the box with mo + mi information so we can mc' x (mo x mi)(from box)
            n-alt.transform.baseVal.initialize @host.createSVGTransformFromMatrix mo.multiply(mi)
            @host.appendChild n-alt
            b = n-alt.getBoundingClientRect!
            n-alt.parentNode.removeChild n-alt
            @dim.box = box = {x: b.x - hb.x, y: b.y - hb.y, w: b.width, h: b.height}
            [cx, cy] = [box.x + box.w / 2, box.y + box.h / 2]
            at.t <<< do
              x: m.e + at.s.x * cx * Math.cos(at.r) - at.s.y * cy * Math.sin(at.r) - cx
              y: m.f + at.s.x * cx * Math.sin(at.r) + at.s.y * cy * Math.cos(at.r) - cy

        else
          # valid affine transformation:
          at.t <<< do
            x: m.e + at.s.x * cx * Math.cos(at.r) - at.s.y * cy * Math.sin(at.r) - cx
            y: m.f + at.s.x * cx * Math.sin(at.r) + at.s.y * cy * Math.cos(at.r) - cy
          # mi is converted to at and replaced by mc. so it should be identity from now.
          mi = @host.createSVGMatrix!
        @tgt.0._mi = mi
      @dim <<< at # affine transform ( mc' )
      @dim <<< box # bounding box with mo x mi information inside.
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
      ].map -> (p <<< it).matrixTransform(mc) # x,y,w,h 已將 mo 列入計算, 所以只要乘上 mc
      pc = (p <<< x: z.x + z.w * 0.5, y: z.y + z.h * 0.5).matrixTransform(mc) # 同上
      pv =
        * {x: pt.1.x - pt.0.x, y: pt.1.y - pt.0.y}
        * {x: pt.3.x - pt.0.x, y: pt.3.y - pt.0.y}
      offset = @box-offset!
      pt.map -> it <<< x: it.x + offset.dx, y: it.y + offset.dy
      pc <<< x: pc.x + offset.dx, y: pc.y + offset.dy
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
          px = px + if len => vx * s / len - h * r else 0
          py = py + if len => vy * s / len - h * r else 0
          [
            [\x, px]
            [\y, py]
            [\width, s * r]
            [\height, s * r]
          ].map -> nr[y * 2 + x].setAttribute it.0, it.1


      mat = @host.createSVGMatrix! <<< {a,b,c,d,e,f}

      @tgt.map (it,i)~>
        {a,b,c,d,e,f} = it._mo.inverse!multiply(mat.multiply(it._mo))
        if !it._lasttransform => it._lasttransform = it.getAttribute \transform
        it.setAttribute \transform, (
          # affine transformation
          "matrix(#a #b #c #d #e #f)" +
          # inconvertible transformation (contains skewing) in this node.
          if it._mi => " matrix(#{<[a b c d e f]>.map((k)->it._mi[k]).join(' ')})" else ""
        )

  if module? => module.exports = ldResize
  if window => window.ldResize = ldResize
)!


