configRegistry   = require('./core-config-registry').getInstance()
languageRegistry = require('./core-language-registry').getInstance()
terminalManager  = require('./core-terminal-manager').getInstance()
viewManager      = require('./core-view-manager').getInstance()
workspace        = require('./utils-workspace')

# ------------------------------------------------------------------------------

module.exports =
class StateManager

  instance = null

  @getInstance: ->
    instance ?= new StateManager

  initialize: (serializedState) ->
    @initializeTextEditorBindings(serializedState)

  ## Text editor states --------------------------------------------------------

  initializeTextEditorStates: (serializedState) ->
    @textEditorStates = {}

    if serializedState?
      for textEditorId,state of serializedState.textEditorStates
        if (textEditor = getTextEditorForId(textEditorId))?
          language     = state.language
          level        = state.level
          controlPanel = viewManager.getNewControlPanel(state.controlPanelState)
          terminal     = terminalManager.getNewTerminal()
          @bindTextEditor(textEditor,{language,level,controlPanel,terminal})
    else
      for textEditor in atom.workspace.getTextEditors()
        if (languageData = workspace.readLanguageDataFromFileHeader(textEditor))?
          @bindTextEditor(textEditor,languageData)

  bindTextEditor: (textEditor,stateData) ->
    language = stateData.language
    level    = stateData.level
    if (state = @textEditorStates[textEditor.id])?
      state.language = stateData.language
      state.level    = stateData.level
    else
      @textEditorStates[textEditor.id] = stateData


  unbindTextEditor: (textEditor) ->
    delete @textEditorStates[textEditor.id]

  languageDataForTextEditor: (textEditor) ->
    @textEditorData[textEditor.id]?.languageData

  ## Serialization -------------------------------------------------------------

  serialize: ->
    serializedState = {}

    # serialize text editor states
    serializedState.textEditorStates = {}
    for textEditorId,textEditorState of @textEditorStates
      serializedState.textEditorStates.textEditorId =
        language:          textEditorState.language
        level:             textEditorState.level
        controlPanelState: textEditorState.controlPanel.serialize()

    serializedState

# ------------------------------------------------------------------------------
