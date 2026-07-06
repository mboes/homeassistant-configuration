let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Security",
  path = "security",
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
        let heading = {
          type = "heading",
          heading = "Garage",
          heading_style = "title",
        }
        in
        let tiles = [
          {
            type = "tile",
            entity = lib.entity_id "switch" "//Garage/Door",
            name = "Garage door",
          },
          {
            type = "tile",
            entity = lib.entity_id "switch" "//Garage/Gate",
            name = "Garage gate",
          },
        ]
        in
        [heading] @ tiles
    },
    {
      type = "grid",
      cards =
        let heading = {
          type = "heading",
          heading = "Open windows & doors",
          heading_style = "title",
        }
        in
        let tiles =
          knx.binary_sensor
	  |> std.array.sort (std.record.apply_on "name" std.string.compare)
          |> std.array.filter_map (fun e =>
            std.string.find "//(.*)/(.*)/Contact" e.name
            |> match {
              { index, .. } if index < 0 => 'None,
              { groups = [room, contact], .. } =>
                'Some {
                  type = "tile",
                  entity = lib.entity_id "binary_sensor" e.name,
                  name = "%{room} - %{contact}",
                },
            }
          ) | std.array.NonEmpty
        in
        [heading] @ tiles
    },
    {
      type = "grid",
      cards =
        let heading = {
          type = "heading",
          heading = "Locks",
          heading_style = "title",
        }
        in
        let tiles =
          knx.switch
	  |> std.array.sort (std.record.apply_on "name" std.string.compare)
          |> std.array.filter_map (fun e =>
            std.string.find "//(.*)/Sliding windows/Lock" e.name
            |> match {
              { index, .. } if index < 0 => 'None,
              { groups = [room], .. } =>
                'Some {
                  type = "tile",
                  entity = lib.entity_id "lock" e.name,
                  name = room,
                },
            }
          ) | std.array.NonEmpty
        in
        [heading] @ tiles
    },
  ],
}
