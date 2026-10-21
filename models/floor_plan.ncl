let schema = {
  ancillary_rooms
  | { _ : Array String }
  | doc "Map of locations to related locations",
}
in

let cfg = import "floor_plan.yaml"
in

cfg & schema
