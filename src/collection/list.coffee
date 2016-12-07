# **Lists** are ordered lists of objects. The base `List` implementation
# is pretty simple; one can add and remove elements to and from it.
#
# **Events**:
#
# - `added`: `(item, idx)` the item that was added and its position.
# - `removed`: `(item, idx)` the item that was removed and its position.
#
# **Member Events**:
#
# - `addedTo`: `(collection, idx)` this collection and the member's position.
# - `removedFrom`: `(collection, idx)` this collection and the member's
#   position.

Base = require('../core/base').Base
Varying = require('../core/varying').Varying
OrderedCollection = require('./collection').OrderedCollection
Model = require('../model/model').Model
util = require('../util/util')


# We derive off of Model so that we have free access to attributes.
class List extends OrderedCollection

  # We take a list of elements, and initialize to empty list if nothing is given.
  constructor: (list = [], options) ->
    # super first so Model stuff and _initialize gets set up before initial add.
    super({}, options)

    # Init our list, and add the items to it.
    this.list = []
    this.add(list)

  # Add one or more items to this collection. Optionally takes a second `index`
  # parameter indicating what position in the list all the items should be
  # spliced in at.
  #
  # **Returns** the added items as an array.
  add: (elems, idx = this.list.length) ->
    # Normalize the argument to an array, then dump in our items.
    elems = [ elems ] unless util.isArray(elems)
    elems = this._processElements(elems)
    if idx is this.list.length and elems.length is 1
      this.list.push(elems[0]) # for perf. matters a lot in big batches.
    else
      if idx > this.list.length # as with #put, this will make splice behave correctly.
        this.list[idx - 1] = null
        delete this.list[idx - 1]
      Array.prototype.splice.apply(this.list, [ idx, 0 ].concat(elems))

    for elem, subidx in elems
      # Event on ourself for each item we added
      this.emit('added', elem, idx + subidx) 

      # Event on the item for each item we added
      elem?.emit?('addedTo', this, idx + subidx)

      # If the item is destroyed, automatically remove it from our collection.
      (do (elem) => this.listenTo(elem, 'destroying', => this.remove(elem))) if elem?.isBase is true

    elems

  # Remove one item from the collection. Takes a reference to the element
  # to be removed.
  #
  # **Returns** the removed member.
  remove: (which) ->
    idx = this.list.indexOf(which)
    return undefined unless idx >= 0
    this.removeAt(idx)

  # Remove one item from the collection. Takes a reference to the element
  # to be removed.
  #
  # **Returns** the removed member.
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

  # Move an item to an index in the collection. This will trigger `moved`
  # events for only the shifted element. But, it will give the new and old
  # indices so that ranges can be correctly dealt with if necessary.
  #
  # Does _not_ trigger `add` or `remove` events.
  move: (elem, idx) ->

    # If we don't already know about the element, bail.
    oldIdx = this.list.indexOf(elem)
    return unless oldIdx >= 0

    this.moveAt(oldIdx, idx)

  # Same as move, but by index rather than element reference.
  moveAt: (oldIdx, idx) ->
    elem = this.list[oldIdx]

    # Move the element, then trigger `moved` event.
    this.list.splice(oldIdx, 1)
    this.list.splice(idx, 0, elem)

    this.emit('moved', elem, idx, oldIdx)
    elem?.emit?('movedIn', this, idx, oldIdx)

    elem

  # Removes all elements from a collection.
  #
  # **Returns** the removed elements.
  removeAll: ->
    while this.list.length > 0
      elem = this.list.shift()
      this.emit('removed', elem, 0)
      elem?.emit?('removedFrom', this, 0)
      elem

  # Get an element from this collection by index.
  at: (idx) ->
    if idx >= 0
      this.list[idx]
    else
      this.list[this.list.length + idx]

  # Watch an element from this collection by index.
  watchAt: (idx) ->
    if idx?.isVarying is true
      return idx.flatMap((tidx) => this.watchAt(tidx))

    result = new Varying(this.at(idx))

    this.on('added', (elem, midx) =>
      if idx is midx
        result.set(elem)
      else if (idx > 0) and (midx < idx)
        result.set(this.at(idx))
      else if (idx < 0) and (midx >= (this.list.length + idx))
        result.set(this.at(idx))
    )

    this.on('moved', (elem, newIdx, oldIdx) =>
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

    this.on('removed', (_, midx) =>
      if (idx >= 0) and (midx <= idx)
        result.set(this.at(idx))
      else if (idx < 0) and (midx >= (this.list.length + idx))
        result.set(this.at(idx))
    )

    result

  # Provide something that looks like a normal length getter:
  Object.defineProperty(@prototype, 'length', get: -> this.list.length)


  # Watch the length of this collection.
  watchLength: ->
    result = new Varying(this.list.length)

    this.on('added', -> result.set(this.list.length))
    this.on('removed', -> result.set(this.list.length))

    result

  # Set an index of this collection to the given member.
  #
  # This is internally modelled as if the previous item at the index was removed
  # and the new one was added in succession, but without the later members of
  # the collection slipping around.
  #
  # **Returns** the replaced element, if any.
  put: (list, idx) ->
    # normalize input.
    list = [ list ] unless util.isArray(list)

    # If nothing yet exists at the target, populate it with null so that splice
    # does the right thing.
    if idx > this.list.length
      this.list[idx] = null
      delete this.list[idx]

    # Actually process and splice in the elements.
    list = this._processElements(list)
    removed = this.list.splice(idx, list.length, list...)

    # Event on removals
    for elem, subidx in removed# when elem? # TODO: this seems wrong, but why was it here?
      this.emit('removed', elem, idx + subidx)
      elem?.emit?('removedFrom', this, idx + subidx)

    # Event on additions
    for elem, subidx in list
      this.emit('added', elem, idx + subidx)
      elem?.emit?('addedTo', this, idx + subidx)

    removed

  # Somewhat smartly resets the entire list to a new one. Does a merge of the
  # two such that adds/removes are limited.
  putAll: (list) ->
    # first remove all existing models that should no longer exist.
    (this.remove(elem) unless list.indexOf(elem) >= 0) for elem in this.list.slice()

    # now go through each elem one at a time and add or move as necessary.
    for elem, i in list
      continue if this.list[i] is elem

      oldIdx = this.list.indexOf(elem)
      if oldIdx >= 0
        this.move(elem, i)
      else
        this.add(this._processElements([ elem ])[0], i)

    # return the list that was set.
    list

  # A shadow list is really just a clone that has a backreference so that we
  # can determine later if it has changed. We could copy-on-write, but that
  # seems like an unpredictable behaviour to build against.
  #
  # We also shadow all Models we contain at time-of-copy.
  #
  # **Returns** a copy of this list with its parent reference set.
  shadow: ->
    newArray =
      for item in this.list
        if item?.isModel is true
          item.shadow()
        else
          item

    new this.constructor(newArray, { parent: this })

  # Check if our list has changed relative to its shadow parent.
  #
  # **Returns** true if we have been modified.
  modified: (deep) ->
    return false unless this._parent?
    return true if this._parent.list.length isnt this.list.length

    isDeep =
      if !deep?
        true
      else if util.isFunction(deep)
        deep(this)
      else
        deep is true

    for value, i in this.list
      parentValue = this._parent.list[i]

      if value instanceof Model
        return true unless parentValue in value.originals()
        return true if isDeep is true and value.modified(deep)
      else
        return true if parentValue isnt value and !(!parentValue? and !value?)

    return false

  # Watches whether our List has changed relative to our original.
  #
  # **Returns** Varying[Boolean] indicating modified state.
  watchModified: (deep) ->
    return new Varying(false) unless this._parent?

    isDeep =
      if !deep?
        true
      else if util.isFunction(deep)
        deep(this)
      else
        deep is true

    if isDeep is true
      this._watchModifiedDeep$ ?= do =>
        result = new Varying(this.modified(deep))

        react = => result.set(this.modified(deep))

        this.on('added', react)
        this.on('removed', react)
        this.on('moved', react)

        watching = {}
        watchModel = (model) =>
          watching[model._id] = model.watchModified(deep).react((isChanged) ->
            if isChanged is true
              result.set(true)
            else
              react()
          )

        uniqSubmodels = this.filter((elem) -> elem instanceof Model).uniq()
        watchModel(model) for model in uniqSubmodels.list
        uniqSubmodels.on('added', (newModel) -> watchModel(newModel))
        uniqSubmodels.on('removed', (oldModel) -> watching[oldModel._id]?.stop?())

        result

    else
      this._watchModified$ ?= do =>
        result = new Varying(this.modified(deep))

        react = =>
          if this.list.length isnt this._parent.list.length
            result.set(true)
          else
            result.set(this.modified(deep))

        this.on('added', react)
        this.on('removed', react)

        result

  # Handles elements as they're added. Returns possibly the same array of
  # possibly the same elements, to be added.
  #
  # **Returns** Array[obj] of objects to be added.
  _processElements: (elems) ->
    for elem in elems
      if this._parent?
        if elem?.isModel is true
          elem.shadow()
        else
          elem
      else
        elem

  @deserialize: (data) ->
    items =
      if this.modelClass? and (this.modelClass.prototype.isModel is true or this.modelClass.prototype.isCollection is true)
        this.modelClass.deserialize(datum) for datum in data
      else
        data.slice()

    new this(items)

  @serialize: (list) ->
    for child in list.list
      if child?.serialize?
        child.serialize()
      else
        child

class DerivedList extends List
  for method in [ 'add', 'remove', 'removeAt', 'removeAll', 'put', 'putAll', 'move', 'moveAt' ]
    this.prototype["_#{method}"] = this.__super__[method]
    this.prototype[method] = (->)

  shadow: -> this


module.exports = { List, DerivedList }

