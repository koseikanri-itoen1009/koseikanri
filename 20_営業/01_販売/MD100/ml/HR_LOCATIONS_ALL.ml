/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Master Name     : hr_locations_all
 * Description     : 事業所マスタマテリアライズドビューログ
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2024/11/21    1.0  S.Taguchi       初回作成
 ************************************************************************/
CREATE MATERIALIZED VIEW LOG ON hr.hr_locations_all
  WITH PRIMARY KEY
  ;
