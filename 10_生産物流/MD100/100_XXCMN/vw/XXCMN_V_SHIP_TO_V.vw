CREATE OR REPLACE VIEW xxcmn_v_ship_to_v
(
  type
 ,code
 ,name
)
AS
SELECT  '1' type, 'ALL' code, 'èWåvñ≥Çµ' name 
FROM dual 
UNION ALL
SELECT '2' type, xcav.party_number code, xcav.party_short_name name 
FROM xxcmn_cust_accounts_v xcav 
WHERE xcav.party_number <> '9999' 
UNION ALL 
SELECT '3' type, xvv.segment1 code, xvv.vendor_short_name name 
FROM xxcmn_vendors_v xvv
;
