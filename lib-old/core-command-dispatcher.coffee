{CompositeDisposable} = require 'atom'

executionManager = require('./core-execution-manager').getInstance()
languageRegistry = require('./core-language-registry').getInstance()
sessionManager   = require('./core-session-manager').getInstance()
viewManager      = require('./core-view-manager').getInstance()

# ------------------------------------------------------------------------------

module.exports =
class CommandDispatcher

  instance = null

  @getInstance: ->
    instance ?= new CommandDispatcher

  initialize: ->
    @handlers = new CompositeDisposable

    # initialize command handlers
    @handlers.add atom.commands.add 'atom-workspace', 'levels:toggle-level-select', =>
      if (textEditor = atom.workspace.getActiveTextEditor())?
        if (languageData = sessionManager.languageDataForTextEditor(textEditor))?
          viewManager.levelSelectView.toggle(languageData)

    @handlers.add atom.commands.add 'atom-workspace', 'levels:toggle-terminal', =>
      if (textEditor = atom.workspace.getActiveTextEditor())?
        if (sessionManager.languageDataForTextEditor(textEditor))?
          viewManager.controlPanelView.toggleTerminalView()

    @handlers.add atom.commands.add 'atom-workspace', 'levels:start-execution', =>
      if (textEditor = atom.workspace.getActiveTextEditor())?
        if (languageData = sessionManager.languageDataForTextEditor(textEditor))?
          controlPanelView = viewManager.controlPanelView
          controlPanelView.showTerminalView()
          controlPanelView.showStopExecutionControls()
          viewManager.removeIssueAnnotationsForTextEditor(textEditor)
          executionManager.startExecution(textEditor,languageData)
          executionManager.onDidStopExecution ->
            controlPanelView.showStartExecutionControls()

    @handlers.add atom.commands.add 'atom-workspace', 'levels:stop-execution', =>
      if (textEditor = atom.workspace.getActiveTextEditor())?
        if (languageData = sessionManager.languageDataForTextEditor(textEditor))?
          controlPanelView = viewManager.controlPanelView
          controlPanelView.showTerminalView()
          executionManager.stopExecution(textEditor,languageData,controlPanelView)

    @handlers.add atom.commands.add 'atom-workspace', 'levels:install-languages', =>
      atom.pickFolder (paths) =>
        languageRegistry.installLanguages(paths) if paths?

    @handlers.add atom.commands.add 'atom-workspace', 'levels:uninstall-languages', =>
      languageRegistry.uninstallLanguages([])

  disposeAllCommandHandlers: ->
    @handlers.dispose()

  ## Serialization -------------------------------------------------------------

  serialize: ->

# ------------------------------------------------------------------------------
