let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
let buttons = import "buttons.ncl" in
{
  title = "Covers",
  icon = "mdi:weather-sunny",
  path = "covers",
  type = "sections",
  max_columns = 2,
  sections = [
    {
      type = "grid",
      cards =
        knx.cover
        |> std.array.filter (fun e => std.string.is_match "/(Blinds?|Rollers?)\\b" e.name)
        |> lib.sort_by_floor
        |> lib.chunk (fun e => e.function.location)
        |> std.array.flat_map (fun covers =>
          let blinds =
            covers
            |> std.array.filter (fun e => std.string.is_match "/Blinds?\\b" e.name)
          in
          let rollers =
            covers
            |> std.array.filter (fun e => std.string.is_match "/Rollers?\\b" e.name)
          in
          let location = (std.array.first covers).function.location in
          let floor = (std.array.first covers).function.floor in
          [
            buttons.dashboard_button
            & {
              include location,
              include floor,
              sub_button =
                let roller_buttons =
                  rollers
                  |> std.array.map (fun e =>
                    buttons.dashboard_sub_button
                    & {
                      name = e.function.name,
                      icon = "mdi:roller-shade",
                      entity = lib.entity_id "cover" e.name,
                    }
                  )
                in
                let blind_buttons =
                  blinds
                  |> std.array.map (fun e =>
                    buttons.dashboard_sub_button
                    & {
                      name = e.function.name,
                      icon = "mdi:blinds-horizontal",
                      entity = lib.entity_id "cover" e.name,
                    }
                  )
                in
                blind_buttons @ roller_buttons,
            },
            buttons.dashboard_popup
            & {
              include location,
              include floor,
              icon = "mdi:weather-sunny",
              cards =
                let roller_buttons =
                  rollers
                  |> std.array.map (fun e =>
                    buttons.popup_button
                    & {
                      card_type = "cover",
                      name = e.function.name,
                      icon = "mdi:roller-shade",
                      entity = lib.entity_id "cover" e.name,
                    }
                  )
                in
                let blind_buttons =
                  blinds
                  |> std.array.map (fun e =>
                    buttons.popup_button
                    & {
                      card_type = "cover",
                      name = e.function.name,
                      icon = "mdi:blinds-horizontal",
                      entity = lib.entity_id "cover" e.name,
                    }
                  )
                in
                blind_buttons @ roller_buttons,
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
