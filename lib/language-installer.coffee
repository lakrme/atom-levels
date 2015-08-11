languageRegistry  = require('./language-registry').getInstance()
languageValidator = require('./language-validator').getInstance()

# ------------------------------------------------------------------------------

class LanguageInstaller

  installLanguages: (paths) ->
    console.log "DUMMY"

  uninstallLanguages: (languages) ->
    console.log "DUMMY"

# ------------------------------------------------------------------------------

class LanguageInstallerProvider

  instance = null

  @getInstance: ->
    instance ?= new LanguageInstaller

# ------------------------------------------------------------------------------
