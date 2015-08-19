{Emitter}        = require('atom')

languageRegistry = require('./language-registry').getInstance()

# ------------------------------------------------------------------------------

class LanguageInstaller

  activate: ->
    @emitter = new Emitter

  installLanguages: (paths) ->
    console.log "DUMMY"

  uninstallLanguages: (languages) ->
    console.log "DUMMY"

# ------------------------------------------------------------------------------

module.exports =
class LanguageInstallerProvider

  instance = null

  @getInstance: ->
    instance ?= new LanguageInstaller

# ------------------------------------------------------------------------------
