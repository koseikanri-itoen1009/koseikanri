/*************************************************************************
 * 
 * View  Name      : XXSKZ_��̃w�b�__��{_V
 * Description     : XXSKZ_��̃w�b�__��{_V
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------
 *  Date          Ver.  Editor          Description
 * ------------- ----- ---------------- -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai    ����쐬
 *  2013/03/19    1.1   SCSK D.Sugahara E_�{�ғ�_10479 �ۑ�20�Ή�
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_��̃w�b�__��{_V
(
 �o�b�`NO
,�v�����g�R�[�h
,�v�����g��
,���V�s
,���V�s����
,���V�s�E�v
,�t�H�[�~����
,�t�H�[�~��������
,�t�H�[�~�����E�v
,�t�H�[�~�������̂Q
,�t�H�[�~�����E�v�Q
,�H��
,�H������
,�H���E�v
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
,��̌�_���i�敪
,��̌�_���i�敪��
,��̌�_�i�ڋ敪
,��̌�_�i�ڋ敪��
,��̌�_�Q�R�[�h
,��̌�_�i�ڃR�[�h
,��̌�_�i�ڐ�����
,��̌�_�i�ڗ���
,��̌�_���b�gNO
,��̌�_�����N����
,��̌�_�ŗL�L��
,��̌�_�ܖ�������
,��̌�_�v�搔��
,��̌�_WIP�v�搔��
,��̌�_�I���W�i������
,��̌�_���ѐ���
,��̌�_�P��
,��̌�_��������
,��̌�_�����σt���O
,��̌�_�����σt���O��
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
        ,GRPB.recipe_no                                     -- ���V�s
        ,GRPT.recipe_description                            -- ���V�s����
        ,GRPT.recipe_description                            -- ���V�s�E�v
        ,FFMB.formula_no                                    -- �t�H�[�~����
        ,FFMT.formula_desc1                                 -- �t�H�[�~��������
        ,FFMT.formula_desc2                                 -- �t�H�[�~�������̂Q
        ,FFMT.formula_desc1                                 -- �t�H�[�~�����E�v
        ,FFMT.formula_desc2                                 -- �t�H�[�~�����E�v�Q
        ,GPROD.routing_no                                   -- �H��
        ,GRTT.routing_desc                                  -- �H���E�v
        ,GRTT.routing_desc                                  -- �H���E�v�Q
        ,GPROD.plan_start_date                              -- �v��J�n��
        ,GPROD.actual_start_date                            -- ���ъJ�n��
        ,GPROD.due_date                                     -- �K�{������
        ,GPROD.plan_cmplt_date                              -- �v�抮����
        ,GPROD.actual_cmplt_date                            -- ���ъ�����
        ,GPROD.batch_status                                 -- �o�b�`�X�e�[�^�X
        ,FLV01.meaning                                      -- �o�b�`�X�e�[�^�X��
        ,GPROD.wip_whse_code                                -- WIP�q��
        ,IWM.whse_name                                      -- WIP�q�ɖ�
        ,GPROD.batch_close_date                             -- �N���[�Y��
        ,GPROD.delete_mark                                  -- �폜�}�[�N
        -- ���Y����(��̌����)
        ,XPCV.prod_class_code                               -- ��̌�_���i�敪
        ,XPCV.prod_class_name                               -- ��̌�_���i�敪��
        ,XICV.item_class_code                               -- ��̌�_�i�ڋ敪
        ,XICV.item_class_name                               -- ��̌�_�i�ڋ敪��
        ,XCCV.crowd_code                                    -- ��̌�_�Q�R�[�h
        ,XIM2V.item_no                                      -- ��̌�_�i�ڃR�[�h
        ,XIM2V.item_name                                    -- ��̌�_�i�ڐ�����
        ,XIM2V.item_short_name                              -- ��̌�_�i�ڗ���
        ,NVL( DECODE( ILM.lot_no, 'DEFAULTLOT', '0', ILM.lot_no ), '0' )
                                        lot_no              --- ��̌�_���b�gNo('DEFALTLOT'�A���b�g��������'0')
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute1  --���b�g�Ǘ��i   �������N�������擾
              ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
         END                            manufacture_date    -- ��̌�_�����N����
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute2  --���b�g�Ǘ��i   ���ŗL�L�����擾
              ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
         END                            uniqe_sign          -- ��̌�_�ŗL�L��
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute3  --���b�g�Ǘ��i   ���ܖ����������擾
              ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
         END                            expiration_date     -- ��̌�_�ܖ�������
        ,ROUND( GPROD.plan_qty    , 3 )                     -- ��̌�_�v�搔��
        ,ROUND( GPROD.wip_plan_qty, 3 )                     -- ��̌�_WIP�v�搔��
        ,ROUND( GPROD.original_qty, 3 )                     -- ��̌�_�I���W�i������
        ,ROUND( GPROD.actual_qty  , 3 )                     -- ��̌�_���ѐ���
        ,GPROD.item_um                                      -- ��̌�_�P��
        ,GPROD.cost_alloc                                   -- ��̌�_��������
        ,GPROD.alloc_ind                                    -- ��̌�_�����σt���O
        ,CASE WHEN GPROD.alloc_ind = 0 THEN '������'
              WHEN GPROD.alloc_ind = 1 THEN '������'
         END                            alloc_ind_name      -- ��̌�_�����σt���O��
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
                ,GBH.recipe_validity_rule_id                -- ���V�s�Ó������[��
                ,GBH.formula_id                             -- �t�H�[�~����
                ,GBH.routing_id                             -- �H��
                ,GBH.plan_start_date                        -- �v��J�n��
                ,GBH.actual_start_date                      -- ���ъJ�n��
                ,GBH.due_date                               -- �K�{������
                ,GBH.plan_cmplt_date                        -- �v�抮����
                ,GBH.actual_cmplt_date                      -- ���ъ�����
                ,GBH.batch_status                           -- �o�b�`�X�e�[�^�X
                ,GBH.wip_whse_code                          -- WIP�q��
                ,GBH.batch_close_date                       -- �N���[�Y��
                ,GBH.delete_mark                            -- �폜�}�[�N
                -- ���Y����(��̌����)
                ,GMD.item_id                                -- ��̌�_���i�敪�A�i�ڋ敪�A�Q�R�[�h�A�i�ږ���
                ,ITP.lot_id                                 -- ��̌�_���b�gID
                ,GMD.plan_qty                               -- ��̌�_�v�搔��
                ,GMD.wip_plan_qty                           -- ��̌�_WIP�v�搔��
                ,GMD.original_qty                           -- ��̌�_�I���W�i������
                ,GMD.actual_qty                             -- ��̌�_���ѐ���
                ,GMD.item_um                                -- ��̌�_�P��
                ,GMD.cost_alloc                             -- ��̌�_��������
                ,GMD.alloc_ind                              -- ��̌�_�����σt���O
                ,GMD.created_by                             -- �쐬��
                ,GMD.creation_date                          -- �쐬��
                ,GMD.last_updated_by                        -- �ŏI�X�V��
                ,GMD.last_update_date                       -- �ŏI�X�V��
                ,GMD.last_update_login                      -- �ŏI�X�V���O�C��
                -- ���Y���H��
                ,GRB.routing_no                             -- �H��
                --���̎擾�p���
                ,NVL( TO_DATE( GBH.actual_cmplt_date ), TRUNC( GBH.plan_start_date ) )    --NVL( ���ъ�����, �v��J�n�� )
                                             act_date       -- ���{�� (�˕i�ږ��̎擾�Ŏg�p)
        FROM
--Mod 2013/3/19 V1.1 Start ��̃f�[�^���o�b�N�A�b�v�����܂ł͌��e�[�u���Q��
--                 xxcmn_gme_batch_header_arc      GBH            -- ���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
--                ,xxcmn_gme_material_details_arc  GMD            -- ���Y�����ڍׁi�W���j�o�b�N�A�b�v
                 gme_batch_header            GBH            -- ���Y�o�b�`
                ,gme_material_details        GMD            -- ���Y����(��̌����)
                ,gmd_routings_b                  GRB            -- �H���}�X�^
--                ,xxcmn_ic_tran_pnd_arc           ITP            -- OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                ,ic_tran_pnd                 ITP            -- �ۗ��݌Ƀg�����U�N�V����(���b�gID�擾�p)
--Mod 2013/3/19 V1.1 End
        WHERE
                -- �f�[�^�擾����
                    GBH.batch_type           = 0
                -- ��̌��i���ו���������
                AND GMD.line_type            = '-1'         -- ��̌�
                AND GBH.batch_id             = GMD.batch_id
                -- ���Y���擾����
                AND GRB.routing_class        IN ( '61', '62' )   -- ���
                AND GBH.routing_id           = GRB.routing_id
                --���b�gID�擾
                AND  ITP.doc_type(+)         = 'PROD'
                AND  ITP.delete_mark(+)      = 0
                AND  ITP.completed_ind(+)    = 1             --����
                AND  ITP.reverse_id(+)       IS NULL
                AND  GMD.material_detail_id  = ITP.line_id(+)
                AND  GMD.item_id             = ITP.item_id(+)
        )                               GPROD               -- ���Y�o�b�`�w�b�_�����Y����(��̌����)
        -- �ȉ��͏�LSQL�����̍��ڂ��g�p���ĊO���������s������(�G���[�����)
        ,sy_orgn_mst_tl                 SOMT                -- OPM�v�����g�}�X�^
        ,gmd_recipes_b                  GRPB                -- ���V�s�}�X�^
        ,gmd_recipes_tl                 GRPT                -- ���V�s�}�X�^
        ,gmd_recipe_validity_rules      GRPVR               -- ���V�s�Ó������[��
        ,fm_form_mst_b                  FFMB                -- �t�H�[�~�����}�X�^
        ,fm_form_mst_tl                 FFMT                -- �t�H�[�~�����}�X�^(����)
        ,gmd_routings_tl                GRTT                -- �H���}�X�^(����)
        ,ic_whse_mst                    IWM                 -- OPM�q�Ƀ}�X�^
        ,xxskz_prod_class_v             XPCV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(��̌�_���i�敪)
        ,xxskz_item_class_v             XICV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(��̌�_�i�ڋ敪)
        ,xxskz_crowd_code_v             XCCV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(��̌�_�Q�R�[�h)
        ,xxskz_item_mst2_v              XIM2V               -- SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(��̌�_�i�ږ�)
        ,ic_lots_mst                    ILM                 -- OPM���b�g�}�X�^(���b�gNo�擾�p)
        ,fnd_lookup_values              FLV01               -- �N�C�b�N�R�[�h�\(�o�b�`�X�e�[�^�X��)
        ,fnd_user                       FU_CB               -- ���[�U�[�}�X�^(CREATED_BY���̎擾�p)
        ,fnd_user                       FU_LU               -- ���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
        ,fnd_user                       FU_LL               -- ���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
        ,fnd_logins                     FL_LL               -- ���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
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
        -- ��̌�_���i�敪
   AND  GPROD.item_id                   = XPCV.item_id(+)
        -- ��̌�_�i�ڋ敪
   AND  GPROD.item_id                   = XICV.item_id(+)
        -- ��̌�_�Q�R�[�h
   AND  GPROD.item_id                   = XCCV.item_id(+)
        -- ��̌�_�i�ږ���
   AND  GPROD.item_id                   = XIM2V.item_id(+)
   AND  GPROD.act_date                 >= XIM2V.start_date_active(+)
   AND  GPROD.act_date                 <= XIM2V.end_date_active(+)
        -- ���b�g���擾
   AND  GPROD.item_id                   = ILM.item_id(+)
   AND  GPROD.lot_id                    = ILM.lot_id(+)
        -- �o�b�`�X�e�[�^�X��
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'GME_BATCH_STATUS'
   AND  FLV01.lookup_code(+)            = GPROD.batch_status
        -- ���[�U���Ȃ�
   AND  GPROD.created_by                = FU_CB.user_id(+)
   AND  GPROD.last_updated_by           = FU_LU.user_id(+)
   AND  GPROD.last_update_login         = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_��̃w�b�__��{_V IS 'SKYLINK�p��̃w�b�_�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�o�b�`NO              IS '�o�b�`NO'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�v�����g�R�[�h        IS '�v�����g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�v�����g��            IS '�v�����g��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.���V�s                IS '���V�s'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.���V�s����            IS '���V�s����'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.���V�s�E�v            IS '���V�s�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�t�H�[�~����          IS '�t�H�[�~����'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�t�H�[�~��������      IS '�t�H�[�~��������'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�t�H�[�~�������̂Q    IS '�t�H�[�~�������̂Q'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�t�H�[�~�����E�v      IS '�t�H�[�~�����E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�t�H�[�~�����E�v�Q    IS '�t�H�[�~�����E�v�Q'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�H��                  IS '�H��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�H������              IS '�H������'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�H���E�v              IS '�H���E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�v��J�n��            IS '�v��J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.���ъJ�n��            IS '���ъJ�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�K�{������            IS '�K�{������'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�v�抮����            IS '�v�抮����'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.���ъ�����            IS '���ъ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�o�b�`�X�e�[�^�X      IS '�o�b�`�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�o�b�`�X�e�[�^�X��    IS '�o�b�`�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.WIP�q��               IS 'WIP�q��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.WIP�q�ɖ�             IS 'WIP�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�N���[�Y��            IS '�N���[�Y��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�폜�}�[�N            IS '�폜�}�[�N'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_���i�敪       IS '��̌�_���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_���i�敪��     IS '��̌�_���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�i�ڋ敪       IS '��̌�_�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�i�ڋ敪��     IS '��̌�_�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�Q�R�[�h       IS '��̌�_�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�i�ڃR�[�h     IS '��̌�_�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�i�ڐ�����     IS '��̌�_�i�ڐ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�i�ڗ���       IS '��̌�_�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_���b�gNO       IS '��̌�_���b�gNO'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�����N����     IS '��̌�_�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�ŗL�L��       IS '��̌�_�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�ܖ�������     IS '��̌�_�ܖ�������'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�v�搔��       IS '��̌�_�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_WIP�v�搔��    IS '��̌�_WIP�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�I���W�i������ IS '��̌�_�I���W�i������'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_���ѐ���       IS '��̌�_���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�P��           IS '��̌�_�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_��������       IS '��̌�_��������'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�����σt���O   IS '��̌�_�����σt���O'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.��̌�_�����σt���O�� IS '��̌�_�����σt���O��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�쐬��                IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�쐬��                IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�ŏI�X�V��            IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�ŏI�X�V��            IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_��̃w�b�__��{_V.�ŏI�X�V���O�C��      IS '�ŏI�X�V���O�C��'
/
