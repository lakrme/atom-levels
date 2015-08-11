configRegistry = require('./core-config-registry').getInstance()

# ------------------------------------------------------------------------------

module.exports =

  defaultInfoHead: 'Levels: '
  defaultSuccessHead: 'Levels: '
  defaultWarningHead: 'Levels: '
  defaultErrorHead: 'The Levels package has detected an error... :-('

  addInfo: (body,{head,important}={}) ->
    head ?= @defaultInfoHead
    important ?= false

    if important or configRegistry.get('showAllInfoNotifications')
      atom.notifications.addInfo head,
        detail: body
        dismissable: true

  addSuccess: (body,{head,important}={}) ->
    head ?= @defaultSuccessHead
    important ?= false

    if important or configRegistry.get('showAllSuccessNotifications')
      atom.notifications.addSuccess head,
        detail: body
        dismissable: true

  addWarning: (body,{head,important}={}) ->
    head ?= @defaultWarningHead
    important ?= false

    if important or configRegistry.get('showAllWarningNotifications')
      atom.notifications.addWarning head,
        detail: body
        dismissable: true

  addError: (body,{head,important}={}) ->
    head ?= @defaultErrorHead
    important ?= false

    if important or configRegistry.get('showAllErrorNotifications')
      atom.notifications.addError head,
        detail: body
        dismissable: true

  notFoundLanguageConfig: (languageDirPath) ->
    "Could not find language configuration file \"config.json\" in directory
     \"#{languageDirPath}\"."

# ------------------------------------------------------------------------------
