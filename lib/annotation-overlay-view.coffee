{View} = require('atom-space-pen-views')

# ------------------------------------------------------------------------------

module.exports =
class AnnotationOverlayView extends View

  @content: (_,{type,source,row,col,message}) ->
    @div class: 'levels-view annotation-overlay', =>
      @span class: 'source pull-right', =>
        @text "Source: #{source.charAt(0).toUpperCase()+source.slice(1)}"
      if type is 'warning'
        @span class: 'type badge badge-warning', =>
          @text 'Warning'
      else
        @span class: 'type badge badge-error', =>
          @text 'Error'
      @span class: 'position', =>
        @text "at line #{row+1}" + if col? then ", column #{col+1}" else ""
      @hr()
      @text message

  ## Initialization and destruction --------------------------------------------

  initialize: (textEditor,_) ->

  destroy: ->

  ## Showing and hiding the overlay --------------------------------------------

  show: ->
    @fadeIn(100)

  hide: ->
    @fadeOut(100)

# ------------------------------------------------------------------------------
