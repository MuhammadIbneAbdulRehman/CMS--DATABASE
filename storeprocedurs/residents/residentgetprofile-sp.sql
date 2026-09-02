-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_resident_profile(INTEGER) CASCADE;

-- ============================================
-- GET RESIDENT PROFILE FUNCTION (UPDATED)
-- ============================================

CREATE OR REPLACE FUNCTION get_resident_profile(
    p_resident_id INTEGER
)
RETURNS TABLE(
    resident_id INTEGER,
    resident_unit_id INTEGER,
    resident_full_name VARCHAR,
    resident_email VARCHAR,
    resident_phone VARCHAR,
    resident_alternate_phone VARCHAR,
    resident_resident_type VARCHAR,
    resident_is_email_verified BOOLEAN,
    resident_is_phone_verified BOOLEAN,
    resident_last_login TIMESTAMP,
    resident_preferred_language VARCHAR,
    resident_is_active BOOLEAN,
    resident_created_at TIMESTAMP,
    resident_updated_at TIMESTAMP,
    resident_address VARCHAR,
    resident_pin_code VARCHAR,
    resident_location VARCHAR,
    unit_number VARCHAR,
    unit_type VARCHAR,
    usage_type VARCHAR,
    floor_number INTEGER,
    size_sqft DECIMAL,
    room_count INTEGER,
    block_name VARCHAR,
    block_id INTEGER,
    phase_name VARCHAR,
    phase_id INTEGER,
    society_name VARCHAR,
    society_id INTEGER
) AS $$
DECLARE
    v_resident_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Check if resident exists
    SELECT EXISTS(
        SELECT 1 FROM residents WHERE id = p_resident_id
    ) INTO v_resident_exists;
    
    IF NOT v_resident_exists THEN
        RAISE EXCEPTION 'Resident not found';
    END IF;
    
    -- Get resident profile with all related info
    -- ✅ UPDATED: Get phase from BLOCK instead of UNIT
    SELECT
        r.id,
        r.unit_id,
        r.full_name,
        r.email,
        r.phone,
        r.alternate_phone,
        r.resident_type,
        r.is_email_verified,
        r.is_phone_verified,
        r.last_login,
        r.preferred_language,
        r.is_active,
        r.created_at,
        r.updated_at,
        r.address,
        r.pin_code,
        r.location,
        u.unit_number,
        u.unit_type,
        u.usage_type,
        u.floor_number,
        u.size_sqft,
        u.room_count,
        b.name as block_name,
        b.id as block_id,
        -- ✅ Get phase from BLOCK (b.phase_id) instead of unit (u.phase_id)
        bp.name as phase_name,
        bp.id as phase_id,
        s.name as society_name,
        s.id as society_id
    INTO v_result
    FROM residents r
    JOIN units u ON r.unit_id = u.id
    JOIN blocks b ON u.block_id = b.id
    -- ✅ Join phases through BLOCK instead of unit
    LEFT JOIN phases bp ON b.phase_id = bp.id
    JOIN societies s ON u.society_id = s.id
    WHERE r.id = p_resident_id;
    
    -- Return the profile
    resident_id := v_result.id;
    resident_unit_id := v_result.unit_id;
    resident_full_name := v_result.full_name;
    resident_email := v_result.email;
    resident_phone := v_result.phone;
    resident_alternate_phone := v_result.alternate_phone;
    resident_resident_type := v_result.resident_type;
    resident_is_email_verified := v_result.is_email_verified;
    resident_is_phone_verified := v_result.is_phone_verified;
    resident_last_login := v_result.last_login;
    resident_preferred_language := v_result.preferred_language;
    resident_is_active := v_result.is_active;
    resident_created_at := v_result.created_at;
    resident_updated_at := v_result.updated_at;
    resident_address := v_result.address;
    resident_pin_code := v_result.pin_code;
    resident_location := v_result.location;
    unit_number := v_result.unit_number;
    unit_type := v_result.unit_type;
    usage_type := v_result.usage_type;
    floor_number := v_result.floor_number;
    size_sqft := v_result.size_sqft;
    room_count := v_result.room_count;
    block_name := v_result.block_name;
    block_id := v_result.block_id;
    -- ✅ These will now have values from the block
    phase_name := v_result.phase_name;
    phase_id := v_result.phase_id;
    society_name := v_result.society_name;
    society_id := v_result.society_id;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

