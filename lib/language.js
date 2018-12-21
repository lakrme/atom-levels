'use babel';

import {Emitter}          from 'atom';
import CSON               from 'season';
import * as languageUtils from './language-utils';

export default class Language {
  constructor(properties, levels) {
    this.properties = properties;
    this.emitter = new Emitter();

    this.levelsByName = {};
    for (const level of levels) {
      level.setLanguage(this);
      this.levelsByName[level.getName()] = level;
    }
  }

  destroy() {
    this.emitter.dispose();
  }

  observe(callback) {
    callback();

    return this.onDidChange((event) => callback(event));
  }

  onDidChange() {
    let callback, property;
    switch (arguments.length) {
      case 1:
        [callback] = arguments;
        break;
      case 2:
        [property, callback] = arguments;
        break;
      default:
    }

    return this.emitter.on('did-change', (event) => {
      if (!property || property === event.property) {
        return callback(event);
      }
    });
  }

  getName() {
    return this.properties.name;
  }

  getLevels() {
    const levels = [];
    for (const name in this.levelsByName) {
      levels.push(this.levelsByName[name]);
    }

    return levels.sort((x, y) => x.getNumber() >= y.getNumber() ? 1 : -1);
  }

  getLevelsByName() {
    return this.levelsByName;
  }

  getLevelForNumber(levelNumber) {
    for (const name in this.levelsByName) {
      const level = this.levelsByName[name];
      if (level.getNumber() === levelNumber) {
        return level;
      }
    }
  }

  getLevelForName(levelName) {
    return this.levelsByName[levelName];
  }

  getLastActiveLevel() {
    return this.properties.lastActiveLevel;
  }

  getLevelOnInitialization() {
    const activeLevel = this.getLastActiveLevel();

    return activeLevel ? activeLevel : this.getLevelForNumber(1);
  }

  getObjectCodeFileType() {
    return this.properties.objectCodeFileType;
  }

  getExecutionCommandPatterns() {
    return this.properties.executionCommandPatterns;
  }

  getConfigFilePath() {
    return this.properties.configFilePath;
  }

  getExecutablePath() {
    return this.properties.executablePath;
  }

  getDummyGrammar() {
    return this.properties.dummyGrammar;
  }

  getDefaultGrammar() {
    return this.properties.defaultGrammar;
  }

  getGrammarName() {
    return this.properties.grammarName;
  }

  getScopeName() {
    return this.properties.scopeName;
  }

  getLevelCodeFileTypes() {
    return this.properties.levelCodeFileTypes;
  }

  getLineCommentPattern() {
    return this.properties.lineCommentPattern;
  }

  isExecutable() {
    return this.properties.executionCommandPatterns.length > 0;
  }

  setObjectCodeFileType(fileType) {
    this.setPropertyAndUpdateConfigFile('objectCodeFileType', fileType);
  }

  setExecutionCommandPatterns(patterns) {
    this.setPropertyAndUpdateConfigFile('executionCommandPatterns', patterns);
  }

  setDummyGrammar(dummyGrammar) {
    this.setPropertyAndUpdateConfigFile('dummyGrammar', dummyGrammar);
  }

  setLevelCodeFileTypes(fileTypes) {
    this.setPropertyAndUpdateConfigFile('levelCodeFileTypes', fileTypes);
  }

  setLineCommentPattern(pattern) {
    this.setPropertyAndUpdateConfigFile('lineCommentPattern', pattern);
  }

  setLastActiveLevel(lastActiveLevel) {
    this.setPropertyAndUpdateConfigFile('lastActiveLevel', lastActiveLevel);
  }

  setPropertyAndUpdateConfigFile(property, value) {
    const oldValue = this.properties[property];
    this.properties[property] = value;
    this.emitter.emit('did-change', {property, oldValue, value});
    this.updateConfigFile(property, value);
  }

  updateConfigFile(property, value) {
    if (languageUtils.isConfigFileKey(property)) {
      const configFilePath = this.properties.configFilePath;
      const configFile = CSON.readFileSync(configFilePath);
      const convertedValue = languageUtils.toConfigFileValue(property, value);
      configFile[property] = convertedValue;
      CSON.writeFileSync(configFilePath, configFile);
    }
  }

  hasLevel(level) {
    return level.getLanguage() === this && this.getLevelForName(level.getName());
  }
}