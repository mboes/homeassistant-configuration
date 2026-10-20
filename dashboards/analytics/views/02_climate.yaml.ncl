let knx = import "../../../integrations/knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Climate",
  icon = "mdi:home-thermometer",
  show_icon_and_title = true,
  max_columns = 3,
  sections =
    knx.climate
    |> lib.sort_by_floor
    |> std.array.map (fun e =>
      {
        type = "custom:mini-graph-card",
        name = e.name,
        entities = [
          {
            entity = lib.entity_id "climate" e.name,
            attribute = "current_temperature",
          }
        ],
        hours_to_show = 72,
        points_per_hour = 1,
        hour24 = true,
        min_bound_range = 6.0,
        line_color = "#ff6b35",
        line_width = 3,
        show = {
          fill = "fade",
        },
      }
    )
}
