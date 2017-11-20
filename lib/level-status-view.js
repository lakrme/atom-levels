'use babel';

import {CompositeDisposable} from 'atom';
import workspace             from './workspace';

export default class LevelStatusView {
  constructor() {
    this.element = document.createElement('div');
    this.element.className = 'level-status inline-block';
    this.element.style.display = 'none';

    this.statusLink = document.createElement('a');
    this.statusLink.className = 'inline-block';
    this.statusLink.addEventListener('click', () => this.toggleLevelSelect());
    this.element.appendChild(this.statusLink);

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(workspace.onDidEnterWorkspace(activeLevelCodeEditor => this.handleOnDidEnterWorkspace(activeLevelCodeEditor)));
    this.subscriptions.add(workspace.onDidExitWorkspace(() => this.handleOnDidExitWorkspace()));
    this.subscriptions.add(workspace.onDidChangeActiveLevel(activeLevel => this.handleOnDidChangeActiveLevel(activeLevel)));
  }

  destroy() {
    this.subscriptions.dispose();
    if (this.statusTooltip) {
      this.statusTooltip.dispose();
    }
  }

  toggleLevelSelect() {
    if (!workspace.getActiveLevelCodeEditor().isExecuting()) {
      const workspaceView = atom.views.getView(atom.workspace);
      atom.commands.dispatch(workspaceView, 'levels:toggle-level-select');
    }
  }

  handleOnDidEnterWorkspace(activeLevelCodeEditor) {
    this.handleOnDidChangeActiveLevel(activeLevelCodeEditor.getLevel());
    this.element.style.display = '';
  }

  handleOnDidExitWorkspace() {
    this.element.style.display = 'none';
  }

  handleOnDidChangeActiveLevel(activeLevel) {
    const activeLevelName = activeLevel.getName();
    this.statusLink.textContent = activeLevelName;
    this.statusLink.dataset.level = activeLevelName;

    if (this.statusTooltip) {
      this.statusTooltip.dispose();
    }
    this.statusTooltip = atom.tooltips.add(this.statusLink, {title: activeLevel.getDescription(), html: false});
  }
}