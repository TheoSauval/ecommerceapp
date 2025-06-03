const request = require('supertest');
const app = require('../../app');
const sequelize = require('../../config/database');

let token;
let orderId;

beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  await sequelize.sync({ force: true });

  // Créer un vendeur et récupérer son token
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

  const res = await request(app)
    .post('/api/auth/login')
    .send({
      mail: 'test.vendor@example.com',
      password: 'pwd12345'
    });
  token = res.body.token;

  // Créer un produit pour les tests
  const productRes = await request(app)
    .post('/api/admin/products')
    .set('Authorization', `Bearer ${token}`)
    .send({
      name: 'Test Product',
      description: 'Test Description',
      price: 99.99,
      category: 'Test Category',
      brand: 'Test Brand',
      stock: 100,
      images: ['test-image-1.jpg']
    });

  // Créer un utilisateur pour la commande
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

  // Créer une commande
  const orderRes = await request(app)
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
        productId: productRes.body.id,
        quantity: 1
      }]
    });
  orderId = orderRes.body.id;
});

afterAll(async () => {
  await sequelize.close();
});

describe('## ADMIN ORDERS', () => {
  it('GET /api/admin/orders → doit renvoyer la liste des commandes', async () => {
    const res = await request(app)
      .get('/api/admin/orders')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('GET /api/admin/orders/:id → doit renvoyer une commande spécifique', async () => {
    const res = await request(app)
      .get(`/api/admin/orders/${orderId}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.id).toBe(orderId);
  });

  it('PUT /api/admin/orders/:id/status → doit mettre à jour le statut d\'une commande', async () => {
    const res = await request(app)
      .put(`/api/admin/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        status: 'En cours de préparation'
      });
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('En cours de préparation');
  });
}); 