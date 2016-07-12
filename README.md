
tcloptics -- this tiny library provides utilities for building and using 'lenses' in Tcl.

-- OVERVIEW --

In its most general form, a lens is a link between two data structures, allowing transformations
applied to one structure to be reflected into transformations on the linked structure. In practice,
many lenses link a data structure to some substructure of itself, in which case lenses can be
seen as glorified getters and setters that operate on nested data structures.

True lenses are also first-class objects that can be composed together to form more complex lenses.

This library attempts to provide a very lightweight implementation of a very restricted class
of lenses for a very restricted class of data structures in Tcl, specifically nested structures
consisting of lists and dictionaries.

Such a lens can be "viewed" to retrieve the value(s) that it targets. It can also be "set" to change the
value that it targets.

Proper first-class lenses are to my knowledge not really possible in Tcl. Here I define a lens
basically as a specification of a path into such a nested structure. For instance, imagine
we have the following structure:

set d [dict create x [list a b [dict create y 1 z 2]]]

We might like to update the value of z to be, say, 3. We can define a lens like so:

set _z [lens [key x] [index 2] [key z]]

We can fetch the value of z using

lens_view d $_z

We can update the value at z using

lens_set d $_z 3

Note that the _z lens can be applied to any nested structure with the same "shape" as d, so
it could potentially be reused in many places in a codebase.

-- COMPOSITION --

Lenses can be composed. For instance, let's say we have positions that are represented with structures
like so:

set pos [dict create lat 1 lon 1 clock 0]

We can create lat and lon lenses:

set _lat [lens [key lat]]
set _lon [lens [key lon]]
set _clock [lens [key clock]]

We might also have some structure which has various properties, including a position:

set inflight [dict create ident X inair 1 lastPos [dict create lat 1 lon 1 clock 0]]

We can have a lastPos lens as well:

set _lastPos [lens [key lastPos]]

Composition of lenses lets us pierce straight into the lat, lon, or clock of an inflight object's last position:

set lastClock [lens_view inflight [lens_compose $_lastPos $_clock]]

-- TRAVERSALS --

Some lenses don't specify single elements in a nested structure but rather a whole collection of elements.

For instance, suppose we have a list of inflight objects, each of which has the same shape as above:

set inflightList [list ...]

We can get a list of all the most recent positions from each object by composing our _lastPos lens
with a special traversal lens called `each`:

set positions [lens_view inflightList [lens_compose each $_lastPos]]

There are two other available primitive traversal lenses:

- `keys`: targets all keys of a dict.
- `values`: targets all values of a dict.

It's not possible to define new primitive traversal lenses as an end-user of the library, but these three
traversal lenses can be composed arbitrarily and in combination with new non-traversal lenses.

-- IMPLEMENTATION --

Lenses themselves are simply paths, so that lens composition is the concatenation of paths.

For instance, _lastPos is really just the list

[list [list key "lastPos"]]

and [lens_compose each $_lastPos] is really just

[list each [list key "lastPos"]].

Likewise [lens_compose $_lastPos $_clock] is just

[list [list key "lastPos"] [list key "clock"]].

`each` and the other traversal lenses are treated as special keywords by the tcloptics library.

Functions like lens_view simply traverse the path as specified. Traversals are implemented by recursively
invoking lens_view using the remainder of the lens and accumulating the results into a list.


