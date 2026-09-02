DROP FUNCTION IF EXISTS sp_update_society_profile(INT, VARCHAR, TEXT, TEXT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION sp_update_society_profile(
    p_society_id INT,
    p_name VARCHAR(200) DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_city VARCHAR(100) DEFAULT NULL,
    p_state VARCHAR(100) DEFAULT NULL,
    p_pincode VARCHAR(20) DEFAULT NULL,
    p_admin_name VARCHAR(100) DEFAULT NULL,
    p_admin_phone VARCHAR(15) DEFAULT NULL,
    p_admin_profile_pic VARCHAR(255) DEFAULT NULL
)
RETURNS TABLE (
    status_code INT,
    status_message VARCHAR(100),
    id INT,
    name VARCHAR(200),
    description TEXT,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(20),
    admin_name VARCHAR(100),
    admin_email VARCHAR(100),
    admin_phone VARCHAR(15),
    admin_profile_pic VARCHAR(255),
    admin_last_login TIMESTAMP,
    total_units INT,
    total_residents INT,
    is_active BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_name VARCHAR(200);
    v_old_city VARCHAR(100);
    v_target_name VARCHAR(200);
    v_target_city VARCHAR(100);
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM societies WHERE societies.id = p_society_id), s.name, s.city
    INTO v_exists, v_old_name, v_old_city
    FROM societies s
    WHERE s.id = p_society_id;

    IF NOT v_exists THEN
        RETURN QUERY SELECT 404, 'NOT_FOUND'::VARCHAR(100), 
            NULL::INT, NULL::VARCHAR(200), NULL::TEXT, NULL::TEXT, NULL::VARCHAR(100), 
            NULL::VARCHAR(100), NULL::VARCHAR(20), NULL::VARCHAR(100), NULL::VARCHAR(100), 
            NULL::VARCHAR(15), NULL::VARCHAR(255), NULL::TIMESTAMP, NULL::INT, NULL::INT, 
            NULL::BOOLEAN, NULL::TIMESTAMP, NULL::TIMESTAMP;
        RETURN;
    END IF;

    v_target_name := COALESCE(p_name, v_old_name);
    v_target_city := COALESCE(p_city, v_old_city);

    IF EXISTS (
        SELECT 1 FROM societies s
        WHERE s.name = v_target_name 
          AND s.city = v_target_city 
          AND s.id != p_society_id
    ) THEN
        RETURN QUERY SELECT 400, 'DUPLICATE_NAME_CITY'::VARCHAR(100), 
            NULL::INT, NULL::VARCHAR(200), NULL::TEXT, NULL::TEXT, NULL::VARCHAR(100), 
            NULL::VARCHAR(100), NULL::VARCHAR(20), NULL::VARCHAR(100), NULL::VARCHAR(100), 
            NULL::VARCHAR(15), NULL::VARCHAR(255), NULL::TIMESTAMP, NULL::INT, NULL::INT, 
            NULL::BOOLEAN, NULL::TIMESTAMP, NULL::TIMESTAMP;
        RETURN;
    END IF;

    RETURN QUERY
    UPDATE societies s
    SET 
        name = COALESCE(p_name, s.name),
        description = COALESCE(p_description, s.description),
        address = COALESCE(p_address, s.address),
        city = COALESCE(p_city, s.city),
        state = COALESCE(p_state, s.state),
        pincode = COALESCE(p_pincode, s.pincode),
        admin_name = COALESCE(p_admin_name, s.admin_name),
        admin_phone = COALESCE(p_admin_phone, s.admin_phone),
        admin_profile_pic = COALESCE(p_admin_profile_pic, s.admin_profile_pic),
        updated_at = CURRENT_TIMESTAMP
    WHERE s.id = p_society_id
    RETURNING 
        200, 
        'SUCCESS'::VARCHAR(100),
        s.id, s.name, s.description, s.address, s.city, s.state, s.pincode,
        s.admin_name, s.admin_email, s.admin_phone, s.admin_profile_pic,
        s.admin_last_login, s.total_units, s.total_residents,
        s.is_active, s.created_at, s.updated_at;
END;
$$;