// Generated by CoffeeScript 1.12.2
(function() {
  var Base, List, Varying, View, app, attribute, closest, closest_, dynamic, get, into, intoAll, intoAll_, into_, isFunction, isString, match, navigation, parent, parent_, ref, ref1, self, subject, varying, vm,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Base = require('../core/base').Base;

  Varying = require('../core/varying').Varying;

  ref = require('../core/types').from, dynamic = ref.dynamic, get = ref.get, subject = ref.subject, attribute = ref.attribute, vm = ref.vm, varying = ref.varying, app = ref.app, self = ref.self;

  match = require('../core/case').match;

  List = require('../collection/list').List;

  navigation = require('./navigation');

  parent_ = navigation.parent_, closest_ = navigation.closest_, into_ = navigation.into_, intoAll_ = navigation.intoAll_, parent = navigation.parent, closest = navigation.closest, into = navigation.into, intoAll = navigation.intoAll;

  ref1 = require('../util/util'), isFunction = ref1.isFunction, isString = ref1.isString;

  View = (function(superClass) {
    extend(View, superClass);

    function View(subject1, options) {
      this.subject = subject1;
      this.options = options != null ? options : {};
      View.__super__.constructor.call(this);
      if (this.constructor.viewModelClass != null) {
        this.viewModel = this.vm = new this.constructor.viewModelClass({
          subject: this.subject,
          view: this,
          options: this.options
        }, {
          app: this.options.app
        });
        this.viewModel.destroyWith(this);
      }
      if (typeof this._initialize === "function") {
        this._initialize();
      }
    }

    View.prototype.artifact = function() {
      return this._artifact != null ? this._artifact : this._artifact = this._render();
    };

    View.prototype._render = function() {};

    View.prototype.pointer = function() {
      return this.pointer$ != null ? this.pointer$ : this.pointer$ = match(dynamic((function(_this) {
        return function(x) {
          if (isString(x) && (_this.subject.get != null)) {
            return _this.subject.get(x);
          } else if (isFunction(x)) {
            return Varying.of(x(_this.subject));
          } else {
            return Varying.of(x);
          }
        };
      })(this)), get((function(_this) {
        return function(x) {
          return _this.subject.get(x);
        };
      })(this)), subject((function(_this) {
        return function(x) {
          if (x != null) {
            return _this.subject.get(x);
          } else {
            return new Varying(_this.subject);
          }
        };
      })(this)), attribute((function(_this) {
        return function(x) {
          return new Varying(_this.subject.attribute(x));
        };
      })(this)), vm((function(_this) {
        return function(x) {
          var ref2;
          if (x != null) {
            return (ref2 = _this.viewModel) != null ? ref2.get(x) : void 0;
          } else {
            return new Varying(_this.viewModel);
          }
        };
      })(this)), varying((function(_this) {
        return function(x) {
          if (isFunction(x)) {
            return Varying.of(x(_this.subject));
          } else {
            return Varying.of(x);
          }
        };
      })(this)), app((function(_this) {
        return function(x) {
          if (x != null) {
            return _this.options.app.get(x);
          } else {
            return new Varying(_this.options.app);
          }
        };
      })(this)), self((function(_this) {
        return function(x) {
          if (isFunction(x)) {
            return Varying.of(x(_this));
          } else {
            return Varying.of(_this);
          }
        };
      })(this)));
    };

    View.prototype.reference = function(x) {
      var attr;
      attr = isString(x) ? this.subject.attribute(x) : x;
      attr.resolveWith(this.options.app);
      return this.reactTo(attr.model.get(attr.key), (function() {}));
    };

    View.prototype.subviews = function() {
      return new List();
    };

    View.prototype.subviews_ = function() {
      return [];
    };

    View.prototype.parent = function(selector) {
      return parent(selector, this);
    };

    View.prototype.parent_ = function(selector) {
      return parent_(selector, this);
    };

    View.prototype.closest = function(selector) {
      return closest(selector, this);
    };

    View.prototype.closest_ = function(selector) {
      return closest_(selector, this);
    };

    View.prototype.into = function(selector) {
      return into(selector, this);
    };

    View.prototype.into_ = function(selector) {
      return into_(selector, this);
    };

    View.prototype.intoAll = function(selector) {
      return intoAll(selector, this);
    };

    View.prototype.intoAll_ = function(selector) {
      return intoAll_(selector, this);
    };

    View.navigation = navigation;

    return View;

  })(Base);

  module.exports = {
    View: View
  };

}).call(this);
