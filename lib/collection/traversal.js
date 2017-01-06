// Generated by CoffeeScript 1.12.2
(function() {
  var Traversal, Varying, deepSet, defcase, defer, delegate, extendNew, fn, identity, isFunction, k, kase, match, matchCases, matcher, nothing, processNode, recurse, ref, ref1, ref2, value, valueCases, varying, withContext, x,
    slice = [].slice;

  Varying = require('../core/varying').Varying;

  ref = require('../core/case'), defcase = ref.defcase, match = ref.match;

  ref1 = require('../util/util'), identity = ref1.identity, isFunction = ref1.isFunction, extendNew = ref1.extendNew, deepSet = ref1.deepSet;

  withContext = function(name) {
    var obj1;
    return (
      obj1 = {},
      obj1["" + name] = {
        unapply: function(x, additional) {
          if (isFunction(x)) {
            return x.apply(null, [this.value[0], this.value[1]].concat(slice.call(additional)));
          } else {
            return x;
          }
        }
      },
      obj1
    );
  };

  matchCases = (ref2 = defcase.apply(null, ['org.janusjs.traversal'].concat(slice.call((function() {
    var i, len, ref2, results;
    ref2 = ['recurse', 'delegate', 'defer', 'varying', 'value', 'nothing'];
    results = [];
    for (i = 0, len = ref2.length; i < len; i++) {
      x = ref2[i];
      results.push(withContext(x));
    }
    return results;
  })()))), recurse = ref2.recurse, delegate = ref2.delegate, defer = ref2.defer, varying = ref2.varying, value = ref2.value, nothing = ref2.nothing, ref2);

  valueCases = {};

  fn = function(kase) {
    return valueCases[k] = function(x, context) {
      return kase([x, context]);
    };
  };
  for (k in matchCases) {
    kase = matchCases[k];
    fn(kase);
  }

  matcher = match(recurse(function(into, context, local) {
    return local.root(into, local.map, context != null ? context : local.context, local.reduce);
  }), delegate(function(to, context, local) {
    return matcher(to(local.key, local.value, local.obj, local.attribute, context != null ? context : local.context), extendNew(local, {
      context: context
    }));
  }), defer(function(to, context, local) {
    return matcher(to(local.key, local.value, local.obj, local.attribute, context != null ? context : local.context), extendNew(local, {
      context: context,
      map: to
    }));
  }), varying(function(v, _, local) {
    var result;
    result = v.flatMap(function(x) {
      return matcher(x, local);
    });
    if (local.immediate === true) {
      result = result.get();
    }
    return result;
  }), value(function(x) {
    return x;
  }), nothing(function() {
    return void 0;
  }));

  processNode = function(general) {
    return function(key, value) {
      var attribute, local, obj;
      obj = general.obj;
      if (obj.isModel === true) {
        attribute = obj.attribute(key);
      }
      local = extendNew(general, {
        key: key,
        value: value,
        attribute: attribute
      });
      return matcher(general.map(key, value, obj, attribute, general.context), local);
    };
  };

  Traversal = {
    asNatural: function(obj, map, context) {
      var general;
      if (context == null) {
        context = {};
      }
      general = {
        obj: obj,
        map: map,
        context: context,
        root: Traversal.asNatural
      };
      if (obj.isEnumerable === true) {
        return obj.flatMapPairs(processNode(general));
      }
    },
    asList: function(obj, map, context, reduce) {
      if (context == null) {
        context = {};
      }
      if (reduce == null) {
        reduce = identity;
      }
      return reduce(obj.enumeration().flatMapPairs(processNode({
        obj: obj,
        map: map,
        context: context,
        reduce: reduce,
        root: Traversal.asList
      })));
    },
    getNatural: function(obj, map, context) {
      var attribute, i, key, len, local, ref3, result, set, val;
      if (context == null) {
        context = {};
      }
      result = obj.isCollection === true ? [] : {};
      set = obj.isCollection === true ? (function(k, v) {
        return result[k] = v;
      }) : (function(k, v) {
        return deepSet(result, k)(v);
      });
      ref3 = obj.enumerate();
      for (i = 0, len = ref3.length; i < len; i++) {
        key = ref3[i];
        val = obj.get(key);
        if (obj.isModel === true) {
          attribute = obj.attribute(key);
        }
        local = {
          obj: obj,
          map: map,
          key: key,
          val: val,
          attribute: attribute,
          context: context,
          immediate: true,
          root: Traversal.getNatural
        };
        set(key, matcher(map(key, val, obj, attribute, context), local));
      }
      return result;
    },
    getArray: function(obj, map, context, reduce) {
      var attribute, key, local, val;
      if (context == null) {
        context = {};
      }
      if (reduce == null) {
        reduce = identity;
      }
      return reduce((function() {
        var i, len, ref3, results;
        ref3 = obj.enumerate();
        results = [];
        for (i = 0, len = ref3.length; i < len; i++) {
          key = ref3[i];
          val = obj.get(key);
          if (obj.isModel === true) {
            attribute = obj.attribute(key);
          }
          local = {
            obj: obj,
            map: map,
            reduce: reduce,
            key: key,
            val: val,
            attribute: attribute,
            context: context,
            immediate: true,
            root: Traversal.getArray
          };
          results.push(matcher(map(key, val, obj, attribute, context), local));
        }
        return results;
      })());
    }
  };

  recurse = valueCases.recurse, delegate = valueCases.delegate, defer = valueCases.defer, varying = valueCases.varying, value = valueCases.value, nothing = valueCases.nothing;

  Traversal["default"] = {
    serialize: function(k, v, _, attribute) {
      if (attribute != null) {
        return value(attribute.serialize());
      } else if (v != null) {
        if (v.isEnumerable === true) {
          return recurse(v);
        } else {
          return value(v);
        }
      } else {
        return nothing;
      }
    },
    modified: {
      map: function(k, va, obj) {
        if (obj._parent == null) {
          return value(false);
        } else {
          return varying(obj._parent.watch(k).map(function(vb) {
            if ((va != null ? va.isEnumerable : void 0) === true) {
              if (vb === va._parent) {
                return varying(Varying.mapAll(va.watchLength(), vb.watchLength(), function(la, lb) {
                  if (la !== lb) {
                    return value(true);
                  } else {
                    return recurse(va);
                  }
                }));
              } else {
                return value(true);
              }
            } else {
              return value(va !== vb);
            }
          }));
        }
      },
      reduce: function(list) {
        return list.any(identity);
      }
    },
    diff: {
      map: function(k, va, obj, attribute, arg) {
        var other;
        other = arg.other;
        return varying(other.watch(k).map(function(vb) {
          if ((va == null) && (vb == null)) {
            return value(false);
          } else if ((va != null) && (vb != null)) {
            if ((va.isEnumerable === true && vb.isEnumerable === true) && (va.isCollection === vb.isCollection)) {
              return varying(Varying.mapAll(va.watchLength(), vb.watchLength(), function(la, lb) {
                if (la !== lb) {
                  return value(true);
                } else {
                  return recurse(va, {
                    other: vb
                  });
                }
              }));
            } else {
              return value(va !== vb);
            }
          } else {
            return value(true);
          }
        }));
      },
      reduce: function(list) {
        return list.any(identity);
      }
    }
  };

  Traversal.cases = valueCases;

  module.exports = {
    Traversal: Traversal
  };

}).call(this);