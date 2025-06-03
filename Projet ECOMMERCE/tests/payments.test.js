// tests/payments.test.js
const request = require('supertest');
const app = require('../app');
const sequelize = require('../config/database');

let token;
let orderId;
let productId;

beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  await sequelize.sync({ force: true });

  // Créer un utilisateur et récupérer son token
  await request(app)
    .post('/api/auth/register')
    .send({
      nom: 'Test',
      prenom: 'User',
      age: 30,
      mail: 'test.user@example.com',
      password: 'pwd12345'
    });

  const res = await request(app)
    .post('/api/auth/login')
    .send({
      mail: 'test.user@example.com',
      password: 'pwd12345'
    });
  token = res.body.token;

  // Créer un produit pour la commande
  const productRes = await request(app)
    .post('/api/admin/products')
    .set('Authorization', `Bearer ${token}`)
    .send({
      name: 'Test Product',
      description: 'Test Description',
      price: 50.0,
      category: 'Test Category',
      brand: 'Test Brand',
      stock: 10,
      images: ['test-image.jpg']
    });
  productId = productRes.body.id || productRes.body.product?.id;

  // Créer une commande pour les tests
  const orderRes = await request(app)
    .post('/api/orders')
    .set('Authorization', `Bearer ${token}`)
    .send({
      address: {
        street: '123 Test Street',
        city: 'Test City',
        postalCode: '12345',
        country: 'Test Country'
      },
      paymentMethod: 'card',
      items: [{
        productId: productId,
        quantity: 1
      }]
    });
  orderId = orderRes.body.id;
});

afterAll(async () => {
  await sequelize.close();
});

describe('## PAYMENTS', () => {
  it('POST /api/payments → doit initier un paiement', async () => {
    const res = await request(app)
      .post('/api/payments')
      .set('Authorization', `Bearer ${token}`)
      .send({ orderId });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('sessionId');
  });

  it('GET /api/payments/:orderId → doit vérifier le statut du paiement', async () => {
    const res = await request(app)
      .get(`/api/payments/${orderId}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('status');
    expect(res.body).toHaveProperty('amount');
    expect(res.body).toHaveProperty('currency');
  });
}); 