# SQL Server RAG System Setup Guide

This guide will help you set up a complete RAG (Retrieval-Augmented Generation) system for your SQL Server database with a React frontend.

## Architecture Overview

```
┌─────────────────┐    HTTP     ┌──────────────────┐    SQL    ┌──────────────────┐
│   React Frontend│ ◄─────────► │ FastAPI Backend  │ ◄───────► │  SQL Server DB   │
│                 │             │                  │           │                  │
│ - Chat Interface│             │ - LLM Integration│           │ - Your Database  │
│ - Data Tables   │             │ - SQL Generation │           │ - Schema Info    │
│ - Charts        │             │ - Query Execution│           │ - Sample Data    │
└─────────────────┘             └──────────────────┘           └──────────────────┘
```

## Prerequisites

- Python 3.8+
- Node.js 14+
- SQL Server with ODBC drivers
- OpenAI API key
- Git

## Backend Setup (FastAPI)

### 1. Install Dependencies

Create a `requirements.txt` file:

```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
pyodbc==4.0.39
pandas==2.1.3
openai==0.28.1
sqlparse==0.4.4
python-multipart==0.0.6
```

Install the dependencies:

```bash
pip install -r requirements.txt
```

### 2. Database Configuration

Update the `DATABASE_CONFIG` in your FastAPI app:

```python
DATABASE_CONFIG = {
    'driver': '{ODBC Driver 17 for SQL Server}',
    'server': 'your_server_name',        # e.g., 'localhost' or 'server.domain.com'
    'database': 'your_database_name',     # Your database name
    'username': 'your_username',          # SQL Server username
    'password': 'your_password',          # SQL Server password
    'trusted_connection': 'no'            # 'yes' for Windows Auth, 'no' for SQL Auth
}
```

### 3. Environment Variables

Create a `.env` file in your backend directory:

```env
OPENAI_API_KEY=your_openai_api_key_here
```

### 4. Install SQL Server ODBC Driver

**Windows:**
- Download from Microsoft's website
- Install ODBC Driver 17 for SQL Server

**Linux (Ubuntu/Debian):**
```bash
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get install -y msodbcsql17
```

**macOS:**
```bash
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew update
HOMEBREW_NO_ENV_FILTERING=1 ACCEPT_EULA=Y brew install msodbcsql17 mssql-tools
```

### 5. Run Backend

```bash
python app.py
# or
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at: `http://localhost:8000`

## Frontend Setup (React)

### 1. Create React App

```bash
npx create-react-app sql-rag-frontend
cd sql-rag-frontend
```

### 2. Install Dependencies

```bash
npm install recharts lucide-react
```

### 3. Replace App.js

Replace the contents of `src/App.js` with the React component from the artifacts above.

### 4. Update package.json

Add a proxy to avoid CORS issues during development:

```json
{
  "name": "sql-rag-frontend",
  "version": "0.1.0",
  "private": true,
  "proxy": "http://localhost:8000",
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "recharts": "^2.8.0",
    "lucide-react": "^0.263.1"
  }
}
```

### 5. Run Frontend

```bash
npm start
```

The frontend will be available at: `http://localhost:3000`

## Testing the Setup

### 1. Verify Backend

Visit `http://localhost:8000/docs` to see the FastAPI documentation.

Test endpoints:
- `GET /schema` - Should return your database schema
- `GET /tables` - Should return list of tables

### 2. Test Database Connection

