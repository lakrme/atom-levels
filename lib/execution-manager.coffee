child_process     = require('child_process')
path              = require('path')
_                 = require('underscore-plus')

notificationUtils = require('./notification-utils')

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
      throw {name: 'ExecutionIsAlreadyRunningError'}
    if @terminal.isExecuting()
      throw {name: 'TerminalIsBusyError'}
    unless (executionMode = @language.getExecutionMode())?
      throw {name: 'ExecutionModeNotFoundError'}
    unless (filePath = @textEditor.getPath())?
      throw {name: 'BufferNotSavedError'}

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
    @process = child_process.exec cmd,
      cwd: path.dirname(runPath)
      env: process.env

    # set up process handle subscriptions
    @process.stdout.on 'data', (data) =>
      @terminal.write(data.toString())
    @terminalSubscr = @terminal.onDidEnterInput (input) =>
      @process.stdin.write("#{input}\n")
    @process.on 'close', =>
      @process.stdin.end()
      @process = null
      @terminalSubscr.dispose()
      @terminalSubscr = null
      @terminal.exitScope()
      @terminal.didStopExecution()
      @levelCodeEditor.didStopExecution()

    # notify terminal and level code editor
    @terminal.enterScope()
    @terminal.didStartExecution()
    @levelCodeEditor.didStartExecution()

  stopExecution: ->
    if @isExecuting()
      switch process.platform
        when 'darwin' then @killProcessOnDarwinAndLinux(@process.pid)
        when 'linux'  then @killProcessOnDarwinAndLinux(@process.pid)
        when 'win32'  then @killProcessOnWin32(@process.pid)
        # else
        #   # FIXME on OS X and Linux this only kills the sh root process but not the
        #   # child processes (primarily the run process); therefore the close event
        #   # will not be emitted until the run process is killed manually
        #   # @process.kill()
        #   message =
        #     'Unfortunately, this functionality is not yet supported.\nAt the moment
        #     execution can only be stopped by killing the process manually.\n \nThis
        #     will be fixed in a future release.'
        #   notificationUtils.addWarning message,
        #     head: 'Sorry! This is not yet supported!'
        #     important: true
        #   # -----------------------------------------------------------------------

  killProcessOnDarwinAndLinux: (parentPid) ->
    # get child process IDs
    try
      out = child_process.execSync("pgrep -P #{parentPid}",{env: process.env})
      childPids = _.filter _.map(out.toString().split('\n'),parseInt), (pid) ->
        not isNaN(pid)
    catch error
      # execSync returns an error if the process has no childs, so we ignore
      # this error here and continue with an empty childPids array
      childPids = []

    # recursively kill child processes
    for childPid in childPids
      @killProcessOnDarwinAndLinux(childPid)

    # kill parent process
    process.kill(parentPid)

  # NOTE stolen from Atom's BufferedNodeProcess API (Oops!)
  killProcessOnWin32: (parentPid) ->
    try
      wmicProcess = child_process.spawn 'wmic', [
        'process'
        'where'
        "(ParentProcessId=#{parentPid})"
        'get'
        'processid'
      ]
      out = ''
      wmicProcess.stdout.on 'data', (data) ->
        out += data
      wmicProcess.stdout.on 'close', ->
        # get child process pids
        childPids = out.split(/\s+/)
                      .filter (pid) -> /^\d+$/.test(pid)
                      .map (pid) -> parseInt(pid)
                      .filter (pid) -> pid isnt parentPid and 0 < pid < Infinity
        # recursively kill child processes
        for childPid in childPids
          @killProcessOnWin32(childPid)
        # kill parent process
        process.kill(parentPid)
    catch error
      # TODO show proper error notification here
      console.log("Spawn error")
      # ----------------------------------------

# ------------------------------------------------------------------------------
