SelectListView = require 'atom-select-list'
workspace      = require './workspace'

module.exports =
class LevelSelectView
  constructor: ->
    @selectListView = new SelectListView
      items: [],
      filterKeyForItem: (level) -> level.getName(),
      elementForItem: (level) => @viewForLevel level,
      didCancelSelection: => @cancel(),
      didConfirmSelection: (level) => @confirm level

  destroy: ->
    @cancel()
    @selectListView.destroy()
    return

  cancel: ->
    @panel?.destroy()
    @panel = null

    @previouslyFocusedElement?.focus()
    @previouslyFocusedElement = null
    return

  attach: ->
    @previouslyFocusedElement = document.activeElement
    @panel ?= atom.workspace.addModalPanel item: @selectListView

    @selectListView.focus()
    @selectListView.reset()
    return

  confirm: (level) ->
    @cancel()
    if level.getName() != @activeLevel.getName()
      @activeLevelCodeEditor.setLevel level
      @activeLanguage.setLastActiveLevel level
    return

  toggle: ->
    if @panel
      @cancel()
    else
      @update workspace.getActiveLevelCodeEditor()
      @attach()
    return

  update: (@activeLevelCodeEditor) ->
    @activeLanguage = @activeLevelCodeEditor.getLanguage()
    @activeLevel = @activeLevelCodeEditor.getLevel()
    @selectListView.update items: @activeLanguage.getLevels()
    return

  viewForLevel: (level) ->
    listElement = document.createElement 'li'
    listElement.dataset.level = level.getName()

    if level.getDescription()
      listElement.className = 'two-lines'

      nameElement = document.createElement 'div'
      if level == @activeLevel
        nameElement.className = 'primary-line icon icon-triangle-right'
      else
        nameElement.className = 'primary-line no-icon'
      nameElement.textContent = level.getName()
      listElement.appendChild nameElement

      descElement = document.createElement 'div'
      descElement.className = 'secondary-line no-icon'
      descElement.textContent = level.getDescription()
      listElement.appendChild descElement
    else
      nameElement = document.createElement 'span'
      if level == @activeLevel
        nameElement.className = 'icon icon-triangle-right'
      else
        nameElement.className = 'no-icon'
      nameElement.textContent = level.getName()
      listElement.appendChild nameElement

    return listElement