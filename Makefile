all: knx.yaml

knx-model.yaml: 0.xml scripts/knx-model.py
	./scripts/knx-model.py $< -o $@

knx.yaml: knx-model.yaml scripts/knx.ncl
	./scripts/nickel-yaml knx.ncl $< -o $@
