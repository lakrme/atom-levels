exec = require('child_process').exec
path = require('path')

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
    runPath = @language.getExecutablePath()

    if @isExecuting()
      throw new Error
        name: 'ExecutionNotPossibleError'
        message: ''
    if @terminal.isExecuting()
      throw new Error
        name: 'ExecutionError'
        message: 'Execution is already running.'
    unless (executionMode = @language.getExecutionMode())?
      throw new Error
        name: 'ExecutionError'
        message: ''
    unless (filePath = @textEditor.getPath())?
      throw new Error
        name: 'ExecutionError'
        message: ''

    @terminal.writeLn('Running level code...')

    # build command
    cmd = [
      "#{runPath}"
      '-m',"#{executionMode}"
      "#{@level.getNumber()}"
      "#{filePath}"
      '2>&1'
    ].join(' ')

    # spawn the child process
    @process = exec cmd,
      cwd: path.dirname(runPath)
      env: process.env

    # set up process handle subscriptions
    @process.stdout.on 'data', (data) =>
      @terminal.write(data.toString())
    @terminalSubscr = @terminal.onDidEnterInput (input) =>
      @process.stdin.write("#{input}\n")
    @process.on 'close', =>
      @didStopExecution()
    @didStartExecution()

  didStartExecution: ->
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
