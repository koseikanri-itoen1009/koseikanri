CREATE OR REPLACE PACKAGE XXWSH920003C AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920003C(spec)
 * Description      : 移動指示発注依頼自動作成
 * MD.050           : 生産物流共通（出荷・移動仮引当） T_MD050_BPO921
 * MD.070           : 移動指示発注依頼自動作成 T_MD070_BPO92C
 * Version          : 1.6
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
 *  2008/06/11   1.1   Oracle 中田 準   デバッグ出力制御対応。エラーハンドリング不備の修正。
 *                                      重量容積算出/積載効率算出処理をプロシージャ化(C-15)。
 *  2008/07/02   1.2   Oracle 中田 準   ST不具合No368対応
 *                                      在庫補充ルールが発注で、補充先の直送倉庫区分が直送の場合のみ
 *                                      配送先を設定するように修正。
 *                                      その他の場合にはNULLを設定。(配送先毎の集約を行わないため。)
 *  2008/07/31   1.3   Oracle 中田 準   ST不具合No522対応
 *                                      SUBMAINのリターンコード変数の定義誤りによる
 *                                      エラーハンドリング不備の修正。
 *  2008/10/03   1.4   Oracle 中田 準   内部課題#32、内部課題#58/内部変更#166、
 *                                      内部課題#66/内部変更#173、内部変更#183
 *                                      内部変更#233
 *  2008/10/20   1.5   Oracle 福田      統合テスト指摘#240
 *  2008/12/15   1.6   Oracle 福田      本番障害#631
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,   -- エラーメッセージ #固定#
    retcode                  OUT NOCOPY VARCHAR2,   -- エラーコード     #固定#
    iv_action_type           IN         VARCHAR2,   -- 処理種別
    iv_req_mov_no            IN         VARCHAR2,   -- 依頼/移動No
    iv_deliver_from          IN         VARCHAR2,   -- 出庫元
    iv_deliver_type          IN         VARCHAR2,   -- 出庫形態
    iv_object_date_from      IN         VARCHAR2,   -- 対象期間From
    iv_object_date_to        IN         VARCHAR2,   -- 対象期間To
    iv_shipped_date          IN         VARCHAR2,   -- 出庫日指定
    iv_arrival_date          IN         VARCHAR2,   -- 着日指定
    iv_instruction_post_code IN         VARCHAR2    -- 指示部署指定
  );
END XXWSH920003C;
/