```python
# Test script: test_connection.py
import pyodbc

DATABASE_CONFIG = {
    'driver': '{ODBC Driver 17 for SQL Server}',
    'server': 'your_server_name',
    'database': 'your_database_name',
    'username': 'your_username',
    'password': 'your_password',
    'trusted_connection': 'no'
}

try:
    conn_string = (
        f"DRIVER={DATABASE_CONFIG['driver']};"
        f"SERVER={DATABASE_CONFIG['server']};"
        f"DATABASE={DATABASE_CONFIG['database']};"
        f"UID={DATABASE_CONFIG['username']};"
        f"PWD={DATABASE_CONFIG['password']};"
        f"Trusted_Connection={DATABASE_CONFIG['trusted_connection']};"
    )
    conn = pyodbc.connect(conn_string)
    print("✅ Database connection successful!")
    
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'")
    table_count = cursor.fetchone()[0]
    print(f"✅ Found {table_count} tables in database")
    
except Exception as e:
    print(f"❌ Database connection failed: {e}")
```

### 3. Test OpenAI API

```python
# Test script: test_openai.py
import openai
import os

openai.api_key = os.getenv("OPENAI_API_KEY")

try:
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": "Hello, are you working?"}],
        max_tokens=50
    )
    print("✅ OpenAI API connection successful!")
    print(f"Response: {response.choices[0].message.content}")
except Exception as e:
    print(f"❌ OpenAI API connection failed: {e}")
```

## Example Queries

Once everything is set up, try these example queries:

1. **Basic Data Exploration:**
   - "Show me all tables in the database"
   - "What columns are in the users table?"
   - "Give me 10 rows from the orders table"

2. **Aggregated Queries:**
   - "Show total sales by month"
   - "Count customers by region"
   - "Average order value by product category"

3. **Complex Analysis:**
   - "Which products have the highest sales?"
   - "Show customer growth over time"
   - "Find top 10 customers by revenue"

## Troubleshooting

### Common Issues

1. **Database Connection Errors:**
   - Verify SQL Server is running
   - Check firewall settings
   - Confirm connection string parameters
   - Test with SQL Server Management Studio first

2. **ODBC Driver Issues:**
   - Install correct ODBC driver version
   - Check driver name in connection string
   - Verify driver installation with `odbcinst -q -d`

3. **OpenAI API Errors:**
   - Verify API key is correct
   - Check OpenAI account has credits
   - Ensure proper environment variable setup

4. **CORS Issues:**
   - Verify FastAPI CORS middleware is configured
   - Check frontend is making requests to correct URL
   - Use proxy in package.json for development

### Performance Optimization

1. **Query Optimization:**
   - Add `TOP` clauses to limit large result sets
   - Create indexes on frequently queried columns
   - Use appropriate data types

2. **Caching:**
   - Cache schema information
   - Implement query result caching
   - Cache frequently accessed data

3. **Security:**
   - Use read-only database user
   - Validate and sanitize SQL queries
   - Implement rate limiting
   - Use HTTPS in production

## Deployment

### Backend Deployment

1. **Using Docker:**

```dockerfile
FROM python:3.9-slim

RUN apt-get update && apt-get install -y \
    curl apt-transport-https gnupg \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

2. **Using Cloud Services:**
   - AWS: Deploy to ECS, Lambda, or EC2
   - Azure: Use App Service or Container Instances
   - Google Cloud: Deploy to Cloud Run or Compute Engine

### Frontend Deployment

1. **Build for Production:**

```bash
npm run build
```

2. **Deploy to:**
   - Vercel: `vercel --prod`
   - Netlify: Drag and drop `build` folder
   - AWS S3 + CloudFront
   - Azure Static Web Apps

## Next Steps

1. **Enhanced Features:**
   - Add user authentication
   - Implement query history persistence
   - Add data export options
   - Create custom visualizations

2. **Advanced Analytics:**
   - Integrate with ML models
   - Add predictive analytics
   - Implement anomaly detection
   - Create automated reports

3. **Security Enhancements:**
   - Add role-based access control
   - Implement audit logging
   - Add data masking for sensitive data
   - Use encrypted connections

4. **Monitoring:**
   - Add application logging
   - Monitor query performance
   - Track user interactions
   - Set up alerts for errors

This RAG system provides a solid foundation for natural language database querying. You can extend it based on your specific needs and requirements.