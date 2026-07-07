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
      cards =
        let heading = {
          type = "heading",
          heading = "Garage",
          heading_style = "title",
        }
        in
        let tiles = [
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
        in
        [heading] @ tiles
    },
    {
      type = "grid",
      cards =
        let heading = {
          type = "heading",
          heading = "Open windows & doors",
          heading_style = "title",
        }
        in
        let tiles =
          knx.binary_sensor
          |> std.array.filter (fun e => std.string.is_match "/Contact$" e.name)
          |> std.array.map_with_index (std.record.insert "key")
          |> lib.group (fun e => if e.key < 10 then "0%{e.key}" else "%{e.key}")
          |> std.record.map (fun _ contacts =>
            {
              type = "custom:bubble-card",
              card_type = "button",
              button_type = "name",
              name = (std.array.first contacts).function.location,
              tap_action = {
                action = "more-info",
              },
              button_action = {
                tap_action = {
                  action = "more-info",
                },
              },
              sub_button =
                contacts
                |> std.array.map (fun e =>
                  {
                    name = e.function.name,
                    icon = "mdi:window-closed-variant",
                    entity = lib.entity_id "switch" e.name,
                    tap_action = {
                      action = "more-info",
                    },
                  }
                ),
            }
          )
          |> std.record.values
            | std.array.NonEmpty
        in
        [heading] @ tiles
    },
    {
      type = "grid",
      cards =
        let heading = {
          type = "heading",
          heading = "Locks",
          heading_style = "title",
        }
        in
        let tiles =
          knx.switch
          |> std.array.filter (fun e => std.string.is_match "/Lock$" e.name)
          |> std.array.map (fun e =>
            {
              type = "tile",
              entity = lib.entity_id "lock" e.name,
              name = e.function.location,
            }
          ) | std.array.NonEmpty
        in
        [heading] @ tiles
    },
  ],
}
