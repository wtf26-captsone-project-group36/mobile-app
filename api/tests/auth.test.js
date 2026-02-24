const request = require('supertest');
const app = require('../src/index');

const runIntegration = process.env.RUN_INTEGRATION_TESTS === 'true';
const describeIf = runIntegration ? describe : describe.skip;

describeIf('Auth API', () => {
  const uniqueEmail = `test_${Date.now()}@example.com`;
  const password = 'TestPassword123!';
  let otp = '';
  let accessToken = '';
  let refreshToken = '';

  it('POST /api/auth/signup', async () => {
    const res = await request(app).post('/api/auth/signup').send({
      email: uniqueEmail,
      password,
      full_name: 'Test User',
      business_type: 'restaurant',
      business_name: 'Test Kitchen',
      role: 'owner'
    });
    expect([200, 201]).toContain(res.status);
  });

  it('POST /api/auth/signup/verify', async () => {
    // OTP is delivered via email in real flow. For integration automation,
    // set TEST_SIGNUP_OTP manually after reading your mailbox.
    otp = process.env.TEST_SIGNUP_OTP || '';
    if (!otp) return;
    const res = await request(app).post('/api/auth/signup/verify').send({ email: uniqueEmail, otp });
    expect([200, 201]).toContain(res.status);
  });

  it('POST /api/auth/signin', async () => {
    const res = await request(app).post('/api/auth/signin').send({ email: uniqueEmail, password });
    expect(res.status).toBe(200);
    expect(res.body.access_token).toBeDefined();
    expect(res.body.refresh_token).toBeDefined();
    accessToken = res.body.access_token;
    refreshToken = res.body.refresh_token;
  });

  it('GET /api/auth/profile', async () => {
    const res = await request(app).get('/api/auth/profile').set('Authorization', `Bearer ${accessToken}`);
    expect(res.status).toBe(200);
  });

  it('POST /api/auth/refresh', async () => {
    const res = await request(app).post('/api/auth/refresh').send({ refresh_token: refreshToken });
    expect(res.status).toBe(200);
    expect(res.body.access_token).toBeDefined();
  });
});
