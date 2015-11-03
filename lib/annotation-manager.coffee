{CompositeDisposable} = require('atom')

AnnotationOverlayView = require('./annotation-overlay-view')

# ------------------------------------------------------------------------------

module.exports =
class AnnotationManager

  ## Construction --------------------------------------------------------------

  constructor: (@levelCodeEditor) ->
    @textEditor = @levelCodeEditor.getTextEditor()
    @textEditorSubscrsByExecutionIssueId = {}
    @markersByExecutionIssueId = {}

  ## Level code editor annotations ---------------------------------------------

  addAnnotationForExecutionIssue: (executionIssue) ->
    type = executionIssue.getType()
    source = executionIssue.getSource()
    row = parseInt(executionIssue.getRow()) - 1
    col = parseInt(executionIssue.getColumn() ? 0) - 1
    message = executionIssue.getMessage()

    # create line marker
    marker = @textEditor.markBufferRange [[row,col],[row,Infinity]],
      invalidate: 'inside'
    @markersByExecutionIssueId[executionIssue.getId()] = marker

    # dye line number
    @textEditor.decorateMarker marker,
      type: 'line-number'
      class: "annotation annotation-#{type}"

    # create annotation overlay
    annotationOverlayView = new AnnotationOverlayView @textEditor, \
      {type,source,row,col,message}
    @textEditor.decorateMarker marker,
      type: 'overlay'
      item: annotationOverlayView
      position: 'tail'
    currentCursorPos = @textEditor.getCursorBufferPosition()
    if currentCursorPos.row is row
      annotationOverlayView.show()
    else
      annotationOverlayView.hide()

    textEditorSubscrs = new CompositeDisposable
    textEditorSubscrs.add @textEditor.onDidChangeCursorPosition (event) ->
      cursorPos = event.newBufferPosition
      if cursorPos.row is row
        annotationOverlayView.show()
      else
        annotationOverlayView.hide()
    @textEditorSubscrsByExecutionIssueId[executionIssue.getId()] = \
      textEditorSubscrs

  removeAnnotationForExecutionIssue: (executionIssue) ->
    executionIssueId = executionIssue.getId()
    @textEditorSubscrsByExecutionIssueId[executionIssueId].dispose()
    delete @textEditorSubscrsByExecutionIssueId[executionIssueId]
    @markersByExecutionIssueId[executionIssueId].destroy()
    delete @markersByExecutionIssueId[executionIssueId]

# ------------------------------------------------------------------------------
