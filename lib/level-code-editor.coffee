{Emitter} = require('atom')

Terminal  = require('./terminal')

# ------------------------------------------------------------------------------

module.exports =
class LevelCodeEditor

  ## Construction and destruction ----------------------------------------------

  constructor: ({@textEditor,@language,@level,@terminal}) ->
    @emitter = new Emitter

    # initialize optional parameters
    @level ?= @language.getLevelOnInitialization()
    @terminal ?= new Terminal

    # activate the current level's grammarna
    @textEditor.setGrammar(@level.getGrammar())

  destroy: ->
    @terminal.destroy()

  ## Event subscription --------------------------------------------------------

  onDidChangeLanguage: (callback) ->
    @emitter.on('did-change-language',callback)

  onDidChangeLevel: (callback) ->
    @emitter.on('did-change-level',callback)

  ## Getting properties and associated entities --------------------------------

  getId: ->
    @textEditor.id

  getTextEditor: ->
    @textEditor

  getLanguage: ->
    @language

  getLevel: ->
    @level

  getTerminal: ->
    @terminal

  ## Setting the language and the level ----------------------------------------
 
  setLanguage: (language,{level}={}) ->
    if language.getName() is @language.getName()
      @setLevel(level) if level?
    else
      @language = language
      @setLevel(level ? @language.getLevelOnInitialization())
      @emitter.emit('did-change-language',{@language,@level})

  setLevel: (level) ->
    if @language.hasLevel(level)
      unless level.getName() is @level.getName()
        @level = level
        @textEditor.setGrammar(@level.getGrammar())
        @language.setLastActiveLevel(@level)
        @emitter.emit('did-change-level',@level)

# ------------------------------------------------------------------------------
