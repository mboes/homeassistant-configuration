let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
let with_separator = fun name =>
  std.array.prepend {
    type = "custom:bubble-card",
    card_type = "separator",
    include name,
  }
in
{
  title = "Security",
  icon = "mdi:shield",
  show_icon_and_title = true,
  sections = [
    {
      type = "grid",
      cards =
        with_separator
          "Contacts"
          [
            {
              type = "history-graph",
              hours_to_show = 96,
              entities =
                knx.binary_sensor
                |> lib.sort_by_floor
                |> std.array.filter (fun e => std.string.is_match "/Contact$" e.name)
                |> std.array.map (fun e => lib.entity_id "binary_sensor" e.name),
            }
          ]
    },
    {
      type = "grid",
      cards =
        with_separator
          "Locks"
          [
            {
              type = "history-graph",
              hours_to_show = 96,
              entities =
                knx.switch
                |> lib.sort_by_floor
                |> std.array.filter (fun e => std.string.is_match "/Lock$" e.name)
                |> std.array.map (fun e => lib.entity_id "lock" e.name),
            }
          ]
    },
  ],
}
