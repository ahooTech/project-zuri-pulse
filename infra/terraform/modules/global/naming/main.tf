locals {
  cloud_abbreviations = {
    aws   = "aws"
    azure = "az"
    gcp   = "gcp"
  }

  layer_abbreviations = {
    networking  = "net"
    security    = "sec"
    kubernetes  = "k8s"
    databases   = "db"
    monitoring  = "mon"
    application = "app"
    global      = "global"
  }

  name_parts = concat(
    [
      var.project,
      var.environment,
      local.cloud_abbreviations[var.cloud],
      local.layer_abbreviations[var.layer]
    ],
    var.resource_type == "" ? [] : [var.resource_type],
    var.suffix == "" ? [] : [var.suffix]
  )

  raw_name = join("-", local.name_parts)

  lowered = lower(local.raw_name)

  normalized = replace(
    local.lowered,
    "/[^a-z0-9-]/",
    "-"
  )

  truncated = substr(
    local.normalized,
    0,
    var.max_length
  )

  final = trimsuffix(local.truncated, "-")
}