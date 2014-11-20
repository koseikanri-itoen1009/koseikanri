CREATE OR REPLACE VIEW XXCFR_AWI_SHIP_CODE_V ("DESCRIPTION", "NAME")
AS 
/*************************************************************************
 * 
 * View Name       : XXCFR_AWI_SHIP_CODE_V
 * Description     : ARWebInquiry用 納品先顧客コードLOV
 *                 : xgv_riq.pkbの請求先値リストを作成するSQLよりモディファイ(L.3513～3523)
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- -------------    -------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- -------------    -------------------------------------
 *  2010/07/09    1.0  SCS 廣瀬 真佐人  障害「E_本稼動_01990」対応
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

COMMENT ON COLUMN  xxcfr_awi_ship_code_v.description IS '顧客名';
COMMENT ON COLUMN  xxcfr_awi_ship_code_v.name        IS '顧客コード';

COMMENT ON TABLE  xxcfr_awi_ship_code_v IS 'ARWebInquiry用 納品先顧客コードLOV';
