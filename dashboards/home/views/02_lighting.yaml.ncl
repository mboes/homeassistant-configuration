let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Lighting",
  path = "lights",
  type = "sections",
  sections = [
    {
      type = "grid",
      cards = [
        {
          type = "tile",
          name = "House OFF",
          entity = lib.entity_id "button" "//House/All lights",
        },
        {
          type = "tile",
          name = "Exterior OFF",
          entity = lib.entity_id "button" "//House/All lights exterior",
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
          let group_name = "//%{location}/Lights" in
          {
            type = "custom:bubble-card",
            card_type = "button",
            name = location,
            entity = lib.entity_id "light" group_name,
            show_icon = false,
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
          | std.array.NonEmpty
    },
  ],
}
