# ------------------------------------------------------------------------------

module.exports =
class ConfigRegistry

  instance = null

  @getInstance: ->
    instance ?= new ConfigRegistry

  initialize: ->
    # set up configurations that require a package restart to apply changes
    @grammarNamePattern = atom.config.get('levels.grammarNamePattern')

  ## Getting and setting configurations ----------------------------------------

  get: (key) ->
    @[key] ? atom.config.get("levels.#{key}")

  ## Static, immutable configurations ------------------------------------------

  fileHeaderPattern: 'Language: <languageName>, Level: <levelName>'
  fileHeaderRegExp:  /Language:\s+(.+),\s+Level:\s+(.+)/

# ------------------------------------------------------------------------------
