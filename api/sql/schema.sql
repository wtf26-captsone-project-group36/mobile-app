-- =============================================
-- HERVEST AI SCHEMA — PostgreSQL for Supabase
-- =============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- BUSINESSES
-- =============================================
CREATE TABLE IF NOT EXISTS businesses (
  business_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  business_name VARCHAR(200) NOT NULL,
  business_type VARCHAR(100),
  currency VARCHAR(3) DEFAULT 'NGN',
  timezone VARCHAR(50) DEFAULT 'Africa/Lagos',
  current_balance DECIMAL(15,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- USERS (extends Supabase auth.users)
-- =============================================
CREATE TABLE IF NOT EXISTS users (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  business_id UUID REFERENCES businesses(business_id) ON DELETE SET NULL,
  full_name VARCHAR(200),
  email VARCHAR(200) UNIQUE NOT NULL,
  password_hash TEXT,
  role VARCHAR(50),
  phone VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- TRANSACTIONS
-- =============================================
CREATE TABLE IF NOT EXISTS transactions (
  transaction_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  business_id UUID REFERENCES businesses(business_id) ON DELETE CASCADE,
  date TIMESTAMPTZ NOT NULL,
  type VARCHAR(20) CHECK (type IN ('income', 'expense', 'refund', 'adjustment')) NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  category VARCHAR(100),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- INVENTORY
-- =============================================
CREATE TABLE IF NOT EXISTS inventory (
  item_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  business_id UUID REFERENCES businesses(business_id) ON DELETE CASCADE,
  item_name VARCHAR(200) NOT NULL,
  sku VARCHAR(120),
  quantity DECIMAL(10,2) NOT NULL,
  unit VARCHAR(50) DEFAULT 'units',
  expiry_date DATE,
  purchase_price DECIMAL(10,2),
  category VARCHAR(100),
  reorder_level DECIMAL(10,2),
  location VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- CASHFLOW PREDICTIONS
-- =============================================
CREATE TABLE IF NOT EXISTS cashflow_predictions (
  prediction_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  business_id UUID REFERENCES businesses(business_id) ON DELETE CASCADE,
  risk_level VARCHAR(20),
  days_until_broke INT,
  confidence_score DECIMAL(4,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- INVENTORY PREDICTIONS
-- =============================================
CREATE TABLE IF NOT EXISTS inventory_predictions (
  prediction_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  business_id UUID REFERENCES businesses(business_id) ON DELETE CASCADE,
  critical_items INT,
  warning_items INT,
  total_value_at_risk DECIMAL(15,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- EXPENSE ANOMALIES
-- =============================================
CREATE TABLE IF NOT EXISTS expense_anomalies (
  anomaly_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  transaction_id UUID REFERENCES transactions(transaction_id) ON DELETE CASCADE,
  anomaly_level VARCHAR(20),
  z_score DECIMAL(10,2),
  deviation_percentage DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- RISK ALERTS
-- =============================================
CREATE TABLE IF NOT EXISTS risk_alerts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  inventory_id UUID REFERENCES inventory(item_id) ON DELETE SET NULL,
  alert_type VARCHAR(50) NOT NULL,
  message TEXT NOT NULL,
  severity VARCHAR(20) DEFAULT 'medium',
  metadata JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  is_resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- SURPLUS
-- =============================================
CREATE TABLE IF NOT EXISTS surplus (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  claimer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  inventory_id UUID REFERENCES inventory(item_id) ON DELETE SET NULL,
  name VARCHAR(255) NOT NULL,
  quantity DECIMAL(10,2) NOT NULL,
  unit VARCHAR(50) DEFAULT 'units',
  description TEXT,
  expiry_date DATE,
  pickup_deadline TIMESTAMPTZ,
  is_free BOOLEAN DEFAULT TRUE,
  price DECIMAL(10,2) DEFAULT 0,
  location VARCHAR(255),
  status VARCHAR(20) DEFAULT 'available',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- ACTIVITY LOG
-- =============================================
CREATE TABLE IF NOT EXISTS activity_log (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  action VARCHAR(120) NOT NULL,
  entity_type VARCHAR(80),
  entity_id UUID,
  details JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- INDEXES
-- =============================================
CREATE INDEX IF NOT EXISTS idx_users_business ON users(business_id);
CREATE INDEX IF NOT EXISTS idx_transactions_business ON transactions(business_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_inventory_business ON inventory(business_id);
CREATE INDEX IF NOT EXISTS idx_inventory_expiry ON inventory(expiry_date);
CREATE INDEX IF NOT EXISTS idx_cashflow_predictions_business ON cashflow_predictions(business_id);
CREATE INDEX IF NOT EXISTS idx_inventory_predictions_business ON inventory_predictions(business_id);
CREATE INDEX IF NOT EXISTS idx_alerts_user ON risk_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_surplus_status ON surplus(status);
CREATE INDEX IF NOT EXISTS idx_activity_user ON activity_log(user_id);

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE cashflow_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE surplus ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own row" ON users
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users see own business" ON businesses
  FOR ALL USING (
    business_id IN (SELECT business_id FROM users WHERE user_id = auth.uid())
  );

CREATE POLICY "Users see own transactions" ON transactions
  FOR ALL USING (
    business_id IN (SELECT business_id FROM users WHERE user_id = auth.uid())
  );

CREATE POLICY "Users see own inventory" ON inventory
  FOR ALL USING (
    business_id IN (SELECT business_id FROM users WHERE user_id = auth.uid())
  );

CREATE POLICY "Users see own cashflow predictions" ON cashflow_predictions
  FOR ALL USING (
    business_id IN (SELECT business_id FROM users WHERE user_id = auth.uid())
  );

CREATE POLICY "Users see own inventory predictions" ON inventory_predictions
  FOR ALL USING (
    business_id IN (SELECT business_id FROM users WHERE user_id = auth.uid())
  );

CREATE POLICY "Users see own anomalies" ON expense_anomalies
  FOR ALL USING (
    transaction_id IN (
      SELECT transaction_id FROM transactions
      WHERE business_id IN (SELECT business_id FROM users WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Users see own alerts" ON risk_alerts
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users see marketplace surplus" ON surplus
  FOR SELECT USING (status = 'available' OR owner_id = auth.uid() OR claimer_id = auth.uid());

CREATE POLICY "Users own activity" ON activity_log
  FOR ALL USING (user_id = auth.uid());

-- =============================================
-- REALTIME
-- =============================================
ALTER PUBLICATION supabase_realtime ADD TABLE inventory;
ALTER PUBLICATION supabase_realtime ADD TABLE cashflow_predictions;
ALTER PUBLICATION supabase_realtime ADD TABLE inventory_predictions;
ALTER PUBLICATION supabase_realtime ADD TABLE expense_anomalies;
ALTER PUBLICATION supabase_realtime ADD TABLE risk_alerts;
