create or replace
PACKAGE      xx03_deptinput_ar_check_pkg
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004-2005. All rights reserved.
 *
 * Package Name           : xx03_deptinput_ar_check_pkg(body)
 * Description            : 部門入力(AR)において入力チェックを行う共通関数
 * MD.070                 : 部門入力(AR)共通関数 OCSJ/BFAFIN/MD070/F702
 * Version                : 11.5.10.1.6
 *
 * Program List
 *  -------------------------- ---- ----- --------------------------------------------------
 *   Name                      Type  Ret   Description
 *  -------------------------- ---- ----- --------------------------------------------------
 *  check_deptinput_ar          P          部門入力(AR)のエラー（仕訳）チェック
 *  set_account_approval_flag   P          重点管理チェック
 *  get_terms_date              P          入金予定日の算出
 *  del_receivable_data         P          請求依頼伝票レコードの削除
 *
 * Change Record
 * ------------ ------------- ------------- -----------------------------------------------
 *  Date         Ver.          Editor        Description
 * ------------ ------------- ------------- -----------------------------------------------
 *  2005-01-20   1.0           T.Noro        新規作成
 *  2006-02-15   11.5.10.1.6   S.Morisawa    ダブルクリック対応,PKGでcommitするPROCEDURE追加
 *
 *****************************************************************************************/
--
--部門入力(AR)のエラーチェック
  PROCEDURE check_deptinput_ar(
    in_receivable_id IN   NUMBER,    -- 1.チェック対象請求書ID
    on_error_cnt     OUT  NUMBER,    -- 2.処理全体でのエラーフラグ
    ov_error_flg     OUT  VARCHAR2,  -- 3.処理全体でのエラーフラグ
    ov_error_flg1    OUT  VARCHAR2,  -- 4.1個目のRETURNデータのエラーフラグ
    ov_error_msg1    OUT  VARCHAR2,  -- 5.1個目のRETURNデータのエラー内容
    ov_error_flg2    OUT  VARCHAR2,  -- 6.2個目のRETURNデータのエラーフラグ
    ov_error_msg2    OUT  VARCHAR2,  -- 7.2個目のRETURNデータのエラー内容
    ov_error_flg3    OUT  VARCHAR2,  -- 8.3個目のRETURNデータのエラーフラグ
    ov_error_msg3    OUT  VARCHAR2,  -- 9.3個目のRETURNデータのエラー内容
    ov_error_flg4    OUT  VARCHAR2,  -- 10.4個目のRETURNデータのエラーフラグ
    ov_error_msg4    OUT  VARCHAR2,  -- 11.4個目のRETURNデータのエラー内容
    ov_error_flg5    OUT  VARCHAR2,  -- 12.5個目のRETURNデータのエラーフラグ
    ov_error_msg5    OUT  VARCHAR2,  -- 13.5個目のRETURNデータのエラー内容
    ov_error_flg6    OUT  VARCHAR2,  -- 14.6個目のRETURNデータのエラーフラグ
    ov_error_msg6    OUT  VARCHAR2,  -- 15.6個目のRETURNデータのエラー内容
    ov_error_flg7    OUT  VARCHAR2,  -- 16.7個目のRETURNデータのエラーフラグ
    ov_error_msg7    OUT  VARCHAR2,  -- 17.7個目のRETURNデータのエラー内容
    ov_error_flg8    OUT  VARCHAR2,  -- 18.8個目のRETURNデータのエラーフラグ
    ov_error_msg8    OUT  VARCHAR2,  -- 19.8個目のRETURNデータのエラー内容
    ov_error_flg9    OUT  VARCHAR2,  -- 20.9個目のRETURNデータのエラーフラグ
    ov_error_msg9    OUT  VARCHAR2,  -- 21.9個目のRETURNデータのエラー内容
    ov_error_flg10   OUT  VARCHAR2,  -- 22.10個目のRETURNデータのエラーフラグ
    ov_error_msg10   OUT  VARCHAR2,  -- 23.10個目のRETURNデータのエラー内容
    ov_error_flg11   OUT  VARCHAR2,  -- 24.11個目のRETURNデータのエラーフラグ
    ov_error_msg11   OUT  VARCHAR2,  -- 25.11個目のRETURNデータのエラー内容
    ov_error_flg12   OUT  VARCHAR2,  -- 26.12個目のRETURNデータのエラーフラグ
    ov_error_msg12   OUT  VARCHAR2,  -- 27.12個目のRETURNデータのエラー内容
    ov_error_flg13   OUT  VARCHAR2,  -- 28.13個目のRETURNデータのエラーフラグ
    ov_error_msg13   OUT  VARCHAR2,  -- 29.13個目のRETURNデータのエラー内容
    ov_error_flg14   OUT  VARCHAR2,  -- 30.14個目のRETURNデータのエラーフラグ
    ov_error_msg14   OUT  VARCHAR2,  -- 31.14個目のRETURNデータのエラー内容
    ov_error_flg15   OUT  VARCHAR2,  -- 32.15個目のRETURNデータのエラーフラグ
    ov_error_msg15   OUT  VARCHAR2,  -- 33.15個目のRETURNデータのエラー内容
    ov_error_flg16   OUT  VARCHAR2,  -- 34.16個目のRETURNデータのエラーフラグ
    ov_error_msg16   OUT  VARCHAR2,  -- 35.16個目のRETURNデータのエラー内容
    ov_error_flg17   OUT  VARCHAR2,  -- 36.17個目のRETURNデータのエラーフラグ
    ov_error_msg17   OUT  VARCHAR2,  -- 37.17個目のRETURNデータのエラー内容
    ov_error_flg18   OUT  VARCHAR2,  -- 38.18個目のRETURNデータのエラーフラグ
    ov_error_msg18   OUT  VARCHAR2,  -- 39.18個目のRETURNデータのエラー内容
    ov_error_flg19   OUT  VARCHAR2,  -- 40.19個目のRETURNデータのエラーフラグ
    ov_error_msg19   OUT  VARCHAR2,  -- 41.19個目のRETURNデータのエラー内容
    ov_error_flg20   OUT  VARCHAR2,  -- 42.20個目のRETURNデータのエラーフラグ
    ov_error_msg20   OUT  VARCHAR2,  -- 43.20個目のRETURNデータのエラー内容
    ov_errbuf        OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg        OUT  VARCHAR2); --   (固定)ユーザー・エラー・メッセージ
