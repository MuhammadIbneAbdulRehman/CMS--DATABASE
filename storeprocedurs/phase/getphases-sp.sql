-- ============================================
-- GET PHASES STORED PROCEDURE
-- ============================================
-- File: getphasesp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_phases(INTEGER, INTEGER, INTEGER, VARCHAR, BOOLEAN) CASCADE;

-- ============================================
-- GET PHASES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_phases(
    p_page INTEGER DEFAULT 1,
    p_limit INTEGER DEFAULT 10,
    p_society_id INTEGER DEFAULT NULL,
    p_search VARCHAR DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE(
    phase_id INTEGER,
    phase_society_id INTEGER,
    phase_name VARCHAR,
    phase_description TEXT,
    phase_sequence_number INTEGER,
    phase_is_active BOOLEAN,
    phase_created_at TIMESTAMP,
    phase_updated_at TIMESTAMP,
    society_name VARCHAR,
    total_count BIGINT
) AS $$
DECLARE
    v_offset INTEGER;
    v_conditions TEXT;
    v_params TEXT[];
    v_query TEXT;
    v_count_query TEXT;
    v_count BIGINT;
BEGIN
    -- Calculate offset
    v_offset := (p_page - 1) * p_limit;
    
    -- Build conditions
    v_conditions := '';
    
    IF p_society_id IS NOT NULL THEN
        v_conditions := v_conditions || ' AND p.society_id = ' || p_society_id;
    END IF;
    
    IF p_search IS NOT NULL AND p_search != '' THEN
        v_conditions := v_conditions || ' AND (p.name ILIKE ''%' || p_search || '%'' OR p.description ILIKE ''%' || p_search || '%'')';
    END IF;
    
    IF p_is_active IS NOT NULL THEN
        v_conditions := v_conditions || ' AND p.is_active = ' || CASE WHEN p_is_active THEN 'true' ELSE 'false' END;
    END IF;
    
    -- Remove first ' AND ' if exists
    IF v_conditions != '' THEN
        v_conditions := 'WHERE ' || SUBSTRING(v_conditions, 6);
    END IF;
    
    -- Get total count
    v_count_query := 'SELECT COUNT(*) as total FROM phases p ' || v_conditions;
    EXECUTE v_count_query INTO v_count;
    
    -- Get phases with society name
    v_query := '
        SELECT 
            p.id AS phase_id,
            p.society_id AS phase_society_id,
            p.name AS phase_name,
            p.description AS phase_description,
            p.sequence_number AS phase_sequence_number,
            p.is_active AS phase_is_active,
            p.created_at AS phase_created_at,
            p.updated_at AS phase_updated_at,
            s.name AS society_name,
            ' || v_count || ' AS total_count
        FROM phases p
        JOIN societies s ON p.society_id = s.id
        ' || v_conditions || '
        ORDER BY p.sequence_number NULLS LAST, p.created_at ASC
        LIMIT ' || p_limit || ' OFFSET ' || v_offset;
    
    RETURN QUERY EXECUTE v_query;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT * FROM get_phases(1, 10, NULL, NULL, NULL);
-- SELECT * FROM get_phases(1, 10, 1, NULL, NULL);
-- SELECT * FROM get_phases(1, 10, NULL, 'Phase', NULL);
-- SELECT * FROM get_phases(1, 10, NULL, NULL, true);

-- ============================================
-- END OF FILE
-- ============================================