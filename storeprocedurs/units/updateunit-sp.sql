-- ============================================
-- UPDATE UNIT STORED PROCEDURE
-- ============================================
-- File: updateunitsp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS update_unit(INTEGER, VARCHAR, VARCHAR, VARCHAR, INTEGER, DECIMAL, INTEGER, INTEGER, BOOLEAN) CASCADE;

-- ============================================
-- UPDATE UNIT FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_unit(
    p_id INTEGER,
    p_unit_number VARCHAR,
    p_unit_type VARCHAR,
    p_usage_type VARCHAR,
    p_floor_number INTEGER,
    p_size_sqft DECIMAL,
    p_room_count INTEGER,
    p_phase_id INTEGER,
    p_is_active BOOLEAN
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
    unit_updated_at TIMESTAMP
) AS $$
DECLARE
    v_old_data RECORD;
    v_duplicate_exists BOOLEAN;
    v_phase_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Get old data and check existence
    SELECT * INTO v_old_data FROM units WHERE id = p_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unit not found';
    END IF;
    
    -- Check unit_number uniqueness if changing
    IF p_unit_number IS NOT NULL AND p_unit_number != v_old_data.unit_number THEN
        SELECT EXISTS(
            SELECT 1 FROM units 
            WHERE block_id = v_old_data.block_id 
                AND unit_number = p_unit_number 
                AND id != p_id
        ) INTO v_duplicate_exists;
        
        IF v_duplicate_exists THEN
            RAISE EXCEPTION 'Unit with this number already exists in this block';
        END IF;
    END IF;
    
    -- Check phase exists if changing
    IF p_phase_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM phases 
            WHERE id = p_phase_id AND society_id = v_old_data.society_id AND is_active = true
        ) INTO v_phase_exists;
        
        IF NOT v_phase_exists THEN
            RAISE EXCEPTION 'Phase not found or inactive in this society';
        END IF;
    END IF;
    
    -- Update using COALESCE - only update provided values
    UPDATE units 
    SET 
        unit_number = COALESCE(p_unit_number, unit_number),
        unit_type = COALESCE(p_unit_type, unit_type),
        usage_type = COALESCE(p_usage_type, usage_type),
        floor_number = COALESCE(p_floor_number, floor_number),
        size_sqft = COALESCE(p_size_sqft, size_sqft),
        room_count = COALESCE(p_room_count, room_count),
        phase_id = COALESCE(p_phase_id, phase_id),
        is_active = COALESCE(p_is_active, is_active),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_id
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
        created_at,
        updated_at
    INTO v_result;
    
    -- Return the updated unit
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
    unit_updated_at := v_result.updated_at;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM update_unit(1, '101A', 'Flat', 'Residential', 1, 1200, 3, 1, true);

-- ============================================
-- END OF FILE
-- ============================================