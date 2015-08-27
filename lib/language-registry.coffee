{Emitter}     = require('atom')
fs            = require('fs')
path          = require('path')
CSON          = require('season')

languageUtils = require('./language-utils')

Language      = require('./language')
Level         = require('./level')

# ------------------------------------------------------------------------------

class LanguageRegistry

  ## Construction and initialization -------------------------------------------

  constructor: ->
    @emitter = new Emitter
    @languagesDirPath = path.join(path.dirname(__dirname),'languages')
    @languagesByName = {}

  loadInstalledLanguages: ->
    for dirName in fs.readdirSync(@languagesDirPath)
      dirPath = path.join(@languagesDirPath,dirName)
      if fs.statSync(dirPath).isDirectory(dirPath)
        @loadLanguage(dirPath)
    undefined

  ## Event subscription --------------------------------------------------------

  observeLanguages: (callback) ->
    callback(language) for language in @getLanguages()
    @onDidAddLanguage(callback)

  onDidAddLanguage: (callback) ->
    @emitter.on('did-add-language',callback)

  onDidRemoveLanguage: (callback) ->
    @emitter.on('did-remove-language',callback)

  onDidRemoveLanguages: (callback) ->
    @emitter.on('did-remove-languages',callback)

  ## Adding languages to the registry ------------------------------------------

  addLanguage: (language) ->
    # set up event handlers
    language.onDidChange (changes) =>
      @applyLanguageChanges(language,changes)

    # add language and emit event
    @languagesByName[language.getName()] = language
    @emitter.emit('did-add-language',language)
    undefined

  readLanguage: (languageDirPath) ->
    configFilePath = path.join(languageDirPath,'config.json')
    @readLanguageFromConfigurationFile(configFilePath)

  loadLanguage: (languageDirPath) ->
    language = @readLanguage(languageDirPath)
    @addLanguage(language)
    language

  ## Removing languages from the registry --------------------------------------

  removeLanguage: (language) ->
    removedLanguages = @removeLanguages([language])
    removedLanguages[0]

  removeLanguages: (languages) ->
    removedLanguages = []
    for language in languages
      languageName = language.getName()
      if @getLanguageForName(languageName)?
        delete @languagesByName[languageName]
        @emitter.emit('did-remove-language',language)
        removedLanguages.push(language)
    if removedLanguages.length > 0
      @emitter.emit('did-remove-languages',removedLanguages)
    removedLanguages

  ## Querying the language registry --------------------------------------------

  getLanguageForName: (languageName) ->
    @languagesByName[languageName]

  getLanguageForGrammar: (grammar) ->
    grammarNameRegExp = languageUtils.GRAMMAR_NAME_REG_EXP
    if (match = grammarNameRegExp.exec(grammar.name))?
      @getLanguageForName(match[1])

  getLanguages: ->
    language for languageName,language of @languagesByName

  getLanguagesForFileType: (fileType) ->
    results = []
    for languageName,language of @languagesByName
      fileTypes = language.getLevelCodeFileTypes()
      if fileTypes? and (i = fileTypes.indexOf(fileType)) >= 0
        lowestIndex = i unless lowestIndex?
        switch
          when i <  lowestIndex then results = [language]
          when i is lowestIndex then results.push(language)
    results

  ## Reading and writing language configuration files --------------------------

  readLanguageFromConfigurationFile: (configFilePath) ->
    configDirPath = path.dirname(configFilePath)
    config = CSON.readFileSync(configFilePath)

    # adopt basic properties
    properties = {}
    properties.name = config.name
    properties.scopeName = config.scopeName
    properties.levelCodeFileTypes = config.levelCodeFileTypes
    properties.objectCodeFileType = config.objectCodeFileType
    properties.lineCommentPattern = config.lineCommentPattern
    properties.executionMode = config.executionMode
    properties.interpreterCmdPattern = config.interpreterCmdPattern
    properties.compilerCmdPattern = config.compilerCmdPattern
    properties.executionCmdPattern = config.executionCmdPattern

    # set the language directory path
    properties.dirPath = path.dirname(configFilePath)

    # set the default grammar
    if (defaultGrammarPath = config.defaultGrammar)?
      unless path.isAbsolute(defaultGrammarPath)
        defaultGrammarPath = path.join(configDirPath,defaultGrammarPath)
    else
      defaultGrammarPath = path.join(@languagesDirPath,'empty.cson')
    defaultGrammar = atom.grammars.readGrammarSync(defaultGrammarPath)

    grammarNamePattern = languageUtils.GRAMMAR_NAME_PATTERN
    grammarName = grammarNamePattern.replace(/<languageName>/,config.name)
    scopeName = config.scopeName
    fileTypes = config.levelCodeFileTypes
    defaultGrammar.name = grammarName
    defaultGrammar.scopeName = scopeName if scopeName?
    defaultGrammar.fileTypes = fileTypes if fileTypes?
    properties.defaultGrammar = defaultGrammar

    # create the language levels
    levels = []
    for levelConfig,i in config.levels
      levelProperties = {}
      levelProperties.number = i
      # adopt basic properties
      levelProperties.name = levelConfig.name
      levelProperties.description = levelConfig.description
      # set level grammar
      grammar = null
      if (grammarPath = levelConfig.grammar)?
        unless path.isAbsolute(grammarPath)
          grammarPath = path.join(configDirPath,grammarPath)
        grammar = atom.grammars.readGrammarSync(grammarPath)
        grammar.name = grammarName
        grammar.scopeName = scopeName if scopeName?
        grammar.fileTypes = fileTypes if fileTypes?
      levelProperties.grammar = grammar ? defaultGrammar
      # create level instance
      level = new Level(levelProperties)
      levels.push(level)
      # create last active level reference
      if level.getName() is config.lastActiveLevel
        properties.lastActiveLevel = level
      else
        properties.lastActiveLevel = undefined

    new Language(properties,levels)

  writeLanguageToConfigurationFile: (language,configFilePath) ->
    config = {}
    config.name = language.getName()
    config.levels =
      for level in language.getLevels()
        name: level.getName()
        description: level.getDescription()
        # TODO filter default/empty grammar
        grammar: level.getGrammar().path
    config.lastActiveLevel = language.getLastActiveLevel()?.getName()
    config.defaultGrammar = language.getDefaultGrammar()?.path
    config.scopeName = language.getScopeName()
    config.levelCodeFileTypes = language.getLevelCodeFileTypes()
    config.objectCodeFileType = language.getObjectCodeFileType()
    config.lineCommentPattern = language.getLineCommentPattern()
    config.executionMode = language.getExecutionMode()
    config.interpreterCmdPattern = language.getInterpreterCommandPattern()
    config.compilerCmdPattern = language.getCompilerCommandPattern()
    config.executionCmdPattern = language.getExecutionCommandPattern()
    CSON.writeFileSync(configFilePath,config)

  ## Handling language changes -------------------------------------------------

  applyLanguageChanges: (language,changes) ->
    # TODO do something with the changes
    configFilePath = path.join(language.getDirectoryPath(),'config.json')
    @writeLanguageToConfigurationFile(language,configFilePath)
    undefined

# ------------------------------------------------------------------------------

module.exports =
class LanguageRegistryProvider

  instance = null

  @getInstance: ->
    instance ?= new LanguageRegistry

# ------------------------------------------------------------------------------
