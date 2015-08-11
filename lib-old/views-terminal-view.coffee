{$,View} = require 'atom-space-pen-views'

# ------------------------------------------------------------------------------

module.exports =
class TerminalView extends View

  @content: ->
    @div class: 'terminal', tabindex: 0, =>
      @div class: 'cursor', outlet: 'cursor', =>
        @raw '&nbsp;'

  initialize: (@viewManager) ->
    # TODO move these to constants object
    @charWidth = 7
    @iconWidth = 14
    @lineHeight = 15

    @activeLineIndex = -1
    @typedMessageBuffer = null
    @typedMessageCurrentLineBuffer = ''

  setTextEditor: (@textEditor) ->

  newLine: ->
    unless @typedMessageBuffer?
      @activeLine = $(document.createElement('div'))
      @activeLine.addClass('line')
      @append(@activeLine)
      @activeLineIndex++
      @moveCursorAbsolute(@activeLineIndex,0)
      @scrollToBottom()
    else
      @typedMessageBuffer += "#{@typedMessageCurrentLineBuffer}\n"
      if @typedMessageCurrentLineBuffer.match(/^<\/message>$/)?
        typedMessage = @readTypedMessage(@typedMessageBuffer)
        @typedMessageBuffer = null
        @typedMessageCurrentLineBuffer = ''
        @writeTypedMessage(typedMessage)
        if typedMessage['data-row']?
          @viewManager.addIssueAnnotiationToTextEditor(@textEditor,typedMessage)

  updateActiveLine: ({input,output,inputCursorPos}) ->
    unless @typedMessageBuffer?
      if output.match(/^<message\s+.*type=.*>$/)?
        @typedMessageBuffer = ''
        @typedMessageCurrentLineBuffer = output
      else
        @activeLine.empty()
        @activeLine.text(output+input)
        @moveCursorAbsoluteInRow(output.length+inputCursorPos)
        # @scrollToBottom()
    else
      @typedMessageCurrentLineBuffer = output

  clear: ->
    @empty()
    @append(@cursor)
    @append(@activeLine)
    @moveCursorRelative(-@activeLineIndex,0)
    @activeLineIndex = 0

  ## Moving the cursor ---------------------------------------------------------

  moveCursorAbsolute: (rowIndex,colIndex) ->
    @moveCursorAbsoluteInRow(colIndex)
    @moveCursorAbsoluteInCol(rowIndex)

  moveCursorAbsoluteInRow: (colIndex) ->
    left = colIndex * @charWidth
    @cursor.css('left',left)

  moveCursorAbsoluteInCol: (rowIndex) ->
    top = rowIndex * @lineHeight
    @cursor.css('top',top)

  moveCursorRelative: (rowOffset,colOffset) ->
    @moveCursorRelativeInRow(colOffset)
    @moveCursorRelativeInCol(rowOffset)

  moveCursorRelativeInRow: (colOffset) ->
    leftOffset = colOffset * @charWidth
    @cursor.css('left',parseInt(@cursor.css('left'))+leftOffset)

  moveCursorRelativeInCol: (rowOffset) ->
    topOffset = rowOffset * @lineHeight
    @cursor.css('top',parseInt(@cursor.css('top'))+topOffset)

  ## Reading and writing typed messages ----------------------------------------

  readTypedMessage: (buffer) ->
    typedMessageXml = $($.parseXML(buffer)).find('message')
    typedMessage = {}

    # read attributes
    typedMessageXml.each ->
      $.each this.attributes, (i,attr) ->
        typedMessage[attr.name] = attr.value

    # read head and body content
    typedMessage.head = typedMessageXml.children('head').text()
    typedMessage.body = typedMessageXml.children('body').text()
    typedMessage

  writeTypedMessage: (typedMessage) ->
    headLines = typedMessage.head.split('\n').splice(1).slice(0,-1)
    bodyLines = typedMessage.body.split('\n').splice(1).slice(0,-1)

    type = typedMessage.type
    if (type is 'warning' or type is 'error') and typedMessage['data-source']?
      typedMessage.icon = 'alert'        if type is 'warning'
      typedMessage.icon = 'issue-opened' if type is 'error'

      startTag = ''
      endTag = ''
      if (row = typedMessage['data-row'])?
        col = typedMessage['data-col']
        startTag  = "<a class=\"#{type}-link\" href=\"#\" data-row=\"#{row}\""
        startTag += " data-col=\"#{col}\"" if col?
        startTag += ">"
        endTag    = "</a>"

      headLines[i] = " #{startTag}"+line+endTag for line,i in headLines
      bodyLines[i] = '   '         +line        for line,i in bodyLines

    icon = typedMessage.icon

    headHtmlLines = []
    if headLines.length > 0 and icon
      firstHeadHtmlLine =
        "<span class=\"text-#{type} icon icon-#{icon}\">#{headLines[0]}</span>"
      headHtmlLines.push(firstHeadHtmlLine)
      headLines = headLines.splice(1)
    for line in headLines
      htmlLine = "<span class=\"text-#{type}\">#{line}</span>"
      headHtmlLines.push(htmlLine)

    bodyHtmlLines = []
    for line in bodyLines
      htmlLine = "<span class=\"text-#{typedMessage.type}\">#{line}</span>"
      bodyHtmlLines.push(htmlLine)

    for line in headHtmlLines.concat(bodyHtmlLines)
      @activeLine.empty()
      @activeLine.append(line)
      @newLine()

# ------------------------------------------------------------------------------
