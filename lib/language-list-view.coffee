{CompositeDisposable}      = require('atom')
{$,$$,TextEditorView,View} = require('atom-space-pen-views')
dialog                     = require('remote').require('dialog')
moment                     = require('moment')

languageUtils              = require('./language-utils')

languageManager            = require('./language-manager').getInstance()

# ------------------------------------------------------------------------------

module.exports =
class LanguageListView extends View

  @content: ->
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

  initialize: (@languageManagerView) ->
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
    @filterInputTextEditorSubscr.dispose()
    @languageManagerSubscrs.dispose()
    for languageName,languageCard of @languageCardsByLanguageName
      languageCard.configureButton.off('click')
      languageCard.uninstallButton.off('click')

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
    # @languageManagerView.showLanguage

  handleDidClickUninstallButton: (language) ->
    atom.confirm
      message: "Are you sure you want to uninstall #{language.getName()}?"
      detailedMessage: 'This operation cannot be undone.'
      buttons:
        'Uninstall': => setTimeout((=> @doUninstallLanguage(language)),200)
        'Cancel': ->

  doUninstallLanguage: (language) ->
    progressPanel = @languageManagerView.progressPanel
    progressPanel.update
      headline: "Uninstalling #{language.getName()}..."
      info: 'Preparing...'
    uninstallSubscrs = new CompositeDisposable
    uninstallSubscrs.add languageManager.onDidStartUninstalling =>
      progressPanel.update
        progress: 0
        info: 'Starting to uninstall...'
    uninstallSubscrs.add languageManager.onDidStopUninstalling ({success}) =>
      if success
        progressPanel.updateProgress(100)
        progressPanel.updateInfo('Uninstallation succeeded.')
      else
        progressPanel.updateInfo('Uninstallation failed.')
        progressPanel.done()
      uninstallSubscrs.dispose()
    progressPanel.show ->
      languageManager.uninstallLanguage(language)

  handleDidClickCancelButton: ->
    @languageManagerView.hide()

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
    progressPanel = @languageManagerView.progressPanel
    progressPanel.update
      headline: "Installing language..."
      info: 'Preparing...'
    installSubscrs = new CompositeDisposable
    installSubscrs.add languageManager.onDidStartInstalling =>
      console.log "started"
      progressPanel.update
        progress: 0
        info: 'Starting to install...'
    installSubscrs.add languageManager.onDidStopInstalling ({success}) =>
      console.log "stopped"
      if success
        progressPanel.updateProgress(100)
        progressPanel.updateInfo('Installation succeeded.')
      else
        progressPanel.updateInfo('Installation failed.')
        progressPanel.done()
      installSubscrs.dispose()
    installSubscrs.add languageManager.onDidBeginInstallationStep \
      ({message,progress}) =>
        progressPanel.updateProgress(progress)
        progressPanel.updateInfo(message)
    installSubscrs.add languageManager.onDidGenerateInstallationWarning \
      (warning) => progressPanel.addWarning(warning.message)
    installSubscrs.add languageManager.onDidGenerateInstallationError \
      (error) => progressPanel.addError(error.message)
    progressPanel.show ->
      languageManager.installLanguage(configFilePath)

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

# ------------------------------------------------------------------------------
