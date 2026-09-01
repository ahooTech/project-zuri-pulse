output "example_names" {
  description = "Example standardized resource names."
  value = {
    for name, module_output in module.example_names :
    name => module_output.name
  }
}