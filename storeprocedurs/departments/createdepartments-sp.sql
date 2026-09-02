-- ============================================
-- CREATE DEPARTMENT SUB-CATEGORY STORED PROCEDURE
-- ============================================
-- File: createdepartmentsubcatsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS create_department_sub_category(INTEGER, VARCHAR, INTEGER) CASCADE;

-- ============================================
-- CREATE DEPARTMENT SUB-CATEGORY FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION create_department_sub_category(
    p_category_id INTEGER,
    p_name VARCHAR,
    p_sla_hours INTEGER DEFAULT NULL
)
RETURNS TABLE(
    sub_category_id INTEGER,
    sub_category_category_id INTEGER,
    sub_category_name VARCHAR,
    sub_category_sla_hours INTEGER,
    sub_category_is_active BOOLEAN,
    sub_category_created_at TIMESTAMP,
    category_name VARCHAR,
    category_is_active BOOLEAN
) AS $$
DECLARE
    v_category_exists BOOLEAN;
    v_category_name VARCHAR;
    v_category_is_active BOOLEAN;
    v_sub_category_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Check if category exists and is active
    SELECT 
        id,
        name,
        is_active
    INTO v_category_exists, v_category_name, v_category_is_active
    FROM department_categories 
    WHERE id = p_category_id;
    
    IF v_category_exists IS NULL THEN
        RAISE EXCEPTION 'Department category not found';
    END IF;
    
    IF v_category_is_active = false THEN
        RAISE EXCEPTION 'Department category is inactive';
    END IF;
    
    -- Check if sub-category already exists in this category
    SELECT EXISTS(
        SELECT 1 FROM department_sub_categories 
        WHERE category_id = p_category_id AND name = p_name
    ) INTO v_sub_category_exists;
    
    IF v_sub_category_exists THEN
        RAISE EXCEPTION 'Sub-category already exists in this category';
    END IF;
    
    -- Insert the sub-category
    INSERT INTO department_sub_categories (
        category_id,
        name,
        sla_hours,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_category_id,
        p_name,
        p_sla_hours,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING 
        id,
        category_id,
        name,
        sla_hours,
        is_active,
        created_at
    INTO v_result;
    
    -- Return the inserted sub-category
    sub_category_id := v_result.id;
    sub_category_category_id := v_result.category_id;
    sub_category_name := v_result.name;
    sub_category_sla_hours := v_result.sla_hours;
    sub_category_is_active := v_result.is_active;
    sub_category_created_at := v_result.created_at;
    category_name := v_category_name;
    category_is_active := v_category_is_active;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM create_department_sub_category(1, 'CCTV', 24);
-- SELECT * FROM create_department_sub_category(1, 'Access Control', 12);

-- ============================================
-- END OF FILE
-- ============================================