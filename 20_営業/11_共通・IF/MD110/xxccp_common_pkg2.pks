create or replace PACKAGE apps.xxccp_common_pkg2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_common_pkg2(spec)
 * Description            :
 * MD.070                 : MD070_IPO_CCP_共通関数
 * Version                : 1.4
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_process_date          F    DATE   業務処理日取得関数
 *  get_working_day           F    DATE   営業日日付取得関数
 *  chk_moji                  F    BOOL   禁則文字チェック
 *  blob_to_varchar2          P           BLOBデータ変換
 *  upload_item_check         P           項目チェック
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-10-24    1.0  Naoki.Watanabe   新規作成
 *  2008-11-11    1.1  Yutaka.Kuboshima 禁則文字チェック,BLOBデータ変換,項目チェック関数追加
 *  2009-01-30    1.2  Yutaka.Kuboshima 禁則文字チェックの半角スペース,アンダーバーを
 *                                      禁則文字から除外
 *  2009-03-23    1.3  Shinya.Kayahara  最終行にスラッシュ追加
 *  2009-05-01    1.4  Masayuki.Sano    障害番号T1_0910対応(スキーマ名付加)
 *****************************************************************************************/
--
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
  --営業日日付取得関数
  FUNCTION get_working_day(
              id_date          IN DATE
             ,in_working_day   IN NUMBER
             ,iv_calendar_code IN VARCHAR2 DEFAULT NULL
           )
    RETURN DATE;


  --業務日付取得関数
  FUNCTION get_process_date
    RETURN DATE;


  --禁則文字チェック
  FUNCTION chk_moji(
    iv_check_char  IN VARCHAR2,
    iv_check_scope IN VARCHAR2)
    RETURN BOOLEAN;
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
    iv_item_nullflg   IN          VARCHAR2,       -- 必須フラグ（上記定数を設定）-- 必須
    iv_item_attr      IN          VARCHAR2,       -- 項目属性（上記定数を設定）  -- 必須
    ov_errbuf         OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2);       -- ユーザー・エラー・メッセージ --# 固定 #
  --
END XXCCP_COMMON_PKG2;
/
