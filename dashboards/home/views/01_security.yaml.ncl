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
          if contacts == [] then
            'None
          else
            'Some {
              type = "custom:bubble-card",
              card_type = "button",
              button_type = "name",
              name = (std.array.first contacts).function.location,
              show_icon = false,
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
                        name = e.function.name,
                        entity = lib.entity_id "lock" e.name,
                        tap_action = {
                          action = "more-info",
                        },
                      }
                    ),
                in contact_buttons @ lock_buttons,
            }
        )
          | std.array.NonEmpty
    },
  ],
}
