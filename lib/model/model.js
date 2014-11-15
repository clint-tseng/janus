(function() {
  var Base, Binder, Model, Null, NullClass, Reference, Resolver, Varying, util, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Base = require('../core/base').Base;

  Varying = require('../core/varying').Varying;

  _ref = require('./reference'), Reference = _ref.Reference, Resolver = _ref.Resolver;

  util = require('../util/util');

  Binder = require('./binder').Binder;

  NullClass = (function() {
    function NullClass() {}

    return NullClass;

  })();

  Null = new NullClass();

  Model = (function(_super) {
    __extends(Model, _super);

    function Model(attributes, options) {
      if (attributes == null) {
        attributes = {};
      }
      this.options = options != null ? options : {};
      Model.__super__.constructor.call(this);
      this.attributes = {};
      this._attributes = {};
      this._watches = {};
      this._parent = this.options.parent;
      if (typeof this._preinitialize === "function") {
        this._preinitialize();
      }
      this.set(attributes);
      if (typeof this._initialize === "function") {
        this._initialize();
      }
      this._bind();
    }

    Model.prototype.get = function(key, bypassAttribute) {
      var attribute, mappedValue, value, _ref1;

      if (bypassAttribute == null) {
        bypassAttribute = false;
      }
      value = util.deepGet(this.attributes, key);
      if (value == null) {
        value = (_ref1 = this._parent) != null ? _ref1.get(key) : void 0;
        if (value instanceof Model) {
          value = this.set(key, value.shadow());
        } else if (value instanceof Reference) {
          mappedValue = value.map(function(inner) {
            if (inner instanceof Model) {
              return inner.shadow();
            } else {
              return inner;
            }
          });
          value = this.set(key, mappedValue);
        }
      }
      if ((value == null) && bypassAttribute === false) {
        attribute = this.attribute(key);
        value = attribute != null ? attribute.writeDefault === true ? this.set(key, attribute["default"]()) : attribute["default"]() : void 0;
      }
      if (value == null) {
        value = null;
      }
      if (value === Null) {
        return null;
      } else {
        return value;
      }
    };

    Model.prototype.set = function() {
      var args, key, obj, oldValue, value,
        _this = this;

      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (args.length === 1 && util.isPlainObject(args[0])) {
        return util.traverse(args[0], function(path, value) {
          return _this.set(path, value);
        });
      } else if (args.length === 2 && util.isPlainObject(args[1])) {
        obj = {};
        util.deepSet(obj, args[0])(args[1]);
        return this.set(obj);
      } else if (args.length === 2) {
        key = args[0], value = args[1];
        oldValue = util.deepGet(this.attributes, key);
        if (oldValue === value) {
          return value;
        }
        util.deepSet(this.attributes, key)(value === Null ? null : value);
        this._emitChange(key, value, oldValue);
        return value;
      }
    };

    Model.prototype.unset = function(key) {
      var oldValue;

      if (this._parent != null) {
        oldValue = this.get(key);
        util.deepSet(this.attributes, key)(Null);
        if (oldValue !== null) {
          this._emitChange(key, null, oldValue);
        }
      } else {
        oldValue = this.get(key);
        this._deleteAttr(key);
      }
      return oldValue;
    };

    Model.prototype.setAll = function(attrs) {
      var _this = this;

      util.traverseAll(this.attributes, function(path, value) {
        if (util.deepGet(attrs, path) == null) {
          return _this.unset(path.join('.'));
        }
      });
      this.set(attrs);
      return null;
    };

    Model.prototype.watch = function(key) {
      var _base, _ref1,
        _this = this;

      return (_ref1 = (_base = this._watches)[key]) != null ? _ref1 : _base[key] = (function() {
        var varying;

        varying = new Varying(_this.get(key));
        if (_this._parent != null) {
          varying.listenTo(_this._parent, "changed:" + key, function() {
            return varying.setValue(_this.get(key));
          });
        }
        return varying.listenTo(_this, "changed:" + key, function(newValue) {
          return varying.setValue(newValue);
        });
      })();
    };

    Model.prototype.watchAll = function() {
      var varying,
        _this = this;

      varying = new Varying(this);
      return varying.listenTo(this, 'anyChanged', function() {
        return varying.setValue(_this, true);
      });
    };

    Model.attributes = function() {
      if (this._attributesAgainst !== this) {
        this._attributesAgainst = this;
        this._attributes = {};
      }
      return this._attributes;
    };

    Model.allAttributes = function() {
      var attrs, recurse,
        _this = this;

      attrs = {};
      recurse = function(obj) {
        var attr, key, _ref1;

        if (obj.attributes == null) {
          return;
        }
        if (obj.__super__ != null) {
          recurse(obj.__super__.constructor);
        }
        _ref1 = obj.attributes();
        for (key in _ref1) {
          attr = _ref1[key];
          attrs[key] = attr;
        }
        return null;
      };
      recurse(this);
      return attrs;
    };

    Model.attribute = function(key, attribute) {
      return this.attributes()[key] = attribute;
    };

    Model.prototype.attribute = function(key) {
      var recurse, _base, _ref1,
        _this = this;

      recurse = function(obj) {
        var result, _base;

        if (obj.attributes == null) {
          return;
        }
        result = typeof (_base = (obj.attributes()[key])) === "function" ? new _base(_this, key) : void 0;
        if (result != null) {
          return result;
        } else if (obj.__super__ != null) {
          return recurse(obj.__super__.constructor);
        }
      };
      if (util.isArray(key)) {
        key = key.join('.');
      }
      return (_ref1 = (_base = this._attributes)[key]) != null ? _ref1 : _base[key] = recurse(this.constructor);
    };

    Model.prototype.attributeClass = function(key) {
      return this.constructor.attributes()[key];
    };

    Model.prototype.allAttributes = function() {
      var key, _results;

      _results = [];
      for (key in this.constructor.allAttributes()) {
        _results.push(this.attribute(key));
      }
      return _results;
    };

    Model.binders = function() {
      if (this._bindersAgainst !== this) {
        this._bindersAgainst = this;
        this._binders = [];
      }
      return this._binders;
    };

    Model.bind = function(key) {
      var binder;

      binder = new Binder(key);
      this.binders().push(binder);
      return binder;
    };

    Model.prototype._bind = function() {
      var recurse,
        _this = this;

      this._binders = {};
      recurse = function(obj) {
        var binder, _i, _len, _ref1;

        _ref1 = obj.binders();
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          binder = _ref1[_i];
          if (_this._binders[binder._key] == null) {
            _this._binders[binder._key] = binder.bind(_this);
          }
        }
        if ((obj.__super__ != null) && (obj.__super__.constructor.binders != null)) {
          recurse(obj.__super__.constructor);
        }
        return null;
      };
      recurse(this.constructor);
      return null;
    };

    Model.prototype.rebind = function(key) {
      var _ref1;

      return (_ref1 = this._binders[key]) != null ? _ref1.apply() : void 0;
    };

    Model.prototype.revert = function(key) {
      if (this._parent == null) {
        return;
      }
      return this._deleteAttr(key);
    };

    Model.prototype.shadow = function() {
      return new this.constructor({}, util.extendNew(this.options, {
        parent: this
      }));
    };

    Model.prototype.modified = function(deep) {
      var result,
        _this = this;

      if (deep == null) {
        deep = true;
      }
      if (this._parent == null) {
        return false;
      }
      result = false;
      util.traverse(this.attributes, function(path) {
        if (_this.attrModified(path, deep)) {
          return result = true;
        }
      });
      return result;
    };

    Model.prototype.attrModified = function(path, deep) {
      var attribute, isDeep, parentValue, transient, value, _ref1, _ref2;

      if (this._parent == null) {
        return false;
      }
      value = util.deepGet(this.attributes, path);
      if (value == null) {
        return false;
      }
      if (value === Null) {
        value = null;
      }
      if (value instanceof Reference) {
        value = (_ref1 = value.value) != null ? _ref1 : value.flatValue;
      }
      isDeep = deep == null ? true : util.isFunction(deep) ? deep(this, path, value) : deep === true;
      attribute = this.attribute(path);
      transient = (attribute != null) && attribute.transient === true;
      if (!transient) {
        parentValue = this._parent.get(path);
        if (parentValue instanceof Reference) {
          parentValue = (_ref2 = parentValue.value) != null ? _ref2 : parentValue.flatValue;
        }
        if (value instanceof Model) {
          if (isDeep === true) {
            return value.modified(deep);
          } else {
            return !(__indexOf.call(value.originals(), parentValue) >= 0);
          }
        } else {
          return parentValue !== value && !((parentValue == null) && (value == null));
        }
      } else {
        return false;
      }
    };

    Model.prototype.watchModified = function(deep) {
      var isDeep, _ref1, _ref2,
        _this = this;

      isDeep = deep == null ? true : util.isFunction(deep) ? deep(this) : deep === true;
      if (isDeep === true) {
        return (_ref1 = this._watchModifiedDeep$) != null ? _ref1 : this._watchModifiedDeep$ = (function() {
          var model, result, uniqSubmodels, watchModel, _i, _len, _ref2;

          if (_this._watchModifiedDeep$init === true) {
            return;
          }
          _this._watchModifiedDeep$init = true;
          result = new Varying(_this.modified(deep));
          _this.on('anyChanged', function(path) {
            if (_this.attrModified(path, deep)) {
              return result.setValue(true);
            } else {
              return result.setValue(_this.modified(deep));
            }
          });
          watchModel = function(model) {
            return result.listenTo(model.watchModified(deep), 'changed', function(isChanged) {
              if (isChanged === true) {
                return result.setValue(true);
              } else {
                return result.setValue(_this.modified(deep));
              }
            });
          };
          uniqSubmodels = _this._submodels().uniq();
          _ref2 = uniqSubmodels.list;
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            model = _ref2[_i];
            watchModel(model);
          }
          uniqSubmodels.on('added', function(newModel) {
            return watchModel(newModel);
          });
          uniqSubmodels.on('removed', function(oldModel) {
            return result.unlistenTo(oldModel.watchModified(deep));
          });
          return result;
        })();
      } else {
        return (_ref2 = this._watchModified$) != null ? _ref2 : this._watchModified$ = (function() {
          var result;

          result = new Varying(_this.modified(deep));
          _this.on('anyChanged', function(path) {
            if (_this.attrModified(path, deep)) {
              return result.setValue(true);
            } else {
              return result.setValue(_this.modified(deep));
            }
          });
          return result;
        })();
      }
    };

    Model.prototype.original = function() {
      var _ref1, _ref2;

      return (_ref1 = (_ref2 = this._parent) != null ? _ref2.original() : void 0) != null ? _ref1 : this;
    };

    Model.prototype.originals = function() {
      var cur, _results;

      cur = this;
      _results = [];
      while (cur._parent != null) {
        _results.push(cur = cur._parent);
      }
      return _results;
    };

    Model.prototype.merge = function() {
      var _ref1;

      if ((_ref1 = this._parent) != null) {
        _ref1.set(this.attributes);
      }
      return null;
    };

    Model.prototype.issues = function() {
      var _ref1,
        _this = this;

      return (_ref1 = this.issues$) != null ? _ref1 : this.issues$ = (function() {
        var attr, issueList;

        issueList = (function() {
          var _i, _len, _ref2, _results;

          _ref2 = this.allAttributes();
          _results = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            attr = _ref2[_i];
            if (attr.issues != null) {
              _results.push(attr.issues());
            }
          }
          return _results;
        }).call(_this);
        if (_this._issues != null) {
          issueList.unshift(_this._issues());
        }
        return (new (require('../collection/collection').CattedList)(issueList)).filter(function(issue) {
          return issue.active;
        });
      })();
    };

    Model.prototype.valid = function(severity) {
      if (severity == null) {
        severity = 0;
      }
      return this.issues().filter(function(issue) {
        return issue.severity.map(function(issueSev) {
          return issueSev <= severity;
        });
      }).watchLength().map(function(length) {
        return length === 0;
      });
    };

    Model.deserialize = function(data) {
      var attribute, key, prop, _ref1;

      _ref1 = this.allAttributes();
      for (key in _ref1) {
        attribute = _ref1[key];
        prop = util.deepGet(data, key);
        if (prop != null) {
          util.deepSet(data, key)(attribute.deserialize(prop));
        }
      }
      return new this(data);
    };

    Model.serialize = function(model, opts) {
      var result, walkAttrs,
        _this = this;

      if (opts == null) {
        opts = {};
      }
      walkAttrs = function(keys, src, target) {
        var attribute, innerResult, result, strKey, subKey, thisKey, value, _ref1;

        for (subKey in src) {
          value = src[subKey];
          thisKey = keys.concat([subKey]);
          strKey = thisKey.join('.');
          attribute = model.attribute(strKey);
          result = value === Null ? void 0 : (attribute != null) && (attribute.serialize != null) ? attribute.serialize(opts) : util.isPlainObject(value) ? (innerResult = (_ref1 = target[subKey]) != null ? _ref1 : {}, walkAttrs(thisKey, value, innerResult), innerResult) : value;
          if (result instanceof Reference) {
            result = result.flatValue;
          }
          target[subKey] = result;
        }
        return target;
      };
      result = model._parent != null ? Model.serialize(model._parent, opts) : {};
      walkAttrs([], model.attributes, result);
      return result;
    };

    Model.prototype.serialize = function() {
      return this.constructor.serialize(this);
    };

    Model.prototype._deleteAttr = function(key) {
      var newValue, oldValue;

      oldValue = util.deepDelete(this.attributes, key);
      newValue = this.get(key);
      if (newValue !== oldValue) {
        this._emitChange(key, newValue, oldValue);
      }
      return oldValue;
    };

    Model.prototype._emitChange = function(key, newValue, oldValue) {
      var emit, parts,
        _this = this;

      parts = util.isArray(key) ? key : key.split('.');
      if (oldValue instanceof Model) {
        this._submodels().remove(oldValue);
      }
      if (newValue instanceof Model) {
        this._submodels().add(newValue);
      }
      emit = function(name, partKey) {
        return _this.emit("" + name + ":" + partKey, newValue, oldValue, partKey);
      };
      emit('changed', parts.join('.'));
      while (parts.length > 1) {
        parts.pop();
        emit('subKeyChanged', parts.join('.'));
      }
      this.emit('anyChanged', key, newValue, oldValue);
      return null;
    };

    Model.prototype._submodels = function() {
      var _ref1;

      return (_ref1 = this._submodels$) != null ? _ref1 : this._submodels$ = new (require('../collection/list').List)();
    };

    return Model;

  })(Base);

  util.extend(module.exports, {
    Model: Model
  });

}).call(this);
