-- ============================================
-- GET DEPARTMENT CATEGORIES STORED PROCEDURE
-- ============================================
-- File: getdepartmentcategoriesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_department_categories(INTEGER, INTEGER, INTEGER, VARCHAR, BOOLEAN) CASCADE;

-- ============================================
-- GET DEPARTMENT CATEGORIES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_department_categories(
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 10,
    p_society_id INTEGER DEFAULT NULL,
    p_search VARCHAR DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE(
    category_id INTEGER,
    category_society_id INTEGER,
    category_name VARCHAR,
    category_is_active BOOLEAN,
    category_created_at TIMESTAMP,
    category_updated_at TIMESTAMP,
    category_manager_id INTEGER,
    society_name VARCHAR,
    manager_id INTEGER,
    manager_full_name VARCHAR,
    manager_email VARCHAR,
    manager_phone VARCHAR,
    manager_is_active BOOLEAN,
    sub_category_count BIGINT,
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
    
    IF p_society_id IS NOT NULL THEN
        v_conditions := v_conditions || ' AND dc.society_id = ' || p_society_id;
    END IF;
    
    IF p_search IS NOT NULL AND p_search != '' THEN
        v_conditions := v_conditions || ' AND dc.name ILIKE ''%' || p_search || '%''';
    END IF;
    
    IF p_is_active IS NOT NULL THEN
        v_conditions := v_conditions || ' AND dc.is_active = ' || CASE WHEN p_is_active THEN 'true' ELSE 'false' END;
    END IF;
    
    -- Remove first ' AND ' if exists
    IF v_conditions != '' THEN
        v_conditions := 'WHERE ' || SUBSTRING(v_conditions, 6);
    END IF;
    
    -- Get total count
    v_count_query := 'SELECT COUNT(*)::BIGINT as total FROM department_categories dc ' || v_conditions;
    EXECUTE v_count_query INTO v_count;
    
    -- Get department categories with society and manager details
    v_query := '
        SELECT 
            dc.id AS category_id,
            dc.society_id AS category_society_id,
            dc.name AS category_name,
            dc.is_active AS category_is_active,
            dc.created_at AS category_created_at,
            dc.updated_at AS category_updated_at,
            dc.manager_id AS category_manager_id,
            s.name AS society_name,
            m.id AS manager_id,
            m.full_name AS manager_full_name,
            m.email AS manager_email,
            m.phone AS manager_phone,
            m.is_active AS manager_is_active,
            (SELECT COUNT(*) FROM department_sub_categories 
             WHERE category_id = dc.id AND is_active = true) AS sub_category_count,
            ' || v_count || '::BIGINT AS total_count
        FROM department_categories dc
        JOIN societies s ON dc.society_id = s.id
        LEFT JOIN managers m ON dc.manager_id = m.id
        ' || v_conditions || '
        ORDER BY dc.name ASC
        LIMIT ' || p_limit || ' OFFSET ' || v_offset;
    
    RETURN QUERY EXECUTE v_query;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_department_categories(1, 10, NULL, NULL, NULL);
-- SELECT * FROM get_department_categories(1, 10, 1, NULL, NULL);
-- SELECT * FROM get_department_categories(1, 10, NULL, 'Security', NULL);
-- SELECT * FROM get_department_categories(1, 10, NULL, NULL, true);

-- ============================================
-- END OF FILE
-- ============================================