{CompositeDisposable} = require('atom')
{$,View}              = require('atom-space-pen-views')

# ------------------------------------------------------------------------------

module.exports =
class TerminalView extends View

  @content: ->
    @div class: 'terminal', tabindex: 0, =>
      @div class: 'cursor', outlet: 'cursor', =>
        @raw '&nbsp;'

  ## Initialization ------------------------------------------------------------

  initialize: (@terminal) ->
    @lineHeight = @terminal.getLineHeight()
    @charWidth = @terminal.getCharWidth()
    @cursorRowIndex = 0
    @cursorColIndex = 0
    @activeLineIndex = -1

    @terminalSubscrs = new CompositeDisposable
    @terminalSubscrs.add @terminal.observeIsVisible (isVisible) =>
      @updateOnDidChangeIsVisible(isVisible)
    @terminalSubscrs.add @terminal.observeSize (size) =>
      @updateOnDidChangeSize(size)
    @terminalSubscrs.add @terminal.observeFontSize (fontSize) =>
      @updateOnDidChangeFontSize(fontSize)
    @terminalSubscrs.add @terminal.onDidScrollToTop =>
      @scrollToTop()
    @terminalSubscrs.add @terminal.onDidScrollToBottom =>
      @scrollToBottom()
    @terminalSubscrs.add @terminal.onDidCreateNewLine =>
      @updateOnDidCreateNewLine()
    @terminalSubscrs.add @terminal.onDidUpdateActiveLine (activeLine) =>
      @updateOnDidUpdateActiveLine(activeLine)
    @terminalSubscrs.add @terminal.onDidClear =>
      @updateOnDidClear()

  updateActiveLine: ({input,output,inputCursorPos}) ->
    @activeLine.empty()
    @activeLine.text(output+input)
    @moveCursorAbsoluteInRow(output.length+inputCursorPos)

  ## Moving the cursor -------------------------------------------------------

  moveCursorAbsolute: (rowIndex,colIndex) ->
    @moveCursorAbsoluteInRow(colIndex)
    @moveCursorAbsoluteInCol(rowIndex)

  moveCursorAbsoluteInRow: (@cursorColIndex) ->
    left = @cursorColIndex * @charWidth
    @cursor.css('left',left)

  moveCursorAbsoluteInCol: (@cursorRowIndex) ->
    top = @cursorRowIndex * @lineHeight
    @cursor.css('top',top)

  moveCursorRelative: (rowOffset,colOffset) ->
    @moveCursorRelativeInRow(colOffset)
    @moveCursorRelativeInCol(rowOffset)

  moveCursorRelativeInRow: (colOffset) ->
    @cursorColIndex + colOffset
    leftOffset = colOffset * @charWidth
    @cursor.css('left',parseInt(@cursor.css('left'))+leftOffset)

  moveCursorRelativeInCol: (rowOffset) ->
    @cursorRowIndex + rowOffset
    topOffset = rowOffset * @lineHeight
    @cursor.css('top',parseInt(@cursor.css('top'))+topOffset)

  ## Updating this view --------------------------------------------------------

  updateOnDidChangeIsVisible: (@isVisible) ->
    if @isVisible then @show() else @hide()

  updateOnDidChangeSize: (@size) ->
    @height(@size*@lineHeight)

  updateOnDidChangeFontSize: (@fontSize) ->
    @lineHeight = @terminal.getLineHeight()
    @charWidth = @terminal.getCharWidth()
    @css('font-size',"#{@fontSize}px")
    @css('line-height',"#{@lineHeight}px")
    @height(@size*@lineHeight)

    # update the cursor
    @cursor.css('height',"#{@lineHeight}px")
    @cursor.css('width',"#{@charWidth}px")
    @moveCursorAbsolute(@cursorRowIndex,@cursorColIndex)

  updateOnDidCreateNewLine: ->
    @activeLine = $(document.createElement('div'))
    @activeLine.addClass('line')
    @append(@activeLine)
    @activeLineIndex++
    @moveCursorAbsolute(@activeLineIndex,0)
    @scrollToBottom()

  updateOnDidUpdateActiveLine: ({input,output,inputCursorPos}) ->
    @activeLine.empty()
    @activeLine.text(output+input)
    @moveCursorAbsoluteInRow(output.length+inputCursorPos)

  updateOnDidClear: ->
    @empty()
    @append(@cursor)
    @append(@activeLine)
    @moveCursorRelative(-@activeLineIndex,0)
    @activeLineIndex = 0

# ------------------------------------------------------------------------------
