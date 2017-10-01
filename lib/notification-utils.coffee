module.exports =
  DEFAULT_SHOW_ALL_ERRORS: true
  DEFAULT_SHOW_ALL_INFOS: true
  DEFAULT_SHOW_ALL_SUCCESSES: true
  DEFAULT_SHOW_ALL_WARNINGS: true
  DEFAULT_ERROR_HEAD: 'The levels package has detected an error!'
  DEFAULT_INFO_HEAD: 'The levels package has got some information for you!'
  DEFAULT_SUCCESS_HEAD: 'Success!'
  DEFAULT_WARNING_HEAD: 'Attention! A warning from the levels package!'

  addError: (body, {head, important} = {}) ->
    head ?= @DEFAULT_ERROR_HEAD
    important ?= false

    configKeyPath = 'levels.notificationSettings.showAllErrors'
    if important || atom.config.get(configKeyPath)
      atom.notifications.addError head, {detail: body, dismissable: true}

  addInfo: (body, {head, important} = {}) ->
    head ?= @DEFAULT_INFO_HEAD
    important ?= false

    configKeyPath = 'levels.notificationSettings.showAllInfos'
    if important || atom.config.get(configKeyPath)
      atom.notifications.addInfo head, {detail: body, dismissable: true}

  addSuccess: (body, {head, important} = {}) ->
    head ?= @DEFAULT_SUCCESS_HEAD
    important ?= false

    configKeyPath = 'levels.notificationSettings.showAllSuccesses'
    if important || atom.config.get(configKeyPath)
      atom.notifications.addSuccess head, {detail: body, dismissable: true}

  addWarning: (body, {head, important} = {}) ->
    head ?= @DEFAULT_WARNING_HEAD
    important ?= false

    configKeyPath = 'levels.notificationSettings.showAllWarnings'
    if important || atom.config.get(configKeyPath)
      atom.notifications.addWarning head, {detail: body, dismissable: true}