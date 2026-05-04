#!/bin/bash

# macOS Java 버전 관리 자동화 스크립트
# Homebrew로 설치된 Java에 대한 심볼릭 링크 생성 및 jenv 설정

set -euo pipefail

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Java 버전 배열
JAVA_VERSIONS=("8" "11" "17" "21")

echo "🍵 Java 버전 관리 설정 시작..."

# jenv 설치 확인
if ! command -v jenv &>/dev/null; then
  echo -e "${RED}✗ jenv가 설치되어 있지 않습니다.${NC}"
  echo "  brew install jenv 명령으로 설치해주세요."
  exit 1
fi

# 심볼릭 링크 생성
echo ""
echo "📎 심볼릭 링크 생성 중..."
for version in "${JAVA_VERSIONS[@]}"; do
  # Homebrew Cellar에서 Java 경로 찾기
  JAVA_PATH=$(find /opt/homebrew/Cellar/openjdk@${version} -name "openjdk.jdk" 2>/dev/null | head -1)

  if [ -z "$JAVA_PATH" ]; then
    echo -e "${YELLOW}⚠ openjdk@${version}이 설치되어 있지 않습니다. 건너뜁니다.${NC}"
    continue
  fi

  TARGET_PATH="/Library/Java/JavaVirtualMachines/openjdk-${version}.jdk"

  # 기존 링크 확인
  if [ -L "$TARGET_PATH" ]; then
    echo -e "${YELLOW}⚠ openjdk-${version}.jdk 링크가 이미 존재합니다. 재생성합니다.${NC}"
  fi

  # 심볼릭 링크 생성 (sudo 필요)
  sudo ln -sfn "$JAVA_PATH" "$TARGET_PATH"

  # 검증
  if /usr/libexec/java_home -v ${version} &>/dev/null; then
    JAVA_HOME=$(/usr/libexec/java_home -v ${version})
    echo -e "${GREEN}✓ Java ${version} 링크 생성 완료: ${JAVA_HOME}${NC}"
  else
    echo -e "${RED}✗ Java ${version} 링크 검증 실패${NC}"
  fi
done

# jenv에 Java 버전 추가
echo ""
echo "🔧 jenv에 Java 버전 추가 중..."

# jenv 플러그인 활성화 (필요한 경우)
if ! jenv plugins | grep -q "export"; then
  echo "  jenv export 플러그인 활성화..."
  jenv enable-plugin export
fi

for version in "${JAVA_VERSIONS[@]}"; do
  JAVA_HOME=$(/usr/libexec/java_home -v ${version} 2>/dev/null || echo "")

  if [ -z "$JAVA_HOME" ]; then
    echo -e "${YELLOW}⚠ Java ${version} 홈 디렉토리를 찾을 수 없습니다. 건너뜁니다.${NC}"
    continue
  fi

  # jenv에 이미 추가되어 있는지 확인
  if jenv versions | grep -q "${JAVA_HOME}"; then
    echo -e "${YELLOW}⚠ Java ${version}이 이미 jenv에 추가되어 있습니다.${NC}"
  else
    jenv add "$JAVA_HOME"
    echo -e "${GREEN}✓ Java ${version} jenv 추가 완료${NC}"
  fi
done

# 설정된 Java 버전 확인
echo ""
echo "📋 설정된 Java 버전 목록:"
jenv versions

echo ""
echo -e "${GREEN}✨ Java 버전 관리 설정 완료!${NC}"
echo ""
echo "사용 방법:"
echo "  전역 버전 설정: jenv global <version>"
echo "  로컬 버전 설정: jenv local <version>"
echo "  현재 버전 확인: jenv version"
