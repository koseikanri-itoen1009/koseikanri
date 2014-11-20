ALTER TABLE xxcso.xxcso_sales_target_mst ADD CONSTRAINT xxcso_sales_target_mst_pk PRIMARY KEY (
    target_management_code,  --目標管理項目コード
    employee_code,           --営業員コード
    target_month,            --目標年月
    base_code                --拠点コード
  )
/
