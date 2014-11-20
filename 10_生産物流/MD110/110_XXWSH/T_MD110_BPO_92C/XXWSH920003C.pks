CREATE OR REPLACE PACKAGE APPS.XXWSH920003C AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920003C(spec)
 * Description      : 生産物流(引当、配車)
 * MD.050           : 計画・移動・在庫・販売計画/引取計画 T_MD050_BPO921
 * MD.070           : 計画・移動・在庫・販売計画/引取計画 T_MD070_BPO92E
 * Version          : 1.0
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
 *  2008/04/23   1.0   Oracle 土田 茂   初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,   -- エラーメッセージ #固定#
    retcode                  OUT NOCOPY VARCHAR2,   -- エラーコード     #固定#
    iv_action_type           IN         VARCHAR2,   -- 処理種別
    iv_req_mov_no            IN         VARCHAR2,   -- 依頼/移動No
    iv_deliver_from_id       IN         VARCHAR2,   -- 出庫元
    iv_deliver_type          IN         VARCHAR2,   -- 出庫形態
    iv_object_date_from      IN         VARCHAR2,   -- 対象期間From
    iv_object_date_to        IN         VARCHAR2,   -- 対象期間To
    iv_shipped_date          IN         VARCHAR2,   -- 出庫日指定
    iv_arrival_date          IN         VARCHAR2,   -- 着日指定
    iv_instruction_post_code IN         VARCHAR2    -- 指示部署指定
  );
END XXWSH920003C;
/
