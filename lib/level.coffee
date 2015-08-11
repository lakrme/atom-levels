{Emitter} = require('atom')

# ------------------------------------------------------------------------------

module.exports =
class Level

  constructor: (levelObject) ->
    @emitter = new Emitter

    @name        = levelObject.name
    @description = levelObject.description
    @grammar     = levelObject.grammar

  setLanguage: (@language) ->

# ------------------------------------------------------------------------------
