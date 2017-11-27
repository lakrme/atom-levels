{CompositeDisposable} = require 'atom'
terminalUtils         = require './terminal-utils'
workspace             = require './workspace'

module.exports =
class TerminalPanelView
  constructor: ->
    @element = document.createElement 'div'
    @element.className = 'levels-view terminal-panel'
    @element.tabIndex = 0

    @resizeHandle = document.createElement 'div'
    @resizeHandle.className = 'resize-handle'
    @element.appendChild @resizeHandle

    @controlBar = document.createElement 'div'
    @controlBar.className = 'control-bar'
    @element.appendChild @controlBar

    @terminalContainer = document.createElement 'div'
    @terminalContainer.className = 'terminal-container'
    @element.appendChild @terminalContainer

    @terminalInfo = document.createElement 'div'
    @terminalInfo.className = 'terminal-info'
    @element.appendChild @terminalInfo

    cbl = document.createElement 'div'
    cbl.className = 'control-bar-left'
    @controlBar.appendChild cbl

    cbr = document.createElement 'div'
    cbr.className = 'control-bar-right'
    @controlBar.appendChild cbr

    @executionControls = document.createElement 'div'
    @executionControls.className = 'control-group execution-controls'
    cbr.appendChild @executionControls

    @startExecutionLink = document.createElement 'a'
    @startExecutionLink.href = '#'
    @startExecutionLink.addEventListener 'click', => @doStartExecution()
    @executionControls.appendChild @startExecutionLink
    startExecutionLinkSpan = document.createElement 'span'
    startExecutionLinkSpan.className = 'text-success icon icon-playback-play'
    startExecutionLinkSpan.textContent = 'Run'
    @startExecutionLink.appendChild startExecutionLinkSpan

    @stopExecutionLink = document.createElement 'a'
    @stopExecutionLink.href = '#'
    @stopExecutionLink.addEventListener 'click', => @doStopExecution()
    @executionControls.appendChild @stopExecutionLink
    stopExecutionLinkSpan = document.createElement 'span'
    stopExecutionLinkSpan.className = 'text-error icon icon-primitive-square'
    stopExecutionLinkSpan.textContent = 'Stop'
    @stopExecutionLink.appendChild stopExecutionLinkSpan

    @noExecutionModeAvailableInfo = document.createElement 'span'
    @noExecutionModeAvailableInfo.className = 'text-subtle'
    @noExecutionModeAvailableInfo.textContent = '(no execution mode available)'
    @executionControls.appendChild @noExecutionModeAvailableInfo

    cg = document.createElement 'div'
    cg.className = 'control-group'
    cbl.appendChild cg

    ce = document.createElement 'div'
    ce.className = 'control-element'
    cg.appendChild ce

    @showTerminalLink = document.createElement 'a'
    @showTerminalLink.href = '#'
    @showTerminalLink.addEventListener 'click', => @doShowTerminal()
    ce.appendChild @showTerminalLink
    showTerminalLinkSpan = document.createElement 'span'
    showTerminalLinkSpan.className = 'icon icon-triangle-up'
    showTerminalLinkSpan.textContent = 'Show Terminal'
    @showTerminalLink.appendChild showTerminalLinkSpan

    ce = document.createElement 'div'
    ce.className = 'control-element'
    cg.appendChild ce

    @hideTerminalLink = document.createElement 'a'
    @hideTerminalLink.href = '#'
    @hideTerminalLink.addEventListener 'click', => @doHideTerminal()
    ce.appendChild @hideTerminalLink
    hideTerminalLinkSpan = document.createElement 'span'
    hideTerminalLinkSpan.className = 'icon icon-triangle-down'
    hideTerminalLinkSpan.textContent = 'Hide Terminal'
    @hideTerminalLink.appendChild hideTerminalLinkSpan

    @terminalControls = document.createElement 'div'
    @terminalControls.className = 'control-group terminal-controls'
    cbl.appendChild @terminalControls

    cbs = document.createElement 'div'
    cbs.className = 'control-bar-separator'
    @terminalControls.appendChild cbs

    ce = document.createElement 'div'
    ce.className = 'control-element'
    @terminalControls.appendChild ce

    clearTerminalLink = document.createElement 'a'
    clearTerminalLink.href = '#'
    clearTerminalLink.addEventListener 'click', => @doClearTerminal()
    ce.appendChild clearTerminalLink
    clearTerminalLinkSpan = document.createElement 'span'
    clearTerminalLinkSpan.className = 'icon icon-x'
    clearTerminalLinkSpan.textContent = 'Clear'
    clearTerminalLink.appendChild clearTerminalLinkSpan

    ce = document.createElement 'div'
    ce.className = 'control-element'
    @terminalControls.appendChild ce

    scrollTopLink = document.createElement 'a'
    scrollTopLink.href = '#'
    scrollTopLink.addEventListener 'click', => @doScrollTerminalToTop()
    ce.appendChild scrollTopLink
    scrollTopLinkSpan = document.createElement 'span'
    scrollTopLinkSpan.className = 'icon icon-move-up'
    scrollTopLinkSpan.textContent = 'Scroll To Top'
    scrollTopLink.appendChild scrollTopLinkSpan

    ce = document.createElement 'div'
    ce.className = 'control-element'
    @terminalControls.appendChild ce

    scrollBottomLink = document.createElement 'a'
    scrollBottomLink.href = '#'
    scrollBottomLink.addEventListener 'click', => @doScrollTerminalToBottom()
    ce.appendChild scrollBottomLink
    scrollBottomLinkSpan = document.createElement 'span'
    scrollBottomLinkSpan.className = 'icon icon-move-down'
    scrollBottomLinkSpan.textContent = 'Scroll To Bottom'
    scrollBottomLink.appendChild scrollBottomLinkSpan

    cbs = document.createElement 'div'
    cbs.className = 'control-bar-separator'
    @terminalControls.appendChild cbs

    ce = document.createElement 'div'
    ce.className = 'control-element'
    @terminalControls.appendChild ce

    fontSizeLinkSpan = document.createElement 'span'
    fontSizeLinkSpan.className = 'icon icon-mention'
    fontSizeLinkSpan.textContent = 'Font Size:'
    ce.appendChild fontSizeLinkSpan

    @fontSizeSelect = document.createElement 'select'
    @fontSizeSelect.className = 'font-size-select'
    ce.appendChild @fontSizeSelect

    @workspaceSubscrs = new CompositeDisposable()
    @workspaceSubscrs.add workspace.onDidEnterWorkspace (activeLevelCodeEditor) => @updateOnDidEnterWorkspace(activeLevelCodeEditor)
    @workspaceSubscrs.add workspace.onDidExitWorkspace => @updateOnDidExitWorkspace()
    @workspaceSubscrs.add workspace.onDidChangeActiveLanguage ({activeLanguage}) => @updateOnDidChangeActiveLanguageOfWorkspace(activeLanguage)
    @workspaceSubscrs.add workspace.onDidChangeActiveTerminal (activeTerminal) => @updateOnDidChangeActiveTerminalOfWorkspace(activeTerminal)

  destroy: ->
    @workspaceSubscrs.dispose()
    @hide()

  resizeStarted: =>
    document.addEventListener 'mousemove', @resize
    document.addEventListener 'mouseup', @resizeStopped

  resizeStopped: =>
    document.removeEventListener 'mousemove', @resize
    document.removeEventListener 'mouseup', @resizeStopped

  resize: ({pageY, which}) =>
    return @resizeStopped() unless which is 1
    controlBarHeight = @controlBar.offsetHeight
    newHeight = document.body.clientHeight - pageY - controlBarHeight
    heightDiff = newHeight - @element.clientHeight
    lineHeight = @activeTerminal.getLineHeight()
    sizeDiff = (heightDiff - (heightDiff % lineHeight)) / lineHeight
    if sizeDiff isnt 0
      size = @activeTerminal.getSize()
      @activeTerminal.setSize(size+sizeDiff)

  resizeToMinSize: =>
    @activeTerminal.setSize(terminalUtils.MIN_SIZE)

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
    @fontSizeSelect.removeEventListener 'change', @onDidChangeFontSize
    # TODO: @off()

  updateOnDidChangeActiveLanguageOfWorkspace: (@activeLanguage) ->
    @activeLanguageSubscrs?.dispose()
    @activeLanguageSubscrs = new CompositeDisposable()
    @activeLanguageSubscrs.add @activeLanguage.observe => @updateOnDidChangeActiveLanguage()

  updateOnDidChangeActiveTerminalOfWorkspace: (@activeTerminal) ->
    @activeTerminalSubscrs?.dispose()
    @activeTerminalSubscrs = new CompositeDisposable()
    @activeTerminalSubscrs.add @activeTerminal.observeIsVisible (isVisible) => @updateOnDidChangeIsVisibleOfActiveTerminal(isVisible)
    @activeTerminalSubscrs.add @activeTerminal.onDidChangeSize (size) => @updateOnDidChangeTerminalSize(size)
    @activeTerminalSubscrs.add @activeTerminal.observeFontSize (fontSize) => @updateOnDidChangeTerminalFontSize(fontSize)
    @activeTerminalSubscrs.add @activeTerminal.observeIsExecuting (isExecuting) => @updateOnDidChangeIsExecutingOfActiveTerminal(isExecuting)

    @terminalContainer.innerHTML = ''
    @terminalContainer.appendChild(atom.views.getView(@activeTerminal))

  updateOnDidChangeActiveLanguage: ->
    # update terminal panel for current execution mode
    unless @activeTerminal.isExecuting()
      if @activeLanguage.isExecutable()
        @startExecutionLink.style.display = ''
        @stopExecutionLink.style.display = 'none'
        @noExecutionModeAvailableInfo.style.display = 'none'
      else
        @startExecutionLink.style.display = 'none'
        @stopExecutionLink.style.display = 'none'
        @noExecutionModeAvailableInfo.style.display = ''

  onDidChangeFontSize: =>
    fontSize = parseInt(@fontSizeSelect.value)
    @activeTerminal.setFontSize(fontSize)

  updateOnDidChangeIsVisibleOfActiveTerminal: (isVisible) ->
    if isVisible
      # update control bar elements
      @resizeHandle.style.display = ''
      @showTerminalLink.style.display = 'none'
      @hideTerminalLink.style.display = ''
      @terminalControls.style.display = 'inline'
      # set up font size select handler
      @fontSizeSelect.removeEventListener 'change', @onDidChangeFontSize
      @fontSizeSelect.addEventListener 'change', @onDidChangeFontSize
      # set up event handlers
      # TODO: @off()
      @resizeHandle.addEventListener 'mousedown', => @resizeStarted()
      @resizeHandle.addEventListener 'dblclick', => @resizeToMinSize()
      @element.addEventListener 'keydown', (event) => @dispatchKeyEvent(event)

      # TODO
      # @on 'click', '.warning-link', (event) =>
      #   @doSetCursorToExecutionIssuePorsition(event.target)
      # @on 'click', '.error-link', (event) =>
      #  @doSetCursorToExecutionIssuePorsition(event.target)
      @element.addEventListener 'focusin', => @activeTerminal.didFocus()
      @element.addEventListener 'focusout', => @activeTerminal.didBlur()
    else
      # update control bar elements
      @resizeHandle.style.display = 'none'
      @showTerminalLink.style.display = ''
      @hideTerminalLink.style.display = 'none'
      @terminalControls.style.display = 'none'
      # remove font size selector handler
      @fontSizeSelect.removeEventListener 'change', @onDidChangeFontSize
      # remove event handlers
      # TODO: @off()

  updateOnDidChangeTerminalSize: (size) ->
    @terminalInfo.innerHTML = "Lines: #{size}"
    @terminalInfo.style.display = 'block'
    if @terminalInfo.style.opacity > 0
      clearInterval @interval
      @interval = null
      @terminalInfo.style.opacity = 1
    else
      @terminalInfo.style.opacity = 1
 
    @interval ?= setInterval () =>
      if @terminalInfo.style.opacity > 0
        @terminalInfo.style.opacity -= 0.01
      else
        clearInterval @interval
        @interval = null
        @terminalInfo.style.display = 'none'
    , 14

  updateOnDidChangeTerminalFontSize: (currentFontSize) ->
    @fontSizeSelect.innerHTML = ''
    for fontSize in terminalUtils.FONT_SIZES
      optionHtml = "<option value=\"#{fontSize}\""
      optionHtml += ' selected' if fontSize is currentFontSize
      optionHtml += ">#{fontSize}</option>"
      @fontSizeSelect.innerHTML += optionHtml

  updateOnDidChangeIsExecutingOfActiveTerminal: (isExecuting) ->
    if isExecuting
      @startExecutionLink.style.display = 'none'
      @stopExecutionLink.style.display = ''
      @noExecutionModeAvailableInfo.style.display = 'none'
    else
      @stopExecutionLink.style.display = 'none'
      if @activeLanguage.isExecutable()
        @startExecutionLink.style.display = ''
        @noExecutionModeAvailableInfo.style.display = 'none'
      else
        @startExecutionLink.style.display = 'none'
        @noExecutionModeAvailableInfo.style.display = ''

  show: ->
    unless @bottomPanel?
      @bottomPanel = atom.workspace.addBottomPanel(item: @)

  hide: ->
    if @bottomPanel?
      @bottomPanel.destroy()
      @bottomPanel = null

  dispatchKeyEvent: (event) ->
    buffer = @activeTerminal.getBuffer()
    keystroke = atom.keymaps.keystrokeForKeyboardEvent event
    keystrokeParts = if keystroke == '-' then ['-'] else keystroke.split '-'

    switch keystrokeParts.length
      when 1
        switch firstPart = keystrokeParts[0]
          when 'enter'     then buffer.enterInput()
          when 'backspace' then buffer.removeCharFromInput()
          when 'up'        then buffer.showPreviousInput()
          when 'left'      then buffer.moveInputCursorLeft()
          when 'down'      then buffer.showSubsequentInput()
          when 'right'     then buffer.moveInputCursorRight()
          when 'space'     then buffer.addStringToInput ' '
          else
            if firstPart.length == 1
              buffer.addStringToInput firstPart
      when 2
        switch keystrokeParts[0]
          when 'shift'
            secondPart = keystrokeParts[1]
            if secondPart.length == 1
              buffer.addStringToInput secondPart

    return