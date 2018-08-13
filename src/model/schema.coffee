{ isFunction } = require('../util/util')
{ Attribute } = require('./attribute')

TransientAttribute = class extends Attribute
  transient: true

module.exports = {
  attribute: (key, klass) -> (schema) -> schema.attributes[key] = klass
  bind: (key, binding) -> (schema) -> schema.bindings[key] = binding
  validate: (binding) -> (schema) -> schema.validations.push(binding)

  transient: (key) -> (schema) -> schema.attributes[key] = TransientAttribute
  dfault: (key, value, klass = Attribute) -> (schema) ->
    wrapped = if isFunction(value) then value else (-> value)
    schema.attributes[key] = class extends klass
      default: wrapped

  Trait: (parts...) -> (schema) ->
    part(schema) for part in parts
    return
}

# in case some people prefer the consistent syntax:
module.exports.Trait.build = module.exports.Trait

# and another handy shortcut for a writing default:
module.exports.dfault.writing = (key, value, klass = Attribute) ->
  module.exports.dfault(key, value, class extends klass
    writeDefault: true)

# and "dfault" is super annoying..
module.exports.dēfault = module.exports.dfault

