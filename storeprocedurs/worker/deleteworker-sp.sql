-- ============================================
-- DELETE WORKER STORED PROCEDURE
-- ============================================
-- File: deleteworkersp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS delete_worker(INTEGER, INTEGER) CASCADE;

-- ============================================
-- DELETE WORKER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION delete_worker(
    p_worker_id INTEGER,
    p_manager_id INTEGER
)
RETURNS TABLE(
    deleted_id INTEGER,
    deleted_full_name VARCHAR,
    deleted_email VARCHAR,
    deleted_is_active BOOLEAN,
    deleted_updated_at TIMESTAMP,
    deleted_society_name VARCHAR,
    deleted_manager_name VARCHAR,
    deleted_has_active_complaints BOOLEAN,
    deleted_active_complaint_count BIGINT
) AS $$
DECLARE
    v_worker_data RECORD;
    v_active_complaints BIGINT;
    v_society_name VARCHAR;
    v_manager_name VARCHAR;
    v_manager_category_id INTEGER;
BEGIN
    -- Get manager's category
    SELECT department_category_id INTO v_manager_category_id
    FROM managers 
    WHERE id = p_manager_id AND is_active = true;
    
    IF v_manager_category_id IS NULL THEN
        RAISE EXCEPTION 'Manager not found or inactive';
    END IF;
    
    -- Check if worker exists and belongs to this manager
    SELECT 
        w.id,
        w.full_name,
        w.email,
        w.is_active,
        w.society_id,
        w.manager_id,
        m.full_name as manager_name,
        s.name as society_name
    INTO v_worker_data
    FROM workers w
    JOIN managers m ON w.manager_id = m.id
    JOIN societies s ON w.society_id = s.id
    WHERE w.id = p_worker_id 
    AND w.manager_id = p_manager_id 
    AND w.department_category_id = v_manager_category_id
    AND w.is_active = true;
    
    IF v_worker_data.id IS NULL THEN
        RAISE EXCEPTION 'Worker not found, already deactivated, or not created by you';
    END IF;
    
    -- Check if worker has active complaints
    SELECT COUNT(*) INTO v_active_complaints
    FROM complaints 
    WHERE assigned_to = p_worker_id AND status IN ('Open', 'In-Progress');
    
    -- Set names
    v_society_name := v_worker_data.society_name;
    v_manager_name := v_worker_data.manager_name;
    
    -- If worker has active complaints, raise exception
    IF v_active_complaints > 0 THEN
        RAISE EXCEPTION 'Cannot delete worker with active complaints. Reassign complaints first.';
    END IF;
    
    -- Soft delete the worker
    UPDATE workers
    SET is_active = false, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_worker_id AND manager_id = p_manager_id;
    
    -- Return the deleted worker data
    deleted_id := v_worker_data.id;
    deleted_full_name := v_worker_data.full_name;
    deleted_email := v_worker_data.email;
    deleted_is_active := false;
    deleted_updated_at := CURRENT_TIMESTAMP;
    deleted_society_name := v_society_name;
    deleted_manager_name := v_manager_name;
    deleted_has_active_complaints := v_active_complaints > 0;
    deleted_active_complaint_count := v_active_complaints;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM delete_worker(3, 3);

-- ============================================
-- END OF FILE
-- ============================================