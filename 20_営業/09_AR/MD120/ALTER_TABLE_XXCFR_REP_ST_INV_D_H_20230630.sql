ALTER TABLE xxcfr.xxcfr_rep_st_inv_d_h
ADD (
      target_date                       VARCHAR2(10)
     ,ar_concat_text                    VARCHAR2(80)
     ,ex_tax_charge_header              NUMBER
     ,tax_sum_header                    NUMBER
     ,payment_due_date                  VARCHAR2(20)
     ,category1                         VARCHAR2(30)
     ,category2                         VARCHAR2(30)
     ,category3                         VARCHAR2(30)
     ,ex_tax_charge1                    NUMBER
     ,ex_tax_charge2                    NUMBER
     ,ex_tax_charge3                    NUMBER
     ,tax_sum1                          NUMBER
     ,tax_sum2                          NUMBER
     ,tax_sum3                          NUMBER
     ,ship_cust_code                    VARCHAR2(30)
     ,ship_cust_name                    VARCHAR2(360)
     ,store_code                        VARCHAR2(10)
     ,store_code_sort                   VARCHAR2(10)
     ,ship_account_number               VARCHAR2(30)
     ,store_charge_sum                  NUMBER
     ,store_tax_sum                     NUMBER
     ,invoice_t_no                      VARCHAR2(14)
)
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.target_date                        IS '対象年月'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ar_concat_text                     IS '売掛管理コード連結文字列'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ex_tax_charge_header               IS 'ヘッダー用当月お買上げ額'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.tax_sum_header                     IS 'ヘッダー用消費税額'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.payment_due_date                   IS '入金予定日'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.category1                          IS '内訳分類１'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.category2                          IS '内訳分類２'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.category3                          IS '内訳分類３'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ex_tax_charge1                     IS '当月お買上げ額１'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ex_tax_charge2                     IS '当月お買上げ額２'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ex_tax_charge3                     IS '当月お買上げ額３'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.tax_sum1                           IS '消費税額１'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.tax_sum2                           IS '消費税額２'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.tax_sum3                           IS '消費税額３'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ship_cust_code                     IS '納品先顧客コード'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ship_cust_name                     IS '納品先顧客名'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.store_code                         IS '店舗コード'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.store_code_sort                    IS '店舗コード(ソート用)'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.ship_account_number                IS '納品先顧客コード(ソート用)'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.store_charge_sum                   IS '店舗金額'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.store_tax_sum                      IS '店舗税額'
/
COMMENT ON COLUMN xxcfr.xxcfr_rep_st_inv_d_h.invoice_t_no                       IS '適格請求書発行事業者登録番号'
/
