-- ============================================
-- UPDATE DEPARTMENT SUB-CATEGORY STORED PROCEDURE
-- ============================================
-- File: updatedepartmentsubcatsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS update_department_sub_category(INTEGER, VARCHAR, INTEGER, BOOLEAN, INTEGER) CASCADE;

-- ============================================
-- UPDATE DEPARTMENT SUB-CATEGORY FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_department_sub_category(
    p_sub_category_id INTEGER,
    p_name VARCHAR,
    p_category_id INTEGER,
    p_is_active BOOLEAN,
    p_sla_hours INTEGER
)
RETURNS TABLE(
    updated_id INTEGER,
    updated_category_id INTEGER,
    updated_name VARCHAR,
    updated_is_active BOOLEAN,
    updated_sla_hours INTEGER,
    updated_created_at TIMESTAMP,
    updated_updated_at TIMESTAMP,
    old_name VARCHAR,
    old_category_id INTEGER,
    old_is_active BOOLEAN,
    old_sla_hours INTEGER,
    category_name VARCHAR,
    category_is_active BOOLEAN
) AS $$
DECLARE
    v_old_data RECORD;
    v_category_exists BOOLEAN;
    v_category_name VARCHAR;
    v_category_is_active BOOLEAN;
    v_duplicate_exists BOOLEAN;
    v_target_category_id INTEGER;
    v_result RECORD;
BEGIN
    -- Get old data
    SELECT 
        id,
        name,
        category_id,
        is_active,
        sla_hours
    INTO v_old_data
    FROM department_sub_categories 
    WHERE id = p_sub_category_id;
    
    -- Check if sub-category exists
    IF v_old_data.id IS NULL THEN
        RAISE EXCEPTION 'Department sub-category not found';
    END IF;
    
    -- Determine target category ID for uniqueness check
    v_target_category_id := COALESCE(p_category_id, v_old_data.category_id);
    
    -- If category_id is being changed, check if new category exists
    IF p_category_id IS NOT NULL AND p_category_id != v_old_data.category_id THEN
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
    END IF;
    
    -- Check name uniqueness if changing
    IF p_name IS NOT NULL AND p_name != v_old_data.name THEN
        SELECT EXISTS(
            SELECT 1 FROM department_sub_categories 
            WHERE category_id = v_target_category_id 
            AND name = p_name 
            AND id != p_sub_category_id
        ) INTO v_duplicate_exists;
        
        IF v_duplicate_exists THEN
            RAISE EXCEPTION 'Sub-category already exists in this category';
        END IF;
    END IF;
    
    -- Update the sub-category
    UPDATE department_sub_categories
    SET 
        name = COALESCE(p_name, name),
        category_id = COALESCE(p_category_id, category_id),
        is_active = COALESCE(p_is_active, is_active),
        sla_hours = COALESCE(p_sla_hours, sla_hours),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_sub_category_id
    RETURNING 
        id,
        category_id,
        name,
        is_active,
        sla_hours,
        created_at,
        updated_at
    INTO v_result;
    
    -- Get category details for the new/current category
    SELECT 
        name,
        is_active
    INTO 
        v_category_name,
        v_category_is_active
    FROM department_categories 
    WHERE id = v_result.category_id;
    
    -- Return the updated sub-category
    updated_id := v_result.id;
    updated_category_id := v_result.category_id;
    updated_name := v_result.name;
    updated_is_active := v_result.is_active;
    updated_sla_hours := v_result.sla_hours;
    updated_created_at := v_result.created_at;
    updated_updated_at := v_result.updated_at;
    old_name := v_old_data.name;
    old_category_id := v_old_data.category_id;
    old_is_active := v_old_data.is_active;
    old_sla_hours := v_old_data.sla_hours;
    category_name := v_category_name;
    category_is_active := v_category_is_active;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM update_department_sub_category(1, 'Updated CCTV', 1, true, 48);

-- ============================================
-- END OF FILE
-- ============================================