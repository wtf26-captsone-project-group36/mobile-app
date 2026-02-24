// In-memory OTP store for development.
// Replace with Redis or persistent store in production.
const otpStore = new Map();

function storeOTP(email, otp, userData) {
  otpStore.set(email, {
    otp: String(otp),
    expiresAt: Date.now() + 10 * 60 * 1000,
    userData
  });
}

function verifyOTP(email, otp) {
  const record = otpStore.get(email);
  if (!record) {
    return { valid: false, reason: 'No OTP found for this email. Please request a new one.' };
  }

  if (Date.now() > record.expiresAt) {
    otpStore.delete(email);
    return { valid: false, reason: 'OTP has expired. Please request a new one.' };
  }

  if (record.otp !== String(otp)) {
    return { valid: false, reason: 'Incorrect OTP.' };
  }

  const userData = record.userData;
  otpStore.delete(email);
  return { valid: true, userData };
}

function clearOTP(email) {
  otpStore.delete(email);
}

module.exports = { storeOTP, verifyOTP, clearOTP };
