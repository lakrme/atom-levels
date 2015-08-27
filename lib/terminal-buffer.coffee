{Emitter} = require('atom')

# ------------------------------------------------------------------------------

module.exports =
class TerminalBuffer

  ## Construction --------------------------------------------------------------

  constructor: ({prompt,commands,commandNotFound}={}) ->
    @emitter = new Emitter

    # assign default values to the root scope attributes
    prompt ?= ''
    commands ?= {}
    commandNotFound ?= (input) -> @writeLn("#{input}: command not found")

    @history = []
    @scopes = []

    # enter the root scope
    @enterScope
      prompt: prompt
      commands: commands
      commandNotFound: commandNotFound

  ## Event subscription --------------------------------------------------------

  onDidCreateNewLine: (callback) ->
    @emitter.on('did-create-new-line',callback)

  onDidUpdateActiveLine: (callback) ->
    @emitter.on('did-update-active-line',callback)

  onDidEnterInput: (callback) ->
    @emitter.on('did-enter-input',callback)

  onDidEnterScope: (callback) ->
    @emitter.on('did-enter-scope',callback)

  onDidExitScope: (callback) ->
    @emitter.on('did-exit-scope',callback)

  onDidClear: (callback) ->
    @emitter.on('did-clear',callback)

  ## Mutating the buffer -------------------------------------------------------

  newLine: (prompt=@prompt) ->
    if @activeLineOutput? and @activeLineInput?
      @history.push(@activeLineOutput+@activeLineInput)
    @activeLineOutput = ''
    @activeLineInput = ''
    @activeLineInputCursorPos = 0
    @promptIsActive = false
    @didCreateNewLine()
    @inputHistoryIndex = -1

    if prompt
      @activeLineOutput = "#{prompt} "
      @promptIsActive = true
      @didUpdateActiveLine()

  addStringToOutput: (string) ->
    if @promptIsActive
      @activeLineOutput = ''
      @promptIsActive = false
    @activeLineOutput += string
    @didUpdateActiveLine()

  addStringToInput: (string) ->
    prefix = @activeLineInput.slice(0,@activeLineInputCursorPos)
    suffix = @activeLineInput.substr(@activeLineInputCursorPos)
    @activeLineInput = prefix + string + suffix
    @activeLineInputCursorPos += string.length
    @didUpdateActiveLine()

  removeCharFromInput: ->
    unless @activeLineInputCursorPos is 0
      prefix = @activeLineInput.slice(0,@activeLineInputCursorPos-1)
      suffix = @activeLineInput.substr(@activeLineInputCursorPos)
      @activeLineInput = prefix + suffix
      @activeLineInputCursorPos--
      @didUpdateActiveLine()

  ## Browsing the input history ------------------------------------------------

  showPreviousInput: ->
    if @inputHistoryIndex < @inputHistory.length - 1
      @inputHistoryIndex++
      @activeLineInput = @inputHistory[@inputHistoryIndex]
      @activeLineInputCursorPos = @activeLineInput.length
      @didUpdateActiveLine()

  showSubsequentInput: ->
    switch
      when @inputHistoryIndex == 0
        @activeLineInput = ''
        @activeLineInputCursorPos = 0
        @inputHistoryIndex--
        @didUpdateActiveLine()
      when @inputHistoryIndex > 0
        @activeLineInput = @inputHistory[@inputHistoryIndex-1]
        @activeLineInputCursorPos = @activeLineInput.length
        @inputHistoryIndex--
        @didUpdateActiveLine()

  ## Moving the input cursor ---------------------------------------------------

  moveInputCursorLeft: ->
    if @activeLineInputCursorPos > 0
      @activeLineInputCursorPos--
      @didUpdateActiveLine()

  moveInputCursorRight: ->
    if @activeLineInputCursorPos < @activeLineInput.length
      @activeLineInputCursorPos++
      @didUpdateActiveLine()

  ## Entering the current input ------------------------------------------------

  enterInput: ->
    input = @activeLineInput.trim()
    @newLine()
    @didEnterInput(input)
    if input
      @inputHistory.unshift(input) unless @inputHistory[0] is input
      if Object.keys(@commands).length isnt 0
        args = input.split(' ')
        commandName = args.shift()
        if (command = @commands[commandName])?
          if args.length is 0
            command()
          else
            command(args)
        else
          @commandNotFound(commandName)

  ## Interface methods ---------------------------------------------------------

  write: (output) ->
    lines = output.split('\n')
    @addStringToOutput(lines[0])
    restLines = lines.splice(1)
    for line,i in restLines
      @newLine()
      # if the output ends with "\n", do not print the last element of restLines
      # (the empty string) which would overwrite the next line's prompt
      unless i is restLines.length-1 and not line
        @addStringToOutput(line)

  writeLn: (output) ->
    @write(output)
    @newLine()

  clear: ->
    @history = []
    @emitter.emit('did-clear')

  ## Entering and exiting scopes -----------------------------------------------

  # TODO overwrite old prompt (see exitScope)
  enterScope: ({prompt,commands,commandNotFound}={}) ->
    prompt ?= prompt
    commands ?= 'none'
    commandNotFound ?= @commandNotFound

    switch prompt
      when 'none'    then prompt = ''
      when 'inherit' then prompt = @prompt

    switch commands
      when 'none'    then commands = {}
      when 'inherit' then commands = @commands

    @prompt = prompt
    @commands = commands
    @commandNotFound = commandNotFound
    @inputHistory = []
    @scopes.push
      prompt: @prompt
      commands: @commands
      commandNotFound: @commandNotFound
      inputHistory: @inputHistory

  exitScope: ->
    # the root scope can not be exited
    unless @scopes.length is 1
      @scopes.pop()
      currentScope = @scopes[@scopes.length-1]
      @prompt = currentScope.prompt
      @commands = currentScope.commands
      @commandNotFound = currentScope.commandNotFound
      @inputHistory = currentScope.inputHistory

      # update prompt
      if @prompt
        @addStringToOutput("#{@prompt} ")
        @promptIsActive = true

  ## Emitting events -----------------------------------------------------------

  didCreateNewLine: ->
    @emitter.emit('did-create-new-line')

  didUpdateActiveLine: ->
    @emitter.emit 'did-update-active-line',
      output: @activeLineOutput
      input: @activeLineInput
      inputCursorPos: @activeLineInputCursorPos

  didEnterInput: (input) ->
    @emitter.emit('did-enter-input',input)

# ------------------------------------------------------------------------------
