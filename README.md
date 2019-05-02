# ldResize

A simple bounding box widget empowers users with the ability to move, rotate or scale anything. Expected Features:

 * Vanilla JS
 * works both for HTML or SVG
   - auto parse transform attr/style for extracting current t/r/s.
   - keep the flexibility of working also on Canvas.
 * incudes basic affine transformation
   - can support shear, skew in SVG ?
 * auto transform target, but could also be set to manual
   - then user should do it themselves from values of get-state.


## Usage

```
    # create a new ldr instance.
    ldr = new ldResize ...

    # attach to certain node.
    ldr.attach node

    ldr.on \change, -> ...
    ldr.get-state # return {t: {x, y, z}, r, s: {x, y}}

    ldr.detach!
```


## License

MIT License
