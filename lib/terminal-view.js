'use babel';

import {CompositeDisposable} from 'atom';

export default class TerminalView {
  constructor(terminal) {
    this.terminal = terminal;

    this.element = document.createElement('div');
    this.element.className = 'terminal';

    this.cursor = document.createElement('div');
    this.cursor.className = 'cursor';
    this.cursor.innerHTML = '&nbsp;';
    this.element.appendChild(this.cursor);

    this.lineHeight = this.terminal.getLineHeight();
    this.charWidth = this.terminal.getCharWidth();
    this.cursorRowIndex = 0;
    this.cursorColIndex = 0;
    this.activeLineIndex = -1;
    this.waitingForTypedMessage = false;

    this.terminalSubscriptions = new CompositeDisposable();
    this.terminalSubscriptions.add(this.terminal.observeIsVisible(visible => this.updateOnDidChangeIsVisible(visible)));
    this.terminalSubscriptions.add(this.terminal.observeSize(size => this.updateOnDidChangeSize(size)));
    this.terminalSubscriptions.add(this.terminal.observeFontSize(fontSize => this.updateOnDidChangeFontSize(fontSize)));
    this.terminalSubscriptions.add(this.terminal.onDidFocus(() => this.activeLine.focus()));
    this.terminalSubscriptions.add(this.terminal.onDidScrollToTop(() => {
      this.element.scrollTop = 0;
    }));
    this.terminalSubscriptions.add(this.terminal.onDidScrollToBottom(() => {
      this.element.scrollTop = this.element.scrollHeight;
    }));
    this.terminalSubscriptions.add(this.terminal.onDidCreateNewLine(() => this.updateOnDidCreateNewLine()));
    this.terminalSubscriptions.add(this.terminal.onDidUpdateActiveLine(activeLine => this.updateOnDidUpdateActiveLine(activeLine)));
    this.terminalSubscriptions.add(this.terminal.onDidClear(() => this.updateOnDidClear()));
    this.terminalSubscriptions.add(this.terminal.onDidStartReadingTypedMessage(() => this.didStartReadingTypedMessage()));
    this.terminalSubscriptions.add(this.terminal.onDidStopReadingTypedMessage(() => this.didStopReadingTypedMessage()));
    this.terminalSubscriptions.add(this.terminal.onDidReadTypedMessage(typedMessage => this.didReadTypedMessage(typedMessage)));
  }

  destroy() {
    this.terminalSubscriptions.dispose();
  }

  moveCursorAbsolute(rowIndex, colIndex) {
    this.moveCursorAbsoluteInRow(colIndex);
    this.moveCursorAbsoluteInCol(rowIndex);
  }

  moveCursorAbsoluteInRow(cursorColIndex) {
    this.cursorColIndex = cursorColIndex;
    const left = this.cursorColIndex * this.charWidth;
    this.cursor.style.left = `${left}px`;
  }

  moveCursorAbsoluteInCol(cursorRowIndex) {
    this.cursorRowIndex = cursorRowIndex;
    const top = this.cursorRowIndex * this.lineHeight;
    this.cursor.style.top = `${top}px`;
  }

  moveCursorRelative(rowOffset, colOffset) {
    this.moveCursorRelativeInRow(colOffset);
    this.moveCursorRelativeInCol(rowOffset);
  }

  moveCursorRelativeInRow(colOffset) {
    this.cursorColIndex += colOffset;
    const left = this.cursorColIndex * this.charWidth;
    this.cursor.style.left = `${left}px`;
  }

  moveCursorRelativeInCol(rowOffset) {
    this.cursorRowIndex += rowOffset;
    const top = this.cursorRowIndex * this.lineHeight;
    this.cursor.style.top = `${top}px`;
  }

  show() {
    this.element.style.display = '';
  }

  hide() {
    this.element.style.display = 'none';
  }

  updateOnDidChangeIsVisible(visible) {
    if (visible) {
      this.show();
    } else {
      this.hide();
    }
  }

