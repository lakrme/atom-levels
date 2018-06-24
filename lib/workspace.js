'use babel';

import {CompositeDisposable, Emitter} from 'atom';

class Workspace {
  constructor() {
    this.emitter = new Emitter();
    this.levelCodeEditorsById = {};
    this.activeLevelCodeEditor = null;
    this.activeLevelCodeEditorSubscriptions = new CompositeDisposable();
  }

  destroy() {
    this.emitter.dispose();
    this.unsubscribeFromActiveLevelCodeEditor();
  }

  // Public: Invoke the given callback when the level workspace is entered.
  //
  // * `callback` {Function} to be called with the active level code editor.
  //   * `levelCodeEditor` The {LevelCodeEditor} that is present in the level
  //     workspace.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidEnterWorkspace(callback) {
    return this.emitter.on('did-enter-workspace', callback);
  }

  // Public: Invoke the given callback when the level workspace is exited.
  //
  // * `callback` {Function} to be called when the level workspace is exited.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidExitWorkspace(callback) {
    return this.emitter.on('did-exit-workspace', callback);
  }

  // Public: Invoke the given callback with all current and future level code
  // editors in the workspace.
  //
  // * `callback` {Function} to be called with current and future level code
  //   editors.
  //   * `levelCodeEditor` A {LevelCodeEditor} that is present in the workspace
  //     at the time of subscription or that is added at some later time.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  observeLevelCodeEditors(callback) {
    for (const levelCodeEditor of this.getLevelCodeEditors()) {
      callback(levelCodeEditor);
    }
    return this.onDidAddLevelCodeEditor(callback);
  }

  // Public: Invoke the given callback when a level code editor is added to the
  // workspace.
  //
  // * `callback` {Function} to be called when a level code editor is added.
  //   * `levelCodeEditor` The {LevelCodeEditor} that was added.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidAddLevelCodeEditor(callback) {
    return this.emitter.on('did-add-level-code-editor', callback);
  }

  // Public: Invoke the given callback when a level code editor is destroyed.
  //
  // * `callback` {Function} to be called when a level code editor is destroyed.
  //   * `levelCodeEditor` The {LevelCodeEditor} that was destroyed.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidDestroyLevelCodeEditor(callback) {
    return this.emitter.on('did-destroy-level-code-editor', callback);
  }

  // Public: Invoke the given callback when the active level code editor is
  // changed.
  //
  // * `callback` {Function} to be called when the active level code editor is
  //   changed.
  //   * `levelCodeEditor` The {LevelCodeEditor} that is activated.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChangeActiveLevelCodeEditor(callback) {
    return this.emitter.on('did-change-active-level-code-editor', callback);
  }

  // Public: Invoke the given callback when the active level language is
  // changed.
  //
  // * `callback` {Function} to be called when the active level language is
  //   changed.
  //   * `activeLanguage` The {Language} that is activated.
  //   * `activeLevel` The {Level} that is activated.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChangeActiveLanguage(callback) {
    return this.emitter.on('did-change-active-language', callback);
  }

  // Public: Invoke the given callback when the active level is changed.
  //
  // * `callback` {Function} to be called when the active level is changed.
  //   * `activeLevel` The {Level} that is activated.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChangeActiveLevel(callback) {
    return this.emitter.on('did-change-active-level', callback);
  }

  // Public: Invoke the given callback when the active terminal is changed.
  //
  // * `callback` {Function} to be called when the active terminal is changed.
  //   * `activeTerminal` The {Terminal} that is activated.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChangeActiveTerminal(callback) {
    return this.emitter.on('did-change-active-terminal', callback);
  }

  // Public: Returns a {Boolean} that is `true` if a level code editor is
  // active.
  isActive() {
    return this.activeLevelCodeEditor != null;
  }

  addLevelCodeEditor(levelCodeEditor) {
    this.levelCodeEditorsById[levelCodeEditor.getId()] = levelCodeEditor;
    this.emitter.emit('did-add-level-code-editor', levelCodeEditor);
  }

  destroyLevelCodeEditor(levelCodeEditor) {
    delete this.levelCodeEditorsById[levelCodeEditor.getId()];
    levelCodeEditor.destroy();
    this.emitter.emit('did-destroy-level-code-editor', levelCodeEditor);
  }

  getLevelCodeEditorForId(levelCodeEditorId) {
    return this.levelCodeEditorsById[levelCodeEditorId];
  }

  getLevelCodeEditorForTextEditor(textEditor) {
    return this.levelCodeEditorsById[textEditor.id];
  }

  // Public: Get all the level code editors in the workspace.
  //
  // Returns an {Array} of {LevelCodeEditor} objects.
  getLevelCodeEditors() {
    const levelCodeEditors = [];
    for (const levelCodeEditorId in this.levelCodeEditorsById) {
      levelCodeEditors.push(this.levelCodeEditorsById[levelCodeEditorId]);
    }
    return levelCodeEditors;
  }

  isLevelCodeEditor(textEditor) {
    return this.getLevelCodeEditorForTextEditor(textEditor) != null;
  }

  // Public: Returns the active {LevelCodeEditor}.
  getActiveLevelCodeEditor() {
    return this.activeLevelCodeEditor;
  }

  // Public: Returns the active {Language} or `undefined`.
  getActiveLanguage() {
    if (this.activeLevelCodeEditor) {
      return this.activeLevelCodeEditor.getLanguage();
    }
  }

  // Public: Returns the active {Level} or `undefined`.
  getActiveLevel() {
    if (this.activeLevelCodeEditor) {
      return this.activeLevelCodeEditor.getLevel();
    }
  }

  // Public: Returns the active {Terminal} or `undefined`.
  getActiveTerminal() {
    if (this.activeLevelCodeEditor) {
      return this.activeLevelCodeEditor.getTerminal();
    }
  }

  setActiveLevelCodeEditor(levelCodeEditor) {
    if (this.isActive()) {
      if (levelCodeEditor.getId() !== this.activeLevelCodeEditor.getId()) {
        const newLanguage = levelCodeEditor.getLanguage();
        const oldLanguage = this.activeLevelCodeEditor.getLanguage();
        const newLevel = levelCodeEditor.getLevel();
        const oldLevel = this.activeLevelCodeEditor.getLevel();

        this.unsubscribeFromActiveLevelCodeEditor();
        this.activeLevelCodeEditor = levelCodeEditor;

        if (newLanguage.getName() !== oldLanguage.getName()) {
          this.emitter.emit('did-change-active-level', newLevel);
          this.emitter.emit('did-change-active-language', {
            activeLanguage: newLanguage,
            activeLevel: newLevel
          });
        } else if (newLevel.getName() !== oldLevel.getName()) {
          this.emitter.emit('did-change-active-level', newLevel);
        }

        this.subscribeToActiveLevelCodeEditor();
        this.emitter.emit('did-change-active-terminal', this.activeLevelCodeEditor.getTerminal());
        this.emitter.emit('did-change-active-level-code-editor', this.activeLevelCodeEditor);
      }
    } else {
      this.activeLevelCodeEditor = levelCodeEditor;
      this.subscribeToActiveLevelCodeEditor();
      this.emitter.emit('did-enter-workspace', this.activeLevelCodeEditor);
    }
  }

  unsetActiveLevelCodeEditor() {
    if (this.isActive()) {
      this.unsubscribeFromActiveLevelCodeEditor();
      this.activeLevelCodeEditor = null;
      this.emitter.emit('did-exit-workspace');
    }
  }

  subscribeToActiveLevelCodeEditor() {
    this.activeLevelCodeEditorSubscriptions = new CompositeDisposable();
    this.activeLevelCodeEditorSubscriptions.add(this.activeLevelCodeEditor.onDidChangeLanguage(({language, level}) => {
      this.emitter.emit('did-change-active-language', {
        activeLanguage: language,
        activeLevel: level
      });
    }));
    this.activeLevelCodeEditorSubscriptions.add(this.activeLevelCodeEditor.onDidChangeLevel((level) => {
      this.emitter.emit('did-change-active-level', level);
    }));
  }

  unsubscribeFromActiveLevelCodeEditor() {
    this.activeLevelCodeEditorSubscriptions.dispose();
  }
}

export default new Workspace();