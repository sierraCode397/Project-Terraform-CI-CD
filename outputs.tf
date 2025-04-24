output "gitlab_instance_info" {
  description = "GitLab instance connection details"
  value       = module.ec2-gitlab.instance_info["Gitlab"]
}

output "jenkins_instance_info" {
  description = "Jenkins instance connection details"
  value       = module.ec2-jenkins.instance_info["Jenkins"]
}
