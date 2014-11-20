CREATE OR REPLACE VIEW APPS.XXSKY_�󒍏o�ז���_��{_V
(
 �˗�NO
,���הԍ�
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�o�וi��
,�o�וi�ږ�
,�o�וi�ڗ���
,�˗��i��
,�˗��i�ږ�
,�˗��i�ڗ���
,�폜�t���O
,����
,�P��
,�o�׎��ѐ���
,�w�萻����
,���_�˗�����
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
,�X�e�[�^�X�ʐ���
,�x���敪
,�x���敪��
,�x�����t
,�E�v
,�o�׈˗��C���^�t�F�[�X�σt���O
,�o�׎��уC���^�t�F�[�X�σt���O
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��)
AS
SELECT  XOL.request_no                  request_no                 --�˗�No
       ,XOL.order_line_number           order_line_number          --���הԍ�
       ,PRODC.prod_class_code           prod_class_code            --���i�敪
       ,PRODC.prod_class_name           prod_class_name            --���i�敪��
       ,ITEMC.item_class_code           item_class_code            --�i�ڋ敪
       ,ITEMC.item_class_name           item_class_name            --�i�ڋ敪��
       ,CROWD.crowd_code                crowd_code                 --�Q�R�[�h
       ,XOL.shipping_item_code          shipping_item_code         --�o�וi��
       ,ITEM1.item_name                 shipping_item_name         --�o�וi�ږ�
       ,ITEM1.item_short_name           shipping_item_s_name       --�o�וi�ڗ���
       ,XOL.request_item_code           request_item_code          --�˗��i��
       ,ITEM2.item_name                 request_item_name          --�˗��i�ږ�
       ,ITEM2.item_short_name           request_item_s_name        --�˗��i�ڗ���
       ,XOL.delete_flag                 delete_flag                --�폜�t���O
       ,XOL.quantity                    quantity                   --����
       ,XOL.uom_code                    uom_code                   --�P��
       ,XOL.shipped_quantity            shipped_quantity           --�o�׎��ѐ���
       ,XOL.designated_production_date  designated_production_date --�w�萻����
       ,XOL.based_request_quantity      based_request_quantity     --���_�˗�����
       ,XOL.designated_date             designated_date            --�w����t_���[�t
       ,XOL.move_number                 move_number                --�ړ�No
       ,XOL.po_number                   po_number                  --����No
       ,XOL.cust_po_number              cust_po_number             --�ڋq����
       ,XOL.pallet_quantity             pallet_quantity            --�p���b�g��
       ,XOL.layer_quantity              layer_quantity             --�i��
       ,XOL.case_quantity               case_quantity              --�P�[�X��
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL(XOL.weight)                weight                     --�d��(�����_�ȉ��؏グ)
       ,CEIL(TRUNC(NVL(XOL.weight,0),1))                           
                                        weight                     --�d��(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/7 #627 Y.Fukami Mod End
       ,CEIL(XOL.capacity)              capacity                   --�e��(�����_�ȉ��؏グ)
       ,XOL.pallet_qty                  pallet_qty                 --�p���b�g����
       ,CEIL(XOL.pallet_weight)         pallet_weight              --�p���b�g�d��(�����_�ȉ��؏グ)
       ,XOL.reserved_quantity           reserved_quantity          --������
       ,XOL.status_quantity             status_quantity            --�X�e�[�^�X�ʐ���
       ,XOL.warning_class               warning_class              --�x���敪
       ,FLV01.meaning                   warning_c_name             --�x���敪��
       ,XOL.warning_date                warning_date               --�x�����t
       ,XOL.line_description            line_description           --�E�v
       ,XOL.shipping_request_if_flg     shipping_request_if_flg    --�o�׈˗��C���^�t�F�[�X�σt���O
       ,XOL.shipping_result_if_flg      shipping_result_if_flg     --�o�׎��уC���^�t�F�[�X�σt���O
       ,FU_CB.user_name                 created_by_name            --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XOL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        creation_date              --�쐬����
       ,FU_LU.user_name                 last_updated_by_name       --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XOL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                        last_update_date           --�X�V����
       ,FU_LL.user_name                 last_update_login_name     --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  ( --���̎擾�n�ȊO�̃f�[�^�͂��̓���SQL�őS�Ď擾����
          SELECT XOLA.request_no                                   --�˗�No
                ,XOLA.order_line_number                            --���הԍ�
                ,XOLA.shipping_item_code                           --�o�וi�ڃR�[�h
                ,XOLA.request_item_code                            --�˗��i�ڃR�[�h
                ,XOLA.delete_flag                                  --�폜�t���O
                ,XOLA.quantity                                     --����
                ,XOLA.uom_code                                     --�P��
                ,XOLA.shipped_quantity                             --�o�׎��ѐ���
                ,XOLA.designated_production_date                   --�w�萻����
                ,XOLA.based_request_quantity                       --���_�˗�����
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
                ,CASE WHEN XOHA.req_status = '04' THEN XOLA.shipped_quantity        --���ю�
                      WHEN XOHA.req_status = '03' THEN XOLA.quantity                --�w����
                      ELSE                             XOLA.based_request_quantity  --�˗���
                 END                              status_quantity  --�X�e�[�^�X�ʐ���
                ,XOLA.warning_class                                --�x���敪
                ,XOLA.warning_date                                 --�x�����t
                ,XOLA.line_description                             --�E�v
                ,XOLA.shipping_request_if_flg                      --�o�׈˗��C���^�t�F�[�X�σt���O
                ,XOLA.shipping_result_if_flg                       --�o�׎��уC���^�t�F�[�X�σt���O
                ,XOLA.created_by                                   --�쐬��
                ,XOLA.creation_date                                --�쐬��
                ,XOLA.last_updated_by                              --�ŏI�X�V��
                ,XOLA.last_update_date                             --�ŏI�X�V��
                ,XOLA.last_update_login                            --�ŏI�X�V���O�C��
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )    --NVL( ���ד�, ���ח\��� )
                                                  arrival_date     --���ד� (�˕i�ږ��̎擾�Ŏg�p)
          FROM   xxwsh_order_headers_all   XOHA
                ,xxwsh_order_lines_all     XOLA
                ,oe_transaction_types_all  OTTA
          WHERE
                 XOHA.order_header_id = XOLA.order_header_id
          AND    XOHA.order_type_id = OTTA.transaction_type_id
          AND    OTTA.attribute1 = '1'                             --1:�o��
          AND    XOHA.latest_external_flag = 'Y'
          AND    NVL(XOLA.delete_flag, 'N') <> 'Y'
        )                     XOL     --���׏��
       ,xxsky_item_mst2_v     ITEM1    --�o�וi�ږ��̎擾�p
       ,xxsky_item_mst2_v     ITEM2    --�˗��i�ږ��̎擾�p
       ,xxsky_prod_class_v    PRODC    --���i�敪�擾�p
       ,xxsky_item_class_v    ITEMC    --�i�ڋ敪�擾�p
       ,xxsky_crowd_code_v    CROWD    --�Q�R�[�h�擾�p
       ,fnd_lookup_values     FLV01    --�x���敪���擾�p
       ,fnd_user                     FU_CB   --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                     FU_LU   --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                     FU_LL   --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                   FL_LL   --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
        --�o�וi�ڏ��擾����
        XOL.shipping_item_code =  ITEM1.item_no(+)
   AND  XOL.arrival_date       >= ITEM1.start_date_active(+)
   AND  XOL.arrival_date       <= ITEM1.end_date_active(+)
        --�o�וi�ڂ̃J�e�S�����擾����
   AND  ITEM1.item_id = PRODC.item_id(+)    --���i�敪
   AND  ITEM1.item_id = ITEMC.item_id(+)    --�i�ڋ敪
   AND  ITEM1.item_id = CROWD.item_id(+)    --�Q�R�[�h
        --�˗��i�ڏ��擾����
   AND  XOL.request_item_code =  ITEM2.item_no(+)
   AND  XOL.arrival_date      >= ITEM2.start_date_active(+)
   AND  XOL.arrival_date      <= ITEM2.end_date_active(+)
        --�x���敪���擾����
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXWSH_WARNING_CLASS'
   AND  FLV01.lookup_code(+) = XOL.warning_class
        --WHO�J�����擾
   AND  XOL.created_by        = FU_CB.user_id(+)
   AND  XOL.last_updated_by   = FU_LU.user_id(+)
   AND  XOL.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�󒍏o�ז���_��{_V IS 'SKYLINK�p �󒍏o�ז��ׁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�˗�NO IS '�˗�NO'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.���הԍ� IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�o�וi�� IS '�o�וi��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�o�וi�ږ� IS '�o�וi�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�o�וi�ڗ��� IS '�o�וi�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�˗��i�� IS '�˗��i��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�˗��i�ږ� IS '�˗��i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�˗��i�ڗ��� IS '�˗��i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�폜�t���O IS '�폜�t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.���� IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�P�� IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�o�׎��ѐ��� IS '�o�׎��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�w�萻���� IS '�w�萻����'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.���_�˗����� IS '���_�˗�����'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�w����t_���[�t IS '�w����t_���[�t'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�ړ�NO IS '�ړ�NO'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.����NO IS '����NO'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�ڋq���� IS '�ڋq����'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�p���b�g�� IS '�p���b�g��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�i�� IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�P�[�X�� IS '�P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�d�� IS '�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�e�� IS '�e��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�p���b�g���� IS '�p���b�g����'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�p���b�g�d�� IS '�p���b�g�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�X�e�[�^�X�ʐ��� IS '�X�e�[�^�X�ʐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�x���敪 IS '�x���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�x���敪�� IS '�x���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�x�����t IS '�x�����t'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�E�v IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�o�׈˗��C���^�t�F�[�X�σt���O IS '�o�׈˗��C���^�t�F�[�X�σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�o�׎��уC���^�t�F�[�X�σt���O IS '�o�׎��уC���^�t�F�[�X�σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�󒍏o�ז���_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
