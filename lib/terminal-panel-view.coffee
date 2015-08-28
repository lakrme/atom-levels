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
            @a href: '#', click: 'doShowTerminal', \
                outlet: 'showTerminalLink', =>
              @span class: 'icon icon-triangle-up', =>
                @text 'Show Terminal'
            @a href: '#', click: 'doHideTerminal', \
                outlet: 'hideTerminalLink', =>
              @span class: 'icon icon-triangle-down', =>
                @text 'Hide Terminal'

          @div class: 'control-bar-separator', outlet: 'separatorLeft'

          @div class: 'control-group terminal-controls', \
               outlet: 'terminalControls', =>
            @a href: '#', click: 'doClearTerminal', =>
              @span class: 'icon icon-x', =>
                @text 'Clear'
            @a href: '#', click: 'doScrollTerminalToTop', =>
              @span class: 'icon icon-move-up', =>
                @text 'To Top'
            @a href: '#', click: 'doScrollTerminalToBottom', =>
              @span class: 'icon icon-move-down', =>
                @text 'To Bottom'
            # @a href: '#', click: 'doIncreaseTerminalFontSize', =>
            #   @span class: 'icon icon-diff-added'
            # @a href: '#', click: 'doDecreaseTerminalFontSize', =>
            #   @span class: 'icon icon-diff-removed'

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

          @div class: 'control-bar-separator', outlet: 'separatorRight'

          @div class: 'control-group', =>
            @a href: '#', click: 'test', =>
              @span class: 'icon icon-gear', =>
                @text 'Language Configuration'

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
    @activeTerminal.show()

  doHideTerminal: ->
    @activeTerminal.hide()

  doClearTerminal: ->
    @activeTerminal.clear()

  doScrollTerminalToTop: ->
    @activeTerminal.scrollToTop()

  doScrollTerminalToBottom: ->
    @activeTerminal.scrollToBottom()

  doIncreaseTerminalFontSize: ->
    @activeTerminal.increaseFontSize()

  doDecreaseTerminalFontSize: ->
    @activeTerminal.decreaseFontSize()

  doStartExecution: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:start-execution')

  doStopExecution: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:stop-execution')

  test: ->
    @activeTerminal.writeSuccess
      head: "hallo"
      body: "tschüß"

  ## Updating the terminal panel's state ---------------------------------------

  updateOnDidEnterWorkspace: (activeLevelCodeEditor) ->
    @activeLanguage = activeLevelCodeEditor.getLanguage()
    @activeTerminal = activeLevelCodeEditor.getTerminal()
    @show()
    @updateOnDidChangeActiveLanguageOfWorkspace(@activeLanguage)
    @updateOnDidChangeActiveTerminalOfWorkspace(@activeTerminal)

    # set up window event handlers
    @on 'mousedown', '.resize-handle', => @resizeStarted()
    @on 'dblclick', '.resize-handle', => @resizeToMinSize()

  updateOnDidExitWorkspace: ->
    @hide()
    @activeTerminalSubscrs.dispose()
    @activeLanguageSubscrs.dispose()
    @activeTerminal = null
    @activeLanguage = null

    # remove event handlers
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
    # @activeTerminalSubscrs.add @activeTerminal.onDidChangeSize \
    #   (size) => @updateOnDidChangePropertyOfActiveTerminal
    #     name: 'Size'
    #     value: size
    # @activeTerminalSubscrs.add @activeTerminal.onDidChangeFontSize \
    #   (fontSize) => @updateOnDidChangePropertyOfActiveTerminal
    #     name: 'Font size'
    #     value: fontSize
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
      # update control bar element
      @resizeHandle.show()
      @showTerminalLink.hide()
      @hideTerminalLink.show()
      @separatorLeft.css('display','inline')
      @terminalControls.css('display','inline')
      # add terminal event handlers
      @off('keydown')
      @on 'keydown', (event) =>
        terminalUtils.dispatchKeyEvent(@activeTerminal,event)
    else
      # update control bar elements
      @resizeHandle.hide()
      @showTerminalLink.show()
      @hideTerminalLink.hide()
      @separatorLeft.hide()
      @terminalControls.hide()
      # remove terminal event handlers
      @off('keydown')

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

  # updateOnDidChangePropertyOfActiveTerminal: ({name,value}) ->
  #   @terminalInfo.empty()
  #   @terminalInfo.append("#{name}: #{value}")
  #   if @terminalInfo.is(':visible')
  #     @terminalInfo.stop(true)
  #     @terminalInfo.css('opacity',100)
  #   else
  #     @terminalInfo.show()
  #   @terminalInfo.fadeOut(1000)

  ## Showing and hiding the terminal panel -------------------------------------

  show: ->
    unless @bottomPanel?
      @bottomPanel = atom.workspace.addBottomPanel(item: @)

  hide: ->
    if @bottomPanel?
      @bottomPanel.destroy()
      @bottomPanel = null

# ------------------------------------------------------------------------------
