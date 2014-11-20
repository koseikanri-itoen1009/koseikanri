CREATE OR REPLACE VIEW apps.xxwip_batch_header_v
(
  row_id
, duty_status                     -- �Ɩ��X�e�[�^�X
, duty_status_name                -- �Ɩ��X�e�[�^�X(����)
, batch_id                        -- �o�b�`ID
, batch_no                        -- �o�b�`No
, plant_code                      -- �v�����g�R�[�h
, recipe_validity_rule_id         -- �Ó������[��ID
, material_detail_id              -- ���Y�����ڍ�ID
, formulaline_id                  -- �t�H�[�~��������ID
, trans_id                        -- �ۗ��݌Ƀg�����U�N�V����ID
, item_id                         -- �i��ID
, item_no                         -- �i�ڃR�[�h
, item_short_name                 -- �i��(����)
, item_class_code                 -- �i�ڋ敪
, item_class_name                 -- �i�ڋ敪(����)
, lot_id                          -- ���b�gID
, lot_no                          -- ���b�gNo
, routing_id                      -- �H��ID
, routing_no                      -- �H��No
, routing_name                    -- ���C�����E����
, shinkansen_type                 -- �V�ʐ��敪
, unique_sign                     -- �ŗL�L��
, destination_div                 -- �d���敪
, slip_type                       -- �`�[�敪
, slip_type_name                  -- �`�[�敪(����)
, in_out_type                     -- ���O�敪
, item_um                         -- �P��
, product_plan_date               -- ���Y�\���
, store_plan_date                 -- �������ɗ\���
, request_qty                     -- �˗�����
, instructions_qty                -- �w�}����
, delivery_location_id            -- �[�i�ꏊID
, delivery_location               -- �[�i�ꏊ
, delivery_location_name          -- �[�i�ꏊ����
, move_location_id                -- �ړ��ꏊID
, move_location                   -- �ړ��ꏊ
, move_location_name              -- �ړ��ꏊ����
, material_type                   -- �^�C�v
, material_type_name              -- �^�C�v(����)
, rank1                           -- �����N1
, rank2                           -- �����N2
, wip_whse_code                   -- WIP�q�ɃR�[�h
, send_class                      -- ���M�敪
, result_management_post          -- ���ъǗ�����
, result_management_post_name     -- ���ъǗ�����(����)
, remarks_column                  -- �E�v
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
, detail_last_update_date
)
AS
  SELECT
    gbh.rowid                                     row_id
  , gbh.attribute4                                duty_status                     -- �Ɩ��X�e�[�^�X
  , xlvv_status.meaning                           duty_status_name                -- �Ɩ��X�e�[�^�X(����)
  , gbh.batch_id                                  batch_id                        -- �o�b�`ID
  , gbh.batch_no                                  batch_no                        -- �o�b�`No
  , gbh.plant_code                                plant_code                      -- �v�����g�R�[�h
  , gbh.recipe_validity_rule_id                   recipe_validity_rule_id         -- �Ó������[��ID
  , gmd.material_detail_id                        material_detail_id              -- ���Y�����ڍ�ID
  , gmd.formulaline_id                            formulaline_id                  -- �t�H�[�~��������ID
  , itp.trans_id                                  trans_id                        -- �ۗ��݌Ƀg�����U�N�V����ID
  , xim2v.item_id                                 item_id                         -- �i��ID
  , xim2v.item_no                                 item_no                         -- �i�ڃR�[�h
  , xim2v.item_short_name                         item_short_name                 -- �i��(����)
  , xic5v.item_class_code                         item_class_code                 -- �i�ڋ敪
  , xic5v.item_class_name                         item_class_name                 -- �i�ڋ敪(����)
  , ilm.lot_id                                    lot_id                          -- ���b�gID
  , ilm.lot_no                                    lot_no                          -- ���b�gNo
  , grv.routing_id                                routing_id                      -- �H��ID
  , grv.routing_no                                routing_no                      -- �H��No
  , grv.attribute1                                routing_name                    -- ���C�����E����
  , grv.attribute17                               shinkansen_type                 -- �V�ʐ��敪
  , grv.attribute19                               unique_sign                     -- �ŗL�L��
  , xim2v.destination_div                         destination_div                 -- �d���敪
  , grv.attribute13                               slip_type                       -- �`�[�敪
  , xlvv_l03.meaning                              slip_type_name                  -- �`�[�敪(����)
  , grv.attribute15                               in_out_type                     -- ���O�敪
  , CASE
      WHEN ( ( grv.attribute16 = '3' ) AND ( xic5v.item_class_code = '5' ) )
        THEN xim2v.conv_unit
        ELSE xim2v.item_um
    END                                           item_um                         -- �P��
  , gbh.plan_start_date                           product_plan_date               -- ���Y�\���
  , FND_DATE.STRING_TO_DATE(
      gmd.attribute22, 'RRRR/MM/DD' )             store_plan_date                 -- �������ɗ\���
  , xxcmn_common_pkg.rcv_ship_conv_qty(
      '2', xim2v.item_id, TO_NUMBER( gmd.attribute7 ) )
                                                  request_qty                     -- �˗�����
  , xxcmn_common_pkg.rcv_ship_conv_qty(
      '2', xim2v.item_id, TO_NUMBER( gmd.attribute23 ) )
                                                  instructions_qty                -- �w�}����
  , xilv_deli.inventory_location_id               delivery_location_id            -- �[�i�ꏊID
  , grv.attribute9                                delivery_location               -- �[�i�ꏊ
  , xilv_deli.description                         delivery_location_name          -- �[�i�ꏊ(����)
  , xilv_move.inventory_location_id               move_location_id                -- �ړ��ꏊID
  , gmd.attribute12                               move_location                   -- �ړ��ꏊ
  , xilv_move.description                         move_location_name              -- �ړ��ꏊ(����)
  , gmd.attribute1                                material_type                   -- �^�C�v
  , xlvv_l08.meaning                              material_type_name              -- �^�C�v(����)
  , gmd.attribute2                                rank1                           -- �����N1
  , gmd.attribute3                                rank2                           -- �����N2
  , gbh.wip_whse_code                             wip_whse_code                   -- WIP�q�ɃR�[�h
  , gbh.attribute3                                send_class                      -- ���M�敪
  , grv.attribute14                               result_management_post          -- ���ъǗ�����
  , xlvv_l10.meaning                              result_management_post_name     -- ���ъǗ�����(����)
  , gmd.attribute4                                remarks_column                  -- �E�v
  , gbh.created_by                                created_by
  , gbh.creation_date                             creation_date
  , gbh.last_updated_by                           last_updated_by
  , gbh.last_update_date                          last_update_date
  , gbh.last_update_login                         last_update_login
  , gmd.last_update_date                          detail_last_update_date
  FROM
    xxcmn_lookup_values_v           xlvv_status   -- �Ɩ��X�e�[�^�X
  , xxcmn_lookup_values_v           xlvv_l10      -- ���ъǗ�����
  , xxcmn_lookup_values_v           xlvv_l08      -- �^�C�v
  , xxcmn_lookup_values_v           xlvv_l03      -- �`�[�敪
  , xxcmn_item_categories5_v        xic5v         -- �J�e�S��VIEW5
  , xxcmn_item_locations_v          xilv_deli     -- �ۊǏꏊ�}�X�^VIEW(�[�i�ꏊ)
  , xxcmn_item_locations_v          xilv_move     -- �ۊǏꏊ�}�X�^VIEW(�ړ��ꏊ)
  , gmd_routings_vl                 grv           -- �H���}�X�^VIEW
  , xxcmn_item_mst2_v               xim2v         -- OPM�i��VIEW
  , ic_lots_mst                     ilm           -- OPM���b�g
  , ic_tran_pnd                     itp           -- OPM�ۗ��݌Ƀg�����U�N�V����
  , gme_material_details            gmd           -- ���Y�����ڍ�
  , gme_batch_header                gbh           -- ���Y�o�b�`�w�b�_
  WHERE
        xlvv_status.lookup_code (+) = gbh.attribute4
    AND xlvv_status.lookup_type (+) = 'XXWIP_DUTY_STATUS'
    AND xlvv_l10.lookup_code    (+) = grv.attribute14
    AND xlvv_l10.lookup_type    (+) = 'XXCMN_L10'
    AND xlvv_l08.lookup_code    (+) = gmd.attribute1
    AND xlvv_l08.lookup_type    (+) = 'XXCMN_L08'
    AND xlvv_l03.lookup_code    (+) = grv.attribute13
    AND xlvv_l03.lookup_type    (+) = 'XXCMN_L03'
    AND xic5v.item_id           (+) = gmd.item_id
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
-- 2008/09/08 D.Nihei Add Start �������\���Ή�
    AND itp.doc_type            (+) = 'PROD'
-- 2008/09/08 D.Nihei Add End
    AND gmd.line_type               = 1
    AND gmd.batch_id                = gbh.batch_id
/
