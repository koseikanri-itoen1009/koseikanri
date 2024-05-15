-- 原価差額ワークテーブル項目追加
ALTER TABLE xxcoi.xxcoi_wk_cost_variance ADD(
  company_code           VARCHAR2(3)
 ,transaction_type_id    NUMBER
 ,group_company_flg      VARCHAR2(1)
 ,transfer_ownership_flg VARCHAR2(1)
 ,reverse_flg            VARCHAR2(1)
 ,grcp_adj_dept_code     VARCHAR2(4)
);
--
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.company_code IS '会社コード';
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.transaction_type_id IS '取引タイプID';
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.group_company_flg IS 'グループ会社フラグ';
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.transfer_ownership_flg IS '所有権移転取引フラグ';
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.reverse_flg IS '反転フラグ';
COMMENT ON COLUMN xxcoi.xxcoi_wk_cost_variance.grcp_adj_dept_code IS '調整部門コード(グループ会社)';
