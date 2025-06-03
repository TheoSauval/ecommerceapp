const request = require('supertest');
const app = require('../../app');
const sequelize = require('../../config/database');

let token;
let productId1, productId2;

beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  await sequelize.sync({ force: true });

  // Créer un administrateur et récupérer son token
  await request(app)
    .post('/api/auth/register')
    .send({
      nom: 'Test',
      prenom: 'Admin',
      age: 30,
      mail: 'test.admin@example.com',
      password: 'pwd12345',
      role: 'admin'
    });

  const res = await request(app)
    .post('/api/auth/login')
    .send({
      mail: 'test.admin@example.com',
      password: 'pwd12345'
    });
  token = res.body.token;

  // Créer un vendeur
  await request(app)
    .post('/api/auth/register')
    .send({
      nom: 'Test',
      prenom: 'Vendor',
      age: 30,
      mail: 'test.vendor@example.com',
      password: 'pwd12345',
      role: 'vendor'
    });

  const vendorRes = await request(app)
    .post('/api/auth/login')
    .send({
      mail: 'test.vendor@example.com',
      password: 'pwd12345'
    });

  // Créer des produits pour les tests
  const prod1Res = await request(app)
    .post('/api/admin/products')
    .set('Authorization', `Bearer ${vendorRes.body.token}`)
    .send({
      name: 'Test Product 1',
      description: 'Test Description 1',
      price: 99.99,
      category: 'Test Category',
      brand: 'Test Brand',
      stock: 100,
      images: ['test-image-1.jpg']
    });
  productId1 = prod1Res.body.id || prod1Res.body.product?.id;

  const prod2Res = await request(app)
    .post('/api/admin/products')
    .set('Authorization', `Bearer ${vendorRes.body.token}`)
    .send({
      name: 'Test Product 2',
      description: 'Test Description 2',
      price: 149.99,
      category: 'Test Category',
      brand: 'Test Brand',
      stock: 50,
      images: ['test-image-2.jpg']
    });
  productId2 = prod2Res.body.id || prod2Res.body.product?.id;

  // Créer un utilisateur pour les commandes
  await request(app)
    .post('/api/auth/register')
    .send({
      nom: 'Test',
      prenom: 'User',
      age: 30,
      mail: 'test.user@example.com',
      password: 'pwd12345'
    });

  const userRes = await request(app)
    .post('/api/auth/login')
    .send({
      mail: 'test.user@example.com',
      password: 'pwd12345'
    });

  // Créer quelques commandes
  await request(app)
    .post('/api/orders')
    .set('Authorization', `Bearer ${userRes.body.token}`)
    .send({
      address: {
        street: '123 Test Street',
        city: 'Test City',
        postalCode: '12345',
        country: 'Test Country'
      },
      paymentMethod: 'card',
      items: [{
        productId: productId1,
        quantity: 2
      }]
    });

  await request(app)
    .post('/api/orders')
    .set('Authorization', `Bearer ${userRes.body.token}`)
    .send({
      address: {
        street: '123 Test Street',
        city: 'Test City',
        postalCode: '12345',
        country: 'Test Country'
      },
      paymentMethod: 'card',
      items: [{
        productId: productId2,
        quantity: 1
      }]
    });
});

afterAll(async () => {
  await sequelize.close();
});

describe('## ADMIN DASHBOARD', () => {
  it('GET /api/admin/dashboard/sales → doit renvoyer les données de ventes', async () => {
    const res = await request(app)
      .get('/api/admin/dashboard/sales')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('totalRevenue');
    expect(res.body).toHaveProperty('salesByDay');
    expect(res.body).toHaveProperty('salesByMonth');
  });

  it('GET /api/admin/dashboard/top-products → doit renvoyer les produits les plus vendus', async () => {
    const res = await request(app)
      .get('/api/admin/dashboard/top-products')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    expect(res.body[0]).toHaveProperty('id');
    expect(res.body[0]).toHaveProperty('name');
    expect(res.body[0]).toHaveProperty('totalSales');
    expect(res.body[0]).toHaveProperty('revenue');
  });
}); 