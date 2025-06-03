const request = require('supertest');
const app = require('../../app');
const sequelize = require('../../config/database');
const { Vendeur } = require('../../models');

let token;
let productId;
let vendorId;

beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  await sequelize.sync({ force: true });

  // Créer un vendeur et récupérer son token
  const userRes = await request(app)
    .post('/api/auth/register')
    .send({
      nom: 'Test',
      prenom: 'Vendor',
      age: 30,
      mail: 'test.vendor@example.com',
      password: 'pwd12345',
      role: 'vendor'
    });

  // Créer un vendeur associé à l'utilisateur
  const vendor = await Vendeur.create({
    nom: 'Test Vendor'
  });
  vendorId = vendor.id;

  const res = await request(app)
    .post('/api/auth/login')
    .send({
      mail: 'test.vendor@example.com',
      password: 'pwd12345'
    });
  token = res.body.token;
});

afterAll(async () => {
  await sequelize.close();
});

describe('## ADMIN PRODUCTS', () => {
  it('GET /api/admin/products → doit renvoyer la liste des produits', async () => {
    const res = await request(app)
      .get('/api/admin/products')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /api/admin/products → doit créer un produit', async () => {
    const res = await request(app)
      .post('/api/admin/products')
      .set('Authorization', `Bearer ${token}`)
      .send({
        nom: 'Test Product',
        description: 'Test Description',
        prix: 99.99,
        categorie: 'Test Category',
        marque: 'Test Brand',
        quantite: 100,
        vendeur_id: vendorId,
        images: ['test-image-1.jpg', 'test-image-2.jpg']
      });
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('id');
    productId = res.body.id;
  });

  it('GET /api/admin/products/:id → doit renvoyer un produit spécifique', async () => {
    const res = await request(app)
      .get(`/api/admin/products/${productId}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.id).toBe(productId);
  });

  it('PUT /api/admin/products/:id → doit mettre à jour un produit', async () => {
    const res = await request(app)
      .put(`/api/admin/products/${productId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        nom: 'Updated Product',
        prix: 149.99
      });
    expect(res.statusCode).toBe(200);
    expect(res.body.nom).toBe('Updated Product');
    expect(res.body.prix).toBe(149.99);
  });

  it('POST /api/admin/products/:id/heights → doit ajouter une hauteur', async () => {
    const res = await request(app)
      .post(`/api/admin/products/${productId}/heights`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        hauteur: 180
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.taille).toBe(180);
  });

  it('POST /api/admin/products/:id/colors → doit ajouter une couleur', async () => {
    const res = await request(app)
      .post(`/api/admin/products/${productId}/colors`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        couleur: 'red'
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.couleur).toBe('red');
  });

  it('DELETE /api/admin/products/:id → doit supprimer un produit', async () => {
    const res = await request(app)
      .delete(`/api/admin/products/${productId}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Produit supprimé avec succès');
  });
}); 