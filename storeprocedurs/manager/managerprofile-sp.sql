-- ============================================
-- GET MANAGER PROFILE STORED PROCEDURE
-- ============================================
-- File: getmanagerprofilesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_manager_profile(INTEGER) CASCADE;

-- ============================================
-- GET MANAGER PROFILE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_manager_profile(
    p_manager_id INTEGER
)
RETURNS TABLE(
    manager_id INTEGER,
    manager_society_id INTEGER,
    manager_gm_id INTEGER,
    manager_full_name VARCHAR,
    manager_email VARCHAR,
    manager_phone VARCHAR,
    manager_department_category_id INTEGER,
    manager_is_active BOOLEAN,
    manager_last_login TIMESTAMP,
    manager_created_at TIMESTAMP,
    manager_updated_at TIMESTAMP,
    society_name VARCHAR,
    category_name VARCHAR
) AS $$
DECLARE
    v_manager_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Check if manager exists
    SELECT EXISTS(
        SELECT 1 FROM managers WHERE id = p_manager_id
    ) INTO v_manager_exists;
    
    IF NOT v_manager_exists THEN
        RAISE EXCEPTION 'Manager not found';
    END IF;
    
    -- Get manager profile with society and category info
    SELECT
        m.id,
        m.society_id,
        m.gm_id,
        m.full_name,
        m.email,
        m.phone,
        m.department_category_id,
        m.is_active,
        m.last_login,
        m.created_at,
        m.updated_at,
        s.name as society_name,
        dc.name as category_name
    INTO v_result
    FROM managers m
    JOIN societies s ON m.society_id = s.id
    LEFT JOIN department_categories dc ON m.department_category_id = dc.id
    WHERE m.id = p_manager_id;
    
    -- Return the profile
    manager_id := v_result.id;
    manager_society_id := v_result.society_id;
    manager_gm_id := v_result.gm_id;
    manager_full_name := v_result.full_name;
    manager_email := v_result.email;
    manager_phone := v_result.phone;
    manager_department_category_id := v_result.department_category_id;
    manager_is_active := v_result.is_active;
    manager_last_login := v_result.last_login;
    manager_created_at := v_result.created_at;
    manager_updated_at := v_result.updated_at;
    society_name := v_result.society_name;
    category_name := v_result.category_name;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_manager_profile(1);

-- ============================================
-- END OF FILE
-- ============================================