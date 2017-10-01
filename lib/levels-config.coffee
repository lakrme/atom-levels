notificationUtils = require './notification-utils'
terminalUtils     = require './terminal-utils'
workspaceUtils    = require './workspace-utils'

module.exports =
  workspaceSettings:
    title: 'Workspace Settings'
    type: 'object'
    order: 1
    properties:
      clearTerminalOnExecution:
        title: 'Clear The Terminal On Execution'
        description: 'If enabled, the terminal will be cleared immediately before running a program.'
        type: 'boolean'
        default: workspaceUtils.DEFAULT_CLEAR_TERMINAL_ON_EXECUTION
      whenToWriteFileHeader:
        title: 'When To Write The Language Information File Header'
        description: 'Determines when to write the language information file header
          which is used to identify the language and the level of a file (note that
          writing the file header after setting the level will modify the buffer).'
        type: 'string'
        default: workspaceUtils.DEFAULT_WHEN_TO_WRITE_FILE_HEADER
        enum: ['before saving the buffer', 'after setting the level', 'never']

  terminalSettings:
    title: 'Terminal Settings'
    type: 'object'
    order: 2
    properties:
      defaultTerminalFontSize:
        title: 'Default Terminal Font Size'
        description: 'The default font size (in pixels) of newly spawned level code editor terminals.'
        type: 'integer'
        default: terminalUtils.DEFAULT_FONT_SIZE
        enum: terminalUtils.FONT_SIZES
        order: 2
      defaultTerminalIsHidden:
        title: 'Initially Hide The Terminal'
        description: 'If enabled, level code editor terminals will initially be hidden.'
        type: 'boolean'
        default: terminalUtils.DEFAULT_IS_HIDDEN
        order: 1
      defaultTerminalSize:
        title: 'Default Terminal Size'
        description: 'The default size (in visible lines) of newly spawned level code editor terminals.'
        type: 'integer'
        default: terminalUtils.DEFAULT_SIZE
        minimum: terminalUtils.MIN_SIZE
        order: 3
      terminalContentLimit:
        title: 'Terminal Content Limit'
        description: 'Specifies the maximum terminal content size (in lines). When
          reaching the content limit, the terminal is cleared automatically
          which may reduce output performance issues. Set this to `0` to
          prevent the terminal from being cleared automatically.'
        type: 'integer'
        default: terminalUtils.DEFAULT_CONTENT_LIMIT
        minimum: 0
        order: 4

  notificationSettings:
    title: 'Notification Settings'
    type: 'object'
    order: 3
    properties:
      showAllErrors:
        title: 'Show All Error Notifications'
        description: 'If disabled, only important error notifications will be displayed.'
        type: 'boolean'
        default: notificationUtils.DEFAULT_SHOW_ALL_ERRORS
      showAllInfos:
        title: 'Show All Info Notifications'
        description: 'If disabled, only important info notifications will be displayed.'
        type: 'boolean'
        default: notificationUtils.DEFAULT_SHOW_ALL_INFOS
      showAllSuccesses:
        title: 'Show All Success Notifications'
        description: 'If disabled, only important success notifications will be displayed.'
        type: 'boolean'
        default: notificationUtils.DEFAULT_SHOW_ALL_SUCCESSES
      showAllWarnings:
        title: 'Show All Warning Notifications'
        description: 'If disabled, only important warning notifications will be displayed.'
        type: 'boolean'
        default: notificationUtils.DEFAULT_SHOW_ALL_WARNINGS