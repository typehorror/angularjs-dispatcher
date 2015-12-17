angular.module('dispatcher', []).service 'dispatcher',
    (
        dataContract
    ) ->
        @registry = {}
        @isHandled = {}
        @isPending = {}
        @lastID = 1
        @isDispatching = false

        @prefix = 'ID_'
        @dispatcher_logs = []


        ###*
        Trigger the callback registered by a given store

        Error is catched and logged but does not break to prevent
        other store from being dispatched to.
        ###
        invoke = (store) ->
            @isPending[store] = true

            try
                @registry[store](@action, @payload)
            catch e
                console.error e

            @isHandled[store] = true


        ###*
        Register a store callback and returns a deregistration method.

        name is an optional parameter allowing you to define a registration name
        for your store. This is to allow you to have reverse dependencies on the waitFor:
        - X-provider can depend on Y-provider through angular DI
        - Y-provider can waitFor X-provider without creating a circular dependency

            >>> dispatcher.waitFor('X')  # no need to import X-provider here
        ###
        register: (callback, name) ->
            if name of @registry
                throw new Error("dispatcher.register(...): a store is already registered under #{name}.")

            unless name  # Generate an ID
                name = "#{_prefix}#{@lastID++}"

            @registry[name] = callback

            return name


        ###*
        Wait for a store or a list of store digest cycle
        ###
        waitFor: (stores) ->
            unless @isDispatching
                throw new Error("dispatcher.waitFor(...): must be called only while dispatching.")

            # Cast to an array if not already one
            unless _.isArray stores
                stores = [stores]

            for store in stores
                if @isPending[store]
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


        ###*
        Unregister a store.
        ###
        unregister: (name) ->
            unless name of @registry
                throw new Error("dispatcher.unregister(...): #{name} is not a registered.")

            delete @registry[name]


        ###*
        Start dispatching action and payload to the stores
        ###
        dispatch: (action, payload) ->
            if window.__DEV__
                console.debug "Dispatch: #{action.name}", payload
                dataContract.check payload, action.schema
                @dispatcher_logs.push {action, payload}

            if @isDispatching
                throw new Error('dispatcher.dispacth(...): Cannot dispacth while dispatching')

            @startDispatching(action, payload)

            for store in @registry
                @invoke(store) unless @isPending[store]

            @stopDispatching()


        ###*
        Return true if dispatcher is in the middle of a dispatch
        ###
        isDispatching: ->
            return @isDispatching


        ###*
        Start a new dispatch:
        - Cleanup tracking of what store is pending and handled
        - Attach action and payload to dispatcher object's scope
        ###
        startDispatching: (action, payload) ->
            @isDispatching = true
            @action = action
            @payload = payload

            for store in @registry
                @isHandled[store] = false
                @isPending[store] = false


        ###*
        Finishes the dispatch cycle
        ###
        stopDispatching: ->
            @isDispatching = false
            @action = null
            @payload = null
