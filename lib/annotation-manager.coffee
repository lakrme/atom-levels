# ------------------------------------------------------------------------------

module.exports =
class AnnotationManager

  ## Construction --------------------------------------------------------------

  constructor: (@levelCodeEditor) ->
    @textEditor = @levelCodeEditor.getTextEditor()
    @markers = []

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

    marker.onDidDestroy => console.log "lol"

    @markers.push(marker)

# ------------------------------------------------------------------------------

  #
  #
  # removeIssueAnnotationsForTextEditor: (textEditor) ->
  #   if (annotations = @textEditorIssueAnnotations[textEditor.id])?
  #     marker.destroy() for marker in annotations
  #     delete @textEditorIssueAnnotations[textEditor.id]
