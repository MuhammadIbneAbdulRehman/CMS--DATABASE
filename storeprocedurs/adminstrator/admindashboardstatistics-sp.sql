-- ============================================
-- GET ADMIN DASHBOARD STATISTICS STORED PROCEDURE
-- ============================================
-- File: getadmindashboardstatssp.sql
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTION
-- ============================================

DROP FUNCTION IF EXISTS get_admin_dashboard_stats(INTEGER) CASCADE;

-- ============================================
-- GET ADMIN DASHBOARD STATISTICS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_admin_dashboard_stats(
    p_society_id INTEGER
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    WITH stats AS (
        SELECT 
            s.id as society_id,
            s.name as society_name,
            
            -- Basic Statistics
            (SELECT COUNT(*) FROM phases WHERE society_id = p_society_id AND is_active = true) as total_phases,
            (SELECT COUNT(*) FROM blocks WHERE society_id = p_society_id AND is_active = true) as total_blocks,
            (SELECT COUNT(*) FROM units WHERE society_id = p_society_id AND is_active = true) as total_units,
            (SELECT COUNT(*) FROM residents r JOIN units u ON r.unit_id = u.id WHERE u.society_id = p_society_id AND r.is_active = true) as total_residents,
            
            -- Complaint Statistics
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.status = 'Open' AND c.is_active = true) as open_complaints,
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.status = 'Resolved' AND c.is_active = true) as resolved_complaints,
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.status = 'In-Progress' AND c.is_active = true) as in_progress_complaints,
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true) as total_complaints,
            
            -- Overdue Statistics
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.is_overdue = true) as total_overdue_complaints,
            (SELECT COALESCE(AVG(c.overdue_hours), 0) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.is_overdue = true) as avg_overdue_hours,
            (SELECT COALESCE(MAX(c.overdue_hours), 0) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.is_overdue = true) as max_overdue_hours,
            
            -- Critical Overdue
            (SELECT COUNT(*) 
             FROM complaints c 
             JOIN units u ON c.unit_id = u.id 
             JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id 
             WHERE u.society_id = p_society_id 
             AND c.is_active = true 
             AND c.is_overdue = true 
             AND c.status NOT IN ('Resolved', 'Closed') 
             AND dsc.sla_hours IS NOT NULL 
             AND EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 >= (dsc.sla_hours * 2)) as critical_overdue_complaints,
            
            -- Escalated
            (SELECT COUNT(*) 
             FROM complaints c 
             JOIN units u ON c.unit_id = u.id 
             WHERE u.society_id = p_society_id 
             AND c.is_active = true 
             AND c.escalation_level > 0 
             AND c.is_overdue = true 
             AND c.status NOT IN ('Resolved', 'Closed')) as total_escalated,
            
            -- Overdue by Status
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.is_overdue = true AND c.status = 'Open') as overdue_open,
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.is_overdue = true AND c.status = 'In-Progress') as overdue_in_progress,
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.is_overdue = true AND c.status = 'Resolved') as overdue_resolved,
            
            -- Overdue by Escalation
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.is_overdue = true AND c.escalation_level = 1 AND c.status NOT IN ('Resolved', 'Closed')) as overdue_level_1,
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.is_overdue = true AND c.escalation_level = 2 AND c.status NOT IN ('Resolved', 'Closed')) as overdue_level_2,
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.is_overdue = true AND c.escalation_level = 3 AND c.status NOT IN ('Resolved', 'Closed')) as overdue_level_3,
            
            -- Approaching Breach
            (SELECT COUNT(*) 
             FROM complaints c 
             JOIN units u ON c.unit_id = u.id 
             JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id 
             WHERE u.society_id = p_society_id 
             AND c.is_active = true 
             AND c.is_overdue = false 
             AND c.status NOT IN ('Resolved', 'Closed') 
             AND dsc.sla_hours IS NOT NULL 
             AND EXTRACT(EPOCH FROM (NOW() - c.created_at)) / 3600 >= (dsc.sla_hours * 0.75)) as approaching_breach,
            
            -- Without SLA
            (SELECT COUNT(*) 
             FROM complaints c 
             JOIN units u ON c.unit_id = u.id 
             LEFT JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id 
             WHERE u.society_id = p_society_id 
             AND c.is_active = true 
             AND c.status NOT IN ('Resolved', 'Closed') 
             AND (dsc.sla_hours IS NULL OR dsc.sla_hours = 0)) as without_sla,
            
            -- SLA Metrics
            (SELECT COUNT(*) 
             FROM complaints c 
             JOIN units u ON c.unit_id = u.id 
             JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id 
             WHERE u.society_id = p_society_id 
             AND c.is_active = true 
             AND dsc.sla_hours IS NOT NULL 
             AND c.status = 'Resolved' 
             AND EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600 > dsc.sla_hours) as sla_breach_count,
            
            (SELECT CASE 
                WHEN COUNT(*) = 0 THEN 100 
                ELSE ROUND((COUNT(*) FILTER (WHERE dsc.sla_hours IS NOT NULL AND EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600 <= dsc.sla_hours)::numeric / COUNT(*)::numeric) * 100, 2) 
             END
             FROM complaints c 
             JOIN units u ON c.unit_id = u.id 
             JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id 
             WHERE u.society_id = p_society_id 
             AND c.is_active = true 
             AND c.status = 'Resolved') as sla_compliance_rate,
            
            (SELECT COALESCE(AVG(EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 3600), 0) 
             FROM complaints c 
             JOIN units u ON c.unit_id = u.id 
             WHERE u.society_id = p_society_id 
             AND c.is_active = true 
             AND c.status = 'Resolved' 
             AND c.resolved_at IS NOT NULL) as avg_resolution_hours,
            
            (SELECT COALESCE(AVG(EXTRACT(EPOCH FROM (c.assigned_at - c.created_at)) / 3600), 0) 
             FROM complaints c 
             JOIN units u ON c.unit_id = u.id 
             WHERE u.society_id = p_society_id 
             AND c.is_active = true 
             AND c.status IN ('In-Progress', 'Resolved') 
             AND c.assigned_at IS NOT NULL) as avg_response_hours,
            
            -- Priority Statistics
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.priority = 'Urgent' AND c.status = 'Open') as urgent_open,
            (SELECT COUNT(*) FROM complaints c JOIN units u ON c.unit_id = u.id WHERE u.society_id = p_society_id AND c.is_active = true AND c.priority = 'High' AND c.status = 'Open') as high_priority_open,
            
            -- Recent Overdue Complaints
            (SELECT COALESCE(JSON_AGG(
                JSON_BUILD_OBJECT(
                    'id', c.id,
                    'subject', c.subject,
                    'description', c.description,
                    'status', c.status,
                    'priority', c.priority,
                    'overdue_hours', c.overdue_hours,
                    'escalation_level', c.escalation_level,
                    'created_at', c.created_at,
                    'unit_number', u.unit_number,
                    'block_name', b.name,
                    'phase_name', p.name,
                    'sub_category_name', dsc.name
                ) ORDER BY c.overdue_hours DESC
            ), '[]'::json)
            FROM complaints c 
            JOIN units u ON c.unit_id = u.id 
            JOIN blocks b ON u.block_id = b.id 
            JOIN phases p ON b.phase_id = p.id 
            LEFT JOIN department_sub_categories dsc ON c.sub_category_id = dsc.id 
            WHERE u.society_id = p_society_id 
            AND c.is_active = true 
            AND c.is_overdue = true 
            LIMIT 5) as recent_overdue
            
        FROM societies s
        WHERE s.id = p_society_id AND s.is_active = true
    )
    SELECT json_build_object(
        'society', json_build_object(
            'id', society_id,
            'name', society_name
        ),
        'total_phases', total_phases,
        'total_blocks', total_blocks,
        'total_units', total_units,
        'total_residents', total_residents,
        'open_complaints', open_complaints,
        'resolved_complaints', resolved_complaints,
        'in_progress_complaints', in_progress_complaints,
        'total_complaints', total_complaints,
        'overdue', json_build_object(
            'summary', json_build_object(
                'total', total_overdue_complaints,
                'avg_overdue_hours', avg_overdue_hours,
                'max_overdue_hours', max_overdue_hours,
                'critical', critical_overdue_complaints,
                'total_escalated', total_escalated
            ),
            'by_status', json_build_object(
                'open', overdue_open,
                'in_progress', overdue_in_progress,
                'resolved', overdue_resolved
            ),
            'by_escalation', json_build_object(
                'level_1', overdue_level_1,
                'level_2', overdue_level_2,
                'level_3', overdue_level_3
            ),
            'recent', recent_overdue,
            'approaching_breach', approaching_breach,
            'without_sla', without_sla
        ),
        'sla', json_build_object(
            'avg_resolution_hours', avg_resolution_hours,
            'sla_breach_count', sla_breach_count,
            'sla_compliance_rate', sla_compliance_rate,
            'avg_response_hours', avg_response_hours,
            'urgent_open', urgent_open,
            'high_priority_open', high_priority_open
        )
    ) INTO v_result
    FROM stats;
    
    -- If society not found, return empty stats
    IF v_result IS NULL THEN
        v_result := json_build_object(
            'society', json_build_object('id', p_society_id, 'name', 'Society not found'),
            'total_phases', 0,
            'total_blocks', 0,
            'total_units', 0,
            'total_residents', 0,
            'open_complaints', 0,
            'resolved_complaints', 0,
            'in_progress_complaints', 0,
            'total_complaints', 0,
            'overdue', json_build_object(
                'summary', json_build_object(
                    'total', 0,
                    'avg_overdue_hours', 0,
                    'max_overdue_hours', 0,
                    'critical', 0,
                    'total_escalated', 0
                ),
                'by_status', json_build_object('open', 0, 'in_progress', 0, 'resolved', 0),
                'by_escalation', json_build_object('level_1', 0, 'level_2', 0, 'level_3', 0),
                'recent', '[]'::json,
                'approaching_breach', 0,
                'without_sla', 0
            ),
            'sla', json_build_object(
                'avg_resolution_hours', 0,
                'sla_breach_count', 0,
                'sla_compliance_rate', 0,
                'avg_response_hours', 0,
                'urgent_open', 0,
                'high_priority_open', 0
            )
        );
    END IF;
    
    RETURN v_result;
    
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TEST QUERY
-- ============================================

-- SELECT get_admin_dashboard_stats(1);

-- ============================================
-- END OF FILE
-- ============================================