{SelectListView} = require('atom-space-pen-views')
_                = require('underscore-plus')

workspace        = require('./workspace').getInstance()

# ------------------------------------------------------------------------------

module.exports =
class LevelSelectView extends SelectListView

  ## Initialization and destruction --------------------------------------------

  initialize: (@workspaceManager) ->
    super
    @addClass('levels-view level-select')

  destroy: ->
    @cancel()

  cancelled: ->
    @levelSelectPanel?.destroy()
    @levelSelectPanel = null

  ## Overwritten list view methods ---------------------------------------------

  getFilterKey: ->
    'filterKey'

  confirmed: ({level}) ->
    @cancel()
    unless level.getName() is @activeLevel.getName()
      @activeLevelCodeEditor.setLevel(level)
      @activeLanguage.setLastActiveLevel(level)

  viewForItem: ({level}) ->
    listElement = document.createElement('li')

    if level.getDescription()?
      listElement.classList.add('two-lines')
      # define the primary line (level name)
      nameElement = document.createElement('div')
      if level is @activeLevel
        nameElement.classList.add('primary-line','icon','icon-triangle-right')
      else
        nameElement.classList.add('primary-line','no-icon')
      nameElement.textContent = level.getName()
      # define the secondary line (level description)
      descrElement = document.createElement('div')
      descrElement.classList.add('secondary-line','no-icon')
      descrElement.textContent = level.getDescription()
      # append lines to the list element
      listElement.appendChild(nameElement)
      listElement.appendChild(descrElement)
    else
      nameElement = document.createElement('span')
      if level is @activeLevel
        nameElement.classList.add('icon','icon-triangle-right')
      else
        nameElement.classList.add('no-icon')
      nameElement.textContent = level.getName()
      # append line to the list element
      listElement.appendChild(nameElement)

    listElement.dataset.level = level.getName()
    listElement

  ## Updating this view --------------------------------------------------------

  update: (@activeLevelCodeEditor) ->
    @activeLanguage = @activeLevelCodeEditor.getLanguage()
    @activeLevel = @activeLevelCodeEditor.getLevel()
    @setItems _.map @activeLanguage.getLevels(), (level) ->
      filterKey: "#{level.getName()} #{level.getDescription()}"
      level: level

  ## Showing and hiding this view ----------------------------------------------

  toggle: ->
    if @levelSelectPanel? then @hide() else @show()

  show: ->
    @update(workspace.getActiveLevelCodeEditor())
    @storeFocusedElement()
    @levelSelectPanel ?= atom.workspace.addModalPanel(item: @)
    @focusFilterEditor()

  hide: ->
    @cancel()

# ------------------------------------------------------------------------------
