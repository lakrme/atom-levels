{Emitter} = require('atom')
fs        = require('fs')
path      = require('path')
CSON      = require('season')

Language  = require('./language')
Level     = require('./level')

# ------------------------------------------------------------------------------

class LanguageRegistry

  constructor: ->
    @emitter = new Emitter
    @languagesDirPath = path.join(path.dirname(__dirname),'languages')
    @languagesByName = {}

  ## Event subscription --------------------------------------------------------

  onDidAddLanguage: (callback) ->
    @emitter.on('did-add-language',callback)

  onDidRemoveLanguage: (callback) ->
    @emitter.on('did-remove-language',callback)

  ## Adding languages to the registry ------------------------------------------

  addLanguage: (language) ->
    # set up event handlers
    language.onDidChangeProperties =>
      @handleLanguageDidChange(language)
    language.onDidAddLevel =>
      @handleLanguageDidChange(language)
    language.onDidRemoveLevel =>
      @handleLanguageDidChange(language)

    # add language and emit event
    @languagesByName[language.getName()] = language
    @emitter.emit('did-add-language',language)
    undefined

  readLanguage: (languageDirPath) ->
    # read configuration file
    config = CSON.readFileSync(path.join(languageDirPath,'config.json'))

    # adopt basic properties
    properties = {}
    properties.name = config.name
    properties.lastActiveLevel = config.lastActiveLevel
    properties.scopeName = config.scopeName
    properties.levelCodeFileTypes = config.levelCodeFileTypes
    properties.objectCodeFileType = config.objectCodeFileType
    properties.lineCommentPattern = config.lineCommentPattern
    properties.executionMode = config.executionMode
    properties.interpreterCmdPattern = config.interpreterCmdPattern
    properties.compilerCmdPattern = config.compilerCmdPattern
    properties.executionCmdPattern = config.executionCmdPattern

    # set the directory path
    properties.dirPath = languageDirPath

    # set the grammar name
    # TODO move the grammar name pattern to a package configuration object?
    grammarNamePattern = 'Levels: <languageName>'
    grammarName = grammarNamePattern.replace(/<languageName>/,config.name)
    properties.grammarName = grammarName

    # set the default grammar
    grammarsDirPath = path.join(languageDirPath,'grammars')
    if config.defaultGrammar?
      defaultGrammarPath = path.join(grammarsDirPath,config.defaultGrammar)
      defaultGrammar = atom.grammars.loadGrammarSync(defaultGrammarPath)
    else
      defaultGrammarPath = path.join(@languagesDirPath,'empty.cson')
      defaultGrammar = atom.grammars.loadGrammarSync(defaultGrammarPath)

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
      if levelConfig.grammar?
        grammarPath = path.join(grammarsDirPath,levelConfig.grammar)
        grammar = atom.grammars.readGrammarSync(grammarPath)
        grammar.name = grammarName
        grammar.scopeName = scopeName if scopeName?
        grammar.fileTypes = fileTypes if fileTypes?
      levelProperties.grammar = grammar ? defaultGrammar

      level = new Level(levelProperties)
      levels.push(level)

    new Language(properties,levels)

  loadLanguage: (languageDirPath) ->
    language = @readLanguage(languageDirPath)
    @addLanguage(language)
    language

  loadInstalledLanguages: ->
    for dirName in fs.readdirSync(@languagesDirPath)
      dirPath = path.join(@languagesDirPath,dirName)
      if fs.statSync(dirPath).isDirectory(dirPath)
        @loadLanguage(dirPath)
    undefined

  ## Removing languages from the registry --------------------------------------

  removeLanguage: (language) ->
    languageName = language.getName()
    if @getLanguageForName(languageName)?
      delete @languagesByName[languageName]
      @emitter.emit('did-remove-language',language)
      return language
    undefined

  ## Querying the language registry --------------------------------------------

  getLanguageForName: (languageName) ->
    @languagesByName[languageName]

  getLanguages: ->
    language for languageName,language of @languagesByName

  # languageForGrammar: (grammar) ->
  #   grammarNamePattern = configRegistry.get('grammarNamePattern')
  #   grammarNameMatch = grammarNamePattern.replace(/<languageName>/,'(.*)')
  #   grammarNameRegExp = new RegExp(grammarNameMatch)
  #   if (match = grammarNameRegExp.exec(grammar.name))?
  #     @languageForName(match[1])
  #
  # languagesForFileType: (fileType) ->
  #   results = []
  #   for lang in @languages when lang.fileTypes?
  #     if (i = lang.fileTypes.indexOf(fileType)) >= 0
  #       lowestIndex = i unless lowestIndex?
  #       switch
  #         when i <  lowestIndex then results = [lang]
  #         when i is lowestIndex then results.push(lang)
  #   results

  ## Reading from and writing to language configuration files ------------------

  # readLanguageFromConfigurationFile: (configPath) ->
  #
  #
  # writePropertyChangesToConfigurationFile: (languages,propertyChanges) ->
  #
  # writeLevelChangesToConfigurationFile: (languages,leve)
  #
  # writeLanguageToConfigurationFile: (language) ->
  #
  #   languageObjectPath = path.join(@dirPath,'config.json')
  #   languageObject = CSON.readFileSync(languageObjectPath)
  #   languageObject[key] = value for key,value of updates
  #   CSON.writeFileSync(languageObjectPath,languageObject)
  #   @emitter.emit('did-update',updates)

  ## Event handlers ------------------------------------------------------------

  handleLanguageDidChangeProperties: (language) ->
    @writeLanguageToConfigurationFile
    undefined

  handleLanguageDidChangeLevels: (language) ->
    undefined

# ------------------------------------------------------------------------------

module.exports =
class LanguageRegistryProvider

  instance = null

  @getInstance: ->
    instance ?= new LanguageRegistry

# ------------------------------------------------------------------------------
