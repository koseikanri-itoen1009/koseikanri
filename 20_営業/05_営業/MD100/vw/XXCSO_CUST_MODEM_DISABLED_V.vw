/*************************************************************************
 * 
 * VIEW Name       : XXCSO_CUST_MODEM_DISABLED_V
 * Description     : �ʐM���f���ݒu�s�ڋq�ꗗ�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2015/06/24    1.0  S.Yamashita   ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_cust_modem_disabled_v
(
 account_number
,party_name
)
AS
SELECT hca.account_number
      ,hp.party_name
FROM
       xxcso_hht_col_dlv_coop_trn xhcdct
      ,hz_cust_accounts           hca
      ,hz_parties                 hp
WHERE
       xhcdct.account_number       = hca.account_number
AND    hca.party_id                = hp.party_id
AND    xhcdct.creating_source_code = 'XXCSO011A05C'
AND    xhcdct.cooperate_flag       = 'Y'
AND    xhcdct.withdraw_psid        IS NOT NULL
WITH READ ONLY
;
COMMENT ON COLUMN xxcso_cust_modem_disabled_v.account_number IS '�ڋq�R�[�h';
COMMENT ON COLUMN xxcso_cust_modem_disabled_v.party_name IS '�ڋq��';
COMMENT ON TABLE  xxcso_cust_modem_disabled_v IS '�ʐM���f���ݒu�s�ڋq�ꗗ�r���[';
