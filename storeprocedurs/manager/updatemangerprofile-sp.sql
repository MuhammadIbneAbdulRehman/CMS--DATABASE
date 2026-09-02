-- ============================================
-- UPDATE MANAGER PROFILE STORED PROCEDURE
-- ============================================
-- File: updatemanagerprofilesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS update_manager_profile(INTEGER, VARCHAR, VARCHAR) CASCADE;

-- ============================================
-- UPDATE MANAGER PROFILE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_manager_profile(
    p_manager_id INTEGER,
    p_full_name VARCHAR,
    p_phone VARCHAR
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
    manager_updated_at TIMESTAMP,
    old_full_name VARCHAR,
    old_phone VARCHAR,
    old_email VARCHAR,
    society_name VARCHAR,
    updated_fields TEXT
) AS $$
DECLARE
    v_old_data RECORD;
    v_society_name VARCHAR;
    v_phone_exists BOOLEAN;
    v_result RECORD;
    v_updated_fields TEXT := '';
BEGIN
    -- Get current manager data before update
    SELECT 
        m.id,
        m.full_name,
        m.email,
        m.phone,
        m.society_id,
        s.name as society_name
    INTO v_old_data
    FROM managers m
    LEFT JOIN societies s ON m.society_id = s.id
    WHERE m.id = p_manager_id;
    
    -- Check if manager exists
    IF v_old_data.id IS NULL THEN
        RAISE EXCEPTION 'Manager not found';
    END IF;
    
    -- Set society name
    v_society_name := v_old_data.society_name;
    
    -- Check phone uniqueness if changing
    IF p_phone IS NOT NULL AND p_phone != v_old_data.phone THEN
        SELECT EXISTS(
            SELECT 1 FROM managers 
            WHERE phone = p_phone AND id != p_manager_id
        ) INTO v_phone_exists;
        
        IF v_phone_exists THEN
            RAISE EXCEPTION 'Phone number already in use';
        END IF;
    END IF;
    
    -- Track updated fields
    IF p_full_name IS NOT NULL AND p_full_name != v_old_data.full_name THEN
        v_updated_fields := v_updated_fields || 'Full Name, ';
    END IF;
    
    IF p_phone IS NOT NULL AND p_phone != v_old_data.phone THEN
        v_updated_fields := v_updated_fields || 'Phone, ';
    END IF;
    
    -- Remove trailing comma and space
    IF v_updated_fields != '' THEN
        v_updated_fields := LEFT(v_updated_fields, LENGTH(v_updated_fields) - 2);
    END IF;
    
    -- Update the manager
    UPDATE managers
    SET full_name = COALESCE(p_full_name, full_name),
        phone = COALESCE(p_phone, phone),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_manager_id
    RETURNING 
        id,
        society_id,
        gm_id,
        full_name,
        email,
        phone,
        department_category_id,
        is_active,
        last_login,
        updated_at
    INTO v_result;
    
    -- Return the updated profile with old data for comparison
    manager_id := v_result.id;
    manager_society_id := v_result.society_id;
    manager_gm_id := v_result.gm_id;
    manager_full_name := v_result.full_name;
    manager_email := v_result.email;
    manager_phone := v_result.phone;
    manager_department_category_id := v_result.department_category_id;
    manager_is_active := v_result.is_active;
    manager_last_login := v_result.last_login;
    manager_updated_at := v_result.updated_at;
    old_full_name := v_old_data.full_name;
    old_phone := v_old_data.phone;
    old_email := v_old_data.email;
    society_name := v_society_name;
    updated_fields := v_updated_fields;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM update_manager_profile(1, 'Updated Manager', '9876543210');

-- ============================================
-- END OF FILE
-- ============================================