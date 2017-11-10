{CompositeDisposable, Emitter} = require 'atom'

class Workspace
  constructor: ->
    @emitter = new Emitter
    @levelCodeEditorsById = {}
    @activeLevelCodeEditor = null
    @activeLevelCodeEditorSubscriptions = new CompositeDisposable

  onDidEnterWorkspace: (callback) ->
    @emitter.on 'did-enter-workspace', callback

  onDidExitWorkspace: (callback) ->
    @emitter.on 'did-exit-workspace', callback

  observeLevelCodeEditors: (callback) ->
    for levelCodeEditor in @getLevelCodeEditors()
      callback levelCodeEditor
    @onDidAddLevelCodeEditor callback

  onDidAddLevelCodeEditor: (callback) ->
    @emitter.on 'did-add-level-code-editor', callback

  onDidDestroyLevelCodeEditor: (callback) ->
    @emitter.on 'did-destroy-level-code-editor', callback

  onDidChangeActiveLevelCodeEditor: (callback) ->
    @emitter.on 'did-change-active-level-code-editor', callback

  onDidChangeActiveLanguage: (callback) ->
    @emitter.on 'did-change-active-language', callback

  onDidChangeActiveLevel: (callback) ->
    @emitter.on 'did-change-active-level', callback

  onDidChangeActiveTerminal: (callback) ->
    @emitter.on 'did-change-active-terminal', callback

  isActive: ->
    return @activeLevelCodeEditor?

  addLevelCodeEditor: (levelCodeEditor) ->
    @levelCodeEditorsById[levelCodeEditor.getId()] = levelCodeEditor
    @emitter.emit 'did-add-level-code-editor', levelCodeEditor
    return

  destroyLevelCodeEditor: (levelCodeEditor) ->
    delete @levelCodeEditorsById[levelCodeEditor.getId()]
    levelCodeEditor.destroy()
    @emitter.emit 'did-destroy-level-code-editor', levelCodeEditor
    return

  getLevelCodeEditorForId: (levelCodeEditorId) ->
    return @levelCodeEditorsById[levelCodeEditorId]

  getLevelCodeEditorForTextEditor: (textEditor) ->
    return @levelCodeEditorsById[textEditor.id]

  getLevelCodeEditors: ->
    levelCodeEditor for _, levelCodeEditor of @levelCodeEditorsById

  isLevelCodeEditor: (textEditor) ->
    return @getLevelCodeEditorForTextEditor(textEditor)?

  getActiveLevelCodeEditor: ->
    return @activeLevelCodeEditor

  getActiveLanguage: ->
    return @activeLevelCodeEditor?.getLanguage()

  getActiveLevel: ->
    return @activeLevelCodeEditor?.getLevel()

  getActiveTerminal: ->
    return @activeLevelCodeEditor?.getTerminal()

  setActiveLevelCodeEditor: (levelCodeEditor) ->
    if @isActive()
      if levelCodeEditor.getId() != @activeLevelCodeEditor.getId()
        newLanguage = levelCodeEditor.getLanguage()
        oldLanguage = @activeLevelCodeEditor.getLanguage()
        newLevel = levelCodeEditor.getLevel()
        oldLevel = @activeLevelCodeEditor.getLevel()
        newTerminal = levelCodeEditor.getTerminal()
        oldTerminal = @activeLevelCodeEditor.getTerminal()

        @unsubscribeFromActiveLevelCodeEditor()
        @activeLevelCodeEditor = levelCodeEditor
        if newLanguage.getName() != oldLanguage.getName()
          @emitter.emit 'did-change-active-level', newLevel
          @emitter.emit 'did-change-active-language',
            activeLanguage: newLanguage
            activeLevel: newLevel
        else if newLevel.getName() != oldLevel.getName()
          @emitter.emit 'did-change-active-level', newLevel
        @subscribeToActiveLevelCodeEditor()
        @emitter.emit 'did-change-active-terminal', newTerminal
        @emitter.emit 'did-change-active-level-code-editor', @activeLevelCodeEditor
    else
      @activeLevelCodeEditor = levelCodeEditor
      @subscribeToActiveLevelCodeEditor()
      @emitter.emit 'did-enter-workspace', @activeLevelCodeEditor
    return

  unsetActiveLevelCodeEditor: ->
    if @isActive()
      @unsubscribeFromActiveLevelCodeEditor()
      @activeLevelCodeEditor = null
      @emitter.emit 'did-exit-workspace'
    return

  subscribeToActiveLevelCodeEditor: ->
    @activeLevelCodeEditorSubscriptions.add @activeLevelCodeEditor.onDidChangeLanguage ({language, level}) =>
      @emitter.emit 'did-change-active-language',
        activeLanguage: language
        activeLevel: level
    @activeLevelCodeEditorSubscriptions.add @activeLevelCodeEditor.onDidChangeLevel (level) =>
      @emitter.emit 'did-change-active-level', level
    return

  unsubscribeFromActiveLevelCodeEditor: ->
    @activeLevelCodeEditorSubscriptions.dispose()
    return

module.exports = new Workspace