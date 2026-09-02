-- ============================================
-- DELETE MANAGER STORED PROCEDURE
-- ============================================
-- File: deletemanagersp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS delete_manager(INTEGER, INTEGER, INTEGER) CASCADE;

-- ============================================
-- DELETE MANAGER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION delete_manager(
    p_manager_id INTEGER,
    p_gm_id INTEGER DEFAULT NULL,
    p_society_id INTEGER DEFAULT NULL
)
RETURNS TABLE(
    deleted_id INTEGER,
    deleted_full_name VARCHAR,
    deleted_email VARCHAR,
    deleted_is_active BOOLEAN,
    deleted_updated_at TIMESTAMP,
    deleted_category_name VARCHAR,
    deleted_society_name VARCHAR,
    deleted_has_workers BOOLEAN,
    deleted_worker_count BIGINT
) AS $$
DECLARE
    v_manager_data RECORD;
    v_worker_count BIGINT;
    v_society_name VARCHAR;
    v_category_name VARCHAR;
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
        RAISE EXCEPTION 'Manager not found or you do not have permission to delete this manager';
    END IF;
    
    -- Check if manager has active workers
    SELECT COUNT(*) INTO v_worker_count
    FROM workers 
    WHERE manager_id = p_manager_id AND is_active = true;
    
    -- Get society name
    SELECT name INTO v_society_name
    FROM societies 
    WHERE id = v_manager_data.society_id;
    
    -- Set category name
    v_category_name := v_manager_data.category_name;
    
    -- Soft delete the manager
    UPDATE managers
    SET is_active = false, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_manager_id;
    
    -- Remove manager_id from department category if assigned
    IF v_manager_data.department_category_id IS NOT NULL THEN
        UPDATE department_categories 
        SET manager_id = NULL, 
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_manager_data.department_category_id;
    END IF;
    
    -- Return the deleted manager data
    deleted_id := v_manager_data.id;
    deleted_full_name := v_manager_data.full_name;
    deleted_email := v_manager_data.email;
    deleted_is_active := false;
    deleted_updated_at := CURRENT_TIMESTAMP;
    deleted_category_name := v_category_name;
    deleted_society_name := v_society_name;
    deleted_has_workers := v_worker_count > 0;
    deleted_worker_count := v_worker_count;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM delete_manager(1, NULL, 1);
-- SELECT * FROM delete_manager(1, 1, NULL);

-- ============================================
-- END OF FILE
-- ============================================