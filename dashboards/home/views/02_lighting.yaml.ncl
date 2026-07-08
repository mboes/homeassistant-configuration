let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Lighting",
  path = "lights",
  type = "sections",
  sections = [
    {
      type = "grid",
      cards =
        knx.light
        |> std.array.filter (fun e => !std.string.is_match "^All lights" e.function.name)
        |> lib.sort_by_floor
        |> lib.chunk (fun e => e.function.location)
        |> std.array.map (fun lights =>
          let location = (std.array.first lights).function.location in
          let group_id = "//%{location}/Lights" in
          {
            type = "custom:bubble-card",
            card_type = "button",
            button_type = "name",
            name = location,
            entity = lib.entity_id "light" group_id,
            show_icon = false,
            sub_button = [
              {
                name = "Number of ON lights",
                entity = lib.entity_id "sensor" "%{group_id}/Summary",
                show_background = false,
		show_icon = false,
                show_state = true,
		show_attribute = true,
		attribute = "total",
              }
            ],
          }
        )
          | std.array.NonEmpty
    },
  ],
}
