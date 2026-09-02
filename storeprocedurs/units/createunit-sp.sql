-- ============================================
-- CREATE UNIT STORED PROCEDURE
-- ============================================
-- File: createunitsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS create_unit(INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, VARCHAR, INTEGER, DECIMAL, INTEGER) CASCADE;

-- ============================================
-- CREATE UNIT FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION create_unit(
    p_society_id INTEGER,
    p_phase_id INTEGER,
    p_block_id INTEGER,
    p_unit_number VARCHAR,
    p_unit_type VARCHAR,
    p_usage_type VARCHAR,
    p_floor_number INTEGER,
    p_size_sqft DECIMAL,
    p_room_count INTEGER
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
    unit_created_at TIMESTAMP
) AS $$
DECLARE
    v_society_exists BOOLEAN;
    v_block_exists BOOLEAN;
    v_phase_exists BOOLEAN;
    v_unit_exists BOOLEAN;
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
    
    -- Check if block exists and belongs to society
    SELECT EXISTS(
        SELECT 1 FROM blocks 
        WHERE id = p_block_id AND society_id = p_society_id AND is_active = true
    ) INTO v_block_exists;
    
    IF NOT v_block_exists THEN
        RAISE EXCEPTION 'Block not found or inactive in this society';
    END IF;
    
    -- Check if phase exists (if provided) and belongs to society
    IF p_phase_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM phases 
            WHERE id = p_phase_id AND society_id = p_society_id AND is_active = true
        ) INTO v_phase_exists;
        
        IF NOT v_phase_exists THEN
            RAISE EXCEPTION 'Phase not found or inactive in this society';
        END IF;
    END IF;
    
    -- Check if unit already exists in this block
    SELECT EXISTS(
        SELECT 1 FROM units 
        WHERE block_id = p_block_id AND unit_number = p_unit_number
    ) INTO v_unit_exists;
    
    IF v_unit_exists THEN
        RAISE EXCEPTION 'Unit with this number already exists in this block';
    END IF;
    
    -- Insert the unit
    INSERT INTO units (
        society_id,
        phase_id,
        block_id,
        unit_number,
        unit_type,
        usage_type,
        floor_number,
        size_sqft,
        room_count,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_society_id,
        p_phase_id,
        p_block_id,
        p_unit_number,
        COALESCE(p_unit_type, 'Flat'),
        COALESCE(p_usage_type, 'Residential'),
        p_floor_number,
        p_size_sqft,
        COALESCE(p_room_count, 0),
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING 
        id,
        society_id,
        phase_id,
        block_id,
        unit_number,
        unit_type,
        usage_type,
        floor_number,
        size_sqft,
        room_count,
        is_active,
        created_at
    INTO v_result;
    
    -- Update block total_units count
    UPDATE blocks 
    SET total_units = total_units + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_block_id;
    
    -- Update society total_units count
    UPDATE societies 
    SET total_units = total_units + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_society_id;
    
    -- Return the inserted unit
    unit_id := v_result.id;
    unit_society_id := v_result.society_id;
    unit_phase_id := v_result.phase_id;
    unit_block_id := v_result.block_id;
    unit_unit_number := v_result.unit_number;
    unit_unit_type := v_result.unit_type;
    unit_usage_type := v_result.usage_type;
    unit_floor_number := v_result.floor_number;
    unit_size_sqft := v_result.size_sqft;
    unit_room_count := v_result.room_count;
    unit_is_active := v_result.is_active;
    unit_created_at := v_result.created_at;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM create_unit(1, NULL, 1, '101', 'Flat', 'Residential', 1, 1000, 2);

-- ============================================
-- END OF FILE
-- ============================================