CREATE OR REPLACE VIEW xxcmn_v_lot_v
(
  item_id
 ,item_no
 ,lot_id
 ,lot_no
 ,attribute1
 ,attribute2
)
AS
  SELECT DISTINCT 
        ilm.item_id
       ,iimb.item_no
       ,ilm.lot_id
       ,ilm.lot_no
       ,ilm.attribute1
       ,ilm.attribute2
  FROM  ic_item_mst_b      iimb,
        ic_lots_mst        ilm
  WHERE iimb.item_id = ilm.item_id
  AND   ilm.lot_id > 0
;
