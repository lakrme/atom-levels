'use babel';

import {CompositeDisposable} from 'atom';
import languageRegistry      from './language-registry';
import LevelCodeEditor       from './level-code-editor';
import LevelSelectView       from './level-select-view';
import LevelStatusView       from './level-status-view';
import Terminal              from './terminal';
import TerminalPanelView     from './terminal-panel-view';
import TerminalView          from './terminal-view';
import workspace             from './workspace';
import * as workspaceUtils   from './workspace-utils';

class WorkspaceManager {
  setUpWorkspace() {
    this.viewProvider = atom.views.addViewProvider(Terminal, terminal => {
      const terminalView = new TerminalView(terminal);

      terminal.newLine();
      terminal.writeInfo('Welcome to the levels terminal!');
      terminal.writeSubtle('Hit the "Run" button in the top-right corner of the terminal,');
      terminal.writeSubtle('type "run" and hit enter or press "ctrl-alt-r" to execute your program.');
      terminal.writeSubtle('While executing, hit the "Stop" button or press "ctrl-alt-s" to stop the execution of your program.');

      return terminalView.element;
    });

    this.levelSelectView = new LevelSelectView();
    this.terminalPanelView = new TerminalPanelView();
  }

  cleanUpWorkspace() {
    this.viewProvider.dispose();

    if (this.levelStatusView) {
      this.levelStatusView.destroy();
    }
    if (this.levelStatusTile) {
      this.levelStatusTile.destroy();
    }
    this.levelSelectView.destroy();
    this.terminalPanelView.destroy();

    for (const language of languageRegistry.getLanguages()) {
      languageRegistry.removeLanguage(language);
    }
  }

  activateEventHandlers() {
    this.subscribeToAtomWorkspace();
    this.subscribeToLanguageRegistry();
  }

  deactivateEventHandlers() {
    this.unsubscribeFromAtomWorkspace();
    this.unsubscribeFromLanguageRegistry();
  }

  activateCommandHandlers() {
    this.commandHandlers = atom.commands.add('atom-workspace', {
      'levels:clear-terminal': event => this.doClearTerminal(event),
      'levels:toggle-terminal-focus': event => this.doToggleTerminalFocus(event),
      'levels:toggle-level-select': event => this.doToggleLevelSelect(event),
      'levels:start-execution': event => this.doStartExecution(event),
      'levels:stop-execution': event => this.doStopExecution(event),
      'levels:toggle-terminal': event => this.doToggleTerminal(event),
      'levels:increase-terminal-font-size': event => this.doIncreaseTerminalFontSize(event),
      'levels:decrease-terminal-font-size': event => this.doDecreaseTerminalFontSize(event),
      'levels:scroll-terminal-to-top': event => this.doScrollTerminalToTop(event),
      'levels:scroll-terminal-to-bottom': event => this.doScrollTerminalToBottom(event)
    });
  }

  deactivateCommandHandlers() {
    this.commandHandlers.dispose();
  }

  subscribeToAtomWorkspace() {
    this.textEditorSubscriptions = {};

    this.atomWorkspaceSubscriptions = new CompositeDisposable();
    this.atomWorkspaceSubscriptions.add(atom.workspace.onDidAddTextEditor(({textEditor}) => this.handleDidAddTextEditor(textEditor)));
    this.atomWorkspaceSubscriptions.add(atom.workspace.onDidChangeActivePaneItem(item => this.handleDidChangeActivePaneItem(item)));

    for (const textEditor of atom.workspace.getTextEditors()) {
      this.subscribeToTextEditor(textEditor);
    }
  }

  unsubscribeFromAtomWorkspace() {
    this.atomWorkspaceSubscriptions.dispose();

    for (const textEditor of atom.workspace.getTextEditors()) {
      this.unsubscribeFromTextEditor(textEditor);
    }
  }

