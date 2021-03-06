// Generated by CoffeeScript 1.12.2
(function() {
  var List, Mappable, Set, Varying, util,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Varying = require('../core/varying').Varying;

  Mappable = require('./collection').Mappable;

  List = require('./list').List;

  util = require('../util/util');

  Set = (function(superClass) {
    extend(Set, superClass);

    function Set(init) {
      Set.__super__.constructor.call(this);
      this._watched = [];
      this._watchers = [];
      this._list = new List();
      this.list = this._list.list;
      if (init != null) {
        this.add(init);
      }
    }

    Set.prototype.add = function(elems) {
      var elem, i, len, widx;
      if (!util.isArray(elems)) {
        elems = [elems];
      }
      for (i = 0, len = elems.length; i < len; i++) {
        elem = elems[i];
        if (!(!this.includes_(elem))) {
          continue;
        }
        widx = this._watched.indexOf(elem);
        if (widx >= 0) {
          this._watchers[widx].set(true);
        }
        this._list.add(elem);
        this.emit('added', elem);
      }
      return elems;
    };

    Set.prototype.remove = function(elem) {
      var idx, widx;
      widx = this._watched.indexOf(elem);
      if (widx >= 0) {
        this._watchers[widx].set(false);
      }
      idx = this.list.indexOf(elem);
      if (!(idx >= 0)) {
        return void 0;
      }
      this._list.removeAt(idx);
      this.emit('removed', elem);
      return elem;
    };

    Set.prototype.includes_ = function(elem) {
      return this.list.indexOf(elem) >= 0;
    };

    Set.prototype.includes = function(elem) {
      var v;
      v = new Varying(this.includes_(elem));
      this._watched.push(elem);
      this._watchers.push(v);
      return v;
    };

    Object.defineProperty(Set.prototype, 'length', {
      get: function() {
        return this._list.length;
      }
    });

    Object.defineProperty(Set.prototype, 'length_', {
      get: function() {
        return this.list.length;
      }
    });

    Set.prototype.flatten = function() {
      return this._flatten$ != null ? this._flatten$ : this._flatten$ = new (require('./derived/flattened-set').FlattenedSet)(this);
    };

    Set.prototype.enumerate_ = function() {
      return this.list.slice();
    };

    Set.prototype.enumerate = function() {
      return this;
    };

    Set.prototype.filter = function(f) {
      return this._list.filter(f);
    };

    Set.prototype.map = function(f) {
      return this._list.map(f);
    };

    Set.prototype.flatMap = function(f) {
      return this._list.flatMap(f);
    };

    Set.prototype.uniq = function() {
      return this;
    };

    Set.prototype.any = function(f) {
      return this._list.any(f);
    };

    Set.deserialize = List.deserialize;

    Set.of = List.of;

    return Set;

  })(Mappable);

  module.exports = {
    Set: Set
  };

}).call(this);
