module.exports =
  DEFAULT_IS_HIDDEN: false
  DEFAULT_SIZE: 20
  MIN_SIZE: 15
  DEFAULT_FONT_SIZE: 12
  FONT_SIZES: [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30]
  DEFAULT_CONTENT_LIMIT: 2000
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

  dispatchKeyEvent: (terminal, event) ->
    buffer = terminal.getBuffer()
    keystroke = atom.keymaps.keystrokeForKeyboardEvent event.originalEvent
    keystrokeParts = if keystroke == '-' then ['-'] else keystroke.split '-'

    switch keystrokeParts.length
      when 1
        switch firstPart = keystrokeParts[0]
          when 'enter'     then buffer.enterInput()
          when 'backspace' then buffer.removeCharFromInput()
          when 'up'        then buffer.showPreviousInput()
          when 'left'      then buffer.moveInputCursorLeft()
          when 'down'      then buffer.showSubsequentInput()
          when 'right'     then buffer.moveInputCursorRight()
          when 'space'     then buffer.addStringToInput ' '
          else
            if firstPart.length == 1
              buffer.addStringToInput firstPart
      when 2
        switch keystrokeParts[0]
          when 'shift'
            secondPart = keystrokeParts[1]
            if secondPart.length == 1
              buffer.addStringToInput secondPart

    return