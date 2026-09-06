-- ============================================
-- GET WORKER BY ID STORED PROCEDURE
-- ============================================
-- File: getworkerbyidsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_worker_by_id(INTEGER, INTEGER) CASCADE;

-- ============================================
-- GET WORKER BY ID FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_worker_by_id(
    p_worker_id INTEGER,
    p_manager_id INTEGER
)
RETURNS TABLE(
    worker_id INTEGER,
    worker_society_id INTEGER,
    worker_manager_id INTEGER,
    worker_full_name VARCHAR,
    worker_email VARCHAR,
    worker_phone VARCHAR,
    worker_department_category_id INTEGER,
    worker_department_sub_category_id INTEGER,
    worker_is_active BOOLEAN,
    worker_last_login TIMESTAMP,
    worker_created_at TIMESTAMP,
    worker_updated_at TIMESTAMP,
    category_name VARCHAR,
    sub_category_name VARCHAR,
    manager_name VARCHAR,
    status VARCHAR,
    active_complaints BIGINT
) AS $$
DECLARE
    v_result RECORD;
    v_manager_category_id INTEGER;
BEGIN
    -- Get manager's category to validate access
    SELECT department_category_id INTO v_manager_category_id
    FROM managers 
    WHERE id = p_manager_id AND is_active = true;
    
    IF v_manager_category_id IS NULL THEN
        RAISE EXCEPTION 'Manager not found or inactive';
    END IF;
    
    -- Get worker by ID with manager validation
    SELECT 
        w.id,
        w.society_id,
        w.manager_id,
        w.full_name,
        w.email,
        w.phone,
        w.department_category_id,
        w.department_sub_category_id,
        w.is_active,
        w.last_login,
        w.created_at,
        w.updated_at,
        dc.name as category_name,
        dsc.name as sub_category_name,
        m.full_name as manager_name,
        CASE 
            WHEN w.is_active = false THEN 'inactive'::VARCHAR
            WHEN COUNT(c.id) > 0 THEN 'busy'::VARCHAR
            ELSE 'available'::VARCHAR
        END as status,
        COUNT(c.id) as active_complaints
    INTO v_result
    FROM workers w
    LEFT JOIN department_categories dc ON w.department_category_id = dc.id
    LEFT JOIN department_sub_categories dsc ON w.department_sub_category_id = dsc.id
    LEFT JOIN managers m ON w.manager_id = m.id
    LEFT JOIN complaints c ON w.id = c.assigned_to AND c.status IN ('Open', 'In-Progress')
    WHERE w.id = p_worker_id AND w.manager_id = p_manager_id
    AND w.department_category_id = v_manager_category_id
    GROUP BY 
        w.id, 
        w.society_id, 
        w.manager_id, 
        w.full_name, 
        w.email, 
        w.phone,
        w.department_category_id, 
        w.department_sub_category_id,
        w.is_active, 
        w.last_login, 
        w.created_at, 
        w.updated_at,
        dc.name, 
        dsc.name,
        m.full_name;
    
    -- Check if worker exists
    IF v_result.id IS NULL THEN
        RAISE EXCEPTION 'Worker not found or not created by you';
    END IF;
    
    -- Return the worker data
    worker_id := v_result.id;
    worker_society_id := v_result.society_id;
    worker_manager_id := v_result.manager_id;
    worker_full_name := v_result.full_name;
    worker_email := v_result.email;
    worker_phone := v_result.phone;
    worker_department_category_id := v_result.department_category_id;
    worker_department_sub_category_id := v_result.department_sub_category_id;
    worker_is_active := v_result.is_active;
    worker_last_login := v_result.last_login;
    worker_created_at := v_result.created_at;
    worker_updated_at := v_result.updated_at;
    category_name := v_result.category_name;
    sub_category_name := v_result.sub_category_name;
    manager_name := v_result.manager_name;
    status := v_result.status;
    active_complaints := v_result.active_complaints;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_worker_by_id(1, 1);

-- ============================================
-- END OF FILE
-- ============================================