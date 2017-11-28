'use babel';

import languageRegistry from './language-registry';
import levelsConfig     from './levels-config';
import levelsServices   from './levels-services';
import workspace        from './workspace';
import workspaceManager from './workspace-manager';

export default {
  activate() {
    workspaceManager.setUpWorkspace();
    workspaceManager.activateEventHandlers();
    workspaceManager.activateCommandHandlers();
  },

  deactivate() {
    workspaceManager.cleanUpWorkspace();
    workspaceManager.deactivateEventHandlers();
    workspaceManager.deactivateCommandHandlers();
    workspace.destroy();
    languageRegistry.destroy();
  },

  config: levelsConfig,

  provideLevels() {
    return levelsServices;
  },

  consumeStatusBar(statusBar) {
    workspaceManager.consumeStatusBar(statusBar);
  }
};