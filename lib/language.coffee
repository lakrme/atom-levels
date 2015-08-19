{Emitter} = require('atom')
_         = require('underscore-plus')

# ------------------------------------------------------------------------------

module.exports =
class Language

  constructor: (@properties,levels) ->
    @emitter = new Emitter

    # set up the language levels
    @levelsByName = {}
    for level in levels
      level.setLanguage(@)
      @levelsByName[level.getName()] = level

  ## Event subscription --------------------------------------------------------

  onDidChangeProperties: (callback) ->
    @emitter.on('did-change-properties',callback)

  onDidAddLevel: (callback) ->
    @emitter.on('did-add-level',callback)

  onDidRemoveLevel: (callback) ->
    @emitter.on('did-remove-level',callback)

  ## Getting language properties -----------------------------------------------

  getName: ->
    @properties.name

  getDirectoryPath: ->
    @properties.dirPath

  getGrammarName: ->
    @properties.grammarName

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

  getExecutionMode: ->
    @properties.executionMode

  getInterpreterCommandPattern: ->
    @properties.interpreterCmdPattern

  getCompilerCommandPattern: ->
    @properties.compilerCmdPattern

  getExecutionCommandPattern: ->
    @properties.executionCmdPattern

  getLastActiveLevel: ->
    @properties.lastActiveLevel

  ## Setting language properties -----------------------------------------------

  setLastActiveLevel: (level) ->
    @setProperties({lastActiveLevel: level})

  setProperties: (newProperties) ->
    # save old property values and set new property values
    oldProperties = {}
    for name,newValue of newProperties
      if name of @properties and newValue isnt @properties[name]
        oldProperties[name] = @properties[name]
        @properties[name] = newValue
      else
        delete newProperties[name]

    # emit event if changes were made
    if Object.keys(newProperties).length isnt 0
      @emitter.emit('did-change-properties',{oldProperties,newProperties})
    undefined

  ## Managing language levels --------------------------------------------------

  addLevel: (level) ->
    # TODO to be implemented
    undefined

  removeLevel: (level) ->
    if @hasLevel(level)
      if level is @getLastActiveLevel()
        @setLastActiveLevel(undefined)
      delete @levelsByName[levelName]
      @emitter.emit('did-remove-level',level)
      return level
    undefined

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
