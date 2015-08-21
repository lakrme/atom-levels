{CompositeDisposable,Emitter} = require 'atom'

TerminalBuffer                = require './terminal-buffer'

# ------------------------------------------------------------------------------

module.exports =
class Terminal

  ## Construction and destruction ----------------------------------------------

  constructor: (params={}) ->
    @emitter = new Emitter
    @buffer = new TerminalBuffer

    @isExecuting = false
    @isFolded = params.isFolded ? false
    @visibleLines = params.visibleLines ? 20

    @typedMessageBuffer = null
    @typedMessageCurrentLineBuffer = ''

  destroy: ->

  ## Event subscription --------------------------------------------------------

  onDidCreateNewLine: (callback) ->
    @buffer.onDidCreateNewLine(callback)

  onDidUpdateActiveLine: (callback) ->
    @buffer.onDidUpdateActiveLine(callback)

  onDidEnterInput: (callback) ->
    @buffer.onDidEnterInput(callback)

  onWillReadTypedMessage: (callback) ->
     @emitter.on('will-read-typed-message',callback)

  onDidReadTypedMessage: (callback) ->
    @emitter.on('did-read-typed-message',callback)

  ## Managing associated level code editors ------------------------------------

  # addLevelCodeEditor: (levelCodeEditor) ->
  #   levelCodeEditorSubscrs = new CompositeDisposable
  #   levelCodeEditorSubscrs.add levelCodeEditor.onDidActivate =>
  #
  #   levelCodeEditorSubscrs.add levelCodeEditor.onDidDeactivate =>
  #
  #   levelCodeEditorSubscrs.add levelCodeEditor.onDidDestroy =>
  #
  #   @levelCodeEditorSubscrsById[levelCodeEditor.getId()] = n
  #
  # removeLevelCodeEditor: (levelCodeEditor) ->
  #   id = levelCodeEditor.getId()
  #   if (levelCodeEditorSubscrs = @levelCodeEditorSubscrsById[id])?
  #     if @activeLevelCodeEditor
  #     levelCodeEditorSubscrs.dispose()
  #     delete @levelCodeEditorSubscrsById[id]

  ## Writing to the terminal ---------------------------------------------------

  write: (output) ->
    @buffer.write(output)

  writeLn: (output) ->
    @buffer.writeLn(output)

  writeTypedMessage = (head,body,{type,icon,data}={}) ->
        if head or body
          type ?= "normal"
          startTag = ''
          endTag = ''
          headElem = ''
          bodyElem = ''
          if type isnt 'normal' or icon or data?
            startTag  = "<message type=\"#{type}\""
            startTag += " icon=\"#{icon}\""          if icon
            startTag += " data-#{key}=\"#{value}\""  for key,value of data
            startTag += '>\n'
            headElem  = "<head>\n#{head}\n</head>\n" if head
            bodyElem  = "<body>\n#{body}\n</body>\n" if body
            endTag    = "</message>\n"
          typedMessage = startTag + headElem + bodyElem + endTag
          @write(typedMessage)

  writeSubtleMessage = (head,body) ->
    @writeTypedMessage(head,body,{type: 'subtle'})

  writeInfoMessage = (head,body,{icon}={}) ->
    @writeTypedMessage(head,body,{type: 'info',icon})

  writeSuccessMessage = (head,body,{icon}={}) ->
    @writeTypedMessage(head,body,{type: 'success',icon})

  writeWarningMessage = (head,body,{icon,row,col}={}) ->
    data = {}
    data.row = row if row
    data.col = col if row and col
    @writeTypedMessage(head,body,{type: 'warning',icon,data})

  writeErrorMessage = (head,body,{icon,row,col}={}) ->
    data = {}
    data.row = row if row
    data.col = col if row and col
    @writeTypedMessage(head,body,{type: 'error',icon,data})

  ## ---------------------------------------------------------------------------

  # fold: ->
  #
  #
  # writeLn: ()
  #
  # show: ->

  ## Showing and hiding the terminal -------------------------------------------

  show: ->

  hide: ->

# ------------------------------------------------------------------------------
