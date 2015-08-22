{Emitter}      = require('atom')

workspaceUtils = require('./workspace-utils')

Terminal       = require('./terminal')

# ------------------------------------------------------------------------------

module.exports =
class LevelCodeEditor

  ## Construction and destruction ----------------------------------------------

  constructor: ({@textEditor,language,level,@terminal}) ->
    @emitter = new Emitter
    @setLanguage(language,level)
    @terminal ?= new Terminal
    @terminal.addLevelCodeEditor(@)
    @active = false

    # subscribe to text buffer
    @willSaveSubscr = @textEditor.getBuffer().onWillSave =>
      @writeLanguageInformationFileHeaderIf('before saving the buffer')

  destroy: ->
    @willSaveSubscr.dispose()
    @emitter.emit('did-destroy')

  ## Event subscription --------------------------------------------------------

  onDidChangeLanguage: (callback) ->
    @emitter.on('did-change-language',callback)

  onDidChangeLevel: (callback) ->
    @emitter.on('did-change-level',callback)

  onDidDestroy: (callback) ->
    @emitter.on('did-destroy',callback)

  ## Text editor properties and methods ----------------------------------------

  getId: ->
    @textEditor.id

  getPath: ->
    @textEditor.getPath()

  ## Associated entities -------------------------------------------------------

  getTextEditor: ->
    @textEditor

  getLanguage: ->
    @language

  getLevel: ->
    @level

  getTerminal: ->
    @terminal

  ## Writing language informations to the file header --------------------------

  writeLanguageInformationFileHeaderIf: (condition) ->
    configKey = 'levels.workspaceSettings.whenToWriteFileHeader'
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
      @emitter.emit('did-change-language',{@language,@level})

  setLevel: (level) ->
    if @language.hasLevel(level)
      unless level.getName() is @level?.getName()
        @level = level
        @textEditor.setGrammar(@level.getGrammar())
        @writeLanguageInformationFileHeaderIf('after setting the level')
        @emitter.emit('did-change-level',@level)

# ------------------------------------------------------------------------------
