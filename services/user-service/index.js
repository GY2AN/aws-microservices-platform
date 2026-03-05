const express = require('express');
const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

// Health check endpoint - required for ALB
app.get('/health', (req, res) => {
  res.json({ service: 'user-service', status: 'ok', timestamp: new Date().toISOString() });
});

// Get all users (mock data for now)
app.get('/users', (req, res) => {
  res.json([
    { id: 1, name: 'Alice', email: 'alice@example.com' },
    { id: 2, name: 'Bob', email: 'bob@example.com' }
  ]);
});

// Get user by ID
app.get('/users/:id', (req, res) => {
  res.json({ id: parseInt(req.params.id), name: 'Alice', email: 'alice@example.com' });
});

// Create user
app.post('/users', (req, res) => {
  const { name, email } = req.body;
  res.status(201).json({ id: 3, name, email, created_at: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`User service running on port ${PORT}`);
}); 
