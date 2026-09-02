-- ============================================
-- CREATE BLOCK STORED PROCEDURE (FIXED)
-- ============================================
-- File: createblocksp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS create_block(INTEGER, INTEGER, VARCHAR, TEXT) CASCADE;

-- ============================================
-- CREATE BLOCK FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION create_block(
    p_society_id INTEGER,
    p_phase_id INTEGER,
    p_name VARCHAR,
    p_description TEXT
)
RETURNS TABLE(
    block_id INTEGER,
    block_society_id INTEGER,
    block_phase_id INTEGER,
    block_name VARCHAR,
    block_description TEXT,
    block_total_units INTEGER,
    block_is_active BOOLEAN,
    block_created_at TIMESTAMP
) AS $$
DECLARE
    v_society_exists BOOLEAN;
    v_phase_exists BOOLEAN;
    v_block_exists BOOLEAN;
    v_block_id INTEGER;
BEGIN
    -- Check if society exists and is active
    SELECT EXISTS(
        SELECT 1 FROM societies 
        WHERE id = p_society_id AND is_active = true
    ) INTO v_society_exists;
    
    IF NOT v_society_exists THEN
        RAISE EXCEPTION 'Society not found or inactive';
    END IF;
    
    -- Check if phase exists (if provided)
    IF p_phase_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM phases 
            WHERE id = p_phase_id AND is_active = true
        ) INTO v_phase_exists;
        
        IF NOT v_phase_exists THEN
            RAISE EXCEPTION 'Phase not found or inactive';
        END IF;
    END IF;
    
    -- Check if block already exists in this society
    SELECT EXISTS(
        SELECT 1 FROM blocks 
        WHERE society_id = p_society_id AND name = p_name
    ) INTO v_block_exists;
    
    IF v_block_exists THEN
        RAISE EXCEPTION 'Block with this name already exists in this society';
    END IF;
    
    -- Insert the block
    INSERT INTO blocks (
        society_id,
        phase_id,
        name,
        description,
        total_units,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_society_id,
        p_phase_id,
        p_name,
        p_description,
        0,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO v_block_id;
    
    -- Update society total_units count
    UPDATE societies 
    SET total_units = total_units + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_society_id;
    
    -- Return the inserted block with prefixed column names
    RETURN QUERY
    SELECT 
        b.id AS block_id,
        b.society_id AS block_society_id,
        b.phase_id AS block_phase_id,
        b.name AS block_name,
        b.description AS block_description,
        b.total_units AS block_total_units,
        b.is_active AS block_is_active,
        b.created_at AS block_created_at
    FROM blocks b
    WHERE b.id = v_block_id;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM create_block(1, NULL, 'Block A', 'First block in society');

-- ============================================
-- END OF FILE
-- ============================================