NCL_FILES := $(shell find . -name '*.yaml.ncl')
YAML_FILES := $(NCL_FILES:.yaml.ncl=.yaml)

all: $(YAML_FILES)

%.yaml: %.yaml.ncl
	nickel export -fyaml -o $@ $<

%.yaml: %.yaml.py
	python3 $< -o $@

knx-model.yaml: 0.xml

knx.yaml: knx-model.yaml

