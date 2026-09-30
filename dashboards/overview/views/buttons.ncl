# A bespoke library of UI elements
#
# A dashboard view consists of mostly buttons, optionally containing
# sub buttons. Each button typically has an associated popup. The sub
# buttons of a button should be the buttons of the associated popup.
{
  dashboard_button = {
    location | not_exported,
    floor | not_exported,
    type = "custom:bubble-card",
    card_type = "button",
    button_type = "name",
    name = location,
    show_icon = false,
    button_action.tap_action = {
      action = "navigate",
      navigation_path = "#%{std.string.replace_regex "\\s+" "_" location}",
    },
    sub_button,
    styles | optional,
  },

  dashboard_sub_button = {
    name,
    icon | optional,
    entity,
  },

  dashboard_popup = {
    location | not_exported,
    floor | not_exported,
    type = "custom:bubble-card",
    card_type = "pop-up",
    hash = "#%{std.string.replace_regex "\\s+" "_" location}",
    name = location,
    icon,
    cards,
  },

  popup_button = {
    type = "custom:bubble-card",
    card_type | default = "button",
    name,
    icon | optional,
    entity,
    button_action.tap_action.action = "more-info",
  },
}
