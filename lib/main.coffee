languageRegistry  = require('./language-manager').getInstance()
workspaceManager  = require('./workspace-manager').getInstance()

notificationUtils = require('./notification-utils')
terminalUtils     = require('./terminal-utils')

# ------------------------------------------------------------------------------

module.exports =

  config:
    whenToWriteFileHeader:
      title: 'When To Write The Language Information File Header'
      description:
        "Determines when to write the language information file header which is
        used to identify the language and the level of a file (note that writing
        the file header after setting the level will modify the buffer)."
      type: 'string'
      default: 'before saving the buffer'
      enum: ['before saving the buffer','after setting the level']
    defaultTerminalIsHidden:
      title: 'Initially Hide The Terminal'
      description:
        "If enabled, level code editor terminals will initially be hidden."
      type: 'boolean'
      default: terminalUtils.DEFAULT_IS_HIDDEN
    defaultTerminalSize:
      title: 'Default Terminal Size'
      description:
        "The default size (in visible lines) of newly spawned level code editor
        terminals."
      type: 'integer'
      default: terminalUtils.DEFAULT_SIZE
      minimum: terminalUtils.MIN_SIZE
    defaultTerminalFontSize:
      title: 'Default Terminal Font Size'
      description:
        "The default font size (in pixels) of newly spawned level code editor
        terminals."
      type: 'integer'
      default: terminalUtils.DEFAULT_FONT_SIZE
      minimum: terminalUtils.MIN_FONT_SIZE
      maximum: terminalUtils.MAX_FONT_SIZE
    showAllInfos:
      title: 'Show All Info Notifications'
      description:
        "If disabled, only important info notifications will be displayed."
      type: 'boolean'
      default: notificationUtils.DEFAULT_SHOW_ALL_INFOS
    showAllSuccesses:
      title: 'Show All Success Notifications'
      description:
        "If disabled, only important success notifications will be displayed."
      type: 'boolean'
      default: notificationUtils.DEFAULT_SHOW_ALL_SUCCESSES
    showAllWarnings:
      title: 'Show All Warning Notifications'
      description:
        "If disabled, only important warning notifications will be displayed."
      type: 'boolean'
      default: notificationUtils.DEFAULT_SHOW_ALL_WARNINGS
    showAllErrors:
      title: 'Show All Error Notifications'
      description:
        "If disabled, only important error notifications will be displayed."
      type: 'boolean'
      default: notificationUtils.DEFAULT_SHOW_ALL_ERRORS

  activate: (state) ->
    workspaceManager.setUpWorkspace(state)
    workspaceManager.activateEventHandlers()
    workspaceManager.activateCommandHandlers()

  deactivate: ->
    workspaceManager.cleanUpWorkspace()
    workspaceManager.deactivateEventHandlers()
    workspaceManager.deactivateCommandHandlers()

  ## Provided services ---------------------------------------------------------

  provideLevels: ->
    languageRegistry:
      addLanguage: languageRegistry.addLanguage.bind(languageRegistry)
      readLanguage: languageRegistry.readLanguage.bind(languageRegistry)
      loadLanguage: languageRegistry.loadLanguage.bind(languageRegistry)
      removeLanguage: languageRegistry.removeLanguage.bind(languageRegistry)

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    workspaceManager.consumeStatusBar(statusBar)

  ## Serialization -------------------------------------------------------------

  serialize: ->
    workspaceManager.serializeWorkspace()

# ------------------------------------------------------------------------------
