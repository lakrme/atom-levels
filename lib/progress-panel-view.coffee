{$,View}  = require('atom-space-pen-views')

# ------------------------------------------------------------------------------

module.exports =
class ProgressPanelView extends View

  @content: (_,{title}) ->
    @div class: 'levels-view panel progress-panel', =>
      @div class: 'title', =>
        @text title if title?
      @tag 'progress', class: 'progress-bar', outlet: 'progressBar'
      @div class: 'info', outlet: 'info', =>
        @text 'Preparing...'
      @div class: 'issue-log-container', =>
        @div class: 'issue-count', outlet: 'issueCount', =>
          @text '0 Warning(s), 0 Error(s)'
        @div class: 'issue-log', outlet: 'issueLog'
      @div class: 'controls', outlet: 'controls', =>
        @button class: 'btn pull-right', click: 'handleDidClickCloseButton', =>
          @text 'Close'

  ## Initialization ------------------------------------------------------------

  initialize: (@progressEmitter,options={}) ->
    # initialize parameters
    @onDidOpen = ->
      options.onDidOpen?()
      @progressEmitter.start()
    @onDidClose = options.onDidClose
    @closeOnSuccess = options.closeOnSuccess ? true

    # initialize issue counters
    @warningCount = 0
    @errorCount = 0

    # set up progress emitter event handlers
    @progressEmitter.setUp
      emitProgress: @updateOnDidEmitProgress
      emitWarning: @updateOnDidEmitWarning
      emitError: @updateOnDidEmitError

    # open progress panel
    @open()

  ## Updating the progress panel -----------------------------------------------

  updateOnDidEmitProgress: ({value,info}) =>
    # update progress value
    if 0 <= value <= 100
      @progressBar.attr('max','100')
      @progressBar.attr('value',"#{value}")

    # update info
    @info.empty()
    @info.append(info)

    # stop progressing if done
    @done() if value is 100

  updateOnDidEmitWarning: (message) =>
    @warningCount++
    @issueCount.text("#{@warningCount} Warning(s), #{@errorCount} Error(s)")
    warning = $('<span class="text text-warning"></span>')
    warning.append("Warning: #{message}")
    @issueLog.append(warning)
    @issueLog.scrollTop(@issueLog[0].scrollHeight)

  updateOnDidEmitError: (message) =>
    @errorCount++
    @issueCount.text("#{@warningCount} Warning(s), #{@errorCount} Error(s)")
    error = $('<span class="text text-error"></span>')
    error.append("Error: #{message}")
    @issueLog.append(error)
    @issueLog.scrollTop(@issueLog[0].scrollHeight)
    @done()

  done: ->
    @progressEmitter.stop()
    if not @closeOnSuccess or @warningCount > 0 or @errorCount > 0
      @controls.css({visibility: 'visible'})
    else
      @close()

  ## Handling view events ------------------------------------------------------

  handleDidClickCloseButton: ->
    @close()

  ## Opening and closing the progress panel ------------------------------------

  open: ->
    @topPanel = atom.workspace.addTopPanel({item: @})
    outerHeight = @outerHeight()
    @css({top: "-#{outerHeight}px"})
    @animate {top: '-1px'}, 'fast', =>
      @onDidOpen()

  close: ->
    outerHeight = @outerHeight()
    @animate {top: "-#{outerHeight}px"}, 'fast', =>
      @topPanel.destroy()
      @topPanel = null
      @onDidClose?()

# ------------------------------------------------------------------------------
