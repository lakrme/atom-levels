languageRegistry = require('./language-registry').getInstance()
workspace        = require('./workspace').getInstance()

module.exports =
  provideLevels: ->
    languageRegistry:
      observeLanguages:
        languageRegistry.observeLanguages.bind languageRegistry
      onDidAddLanguage:
        languageRegistry.onDidAddLanguage.bind languageRegistry
      onDidRemoveLanguage:
        languageRegistry.onDidRemoveLanguage.bind languageRegistry
      addLanguage:
        languageRegistry.addLanguage.bind languageRegistry
      readLanguageSync:
        languageRegistry.readLanguageSync.bind languageRegistry
      loadLanguageSync:
        languageRegistry.loadLanguageSync.bind languageRegistry
      removeLanguage:
        languageRegistry.removeLanguage.bind languageRegistry
      getLanguageForName:
        languageRegistry.getLanguageForName.bind languageRegistry
      getLanguageForGrammar:
        languageRegistry.getLanguageForGrammar.bind languageRegistry
      getLanguages:
        languageRegistry.getLanguages.bind languageRegistry
      getLanguagesForFileType:
        languageRegistry.getLanguagesForFileType.bind languageRegistry
    workspace:
      onDidEnterWorkspace:
        workspace.onDidEnterWorkspace.bind workspace
      onDidExitWorkspace:
        workspace.onDidExitWorkspace.bind workspace
      observeLevelCodeEditors:
        workspace.observeLevelCodeEditors.bind workspace
      onDidAddLevelCodeEditor:
        workspace.onDidAddLevelCodeEditor.bind workspace
      onDidDestroyLevelCodeEditor:
        workspace.onDidDestroyLevelCodeEditor.bind workspace
      onDidChangeActiveLevelCodeEditor:
        workspace.onDidChangeActiveLevelCodeEditor.bind workspace
      onDidChangeActiveLanguage:
        workspace.onDidChangeActiveLanguage.bind workspace
      onDidChangeActiveLevel:
        workspace.onDidChangeActiveLevel.bind workspace
      onDidChangeActiveTerminal:
        workspace.onDidChangeActiveTerminal.bind workspace
      isActive:
        workspace.isActive.bind workspace
      getLevelCodeEditors:
        workspace.getLevelCodeEditors.bind workspace
      getActiveLevelCodeEditor:
        workspace.getActiveLevelCodeEditor.bind workspace
      getActiveLanguage:
        workspace.getActiveLanguage.bind workspace
      getActiveLevel:
        workspace.getActiveLevel.bind workspace
      getActiveTerminal:
        workspace.getActiveTerminal.bind workspace