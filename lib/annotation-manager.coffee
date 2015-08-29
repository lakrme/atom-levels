# ------------------------------------------------------------------------------

module.exports =
class AnnotationManager

  ## Construction --------------------------------------------------------------

  constructor: (@levelCodeEditor) ->
    @textEditor = @levelCodeEditor.getTextEditor()
    @markersByExecutionIssueId = {}

  ## Level code editor annotations ---------------------------------------------

  addAnnotationForExecutionIssue: (executionIssue) ->
    type = executionIssue.getType()
    source = executionIssue.getSource()
    row = parseInt(executionIssue.getRow()) - 1
    col = parseInt(executionIssue.getColumn() ? 0) - 1
    message = executionIssue.getMessage()

    marker = @textEditor.markBufferRange [[row,col],[row,Infinity]],
      invalidate: 'touch'
    @textEditor.decorateMarker marker,
      type: 'line-number'
      class: "annotation annotation-#{type}"

    @markersByExecutionIssueId[executionIssue.getId()] = marker

  removeAnnotationForExecutionIssue: (executionIssue) ->
    @markersByExecutionIssueId[executionIssue.getId()].destroy()
    delete @markersByExecutionIssueId[executionIssue.getId()]

# ------------------------------------------------------------------------------
