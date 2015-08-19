{Emitter}        = require('atom')

languageRegistry = require('./language-registry').getInstance()

# ------------------------------------------------------------------------------

class LanguageInstaller

  ## Construction --------------------------------------------------------------

  constructor: ->
    @emitter = new Emitter

  ## Installing languages ------------------------------------------------------

  installLanguages: (paths) ->
    console.log "DUMMY"

  ## Uninstalling languages ----------------------------------------------------

  uninstallLanguages: (languages) ->
    console.log "DUMMY"

# ------------------------------------------------------------------------------

module.exports =
class LanguageInstallerProvider

  instance = null

  @getInstance: ->
    instance ?= new LanguageInstaller

# ------------------------------------------------------------------------------
