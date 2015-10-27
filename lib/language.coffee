{Emitter} = require('atom')
path      = require('path')
CSON      = require('season')
_         = require('underscore-plus')

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

  observe: (callback) ->
    callback()
    @onDidChange((changes) -> callback())

  onDidChange: (callback) ->
    @emitter.on('did-change',callback)

  ## Getting language properties -----------------------------------------------

  getName: ->
    @properties.name

  getLastActiveLevel: ->
    @properties.lastActiveLevel

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

  getObjectCodeFileType: ->
    @properties.objectCodeFileType

  getLineCommentPattern: ->
    @properties.lineCommentPattern

  getConfigurationFilePath: ->
    @properties.configFilePath

  getExecutablePath: ->
    @properties.executablePath

  getExecutionMode: ->
    if @properties.executionMode?
      return @properties.executionMode
    if (executionModes = @getExecutionModes()).length isnt 0
      return @properties.executionMode = executionModes[0]
    undefined

  getInterpreterCommandPattern: ->
    @properties.interpreterCmdPattern

  getCompilerCommandPattern: ->
    @properties.compilerCmdPattern

  getExecutionCommandPattern: ->
    @properties.executionCmdPattern

  ## Setting language properties -----------------------------------------------

  setLastActiveLevel: (level) ->
    @set({newProperties: {lastActiveLevel: level}})

  setDummyGrammar: (dummyGrammar) ->
    @properties.dummyGrammar = dummyGrammar

  setLevelCodeFileTypes: (levelCodeFileTypes) ->
    @set({newProperties: {levelCodeFileTypes}})

  setObjectCodeFileType: (objectCodeFileType) ->
    @set({newProperties: {objectCodeFileType}})

  setLineCommentPattern: (lineCommentPattern) ->
    @set({newProperties: {lineCommentPattern}})

  set: (changes) ->
    # apply language property changes
    if (newProperties = changes?.newProperties)?
      oldProperties = {}
      for name,newValue of newProperties
        if name of @properties and newValue isnt @properties[name]
          oldProperties[name] = @properties[name]
          # TODO apply changes to grammars etc.
          @properties[name] = newValue
        else
          delete newProperties[name]

      if Object.keys(newProperties).length isnt 0
        propertyChanges = {oldProperties,newProperties}

    # apply level changes
    if (newLevelPropertiesByLevelName = changes?.newLevelPropertiesByLevelName)?
      levelChangesByLevelName = undefined
      for levelName,newLevelProperties of newLevelPropertiesByLevelName
        if (level = @getLevelForName(levelName))?
          if (result = level.set(newLevelProperties))?
            levelChangesByLevelName ?= {}
            levelChangesByLevelName[levelName] = {}
            levelChangesByLevelName[levelName].oldProperties = \
              result.oldProperties
            levelChangesByLevelName[levelName].newProperties = \
              result.newProperties

    # emit event if changes were made
    if propertyChanges? or levelChangesByLevelName?
      changes = {propertyChanges,levelChangesByLevelName}
      @emitter.emit('did-change',changes)
      @applyLanguageChanges(@,changes)
    undefined

  writeLanguageToConfigurationFile: (language,configFilePath) ->
    defaultGrammarPath = language.getDefaultGrammar().path
    configDirPath = path.dirname(configFilePath)

    config = {}
    config.name = language.getName()

    config.levels =
      for level in language.getLevels()
        name = level.getName()
        description = level.getDescription()
        grammar = undefined
        grammarPath = level.getGrammar().path
        unless grammarPath is defaultGrammarPath
          grammar = path.relative(configDirPath,grammarPath)
        {name,description,grammar}
    config.lastActiveLevel = language.getLastActiveLevel()?.getName()
    if defaultGrammarPath?
      config.defaultGrammar = path.relative(configDirPath,defaultGrammarPath)

    config.levelCodeFileTypes = language.getLevelCodeFileTypes()
    config.objectCodeFileType = language.getObjectCodeFileType()
    config.lineCommentPattern = language.getLineCommentPattern()
    config.executionMode = language.getExecutionMode()
    config.interpreterCmdPattern = language.getInterpreterCommandPattern()
    config.compilerCmdPattern = language.getCompilerCommandPattern()
    config.executionCmdPattern = language.getExecutionCommandPattern()

    CSON.writeFileSync(configFilePath,config)
    undefined

  applyLanguageChanges: (language,changes) ->
    # TODO do something with the changes
    configFilePath = language.getConfigurationFilePath()
    @writeLanguageToConfigurationFile(language,configFilePath)
    undefined

  ## Managing language levels --------------------------------------------------

  getLevelForNumber: (levelNumber) ->
    for levelName,level of @levelsByName
      if level.getNumber() is levelNumber
        return level
    undefined

  getLevelForName: (levelName) ->
    @levelsByName[levelName]

  getLevelOnInitialization: ->
    @getLastActiveLevel() ? @getLevelForNumber(0)

  getLevels: ->
    levels = (level for levelName,level of @levelsByName)
    _.sortBy(levels,(level) -> level.getNumber())

  getLevelsByName: ->
    @levelsByName

  ## More interface methods ----------------------------------------------------

  hasLevel: (level) ->
    level.getLanguage() is @ and @getLevelForName(level.getName())?

# ------------------------------------------------------------------------------
