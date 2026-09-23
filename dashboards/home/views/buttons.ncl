{
  dashboard_button = fun { location, floor, sub_buttons } =>
    {
      type = "custom:bubble-card",
      card_type = "button",
      button_type = "name",
      name = location,
      include floor | not_exported,
      show_icon = false,
      button_action.tap_action = {
        action = "navigate",
        navigation_path = "#%{std.string.replace_regex "\\s+" "_" location}",
      },
      sub_button = sub_buttons,
    },
  dashboard_popup = fun { location, floor, icon, cards } =>
    {
      type = "custom:bubble-card",
      card_type = "pop-up",
      hash = "#%{std.string.replace_regex "\\s+" "_" location}",
      name = location,
      include floor | not_exported,
      include icon,
      include cards,
    },
  popup_button = fun { name, icon, entity } =>
    {
      type = "custom:bubble-card",
      card_type = "button",
      include name,
      include icon,
      include entity,
      button_action.tap_action.action = "more-info",
    }
}
