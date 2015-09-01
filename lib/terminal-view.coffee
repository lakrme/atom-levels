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
    @waitingForTypedMessage = false

    @terminalSubscrs = new CompositeDisposable
    @terminalSubscrs.add @terminal.observeIsVisible (isVisible) =>
      @updateOnDidChangeIsVisible(isVisible)
    @terminalSubscrs.add @terminal.observeSize (size) =>
      @updateOnDidChangeSize(size)
    @terminalSubscrs.add @terminal.observeFontSize (fontSize) =>
      @updateOnDidChangeFontSize(fontSize)
    @terminalSubscrs.add @terminal.onDidFocus =>
      @activeLine.focus()
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
    @terminalSubscrs.add @terminal.onDidStartReadingTypedMessage =>
      @didStartReadingTypedMessage()
    @terminalSubscrs.add @terminal.onDidReadTypedMessage (typedMessage) =>
      @didReadTypedMessage(typedMessage)

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

    # update the icon size
    icons = $('.icon:before')
    icons.css('font-size',"#{@fontSize}px")
    icons.css('height',"#{@fontSize}px")
    icons.css('width',"#{@fontSize}px")

    # update the cursor
    @cursor.css('height',"#{@lineHeight}px")
    @cursor.css('width',"#{@charWidth}px")
    @moveCursorAbsolute(@cursorRowIndex,@cursorColIndex)

  updateOnDidCreateNewLine: ->
    unless @waitingForTypedMessage
      @activeLine = $('<div class="line" tabindex="0">&nbsp;</div>')
      @append(@activeLine)
      @activeLineIndex++
      @moveCursorAbsolute(@activeLineIndex,0)
      @scrollToBottom()

  updateOnDidUpdateActiveLine: ({input,output,inputCursorPos}) ->
    unless @waitingForTypedMessage
      @activeLine.empty()
      @activeLine.text(output+input)
      @activeLine.append('&nbsp;')
      @moveCursorAbsoluteInRow(output.length+inputCursorPos)

  updateOnDidClear: ->
    @empty()
    @append(@cursor)
    @append(@activeLine)
    @moveCursorRelative(-@activeLineIndex,0)
    @activeLineIndex = 0

  ## Processing typed messages -------------------------------------------------

  didStartReadingTypedMessage: ->
    @waitingForTypedMessage = true

  didReadTypedMessage: (typedMessage) ->
    @waitingForTypedMessage = false
    @putTypedMessage(typedMessage)

  putTypedMessage: (typedMessage) ->
    headLines = typedMessage.head.split('\n').splice(1).slice(0,-1)
    bodyLines = typedMessage.body.split('\n').splice(1).slice(0,-1)

    # process execution warnings and errors
    id = typedMessage.id
    type = typedMessage.type
    if (type is 'warning' or type is 'error') and typedMessage.data.source?
      # create issue link element
      startTag = ''
      endTag = ''
      if (row = typedMessage.data.row)?
        col = typedMessage['data-col']
        startTag  = "<a class=\"#{type}-link\" href=\"#\""
        startTag += " data-id=\"#{id}\""
        startTag += " data-row=\"#{row}\""
        startTag += " data-col=\"#{col}\"" if col?
        startTag += ">"
        endTag    = "</a>"
      headLines[i] = "#{startTag}"+line+endTag for line,i in headLines
      bodyLines[i] =               line        for line,i in bodyLines

    # default typed message processing
    headHtmlLines = []
    for line in headLines
      htmlLine = "<span class=\"text-#{type}\">#{line}</span>"
      headHtmlLines.push(htmlLine)
    bodyHtmlLines = []
    for line in bodyLines
      htmlLine = "<span class=\"text-#{typedMessage.type}\">#{line}</span>"
      bodyHtmlLines.push(htmlLine)

    # put typed message
    htmlLines = headHtmlLines.concat(bodyHtmlLines)
    for line,i in htmlLines
      @activeLine.empty()
      @activeLine.append(line)
      if i isnt htmlLines.length - 1
        @updateOnDidCreateNewLine()

# ------------------------------------------------------------------------------
