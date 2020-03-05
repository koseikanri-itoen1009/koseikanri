SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

clear buffer;

set feed off
set linesize 300
set pagesize 5000
set underline '='
set serveroutput on size 1000000
set trimspool on

set head off

SELECT           '�`�[�ԍ�'
        ||','||  '�`�[���t'
        ||','||  '�o�ɑ����_'
        ||','||  '�o�ɑ��q��'
        ||','||  '���ɑ����_'
        ||','||  '���ɑ��c�Ǝ�'
        ||','||  '�S����'
        ||','||  '�S���Җ�'
        ||','||  '�{�Џ��i�敪'
        ||','||  '�e��Q��'
        ||','||  '�e�i��'
        ||','||  '�e�i�ڗ���'
        ||','||  '�q�i��'
        ||','||  '�q�i�ڗ���'
        ||','||  '���b�g'
        ||','||  '�ŗL�L��'
        ||','||  '���P�[�V����'
        ||','||  '����'
        ||','||  '�P�[�X��'
        ||','||  '�o����'
        ||','||  '������ʁi�����j'
        ||','||  '��P��'
        ||','||  '�q�֐惁�C���q��'
        ||','||  '����^�C�v'
        ||','||  '�^�C�v��'
        ||','||  '��������'
FROM    dual
union all
SELECT          a.�`�[�ԍ�
        ||','|| a.�`�[���t
        ||','|| a.�o�ɑ����_
        ||','|| a.�o�ɑ��q��
        ||','|| a.���ɑ����_
        ||','|| a.���ɑ��c�Ǝ�
        ||','|| a.�S����
        ||','|| a.�S���Җ�
        ||','|| a.�{�Џ��i�敪
--        ||','|| a.�e��Q
        ||','|| a.�e��Q��
        ||','|| a.�e�i��
--        ||','|| a.�e�i�ږ�
        ||','|| a.�e�i�ڗ���
        ||','|| a.�q�i��
--        ||','|| a.�q�i�ږ�
        ||','|| a.�q�i�ڗ���
        ||','|| a.���b�g
        ||','|| a.�ŗL�L��
        ||','|| a.���P�[�V����
        ||','|| a.����
        ||','|| a.�P�[�X��
        ||','|| a.�o����
        ||','|| a.�������
        ||','|| a.��P��
        ||','|| a.�q�֐惁�C���q��
        ||','|| a.����^�C�v
        ||','|| a.�^�C�v��
        ||','|| a.��������
FROM   
(SELECT xlt.slip_num                      as                  "�`�[�ԍ�"
      , to_char(xlt.transaction_date,'YYYY/MM/DD') as         "�`�[���t"
      , xlt.base_code                     as                  "�o�ɑ����_"
      , xlt.subinventory_code             as                  "�o�ɑ��q��"
      , msiin.attribute7                  as                  "���ɑ����_"
      , xlt.inside_warehouse_code         as                  "���ɑ��c�Ǝ�"
      , msiin.attribute3                  as                  "�S����"
      , SUBSTRB(msiin.description, 1, 20) as                  "�S���Җ�"
      , mc.description                    as                  "�{�Џ��i�敪"
      , xsib.vessel_group                 as                  "�e��Q"
      , xiy.meaning                       as                  "�e��Q��"
      , msibp.segment1                    as                  "�e�i��"
      , msibp.description                 as                  "�e�i�ږ�"
      , ximbp.item_short_name             as                  "�e�i�ڗ���"
      , msibc.segment1                    as                  "�q�i��"
      , msibc.description                 as                  "�q�i�ږ�"
      , ximbc.item_short_name             as                  "�q�i�ڗ���"
      , xlt.lot                           as                  "���b�g"
      , xlt.difference_summary_code       as                  "�ŗL�L��"
      , xlt.location_code                 as                  "���P�[�V����"
      , xlt.case_in_qty                   as                  "����"
      , -xlt.case_qty                     as                  "�P�[�X��"
      , -xlt.singly_qty                   as                  "�o����"
      , -xlt.summary_qty                  as                  "�������"
      , xlt.transaction_uom               as                  "��P��"
      , xlt.transfer_subinventory         as                  "�q�֐惁�C���q��"
      , xlt.transaction_type_code         as                  "����^�C�v"
      , flv.meaning                       as                  "�^�C�v��"
      , to_char(xlt.creation_date,'YYYY/MM/DD HH24:MI:SS') as "��������"
FROM    xxcoi_lot_transactions            xlt
      , mtl_secondary_inventories         msiin
      , mtl_system_items_b                msibp
      , mtl_system_items_b                msibc
      , fnd_lookup_values                 flv
      , ic_item_mst_b                     iimbp
      , xxcmn_item_mst_b                  ximbp
      , ic_item_mst_b                     iimbc
      , xxcmn_item_mst_b                  ximbc
      , mtl_category_sets                 mcs
      , mtl_item_categories               mic
      , mtl_categories                    mc
      , xxcmm_system_items_b              xsib
      ,(SELECT flvv.lookup_code
              ,flvv.meaning
        FROM   apps.fnd_lookup_types_vl   fltv
              ,apps.fnd_lookup_values_vl  flvv
              ,apps.fnd_application_tl    fat
              ,apps.fnd_application       fa
        WHERE  fltv.lookup_type         = flvv.lookup_type(+)
        AND    fltv.application_id      = fat.application_id
        AND    fltv.view_application_id = fa.application_id
        AND    fat.language             = 'JA'
        AND    fltv.lookup_type         = 'XXCMM_ITM_YOKIGUN') xiy --�Q�ƃ^�C�v�F�e��Q
WHERE   xlt.inside_warehouse_code       = msiin.secondary_inventory_name
AND     xlt.parent_item_id              = msibp.inventory_item_id
AND     xlt.child_item_id               = msibc.inventory_item_id
AND     msibp.organization_id           = xxcoi_common_pkg.get_organization_id( fnd_profile.value( 'XXCOI1_ORGANIZATION_CODE' ) )
AND     msibc.organization_id           = xxcoi_common_pkg.get_organization_id( fnd_profile.value( 'XXCOI1_ORGANIZATION_CODE' ) )
AND     msibp.segment1                  = iimbp.item_no
AND     iimbp.item_id                   = ximbp.item_id
AND     SYSDATE BETWEEN ximbp.start_date_active AND ximbp.end_date_active
AND     msibc.segment1                  = iimbc.item_no
AND     iimbc.item_id                   = ximbc.item_id
AND     SYSDATE BETWEEN ximbc.start_date_active AND ximbc.end_date_active
AND     msibp.inventory_item_id         = mic.inventory_item_id
AND     msibp.organization_id           = mic.organization_id
AND     mcs.category_set_name           = '�{�Џ��i�敪'
AND     mcs.category_set_id             = mic.category_set_id
AND     mic.category_id                 = mc.category_id
AND     flv.lookup_type                 = 'XXCOI1_TRANSACTION_TYPE_NAME'
AND     flv.language                    = USERENV( 'LANG' )
AND     flv.lookup_code                 = xlt.transaction_type_code
and     msibp.segment1                  = xsib.ITEM_CODE
and     xsib.vessel_group               = xiy.lookup_code(+)
AND     xlt.transaction_date           >= TRUNC(SYSDATE)-14
--  ���������i�쐬�����j
and     xlt.creation_date              >= TO_DATE('&1', 'YYYY/MM/DD HH24:MI:SS' ) --�p�����[�^�F�쐬����
order by xlt.slip_num , xlt.transaction_date ,xlt.inside_warehouse_code , mc.description , xsib.vessel_group , msibp.segment1 , msibc.segment1) a
;

--Prompt
--Prompt ********************************************************************************
--Prompt ********************* END ******************************************************
--Prompt ********************************************************************************
--Prompt

exit;
