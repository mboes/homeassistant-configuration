all: knx.yaml

%.yaml: %.yaml.ncl
	nickel export -fyaml -o $@ $<

%.yaml: %.yaml.py
	python3 $< -o $@

knx.yaml: knx-model.yaml

knx-model.yaml: 0.xml
