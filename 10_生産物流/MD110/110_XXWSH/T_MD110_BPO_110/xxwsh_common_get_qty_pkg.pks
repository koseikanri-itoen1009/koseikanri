CREATE OR REPLACE PACKAGE xxwsh_common_get_qty_pkg 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwsh_common_get_qty_pkg(SPEC)
 * Description            : ¤ÊÖø(SPEC)
 * MD.070(CMD.050)        : Èµ
 * Version                : 1.4
 *
 * Program List
 *  ----------------------   ---- ----- --------------------------------------------------
 *   Name                    Type  Ret   Description
 *  ----------------------   ---- ----- --------------------------------------------------
 *  get_demsup_qy             F    NUM   ÝÉÈOÌøÂ\
 *  get_stock_qty             F    NUM   ÝÉæ¾
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/12/25   1.0   Oracle k¦³v VKì¬
 *  2009/01/21   1.1   SCSñr           {ÔáQ#1020
 *  2009/11/25   1.2   SCSk¦         cÆáQÇ\No11
 *  2009/11/27   1.3   SCSÉ¡           cÆáQÇ\No11
 *  2010/02/23   1.4   SCSÉ¡           E_{Ò®_01612Î
 *****************************************************************************************/
--
  FUNCTION get_demsup_qty (it_item_id   IN ic_item_mst_b.item_id%TYPE
                          ,it_lot_ctl   IN ic_item_mst_b.lot_ctl%TYPE
                          ,it_lot_id    IN ic_lots_mst.lot_id%TYPE
                          ,it_lot_no    IN ic_lots_mst.lot_no%TYPE
                          ,it_org_id    IN mtl_system_items_b.organization_id%TYPE
                          ,id_trn_date  IN DATE
                          ,id_max_date  IN DATE
                          ,it_loc_id    IN mtl_item_locations.inventory_location_id%TYPE
                          ,it_loc_code  IN mtl_item_locations.segment1%TYPE
                          ,it_head_loc  IN mtl_item_locations.segment1%TYPE
                          ,it_dummy_loc IN mtl_item_locations.segment1%TYPE) RETURN NUMBER;
--
  FUNCTION get_stock_qty  (it_item_id   IN ic_item_mst_b.item_id%TYPE
                          ,it_lot_ctl   IN ic_item_mst_b.lot_ctl%TYPE
                          ,it_lot_id    IN ic_lots_mst.lot_id%TYPE
                          ,it_loc_id    IN mtl_item_locations.inventory_location_id%TYPE) RETURN NUMBER;
--
END xxwsh_common_get_qty_pkg;
/
