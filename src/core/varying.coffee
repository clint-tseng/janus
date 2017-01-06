# `Varying` is a monad. Don't worry about the m-word. All it means here is that
# it has facilities to help you handle state, and chaining stateful consequences
# together without sacrificing the functional purity of userland code.
#
# For more philosophy on `Varying`, please see the documentation.
#
# Internally, `Varying` operates as follows:
# * `map` returns a new `Varying`, but all that is really returned is the new
#   monad recording the composition of the existing `Varying` and a pure function.
#   Once the computation is activated, it of course applies the function to the
#   value any time the original value changes, and wraps the result.
# * `flatten` takes a wrapped `Varying` and flattens it down. As with `map`,
#   this is entirely a passive action at first. The one trick with `flatten` is
#   that if the inner value is a `Varying`, the outer one being flattened will
#   itself update to track the inner value.
# * `flatMap` is a composition of the two, but:
#
# `map` and `flatten` are actually implemented in terms of `flatMap`. In fact,
# `flatMap` is implemented in the `FlatMappedVarying` class below. It simply
# has some non-exposed toggles to turn on and off flattening behaviour, and it
# presumes a mapping function of `identity` if not given.
#
# The other tricky implementation detail is `::pure`. This is also largely
# implemented in terms of `flatMap`, for the sake of exposing the same mapping
# and flattening behaviour without duplicating code, but has a different binding
# to its parent, which first gathers all the applicants' values and applies them
# before handing the single value back to the normal `Varying` machinery.
#
# Both bindings, the `Varying` and the `ComposedVarying` implementations cache
# the binding to the parent, and only listen once to them for every map or
# reaction bound outward. We use refcounting to manage this.

{ isFunction, fix, uniqueId } = require('../util/util')


class Varying
  # flag to enable duck-typed detection of this class. thanks, npm.
  isVarying: true

  constructor: (value) ->
    this.set(value) # immediately set our internal value.
    this._observers = {} # track our observers so we can notify on change.
    this._refCount = 0

    this._generation = 0 # keeps track of which propagation cycle we're on.

  # (Varying v) => v a -> (a -> b) -> v b
  map: (f) -> new MappedVarying(this, f)

  # (Varying v) => v v a -> v a
  flatten: -> new FlattenedVarying(this)

  # (Varying v) => v a -> (a -> v b) -> v b
  flatMap: (f) -> new FlatMappedVarying(this, f)

  # returns the `Varied` representing this reaction.
  # (Varying v, Varied w) => v a -> (a -> ()) -> w
  react: (f_) ->
    id = uniqueId()
    this._refCount += 1
    this.refCount$?.set(this._refCount)

    this._observers[id] = new Varied(id, f_, =>
      delete this._observers[id]
      this._refCount -= 1
      this.refCount$?.set(this._refCount)
    )

  # (Varying v, Varied w) => v a -> (a -> ()) -> w
  reactNow: (f_) ->
    varied = this.react(f_)
    f_.call(varied, this.get())
    varied

  # gets and stores a value, and triggers any reactions upon it. returns nothing.
  # impure! (Varying v) => v a -> b -> ()
  set: (value) ->
    return if value is this._value

    generation = this._generation += 1
    this._value = value

    for _, observer of this._observers
      observer.f_(this._value)
      return if generation isnt this._generation # we've re-triggered setValue. abort.

    null

  # (Varying v) => v a -> a
  get: -> this._value

  # (Varying v, Int b) => v a -> v b
  refCount: -> this.refCount$ ?= new Varying(this._refCount)

  # we have two very similar behaviours, `pure` and `flatMapAll`, that differ only
  # in a parameter passed to the returned class. so we implement it once and
  # partially apply with that difference immedatiely.
  _pure = (flat) -> (args...) ->
    if isFunction(args[0]) and not args[0].react?
      f = args[0]

      (fix (curry) -> (args) ->
        if args.length < f.length
          (more...) -> curry(args.concat(more))
        else
          new ComposedVarying(args, f, flat)
      )(args.slice(1))
    else # TODO: can't we curry here too until we see a function?
      f = args.pop()
      new ComposedVarying(args, f, flat)

  # overloaded, flexible argument count a/b/c/d/etc:
  # (Varying v) => (a -> b -> c) -> v a -> v b -> v c
  # (Varying v) => v a -> v b -> (a -> b -> c) -> v c
  @pure: _pure(false)

  # Synonym for `pure`, in case it's too haskell-y for people to understand.
  @mapAll: @pure

  # overloaded, flexible argument count a/b/c/d/etc:
  # (Varying v) => (a -> b -> v c) -> v a -> v b -> v c
  # (Varying v) => v a -> v b -> (a -> b -> v c) -> v c
  @flatMapAll: _pure(true)

  @managed: (resources..., computation) -> new ManagedVarying(resources, computation)

  # convenience constructor to ensure a Varying. wraps nonVaryings, and returns
  # Varyings given to it.
  # (Varying v) => a -> v a
  @ly: (x) -> if x?.isVarying is true then x else new Varying(x)

class Varied
  constructor: (@id, @f_, @_stop) ->
  stop: ->
    this.stopped = true # for debugging.
    this._stop()

identity = (x) -> x
nothing = {}

