{ extend } = require('./util')
{ defcase } = require('../core/case')


types =
  result: defcase('org.janusjs.util.result', 'init', 'pending', 'progress', 'success', 'failure')
  error: defcase('org.janusjs.util.error', 'denied', 'not_authorized', 'not_found', 'invalid', 'internal')

  traversal: defcase('org.janusjs.collection.traversal': { arity: 2 }, 'recurse', 'delegate', 'defer', 'varying', 'value', 'nothing')


module.exports = types

