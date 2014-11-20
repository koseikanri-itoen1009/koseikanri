CREATE OR REPLACE VIEW APPS.XXSKY_�o�ז��׃��b�g��_��{_V
(
 �˗�No
,���הԍ�
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
,���b�g�ʎw������
,���b�g�ʏo�׎��ѐ���
,�P��
,�˗��i��
,�˗��i�ږ�
,�˗��i�ڗ���
,�w�萻����
,�w����t_���[�t
,�ړ�No
,����No
,�ڋq����
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
,�ŏI�X�V���O�C��
)
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
       ,NVL( DECODE( XOL.lot_no, 'DEFAULTLOT', '0', XOL.lot_no ), '0' )
                                        lot_no                     --���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN ILM.attribute1      --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                       --�񃍃b�g�Ǘ��i ��NULL
        END                             lot_date                   --�����N����
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN ILM.attribute2      --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                       --�񃍃b�g�Ǘ��i ��NULL
        END                             lot_sign                   --�ŗL�L��
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN ILM.attribute3      --���b�g�Ǘ��i   ���ܖ��������擾
             ELSE NULL                                       --�񃍃b�g�Ǘ��i ��NULL
        END                             best_bfr_date              --�ܖ�����
       ,XOL.instruct_qty                instruct_qty               --���b�g�ʎw������
       ,XOL.shipped_quantity            shipped_quantity           --���b�g�ʏo�׎��ѐ���
       ,XOL.uom_code                    uom_code                   --�P��
       ,XOL.request_item_code           request_item_code          --�˗��i��
       ,ITEM2.item_name                 request_item_name          --�˗��i�ږ�
       ,ITEM2.item_short_name           request_item_s_name        --�˗��i�ڗ���
       ,XOL.designated_production_date  designated_production_date --�w�萻����
       ,XOL.designated_date             designated_date            --�w����t_���[�t
       ,XOL.move_number                 move_number                --�ړ�No
       ,XOL.po_number                   po_number                  --����No
       ,XOL.cust_po_number              cust_po_number             --�ڋq����
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
                ,XMLD.item_id                                      --�i��ID
                ,XMLD.lot_id                                       --���b�gID
                ,XMLD.lot_no                                       --���b�gno
                ,XMLD.instruct_qty                                 --���b�g�ʎw������
                ,XMLD.shipped_quantity                             --���b�g�ʏo�׎��ѐ���
                ,XOLA.uom_code                                     --�P��
                ,XOLA.request_item_code                            --�˗��i�ڃR�[�h
                ,XOLA.designated_production_date                   --�w�萻����
                ,XOLA.designated_date                              --�w����t_���[�t
                ,XOLA.move_number                                  --�ړ�No
                ,XOLA.po_number                                    --����No
                ,XOLA.cust_po_number                               --�ڋq����
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
                ,(  --�ړ����b�g�ڍׂ̏������b�g�P�ʂŏW�v
                    SELECT  mov_line_id                            --����ID
                           ,item_id                                --�i��ID
                           ,lot_id                                 --���b�gID
                           ,lot_no                                 --���b�gNo
                           ,SUM( CASE WHEN record_type_code = '10' THEN actual_quantity END )
                                               instruct_qty        --���b�g�ʎw������
                           ,SUM( CASE WHEN record_type_code = '20' THEN actual_quantity END )
                                               shipped_quantity    --���b�g�ʏo�׎���
                      FROM  xxinv_mov_lot_details
                     WHERE  document_type_code = '10'                                          --�o�׈˗�
                    GROUP BY mov_line_id
                            ,item_id
                            ,lot_id
                            ,lot_no
                 )                         XMLD
                ,oe_transaction_types_all  OTTA
          WHERE
                 XOHA.order_header_id = XOLA.order_header_id
          AND    XOHA.order_type_id = OTTA.transaction_type_id
          AND    OTTA.attribute1 = '1'                             --1:�o��
          AND    XOHA.latest_external_flag = 'Y'
          AND    NVL(XOLA.delete_flag, 'N') <> 'Y'
          --�ړ����b�g�ڍ׃f�[�^�Ƃ̌���
          AND    XOLA.order_line_id = XMLD.mov_line_id(+)
        )                     XOL      --���׏��
       ,xxsky_item_mst2_v     ITEM1    --�o�וi�ږ��̎擾�p
       ,xxsky_item_mst2_v     ITEM2    --�˗��i�ږ��̎擾�p
       ,xxsky_prod_class_v    PRODC    --���i�敪�擾�p
       ,xxsky_item_class_v    ITEMC    --�i�ڋ敪�擾�p
       ,xxsky_crowd_code_v    CROWD    --�Q�R�[�h�擾�p
       ,ic_lots_mst           ILM      --���b�g�}�X�^
       ,fnd_lookup_values     FLV01    --�x���敪���擾�p
       ,fnd_user              FU_CB    --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user              FU_LU    --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user              FU_LL    --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins            FL_LL    --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
        --�o�וi�ڏ��擾����
        XOL.shipping_item_code  = ITEM1.item_no(+)
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
        --���b�g���擾����
   AND  XOL.item_id           = ILM.item_id(+)
   AND  XOL.lot_id            = ILM.lot_id(+)
        --�x���敪���擾����
   AND  FLV01.language(+)     = 'JA'
   AND  FLV01.lookup_type(+)  = 'XXWSH_WARNING_CLASS'
   AND  FLV01.lookup_code(+)  = XOL.warning_class
        --WHO�J�����擾
   AND  XOL.created_by        = FU_CB.user_id(+)
   AND  XOL.last_updated_by   = FU_LU.user_id(+)
   AND  XOL.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id         = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�o�ז��׃��b�g��_��{_V IS 'SKYLINK�p �o�ז��׃��b�g�ʁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�˗�No                         IS '�˗�No'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.���הԍ�                       IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�i�ڋ敪                       IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�i�ڋ敪��                     IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�Q�R�[�h                       IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�o�וi��                       IS '�o�וi��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�o�וi�ږ�                     IS '�o�וi�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�o�וi�ڗ���                   IS '�o�וi�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.���b�gNO                       IS '���b�gNO'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�����N����                     IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�ŗL�L��                       IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�ܖ�����                       IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.���b�g�ʎw������               IS '���b�g�ʎw������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.���b�g�ʏo�׎��ѐ���           IS '���b�g�ʏo�׎��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�P��                           IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�˗��i��                       IS '�˗��i��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�˗��i�ږ�                     IS '�˗��i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�˗��i�ڗ���                   IS '�˗��i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�w�萻����                     IS '�w�萻����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�w����t_���[�t                IS '�w����t_���[�t'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�ړ�No                         IS '�ړ�No'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.����No                         IS '����No'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�ڋq����                       IS '�ڋq����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�x���敪                       IS '�x���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�x���敪��                     IS '�x���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�x�����t                       IS '�x�����t'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�E�v                           IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�o�׈˗��C���^�t�F�[�X�σt���O IS '�o�׈˗��C���^�t�F�[�X�σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�o�׎��уC���^�t�F�[�X�σt���O IS '�o�׎��уC���^�t�F�[�X�σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�ז��׃��b�g��_��{_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
