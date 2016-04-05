languageRegistry  = require('./language-registry').getInstance()
workspaceManager  = require('./workspace-manager').getInstance()

levelsConfig      = require('./levels-config')
levelsServices    = require('./levels-services')

# ------------------------------------------------------------------------------

module.exports =

  activate: (state) ->
    workspaceManager.setUpWorkspace(state)
    workspaceManager.activateEventHandlers()
    workspaceManager.activateCommandHandlers()

  deactivate: ->
    workspaceManager.cleanUpWorkspace()
    workspaceManager.deactivateEventHandlers()
    workspaceManager.deactivateCommandHandlers()

  ## Configuration -------------------------------------------------------------

  config: levelsConfig

  ## Provided services ---------------------------------------------------------

  provideLevels: levelsServices.provideLevels

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    workspaceManager.consumeStatusBar(statusBar)

  ## Serialization -------------------------------------------------------------

  serialize: ->
    workspaceManager.serializeWorkspace()

# ------------------------------------------------------------------------------
