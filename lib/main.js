'use babel';

import levelsConfig     from './levels-config';
import levelsServices   from './levels-services';
import workspaceManager from './workspace-manager';

export default {
  activate(state) {
    workspaceManager.setUpWorkspace(state);
    workspaceManager.activateEventHandlers();
    workspaceManager.activateCommandHandlers();
  },

  deactivate() {
    workspaceManager.cleanUpWorkspace();
    workspaceManager.deactivateEventHandlers();
    workspaceManager.deactivateCommandHandlers();
  },

  config: levelsConfig,

  provideLevels() {
    return levelsServices;
  },

  consumeStatusBar(statusBar) {
    workspaceManager.consumeStatusBar(statusBar);
  },

  serialize() {
    workspaceManager.serializeWorkspace();
  }
};