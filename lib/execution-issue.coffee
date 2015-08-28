{Emitter} = require('atom')

# ------------------------------------------------------------------------------

module.exports =
class ExecutionIssue

  ## Construction and destruction ----------------------------------------------

  constructor: (@levelCodeEditor,{@id,@type,@source,@row,@column,@message}) ->
    @emitter = new Emitter

  destroy: ->
    @emitter.emit('did-destroy')

  ## Event subscrption ---------------------------------------------------------

  onDidDestroy: (callback) ->
    @emitter.on('did-destroy')

  ## Properties ----------------------------------------------------------------

  getLevelCodeEditor: ->
    @levelCodeEditor

  getId: ->
    @id

  getType: ->
    @type

  getSource: ->
    @source

  getRow: ->
    @row

  getColumn: ->
    @column

  getMessage: ->
    @message

# ------------------------------------------------------------------------------
