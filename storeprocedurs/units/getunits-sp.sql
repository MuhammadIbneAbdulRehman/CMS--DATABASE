-- ============================================
-- GET UNITS STORED PROCEDURE
-- ============================================
-- File: getunitssp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_units(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, VARCHAR, VARCHAR, VARCHAR, BOOLEAN) CASCADE;

-- ============================================
-- GET UNITS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_units(
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 10,
    p_society_id INTEGER DEFAULT NULL,
    p_phase_id INTEGER DEFAULT NULL,
    p_block_id INTEGER DEFAULT NULL,
    p_search VARCHAR DEFAULT NULL,
    p_unit_type VARCHAR DEFAULT NULL,
    p_usage_type VARCHAR DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
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
    society_name VARCHAR,
    phase_name VARCHAR,
    block_name VARCHAR,
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
        v_conditions := v_conditions || ' AND u.society_id = ' || p_society_id;
    END IF;
    
    IF p_phase_id IS NOT NULL THEN
        v_conditions := v_conditions || ' AND u.phase_id = ' || p_phase_id;
    END IF;
    
    IF p_block_id IS NOT NULL THEN
        v_conditions := v_conditions || ' AND u.block_id = ' || p_block_id;
    END IF;
    
    IF p_search IS NOT NULL AND p_search != '' THEN
        v_conditions := v_conditions || ' AND (u.unit_number ILIKE ''%' || p_search || '%'' OR u.unit_type ILIKE ''%' || p_search || '%'')';
    END IF;
    
    IF p_unit_type IS NOT NULL AND p_unit_type != '' THEN
        v_conditions := v_conditions || ' AND u.unit_type = ''' || p_unit_type || '''';
    END IF;
    
    IF p_usage_type IS NOT NULL AND p_usage_type != '' THEN
        v_conditions := v_conditions || ' AND u.usage_type = ''' || p_usage_type || '''';
    END IF;
    
    IF p_is_active IS NOT NULL THEN
        v_conditions := v_conditions || ' AND u.is_active = ' || CASE WHEN p_is_active THEN 'true' ELSE 'false' END;
    END IF;
    
    -- Remove first ' AND ' if exists
    IF v_conditions != '' THEN
        v_conditions := 'WHERE ' || SUBSTRING(v_conditions, 6);
    END IF;
    
    -- Get total count
    v_count_query := 'SELECT COUNT(*) as total FROM units u ' || v_conditions;
    EXECUTE v_count_query INTO v_count;
    
    -- Get units with society, phase, block names
    v_query := '
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
            s.name AS society_name,
            p.name AS phase_name,
            b.name AS block_name,
            ' || v_count || ' AS total_count
        FROM units u
        JOIN societies s ON u.society_id = s.id
        LEFT JOIN phases p ON u.phase_id = p.id
        JOIN blocks b ON u.block_id = b.id
        ' || v_conditions || '
        ORDER BY b.name ASC, u.unit_number ASC
        LIMIT ' || p_limit || ' OFFSET ' || v_offset;
    
    RETURN QUERY EXECUTE v_query;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_units(1, 10, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
-- SELECT * FROM get_units(1, 10, 1, NULL, NULL, NULL, NULL, NULL, NULL);
-- SELECT * FROM get_units(1, 10, NULL, 1, NULL, NULL, NULL, NULL, NULL);
-- SELECT * FROM get_units(1, 10, NULL, NULL, 1, NULL, NULL, NULL, NULL);
-- SELECT * FROM get_units(1, 10, NULL, NULL, NULL, '101', NULL, NULL, NULL);
-- SELECT * FROM get_units(1, 10, NULL, NULL, NULL, NULL, 'Flat', NULL, NULL);
-- SELECT * FROM get_units(1, 10, NULL, NULL, NULL, NULL, NULL, 'Residential', NULL);
-- SELECT * FROM get_units(1, 10, NULL, NULL, NULL, NULL, NULL, NULL, true);

-- ============================================
-- END OF FILE
-- ============================================