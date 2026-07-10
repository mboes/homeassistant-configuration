let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Climate",
  path = "climate",
  type = "sections",
  sections = [
    {
      type = "grid",
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
          let group_name = "//%{location}/Climate" in
          {
            type = "custom:bubble-card",
            card_type = "button",
            button_type = "name",
            name = location,
            entity = lib.entity_id "climate" group_name,
            show_icon = false,
            sub_button =
              let floor_heating_buttons =
                floor_heating
                |> std.array.map (fun e =>
                  {
                    name = "Floor heating",
                    icon = "mdi:heat-coil",
                    entity = lib.entity_id "climate" e.name,
                  }
                )
              in
              let fcus_buttons =
                fcus
                |> std.array.map (fun e =>
                  {
                    name = e.function.name,
                    icon = "mdi:air-conditioner",
                    entity = lib.entity_id "climate" e.name,
                  }
                )
              in
              floor_heating_buttons @ fcus_buttons,
          }
        )
          | std.array.NonEmpty
    },
  ],
}
