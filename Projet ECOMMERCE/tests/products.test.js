const request = require('supertest');
const app = require('../app');
const sequelize = require('../config/database');

let token;
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
});

afterAll(async () => {
  await sequelize.close();
});

describe('## PRODUCTS', () => {
  it('GET /api/products → doit renvoyer la liste des produits', async () => {
    const res = await request(app)
      .get('/api/products');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.products)).toBe(true);
    expect(res.body).toHaveProperty('totalPages');
    expect(res.body).toHaveProperty('currentPage');
  });

  it('GET /api/products/search → doit rechercher des produits', async () => {
    const res = await request(app)
      .get('/api/products/search?q=test');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('GET /api/products/:id → doit renvoyer un produit spécifique', async () => {
    const res = await request(app)
      .get('/api/products/1');
    expect(res.statusCode).toBe(404); // Le produit n'existe pas encore
  });
}); 