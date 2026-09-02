-- ============================================
-- DELETE PHASE STORED PROCEDURE (FIXED)
-- ============================================
-- File: deletephasesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS delete_phase(INTEGER) CASCADE;

-- ============================================
-- DELETE PHASE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION delete_phase(
    p_id INTEGER
)
RETURNS TABLE(
    deleted_id INTEGER,
    deleted_name VARCHAR,
    deleted_is_active BOOLEAN
) AS $$
DECLARE
    v_phase_exists BOOLEAN;
    v_block_count BIGINT;
    v_result RECORD;
BEGIN
    -- Check if phase exists
    SELECT EXISTS(
        SELECT 1 FROM phases WHERE id = p_id
    ) INTO v_phase_exists;
    
    IF NOT v_phase_exists THEN
        RAISE EXCEPTION 'Phase not found';
    END IF;
    
    -- Check if phase has active blocks
    SELECT COUNT(*) INTO v_block_count
    FROM blocks 
    WHERE phase_id = p_id AND is_active = true;
    
    IF v_block_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete phase with active blocks. Deactivate blocks first.';
    END IF;
    
    -- Soft delete the phase
    UPDATE phases
    SET 
        is_active = false, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_id
    RETURNING 
        id,
        name,
        is_active
    INTO v_result;
    
    -- Return the deleted phase with prefixed names
    deleted_id := v_result.id;
    deleted_name := v_result.name;
    deleted_is_active := v_result.is_active;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM delete_phase(1);

-- ============================================
-- END OF FILE
-- ============================================