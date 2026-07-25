let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Security",
  path = "security",
  type = "sections",
  sections = [
    {
      type = "grid",
      cards = [
        {
          type = "alarm-panel",
          entity = "alarm_control_panel.intrusion_alarm",
          name = "Intrusion alarm",
        }
      ],
    },
    {
      type = "grid",
      cards = [
        {
          type = "tile",
          entity = lib.entity_id "switch" "//Garage/Door",
          name = "Garage door",
        },
        {
          type = "tile",
          entity = lib.entity_id "switch" "//Garage/Gate",
          name = "Garage gate",
        },
      ]
    },
    {
      type = "grid",
      columns = 2,
      cards =
        (knx.binary_sensor @ knx.switch)
        |> lib.sort_by_floor
        # Already accounted for in garage section.
        |> std.array.filter (fun e => e.name != "//Garage/Door/Contact")
        |> lib.chunk (fun e => e.function.location)
        |> std.array.filter_map (fun entities =>
          let
            contacts =
              entities
              |> std.array.filter (fun e => std.string.is_match "/Contact$" e.name),
            locks =
              entities
              |> std.array.filter (fun e => std.string.is_match "/Lock$" e.name),
          in
          let location = (std.array.first contacts).function.location in
          let floor = (std.array.first contacts).function.floor in
          if contacts == [] then
            'None
          else
            'Some [
              {
                type = "custom:bubble-card",
                card_type = "button",
                button_type = "name",
                name = (std.array.first contacts).function.location,
                include floor | not_exported,
                show_icon = false,
                button_action.tap_action = {
                  action = "navigate",
                  navigation_path = "#%{std.string.replace_regex "\\s+" "_" location}",
                },
                sub_button =
                  let
                    contact_buttons =
                      contacts
                      |> std.array.map (fun e =>
                        {
                          name = e.function.name,
                          icon =
                            if std.string.contains "Sliding" e.function.name then
                              "mdi:door-sliding-lock"
                            else if std.string.contains "Door" e.function.name then
                              "mdi:door"
                            else
                              "mdi:window-closed-variant",
                          entity = lib.entity_id "binary_sensor" e.name,
                          tap_action = {
                            action = "more-info",
                          },
                        }
                      ),
                    lock_buttons =
                      locks
                      |> std.array.map (fun e =>
                        {
                          name = "Lock",
                          entity = lib.entity_id "lock" e.name,
                          tap_action = {
                            action = "more-info",
                          },
                        }
                      ),
                  in contact_buttons @ lock_buttons,
                styles =
                  if locks == [] then
                    ""
                  else
                    m%"
                .lock-button {
                  background: ${hass.states['%{lib.entity_id "lock" (std.array.first locks).name}'].state === 'locked' ? 'var(--card-background-color)' : 'var(--error-color)'} !important;
                }
              "%,
              },
              {
                type = "custom:bubble-card",
                card_type = "pop-up",
                hash = "#%{std.string.replace_regex "\\s+" "_" location}",
                name = location,
                include floor | not_exported,
                icon = "mdi:shield",
                cards =
                  let contact_buttons =
                    contacts
                    |> std.array.map (fun e =>
                      {
                        type = "custom:bubble-card",
                        card_type = "button",
                        name = e.function.name,
                        icon =
                          if std.string.contains "Sliding" e.function.name then
                            "mdi:door-sliding-lock"
                          else if std.string.contains "Door" e.function.name then
                            "mdi:door"
                          else
                            "mdi:window-closed-variant",
                        entity = lib.entity_id "binary_sensor" e.name,
                        button_action.tap_action.action = "more-info",
                      }
                    )
                  in
                  let lock_buttons =
                    locks
                    |> std.array.map (fun e =>
                      {
                        type = "custom:bubble-card",
                        card_type = "button",
                        name = e.function.name,
                        entity = lib.entity_id "lock" e.name,
                        button_action.tap_action.action = "more-info",
                      }
                    )
                  in
                  contact_buttons @ lock_buttons,
              },
            ]
        )
        |> std.array.flatten
        |> lib.chunk (fun card => card.floor)
        |> std.array.map (fun cards =>
          cards
          |> std.array.prepend {
            type = "custom:bubble-card",
            card_type = "separator",
            name = (std.array.first cards).floor,
          }
        )
        |> std.array.flatten
          | std.array.NonEmpty
    },
  ],
}
