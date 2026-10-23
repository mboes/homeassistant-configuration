let lib = import "../../../lib.ncl" in
let cfg = import "../../../models/devices.ncl" in

let badge = fun printer name =>
  {
    type = "entity",
    icon = "mdi:alert-octagon",
    color = "red",
    visibility = [
      {
        condition = "state",
        entity = lib.entity_id "binary_sensor" "%{printer}/%{name}",
        state = "on",
      },
    ],
  }
in

let heading = fun name =>
  {
    type = "custom:bubble-card",
    card_type = "separator",
    include name,
    icon | optional,
  }
in

let tile = fun printer name =>
  {
    domain | not_exported | default = "sensor",
    type = "tile",
    entity = lib.entity_id domain "%{printer}/%{name}",
    include name,
  }
in

let slider = fun printer name =>
  {
    type = "custom:bubble-card",
    card_type = "button",
    button_type = "slider",
    entity = lib.entity_id "sensor" "%{printer}/%{name}",
    include name,
    min_value = 0,
    max_value = 100,
  }
in

let annotation = fun printer name =>
  {
    sub_button = [
      {
        entity = lib.entity_id "sensor" "%{printer}/%{name}",
        state_content = "state",
        show_icon = false,
        show_name = false,
        show_background = false,
        tap_action.action = "more-info",
      },
    ],
  }
in

let colours = [
  { name = "Black", css = "var(--black-color)" },
  { name = "Cyan", css = "var(--cyan-color)" },
  { name = "Magenta", css = "var(--magenta-color, var(--pink-color))" },
  { name = "Yellow", css = "var(--yellow-color)" },
]
in

cfg.printers
|> std.array.map (fun printer =>
  {
    title = "Printer",
    path = "printers",
    icon = "mdi:printer",
    type = "sections",
    max_columns = 1,

    badges = [
      badge printer.name "Paper jam",
      badge printer.name "No paper",
      badge printer.name "Door open",
      badge printer.name "No toner",
      badge printer.name "Low toner",
    ],

    sections = [
      {
        type = "grid",
        cards = [
          tile printer.name "Status" & { grid_options.columns = 12 },
          tile printer.name "Message" & { grid_options.columns = 12 },
          tile printer.name "Paper jam" & { domain = "binary_sensor" },
          tile printer.name "No paper" & { domain = "binary_sensor" },
          tile printer.name "Door open" & { domain = "binary_sensor" },
          tile printer.name "low toner" & { domain = "binary_sensor" },
        ],
      },
      {
        type = "grid",
        cards =
          let slider_style = fun colour =>
            {
              show_name = false,
              styles = m%"
              .bubble-range-fill {
                background: repeating-linear-gradient(
                  135deg,
                  %{colour.css} 0 7px,
                  var(--divider-color) 7px 12px
                ) !important;
              }
            "%,
            }
          in
          std.array.flatten [
            [heading "Toner" & { icon = "mdi:printer-3d-nozzle" }],
            colours
            |> std.array.map (fun colour =>
              slider printer.name "%{colour.name} toner" & slider_style colour
            ),
            [heading "Drum" & { icon = "mdi:cylinder" }],
            colours
            |> std.array.map (fun colour =>
              slider printer.name "%{colour.name} drum life"
              & slider_style colour
              & annotation printer.name "%{colour.name} drum pages left"
            ),
          ],
      },
      {
        type = "grid",
        cards = [
          heading "Usage" & { icon = "mdi:counter" },
          tile printer.name "B/W pages",
          tile printer.name "Colour pages",
          tile printer.name "Black drum pages",
          tile printer.name "Cyan drum pages",
          tile printer.name "Magenta drum pages",
          tile printer.name "Yellow drum pages",
        ],
      },
    ],
  }
)
