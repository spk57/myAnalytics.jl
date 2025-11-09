curl -X POST http://localhost:8080/api/analytics/ssl \
  -H "Content-Type: application/json" \
  -d '{
    "prices": [100.5, 102.3, 101.8, 103.2, 102.9, 104.1, 103.5, 105.2, 104.8, 106.1, 105.5, 107.2]
  }'