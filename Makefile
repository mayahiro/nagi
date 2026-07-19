.PHONY: check check-submodules

check: check-submodules

check-submodules:
	sh scripts/check-submodules.sh
