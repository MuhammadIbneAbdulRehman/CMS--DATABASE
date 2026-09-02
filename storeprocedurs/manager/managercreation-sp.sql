-- ============================================
-- CREATE MANAGER STORED PROCEDURE
-- ============================================
-- File: createmanagersp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS create_manager(INTEGER, INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INTEGER, INTEGER) CASCADE;

-- ============================================
-- CREATE MANAGER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION create_manager(
    p_society_id INTEGER,
    p_gm_id INTEGER,
    p_full_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_password_hash TEXT,
    p_department_category_id INTEGER,
    p_created_by INTEGER
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
    manager_created_at TIMESTAMP,
    manager_updated_at TIMESTAMP,
    category_name VARCHAR,
    society_name VARCHAR
) AS $$
DECLARE
    v_manager_exists BOOLEAN;
    v_phone_exists BOOLEAN;
    v_category_exists BOOLEAN;
    v_category_name VARCHAR;
    v_society_name VARCHAR;
    v_result RECORD;
    v_category_manager_exists BOOLEAN;
    v_category_manager_name VARCHAR;
BEGIN
    -- Check if email already exists
    SELECT EXISTS(
        SELECT 1 FROM managers WHERE email = p_email
    ) INTO v_manager_exists;
    
    IF v_manager_exists THEN
        RAISE EXCEPTION 'Email already registered';
    END IF;
    
    -- Check if phone already exists
    SELECT EXISTS(
        SELECT 1 FROM managers WHERE phone = p_phone
    ) INTO v_phone_exists;
    
    IF v_phone_exists THEN
        RAISE EXCEPTION 'Phone number already registered';
    END IF;
    
    -- Check if society exists
    SELECT name INTO v_society_name
    FROM societies 
    WHERE id = p_society_id AND is_active = true;
    
    IF v_society_name IS NULL THEN
        RAISE EXCEPTION 'Society not found or inactive';
    END IF;
    
    -- Validate department category if provided
    IF p_department_category_id IS NOT NULL THEN
        SELECT 
            name,
            EXISTS(
                SELECT 1 FROM department_categories 
                WHERE id = p_department_category_id AND society_id = p_society_id AND is_active = true
            )
        INTO v_category_name, v_category_exists
        FROM department_categories 
        WHERE id = p_department_category_id AND society_id = p_society_id AND is_active = true;
        
        IF NOT v_category_exists THEN
            RAISE EXCEPTION 'Department category not found or inactive in this society';
        END IF;
        
        -- Check if category already has a manager assigned
        SELECT 
            m.id,
            m.full_name
        INTO v_category_manager_exists, v_category_manager_name
        FROM managers m
        WHERE m.department_category_id = p_department_category_id 
        AND m.is_active = true
        LIMIT 1;
        
        IF v_category_manager_exists THEN
            RAISE EXCEPTION 'Department category "%" is already assigned to manager: %', v_category_name, v_category_manager_name;
        END IF;
    END IF;
    
    -- Insert manager
    INSERT INTO managers (
        society_id,
        gm_id,
        full_name,
        email,
        phone,
        password_hash,
        department_category_id,
        created_by,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_society_id,
        p_gm_id,
        p_full_name,
        p_email,
        p_phone,
        p_password_hash,
        p_department_category_id,
        p_created_by,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING 
        id,
        society_id,
        gm_id,
        full_name,
        email,
        phone,
        department_category_id,
        is_active,
        created_at,
        updated_at
    INTO v_result;
    
    -- If category was assigned, update it with manager_id
    IF p_department_category_id IS NOT NULL THEN
        UPDATE department_categories 
        SET manager_id = v_result.id,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_department_category_id;
    END IF;
    
    -- Return the complete manager data
    manager_id := v_result.id;
    manager_society_id := v_result.society_id;
    manager_gm_id := v_result.gm_id;
    manager_full_name := v_result.full_name;
    manager_email := v_result.email;
    manager_phone := v_result.phone;
    manager_department_category_id := v_result.department_category_id;
    manager_is_active := v_result.is_active;
    manager_created_at := v_result.created_at;
    manager_updated_at := v_result.updated_at;
    category_name := v_category_name;
    society_name := v_society_name;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM create_manager(1, NULL, 'John Manager', 'manager@example.com', '1234567890', 'hashed_password', 1, 1);

-- ============================================
-- END OF FILE
-- ============================================