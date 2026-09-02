-- ============================================
-- GET ALL MANAGERS STORED PROCEDURE
-- ============================================
-- File: getmanagerssp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_managers(INTEGER, INTEGER, INTEGER, VARCHAR, BOOLEAN) CASCADE;

-- ============================================
-- GET ALL MANAGERS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_managers(
    p_gm_id INTEGER DEFAULT NULL,
    p_society_id INTEGER DEFAULT NULL,
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
    category_name VARCHAR,
    total_count BIGINT
) AS $$
DECLARE
    v_offset INTEGER;
    v_conditions TEXT;
    v_query TEXT;
    v_count_query TEXT;
    v_count BIGINT;
BEGIN
    -- Calculate offset
    v_offset := (p_page - 1) * p_limit;
    
    -- Build conditions
    v_conditions := '';
    
    IF p_gm_id IS NOT NULL THEN
        v_conditions := v_conditions || ' AND m.gm_id = ' || p_gm_id;
    END IF;
    
    IF p_society_id IS NOT NULL THEN
        v_conditions := v_conditions || ' AND m.society_id = ' || p_society_id;
    END IF;
    
    IF p_search IS NOT NULL AND p_search != '' THEN
        v_conditions := v_conditions || ' AND (m.full_name ILIKE ''%' || p_search || '%'' OR m.email ILIKE ''%' || p_search || '%'' OR m.phone ILIKE ''%' || p_search || '%'')';
    END IF;
    
    IF p_is_active IS NOT NULL THEN
        v_conditions := v_conditions || ' AND m.is_active = ' || CASE WHEN p_is_active THEN 'true' ELSE 'false' END;
    END IF;
    
    -- Remove first ' AND ' if exists
    IF v_conditions != '' THEN
        v_conditions := 'WHERE ' || SUBSTRING(v_conditions, 6);
    END IF;
    
    -- Get total count
    v_count_query := 'SELECT COUNT(*) as total FROM managers m ' || v_conditions;
    EXECUTE v_count_query INTO v_count;
    
    -- Get managers with department category names
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
            dc.name AS category_name,
            ' || v_count || ' AS total_count
        FROM managers m
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

-- SELECT * FROM get_managers(NULL, 1, 1, 10, NULL, NULL);
-- SELECT * FROM get_managers(1, NULL, 1, 10, NULL, NULL);
-- SELECT * FROM get_managers(NULL, 1, 1, 10, 'john', NULL);
-- SELECT * FROM get_managers(NULL, 1, 1, 10, NULL, true);

-- ============================================
-- END OF FILE
-- ============================================