logging {
  level = sys.env("LOG_LEVEL")
}

server {
  http_listen_address = "0.0.0.0:9080"
}

# ========================
# LOKI OUTPUT (SHARED)
# ========================

loki.write "default" {
  endpoint {
    url = sys.env("LOKI_URL")
  }

  # safer: hardcode or ensure env is valid
  batch_size = 102400
  batch_wait = "2s"
}

# ========================
# GLOBAL LABEL
# ========================

loki.relabel "global_labels" {
  rule {
    target_label = "env"
    replacement  = sys.env("ENV")
  }

  rule {
    target_label = "host"
    replacement  = sys.env("HOST")
  }

  forward_to = [loki.write.default.receiver]
}

# ========================
# SERVICE LIST
# ========================

local.file_match "risk_services" {
  path_targets = [
    {
      __path__ = "/data/logs/service-name/service-name.log",
      group    = "risk"
    }
  ]
}

# ========================
# PIPELINE ENTRY
# ========================

loki.source.file "risk_services" {
  targets    = local.file_match.risk_services.targets
  forward_to = [loki.process.extract_service.receiver]
}

# ========================
# SHARED SERVICE EXTRACTION
# ========================

loki.process "extract_service" {
  stage.regex {
    expression = "/data/logs/(?P<service>[^/]+)/"
  }

  forward_to = [loki.relabel.global_labels.receiver]
}