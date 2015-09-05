# ------------------------------------------------------------------------------

module.exports =

  ## Constants -----------------------------------------------------------------

  GRAMMAR_NAME_PATTERN: '<languageName> (Levels)'
  GRAMMAR_NAME_REG_EXP: /(.*) \(Levels\)/

  ## Formatting language properties --------------------------------------------

  formatInstallationDate: (installationDate) ->
    day = switch installationDate.getDay()
      when 0 then 'Monday'
      when 1 then 'Tuesday'
      when 2 then 'Wednesday'
      when 3 then 'Thursday'
      when 4 then 'Friday'
      when 5 then 'Saturday'
      when 6 then 'Sunday'
    month = switch installationDate.getMonth()
      when 0 then 'January'
      when 1 then 'February'
      when 2 then 'March'
      when 3 then 'April'
      when 4 then 'May'
      when 5 then 'June'
      when 6 then 'July'
      when 7 then 'August'
      when 8 then 'September'
      when 9 then 'October'
      when 10 then 'November'
      when 11 then 'December'
    "#{day}, #{installationDate.getDate()}. #{month} #{installationDate.getFullYear()}"


# ------------------------------------------------------------------------------
