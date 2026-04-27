ALLOY_BIN := alloy-linux-amd64
ALLOY_ZIP := $(ALLOY_BIN).zip
ALLOY_URL := https://github.com/grafana/alloy/releases/download/v1.16.0/$(ALLOY_ZIP)

ENV_FILE := env.sh
PID_FILE := .alloy.pid
CONFIG := alloy.hcl
LOG_FILE := alloy.log

.PHONY: run stop status clean

run:
        @if [ ! -x "$(ALLOY_BIN)" ]; then \
                echo "Grafana Alloy not found. Downloading..."; \
                wget -O $(ALLOY_ZIP) $(ALLOY_URL) || { \
                        echo "Failed to download Alloy"; \
                        exit 1; \
                }; \
                unzip -o $(ALLOY_ZIP); \
                chmod u+x $(ALLOY_BIN); \
        fi

        @if [ ! -f "$(ENV_FILE)" ]; then \
                echo "Missing $(ENV_FILE)"; \
                exit 1; \
        fi

        @if [ -f "$(PID_FILE)" ]; then \
                PID=$$(cat "$(PID_FILE)"); \
                if kill -0 $$PID 2>/dev/null; then \
                        echo "Alloy already running with PID $$PID"; \
                        exit 0; \
                else \
                        echo "Stale PID file found. Cleaning up..."; \
                        rm -f "$(PID_FILE)"; \
                fi; \
        fi

        @echo "Starting Alloy..."
        @nohup sh -c '. ./$(ENV_FILE) && exec ./$(ALLOY_BIN) run "$(CONFIG)"' \
                > "$(LOG_FILE)" 2>&1 & echo $$! > "$(PID_FILE)"

        @echo "Started with PID $$(cat $(PID_FILE))"
        @echo "Logs: $(LOG_FILE)"

stop:
        @if [ ! -f "$(PID_FILE)" ]; then \
                echo "Alloy is not running (no PID file found)"; \
                exit 0; \
        fi; \
        PID=$$(cat "$(PID_FILE)"); \
        if kill -0 $$PID 2>/dev/null; then \
                echo "Stopping Alloy (PID $$PID)..."; \
                kill $$PID; \
                sleep 1; \
                if kill -0 $$PID 2>/dev/null; then \
                        echo "Process still running, forcing stop..."; \
                        kill -9 $$PID; \
                fi; \
                echo "Alloy stopped."; \
        else \
                echo "Process not running, cleaning up stale PID file."; \
        fi; \
        rm -f "$(PID_FILE)"

status:
        @if [ -f "$(PID_FILE)" ]; then \
                PID=$$(cat "$(PID_FILE)"); \
                if kill -0 $$PID 2>/dev/null; then \
                        echo "Alloy is running with PID $$PID"; \
                else \
                        echo "PID file exists but process is not running"; \
                fi; \
        else \
                echo "Alloy is not running"; \
        fi

clean:
        @echo "Cleaning up..."
        @rm -f $(PID_FILE) $(LOG_FILE)