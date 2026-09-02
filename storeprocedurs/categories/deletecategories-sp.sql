-- ============================================
-- DELETE DEPARTMENT CATEGORY STORED PROCEDURE
-- ============================================
-- File: deletedepartmentcategorysp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS delete_department_category(INTEGER) CASCADE;

-- ============================================
-- DELETE DEPARTMENT CATEGORY FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION delete_department_category(
    p_category_id INTEGER
)
RETURNS TABLE(
    deleted_id INTEGER,
    deleted_name VARCHAR,
    deleted_is_active BOOLEAN,
    deleted_updated_at TIMESTAMP,
    sub_categories_deactivated BOOLEAN,
    sub_category_count BIGINT,
    deactivated_sub_categories JSON
) AS $$
DECLARE
    v_category_data RECORD;
    v_sub_categories RECORD;
    v_sub_category_count BIGINT;
    v_sub_category_json JSON;
BEGIN
    -- Check if category exists and get data
    SELECT 
        id,
        name,
        is_active
    INTO v_category_data
    FROM department_categories 
    WHERE id = p_category_id;
    
    IF v_category_data.id IS NULL THEN
        RAISE EXCEPTION 'Department category not found';
    END IF;
    
    -- Deactivate all sub-categories under this category (cascade)
    WITH updated_sub_categories AS (
        UPDATE department_sub_categories
        SET is_active = false, 
            updated_at = CURRENT_TIMESTAMP
        WHERE category_id = p_category_id
        RETURNING id, name
    )
    SELECT 
        COUNT(*)::BIGINT,
        JSON_AGG(JSON_BUILD_OBJECT('id', id, 'name', name))
    INTO 
        v_sub_category_count,
        v_sub_category_json
    FROM updated_sub_categories;
    
    -- Deactivate the category
    UPDATE department_categories
    SET is_active = false, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_category_id;
    
    -- Return the deleted category data
    deleted_id := v_category_data.id;
    deleted_name := v_category_data.name;
    deleted_is_active := false;
    deleted_updated_at := CURRENT_TIMESTAMP;
    sub_categories_deactivated := v_sub_category_count > 0;
    sub_category_count := v_sub_category_count;
    deactivated_sub_categories := v_sub_category_json;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM delete_department_category(1);

-- ============================================
-- END OF FILE
-- ============================================