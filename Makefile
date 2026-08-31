VARIANT ?= winner-4096
RUN_ID ?= run-001

.PHONY: validate render preflight model-cache deploy prepare-run smoke benchmark

validate:
	./scripts/validate-repository.sh

render:
	./scripts/render.sh $(VARIANT)

preflight:
	./scripts/preflight.sh

model-cache:
	./scripts/prepare-model-cache.sh

deploy:
	./scripts/deploy.sh $(VARIANT)

prepare-run:
	./scripts/prepare-run.sh $(VARIANT)

smoke:
	./scripts/smoke.sh

benchmark:
	./scripts/run-benchmark.sh $(VARIANT) $(RUN_ID)
