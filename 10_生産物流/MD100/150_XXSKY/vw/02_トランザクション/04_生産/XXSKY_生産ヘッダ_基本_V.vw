CREATE OR REPLACE VIEW APPS.XXSKY_���Y�w�b�__��{_V
(
 �o�b�`NO
,�v�����g�R�[�h
,�v�����g��
,���V�s
,���V�s����
,���V�s�E�v
,�t�H�[�~����
,�t�H�[�~��������
,�t�H�[�~�������̂Q
,�t�H�[�~�����E�v
,�t�H�[�~�����E�v�Q
,�H��
,�H������
,�H���E�v
,�Ɩ��X�e�[�^�X
,�Ɩ��X�e�[�^�X��
,���M�ς݃t���O
,���M�ς݃t���O��
,�v��J�n��
,���ъJ�n��
,�K�{������
,�v�抮����
,���ъ�����
,�o�b�`�X�e�[�^�X
,�o�b�`�X�e�[�^�X��
,WIP�q��
,WIP�q�ɖ�
,�N���[�Y��
,�폜�}�[�N
,�`�[�敪
,���ъǗ�����
,���`�[�ԍ�
,�����i_���i�敪
,�����i_���i�敪��
,�����i_�i�ڋ敪
,�����i_�i�ڋ敪��
,�����i_�Q�R�[�h
,�����i_�i�ڃR�[�h
,�����i_�i�ڐ�����
,�����i_�i�ڗ���
,�����i_���b�gNO
,�����i_�^�C�v
,�����i_�^�C�v��
,�����i_�����N����
,�����i_�ŗL�L��
,�����i_�ܖ�������
,�����i_���Y��
,�����i_�������ɓ�
,�����i_�v�搔��
,�����i_WIP�v�搔��
,�����i_�I���W�i������
,�����i_���ѐ���
,�����i_�P��
,�����i_��������
,�����i_�����σt���O
,�����i_�����σt���O��
,�����i_�����N�P
,�����i_�����N�Q
,�����i_�����N�R
,�����i_�E�v
,�����i_�݌ɓ���
,�����i_�˗�����
,�����i_�w�}����
,�����i_�ϑ����H�P��
,�����i_�ϑ����H��
,�����i_���̑����z
,�����i_�v�Z�敪
,�����i_�v�Z�敪��
,�����i_�ړ��ꏊ�R�[�h
,�����i_�ړ��ꏊ��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        -- ���Y�o�b�`�w�b�_
        GPROD.batch_no                                           -- �o�b�`No
       ,GPROD.plant_code                                         -- �v�����g�R�[�h
       ,SOMT.orgn_name                                           -- �v�����g��
       ,GRPB.recipe_no                                           -- ���V�s
       ,GRPT.recipe_description                                  -- ���V�s����
       ,GRPT.recipe_description                                  -- ���V�s�E�v
       ,FFMB.formula_no                                          -- �t�H�[�~����
       ,FFMT.formula_desc1                                       -- �t�H�[�~��������
       ,FFMT.formula_desc2                                       -- �t�H�[�~�������̂Q
       ,FFMT.formula_desc1                                       -- �t�H�[�~�����E�v
       ,FFMT.formula_desc2                                       -- �t�H�[�~�����E�v�Q
       ,GPROD.routing_no                                         -- �H��
       ,GRTT.routing_desc                                        -- �H������
       ,GRTT.routing_desc                                        -- �H���E�v
       ,GPROD.hattr4                                             -- �Ɩ��X�e�[�^�X
       ,FLV01.meaning                                            -- �Ɩ��X�e�[�^�X��
       ,GPROD.hattr3                                             -- ���M�ς݃t���O
       ,FLV02.meaning                                            -- ���M�ς݃t���O��
       ,GPROD.plan_start_date                                    -- �v��J�n��
       ,GPROD.actual_start_date                                  -- ���ъJ�n��
       ,GPROD.due_date                                           -- �K�{������
       ,GPROD.plan_cmplt_date                                    -- �v�抮����
       ,GPROD.actual_cmplt_date                                  -- ���ъ�����
       ,GPROD.batch_status                                       -- �o�b�`�X�e�[�^�X
       ,FLV03.meaning                                            -- �o�b�`�X�e�[�^�X��
       ,GPROD.wip_whse_code                                      -- WIP�q��
       ,IWM.whse_name                                            -- WIP�q�ɖ�
       ,GPROD.batch_close_date                                   -- �N���[�Y��
       ,GPROD.delete_mark                                        -- �폜�}�[�N
       ,GPROD.hattr1                                             -- �`�[�敪
       ,GPROD.hattr2                                             -- ���ъǗ�����
       ,GPROD.hattr5                                             -- ���`�[�ԍ�
        -- ���Y����(�����i���)
       ,XPCV.prod_class_code                                     -- �����i_���i�敪
       ,XPCV.prod_class_name                                     -- �����i_���i�敪��
       ,XICV.item_class_code                                     -- �����i_�i�ڋ敪
       ,XICV.item_class_name                                     -- �����i_�i�ڋ敪��
       ,XCCV.crowd_code                                          -- �����i_�Q�R�[�h
       ,XIM2V.item_no                                            -- �����i_�i�ڃR�[�h
       ,XIM2V.item_name                                          -- �����i_�i�ڐ�����
       ,XIM2V.item_short_name                                    -- �����i_�i�ڗ���
       ,NVL( DECODE( ILM.lot_no, 'DEFAULTLOT', '0', ILM.lot_no ), '0' )
                                             lot_no              -- �����i_���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,GPROD.dattr1                                             -- �����i_�^�C�v
       ,FLV04.meaning                                            -- �����i_�^�C�v��
       ,GPROD.dattr17                                            -- �����i_�����N����
       ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute2    --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                     --�񃍃b�g�Ǘ��i ��NULL
        END                                  uniqe_sign          -- �����i_�ŗL�L��
       ,GPROD.dattr10                                            -- �����i_�ܖ�������
       ,GPROD.dattr11                                            -- �����i_���Y��
       ,GPROD.dattr22                                            -- �����i_�������ɓ�
       ,ROUND( GPROD.plan_qty    , 3 )                           -- �����i_�v�搔��
       ,ROUND( GPROD.wip_plan_qty, 3 )                           -- �����i_WIP�v�搔��
       ,ROUND( GPROD.original_qty, 3 )                           -- �����i_�I���W�i������
       ,ROUND( GPROD.actual_qty  , 3 )                           -- �����i_���ѐ���
       ,GPROD.item_um                                            -- �����i_�P��
       ,GPROD.cost_alloc                                         -- �����i_��������
       ,GPROD.alloc_ind                                          -- �����i_�����σt���O
       ,CASE WHEN GPROD.alloc_ind = 0 THEN '������'
             WHEN GPROD.alloc_ind = 1 THEN '������'
        END                                  alloc_ind_name      -- �����i_�����σt���O��
       ,GPROD.dattr2                                             -- �����i_�����N1
       ,GPROD.dattr3                                             -- �����i_�����N2
       ,GPROD.dattr26                                            -- �����i_�����N3
       ,GPROD.dattr4                                             -- �����i_�E�v
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr6  ), 3 ), 0 )         -- �����i_�݌ɓ���
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr7  ), 3 ), 0 )         -- �����i_�˗�����
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr23 ), 3 ), 0 )         -- �����i_�w�}����
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr9  ), 3 ), 0 )         -- �����i_�ϑ����H�P��
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr15 ), 3 ), 0 )         -- �����i_�ϑ����H��
       ,NVL( ROUND( TO_NUMBER( GPROD.dattr16 ), 3 ), 0 )         -- �����i_���̑����z
       ,GPROD.dattr14                                            -- �����i_�v�Z�敪
       ,FLV05.meaning                                            -- �����i_�v�Z�敪��
       ,GPROD.dattr12                                            -- �����i_�ړ��ꏊ�R�[�h
       ,XILV01.description                                       -- �����i_�ړ��ꏊ��
       -- ���[�U���
       ,FU_CB.user_name                                          -- �쐬��
       ,TO_CHAR( GPROD.creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                                 -- �쐬��
       ,FU_LU.user_name                                          -- �ŏI�X�V��
       ,TO_CHAR( GPROD.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                                 -- �ŏI�X�V��
       ,FU_LL.user_name                                          -- �ŏI�X�V���O�C��
FROM
        -- ���̎擾�n�ȊO�̃f�[�^�͂��̓���SQL�őS�Ď擾����
        ( SELECT
                -- ���Y�o�b�`�w�b�_
                GBH.batch_no                                     -- �o�b�`No
               ,GBH.routing_id                                   -- �H��
               ,GRTB.routing_no                                  -- �H��No
               ,GBH.plant_code                                   -- �v�����g�R�[�h
               ,GBH.recipe_validity_rule_id                      -- ���V�s�Ó������[��
               ,GBH.formula_id                                   -- �t�H�[�~������
               ,GBH.attribute4                    HATTR4         -- �Ɩ��X�e�[�^�X
               ,GBH.attribute3                    HATTR3         -- ���M�ς݃t���O
               ,GBH.plan_start_date                              -- �v��J�n��
               ,GBH.actual_start_date                            -- ���ъJ�n��
               ,GBH.due_date                                     -- �K�{������
               ,GBH.plan_cmplt_date                              -- �v�抮����
               ,GBH.actual_cmplt_date                            -- ���ъ�����
               ,GBH.batch_status                                 -- �o�b�`�X�e�[�^�X
               ,GBH.wip_whse_code                                -- WIP�q��
               ,GBH.batch_close_date                             -- �N���[�Y��
               ,GBH.delete_mark                                  -- �폜�}�[�N
               ,GBH.attribute1                    HATTR1         -- �`�[�敪
               ,GBH.attribute2                    HATTR2         -- ���ъǗ�����
               ,GBH.attribute5                    HATTR5         -- ���`�[�ԍ�
                -- ���Y����(�����i���)
               ,GMD.item_id                                      -- �����i_���i�敪�A�i�ڋ敪�A�Q�R�[�h�A�i�ږ���
               ,ITP.lot_id                                       -- �����i_���b�gID
               ,GMD.attribute1                    DATTR1         -- �����i_�^�C�v
               ,GMD.attribute17                   DATTR17        -- �����i_�����N����
               ,GMD.attribute10                   DATTR10        -- �����i_�ܖ�������
               ,GMD.attribute11                   DATTR11        -- �����i_���Y��
               ,GMD.attribute22                   DATTR22        -- �����i_�������ɓ�
               ,GMD.plan_qty                                     -- �����i_�v�搔��
               ,GMD.wip_plan_qty                                 -- �����i_WIP�v�搔��
               ,GMD.original_qty                                 -- �����i_�I���W�i������
               ,GMD.actual_qty                                   -- �����i_���ѐ���
               ,GMD.item_um                                      -- �����i_�P��
               ,GMD.cost_alloc                                   -- �����i_��������
               ,GMD.alloc_ind                                    -- �����i_�����σt���O
               ,GMD.attribute2                    DATTR2         -- �����i_�����N1
               ,GMD.attribute3                    DATTR3         -- �����i_�����N2
               ,GMD.attribute26                   DATTR26        -- �����i_�����N3
               ,GMD.attribute4                    DATTR4         -- �����i_�E�v
               ,GMD.attribute6                    DATTR6         -- �����i_�݌ɓ���
               ,GMD.attribute7                    DATTR7         -- �����i_�˗�����
               ,GMD.attribute23                   DATTR23        -- �����i_�w�}����
               ,GMD.attribute9                    DATTR9         -- �����i_�ϑ����H�P��
               ,GMD.attribute15                   DATTR15        -- �����i_�ϑ����H��
               ,GMD.attribute16                   DATTR16        -- �����i_���̑����z
               ,GMD.attribute14                   DATTR14        -- �����i_�v�Z�敪
               ,GMD.attribute12                   DATTR12        -- �����i_�ړ��ꏊ�R�[�h
               ,GMD.created_by                                   -- �쐬��
               ,GMD.creation_date                                -- �쐬��(�x���˗����IF����)
               ,GMD.last_updated_by                              -- �ŏI�X�V��
               ,GMD.last_update_date                             -- �ŏI�X�V��(�x���˗����IF����)
               ,GMD.last_update_login                            -- �ŏI�X�V���O�C��
                --���̎擾�p���
-- 2016/06/21 S.Yamashita Mod Start
--               ,NVL( TO_DATE( GMD.attribute11 ), TRUNC( GBH.plan_start_date ) )    --NVL( ���Y��, �v��J�n�� )
               ,NVL( TO_DATE( GMD.attribute11,'YYYY/MM/DD' ), TRUNC( GBH.plan_start_date ) )    --NVL( ���Y��, �v��J�n�� )
-- 2016/06/21 S.Yamashita Mod End
                                                  act_date       -- ���Y�� (�˕i�ږ��̎擾�Ŏg�p)
          FROM
                 gme_batch_header            GBH                 -- ���Y�o�b�`
                ,gmd_routings_b              GRTB                -- �H���}�X�^
                ,gme_material_details        GMD                 -- ���Y�����ڍ�(�����i���)
                ,ic_tran_pnd                 ITP                 -- �ۗ��݌Ƀg�����U�N�V����
         WHERE
                -- �f�[�^�擾����
                GBH.batch_type               = 0
           AND  GBH.attribute4              <> '-1'              -- �Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                -- �H��(���Y���擾)
           AND  GRTB.routing_class           NOT IN ( '61', '62', '70' )     -- �i�ڐU��(70)�A���(61,62) �ȊO
           AND  GBH.routing_id               = GRTB.routing_id
                -- �����i���ו���������
           AND  GBH.batch_id                 = GMD.batch_id
           AND  GMD.line_type                = '1'               -- �����i
                -- ���b�gID�擾
           AND  ITP.doc_type(+)              = 'PROD'
           AND  ITP.delete_mark(+)           = 0
           AND  ITP.reverse_id(+)            IS NULL
           AND  ITP.lot_id(+)               <> 0                 --�w���ށx�͗L�蓾�Ȃ�
           AND  GMD.material_detail_id       = ITP.line_id(+)
           AND  GMD.item_id                  = ITP.item_id(+)
        )                               GPROD               -- ���Y�o�b�`�w�b�_�����Y����(�����i���)
        -- �ȉ��͏�LSQL�����̍��ڂ��g�p���ĊO���������s������(�G���[�����)
       ,sy_orgn_mst_tl                  SOMT                -- OPM�v�����g�}�X�^
       ,gmd_recipes_b                   GRPB                -- ���V�s�}�X�^
       ,gmd_recipes_tl                  GRPT                -- ���V�s�}�X�^(���{��)
       ,gmd_recipe_validity_rules       GRPVR               -- �����V�s�Ó������[��(WHERE��̂�)
       ,fm_form_mst_b                   FFMB                -- �t�H�[�~�����}�X�^
       ,fm_form_mst_tl                  FFMT                -- �t�H�[�~�����}�X�^(����)
       ,gmd_routings_tl                 GRTT                -- �H���}�X�^(����)
       ,ic_whse_mst                     IWM                 -- OPM�q�Ƀ}�X�^
       ,xxsky_prod_class_v              XPCV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�����i_���i�敪)
       ,xxsky_item_class_v              XICV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�����i_�i�ڋ敪)
       ,xxsky_crowd_code_v              XCCV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�����i_�Q�R�[�h)
       ,xxsky_item_mst2_v               XIM2V               -- SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�����i_�i�ږ�)
       ,ic_lots_mst                     ILM                 -- OPM���b�g�}�X�^
       ,fnd_lookup_values               FLV01               -- �N�C�b�N�R�[�h�\(�Ɩ��X�e�[�^�X��)
       ,fnd_lookup_values               FLV02               -- �N�C�b�N�R�[�h�\(���M�ς݃t���O��)
       ,fnd_lookup_values               FLV03               -- �N�C�b�N�R�[�h�\(�o�b�`�X�e�[�^�X��)
       ,fnd_lookup_values               FLV04               -- �N�C�b�N�R�[�h�\(�����i_�^�C�v��)
       ,fnd_lookup_values               FLV05               -- �N�C�b�N�R�[�h�\(�����i_�v�Z�敪��)
       ,xxsky_item_locations_v          XILV01              -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(�����i_�ړ��ꏊ��)
       ,fnd_user                        FU_CB               -- ���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                        FU_LU               -- ���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                        FU_LL               -- ���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                      FL_LL               -- ���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
        -- �v�����g��
        SOMT.language(+)                = 'JA'
   AND  GPROD.plant_code                = SOMT.orgn_code(+)
        -- ���V�s��
   AND  GPROD.recipe_validity_rule_id   = GRPVR.recipe_validity_rule_id(+)
   AND  GRPVR.recipe_id                 = GRPB.recipe_id(+)
   AND  GRPVR.recipe_id                 = GRPT.recipe_id(+)
   AND  GRPT.language(+)                = 'JA'
        -- �t�H�[�~������
   AND  GPROD.formula_id                = FFMB.formula_id(+)
   AND  FFMT.language(+)                = 'JA'
   AND  FFMB.formula_id                 = FFMT.formula_id(+)
        -- �H����
   AND  GRTT.language(+)                = 'JA'
   AND  GPROD.routing_id                = GRTT.routing_id(+)
        -- WIP�q�ɖ�
   AND  GPROD.wip_whse_code             = IWM.whse_code(+)
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
        -- �����i���b�g���
   AND  GPROD.item_id                   = ILM.item_id(+)
   AND  GPROD.lot_id                    = ILM.lot_id(+)
        -- �����i_�ړ��ꏊ
   AND  GPROD.dattr12                   = XILV01.segment1(+)
        -- ���[�U���Ȃ�
   AND  GPROD.created_by                = FU_CB.user_id(+)
   AND  GPROD.last_updated_by           = FU_LU.user_id(+)
   AND  GPROD.last_update_login         = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
        -- �y�N�C�b�N�R�[�h�z�Ɩ��X�e�[�^�X��
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXWIP_DUTY_STATUS'
   AND  FLV01.lookup_code(+)            = GPROD.hattr4
        -- �y�N�C�b�N�R�[�h�z���M�ς݃t���O��
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV02.lookup_code(+)            = GPROD.hattr3
        -- �y�N�C�b�N�R�[�h�z�o�b�`�X�e�[�^�X��
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'GME_BATCH_STATUS'
   AND  FLV03.lookup_code(+)            = GPROD.batch_status
        -- �y�N�C�b�N�R�[�h�z�����i_�^�C�v��
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXCMN_L08'
   AND  FLV04.lookup_code(+)            = GPROD.dattr1
        -- �y�N�C�b�N�R�[�h�z�����i_�v�Z�敪��
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXWIP_CALCULATE_TYPE'
   AND  FLV05.lookup_code(+)            = GPROD.dattr14
/
COMMENT ON TABLE APPS.XXSKY_���Y�w�b�__��{_V IS 'SKYLINK�p���Y�w�b�_�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�o�b�`NO              IS '�o�b�`No'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�v�����g�R�[�h        IS '�v�����g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�v�����g��            IS '�v�����g��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.���V�s                IS '���V�s'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.���V�s����            IS '���V�s����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.���V�s�E�v            IS '���V�s�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�t�H�[�~����          IS '�t�H�[�~����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�t�H�[�~��������      IS '�t�H�[�~��������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�t�H�[�~�������̂Q    IS '�t�H�[�~�������̂Q'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�t�H�[�~�����E�v      IS '�t�H�[�~�����E�v'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�t�H�[�~�����E�v�Q    IS '�t�H�[�~�����E�v�Q'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�H��                  IS '�H��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�H������              IS '�H������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�H���E�v              IS '�H���E�v'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�Ɩ��X�e�[�^�X        IS '�Ɩ��X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�Ɩ��X�e�[�^�X��      IS '�Ɩ��X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.���M�ς݃t���O        IS '���M�ς݃t���O'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.���M�ς݃t���O��      IS '���M�ς݃t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�v��J�n��            IS '�v��J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.���ъJ�n��            IS '���ъJ�n��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�K�{������            IS '�K�{������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�v�抮����            IS '�v�抮����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.���ъ�����            IS '���ъ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�o�b�`�X�e�[�^�X      IS '�o�b�`�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�o�b�`�X�e�[�^�X��    IS '�o�b�`�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.WIP�q��               IS 'WIP�q��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.WIP�q�ɖ�             IS 'WIP�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�N���[�Y��            IS '�N���[�Y��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�폜�}�[�N            IS '�폜�}�[�N'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�`�[�敪              IS '�`�[�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.���ъǗ�����          IS '���ъǗ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.���`�[�ԍ�            IS '���`�[�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_���i�敪       IS '�����i_���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_���i�敪��     IS '�����i_���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�i�ڋ敪       IS '�����i_�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�i�ڋ敪��     IS '�����i_�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�Q�R�[�h       IS '�����i_�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�i�ڃR�[�h     IS '�����i_�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�i�ڐ�����     IS '�����i_�i�ڐ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�i�ڗ���       IS '�����i_�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_���b�gNO       IS '�����i_���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�^�C�v         IS '�����i_�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�^�C�v��       IS '�����i_�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�����N����     IS '�����i_�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�ŗL�L��       IS '�����i_�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�ܖ�������     IS '�����i_�ܖ�������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_���Y��         IS '�����i_���Y��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�������ɓ�     IS '�����i_�������ɓ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�v�搔��       IS '�����i_�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_WIP�v�搔��    IS '�����i_WIP�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�I���W�i������ IS '�����i_�I���W�i������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_���ѐ���       IS '�����i_���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�P��           IS '�����i_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_��������       IS '�����i_��������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�����σt���O   IS '�����i_�����σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�����σt���O�� IS '�����i_�����σt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�����N�P       IS '�����i_�����N�P'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�����N�Q       IS '�����i_�����N�Q'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�����N�R       IS '�����i_�����N�R'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�E�v           IS '�����i_�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�݌ɓ���       IS '�����i_�݌ɓ���'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�˗�����       IS '�����i_�˗�����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�w�}����       IS '�����i_�w�}����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�ϑ����H�P��   IS '�����i_�ϑ����H�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�ϑ����H��     IS '�����i_�ϑ����H��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_���̑����z     IS '�����i_���̑����z'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�v�Z�敪       IS '�����i_�v�Z�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�v�Z�敪��     IS '�����i_�v�Z�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�ړ��ꏊ�R�[�h IS '�����i_�ړ��ꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�����i_�ړ��ꏊ��     IS '�����i_�ړ��ꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�쐬��                IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�쐬��                IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�ŏI�X�V��            IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�ŏI�X�V��            IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y�w�b�__��{_V.�ŏI�X�V���O�C��      IS '�ŏI�X�V���O�C��'
/
