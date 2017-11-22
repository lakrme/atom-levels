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

  onDidEnterWorkspace(callback) {
    return this.emitter.on('did-enter-workspace', callback);
  }

  onDidExitWorkspace(callback) {
    return this.emitter.on('did-exit-workspace', callback);
  }

  observeLevelCodeEditors(callback) {
    for (const levelCodeEditor of this.getLevelCodeEditors()) {
      callback(levelCodeEditor);
    }
    return this.onDidAddLevelCodeEditor(callback);
  }

  onDidAddLevelCodeEditor(callback) {
    return this.emitter.on('did-add-level-code-editor', callback);
  }

  onDidDestroyLevelCodeEditor(callback) {
    return this.emitter.on('did-destroy-level-code-editor', callback);
  }

  onDidChangeActiveLevelCodeEditor(callback) {
    return this.emitter.on('did-change-active-level-code-editor', callback);
  }

  onDidChangeActiveLanguage(callback) {
    return this.emitter.on('did-change-active-language', callback);
  }

  onDidChangeActiveLevel(callback) {
    return this.emitter.on('did-change-active-level', callback);
  }

  onDidChangeActiveTerminal(callback) {
    return this.emitter.on('did-change-active-terminal', callback);
  }

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

  getActiveLevelCodeEditor() {
    return this.activeLevelCodeEditor;
  }

  getActiveLanguage() {
    if (this.activeLevelCodeEditor) {
      return this.activeLevelCodeEditor.getLanguage();
    }
  }

  getActiveLevel() {
    if (this.activeLevelCodeEditor) {
      return this.activeLevelCodeEditor.getLevel();
    }
  }

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
    this.activeLevelCodeEditorSubscriptions.add(this.activeLevelCodeEditor.onDidChangeLevel(level => {
      this.emitter.emit('did-change-active-level', level);
    }));
  }

  unsubscribeFromActiveLevelCodeEditor() {
    this.activeLevelCodeEditorSubscriptions.dispose();
  }
}

export default new Workspace();