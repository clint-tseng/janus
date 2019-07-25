// Generated by CoffeeScript 1.12.2
(function() {
  var CattedList, DerivedList, util,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  DerivedList = require('../list').DerivedList;

  util = require('../../util/util');

  CattedList = (function(superClass) {
    extend(CattedList, superClass);

    function CattedList(lists) {
      var fn, i, len, list, listIdx, ref;
      this.lists = lists;
      CattedList.__super__.constructor.call(this);
      this.list = util.foldLeft([])(this.lists, function(elems, list) {
        return elems.concat(list.list);
      });
      ref = this.lists;
      fn = (function(_this) {
        return function(list, listIdx) {
          var getOverallIdx;
          getOverallIdx = function(itemIdx) {
            return util.foldLeft(0)(_this.lists.slice(0, listIdx), function(length, list) {
              return length + list.list.length;
            }) + itemIdx;
          };
          _this.listenTo(list, 'added', function(elem, idx) {
            return _this._add(elem, getOverallIdx(idx));
          });
          _this.listenTo(list, 'removed', function(_, idx) {
            return _this._removeAt(getOverallIdx(idx));
          });
          return _this.listenTo(list, 'moved', function(_, idx, oldIdx) {
            return _this._moveAt(getOverallIdx(oldIdx), getOverallIdx(idx));
          });
        };
      })(this);
      for (listIdx = i = 0, len = ref.length; i < len; listIdx = ++i) {
        list = ref[listIdx];
        fn(list, listIdx);
      }
    }

    return CattedList;

  })(DerivedList);

  module.exports = {
    CattedList: CattedList
  };

}).call(this);