CREATE OR REPLACE VIEW apps.xxwip_batch_all_v
(
  row_id
, duty_status                     -- �Ɩ��X�e�[�^�X
, duty_status_name                -- �Ɩ��X�e�[�^�X(����)
, duty_status_order               -- �Ɩ��X�e�[�^�X(�\�[�g�p)
, batch_id                        -- �o�b�`ID
, batch_no                        -- �o�b�`No
, material_detail_id              -- ���Y�����ڍ�ID
, trans_id                        -- �ۗ��݌Ƀg�����U�N�V����ID
, item_id                         -- �i��ID
, item_no                         -- �i�ڃR�[�h
, item_short_name                 -- �i��(����)
, lot_id                          -- ���b�gID
, lot_no                          -- ���b�gNo
, routing_id                      -- �H��ID
, routing_no                      -- �H��No
, routing_name                    -- ���C�����E����
, slip_type                       -- �`�[�敪
, slip_type_name                  -- �`�[�敪(����)
, in_out_type                     -- ���O�敪
, product_plan_date               -- ���Y�\���
, store_plan_date                 -- �������ɗ\���
, product_date                    -- ���Y��
, maker_date                      -- ������
, use_by_date                     -- �ܖ�������
, request_qty                     -- �˗�����
, instructions_qty                -- �w�}����
, actual_qty                      -- ���ѐ�
, delivery_location               -- �[�i�ꏊ
, delivery_location_name          -- �[�i�ꏊ����
, move_location                   -- �ړ��ꏊ
, move_location_name              -- �ړ��ꏊ����
, wip_whse_code                   -- WIP�q�ɃR�[�h
, send_class                      -- ���M�敪
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
)
AS
  SELECT
    gbh.rowid                                                     row_id
  , gbh.attribute4                                                duty_status                     -- �Ɩ��X�e�[�^�X
  , xlvv_status.meaning                                           duty_status_name                -- �Ɩ��X�e�[�^�X(����)
  , DECODE( gbh.attribute4
          , '-1', '99'
          , gbh.attribute4 )
                                                                  duty_status_order               -- �Ɩ��X�e�[�^�X(�\�[�g�p)
  , gbh.batch_id                                                  batch_id                        -- �o�b�`ID
  , gbh.batch_no                                                  batch_no                        -- �o�b�`No
  , gmd.material_detail_id                                        material_detail_id              -- ���Y�����ڍ�ID
  , itp.trans_id                                                  trans_id                        -- �ۗ��݌Ƀg�����U�N�V����ID
  , xim2v.item_id                                                 item_id                         -- �i��ID
  , xim2v.item_no                                                 item_no                         -- �i�ڃR�[�h
  , xim2v.item_short_name                                         item_short_name                 -- �i��(����)
  , ilm.lot_id                                                    lot_id                          -- ���b�gID
  , ilm.lot_no                                                    lot_no                          -- ���b�gNo
  , grv.routing_id                                                routing_id                      -- �H��ID
  , grv.routing_no                                                routing_no                      -- �H��No
  , grv.attribute1                                                routing_name                    -- ���C�����E����
  , grv.attribute13                                               slip_type                       -- �`�[�敪
  , xlvv_l03.meaning                                              slip_type_name                  -- �`�[�敪(����)
  , grv.attribute15                                               in_out_type                     -- ���O�敪
  , gbh.plan_start_date                                           product_plan_date               -- ���Y�\���
  , FND_DATE.STRING_TO_DATE( gmd.attribute22, 'RRRR/MM/DD' )      store_plan_date                 -- �������ɗ\���
  , FND_DATE.STRING_TO_DATE( gmd.attribute11, 'RRRR/MM/DD' )      product_date                    -- ���Y��
  , FND_DATE.STRING_TO_DATE( gmd.attribute17, 'RRRR/MM/DD' )      maker_date                      -- ������
  , FND_DATE.STRING_TO_DATE( gmd.attribute10, 'RRRR/MM/DD' )      use_by_date                     -- �ܖ�������
  , xxcmn_common_pkg.rcv_ship_conv_qty(
      '2', xim2v.item_id, TO_NUMBER( gmd.attribute7 ) )           request_qty                     -- �˗�����
  , xxcmn_common_pkg.rcv_ship_conv_qty(
      '2', xim2v.item_id, TO_NUMBER( gmd.attribute23 ) )          instructions_qty                -- �w�}����
  , xxcmn_common_pkg.rcv_ship_conv_qty(
      '2', xim2v.item_id, gmd.actual_qty )                        actual_qty                      -- ���ѐ�
  , grv.attribute9                                                delivery_location               -- �[�i�ꏊ
  , xilv_deli.description                                         delivery_location_name          -- �[�i�ꏊ����
  , gmd.attribute12                                               move_location                   -- �ړ��ꏊ
  , xilv_move.description                                         move_location_name              -- �ړ��ꏊ����
  , gbh.wip_whse_code                                             wip_whse_code                   -- WIP�q�ɃR�[�h
  , gbh.attribute3                                                send_class                      -- ���M�敪
  , gbh.created_by                                                created_by
  , gbh.creation_date                                             creation_date
  , gbh.last_updated_by                                           last_updated_by
  , gbh.last_update_date                                          last_update_date
  , gbh.last_update_login                                         last_update_login
  FROM
    xxcmn_lookup_values_v           xlvv_status   -- �Ɩ��X�e�[�^�X
  , xxcmn_lookup_values_v           xlvv_l03      -- �`�[�敪
  , xxcmn_item_locations_v          xilv_deli     -- �ۊǏꏊ�}�X�^(�[�i�ꏊ)
  , xxcmn_item_locations_v          xilv_move     -- �ۊǏꏊ�}�X�^(�ړ��ꏊ)
  , gmd_routings_vl                 grv           -- �H���}�X�^
  , xxcmn_item_mst2_v               xim2v         -- OPM�i��VIEW
  , ic_lots_mst                     ilm           -- OPM���b�g
  , ic_tran_pnd                     itp           -- OPM�ۗ��݌Ƀg�����U�N�V����
  , gme_material_details            gmd           -- ���Y�����ڍ�
  , gme_batch_header                gbh           -- ���Y�o�b�`�w�b�_
  WHERE
        xlvv_status.lookup_code (+) = gbh.attribute4
    AND xlvv_status.lookup_type (+) = 'XXWIP_DUTY_STATUS'
    AND xlvv_l03.lookup_code    (+) = grv.attribute13
    AND xlvv_l03.lookup_type    (+) = 'XXCMN_L03'
    AND xilv_deli.segment1      (+) = grv.attribute9
    AND grv.routing_id              = gbh.routing_id
    AND xim2v.item_id           (+) = gmd.item_id
    AND xim2v.start_date_active     <= TRUNC( gbh.plan_start_date )
    AND xim2v.end_date_active       >= TRUNC( gbh.plan_start_date )
    AND xilv_move.segment1      (+) = gmd.attribute12
    AND ilm.lot_id              (+) = itp.lot_id
    AND ilm.item_id             (+) = itp.item_id
    AND itp.reverse_id              IS NULL
    AND itp.delete_mark         (+) = 0
    AND itp.lot_id              (+) > 0
    AND itp.line_id             (+) = gmd.material_detail_id
    AND gbh.attribute4              IS NOT NULL
    AND gmd.line_type               = 1
    AND gmd.batch_id                = gbh.batch_id
/
