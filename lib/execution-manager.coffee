exec = require('child_process').exec
path  = require('path')

# ------------------------------------------------------------------------------

module.exports =
class ExecutionManager

  ## Construction --------------------------------------------------------------

  constructor: (@levelCodeEditor) ->

  ## Level code execution ------------------------------------------------------

  isExecuting: ->
    @process?

  startExecution: ->
    @textEditor = @levelCodeEditor.getTextEditor()
    @language = @levelCodeEditor.getLanguage()
    @level = @levelCodeEditor.getLevel()
    @terminal = @levelCodeEditor.getTerminal()

    if @isExecuting()
      throw new Error('execution is already running!')
    if @terminal.isExecuting()
      throw new Error('terminal is busy!')
    unless (executionMode = @language.getExecutionMode())?
      throw new Error('no execution mode found!')
    unless (filePath = @textEditor.getPath())?
      throw new Error('file not saved!')

    dirPath = @language.getDirectoryPath()

    # build command
    cmd = [
      "#{path.join(dirPath,'run')}"
      '-v','-r','-m'
      "#{executionMode}"
      "#{@level.getNumber()}"
      "#{filePath}"
      '2>&1'
    ].join(' ')

    # spawn the child process
    @process = exec cmd,
      cwd: dirPath
      env: process.env

    # set up process handle subscriptions
    @process.stdout.on 'data', (data) =>
      @terminal.write(data.toString())
    @terminalSubscr = @terminal.onDidEnterInput (input) =>
      @process.stdin.write("#{input}\n")
    @process.on 'close', =>
      @didStopExecution()

    # enter scope and
    @terminal.enterScope()
    @terminal.didStartExecution()
    @levelCodeEditor.didStartExecution()

  stopExecution: ->
    if @isExecuting()
      # TODO stop execution
      @didStopExecution()

  didStopExecution: ->
    @process.stdin.end()
    @process = null
    @terminalSubscr.dispose()
    @terminalSubscr = null
    @terminal.exitScope()
    @terminal.didStopExecution()
    @levelCodeEditor.didStopExecution()

# ------------------------------------------------------------------------------
