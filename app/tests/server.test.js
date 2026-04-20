const request = require('supertest');
const app = require('../src/server');

describe('GlobalMart API - Health & Version', () => {
  test('GET /health returns healthy status', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('healthy');
    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('uptime');
  });

  test('GET /api/version returns version info', async () => {
    const res = await request(app).get('/api/version');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('color');
  });
});

describe('GlobalMart API - Products', () => {
  test('GET /api/products returns all products', async () => {
    const res = await request(app).get('/api/products');
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
  });

  test('GET /api/products?category=Electronics filters correctly', async () => {
    const res = await request(app).get('/api/products?category=Electronics');
    expect(res.statusCode).toBe(200);
    res.body.data.forEach(p => expect(p.category).toBe('Electronics'));
  });

  test('GET /api/products/:id returns single product', async () => {
    const res = await request(app).get('/api/products/1');
    expect(res.statusCode).toBe(200);
    expect(res.body.data.id).toBe('1');
  });

  test('GET /api/products/:id returns 404 for unknown id', async () => {
    const res = await request(app).get('/api/products/999');
    expect(res.statusCode).toBe(404);
  });

  test('POST /api/products creates a new product', async () => {
    const res = await request(app)
      .post('/api/products')
      .send({ name: 'Test Product', price: 9.99, category: 'Test', stock: 10 });
    expect(res.statusCode).toBe(201);
    expect(res.body.data.name).toBe('Test Product');
    expect(res.body.data).toHaveProperty('id');
  });

  test('POST /api/products returns 400 if name is missing', async () => {
    const res = await request(app)
      .post('/api/products')
      .send({ price: 9.99, category: 'Test' });
    expect(res.statusCode).toBe(400);
  });
});

describe('GlobalMart API - Cart', () => {
  const userId = 'test-user-123';

  test('GET /api/cart/:userId returns empty cart initially', async () => {
    const res = await request(app).get(`/api/cart/${userId}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data).toEqual([]);
    expect(res.body.total).toBe(0);
  });

  test('POST /api/cart/:userId adds item to cart', async () => {
    const res = await request(app)
      .post(`/api/cart/${userId}`)
      .send({ productId: '1', quantity: 2 });
    expect(res.statusCode).toBe(200);
    expect(res.body.data.length).toBe(1);
    expect(res.body.data[0].quantity).toBe(2);
  });

  test('POST /api/cart/:userId increments quantity for existing item', async () => {
    await request(app).post(`/api/cart/${userId}`).send({ productId: '2', quantity: 1 });
    await request(app).post(`/api/cart/${userId}`).send({ productId: '2', quantity: 1 });
    const res = await request(app).get(`/api/cart/${userId}`);
    const item = res.body.data.find(i => i.productId === '2');
    expect(item.quantity).toBe(2);
  });
});

describe('GlobalMart API - Orders', () => {
  const userId = 'order-test-user';

  test('POST /api/orders/:userId returns 400 for empty cart', async () => {
    const res = await request(app).post(`/api/orders/${userId}`);
    expect(res.statusCode).toBe(400);
  });

  test('POST /api/orders/:userId creates order and clears cart', async () => {
    await request(app).post(`/api/cart/${userId}`).send({ productId: '3', quantity: 1 });
    const res = await request(app).post(`/api/orders/${userId}`);
    expect(res.statusCode).toBe(201);
    expect(res.body.data.status).toBe('confirmed');
    expect(res.body.data.items.length).toBe(1);

    const cartRes = await request(app).get(`/api/cart/${userId}`);
    expect(cartRes.body.data).toEqual([]);
  });
});
