CREATE INDEX xxcok.xxcok_cust_shift_info_n07
ON xxcok.xxcok_cust_shift_info(
     status
   , base_split_flag
   , business_vd_if_flag
   , business_fa_if_flag
)
TABLESPACE xxidx2
/
