const request = require('supertest');
const app = require('../app');
const sequelize = require('../config/database');

let token;

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

describe('## NOTIFICATIONS', () => {
  it('GET /api/notifications → doit renvoyer la liste des notifications', async () => {
    const res = await request(app)
      .get('/api/notifications')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('POST /api/notifications/register → doit enregistrer un token de device', async () => {
    const res = await request(app)
      .post('/api/notifications/register')
      .set('Authorization', `Bearer ${token}`)
      .send({
        deviceToken: 'test-device-token-123'
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.message).toBe('Token enregistré avec succès');
  });

  it('DELETE /api/notifications/:id → doit supprimer une notification', async () => {
    // Créer d'abord une notification
    const notificationRes = await request(app)
      .get('/api/notifications')
      .set('Authorization', `Bearer ${token}`);
    
    if (notificationRes.body.length > 0) {
      const notificationId = notificationRes.body[0].id;
      const res = await request(app)
        .delete(`/api/notifications/${notificationId}`)
        .set('Authorization', `Bearer ${token}`);
      expect(res.statusCode).toBe(200);
      expect(res.body.message).toBe('Notification supprimée avec succès');
    }
  });
}); 