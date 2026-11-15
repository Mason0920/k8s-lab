# k8s-lab

Terragrunt와 Istio(Ambient)를 로컬 kind 클러스터에서 학습하고, 회사 EKS에 적용할 방안을 찾기 위한 실습 저장소.
과정은 블로그 https://thereisnotherway.tistory.com/ 에 연재한다.

## 기록 방식

| 폴더 | 내용 |
|---|---|
| `docs/notes/` | 학습 노트. `_template.md` 를 복사해 `YYYY-MM-DD-주제.md` 로 쓴다 |
| `docs/blog/` | 노트를 정리한 블로그 원고 |
| `private/` | 저장소에 올리지 않는 개인 메모 (.gitignore) |

## 구조

```
k8s-lab/
├── root.hcl                    # 공통 설정: backend(state 위치), provider 생성, 공통 inputs
├── modules/
│   └── kind-cluster/           # Terraform 모듈: kind 클러스터 1개
└── live/
    └── dev/
        ├── env.hcl             # dev 환경 값 (클러스터 이름, 노드 이미지, 워커 수)
        └── cluster/
            └── terragrunt.hcl  # unit: root.hcl include + 모듈 source + unit 전용 inputs
```

## 버전 (2026-11-15 확인)

| 도구 | 버전 | 비고 |
|---|---|---|
| kind | v0.33.0 | |
| 노드 이미지 | kindest/node:v1.34.11 | 회사 EKS 1.34 와 맞춤 |
| tehcyx/kind provider | ~> 0.13 (v0.13.0) | |
| Terragrunt | v1.2.2 | 0.x 시절 명령(`run-all`)과 다름. `run --all` 사용 |
| Terraform | v1.17.2 | HashiCorp 공식 tap 으로 설치 (root.hcl 에 terraform_binary 고정) |

---

# 1주차: Terragrunt 기본

**목표:** dev kind 클러스터를 Terragrunt 로 생성·확인·삭제하고, Terragrunt 가 해주는 일(backend/provider 생성, inputs 전달, state 분리)을 눈으로 확인한다.

**완료 기준:** `terragrunt run apply` 로 클러스터 생성 → `kubectl get nodes` 2대 Ready → `terragrunt run destroy` 로 깨끗이 삭제.

## 0. 준비

```bash
brew install kind kubectl terragrunt k9s
brew tap hashicorp/tap && brew install hashicorp/tap/terraform   # brew 기본 terraform 은 1.5.7 에 멈춰 있음
# 컨테이너 런타임 하나: OrbStack(권장, 가벼움) / colima / Docker Desktop
docker info >/dev/null && echo "docker OK"

kind version; terragrunt --version; terraform version
```

> ⚠️ 회사 자격증명과 분리: 이 실습은 kubeconfig 를 `~/.kube/k8s-lab/<클러스터>.yaml` 에 따로 만든다.
> 기본 `~/.kube/config`(회사 EKS)는 건드리지 않는다. kubectl 을 쓸 때는 항상 `KUBECONFIG` 를 지정한다.

## 1. (비교용) Terragrunt 없이 모듈을 직접 실행해 보기 — 10분

Terragrunt 가 왜 필요한지 체감하는 단계. 블로그의 "Before" 소재.

```bash
mkdir -p scratch && cd scratch
cat > main.tf <<'TF'
terraform {
  backend "local" { path = "dev.tfstate" }   # 환경마다 이 줄을 복사해야 한다
}
provider "kind" {}
module "cluster" {
  source          = "../modules/kind-cluster"
  cluster_name    = "k8s-lab-dev"
  node_image      = "kindest/node:v1.34.11"
  worker_count    = 1
  kubeconfig_path = pathexpand("~/.kube/k8s-lab/k8s-lab-dev.yaml")
}
TF
terraform init && terraform plan
cd .. && rm -rf scratch
```

👉 기록할 것: stg 를 추가하려면 무엇을 복사·수정해야 하는지 (backend, provider, 변수값…)

## 2. Terragrunt 로 plan / apply

```bash
cd live/dev/cluster
terragrunt run init
terragrunt run plan
terragrunt run apply      # kind 이미지 pull 때문에 첫 실행은 1~3분
```

👉 확인하고 기록할 것

```bash
# (1) Terragrunt 가 만든 작업 폴더와 자동 생성 파일
find .terragrunt-cache -maxdepth 4 -name "*.tf" | head
cat $(find .terragrunt-cache -name backend.tf | head -1)
cat $(find .terragrunt-cache -name provider.tf | head -1)

# (2) state 가 unit 경로별로 분리되어 저장되는지
ls -R ../../../.state

# (3) inputs 가 어떻게 합쳐졌는지 (root.hcl 의 env.hcl 값 + unit 의 kubeconfig_path)
terragrunt render --format json | jq .inputs
```

## 3. 클러스터 확인

```bash
export KUBECONFIG=~/.kube/k8s-lab/k8s-lab-dev.yaml
kubectl get nodes -o wide          # control-plane 1 + worker 1, VERSION v1.34.11
kubectl get pods -A
docker ps --format '{{.Names}}\t{{.Image}}'
terragrunt run output
```

## 4. 실험: 값 바꿔 보기

`live/dev/env.hcl` 의 `worker_count = 2` 로 바꾸고:

```bash
terragrunt run plan
```

👉 기록할 것: plan 결과가 "변경(update)"인지 "교체(replace)"인지, 그 이유.
(힌트: kind provider 문서 — "It does NOT support modification to an existing kind cluster")
실험 후 `worker_count = 1` 로 되돌린다.

## 5. 정리

```bash
terragrunt run destroy
kind get clusters          # 비어 있어야 함
```

## 6. 실습 기록

`docs/notes/week1.md` (또는 `_template.md` 를 복사한 노트)를 채운다. 노트가 블로그 원고(`docs/blog/`)로 정리된다.
에러가 나면 **에러 메시지 원문 전체**와 **무엇을 해서 해결했는지**를 꼭 남긴다.

## 참고 문서

- Terragrunt run 명령: https://docs.terragrunt.com/reference/cli/commands/run/
- kind_cluster 리소스: https://registry.terraform.io/providers/tehcyx/kind/latest/docs/resources/cluster
- kind 릴리스/노드 이미지: https://github.com/kubernetes-sigs/kind/releases
