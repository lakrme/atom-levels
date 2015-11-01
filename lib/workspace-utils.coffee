{Point}          = require('atom')
path             = require('path')

languageRegistry = require('./language-registry').getInstance()

# ------------------------------------------------------------------------------

module.exports =

  ## Constants -----------------------------------------------------------------

  DEFAULT_WHEN_TO_WRITE_FILE_HEADER: 'before saving the buffer'
  DEFAULT_CLEAR_TERMINAL_ON_EXECUTION: true
  FILE_HEADER_PATTERN: 'Language: <languageName>, Level: <levelName>'
  FILE_HEADER_REG_EXP:  /Language:\s+(.+),\s+Level:\s+(.+)/

  ## Writing and reading language information to and from text editors ---------

  writeLanguageInformationFileHeader: (textEditor,language,level) ->
    fileHeader = @FILE_HEADER_PATTERN
    fileHeader = fileHeader.replace(/<languageName>/,language.getName())
    fileHeader = fileHeader.replace(/<levelName>/,level.getName())
    # TODO toggle lines comments from grammar?
    lineCommentPattern = language.getLineCommentPattern()
    if lineCommentPattern and lineCommentPattern.indexOf('<comment>') > -1
      fileHeader = lineCommentPattern.replace(/<comment>/,fileHeader)
      textEditor.getBuffer().insert(new Point(0,0),"#{fileHeader}\n")

  deleteLanguageInformationFileHeader: (textEditor) ->
    textBuffer = textEditor.getBuffer()
    fileHeader = textBuffer.lineForRow(0)
    if @FILE_HEADER_REG_EXP.exec(fileHeader)?
      textBuffer.deleteRow(0)

  readLanguageInformationFromTextEditor: (textEditor) ->
    result = @readLanguageInformationFromFileHeader(textEditor)
    language = result?.language
    level = result?.level
    language ?= @readLanguageFromFileExtension(textEditor)
    language ?= languageRegistry.getLanguageForGrammar(textEditor.getGrammar())
    if language?
      return {language,level}
    undefined

  readLanguageInformationFromFileHeader: (textEditor) ->
    fileHeader = textEditor.getBuffer().lineForRow(0)
    if (match = @FILE_HEADER_REG_EXP.exec(fileHeader))?
      languageName = match[1]
      levelName = match[2]
      if (language = languageRegistry.getLanguageForName(languageName))?
        result = {language}
        if (level = language.getLevelForName(levelName))?
          result.level = level
        else
          # TODO maybe show a notification here
          console.log "Levels: level malformed in file header?"
    result

  readLanguageFromFileExtension: (textEditor) ->
    if (filePath = textEditor.getBuffer().getPath())?
      fileType = path.extname(filePath).substr(1)
      results = languageRegistry.getLanguagesForFileType(fileType)
      # TODO maybe show a notification for the >1 case
      if results.length >= 1
        result = results[0]
    result

# ------------------------------------------------------------------------------
