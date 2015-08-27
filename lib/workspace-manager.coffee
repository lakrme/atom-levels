{CompositeDisposable} = require('atom')

executionManager      = require('./execution-manager').getInstance()
languageInstaller     = require('./language-installer').getInstance()
languageRegistry      = require('./language-registry').getInstance()
workspace             = require('./workspace').getInstance()

notificationUtils     = require('./notification-utils')
workspaceUtils        = require('./workspace-utils')

LevelCodeEditor       = require('./level-code-editor')
LevelStatusView       = require('./level-status-view')
LevelSelectView       = require('./level-select-view')
LanguageConfigView    = require('./language-config-view')
TerminalPanelView     = require('./terminal-panel-view')
TerminalView          = require('./terminal-view')
Terminal              = require('./terminal')

# ------------------------------------------------------------------------------

class WorkspaceManager

  ## Set-up and clean-up operations --------------------------------------------

  setUpWorkspace: (@state) ->
    # add view providers
    @viewProviders = new CompositeDisposable
    @viewProviders.add atom.views.addViewProvider Terminal, (terminal) ->
      terminalView = new TerminalView(terminal)
      # initialize the terminal
      terminal.newLine()
      terminal.writeLn('Welcome to the Levels terminal!')
      terminalView

    # create workspace view components
    @levelStatusView = new LevelStatusView
    @levelSelectView = new LevelSelectView
    @terminalPanelView = new TerminalPanelView
    @languageConfigView = new LanguageConfigView

  cleanUpWorkspace: ->
    # remove view providers
    @viewProviders.dispose()

    # destroy workspace view components
    @levelStatusView.destroy()
    @levelSelectView.destroy()
    @terminalPanelView.destroy()
    @languageConfigView.destroy()

    # destroy status bar tiles
    @levelStatusTile.destroy()

  activateEventHandlers: ->
    @subscribeToAtomWorkspace()
    @subscribeToLanguageRegistry()

  deactivateEventHandlers: ->
    @unsubscribeFromAtomWorkspace()
    @unsubscribeFromLanguageRegistry()

  activateCommandHandlers: ->
    @commandHandlers = atom.commands.add 'atom-workspace',
      'levels:install-languages': @doInstallLanguages
      'levels:uninstall-languages': @doUninstallLanguages
      'levels:toggle-level-select': @doToggleLevelSelect
      'levels:toggle-terminal': @doToggleTerminal
      'levels:increase-terminal-font-size': @doIncreaseTerminalFontSize
      'levels:decrease-terminal-font-size': @doDecreaseTerminalFontSize
      'levels:start-execution': @doStartExecution
      'levels:stop-execution': @doStopExecution

  deactivateCommandHandlers: ->
    @commandHandlers.dispose()

  ## Atom workspace subscriptions ----------------------------------------------

  subscribeToAtomWorkspace: ->
    @textEditorSubscrsById = {}
    @atomWorkspaceSubscrs = new CompositeDisposable
    @atomWorkspaceSubscrs.add atom.workspace.observeTextEditors (textEditor) =>
      @handleDidAddTextEditor(textEditor)
    @atomWorkspaceSubscrs.add atom.workspace.observeActivePaneItem (item) =>
      @handleDidChangeActivePaneItem(item)

  unsubscribeFromAtomWorkspace: ->
    # dispose Atom workspace event handlers
    @atomWorkspaceSubscrs.dispose()

    # dispose text editor event handlers
    for textEditor in atom.workspace.getTextEditors()
      @unsubscribeFromTextEditor(textEditor)

  handleDidChangeActivePaneItem: (item) ->
    textEditor = atom.workspace.getActiveTextEditor()
    if textEditor? and workspace.isLevelCodeEditor(textEditor)
      levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor)
      workspace.setActiveLevelCodeEditor(levelCodeEditor)
    else
      workspace.unsetActiveLevelCodeEditor()

  handleDidAddTextEditor: (textEditor) ->
    levelCodeEditorState = @state?.levelCodeEditorStatesById[textEditor.id]
    if levelCodeEditorState?
      levelCodeEditor = atom.deserializers.deserialize(levelCodeEditorState,\
        textEditor)

    unless levelCodeEditor?
      result = workspaceUtils.readLanguageInformationFromFileHeader(textEditor)
      if (language = result?.language)?
        level = result.level
        levelCodeEditor = new LevelCodeEditor({textEditor,language,level})

    unless levelCodeEditor?
      levelCodeEditorState = @state?.levelCodeEditorStatesById[textEditor.id]
      if levelCodeEditorState?
        levelCodeEditor = atom.deserializers.deserialize(levelCodeEditorState,\
          textEditor)

    unless levelCodeEditor?
      language = workspaceUtils.readLanguageFromFileExtension(textEditor)
      levelCodeEditor = new LevelCodeEditor({textEditor,language}) if language?

    unless levelCodeEditor?
      language = languageRegistry.getLanguageForGrammar(textEditor.getGrammar())
      levelCodeEditor = new LevelCodeEditor({textEditor,language}) if language?

    workspace.addLevelCodeEditor(levelCodeEditor) if levelCodeEditor?
    @subscribeToTextEditor(textEditor)

  ## Text editor subscriptions -------------------------------------------------

  subscribeToTextEditor: (textEditor) ->
    currentGrammarName = textEditor.getGrammar().name
    @textEditorSubscrsById[textEditor.id] =
      didDestroySubscr: textEditor.onDidDestroy =>
        @handleDidDestroy(textEditor)
      didChangeGrammarSubscr: textEditor.onDidChangeGrammar (grammar) =>
        @handleDidChangeGrammar(textEditor,currentGrammarName,grammar)

  unsubscribeFromTextEditor: (textEditor) ->
    textEditorSubscr = @textEditorSubscrsById[textEditor.id]
    textEditorSubscr?.didDestroySubscr.dispose()
    textEditorSubscr?.didChangeGrammarSubscr.dispose()
    delete @textEditorSubscrsById[textEditor.id]

  handleDidDestroy: (textEditor) ->
    if workspace.isLevelCodeEditor(textEditor)
      levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor)
      workspace.destroyLevelCodeEditor(levelCodeEditor)
    @unsubscribeFromTextEditor(textEditor)

  handleDidChangeGrammar: (textEditor,oldGrammarName,newGrammar) ->
    unless newGrammar.name is oldGrammarName

      @textEditorSubscrsById[textEditor.id].didChangeGrammarSubscr.dispose()
      @textEditorSubscrsById[textEditor.id].didChangeGrammarSubscr = \
        textEditor.onDidChangeGrammar (grammar) =>
          @handleDidChangeGrammar(textEditor,newGrammar.name,grammar)

      language = languageRegistry.getLanguageForGrammar(newGrammar)
      if workspace.isLevelCodeEditor(textEditor)
        levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor)
        # TODO prevent grammar change when level code editor is executing
        # if levelCodeEditor.isExecuting()
        #   ...
        if language?
          levelCodeEditor.setLanguage(language)
        else
          workspace.destroyLevelCodeEditor(levelCodeEditor)
          if textEditor is atom.workspace.getActiveTextEditor()
            workspace.unsetActiveLevelCodeEditor()
      else
        if language?
          levelCodeEditor = new LevelCodeEditor
            textEditor: textEditor
            language: language
          workspace.addLevelCodeEditor(levelCodeEditor)
          if textEditor is atom.workspace.getActiveTextEditor()
            workspace.setActiveLevelCodeEditor(levelCodeEditor)

  ## Language registry subscriptions -------------------------------------------

  subscribeToLanguageRegistry: ->
    @languageRegistrySubscrs = new CompositeDisposable
    @languageRegistrySubscrs.add languageRegistry.onDidRemoveLanguages \
      (removedLanguages) => @handleDidRemoveLanguages(removedLanguages)

  unsubscribeFromLanguageRegistry: ->
    @languageRegistrySubscrs.dispose()

  handleDidRemoveLanguages: (removedLanguages) ->

  ## Command handlers ----------------------------------------------------------

  doInstallLanguages: (event) =>
    atom.pickFolder (paths) ->
      languageInstaller.installLanguages(paths) if paths?

  doUninstallLanguages: (event) =>
    languageInstaller.uninstallLanguages([])

  doToggleLevelSelect: (event) =>
    if workspace.isActive()
      @levelSelectView.toggle()
    else
      event.abortKeyBinding()

  doToggleTerminal: (event) =>
    if (activeLevelCodeEditor = workspace.getActiveLevelCodeEditor())?
      activeLevelCodeEditor.getTerminal().toggle()
    else
      event.abortKeyBinding()

  doIncreaseTerminalFontSize: (event) =>
    if (activeTerminal = workspace.getActiveTerminal())?
      activeTerminal.increaseFontSize()
    else
      event.abortKeyBinding()

  doDecreaseTerminalFontSize: (event) =>
    if (activeTerminal = workspace.getActiveTerminal())?
      activeTerminal.decreaseFontSize()
    else
      event.abortKeyBinding()

  doStartExecution: (event) =>
    if (activeLevelCodeEditor = workspace.getActiveLevelCodeEditor())?
      if activeLevelCodeEditor.getTextEditor().getPath()?
        activeLevelCodeEditor.startExecution()
      else
        console.log atom.showSaveDialogSync()
        # notificationUtils.addError notificationUtils.executionNotPossible,
        #   important: true
    else
      event.abortKeyBinding()

  doStopExecution: (event) =>
    if (activeLevelCodeEditor = workspace.getActiveLevelCodeEditor())?
      activeLevelCodeEditor.stopExecution()
    else
      event.abortKeyBinding()

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    @levelStatusTile = statusBar.addRightTile
      item: @levelStatusView
      priority: 9

  ## Serialization -------------------------------------------------------------

  serializeWorkspace: ->
    levelCodeEditorStatesById = {}
    for levelCodeEditor in workspace.getLevelCodeEditors()
      levelCodeEditorStatesById[levelCodeEditor.getId()] =
        levelCodeEditor.serialize()
    {levelCodeEditorStatesById}

# ------------------------------------------------------------------------------

module.exports =
class WorkspaceManagerProvider

  instance = null

  @getInstance: ->
    instance ?= new WorkspaceManager

# ------------------------------------------------------------------------------
