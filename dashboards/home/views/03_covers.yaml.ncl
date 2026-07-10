let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Covers",
  path = "covers",
  type = "sections",
  sections = [
    {
      type = "grid",
      cards =
        knx.cover
        |> lib.sort_by_floor
        |> lib.chunk (fun e => e.function.location)
        |> std.array.map (fun covers =>
          let blinds =
            covers
            |> std.array.filter (fun e => std.string.is_match "/Blind" e.name)
          in
          let rollers =
            covers
            |> std.array.filter (fun e => std.string.is_match "/Roller" e.name)
          in
          let location = (std.array.first covers).function.location in
          {
            type = "custom:bubble-card",
            card_type = "button",
            button_type = "name",
            name = location,
            show_icon = false,
            sub_button =
              let roller_buttons =
                rollers
                |> std.array.map (fun e =>
                  {
                    name = e.function.name,
                    icon = "mdi:roller-shade",
                    entity = lib.entity_id "cover" e.name,
                  }
                )
              in
              let blind_buttons =
                blinds
                |> std.array.map (fun e =>
                  {
                    name = e.function.name,
                    icon = "mdi:blinds-horizontal",
                    entity = lib.entity_id "cover" e.name,
                  }
                )
              in
              blind_buttons @ roller_buttons,
          }
        )
          | std.array.NonEmpty
    },
  ],
}
