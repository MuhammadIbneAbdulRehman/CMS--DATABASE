-- ============================================
-- RESTORE DEPARTMENT SUB-CATEGORY STORED PROCEDURE
-- ============================================
-- File: restoredepartmentsubcatsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS restore_department_sub_category(INTEGER) CASCADE;

-- ============================================
-- RESTORE DEPARTMENT SUB-CATEGORY FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION restore_department_sub_category(
    p_sub_category_id INTEGER
)
RETURNS TABLE(
    restored_id INTEGER,
    restored_category_id INTEGER,
    restored_name VARCHAR,
    restored_is_active BOOLEAN,
    restored_updated_at TIMESTAMP,
    category_name VARCHAR,
    category_is_active BOOLEAN
) AS $$
DECLARE
    v_sub_category RECORD;
    v_category_data RECORD;
BEGIN
    -- Get sub-category data before restoration
    SELECT 
        dsc.id,
        dsc.category_id,
        dsc.name,
        dsc.is_active,
        dc.name as category_name,
        dc.is_active as category_is_active
    INTO v_sub_category
    FROM department_sub_categories dsc
    LEFT JOIN department_categories dc ON dsc.category_id = dc.id
    WHERE dsc.id = p_sub_category_id;
    
    -- Check if sub-category exists
    IF v_sub_category.id IS NULL THEN
        RAISE EXCEPTION 'Department sub-category not found';
    END IF;
    
    -- Check if sub-category is already active
    IF v_sub_category.is_active THEN
        RAISE EXCEPTION 'Department sub-category is already active';
    END IF;
    
    -- Check if parent category is active
    IF v_sub_category.category_is_active = false THEN
        RAISE EXCEPTION 'Cannot restore sub-category because parent category is inactive';
    END IF;
    
    -- Restore the sub-category
    UPDATE department_sub_categories
    SET 
        is_active = true, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_sub_category_id;
    
    -- Return the restored sub-category data
    restored_id := v_sub_category.id;
    restored_category_id := v_sub_category.category_id;
    restored_name := v_sub_category.name;
    restored_is_active := true;
    restored_updated_at := CURRENT_TIMESTAMP;
    category_name := v_sub_category.category_name;
    category_is_active := v_sub_category.category_is_active;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM restore_department_sub_category(1);

-- ============================================
-- END OF FILE
-- ============================================