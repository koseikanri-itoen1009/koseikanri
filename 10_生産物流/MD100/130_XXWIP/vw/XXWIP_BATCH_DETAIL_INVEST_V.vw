CREATE OR REPLACE VIEW apps.xxwip_batch_detail_invest_v
(
  row_id
, batch_id               -- �o�b�`ID
, material_detail_id     -- ���Y�����ڍ�ID
, line_no                -- �s�ԍ�
, item_id                -- �i��ID
, item_no                -- �i�ڃR�[�h
, item_short_name        -- �i��(����)
, item_um                -- �P��
, slit                   -- ������
, slit_name              -- ������(����)
, original_qty           -- �v�搔
, request_qty_all        -- �˗�����
, instructions_qty_all   -- �w������
, out_whse_1             -- �o�q��1
, out_whse_2             -- �o�q��2
, out_whse_3             -- �o�q��3
, out_whse_4             -- �o�q��4
, out_whse_5             -- �o�q��5
, comments               -- �R�����g
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
)
AS
  SELECT
    gmd.rowid                       row_id
  , gbh.batch_id                    batch_id               -- �o�b�`ID
  , gmd.material_detail_id          material_detail_id     -- ���Y�����ڍ�ID
  , gmd.line_no                     line_no                -- �s�ԍ�
  , xim2v.item_id                   item_id                -- �i��ID
  , xim2v.item_no                   item_no                -- �i�ڃR�[�h
  , xim2v.item_short_name           item_short_name        -- �i��(����)
  , xim2v.item_um                   item_um                -- �P��
  , gbsi_sq.slit                    slit                   -- ������
  , gbsi_sq.slit_name               slit_name              -- ������(����)
-- 2009/01/20 D.Nihei Mod Start
--  , gmd.original_qty                original_qty           -- �v�搔
  , NVL(gmd.attribute25, gmd.original_qty)
                                    original_qty           -- �v�搔
-- 2009/01/20 D.Nihei Mod End
-- 2009/03/06 D.Nihei Mod Start �{�ԏ�Q#1278
--  , TO_NUMBER( gmd.attribute7 )     request_qty_all        -- �˗�����
  , NVL(TO_NUMBER( gmd.attribute7 ), 0)
                                    request_qty_all        -- �˗�����
-- 2009/03/06 D.Nihei Mod End
  , NVL( xmd_sq.instructions_qty, 0 )
                                    instructions_qty_all   -- �w������
  , gmd.attribute13                 out_whse_1             -- �o�q��1
  , gmd.attribute18                 out_whse_2             -- �o�q��2
  , gmd.attribute19                 out_whse_3             -- �o�q��3
  , gmd.attribute20                 out_whse_4             -- �o�q��4
  , gmd.attribute21                 out_whse_5             -- �o�q��5
  , DECODE( xmd_sq.location_count
          , NULL, '�����Ă��Ă��܂���'
          , 0, '�����Ă��Ă��܂���'
          , 1, '�P��q�ɂň�������Ă��܂�'
          , '�����q�ɂň�������Ă��܂�' )
                                    comments               -- �R�����g
  , gmd.created_by
  , gmd.creation_date
  , gmd.last_updated_by
  , gmd.last_update_date
  , gmd.last_update_login
  FROM
    xxcmn_item_locations_v          xilv          -- �ۊǑq��(�[�i�ꏊ)
  , gmd_routings_vl                 grv           -- �H���}�X�^VIEW
  , xxcmn_item_mst2_v               xim2v         -- OPM�i��VIEW
  , gme_batch_header                gbh           -- ���Y�o�b�`�w�b�_
  , gme_material_details            gmd           -- ���Y�����ڍ�
  , (
      SELECT
        gbsi.material_detail_id         material_detail_id
      , gbs.batchstep_no                slit  
      , gov.oprn_desc                   slit_name -- �������敪��
      FROM
        gme_batch_steps                 gbs       -- �o�b�`�X�e�b�v
      , gme_batch_step_items            gbsi      -- �o�b�`�X�e�b�v�i��
      , gmd_operations_vl               gov       -- �H���}�X�^�r���[
      WHERE
            gbs.batchstep_id = gbsi.batchstep_id
        AND gov.oprn_id      = gbs.oprn_id
    ) gbsi_sq
  , (
      SELECT
        SUM( xmd.instructions_qty )     instructions_qty
      , COUNT( DISTINCT xmd.location_code )
                                        location_count
      , xmd.batch_id                    batch_id
      , xmd.material_detail_id          material_detail_id
      FROM
        xxwip_material_detail           xmd     -- ���Y�����ڍ׃A�h�I��
      WHERE
            xmd.plan_type IN ( '1', '2', '3' )
-- 2009/03/06 D.Nihei Add Start �{�ԏ�Q#1280
      AND   EXISTS(SELECT 1
                   FROM   xxwip_material_detail xmdd
                   WHERE  xmdd.material_detail_id = xmd.material_detail_id
                   AND    xmdd.plan_type          = '4'
                   AND    ROWNUM                  = 1)
-- 2009/03/06 D.Nihei Add End
      GROUP BY
        batch_id
      , material_detail_id
    ) xmd_sq
  WHERE
        xilv.segment1              (+) = grv.attribute9
    AND grv.routing_id                 = gbh.routing_id
    AND xim2v.item_id                  = gmd.item_id
    AND xim2v.start_date_active        <= TRUNC( gbh.plan_start_date )
    AND xim2v.end_date_active          >= TRUNC( gbh.plan_start_date )
    AND gbh.batch_id                   = gmd.batch_id
    AND xmd_sq.batch_id            (+) = gmd.batch_id
    AND xmd_sq.material_detail_id  (+) = gmd.material_detail_id
    AND gbsi_sq.material_detail_id (+) = gmd.material_detail_id
    AND gmd.line_type                  = -1                            -- �����i
    AND gmd.attribute5                 IS NULL                         -- ����
    AND gmd.attribute24                IS NULL
/
