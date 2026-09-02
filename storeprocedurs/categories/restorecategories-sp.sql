-- ============================================
-- RESTORE DEPARTMENT CATEGORY STORED PROCEDURE
-- ============================================
-- File: restoredepartmentcategorysp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS restore_department_category(INTEGER) CASCADE;

-- ============================================
-- RESTORE DEPARTMENT CATEGORY FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION restore_department_category(
    p_category_id INTEGER
)
RETURNS TABLE(
    restored_id INTEGER,
    restored_name VARCHAR,
    restored_is_active BOOLEAN,
    restored_updated_at TIMESTAMP,
    sub_categories_restored BOOLEAN,
    sub_category_count BIGINT
) AS $$
DECLARE
    v_category_data RECORD;
    v_sub_category_count BIGINT;
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
    
    -- Check if category is already active
    IF v_category_data.is_active THEN
        RAISE EXCEPTION 'Department category is already active';
    END IF;
    
    -- Restore all sub-categories under this category (cascade)
    UPDATE department_sub_categories
    SET is_active = true, 
        updated_at = CURRENT_TIMESTAMP
    WHERE category_id = p_category_id;
    
    -- Get count of restored sub-categories
    SELECT COUNT(*) INTO v_sub_category_count
    FROM department_sub_categories 
    WHERE category_id = p_category_id;
    
    -- Restore the category
    UPDATE department_categories
    SET is_active = true, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_category_id;
    
    -- Return the restored category data
    restored_id := v_category_data.id;
    restored_name := v_category_data.name;
    restored_is_active := true;
    restored_updated_at := CURRENT_TIMESTAMP;
    sub_categories_restored := v_sub_category_count > 0;
    sub_category_count := v_sub_category_count;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM restore_department_category(1);

-- ============================================
-- END OF FILE
-- ============================================