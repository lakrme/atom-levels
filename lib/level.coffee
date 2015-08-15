{Emitter} = require('atom')

# ------------------------------------------------------------------------------

module.exports =
class Level

  constructor: (@properties) ->
    @emitter = new Emitter

  ## Event subscription --------------------------------------------------------

  # onDidChangeProperties: (callback) ->
  #   @emitter.on('did-change-properties',callback)

  ## Getting level properties --------------------------------------------------

  getNumber: ->
    @properties.number

  getName: ->
    @properties.name

  getDescription: ->
    @properties.description

  getGrammar: ->
    @properties.grammar

  ## Setting level properties --------------------------------------------------

  ## Managing the associated language ------------------------------------------

  getLanguage: ->
    @language

  setLanguage: (@language) ->

# ------------------------------------------------------------------------------
