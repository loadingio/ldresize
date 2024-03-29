(function(){
  var svg, cs, deg, ldresize;
  svg = 'http://www.w3.org/2000/svg';
  cs = ['#ff0', '#0ff', '#f0f', '#fff'];
  deg = function(v){
    return 180 * v / Math.PI;
  };
  ldresize = function(opt){
    var host, root, filter, mousedown, dim, ns, nr, ng, nb, mouse, this$ = this;
    opt == null && (opt = {});
    host = !opt.host
      ? opt.root
      : opt.host;
    import$(this, {
      opt: opt,
      evtHandler: {},
      tgt: [],
      host: host = typeof host === 'string'
        ? document.querySelector(host)
        : opt.host,
      root: opt.root ? root = typeof opt.root === 'string'
        ? document.querySelector(opt.root)
        : opt.root : void 8,
      filter: filter = opt.filter || null,
      mousedown: mousedown = opt.mousedown || null,
      dim: dim = {
        s: {
          x: 1,
          y: 1
        },
        t: {
          x: 0,
          y: 0
        },
        r: 0,
        x: 0,
        y: 0,
        w: 0,
        h: 0,
        mo: null
      }
    });
    this.host.classList.add('ldr-host');
    if (this.host !== this.root) {
      this.host.classList.add('ldr-host-standalone');
    }
    this.n = {
      s: ns = [0, 1, 2, 3, 4, 5, 6, 7, 8].map(function(d, i){
        var x$, n;
        x$ = n = document.createElementNS(svg, 'rect');
        x$.classList.add('ldr-ctrl', 's');
        x$.setAttribute('data-nx', i % 3);
        x$.setAttribute('data-ny', Math.floor(i / 3));
        return x$;
      }),
      r: nr = [0, 1, 2, 3].map(function(d, i){
        var x$, n;
        x$ = n = document.createElementNS(svg, 'rect');
        x$.classList.add('ldr-ctrl', 'r');
        x$.setAttribute('data-nx', 2 * (i % 2));
        x$.setAttribute('data-ny', 2 * Math.floor(i / 2));
        if (opt.visibleCtrlR) {
          x$.setAttribute('fill', cs[i]);
        }
        if (opt.visibleCtrlR) {
          x$.style.opacity(0.5);
        }
        return x$;
      }),
      g: ng = document.createElementNS(svg, 'g')
    };
    this.n.b = nb = document.createElementNS(svg, 'path');
    nb.classList.add('ldr-ctrl', 'bbox');
    ng.appendChild(nb);
    nr.map(function(it){
      return ng.appendChild(it);
    });
    ns.map(function(it){
      return ng.appendChild(it);
    });
    host.appendChild(ng);
    mouse = {
      up: function(e){
        document.removeEventListener('mouseup', mouse.up);
        return document.removeEventListener('mousemove', mouse.move);
      },
      downRoot: function(e){
        var n;
        if (e.button > 0) {
          return;
        }
        if (!((n = e.target) && n.classList && !n.classList.contains('ldr-ctrl'))) {
          return this$.detach();
        }
        if (n === root || (filter && !filter(n))) {
          return this$.detach();
        }
        document.addEventListener('mouseup', mouse.up);
        document.addEventListener('mousemove', mouse.move);
        mouse.ix = e.clientX;
        mouse.iy = e.clientY;
        mouse.nx = 1;
        mouse.ny = 1;
        mouse.n = nr[1];
        if (this$.mousedown) {
          return this$.attach(this$.mousedown(e));
        } else if (!(this$.tgt.length && in$(n, this$.tgt))) {
          return this$.attach(n, e.shiftKey);
        }
      },
      downHost: function(e){
        var n, ref$, nx, ny;
        if (!((n = e.target) && e.target.classList) || e.button > 0) {
          return;
        }
        if (n.classList.contains('ldr-ctrl')) {
          document.addEventListener('mouseup', mouse.up);
          document.addEventListener('mousemove', mouse.move);
          ref$ = ['data-nx', 'data-ny'].map(function(k){
            return +n.getAttribute(k);
          }), nx = ref$[0], ny = ref$[1];
          import$(mouse, {
            ix: e.clientX,
            iy: e.clientY,
            nx: nx,
            ny: ny,
            n: n
          });
        } else if (root === host) {
          mouse.downRoot(e);
        } else {
          this$.detach();
        }
        return e.stopPropagation();
      },
      move: function(e){
        var ref$, cx, cy, nx, ny, box, dx, dy, pt, pc, pv, mc, p2, v, len, a, p2p, na, p1, p1p, v2, len2, cp;
        ref$ = [e.clientX, e.clientY, mouse.nx, mouse.ny], cx = ref$[0], cy = ref$[1], nx = ref$[2], ny = ref$[3];
        box = host.getBoundingClientRect();
        if (nx === 1 && ny === 1) {
          ref$ = [cx - mouse.ix, cy - mouse.iy], dx = ref$[0], dy = ref$[1];
          if (e.shiftKey) {
            ref$ = Math.abs(dx) > Math.abs(dy)
              ? [dx, 0]
              : [0, dy], dx = ref$[0], dy = ref$[1];
          }
          ref$ = [dim.t.x + dx, dim.t.y + dy], dim.t.x = ref$[0], dim.t.y = ref$[1];
          mouse.ix = cx;
          mouse.iy = cy;
          this$.fire('resize', {
            dim: this$.dim,
            targets: this$.tgt
          });
          return this$.render();
        }
        ref$ = this$.pts(), pt = ref$.pt, pc = ref$.pc, pv = ref$.pv, mc = ref$.mc;
        if (mouse.n.classList.contains('r')) {
          p2 = [nx * pv[0].x / 2 + ny * pv[1].x / 2 + pt[0].x, nx * pv[0].y / 2 + ny * pv[1].y / 2 + pt[0].y];
          v = [p2[0] - pc.x, p2[1] - pc.y];
          len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
          a = Math.acos(v[0] / len);
          if (v[1] < 0) {
            a = 2 * Math.PI - a;
          }
          p2p = [cx - box.x, cy - box.y];
          v = [p2p[0] - pc.x, p2p[1] - pc.y];
          len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
          na = Math.acos(v[0] / len);
          if (v[1] < 0) {
            na = 2 * Math.PI - na;
          }
          dim.r += na - a;
          if (e.shiftKey) {
            dim.r = Math.floor(dim.r / (Math.PI / 8)) * (Math.PI / 8);
          }
          this$.fire('resize', {
            dim: this$.dim,
            targets: this$.tgt
          });
          return this$.render();
        }
        if (mouse.n.classList.contains('s')) {
          p1 = [(2 - nx) * pv[0].x / 2 + (2 - ny) * pv[1].x / 2 + pt[0].x, (2 - nx) * pv[0].y / 2 + (2 - ny) * pv[1].y / 2 + pt[0].y];
          p2 = [nx * pv[0].x / 2 + ny * pv[1].x / 2 + pt[0].x, nx * pv[0].y / 2 + ny * pv[1].y / 2 + pt[0].y];
          v = [p1[0] - pc.x, p1[1] - pc.y];
          len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
          a = Math.acos(v[0] / len);
          if (v[1] < 0) {
            a = 2 * Math.PI - a;
          }
          p1p = p1;
          p2p = [cx - box.x, cy - box.y];
          if (e.shiftKey) {
            v = [Math.cos(a + Math.PI), Math.sin(a + Math.PI)];
            v2 = [p2p[0] - pc.x, p2p[1] - pc.y];
            len2 = Math.sqrt(Math.pow(v2[0], 2) + Math.pow(v2[1], 2));
            p2p = [pc.x + v[0] * len2, pc.y + v[1] * len2];
          }
          cp = [(p1p[0] + p2p[0]) / 2, (p1p[1] + p2p[1]) / 2];
          v = [p2p[0] - cp[0], p2p[1] - cp[1]];
          len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
          a = Math.acos(v[0] / len);
          if (v[1] < 0) {
            a = 2 * Math.PI - a;
          }
          a -= dim.r;
          p2 = [cp[0] + len * Math.cos(a), cp[1] + len * Math.sin(a)];
          v = [p1p[0] - cp[0], p1p[1] - cp[1]];
          len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
          a = Math.acos(v[0] / len);
          if (v[1] < 0) {
            a = 2 * Math.PI - a;
          }
          a -= dim.r;
          p1 = [cp[0] + len * Math.cos(a), cp[1] + len * Math.sin(a)];
          if (nx === 0) {
            ref$ = [(p1[0] - p2[0]) / dim.w, dim.t.x + (cp[0] - pc.x)], dim.s.x = ref$[0], dim.t.x = ref$[1];
          }
          if (ny === 0) {
            ref$ = [(p1[1] - p2[1]) / dim.h, dim.t.y + (cp[1] - pc.y)], dim.s.y = ref$[0], dim.t.y = ref$[1];
          }
          if (nx === 2) {
            ref$ = [(p2[0] - p1[0]) / dim.w, dim.t.x + (cp[0] - pc.x)], dim.s.x = ref$[0], dim.t.x = ref$[1];
          }
          if (ny === 2) {
            ref$ = [(p2[1] - p1[1]) / dim.h, dim.t.y + (cp[1] - pc.y)], dim.s.y = ref$[0], dim.t.y = ref$[1];
          }
          this$.fire('resize', {
            dim: this$.dim,
            targets: this$.tgt
          });
          return this$.render();
        }
      }
    };
    host.addEventListener('mousedown', mouse.downHost);
    if (root && host !== root) {
      root.addEventListener('mousedown', mouse.downRoot);
    }
    return this;
  };
  ldresize.prototype = import$(Object.create(Object.prototype), {
    on: function(n, cb){
      var ref$;
      return ((ref$ = this.evtHandler)[n] || (ref$[n] = [])).push(cb);
    },
    fire: function(n){
      var v, res$, i$, to$, ref$, len$, cb, results$ = [];
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      v = res$;
      for (i$ = 0, len$ = (ref$ = this.evtHandler[n] || []).length; i$ < len$; ++i$) {
        cb = ref$[i$];
        results$.push(cb.apply(this, v));
      }
      return results$;
    },
    set: function(){},
    get: function(){
      return this.dim;
    },
    boxOffset: function(){
      var hbox, rbox, rvb, ref$, rvx, rvy, w, h;
      if (this.host === this.root) {
        return {
          dx: 0,
          dy: 0
        };
      }
      hbox = this.host.getBoundingClientRect();
      rbox = this.root.getBoundingClientRect();
      rvb = this.root.getAttribute('viewBox');
      ref$ = rvb
        ? rvb.split(' ')
        : [0, 0, 0, 0], rvx = ref$[0], rvy = ref$[1], w = ref$[2], h = ref$[3];
      return {
        dx: rbox.x - hbox.x - rvx,
        dy: rbox.y - hbox.y - rvy
      };
    },
    attach: function(n, append){
      var ref$, hb, rb, _, at, rvb, rvx, rvy, w, h, b, box, cx, cy, mo, nAlt, transform, mi, i$, to$, i, m, this$ = this;
      append == null && (append = false);
      n = Array.isArray(n)
        ? n
        : [n];
      this.tgt = !append
        ? n
        : this.tgt.concat(n.filter(function(it){
          return !in$(it, this$.tgt);
        }));
      if (!this.tgt.length) {
        return this.detach();
      }
      this.n.g.style.display = 'block';
      ref$ = [this.host, this.root].map(function(it){
        return it.getBoundingClientRect();
      }), hb = ref$[0], rb = ref$[1];
      _ = function(n){
        var mat, that;
        if (!n || n.nodeName.toLowerCase() === 'svg') {
          return this$.host.createSVGMatrix();
        }
        mat = (that = n.transform.baseVal.consolidate())
          ? that.matrix
          : this$.host.createSVGMatrix();
        return _(n.parentNode).multiply(mat);
      };
      at = {
        s: {
          x: 1,
          y: 1
        },
        r: 0,
        t: {
          x: 0,
          y: 0
        }
      };
      rvb = this.root.getAttribute('viewBox');
      ref$ = rvb
        ? rvb.split(' ').map(function(it){
          return +it;
        })
        : [0, 0, 0, 0], rvx = ref$[0], rvy = ref$[1], w = ref$[2], h = ref$[3];
      if (this.tgt.length > 1) {
        b = {
          x1: null,
          x2: null,
          y1: null,
          y2: null
        };
        this.tgt.map(function(it){
          var box, mat, ref$;
          box = it.getBoundingClientRect();
          if (b.x1 === null || b.x1 > box.x) {
            b.x1 = box.x;
          }
          if (b.x2 === null || b.x2 < box.x + box.width) {
            b.x2 = box.x + box.width;
          }
          if (b.y1 === null || b.y1 > box.y) {
            b.y1 = box.y;
          }
          if (b.y2 === null || b.y2 < box.y + box.height) {
            b.y2 = box.y + box.height;
          }
          mat = (it.transform.baseVal.consolidate() || {}).matrix || {
            a: 1,
            b: 0,
            c: 0,
            d: 1,
            e: 0,
            f: 0
          };
          it._mi = (ref$ = this$.host.createSVGMatrix(), ref$.a = mat.a, ref$.b = mat.b, ref$.c = mat.c, ref$.d = mat.d, ref$.e = mat.e, ref$.f = mat.f, ref$);
          return it._mo = _(it.parentNode);
        });
        this.dim.box = box = {
          x: b.x1 - rb.x + rvx,
          y: b.y1 - rb.y + rvy,
          w: b.x2 - b.x1,
          h: b.y2 - b.y1
        };
        ref$ = [box.x + box.w / 2, box.y + box.h / 2], cx = ref$[0], cy = ref$[1];
      } else {
        this.tgt[0]._mo = mo = _(this.tgt[0].parentNode);
        nAlt = this.tgt[0].cloneNode(true);
        nAlt.transform.baseVal.initialize(this.host.createSVGTransformFromMatrix(mo));
        this.host.appendChild(nAlt);
        b = nAlt.getBoundingClientRect();
        nAlt.parentNode.removeChild(nAlt);
        this.dim.box = box = {
          x: b.x - hb.x,
          y: b.y - hb.y,
          w: b.width,
          h: b.height
        };
        ref$ = [box.x + box.w / 2, box.y + box.h / 2], cx = ref$[0], cy = ref$[1];
        transform = this.tgt[0].transform.baseVal;
        mi = this.host.createSVGMatrix();
        for (i$ = 0, to$ = transform.numberOfItems; i$ < to$; ++i$) {
          i = i$;
          mi = mi.multiply(transform.getItem(i).matrix);
        }
        m = this.tgt[0]._mo.multiply(mi.multiply(this.tgt[0]._mo.inverse()));
        ref$ = at.s;
        ref$.x = Math.sqrt(Math.pow(m.a, 2) + Math.pow(m.b, 2));
        ref$.y = Math.sqrt(Math.pow(m.c, 2) + Math.pow(m.d, 2));
        at.r = Math.acos(m.a / at.s.x);
        if (m.b < 0) {
          at.r = Math.PI * 2 - at.r;
        }
        if (Math.pow(m.c - at.s.y * -Math.sin(at.r), 2) + Math.pow(m.d - at.s.y * Math.cos(at.r), 2) > 1e-5) {
          m = this.tgt[0]._mo.multiply(transform.getItem(0).matrix.multiply(this.tgt[0]._mo.inverse()));
          ref$ = at.s;
          ref$.x = Math.sqrt(Math.pow(m.a, 2) + Math.pow(m.b, 2));
          ref$.y = Math.sqrt(Math.pow(m.c, 2) + Math.pow(m.d, 2));
          at.r = Math.acos(m.a / at.s.x);
          if (m.b < 0) {
            at.r = Math.PI * 2 - at.r;
          }
          if (Math.pow(m.c - at.s.y * -Math.sin(at.r), 2) + Math.pow(m.d - at.s.y * Math.cos(at.r), 2) > 1e-5) {
            b = this.tgt[0].getBoundingClientRect();
            this.dim.box = box = {
              x: b.x - rb.x + rvx,
              y: b.y - rb.y + rvy,
              w: b.width,
              h: b.height
            };
            ref$ = [box.x + box.w / 2, box.y + box.h / 2], cx = ref$[0], cy = ref$[1];
            ref$ = at.s;
            ref$.x = 1;
            ref$.y = 1;
            ref$ = at.t;
            ref$.x = 0;
            ref$.y = 0;
            at.r = 0;
          } else {
            mi = transform.getItem(0).matrix.inverse().multiply(mi);
            nAlt.transform.baseVal.initialize(this.host.createSVGTransformFromMatrix(mo.multiply(mi)));
            this.host.appendChild(nAlt);
            b = nAlt.getBoundingClientRect();
            nAlt.parentNode.removeChild(nAlt);
            this.dim.box = box = {
              x: b.x - hb.x,
              y: b.y - hb.y,
              w: b.width,
              h: b.height
            };
            ref$ = [box.x + box.w / 2, box.y + box.h / 2], cx = ref$[0], cy = ref$[1];
            import$(at.t, {
              x: m.e + at.s.x * cx * Math.cos(at.r) - at.s.y * cy * Math.sin(at.r) - cx,
              y: m.f + at.s.x * cx * Math.sin(at.r) + at.s.y * cy * Math.cos(at.r) - cy
            });
          }
        } else {
          import$(at.t, {
            x: m.e + at.s.x * cx * Math.cos(at.r) - at.s.y * cy * Math.sin(at.r) - cx,
            y: m.f + at.s.x * cx * Math.sin(at.r) + at.s.y * cy * Math.cos(at.r) - cy
          });
          mi = this.host.createSVGMatrix();
        }
        this.tgt[0]._mi = mi;
      }
      import$(this.dim, at);
      import$(this.dim, box);
      return this.render();
    },
    detach: function(){
      this.tgt.map(function(it){
        return it._mi = null, it._mo = null, it;
      });
      this.tgt = [];
      return this.n.g.style.display = 'none';
    },
    pts: function(){
      var z, ref$, cx, cy, a, b, c, d, e, f, mc, p, pt, pc, pv, offset;
      z = this.dim;
      ref$ = [z.x + z.w / 2, z.y + z.h / 2], cx = ref$[0], cy = ref$[1];
      a = z.s.x * Math.cos(z.r);
      b = z.s.x * Math.sin(z.r);
      c = -z.s.y * Math.sin(z.r);
      d = z.s.y * Math.cos(z.r);
      e = -z.s.x * cx * Math.cos(z.r) + z.s.y * cy * Math.sin(z.r) + cx + z.t.x;
      f = -z.s.x * cx * Math.sin(z.r) - z.s.y * cy * Math.cos(z.r) + cy + z.t.y;
      mc = this.host.createSVGMatrix();
      mc.a = a;
      mc.b = b;
      mc.c = c;
      mc.d = d;
      mc.e = e;
      mc.f = f;
      p = this.host.createSVGPoint();
      pt = [
        {
          x: z.x,
          y: z.y
        }, {
          x: z.x + z.w,
          y: z.y
        }, {
          x: z.x + z.w,
          y: z.y + z.h
        }, {
          x: z.x,
          y: z.y + z.h
        }
      ].map(function(it){
        return import$(p, it).matrixTransform(mc);
      });
      pc = (p.x = z.x + z.w * 0.5, p.y = z.y + z.h * 0.5, p).matrixTransform(mc);
      pv = [
        {
          x: pt[1].x - pt[0].x,
          y: pt[1].y - pt[0].y
        }, {
          x: pt[3].x - pt[0].x,
          y: pt[3].y - pt[0].y
        }
      ];
      offset = this.boxOffset();
      pt.map(function(it){
        return it.x = it.x + offset.dx, it.y = it.y + offset.dy, it;
      });
      pc.x = pc.x + offset.dx;
      pc.y = pc.y + offset.dy;
      return {
        a: a,
        b: b,
        c: c,
        d: d,
        e: e,
        f: f,
        pt: pt,
        pc: pc,
        pv: pv
      };
    },
    render: function(){
      var z, ref$, ng, nb, ns, nr, a, b, c, d, e, f, pt, pc, pv, s, h, r, i$, y, j$, x, px, py, vx, vy, len, mat;
      z = this.dim;
      ref$ = [this.n.g, this.n.b, this.n.s, this.n.r], ng = ref$[0], nb = ref$[1], ns = ref$[2], nr = ref$[3];
      ref$ = this.pts(), a = ref$.a, b = ref$.b, c = ref$.c, d = ref$.d, e = ref$.e, f = ref$.f, pt = ref$.pt, pc = ref$.pc, pv = ref$.pv;
      nb.setAttribute('d', "M" + pt[0].x + " " + pt[0].y + "\nL" + pt[1].x + " " + pt[1].y + "\nL" + pt[2].x + " " + pt[2].y + "\nL" + pt[3].x + " " + pt[3].y + "\nZ");
      ref$ = [8, 4, 2], s = ref$[0], h = ref$[1], r = ref$[2];
      for (i$ = 0; i$ <= 2; ++i$) {
        y = i$;
        for (j$ = 0; j$ <= 2; ++j$) {
          x = j$;
          if ((x === 1 || y === 1) && !(x === 1 && y === 1)) {
            continue;
          }
          [['width', s], ['height', s], ['x', x * pv[0].x / 2 + y * pv[1].x / 2 + pt[0].x - h], ['y', x * pv[0].y / 2 + y * pv[1].y / 2 + pt[0].y - h]].map(fn$);
        }
      }
      for (i$ = 0; i$ <= 1; ++i$) {
        y = i$;
        for (j$ = 0; j$ <= 1; ++j$) {
          x = j$;
          px = x * pv[0].x + y * pv[1].x + pt[0].x;
          py = x * pv[0].y + y * pv[1].y + pt[0].y;
          vx = px - pc.x;
          vy = py - pc.y;
          len = Math.sqrt(Math.pow(vx, 2) + Math.pow(vy, 2));
          px = px + (len ? vx * s / len - h * r : 0);
          py = py + (len ? vy * s / len - h * r : 0);
          [['x', px], ['y', py], ['width', s * r], ['height', s * r]].map(fn1$);
        }
      }
      mat = (ref$ = this.host.createSVGMatrix(), ref$.a = a, ref$.b = b, ref$.c = c, ref$.d = d, ref$.e = e, ref$.f = f, ref$);
      return this.tgt.map(function(it, i){
        var ref$, a, b, c, d, e, f;
        ref$ = it._mo.inverse().multiply(mat.multiply(it._mo)), a = ref$.a, b = ref$.b, c = ref$.c, d = ref$.d, e = ref$.e, f = ref$.f;
        if (!it._lasttransform) {
          it._lasttransform = it.getAttribute('transform');
        }
        return it.setAttribute('transform', ("matrix(" + a + " " + b + " " + c + " " + d + " " + e + " " + f + ")") + (it._mi ? " matrix(" + ['a', 'b', 'c', 'd', 'e', 'f'].map(function(k){
          return it._mi[k];
        }).join(' ') + ")" : ""));
      });
      function fn$(it){
        return ns[y * 3 + x].setAttribute(it[0], it[1]);
      }
      function fn1$(it){
        return nr[y * 2 + x].setAttribute(it[0], it[1]);
      }
    }
  });
  if (typeof module != 'undefined' && module !== null) {
    module.exports = ldresize;
  } else if (typeof window != 'undefined' && window !== null) {
    window.ldresize = ldresize;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
