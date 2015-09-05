{Emitter} = require('atom')
{$,View}  = require('atom-space-pen-views')

# ------------------------------------------------------------------------------

module.exports =
class ProgressPanelView extends View

  @content: ->
    @div class: 'levels-view progress-panel', =>
      @div class: 'headline', outlet: 'headline', =>
        @text '(No headline given)'
      @tag 'progress', class: 'inline-block', \
          outlet: 'progressBar'
      @div outlet: 'info', =>
        @text '(No info given)'
      @div class: 'issue-log-container', =>
        @div class: 'issue-count', outlet: 'issueCount', =>
          @text '0 Warnings, 0 Errors'
        @div class: 'issue-log', outlet: 'issueLog'
      @div class: 'controls', outlet: 'controls', =>
        @button class: 'btn pull-right', \
            click: 'handleDidClickCloseButton', \
            outlet: 'closeButton', =>
          @text 'Close'

  ## Initialization ------------------------------------------------------------

  initialize: ->
    @emitter = new Emitter
    @warningCount = 0
    @errorCount = 0

  ## Event subscription --------------------------------------------------------

  onDidShow: (callback) ->
    @emitter.on('did-show',callback)

  onDidHide: (callback) ->
    @emitter.on('did-hide',callback)

  ## Controlling the progress panel --------------------------------------------

  update: ({headline,progress,info}) ->
    @updateHeadline(headline) if headline?
    @updateProgress(progress) if progress?
    @updateInfo(info) if info?

  updateHeadline: (headline) ->
    @headline.empty()
    @headline.append(headline)

  updateProgress: (value) ->
    if 0 <= value <= 100
      @progressBar.attr('max','100')
      @progressBar.attr('value',"#{value}")
      @done() if value is 100

  updateInfo: (info) ->
    @info.empty()
    @info.append(info)

  addWarning: (warningMsg) ->
    @warningCount++
    @issueCount.text("#{@warningCount} Warnings, #{@errorCount} Errors")
    warning = $("<span class=\"text text-warning\"></span>")
    warning.append("Warning: #{warningMsg}")
    @issueLog.append(warning)
    @issueLog.scrollTop(@issueLog[0].scrollHeight)

  addError: (errorMsg) ->
    @errorCount++
    @issueCount.text("#{@warningCount} Warnings, #{@errorCount} Errors")
    error = $("<span class=\"text text-error\">Error: #{errorMsg}</span>")
    @issueLog.append(error)
    @issueLog.scrollTop(@issueLog[0].scrollHeight)

  clearIssueLog: ->
    @warningCount = 0
    @errorCount = 0
    @issueCount.text("#{@warningCount} Warnings, #{@errorCount} Errors")
    @issueLog.empty()

  reset: ->
    @update
      headline: '(No headline given)'
      info: '(No info given)'
    @progressBar.removeAttr('max')
    @progressBar.removeAttr('value')
    @clearIssueLog()

  done: ->
    if @warningCount > 0 or @errorCount > 0
      @controls.css({visibility: 'visible'})
    else
      @hide()

  ## Handling view events ------------------------------------------------------

  handleDidClickCloseButton: ->
    @hide()

  ## Opening and closing the progress panel ------------------------------------

  show: (callback) ->
    # @closeButton.css('visiblity','hidden')
    outerHeight = @outerHeight()
    @css({display: 'block',top: "-#{outerHeight+1}px"})
    @controls.css({visibility: 'hidden'})
    @animate {top: '-1px'}, 'fast', =>
      @emitter.emit('did-show')
      callback() if callback?

  hide: ->
    outerHeight = @outerHeight()
    @animate {top: "-#{outerHeight+1}px"}, 'fast', =>
      @reset()
      @css({display: 'none'})
      @emitter.emit('did-hide')

# ------------------------------------------------------------------------------
