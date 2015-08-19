languageRegistry = require('./language-registry')

# ------------------------------------------------------------------------------

module.exports =

  ## Constants -----------------------------------------------------------------

  FILE_HEADER_PATTERN: 'Language: <languageName>, Level: <levelName>'
  FILE_HEADER_REG_EXP:  /Language:\s+(.+),\s+Level:\s+(.+)/

  ## Validating languages ------------------------------------------------------

  ## Writing language and level

  ## Writing and reading language information ---------------------------------

  deduceLanguageInformationFromTextEditor: (textEditor) ->

  deduceLanguageInformationFromFileHeader: ()

  deduceLanguageFromFilePath: (filePath) ->

  deduceLanguageFromGrammar: (grammar) ->


  readLanguageDataFromFileHeader: (textEditor) ->
    fileHeader = textEditor.getBuffer().lineForRow(0)
    fileHeaderRegExp = configRegistry.get('fileHeaderRegExp')
    if (match = fileHeaderRegExp.exec(fileHeader))?
      languageName = match[1]
      levelName = match[2]
      if (language = languageRegistry.languageForName(languageName))?
        languageData = {}
        languageData.language = language
        if (level = language.levelForName(levelName))?
          languageData.level = level
        else
          # TODO maybe show a notification here
          languageData.level = language.levelOnInitialization()
    return languageData

  readLanguageDataFromFilePath: (textEditor) ->
    filePath = textEditor.getBuffer().getPath()
    fileType = path.extname(filePath).substr(1)
    results = languageRegistry.languagesForFileType(fileType)
    switch
      when results.length >  1
        # TODO show notification? choose first language?
        console.log 'DUMMY'
      when results.length == 1
        languageData = {}
        languageData.language = results[0]
        languageData.level = results[0].levelOnInitialization()
    return languageData

  readLanguageDataFromGrammar: (textEditor) ->
    grammar = textEditor.getGrammar()
    if (language = languageRegistry.languageForGrammar(grammar))?
      languageData = {}
      languageData.language = language
      languageData.level = language.levelOnInitialization()
    return languageData

# ------------------------------------------------------------------------------
