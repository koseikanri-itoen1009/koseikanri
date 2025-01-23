/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Master Name     : mtl_item_categories
 * Description     : 品目カテゴリマテリアライズドビューログ
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2024/06/19    1.0   T.Nishikawa    初回作成
 ************************************************************************/
CREATE MATERIALIZED VIEW LOG ON inv.mtl_item_categories
  WITH ROWID
  ;
