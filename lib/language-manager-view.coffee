{CompositeDisposable}      = require('atom')
{$,$$,TextEditorView,View} = require('atom-space-pen-views')
dialog                     = require('remote').require('dialog')
moment                     = require('moment')

languageManager            = require('./language-manager').getInstance()

languageUtils              = require('./language-utils')

LanguageSettingsView       = require('./language-settings-view')
ProgressPanelView          = require('./progress-panel-view')

# ------------------------------------------------------------------------------

module.exports =
class LanguageManagerView extends View

  @content: ->
    @div class: 'levels-view language-manager', =>
      @div class: 'overlay-hack', outlet: 'overlayHack', =>
        @raw '&nbsp;'
      @div class: 'language-list', =>
        @div class: 'header', =>
          @h1 class: 'heading icon icon-list-unordered', =>
            @text 'Installed Languages '
            @span class: 'badge badge-flexible', \
                outlet: 'languageCountBadge'
          @subview 'filterInput', new TextEditorView
            mini: true
            placeholderText: 'Filter languages by name'
        @div class: 'language-cards', outlet: 'languageCards'
        @div class: 'controls', =>
          @div class: 'block pull-right', =>
            @button class: 'inline-block btn', \
                click: 'handleDidClickCancelButton', \
                outlet: 'cancelButton', =>
              @text 'Cancel'
            @button class: 'inline-block btn icon icon-plus', \
                click: 'handleDidClickInstallLanguageButton', \
                outlet: 'installLanguageButton', =>
              @text 'Install Language'

  ## Initialization and destruction --------------------------------------------

  initialize: ->
    # initialize view components
    languages = languageManager.getLanguages().sort \
      languageUtils.compareLanguageNames({order: 'ascending'})
    @languageCountBadge.append(languages.length)
    @languageCardsByLanguageName = {}
    for language in languages
      @languageCards.append(languageCard = @renderLanguageCard(language))
      @languageCardsByLanguageName[language.getName()] = languageCard

    # set up event handlers
    @languageManagerSubscrs = new CompositeDisposable
    @languageManagerSubscrs.add languageManager.onDidAddLanguage \
      (language) => @updateOnDidAddLanguage(language)
    @languageManagerSubscrs.add languageManager.onDidRemoveLanguage \
      (language) => @updateOnDidRemoveLanguage(language)

    # set up filter input text editor
    @filterInputTextEditor = @filterInput.getModel()
    @filterInputTextEditorSubscr = @filterInputTextEditor.onDidChange =>
      filter = @filterInputTextEditor.getText()
      @filterLanguagesCardsByName(filter)

  destroy: ->
    @hide()
    @languageListView.destroy()
    # @languageConfigView.destroy()
    # @progressPanelSubscrs.dispose()

  # destroy: ->
  #   @filterInputTextEditorSubscr.dispose()
  #   @languageManagerSubscrs.dispose()
  #   for languageName,languageCard of @languageCardsByLanguageName
  #     languageCard.configureButton.off('click')
  #     languageCard.uninstallButton.off('click')

  ## Rendering view components -------------------------------------------------

  renderLanguageCard: (language) ->
    languageName = language.getName()
    levelCount = language.getLevels().length
    installDate = language.getInstallationDate()
    installDateFormatted = installDate.format('dddd, D. MMMM YYYY')
    isNew = moment().diff(installDate,'days') <= 2

    configureButton = $('<button>Configure</div>')
    configureButton.addClass('btn icon icon-gear')
    uninstallButton = $('<button>Uninstall</div>')
    uninstallButton.addClass('btn btn-error icon icon-trashcan')

    configureButton.on 'click', =>
      @handleDidClickConfigureButton(language)
    uninstallButton.on 'click', =>
      @handleDidClickUninstallButton(language)

    languageCard = $$ ->
      @div class: 'language-card', =>
        @div class: 'controls pull-right', =>
          @div class: 'btn-group', =>
            @subview 'configureButton', configureButton
            @subview 'uninstallButton', uninstallButton
        @div class: 'primary-line', =>
          @span class: 'language-name', =>
            @text "#{languageName}"
          @span class: 'level-count', =>
            @text "(#{levelCount} Levels)"
          if isNew
            @span class: 'newness-indicator highlight-success', =>
              @text "New!"
        @div class: 'secondary-line', =>
          @span class: 'text-subtle', =>
            @text "Added on #{installDateFormatted}"

    languageCard.configureButton = configureButton
    languageCard.uninstallButton = uninstallButton
    languageCard

  ## Updating view elements ----------------------------------------------------

  updateOnDidAddLanguage: (language) ->
    languages = languageManager.getLanguages().sort \
      languageUtils.compareLanguageNames({order: 'ascending'})
    @languageCountBadge.empty()
    @languageCountBadge.append(languages.length)
    languageCard = @renderLanguageCard(language)
    languageCard.hide()

    # insert language card
    languageIndex = languages.indexOf(language)
    if languageIndex is 0
      @languageCards.prepend(languageCard)
    else
      @languageCards.children().eq(languageIndex-1).after(languageCard)

    @languageCardsByLanguageName[language.getName()] = languageCard
    # TODO scroll to correct position
    @languageCards.scrollTop(@languageCards[0].scrollHeight)
    # -------------------------------
    languageCard.fadeIn('slow')

  updateOnDidRemoveLanguage: (language) ->
    @languageCountBadge.empty()
    @languageCountBadge.append(languageManager.getLanguages().length)
    languageName = language.getName()
    languageCard = @languageCardsByLanguageName[languageName]
    languageCard.fadeOut 'slow', =>
      languageCard.remove()
      delete @languageCardsByLanguageName[languageName]

  ## Handling view events ------------------------------------------------------

  handleDidClickConfigureButton: (language) ->
    @languageSettingsView = new LanguageSettingsView language,
      onDidOpen: @showOverlayHack
      onDidClose: @hideOverlayHack
    @languageSettingsView.open()

  handleDidClickUninstallButton: (language) ->
    atom.confirm
      message: "Are you sure you want to uninstall #{language.getName()}?"
      detailedMessage: 'This operation cannot be undone.'
      buttons:
        'Uninstall': => setTimeout((=> @doUninstallLanguage(language)),200)
        'Cancel': ->

  doUninstallLanguage: (language) ->
    progressEmitter = @getLanguageUninstallationProgressEmitter(language)
    new ProgressPanelView progressEmitter,
      title: "Uninstalling #{language.getName()}..."
      onDidOpen: => @overlayHack.show()
      onDidClose: => @overlayHack.hide()

  getLanguageUninstallationProgressEmitter: (language) ->
    languageManagerSubscrs: new CompositeDisposable
    start: -> languageManager.uninstallLanguage(language)
    stop: -> @languageManagerSubscrs.dispose()
    setUp: ({emitProgress,emitWarning,emitError}) ->
      @languageManagerSubscrs.add languageManager.onDidStartUninstalling ->
        emitProgress
          value: 0
          info: 'Starting to uninstall...'
      @languageManagerSubscrs.add languageManager.onDidStopUninstalling \
        ({success}) ->
          if success
            emitProgress
              value: 100
              info: 'Uninstallation succeeded.'
          else
            emitError('Uninstallation failed.')

  handleDidClickCancelButton: ->
    @hide()

  handleDidClickInstallLanguageButton: ->
    configFilePaths = dialog.showOpenDialog
      title: 'Choose language configuration file'
      filters: [
        {name: 'Language Configuration File',extensions: ['json','cson']}
      ]
      properties: ['openFile']
    if configFilePaths?
      setTimeout((=> @doInstallLanguage(configFilePaths[0])),200)

  doInstallLanguage: (configFilePath) ->
    progressEmitter = @getLanguageInstallationProgressEmitter(configFilePath)
    new ProgressPanelView progressEmitter,
      title: 'Installing language...'
      onDidOpen: => @overlayHack.show()
      onDidClose: => @overlayHack.hide()

  getLanguageInstallationProgressEmitter: (configFilePath) ->
    languageManagerSubscrs: new CompositeDisposable
    start: -> languageManager.installLanguage(configFilePath)
    stop: -> @languageManagerSubscrs.dispose()
    setUp: ({emitProgress,emitWarning,emitError}) ->
      @languageManagerSubscrs.add languageManager.onDidStartInstalling =>
        emitProgress
          value: 0
          info: 'Starting to install...'
      @languageManagerSubscrs.add languageManager.onDidStopInstalling ({success}) =>
        if success
          emitProgress
            value: 100
            info: 'Installation suceeded'
        else
          emitError('Installation failed')
      @languageManagerSubscrs.add languageManager.onDidBeginInstallationStep \
        ({message,progress}) =>
          emitProgress
            value: progress
            info: message
      @languageManagerSubscrs.add languageManager.onDidGenerateInstallationWarning \
        (warning) => emitWarning(warning.message)
      @languageManagerSubscrs.add languageManager.onDidGenerateInstallationError \
        (error) => emitError(error.message)

  ## Filtering installed languages ---------------------------------------------

  filterLanguagesCardsByName: (@filter) ->
    # update language card list
    resultsCount = 0
    for languageName,languageCard of @languageCardsByLanguageName
      languageNameLowered = languageName.toLowerCase()
      filterLowered = @filter.toLowerCase()
      if not @filter or languageNameLowered.indexOf(filterLowered) >= 0
        languageCard.show()
        resultsCount++
      else
        languageCard.hide()

    # update language count badge
    languageCount = languageManager.getLanguages().length
    @languageCountBadge.empty()
    if @filter
      @languageCountBadge.append("#{resultsCount}/#{languageCount}")
    else
      @languageCountBadge.append("#{languageCount}")

  ## Showing and hiding the overlay view ---------------------------------------

  showOverlayHack: =>
    @overlayHack.fadeIn('fast')

  hideOverlayHack: =>
    @overlayHack.fadeOut('fast')

  ## Showing and hiding the language manager -----------------------------------

  toggle: ->
    if @isVisible() then @hide() else @show()

  isVisible: ->
    @topPanel?

  show: ->
    unless @isVisible()
      @topPanel = atom.workspace.addTopPanel({item: @})
      @css({display: 'none'})
      @fadeIn 'fast', =>
        @filterInput.focus()

  hide: ->
    if @isVisible()
      @fadeOut 'fast', =>
        @topPanel.destroy()
        @topPanel = null

# ------------------------------------------------------------------------------
