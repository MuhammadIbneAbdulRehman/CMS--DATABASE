-- ============================================
-- UPDATE DEPARTMENT CATEGORY STORED PROCEDURE (FIXED)
-- ============================================
-- File: updatedepartmentcategorysp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS update_department_category(INTEGER, VARCHAR, BOOLEAN) CASCADE;

-- ============================================
-- UPDATE DEPARTMENT CATEGORY FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_department_category(
    p_category_id INTEGER,
    p_name VARCHAR,
    p_is_active BOOLEAN
)
RETURNS TABLE(
    updated_id INTEGER,
    updated_society_id INTEGER,
    updated_name VARCHAR,
    updated_is_active BOOLEAN,
    updated_created_at TIMESTAMP,
    updated_updated_at TIMESTAMP,
    old_name VARCHAR,
    old_is_active BOOLEAN,
    sub_categories_updated BOOLEAN,
    sub_category_count BIGINT
) AS $$
DECLARE
    v_old_data RECORD;
    v_result RECORD;
    v_sub_category_count BIGINT;
    v_sub_categories_updated BOOLEAN := false;
BEGIN
    -- Get old data
    SELECT 
        id,
        society_id,
        name,
        is_active
    INTO v_old_data
    FROM department_categories 
    WHERE id = p_category_id;
    
    -- Check if category exists
    IF v_old_data.id IS NULL THEN
        RAISE EXCEPTION 'Department category not found';
    END IF;
    
    -- Count sub-categories
    SELECT COUNT(*) INTO v_sub_category_count
    FROM department_sub_categories 
    WHERE category_id = p_category_id;
    
    -- Check if is_active is being changed
    IF p_is_active IS NOT NULL AND p_is_active != v_old_data.is_active THEN
        -- Update all sub-categories under this category (cascade)
        UPDATE department_sub_categories 
        SET is_active = p_is_active, 
            updated_at = CURRENT_TIMESTAMP
        WHERE category_id = p_category_id;
        
        v_sub_categories_updated := true;
    END IF;
    
    -- Update the category
    UPDATE department_categories
    SET 
        name = COALESCE(p_name, name),
        is_active = COALESCE(p_is_active, is_active),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_category_id
    RETURNING 
        id,
        society_id,
        name,
        is_active,
        created_at,
        updated_at
    INTO v_result;
    
    -- Return the updated category with prefixed names
    updated_id := v_result.id;
    updated_society_id := v_result.society_id;
    updated_name := v_result.name;
    updated_is_active := v_result.is_active;
    updated_created_at := v_result.created_at;
    updated_updated_at := v_result.updated_at;
    old_name := v_old_data.name;
    old_is_active := v_old_data.is_active;
    sub_categories_updated := v_sub_categories_updated;
    sub_category_count := v_sub_category_count;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM update_department_category(1, 'Updated Category', true);

-- ============================================
-- END OF FILE
-- ============================================