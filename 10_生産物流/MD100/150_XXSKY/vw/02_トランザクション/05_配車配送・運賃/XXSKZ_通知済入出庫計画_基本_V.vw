/*************************************************************************
 * 
 * View  Name      : XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V
 * Description     : XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V
(
 ��Ж�
,�˗�No
,�z��No
,�f�[�^���
,�f�[�^��ʖ�
,�f�[�^�敪
,�f�[�^�敪��
,�f�[�^�^�C�v
,�f�[�^�^�C�v��
,�m��ʒm���{����
,�X�V����
,EOS����_�o�ɑq��
,EOS����_�o�ɑq�ɖ�
,EOS����_�^���Ǝ�
,EOS����_�^���ƎҖ�
,EOS����_CSV�o��
,EOS����_CSV�o�͖�
,�`���p�}��
,�`���p�}�Ԗ�
,�\��
,�Ǌ����_�R�[�h
,�Ǌ����_����
,�o�ɑq�ɃR�[�h
,�o�ɑq�ɖ���
,���ɑq�ɃR�[�h
,���ɑq�ɖ���
,�^���Ǝ҃R�[�h
,�^���ƎҖ�
,�z����R�[�h
,�z���於
,����
,����
,�z���敪
,�z���敪��
,�˗�NO�P��_�d�ʗe��
,���ڌ��˗�No
,�p���b�g�������
,���׎��Ԏw��FROM
,���׎��Ԏw��FROM��
,���׎��Ԏw��TO
,���׎��Ԏw��TO��
,�ڋq�����ԍ�
,�E�v
,�X�e�[�^�X
,�X�e�[�^�X��
,�^���敪
,�^���敪��
,�p���b�g�g�p����
,�񍐕����R�[�h
,�񍐕�����
,�\���P
,�\���Q
,�\���R
,�\���S
,���הԍ�
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ���
,�i�ڗ���
,�i�ڒP��
,�i�ڐ���
,���b�g�ԍ�
,������
,�ܖ�����
,�ŗL�L��
,���b�g����
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XNDI.corporation_name           corporation_name              --��Ж�
       ,XNDI.request_no                 request_no                    --�˗�No
       ,XNDI.delivery_no                delivery_no                   --�z��No
       ,XNDI.data_class                 data_class                    --�f�[�^���
       ,FLV01.meaning                   data_class_name               --�f�[�^��ʖ�
       ,XNDI.new_modify_del_class       new_modify_del_class          --�f�[�^�敪
       ,CASE WHEN XNDI.new_modify_del_class = '0' THEN '�ǉ�'
             WHEN XNDI.new_modify_del_class = '1' THEN '����'
             WHEN XNDI.new_modify_del_class = '2' THEN '�폜'
             ELSE                                      NULL
        END                             new_modify_del_class_name     --�f�[�^�敪��
       ,XNDI.data_type                  data_type                     --�f�[�^�^�C�v
       ,FLV02.meaning                   data_type_name                --�f�[�^�^�C�v��
       ,TO_CHAR( XNDI.notif_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        notif_date                    --�m��ʒm���{����
       ,TO_CHAR( XNDI.update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        update_date                   --�X�V����
       ,XNDI.eos_shipped_locat          eos_shipped_locat             --EOS����_�o�ɑq��
       ,XILV.description                eos_shipped_locat_name        --EOS����_�o�ɑq�ɖ�
       ,XNDI.eos_freight_carrier        eos_freight_carrier           --EOS����_�^���Ǝ�
       ,XCAR.party_name                 eos_freight_carrier_name      --EOS����_�^���ƎҖ�
       ,XNDI.eos_csv_output             eos_csv_output                --EOS����_CSV�o��
       ,CASE WHEN XNDI.eos_csv_output = XNDI.eos_shipped_locat   THEN XILV.description
             WHEN XNDI.eos_csv_output = XNDI.eos_freight_carrier THEN XCAR.party_name
             ELSE                                                     NULL
        END                             eos_csv_output_name           --EOS����_CSV�o�͖�
       ,XNDI.transfer_branch_no         transfer_branch_no            --�`���p�}��
       ,CASE WHEN XNDI.transfer_branch_no = '10' THEN '�w�b�_'
             WHEN XNDI.transfer_branch_no = '20' THEN '����'
             ELSE                                     NULL
        END                             transfer_branch_name          --�`���p�}�Ԗ�
        --�ȉ��A�`���p�}��:10(�w�b�_)���ɕ\������鍀��
       ,XNDI.reserve                    reserve                       --�\��
       ,XNDI.head_sales_branch          head_sales_branch             --�Ǌ����_�R�[�h
       ,XNDI.head_sales_branch_name     head_sales_branch_name        --�Ǌ����_����
       ,XNDI.shipped_locat_code         shipped_locat_code            --�o�ɑq�ɃR�[�h
       ,XNDI.shipped_locat_name         shipped_locat_name            --�o�ɑq�ɖ���
       ,XNDI.ship_to_locat_code         ship_to_locat_code            --���ɑq�ɃR�[�h
       ,XNDI.ship_to_locat_name         ship_to_locat_name            --���ɑq�ɖ���
       ,XNDI.freight_carrier_code       freight_carrier_code          --�^���Ǝ҃R�[�h
       ,XNDI.freight_carrier_name       freight_carrier_name          --�^���ƎҖ�
       ,XNDI.deliver_to                 deliver_to                    --�z����R�[�h
       ,XNDI.deliver_to_name            deliver_to_name               --�z���於
       ,XNDI.schedule_ship_date         schedule_ship_date            --����
       ,XNDI.schedule_arrival_date      schedule_arrival_date         --����
       ,XNDI.shipping_method_code       shipping_method_code          --�z���敪
       ,FLV03.meaning                   shipping_method_name          --�z���敪��
-- 2010/1/8 #627 Y.Fukami Mod Start
--       ,CEIL( XNDI.weight )             weight                        --�˗�NO�P��_�d�ʗe��
       ,CEIL( TRUNC(NVL(XNDI.weight,0),1) )
                                        weight                        --�˗�NO�P��_�d�ʗe��(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
       ,XNDI.mixed_no                   mixed_no                      --���ڌ��˗�No
       ,XNDI.collected_pallet_qty       collected_pallet_qty          --�p���b�g�������
       ,XNDI.arrival_time_from          arrival_time_from             --���׎��Ԏw��FROM
       ,FLV04.meaning                   arrival_time_from_name        --���׎��Ԏw��FROM��
       ,XNDI.arrival_time_to            arrival_time_to               --���׎��Ԏw��TO
       ,FLV05.meaning                   arrival_time_to_name          --���׎��Ԏw��TO��
       ,XNDI.cust_po_number             cust_po_number                --�ڋq�����ԍ�
       ,XNDI.description                description                   --�E�v
       ,XNDI.status                     status                        --�X�e�[�^�X
       ,CASE WHEN XNDI.status = '01' THEN '�\��'
             WHEN XNDI.status = '02' THEN '�m��'
             ELSE                         NULL
        END                             status_name                   --�X�e�[�^�X��
       ,XNDI.freight_charge_class       freight_charge_class          --�^���敪
       ,FLV06.meaning                   freight_charge_clase_name     --�^���敪��
       ,XNDI.pallet_sum_quantity        pallet_sum_quantity           --�p���b�g�g�p����
       ,XNDI.report_dept                report_dept                   --�񍐕����R�[�h
       ,XLOCT.location_name             report_dept_name              --�񍐕�����
       ,XNDI.reserve1                   reserve1                      --�\���P
       ,XNDI.reserve2                   reserve2                      --�\���Q
       ,XNDI.reserve3                   reserve3                      --�\���R
       ,XNDI.reserve4                   reserve4                      --�\���S
        --�ȉ��A�`���p�}��:20(����)���ɕ\������鍀��
       ,XNDI.line_number                line_number                   --���הԍ�
       ,XPRODC.prod_class_code          prod_class_code               --���i�敪
       ,XPRODC.prod_class_name          prod_class_name               --���i�敪��
       ,XITEMC.item_class_code          item_class_code               --�i�ڋ敪
       ,XITEMC.item_class_name          item_class_name               --�i�ڋ敪��
       ,XCRWDC.crowd_code               crowd_cod                     --�Q�R�[�h
       ,XNDI.item_code                  item_code                     --�i�ڃR�[�h
       ,XITEM.item_name                 item_name                     --�i�ږ���
       ,XITEM.item_short_name           item_short_name               --�i�ڗ���
       ,XNDI.item_uom_code              item_uom_code                 --�i�ڒP��
       ,XNDI.item_quantity              item_quantity                 --�i�ڐ���
       ,XNDI.lot_no                     lot_no                        --���b�g�ԍ�
       ,XNDI.lot_date                   lot_date                      --������
       ,XNDI.best_bfr_date              best_bfr_date                 --�ܖ�����
       ,XNDI.lot_sign                   lot_sign                      --�ŗL�L��
       ,XNDI.lot_quantity               lot_quantity                  --���b�g����
        --WHO�J�������
       ,FU_CB.user_name                 created_by                    --�쐬��
       ,TO_CHAR( XNDI.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        creation_date                 --�쐬��
       ,FU_LU.user_name                 last_updated_by               --�ŏI�X�V��
       ,TO_CHAR( XNDI.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        last_update_date              --�ŏI�X�V��
       ,FU_LL.user_name                 last_update_login             --�ŏI�X�V���O�C��
  FROM
        xxwsh_notif_delivery_info       XNDI                          --�ʒm�ϓ��o�ɔz���v����A�h�I��
       ,xxskz_item_locations_v          XILV                          --EOS����_�o�ɑq�ɖ��擾�p
       ,xxskz_carriers2_v               XCAR                          --EOS����_�^���ƎҖ��擾�p
       ,xxskz_locations2_v              XLOCT                         --�񍐕������擾�p
       ,xxskz_item_mst2_v               XITEM                         --�i�ڏ��擾�p
       ,xxskz_prod_class_v              XPRODC                        --���i�敪�擾�p
       ,xxskz_item_class_v              XITEMC                        --�i�ڋ敪�擾�p
       ,xxskz_crowd_code_v              XCRWDC                        --�Q�R�[�h�擾�p
       ,fnd_lookup_values               FLV01                         --�N�C�b�N�R�[�h(�f�[�^��ʖ�)
       ,fnd_lookup_values               FLV02                         --�N�C�b�N�R�[�h(�f�[�^�^�C�v��)
       ,fnd_lookup_values               FLV03                         --�N�C�b�N�R�[�h(�z���敪��)
       ,fnd_lookup_values               FLV04                         --�N�C�b�N�R�[�h(���׎���FROM��)
       ,fnd_lookup_values               FLV05                         --�N�C�b�N�R�[�h(���׎���TO��)
       ,fnd_lookup_values               FLV06                         --�N�C�b�N�R�[�h(�^���敪��)
       ,fnd_user                        FU_CB                         --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                        FU_LU                         --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                        FU_LL                         --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                      FL_LL                         --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
   --EOS����_�o�ɑq�ɖ��擾
        XNDI.eos_shipped_locat          = XILV.segment1(+)
   --EOS����_�^���ƎҖ��擾
   AND  XNDI.eos_freight_carrier        = XCAR.freight_code(+)
   AND  XNDI.notif_date                >= XCAR.start_date_active(+)
   AND  XNDI.notif_date                <= XCAR.end_date_active(+)
   --�񍐕������擾
   AND  XNDI.report_dept                = XLOCT.location_code(+)
   AND  XNDI.notif_date                >= XLOCT.start_date_active(+)
   AND  XNDI.notif_date                <= XLOCT.end_date_active(+)
   --�i�ڏ��擾
   AND  XNDI.item_code                  = XITEM.item_no(+)
   AND  XNDI.notif_date                >= XITEM.start_date_active(+)
   AND  XNDI.notif_date                <= XITEM.end_date_active(+)
   --�i�ڃJ�e�S�����擾
   AND  XITEM.item_id                   = XPRODC.item_id(+)           --���i�敪
   AND  XITEM.item_id                   = XITEMC.item_id(+)           --�i�ڋ敪
   AND  XITEM.item_id                   = XCRWDC.item_id(+)           --�Q�R�[�h
   --�f�[�^��ʖ��擾�i�N�C�b�N�R�[�h�l�j
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXCMN_D17'
   AND  FLV01.lookup_code(+)            = XNDI.data_class
   --�f�[�^�^�C�v���擾�i�N�C�b�N�R�[�h�l�j
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXWSH_SHIPPING_BIZ_TYPE'
   AND  FLV02.lookup_code(+)            = XNDI.data_type
   --�z���敪���擾�i�N�C�b�N�R�[�h�l�j
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXCMN_SHIP_METHOD'
   AND  FLV03.lookup_code(+)            = XNDI.shipping_method_code
   --���׎���FROM���擾�i�N�C�b�N�R�[�h�l�j
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXWSH_ARRIVAL_TIME'
   AND  FLV04.lookup_code(+)            = XNDI.arrival_time_from
   --���׎���TO���擾�i�N�C�b�N�R�[�h�l�j
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXWSH_ARRIVAL_TIME'
   AND  FLV05.lookup_code(+)            = XNDI.arrival_time_to
   --�^���敪���擾�i�N�C�b�N�R�[�h�l�j
   AND  FLV06.language(+)               = 'JA'
   AND  FLV06.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV06.lookup_code(+)            = XNDI.freight_charge_class
   --WHO�J�������擾
   AND  XNDI.created_by                 = FU_CB.user_id(+)
   AND  XNDI.last_updated_by            = FU_LU.user_id(+)
   AND  XNDI.last_update_login          = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V IS 'SKYLINK�p �ʒm�ϓ��o�Ɍv��i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.��Ж�              IS '��Ж�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�˗�No              IS '�˗�No'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�z��No              IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�f�[�^���          IS '�f�[�^���'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�f�[�^��ʖ�        IS '�f�[�^��ʖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�f�[�^�敪          IS '�f�[�^�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�f�[�^�敪��        IS '�f�[�^�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�f�[�^�^�C�v        IS '�f�[�^�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�f�[�^�^�C�v��      IS '�f�[�^�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�m��ʒm���{����    IS '�m��ʒm���{����'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�X�V����            IS '�X�V����'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.EOS����_�o�ɑq��    IS 'EOS����_�o�ɑq��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.EOS����_�o�ɑq�ɖ�  IS 'EOS����_�o�ɑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.EOS����_�^���Ǝ�    IS 'EOS����_�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.EOS����_�^���ƎҖ�  IS 'EOS����_�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.EOS����_CSV�o��     IS 'EOS����_CSV�o��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.EOS����_CSV�o�͖�   IS 'EOS����_CSV�o�͖�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�`���p�}��          IS '�`���p�}��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�`���p�}�Ԗ�        IS '�`���p�}�Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�\��                IS '�\��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�Ǌ����_�R�[�h      IS '�Ǌ����_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�Ǌ����_����        IS '�Ǌ����_����'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�o�ɑq�ɃR�[�h      IS '�o�ɑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�o�ɑq�ɖ���        IS '�o�ɑq�ɖ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���ɑq�ɃR�[�h      IS '���ɑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���ɑq�ɖ���        IS '���ɑq�ɖ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�^���Ǝ҃R�[�h      IS '�^���Ǝ҃R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�^���ƎҖ�          IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�z����R�[�h        IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�z���於            IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.����                IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.����                IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�z���敪            IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�z���敪��          IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�˗�NO�P��_�d�ʗe�� IS '�˗�NO�P��_�d�ʗe��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���ڌ��˗�No        IS '���ڌ��˗�No'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�p���b�g�������    IS '�p���b�g�������'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���׎��Ԏw��FROM    IS '���׎��Ԏw��FROM'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���׎��Ԏw��FROM��  IS '���׎��Ԏw��FROM��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���׎��Ԏw��TO      IS '���׎��Ԏw��TO'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���׎��Ԏw��TO��    IS '���׎��Ԏw��TO��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�ڋq�����ԍ�        IS '�ڋq�����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�E�v                IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�X�e�[�^�X          IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�X�e�[�^�X��        IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�^���敪            IS '�^���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�^���敪��          IS '�^���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�p���b�g�g�p����    IS '�p���b�g�g�p����'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�񍐕����R�[�h      IS '�񍐕����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�񍐕�����          IS '�񍐕�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�\���P              IS '�\���P'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�\���Q              IS '�\���Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�\���R              IS '�\���R'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�\���S              IS '�\���S'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���הԍ�            IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���i�敪            IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���i�敪��          IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�i�ڋ敪            IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�i�ڋ敪��          IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�Q�R�[�h            IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�i�ڃR�[�h          IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�i�ږ���            IS '�i�ږ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�i�ڗ���            IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�i�ڒP��            IS '�i�ڒP��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�i�ڐ���            IS '�i�ڐ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���b�g�ԍ�          IS '���b�g�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.������              IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�ܖ�����            IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�ŗL�L��            IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.���b�g����          IS '���b�g����'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�쐬��              IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�쐬��              IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�ŏI�X�V��          IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�ŏI�X�V��          IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�ʒm�ϓ��o�Ɍv��_��{_V.�ŏI�X�V���O�C��    IS '�ŏI�X�V���O�C��'
/
