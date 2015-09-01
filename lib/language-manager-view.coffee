{CompositeDisposable} = require('atom')
{$,$$,View}           = require('atom-space-pen-views')
dialog                = require('remote').require('dialog')

languageManager       = require('./language-manager').getInstance()
workspace             = require('./workspace').getInstance()

# ------------------------------------------------------------------------------

module.exports =
class LanguageManagerView extends View

  @content: ->
    @div class: 'levels-view language-manager', =>
      @a href: '#', class: 'close-button icon icon-x', \
        click: 'handleDidClickCloseButton', \
        outlet: 'closeButton'
      @div class: 'head', =>
        @div class: 'heading', =>
          @h1 class: 'icon icon-tools', =>
            @text 'Language Manager'
        @div class: 'subheading', outlet: 'subheading'
      @div class: 'body', outlet: 'body'
      @div class: 'control-bar', outlet: 'controlBar'

  ## Initialization and destruction --------------------------------------------

  initialize: ->
    # @workspaceSubscrs = new CompositeDisposable
    # @workspaceSubscrs.add workspace.onDidEnterWorkspace =>
    #   @updateOnDidEnterWorkspace()
    # @workspaceSubscrs.add workspace.onDidExitWorkspace =>
    #   @updateOnDidEnterWorkspace()
    @languageCardsByLanguageName = {}
    @listViewElements = {}
    @configViewElements = {}

    languageManager.onDidAddLanguage =>
      if @isVisible()
        @subheading.empty()
        subheading = @renderSubheadingForLanguageList()
        @subheading.append(subheading)
        @body.empty()
        body = @renderLanguageList()
        @body.append(body)

  destroy: ->
    # @workspaceSubscrs.dispose()
    @hide()

  ## Language list -------------------------------------------------------------

  renderSubheadingForLanguageList: ->
    languageCount = languageManager.getLanguages().length
    subheading = $$ ->
      @h2 class: 'icon icon-list-unordered', =>
        @text 'Installed Languages '
        @span class: 'badge badge-flexible', =>
          @text "#{languageCount}"

  renderLanguageList: ->
    languageList = $('<div class="language-list"></div>')
    for language in languageManager.getLanguages()
      languageList.append(@renderLanguageCard(language))
    languageList

  renderLanguageCard: (language) ->
    configureButton = $('<button>Configure</button>')
    configureButton.addClass('btn icon icon-gear')
    uninstallButton = $('<button>Uninstall</button>')
    uninstallButton.addClass('btn btn-error icon icon-trashcan')

    languageName = language.getName()
    levelCount = language.getLevels().length
    languageCard = $$ ->
      @div class: 'language-card', =>
        @div class: 'controls pull-right', =>
          @div class: 'btn-group btn-group-sm', =>
            @subview 'configureButton', configureButton
            @subview 'uninstallButton', uninstallButton
        @div class: 'card-name', =>
          @text languageName
        @span class: 'info', =>
          @text "Levels: #{levelCount}"

    uninstallButton.on 'click', =>
      console.log "rofl"
      atom.pickFolder =>
        console.log "lol"

    @languageCardsByLanguageName[languageName] = languageCard

  renderControlBarForLanguageList: ->
    installLanguageButton = $$ ->
      @button class: 'btn btn-success icon icon-plus', =>
        @text 'Install Language'
    @installLanguageButton = installLanguageButton
    @installLanguageButton.on 'click', =>
      @doInstallLanguage()

    controlBarRight = $$ ->
      @div class: 'control-bar-right', =>
        @subview 'installLanguagesButton', installLanguageButton

  doInstallLanguage: ->
    configFilePaths = dialog.showOpenDialog
      title: 'Choose language configuration file'
      filters: [
        {name: 'Language Configuration File',extensions: ['json','cson']}
      ]
      properties: ['openFile']
    languageManager.installLanguage(configFilePaths[0]) if configFilePaths?

  ## Language configuration view -----------------------------------------------


  ## Handling view events ------------------------------------------------------

  handleDidClickCloseButton: ->
    @hide()

  ## Showing and hiding the language manager view ------------------------------

  toggle: ->
    if @isVisible() then @hide() else @show()

  isVisible: ->
    @modalPanel?

  show: ->
    unless @modalPanel?
      @subheading.empty()
      subheading = @renderSubheadingForLanguageList()
      @subheading.append(subheading)
      @body.empty()
      body = @renderLanguageList()
      @body.append(body)
      @controlBar.empty()
      controlBar = @renderControlBarForLanguageList()
      @controlBar.append(controlBar)
      @modalPanel = atom.workspace.addModalPanel(item: @)

  hide: ->
    if @modalPanel?
      @modalPanel.destroy()
      @modalPanel = null

# ------------------------------------------------------------------------------
