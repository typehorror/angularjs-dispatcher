angular.module('dispatcher', []).service('dispatcher', function(dataContract) {
  var dispatch_scope, dispatcher_logs, isDispatching, isHandled, isPending, lastID, prefix, registry;
  registry = {};
  isHandled = {};
  isPending = {};
  lastID = 1;
  isDispatching = false;
  prefix = 'ID_';
  dispatcher_logs = [];
  dispatch_scope = {
    action: null,
    payload: null
  };
  return {

    /**
    Trigger the callback registered by a given store
    
    Error is catched and logged but does not break to prevent
    other store from being dispatched to.
     */
    invoke: function(store) {
      var e, error;
      isPending[store] = true;
      try {
        registry[store](dispatch_scope.action, dispatch_scope.payload);
      } catch (error) {
        e = error;
        console.error(e);
      }
      return isHandled[store] = true;
    },

    /**
    Register a store callback and returns a deregistration method.
    
    name is an optional parameter allowing you to define a registration name
    for your store. This is to allow you to have reverse dependencies on the waitFor:
    - X-provider can depend on Y-provider through angular DI
    - Y-provider can waitFor X-provider without creating a circular dependency
    
        >>> dispatcher.waitFor('X')  # no need to import X-provider here
     */
    register: function(callback, name) {
      if (!name) {
        name = "" + prefix + (lastID++);
      }
      if (name in registry) {
        throw new Error("dispatcher.register(...): a store is already registered under " + name + ".");
      }
      registry[name] = callback;
      return name;
    },

    /**
    Wait for a store or a list of store digest cycle
     */
    waitFor: function(stores) {
      var i, len, results, store;
      if (!isDispatching) {
        throw new Error("dispatcher.waitFor(...): must be called only while dispatching.");
      }
      if (!_.isArray(stores)) {
        stores = [stores];
      }
      results = [];
      for (i = 0, len = stores.length; i < len; i++) {
        store = stores[i];
        if (isPending[store]) {
          throw new Error("dispatcher.waitFor(...): circular dependency detected while waiting for " + store);
        }
        results.push(this.invoke(store));
      }
      return results;
    },

    /**
    Replays a set of logs into the dispatcher
     */
    replay: function(logs) {
      var i, len, log, results;
      results = [];
      for (i = 0, len = logs.length; i < len; i++) {
        log = logs[i];
        results.push(this.dispatch(log.action, log.payload));
      }
      return results;
    },

    /**
    Unregister a store.
     */
    unregister: function(name) {
      if (!(name in registry)) {
        throw new Error("dispatcher.unregister(...): " + name + " is not a registered.");
      }
      return delete registry[name];
    },

    /**
    Start dispatching action and payload to the stores
     */
    dispatch: function(action, payload) {
      var callback, store;
      if (window.__DEV__) {
        console.debug("Dispatch: " + action.name, payload);
        dataContract.check(payload, action.schema);
        dispatcher_logs.push({
          action: action,
          payload: payload
        });
      }
      if (isDispatching) {
        throw new Error('dispatcher.dispacth(...): Cannot dispacth while dispatching');
      }
      this.startDispatching(action, payload);
      for (store in registry) {
        callback = registry[store];
        if (!isPending[store]) {
          this.invoke(store);
        }
      }
      return this.stopDispatching();
    },

    /**
    Return true if dispatcher is in the middle of a dispatch
     */
    isDispatching: function() {
      return isDispatching;
    },

    /**
    Start a new dispatch:
    - Cleanup tracking of what store is pending and handled
    - Attach action and payload to dispatcher object's scope
     */
    startDispatching: function(action, payload) {
      var callback, results, store;
      isDispatching = true;
      dispatch_scope.action = action;
      dispatch_scope.payload = payload;
      results = [];
      for (store in registry) {
        callback = registry[store];
        isHandled[store] = false;
        results.push(isPending[store] = false);
      }
      return results;
    },

    /**
    Finishes the dispatch cycle
     */
    stopDispatching: function() {
      isDispatching = false;
      dispatch_scope.action = null;
      return dispatch_scope.payload = null;
    }
  };
});


/*
DataContract module
 */
angular.module('dispatcher').service('dataContract', function() {
  return {
    check: function(data, contract) {
      var key, prop, results, sub_data;
      if (_.isString(contract)) {
        if (typeof data !== contract) {
          console.error("Contract breach: " + data + ": ", data);
          throw Error("Contract breach: expect " + data + " to be of type " + contract + ", instead found " + (typeof data));
        }
      } else {
        results = [];
        for (key in contract) {
          prop = contract[key];
          if (_.isArray(prop)) {
            if (!_.isArray(data[key])) {
              console.error("Contract breach: " + key + ": ", data[key]);
              throw Error("Contract breach: expect '" + key + "' (" + prop + ") to be an array, instead found " + (typeof data[key]));
            }
            results.push((function() {
              var i, len, ref, results1;
              ref = data[key];
              results1 = [];
              for (i = 0, len = ref.length; i < len; i++) {
                sub_data = ref[i];
                results1.push(this.check(sub_data, prop[0]));
              }
              return results1;
            }).call(this));
          } else if (_.isObject(prop)) {
            results.push(this.check(data[key], prop));
          } else {
            if (data[key] && typeof data[key] !== prop) {
              console.error("Contract breach: " + key + ": ", data[key]);
              throw Error("Contract breach: expect '" + key + "' (" + data[key] + ") to be a " + prop + ", instead found " + (typeof data[key]));
            } else {
              results.push(void 0);
            }
          }
        }
        return results;
      }
    }
  };
});
