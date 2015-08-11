{Point} = require 'atom'
path    = require 'path'

configRegistry   = require('./core-config-registry').getInstance()
languageRegistry = require('./core-language-registry').getInstance()

# ------------------------------------------------------------------------------

module.exports =

  ## General workspace functions -----------------------------------------------

  getTextEditorForId: (textEditorId) ->
    for textEditor in atom.workspace.getTextEditors()
      if textEditor.id is textEditorId
        return textEditor
    undefined

  ## Reading and mutating language data information in the workspace -----------

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

  writeLanguageDataToFileHeader: (textEditor,{language,level}) ->
    fileHeader = configRegistry.get('fileHeaderPattern')
    fileHeader = fileHeader.replace(/<languageName>/,language.name)
    fileHeader = fileHeader.replace(/<levelName>/,level.name)

    # TODO toggle lines comments from grammar?
    if (lineCommentPattern = language.lineCommentPattern)?
      fileHeader = lineCommentPattern.replace(/<commentText>/,fileHeader)

    textEditor.getBuffer().insert(new Point(0,0),"#{fileHeader}\n")

  deleteFileHeader: (textEditor) ->
    textBuffer = textEditor.getBuffer()
    fileHeader = textBuffer.lineForRow(0)
    fileHeaderRegExp = configRegistry.get('fileHeaderRegExp')
    if fileHeaderRegExp.exec(fileHeader)?
      textBuffer.deleteRow(0)

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
