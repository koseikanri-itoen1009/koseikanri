CREATE OR REPLACE PACKAGE xxcmn_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxcmn_common3_pkg(SPEC)
 * Description            : 共通関数(SPEC)
 * MD.070(CMD.050)        : T_MD050_BPO_000_共通関数3（補足資料）.xls
 * Version                : 1.0
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  blob_to_varchar2       P         BLOB変換
 *  upload_item_check      P         項目チェック
 *  delete_fileup_proc     P         ファイルアップロードインタフェースデータ削除
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/29   1.0   ohba             新規作成
 *  2008/01/30   1.0   nomura           項目チェック追加
 *  2008/02/01   1.0   nomura           ファイルアップロードインタフェースデータ削除追加
 *
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル型
  -- ===============================
--
  -- 変換後VARCHAR2データを格納する配列
  TYPE g_file_data_tbl IS TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
--
  -- 必須フラグ
  gv_null_ok  CONSTANT VARCHAR2(7)  := 'NULL_OK';    -- 任意項目
  gv_null_ng  CONSTANT VARCHAR2(7)  := 'NULL_NG';    -- 必須項目
  -- 項目属性
  gv_attr_vc2  CONSTANT VARCHAR2(1) := '0';   -- VARCHAR2（属性チェックなし）
  gv_attr_num  CONSTANT VARCHAR2(1) := '1';   -- NUMBER  （数値チェック）
  gv_attr_dat  CONSTANT VARCHAR2(1) := '2';   -- DATE    （日付型チェック）
--
  -- ===============================
  -- プロシージャおよびファンクション
  -- ===============================
--
  -- BLOBデータ変換
  PROCEDURE blob_to_varchar2(
    in_file_id   IN         NUMBER,          -- ファイルＩＤ
    ov_file_data OUT NOCOPY g_file_data_tbl, -- 変換後VARCHAR2データ
    ov_errbuf    OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode   OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg    OUT NOCOPY VARCHAR2);       -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 項目チェック
  PROCEDURE upload_item_check(
    iv_item_name      IN          VARCHAR2,       -- 項目名称（項目の日本語名）  -- 必須
    iv_item_value     IN          VARCHAR2,       -- 項目の値                    -- 任意
    in_item_len       IN          NUMBER,         -- 項目の長さ                  -- 必須
    in_item_decimal   IN          NUMBER,         -- 項目の長さ（小数点以下）    -- 条件付必須
    in_item_nullflg   IN          VARCHAR2,       -- 必須フラグ（上記定数を設定）-- 必須
    iv_item_attr      IN          VARCHAR2,       -- 項目属性（上記定数を設定）  -- 必須
    ov_errbuf         OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2);       -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- ファイルアップロードインタフェースデータ削除
  PROCEDURE delete_fileup_proc(
    iv_file_format IN         VARCHAR2,     --   フォーマットパターン
    id_now_date    IN         DATE,         --   対象日付
    in_purge_days  IN         NUMBER,       --   パージ対象期間
    ov_errbuf      OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
--
END xxcmn_common3_pkg;
/
