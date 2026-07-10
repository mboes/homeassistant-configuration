let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Nets",
  path = "nets",
  type = "sections",
  sections = [
    {
      type = "grid",
      cards =
        knx.cover
        |> std.array.filter (fun e => std.string.is_match "/Net\\b" e.name)
        |> lib.sort_by_floor
        |> lib.chunk (fun e => e.function.location)
        |> std.array.map (fun nets =>
          let location = (std.array.first nets).function.location in
          {
            type = "custom:bubble-card",
            card_type = "button",
            button_type = "name",
            name = location,
            show_icon = false,
            sub_button =
              nets
              |> std.array.map (fun e =>
                {
                  name = e.function.name,
                  icon = "mdi:bug",
                  entity = lib.entity_id "cover" e.name,
                }
              )
          }
        )
          | std.array.NonEmpty
    },
  ],
}
