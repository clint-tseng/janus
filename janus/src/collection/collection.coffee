# Some general types that the specific implementations can derive off of,
# mostly to express behavioral characteristics that a `View` can count on
# so that we can easily register against these collections.

{ Base } = require('../core/base')
{ Varying } = require('../core/varying')
{ Traversal } = require('./traversal')
folds = require('./folds')

{ IndexOfFold } = require('./derived/indexof-fold')
{ IncludesFold } = require('./derived/includes-fold')
{ AnyFold } = require('./derived/any-fold')
{ MinMaxFold } = require('./derived/min-max-fold')
{ SumFold } = require('./derived/sum-fold')


# cache this circularly referenced module once we fetch it:
Enumeration$ = null

# The base for all data structures. Provides basic enumeration functions around
# keys/indices, and all classes implementing Enumerable are expected to also
# provide:
# * get: (key) -> Varying[value]
# * get_: (key) -> value
# * set: (key, value) -> value
# * shadow: -> Enumerable
#
# Most classes (not Set) also provide these:
# * mapPairs: ((key, value) -> T) -> [T]
# * flatMapPairs: ((key, value) -> Varying?[T]) -> [T]
class Enumerable extends Base
  isEnumerable: true

  # Calls into the Enumeration module to get either a live KeySet or a static
  # array enumerating the keys of this Map or List. The options are passed
  # directly to Enumeration and only matter for Maps, but consist of:
  # * scope: (all|direct) all inherited or only dir
  enumerate_: (options) -> (Enumeration$ ?= require('./enumeration').Enumeration).get_(this, options)
  enumerate: (options) ->
    Enumeration$ ?= require('./enumeration').Enumeration
    if options?
      Enumeration$.get(this, options)
    else
      (this.enumeration$ ?= Base.managed(=> Enumeration$.get(this)))()

  serialize: -> Traversal.natural_(this, Traversal.default.serialize)

  modified: -> if this._parent? then this.diff(this._parent) else new Varying(false)
  diff: (other) -> Traversal.list([ this, other ], Traversal.default.diff)

# A `Mappable` provides map-like functions (map, filter, etc) and fires `add`
# and `remove` events for every element that is added or removed from the list.
class Mappable extends Enumerable
  isMappable: true

  # map-like operations:
  map: (f) -> new (require('./derived/mapped-list').MappedList)(this, f)
  flatMap: (f) -> new (require('./derived/mapped-list').FlatMappedList)(this, f)
  filter: (f) -> new (require('./derived/filtered-list').FilteredList)(this, f)
  flatten: -> new (require('./derived/flattened-list').FlattenedList)(this)
  uniq: -> new (require('./derived/uniq-list').UniqList)(this)

  # fold-like operations:
  includes: (x) -> IncludesFold.includes(this, x)
  any: (f) -> AnyFold.any(this, f)
  min: -> MinMaxFold.min(this)
  max: -> MinMaxFold.max(this)
  sum: -> SumFold.sum(this)


# An `OrderedMappable` provides `add` and `remove` events for every element
# that is added or removed from the list, along with a positional argument.
class OrderedMappable extends Mappable
  isOrderedMappable: true

  # Rely on enumeration to give us mapPairs and flatMapPairs:
  mapPairs: (f) -> this.enumerate().mapPairs(f)
  flatMapPairs: (f) -> this.enumerate().flatMapPairs(f)

  take: (x) -> new (require('./derived/taken-list').TakenList)(this, x)

  # Can be passed in either as an arg list of Lists or as an array of Lists.
  concat: (lists...) ->
    new (require('./derived/catted-list').CattedList)([ this ].concat(lists))

  # value may be Varying[x].
  indexOf: (value) -> IndexOfFold.indexOf(this, value)

  # fold-like operations (ALPHA):
  join: (joiner) -> folds.join(this, joiner)
  apply: (f) -> folds.apply(this, f)
  scanl: (memo, f) -> folds.scanl(this, memo, f)
  foldl: (memo, f) -> folds.foldl(this, memo, f)


module.exports = { Enumerable, Mappable, OrderedMappable }

