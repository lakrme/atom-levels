levelsConfig     = require './levels-config'
levelsServices   = require './levels-services'
workspaceManager = require('./workspace-manager').getInstance()

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
    levelsServices.provideLevels()

  consumeStatusBar: (statusBar) ->
    workspaceManager.consumeStatusBar statusBar

  serialize: ->
    workspaceManager.serializeWorkspace()