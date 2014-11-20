ALTER TABLE xxcso.xxcso_wk_sales_target ADD CONSTRAINT xxcso_wk_sales_target_pk PRIMARY KEY (
    target_management_code,  --目標管理項目コード
    employee_code,           --営業員コード
    target_month,            --目標年月
    base_code                --拠点コード
  )
/
