CREATE OR REPLACE VIEW APPS.XXSKY_�i�ڐU�֏��_��{_V
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
,�i�ڐU�֖���
,�i�ڐU�֓E�v
,�i�ڐU�֖ړI
,�i�ڐU�֖ړI��
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
,���o_���i�敪
,���o_���i�敪��
,���o_�i�ڋ敪
,���o_�i�ڋ敪��
,���o_�Q�R�[�h
,���o_�i�ڃR�[�h
,���o_�i�ڐ�����
,���o_�i�ڗ���
,���o_���b�gNO
,���o_�����N����
,���o_�ŗL�L��
,���o_�ܖ�������
,���o_�v�搔��
,���o_WIP�v�搔��
,���o_�I���W�i������
,���o_���ѐ���
,���o_�P��
,���o_��������
,���o_�����σt���O
,���o_�����σt���O��
,���_���i�敪
,���_���i�敪��
,���_�i�ڋ敪
,���_�i�ڋ敪��
,���_�Q�R�[�h
,���_�i�ڃR�[�h
,���_�i�ڐ�����
,���_�i�ڗ���
,���_���b�gNO
,���_�����N����
,���_�ŗL�L��
,���_�ܖ�������
,���_�v�搔��
,���_WIP�v�搔��
,���_�I���W�i������
,���_���ѐ���
,���_�P��
,���_��������
,���_�����σt���O
,���_�����σt���O��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT 
        -- ���ʍ���
        GBHM.batch_no                             batch_no                 --�o�b�`No
       ,GBHM.plant_code                           plant_code               --�v�����g�R�[�h
       ,SOMT.orgn_name                            orgn_name                --�v�����g��
       ,GRPB.recipe_no                            recipe_no                --���V�s
       ,GRPT.recipe_description                   recipe_name              --���V�s����
       ,GRPT.recipe_description                   recipe_description       --���V�s�E�v
       ,FFMB.formula_no                           formula_no               --�t�H�[�~����
       ,FFMT.formula_desc1                        formula_neme1            --�t�H�[�~��������
       ,FFMT.formula_desc2                        formula_name2            --�t�H�[�~�������̂Q
       ,FFMT.formula_desc1                        formula_desc1            --�t�H�[�~�����E�v
       ,FFMT.formula_desc2                        formula_desc2            --�t�H�[�~�����E�v�Q
       ,GBHM.routing_no                           routing_no               --�H��
       ,GRTT.routing_desc                         routing_name             --�H������
       ,GRTT.routing_desc                         routing_desc             --�H���E�v
       ,GBHM.attribute6                           transfer_name            --�i�ڐU�֖���
       ,GBHM.attribute6                           attribute6               --�i�ڐU�֓E�v
       ,GBHM.attribute7                           attribute7               --�i�ڐU�֖ړI
       ,FLV01.meaning                             attribute7_name          --�i�ڐU�֖ړI��
       ,GBHM.plan_start_date                      plan_start_date          --�v��J�n��
       ,GBHM.actual_start_date                    actual_start_date        --���ъJ�n��
       ,GBHM.due_date                             due_date                 --�K�{������
       ,GBHM.plan_cmplt_date                      plan_cmplt_date          --�v�抮����
       ,GBHM.actual_cmplt_date                    actual_cmplt_date        --���ъ�����
       ,GBHM.batch_status                         batch_status             --�o�b�`�X�e�[�^�X
       ,FLV02.meaning                             batch_status_name        --�o�b�`�X�e�[�^�X��
       ,GBHM.wip_whse_code                        wip_whse_code            --WIP�q��
       ,IWM.whse_name                             wip_whse_name            --WIP�q�ɖ�
       ,GBHM.batch_close_date                     batch_close_date         --�N���[�Y��
       ,GBHM.delete_mark                          delete_mark              --�폜�}�[�N
        --
        -- �y�U�֌� ���׏��z
       ,XPCV_AFT.prod_class_code                  aft_prod_class_code      --���o_���i�敪
       ,XPCV_AFT.prod_class_name                  aft_prod_class_name      --���o_���i�敪��
       ,XICV_AFT.item_class_code                  aft_item_class_code      --���o_�i�ڋ敪
       ,XICV_AFT.item_class_name                  aft_item_class_name      --���o_�i�ڋ敪��
       ,XCCV_AFT.crowd_code                       aft_crowd_code           --���o_�Q�R�[�h
       ,XIM2V_AFT.item_no                         aft_item_no              --���o_�i�ڃR�[�h
       ,XIM2V_AFT.item_name                       aft_item_name            --���o_�i�ڐ�����
       ,XIM2V_AFT.item_short_name                 aft_item_short_name      --���o_�i�ڗ���
       ,NVL( DECODE( ILM_AFT.lot_no, 'DEFAULTLOT', '0', ILM_AFT.lot_no ), '0' )
                                                  aft_lot_no               --���o_���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN XIM2V_AFT.lot_ctl = 1 THEN ILM_AFT.attribute1        --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                                 --�񃍃b�g�Ǘ��i ��NULL
        END                                       aft_manufacture_date     --���o_�����N����
       ,CASE WHEN XIM2V_AFT.lot_ctl = 1 THEN ILM_AFT.attribute2        --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                                 --�񃍃b�g�Ǘ��i ��NULL
        END                                       aft_uniqe_sign           --���o_�ŗL�L��
       ,CASE WHEN XIM2V_AFT.lot_ctl = 1 THEN ILM_AFT.attribute3        --���b�g�Ǘ��i   ���ܖ����������擾
             ELSE NULL                                                 --�񃍃b�g�Ǘ��i ��NULL
        END                                       aft_expiration_date      --���o_�ܖ�������
       ,ROUND( GBHM.aft_plan_qty    , 3 )         aft_plan_qty             --���o_�v�搔��
       ,ROUND( GBHM.aft_wip_plan_qty, 3 )         aft_wip_plan_qty         --���o_WIP�v�搔��
       ,ROUND( GBHM.aft_original_qty, 3 )         aft_original_qty         --���o_�I���W�i������
       ,ROUND( GBHM.aft_actual_qty  , 3 )         aft_actual_qty           --���o_���ѐ���
       ,GBHM.aft_item_um                          aft_item_um              --���o_�P��
       ,GBHM.aft_cost_alloc                       aft_cost_alloc           --���o_��������
       ,GBHM.aft_alloc_ind                        aft_alloc_ind            --���o_�����σt���O
       ,CASE WHEN GBHM.aft_alloc_ind = 0 THEN '������'
             WHEN GBHM.aft_alloc_ind = 1 THEN '������'
        END                                       aft_alloc_name           --���o_�����σt���O��
        --
        -- �y�U�֑O ���׏��z
       ,XPCV_BEF.prod_class_code                  bef_prod_class_code      --���_���i�敪
       ,XPCV_BEF.prod_class_name                  bef_prod_class_name      --���_���i�敪��
       ,XICV_BEF.item_class_code                  bef_item_class_code      --���_�i�ڋ敪
       ,XICV_BEF.item_class_name                  bef_item_class_name      --���_�i�ڋ敪��
       ,XCCV_BEF.crowd_code                       bef_crowd_code           --���_�Q�R�[�h
       ,XIM2V_BEF.item_no                         bef_item_no              --���_�i�ڃR�[�h
       ,XIM2V_BEF.item_name                       bef_item_name            --���_�i�ڐ�����
       ,XIM2V_BEF.item_short_name                 bef_item_short_name      --���_�i�ڗ���
       ,NVL( DECODE( ILM_BEF.lot_no, 'DEFAULTLOT', '0', ILM_BEF.lot_no ), '0' )
                                                  bef_lot_no               --���_���b�gNo(DEFALTLOT�A���b�g��������'0')
       ,CASE WHEN XIM2V_BEF.lot_ctl = 1 THEN ILM_BEF.attribute1        --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                                 --�񃍃b�g�Ǘ��i ��NULL
        END                                       bef_manufacture_date     --���_�����N����
       ,CASE WHEN XIM2V_BEF.lot_ctl = 1 THEN ILM_BEF.attribute2        --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                                 --�񃍃b�g�Ǘ��i ��NULL
        END                                       bef_uniqe_sign           --���_�ŗL�L��
       ,CASE WHEN XIM2V_BEF.lot_ctl = 1 THEN ILM_BEF.attribute3        --���b�g�Ǘ��i   ���ܖ����������擾
             ELSE NULL                                                 --�񃍃b�g�Ǘ��i ��NULL
        END                                       bef_expiration_date      --���_�ܖ�������
       ,ROUND( GBHM.bef_plan_qty    , 3 )         bef_plan_qty             --���_�v�搔��
       ,ROUND( GBHM.bef_wip_plan_qty, 3 )         bef_wip_plan_qty         --���_WIP�v�搔��
       ,ROUND( GBHM.bef_original_qty, 3 )         bef_original_qty         --���_�I���W�i������
       ,ROUND( GBHM.bef_actual_qty  , 3 )         bef_actual_qty           --���_���ѐ���
       ,GBHM.bef_item_um                          bef_item_um              --���_�P��
       ,GBHM.bef_cost_alloc                       bef_cost_alloc           --���_��������
       ,GBHM.bef_alloc_ind                        bef_alloc_ind            --���_�����σt���O
       ,CASE WHEN GBHM.bef_alloc_ind = 0 THEN '������'
             WHEN GBHM.bef_alloc_ind = 1 THEN '������'
        END                                       bef_alloc_name           --���o_�����σt���O��
        --
        -- ���[�U���Ȃ�
       ,FU_CB.user_name                           created_by_name          --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( GBHM.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                  creation_date            --�쐬����
       ,FU_LU.user_name                           last_updated_by_name     --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( GBHM.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                  last_update_date         --�X�V����
       ,FU_LL.user_name                           last_update_login_name   --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  (
        SELECT
               -- ���ʍ���
                GBH.batch_no                      batch_no                 --�o�b�`No
               ,GBH.plant_code                    plant_code               --�v�����g�R�[�h
               ,GBH.recipe_validity_rule_id       recipe_validity_rule_id  --���V�s�擾�p
               ,GBH.formula_id                    formula_id               --�t�H�[�~�����擾�p
               ,GRB.routing_id                    routing_id               --�H�����擾�p
               ,GRB.routing_no                    routing_no               --�H��
               ,GBH.attribute6                    attribute6               --�i�ڐU�֓E�v
               ,GBH.attribute7                    attribute7               --�i�ڐU�֖ړI
               ,GBH.plan_start_date               plan_start_date          --�v��J�n��
               ,GBH.actual_start_date             actual_start_date        --���ъJ�n��
               ,GBH.due_date                      due_date                 --�K�{������
               ,GBH.plan_cmplt_date               plan_cmplt_date          --�v�抮����
               ,GBH.actual_cmplt_date             actual_cmplt_date        --���ъ�����
               ,GBH.batch_status                  batch_status             --�o�b�`�X�e�[�^�X
               ,GBH.wip_whse_code                 wip_whse_code            --WIP�q��
               ,GBH.batch_close_date              batch_close_date         --�N���[�Y��
               ,GBH.delete_mark                   delete_mark              --�폜�}�[�N
                --
                -- �y�U�֌� ���׏��z
               ,GMD_AFT.item_id                   aft_item_id              --���o_�i��ID
               ,ITP_AFT.lot_id                    aft_lot_id               --���o_���b�gID
               ,GMD_AFT.plan_qty                  aft_plan_qty             --���o_�v�搔��
               ,GMD_AFT.wip_plan_qty              aft_wip_plan_qty         --���o_WIP�v�搔��
               ,GMD_AFT.original_qty              aft_original_qty         --���o_�I���W�i������
               ,GMD_AFT.actual_qty                aft_actual_qty           --���o_���ѐ���
               ,GMD_AFT.item_um                   aft_item_um              --���o_�P��
               ,GMD_AFT.cost_alloc                aft_cost_alloc           --���o_��������
               ,GMD_AFT.alloc_ind                 aft_alloc_ind            --���o_�����σt���O
                --
                -- �y�U�֑O ���׏��z
               ,GMD_BEF.item_id                   bef_item_id              --���_�i��ID
               ,ITP_BEF.lot_id                    bef_lot_id               --���_���b�gID
               ,GMD_BEF.plan_qty                  bef_plan_qty             --���_�v�搔��
               ,GMD_BEF.wip_plan_qty              bef_wip_plan_qty         --���_WIP�v�搔��
               ,GMD_BEF.original_qty              bef_original_qty         --���_�I���W�i������
               ,GMD_BEF.actual_qty                bef_actual_qty           --���_���ѐ���
               ,GMD_BEF.item_um                   bef_item_um              --���_�P��
               ,GMD_BEF.cost_alloc                bef_cost_alloc           --���_��������
               ,GMD_BEF.alloc_ind                 bef_alloc_ind            --���_�����σt���O
                --
                -- ���[�U���Ȃ�
               ,GMD_AFT.created_by                created_by               --CREATED_BY
               ,GMD_AFT.creation_date             creation_date            --�쐬����
               ,GMD_AFT.last_updated_by           last_updated_by          --LAST_UPDATED_BY
               ,GMD_AFT.last_update_date          last_update_date         --�X�V����
               ,GMD_AFT.last_update_login         last_update_login        --LAST_UPDATE_LOGIN
                --���̎擾�p���
               ,NVL( TRUNC( GBH.actual_cmplt_date ), TRUNC( GBH.plan_start_date ) )    --NVL( ���ъ�����, �v��J�n�� )
                                                  act_date                 --���{�� (�˕i�ږ��̎擾�Ŏg�p)
        FROM
                gme_batch_header             GBH                           --���Y�o�b�`
               ,gmd_routings_b               GRB                           --�i�ڐU�֏��擾�����p
                --�y�U�֌���擾�p�z
               ,gme_material_details         GMD_AFT                       --���Y�o�b�`���׎擾�p
               ,ic_tran_pnd                  ITP_AFT                       --�ۗ��݌Ƀg�����U�N�V����
                --�y�U�֑O���擾�p�z
               ,gme_material_details         GMD_BEF                       --���Y�o�b�`���׎擾�p
               ,ic_tran_pnd                  ITP_BEF                       --�ۗ��݌Ƀg�����U�N�V����
        WHERE
                GBH.batch_type               =  0
          --�i�ڐU�֏��擾����
          AND   GRB.routing_class            =  '70'                       --'�i�ڐU��'
          AND   GBH.routing_id               =  GRB.routing_id
          --
          --�y�U�֌���擾�z
          --�U�֌㖾�׎擾����
          AND   GBH.batch_id                 =  GMD_AFT.batch_id
          AND   GMD_AFT.line_type            =  '-1'
          --�U�֌ネ�b�gID�擾���� (�\��f�[�^�����݂���ׁACOMPLETED_IND�͎Q�Ƃ��Ȃ�)
          AND   ITP_AFT.doc_type             = 'PROD'
          AND   ITP_AFT.delete_mark          =  0
          AND   ITP_AFT.lot_id              <>  0                          --���ނ͂��蓾�Ȃ�
          AND   ITP_AFT.reverse_id           IS NULL
          AND   GMD_AFT.material_detail_id   =  ITP_AFT.line_id
          AND   GMD_AFT.item_id              =  ITP_AFT.item_id
          --
          --�y�U�֌���擾�z
          --�U�֑O���׎擾����
          AND   GBH.batch_id                 =  GMD_BEF.batch_id
          AND   GMD_BEF.line_type(+)         =  '1'
          --�U�֑O���b�gID�擾���� (�\��f�[�^�����݂���ׁACOMPLETED_IND�͎Q�Ƃ��Ȃ�)
          AND   ITP_BEF.doc_type             = 'PROD'
          AND   ITP_BEF.delete_mark          =  0
          AND   ITP_BEF.lot_id              <>  0                          --���ނ͂��蓾�Ȃ�
          AND   ITP_BEF.reverse_id           IS NULL
          AND   GMD_BEF.material_detail_id   =  ITP_BEF.line_id
          AND   GMD_BEF.item_id              =  ITP_BEF.item_id
        )                               GBHM                        --�i�ڐU�֏��@�w�b�_�E����(�U�֑O��)
       ,sy_orgn_mst_tl                  SOMT                        --�v�����g���擾�p
       ,gmd_recipe_validity_rules       GRPVR                       --���V�s�擾�p
       ,gmd_recipes_b                   GRPB                        --���V�s�擾�p
       ,gmd_recipes_tl                  GRPT                        --���V�s�E�v�擾�p
       ,fm_form_mst_b                   FFMB                        --�t�H�[�~�����擾�p
       ,fm_form_mst_tl                  FFMT                        --�t�H�[�~�����E�v�擾�p
       ,gmd_routings_tl                 GRTT                        --�H���E�v�擾�p
       ,ic_whse_mst                     IWM                         --WIP�q�ɖ��擾�p
        --�y�U�֌���擾�p�z
       ,xxsky_prod_class_v              XPCV_AFT                    --SKYLINK�p����VIEW ���i�敪�擾VIEW
       ,xxsky_item_class_v              XICV_AFT                    --SKYLINK�p����VIEW �i�ڏ��i�敪�擾VIEW
       ,xxsky_crowd_code_v              XCCV_AFT                    --SKYLINK�p����VIEW �Q�R�[�h�擾VIEW
       ,xxsky_item_mst2_v               XIM2V_AFT                   --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2
       ,ic_lots_mst                     ILM_AFT                     --OPM���b�g�}�X�^
        --�y�U�֑O���擾�p�z
       ,xxsky_prod_class_v              XPCV_BEF                    --SKYLINK�p����VIEW ���i�敪�擾VIEW
       ,xxsky_item_class_v              XICV_BEF                    --SKYLINK�p����VIEW �i�ڏ��i�敪�擾VIEW
       ,xxsky_crowd_code_v              XCCV_BEF                    --SKYLINK�p����VIEW �Q�R�[�h�擾VIEW
       ,xxsky_item_mst2_v               XIM2V_BEF                   --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2
       ,ic_lots_mst                     ILM_BEF                     --OPM���b�g�}�X�^
        --
       ,fnd_lookup_values               FLV01                       --�i�ڐU�֖ړI���擾�p
       ,fnd_lookup_values               FLV02                       --�o�b�`�X�e�[�^�X���擾�p
       ,fnd_user                        FU_CB                       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                        FU_LU                       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                        FU_LL                       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                      FL_LL                       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
   --�v�����g���擾����
        SOMT.language(+)                =  'JA'
   AND  GBHM.plant_code                 =  SOMT.orgn_code(+)
   --���V�s�擾����
   AND  GBHM.recipe_validity_rule_id    =  GRPVR.recipe_validity_rule_id(+)
   AND  GRPVR.recipe_id                 =  GRPB.recipe_id(+)
   AND  GRPT.language(+)                =  'JA'
   AND  GRPVR.recipe_id                 =  GRPT.recipe_id(+)
   --�t�H�[�~�����擾����
   AND  FFMB.formula_id(+)              =  GBHM.formula_id
   AND  FFMT.formula_id(+)              =  FFMB.formula_id
   AND  FFMT.language(+)                =  'JA'
   --�H�����擾����
   AND  GBHM.routing_id                 =  GRTT.routing_id(+)
   AND  GRTT.language(+)                =  'JA'
   --WIP�q�ɖ��擾����
   AND  GBHM.wip_whse_code              =  IWM.whse_code(+)
   --
   --�y�U�֌���擾�z
   --�i�ڃR�[�h�A�i�ږ��A�i�ڗ��̎擾����
   AND  GBHM.aft_item_id                =  XIM2V_AFT.item_id(+)
   AND  GBHM.act_date                  >=  XIM2V_AFT.start_date_active(+)
   AND  GBHM.act_date                  <=  XIM2V_AFT.end_date_active(+)
   --���i�敪�A���i�敪���擾����
   AND  GBHM.aft_item_id                =  XPCV_AFT.item_id(+)
   --�i�ڋ敪�A�i�ڋ敪���擾����
   AND  GBHM.aft_item_id                =  XICV_AFT.item_id(+)
   --�Q�R�[�h�擾����
   AND  GBHM.aft_item_id                =  XCCV_AFT.item_id(+)
   --���b�gNo�擾
   AND  GBHM.aft_item_id                =  ILM_AFT.item_id(+)
   AND  GBHM.aft_lot_id                 =  ILM_AFT.lot_id(+)
   --
   --�y�U�֑O���擾�z
   --�i�ڃR�[�h�A�i�ږ��A�i�ڗ��̎擾����
   AND  GBHM.bef_item_id                =  XIM2V_BEF.item_id(+)
   AND  GBHM.act_date                  >=  XIM2V_BEF.start_date_active(+)
   AND  GBHM.act_date                  <=  XIM2V_BEF.end_date_active(+)
   --���i�敪�A���i�敪���擾����
   AND  GBHM.bef_item_id                =  XPCV_BEF.item_id(+)
   --�i�ڋ敪�A�i�ڋ敪���擾����
   AND  GBHM.bef_item_id                =  XICV_BEF.item_id(+)
   --�Q�R�[�h�擾����
   AND  GBHM.bef_item_id                =  XCCV_BEF.item_id(+)
   --���b�gNo�擾
   AND  GBHM.bef_item_id                =  ILM_BEF.item_id(+)
   AND  GBHM.bef_lot_id                 =  ILM_BEF.lot_id(+)
   --
   --WHO�J�����擾
   AND  GBHM.created_by                 =  FU_CB.user_id(+)
   AND  GBHM.last_updated_by            =  FU_LU.user_id(+)
   AND  GBHM.last_update_login          =  FL_LL.login_id(+)
   AND  FL_LL.user_id                   =  FU_LL.user_id(+)
   --�y�N�C�b�N�R�[�h�z�i�ڐU�֖ړI���擾����
   AND  FLV01.language(+)               =  'JA'
   AND  FLV01.lookup_type(+)            =  'XXINV_ITEM_TRANS_CLASS'
   AND  FLV01.lookup_code(+)            =  GBHM.attribute7
   --�y�N�C�b�N�R�[�h�z�o�b�`�X�e�[�^�X���擾����
   AND  FLV02.language(+)               =  'JA'
   AND  FLV02.lookup_type(+)            =  'GME_BATCH_STATUS'
   AND  FLV02.lookup_code(+)            =  GBHM.batch_status
/
COMMENT ON TABLE APPS.XXSKY_�i�ڐU�֏��_��{_V IS 'SKYLINK�p�i�ڐU�֏��i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�o�b�`NO               IS '�o�b�`No'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�v�����g�R�[�h         IS '�v�����g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�v�����g��             IS '�v�����g��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���V�s                 IS '���V�s'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���V�s����             IS '���V�s����'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���V�s�E�v             IS '���V�s�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�t�H�[�~����           IS '�t�H�[�~����'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�t�H�[�~��������       IS '�t�H�[�~��������'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�t�H�[�~�������̂Q     IS '�t�H�[�~�������̂Q'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�t�H�[�~�����E�v       IS '�t�H�[�~�����E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�t�H�[�~�����E�v�Q     IS '�t�H�[�~�����E�v�Q'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�H��                   IS '�H��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�H������               IS '�H������'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�H���E�v               IS '�H���E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�i�ڐU�֖���           IS '�i�ڐU�֖���'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�i�ڐU�֓E�v           IS '�i�ڐU�֓E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�i�ڐU�֖ړI           IS '�i�ڐU�֖ړI'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�i�ڐU�֖ړI��         IS '�i�ڐU�֖ړI��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�v��J�n��             IS '�v��J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���ъJ�n��             IS '���ъJ�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�K�{������             IS '�K�{������'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�v�抮����             IS '�v�抮����'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���ъ�����             IS '���ъ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�o�b�`�X�e�[�^�X       IS '�o�b�`�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�o�b�`�X�e�[�^�X��     IS '�o�b�`�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.WIP�q��                IS 'WIP�q��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.WIP�q�ɖ�              IS 'WIP�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�N���[�Y��             IS '�N���[�Y��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�폜�}�[�N             IS '�폜�}�[�N'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_���i�敪          IS '���o_���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_���i�敪��        IS '���o_���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�i�ڋ敪          IS '���o_�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�i�ڋ敪��        IS '���o_�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�Q�R�[�h          IS '���o_�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�i�ڃR�[�h        IS '���o_�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�i�ڐ�����        IS '���o_�i�ڐ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�i�ڗ���          IS '���o_�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_���b�gNO          IS '���o_���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�����N����        IS '���o_�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�ŗL�L��          IS '���o_�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�ܖ�������        IS '���o_�ܖ�������'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�v�搔��          IS '���o_�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_WIP�v�搔��       IS '���o_WIP�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�I���W�i������    IS '���o_�I���W�i������'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_���ѐ���          IS '���o_���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�P��              IS '���o_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_��������          IS '���o_��������'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�����σt���O      IS '���o_�����σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���o_�����σt���O��    IS '���o_�����σt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_���i�敪          IS '���_���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_���i�敪��        IS '���_���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�i�ڋ敪          IS '���_�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�i�ڋ敪��        IS '���_�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�Q�R�[�h          IS '���_�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�i�ڃR�[�h        IS '���_�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�i�ڐ�����        IS '���_�i�ڐ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�i�ڗ���          IS '���_�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_���b�gNO          IS '���_���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�����N����        IS '���_�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�ŗL�L��          IS '���_�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�ܖ�������        IS '���_�ܖ�������'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�v�搔��          IS '���_�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_WIP�v�搔��       IS '���_WIP�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�I���W�i������    IS '���_�I���W�i������'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_���ѐ���          IS '���_���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�P��              IS '���_�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_��������          IS '���_��������'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�����σt���O      IS '���_�����σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.���_�����σt���O��    IS '���_�����σt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�쐬��                 IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�쐬��                 IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�ŏI�X�V��             IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�ŏI�X�V��             IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�i�ڐU�֏��_��{_V.�ŏI�X�V���O�C��       IS '�ŏI�X�V���O�C��'
/
