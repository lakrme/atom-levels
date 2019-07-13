'use babel';

export const GRAMMAR_NAME_PATTERN = '<languageName> (Levels)';
export const GRAMMAR_NAME_REG_EXP = /(.*) \(Levels\)/;
export const CONFIG_FILE_DESCRIPTION = {
  name: {
    fromConfigFileValue(name) {
      return name;
    },
    toConfigFileValue(name) {
      return name;
    }
  },
  levels: {
    fromConfigFileValue(levels) {
      return levels;
    },
    toConfigFileValue(levels) {
      return levels;
    }
  },
  defaultGrammar: {
    fromConfigFileValue(defaultGrammarPath) {
      return defaultGrammarPath;
    },
    toConfigFileValue(defaultGrammarPath) {
      return defaultGrammarPath;
    }
  },
  levelCodeFileTypes: {
    fromConfigFileValue(fileTypes) {
      return fileTypes;
    },
    toConfigFileValue(fileTypes) {
      return fileTypes;
    }
  },
  objectCodeFileType: {
    fromConfigFileValue(fileType) {
      return fileType;
    },
    toConfigFileValue(fileType) {
      return fileType;
    }
  },
  lineCommentPattern: {
    fromConfigFileValue(pattern) {
      return pattern;
    },
    toConfigFileValue(pattern) {
      return pattern;
    }
  },
  executionCommandPatterns: {
    fromConfigFileValue(patterns) {
      return patterns;
    },
    toConfigFileValue(patterns) {
      return patterns;
    }
  },
  lastActiveLevel: {
    fromConfigFileValue(activeLevelName) {
      return activeLevelName;
    },
    toConfigFileValue(activeLevel) {
      return activeLevel.getName();
    }
  }
};

export function isConfigFileKey(property) {
  return Object.prototype.hasOwnProperty.call(CONFIG_FILE_DESCRIPTION, property);
}

export function fromConfigFileValue(property, value) {
  if (isConfigFileKey(property)) {
    return CONFIG_FILE_DESCRIPTION[property].fromConfigFileValue(value);
  }
}

export function toConfigFileValue(property, value) {
  if (isConfigFileKey(property)) {
    return CONFIG_FILE_DESCRIPTION[property].toConfigFileValue(value);
  }
}