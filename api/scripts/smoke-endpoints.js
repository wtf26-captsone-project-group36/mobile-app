/*
  Minimal API smoke checker for local/manual runs.
  Usage:
    API_BASE_URL=http://localhost:3000 ACCESS_TOKEN=<jwt> node scripts/smoke-endpoints.js
*/

const base = (process.env.API_BASE_URL || 'http://localhost:3000').replace(/\/$/, '');
const token = process.env.ACCESS_TOKEN || '';

function authHeaders() {
  if (!token) return {};
  return { Authorization: `Bearer ${token}` };
}

async function hit(name, method, path, body) {
  const url = `${base}${path}`;
  const headers = {
    'Content-Type': 'application/json',
    ...authHeaders(),
  };

  const res = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  let json = {};
  try {
    json = await res.json();
  } catch (_) {
    json = {};
  }

  const ok = res.status >= 200 && res.status < 300;
  const marker = ok ? 'OK' : 'FAIL';
  console.log(`[${marker}] ${name} -> ${res.status} ${method} ${path}`);
  if (!ok) {
    const msg = json.error || json.message || JSON.stringify(json);
    console.log(`      ${msg}`);
  }
  return { ok, status: res.status, json };
}

async function main() {
  console.log(`Base URL: ${base}`);
  if (!token) {
    console.log('ACCESS_TOKEN not set: running public checks only.');
  }

  await hit('health', 'GET', '/api/health');

  if (!token) return;

  await hit('profile', 'GET', '/api/auth/profile');
  await hit('transactions', 'GET', '/api/transactions?limit=5');
  await hit('cashflow report', 'GET', '/api/transactions/report');
  await hit('budgets', 'GET', '/api/budgets');
  await hit('expenses', 'GET', '/api/expenses?limit=5');
  await hit('expense summary', 'GET', '/api/expenses/summary');
  await hit('predictions', 'GET', '/api/predictions');
  await hit('anomalies', 'GET', '/api/predictions/anomalies');
  await hit('activity', 'GET', '/api/activity');

  // Owner-only route may return 403 for non-owner tokens; still useful signal.
  await hit('audit logs', 'GET', '/api/audit-logs?limit=5');
}

main().catch((err) => {
  console.error('Smoke run failed:', err.message);
  process.exitCode = 1;
});
