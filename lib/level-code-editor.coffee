{CompositeDisposable,Emitter} = require('atom')

languageRegistry              = require('./language-registry').getInstance()

notificationUtils             = require('./notification-utils')
workspaceUtils                = require('./workspace-utils')

AnnotationManager             = require('./annotation-manager')
ExecutionIssue                = require('./execution-issue')
ExecutionManager              = require('./execution-manager')
Terminal                      = require('./terminal')

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

    # create annotation and execution manager instances
    @annotationManager = new AnnotationManager(@)
    @executionManager = new ExecutionManager(@)

    # initialize properties
    @setLanguage(language,level)
    @terminal ?= new Terminal
    @terminal.acquire()

    # text buffer subscriptions
    @bufferSubscr = @textEditor.getBuffer().onWillSave =>
      @writeLanguageInformationFileHeaderIf('before saving the buffer')

    # terminal subscriptions
    @currentExecutionIssuesById = {}
    @terminalSubscrs = new CompositeDisposable
    @terminalSubscrs = @terminal.onDidReadTypedMessage (typedMessage) =>
      @readExecutionIssueFromTypedMessage(typedMessage)

  destroy: ->
    # dispose subscriptios
    @terminalSubscrs.dispose()
    @bufferSubscr.dispose()

    # TODO maybe display a notification here?
    @stopExecution()
    # ---------------------------------------
    @removeExecutionIssues()
    @terminal.release()

    @emitter.emit('did-destroy')

  ## Event subscription --------------------------------------------------------

  # Public: Invoke the given callback with the current language and all future
  # language changes of this level code editor.
  #
  # * `callback` {Function} to be called with the current language and all
  #   future language changes.
  #   * `event` An {Object} with the following keys:
  #     * `language` The new {Language} of the level code editor.
  #     * `level` The new {Level} of the level code editor.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  observeLanguage: (callback) ->
    callback({language: @language,level: @level})
    @onDidChangeLanguage(callback)

  # Public: Invoke the given callback when the language is changed for this
  # level code editor.
  #
  # * `callback` {Function} to be called when the language is changed.
  #   * `event` An {Object} with the following keys:
  #     * `language` The new {Language} of the level code editor.
  #     * `level` The new {Level} of the level code editor.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChangeLanguage: (callback) ->
    @emitter.on('did-change-language',callback)

  # Public: Invoke the given callback with the current level and all future
  # level changes of this level code editor.
  #
  # * `callback` {Function} to be called with the current level and all future
  #   level changes.
  #   * `level` The new {Level} of the level code editor.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  observeLevel: (callback) ->
    callback(@level)
    @onDidChangeLevel(callback)

  # Public: Invoke the given callback when the level is changed for this level
  # code editor.
  #
  # * `callback` {Function} to be called when the level is changed.
  #   * `level` The new {Level} of the level code editor.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChangeLevel: (callback) ->
    @emitter.on('did-change-level',callback)

  # Public: Invoke the given callback when the level code editor is destroyed.
  #
  # * `callback` {Function} to be called when the level code editor is
  #   destroyed.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidDestroy: (callback) ->
    @emitter.on('did-destroy',callback)

  observeIsExecuting: (callback) ->
    callback(@isExecuting())
    @onDidChangeIsExecuting(callback)

  onDidChangeIsExecuting: (callback) ->
    @emitter.on('did-change-is-executing',callback)

  onDidStartExecution: (callback) ->
    @emitter.on('did-start-execution',callback)

  onDidStopExecution: (callback) ->
    @emitter.on('did-stop-execution',callback)

  ## Associated entities and derived properties and methods --------------------

  getTextEditor: ->
    @textEditor

  getId: ->
    @textEditor.id

  getLanguage: ->
    @language

  getExecutionMode: ->
    @language.getExecutionMode()

  getLevel: ->
    @level

  getTerminal: ->
    @terminal

  ## Setting the language and the level ----------------------------------------

  setLanguage: (language,level) ->
    if @isExecuting()
      @restore()
      throw {name: 'ExecutionIsRunningError'}

    if language.getName() is @language?.getName()
      @setLevel(level) if level?
    else
      @language = language
      @setLevel(level ? @language.getLevelOnInitialization())
      @emitter.emit 'did-change-language',
        language: @language
        level: @level

  setLevel: (level) ->
    if @isExecuting()
      throw {name: 'ExecutionIsRunningError'}

    if @language.hasLevel(level)
      unless level.getName() is @level?.getName()
        @level = level
        @textEditor.setGrammar(@level.getGrammar())
        @writeLanguageInformationFileHeaderIf('after setting the level')
        @emitter.emit('did-change-level',@level)

  restore: ->
    @textEditor.setGrammar(@level.getGrammar())

  ## Writing language information to the file header ---------------------------

  writeLanguageInformationFileHeaderIf: (condition) ->
    configKeyPath = 'levels.workspaceSettings.whenToWriteFileHeader'
    whenToWriteFileHeader = atom.config.get(configKeyPath)
    if whenToWriteFileHeader is condition
      workspaceUtils.deleteLanguageInformationFileHeader(@textEditor)
      workspaceUtils.writeLanguageInformationFileHeader(@textEditor,\
        @language,@level)

  ## Level code execution ------------------------------------------------------

  isExecuting: ->
    @executionManager.isExecuting()

  startExecution: ->
    @executionManager.startExecution()

  didStartExecution: ->
    @removeExecutionIssues()
    @emitter.emit('did-start-execution')
    @emitter.emit('did-change-is-executing',true)

  stopExecution: ->
    @executionManager.stopExecution()

  didStopExecution: ->
    @emitter.emit('did-stop-execution')
    @emitter.emit('did-change-is-executing',false)

  ## Managing execution issues -------------------------------------------------

  readExecutionIssueFromTypedMessage: (typedMessage) ->
    if @isExecuting()
      type = typedMessage.type
      source = typedMessage.data?.source
      if source? and (type is 'warning' or type is 'error')
        executionIssue = new ExecutionIssue @,
          id: typedMessage.id
          type: type
          source: source
          row: typedMessage.data.row
          column: typedMessage.data.col
          message: typedMessage.body
        @addExecutionIssue(executionIssue)

  addExecutionIssue: (executionIssue) ->
    @currentExecutionIssuesById[executionIssue.getId()] = executionIssue
    @annotationManager.addAnnotationForExecutionIssue(executionIssue)

  removeExecutionIssue: (executionIssue) ->
    @annotationManager.removeAnnotationForExecutionIssue(executionIssue)
    delete @currentExecutionIssuesById[executionIssue.getId()]
    executionIssue.destroy()

  removeExecutionIssues: ->
    for _,executionIssue of @currentExecutionIssuesById
      @removeExecutionIssue(executionIssue)

  getCurrentExecutionIssueById: (executionIssueId) ->
    @currentExecutionIssuesById[executionIssueId]

  getCurrentExecutionIssues: ->
    executionIssue for _,executionIssue of @currentExecutionIssuesById

  ## Serialization -------------------------------------------------------------

  serialize: ->
    version: @constructor.version
    deserializer: 'LevelCodeEditor'
    data:
      languageName: @language.getName()
      levelName: @level.getName()
      terminalState: @terminal.serialize()

# ------------------------------------------------------------------------------
