let knx = import "../../../knx.yaml.ncl" in
let lib = import "../../../lib.ncl" in
{
  title = "Lighting",
  path = "lights",
  type = "sections",
  sections = [
    {
      type = "grid",
      cards =
        knx.light
	|> std.array.filter (fun e => ! std.string.is_match "^All lights" e.function.name)
        |> lib.sort_by_floor
        |> lib.chunk (fun e => e.function.location)
        |> std.array.map (fun lights =>
          {
            type = "custom:bubble-card",
            card_type = "button",
            button_type = "name",
            name = (std.array.first lights).function.location,
            show_icon = false,
            sub_button =
              let
                light_buttons =
                  lights
                  |> std.array.map (fun e =>
                    {
                      name = e.function.name,
                      entity = lib.entity_id "light" e.name,
                      tap_action = {
                        action = "more-info",
                      },
                    }
                  ),
              in light_buttons,
          }
        )
          | std.array.NonEmpty
    },
  ],
}
