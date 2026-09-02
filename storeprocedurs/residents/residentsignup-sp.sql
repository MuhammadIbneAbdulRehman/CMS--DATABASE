-- ============================================
-- RESIDENT SIGNUP STORED PROCEDURE (FIXED)
-- ============================================
-- File: residentsignupsp.sql
-- ============================================

-- ============================================
-- FORCE DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS resident_signup(INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR, VARCHAR) CASCADE;

-- ============================================
-- RESIDENT SIGNUP FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION resident_signup(
    p_unit_id INTEGER,
    p_full_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_alternate_phone VARCHAR,
    p_resident_type VARCHAR,
    p_password_hash TEXT,
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
    verification_code VARCHAR,
    society_name VARCHAR,
    unit_number_display VARCHAR
) AS $$
DECLARE
    v_unit_exists BOOLEAN;
    v_society_id INTEGER;
    v_society_name VARCHAR;
    v_unit_number VARCHAR;
    v_resident_exists BOOLEAN;
    v_email_exists BOOLEAN;
    v_phone_exists BOOLEAN;
    v_result RECORD;
    v_verification_code VARCHAR;
    v_code_expiry TIMESTAMP;
BEGIN
    -- Check if unit exists and is active
    SELECT EXISTS(
        SELECT 1 FROM units 
        WHERE id = p_unit_id AND is_active = true
    ) INTO v_unit_exists;
    
    IF NOT v_unit_exists THEN
        RAISE EXCEPTION 'Unit not found or inactive';
    END IF;
    
    -- Get unit details
    SELECT 
        society_id,
        unit_number
    INTO 
        v_society_id,
        v_unit_number
    FROM units 
    WHERE id = p_unit_id;
    
    -- Get society name
    SELECT name INTO v_society_name
    FROM societies 
    WHERE id = v_society_id AND is_active = true;
    
    -- Check if unit already has a resident
    SELECT EXISTS(
        SELECT 1 FROM residents 
        WHERE unit_id = p_unit_id AND is_active = true
    ) INTO v_resident_exists;
    
    IF v_resident_exists THEN
        RAISE EXCEPTION 'This unit already has an active resident';
    END IF;
    
    -- Check if email already exists
    SELECT EXISTS(
        SELECT 1 FROM residents WHERE email = p_email
    ) INTO v_email_exists;
    
    IF v_email_exists THEN
        RAISE EXCEPTION 'Email already registered';
    END IF;
    
    -- Check if phone already exists
    SELECT EXISTS(
        SELECT 1 FROM residents WHERE phone = p_phone
    ) INTO v_phone_exists;
    
    IF v_phone_exists THEN
        RAISE EXCEPTION 'Phone number already registered';
    END IF;
    
    -- Generate 6-digit verification code
    v_verification_code := LPAD(FLOOR(RANDOM() * 900000 + 100000)::TEXT, 6, '0');
    v_code_expiry := CURRENT_TIMESTAMP + INTERVAL '15 minutes';
    
    -- Insert resident
    INSERT INTO residents (
        unit_id,
        full_name,
        email,
        phone,
        alternate_phone,
        resident_type,
        password_hash,
        address,
        pin_code,
        location,
        is_email_verified,
        email_verification_token,
        email_verification_expiry,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_unit_id,
        p_full_name,
        p_email,
        p_phone,
        p_alternate_phone,
        COALESCE(p_resident_type, 'Owner'),
        p_password_hash,
        p_address,
        p_pin_code,
        p_location,
        FALSE,
        v_verification_code,
        v_code_expiry,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
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
        created_at
    INTO v_result;
    
    -- Update society total_residents count
    UPDATE societies 
    SET total_residents = total_residents + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_society_id;
    
    -- Return the inserted resident with prefixed names
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
    verification_code := v_verification_code;
    society_name := v_society_name;
    unit_number_display := v_unit_number;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM resident_signup(1, 'John Doe', 'john@example.com', '1234567890', NULL, 'Owner', 'hashed_password', '123 Main St', '12345', NULL);

-- ============================================
-- END OF FILE
-- ============================================