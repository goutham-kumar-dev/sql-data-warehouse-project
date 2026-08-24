/*
==================================================================
Stored procedure: Load Bronze layer (Source -> Bronze)
==================================================================

Script purpose:
  This stored procedure loads data into bronze schema from external csv files.
  It performs following actions:
  Truncate the bronze tables before loading data
  use the 'COPY' command to load data from csv files to bronze tables

parameters:
  None
  stored procedures doesn't accept any parameters or return any value.

usage Example 
  for postgres: call bronze.load_bronze();
==================================================================
*/

-- PROCEDURE: bronze.load_bronze()

-- DROP PROCEDURE IF EXISTS bronze.load_bronze();

CREATE OR REPLACE PROCEDURE bronze.load_bronze(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_context TEXT;
    v_line_num TEXT;
	batch_start_time timestamp;
	batch_end_time timestamp;
	v_runtime_seconds INT;
begin

	-- Full Load at bronze layer (Truncate & Insert)
	batch_start_time := clock_timestamp();
	raise notice '===============================';
	raise notice 'Loading Bronze layer ';
	raise notice '===============================';

	raise notice 'Loading CRM Tables';

	
	Truncate table bronze.crm_cust_info;
	
	-- bulk insert 
	copy bronze.crm_cust_info
	from 'C:\Users\Public\datawarehouse\source_crm\cust_info.csv'
	with (
		FORMAT CSV,
	    HEADER true,
	    DELIMITER ','
	);
	
	
	-- select count(*) from bronze.crm_cust_info;
	------------------------------------------------------------------------------
	Truncate table bronze.crm_prd_info;
	
	-- bulk insert 
	copy bronze.crm_prd_info
	from 'C:\Users\Public\datawarehouse\source_crm\prd_info.csv'
	with (
		FORMAT CSV,
	    HEADER true,
	    DELIMITER ','
	);
	
	-------------------------------------------------------------------------------
	Truncate table bronze.crm_sales_details;
	
	-- bulk insert 
	copy bronze.crm_sales_details
	from 'C:\Users\Public\datawarehouse\source_crm\sales_details.csv'
	with (
		FORMAT CSV,
	    HEADER true,
	    DELIMITER ','
	);

	raise notice '===============================';
	raise notice 'Loading ERP Tables';
	-------------------------------------------------------------------------------
	Truncate table bronze.erp_cust_az12;
	
	-- bulk insert 
	copy bronze.erp_cust_az12
	from 'C:\Users\Public\datawarehouse\source_erp\cust_az12.csv'
	with (
		FORMAT CSV,
	    HEADER true,
	    DELIMITER ','
	);
	
	-------------------------------------------------------------------------------
	Truncate table bronze.erp_loc_a101;
	
	-- bulk insert 
	copy bronze.erp_loc_a101
	from 'C:\Users\Public\datawarehouse\source_erp\loc_a101.csv'
	with (
		FORMAT CSV,
	    HEADER true,
	    DELIMITER ','
	);
	
	-- select * from bronze.erp_loc_a101;
	
	-------------------------------------------------------------------------------
	Truncate table bronze.erp_px_cat_g1v2;
	
	-- bulk insert 
	copy bronze.erp_px_cat_g1v2
	from 'C:\Users\Public\datawarehouse\source_erp\px_cat_g1v2.csv'
	with (
		FORMAT CSV,
	    HEADER true,
	    DELIMITER ','
	);

	batch_end_time := clock_timestamp();
	v_runtime_seconds := extract(epoch from (batch_end_time - batch_start_time));
	raise notice 'Batch Load duration: %', v_runtime_seconds;

exception when others then
	 RAISE NOTICE 'The error message is: %', SQLERRM;
	 RAISE NOTICE 'The error code is: %', SQLSTATE;
	 -- 1. Get the raw stack trace text
    GET STACKED DIAGNOSTICS v_context = PG_EXCEPTION_CONTEXT;

    -- 2. Extract the line number using a Regular Expression
    v_line_num := substring(v_context from 'line ([0-40960])');

    -- 3. Print the results
    RAISE NOTICE 'Error occurred at line number: %', v_line_num;
    RAISE NOTICE 'Full context trace: %', v_context;

end;
$BODY$;
ALTER PROCEDURE bronze.load_bronze()
    OWNER TO postgres;

