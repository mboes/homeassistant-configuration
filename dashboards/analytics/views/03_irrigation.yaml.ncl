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
            std.array.range 1 54
            |> std.array.map (fun x => lib.entity_id "binary_sensor" "//Irrigation/%{x}")
        }
      ]
    },
    {
      type = "grid",
      cards = [
        {
          type = "history-graph",
          hours_to_show = 96,
          entities =
            std.array.range 1 54
            |> std.array.map (fun x => lib.entity_id "binary_sensor" "//Irrigation/%{x}/status")
        }
      ]
    },
  ],
}
