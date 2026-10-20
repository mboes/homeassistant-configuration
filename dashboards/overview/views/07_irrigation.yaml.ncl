let knx = import "../../../integrations/knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Irrigation",
  icon = "mdi:sprinkler",
  path = "irrigation",
  type = "sections",
  max_columns = 1,
  sections = [
    {
      type = "grid",
      cards =
        knx.switch
        |> std.array.filter (fun e => std.string.is_match "/Irrigation\\b" e.name)
        |> lib.sort_by_floor
        |> std.array.group (fun e =>
          std.string.find "(\\(Area [0-9] - .*\\))" e.function.name
          |> match {
            { index, .. } if index < 0 => e.function.location,
            { matched, .. } => std.string.join " " [e.function.location, matched],
          }
        )
        |> std.record.map (fun location => std.array.map (fun e => std.record.update "function" (std.record.update "location" location e.function) e))
        |> std.record.values
        |> std.array.flat_map (fun taps =>
          let location = (std.array.first taps).function.location in
          let floor = (std.array.first taps).function.floor in
          [
            {
              type = "custom:bubble-card",
              card_type = "button",
              button_type = "name",
              name = location,
              include floor | not_exported,
              show_icon = false,
              button_action.tap_action = {
                action = "navigate",
                navigation_path = "#%{std.string.replace_regex "(\\s|\\(|\\))+" "_" location}",
              },
              sub_button =
                taps
                |> std.array.map (fun e =>
                  {
                    name = e.function.name,
                    icon = "mdi:sprinkler",
                    entity = lib.entity_id "switch" e.name,
                  }
                )
            },
            {
              type = "custom:bubble-card",
              card_type = "pop-up",
              hash = "#%{std.string.replace_regex "(\\s|\\(|\\))+" "_" location}",
              name = location,
              include floor | not_exported,
              icon = "mdi:sprinkler",
              cards =
                taps
                |> std.array.map (fun e =>
                  {
                    type = "custom:bubble-card",
                    card_type = "button",
                    name = e.function.name,
                    icon = "mdi:sprinkler",
                    entity = lib.entity_id "switch" e.name,
                    button_action.tap_action.action = "more-info",
                  }
                )
            },
          ]
        )
        |> std.array.sort (std.record.apply_on "floor" std.string.compare)
        |> std.array.chunk (fun card => card.floor)
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
