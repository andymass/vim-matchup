COV ?= covimerage run --append --no-report \
       --data-file $(CURDIR)/.coverage_covimerage \
       --source $(CURDIR)/../../autoload \
       --source $(CURDIR)/../../plugin
MYVIM ?= nvim --headless
MAKEFLAGS+=--no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test $(TESTS)

test: $(TESTS)

sysinfo:
	@echo "**** SYSTEM INFORMATION ****"
	@-git log -1
	@-$(MYVIM) --version
	@echo "**** SYSTEM INFORMATION ****"

$(TESTS): env
	@. env/bin/activate
	MYVIM="$(COV) $(MYVIM)" $(MAKE) -C $@

coverage: coverage.xml

coverage.xml: env .coverage_covimerage
	. env/bin/activate
	coverage report -m
	coverage html
	coverage xml

env: env/pyvenv.cfg

env/pyvenv.cfg:
	python3 -m venv env
	. env/bin/activate
	pip install setuptools wheel
	pip install "click<8.0.0" coverage==4.5.4 covimerage==0.2.1
