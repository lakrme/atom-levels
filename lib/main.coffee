languageInstaller = require('./language-installer').getInstance()
languageRegistry  = require('./language-registry').getInstance()
workspaceManager  = require('./workspace-manager').getInstance()
workspace         = require('./workspace').getInstance()

# ------------------------------------------------------------------------------

module.exports =

  config:
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

    languageInstaller.activate()

    workspaceManager.setUpWorkspace(state)
    workspaceManager.activate()

  deactivate: ->
    workspaceManager.deactivate()

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    # workspaceManager.consumeStatusBar(statusBar)

  ## Serialization -------------------------------------------------------------

  serialize: ->
    workspace.serialize()

# ------------------------------------------------------------------------------
