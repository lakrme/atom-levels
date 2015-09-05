{CompositeDisposable} = require('atom')
{View}                = require('atom-space-pen-views')

LanguageListView      = require('./language-list-view')
# LanguageConfigView = require('./language-config-view')
ProgressPanelView     = require('./progress-panel-view')

# ------------------------------------------------------------------------------

module.exports =
class LanguageManagerView extends View

  @content: ->
    @div class: 'levels-view language-manager', =>
      @subview 'progressPanel', new ProgressPanelView
      @div class: 'overlay-hack', outlet: 'overlayHack', =>
        @raw '&nbsp;'

  ## Initialization and destruction --------------------------------------------

  initialize: ->
    @languageListView = new LanguageListView(@)
    # @languageConfigView = new LanguageConfigView(@)
    @append(@languageListView)

    # set up progress panel subscriptions
    @progressPanelSubscrs = new CompositeDisposable
    @progressPanelSubscrs.add @progressPanel.onDidShow =>
      @overlayHack.show()
    @progressPanelSubscrs.add @progressPanel.onDidHide =>
      @overlayHack.hide()

  destroy: ->
    @hide()
    @languageListView.destroy()
    # @languageConfigView.destroy()
    @progressPanelSubscrs.dispose()

  ## Showing and hiding the language manager and view components ---------------

  toggle: ->
    if @isVisible() then @hide() else @show()

  isVisible: ->
    @modalPanel?

  show: ->
    unless @modalPanel?
      @showLanguageList()

  hide: ->
    if @modalPanel?
      @modalPanel.destroy()
      @modalPanel = null

  showLanguageList: ->
    @modalPanel = atom.workspace.addModalPanel(item: @)
    @languageListView.filterInput.focus()

  showLanguageConfiguration: (language) ->

# ------------------------------------------------------------------------------
