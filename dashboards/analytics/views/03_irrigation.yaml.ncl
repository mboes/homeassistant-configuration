let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Irrigation",
  icon = "mdi:sprinkler",
  show_icon_and_title = true,
  sections = [
    {
      type = "grid",
      cards = [
        {
          type = "history-graph",
          hours_to_show = 96,
          entities =
            knx.switch
            |> lib.sort_by_floor
            |> std.array.filter (fun e => std.string.is_match "/Irrigation" e.name)
            |> std.array.map (fun e => lib.entity_id "switch" e.name),
        }
      ]
    },
  ],
}
