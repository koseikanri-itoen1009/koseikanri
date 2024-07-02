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
    papf.employee_number           AS �]�ƈ��ԍ�                 -- 1.�]�ƈ��ԍ�
  , papf.full_name                 AS �]�ƈ���                   -- 2.�]�ƈ���
  , pv.segment1                    AS �d����ԍ�                 -- 3.�d����ԍ�
  , pv.vendor_name                 AS �d���於                   -- 4.�d���於
  , abb.bank_number                AS ��s�ԍ�                   -- 5.��s�ԍ�
  , abb.bank_name                  AS ��s��                     -- 6.��s��
  , abb.bank_num                   AS ��s�x�X�ԍ�                -- 7.��s�x�X�ԍ�
  , abb.bank_branch_name           AS ��s�x�X��                  -- 8.��s�x�X��
  , abaa.bank_account_type         AS �������                    -- 9.�������
  , abaa.bank_account_num          AS �����ԍ�                    -- 10.�����ԍ�
  , abaa.account_holder_name       AS �������`�l                  -- 11.�������`�l
  , abaa.account_holder_name_alt   AS �������`�l�J�i               -- 12.�������`�l�J�i
  , RPAD( abaua.primary_flag, 20 ) AS �o��v���C�}���t���O          -- 13.�o��v���C�}���t���O
  , TO_CHAR( abaua.creation_date, 'YYYY/MM/DD HH24:MI;SS' )    AS ��s�����g�p�}�X�^�̍쐬��      -- 14.��s�����g�p�}�X�^�̍쐬��
  , TO_CHAR( abaua.last_update_date, 'YYYY/MM/DD HH24:MI;SS' ) AS ��s�����g�p�}�X�^�̍ŏI�X�V��  -- 15.��s�����g�p�}�X�^�̍ŏI�X�V��
  , TO_CHAR( abaa.creation_date, 'YYYY/MM/DD HH24:MI;SS' )     AS ��s�����}�X�^�̍쐬��         -- 16.��s�����}�X�^�̍쐬��
  , TO_CHAR( abaa.last_update_date, 'YYYY/MM/DD HH24:MI;SS' )  AS ��s�����}�X�^�̍ŏI�X�V��      -- 17.��s�����}�X�^�̍ŏI�X�V��
FROM
   apps.per_all_people_f           papf  -- �]�ƈ��}�X�^
  ,apps.po_vendors                 pv    -- �d����}�X�^
  ,apps.po_vendor_sites_all        pvsa  -- �d����T�C�g�}�X�^
  ,apps.ap_bank_accounts_all       abaa  -- ��s�����}�X�^
  ,apps.ap_bank_branches           abb   -- ��s�x�X�}�X�^
  ,apps.ap_bank_account_uses_all   abaua -- ��s�����g�p�}�X�^ 
WHERE
    papf.attribute3 IN ('1', '4')  -- �]�ƈ��敪�i1:�����A4:�_�~�[�j
AND papf.attribute4 IS NULL        -- �d����R�[�h
AND papf.attribute5 IS NULL        -- �^���Ǝ�
AND papf.employee_number NOT IN ( '99983', '99984', '99985', '99989', 
                                  '99997', '99998', '99999', 'XXSCV_2' )  -- ���o�ΏۊO�̏]�ƈ��ԍ�
AND papf.effective_start_date = 
        (SELECT
             MAX(papf2.effective_start_date)
         FROM
             apps.per_all_people_f  papf2  -- �]�ƈ��}�X�^
         WHERE
             papf2.person_id = papf.person_id
        )
AND papf.person_id                 = pv.employee_id
AND pv.vendor_type_lookup_code     = 'EMPLOYEE'
AND pv.vendor_id                   = pvsa.vendor_id
AND pvsa.vendor_site_code          = '���'
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
