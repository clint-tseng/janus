# Some general types that the specific implementations can derive off of,
# mostly to express behavioral characteristics that a `View` can count on
# so that we can easily register against these collections.

Model = require('../model/model').Model
folds = require('./folds')


# A `Collection` provides `add` and `remove` events for every element that is
# added or removed from the list.
class Collection extends Model
  isCollection: true

  # Create a new FilteredList based on this list, with the member check
  # function `f`.
  #
  # **Returns** a `FilteredList`
  filter: (f) -> new (require('./filtered-list').FilteredList)(this, f)

  # Create a new mapped List based on this list, with the mapping function `f`.
  #
  # **Returns** a `MappedList`
  map: (f) -> new (require('./mapped-list').MappedList)(this, f)

  # Create a new mapped List based on this list, with the mapping function `f`.
  # Due to the flatMap, `f` may return a `Varying` that changes, which will in
  # turn change the value in the resulting list.
  #
  # **Returns** a `MappedList`
  flatMap: (f) -> new (require('./mapped-list').FlatMappedList)(this, f)

  # Create a new concatenated List based on this List, along with the other
  # Lists provided in the call. Can be passed in either as an arg list of Lists
  # or as an array of Lists.
  #
  # **Returns** a `CattedList`
  concat: (lists...) ->
    new (require('./catted-list').CattedList)([ this ].concat(lists))

  # Create a new FlattenedList based on this List.
  #
  # **Returns** a `FlattenedList`
  flatten: -> new (require('./flattened-list').FlattenedList)(this)

  # Create a new UniqList based on this List.
  #
  # **Returns** a `UniqList`
  uniq: (options) -> new (require('./uniq-list').UniqList)(this, options)

  # Create a list that always takes the first x elements of this collection,
  # where x may be a number or a Varying[Int].
  #
  # **Returns** a `TakenList`
  take: (x) -> new (require('./taken-list').TakenList)(this, x)

  # See if any element in this list qualifies for the condition.
  any: (f) -> folds.any(new (require('./mapped-list').MappedList)(this, f))

  # fold left across the list.
  fold: (memo, f) -> folds.fold(this, memo, f)

  # scan left across the list. (alt implementation)
  scanl: (memo, f) -> folds.scanl(this, memo, f)

  # fold left across the list. (alt implementation)
  foldl: (memo, f) -> folds.foldl(this, memo, f)

  # get the minimum number on the list.
  min: -> folds.min(this)

  # get the maximum number on the list.
  max: -> folds.max(this)

  # get the sum of this list.
  sum: -> folds.sum(this)

  # get the strings of this list joined by some string.
  join: (joiner) -> folds.join(this, joiner)


# An `OrderedCollection` provides `add` and `remove` events for every element
# that is added or removed from the list, along with a positional argument.
class OrderedCollection extends Collection


module.exports = { Collection, OrderedCollection }

