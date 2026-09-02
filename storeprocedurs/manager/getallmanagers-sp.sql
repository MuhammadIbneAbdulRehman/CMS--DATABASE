-- ============================================
-- GET ALL MANAGERS STORED PROCEDURE (FIXED)
-- ============================================
-- File: getallmanagerssp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_all_managers(INTEGER, INTEGER, INTEGER, VARCHAR, BOOLEAN) CASCADE;

-- ============================================
-- GET ALL MANAGERS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_all_managers(
    p_society_id INTEGER,
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 10,
    p_search VARCHAR DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
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
    manager_created_at TIMESTAMP,
    manager_updated_at TIMESTAMP,
    society_name VARCHAR,
    gm_name VARCHAR,
    category_name VARCHAR,
    total_count BIGINT
) AS $$
DECLARE
    v_offset INTEGER;
    v_conditions TEXT;
    v_query TEXT;
    v_count_query TEXT;
    v_count BIGINT;  -- Changed to BIGINT
BEGIN
    -- Calculate offset
    v_offset := (p_page - 1) * p_limit;
    
    -- Build conditions
    v_conditions := ' WHERE m.society_id = ' || p_society_id;
    
    IF p_search IS NOT NULL AND p_search != '' THEN
        v_conditions := v_conditions || ' AND (m.full_name ILIKE ''%' || p_search || '%'' OR m.email ILIKE ''%' || p_search || '%'' OR m.phone ILIKE ''%' || p_search || '%'')';
    END IF;
    
    IF p_is_active IS NOT NULL THEN
        v_conditions := v_conditions || ' AND m.is_active = ' || CASE WHEN p_is_active THEN 'true' ELSE 'false' END;
    END IF;
    
    -- Get total count
    v_count_query := 'SELECT COUNT(*)::BIGINT as total FROM managers m ' || v_conditions;  -- Cast to BIGINT
    EXECUTE v_count_query INTO v_count;
    
    -- Get managers with society, gm, and category info
    v_query := '
        SELECT 
            m.id AS manager_id,
            m.society_id AS manager_society_id,
            m.gm_id AS manager_gm_id,
            m.full_name AS manager_full_name,
            m.email AS manager_email,
            m.phone AS manager_phone,
            m.department_category_id AS manager_department_category_id,
            m.is_active AS manager_is_active,
            m.last_login AS manager_last_login,
            m.created_at AS manager_created_at,
            m.updated_at AS manager_updated_at,
            s.name AS society_name,
            g.full_name AS gm_name,
            dc.name AS category_name,
            ' || v_count || '::BIGINT AS total_count  -- Cast to BIGINT
        FROM managers m
        JOIN societies s ON m.society_id = s.id
        LEFT JOIN gm_staff g ON m.gm_id = g.id
        LEFT JOIN department_categories dc ON m.department_category_id = dc.id
        ' || v_conditions || '
        ORDER BY m.created_at DESC
        LIMIT ' || p_limit || ' OFFSET ' || v_offset;
    
    RETURN QUERY EXECUTE v_query;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_all_managers(1, 1, 10, NULL, NULL);
-- SELECT * FROM get_all_managers(1, 1, 10, 'john', NULL);
-- SELECT * FROM get_all_managers(1, 1, 10, NULL, true);

-- ============================================
-- END OF FILE
-- ============================================