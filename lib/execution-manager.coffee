{Disposable}      = require('atom')
child_process     = require('child_process')
path              = require('path')
_                 = require('underscore-plus')

# ------------------------------------------------------------------------------

module.exports =
class ExecutionManager

  ## Construction --------------------------------------------------------------

  constructor: (@levelCodeEditor) ->

  ## Level code execution ------------------------------------------------------

  isExecuting: ->
    @executing

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

    @executing = true
    @processExited = false
    @processClosed = false

    configKeyPath = 'levels.workspaceSettings.clearTerminalOnExecution'
    @terminal.clear() if atom.config.get(configKeyPath)
    @terminal.writeLn('Running level code...')

    # build command
    cmd = [
      runPath
      '-l',"#{@language.getConfigurationFilePath()}"
      '-m',"#{executionMode}"
      "#{@level.getNumber()}"
      "#{filePath}"
      '2>&1'
    ].join(' ')

    # spawn the child process and set up handlers
    @process = child_process.exec cmd,
      cwd: path.dirname(runPath)
      env: process.env
    @process.stdout.on 'data', (data) =>
      @handleProcessData(data)
    @terminalSubscr = @terminal.onDidEnterInput (input) =>
      @process.stdin.write("#{input}\n")
    @process.on 'exit', (code,signal) =>
      @handleProcessExit(code,signal)
    @process.on 'close', (code,signal) =>
      @handleProcessClose(code,signal)

    # notify terminal and level code editor
    @terminal.enterScope()
    @terminal.didStartExecution()
    @levelCodeEditor.didStartExecution()

  stopExecution: ->
    if @isExecuting()
      if @processExited
        @dataWriter?.dispose()
        @executing = false
        @terminalSubscr.dispose()
        @terminal.exitScope()
        @terminal.didStopExecution()
        @levelCodeEditor.didStopExecution()
      else
        switch process.platform
          when 'darwin' then @killProcessOnDarwinAndLinux(@process.pid)
          when 'linux'  then @killProcessOnDarwinAndLinux(@process.pid)
          when 'win32'  then @killProcessOnWin32(@process.pid)

  ## Process event handling ----------------------------------------------------

  handleProcessData: (data) ->
    @process.stdout.pause()
    lines = data.toString().split('\n')
    console.log lines
    @dataWriter = @writeDataLines(lines)

  writeDataLines: (lines) ->
    intervalId = setInterval =>
      if lines.length is 1
        lastLine = lines.shift()
        @writeDataLine(lastLine) if lastLine
        @dataWriter.dispose()
        unless @process?
          console.log 'execution stopped'
          @terminalSubscr.dispose()
          @terminal.exitScope()
          @terminal.didStopExecution()
          @executing = false
          @levelCodeEditor.didStopExecution()
        else
          @process.stdout.resume()
      else
        @writeDataLine(lines.shift())
        @terminal.newLine()
    ,10
    new Disposable(-> clearInterval(intervalId))

  writeDataLine: (line) ->
    @terminal.write(line)

  handleProcessExit: (code,signal) ->
    console.log "exit with signal #{signal}"
    @processExited = true
    # @dataWriter?.dispose()
    # @stdoutTerminalPipe.dispose()
    # data = @process.stdout.read()
    # console.log data?.toString()
    # # while not @closed
    # #   console.log 'here'
    # #   data = @process.stdout.read(64)
    # #   console.log data.toString() if data?
    # #   @terminal.write(data.toString()) if data?
    # @destroyReadableStream(@process.stdout) if signal is 'SIGINT'

  handleProcessClose: (code,signal) ->
    @process.stdin.end()
    @process = null
    console.log 'process closed'

  ## Killing processes ---------------------------------------------------------

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
    try process.kill(parentPid,'SIGINT')

  # NOTE stolen from Atom's BufferedProcess API (Oops!)
  killProcessOnWin32: (parentPid) ->
    try
      wmicProcess = child_process.spawn 'wmic', [
        'process','where',"(ParentProcessId=#{parentPid})",'get','processid'
      ]
      out = ''
      wmicProcess.stdout.on 'data', (data) ->
        out += data
      wmicProcess.stdout.on 'close', =>
        # get child process pids
        childPids = out.split(/\s+/)
                      .filter (pid) -> /^\d+$/.test(pid)
                      .map    (pid) -> parseInt(pid)
                      .filter (pid) -> pid isnt parentPid and 0 < pid < Infinity
        # recursively kill child processes
        for childPid in childPids
          @killProcessOnWin32(childPid)
        # kill parent process
        try process.kill(parentPid,'SIGINT')
    catch error
      # TODO show proper error notification here
      console.log("Spawn error!")
      # ----------------------------------------

# ------------------------------------------------------------------------------
