module.exports =
class ExecutionIssue
  constructor: (@levelCodeEditor, {@id, @type, @source, @row, @column, @message}) ->

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