-- ============================================
-- ADMIN SIGNUP STORED PROCEDURES
-- ============================================
-- File: adminsignupsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTIONS
-- ============================================

DROP FUNCTION IF EXISTS check_society_exists(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS check_admin_email_exists(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS create_admin(INTEGER, VARCHAR, VARCHAR, VARCHAR, TEXT) CASCADE;

-- ============================================
-- 1. CHECK SOCIETY EXISTS
-- ============================================

CREATE OR REPLACE FUNCTION check_society_exists(
    p_society_id INTEGER
)
RETURNS TABLE(
    society_id INTEGER,
    society_name VARCHAR,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        id,
        name,
        is_active
    FROM societies 
    WHERE id = p_society_id AND is_active = true;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 2. CHECK ADMIN EMAIL EXISTS
-- ============================================

CREATE OR REPLACE FUNCTION check_admin_email_exists(
    p_email VARCHAR
)
RETURNS TABLE(
    admin_id INTEGER,
    admin_email VARCHAR,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        id,
        email,
        is_active
    FROM administrators 
    WHERE email = p_email;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 3. CREATE ADMIN
-- ============================================

CREATE OR REPLACE FUNCTION create_admin(
    p_society_id INTEGER,
    p_full_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_password_hash TEXT
)
RETURNS TABLE(
    admin_id INTEGER,
    admin_society_id INTEGER,
    admin_full_name VARCHAR,
    admin_email VARCHAR,
    admin_phone VARCHAR,
    admin_is_active BOOLEAN,
    admin_created_at TIMESTAMP
) AS $$
DECLARE
    v_society_exists BOOLEAN;
    v_email_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Check if society exists and is active
    SELECT EXISTS(
        SELECT 1 FROM societies 
        WHERE id = p_society_id AND is_active = true
    ) INTO v_society_exists;
    
    IF NOT v_society_exists THEN
        RAISE EXCEPTION 'Society not found or inactive';
    END IF;
    
    -- Check if email already exists
    SELECT EXISTS(
        SELECT 1 FROM administrators WHERE email = p_email
    ) INTO v_email_exists;
    
    IF v_email_exists THEN
        RAISE EXCEPTION 'Email already registered';
    END IF;
    
    -- Insert the admin
    INSERT INTO administrators (
        society_id,
        full_name,
        email,
        phone,
        password_hash,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_society_id,
        p_full_name,
        p_email,
        p_phone,
        p_password_hash,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING 
        id,
        society_id,
        full_name,
        email,
        phone,
        is_active,
        created_at
    INTO v_result;
    
    -- Return the inserted admin
    admin_id := v_result.id;
    admin_society_id := v_result.society_id;
    admin_full_name := v_result.full_name;
    admin_email := v_result.email;
    admin_phone := v_result.phone;
    admin_is_active := v_result.is_active;
    admin_created_at := v_result.created_at;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERIES
-- ============================================

-- SELECT * FROM check_society_exists(1);
-- SELECT * FROM check_admin_email_exists('admin@example.com');
-- SELECT * FROM create_admin(1, 'Admin User', 'admin@example.com', '1234567890', 'hashed_password');

-- ============================================
-- END OF FILE
-- ============================================