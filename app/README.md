# Scalable Web Application

A Node.js web application with PostgreSQL database integration, designed for containerized deployment on AWS ECS.

## Features

- **RESTful API** with Express.js
- **PostgreSQL** database integration
- **Health checks** and monitoring endpoints
- **Security** with Helmet.js and CORS
- **Logging** with Morgan
- **Testing** with Jest and Supertest
- **Docker** containerization with multi-stage builds

## API Endpoints

### Health & Status
- `GET /` - Welcome message and app info
- `GET /health` - Health check endpoint
- `GET /api/db-status` - Database connection status

### Users
- `GET /api/users` - List all users
- `POST /api/users` - Create new user

### Posts
- `GET /api/posts` - List all posts with author info
- `POST /api/posts` - Create new post

## Environment Variables

```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
DB_USER=dbadmin
DB_PASSWORD=your_password

# Application Configuration
NODE_ENV=development
PORT=3000
```

## Local Development

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

3. **Start development server**
   ```bash
   npm run dev
   ```

4. **Run tests**
   ```bash
   npm test
   npm run test:coverage
   ```

## Docker Deployment

1. **Build image**
   ```bash
   docker build -t scalable-web-app .
   ```

2. **Run container**
   ```bash
   docker run -p 3000:3000 \
     -e DB_HOST=your_db_host \
     -e DB_USER=your_db_user \
     -e DB_PASSWORD=your_db_password \
     -e DB_NAME=your_db_name \
     scalable-web-app
   ```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Posts Table
```sql
CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  content TEXT,
  user_id INTEGER REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Security Features

- **Helmet.js** for security headers
- **CORS** configuration
- **Input validation** and sanitization
- **Non-root user** in Docker container
- **Health checks** for container orchestration

## Monitoring

The application includes several monitoring endpoints:

- `/health` - Basic health check
- `/api/db-status` - Database connectivity check

Logs are structured and include:
- Request logging with Morgan
- Error logging with stack traces
- Database operation logs

## Testing

Run the test suite:

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run in watch mode
npm run test:watch
```

## Production Considerations

- Set `NODE_ENV=production`
- Use SSL for database connections
- Configure proper logging levels
- Set up monitoring and alerting
- Use secrets management for credentials
- Enable container health checks