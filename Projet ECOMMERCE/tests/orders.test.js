const request = require('supertest');
const app = require('../app');
const sequelize = require('../config/database');

let token;
let orderId;

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

  // Créer un produit pour les tests
  await request(app)
    .post('/api/products')
    .set('Authorization', `Bearer ${token}`)
    .send({
      nom: 'Test Product',
      prix: 99.99,
      quantite: 10
    });
});

afterAll(async () => {
  await sequelize.close();
});

describe('## ORDERS', () => {
  it('GET /api/orders → doit renvoyer la liste des commandes', async () => {
    const res = await request(app)
      .get('/api/orders')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /api/orders → doit créer une commande', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({
        items: [
          {
            productId: 1,
            quantity: 1
          }
        ],
        adresse_livraison: {
          rue: '123 Test Street',
          ville: 'Test City',
          code_postal: '12345',
          pays: 'Test Country'
        },
        methode_paiement: 'card'
      });
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.status).toBe('En attente');
    orderId = res.body.id;
  });

  it('GET /api/orders/:id → doit renvoyer une commande spécifique', async () => {
    const res = await request(app)
      .get(`/api/orders/${orderId}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.id).toBe(orderId);
  });

  it('PUT /api/orders/:id/cancel → doit annuler une commande', async () => {
    const res = await request(app)
      .put(`/api/orders/${orderId}/cancel`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('Annulée');
  });
}); 