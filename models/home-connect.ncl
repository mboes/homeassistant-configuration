# Describe Home Connect devices

let schema = {
  alarm_entities | Array String,
}
in

let cfg = import "home-connect.yaml"
in

cfg & schema
