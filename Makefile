all: knx.yaml

knx-model.yaml: 0.xml scripts/knx-model.py schemas/knx-model.ncl
	./scripts/knx-model.py $< -o $@
	./schemas/nickel-validate knx-model.ncl $@

knx.yaml: knx-model.yaml scripts/knx.ncl
	./scripts/nickel-yaml knx.ncl $< -o $@
