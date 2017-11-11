'use babel';

import SelectListView from 'atom-select-list';
import workspace      from './workspace';

export default class LevelSelectView {
  constructor() {
    this.selectListView = new SelectListView({
      items: [],
      filterKeyForItem: level => level.getName(),
      elementForItem: level => this.viewForLevel(level),
      didCancelSelection: () => this.cancel(),
      didConfirmSelection: level => this.confirm(level)
    });
  }

  destroy() {
    this.cancel();
    this.selectListView.destroy();
  }

  cancel() {
    if (this.panel) {
      this.panel.destroy();
      this.panel = null;
    }

    if (this.previouslyFocusedElement) {
      this.previouslyFocusedElement.focus();
      this.previouslyFocusedElement = null;
    }
  }

  attach() {
    this.previouslyFocusedElement = document.activeElement;
    if (!this.panel) {
      this.panel = atom.workspace.addModalPanel({item: this.selectListView});
    }

    this.selectListView.focus();
    this.selectListView.reset();
  }

  confirm(level) {
    this.cancel();
    if (level.getName() !== this.activeLevel.getName()) {
      this.activeLevelCodeEditor.setLevel(level);
      this.activeLanguage.setLastActiveLevel(level);
    }
  }

  toggle() {
    if (this.panel) {
      this.cancel();
    } else {
      this.update(workspace.getActiveLevelCodeEditor());
      this.attach();
    }
  }

  update(activeLevelCodeEditor) {
    this.activeLevelCodeEditor = activeLevelCodeEditor;
    this.activeLanguage = this.activeLevelCodeEditor.getLanguage();
    this.activeLevel = this.activeLevelCodeEditor.getLevel();
    this.selectListView.update({items: this.activeLanguage.getLevels()});
  }

  viewForLevel(level) {
    const levelName = level.getName();
    const levelDescription = level.getDescription();

    const listElement = document.createElement('li');
    listElement.dataset.level = levelName;

    if (levelDescription) {
      listElement.className = 'two-lines';

      const nameElement = document.createElement('div');
      nameElement.className = level === this.activeLevel ? 'primary-line icon icon-triangle-right' : 'primary-line no-icon';
      nameElement.textContent = levelName;
      listElement.appendChild(nameElement);

      const descElement = document.createElement('div');
      descElement.className = 'secondary-line no-icon';
      descElement.textContent = levelDescription;
      listElement.appendChild(descElement);
    } else {
      const nameElement = document.createElement('span');
      nameElement.className = level === this.activeLevel ? 'icon icon-triangle-right' : 'no-icon';
      nameElement.textContent = levelName;
      listElement.appendChild(nameElement);
    }

    return listElement;
  }
}