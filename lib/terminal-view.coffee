{View} = require('atom-space-pen-views')

# ------------------------------------------------------------------------------

module.exports =
class TerminalView extends View

  @content: ->
    @div class: 'terminal', tabindex: 0, =>
      @div class: 'cursor', outlet: 'cursor', =>
        @raw '&nbsp;'

  ## Initialization ------------------------------------------------------------

  initialize: (@terminal) ->
    @terminal.onDidShow => @show()
    @terminal.onDidHide => @hide()
    @terminal.onDidChangeSize (rows) => @setSize(rows)
    @terminal.onDidFocus => @focus()
    @terminal.onDidScrollToTop => @scrollToTop()
    @terminal.onDidScrollToBottom => @scrollToBottom()

    @setSize(@terminal.getSize())

    @cursor.css('height',@terminal.getLineHeight())
    @cursor.css('width',@terminal.getCharWidth())

    @append("njhkjhkh")

  ## Activation and deactivation -----------------------------------------------

  setSize: (rows) ->
    @height(rows*@terminal.getLineHeight())

  #   @terminal.onDidCreateNewActiveLine =>
  #     @createNewActiveLine()
  #
  #   @terminal.onDidUpdateActiveLine (activeLineState) =>
  #     @updateActiveLine(activeLineState)
  #
  # ## Managing
  #
  # @updateActiveLine: ({input,output,inputCursorPos}) ->
  #   @activeLine.empty()
  #   @activeLine.text(output+input)
  #   @moveCursorAbsoluteInRow(output.length+inputCursorPos)
  #   # @scrollToBottom()
  #

# ------------------------------------------------------------------------------
