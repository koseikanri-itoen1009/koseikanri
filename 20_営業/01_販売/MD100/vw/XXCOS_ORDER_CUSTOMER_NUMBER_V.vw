/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_order_customer_number_v
 * Description     : 顧客コードのセキュリティ（クイック受注用）
 * Version         : 1.6
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/26    1.0   T.Tyou           新規作成
 *  2009/05/18    1.1   S.Tomita         [T1_0976]クイック受注オーガナイザセキュリティ対応
 *  2009/07/06    1.2   K.Kakishita      [T3_0317]パフォーマンス対応
 *                                       ・ヒント句追加、IN句からEXISTSへの変更
 *                                       ・拠点コード、顧客ステータス項目の削除
 *  2009/07/10    1.3   K.Kakishita      [T3_0317]パフォーマンス対応
 *                                       ・ヒント句追加、EXISTSからINへの変更
 *  2009/07/15    1.4   K.Kakishita      [T3_0757]重複データが表示される障害対応
 *                                       ・GROUP BY句を追加
 *  2009/09/03    1.5   M.Sano           [0001277]業務日付取得方法をテーブル参照へ変更
 *  2017/10/18    1.6   S.Niki           [E_本稼動_14671]事務センター構想に伴なう拠点セキュリティ変更
 *
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_order_customer_number_v (
  account_number,
  account_description,
  registry_id,
  party_name,
  party_type,
  cust_account_id,
  email_address,
  gsa_indicator
)
AS
  SELECT
    /*+
      INDEX ( acct HZ_CUST_ACCOUNTS_N06 )
      INDEX ( party HZ_PARTIES_U1 )
      INDEX ( xca XXCMM_CUST_ACCOUNTS_PK )
    */
    acct.account_number                   account_number,
    acct.account_name                     account_description,
    party.party_number                    registry_id,
    party.party_name                      party_name,
    party.party_type                      party_type,
    acct.cust_account_id                  cust_account_id,
    party.email_address                   email_address,
    NVL( party.gsa_indicator_flag, 'N' )  gsa_indicator
  FROM
    hz_parties                            party,
    hz_cust_accounts                      acct,
    xxcmm_cust_accounts                   xca,
-- Ver1.6 Mod Start
--    xxcos_login_base_info_v               xlbiv
    xxcos_all_or_login_base_info_v        xlbiv
-- Ver1.6 Mod End
  WHERE
    acct.party_id                       = party.party_id
  AND acct.status                       = 'A'
  AND acct.cust_account_id              = xca.customer_id
  AND xlbiv.base_code IN ( xca.sale_base_code, xca.past_sale_base_code, xca.delivery_base_code )
  AND EXISTS(
        SELECT 'Y' exists_flag
        FROM fnd_lookup_values flv
-- 2009/09/03 Ver1.5 Add Start
            ,( SELECT TRUNC( xpd.process_date ) process_date
               FROM   xxccp_process_dates xpd ) pd
-- 2009/09/03 Ver1.5 Add End
        WHERE flv.lookup_type = 'XXCOS1_CUS_CLASS_MST_005_A01'
        AND flv.meaning = acct.customer_class_code
        AND flv.enabled_flag = 'Y'
        AND flv.language = userenv('LANG')
-- 2009/09/03 Ver1.5 Mod Start
--        AND xxccp_common_pkg2.get_process_date >= flv.start_date_active
--        AND xxccp_common_pkg2.get_process_date <= NVL(flv.end_date_active, xxccp_common_pkg2.get_process_date )
        AND pd.process_date >= flv.start_date_active
        AND pd.process_date <= NVL(flv.end_date_active, pd.process_date )
-- 2009/09/03 Ver1.5 Mod End
      )
  GROUP BY
    acct.account_number,
    acct.account_name,
    party.party_number,
    party.party_name,
    party.party_type,
    acct.cust_account_id,
    party.email_address,
    NVL( party.gsa_indicator_flag, 'N' )
;
COMMENT ON  COLUMN  xxcos_order_customer_number_v.account_number       IS  '顧客コード';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.account_description  IS  '顧客名称';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.registry_id          IS  'パーティ番号';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.party_name           IS  'パーティ名称';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.party_type           IS  'パーティタイプ';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.cust_account_id      IS  '顧客ID';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.email_address        IS  'メールアドレス';
COMMENT ON  COLUMN  xxcos_order_customer_number_v.gsa_indicator        IS  'フラグ';
--
COMMENT ON  TABLE   xxcos_order_customer_number_v                      IS  '顧客コードのセキュリティ(クイック受注用)';
