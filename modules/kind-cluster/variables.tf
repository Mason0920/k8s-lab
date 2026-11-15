variable "cluster_name" {
  description = "kind 클러스터 이름 (컨텍스트는 kind-<이름>)"
  type        = string
}

variable "node_image" {
  description = "노드 이미지. 회사 EKS 버전과 맞춘다."
  type        = string
}

variable "worker_count" {
  description = "워커 노드 수"
  type        = number
  default     = 1
}

variable "kubeconfig_path" {
  description = "이 클러스터 전용 kubeconfig 경로 (회사 ~/.kube/config 와 분리)"
  type        = string
}
