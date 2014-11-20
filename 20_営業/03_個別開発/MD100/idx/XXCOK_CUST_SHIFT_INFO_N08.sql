CREATE INDEX xxcok.xxcok_cust_shift_info_n08
ON xxcok.xxcok_cust_shift_info(
     cust_shift_date
   , status
   , vd_inv_trnsfr_status
   , create_chg_je_flag
)
TABLESPACE xxidx2
/
