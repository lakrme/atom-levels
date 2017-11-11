'use babel';

export default class AnnotationOverlayView {
  constructor({type, source, row, col, message}) {
    this.element = document.createElement('div');
    this.element.className = 'levels-view annotation-overlay';
    this.element.style.display = 'none';

    this.headerDiv = document.createElement('div');
    this.headerDiv.className = 'header';
    this.element.appendChild(this.headerDiv);

    this.typeSpan = document.createElement('span');
    this.typeSpan.className = `type badge badge-flexible badge-${type}`;
    this.typeSpan.textContent = type;
    this.headerDiv.appendChild(this.typeSpan);

    this.positionSpan = document.createElement('span');
    this.positionSpan.className = 'position';
    this.positionSpan.textContent = `at line ${row + 1}${col ? `, column ${col + 1}` : ''}`;
    this.headerDiv.appendChild(this.positionSpan);

    this.sourceSpan = document.createElement('span');
    this.sourceSpan.className = 'source';
    this.sourceSpan.textContent = source;
    this.headerDiv.appendChild(this.sourceSpan);

    this.element.appendChild(document.createElement('hr'));

    this.messageDiv = document.createElement('div');
    this.messageDiv.textContent = message;
    this.element.appendChild(this.messageDiv);
  }

  show() {
    this.element.style.display = '';
  }

  hide() {
    this.element.style.display = 'none';
  }
}