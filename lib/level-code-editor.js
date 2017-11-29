'use babel';

import {Emitter}           from 'atom';
import AnnotationManager   from './annotation-manager';
import ExecutionIssue      from './execution-issue';
import ExecutionManager    from './execution-manager';
import Terminal            from './terminal';
import * as workspaceUtils from './workspace-utils';

export default class LevelCodeEditor {
  constructor({textEditor, language, level, terminal}) {
    this.textEditor = textEditor;
    this.terminal = terminal;
    this.emitter = new Emitter();

    this.annotationManager = new AnnotationManager(this);
    this.executionManager = new ExecutionManager(this);

    this.setLanguage(language, level);

    this.terminal = new Terminal();
    this.terminal.acquire();

    this.bufferSubscription = this.textEditor.getBuffer().onWillSave(() => {
      this.writeLanguageInformationFileHeaderIf('before saving the buffer');
    });

    this.currentExecutionIssuesById = {};

    this.terminalSubscription = this.terminal.onDidReadTypedMessage(typedMessage => {
      this.readExecutionIssueFromTypedMessage(typedMessage);
    });
  }

  destroy() {
    this.terminalSubscription.dispose();
    this.bufferSubscription.dispose();

    this.stopExecution();

    this.removeExecutionIssues();
    this.terminal.release();

    this.emitter.emit('did-destroy');
  }

  // Public: Invoke the given callback with the current language and all future
  // language changes of this level code editor.
  //
  // * `callback` {Function} to be called with the current language and all
  //   future language changes.
  //   * `event` An {Object} with the following keys:
  //     * `language` The new {Language} of the level code editor.
  //     * `level` The new {Level} of the level code editor.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  observeLanguage(callback) {
    callback({language: this.language, level: this.level});
    return this.onDidChangeLanguage(callback);
  }

  // Public: Invoke the given callback when the language is changed for this
  // level code editor.
  //
  // * `callback` {Function} to be called when the language is changed.
  //   * `event` An {Object} with the following keys:
  //     * `language` The new {Language} of the level code editor.
  //     * `level` The new {Level} of the level code editor.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChangeLanguage(callback) {
    return this.emitter.on('did-change-language', callback);
  }

  // Public: Invoke the given callback with the current level and all future
  // level changes of this level code editor.
  //
  // * `callback` {Function} to be called with the current level and all future
  //   level changes.
  //   * `level` The new {Level} of the level code editor.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  observeLevel(callback) {
    callback(this.level);
    return this.onDidChangeLevel(callback);
  }

  // Public: Invoke the given callback when the level is changed for this level
  // code editor.
  //
  // * `callback` {Function} to be called when the level is changed.
  //   * `level` The new {Level} of the level code editor.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChangeLevel(callback) {
    return this.emitter.on('did-change-level', callback);
  }

  // Public: Invoke the given callback when the level code editor is destroyed.
  //
  // * `callback` {Function} to be called when the level code editor is
  //   destroyed.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidDestroy(callback) {
    return this.emitter.on('did-destroy', callback);
  }

  observeIsExecuting(callback) {
    callback(this.isExecuting());
    return this.onDidChangeIsExecuting(callback);
  }

  onDidChangeIsExecuting(callback) {
    return this.emitter.on('did-change-is-executing', callback);
  }

  onDidStartExecution(callback) {
    return this.emitter.on('did-start-execution', callback);
  }

  onDidStopExecution(callback) {
    return this.emitter.on('did-stop-execution', callback);
  }

  getTextEditor() {
    return this.textEditor;
  }

  getId() {
    return this.textEditor.id;
  }

  getLanguage() {
    return this.language;
  }

  isExecutable() {
    return this.language.isExecutable();
  }

  getLevel() {
    return this.level;
  }

  getTerminal() {
    return this.terminal;
  }

  setLanguage(language, level) {
    if (this.isExecuting()) {
      return;
    }

    if (this.language && language.getName() === this.language.getName()) {
      this.setLevel(level);
    } else {
      this.language = language;
      this.setLevel(level ? level : this.language.getLevelOnInitialization());
      this.emitter.emit('did-change-language', {
        language: this.language,
        level: this.level
      });
    }
  }

  setLevel(level) {
    if (this.isExecuting()) {
      return;
    }

    if (level && this.language.hasLevel(level)) {
      if (level.getName() !== (this.level ? this.level.getName() : undefined)) {
        this.level = level;
        this.textEditor.setGrammar(this.level.getGrammar());
        this.writeLanguageInformationFileHeaderIf('after setting the level');
        this.emitter.emit('did-change-level', this.level);
      }
    }
  }

  restore() {
    this.textEditor.setGrammar(this.level.getGrammar());
  }

  writeLanguageInformationFileHeaderIf(condition) {
    if (atom.config.get('levels.workspaceSettings.whenToWriteFileHeader') === condition) {
      workspaceUtils.deleteLanguageInformationFileHeader(this.textEditor);
      workspaceUtils.writeLanguageInformationFileHeader(this.textEditor, this.language, this.level);
    }
  }

  isExecuting() {
    return this.executionManager.isExecuting();
  }

  startExecution(options) {
    this.executionManager.startExecution(options);
  }

  didStartExecution() {
    this.removeExecutionIssues();
    this.emitter.emit('did-start-execution');
    this.emitter.emit('did-change-is-executing', true);
  }

  stopExecution() {
    this.executionManager.stopExecution();
  }

  didStopExecution() {
    this.emitter.emit('did-stop-execution');
    this.emitter.emit('did-change-is-executing', false);
  }

  readExecutionIssueFromTypedMessage(typedMessage) {
    if (this.isExecuting()) {
      const type = typedMessage.type;
      const source = typedMessage.data ? typedMessage.data.source : undefined;
      if (source && (type === 'error' || type === 'warning')) {
        const executionIssue = new ExecutionIssue(this, {
          id: typedMessage.id,
          type,
          source,
          row: parseInt(typedMessage.data.row),
          column: parseInt(typedMessage.data.col),
          message: typedMessage.body
        });
        this.addExecutionIssue(executionIssue);
      }
    }
  }

  addExecutionIssue(executionIssue) {
    this.currentExecutionIssuesById[executionIssue.getId()] = executionIssue;
    this.annotationManager.addAnnotationForExecutionIssue(executionIssue);
  }

  removeExecutionIssue(executionIssue) {
    this.annotationManager.removeAnnotationForExecutionIssue(executionIssue);
    delete this.currentExecutionIssuesById[executionIssue.getId()];
  }

  removeExecutionIssues() {
    for (const id in this.currentExecutionIssuesById) {
      this.removeExecutionIssue(this.currentExecutionIssuesById[id]);
    }
  }

  getCurrentExecutionIssueById(executionIssueId) {
    return this.currentExecutionIssuesById[executionIssueId];
  }

  getCurrentExecutionIssues() {
    const result = [];
    for (const id in this.currentExecutionIssuesById) {
      result.push(this.currentExecutionIssuesById[id]);
    }
    return result;
  }
}