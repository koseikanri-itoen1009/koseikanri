CREATE OR REPLACE PACKAGE xxinv540001_p
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv540001(SPEC)
 * Description            : 在庫照会画面データソースパッケージ(SPEC)
 * MD.050                 : T_MD050_BPO_540_在庫照会Issue1.0.doc
 * MD.070                 : T_MD070_BPO_54A_在庫照会画面Draft1A.doc
 * Version                : 1.23
 *
 * Program List
 *  --------------------  ---- ----- -------------------------------------------------
 *   Name                 Type  Ret   Description
 *  --------------------  ---- ----- -------------------------------------------------
 *  blk_ilm_qry             P    -    データ取得
 *  get_parent_item_id      F   NUM   親品目ID取得
 *  get_attribute5          F   VAR   代表倉庫取得
 *  get_organization_id     F   NUM   在庫組織ID取得
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/16   1.0   Jun.Komatsu      新規作成
 *  2008/03/13   1.1   Jun.Komatsu      変更要求#15、#7対応
 *  2008/04/18   1.3   Jun.Komatsu      変更要求#43、#51対応
 *  2008/05/26   1.4   Kazuo.Kumamoto   変更要求##119対応
 *  2008/06/13   1.5   Yuko.Kawano      結合テスト不具合対応
 *  2008/06/25   1.6   S.Takemoto       変更要求##93対応
 *  2008/09/03   1.7   N.Yoshida        PT対応(起票なし)
 *  2008/09/24   1.8   T.Ohashi         PT 1-1_2 指摘39,変更#139対応
 *  2008/10/29   1.9   T.Ohashi         PT 1-1_2再対応
 *  2008/11/19   1.10  T.Ohashi         指摘681対応
 *  2008/12/02   1.11  D.Nihei          本番障害#251対応（条件追加）
 *  2008/12/15   1.12  H.Itou           本番障害#645対応（D4、S4取得時は予定日でなく実績日を基準とする。）
 *  2008/12/19   1.13  H.Itou           本番障害#648対応（I5、I6取得数量は実績数量－前回数量）
 *  2008/12/24   1.14  T.Ohashi         本番障害#836対応（条件追加）
 *  2009/01/20   1.15  N.Yoshida        本番障害#1056対応
 *  2009/01/21   1.16  N.Yoshida        本番障害#1050対応
 *  2009/02/02   1.17  Y.Yamamoto       本番障害#1084対応
 *  2009/04/09   1.18  H.Marushita      本番障害#1346対応
 *  2009/12/22   1.19  M.Hokkanji       本番稼働障害#518対応
 *  2009/12/21   1.20  H.Itou           本番稼働障害#518対応
 *  2009/12/25   1.20  M.Hokkanji       本番稼働障害#518対応(Ver1.9で追加したヒント句を元に戻す)
 *  2009/12/25   1.20PT M.Hokkanji      本番稼働障害#518対応のため最新の状態を反映
 *  2009/12/29   1.21  H.Itou           本番稼働障害#518対応(カーソル1,2,3対応)
 *  2010/01/12   1.22  H.Itou           本番稼働障害#518対応(カーソル18再対応)
 *  2010/01/26   1.23  H.Itou           本番稼働障害#518対応(カーソル17再対応)
 *****************************************************************************************/
--
  --#######################  パッケージ変数宣言部 START   #######################
