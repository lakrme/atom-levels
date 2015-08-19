{CompositeDisposable} = require('atom')
{View}                = require('atom-space-pen-views')

workspace             = require('./workspace').getInstance()

# ------------------------------------------------------------------------------

module.exports =
class LevelStatusView extends View

  @content: ->
    @div class: 'levels-view level-status inline-block', =>
      @a class: 'inline-block',
         href: '#',
         click: 'handleDidClickLevelStatusLink',
         outlet: 'levelStatusLink'

  ## Initialization and destruction --------------------------------------------

  initialize: ->
    @workspaceSubscrs = new CompositeDisposable
    @workspaceSubscrs.add workspace.onDidEnterWorkspace =>
      @update(workspace.getActiveLevel())
      @show()
    @workspaceSubscrs.add workspace.onDidExitWorkspace =>
      @hide()
    @workspaceSubscrs.add workspace.onDidChangeActiveLevel (activeLevel) =>
      @update(activeLevel)

  destroy: ->
    @workspaceSubscrs.dispose()

  ## Handling view events ------------------------------------------------------

  handleDidClickLevelStatusLink: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:toggle-level-select')

  ## Updating this view --------------------------------------------------------

  update: (activeLevel) ->
    # TODO check is level name is to long, shorten the link?
    activeLevelName = activeLevel.getName()
    @levelStatusLink.text("(#{activeLevelName})")
    @levelStatusLink.attr('data-level',activeLevelName)

  ## Showing and hiding this view ----------------------------------------------

  show: ->
    @css({display: ''})

  hide: ->
    @css({display: 'none'})

# ------------------------------------------------------------------------------
