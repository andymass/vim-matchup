RANDOM := $(shell bash -c 'echo $$RANDOM')
COVER = covimerage -q run --append --no-report \
       --data-file $(CURDIR)/cov.tmp/_$(RANDOM)_coverage_covimerage_$@ \
       --source $(CURDIR)/../../autoload \
       --source $(CURDIR)/../../plugin
MYVIM ?= nvim --headless
MAKEFLAGS += --no-print-directory
VENV = . env/bin/activate; 

TESTS := $(wildcard test-*)

.PHONY: test $(TESTS)

test: $(TESTS)

sysinfo:
	@echo "**** SYSTEM INFORMATION ****"
	@-git log -1
	@-$(MYVIM) --version
	@echo "**** SYSTEM INFORMATION ****"

$(TESTS): env
	$(VENV) mkdir -p cov.tmp
	$(VENV) MYVIM="$(COVER) $(MYVIM)" $(MAKE) -C $@

coverage: coverage.xml

cov.tmp/coverage_covimerage: $(wildcard cov.tmp/_*)
	$(VENV) coverage combine $^

coverage.xml: env cov.tmp/coverage_covimerage
	$(VENV) coverage report -m
	$(VENV) coverage html
	$(VENV) coverage xml

env: env/pyvenv.cfg

env/pyvenv.cfg:
	python3 -m venv env
	$(VENV) pip install -r requirements.txt

ifndef MAKECMDGOALS
test: sysinfo
$(TESTS): sysinfo
endif
