-- ============================================
-- UPDATE WORKER STORED PROCEDURE
-- ============================================
-- File: updateworkersp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS update_worker(INTEGER, INTEGER, VARCHAR, VARCHAR, VARCHAR, INTEGER, INTEGER, BOOLEAN) CASCADE;

-- ============================================
-- UPDATE WORKER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_worker(
    p_worker_id INTEGER,
    p_manager_id INTEGER,
    p_full_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_department_category_id INTEGER,
    p_department_sub_category_id INTEGER,
    p_is_active BOOLEAN
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
    worker_last_login TIMESTAMP,
    worker_created_at TIMESTAMP,
    worker_updated_at TIMESTAMP,
    old_full_name VARCHAR,
    old_email VARCHAR,
    old_phone VARCHAR,
    old_category_name VARCHAR,
    old_sub_category_name VARCHAR,
    old_is_active BOOLEAN,
    category_name VARCHAR,
    sub_category_name VARCHAR,
    manager_name VARCHAR,
    society_name VARCHAR
) AS $$
DECLARE
    v_old_data RECORD;
    v_email_exists BOOLEAN;
    v_phone_exists BOOLEAN;
    v_result RECORD;
    v_manager_category_id INTEGER;
    v_category_name VARCHAR;
    v_sub_category_name VARCHAR;
    v_manager_name VARCHAR;
    v_society_name VARCHAR;
BEGIN
    -- Get manager's category
    SELECT department_category_id INTO v_manager_category_id
    FROM managers 
    WHERE id = p_manager_id AND is_active = true;
    
    IF v_manager_category_id IS NULL THEN
        RAISE EXCEPTION 'Manager not found or inactive';
    END IF;
    
    -- Check if worker exists and belongs to this manager
    SELECT 
        w.id,
        w.full_name,
        w.email,
        w.phone,
        w.department_category_id,
        w.department_sub_category_id,
        w.is_active,
        w.society_id,
        w.manager_id,
        dc.name as category_name,
        dsc.name as sub_category_name
    INTO v_old_data
    FROM workers w
    LEFT JOIN department_categories dc ON w.department_category_id = dc.id
    LEFT JOIN department_sub_categories dsc ON w.department_sub_category_id = dsc.id
    WHERE w.id = p_worker_id AND w.manager_id = p_manager_id
    AND w.department_category_id = v_manager_category_id;
    
    IF v_old_data.id IS NULL THEN
        RAISE EXCEPTION 'Worker not found or not created by you';
    END IF;
    
    -- Check email uniqueness if changing
    IF p_email IS NOT NULL AND p_email != v_old_data.email THEN
        SELECT EXISTS(
            SELECT 1 FROM workers 
            WHERE email = p_email AND id != p_worker_id
        ) INTO v_email_exists;
        
        IF v_email_exists THEN
            RAISE EXCEPTION 'Email already in use';
        END IF;
    END IF;
    
    -- Check phone uniqueness if changing
    IF p_phone IS NOT NULL AND p_phone != v_old_data.phone THEN
        SELECT EXISTS(
            SELECT 1 FROM workers 
            WHERE phone = p_phone AND id != p_worker_id
        ) INTO v_phone_exists;
        
        IF v_phone_exists THEN
            RAISE EXCEPTION 'Phone number already in use';
        END IF;
    END IF;
    
    -- Update the worker
    UPDATE workers
    SET 
        full_name = COALESCE(p_full_name, full_name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone),
        department_category_id = COALESCE(p_department_category_id, department_category_id),
        department_sub_category_id = COALESCE(p_department_sub_category_id, department_sub_category_id),
        is_active = COALESCE(p_is_active, is_active),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_worker_id AND manager_id = p_manager_id
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
        last_login,
        created_at,
        updated_at
    INTO v_result;
    
    -- Get updated worker data with names
    SELECT 
        dc.name,
        dsc.name,
        m.full_name,
        s.name
    INTO 
        v_category_name,
        v_sub_category_name,
        v_manager_name,
        v_society_name
    FROM workers w
    LEFT JOIN department_categories dc ON w.department_category_id = dc.id
    LEFT JOIN department_sub_categories dsc ON w.department_sub_category_id = dsc.id
    JOIN managers m ON w.manager_id = m.id
    JOIN societies s ON w.society_id = s.id
    WHERE w.id = p_worker_id;
    
    -- Return the updated worker data
    worker_id := v_result.id;
    worker_society_id := v_result.society_id;
    worker_manager_id := v_result.manager_id;
    worker_full_name := v_result.full_name;
    worker_email := v_result.email;
    worker_phone := v_result.phone;
    worker_department_category_id := v_result.department_category_id;
    worker_department_sub_category_id := v_result.department_sub_category_id;
    worker_is_active := v_result.is_active;
    worker_last_login := v_result.last_login;
    worker_created_at := v_result.created_at;
    worker_updated_at := v_result.updated_at;
    old_full_name := v_old_data.full_name;
    old_email := v_old_data.email;
    old_phone := v_old_data.phone;
    old_category_name := v_old_data.category_name;
    old_sub_category_name := v_old_data.sub_category_name;
    old_is_active := v_old_data.is_active;
    category_name := v_category_name;
    sub_category_name := v_sub_category_name;
    manager_name := v_manager_name;
    society_name := v_society_name;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM update_worker(3, 3, 'Updated Worker', 'updated@test.com', '9876543210', 5, 42, true);

-- ============================================
-- END OF FILE
-- ============================================