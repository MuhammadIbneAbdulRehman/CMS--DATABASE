-- ============================================
-- GET WORKERS STORED PROCEDURE (FIXED)
-- ============================================
-- File: getworkerssp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_workers(INTEGER, INTEGER, INTEGER, VARCHAR, BOOLEAN) CASCADE;

-- ============================================
-- GET WORKERS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_workers(
    p_manager_id INTEGER,
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 10,
    p_search VARCHAR DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
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
    active_complaints BIGINT,
    total_count BIGINT
) AS $$
DECLARE
    v_offset INTEGER;
    v_conditions TEXT;
    v_query TEXT;
    v_count_query TEXT;
    v_count BIGINT;
    v_manager_category_id INTEGER;
BEGIN
    -- Calculate offset
    v_offset := (p_page - 1) * p_limit;
    
    -- Get manager's category
    SELECT department_category_id INTO v_manager_category_id
    FROM managers 
    WHERE id = p_manager_id AND is_active = true;
    
    IF v_manager_category_id IS NULL THEN
        RAISE EXCEPTION 'Manager not found or inactive';
    END IF;
    
    -- Build conditions
    v_conditions := ' WHERE w.manager_id = ' || p_manager_id;
    v_conditions := v_conditions || ' AND w.department_category_id = ' || v_manager_category_id;
    
    IF p_search IS NOT NULL AND p_search != '' THEN
        v_conditions := v_conditions || ' AND (w.full_name ILIKE ''%' || p_search || '%'' OR w.email ILIKE ''%' || p_search || '%'' OR w.phone ILIKE ''%' || p_search || '%'')';
    END IF;
    
    IF p_is_active IS NOT NULL THEN
        v_conditions := v_conditions || ' AND w.is_active = ' || CASE WHEN p_is_active THEN 'true' ELSE 'false' END;
    END IF;
    
    -- Get total count
    v_count_query := 'SELECT COUNT(*)::BIGINT as total FROM workers w ' || v_conditions;
    EXECUTE v_count_query INTO v_count;
    
    -- Get workers with category, sub-category, and complaint counts
    v_query := '
        SELECT 
            w.id AS worker_id,
            w.society_id AS worker_society_id,
            w.manager_id AS worker_manager_id,
            w.full_name AS worker_full_name,
            w.email AS worker_email,
            w.phone AS worker_phone,
            w.department_category_id AS worker_department_category_id,
            w.department_sub_category_id AS worker_department_sub_category_id,
            w.is_active AS worker_is_active,
            w.last_login AS worker_last_login,
            w.created_at AS worker_created_at,
            w.updated_at AS worker_updated_at,
            dc.name AS category_name,
            dsc.name AS sub_category_name,
            m.full_name AS manager_name,
            CASE 
                WHEN w.is_active = false THEN ''inactive''::VARCHAR
                WHEN COUNT(c.id) > 0 THEN ''busy''::VARCHAR
                ELSE ''available''::VARCHAR
            END AS status,
            COUNT(c.id) AS active_complaints,
            ' || v_count || '::BIGINT AS total_count
        FROM workers w
        LEFT JOIN department_categories dc ON w.department_category_id = dc.id
        LEFT JOIN department_sub_categories dsc ON w.department_sub_category_id = dsc.id
        LEFT JOIN managers m ON w.manager_id = m.id
        LEFT JOIN complaints c ON w.id = c.assigned_to AND c.status IN (''Open'', ''In-Progress'')
        ' || v_conditions || '
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
            m.full_name
        ORDER BY 
            CASE 
                WHEN w.is_active = false THEN 3
                WHEN COUNT(c.id) > 0 THEN 2
                ELSE 1
            END,
            w.full_name ASC
        LIMIT ' || p_limit || ' OFFSET ' || v_offset;
    
    RETURN QUERY EXECUTE v_query;
    
END;
$$ LANGUAGE plpgsql;
