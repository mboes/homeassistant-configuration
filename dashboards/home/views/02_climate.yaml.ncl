let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Climate",
  path = "climate",
  type = "sections",
  sections = [
    {
      type = "custom:vertical-stack-in-card",
      cards = [
        {
          type = "custom:clock-weather-card",
          entity = lib.entity_id "weather" "forecast_home",
          temperature_sensor = lib.entity_id "weather" "//Weather station",
          locale = "gb",
          weather_icon_type = "fill",
          hide_clock = true,
          hide_date = true,
          forecast_rows = 3,
          show_decimal = true,
          hide_forecast_section = true,
        },
        {
          type = "custom:hourly-weather",
	  name = "Next 12 hours",
          entity = lib.entity_id "weather" "forecast_home",
	  round_temperatures = true,
        },
      ],
    },
    {
      type = "grid",
      columns = 2,
      cards =
        knx.climate
        |> lib.sort_by_floor
        |> lib.chunk (fun e => e.function.location)
        |> std.array.flat_map (fun controllers =>
          let floor_heating =
            controllers
            |> std.array.filter (fun e => std.string.is_match "/Floor heating$" e.name)
          in
          let fcus =
            controllers
            |> std.array.filter (fun e => std.string.is_match "/Air conditioning" e.name)
          in
          let location = (std.array.first controllers).function.location in
          let floor = (std.array.first controllers).function.floor in
          [
            {
              type = "custom:bubble-card",
              card_type = "button",
              button_type = "name",
              name = location,
              include floor | not_exported,
              show_icon = false,
              button_action.tap_action = {
                action = "navigate",
                navigation_path = "#%{std.string.replace_regex "\\s+" "_" location}",
              },
              sub_button =
                let floor_heating_buttons =
                  floor_heating
                  |> std.array.map (fun e =>
                    {
                      name = "Floor heating",
                      icon = "mdi:heating-coil",
                      entity = lib.entity_id "climate" e.name,
                    }
                  )
                in
                let fcu_buttons =
                  fcus
                  |> std.array.map (fun e =>
                    {
                      name = e.function.name,
                      icon = "mdi:air-conditioner",
                      entity = lib.entity_id "climate" e.name,
                    }
                  )
                in
                let current_temperature = {
                  name = "Current temperature",
                  icon = "mdi:thermometer",
                  entity =
                    floor_heating
                    |> std.array.at_or 0 (std.array.first fcus)
                    |> std.record.get "name"
                    |> lib.entity_id "climate",
                  show_name = false,
                  show_icon = true,
                  show_background = false,
                  show_attribute = true,
                  attribute = "current_temperature",
                }
                in
                fcu_buttons @ floor_heating_buttons @ [current_temperature],
            },
            {
              type = "custom:bubble-card",
              card_type = "pop-up",
              hash = "#%{std.string.replace_regex "\\s+" "_" location}",
              name = location,
              include floor | not_exported,
              icon = "mdi:home-thermometer",
              cards =
                let fcus_buttons =
                  fcus
                  |> std.array.map (fun e =>
                    {
                      type = "custom:bubble-card",
                      card_type = "climate",
                      name = e.function.name,
                      icon = "mdi:air-conditioner",
                      entity = lib.entity_id "climate" e.name,
                      button_action.tap_action.action = "more-info",
                    }
                  )
                in
                let floor_heating_buttons =
                  floor_heating
                  |> std.array.map (fun e =>
                    {
                      type = "custom:bubble-card",
                      card_type = "climate",
                      name = e.function.name,
                      icon = "mdi:heating-coil",
                      entity = lib.entity_id "climate" e.name,
                      button_action.tap_action.action = "more-info",
                    }
                  )
                in
                let graph = {
                  type = "custom:mini-graph-card",
                  name =
                    if floor_heating == [] then
                      "AC temperature"
                    else
                      "Thermostat temperature",
                  entities = [
                    {
                      entity =
                        floor_heating
                        |> std.array.at_or 0 (std.array.first fcus)
                        |> std.record.get "name"
                        |> lib.entity_id "climate",
                      attribute = "current_temperature",
                    }
                  ],
                  hours_to_show = 48,
                  points_per_hour = 4,
                  hour24 = true,
                  min_bound_range = 6.0,
                  line_color = "#ff6b35",
                  line_width = 3,
                  show = {
                    fill = "fade",
                  },
                }
                in
                fcus_buttons @ floor_heating_buttons @ [graph],
            },
          ]
        )
        |> lib.chunk (fun card => card.floor)
        |> std.array.map (fun cards =>
          cards
          |> std.array.prepend {
            type = "custom:bubble-card",
            card_type = "separator",
            name = (std.array.first cards).floor,
          }
        )
        |> std.array.flatten
          | std.array.NonEmpty
    },
  ],
}
