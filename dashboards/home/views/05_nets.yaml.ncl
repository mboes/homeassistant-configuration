let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Nets",
  icon = "mdi:bug",
  path = "nets",
  type = "sections",
  max_columns = 2,
  sections = [
    {
      type = "grid",
      cards =
        knx.cover
        |> std.array.filter (fun e => std.string.is_match "/Net\\b" e.name)
        |> lib.sort_by_floor
        |> lib.chunk (fun e => e.function.location)
        |> std.array.flat_map (fun nets =>
          let location = (std.array.first nets).function.location in
          let floor = (std.array.first nets).function.floor in
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
                navigation_path = "#%{std.string.replace_regex "\\s+" "_" location}",
              },
              sub_button =
                nets
                |> std.array.map (fun e =>
                  {
                    name = e.function.name,
                    icon = "mdi:bug",
                    entity = lib.entity_id "cover" e.name,
                  }
                )
            },
            {
              type = "custom:bubble-card",
              card_type = "pop-up",
              hash = "#%{std.string.replace_regex "\\s+" "_" location}",
              name = location,
              include floor | not_exported,
              icon = "mdi:bug",
              cards =
                nets
                |> std.array.map (fun e =>
                  {
                    type = "custom:bubble-card",
                    card_type = "cover",
                    name = e.function.name,
                    icon = "mdi:bug",
                    entity = lib.entity_id "cover" e.name,
                    button_action.tap_action.action = "more-info",
                  }
                )
            },
          ]
        )
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
