{Emitter}     = require('atom')
path          = require('path')
CSON          = require('season')

languageUtils = require('./language-utils')

# ------------------------------------------------------------------------------

module.exports =
class Language

  ## Construction --------------------------------------------------------------

  constructor: (@properties,levels) ->
    @emitter = new Emitter

    # set up the language levels
    @levelsByName = {}
    for level in levels
      level.setLanguage(@)
      @levelsByName[level.getName()] = level

  ## Event subscription --------------------------------------------------------

  # Public: Invoke the given callback with the current state of the language and
  # all future changes to its properties.
  #
  # * `callback` {Function} to be called with current state of the language and
  #   future changes to it.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  observe: (callback) ->
    callback()
    @onDidChange((event) -> callback())

  # Public: Invoke the given callback when a (certain) language property
  # changes.
  #
  # If `property` is not specified, your callback will be called on changes to
  # any language property.
  #
  # * `property` (optional) The {String} name of the language property to
  #   observe.
  # * `callback` {Function} to be called when a (certain) language property
  #   changes.
  #   * `event` An {Object} containing the name, the old value and the new value
  #     of the language property that has been changed.
  #     * `property` The {String} name of the property.
  #     * `oldValue` The old value of the property.
  #     * `newValue` The new value of the property.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChange: ->
    switch arguments.length
      when 1 then [callback] = arguments
      when 2 then [property,callback] = arguments
    @emitter.on 'did-change', (event) ->
      if not property? or property is event.property
        callback(event)

  ## Getting language properties -----------------------------------------------

  getName: ->
    @properties.name

  getLevels: ->
    levels = (level for levelName,level of @levelsByName)
    levels.sort (e1, e2) -> if e1.getNumber() >= e2.getNumber() then 1 else -1

  getLevelsByName: ->
    @levelsByName

  getLevelForNumber: (levelNumber) ->
    for levelName,level of @levelsByName
      if level.getNumber() is levelNumber
        return level
    undefined

  getLevelForName: (levelName) ->
    @levelsByName[levelName]

  getLastActiveLevel: ->
    @properties.lastActiveLevel

  getLevelOnInitialization: ->
    @getLastActiveLevel() ? @getLevelForNumber(0)

  getObjectCodeFileType: ->
    @properties.objectCodeFileType

  getExecutionCommandPatterns: ->
    @properties.executionCommandPatterns

  getConfigFilePath: ->
    @properties.configFilePath

  getRunExecPath: ->
    @properties.executablePath

  getDummyGrammar: ->
    @properties.dummyGrammar

  getDefaultGrammar: ->
    @properties.defaultGrammar

  getGrammarName: ->
    @properties.grammarName

  getScopeName: ->
    @properties.scopeName

  getLevelCodeFileTypes: ->
    @properties.levelCodeFileTypes

  getLineCommentPattern: ->
    @properties.lineCommentPattern

  # TODO remove this when the calls in terminal-panel-view has been removed
  getExecutionMode: ->
    if @properties.executionCommandPatterns.length > 0
      return "yes"
    undefined
  # ----------------

  ## Setting language properties -----------------------------------------------

  setObjectCodeFileType: (objectCodeFileType) ->
    @setPropertyAndUpdateConfigFile\
      ('objectCodeFileType',objectCodeFileType)

  setExecutionCommandPatterns: (executionCommandPatterns) ->
    @setPropertyAndUpdateConfigFile\
      ('executionCommandPatterns',executionCommandPatterns)

  setDummyGrammar: (dummyGrammar) ->
    @setPropertyAndUpdateConfigFile\
      ('dummyGrammar',dummyGrammar)

  setLevelCodeFileTypes: (levelCodeFileTypes) ->
    @setPropertyAndUpdateConfigFile\
      ('levelCodeFileTypes',levelCodeFileTypes)

  setLineCommentPattern: (lineCommentPattern) ->
    @setPropertyAndUpdateConfigFile\
      ('lineCommentPattern',lineCommentPattern)

  setLastActiveLevel: (lastActiveLevel) ->
    @setPropertyAndUpdateConfigFile\
      ('lastActiveLevel',lastActiveLevel)

  setPropertyAndUpdateConfigFile: (property,value) ->
    oldValue = @properties[property]
    newValue = value
    @properties[property] = newValue
    @emitter.emit('did-change',{property,oldValue,newValue})
    @updateConfigFile({property,value})

  updateConfigFile: ({property,value}) ->
    if languageUtils.isConfigFileKey(property)
      configFilePath = @properties.configFilePath
      configFile = CSON.readFileSync(configFilePath)
      convertedValue = languageUtils.toConfigFileValue(property,value,@)
      configFile[property] = convertedValue
      CSON.writeFileSync(configFilePath,configFile)

  ## Other interface methods ---------------------------------------------------

  hasLevel: (level) ->
    level.getLanguage() is @ and @getLevelForName(level.getName())?

# ------------------------------------------------------------------------------
