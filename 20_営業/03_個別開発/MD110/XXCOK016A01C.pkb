CREATE OR REPLACE PACKAGE BODY XXCOK016A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK016A01C(spec)
 * Description      : 組み戻し・残高取消・保留情報(CSVファイル)の取込処理
 * MD.050           : 残高更新Excelアップロード MD050_COK_016_A01
 * Version          : 1.13
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 組み戻し・残高取消・保留情報(CSVファイル)の取込処理
 *  submain              メイン処理プロシージャ
 *  init_proc            初期処理(A-1)
 *  chk_validate_item    妥当性チェック処理(A-4)
 *  upd_bm_balance_data  残高の更新(A-6)
 *  del_file_upload_data ファイルアップロードデータの削除(A-7)
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   K.Ezaki          新規作成
 *  2009/02/19    1.1   A.Yano           [障害COK_047] 残高取消日の更新不具合対応
 *  2009/05/29    1.2   M.Hiruta         [障害T1_1139] 日付条件を変更し、過去分のデータを処理できるよう変更
 *  2010/01/20    1.3   K.Kiriu          [E_本稼動_01115]残高更新を拠点で処理可、１仕入先の複数処理を可能とできるよう変更
 *  2010/03/19    1.4   S.Moriyama       [E_本稼動_01897]組み戻し時に元伝票番号、連携日時のクリアを行うように変更
 *  2011/02/22    1.5   T.Ishiwata       [E_本稼動_05408]年次切替対応
 *  2011/04/14    1.6   S.Niki           [E_本稼動_07143]前月担当拠点の管理元拠点ユーザーが処理できるよう変更
 *  2012/07/04    1.7   K.Onotsuka       [E_本稼動_08365]処理区分が以下の場合、販手残高テーブルの処理区分に各々の区分値を更新する
 *                                                       「残高取消」⇒'1'「保留」⇒'2'「保留解除」⇒'0'
 *  2012/09/20    1.8   T.Osawa          [E_本稼動_10100]残高更新Excelアップロードの改修について
 *  2018/01/23    1.9   K.Nara           [E_本稼動_14790]事務センター対応（事務センタユーザの顧客指定残高取消）
 *  2019/03/14    1.10  T.Kawaguchi      [E_本稼動_15561]残高消し込みを問合せ担当拠点でできるようにする
 *  2019/04/16    1.11  T.Kawaguchi      [E_本稼動_15603]E_本稼動_15603【営業】VDBM残高の保留について
 *  2019/10/29    1.12  Y.Ohishi         [E_本稼動_15863]問合せ拠点で残高を消込む際に仕入先コードに紐づく顧客の残高をまとめて消込できるようにする
 *  2020/11/24    1.13  Y.Sasaki         [E_本稼動_16730]残高Excelアップロード 事務センターで残高取消がされない
 *****************************************************************************************/
--
  ------------------------------------------------------------
  -- ユーザー定義グローバル定数
  ------------------------------------------------------------
  -- パッケージ定義
  cv_pkg_name       CONSTANT VARCHAR2(12) := 'XXCOK016A01C';                     -- パッケージ名
  -- 初期値
  cv_msg_part       CONSTANT VARCHAR2(3)  := ' : ';                              -- メッセージデリミタ
  cv_msg_cont       CONSTANT VARCHAR2(1)  := '.';                                -- カンマ
  cn_zero           CONSTANT NUMBER       := 0;                                  -- 数値:0
  cn_one            CONSTANT NUMBER       := 1;                                  -- 数値:1
  cv_zero           CONSTANT VARCHAR2(1)  := '0';                                -- 文字:0
  cv_one            CONSTANT VARCHAR2(1)  := '1';                                -- 文字:1
  cv_msg_wq         CONSTANT VARCHAR2(1)  := '"';                                -- ダブルクォーテイション
  cv_msg_c          CONSTANT VARCHAR2(1)  := ',';                                -- コンマ
  cv_csv_sep        CONSTANT VARCHAR2(1)  := ',';                                -- CSVセパレータ
  cv_yes            CONSTANT VARCHAR2(1)  := 'Y';                                -- 文字:Y
  cv_no             CONSTANT VARCHAR2(1)  := 'N';                                -- 文字:N
  cv_act_dept       CONSTANT VARCHAR2(1)  := '1';                                -- 業務管理部
  cv_bel_dept       CONSTANT VARCHAR2(1)  := '2';                                -- 各拠点部門
  cn_vend_len       CONSTANT NUMBER       := 9;                                  -- 仕入先コード桁数
  cn_cust_len       CONSTANT NUMBER       := 9;                                  -- 顧客コード桁数
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--  cn_pay_amt_len    CONSTANT NUMBER       := 7;                                  -- 支払金額桁数
  cn_pay_amt_len    CONSTANT NUMBER       := 10;                                 -- 支払金額桁数(FBデータファイルの桁数に合わす)
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
  cv_proc_type1     CONSTANT VARCHAR2(1)  := '1';                                -- 処理区分：組み戻し
  cv_proc_type2     CONSTANT VARCHAR2(1)  := '2';                                -- 処理区分：残高取消
  cv_proc_type3     CONSTANT VARCHAR2(1)  := '3';                                -- 処理区分：保留
  cv_proc_type4     CONSTANT VARCHAR2(1)  := '4';                                -- 処理区分：保留解除
  cv_pay_type1      CONSTANT VARCHAR2(1)  := '1';                                -- 支払区分：本振（案内書あり）
  cv_pay_type2      CONSTANT VARCHAR2(1)  := '2';                                -- 支払区分：本振（案内書なし）
  cv_pay_type3      CONSTANT VARCHAR2(1)  := '3';                                -- 支払区分：経費支払ＢＭ
  cv_pay_type4      CONSTANT VARCHAR2(1)  := '4';                                -- 支払区分：現金支払
  cv_pay_type5      CONSTANT VARCHAR2(1)  := '5';                                -- 支払区分：なし
  cv_fb_if_type0    CONSTANT VARCHAR2(1)  := '0';                                -- 連携区分：未処理
  cv_fb_if_type1    CONSTANT VARCHAR2(1)  := '1';                                -- 連携区分：処理済
  cv_output         CONSTANT VARCHAR2(6)  := 'OUTPUT';                           -- ヘッダログ出力
  --WHOカラム
  cn_created_by     CONSTANT NUMBER       := fnd_global.user_id;                 -- 作成者のユーザーID
  cn_last_upd_by    CONSTANT NUMBER       := fnd_global.user_id;                 -- 最終更新者のユーザーID
  cn_last_upd_login CONSTANT NUMBER       := fnd_global.login_id;                -- 最終更新者のログインID
  cn_request_id     CONSTANT NUMBER       := fnd_global.conc_request_id;         -- 要求ID
  cn_prg_appl_id    CONSTANT NUMBER       := fnd_global.prog_appl_id;            -- コンカレントアプリケーションID
  cn_program_id     CONSTANT NUMBER       := fnd_global.conc_program_id;         -- コンカレントプログラムID
  -- アプリケーション短縮名
  cv_ap_type_xxccp  CONSTANT VARCHAR2(5)  := 'XXCCP';                            -- 共通
  cv_ap_type_xxcok  CONSTANT VARCHAR2(5)  := 'XXCOK';                            -- 個別開発
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
  cv_ap_type_xxcfo  CONSTANT VARCHAR2(5)  := 'XXCFO';                            -- 会計
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
  -- ステータス・コード
  cv_status_normal  CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  -- 異常:2
  cv_status_check   CONSTANT VARCHAR2(1)  := 9;                                  -- チェックエラー:9
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
  cv_status_lock    CONSTANT VARCHAR2(1)  := '7';                                -- ロックエラー:7
  cv_status_update  CONSTANT VARCHAR2(1)  := '8';                                -- 更新エラー:8
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
  cv_status_insert  CONSTANT VARCHAR2(1)  := '9';                                -- 挿入エラー:9
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD START
  cv_proc_type0_upd CONSTANT VARCHAR2(1)  := '0';                                -- (UPDATE用)処理区分：保留解除
  cv_proc_type1_upd CONSTANT VARCHAR2(1)  := '1';                                -- (UPDATE用)処理区分：消込済
  cv_proc_type2_upd CONSTANT VARCHAR2(1)  := '2';                                -- (UPDATE用)処理区分：保留
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD END
  -- 共通メッセージ定義
  cv_normal_msg     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';                 -- 正常終了メッセージ
  cv_warn_msg       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005';                 -- 警告終了メッセージ
  cv_error_msg      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';                 -- エラー終了メッセージ
  cv_mainmsg_90000  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';                 -- 対象件数出力
  cv_mainmsg_90001  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';                 -- 成功件数出力
  cv_mainmsg_90002  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';                 -- エラー件数出力
  cv_mainmsg_90003  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003';                 -- スキップ件数出力
  -- 個別メッセージ定義
  cv_prmmsg_00016   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00016';                 -- ファイルIDパラメータ
  cv_prmmsg_00017   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00017';                 -- ファイルパターンパラメータ
  cv_errmsg_00028   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';                 -- 業務処理日付取得エラー
  cv_errmsg_00003   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003';                 -- プロファイル取得エラー
  cv_errmsg_00030   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00030';                 -- 所属部門取得エラー
  cv_errmsg_00061   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00061';                 -- ファイルアップロードロックエラー
  cv_errmsg_00041   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00041';                 -- BLOBデータ変換エラー
  cv_errmsg_00039   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00039';                 -- ファイル取得エラー
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--  cv_errmsg_00053   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00053';                 -- 残高更新ロックエラー
--  cv_errmsg_00054   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00054';                 -- 残高更新エラー
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
  cv_errmsg_00062   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00062';                 -- ファイルアップロードIF削除エラー
  cv_errmsg_10217   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10217';                 -- 残高更新アップロード情報取得エラー
  cv_errmsg_10218   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10218';                 -- 業務管理部処理区分チェックエラー
  cv_errmsg_10219   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10219';                 -- 拠点処理区分チェックエラー
  cv_errmsg_10220   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10220';                 -- 組み戻し必須チェックエラー
  cv_errmsg_10221   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10221';                 -- 残高取消必須チェックエラー
  cv_errmsg_10222   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10222';                 -- 業務管理部保留必須チェックエラー
  cv_errmsg_10223   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10223';                 -- 拠点保留必須チェックエラー
  cv_errmsg_10224   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10224';                 -- 仕入先コード半角英数字チェックエラー
  cv_errmsg_10225   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10225';                 -- 顧客コード半角英数字チェックエラー
  cv_errmsg_10226   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10226';                 -- 仕入先コード桁数チェックエラー
  cv_errmsg_10227   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10227';                 -- 顧客コード桁数チェックエラー
  cv_errmsg_10228   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10228';                 -- 支払日日付チェックエラー
  cv_errmsg_10229   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10229';                 -- 支払金額数値チェックエラー
  cv_errmsg_10230   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10230';                 -- 支払金額桁数チェックエラー
  cv_errmsg_10231   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10231';                 -- 支払金額値チェックエラー
  cv_errmsg_10232   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10232';                 -- 仕入先存在チェックエラー
  cv_errmsg_10233   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10233';                 -- 顧客存在チェックエラー
  cv_errmsg_10234   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10234';                 -- 組み戻し仕入先BM支払区分チェックエラー
  cv_errmsg_10235   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10235';                 -- 残高取消仕入先BM支払区分チェックエラー
  cv_errmsg_10236   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10236';                 -- 保留仕入先BM支払区分チェックエラー
  cv_errmsg_10237   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10237';                 -- 保留顧客BM支払区分チェックエラー
  cv_errmsg_10238   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10238';                 -- 仕入先保留チェックエラー
  cv_errmsg_10239   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10239';                 -- 組み戻し組み合わせチェックエラー
  cv_errmsg_10240   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10240';                 -- 残高取消組み合わせチェックエラー
  cv_errmsg_10241   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10241';                 -- 保留仕入先組み合わせチェックエラー
  cv_errmsg_10242   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10242';                 -- 保留顧客組み合わせチェックエラー
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
  cv_errmsg_10474   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10474';                 -- 残高更新ロックエラー
  cv_errmsg_10475   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10475';                 -- 残高更新エラー
  cv_errmsg_10456   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10476';                 -- 残高取消必須チェックエラー(拠点)
  cv_errmsg_10457   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10477';                 -- 残高取消組み合わせチェックエラー（拠点）
  cv_errmsg_10458   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10478';                 -- 金額未確定チェックエラー（拠点）
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
-- Ver_1.9 E_本稼動_14790 ADD Start
  cv_errmsg_10544   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10544';                 -- 事務センター顧客指定 処理区分チェックエラー
-- Ver_1.9 E_本稼動_14790 ADD End
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD START
  cv_errmsg_10487   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10487';                 -- 残高取消組み合わせチェックエラー2（拠点）
  cv_errmsg_10488   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10488';                 -- 保留顧客組み合わせチェックエラーメッセージ（拠点）
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD END
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
  cv_errmsg_00024   CONSTANT VARCHAR2(16) := 'APP-XXCFO1-00024';                 -- データ挿入エラー
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
-- Ver_1.11 E_本稼動_15603 ADD Start
  cv_errmsg_10568   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10568';                 -- 業務管理部保留必須チェックエラー2
  cv_errmsg_10567   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10567';                 -- 業務管理部保留必須チェックエラー3
-- Ver_1.11 E_本稼動_15603 ADD End
-- Ver_1.12 E_本稼動_15863 ADD Start
  cv_errmsg_10569   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10569';                 -- 拠点処理区分チェックエラー
-- Ver_1.12 E_本稼動_15863 ADD End
  -- メッセージトークン定義
  cv_tkn_file_id    CONSTANT VARCHAR2(7)  := 'FILE_ID';                          -- ファイルIDトークン
  cv_tkn_format     CONSTANT VARCHAR2(6)  := 'FORMAT';                           -- ファイルパターントークン
  cv_tkn_profile    CONSTANT VARCHAR2(7)  := 'PROFILE';                          -- プロファイルトークン
  cv_tkn_user_id    CONSTANT VARCHAR2(7)  := 'USER_ID';                          -- ユーザIDトークン
  cv_tkn_row_num    CONSTANT VARCHAR2(7)  := 'ROW_NUM';                          -- エラー行トークン
  cv_tkn_vend_code  CONSTANT VARCHAR2(11) := 'VENDOR_CODE';                      -- 仕入先コードトークン
  cv_tkn_cust_code  CONSTANT VARCHAR2(13) := 'CUSTOMER_CODE';                    -- 顧客コードトークン
  cv_tkn_pay_date   CONSTANT VARCHAR2(8)  := 'PAY_DATE';                         -- 支払日トークン
  cv_tkn_pay_amt    CONSTANT VARCHAR2(10) := 'PAY_AMOUNT';                       -- 支払金額トークン
  cv_tkn_count      CONSTANT VARCHAR2(5)  := 'COUNT';                            -- 件数出力トークン
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD START
  cv_tkn_pbase_code CONSTANT VARCHAR2(19) := 'PAST_SALE_BASE_CODE';              -- 前月売上拠点トークン
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD END
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
  cv_tkn_table      CONSTANT VARCHAR2(5)  := 'TABLE';                            --テーブル
  cv_tkn_errmsg     CONSTANT VARCHAR2(6)  := 'ERRMSG';                           --エラーメッセージ
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
  -- プロファイル定義
  cv_dept_act_code  CONSTANT VARCHAR2(20) := 'XXCOK1_AFF2_DEPT_ACT';             -- 業務管理部部門コード
  cv_prof_org_id    CONSTANT VARCHAR2(30) := 'ORG_ID';                           -- 組織ID
-- Ver_1.9 E_本稼動_14790 ADD Start
  cv_prof_cent_proc CONSTANT VARCHAR2(50) := 'XXCOK1_BL_UPLOAD_CENTER_CUST';     -- 事務センター顧客指定フォーマットパターン
-- Ver_1.9 E_本稼動_14790 ADD End
  -- 参照表定義
  cv_lk_proc_type   CONSTANT VARCHAR2(27) := 'XXCOK1_BM_BALANCE_PROC_TYPE';      -- 残高アップロード処理区分
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
  cv_bm_balance_rtn_info
                    CONSTANT VARCHAR2(30) := 'XXCOK_BM_BALANCE_RTN_INFO';        -- 自販機販売手数料組み戻し管理テーブル
  cv_backmargin_balance
                    CONSTANT VARCHAR2(30) := 'XXCOK_BACKMARGIN_BALANCE';         -- 販手残高テーブル
  cv_bm_balance_id  CONSTANT VARCHAR2(30) := 'BM_BALANCE_ID';                    -- 販手残高ID
  cv_supplier_code  CONSTANT VARCHAR2(30) := 'SUPPLIER_CODE';                    -- 仕入先コード
  cv_publication_date  
                    CONSTANT VARCHAR2(30) := 'PUBLICATION_DATE';                 -- 案内書発効日
  --
  cv_date_format    CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';                       -- 日付書式
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
  ------------------------------------------------------------
  -- ユーザー定義グローバル変数
  ------------------------------------------------------------
  gd_proc_date      DATE           := NULL;                                      -- 業務処理日付
  gn_target_cnt     NUMBER         := 0;                                         -- 対象件数
  gn_normal_cnt     NUMBER         := 0;                                         -- 正常件数
  gn_error_cnt      NUMBER         := 0;                                         -- エラー件数
  gn_warn_cnt       NUMBER         := 0;                                         -- スキップ件数
  gn_org_id         NUMBER         := NULL;                                      -- 在庫組織ID
  gv_dept_flg       VARCHAR2(1)    := NULL;                                      -- 部門フラグ
  gv_dept_act_code  fnd_profile_option_values.profile_option_value%TYPE := NULL; -- 業務管理部部門コード
  gv_org_code_sales fnd_profile_option_values.profile_option_value%TYPE := NULL; -- 在庫組織コード
  gv_dept_bel_code  per_all_people_f.attribute1%TYPE                    := NULL; -- 所属部門コード
-- Ver_1.9 E_本稼動_14790 ADD Start
  gv_prof_cent_proc fnd_profile_option_values.profile_option_value%TYPE := NULL; -- プロファイル値（事務センダー顧客指定フォーマットパターン）
  gv_f_cend_cust    VARCHAR2(1)    := NULL;                                      -- 顧客指定フラグ