class FlatMappedVarying extends Varying
  constructor: (@_parent, @_f = identity, @_flatten = true) ->
    this._observers = {}
    this._internalObservers = {}
    this._refCount = 0

  _react = (self, callback, immediate) ->
    # create the consumer Varied that will be returned.
    id = uniqueId()
    self._observers[id] = varied = new Varied(id, callback, ->
      delete self._observers[id]

      self._refCount -= 1
      if self._refCount is 0
        self._lastInnerVaried?.stop()
        self._parentVaried.stop()
      self.refCount$?.set(self._refCount)
    )

    # onValue is the handler called for both the parent changing _as well as_
    # an inner flattened value changing.
    ignoreFirst = true
    onValue = (value) ->
      if self._flatten is true and this is self._parentVaried
        # unbind old and bind to new if applicable.
        self._lastInnerVaried?.stop()
        if value?.isVarying is true
          self._lastInnerVaried = value.reactNow(onValue)
          return # don't run the below, since reactNow will update the value.
        else
          self._lastInnerVaried = null

      # don't bail until we've unlistened/relistened to the container result.
      return if value is self._lastValue
      self._lastValue = value

      unless immediate is false and ignoreFirst is true
        # we always call onValue immediately; so we don't want to notify if
        # this is our first trip and immediate is false.
        generation = (self._generation += 1)
        o.f_(value) for _, o of self._observers when generation is self._generation

      null

    if self._refCount is 0
      self._lastValue = nothing
      self._lastInnerVaried = null
      self._generation = 0
      self._parentVaried = self._bind(onValue) 

    # increment and update refcount only after we've bound, but before we call
    # immediate in case we have eg a managed varying.
    initialGeneration = self._generation
    self._refCount += 1
    self.refCount$?.set(self._refCount)

    # the only cases we can ignore the initial value are nonflat nonimmediates,
    # or if someone has already fired our bound listener within refcount.
    if (self._generation is initialGeneration) and (self._flatten is true or immediate is true)
      if self._lastValue is nothing
        onValue.call(self._parentVaried, self._immediate())
      else
        callback.call(varied, self._lastValue)

    ignoreFirst = false
    varied

  # with the normal Varying, we simply reactNow and call get() for the immediate
  # callback. this gets really tricky with flatten, because an extant Varying won't
  # be correctly bound to with that method when reactNow gets called. so we override
  # the default implementation and parameterize react to handle it internally if
  # necessary.
  # TODO: there is an open question as to whether reactNow should be the only api.
  react: (f_) -> _react(this, f_, false)
  reactNow: (f_) -> _react(this, f_, true)

  # actually listens to the parent(s) and returns the Varied that represents it.
  #
  # mapping is handled here because the implementation of applying it varies depending
  # on whether there is one parent or many.
  _bind: (callback) -> this._parent.react((raw) => callback.call(this._parentVaried, this._f.call(null, raw)))

  # used internally; essentially get() w/out flatten.
  _immediate: -> this._f.call(null, this._parent.get())

  # can't set a derived varying.
  set: null

  # gets immediate, then flattens if we should.
  get: ->
    result = this._immediate()
    if this._flatten is true and result?.isVarying is true
      result.get()
    else
      result

class FlattenedVarying extends FlatMappedVarying
  constructor: (parent) -> super(parent)

class MappedVarying extends FlatMappedVarying
  constructor: (parent, f) -> super(parent, f, false)


# ComposedVarying has some odd implications. It's not valid to apply our map
# without all the values present, and trying to fulfill that kind of interface
# leads to huge oddities with side effects and call orders.
# So, we always reactNow on our parents, even if we simply are reacted.
class ComposedVarying extends FlatMappedVarying
  constructor: (@_applicants, @_f = identity, @_flatten = false) ->
    this._observers = {}
    this._refCount = 0

    this._partial = [] # track the current mapping arguments.
    this._parentVarieds = [] # track our observers watching for mapping arguments.

  # as noted above, we reimplement here because there are many parents, and we
  # have to implement the mapping application differently.
  _bind: (callback) ->
    # listen to all our parents if we must.
    this._parentVarieds = for a, idx in this._applicants
      do (a, idx) => a.reactNow((value) =>
        # update our arguments list, then trigger internal observers in turn.
        # note that this doesn't happen for the very first call, since internal
        # observers is not updated until the end of this method.
        this._partial[idx] = value
        callback.call(this._parentVaried, this._f.apply(this._parentVarieds[idx], this._partial)) if allBound is true
        null
      )

    # release lock on calback firing and return an agglomerated varied.
    allBound = true
    new Varied(uniqueId(), null, => v.stop() for v in this._parentVarieds)

  _immediate: -> this._f.apply(null, (a.get() for a in this._applicants))

class ManagedVarying extends FlatMappedVarying
  constructor: (@_resources, @_computation) ->
    super(new Varying())

    this._awake = false
    resources = null
    this.refCount().react((count) =>
      if count > 0 and this._awake is false
        this._awake = true
        resources = (f() for f in this._resources)
        this._parent.set(this._computation.apply(null, resources))
      else if count is 0 and this._awake is true
        this._awake = false
        resource.destroy() for resource in resources
    )

  get: ->
    if this._awake is true
      super()
    else
      result = null
      this.reactNow((x) -> result = x; this.stop()) # kind of gross? but maybe not?
      result


module.exports = { Varying, Varied, FlatMappedVarying, FlattenedVarying, MappedVarying, ComposedVarying }

