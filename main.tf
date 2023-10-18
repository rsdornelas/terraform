variable "gcp_credential" {
  type        = string
  sensitive   = true
  description = "GCP Access Key"

}

variable "hosts" {
  type        = list(string)
  default = ["srv.hosts.ca"]
}


locals {
  cloud_functions_file_list = [for f in fileset("${path.module}/project", "[^_]*.yaml") : yamldecode(file("${path.module}/project/${f}"))]
  
  cloud_functions_list = flatten ([
    for cloud_functions in local.cloud_functions_file_list : [
      for function in try(cloud_functions.mobility_cloud_functions_list,[]):{
        function_name = lower(function.name)

  }
    ]])
}

resource "google_monitoring_uptime_check_config" "http-check" {
  for_each = { for index,code in local.cloud_functions_list: index  => code}
  display_name = "glb-http-uptime-check-${each.value.function_name}"
  timeout = "60s"

  http_check {
    path = "/${each.value.function_name}"
    port = "80"
    # use_ssl = true
    # validate_ssl = true
        
    accepted_response_status_codes {
            status_value = 200
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "projectID"
      host = var.hosts[0]

    }
  }
}


