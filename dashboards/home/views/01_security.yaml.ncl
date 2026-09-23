let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
let buttons = import "buttons.ncl" in
{
  title = "Security",
  icon = "mdi:shield",
  path = "security",
  type = "sections",
  max_columns = 2,
  sections = [
    {
      type = "grid",
      cards = [
        {
          type = "alarm-panel",
          name = "Intrusion alarm",
          entity = "alarm_control_panel.intrusion_alarm",
        }
      ],
    },
    {
      type = "grid",
      cards = [
        {
          type = "tile",
          name = "Garage gate CLOSED",
          entity = lib.entity_id "button" "//Garage/Gate/CLOSED",
          icon = "mdi:gate",
        },
        {
          type = "tile",
          name = "Garage gate OPEN",
          entity = lib.entity_id "button" "//Garage/Gate/OPEN",
          icon = "mdi:gate-open",
        },
        {
          type = "tile",
          name = "Garage door",
          entity = lib.entity_id "switch" "//Garage/Door",
          icon = "mdi:garage-variant",
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
          let security_entities = contacts @ locks in
          let location = (std.array.first security_entities).function.location in
          let floor = (std.array.first security_entities).function.floor in
          if contacts == [] then
            'None
          else
            'Some [
              buttons.dashboard_button
              & {
                include location,
                include floor,
                sub_button =
                  let
                    contact_buttons =
                      contacts
                      |> std.array.map (fun e =>
                        buttons.dashboard_sub_button
                        & {
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
                        buttons.dashboard_sub_button
                        & {
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
              buttons.dashboard_popup
              & {
                include location,
                include floor,
                icon = "mdi:shield",
                cards =
                  let contact_buttons =
                    contacts
                    |> std.array.map (fun e =>
                      buttons.popup_button
                      & {
                        name = e.function.name,
                        icon =
                          if std.string.contains "Sliding" e.function.name then
                            "mdi:door-sliding-lock"
                          else if std.string.contains "Door" e.function.name then
                            "mdi:door"
                          else
                            "mdi:window-closed-variant",
                        entity = lib.entity_id "binary_sensor" e.name,
                      }
                    )
                  in
                  let lock_buttons =
                    locks
                    |> std.array.map (fun e =>
                      buttons.popup_button
                      & {
                        name = e.function.name,
                        entity = lib.entity_id "lock" e.name,
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
