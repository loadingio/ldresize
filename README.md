# ldResize

A simple bounding box widget empowering users with the ability to move, rotate or scale anything. Expected Features:

 * Vanilla JS
 * works both for SVG or HTML ( SVG: ready, HTML: wip )
   - auto parse transform attr/style for extracting current t/r/s.
   - keep the flexibility of working also on Canvas. ( Todo )
 * incudes basic affine transformation
   - can support shear, skew in SVG ? ( Todo )
 * auto transform target, but could also be set to manual
   - then user should do it themselves from values of get-state.


## Usage

```
    # create a new ldr instance.
    ldr = new ldResize ...

    # attach to certain node.
    ldr.attach node

    ldr.on \resize, -> ...
    satate = ldr.get!

    ldr.detach!
```


## Configuration

configs are set in a object which is passed into the ldResize constructor. For example:

```
    new ldResize({root: ".root"});
```

options: 

 * host - css selector or Element. where ldResize puts it's widgets ( ctrl points, bounding box ).
   default root if omitted.
 * root - css selector or Element. where target elements reside. optional.
 * filter(node) - return true if node should be resized. call on mouse down on root element.
 * visible-ctrl-r - should rotating ctrl node be visible.

## API

 * attach(node) - resize node
 * detach() - stop resizing attached node.
 * set({t: {x, y}, s: {x, y}, r}, delta) - set affine transformation for attached node.
   if delta is true, all values in params are relative to current values.
 * get() - get affine transformation data as an object in following format:
   {x, y, w, h, r}
 * on(name, callback(value)) - listen for specific event. currently available events:
     * resize - when resizing. affine transformation data provided.


## Todo
 * Supporting non-preserving-aspect-ratio scaling in group resizing, which needs to deal with shearing.
   - Illustrator just expand the transform into shape. Perhaps it's an feasible approach.

## License

MIT License
