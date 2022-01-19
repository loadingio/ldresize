# ldresize

A simple bounding box widget empowering users with the ability to move, rotate or scale anything.


## Usage

    # create a new ldr instance.
    ldr = new ldresize ...

    # attach to certain node.
    ldr.attach node

    ldr.on \resize, -> ...
    state = ldr.get!

    ldr.detach!


## Configuration

configs are set in a object which is passed into the ldresize constructor. For example:

    new ldresize({root: ".root"});


## Configuration

 * `host` - CSS selector or element where to put resize widget elements. will use `root` if `host` is omitted.
 * `root` - CSS selector or element for the container of the elements to be resized.
   ldresize automatically intercept mouse events for elements in `root` and handle the interactions.
 * `filter(n)` - callback function to determine if an element `n` should be resized.
   ldresize by default resizes all elements if filter is omitted.
   called on mousedown on root element.
 * `mousedown` - TBD
 * `visible-ctrl-r` - default false. show all rotating ctrl node if true.


## API

 * `attach(n,append)`: attach resizer to certain node(s) and show resize widget.
   - `n`: node(s) to be attached. can be a list or a single node. equivalent to detech if n = null.
   - `append`: default false. append n to current attached list if true.
 * `detect()`: clear attached list and hide resize widget.
 * `render()`: update transformation of resize widget and attached nodes.
 * `pts`: internal api ( TBD )
 * `box-offset`: internal api ( TBD )
 * `get()`: return an object representing transformation information as follow:
   - `t`: {x, y} - translate
   - `s`: {x, y} - scale
   - `r`: rotate
   - `x, y, w, h`: Bounding Rect. ( TBD? )
   - `box`: TBD
 * `on(name, cb)`: handle specific event `name` with function `cb`.

### API ( WIP )
 * `set({t`: {x, y}, s: {x, y}, r}, delta): set affine transformation for attached node. ( No Yet Implemented )
   if delta is true, all values in params are relative to current values.


## Events

 * `resize`: fire when resizing ( including translating, rotating and scaling ). arguments:
   - `dim`: transformation information. see `get` API for more information.
   - `targets`: list of affected nods


## Widget Hierarchy

ldresize will add a set of SVG elements for controlling the resize of any elements. This reizer widget is constructed with following structure:

 * g
   - path.ldr-ctrl.bbox
   - rect.ldr-ctrl.r x 4
   - rect.ldr-ctrl.s x 9


## CSS Classes Used

 * `ldr-host` - host element
   - `ldr-host-standalone` - added on host element if root != host
 * `ldr-ctrl` - control points
   - `r` - ctrl points for rotating
   - `s` - ctrl points for resizing
   - `bbox` - wireframe of the resize rectangle


## Technical Note

 * Additional interface:
   * `node._lasttransform` - old transform attribute will be stored in this attribute of specific node when ldresize is going to overwrite it.
     - currently, this is only done when _lasttransform is undefined.
     - TODO: add opt for customize attr name and store timing?
 * ldresize store transformation matrix for both parent and node in `_mo` and `_mi` member of an element. Also, old transform info is stored in `_lasttransform`. This is somewhat hacky, maybe we can find a better way to replace these in the future.


## Todo

 * Supporting non-preserving-aspect-ratio scaling in group resizing, which needs to deal with shearing.
   - Illustrator just expand the transform into shape. Perhaps it's an feasible approach.
 * should we provide API for customizing before ldresize applying transformation over attached nodes?
 * Support HTML
   - currently we use features from SVG, such as SVGMatrix, node.transform.baseVal, etc so we don't support HTML.
 * make `root` optional ( is this necessary? )
 * resizing might lead to distortion. try to support resizing that is actually updating position of the underlying points, or only the input box ( e.g., for text box resizing )

Expected Features:

 * Vanilla JS
 * works both for SVG or HTML ( SVG: ready, HTML: wip )
   - auto parse transform attr/style for extracting current t/r/s.
   - keep the flexibility of working also on Canvas. ( Todo )
 * incudes basic affine transformation
   - can support shear, skew in SVG ? ( Todo )
 * auto transform target, but could also be set to manual
   - then user should do it themselves from values of get-state.


## License

MIT License
