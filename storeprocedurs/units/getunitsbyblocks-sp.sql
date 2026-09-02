-- ============================================
-- GET UNITS BY BLOCK STORED PROCEDURE
-- ============================================
-- File: getunitsbyblocksp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_units_by_block(INTEGER) CASCADE;

-- ============================================
-- GET UNITS BY BLOCK FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_units_by_block(
    p_block_id INTEGER
)
RETURNS TABLE(
    unit_id INTEGER,
    unit_society_id INTEGER,
    unit_phase_id INTEGER,
    unit_block_id INTEGER,
    unit_unit_number VARCHAR,
    unit_unit_type VARCHAR,
    unit_usage_type VARCHAR,
    unit_floor_number INTEGER,
    unit_size_sqft DECIMAL,
    unit_room_count INTEGER,
    unit_is_active BOOLEAN,
    unit_created_at TIMESTAMP,
    unit_updated_at TIMESTAMP,
    phase_name VARCHAR,
    block_id INTEGER,
    block_name VARCHAR
) AS $$
DECLARE
    v_block_exists BOOLEAN;
    v_block_record RECORD;
BEGIN
    -- Check if block exists and is active
    SELECT EXISTS(
        SELECT 1 FROM blocks 
        WHERE id = p_block_id AND is_active = true
    ) INTO v_block_exists;
    
    IF NOT v_block_exists THEN
        RAISE EXCEPTION 'Block not found or inactive';
    END IF;
    
    -- Get block details
    SELECT 
        id,
        name
    INTO v_block_record
    FROM blocks
    WHERE id = p_block_id;
    
    -- Return units with block and phase details
    RETURN QUERY
    SELECT 
        u.id AS unit_id,
        u.society_id AS unit_society_id,
        u.phase_id AS unit_phase_id,
        u.block_id AS unit_block_id,
        u.unit_number AS unit_unit_number,
        u.unit_type AS unit_unit_type,
        u.usage_type AS unit_usage_type,
        u.floor_number AS unit_floor_number,
        u.size_sqft AS unit_size_sqft,
        u.room_count AS unit_room_count,
        u.is_active AS unit_is_active,
        u.created_at AS unit_created_at,
        u.updated_at AS unit_updated_at,
        p.name AS phase_name,
        v_block_record.id AS block_id,
        v_block_record.name AS block_name
    FROM units u
    LEFT JOIN phases p ON u.phase_id = p.id
    WHERE u.block_id = p_block_id 
        AND u.is_active = true
    ORDER BY u.unit_number ASC;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_units_by_block(1);

-- ============================================
-- END OF FILE
-- ============================================