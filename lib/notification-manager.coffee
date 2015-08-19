# ------------------------------------------------------------------------------

class NotificationManager

  # default message heads
  defaultInfoHead: 'Levels: '
  defaultSuccessHead: 'Levels: '
  defaultWarningHead: 'Levels: '
  defaultErrorHead: 'The Levels package has detected an error... :-('

  addInfo: (body,{head,important}={}) ->
    head ?= @defaultInfoHead
    important ?= false

    if important or atom.config.get('notificationSettings.showAllInfos')
      atom.notifications.addInfo head,
        detail: body
        dismissable: true

  addSuccess: (body,{head,important}={}) ->
    head ?= @defaultSuccessHead
    important ?= false

    if important or atom.config.get('notificationSettings.showAllSuccesses')
      atom.notifications.addSuccess head,
        detail: body
        dismissable: true

  addWarning: (body,{head,important}={}) ->
    head ?= @defaultWarningHead
    important ?= false

    if important or atom.config.get('notificationSettings.showAllWarnings')
      atom.notifications.addWarning head,
        detail: body
        dismissable: true

  addError: (body,{head,important}={}) ->
    head ?= @defaultErrorHead
    important ?= false

    if important or atom.config.get('notificationSettings.showAllErrors')
      atom.notifications.addError head,
        detail: body
        dismissable: true

# ------------------------------------------------------------------------------

module.exports =
class NotificationManagerProvider

  instance = null

  @getInstance: ->
    instance ?= new NotificationManager

# ------------------------------------------------------------------------------
