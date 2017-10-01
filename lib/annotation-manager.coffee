AnnotationOverlayView = require './annotation-overlay-view'

module.exports =
class AnnotationManager
  constructor: (@levelCodeEditor) ->
    @textEditor = @levelCodeEditor.getTextEditor()
    @textEditorSubscriptionsByExecutionIssueId = {}
    @markersByExecutionIssueId = {}

  addAnnotationForExecutionIssue: (executionIssue) ->
    type = executionIssue.getType()
    source = executionIssue.getSource()
    row = parseInt(executionIssue.getRow()) - 1
    col = parseInt(executionIssue.getColumn() ? 0) - 1
    message = executionIssue.getMessage()

    marker = @textEditor.markBufferRange [[row, col], [row, Infinity]], invalidate: 'inside'
    @markersByExecutionIssueId[executionIssue.getId()] = marker

    @textEditor.decorateMarker marker, {type: 'line-number', class: "annotation annotation-#{type}"}

    annotationOverlayView = new AnnotationOverlayView {type, source, row, col, message}
    @textEditor.decorateMarker marker, {type: 'overlay', item: annotationOverlayView, position: 'tail'}

    if @textEditor.getCursorBufferPosition().row == row
      annotationOverlayView.show()
    else
      annotationOverlayView.hide()

    @textEditorSubscriptionsByExecutionIssueId[executionIssue.getId()] = @textEditor.onDidChangeCursorPosition (event) ->
      if event.newBufferPosition.row == row
        annotationOverlayView.show()
      else
        annotationOverlayView.hide()

    return

  removeAnnotationForExecutionIssue: (executionIssue) ->
    executionIssueId = executionIssue.getId()
    @textEditorSubscriptionsByExecutionIssueId[executionIssueId].dispose()
    delete @textEditorSubscriptionsByExecutionIssueId[executionIssueId]
    @markersByExecutionIssueId[executionIssueId].destroy()
    delete @markersByExecutionIssueId[executionIssueId]

    return