'use babel';

export default class Level {
  constructor(properties) {
    this.properties = properties;
  }

  getNumber() {
    return this.properties.number;
  }

  getName() {
    return this.properties.name;
  }

  getDescription() {
    return this.properties.description;
  }

  getGrammar() {
    return this.properties.grammar;
  }

  getOption(option) {
    return this.properties.options[option];
  }

  getLanguage() {
    return this.language;
  }

  setLanguage(language) {
    this.language = language;
  }
}