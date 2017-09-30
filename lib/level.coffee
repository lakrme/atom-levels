module.exports =
class Level
  constructor: (@properties) ->

  getNumber: ->
    return @properties.number

  getName: ->
    return @properties.name

  getDescription: ->
    return @properties.description

  getGrammar: ->
    return @properties.grammar

  getOption: (option) ->
    return @properties.options[option]

  getLanguage: ->
    return @language

  setLanguage: (@language) ->