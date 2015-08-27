{Emitter}      = require('atom')

terminalUtils  = require('./terminal-utils')

TerminalBuffer = require('./terminal-buffer')

# ------------------------------------------------------------------------------

module.exports =
class Terminal

  ## Deserialization -----------------------------------------------------------

  atom.deserializers.add(this)
  @version: 1
  @deserialize: ({data}) ->
    new Terminal(data)

  ## Construction and destruction ----------------------------------------------

  constructor: (params={}) ->
    @emitter = new Emitter

    # initialize terminal interface properties
    @visible = params.visible ? \
      atom.config.get('levels.defaultTerminalIsVisible')
    @size = params.size ? \
      atom.config.get('levels.defaultTerminalSize')
    @fontSize = params.fontSize ? \
      atom.config.get('levels.defaultTerminalFontSize')

    #initialize buffer
    @buffer = new TerminalBuffer
      prompt: 'Levels>'
      commands:
        help: @helpCommand
        set: @setCommand
        unset: @unsetCommand
        hide: @hideCommand
        clear: @clearCommand
        topkek: @topkekCommand

    @refCount = 0
    @executing = false

  destroy: ->
    @emitter.emit('did-destroy')

  ## Event subscription --------------------------------------------------------

  onDidDestroy: (callback) ->
    @emitter.on('did-destroy',callback)

  observeIsVisible: (callback) ->
    callback(@isVisible())
    @onDidChangeIsVisible(callback)

  onDidChangeIsVisible: (callback) ->
    @emitter.on('did-change-is-visible',callback)

  onDidShow: (callback) ->
    @emitter.on('did-show',callback)

  onDidHide: (callback) ->
    @emitter.on('did-hide',callback)

  observeSize: (callback) ->
    callback(@getSize())
    @onDidChangeSize(callback)

  onDidChangeSize: (callback) ->
    @emitter.on('did-change-size',callback)

  observeFontSize: (callback) ->
    callback(@getFontSize())
    @onDidChangeFontSize(callback)

  onDidChangeFontSize: (callback) ->
    @emitter.on('did-change-font-size',callback)

  onDidFocus: (callback) ->
    @emitter.on('did-focus',callback)

  onDidScrollToTop: (callback) ->
    @emitter.on('did-scroll-to-top',callback)

  onDidScrollToBottom: (callback) ->
    @emitter.on('did-scroll-to-bottom',callback)

  observeIsExecuting: (callback) ->
    callback(@isExecuting())
    @onDidChangeIsExecuting(callback)

  onDidChangeIsExecuting: (callback) ->
    @emitter.on('did-change-is-executing',callback)

  onDidStartExecution: (callback) ->
    @emitter.on('did-start-execution',callback)

  onDidStopExecution: (callback) ->
    @emitter.on('did-stop-execution',callback)

  onDidCreateNewLine: (callback) ->
    @buffer.onDidCreateNewLine(callback)

  onDidUpdateActiveLine: (callback) ->
    @buffer.onDidUpdateActiveLine(callback)

  onDidEnterInput: (callback) ->
    @buffer.onDidEnterInput(callback)

  onDidClear: (callback) ->
    @buffer.onDidClear(callback)

  ## Acquiring and releasing the terminal --------------------------------------

  isRetained: ->
    @refCount > 0

  acquire: ->
    @refCount++

  release: ->
    if @isRetained()
      @refCount--
      @destroy() unless @isRetained()

  ## Terminal interface properties and methods ---------------------------------

  getSize: ->
    @size

  setSize: (size) ->
    unless size is @size
      minSize = terminalUtils.MIN_SIZE
      if size >= minSize then @size = size else @size = minSize
      @emitter.emit('did-change-size',@size)

  getFontSize: ->
    @fontSize

  setFontSize: (fontSize) ->
    unless fontSize is @fontSize
      minFontSize = terminalUtils.MIN_FONT_SIZE
      maxFontSize = terminalUtils.MAX_FONT_SIZE
      if minFontSize <= fontSize <= maxFontSize
        @fontSize = fontSize
        @emitter.emit('did-change-font-size',@fontSize)

  increaseFontSize: ->
    @setFontSize(@fontSize+1)

  decreaseFontSize: ->
    @setFontSize(@fontSize-1)

  getLineHeight: ->
    @fontSize + 4

  getCharWidth: ->
    dummyElement = document.createElement('span')
    dummyElement.style.fontFamily = 'Menlo'
    dummyElement.style.fontSize = "#{@fontSize}px"
    dummyElement.style.visibility = 'hidden'
    dummyElement.textContent = '_'
    body = document.getElementsByTagName('body')[0];
    body.appendChild(dummyElement)
    charWidth = dummyElement.offsetWidth
    body.removeChild(dummyElement)
    charWidth

  focus: ->
    @emitter.emit('did-focus')

  scrollToTop: ->
    @emitter.emit('did-scroll-to-top')

  scrollToBottom: ->
    @emitter.emit('did-scroll-to-bottom')

  ## Terminal buffer methods ---------------------------------------------------

  getBuffer: ->
    @buffer

  newLine: ->
    @buffer.newLine()

  write: (output) ->
    @buffer.write(output)

  writeLn: (output) ->
    @buffer.writeLn(output)

  enterScope: (params) ->
    @buffer.enterScope(params)

  exitScope: ->
    @buffer.exitScope()

  clear: ->
    @buffer.clear()

  ## Managing terminal commands ------------------------------------------------

  # ...

  ## Built-in terminal commands ------------------------------------------------

  helpCommand: =>

  setCommand: (args) =>
    if not args? or args.length isnt 2
      @writeLn('set: wrong number of arguments')
    else
      propertyStr = args[0]
      valueStr = args[1]
      switch propertyStr
        when 'size'
          unless isNaN(value = parseInt(valueStr))
            @setSize(value)
          else
            @writeLn("set: #{valueStr}: invalid argument")
        when 'fontSize'
          unless isNaN(value = parseInt(valueStr))
            @setFontSize(value)
          else
            @writeLn("set: #{valueStr}: invalid argument")
        else @writeLn("set: #{propertyStr}: unknown property")

  unsetCommand: (args) =>
    if not args? or args.length isnt 1
      @writeLn('unset: wrong number of arguments')
    else
      switch (propertyStr = args[0])
        when 'size'
          @setSize(terminalUtils.DEFAULT_SIZE)
        when 'fontSize'
          @setFontSize(terminalUtils.DEFAULT_FONT_SIZE)
        else @writeLn("unset: #{propertyStr}: unknown property")

  hideCommand: =>
    @hide()

  clearCommand: =>
    @clear()

  topkekCommand: =>
    @writeLn(terminalUtils.TOPKEK)

  ## Execution -----------------------------------------------------------------

  isExecuting: ->
    @executing

  didStartExecution: ->
    unless @isExecuting()
      # @executionData = executionData
      @executing = true
      @emitter.emit('did-start-execution')
      @emitter.emit('did-change-is-executing',@executing)

  didStopExecution: ->
    if @isExecuting()
      # executionData = @executionData
      # @executionData = null
      @executing = false
      @emitter.emit('did-stop-execution')
      @emitter.emit('did-change-is-executing',@executing)

  ## Showing and hiding the terminal -------------------------------------------

  isVisible: ->
    @visible

  toggle: ->
    if @isVisible() then @hide() else @show()

  show: ->
    unless @isVisible()
      @visible = true
      @emitter.emit('did-show')
      @emitter.emit('did-change-is-visible',@visible)

  hide: ->
    if @isVisible()
      @visible = false
      @emitter.emit('did-hide')
      @emitter.emit('did-change-is-visible',@visible)

  ## Serialization -------------------------------------------------------------

  serialize: ->
    version: @constructor.version
    deserializer: 'Terminal'
    data:
      visible: @visible
      size: @size
      fontSize: @fontSize

# ------------------------------------------------------------------------------

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
