{Emitter} = require 'atom'
path      = require 'path'
exec      = require('child_process').exec

Terminal     = require './models-terminal'
TerminalView = require './views-terminal-view'

# ------------------------------------------------------------------------------

module.exports =
class ExecutionManager

  instance = null

  @getInstance: ->
    instance ?= new ExecutionManager

  initialize: ->
    @idCounter = 0
    @terminalInstance = @newTerminal()
    @emitter = new Emitter

  getTerminalInstance: ->
    @terminalInstance

  ## Creating associated terminal instances ------------------------------------

  newTerminal: ->
    ViewManager  = require './core-view-manager'
    @viewManager = ViewManager.getInstance()
    terminalView = new TerminalView(@viewManager)
    terminal = new Terminal
      view: terminalView
      prompt: 'Levels>'
      commands:
        'clear': ->
          terminalView.clear()
        'run': ->
          workspaceView = atom.views.getView(atom.workspace)
          atom.commands.dispatch(workspaceView,"levels:start-execution")

    # TODO move additional attributes and functions to mixin
    terminal.id = @idCounter++
    terminal.isExecuting = false

    terminal.writeTypedMessage = (head,body,{type,icon,data}={}) ->
      if head or body
        type ?= "normal"
        startTag = ''
        endTag = ''
        headElem = ''
        bodyElem = ''
        if type isnt 'normal' or icon or data?
          startTag  = "<message type=\"#{type}\""
          startTag += " icon=\"#{icon}\""          if icon
          startTag += " data-#{key}=\"#{value}\""  for key,value of data
          startTag += '>\n'
          headElem  = "<head>\n#{head}\n</head>\n" if head
          bodyElem  = "<body>\n#{body}\n</body>\n" if body
          endTag    = "</message>\n"
        typedMessage = startTag + headElem + bodyElem + endTag
        @write(typedMessage)

    terminal.writeSubtleMessage = (head,body) ->
      @writeTypedMessage(head,body,{type: 'subtle'})

    terminal.writeInfoMessage = (head,body,{icon}={}) ->
      @writeTypedMessage(head,body,{type: 'info',icon})

    terminal.writeSuccessMessage = (head,body,{icon}={}) ->
      @writeTypedMessage(head,body,{type: 'success',icon})

    terminal.writeWarningMessage = (head,body,{icon,row,col}={}) ->
      data = {}
      data.row = row if row
      data.col = col if row and col
      @writeTypedMessage(head,body,{type: 'warning',icon,data})

    terminal.writeErrorMessage = (head,body,{icon,row,col}={}) ->
      data = {}
      data.row = row if row
      data.col = col if row and col
      @writeTypedMessage(head,body,{type: 'error',icon,data})

    terminal.commands['topkek'] = ->
      terminal.writeSuccessMessage "", """
         _              _        _
        | |            | |      | |
        | |_ ___  _ __ | | _____| | __
        | __/ _ \\| '_ \\| |/ / _ \\ |/ /
        | || (_) | |_) |   <  __/   <
         \\__\\___/| .__/|_|\\_\\___|_|\\_\\
                 | |
                 |_|

        """

    terminal.writeInfoMessage(' Welcome to the Levels terminal!','',{icon: 'info'})
    terminal

  ## Events --------------------------------------------------------------------

  onDidStopExecution: (callback) ->
    @emitter.on('did-stop-execution',callback)

  ## Executing level code ------------------------------------------------------

  startExecution: (textEditor,{language,level}) ->
    unless @terminalInstance.isExecuting
      @terminalInstance.isExecuting = true

      filePath = textEditor.getPath()

      @terminalInstance.enterScope()

      runExecPath = path.join(language.dirPath,'run')
      runExecPath = runExecPath.replace(/\s/g,'\\ ')
      runExecPath = runExecPath.replace(/\(/g,'\\(')
      runExecPath = runExecPath.replace(/\)/g,'\\)')
      cmd = [runExecPath,'-v',"#{level.id}","\"#{filePath}\"",'2>&1'].join(' ')
      @childProcess = exec cmd,
        cwd: language.dirPath
        env: process.env

      # initializing process handle subscriptions
      @childProcess.stdout.on 'data', (data) =>
        dataStr = data.toString()
        @terminalInstance.write(dataStr)

      @terminalInstance.on 'did-enter-input', (input) =>
        @childProcess.stdin.write("#{input}\n")

      @childProcess.on 'close', (exit) =>
        @childProcess.stdin.end()

        @emitter.emit('did-stop-execution')

        @terminalInstance.isExecuting = false
        @terminalInstance.exitScope()
        @terminalInstance.off('did-enter-input')

  stopExecution: (textEditor,languageData,controlPanelView) ->
    if @terminalInstance.isExecuting

      # NOTE does not work yet (does not kill the interpreter subprocess)
      exec("kill -#{@childProcess.pid}")

      @emitter.emit('did-stop-execution')

      @terminalInstance.isExecuting = false
      @terminalInstance.exitScope()
      @terminalInstance.off('did-enter-input')

  ## For testing purposes ------------------------------------------------------

  handleKeyEvent: (terminal,event) ->
    switch event.keyCode
      when 8
        terminal.removeCharFromInput()
      when 13
        terminal.enterInput()
      when 32
        terminal.addStringToInput(' ')
      when 37
        terminal.moveInputCursorLeft()
      when 38
        terminal.showPreviousInput()
      when 39
        terminal.moveInputCursorRight()
      when 40
        terminal.showSubsequentInput()
      when 65
        terminal.addStringToInput('a')
      when 66
        terminal.addStringToInput('b')
      when 67
        terminal.addStringToInput('c')
      when 68
        terminal.addStringToInput('d')
      when 69
        terminal.addStringToInput('e')
      when 70
        terminal.addStringToInput('f')
      when 71
        terminal.addStringToInput('g')
      when 72
        terminal.addStringToInput('h')
      when 73
        terminal.addStringToInput('i')
      when 74
        terminal.addStringToInput('j')
      when 75
        terminal.addStringToInput('k')
      when 76
        terminal.addStringToInput('l')
      when 77
        terminal.addStringToInput('m')
      when 78
        terminal.addStringToInput('n')
      when 79
        terminal.addStringToInput('o')
      when 80
        terminal.addStringToInput('p')
      when 81
        terminal.addStringToInput('q')
      when 82
        terminal.addStringToInput('r')
      when 83
        terminal.addStringToInput('s')
      when 84
        terminal.addStringToInput('t')
      when 85
        terminal.addStringToInput('u')
      when 86
        terminal.addStringToInput('v')
      when 87
        terminal.addStringToInput('w')
      when 88
        terminal.addStringToInput('x')
      when 89
        terminal.addStringToInput('y')
      when 90
        terminal.addStringToInput('z')

# ------------------------------------------------------------------------------
