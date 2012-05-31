Replicator README

Project to produce PGSQL scripts, Rose models, testing scripts, and manage page controllers
for multiple tables for Michael C. Fina.

FILES:
/M
/Manage
/t
200-insert-table-manage-password_complexity.sql
Manage.pm
    Files and directories for working examples and framework. (background)
    
data_test.pl
database_test.pl
    Testing scripts to check functionality to be included or have been included.
    
documents_replicator_template_fk_sort.txt
documents_replicator_template.txt
groups_replicator_template.txt
    Input template files.

documents_test.txt
documents_test_fk_sort.txt
out.txt
test.txt
    Test output files (Functionality to save to separate files to be added, 
    held off due to file location in camp environment)
    
gen_new_table_and_add_to_manage.COPY_AND_USE.pl
    Previous (unshared) work from coworker, used as base in attempt to DRY, but much room for improvement.
    
read_replicator_template.pl
    Version 1 of Replicator
    
prototype_replicator.pl
ReplicatorDDL.pm
ReplicatorManage.pm
ReplicatorModel.pm
ReplicatorReader.pm
ReplicatorTest.pm
	Current working version (ReplicatorManage in development phase).
	
	
TASK LIST:
Create Manage DDL Insert scripts and Controllers.
Detect foreign key column and table from database
Trigger should not be created when no ID
One word check in terminal read mode
Relationships in terminal read mode
