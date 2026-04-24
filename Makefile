ALLOY_BIN=alloy-linux-amd64
ALLOY_URL=https://github.com/grafana/alloy/releases/download/v1.16.0/alloy-linux-amd64.zip

ENV_FILE=env.sh
PID_FILE=.alloy.pid
CONFIG=alloy.hcl
LOG_FILE=alloy.log

run:
        @if [ ! -x "$(ALLOY_BIN)" ]; then \
                echo "Grafana Alloy not found. Downloading..."; \
                wget $(ALLOY_URL) || { \
                        echo "Failed to download Alloy"; \
                        exit 1; \
                }; \
                unzip $(ALLOY_BIN).zip && chmod u+x $(ALLOY_BIN); \
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

        @echo "Starting Alloy with env from $(ENV_FILE)..."
        @nohup sh -c '. ./$(ENV_FILE) && exec ./$(ALLOY_BIN) run "$(CONFIG)"' \
                > "$(LOG_FILE)" 2>&1 & echo $$! > "$(PID_FILE)"

        @echo "Started with PID $$(cat $(PID_FILE))"
        @echo "Logs: $(LOG_FILE)"


.PHONY: run stop

stop:
        @if [ ! -f $(PID_FILE) ]; then \
                echo "Alloy is not running (no PID file found)"; \
                exit 0; \
        fi; \
        PID=$$(cat $(PID_FILE)); \
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
        rm -f $(PID_FILE)