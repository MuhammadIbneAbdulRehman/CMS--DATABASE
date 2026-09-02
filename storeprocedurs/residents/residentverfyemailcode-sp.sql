-- ============================================
-- VERIFY EMAIL CODE STORED PROCEDURE
-- ============================================
-- File: verifyemailcodesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS verify_email_code(VARCHAR, VARCHAR) CASCADE;

-- ============================================
-- VERIFY EMAIL CODE FUNCTION (6-digit code)
-- ============================================

CREATE OR REPLACE FUNCTION verify_email_code(
    p_email VARCHAR,
    p_code VARCHAR
)
RETURNS TABLE(
    resident_id INTEGER,
    resident_email VARCHAR,
    resident_full_name VARCHAR,
    resident_is_email_verified BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_resident RECORD;
BEGIN
    -- Find resident with this email and code
    SELECT 
        id,
        email,
        full_name,
        is_email_verified,
        email_verification_expiry
    INTO v_resident
    FROM residents 
    WHERE email = p_email AND email_verification_token = p_code;
    
    -- Check if resident exists
    IF v_resident.id IS NULL THEN
        RAISE EXCEPTION 'Invalid verification code';
    END IF;
    
    -- Check if already verified
    IF v_resident.is_email_verified THEN
        RAISE EXCEPTION 'Email already verified';
    END IF;
    
    -- Check if code expired
    IF v_resident.email_verification_expiry < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Verification code has expired. Please request a new one.';
    END IF;
    
    -- Update verification status
    UPDATE residents 
    SET 
        is_email_verified = true,
        email_verified_at = CURRENT_TIMESTAMP,
        email_verification_token = NULL,
        email_verification_expiry = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_resident.id;
    
    -- Return success
    resident_id := v_resident.id;
    resident_email := v_resident.email;
    resident_full_name := v_resident.full_name;
    resident_is_email_verified := true;
    message := 'Email verified successfully! You can now login.';
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM verify_email_code('john@example.com', '123456');

-- ============================================
-- END OF FILE
-- ============================================


