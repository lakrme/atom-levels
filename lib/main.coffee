languageRegistry  = require('./language-registry').getInstance()
workspaceManager  = require('./workspace-manager').getInstance()

# ------------------------------------------------------------------------------

module.exports =

  config:
    workspaceSettings:
      type: 'object'
      properties:
        whenToWriteFileHeader:
          title: 'When To Write File Header'
          description: 'This is a description.'
          type: 'string'
          default: 'before saving the buffer'
          enum: ['before saving the buffer','after setting the level']
    notificationSettings:
      type: 'object'
      properties:
        showAllInfos:
          title: 'Show All Info Notifications'
          description: 'This is a description.'
          type: 'boolean'
          default: true
        showAllSuccesses:
          title: 'Show All Success Notifications'
          description: 'This is a description.'
          type: 'boolean'
          default: true
        showAllWarnings:
          title: 'Show All Warning Notifications'
          description: 'This is a description.'
          type: 'boolean'
          default: true
        showAllErrors:
          title: 'Show All Error Notifications'
          description: 'This is a description.'
          type: 'boolean'
          default: true

  activate: (state) ->
    languageRegistry.loadInstalledLanguages()

    workspaceManager.setUpWorkspace(state)
    workspaceManager.activateEventHandlers()
    workspaceManager.activateCommandHandlers()

  deactivate: ->
    workspaceManager.cleanUpWorkspace()
    workspaceManager.deactivateEventHandlers()
    workspaceManager.deactivateCommandHandlers()

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    workspaceManager.consumeStatusBar(statusBar)

  ## Serialization -------------------------------------------------------------

  serialize: ->
    workspaceManager.serializeWorkspace()

# ------------------------------------------------------------------------------
