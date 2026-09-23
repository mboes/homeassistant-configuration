let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Power",
  icon = "mdi:lightning-bolt",
  path = "power",
  type = "sections",
  max_columns = 2,
  sections = [
    {
      type = "grid",
      cards = [
        {
          type = "tile",
          name = "UPS battery",
          entity = lib.entity_id "binary_sensor" "//UPS battery",
        },
        {
          type = "tile",
          name = "UPS status",
          entity = lib.entity_id "binary_sensor" "//UPS alarm",
        },
      ]
    },
    {
      type = "grid",
      cards =
        knx.switch
        |> lib.sort_by_floor
        |> lib.chunk (fun e => e.function.location)
        |> std.array.filter_map (fun entities =>
          let sockets =
            entities |> std.array.filter (fun e => std.string.is_match "/Switchable socket\\b" e.name)
          in
          let towel_heaters =
            entities |> std.array.filter (fun e => std.string.is_match "/Towel heater\\b" e.name)
          in
          let relays = sockets @ towel_heaters in
          if relays == [] then
            'None
          else
            let location = (std.array.first relays).function.location in
            let floor = (std.array.first relays).function.floor in
            'Some [
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
                  std.array.concat
                    (
                      towel_heaters
                      |> std.array.map (fun e =>
                        {
                          name = e.function.name,
                          icon = "mdi:heat-wave",
                          entity = lib.entity_id "switch" e.name,
                        }
                      )
                    )
                    (
                      sockets
                      |> std.array.map (fun e =>
                        {
                          name = e.function.name,
                          icon = "mdi:power-socket-fr",
                          entity = lib.entity_id "switch" e.name,
                        }
                      )
                    )
              },
              {
                type = "custom:bubble-card",
                card_type = "pop-up",
                hash = "#%{std.string.replace_regex "\\s+" "_" location}",
                name = location,
                include floor | not_exported,
                icon = "mdi:lightning-bolt",
                cards =
                  std.array.concat
                    (
                      towel_heaters
                      |> std.array.map (fun e =>
                        {
                          type = "custom:bubble-card",
                          card_type = "button",
                          name = e.function.name,
                          icon = "mdi:heat-wave",
                          entity = lib.entity_id "switch" e.name,
                          button_action.tap_action.action = "more-info",
                        }
                      )
                    )
                    (
                      sockets
                      |> std.array.map (fun e =>
                        {
                          type = "custom:bubble-card",
                          card_type = "button",
                          name = e.function.name,
                          icon = "mdi:power-socket-fr",
                          entity = lib.entity_id "switch" e.name,
                          button_action.tap_action.action = "more-info",
                        }
                      )
                    )
              },
            ]
        )
        |> std.array.flatten
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
