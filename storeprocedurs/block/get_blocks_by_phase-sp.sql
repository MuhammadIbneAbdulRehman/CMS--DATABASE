-- ============================================
-- GET BLOCKS BY PHASE STORED PROCEDURE (FIXED)
-- ============================================
-- File: getblocksbyphasesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_blocks_by_phase(INTEGER) CASCADE;

-- ============================================
-- GET BLOCKS BY PHASE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_blocks_by_phase(
    p_phase_id INTEGER
)
RETURNS TABLE(
    block_id INTEGER,
    block_society_id INTEGER,
    block_phase_id INTEGER,
    block_name VARCHAR,
    block_description TEXT,
    block_total_units INTEGER,
    block_is_active BOOLEAN,
    block_created_at TIMESTAMP,
    block_updated_at TIMESTAMP,
    phase_id INTEGER,
    phase_name VARCHAR
) AS $$
DECLARE
    v_phase_record RECORD;
BEGIN
    -- Get phase details (check existence and active status)
    SELECT 
        id,
        name,
        is_active
    INTO v_phase_record
    FROM phases
    WHERE id = p_phase_id;
    
    -- Check if phase exists
    IF v_phase_record.id IS NULL THEN
        RAISE EXCEPTION 'Phase not found';
    END IF;
    
    -- Check if phase is active
    IF v_phase_record.is_active = false THEN
        RAISE EXCEPTION 'Phase is inactive';
    END IF;
    
    -- Return blocks with phase details
    RETURN QUERY
    SELECT 
        b.id AS block_id,
        b.society_id AS block_society_id,
        b.phase_id AS block_phase_id,
        b.name AS block_name,
        b.description AS block_description,
        b.total_units AS block_total_units,
        b.is_active AS block_is_active,
        b.created_at AS block_created_at,
        b.updated_at AS block_updated_at,
        v_phase_record.id AS phase_id,
        v_phase_record.name AS phase_name
    FROM blocks b
    WHERE b.phase_id = p_phase_id 
        AND b.is_active = true
    ORDER BY b.name ASC;
    
END;
$$ LANGUAGE plpgsql;

