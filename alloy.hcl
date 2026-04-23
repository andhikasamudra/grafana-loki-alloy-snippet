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
      __path__ = "/data/logs/service_name/service_name.log",
      group    = "group_name",
      service  = "service_name",
    },
  ]
}

loki.source.file "services" {
  targets    = local.file_match.services.targets
  forward_to = [loki.relabel.log_parser.receiver]
}

loki.process "log_parser" {

  stage.regex {
    expression = ".*/data/logs/(?P<service>[^/]+)/"
  }

  stage.labels {
    values = {
      service = "service",
    }
  }

  stage.regex {
    expression = ".*\\s(?P<level>INFO|ERROR|WARN|DEBUG)\\s+(?P<prefix_func>[^\\s]+)(?:\\.\\d+)?\\s+-\\s+(?P<data>.*)"
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