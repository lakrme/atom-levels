{CompositeDisposable,Emitter} = require('atom')

# ------------------------------------------------------------------------------

module.exports =
class Terminal

  ## Construction and destruction ----------------------------------------------

  constructor: (params={}) ->
    @emitter = new Emitter

    # initialize terminal properties
    @visible = params.visible ? true
    @active = false
    @minRows = 10
    @rows = params.rows ? 20
    @fontSize = params.fontSize ? 11
    @charWidth = 7
    @executing = false
    @refCount = 0

  destroy: ->
    @emitter.emit('did-destroy')

  ## Event subscription --------------------------------------------------------

  onDidDestroy: (callback) ->
    @emitter.on('did-destroy',callback)

  observeIsVisible: (callback) ->
    callback(@isVisible())
    @onDidShow(=> callback(@isVisible()))
    @onDidHide(=> callback(@isVisible()))

  onDidShow: (callback) ->
    @emitter.on('did-show',callback)

  onDidHide: (callback) ->
    @emitter.on('did-hide',callback)

  onDidChangeSize: (callback) ->
    @emitter.on('did-change-size',callback)

  onDidClear: (callback) ->
    @emitter.on('did-clear',callback)

  onDidFocus: (callback) ->
    @emitter.on('did-focus',callback)

  onDidScrollToTop: (callback) ->
    @emitter.on('did-scroll-to-top',callback)

  onDidScrollToBottom: (callback) ->
    @emitter.on('did-scroll-to-bottom',callback)

  observeIsExecuting: (callback) ->
    callback(@isExecuting())
    @onDidStartExecution((levelCodeEditor) => callback(@isExecuting()))
    @onDidStopExecution((levelCodeEditor) => callback(@isExecuting()))

  onDidStartExecution: (callback) ->
    @emitter.on('did-start-execution',callback)

  onDidStopExecution: (callback) ->
    @emitter.on('did-stop-execution',callback)

  ## Terminal interface properties ---------------------------------------------

  getMinSize: ->
    @minRows

  getSize: ->
    @rows

  getLineHeight: ->
    @fontSize + 4

  getCharWidth: ->
    @charWidth

  setMinSize: (@minRows) ->

  setSize: (rows) ->
    unless rows is @rows
      if rows >= @minRows then @rows = rows else @rows = @minRows
      @emitter.emit('did-change-size',@rows)

  ## Terminal interface methods ----------------------------------------------

  focus: ->
    @emitter.emit('did-focus')

  scrollToTop: ->
    @emitter.emit('did-scroll-to-top')

  scrollToBottom: ->
    @emitter.emit('did-scroll-to-bottom')

  ## Terminal methods ----------------------------------------------------------

  clear: ->
    # TODO clear the buffer
    @emitter.emit('did-clear')

  ## Level code execution ------------------------------------------------------

  isExecuting: ->
    @executing

  startExecution: (levelCodeEditor) ->
    unless @isExecuting()
      @executing = true
      # TODO actually start execution
      @emitter.emit('did-start-execution',levelCodeEditor)

  stopExecution: (levelCodeEditor) ->
    if @isExecuting()
      @executing = false
      # TODO actually stop execution
      @emitter.emit('did-stop-execution',levelCodeEditor)

  ## Acquiring and releasing the terminal --------------------------------------

  isRetained: ->
    @refCount > 0

  acquire: ->
    @refCount++

  release: ->
    if @isRetained()
      @refCount--
      @destroy() unless @isRetained()

  ## Showing and hiding the terminal -------------------------------------------

  isVisible: ->
    @visible

  toggle: ->
    if @isVisible() then @hide() else @show()

  show: ->
    unless @isVisible()
      @visible = true
      @emitter.emit('did-show')

  hide: ->
    if @isVisible()
      @visible = false
      @emitter.emit('did-hide')

# ------------------------------------------------------------------------------



  # onDidCreateNewLine: (callback) ->
  #   @buffer.onDidCreateNewLine(callback)
  #
  # onDidUpdateActiveLine: (callback) ->
  #   @buffer.onDidUpdateActiveLine(callback)
  #
  # onDidEnterInput: (callback) ->
  #   @buffer.onDidEnterInput(callback)
  #
  #
  # onDidIncreaseFontSize: (callback) ->
  #   @emitter.on('did-increase-font-size',callback)
  #
  # onDidDecreaseFontSize: (callback) ->
  #   @emitter.on('did-decrease-font-size',callback)
  #
  # onDidChangeVisibleLines: (callback) ->
  #   @emitter.on('did-change-visible-lines',callback)

  # onWillReadTypedMessage: (callback) ->
  #    @emitter.on('will-read-typed-message',callback)
  #
  # onDidReadTypedMessage: (callback) ->
  #   @emitter.on('did-read-typed-message',callback)

  ## Writing to the terminal ---------------------------------------------------

  # write: (output) ->
  #   @buffer.write(output)
  #
  # writeLn: (output) ->
  #   @buffer.writeLn(output)

  # writeTypedMessage = (head,body,{type,icon,data}={}) ->
  #       if head or body
  #         type ?= "normal"
  #         startTag = ''
  #         endTag = ''
  #         headElem = ''
  #         bodyElem = ''
  #         if type isnt 'normal' or icon or data?
  #           startTag  = "<message type=\"#{type}\""
  #           startTag += " icon=\"#{icon}\""          if icon
  #           startTag += " data-#{key}=\"#{value}\""  for key,value of data
  #           startTag += '>\n'
  #           headElem  = "<head>\n#{head}\n</head>\n" if head
  #           bodyElem  = "<body>\n#{body}\n</body>\n" if body
  #           endTag    = "</message>\n"
  #         typedMessage = startTag + headElem + bodyElem + endTag
  #         @write(typedMessage)
  #
  # writeSubtleMessage = (head,body) ->
  #   @writeTypedMessage(head,body,{type: 'subtle'})
  #
  # writeInfoMessage = (head,body,{icon}={}) ->
  #   @writeTypedMessage(head,body,{type: 'info',icon})
  #
  # writeSuccessMessage = (head,body,{icon}={}) ->
  #   @writeTypedMessage(head,body,{type: 'success',icon})
  #
  # writeWarningMessage = (head,body,{icon,row,col}={}) ->
  #   data = {}
  #   data.row = row if row
  #   data.col = col if row and col
  #   @writeTypedMessage(head,body,{type: 'warning',icon,data})
  #
  # writeErrorMessage = (head,body,{icon,row,col}={}) ->
  #   data = {}
  #   data.row = row if row
  #   data.col = col if row and col
  #   @writeTypedMessage(head,body,{type: 'error',icon,data})
