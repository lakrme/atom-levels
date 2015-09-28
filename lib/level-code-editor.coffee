{CompositeDisposable,Emitter} = require('atom')

languageManager               = require('./language-manager').getInstance()

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
    if (language = languageManager.getLanguageForName(data.languageName))?
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
    @removeExecutionIssues()
    @terminalSubscrs.dispose()
    @bufferSubscr.dispose()
    @terminal.release()
    @emitter.emit('did-destroy')

    # TODO stop execution here and display a proper info notification as soon as
    # execution can be stopped programmatically (see execution-manager.coffee)
    if @isExecuting()
      message =
        'You just destroyed a level code editor while it was executing. However,
        the execution process is still running and now can only be killed
        manually.\n \nThis will be fixed in a future release.'
      notificationUtils.addWarning message,
        head: 'Attention! Execution is still running!'
        important: true
    # --------------------------------------------------------------------------

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
    configKey = 'levels.whenToWriteFileHeader'
    whenToWriteFileHeader = atom.config.get(configKey)
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
