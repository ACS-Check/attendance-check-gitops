#!/bin/bash
set -euo pipefail

echo "====================================="
echo "ECR Secret 생성 (AWS CLI 기반)"
echo "====================================="

# AWS CLI 설치 확인
if ! command -v aws >/dev/null 2>&1; then
  echo "오류: aws CLI를 찾을 수 없습니다. 설치하거나 PATH를 설정하세요." >&2
  exit 1
fi

# AWS 자격증명 확인
echo "AWS 자격증명 확인 중..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "오류: AWS 자격증명이 유효하지 않습니다." >&2
  echo "다음 명령어로 AWS CLI를 설정하세요:" >&2
  echo "  aws configure" >&2
  exit 1
fi

# 실제 Account ID 가져오기
ACTUAL_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ACTUAL_REGION=$(aws configure get region)
ACTUAL_REGION=${ACTUAL_REGION:-ap-northeast-2}

echo "✅ AWS 자격증명 확인 완료"
echo ""
echo "현재 AWS 설정:"
echo "- Account ID: $ACTUAL_ACCOUNT_ID"
echo "- Region: $ACTUAL_REGION"
echo ""

# 사용자에게 확인
read -p "이 설정으로 진행하시겠습니까? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "취소되었습니다."
    exit 0
fi

# 변수 설정
AWS_ACCOUNT_ID="$ACTUAL_ACCOUNT_ID"
AWS_REGION="$ACTUAL_REGION"

# ECR 로그인 패스워드 가져오기
echo ""
echo "ECR 로그인 토큰 가져오는 중..."
PASSWORD=$(aws ecr get-login-password --region "$AWS_REGION")

# ECR 주소
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# AWS Credentials 미리 가져오기
echo "AWS 자격증명 가져오는 중..."
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "오류: AWS 자격증명을 가져올 수 없습니다." >&2
    echo "aws configure를 먼저 실행하세요." >&2
    exit 1
fi

# 네임스페이스 생성 (없을 경우)
for NAMESPACE in cc-frontend cc-backend; do
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        echo "네임스페이스 '$NAMESPACE' 생성 중..."
        kubectl create namespace "$NAMESPACE"
    fi
done

# 양쪽 네임스페이스에 모두 시크릿 생성
echo ""
echo "시크릿 생성 중 (cc-frontend, cc-backend)..."
echo ""

for NAMESPACE in cc-frontend cc-backend; do
    echo "[$NAMESPACE] 시크릿 생성 중..."
    
    # ECR Secret 삭제
    echo "  1. ecr-secret 삭제 중..."
    kubectl delete secret ecr-secret -n "$NAMESPACE" --ignore-not-found=true
    
    # ECR Secret 생성
    echo "  2. ecr-secret 생성 중..."
    kubectl create secret docker-registry -n "$NAMESPACE" ecr-regcred \
       --docker-server="$ECR_REPO" \
       --docker-username=AWS \
       --docker-password="$PASSWORD"
    echo "     ✅ 생성 완료"
    
    # ConfigMap 삭제
    echo "  3. ecr-config 삭제 중..."
    kubectl delete configmap ecr-config -n "$NAMESPACE" --ignore-not-found=true
    
    # ConfigMap 생성
    echo "  4. ecr-config 생성 중..."
    kubectl create configmap ecr-config \
      --from-literal=AWS_ACCOUNT_ID="$AWS_ACCOUNT_ID" \
      --from-literal=AWS_REGION="$AWS_REGION" \
      -n "$NAMESPACE"
    echo "     ✅ 생성 완료"
    
    # AWS Credentials Secret 삭제
    echo "  5. aws-credentials 삭제 중..."
    kubectl delete secret aws-credentials -n "$NAMESPACE" --ignore-not-found=true
    
    # AWS Credentials Secret 생성
    echo "  6. aws-credentials 생성 중..."
    kubectl create secret generic aws-credentials \
      --from-literal=access-key-id="$AWS_ACCESS_KEY_ID" \
      --from-literal=secret-access-key="$AWS_SECRET_ACCESS_KEY" \
      -n "$NAMESPACE"
    echo "     ✅ 생성 완료"
    echo ""
done

echo ""
echo "====================================="
echo "✅ ECR Secret 생성 완료!"
echo "====================================="
echo ""
echo "생성된 리소스 (cc-frontend, cc-backend 양쪽):"
echo "- Secret: ecr-secret (Docker registry 인증)"
echo "- Secret: aws-credentials (AWS CLI 인증)"
echo "- ConfigMap: ecr-config (AWS 정보)"
echo ""
echo "이제 CronJob이 12시간마다 자동으로 ecr-secret을 갱신합니다."
echo ""
echo "다음 단계:"
echo "  bash bin/deploy-all.sh  # 모든 리소스 배포"
