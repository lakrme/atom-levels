workspace = require './utils-workspace'

# ------------------------------------------------------------------------------

module.exports =
class SessionManager

  instance = null

  @getInstance: ->
    instance ?= new SessionManager

  initialize: (serializedState) ->
    @textEditorData = {}
    for textEditor in atom.workspace.getTextEditors()
      languageData = workspace.readLanguageDataFromFileHeader(textEditor)
      if languageData?
        @bindTextEditor(textEditor,{languageData})
        textEditor.setGrammar(languageData.level.grammar)

  ## Data associated with text editors -----------------------------------------

  bindTextEditor: (textEditor,data) ->
    @textEditorData[textEditor.id] = data

  unbindTextEditor: (textEditor) ->
    delete @textEditorData[textEditor.id]

  languageDataForTextEditor: (textEditor) ->
    @textEditorData[textEditor.id]?.languageData

  ## Serialization and deserialization -----------------------------------------

  serialize: ->

# ------------------------------------------------------------------------------
