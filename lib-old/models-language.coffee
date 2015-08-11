{Emitter} = require 'atom'
CSON      = require 'season'
path      = require 'path'

# ------------------------------------------------------------------------------

module.exports =
class Language

  constructor: (languageObject) ->
    @[key] = value for key,value of languageObject
    @emitter = new Emitter

  ## Querying language properties ----------------------------------------------

  levelForId: (levelId) ->
    @levels[levelId]

  levelForName: (levelName) ->
    @levelsByName[levelName]

  levelOnInitialization: ->
    @lastActiveLevel ? @levels[0]

  ## Updating language properties ----------------------------------------------

  setLastActiveLevel: (lastActiveLevel) ->
    @update({lastActiveLevel: lastActiveLevel.name})

  setExecutionMode: (executionMode) ->
    @update({executionMode})

  setInterpreterCmdPattern: (interpreterCmdPattern) ->
    @update({interpreterCmdPattern})

  setCompilerCmdPattern: (compilerCmdPattern) ->
    @update({compilerCmdPattern})

  setExecutionCmdPattern: (executionCmdPattern) ->
    @update({executionCmdPattern})

  update: (updates) ->
    @[key] = value for key,value of updates
    @updateLanguageConfigFile(updates)

  updateLanguageConfigFile: (updates) ->
    languageObjectPath = path.join(@dirPath,'config.json')
    languageObject = CSON.readFileSync(languageObjectPath)
    languageObject[key] = value for key,value of updates
    CSON.writeFileSync(languageObjectPath,languageObject)
    @emitter.emit('did-update',updates)

  ## Event subscriptions -------------------------------------------------------

  onDidUpdate: (callback) ->
    @emitter.on('did-update',callback)

# ------------------------------------------------------------------------------
