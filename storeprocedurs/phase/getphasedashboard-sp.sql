-- ============================================
-- GET PHASE STATISTICS STORED PROCEDURE
-- ============================================
-- File: getphasestatisticssp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_phase_statistics(INTEGER) CASCADE;

-- ============================================
-- GET PHASE STATISTICS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_phase_statistics(
    p_id INTEGER
)
RETURNS TABLE(
    phase_id INTEGER,
    phase_name VARCHAR,
    phase_society_id INTEGER,
    total_blocks BIGINT,
    total_units BIGINT,
    total_residents BIGINT
) AS $$
DECLARE
    v_phase_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Check if phase exists
    SELECT EXISTS(
        SELECT 1 FROM phases WHERE id = p_id
    ) INTO v_phase_exists;
    
    IF NOT v_phase_exists THEN
        RAISE EXCEPTION 'Phase not found';
    END IF;
    
    -- Get statistics
    SELECT
        p.id,
        p.name,
        p.society_id,
        (SELECT COUNT(*) FROM blocks WHERE phase_id = p.id AND is_active = true) as total_blocks,
        (SELECT COUNT(*) FROM units u
         JOIN blocks b ON u.block_id = b.id
         WHERE b.phase_id = p.id AND u.is_active = true) as total_units,
        (SELECT COUNT(*) FROM residents r
         JOIN units u ON r.unit_id = u.id
         JOIN blocks b ON u.block_id = b.id
         WHERE b.phase_id = p.id AND r.is_active = true) as total_residents
    INTO v_result
    FROM phases p
    WHERE p.id = p_id;
    
    -- Return the statistics
    phase_id := v_result.id;
    phase_name := v_result.name;
    phase_society_id := v_result.society_id;
    total_blocks := v_result.total_blocks;
    total_units := v_result.total_units;
    total_residents := v_result.total_residents;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_phase_statistics(1);

-- ============================================
-- END OF FILE
-- ============================================