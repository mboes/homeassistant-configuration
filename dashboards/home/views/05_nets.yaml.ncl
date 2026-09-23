let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
let buttons = import "buttons.ncl" in
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
            buttons.dashboard_button
            & {
              include location,
              include floor,
              sub_button =
                nets
                |> std.array.map (fun e =>
                  buttons.dashboard_sub_button
                  & {
                    name = e.function.name,
                    icon = "mdi:bug",
                    entity = lib.entity_id "cover" e.name,
                  }
                )
            },
            buttons.dashboard_popup
            & {
              include location,
              include floor,
              icon = "mdi:bug",
              cards =
                nets
                |> std.array.map (fun e =>
                  buttons.popup_button
                  & {
                    card_type = "cover",
                    name = e.function.name,
                    icon = "mdi:bug",
                    entity = lib.entity_id "cover" e.name,
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
