commandDispatcher = require('./core-command-dispatcher').getInstance()
configRegistry    = require('./core-config-registry').getInstance()
eventDispatcher   = require('./core-event-dispatcher').getInstance()
executionManager  = require('./core-execution-manager').getInstance()
languageRegistry  = require('./core-language-registry').getInstance()
sessionManager    = require('./core-session-manager').getInstance()
viewManager       = require('./core-view-manager').getInstance()

# ------------------------------------------------------------------------------

module.exports =

  config:
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
    grammarNamePattern:
      title: 'Grammar Name Pattern'
      description: 'This is a description.'
      type: 'string'
      default: 'Levels: <languageName>'

  activate: (state) ->
    state.viewManagerState ?= {}

    configRegistry.initialize()
    languageRegistry.initialize()
    executionManager.initialize()
    sessionManager.initialize()
    viewManager.initialize(state.viewManagerState)
    eventDispatcher.initialize()
    commandDispatcher.initialize()

  deactivate: ->
    viewManager.destroyAllViews()
    eventDispatcher.disposeAllEventSubscriptions()
    commandDispatcher.disposeAllCommandHandlers()

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    viewManager.consumeStatusBar(statusBar)

  ## Serialization -------------------------------------------------------------

  serialize: ->
    viewManagerState: viewManager.serialize()

# ------------------------------------------------------------------------------
