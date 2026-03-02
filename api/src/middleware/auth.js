const { supabaseAdmin } = require('../config/supabase');

/**
 * Verifies the Supabase JWT from Authorization: Bearer <token>
 * Attaches req.user (auth user) and req.profile (users + businesses row)
 */
async function authenticate(req, res, next) {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }

  const token = authHeader.split(' ')[1];

  if (!token || token.length < 10) {
    return res.status(401).json({ error: 'Malformed token' });
  }

  try {
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    // Fetch user profile with business data
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('users')
      .select('*, businesses(*)')
      .eq('user_id', user.id)
      .single();

    if (profileError || !profile) {
      return res.status(401).json({ error: 'User profile not found. Please complete registration.' });
    }

    req.user = user;
    req.profile = profile;
    req.token = token;
    next();
  } catch (err) {
    console.error('[Auth Middleware]', err.message);
    return res.status(500).json({ error: 'Authentication error' });
  }
}

/**
 * Role-based access control middleware
 *
 * Role hierarchy:
 *   owner   — full access to everything
 *   manager — can approve expenses, manage inventory and budgets
 *   staff   — can submit expenses, view inventory, view their own data
 *
 * Usage: requireRole('owner', 'manager')
 */
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.profile) {
      return res.status(401).json({ error: 'Not authenticated' });
    }

    if (!roles.includes(req.profile.role)) {
      return res.status(403).json({
        error: 'Access denied',
        required_roles: roles,
        your_role: req.profile.role
      });
    }

    next();
  };
}

module.exports = { authenticate, requireRole };



/*const { supabaseAdmin } = require('../config/supabase');

async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    const { data: profile, error: profileError } = await supabaseAdmin
      .from('users')
      .select('*, businesses(*)')
      .eq('user_id', user.id)
      .single();

    if (profileError || !profile) {
      return res.status(401).json({ error: 'User profile not found' });
    }

    req.user = user;
    req.profile = profile;
    req.token = token;
    return next();
  } catch (err) {
    return res.status(500).json({ error: 'Authentication error', details: err.message });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.profile) {
      return res.status(401).json({ error: 'Not authenticated' });
    }
    if (!roles.includes(req.profile.role)) {
      return res.status(403).json({
        error: `Access denied. Required roles: ${roles.join(', ')}`
      });
    }
    return next();
  };
}

module.exports = { authenticate, requireRole };
*/