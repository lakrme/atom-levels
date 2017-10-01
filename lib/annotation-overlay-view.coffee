module.exports =
class AnnotationOverlayView
  constructor: ({type, source, row, col, message}) ->
    @element = document.createElement 'div'
    @element.className = 'levels-view annotation-overlay'
    @element.style.display = 'none'

    @headerDiv = document.createElement 'div'
    @headerDiv.className = 'header'
    @element.appendChild @headerDiv

    @typeSpan = document.createElement 'span'
    @typeSpan.className = "type badge badge-flexible badge-#{type}"
    @typeSpan.textContent = type
    @headerDiv.appendChild @typeSpan

    @positionSpan = document.createElement 'span'
    @positionSpan.className = 'position'
    @positionSpan.textContent = "at line #{row + 1}" + if col then ", column #{col + 1}" else ''
    @headerDiv.appendChild @positionSpan

    @sourceSpan = document.createElement 'span'
    @sourceSpan.className = 'source'
    @sourceSpan.textContent = source
    @headerDiv.appendChild @sourceSpan

    @element.appendChild document.createElement 'hr'

    @messageDiv = document.createElement 'div'
    @messageDiv.textContent = message
    @element.appendChild @messageDiv

  show: ->
    @element.style.display = ''
    return

  hide: ->
    @element.style.display = 'none'
    return