  updateOnDidChangeSize(size) {
    this.size = size;
    this.element.style.height = `${this.size * this.lineHeight}px`;
  }

  updateOnDidChangeFontSize(fontSize) {
    this.lineHeight = this.terminal.getLineHeight();
    this.charWidth = this.terminal.getCharWidth();

    this.element.style.fontSize = `${fontSize}px`;
    this.element.style.lineHeight = `${this.lineHeight}px`;
    this.element.style.height = `${this.size * this.lineHeight}px`;

    this.cursor.style.height = `${this.lineHeight}px`;
    this.cursor.style.width = `${this.charWidth}px`;
    this.moveCursorAbsolute(this.cursorRowIndex, this.cursorColIndex);
  }

  updateOnDidCreateNewLine() {
    if (!this.waitingForTypedMessage) {
      this.activeLine = document.createElement('div');
      this.activeLine.className = 'line';
      this.activeLine.innerHTML = '&nbsp;';
      this.element.appendChild(this.activeLine);

      this.activeLineIndex++;
      this.moveCursorAbsolute(this.activeLineIndex, 0);
      this.element.scrollTop = this.element.scrollHeight;

      const contentLimit = atom.config.get('levels.terminalSettings.terminalContentLimit');
      if (contentLimit > 0 && contentLimit <= this.activeLineIndex) {
        this.terminal.clear();
      }
    }
  }

  updateOnDidUpdateActiveLine({input, output, inputCursorPos}) {
    if (!this.waitingForTypedMessage) {
      this.activeLine.textContent = output + input;
      this.activeLine.innerHTML += '&nbsp;';
      this.moveCursorAbsoluteInRow(output.length + inputCursorPos);
    }
  }

  updateOnDidClear() {
    this.element.innerHTML = '';
    this.element.appendChild(this.cursor);
    this.element.appendChild(this.activeLine);
    this.moveCursorRelative(-this.activeLineIndex, 0);
    this.activeLineIndex = 0;
  }

  didStartReadingTypedMessage() {
    this.waitingForTypedMessage = true;
  }

  didStopReadingTypedMessage() {
    if (this.waitingForTypedMessage) {
      this.activeLine.innerHTML = '&nbsp;';
      this.waitingForTypedMessage = false;
    }
  }

  didReadTypedMessage(typedMessage) {
    this.waitingForTypedMessage = false;
    this.putTypedMessage(typedMessage);
  }

  putTypedMessage(typedMessage) {
    const headLines = typedMessage.head.split('\n').slice(1, -1).map(line => line.replace(/</g, '&lt;').replace(/>/g, '&gt;'));
    const bodyLines = typedMessage.body.split('\n').slice(1, -1).map(line => line.replace(/</g, '&lt;').replace(/>/g, '&gt;'));
    const id = typedMessage.id;
    const type = typedMessage.type;

    if ((type === 'error' || type === 'warning') && typedMessage.data && typedMessage.data.source) {
      let startTag = '';
      let endTag = '';

      if (typedMessage.data.row) {
        startTag = `<a class="${type}-link" href="#" data-id="${id}" data-row="${typedMessage.data.row}"`;
        if (typedMessage.data.col) {
          startTag += ` data-col="${typedMessage.data.col}"`;
        }
        startTag += '>';
        endTag = '</a>';
      }

      for (let i = 0; i < headLines.length; i++) {
        headLines[i] = `${startTag}${headLines[i]}${endTag}`;
      }
    }

    const headHtmlLines = [];
    for (const line of headLines) {
      headHtmlLines.push(`<span class="text-${type}">${line}</span>`);
    }

    const bodyHtmlLines = [];
    for (const line of bodyLines) {
      bodyHtmlLines.push(`<span class="text-${type}">${line}</span>`);
    }

    const htmlLines = headHtmlLines.concat(bodyHtmlLines);
    for (let i = 0; i < htmlLines.length; i++) {
      this.activeLine.innerHTML = htmlLines[i];
      if (i !== htmlLines.length - 1) {
        this.updateOnDidCreateNewLine();
      }
    }
  }
}