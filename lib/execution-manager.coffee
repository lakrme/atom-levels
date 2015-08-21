{Emitter} = require('atom')

# ------------------------------------------------------------------------------

class ExecutionManager

  ## Construction --------------------------------------------------------------

  constructor: ->
    @emitter = new Emitter

  ## Event subscription --------------------------------------------------------

  onDidStartExecution: (callback) ->
    @emitter.on('did-start-execution',callback)

  onDidStopExecution: (callback) ->
    @emitter.on('did-stop-execution',callback)

  ## Level code execution ------------------------------------------------------

  startExecution: (levelCodeEditor) ->
    terminal = levelCodeEditor.getTerminal()
    # unless terminal.isExecuting()
    #   terminal.setIsExe
    #
    #   textEditor = levelCodeEditor.getTextEditor()
    #   language = levelCodeEditor.getLanguage()
    #   level = levelCodeEditor.getLevel()
    #



  stopExecution: (levelCodeEditor) ->

# ------------------------------------------------------------------------------

module.exports =
class ExecutionManagerProvider

  instance = null

  @getInstance: ->
    instance ?= new ExecutionManager

# ------------------------------------------------------------------------------
