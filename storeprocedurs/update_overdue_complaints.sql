-- ============================================
-- POSTGRESQL FUNCTION: update_overdue_complaints
-- ============================================
CREATE OR REPLACE FUNCTION update_overdue_complaints() RETURNS TABLE(
        complaint_id INT,
        subject VARCHAR,
        current_deadline TIMESTAMP,
        overdue_hours INT,
        escalation_level INT,
        manager_email VARCHAR,
        manager_name VARCHAR
    ) AS $$ BEGIN RETURN QUERY
UPDATE complaints c
SET is_overdue = TRUE,
    overdue_hours = EXTRACT(
        EPOCH
        FROM (NOW() - c.current_deadline)
    ) / 3600,
    escalation_level = CASE
        WHEN EXTRACT(
            EPOCH
            FROM (NOW() - c.current_deadline)
        ) / 3600 > 72 THEN 3
        WHEN EXTRACT(
            EPOCH
            FROM (NOW() - c.current_deadline)
        ) / 3600 > 48 THEN 2
        WHEN EXTRACT(
            EPOCH
            FROM (NOW() - c.current_deadline)
        ) / 3600 > 24 THEN 1
        ELSE 0
    END,
    sla_breached_at = CASE
        WHEN c.is_overdue = FALSE THEN NOW()
        ELSE c.sla_breached_at
    END,
    updated_at = NOW()
FROM managers m
WHERE c.status IN ('Open', 'In-Progress', 'Assigned')
    AND c.current_deadline < NOW()
    AND c.is_overdue = FALSE
    AND c.assigned_to_manager = m.id
RETURNING c.id,
    c.subject,
    c.current_deadline,
    c.overdue_hours,
    c.escalation_level,
    m.email,
    m.full_name;
END;
$$ LANGUAGE plpgsql;
-- ✅ Test the function
SELECT *
FROM update_overdue_complaints();