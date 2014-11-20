CREATE OR REPLACE FORCE VIEW XXCFR_RECEIPT_CUST_ACCOUNTS_V (
/*************************************************************************
 * 
 * View Name       : XXCFR_RECEIPT_CUST_ACCOUNTS_V
 * Description     : 入金先顧客ビュー（支払通知データダウンロード用）
 * MD.050          : MD.050_LDM_CFR_001
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2008/11/27    1.0  SCS 中村 博   初回作成
 *  2010/01/29    1.1  SCS 安川 智博 障害「E__本稼動_01503」対応
 ************************************************************************/
  type,                                   -- タイプ
  account_number,                         -- 顧客コード
  party_name                              -- 顧客名
) AS
-- エラーデータ抽出用
SELECT '1'                type,           -- タイプ
       'Error'            account_number, -- 顧客コード
       'エラー'           party_name      -- 顧客名
  FROM dual
UNION
SELECT 
       '2'                  type                         -- タイプ
      ,cash_account_number                               --入金先顧客コード    ：(入金先顧客)
      ,xxcfr_common_pkg.get_cust_account_name(cash_account_number, 0) --入金先顧客名称      ：(入金先顧客)
  FROM (
    --①入金先顧客（売掛金管理先顧客）
    SELECT DISTINCT
           hca.cust_account_id       cash_account_id         --入金先顧客ID        ：(入金先顧客)
          ,hca.account_number        cash_account_number     --入金先顧客コード    ：(入金先顧客)
    FROM
         hz_cust_accounts          hca              --請求先顧客マスタ
        ,hz_cust_acct_sites_all    hcasa            --請求先顧客所在地
        ,hz_cust_site_uses_all     hcsua            --請求先顧客使用目的
        ,hz_customer_profiles      hcp              --請求先顧客プロファイル
    WHERE 
          hca.customer_class_code = '14'                        --請求先顧客.顧客区分 = '14'(売掛管理先顧客)
      AND NOT EXISTS (
                SELECT ROWNUM
                FROM hz_cust_acct_relate_all hcara           --顧客関連マスタ(入金関連)
                WHERE hcara.related_cust_account_id = hca.cust_account_id   --顧客関連マスタ(入金関連).関連先顧客ID = 請求先顧客マスタ.顧客ID
                  AND hcara.status                  = 'A'                   --顧客関連マスタ(入金関連).ステータス = ‘A’
                  AND hcara.attribute1              = '2'                   --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
              )
      AND hca.cust_account_id     = hcasa.cust_account_id       --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
      AND hcasa.org_id            = fnd_profile.value('ORG_ID') --請求先顧客所在地.組織ID = 
      AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
      AND hcsua.site_use_code     = 'BILL_TO'                   --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010/01/29 Yasukawa Start
      AND hcsua.status            = 'A'                         --請求先顧客使用目的.ステータス = 'A'
-- Add 2010/01/29 Yasukawa End
      AND hca.cust_account_id     = hcp.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客プロファイル.顧客ID
      AND hcp.site_use_id         IS NULL                       --請求先顧客プロファイル.使用目的 IS NULL
    UNION ALL
    --②入金先顧客＆請求先顧客＆出荷先顧客
    SELECT DISTINCT
           hca.cust_account_id       cash_account_id         --入金先顧客ID        ：(入金先顧客)
          ,hca.account_number        cash_account_number     --入金先顧客コード    ：(入金先顧客)
    FROM 
         hz_cust_accounts          hca              --出荷先顧客マスタ　※入金先・請求先含む
        ,hz_cust_acct_sites_all    hcasa            --請求先顧客所在地
        ,hz_cust_site_uses_all     hcsua            --請求先顧客使用目的
        ,hz_customer_profiles      hcp              --請求先顧客プロファイル
    WHERE 
          hca.customer_class_code = '10'                        --請求先顧客.顧客区分 = '10'(顧客)
      AND NOT EXISTS (
                SELECT ROWNUM
                FROM hz_cust_acct_relate_all hcara2           --顧客関連マスタ
                WHERE 
                     (hcara2.cust_account_id         = hca.cust_account_id   --顧客関連マスタ(請求関連).顧客ID = 出荷先顧客マスタ.顧客ID
                   OR hcara2.related_cust_account_id = hca.cust_account_id)  --顧客関連マスタ(請求関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
                  AND hcara2.status                  = 'A'                   --顧客関連マスタ(請求関連).ステータス = ‘A’
              )
      AND hca.cust_account_id     = hcasa.cust_account_id       --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
      AND hcasa.org_id            = fnd_profile.value('ORG_ID') --請求先顧客所在地.組織ID = 
      AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
      AND hcsua.site_use_code     = 'BILL_TO'                   --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010/01/29 Yasukawa Start
      AND hcsua.status            = 'A'                         --請求先顧客使用目的.ステータス = 'A'
-- Add 2010/01/29 Yasukawa End
      AND hca.cust_account_id     = hcp.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客プロファイル.顧客ID
      AND hcp.site_use_id         IS NULL                       --請求先顧客プロファイル.使用目的 IS NULL
  )  xxcfr_receipt_cust_account
;
--
COMMENT ON COLUMN xxcfr_receipt_cust_accounts_v.type                IS 'タイプ';
COMMENT ON COLUMN xxcfr_receipt_cust_accounts_v.account_number      IS '顧客コード';
COMMENT ON COLUMN xxcfr_receipt_cust_accounts_v.party_name          IS '顧客名';
--
COMMENT ON TABLE  xxcfr_receipt_cust_accounts_v IS '入金先顧客ビュー（支払通知データダウンロード用）';
