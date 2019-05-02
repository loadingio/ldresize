// Generated by LiveScript 1.3.1
var svg, range, pts, cs, rts, g, b, deg, draw, mouse;
svg = ld$.find(document, '#svg', 0);
range = ld$.create({
  name: 'rect',
  ns: 'svg',
  className: ['range']
});
pts = [0, 1, 2, 3, 4, 5, 6, 7, 8].map(function(d, i){
  return ld$.create({
    name: 'rect',
    ns: 'svg',
    className: ['ctrl', 't'],
    attr: {
      px: i % 3,
      py: Math.floor(i / 3)
    }
  });
});
cs = ['#ff0', '#0ff', '#f0f', '#fff'];
rts = [0, 1, 2, 3].map(function(d, i){
  return ld$.create({
    name: 'rect',
    ns: 'svg',
    className: ['ctrl', 'r'],
    attr: {
      px: 2 * (i % 2),
      py: 2 * Math.floor(i / 2),
      fill: cs[i]
    }
  });
});
g = ld$.create({
  name: 'g',
  ns: 'svg'
});
b = {
  x: 100,
  y: 100,
  a: Math.PI / 4,
  w: 100,
  h: 100
};
deg = function(v){
  return 180 * v / Math.PI;
};
draw = function(){
  var s, h, sw, sh, i$, y, j$, x, lresult$, results$ = [];
  s = 8;
  h = s / 2;
  sw = b.w / 2;
  sh = b.h / 2;
  ld$.attr(range, {
    x: -b.w / 2,
    y: -b.h / 2,
    width: b.w,
    height: b.h
  });
  g.setAttribute('transform', "translate(" + (b.x + b.w / 2) + ", " + (b.y + b.h / 2) + ") rotate(" + deg(b.a || 0) + ")");
  for (i$ = 0; i$ <= 2; ++i$) {
    y = i$;
    for (j$ = 0; j$ <= 2; ++j$) {
      x = j$;
      if ((x === 1 || y === 1) && !(x === 1 && y === 1)) {
        continue;
      }
      ld$.attr(pts[y * 3 + x], {
        x: -b.w / 2 - h + x * sw,
        y: -b.h / 2 - h + y * sh,
        width: s,
        height: s
      });
    }
  }
  for (i$ = 0; i$ <= 1; ++i$) {
    y = i$;
    lresult$ = [];
    for (j$ = 0; j$ <= 1; ++j$) {
      x = j$;
      lresult$.push(ld$.attr(rts[y * 2 + x], {
        x: -b.w / 2 - h * 1.5 + x * b.w + (2 * x - 1) * h,
        y: -b.h / 2 - h * 1.5 + y * b.h + (2 * y - 1) * h,
        width: s * 1.5,
        height: s * 1.5
      }));
    }
    results$.push(lresult$);
  }
  return results$;
};
g.appendChild(range);
rts.map(function(it){
  return g.appendChild(it);
});
pts.map(function(it){
  return g.appendChild(it);
});
svg.appendChild(g);
draw();
mouse = {
  up: function(e){
    document.removeEventListener('mouseup', mouse.up);
    return document.removeEventListener('mousemove', mouse.move);
  },
  move: function(e){
    var ref$, cx, cy, px, py, box, dx, dy, p2, v, len, a, p2p, na, p1, p1p, cp;
    ref$ = [e.clientX, e.clientY, mouse.px, mouse.py], cx = ref$[0], cy = ref$[1], px = ref$[2], py = ref$[3];
    box = svg.getBoundingClientRect();
    if (px === 1 && py === 1) {
      ref$ = [cx - mouse.ix, cy - mouse.iy], dx = ref$[0], dy = ref$[1];
      b.x += dx;
      b.y += dy;
      mouse.ix = cx;
      mouse.iy = cy;
      draw();
      return;
    }
    if (mouse.n.classList.contains('r')) {
      p2 = [b.x + b.w * px / 2, b.y + b.h * py / 2];
      v = [p2[0] - b.x - b.w / 2, p2[1] - b.y - b.h / 2];
      len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
      a = Math.acos(v[0] / len);
      if (v[1] < 0) {
        a = 2 * Math.PI - a;
      }
      a += b.a;
      p2p = [cx - box.x, cy - box.y];
      v = [p2p[0] - b.x - b.w / 2, p2p[1] - b.y - b.h / 2];
      len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
      na = Math.acos(v[0] / len);
      if (v[1] < 0) {
        na = 2 * Math.PI - na;
      }
      b.a = b.a + (na - a);
    }
    if (mouse.n.classList.contains('t')) {
      p1 = [b.x + b.w * (2 - px) / 2, b.y + b.h * (2 - py) / 2];
      p2 = [b.x + b.w * px / 2, b.y + b.h * py / 2];
      v = [b.w * (1 - px) / 2, b.h * (1 - py) / 2];
      len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
      a = Math.acos(v[0] / len);
      if (v[1] < 0) {
        a = 2 * Math.PI - a;
      }
      a += b.a;
      p1p = [b.x + b.w / 2 + len * Math.cos(a), b.y + b.h / 2 + len * Math.sin(a)];
      p2p = [cx - box.x, cy - box.y];
      cp = [(p1p[0] + p2p[0]) / 2, (p1p[1] + p2p[1]) / 2];
      v = [p2p[0] - cp[0], p2p[1] - cp[1]];
      len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
      a = Math.acos(v[0] / len);
      if (v[1] < 0) {
        a = 2 * Math.PI - a;
      }
      a -= b.a;
      p2 = [cp[0] + len * Math.cos(a), cp[1] + len * Math.sin(a)];
      v = [p1p[0] - cp[0], p1p[1] - cp[1]];
      len = Math.sqrt(v[0] * v[0] + v[1] * v[1]);
      a = Math.acos(v[0] / len);
      if (v[1] < 0) {
        a = 2 * Math.PI - a;
      }
      a -= b.a;
      p1 = [cp[0] + len * Math.cos(a), cp[1] + len * Math.sin(a)];
      if (px === 0) {
        ref$ = [(ref$ = p1[0] - p2[0]) > 0 ? ref$ : 0, p2[0]], b.w = ref$[0], b.x = ref$[1];
      }
      if (py === 0) {
        ref$ = [(ref$ = p1[1] - p2[1]) > 0 ? ref$ : 0, p2[1]], b.h = ref$[0], b.y = ref$[1];
      }
      if (px === 2) {
        ref$ = [(ref$ = p2[0] - p1[0]) > 0 ? ref$ : 0, p1[0]], b.w = ref$[0], b.x = ref$[1];
      }
      if (py === 2) {
        ref$ = [(ref$ = p2[1] - p1[1]) > 0 ? ref$ : 0, p1[1]], b.h = ref$[0], b.y = ref$[1];
      }
    }
    return draw();
  },
  down: function(e){
    var n, ref$, px, py;
    if (!(n = ld$.parent(e.target, '.ctrl', svg))) {
      return;
    }
    document.addEventListener('mouseup', mouse.up);
    document.addEventListener('mousemove', mouse.move);
    ref$ = ['px', 'py'].map(function(k){
      return +n.getAttribute(k);
    }), px = ref$[0], py = ref$[1];
    return mouse.ix = e.clientX, mouse.iy = e.clientY, mouse.px = px, mouse.py = py, mouse.n = n, mouse;
  }
};
svg.addEventListener('mousedown', mouse.down);