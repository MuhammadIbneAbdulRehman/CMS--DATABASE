-- ============================================
-- ADMIN LOGIN STORED PROCEDURES
-- ============================================
-- File: adminloginsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTIONS
-- ============================================

DROP FUNCTION IF EXISTS admin_login(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS update_admin_last_login(INTEGER) CASCADE;

-- ============================================
-- 1. ADMIN LOGIN - Fetches admin by email
-- ============================================

CREATE OR REPLACE FUNCTION admin_login(
    p_email VARCHAR
)
RETURNS TABLE(
    id INTEGER,
    society_id INTEGER,
    society_name VARCHAR,
    full_name VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    password_hash TEXT,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.society_id,
        s.name AS society_name,
        a.full_name,
        a.email,
        a.phone,
        a.password_hash,
        a.is_active
    FROM administrators a
    LEFT JOIN societies s ON a.society_id = s.id
    WHERE a.email = p_email;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 2. UPDATE ADMIN LAST LOGIN
-- ============================================

CREATE OR REPLACE FUNCTION update_admin_last_login(
    p_admin_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE administrators
    SET 
        last_login = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_admin_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERIES
-- ============================================

-- SELECT * FROM admin_login('admin@example.com');
-- SELECT update_admin_last_login(1);

-- ============================================
-- END OF FILE
-- ============================================