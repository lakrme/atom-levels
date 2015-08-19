{SelectListView} = require 'atom-space-pen-views'

# ------------------------------------------------------------------------------

module.exports =
class LevelSelectorView extends SelectListView

  initialize: (@workspaceManager) ->
    super
    @addClass('levels-view level-select')

  destroy: ->
    @cancel()

  cancelled: ->
    @panel?.destroy()
    @panel = null

  getFilterKey: ->
    # TODO maybe use the concantenation of name and description here
    'name'

  confirmed: (level) ->
    @workspaceManager.updateLevelForActiveWorkspaceSession(level)
    @cancel()

  viewForItem: (level) ->
    listElem = document.createElement('li')

    if level is @defaultLevel
      defaultElem = document.createElement('div')
      defaultElem.classList.add('pull-right')
      defaultElem.textContent = '(default)'

    if level.description?
      listElem.classList.add('two-lines')

      # define the primary line (level name)
      nameElem = document.createElement('div')
      if level is @activeLevel
        nameElem.classList.add('primary-line','icon','icon-triangle-right')
      else
        nameElem.classList.add('primary-line','no-icon')
      nameElem.textContent = level.name

      # define the secondary line (level description)
      descrElem = document.createElement('div')
      descrElem.classList.add('secondary-line','no-icon')
      descrElem.textContent = level.description

      listElem.appendChild(defaultElem) if level is @defaultLevel
      listElem.appendChild(nameElem)
      listElem.appendChild(descrElem)

    else
      nameElem = document.createElement('span')
      if level is @activeLevel
        nameElem.classList.add('icon','icon-triangle-right')
      else
        nameElem.classList.add('no-icon')
      nameElem.textContent = level.name

      listElem.appendChild(defaultElem) if level is @defaultLevel
      listElem.appendChild(nameElem)

    listElem.dataset.level = level.name
    listElem

  toggle: (languageData) ->
    if @panel?
      @cancel()
    else
      language = languageData.language
      @activeLevel = languageData.level
      @defaultLevel = language.defaultLevel
      @setItems(language.levels)
      @storeFocusedElement()
      @panel ?= atom.workspace.addModalPanel(item: this)
      @focusFilterEditor()

  ## Showing and hiding this view ----------------------------------------------

  show: ->
    @panel

  hide: ->
    @cancel()

# ------------------------------------------------------------------------------
