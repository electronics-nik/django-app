.PHONY: help version clean commit lint test coverage
.DEFAULT_GOAL := help

SHELL := /bin/bash
VENV_PREFIX ?= uv run

VERSION := $(shell $(VENV_PREFIX) cz version -p)

# Docker image related:
MODULE := src

# Macro to print help
# Don't leave space after ## (Eg. ##***CI/CD-only***) to prevent help from picking up
define PRINT_HELP_PYSCRIPT
import re, sys

print("\nPossible commands:")
for line in sys.stdin:
	match = re.match(r'^([a-zA-Z0-9_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("  %-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:  ## Print this help message
	@echo src version $(VERSION)
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

version:  ## Print version
	@echo $(VERSION)

dry-clean:  ## Dry Run: Delete files defined in .gitignore
	@echo "Files to delete:"
	@git clean -Xdf --dry-run

check-clean: dry-clean
	@echo -n "Are you sure you want to clean and keep only files fetched from git? [y/N] " && read ans && [ $${ans:-N} = y ]

clean:  ## Delete files defined in .gitignore
	git clean -Xdf

install-uv:  ## Install uv
	@if ! command -v uv >/dev/null 2>&1; then \
			echo "uv not found, installing..."; \
			brew install uv; \
	else \
			echo "uv is already installed."; \
	fi

init-venv:  ## Install python libraries defined in pyproject.toml
	uv sync

setup-pre-commit:  ## Install pre-commit hooks
	$(VENV_PREFIX) pre-commit install
	$(VENV_PREFIX) pre-commit autoupdate

init-dev: install-uv init-venv setup-pre-commit

init-cicd: clean install-uv init-venv

commit:
	$(VENV_PREFIX) cz commit

lint: ruff pylint commit-check

ruff:
	$(VENV_PREFIX) ruff check .

pylint:
	$(VENV_PREFIX) pylint src
	$(VENV_PREFIX) pylint tests

test:
	$(VENV_PREFIX) pytest tests/unit -n 4

test-durations:
	$(VENV_PREFIX) pytest tests/unit --store-durations

coverage:
	$(VENV_PREFIX) pytest --cov-report term-missing:skip-covered --cov-report xml --cov

commit-check:
	@echo Skip if NO_COMMIT_FOUND is raised, return value shall be 0
	git fetch origin
	$(VENV_PREFIX) cz check --rev-range origin/master.. || if [ $$? != 3 ]; then exit 1; fi

bump-version-local:
	git config user.email "developer@local"
	git config user.name "Developer Local"
	$(VENV_PREFIX) cz bump --yes --no-verify --changelog
	git push origin master
	git push origin --tags
