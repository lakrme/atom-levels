ControlPanelView   = require './views-control-panel-view'
LanguageConfigView = require './views-language-config-view'
LevelSelectView    = require './views-level-select-view'
LevelStatusView    = require './views-level-status-view'

# ------------------------------------------------------------------------------

module.exports =
class ViewManager

  instance = null

  @getInstance: ->
    instance ?= new ViewManager

  initialize: (state) ->
    @levelStatusView    = new LevelStatusView(@)
    @levelSelectView    = new LevelSelectView(@)
    @languageConfigView = new LanguageConfigView(@)
    @controlPanelView   = new ControlPanelView(@,state.controlPanelViewState)

    @textEditorIssueAnnotations = {}

  destroyAllViews: ->
    @levelStatusTile.destroy()
    @levelSelectView.destroy()
    @languageConfigView.destroy()
    @controlPanelView.destroy()

  ## Displaying view components ------------------------------------------------

  showControlPanelView: (textEditor,languageData,terminal) ->
    @controlPanelView.show(textEditor,languageData,terminal)

  hideControlPanelView: ->
    @controlPanelView.hide()

  showLevelStatusView: (languageData) ->
    @levelStatusView.show(languageData)

  hideLevelStatusView: ->
    @levelStatusView.hide()

  # showViewsForTextEditor: (textEditor) ->


  ## Consumed services ---------------------------------------------------------

  consumeStatusBar: (statusBar) ->
    @levelStatusTile = statusBar.addRightTile(item: @levelStatusView,priority: 9)

  ## Managing text editor markers for warning and error annotations ------------

  addIssueAnnotiationToTextEditor: (textEditor,issueMessage) ->
    type   = issueMessage.type
    source = issueMessage['data-source']
    row    = parseInt(issueMessage['data-row'])-1
    col    = parseInt(issueMessage['data-col'] ? 0)-1
    body   = issueMessage.body

    marker = textEditor.markBufferRange [[row,col],[row,Infinity]],
      invalidate: 'touch'
    textEditor.decorateMarker marker,
      type: 'line-number'
      class: "levels:annotation levels:annotation-#{type}"

    markers = @textEditorIssueAnnotations[textEditor.id] ? []
    markers.push(marker)
    @textEditorIssueAnnotations[textEditor.id] = markers

  removeIssueAnnotationsForTextEditor: (textEditor) ->
    if (annotations = @textEditorIssueAnnotations[textEditor.id])?
      marker.destroy() for marker in annotations
      delete @textEditorIssueAnnotations[textEditor.id]

  ## Serialization -------------------------------------------------------------

  serialize: ->
    controlPanelViewState: @controlPanelView.serialize()

# ------------------------------------------------------------------------------
