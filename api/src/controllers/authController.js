const { supabase, supabaseAdmin } = require('../config/supabase');
const { sendOTPEmail, sendPasswordResetEmail } = require('../utils/mailer');
const { storeOTP, verifyOTP, clearOTP } = require('../utils/otpStore');
const { generateOTP } = require('../utils/generateOTP');

const VALID_BUSINESS_TYPES = [
  'restaurant', 'store', 'farmer', 'bakery', 'cafe',
  'supermarket', 'butcher', 'fishmonger', 'pharmacy',
  'wholesaler', 'food_truck', 'catering'
];
const VALID_ROLES = ['owner', 'manager', 'staff'];

async function cleanupUnverifiedUsers() {
  try {
    const { data: { users }, error } = await supabaseAdmin.auth.admin.listUsers();
    if (error) return;
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
    for (const user of users) {
      if (!user.email_confirmed_at && new Date(user.created_at) < tenMinutesAgo) {
        // eslint-disable-next-line no-await-in-loop
        await supabaseAdmin.auth.admin.deleteUser(user.id);
      }
    }
  } catch (_) {
    // Best-effort cleanup.
  }
}

async function signUp(req, res) {
  await cleanupUnverifiedUsers();
  const {
    email, password, full_name,
    business_type, role = 'owner',
    business_name, phone
  } = req.body;

  if (!email || !password || !full_name || !business_type || !business_name) {
    return res.status(400).json({
      error: 'email, password, full_name, business_type, and business_name are required'
    });
  }
  if (!VALID_BUSINESS_TYPES.includes(business_type)) {
    return res.status(400).json({ error: 'Invalid business_type', valid_options: VALID_BUSINESS_TYPES });
  }
  if (!VALID_ROLES.includes(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }
  if (String(password).length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters' });
  }

  try {
    const { data: { users }, error } = await supabaseAdmin.auth.admin.listUsers();
    if (error) return res.status(500).json({ error: error.message });

    const existingUser = users.find((u) => u.email === email);
    if (existingUser) {
      if (existingUser.email_confirmed_at) {
        return res.status(409).json({ error: 'Email already registered' });
      }
      await supabaseAdmin.auth.admin.deleteUser(existingUser.id);
      clearOTP(email);
    }

    const otp = generateOTP();
    storeOTP(email, otp, {
      password,
      full_name,
      business_type,
      business_name,
      role,
      phone: phone || null
    });

    await sendOTPEmail(email, otp);
    return res.status(200).json({
      message: 'Verification code sent to your email. Please verify to complete signup.',
      email
    });
  } catch (err) {
    return res.status(500).json({ error: 'Sign up failed', details: err.message });
  }
}

async function verifySignup(req, res) {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).json({ error: 'email and otp are required' });
  }

  try {
    const result = verifyOTP(email, otp);
    if (!result.valid) {
      return res.status(400).json({ error: result.reason });
    }

    const { password, full_name, business_type, business_name, role, phone } = result.userData;

    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name, business_type, business_name, role, phone }
    });
    if (authError) return res.status(500).json({ error: 'Failed to create account', details: authError.message });

    const userId = authData.user.id;
    const { data: business, error: businessError } = await supabaseAdmin
      .from('businesses')
      .insert({
        business_name,
        business_type,
        currency: 'NGN',
        timezone: 'Africa/Lagos'
      })
      .select()
      .single();
    if (businessError) {
      await supabaseAdmin.auth.admin.deleteUser(userId);
      return res.status(500).json({ error: 'Failed to create business', details: businessError.message });
    }

    const { data: profile, error: profileError } = await supabaseAdmin
      .from('users')
      .insert({
        user_id: userId,
        business_id: business.business_id,
        full_name,
        email,
        role: role || 'owner'
      })
      .select()
      .single();
    if (profileError) {
      await supabaseAdmin.auth.admin.deleteUser(userId);
      await supabaseAdmin.from('businesses').delete().eq('business_id', business.business_id);
      return res.status(500).json({ error: 'Failed to create user profile', details: profileError.message });
    }

    const { data: sessionData, error: sessionError } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    if (sessionError) {
      return res.status(500).json({
        error: 'Account created but failed to sign in automatically. Please sign in manually.',
        details: sessionError.message
      });
    }

    return res.status(201).json({
      message: 'Account verified and created successfully',
      access_token: sessionData.session.access_token,
      refresh_token: sessionData.session.refresh_token,
      expires_at: sessionData.session.expires_at,
      user: {
        id: userId,
        email,
        full_name: profile.full_name,
        role: profile.role,
        business: {
          business_id: business.business_id,
          business_name: business.business_name,
          business_type: business.business_type
        }
      }
    });
  } catch (err) {
    return res.status(500).json({ error: 'Verification failed', details: err.message });
  }
}

