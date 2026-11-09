INSERT INTO roles(name) VALUES ('owner') ON CONFLICT(name) DO NOTHING;
INSERT INTO roles(name) VALUES ('catalog_manager') ON CONFLICT(name) DO NOTHING;
INSERT INTO roles(name) VALUES ('catalog_viewer') ON CONFLICT(name) DO NOTHING;
INSERT INTO role_permissions(role_id,permission_code)
SELECT r.id,p.permission_code
FROM roles r
CROSS JOIN (VALUES ('catalog.read'),('catalog.write')) AS p(permission_code)
WHERE r.name IN ('owner','catalog_manager')
ON CONFLICT(role_id,permission_code) DO NOTHING;
INSERT INTO role_permissions(role_id,permission_code)
SELECT r.id,'catalog.read'
FROM roles r
WHERE r.name='catalog_viewer'
ON CONFLICT(role_id,permission_code) DO NOTHING;
