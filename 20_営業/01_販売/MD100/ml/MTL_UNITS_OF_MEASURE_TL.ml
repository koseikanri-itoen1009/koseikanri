/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Master Name     : mtl_units_of_measure_tl
 * Description     : 単位名称マスタマテリアライズドビューログ
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2024/01/17    1.0  Y.Kubota       初回作成
 ************************************************************************/
CREATE MATERIALIZED VIEW LOG ON inv.mtl_units_of_measure_tl
  WITH ROWID
  ;
