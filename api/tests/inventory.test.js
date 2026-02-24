const request = require('supertest');
const app = require('../src/index');

const runIntegration = process.env.RUN_INTEGRATION_TESTS === 'true';
const describeIf = runIntegration ? describe : describe.skip;

describeIf('Inventory API', () => {
  const token = process.env.TEST_ACCESS_TOKEN || '';
  let createdItemId = '';

  it('POST /api/inventory creates item', async () => {
    const res = await request(app)
      .post('/api/inventory')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Test Tomatoes',
        category: 'Produce',
        quantity: 50,
        unit: 'kg'
      });
    expect([200, 201]).toContain(res.status);
    createdItemId = res.body.item?.item_id || res.body.item?.id || '';
  });

  it('GET /api/inventory returns list', async () => {
    const res = await request(app)
      .get('/api/inventory')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.items)).toBe(true);
  });

  it('PUT /api/inventory/:id updates item', async () => {
    if (!createdItemId) return;
    const res = await request(app)
      .put(`/api/inventory/${createdItemId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ quantity: 35 });
    expect(res.status).toBe(200);
  });
});
