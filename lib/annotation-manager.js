'use babel';

import AnnotationOverlayView from './annotation-overlay-view';

export default class AnnotationManager {
  constructor(levelCodeEditor) {
    this.levelCodeEditor = levelCodeEditor;
    this.textEditor = this.levelCodeEditor.getTextEditor();
    this.textEditorSubscriptions = {};
    this.markers = {};
  }

  addAnnotationForExecutionIssue(executionIssue) {
    const id = executionIssue.getId();

    const row = executionIssue.getRow() - 1;
    const column = executionIssue.getColumn();
    const col = column ? column - 1 : 0;

    const marker = this.textEditor.markBufferRange([[row, col], [row, Infinity]], {invalidate: 'inside'});
    this.markers[id] = marker;

    this.textEditor.decorateMarker(marker, {type: 'line-number', class: `annotation annotation-${executionIssue.getType()}`});

    const annotationOverlayView = new AnnotationOverlayView(executionIssue);
    this.textEditor.decorateMarker(marker, {type: 'overlay', item: annotationOverlayView, position: 'tail'});

    if (this.textEditor.getCursorBufferPosition().row === row) {
      annotationOverlayView.show();
    } else {
      annotationOverlayView.hide();
    }

    this.textEditorSubscriptions[id] = this.textEditor.onDidChangeCursorPosition(event => {
      if (event.newBufferPosition.row === row) {
        annotationOverlayView.show();
      } else {
        annotationOverlayView.hide();
      }
    });
  }

  removeAnnotationForExecutionIssue(executionIssue) {
    const id = executionIssue.getId();
    this.textEditorSubscriptions[id].dispose();
    delete this.textEditorSubscriptions[id];
    this.markers[id].destroy();
    delete this.markers[id];
  }
}