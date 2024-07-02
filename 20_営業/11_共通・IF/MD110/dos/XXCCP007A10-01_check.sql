set verify off
set serveroutput on
set trimspool on
set heading on
set tab off
set headsep ','
set colsep ','
set lines 5000
set pagesize 1000

DEFINE  connect_user       = &1
DEFINE  connect_password   = &2
DEFINE  net_service        = &3
DEFINE  log_file           = &4
DEFINE  input_date         = &5

set echo off
connect &&connect_user/&&connect_password@&&net_service

spool &&log_file

SELECT
    papf.employee_number           AS 従業員番号                 -- 1.従業員番号
  , papf.full_name                 AS 従業員名                   -- 2.従業員名
  , pv.segment1                    AS 仕入先番号                 -- 3.仕入先番号
  , pv.vendor_name                 AS 仕入先名                   -- 4.仕入先名
  , abb.bank_number                AS 銀行番号                   -- 5.銀行番号
  , abb.bank_name                  AS 銀行名                     -- 6.銀行名
  , abb.bank_num                   AS 銀行支店番号                -- 7.銀行支店番号
  , abb.bank_branch_name           AS 銀行支店名                  -- 8.銀行支店名
  , abaa.bank_account_type         AS 口座種別                    -- 9.口座種別
  , abaa.bank_account_num          AS 口座番号                    -- 10.口座番号
  , abaa.account_holder_name       AS 口座名義人                  -- 11.口座名義人
  , abaa.account_holder_name_alt   AS 口座名義人カナ               -- 12.口座名義人カナ
  , RPAD( abaua.primary_flag, 20 ) AS 経費プライマリフラグ          -- 13.経費プライマリフラグ
  , TO_CHAR( abaua.creation_date, 'YYYY/MM/DD HH24:MI;SS' )    AS 銀行口座使用マスタの作成日      -- 14.銀行口座使用マスタの作成日
  , TO_CHAR( abaua.last_update_date, 'YYYY/MM/DD HH24:MI;SS' ) AS 銀行口座使用マスタの最終更新日  -- 15.銀行口座使用マスタの最終更新日
  , TO_CHAR( abaa.creation_date, 'YYYY/MM/DD HH24:MI;SS' )     AS 銀行口座マスタの作成日         -- 16.銀行口座マスタの作成日
  , TO_CHAR( abaa.last_update_date, 'YYYY/MM/DD HH24:MI;SS' )  AS 銀行口座マスタの最終更新日      -- 17.銀行口座マスタの最終更新日
FROM
   apps.per_all_people_f           papf  -- 従業員マスタ
  ,apps.po_vendors                 pv    -- 仕入先マスタ
  ,apps.po_vendor_sites_all        pvsa  -- 仕入先サイトマスタ
  ,apps.ap_bank_accounts_all       abaa  -- 銀行口座マスタ
  ,apps.ap_bank_branches           abb   -- 銀行支店マスタ
  ,apps.ap_bank_account_uses_all   abaua -- 銀行口座使用マスタ 
WHERE
    papf.attribute3 IN ('1', '4')  -- 従業員区分（1:内部、4:ダミー）
AND papf.attribute4 IS NULL        -- 仕入先コード
AND papf.attribute5 IS NULL        -- 運送業者
AND papf.employee_number NOT IN ( '99983', '99984', '99985', '99989', 
                                  '99997', '99998', '99999', 'XXSCV_2' )  -- 抽出対象外の従業員番号
AND papf.effective_start_date = 
        (SELECT
             MAX(papf2.effective_start_date)
         FROM
             apps.per_all_people_f  papf2  -- 従業員マスタ
         WHERE
             papf2.person_id = papf.person_id
        )
AND papf.person_id                 = pv.employee_id
AND pv.vendor_type_lookup_code     = 'EMPLOYEE'
AND pv.vendor_id                   = pvsa.vendor_id
AND pvsa.vendor_site_code          = '会社'
AND pvsa.vendor_id                 = abaua.vendor_id
AND pvsa.vendor_site_id            = abaua.vendor_site_id
AND abaua.external_bank_account_id = abaa.bank_account_id
AND abaa.account_type              = 'SUPPLIER'
AND abaa.bank_branch_id            = abb.bank_branch_id
AND abaua.primary_flag             = 'Y'
AND abaua.last_update_date        >= TO_DATE( NVL( '&&input_date', TO_CHAR( SYSDATE, 'YYYYMMDD' )) || ' 060000', 'YYYYMMDD HH24MISS' ) -1
AND abaua.last_update_date         < TO_DATE( NVL( '&&input_date', TO_CHAR( SYSDATE, 'YYYYMMDD' )) || ' 060000', 'YYYYMMDD HH24MISS' )
AND abaa.last_update_date          < TO_DATE( NVL( '&&input_date', TO_CHAR( SYSDATE, 'YYYYMMDD' )) || ' 060000', 'YYYYMMDD HH24MISS' ) -1
ORDER BY
    papf.employee_number
  , pv.segment1
  , abb.bank_number
  , abb.bank_num
  , abaa.bank_account_type
  , abaa.bank_account_num
/

spool off

quit
