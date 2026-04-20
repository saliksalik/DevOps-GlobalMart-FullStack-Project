const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const client = require('prom-client');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;
const APP_VERSION = process.env.APP_VERSION || 'v1';

// ─── Prometheus Metrics ────────────────────────────────────────────────────
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ timeout: 5000 });

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
});

const httpRequestTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

// ─── Middleware ────────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Metrics middleware
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on('finish', () => {
    end({ method: req.method, route: req.path, status_code: res.statusCode });
    httpRequestTotal.inc({ method: req.method, route: req.path, status_code: res.statusCode });
  });
  next();
});

// ─── In-Memory Data Store ─────────────────────────────────────────────────
let products = [
  { id: '1', name: 'Wireless Headphones', price: 99.99, category: 'Electronics', stock: 50, image: '🎧' },
  { id: '2', name: 'Running Shoes',        price: 79.99, category: 'Sports',      stock: 30, image: '👟' },
  { id: '3', name: 'Coffee Maker',         price: 49.99, category: 'Kitchen',     stock: 20, image: '☕' },
  { id: '4', name: 'Laptop Backpack',      price: 39.99, category: 'Accessories', stock: 75, image: '🎒' },
  { id: '5', name: 'Smart Watch',          price: 199.99, category: 'Electronics', stock: 15, image: '⌚' },
  { id: '6', name: 'Yoga Mat',             price: 29.99, category: 'Sports',       stock: 40, image: '🧘' },
];

let cart = {};
let orders = [];

// ─── Health & Metrics Endpoints ───────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    version: APP_VERSION,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// ─── Product Routes ───────────────────────────────────────────────────────
app.get('/api/products', (req, res) => {
  const { category, search } = req.query;
  let result = [...products];
  if (category) result = result.filter(p => p.category.toLowerCase() === category.toLowerCase());
  if (search)   result = result.filter(p => p.name.toLowerCase().includes(search.toLowerCase()));
  res.json({ success: true, count: result.length, data: result });
});

app.get('/api/products/:id', (req, res) => {
  const product = products.find(p => p.id === req.params.id);
  if (!product) return res.status(404).json({ success: false, error: 'Product not found' });
  res.json({ success: true, data: product });
});

app.post('/api/products', (req, res) => {
  const { name, price, category, stock, image } = req.body;
  if (!name || !price || !category) {
    return res.status(400).json({ success: false, error: 'name, price, and category are required' });
  }
  const product = { id: uuidv4(), name, price: parseFloat(price), category, stock: stock || 0, image: image || '📦' };
  products.push(product);
  res.status(201).json({ success: true, data: product });
});

// ─── Cart Routes ──────────────────────────────────────────────────────────
app.get('/api/cart/:userId', (req, res) => {
  const userCart = cart[req.params.userId] || [];
  const total = userCart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  res.json({ success: true, data: userCart, total: parseFloat(total.toFixed(2)) });
});

app.post('/api/cart/:userId', (req, res) => {
  const { productId, quantity = 1 } = req.body;
  const product = products.find(p => p.id === productId);
  if (!product) return res.status(404).json({ success: false, error: 'Product not found' });

  if (!cart[req.params.userId]) cart[req.params.userId] = [];
  const existing = cart[req.params.userId].find(i => i.productId === productId);
  if (existing) {
    existing.quantity += quantity;
  } else {
    cart[req.params.userId].push({ productId, name: product.name, price: product.price, quantity, image: product.image });
  }
  res.json({ success: true, data: cart[req.params.userId] });
});

app.delete('/api/cart/:userId/:productId', (req, res) => {
  if (cart[req.params.userId]) {
    cart[req.params.userId] = cart[req.params.userId].filter(i => i.productId !== req.params.productId);
  }
  res.json({ success: true, message: 'Item removed' });
});

// ─── Order Routes ─────────────────────────────────────────────────────────
app.post('/api/orders/:userId', (req, res) => {
  const userCart = cart[req.params.userId];
  if (!userCart || userCart.length === 0) {
    return res.status(400).json({ success: false, error: 'Cart is empty' });
  }
  const total = userCart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const order = {
    id: uuidv4(),
    userId: req.params.userId,
    items: [...userCart],
    total: parseFloat(total.toFixed(2)),
    status: 'confirmed',
    createdAt: new Date().toISOString(),
  };
  orders.push(order);
  cart[req.params.userId] = [];
  res.status(201).json({ success: true, data: order });
});

app.get('/api/orders/:userId', (req, res) => {
  const userOrders = orders.filter(o => o.userId === req.params.userId);
  res.json({ success: true, data: userOrders });
});

// ─── Version Route (for Blue-Green Demo) ─────────────────────────────────
app.get('/api/version', (req, res) => {
  res.json({ version: APP_VERSION, color: process.env.DEPLOY_COLOR || 'blue' });
});

// ─── Start Server ─────────────────────────────────────────────────────────
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`GlobalMart API [${APP_VERSION}] running on port ${PORT}`);
  });
}

module.exports = app;
