-- ============================================
-- UPDATE BLOCK STORED PROCEDURE
-- ============================================
-- File: updateblocksp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS update_block(INTEGER, VARCHAR, TEXT, INTEGER, BOOLEAN) CASCADE;

-- ============================================
-- UPDATE BLOCK FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_block(
    p_id INTEGER,
    p_name VARCHAR,
    p_description TEXT,
    p_phase_id INTEGER,
    p_is_active BOOLEAN
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
    block_updated_at TIMESTAMP
) AS $$
DECLARE
    v_old_data RECORD;
    v_duplicate_exists BOOLEAN;
    v_phase_exists BOOLEAN;
    v_result RECORD;
BEGIN
    -- Get old data and check existence
    SELECT * INTO v_old_data FROM blocks WHERE id = p_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Block not found';
    END IF;
    
    -- Check name uniqueness if changing
    IF p_name IS NOT NULL AND p_name != v_old_data.name THEN
        SELECT EXISTS(
            SELECT 1 FROM blocks 
            WHERE society_id = v_old_data.society_id 
                AND name = p_name 
                AND id != p_id
        ) INTO v_duplicate_exists;
        
        IF v_duplicate_exists THEN
            RAISE EXCEPTION 'Block with this name already exists in this society';
        END IF;
    END IF;
    
    -- Check phase exists if changing
    IF p_phase_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM phases 
            WHERE id = p_phase_id AND is_active = true
        ) INTO v_phase_exists;
        
        IF NOT v_phase_exists THEN
            RAISE EXCEPTION 'Phase not found or inactive';
        END IF;
    END IF;
    
    -- Update using COALESCE - only update provided values
    UPDATE blocks 
    SET 
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        phase_id = COALESCE(p_phase_id, phase_id),
        is_active = COALESCE(p_is_active, is_active),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_id
    RETURNING 
        id,
        society_id,
        phase_id,
        name,
        description,
        total_units,
        is_active,
        created_at,
        updated_at
    INTO v_result;
    
    -- Return the updated block
    block_id := v_result.id;
    block_society_id := v_result.society_id;
    block_phase_id := v_result.phase_id;
    block_name := v_result.name;
    block_description := v_result.description;
    block_total_units := v_result.total_units;
    block_is_active := v_result.is_active;
    block_created_at := v_result.created_at;
    block_updated_at := v_result.updated_at;
    
    RETURN NEXT;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM update_block(1, 'Updated Block', 'Updated description', 1, true);

-- ============================================
-- END OF FILE
-- ============================================