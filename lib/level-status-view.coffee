{View} = require 'atom-space-pen-views'

# ------------------------------------------------------------------------------

module.exports =
class LevelStatusView extends View

  @content: ->
    @div class: 'levels-view level-status inline-block', =>
      @a class: 'inline-block', href: '#', click: 'handleDidClickLevelStatusLink'
                                         , outlet: 'levelStatusLink'

  initialize: (@workspace) ->
    # set up model event subscriptions
    workspace.onDidEnterWorkspace =>
      @handleDidEnterWorkspace()
    workspace.onDidExitWorkspace =>
      @handleDidExitWorkspace()

  destroy: ->

  ## Handling view events ------------------------------------------------------

  handleDidClickLevelStatusLink: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:toggle-level-select')

  ## Handling model events -----------------------------------------------------

  handleDidEnterWorkspace: ->
    # get active workspace session
    @activeWorkspaceSession = @workspaceManager.getActiveWorkspaceSession()
    # set up workspace session event subscription
    didChangeLevelSubscription?.dispose()
    didChangeLevelSubscription = @activeWorkspaceSession.onDidChangeLevel =>
      @update()
    # update content and make the view visible
    @update()
    @show()

  handleDidExitWorkspace: ->
    @hide()
    didChangeLevelSubscription?.dispose()
    @activeWorkspaceSession = null

  ## Updating this view's content ----------------------------------------------

  update: ->
    # TODO check is level name is to long, shorten the link?
    levelName = @activeWorkspaceSession.getLevel().getName()
    @levelStatusLink.text("(#{levelName})")
    @levelStatusLink.attr('data-level',levelName)

  ## Showing and hiding this view ----------------------------------------------

  show: ->
    @css({display: ''})

  hide: ->
    @css({display: 'none'})

# ------------------------------------------------------------------------------
