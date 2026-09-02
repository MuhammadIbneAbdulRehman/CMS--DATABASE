-- ============================================
-- GET CATEGORY WITH SUB-CATEGORIES STORED PROCEDURE
-- ============================================
-- File: getcategorywithsubcatsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_category_with_sub_categories(INTEGER) CASCADE;

-- ============================================
-- GET CATEGORY WITH SUB-CATEGORIES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_category_with_sub_categories(
    p_category_id INTEGER
)
RETURNS TABLE(
    category_id INTEGER,
    category_society_id INTEGER,
    category_name VARCHAR,
    category_is_active BOOLEAN,
    category_created_at TIMESTAMP,
    category_updated_at TIMESTAMP,
    society_name VARCHAR,
    sub_category_id INTEGER,
    sub_category_category_id INTEGER,
    sub_category_name VARCHAR,
    sub_category_is_active BOOLEAN,
    sub_category_sla_hours INTEGER,
    sub_category_created_at TIMESTAMP
) AS $$
DECLARE
    v_category_exists BOOLEAN;
BEGIN
    -- Check if category exists
    SELECT EXISTS(
        SELECT 1 FROM department_categories WHERE id = p_category_id
    ) INTO v_category_exists;
    
    IF NOT v_category_exists THEN
        RAISE EXCEPTION 'Department category not found';
    END IF;
    
    -- Return category with its sub-categories
    RETURN QUERY
    SELECT 
        dc.id AS category_id,
        dc.society_id AS category_society_id,
        dc.name AS category_name,
        dc.is_active AS category_is_active,
        dc.created_at AS category_created_at,
        dc.updated_at AS category_updated_at,
        s.name AS society_name,
        dsc.id AS sub_category_id,
        dsc.category_id AS sub_category_category_id,
        dsc.name AS sub_category_name,
        dsc.is_active AS sub_category_is_active,
        dsc.sla_hours AS sub_category_sla_hours,
        dsc.created_at AS sub_category_created_at
    FROM department_categories dc
    JOIN societies s ON dc.society_id = s.id
    LEFT JOIN department_sub_categories dsc ON dc.id = dsc.category_id
    WHERE dc.id = p_category_id
    ORDER BY dsc.name ASC;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_category_with_sub_categories(1);

-- ============================================
-- END OF FILE
-- ============================================