BEGIN;

--DELETE FROM manage_functions where code like 'PasswordComplexityLevels_passwordcomplexitylevel%';
DELETE FROM manage_functions where code like 'PasswordComplexityLevels_passwordcomplexitylevel%';

INSERT INTO manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) VALUES
('PasswordComplexityLevels_passwordcomplexitylevelAdd', 'users', TRUE, TRUE, '1300', 'Add Password Complexity Level', 'schema', 'schema');
INSERT INTO manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) VALUES
('PasswordComplexityLevels_passwordcomplexitylevelProperties', 'users', TRUE, FALSE, '1301', 'Edit Password Complexity Level', 'schema', 'schema');
INSERT INTO manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) VALUES
('PasswordComplexityLevels_passwordcomplexitylevelDrop', 'users', TRUE, FALSE, '1302', 'Drop Password Complexity Level', 'schema', 'schema');
INSERT INTO manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) VALUES
('PasswordComplexityLevels_passwordcomplexitylevelList', 'users', FALSE, TRUE, '1303', 'List Password Complexity Levels', 'schema', 'schema');
INSERT INTO manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) VALUES
('PasswordComplexityLevels_passwordcomplexitylevelDetailView', 'users', FALSE, FALSE, '1304', 'Password Complexity Level Detail View', 'schema', 'schema');

--DELETE FROM manage_group_manage_function_map where manage_function_code like 'PasswordComplexityLevels_passwordcomplexitylevel%';
DELETE FROM manage_group_manage_function_map where manage_function_code like 'PasswordComplexityLevels_passwordcomplexitylevel%';

INSERT INTO manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) VALUES
('PasswordComplexityLevels_passwordcomplexitylevelAdd', 'site_developers', 'schema', 'schema');
INSERT INTO manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) VALUES
('PasswordComplexityLevels_passwordcomplexitylevelProperties', 'site_developers', 'schema', 'schema');
INSERT INTO manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) VALUES
('PasswordComplexityLevels_passwordcomplexitylevelDrop', 'site_developers', 'schema', 'schema');
INSERT INTO manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) VALUES
('PasswordComplexityLevels_passwordcomplexitylevelList', 'site_developers', 'schema', 'schema');
INSERT INTO manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) VALUES
('PasswordComplexityLevels_passwordcomplexitylevelDetailView', 'site_developers', 'schema', 'schema');

--DELETE FROM manage_functions where code like 'PasswordComplexityValidations_passwordcomplexityvalidation%';
DELETE FROM manage_functions where code like 'PasswordComplexityValidations_passwordcomplexityvalidation%';

INSERT INTO manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) VALUES
('PasswordComplexityValidations_passwordcomplexityvalidationAdd', 'users', TRUE, TRUE, '1400', 'Add Password Complexity Validation', 'schema', 'schema');
INSERT INTO manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) VALUES
('PasswordComplexityValidations_passwordcomplexityvalidationProperties', 'users', TRUE, FALSE, '1401', 'Edit Password Complexity Validation', 'schema', 'schema');
INSERT INTO manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) VALUES
('PasswordComplexityValidations_passwordcomplexityvalidationDrop', 'users', TRUE, FALSE, '1402', 'Drop Password Complexity Validation', 'schema', 'schema');
INSERT INTO manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) VALUES
('PasswordComplexityValidations_passwordcomplexityvalidationList', 'users', FALSE, TRUE, '1403', 'List Password Complexity Validations', 'schema', 'schema');
INSERT INTO manage_functions (code, section_code, developer_only, in_menu, sort_order, display_label, created_by, modified_by) VALUES
('PasswordComplexityValidations_passwordcomplexityvalidationDetailView', 'users', FALSE, FALSE, '1404', 'Password Complexity Validation Detail View', 'schema', 'schema');

--DELETE FROM manage_group_manage_function_map where manage_function_code like 'PasswordComplexityValidations_passwordcomplexityvalidation%';
DELETE FROM manage_group_manage_function_map where manage_function_code like 'PasswordComplexityValidations_passwordcomplexityvalidation%';

INSERT INTO manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) VALUES
('PasswordComplexityValidations_passwordcomplexityvalidationAdd', 'site_developers', 'schema', 'schema');
INSERT INTO manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) VALUES
('PasswordComplexityValidations_passwordcomplexityvalidationProperties', 'site_developers', 'schema', 'schema');
INSERT INTO manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) VALUES
('PasswordComplexityValidations_passwordcomplexityvalidationDrop', 'site_developers', 'schema', 'schema');
INSERT INTO manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) VALUES
('PasswordComplexityValidations_passwordcomplexityvalidationList', 'site_developers', 'schema', 'schema');
INSERT INTO manage_group_manage_function_map (manage_function_code, manage_group_code, created_by, modified_by) VALUES
('PasswordComplexityValidations_passwordcomplexityvalidationDetailView', 'site_developers', 'schema', 'schema');

COMMIT;