async function signIn(req, res) {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'email and password are required' });

  try {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return res.status(401).json({ error: 'Invalid credentials' });

    const { data: profile } = await supabaseAdmin
      .from('users')
      .select('*, businesses(*)')
      .eq('user_id', data.user.id)
      .single();

    return res.status(200).json({
      message: 'Login successful',
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_at: data.session.expires_at,
      user: {
        id: data.user.id,
        email: data.user.email,
        full_name: profile?.full_name || null,
        role: profile?.role || null,
        business: {
          business_id: profile?.businesses?.business_id || null,
          business_name: profile?.businesses?.business_name || null,
          business_type: profile?.businesses?.business_type || null,
          current_balance: profile?.businesses?.current_balance || null
        }
      }
    });
  } catch (err) {
    return res.status(500).json({ error: 'Sign in failed', details: err.message });
  }
}

async function signOut(req, res) {
  try {
    const { error } = await supabase.auth.signOut();
    if (error) return res.status(400).json({ error: error.message });
    return res.status(200).json({ message: 'Logged out successfully' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function refreshToken(req, res) {
  const { refresh_token } = req.body;
  if (!refresh_token) return res.status(400).json({ error: 'refresh_token is required' });
  try {
    const { data, error } = await supabase.auth.refreshSession({ refresh_token });
    if (error) return res.status(401).json({ error: error.message });
    return res.status(200).json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_at: data.session.expires_at
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function sendPasswordResetOTP(req, res) {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'email is required' });
  try {
    const { data: { users }, error } = await supabaseAdmin.auth.admin.listUsers();
    if (error) return res.status(500).json({ error: error.message });

    const existingUser = users.find((u) => u.email === email);
    if (!existingUser || !existingUser.email_confirmed_at) {
      return res.status(200).json({
        message: 'If this email is registered, a password reset code has been sent'
      });
    }

    const otp = generateOTP();
    storeOTP(email, otp, { type: 'password_reset' });
    await sendPasswordResetEmail(email, otp);
    return res.status(200).json({
      message: 'If this email is registered, a password reset code has been sent'
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function verifyOTPAndResetPassword(req, res) {
  const { email, otp, new_password } = req.body;
  if (!email || !otp || !new_password) {
    return res.status(400).json({ error: 'email, otp, and new_password are required' });
  }
  if (String(new_password).length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters' });
  }

  try {
    const result = verifyOTP(email, otp);
    if (!result.valid) return res.status(400).json({ error: result.reason });

    const { data: { users }, error } = await supabaseAdmin.auth.admin.listUsers();
    if (error) return res.status(500).json({ error: error.message });
    const existingUser = users.find((u) => u.email === email);
    if (!existingUser) return res.status(404).json({ error: 'User not found' });

    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(existingUser.id, {
      password: new_password
    });
    if (updateError) return res.status(400).json({ error: updateError.message });
    return res.status(200).json({ message: 'Password reset successfully' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function getProfile(req, res) {
  return res.status(200).json({ user: req.profile });
}

async function updateProfile(req, res) {
  const { full_name, role, business_name, business_type, phone } = req.body;

  const userUpdates = {};
  if (full_name) userUpdates.full_name = full_name;
  if (phone) userUpdates.phone = phone;
  if (role) {
    if (!VALID_ROLES.includes(role)) return res.status(400).json({ error: 'Invalid role' });
    userUpdates.role = role;
  }

  const businessUpdates = {};
  if (business_name) businessUpdates.business_name = business_name;
  if (business_type) {
    if (!VALID_BUSINESS_TYPES.includes(business_type)) {
      return res.status(400).json({ error: 'Invalid business_type', valid_options: VALID_BUSINESS_TYPES });
    }
    businessUpdates.business_type = business_type;
  }

  try {
    if (Object.keys(userUpdates).length) {
      const { error } = await supabaseAdmin.from('users').update(userUpdates).eq('user_id', req.user.id);
      if (error) return res.status(400).json({ error: error.message });
    }

    if (Object.keys(businessUpdates).length) {
      const { error } = await supabaseAdmin
        .from('businesses')
        .update(businessUpdates)
        .eq('business_id', req.profile.business_id);
      if (error) return res.status(400).json({ error: error.message });
    }

    const { data: updatedProfile } = await supabaseAdmin
      .from('users')
      .select('*, businesses(*)')
      .eq('user_id', req.user.id)
      .single();

    return res.status(200).json({ message: 'Profile updated', user: updatedProfile });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function deleteUser(req, res) {
  const { id } = req.params;
  try {
    const { data: targetUser, error } = await supabaseAdmin
      .from('users')
      .select('user_id, business_id')
      .eq('user_id', id)
      .single();
    if (error || !targetUser) return res.status(404).json({ error: 'User not found' });

    if (targetUser.business_id !== req.profile.business_id) {
      return res.status(403).json({ error: 'Cannot delete users outside your business' });
    }

    const { error: usersDeleteError } = await supabaseAdmin.from('users').delete().eq('user_id', id);
    if (usersDeleteError) return res.status(400).json({ error: usersDeleteError.message });

    const { error: authDeleteError } = await supabaseAdmin.auth.admin.deleteUser(id);
    if (authDeleteError) return res.status(400).json({ error: authDeleteError.message });

    return res.status(200).json({ message: 'User deleted successfully' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = {
  signUp,
  verifySignup,
  signIn,
  signOut,
  refreshToken,
  sendPasswordResetOTP,
  verifyOTPAndResetPassword,
  getProfile,
  updateProfile,
  deleteUser
};