  handleDidChangeActivePaneItem() {
    const textEditor = atom.workspace.getActiveTextEditor();
    if (textEditor && workspace.isLevelCodeEditor(textEditor)) {
      const levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor);
      workspace.setActiveLevelCodeEditor(levelCodeEditor);
    } else {
      workspace.unsetActiveLevelCodeEditor();
    }
  }

  handleDidAddTextEditor(textEditor) {
    let levelCodeEditor = null;

    if (!levelCodeEditor) {
      const result = workspaceUtils.readLanguageInformationFromFileHeader(textEditor);
      if (result && result.language) {
        const language = result.language;
        const level = result.level;
        levelCodeEditor = new LevelCodeEditor({textEditor, language, level});
      }
    }

    if (!levelCodeEditor) {
      const language = workspaceUtils.readLanguageFromFileExtension(textEditor);
      if (language) {
        levelCodeEditor = new LevelCodeEditor({textEditor, language});
      }
    }

    if (!levelCodeEditor) {
      const language = languageRegistry.getLanguageForGrammar(textEditor.getGrammar());
      if (language) {
        levelCodeEditor = new LevelCodeEditor({textEditor, language});
      }
    }

    if (levelCodeEditor) {
      workspace.addLevelCodeEditor(levelCodeEditor);
    }
    this.subscribeToTextEditor(textEditor);
  }

  subscribeToTextEditor(textEditor) {
    this.textEditorSubscriptions[textEditor.id] = {
      didChangeGrammarSubscription: textEditor.onDidChangeGrammar(grammar => this.handleDidChangeGrammarOfTextEditor(textEditor, grammar)),
      didDestroySubscription: textEditor.onDidDestroy(() => this.handleDidDestroyTextEditor(textEditor))
    };
  }

  unsubscribeFromTextEditor(textEditor) {
    const textEditorSubscription = this.textEditorSubscriptions[textEditor.id];
    if (textEditorSubscription) {
      textEditorSubscription.didChangeGrammarSubscription.dispose();
      textEditorSubscription.didDestroySubscription.dispose();
    }
    delete this.textEditorSubscriptions[textEditor.id];
  }

  handleDidChangeGrammarOfTextEditor(textEditor, grammar) {
    this.textEditorSubscriptions[textEditor.id].didChangeGrammarSubscription.dispose();
    const language = languageRegistry.getLanguageForGrammar(grammar);

    if (workspace.isLevelCodeEditor(textEditor)) {
      const levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor);
      const currentLanguage = levelCodeEditor.getLanguage();

      if (language) {
        if (language === currentLanguage) {
          if (grammar === language.getDummyGrammar()) {
            levelCodeEditor.restore();
          }
        } else {
          levelCodeEditor.setLanguage(language);
        }
      } else {
        workspace.destroyLevelCodeEditor(levelCodeEditor);
        if (textEditor === atom.workspace.getActiveTextEditor()) {
          workspace.unsetActiveLevelCodeEditor();
        }
      }
    } else if (language && grammar === language.getDummyGrammar()) {
      const levelCodeEditor = new LevelCodeEditor({textEditor, language});
      workspace.addLevelCodeEditor(levelCodeEditor);
      if (textEditor === atom.workspace.getActiveTextEditor()) {
        workspace.setActiveLevelCodeEditor(levelCodeEditor);
      }
    }

    this.textEditorSubscriptions[textEditor.id].didChangeGrammarSubscription =
      textEditor.onDidChangeGrammar(newGrammar => this.handleDidChangeGrammarOfTextEditor(textEditor, newGrammar));
  }

  handleDidDestroyTextEditor(textEditor) {
    if (workspace.isLevelCodeEditor(textEditor)) {
      const levelCodeEditor = workspace.getLevelCodeEditorForTextEditor(textEditor);
      workspace.destroyLevelCodeEditor(levelCodeEditor);
    }
    this.unsubscribeFromTextEditor(textEditor);
  }

  subscribeToLanguageRegistry() {
    this.languageRegistrySubscriptions = new CompositeDisposable();
    this.languageRegistrySubscriptions.add(languageRegistry.observeLanguages(language => this.handleDidAddLanguageToLanguageRegistry(language)));
    this.languageRegistrySubscriptions.add(languageRegistry.onDidRemoveLanguage(language => this.handleDidRemoveLanguageFromLanguageRegistry(language)));
  }

  unsubscribeFromLanguageRegistry() {
    this.languageRegistrySubscriptions.dispose();
  }

  handleDidAddLanguageToLanguageRegistry(addedLanguage) {
    for (const textEditor of atom.workspace.getTextEditors()) {
      if (!workspace.isLevelCodeEditor(textEditor)) {
        let levelCodeEditor = null;

        if (!levelCodeEditor) {
          const result = workspaceUtils.readLanguageInformationFromFileHeader(textEditor);
          if (result && result.language) {
            const language = result.language;
            if (language === addedLanguage) {
              const level = result.level;
              levelCodeEditor = new LevelCodeEditor({textEditor, language, level});
            }
          }
        }

        if (!levelCodeEditor) {
          const language = workspaceUtils.readLanguageFromFileExtension(textEditor);
          if (language && language === addedLanguage) {
            levelCodeEditor = new LevelCodeEditor({textEditor, language});
          }
        }

        if (!levelCodeEditor) {
          const language = languageRegistry.getLanguageForGrammar(textEditor.getGrammar());
          if (language && language === addedLanguage) {
            levelCodeEditor = new LevelCodeEditor({textEditor, language});
          }
        }

        if (levelCodeEditor) {
          workspace.addLevelCodeEditor(levelCodeEditor);
          if (textEditor === atom.workspace.getActiveTextEditor()) {
            workspace.setActiveLevelCodeEditor(levelCodeEditor);
          }
        }
      }
    }
  }

  handleDidRemoveLanguageFromLanguageRegistry(language) {
    for (const levelCodeEditor of workspace.getLevelCodeEditors()) {
      if (levelCodeEditor.getLanguage() === language) {
        workspace.destroyLevelCodeEditor(levelCodeEditor);
        if (levelCodeEditor.getTextEditor() === atom.workspace.getActiveTextEditor()) {
          workspace.unsetActiveLevelCodeEditor();
        }
      }
    }
  }

  doToggleLevelSelect(event) {
    if (workspace.isActive()) {
      if (!workspace.getActiveLevelCodeEditor().isExecuting()) {
        this.levelSelectView.toggle();
      }
    } else {
      event.abortKeyBinding();
    }
  }

  doToggleTerminal(event) {
    if (workspace.isActive()) {
      const activeLevelCodeEditor = workspace.getActiveLevelCodeEditor();
      const activeTextEditor = activeLevelCodeEditor.getTextEditor();
      const activeTerminal = activeLevelCodeEditor.getTerminal();

      if (activeTerminal.isVisible()) {
        activeTerminal.hide();
        atom.views.getView(activeTextEditor).focus();
      } else {
        activeTerminal.show();
        activeTerminal.focus();
      }
    } else {
      event.abortKeyBinding();
    }
  }

  doIncreaseTerminalFontSize(event) {
    if (workspace.isActive()) {
      workspace.getActiveTerminal().increaseFontSize();
    } else {
      event.abortKeyBinding();
    }
  }

  doDecreaseTerminalFontSize(event) {
    if (workspace.isActive()) {
      workspace.getActiveTerminal().decreaseFontSize();
    } else {
      event.abortKeyBinding();
    }
  }

  doToggleTerminalFocus(event) {
    if (workspace.isActive()) {
      const activeLevelCodeEditor = workspace.getActiveLevelCodeEditor();
      const activeTextEditor = activeLevelCodeEditor.getTextEditor();
      const activeTerminal = activeLevelCodeEditor.getTerminal();

      if (activeTerminal.hasFocus()) {
        atom.views.getView(activeTextEditor).focus();
      } else {
        activeTerminal.show();
        activeTerminal.focus();
      }
    } else {
      event.abortKeyBinding();
    }
  }

  doClearTerminal(event) {
    if (workspace.isActive()) {
      const activeLevelCodeEditor = workspace.getActiveLevelCodeEditor();
      if (!activeLevelCodeEditor.isExecuting()) {
        const activeTerminal = activeLevelCodeEditor.getTerminal();
        activeTerminal.clear();
        activeTerminal.focus();
      }
    } else {
      event.abortKeyBinding();
    }
  }

  doScrollTerminalToTop(event) {
    if (workspace.isActive()) {
      workspace.getActiveTerminal().scrollToTop();
    } else {
      event.abortKeyBinding();
    }
  }

  doScrollTerminalToBottom(event) {
    if (workspace.isActive()) {
      workspace.getActiveTerminal().scrollToBottom();
    } else {
      event.abortKeyBinding();
    }
  }

  doStartExecution(event) {
    if (workspace.isActive()) {
      const activeLevelCodeEditor = workspace.getActiveLevelCodeEditor();

      if (!activeLevelCodeEditor.isExecuting()) {
        const activeTextEditor = activeLevelCodeEditor.getTextEditor();
        const activeTerminal = activeLevelCodeEditor.getTerminal();

        const path = activeTextEditor.getPath();
        const startExecutionAction = () => {
          activeLevelCodeEditor.startExecution();
          activeTerminal.show();
          activeTerminal.focus();
        };

        if (path) {
          activeTextEditor.saveAs(path).then(startExecutionAction);
        } else {
          const textEditorPaneContainer = atom.workspace.paneContainerForItem(activeTextEditor);
          textEditorPaneContainer.getActivePane().saveItemAs(activeTextEditor, error => {
            if (!error) {
              startExecutionAction();
            }
          });
        }
      }
    } else {
      event.abortKeyBinding();
    }
  }

  doStopExecution(event) {
    if (workspace.isActive()) {
      workspace.getActiveLevelCodeEditor().stopExecution();
    } else {
      event.abortKeyBinding();
    }
  }

  consumeStatusBar(statusBar) {
    this.levelStatusView = new LevelStatusView();
    this.levelStatusTile = statusBar.addRightTile({priority: 9, item: this.levelStatusView.element});
  }
}

export default new WorkspaceManager();