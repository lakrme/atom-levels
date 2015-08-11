fs   = require 'fs'
path = require 'path'
CSON = require 'season'
_    = require 'underscore-plus'

configRegistry = require('./core-config-registry').getInstance()
Language       = require './models-language'

# ------------------------------------------------------------------------------

module.exports =
class LanguageRegistry

  instance = null

  @getInstance: ->
    instance ?= new LanguageRegistry

  initialize: ->
    @languagesDirPath = path.join(path.dirname(__dirname),'languages')
    @languages        = []
    @languagesByName  = {}

    # read all languages from the languages/ directory
    for dirName in fs.readdirSync(@languagesDirPath)
      dirPath = path.join(@languagesDirPath,dirName)
      if fs.statSync(dirPath).isDirectory(dirPath)
        @loadLanguageSync(dirPath)

  ## Adding languages to the registry ------------------------------------------

  addLanguage: (lang) ->
    @languages.push(lang)
    @languagesByName[lang.name] = lang

  readLanguageSync: (langDirPath) ->
    # read language properties from configuration file
    langObject = CSON.readFileSync(path.join(langDirPath,'config.json'))

    grammarsDirPath = path.join(langDirPath,'grammars')
    grammarNamePattern = configRegistry.get('grammarNamePattern')
    grammarName = grammarNamePattern.replace(/<languageName>/,langObject.name)

    # set the language's default grammar
    if langObject.defaultGrammar?
      defaultGrammarPath = path.join(grammarsDirPath,langObject.defaultGrammar)
      defaultGrammar     = atom.grammars.loadGrammarSync(defaultGrammarPath)
    else
      defaultGrammarPath = path.join(@languagesDirPath,'empty.cson')
      defaultGrammar     = atom.grammars.loadGrammarSync(defaultGrammarPath)

    defaultGrammar.name = grammarName
    defaultGrammar.scopeName = langObject.scopeName if langObject.scopeName?
    defaultGrammar.fileTypes = langObject.fileTypes if langObject.fileTypes?

    # set up the language's levels and last active level
    levels = []
    levelsByName = {}
    for level,i in langObject.levels
      level.id = i
      if level.grammar?
        grammarPath = path.join(grammarsDirPath,level.grammar)
        grammar = atom.grammars.readGrammarSync(grammarPath)
        grammar.name = grammarName
        grammar.scopeName = langObject.scopeName if langObject.scopeName?
        grammar.fileTypes = langObject.fileTypes if langObject.fileTypes?
      level.grammar = grammar ? defaultGrammar
      levels.push(level)
      levelsByName[level.name] = level

    if (lastActiveLevel = langObject.lastActiveLevel)?
      langObject.lastActiveLevel = levelsByName[lastActiveLevel]

    # update language object and create language instance
    langObject.dirPath = langDirPath
    langObject.grammarName = grammarName
    langObject.levels = levels
    langObject.levelsByName = levelsByName
    new Language(langObject)

  loadLanguageSync: (langDirPath) ->
    lang = @readLanguageSync(langDirPath)
    @addLanguage(lang)
    lang

  ## Queries -------------------------------------------------------------------

  languageForName: (langName) ->
    @languagesByName[langName]

  languageForGrammar: (grammar) ->
    grammarNamePattern = configRegistry.get('grammarNamePattern')
    grammarNameMatch = grammarNamePattern.replace(/<languageName>/,'(.*)')
    grammarNameRegExp = new RegExp(grammarNameMatch)
    if (match = grammarNameRegExp.exec(grammar.name))?
      @languageForName(match[1])

  languages: ->
    _.clone(@languages)

  languagesForFileType: (fileType) ->
    results = []
    for lang in @languages when lang.fileTypes?
      if (i = lang.fileTypes.indexOf(fileType)) >= 0
        lowestIndex = i unless lowestIndex?
        switch
          when i <  lowestIndex then results = [lang]
          when i is lowestIndex then results.push(lang)
    results

  ## Installing and uninstalling languages -------------------------------------

  installLanguages: (paths) ->
    console.log paths

  uninstallLanguages: (langs) ->
    console.log langs

# ------------------------------------------------------------------------------
