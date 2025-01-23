/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Master Name     : hz_cust_acct_relate_all
 * Description     : 顧客関連マテリアライズドビューログ
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2024/06/20    1.0   T.Nishikawa    初回作成
 ************************************************************************/
CREATE MATERIALIZED VIEW LOG ON ar.hz_cust_acct_relate_all
  WITH ROWID
  ;
