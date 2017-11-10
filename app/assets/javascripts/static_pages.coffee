$ ->
  $('.collapse').on 'shown.bs.collapse', ->
    $(this).parent().find(".fa-chevron-right").removeClass("fa-chevron-right").addClass("fa-chevron-down")
  $('.collapse').on 'hidden.bs.collapse', ->
    $(this).parent().find(".fa-chevron-down").removeClass("fa-chevron-down").addClass("fa-chevron-right")
