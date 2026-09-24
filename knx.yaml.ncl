# Entities provided by the KNX integration
#
# Defines Home Assistant entities, using the ETS configuration as
# a database. For each family of entities we want to define, we filter
# through the database to find matching KNX functions.

# A model of the ETS configuration.
let cfg = import "knx-model.yaml" in

# As measured.
let rollers_travelling_time = 33 in

# A small DSL for expressing what KNX functions to select.
let knx = {
  type_is = fun type f => f.type == type,
  name_is = fun name f => f.name == name,
  location_is = fun loc f => f.location == loc,
  location_type_is =
    let location_types =
      cfg.locations
      |> std.array.map (fun r => { field = r.name, value = r.type })
      |> std.record.from_array
    in
    fun type f => std.record.get f.location location_types == type,
  and = fun p1 p2 f => p1 f && p2 f,
  name_matches = fun pat =>
    # Share compilation of regex.
    let is_match = std.string.is_match (std.string.lowercase pat) in
    fun f => f.name |> std.string.lowercase |> is_match,
  name_contains = fun word => name_matches "\\b%{word}s?\\b",
  merge =
    let f = fun r1 r2 =>
      {
        binary_sensor = std.record.get_or "binary_sensor" [] r1 @ std.record.get_or "binary_sensor" [] r2,
        button = std.record.get_or "button" [] r1 @ std.record.get_or "button" [] r2,
        climate = std.record.get_or "climate" [] r1 @ std.record.get_or "climate" [] r2,
        cover = std.record.get_or "cover" [] r1 @ std.record.get_or "cover" [] r2,
        date = std.record.get_or "date" [] r1 @ std.record.get_or "date" [] r2,
        datetime = std.record.get_or "datetime" [] r1 @ std.record.get_or "datetime" [] r2,
        fan = std.record.get_or "fan" [] r1 @ std.record.get_or "fan" [] r2,
        light = std.record.get_or "light" [] r1 @ std.record.get_or "light" [] r2,
        notify = std.record.get_or "notify" [] r1 @ std.record.get_or "notify" [] r2,
        number = std.record.get_or "number" [] r1 @ std.record.get_or "number" [] r2,
        scene = std.record.get_or "scene" [] r1 @ std.record.get_or "scene" [] r2,
        select = std.record.get_or "select" [] r1 @ std.record.get_or "select" [] r2,
        sensor = std.record.get_or "sensor" [] r1 @ std.record.get_or "sensor" [] r2,
        switch = std.record.get_or "switch" [] r1 @ std.record.get_or "switch" [] r2,
        text = std.record.get_or "text" [] r1 @ std.record.get_or "text" [] r2,
        time = std.record.get_or "time" [] r1 @ std.record.get_or "time" [] r2,
        weather = std.record.get_or "weather" [] r1 @ std.record.get_or "weather" [] r2,
      }
      |> std.record.filter (fun k v => v != [])
    in std.array.reduce_left f
}
in

# The names of generated entities have a special form, to
# distinguish them from automatically or manually created entities.
let GeneratedEntityName = std.contract.from_predicate (std.string.is_match "^//") in

let Entity = { function, name | GeneratedEntityName, .. } in

# Entities have a location-qualified name. We track as an input the
# ETS function they were generated from.
let base_entity | Entity = {
  function | not_exported,
  name
    | GeneratedEntityName
    | default
    = "//%{function.location}/%{function.name}",
}
in

# Filter through the list of functions in the ETS configuration and
# pass the matches to an entity construction function. In this
# variant, the entity construction function is allowed to return
# multiple entities.
let select_flatten
  | (Dyn -> Bool) -> (Dyn -> Array Entity) -> Array Entity
  = fun pred mk =>
    cfg.functions
    |> std.array.filter pred
    |> std.array.map (fun f => mk f |> std.array.map (fun r => r & base_entity & { function = f }))
    |> std.array.flatten
    |> std.array.map (std.record.filter (fun _ v => v != null))
    # XXX Workaround https://github.com/nickel-lang/nickel/issues/2633
    |> std.array.map (fun r => r & base_entity & { function = r.function })
      | std.array.NonEmpty
in

# Filter through the list of functions in the ETS configuration and
# pass the matches to an entity construction function.
let select
  | (Dyn -> Bool) -> (Dyn -> Entity) -> Array Entity
  = fun pred mk => select_flatten pred (fun f => [mk f])
in

