-- ============================================
-- CREATE WORKER STORED PROCEDURE
-- ============================================
-- File: createworkersp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS create_worker(INTEGER, INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INTEGER, INTEGER, INTEGER) CASCADE;

-- ============================================
-- CREATE WORKER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION create_worker(
    p_society_id INTEGER,
    p_manager_id INTEGER,
    p_full_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_password_hash TEXT,
    p_department_category_id INTEGER,
    p_department_sub_category_id INTEGER,
    p_created_by INTEGER
)
RETURNS TABLE(
    worker_id INTEGER,
    worker_society_id INTEGER,
    worker_manager_id INTEGER,
    worker_full_name VARCHAR,
    worker_email VARCHAR,
    worker_phone VARCHAR,
    worker_department_category_id INTEGER,
    worker_department_sub_category_id INTEGER,
    worker_is_active BOOLEAN,
    worker_created_at TIMESTAMP,
    manager_name VARCHAR,
    society_name VARCHAR,
    category_name VARCHAR,
    sub_category_name VARCHAR
) AS $$
DECLARE
    v_manager_exists BOOLEAN;
    v_manager_category_id INTEGER;
    v_email_exists BOOLEAN;
    v_phone_exists BOOLEAN;
    v_sub_category RECORD;
    v_result RECORD;
    v_manager_name VARCHAR;
    v_society_name VARCHAR;
    v_category_name VARCHAR;
    v_sub_category_name VARCHAR;
BEGIN
    -- Check if manager exists and is active
    SELECT 
        is_active,
        department_category_id
    INTO v_manager_exists, v_manager_category_id
    FROM managers 
    WHERE id = p_manager_id;
    
    IF v_manager_exists IS NULL OR v_manager_exists = false THEN
        RAISE EXCEPTION 'Manager not found or inactive';
    END IF;
    
    -- Check email uniqueness
    SELECT EXISTS(
        SELECT 1 FROM workers WHERE email = p_email
    ) INTO v_email_exists;
    
    IF v_email_exists THEN
        RAISE EXCEPTION 'Email already registered';
    END IF;
    
    -- Check phone uniqueness
    SELECT EXISTS(
        SELECT 1 FROM workers WHERE phone = p_phone
    ) INTO v_phone_exists;
    
    IF v_phone_exists THEN
        RAISE EXCEPTION 'Phone number already registered';
    END IF;
    
    -- If sub-category is provided, validate it belongs to manager's category
    IF p_department_sub_category_id IS NOT NULL THEN
        SELECT 
            dsc.id,
            dsc.category_id,
            dsc.name as sub_name,
            dc.name as cat_name
        INTO v_sub_category
        FROM department_sub_categories dsc
        LEFT JOIN department_categories dc ON dsc.category_id = dc.id
        WHERE dsc.id = p_department_sub_category_id AND dsc.is_active = true;
        
        IF v_sub_category.id IS NULL THEN
            RAISE EXCEPTION 'Sub-category not found or inactive';
        END IF;
        
        -- Validate sub-category belongs to manager's category
        IF v_sub_category.category_id != v_manager_category_id THEN
            RAISE EXCEPTION 'Sub-category does not belong to your category. You can only assign workers to sub-categories under your category.';
        END IF;
    END IF;
    
    -- Determine final category
    -- If sub-category provided, use its category, otherwise use manager's category or provided category
    IF p_department_sub_category_id IS NOT NULL THEN
        p_department_category_id := v_sub_category.category_id;
    ELSIF p_department_category_id IS NULL THEN
        p_department_category_id := v_manager_category_id;
    END IF;
    
    -- Insert worker
    INSERT INTO workers (
        society_id,
        manager_id,
        full_name,
        email,
        phone,
        password_hash,
        department_category_id,
        department_sub_category_id,
        created_by,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_society_id,
        p_manager_id,
        p_full_name,
        p_email,
        p_phone,
        p_password_hash,
        p_department_category_id,
        p_department_sub_category_id,
        p_created_by,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING 
        id,
        society_id,
        manager_id,
        full_name,
        email,
        phone,
        department_category_id,
        department_sub_category_id,
        is_active,
        created_at
    INTO v_result;
    
    -- Get manager, society, category and sub-category names
    SELECT 
        m.full_name,
        s.name,
        dc.name,
        dsc.name
    INTO 
        v_manager_name,
        v_society_name,
        v_category_name,
        v_sub_category_name
    FROM managers m
    JOIN societies s ON m.society_id = s.id
    LEFT JOIN department_categories dc ON dc.id = p_department_category_id
    LEFT JOIN department_sub_categories dsc ON dsc.id = p_department_sub_category_id
    WHERE m.id = p_manager_id;
    
    -- Return the worker data
    worker_id := v_result.id;
    worker_society_id := v_result.society_id;
    worker_manager_id := v_result.manager_id;
    worker_full_name := v_result.full_name;
    worker_email := v_result.email;
    worker_phone := v_result.phone;
    worker_department_category_id := v_result.department_category_id;
    worker_department_sub_category_id := v_result.department_sub_category_id;
    worker_is_active := v_result.is_active;
    worker_created_at := v_result.created_at;
    manager_name := v_manager_name;
    society_name := v_society_name;
    category_name := v_category_name;
    sub_category_name := v_sub_category_name;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM create_worker(1, 1, 'John Worker', 'worker@example.com', '1234567890', 'hashed_password', 1, NULL, 1);

-- ============================================
-- END OF FILE
-- ============================================