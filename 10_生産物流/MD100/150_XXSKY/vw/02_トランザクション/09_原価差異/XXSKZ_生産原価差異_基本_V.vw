/*************************************************************************
 * 
 * View  Name      : XXSKZ_���Y��������_��{_V
 * Description     : XXSKZ_���Y��������_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_���Y��������_��{_V
(
 ���Y��
,���ъǗ�����
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i��
,�i�ږ�
,�i�ڗ���
,���b�gNO
,�����N����
,�ܖ�����
,�ŗL�L��
,�o��������
,�W�������P��
,�W���������z
,�������z
,�ō����z
,���Y�����z
,�o�������z
,�o�����P��
,�P������
,��������
)
AS
SELECT  SMMR.act_date                           act_date           --���Y��
       ,SMMR.pm_dept                            pm_dept            --���ъǗ�����
       ,PRODC.prod_class_code                   prod_class_code    --���i�敪
       ,PRODC.prod_class_name                   prod_class_name    --���i�敪��
       ,ITEMC.item_class_code                   item_class_code    --�i�ڋ敪
       ,ITEMC.item_class_name                   item_class_name    --�i�ڋ敪��
       ,CROWD.crowd_code                        crowd_code         --�Q�R�[�h
       ,ITEM.item_no                            item_code          --�i��
       ,ITEM.item_name                          item_name          --�i�ږ�
       ,ITEM.item_short_name                    item_s_name        --�i�ڗ���
       ,NVL( DECODE( ILMF.lot_no, 'DEFAULTLOT', '0', ILMF.lot_no ), '0' )
                                                lot_no             --���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN ITEM.lot_ctl = 1 THEN ILMF.attribute1    --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                     --�񃍃b�g�Ǘ��i ��NULL
        END                                     lot_date           --�����N����
       ,CASE WHEN ITEM.lot_ctl = 1 THEN ILMF.attribute3    --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                     --�񃍃b�g�Ǘ��i ��NULL
        END                                     best_bfr_date      --�ܖ�����
       ,CASE WHEN ITEM.lot_ctl = 1 THEN ILMF.attribute2    --���b�g�Ǘ��i   ���ܖ��������擾
             ELSE NULL                                     --�񃍃b�g�Ǘ��i ��NULL
        END                                     lot_sign           --�ŗL�L��
       ,NVL( SMMR.output_qty , 0 )              output_qty         --�o��������
       ,NVL( ICOST.cmpnt_cost, 0 )              cmpt_cost          --�W�������P��
        --�W���������z = ( �����P�� �~ �o�������� )
       ,NVL( ROUND( ICOST.cmpnt_cost * SMMR.output_qty ), 0 )
                                                cmpt_amt           --�W���������z
       ,NVL( SMMR.invest_amt , 0 )              invest_amt         --�������z
       ,NVL( SMMR.into_amt   , 0 )              into_amt           --�ō����z
       ,NVL( SMMR.product_amt, 0 )              product_amt        --���Y�����z
       ,NVL( SMMR.output_amt , 0 )              output_amt         --�o�������z
        --�o�����P�� = ( �o�������z �� �o�������� )
       ,CASE WHEN NVL( SMMR.output_qty, 0 ) = 0 THEN 0               --�o�������ʂ��[���Ȃ珜�Z���Ȃ�
             ELSE                                    NVL( ROUND( SMMR.output_amt / SMMR.output_qty, 2 ), 0 )
        END                                     output_unt         --�o�����P��
        --�P������ = ( �W�������P�� - �o�����P�� )
       ,NVL( ICOST.cmpnt_cost, 0 )
         - CASE WHEN NVL( SMMR.output_qty, 0 ) = 0 THEN 0               --�o�������ʂ��[���Ȃ珜�Z���Ȃ�
                ELSE                                    NVL( ROUND( SMMR.output_amt / SMMR.output_qty, 2 ), 0 )
           END
        --�������� = ( �W���������z - �o�������z )
       ,NVL( ROUND( ICOST.cmpnt_cost * SMMR.output_qty ), 0 ) - NVL( SMMR.output_amt , 0 )
  FROM  (  --���Y���A�����A�����i_�i�ڂ̒P�ʂŏW�v�����f�[�^
           SELECT  MTRL.act_date                     act_date      --���Y��
                  ,MTRL.pm_dept                      pm_dept       --���ъǗ�����
                  ,MTRL.cp_item_id                   cp_item_id    --�����i_�i��ID
                  ,MTRL.cp_lot_id                    cp_lot_id     --�����i_���b�gID
                  ,SUM( MTRL.output_qty  )           output_qty    --�o��������
                  ,SUM( MTRL.output_amt  )           output_amt    --�o�������z�i�������z�{�ō����z�|���Y�����z�j
                  ,SUM( MTRL.invest_amt  )           invest_amt    --�������z
                  ,SUM( MTRL.into_amt    )           into_amt      --�ō����z
                  ,SUM( MTRL.product_amt )           product_amt   --���Y�����z
             FROM  ( --�W�v�Ώۃf�[�^���w�����i�x�A�w�����x�A�w���Y���x�ʂŎ擾
                      --================================================
                      -- �����i�f�[�^
                      --================================================
                      SELECT  GBH.batch_no             batch_no      --�o�b�`No
                             ,TO_DATE( GMD.attribute11, 'YYYY/MM/DD' )
                                                       act_date     --���Y��(�����i_���Y��)
                             ,GBH.attribute2          pm_dept       --���ъǗ�����
                             ,GMD.item_id             cp_item_id    --�����i_�i��ID
                             ,ITP.lot_id              cp_lot_id     --�����i_���b�gID
                             ,GMD.item_id             item_id       --�����i_�i��ID
                             ,ITP.lot_id              lot_id        --�����i_���b�gID
                             ,ITP.trans_qty           output_qty    --�o��������
                             ,0                        output_amt   --�o�������z�i�������z�{�ō����z�|���Y�����z�j
                             ,0                        invest_amt   --�������z�i�P���~�݌ɐ��ʁj
                             ,0                        into_amt     --�ō����z�i�P���~�݌ɐ��ʁj
                             ,0                        product_amt  --���Y�����z�i�P���~�݌ɐ��ʁj
                        FROM  xxcmn_gme_batch_header_arc      GBH   --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                             ,gmd_routings_b                  GRB   --�H���}�X�^
                             ,xxcmn_gme_material_details_arc  GMD   --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                             ,xxcmn_ic_tran_pnd_arc           ITP   --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                       WHERE  GBH.batch_type           = 0
                         AND  GBH.attribute4          <> '-1'       --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                         --�H���ԍ��̎擾�Ɛ��Y�f�[�^���o�ׂ̈̕t������
                         AND  GRB.routing_class        NOT IN ( '61', '62', '70' )  --�i�ڐU��(70)�A���(61,62) �ȊO
                         AND  GBH.routing_id           = GRB.routing_id
                         --�����ڍ׃f�[�^�w�����i�x�Ƃ̌���
                         AND  GMD.line_type            = '1'         --�y�����i�z
                         AND  GBH.batch_id             = GMD.batch_id
                         --�����i���b�gID�擾�ׁ̈A�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
                         AND  ITP.trans_qty           <> 0
                         AND  ITP.doc_type             = 'PROD'
                         AND  ITP.delete_mark          = 0
                         AND  ITP.completed_ind        = 1           --����(�ˎ���)
                         AND  ITP.reverse_id           IS NULL
                         AND  ITP.lot_id              <> 0           --�w���ށx�͗L�蓾�Ȃ�
                         AND  GMD.material_detail_id   = ITP.line_id
                         AND  GMD.item_id              = ITP.item_id
                      -- [ �����i�f�[�^ END ] --
                    UNION ALL
                      --================================================
                      -- �����f�[�^
                      --================================================
                      SELECT  SGMD.batch_no            batch_no      --�o�b�`No
                             ,SGMD.act_date            act_date      --���Y��(�����i_���Y��)
                             ,SGMD.pm_dept             pm_dept       --���ъǗ�����
                             ,SGMD.cp_item_id          cp_item_id    --�����i_�i��ID
                             ,SGMD.cp_lot_id           cp_lot_id     --�����i_���b�gID
                             ,SGMD.item_id             item_id       --����_�i��ID
                             ,SGMD.lot_id              lot_id        --����_���b�gID
                             ,0                        output_qty    --�o��������
                              --�o�������z�i�������z�{�ō����z�|���Y�����z�j
                             ,ROUND( DECODE( IIM.attribute15, '0', SGMD.inv_amt      --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                            , '1', XPH.total_amount  --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                 , 0 )
                                                       * SGMD.quantity )
                                                       output_amt    --�o�������z�i�������z�{�ō����z�|���Y�����z�j
                              --�������z
                             ,CASE WHEN invest_type <> 'Y' THEN                --������ō��敪�w�����x
                                ROUND( DECODE( IIM.attribute15, '0', SGMD.inv_amt      --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                              , '1', XPH.total_amount  --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                   , 0 )
                                                       * SGMD.quantity )
                              END                      invest_amt    --�������z�i�P���~�݌ɐ��ʁj
                              --�ō����z
                             ,CASE WHEN invest_type  = 'Y' THEN                --������ō��敪�w�ō��x
                                ROUND( DECODE( IIM.attribute15, '0', SGMD.inv_amt      --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                              , '1', XPH.total_amount  --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                   , 0 )
                                                       * SGMD.quantity )
                              END                      into_amt      --�ō����z�i�P���~�݌ɐ��ʁj
                             ,0                        product_amt   --���Y�����z�i�P���~�݌ɐ��ʁj
                        FROM  (  --�W���P���}�X�^�Ƃ̊O�������ׁ̈A���₢���킹�Ƃ���
                                 SELECT  GBH.batch_no                    batch_no        --�o�b�`No
                                        ,GBH.attribute2                  pm_dept         --���ъǗ�����
                                        ,TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' )
                                                                         act_date        --�����i_���Y��
                                        ,GMDF.item_id                    cp_item_id      --�����i_�i��ID
                                        ,ITPF.lot_id                     cp_lot_id       --�����i_���b�gID
                                        ,GMD.item_id                     item_id         --����_�i��ID
                                        ,XMD.lot_id                      lot_id          --����_���b�gID
                                        ,NVL( GMD.attribute5, 'N' )      invest_type     --������ō��敪
                                        ,XMD.invested_qty - XMD.return_qty
                                                                         quantity        --����
                                        ,TO_NUMBER( ILM.attribute7 )     inv_amt         --�݌ɒP��
                                   FROM  xxcmn_gme_batch_header_arc      GBH             --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                                        ,gmd_routings_b                  GRB             --�H���}�X�^
                                        ,xxcmn_gme_material_details_arc  GMD             --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                                        ,xxcmn_material_detail_arc       XMD             --���Y�����ڍׁi�A�h�I���j�o�b�N�A�b�v
                                        ,ic_lots_mst                     ILM             --OPM���b�g�}�X�^
                                        ,xxskz_item_class_v              ITEMC           --�i�ڋ敪�擾�p
                                        ,xxcmn_gme_material_details_arc  GMDF            --���Y�����ڍׁi�W���j�o�b�N�A�b�v(�����i���擾�p)
                                        ,xxcmn_ic_tran_pnd_arc           ITPF            --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v(�����i���擾�p)
                                  WHERE  GBH.batch_type              = 0
                                    AND  GBH.attribute4             <> '-1'          --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                                    --�H���ԍ��̎擾�Ɛ��Y�f�[�^���o�ׂ̈̕t������
                                    AND  GRB.routing_class           NOT IN ( '61', '62', '70' )  --�i�ڐU��(70)�A���(61,62) �ȊO
                                    AND  GBH.routing_id              = GRB.routing_id
                                    --�����ڍ׃f�[�^�w�����x�Ƃ̌���
                                    AND  GMD.line_type               = '-1'          --�y�����z
                                    AND  GBH.batch_id                = GMD.batch_id
                                    --�w���ށx�͏��O����
                                    AND  GMD.item_id                 = ITEMC.item_id
                                    AND  ITEMC.item_class_code      <> '2'           --�w���ށx�ȊO
                                    --�����ڍ׃A�h�I���Ƃ̌���
                                    AND  XMD.plan_type               = '4'           --����
                                    AND  (    XMD.invested_qty      <> 0
                                           OR XMD.return_qty        <> 0
                                         )
                                    AND  GMD.batch_id                = XMD.batch_id
                                    AND  GMD.material_detail_id      = XMD.material_detail_id
                                    --���b�g�}�X�^�Ƃ̌���
                                    AND  XMD.item_id                 = ILM.item_id
                                    AND  XMD.lot_id                  = ILM.lot_id
                                    --�����i�f�[�^�Ƃ̌���
                                    AND  GMDF.line_type              = '1'           --�y�����i�z
                                    AND  GBH.batch_id                = GMDF.batch_id
                                    --�����i���b�gID�擾�ׁ̈A�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
                                    AND  ITPF.doc_type               = 'PROD'
                                    AND  ITPF.delete_mark            = 0
                                    AND  ITPF.completed_ind          = 1             --����(�ˎ���)
                                    AND  ITPF.reverse_id             IS NULL
                                    AND  ITPF.lot_id                <> 0             --�w���ށx�͗L�蓾�Ȃ�
                                    AND  GMDF.material_detail_id     = ITPF.line_id
                                    AND  GMDF.item_id                = ITPF.item_id
                              )                        SGMD          --�����i�f�[�^
                             ,ic_item_mst_b            IIM           --OPM�i�ڃ}�X�^
                             ,xxpo_price_headers       XPH           --�d��/�W���P���}�X�^
                       WHERE
                         --OPM�i�ڃ}�X�^�Ƃ̌���
                              SGMD.item_id             = IIM.item_id
                         --�W���P���}�X�^�Ƃ̌���
                         AND  XPH.price_type(+)        = '2'         --�W��
                         AND  SGMD.item_id             = XPH.item_id(+)
                         AND  SGMD.act_date           >= XPH.start_date_active(+)
                         AND  SGMD.act_date           <= XPH.end_date_active(+)
                      -- [ �����f�[�^ END ] --
                    UNION ALL
                      --================================================
                      -- ���Y���f�[�^
                      --================================================
                      SELECT  SGMD.batch_no            batch_no      --�o�b�`No
                             ,SGMD.act_date            act_date      --���Y��(�����i_���Y��)
                             ,SGMD.pm_dept             pm_dept       --���ъǗ�����
                             ,SGMD.cp_item_id          cp_item_id    --�����i_�i��ID
                             ,SGMD.cp_lot_id           cp_lot_id     --�����i_���b�gID
                             ,SGMD.item_id             item_id       --���Y��_�i��ID
                             ,SGMD.lot_id              lot_id        --���Y��_���b�gID
                             ,0                        output_qty    --�o��������
                              --�o�������z�i�������z�{�ō����z�|���Y�����z�j
                             ,ROUND( DECODE( IIM.attribute15, '0', SGMD.inv_amt      --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                            , '1', XPH.total_amount  --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                 , 0 )
                                                       * SGMD.quantity * -1 )
                                                       output_amt    --�o�������z�i�������z�{�ō����z�|���Y�����z�j
                             ,0                        invest_amt    --�������z�i�P���~�݌ɐ��ʁj
                             ,0                        into_amt      --�ō����z�i�P���~�݌ɐ��ʁj
                              --���Y�����z
                             ,ROUND( DECODE( IIM.attribute15, '0', SGMD.inv_amt      --�����Ǘ��敪��0:�����Ȃ�݌ɒP��
                                                            , '1', XPH.total_amount  --�����Ǘ��敪��1:�W���Ȃ�W���P��
                                                                 , 0 )
                                                       * SGMD.quantity )
                                                       product_amt   --���Y�����z�i�P���~�݌ɐ��ʁj
                        FROM  (  --�W���P���}�X�^�Ƃ̊O�������ׁ̈A���₢���킹�Ƃ���
                                 SELECT  GBH.batch_no                    batch_no        --�o�b�`No
                                        ,GBH.attribute2                  pm_dept         --���ъǗ�����
                                        ,TO_DATE( GMDF.attribute11, 'YYYY/MM/DD' )
                                                                         act_date        --�����i_���Y��
                                        ,GMDF.item_id                    cp_item_id      --�����i_�i��ID
                                        ,ITPF.lot_id                     cp_lot_id       --�����i_���b�gID
                                        ,GMD.item_id                     item_id         --���Y��_�i��ID
                                        ,ITP.lot_id                      lot_id          --���Y��_���b�gID
                                        ,ITP.trans_qty                   quantity        --����
                                        ,TO_NUMBER( ILM.attribute7 )     inv_amt         --�݌ɒP��
                                   FROM  xxcmn_gme_batch_header_arc      GBH             --���Y�o�b�`�w�b�_�i�W���j�o�b�N�A�b�v
                                        ,gmd_routings_b                  GRB             --�H���}�X�^
                                        ,xxcmn_gme_material_details_arc  GMD             --���Y�����ڍׁi�W���j�o�b�N�A�b�v
                                        ,xxcmn_ic_tran_pnd_arc           ITP             --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
                                        ,ic_lots_mst                     ILM             --OPM���b�g�}�X�^
                                        ,xxcmn_gme_material_details_arc  GMDF            --���Y�����ڍׁi�W���j�o�b�N�A�b�v(�����i���擾�p)
                                        ,xxcmn_ic_tran_pnd_arc           ITPF            --OPM�ۗ��݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v(�����i���擾�p)
                                  WHERE  GBH.batch_type              = 0
                                    AND  GBH.attribute4             <> '-1'          --�Ɩ��X�e�[�^�X�w������x�̃f�[�^�͑ΏۊO
                                    --�H���ԍ��̎擾�Ɛ��Y�f�[�^���o�ׂ̈̕t������
                                    AND  GRB.routing_class           NOT IN ( '61', '62', '70' )  --�i�ڐU��(70)�A���(61,62) �ȊO
                                    AND  GBH.routing_id              = GRB.routing_id
                                    --�����ڍ׃f�[�^�w���Y���x�Ƃ̌���
                                    AND  GMD.line_type               = '2'           --�y���Y���z
                                    AND  GBH.batch_id                = GMD.batch_id
                                    --�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
                                    AND  ITP.trans_qty              <> 0
                                    AND  ITP.doc_type                = 'PROD'
                                    AND  ITP.delete_mark             = 0
                                    AND  ITP.completed_ind           = 1             --����(�ˎ���)
                                    AND  ITP.reverse_id              IS NULL
                                    AND  ITP.lot_id                 <> 0             --�w���ށx�͗L�蓾�Ȃ�
                                    AND  GMD.material_detail_id      = ITP.line_id
                                    AND  GMD.item_id                 = ITP.item_id
                                    --���b�g�}�X�^�Ƃ̌���
                                    AND  ITP.item_id                 = ILM.item_id
                                    AND  ITP.lot_id                  = ILM.lot_id
                                    --�����i�f�[�^�Ƃ̌���
                                    AND  GMDF.line_type              = '1'           --�y�����i�z
                                    AND  GBH.batch_id                = GMDF.batch_id
                                    --�����i���b�gID�擾�ׁ̈A�ۗ��݌Ƀg�����U�N�V�����Ƃ̌���
                                    AND  ITPF.doc_type               = 'PROD'
                                    AND  ITPF.delete_mark            = 0
                                    AND  ITPF.completed_ind          = 1             --����(�ˎ���)
                                    AND  ITPF.reverse_id             IS NULL
                                    AND  ITPF.lot_id                <> 0             --�w���ށx�͗L�蓾�Ȃ�
                                    AND  GMDF.batch_id               = ITPF.doc_id
                                    AND  GMDF.material_detail_id     = ITPF.line_id
                                    AND  GMDF.item_id                = ITPF.item_id
                              )                        SGMD          --�����i�f�[�^
                             ,ic_item_mst_b            IIM           --OPM�i�ڃ}�X�^
                             ,xxpo_price_headers       XPH           --�d��/�W���P���}�X�^
                       WHERE
                         --OPM�i�ڃ}�X�^�Ƃ̌���
                              SGMD.item_id             = IIM.item_id
                         --�W���P���}�X�^�Ƃ̌���
                         AND  XPH.price_type(+)        = '2'         --�W��
                         AND  SGMD.item_id             = XPH.item_id(+)
                         AND  SGMD.act_date           >= XPH.start_date_active(+)
                         AND  SGMD.act_date           <= XPH.end_date_active(+)
                   )            MTRL
           GROUP BY MTRL.act_date           --���Y��
                   ,MTRL.pm_dept            --���ъǗ�����
                   ,MTRL.cp_item_id         --�����i_�i��ID
                   ,MTRL.cp_lot_id          --�����i_���b�gID
        )  SMMR                             --���Y�W�v���
       ,(  --�i�ڕʕW���������(�����̂�)�擾
           SELECT  CCD.item_id              --�i��ID
                  ,CCDL.start_date          --�K�p�J�n�N����
                  ,CCDL.end_date            --�K�p�I���N����
                  ,CCD.cmpnt_cost           --�����l
             FROM  cm_cmpt_dtl      CCD
                  ,cm_cmpt_mst_b    CCMB
                  ,cm_cldr_dtl      CCDL
            WHERE  CCD.whse_code           = '000'
              AND  CCD.cost_mthd_code      = 'STDU'
              AND  CCD.cost_analysis_code  = '0000'
              AND  CCD.cost_level          = 0
              AND  CCMB.cost_cmpntcls_code = '01GEN'    --������
              AND  CCD.cost_cmpntcls_id    = CCMB.cost_cmpntcls_id
              AND  CCD.calendar_code       = CCDL.calendar_code
              AND  CCD.period_code         = CCDL.period_code
        )                       ICOST       --�i�ڕʌ�������
       ,ic_lots_mst             ILMF        --OPM���b�g�}�X�^(�����i�i�ڂ̃��b�g��񁕍݌ɒP���擾�p)
       ,xxpo_price_headers      XPH         --�d��/�W���P���}�X�^(�����i�i�ڂ̕W���P���擾�p)
       ,xxskz_item_mst2_v       ITEM        --�i�ږ��擾�p
       ,xxskz_prod_class_v      PRODC       --���i�敪�擾�p
       ,xxskz_item_class_v      ITEMC       --�i�ڋ敪�擾�p
       ,xxskz_crowd_code_v      CROWD       --�Q�R�[�h�擾�p
 WHERE
   --�����i�i�ڂ̃��b�g��񁕍݌ɒP���擾
        SMMR.cp_item_id    = ILMF.item_id
   AND  SMMR.cp_lot_id     = ILMF.lot_id
   --�W���P���}�X�^�Ƃ̌���
   AND  XPH.price_type(+)  = '2'            --�W��
   AND  SMMR.cp_item_id    = XPH.item_id(+)
   AND  SMMR.act_date     >= XPH.start_date_active(+)
   AND  SMMR.act_date     <= XPH.end_date_active(+)
   --�����i�i�ڂ̌����P��(�����̂�)�擾
   AND  SMMR.cp_item_id    = ICOST.item_id(+)
   AND  SMMR.act_date     >= ICOST.start_date(+)
   AND  SMMR.act_date     <= ICOST.end_date(+)
   --�i�ږ�(�����i)�擾
   AND  SMMR.cp_item_id    = ITEM.item_id(+)
   AND  SMMR.act_date     >= ITEM.start_date_active(+)
   AND  SMMR.act_date     <= ITEM.end_date_active(+)
   --�i�ڃJ�e�S����(�����i)�擾
   AND  ITEM.item_id       = PRODC.item_id(+)
   AND  ITEM.item_id       = ITEMC.item_id(+)
   AND  ITEM.item_id       = CROWD.item_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_���Y��������_��{_V IS 'SKYLINK�p ���Y�������فi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.���Y��       IS '���Y��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.���ъǗ����� IS '���ъǗ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.���i�敪     IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.���i�敪��   IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�i�ڋ敪     IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�i�ڋ敪��   IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�Q�R�[�h     IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�i��         IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�i�ږ�       IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�i�ڗ���     IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.���b�gNO     IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�����N����   IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�ܖ�����     IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�ŗL�L��     IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�o��������   IS '�o��������'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�W�������P�� IS '�W�������P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�W���������z IS '�W���������z'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�������z     IS '�������z'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�ō����z     IS '�ō����z'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.���Y�����z   IS '���Y�����z'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�o�������z   IS '�o�������z'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�o�����P��   IS '�o�����P��'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.�P������     IS '�P������'
/
COMMENT ON COLUMN APPS.XXSKZ_���Y��������_��{_V.��������     IS '��������'
/
