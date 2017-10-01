{CompositeDisposable} = require 'atom'
workspace             = require('./workspace').getInstance()

module.exports =
class LevelStatusView
  constructor: ->
    @element = document.createElement 'div'
    @element.className = 'level-status inline-block'
    @element.style.display = 'none'

    @statusLink = document.createElement 'a'
    @statusLink.className = 'inline-block'
    @statusLink.addEventListener 'click', => @toggleLevelSelect()
    @element.appendChild @statusLink

    @subscriptions = new CompositeDisposable
    @subscriptions.add workspace.onDidEnterWorkspace (activeLevelCodeEditor) => @handleOnDidEnterWorkspace activeLevelCodeEditor
    @subscriptions.add workspace.onDidExitWorkspace => @handleOnDidExitWorkspace()
    @subscriptions.add workspace.onDidChangeActiveLevel (activeLevel) => @handleOnDidChangeActiveLevel activeLevel

  destroy: ->
    @subscriptions.dispose()
    @statusTooltip?.dispose()
    return

  toggleLevelSelect: ->
    workspaceView = atom.views.getView atom.workspace
    atom.commands.dispatch workspaceView, 'levels:toggle-level-select'
    return

  handleOnDidEnterWorkspace: (activeLevelCodeEditor) ->
    @handleOnDidChangeActiveLevel activeLevelCodeEditor.getLevel()
    @element.style.display = ''
    return

  handleOnDidExitWorkspace: ->
    @element.style.display = 'none'
    return

  handleOnDidChangeActiveLevel: (activeLevel) ->
    activeLevelName = activeLevel.getName()
    @statusLink.textContent = activeLevelName
    @statusLink.dataset.level = activeLevelName

    @statusTooltip?.dispose()
    @statusTooltip = atom.tooltips.add @statusLink, {title: activeLevel.getDescription(), html: false}
    return