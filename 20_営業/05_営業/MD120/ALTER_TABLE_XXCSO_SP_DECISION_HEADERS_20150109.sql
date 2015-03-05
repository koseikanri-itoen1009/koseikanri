ALTER TABLE xxcso.xxcso_sp_decision_headers ADD(
   contract_year_month           NUMBER(2,0)     -- 契約月数
  ,contract_start_year           NUMBER(4,0)     -- 契約期間開始（年）
  ,contract_start_month          NUMBER(2,0)     -- 契約期間開始（月）
  ,contract_end_year             NUMBER(4,0)     -- 契約期間終了（年）
  ,contract_end_month            NUMBER(2,0)     -- 契約期間終了（月）
  ,bidding_item                  VARCHAR2(1)     -- 入札案件
  ,cancell_before_maturity       VARCHAR2(1)     -- 中途解約条項
  ,ad_assets_type                VARCHAR2(1)     -- 支払区分（行政財産使用料）
  ,ad_assets_amt                 NUMBER(8,0)     -- 総額（行政財産使用料）
  ,ad_assets_this_time           NUMBER(8,0)     -- 今回支払（行政財産使用料）
  ,ad_assets_payment_year        NUMBER(2,0)     -- 支払年数（行政財産使用料）
  ,ad_assets_payment_date        DATE            -- 支払期日（行政財産使用料）
  ,tax_type                      VARCHAR2(1)     -- 税区分
  ,install_supp_type             VARCHAR2(1)     -- 支払区分（設置協賛金）
  ,install_supp_payment_type     VARCHAR2(1)     -- 支払条件（設置協賛金）
  ,install_supp_amt              NUMBER(8,0)     -- 総額（設置協賛金）
  ,install_supp_this_time        NUMBER(8,0)     -- 今回支払（設置協賛金）
  ,install_supp_payment_year     NUMBER(2,0)     -- 支払年数（設置協賛金）
  ,install_supp_payment_date     DATE            -- 支払期日（設置協賛金）
  ,electric_payment_type         VARCHAR2(1)     -- 支払条件（電気代）
  ,electric_payment_change_type  VARCHAR2(1)     -- 支払条件（変動電気代）
  ,electric_payment_cycle        VARCHAR2(1)     -- 支払サイクル（電気代）
  ,electric_closing_date         VARCHAR2(2)     -- 締日（電気代）
  ,electric_trans_month          VARCHAR2(2)     -- 振込月（電気代）
  ,electric_trans_date           VARCHAR2(2)     -- 振込日（電気代）
  ,electric_trans_name           VARCHAR2(360)   -- 契約先以外名（電気代）
  ,electric_trans_name_alt       VARCHAR2(320)   -- 契約先以外名カナ（電気代）
  ,intro_chg_type                VARCHAR2(1)     -- 支払区分（紹介手数料）
  ,intro_chg_payment_type        VARCHAR2(1)     -- 支払条件（紹介手数料）
  ,intro_chg_amt                 NUMBER(8,0)     -- 総額（紹介手数料）
  ,intro_chg_this_time           NUMBER(8,0)     -- 今回支払（紹介手数料）
  ,intro_chg_payment_year        NUMBER(2,0)     -- 支払年数（紹介手数料）
  ,intro_chg_payment_date        DATE            -- 支払期日（紹介手数料）
  ,intro_chg_per_sales_price     NUMBER(5,2)     -- 販売金額当り紹介手数料率
  ,intro_chg_per_piece           NUMBER(8,0)     -- 1本当り紹介手数料額
  ,intro_chg_closing_date        VARCHAR2(2)     -- 締日（紹介手数料）
  ,intro_chg_trans_month         VARCHAR2(2)     -- 振込月（紹介手数料）
  ,intro_chg_trans_date          VARCHAR2(2)     -- 振込日（紹介手数料）
  ,intro_chg_trans_name          VARCHAR2(360)   -- 契約先以外名（紹介手数料）
  ,intro_chg_trans_name_alt      VARCHAR2(320)   -- 契約先以外名カナ（紹介手数料）
);
--
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.contract_year_month           IS '契約月数';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.contract_start_year           IS '契約期間開始（年）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.contract_start_month          IS '契約期間開始（月）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.contract_end_year             IS '契約期間終了（年）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.contract_end_month            IS '契約期間終了（月）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.bidding_item                  IS '入札案件';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.cancell_before_maturity       IS '中途解約条項';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.ad_assets_type                IS '支払区分（行政財産使用料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.ad_assets_amt                 IS '総額（行政財産使用料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.ad_assets_this_time           IS '今回支払（行政財産使用料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.ad_assets_payment_year        IS '支払年数（行政財産使用料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.ad_assets_payment_date        IS '支払期日（行政財産使用料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.tax_type                      IS '税区分';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_type             IS '支払区分（設置協賛金）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_payment_type     IS '支払条件（設置協賛金）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_amt              IS '総額（設置協賛金）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_this_time        IS '今回支払（設置協賛金）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_payment_year     IS '支払年数（設置協賛金）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.install_supp_payment_date     IS '支払期日（設置協賛金）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_payment_type         IS '支払条件（電気代）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_payment_change_type  IS '支払条件（変動電気代）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_payment_cycle        IS '支払サイクル（電気代）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_closing_date         IS '締日（電気代）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_trans_month          IS '振込月（電気代）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_trans_date           IS '振込日（電気代）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_trans_name           IS '契約先以外名（電気代）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.electric_trans_name_alt       IS '契約先以外名カナ（電気代）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_type                IS '支払区分（紹介手数料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_payment_type        IS '支払条件（紹介手数料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_amt                 IS '総額（紹介手数料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_this_time           IS '今回支払（紹介手数料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_payment_year        IS '支払年数（紹介手数料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_payment_date        IS '支払期日（紹介手数料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_per_sales_price     IS '販売金額当り紹介手数料率';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_per_piece           IS '1本当り紹介手数料額';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_closing_date        IS '締日（紹介手数料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_trans_month         IS '振込月（紹介手数料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_trans_date          IS '振込日（紹介手数料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_trans_name          IS '契約先以外名（紹介手数料）';
COMMENT ON COLUMN xxcso.xxcso_sp_decision_headers.intro_chg_trans_name_alt      IS '契約先以外名カナ（紹介手数料）';
