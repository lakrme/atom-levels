languageManager   = require('./language-manager').getInstance()
workspaceManager  = require('./workspace-manager').getInstance()

notificationUtils = require('./notification-utils')
terminalUtils     = require('./terminal-utils')

# ------------------------------------------------------------------------------

module.exports =

  config:
    # NOTE this is commented out because (for whatever reason) nested options
    # sometimes do not appear in the preferences pane
    # workspaceSettings:
    #   type: 'object'
    #   properties:
    # -----------------------------------------------------------------------
    whenToWriteFileHeader:
      title: 'When To Write File Header'
      description: 'This is a description.'
      type: 'string'
      default: 'before saving the buffer'
      enum: ['before saving the buffer','after setting the level']
    # NOTE see above
    # terminalSettings:
    #   type: 'object'
    #   properties:
    # --------------
    defaultTerminalIsVisible:
      title: 'Default Terminal Is Visible'
      description: 'This is a description.'
      type: 'boolean'
      default: terminalUtils.DEFAULT_IS_VISIBLE
    defaultTerminalSize:
      title: 'Default Terminal Size'
      description: 'This is a description.'
      type: 'integer'
      default: terminalUtils.DEFAULT_SIZE
      minimum: terminalUtils.MIN_SIZE
    defaultTerminalFontSize:
      title: 'Default Terminal Font Size'
      description: 'This is a description.'
      type: 'integer'
      default: terminalUtils.DEFAULT_FONT_SIZE
      minimum: terminalUtils.MIN_FONT_SIZE
      maximum: terminalUtils.MAX_FONT_SIZE
    # NOTE see above
    # notificationSettings:
    #   type: 'object'
    #   properties:
    # --------------
    showAllInfos:
      title: 'Show All Info Notifications'
      description: 'This is a description.'
      type: 'boolean'
      default: notificationUtils.DEFAULT_SHOW_ALL_INFOS
    showAllSuccesses:
      title: 'Show All Success Notifications'
      description: 'This is a description.'
      type: 'boolean'
      default: notificationUtils.DEFAULT_SHOW_ALL_SUCCESSES
    showAllWarnings:
      title: 'Show All Warning Notifications'
      description: 'This is a description.'
      type: 'boolean'
      default: notificationUtils.DEFAULT_SHOW_ALL_WARNINGS
    showAllErrors:
      title: 'Show All Error Notifications'
      description: 'This is a description.'
      type: 'boolean'
      default: notificationUtils.DEFAULT_SHOW_ALL_ERRORS

  activate: (state) ->
    languageManager.loadInstalledLanguages()

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
