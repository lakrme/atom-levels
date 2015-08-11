{View} = require 'atom-space-pen-views'

# ------------------------------------------------------------------------------

module.exports =
class LevelStatusView extends View

  @content: ->
    @div class: 'levels-view level-status inline-block', =>
      @a class: 'inline-block', href: '#', click: 'toggleLevelSelectView'
                                         , outlet: 'levelStatusLink'

  ## Displaying the level selector ---------------------------------------------

  toggleLevelSelectView: (event,element) ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:toggle-level-select')

  ## Displaying the level status -----------------------------------------------

  show: (@languageData) ->
    # TODO check is level name is to long, shorten the link
    level = @languageData.level
    @levelStatusLink.text("(#{level.name})")
    @levelStatusLink.attr('data-level',level.name)
    @css({display:''})

  hide: ->
    @css({display:'none'})

# ------------------------------------------------------------------------------
