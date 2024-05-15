-- 原価差額ワークテーブル（エラー）項目追加
ALTER TABLE xxcoi.xxcoi_wk_error_cost_variance ADD(
  company_code           VARCHAR2(3)
 ,group_company_flg      VARCHAR2(1)
 ,transfer_ownership_flg VARCHAR2(1)
);
--
COMMENT ON COLUMN xxcoi.xxcoi_wk_error_cost_variance.company_code IS '会社コード';
COMMENT ON COLUMN xxcoi.xxcoi_wk_error_cost_variance.group_company_flg IS 'グループ会社フラグ';
COMMENT ON COLUMN xxcoi.xxcoi_wk_error_cost_variance.transfer_ownership_flg IS '所有権移転取引フラグ';
