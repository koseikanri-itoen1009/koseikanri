create or replace PACKAGE xxpo_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name           : xxpo_common3_pkg(SPEC)
 * Description            : 共通関数(仕入実績作成処理管理Tblアクセス処理)(SPEC)
 * MD.070(CMD.050)        : なし
 * Version                : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  check_result              F     V     仕入実績情報チェック
 *  insert_result             F     V     仕入実績情報登録
 *  delete_result             P     -     仕入実績情報削除
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2011/06/03   1.0   K.Kubo           新規作成
 *****************************************************************************************/
--
  -- 仕入実績情報チェック
  FUNCTION check_result(
    in_po_header_id       IN  NUMBER         -- 発注ヘッダＩＤ
  ) 
  RETURN VARCHAR2;
--
  -- 仕入実績情報登録
  FUNCTION insert_result(
    in_po_header_id      IN  NUMBER         -- 発注ヘッダＩＤ
   ,iv_po_header_number  IN  VARCHAR2       -- 発注番号
   ,in_created_by        IN  NUMBER         -- 作成者
   ,id_creation_date     IN  DATE           -- 作成日
   ,in_last_updated_by   IN  NUMBER         -- 最終更新者
   ,id_last_update_date  IN  DATE           -- 最終更新日
   ,in_last_update_login IN  NUMBER         -- 最終更新ログイン
  ) 
  RETURN VARCHAR2;
--
  -- 仕入実績情報削除
  PROCEDURE delete_result(
    in_po_header_id       IN  NUMBER             -- (IN)発注ヘッダＩＤ
   ,ov_errbuf             OUT NOCOPY VARCHAR2    -- エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT NOCOPY VARCHAR2    -- リターン・コード             --# 固定 #
   ,ov_errmsg             OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
  );
--
END xxpo_common3_pkg;
