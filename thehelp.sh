if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "❌ OPENAI_API_KEY 환경 변수를 설정하세요."
  exit 1
fi

ERR_LOG=${THEHELP_ERR_FILE:-/tmp/thehelp_err.log}
OUT_LOG=${THEHELP_OUT_FILE:-/tmp/thehelp_out.log}
MODEL=${THEHELP_MODEL:-gpt-4}
VERBOSE=false

if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
  VERBOSE=true
  shift
fi

if [[ -z "$1" ]]; then
  if [[ ! -f "$ERR_LOG" && ! -f "$OUT_LOG" ]]; then
    echo "❌ 분석할 로그 파일이 없습니다."
    exit 1
  fi

  echo "📄 이전 명령어 로그 분석 중..."
  if [[ -s "$ERR_LOG" ]]; then
    echo "⚙️ stderr 로그를 우선 분석합니다."
    CONTENT=$(tail -c 4000 "$ERR_LOG")
  elif [[ -s "$OUT_LOG" ]]; then
    echo "⚙️ stderr가 없으므로 stdout 로그를 분석합니다."
    CONTENT=$(tail -c 4000 "$OUT_LOG")
  else
    echo "❌ stderr와 stdout 모두 비어 있어 분석할 수 없습니다."
    exit 1
  fi
else
  echo "▶️ 명령어 실행 중: $*"
  CONTENT=$(eval "$*" 2>&1)
  echo "📄 명령 실행 결과:"
  echo "$CONTENT"
fi

if $VERBOSE; then
  PROMPT="다음 명령어 실행 결과를 한국어로 상세하게 분석하고, 최대 3가지 해결 방법을 제시해줘:"
else
  PROMPT="다음 명령어 실행 결과를 한국어로 분석하고, 간단한 해결 방법을 알려줘:"
fi

ESCAPED_CONTENT=$(printf "%s\n%s" "$PROMPT" "$CONTENT" | jq -Rs .)

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [{\"role\": \"user\", \"content\": $ESCAPED_CONTENT}],
    \"stream\": false
  }")

echo "🔎 GPT 응답 분석 중..."

echo "$RESPONSE" | jq -e '.choices' > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo "$RESPONSE" | jq -r '.choices[].message.content'
else
  echo "❌ GPT 응답 오류 또는 분석 불가:"
  echo "$RESPONSE" | jq .
fi

