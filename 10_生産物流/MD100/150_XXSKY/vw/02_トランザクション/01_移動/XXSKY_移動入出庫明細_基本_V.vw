CREATE OR REPLACE VIEW APPS.XXSKY_�ړ����o�ɖ���_��{_V
(
 �ړ��ԍ�
,���הԍ�
,�g�D��
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�˗�����
,�p���b�g��
,�i��
,�P�[�X��
,�w������
,������
,�P��
,�w�萻����
,�p���b�g����
,�Q�ƈړ��ԍ�
,�Q�Ɣ����ԍ�
,����w������
,�o�Ɏ��ѐ���
,���Ɏ��ѐ���
,�d��
,�e��
,�p���b�g�d��
,�����蓮�����敪
,�����蓮�����敪��
,����t���O
,����t���O��
,�x�����t
,�x���敪
,���b�gNO
,�����N����
,�ŗL�L��
,�ܖ�����
,�w��_���R�[�h�^�C�v
,�w��_���R�[�h�^�C�v��
,�w��_���ѓ�
,�w��_���ѐ���
,�w��_�����O���ѐ���
,�w��_�����蓮�����敪
,�w��_�����蓮�����敪��
,�o��_���R�[�h�^�C�v
,�o��_���R�[�h�^�C�v��
,�o��_���ѓ�
,�o��_���ѐ���
,�o��_�����O���ѐ���
,�o��_�����蓮�����敪
,�o��_�����蓮�����敪��
,����_���R�[�h�^�C�v
,����_���R�[�h�^�C�v��
,����_���ѓ�
,����_���ѐ���
,����_�����O���ѐ���
,����_�����蓮�����敪
,����_�����蓮�����敪��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  XINS.mov_num                      --�ړ��ԍ�
       ,XINS.line_number                  --���הԍ�
       ,HAOUT.name                        --�g�D��
       ,XPCV.prod_class_code              --���i�敪
       ,XPCV.prod_class_name              --���i�敪��
       ,XICV.item_class_code              --�i�ڋ敪
       ,XICV.item_class_name              --�i�ڋ敪��
       ,XCCV.crowd_code                   --�Q�R�[�h
       ,XINS.item_code                    --�i�ڃR�[�h
       ,XIMV.item_name                    --�i�ږ�
       ,XIMV.item_short_name              --�i�ڗ���
       ,XINS.request_qty                  --�˗�����
       ,XINS.pallet_quantity              --�p���b�g��
       ,XINS.layer_quantity               --�i��
       ,XINS.case_quantity                --�P�[�X��
       ,XINS.instruct_qty                 --�w������
       ,XINS.reserved_quantity            --������
       ,XINS.uom_code                     --�P��
       ,XINS.designated_production_date   --�w�萻����
       ,XINS.pallet_qty                   --�p���b�g����
       ,XINS.move_num                     --�Q�ƈړ��ԍ�
       ,XINS.po_num                       --�Q�Ɣ����ԍ�
       ,XINS.first_instruct_qty           --����w������
       ,XINS.shipped_quantity             --�o�Ɏ��ѐ���
       ,XINS.ship_to_quantity             --���Ɏ��ѐ���
       ,CEIL(XINS.weight)
        weight                            --�d��
       ,CEIL(XINS.capacity)
        capacity                          --�e��
       ,XINS.pallet_weight                --�p���b�g�d��
       ,XINS.automanual_reserve_class     --�����蓮�����敪
       ,FLV01.meaning                     --�����蓮�����敪��
       ,XINS.delete_flg                   --����t���O
       ,FLV02.meaning                     --����t���O��
       ,XINS.warning_date                 --�x�����t
       ,XINS.warning_class                --�x���敪
       ,NVL( DECODE( XINS.lot_no, 'DEFAULTLOT', '0', XINS.lot_no ), '0' )
                       lot_no            --���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN XIMV.lot_ctl = 1 THEN XINS.attribute1  --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END             manufacture_date  --�����N����
       ,CASE WHEN XIMV.lot_ctl = 1 THEN XINS.attribute2  --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END             uniqe_sign        --�ŗL�L��
       ,CASE WHEN XIMV.lot_ctl = 1 THEN XINS.attribute3  --���b�g�Ǘ��i   ���ܖ��������擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END             expiration_date   --�ܖ�����
       ,XINS.record_type_code_sj          --�w��_���R�[�h�^�C�v
       ,FLV03.meaning                     --�w��_���R�[�h�^�C�v��
       ,XINS.actual_date_sj               --�w��_���ѓ�
       ,XINS.actual_quantity_sj           --�w��_���ѐ���
       ,XINS.before_actual_quantity_sj    --�w��_�����O���ѐ���
       ,XINS.automanual_reserve_class_sj  --�w��_�����蓮�����敪
       ,FLV04.meaning                     --�w��_�����蓮�����敪��
       ,XINS.record_type_code_sk          --�o��_���R�[�h�^�C�v
       ,FLV05.meaning                     --�o��_���R�[�h�^�C�v��
       ,XINS.actual_date_sk               --�o��_���ѓ�
       ,XINS.actual_quantity_sk           --�o��_���ѐ���
       ,XINS.before_actual_quantity_sk    --�o��_�����O���ѐ���
       ,XINS.automanual_reserve_class_sk  --�o��_�����蓮�����敪
       ,FLV06.meaning                     --�o��_�����蓮�����敪��
       ,XINS.record_type_code_nk          --����_���R�[�h�^�C�v
       ,FLV07.meaning                     --����_���R�[�h�^�C�v��
       ,XINS.actual_date_nk               --����_���ѓ�
       ,XINS.actual_quantity_nk           --����_���ѐ���
       ,XINS.before_actual_quantity_nk    --����_�����O���ѐ���
       ,XINS.automanual_reserve_class_nk  --����_�����蓮�����敪
       ,FLV08.meaning                     --����_�����蓮�����敪��
       ,FU_CB.user_name                   --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XINS.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                          --�쐬����
       ,FU_LU.user_name                   --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XINS.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                          --�X�V����
       ,FU_LL.user_name                   --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  (  ----���̎擾�n�ȊO�̃f�[�^�͂��̓���SQL�őS�Ď擾����
           SELECT  XMRIH.mov_num                     --�ړ��ԍ�
                  ,XMRIL.line_number                 --���הԍ�
                  ,XMRIL.item_code                   --�i�ڃR�[�h
                  ,XMRIL.request_qty                 --�˗�����
                  ,XMRIL.pallet_quantity             --�p���b�g��
                  ,XMRIL.layer_quantity              --�i��
                  ,XMRIL.case_quantity               --�P�[�X��
                  ,XMRIL.instruct_qty                --�w������
                  ,XMRIL.reserved_quantity           --������
                  ,XMRIL.uom_code                    --�P��
                  ,XMRIL.designated_production_date  --�w�萻����
                  ,XMRIL.pallet_qty                  --�p���b�g����
                  ,XMRIL.move_num                    --�Q�ƈړ��ԍ�
                  ,XMRIL.po_num                      --�Q�Ɣ����ԍ�
                  ,XMRIL.first_instruct_qty          --����w������
                  ,XMRIL.shipped_quantity            --�o�Ɏ��ѐ���
                  ,XMRIL.ship_to_quantity            --���Ɏ��ѐ���
                  ,XMRIL.weight                      --�d��
                  ,XMRIL.capacity                    --�e��
                  ,XMRIL.pallet_weight               --�p���b�g�d��
                  ,XMRIL.automanual_reserve_class    --�����蓮�����敪
                  ,XMRIL.delete_flg                  --����t���O
                  ,XMRIL.warning_date                --�x�����t
                  ,XMRIL.warning_class               --�x���敪
                  ,XMLD.lot_no                       --���b�gNo
                  ,ILM.attribute1                    --�����N����
                  ,ILM.attribute2                    --�ŗL�L��
                  ,ILM.attribute3                    --�ܖ�����
                   --�w�����b�g�ڍ׍���
                  ,XMLD_SJ.record_type_code
                   record_type_code_sj               --�w��_���R�[�h�^�C�v
                  ,XMLD_SJ.actual_date
                   actual_date_sj                    --�w��_���ѓ�
                  ,XMLD_SJ.actual_quantity
                   actual_quantity_sj                --�w��_���ѐ���
                  ,XMLD_SJ.before_actual_quantity
                   before_actual_quantity_sj         --�w��_�����O���ѐ���
                  ,XMLD_SJ.automanual_reserve_class
                   automanual_reserve_class_sj       --�w��_�����蓮�����敪
                   --�o�Ɏ��у��b�g�ڍ׍���
                  ,XMLD_SK.record_type_code
                   record_type_code_sk               --�o��_���R�[�h�^�C�v
                  ,XMLD_SK.actual_date
                   actual_date_sk                    --�o��_���ѓ�
                  ,XMLD_SK.actual_quantity
                   actual_quantity_sk                --�o��_���ѐ���
                  ,XMLD_SK.before_actual_quantity
                   before_actual_quantity_sk         --�o��_�����O���ѐ���
                  ,XMLD_SK.automanual_reserve_class
                   automanual_reserve_class_sk       --�o��_�����蓮�����敪
                   --���Ɏ��у��b�g�ڍ׍���
                  ,XMLD_NK.record_type_code
                   record_type_code_nk               --����_���R�[�h�^�C�v
                  ,XMLD_NK.actual_date
                   actual_date_nk                    --����_���ѓ�
                  ,XMLD_NK.actual_quantity
                   actual_quantity_nk                --����_���ѐ���
                  ,XMLD_NK.before_actual_quantity
                   before_actual_quantity_nk         --����_�����O���ѐ���
                  ,XMLD_NK.automanual_reserve_class
                   automanual_reserve_class_nk       --����_�����蓮�����敪
                  ,XMRIL.created_by                  --�쐬��
                  ,XMRIL.creation_date               --�쐬����
                  ,XMRIL.last_updated_by             --�ŏI�X�V��
                  ,XMRIL.last_update_date            --�X�V����
                  ,XMRIL.last_update_login           --�ŏI�X�V���O�C��
                  ,XMRIL.organization_id             --�g�DID(�g�D���擾�p)
                  ,NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date )
                                   arrival_date      --���ɓ�(�i�ڏ��擾�p)
             FROM  xxinv_mov_req_instr_lines    XMRIL               --�ړ��˗�/�w�����׃A�h�I��
                  ,xxinv_mov_req_instr_headers  XMRIH               --�ړ��˗�/�w���w�b�_�A�h�I��
                  ,(  SELECT  distinct mov_line_id
                                      ,item_id
                                      ,lot_id
                                      ,lot_no
                        FROM  xxinv_mov_lot_details
                       WHERE  document_type_code = '20'
                    )                            XMLD               --�ړ����b�g�ڍ׃A�h�I��(���C��ID,���b�gID�d������)
                  ,(  SELECT  XMLD10.mov_line_id
                             ,XMLD10.lot_id
                             ,XMLD10.record_type_code
                             ,XMLD10.actual_date
                             ,SUM(XMLD10.actual_quantity)
                              actual_quantity
                             ,SUM(XMLD10.before_actual_quantity)
                              before_actual_quantity
                             ,XMLD10.automanual_reserve_class
                        FROM  xxinv_mov_lot_details       XMLD10
                       WHERE  XMLD10.record_type_code   = '10'      --�w��
                         AND  XMLD10.document_type_code = '20'
                    GROUP BY  XMLD10.mov_line_id
                             ,XMLD10.lot_id
                             ,XMLD10.record_type_code
                             ,XMLD10.actual_date
                             ,XMLD10.automanual_reserve_class
                   )                             XMLD_SJ            --�ړ����b�g�ڍ׃A�h�I��(�w�����b�g�ڍחp)
                  ,(  SELECT  XMLD20.mov_line_id
                             ,XMLD20.lot_id
                             ,XMLD20.record_type_code
                             ,XMLD20.actual_date
                             ,SUM(XMLD20.actual_quantity)
                              actual_quantity
                             ,SUM(XMLD20.before_actual_quantity)
                              before_actual_quantity
                             ,XMLD20.automanual_reserve_class
                        FROM  xxinv_mov_lot_details       XMLD20
                       WHERE  XMLD20.record_type_code   = '20'      --�o�Ɏ���
                         AND  XMLD20.document_type_code = '20'
                    GROUP BY  XMLD20.mov_line_id
                             ,XMLD20.lot_id
                             ,XMLD20.record_type_code
                             ,XMLD20.actual_date
                             ,XMLD20.automanual_reserve_class
                   )                             XMLD_SK            --�ړ����b�g�ڍ׃A�h�I��(�o�Ɏ��у��b�g�ڍחp)
                  ,(  SELECT  XMLD30.mov_line_id
                             ,XMLD30.lot_id
                             ,XMLD30.record_type_code
                             ,XMLD30.actual_date
                             ,SUM(XMLD30.actual_quantity)
                              actual_quantity
                             ,SUM(XMLD30.before_actual_quantity)
                              before_actual_quantity
                             ,XMLD30.automanual_reserve_class
                        FROM  xxinv_mov_lot_details       XMLD30
                       WHERE  XMLD30.record_type_code   = '30'      --���Ɏ���
                         AND  XMLD30.document_type_code = '20'
                    GROUP BY  XMLD30.mov_line_id
                             ,XMLD30.lot_id
                             ,XMLD30.record_type_code
                             ,XMLD30.actual_date
                             ,XMLD30.automanual_reserve_class
                   )                             XMLD_NK            --�ړ����b�g�ڍ׃A�h�I��(���Ɏ��у��b�g�ڍחp)
                  ,ic_lots_mst               ILM                    --���b�g�}�X�^
            WHERE  XMRIL.mov_hdr_id           = XMRIH.mov_hdr_id
              AND  NVL( XMRIL.delete_flg, 'N' ) <> 'Y'              --�������׈ȊO
              AND  XMRIL.mov_line_id          = XMLD.mov_line_id(+)
              AND  XMLD.item_id               = ILM.item_id(+)
              AND  XMLD.lot_id                = ILM.lot_id(+)
              --�w�����b�g�ڍ׎擾����
              AND  XMLD.mov_line_id           = XMLD_SJ.mov_line_id(+)
              AND  XMLD.lot_id                = XMLD_SJ.lot_id(+)
              --�o�Ɏ��у��b�g�ڍ׎擾����
              AND  XMLD.mov_line_id           = XMLD_SK.mov_line_id(+)
              AND  XMLD.lot_id                = XMLD_SK.lot_id(+)
              --���Ɏ��у��b�g�ڍ׎擾����
              AND  XMLD.mov_line_id           = XMLD_NK.mov_line_id(+)
              AND  XMLD.lot_id                = XMLD_NK.lot_id(+)
        )                               XINS                        --�ړ����o�ɖ��ׁ��ړ����o�Ƀ��b�g�ڍ׏��
       ,hr_all_organization_units_tl    HAOUT                       --�g�D���̃}�X�^
       ,xxsky_prod_class_v              XPCV                        --SKYLINK�p ���i�敪�擾VIEW
       ,xxsky_item_class_v              XICV                        --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxsky_crowd_code_v              XCCV                        --SKYLINK�p �S�R�[�h�擾VIEW
       ,xxsky_item_mst2_v               XIMV                        --SKYLINK�p����VIEW OPM�i�ڏ��VIEW
       ,fnd_lookup_values               FLV01                       --�N�C�b�N�R�[�h(�����蓮�����敪��)
       ,fnd_lookup_values               FLV02                       --�N�C�b�N�R�[�h(����t���O��)
       ,fnd_lookup_values               FLV03                       --�N�C�b�N�R�[�h(�w��_���R�[�h�^�C�v��)
       ,fnd_lookup_values               FLV04                       --�N�C�b�N�R�[�h(�w��_�����蓮�����敪��)
       ,fnd_lookup_values               FLV05                       --�N�C�b�N�R�[�h(�o��_���R�[�h�^�C�v��)
       ,fnd_lookup_values               FLV06                       --�N�C�b�N�R�[�h(�o��_�����蓮�����敪��)
       ,fnd_lookup_values               FLV07                       --�N�C�b�N�R�[�h(����_���R�[�h�^�C�v��)
       ,fnd_lookup_values               FLV08                       --�N�C�b�N�R�[�h(����_�����蓮�����敪��)
       ,fnd_user                        FU_CB                       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                        FU_LU                       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                        FU_LL                       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                      FL_LL                       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
   --�g�D���擾����
        XINS.organization_id      = HAOUT.organization_id(+)
   AND  HAOUT.language(+)         = 'JA'
   --�i�ڏ��擾����
   AND  XINS.item_code            = XIMV.item_no(+)
   AND  XINS.arrival_date        >= XIMV.start_date_active(+)
   AND  XINS.arrival_date        <= XIMV.end_date_active(+)
   --�i�ڃJ�e�S�����擾����
   AND  XIMV.item_id              = XPCV.item_id(+)
   AND  XIMV.item_id              = XICV.item_id(+)
   AND  XIMV.item_id              = XCCV.item_id(+)
   --�N�C�b�N�R�[�h�F�����蓮�����敪���擾
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV01.lookup_code(+) = XINS.automanual_reserve_class
   --�N�C�b�N�R�[�h�F����t���O���擾
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_YESNO'
   AND  FLV02.lookup_code(+) = XINS.delete_flg
   --�N�C�b�N�R�[�h�F�w��_���R�[�h�^�C�v���擾
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXINV_RECORD_TYPE'
   AND  FLV03.lookup_code(+) = XINS.record_type_code_sj
   --�N�C�b�N�R�[�h�F�w��_�����蓮�����敪���擾
   AND  FLV04.language(+)    = 'JA'
   AND  FLV04.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV04.lookup_code(+) = XINS.automanual_reserve_class_sj
   --�N�C�b�N�R�[�h�F�o��_���R�[�h�^�C�v���擾
   AND  FLV05.language(+)    = 'JA'
   AND  FLV05.lookup_type(+) = 'XXINV_RECORD_TYPE'
   AND  FLV05.lookup_code(+) = XINS.record_type_code_sk
   --�N�C�b�N�R�[�h�F�o��_�����蓮�����敪���擾
   AND  FLV06.language(+)    = 'JA'
   AND  FLV06.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV06.lookup_code(+) = XINS.automanual_reserve_class_sk
   --�N�C�b�N�R�[�h�F����_���R�[�h�^�C�v���擾
   AND  FLV07.language(+)    = 'JA'
   AND  FLV07.lookup_type(+) = 'XXINV_RECORD_TYPE'
   AND  FLV07.lookup_code(+) = XINS.record_type_code_nk
   --�N�C�b�N�R�[�h�F����_�����蓮�����敪���擾
   AND  FLV08.language(+)    = 'JA'
   AND  FLV08.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV08.lookup_code(+) = XINS.automanual_reserve_class_nk
   --WHO�J�����擾
   AND  XINS.created_by         = FU_CB.user_id(+)
   AND  XINS.last_updated_by    = FU_LU.user_id(+)
   AND  XINS.last_update_login  = FL_LL.login_id(+)
   AND  FL_LL.user_id           = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�ړ����o�ɖ���_��{_V IS 'SKYLINK�p�ړ����o�ɖ��ׁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�ړ��ԍ� IS '�ړ��ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.���הԍ� IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�g�D�� IS '�g�D��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�i�ڃR�[�h IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�i�ږ� IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�˗����� IS '�˗�����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�p���b�g�� IS '�p���b�g��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�i�� IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�P�[�X�� IS '�P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�w������ IS '�w������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�P�� IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�w�萻���� IS '�w�萻����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�p���b�g���� IS '�p���b�g����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�Q�ƈړ��ԍ� IS '�Q�ƈړ��ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�Q�Ɣ����ԍ� IS '�Q�Ɣ����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.����w������ IS '����w������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�o�Ɏ��ѐ��� IS '�o�Ɏ��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.���Ɏ��ѐ��� IS '���Ɏ��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�d�� IS '�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�e�� IS '�e��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�p���b�g�d�� IS '�p���b�g�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�����蓮�����敪 IS '�����蓮�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�����蓮�����敪�� IS '�����蓮�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.����t���O IS '����t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.����t���O�� IS '����t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�x�����t IS '�x�����t'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�x���敪 IS '�x���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.���b�gNO IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�����N���� IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�ŗL�L�� IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�ܖ����� IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�w��_���R�[�h�^�C�v IS '�w��_���R�[�h�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�w��_���R�[�h�^�C�v�� IS '�w��_���R�[�h�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�w��_���ѓ� IS '�w��_���ѓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�w��_���ѐ��� IS '�w��_���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�w��_�����O���ѐ��� IS '�w��_�����O���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�w��_�����蓮�����敪 IS '�w��_�����蓮�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�w��_�����蓮�����敪�� IS '�w��_�����蓮�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�o��_���R�[�h�^�C�v IS '�o��_���R�[�h�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�o��_���R�[�h�^�C�v�� IS '�o��_���R�[�h�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�o��_���ѓ� IS '�o��_���ѓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�o��_���ѐ��� IS '�o��_���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�o��_�����O���ѐ��� IS '�o��_�����O���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�o��_�����蓮�����敪 IS '�o��_�����蓮�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�o��_�����蓮�����敪�� IS '�o��_�����蓮�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.����_���R�[�h�^�C�v IS '����_���R�[�h�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.����_���R�[�h�^�C�v�� IS '����_���R�[�h�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.����_���ѓ� IS '����_���ѓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.����_���ѐ��� IS '����_���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.����_�����O���ѐ��� IS '����_�����O���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.����_�����蓮�����敪 IS '����_���b�g_�����蓮�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.����_�����蓮�����敪�� IS '����_���b�g_�����蓮�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ����o�ɖ���_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