knx.merge [
  # Lights
  {
    light =
      std.array.flatten [
        select
          (knx.type_is "dimmable light")
          (fun f =>
            {
              address = f.group_addresses.Switching,
              state_address = std.record.get_or "Status" null f.group_addresses,
              brightness_address = f.group_addresses."dimming value",
              brightness_state_address = std.record.get_or "Value" null f.group_addresses,
            }
          ),
        select
          (knx.type_is "switchable light")
          (fun f =>
            {
              address = f.group_addresses.Switching,
              state_address = std.record.get_or "Status" null f.group_addresses,
            }
          ),
      ],

    # Central functions don't have a state address, so buttons are the
    # better abstraction than lights. They only turn off.
    button =
      std.array.flatten [
        select
          (knx.and (knx.type_is "dimmable light") (knx.name_matches "^All "))
          (fun f =>
            {
              address = f.group_addresses.Switching,
              payload = 0,
            }
          ),
        select
          (knx.and (knx.type_is "switchable light") (knx.name_matches "^All "))
          (fun f =>
            {
              address = f.group_addresses.Switching,
              payload = 0,
            }
          ),
      ],
  },

  # Rollers
  {
    cover =
      select
        (knx.and (knx.type_is "sun protection") (knx.name_contains "roller"))
        (fun f =>
          {
            move_long_address = f.group_addresses.Movement,
            move_short_address = f.group_addresses."Step/Stop",
            position_address = f.group_addresses."blinds position",
            # Provisions should be considered near instantanous.
            travelling_time_down = if std.string.contains "(provision)" f.name then 1 else rollers_travelling_time,
            travelling_time_up = if std.string.contains "(provision)" f.name then 1 else rollers_travelling_time,
            device_class = "shade",
          }
        ),
  },

  # Blinds
  {
    cover =
      select
        (knx.and (knx.type_is "sun protection") (knx.name_contains "blind"))
        (fun f =>
          {
            move_long_address = f.group_addresses.Movement,
            move_short_address = f.group_addresses."Step/Stop",
            position_address = f.group_addresses."blinds position",
            angle_address = f.group_addresses."slat position",
            device_class = "blind",
          }
        ),
  },

  # Nets
  {
    cover =
      select
        (knx.name_contains "net")
        (fun f =>
          {
            move_long_address = f.group_addresses.Movement,
            move_short_address = f.group_addresses."Step/Stop",
            position_address = f.group_addresses.Position,
          }
        ),
  },

  # Climate control mode
  {
    select =
      select_flatten
        (knx.name_is "Heating/Cooling")
        (fun f =>
          [
            {
              name = "//HVAC heat cool",
              address = f.group_addresses.Mode,
              payload_length = 0,
              options = [
                { option = "Heat", payload = 1 },
                { option = "Cool", payload = 0 },
              ],
            },
          ]
        ),
  },

  # Domestic hot water
  {
    switch =
      select
        (knx.name_is "Domestic hot water")
        (fun f =>
          {
            name = "//Domestic hot water",
            address = f.group_addresses.Switching,
          }
        ),
  },

  # Floor heating
  {
    climate =
      select
        (knx.name_is "Floor heating")
        (fun f =>
          {
            temperature_address = f.group_addresses."Current temperature",
            target_temperature_address = f.group_addresses."Setpoint temperature",
            target_temperature_state_address = f.group_addresses."Setpoint temperature status",
            on_off_address = f.group_addresses.Switching,
            on_off_state_address = f.group_addresses.Status,
          }
        ),
  },

  # Casement windows
  {
    binary_sensor =
      select
        (knx.name_contains "casement window")
        (fun f =>
          {
            name = "//%{f.location}/%{f.name}/Contact",
            state_address = f.group_addresses.Status,
            device_class = "window",
          }
        ),
  },

  # Doors
  {
    binary_sensor =
      select
        (knx.name_matches "^door")
        (fun f =>
          {
            name = "//%{f.location}/%{f.name}/Contact",
            state_address = f.group_addresses.Status,
            device_class = "door",
          }
        ),
  },

  # Motorized windows
  {
    binary_sensor =
      select
        (knx.name_contains "motorized window")
        (fun f =>
          {
            name = "//%{f.location}/%{f.name}/Contact",
            state_address = f.group_addresses.Status,
            device_class = "window",
          }
        ),
    cover =
      select
        (knx.name_contains "motorized window")
        (fun f =>
          {
            move_long_address = f.group_addresses.Movement,
            move_short_address = f.group_addresses."Step/Stop",
            position_address = f.group_addresses."Position",
            device_class = "window",
          }
        ),
  },

  # Sliding windows
  {
    binary_sensor =
      select
        (knx.name_matches "^sliding windows")
        (fun f =>
          {
            name = "//%{f.location}/%{f.name}/Contact",
            state_address = f.group_addresses.Status,
            device_class = "window",
          }
        ),
    switch =
      select
        (knx.and (knx.name_is "All sliding windows") (knx.location_type_is "room"))
        (fun f =>
          {
            name = "//%{f.location}/Sliding windows/Lock",
            address = f.group_addresses.Lock,
            state_address = std.record.get_or "Lock status" null f.group_addresses,
          }
        ),
  },

  # Air conditioning
  {
    climate =
      select
        (knx.name_contains "air conditioning")
        (fun f =>
          {
            temperature_address = f.group_addresses."Current temperature",
            target_temperature_address = f.group_addresses."Setpoint temperature",
            target_temperature_state_address = f.group_addresses."Setpoint temperature status",
            on_off_address = f.group_addresses.Switching,
            on_off_state_address = f.group_addresses.Status,
            fan_speed_address = f.group_addresses."Fan speed",
            fan_speed_state_address = f.group_addresses."Fan speed status",
            fan_zero_mode = "auto",
            default_controller_mode = "cool",
          }
        ),
  },

  # Towel heaters
  {
    switch =
      select
        (knx.name_contains "towel heater")
        (fun f =>
          {
            address = f.group_addresses.Switching,
            state_address = std.record.get_or "Status" null f.group_addresses,
          }
        ),
  },

  # Switchable sockets
  {
    switch =
      select
        (knx.name_contains "switchable socket")
        (fun f =>
          {
            address = f.group_addresses.Switching,
            state_address = f.group_addresses.Status,
          }
        ),
  },

  # Appliances that can be controlled by a relay
  {
    switch =
      select
        (knx.name_is "Appliances")
        (fun f =>
          {
            address = f.group_addresses.Switching,
            state_address = std.record.get_or "Status" null f.group_addresses,
          }
        ),
  },

  # Alarm
  {
    switch =
      select_flatten
        (knx.name_is "Alarm")
        (fun f =>
          [
            {
              name = "//Intrusion alarm/Arm",
              address = f.group_addresses.Arm,
              state_address = f.group_addresses."Arm status",
            },
            {
              name = "//Intrusion alarm/Partial arm",
              address = f.group_addresses."Partial arm",
              state_address = f.group_addresses."Partial arm status",
            },
            {
              name = "//Intrusion alarm/Disarm",
              address = f.group_addresses.Disarm,
              state_address = f.group_addresses."Disarm status",
            },
          ]
        ),
    binary_sensor =
      select_flatten
        (knx.name_is "Alarm")
        (fun f =>
          [
            {
              name = "//Intrusion alarm",
              state_address = f.group_addresses."Intrusion alarm status",
              device_class = "problem",
            },
            {
              name = "//Fire alarm",
              state_address = f.group_addresses."Fire alarm status",
              device_class = "problem",
            },
            {
              name = "//Panic alarm",
              state_address = f.group_addresses."Panic alarm status",
              device_class = "problem",
            },
          ]
        ),
  },

  # BMS
  {
    switch =
      select
        (knx.name_is "BMS")
        (fun f =>
          {
            name = "//BMS",
            address = f.group_addresses.Switching
          }
        ),
    binary_sensor =
      select
        (knx.name_is "BMS")
        (fun f =>
          {
            name = "//BMS Alarm",
            state_address = f.group_addresses."Alarm status",
            device_class = "problem",
          }
        ),
  },

  # UPS
  {
    binary_sensor =
      select_flatten
        (knx.name_is "UPS")
        (fun f =>
          [
            {
              name = "//UPS battery",
              state_address = f.group_addresses."Battery status",
              device_class = "battery",
            },
            {
              name = "//UPS alarm",
              state_address = f.group_addresses."Alarm status",
              device_class = "problem",
            },
          ]
        ),
  },

  # Motion detection
  {
    binary_sensor =
      select
        (knx.name_contains "motion detection")
        (fun f =>
          {
            state_address = f.group_addresses.Status,
            device_class = "motion",
          }
        ),
  },

  # Water leak detection
  {
    binary_sensor =
      select
        (knx.name_contains "water leak detection")
        (fun f =>
          {
            state_address = f.group_addresses.Status,
            device_class = "problem",
          }
        ),
  },

  # Ventilation
  {
    switch =
      select
        (knx.name_is "Ventilation")
        (fun f =>
          {
            address = f.group_addresses.Switching,
            state_address = f.group_addresses.Status,
          }
        ),
  },

  # Garage door
  {
    switch =
      select
        (knx.and (knx.location_is "Garage") (knx.name_is "Door"))
        (fun f =>
          {
            address = f.group_addresses.Switching,
            state_address = f.group_addresses.Status,
          }
        ),
  },

  # Garage gate
  {
    button =
      select_flatten
        (knx.and (knx.location_is "Garage") (knx.name_is "Gate"))
        (fun f => # Can't sense the state so have two buttons instead of a switch.
          [
            {
              name = "//Garage/Gate/CLOSED",
              address = f.group_addresses.Switching,
              payload = 0,
            },
            {
              name = "//Garage/Gate/OPEN",
              address = f.group_addresses.Switching,
              payload = 1,
            },
          ]
        ),
  },

  # Weather station
  {
    weather =
      select
        (knx.name_is "Weather")
        (fun f =>
          {
            name = "//Weather station",
            address_temperature = f.group_addresses.Temp,
            address_wind_speed = f.group_addresses.Wind,
            address_rain_alarm = f.group_addresses.Rain,
          }
        ),
  },

  # Irrigation
  {
    switch =
      select
        (knx.name_contains "Irrigation")
        (fun f =>
          {
            address = f.group_addresses.Switching,
            state_address = f.group_addresses.Status,
          }
        ),
  },
]
