{Emitter}        = require('atom')

languageRegistry = require('./language-registry').getInstance()

workspaceUtils   = require('./workspace-utils')

Terminal         = require('./terminal')

# ------------------------------------------------------------------------------

module.exports =
class LevelCodeEditor

  ## Deserialization -----------------------------------------------------------

  atom.deserializers.add(this)
  @version: 1
  @deserialize: ({data},textEditor) ->
    if (language = languageRegistry.getLanguageForName(data.languageName))?
      level = language.getLevelForName(data.levelName)
      terminal = atom.deserializers.deserialize(data.terminalState)
      return new LevelCodeEditor({textEditor,language,level,terminal})
    undefined

  ## Construction and destruction ----------------------------------------------

  constructor: ({@textEditor,language,level,@terminal}) ->
    @emitter = new Emitter
    @setLanguage(language,level)
    @terminal ?= new Terminal
    @terminal.acquire()

    # subscribe to text buffer
    @willSaveSubscr = @textEditor.getBuffer().onWillSave =>
      @writeLanguageInformationFileHeaderIf('before saving the buffer')

  destroy: ->
    @willSaveSubscr.dispose()
    @terminal.release()
    @emitter.emit('did-destroy')

  ## Event subscription --------------------------------------------------------

  observeLanguage: (callback) ->
    callback({language: @language,level: @level})
    @onDidChangeLanguage(callback)

  onDidChangeLanguage: (callback) ->
    @emitter.on('did-change-language',callback)

  observeLevel: (callback) ->
    callback(@level)
    @onDidChangeLevel(callback)

  onDidChangeLevel: (callback) ->
    @emitter.on('did-change-level',callback)

  onDidDestroy: (callback) ->
    @emitter.on('did-destroy',callback)

  onDidStartExecution: (callback) ->
    @terminal.onDidStartExecution (levelCodeEditor) =>
      callback() if levelCodeEditor.getId() is @getId()

  onDidStopExecution: (callback) ->
    @terminal.onDidStopExecution (levelCodeEditor) =>
      callback() if levelCodeEditor.getId() is @getId()

  ## Associated entities and derived properties and methods --------------------

  getTextEditor: ->
    @textEditor

  getId: ->
    @textEditor.id

  getPath: ->
    @textEditor.getPath()

  getLanguage: ->
    @language

  getExecutionMode: ->
    @language.getExecutionMode()

  getLevel: ->
    @level

  getTerminal: ->
    @terminal

  isExecuting: ->
    @terminal.isExecuting()

  startExecution: ->
    @terminal.startExecution(@)

  stopExecution: ->
    @terminal.stopExecution(@)

  ## Writing language information to the file header ---------------------------

  writeLanguageInformationFileHeaderIf: (condition) ->
    configKey = 'levels.whenToWriteFileHeader'
    whenToWriteFileHeader = atom.config.get(configKey)
    if whenToWriteFileHeader is condition
      workspaceUtils.deleteLanguageInformationFileHeader(@textEditor)
      workspaceUtils.writeLanguageInformationFileHeader(@textEditor,\
        @language,@level)

  ## Setting the language and the level ----------------------------------------

  setLanguage: (language,level) ->
    if language.getName() is @language?.getName()
      @setLevel(level) if level?
    else
      @language = language
      @setLevel(level ? @language.getLevelOnInitialization())
      @emitter.emit 'did-change-language',
        language: @language
        level: @level

  setLevel: (level) ->
    if @language.hasLevel(level)
      unless level.getName() is @level?.getName()
        @level = level
        @textEditor.setGrammar(@level.getGrammar())
        @writeLanguageInformationFileHeaderIf('after setting the level')
        @emitter.emit('did-change-level',@level)

  ## Serialization -------------------------------------------------------------

  serialize: ->
    version: @constructor.version
    deserializer: 'LevelCodeEditor'
    data:
      languageName: @language.getName()
      levelName: @level.getName()
      terminalState: @terminal.serialize()

# ------------------------------------------------------------------------------
