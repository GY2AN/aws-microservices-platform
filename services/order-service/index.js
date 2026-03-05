 const express = require('express');
const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3001;

app.get('/health', (req, res) => {
  res.json({ service: 'order-service', status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/orders', (req, res) => {
  res.json([
    { id: 1, user_id: 1, product_id: 10, status: 'shipped', total: 29.99 },
    { id: 2, user_id: 2, product_id: 11, status: 'processing', total: 49.99 }
  ]);
});

app.get('/orders/:id', (req, res) => {
  res.json({ id: parseInt(req.params.id), user_id: 1, product_id: 10, status: 'shipped', total: 29.99 });
});

app.post('/orders', (req, res) => {
  const { user_id, product_id, total } = req.body;
  res.status(201).json({ id: 3, user_id, product_id, total, status: 'processing', created_at: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Order service running on port ${PORT}`);
});
