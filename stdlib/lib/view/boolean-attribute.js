// Generated by CoffeeScript 1.12.2
(function() {
  var $, Base, Boolean, BooleanAttributeEditView, BooleanButtonAttributeEditView, DomView, Varying, find, from, ref, stringifier, template;

  ref = require('janus'), Varying = ref.Varying, DomView = ref.DomView, from = ref.from, template = ref.template, find = ref.find, Base = ref.Base;

  Boolean = require('janus').attribute.Boolean;

  stringifier = require('../util/util').stringifier;

  $ = require('janus-dollar');

  BooleanAttributeEditView = DomView.build($('<input type="checkbox"/>'), template(find('input').prop('checked', from.self().flatMap(function(view) {
    return view.subject.getValue();
  })).on('input change', function(event, subject) {
    return subject.setValue(event.target.checked);
  })));

  BooleanButtonAttributeEditView = DomView.build($('<button/>'), template(find('button').text(from.self().flatMap(stringifier).and.self().flatMap(function(view) {
    return view.subject.getValue();
  }).all.map(function(f, value) {
    return f(value);
  })).classed('checked', from.self().flatMap(function(view) {
    return view.subject.getValue();
  })).on('click', function(event, subject) {
    event.preventDefault();
    return subject.setValue(!subject.getValue_());
  })));

  module.exports = {
    BooleanAttributeEditView: BooleanAttributeEditView,
    BooleanButtonAttributeEditView: BooleanButtonAttributeEditView,
    registerWith: function(library) {
      library.register(Boolean, BooleanAttributeEditView, {
        context: 'edit'
      });
      return library.register(Boolean, BooleanButtonAttributeEditView, {
        context: 'edit',
        style: 'button'
      });
    }
  };

}).call(this);
