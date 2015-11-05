# ------------------------------------------------------------------------------

module.exports =
class Level

  ## Construction --------------------------------------------------------------

  constructor: (@properties) ->

  ## Getting level properties --------------------------------------------------

  getNumber: ->
    @properties.number

  getName: ->
    @properties.name

  getDescription: ->
    @properties.description

  getGrammar: ->
    @properties.grammar

  ## Managing the associated language ------------------------------------------

  getLanguage: ->
    @language

  setLanguage: (@language) ->

# ------------------------------------------------------------------------------
