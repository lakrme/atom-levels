{CompositeDisposable} = require('atom')

languageInstaller     = require('./language-installer').getInstance()
languageRegistry      = require('./language-registry').getInstance()
workspace             = require('./workspace').getInstance()

# languageUtils         = require('./language-utils')

LevelCodeEditor       = require('./level-code-editor')
LevelStatusView       = require('./level-status-view')
LevelSelectView       = require('./level-select-view')
LanguageConfigView    = require('./language-config-view')
TerminalView          = require('./terminal-view')
Terminal              = require('./terminal')

# ------------------------------------------------------------------------------

class WorkspaceManager

  ## Set-up and clean-up operations --------------------------------------------

  setUpWorkspace: (state) ->
    # restore/initialitze the Levels workspace
    for textEditor in atom.workspace.getTextEditors()
    #   if (result = languageUtils.)?
    #     levelCodeEditor = new LevelCodeEditor
    #       textEditor: textEditor
    #       language: result.language
    #       level: result.level
    #     continue

      if (data = state?.serializedLevelCodeEditorsById[textEditor.id])?
        if (language = languageRegistry.getLanguageForName(data.language))?
          level = language.getLevelForName(data.level)
          terminal = new Terminal(data.serializedTerminal)
          levelCodeEditor = new LevelCodeEditor
            textEditor: textEditor
            language: language
            level: level
            terminal: terminal
          workspace.addLevelCodeEditor(levelCodeEditor)

    # add view providers
    @viewProviders = new CompositeDisposable
    @viewProviders.add atom.views.addViewProvider Terminal, (terminal) ->
      new TerminalView(terminal)

    # create workspace view components
    @levelStatusView = new LevelStatusView
    @levelSelectView = new LevelSelectView
    @languageConfigView = new LanguageConfigView

    # initialize active level code editor
    if (textEditor = atom.workspace.getActiveTextEditor())
      if workspace.isLevelCodeEditor(textEditor)
        levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor)
        workspace.setActiveLevelCodeEditor(levelCodeEditor)

  cleanUpWorkspace: ->
    # remove view providers
    @viewProviders.dispose()

    # destroy workspace view components
    @levelStatusView.destroy()
    @levelSelectView.destroy()
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
      'levels:install-languages': (event) => @doInstallLanguages(event)
      'levels:uninstall-languages': (event) => @doUninstallLanguages(event)
      'levels:toggle-level-select': (event) => @doToggleLevelSelect(event)
      'levels:toggle-terminal': (event) => @doToggleTerminal(event)
      'levels:start-execution': (event) => @doStartExecution(event)
      'levels:stop-execution': (event) => @doStopExecution(event)

  deactivateCommandHandlers: ->
    @commandHandlers.dispose()

  ## Atom workspace subscriptions ----------------------------------------------

  subscribeToAtomWorkspace: ->
    # general Atom workspace subscriptions
    @atomWorkspaceSubscrs = new CompositeDisposable
    @atomWorkspaceSubscrs.add atom.workspace.onDidChangeActivePaneItem (item) =>
      @handleDidChangeActivePaneItem(item)
    @atomWorkspaceSubscrs.add atom.workspace.onDidAddTextEditor (event) =>
      @handleDidAddTextEditor(event)

    # text editor subscriptions
    @textEditorSubscrsById = {}
    for textEditor in atom.workspace.getTextEditors()
      @subscribeToTextEditor(textEditor)

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

  handleDidAddTextEditor: ({textEditor}) ->
    @subscribeToTextEditor(textEditor)
    # ...

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

  doInstallLanguages: (event) ->
    atom.pickFolder (paths) ->
      languageInstaller.installLanguages(paths) if paths?

  doUninstallLanguages: (event) ->
    languageInstaller.uninstallLanguages([])

  doToggleLevelSelect: (event) ->
    if workspace.isActive()
      @levelSelectView.toggle()
    else
      event.abortKeyBinding()

  doToggleTerminal: (event) ->
    event.abortKeyBinding()

  doStartExecution: (event) ->
    event.abortKeyBinding()

  doStopExecution: (event) ->
    event.abortKeyBinding()

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    @levelStatusTile = statusBar.addRightTile
      item: @levelStatusView
      priority: 9

  ## Serialization -------------------------------------------------------------

  serializeWorkspace: ->
    serializedLevelCodeEditorsById = {}
    for levelCodeEditor in workspace.getLevelCodeEditors()
      serializedLevelCodeEditorsById[levelCodeEditor.getId()] =
        language: levelCodeEditor.getLanguage().getName()
        level: levelCodeEditor.getLevel().getName()
        serializedTerminal: undefined
    {serializedLevelCodeEditorsById}

# ------------------------------------------------------------------------------

module.exports =
class WorkspaceManagerProvider

  instance = null

  @getInstance: ->
    instance ?= new WorkspaceManager

# ------------------------------------------------------------------------------
