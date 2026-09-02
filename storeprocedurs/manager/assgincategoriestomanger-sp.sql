-- ============================================
-- ASSIGN CATEGORY TO MANAGER STORED PROCEDURE
-- ============================================
-- File: assigncategorytomanagersp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS assign_category_to_manager(INTEGER, INTEGER, INTEGER) CASCADE;

-- ============================================
-- ASSIGN CATEGORY TO MANAGER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION assign_category_to_manager(
    p_manager_id INTEGER,
    p_gm_staff_id INTEGER,
    p_department_category_id INTEGER
)
RETURNS TABLE(
    manager_id INTEGER,
    manager_full_name VARCHAR,
    manager_email VARCHAR,
    manager_phone VARCHAR,
    manager_department_category_id INTEGER,
    manager_is_active BOOLEAN,
    manager_updated_at TIMESTAMP,
    manager_society_name VARCHAR,
    category_id INTEGER,
    category_name VARCHAR,
    category_society_id INTEGER,
    category_society_name VARCHAR,
    previous_category_name VARCHAR,
    action_type VARCHAR,
    assigned_by_name VARCHAR,
    assigned_by_type VARCHAR
) AS $$
DECLARE
    v_manager_data RECORD;
    v_category_data RECORD;
    v_previous_category_name VARCHAR;
    v_society_name VARCHAR;
    v_gm_staff_name VARCHAR;
BEGIN
    -- Get GM staff name
    SELECT full_name INTO v_gm_staff_name
    FROM gm_staff 
    WHERE id = p_gm_staff_id;
    
    -- Get manager data with society name
    SELECT 
        m.id,
        m.full_name,
        m.email,
        m.phone,
        m.department_category_id,
        m.is_active,
        m.society_id,
        s.name as society_name
    INTO v_manager_data
    FROM managers m
    JOIN societies s ON m.society_id = s.id
    WHERE m.id = p_manager_id 
    AND m.gm_id = p_gm_staff_id 
    AND m.is_active = true;
    
    -- Check if manager exists and belongs to this GM
    IF v_manager_data.id IS NULL THEN
        RAISE EXCEPTION 'Manager not found or not created by you';
    END IF;
    
    -- Get previous category name if any
    IF v_manager_data.department_category_id IS NOT NULL THEN
        SELECT name INTO v_previous_category_name
        FROM department_categories 
        WHERE id = v_manager_data.department_category_id;
    END IF;
    
    -- Set society name
    v_society_name := v_manager_data.society_name;
    
    -- If assigning a category
    IF p_department_category_id IS NOT NULL THEN
        -- Validate category
        SELECT 
            dc.id,
            dc.name as category_name,
            dc.society_id,
            s.name as society_name
        INTO v_category_data
        FROM department_categories dc
        JOIN societies s ON dc.society_id = s.id
        WHERE dc.id = p_department_category_id AND dc.is_active = true;
        
        IF v_category_data.id IS NULL THEN
            RAISE EXCEPTION 'Department category not found or inactive';
        END IF;
        
        -- Check if category already assigned to another manager
        IF EXISTS (
            SELECT 1 FROM managers 
            WHERE department_category_id = p_department_category_id 
            AND id != p_manager_id 
            AND is_active = true
        ) THEN
            RAISE EXCEPTION 'Category "%" is already assigned to another manager', v_category_data.category_name;
        END IF;
        
        -- Update manager with category
        UPDATE managers
        SET department_category_id = p_department_category_id,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_manager_id;
        
        -- Update department_categories with manager_id
        UPDATE department_categories 
        SET manager_id = p_manager_id, 
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_department_category_id;
        
        -- Return assignment data
        manager_id := v_manager_data.id;
        manager_full_name := v_manager_data.full_name;
        manager_email := v_manager_data.email;
        manager_phone := v_manager_data.phone;
        manager_department_category_id := p_department_category_id;
        manager_is_active := v_manager_data.is_active;
        manager_updated_at := CURRENT_TIMESTAMP;
        manager_society_name := v_manager_data.society_name;
        category_id := v_category_data.id;
        category_name := v_category_data.category_name;
        category_society_id := v_category_data.society_id;
        category_society_name := v_category_data.society_name;
        previous_category_name := v_previous_category_name;
        action_type := 'assigned';
        assigned_by_name := v_gm_staff_name;
        assigned_by_type := 'GM Staff';
        
        RETURN NEXT;
        
    ELSE
        -- Removing category
        UPDATE managers
        SET department_category_id = NULL,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_manager_id;
        
        -- Update department_categories - remove manager_id
        UPDATE department_categories 
        SET manager_id = NULL, 
            updated_at = CURRENT_TIMESTAMP
        WHERE manager_id = p_manager_id;
        
        -- Return removal data
        manager_id := v_manager_data.id;
        manager_full_name := v_manager_data.full_name;
        manager_email := v_manager_data.email;
        manager_phone := v_manager_data.phone;
        manager_department_category_id := NULL;
        manager_is_active := v_manager_data.is_active;
        manager_updated_at := CURRENT_TIMESTAMP;
        manager_society_name := v_manager_data.society_name;
        category_id := NULL;
        category_name := NULL;
        category_society_id := NULL;
        category_society_name := NULL;
        previous_category_name := v_previous_category_name;
        action_type := 'removed';
        assigned_by_name := v_gm_staff_name;
        assigned_by_type := 'GM Staff';
        
        RETURN NEXT;
    END IF;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM assign_category_to_manager(1, 1, 1);
-- SELECT * FROM assign_category_to_manager(1, 1, NULL);

-- ============================================
-- END OF FILE
-- ============================================