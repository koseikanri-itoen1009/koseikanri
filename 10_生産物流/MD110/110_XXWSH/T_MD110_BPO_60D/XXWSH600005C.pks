CREATE OR REPLACE PACKAGE xxwsh600005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600005c(spec)
 * Description      : 確定ブロック処理
 * MD.050           : 出荷依頼 T_MD050_BPO_601
 * MD.070           : 確定ブロック処理  T_MD070_BPO_60D
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/18    1.0  Oracle 上原正好   初回作成
 *  2008/06/16    1.1  Oracle 野村正幸   結合障害 #9対応
 *  2008/06/19    1.2  Oracle 上原正好   ST障害 #178対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT NOCOPY VARCHAR2,  -- エラーメッセージ #固定#
    retcode                   OUT NOCOPY VARCHAR2,  -- エラーコード     #固定#
    iv_dept_code              IN VARCHAR2,          -- 部署
    iv_shipping_biz_type      IN VARCHAR2,          -- 処理種別
    iv_transaction_type_id    IN VARCHAR2,          -- 出庫形態
    iv_lead_time_day_01       IN VARCHAR2,          -- 生産物流LT1
    iv_lt1_ship_date_from     IN VARCHAR2,          -- 生産物流LT1/出荷依頼/出庫日From
    iv_lt1_ship_date_to       IN VARCHAR2,          -- 生産物流LT1/出荷依頼/出庫日To
    iv_lead_time_day_02       IN VARCHAR2,          -- 生産物流LT2
    iv_lt2_ship_date_from     IN VARCHAR2,          -- 生産物流LT2/出荷依頼/出庫日From
    iv_lt2_ship_date_to       IN VARCHAR2,          -- 生産物流LT2/出荷依頼/出庫日To
    iv_ship_date_from         IN VARCHAR2,          -- 出庫日From
    iv_ship_date_to           IN VARCHAR2,          -- 出庫日To
    iv_move_ship_date_from    IN VARCHAR2,          -- 移動/出庫日From
    iv_move_ship_date_to      IN VARCHAR2,          -- 移動/出庫日To
    iv_prov_ship_date_from    IN VARCHAR2,          -- 支給/出庫日From
    iv_prov_ship_date_to      IN VARCHAR2,          -- 支給/出庫日To
    iv_block_01               IN VARCHAR2,          -- ブロック１
    iv_block_02               IN VARCHAR2,          -- ブロック２
    iv_block_03               IN VARCHAR2,          -- ブロック３
    iv_shipped_locat_code     IN VARCHAR2           -- 出庫元
  );
END xxwsh600005c;
/
