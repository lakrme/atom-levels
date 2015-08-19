{CompositeDisposable,Emitter} = require('atom')

# ------------------------------------------------------------------------------

class Workspace

  ## Construction --------------------------------------------------------------

  constructor: ->
    @emitter = new Emitter
    @levelCodeEditorsById = {}
    @activeLevelCodeEditor = null
    @activeLevelCodeEditorSubscrs= new CompositeDisposable

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

  oinDidChangeActiveLanguage: (callback) ->
    @emitter.on('did-change-active-language',callback)

  onDidChangeActiveLevel: (callback) ->
    @emitter.on('did-change-active-level',callback)

  ## Workspace properties ------------------------------------------------------

  isActive: ->
    @activeLevelCodeEditor?

  ## Managing level code editors -----------------------------------------------

  addLevelCodeEditor: (levelCodeEditor) ->
    @levelCodeEditorsById[levelCodeEditor.getId()] = levelCodeEditor
    @emitter.emit('did-add-level-code-editor',levelCodeEditor)

  destroyLevelCodeEditor: (levelCodeEditor) ->
    delete @levelCodeEditorsById[levelCodeEditor.getId()]
    levelCodeEditor.destroy()
    @emitter.emit('did-destroy-level-code-editor')

  getLevelCodeEditorForTextEditor: (textEditor) ->
    @levelCodeEditorsById[textEditor.id]

  getLevelCodeEditors: ->
    levelCodeEditor for _,levelCodeEditor of @levelCodeEditorsById

  isLevelCodeEditor: (textEditor) ->
    @getLevelCodeEditorForTextEditor(textEditor)?

  ## Managing the active level code editor -------------------------------------

  getActiveLevelCodeEditor: ->
    @activeLevelCodeEditor

  getActiveLanguage: ->
    @activeLevelCodeEditor.getLanguage()

  getActiveLevel: ->
    @activeLevelCodeEditor.getLevel()

  setActiveLevelCodeEditor: (levelCodeEditor) ->
    if @isActive()
      unless levelCodeEditor.getId() is @activeLevelCodeEditor.getId()
        newLanguage = levelCodeEditor.getLanguage()
        oldLanguage = @activeLevelCodeEditor.getLanguage()
        newLevel = levelCodeEditor.getLevel()
        oldLevel = @activeLevelCodeEditor.getLevel()
        @unsubscribeFromActiveLevelCodeEditor()
        @activeLevelCodeEditor = levelCodeEditor
        if newLanguage.getName() isnt oldLanguage.getName()
          @emitter.emit('did-change-active-level',newLevel)
          @emitter.emit('did-change-active-language',{newLanguage,newLevel})
        else if newLevel.getName() isnt oldLevel.getName()
          @emitter.emit('did-change-active-level',newLevel)
        @subscribeToActiveLevelCodeEditor()
        @emitter.emit('did-change-active-level-code-editor',@activeLevelCodeEditor)
    else
      @activeLevelCodeEditor = levelCodeEditor
      @subscribeToActiveLevelCodeEditor()
      @emitter.emit('did-enter-workspace',@activeLevelCodeEditor)

  unsetActiveLevelCodeEditor: ->
    if @isActive()
      @unsubscribeFromActiveLevelCodeEditor()
      @activeLevelCodeEditor = null
      @emitter.emit('did-exit-workspace')

  subscribeToActiveLevelCodeEditor: ->
    @activeLevelCodeEditorSubscrs.add \
      @activeLevelCodeEditor.onDidChangeLanguage (language,level) =>
        @emitter.emit('did-change-active-language',{language,level})
    @activeLevelCodeEditorSubscrs.add \
      @activeLevelCodeEditor.onDidChangeLevel (level) =>
        @emitter.emit('did-change-active-level',level)

  unsubscribeFromActiveLevelCodeEditor: ->
    @activeLevelCodeEditorSubscrs.dispose()

# ------------------------------------------------------------------------------

module.exports =
class WorkspaceProvider

  instance = null

  @getInstance: ->
    instance ?= new Workspace

# ------------------------------------------------------------------------------
