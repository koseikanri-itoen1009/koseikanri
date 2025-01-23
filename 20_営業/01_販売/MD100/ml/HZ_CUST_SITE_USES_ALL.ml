/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Master Name     : hz_cust_site_uses_all
 * Description     : 顧客使用目的マテリアライズドビューログ
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2024/01/17    1.0  Y.Kubota       初回作成
 ************************************************************************/
CREATE MATERIALIZED VIEW LOG ON ar.hz_cust_site_uses_all
  WITH PRIMARY KEY
  ;
