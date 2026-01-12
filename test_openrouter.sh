OPENROUTER_API_KEY=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

/usr/bin/bash -c "curl --ssl-no-revoke https://openrouter.ai/api/v1/chat/completions \
  -H \"Authorization: Bearer $OPENROUTER_API_KEY\" \
  -H \"Content-Type: application/json\" \
  -d '{
    \"model\": \"allenai/molmo-2-8b:free\",
    \"messages\": [{\"role\": \"user\", \"content\": \"Dis bonjour à la dame !\"}]
  }'"