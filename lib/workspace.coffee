{CompositeDisposable,Emitter} = require('atom')

# ------------------------------------------------------------------------------

class Workspace

  ## Construction --------------------------------------------------------------

  constructor: ->
    @emitter = new Emitter
    @levelCodeEditorsById = {}
    @activeLevelCodeEditor = null
    @activeLevelCodeEditorSubscrs = new CompositeDisposable

  ## Event subscription --------------------------------------------------------

  onDidEnterWorkspace: (callback) ->
    @emitter.on('did-enter-workspace',callback)

  onDidExitWorkspace: (callback) ->
    @emitter.on('did-exit-workspace',callback)

  observeLevelCodeEditors: (callback) ->
    callback(levelCodeEditor) for levelCodeEditor in @getLevelCodeEditors()
    @onDidAddLevelCodeEditor(callback)

  onDidAddLevelCodeEditor: (callback) ->
    @emitter.on('did-add-level-code-editor',callback)

  onDidDestroyLevelCodeEditor: (callback) ->
    @emitter.on('did-destroy-level-code-editor',callback)

  onDidChangeActiveLevelCodeEditor: (callback) ->
    @emitter.on('did-change-active-level-code-editor',callback)

  onDidChangeActiveLanguage: (callback) ->
    @emitter.on('did-change-active-language',callback)

  onDidChangeActiveLevel: (callback) ->
    @emitter.on('did-change-active-level',callback)

  onDidChangeActiveTerminal: (callback) ->
    @emitter.on('did-change-active-terminal',callback)

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
    @emitter.emit('did-destroy-level-code-editor',levelCodeEditor)

  getLevelCodeEditorForId: (levelCodeEditorId) ->
    @levelCodeEditorsById[levelCodeEditorId]

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
    @activeLevelCodeEditor?.getLanguage()

  getActiveLevel: ->
    @activeLevelCodeEditor?.getLevel()

  getActiveTerminal: ->
    @activeLevelCodeEditor?.getTerminal()

  setActiveLevelCodeEditor: (levelCodeEditor) ->
    if @isActive()
      unless levelCodeEditor.getId() is @activeLevelCodeEditor.getId()
        newLanguage = levelCodeEditor.getLanguage()
        oldLanguage = @activeLevelCodeEditor.getLanguage()
        newLevel = levelCodeEditor.getLevel()
        oldLevel = @activeLevelCodeEditor.getLevel()
        # NOTE currently a level code editor change is also a terminal change
        # but in the future it might be possible to alternatively share one
        # terminal with all level code editors
        newTerminal = levelCodeEditor.getTerminal()
        oldTerminal = @activeLevelCodeEditor.getTerminal()
        # -------------------------------------------------------------------
        @unsubscribeFromActiveLevelCodeEditor()
        @activeLevelCodeEditor = levelCodeEditor
        if newLanguage.getName() isnt oldLanguage.getName()
          @emitter.emit('did-change-active-level',newLevel)
          @emitter.emit 'did-change-active-language',
            activeLanguage: newLanguage
            activeLevel: newLevel
        else if newLevel.getName() isnt oldLevel.getName()
          @emitter.emit('did-change-active-level',newLevel)
        @subscribeToActiveLevelCodeEditor()
        # NOTE see above
        @emitter.emit('did-change-active-terminal',newTerminal)
        # --------------
        @emitter.emit('did-change-active-level-code-editor',\
        @activeLevelCodeEditor)
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
      @activeLevelCodeEditor.onDidChangeLanguage ({language,level}) =>
        @emitter.emit 'did-change-active-language',
          activeLanguage: language
          activeLevel: level
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
