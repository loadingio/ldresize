## Affine Transformation Convertion

To do some affine transformation over an object, we could:

    translate(tx ty)
    translate(cx cy)
    rotate(r)
    scale(sx sy)
    translate(-cx -cy)

where [cx, cy] = central point, [tx,ty] for translation, [sx,sy] for scaling, r for rotation.


to calculate a transformation matrix, we multiply matrices for above transformations one by one and get:

    a = [sx * cos(r)]  c = [-sy * sin(r)]  e = [-sx * cx * cos(r) + sy * cy * sin(r) + cx + tx]
    b = [sx * sin(r)]  d = [ sy * cos(r)]  f = [-sx * cx * sin(r) - sy * cy * cos(r) + cy + ty]
        [    0      ]      [     0      ]      [                    1                         ]


To restore [tx, ty], [sx, sy], [r] from [a,b,c,d,e,f] and [cx, cy], we can do following:

    sx = a^2 + b^2
    sy = c^2 + d^2
    r = acos(a / sx)
    tx = e + sx * cx * cos(r) - sy * cy * sin(r) - cx
    ty = f + sy * cy * sin(r) + sy * cy * cos(r) - cy


## Transformation 

SVG node can be nested. For example:

    g(transform=mo): path(transform=mi)

we want to do affine transformation over path. It will be like:

    g(transform=mo): path(transform = mc x mi)

Or, if mi can be parsed as an affine transformation:

    g(transform=mo): path(transform = mc)

where mc is the target affine transformation. For simplicity, we try to escape mc from mo:

    mo x mc = mc' x mo
    mc' = mo x mc x inv(mo)


then, we can simply apply mc' in path like:

    g(transform=mo): path(transform = mc)
    g(transform=mo): path(transform = inv(mo) x mc' x mo)

as you can see, this is then equivalent to:

    path(transform = mc' x mo)

where we can work with mc' to make translation, roation and scaling; we just have to get the initial value for them with above formula: 

    [a,b,c,d,e,f] = mc' = mo x mc x inv(mo)
    sx = a^2 + b^2
    sy = c^2 + d^2
    r = acos(a / sx)
    tx = e + sx * cx * cos(r) - sy * cy * sin(r) - cx
    ty = f + sy * cy * sin(r) + sy * cy * cos(r) - cy


### Skewed Transformation

Sometimes the transformation mc' is just skewed and contains additional variable other than t,s,r; this can be verified by comparing c, d with the computed sx, sy and r:

  (c - sy * -sin(r))^2 + (d - sx * cos(r))^2 < threshold if it contains no skew.


if skew exits, we try again with following config:

    g(transform=mo): path(transform = mi0 x mi')

if there are multiple matrices in mi where mi = mi0 x mi'. this time we'll use mi0 as mc and repeat the above calculation to see if it's a valid affine transformation, otherwise we will use identity matrix as a new mc.


### Rendering

to render a node with mc, we simply restore 

    path(transform = mc' x mo x mi')
    g(transform=mo): path(transform = inv(mo) x mc' x mo x mi')
  = g(transform=mo): path(transform = inv(mo) x mo x mc x inv(mo) x mo x mi')
  = g(transform=mo): path(transform = mc x mi')

since g(transform=mo) already exists, we use following sequence to transform a node:

  inv(mo) x mc' x mo x mi'

