-- Existing versions ko clean karne ke liye
DROP FUNCTION IF EXISTS sp_get_society_profile(INTEGER);
DROP FUNCTION IF EXISTS sp_get_society_profile(BIGINT);

-- Corrected Stored Function
CREATE OR REPLACE FUNCTION sp_get_society_profile(
    p_society_id INT
)
RETURNS TABLE (
    id INT,
    name VARCHAR(200),
    description TEXT,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(20),
    admin_name VARCHAR(100),
    admin_email VARCHAR(100),
    admin_phone VARCHAR(15),
    admin_profile_pic VARCHAR(255),
    admin_last_login TIMESTAMP,
    total_units INT,
    total_residents INT,
    is_active BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id, s.name, s.description, s.address, s.city, s.state, s.pincode,
        s.admin_name, s.admin_email, s.admin_phone, s.admin_profile_pic,
        s.admin_last_login, s.total_units, s.total_residents,
        s.is_active, s.created_at, s.updated_at
    FROM societies s
    WHERE s.id = p_society_id;
END;
$$;