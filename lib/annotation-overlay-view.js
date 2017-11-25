'use babel';

export default class AnnotationOverlayView {
  constructor({type, source, row, column, message}) {
    this.element = document.createElement('div');
    this.element.className = 'levels-view annotation-overlay';
    this.element.style.display = 'none';

    const headerDiv = document.createElement('div');
    headerDiv.className = 'header';
    this.element.appendChild(headerDiv);

    const typeSpan = document.createElement('span');
    typeSpan.className = `type badge badge-flexible badge-${type}`;
    typeSpan.textContent = type;
    headerDiv.appendChild(typeSpan);

    const positionSpan = document.createElement('span');
    positionSpan.className = 'position';
    positionSpan.textContent = `at line ${row}${column ? `, column ${column}` : ''}`;
    headerDiv.appendChild(positionSpan);

    const sourceSpan = document.createElement('span');
    sourceSpan.className = 'source';
    sourceSpan.textContent = source;
    headerDiv.appendChild(sourceSpan);

    this.element.appendChild(document.createElement('hr'));

    const messageDiv = document.createElement('div');
    messageDiv.textContent = message;
    this.element.appendChild(messageDiv);
  }

  show() {
    this.element.style.display = '';
  }

  hide() {
    this.element.style.display = 'none';
  }
}