{Disposable}      = require('atom')
child_process     = require('child_process')
path              = require('path')
_                 = require('underscore-plus')

# ------------------------------------------------------------------------------

module.exports =
class ExecutionManager

  ## Construction --------------------------------------------------------------

  constructor: (@levelCodeEditor) ->
    @executing = false

  ## Level code execution ------------------------------------------------------

  isExecuting: ->
    @executing

  startExecution: ->
    @textEditor = @levelCodeEditor.getTextEditor()
    @language = @levelCodeEditor.getLanguage()
    @level = @levelCodeEditor.getLevel()
    @terminal = @levelCodeEditor.getTerminal()

    return if @isExecuting() or @terminal.isExecuting()

    configKeyPath = 'levels.workspaceSettings.clearTerminalOnExecution'
    @terminal.clear() if atom.config.get(configKeyPath)
    @terminal.writeLn('Running level code...')

    runExecPath = @language.getRunExecPath()
    configFilePath = @language.getConfigFilePath()
    levelNumber = @level.getNumber()
    filePath = @textEditor.getPath()
    cmd = [
      "\"#{runExecPath}\""
      '-l',"\"#{configFilePath}\""
      "#{levelNumber}"
      "\"#{filePath}\""
      '2>&1'
    ].join(' ')

    @processExited = false
    @processClosed = false

    # spawn child process and set up handlers
    @process = child_process.exec cmd,
      cwd: path.dirname(runExecPath)
      env: process.env
    @terminalSubscr = @terminal.onDidEnterInput (input) =>
      @process.stdin.write("#{input}\n")
    @process.stdout.on('data',@handleProcessData)
    @process.on('exit',@handleProcessExit)
    @process.on('close',@handleProcessClose)
    @executionStarted()

  stopExecution: ->
    return unless @isExecuting()
    @executionStoppedByUser = true
    @process.stdout.removeListener('data',@handleProcessData)
    @activeDataWriter?.dispose()
    unless @processExited
      @killProcess(@process.pid)
    unless @processClosed
      @process.stdout.read()
      @process.stdout.destroy()

  executionStarted: ->
    @executing = true
    @terminal.enterScope()
    @terminal.didStartExecution()
    @levelCodeEditor.didStartExecution()

  executionStopped: ->
    @executing = false
    @terminal.exitScope()
    @terminal.didStopExecution()
    @levelCodeEditor.didStopExecution()
    if @executionStoppedByUser
      @executionStoppedByUser = false
      @terminal.writeLn('...')
      @terminal.writeSubtle('Execution stopped!')

  ## Process event handling ----------------------------------------------------

  handleProcessData: (data) =>
    @process.stdout.pause()
    lines = data.toString().split('\n')
    @activeDataWriter = @writeDataLines(lines)

  handleProcessExit: (code,signal) =>
    @processExited = true

  handleProcessClose: (code,signal) =>
    @terminalSubscr.dispose()
    @process.stdin.end()
    @processClosed = true
    @executionStopped() unless @activeDataWriter?

  ## Writing data to the terminal ----------------------------------------------

  writeDataLines: (lines) ->
    intervalId = setInterval =>
      if lines.length is 1
        lastLine = lines.shift()
        @writeDataLine(lastLine) if lastLine
        @activeDataWriter.dispose()
        @process.stdout.resume()
      else
        @writeDataLine(lines.shift())
        @terminal.newLine()
    ,10
    new Disposable =>
      clearInterval(intervalId)
      @activeDataWriter = null
      @executionStopped() if @processClosed

  writeDataLine: (line) ->
    @terminal.write(line)

  ## Killing processes ---------------------------------------------------------

  killProcess: (pid) ->
    switch process.platform
      when 'darwin' then @killProcessOnDarwinAndLinux(pid)
      when 'linux'  then @killProcessOnDarwinAndLinux(pid)
      when 'win32'  then @killProcessOnWin32(pid)

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
