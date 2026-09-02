-- ============================================
-- CREATE PHASE STORED PROCEDURE (FIXED)
-- ============================================
-- File: createphasesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS create_phase(INTEGER, VARCHAR, TEXT, INTEGER) CASCADE;

-- ============================================
-- CREATE PHASE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION create_phase(
    p_society_id INTEGER,
    p_name VARCHAR,
    p_description TEXT,
    p_sequence_number INTEGER
)
RETURNS TABLE(
    phase_id INTEGER,
    phase_society_id INTEGER,
    phase_name VARCHAR,
    phase_description TEXT,
    phase_sequence_number INTEGER,
    phase_is_active BOOLEAN,
    phase_created_at TIMESTAMP
) AS $$
DECLARE
    v_society_exists BOOLEAN;
    v_phase_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Check if society exists and is active
    SELECT EXISTS(
        SELECT 1 FROM societies 
        WHERE id = p_society_id AND is_active = true
    ) INTO v_society_exists;
    
    IF NOT v_society_exists THEN
        RAISE EXCEPTION 'Society not found or inactive';
    END IF;
    
    -- Check if phase already exists in this society
    SELECT EXISTS(
        SELECT 1 FROM phases 
        WHERE society_id = p_society_id AND name = p_name
    ) INTO v_phase_exists;
    
    IF v_phase_exists THEN
        RAISE EXCEPTION 'Phase with this name already exists in this society';
    END IF;
    
    -- Insert the phase
    INSERT INTO phases (
        society_id,
        name,
        description,
        sequence_number,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_society_id,
        p_name,
        p_description,
        p_sequence_number,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING 
        id,
        society_id,
        name,
        description,
        sequence_number,
        is_active,
        created_at
    INTO 
        v_result;
    
    -- Return the inserted phase with prefixed column names
    phase_id := v_result.id;
    phase_society_id := v_result.society_id;
    phase_name := v_result.name;
    phase_description := v_result.description;
    phase_sequence_number := v_result.sequence_number;
    phase_is_active := v_result.is_active;
    phase_created_at := v_result.created_at;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM create_phase(1, 'Phase 1', 'First phase', 1);

-- ============================================
-- END OF FILE
-- ============================================