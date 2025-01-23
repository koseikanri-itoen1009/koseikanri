/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Master Name     : hz_locations
 * Description     : 事業所マスタマテリアライズドビューログ
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2024/01/17    1.0  Y.Kubota       初回作成
 ************************************************************************/
CREATE MATERIALIZED VIEW LOG ON ar.hz_locations
  WITH PRIMARY KEY
  ;
