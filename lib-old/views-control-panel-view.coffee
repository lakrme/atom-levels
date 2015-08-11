{$,View} = require 'atom-space-pen-views'

executionManager = require('./core-execution-manager').getInstance()

# ------------------------------------------------------------------------------

module.exports =
class ControlPanelView extends View

  @content: ->
    @div class: 'levels-view control-panel', =>
      @div class: 'control-panel-resize-handle', outlet: 'resizeHandle'
      @div class: 'control-bar', tabindex: 0, outlet: 'controlBar', =>

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

      @div class: 'terminal-frame', outlet: 'terminalFrame'

  initialize: (@viewManager,state) ->
    @controlBarHeight = 26
    @minHeightWhenShown = @controlBarHeight + 200
    @minHeightWhenHidden = @controlBarHeight
    @height(state?.height ? @minHeightWhenShown + 100)

    @hideTerminalView()
    @showTerminalView() unless (state?.terminalHidden ? true)

  destroy: ->
    @off()
    @panel?.destroy()

  ## Displaying the terminal ---------------------------------------------------

  showTerminalView: ->
    if @terminalHidden
      @css('min-height',@minHeightWhenShown)
      @height(@lastHeight)
      @terminalShowTile.hide()
      @terminalHideTile.show()
      # @terminalControls.show()
      @terminalControls.css('display','inline')
      @resizeHandle.show()
      @terminalHidden = false

      # set event listeners
      @off('keydown')
      @on 'keydown', (event) =>
        executionManager.handleKeyEvent(@terminal,event)

      # focus the control panel
      @focus()

  hideTerminalView: ->
    unless @terminalHidden
      @css('min-height',@minHeightWhenHidden)
      @lastHeight = @height()
      @height(@minHeightWhenHidden)
      @terminalShowTile.show()
      @terminalHideTile.hide()
      @terminalControls.hide()
      @resizeHandle.hide()
      @terminalHidden = true

      # detach the keydown event listener
      @off('keydown')

  toggleTerminalView: ->
    if @terminalHidden
      @showTerminalView()
    else
      @hideTerminalView()

  ## Terminal controls ---------------------------------------------------------

  clearTerminalView: ->
    @terminal.view.clear()

  scrollTerminalViewToTop: ->
    @terminal.view.scrollToTop()

  scrollTerminalViewToBottom: ->
    @terminal.view.scrollToBottom()

  ## Displaying the execution control elements ---------------------------------

  showStartExecutionControls: ->
    @executionStartTile.show()
    @executionStopTile.hide()

  showStopExecutionControls: ->
    @executionStartTile.hide()
    @executionStopTile.show()

  ## Execution controls --------------------------------------------------------

  startExecution: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,"levels:start-execution")

  stopExecution: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,"levels:stop-execution")

  ## Language controls ---------------------------------------------------------

  toggleLanguageConfigView: ->
    @viewManager.languageConfigView.toggle(@languageData)

  ## Displaying the control panel ----------------------------------------------

  show: (@textEditor,@languageData,@terminal) ->
    # update the control panel view components
    @terminalFrame.empty()
    @terminalFrame.append(@terminal.view)

    # display the execution controls
    if @terminal.isExecuting
      @showStopExecutionControls()
    else
      @showStartExecutionControls()

    # detach old event listeners
    @off()

    # attach fresh event listeners
    @on 'mousedown', '.control-panel-resize-handle', =>
      @resizeStarted()
    @on 'dblclick', '.control-panel-resize-handle', =>
      @resizeToMinHeight()
    @on 'click', '.warning-link', (event) =>
      @handleClickIssueLink(event.target)
    @on 'click', '.error-link', (event) =>
      @handleClickIssueLink(event.target)
    @on 'click', (event) =>
      className = event.target.className
      @focus() unless className is 'warning-link' or className is 'error-link'

    unless @terminalHidden
      @on 'keydown', (event) =>
        executionManager.handleKeyEvent(@terminal,event)

    @panel ?= atom.workspace.addBottomPanel(item: this)
    @terminal.view.setTextEditor(@textEditor)
    @terminal.view.scrollToBottom()

  # show: (@textEditor,sessionData) ->
  #   @language      = sessionData.language
  #   @level         = sessionData.level
  #   @terminalModel = sessionData.terminal.model
  #   @terminalView  = sessionData.terminal.view
  #   height         = sessionData.viewState.controlPanel.height
  #   terminalHidden = sessionData.viewState.controlPanel.terminalHidden
  #
  #   # display execution controls
  #   if @terminalModel.isExecuting
  #     @showStopExecutionControls()
  #   else
  #     @showStartExecutionControls()
  #
  #   # append the terminal view
  #   @terminalFrame.empty()
  #   @terminalFrame.append(@terminalView)
  #   @terminalView.scrollToBottom()
  #
  #   @panel ?= atom.workspace.addBottomPanel(item: this)

  hide: ->
    @off()
    @panel?.destroy()
    @panel = null

  update: (@language,@level) ->
    # TODO things to do when updating the language

  focus: ->
    @controlBar.focus()
    # @focused = true

  handleClickIssueLink: (element) ->
    row = parseInt(element.getAttribute('data-row'))-1
    col = parseInt(element.getAttribute('data-col') ? 0)-1

    pos = @textEditor.clipBufferPosition([row,col])
    atom.views.getView(@textEditor).focus()
    @textEditor.setCursorBufferPosition(pos)

  ## Resizing the control panel ------------------------------------------------

  # TODO save scroll position in a variable?
  # TODO keep scroll position in terminal when resizing
  # TODO scroll in line gaps rather than continuous

  resizeStarted: =>
    $(document).on('mousemove',@resize)
    $(document).on('mouseup',@resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove',@resize)
    $(document).off('mouseup',@resizeStopped)

  resize: ({pageY,which}) =>
    return @resizeStopped() unless which is 1
    height = $(document.body).height() - pageY
    @height(height)

  resizeToMinHeight: =>
    @height(@minHeightWhenShown)

  ## Serialization -------------------------------------------------------------

  serialize: ->
    height: if @terminalHidden then @lastHeight else @height()
    terminalHidden: @terminalHidden

# ------------------------------------------------------------------------------
