-- ============================================
-- SOCIETY LOGIN STORED PROCEDURES
-- ============================================
-- File: societyloginsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTIONS
-- ============================================

DROP FUNCTION IF EXISTS society_login(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS update_society_last_login(INTEGER) CASCADE;

-- ============================================
-- 1. SOCIETY LOGIN - Fetches society by admin email
-- ============================================

CREATE OR REPLACE FUNCTION society_login(
    p_email VARCHAR
)
RETURNS TABLE(
    id INTEGER,
    name VARCHAR,
    description TEXT,
    address TEXT,
    city VARCHAR,
    state VARCHAR,
    pincode VARCHAR,
    admin_name VARCHAR,
    admin_email VARCHAR,
    admin_password VARCHAR,
    admin_phone VARCHAR,
    admin_profile_pic VARCHAR,
    admin_last_login TIMESTAMP,
    total_units INTEGER,
    total_residents INTEGER,
    is_active BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.description,
        s.address,
        s.city,
        s.state,
        s.pincode,
        s.admin_name,
        s.admin_email,
        s.admin_password,
        s.admin_phone,
        s.admin_profile_pic,
        s.admin_last_login,
        s.total_units,
        s.total_residents,
        s.is_active,
        s.created_at,
        s.updated_at
    FROM societies s
    WHERE s.admin_email = p_email;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 2. UPDATE SOCIETY LAST LOGIN
-- ============================================

CREATE OR REPLACE FUNCTION update_society_last_login(
    p_society_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE societies
    SET 
        admin_last_login = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_society_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERIES
-- ============================================

-- SELECT * FROM society_login('admin@example.com');
-- SELECT update_society_last_login(1);

-- ============================================
-- END OF FILE
-- ============================================