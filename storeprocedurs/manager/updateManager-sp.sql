-- ============================================
-- UPDATE MANAGER STORED PROCEDURE (FIXED)
-- ============================================
-- File: updatemanagersp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS update_manager(INTEGER, VARCHAR, VARCHAR, VARCHAR, INTEGER, BOOLEAN) CASCADE;

-- ============================================
-- UPDATE MANAGER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_manager(
    p_manager_id INTEGER,
    p_full_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_department_category_id INTEGER,
    p_is_active BOOLEAN
)
RETURNS TABLE(
    updated_id INTEGER,
    updated_full_name VARCHAR,
    updated_email VARCHAR,
    updated_phone VARCHAR,
    updated_department_category_id INTEGER,
    updated_category_name VARCHAR,
    updated_society_id INTEGER,
    updated_gm_id INTEGER,
    updated_is_active BOOLEAN,
    updated_created_at TIMESTAMP,
    updated_updated_at TIMESTAMP,
    old_full_name VARCHAR,
    old_email VARCHAR,
    old_phone VARCHAR,
    old_category_name VARCHAR,
    old_is_active BOOLEAN,
    society_name VARCHAR
) AS $$
DECLARE
    v_old_data RECORD;
    v_category_details RECORD;
    v_existing_manager RECORD;
    v_society_name VARCHAR;
    v_result RECORD;
BEGIN
    -- Get the manager's current data before update
    SELECT 
        m.id,
        m.full_name,
        m.email,
        m.phone,
        m.department_category_id,
        m.is_active,
        m.society_id,
        m.gm_id,
        dc.name as category_name
    INTO v_old_data
    FROM managers m
    LEFT JOIN department_categories dc ON m.department_category_id = dc.id
    WHERE m.id = p_manager_id;
    
    -- Check if manager exists
    IF v_old_data.id IS NULL THEN
        RAISE EXCEPTION 'Manager not found';
    END IF;
    
    -- Get society name
    SELECT name INTO v_society_name
    FROM societies 
    WHERE id = v_old_data.society_id;
    
    -- Validate department category if provided
    IF p_department_category_id IS NOT NULL THEN
        SELECT 
            id,
            name,
            society_id
        INTO v_category_details
        FROM department_categories 
        WHERE id = p_department_category_id AND is_active = true;
        
        IF v_category_details.id IS NULL THEN
            RAISE EXCEPTION 'Department category not found or inactive';
        END IF;
        
        -- Check if category already assigned to another manager
        SELECT 
            m.id,
            m.full_name
        INTO v_existing_manager
        FROM managers m
        WHERE m.department_category_id = p_department_category_id 
        AND m.is_active = true
        AND m.id != p_manager_id
        LIMIT 1;
        
        IF v_existing_manager.id IS NOT NULL THEN
            RAISE EXCEPTION 'Department category "%" is already assigned to manager: %', 
                v_category_details.name, v_existing_manager.full_name;
        END IF;
    END IF;
    
    -- Update the manager
    UPDATE managers 
    SET 
        full_name = COALESCE(p_full_name, full_name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone),
        department_category_id = p_department_category_id,
        is_active = COALESCE(p_is_active, is_active),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_manager_id;
    
    -- Update department categories assignment
    IF p_department_category_id IS NOT NULL THEN
        -- Remove manager_id from old category
        UPDATE department_categories 
        SET manager_id = NULL, 
            updated_at = CURRENT_TIMESTAMP
        WHERE manager_id = p_manager_id 
        AND id != p_department_category_id;
        
        -- Assign manager_id to new category
        UPDATE department_categories 
        SET manager_id = p_manager_id, 
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_department_category_id;
    ELSE
        -- Remove manager_id from all categories
        UPDATE department_categories 
        SET manager_id = NULL, 
            updated_at = CURRENT_TIMESTAMP
        WHERE manager_id = p_manager_id;
    END IF;
    
    -- Get the updated manager data
    SELECT 
        m.id,
        m.full_name,
        m.email,
        m.phone,
        m.department_category_id,
        dc.name as category_name,
        m.society_id,
        m.gm_id,
        m.is_active,
        m.created_at,
        m.updated_at
    INTO v_result
    FROM managers m
    LEFT JOIN department_categories dc ON m.department_category_id = dc.id
    WHERE m.id = p_manager_id;
    
    -- Return the updated manager data with old data for comparison
    updated_id := v_result.id;
    updated_full_name := v_result.full_name;
    updated_email := v_result.email;
    updated_phone := v_result.phone;
    updated_department_category_id := v_result.department_category_id;
    updated_category_name := v_result.category_name;
    updated_society_id := v_result.society_id;
    updated_gm_id := v_result.gm_id;
    updated_is_active := v_result.is_active;
    updated_created_at := v_result.created_at;
    updated_updated_at := v_result.updated_at;
    old_full_name := v_old_data.full_name;
    old_email := v_old_data.email;
    old_phone := v_old_data.phone;
    old_category_name := v_old_data.category_name;
    old_is_active := v_old_data.is_active;
    society_name := v_society_name;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM update_manager(1, 'Updated Manager', 'updated@example.com', '9876543210', 1, true);

-- ============================================
-- END OF FILE
-- ============================================