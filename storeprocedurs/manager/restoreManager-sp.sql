-- ============================================
-- RESTORE MANAGER STORED PROCEDURE
-- ============================================
-- File: restoremanagersp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS restore_manager(INTEGER, INTEGER, INTEGER) CASCADE;

-- ============================================
-- RESTORE MANAGER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION restore_manager(
    p_manager_id INTEGER,
    p_gm_id INTEGER DEFAULT NULL,
    p_society_id INTEGER DEFAULT NULL
)
RETURNS TABLE(
    restored_id INTEGER,
    restored_full_name VARCHAR,
    restored_is_active BOOLEAN,
    restored_updated_at TIMESTAMP,
    restored_category_name VARCHAR,
    restored_society_name VARCHAR,
    restored_category_restored BOOLEAN
) AS $$
DECLARE
    v_manager_data RECORD;
    v_society_name VARCHAR;
    v_category_name VARCHAR;
    v_is_already_active BOOLEAN;
BEGIN
    -- Get manager data with category name
    SELECT 
        m.id,
        m.full_name,
        m.email,
        m.is_active,
        m.department_category_id,
        m.society_id,
        m.gm_id,
        dc.name as category_name
    INTO v_manager_data
    FROM managers m
    LEFT JOIN department_categories dc ON m.department_category_id = dc.id
    WHERE m.id = p_manager_id
    AND (p_gm_id IS NULL OR m.gm_id = p_gm_id)
    AND (p_society_id IS NULL OR m.society_id = p_society_id);
    
    -- Check if manager exists
    IF v_manager_data.id IS NULL THEN
        RAISE EXCEPTION 'Manager not found or you do not have permission to restore this manager';
    END IF;
    
    -- Check if manager is already active
    IF v_manager_data.is_active THEN
        RAISE EXCEPTION 'Manager is already active';
    END IF;
    
    -- Get society name
    SELECT name INTO v_society_name
    FROM societies 
    WHERE id = v_manager_data.society_id;
    
    -- Set category name
    v_category_name := v_manager_data.category_name;
    
    -- Restore the manager (set is_active = true)
    UPDATE managers
    SET is_active = true, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_manager_id;
    
    -- If the manager had a department category assigned, update it
    IF v_manager_data.department_category_id IS NOT NULL THEN
        UPDATE department_categories 
        SET manager_id = p_manager_id, 
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_manager_data.department_category_id 
        AND manager_id IS NULL;
    END IF;
    
    -- Return the restored manager data
    restored_id := v_manager_data.id;
    restored_full_name := v_manager_data.full_name;
    restored_is_active := true;
    restored_updated_at := CURRENT_TIMESTAMP;
    restored_category_name := v_category_name;
    restored_society_name := v_society_name;
    restored_category_restored := v_manager_data.department_category_id IS NOT NULL;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM restore_manager(1, NULL, 1);
-- SELECT * FROM restore_manager(1, 1, NULL);

-- ============================================
-- END OF FILE
-- ============================================