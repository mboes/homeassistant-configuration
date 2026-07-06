let entity_id = fun domain name =>
  let slug =
    name
    |> std.string.replace_regex "[^a-zA-Z0-9]" " "
    |> std.string.replace_regex "\\s+" "_"
    |> std.string.replace_regex "^_" ""
    |> std.string.replace_regex "_$" ""
    |> std.string.lowercase
  in
  "%{domain}.%{slug}"
in
{
  title = "Alarm",
  path = "alarm",
  type = "sections",
  sections = [
    {
      type = "grid",
      cards = [
        {
          type = "alarm-panel",
          entity = "alarm_control_panel.intrusion_alarm",
          name = "Intrusion alarm",
        }
      ],
    },
    {
      type = "grid",
      cards =
        let knx = import "../../../knx.yaml.ncl" in
        let heading = {
          type = "heading",
          heading = "Open rooms",
          heading_style = "title",
        }
        in
        let tiles =
          knx.binary_sensor
          |> std.array.filter_map (fun e =>
            std.string.find "//(.*)/(.*)/Contact" e.name
            |> match {
              { index, .. } if index < 0 => 'None,
              { groups = [room, contact], .. } =>
                'Some {
                  type = "tile",
                  entity = entity_id "binary_sensor" e.name,
                  name = "%{room} - %{contact}",
                },
            }
          ) | std.array.NonEmpty
        in
        [heading] @ tiles
    },
  ],
}
