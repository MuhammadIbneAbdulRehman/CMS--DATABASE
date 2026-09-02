-- ============================================
-- GET BLOCKS STORED PROCEDURE
-- ============================================
-- File: getblockssp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_blocks(INTEGER, INTEGER, INTEGER, VARCHAR, BOOLEAN) CASCADE;

-- ============================================
-- GET BLOCKS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_blocks(
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 10,
    p_society_id INTEGER DEFAULT NULL,
    p_phase_id INTEGER DEFAULT NULL,
    p_search VARCHAR DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
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
    society_name VARCHAR,
    phase_name VARCHAR,
    total_count BIGINT
) AS $$
DECLARE
    v_offset INTEGER;
    v_conditions TEXT;
    v_query TEXT;
    v_count_query TEXT;
    v_count BIGINT;
BEGIN
    -- Calculate offset
    v_offset := (p_page - 1) * p_limit;
    
    -- Build conditions
    v_conditions := '';
    
    IF p_society_id IS NOT NULL THEN
        v_conditions := v_conditions || ' AND b.society_id = ' || p_society_id;
    END IF;
    
    IF p_phase_id IS NOT NULL THEN
        v_conditions := v_conditions || ' AND b.phase_id = ' || p_phase_id;
    END IF;
    
    IF p_search IS NOT NULL AND p_search != '' THEN
        v_conditions := v_conditions || ' AND (b.name ILIKE ''%' || p_search || '%'' OR b.description ILIKE ''%' || p_search || '%'')';
    END IF;
    
    IF p_is_active IS NOT NULL THEN
        v_conditions := v_conditions || ' AND b.is_active = ' || CASE WHEN p_is_active THEN 'true' ELSE 'false' END;
    END IF;
    
    -- Remove first ' AND ' if exists
    IF v_conditions != '' THEN
        v_conditions := 'WHERE ' || SUBSTRING(v_conditions, 6);
    END IF;
    
    -- Get total count
    v_count_query := 'SELECT COUNT(*) as total FROM blocks b ' || v_conditions;
    EXECUTE v_count_query INTO v_count;
    
    -- Get blocks with society and phase names
    v_query := '
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
            s.name AS society_name,
            p.name AS phase_name,
            ' || v_count || ' AS total_count
        FROM blocks b
        JOIN societies s ON b.society_id = s.id
        LEFT JOIN phases p ON b.phase_id = p.id
        ' || v_conditions || '
        ORDER BY b.created_at DESC
        LIMIT ' || p_limit || ' OFFSET ' || v_offset;
    
    RETURN QUERY EXECUTE v_query;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_blocks(1, 10, NULL, NULL, NULL, NULL);
-- SELECT * FROM get_blocks(1, 10, 1, NULL, NULL, NULL);
-- SELECT * FROM get_blocks(1, 10, NULL, 1, NULL, NULL);
-- SELECT * FROM get_blocks(1, 10, NULL, NULL, 'Block', NULL);
-- SELECT * FROM get_blocks(1, 10, NULL, NULL, NULL, true);

-- ============================================
-- END OF FILE
-- ============================================