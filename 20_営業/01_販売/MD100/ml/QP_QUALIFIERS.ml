/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Master Name     : qp_qualifiers
 * Description     : クオリファイアマテリアライズドビューログ
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2024/06/03    1.0   Y.Ooyama       初回作成
 ************************************************************************/
CREATE MATERIALIZED VIEW LOG ON qp.qp_qualifiers
  WITH ROWID
  ;
