/*************************************************************************
 * 
 * VIEW Name       : XXCSO_BANK_ACCTS_V
 * Description     : 共通用：銀行口座マスタ（最新）ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_BANK_ACCTS_V
(
 vendor_id
,vendor_site_id
,bank_number
,bank_name
,bank_num
,bank_branch_name
,bank_account_type
,bank_account_num
,account_holder_name_alt
,account_holder_name
)
AS
SELECT
 abau.vendor_id
,abau.vendor_site_id
,abb.bank_number
,abb.bank_name
,abb.bank_num
,abb.bank_branch_name
,aba.bank_account_type
,aba.bank_account_num
,aba.account_holder_name_alt
,aba.account_holder_name
FROM
 ap_bank_account_uses abau
,ap_bank_accounts aba
,ap_bank_branches abb
WHERE
abau.primary_flag = 'Y' AND
NVL(abau.start_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
NVL(abau.end_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
aba.bank_account_id = abau.external_bank_account_id AND
abb.bank_branch_id = aba.bank_branch_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_BANK_ACCTS_V.vendor_id IS '仕入先ID';
COMMENT ON COLUMN XXCSO_BANK_ACCTS_V.vendor_id IS '仕入先サイトID';
COMMENT ON COLUMN XXCSO_BANK_ACCTS_V.bank_number IS '銀行番号';
COMMENT ON COLUMN XXCSO_BANK_ACCTS_V.bank_name IS '銀行名';
COMMENT ON COLUMN XXCSO_BANK_ACCTS_V.bank_num IS '銀行支店番号';
COMMENT ON COLUMN XXCSO_BANK_ACCTS_V.bank_branch_name IS '銀行支店名';
COMMENT ON COLUMN XXCSO_BANK_ACCTS_V.bank_account_type IS '口座種別';
COMMENT ON COLUMN XXCSO_BANK_ACCTS_V.bank_account_num IS '口座番号';
COMMENT ON COLUMN XXCSO_BANK_ACCTS_V.account_holder_name_alt IS '口座名義カナ';
COMMENT ON COLUMN XXCSO_BANK_ACCTS_V.account_holder_name IS '口座名義漢字';
COMMENT ON TABLE XXCSO_BANK_ACCTS_V IS '共通用：銀行口座マスタ（最新）ビュー';
