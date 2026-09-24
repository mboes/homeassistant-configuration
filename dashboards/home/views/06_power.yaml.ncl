let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
let buttons = import "buttons.ncl" in
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
        |> std.array.chunk (fun e => e.function.location)
        |> std.array.filter_map (fun entities =>
          let appliances =
            entities
            |> std.array.filter (fun e => e.name == "//Main kitchen/Appliances")
            |> std.array.map (fun e => e & { icon = "mdi:stove" })
          in
          let sockets =
            entities
            |> std.array.filter (fun e => std.string.is_match "/Switchable socket\\b" e.name)
            |> std.array.map (fun e => e & { icon = "mdi:power-socket-fr" })
          in
          let towel_heaters =
            entities
            |> std.array.filter (fun e => std.string.is_match "/Towel heater\\b" e.name)
            |> std.array.map (fun e => e & { icon = "mdi:heat-wave" })
          in
          let relays = appliances @ sockets @ towel_heaters in
          let location = (std.array.first relays).function.location in
          let floor = (std.array.first relays).function.floor in
          if relays == [] then
            'None
          else
            'Some [
              buttons.dashboard_button
              & {
                include location,
                include floor,
                sub_button =
                  relays
                  |> std.array.map (fun e =>
                    buttons.dashboard_sub_button
                    & {
                      name = e.function.name,
                      icon = e.icon,
                      entity = lib.entity_id "switch" e.name,
                    }
                  ),
              },
              buttons.dashboard_popup
              & {
                include location,
                include floor,
                icon = "mdi:lightning-bolt",
                cards =
                  relays
                  |> std.array.map (fun e =>
                    buttons.popup_button
                    & {
                      name = e.function.name,
                      icon = e.icon,
                      entity = lib.entity_id "switch" e.name,
                    }
                  )
              },
            ]
        )
        |> std.array.flatten
        |> std.array.chunk (fun card => card.floor)
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
