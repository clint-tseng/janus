// Generated by CoffeeScript 1.12.2
(function() {
  var DerivedList, Enumeration, IndexList, KeyList, Map, Varying, _dynamic, deepGet, ref, traverse, traverseAll,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Varying = require('../core/varying').Varying;

  DerivedList = require('../collection/list').DerivedList;

  Map = require('./map').Map;

  ref = require('../util/util'), traverse = ref.traverse, traverseAll = ref.traverseAll, deepGet = ref.deepGet;

  KeyList = (function(superClass) {
    extend(KeyList, superClass);

    function KeyList(target, options) {
      var ptr, ref1, ref2, scanMap;
      this.target = target;
      if (options == null) {
        options = {};
      }
      KeyList.__super__.constructor.call(this);
      this.scope = (ref1 = options.scope) != null ? ref1 : 'all';
      this.include = (ref2 = options.include) != null ? ref2 : 'values';
      this._trackedKeys = {};
      scanMap = (function(_this) {
        return function(map) {
          return traverse(map.data, function(key) {
            return _this._addKey(key.join('.'));
          });
        };
      })(this);
      if (this.scope === 'all') {
        ptr = this.target;
        while (ptr != null) {
          scanMap(ptr);
          ptr = ptr._parent;
        }
      } else if (this.scope === 'direct') {
        scanMap(this.target);
      }
      this.listenTo(this.target, 'changed', (function(_this) {
        return function(key, newValue, oldValue) {
          var ownValue;
          if (_this.scope === 'direct') {
            ownValue = deepGet(_this.target.data, key);
            if (ownValue !== newValue) {
              return;
            }
          }
          if ((newValue != null) && (oldValue == null)) {
            _this._addKey(key);
          } else if ((oldValue != null) && (newValue == null)) {
            _this._removeKey(key);
          }
        };
      })(this));
    }

    KeyList.prototype._addKey = function(key) {
      var i, j, parts, ref1;
      if (this._trackedKeys[key] === true) {
        return;
      }
      if (this.include === 'all') {
        parts = key.split('.');
        for (i = j = ref1 = parts.length; j > 0; i = j += -1) {
          key = parts.slice(0, i).join('.');
          if (this._trackedKeys[key] === true) {
            break;
          }
          this._trackedKeys[key] = true;
          this._add(key);
        }
      } else {
        this._trackedKeys[key] = true;
        this._add(key);
      }
    };

    KeyList.prototype._removeKey = function(key) {
      var idx, j, k, len, ref1;
      idx = this.list.indexOf(key);
      if (!(idx >= 0)) {
        return;
      }
      delete this._trackedKeys[key];
      this._removeAt(idx);
      if (this.include === 'all') {
        ref1 = this.list;
        for (idx = j = 0, len = ref1.length; j < len; idx = ++j) {
          k = ref1[idx];
          if (!(k.indexOf(key) === 0)) {
            continue;
          }
          delete this._trackedKeys[k];
          this._removeAt(idx);
        }
      }
    };

    KeyList.prototype.mapPairs = function(f) {
      return this.flatMap((function(_this) {
        return function(key) {
          return Varying.mapAll(f, new Varying(key), _this.target.get(key));
        };
      })(this));
    };

    KeyList.prototype.flatMapPairs = function(f) {
      return this.flatMap((function(_this) {
        return function(key) {
          return Varying.flatMapAll(f, new Varying(key), _this.target.get(key));
        };
      })(this));
    };

    return KeyList;

  })(DerivedList);

  IndexList = (function(superClass) {
    extend(IndexList, superClass);

    function IndexList(parent) {
      this.parent = parent;
      IndexList.__super__.constructor.call(this);
      this._lengthObservation = this.reactTo(this.parent.length, (function(_this) {
        return function(length) {
          var idx, j, l, ourLength, ref1, ref2, ref3, ref4;
          ourLength = _this.length_;
          if (length > ourLength) {
            for (idx = j = ref1 = ourLength, ref2 = length; ref1 <= ref2 ? j < ref2 : j > ref2; idx = ref1 <= ref2 ? ++j : --j) {
              _this._add(idx);
            }
          } else if (length < ourLength) {
            for (idx = l = ref3 = ourLength, ref4 = length; l > ref4; idx = l += -1) {
              _this._removeAt(idx - 1);
            }
          }
        };
      })(this));
    }

    IndexList.prototype.mapPairs = function(f) {
      return this.flatMap((function(_this) {
        return function(idx) {
          return Varying.mapAll(f, new Varying(idx), _this.parent.at(idx));
        };
      })(this));
    };

    IndexList.prototype.flatMapPairs = function(f) {
      return this.flatMap((function(_this) {
        return function(idx) {
          return Varying.flatMapAll(f, new Varying(idx), _this.parent.at(idx));
        };
      })(this));
    };

    IndexList.prototype.__destroy = function() {
      this._lengthObservation.stop();
    };

    return IndexList;

  })(DerivedList);

  _dynamic = function(suffix) {
    return function(obj, options) {
      var type;
      type = obj.isMappable === true ? 'list' : obj.isMap === true ? 'map' : void 0;
      return Enumeration[type + suffix](obj, options);
    };
  };

  Enumeration = {
    get_: _dynamic('_'),
    get: _dynamic(''),
    map_: function(map, options) {
      var include, ptr, ref1, ref2, result, scanMap, scope, traverser;
      if (options == null) {
        options = {};
      }
      scope = (ref1 = options.scope) != null ? ref1 : 'all';
      include = (ref2 = options.include) != null ? ref2 : 'values';
      result = [];
      traverser = include === 'values' ? traverse : include === 'all' ? traverseAll : void 0;
      scanMap = (function(_this) {
        return function(map) {
          return traverser(map.data, function(key) {
            if (!(result.indexOf(key) >= 0)) {
              return result.push(key.join('.'));
            }
          });
        };
      })(this);
      if (scope === 'all') {
        ptr = map;
        while (ptr != null) {
          scanMap(ptr);
          ptr = ptr._parent;
        }
      } else if (scope === 'direct') {
        scanMap(map);
      }
      return result;
    },
    map: function(map, options) {
      return new KeyList(map, options);
    },
    list_: function(list) {
      var idx, j, ref1, results;
      results = [];
      for (idx = j = 0, ref1 = list.length_; 0 <= ref1 ? j < ref1 : j > ref1; idx = 0 <= ref1 ? ++j : --j) {
        results.push(idx);
      }
      return results;
    },
    list: function(list) {
      return new IndexList(list);
    }
  };

  module.exports = {
    KeyList: KeyList,
    IndexList: IndexList,
    Enumeration: Enumeration
  };

}).call(this);