-- Ver_1.9 E_本稼動_14790 ADD End
  -- チェック後データ退避レコード型
  TYPE g_check_data_rtype IS RECORD (
     vendor_code   po_vendors.segment1%TYPE                                      -- 仕入先コード
    ,customer_code hz_cust_accounts.account_number%TYPE                          -- 顧客コード
    ,pay_date      xxcok_backmargin_balance.expect_payment_date%TYPE             -- 支払日
    ,pay_amount    xxcok_backmargin_balance.backmargin%TYPE                      -- 支払金額
    ,proc_type     xxcok_backmargin_balance.resv_flag%TYPE                       -- 処理タイプ
  );
  -- チェック後データ退避テーブル型
  TYPE g_check_data_ttype IS TABLE OF g_check_data_rtype INDEX BY BINARY_INTEGER;
  ------------------------------------------------------------
  -- ユーザー定義例外
  ------------------------------------------------------------
  -- 例外
  global_api_expt        EXCEPTION; -- 共通関数例外
  global_api_others_expt EXCEPTION; -- 共通関数OTHERS例外
  global_lock_expt       EXCEPTION; -- グローバル例外
  -- プラグマ
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : del_file_upload_data
   * Description      : ファイルアップロードデータの削除(A-6)
   ***********************************************************************************/
  PROCEDURE del_file_upload_data(
     ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
    ,ov_retcode OUT VARCHAR2 -- リターン・コード
    ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
    ,in_file_id IN NUMBER    -- ファイルID
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_file_upload_data'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(2000);  -- メッセージ
    lb_retcode BOOLEAN;         -- APIリターン・メッセージ用
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- ファイルアップロード削除ロックカーソル定義
    CURSOR file_delete_cur(
       in_file_id IN NUMBER -- ファイルID
    )
    IS
      SELECT xmf.file_id AS file_id -- ファイルID
      FROM   xxccp_mrp_file_ul_interface xmf -- ファイルアップロードテーブル
      WHERE  xmf.file_id = in_file_id
      FOR UPDATE NOWAIT;
    --===============================
    -- ローカル例外
    --===============================
    delete_err_expt EXCEPTION; -- 削除エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.ファイルアップロード削除ロック処理
    -------------------------------------------------
    -- ロック処理
    OPEN file_delete_cur(
       in_file_id -- ファイルID
    );
    CLOSE file_delete_cur;
    -------------------------------------------------
    -- 2.ファイルアップロード削除処理
    -------------------------------------------------
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmf
      WHERE xmf.file_id = in_file_id;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE delete_err_expt;
    END;
  --
  EXCEPTION
    -- *** ロック例外ハンドラ ****
    WHEN global_lock_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00061
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(in_file_id)
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力区分
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 削除例外ハンドラ ***
    WHEN delete_err_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00062
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(in_file_id)
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力区分
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END del_file_upload_data;
  --
  /**********************************************************************************
   * Procedure Name   : upd_bm_balance_data
   * Description      : 残高の更新(A-5)
   ***********************************************************************************/
  PROCEDURE upd_bm_balance_data(
     ov_errbuf     OUT VARCHAR2           -- エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2           -- リターン・コード
    ,ov_errmsg     OUT VARCHAR2           -- ユーザー・エラー・メッセージ
    ,in_index      IN  NUMBER             -- 行番号
    ,it_check_data IN  g_check_data_ttype -- チェック後データ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_bm_balance_data'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(2000);  -- メッセージ
    lb_retcode BOOLEAN;         -- APIリターン・メッセージ用
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
    ln_cnt     NUMBER;
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 組み戻しロックカーソル定義
    CURSOR bm_rollback_cur(
       iv_vendor_code IN po_vendors.segment1%TYPE                          -- 仕入先コード
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      ,id_pay_date    IN xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払日
      ,id_pay_date    IN xxcok_backmargin_balance.publication_date%TYPE    -- 支払日
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- 販手残高ID
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
            ,xbb.base_code                        AS base_code                            --拠点コード
            ,xbb.supplier_code                    AS supplier_code                        --仕入先コード
            ,xbb.supplier_site_code               AS supplier_site_code                   --仕入先サイトコード
            ,xbb.cust_code                        AS cust_code                            --顧客コード
            ,xbb.closing_date                     AS closing_date                         --締め日
            ,xbb.selling_amt_tax                  AS selling_amt_tax                      --販売金額（税込）
            ,xbb.backmargin                       AS backmargin                           --販売手数料
            ,xbb.backmargin_tax                   AS backmargin_tax                       --販売手数料（消費税額）
            ,xbb.electric_amt                     AS electric_amt                         --電気料
            ,xbb.electric_amt_tax                 AS electric_amt_tax                     --電気料（消費税額）
            ,xbb.tax_code                         AS tax_code                             --税金コード
            ,xbb.expect_payment_date              AS expect_payment_date                  --支払予定日
            ,xbb.expect_payment_amt_tax           AS expect_payment_amt_tax               --支払予定額（税込）
            ,xbb.payment_amt_tax                  AS payment_amt_tax                      --支払額（税込）
            ,xbb.balance_cancel_date              AS balance_cancel_date                  --残高取消日
            ,xbb.resv_flag                        AS resv_flag                            --保留フラグ
            ,xbb.return_flag                      AS return_flag                          --組み戻しフラグ
            ,xbb.publication_date                 AS publication_date                     --案内書発効日
            ,xbb.fb_interface_status              AS fb_interface_status                  --連携ステータス（本振用FB）
            ,xbb.fb_interface_date                AS fb_interface_date                    --連携日（本振用FB）
            ,xbb.edi_interface_status             AS edi_interface_status                 --連携ステータス（EDI支払案内書）
            ,xbb.edi_interface_date               AS edi_interface_date                   --連携日（EDI支払案内書）
            ,xbb.gl_interface_status              AS gl_interface_status                  --連携ステータス（GL）
            ,xbb.gl_interface_date                AS gl_interface_date                    --連携日（GL）
            ,xbb.amt_fix_status                   AS amt_fix_status                       --金額確定ステータス
            ,xbb.org_slip_number                  AS org_slip_number                      --元伝票番号
            ,xbb.proc_type                        AS proc_type                            --処理区分
            ,NULL                                 AS eb_status                            --電子帳簿処理ステータス
            ,cn_created_by                        AS created_by                           --作成者
            ,SYSDATE                              AS creation_date                        --作成日
            ,cn_last_upd_by                       AS last_updated_by                      --最終更新者
            ,SYSDATE                              AS last_update_date                     --最終更新日
            ,cn_last_upd_login                    AS last_update_login                    --最終更新ログイン
            ,cn_request_id                        AS request_id                           --要求ID
            ,cn_prg_appl_id                       AS program_application_id               --コンカレント･プログラム・アプリケーションID
            ,cn_program_id                        AS program_id                           --コンカレント･プログラムID
            ,SYSDATE                              AS program_update_date                  --プログラム更新日
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
      FROM   xxcok_backmargin_balance xbb -- 販手残高テーブル
      WHERE  xbb.supplier_code       = iv_vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date = id_pay_date
      AND    xbb.publication_date = id_pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    xbb.resv_flag           IS NULL
      AND    xbb.fb_interface_status = cv_fb_if_type1
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
    -- 業務管理部残高取消ロックカーソル定義
    CURSOR bm_cancel_cur(
       iv_vendor_code IN po_vendors.segment1%TYPE                          -- 仕入先コード
      ,id_pay_date    IN xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払日
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- 販手残高ID
      FROM   xxcok_backmargin_balance xbb -- 販手残高テーブル
      WHERE  xbb.supplier_code       = iv_vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date = id_pay_date
      AND    xbb.expect_payment_date <= id_pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    xbb.resv_flag           IS NULL
      AND    xbb.fb_interface_status = cv_fb_if_type0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
    -- 業務管理部仕入先保留ロックカーソル定義
    CURSOR bm_act_vend_pending_cur(
       iv_vendor_code IN po_vendors.segment1%TYPE                          -- 仕入先コード
      ,id_pay_date    IN xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払日
      ,iv_recv_type   IN VARCHAR2                                          -- 保留・保留解除
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- 販手残高ID
      FROM   xxcok_backmargin_balance xbb -- 販手残高テーブル
      WHERE  xbb.supplier_code        = iv_vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date  = id_pay_date
      AND    xbb.expect_payment_date <= id_pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    NVL( xbb.resv_flag,'N' ) = iv_recv_type
      AND    xbb.fb_interface_status  = cv_fb_if_type0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
    -- 業務管理部顧客保留ロックカーソル定義
    CURSOR bm_act_cust_pending_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE              -- 顧客コード
      ,id_pay_date      IN xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払日
      ,iv_recv_type     IN VARCHAR2                                          -- 保留・保留解除
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- 販手残高ID
      FROM   xxcok_backmargin_balance xbb -- 販手残高テーブル
      WHERE  xbb.cust_code            = iv_customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date  = id_pay_date
      AND    xbb.expect_payment_date <= id_pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    NVL( xbb.resv_flag,'N' ) = iv_recv_type
      AND    xbb.fb_interface_status  = cv_fb_if_type0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    -- 拠点残高取消ロック、更新カーソル定義
    CURSOR bm_bel_cancel_cur(
       iv_vendor_code IN po_vendors.segment1%TYPE                          -- 仕入先コード
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE            -- 顧客コード
      ,id_pay_date    IN xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払日
    )
    IS
      SELECT xbb.rowid AS row_id -- 販手残高ROWID
      FROM   xxcok_backmargin_balance xbb -- 販手残高テーブル
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD START
            ,xxcmm_cust_accounts      xca -- 顧客追加情報
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD END
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD START
            ,xxcmm_cust_accounts      xca2 -- 顧客追加情報【拠点】
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD END
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD START
            ,po_vendors               pv   -- 仕入先マスタ
            ,po_vendor_sites_all      pva  -- 仕入先サイトマスタ
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD END
      WHERE  xbb.supplier_code       = iv_vendor_code
      AND    xbb.expect_payment_date <= id_pay_date
      AND    xbb.resv_flag           IS NULL
      AND    xbb.fb_interface_status = cv_fb_if_type0
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD START
--      AND    xbb.base_code           = gv_dept_bel_code
      AND    xbb.cust_code           = xca.customer_code
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD START
--      AND    xca.past_sale_base_code = gv_dept_bel_code
      AND    xca2.customer_code        = xca.past_sale_base_code  -- 拠点ＣＤ = 前月売上拠点
-- Ver_1.9 E_本稼動_14790 MOD Start
--      AND  ( xca.past_sale_base_code   = gv_dept_bel_code         -- 所属拠点 = 前月売上拠点
--      OR     xca2.management_base_code = gv_dept_bel_code )       -- 所属拠点 = 前月売上拠点の管理元拠点
      AND  (
               (    xca.past_sale_base_code   = gv_dept_bel_code  -- 所属拠点 = 前月売上拠点
                 OR xca2.management_base_code = gv_dept_bel_code  -- 所属拠点 = 前月売上拠点の管理元拠点
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD START
                 OR pva.attribute5            = gv_dept_bel_code  -- 所属拠点 = 仕入先の問合せ担当拠点
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD END
-- E_本稼動_16730 ADD START
                 OR gv_dept_flg               = cv_act_dept       -- 所属部門 = 業務管理部
-- E_本稼動_16730 ADD END
               )
-- Ver_1.12 E_本稼動_15863 MOD Start
--           OR
           AND
-- Ver_1.12 E_本稼動_15863 MOD End
               ( gv_f_cend_cust = cv_yes )                           -- 顧客指定メニュー
           )
-- Ver_1.9 E_本稼動_14790 MOD End
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD END
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD END
      AND    xbb.cust_code           = iv_customer_code
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD START
      AND    pv.segment1               = xbb.supplier_code
      AND    pv.vendor_id              = pva.vendor_id
      AND    pva.vendor_site_code      = xbb.supplier_site_code
      AND    pva.org_id                = gn_org_id
      AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD END
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
-- Ver_1.12 E_本稼動_15863 ADD Start
    -- 拠点残高取消ロック、更新カーソル定義
    CURSOR bm_bel_cancel_cur2(
       iv_vendor_code IN po_vendors.segment1%TYPE                          -- 仕入先コード
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE            -- 顧客コード
      ,id_pay_date    IN xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払日
    )
    IS
      SELECT xbb.rowid AS row_id -- 販手残高ROWID
      FROM   xxcok_backmargin_balance xbb -- 販手残高テーブル
            ,po_vendors               pv   -- 仕入先マスタ
            ,po_vendor_sites_all      pva  -- 仕入先サイトマスタ
      WHERE  xbb.supplier_code        = iv_vendor_code
      AND    xbb.expect_payment_date <= id_pay_date
      AND    xbb.resv_flag           IS NULL
      AND    xbb.fb_interface_status  = cv_fb_if_type0
      AND    pv.segment1              = xbb.supplier_code
      AND    pv.vendor_id             = pva.vendor_id
      AND    pva.vendor_site_code     = xbb.supplier_site_code
      AND    pva.org_id               = gn_org_id
      AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
-- Ver_1.12 E_本稼動_15863 ADD End
    -- 拠点顧客保留ロックカーソル定義
    CURSOR bm_bel_cust_pending_cur(
       iv_base_code     IN xxcok_backmargin_balance.base_code%TYPE           -- 拠点コード
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE              -- 顧客コード
      ,id_pay_date      IN xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払日
      ,iv_recv_type     IN VARCHAR2                                          -- 保留・保留解除
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- 販手残高ID
      FROM   xxcok_backmargin_balance xbb -- 販手残高テーブル
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD START
            ,xxcmm_cust_accounts      xca -- 顧客追加情報
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD END
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD START
            ,xxcmm_cust_accounts      xca2 -- 顧客追加情報【拠点】
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD END
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCST.Ishiwata UPD START
--      WHERE  xbb.base_code            = iv_base_code
      WHERE  xbb.cust_code            = xca.customer_code
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD START
--      AND    xca.past_sale_base_code = gv_dept_bel_code
      AND    xca2.customer_code        = xca.past_sale_base_code  -- 拠点ＣＤ = 前月売上拠点
      AND  ( xca.past_sale_base_code   = gv_dept_bel_code         -- 所属拠点 = 前月売上拠点
      OR     xca2.management_base_code = gv_dept_bel_code )       -- 所属拠点 = 前月売上拠点の管理元拠点
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD END
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD END
      AND    xbb.cust_code            = iv_customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date  = id_pay_date
      AND    xbb.expect_payment_date <= id_pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    NVL( xbb.resv_flag,'N' ) = iv_recv_type
      AND    xbb.fb_interface_status  = cv_fb_if_type0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    -- =======================
    -- ローカルTABLE型
    -- =======================
    TYPE bm_bel_cancel_tab_type IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    l_bm_bel_cancel_tab  bm_bel_cancel_tab_type;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
    TYPE bm_rollback_tab_type IS TABLE OF bm_rollback_cur%ROWTYPE INDEX BY PLS_INTEGER;
    l_bm_rollback_tab         bm_rollback_tab_type;
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
-- Ver_1.11 E_本稼動_15603 ADD Start
    -- 仕入先、顧客指定保留、保留解除カーソル
    CURSOR bm_sup_cust_pending_cur(
       iv_vendor_code IN po_vendors.segment1%TYPE                          -- 仕入先コード
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE            -- 顧客コード
      ,id_pay_date    IN xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払日
      ,iv_act_dpt_flag IN VARCHAR2                                         -- 業務拠点管理フラグ
      ,iv_resv_flag    IN VARCHAR2                                         -- 保留フラグ
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- 販手残高ID
      FROM   xxcok_backmargin_balance xbb -- 販手残高テーブル
            ,xxcmm_cust_accounts      xca -- 顧客追加情報
            ,xxcmm_cust_accounts      xca2 -- 顧客追加情報【拠点】
            ,po_vendors               pv   -- 仕入先マスタ
            ,po_vendor_sites_all      pva  -- 仕入先サイトマスタ
      WHERE  xbb.supplier_code       = iv_vendor_code
      AND    xbb.expect_payment_date <= id_pay_date
      AND    NVL(xbb.resv_flag,'N')  = iv_resv_flag
      AND    xbb.fb_interface_status = cv_fb_if_type0
      AND    xbb.cust_code           = xca.customer_code
      AND    xca2.customer_code        = xca.past_sale_base_code  -- 拠点ＣＤ = 前月売上拠点
      AND  (
               (    xca.past_sale_base_code   = gv_dept_bel_code  -- 所属拠点 = 前月売上拠点
                 OR xca2.management_base_code = gv_dept_bel_code  -- 所属拠点 = 前月売上拠点の管理元拠点
                 OR pva.attribute5            = gv_dept_bel_code  -- 所属拠点 = 仕入先の問合せ担当拠点
               )
           OR
               ( iv_act_dpt_flag = cv_act_dept )                  -- 業務管理部の場合、拠点に関わらず処理される
           )
      AND    xbb.cust_code           = iv_customer_code
      AND    pv.segment1               = xbb.supplier_code
      AND    pv.vendor_id              = pva.vendor_id
      AND    pva.vendor_site_code      = xbb.supplier_site_code
      AND    pva.org_id                = gn_org_id
      FOR UPDATE NOWAIT;
    TYPE bm_sup_cust_pending_tab_type IS TABLE OF bm_sup_cust_pending_cur%ROWTYPE INDEX BY PLS_INTEGER;
    l_bm_sup_cust_pending_tab  bm_sup_cust_pending_tab_type;
-- Ver_1.11 E_本稼動_15603 ADD End
    --===============================
    -- ローカル例外
    --===============================
    update_err_expt EXCEPTION; -- 更新エラー
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
    insert_err_expt EXCEPTION; -- 挿入エラー
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    --
    -------------------------------------------------
    -- 1.組み戻しロック処理
    -------------------------------------------------
    IF ( it_check_data(in_index).proc_type = cv_proc_type1 ) THEN
      -- ロック処理
      OPEN bm_rollback_cur(
         it_check_data(in_index).vendor_code -- 仕入先コード
        ,it_check_data(in_index).pay_date    -- 支払日
      );
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
      l_bm_rollback_tab.DELETE;
      FETCH bm_rollback_cur BULK COLLECT INTO l_bm_rollback_tab;
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
      CLOSE bm_rollback_cur;
    -------------------------------------------------
    -- 2.業務管理部残高取消ロック処理
    -------------------------------------------------
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--    ELSIF ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
-- Ver_1.9 E_本稼動_14790 ADD Start
          ( gv_f_cend_cust = cv_no ) AND  -- 事務センター仕入先単位
-- Ver_1.9 E_本稼動_14790 ADD End
          ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
      -- ロック処理
      OPEN bm_cancel_cur(
         it_check_data(in_index).vendor_code -- 仕入先コード
        ,it_check_data(in_index).pay_date    -- 支払日
      );
      CLOSE bm_cancel_cur;
    -------------------------------------------------
    -- 3.業務管理部仕入先保留ロック処理
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
          ( it_check_data(in_index).customer_code IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
          ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
      -- ロック処理
      OPEN bm_act_vend_pending_cur(
         it_check_data(in_index).vendor_code -- 仕入先コード
        ,it_check_data(in_index).pay_date    -- 支払日
        ,cv_no                               -- 保留・保留解除
      );
      CLOSE bm_act_vend_pending_cur;
    -------------------------------------------------
    -- 3.業務管理部仕入先保留解除ロック処理
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
          ( it_check_data(in_index).customer_code IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
          ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
      -- ロック処理
      OPEN bm_act_vend_pending_cur(
         it_check_data(in_index).vendor_code -- 仕入先コード
        ,it_check_data(in_index).pay_date    -- 支払日
        ,cv_yes                              -- 保留・保留解除
      );
      CLOSE bm_act_vend_pending_cur;
    -------------------------------------------------
    -- 4.業務管理部顧客保留ロック処理
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
          ( it_check_data(in_index).vendor_code IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
          ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
      -- ロック処理
      OPEN bm_act_cust_pending_cur(
         it_check_data(in_index).customer_code -- 顧客コード
        ,it_check_data(in_index).pay_date      -- 支払日
        ,cv_no                                 -- 保留・保留解除
      );
      CLOSE bm_act_cust_pending_cur;
    -------------------------------------------------
    -- 4.業務管理部顧客保留解除ロック処理
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
          ( it_check_data(in_index).vendor_code IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
          ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
      -- ロック処理
      OPEN bm_act_cust_pending_cur(
         it_check_data(in_index).customer_code -- 顧客コード
        ,it_check_data(in_index).pay_date      -- 支払日
        ,cv_yes                                -- 保留・保留解除
      );
      CLOSE bm_act_cust_pending_cur;
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
-- Ver_1.11 E_本稼動_15603 ADD Start
    -- 業務管理部顧客仕入先保留ロック処理
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
          ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
      -- ロック処理
      OPEN bm_sup_cust_pending_cur(
         it_check_data(in_index).vendor_code   -- 仕入先コード
        ,it_check_data(in_index).customer_code -- 顧客コード
        ,it_check_data(in_index).pay_date      -- 支払日
        ,gv_dept_flg                           -- 業務管理部フラグ
        ,cv_no                                 -- 保留・保留解除
      );
      FETCH bm_sup_cust_pending_cur BULK COLLECT INTO l_bm_sup_cust_pending_tab;
      CLOSE bm_sup_cust_pending_cur;
    -- 業務管理部顧客仕入先保留解除ロック処理
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
          ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
      -- ロック処理
      OPEN bm_sup_cust_pending_cur(
         it_check_data(in_index).vendor_code   -- 仕入先コード
        ,it_check_data(in_index).customer_code -- 顧客コード
        ,it_check_data(in_index).pay_date      -- 支払日
        ,gv_dept_flg                           -- 業務管理部フラグ
        ,cv_yes                                -- 保留・保留解除
      );
      FETCH bm_sup_cust_pending_cur BULK COLLECT INTO l_bm_sup_cust_pending_tab;
      CLOSE bm_sup_cust_pending_cur;
-- Ver_1.11 E_本稼動_15603 ADD End
    -------------------------------------------------
    -- 5.拠点残高取消ロック処理
    -------------------------------------------------
-- Ver_1.9 E_本稼動_14790 MOD Start
--    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
-- Ver_1.12 E_本稼動_15863 MOD Start
--    ELSIF ( ( gv_dept_flg =  cv_bel_dept ) OR ( gv_f_cend_cust = cv_yes ) ) AND
-- E_本稼動_16730 Mod Start
--    ELSIF ( ( gv_dept_flg =  cv_bel_dept ) AND ( gv_f_cend_cust = cv_yes ) ) AND
    ELSIF( gv_f_cend_cust = cv_yes ) AND
-- E_本稼動_16730 Mod End
-- Ver_1.12 E_本稼動_15863 MOD End
      -- 拠点 または 事務センター顧客指定 の場合
-- Ver_1.9 E_本稼動_14790 MOD End
          ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
      OPEN bm_bel_cancel_cur(
         it_check_data(in_index).vendor_code   -- 仕入先コード
        ,it_check_data(in_index).customer_code -- 顧客コード
        ,it_check_data(in_index).pay_date      -- 支払日
      );
      FETCH bm_bel_cancel_cur BULK COLLECT INTO l_bm_bel_cancel_tab;
      CLOSE bm_bel_cancel_cur;
-- Ver_1.12 E_本稼動_15863 ADD Start
    ELSIF ( ( gv_dept_flg =  cv_bel_dept ) AND ( gv_f_cend_cust = cv_no ) ) AND  -- 拠点 かつ 顧客未指定 の場合
          ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
      OPEN bm_bel_cancel_cur2(
         it_check_data(in_index).vendor_code   -- 仕入先コード
        ,it_check_data(in_index).customer_code -- 顧客コード
        ,it_check_data(in_index).pay_date      -- 支払日
      );
      FETCH bm_bel_cancel_cur2 BULK COLLECT INTO l_bm_bel_cancel_tab;
      CLOSE bm_bel_cancel_cur2;
-- Ver_1.12 E_本稼動_15863 ADD End
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    -------------------------------------------------
    -- 6.拠点顧客保留ロック処理
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
          ( it_check_data(in_index).vendor_code   IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
          ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
      -- ロック処理
      OPEN bm_bel_cust_pending_cur(
         gv_dept_bel_code                      -- 所属部門コード
        ,it_check_data(in_index).customer_code -- 顧客コード
        ,it_check_data(in_index).pay_date      -- 支払日
        ,cv_no                                 -- 保留・保留解除
      );
      CLOSE bm_bel_cust_pending_cur;
    -------------------------------------------------
    -- 7.拠点顧客保留解除ロック処理
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
          ( it_check_data(in_index).vendor_code   IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
          ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
      -- ロック処理
      OPEN bm_bel_cust_pending_cur(
         gv_dept_bel_code                      -- 所属部門コード
        ,it_check_data(in_index).customer_code -- 顧客コード
        ,it_check_data(in_index).pay_date      -- 支払日
        ,cv_yes                                -- 保留・保留解除
      );
      CLOSE bm_bel_cust_pending_cur;
-- Ver_1.11 E_本稼動_15603 ADD Start
    -- 拠点顧客仕入先保留ロック処理
    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
          ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
      -- ロック処理
      OPEN bm_sup_cust_pending_cur(
         it_check_data(in_index).vendor_code   -- 仕入先コード
        ,it_check_data(in_index).customer_code -- 顧客コード
        ,it_check_data(in_index).pay_date      -- 支払日
        ,gv_dept_flg                           -- 業務管理部フラグ
        ,cv_no                                 -- 保留・保留解除
      );
      FETCH bm_sup_cust_pending_cur BULK COLLECT INTO l_bm_sup_cust_pending_tab;
      CLOSE bm_sup_cust_pending_cur;
    -- 拠点顧客仕入先保留解除ロック処理
    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
          ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
      -- ロック処理
      OPEN bm_sup_cust_pending_cur(
         it_check_data(in_index).vendor_code   -- 仕入先コード
        ,it_check_data(in_index).customer_code -- 顧客コード
        ,it_check_data(in_index).pay_date      -- 支払日
        ,gv_dept_flg                           -- 業務管理部フラグ
        ,cv_yes                                -- 保留・保留解除
      );
      FETCH bm_sup_cust_pending_cur BULK COLLECT INTO l_bm_sup_cust_pending_tab;
      CLOSE bm_sup_cust_pending_cur;
-- Ver_1.11 E_本稼動_15603 ADD End
    END IF;
    -------------------------------------------------
    -- 8.組み戻し更新処理
    -------------------------------------------------
    BEGIN
      IF ( it_check_data(in_index).proc_type = cv_proc_type1 ) THEN
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
        -- 元伝票番号がNULL以外を対象に、組み戻し管理テーブルに出力
        <<bm_balance_rtn_info_loop>>
        FOR ln_cnt IN 1..l_bm_rollback_tab.COUNT LOOP
          IF ( l_bm_rollback_tab(ln_cnt).org_slip_number IS NOT NULL ) THEN
            BEGIN
              INSERT INTO xxcok_bm_balance_rtn_info (
                  bm_balance_id                                                   --販手残高ID
                , base_code                                                       --拠点コード
                , supplier_code                                                   --仕入先コード
                , supplier_site_code                                              --仕入先サイトコード
                , cust_code                                                       --顧客コード
                , closing_date                                                    --締め日
                , selling_amt_tax                                                 --販売金額（税込）
                , backmargin                                                      --販売手数料
                , backmargin_tax                                                  --販売手数料（消費税額）
                , electric_amt                                                    --電気料
                , electric_amt_tax                                                --電気料（消費税額）
                , tax_code                                                        --税金コード
                , expect_payment_date                                             --支払予定日
                , expect_payment_amt_tax                                          --支払予定額（税込）
                , payment_amt_tax                                                 --支払額（税込）
                , balance_cancel_date                                             --残高取消日
                , resv_flag                                                       --保留フラグ
                , return_flag                                                     --組み戻しフラグ
                , publication_date                                                --案内書発効日
                , fb_interface_status                                             --連携ステータス（本振用FB）
                , fb_interface_date                                               --連携日（本振用FB）
                , edi_interface_status                                            --連携ステータス（EDI支払案内書）
                , edi_interface_date                                              --連携日（EDI支払案内書）
                , gl_interface_status                                             --連携ステータス（GL）
                , gl_interface_date                                               --連携日（GL）
                , amt_fix_status                                                  --金額確定ステータス
                , org_slip_number                                                 --元伝票番号
                , proc_type                                                       --処理区分
                , eb_status                                                       --電子帳簿処理ステータス
                , created_by                                                      --作成者
                , creation_date                                                   --作成日
                , last_updated_by                                                 --最終更新者
                , last_update_date                                                --最終更新日
                , last_update_login                                               --最終更新ログイン
                , request_id                                                      --要求ID
                , program_application_id                                          --コンカレント・プログラム・アプリケーションID
                , program_id                                                      --コンカレント・プログラムID
                , program_update_date                                             --プログラム更新日
              ) VALUES (
                  l_bm_rollback_tab(ln_cnt).bm_balance_id                         --販手残高ID
                , l_bm_rollback_tab(ln_cnt).base_code                             --拠点コード
                , l_bm_rollback_tab(ln_cnt).supplier_code                         --仕入先コード
                , l_bm_rollback_tab(ln_cnt).supplier_site_code                    --仕入先サイトコード
                , l_bm_rollback_tab(ln_cnt).cust_code                             --顧客コード
                , l_bm_rollback_tab(ln_cnt).closing_date                          --締め日
                , l_bm_rollback_tab(ln_cnt).selling_amt_tax                       --販売金額（税込）
                , l_bm_rollback_tab(ln_cnt).backmargin                            --販売手数料
                , l_bm_rollback_tab(ln_cnt).backmargin_tax                        --販売手数料（消費税額
                , l_bm_rollback_tab(ln_cnt).electric_amt                          --電気料
                , l_bm_rollback_tab(ln_cnt).electric_amt_tax                      --電気料（消費税額）
                , l_bm_rollback_tab(ln_cnt).tax_code                              --税金コード
                , l_bm_rollback_tab(ln_cnt).expect_payment_date                   --支払予定日
                , l_bm_rollback_tab(ln_cnt).expect_payment_amt_tax                --支払予定額（税込）
                , l_bm_rollback_tab(ln_cnt).payment_amt_tax                       --支払額（税込）
                , l_bm_rollback_tab(ln_cnt).balance_cancel_date                   --残高取消日
                , l_bm_rollback_tab(ln_cnt).resv_flag                             --保留フラグ
                , l_bm_rollback_tab(ln_cnt).return_flag                           --組み戻しフラグ
                , l_bm_rollback_tab(ln_cnt).publication_date                      --案内書発効日
                , l_bm_rollback_tab(ln_cnt).fb_interface_status                   --連携ステータス（本振
                , l_bm_rollback_tab(ln_cnt).fb_interface_date                     --連携日（本振用FB）
                , l_bm_rollback_tab(ln_cnt).edi_interface_status                  --連携ステータス（EDI
                , l_bm_rollback_tab(ln_cnt).edi_interface_date                    --連携日（EDI支払案内
                , l_bm_rollback_tab(ln_cnt).gl_interface_status                   --連携ステータス（GL）
                , l_bm_rollback_tab(ln_cnt).gl_interface_date                     --連携日（GL）
                , l_bm_rollback_tab(ln_cnt).amt_fix_status                        --金額確定ステータス
                , l_bm_rollback_tab(ln_cnt).org_slip_number                       --元伝票番号
                , l_bm_rollback_tab(ln_cnt).proc_type                             --処理区分
                , l_bm_rollback_tab(ln_cnt).eb_status                             --電子帳簿処理ステータス
                , l_bm_rollback_tab(ln_cnt).created_by                            --作成者
                , l_bm_rollback_tab(ln_cnt).creation_date                         --作成日
                , l_bm_rollback_tab(ln_cnt).last_updated_by                       --最終更新者
                , l_bm_rollback_tab(ln_cnt).last_update_date                      --最終更新日
                , l_bm_rollback_tab(ln_cnt).last_update_login                     --最終更新ログイン
                , l_bm_rollback_tab(ln_cnt).request_id                            --要求ID
                , l_bm_rollback_tab(ln_cnt).program_application_id                --コンカレント・プログ
                , l_bm_rollback_tab(ln_cnt).program_id                            --コンカレント・プログ
                , l_bm_rollback_tab(ln_cnt).program_update_date                   --プログラム更新日
              );
            EXCEPTION
              WHEN OTHERS THEN
                ov_errmsg := SQLERRM || ' ' || 
                             xxcfr_common_pkg.get_col_comment(cv_backmargin_balance, cv_bm_balance_id) ||
                                cv_msg_part || l_bm_rollback_tab(ln_cnt).bm_balance_id || ' ' ||
                             xxcfr_common_pkg.get_col_comment(cv_backmargin_balance, cv_supplier_code) ||
                                cv_msg_part || l_bm_rollback_tab(ln_cnt).supplier_code || ' ' ||
                             xxcfr_common_pkg.get_col_comment(cv_backmargin_balance, cv_publication_date) ||
                                cv_msg_part || TO_CHAR(l_bm_rollback_tab(ln_cnt).publication_date, cv_date_format); 
                RAISE insert_err_expt;
            END;
          END IF;
        END LOOP bm_balance_rtn_info_loop;
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
        -- 更新処理
        UPDATE xxcok_backmargin_balance xbb -- 販手残高テーブル
        SET    xbb.expect_payment_amt_tax = xbb.payment_amt_tax       -- 支払予定額
              ,xbb.payment_amt_tax        = cn_zero                   -- 支払額
              ,xbb.publication_date       = NULL                      -- 案内書発効日
              ,xbb.fb_interface_status    = cv_fb_if_type0            -- 連携ステータス（本振用FB）
              ,xbb.edi_interface_status   = cv_fb_if_type0            -- 連携ステータス（EDI支払案内書）
              ,xbb.gl_interface_status    = cv_fb_if_type0            -- 連携ステータス（GL）
              ,xbb.return_flag            = cv_yes                    -- 組み戻しフラグ
              ,xbb.balance_cancel_date    = NULL                      -- 残高取消日
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- 最終更新者
              ,xbb.last_update_date       = SYSDATE                   -- 最終更新日
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- 最終更新ログインID
              ,xbb.request_id             = cn_request_id             -- リクエストID
              ,xbb.program_application_id = cn_prg_appl_id            -- プログラムアプリID
              ,xbb.program_id             = cn_program_id             -- プログラムID
              ,xbb.program_update_date    = SYSDATE                   -- プログラム更新日
-- 2010/03/19 Ver.1.4 [障害E_本稼動_01897] SCS S.Moriyama ADD START
              ,xbb.fb_interface_date      = NULL                      -- 連携日（本振用FB）
              ,xbb.edi_interface_date     = NULL                      -- 連携日（EDI支払案内書）
              ,xbb.gl_interface_date      = NULL                      -- 連携日（GL）
              ,xbb.org_slip_number        = NULL                      -- 元伝票番号
-- 2010/03/19 Ver.1.4 [障害E_本稼動_01897] SCS S.Moriyama ADD END
        WHERE  xbb.supplier_code       = it_check_data(in_index).vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date = it_check_data(in_index).pay_date
        AND    xbb.publication_date    = it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    xbb.resv_flag           IS NULL
        AND    xbb.fb_interface_status = cv_fb_if_type1;
      -------------------------------------------------
      -- 9.業務管理部残高取消更新処理
      -------------------------------------------------
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--      ELSIF ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
      ELSIF ( gv_dept_flg =  cv_act_dept ) AND
-- Ver_1.9 E_本稼動_14790 ADD Start
            ( gv_f_cend_cust = cv_no ) AND  --事務センターの仕入先指定メニュー
-- Ver_1.9 E_本稼動_14790 ADD End
            ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
        -- 更新処理
        UPDATE xxcok_backmargin_balance xbb -- 販手残高テーブル
        SET    xbb.expect_payment_amt_tax = cn_zero                    -- 支払予定額
              ,xbb.payment_amt_tax        = xbb.expect_payment_amt_tax -- 支払額
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--              ,xbb.publication_date       = gd_proc_date               -- 案内書発効日
              ,xbb.publication_date       = it_check_data(in_index).pay_date -- 案内書発効日
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
              ,xbb.fb_interface_status    = cv_fb_if_type1             -- 連携ステータス（本振用FB）
              ,xbb.fb_interface_date      = gd_proc_date               -- 連携日（本振用FB）
              ,xbb.edi_interface_status   = cv_fb_if_type1             -- 連携ステータス（EDI支払案内書）
              ,xbb.edi_interface_date     = gd_proc_date               -- 連携日（EDI支払案内書）
              ,xbb.gl_interface_status    = cv_fb_if_type1             -- 連携ステータス（GL）
              ,xbb.gl_interface_date      = gd_proc_date               -- 連携日（GL）
              ,xbb.return_flag            = NULL                       -- 組み戻しフラグ
              ,xbb.balance_cancel_date    = gd_proc_date               -- 残高取消日
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD START
              ,xbb.proc_type              = cv_proc_type1_upd          -- 処理区分：'1'(消込済)
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD END
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID    -- 最終更新者
              ,xbb.last_update_date       = SYSDATE                    -- 最終更新日
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID   -- 最終更新ログインID
              ,xbb.request_id             = cn_request_id              -- リクエストID
              ,xbb.program_application_id = cn_prg_appl_id             -- プログラムアプリID
              ,xbb.program_id             = cn_program_id              -- プログラムID
              ,xbb.program_update_date    = SYSDATE                    -- プログラム更新日
        WHERE  xbb.supplier_code       = it_check_data(in_index).vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    xbb.resv_flag           IS NULL
        AND    xbb.fb_interface_status = cv_fb_if_type0;
      -------------------------------------------------
      -- 10.業務管理部仕入先保留更新処理
      -------------------------------------------------
      ELSIF ( gv_dept_flg =  cv_act_dept ) AND
            ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
            ( it_check_data(in_index).customer_code IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
            ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
        -- 更新処理
        UPDATE xxcok_backmargin_balance xbb -- 販手残高テーブル
        SET    xbb.resv_flag              = cv_yes                    -- 保留フラグ
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD START
              ,xbb.proc_type              = cv_proc_type2_upd         -- 処理区分：'2'(保留)
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD END
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- 最終更新者
              ,xbb.last_update_date       = SYSDATE                   -- 最終更新日
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- 最終更新ログインID
              ,xbb.request_id             = cn_request_id             -- リクエストID
              ,xbb.program_application_id = cn_prg_appl_id            -- プログラムアプリID
              ,xbb.program_id             = cn_program_id             -- プログラムID
              ,xbb.program_update_date    = SYSDATE                   -- プログラム更新日
        WHERE  xbb.supplier_code        = it_check_data(in_index).vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_no
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
      ELSIF ( gv_dept_flg =  cv_act_dept ) AND
            ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
            ( it_check_data(in_index).customer_code IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
            ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
        -- 更新処理
        UPDATE xxcok_backmargin_balance xbb -- 販手残高テーブル
        SET    xbb.resv_flag         = NULL                           -- 保留フラグ
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD START
              ,xbb.proc_type         = cv_proc_type0_upd              -- 処理区分：'0'(保留解除)
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD END
              ,xbb.last_updated_by   = APPS.FND_GLOBAL.USER_ID        -- 最終更新者
              ,xbb.last_update_date  = SYSDATE                        -- 最終更新日
              ,xbb.last_update_login = APPS.FND_GLOBAL.LOGIN_ID       -- 最終更新ログインID
              ,xbb.request_id             = cn_request_id             -- リクエストID
              ,xbb.program_application_id = cn_prg_appl_id            -- プログラムアプリID
              ,xbb.program_id             = cn_program_id             -- プログラムID
              ,xbb.program_update_date    = SYSDATE                   -- プログラム更新日
        WHERE  xbb.supplier_code        = it_check_data(in_index).vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_yes
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
      -------------------------------------------------
      -- 11.業務管理部顧客保留更新処理
      -------------------------------------------------
      ELSIF ( gv_dept_flg =  cv_act_dept ) AND
            ( it_check_data(in_index).customer_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
            ( it_check_data(in_index).vendor_code IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
            ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
        -- 更新処理
        UPDATE xxcok_backmargin_balance xbb -- 販手残高テーブル
        SET    xbb.resv_flag              = cv_yes                    -- 保留フラグ
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD START
              ,xbb.proc_type              = cv_proc_type2_upd         -- 処理区分：'2'(保留)
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD END
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- 最終更新者
              ,xbb.last_update_date       = SYSDATE                   -- 最終更新日
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- 最終更新ログインID
              ,xbb.request_id             = cn_request_id             -- リクエストID
              ,xbb.program_application_id = cn_prg_appl_id            -- プログラムアプリID
              ,xbb.program_id             = cn_program_id             -- プログラムID
              ,xbb.program_update_date    = SYSDATE                   -- プログラム更新日
        WHERE  xbb.cust_code            = it_check_data(in_index).customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_no
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
      ELSIF ( gv_dept_flg =  cv_act_dept ) AND
            ( it_check_data(in_index).customer_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
            ( it_check_data(in_index).vendor_code IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
            ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
        -- 更新処理
        UPDATE xxcok_backmargin_balance xbb -- 販手残高テーブル
        SET    xbb.resv_flag              = NULL                      -- 保留フラグ
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD START
              ,xbb.proc_type              = cv_proc_type0_upd         -- 処理区分：'0'(保留解除)
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD END
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- 最終更新者
              ,xbb.last_update_date       = SYSDATE                   -- 最終更新日
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- 最終更新ログインID
              ,xbb.request_id             = cn_request_id             -- リクエストID
              ,xbb.program_application_id = cn_prg_appl_id            -- プログラムアプリID
              ,xbb.program_id             = cn_program_id             -- プログラムID
              ,xbb.program_update_date    = SYSDATE                   -- プログラム更新日
        WHERE  xbb.cust_code            = it_check_data(in_index).customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_yes
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
        -------------------------------------------------
        -- 12.拠点顧客残高取消更新処理
        -------------------------------------------------
  -- Ver_1.9 E_本稼動_14790 MOD Start
  --      ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
        -- 拠点 または 事務センタ顧客指定の残高取消 の場合
        ELSIF ( ( gv_dept_flg =  cv_bel_dept ) OR ( gv_f_cend_cust = cv_yes ) ) AND
  -- Ver_1.9 E_本稼動_14790 MOD End
              ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
        -- 更新処理
        FORALL i IN 1 .. l_bm_bel_cancel_tab.COUNT
          UPDATE xxcok_backmargin_balance xbb -- 販手残高テーブル
          SET    xbb.expect_payment_amt_tax = cn_zero                    -- 支払予定額
                ,xbb.payment_amt_tax        = xbb.expect_payment_amt_tax -- 支払額
                ,xbb.publication_date       = it_check_data(in_index).pay_date -- 案内書発効日
                ,xbb.fb_interface_status    = cv_fb_if_type1             -- 連携ステータス（本振用FB）
                ,xbb.fb_interface_date      = gd_proc_date               -- 連携日（本振用FB）
                ,xbb.edi_interface_status   = cv_fb_if_type1             -- 連携ステータス（EDI支払案内書）
                ,xbb.edi_interface_date     = gd_proc_date               -- 連携日（EDI支払案内書）
                ,xbb.gl_interface_status    = cv_fb_if_type1             -- 連携ステータス（GL）
                ,xbb.gl_interface_date      = gd_proc_date               -- 連携日（GL）
                ,xbb.return_flag            = NULL                       -- 組み戻しフラグ
                ,xbb.balance_cancel_date    = gd_proc_date               -- 残高取消日
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD START
                ,xbb.proc_type              = cv_proc_type1_upd          -- 処理区分：'1'(消込済)
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD END
                ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID    -- 最終更新者
                ,xbb.last_update_date       = SYSDATE                    -- 最終更新日
                ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID   -- 最終更新ログインID
                ,xbb.request_id             = cn_request_id              -- リクエストID
                ,xbb.program_application_id = cn_prg_appl_id             -- プログラムアプリID
                ,xbb.program_id             = cn_program_id              -- プログラムID
                ,xbb.program_update_date    = SYSDATE                    -- プログラム更新日
          WHERE  xbb.rowid       = l_bm_bel_cancel_tab(i);
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
      -------------------------------------------------
      -- 13.拠点顧客保留更新処理
      -------------------------------------------------
      ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
            ( it_check_data(in_index).customer_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
            ( it_check_data(in_index).vendor_code IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
            ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
        -- 更新処理
        UPDATE xxcok_backmargin_balance xbb -- 販手残高テーブル
        SET    xbb.resv_flag              = cv_yes                    -- 保留フラグ
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD START
              ,xbb.proc_type              = cv_proc_type2_upd         -- 処理区分：'2'(保留)
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD END
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- 最終更新者
              ,xbb.last_update_date       = SYSDATE                   -- 最終更新日
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- 最終更新ログインID
              ,xbb.request_id             = cn_request_id             -- リクエストID
              ,xbb.program_application_id = cn_prg_appl_id            -- プログラムアプリID
              ,xbb.program_id             = cn_program_id             -- プログラムID
              ,xbb.program_update_date    = SYSDATE                   -- プログラム更新日
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD START
--        WHERE  xbb.base_code            = gv_dept_bel_code
        WHERE  EXISTS
                   ( SELECT 'X'
                     FROM   xxcmm_cust_accounts xca
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD START
                           ,xxcmm_cust_accounts xca2 -- 顧客追加情報【拠点】
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD END
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD START
--                     WHERE  xca.past_sale_base_code = gv_dept_bel_code
                     WHERE ( xca.past_sale_base_code   = gv_dept_bel_code         -- 所属拠点 = 前月売上拠点
                       OR    xca2.management_base_code = gv_dept_bel_code )       -- 所属拠点 = 前月売上拠点の管理元拠点
                       AND   xca2.customer_code        = xca.past_sale_base_code  -- 拠点ＣＤ = 前月売上拠点
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD END
                       AND  xca.customer_code        = xbb.cust_code
                   )
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD END
        AND    xbb.cust_code            = it_check_data(in_index).customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_no
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
      ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
            ( it_check_data(in_index).customer_code IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
            ( it_check_data(in_index).vendor_code IS NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD End
            ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
        -- 更新処理
        UPDATE xxcok_backmargin_balance xbb -- 販手残高テーブル
        SET    xbb.resv_flag              = NULL                      -- 保留フラグ
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD START
              ,xbb.proc_type              = cv_proc_type0_upd         -- 処理区分：'0'(保留解除)
-- 2012/07/04 Ver.1.7 [E_本稼動_08365] SCSK K.Onotsuka ADD END
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- 最終更新者
              ,xbb.last_update_date       = SYSDATE                   -- 最終更新日
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- 最終更新ログインID
              ,xbb.request_id             = cn_request_id             -- リクエストID
              ,xbb.program_application_id = cn_prg_appl_id            -- プログラムアプリID
              ,xbb.program_id             = cn_program_id             -- プログラムID
              ,xbb.program_update_date    = SYSDATE                   -- プログラム更新日
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD START
--        WHERE  xbb.base_code            = gv_dept_bel_code
        WHERE  EXISTS
                   ( SELECT 'X'
                     FROM   xxcmm_cust_accounts xca
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD START
                           ,xxcmm_cust_accounts xca2 -- 顧客追加情報【拠点】
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD END
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD START
--                     WHERE  xca.past_sale_base_code = gv_dept_bel_code
                     WHERE ( xca.past_sale_base_code   = gv_dept_bel_code         -- 所属拠点 = 前月売上拠点
                       OR    xca2.management_base_code = gv_dept_bel_code )       -- 所属拠点 = 前月売上拠点の管理元拠点
                       AND   xca2.customer_code        = xca.past_sale_base_code  -- 拠点ＣＤ = 前月売上拠点
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD END
                       AND  xca.customer_code        = xbb.cust_code
                   )
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD END
        AND    xbb.cust_code            = it_check_data(in_index).customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_yes
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
-- Ver_1.11 E_本稼動_15603 ADD Start
      -- 仕入先顧客指定保留保留解除更新処理
      ELSIF ( it_check_data(in_index).customer_code IS NOT NULL ) AND
          ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type IN (cv_proc_type3,cv_proc_type4) ) THEN
        FOR i in 1..l_bm_sup_cust_pending_tab.COUNT LOOP
          UPDATE xxcok_backmargin_balance xbb
          SET    xbb.resv_flag = DECODE(it_check_data(in_index).proc_type, cv_proc_type3, cv_yes, null)
                ,xbb.proc_type = DECODE(it_check_data(in_index).proc_type, cv_proc_type3, cv_proc_type2_upd, cv_proc_type0_upd)
                ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- 最終更新者
                ,xbb.last_update_date       = SYSDATE                   -- 最終更新日
                ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- 最終更新ログインID
                ,xbb.request_id             = cn_request_id             -- リクエストID
                ,xbb.program_application_id = cn_prg_appl_id            -- プログラムアプリID
                ,xbb.program_id             = cn_program_id             -- プログラムID
                ,xbb.program_update_date    = SYSDATE                   -- プログラム更新日
          WHERE  xbb.bm_balance_id = l_bm_sup_cust_pending_tab(i).bm_balance_id;
        END LOOP;
-- Ver_1.11 E_本稼動_15603 ADD End
      END IF;
    EXCEPTION
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
      WHEN insert_err_expt THEN
        RAISE insert_err_expt;
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
      WHEN OTHERS THEN
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
        --エラー内容設定
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
        RAISE update_err_expt;
    END;
  --
  EXCEPTION
    -- *** ロック例外ハンドラ ****
    WHEN global_lock_expt THEN
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--      -- メッセージ取得
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_ap_type_xxcok
--                      ,iv_name         => cv_errmsg_00053
--                    );    
--      -- メッセージ出力
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       in_which      => FND_FILE.OUTPUT -- 出力区分
--                      ,iv_message    => lv_out_msg      -- メッセージ
--                      ,in_new_line   => cn_one          -- 改行
--                    );
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_lock;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    -- *** 更新例外ハンドラ ***
    WHEN update_err_expt THEN
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--      -- メッセージ取得
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_ap_type_xxcok
--                      ,iv_name         => cv_errmsg_00054
--                    );
--      -- メッセージ出力
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       in_which      => FND_FILE.OUTPUT -- 出力区分
--                      ,iv_message    => lv_out_msg      -- メッセージ
--                      ,in_new_line   => cn_one          -- 改行
--                    );
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_update;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
    WHEN insert_err_expt THEN
      ov_retcode := cv_status_insert;
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END upd_bm_balance_data;
  --
  /**********************************************************************************
   * Procedure Name   : chk_validate_item（ループ部）
   * Description      : 妥当性チェック処理(A-3)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
     ov_errbuf   OUT VARCHAR2                                          -- エラー・メッセージ
    ,ov_retcode  OUT VARCHAR2                                          -- リターン・コード
    ,ov_errmsg   OUT VARCHAR2                                          -- ユーザー・エラー・メッセージ
    ,in_index    IN  PLS_INTEGER                                       -- 行番号
    ,iv_segment1 IN  VARCHAR2                                          -- チェック前項目1：仕入先コード
    ,iv_segment2 IN  VARCHAR2                                          -- チェック前項目2：顧客コード
    ,iv_segment3 IN  VARCHAR2                                          -- チェック前項目3：支払日
    ,iv_segment4 IN  VARCHAR2                                          -- チェック前項目4：支払金額
    ,iv_segment5 IN  VARCHAR2                                          -- チェック前項目5：処理タイプ
    ,ov_segment1 OUT po_vendors.segment1%TYPE                          -- チェック後項目1：仕入先コード
    ,ov_segment2 OUT hz_cust_accounts.account_number%TYPE              -- チェック後項目2：顧客コード
    ,ov_segment3 OUT xxcok_backmargin_balance.expect_payment_date%TYPE -- チェック後項目3：支払日
    ,ov_segment4 OUT xxcok_backmargin_balance.backmargin%TYPE          -- チェック後項目4：支払金額
    ,ov_segment5 OUT xxcok_backmargin_balance.resv_flag%TYPE           -- チェック後項目5：処理タイプ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf        VARCHAR2(5000);                                    -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);                                       -- リターン・コード
    lv_errmsg        VARCHAR2(5000);                                    -- ユーザー・エラー・メッセージ
    ln_cnt           NUMBER;                                            -- カウンタ
    lb_retcode       BOOLEAN;                                           -- APIリターン・メッセージ用
    lb_retbool       BOOLEAN;                                           -- APIリターン・チェック用
    lv_out_msg       VARCHAR2(2000);                                    -- メッセージ
    ln_pay_chk_flg   VARCHAR2(1) := '0';                                -- 支払金額チェック用(0:エラー,1:正常)
    lv_recv_type     VARCHAR2(1) := NULL;                               -- 保留・保留解除判断用
    -- チェック項目
    lv_vendor_code   po_vendors.segment1%TYPE;                          -- 仕入先コード
    lv_customer_code hz_cust_accounts.account_number%TYPE;              -- 顧客コード
    ld_pay_date      xxcok_backmargin_balance.expect_payment_date%TYPE; -- 支払日
    ln_pay_amount    xxcok_backmargin_balance.backmargin%TYPE;          -- 支払金額
    lv_proc_type     xxcok_backmargin_balance.resv_flag%TYPE;           -- 処理区分
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    ln_amt_nofix_cnt NUMBER;                                            -- 金額確定
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    -- 抽出項目
    lv_hold_pay_flg  po_vendor_sites_all.hold_all_payments_flag%TYPE;   -- 全支払保留フラグ
    lv_pay_type      po_vendor_sites_all.attribute4%TYPE;               -- BM支払区分
    ln_pay_sum_amt   xxcok_backmargin_balance.backmargin%TYPE;          -- 販手残高支払金額
    --===============================
    -- ローカルカーソル
    --===============================
    -- 業務管理部チェック用カーソル定義
    CURSOR customer_bm_chk_cur1 (
       iv_customer_code IN hz_cust_accounts.account_number%TYPE              -- 顧客コード
      ,id_pay_date      IN xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払日
      ,id_proc_date     IN DATE                                              -- 業務処理日付
      ,iv_recv_type     IN VARCHAR2 -- 保留・保留解除
    ) IS
      SELECT xbb.cust_code              AS customer_code -- 顧客コード
            ,xbb.supplier_code          AS vendor_code   -- 仕入先コード
            ,pva.hold_all_payments_flag AS hold_pay_flg  -- 全支払保留
            ,NVL( pva.attribute4,'X' )  AS pay_type      -- BM支払区分
      FROM   xxcok_backmargin_balance xbb
            ,po_vendors               pvs
            ,po_vendor_sites_all      pva
      WHERE  xbb.cust_code                                        = iv_customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date                              = TRUNC( id_pay_date )
      AND    xbb.expect_payment_date                             <= TRUNC( id_pay_date )
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    NVL( xbb.resv_flag,'N' )                             = iv_recv_type
      AND    xbb.fb_interface_status                              = cv_zero
      AND    pvs.segment1                                         = xbb.supplier_code
      AND    pvs.enabled_flag                                     = cv_yes
      AND    pvs.vendor_id                                        = pva.vendor_id
      AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > id_proc_date
      AND    pva.org_id                                           = gn_org_id
      GROUP BY xbb.cust_code
              ,xbb.supplier_code
              ,pva.hold_all_payments_flag
              ,pva.attribute4;
    -- 業務管理部チェック用レコード定義
    customer_bm_chk_rec1 customer_bm_chk_cur1%ROWTYPE;
    -- 拠点チェック用カーソル定義
    CURSOR customer_bm_chk_cur2 (
       iv_base_code     IN xxcok_backmargin_balance.base_code%TYPE           -- 所属部門コード
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE              -- 顧客コード
      ,id_pay_date      IN xxcok_backmargin_balance.expect_payment_date%TYPE -- 支払日
      ,id_proc_date     DATE                                                 -- 業務処理日付
      ,iv_recv_type     VARCHAR2                                             -- 保留・保留解除
    ) IS
      SELECT xbb.cust_code              AS customer_code -- 顧客コード
            ,xbb.supplier_code          AS vendor_code   -- 仕入先コード
            ,pva.hold_all_payments_flag AS hold_pay_flg  -- 全支払保留
            ,NVL( pva.attribute4,'X' )  AS pay_type      -- BM支払区分
      FROM   xxcok_backmargin_balance xbb
            ,po_vendors               pvs
            ,po_vendor_sites_all      pva
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD START
            ,xxcmm_cust_accounts      xca -- 顧客追加情報
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD END
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD START
            ,xxcmm_cust_accounts      xca2 -- 顧客追加情報【拠点】
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD END
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD START
--      WHERE  xbb.base_code                                        = iv_base_code
--      AND    xbb.cust_code                                        = iv_customer_code
      WHERE  xbb.cust_code                                        = iv_customer_code

-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD START
--      AND    xca.past_sale_base_code = gv_dept_bel_code
      AND    xca2.customer_code        = xca.past_sale_base_code  -- 拠点ＣＤ = 前月売上拠点
      AND  ( xca.past_sale_base_code   = gv_dept_bel_code         -- 所属拠点 = 前月売上拠点
      OR     xca2.management_base_code = gv_dept_bel_code )       -- 所属拠点 = 前月売上拠点の管理元拠点
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD END
      AND    xbb.cust_code                                        = xca.customer_code
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD END
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date                              = TRUNC( id_pay_date )
      AND    xbb.expect_payment_date                             <= TRUNC( id_pay_date )
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    NVL( xbb.resv_flag,'N' )                             = iv_recv_type
      AND    xbb.fb_interface_status                              = cv_zero
      AND    pvs.segment1                                         = xbb.supplier_code
      AND    pvs.enabled_flag                                     = cv_yes
      AND    pvs.vendor_id                                        = pva.vendor_id
      AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > id_proc_date
      AND    pva.org_id                                           = gn_org_id
      GROUP BY xbb.cust_code
              ,xbb.supplier_code
              ,pva.hold_all_payments_flag
              ,pva.attribute4;
    -- 拠点チェック用レコード定義
    customer_bm_chk_rec2 customer_bm_chk_cur2%ROWTYPE;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    -------------------------------------------------
    -- 1.業務管理部処理区分チェック（共通）
    -------------------------------------------------
-- Ver_1.9 E_本稼動_14790 MOD Start
--    IF ( gv_dept_flg =  cv_act_dept ) THEN
    IF ( gv_dept_flg =  cv_act_dept ) AND
       ( gv_f_cend_cust = cv_no ) THEN  --顧客指定でない
-- Ver_1.9 E_本稼動_14790 MOD End
      -- 業務管理部処理区分チェック
      IF ( iv_segment5 = cv_proc_type1 ) OR
         ( iv_segment5 = cv_proc_type2 ) OR
         ( iv_segment5 = cv_proc_type3 ) OR
         ( iv_segment5 = cv_proc_type4 ) THEN
        -- 処理区分を退避
        lv_proc_type := iv_segment5;
      ELSE
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10218
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
    END IF;
-- Ver_1.9 E_本稼動_14790 ADD Start
    IF ( gv_dept_flg =  cv_act_dept ) AND
       ( gv_f_cend_cust = cv_yes ) THEN  --顧客指定の場合
      -- 事務センター顧客指定時の処理区分チェック
      IF ( iv_segment5 = cv_proc_type2 ) THEN
        -- 処理区分を退避
        lv_proc_type := iv_segment5;
      ELSE
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10544
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
    END IF;
-- Ver_1.9 E_本稼動_14790 ADD End
    -------------------------------------------------
    -- 2.拠点処理区分チェック（共通）
    -------------------------------------------------
    IF ( gv_dept_flg =  cv_bel_dept ) THEN
      -- 拠点処理区分チェック
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--      IF ( iv_segment5 = cv_proc_type3 ) OR
      IF ( iv_segment5 = cv_proc_type2 ) OR
         ( iv_segment5 = cv_proc_type3 ) OR
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
         ( iv_segment5 = cv_proc_type4 ) THEN
        -- 処理区分を退避
        lv_proc_type := iv_segment5;
      ELSE
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10219
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
    END IF;
-- Ver_1.12 E_本稼動_15863 ADD Start
    IF ( gv_dept_flg =  cv_bel_dept ) AND
       ( gv_f_cend_cust = cv_no ) THEN  --事務センタ顧客未指定の場合
      -- 事務センター顧客未指定時の処理区分チェック
      IF ( iv_segment5 = cv_proc_type2 ) THEN
        -- 処理区分を退避
        lv_proc_type := iv_segment5;
      ELSE
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10569
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
    END IF;
-- Ver_1.12 E_本稼動_15863 MOD End
    -------------------------------------------------
    -- 3.仕入先コード半角英数字チェック（共通）
    -------------------------------------------------
    IF ( iv_segment1 IS NOT NULL ) THEN
      -- 半角英数字チェック
      lb_retbool := xxccp_common_pkg.chk_alphabet_number_only( iv_segment1 );
      -- 仕入先コード半角英数字チェック
      IF ( lb_retbool = FALSE ) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10224
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 4.仕入先コード桁数チェック（共通）
    -------------------------------------------------
    IF ( iv_segment1 IS NOT NULL ) AND
       ( lb_retbool = TRUE ) THEN
      -- 桁数カウント
      ln_cnt := LENGTHB( iv_segment1 );
      -- 仕入先コード桁数チェック
      IF ( ln_cnt <> cn_vend_len ) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10226
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 5.顧客コード半角英数字チェック（共通）
    -------------------------------------------------
    IF ( iv_segment2 IS NOT NULL ) THEN
      -- 半角英数字チェック
      lb_retbool := xxccp_common_pkg.chk_alphabet_number_only( iv_segment2 );
      -- 顧客コード半角英数字チェック
      IF ( lb_retbool = FALSE ) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10225
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 6.顧客コード桁数チェック（共通）
    -------------------------------------------------
    IF ( iv_segment2 IS NOT NULL ) AND
       ( lb_retbool = TRUE ) THEN
      -- 桁数カウント
      ln_cnt := LENGTHB( iv_segment2 );
      -- 顧客コード桁数チェック
      IF ( ln_cnt <> cn_cust_len ) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10227
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 7.支払日書式チェック（共通）
    -------------------------------------------------
    IF ( iv_segment3 IS NOT NULL ) THEN
      -- 日付変換
      BEGIN
        ld_pay_date := fnd_date.canonical_to_date( iv_segment3 );
      EXCEPTION
        WHEN OTHERS THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10228
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
      END;
    END IF;
    -------------------------------------------------
    -- 8.支払金額半角数字チェック（共通）
    -------------------------------------------------
    IF ( iv_segment4 IS NOT NULL ) THEN
      -- 半角数字チェック
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--      lb_retbool := xxccp_common_pkg.chk_number( iv_segment4 );
      BEGIN
        ln_pay_amount := TO_NUMBER( iv_segment4 );
        lb_retbool    := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          lb_retbool := FALSE;
      END;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
      -- 支払金額半角数字チェック
      IF ( lb_retbool = TRUE ) THEN
        -- 支払金額チェック正常
        ln_pay_chk_flg := cv_one;
      ELSE
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10229
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 9.支払金額桁数チェック（共通）
    -------------------------------------------------
    IF ( iv_segment4 IS NOT NULL ) AND
       ( ln_pay_chk_flg = cv_one ) THEN
      -- 桁数カウント
      ln_cnt := LENGTHB( TO_NUMBER( iv_segment4 ) );
      -- 支払金額桁数チェック
      IF ( ln_cnt > cn_pay_amt_len ) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10230
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
        -- 支払金額チェックエラー
        ln_pay_chk_flg := cv_zero;
      END IF;
    END IF;
    -------------------------------------------------
    -- 10.部門フラグ・処理区分分岐
    -------------------------------------------------
    -- 業務管理部かつ組み戻しの場合
    IF ( gv_dept_flg = cv_act_dept ) AND
       ( lv_proc_type = cv_proc_type1 ) THEN
      -------------------------------------------------
      -- 1.必須チェック（組み戻し）
      -------------------------------------------------
      IF ( iv_segment1 IS NULL ) OR
         ( iv_segment3 IS NULL ) OR
         ( iv_segment4 IS NULL ) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10220
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
      -------------------------------------------------
      -- 2.支払金額値チェック（組み戻し）
      -------------------------------------------------
      IF ( iv_segment4 IS NOT NULL ) AND
         ( ln_pay_chk_flg = cv_one ) THEN
        -- 数値変換
        ln_pay_amount := TO_NUMBER( iv_segment4 );
        -- 支払金額値チェック
        IF ( ln_pay_amount = cn_zero ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10231
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
          -- 支払金額チェックエラー
          ln_pay_chk_flg := cv_zero;
        END IF;
      END IF;
      -------------------------------------------------
      -- 3.仕入先存在チェック（組み戻し）
      -------------------------------------------------
      IF ( iv_segment1 IS NOT NULL ) THEN
        -- 仕入先確認
        BEGIN
          SELECT pvs.segment1               AS vendor_code  -- 仕入先コード
                ,pva.hold_all_payments_flag AS hold_pay_flg -- 全支払保留フラグ
                ,NVL( pva.attribute4,'X' )  AS pay_type     -- BM支払区分
          INTO   lv_vendor_code  -- 仕入先コード
                ,lv_hold_pay_flg -- 全支払保留フラグ
                ,lv_pay_type     -- BM支払区分
          FROM   po_vendors          pvs
                ,po_vendor_sites_all pva
          WHERE  pvs.segment1                                         = iv_segment1
          AND    pvs.enabled_flag                                     = cv_yes
          AND    pvs.vendor_id                                        = pva.vendor_id
          AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
          AND    pva.org_id                                           = gn_org_id;
        EXCEPTION
          -- 仕入先存在チェック
          WHEN NO_DATA_FOUND THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10232
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 4.BM支払区分有効チェック（組み戻し）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- BM支払区分有効チェック
        IF ( lv_pay_type <> cv_pay_type1 ) AND
           ( lv_pay_type <> cv_pay_type2 ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10234
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 5.支払保留有効チェック（組み戻し）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- 支払保留有効チェック
        IF ( lv_hold_pay_flg = cv_yes ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10238
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 6.販手残高存在チェック（組み戻し）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- 販手残高確認
        BEGIN
          SELECT xbb.supplier_code          AS supplier_code -- 仕入先コード
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--                ,xbb.expect_payment_date    AS payment_date  -- 支払予定日
                ,xbb.publication_date       AS publication_date  -- 案内書発効日
                ,SUM( xbb.payment_amt_tax ) AS payment_amt   -- 支払額
          INTO   lv_vendor_code -- 仕入先コード
--                ,ld_pay_date    -- 支払予定日
                ,ld_pay_date    -- 案内書発効日
                ,ln_pay_sum_amt -- 支払予定額
          FROM   xxcok_backmargin_balance xbb
          WHERE  xbb.supplier_code       = lv_vendor_code
--          AND    xbb.expect_payment_date = TRUNC( ld_pay_date )
          AND    xbb.publication_date    = TRUNC( ld_pay_date )
          AND    xbb.resv_flag           IS NULL
          AND    xbb.fb_interface_status = cv_one
          GROUP BY xbb.supplier_code
--                  ,xbb.expect_payment_date;
                  ,xbb.publication_date;
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        EXCEPTION
          -- 販手残高存在チェック
          WHEN NO_DATA_FOUND THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10239
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => lv_vendor_code
                            ,iv_token_name2  => cv_tkn_pay_date
                            ,iv_token_value2 => ld_pay_date
                            ,iv_token_name3  => cv_tkn_pay_amt
                            ,iv_token_value3 => ln_pay_amount
                            ,iv_token_name4  => cv_tkn_row_num
                            ,iv_token_value4 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 7.販手残高組み合わせチェック（組み戻し）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( ln_pay_sum_amt IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- 販手残高組み合わせチェック
        IF ( ln_pay_amount <> ln_pay_sum_amt ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10239
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_pay_amt
                          ,iv_token_value3 => ln_pay_amount
                          ,iv_token_name4  => cv_tkn_row_num
                          ,iv_token_value4 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
    -- 業務管理部かつ残高取消の場合
-- Ver_1.12 E_本稼動_15863 MOD Start
--    ELSIF ( gv_dept_flg = cv_act_dept ) AND
    ELSIF ( ( gv_dept_flg = cv_act_dept ) OR ( gv_dept_flg = cv_bel_dept ) ) AND  -- 業務管理部または各拠点部門
-- Ver_1.12 E_本稼動_15863 MOD End
-- Ver_1.9 E_本稼動_14790 ADD Start
          ( gv_f_cend_cust = cv_no  ) AND  --現行のメニューより起動（顧客指定でない）
-- Ver_1.9 E_本稼動_14790 ADD End
          ( lv_proc_type = cv_proc_type2 ) THEN
      -------------------------------------------------
      -- 1.必須チェック（残高取消）
      -------------------------------------------------
      IF ( iv_segment1 IS NULL ) OR
         ( iv_segment3 IS NULL ) OR
         ( iv_segment4 IS NULL ) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10221
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
      -------------------------------------------------
      -- 2.支払金額値チェック（残高取消）
      -------------------------------------------------
      IF ( iv_segment4 IS NOT NULL ) AND
         ( ln_pay_chk_flg = cv_one ) THEN
        -- 数値変換
        ln_pay_amount := TO_NUMBER( iv_segment4 );
        -- 支払金額値チェック
        IF ( ln_pay_amount = cn_zero ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10231
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
          -- 支払金額チェックエラー
          ln_pay_chk_flg := cv_zero;
        END IF;
      END IF;
      -------------------------------------------------
      -- 3.仕入先存在チェック（残高取消）
      -------------------------------------------------
      IF ( iv_segment1 IS NOT NULL ) THEN
        -- 仕入先確認
        BEGIN
-- Ver_1.12 E_本稼動_15863 MOD Start
        IF ( gv_dept_flg = cv_act_dept ) AND       -- 部門フラグ＝'1'：業務管理部
           ( gv_f_cend_cust = cv_no  ) THEN        -- 顧客指定フラグ＝'N'：顧客指定でない
-- Ver_1.12 E_本稼動_15863 MOD End
            SELECT pvs.segment1               AS vendor_code  -- 仕入先コード
                  ,pva.hold_all_payments_flag AS hold_pay_flg -- 全支払保留フラグ
                  ,NVL( pva.attribute4,'X' )  AS pay_type     -- BM支払区分
            INTO   lv_vendor_code  -- 仕入先コード
                  ,lv_hold_pay_flg -- 全支払保留フラグ
                  ,lv_pay_type     -- BM支払区分
            FROM   po_vendors          pvs
                  ,po_vendor_sites_all pva
            WHERE  pvs.segment1                                         = iv_segment1
            AND    pvs.enabled_flag                                     = cv_yes
            AND    pvs.vendor_id                                        = pva.vendor_id
            AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
            AND    pva.org_id                                           = gn_org_id;
-- Ver_1.12 E_本稼動_15863 ADD Start
        ELSIF ( gv_dept_flg = cv_bel_dept ) AND   -- 部門フラグ＝'2'：各拠点部門
              ( gv_f_cend_cust = cv_no  ) THEN    -- 顧客指定フラグ＝'N'：顧客指定でない
            SELECT pvs.segment1               AS vendor_code  -- 仕入先コード
                  ,pva.hold_all_payments_flag AS hold_pay_flg -- 全支払保留フラグ
                  ,NVL( pva.attribute4,'X' )  AS pay_type     -- BM支払区分
            INTO   lv_vendor_code  -- 仕入先コード
                  ,lv_hold_pay_flg -- 全支払保留フラグ
                  ,lv_pay_type     -- BM支払区分
            FROM   po_vendors          pvs
                  ,po_vendor_sites_all pva
            WHERE  pvs.segment1                                         = iv_segment1
            AND    pvs.enabled_flag                                     = cv_yes
            AND    pvs.vendor_id                                        = pva.vendor_id
            AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
            AND    pva.org_id                                           = gn_org_id
            AND    pva.attribute5                                       = gv_dept_bel_code;  -- 仕入先サイトコード．問合せ担当拠点コード＝初期処理で取得した所属部門コード
        END IF;
-- Ver_1.12 E_本稼動_15863 ADD End
        EXCEPTION
          -- 仕入先存在チェック
          WHEN NO_DATA_FOUND THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10232
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 4.BM支払区分有効チェック（残高取消）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- BM支払区分有効チェック
        IF ( lv_pay_type <> cv_pay_type1 ) AND
           ( lv_pay_type <> cv_pay_type2 ) AND
           ( lv_pay_type <> cv_pay_type3 ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10235
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 5.支払保留有効チェック（残高取消）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- 支払保留有効チェック
        IF ( lv_hold_pay_flg = cv_yes ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10238
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 6.販手残高存在チェック（残高取消）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- 販手残高確認
        BEGIN
-- Ver_1.12 E_本稼動_15863 ADD Start
          IF ( gv_dept_flg = cv_act_dept ) AND       -- 部門フラグ＝'1'：業務管理部
             ( gv_f_cend_cust = cv_no ) THEN         -- 顧客指定フラグ＝'N'：顧客指定でない
-- Ver_1.12 E_本稼動_15863 ADD End
            SELECT xbb.supplier_code                 AS supplier_code -- 仕入先コード
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--                  ,xbb.expect_payment_date           AS payment_date  -- 支払予定日
                  ,SUM( xbb.expect_payment_amt_tax ) AS payment_amt   -- 支払予定額
            INTO   lv_vendor_code -- 仕入先コード
--                  ,ld_pay_date    -- 支払予定日
                  ,ln_pay_sum_amt -- 支払予定額
            FROM   xxcok_backmargin_balance xbb
            WHERE  xbb.supplier_code       = lv_vendor_code
--            AND    xbb.expect_payment_date = TRUNC( ld_pay_date )
            AND    xbb.expect_payment_date <= TRUNC( ld_pay_date )
            AND    xbb.resv_flag           IS NULL
            AND    xbb.fb_interface_status = cv_zero
--            GROUP BY xbb.supplier_code
--                    ,xbb.expect_payment_date;
            GROUP BY xbb.supplier_code;
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
-- Ver_1.12 E_本稼動_15863 ADD Start
          ELSIF  ( gv_dept_flg = cv_bel_dept ) AND   -- 部門フラグ＝'2'：各拠点部門
                 ( gv_f_cend_cust = cv_no ) THEN     -- 顧客指定フラグ＝'N'：顧客指定でない
            SELECT xbb.supplier_code                 AS supplier_code -- 仕入先コード
                  ,SUM( xbb.expect_payment_amt_tax ) AS payment_amt   -- 支払予定額
            INTO   lv_vendor_code -- 仕入先コード
                  ,ln_pay_sum_amt -- 支払予定額
            FROM   xxcok_backmargin_balance xbb
                  ,po_vendors               pv   -- 仕入先マスタ
                  ,po_vendor_sites_all      pva  -- 仕入先サイトマスタ
            WHERE  xbb.supplier_code       = lv_vendor_code
            AND    xbb.expect_payment_date <= TRUNC( ld_pay_date )
            AND    xbb.resv_flag           IS NULL
            AND    xbb.fb_interface_status = cv_zero
            AND    pva.attribute5          = gv_dept_bel_code        -- 仕入先サイトコード．問合せ担当拠点コード＝初期処理で取得した所属部門コード
            AND    pv.segment1             = xbb.supplier_code       -- 販手残高テーブル．仕入先コード＝仕入先マスタ．仕入先コード
            AND    pv.vendor_id            = pva.vendor_id           -- 仕入先マスタ．仕入先ID＝仕入先サイトマスタ．仕入先ID
            AND    pva.vendor_site_code    = xbb.supplier_site_code  -- 販手残高テーブル．仕入先サイトコード＝仕入先サイトマスタ．仕入先サイトコード
            AND    pva.org_id              = gn_org_id               -- 仕入先サイトマスタ.営業単位 = 初期処理で取得した営業単位ID
            AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
                   -- NVL(仕入サイトマスタ.無効日,初期処理で取得した業務処理日付＋1) > 初期処理で取得した業務処理日付
            GROUP BY xbb.supplier_code;
          END IF;
-- Ver_1.12 E_本稼動_15863 ADD End
        EXCEPTION
          -- 販手残高存在チェック
          WHEN NO_DATA_FOUND THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10240
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => lv_vendor_code
                            ,iv_token_name2  => cv_tkn_pay_date
                            ,iv_token_value2 => ld_pay_date
                            ,iv_token_name3  => cv_tkn_pay_amt
                            ,iv_token_value3 => ln_pay_amount
                            ,iv_token_name4  => cv_tkn_row_num
                            ,iv_token_value4 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 7.販手残高組み合わせチェック（残高取消）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( ln_pay_sum_amt IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- 販手残高組み合わせチェック
        IF ( ln_pay_amount <> ln_pay_sum_amt ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10240
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_pay_amt
                          ,iv_token_value3 => ln_pay_amount
                          ,iv_token_name4  => cv_tkn_row_num
                          ,iv_token_value4 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
    -- 業務管理部かつ保留・保留解除の場合
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          (( lv_proc_type = cv_proc_type3 ) OR ( lv_proc_type = cv_proc_type4 )) THEN
      -------------------------------------------------
      -- 1.必須チェック（業務管理部保留）
      -------------------------------------------------
      IF (( iv_segment1 IS NULL ) AND ( iv_segment2 IS NULL )) OR
-- Ver_1.11 E_本稼動_15603 DEL Start
         --(( iv_segment1 IS NOT NULL ) AND ( iv_segment2 IS NOT NULL )) OR
-- Ver_1.11 E_本稼動_15603 DEL End
         ( iv_segment3 IS NULL ) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10222
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
-- Ver_1.11 E_本稼動_15603 ADD Start
      -- 仕入先、顧客コードに設定があり、支払金額に設定がない場合エラー
      IF iv_segment1 IS NOT NULL AND iv_segment2 IS NOT NULL AND iv_segment4 IS NULL THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10568
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
-- Ver_1.11 E_本稼動_15603 ADD End
      -------------------------------------------------
      -- 2.仕入先存在チェック（業務管理部保留）
      -------------------------------------------------
      IF ( iv_segment1 IS NOT NULL ) THEN
        -- 仕入先確認
        BEGIN
          SELECT pvs.segment1               AS vendor_code  -- 仕入先コード
                ,pva.hold_all_payments_flag AS hold_pay_flg -- 全支払保留フラグ
                ,NVL( pva.attribute4,'X' )  AS pay_type     -- BM支払区分
          INTO   lv_vendor_code     -- 仕入先コード
                ,lv_hold_pay_flg -- 全支払保留フラグ
                ,lv_pay_type     -- BM支払区分
          FROM   po_vendors          pvs
                ,po_vendor_sites_all pva
          WHERE  pvs.segment1                                         = iv_segment1
          AND    pvs.enabled_flag                                     = cv_yes
          AND    pvs.vendor_id                                        = pva.vendor_id
          AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
          AND    pva.org_id                                           = gn_org_id;
        EXCEPTION
          -- 仕入先存在チェック
          WHEN NO_DATA_FOUND THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10232
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 3.BM支払区分有効チェック（業務管理部保留）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- BM支払区分有効チェック
        IF ( lv_pay_type <> cv_pay_type1 ) AND
           ( lv_pay_type <> cv_pay_type2 ) AND
           ( lv_pay_type <> cv_pay_type3 ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10236
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 4.支払保留有効チェック（業務管理部保留）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- 支払保留有効チェック
        IF ( lv_hold_pay_flg = cv_yes ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10238
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 5.販手残高存在チェック（業務管理部保留）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
         ( iv_segment2    IS NULL )     AND
-- Ver_1.11 E_本稼動_15603 ADD End
         ( lv_proc_type   =  cv_pay_type3 ) THEN
        -- 販手残高確認
        SELECT COUNT('X')
        INTO   ln_cnt
        FROM   xxcok_backmargin_balance xbb
        WHERE  xbb.supplier_code       = lv_vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date = TRUNC( ld_pay_date )
        AND    xbb.expect_payment_date <= TRUNC( ld_pay_date )
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    xbb.resv_flag           IS NULL
        AND    xbb.fb_interface_status = cv_zero;
        -- 販手残高存在チェック
        IF ( ln_cnt = cn_zero ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10241
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_row_num
                          ,iv_token_value3 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 6.販手残高存在チェック（業務管理部保留解除）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
         ( iv_segment2    IS NULL )     AND
-- Ver_1.11 E_本稼動_15603 ADD End
         ( lv_proc_type   =  cv_pay_type4 ) THEN
        -- 販手残高確認
        SELECT COUNT('X')
        INTO   ln_cnt
        FROM   xxcok_backmargin_balance xbb
        WHERE  xbb.supplier_code       = lv_vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date = TRUNC( ld_pay_date )
        AND    xbb.expect_payment_date <= TRUNC( ld_pay_date )
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    xbb.resv_flag           IS NOT NULL
        AND    xbb.fb_interface_status = cv_zero;
        -- 販手残高存在チェック
        IF ( ln_cnt = cn_zero ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10241
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_row_num
                          ,iv_token_value3 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 7.顧客存在チェック（業務管理部保留）
      -------------------------------------------------
      IF ( iv_segment2 IS NOT NULL ) THEN
        -- 顧客確認
        BEGIN
          SELECT hza.account_number
          INTO   lv_customer_code
          FROM   hz_cust_accounts hza
          WHERE  hza.account_number = iv_segment2;
        EXCEPTION
          -- 顧客存在チェック
          WHEN NO_DATA_FOUND THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10233
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 8.販手残高存在チェック（業務管理部保留）
      -------------------------------------------------
      IF ( lv_customer_code IS NOT NULL ) AND
         ( ld_pay_date      IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 DEL Start
         ( lv_vendor_code   IS NULL )     AND
-- Ver_1.11 E_本稼動_15603 DEL END
         ( lv_proc_type     IS NOT NULL ) THEN
        -- 保留・保留解除判定
        IF ( lv_proc_type   =  cv_pay_type3 ) THEN
          -- 保留
          lv_recv_type := cv_no;
        ELSE
          -- 保留解除
          lv_recv_type := cv_yes;
        END IF;
        -- 販手残高チェックカーソル
        OPEN customer_bm_chk_cur1 (
           lv_customer_code -- 顧客コード
          ,ld_pay_date      -- 支払日
          ,gd_proc_date     -- 業務処理日付
          ,lv_recv_type     -- 保留・保留解除
        );
        LOOP
          FETCH customer_bm_chk_cur1 INTO customer_bm_chk_rec1;
          EXIT WHEN customer_bm_chk_cur1%NOTFOUND;
          -------------------------------------------------
          -- 9.BM支払区分有効チェック（業務管理部保留）
          -------------------------------------------------
          -- BM支払区分有効チェック
          IF ( customer_bm_chk_rec1.pay_type <> cv_pay_type1 ) AND
             ( customer_bm_chk_rec1.pay_type <> cv_pay_type2 ) AND
             ( customer_bm_chk_rec1.pay_type <> cv_pay_type3 ) THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10237
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => customer_bm_chk_rec1.vendor_code
                            ,iv_token_name2  => cv_tkn_row_num
                            ,iv_token_value2 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
          END IF;
          -------------------------------------------------
          -- 10.支払保留有効チェック（業務管理部保留）
          -------------------------------------------------
          -- 支払保留有効チェック
          IF ( customer_bm_chk_rec1.hold_pay_flg = cv_yes ) THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10238
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => customer_bm_chk_rec1.vendor_code
                            ,iv_token_name2  => cv_tkn_row_num
                            ,iv_token_value2 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
          END IF;
        END LOOP;
        -- 販手残高チェック
        IF ( customer_bm_chk_cur1%ROWCOUNT = cn_zero ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10242
                          ,iv_token_name1  => cv_tkn_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_row_num
                          ,iv_token_value3 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
        -- カーソルクローズ
        CLOSE customer_bm_chk_cur1;
      END IF;
-- Ver_1.11 E_本稼動_15603 ADD Start
      IF ( lv_customer_code IS NOT NULL ) AND
         ( lv_vendor_code   IS NOT NULL ) AND
         ( ld_pay_date      IS NOT NULL ) AND
         ( lv_proc_type     IS NOT NULL ) THEN
        -- 保留・保留解除判定
        IF ( lv_proc_type   =  cv_pay_type3 ) THEN
          -- 保留
          lv_recv_type := cv_no;
        ELSE
          -- 保留解除
          lv_recv_type := cv_yes;
        END IF;
                 
        SELECT SUM(xbb.expect_payment_amt_tax) expect_payment_amt_tax
        INTO   ln_pay_sum_amt
        FROM   xxcok_backmargin_balance xbb
        WHERE  xbb.cust_code           =  lv_customer_code
        AND    xbb.supplier_code       =  lv_vendor_code
        AND    xbb.expect_payment_date <= TRUNC( ld_pay_date )
        AND    xbb.fb_interface_status =  cv_fb_if_type0
        AND    NVL(xbb.resv_flag,'N')  =  lv_recv_type;
        
        IF ln_pay_sum_amt IS NULL THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10567
                          ,iv_token_name1  => cv_tkn_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_tkn_vend_code
                          ,iv_token_value2 => lv_vendor_code
                          ,iv_token_name3  => cv_tkn_pay_date
                          ,iv_token_value3 => TO_CHAR(ld_pay_date, cv_date_format)
                          ,iv_token_name4  => cv_tkn_pay_amt
                          ,iv_token_value4 => ln_pay_amount
                          ,iv_token_name5  => cv_tkn_row_num
                          ,iv_token_value5 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        ELSIF ln_pay_sum_amt != ln_pay_amount THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10567
                          ,iv_token_name1  => cv_tkn_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_tkn_vend_code
                          ,iv_token_value2 => lv_vendor_code
                          ,iv_token_name3  => cv_tkn_pay_date
                          ,iv_token_value3 => TO_CHAR(ld_pay_date, cv_date_format)
                          ,iv_token_name4  => cv_tkn_pay_amt
                          ,iv_token_value4 => ln_pay_amount
                          ,iv_token_name5  => cv_tkn_row_num
                          ,iv_token_value5 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
-- Ver_1.11 E_本稼動_15603 ADD End

-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
-- Ver_1.9 E_本稼動_14790 MOD Start
--    -- 拠点かつ残高取消の場合
--    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
-- Ver_1.12 E_本稼動_15863 MOD Start
--    -- 拠点 または 事務センタ顧客指定の残高取消 の場合
--    ELSIF ( ( gv_dept_flg =  cv_bel_dept ) OR ( gv_f_cend_cust = cv_yes ) ) AND
-- E_本稼動_16730 Mod Start
--    -- 拠点 かつ 事務センタ顧客指定の残高取消 の場合
--    ELSIF ( ( gv_dept_flg =  cv_bel_dept ) AND ( gv_f_cend_cust = cv_yes ) ) AND
    -- 顧客指定 かつ 残高取消 の場合
    ELSIF ( gv_f_cend_cust = cv_yes ) AND
-- Ver_1.12 E_本稼動_15863 MOD End
-- E_本稼動_16730 Mod End
-- Ver_1.9 E_本稼動_14790 MOD End
          ( lv_proc_type = cv_proc_type2 ) THEN
      -------------------------------------------------
      -- 1.必須チェック（残高取消）
      -------------------------------------------------
      IF ( iv_segment1 IS NULL ) OR
         ( iv_segment2 IS NULL ) OR
         ( iv_segment3 IS NULL ) OR
         ( iv_segment4 IS NULL ) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10456
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
      -------------------------------------------------
      -- 2.支払金額値チェック（残高取消）
      -------------------------------------------------
      IF ( iv_segment4 IS NOT NULL ) AND
         ( ln_pay_chk_flg = cv_one ) THEN
        -- 数値変換
        ln_pay_amount := TO_NUMBER( iv_segment4 );
        -- 支払金額値チェック
        IF ( ln_pay_amount = cn_zero ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10231
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
          -- 支払金額チェックエラー
          ln_pay_chk_flg := cv_zero;
        END IF;
      END IF;
      -------------------------------------------------
      -- 3.仕入先存在チェック（残高取消）
      -------------------------------------------------
      IF ( iv_segment1 IS NOT NULL ) THEN
        -- 仕入先確認
        BEGIN
          SELECT pvs.segment1               AS vendor_code  -- 仕入先コード
                ,pva.hold_all_payments_flag AS hold_pay_flg -- 全支払保留フラグ
                ,NVL( pva.attribute4,'X' )  AS pay_type     -- BM支払区分
          INTO   lv_vendor_code  -- 仕入先コード
                ,lv_hold_pay_flg -- 全支払保留フラグ
                ,lv_pay_type     -- BM支払区分
          FROM   po_vendors          pvs
                ,po_vendor_sites_all pva
          WHERE  pvs.segment1                                         = iv_segment1
          AND    pvs.enabled_flag                                     = cv_yes
          AND    pvs.vendor_id                                        = pva.vendor_id
          AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
          AND    pva.org_id                                           = gn_org_id;
        EXCEPTION
          -- 仕入先存在チェック
          WHEN NO_DATA_FOUND THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10232
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 4.顧客存在チェック（業務管理部保留）
      -------------------------------------------------
      IF ( iv_segment2 IS NOT NULL ) THEN
        -- 顧客確認
        BEGIN
          SELECT hza.account_number
          INTO   lv_customer_code
          FROM   hz_cust_accounts hza
          WHERE  hza.account_number = iv_segment2;
        EXCEPTION
          -- 顧客存在チェック
          WHEN NO_DATA_FOUND THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10233
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 5.支払保留有効チェック（残高取消）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- 支払保留有効チェック
        IF ( lv_hold_pay_flg = cv_yes ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10238
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 6.販手残高存在チェック（残高取消）
      -------------------------------------------------
      IF ( lv_vendor_code   IS NOT NULL ) AND
         ( lv_customer_code IS NOT NULL ) AND
         ( ld_pay_date      IS NOT NULL ) AND
         ( lv_proc_type     IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- 販手残高確認
        BEGIN
          SELECT xbb.supplier_code                 AS supplier_code -- 仕入先コード
                ,SUM( xbb.expect_payment_amt_tax ) AS payment_amt   -- 支払予定額
                ,SUM( DECODE(  xbb.amt_fix_status
                              ,cv_zero, cn_one
                              ,cn_zero
                      )
                 )                                 AS amt_nofix_cnt -- 金額未確定件数
          INTO   lv_vendor_code   -- 仕入先コード
                ,ln_pay_sum_amt   -- 支払予定額
                ,ln_amt_nofix_cnt -- 金額未確定件数
          FROM   xxcok_backmargin_balance xbb  -- 販手残高
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD START
                ,xxcmm_cust_accounts      xca -- 顧客追加情報
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata ADD END
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD START
                ,xxcmm_cust_accounts      xca2 -- 顧客追加情報【拠点】
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki ADD END
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD START
                ,po_vendors               pv   -- 仕入先マスタ
                ,po_vendor_sites_all      pva  -- 仕入先サイトマスタ
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD END
          WHERE  xbb.supplier_code       = lv_vendor_code
          AND    xbb.expect_payment_date <= TRUNC( ld_pay_date )
          AND    xbb.resv_flag           IS NULL
          AND    xbb.fb_interface_status = cv_zero
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD START
--          AND    xbb.base_code           = gv_dept_bel_code
          AND    xbb.cust_code           = lv_customer_code
          AND    xbb.cust_code           = xca.customer_code
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD START
--          AND    xca.past_sale_base_code = gv_dept_bel_code
          AND    xca2.customer_code        = xca.past_sale_base_code  -- 拠点ＣＤ = 前月売上拠点
-- Ver_1.9 E_本稼動_14790 MOD Start
--          AND  ( xca.past_sale_base_code   = gv_dept_bel_code         -- 所属拠点 = 前月売上拠点
--          OR     xca2.management_base_code = gv_dept_bel_code )       -- 所属拠点 = 前月売上拠点の管理元拠点
          AND  (
                   (    xca.past_sale_base_code   = gv_dept_bel_code  -- 所属拠点 = 前月売上拠点
                     OR xca2.management_base_code = gv_dept_bel_code  -- 所属拠点 = 前月売上拠点の管理元拠点
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD START
                     OR pva.attribute5            = gv_dept_bel_code  -- 所属拠点 = 仕入先の問合せ担当拠点
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD END
-- E_本稼動_16730 Add Start
                     OR gv_dept_flg               = cv_act_dept       -- 所属部門 = 業務管理部
-- E_本稼動_16730 Add End
                   )
-- Ver_1.12 E_本稼動_15863 MOD Start
--               OR
               AND
-- Ver_1.12 E_本稼動_15863 MOD End
                   ( gv_f_cend_cust = cv_yes )                           -- 顧客指定メニュー
               )
-- Ver_1.9 E_本稼動_14790 MOD End
-- 2011/04/14 Ver.1.6 [障害E_本稼動_07143] SCS S.Niki UPD END
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD END
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD START
          AND    pv.segment1               = xbb.supplier_code
          AND    pv.vendor_id              = pva.vendor_id
          AND    pva.vendor_site_code      = xbb.supplier_site_code
          AND    pva.org_id                = gn_org_id
          AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
-- Ver.1.10 [障害E_本稼動_15561] SCSK T.Kawaguchi ADD END
          GROUP BY xbb.supplier_code
                  ,xbb.cust_code;
        EXCEPTION
          -- 販手残高存在チェック
          WHEN NO_DATA_FOUND THEN
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD START
            -- 妥当性チェックエラーメッセージ取得
--            lv_out_msg := xxccp_common_pkg.get_msg(
--                             iv_application  => cv_ap_type_xxcok
--                            ,iv_name         => cv_errmsg_10457
--                            ,iv_token_name1  => cv_tkn_vend_code
--                            ,iv_token_value1 => lv_vendor_code
--                            ,iv_token_name2  => cv_tkn_cust_code
--                            ,iv_token_value2 => lv_customer_code
--                            ,iv_token_name3  => cv_tkn_pay_date
--                            ,iv_token_value3 => ld_pay_date
--                            ,iv_token_name4  => cv_tkn_pay_amt
--                            ,iv_token_value4 => ln_pay_amount
--                            ,iv_token_name5  => cv_tkn_row_num
--                            ,iv_token_value5 => in_index
--                          );
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10487
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => lv_vendor_code
                            ,iv_token_name2  => cv_tkn_pbase_code
                            ,iv_token_value2 => gv_dept_bel_code
                            ,iv_token_name3  => cv_tkn_cust_code
                            ,iv_token_value3 => lv_customer_code
                            ,iv_token_name4  => cv_tkn_pay_date
                            ,iv_token_value4 => ld_pay_date
                            ,iv_token_name5  => cv_tkn_pay_amt
                            ,iv_token_value5 => ln_pay_amount
                            ,iv_token_name6  => cv_tkn_row_num
                            ,iv_token_value6 => in_index
                          );
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD END
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 7.金額未確定チェック（残高取消）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( ln_pay_sum_amt IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        --金額未確定チェック
        IF ( ln_amt_nofix_cnt <> cn_zero ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10458
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_cust_code
                          ,iv_token_value2 => lv_customer_code
                          ,iv_token_name3  => cv_tkn_pay_date
                          ,iv_token_value3 => ld_pay_date
                          ,iv_token_name4  => cv_tkn_pay_amt
                          ,iv_token_value4 => ln_pay_amount
                          ,iv_token_name5  => cv_tkn_row_num
                          ,iv_token_value5 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 8.販手残高組み合わせチェック（残高取消）
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( ln_pay_sum_amt IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- 販手残高組み合わせチェック
        IF ( ln_pay_amount <> ln_pay_sum_amt ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10457
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_cust_code
                          ,iv_token_value2 => lv_customer_code
                          ,iv_token_name3  => cv_tkn_pay_date
                          ,iv_token_value3 => ld_pay_date
                          ,iv_token_name4  => cv_tkn_pay_amt
                          ,iv_token_value4 => ln_pay_amount
                          ,iv_token_name5  => cv_tkn_row_num
                          ,iv_token_value5 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    -- 拠点かつ保留・保留解除の場合
    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
          (( lv_proc_type = cv_proc_type3 ) OR ( lv_proc_type = cv_proc_type4 )) THEN
      -------------------------------------------------
      -- 1.必須チェック（拠点保留）
      -------------------------------------------------
      IF ( iv_segment2 IS NULL ) OR
         ( iv_segment3 IS NULL ) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10223
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
      
-- Ver_1.11 E_本稼動_15603 ADD Start
      -- 仕入先、顧客コード入力時は支払金額が必須
      IF (iv_segment1 IS NOT NULL) AND (iv_segment2 IS NOT NULL) AND (iv_segment4 IS NULL) THEN
        -- 妥当性チェックエラーメッセージ取得
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10568
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- 妥当性チェックエラーメッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => lv_out_msg      -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        -- 妥当性チェックエラー
        ov_retcode := cv_status_check;
      END IF;
-- Ver_1.11 E_本稼動_15603 ADD End
      
      -------------------------------------------------
      -- 2.顧客存在チェック（拠点保留）
      -------------------------------------------------
      IF ( iv_segment2 IS NOT NULL ) THEN
        -- 顧客確認
        BEGIN
          SELECT hza.account_number
          INTO   lv_customer_code
          FROM   hz_cust_accounts hza
          WHERE  hza.account_number = iv_segment2;
        EXCEPTION
          -- 顧客存在チェック
          WHEN NO_DATA_FOUND THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10233
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
-- Ver_1.11 E_本稼動_15603 ADD Start
      -- 仕入先確認
      IF ( iv_segment1 IS NOT NULL ) THEN
        BEGIN
          SELECT pvs.segment1               AS vendor_code  -- 仕入先コード
                ,pva.hold_all_payments_flag AS hold_pay_flg -- 全支払保留フラグ
                ,NVL( pva.attribute4,'X' )  AS pay_type     -- BM支払区分
          INTO   lv_vendor_code     -- 仕入先コード
                ,lv_hold_pay_flg -- 全支払保留フラグ
                ,lv_pay_type     -- BM支払区分
          FROM   po_vendors          pvs
                ,po_vendor_sites_all pva
          WHERE  pvs.segment1                                         = iv_segment1
          AND    pvs.enabled_flag                                     = cv_yes
          AND    pvs.vendor_id                                        = pva.vendor_id
          AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
          AND    pva.org_id                                           = gn_org_id;
        EXCEPTION
          -- 仕入先存在チェック
          WHEN NO_DATA_FOUND THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10232
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
        END;
      END IF;
      -- BM支払区分有効チェック
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- BM支払区分有効チェック
        IF ( lv_pay_type <> cv_pay_type1 ) AND
           ( lv_pay_type <> cv_pay_type2 ) AND
           ( lv_pay_type <> cv_pay_type3 ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10236
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -- 支払保留有効チェック
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- 支払保留有効チェック
        IF ( lv_hold_pay_flg = cv_yes ) THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10238
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
-- Ver_1.11 E_本稼動_15603 ADD End
      -------------------------------------------------
      -- 3.販手残高存在チェック（拠点保留）
      -------------------------------------------------
      IF ( lv_customer_code IS NOT NULL ) AND
         ( ld_pay_date      IS NOT NULL ) AND
-- Ver_1.11 E_本稼動_15603 ADD Start
         ( lv_vendor_code   IS NULL )     AND
-- Ver_1.11 E_本稼動_15603 ADD End
         ( lv_proc_type     IS NOT NULL ) THEN
        -- 保留・保留解除判定
        IF ( lv_proc_type   =  cv_pay_type3 ) THEN
          -- 保留
          lv_recv_type := cv_no;
        ELSE
          -- 保留解除
          lv_recv_type := cv_yes;
        END IF;
        -- 販手残高チェックカーソル
        OPEN customer_bm_chk_cur2 (
           gv_dept_bel_code -- 所属部門コード
          ,lv_customer_code -- 顧客コード
          ,ld_pay_date      -- 支払日
          ,gd_proc_date     -- 業務処理日付
          ,lv_recv_type     -- 保留・保留解除
        );
        LOOP
          FETCH customer_bm_chk_cur2 INTO customer_bm_chk_rec2;
          EXIT WHEN customer_bm_chk_cur2%NOTFOUND;
          
          -------------------------------------------------
          -- 8.BM支払区分有効チェック（業務管理部保留）
          -------------------------------------------------
          -- BM支払区分有効チェック
          IF ( customer_bm_chk_rec2.pay_type <> cv_pay_type1 ) AND
             ( customer_bm_chk_rec2.pay_type <> cv_pay_type2 ) AND
             ( customer_bm_chk_rec2.pay_type <> cv_pay_type3 ) THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10237
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => customer_bm_chk_rec2.vendor_code
                            ,iv_token_name2  => cv_tkn_row_num
                            ,iv_token_value2 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
          END IF;
          -------------------------------------------------
          -- 9.支払保留有効チェック（業務管理部保留）
          -------------------------------------------------
          -- 支払保留有効チェック
          IF ( customer_bm_chk_rec2.hold_pay_flg = cv_yes ) THEN
            -- 妥当性チェックエラーメッセージ取得
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10238
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => customer_bm_chk_rec2.vendor_code
                            ,iv_token_name2  => cv_tkn_row_num
                            ,iv_token_value2 => in_index
                          );
            -- 妥当性チェックエラーメッセージ出力
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- 出力区分
                            ,iv_message    => lv_out_msg      -- メッセージ
                            ,in_new_line   => cn_zero         -- 改行
                          );
            -- 妥当性チェックエラー
            ov_retcode := cv_status_check;
          END IF;
        END LOOP;
        -- 販手残高チェック
        IF ( customer_bm_chk_cur2%ROWCOUNT = cn_zero ) THEN
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD START
          -- 妥当性チェックエラーメッセージ取得
--          lv_out_msg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_ap_type_xxcok
--                          ,iv_name         => cv_errmsg_10242
--                          ,iv_token_name1  => cv_tkn_cust_code
--                          ,iv_token_value1 => lv_customer_code
--                          ,iv_token_name2  => cv_tkn_pay_date
--                          ,iv_token_value2 => ld_pay_date
--                          ,iv_token_name3  => cv_tkn_row_num
--                          ,iv_token_value3 => in_index
--                        );
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10488
                          ,iv_token_name1  => cv_tkn_pbase_code
                          ,iv_token_value1 => gv_dept_bel_code
                          ,iv_token_name2  => cv_tkn_cust_code
                          ,iv_token_value2 => lv_customer_code
                          ,iv_token_name3  => cv_tkn_pay_date
                          ,iv_token_value3 => ld_pay_date
                          ,iv_token_name4  => cv_tkn_row_num
                          ,iv_token_value4 => in_index
                        );
-- 2011/02/22 Ver.1.5 [障害E_本稼動_05408] SCS T.Ishiwata UPD END
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
        -- カーソルクローズ
        CLOSE customer_bm_chk_cur2;
      END IF;
-- Ver_1.11 E_本稼動_15603 ADD Start
      IF ( lv_customer_code IS NOT NULL ) AND
         ( lv_vendor_code   IS NOT NULL ) AND
         ( ld_pay_date      IS NOT NULL ) AND
         ( lv_proc_type     IS NOT NULL ) THEN
        -- 保留・保留解除判定
        IF ( lv_proc_type   =  cv_pay_type3 ) THEN
          -- 保留
          lv_recv_type := cv_no;
        ELSE
          -- 保留解除
          lv_recv_type := cv_yes;
        END IF;
        SELECT SUM(xbb.expect_payment_amt_tax) expect_payment_amt_tax
        INTO   ln_pay_sum_amt
        FROM   xxcok_backmargin_balance xbb -- 販手残高テーブル
              ,xxcmm_cust_accounts      xca -- 顧客追加情報
              ,xxcmm_cust_accounts      xca2 -- 顧客追加情報【拠点】
              ,po_vendors               pv   -- 仕入先マスタ
              ,po_vendor_sites_all      pva  -- 仕入先サイトマスタ
        WHERE  xbb.supplier_code       = lv_vendor_code
        AND    xbb.expect_payment_date <= ld_pay_date
        AND    NVL(xbb.resv_flag,'N')  = lv_recv_type
        AND    xbb.fb_interface_status = cv_fb_if_type0
        AND    xbb.cust_code           = xca.customer_code
        AND    xca2.customer_code      = xca.past_sale_base_code  -- 拠点ＣＤ = 前月売上拠点
        AND  (    xca.past_sale_base_code   = gv_dept_bel_code  -- 所属拠点 = 前月売上拠点
               OR xca2.management_base_code = gv_dept_bel_code  -- 所属拠点 = 前月売上拠点の管理元拠点
               OR pva.attribute5            = gv_dept_bel_code  -- 所属拠点 = 仕入先の問合せ担当拠点
             )
        AND    xbb.cust_code           = lv_customer_code
        AND    pv.segment1             = xbb.supplier_code
        AND    pv.vendor_id            = pva.vendor_id
        AND    pva.vendor_site_code    = xbb.supplier_site_code
        AND    pva.org_id              = gn_org_id
        AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date;
        
        IF ln_pay_sum_amt IS NULL THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10567
                          ,iv_token_name1  => cv_tkn_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_tkn_vend_code
                          ,iv_token_value2 => lv_vendor_code
                          ,iv_token_name3  => cv_tkn_pay_date
                          ,iv_token_value3 => TO_CHAR(ld_pay_date, cv_date_format)
                          ,iv_token_name4  => cv_tkn_pay_amt
                          ,iv_token_value4 => ln_pay_amount
                          ,iv_token_name5  => cv_tkn_row_num
                          ,iv_token_value5 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        ELSIF ln_pay_sum_amt != ln_pay_amount THEN
          -- 妥当性チェックエラーメッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10567
                          ,iv_token_name1  => cv_tkn_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_tkn_vend_code
                          ,iv_token_value2 => lv_vendor_code
                          ,iv_token_name3  => cv_tkn_pay_date
                          ,iv_token_value3 => TO_CHAR(ld_pay_date, cv_date_format)
                          ,iv_token_name4  => cv_tkn_pay_amt
                          ,iv_token_value4 => ln_pay_amount
                          ,iv_token_name5  => cv_tkn_row_num
                          ,iv_token_value5 => in_index
                        );
          -- 妥当性チェックエラーメッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero         -- 改行
                        );
          -- 妥当性チェックエラー
          ov_retcode := cv_status_check;
        END IF;
      END IF;
-- Ver_1.11 E_本稼動_15603 ADD End

    END IF;
    -- 処理結果退避
    ov_segment1 := lv_vendor_code;   -- チェック後項目1：仕入先コード
    ov_segment2 := lv_customer_code; -- チェック後項目2：顧客コード
    ov_segment3 := ld_pay_date;      -- チェック後項目3：支払日
    ov_segment4 := ln_pay_amount;    -- チェック後項目4：支払金額
    ov_segment5 := lv_proc_type;     -- チェック後項目5：処理タイプ
  --
  EXCEPTION
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_validate_item;
  --
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
     ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
    ,ov_retcode OUT VARCHAR2 -- リターン・コード
    ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
    ,in_file_id IN  VARCHAR2 -- ファイルID
    ,iv_format  IN  VARCHAR2 -- フォーマット
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf      VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);    -- リターン・コード
    lv_errmsg      VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    lv_out_msg     VARCHAR2(2000); -- メッセージ
    lb_retcode     BOOLEAN;        -- メッセージ戻り値
    -- エラーメッセージ用
    lv_prof_err    fnd_profile_options.profile_option_name%TYPE := NULL; -- プロファイル退避
    ln_user_err    fnd_user.user_id%TYPE                        := NULL; -- ユーザID退避
    --===============================
    -- ローカル例外
    --===============================
    get_date_err_expt   EXCEPTION; -- 業務処理日付取得エラー
    get_prof_err_expt   EXCEPTION; -- プロファイル取得エラー
    get_dept_err_expt   EXCEPTION; -- 所属部門取得エラー
    get_org_id_err_expt EXCEPTION; -- 所属部門取得エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.コンカレント入力パラメータメッセージ出力
    -------------------------------------------------
    -- コンカレントパラメータ.ファイルIDメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00016
                    ,iv_token_name1  => cv_tkn_file_id
                    ,iv_token_value1 => TO_CHAR(in_file_id)
                  );
    -- コンカレントパラメータ.ファイルIDメッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力区分
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_zero         -- 改行
                  );
    -- コンカレントパラメータ.フォーマットパターンメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00017
                    ,iv_token_name1  => cv_tkn_format
                    ,iv_token_value1 => iv_format
                  );
    -- コンカレントパラメータ.フォーマットパターンメッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力区分
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_one          -- 改行
                  );
    -------------------------------------------------
    -- 2.業務処理日付取得
    -------------------------------------------------
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    -- NULLの場合はエラー
    IF ( gd_proc_date IS NULL ) THEN
      RAISE get_date_err_expt;
    END IF;
    -------------------------------------------------
    -- 3.業務管理部部門コードプロファイル取得
    -------------------------------------------------
    gv_dept_act_code := FND_PROFILE.VALUE(cv_dept_act_code);
    -- NULLの場合はエラー
    IF ( gv_dept_act_code IS NULL ) THEN
      lv_prof_err := cv_dept_act_code;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 4.所属部門コード取得
    -------------------------------------------------
    gv_dept_bel_code := xxcok_common_pkg.get_department_code_f(cn_created_by);
    -- NULLの場合はエラー
    IF ( gv_dept_bel_code IS NULL ) THEN
      ln_user_err := cn_created_by;
      RAISE get_dept_err_expt;
    END IF;
    -------------------------------------------------
    -- 5.部門判定
    -------------------------------------------------
    IF ( gv_dept_act_code = gv_dept_bel_code ) THEN
      gv_dept_flg := cv_act_dept; -- 業務管理部を設定
    ELSE
      gv_dept_flg := cv_bel_dept; -- 各拠点部門を設定
    END IF;
    -------------------------------------------------
    -- 6.営業単位IDプロファイル取得
    -------------------------------------------------
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_prof_err := cv_prof_org_id;
      RAISE get_prof_err_expt;
    END IF;
  --
-- Ver_1.9 E_本稼動_14790 ADD Start
    -------------------------------------------------
    -- 7.「事務センター顧客指定フォーマットパターン」プロファイル取得
    -------------------------------------------------
    gv_prof_cent_proc := FND_PROFILE.VALUE( cv_prof_cent_proc );
    IF ( gv_prof_cent_proc IS NULL ) THEN
      lv_prof_err := cv_prof_cent_proc;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 8.顧客指定判定
    -------------------------------------------------
    IF ( gv_prof_cent_proc = iv_format ) THEN
      gv_f_cend_cust := cv_yes; -- 「顧客指定である」を設定（顧客指定用メニューから起動）
    ELSE
      gv_f_cend_cust := cv_no;  -- 「顧客指定でない」を設定
    END IF;
-- Ver_1.9 E_本稼動_14790 ADD End
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 業務処理日付取得例外ハンドラ
    ----------------------------------------------------------
    WHEN get_date_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00028
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力区分
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- プロファイル取得例外ハンドラ
    ----------------------------------------------------------
    WHEN get_prof_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00003
                      ,iv_token_name1  => cv_tkn_profile
                      ,iv_token_value1 => lv_prof_err
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力区分
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- 所属部門取得例外ハンドラ
    ----------------------------------------------------------
    WHEN get_dept_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00030
                      ,iv_token_name1  => cv_tkn_user_id
                      ,iv_token_value1 => ln_user_err
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力区分
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END init_proc;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
    ,ov_retcode OUT VARCHAR2 -- リターン・コード
    ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
    ,iv_file_id IN  VARCHAR2 -- ファイルID
    ,iv_format  IN  VARCHAR2 -- フォーマット
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf        VARCHAR2(5000);                                    -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);                                       -- リターン・コード
    lv_errmsg        VARCHAR2(5000);                                    -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);                                    -- メッセージ
    lb_retcode       BOOLEAN;                                           -- メッセージ戻り値
    ln_file_id       xxccp_mrp_file_ul_interface.file_id%TYPE;          -- ファイルID
    lv_format        xxccp_mrp_file_ul_interface.file_format%TYPE;      -- フォーマット
    -- BLOB変換後データ分割後退避用
    ln_col_cnt       PLS_INTEGER := 0;                                  -- CSV項目数
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--    ln_row_cnt       PLS_INTEGER := 0;                                  -- CSV行数
    ln_row_cnt       PLS_INTEGER := 1;                                  -- CSV行数
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    ln_line_cnt      PLS_INTEGER := 0;                                  -- CSV処理行カウンタ
    lt_csv_data      xxcok_common_pkg.g_split_csv_tbl;                  -- CSV分割データ
    lt_file_data     xxccp_common_pkg2.g_file_data_tbl;                 -- BLOB変換後データ退避(空白行排除後)
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    lt_file_data_all xxccp_common_pkg2.g_file_data_tbl;                 -- BLOB変換後データ退避(全データ)
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    lt_check_data    g_check_data_ttype;                                -- チェック後データ退避
    lv_vendor_code   po_vendors.segment1%TYPE;                          -- 仕入先コード
    lv_customer_code hz_cust_accounts.account_number%TYPE;              -- 顧客コード
    ld_pay_date      xxcok_backmargin_balance.expect_payment_date%TYPE; -- 支払日
    ln_pay_amount    xxcok_backmargin_balance.backmargin%TYPE;          -- 支払金額
    lv_proc_type     xxcok_backmargin_balance.resv_flag%TYPE;           -- 処理タイプ
    --===============================
    -- ローカル例外
    --===============================
    blob_err_expt    EXCEPTION; -- BLOB変換エラー
    no_data_err_expt EXCEPTION; -- 販手残高情報取得エラー
    proc_err_expt    EXCEPTION; -- 呼出しプログラムのエラー
  --
  BEGIN
  --
    --===============================================
    -- A-0.初期化
    --===============================================
    lv_retcode := cv_status_normal;
    ln_file_id := TO_NUMBER(TRUNC(iv_file_id));
    lv_format  := iv_format;
    lt_file_data.delete;
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    lt_file_data_all.delete;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    --===============================================
    -- A-1.初期処理
    --===============================================
    --
    init_proc(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      ,ov_retcode => lv_retcode -- リターン・コード
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      ,in_file_id => ln_file_id -- ファイルID
      ,iv_format  => lv_format  -- フォーマット
    );
    -- ステータスエラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-2.ファイルアップロードデータ取得
    --===============================================
    --
    -- 1.BLOBデータ変換
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => ln_file_id   -- ファイルID
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--      ,ov_file_data => lt_file_data -- BLOB変換後データ退避
      ,ov_file_data => lt_file_data_all -- BLOB変換後データ退避
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
      ,ov_errbuf    => lv_errbuf    -- エラー・メッセージ
      ,ov_retcode   => lv_retcode   -- リターン・コード
      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ 
    );
    -- ステータスエラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE blob_err_expt;
    END IF;
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    -- 取得したデータから、空白行(カンマのみの行)を排除する
    << blob_data_loop >>
    FOR i IN 1..lt_file_data_all.COUNT LOOP
      IF ( LENGTHB( REPLACE( lt_file_data_all(i), ',', '') ) <> cn_zero ) THEN
        ln_line_cnt := ln_line_cnt + cn_one;
        lt_file_data(ln_line_cnt) := lt_file_data_all(i);
      END IF;
    END LOOP blob_data_loop;
    -- 編集用のテーブル削除
    lt_file_data_all.delete;
    -- CSV処理行カウンタ初期化
    ln_line_cnt := cn_zero;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    -- 処理対象件数を退避
    gn_target_cnt := lt_file_data.COUNT - cn_one; -- ヘッダーは除く
    -- 処理対象存在チェック
    IF ( gn_target_cnt <= cn_zero ) THEN
      RAISE no_data_err_expt;
    END IF;
    -- 2.BLOB変換後データチェックループ
    << blob_data_check_loop >>
    FOR ln_line_cnt IN 2..lt_file_data.COUNT LOOP
      --===============================================
      -- A-3.ファイルアップロードデータ変換
      --===============================================
      --
      -- 1.CSV文字列分割
       xxcok_common_pkg.split_csv_data_p(
         ov_errbuf        => lv_errbuf                 -- エラー・メッセージ
        ,ov_retcode       => lv_retcode                -- リターン・コード
        ,ov_errmsg        => lv_errmsg                 -- ユーザー・エラー・メッセージ
        ,iv_csv_data      => lt_file_data(ln_line_cnt) -- CSV文字列
        ,on_csv_col_cnt   => ln_col_cnt                -- CSV項目数
        ,ov_split_csv_tab => lt_csv_data               -- CSV分割データ
      );
      -- ステータスエラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE proc_err_expt;
      END IF;
      --
      --===============================================
      -- A-4.妥当性チェック処理
      --===============================================
      --
      chk_validate_item(
           ov_errbuf   => lv_errbuf             -- エラー・メッセージ
          ,ov_retcode  => lv_retcode            -- リターン・コード
          ,ov_errmsg   => lv_errmsg             -- ユーザー・エラー・メッセージ
          ,in_index    => ln_line_cnt           -- 行番号
          ,iv_segment1 => TRIM(lt_csv_data(1))  -- チェック前項目1：仕入先コード
          ,iv_segment2 => TRIM(lt_csv_data(2))  -- チェック前項目2：顧客コード
          ,iv_segment3 => TRIM(lt_csv_data(3))  -- チェック前項目3：支払日
          ,iv_segment4 => TRIM(lt_csv_data(4))  -- チェック前項目4：支払金額
          ,iv_segment5 => TRIM(lt_csv_data(5))  -- チェック前項目5：処理タイプ
          ,ov_segment1 => lv_vendor_code        -- チェック後項目1：仕入先コード
          ,ov_segment2 => lv_customer_code      -- チェック後項目2：顧客コード
          ,ov_segment3 => ld_pay_date           -- チェック後項目3：支払日
          ,ov_segment4 => ln_pay_amount         -- チェック後項目4：支払金額
          ,ov_segment5 => lv_proc_type          -- チェック後項目5：処理タイプ
        );
      --
      --===============================================
      -- A-5.残高更新アップロードデータの格納
      --===============================================
      --
      -- ステータスエラー判定：正常時
      IF ( lv_retcode = cv_status_normal ) THEN
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--        -- 正常データの行数をインクリメント
--        ln_row_cnt := ln_row_cnt + 1;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
        -- 正常データ退避
        lt_check_data(ln_row_cnt).vendor_code   := lv_vendor_code;   -- 仕入先コード
        lt_check_data(ln_row_cnt).customer_code := lv_customer_code; -- 顧客コード
        lt_check_data(ln_row_cnt).pay_date      := ld_pay_date;      -- 支払日
        lt_check_data(ln_row_cnt).pay_amount    := ln_pay_amount;    -- 支払金額
        lt_check_data(ln_row_cnt).proc_type     := lv_proc_type;     -- 処理タイプ
      -- ステータスエラー判定：チェックエラー時
      ELSIF ( lv_retcode = cv_status_check ) THEN
        -- メッセージ出力
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力区分
                        ,iv_message    => NULL            -- メッセージ
                        ,in_new_line   => cn_one          -- 改行
                      );
        -- エラー件数をインクリメント
        gn_error_cnt := gn_error_cnt + 1;
      -- ステータスエラー判定：エラー時
      ELSE
        -- エラー終了
        RAISE proc_err_expt;
      END IF;
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
      --===============================================
      -- A-6.残高の更新
      --===============================================
      -- ステータスエラー判定：正常時
      IF ( lv_retcode = cv_status_normal ) THEN
        -- 残高更新処理
        upd_bm_balance_data(
             ov_errbuf     => lv_errbuf     -- エラー・メッセージ
            ,ov_retcode    => lv_retcode    -- リターン・コード
            ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--            ,in_index      => ln_line_cnt   -- 行番号
            ,in_index      => ln_row_cnt    -- 行番号
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
            ,it_check_data => lt_check_data -- チェック後データ
          );
        -- ステータスエラー判定(ロックエラー)
        IF ( lv_retcode = cv_status_lock ) THEN
          -- メッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10474
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => ln_line_cnt
                        );
          -- メッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_one          -- 改行
                        );
          -- エラー件数をインクリメント
          gn_error_cnt := gn_error_cnt + 1;
        -- ステータスエラー判定(更新エラー)
        ELSIF ( lv_retcode = cv_status_update ) THEN
          -- メッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10475
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => ln_line_cnt
                        );
          -- メッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero          -- 改行
                        );
          -- エラー内容出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_errbuf       -- メッセージ
                          ,in_new_line   => cn_one          -- 改行
                        );
          -- エラー件数をインクリメント
          gn_error_cnt := gn_error_cnt + 1;
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD START
        -- ステータスエラー判定(挿入エラー)
        ELSIF ( lv_retcode = cv_status_insert ) THEN
          -- メッセージ取得
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcfo
                          ,iv_name         => cv_errmsg_00024
                          ,iv_token_name1  => cv_tkn_table
                          ,iv_token_name2  => cv_tkn_errmsg
                          ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_bm_balance_rtn_info)
                          ,iv_token_value2 => lv_errmsg
                        );
          -- メッセージ出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_out_msg      -- メッセージ
                          ,in_new_line   => cn_zero          -- 改行
                        );
          -- エラー内容出力
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- 出力区分
                          ,iv_message    => lv_errbuf       -- メッセージ
                          ,in_new_line   => cn_one          -- 改行
                        );
          -- エラー件数をインクリメント
          gn_error_cnt := gn_error_cnt + 1;
-- 2012/09/20 Ver.1.8 [E_本稼動_10100] SCSK T.Osawa ADD END
        -- ステータスエラー判定(その他例外)
        ELSIF ( lv_retcode = cv_status_error ) THEN
          -- エラー終了
          RAISE proc_err_expt;
        -- ステータスエラー判定(正常)
        ELSE
          -- 正常終了件数をインクリメント
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
      END IF;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
      --
    END LOOP;
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
--    --===============================================
--    -- A-6.残高の更新
--    --===============================================
--    --
--    IF ( gn_error_cnt = cn_zero ) THEN
--      << upd_bm_balance_loop >>
--      FOR ln_line_cnt IN 1..lt_check_data.COUNT LOOP
--        -- 残高更新処理
--        upd_bm_balance_data(
--             ov_errbuf     => lv_errbuf     -- エラー・メッセージ
--            ,ov_retcode    => lv_retcode    -- リターン・コード
--            ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ
--            ,in_index      => ln_line_cnt   -- 行番号
--            ,it_check_data => lt_check_data -- チェック後データ
--          );
--        -- ステータスエラー判定
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE proc_err_expt;
--        END IF;
--        -- 正常終了件数をインクリメント
--        gn_normal_cnt := gn_normal_cnt + 1;
--      END LOOP;
--    END IF;
    -- チェック・更新でエラーの場合、更新したデータをROLLBACK(削除処理がある為)
    IF ( gn_error_cnt <> cn_zero ) THEN
      ROLLBACK;
    END IF;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    --
    --===============================================
    -- A-7.ファイルアップロードデータの削除
    --===============================================
    --
    del_file_upload_data(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      ,ov_retcode => lv_retcode -- リターン・コード
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
      ,in_file_id => ln_file_id -- ファイルID
    );
    -- ステータスエラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE proc_err_expt;
-- Start 2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    ELSE
      -- チェック・更新エラーの場合、異常終了させるのでここでCOMMIT
      COMMIT;
-- End   2010/01/20 Ver_1.3 E_本稼動_01115 K.Kiriu
    END IF;
    -- 妥当性チェックエラー判定
    IF ( gn_error_cnt <> cn_zero ) THEN
      RAISE proc_err_expt;
    END IF;
    -- 正常終了
    ov_retcode := lv_retcode;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- BLOB変換例外ハンドラ
    ----------------------------------------------------------
    WHEN blob_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00041
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(ln_file_id)
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力区分
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- 残高更新情報取得例外ハンドラ
    ----------------------------------------------------------
    WHEN no_data_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_10217
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力区分
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- サブプログラム例外ハンドラ
    ----------------------------------------------------------
    WHEN proc_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END submain;
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
     errbuf     OUT VARCHAR2 -- エラー・メッセージ
    ,retcode    OUT VARCHAR2 -- リターン・コード
    ,iv_file_id IN  VARCHAR2 -- ファイルID
    ,iv_format  IN  VARCHAR2 -- フォーマット
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000);  -- メッセージ
    lv_message_code VARCHAR2(5000);  -- 処理終了メッセージ
    lb_retcode      BOOLEAN;         -- メッセージ戻り値
  --
  BEGIN
  --
    --===============================================
    -- 初期化
    --===============================================
    lv_out_msg := NULL;
    --===============================================
    -- コンカレントヘッダ出力
    --===============================================
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力区分
                    ,iv_message    => NULL            -- メッセージ
                    ,in_new_line   => cn_one          -- 改行
                  );
    --
    --===============================================
    -- サブメイン処理
    --===============================================
    --
    submain(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      ,ov_retcode => lv_retcode -- リターン・コード
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      ,iv_file_id => iv_file_id -- ファイルID
      ,iv_format  => iv_format  -- フォーマット
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力区分
                      ,iv_message    => lv_errbuf       -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      -- エラー時処理件数設定
      gn_normal_cnt := cn_zero; -- 正常件数
      gn_error_cnt  := cn_one;  -- エラー件数
    END IF;
    --
    --===============================================
    -- A-8.終了処理
    --===============================================
    -------------------------------------------------
    -- 1.対象件数メッセージ出力
    -------------------------------------------------
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力区分
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_zero         -- 改行
                  );
    -------------------------------------------------
    -- 2.成功件数メッセージ出力
    -------------------------------------------------
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力区分
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_zero         -- 改行
                  );
    -------------------------------------------------
    -- 3.成功件数メッセージ出力
    -------------------------------------------------
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力区分
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_one          -- 改行
                  );
    -------------------------------------------------
    -- 4.終了メッセージ出力
    -------------------------------------------------
    -- 終了メッセージ判断
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => lv_message_code
                   );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力区分
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_zero         -- 改行
                  );
    -- ステータスセット
    retcode := lv_retcode;
    -- ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  --
  END main;
  --
END XXCOK016A01C;
/
