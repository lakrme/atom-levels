# ------------------------------------------------------------------------------

module.exports =

  ## Constants -----------------------------------------------------------------

  GRAMMAR_NAME_PATTERN: '<languageName> (Levels)'
  GRAMMAR_NAME_REG_EXP: /(.*) \(Levels\)/
  CONFIG_FILE_DESCRIPTION:
    name:
      fromConfigFileValue: (value) -> value
      toConfigFileValue: (value) -> value
    levels:
      fromConfigFileValue: (levels,configFile) ->
      toConfigFileValue: (levels,language) ->
    lastActiveLevel:
      fromConfigFileValue: (lastActiveLevelName,configFile) ->
      toConfigFileValue: (lastActiveLevel) ->
        lastActiveLevel.getName()
    objectCodeFileType:
      fromConfigFileValue: (value) -> value
      toConfigFileValue: (value) -> value
    executionCommandPatterns:
      fromConfigFileValue: (value) -> value
      toConfigFileValue: (value) -> value
    defaultGrammar:
      fromConfigFileValue: (defaultGrammarPath,configFile) ->
      toConfigFileValue: (defaultGrammar,language) ->
    levelCodeFileTypes:
      fromConfigFileValue: (value) -> value
      toConfigFileValue: (value) -> value
    lineCommentPattern:
      fromConfigFileValue: (value) -> value
      toConfigFileValue: (value) -> value

  ## Processing the configuration file -----------------------------------------

  isConfigFileKey: (property) ->
    property of @CONFIG_FILE_DESCRIPTION

  fromConfigFileValue: (property,value,configFile) ->
    @CONFIG_FILE_DESCRIPTION[property]?.fromConfigFileValue(value,configFile)

  toConfigFileValue: (property,value,language) ->
    @CONFIG_FILE_DESCRIPTION[property]?.toConfigFileValue(value,language)

# ------------------------------------------------------------------------------
