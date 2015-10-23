# ------------------------------------------------------------------------------

module.exports =

  ## Constants -----------------------------------------------------------------

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

# ------------------------------------------------------------------------------
