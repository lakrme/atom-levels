{Emitter}     = require('atom')
fs            = require('fs')
moment        = require('moment')
path          = require('path')
CSON          = require('season')

languageUtils = require('./language-utils')

Language      = require('./language')
Level         = require('./level')

# ------------------------------------------------------------------------------

class LanguageManager

  ## Construction --------------------------------------------------------------

  constructor: ->
    @emitter = new Emitter
    @languagesDirPath = path.join(path.dirname(__dirname),'languages')
    @languagesByName = {}
    @installing = false
    @uninstallung = false

  ## Event subscription --------------------------------------------------------

  observeLanguages: (callback) ->
    callback(language) for language in @getLanguages()
    @onDidAddLanguage(callback)

  onDidAddLanguage: (callback) ->
    @emitter.on('did-add-language',callback)

  onDidRemoveLanguage: (callback) ->
    @emitter.on('did-remove-language',callback)

  ## Adding languages ----------------------------------------------------------

  addLanguage: (language) ->
    # set up event handlers
    language.onDidChange (changes) =>
      @applyLanguageChanges(language,changes)

    # add language and emit event
    @languagesByName[language.getName()] = language
    @emitter.emit('did-add-language',language)
    undefined

  readLanguage: (configFilePath) ->
    @readLanguageFromConfigurationFile(configFilePath)

  loadLanguage: (configFilePath) ->
    language = @readLanguage(configFilePath)
    @addLanguage(language)
    language

  ## Removing languages --------------------------------------------------------

  removeLanguage: (language) ->
    languageName = language.getName()
    if @getLanguageForName(languageName)?
      delete @languagesByName[languageName]
      @emitter.emit('did-remove-language',language)
      return language
    undefined

  ## Queries -------------------------------------------------------------------

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
    installationDateFormat = languageUtils.INSTALLATION_DATE_FORMAT

    properties =
      name: config.name
      scopeName: config.scopeName
      levelCodeFileTypes: config.levelCodeFileTypes
      objectCodeFileType: config.objectCodeFileType
      lineCommentPattern: config.lineCommentPattern
      executionMode: config.executionMode
      interpreterCmdPattern: config.interpreterCmdPattern
      compilerCmdPattern: config.compilerCmdPattern
      executionCmdPattern: config.executionCmdPattern
      installationDate: moment(config.installationDate,installationDateFormat)
      configFilePath: configFilePath

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

    # create language levels
    levels = []
    for levelConfig,i in config.levels
      levelProperties =
        number: i
        name: levelConfig.name
        description: levelConfig.description
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
        properties.lastActiveLevel ?= undefined

    # set executable path
    executablePath = path.join(configDirPath,'executable',process.platform,'run')
    properties.executablePath = executablePath

    new Language(properties,levels)

  writeLanguageToConfigurationFile: (language,configFilePath) ->
    defaultGrammarPath = language.getDefaultGrammar().path
    emptyGrammarPath = path.join(@languagesDirPath,'empty.cson')
    configDirPath = path.dirname(configFilePath)
    installationDateFormat = languageUtils.INSTALLATION_DATE_FORMAT

    config = {}
    config.name = language.getName()
    config.levels =
      for level in language.getLevels()
        name = level.getName()
        description = level.getDescription()
        grammar = undefined
        grammarPath = level.getGrammar().path
        unless grammarPath is defaultGrammarPath
          grammar = path.relative(configDirPath,grammarPath)
        {name,description,grammar}
    config.lastActiveLevel = language.getLastActiveLevel()?.getName()
    unless defaultGrammarPath is emptyGrammarPath
      config.defaultGrammar = path.relative(configDirPath,defaultGrammarPath)
    config.scopeName = language.getScopeName()
    config.levelCodeFileTypes = language.getLevelCodeFileTypes()
    config.objectCodeFileType = language.getObjectCodeFileType()
    config.lineCommentPattern = language.getLineCommentPattern()
    executablePath = language.getExecutablePath()
    config.executable = path.relative(configDirPath,executablePath)
    config.executionMode = language.getExecutionMode()
    config.interpreterCmdPattern = language.getInterpreterCommandPattern()
    config.compilerCmdPattern = language.getCompilerCommandPattern()
    config.executionCmdPattern = language.getExecutionCommandPattern()
    config.installationDate = language.getInstallationDate().format \
      installationDateFormat

    CSON.writeFileSync(configFilePath,config)
    undefined

  ## Handling language changes -------------------------------------------------

  applyLanguageChanges: (language,changes) ->
    # TODO do something with the changes
    configFilePath = language.getConfigurationFilePath()
    @writeLanguageToConfigurationFile(language,configFilePath)
    undefined

  ## Validation ----------------------------------------------------------------

  validateConfigurationFile: (configFilePath) ->

# ------------------------------------------------------------------------------

module.exports =
class LanguageManagerProvider

  instance = null

  @getInstance: ->
    instance ?= new LanguageManager

# ------------------------------------------------------------------------------
