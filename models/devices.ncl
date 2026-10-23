let Device = {
  name,
  entities | optional,
  location | optional,
}
in

let schema = {
  air_quality_sensors | Array Device,
  kitchen_appliances | Array Device,
  lock_buttons | Array Device,
  printers | Array Device,
}
in

let cfg = import "devices.yaml"
in

cfg & schema
