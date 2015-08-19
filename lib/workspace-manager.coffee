{CompositeDisposable} = require('atom')

languageRegistry      = require('./language-registry').getInstance()
workspace             = require('./workspace').getInstance()

# languageUtils         = require('./language-utils')

LevelCodeEditor       = require('./level-code-editor')
LevelStatusView       = require('./level-status-view')
LevelSelectorView     = require('./level-selector-view')
LanguageConfigView    = require('./language-config-view')
TerminalView          = require('./terminal-view')
Terminal              = require('./terminal')

# ------------------------------------------------------------------------------

class WorkspaceManager

  ## Initialization and clean-up operations ------------------------------------

  setUpWorkspace: (state) ->
    # add view providers
    @viewProviders = new CompositeDisposable
    @viewProviders.add atom.views.addViewProvider Terminal, (terminal) ->
      new TerminalView(terminal)

    # create view components
    @levelStatusView = new LevelStatusView(workspace)
    @levelSelectorView = new LevelSelectorView(workspace)
    @languageConfigView = new LanguageConfigView(workspace)

  cleanUpWorkspace: ->
    # remove view providers
    @viewProviders.dispose()

    # destroy view components
    @levelStatusView.destroy()
    @levelSelectorView.destroy()
    @languageConfigView.destroy()

    # destroy status bar tiles
    @levelStatusTile.destroy()

  activate: ->
    @subscribeToAtomWorkspace()
    @subscribeToLanguageRegistry()

  deactivate: ->
    @unsubscribeFromAtomWorkspace()

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
      workspace.setActiveLevelCodeEditor(null)

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
    # do nothing if the grammar was changed due to a level change
    unless newGrammar.name is oldGrammarName
      # update the grammar subscription
      @textEditorSubscrsById[textEditor.id].didChangeGrammarSubscr.dispose()
      @textEditorSubscrsById[textEditor.id].didChangeGrammarSubscr = \
        textEditor.onDidChangeGrammar (grammar) =>
          @handleDidChangeGrammar(textEditor,newGrammar.name,grammar)
      # update Levels workspace based on the new grammar
      language = languageRegistry.getLanguageForGrammar(newGrammar)
      if workspace.isLevelCodeEditor(textEditor)
        levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor)
        if language?
          # new grammar is a Levels grammar too - update the level code editor
          levelCodeEditor.setLanguage(language)
        else
          # new grammar is not a Levels grammar - destroy the level code editor
          workspace.destroyLevelCodeEditor(levelCodeEditor)
      else
        if language?
          # new grammar is a Levels grammar - a new level code editor is born!
          levelCodeEditor = new LevelCodeEditor(textEditor,language)
          workspace.addLevelCodeEditor(levelCodeEditor)

  ## Language registry subscriptions -------------------------------------------

  subscribeToLanguageRegistry: ->
    languageRegistry.onDidRemoveLanguages (removedLanguages) =>
      @handleDidRemoveLanguages(removedLanguages)

  handleDidRemoveLanguages: (removedLanguages) ->

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    @levelStatusTile = statusBar.addRightTile
      item: @levelStatusView
      priority: 9

# ------------------------------------------------------------------------------

module.exports =
class WorkspaceManagerProvider

  instance = null

  @getInstance: ->
    instance ?= new WorkspaceManager

# ------------------------------------------------------------------------------
