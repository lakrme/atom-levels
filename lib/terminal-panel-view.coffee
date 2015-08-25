{CompositeDisposable} = require('atom')
{$,View}              = require('atom-space-pen-views')

workspace             = require('./workspace').getInstance()

# ------------------------------------------------------------------------------

module.exports =
class TerminalPanelView extends View

  @content: ->
    @div class: 'levels-view terminal-panel', =>
      @div class: 'resize-handle', outlet: 'resizeHandle'
      @div class: 'control-bar', tabindex: 0, outlet: 'controlBar', =>

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
            @a href: '#', click: 'doScrollToTopOfTerminal', =>
              @span class: 'icon icon-move-up', =>
                @text 'Scroll To Top'
            @a href: '#', click: 'doScrollToBottomOfTerminal', =>
              @span class: 'icon icon-move-down', =>
                @text 'Scroll To Bottom'

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
            @a href: '#', =>
              @span class: 'icon icon-gear', =>
                @text 'Language Configuration'

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
      @activeTerminal.setSize(@activeTerminal.getSize()+sizeDiff)

  resizeToMinSize: =>
    minSize = @activeTerminal.getMinSize()
    @activeTerminal.setSize(minSize)

  ## Handling view events ------------------------------------------------------

  doShowTerminal: ->
    @activeTerminal.show()

  doHideTerminal: ->
    @activeTerminal.hide()

  doClearTerminal: ->
    @activeTerminal.clear()

  doScrollToTopOfTerminal: ->
    @activeTerminal.scrollToTop()

  doScrollToBottomOfTerminal: ->
    @activeTerminal.scrollToBottom()

  doStartExecution: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:start-execution')

  doStopExecution: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:stop-execution')

  ## Updating the terminal panel's state ---------------------------------------

  updateOnDidEnterWorkspace: (activeLevelCodeEditor) ->
    @activeLanguage = activeLevelCodeEditor.getLanguage()
    @activeTerminal = activeLevelCodeEditor.getTerminal()
    @updateOnDidChangeActiveLanguageOfWorkspace(@activeLanguage)
    @updateOnDidChangeActiveTerminalOfWorkspace(@activeTerminal)
    @show()

  updateOnDidExitWorkspace: ->
    @hide()
    @activeTerminalSubscrs.dispose()
    @activeLanguageSubscrs.dispose()
    @activeTerminal = null
    @activeLanguage = null

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
    @activeTerminalSubscrs.add @activeTerminal.observeIsExecuting \
      (isExecuting) =>
        @updateOnDidChangeIsExecutingOfActiveTerminal(isExecuting)

    lastChild = @children().last()
    lastChild.remove() if lastChild.hasClass('terminal')
    @append(atom.views.getView(@activeTerminal))

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
      @resizeHandle.show()
      @showTerminalLink.hide()
      @hideTerminalLink.show()
      @separatorLeft.css('display','inline')
      @terminalControls.css('display','inline')
    else
      @resizeHandle.hide()
      @showTerminalLink.show()
      @hideTerminalLink.hide()
      @separatorLeft.hide()
      @terminalControls.hide()

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

      # set up window event handlers
      @on 'mousedown', '.resize-handle', => @resizeStarted()
      @on 'dblclick', '.resize-handle', => @resizeToMinSize()

  hide: ->
    if @bottomPanel?
      @bottomPanel.destroy()
      @bottomPanel = null
      @off()

# ------------------------------------------------------------------------------
