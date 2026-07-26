let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Lights",
  icon = "mdi:lightbulb-variant",
  path = "lights",
  type = "sections",
  max_columns = 2,
  sections = [
    {
      type = "grid",
      cards = [
        {
          type = "tile",
          name = "House OFF",
          entity = lib.entity_id "button" "//House/All lights",
          icon = "mdi:lightbulb-multiple-off",
        },
        {
          type = "tile",
          name = "Exterior OFF",
          entity = lib.entity_id "button" "//House/All lights exterior",
          icon = "mdi:lightbulb-multiple-off",
        },
      ]
    },
    {
      type = "grid",
      cards =
        ["Basement", "Ground floor", "1st floor", "2nd floor"]
        |> std.array.map (fun floor =>
          {
            type = "tile",
            name = "%{floor} OFF",
            entity = lib.entity_id "button" "//%{floor}/All lights",
            icon = "mdi:lightbulb-multiple-off",
          }
        )
    },
    {
      type = "grid",
      cards =
        knx.light
        |> std.array.filter (fun e => !std.string.is_match "^All lights" e.function.name)
        |> lib.sort_by_floor
        |> lib.chunk (fun e => e.function.location)
        |> std.array.map (fun lights =>
          let location = (std.array.first lights).function.location in
          let floor = (std.array.first lights).function.floor in
          let group_name = "//%{location}/Lights" in
          {
            type = "custom:bubble-card",
            card_type = "button",
            name = location,
            include floor | not_exported,
            entity = lib.entity_id "light" group_name,
            show_icon = false,
            scrolling_effect = false,
            grid_options.columns = 6,
            sub_button = [
              {
                name = "Lights summary",
                entity = lib.entity_id "sensor" "%{group_name}/Summary",
                show_background = false,
                show_icon = true,
                show_state = true,
              },
            ],
            styles = "${subButtonIcon[0].setAttribute('icon', state === 'on' ? 'mdi:lightbulb-multiple' : 'mdi:lightbulb-off-outline')}",
          }
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
