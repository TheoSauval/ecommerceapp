const request = require('supertest');
const app = require('../app');
const { User, Produit } = require('../models');

describe('## CART', () => {
  let token;
  let productId;
  let cartItemId;

  beforeAll(async () => {
    // Créer un utilisateur de test
    const user = await User.create({
      nom: 'Test',
      prenom: 'User',
      age: 25,
      mail: 'test.user@example.com',
      password: 'password123'
    });

    // Créer un produit de test
    const product = await Produit.create({
      nom: 'Test Product',
      prix: 99.99,
      quantite: 10
    });
    productId = product.id;

    // Obtenir le token
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({
        mail: 'test.user@example.com',
        password: 'password123'
      });
    token = loginRes.body.token;
  });

  afterAll(async () => {
    // Nettoyer la base de données
    await User.destroy({ where: { mail: 'test.user@example.com' } });
    await Produit.destroy({ where: { id: productId } });
  });

  test('GET /api/cart → doit renvoyer le contenu du panier', async () => {
    const res = await request(app)
      .get('/api/cart')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('items');
    expect(Array.isArray(res.body.items)).toBe(true);
  });

  test('POST /api/cart → doit ajouter un produit au panier', async () => {
    const res = await request(app)
      .post('/api/cart')
      .set('Authorization', `Bearer ${token}`)
      .send({
        productId,
        quantity: 1,
        size: 'M',
        color: 'Rouge'
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.message).toBe('Produit ajouté au panier');
    cartItemId = res.body.cartItemId;
  });

  test('PUT /api/cart/:itemId → doit modifier un item du panier', async () => {
    const res = await request(app)
      .put(`/api/cart/${cartItemId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        quantity: 2,
        size: 'L',
        color: 'Bleu'
      });
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Item du panier mis à jour');
  });

  test('DELETE /api/cart/:itemId → doit retirer un item du panier', async () => {
    const res = await request(app)
      .delete(`/api/cart/${cartItemId}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Item retiré du panier');
  });
}); 