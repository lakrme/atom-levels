{CompositeDisposable} = require('atom')
{$,View}              = require('atom-space-pen-views')

terminalUtils         = require('./terminal-utils')

workspace             = require('./workspace').getInstance()

# ------------------------------------------------------------------------------

module.exports =
class TerminalPanelView extends View

  @content: ->
    @div class: 'levels-view terminal-panel', tabindex: 0, =>
      @div class: 'resize-handle', outlet: 'resizeHandle'
      @div class: 'control-bar', outlet: 'controlBar', =>

        @div class: 'control-bar-left', =>

          @div class: 'control-group', =>
            @div class: 'control-element', =>
              @a href: '#', click: 'doShowTerminal', \
                  outlet: 'showTerminalLink', =>
                @span class: 'icon icon-triangle-up', =>
                  @text 'Show Terminal'
            @div class: 'control-element', =>
              @a href: '#', click: 'doHideTerminal', \
                  outlet: 'hideTerminalLink', =>
                @span class: 'icon icon-triangle-down', =>
                  @text 'Hide Terminal'

          @div class: 'control-group terminal-controls', \
              outlet: 'terminalControls', =>

            @div class: 'control-bar-separator'

            @div class: 'control-element', =>
              @a href: '#', click: 'doClearTerminal', =>
                @span class: 'icon icon-x', =>
                  @text 'Clear'
            @div class: 'control-element', =>
              @a href: '#', click: 'doScrollTerminalToTop', =>
                @span class: 'icon icon-move-up', =>
                  @text 'Scroll To Top'
            @div class: 'control-element', =>
              @a href: '#', click: 'doScrollTerminalToBottom', =>
                @span class: 'icon icon-move-down', =>
                  @text 'Scroll To Bottom'

            @div class: 'control-bar-separator'

            @div class: 'control-element', =>
              @span class: 'icon icon-mention', =>
                @text 'Font Size:'
              @select class: 'font-size-select', outlet: 'fontSizeSelect'

        @div class: 'control-bar-right', =>

          @div class: 'control-group execution-controls', \
              outlet: 'executionControls', =>
            @a href: '#', click: 'doStartExecution', \
                outlet: 'startExecutionLink', =>
              @span class: 'text-success icon icon-playback-play', =>
                @text 'Run'
            @a href: '#', click: 'doStopExecution', \
                outlet: 'stopExecutionLink', =>
              @span class: 'text-error icon icon-primitive-square', =>
                @text 'Stop'
            @span class: 'text-subtle', \
                outlet: 'noExecutionModeAvailableInfo', =>
              @text '(no execution mode available)'

      @div class: 'terminal-container', outlet: 'terminalContainer'
      @div class: 'terminal-info', outlet: 'terminalInfo'

  ## Initialization and destruction --------------------------------------------

  initialize: ->
    @workspaceSubscrs = new CompositeDisposable
    @workspaceSubscrs.add workspace.onDidEnterWorkspace \
      (activeLevelCodeEditor) =>
        @updateOnDidEnterWorkspace(activeLevelCodeEditor)
    @workspaceSubscrs.add workspace.onDidExitWorkspace =>
        @updateOnDidExitWorkspace()
    @workspaceSubscrs.add workspace.onDidChangeActiveLanguage \
      ({activeLanguage}) =>
        @updateOnDidChangeActiveLanguageOfWorkspace(activeLanguage)
    @workspaceSubscrs.add workspace.onDidChangeActiveTerminal \
      (activeTerminal) =>
        @updateOnDidChangeActiveTerminalOfWorkspace(activeTerminal)

  destroy: ->
    @workspaceSubscrs.dispose()
    @hide()

  ## Resizing the terminal panel -----------------------------------------------

  resizeStarted: =>
    $(document).on('mousemove',@resize)
    $(document).on('mouseup',@resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove',@resize)
    $(document).off('mouseup',@resizeStopped)

  resize: ({pageY,which}) =>
    return @resizeStopped() unless which is 1
    controlBarHeight = @controlBar.outerHeight()
    newHeight = $(document.body).height() - pageY - controlBarHeight
    heightDiff = newHeight - @height()
    lineHeight = @activeTerminal.getLineHeight()
    sizeDiff = (heightDiff - (heightDiff % lineHeight)) / lineHeight
    if sizeDiff isnt 0
      size = @activeTerminal.getSize()
      @activeTerminal.setSize(size+sizeDiff)

  resizeToMinSize: =>
    @activeTerminal.setSize(terminalUtils.MIN_SIZE)

  ## Handling view events ------------------------------------------------------

  doShowTerminal: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:toggle-terminal')

  doHideTerminal: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:toggle-terminal')

  doClearTerminal: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:clear-terminal')

  doScrollTerminalToTop: ->
    @activeTerminal.scrollToTop()

  doScrollTerminalToBottom: ->
    @activeTerminal.scrollToBottom()

  doStartExecution: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:start-execution')

  doStopExecution: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:stop-execution')

  doSetCursorToExecutionIssuePorsition: (element) ->
    id = element.getAttribute('data-id')
    row = parseInt(element.getAttribute('data-row')) - 1
    col = parseInt(element.getAttribute('data-col') ? 0) - 1
    levelCodeEditor = workspace.getActiveLevelCodeEditor()
    if levelCodeEditor.getCurrentExecutionIssueById(id)
      textEditor = levelCodeEditor.getTextEditor()
      pos = textEditor.clipBufferPosition([row,col])
      atom.views.getView(textEditor).focus()
      textEditor.setCursorBufferPosition(pos)

  ## Updating the terminal panel's state ---------------------------------------

  updateOnDidEnterWorkspace: (activeLevelCodeEditor) ->
    @activeLanguage = activeLevelCodeEditor.getLanguage()
    @activeTerminal = activeLevelCodeEditor.getTerminal()
    @show()
    @updateOnDidChangeActiveLanguageOfWorkspace(@activeLanguage)
    @updateOnDidChangeActiveTerminalOfWorkspace(@activeTerminal)

  updateOnDidExitWorkspace: ->
    @hide()
    @activeTerminalSubscrs?.dispose()
    @activeLanguageSubscrs?.dispose()
    @activeTerminal = null
    @activeLanguage = null
    @fontSizeSelect.off()
    @off()

  updateOnDidChangeActiveLanguageOfWorkspace: (@activeLanguage) ->
    @activeLanguageSubscrs?.dispose()
    @activeLanguageSubscrs = new CompositeDisposable
    @activeLanguageSubscrs.add @activeLanguage.observe =>
      @updateOnDidChangeActiveLanguage()

  updateOnDidChangeActiveTerminalOfWorkspace: (@activeTerminal) ->
    @activeTerminalSubscrs?.dispose()
    @activeTerminalSubscrs = new CompositeDisposable
    @activeTerminalSubscrs.add @activeTerminal.observeIsVisible \
      (isVisible) =>
        @updateOnDidChangeIsVisibleOfActiveTerminal(isVisible)
    @activeTerminalSubscrs.add @activeTerminal.onDidChangeSize \
      (size) =>
        @updateOnDidChangeTerminalSize(size)
    @activeTerminalSubscrs.add @activeTerminal.observeFontSize \
      (fontSize) =>
        @updateOnDidChangeTerminalFontSize(fontSize)
    @activeTerminalSubscrs.add @activeTerminal.observeIsExecuting \
      (isExecuting) =>
        @updateOnDidChangeIsExecutingOfActiveTerminal(isExecuting)

    @terminalContainer.empty()
    @terminalContainer.append(atom.views.getView(@activeTerminal))

  updateOnDidChangeActiveLanguage: ->
    # update terminal panel for current execution mode
    unless @activeTerminal.isExecuting()
      if @activeLanguage.getExecutionMode()?
        @startExecutionLink.show()
        @stopExecutionLink.hide()
        @noExecutionModeAvailableInfo.hide()
      else
        @startExecutionLink.hide()
        @stopExecutionLink.hide()
        @noExecutionModeAvailableInfo.show()

  updateOnDidChangeIsVisibleOfActiveTerminal: (isVisible) ->
    if isVisible
      # update control bar elements
      @resizeHandle.show()
      @showTerminalLink.hide()
      @hideTerminalLink.show()
      @terminalControls.css('display','inline')
      # set up font size select handler
      @fontSizeSelect.off()
      @fontSizeSelect.change =>
        fontSize = parseInt(@fontSizeSelect.val())
        @activeTerminal.setFontSize(fontSize)
      # set up event handlers
      @off()
      @on 'mousedown', '.resize-handle', =>
        @resizeStarted()
      @on 'dblclick', '.resize-handle', =>
        @resizeToMinSize()
      @on 'keydown', (event) =>
        terminalUtils.dispatchKeyEvent(@activeTerminal,event)
      @on 'click', '.warning-link', (event) =>
        @doSetCursorToExecutionIssuePorsition(event.target)
      @on 'click', '.error-link', (event) =>
        @doSetCursorToExecutionIssuePorsition(event.target)
      @on 'focusin', =>
        @activeTerminal.didFocus()
      @on 'focusout', =>
        @activeTerminal.didBlur()
    else
      # update control bar elements
      @resizeHandle.hide()
      @showTerminalLink.show()
      @hideTerminalLink.hide()
      @terminalControls.hide()
      # remove font size selector handler
      @fontSizeSelect.off()
      # remove event handlers
      @off()

  updateOnDidChangeTerminalSize: (size) ->
    @terminalInfo.empty()
    @terminalInfo.append("Lines: #{size}")
    if @terminalInfo.is(':visible')
      @terminalInfo.stop(true)
      @terminalInfo.css('opacity',100)
    else
      @terminalInfo.show()
    @terminalInfo.fadeOut(1400)

  updateOnDidChangeTerminalFontSize: (currentFontSize) ->
    @fontSizeSelect.empty()
    for fontSize in terminalUtils.FONT_SIZES
      optionHtml = "<option value=\"#{fontSize}\""
      optionHtml += ' selected' if fontSize is currentFontSize
      optionHtml += ">#{fontSize}</option>"
      option = $(optionHtml)
      @fontSizeSelect.append(option)

  updateOnDidChangeIsExecutingOfActiveTerminal: (isExecuting) ->
    if isExecuting
      @startExecutionLink.hide()
      @stopExecutionLink.show()
      @noExecutionModeAvailableInfo.hide()
    else
      @stopExecutionLink.hide()
      if @activeLanguage.getExecutionMode()?
        @startExecutionLink.show()
        @noExecutionModeAvailableInfo.hide()
      else
        @startExecutionLink.hide()
        @noExecutionModeAvailableInfo.show()

  ## Showing and hiding the terminal panel -------------------------------------

  show: ->
    unless @bottomPanel?
      @bottomPanel = atom.workspace.addBottomPanel(item: @)

  hide: ->
    if @bottomPanel?
      @bottomPanel.destroy()
      @bottomPanel = null

# ------------------------------------------------------------------------------
