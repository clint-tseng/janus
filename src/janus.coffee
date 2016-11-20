util = require('./util/util')

# pre-require these to fan them out top-level
kase = require('./core/case')
template = require('./view/template')
collection = require('./collection/collection')

# TODO: once we're sure the global is superfluous, remove.
janus = (window ? global)._janus$ ?=
  util: util

  # core functionality.
  Varying: require('./core/varying').Varying
  defcase: kase.defcase
  match: kase.match
  otherwise: kase.otherwise
  from: require('./core/from')

  # model functionality.
  Model: require('./model/model').Model
  attribute: require('./model/attribute')
  Issue: require('./model/issue').Issue
  store: require('./model/store')

  # collection functionality. TODO: toplevel more in 0.4?
  List: collection.List
  collection: collection

  # view and templating functionality.
  View: require('./view/view').View
  DomView: require('./view/dom-view').DomView
  find: template.find
  template: template.template
  mutators: require('./view/mutators')

  # application stuff is nested to reduce clutter.
  application:
    App: require('./application/app').App
    Library: require('./application/library').Library
    endpoint: require('./application/endpoint')
    handler: require('./application/handler')
    manifest: require('./application/manifest')

util.extend(module.exports, janus)

