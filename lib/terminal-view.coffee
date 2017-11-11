{CompositeDisposable} = require 'atom'

module.exports =
class TerminalView
  constructor: (@terminal) ->
    @element = document.createElement 'div'
    @element.className = 'terminal'
    @element.tabIndex = 0

    @cursor = document.createElement 'div'
    @cursor.className = 'cursor'
    @cursor.innerHTML = '&nbsp;'
    @element.appendChild @cursor

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
      @element.scrollTop = 0
    @terminalSubscrs.add @terminal.onDidScrollToBottom =>
      @element.scrollTop = @element.scrollHeight
    @terminalSubscrs.add @terminal.onDidCreateNewLine =>
      @updateOnDidCreateNewLine()
    @terminalSubscrs.add @terminal.onDidUpdateActiveLine (activeLine) =>
      @updateOnDidUpdateActiveLine(activeLine)
    @terminalSubscrs.add @terminal.onDidClear =>
      @updateOnDidClear()
    @terminalSubscrs.add @terminal.onDidStartReadingTypedMessage =>
      @didStartReadingTypedMessage()
    @terminalSubscrs.add @terminal.onDidStopReadingTypedMessage =>
      @didStopReadingTypedMessage()
    @terminalSubscrs.add @terminal.onDidReadTypedMessage (typedMessage) =>
      @didReadTypedMessage(typedMessage)

  moveCursorAbsolute: (rowIndex,colIndex) ->
    @moveCursorAbsoluteInRow(colIndex)
    @moveCursorAbsoluteInCol(rowIndex)

  moveCursorAbsoluteInRow: (@cursorColIndex) ->
    left = @cursorColIndex * @charWidth
    @cursor.style.left = "#{left}px"

  moveCursorAbsoluteInCol: (@cursorRowIndex) ->
    top = @cursorRowIndex * @lineHeight
    @cursor.style.top = "#{top}px"

  moveCursorRelative: (rowOffset,colOffset) ->
    @moveCursorRelativeInRow(colOffset)
    @moveCursorRelativeInCol(rowOffset)

  moveCursorRelativeInRow: (colOffset) ->
    @cursorColIndex += colOffset
    leftOffset = colOffset * @charWidth
    @cursor.style.left = "#{parseInt(@cursor.style.left) + leftOffset}px"

  moveCursorRelativeInCol: (rowOffset) ->
    @cursorRowIndex += rowOffset
    topOffset = rowOffset * @lineHeight
    @cursor.style.top = "#{parseInt(@cursor.style.top) + topOffset}px"

  show: ->
    @element.style.display = ''

  hide: ->
    @element.style.display = 'none'

  updateOnDidChangeIsVisible: (@isVisible) ->
    if @isVisible then @show() else @hide()

  updateOnDidChangeSize: (@size) ->
    @element.style.height = "#{@size*@lineHeight}px"

  updateOnDidChangeFontSize: (@fontSize) ->
    @lineHeight = @terminal.getLineHeight()
    @charWidth = @terminal.getCharWidth()
    @element.style.fontSize = "#{@fontSize}px"
    @element.style.lineHeight = "#{@lineHeight}px"
    @element.style.height = "#{@size*@lineHeight}px"

    # TODO: Fix pseudo-class styling!
    # update the icon size
    # icons = document.querySelector '.icon::before'
    # icons.style.fontSize = "#{@fontSize}px"
    # icons.style.height = "#{@fontSize}px"
    # icons.style.width = "#{@fontSize}px"

    # update the cursor
    @cursor.style.height = "#{@lineHeight}px"
    @cursor.style.width = "#{@charWidth}px"
    @moveCursorAbsolute(@cursorRowIndex,@cursorColIndex)

  updateOnDidCreateNewLine: ->
    unless @waitingForTypedMessage
      @activeLine = document.createElement 'div'
      @activeLine.className = 'line'
      @activeLine.tabIndex = 0
      @activeLine.innerHTML = '&nbsp;'
      @element.appendChild(@activeLine)
      @activeLineIndex++
      @moveCursorAbsolute(@activeLineIndex,0)
      @element.scrollTop = @element.scrollHeight

      configKeyPath = 'levels.terminalSettings.terminalContentLimit'
      contentLimit = atom.config.get(configKeyPath)
      if contentLimit > 0 and contentLimit <= @activeLineIndex
        # @removeLines(1,(@activeLineIndex-contentLimit)+1)
        @terminal.clear()

  updateOnDidUpdateActiveLine: ({input,output,inputCursorPos}) ->
    unless @waitingForTypedMessage
      @activeLine.innerHTML = ''
      @activeLine.textContent = output+input
      @activeLine.innerHTML += '&nbsp;'
      @moveCursorAbsoluteInRow(output.length+inputCursorPos)

  updateOnDidClear: ->
    @element.innerHTML = ''
    @element.appendChild @cursor
    @element.appendChild @activeLine
    @moveCursorRelative(-@activeLineIndex,0)
    @activeLineIndex = 0

  removeLines: (index,deleteCount) ->
    @element.children.slice(index,index+deleteCount).remove()
    @moveCursorRelative(-deleteCount,0)
    @activeLineIndex -= deleteCount

  didStartReadingTypedMessage: ->
    @waitingForTypedMessage = true

  didStopReadingTypedMessage: ->
    if @waitingForTypedMessage
      @activeLine.innerHTML = '&nbsp;'
      @waitingForTypedMessage = false

  didReadTypedMessage: (typedMessage) ->
    @waitingForTypedMessage = false
    @putTypedMessage(typedMessage)

  putTypedMessage: (typedMessage) ->
    headLines = typedMessage.head.split('\n').splice(1).slice(0,-1).map \
      (line) -> line.replace(/</g,'&lt;').replace(/>/g,'&gt;')
    bodyLines = typedMessage.body.split('\n').splice(1).slice(0,-1).map \
      (line) -> line.replace(/</g,'&lt;').replace(/>/g,'&gt;')

    # process execution warnings and errors
    id = typedMessage.id
    type = typedMessage.type
    if (type is 'warning' or type is 'error') and typedMessage.data?.source?
      # create issue link element
      startTag = ''
      endTag = ''
      if (row = typedMessage.data.row)?
        col = typedMessage.data.col
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
      @activeLine.innerHTML = line
      if i isnt htmlLines.length - 1
        @updateOnDidCreateNewLine()