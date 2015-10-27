# ------------------------------------------------------------------------------

module.exports =

  ## Constants -----------------------------------------------------------------

  DEFAULT_SHOW_ALL_INFOS: true
  DEFAULT_SHOW_ALL_SUCCESSES: true
  DEFAULT_SHOW_ALL_WARNINGS: true
  DEFAULT_SHOW_ALL_ERRORS: true
  DEFAULT_INFO_HEAD: 'Hey! The Levels package has got some information for you!'
  DEFAULT_SUCCESS_HEAD: 'Success!'
  DEFAULT_WARNING_HEAD: 'Attention! A warning from the Levels package!'
  DEFAULT_ERROR_HEAD: 'The Levels package has detected an error... :-('

  ## Displaying package notifcations -------------------------------------------

  addInfo: (body,{head,important}={}) ->
    head ?= @DEFAULT_INFO_HEAD
    important ?= false

    configKeyPath = 'levels.notificationSettings.showAllInfos'
    if important or atom.config.get(configKeyPath)
      atom.notifications.addInfo head,
        detail: body
        dismissable: true

  addSuccess: (body,{head,important}={}) ->
    head ?= @DEFAULT_SUCCESS_HEAD
    important ?= false

    configKeyPath = 'levels.notificationSettings.showAllSuccesses'
    if important or atom.config.get(configKeyPath)
      atom.notifications.addSuccess head,
        detail: body
        dismissable: true

  addWarning: (body,{head,important}={}) ->
    head ?= @DEFAULT_WARNING_HEAD
    important ?= false

    configKeyPath = 'levels.notificationSettings.showAllWarnings'
    if important or atom.config.get(configKeyPath)
      atom.notifications.addWarning head,
        detail: body
        dismissable: true

  addError: (body,{head,important}={}) ->
    head ?= @DEFAULT_ERROR_HEAD
    important ?= false

    configKeyPath = 'levels.notificationSettings.showAllErrors'
    if important or atom.config.get(configKeyPath)
      atom.notifications.addError head,
        detail: body
        dismissable: true

# ------------------------------------------------------------------------------
