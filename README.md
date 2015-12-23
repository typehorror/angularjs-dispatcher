# angularjs-dispatcher
An AngularJS implementation of the flux dispatcher

## Usage

Import dispatcher as a module dependency

```coffee
angular.module('my_app', ['dispatcher'])
```

the `dispatcher` is then loaded through the dependency on your stores

```coffee
angular.module('my_app').service 'my_store',
    (
        dispatcher
    ) ->
        store =
            my_value: null
            change_event: 'change:my_store'

        onDispatch = (action, payload) ->
            switch action
                when 'FOO_ACTION'
                    store.my_value = payload
                when 'BAR_ACTION'
                    store.my_value = null
                else
                    return

            # broadcast this store has changed
            $rootScope.$broadcast store.change_event, store


        dispatcher.register(onDispatch)

        return store
```

Actions call start the dispatch

```coffee
angular.module('my_app').service 'my_actions',
    (
        dispatcher
    ) ->
        fooAction: (payload) ->
            dispatcher.dispatch('FOO_ACTION', payload)
        barAction: ->
            dispatcher.dispatch('BAR_ACTION')
```

Actions are triggered inside your controllers or other services:

```coffee
angular.module('my_app').controller 'my_controller',
    (
        my_actions
        my_store
        $scope
    ) ->
        $scope.onFooClick = ->
            my_actions.fooAction($scope.foo_value)

        $scope.onBarClick = ->
            my_actions.barAction()

        $scope.$on my_store.change_event, (event, store) ->
            $scope.my_value = store.my_value
```
