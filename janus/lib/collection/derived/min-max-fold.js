// Generated by CoffeeScript 1.12.2
(function() {
  var Base, MinMaxFold, Varying,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Varying = require('../../core/varying').Varying;

  Base = require('../../core/base').Base;

  MinMaxFold = (function(superClass) {
    extend(MinMaxFold, superClass);

    function MinMaxFold(list, compare) {
      var find;
      MinMaxFold.__super__.constructor.call(this);
      find = function() {
        var candidate, i, len, ref, x;
        candidate = list.list[0];
        ref = list.list;
        for (i = 0, len = ref.length; i < len; i++) {
          x = ref[i];
          if (compare(x, candidate)) {
            candidate = x;
          }
        }
        return candidate;
      };
      this._varying = new Varying(find());
      this.listenTo(list, 'added', (function(_this) {
        return function(obj) {
          if (compare(obj, _this._varying.get())) {
            _this._varying.set(obj);
          }
        };
      })(this));
      this.listenTo(list, 'removed', (function(_this) {
        return function(obj) {
          if (obj === _this._varying.get()) {
            _this._varying.set(find());
          }
        };
      })(this));
    }

    MinMaxFold.min = function(list) {
      return Varying.managed((function() {
        return new MinMaxFold(list, function(x, y) {
          return x < y;
        });
      }), function(incl) {
        return incl._varying;
      });
    };

    MinMaxFold.max = function(list) {
      return Varying.managed((function() {
        return new MinMaxFold(list, function(x, y) {
          return x > y;
        });
      }), function(incl) {
        return incl._varying;
      });
    };

    return MinMaxFold;

  })(Base);

  module.exports = {
    MinMaxFold: MinMaxFold
  };

}).call(this);
