# **Lists** are ordered lists of objects. The base `List` implementation
# is pretty simple; one can add and remove elements to and from it, and
# it will emit added/removed events with (item, idx) params.

{ Base } = require('../core/base')
{ Varying } = require('../core/varying')
{ OrderedMappable } = require('./collection')
util = require('../util/util')


# We derive off of Model so that we have free access to attributes.
class List extends OrderedMappable
  isList: true

  # We take a list of elements, and initialize to empty list if nothing is given.
  constructor: (list = [], options) ->
    # super first so Model stuff and _initialize gets set up before initial add.
    this._parent = options.parent if options?.parent?
    super({}, options)
    this._initialize?()

    # Init our list, and add the items to it.
    this.list = []
    this.add(list)

  # Add one or more items to this collection. Optionally takes a second `index`
  # arg defining where in the list all the items should be spliced in at.
  add: (elems, idx = this.list.length) ->
    # Normalize the argument to an array, then dump in our items.
    elems = [ elems ] unless util.isArray(elems)
    if idx is this.list.length and elems.length is 1
      this.list.push(elems[0]) # for perf. matters a lot in big batches.
    else
      if idx > this.list.length # as with #put, this will make splice behave correctly.
        this.list[idx - 1] = null
        delete this.list[idx - 1]
      Array.prototype.splice.apply(this.list, [ idx, 0 ].concat(elems))

    for elem, subidx in elems
      # fire events:
      this.emit('added', elem, idx + subidx) 
      elem?.emit?('addedTo', this, idx + subidx)

      # If the item is destroyed, automatically remove it from our collection.
      if util.isFunction(elem?.destroy) and (this.isDerivedList isnt true)
        (do (elem) => this.listenTo(elem, 'destroying', => this.remove(elem)))

    return

  # Sets a single value at a given index. Emits events as appropriate.
  set: (idx, value) ->
    idx = this.length + idx if idx < 0

    if 0 <= idx and idx < this.length
      removed = this.list[idx]
      this.emit('removed', removed, idx)
      removed?.emit?('removedFrom', this, idx)

    this.list[idx] = value
    this.emit('added', value, idx)
    value?.emit?('addedTo', this, idx)
    return

  # Removes one item from the collection by reference and returns it.
  remove: (which) ->
    idx = this.list.indexOf(which)
    return undefined unless idx >= 0
    this.removeAt(idx)

  # Removes one item from the collection by index and returns it.
  removeAt: (idx) ->
    idx = this.list.length + idx if idx < 0
    return if idx < 0 or idx >= this.list.length

    removed = # perf. matters a lot in big batches.
      if idx is 0
        this.list.shift()
      else if idx is this.list.length - 1
        this.list.pop()
      else
        this.list.splice(idx, 1)[0]

    this.emit('removed', removed, idx)
    removed?.emit?('removedFrom', this, idx)
    removed

  # Move an item by reference to an index in the collection. This will trigger
  # `moved` events for only the shifted element. But, it will give the new and
  # old indices so that ranges can be correctly dealt with if necessary.
  #
  # Does _not_ trigger `add` or `remove` events.
  move: (elem, idx) ->
    # If we don't already know about the element, bail.
    oldIdx = this.list.indexOf(elem)
    return unless oldIdx >= 0

    this.moveAt(oldIdx, idx)

  # Same as move, but by index rather than element reference.
  moveAt: (oldIdx, idx) ->
    oldIdx = this.length + oldIdx if oldIdx < 0
    idx = this.length + idx if idx < 0
    elem = this.list[oldIdx]

    # Move the element, then trigger `moved` event.
    this.list.splice(oldIdx, 1)
    this.list.splice(idx, 0, elem)

    this.emit('moved', elem, idx, oldIdx)
    elem?.emit?('movedIn', this, idx, oldIdx)

    elem

  # Removes and returns (as array) all elements from a collection.
  removeAll: ->
    while this.list.length > 0
      elem = this.list.shift()
      this.emit('removed', elem, 0)
      elem?.emit?('removedFrom', this, 0)
      elem

  # Get an element from this collection by index.
  _at = (idx) ->
    if idx >= 0
      this.list[idx]
    else
      this.list[this.list.length + idx]
  at: _at
  get: _at

  # Watch an element from this collection by index.
  _watchAt = (idx) ->
    if idx?.isVarying is true
      return idx.flatMap((tidx) => this.watchAt(tidx))

    result = new Varying(this.at(idx))

    this.listenTo(this, 'added', (elem, midx) =>
      if idx is midx
        result.set(elem)
      else if (idx > 0) and (midx < idx)
        result.set(this.at(idx))
      else if (idx < 0) and (midx >= (this.list.length + idx))
        result.set(this.at(idx))
    )

    this.listenTo(this, 'moved', (elem, newIdx, oldIdx) =>
      tidx = if idx < 0 then this.list.length + idx else idx
      if tidx is newIdx
        result.set(elem)
      else if tidx is oldIdx
        result.set(this.at(tidx))
      else if tidx > oldIdx and tidx < newIdx
        result.set(this.at(tidx))
      else if tidx < oldIdx and tidx > newIdx
        result.set(this.at(tidx))
    )

    this.listenTo(this, 'removed', (_, midx) =>
      if (idx >= 0) and (midx <= idx)
        result.set(this.at(idx))
      else if (idx < 0) and (midx >= (this.list.length + idx))
        result.set(this.at(idx))
    )

    result
  watchAt: _watchAt
  watch: _watchAt

  # Length-related operations. .length is presented as a getter for familiarity.
  Object.defineProperty(@prototype, 'length', get: -> this.list.length)
  watchLength: ->
    this.watchLength$ ?= Varying.managed((-> new Base()), (listener) =>
      result = new Varying(this.list.length)

      listener.listenTo(this, 'added', => result.set(this.list.length))
      listener.listenTo(this, 'removed', => result.set(this.list.length))

      result
    )

  # Length-related convenience methods, since these maps happen a lot:
  empty: -> this.length is 0
  watchEmpty: -> this.watchLength().map((length) -> length is 0)
  nonEmpty: -> this.length > 0
  watchNonEmpty: -> this.watchLength().map((length) -> length > 0)

  # A shadow list is really just a clone that has a backreference so that we
  # can determine later if it has changed. We could copy-on-write, but that
  # seems like an unpredictable behaviour to build against.
  #
  # We also shadow all Models we contain at time-of-copy. This is really the
  # primary reason we implement shadow; so that when a Model is shadowed the
  # entire data tree does so with it.
  shadow: ->
    newArray =
      for item in this.list
        if item?.isEnumerable is true
          item.shadow()
        else
          item

    new this.constructor(newArray, { parent: this })

  # allow ES iterators but only if ES5+ is actually present.
  if typeof Symbol isnt 'undefined'
    @.prototype[Symbol.iterator] = -> this.list[Symbol.iterator]()

  @deserialize: (data) ->
    items =
      if this.modelClass? and util.isFunction(this.modelClass.deserialize)
        this.modelClass.deserialize(datum) for datum in data
      else
        data

    new this(items)

  @of: (modelClass) -> class extends this
    @modelClass: modelClass

class DerivedList extends List
  isDerivedList: true

  constructor: ->
    # still call Base to set up important things, but skip List constructor as
    # it tries to add the initial items.
    OrderedMappable.call(this)
    this.list = []
    this._initialize?()

  roError = -> throw new Error('this list is read-only')

  for method in [ 'add', 'remove', 'removeAt', 'removeAll', 'set', 'move', 'moveAt' ]
    this.prototype["_#{method}"] = this.__super__[method]
    this.prototype[method] = roError

  shadow: -> this

# also export under List:
List.Derived = DerivedList

module.exports = { List, DerivedList }

