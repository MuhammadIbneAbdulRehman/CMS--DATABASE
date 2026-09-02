-- ============================================
-- GET PHASES BY SOCIETY STORED PROCEDURE
-- ============================================
-- File: getphasesbysocietysp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_phases_by_society(INTEGER) CASCADE;

-- ============================================
-- GET PHASES BY SOCIETY FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_phases_by_society(
    p_society_id INTEGER
)
RETURNS TABLE(
    phase_id INTEGER,
    phase_society_id INTEGER,
    phase_name VARCHAR,
    phase_description TEXT,
    phase_sequence_number INTEGER,
    phase_is_active BOOLEAN,
    phase_created_at TIMESTAMP,
    phase_updated_at TIMESTAMP,
    society_id INTEGER,
    society_name VARCHAR,
    society_admin_name VARCHAR,
    society_admin_email VARCHAR
) AS $$
DECLARE
    v_society_exists BOOLEAN;
    v_society_record RECORD;
BEGIN
    -- Check if society exists and is active
    SELECT EXISTS(
        SELECT 1 FROM societies 
        WHERE id = p_society_id AND is_active = true
    ) INTO v_society_exists;
    
    IF NOT v_society_exists THEN
        RAISE EXCEPTION 'Society not found or inactive';
    END IF;
    
    -- Get society details
    SELECT 
        id,
        name,
        admin_name,
        admin_email
    INTO v_society_record
    FROM societies
    WHERE id = p_society_id;
    
    -- Return phases with society details
    RETURN QUERY
    SELECT 
        p.id AS phase_id,
        p.society_id AS phase_society_id,
        p.name AS phase_name,
        p.description AS phase_description,
        p.sequence_number AS phase_sequence_number,
        p.is_active AS phase_is_active,
        p.created_at AS phase_created_at,
        p.updated_at AS phase_updated_at,
        v_society_record.id AS society_id,
        v_society_record.name AS society_name,
        v_society_record.admin_name AS society_admin_name,
        v_society_record.admin_email AS society_admin_email
    FROM phases p
    WHERE p.society_id = p_society_id 
        AND p.is_active = true
    ORDER BY p.sequence_number NULLS LAST, p.created_at ASC;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_phases_by_society(1);

-- ============================================
-- END OF FILE
-- ============================================