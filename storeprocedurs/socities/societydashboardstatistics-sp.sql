-- ============================================================================
-- 1. PROCEDURE: Update Overdue Complaints (Schema Matched)
-- ============================================================================
DROP FUNCTION IF EXISTS sp_update_overdue_complaints();

CREATE OR REPLACE FUNCTION sp_update_overdue_complaints()
RETURNS TABLE (
    id INT,
    subject VARCHAR(255),
    overdue_hours INT,
    escalation_level INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    UPDATE complaints c
    SET 
        is_overdue = TRUE,
        overdue_hours = CEIL(EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 - dsc.sla_hours)::INT,
        sla_breached_at = COALESCE(c.sla_breached_at, NOW()),
        escalation_level = CASE 
            WHEN EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 >= dsc.sla_hours * 3 THEN 3
            WHEN EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 >= dsc.sla_hours * 2 THEN 2
            ELSE 1
        END,
        updated_at = NOW()
    FROM department_sub_categories dsc
    WHERE c.sub_category_id = dsc.id
      AND c.status IN ('Open'::complaint_status, 'In-Progress'::complaint_status)
      AND c.is_overdue = FALSE
      AND dsc.sla_hours IS NOT NULL
      AND EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 > dsc.sla_hours
    RETURNING c.id, c.subject, c.overdue_hours, c.escalation_level;
END;
$$;


-- ============================================================================
-- 2. PROCEDURE: Fetch Society Statistics (Schema Matched)
-- ============================================================================
DROP FUNCTION IF EXISTS sp_get_society_statistics(INT);

CREATE OR REPLACE FUNCTION sp_get_society_statistics(
    p_society_id INT
)
RETURNS TABLE (
    total_phases BIGINT,
    total_blocks BIGINT,
    total_units BIGINT,
    total_residents BIGINT,
    open_complaints BIGINT,
    resolved_complaints BIGINT,
    in_progress_complaints BIGINT,
    total_complaints BIGINT,
    total_overdue_complaints BIGINT,
    overdue_open_complaints BIGINT,
    overdue_in_progress_complaints BIGINT,
    critical_overdue_complaints BIGINT,
    escalation_level_1 BIGINT,
    escalation_level_2 BIGINT,
    escalation_level_3 BIGINT,
    avg_overdue_hours NUMERIC,
    max_overdue_hours NUMERIC,
    overdue_by_sub_category JSONB,
    recent_overdue_complaints JSONB,
    approaching_sla_breach BIGINT,
    complaints_without_sla BIGINT,
    urgent_open_complaints BIGINT,
    high_priority_open_complaints BIGINT,
    avg_resolution_hours NUMERIC,
    sla_breach_count BIGINT,
    sla_compliance_rate NUMERIC,
    avg_response_hours NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM phases WHERE society_id = p_society_id AND is_active = true),
        (SELECT COUNT(*) FROM blocks WHERE society_id = p_society_id AND is_active = true),
        (SELECT COUNT(*) FROM units WHERE society_id = p_society_id AND is_active = true),
        (SELECT COUNT(*) FROM residents r JOIN units u ON r.unit_id = u.id WHERE u.society_id = p_society_id AND r.is_active = true),
        
        -- COMPLAINT COUNTS WITH ENUM CASTING
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.status = 'Open'::complaint_status),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.status = 'Resolved'::complaint_status),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.status = 'In-Progress'::complaint_status),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id),
        
        -- OVERDUE STATS
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_overdue = true),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_overdue = true AND c.status = 'Open'::complaint_status),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_overdue = true AND c.status = 'In-Progress'::complaint_status),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id WHERE u.society_id = p_society_id AND c.is_overdue = true AND dsc.sla_hours IS NOT NULL AND EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 >= (dsc.sla_hours * 2)),
        
        -- ESCALATION LEVELS
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_overdue = true AND c.escalation_level = 1),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_overdue = true AND c.escalation_level = 2),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_overdue = true AND c.escalation_level = 3),
        
        (SELECT COALESCE(AVG(c.overdue_hours), 0)::NUMERIC FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_overdue = true),
        (SELECT COALESCE(MAX(c.overdue_hours), 0)::NUMERIC FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_overdue = true),
        
        -- SUB-CATEGORY BREAKDOWN (AGGREGATED TO JSONB)
        (SELECT COALESCE(jsonb_agg(sub_cat_stats), '[]'::jsonb)
         FROM (
             SELECT 
                 dsc.id as sub_category_id,
                 dsc.name as sub_category_name,
                 dc.id as category_id,
                 dc.name as category_name,
                 dsc.sla_hours as sla_hours,
                 COUNT(c.id) as overdue_count,
                 COALESCE(AVG(EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 - dsc.sla_hours), 0)::NUMERIC as avg_overdue_hours,
                 COALESCE(MAX(EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 - dsc.sla_hours), 0)::NUMERIC as max_overdue_hours,
                 COALESCE(MIN(EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 - dsc.sla_hours), 0)::NUMERIC as min_overdue_hours,
                 COUNT(c.id) FILTER (WHERE c.escalation_level = 3) as critical_count
             FROM complaints c
             JOIN units u ON c.unit_id = u.id
             JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id
             JOIN department_categories dc ON dsc.category_id = dc.id
             WHERE u.society_id = p_society_id 
               AND c.is_overdue = true
               AND dsc.sla_hours IS NOT NULL
             GROUP BY dsc.id, dsc.name, dc.id, dc.name, dsc.sla_hours
             ORDER BY overdue_count DESC, avg_overdue_hours DESC
         ) sub_cat_stats),

        -- RECENT OVERDUE COMPLAINTS
        (SELECT COALESCE(jsonb_agg(recent_overdue), '[]'::jsonb)
         FROM (
             SELECT 
                 c.id, c.subject, c.created_at, c.status, c.priority,
                 c.overdue_hours, c.escalation_level,
                 dsc.name as sub_category_name, dc.name as category_name
             FROM complaints c
             JOIN units u ON c.unit_id = u.id
             JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id
             JOIN department_categories dc ON dsc.category_id = dc.id
             WHERE u.society_id = p_society_id 
               AND c.is_overdue = true
             ORDER BY c.overdue_hours DESC
             LIMIT 5
         ) recent_overdue),

        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id WHERE u.society_id = p_society_id AND c.status IN ('Open'::complaint_status, 'In-Progress'::complaint_status) AND c.is_overdue = false AND dsc.sla_hours IS NOT NULL AND EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 > (dsc.sla_hours * 0.8)),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id WHERE u.society_id = p_society_id AND c.status IN ('Open'::complaint_status, 'In-Progress'::complaint_status) AND dsc.sla_hours IS NULL),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.priority = 'Urgent'::complaint_priority AND c.status != 'Resolved'::complaint_status),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.priority = 'High'::complaint_priority AND c.status != 'Resolved'::complaint_status),
        (SELECT COALESCE(AVG(EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600), 0)::NUMERIC FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.status = 'Resolved'::complaint_status AND c.resolved_at IS NOT NULL),
        (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id WHERE u.society_id = p_society_id AND c.status = 'Resolved'::complaint_status AND c.resolved_at IS NOT NULL AND dsc.sla_hours IS NOT NULL AND EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600 > dsc.sla_hours),
        (SELECT CASE WHEN COUNT(*) = 0 THEN 100 ELSE ROUND((COUNT(*) FILTER (WHERE dsc.sla_hours IS NOT NULL AND EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600 <= dsc.sla_hours)::numeric / COUNT(*)::numeric) * 100, 2) END FROM complaints c JOIN units u ON c.unit_id = u.id JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id WHERE u.society_id = p_society_id AND c.status = 'Resolved'::complaint_status),
        (SELECT COALESCE(AVG(EXTRACT(EPOCH FROM (c.assigned_at - c.created_at)) / 3600), 0)::NUMERIC FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.assigned_at IS NOT NULL)
    FROM societies
    WHERE id = p_society_id;
END;
$$;