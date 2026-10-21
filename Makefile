NCL_FILES := $(shell find . -name '*.yaml.ncl')
NCL_LIB_FILES := $(filter-out %.yaml.ncl,$(shell find . -name '*.ncl'))
YAML_FILES := $(NCL_FILES:.yaml.ncl=.yaml)

MODEL_YAML_FILES := $(filter ./models/%.yaml,$(YAML_FILES))
INTEGRATION_YAML_FILES := $(filter ./integrations/%.yaml,$(YAML_FILES))
DASHBOARD_YAML_FILES := $(filter ./dashboards/%.yaml,$(YAML_FILES))
PACKAGE_YAML_FILES := $(filter ./packages/%.yaml,$(YAML_FILES))

all: $(YAML_FILES)

%.yaml: %.yaml.ncl $(NCL_LIB_FILES)
	nickel export -fyaml -o $@ $<
	@# Workaround Norway problem. See https://github.com/nickel-lang/nickel/issues/2481
	@sed -i -E 's/: ([Oo]n|[Oo]ff)$$/: "\1"/g' $@

%.yaml: %.yaml.py
	python3 $< -o $@

models/knx.yaml: 0.xml

$(INTEGRATION_YAML_FILES): $(MODEL_YAML_FILES)

$(DASHBOARD_YAML_FILES): $(INTEGRATION_YAML_FILES)

$(PACKAGE_YAML_FILES): $(INTEGRATION_YAML_FILES)
