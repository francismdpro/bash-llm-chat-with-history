OPENROUTER_API_KEY=****

/usr/bin/bash -c "curl --ssl-no-revoke https://openrouter.ai/api/v1/chat/completions \
  -H \"Authorization: Bearer $OPENROUTER_API_KEY\" \
  -H \"Content-Type: application/json\" \
  -d '{
    \"model\": \"allenai/molmo-2-8b:free\",
    \"messages\": [{\"role\": \"user\", \"content\": \"Dis bonjour à la dame !\"}]

  }'"
