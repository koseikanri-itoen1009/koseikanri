/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Master Name     : hz_customer_profiles
 * Description     : 顧客プロファイルマテリアライズドビューログ
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2024/06/21    1.0   T.Nishikawa    初回作成
 ************************************************************************/
CREATE MATERIALIZED VIEW LOG ON ar.hz_customer_profiles
  WITH ROWID
  ;
