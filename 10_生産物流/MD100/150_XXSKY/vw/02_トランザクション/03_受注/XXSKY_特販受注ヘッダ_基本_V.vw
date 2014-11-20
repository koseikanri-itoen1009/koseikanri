CREATE OR REPLACE VIEW APPS.XXSKY_特販受注ヘッダ_基本_V
(
   ステータス
  ,受注タイプ
  ,コンテキスト値
  ,請求先
  ,請求先名
  ,受注番号
  ,納品予定日
  ,顧客コード
  ,顧客名
  ,顧客_住所
  ,拠点コード
  ,拠点名称
  ,"時間指定（From）"
  ,"時間指定（To）"
  ,摘要
  ,オーダーNo
  ,受注日
  ,担当営業員
  ,顧客発注番号
)
AS
SELECT
        CASE ooha.flow_status_code 
        WHEN 'ENTERED'    THEN  '入力済'
        WHEN 'CANCELLED'  THEN  '取消'
        WHEN 'CLOSED'     THEN  'クローズ'
        WHEN 'BOOKED'     THEN  '記帳済'
        ELSE '－'
        END                                           ステータス
      , ottt.name                                     受注タイプ
      , ooha.context                                  コンテキスト値
      , s_hca.account_number                          請求先
      , s_hp.party_name                               請求先名
      , ooha.order_number                             受注番号
      , ooha.request_date                             納品予定日
      , k_hca.account_number                          顧客コード
      , k_hp.party_name                               顧客名
      , k_hl.address1                                 顧客_住所
      , k_hca.attribute17                             拠点コード
      , xca2v2.party_name                             拠点名称
      , ooha.attribute13                              "時間指定（From）"
      , ooha.attribute14                              "時間指定（To）"
      , ooha.shipping_instructions                    摘要
      , ooha.attribute19                              オーダーNo
      , ooha.ordered_date                             受注日
      , papf.full_name                                担当営業員
      , ooha.cust_po_number                           顧客発注番号
FROM    oe_order_headers_all          ooha    -- 受注ヘッダ
      , oe_transaction_types_tl       ottt    -- 受注タイプマスタ(日本語)
      -- 営業担当
      , jtf_rs_resource_extns         jrre    -- リソースマスタ
      , per_all_people_f              papf    -- 従業員マスタ
      , jtf_rs_salesreps              jrs     -- jtf_rs_salesreps
      -- 顧客情報
      , hz_cust_accounts              k_hca
      , hz_parties                    k_hp
      , hz_cust_site_uses_all         k_hcsua
      , hz_cust_acct_sites_all        k_hcasa
      , hz_party_sites                k_hps
      , hz_locations                  k_hl
      , xxcmn_cust_accounts2_v        xca2v2
      -- 請求先情報
      , hz_cust_site_uses_all         s_hcaua
      , hz_cust_acct_sites_all        s_hcasa
      , hz_cust_accounts              s_hca
      , hz_parties                    s_hp
      -- 営業単位
      , hr_all_organization_units     haou
WHERE 
--受注タイプ名取得
     ottt.language      = 'JA'
AND  ooha.order_type_id = OTTT.transaction_type_id
-- 担当者名
AND  ooha.salesrep_id   = jrs.salesrep_id
AND  jrs.resource_id    = jrre.resource_id
AND  jrre.source_id     = papf.person_id
AND  ooha.request_date BETWEEN TRUNC(papf.effective_start_date)
                           AND TRUNC(NVL(papf.effective_end_date, ooha.request_date))
-- 顧客情報
AND   ooha.sold_to_org_id        = k_hca.cust_account_id
AND   k_hca.party_id             = k_hp.party_id
AND   ooha.ship_to_org_id        = k_hcsua.site_use_id
AND   k_hcsua.site_use_code      = 'SHIP_TO'
AND   k_hcsua.cust_acct_site_id  = k_hcasa.cust_acct_site_id
AND   k_hcasa.party_site_id      = k_hps.party_site_id
AND   k_hps.location_id          = k_hl.location_id
-- 当月売上拠点名
AND   k_hca.attribute17          = xca2v2.party_number
AND   ooha.request_date BETWEEN xca2v2.start_date_active
                            AND xca2v2.end_date_active
-- 請求先情報
AND   ooha.invoice_to_org_id    = s_hcaua.site_use_id
AND   s_hcaua.cust_acct_site_id = s_hcasa.cust_acct_site_id
AND   s_hcasa.cust_account_id   = s_hca.cust_account_id
AND   s_hca.party_id            = s_hp.party_id
-- 拠点コード（特版部指定 クイックコード定義）
AND   EXISTS (
              SELECT 'x'
              FROM  xxcmn_lookup_values_v xlvv
              WHERE xlvv.lookup_type = 'XXCMN_SALE_SKYLINK_BRANCH'
              AND   xlvv.lookup_code = k_hca.attribute17
             )
-- 営業組織
AND   haou.type    = 'OU'
AND   haou.name    = 'SALES-OU'
-- 営業 組織ID
AND   ooha.org_id  = haou.organization_id
;
