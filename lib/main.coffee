levelsConfig     = require './levels-config'
levelsServices   = require './levels-services'
workspaceManager = require './workspace-manager'

module.exports =
  activate: (state) ->
    workspaceManager.setUpWorkspace state
    workspaceManager.activateEventHandlers()
    workspaceManager.activateCommandHandlers()

  deactivate: ->
    workspaceManager.cleanUpWorkspace()
    workspaceManager.deactivateEventHandlers()
    workspaceManager.deactivateCommandHandlers()

  config: levelsConfig

  provideLevels: ->
    return levelsServices

  consumeStatusBar: (statusBar) ->
    workspaceManager.consumeStatusBar statusBar

  serialize: ->
    workspaceManager.serializeWorkspace()