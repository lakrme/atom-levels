# commandDispatcher = require './command-dispatcher'
# eventDispatcher   = require './event-dispatcher'
languageRegistry  = require('./language-registry').getInstance()
workspaceManager  = require('./workspace-manager').getInstance()

# ------------------------------------------------------------------------------

module.exports =

  config:
    # workspaceSettings:
    #   type: 'object'
    #   properties:
    #     useOneTerminalForAllTextEditors
    #       title:
    #       description: 'This is a description.'
    #       type: 'boolean'
    #       default: false
    #     initiallyHideTheTerminal:
    #
    notificationSettings:
      type: 'object'
      properties:
        showAllInfoNotifications:
          title: 'Show All Info Notifications'
          description: 'This is a description.'
          type: 'boolean'
          default: true
        showAllSuccessNotifications:
          title: 'Show All Success Notifications'
          description: 'This is a description.'
          type: 'boolean'
          default: true
        showAllWarningNotifications:
          title: 'Show All Warning Notifications'
          description: 'This is a description.'
          type: 'boolean'
          default: true
        showAllErrorNotifications:
          title: 'Show All Error Notifications'
          description: 'This is a description.'
          type: 'boolean'
          default: true

  activate: (state={}) ->
    # initialize the language registry
    languageRegistry.loadInstalledLanguages()
    # set up the package workspaces
    workspaceManager.setUpWorkspace(state)
    # activate the event dispatchers
    # commandDispatcher.activate()
    # eventDispatcher.activate()

  deactivate: ->
    # clean up the package workspace
    workspaceManager.cleanUpWorkspace()
    # deactivate the event dispatchers
    # eventDispatcher.deactivate()
    # commandDispatcher.deactivate()

  ## Provided services ---------------------------------------------------------

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    workspaceManager.consumeStatusBar(statusBar)

  ## Serialization -------------------------------------------------------------

  serialize: ->
    workspaceManager.serialize()

# ------------------------------------------------------------------------------
