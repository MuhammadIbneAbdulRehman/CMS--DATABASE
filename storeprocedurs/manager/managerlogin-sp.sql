-- ============================================
-- MANAGER LOGIN STORED PROCEDURE
-- ============================================
-- File: managerloginsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS manager_login(VARCHAR) CASCADE;

-- ============================================
-- MANAGER LOGIN FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION manager_login(
    p_email VARCHAR
)
RETURNS TABLE(
    manager_id INTEGER,
    manager_society_id INTEGER,
    manager_gm_id INTEGER,
    manager_full_name VARCHAR,
    manager_email VARCHAR,
    manager_phone VARCHAR,
    manager_password_hash TEXT,
    manager_department_category_id INTEGER,
    manager_is_active BOOLEAN,
    manager_created_by INTEGER,
    manager_last_login TIMESTAMP,
    manager_created_at TIMESTAMP,
    manager_updated_at TIMESTAMP,
    society_name VARCHAR,
    category_name VARCHAR
) AS $$
DECLARE
    v_manager_exists BOOLEAN;
    v_manager RECORD;
BEGIN
    -- Check if manager exists and is active
    SELECT EXISTS(
        SELECT 1 FROM managers 
        WHERE email = p_email AND is_active = true
    ) INTO v_manager_exists;
    
    IF NOT v_manager_exists THEN
        RAISE EXCEPTION 'Invalid credentials';
    END IF;
    
    -- Get manager details with society and category info
    SELECT 
        m.id,
        m.society_id,
        m.gm_id,
        m.full_name,
        m.email,
        m.phone,
        m.password_hash,
        m.department_category_id,
        m.is_active,
        m.created_by,
        m.last_login,
        m.created_at,
        m.updated_at,
        s.name as society_name,
        dc.name as category_name
    INTO v_manager
    FROM managers m
    JOIN societies s ON m.society_id = s.id
    LEFT JOIN department_categories dc ON m.department_category_id = dc.id
    WHERE m.email = p_email AND m.is_active = true;
    
    -- Update last login
    UPDATE managers 
    SET last_login = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_manager.id;
    
    -- Return manager data
    manager_id := v_manager.id;
    manager_society_id := v_manager.society_id;
    manager_gm_id := v_manager.gm_id;
    manager_full_name := v_manager.full_name;
    manager_email := v_manager.email;
    manager_phone := v_manager.phone;
    manager_password_hash := v_manager.password_hash;
    manager_department_category_id := v_manager.department_category_id;
    manager_is_active := v_manager.is_active;
    manager_created_by := v_manager.created_by;
    manager_last_login := v_manager.last_login;
    manager_created_at := v_manager.created_at;
    manager_updated_at := v_manager.updated_at;
    society_name := v_manager.society_name;
    category_name := v_manager.category_name;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM manager_login('manager@example.com');

-- ============================================
-- END OF FILE
-- ============================================