--
--重点管理チェック
  PROCEDURE set_account_approval_flag(
    in_receivable_id IN  NUMBER,     -- 1.チェック対象請求書ID
    ov_app_upd       OUT VARCHAR2,   -- 2.重点管理更新内容
    ov_errbuf        OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2);  --   ユーザー・エラー・メッセージ --# 固定 #
--
--入金予定日の算出
  PROCEDURE get_terms_date(
    in_terms_id      IN  NUMBER,     -- 1.支払条件
    id_start_date    IN  DATE,       -- 2.請求書日付
    od_terms_date    OUT DATE,       -- 3.入金予定日
    ov_errbuf        OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2);  --   ユーザー・エラー・メッセージ --# 固定 #
--
--請求依頼伝票レコードの削除
  PROCEDURE del_receivable_data(
    in_receivable_id IN  NUMBER,     -- 1.削除対象請求依頼ID
    ov_errbuf        OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2);  --   ユーザー・エラー・メッセージ --# 固定 #
--
-- ver11.5.10.1.6 Add Start
--部門入力(AR)のエラーチェック(画面用)
  PROCEDURE check_deptinput_ar_input(
    in_receivable_id IN   NUMBER,    -- 1.チェック対象請求書ID
    on_error_cnt     OUT  NUMBER,    -- 2.処理全体でのエラーフラグ
    ov_error_flg     OUT  VARCHAR2,  -- 3.処理全体でのエラーフラグ
    ov_error_flg1    OUT  VARCHAR2,  -- 4.1個目のRETURNデータのエラーフラグ
    ov_error_msg1    OUT  VARCHAR2,  -- 5.1個目のRETURNデータのエラー内容
    ov_error_flg2    OUT  VARCHAR2,  -- 6.2個目のRETURNデータのエラーフラグ
    ov_error_msg2    OUT  VARCHAR2,  -- 7.2個目のRETURNデータのエラー内容
    ov_error_flg3    OUT  VARCHAR2,  -- 8.3個目のRETURNデータのエラーフラグ
    ov_error_msg3    OUT  VARCHAR2,  -- 9.3個目のRETURNデータのエラー内容
    ov_error_flg4    OUT  VARCHAR2,  -- 10.4個目のRETURNデータのエラーフラグ
    ov_error_msg4    OUT  VARCHAR2,  -- 11.4個目のRETURNデータのエラー内容
    ov_error_flg5    OUT  VARCHAR2,  -- 12.5個目のRETURNデータのエラーフラグ
    ov_error_msg5    OUT  VARCHAR2,  -- 13.5個目のRETURNデータのエラー内容
    ov_error_flg6    OUT  VARCHAR2,  -- 14.6個目のRETURNデータのエラーフラグ
    ov_error_msg6    OUT  VARCHAR2,  -- 15.6個目のRETURNデータのエラー内容
    ov_error_flg7    OUT  VARCHAR2,  -- 16.7個目のRETURNデータのエラーフラグ
    ov_error_msg7    OUT  VARCHAR2,  -- 17.7個目のRETURNデータのエラー内容
    ov_error_flg8    OUT  VARCHAR2,  -- 18.8個目のRETURNデータのエラーフラグ
    ov_error_msg8    OUT  VARCHAR2,  -- 19.8個目のRETURNデータのエラー内容
    ov_error_flg9    OUT  VARCHAR2,  -- 20.9個目のRETURNデータのエラーフラグ
    ov_error_msg9    OUT  VARCHAR2,  -- 21.9個目のRETURNデータのエラー内容
    ov_error_flg10   OUT  VARCHAR2,  -- 22.10個目のRETURNデータのエラーフラグ
    ov_error_msg10   OUT  VARCHAR2,  -- 23.10個目のRETURNデータのエラー内容
    ov_error_flg11   OUT  VARCHAR2,  -- 24.11個目のRETURNデータのエラーフラグ
    ov_error_msg11   OUT  VARCHAR2,  -- 25.11個目のRETURNデータのエラー内容
    ov_error_flg12   OUT  VARCHAR2,  -- 26.12個目のRETURNデータのエラーフラグ
    ov_error_msg12   OUT  VARCHAR2,  -- 27.12個目のRETURNデータのエラー内容
    ov_error_flg13   OUT  VARCHAR2,  -- 28.13個目のRETURNデータのエラーフラグ
    ov_error_msg13   OUT  VARCHAR2,  -- 29.13個目のRETURNデータのエラー内容
    ov_error_flg14   OUT  VARCHAR2,  -- 30.14個目のRETURNデータのエラーフラグ
    ov_error_msg14   OUT  VARCHAR2,  -- 31.14個目のRETURNデータのエラー内容
    ov_error_flg15   OUT  VARCHAR2,  -- 32.15個目のRETURNデータのエラーフラグ
    ov_error_msg15   OUT  VARCHAR2,  -- 33.15個目のRETURNデータのエラー内容
    ov_error_flg16   OUT  VARCHAR2,  -- 34.16個目のRETURNデータのエラーフラグ
    ov_error_msg16   OUT  VARCHAR2,  -- 35.16個目のRETURNデータのエラー内容
    ov_error_flg17   OUT  VARCHAR2,  -- 36.17個目のRETURNデータのエラーフラグ
    ov_error_msg17   OUT  VARCHAR2,  -- 37.17個目のRETURNデータのエラー内容
    ov_error_flg18   OUT  VARCHAR2,  -- 38.18個目のRETURNデータのエラーフラグ
    ov_error_msg18   OUT  VARCHAR2,  -- 39.18個目のRETURNデータのエラー内容
    ov_error_flg19   OUT  VARCHAR2,  -- 40.19個目のRETURNデータのエラーフラグ
    ov_error_msg19   OUT  VARCHAR2,  -- 41.19個目のRETURNデータのエラー内容
    ov_error_flg20   OUT  VARCHAR2,  -- 42.20個目のRETURNデータのエラーフラグ
    ov_error_msg20   OUT  VARCHAR2,  -- 43.20個目のRETURNデータのエラー内容
    ov_errbuf        OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg        OUT  VARCHAR2); --   (固定)ユーザー・エラー・メッセージ
-- ver11.5.10.1.6 Add End
--
END xx03_deptinput_ar_check_pkg;
