{Disposable}  = require 'atom'
child_process = require 'child_process'
path          = require 'path'

module.exports =
class ExecutionManager
  constructor: (@levelCodeEditor) ->
    @executing = false

  isExecuting: ->
    return @executing

  startExecution: ({runExecArgs} = {}) ->
    @terminal = @levelCodeEditor.getTerminal()

    if @isExecuting() || @terminal.isExecuting()
      return

    @textEditor = @levelCodeEditor.getTextEditor()
    @language = @levelCodeEditor.getLanguage()
    @level = @levelCodeEditor.getLevel()

    configKeyPath = 'levels.workspaceSettings.clearTerminalOnExecution'
    if atom.config.get configKeyPath
      @terminal.clear()

    @terminal.writeLn 'Running level code …'

    runExecPath = @language.getExecutablePath()
    configFilePath = @language.getConfigFilePath()
    levelNumber = @level.getNumber() - 1
    filePath = @textEditor.getPath()

    cmd = ([
      "\"#{runExecPath}\""
      '-l', "\"#{configFilePath}\""
    ].concat(runExecArgs).concat [
      "#{levelNumber}"
      "\"#{filePath}\""
      '2>&1'
    ]).join(' ')

    @processExited = false
    @processClosed = false

    @process = child_process.exec cmd, {cwd: path.dirname runExecPath, env: process.env}
    @terminalSubscription = @terminal.onDidEnterInput (input) => @process.stdin.write "#{input}\n"
    @process.stdout.on 'data', @handleProcessData
    @process.on 'exit', @handleProcessExit
    @process.on 'close', @handleProcessClose
    @executionStarted()

    return

  stopExecution: ->
    if !@isExecuting()
      return

    @executionStoppedByUser = true
    @process.stdout.removeListener 'data', @handleProcessData
    @activeDataWriter?.dispose()
    if !@processExited
      @killProcess @process.pid
    if !@processClosed
      @process.stdout.read()
      @process.stdout.destroy()

    return

  executionStarted: ->
    @executing = true
    @terminal.enterScope()
    @terminal.didStartExecution()
    @levelCodeEditor.didStartExecution()
    return

  executionStopped: ->
    @executing = false
    @terminal.exitScope()
    @terminal.didStopExecution()
    @levelCodeEditor.didStopExecution()
    if @executionStoppedByUser
      @executionStoppedByUser = false
      @terminal.writeLn '…'
      @terminal.writeSubtle 'Execution stopped!'
    return

  handleProcessData: (data) =>
    @process.stdout.pause()
    lines = data.toString().split '\n'
    @activeDataWriter = @writeDataLines lines
    return

  handleProcessExit: (code, signal) =>
    @processExited = true
    return

  handleProcessClose: (code, signal) =>
    @terminalSubscription.dispose()
    @process.stdin.end()
    @processClosed = true
    if !@activeDataWriter
      @executionStopped()
    return

  writeDataLines: (lines) ->
    intervalId = setInterval =>
      if lines.length == 1
        lastLine = lines.shift()
        if lastLine
          @writeDataLine lastLine
        @activeDataWriter.dispose()
        @process.stdout.resume()
      else if lines.length > 1
        @writeDataLine lines.shift()
        @terminal.newLine()
    , 10
    new Disposable =>
      clearInterval intervalId
      @activeDataWriter = null
      if @processClosed
        @executionStopped()

  writeDataLine: (line) ->
    @terminal.write line
    return

  killProcess: (pid) ->
    switch process.platform
      when 'darwin' then @killProcessOnDarwinAndLinux pid
      when 'linux'  then @killProcessOnDarwinAndLinux pid
      when 'win32'  then @killProcessOnWin32 pid

  killProcessOnDarwinAndLinux: (parentPid) ->
    try
      out = child_process.execSync "pgrep -P #{parentPid}", {env: process.env}
      childPids = out.toString().split('\n')
                    .map (pid) -> parseInt pid
                    .filter (pid) -> not isNaN pid
    catch error
      childPids = []
    for childPid in childPids
      @killProcessOnDarwinAndLinux childPid
    try process.kill parentPid, 'SIGINT'

    return

  killProcessOnWin32: (parentPid) ->
    try
      wmicProcess = child_process.spawn 'wmic', [
        'process', 'where', "(ParentProcessId=#{parentPid})", 'get', 'processid'
      ]
      out = ''
      wmicProcess.stdout.on 'data', (data) -> out += data
      wmicProcess.stdout.on 'close', =>
        childPids = out.split(/\s+/)
                      .filter (pid) -> /^\d+$/.test pid
                      .map (pid) -> parseInt pid
                      .filter (pid) -> pid != parentPid && 0 < pid < Infinity
        for childPid in childPids
          @killProcessOnWin32 childPid
        try process.kill parentPid, 'SIGINT'
    return