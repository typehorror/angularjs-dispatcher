# angularjs-dispatcher
An AngularJS implementation of the flux dispatcher

## Usage

Import dispatcher as a module dependency

```coffee
angular.module('my_app', ['dispatcher'])
```

the `dispatcher` is then loaded through the dependency on your stores

```coffee
angular.module('my_app').service('my_store', [
    'dispatcher',
    (dispatcher) ->
        listeners = []
        store =
            my_value: null
            addListener: (callback) ->
                listeners.push(callback)

            removeListener: (callback) ->
                index = listeners.indexOf(callback)
                if index > -1
                    listeners.splice(index,1)

        onDispatch = (action, payload) ->
            switch action
                when 'FOO_ACTION'
                    store.my_value = payload
                when 'BAR_ACTION'
                    store.my_value = null

                else
                    return

            # announce the change to whatever is listening
            for callback in listeners
                callback()


        dispatcher.register(onDispatch)

        return store
])
```

Actions call start the dispatch

```coffee
angular.module('my_app').service('my_actions', [
    'dispatcher',
    (dispatcher) ->
        fooAction: (payload) ->
            dispatcher.dispatch('FOO_ACTION', payload)
        barAction: ->
            dispatcher.dispatch('BAR_ACTION')

])
```

Actions are triggered inside your controllers or other services:

```coffee
angular.module('my_app').controller('my_controller', [
    'my_actions', '$scope',
    (my_actions, $scope) ->
        $scope.onFooClick = ->
            my_actions.fooAction($scope.foo_value)

        $scope.onBarClick = ->
            my_actions.barAction()

])
```