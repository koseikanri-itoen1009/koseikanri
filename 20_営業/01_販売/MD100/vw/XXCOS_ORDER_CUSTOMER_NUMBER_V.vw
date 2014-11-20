/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_order_customer_number_v
 * Description     : 顧客コードのセキュリティ（クイック受注用）
 * Version         : 1.2
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
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_order_customer_number_v (
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
      INDEX ( xca xxcmm_cust_accounts_pk )
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
    xxcmm_cust_accounts                   xca
  WHERE
    acct.party_id                       = party.party_id
  AND acct.status                       = 'A'
  AND acct.cust_account_id              = xca.customer_id
  AND EXISTS(
        SELECT 'Y' exeist_flag
        FROM xxcos_order_lookup_values_v xolvv
        WHERE xolvv.lookup_type = 'XXCOS1_CUS_CLASS_MST_005_A01'
        AND xolvv.meaning = acct.customer_class_code
      )
  AND EXISTS(
        SELECT 'Y' exists_flag
        FROM xxcos_login_base_info_v xlbiv
        WHERE xlbiv.base_code IN ( xca.sale_base_code, xca.past_sale_base_code, xca.delivery_base_code )
      )
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
