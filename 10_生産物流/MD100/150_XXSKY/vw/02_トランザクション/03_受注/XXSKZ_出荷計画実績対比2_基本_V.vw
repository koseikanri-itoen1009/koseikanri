/*************************************************************************
 * 
 * View  Name      : XXSKZ_�o�׌v����ёΔ�2_��{_V
 * Description     : XXSKZ_�o�׌v����ёΔ�2_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V
(
 ����
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i��
,�i�ږ�
,�i�ڗ���
,���_
,���_��
--2009.02.16 Add->
,�o�׌��ۊǏꏊ
,�o�׌��ۊǏꏊ��
--2009.02.16 Add<-
,����v�搔
,�o�ח\�萔
,�o�׎��ѐ�
,���ِ�
,���旦
)
AS
SELECT  SMSP.arrival_date            arrival_date     --����
       ,PRODC.prod_class_code        prod_class_code  --���i�敪
       ,PRODC.prod_class_name        prod_class_name  --���i�敪��
       ,ITEMC.item_class_code        item_class_code  --�i�ڋ敪
       ,ITEMC.item_class_name        item_class_name  --�i�ڋ敪��
       ,CROWD.crowd_code             crowd_code       --�Q�R�[�h
       ,SMSP.item_code               item_code        --�o�וi��
       ,ITEM.item_name               item_name        --�o�וi�ږ�
       ,ITEM.item_short_name         item_s_name      --�o�וi�ڗ���
       ,SMSP.branch                  branch           --���_
       ,CSACT.party_name             branch_name      --���_��
--2009.02.16 Add->
       ,SMSP.deliver_from            deliver_from     --�o�׌��ۊǏꏊ
       ,XIL2V.DESCRIPTION            deliver_name     --�o�׌��ۊǏꏊ��
--2009.02.16 Add<-
       ,NVL( SMSP.forecast_qty, 0 )  forecast_qty     --����v�搔
       ,NVL( SMSP.request_qty , 0 )  request_qty      --�o�ח\�萔
       ,NVL( SMSP.shipped_qty , 0 )  shipped_qty      --�o�׎��ѐ�
       ,NVL( SMSP.forecast_qty, 0 ) - NVL( SMSP.shipped_qty , 0 )
                                     deff_qty         --���ِ�
       ,CASE WHEN ( NVL( SMSP.forecast_qty, 0 ) = 0 ) THEN
                 0    --0���΍�
             ELSE  -- ���旦 = ( �o�׎��ѐ� / ����v�搔 ) * 100   �ˏ����_��R�ʈȉ��l�̌ܓ�
                 ROUND( ( ( NVL( SMSP.shipped_qty , 0 ) / SMSP.forecast_qty ) * 100 ), 2 )
        END                          forecast_rate    --���旦
  FROM  ( --�o�׃f�[�^�{����v��f�[�^���W�v
          SELECT  SHIP.arrival_date                         --����
                 ,SHIP.item_code                            --�o�וi�ڃR�[�h
                 ,SHIP.branch                               --�Ǌ����_�R�[�h
--2009.02.16 Add->
                 ,SHIP.deliver_from                         --�o�׌��ۊǏꏊ
--2009.02.16 Add<-
                 ,SUM( SHIP.forecast_qty )    forecast_qty  --����v�搔
                 ,SUM( SHIP.request_qty  )    request_qty   --�o�ח\�萔
                 ,SUM( SHIP.shipped_qty  )    shipped_qty   --�o�׎��ѐ�
            FROM  (  --�W�v���f�[�^�i�󒍃e�[�u���̃��R�[�h�P�ʁj
                     -------------------------------------------------
                     -- �o�׃f�[�^�i�\��j
                     -------------------------------------------------
                     SELECT  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )
                                                               arrival_date      --����(�����\���)
                            ,XOLA.shipping_item_code           item_code         --�o�וi�ڃR�[�h
                            ,XOHA.head_sales_branch            branch            --���_�R�[�h(�Ǌ����_)
--2009.02.16 Add->
                            ,XOHA.deliver_from                 deliver_from      --�o�׌��ۊǏꏊ
--2009.02.16 Add<-
                            ,0                                 forecast_qty      --����v�搔
                            ,XOLA.quantity                     request_qty       --�o�ח\�萔�i�w�����j
                            ,0                                 shipped_qty       --�o�׎��ѐ�
                       FROM  xxcmn_order_headers_all_arc           XOHA              --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                            ,xxcmn_order_lines_all_arc             XOLA              --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                            ,oe_transaction_types_all          OTTA              --�󒍃^�C�v
                      WHERE  XOHA.order_type_id                = OTTA.transaction_type_id
                        AND  OTTA.attribute1                   = '1'             --'1:�o��'
                        AND  OTTA.attribute4                   = '1'             --'1:�ʏ�o��'(���{�A�p��������)
                        AND  OTTA.order_category_code          = 'ORDER'
                        AND  XOHA.req_status                   = '03'            --'03:���ߍς�'
                        AND  XOHA.latest_external_flag         = 'Y'             --�ŐV�t���O�L��
                        AND  NVL( XOLA.delete_flag, 'N' )     <> 'Y'             --�������׈ȊO
                        AND  XOLA.quantity                    <> 0
                        AND  XOHA.order_header_id              = XOLA.order_header_id
                   UNION ALL
                     -------------------------------------------------
                     -- �o�׃f�[�^�i���сj
                     -------------------------------------------------
                     SELECT  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )
                                                               arrival_date      --����(�����\���)
                            ,XOLA.shipping_item_code           item_code         --�o�וi�ڃR�[�h
                            ,XOHA.head_sales_branch            branch            --���_�R�[�h(�Ǌ����_)
--2009.02.16 Add->
                            ,XOHA.deliver_from                 deliver_from      --�o�׌��ۊǏꏊ
--2009.02.16 Add<-
                            ,0                                 forecast_qty      --����v�搔
                            ,0                                 request_qty       --�o�ח\�萔
                            ,XOLA.shipped_quantity             shipped_qty       --�o�׎��ѐ�
                       FROM  xxcmn_order_headers_all_arc           XOHA              --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                            ,xxcmn_order_lines_all_arc             XOLA              --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                            ,oe_transaction_types_all          OTTA              --�󒍃^�C�v
                      WHERE  XOHA.order_type_id                = OTTA.transaction_type_id
                        AND  OTTA.attribute1                   = '1'             --'1:�o��'
                        AND  OTTA.attribute4                   = '1'             --'1:�ʏ�o��'(���{�A�p��������)
                        AND  OTTA.order_category_code          = 'ORDER'
                        AND  XOHA.req_status                   = '04'            --'04:���ьv���'
                        AND  XOHA.latest_external_flag         = 'Y'             --�ŐV�t���O�L��
                        AND  NVL( XOLA.delete_flag, 'N' )     <> 'Y'             --�������׈ȊO
                        AND  XOLA.shipped_quantity            <> 0
                        AND  XOHA.order_header_id              = XOLA.order_header_id
                   UNION ALL
                     -------------------------------------------------
                     -- ����v��f�[�^
                     -------------------------------------------------
                     SELECT  MFDT.forecast_date                arrival_date      --����(�v���)
                            ,XIMV.item_no                      item_code         --�o�וi�ڃR�[�h
                            ,MFDN.attribute3                   branch            --���_�R�[�h
--2009.02.16 Add->
                            ,MFDN.attribute2                   deliver_from      --�o�׌��ۊǏꏊ
--2009.02.16 Add<-
                            ,MFDT.original_forecast_quantity   forecast_qty      --����v�搔(�\����������)
                            ,0                                 request_qty       --�o�ח\�萔
                            ,0                                 shipped_qty       --�o�׎��ѐ�
                       FROM  mrp_forecast_designators          MFDN              --�t�H�[�L���X�g���e�[�u��
                            ,mrp_forecast_dates                MFDT              --�t�H�[�L���X�g���t�e�[�u��
                            ,xxskz_item_mst2_v                 XIMV              --�i�ڏ��擾�p
                      WHERE  MFDN.attribute1                   = '01'            --����v��
                        AND  MFDN.organization_id              = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
                        AND  MFDT.original_forecast_quantity  <> 0
                        AND  MFDN.forecast_designator          = MFDT.forecast_designator
                        AND  MFDN.organization_id              = MFDT.organization_id
                        AND  MFDT.inventory_item_id            = XIMV.inventory_item_id(+)
                        AND  MFDT.forecast_date               >= XIMV.start_date_active(+)
                        AND  MFDT.forecast_date               <= XIMV.end_date_active(+)
                  )    SHIP
          GROUP BY  SHIP.arrival_date
                   ,SHIP.item_code
                   ,SHIP.branch
--2009.02.16 Add->
                   ,SHIP.deliver_from
--2009.02.16 Add<-
        )                         SMSP
        --�ȉ��͏�LSQL�����̍��ڂ��g�p���ĊO���������s������(�G���[�����)
       ,xxskz_item_mst2_v         ITEM
       ,xxskz_prod_class_v        PRODC
       ,xxskz_item_class_v        ITEMC
       ,xxskz_crowd_code_v        CROWD
       ,xxskz_cust_accounts2_v    CSACT
--2009.02.16 Add->
       ,xxskz_item_locations2_v   XIL2V
--2009.02.16 Add<-
 WHERE
   --�i�ڏ��擾����
        SMSP.item_code    =  ITEM.item_no(+)
   AND  SMSP.arrival_date >= ITEM.start_date_active(+)
   AND  SMSP.arrival_date <= ITEM.end_date_active(+)
   --�i�ڂ̃J�e�S�����擾����
   AND  ITEM.item_id = PRODC.item_id(+)    --���i�敪
   AND  ITEM.item_id = ITEMC.item_id(+)    --�i�ڋ敪
   AND  ITEM.item_id = CROWD.item_id(+)    --�Q�R�[�h
   --���_���擾����
   AND  SMSP.branch       =  CSACT.party_number(+)
   AND  SMSP.arrival_date >= CSACT.start_date_active(+)
   AND  SMSP.arrival_date <= CSACT.end_date_active(+)
--2009.02.16 Add->
   --�o�׌��ۊǏꏊ���擾
   AND  SMSP.deliver_from = XIL2V.segment1(+)
--2009.02.16 Add<-
/
COMMENT ON TABLE APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V IS 'SKYLINK�p XXSKZ_�o�׌v����ёΔ�2�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.���� IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.�i�� IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.�i�ږ� IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.���_ IS '���_'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.���_�� IS '���_��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.�o�׌��ۊǏꏊ IS '�o�׌��ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.�o�׌��ۊǏꏊ�� IS '�o�׌��ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.����v�搔 IS '����v�搔'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.�o�ח\�萔 IS '�o�ח\�萔'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.�o�׎��ѐ� IS '�o�׎��ѐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.���ِ� IS '���ِ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׌v����ёΔ�2_��{_V.���旦 IS '���旦'
/
