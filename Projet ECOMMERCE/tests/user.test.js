// tests/user.test.js
const request = require('supertest');
const app     = require('../app');
const sequelize = require('../config/database');

let token;

beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  await sequelize.sync({ force: true });

  // on crée un utilisateur et on récupère son token
  await request(app)
    .post('/api/auth/register')
    .send({
      nom:     'Test',
      prenom:  'User',
      age:     30,
      mail:    'test.user@example.com',
      password:'pwd12345'
    });

  const res = await request(app)
    .post('/api/auth/login')
    .send({
      mail:     'test.user@example.com',
      password: 'pwd12345'
    });
  token = res.body.token;
});

afterAll(async () => {
  await sequelize.close();
});

describe('## USER PROFILE', () => {
  it('GET /api/users/me → doit renvoyer le profil', async () => {
    const res = await request(app)
      .get('/api/users/me')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.mail).toBe('test.user@example.com');
    expect(res.body).not.toHaveProperty('pwd12345');
  });

  it('PUT /api/users/me → doit mettre à jour le profil', async () => {
    const res = await request(app)
      .put('/api/users/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ prenom: 'Utilisateur' });
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Profil mis à jour');

    // on vérifie que la maj est effective
    const res2 = await request(app)
      .get('/api/users/me')
      .set('Authorization', `Bearer ${token}`);
    expect(res2.body.prenom).toBe('Utilisateur');
  });

  it('DELETE /api/users/me → doit supprimer le compte', async () => {
    const res = await request(app)
      .delete('/api/users/me')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Compte supprimé');
  });
});
