-- ============================================
-- RESIDENT LOGIN STORED PROCEDURE
-- ============================================
-- File: residentloginsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS resident_login(VARCHAR) CASCADE;

-- ============================================
-- RESIDENT LOGIN FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION resident_login(
    p_email VARCHAR
)
RETURNS TABLE(
    resident_id INTEGER,
    resident_unit_id INTEGER,
    resident_full_name VARCHAR,
    resident_email VARCHAR,
    resident_phone VARCHAR,
    resident_password_hash TEXT,
    resident_address VARCHAR,
    resident_pin_code VARCHAR,
    resident_location VARCHAR,
    resident_is_active BOOLEAN,
    resident_is_email_verified BOOLEAN,
    resident_last_login TIMESTAMP,
    resident_created_at TIMESTAMP,
    resident_updated_at TIMESTAMP,
    unit_number VARCHAR,
    block_id INTEGER,
    block_name VARCHAR,
    society_id INTEGER,
    society_name VARCHAR
) AS $$
DECLARE
    v_resident_exists BOOLEAN;
    v_resident RECORD;
    v_unit_info RECORD;
BEGIN
    -- Check if resident exists and is active
    SELECT EXISTS(
        SELECT 1 FROM residents 
        WHERE email = p_email AND is_active = true
    ) INTO v_resident_exists;
    
    IF NOT v_resident_exists THEN
        RAISE EXCEPTION 'Resident not found';
    END IF;
    
    -- Get resident details
    SELECT 
        id,
        unit_id,
        full_name,
        email,
        phone,
        password_hash,
        address,
        pin_code,
        location,
        is_active,
        is_email_verified,
        last_login,
        created_at,
        updated_at
    INTO v_resident
    FROM residents 
    WHERE email = p_email AND is_active = true;
    
    -- Check if email is verified
    IF NOT v_resident.is_email_verified THEN
        RAISE EXCEPTION 'Email not verified';
    END IF;
    
    -- Get additional unit info
    SELECT 
        u.unit_number,
        u.block_id,
        b.name as block_name,
        u.society_id,
        s.name as society_name
    INTO v_unit_info
    FROM units u
    LEFT JOIN blocks b ON u.block_id = b.id
    LEFT JOIN societies s ON u.society_id = s.id
    WHERE u.id = v_resident.unit_id;
    
    -- Update last login
    UPDATE residents 
    SET last_login = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_resident.id;
    
    -- Return all data
    resident_id := v_resident.id;
    resident_unit_id := v_resident.unit_id;
    resident_full_name := v_resident.full_name;
    resident_email := v_resident.email;
    resident_phone := v_resident.phone;
    resident_password_hash := v_resident.password_hash;
    resident_address := v_resident.address;
    resident_pin_code := v_resident.pin_code;
    resident_location := v_resident.location;
    resident_is_active := v_resident.is_active;
    resident_is_email_verified := v_resident.is_email_verified;
    resident_last_login := v_resident.last_login;
    resident_created_at := v_resident.created_at;
    resident_updated_at := v_resident.updated_at;
    unit_number := v_unit_info.unit_number;
    block_id := v_unit_info.block_id;
    block_name := v_unit_info.block_name;
    society_id := v_unit_info.society_id;
    society_name := v_unit_info.society_name;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM resident_login('john@example.com');

-- ============================================
-- END OF FILE
-- ============================================