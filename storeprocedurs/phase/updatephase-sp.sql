-- ============================================
-- UPDATE PHASE STORED PROCEDURE (FIXED)
-- ============================================
-- File: updatephasesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS update_phase(INTEGER, VARCHAR, TEXT, INTEGER, BOOLEAN) CASCADE;

-- ============================================
-- UPDATE PHASE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_phase(
    p_id INTEGER,
    p_name VARCHAR,
    p_description TEXT,
    p_sequence_number INTEGER,
    p_is_active BOOLEAN
)
RETURNS TABLE(
    phase_id INTEGER,
    phase_society_id INTEGER,
    phase_name VARCHAR,
    phase_description TEXT,
    phase_sequence_number INTEGER,
    phase_is_active BOOLEAN,
    phase_created_at TIMESTAMP,
    phase_updated_at TIMESTAMP
) AS $$
DECLARE
    v_old_data RECORD;
    v_duplicate_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Get old data and check existence
    SELECT * INTO v_old_data FROM phases WHERE id = p_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Phase not found';
    END IF;
    
    -- Check name uniqueness if changing
    IF p_name IS NOT NULL AND p_name != v_old_data.name THEN
        SELECT EXISTS(
            SELECT 1 FROM phases 
            WHERE society_id = v_old_data.society_id 
                AND name = p_name 
                AND id != p_id
        ) INTO v_duplicate_exists;
        
        IF v_duplicate_exists THEN
            RAISE EXCEPTION 'Phase with this name already exists in this society';
        END IF;
    END IF;
    
    -- Update using COALESCE - only update provided values
    UPDATE phases 
    SET 
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        sequence_number = COALESCE(p_sequence_number, sequence_number),
        is_active = COALESCE(p_is_active, is_active),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_id
    RETURNING 
        id,
        society_id,
        name,
        description,
        sequence_number,
        is_active,
        created_at,
        updated_at
    INTO v_result;
    
    -- Return the updated phase
    phase_id := v_result.id;
    phase_society_id := v_result.society_id;
    phase_name := v_result.name;
    phase_description := v_result.description;
    phase_sequence_number := v_result.sequence_number;
    phase_is_active := v_result.is_active;
    phase_created_at := v_result.created_at;
    phase_updated_at := v_result.updated_at;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM update_phase(1, 'Updated Phase', 'Updated description', 2, true);

-- ============================================
-- END OF FILE
-- ============================================