{Emitter} = require('atom')

# ------------------------------------------------------------------------------

class Workspace

  ## Construction and initialization -------------------------------------------

  constructor: ->
    @emitter = new Emitter
    @levelCodeEditorsById = {}
    @activeLevelCodeEditor = null

  ## Event subscription --------------------------------------------------------

  onDidEnterWorkspace: (callback) ->
    @emitter.on('did-enter-workspace',callback)

  onDidExitWorkspace: (callback) ->
    @emitter.on('did-exit-workspace',callback)

  onDidAddLevelCodeEditor: (callback) ->
    @emitter.on('did-add-level-code-editor',callback)

  onDidDestroyLevelCodeEditor: (callback) ->
    @emitter.on('did-destroy-level-code-editor',callback)

  onDidChangeActiveLevelCodeEditor: (callback) ->
    @emitter.on('did-change-active-level-code-editor',callback)

  ## Workspace properties ------------------------------------------------------

  isActive: ->
    @activeLevelCodeEditor?

  ## Managing level code editors -----------------------------------------------

  getActiveLevelCodeEditor: ->
    @activeLevelCodeEditor

  setActiveLevelCodeEditor: (levelCodeEditor) ->

  addLevelCodeEditor: (levelCodeEditor) ->
    @levelCodeEditorsById[levelCodeEditor.getId()] = levelCodeEditor
    @emitter.emit('did-add-level-code-editor',levelCodeEditor)
    console.log @levelCodeEditorsById

  destroyLevelCodeEditor: (levelCodeEditor) ->
    delete @levelCodeEditorsById[levelCodeEditor.getId()]
    levelCodeEditor.destroy()
    @emitter.emit('did-destroy-level-code-editor')
    console.log @levelCodeEditorsById

  getLevelCodeEditorForTextEditor: (textEditor) ->
    @levelCodeEditorsById[textEditor.id]

  getLevelCodeEditors: ->
    levelCodeEditor for _,levelCodeEditor of @levelCodeEditorsById

  isLevelCodeEditor: (textEditor) ->
    @getLevelCodeEditorForTextEditor(textEditor)?

  ## Serialization -------------------------------------------------------------

  serialize: ->

# ------------------------------------------------------------------------------

module.exports =
class WorkspaceProvider

  instance = null

  @getInstance: ->
    instance ?= new Workspace

# ------------------------------------------------------------------------------
