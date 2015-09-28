{$,TextEditorView,View} = require('atom-space-pen-views')

# ------------------------------------------------------------------------------

module.exports =
class LanguageSettingsView extends View

  @content: ->
    @div class: 'levels-view panel language-settings', =>

      @div class: 'header', =>
        @h1 class: 'heading icon icon-gear', =>
          @text 'Language Configuration'

      @div class: 'settings-sections', =>
        @div class: 'settings-section', =>
          @div class: 'setting', =>
            @label class: 'setting-label', =>
              @div class: 'setting-title', =>
                @text 'Interpreter Command Pattern'
              @div class: 'setting-description', =>
                @text \
                  'The command to be used when running your level code program
                  in interpreted mode. Specifies how the generated object code
                  is passed to the interpreter. Must contain the <filePath>
                  variable to indicate where to insert the object code file
                  path.'
            @subview 'interpreterCmdPattern', new TextEditorView
              mini: true
              placeholderText: 'e.g. "ruby <filePath>"'
          @div class: 'setting', =>
            @label class: 'setting-label', =>
              @div class: 'setting-title', =>
                @text 'Compiler Command Pattern'
              @div class: 'setting-description', =>
                @text \
                  'The first command to be used when running your level code
                  program in compiled mode. Specifies how the generated object
                  code is passed to the compiler. Must contain the <filePath>
                  variable to indicate where to insert the object code file
                  path.'
            @subview 'compilerCmdPattern', new TextEditorView
              mini: true
              placeholderText: 'e.g. "ghc -v0 <filePath>"'
          @div class: 'setting', =>
            @label class: 'setting-label', =>
              @div class: 'setting-title', =>
                @text 'Execution Command Pattern'
              @div class: 'setting-description', =>
                @text \
                  'The second command to be used when running your level code
                  program in compiled mode. Specifies how the compiled object
                  code will be executed. Must contain the <filePath> variable to
                  indicate where to insert the path to the program.'
            @subview 'executionCmdPattern', new TextEditorView
              mini: true
              placeholderText: 'e.g. "java <filePath>"'
          @div class: 'setting', =>
            @label class: 'setting-label', =>
              @div class: 'setting-title', =>
                @text 'Execution Mode'
              @div class: 'setting-description', =>
                @text \
                  'Specifies the execution mode to be used when running your
                  level code program.'
            @select outlet: 'executionModeSelect'

      @div class: 'controls', =>
        @button class:'inline-block btn icon icon-history', \
            click: 'handleDidClickResetButton', =>
          @text 'Reset'
        @div class: 'block pull-right', =>
          @button class: 'inline-block btn', \
              click: 'handleDidClickCancelButton', =>
            @text 'Cancel'
          @button class: 'inline-block btn icon icon-check', \
              click: 'handleDidClickApplyButton', =>
            @text 'Apply'

  ## Initialization and destruction --------------------------------------------

  initialize: (@language,options={}) ->
    @onDidOpen = options.onDidOpen
    @onDidClose = options.onDidClose

    @updateCommandPatterns()
    @updateExecutionModes()

    @languageSubscr = @language.observe =>
      @updateOnDidChangeLanguage()

  destroy: ->
    @languageSubscr.dispose()

  ## Handling view events ------------------------------------------------------

  handleDidClickResetButton: ->


  handleDidClickCancelButton: ->
    @close()

  handleDidClickApplyButton: ->
    newProperties = {}
    if (interpreterCmdPattern = @interpreterCmdPattern.getText())
      newProperties.interpreterCmdPattern = interpreterCmdPattern
    else
      newProperties.interpreterCmdPattern = undefined
    if (compilerCmdPattern = @compilerCmdPattern.getText())
      newProperties.compilerCmdPattern = compilerCmdPattern
    else
      newProperties.compilerCmdPattern = undefined
    if (executionCmdPattern = @executionCmdPattern.getText())
      newProperties.executionCmdPattern = executionCmdPattern
    else
      newProperties.executionCmdPattern = undefined
    if (executionMode = @executionModeSelect.val())?
      newProperties.executionMode = executionMode
    @language.set({newProperties})

  ## Updating view components --------------------------------------------------

  updateOnDidChangeLanguage: ->
    console.log "changed"
    @updateCommandPatterns()
    @updateExecutionModes()

  updateCommandPatterns: ->
    if (interpreterCmdPattern = @language.getInterpreterCommandPattern())?
      @interpreterCmdPattern.setText(interpreterCmdPattern)
    if (compilerCmdPattern = @language.getCompilerCommandPattern())?
      @compilerCmdPattern.setText(compilerCmdPattern)
    if (executionCmdPattern = @language.getExecutionCommandPattern())?
      @executionCmdPattern.setText(executionCmdPattern)

  updateExecutionModes: ->
    @executionModeSelect.empty()
    for executionMode in @language.getExecutionModes()
      option = $("<option value=#{executionMode}>#{executionMode}</option>")
      if executionMode is @language.getExecutionMode()
        option.prop('selected',true)
      @executionModeSelect.append(option)

  ## Showing and hiding the language configuration panel -----------------------

  isVisible: ->
    @topPanel?

  open: ->
    unless @isVisible()
      @topPanel = atom.workspace.addTopPanel({item: @})
      outerHeight = @outerHeight()
      @css({top: "-#{outerHeight}px"})
      @animate {top: '-1px'}, 'fast', =>
        @onDidOpen?()

  close: ->
    if @isVisible()
      outerHeight = @outerHeight()
      @animate {top: "-#{outerHeight}px"}, 'fast', =>
        @topPanel.destroy()
        @topPanel = null
        @destroy()
        @onDidClose?()

# ------------------------------------------------------------------------------
