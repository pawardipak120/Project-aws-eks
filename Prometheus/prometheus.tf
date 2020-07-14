provider "kubernetes" {  
	config_context_cluster   = ""
	}

resource "kubernetes_service" "prometheus-svc" {
	metadata {
		name = "prometheus-svc"
	}
	spec {
		selector = {
		  app = "${kubernetes_deployment.prom-deploy.metadata.0.labels.app}"
		}
		
		port {
			
			port        = 9090
			target_port = 9090
		}
			type = "LoadBalancer"
	}
}

resource "kubernetes_deployment" "prom-deploy" {
	metadata {
		name = "prom-deploy"
		labels = {
			app = "prom"
		}
	}
	  

	spec { 
		replicas = 1
		selector {
			match_labels = {
				app = "prom"
			} 
		}
		template {
			metadata {
				labels = {
					app = "prom"
				}
			}
			spec {
				container {
					image = "sunny078/prometheus:v1"
					name  = "prom-con"							
				}
			}
		}
	}
}
