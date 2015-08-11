# ------------------------------------------------------------------------------

class WorkspaceManager

  constructor: ->

  setUpWorkspace: (state) ->

  cleanUpWorkspace: ->

  consumeStatusBar: (@statusBar) ->

  ## Serialization -------------------------------------------------------------

  serialize: ->

# ------------------------------------------------------------------------------

module.exports =
class WorkspaceManagerProvider

  instance = null

  @getInstance: ->
    instance ?= new WorkspaceManager

# ------------------------------------------------------------------------------
