// Generated by CoffeeScript 1.12.2
(function() {
  var attribute, collection, kase, resolver, schema, template, util;

  util = require('./util/util');

  kase = require('./core/case');

  template = require('./view/template');

  collection = require('./collection/collection');

  resolver = require('./model/resolver');

  schema = require('./model/schema');

  attribute = schema.attribute;

  util.extend(attribute, require('./model/attribute'));

  module.exports = {
    Varying: require('./core/varying').Varying,
    Case: kase.Case,
    match: kase.match,
    otherwise: kase.otherwise,
    from: require('./core/from'),
    types: require('./core/types'),
    Base: require('./core/base').Base,
    Map: require('./collection/map').Map,
    List: require('./collection/list').List,
    Set: require('./collection/set').Set,
    Traversal: require('./collection/traversal').Traversal,
    Model: require('./model/model').Model,
    Trait: schema.Trait,
    attribute: attribute,
    bind: schema.bind,
    validate: schema.validate,
    transient: schema.transient,
    initial: schema.initial,
    Request: resolver.Request,
    Resolver: resolver.Resolver,
    View: require('./view/view').View,
    DomView: require('./view/dom-view').DomView,
    find: template.find,
    template: template.template,
    mutators: require('./view/mutators'),
    App: require('./application/app').App,
    Library: require('./application/library').Library,
    Manifest: require('./application/manifest').Manifest,
    util: util
  };

}).call(this);
