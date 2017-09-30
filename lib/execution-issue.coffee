{Emitter} = require 'atom'

module.exports =
class ExecutionIssue
  constructor: (@levelCodeEditor, {@id, @type, @source, @row, @column, @message}) ->
    @emitter = new Emitter

  destroy: ->
    @emitter.emit 'did-destroy'
    return

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy'

  getLevelCodeEditor: ->
    return @levelCodeEditor

  getId: ->
    return @id

  getType: ->
    return @type

  getSource: ->
    return @source

  getRow: ->
    return @row

  getColumn: ->
    return @column

  getMessage: ->
    return @message