/*
======================================================================
create database and schemas
======================================================================
script purpose:
          This script creates a new database named 'Data warehouse' after checking if it is already exists.
          IF database exists, it is dropped and recreated. Aditionally, the script sets up three schemas with in Db 
          'Bronze', 'Sliver', 'Gold'

Warning:
          Running this script will drop entire 'Data warehouse' Db if exist
          All data in DB are permanently deleted. Proceed with caution
          and ensure you have proper backups before running this scripts
*/

-- Drop and create if 'datawarehouse' db 
CREATE DATABASE IF NOT EXIST datawarehouse;


--Create Schemas
CREATE schema bronze;

CREATE schema silver;

CREATE schema gold;
