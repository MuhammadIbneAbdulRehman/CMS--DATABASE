-- ============================================
-- UPDATE RESIDENT PROFILE STORED PROCEDURE
-- ============================================
-- File: updateresidentprofilesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS update_resident_profile(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;

-- ============================================
-- UPDATE RESIDENT PROFILE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_resident_profile(
    p_resident_id INTEGER,
    p_full_name VARCHAR,
    p_phone VARCHAR,
    p_alternate_phone VARCHAR,
    p_preferred_language VARCHAR,
    p_address VARCHAR,
    p_pin_code VARCHAR,
    p_location VARCHAR
)
RETURNS TABLE(
    resident_id INTEGER,
    resident_unit_id INTEGER,
    resident_full_name VARCHAR,
    resident_email VARCHAR,
    resident_phone VARCHAR,
    resident_alternate_phone VARCHAR,
    resident_resident_type VARCHAR,
    resident_address VARCHAR,
    resident_pin_code VARCHAR,
    resident_location VARCHAR,
    resident_is_email_verified BOOLEAN,
    resident_is_phone_verified BOOLEAN,
    resident_preferred_language VARCHAR,
    resident_is_active BOOLEAN,
    resident_created_at TIMESTAMP,
    resident_updated_at TIMESTAMP
) AS $$
DECLARE
    v_resident_exists BOOLEAN;
    v_phone_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Check if resident exists and is active
    SELECT EXISTS(
        SELECT 1 FROM residents 
        WHERE id = p_resident_id AND is_active = true
    ) INTO v_resident_exists;
    
    IF NOT v_resident_exists THEN
        RAISE EXCEPTION 'Resident not found';
    END IF;
    
    -- Check phone uniqueness if changing
    IF p_phone IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM residents 
            WHERE phone = p_phone AND id != p_resident_id
        ) INTO v_phone_exists;
        
        IF v_phone_exists THEN
            RAISE EXCEPTION 'Phone number already in use';
        END IF;
    END IF;
    
    -- Update using COALESCE - only update provided values
    UPDATE residents 
    SET 
        full_name = COALESCE(p_full_name, full_name),
        phone = COALESCE(p_phone, phone),
        alternate_phone = COALESCE(p_alternate_phone, alternate_phone),
        preferred_language = COALESCE(p_preferred_language, preferred_language),
        address = COALESCE(p_address, address),
        pin_code = COALESCE(p_pin_code, pin_code),
        location = COALESCE(p_location, location),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_resident_id AND is_active = true
    RETURNING 
        id,
        unit_id,
        full_name,
        email,
        phone,
        alternate_phone,
        resident_type,
        address,
        pin_code,
        location,
        is_email_verified,
        is_phone_verified,
        preferred_language,
        is_active,
        created_at,
        updated_at
    INTO v_result;
    
    -- Return the updated profile
    resident_id := v_result.id;
    resident_unit_id := v_result.unit_id;
    resident_full_name := v_result.full_name;
    resident_email := v_result.email;
    resident_phone := v_result.phone;
    resident_alternate_phone := v_result.alternate_phone;
    resident_resident_type := v_result.resident_type;
    resident_address := v_result.address;
    resident_pin_code := v_result.pin_code;
    resident_location := v_result.location;
    resident_is_email_verified := v_result.is_email_verified;
    resident_is_phone_verified := v_result.is_phone_verified;
    resident_preferred_language := v_result.preferred_language;
    resident_is_active := v_result.is_active;
    resident_created_at := v_result.created_at;
    resident_updated_at := v_result.updated_at;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM update_resident_profile(1, 'John Updated', '9876543210', NULL, 'en', '123 New St', '54321', NULL);

-- ============================================
-- END OF FILE
-- ============================================