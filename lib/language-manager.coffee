{Emitter}     = require('atom')
fs            = require('fs-plus')
path          = require('path')
CSON          = require('season')

languageUtils = require('./language-utils')

Language      = require('./language')
Level         = require('./level')

# ------------------------------------------------------------------------------

class LanguageManager

  ## Construction and initialization -------------------------------------------

  constructor: ->
    @emitter = new Emitter
    @languagesDirPath = path.join(path.dirname(__dirname),'languages')
    @languagesByName = {}
    @installing = false

  loadInstalledLanguages: ->
    for dirName in fs.readdirSync(@languagesDirPath)
      dirPath = path.join(@languagesDirPath,dirName)
      if fs.statSync(dirPath).isDirectory(dirPath)
        @loadLanguage(path.join(dirPath,'config.json'))
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

  onDidStartInstalling: (callback) ->
    @emitter.on('did-start-installing',callback)

  onDidStopInstalling: (callback) ->
    @emitter.on('did-stop-installing',callback)

  # onDidBeginInstallationStep: (callback) ->
  #   @emitter.on('did-begin-installation-phase',callback)
  #
  # onDidEndInstallationStep: (callback) ->
  #   @emitter.on('did-end-installation-phase',callback)

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

    # set configuration file path
    properties.configFilePath = configFilePath

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
        properties.lastActiveLevel ?= undefined

    # set executable path
    executablePath = config.executable
    unless path.isAbsolute(executablePath)
      executablePath = path.join(configDirPath,executablePath)
    properties.executablePath = executablePath

    new Language(properties,levels)

  writeLanguageToConfigurationFile: (language,configFilePath) ->
    defaultGrammarPath = language.getDefaultGrammar().path
    emptyGrammarPath = path.join(@languagesDirPath,'empty.cson')
    configDirPath = path.dirname(configFilePath)
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
    CSON.writeFileSync(configFilePath,config)

  ## Handling language changes -------------------------------------------------

  applyLanguageChanges: (language,changes) ->
    # TODO do something with the changes
    configFilePath = language.getConfigurationFilePath()
    @writeLanguageToConfigurationFile(language,configFilePath)
    undefined

  ## Installing and uninstalling languages -------------------------------------

  isInstalling: ->
    @installing

  installLanguage: (configFilePath) ->
    @installing = true
    @emitter.emit('did-start-installing')
    @validateConfigurationFile(configFilePath)

    configDirPath = path.dirname(configFilePath)
    config = CSON.readFileSync(configFilePath)

    grammarNamePattern = languageUtils.GRAMMAR_NAME_PATTERN
    grammarName = grammarNamePattern.replace(/<languageName>/,config.name)
    languageNameFormatted = config.name.replace(/\s+/g,'-').toLowerCase()
    languageDirPath = path.join(@languagesDirPath,languageNameFormatted)
    languageGrammarsDirPath = path.join(languageDirPath,'grammars')
    fs.mkdirSync(languageDirPath)
    fs.mkdirSync(languageGrammarsDirPath)

    configCopy = {}
    configCopy.name = config.name
    configCopy.scopeName = "levels.source.#{languageNameFormatted}"

    configCopy.levels = []
    for levelConfig in config.levels
      levelConfigCopy = {}
      levelConfigCopy.name = levelConfig.name
      levelConfigCopy.description = levelConfig.description
      if (grammarPath = levelConfig.grammar)?
        levelNameFormatted = levelConfig.name.replace(/\s+/g,'-').toLowerCase()
        levelConfigCopy.grammar = "grammars/#{levelNameFormatted}.cson"
        # copy level grammar to directory
        unless path.isAbsolute(grammarPath)
          grammarPath = path.join(configDirPath,grammarPath)
        grammar = CSON.readFileSync(grammarPath)
        grammarCopy = grammar
        delete grammarCopy.name
        delete grammarCopy.fileTypes
        delete grammarCopy.firstLineMatch
        grammarCopy.scopeName = configCopy.scopeName
        grammarCopyPath = path.join(languageDirPath,levelConfigCopy.grammar)
        CSON.writeFileSync(grammarCopyPath,grammarCopy)
      configCopy.levels.push(levelConfigCopy)

    if (defaultGrammarPath = config.defaultGrammar)?
      configCopy.defaultGrammar = 'grammars/default.cson'
      # write default grammar to directory
      unless path.isAbsolute(defaultGrammarPath)
        defaultGrammarPath = path.join(configDirPath,defaultGrammarPath)
      defaultGrammar = CSON.readFileSync(defaultGrammarPath)
      defaultGrammarCopy = defaultGrammar
      delete defaultGrammarCopy.name
      delete defaultGrammarCopy.fileTypes
      delete defaultGrammarCopy.firstLineMatch
      defaultGrammarCopy.scopeName = configCopy.scopeName
      defaultGrammarCopyPath = \
        path.join(languageDirPath,configCopy.defaultGrammar)
      CSON.writeFileSync(defaultGrammarCopyPath,defaultGrammarCopy)

    configCopy.levelCodeFileTypes = config.levelCodeFileTypes
    configCopy.objectCodeFileType = config.objectCodeFileType
    configCopy.lineCommentPattern = config.lineCommentPattern

    configCopy.executable = 'run'
    configCopy.executable += '.exe' if process.platform is 'win32'
    executablePath = config.executable
    unless path.isAbsolute(executablePath)
      executablePath = path.join(configDirPath,executablePath)
    executableCopyPath = path.join(languageDirPath,configCopy.executable)
    readStream = fs.createReadStream(executablePath)
    writeStream = fs.createWriteStream(executableCopyPath)
    readStream.pipe(writeStream)
    writeStream.on 'finish', =>
      fs.chmodSync(executableCopyPath,'755')

    configCopy.interpreterCmdPattern = config.interpreterCmdPattern
    configCopy.compilerCmdPattern = config.compilerCmdPattern
    configCopy.executionCmdPattern = config.executionCmdPattern

    configCopyFilePath = path.join(languageDirPath,'config.json')
    CSON.writeFileSync(configCopyFilePath,configCopy)

    # write dummy grammar
    dummyGrammar =
      name: grammarName
      scopeName: configCopy.scopeName
      fileTypes: configCopy.levelCodeFileTypes
    grammarsDirPath = path.join(path.dirname(__dirname),'grammars')
    dummyGrammarPath = \
      path.join(grammarsDirPath,"#{languageNameFormatted}.cson")
    CSON.writeFileSync(dummyGrammarPath,dummyGrammar)

    @loadLanguage(configCopyFilePath)
    atom.grammars.loadGrammarSync(dummyGrammarPath)

    @installing = false
    @emitter.emit('did-stop-installing')

  uninstallLanguage: (language) ->

  ## Validation ----------------------------------------------------------------

  validateConfigurationFile: (configFilePath) ->

# ------------------------------------------------------------------------------

module.exports =
class LanguageManagerProvider

  instance = null

  @getInstance: ->
    instance ?= new LanguageManager

# ------------------------------------------------------------------------------
