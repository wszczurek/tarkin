passwords = {} # cache for passwords retrieved by AJAX

@ready = () ->
  $('.hidden').hide()
  $('#cookies-information-close-button').click ->
    ok_with_cookies()
  $('.highlightable').hover(
    -> 
      highlight_row($(this))
    -> 
      lowlight_row($(this))
  )
  $('.favorite-switch').change ->
    favorite_switch($(this))
  $('.password').each ->
    show_password($(this)) if $(this).data('favorite')
  $('#edit-mode-button').click ->
    switch_edit_mode($(this))
  $(document).bind('ajaxError', 'form#new_directory', (event, jqxhr, settings, exception) -> 
    render_form_errors($.parseJSON(jqxhr.responseText)))   # show errors which cames back from rails
  $('#new-directory-modal').on "opened.fndtn.reveal", -> 
    $("#new_directory input:text, #new_directory textarea").first().focus(); # focus on the first element
  $('#new-directory-form-close-button').click -> $('#new-directory-modal').foundation('reveal', 'close')

@ready_with_foundation = () ->
  $(document).foundation() # bad looking, but it must be re-initialized because of turbolinks
  ready()

capitalize = (word) -> 
  word.charAt(0).toUpperCase() + word.slice 1

render_form_errors = (errors) ->
  s = ""
  for key, value of errors
    s += capitalize "#{key} #{value.join(' and ')}. <br>"
  $('#new-directory-modal-alert-box-text').html(s)
  $('#new-directory-modal-alert-box').fadeIn(250)

switch_edit_mode = (button) ->
  button.toggleClass('active')
  $('.favorite-switch').toggle()
  $('.edit-button').toggle()
  $('.buttons-panel').toggle()

favorite_switch = (sw) ->
  $.ajax
    url: "/_aj/switch_favorite"
    type: 'post'
    data: { type: sw.data('type'), id: sw.data('id') }
    error: ->
      alert "Server not responding"

highlight_row = (row) ->
  row.addClass('highlight')
  show_password_in_row(row)

show_password_in_row = (row) ->
  item = row.find('.password')
  show_password(item)

show_password = (item) ->
  unless item.length == 0
    item_id = item.data('id')
    if item_id
      if passwords[item_id]
        # password is in cache
        item.text(passwords[item_id]) 
        item.attr('showing', true) 
        item.fadeIn(100)
      else
        # must get it via AJAX
        unless item.attr('processing')
          item.attr('processing', true)
          get_password(item)

lowlight_row = (row) ->
  row.removeClass('highlight')
  sw = row.find('.favorite-switch')
  item = row.find('.password')
  unless item.length == 0 
    unless sw.is(':checked')
      item.fadeOut(100, -> item.html(''))
      item.attr('showing', false) 


get_password = (item) ->
  $.ajax
    url: "/_api/v1/_password"
    type: 'get'
    data: {id: item.data('id')}
    context: item
    success: (data) ->
      passwords[item.data('id')] = data
      unless item.attr('showing') 
        $(this).text(data)
        $(this).attr('processing', false)
        $(this).fadeIn(100)
    error: ->
      alert "Server not responding"

ok_with_cookies = () ->
  $.ajax
    url: '/_aj/ok_with_cookies'
    type: 'post'
    data: true
    error: ->
      alert "Server not responding"

$(document).ready(@ready)
$(document).on('page:load', @ready_with_foundation)
