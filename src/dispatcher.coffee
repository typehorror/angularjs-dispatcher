angular.module('dispatcher', []).service 'dispatcher',
    (
        dataContract
    ) ->
        @_callbacks = {}
        @_isHandled = {}
        @_isPending = {}
        @_lastID = number
        @_isDispatching = false

        @_prefix = 'ID_'

        invoke = (store) ->
            @_isPending[store] = true

            try
                @_callbacks[store](@_action, @_payload)
            catch e
                console.error e

            @_isHandled[store] = true

        constructor: (@_prefix) ->
            @dispatcher_logs = []
            @_isDispatching = false
            @_lastID = 1

        ###*
        Register a store callback and returns a deregistration method.
        name is an optional parameter allowing you to define a registration name
        for your store. This is to allow you to have reverse dependencies on the waitFor.
        ###
        register: (callback, name) ->
            if name of @_callbacks
                throw new Error("dispatcher.register(...): a store is already registered under #{name}.")

            unless name  # Generate an ID
                name = "#{_prefix}#{@_lastID++}"

            @_callbacks[name] = callback

            return name

        ###*
        Wait for a store digest cycle
        ###
        waitFor: (stores) ->
            unless @_isDispatching
                throw new Error("dispatcher.waitFor(...): must be called only while dispatching.")

            for store in stores
                if @_isPending[store]
                    throw new Error(
                        "dispatcher.waitFor(...): circular dependency detected while waiting for #{store}"
                    )

                invoke(store)
        ###*
        Replays a set of logs into the dispatcher
        ###
        replay: (logs) ->
          for log in logs
            @dispatch(log.action, log.payload)

          undefined

        ###*
        Unregister a store.
        ###
        unregister: (name) ->
            unless name of @_callbacks
                throw new Error("dispatcher.unregister(...): #{name} argument is not a registered callback.")

            delete @_callbacks[name]

        ###*
        Start dispatching action and payload to the stores
        ###
        dispatch: (action, payload) ->
            if window.__DEV__
                console.debug "Dispatch: #{action.name}", payload
                dataContract.check payload, action.schema
                @dispatcher_logs.push {action, payload}

            if @_isDispatching
                throw new Error('dispatcher.dispacth(...): Cannot dispacth while dispatching')

            @startDispatching(action, payload)

            for store in @_callbacks
                @invoke(store) unless @_isPending[store]

            @stopDispatching()

        ###*
        Return true if dispatcher is in the middle of a dispatch
        ###
        isDispatching: ->
            return @_isDispatching

        startDispatching: (action, payload) ->
            @_isDispatching = true
            @_action = action
            @_payload = payload

            for store in @_callbacks
                @_isHandled[store] = false
                @_isPending[store] = false

        stopDispatching: ->
            @_isDispatching = false
            @_action = null
            @_payload = null