--
  -- 在庫照会画面基礎表となるレコード定義
  TYPE rec_ilm_block IS RECORD(
         rec_no                     NUMBER,
         xilv_segment1              xxcmn_item_locations_v.segment1%TYPE,
         xilv_description           xxcmn_item_locations_v.short_name%TYPE,
         xilv_inventory_location_id xxcmn_item_locations_v.inventory_location_id%TYPE,
         ximv_item_id               xxcmn_item_mst_v.item_id%TYPE,
         ximv_item_no               xxcmn_item_mst_v.item_no%TYPE,
         ximv_item_short_name       xxcmn_item_mst_v.item_short_name%TYPE,
         ilm_lot_no                 ic_lots_mst.lot_no%TYPE,
         ilm_lot_id                 ic_lots_mst.lot_id%TYPE,
         ilm_attribute1             DATE,
         ilm_attribute3             DATE,
         ilm_attribute2             ic_lots_mst.attribute2%TYPE,
         ilm_attribute4             DATE,
         ilm_attribute5             DATE,
         ilm_attribute6             NUMBER,
         ilm_attribute7             NUMBER,
         ilm_attribute8             ic_lots_mst.attribute8%TYPE,
         xvv_vendor_short_name      xxcmn_vendors_v.vendor_short_name%TYPE,
         ilm_attribute9             ic_lots_mst.attribute9%TYPE,
         xlvv_xl5_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ilm_attribute10            ic_lots_mst.attribute10%TYPE,
         xlvv_xl6_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ilm_attribute11            ic_lots_mst.attribute11%TYPE,
         ilm_attribute12            ic_lots_mst.attribute12%TYPE,
         xlvv_xl7_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ilm_attribute13            ic_lots_mst.attribute13%TYPE,
         xlvv_xl8_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ilm_attribute14            ic_lots_mst.attribute14%TYPE,
         ilm_attribute15            ic_lots_mst.attribute15%TYPE,
         ilm_attribute19            ic_lots_mst.attribute19%TYPE,
         ilm_attribute16            ic_lots_mst.attribute16%TYPE,
         xlvv_xl3_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ilm_attribute17            ic_lots_mst.attribute17%TYPE,
         grb_routing_desc           gmd_routings_b.routing_desc%TYPE,
         ilm_attribute18            ic_lots_mst.attribute18%TYPE,
         ilm_attribute23            ic_lots_mst.attribute23%TYPE,
         xqi_qt_inspect_req_no      xxwip_qt_inspection.qt_inspect_req_no%TYPE,
         xlvv_xqs_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ili_loct_onhand            ic_loct_inv.loct_onhand%TYPE,
         inv_stock_vol              NUMBER,
         subtractable               NUMBER,
         supply_stock_plan          NUMBER,
         take_stock_plan            NUMBER,
         ilm_created_by             ic_lots_mst.created_by%TYPE,
         ilm_creation_date          ic_lots_mst.creation_date%TYPE,
         ilm_last_updated_by        ic_lots_mst.last_updated_by%TYPE,
         ilm_last_update_date       ic_lots_mst.last_update_date%TYPE,
         ilm_last_update_login      ic_lots_mst.last_update_login%TYPE,
         xilv_frequent_whse         xxcmn_item_locations_v.frequent_whse%TYPE,
         ximv_num_of_cases          xxcmn_item_mst_v.num_of_cases%TYPE);
--
  -- 在庫照会画面基礎表となる索引付きレコード
  TYPE tbl_ilm_block IS TABLE OF rec_ilm_block
  INDEX BY BINARY_INTEGER;
--
  --#######################  パッケージ変数宣言部 END   #######################
--
  --#######################  パッケージプロシージャ宣言部 START   #######################
--
  PROCEDURE blk_ilm_qry(
              ior_ilm_data              IN OUT NOCOPY tbl_ilm_block,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,          --品目ID
              iv_parent_div             IN VARCHAR2,                               --親コード区分
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
                                                                                   --保管倉庫ID
              iv_deleg_house            IN VARCHAR2,                               --代表倉庫照会
              iv_ext_warehouse          IN VARCHAR2,                               --倉庫抽出フラグ
              iv_item_div_code          IN xxcmn_item_categories_v.segment1%TYPE,  --品目区分コード
              iv_prod_div_code          IN xxcmn_item_categories_v.segment1%TYPE,  --商品区分コード
              iv_unit_div               IN VARCHAR2,                               --単位区分
              iv_qt_status_code         IN xxwip_qt_inspection.qt_effect1%TYPE,    --品質判定結果
              id_manu_date_from         IN DATE,                                   --製造年月日From
              id_manu_date_to           IN DATE,                                   --製造年月日To
              iv_prop_sign              IN ic_lots_mst.attribute2%TYPE,            --固有記号
              id_consume_from           IN DATE,                                   --賞味期限From
              id_consume_to             IN DATE,                                   --賞味期限To
              iv_lot_no                 IN ic_lots_mst.lot_no%TYPE,                --ロット№
              iv_register_code          IN xxcmn_item_locations_v.customer_stock_whse%TYPE,
                                                                                   --名義コード
              id_effective_date         IN DATE,                                   --有効日付
              iv_ext_show               IN VARCHAR2);                              --在庫有だけ表示
--
  --#######################  パッケージプロシージャ宣言部 END   #######################
--
  --#######################  パッケージファンクション宣言部 START   #######################
--
  FUNCTION  get_parent_item_id(
              in_parent_item_id         IN xxcmn_item_mst_v.item_id%TYPE)
              RETURN NUMBER;
--
  FUNCTION  get_attribute5(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE)
              RETURN VARCHAR2;
--
  FUNCTION  get_organization_id(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE)
              RETURN NUMBER;
--
  --#######################  パッケージファンクション宣言部 END   #######################
--
END xxinv540001_p;
/
