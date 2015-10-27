languageRegistry  = require('./language-registry').getInstance()
workspaceManager  = require('./workspace-manager').getInstance()

notificationUtils = require('./notification-utils')
terminalUtils     = require('./terminal-utils')
workspaceUtils    = require('./workspace-utils')

# ------------------------------------------------------------------------------

module.exports =

  config:
    workspaceSettings:
      type: 'object'
      order: 1
      properties:
        whenToWriteFileHeader:
          title: 'When To Write The Language Information File Header'
          description:
            'Determines when to write the language information file header which
            is used to identify the language and the level of a file (note that
            writing the file header after setting the level will modify the
            buffer).'
          type: 'string'
          default: workspaceUtils.DEFAULT_WHEN_TO_WRITE_FILE_HEADER
          enum: ['before saving the buffer','after setting the level']
        clearTerminalOnExecution:
          title: 'Clear The Terminal On Execution'
          description:
            'If enabled, the terminal will be cleared immediately before running
            a program.'
          type: 'boolean'
          default: workspaceUtils.DEFAULT_CLEAR_TERMINAL_ON_EXECUTION
    terminalSettings:
      type: 'object'
      order: 2
      properties:
        defaultTerminalIsHidden:
          title: 'Initially Hide The Terminal'
          description:
            'If enabled, level code editor terminals will initially be hidden.'
          type: 'boolean'
          default: terminalUtils.DEFAULT_IS_HIDDEN
        defaultTerminalSize:
          title: 'Default Terminal Size'
          description:
            'The default size (in visible lines) of newly spawned level code
            editor terminals.'
          type: 'integer'
          default: terminalUtils.DEFAULT_SIZE
          minimum: terminalUtils.MIN_SIZE
        defaultTerminalFontSize:
          title: 'Default Terminal Font Size'
          description:
            'The default font size (in pixels) of newly spawned level code
            editor terminals.'
          type: 'integer'
          default: terminalUtils.DEFAULT_FONT_SIZE
          enum: [terminalUtils.MIN_FONT_SIZE..terminalUtils.MAX_FONT_SIZE]
        terminalContentLimit:
          title: 'Terminal Content Limit'
          description:
            'Specifies the maximum terminal content size (in lines). When
            reaching the content limit, the terminal is cleared automatically
            which may reduce output performance issues. Set this to `0` to
            prevent the terminal from being cleared automatically.'
          type: 'integer'
          default: terminalUtils.DEFAULT_CONTENT_LIMIT
          minimum: 0
    notificationSettings:
      type: 'object'
      order: 3
      properties:
        showAllInfos:
          title: 'Show All Info Notifications'
          description:
            'If disabled, only important info notifications will be displayed.'
          type: 'boolean'
          default: notificationUtils.DEFAULT_SHOW_ALL_INFOS
        showAllSuccesses:
          title: 'Show All Success Notifications'
          description:
            'If disabled, only important success notifications will be
            displayed.'
          type: 'boolean'
          default: notificationUtils.DEFAULT_SHOW_ALL_SUCCESSES
        showAllWarnings:
          title: 'Show All Warning Notifications'
          description:
            'If disabled, only important warning notifications will be
            displayed.'
          type: 'boolean'
          default: notificationUtils.DEFAULT_SHOW_ALL_WARNINGS
        showAllErrors:
          title: 'Show All Error Notifications'
          description:
            'If disabled, only important error notifications will be displayed.'
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
      observeLanguages:
        languageRegistry.observeLanguages.bind(languageRegistry)
      onDidAddLanguage:
        languageRegistry.onDidAddLanguage.bind(languageRegistry)
      onDidRemoveLanguage:
        languageRegistry.onDidRemoveLanguage.bind(languageRegistry)
      addLanguage:
        languageRegistry.addLanguage.bind(languageRegistry)
      readLanguageSync:
        languageRegistry.readLanguageSync.bind(languageRegistry)
      loadLanguageSync:
        languageRegistry.loadLanguageSync.bind(languageRegistry)
      removeLanguage:
        languageRegistry.removeLanguage.bind(languageRegistry)
      getLanguageForName:
        languageRegistry.getLanguageForName.bind(languageRegistry)
      getLanguageForGrammar:
        languageRegistry.getLanguageForGrammar.bind(languageRegistry)
      getLanguages:
        languageRegistry.getLanguages.bind(languageRegistry)
      getLanguagesForFileType:
        languageRegistry.getLanguagesForFileType.bind(languageRegistry)

  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    workspaceManager.consumeStatusBar(statusBar)

  ## Serialization -------------------------------------------------------------

  serialize: ->
    workspaceManager.serializeWorkspace()

# ------------------------------------------------------------------------------
