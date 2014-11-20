CREATE OR REPLACE VIEW APPS.XXSKY_��̖���_��{_V
(
�o�b�`NO
,�v�����g�R�[�h
,�v�����g��
,���C��NO
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ڐ�����
,�i�ڗ���
,���b�gNO
,�����N����
,�ŗL�L��
,�ܖ�������
,�v�搔��
,WIP�v�搔��
,�I���W�i������
,���ѐ���
,�P��
,��������
,�����σt���O
,�����σt���O��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        -- ���Y�o�b�`�w�b�_
         GPROD.batch_no                                     -- �o�b�`No
        ,GPROD.plant_code                                   -- �v�����g�R�[�h
        ,SOMT.orgn_name                                     -- �v�����g��
        -- ���Y���� ��̌��ȊO(��̐�)�̏��
        ,GPROD.line_no                                      -- ���C��No
        ,XPCV.prod_class_code                               -- ���i�敪
        ,XPCV.prod_class_name                               -- ���i�敪��
        ,XICV.item_class_code                               -- �i�ڋ敪
        ,XICV.item_class_name                               -- �i�ڋ敪��
        ,XCCV.crowd_code                                    -- �Q�R�[�h
        ,XIM2V.item_no                                      -- �i�ڃR�[�h
        ,XIM2V.item_name                                    -- �i�ڐ�����
        ,XIM2V.item_short_name                              -- �i�ڗ���
        ,NVL( DECODE( ILM.lot_no, 'DEFAULTLOT', '0', ILM.lot_no ), '0' )
                                        lot_no              -- ���b�gNo('DEFALTLOT'�A���b�g��������'0')
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute1  --���b�g�Ǘ��i   �������N�������擾
              ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
         END                            manufacture_date    -- �����N����
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute2  --���b�g�Ǘ��i   ���ŗL�L�����擾
              ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
         END                            uniqe_sign          -- �ŗL�L��
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute3  --���b�g�Ǘ��i   ���ܖ����������擾
              ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
         END                            expiration_date     -- �ܖ�������
        ,ROUND( GPROD.plan_qty    , 3 )                     -- �v�搔��
        ,ROUND( GPROD.wip_plan_qty, 3 )                     -- WIP�v�搔��
        ,ROUND( GPROD.original_qty, 3 )                     -- �I���W�i������
        ,ROUND( GPROD.actual_qty  , 3 )                     -- ���ѐ���
        ,GPROD.item_um                                      -- �P��
        ,GPROD.cost_alloc                                   -- ��������
        ,GPROD.alloc_ind                                    -- �����σt���O
        ,CASE WHEN GPROD.alloc_ind = 0 THEN '������'
              WHEN GPROD.alloc_ind = 1 THEN '������'
         END                            alloc_ind_name      -- �����σt���O��
        -- ���[�U���
        ,FU_CB.user_name                                    -- �쐬��
        ,TO_CHAR( GPROD.creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                            -- �쐬��
        ,FU_LU.user_name                                    -- �ŏI�X�V��
        ,TO_CHAR( GPROD.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            -- �ŏI�X�V��
        ,FU_LL.user_name                                    -- �ŏI�X�V���O�C��
FROM
        -- ���̎擾�n�ȊO�̃f�[�^�͂��̓���SQL�őS�Ď擾����
        ( SELECT
                -- ���Y�o�b�`�w�b�_
                 GBH.batch_no                               -- �o�b�`No
                ,GBH.plant_code                             -- �v�����g�R�[�h
                ,GBH.plan_start_date                        -- ���v��J�n��(�O�������p)
                -- ���Y���� �����i�ȊO(�����A���Y��)�̏��
                ,GMD.line_no                                -- ���C��No
                ,GMD.plan_qty                               -- �v�搔��
                ,GMD.wip_plan_qty                           -- WIP�v�搔��
                ,GMD.original_qty                           -- �I���W�i������
                ,GMD.actual_qty                             -- ���ѐ���
                ,GMD.item_um                                -- �P��
                ,GMD.cost_alloc                             -- ��������
                ,GMD.alloc_ind                              -- �����σt���O
                ,GMD.created_by                             -- �쐬��
                ,GMD.creation_date                          -- �쐬��
                ,GMD.last_updated_by                        -- �ŏI�X�V��
                ,GMD.last_update_date                       -- �ŏI�X�V��
                ,GMD.last_update_login                      -- �ŏI�X�V���O�C��
                ,GMD.item_id                                -- ��̐�_���i�敪�A�i�ڋ敪�A�Q�R�[�h�A�i�ږ���(�O�������p)
                ,ITP.lot_id                                 -- ��̐�_���b�gID
                --���̎擾�p���
                ,NVL( TO_DATE( GBH.actual_cmplt_date ), TRUNC( GBH.plan_start_date ) )    --NVL( ���ъ�����, �v��J�n�� )
                                             act_date       -- ���{�� (�˕i�ږ��̎擾�Ŏg�p)
        FROM
                 gme_batch_header            GBH            -- ���Y�o�b�`
                ,gme_material_details        GMD            -- ���Y�����ڍ�(��̐���)
                ,gmd_routings_b              GRB            -- �H���}�X�^
                ,ic_tran_pnd                 ITP            -- �ۗ��݌Ƀg�����U�N�V����(���b�gID�擾�p)
        WHERE
                -- �w�b�_�e�[�u���Ƃ̌���
                    GBH.batch_type           = 0
                AND GBH.batch_id             = GMD.batch_id
                -- �w�����i�ȊO�i�����A���Y���j�x�̖��ו��擾
                AND GMD.line_type           <> '-1'         -- ��̌��ȊO
                -- �H��(���Y���擾)
                AND GRB.routing_class        IN ( '61', '62' )   -- ���
                AND GBH.routing_id           = GRB.routing_id
                --���b�gID�擾
                AND  ITP.doc_type(+)         = 'PROD'
                AND  ITP.delete_mark(+)      = 0
                AND  ITP.completed_ind(+)    = 1             --����
                AND  ITP.reverse_id(+)       IS NULL
                AND  GMD.material_detail_id  = ITP.line_id(+)
                AND  GMD.item_id             = ITP.item_id(+)
        )                               GPROD               -- ���Y�o�b�`�w�b�_�����Y����(�����i���)
        -- �ȉ��͏�LSQL�����̍��ڂ��g�p���ĊO���������s������(�G���[�����)
        ,sy_orgn_mst_tl                 SOMT                -- OPM�v�����g�}�X�^
        ,xxsky_prod_class_v             XPCV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(���i�敪)
        ,xxsky_item_class_v             XICV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�i�ڋ敪)
        ,xxsky_crowd_code_v             XCCV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�Q�R�[�h)
        ,xxsky_item_mst2_v              XIM2V               -- SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ږ�)
        ,ic_lots_mst                    ILM                 -- OPM���b�g�}�X�^(���b�gNo�擾�p)
        ,fnd_user                       FU_CB               -- ���[�U�[�}�X�^(CREATED_BY���̎擾�p)
        ,fnd_user                       FU_LU               -- ���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
        ,fnd_user                       FU_LL               -- ���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
        ,fnd_logins                     FL_LL               -- ���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
        -- �v�����g��
        SOMT.language(+)                = 'JA'
   AND  GPROD.plant_code                = SOMT.orgn_code(+)
        -- �����i_���i�敪
   AND  GPROD.item_id                   = XPCV.item_id(+)
        -- �����i_�i�ڋ敪
   AND  GPROD.item_id                   = XICV.item_id(+)
        -- �����i_�Q�R�[�h
   AND  GPROD.item_id                   = XCCV.item_id(+)
        -- �����i_�i�ږ���
   AND  GPROD.item_id                   = XIM2V.item_id(+)
   AND  GPROD.act_date                 >= XIM2V.start_date_active(+)
   AND  GPROD.act_date                 <= XIM2V.end_date_active(+)
        -- ���b�g���擾
   AND  GPROD.item_id                   = ILM.item_id(+)
   AND  GPROD.lot_id                    = ILM.lot_id(+)
        -- ���[�U���Ȃ�
   AND  GPROD.created_by                = FU_CB.user_id(+)
   AND  GPROD.last_updated_by           = FU_LU.user_id(+)
   AND  GPROD.last_update_login         = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_��̖���_��{_V IS 'SKYLINK�p��̖��ׁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�o�b�`NO           IS '�o�b�`No'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�v�����g�R�[�h     IS '�v�����g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�v�����g��         IS '�v�����g��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.���C��NO           IS '���C��No'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.���i�敪           IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.���i�敪��         IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�i�ڋ敪           IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�i�ڋ敪��         IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�Q�R�[�h           IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�i�ڃR�[�h         IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�i�ڐ�����         IS '�i�ڐ�����'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�i�ڗ���           IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.���b�gNO           IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�����N����         IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�ŗL�L��           IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�ܖ�������         IS '�ܖ�������'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�v�搔��           IS '�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.WIP�v�搔��        IS 'WIP�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�I���W�i������     IS '�I���W�i������'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.���ѐ���           IS '���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�P��               IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.��������           IS '��������'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�����σt���O       IS '�����σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�����σt���O��     IS '�����σt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_��̖���_��{_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/
