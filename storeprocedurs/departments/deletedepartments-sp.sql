-- ============================================
-- DELETE DEPARTMENT SUB-CATEGORY STORED PROCEDURE
-- ============================================
-- File: deletedepartmentsubcatsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS delete_department_sub_category(INTEGER) CASCADE;

-- ============================================
-- DELETE DEPARTMENT SUB-CATEGORY FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION delete_department_sub_category(
    p_sub_category_id INTEGER
)
RETURNS TABLE(
    deleted_id INTEGER,
    deleted_category_id INTEGER,
    deleted_name VARCHAR,
    deleted_is_active BOOLEAN,
    deleted_updated_at TIMESTAMP,
    category_name VARCHAR,
    has_active_complaints BOOLEAN,
    active_complaint_count BIGINT
) AS $$
DECLARE
    v_sub_category RECORD;
    v_category_name VARCHAR;
    v_active_complaint_count BIGINT;
BEGIN
    -- Get sub-category data before deletion
    SELECT 
        dsc.id,
        dsc.category_id,
        dsc.name,
        dsc.is_active,
        dc.name as category_name
    INTO v_sub_category
    FROM department_sub_categories dsc
    LEFT JOIN department_categories dc ON dsc.category_id = dc.id
    WHERE dsc.id = p_sub_category_id;
    
    -- Check if sub-category exists
    IF v_sub_category.id IS NULL THEN
        RAISE EXCEPTION 'Department sub-category not found';
    END IF;
    
    -- Check if sub-category is being used in active complaints
    SELECT COUNT(*) INTO v_active_complaint_count
    FROM complaints 
    WHERE sub_category_id = p_sub_category_id AND is_active = true;
    
    -- Set category name
    v_category_name := v_sub_category.category_name;
    
    -- If sub-category has active complaints, raise exception
    IF v_active_complaint_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete sub-category as it is being used in active complaints';
    END IF;
    
    -- Soft delete the sub-category
    UPDATE department_sub_categories
    SET 
        is_active = false, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_sub_category_id;
    
    -- Return the deleted sub-category data
    deleted_id := v_sub_category.id;
    deleted_category_id := v_sub_category.category_id;
    deleted_name := v_sub_category.name;
    deleted_is_active := false;
    deleted_updated_at := CURRENT_TIMESTAMP;
    category_name := v_category_name;
    has_active_complaints := v_active_complaint_count > 0;
    active_complaint_count := v_active_complaint_count;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM delete_department_sub_category(1);

-- ============================================
-- END OF FILE
-- ============================================