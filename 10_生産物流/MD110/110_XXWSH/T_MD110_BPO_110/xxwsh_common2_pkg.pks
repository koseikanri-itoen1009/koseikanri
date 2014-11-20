CREATE OR REPLACE PACKAGE xxwsh_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common2_pkg(SPEC)
 * Description            : 共通関数(OAF用)(SPEC)
 * MD.070(CMD.050)        : なし
 * Version                : 1.4
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  copy_order_data         F    NUM  受注情報コピー処理
 *  upd_order_req_status    P         受注ヘッダステータス更新処理を追加
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/04/08   1.0   H.Itou           新規作成
 *  2008/12/06   1.1   T.Miyata         コピー作成時、出荷実績インタフェース済フラグをN(固定)とする。
 *  2008/12/16   1.2   D.Nihei          追加対象：実績計上済区分を追加。
 *  2008/12/19   1.3   M.Hokkanji       移動ロット詳細複写時に訂正前実績数量を追加
 *  2009/02/09   1.4   M.Hokkanji       受注ヘッダステータス更新処理を追加
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル型
  -- ===============================
--
  -- ===============================
  -- プロシージャおよびファンクション
  -- ===============================
--
   -- 受注情報コピー処理
  FUNCTION copy_order_data(
    it_header_id     IN  xxwsh_order_lines_all.order_header_id%TYPE)   -- 受注ヘッダアドオンID
  RETURN NUMBER; -- 受注ヘッダアドオンID
-- Ver1.4 M.Hokkanji Start
  -- 受注ヘッダステータス更新処理
  PROCEDURE upd_order_req_status(
    in_order_header_id  IN  NUMBER   -- ヘッダID
   ,iv_req_status       IN  VARCHAR2 -- 更新するステータス
   ,ov_ret_code         OUT VARCHAR2 -- リターンコード
   ,ov_errmsg           OUT VARCHAR2 -- エラーメッセージ
  );
-- Ver1.4 M.Hokkanji End
END xxwsh_common2_pkg;
/
