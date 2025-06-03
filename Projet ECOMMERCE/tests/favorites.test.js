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
      password: 'pwd12345',
      role: 'vendor'
    });

  const res = await request(app)
    .post('/api/auth/login')
    .send({
      mail: 'test.user@example.com',
      password: 'pwd12345'
    });
  token = res.body.token;

  // Créer un produit pour les tests et stocker son id
  const productRes = await request(app)
    .post('/api/admin/products')
    .set('Authorization', `Bearer ${token}`)
    .send({
      nom: 'Test Product',
      prix: 99.99,
      quantite: 10
    });
  productId = productRes.body.id;
});

afterAll(async () => {
  await sequelize.close();
});

describe('## FAVORITES', () => {
  it('GET /api/users/me/favorites → doit renvoyer la liste des favoris', async () => {
    const res = await request(app)
      .get('/api/users/me/favorites')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /api/users/me/favorites → doit ajouter un produit aux favoris', async () => {
    const res = await request(app)
      .post('/api/users/me/favorites')
      .set('Authorization', `Bearer ${token}`)
      .send({ productId });
    expect(res.statusCode).toBe(201);
    expect(res.body.message).toBe('Produit ajouté aux favoris');
  });

  it('DELETE /api/users/me/favorites/:id → doit retirer un produit des favoris', async () => {
    const res = await request(app)
      .delete(`/api/users/me/favorites/${productId}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Produit retiré des favoris');
  });
}); 