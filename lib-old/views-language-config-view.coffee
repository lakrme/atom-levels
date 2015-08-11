{TextEditorView,View} = require 'atom-space-pen-views'

# ------------------------------------------------------------------------------

module.exports =
class LanguageConfigView extends View

  @content: ->
    @div class: 'levels-view language-config', =>
      @div class: 'section-container', =>
        @div class: 'section-heading icon icon-gear', => @text 'File Types'
        @div class: 'section-body', =>
          @div class: 'control-group', =>
            @div class: 'controls', =>
              @label class: 'control-label', =>
                @div class: 'config-title', =>
                  @text 'Level Code File Types:'
                @div class: 'config-description', =>
                  @text 'This is a description.'
              @div class: 'editor-container', =>
                @subview 'levelCodeFileTypes', new TextEditorView(mini: true), =>
          @div class: 'control-group', =>
            @div class: 'controls', =>
              @label class: 'control-label', =>
                @div class: 'config-title', =>
                  @text 'Object Code File Type:'
                @div class: 'config-description', =>
                  @text 'This is a description.'
              @div class: 'editor-container', =>
                @subview 'objectCodeFileType', new TextEditorView(mini: true), =>
      @div class: 'section-container', =>
        @div class: 'section-heading icon icon-gear', => @text 'Commands'
        @div class: 'section-body', =>
          @div class: 'control-group', =>
            @div class: 'controls', =>
              @label class: 'control-label', =>
                @div class: 'config-title', =>
                  @text 'Interpreter Command:'
                @div class: 'config-description', =>
                  @text 'This is a description.'
              @div class: 'editor-container', =>
                @subview 'interpreterCmdPattern', new TextEditorView(mini: true), =>
          @div class: 'control-group', =>
            @div class: 'controls', =>
              @label class: 'control-label', =>
                @div class: 'config-title', =>
                  @text 'Compiler Command:'
                @div class: 'config-description', =>
                  @text 'This is a description.'
              @subview 'compilerCmdPattern', new TextEditorView(mini: true), =>
          @div class: 'control-group', =>
            @div class: 'controls', =>
              @label class: 'control-label', =>
                @div class: 'config-title', =>
                  @text 'Execution Command:'
                @div class: 'config-description', =>
                  @text 'This is a description.'
              @subview 'executionCmdPattern', new TextEditorView(mini: true), =>
      @button class: 'btn icon icon-check', click: 'save', => @text 'Save'

      # @div class: 'control-group', =>
      #   @div class: 'controls', =>
      #     @label class: 'control-label', => @text 'Default level:'
      #     @select class: 'form-control', =>

  initialize: (@viewManager) ->

  destroy: ->
    @panel?.destroy()

  # save: (event,element) ->
  #   interpretedPath = @intcmd.getText()
  #   level = @find('select option:selected').text()
  #   console.log interpretedPath
  #   console.log level
  #   # save to language registry
  #   main.languages.languageForName(@languageName).defaultLevel = level
  #   main.languages.languageForName(@languageName).interpreterCmd = interpretedPath
  #   packageDirPath = main.packagePath
  #   path = "#{packageDirPath}/languages/#{@languageName}/config.json"
  #   conf = CSON.readFileSync(path)
  #   conf.defaultLevel = level
  #   conf.interpreterCmd = interpretedPath
  #   CSON.writeFileSync(path,conf)
  #   @panel.hide()

  ## Displaying the language settings panel ------------------------------------

  show: (languageData) ->
    @update(languageData)
    @panel ?= atom.workspace.addModalPanel(item: this,visible: true)

  hide: ->
    @panel?.destroy()
    @panel = null

  toggle: (languageData) ->
    if @panel?
      @hide()
    else
      @show(languageData)

  update: (@languageData) ->


  # toggle: ({@language,@level}) ->
  #   @languageName = language.name
  #   if @panel.isVisible()
  #     @panel.hide()
  #   else
  #     @find('select').empty()
  #     for levelName of language.levels
  #       if levelName is language.defaultLevel
  #         @find('select').append("<option selected>#{levelName}</option>")
  #       else
  #         @find('select').append("<option>#{levelName}</option>")
  #     interpreterCmd = language.interpreterCmd
  #     @intcmd.setText(interpreterCmd)
  #     @panel.show()
