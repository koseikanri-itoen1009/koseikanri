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

SELECT
   '�`�[�ԍ�'              ||','||
   '�`�[���t'              ||','||
   '�o�ɑ����_'            ||','||
   '�o�ɑ��q��'            ||','||
   '���ɑ����_'            ||','||
   '���ɑ��c�Ǝ�'          ||','||
   '�S����'                ||','||
   '�S���Җ�'              ||','||
   '�{�Џ��i�敪'          ||','||
   '�e�i��'                ||','||
   '�e�i�ڗ���'            ||','||
   '�q�i��'                ||','||
   '�q�i�ڗ���'            ||','||
   '���b�g'                ||','||
   '�ŗL�L��'              ||','||
   '���P�[�V����'          ||','||
   '����'                  ||','||
   '�P�[�X��'              ||','||
   '�o����'                ||','||
   '������ʁi�����j'      ||','||
   '��P��'              ||','||
   '�q�֐惁�C���q��'      ||','||
   '����^�C�v'            ||','||
   '�^�C�v��'
FROM
   dual
;
SELECT        xlt.slip_num                        --  "�`�[�ԍ�"
      ||','|| xlt.transaction_date                --  "�`�[���t"
      ||','|| xlt.base_code                       --  "�o�ɑ����_"
      ||','|| xlt.subinventory_code               --  "�o�ɑ��q��"
      ||','|| msiin.attribute7                    --  "���ɑ����_"
      ||','|| xlt.inside_warehouse_code           --  "���ɑ��c�Ǝ�"
      ||','|| msiin.attribute3                    --  "�S����"
      ||','|| SUBSTRB(msiin.description, 1, 20)   --  "�S���Җ�"
      ||','|| mc.description                      --  "�{�Џ��i�敪"
      ||','|| msibp.segment1                      --  "�e�i��"
--      ||','|| msibp.description                   --  "�e�i�ږ�"
      ||','|| ximbp.item_short_name               --  "�e�i�ڗ���"
      ||','|| msibc.segment1                      --  "�q�i��"
--      ||','|| msibc.description                   --  "�q�i�ږ�"
      ||','|| ximbc.item_short_name               --  "�q�i�ڗ���"
      ||','|| xlt.lot                             --  "���b�g"
      ||','|| xlt.difference_summary_code         --  "�ŗL�L��"
      ||','|| xlt.location_code                   --  "���P�[�V����"
      ||','|| xlt.case_in_qty                     --  "����"
      ||','|| -xlt.case_qty                        --  "�P�[�X��"
      ||','|| -xlt.singly_qty                      --  "�o����"
      ||','|| -xlt.summary_qty                     --  "������ʁi�����j"
      ||','|| xlt.transaction_uom                 --  "��P��"
      ||','|| xlt.transfer_subinventory           --  "�q�֐惁�C���q��"
      ||','|| xlt.transaction_type_code           --  "����^�C�v"
      ||','|| flv.meaning                         --  "�^�C�v��"
FROM    xxcoi_lot_transactions      xlt
      , mtl_secondary_inventories   msiin
      , mtl_system_items_b          msibp
      , mtl_system_items_b          msibc
      , fnd_lookup_values           flv
      , ic_item_mst_b               iimbp
      , xxcmn_item_mst_b            ximbp
      , ic_item_mst_b               iimbc
      , xxcmn_item_mst_b            ximbc
      , mtl_category_sets           mcs
      , mtl_item_categories         mic
      , mtl_categories              mc
WHERE   xlt.inside_warehouse_code   =   msiin.secondary_inventory_name
AND     xlt.parent_item_id          =   msibp.inventory_item_id
AND     xlt.child_item_id           =   msibc.inventory_item_id
AND     msibp.organization_id       =   xxcoi_common_pkg.get_organization_id( fnd_profile.value( 'XXCOI1_ORGANIZATION_CODE' ) )
AND     msibc.organization_id       =   xxcoi_common_pkg.get_organization_id( fnd_profile.value( 'XXCOI1_ORGANIZATION_CODE' ) )
AND     msibp.segment1              =   iimbp.item_no
AND     iimbp.item_id               =   ximbp.item_id
AND     SYSDATE BETWEEN ximbp.start_date_active AND ximbp.end_date_active
AND     msibc.segment1              =   iimbc.item_no
AND     iimbc.item_id               =   ximbc.item_id
AND     SYSDATE BETWEEN ximbc.start_date_active AND ximbc.end_date_active
AND     msibp.inventory_item_id     =   mic.inventory_item_id
AND     msibp.organization_id       =   mic.organization_id
AND     mcs.category_set_name       =   '�{�Џ��i�敪'
AND     mcs.category_set_id         =   mic.category_set_id
AND     mic.category_id             =   mc.category_id
AND     flv.lookup_type             =   'XXCOI1_TRANSACTION_TYPE_NAME'
AND     flv.language                =   USERENV( 'LANG' )
AND     flv.lookup_code             =   xlt.transaction_type_code
--  ���������i�`�[���t�j
AND     xlt.transaction_date        >=  TRUNC(SYSDATE)
order by xlt.transaction_date , mc.description , msibp.segment1 , msibc.segment1 , xlt.location_code , xlt.inside_warehouse_code
;

--Prompt
--Prompt ********************************************************************************
--Prompt ********************* END ******************************************************
--Prompt ********************************************************************************
--Prompt

exit;
