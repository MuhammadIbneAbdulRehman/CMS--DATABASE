-- ============================================
-- GET AVAILABLE WORKERS STORED PROCEDURE
-- ============================================
-- File: getavailableworkerssp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_available_workers(INTEGER) CASCADE;

-- ============================================
-- GET AVAILABLE WORKERS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_available_workers(
    p_manager_id INTEGER
)
RETURNS TABLE(
    worker_id INTEGER,
    worker_full_name VARCHAR,
    worker_email VARCHAR,
    worker_phone VARCHAR,
    worker_department_category_id INTEGER,
    worker_department_sub_category_id INTEGER,
    worker_is_active BOOLEAN,
    category_name VARCHAR,
    sub_category_name VARCHAR,
    active_complaints BIGINT,
    status VARCHAR
) AS $$
DECLARE
    v_manager_category_id INTEGER;
    v_manager_exists BOOLEAN;
BEGIN
    -- Get manager's category
    SELECT department_category_id INTO v_manager_category_id
    FROM managers 
    WHERE id = p_manager_id AND is_active = true;
    
    IF v_manager_category_id IS NULL THEN
        RAISE EXCEPTION 'Manager not found or inactive';
    END IF;
    
    -- Return available workers in manager's category
    RETURN QUERY
    SELECT 
        w.id AS worker_id,
        w.full_name AS worker_full_name,
        w.email AS worker_email,
        w.phone AS worker_phone,
        w.department_category_id AS worker_department_category_id,
        w.department_sub_category_id AS worker_department_sub_category_id,
        w.is_active AS worker_is_active,
        dc.name AS category_name,
        dsc.name AS sub_category_name,
        COUNT(c.id) AS active_complaints,
        CASE 
            WHEN COUNT(c.id) > 0 THEN 'busy'::VARCHAR
            ELSE 'available'::VARCHAR
        END AS status
    FROM workers w
    LEFT JOIN department_categories dc ON w.department_category_id = dc.id
    LEFT JOIN department_sub_categories dsc ON w.department_sub_category_id = dsc.id
    LEFT JOIN complaints c ON w.id = c.assigned_to AND c.status IN ('Open', 'In-Progress')
    WHERE w.manager_id = p_manager_id 
    AND w.is_active = true
    AND w.department_category_id = v_manager_category_id
    GROUP BY 
        w.id, 
        w.full_name, 
        w.email, 
        w.phone,
        w.department_category_id,
        w.department_sub_category_id,
        w.is_active,
        dc.name,
        dsc.name
    HAVING COUNT(c.id) = 0
    ORDER BY w.full_name ASC;
    
END;
$$ LANGUAGE plpgsql;

