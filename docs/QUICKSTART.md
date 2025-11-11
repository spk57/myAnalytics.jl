# Quick Start Guide

Get up and running with myAnalytics.jl in 5 minutes.

## 1. Installation (1 minute)

```bash
# Clone the repository
git clone <your-repo-url>
cd myAnalytics.jl

# Install dependencies
julia --project -e 'using Pkg; Pkg.instantiate()'
```

## 2. Start the Server (30 seconds)

```bash
./start_server.sh
```

The server will start on **port 8765**.

## 3. Test the API (2 minutes)

### Open the Interactive Documentation

Visit in your browser:
```
http://localhost:8765/docs
```

### Or Test with curl

```bash
curl -X POST http://localhost:8765/api/getssl \
  -H "Content-Type: application/json" \
  -d '{
    "prices": [100, 102, 101, 103, 105, 104, 106, 108, 107, 109, 110, 112, 111, 113, 115]
  }'
```

Expected output:
```json
{
  "success": true,
  "message": "Analysis completed successfully",
  "predicted": [...],
  "stats": {...},
  ...
}
```

## 4. Run the Tests (1 minute)

```bash
julia --project test/runtests.jl
```

All tests should pass with green checkmarks ✓

## Common First Steps

### Change the Port

```bash
PORT=8080 julia --project src/myAnalytics.jl
```

### Test with Your Data

```bash
# Create a JSON file with your data
echo '{"prices": [10.5, 11.2, 10.8, 11.5, 12.0, ...]}' > mydata.json

# Test the API
curl -X POST http://localhost:8765/api/getssl \
  -H "Content-Type: application/json" \
  -d @mydata.json
```

### Explore the API

1. Open `http://localhost:8765/docs` in your browser
2. Click "Try it out" on the `/api/getssl` endpoint
3. Modify the example data
4. Click "Execute"
5. See the results

## What's Next?

- Read the [full README](../README.md) for detailed documentation
- Check [API documentation](API.md) for complete endpoint reference
- Review [testing guide](TESTING.md) to understand the test suite
- Explore the Swagger UI for interactive API testing

## Troubleshooting

**Server won't start?**
```bash
# Check if port is in use
lsof -i :8765

# Try a different port
PORT=8080 ./start_server.sh
```

**Tests fail?**
```bash
# Check the log file
cat test/runtests.log
```

**API returns errors?**
- Ensure you have at least 10 data points
- Verify JSON format is correct
- Check that values are numeric

## Key Files

- `src/myAnalytics.jl` - Main server
- `src/api/getssl.jl` - Analytics function
- `test/runtests.jl` - Test suite
- `swagger.json` - API specification
- `start_server.sh` - Startup script

## Need Help?

- Check the [README](../README.md)
- Review logs: `test/runtests.log`
- Open an issue on GitHub

