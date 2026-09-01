output "tags_by_environment" {
  description = "Standard tags generated for each environment."
  value = {
    for environment, module_output in module.standard_tags :
    environment => module_output.tags
  }
}