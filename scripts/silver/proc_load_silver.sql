/*

Stote procedure : Load Silver layer (Bronze->Silver)

Script purpose : this stored procedure performs the ETL (Extract transform load ) process to populate the silver schema 
from the bronze schema

actions performed:
-truncate silver tables
-inserts transformaed and cleansed data from bronze into silver tables 

parameters : None
this strored procedure doesnt accept any parametetrs or return any values 

usage example:
call silver.load_silver()

postgres...!
*/


create or replace procedure silver.load_silver()
language plpgsql
as $$
DECLARE
    v_context TEXT;
    v_line_num TEXT;
	batch_start_time timestamp;
	batch_end_time timestamp;
	v_runtime_seconds INT;
begin

	batch_start_time := clock_timestamp();
	raise notice '===============================';
	raise notice 'Loading Silver layer ';
	raise notice '===============================';
	
	
	raise notice 'Truncating Table : Silver.crm_cust_info';
	truncate table silver.crm_cust_info;
	raise notice 'Inserting Data into : Silver.crm_cust_info';
	
	insert into silver.crm_cust_info(cst_id,cst_key,cst_firstname,cst_lastname,
	cst_marital_status,cst_gndr,cst_create_date)
	
	select cst_id,cst_key,
	trim(cst_firstname) as cst_firstname,
	trim(cst_lastname) as cst_lastname,
	case when upper(trim(cst_gndr))='S' then 'Single'
		 when upper(trim(cst_gndr))='M' then 'Married'
		 else 'n/a'
	end as cst_marital_status,
	case when upper(trim(cst_gndr))='M' then 'Male'
		 when upper(trim(cst_gndr))='F' then 'Female'
		 else 'n/a'
	end as cst_gndr,
	cst_create_date
	from 
	( 
	select *,
	row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
	from bronze.crm_cust_info
	where cst_id is not null) t
	where flag_last=1;
	
	
	
	raise notice 'Truncating Table : Silver.crm_prd_info';
	truncate table silver.crm_prd_info;
	raise notice 'Inserting Data into : Silver.crm_prd_info';
	
	insert into silver.crm_prd_info(prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
	
	select prd_id,
	replace(substring(prd_key,1,5),'-','_') as cat_id,  --extract category id -- add/modify dervied columns in silver table 
	substring(prd_key,7,length(prd_key)) as prd_key,  -- extract product key
	prd_nm,
	coalesce(prd_cost,0) as prd_cost,
	case upper(trim(prd_line))
		when 'M' then 'Mountain'
		when 'R' then 'Road'
		when 'S' then 'Other Sales'
		when 'T' then 'Touring'
		else 'n/a'
	end as prd_line,
	prd_start_dt,
	lead(prd_start_dt,1) over(partition by prd_key order by prd_start_dt)-1 as prd_end_dt
	from bronze.crm_prd_info;
	
	raise notice 'Truncating Table : Silver.crm_sales_details';
	truncate table silver.crm_sales_details;
	raise notice 'Inserting Data into : Silver.crm_sales_details';
	
	Insert into silver.crm_sales_details(sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,
	sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price)
	
	select 
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	case 
		when sls_order_dt=0 or length(cast(sls_order_dt as varchar)) != 8 then null
		else cast(cast(sls_order_dt as varchar) as date)
	end as sls_order_dt,
	case 
		when sls_ship_dt=0 or length(cast(sls_ship_dt as varchar)) != 8 then null
		else cast(cast(sls_ship_dt as varchar) as date)
	end as sls_ship_dt,
	case 
		when sls_due_dt=0 or length(cast(sls_due_dt as varchar)) != 8 then null
		else cast(cast(sls_due_dt as varchar) as date)
	end as sls_due_dt,
	case 
		when sls_sales is null or sls_sales<=0 or sls_sales !=sls_quantity*abs(sls_price)
		then sls_quantity * abs(sls_price)
		else sls_sales
	end as sls_sales,
	sls_quantity,
	case 
		when sls_price is null or sls_price <=0
		then sls_sales / nullif(sls_quantity,0)
		else sls_price
	end as sls_price
	from bronze.crm_sales_details;  -- Compare all data type with silver table and do change if required. as we have changed dates from into to date 
	
	
	
	
	
	raise notice 'Truncating Table : Silver.erp_cust_az12';
	truncate table silver.erp_cust_az12;
	raise notice 'Inserting Data into : Silver.erp_cust_az12';
	
	Insert into silver.erp_cust_az12(cid,bdate,gen)
	select 
	case 
		when cid like 'NAS%' then substring(cid,4,length(cid))
		else cid
	end as cid,
	case 
		when bdate>current_date then null 
		else bdate
	end as bdate,
	case 
		when upper(trim(gen)) in ('M','MALE') then 'Male'
		when upper(trim(gen)) in ('F','FEMALE') then 'Female'
		else 'n/a'
	end as gen
	from bronze.erp_cust_az12;
	
	
	raise notice 'Truncating Table : Silver.erp_loc_a101';
	truncate table silver.erp_loc_a101;
	raise notice 'Inserting Data into : Silver.erp_loc_a101';
	
	Insert into silver.erp_loc_a101(cid,cntry)
	
	select 
	replace(cid,'-','') as cid,
	case 
		when trim(cntry)='DE' then 'Germany'
		when trim(cntry) in ('US','USA') then 'United States'
		when trim(cntry)='' or cntry is null then 'n/a'
		else trim(cntry)
	end as cntry
	from bronze.erp_loc_a101;
	
	
	
	raise notice 'Truncating Table : Silver.erp_px_cat_g1v2';
	truncate table silver.erp_px_cat_g1v2;
	raise notice 'Inserting Data into : Silver.erp_px_cat_g1v2';
	
	insert into silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
	select id,
	cat,
	subcat,
	maintenance
	from bronze.erp_px_cat_g1v2;


	batch_end_time := clock_timestamp();
	v_runtime_seconds := extract(epoch from (batch_end_time - batch_start_time));
	raise notice 'Batch Load duration: %', v_runtime_seconds;

Exception when others then
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
$$;






