CREATE OR REPLACE VIEW XXCFR_AWI_SHIP_CODE_V ("DESCRIPTION", "NAME")
AS 
/*************************************************************************
 * 
 * View Name       : XXCFR_AWI_SHIP_CODE_V
 * Description     : ARWebInquiry�p �[�i��ڋq�R�[�hLOV
 *                 : xgv_riq.pkb�̐�����l���X�g���쐬����SQL��胂�f�B�t�@�C(L.3513�`3523)
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- -------------    -------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- -------------    -------------------------------------
 *  2010/07/09    1.0  SCS �A�� �^���l  ��Q�uE_�{�ғ�_01990�v�Ή�
 ************************************************************************/
SELECT hp.party_name      AS description
      ,hca.account_number AS name
FROM   hz_cust_accounts hca
      ,hz_parties       hp
WHERE  hca.party_id = hp.party_id
AND    EXISTS(SELECT NULL
              FROM   hz_cust_acct_sites  hcs
                    ,hz_cust_site_uses   hcu
              WHERE  hcs.cust_account_id   = hca.cust_account_id
              AND    hcs.cust_acct_site_id = hcu.cust_acct_site_id
              AND    ROWNUM <= 1
       )
;

COMMENT ON COLUMN  xxcfr_awi_ship_code_v.description IS '�ڋq��';
COMMENT ON COLUMN  xxcfr_awi_ship_code_v.name        IS '�ڋq�R�[�h';

COMMENT ON TABLE  xxcfr_awi_ship_code_v IS 'ARWebInquiry�p �[�i��ڋq�R�[�hLOV';
