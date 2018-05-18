// Generated by CoffeeScript 1.12.2
(function() {
  var DerivedMap, Enumerable, Map, Null, NullClass, Varying, deepDelete, deepGet, deepSet, extendNew, isArray, isEmptyObject, isPlainObject, ref, traverse, traverseAll,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Enumerable = require('./collection').Enumerable;

  Varying = require('../core/varying').Varying;

  ref = require('../util/util'), deepGet = ref.deepGet, deepSet = ref.deepSet, deepDelete = ref.deepDelete, extendNew = ref.extendNew, isArray = ref.isArray, isPlainObject = ref.isPlainObject, isEmptyObject = ref.isEmptyObject, traverse = ref.traverse, traverseAll = ref.traverseAll;

  NullClass = (function() {
    function NullClass() {}

    return NullClass;

  })();

  Null = new NullClass();

  Map = (function(superClass) {
    extend(Map, superClass);

    Map.prototype.isMap = true;

    function Map(attributes, options) {
      if (attributes == null) {
        attributes = {};
      }
      this.options = options != null ? options : {};
      Map.__super__.constructor.call(this);
      this.attributes = {};
      this._watches = {};
      if (this.options.parent != null) {
        this._parent = this.options.parent;
        this.listenTo(this._parent, 'anyChanged', (function(_this) {
          return function(key, newValue, oldValue) {
            return _this._parentChanged(key, newValue, oldValue);
          };
        })(this));
      }
      if (typeof this._preinitialize === "function") {
        this._preinitialize();
      }
      this.set(attributes);
      if (typeof this._initialize === "function") {
        this._initialize();
      }
    }

    Map.prototype.get = function(key) {
      var value;
      value = deepGet(this.attributes, key);
      if ((value == null) && (this._parent != null)) {
        value = this._parent.get(key);
        if ((value != null ? value.isEnumerable : void 0) === true) {
          value = this.set(key, value.shadow());
        }
      }
      if (value === Null) {
        return null;
      } else {
        return value;
      }
    };

    Map.prototype.set = function(x, y) {
      var obj;
      if ((y != null) && (!isPlainObject(y) || isEmptyObject(y))) {
        return this._set(x, y);
      } else if (isPlainObject(y)) {
        obj = {};
        deepSet(obj, x)(y);
        return traverse(obj, (function(_this) {
          return function(path, value) {
            return _this._set(path, value);
          };
        })(this));
      } else if (isPlainObject(x)) {
        return traverse(x, (function(_this) {
          return function(path, value) {
            return _this._set(path, value);
          };
        })(this));
      }
    };

    Map.prototype._set = function(key, value) {
      var oldValue;
      oldValue = deepGet(this.attributes, key);
      if (oldValue === value) {
        return value;
      }
      deepSet(this.attributes, key)(value);
      if (isArray(key)) {
        key = key.join('.');
      }
      this._changed(key, value, oldValue);
      return value;
    };

    Map.prototype.setAll = function(attrs) {
      traverseAll(this.attributes, (function(_this) {
        return function(path, value) {
          if (deepGet(attrs, path) == null) {
            return _this.unset(path.join('.'));
          }
        };
      })(this));
      this.set(attrs);
      return null;
    };

    Map.prototype.unset = function(key) {
      var oldValue;
      if (this._parent != null) {
        oldValue = this.get(key);
        deepSet(this.attributes, key)(Null);
      } else {
        oldValue = deepDelete(this.attributes, key);
      }
      if (oldValue != null) {
        this._changed(key, this.get(key), oldValue);
      }
      return oldValue;
    };

    Map.prototype.revert = function(key) {
      var newValue, oldValue;
      if (this._parent == null) {
        return;
      }
      oldValue = deepDelete(this.attributes, key);
      newValue = this.get(key);
      if (newValue !== oldValue) {
        this._changed(key, newValue, oldValue);
      }
      return oldValue;
    };

    Map.prototype.shadow = function(klass) {
      return new (klass != null ? klass : this.constructor)({}, extendNew(this.options, {
        parent: this
      }));
    };

    Map.prototype["with"] = function(attributes) {
      var result;
      result = this.shadow();
      result.set(attributes);
      return result;
    };

    Map.prototype.original = function() {
      var ref1, ref2;
      return (ref1 = (ref2 = this._parent) != null ? ref2.original() : void 0) != null ? ref1 : this;
    };

    Map.prototype.watch = function(key) {
      var base;
      return (base = this._watches)[key] != null ? base[key] : base[key] = (function(_this) {
        return function() {
          var varying;
          varying = new Varying(_this.get(key));
          _this.listenTo(_this, "changed:" + key, function(newValue) {
            return varying.set(newValue);
          });
          return varying;
        };
      })(this)();
    };

    Map.prototype._changed = function(key, newValue, oldValue) {
      if (oldValue === Null) {
        oldValue = null;
      }
      if (isPlainObject(oldValue) && (newValue == null)) {
        traverse(oldValue, (function(_this) {
          return function(path, value) {
            var subkey;
            subkey = key + "." + (path.join('.'));
            _this.emit("changed:" + subkey, null, value);
            return _this.emit('anyChanged', subkey, null, value);
          };
        })(this));
      }
      this.emit("changed:" + key, newValue, oldValue);
      this.emit('anyChanged', key, newValue, oldValue);
      return null;
    };

    Map.prototype._parentChanged = function(key, newValue, oldValue) {
      var ourValue;
      ourValue = deepGet(this.attributes, key);
      if ((ourValue != null) || ourValue === Null) {
        return;
      }
      this.emit("changed:" + key, newValue, oldValue);
      return this.emit('anyChanged', key, newValue, oldValue);
    };

    Map.prototype.mapPairs = function(f) {
      var result;
      result = new DerivedMap();
      traverse(this.attributes, function(k, v) {
        k = k.join('.');
        return result.__set(k, f(k, v));
      });
      result.listenTo(this, 'anyChanged', (function(_this) {
        return function(key, value) {
          if ((value != null) && value !== Null) {
            return result.__set(key, f(key, value));
          } else {
            return result._unset(key);
          }
        };
      })(this));
      return result;
    };

    Map.prototype.flatMapPairs = function(f, klass) {
      var add, result, varieds;
      if (klass == null) {
        klass = DerivedMap;
      }
      result = new klass();
      varieds = {};
      add = (function(_this) {
        return function(key) {
          return varieds[key] != null ? varieds[key] : varieds[key] = _this.watch(key).flatMap(function(value) {
            return f(key, value);
          }).react(function(x) {
            return result.__set(key, x);
          });
        };
      })(this);
      traverse(this.attributes, function(k) {
        return add(k.join('.'));
      });
      result.listenTo(this, 'anyChanged', (function(_this) {
        return function(key, newValue, oldValue) {
          var k, varied;
          if ((newValue != null) && (varieds[key] == null)) {
            return add(key);
          } else if ((oldValue != null) && (newValue == null)) {
            for (k in varieds) {
              varied = varieds[k];
              if (!(k.indexOf(key) === 0)) {
                continue;
              }
              varied.stop();
              delete varieds[k];
            }
            return result._unset(key);
          }
        };
      })(this));
      result.on('destroying', function() {
        var _, results, varied;
        results = [];
        for (_ in varieds) {
          varied = varieds[_];
          results.push(varied.stop());
        }
        return results;
      });
      return result;
    };

    Map.prototype.watchLength = function() {
      return this.watchLength$ != null ? this.watchLength$ : this.watchLength$ = Varying.managed(((function(_this) {
        return function() {
          return _this.enumeration();
        };
      })(this)), function(it) {
        return it.watchLength();
      });
    };

    Map.deserialize = function(data) {
      return new this(data);
    };

    return Map;

  })(Enumerable);

  DerivedMap = (function(superClass) {
    var i, len, method, ref1, roError;

    extend(DerivedMap, superClass);

    function DerivedMap() {
      return DerivedMap.__super__.constructor.apply(this, arguments);
    }

    roError = function() {
      throw new Error('this map is read-only');
    };

    ref1 = ['_set', 'setAll', 'unset', 'revert'];
    for (i = 0, len = ref1.length; i < len; i++) {
      method = ref1[i];
      DerivedMap.prototype["_" + method] = DerivedMap.__super__[method];
      DerivedMap.prototype[method] = roError;
    }

    DerivedMap.prototype.set = function() {
      return roError;
    };

    DerivedMap.prototype.shadow = function() {
      return this;
    };

    return DerivedMap;

  })(Map);

  module.exports = {
    Null: Null,
    Map: Map
  };

}).call(this);