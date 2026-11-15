<!-- 블로그 1번 글 초안 틀. 〔 〕 부분은 실습 후 실제 내용으로 채운다. -->

# [Terragrunt] Terraform을 쓰다 Terragrunt가 궁금해진 이유와 로컬 실습 환경 구성

## 서론

〔회사에서 Terraform으로 EKS·Karpenter 등을 관리하며 느낀 불편함 1~3줄.
 예: 환경마다 backend 설정 복사, 모듈 apply 순서를 사람이 기억해야 함 등 — 실제 겪은 것만〕

그래서 Terragrunt를 학습하고, 우리 인프라에 적용할 수 있을지 판단해 보려 한다.
회사 인프라에 바로 손대기보다 먼저 로컬 kind 클러스터로 실습한다.

이 글은 연재의 1편이다.
1. **Terragrunt가 궁금해진 이유와 로컬 실습 환경 구성 (이번 글)**
2. root.hcl과 include로 backend 반복 없애기
3. dependency와 run --all로 dev/stg 한 번에 만들기
4. Stacks와 --filter-affected로 바뀐 것만 plan하기
5. 이후 Istio(Ambient) 편으로 이어짐

## 실습 환경

| 항목 | 버전 |
|---|---|
| Mac / 컨테이너 런타임 | 〔〕 |
| kind | 〔v0.33.0〕 |
| 노드 이미지 | kindest/node:v1.34.11 (회사 EKS 1.34와 맞춤) |
| Terragrunt | 〔v1.2.2〕 |
| Terraform | 〔v1.17.2〕 |

실습 코드: 〔GitHub 저장소 링크〕

## Terragrunt란

- Terraform(또는 OpenTofu)을 **감싸서** 실행하는 도구. 모듈 코드를 바꾸지 않는다.
- 해결하는 문제 (표로 정리)

| Terraform만 쓸 때 | Terragrunt |
|---|---|
| 환경마다 backend 설정 복사 | root.hcl 한 곳에서 생성 |
| dev/stg/prod에 같은 코드 반복 | 모듈 한 벌 + 환경별 값만 분리 |
| 모듈 간 apply 순서를 사람이 관리 | dependency 블록 (2편) |
| 바뀐 것만 plan하기 어려움 | run --all, --filter-affected (3·4편) |

- 용어: **unit**(terragrunt.hcl이 있는 폴더 하나 = state 하나), **stack**(unit 묶음)
- 주의: 1.x에서 명령어가 바뀌었다. 예전 글의 `terragrunt run-all plan` → 지금은 `terragrunt run --all plan`

## 왜 kind로 실습하나

- 비용 0원, 클러스터를 몇 분 만에 만들고 지울 수 있음
- Terragrunt로 "환경별 클러스터"를 관리하는 구조가 회사 구조(환경별 폴더 + 의존성)와 닮음
- 다음 Istio 편에서 같은 클러스터를 그대로 사용

## 저장소 구조

```
〔tree 결과 붙여넣기〕
```

- `root.hcl`: 〔역할 한 줄〕
- `live/dev/env.hcl`: 〔역할 한 줄〕
- `live/dev/cluster/terragrunt.hcl`: 〔역할 한 줄〕
- `modules/kind-cluster`: 〔역할 한 줄〕

## 작업 순서

### 1. Terragrunt 없이 실행해 보기 (Before)

〔scratch/main.tf 코드 + stg를 추가하려면 무엇을 복사해야 했는지〕

### 2. Terragrunt로 apply

```bash
cd live/dev/cluster
terragrunt run apply
```

〔실행 결과 일부 + 소요 시간〕

### 3. Terragrunt가 해준 일 확인

- 자동 생성된 backend.tf / provider.tf 〔내용〕
- state가 unit 경로별로 분리됨 〔.state 구조〕
- inputs가 합쳐지는 방식 〔render 결과〕

### 4. 클러스터 확인

〔kubectl get nodes -o wide 결과〕

### 5. 값 바꿔 보기: worker_count 1 → 2

〔plan 결과와 replace가 나온 이유〕

## 트러블슈팅

〔에러 메시지 원문 → 원인 → 해결. 겪은 순서대로〕

## 정리

- 오늘 확인한 것: 〔3줄〕
- 회사에 적용한다면 먼저 볼 것: 〔예: 현재 backend 설정 중복 정도〕
- 다음 글: root.hcl과 include를 더 깊게, stg 환경 추가

## 참고

- https://docs.terragrunt.com/reference/cli/commands/run/
- https://registry.terraform.io/providers/tehcyx/kind/latest/docs/resources/cluster
- https://github.com/kubernetes-sigs/kind/releases
