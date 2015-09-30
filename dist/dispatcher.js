angular.module('dispatcher', []).service('dispatcher', function() {
  var _callbacks, _isDispatching;
  _callbacks = [];
  _isDispatching = false;
  return {

    /**
    Register a store callback and returns a deregistration method.
     */
    register: function(callback) {
      _callbacks.push(callback);
      return (function(_this) {
        return function() {
          return _this.unregister(callback);
        };
      })(this);
    },

    /**
    Unregister a store.
     */
    unregister: function(callback) {
      var index;
      index = _callbacks.indexOf(callback);
      if (index < 0) {
        throw new Error('dispatcher.unregister(...): callback argument is not a registered callback.');
      }
      return _callbacks.splice(index, 1);
    },

    /**
    Start dispatching action and payload to the stores
     */
    dispatch: function(action, payload) {
      var callback, i, len, results;
      if (_isDispatching) {
        throw new Error('dispatcher.dispacth(...): Cannot dispacth while dispatching');
      }
      _isDispatching = true;
      try {
        results = [];
        for (i = 0, len = _callbacks.length; i < len; i++) {
          callback = _callbacks[i];
          results.push(callback(action, payload));
        }
        return results;
      } finally {
        _isDispatching = false;
      }
    },

    /**
    Return true if dispatcher is in the middle of a dispatch
     */
    isDispatching: function() {
      return _isDispatching;
    }
  };
});
