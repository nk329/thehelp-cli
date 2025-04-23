#!/bin/bash

if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "❌ OPENAI_API_KEY 환경 변수를 설정하세요."
  exit 1
fi

ERR_LOG=${THEHELP_ERR_FILE:-/tmp/thehelp_err.log}
OUT_LOG=${THEHELP_OUT_FILE:-/tmp/thehelp_out.log}
MODEL=${THEHELP_MODEL:-gpt-4}

if [[ -z "$1" ]]; then
  if [[ ! -f "$ERR_LOG" && ! -f "$OUT_LOG" ]]; then
    echo "❌ 분석할 로그 파일이 없습니다."
    exit 1
  fi
  echo "📄 이전 명령어 로그 분석 중..."
  CONTENT=$(cat "$ERR_LOG" "$OUT_LOG")
else
  echo "▶️ 명령어 실행 중: $*"
  CONTENT=$(eval "$*" 2>&1)
  echo "📄 명령 실행 결과:"
  echo "$CONTENT"
fi

echo "🧠 GPT 분석 요청 중..."
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [{\"role\": \"user\", \"content\": \"다음 명령어 실행 결과를 분석해줘:\n$CONTENT\"}],
    \"stream\": false
  }" | jq -r '.choices[].message.content'
