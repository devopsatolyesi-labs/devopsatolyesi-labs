-- Portal authorization and dynamic course-package model.
-- Keycloak owns credentials and authentication; this database owns course access.

CREATE TABLE portal_user (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    keycloak_subject VARCHAR(64) NOT NULL UNIQUE,
    username VARCHAR(128) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    global_role VARCHAR(20) NOT NULL CHECK (global_role IN ('admin', 'instructor', 'student')),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lab_definition (
    id VARCHAR(32) PRIMARY KEY,
    title VARCHAR(250) NOT NULL,
    topic VARCHAR(80) NOT NULL,
    difficulty SMALLINT NOT NULL CHECK (difficulty IN (100, 200, 300, 400)),
    estimated_minutes INTEGER NOT NULL CHECK (estimated_minutes > 0),
    catalog_revision VARCHAR(64) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    synced_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE course_package (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug VARCHAR(100) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    created_by BIGINT NOT NULL REFERENCES portal_user(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE course_lab (
    course_id BIGINT NOT NULL REFERENCES course_package(id) ON DELETE CASCADE,
    lab_id VARCHAR(32) NOT NULL REFERENCES lab_definition(id),
    position INTEGER NOT NULL CHECK (position > 0),
    required BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (course_id, lab_id),
    UNIQUE (course_id, position)
);

CREATE TABLE course_enrollment (
    course_id BIGINT NOT NULL REFERENCES course_package(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES portal_user(id) ON DELETE CASCADE,
    enrollment_role VARCHAR(20) NOT NULL DEFAULT 'student' CHECK (enrollment_role IN ('instructor', 'student')),
    enrolled_by BIGINT NOT NULL REFERENCES portal_user(id),
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (course_id, user_id)
);

CREATE TABLE package_build (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id BIGINT NOT NULL REFERENCES course_package(id) ON DELETE CASCADE,
    audience VARCHAR(20) NOT NULL CHECK (audience IN ('instructor', 'student')),
    catalog_revision VARCHAR(64) NOT NULL,
    artifact_name VARCHAR(255) NOT NULL,
    sha256 CHAR(64),
    created_by BIGINT NOT NULL REFERENCES portal_user(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX course_enrollment_user_idx ON course_enrollment(user_id);
CREATE INDEX course_lab_lab_idx ON course_lab(lab_id);
