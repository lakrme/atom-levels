'use babel';

export default class ExecutionIssue {
  constructor(levelCodeEditor, {id, type, source, row, column, message}) {
    this.levelCodeEditor = levelCodeEditor;
    this.id = id;
    this.type = type;
    this.source = source;
    this.row = row;
    this.column = column;
    this.message = message;
  }

  getLevelCodeEditor() {
    return this.levelCodeEditor;
  }

  getId() {
    return this.id;
  }

  getType() {
    return this.type;
  }

  getSource() {
    return this.source;
  }

  getRow() {
    return this.row;
  }

  getColumn() {
    return this.column;
  }

  getMessage() {
    return this.message;
  }
}