CREATE OR REPLACE VIEW APPS.XXSKY_���Y����_��{_V
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
,���C���^�C�v
,���C���^�C�v��
,�^�C�v
,�^�C�v��
,�������敪
,�������敪��
,�ō��敪
,�ō��敪��
,���Y��
,�������ɓ�
,�v�搔��
,WIP�v�搔��
,�I���W�i������
,���ѐ���
,�P��
,��������
,�����σt���O
,�����σt���O��
,�����N�P
,�����N�Q
,�����N�R
,�E�v
,�݌ɓ���
,�˗�����
,�����폜�t���O
,�o�q�ɃR�[�h�P
,�o�q�ɖ��P
,�o�q�ɃR�[�h�Q
,�o�q�ɖ��Q
,�o�q�ɃR�[�h�R
,�o�q�ɖ��R
,�o�q�ɃR�[�h�S
,�o�q�ɖ��S
,�o�q�ɃR�[�h�T
,�o�q�ɖ��T
,���b�g_�w������
,���b�g_��������
,���b�g_�ߓ�����
,���b�g_���ސ����s�ǐ�
,���b�g_���ދƎҕs�ǐ�
,���b�g_��z�q�ɃR�[�h
,���b�g_��z�q�ɖ�
,���b�g_�\��敪
,���b�g_�\��敪��
,���b�g_�\��ԍ�
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        -- ���Y�o�b�`�w�b�_
         GPROD.batch_no                      batch_no                -- �o�b�`No
        ,GPROD.plant_code                    plant_code              -- �v�����g�R�[�h
        ,SOMT.orgn_name                      orgn_name               -- �v�����g��
        -- ���Y���� �����i�ȊO(�����A���Y��)�̏��
        ,GPROD.line_no                       line_no                 -- ���C��No
        ,XPCV.prod_class_code                prod_class_code         -- ���i�敪
        ,XPCV.prod_class_name                prod_class_name         -- ���i�敪��
        ,XICV.item_class_code                item_class_code         -- �i�ڋ敪
        ,XICV.item_class_name                item_class_name         -- �i�ڋ敪��
        ,XCCV.crowd_code                     crowd_code              -- �Q�R�[�h
        ,XIM2V.item_no                       item_no                 -- �i�ڃR�[�h
        ,XIM2V.item_name                     item_name               -- �i�ڐ�����
        ,XIM2V.item_short_name               item_short_name         -- �i�ڗ���
        ,NVL( DECODE( ILM.lot_no, 'DEFAULTLOT', '0', ILM.lot_no ), '0' )
                                             lot_no                  -- ���b�gNo('DEFALTLOT'�A���b�g��������'0')
        ,GPROD.manufacture_date              manufacture_date        -- �����N����
        ,CASE WHEN XIM2V.lot_ctl = 1 THEN ILM.attribute2          --���b�g�Ǘ��i   ���ŗL�L�����擾
              ELSE NULL                                           --�񃍃b�g�Ǘ��i ��NULL
         END                                 uniqe_sign              -- �ŗL�L��
        ,GPROD.expiration_date               expiration_date         -- �ܖ�������
        ,GPROD.line_type                     line_type               -- ���C���^�C�v
        ,FLV01.meaning                       line_type_name          -- ���C���^�C�v��
        ,GPROD.type                          type                    -- �^�C�v
        ,FLV02.meaning                       type_name               -- �^�C�v��
        ,GPROD.invest_ent_type               invest_ent_type         -- �������敪
        ,GOT.oprn_desc                       invest_ent_type_name    -- �������敪��
        ,GPROD.invest_type                   invest_type             -- �ō��敪
        ,CASE WHEN GPROD.invest_type = 'N' THEN '����'
              WHEN GPROD.invest_type = 'Y' THEN '�ō�'
         END                                 invest_type_name        -- �ō��敪��
        ,GPROD.prod_date                     prod_date               -- ���Y��
        ,GPROD.mtrl_in_date                  mtrl_in_date            -- �������ɓ�
        ,ROUND( GPROD.plan_qty    , 3 )      plan_qty                -- �v�搔��
        ,ROUND( GPROD.wip_plan_qty, 3 )      wip_plan_qty            -- WIP�v�搔��
        ,ROUND( GPROD.original_qty, 3 )      original_qty            -- �I���W�i������
        ,ROUND( GPROD.actual_qty  , 3 )      actual_qty              -- ���ѐ���
        ,GPROD.item_um                       item_um                 -- �P��
        ,GPROD.cost_alloc                    cost_alloc              -- ��������
        ,GPROD.alloc_ind                     alloc_ind               -- �����σt���O
        ,CASE WHEN GPROD.alloc_ind = 0 THEN '������'
              WHEN GPROD.alloc_ind = 1 THEN '������'
         END                                 alloc_ind_name          -- �����σt���O��
        ,GPROD.rank1                         rank1                   -- �����N1
        ,GPROD.rank2                         rank2                   -- �����N2
        ,GPROD.rank3                         rank3                   -- �����N3
        ,GPROD.description                   description             -- �E�v
        ,NVL( ROUND( TO_NUMBER( GPROD.inv_qty ), 3 ), 0 )
                                             inv_qty                 -- �݌ɓ���
        ,NVL( ROUND( TO_NUMBER( GPROD.req_qty ), 3 ), 0 )
                                             req_qty                 -- �˗�����
        ,GPROD.mtrl_del_flg                  mtrl_del_flg            -- �����폜�t���O
        ,GPROD.item_loct1                    item_loct1              -- �o�q�ɃR�[�h1
        ,XILV01.description                  item_loct_name1         -- �o�q�ɖ�1
        ,GPROD.item_loct2                    item_loct2              -- �o�q�ɃR�[�h2
        ,XILV02.description                  item_loct_name2         -- �o�q�ɖ�2
        ,GPROD.item_loct3                    item_loct3              -- �o�q�ɃR�[�h3
        ,XILV03.description                  item_loct_name3         -- �o�q�ɖ�3
        ,GPROD.item_loct4                    item_loct4              -- �o�q�ɃR�[�h4
        ,XILV04.description                  item_loct_name4         -- �o�q�ɖ�4
        ,GPROD.item_loct5                    item_loct5              -- �o�q�ɃR�[�h5
        ,XILV05.description                  item_loct_name5         -- �o�q�ɖ�5
        -- ���b�g���
        ,ROUND( GPROD.instructions_qty, 3 )  instructions_qty        -- ���b�g_�w������
        ,ROUND( GPROD.invested_qty    , 3 )  invested_qty            -- ���b�g_��������
        ,ROUND( GPROD.return_qty      , 3 )  return_qty              -- ���b�g_�ߓ�����
        ,ROUND( GPROD.mtl_prod_qty    , 3 )  mtl_prod_qty            -- ���b�g_���ސ����s�ǐ�
        ,ROUND( GPROD.mtl_mfg_qty     , 3 )  mtl_mfg_qty             -- ���b�g_���ދƎҕs�ǐ�
        ,GPROD.lot_location                  lot_location            -- ���b�g_��z�q�ɃR�[�h
        ,XILV06.description                  lot_loct_name           -- ���b�g_��z�q�ɖ�
        ,GPROD.plan_type                     plan_type               -- ���b�g_�\��敪
        ,FLV03.meaning                       plan_type_name          -- ���b�g_�\��敪��
        ,GPROD.plan_number                   plan_number             -- ���b�g_�\��ԍ�
        -- ���[�U���
        ,FU_CB.user_name                     created_by              -- �쐬��
        ,TO_CHAR( GPROD.creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                             creation_date           -- �쐬��(�x���˗����IF����)
        ,FU_LU.user_name                     last_updated_by         -- �ŏI�X�V��
        ,TO_CHAR( GPROD.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                             last_update_date        -- �ŏI�X�V��(�x���˗����IF����)
        ,FU_LL.user_name                     last_update_login       -- �ŏI�X�V���O�C��
FROM
        (  --========================================================================
           -- �����̃f�[�^�𒊏o     �˃��b�gID�͌����ڍ׃A�h�I������擾
           --========================================================================
           SELECT  MTRL.*
             FROM  (  -- �����ڍ׃A�h�I�����O�������{�\��敪�̑I�������𖞂����ׁA���₢���킹�Ƃ���
                      SELECT
                             -- ���Y�o�b�`�w�b�_
                              GBH.batch_no                  batch_no           -- �o�b�`No
                             ,GBH.plant_code                plant_code         -- �v�����g�R�[�h
                             ,GBH.batch_id                  batch_id           -- ���o�b�`ID(�ō��敪���擾�p)
                             ,GBH.attribute4                work_stat          -- ���Ɩ��X�e�[�^�X(�\��敪���o�p)
                             -- ���Y���� �������
                             ,GMD.line_no                   line_no            -- ���C��No
                             ,GMD.attribute17               manufacture_date   -- �����N����
                             ,GMD.attribute10               expiration_date    -- �ܖ�������
                             ,GMD.line_type                 line_type          -- ���C���^�C�v
                             ,GMD.attribute1                type               -- �^�C�v
                             ,GMD.attribute8                invest_ent_type    -- �������敪
                             ,GMD.attribute5                invest_type        -- �ō��敪
                             ,GMD.attribute11               prod_date          -- ���Y��
                             ,GMD.attribute22               mtrl_in_date       -- �������ɓ�
                             ,NVL( TO_NUMBER( gmd.attribute25 ), gmd.original_qty )
                                                            plan_qty           -- �v�搔��(�����̂ݎd�l���قȂ�)
                             ,GMD.wip_plan_qty              wip_plan_qty       -- WIP�v�搔��
                             ,GMD.original_qty              original_qty       -- �I���W�i������
                             ,GMD.actual_qty                actual_qty         -- ���ѐ���
                             ,GMD.item_um                   item_um            -- �P��
                             ,GMD.cost_alloc                cost_alloc         -- ��������
                             ,GMD.alloc_ind                 alloc_ind          -- �����σt���O
                             ,GMD.attribute2                rank1              -- �����N1
                             ,GMD.attribute3                rank2              -- �����N2
                             ,GMD.attribute26               rank3              -- �����N3
                             ,GMD.attribute4                description        -- �E�v
                             ,GMD.attribute6                inv_qty            -- �݌ɓ���
                             ,GMD.attribute7                req_qty            -- �˗�����
                             ,GMD.attribute24               mtrl_del_flg       -- �����폜�t���O
                             ,GMD.attribute13               item_loct1         -- �o�q�ɃR�[�h1
                             ,GMD.attribute18               item_loct2         -- �o�q�ɃR�[�h2
                             ,GMD.attribute19               item_loct3         -- �o�q�ɃR�[�h3
                             ,GMD.attribute20               item_loct4         -- �o�q�ɃR�[�h4
                             ,GMD.attribute21               item_loct5         -- �o�q�ɃR�[�h5
                             ,GMD.created_by                created_by         -- �쐬��
                             ,GMD.creation_date             creation_date      -- �쐬��
                             ,GMD.last_updated_by           last_updated_by    -- �ŏI�X�V��
                             ,GMD.last_update_date          last_update_date   -- �ŏI�X�V��
                             ,GMD.last_update_login         last_update_login  -- �ŏI�X�V���O�C��
                             ,GMD.item_id                   item_id            -- ���i��ID(�i�ڏ��擾�p)
                             -- ���b�g���
                             ,XMD.lot_id                    lot_id             -- �����b�gID
                             ,XMD.instructions_qty          instructions_qty   -- ���b�g_�w������
                             ,XMD.invested_qty              invested_qty       -- ���b�g_��������
                             ,XMD.return_qty                return_qty         -- ���b�g_�ߓ�����
                             ,XMD.mtl_prod_qty              mtl_prod_qty       -- ���b�g_���ސ����s�ǐ�
                             ,XMD.mtl_mfg_qty               mtl_mfg_qty        -- ���b�g_���ދƎҕs�ǐ�
                             ,XMD.location_code             lot_location       -- ���b�g_��z�q�ɃR�[�h
                             ,XMD.plan_type                 plan_type          -- ���b�g_�\��敪
                             ,XMD.plan_number               plan_number        -- ���b�g_�\��ԍ�
                              --���̎擾�p���
-- 2016/06/21 S.Yamashita Mod Start
--                             ,NVL( TO_DATE( GMDF.attribute11 ), GBH.plan_start_date )    --NVL( ���Y��, �v��J�n�� )
                             ,NVL( TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' ), GBH.plan_start_date )    --NVL( ���Y��, �v��J�n�� )
-- 2016/06/21 S.Yamashita Mod ENd
                                                            act_date           -- ���Y�� (�˕i�ږ��̎擾�Ŏg�p)
                        FROM
                              gme_batch_header              GBH                -- ���Y�o�b�`
                             ,gmd_routings_b                GRTB               -- �H���}�X�^
                             ,gme_material_details          GMD                -- ���Y�����ڍ�(����)
                             ,xxwip_material_detail         XMD                -- ���Y�����ڍ׃A�h�I��
                             ,gme_material_details          GMDF               -- ���Y�����ڍ�(�����i)
                       WHERE
                         -- �w�b�_�e�[�u���Ƃ̌���
                              GBH.batch_type   = 0
                         AND  GBH.attribute4  <> -1                            -- �Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                         -- �H��(���Y���擾)
                         AND  GRTB.routing_class NOT IN ( '61', '62', '70' )   -- �i�ڐU��(70)�A���(61,62) �ȊO
                         AND  GBH.routing_id   = GRTB.routing_id
                         -- �w�����x�̖��ו��擾
                         AND  GMD.line_type    = '-1'                          -- ����
                         AND  GBH.batch_id     = GMD.batch_id
                         -- ���Y�����ڍ׃A�h�I�����擾
                         AND  GMD.batch_id            = XMD.batch_id(+)
                         AND  GMD.material_detail_id  = XMD.material_detail_id(+)
                         -- �w�����i�x�̖��ו��擾
                         AND  GMDF.line_type   = '1'                           -- �����i
                         AND  GBH.batch_id     = GMDF.batch_id
                   )                                  MTRL
            WHERE
              -- �\��敪���o�̏���(�Ɩ��X�e�[�^�X�ɂ���Ď擾����\��敪�̃��R�[�h���قȂ�)
                   (      MTRL.plan_type IS NULL                                             -- �����ڍ׃A�h�I�������݂��Ȃ��f�[�^�͂��̂܂�(���b�g��������)
                     OR ( MTRL.work_stat     IN ( '7', '8' )  AND MTRL.plan_type  = '4' )    -- �Ɩ��X�e�[�^�X�����тł���Η\��敪'4:����'�̃f�[�^�𒊏o
                     OR ( MTRL.work_stat NOT IN ( '7', '8' )  AND MTRL.plan_type <> '4' )    -- �Ɩ��X�e�[�^�X�����шȊO�ł���Η\��敪'4:����'�ȊO�̃f�[�^�𒊏o
                   )
         UNION ALL
           --========================================================================
           -- ���Y���̃f�[�^�𒊏o   �˃��b�gID�͕ۗ��݌Ƀg�����U�N�V��������擾
           --========================================================================
           SELECT
                  -- ���Y�o�b�`�w�b�_
                   GBH.batch_no                batch_no           -- �o�b�`No
                  ,GBH.plant_code              plant_code         -- �v�����g�R�[�h
                  ,GBH.batch_id                batch_id           -- ���o�b�`ID(�ō��敪���擾�p)
                  ,GBH.attribute4              work_stat          -- ���Ɩ��X�e�[�^�X(�\��敪���o�p)
                  -- ���Y���� ���Y�����
                  ,GMD.line_no                 line_no            -- ���C��No
                  ,GMD.attribute17             manufacture_date   -- �����N����
                  ,GMD.attribute10             expiration_date    -- �ܖ�������
                  ,GMD.line_type               line_type          -- ���C���^�C�v
                  ,GMD.attribute1              type               -- �^�C�v
                  ,GMD.attribute8              invest_ent_type    -- �������敪
                  ,GMD.attribute5              invest_type        -- �ō��敪
                  ,GMD.attribute11             prod_date          -- ���Y��
                  ,GMD.attribute22             mtrl_in_date       -- �������ɓ�
                  ,GMD.plan_qty                plan_qty           -- �v�搔��
                  ,GMD.wip_plan_qty            wip_plan_qty       -- WIP�v�搔��
                  ,GMD.original_qty            original_qty       -- �I���W�i������
                  ,GMD.actual_qty              actual_qty         -- ���ѐ���
                  ,GMD.item_um                 item_um            -- �P��
                  ,GMD.cost_alloc              cost_alloc         -- ��������
                  ,GMD.alloc_ind               alloc_ind          -- �����σt���O
                  ,GMD.attribute2              rank1              -- �����N1
                  ,GMD.attribute3              rank2              -- �����N2
                  ,GMD.attribute26             rank3              -- �����N3
                  ,GMD.attribute4              description        -- �E�v
                  ,GMD.attribute6              inv_qty            -- �݌ɓ���
                  ,GMD.attribute7              req_qty            -- �˗�����
                  ,GMD.attribute24             mtrl_del_flg       -- �����폜�t���O
                  ,GMD.attribute13             item_loct1         -- �o�q�ɃR�[�h1
                  ,GMD.attribute18             item_loct2         -- �o�q�ɃR�[�h2
                  ,GMD.attribute19             item_loct3         -- �o�q�ɃR�[�h3
                  ,GMD.attribute20             item_loct4         -- �o�q�ɃR�[�h4
                  ,GMD.attribute21             item_loct5         -- �o�q�ɃR�[�h5
                  ,GMD.created_by              created_by         -- �쐬��
                  ,GMD.creation_date           creation_date      -- �쐬��
                  ,GMD.last_updated_by         last_updated_by    -- �ŏI�X�V��
                  ,GMD.last_update_date        last_update_date   -- �ŏI�X�V��
                  ,GMD.last_update_login       last_update_login  -- �ŏI�X�V���O�C��
                  ,GMD.item_id                 item_id            -- ���i��ID(�i�ڏ��擾�p)
                   -- ���b�g���
                  ,ITP.lot_id                  lot_id             -- �����b�gID
                  ,NULL                        instructions_qty   -- ���b�g_�w������
                  ,NULL                        invested_qty       -- ���b�g_��������
                  ,NULL                        return_qty         -- ���b�g_�ߓ�����
                  ,NULL                        mtl_prod_qty       -- ���b�g_���ސ����s�ǐ�
                  ,NULL                        mtl_mfg_qty        -- ���b�g_���ދƎҕs�ǐ�
                  ,NULL                        lot_location       -- ���b�g_��z�q�ɃR�[�h
                  ,NULL                        plan_type          -- ���b�g_�\��敪
                  ,NULL                        plan_number        -- ���b�g_�\��ԍ�
                   --���̎擾�p���
-- 2016/06/21 S.Yamashita Mod Start
--                  ,NVL( TO_DATE( GMDF.attribute11 ), TRUNC( GBH.plan_start_date ) )    --NVL( ���Y��, �v��J�n�� )
                  ,NVL( TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' ), TRUNC( GBH.plan_start_date ) )    --NVL( ���Y��, �v��J�n�� )
-- 2016/06/21 S.Yamashita Mod End
                                               act_date           -- ���Y�� (�˕i�ږ��̎擾�Ŏg�p)
             FROM
                   gme_batch_header            GBH                -- ���Y�o�b�`
                  ,gmd_routings_b              GRTB               -- �H���}�X�^
                  ,gme_material_details        GMD                -- ���Y�����ڍ�(���Y��)
                  ,ic_tran_pnd                 ITP                -- OPM�ۗ��݌Ƀg�����U�N�V����
                  ,gme_material_details        GMDF               -- ���Y�����ڍ�(�����i)
            WHERE
              -- �w�b�_�e�[�u���Ƃ̌���
                   GBH.batch_type         = 0
              AND  GBH.attribute4        <> '-1'                  -- �Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
              -- �H��(���Y���擾)
              AND  GRTB.routing_class     NOT IN ( '61', '62', '70' ) -- �i�ڐU��(70)�A���(61,62) �ȊO
              AND  GBH.routing_id         = GRTB.routing_id
              -- �w���Y���x�̖��ו��擾
              AND  GBH.batch_id           = GMD.batch_id
              AND  GMD.line_type          = '2'                   -- ���Y��
              -- OPM�ۗ��݌Ƀg�����U�N�V�����Ƃ̌������� (�\��f�[�^�����݂���ׁACOMPLETED_IND�͎Q�Ƃ��Ȃ�)
              AND  ITP.doc_type(+)        = 'PROD'
              AND  ITP.delete_mark(+)     = 0                     -- �L���`�F�b�N(OPM�ۗ��݌�)
              AND  ITP.reverse_id(+)      IS NULL
              AND  ITP.lot_id(+)         <> 0                     --�w���ށx�͗L�蓾�Ȃ�
              AND  GMD.material_detail_id = ITP.line_id(+)
              AND  GMD.item_id            = ITP.item_id(+)
              -- �w�����i�x�̖��ו��擾
              AND  GMDF.line_type         = '1'                   -- �����i
              AND  GBH.batch_id           = GMDF.batch_id
        )                                   GPROD               -- �����{���Y�����
        -- �ȉ��͏�LSQL�����̍��ڂ��g�p���ĊO���������s������(�G���[�����)
        ,sy_orgn_mst_tl                     SOMT                -- ��OPM�v�����g�}�X�^(WHERE��̂�)
        ,xxsky_prod_class_v                 XPCV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�����i_���i�敪)
        ,xxsky_item_class_v                 XICV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�����i_�i�ڋ敪)
        ,xxsky_crowd_code_v                 XCCV                -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�����i_�Q�R�[�h)
        ,xxsky_item_mst2_v                  XIM2V               -- SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�����i_�i�ږ�)
        ,ic_lots_mst                        ILM                 -- OPM���b�g�}�X�^
        ,gmd_operations_tl                  GOT                 -- �H���}�X�^
        ,gme_batch_steps                    GBS                 -- ���������敪���擾�p
        ,fnd_lookup_values                  FLV01               -- �N�C�b�N�R�[�h�\(���C���^�C�v��)
        ,fnd_lookup_values                  FLV02               -- �N�C�b�N�R�[�h�\(�^�C�v��)
        ,fnd_lookup_values                  FLV03               -- �N�C�b�N�R�[�h�\(���b�g_�\��敪��)
        ,xxsky_item_locations_v             XILV01              -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(�o�q�ɖ�1)
        ,xxsky_item_locations_v             XILV02              -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(�o�q�ɖ�2)
        ,xxsky_item_locations_v             XILV03              -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(�o�q�ɖ�3)
        ,xxsky_item_locations_v             XILV04              -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(�o�q�ɖ�4)
        ,xxsky_item_locations_v             XILV05              -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(�o�q�ɖ�5)
        ,xxsky_item_locations_v             XILV06              -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(���b�g��z�q�ɖ�)
        ,fnd_user                           FU_CB               -- ���[�U�[�}�X�^(CREATED_BY���̎擾�p)
        ,fnd_user                           FU_LU               -- ���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
        ,fnd_user                           FU_LL               -- ���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
        ,fnd_logins                         FL_LL               -- ���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
        -- �v�����g��
        SOMT.language(+)                    = 'JA'
   AND  GPROD.plant_code                    = SOMT.orgn_code(+)
        -- ���i�敪(�����A���Y��)
   AND  GPROD.item_id                       = XPCV.item_id(+)
        -- �i�ڋ敪(�����A���Y��)
   AND  GPROD.item_id                       = XICV.item_id(+)
        -- �Q�R�[�h(�����A���Y��)
   AND  GPROD.item_id                       = XCCV.item_id(+)
        -- �i�ږ���(�����A���Y��)
   AND  GPROD.item_id                       = XIM2V.item_id(+)
   AND  GPROD.act_date                     >= XIM2V.start_date_active(+)
   AND  GPROD.act_date                     <= XIM2V.end_date_active(+)
        -- ���b�g���(�����A���Y��)
   AND  GPROD.item_id                       = ILM.item_id(+)
   AND  GPROD.lot_id                        = ILM.lot_id(+)
        -- �������敪��
   AND  GOT.language(+)                     = 'JA'
   AND  GBS.oprn_id                         = GOT.oprn_id(+)
   AND  GPROD.batch_id                      = GBS.batch_id(+)
   AND  GPROD.invest_ent_type               = GBS.batchstep_no(+)
        -- �o�q�ɖ�1�`5
   AND  GPROD.item_loct1                    = XILV01.segment1(+)
   AND  GPROD.item_loct2                    = XILV02.segment1(+)
   AND  GPROD.item_loct3                    = XILV03.segment1(+)
   AND  GPROD.item_loct4                    = XILV04.segment1(+)
   AND  GPROD.item_loct5                    = XILV05.segment1(+)
        -- ���b�g��z�q�ɖ�
   AND  GPROD.lot_location                  = XILV06.segment1(+)
        -- ���[�U���Ȃ�
   AND  GPROD.created_by                    = FU_CB.user_id(+)
   AND  GPROD.last_updated_by               = FU_LU.user_id(+)
   AND  GPROD.last_update_login             = FL_LL.login_id(+)
   AND  FL_LL.user_id                       = FU_LL.user_id(+)
        -- �y�N�C�b�N�R�[�h�z���C���^�C�v��
   AND  FLV01.language(+)                   = 'JA'
   AND  FLV01.lookup_type(+)                = 'GMD_FORMULA_ITEM_TYPE'
   AND  FLV01.lookup_code(+)                = GPROD.line_type
        -- �y�N�C�b�N�R�[�h�z�^�C�v��
   AND  FLV02.language(+)                   = 'JA'
   AND  FLV02.lookup_type(+)                = 'XXCMN_L08'
   AND  FLV02.lookup_code(+)                = GPROD.type
        -- �y�N�C�b�N�R�[�h�z���b�g�\��敪��
   AND  FLV03.language(+)                   = 'JA'
   AND  FLV03.lookup_type(+)                = 'XXWIP_PLAN_TYPE'
   AND  FLV03.lookup_code(+)                = GPROD.plan_type
/
COMMENT ON TABLE APPS.XXSKY_���Y����_��{_V IS 'SKYLINK�p���Y���ׁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�b�`NO               IS '�o�b�`No'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�v�����g�R�[�h         IS '�v�����g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�v�����g��             IS '�v�����g��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���C��NO               IS '���C��No'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���i�敪               IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���i�敪��             IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�i�ڋ敪               IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�i�ڋ敪��             IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�Q�R�[�h               IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�i�ڃR�[�h             IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�i�ڐ�����             IS '�i�ڐ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�i�ڗ���               IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�gNO               IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�����N����             IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�ŗL�L��               IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�ܖ�������             IS '�ܖ�������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���C���^�C�v           IS '���C���^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���C���^�C�v��         IS '���C���^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�^�C�v                 IS '�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�^�C�v��               IS '�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�������敪             IS '�������敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�������敪��           IS '�������敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�ō��敪               IS '�ō��敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�ō��敪��             IS '�ō��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���Y��                 IS '���Y��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�������ɓ�             IS '�������ɓ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�v�搔��               IS '�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.WIP�v�搔��            IS 'WIP�v�搔��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�I���W�i������         IS '�I���W�i������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���ѐ���               IS '���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�P��                   IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.��������               IS '��������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�����σt���O           IS '�����σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�����σt���O��         IS '�����σt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�����N�P               IS '�����N�P'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�����N�Q               IS '�����N�Q'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�����N�R               IS '�����N�R'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�E�v                   IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�݌ɓ���               IS '�݌ɓ���'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�˗�����               IS '�˗�����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�����폜�t���O         IS '�����폜�t���O'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�q�ɃR�[�h�P         IS '�o�q�ɃR�[�h�P'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�q�ɖ��P             IS '�o�q�ɖ��P'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�q�ɃR�[�h�Q         IS '�o�q�ɃR�[�h�Q'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�q�ɖ��Q             IS '�o�q�ɖ��Q'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�q�ɃR�[�h�R         IS '�o�q�ɃR�[�h�R'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�q�ɖ��R             IS '�o�q�ɖ��R'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�q�ɃR�[�h�S         IS '�o�q�ɃR�[�h�S'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�q�ɖ��S             IS '�o�q�ɖ��S'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�q�ɃR�[�h�T         IS '�o�q�ɃR�[�h�T'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�o�q�ɖ��T             IS '�o�q�ɖ��T'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�g_�w������        IS '���b�g_�w������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�g_��������        IS '���b�g_��������'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�g_�ߓ�����        IS '���b�g_�ߓ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�g_���ސ����s�ǐ�  IS '���b�g_���ސ����s�ǐ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�g_���ދƎҕs�ǐ�  IS '���b�g_���ދƎҕs�ǐ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�g_��z�q�ɃR�[�h  IS '���b�g_��z�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�g_��z�q�ɖ�      IS '���b�g_��z�q�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�g_�\��敪        IS '���b�g_�\��敪'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�g_�\��敪��      IS '���b�g_�\��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.���b�g_�\��ԍ�        IS '���b�g_�\��ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�쐬��                 IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�쐬��                 IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�ŏI�X�V��             IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�ŏI�X�V��             IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���Y����_��{_V.�ŏI�X�V���O�C��       IS '�ŏI�X�V���O�C��'
/
