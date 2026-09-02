-- ============================================
-- GET UNIT STATISTICS STORED PROCEDURE
-- ============================================
-- File: getunitstatisticssp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_unit_statistics(INTEGER) CASCADE;

-- ============================================
-- GET UNIT STATISTICS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_unit_statistics(
    p_id INTEGER
)
RETURNS TABLE(
    unit_id INTEGER,
    unit_unit_number VARCHAR,
    unit_block_id INTEGER,
    unit_society_id INTEGER,
    total_residents BIGINT,
    open_complaints BIGINT,
    resolved_complaints BIGINT,
    in_progress_complaints BIGINT
) AS $$
DECLARE
    v_unit_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Check if unit exists
    SELECT EXISTS(
        SELECT 1 FROM units WHERE id = p_id
    ) INTO v_unit_exists;
    
    IF NOT v_unit_exists THEN
        RAISE EXCEPTION 'Unit not found';
    END IF;
    
    -- Get statistics
    SELECT
        u.id,
        u.unit_number,
        u.block_id,
        u.society_id,
        (SELECT COUNT(*) FROM residents WHERE unit_id = u.id AND is_active = true) as total_residents,
        (SELECT COUNT(*) FROM complaints WHERE unit_id = u.id AND status = 'Open') as open_complaints,
        (SELECT COUNT(*) FROM complaints WHERE unit_id = u.id AND status = 'Resolved') as resolved_complaints,
        (SELECT COUNT(*) FROM complaints WHERE unit_id = u.id AND status = 'In-Progress') as in_progress_complaints
    INTO v_result
    FROM units u
    WHERE u.id = p_id;
    
    -- Return the statistics
    unit_id := v_result.id;
    unit_unit_number := v_result.unit_number;
    unit_block_id := v_result.block_id;
    unit_society_id := v_result.society_id;
    total_residents := v_result.total_residents;
    open_complaints := v_result.open_complaints;
    resolved_complaints := v_result.resolved_complaints;
    in_progress_complaints := v_result.in_progress_complaints;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_unit_statistics(1);

-- ============================================
-- END OF FILE
-- ============================================