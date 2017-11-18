{CompositeDisposable} = require('atom')
path                  = require('path')

languageRegistry      = require('./language-registry').getInstance()
workspace             = require './workspace'

workspaceUtils        = require('./workspace-utils')

LevelCodeEditor       = require('./level-code-editor')
LevelStatusView       = require('./level-status-view')
LevelSelectView       = require('./level-select-view')
TerminalPanelView     = require('./terminal-panel-view')
TerminalView          = require('./terminal-view')
Terminal              = require('./terminal')

# ------------------------------------------------------------------------------

class WorkspaceManager

  ## Set-up and clean-up operations --------------------------------------------

  # Initializes the Levels workspace view components (invoked on activation).
  setUpWorkspace: (@state) ->
    @viewProviders = new CompositeDisposable
    @viewProviders.add atom.views.addViewProvider Terminal, (terminal) ->
      terminalView = new TerminalView(terminal)

      # initialize the terminal
      terminal.newLine()
      terminal.writeInfo('Welcome to the Levels terminal!')
      terminalView.element

    @levelSelectView = new LevelSelectView
    @terminalPanelView = new TerminalPanelView

  # Destroys the Levels workspace (view) components (invoked on deactivation).
  cleanUpWorkspace: ->
    @viewProviders.dispose()
    @levelStatusView?.destroy()
    @levelStatusTile?.destroy()
    @levelSelectView.destroy()
    @terminalPanelView.destroy()

    # destroy Levels workspace
    for language in languageRegistry.getLanguages()
      languageRegistry.removeLanguage(language)
    # for levelCodeEditor in workspace.getLevelCodeEditors()
    #   workspace.destroyLevelCodeEditor(levelCodeEditor)
    # workspace.unsetActiveLevelCodeEditor()

  activateEventHandlers: ->
    @subscribeToAtomWorkspace()
    @subscribeToLanguageRegistry()

  deactivateEventHandlers: ->
    @unsubscribeFromAtomWorkspace()
    @unsubscribeFromLanguageRegistry()

  activateCommandHandlers: ->
    @commandHandlers = atom.commands.add 'atom-workspace',
      'levels:toggle-level-select': @doToggleLevelSelect
      'levels:toggle-terminal': @doToggleTerminal
      'levels:increase-terminal-font-size': @doIncreaseTerminalFontSize
      'levels:decrease-terminal-font-size': @doDecreaseTerminalFontSize
      'levels:toggle-terminal-focus': @doToggleTerminalFocus
      'levels:clear-terminal': @doClearTerminal
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
    @atomWorkspaceSubscrs.add atom.workspace.onDidAddTextEditor \
      ({textEditor}) => @handleDidAddTextEditor(textEditor)
    @atomWorkspaceSubscrs.add atom.workspace.onDidChangeActivePaneItem \
      (item) => @handleDidChangeActivePaneItem(item)

    # subscribe to open text editors on startup
    for textEditor in atom.workspace.getTextEditors()
      @subscribeToTextEditor(textEditor)

  unsubscribeFromAtomWorkspace: ->
    @atomWorkspaceSubscrs.dispose()

    # unsubscribe from all text editors
    for textEditor in atom.workspace.getTextEditors()
      @unsubscribeFromTextEditor(textEditor)

  # The handler to be invoked when the active pane item changes in the Atom
  # workspace. Activates (deactivates) the Levels workspace when the active text
  # editor is (not) a level code editor.
  handleDidChangeActivePaneItem: (item) ->
    textEditor = atom.workspace.getActiveTextEditor()
    if textEditor? and workspace.isLevelCodeEditor(textEditor)
      levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor)
      workspace.setActiveLevelCodeEditor(levelCodeEditor)
    else
      workspace.unsetActiveLevelCodeEditor()

  # The handler to be invoked when a text editor was added to the Atom
  # workspace. Creates a level code editor if language information can be
  # derived from the added text editor and updates the Levels workspace.
  handleDidAddTextEditor: (textEditor) ->
    unless levelCodeEditor?
      result = workspaceUtils.readLanguageInformationFromFileHeader(textEditor)
      if (language = result?.language)?
        level = result.level
        levelCodeEditor = new LevelCodeEditor({textEditor,language,level})

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
    @textEditorSubscrsById[textEditor.id] =
      didChangeGrammarSubscr: textEditor.onDidChangeGrammar (grammar) =>
        @handleDidChangeGrammarOfTextEditor(textEditor,grammar)
      didDestroySubscr: textEditor.onDidDestroy =>
        @handleDidDestroyTextEditor(textEditor)

  unsubscribeFromTextEditor: (textEditor) ->
    textEditorSubscr = @textEditorSubscrsById[textEditor.id]
    textEditorSubscr?.didChangeGrammarSubscr.dispose()
    textEditorSubscr?.didDestroySubscr.dispose()
    delete @textEditorSubscrsById[textEditor.id]

  # The handler to be invoked when the grammar of a text editor was changed in
  # the Atom workspace. Determines if a level code editor must be created or
  # destroyed for the given text editor based on the grammar change and updates
  # the Levels workspace if necessary.
  handleDidChangeGrammarOfTextEditor: (textEditor,grammar) ->
    @textEditorSubscrsById[textEditor.id].didChangeGrammarSubscr.dispose()
    language = languageRegistry.getLanguageForGrammar(grammar)

    if workspace.isLevelCodeEditor(textEditor)
      levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor)
      currentLanguage = levelCodeEditor.getLanguage()
      switch
        # if the text editor is part of the Levels workspace and the new grammar
        # grammar is the dummy grammar of the current language, the grammar
        # change was either caused by a level change (then nothing happens) or
        # by Atom after saving the buffer to a path with a file extension that
        # is associated with the current language (in the latter case Atom
        # chooses the dummy grammar from the grammar registry, which is why we
        # have to restore the level grammar here)
        when language? and language is currentLanguage
          if grammar is language.getDummyGrammar()
            levelCodeEditor.restore()
        # if the text editor is part of the Levels workspace and the new grammar
        # is another Levels (dummy) grammar, we just update the level code
        # editor's language
        when language? and language isnt currentLanguage
          levelCodeEditor.setLanguage(language)
        # if the text editor is part of the Levels workspace and the new grammar
        # is not a Levels (dummy) grammar, we destroy the level code editor and
        # exit the Levels workspace if necessary
        when not language?
          workspace.destroyLevelCodeEditor(levelCodeEditor)
          if textEditor is atom.workspace.getActiveTextEditor()
            workspace.unsetActiveLevelCodeEditor()
    else
      # if the text editor isn't part of the Levels workspace yet, only create
      # a level code editor if the new grammar is the language's dummy grammar
      # (which is the case when the user changes the grammar manually, for
      # instance), otherwise the grammar change happened while creating a new
      # level code editor for this text editor (do nothing in this case)
      if language? and grammar is language.getDummyGrammar()
        levelCodeEditor = new LevelCodeEditor({textEditor,language})
        workspace.addLevelCodeEditor(levelCodeEditor)
        if textEditor is atom.workspace.getActiveTextEditor()
          workspace.setActiveLevelCodeEditor(levelCodeEditor)

    @textEditorSubscrsById[textEditor.id].didChangeGrammarSubscr = \
      textEditor.onDidChangeGrammar (grammar) =>
        @handleDidChangeGrammarOfTextEditor(textEditor,grammar)

  # The handler to be invoked when a text editor was destroyed in the Atom
  # workspace. Also destroys the corresponding level code editor if that text
  # editor was part of the Levels workspace.
  handleDidDestroyTextEditor: (textEditor) ->
    if workspace.isLevelCodeEditor(textEditor)
      levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor)
      workspace.destroyLevelCodeEditor(levelCodeEditor)
    @unsubscribeFromTextEditor(textEditor)

  ## Language registry subscriptions -------------------------------------------

  subscribeToLanguageRegistry: ->
    @languageRegistrySubscrs = new CompositeDisposable
    @languageRegistrySubscrs.add languageRegistry.observeLanguages \
      (addedLanguage) =>
        @handleDidAddLanguageToLanguageRegistry(addedLanguage)
    @languageRegistrySubscrs.add languageRegistry.onDidRemoveLanguage \
      (removedLanguage) =>
        @handleDidRemoveLanguageFromLanguageRegistry(removedLanguage)

  unsubscribeFromLanguageRegistry: ->
    @languageRegistrySubscrs.dispose()

  # The handler to be invoked when a language was added to the language
  # registry, for example, when a language package is being activated.
  # Identifies text editors that can be associated with the added language and
  # adds them to the Levels workspace.
  handleDidAddLanguageToLanguageRegistry: (addedLanguage) ->
    for textEditor in atom.workspace.getTextEditors()
      unless workspace.isLevelCodeEditor(textEditor)
        levelCodeEditor = null

        # check if text editor was serialized with the added language
        levelCodeEditorState = @state?.levelCodeEditorStatesById?[textEditor.id]
        if levelCodeEditorState?
          # try to deserialize level code editor with updated language registry
          # (returns `undefined` if the associated language of this text editor
          # has not been added yet)
          levelCodeEditor = atom.deserializers.deserialize(levelCodeEditorState)
          # if successful, remove text editor serialization from state (prevents
          # the re-deserialization of the level code editor when adding another
          # language)
          if levelCodeEditor?
            delete @state.levelCodeEditorStatesById[textEditor.id]

        # check if text editor is associated with the language
        # TODO replace with a more efficient approach
        unless levelCodeEditor?
          res = workspaceUtils.readLanguageInformationFromFileHeader(textEditor)
          if (language = res?.language)? and language is addedLanguage
            level = res.level
            levelCodeEditor = new LevelCodeEditor({textEditor,language,level})

        unless levelCodeEditor?
          language = workspaceUtils.readLanguageFromFileExtension(textEditor)
          if language? and language is addedLanguage
            levelCodeEditor = new LevelCodeEditor({textEditor,language})

        unless levelCodeEditor?
          grammar = textEditor.getGrammar()
          language = languageRegistry.getLanguageForGrammar(grammar)
          if language? and language is addedLanguage
            levelCodeEditor = new LevelCodeEditor({textEditor,language})
        # -------------------------------------------

        # add level code editor to workspace if successful
        if levelCodeEditor?
          workspace.addLevelCodeEditor(levelCodeEditor)
          if textEditor is atom.workspace.getActiveTextEditor()
            workspace.setActiveLevelCodeEditor(levelCodeEditor)

  # The handler to be invoked when a language was removed from the language
  # registry, for example, when a language package is being deactivated. Updates
  # the Levels workspace and destroys all level code editors that are bound to
  # the removed language.
  handleDidRemoveLanguageFromLanguageRegistry: (removedLanguage) ->
    for levelCodeEditor in workspace.getLevelCodeEditors()
      if levelCodeEditor.getLanguage() is removedLanguage

        # update Levels workspace
        workspace.destroyLevelCodeEditor(levelCodeEditor)
        textEditor = levelCodeEditor.getTextEditor()
        if textEditor is atom.workspace.getActiveTextEditor()
          workspace.unsetActiveLevelCodeEditor()

        # set the text editor's grammar to the default grammar
        # nullGrammar = atom.grammars.grammarForScopeName('text.plain')
        # textEditor.setGrammar(nullGrammar)

  ## Command handlers ----------------------------------------------------------

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

  doClearTerminal: (event) ->
    if workspace.isActive()
      activeLevelCodeEditor = workspace.getActiveLevelCodeEditor()
      activeTerminal = activeLevelCodeEditor.getTerminal()
      activeTerminal.clear()
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
      activeLevelCodeEditor = workspace.getActiveLevelCodeEditor()
      activeTextEditor = activeLevelCodeEditor.getTextEditor()
      activeTerminal = activeLevelCodeEditor.getTerminal()
      if (filePath = activeTextEditor.getPath() ? atom.showSaveDialogSync())?
        activeTextEditor.saveAs(filePath).then () =>
          activeLevelCodeEditor.startExecution()
          activeTerminal.show()
          activeTerminal.focus()
    else
      event.abortKeyBinding()

  doStopExecution: (event) ->
    if workspace.isActive()
      workspace.getActiveLevelCodeEditor().stopExecution()
    else
      event.abortKeyBinding()

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    @levelStatusView = new LevelStatusView
    @levelStatusTile = statusBar.addRightTile {priority: 9, item: @levelStatusView.element}

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
