provider "kubernetes" {  
		config_context_cluster   = ""
	}

resource "kubernetes_service" "grafana-svc" {
	metadata {
		name = "grafana-svc"
	}
	spec {
		selector = {
			app = "${kubernetes_deployment.graf-deploy.metadata.0.labels.app}"
		}
		port {
			
			port        = 3000
			target_port = 3000
		}
			type = "LoadBalancer"
	}	
}

resource "kubernetes_deployment" "graf-deploy" {
	metadata {
		name = "graf-deploy"
		labels = {
			app = "graf"
		}
	}
	 
	spec { 
		replicas = 1
		selector {
			match_labels = {
				app = "graf"
			}
		}
		template {
			metadata {
				labels = {
					app = "graf"
				}
			}
			spec {
				container {
					image = "sunny078/grafana:v1"
					name  = "graf-con"	
				}
			}
		}	
	}
}
