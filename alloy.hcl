logging {
  level = "debug"
}

loki.write "default" {
  endpoint {
    url = sys.env("LOKI_URL")
  }
}

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

// service list
local.file_match "services" {
  path_targets = [
    {
      __path__ = "/data/logs/service-name/service-name.log",
      group    = "service-group",
      service  = "service-name",
    },
  ]
}

loki.source.file "services" {
  targets    = local.file_match.services.targets
  forward_to = [loki.process.log_parser.receiver]
}

loki.process "log_parser" {
  stage.multiline {
    firstline = "^\\d{2}-\\d{2}-\\d{4} \\d{2}:\\d{2}:\\d{2}\\.\\d{3}"
    max_wait_time = "2s"
  }

  stage.regex {
    expression = "^(?P<ts>\\d{2}-\\d{2}-\\d{4} \\d{2}:\\d{2}:\\d{2}\\.\\d{3})\\s+\\[.*\\]\\s+\\[.*\\]\\s+\\[.*\\]\\s+(?P<level>INFO|ERROR|WARN|DEBUG)\\s+(?P<prefix_func>[^\\s]+)\\s+-\\s+(?P<data>[\\s\\S]*)"
  }

  stage.timestamp {
    source = "ts"
    format = "02-01-2006 15:04:05.000"
    location = "Asia/Jakarta"
  }

  stage.labels {
    values = {
      level = "level",
    }
  }

  stage.regex {
    expression = "(?P<function>[a-zA-Z0-9_]+(ServiceImpl|Util|Handler|Aspect)\\.[a-zA-Z0-9_]+)"
  }

  stage.labels {
    values = {
      function = "function",
    }
  }

  stage.output {
    source = "data"
  }

  forward_to = [loki.relabel.global_labels.receiver]
}
