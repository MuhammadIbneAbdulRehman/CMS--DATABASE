DROP FUNCTION IF EXISTS update_admin_profile(INTEGER, VARCHAR, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION update_admin_profile(
        p_admin_id INTEGER,
        p_full_name VARCHAR,
        p_phone VARCHAR
    ) RETURNS TABLE(
        admin_id INTEGER,
        admin_full_name VARCHAR,
        admin_phone VARCHAR,
        admin_updated_at TIMESTAMP
    ) AS $$ BEGIN RETURN QUERY
UPDATE administrators
SET full_name = COALESCE(p_full_name, full_name),
    phone = COALESCE(p_phone, phone),
    updated_at = CURRENT_TIMESTAMP
WHERE id = p_admin_id
RETURNING id AS admin_id,
    full_name AS admin_full_name,
    phone AS admin_phone,
    updated_at AS admin_updated_at;
END;
$$ LANGUAGE plpgsql;