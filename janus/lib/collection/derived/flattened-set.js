// Generated by CoffeeScript 1.12.2
(function() {
  var FlattenedSet, Set,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Set = require('../set').Set;

  FlattenedSet = (function(superClass) {
    extend(FlattenedSet, superClass);

    function FlattenedSet(parent) {
      var elem, i, len, ref;
      this.parent = parent;
      FlattenedSet.__super__.constructor.call(this);
      this._counts = [];
      this.listenTo(this.parent, 'added', (function(_this) {
        return function(elem) {
          return _this._tryAdd(elem);
        };
      })(this));
      this.listenTo(this.parent, 'removed', (function(_this) {
        return function(elem) {
          return _this._tryRemove(elem);
        };
      })(this));
      ref = this.parent.list;
      for (i = 0, len = ref.length; i < len; i++) {
        elem = ref[i];
        this._tryAdd(elem);
      }
    }

    FlattenedSet.prototype._tryAdd = function(elem) {
      var i, len, ref, subelem;
      if ((elem != null ? elem.isMappable : void 0) === true && elem !== this.parent && elem !== this) {
        this.listenTo(elem, 'added', (function(_this) {
          return function(elem) {
            return _this._tryAddOne(elem);
          };
        })(this));
        this.listenTo(elem, 'removed', (function(_this) {
          return function(elem) {
            return _this._tryRemove(elem);
          };
        })(this));
        ref = elem.list;
        for (i = 0, len = ref.length; i < len; i++) {
          subelem = ref[i];
          this._tryAddOne(subelem);
        }
      } else {
        this._tryAddOne(elem);
      }
    };

    FlattenedSet.prototype._tryAddOne = function(elem) {
      var idx;
      idx = this.list.indexOf(elem);
      if (idx >= 0) {
        this._counts[idx] += 1;
      } else {
        this._counts[this.list.length] = 1;
        Set.prototype.add.call(this, elem);
      }
    };

    FlattenedSet.prototype._tryRemove = function(elem) {
      var i, idx, len, ref, subelem;
      idx = this.list.indexOf(elem);
      if (idx >= 0) {
        this._counts[idx] -= 1;
        if (this._counts[idx] === 0) {
          this._counts.splice(idx, 1);
          Set.prototype.remove.call(this, elem);
        }
      } else {
        ref = elem.list;
        for (i = 0, len = ref.length; i < len; i++) {
          subelem = ref[i];
          this._tryRemove(subelem);
        }
        this.unlistenTo(elem);
      }
    };

    FlattenedSet.prototype.add = void 0;

    FlattenedSet.prototype.remove = void 0;

    FlattenedSet.prototype.putAll = void 0;

    return FlattenedSet;

  })(Set);

  module.exports = {
    FlattenedSet: FlattenedSet
  };

}).call(this);
