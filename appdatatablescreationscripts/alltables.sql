-- ============================================
-- COMPLETE DATABASE SCHEMA - FIXED ORDER
-- ============================================
-- Drop everything first
DROP TABLE IF EXISTS complaint_images CASCADE;
DROP TABLE IF EXISTS complaint_attachments CASCADE;
DROP TABLE IF EXISTS complaint_status_history CASCADE;
DROP TABLE IF EXISTS complaints CASCADE;
DROP TABLE IF EXISTS workers CASCADE;
DROP TABLE IF EXISTS department_sub_categories CASCADE;
DROP TABLE IF EXISTS managers CASCADE;
DROP TABLE IF EXISTS gm_department_assignments CASCADE;
DROP TABLE IF EXISTS department_categories CASCADE;
DROP TABLE IF EXISTS gm_staff CASCADE;
DROP TABLE IF EXISTS administrators CASCADE;
DROP TABLE IF EXISTS residents CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS blocks CASCADE;
DROP TABLE IF EXISTS phases CASCADE;
DROP TABLE IF EXISTS societies CASCADE;
DROP TYPE IF EXISTS complaint_priority CASCADE;
DROP TYPE IF EXISTS complaint_status CASCADE;
-- Create ENUM types
CREATE TYPE complaint_priority AS ENUM ('Low', 'Medium', 'High', 'Urgent');
CREATE TYPE complaint_status AS ENUM ('Open', 'In-Progress', 'Resolved', 'Closed');
-- ============================================
-- 1. SOCIETIES (Parent table)
-- ============================================
CREATE TABLE societies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    pincode VARCHAR(20),
    admin_name VARCHAR(100) NOT NULL,
    admin_email VARCHAR(100) UNIQUE NOT NULL,
    admin_password VARCHAR(255) NOT NULL,
    admin_phone VARCHAR(15),
    admin_profile_pic VARCHAR(255),
    admin_last_login TIMESTAMP,
    total_units INT DEFAULT 0,
    total_residents INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT societies_name_city_unique UNIQUE (name, city)
);
-- ============================================
-- 2. PHASES
-- ============================================
CREATE TABLE phases (
    id SERIAL PRIMARY KEY,
    society_id INT NOT NULL REFERENCES societies(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    sequence_number INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT phases_society_name_unique UNIQUE (society_id, name)
);
-- ============================================
-- 3. BLOCKS
-- ============================================
CREATE TABLE blocks (
    id SERIAL PRIMARY KEY,
    society_id INT NOT NULL REFERENCES societies(id) ON DELETE CASCADE,
    phase_id INT REFERENCES phases(id) ON DELETE
    SET NULL,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        total_units INT DEFAULT 0,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT blocks_society_name_unique UNIQUE (society_id, name)
);
-- ============================================
-- 4. UNITS
-- ============================================
CREATE TABLE units (
    id SERIAL PRIMARY KEY,
    society_id INT NOT NULL REFERENCES societies(id) ON DELETE CASCADE,
    phase_id INT REFERENCES phases(id) ON DELETE
    SET NULL,
        block_id INT NOT NULL REFERENCES blocks(id) ON DELETE CASCADE,
        unit_number VARCHAR(50) NOT NULL,
        unit_type VARCHAR(50) DEFAULT 'Flat',
        usage_type VARCHAR(50) DEFAULT 'Residential',
        floor_number INT,
        size_sqft DECIMAL(10, 2),
        room_count INT DEFAULT 0,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT units_unique_within_block UNIQUE (block_id, unit_number)
);
-- ============================================
-- 5. RESIDENTS
-- ============================================
CREATE TABLE residents (
    id SERIAL PRIMARY KEY,
    unit_id INT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    full_name VARCHAR(200) NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    alternate_phone VARCHAR(20),
    resident_type VARCHAR(50) DEFAULT 'Owner',
    password_hash VARCHAR(255),
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    email_verification_expiry TIMESTAMP,
    email_verified_at TIMESTAMP,
    address VARCHAR(255) NOT NULL,
    pin_code VARCHAR(10) NOT NULL,
    location VARCHAR(255),
    last_login TIMESTAMP,
    preferred_language VARCHAR(10) DEFAULT 'en',
    reset_token VARCHAR(255),
    reset_token_expiry TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 6. ADMINISTRATORS
-- ============================================
CREATE TABLE administrators (
    id SERIAL PRIMARY KEY,
    society_id INTEGER NOT NULL REFERENCES societies(id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    password_hash TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 7. GM STAFF
-- ============================================
CREATE TABLE gm_staff (
    id SERIAL PRIMARY KEY,
    society_id INT NOT NULL REFERENCES societies(id) ON DELETE CASCADE,
    full_name VARCHAR(200) NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by INT REFERENCES societies(id) ON DELETE
    SET NULL,
        last_login TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 8. DEPARTMENT CATEGORIES (No manager_id yet)
-- ============================================
CREATE TABLE department_categories (
    id SERIAL PRIMARY KEY,
    society_id INT REFERENCES societies(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    assign_to INT REFERENCES gm_staff(id) ON DELETE
    SET NULL,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 9. GM DEPARTMENT ASSIGNMENTS
-- ============================================
CREATE TABLE gm_department_assignments (
    id SERIAL PRIMARY KEY,
    gm_staff_id INT NOT NULL REFERENCES gm_staff(id) ON DELETE CASCADE,
    department_category_id INT NOT NULL REFERENCES department_categories(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by INT REFERENCES societies(id) ON DELETE
    SET NULL,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(gm_staff_id, department_category_id)
);
-- ============================================
-- 10. MANAGERS
-- ============================================
CREATE TABLE managers (
    id SERIAL PRIMARY KEY,
    society_id INT NOT NULL REFERENCES societies(id) ON DELETE CASCADE,
    gm_id INT REFERENCES gm_staff(id) ON DELETE
    SET NULL,
        full_name VARCHAR(200) NOT NULL,
        email VARCHAR(200) UNIQUE NOT NULL,
        phone VARCHAR(20) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        department_category_id INT REFERENCES department_categories(id) ON DELETE
    SET NULL,
        is_active BOOLEAN DEFAULT TRUE,
        created_by INT REFERENCES gm_staff(id) ON DELETE
    SET NULL,
        last_login TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 11. ADD manager_id to department_categories (After managers table exists)
-- ============================================
ALTER TABLE department_categories
ADD COLUMN IF NOT EXISTS manager_id INT REFERENCES managers(id) ON DELETE
SET NULL;
-- ============================================
-- 12. DEPARTMENT SUB-CATEGORIES
-- ============================================
CREATE TABLE department_sub_categories (
    id SERIAL PRIMARY KEY,
    category_id INT NOT NULL REFERENCES department_categories(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    sla_hours INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 13. WORKERS
-- ============================================
CREATE TABLE workers (
    id SERIAL PRIMARY KEY,
    society_id INT NOT NULL REFERENCES societies(id) ON DELETE CASCADE,
    manager_id INT NOT NULL REFERENCES managers(id) ON DELETE CASCADE,
    full_name VARCHAR(200) NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    department_category_id INT REFERENCES department_categories(id) ON DELETE
    SET NULL,
        department_sub_category_id INT REFERENCES department_sub_categories(id) ON DELETE
    SET NULL,
        is_active BOOLEAN DEFAULT TRUE,
        created_by INT REFERENCES managers(id) ON DELETE
    SET NULL,
        last_login TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 14. COMPLAINTS
-- ============================================
CREATE TABLE complaints (
    id SERIAL PRIMARY KEY,
    resident_id INT NOT NULL REFERENCES residents(id) ON DELETE CASCADE,
    unit_id INT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category_id INT REFERENCES department_categories(id) ON DELETE
    SET NULL,
        sub_category_id INT REFERENCES department_sub_categories(id) ON DELETE
    SET NULL,
        priority complaint_priority DEFAULT 'Medium',
        status complaint_status DEFAULT 'Open',
        assigned_to INT REFERENCES workers(id) ON DELETE
    SET NULL,
        assigned_to_manager INT REFERENCES managers(id) ON DELETE
    SET NULL,
        assigned_by INT REFERENCES societies(id) ON DELETE
    SET NULL,
        assigned_at TIMESTAMP,
        sla_hours_at_assignment INT,
        is_overdue BOOLEAN DEFAULT FALSE,
        overdue_hours INT DEFAULT 0,
        sla_breached_at TIMESTAMP,
        escalation_level INT DEFAULT 0,
        resolved_at TIMESTAMP,
        resolution_notes TEXT,
        feedback_rating INT CHECK (
            feedback_rating BETWEEN 1 AND 5
        ),
        feedback_comment TEXT,
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        location_address TEXT,
        current_address TEXT,
        use_current_address BOOLEAN DEFAULT FALSE,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 15. COMPLAINT STATUS HISTORY
-- ============================================
CREATE TABLE complaint_status_history (
    id SERIAL PRIMARY KEY,
    complaint_id INT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    changed_by INT,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 16. COMPLAINT ATTACHMENTS
-- ============================================
CREATE TABLE complaint_attachments (
    id SERIAL PRIMARY KEY,
    complaint_id INT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT,
    mime_type VARCHAR(100),
    is_media BOOLEAN DEFAULT TRUE,
    uploaded_by INT REFERENCES residents(id) ON DELETE
    SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 17. COMPLAINT IMAGES
-- ============================================
CREATE TABLE complaint_images (
    id SERIAL PRIMARY KEY,
    complaint_id INT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    image_data TEXT NOT NULL,
    mime_type VARCHAR(50) NOT NULL,
    file_name VARCHAR(255),
    file_size INT,
    is_primary BOOLEAN DEFAULT FALSE,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================
-- 18. COMPLAINTS TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION update_complaints_updated_at() RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER update_complaints_updated_at BEFORE
UPDATE ON complaints FOR EACH ROW EXECUTE FUNCTION update_complaints_updated_at();
-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
-- Societies indexes
CREATE INDEX idx_societies_admin_email ON societies(admin_email);
CREATE INDEX idx_societies_is_active ON societies(is_active);
-- Administrators indexes
CREATE INDEX idx_administrators_society_id ON administrators(society_id);
CREATE INDEX idx_administrators_email ON administrators(email);
CREATE INDEX idx_administrators_is_active ON administrators(is_active);
-- Blocks indexes
CREATE INDEX idx_blocks_society_id ON blocks(society_id);
CREATE INDEX idx_blocks_phase_id ON blocks(phase_id);
-- Units indexes
CREATE INDEX idx_units_society_id ON units(society_id);
CREATE INDEX idx_units_block_id ON units(block_id);
CREATE INDEX idx_units_phase_id ON units(phase_id);
-- Residents indexes
CREATE INDEX idx_residents_email ON residents(email);
CREATE INDEX idx_residents_phone ON residents(phone);
CREATE INDEX idx_residents_unit_id ON residents(unit_id);
CREATE INDEX idx_residents_verification_token ON residents(email_verification_token);
CREATE INDEX idx_residents_is_active ON residents(is_active);
CREATE INDEX idx_residents_is_email_verified ON residents(is_email_verified);
-- GM Staff indexes
CREATE INDEX idx_gm_staff_society_id ON gm_staff(society_id);
CREATE INDEX idx_gm_staff_email ON gm_staff(email);
-- GM Department Assignments indexes
CREATE INDEX idx_gm_dept_assign_gm_id ON gm_department_assignments(gm_staff_id);
CREATE INDEX idx_gm_dept_assign_dept_id ON gm_department_assignments(department_category_id);
-- Department Categories indexes
CREATE INDEX idx_dept_categories_society_id ON department_categories(society_id);
-- Department Sub-Categories indexes
CREATE INDEX idx_dept_sub_cat_category_id ON department_sub_categories(category_id);
CREATE INDEX idx_dept_sub_cat_is_active ON department_sub_categories(is_active);
CREATE INDEX idx_dept_sub_cat_sla ON department_sub_categories(sla_hours);
-- Managers indexes
CREATE INDEX idx_managers_society_id ON managers(society_id);
CREATE INDEX idx_managers_gm_id ON managers(gm_id);
CREATE INDEX idx_managers_email ON managers(email);
-- Workers indexes
CREATE INDEX idx_workers_society_id ON workers(society_id);
CREATE INDEX idx_workers_manager_id ON workers(manager_id);
CREATE INDEX idx_workers_email ON workers(email);
CREATE INDEX idx_workers_phone ON workers(phone);
-- Complaints indexes
CREATE INDEX idx_complaints_resident_id ON complaints(resident_id);
CREATE INDEX idx_complaints_unit_id ON complaints(unit_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_priority ON complaints(priority);
CREATE INDEX idx_complaints_sub_category_id ON complaints(sub_category_id);
CREATE INDEX idx_complaints_assigned_at ON complaints(assigned_at);
CREATE INDEX idx_complaints_is_overdue ON complaints(is_overdue);
CREATE INDEX idx_complaints_overdue_hours ON complaints(overdue_hours);
CREATE INDEX idx_complaints_sla_breached_at ON complaints(sla_breached_at);
CREATE INDEX idx_complaints_escalation_level ON complaints(escalation_level);
CREATE INDEX idx_complaints_latitude ON complaints(latitude);
CREATE INDEX idx_complaints_longitude ON complaints(longitude);
-- Complaint Status History indexes
CREATE INDEX idx_complaint_status_history_complaint_id ON complaint_status_history(complaint_id);
CREATE INDEX idx_complaint_status_history_created_at ON complaint_status_history(created_at);
-- Complaint Images indexes
CREATE INDEX idx_complaint_images_complaint_id ON complaint_images(complaint_id);
CREATE INDEX idx_complaint_images_is_primary ON complaint_images(is_primary);
-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================
COMMENT ON TABLE complaints IS 'Stores all complaint data with SLA tracking and location';
COMMENT ON COLUMN complaints.latitude IS 'Latitude from pin location';
COMMENT ON COLUMN complaints.longitude IS 'Longitude from pin location';
COMMENT ON COLUMN complaints.location_address IS 'Full address of the complaint location';
COMMENT ON COLUMN complaints.is_overdue IS 'Flag indicating if complaint has exceeded SLA';
COMMENT ON COLUMN complaints.escalation_level IS 'Escalation level (1-3) based on overdue time';
COMMENT ON TABLE department_sub_categories IS 'Department sub-categories with SLA';
COMMENT ON COLUMN department_sub_categories.sla_hours IS 'Service Level Agreement - hours within which complaint should be resolved (NULL = not set)';