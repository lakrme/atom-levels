# ------------------------------------------------------------------------------

module.exports =
class Terminal

  constructor: ({@view,prompt,commands,commandNotFound}={}) ->
    # assign default values to the root scope attributes
    prompt ?= ''
    commands ?= {}
    commandNotFound ?= (input) -> @writeLn("#{input}: command not found")

    # @history = []
    @scopes = []
    @handlers =
      'did-enter-input': []

    # enter the root scope
    @enterScope
      prompt: prompt
      commands: commands
      commandNotFound: commandNotFound

    # create the inital terminal line
    @newLine()

  ## ---------------------------------------------------------------------------

  newLine: (prompt=@prompt) ->
    # @history.push(@activeLineOutput+@activeLineInput)
    @activeLineOutput = ''
    @activeLineInput = ''
    @activeLineInputCursorPos = 0
    @promptIsActive = false
    @newLineInView()
    @inputHistoryIndex = -1

    if prompt
      @activeLineOutput = "#{prompt} "
      @promptIsActive = true
      @updateActiveLineInView()

  addStringToOutput: (string) ->
    if @promptIsActive
      @activeLineOutput = ''
      @promptIsActive = false
    @activeLineOutput += string
    @updateActiveLineInView()

  addStringToInput: (string) ->
    prefix = @activeLineInput.slice(0,@activeLineInputCursorPos)
    suffix = @activeLineInput.substr(@activeLineInputCursorPos)
    @activeLineInput = prefix + string + suffix
    @activeLineInputCursorPos += string.length
    @updateActiveLineInView()

  removeCharFromInput: ->
    unless @activeLineInputCursorPos is 0
      prefix = @activeLineInput.slice(0,@activeLineInputCursorPos-1)
      suffix = @activeLineInput.substr(@activeLineInputCursorPos)
      @activeLineInput = prefix + suffix
      @activeLineInputCursorPos--
      @updateActiveLineInView()

  ## Browsing the input history ------------------------------------------------

  showPreviousInput: ->
    if @inputHistoryIndex < @inputHistory.length - 1
      @inputHistoryIndex++
      @activeLineInput = @inputHistory[@inputHistoryIndex]
      @activeLineInputCursorPos = @activeLineInput.length
      @updateActiveLineInView()

  showSubsequentInput: ->
    switch
      when @inputHistoryIndex == 0
        @activeLineInput = ''
        @activeLineInputCursorPos = 0
        @inputHistoryIndex--
        @updateActiveLineInView()
      when @inputHistoryIndex > 0
        @activeLineInput = @inputHistory[@inputHistoryIndex-1]
        @activeLineInputCursorPos = @activeLineInput.length
        @inputHistoryIndex--
        @updateActiveLineInView()

  ## Moving the input cursor ---------------------------------------------------

  moveInputCursorLeft: ->
    if @activeLineInputCursorPos > 0
      @activeLineInputCursorPos--
      @updateActiveLineInView()

  moveInputCursorRight: ->
    if @activeLineInputCursorPos < @activeLineInput.length
      @activeLineInputCursorPos++
      @updateActiveLineInView()

  ## Entering the current input ------------------------------------------------

  enterInput: ->
    input = @activeLineInput.trim()
    @newLine()
    handler(input) for handler in @handlers['did-enter-input']
    if input
      @inputHistory.unshift(input) unless @inputHistory[0] is input
      if Object.keys(@commands).length isnt 0
        if (command = @commands[input])?
          command()
        else
          @commandNotFound(input)

  ## Useful interface methods --------------------------------------------------

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

  ## Attaching and detaching event handlers ------------------------------------

  on: (event,handler) ->
    @handlers[event].push(handler)

  off: (event) ->
    if event?
      @handlers[event] = [] if @handlers[event]?
    else
      @handlers[event] = [] for event of @handlers

  ## Updating the view ---------------------------------------------------------

  newLineInView: ->
    @view?.newLine()

  updateActiveLineInView: ->
    @view?.updateActiveLine
      output: @activeLineOutput
      input: @activeLineInput
      inputCursorPos: @activeLineInputCursorPos

# ------------------------------------------------------------------------------
