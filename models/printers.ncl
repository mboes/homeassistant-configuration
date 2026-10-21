let schema = {
  printers | Array String
}
in

let cfg = import "printers.yaml"
in

cfg & schema
