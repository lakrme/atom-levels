'use babel';

import {Disposable, Emitter}  from 'atom';
import path                   from 'path';
import CSON                   from 'season';
import Language               from './language';
import {GRAMMAR_NAME_PATTERN} from './language-utils';
import Level                  from './level';

class LanguageRegistry {
  constructor() {
    this.emitter = new Emitter();
    this.languagesByName = {};
  }

  destroy() {
    this.emitter.dispose();
  }

  // Public: Invoke the given callback with all current and future languages in
  // the language registry.
  //
  // * `callback` {Function} to be called with current and future languages.
  //   * `language` A {Language} that is present in the language registry at the
  //     time of subscription or that is added at some later time.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  observeLanguages(callback) {
    for (const language of this.getLanguages()) {
      callback(language);
    }
    return this.onDidAddLanguage(callback);
  }

  // Public: Invoke the given callback when a language is added to the language
  // registry.
  //
  // * `callback` {Function} to be called when a language is added.
  //   * `language` The {Language} that was added.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidAddLanguage(callback) {
    return this.emitter.on('did-add-language', callback);
  }

  // Public: Invoke the given callback when a language is removed from the
  // language registry.
  //
  // * `callback` {Function} to be called when a language is removed.
  //   * `language` The {Language} that was removed.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidRemoveLanguage(callback) {
    return this.emitter.on('did-remove-language', callback);
  }

  // Public: Add a language to the language registry.
  //
  // Emits a 'did-add-language' event after adding the language.
  //
  // * `language` The {Language} to be added to the registry. This should be a
  //   value previously returned from {::readLanguageSync}.
  // * `options` (optional) {Object}
  //   * `addNewDummyGrammar` (optional) A {Boolean} indicating whether or not
  //     to create and add a fresh dummy grammar for the given language. The
  //     dummy grammar "represents" the language and makes it selectable via
  //     the grammar selection. Selecting the dummy grammar activates the
  //     appropriate language and causes levels to subsequently set the correct
  //     level grammar. Defaults to `false`.
  //
  // Returns a {Disposable} on which `.dispose()` can be called to remove the
  // language.
  addLanguage(language, options = {}) {
    if (options.addNewDummyGrammar) {
      const dummyGrammar = atom.grammars.createGrammar(undefined, {
        name: language.getGrammarName(),
        scopeName: language.getScopeName(),
        fileTypes: language.getLevelCodeFileTypes()
      });
      language.setDummyGrammar(dummyGrammar);
      atom.grammars.addGrammar(dummyGrammar);
    }

    this.languagesByName[language.getName()] = language;
    this.emitter.emit('did-add-language', language);
    return new Disposable(() => this.removeLanguage(language));
  }

  // Public: Read a language synchronously but don't add it to the registry.
  //
  // Only languages in the language registry are ready to be used with the
  // levels package. Languages can be added to the language registry with
  // {::addLanguage}.
  //
  // * `configFilePath` A {String} containing the absolute file path to the
  //   language's configuration file.
  // * `executablePath` A {String} containing the absolute file path to the
  //   language's executable.
  //
  // Returns a {Language}.
  readLanguageSync(configFilePath, executablePath) {
    const configFile = this.validateConfigFile(configFilePath);
    configFile.path = configFilePath;
    return this.createLanguage(configFile, executablePath);
  }

  // Public: Read a language synchronously and add it to the registry.
  //
  // * `configFilePath` A {String} containing the absolute file path to the
  //   language's configuration file.
  // * `executablePath` A {String} containing the absolute file path to the
  //   language's executable.
  // * `options` (optional) An {Object} with additional options. See
  //   {::addLanguage} for more details.
  //
  // Returns a {Language}.
  loadLanguageSync(configFilePath, executablePath, options) {
    const language = this.readLanguageSync(configFilePath, executablePath);
    this.addLanguage(language, options);
    return language;
  }

  // Public: Remove the given language from the language registry.
  //
  // Emits a 'did-remove-language' event after removing the language.
  //
  // * `language` The {Language} to be removed from the registry.
  //
  // Returns the removed {Language} or `undefined`.
  removeLanguage(language) {
    const languageName = language.getName();
    if (this.getLanguageForName(languageName)) {
      delete this.languagesByName[languageName];
      this.emitter.emit('did-remove-language', language);
      return language;
    }
  }

  // Public: Get a language with the given name.
  //
  // * `languageName` The name of the language as a {String}.
  //
  // Returns a {Language} or `undefined`.
  getLanguageForName(languageName) {
    return this.languagesByName[languageName];
  }

  // Public: Get a language that is associated with the given grammar.
  //
  // The grammar can be the dummy grammar or a level grammar of the language.
  //
  // * `grammar` The language's {Grammar}.
  //
  // Returns a {Language} or `undefined`.
  getLanguageForGrammar(grammar) {
    for (const language of this.getLanguages()) {
      if (grammar === language.getDummyGrammar()) {
        return language;
      }
      for (const level of language.getLevels()) {
        if (grammar === level.getGrammar()) {
          return language;
        }
      }
    }
  }

  // Public: Get all the languages in this registry.
  //
  // Returns an {Array} of {Language} objects.
  getLanguages() {
    const languages = [];
    for (const languageName in this.languagesByName) {
      languages.push(this.languagesByName[languageName]);
    }
    return languages;
  }

  // Public: Get the best matching languages in the registry that are associated
  // with the given level code file type.
  //
  // If there are multiple level code file types given for a language, the
  // foremost ones in the file types array are supposed to have the highest
  // priority. This picks the language(s) with the highest priority defined for
  // the given file type.
  //
  // * `fileType` The level code file type as a {String} (e.g. `"rb"`).
  //
  // Returns an {Array} of {Language} objects.
  getLanguagesForFileType(fileType) {
    let languages = [];
    let lowestIndex;

    for (const languageName in this.languagesByName) {
      const language = this.languagesByName[languageName];
      const fileTypes = language.getLevelCodeFileTypes();
      if (fileTypes) {
        const i = fileTypes.indexOf(fileType);
        if (i >= 0) {
          if (lowestIndex == null || i < lowestIndex) {
            lowestIndex = i;
            languages = [language];
          } else if (i === lowestIndex) {
            languages.push(language);
          }
        }
      }
    }

    return languages;
  }

  validateConfigFile(configFilePath) {
    return CSON.readFileSync(configFilePath);
  }

  createLanguage(config, executablePath) {
    const properties = {
      name: config.name,
      objectCodeFileType: config.objectCodeFileType,
      lineCommentPattern: config.lineCommentPattern,
      executionCommandPatterns: config.executionCommandPatterns,
      configFilePath: config.path,
      executablePath
    };

    const grammarName = GRAMMAR_NAME_PATTERN.replace(/<languageName>/, config.name);
    const languageNameFormatted = config.name.replace(/\s+/g, '-').toLowerCase();
    const scopeName = `levels.source.${languageNameFormatted}`;
    const fileTypes = config.levelCodeFileTypes ? config.levelCodeFileTypes : [];

    let defaultGrammar = null;
    let defaultGrammarPath = config.defaultGrammar;

    if (defaultGrammarPath) {
      if (!path.isAbsolute(defaultGrammarPath)) {
        defaultGrammarPath = path.join(config.path, '..', defaultGrammarPath);
      }

      defaultGrammar = atom.grammars.readGrammarSync(defaultGrammarPath);
      defaultGrammar.name = grammarName;
      defaultGrammar.scopeName = scopeName;
      defaultGrammar.fileTypes = fileTypes;
    } else {
      defaultGrammar = atom.grammars.createGrammar(undefined, {
        name: grammarName,
        scopeName,
        fileTypes
      });
    }

    properties.grammarName = grammarName;
    properties.scopeName = scopeName;
    properties.levelCodeFileTypes = fileTypes;
    properties.defaultGrammar = defaultGrammar;
    properties.lastActiveLevel = undefined;

    const levels = [];
    for (let i = 0; i < config.levels.length; i++) {
      const levelConfig = config.levels[i];
      const levelProperties = {
        number: i + 1,
        name: levelConfig.name,
        description: levelConfig.description,
        options: levelConfig.options ? levelConfig.options : {}
      };

      let grammar = null;
      let grammarPath = levelConfig.grammar;

      if (grammarPath) {
        if (!path.isAbsolute(grammarPath)) {
          grammarPath = path.join(config.path, '..', grammarPath);
        }

        grammar = atom.grammars.readGrammarSync(grammarPath);
        grammar.name = grammarName;
        grammar.scopeName = scopeName;
        grammar.fileTypes = fileTypes;
      }

      levelProperties.grammar = grammar ? grammar : defaultGrammar;

      const level = new Level(levelProperties);
      levels.push(level);

      if (level.getName() === config.lastActiveLevel) {
        properties.lastActiveLevel = level;
      }
    }

    return new Language(properties, levels);
  }
}

export default new LanguageRegistry();