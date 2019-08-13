all: report

OUT_DIR=./out/
TESTS_DIR=./tests
RUNNERS_DIR=./runners

clean:
	@echo removing $(OUT_DIR)
	@rm -rf $(OUT_DIR)

init:
ifneq (,$(wildcard $(OUT_DIR)/*))
	@echo -e "\n!!! WARNING !!!\nThe output directory is not empty\n"
endif
	@mkdir -p $(addprefix $(OUT_DIR), $(RUNNERS))

define parse_param
	$(eval $(1):=$(shell grep -m 1 :$1: $2 | cut -d' ' -f2-))
endef

# $(1) - runner name
# $(2) - test
define runner_gen

$(1)_$(2): info init
	@echo Testing $(2) with $(1)
	$(call parse_param,name,$(TESTS_DIR)/$(2))
	$(call parse_param,should_fail,$(TESTS_DIR)/$(2))
	$(call parse_param,tags,$(TESTS_DIR)/$(2))
	@echo "NAME: $(name)" > $(OUT_DIR)/$(1)/$(2).log
	@echo "TAGS: $(tags)" >> $(OUT_DIR)/$(1)/$(2).log
	@echo "SHOULD_FAIL: $(should_fail)" >> $(OUT_DIR)/$(1)/$(2).log
	$(eval TMPDIR:=$(shell mktemp -d))
	$(eval RUNNER_PATH:=$(abspath $(RUNNERS_DIR)/$(1)))
	$(eval TEST_PATH:=$(abspath $(TESTS_DIR)/$(2)))
	$(eval RC:=$(shell cd $(TMPDIR) && $(RUNNER_PATH) $(TEST_PATH) >> $(1).log 2>&1; echo $$?))
	@echo "RC: $(RC)" >> $(OUT_DIR)/$(1)/$(2).log
	@cat $(TMPDIR)/$(1).log >> $(OUT_DIR)/$(1)/$(2).log
	@rm -r $(TMPDIR)

tests: $(1)_$(2)
endef

RUNNERS := $(wildcard $(RUNNERS_DIR)/*)
RUNNERS := $(RUNNERS:$(RUNNERS_DIR)/%=%)
TESTS := $(wildcard $(TESTS_DIR)/*.sv)
TESTS := $(TESTS:$(TESTS_DIR)/%=%)

info:
	@echo "Found the following runners: $(RUNNERS)"
	@echo "Found the following tests: $(TESTS)"

tests:

report: init tests
	@echo "Generating report"
	@./tools/sv-report

$(foreach r, $(RUNNERS),$(foreach t, $(TESTS),$(eval $(call runner_gen,$(r),$(t)))))
