CREATE OR REPLACE PACKAGE xxwsh400006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400006c(spec)
 * Description      : 出荷依頼確定処理
 * MD.050           : T_MD050_BPO_401_出荷依頼
 * MD.070           : 出荷依頼確定処理 T_MD070_EDO_BPO_40G
 * Version          : 1.4
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
 *  2008/3/24     1.0   R.Matusita       新規作成
 *  2008/4/23     1.1   R.Matusita       内部変更要求#63
 *  2009/4/20     1.3   Y.Kazama         本番障害#1398対応
 *  2009/4/20     1.4   M.Miyagawa       本番障害#1671対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,         -- エラーメッセージ #固定#
    retcode                  OUT NOCOPY VARCHAR2,         -- エラーコード     #固定#
    iv_prod_class            IN  VARCHAR2,                -- 商品区分
    iv_head_sales_branch     IN  VARCHAR2,                -- 管轄拠点
    iv_input_sales_branch    IN  VARCHAR2,                -- 入力拠点
    iv_deliver_to_id         IN  VARCHAR2,                -- 配送先ID
    iv_request_no            IN  VARCHAR2,                -- 依頼No
    iv_schedule_ship_date    IN  VARCHAR2,                -- 出庫日
    iv_schedule_arrival_date IN  VARCHAR2,                -- 着日
    iv_status_kbn            IN  VARCHAR2                 -- 締めステータスチェック区分
  );
END xxwsh400006c;
/
