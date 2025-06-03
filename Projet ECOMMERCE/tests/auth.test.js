// tests/auth.test.js
const request = require('supertest');
const app     = require('../app');
const sequelize = require('../config/database');

let refreshToken, resetToken;

beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  await sequelize.sync({ force: true });
});

afterAll(async () => {
  await sequelize.close();
});

describe('## AUTH', () => {
  it('POST /api/auth/register → doit créer un utilisateur', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        nom:     'Test',
        prenom:  'User',
        age:     30,
        mail:    'test.user@example.com',
        password:'pwd12345'
      });
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.mail).toBe('test.user@example.com');
  });

  it('POST /api/auth/login → doit renvoyer token et refreshToken', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        mail:     'test.user@example.com',
        password: 'pwd12345'
      });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('token');
    expect(res.body).toHaveProperty('refreshToken');
    refreshToken = res.body.refreshToken;
  });

  it('POST /api/auth/refresh → doit renvoyer un nouveau token', async () => {
    const res = await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('token');
  });

  it('POST /api/auth/reset → doit générer un resetToken', async () => {
    const res = await request(app)
      .post('/api/auth/reset')
      .send({ mail: 'test.user@example.com' });
    expect(res.statusCode).toBe(200);
    // on récupère le token en mode test
    expect(res.body).toHaveProperty('resetToken');
    resetToken = res.body.resetToken;
  });

  it('PUT /api/auth/reset/:token → doit réinitialiser le mot de passe', async () => {
    const res = await request(app)
      .put(`/api/auth/reset/${resetToken}`)
      .send({ password: 'newPwd123' });
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Mot de passe mis à jour');
  });

  it('POST /api/auth/login (nouveau mdp) → doit fonctionner', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        mail:     'test.user@example.com',
        password: 'newPwd123'
      });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('token');
    expect(res.body).toHaveProperty('refreshToken');
  });
});
