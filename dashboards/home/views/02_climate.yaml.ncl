let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Climate",
  path = "climate",
  type = "sections",
  sections = [
    {
      type = "grid",
      columns = 2,
      cards =
        knx.climate
        |> lib.sort_by_floor
        |> lib.chunk (fun e => e.function.location)
        |> std.array.map (fun controllers =>
          let floor_heating =
            controllers
            |> std.array.filter (fun e => std.string.is_match "/Floor heating$" e.name)
          in
          let fcus =
            controllers
            |> std.array.filter (fun e => std.string.is_match "/Air conditioning" e.name)
          in
          let location = (std.array.first controllers).function.location in
          {
            type = "custom:bubble-card",
            card_type = "button",
            button_type = "name",
            name = location,
            show_icon = false,
            card_layout = if std.array.length controllers < 4 then "normal" else "large",
            grid_options = {
              columns =
                if std.array.length controllers < 4 then 6 else "full",
            },
            sub_button =
              let floor_heating_buttons =
                floor_heating
                |> std.array.map (fun e =>
                  {
                    name = "Floor heating",
                    icon = "mdi:heating-coil",
                    entity = lib.entity_id "climate" e.name,
                  }
                )
              in
              let fcu_buttons =
                fcus
                |> std.array.map (fun e =>
                  {
                    name = e.function.name,
                    icon = "mdi:air-conditioner",
                    entity = lib.entity_id "climate" e.name,
                  }
                )
              in
              fcu_buttons @ floor_heating_buttons,
          }
        )
          | std.array.NonEmpty
    },
  ],
}
