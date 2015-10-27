# ------------------------------------------------------------------------------

module.exports =

  ## Constants -----------------------------------------------------------------

  DEFAULT_IS_HIDDEN: false
  DEFAULT_SIZE: 20
  MIN_SIZE: 15
  DEFAULT_FONT_SIZE: 12
  MIN_FONT_SIZE: 10
  MAX_FONT_SIZE: 20
  DEFAULT_CONTENT_LIMIT: 1000
  TOPKEK:
    """
     _              _        _
    | |            | |      | |
    | |_ ___  _ __ | | _____| | __
    | __/ _ \\| '_ \\| |/ / _ \\ |/ /
    | || (_) | |_) |   <  __/   <
     \\__\\___/| .__/|_|\\_\\___|_|\\_\\
             | |
             |_|
    """

  ## Dispatching key events ----------------------------------------------------

  dispatchKeyEvent: (terminal,event) ->
    buffer = terminal.getBuffer()
    keystroke = atom.keymaps.keystrokeForKeyboardEvent(event.originalEvent)
    keystrokeParts = if keystroke is '-' then ['-'] else keystroke.split('-')
    switch keystrokeParts.length
      when 1
        switch (firstPart = keystrokeParts[0])
          when 'enter' then buffer.enterInput()
          when 'backspace' then buffer.removeCharFromInput()
          when 'up' then buffer.showPreviousInput()
          when 'left' then buffer.moveInputCursorLeft()
          when 'down' then buffer.showSubsequentInput()
          when 'right' then buffer.moveInputCursorRight()
          when 'space' then buffer.addStringToInput(' ')
          else
            if firstPart.length is 1
              buffer.addStringToInput(firstPart)
      when 2
        switch keystrokeParts[0]
          when 'shift'
            secondPart = keystrokeParts[1]
            if secondPart.length is 1
              buffer.addStringToInput(secondPart)

# ------------------------------------------------------------------------------
