# ------------------------------------------------------------------------------

module.exports =

  ## Constants -----------------------------------------------------------------

  DEFAULT_SHOW_ALL_INFOS: true
  DEFAULT_SHOW_ALL_SUCCESSES: true
  DEFAULT_SHOW_ALL_WARNINGS: true
  DEFAULT_SHOW_ALL_ERRORS: true

  # default message heads
  defaultInfoHead: 'Levels: '
  defaultSuccessHead: 'Levels: '
  defaultWarningHead: 'Levels: '
  defaultErrorHead: 'The Levels package has detected an error... :-('

  ## ---------------------------------------------------------------------------

  addInfo: (body,{head,important}={}) ->
    head ?= @defaultInfoHead
    important ?= false

    if important or atom.config.get('levels.showAllInfos')
      atom.notifications.addInfo head,
        detail: body
        dismissable: true

  addSuccess: (body,{head,important}={}) ->
    head ?= @defaultSuccessHead
    important ?= false

    if important or atom.config.get('levels.showAllSuccesses')
      atom.notifications.addSuccess head,
        detail: body
        dismissable: true

  addWarning: (body,{head,important}={}) ->
    head ?= @defaultWarningHead
    important ?= false

    if important or atom.config.get('levels.showAllWarnings')
      atom.notifications.addWarning head,
        detail: body
        dismissable: true

  addError: (body,{head,important}={}) ->
    head ?= @defaultErrorHead
    important ?= false

    if important or atom.config.get('levels.showAllErrors')
      atom.notifications.addError head,
        detail: body
        dismissable: true

  executionNotPossible:
    """
    Execution not possible!
    """
# ------------------------------------------------------------------------------
