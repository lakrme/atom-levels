'use babel';

export const DEFAULT_SHOW_ALL_ERRORS = true;
export const DEFAULT_SHOW_ALL_INFOS = true;
export const DEFAULT_SHOW_ALL_SUCCESSES = true;
export const DEFAULT_SHOW_ALL_WARNINGS = true;
export const DEFAULT_ERROR_HEAD = 'The levels package has detected an error!';
export const DEFAULT_INFO_HEAD = 'The levels package has got some information for you!';
export const DEFAULT_SUCCESS_HEAD = 'Success!';
export const DEFAULT_WARNING_HEAD = 'Attention! A warning from the levels package!';

export function addError(body, head = DEFAULT_ERROR_HEAD, important = false) {
  if (important || atom.config.get('levels.notificationSettings.showAllErrors')) {
    atom.notifications.addError(head, {detail: body, dismissable: true});
  }
}

export function addInfo(body, head = DEFAULT_INFO_HEAD, important = false) {
  if (important || atom.config.get('levels.notificationSettings.showAllInfos')) {
    atom.notifications.addInfo(head, {detail: body, dismissable: true});
  }
}

export function addSuccess(body, head = DEFAULT_SUCCESS_HEAD, important = false) {
  if (important || atom.config.get('levels.notificationSettings.showAllSuccesses')) {
    atom.notifications.addSuccess(head, {detail: body, dismissable: true});
  }
}

export function addWarning(body, head = DEFAULT_WARNING_HEAD, important = false) {
  if (important || atom.config.get('levels.notificationSettings.showAllWarnings')) {
    atom.notifications.addWarning(head, {detail: body, dismissable: true});
  }
}