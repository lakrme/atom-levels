executionManager  = require('./core-execution-manager').getInstance()
languageRegistry  = require('./core-language-registry').getInstance()
sessionManager    = require('./core-session-manager').getInstance()
viewManager       = require('./core-view-manager').getInstance()
workspace         = require './utils-workspace'

# ------------------------------------------------------------------------------

module.exports =
class EventDispatcher

  instance = null

  @getInstance: ->
    instance ?= new EventDispatcher

  initialize: ->
    # create the terminal instance (currently one terminal instance is shared
    # between all associated text editor tabs, but it should be possible to use
    # multiple terminal objects in future extensions)
    @terminal = executionManager.getTerminalInstance()

    # initialize workspace subscriptions
    @didAddTextEditorSub = atom.workspace.onDidAddTextEditor (event) =>
      @handleDidAddTextEditor(event)
    @didChangeActivePaneItemSub = atom.workspace.onDidChangeActivePaneItem (item) =>
      @handleDidChangeActivePaneItem(item)

    # initialize grammar and level subscription
    @didChangeGrammarSub = null
    @didChangeLevelSub = null

    # subscribe to all active text buffers
    @textBufferSubBindings = []
    for textEditor in atom.workspace.getTextEditors()
      @subscribeToTextBuffer(textEditor)

    # subscribe to initial pane item (if it is a text editor)
    if (textEditor = atom.workspace.getActiveTextEditor())?
      @subscribeToTextEditor(textEditor)

  disposeAllEventSubscriptions: ->
    @didAddTextEditorSub.dispose()
    @didChangeActivePaneItemSub.dispose()
    # @didDestroyPaneItemSub.dispose()
    @didChangeGrammarSub?.dispose()
    @didChangeLevelSub?.dispose()
    for binding in @textBufferSubBindings
      binding.willSaveSub.dispose()
      binding.didDestroySub.dispose()

  ## Workspace subscriptions and events ----------------------------------------

  handleDidAddTextEditor: ({textEditor}) ->
    @subscribeToTextBuffer(textEditor)

    languageData = workspace.readLanguageDataFromFileHeader(textEditor)
    if languageData?
      sessionManager.bindTextEditor(textEditor,{languageData})
      textEditor.setGrammar(languageData.level.grammar)
      return

    languageData = workspace.readLanguageDataFromFilePath(textEditor)
    if languageData?
      # NOTE maybe write language data here (would modify the buffer...)
      sessionManager.bindTextEditor(textEditor,{languageData})
      textEditor.setGrammar(languageData.level.grammar)
      return

    languageData = workspace.readLanguageDataFromGrammar(textEditor)
    if languageData?
      # TODO maybe write language data here (would modify the buffer...)
      sessionManager.bindTextEditor(textEditor,{languageData})
      textEditor.setGrammar(languageData.level.grammar)
      return

  handleDidChangeActivePaneItem: (item) ->
    if (textEditor = atom.workspace.getActiveTextEditor())?
      @subscribeToTextEditor(textEditor)
    else
      @didChangeGrammarSubscr?.dispose()
      @didChangeLevelSubscr?.dispose()

      viewManager.hideControlPanelView()
      viewManager.hideLevelStatusView()

  subscribeToTextEditor: (textEditor) ->
    if (languageData = sessionManager.languageDataForTextEditor(textEditor))?
      @didChangeLevelSubscr?.dispose()
      @didChangeLevelSubscr = viewManager.levelSelectView.onDidChangeLevel (level) =>
        @handleDidChangeLevel(level)

      viewManager.showControlPanelView(textEditor,languageData,@terminal)
      viewManager.showLevelStatusView(languageData)
    else
      @didChangeLevelSubscr?.dispose()

      viewManager.hideControlPanelView()
      viewManager.hideLevelStatusView()

    @didChangeGrammarSubscr?.dispose()
    @didChangeGrammarSubscr = textEditor.onDidChangeGrammar (grammar) =>
        @handleDidChangeGrammar(grammar)

  ## Grammar and level subscriptions and events --------------------------------

  handleDidChangeGrammar: (grammar) ->
    textEditor = atom.workspace.getActiveTextEditor()
    if (language = languageRegistry.languageForGrammar(grammar))?
      level = language.levelOnInitialization()
      languageData = {language: language,level: level}
      # TODO _update_ binding instead of overwrite it
      sessionManager.bindTextEditor(textEditor,{languageData})

      # change grammar to level grammar
      @didChangeGrammarSubscr?.dispose()
      textEditor.setGrammar(level.grammar)
      @didChangeGrammarSubscr = textEditor.onDidChangeGrammar (grammar) =>
        @handleDidChangeGrammar(grammar)

      viewManager.showControlPanelView(textEditor,languageData,@terminal)
      viewManager.showLevelStatusView(languageData)

      # set level subscription
      @didChangeLevelSubscr?.dispose()
      @didChangeLevelSubscr = viewManager.levelSelectView.onDidChangeLevel (level) =>
        @handleDidChangeLevel(level)
    else
      viewManager.hideControlPanelView()
      viewManager.hideLevelStatusView()

      @didChangeLevelSubscr?.dispose()
      sessionManager.unbindTextEditor(textEditor)

  handleDidChangeLevel: (level) ->
    textEditor = atom.workspace.getActiveTextEditor()
    language = sessionManager.languageDataForTextEditor(textEditor).language
    language.setLastActiveLevel(level)
    languageData = {language: language,level: level}
    # TODO _update_ binding instead of overwrite it
    sessionManager.bindTextEditor(textEditor,{languageData})

    @didChangeGrammarSubscr?.dispose()
    textEditor.setGrammar(level.grammar)
    @didChangeGrammarSubscr = textEditor.onDidChangeGrammar (grammar) =>
      @handleDidChangeGrammar(grammar)

    viewManager.showLevelStatusView(languageData)

  ## Text buffer subscriptions and events --------------------------------------

  subscribeToTextBuffer: (textEditor) ->
    textBuffer = textEditor.getBuffer()
    @textBufferSubBindings.push
      textBuffer: textBuffer
      willSaveSub: textBuffer.onWillSave =>
        @handleWillSaveTextBuffer(textEditor)
      didDestroySub: textBuffer.onDidDestroy =>
        @handleDidDestroyTextBuffer(textBuffer)

  unsubscribeFromTextBuffer: (textBuffer) ->
    indices = []
    for binding,i in @textBufferSubBindings
      if binding.textBuffer is textBuffer
        binding.willSaveSub.dispose()
        binding.didDestroySub.dispose()
        indices.push(i)
    for i,j in indices
      @textBufferSubBindings.splice(i-j,1)

  handleWillSaveTextBuffer: (textEditor) ->
    if (languageData = sessionManager.languageDataForTextEditor(textEditor))?
      workspace.deleteFileHeader(textEditor)
      workspace.writeLanguageDataToFileHeader(textEditor,languageData)

  handleDidDestroyTextBuffer: (textBuffer) ->
    @unsubscribeFromTextBuffer(textBuffer)

# ------------------------------------------------------------------------------
