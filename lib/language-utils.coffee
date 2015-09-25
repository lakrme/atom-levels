moment = require('moment')

# ------------------------------------------------------------------------------

module.exports =

  ## Constants -----------------------------------------------------------------

  INSTALLATION_DATE_FORMAT: 'dddd, D. MMMM YYYY, HH:mm:ss'
  GRAMMAR_NAME_PATTERN: '<languageName> (Levels)'
  GRAMMAR_NAME_REG_EXP: /(.*) \(Levels\)/

  ## Sorting languages ---------------------------------------------------------

  compareLanguageNames: (options) ->
    ascOrDesc = options?.order ? 'ascending'
    comparator = (language1,language2) ->
      name1 = language1.getName()
      name2 = language2.getName()
      if name1 < name2
        if ascOrDesc is 'ascending' then return -1 else return 1
      if name1 > name2
        if ascOrDesc is 'ascending' then return 1 else return -1
      return 0
    comparator

  # installationDateComparatorAsc: (language1,language2) ->
  #   date1 = language1.getInstallationDate()
  #   date2 = language2.getInstallationDate()
  #   if moment.max(date1,date2) is date2
  #     return -1
  #   if moment.max(date1,date2) is date1
  #     return 1
  #   return 0
  #
  # installationDateComparatorDesc: (language1,language2) ->
  #   date1 = language1.getInstallationDate()
  #   date2 = language2.getInstallationDate()
  #   if moment.max(date1,date2) is date2
  #     return 1
  #   if moment.max(date1,date2) is date1
  #     return -1
  #   return 0

# ------------------------------------------------------------------------------
