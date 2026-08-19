-- ZuriShop database bootstrap (acts as our migration)
-- Runs automatically on first boot of the postgres container.

CREATE SCHEMA IF NOT EXISTS catalog;
CREATE SCHEMA IF NOT EXISTS inventory;
CREATE SCHEMA IF NOT EXISTS orders;

-- ============ CATALOG ============
CREATE TABLE IF NOT EXISTS catalog.products (
    id       TEXT PRIMARY KEY,
    name     TEXT NOT NULL,
    price    NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    currency TEXT NOT NULL DEFAULT 'KES'
);

INSERT INTO catalog.products (id, name, price, currency) VALUES
    ('SKU-001', 'Wireless Mouse',      1500, 'KES'),
    ('SKU-002', 'Mechanical Keyboard', 6500, 'KES'),
    ('SKU-003', 'USB-C Cable',          700, 'KES'),
    ('SKU-004', 'Laptop Stand',        3200, 'KES')
ON CONFLICT (id) DO NOTHING;

-- ============ INVENTORY ============
CREATE TABLE IF NOT EXISTS inventory.stock (
    product_id TEXT PRIMARY KEY,
    remaining  INTEGER NOT NULL CHECK (remaining >= 0)
);

INSERT INTO inventory.stock (product_id, remaining) VALUES
    ('SKU-001', 50),
    ('SKU-002', 20),
    ('SKU-003', 100),
    ('SKU-004', 10)
ON CONFLICT (product_id) DO NOTHING;

-- ============ ORDERS ============
CREATE TABLE IF NOT EXISTS orders.orders (
    order_id       TEXT PRIMARY KEY,
    cart_id        TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    total          NUMERIC(10,2) NOT NULL,
    currency       TEXT NOT NULL,
    status         TEXT NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders.orders (created_at DESC);