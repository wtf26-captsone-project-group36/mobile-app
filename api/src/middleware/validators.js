/*function fail(res, details) {
  return res.status(400).json({ error: 'Validation failed', details });
}

function parseDateLike(value) {
  if (!value || typeof value !== 'string') return null;
  const dt = new Date(value);
  return Number.isNaN(dt.getTime()) ? null : dt;
}

const signUpValidator = (req, res, next) => {
  const { email, password, full_name, business_name, business_type, role } = req.body;
  const details = [];
  if (!email || !String(email).includes('@')) details.push({ field: 'email', message: 'Valid email is required' });
  if (!password || String(password).length < 8) details.push({ field: 'password', message: 'Password must be at least 8 characters' });
  if (!full_name) details.push({ field: 'full_name', message: 'Full name is required' });
  if (!business_name) details.push({ field: 'business_name', message: 'Business name is required' });
  if (!business_type) details.push({ field: 'business_type', message: 'Business type is required' });
  if (role && !['owner', 'manager', 'staff'].includes(role)) details.push({ field: 'role', message: 'Invalid role' });
  if (details.length) return fail(res, details);
  return next();
};

const signInValidator = (req, res, next) => {
  const { email, password } = req.body;
  const details = [];
  if (!email || !String(email).includes('@')) details.push({ field: 'email', message: 'Valid email is required' });
  if (!password) details.push({ field: 'password', message: 'Password is required' });
  if (details.length) return fail(res, details);
  return next();
};

const otpValidator = (req, res, next) => {
  const { email, otp } = req.body;
  const details = [];
  if (!email || !String(email).includes('@')) details.push({ field: 'email', message: 'Valid email is required' });
  if (!otp || !/^\d{6}$/.test(String(otp))) details.push({ field: 'otp', message: 'OTP must be a 6-digit number' });
  if (details.length) return fail(res, details);
  return next();
};

const resetPasswordValidator = (req, res, next) => {
  const { email, otp, new_password } = req.body;
  const details = [];
  if (!email || !String(email).includes('@')) details.push({ field: 'email', message: 'Valid email is required' });
  if (!otp || !/^\d{6}$/.test(String(otp))) details.push({ field: 'otp', message: 'OTP must be 6 digits' });
  if (!new_password || String(new_password).length < 8) details.push({ field: 'new_password', message: 'Password must be at least 8 characters' });
  if (details.length) return fail(res, details);
  return next();
};

const inventoryValidator = (req, res, next) => {
  const { item_name, quantity, unit, expiry_date, purchase_price } = req.body;
  const details = [];
  if (!item_name) details.push({ field: 'item_name', message: 'Item name is required' });
  if (quantity === undefined || Number(quantity) < 0 || Number.isNaN(Number(quantity))) details.push({ field: 'quantity', message: 'Quantity must be a positive number' });
  if (!unit) details.push({ field: 'unit', message: 'Unit is required' });
  if (!parseDateLike(expiry_date)) details.push({ field: 'expiry_date', message: 'Valid expiry date is required (YYYY-MM-DD)' });
  if (purchase_price !== undefined && (Number(purchase_price) < 0 || Number.isNaN(Number(purchase_price)))) {
    details.push({ field: 'purchase_price', message: 'Purchase price must be positive' });
  }
  if (details.length) return fail(res, details);
  return next();
};

const transactionValidator = (req, res, next) => {
  const { type, amount, date, transaction_date } = req.body;
  const details = [];
  if (!['income', 'expense'].includes(type)) details.push({ field: 'type', message: 'Type must be income or expense' });
  if (amount === undefined || Number(amount) <= 0 || Number.isNaN(Number(amount))) details.push({ field: 'amount', message: 'Amount must be greater than 0' });
  const txDate = date || transaction_date;
  if (txDate && !parseDateLike(txDate)) details.push({ field: 'date', message: 'Valid date is required' });
  if (details.length) return fail(res, details);
  return next();
};

const budgetValidator = (req, res, next) => {
  const { name, category, total_amount, allocated_amount, amount } = req.body;
  const details = [];
  if (!name && !category) details.push({ field: 'name', message: 'Budget name or category is required' });
  const numericAmount = total_amount ?? allocated_amount ?? amount;
  if (numericAmount === undefined || Number(numericAmount) <= 0 || Number.isNaN(Number(numericAmount))) {
    details.push({ field: 'total_amount', message: 'Total amount must be greater than 0' });
  }
  if (details.length) return fail(res, details);
  return next();
};

const expenseValidator = (req, res, next) => {
  const { category, amount, purpose, title, description } = req.body;
  const details = [];
  if (!category) details.push({ field: 'category', message: 'Category is required' });
  if (amount === undefined || Number(amount) <= 0 || Number.isNaN(Number(amount))) details.push({ field: 'amount', message: 'Amount must be greater than 0' });
  if (!purpose && !title && !description) details.push({ field: 'purpose', message: 'Purpose is required' });
  if (details.length) return fail(res, details);
  return next();
};

const expenseReviewValidator = (req, res, next) => {
  const { status, decision, rejection_reason, note } = req.body;
  const resolved = status || decision;
  const details = [];
  if (!resolved || !['approved', 'rejected'].includes(resolved)) {
    details.push({ field: 'status', message: 'Status must be approved or rejected' });
  }
  if (resolved === 'rejected' && !rejection_reason && !note) {
    details.push({ field: 'rejection_reason', message: 'Rejection reason is required when rejecting' });
  }
  if (details.length) return fail(res, details);
  return next();
};

module.exports = {
  signUpValidator,
  signInValidator,
  otpValidator,
  resetPasswordValidator,
  inventoryValidator,
  transactionValidator,
  budgetValidator,
  expenseValidator,
  expenseReviewValidator
};
*/