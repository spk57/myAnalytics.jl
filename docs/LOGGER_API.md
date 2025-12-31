# Logger API Documentation

## Overview

The Logger API provides endpoints for storing and retrieving time-series log data with metadata. Each log entry contains a timestamp, name, value, and source identifier.

## Endpoints

### POST /api/logger

Create a new log entry.

**Request Body:**
```json
{
  "datetime": "2025-01-01T10:30:00",
  "name": "temperature",
  "value": 23.5,
  "source": "sensor-01"
}
```

**Request Fields:**
- `datetime` (required): ISO 8601 formatted datetime string
- `name` (required): String identifier for the log entry
- `value` (required): Any value (number, string, boolean, etc.)
- `source` (required): String identifying the source/origin

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Log entry created successfully",
  "id": 1
}
```

**Error Response (400 Bad Request):**
```json
{
  "success": false,
  "message": "Missing required field: datetime"
}
```

**Example:**
```bash
curl -X POST http://localhost:8765/api/logger \
  -H "Content-Type: application/json" \
  -d '{
    "datetime": "2025-01-01T10:30:00",
    "name": "temperature",
    "value": 23.5,
    "source": "sensor-01"
  }'
```

---

### GET /api/logger

Retrieve log entries with optional filtering and pagination.

**Query Parameters:**
- `limit` (optional): Maximum number of entries to return (default: 100)
- `offset` (optional): Number of entries to skip (default: 0)
- `source` (optional): Filter by source
- `name` (optional): Filter by name

**Success Response (200 OK):**
```json
{
  "success": true,
  "entries": [
    {
      "id": 1,
      "datetime": "2025-01-01T10:30:00",
      "name": "temperature",
      "value": 23.5,
      "source": "sensor-01",
      "created_at": "2025-01-01T10:30:05"
    }
  ],
  "total": 1,
  "limit": 100,
  "offset": 0
}
```

**Examples:**

Get all entries:
```bash
curl http://localhost:8765/api/logger
```

Get entries with pagination:
```bash
curl "http://localhost:8765/api/logger?limit=10&offset=20"
```

Filter by source:
```bash
curl "http://localhost:8765/api/logger?source=sensor-01"
```

Filter by name:
```bash
curl "http://localhost:8765/api/logger?name=temperature"
```

Combine filters:
```bash
curl "http://localhost:8765/api/logger?source=sensor-01&name=temperature&limit=50"
```

---

### GET /api/logger/stats

Get statistics about logged entries.

**Success Response (200 OK):**
```json
{
  "success": true,
  "total_entries": 150,
  "unique_sources": 5,
  "unique_names": 10,
  "sources": ["sensor-01", "sensor-02", "api", "manual", "system"],
  "names": ["temperature", "humidity", "pressure", "status", ...]
}
```

**Example:**
```bash
curl http://localhost:8765/api/logger/stats
```

---

## Use Cases

### IoT Sensor Data Logging

```bash
# Log temperature reading
curl -X POST http://localhost:8765/api/logger \
  -H "Content-Type: application/json" \
  -d '{
    "datetime": "2025-01-01T10:30:00",
    "name": "temperature",
    "value": 23.5,
    "source": "sensor-01"
  }'

# Log humidity reading
curl -X POST http://localhost:8765/api/logger \
  -H "Content-Type: application/json" \
  -d '{
    "datetime": "2025-01-01T10:30:00",
    "name": "humidity",
    "value": 65.2,
    "source": "sensor-01"
  }'

# Retrieve all sensor-01 readings
curl "http://localhost:8765/api/logger?source=sensor-01"
```

### Application Event Logging

```bash
# Log application event
curl -X POST http://localhost:8765/api/logger \
  -H "Content-Type: application/json" \
  -d '{
    "datetime": "2025-01-01T10:30:00",
    "name": "user_login",
    "value": "success",
    "source": "web-app"
  }'

# Log error event
curl -X POST http://localhost:8765/api/logger \
  -H "Content-Type: application/json" \
  -d '{
    "datetime": "2025-01-01T10:35:00",
    "name": "api_error",
    "value": "timeout",
    "source": "backend-service"
  }'
