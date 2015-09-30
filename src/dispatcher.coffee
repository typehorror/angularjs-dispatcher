angular.module('dispatcher', []).service 'dispatcher', ->
    _callbacks = []
    _isDispatching = false

    ###*
    Register a store callback and returns a deregistration method.
    ###
    register: (callback) ->
        _callbacks.push(callback)
        return =>
            @unregister(callback)

    ###*
    Unregister a store.
    ###
    unregister: (callback) ->
        index = _callbacks.indexOf(callback)

        if index < 0
            throw new Error('dispatcher.unregister(...): callback argument is not a registered callback.')

        _callbacks.splice(index, 1)

    ###*
    Start dispatching action and payload to the stores
    ###
    dispatch: (action, payload) ->
        if _isDispatching
            throw new Error('dispatcher.dispacth(...): Cannot dispacth while dispatching')

        _isDispatching = true

        try
            for callback in _callbacks
                callback(action, payload)

        finally
            _isDispatching = false

    ###*
    Return true if dispatcher is in the middle of a dispatch
    ###
    isDispatching: ->
        return _isDispatching