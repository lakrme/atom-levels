{Emitter} = require('atom')

# ------------------------------------------------------------------------------

module.exports =
class Language

  constructor: (languageObject) ->
    @emitter = new Emitter
    # initialize language properties
    @[key] = value for key,value of languageObject
    # set references for the language levels
    level.setLanguage(@) for level in @levels

  ## Event subscription --------------------------------------------------------

  onDidUpdate: (callback) ->
    @emitter.on('did-update',callback)

  ## Querying language properties ----------------------------------------------

  levelForName: (levelName) ->
    @levelsByName[levelName]

  levelOnInitialization: ->
    @lastActiveLevel ? @levels[0]

  ## Updating language properties ----------------------------------------------

  # update: (newProperties) ->
  #   oldProperties = {}
  #   for name,value of newProperties
  #     oldProperties[name] = @[name]
  #     @[name] = value
  #   @emitter.emit('did-update',{oldProperties,newProperties})
  #
  # updateConfigurationFile:

# ------------------------------------------------------------------------------
