{Disposable,Emitter} = require('atom')
fs                   = require('fs')
path                 = require('path')
CSON                 = require('season')

languageUtils        = require('./language-utils')

Language             = require('./language')
Level                = require('./level')

# ------------------------------------------------------------------------------

class LanguageRegistry

  ## Construction --------------------------------------------------------------

  constructor: ->
    @emitter = new Emitter
    @languagesByName = {}

  ## Event subscription --------------------------------------------------------

  # Public: Invoke the given callback with all current and future languages in
  # the language registry.
  #
  # * `callback` {Function} to be called with current and future languages.
  #   * `language` A {Language} that is present in the language registry at the
  #     time of subscription or that is added at some later time.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  observeLanguages: (callback) ->
    callback(language) for language in @getLanguages()
    @onDidAddLanguage(callback)

  # Public: Invoke the given callback when a language is added to the language
  # registry.
  #
  # * `callback` {Function} to be called when a language is added.
  #   * `language` The {Language} that was added.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidAddLanguage: (callback) ->
    @emitter.on('did-add-language',callback)

  # Public: Invoke the given callback when a language is removed from the
  # language registry.
  #
  # * `callback` {Function} to be called when a language is removed.
  #   * `language` The {Language} that was removed.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidRemoveLanguage: (callback) ->
    @emitter.on('did-remove-language',callback)

  ## Adding languages ----------------------------------------------------------

  # Public: Add a language to the language registry.
  #
  # Emits a 'did-add-language' event after adding the language.
  #
  # * `language` The {Language} to be added to the registry. This should be a
  #   value previously returned from {::readLanguageSync}.
  # * `options` (optional) An {Object} with additional options:
  #   * `addNewDummyGrammar` (optional) A {Boolean} indicating whether or not to
  #     create and add a fresh dummy grammar for the given language. The dummy
  #     grammar "represents" the language and makes it selectable via the
  #     grammar selection. Selecting the dummy grammar activates the appropriate
  #     language and causes Levels to subsequently set the correct level
  #     grammar. (default: `false`)
  #
  # Returns a {Disposable} on which `.dispose()` can be called to remove the
  # language.
  addLanguage: (language,{addNewDummyGrammar}={}) ->
    if addNewDummyGrammar
      dummyGrammar = atom.grammars.createGrammar undefined,
        name: language.getGrammarName()
        scopeName: language.getScopeName()
        fileTypes: language.getLevelCodeFileTypes()
      language.setDummyGrammar(dummyGrammar)
      atom.grammars.addGrammar(dummyGrammar)

    @languagesByName[language.getName()] = language
    @emitter.emit('did-add-language',language)
    new Disposable(=> @removeLanguage(language))

  # Public: Read a language synchronously but don't add it to the registry.
  #
  # Only languages in the language registry are ready to be used with the Levels
  # package. Languages can be added to the registry with {::addLanguage}.
  #
  # * `configFilePath` A {String} absolute file path to the language's
  #   configuration file.
  # * `executablePath` A {String} absolute file path to the language's
  #   executable.
  #
  # Returns a {Language}.
  readLanguageSync: (configFilePath,executablePath) ->
    configFile = @validateConfigFile(configFilePath)
    configFile.path = configFilePath
    @createLanguage(configFile,executablePath)

  # Public: Read a language synchronously and add it to the registry.
  #
  # * `configFilePath` A {String} absolute file path to the language's
  #   configuration file.
  # * `executablePath` A {String} absolute file path to the language's
  #   executable.
  # * `options` (optional) An {Object} with additional options. See
  #   {::addLanguage} for more details.
  #
  # Returns a {Language}.
  loadLanguageSync: (configFilePath,executablePath,options) ->
    language = @readLanguageSync(configFilePath,executablePath)
    @addLanguage(language,options)
    language

  ## Removing languages --------------------------------------------------------

  # Public: Remove the given language from the language registry.
  #
  # Emits a 'did-remove-language' event after removing the language.
  #
  # * `language` The {Language} to be removed from the registry.
  #
  # Returns the removed {Language} or `undefined`.
  removeLanguage: (language) ->
    languageName = language.getName()
    if @getLanguageForName(languageName)?
      delete @languagesByName[languageName]
      @emitter.emit('did-remove-language',language)
      return language
    undefined

  ## Queries -------------------------------------------------------------------

  # Public: Get a language with the given name.
  #
  # * `languageName` The name of the language as a {String}.
  #
  # Returns a {Language} or `undefined`.
  getLanguageForName: (languageName) ->
    @languagesByName[languageName]

  # Public: Get a language that is associated with the given grammar.
  #
  # The grammar can be the dummy grammar or a level grammar of the language.
  #
  # * `grammar` The language's {Grammar}.
  #
  # Returns a {Language} or `undefined`.
  getLanguageForGrammar: (grammar) ->
    for language in @getLanguages()
      if grammar is language.getDummyGrammar()
        return language
      for level in language.getLevels()
        if grammar is level.getGrammar()
          return language
    undefined

  # Public: Get all the languages in this registry.
  #
  # Returns an {Array} of {Language} instances.
  getLanguages: ->
    language for languageName,language of @languagesByName

  # Public: Get the best matching languages in the registry that are associated
  # with the given level code file type.
  #
  # If there are multiple level code file types given for a language, the
  # foremost ones in the file types array are supposed to have the highest
  # priority. This picks the language(s) with the highest priority defined for
  # the given file type.
  #
  # * `fileType` The level code file type as a {String} (e.g. `"rb"`).
  #
  # Returns an {Array} of {Language} instances.
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

  ## Creating languages from configuration files -------------------------------

  validateConfigFile: (configFilePath) ->
    configFile = CSON.readFileSync(configFilePath)

  createLanguage: (config,executablePath) ->
    # adopt basic properties
    properties =
      name: config.name
      objectCodeFileType: config.objectCodeFileType
      lineCommentPattern: config.lineCommentPattern
      executionCommandPatterns: config.executionCommandPatterns
      configFilePath: config.path
      executablePath: executablePath

    # set the default grammar
    grammarNamePattern = languageUtils.GRAMMAR_NAME_PATTERN
    grammarName = grammarNamePattern.replace(/<languageName>/,config.name)
    languageNameFormatted = config.name.replace(/\s+/g,'-').toLowerCase()
    scopeName = "levels.source.#{languageNameFormatted}"
    fileTypes = config.levelCodeFileTypes ? []

    if (defaultGrammarPath = config.defaultGrammar)?
      unless path.isAbsolute(defaultGrammarPath)
        defaultGrammarPath = path.join(config.path,'..',defaultGrammarPath)
      defaultGrammar = atom.grammars.readGrammarSync(defaultGrammarPath)
      defaultGrammar.name = grammarName
      defaultGrammar.scopeName = scopeName
      defaultGrammar.fileTypes = fileTypes
    else
      defaultGrammar = atom.grammars.createGrammar undefined,
        name: grammarName
        scopeName: scopeName
        fileTypes: fileTypes

    properties.grammarName = grammarName
    properties.scopeName = scopeName
    properties.levelCodeFileTypes = fileTypes
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
          grammarPath = path.join(config.path,'..',grammarPath)
        grammar = atom.grammars.readGrammarSync(grammarPath)
        grammar.name = grammarName
        grammar.scopeName = scopeName
        grammar.fileTypes = fileTypes
      levelProperties.grammar = grammar ? defaultGrammar

      # create level instance
      level = new Level(levelProperties)
      levels.push(level)

      # create last active level reference
      if level.getName() is config.lastActiveLevel
        properties.lastActiveLevel = level
      else
        properties.lastActiveLevel ?= undefined

    new Language(properties,levels)

# ------------------------------------------------------------------------------

module.exports =
class LanguageRegistryProvider

  instance = null

  @getInstance: ->
    instance ?= new LanguageRegistry

# ------------------------------------------------------------------------------
