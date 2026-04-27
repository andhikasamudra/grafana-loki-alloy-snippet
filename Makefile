SHELL := /bin/sh

ALLOY_BIN := alloy-linux-amd64
ALLOY_ZIP := $(ALLOY_BIN).zip
ALLOY_URL := https://github.com/grafana/alloy/releases/download/v1.16.0/$(ALLOY_ZIP)

ENV_FILE := env.sh
PID_FILE := .alloy.pid
CONFIG := alloy.hcl
LOG_FILE := alloy.log

.PHONY: run stop status clean download check-tools

run: check-tools download
        @set -eu; \
        if [ ! -f "$(ENV_FILE)" ]; then \
                echo "ERROR: Missing $(ENV_FILE)"; \
                exit 1; \
        fi; \
        if [ -f "$(PID_FILE)" ]; then \
                PID=$$(cat "$(PID_FILE)"); \
                if kill -0 $$PID 2>/dev/null; then \
                        echo "Alloy already running with PID $$PID"; \
                        exit 0; \
                else \
                        echo "Stale PID file found. Cleaning up..."; \
                        rm -f "$(PID_FILE)"; \
                fi; \
        fi; \
        echo "Starting Alloy..."; \
        nohup sh -c '. ./$(ENV_FILE) && exec ./$(ALLOY_BIN) run "$(CONFIG)"' \
                > "$(LOG_FILE)" 2>&1 & echo $$! > "$(PID_FILE)"; \
        sleep 1; \
        PID=$$(cat "$(PID_FILE)"); \
        if kill -0 $$PID 2>/dev/null; then \
                echo "Started successfully with PID $$PID"; \
                echo "Logs: $(LOG_FILE)"; \
        else \
                echo "ERROR: Failed to start Alloy. Check logs."; \
                exit 1; \
        fi

stop:
        @set -eu; \
        if [ ! -f "$(PID_FILE)" ]; then \
                echo "Alloy is not running"; \
                exit 0; \
        fi; \
        PID=$$(cat "$(PID_FILE)"); \
        if kill -0 $$PID 2>/dev/null; then \
                echo "Stopping Alloy (PID $$PID)..."; \
                kill $$PID; \
                for i in 1 2 3 4 5; do \
                        if kill -0 $$PID 2>/dev/null; then sleep 1; else break; fi; \
                done; \
                if kill -0 $$PID 2>/dev/null; then \
                        echo "Force killing process..."; \
                        kill -9 $$PID; \
                fi; \
                echo "Stopped."; \
        else \
                echo "Process not running (stale PID)"; \
        fi; \
        rm -f "$(PID_FILE)"

status:
        @set -eu; \
        if [ -f "$(PID_FILE)" ]; then \
                PID=$$(cat "$(PID_FILE)"); \
                if kill -0 $$PID 2>/dev/null; then \
                        echo "Alloy is running (PID $$PID)"; \
                else \
                        echo "PID file exists but process is not running"; \
                fi; \
        else \
                echo "Alloy is not running"; \
        fi

download:
        @set -eu; \
        if [ -x "$(ALLOY_BIN)" ]; then \
                echo "Alloy binary already exists"; \
                exit 0; \
        fi; \
        echo "Downloading Alloy..."; \
        if command -v curl >/dev/null 2>&1; then \
                curl -fL -o "$(ALLOY_ZIP)" "$(ALLOY_URL)"; \
        elif command -v wget >/dev/null 2>&1; then \
                wget -O "$(ALLOY_ZIP)" "$(ALLOY_URL)"; \
        else \
                echo "ERROR: Neither curl nor wget is installed"; \
                exit 1; \
        fi; \
        if command -v unzip >/dev/null 2>&1; then \
                unzip -o "$(ALLOY_ZIP)"; \
        else \
                echo "ERROR: unzip is required"; \
                exit 1; \
        fi; \
        chmod +x "$(ALLOY_BIN)"; \
        echo "Download complete"

check-tools:
        @set -eu; \
        for cmd in sh nohup kill; do \
                command -v $$cmd >/dev/null 2>&1 || { \
                        echo "ERROR: $$cmd is required but not installed"; \
                        exit 1; \
                }; \
        done

clean:
        @echo "Cleaning up..."
        @rm -f "$(PID_FILE)" "$(LOG_FILE)" "$(ALLOY_ZIP)"
