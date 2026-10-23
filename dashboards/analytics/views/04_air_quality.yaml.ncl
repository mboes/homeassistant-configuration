let knx = import "../../../integrations/knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
let cfg = import "../../../models/devices.ncl" in

let heading = fun title =>
  [
    {
      type = "custom:bubble-card",
      card_type = "separator",
      name = title,
      icon | optional,
    }
  ]
in

{
  title = "Air quality",
  icon = "mdi:cards-heart",
  path = "air_quality",
  show_icon_and_title = true,
  max_columns = 3,
  sections = [
    {
      type = "grid",
      cards =
        heading "Carbon dioxide"
        @ (
          cfg.air_quality_sensors
          |> std.array.map (fun sensor =>
            {
              type = "custom:mini-graph-card",
              name = sensor.location,
              entities = [
                {
                  entity = lib.entity_id "sensor" "%{sensor.name}/Carbon dioxide",
                }
              ],
              hours_to_show = 72,
              points_per_hour = 1,
              hour24 = true,
              min_bound_range = 100,
              line_color = "#4a7bb0",
              line_width = 3,
              show = {
                fill = "fade",
              },
            }
          )
        ),
    },
    {
      type = "grid",
      cards =
        heading "Volatile organic compounds"
        @ (
          cfg.air_quality_sensors
          |> std.array.map (fun sensor =>
            {
              type = "custom:mini-graph-card",
              name = sensor.location,
              entities = [
                {
                  entity = lib.entity_id "sensor" "%{sensor.name}/Volatile organic compounds parts",
                }
              ],
              hours_to_show = 72,
              points_per_hour = 1,
              hour24 = true,
              min_bound_range = 100,
              line_color = "#8a8f98",
              line_width = 3,
              show = {
                fill = "fade",
              },
            }
          )
        ),
    },
  ]
}
