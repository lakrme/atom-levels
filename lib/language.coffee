{Emitter} = require('atom')
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

  getInstallationDate: ->
    @properties.installationDate

  getLastActiveLevel: ->
    @properties.lastActiveLevel

  getDefaultGrammar: ->
    @properties.defaultGrammar

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

  getExecutionModes: ->
    executionModes = []
    interpreterCmdPattern = @getInterpreterCommandPattern()
    compilerCmdPattern = @getCompilerCommandPattern()
    executionCmdPattern = @getExecutionCommandPattern()
    if interpreterCmdPattern?
      executionModes.push('interpreted')
    if compilerCmdPattern? and executionCmdPattern?
      executionModes.push('compiled')
    executionModes

  getInterpreterCommandPattern: ->
    @properties.interpreterCmdPattern

  getCompilerCommandPattern: ->
    @properties.compilerCmdPattern

  getExecutionCommandPattern: ->
    @properties.executionCmdPattern

  ## Setting language properties -----------------------------------------------

  setLastActiveLevel: (level) ->
    @set({newProperties: {lastActiveLevel: level}})

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
      @emitter.emit('did-change',{propertyChanges,levelChangesByLevelName})
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
    languageName = level.getLanguage().getName()
    levelName = level.getName()
    languageName is @getName() and @getLevelForName(levelName)?

# ------------------------------------------------------------------------------
