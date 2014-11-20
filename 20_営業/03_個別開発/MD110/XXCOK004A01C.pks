CREATE OR REPLACE PACKAGE XXCOK004A01C
AS
 /*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK004A01C(spec)
 * Description      : 顧客移行日に顧客マスタの釣銭金額に基づき仕訳情報を作成します。
 * MD.050           : VD釣銭の振替仕訳作成 (MD050_COK_004_A01)
 * Version          : 1.1
 *
 * Program List
 * ----------------------- ----------------------------------------------------------
 *  Name                    Description
 * ----------------------- ----------------------------------------------------------
 *  init                    初期処理                        (A-1)
 *  get_cust_shift_info     顧客移行情報取得                (A-2)
 *  lock_cust_shift_info    顧客移行情報ロック取得          (A-3)
 *  distinct_target_cust_f  振替仕訳作成対象顧客判別        (A-4)
 *  chk_acctg_target        会計期間チェック                (A-5)
 *  get_gl_data_info        GL連携データ付加情報の取得      (A-6)
 *  ins_gl_oif              一般会計OIF登録                 (A-7)
 *  upd_cust_shift_info     顧客移行情報更新                (A-8)
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/09    1.0   K.Motohashi      新規作成
 *  2009/02/02    1.1   K.Suenaga        [障害COK_002]夜バッチ対応(パラメータ追加)
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf   OUT VARCHAR2  -- エラーメッセージ
  , retcode  OUT VARCHAR2  -- エラーコード
  , iv_process_flag IN VARCHAR2 -- 入力項目の起動区分パラメータ
  );
END XXCOK004A01C;
/