```

### System Metrics

```bash
# Log CPU usage
curl -X POST http://localhost:8765/api/logger \
  -H "Content-Type: application/json" \
  -d '{
    "datetime": "2025-01-01T10:30:00",
    "name": "cpu_usage",
    "value": 45.2,
    "source": "server-01"
  }'

# Get all metrics for server-01
curl "http://localhost:8765/api/logger?source=server-01"
```

---

## Python Client Example

```python
import requests
from datetime import datetime

class LoggerClient:
    def __init__(self, base_url="http://localhost:8765"):
        self.base_url = base_url
    
    def log(self, name, value, source, dt=None):
        """Create a log entry"""
        if dt is None:
            dt = datetime.now()
        
        payload = {
            "datetime": dt.isoformat(),
            "name": name,
            "value": value,
            "source": source
        }
        
        response = requests.post(
            f"{self.base_url}/api/logger",
            json=payload
        )
        return response.json()
    
    def get_entries(self, limit=100, offset=0, source=None, name=None):
        """Retrieve log entries"""
        params = {"limit": limit, "offset": offset}
        if source:
            params["source"] = source
        if name:
            params["name"] = name
        
        response = requests.get(
            f"{self.base_url}/api/logger",
            params=params
        )
        return response.json()
    
    def get_stats(self):
        """Get logger statistics"""
        response = requests.get(f"{self.base_url}/api/logger/stats")
        return response.json()

# Usage
client = LoggerClient()

# Log some data
client.log("temperature", 23.5, "sensor-01")
client.log("humidity", 65.2, "sensor-01")

# Retrieve entries
entries = client.get_entries(source="sensor-01")
print(f"Found {entries['total']} entries")

# Get stats
stats = client.get_stats()
print(f"Total entries: {stats['total_entries']}")
```

---

## Julia Client Example

```julia
using HTTP, JSON, Dates

struct LoggerClient
    base_url::String
end

function log_entry(client::LoggerClient, name::String, value, source::String; dt::DateTime=now())
    payload = Dict(
        "datetime" => Dates.format(dt, "yyyy-mm-ddTHH:MM:SS"),
        "name" => name,
        "value" => value,
        "source" => source
    )
    
    response = HTTP.post(
        "$(client.base_url)/api/logger",
        body=JSON.json(payload),
        headers=Dict("Content-Type" => "application/json")
    )
    
    return JSON.parse(String(response.body))
end

function get_entries(client::LoggerClient; limit=100, offset=0, source=nothing, name=nothing)
    params = ["limit=$limit", "offset=$offset"]
    !isnothing(source) && push!(params, "source=$source")
    !isnothing(name) && push!(params, "name=$name")
    
    url = "$(client.base_url)/api/logger?" * join(params, "&")
    response = HTTP.get(url)
    
    return JSON.parse(String(response.body))
end

# Usage
client = LoggerClient("http://localhost:8765")

# Log data
log_entry(client, "temperature", 23.5, "sensor-01")

# Retrieve entries
entries = get_entries(client, source="sensor-01")
println("Found $(entries["total"]) entries")
```

---

## Data Storage

**Note:** The current implementation stores log entries in memory. This means:
- ✅ Fast access and retrieval
- ✅ No database setup required
- ⚠️ Data is lost when server restarts
- ⚠️ Limited by available RAM

For production use, consider implementing persistent storage using:
- PostgreSQL
- SQLite
- MongoDB
- Time-series databases (InfluxDB, TimescaleDB)

---

## Best Practices

1. **Use ISO 8601 datetime format**: Always use `YYYY-MM-DDTHH:MM:SS` format
2. **Consistent naming**: Use consistent names for similar log types
3. **Source identification**: Use clear, unique source identifiers
4. **Pagination**: Use limit/offset for large datasets
5. **Filtering**: Filter by source or name to reduce data transfer
6. **Regular cleanup**: Implement data retention policies for production

---

## Error Handling

All endpoints return consistent error responses:

```json
{
  "success": false,
  "message": "Description of the error"
}
```

Common errors:
- Missing required fields → 400 Bad Request
- Invalid datetime format → 400 Bad Request
- Server errors → 500 Internal Server Error

---

## Performance Considerations

- In-memory storage is fast but limited by RAM
- Consider implementing pagination for large datasets
- Filter early to reduce data transfer
- Monitor memory usage with many entries
- Implement data archival/cleanup for long-running systems

