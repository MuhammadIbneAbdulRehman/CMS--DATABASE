-- ============================================
-- GET ADMIN PROFILE STORED PROCEDURE
-- ============================================
-- File: getadminprofilesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_admin_profile(INTEGER) CASCADE;

-- ============================================
-- GET ADMIN PROFILE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_admin_profile(
    p_admin_id INTEGER
)
RETURNS TABLE(
    id INTEGER,
    society_id INTEGER,
    full_name VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    is_active BOOLEAN,
    last_login TIMESTAMP,
    created_at TIMESTAMP,
    society_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.society_id,
        a.full_name,
        a.email,
        a.phone,
        a.is_active,
        a.last_login,
        a.created_at,
        s.name AS society_name
    FROM administrators a
    JOIN societies s ON a.society_id = s.id
    WHERE a.id = p_admin_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_admin_profile(1);

-- ============================================
-- END OF FILE
-- ============================================