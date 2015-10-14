{CompositeDisposable} = require('atom')
path                  = require('path')

languageManager       = require('./language-manager').getInstance()
workspace             = require('./workspace').getInstance()

notificationUtils     = require('./notification-utils')
workspaceUtils        = require('./workspace-utils')

LanguageManagerView   = require('./language-manager-view')
LevelCodeEditor       = require('./level-code-editor')
LevelStatusView       = require('./level-status-view')
LevelSelectView       = require('./level-select-view')
TerminalPanelView     = require('./terminal-panel-view')
TerminalView          = require('./terminal-view')
Terminal              = require('./terminal')

# ------------------------------------------------------------------------------

class WorkspaceManager

  ## Set-up and clean-up operations --------------------------------------------

  setUpWorkspace: (@state) ->
    # add view providers
    @viewProviders = new CompositeDisposable
    @viewProviders.add atom.views.addViewProvider Terminal, \
      (terminal) ->
        terminalView = new TerminalView(terminal)
        # initialize the terminal
        terminal.newLine()
        terminal.writeInfo('Welcome to the Levels terminal!')
        terminalView

    # create workspace view components
    @languageManagerView = new LanguageManagerView
    @levelStatusView = new LevelStatusView
    @levelSelectView = new LevelSelectView
    @terminalPanelView = new TerminalPanelView

  cleanUpWorkspace: ->
    # remove view providers
    @viewProviders.dispose()

    # destroy workspace view components
    @levelStatusView.destroy()
    @levelSelectView.destroy()
    @terminalPanelView.destroy()

    # destroy status bar tiles
    @levelStatusTile.destroy()

  activateEventHandlers: ->
    @subscribeToAtomWorkspace()
    @subscribeToLanguageManager()

  deactivateEventHandlers: ->
    @unsubscribeFromAtomWorkspace()
    @unsubscribeFromLanguageManager()

  activateCommandHandlers: ->
    @commandHandlers = atom.commands.add 'atom-workspace',
      'levels:toggle-language-manager': @doToggleLanguageManager
      'levels:toggle-level-select': @doToggleLevelSelect
      'levels:toggle-terminal': @doToggleTerminal
      'levels:increase-terminal-font-size': @doIncreaseTerminalFontSize
      'levels:decrease-terminal-font-size': @doDecreaseTerminalFontSize
      'levels:toggle-terminal-focus': @doToggleTerminalFocus
      'levels:scroll-terminal-to-top': @doScrollTerminalToTop
      'levels:scroll-terminal-to-bottom': @doScrollTerminalToBottom
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
    levelCodeEditorState = @state?.levelCodeEditorStatesById?[textEditor.id]
    if levelCodeEditorState?
      levelCodeEditor = atom.deserializers.deserialize(levelCodeEditorState,\
        textEditor)

    unless levelCodeEditor?
      result = workspaceUtils.readLanguageInformationFromFileHeader(textEditor)
      if (language = result?.language)?
        level = result.level
        levelCodeEditor = new LevelCodeEditor({textEditor,language,level})

    unless levelCodeEditor?
      language = workspaceUtils.readLanguageFromFileExtension(textEditor)
      levelCodeEditor = new LevelCodeEditor({textEditor,language}) if language?

    unless levelCodeEditor?
      language = languageManager.getLanguageForGrammar(textEditor.getGrammar())
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
    # this condition prevents the handler from being executed for grammar
    # changes caused by level code editor initalizations or level changes
    unless newGrammar.name is oldGrammarName
      @textEditorSubscrsById[textEditor.id].didChangeGrammarSubscr.dispose()
      @textEditorSubscrsById[textEditor.id].didChangeGrammarSubscr = \
        textEditor.onDidChangeGrammar (grammar) =>
          @handleDidChangeGrammar(textEditor,newGrammar.name,grammar)

      language = languageManager.getLanguageForGrammar(newGrammar)
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
    else
      if path.dirname(newGrammar.path).endsWith('levels/grammars')
        workspace.getLevelCodeEditorForId(textEditor.id).restore()

  ## Language manager subscriptions --------------------------------------------

  subscribeToLanguageManager: ->
    @languageManagerSubscrs = new CompositeDisposable
    @languageManagerSubscrs.add languageManager.onDidRemoveLanguages \
      (removedLanguages) => @handleDidRemoveLanguages(removedLanguages)

  unsubscribeFromLanguageManager: ->
    @languageManagerSubscrs.dispose()

  handleDidRemoveLanguages: (removedLanguages) ->

  ## Command handlers ----------------------------------------------------------

  doToggleLanguageManager: (event) =>
    @languageManagerView.toggle()

  doToggleLevelSelect: (event) =>
    if workspace.isActive()
      @levelSelectView.toggle()
    else
      event.abortKeyBinding()

  doToggleTerminal: (event) ->
    if workspace.isActive()
      activeLevelCodeEditor = workspace.getActiveLevelCodeEditor()
      activeTextEditor = activeLevelCodeEditor.getTextEditor()
      activeTerminal = activeLevelCodeEditor.getTerminal()
      if activeTerminal.isVisible()
        activeTerminal.hide()
        atom.views.getView(activeTextEditor).focus()
      else
        activeTerminal.show()
        activeTerminal.focus()
    else
      event.abortKeyBinding()

  doIncreaseTerminalFontSize: (event) ->
    if workspace.isActive()
      workspace.getActiveTerminal().increaseFontSize()
    else
      event.abortKeyBinding()

  doDecreaseTerminalFontSize: (event) ->
    if workspace.isActive()
      workspace.getActiveTerminal().decreaseFontSize()
    else
      event.abortKeyBinding()

  doToggleTerminalFocus: (event) ->
    if workspace.isActive()
      activeLevelCodeEditor = workspace.getActiveLevelCodeEditor()
      activeTextEditor = activeLevelCodeEditor.getTextEditor()
      activeTerminal = activeLevelCodeEditor.getTerminal()
      if activeTerminal.hasFocus()
        atom.views.getView(activeTextEditor).focus()
      else
        activeTerminal.show()
        activeTerminal.focus()
    else
      event.abortKeyBinding()

  doScrollTerminalToTop: (event) ->
    if workspace.isActive()
      workspace.getActiveTerminal().scrollToTop()
    else
      event.abortKeyBinding()

  doScrollTerminalToBottom: (event) ->
    if workspace.isActive()
      workspace.getActiveTerminal().scrollToBottom()
    else
      event.abortKeyBinding()

  doStartExecution: (event) ->
    if workspace.isActive()
      try
        activeLevelCodeEditor = workspace.getActiveLevelCodeEditor()
        activeTerminal = activeLevelCodeEditor.getTerminal()
        activeTerminal.show()
        activeTerminal.focus()
        activeLevelCodeEditor.startExecution()
      catch error
        switch error.name
          when 'ExecutionIsAlreadyRunningError'
            message =
              'Level code execution is already running.\nTry again after program
              termination.'
          when 'TerminalIsBusyError'
            message =
              'The terminal is busy.\nThat is, another level code editor is
              using this terminal at the moment.'
          when 'ExecutionModeNotFoundError'
            message =
              'No execution mode could be found.\nPlease define either the
              interpreter command pattern or the compiler command pattern and
              the execution command pattern in the language configuration view.'
          when 'BufferNotSavedError'
            message =
              'The text editor\'s buffer is not saved yet.\nSave your program in
              order to be able to execute it.'
          else
            message = error.message
        notificationUtils.addError message,
          head: 'Oh no! Execution failed!'
          important: true
    else
      event.abortKeyBinding()

  doStopExecution: (event) ->
    if workspace.isActive()
      workspace.getActiveLevelCodeEditor().stopExecution()
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
