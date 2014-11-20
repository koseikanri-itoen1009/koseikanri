CREATE OR REPLACE VIEW APPS.XXSKY_�ړ�����_��{_V
(
 �ړ��ԍ�
,���הԍ�
,���R�[�h�^�C�v
,���R�[�h�^�C�v��
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
,���ѓ�
,���ѐ���
,�����O���ѐ���
,���b�g_�����蓮�����敪
,���b�g_�����蓮�����敪��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  XILL.mov_num                      --�ړ��ԍ�
       ,XILL.line_number                  --���הԍ�
       ,XILL.record_type_code             --���R�[�h�^�C�v
       ,FLV01.meaning                     --���R�[�h�^�C�v��
       ,HAOUT.name                        --�g�D��
       ,XPCV.prod_class_code              --���i�敪
       ,XPCV.prod_class_name              --���i�敪��
       ,XICV.item_class_code              --�i�ڋ敪
       ,XICV.item_class_name              --�i�ڋ敪��
       ,XCCV.crowd_code                   --�Q�R�[�h
       ,XILL.item_code                    --�i�ڃR�[�h
       ,XIMV.item_name                    --�i�ږ�
       ,XIMV.item_short_name              --�i�ڗ���
       ,XILL.request_qty                  --�˗�����
       ,XILL.pallet_quantity              --�p���b�g��
       ,XILL.layer_quantity               --�i��
       ,XILL.case_quantity                --�P�[�X��
       ,XILL.instruct_qty                 --�w������
       ,XILL.reserved_quantity            --������
       ,XILL.uom_code                     --�P��
       ,XILL.designated_production_date   --�w�萻����
       ,XILL.pallet_qty                   --�p���b�g����
       ,XILL.move_num                     --�Q�ƈړ��ԍ�
       ,XILL.po_num                       --�Q�Ɣ����ԍ�
       ,XILL.first_instruct_qty           --����w������
       ,XILL.shipped_quantity             --�o�Ɏ��ѐ���
       ,XILL.ship_to_quantity             --���Ɏ��ѐ���
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL(XILL.weight)
       ,CEIL(TRUNC(NVL(XILL.weight,0),1))     --�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ
-- 2010/1/7 #627 Y.Fukami Mod End
        weight                            --�d��
       ,CEIL(XILL.capacity)
        capacity                          --�e��
       ,XILL.pallet_weight                --�p���b�g�d��
       ,XILL.automanual_reserve_class     --�����蓮�����敪
       ,FLV02.meaning                     --�����蓮�����敪��
       ,XILL.delete_flg                   --����t���O
       ,FLV03.meaning                     --����t���O��
       ,XILL.warning_date                 --�x�����t
       ,XILL.warning_class                --�x���敪
       ,NVL( DECODE( XILL.lot_no, 'DEFAULTLOT', '0', XILL.lot_no ), '0' )
                        lot_no            --���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN XIMV.lot_ctl = 1 THEN XILL.attribute1  --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END             manufacture_date  --�����N����
       ,CASE WHEN XIMV.lot_ctl = 1 THEN XILL.attribute2  --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END             uniqe_sign        --�ŗL�L��
       ,CASE WHEN XIMV.lot_ctl = 1 THEN XILL.attribute3  --���b�g�Ǘ��i   ���ܖ��������擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END             expiration_date   --�ܖ�����
       ,XILL.actual_date                  --���ѓ�
       ,XILL.actual_quantity              --���ѐ���
       ,XILL.before_actual_quantity       --�����O���ѐ���
       ,XILL.automanual_reserve_class_l   --���b�g_�����蓮�����敪
       ,FLV04.meaning                     --���b�g_�����蓮�����敪��
       ,FU_CB.user_name                   --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XILL.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                          --�쐬����
       ,FU_LU.user_name                   --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XILL.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                          --�X�V����
       ,FU_LL.user_name                   --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  (  ----���̎擾�n�ȊO�̃f�[�^�͂��̓���SQL�őS�Ď擾����
           SELECT  XMRIH.mov_num                     --�ړ��ԍ�
                  ,XMRIL.line_number                 --���הԍ�
                  ,XMLD.record_type_code             --���R�[�h�^�C�v
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
                  ,XMLD.actual_date                  --���ѓ�
                  ,XMLD.actual_quantity              --���ѐ���
                  ,XMLD.before_actual_quantity       --�����O���ѐ���
                  ,XMLD.automanual_reserve_class
                   automanual_reserve_class_l        --���b�g_�����蓮�����敪
                  ,XMRIL.created_by                  --�쐬��
                  ,XMRIL.creation_date               --�쐬����
                  ,XMRIL.last_updated_by             --�ŏI�X�V��
                  ,XMRIL.last_update_date            --�X�V����
                  ,XMRIL.last_update_login           --�ŏI�X�V���O�C��
                  ,XMRIL.organization_id             --�g�DID(�g�D���擾�p)
                  ,NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date )
                                   arrival_date      --���ɓ�(�i�ڏ��擾�p)
             FROM  xxinv_mov_req_instr_lines   XMRIL --�ړ��˗�/�w�����׃A�h�I��
                  ,xxinv_mov_req_instr_headers XMRIH --�ړ��˗�/�w���w�b�_�A�h�I��
                  ,xxinv_mov_lot_details       XMLD  --�ړ����b�g�ڍ׃A�h�I��
                  ,ic_lots_mst                 ILM   --���b�g�}�X�^
            WHERE  XMRIL.mov_hdr_id           = XMRIH.mov_hdr_id(+)
              AND  NVL( XMRIL.delete_flg, 'N' ) <> 'Y'              --�������׈ȊO
              AND  XMRIL.mov_line_id          = XMLD.mov_line_id(+)
              AND  XMLD.document_type_code(+) = '20'
              AND  XMLD.item_id               = ILM.item_id(+)
              AND  XMLD.lot_id                = ILM.lot_id(+)
        )                            XILL            --�ړ����ׁ����b�g�ڍ׏��
       ,hr_all_organization_units_tl HAOUT           --�g�D���̃}�X�^
       ,xxsky_prod_class_v           XPCV            --SKYLINK�p ���i�敪�擾VIEW
       ,xxsky_item_class_v           XICV            --SKYLINK�p �i�ڋ敪�擾VIEW
       ,xxsky_crowd_code_v           XCCV            --SKYLINK�p �S�R�[�h�擾VIEW
       ,xxsky_item_mst2_v            XIMV            --SKYLINK�p����VIEW OPM�i�ڏ��VIEW
       ,fnd_lookup_values            FLV01           --�N�C�b�N�R�[�h(���R�[�h�^�C�v��)
       ,fnd_lookup_values            FLV02           --�N�C�b�N�R�[�h(�����蓮�����敪��)
       ,fnd_lookup_values            FLV03           --�N�C�b�N�R�[�h(����t���O��)
       ,fnd_lookup_values            FLV04           --�N�C�b�N�R�[�h(���b�g_�����蓮�����敪��)
       ,fnd_user                     FU_CB           --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                     FU_LU           --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                     FU_LL           --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                   FL_LL           --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
   --�g�D���擾����
        XILL.organization_id      = HAOUT.organization_id(+)
   AND  HAOUT.language(+)         = 'JA'
   --�i�ڏ��擾����
   AND  XILL.item_code            = XIMV.item_no(+)
   AND  XILL.arrival_date        >= XIMV.start_date_active(+)
   AND  XILL.arrival_date        <= XIMV.end_date_active(+)
   --�i�ڃJ�e�S�����擾����
   AND  XIMV.item_id              = XPCV.item_id(+)
   AND  XIMV.item_id              = XICV.item_id(+)
   AND  XIMV.item_id              = XCCV.item_id(+)
   --�N�C�b�N�R�[�h�F���R�[�h�^�C�v���擾
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXINV_RECORD_TYPE'
   AND  FLV01.lookup_code(+) = XILL.record_type_code
   --�N�C�b�N�R�[�h�F�����蓮�����敪���擾
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV02.lookup_code(+) = XILL.automanual_reserve_class
   --�N�C�b�N�R�[�h�F����t���O���擾
   AND  FLV03.language(+)    = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_YESNO'
   AND  FLV03.lookup_code(+) = XILL.delete_flg
   --�N�C�b�N�R�[�h�F���b�g_�����蓮�����敪���擾
   AND  FLV04.language(+)    = 'JA'
   AND  FLV04.lookup_type(+) = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV04.lookup_code(+) = XILL.automanual_reserve_class_l
   --WHO�J�����擾
   AND  XILL.created_by         = FU_CB.user_id(+)
   AND  XILL.last_updated_by    = FU_LU.user_id(+)
   AND  XILL.last_update_login  = FL_LL.login_id(+)
   AND  FL_LL.user_id           = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�ړ�����_��{_V IS 'SKYLINK�p�ړ����ׁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�ړ��ԍ� IS '�ړ��ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���הԍ� IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���R�[�h�^�C�v IS '���R�[�h�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���R�[�h�^�C�v�� IS '���R�[�h�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�g�D�� IS '�g�D��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�i�ڃR�[�h IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�i�ږ� IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�˗����� IS '�˗�����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�p���b�g�� IS '�p���b�g��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�i�� IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�P�[�X�� IS '�P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�w������ IS '�w������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�P�� IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�w�萻���� IS '�w�萻����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�p���b�g���� IS '�p���b�g����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�Q�ƈړ��ԍ� IS '�Q�ƈړ��ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�Q�Ɣ����ԍ� IS '�Q�Ɣ����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.����w������ IS '����w������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�o�Ɏ��ѐ��� IS '�o�Ɏ��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���Ɏ��ѐ��� IS '���Ɏ��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�d�� IS '�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�e�� IS '�e��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�p���b�g�d�� IS '�p���b�g�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�����蓮�����敪 IS '�����蓮�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�����蓮�����敪�� IS '�����蓮�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.����t���O IS '����t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.����t���O�� IS '����t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�x�����t IS '�x�����t'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�x���敪 IS '�x���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���b�gNO IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�����N���� IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�ŗL�L�� IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�ܖ����� IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���ѓ� IS '���ѓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���ѐ��� IS '���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�����O���ѐ��� IS '�����O���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���b�g_�����蓮�����敪 IS '���b�g_�����蓮�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.���b�g_�����蓮�����敪�� IS '���b�g_�����蓮�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ�����_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
