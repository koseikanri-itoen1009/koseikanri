/*************************************************************************
 * 
 * View  Name      : XXSKZ_�o�ז���_��{_V
 * Description     : XXSKZ_�o�ז���_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�o�ז���_��{_V
(
 �˗�NO
,���הԍ�
,���R�[�h�^�C�v
,���R�[�h�^�C�v��
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�o�וi��
,�o�וi�ږ�
,�o�וi�ڗ���
,���b�gNO
,�����N����
,�ŗL�L��
,�ܖ�����
,�폜�t���O
,����
,�P��
,�o�׎��ѐ���
,�w�萻����
,���_�˗�����
,�˗��i��
,�˗��i�ږ�
,�˗��i�ڗ���
,�w����t_���[�t
,�ړ�NO
,����NO
,�ڋq����
,�p���b�g��
,�i��
,�P�[�X��
,�d��
,�e��
,�p���b�g����
,�p���b�g�d��
,������
,�x���敪
,�x���敪��
,�x�����t
,�E�v
,�o�׈˗��C���^�t�F�[�X�σt���O
,�o�׎��уC���^�t�F�[�X�σt���O
,���ѓ�
,���ѐ���
,�����O���ѐ���
,�����蓮�����敪
,�����蓮�����敪��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  XOLL.request_no                 request_no                 --�˗�No
       ,XOLL.order_line_number          order_line_number          --���הԍ�
       ,XOLL.record_type_code           record_type_code           --���R�[�h�^�C�v
       ,FLV01.meaning                   record_type_name           --���R�[�h�^�C�v��
       ,PRODC.prod_class_code           prod_class_code            --���i�敪
       ,PRODC.prod_class_name           prod_class_name            --���i�敪��
       ,ITEMC.item_class_code           item_class_code            --�i�ڋ敪
       ,ITEMC.item_class_name           item_class_name            --�i�ڋ敪��
       ,CROWD.crowd_code                crowd_code                 --�Q�R�[�h
       ,XOLL.shipping_item_code         shipping_item_code         --�o�וi��
       ,ITEM1.item_name                 shipping_item_name         --�o�וi�ږ�
       ,ITEM1.item_short_name           shipping_item_s_name       --�o�וi�ڗ���
       ,NVL( DECODE( XOLL.lot_no, 'DEFAULTLOT', '0', XOLL.lot_no ), '0' )
                                        lot_no                     --���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN XOLL.lot_date       --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                       --�񃍃b�g�Ǘ��i ��NULL
        END                             lot_date                   --�����N����
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN XOLL.lot_sign       --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                       --�񃍃b�g�Ǘ��i ��NULL
        END                             lot_sign                   --�ŗL�L��
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN XOLL.best_bfr_date  --���b�g�Ǘ��i   ���ܖ��������擾
             ELSE NULL                                       --�񃍃b�g�Ǘ��i ��NULL
        END                             best_bfr_date              --�ܖ�����
       ,XOLL.delete_flag                delete_flag                --�폜�t���O
       ,XOLL.quantity                   quantity                   --����
       ,XOLL.uom_code                   uom_code                   --�P��
       ,XOLL.shipped_quantity           shipped_quantity           --�o�׎��ѐ���
       ,XOLL.designated_production_date designated_production_date --�w�萻����
       ,XOLL.based_request_quantity     based_request_quantity     --���_�˗�����
       ,XOLL.request_item_code          request_item_code          --�˗��i��
       ,ITEM2.item_name                 request_item_name          --�˗��i�ږ�
       ,ITEM2.item_short_name           request_item_s_name        --�˗��i�ڗ���
       ,XOLL.designated_date            designated_date            --�w����t_���[�t
       ,XOLL.move_number                move_number                --�ړ�No
       ,XOLL.po_number                  po_number                  --����No
       ,XOLL.cust_po_number             cust_po_number             --�ڋq����
       ,XOLL.pallet_quantity            pallet_quantity            --�p���b�g��
       ,XOLL.layer_quantity             layer_quantity             --�i��
       ,XOLL.case_quantity              case_quantity              --�P�[�X��
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL(XOLL.weight)               weight                     --�d��(�����_�ȉ��؏グ)
       ,CEIL(TRUNC(NVL(XOLL.weight,0),1))
                                        weight                     --�d��(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/7 #627 Y.Fukami Mod End
       ,CEIL(XOLL.capacity)             capacity                   --�e��(�����_�ȉ��؏グ)
       ,XOLL.pallet_qty                 pallet_qty                 --�p���b�g����
       ,CEIL(XOLL.pallet_weight)        pallet_weight              --�p���b�g�d��(�����_�ȉ��؏グ)
       ,XOLL.reserved_quantity          reserved_quantity          --������
       ,XOLL.warning_class              warning_class              --�x���敪
       ,FLV02.meaning                   warning_c_name             --�x���敪��
       ,XOLL.warning_date               warning_date               --�x�����t
       ,XOLL.line_description           line_description           --�E�v
       ,XOLL.shipping_request_if_flg    shipping_request_if_flg    --�o�׈˗��C���^�t�F�[�X�σt���O
       ,XOLL.shipping_result_if_flg     shipping_result_if_flg     --�o�׎��уC���^�t�F�[�X�σt���O
       ,XOLL.actual_date                actual_date                --���ѓ�
       ,XOLL.actual_quantity            actual_quantity            --���ѐ���
       ,XOLL.before_actual_quantity     before_actual_quantity     --�����O���ѐ���
       ,XOLL.automanual_reserve_class   automanual_reserve_class   --�����蓮�����敪
       ,FLV03.meaning                   automanual_reserve_c_name  --�����蓮�����敪��
       ,FU_CB.user_name                 created_by_name            --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XOLL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        creation_date              --�쐬����
       ,FU_LU.user_name                 last_updated_by_name       --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XOLL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        last_update_date           --�X�V����
       ,FU_LL.user_name                 last_update_login_name     --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  ( --���̎擾�n�ȊO�̃f�[�^�͂��̓���SQL�őS�Ď擾����
          SELECT XOLA.request_no                                   --�˗�No
                ,XOLA.order_line_number                            --���הԍ�
                ,XMLD.record_type_code                             --���R�[�h�^�C�v
                ,XOLA.shipping_item_code                           --�o�וi�ڃR�[�h
                ,XMLD.lot_no                                       --���b�gNo
                ,ILTM.attribute1           lot_date                --�����N����
                ,ILTM.attribute2           lot_sign                --�ŗL�L��
                ,ILTM.attribute3           best_bfr_date           --�ܖ�����
                ,XOLA.delete_flag                                  --�폜�t���O
                ,XOLA.quantity                                     --����
                ,XOLA.uom_code                                     --�P��
                ,XOLA.shipped_quantity                             --�o�׎��ѐ���
                ,XOLA.designated_production_date                   --�w�萻����
                ,XOLA.based_request_quantity                       --���_�˗�����
                ,XOLA.request_item_code                            --�˗��i�ڃR�[�h
                ,XOLA.designated_date                              --�w����t_���[�t
                ,XOLA.move_number                                  --�ړ�No
                ,XOLA.po_number                                    --����No
                ,XOLA.cust_po_number                               --�ڋq����
                ,XOLA.pallet_quantity                              --�p���b�g��
                ,XOLA.layer_quantity                               --�i��
                ,XOLA.case_quantity                                --�P�[�X��
                ,XOLA.weight                                       --�d��
                ,XOLA.capacity                                     --�e��
                ,XOLA.pallet_qty                                   --�p���b�g����
                ,XOLA.pallet_weight                                --�p���b�g�d��
                ,XOLA.reserved_quantity                            --������
                ,XOLA.warning_class                                --�x���敪
                ,XOLA.warning_date                                 --�x�����t
                ,XOLA.line_description                             --�E�v
                ,XOLA.shipping_request_if_flg                      --�o�׈˗��C���^�t�F�[�X�σt���O
                ,XOLA.shipping_result_if_flg                       --�o�׎��уC���^�t�F�[�X�σt���O
                ,XMLD.actual_date                                  --���ѓ�
                ,XMLD.actual_quantity                              --���ѐ���
                ,XMLD.before_actual_quantity                       --�����O���ѐ���
                ,XMLD.automanual_reserve_class                     --�����蓮�����敪
                ,XMLD.created_by                                   --�쐬��
                ,XMLD.creation_date                                --�쐬��
                ,XMLD.last_updated_by                              --�ŏI�X�V��
                ,XMLD.last_update_date                             --�ŏI�X�V��
                ,XMLD.last_update_login                            --�ŏI�X�V���O�C��
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )    --NVL( ���ד�, ���ח\��� )
                                                  arrival_date     --���ד� (�˕i�ږ��̎擾�Ŏg�p)
          FROM   xxcmn_order_headers_all_arc   XOHA  --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                ,xxcmn_order_lines_all_arc     XOLA  --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                ,oe_transaction_types_all  OTTA
                ,xxcmn_mov_lot_details_arc     XMLD  --�ړ����b�g�ڍׁi�A�h�I���j�o�b�N�A�b�v
                ,ic_lots_mst               ILTM                    --���b�g���擾�p
          WHERE  XOHA.order_header_id = XOLA.order_header_id
          AND    XOHA.order_type_id = OTTA.transaction_type_id
          AND    XOHA.latest_external_flag = 'Y'
          AND    NVL(XOLA.delete_flag, 'N') <> 'Y'
          AND    OTTA.attribute1 = '1'                             --1:�o��
          AND    XMLD.document_type_code(+) = '10'                 --10:�o�׈˗�
          AND    XOLA.order_line_id = XMLD.mov_line_id(+)
          AND    XMLD.item_id = ILTM.item_id(+)
          AND    XMLD.lot_id = ILTM.lot_id(+)
        )                     XOLL     --���ׁ�LOT�ڍ׏��
        --�ȉ��͏�LSQL�����̍��ڂ��g�p���ĊO���������s������(�G���[�����)
       ,xxskz_item_mst2_v     ITEM1    --�o�וi�ږ��̎擾�p
       ,xxskz_item_mst2_v     ITEM2    --�˗��i�ږ��̎擾�p
       ,xxskz_prod_class_v    PRODC    --���i�敪�擾�p
       ,xxskz_item_class_v    ITEMC    --�i�ڋ敪�擾�p
       ,xxskz_crowd_code_v    CROWD    --�Q�R�[�h�擾�p
       ,fnd_lookup_values     FLV01    --���R�[�h�^�C�v���擾�p
       ,fnd_lookup_values     FLV02    --�x���敪���擾�p
       ,fnd_lookup_values     FLV03    --�����蓮�����敪���擾�p
       ,fnd_user              FU_CB    --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user              FU_LU    --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user              FU_LL    --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins            FL_LL    --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
   --�o�וi�ڏ��擾����
        XOLL.shipping_item_code =  ITEM1.item_no(+)
   AND  XOLL.arrival_date       >= ITEM1.start_date_active(+)
   AND  XOLL.arrival_date       <= ITEM1.end_date_active(+)
   --�o�וi�ڂ̃J�e�S�����擾����
   AND  ITEM1.item_id = PRODC.item_id(+)    --���i�敪
   AND  ITEM1.item_id = ITEMC.item_id(+)    --�i�ڋ敪
   AND  ITEM1.item_id = CROWD.item_id(+)    --�Q�R�[�h
   --�˗��i�ڏ��擾����
   AND  XOLL.request_item_code =  ITEM2.item_no(+)
   AND  XOLL.arrival_date      >= ITEM2.start_date_active(+)
   AND  XOLL.arrival_date      <= ITEM2.end_date_active(+)
   --���R�[�h�^�C�v���擾����
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXINV_RECORD_TYPE'
   AND  FLV01.lookup_code(+) = XOLL.record_type_code
   --�x���敪���擾����
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXWSH_WARNING_CLASS'
   AND  FLV02.lookup_code(+) = XOLL.warning_class
   --�����蓮�����敪���擾����
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV03.lookup_code(+) = XOLL.automanual_reserve_class
   --WHO�J�����擾
   AND  XOLL.created_by        = FU_CB.user_id(+)
   AND  XOLL.last_updated_by   = FU_LU.user_id(+)
   AND  XOLL.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�o�ז���_��{_V IS 'SKYLINK�p�o�ז��׊�{VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�˗�NO IS '�˗�No'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.���הԍ� IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.���R�[�h�^�C�v IS '���R�[�h�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.���R�[�h�^�C�v�� IS '���R�[�h�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�o�וi�� IS '�o�וi��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�o�וi�ږ� IS '�o�וi�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�o�וi�ڗ��� IS '�o�וi�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.���b�gNO IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�����N���� IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�ŗL�L�� IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�ܖ����� IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�폜�t���O IS '�폜�t���O'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.���� IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�P�� IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�o�׎��ѐ��� IS '�o�׎��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�w�萻���� IS '�w�萻����'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.���_�˗����� IS '���_�˗�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�˗��i�� IS '�˗��i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�˗��i�ږ� IS '�˗��i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�˗��i�ڗ��� IS '�˗��i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�w����t_���[�t IS '�w����t_���[�t'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�ړ�NO IS '�ړ�No'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.����NO IS '����No'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�ڋq���� IS '�ڋq����'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�p���b�g�� IS '�p���b�g��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�i�� IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�P�[�X�� IS '�P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�d�� IS '�d��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�e�� IS '�e��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�p���b�g���� IS '�p���b�g����'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�p���b�g�d�� IS '�p���b�g�d��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�x���敪 IS '�x���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�x���敪�� IS '�x���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�x�����t IS '�x�����t'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�E�v IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�o�׈˗��C���^�t�F�[�X�σt���O IS '�o�׈˗��C���^�t�F�[�X�σt���O'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�o�׎��уC���^�t�F�[�X�σt���O IS '�o�׎��уC���^�t�F�[�X�σt���O'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.���ѓ� IS '���ѓ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.���ѐ��� IS '���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�����O���ѐ��� IS '�����O���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�����蓮�����敪 IS '�����蓮�����敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�����蓮�����敪�� IS '�����蓮�����敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�ז���_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
