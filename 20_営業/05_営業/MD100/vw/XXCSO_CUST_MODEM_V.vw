/*************************************************************************
 * 
 * VIEW Name       : XXCSO_CUST_MODEM_V
 * Description     : �ڋq�i�ʐM���f���j�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2015/06/24    1.0  S.Yamashita   ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_cust_modem_v
(
 account_number
,party_name
)
AS
SELECT /*+ LEADING(hca) */
       hca.account_number
      ,hp.party_name
FROM
       csi_item_instances cii
      ,hz_cust_accounts   hca
      ,hz_parties         hp
      ,po_un_numbers_vl   punv
WHERE
       cii.owner_party_account_id = hca.cust_account_id
AND    hca.party_id               = hp.party_id
AND    cii.attribute1             = punv.un_number
AND    punv.attribute15           = '1'
AND    hca.account_number         <> '6864'
WITH READ ONLY
;
COMMENT ON COLUMN xxcso_cust_modem_v.account_number IS '�ڋq�R�[�h';
COMMENT ON COLUMN xxcso_cust_modem_v.party_name IS '�ڋq��';
COMMENT ON TABLE xxcso_cust_modem_v IS '�ڋq�i�ʐM���f���j�r���[';
