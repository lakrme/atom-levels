{Emitter}     = require 'atom'
CSON          = require 'season'
languageUtils = require './language-utils'

module.exports =
class Language
  constructor: (@properties, levels) ->
    @emitter = new Emitter

    @levelsByName = {}
    for level in levels
      level.setLanguage this
      @levelsByName[level.getName()] = level

  observe: (callback) ->
    callback()
    @onDidChange (event) -> callback()

  onDidChange: ->
    switch arguments.length
      when 1 then [callback] = arguments
      when 2 then [property, callback] = arguments
    @emitter.on 'did-change', (event) ->
      if !property? || property == event.property
        callback event

  getName: ->
    return @properties.name

  getLevels: ->
    levels = (level for _, level of @levelsByName)
    return levels.sort (e1, e2) -> if e1.getNumber() >= e2.getNumber() then 1 else -1

  getLevelsByName: ->
    return @levelsByName

  getLevelForNumber: (levelNumber) ->
    for _, level of @levelsByName
      if level.getNumber() == levelNumber
        return level

  getLevelForName: (levelName) ->
    return @levelsByName[levelName]

  getLastActiveLevel: ->
    return @properties.lastActiveLevel

  getLevelOnInitialization: ->
    return @getLastActiveLevel() ? @getLevelForNumber 0

  getObjectCodeFileType: ->
    return @properties.objectCodeFileType

  getExecutionCommandPatterns: ->
    return @properties.executionCommandPatterns

  getConfigFilePath: ->
    return @properties.configFilePath

  getRunExecPath: ->
    return @properties.executablePath

  getDummyGrammar: ->
    return @properties.dummyGrammar

  getDefaultGrammar: ->
    return @properties.defaultGrammar

  getGrammarName: ->
    return @properties.grammarName

  getScopeName: ->
    return @properties.scopeName

  getLevelCodeFileTypes: ->
    return @properties.levelCodeFileTypes

  getLineCommentPattern: ->
    return @properties.lineCommentPattern

  getExecutionMode: ->
    if @properties.executionCommandPatterns.length > 0
      return 'yes'

  setObjectCodeFileType: (objectCodeFileType) ->
    @setPropertyAndUpdateConfigFile 'objectCodeFileType', objectCodeFileType
    return

  setExecutionCommandPatterns: (executionCommandPatterns) ->
    @setPropertyAndUpdateConfigFile 'executionCommandPatterns', executionCommandPatterns
    return

  setDummyGrammar: (dummyGrammar) ->
    @setPropertyAndUpdateConfigFile 'dummyGrammar', dummyGrammar
    return

  setLevelCodeFileTypes: (levelCodeFileTypes) ->
    @setPropertyAndUpdateConfigFile 'levelCodeFileTypes', levelCodeFileTypes
    return

  setLineCommentPattern: (lineCommentPattern) ->
    @setPropertyAndUpdateConfigFile 'lineCommentPattern', lineCommentPattern
    return

  setLastActiveLevel: (lastActiveLevel) ->
    @setPropertyAndUpdateConfigFile 'lastActiveLevel', lastActiveLevel
    return

  setPropertyAndUpdateConfigFile: (property, value) ->
    oldValue = @properties[property]
    newValue = value
    @properties[property] = newValue
    @emitter.emit 'did-change', {property, oldValue, newValue}
    @updateConfigFile {property, value}
    return

  updateConfigFile: ({property, value}) ->
    if languageUtils.isConfigFileKey property
      configFilePath = @properties.configFilePath
      configFile = CSON.readFileSync configFilePath
      convertedValue = languageUtils.toConfigFileValue property, value
      configFile[property] = convertedValue
      CSON.writeFileSync configFilePath, configFile
    return

  hasLevel: (level) ->
    return level.getLanguage() == this && @getLevelForName(level.getName())