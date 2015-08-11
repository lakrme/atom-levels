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
    @languages = []
    @languagesByName = {}

  ## Event subscription --------------------------------------------------------

  onDidAddLanguage: (callback) ->
    @emitter.on('did-add-language',callback)

  onDidRemoveLanguage: (callback) ->
    @emitter.on('did-remove-language',callback)

  ## Adding languages to the registry ------------------------------------------

  addLanguage: (language) ->
    @languages.push(language)
    @languagesByName[language.name] = language
    @emitter.emit('did-add-language',language)

  readLanguage: (languageDirPath) ->
    # read language properties from configuration file
    languageObject = CSON.readFileSync(path.join(languageDirPath,'config.json'))

    # set the directory path
    languageObject.dirPath = languageDirPath

    # set the grammar name
    grammarsDirPath = path.join(languageDirPath,'grammars')
    grammarNamePattern = 'Levels: <languageName>'
    grammarName = grammarNamePattern.replace(/<languageName>/,languageObject.name)
    languageObject.grammarName = grammarName

    # set the default grammar
    if languageObject.defaultGrammar?
      defaultGrammarPath = path.join(grammarsDirPath,languageObject.defaultGrammar)
      defaultGrammar = atom.grammars.loadGrammarSync(defaultGrammarPath)
    else
      defaultGrammarPath = path.join(@languagesDirPath,'empty.cson')
      defaultGrammar = atom.grammars.loadGrammarSync(defaultGrammarPath)

    defaultGrammar.name = grammarName
    if languageObject.scopeName?
      defaultGrammar.scopeName = languageObject.scopeName
    if languageObject.levelCodeFileTypes?
      defaultGrammar.fileTypes = languageObject.levelCodeFileTypes
    languageObject.defaultGrammar = defaultGrammar

    # create and set the language levels
    levels = []
    levelsByName = {}
    for levelObject in languageObject.levels

      grammar = null
      if levelObject.grammar?
        grammarPath = path.join(grammarsDirPath,levelObject.grammar)
        grammar = atom.grammars.readGrammarSync(grammarPath)
        grammar.name = grammarName
        if languageObject.scopeName?
          grammar.scopeName = languageObject.scopeName
        if languageObject.levelCodeFileTypes?
          grammar.fileTypes = languageObject.levelCodeFileTypes
      levelObject.grammar = grammar ? defaultGrammar

      level = new Level(levelObject)
      levels.push(level)
      levelsByName[level.name] = level

    languageObject.levels = levels
    languageObject.levelsByName = levelsByName

    # set the last active level
    if (lastActiveLevel = languageObject.lastActiveLevel)?
      languageObject.lastActiveLevel = levelsByName[lastActiveLevel]

    new Language(languageObject)

  loadLanguage: (languageDirPath) ->
    language = @readLanguage(languageDirPath)
    @addLanguage(language)
    language

  loadInstalledLanguages: ->
    for dirName in fs.readdirSync(@languagesDirPath)
      dirPath = path.join(@languagesDirPath,dirName)
      if fs.statSync(dirPath).isDirectory(dirPath)
        @loadLanguage(dirPath)

  ## Removing languages from the registry --------------------------------------

  # removeLanguage: (language) ->
  #   if languageForName(language.name)?
  #     _.remove(@languages,language)
  #     delete @languagesByName[language.name]
  #     @emitter.emit('did-remove-language',language)
  #     return language
  #   undefined

  ## Querying the language registry --------------------------------------------

  # languageForName: (languageName) ->
  #   @languagesByName[languageName]
  #
  # languageForGrammar: (grammar) ->
  #   grammarNamePattern = configRegistry.get('grammarNamePattern')
  #   grammarNameMatch = grammarNamePattern.replace(/<languageName>/,'(.*)')
  #   grammarNameRegExp = new RegExp(grammarNameMatch)
  #   if (match = grammarNameRegExp.exec(grammar.name))?
  #     @languageForName(match[1])
  #
  # languages: ->
  #   _.clone(@languages)
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

# ------------------------------------------------------------------------------

module.exports =
class LanguageRegistryProvider

  instance = null

  @getInstance: ->
    instance ?= new LanguageRegistry

# ------------------------------------------------------------------------------
