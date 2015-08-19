{Emitter} = require 'atom'
{View}    = require 'atom-space-pen-views'

module.exports =
class TerminalView extends View

  @content: ->
    @div class: 'levels-view terminal', =>
      @div class: 'resize-handle', outlet: 'resizeHandle'
      @div class: 'control-bar', outlet: 'controlBar', =>

        @div class: 'control-bar-left', =>

          # showing and hiding the terminal
          @a href: '#', click: 'showTerminalView', outlet: 'terminalShowTile', =>
            @span class: 'icon icon-triangle-up', =>
              @text 'Show Terminal'
          @a href: '#', click: 'hideTerminalView', outlet: 'terminalHideTile', =>
            @span class: 'icon icon-triangle-down', =>
              @text 'Hide Terminal'

          # terminal controls
          @div class: 'terminal-controls', outlet: 'terminalControls', =>
            @div class: 'control-bar-separator'
            @a href: '#', click: 'clearTerminalView', =>
              @span class: 'icon icon-x', =>
                @text 'Clear'
            @a href: '#', click: 'scrollTerminalViewToTop', =>
              @span class: 'icon icon-move-up', =>
                @text 'Scroll To Top'
            @a href: '#', click: 'scrollTerminalViewToBottom', =>
              @span class: 'icon icon-move-down', =>
                @text 'Scroll To Bottom'

        @div class: 'control-bar-right', =>

          # execution controls
          @div class: 'execution-controls', outlet: 'executionControls', =>
            @a href: '#', click: 'startExecution', outlet: 'executionStartTile', =>
              @span class: 'text-success icon icon-playback-play', =>
                @text 'Run'
            @a href: '#', click: 'stopExecution', outlet: 'executionStopTile', =>
              @span class: 'text-error icon icon-primitive-square', =>
                @text 'Stop'

          @div class: 'control-bar-separator'

          # language controls
          @a href: '#', click: 'toggleLanguageConfigView', =>
            @span class: 'icon icon-gear', =>
              @text 'Language Configuration'

      @div class: 'content', outlet: 'terminalFrame', =>
        @div class: 'cursor', outlet: 'cursor', =>
          @raw '&nbsp;'


  initialize: (@terminal) ->

    @terminal.onDidCreateNewActiveLine =>
      @createNewActiveLine()

    @terminal.onDidUpdateActiveLine (activeLineState) =>
      @updateActiveLine(activeLineState)
