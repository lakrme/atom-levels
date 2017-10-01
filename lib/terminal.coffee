{CompositeDisposable,Emitter} = require('atom')

terminalUtils                 = require('./terminal-utils')

TerminalBuffer                = require('./terminal-buffer')

# ------------------------------------------------------------------------------

module.exports =
class Terminal

  ## Deserialization -----------------------------------------------------------

  atom.deserializers.add(this)
  @version: 1
  @deserialize: ({data}) ->
    new Terminal(data)

  ## IDs for typed messages ----------------------------------------------------

  @typedMessageIdCounter: 0

  @getTypedMessageId: ->
    id = @typedMessageIdCounter
    @typedMessageIdCounter++
    id

  ## Construction and destruction ----------------------------------------------

  constructor: (params={}) ->
    @emitter = new Emitter

    # initialize terminal interface properties
    @visible = params.visible ? \
      not atom.config.get('levels.terminalSettings.defaultTerminalIsHidden')
    @size = params.size ? \
      atom.config.get('levels.terminalSettings.defaultTerminalSize')
    @fontSize = params.fontSize ? \
      atom.config.get('levels.terminalSettings.defaultTerminalFontSize')

    #initialize buffer
    @buffer = new TerminalBuffer
      prompt: 'Levels>'
      commands:
        help: @helpCommand
        set: @setCommand
        unset: @unsetCommand
        clear: @clearCommand
        topkek: @topkekCommand

    @focused = false
    @refCount = 0
    @executing = false
    @typedMessageBuffer = null
    @typedMessageCurrentLineBuffer = null

    @bufferSubscrs = new CompositeDisposable
    @bufferSubscrs.add @buffer.onDidCreateNewLine =>
      @updateTypedMessageBufferOnDidCreateNewLine()
    @bufferSubscrs.add @buffer.onDidUpdateActiveLine ({output}) =>
      @updateTypedMessageBufferOnDidUpdateActiveLine(output)

  destroy: ->
    @bufferSubscrs.dispose()
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

  onDidBlur: (callback) ->
    @emitter.on('did-blur',callback)

  onDidScrollToTop: (callback) ->
    @emitter.on('did-scroll-to-top',callback)

  onDidScrollToBottom: (callback) ->
    @emitter.on('did-scroll-to-bottom',callback)

  # observeIsBusy: (callback) ->
  #   callback(@isBusy())
  #   @onDidChangeIsBusy(callback)
  #
  # onDidChangeIsBusy: (callback) ->
  #   @emitter.on('did-change-is-busy',callback)

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

  onDidStartReadingTypedMessage: (callback) ->
    @emitter.on('did-start-reading-typed-message',callback)

  onDidStopReadingTypedMessage: (callback) ->
    @emitter.on('did-stop-reading-typed-message',callback)

  onDidReadTypedMessage: (callback) ->
    @emitter.on('did-read-typed-message',callback)

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
      fontSizes = terminalUtils.FONT_SIZES
      if fontSizes.indexOf(fontSize) > -1
        @fontSize = fontSize
        @emitter.emit('did-change-font-size',@fontSize)

  increaseFontSize: ->
    fontSizes = terminalUtils.FONT_SIZES
    fontSizeIndex = fontSizes.indexOf(@fontSize)
    if fontSizeIndex < fontSizes.length-1
      @setFontSize(fontSizes[fontSizeIndex+1])

  decreaseFontSize: ->
    fontSizes = terminalUtils.FONT_SIZES
    fontSizeIndex = fontSizes.indexOf(@fontSize)
    if fontSizeIndex > 0
      @setFontSize(fontSizes[fontSizeIndex-1])

  getLineHeight: ->
    @fontSize + 4

  getCharWidth: ->
    dummyElement = document.createElement('span')
    dummyElement.style.fontFamily = 'Courier'
    dummyElement.style.fontSize = "#{@fontSize}px"
    dummyElement.style.visibility = 'hidden'
    dummyElement.textContent = '_'
    body = document.getElementsByTagName('body')[0]
    body.appendChild(dummyElement)
    charWidth = dummyElement.getBoundingClientRect().width
    body.removeChild(dummyElement)
    charWidth

  hasFocus: ->
    @focused

  focus: ->
    @emitter.emit('did-focus')
    @didFocus()

  didFocus: ->
    @focused = true

  blur: ->
    @emitter.emit('did-blur')
    @didBlur()

  didBlur: ->
    @focused = false

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

  ## Writing typed messages to the terminal ------------------------------------

  writeTypedMessage: ({type,head,body,data}={}) ->
    headElem = ''
    bodyElem = ''
    if head or body
      startTag  = "<message type=\"#{type}\""
      startTag += " data-#{key}=\"#{value}\""  for key,value of data
      startTag += '>\n'
      headElem  = "<head>\n#{head}\n</head>\n" if head
      bodyElem  = "<body>\n#{body}\n</body>\n" if body
      endTag    = "</message>\n"
      typedMessage = startTag + headElem + bodyElem + endTag
      @buffer.newLine() if @buffer.getActiveLineOutput()
      @buffer.write(typedMessage)

  writeSubtle: (message) ->
    @writeTypedMessage({type: 'subtle',body: message})

  writeInfo: (message) ->
    @writeTypedMessage({type: 'info',body: message})

  writeSuccess: (message) ->
    @writeTypedMessage({type: 'success',body: message})

  writeWarning: (message) ->
    @writeTypedMessage({type: 'warning',body: message})

  writeError: (message) ->
    @writeTypedMessage({type: 'error',body: message})

  ## Reading typed message from the output -------------------------------------

  updateTypedMessageBufferOnDidCreateNewLine: ->
    if @typedMessageBuffer?
      unless @typedMessageCurrentLineBuffer.match(/^<message\s+.*type=.*>/)? \
          or @typedMessageCurrentLineBuffer.match(/^<head>/)? \
          or @typedMessageCurrentLineBuffer.match(/^<\/head>/)? \
          or @typedMessageCurrentLineBuffer.match(/^<body>/)? \
          or @typedMessageCurrentLineBuffer.match(/^<\/body>/)? \
          or @typedMessageCurrentLineBuffer.match(/^<\/message>/)?
        # escape special characters
        @typedMessageCurrentLineBuffer = @typedMessageCurrentLineBuffer\
          .replace(/&/g,'&amp;')
          .replace(/"/g,'&quot;')
          .replace(/'/g,'&apos;')
          .replace(/</g,'&lt;')
          .replace(/>/g,'&gt;')
      @typedMessageBuffer += "#{@typedMessageCurrentLineBuffer}\n"
      if @typedMessageCurrentLineBuffer.match(/^<\/message>/)?
        typedMessage = @readTypedMessage(@typedMessageBuffer)
        @typedMessageBuffer = null
        @typedMessageCurrentLineBuffer = null
        @emitter.emit('did-read-typed-message',typedMessage)
        @emitter.emit('did-stop-reading-typed-message')

  updateTypedMessageBufferOnDidUpdateActiveLine: (output) ->
    if @typedMessageBuffer?
      @typedMessageCurrentLineBuffer = output
    else
      if output.match(/^<message\s+.*type=.*>/)?
        @typedMessageBuffer = ''
        @typedMessageCurrentLineBuffer = output
        @emitter.emit('did-start-reading-typed-message')

  readTypedMessage: (buffer) ->
    parser = new DOMParser
    xml = parser.parseFromString buffer, 'text/xml'
    typedMessageXml = xml.querySelectorAll 'message'
    typedMessage = {id: @constructor.getTypedMessageId()}

    for msg in typedMessageXml
      for attr in msg.attributes
        if attr.name.startsWith('data-')
          dataKey = attr.name.substr(5)
          typedMessage.data ?= {}
          typedMessage.data[dataKey] = attr.value
        else
          typedMessage[attr.name] = attr.value

    typedMessage.head = typedMessageXml[0].getElementsByTagName('head')[0]?.textContent ? ''
    typedMessage.body = typedMessageXml[0].getElementsByTagName('body')[0]?.textContent ? ''
    typedMessage

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

  clearCommand: =>
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView,'levels:clear-terminal')

  topkekCommand: =>
    @writeLn(terminalUtils.TOPKEK)

  # ## Locking and unlocking the terminal ----------------------------------------
  #
  # isBusy: ->
  #   @busy
  #
  # hire: ->
  #   unless @isBusy()
  #     @busy = true
  #     @emitter.emit('did-change-is-busy',@busy)
  #
  # fire: ->
  #   if @isBusy()
  #     @busy = false
  #     @emitter.emit('did-change-is-busy'@busy)

  ## Execution -----------------------------------------------------------------

  isExecuting: ->
    @executing

  didStartExecution: ->
    unless @isExecuting()
      @executing = true
      @emitter.emit('did-start-execution')
      @emitter.emit('did-change-is-executing',@executing)

  didStopExecution: ->
    if @isExecuting()
      if @typedMessageBuffer?
        @typedMessageBuffer = null
        @typedMessageCurrentLineBuffer = null
        @emitter.emit('did-stop-reading-typed-message')
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
