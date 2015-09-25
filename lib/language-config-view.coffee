{View} = require('atom-space-pen-views')

# ------------------------------------------------------------------------------

module.exports =
class LanguageConfigView extends View

  @content: ->
    @div class: 'language-config', =>
      @div class: 'language-cards', outlet: 'languageCards', =>
        @text 'hjksdhf'
      @div class: 'controls', =>
        @div class: 'block pull-left', =>
          @button class:'inline-block btn', \
              # click: 'handleDidClickBackButton', \
              outlet: 'backButton', =>
            @text 'All Languages'
        @div class: 'block pull-right', =>
          @button class: 'inline-block btn icon icon-chevron-left', \
              # click: 'handleDidClickCancelButton', \
              outlet: 'cancelButton', =>
            @text 'Cancel'
          @button class: 'inline-block btn icon icon-plus', \
              # click: 'handleDidClickInstallLanguageButton', \
              outlet: 'installLanguageButton', =>
            @text 'Install Language'

  ## Initialization and destruction --------------------------------------------

  initialize: (@languageManagerView) ->
    # initialize view components

  destroy: ->

# ------------------------------------------------------------------------------
