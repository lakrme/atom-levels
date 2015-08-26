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
         click: 'doToggleLevelSelect',
         outlet: 'levelStatusLink'

  ## Initialization and destruction --------------------------------------------

  initialize: ->
    # subscribe to the Levels workspace
    @workspaceSubscrs = new CompositeDisposable
    @workspaceSubscrs.add workspace.onDidEnterWorkspace \
      (activeLevelCodeEditor) =>
        @updateOnDidEnterWorkspace(activeLevelCodeEditor)
    @workspaceSubscrs.add workspace.onDidExitWorkspace =>
        @updateOnDidExitWorkspace()
    @workspaceSubscrs.add workspace.onDidChangeActiveLevel \
      (activeLevel) =>
        @updateOnDidChangeActiveLevelOfWorkspace(activeLevel)

  destroy: ->
    @workspaceSubscrs.dispose()

  ## Handling view events ------------------------------------------------------

  doToggleLevelSelect: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:toggle-level-select')

  ## Updating this view --------------------------------------------------------

  updateOnDidEnterWorkspace: (activeLevelCodeEditor) ->
    @updateOnDidChangeActiveLevelOfWorkspace(activeLevelCodeEditor.getLevel())
    @show()

  updateOnDidExitWorkspace: ->
    @hide()

  updateOnDidChangeActiveLevelOfWorkspace: (@activeLevel) ->
    # TODO check is level name is to long, shorten the link?
    activeLevelName = activeLevel.getName()
    # ------------------------------------------------------
    @levelStatusLink.text("(#{activeLevelName})")
    @levelStatusLink.attr('data-level',activeLevelName)

  ## Showing and hiding this view ----------------------------------------------

  show: ->
    @css({display: ''})

  hide: ->
    @css({display: 'none'})

# ------------------------------------------------------------------------------
