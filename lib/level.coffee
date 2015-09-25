{Emitter} = require('atom')

# ------------------------------------------------------------------------------

module.exports =
class Level

  constructor: (@properties) ->
    @emitter = new Emitter

  ## Event subscription --------------------------------------------------------

  observe: (callback) ->
    callback()
    @onDidChange((changes) -> callback())

  onDidChange: (callback) ->
    @emitter.on('did-change',callback)

  ## Getting level properties --------------------------------------------------

  getNumber: ->
    @properties.number

  getName: ->
    @properties.name

  getDescription: ->
    @properties.description

  getGrammar: ->
    @properties.grammar

  ## Setting level properties --------------------------------------------------

  set: (newProperties) ->
    oldProperties = {}
    for name,newValue of newProperties
      if name of @properties and newValue isnt @properties[name]
        oldProperties[name] = @properties[name]
        # TODO apply changes to grammars etc.
        @properties[name] = newValue
      else
        delete newProperties[name]

    # emit event if changes were made
    if Object.keys(newProperties).length isnt 0
      @emitter.emit('did-change',{oldProperties,newProperties})
      return {oldProperties,newProperties}
    undefined

  ## Managing the associated language ------------------------------------------

  getLanguage: ->
    @language

  setLanguage: (@language) ->

# ------------------------------------------------------------------------------
