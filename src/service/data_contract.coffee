###
DataContract module
###

angular.module('dispatcher').service 'dataContract', ->
  check: (data, contract) ->
    if _.isString contract
      if typeof data isnt contract
        console.debug "Contract breach: #{data}: ", data
        throw Error "Contract breach: expect #{data} to be of type #{contract}, instead found #{typeof data}",

    else
      for key, prop of contract
        if _.isArray prop
          unless _.isArray data[key]
            console.debug "Contract breach: #{key}: ", data[key]
            throw Error "Contract breach: expect '#{key}' (#{prop}) to be an array, instead found #{typeof data[key]}"

          for sub_data in data[key]
            @check sub_data, prop[0]

        else if _.isObject prop
          @check data[key], prop

        else
          if data[key] and typeof data[key] isnt prop
            console.debug "Contract breach: #{key}: ", data[key]
            throw Error "Contract breach: expect '#{key}' (#{data[key]}) to be a #{prop}, instead found #{typeof data[key]}"
