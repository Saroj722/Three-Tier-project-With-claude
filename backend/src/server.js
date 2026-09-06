require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { pool, initSchema } = require('./db');
const tasksRouter = require('./routes/tasks');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

// Simple request logging - useful when you're checking CloudWatch logs
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});

// Health check endpoint - THIS is what the ALB target group and ECS
// container health check will hit. Keep it fast and dependency-light,
// but also verify DB connectivity so ECS can catch a broken DB link.
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'ok', db: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'error', db: 'disconnected' });
  }
});

app.use('/api/tasks', tasksRouter);

app.get('/', (req, res) => {
  res.json({ message: 'Three-tier demo API', tier: 'backend' });
});

async function start() {
  try {
    await initSchema();
  } catch (err) {
    console.error('Failed to initialize schema, will retry on first request:', err.message);
  }
  app.listen(PORT, () => {
    console.log(`Backend API listening on port ${PORT}`);
  });
}

start();
