CREATE OR REPLACE PACKAGE BODY XXCMM002A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A05C(body)
 * Description      : 仕入先マスタデータ連携
 * MD.050           : 仕入先マスタデータ連携 MD050_CMM_002_A05
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理プロシージャ(A-1)
 *  get_u_people_data      新規登録以外の社員データ取得プロシージャ(A-3)
 *  update_output_csv      中間I/Fテーブルデータ登録(更新)プロシージャ(A-7)
 *  get_i_people_data      新規登録の社員データ取得プロシージャ(A-8)
 *  add_output_csv         中間I/Fテーブルデータ登録(新規登録)プロシージャ(A-10)
 *  delete_table           仕入先従業員情報中間I/Fテーブルデータ削除プロシージャ(A-2)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   SCS 福間 貴子    初回作成
 *  2009/03/03    1.1   SCS 吉川 博章    新規連携時、仕入先サイトのATTRIBUTE_CATEGORYに
 *                                       ORG_IDを設定するよう修正
 *  2009/04/21    1.2   SCS 吉川 博章    障害T1_0255, T1_0388, T1_0438 対応
 *  2009/04/24          SCS 吉川 博章    仕入先登録済み、サイト「会社」未登録時の対応
 *  2009/07/17    1.3   SCS 久保島 豊    統合テスト障害0000204の対応
 *                                       CSVファイルを作成しBFAのローダーで中間テーブルに取込から
 *                                       CSVファイル作成は廃止し、中間テーブルにINSERTを行うように修正
 *  2009/10/02    1.4   SCS 久保島 豊    統合テスト障害0001221の対応
 *                                       仕入先のマッピングを移行に合わせる
 *  2010/04/12    1.5   SCS 久保島 豊    障害E_本稼動_02240の対応
 *                                       ・抽出SQLに条件を追加
 *                                       ・支払グループの導出方法の変更
 *                                       ・更新対象データチェック方法の変更
 *                                       ・再雇用者に対する処理の追加
 *                                       ・仕入先マスタの無効日の設定の変更
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
  gn_warn_cnt               NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  lock_expt                 EXCEPTION;        -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM002A05C';                    -- パッケージ名
  -- プロファイル
-- 2009/07/17 Ver1.3 delete start by Yutaka.Kuboshima
--  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_OUT_DIR';           -- 連携用CSVファイル出力先
--  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_OUT_FILE';          -- 連携用CSVファイル名
-- 2009/07/17 Ver1.3 delete end by Yutaka.Kuboshima
  cv_cal_code               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_SYS_CAL_CODE';      -- システム稼働日カレンダコード値
  cv_jyugyoin_kbn_s         CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_JYUGYOIN_KBN_S';    -- 従業員区分の正社員値
  cv_jyugyoin_kbn_d         CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_JYUGYOIN_KBN_D';    -- 従業員区分のダミー値
  cv_vendor_type            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_VENDOR_TYPE';       -- 仕入先タイプ
  cv_country                CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_COUNTRY';           -- 国記号
  cv_accts_pay_ccid         CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_ACCTS_PAY_CCID';    -- 負債勘定科目ID
  cv_prepay_ccid            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PREPAY_CCID';       -- 前払／仮払金勘定科目ID
  cv_group_type_nm          CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_GROUP_TYPE_NM';     -- 支払グループタイプ名
  cv_pay_bumon_cd           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_BUMON_CD';      -- 本社総振込支払部門コード
-- 2009/10/02 Ver1.4 delete start by Yutaka.Kuboshima
--  cv_pay_bumon_nm           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_BUMON_NM';      -- 本社総振込支払部門名称
-- 2009/10/02 Ver1.4 delete end by Yutaka.Kuboshima
  cv_pay_method_nm          CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_METHOD_NM';     -- 本社総振込支払方法名称
  cv_pay_bank               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_BANK';          -- 本社総振込支払窓口銀行支店
  cv_koguti_genkin_nm       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_KOGUTI_GENKIN_NM';  -- 小口現金支払方法名称
-- 2009/10/02 Ver1.4 delete start by Yutaka.Kuboshima
--  cv_pay_type_nm            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_TYPE_NM';       -- 支払種類名称
-- 2009/10/02 Ver1.4 delete end by Yutaka.Kuboshima
  cv_terms_id               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_TERMS_ID';          -- 支払条件
-- Ver1.2  2009/04/21  Add  障害：T1_0438対応  銀行手数料負担者を追加「当方(I)」
  cv_bank_charge_bearer     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_BANK_CHARGE';       -- 銀行手数料負担者
-- End Ver1.2
  cv_bank_number            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_BANK_NUMBER';       -- 現金ダミー銀行支店コード
  cv_bank_num               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_BANK_NUM';          -- 現金ダミー銀行コード
  cv_bank_nm                CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_BANK_NM';           -- 現金ダミー銀行名称
  cv_shiten_nm              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_SHITEN_NM';         -- 現金ダミー銀行支店名称
  cv_account_num            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_ACCOUNT_NUM';       -- 現金ダミー口座番号
  cv_currency_cd            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_CURRENCY_CD';       -- 通貨コード
  cv_account_type           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_ACCOUNT_TYPE';      -- 現金ダミー口座種別
  cv_holder_nm              CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_HOLDER_NM';         -- 現金ダミー口座名義人名
  cv_holder_alt_nm          CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_HOLDER_ALT_NM';     -- 現金ダミー口座名義人カナ名
  cv_address_nm1            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_ADDRESS1_NM';       -- 所在地1
  cv_address_nm2            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_ADDRESS2_NM';       -- 所在地2
  --
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
  cv_pay_method_cd          CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PAY_METHOD_CD';     -- ダミー支払方法
  cv_site_vat_cd            CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_SITE_VAT_CD';       -- ダミー請求書税金コード
  cv_prepay_ccid_aff1       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PREPAY_CCID_AFF1';  -- 前払/仮払金勘定科目AFF1
  cv_prepay_ccid_aff3       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PREPAY_CCID_AFF3';  -- 前払/仮払金勘定科目AFF3
  cv_prepay_ccid_aff4       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PREPAY_CCID_AFF4';  -- 前払/仮払金勘定科目AFF4
  cv_prepay_ccid_aff5       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PREPAY_CCID_AFF5';  -- 前払/仮払金勘定科目AFF5
  cv_prepay_ccid_aff6       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PREPAY_CCID_AFF6';  -- 前払/仮払金勘定科目AFF6
  cv_prepay_ccid_aff7       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PREPAY_CCID_AFF7';  -- 前払/仮払金勘定科目AFF7
  cv_prepay_ccid_aff8       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A05_PREPAY_CCID_AFF8';  -- 前払/仮払金勘定科目AFF8
  cv_bks_name               CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_NAME';              -- GL会計帳簿名
-- 2009/10/02 Ver1.4 add end by Yutaka.Kuboshima
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                      -- プロファイル名
-- 2009/07/17 Ver1.3 delete start by Yutaka.Kuboshima
--  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル出力先';
--  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル名';
-- 2009/07/17 Ver1.3 delete end by Yutaka.Kuboshima
  cv_tkn_cal_code           CONSTANT VARCHAR2(30)  := 'システム稼働日カレンダコード値';
  cv_tkn_jyugoin_kbn_s_nm   CONSTANT VARCHAR2(20)  := '従業員区分の正社員値';
  cv_tkn_jyugoin_kbn_d_nm   CONSTANT VARCHAR2(20)  := '従業員区分のダミー値';
  cv_tkn_vendor_type_nm     CONSTANT VARCHAR2(20)  := '仕入先タイプ';
  cv_tkn_country_nm         CONSTANT VARCHAR2(10)  := '国記号';
  cv_tkn_accts_pay_ccid_nm  CONSTANT VARCHAR2(20)  := '負債勘定科目ID';
  cv_tkn_prepay_ccid_nm     CONSTANT VARCHAR2(22)  := '前払／仮払金勘定科目ID';
  cv_tkn_group_type_nm      CONSTANT VARCHAR2(20)  := '支払グループタイプ名';
  cv_tkn_pay_bumon_cd_nm    CONSTANT VARCHAR2(24)  := '本社総振込支払部門コード';
-- 2009/10/02 Ver1.4 delete start by Yutaka.Kuboshima
--  cv_tkn_pay_bumon_nm       CONSTANT VARCHAR2(22)  := '本社総振込支払部門名称';
-- 2009/10/02 Ver1.4 delete end by Yutaka.Kuboshima
  cv_tkn_pay_method_nm      CONSTANT VARCHAR2(22)  := '本社総振込支払方法名称';
  cv_tkn_pay_bank_nm        CONSTANT VARCHAR2(26)  := '本社総振込支払窓口銀行支店';
  cv_tkn_koguti_genkin_nm   CONSTANT VARCHAR2(20)  := '小口現金支払方法名称';
-- 2009/10/02 Ver1.4 delete start by Yutaka.Kuboshima
--  cv_tkn_pay_type_nm        CONSTANT VARCHAR2(20)  := '支払種類名称';
-- 2009/10/02 Ver1.4 delete end by Yutaka.Kuboshima
  cv_tkn_terms_id_nm        CONSTANT VARCHAR2(10)  := '支払条件';
-- Ver1.2  2009/04/21  Add  障害：T1_0438対応  銀行手数料負担者を追加
  cv_tkn_bank_charge        CONSTANT VARCHAR2(30)  := '銀行手数料負担者';
-- End Ver1.2
  cv_tkn_bank_number_nm     CONSTANT VARCHAR2(24)  := '現金ダミー銀行支店コード';
  cv_tkn_bank_num_nm        CONSTANT VARCHAR2(20)  := '現金ダミー銀行コード';
  cv_tkn_bank_nm            CONSTANT VARCHAR2(20)  := '現金ダミー銀行名称';
  cv_tkn_shiten_nm          CONSTANT VARCHAR2(22)  := '現金ダミー銀行支店名称';
  cv_tkn_account_num_nm     CONSTANT VARCHAR2(20)  := '現金ダミー口座番号';
  cv_tkn_currency_cd_nm     CONSTANT VARCHAR2(10)  := '通貨コード';
  cv_tkn_account_type_nm    CONSTANT VARCHAR2(20)  := '現金ダミー口座種別';
  cv_tkn_holder_nm          CONSTANT VARCHAR2(22)  := '現金ダミー口座名義人名';
  cv_tkn_holder_alt_nm      CONSTANT VARCHAR2(26)  := '現金ダミー口座名義人カナ名';
  cv_tkn_address_nm1        CONSTANT VARCHAR2(10)  := '所在地1';
  cv_tkn_address_nm2        CONSTANT VARCHAR2(10)  := '所在地2';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- 項目名
  cv_tkn_word1              CONSTANT VARCHAR2(20)  := '社員番号';
  cv_tkn_word2              CONSTANT VARCHAR2(10)  := '、氏名 : ';
  cv_tkn_word3              CONSTANT VARCHAR2(23)  := '、支払グループコード : ';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- データ
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- ファイル名
  cv_tkn_table              CONSTANT VARCHAR2(10)  := 'NG_TABLE';                   -- テーブル
  cv_tkn_length             CONSTANT VARCHAR2(10)  := 'NG_LENGTH';                  -- 文字数
  cv_tkn_table_nm           CONSTANT VARCHAR2(31)  := '仕入先従業員情報中間I/Fテーブル';
  --
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
  cv_tkn_pay_method_cd      CONSTANT VARCHAR2(30)  := 'ダミー支払方法';             -- ダミー支払方法
  cv_tkn_site_vat_cd        CONSTANT VARCHAR2(30)  := 'ダミー請求書税金コード';     -- ダミー請求書税金コード
  cv_tkn_ccid_aff1          CONSTANT VARCHAR2(30)  := '前払/仮払金勘定科目AFF1';    -- 前払/仮払金勘定科目AFF1
  cv_tkn_ccid_aff3          CONSTANT VARCHAR2(30)  := '前払/仮払金勘定科目AFF3';    -- 前払/仮払金勘定科目AFF3
  cv_tkn_ccid_aff4          CONSTANT VARCHAR2(30)  := '前払/仮払金勘定科目AFF4';    -- 前払/仮払金勘定科目AFF4
  cv_tkn_ccid_aff5          CONSTANT VARCHAR2(30)  := '前払/仮払金勘定科目AFF5';    -- 前払/仮払金勘定科目AFF5
  cv_tkn_ccid_aff6          CONSTANT VARCHAR2(30)  := '前払/仮払金勘定科目AFF6';    -- 前払/仮払金勘定科目AFF6
  cv_tkn_ccid_aff7          CONSTANT VARCHAR2(30)  := '前払/仮払金勘定科目AFF7';    -- 前払/仮払金勘定科目AFF7
  cv_tkn_ccid_aff8          CONSTANT VARCHAR2(30)  := '前払/仮払金勘定科目AFF8';    -- 前払/仮払金勘定科目AFF8
  cv_tkn_bks_name           CONSTANT VARCHAR2(30)  := 'GL会計帳簿名';               -- GL会計帳簿名
-- 2009/10/02 Ver1.4 add end by Yutaka.Kuboshima
  --
-- 2009/07/17 Ver1.3 add start by Yutaka.Kuboshima
  cv_tkn_err_msg            CONSTANT VARCHAR2(10)  := 'ERR_MSG';                    -- 項目名
-- 2009/07/17 Ver1.3 add end by Yutaka.Kuboshima
  -- メッセージ区分
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- メッセージ
  cv_msg_90008              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';           -- コンカレント入力パラメータなし
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- プロファイル取得エラー
-- 2009/07/17 Ver1.3 delete start by Yutaka.Kuboshima
--  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- ファイル名出力メッセージ
-- 2009/07/17 Ver1.3 delete end by Yutaka.Kuboshima
  cv_msg_00214              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00214';           -- 文字数制限エラー
-- 2009/07/17 Ver1.3 delete start by Yutaka.Kuboshima
--  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- ファイルパス不正エラー
-- 2009/07/17 Ver1.3 delete end by Yutaka.Kuboshima
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- 業務日付取得エラー
  cv_msg_00036              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00036';           -- 次のシステム稼働日取得エラー
  cv_msg_00008              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';           -- ロック取得NGメッセージ
  cv_msg_00208              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00208';           -- 勤務地拠点コード(新)未入力エラー
  cv_msg_00211              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00211';           -- 以前の支払グループ取得エラー
  cv_msg_00215              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00215';           -- 支払グループコード文字数制限エラー
  cv_msg_00212              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00212';           -- 仕入先マスタデータ取得エラー
  cv_msg_00213              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00213';           -- 仕入先サイトマスタデータ取得エラー
  cv_msg_00209              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00209';           -- 従業員番号重複メッセージ
-- 2009/07/17 Ver1.3 delete start by Yutaka.Kuboshima
--  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- ファイルアクセス権限エラー
--  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSVデータ出力エラー
-- 2009/07/17 Ver1.3 delete end by Yutaka.Kuboshima
  cv_msg_00012              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00012';           -- データ削除エラー
-- 2009/07/17 Ver1.3 add start by Yutaka.Kuboshima
  cv_msg_00221              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00221';           -- 仕入先従業員情報中間I/Fテーブル登録エラー
-- 2009/07/17 Ver1.3 add end by Yutaka.Kuboshima
  -- 固定値(設定値)
  cv_insert_flg             CONSTANT VARCHAR2(1)   := 'I';                          -- 追加更新フラグ(新規)
  cv_update_flg             CONSTANT VARCHAR2(1)   := 'U';                          -- 追加更新フラグ(更新)
  cv_status_flg             CONSTANT VARCHAR2(1)   := '0';                          -- ステータスフラグ
  cv_address_length         CONSTANT NUMBER(2)     := 35;                           -- プロファイル(所在地1、2)の文字数
  cv_pay_group_length       CONSTANT NUMBER(2)     := 25;                           -- 支払グループコードの文字数
  cv_9000                   CONSTANT VARCHAR2(4)   := '9000';                       -- CSV出力時に使用する文字列
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
  cv_y_flag                 CONSTANT VARCHAR2(1)   := 'Y';                          -- Yフラグ
  cv_n_flag                 CONSTANT VARCHAR2(1)   := 'N';                          -- Nフラグ
  cv_i_flag                 CONSTANT VARCHAR2(1)   := 'I';                          -- Iフラグ
  cv_dummy                  CONSTANT VARCHAR2(1)   := '*';                          -- ダミー値(*)
--
-- Ver1.1 2009/03/03 Mod  コンテキストにORG_IDを設定
  -- ORG_ID
  gn_org_id                 CONSTANT NUMBER        := FND_GLOBAL.ORG_ID;
-- End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
-- Ver1.2  2009/04/21  Add  障害：T1_0255、T1_0388対応
  cv_site_code_comp         po_vendor_sites.vendor_site_code%TYPE := '会社';
-- End Ver1.2
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- 2009/07/17 Ver1.3 delete start by Yutaka.Kuboshima
--  gv_filepath               VARCHAR2(255);        -- 連携用CSVファイル出力先
--  gv_filename               VARCHAR2(255);        -- 連携用CSVファイル名
-- 2009/07/17 Ver1.3 delete end by Yutaka.Kuboshima
  gv_jyugyoin_kbn_s         VARCHAR2(10);         -- 従業員区分の正社員値
  gv_jyugyoin_kbn_d         VARCHAR2(10);         -- 従業員区分のダミー値
  gv_cal_code               VARCHAR2(30);         -- システム稼働日カレンダコード値
  gv_vendor_type            VARCHAR2(50);         -- 仕入先タイプ
  gv_country                VARCHAR2(50);         -- 国記号
  gv_accts_pay_ccid         VARCHAR2(50);         -- 負債勘定科目ID
  gv_prepay_ccid            VARCHAR2(50);         -- 前払／仮払金勘定科目ID
  gv_group_type_nm          VARCHAR2(50);         -- 支払グループタイプ名
  gv_pay_bumon_cd           VARCHAR2(50);         -- 本社総振込支払部門コード
-- 2009/10/02 Ver1.4 delete start by Yutaka.Kuboshima
--  gv_pay_bumon_nm           VARCHAR2(50);         -- 本社総振込支払部門名称
-- 2009/10/02 Ver1.4 delete end by Yutaka.Kuboshima
  gv_pay_method_nm          VARCHAR2(50);         -- 本社総振込支払方法名称
  gv_pay_bank               VARCHAR2(50);         -- 本社総振込支払窓口銀行支店
  gv_koguti_genkin_nm       VARCHAR2(50);         -- 小口現金支払方法名称
-- 2009/10/02 Ver1.4 delete start by Yutaka.Kuboshima
--  gv_pay_type_nm            VARCHAR2(50);         -- 支払種類名称
-- 2009/10/02 Ver1.4 delete end by Yutaka.Kuboshima
  gv_terms_id               VARCHAR2(50);         -- 支払条件
  gv_bank_number            VARCHAR2(50);         -- 現金ダミー銀行支店コード
  gv_bank_num               VARCHAR2(50);         -- 現金ダミー銀行コード
  gv_bank_nm                VARCHAR2(80);         -- 現金ダミー銀行名称
  gv_shiten_nm              VARCHAR2(80);         -- 現金ダミー銀行支店名称
  gv_account_num            VARCHAR2(50);         -- 現金ダミー口座番号
  gv_currency_cd            VARCHAR2(30);         -- 通貨コード
  gv_account_type           VARCHAR2(50);         -- 現金ダミー口座種別
  gv_holder_nm              VARCHAR2(240);        -- 現金ダミー口座名義人名
  gv_holder_alt_nm          VARCHAR2(150);        -- 現金ダミー口座名義人カナ名
  gv_address_nm1            VARCHAR2(240);        -- 所在地1
  gv_address_nm2            VARCHAR2(240);        -- 所在地2
  gd_process_date           DATE;                 -- 業務日付
  gd_select_next_date       DATE;                 -- 取得次のシステム稼働日
-- 2009/07/17 Ver1.3 delete start by Yutaka.Kuboshima
--  gf_file_hand              UTL_FILE.FILE_TYPE;   -- ファイル・ハンドルの宣言
-- 2009/07/17 Ver1.3 delete end by Yutaka.Kuboshima
  gn_target_add_cnt         NUMBER;               -- 新規登録の対象件数
  gn_target_update_cnt      NUMBER;               -- 新規登録以外の対象件数
  gv_warn_flg               VARCHAR2(1);          -- 警告フラグ
  -- 出力項目
  gn_v_interface_id         NUMBER(15);           -- 仕入先インターフェースID
  gv_v_vendor_name          VARCHAR2(80);         -- 仕入先仕入先名
  gv_v_segment1             VARCHAR2(30);         -- 仕入先仕入先番号
  gn_v_employee_id          NUMBER(22);           -- 仕入先従業員ID
  gv_v_vendor_type          VARCHAR2(30);         -- 仕入先仕入先タイプ
  gn_v_terms_id             NUMBER(22);           -- 仕入先支払条件
  gv_v_pay_group            VARCHAR2(25);         -- 仕入先支払グループコード
  gn_v_invoice_amount_limit NUMBER(22);           -- 仕入先請求限度額
  gn_v_accts_pay_ccid       NUMBER(22);           -- 仕入先負債勘定科目ID
  gn_v_prepay_ccid          NUMBER(22);           -- 仕入先前払／仮払金勘定科目ID
  gd_v_end_date_active      DATE;                 -- 仕入先無効日
  gv_v_sb_flag              VARCHAR2(1);          -- 仕入先中小法人フラグ
  gv_v_rr_flag              VARCHAR2(1);          -- 仕入先入金確認フラグ
  gv_v_attribute_category   VARCHAR2(30);         -- 仕入先予備カテゴリ
  gv_v_attribute1           VARCHAR2(150);        -- 仕入先予備1
  gv_v_attribute2           VARCHAR2(150);        -- 仕入先予備2
  gv_v_attribute3           VARCHAR2(150);        -- 仕入先予備3
  gv_v_attribute4           VARCHAR2(150);        -- 仕入先予備4
  gv_v_attribute5           VARCHAR2(150);        -- 仕入先予備5
  gv_v_attribute6           VARCHAR2(150);        -- 仕入先予備6
  gv_v_attribute7           VARCHAR2(150);        -- 仕入先予備7
  gv_v_attribute8           VARCHAR2(150);        -- 仕入先予備8
  gv_v_attribute9           VARCHAR2(150);        -- 仕入先予備9
  gv_v_attribute10          VARCHAR2(150);        -- 仕入先予備10
  gv_v_attribute11          VARCHAR2(150);        -- 仕入先予備11
  gv_v_attribute12          VARCHAR2(150);        -- 仕入先予備12
  gv_v_attribute13          VARCHAR2(150);        -- 仕入先予備13
  gv_v_attribute14          VARCHAR2(150);        -- 仕入先予備14
  gv_v_attribute15          VARCHAR2(150);        -- 仕入先予備15
  gv_v_allow_awt_flag       VARCHAR2(1);          -- 仕入先源泉徴収税使用フラグ
  gv_v_vendor_name_alt      VARCHAR2(320);        -- 仕入先仕入先カナ名称
  gv_v_ap_tax_rounding_rule VARCHAR2(1);          -- 仕入先請求税自動計算端数処理規
  gv_v_atc_flag             VARCHAR2(1);          -- 仕入先請求税自動計算計算レベル
  gv_v_atc_override         VARCHAR2(1);          -- 仕入先請求税自動計算上書きの許
  gv_v_bank_charge_bearer   VARCHAR2(1);          -- 仕入先銀行手数料負担者
  gn_s_vendor_site_id       NUMBER(22);           -- 仕入先サイト仕入先サイトID
  gv_s_vendor_site_code     VARCHAR2(15);         -- 仕入先サイト仕入先サイト名
  gv_s_address_line1        VARCHAR2(35);         -- 仕入先サイト所在地1
  gv_s_address_line2        VARCHAR2(35);         -- 仕入先サイト所在地2
  gv_s_address_line3        VARCHAR2(35);         -- 仕入先サイト所在地3
  gv_s_city                 VARCHAR2(25);         -- 仕入先サイト住所・郡市区
  gv_s_state                VARCHAR2(25);         -- 仕入先サイト住所・都道府県
  gv_s_zip                  VARCHAR2(20);         -- 仕入先サイト住所・郵便番号
  gv_s_province             VARCHAR2(25);         -- 仕入先サイト住所・州
  gv_s_country              VARCHAR2(25);         -- 仕入先サイト国
  gv_s_area_code            VARCHAR2(10);         -- 仕入先サイト市外局番
  gv_s_phone                VARCHAR2(15);         -- 仕入先サイト電話番号
  gv_s_fax                  VARCHAR2(15);         -- 仕入先サイトFAX
  gv_s_fax_area_code        VARCHAR2(10);         -- 仕入先サイトFAX市外局番
  gv_s_payment_method       VARCHAR2(25);         -- 仕入先サイト支払方法
  gv_s_bank_account_name    VARCHAR2(80);         -- 仕入先サイト口座名称
  gv_s_bank_account_num     VARCHAR2(30);         -- 仕入先サイト口座番号
  gv_s_bank_num             VARCHAR2(25);         -- 仕入先サイト銀行コード
  gv_s_bank_account_type    VARCHAR2(25);         -- 仕入先サイト預金種別
  gv_s_vat_code             VARCHAR2(20);         -- 仕入先サイト請求書税金コード
  gn_s_distribution_set_id  NUMBER(22);           -- 仕入先サイト配分セットID
  gn_s_accts_pay_ccid       NUMBER(22);           -- 仕入先サイト負債勘定科目ID
  gn_s_prepay_ccid          NUMBER(22);           -- 仕入先サイト前払／仮払金勘定科
  gn_s_terms_id             NUMBER(22);           -- 仕入先サイト支払条件
  gn_s_invoice_amount_limit NUMBER(22);           -- 仕入先サイト請求限度額
  gv_s_attribute_category   VARCHAR2(30);         -- 仕入先サイト予備カテゴリ
  gv_s_attribute1           VARCHAR2(150);        -- 仕入先サイト予備1
  gv_s_attribute2           VARCHAR2(150);        -- 仕入先サイト予備2
  gv_s_attribute3           VARCHAR2(150);        -- 仕入先サイト予備3
  gv_s_attribute4           VARCHAR2(150);        -- 仕入先サイト予備4
  gv_s_attribute5           VARCHAR2(150);        -- 仕入先サイト予備5
  gv_s_attribute6           VARCHAR2(150);        -- 仕入先サイト予備6
  gv_s_attribute7           VARCHAR2(150);        -- 仕入先サイト予備7
  gv_s_attribute8           VARCHAR2(150);        -- 仕入先サイト予備8
  gv_s_attribute9           VARCHAR2(150);        -- 仕入先サイト予備9
  gv_s_attribute10          VARCHAR2(150);        -- 仕入先サイト予備10
  gv_s_attribute11          VARCHAR2(150);        -- 仕入先サイト予備11
  gv_s_attribute12          VARCHAR2(150);        -- 仕入先サイト予備12
  gv_s_attribute13          VARCHAR2(150);        -- 仕入先サイト予備13
  gv_s_attribute14          VARCHAR2(150);        -- 仕入先サイト予備14
  gv_s_attribute15          VARCHAR2(150);        -- 仕入先サイト予備15
  gv_s_bank_number          VARCHAR2(30);         -- 仕入先サイト銀行支店コード
  gv_s_address_line4        VARCHAR2(35);         -- 仕入先サイト所在地4
  gv_s_county               VARCHAR2(25);         -- 仕入先サイト郡
  gv_s_allow_awt_flag       VARCHAR2(1);          -- 仕入先サイト源泉徴収税使用フラ
  gn_s_awt_group_id         NUMBER(15);           -- 仕入先サイト源泉徴収税グループ
  gv_s_vendor_site_code_alt VARCHAR2(320);        -- 仕入先サイト仕入先サイト名（カ
  gv_s_address_lines_alt    VARCHAR2(560);        -- 仕入先サイト住所カナ
  gv_s_ap_tax_rounding_rule VARCHAR2(1);          -- 仕入先サイト請求税自動計算端数
  gv_s_atc_flag             VARCHAR2(1);          -- 仕入先サイト請求税自動計算計算
  gv_s_atc_override         VARCHAR2(1);          -- 仕入先サイト請求税自動計算上書
  gv_s_bank_charge_bearer   VARCHAR2(1);          -- 仕入先サイト銀行手数料負担者
  gv_s_bank_branch_type     VARCHAR2(25);         -- 仕入先サイト銀行支店タイプ
  gv_s_cdm_flag             VARCHAR2(25);         -- 仕入先サイトRTS取引からデビッ
  gv_s_sn_method            VARCHAR2(25);         -- 仕入先サイト仕入先通知方法
  gv_s_email_address        VARCHAR2(2000);       -- 仕入先サイトEメールアドレス
  gv_s_pps_flag             VARCHAR2(1);          -- 仕入先サイト主支払サイトフラグ
  gv_s_ps_flag              VARCHAR2(1);          -- 仕入先サイト購買フラグ
-- Ver1.2  2009/04/21  Add  障害：T1_0438対応  銀行手数料負担者を追加
  gv_s_bank_charge_new      VARCHAR2(1);          -- 仕入先サイト銀行手数料負担者(新規登録用)
-- End Ver1.2
--
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
  gv_pay_method_cd          VARCHAR2(25);         -- 仕入先サイトダミー支払方法
  gv_site_vat_cd            VARCHAR2(20);         -- 仕入先サイトダミー請求書税金コード
  gv_non_recover_tax_flag   VARCHAR2(1);          -- 会計オプション：控除対象消費税使用可
  gv_tax_rounding_rule      VARCHAR2(1);          -- 会計オプション：端数処理規則
  gv_auto_tax_calc_flag     VARCHAR2(1);          -- 買掛/未払金オプション：計算レベル
  gv_auto_tax_calc_override VARCHAR2(1);          -- 買掛/未払金オプション：計算レベル上書きの許可
  gv_bks_name               VARCHAR2(100);        -- GL会計帳簿名
  gn_chart_of_acct_id       NUMBER;               -- 勘定科目体系ＩＤ
  gv_id_flex_code           VARCHAR2(100);        -- キーフレックスコード
  g_aff_segments_tab        fnd_flex_ext.segmentarray; -- AFFセグメントテーブル
-- 2009/10/02 Ver1.4 add end by Yutaka.Kuboshima
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  CURSOR get_u_people_data_cur
  IS
    SELECT   p.person_id AS person_id,                              -- 従業員ID
             p.employee_number AS employee_number,                  -- 従業員番号
             p.per_information18 AS per_information18,              -- 氏名(姓)
             p.per_information19 AS per_information19,              -- 氏名(名)
             t.actual_termination_date AS actual_termination_date,  -- 退職年月日
             a.ass_attribute3 AS ass_attribute3,                    -- 部門コード
             s.vendor_id AS vendor_id                               -- 仕入先ID
-- Ver1.2  2009/04/21  Add  障害：T1_0388対応  従業員仕入先サイト対応
            ,pvs.vendor_site_id
-- End Ver1.2
-- 2010/04/12 Ver1.5 E_本稼動_02240 add start by Y.Kuboshima
            ,s.end_date_active AS end_date_active
            ,pvs.attribute5 AS attribute5
-- 2010/04/12 Ver1.5 E_本稼動_02240 add end by Y.Kuboshima
    FROM     per_periods_of_service t,
             per_all_assignments_f a,
-- Ver1.2  2009/04/21  Add  障害：T1_0388対応  従業員仕入先サイト対応
             po_vendor_sites  pvs,
-- End Ver1.2
             po_vendors s,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
    AND      (p.attribute3 = gv_jyugyoin_kbn_s OR p.attribute3 = gv_jyugyoin_kbn_d)
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      p.person_id = s.employee_id
-- Ver1.2  2009/04/21  Add  障害：T1_0388対応  従業員仕入先サイト対応
    AND      s.vendor_id = pvs.vendor_id
    AND      pvs.vendor_site_code = cv_site_code_comp
-- End Ver1.2
    AND      a.period_of_service_id = t.period_of_service_id
-- 2010/04/12 Ver1.5 E_本稼動_02240 add start by Y.Kuboshima
    AND      p.last_update_date BETWEEN gd_process_date AND SYSDATE
-- 2010/04/12 Ver1.5 E_本稼動_02240 add end by Y.Kuboshima
    ORDER BY p.employee_number
  ;
  TYPE g_u_people_data_ttype IS TABLE OF get_u_people_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_u_people_data            g_u_people_data_ttype;
  --
  -- 仕入先自体は登録済みだが、サイトに「会社」が存在しないものも新規として抽出する（2009/04/24）
  CURSOR get_i_people_data_cur
  IS
    SELECT   p.person_id AS person_id,                              -- 従業員ID
             p.employee_number AS employee_number,                  -- 従業員番号
             p.per_information18 AS per_information18,              -- 氏名(姓)
             p.per_information19 AS per_information19,              -- 氏名(名)
             a.ass_attribute3 AS ass_attribute3                     -- 部門コード
-- Ver1.2  2009/04/24  Add  仕入先登録済み、サイト「会社」未登録対応
            ,s.vendor_id AS vendor_id                               -- 仕入先ID
-- End Ver1.2
    FROM     po_vendors s,
             per_periods_of_service t,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
    AND      (p.attribute3 = gv_jyugyoin_kbn_s OR p.attribute3 = gv_jyugyoin_kbn_d)
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = t.period_of_service_id
    AND      (t.actual_termination_date IS NULL OR t.actual_termination_date >= gd_process_date)
    AND      p.person_id = s.employee_id(+)
-- 2009/04/21  Mod  障害：T1_0388対応  従業員仕入先サイト対応
--    AND      s.employee_id IS NULL
    AND      NOT EXISTS ( SELECT   'x'
                          FROM     po_vendor_sites  pvs
                          WHERE    s.vendor_id = pvs.vendor_id
                          AND      pvs.vendor_site_code = cv_site_code_comp )
-- End Ver1.2
-- 2010/04/12 Ver1.5 E_本稼動_02240 add start by Y.Kuboshima
    AND      p.last_update_date BETWEEN gd_process_date AND SYSDATE
-- 2010/04/12 Ver1.5 E_本稼動_02240 add end by Y.Kuboshima
    ORDER BY p.employee_number
  ;
  TYPE g_i_people_data_ttype IS TABLE OF get_i_people_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_i_people_data            g_i_people_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理プロシージャ(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                  -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- ファイルオープンモード
    cv_open_mode_w          CONSTANT VARCHAR2(10)  := 'w';           -- 上書き
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
    cv_short_name           VARCHAR2(5) := 'SQLGL';
-- 2009/10/02 Ver1.4 add end by Yutaka.Kuboshima
--
    -- *** ローカル変数 ***
    lb_fexists              BOOLEAN;              -- ファイルが存在するかどうか
    ln_file_size            NUMBER;               -- ファイルの長さ
    ln_block_size           NUMBER;               -- ファイルシステムのブロックサイズ
    lv_tkn_nm               VARCHAR2(31);         -- トークン
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
    lb_ret                  BOOLEAN;
    ln_ccid                 gl_code_combinations.code_combination_id%TYPE;
-- 2009/10/02 Ver1.4 add end by Yutaka.Kuboshima
--
    -- *** ローカル・カーソル ***
    CURSOR get_vendors_interface_cur IS
      SELECT   vendors_interface_id
      FROM     xx03_vendors_interface
-- Ver1.2  2009/04/21  Add  障害：T1_0255対応  会計とバッティングしないよう条件を追加
      WHERE    vndr_vendor_type_lkup_code = gv_vendor_type
-- End Ver1.2
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ============================================================
    --  固定出力(入力パラメータ部)
    -- ============================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp             -- 'XXCCP'
                    ,iv_name         => cv_msg_90008               -- コンカレント入力パラメータなし
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ============================================================
    --  プロファイルの取得
    -- ============================================================
-- 2009/07/17 delete start by Yutaka.Kuboshima
--    gv_filepath := fnd_profile.value(cv_filepath);
--    IF (gv_filepath IS NULL) THEN
--      lv_tkn_nm := cv_tkn_filepath_nm;
--      RAISE global_process_expt;
--    END IF;
--    gv_filename := fnd_profile.value(cv_filename);
--    IF (gv_filename IS NULL) THEN
--      lv_tkn_nm := cv_tkn_filename_nm;
--      RAISE global_process_expt;
--    END IF;
-- 2009/07/17 delete end by Yutaka.Kuboshima
    gv_cal_code := fnd_profile.value(cv_cal_code);
    IF (gv_cal_code IS NULL) THEN
      lv_tkn_nm := cv_tkn_cal_code;
      RAISE global_process_expt;
    END IF;
    gv_vendor_type := fnd_profile.value(cv_vendor_type);
    IF (gv_vendor_type IS NULL) THEN
      lv_tkn_nm := cv_tkn_vendor_type_nm;
      RAISE global_process_expt;
    END IF;
    gv_country := fnd_profile.value(cv_country);
    IF (gv_country IS NULL) THEN
      lv_tkn_nm := cv_tkn_country_nm;
      RAISE global_process_expt;
    END IF;
-- Ver1.2  2009/04/21  Del  障害：T1_0438対応  会計オプションから取得するよう変更（負債・前払金）
--    gv_accts_pay_ccid := fnd_profile.value(cv_accts_pay_ccid);
--    IF (gv_accts_pay_ccid IS NULL) THEN
--      lv_tkn_nm := cv_tkn_accts_pay_ccid_nm;
--      RAISE global_process_expt;
--    END IF;
--    gv_prepay_ccid := fnd_profile.value(cv_prepay_ccid);
--    IF (gv_prepay_ccid IS NULL) THEN
--      lv_tkn_nm := cv_tkn_prepay_ccid_nm;
--      RAISE global_process_expt;
--    END IF;
-- End Ver1.2
    gv_group_type_nm := fnd_profile.value(cv_group_type_nm);
    IF (gv_group_type_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_group_type_nm;
      RAISE global_process_expt;
    END IF;
    gv_pay_bumon_cd := fnd_profile.value(cv_pay_bumon_cd);
    IF (gv_pay_bumon_cd IS NULL) THEN
      lv_tkn_nm := cv_tkn_pay_bumon_cd_nm;
      RAISE global_process_expt;
    END IF;
-- 2009/10/02 Ver1.4 delete start by Yutaka.Kuboshima
--    gv_pay_bumon_nm := fnd_profile.value(cv_pay_bumon_nm);
--    IF (gv_pay_bumon_nm IS NULL) THEN
--      lv_tkn_nm := cv_tkn_pay_bumon_nm;
--      RAISE global_process_expt;
--    END IF;
-- 2009/10/02 Ver1.4 delete end by Yutaka.Kuboshima
    gv_pay_method_nm := fnd_profile.value(cv_pay_method_nm);
    IF (gv_pay_method_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_pay_method_nm;
      RAISE global_process_expt;
    END IF;
    gv_pay_bank := fnd_profile.value(cv_pay_bank);
    IF (gv_pay_bank IS NULL) THEN
      lv_tkn_nm := cv_tkn_pay_bank_nm;
      RAISE global_process_expt;
    END IF;
    gv_koguti_genkin_nm := fnd_profile.value(cv_koguti_genkin_nm);
    IF (gv_koguti_genkin_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_koguti_genkin_nm;
      RAISE global_process_expt;
    END IF;
-- 2009/10/02 Ver1.4 delete start by Yutaka.Kuboshima
--    gv_pay_type_nm := fnd_profile.value(cv_pay_type_nm);
--    IF (gv_pay_type_nm IS NULL) THEN
--      lv_tkn_nm := cv_tkn_pay_type_nm;
--      RAISE global_process_expt;
--    END IF;
-- 2009/10/02 Ver1.4 delete end by Yutaka.Kuboshima
    gv_terms_id := fnd_profile.value(cv_terms_id);
    IF (gv_terms_id IS NULL) THEN
      lv_tkn_nm := cv_tkn_terms_id_nm;
      RAISE global_process_expt;
    END IF;
-- Ver1.2  2009/04/21  Add  障害：T1_0438対応  銀行手数料負担者を追加「当方(I)」
    gv_s_bank_charge_new := fnd_profile.value(cv_bank_charge_bearer);
    IF (gv_s_bank_charge_new IS NULL) THEN
      lv_tkn_nm := cv_tkn_bank_charge;
      RAISE global_process_expt;
    END IF;
-- End Ver1.2
    gv_bank_number := fnd_profile.value(cv_bank_number);
    IF (gv_bank_number IS NULL) THEN
      lv_tkn_nm := cv_tkn_bank_number_nm;
      RAISE global_process_expt;
    END IF;
    gv_bank_num := fnd_profile.value(cv_bank_num);
    IF (gv_bank_num IS NULL) THEN
      lv_tkn_nm := cv_tkn_bank_num_nm;
      RAISE global_process_expt;
    END IF;
    gv_bank_nm := fnd_profile.value(cv_bank_nm);
    IF (gv_bank_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_bank_nm;
      RAISE global_process_expt;
    END IF;
    gv_shiten_nm := fnd_profile.value(cv_shiten_nm);
    IF (gv_shiten_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_shiten_nm;
      RAISE global_process_expt;
    END IF;
    gv_account_num := fnd_profile.value(cv_account_num);
    IF (gv_account_num IS NULL) THEN
      lv_tkn_nm := cv_tkn_account_num_nm;
      RAISE global_process_expt;
    END IF;
    gv_currency_cd := fnd_profile.value(cv_currency_cd);
    IF (gv_currency_cd IS NULL) THEN
      lv_tkn_nm := cv_tkn_currency_cd_nm;
      RAISE global_process_expt;
    END IF;
    gv_account_type := fnd_profile.value(cv_account_type);
    IF (gv_account_type IS NULL) THEN
      lv_tkn_nm := cv_tkn_account_type_nm;
      RAISE global_process_expt;
    END IF;
    gv_holder_nm := fnd_profile.value(cv_holder_nm);
    IF (gv_holder_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_holder_nm;
      RAISE global_process_expt;
    END IF;
    gv_holder_alt_nm := fnd_profile.value(cv_holder_alt_nm);
    IF (gv_holder_alt_nm IS NULL) THEN
      lv_tkn_nm := cv_tkn_holder_alt_nm;
      RAISE global_process_expt;
    END IF;
    gv_address_nm1 := fnd_profile.value(cv_address_nm1);
    IF (gv_address_nm1 IS NULL) THEN
      lv_tkn_nm := cv_tkn_address_nm1;
      RAISE global_process_expt;
    END IF;
    gv_address_nm2 := fnd_profile.value(cv_address_nm2);
    IF (gv_address_nm2 IS NULL) THEN
      lv_tkn_nm := cv_tkn_address_nm2;
      RAISE global_process_expt;
    END IF;
    gv_jyugyoin_kbn_s := fnd_profile.value(cv_jyugyoin_kbn_s);
    IF (gv_jyugyoin_kbn_s IS NULL) THEN
      lv_tkn_nm := cv_tkn_jyugoin_kbn_s_nm;
      RAISE global_process_expt;
    END IF;
    gv_jyugyoin_kbn_d := fnd_profile.value(cv_jyugyoin_kbn_d);
    IF (gv_jyugyoin_kbn_d IS NULL) THEN
      lv_tkn_nm := cv_tkn_jyugoin_kbn_d_nm;
      RAISE global_process_expt;
    END IF;
    --
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
    -- ダミー支払方法の取得
    gv_pay_method_cd := fnd_profile.value(cv_pay_method_cd);
    IF (gv_pay_method_cd IS NULL) THEN
      lv_tkn_nm := cv_tkn_pay_method_cd;
      RAISE global_process_expt;
    END IF;
    -- ダミー請求書税金コードの取得
    gv_site_vat_cd := fnd_profile.value(cv_site_vat_cd);
    IF (gv_site_vat_cd IS NULL) THEN
      lv_tkn_nm := cv_tkn_site_vat_cd;
      RAISE global_process_expt;
    END IF;
    -- 前払/仮払金勘定科目AFF1の取得
    g_aff_segments_tab( 1 ) := fnd_profile.value(cv_prepay_ccid_aff1);
    IF (g_aff_segments_tab( 1 ) IS NULL) THEN
      lv_tkn_nm := cv_tkn_ccid_aff1;
      RAISE global_process_expt;
    END IF;
    -- 前払/仮払金勘定科目AFF3の取得
    g_aff_segments_tab( 3 ) := fnd_profile.value(cv_prepay_ccid_aff3);
    IF (g_aff_segments_tab( 3 ) IS NULL) THEN
      lv_tkn_nm := cv_tkn_ccid_aff3;
      RAISE global_process_expt;
    END IF;
    -- 前払/仮払金勘定科目AFF4の取得
    g_aff_segments_tab( 4 ) := fnd_profile.value(cv_prepay_ccid_aff4);
    IF (g_aff_segments_tab( 4 ) IS NULL) THEN
      lv_tkn_nm := cv_tkn_ccid_aff4;
      RAISE global_process_expt;
    END IF;
    -- 前払/仮払金勘定科目AFF5の取得
    g_aff_segments_tab( 5 ) := fnd_profile.value(cv_prepay_ccid_aff5);
    IF (g_aff_segments_tab( 5 ) IS NULL) THEN
      lv_tkn_nm := cv_tkn_ccid_aff5;
      RAISE global_process_expt;
    END IF;
    -- 前払/仮払金勘定科目AFF6の取得
    g_aff_segments_tab( 6 ) := fnd_profile.value(cv_prepay_ccid_aff6);
    IF (g_aff_segments_tab( 6 ) IS NULL) THEN
      lv_tkn_nm := cv_tkn_ccid_aff6;
      RAISE global_process_expt;
    END IF;
    -- 前払/仮払金勘定科目AFF7の取得
    g_aff_segments_tab( 7 ) := fnd_profile.value(cv_prepay_ccid_aff7);
    IF (g_aff_segments_tab( 7 ) IS NULL) THEN
      lv_tkn_nm := cv_tkn_ccid_aff7;
      RAISE global_process_expt;
    END IF;
    -- 前払/仮払金勘定科目AFF8の取得
    g_aff_segments_tab( 8 ) := fnd_profile.value(cv_prepay_ccid_aff8);
    IF (g_aff_segments_tab( 8 ) IS NULL) THEN
      lv_tkn_nm := cv_tkn_ccid_aff8;
      RAISE global_process_expt;
    END IF;
    -- GL会計帳簿名の取得
    gv_bks_name := fnd_profile.value(cv_bks_name);
    IF (gv_bks_name IS NULL) THEN
      lv_tkn_nm := cv_tkn_bks_name;
      RAISE global_process_expt;
    END IF;
-- 2009/10/02 Ver1.4 add end by Yutaka.Kuboshima
    --
-- Ver1.2  2009/04/21  Del  障害：T1_0438対応  会計オプションから取得するよう変更（負債・前払金）
    -- ============================================================
    --  会計オプションの取得
    -- ============================================================
    SELECT   TO_CHAR( accts_pay_code_combination_id )   -- 負債勘定
-- 2009/10/02 Ver1.4 delete start by Yutaka.Kuboshima
--            ,TO_CHAR( prepay_code_combination_id )      -- 前払金
-- 2009/10/02 Ver1.4 delete end by Yutaka.Kuboshima
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
            ,non_recoverable_tax_flag                   -- 控除対象消費税使用可
            ,tax_rounding_rule                          -- 端数処理規則
-- 2009/10/02 Ver1.4 add end by Yutaka.Kuboshima
    INTO     gv_accts_pay_ccid
-- 2009/10/02 Ver1.4 delete start by Yutaka.Kuboshima
--            ,gv_prepay_ccid
-- 2009/10/02 Ver1.4 delete end by Yutaka.Kuboshima
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
            ,gv_non_recover_tax_flag
            ,gv_tax_rounding_rule
-- 2009/10/02 Ver1.4 add end by Yutaka.Kuboshima
    FROM     financials_system_parameters;    -- 会計オプション
-- End Ver1.2
    --
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
    -- ============================================================
    --  買掛/未払金オプションの取得
    -- ============================================================
    SELECT   auto_tax_calc_flag               -- 計算レベル
            ,auto_tax_calc_override           -- 計算レベル上書きの許可
    INTO     gv_auto_tax_calc_flag
            ,gv_auto_tax_calc_override
    FROM     ap_system_parameters;            -- 買掛/未払金オプション
    --
    -- ============================================================
    -- 勘定科目体系の取得
    -- ============================================================
    SELECT  gsob.chart_of_accounts_id    -- 勘定科目体系ＩＤ
           ,fifsv.id_flex_code           -- キーフレックスコード
    INTO    gn_chart_of_acct_id
           ,gv_id_flex_code
    FROM    fnd_id_flex_structures_vl    fifsv
           ,gl_sets_of_books             gsob
    WHERE   gsob.name            = gv_bks_name
    AND     fifsv.id_flex_num    = gsob.chart_of_accounts_id;
    --
-- 2009/10/02 Ver1.4 add end by Yutaka.Kuboshima
    -- ============================================================
    --  固定出力(I/Fファイル名部)
    -- ============================================================
-- 2009/07/17 delete start by Yutaka.Kuboshima
--    lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_ccp             -- 'XXCCP'
--                    ,iv_name         => cv_msg_05102               -- ファイル名出力メッセージ
--                    ,iv_token_name1  => cv_tkn_filename            -- トークン(FILE_NAME)
--                    ,iv_token_value1 => gv_filename                -- ファイル名
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => lv_errmsg
--    );
--    -- 空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
-- 2009/07/17 delete end by Yutaka.Kuboshima
----
    -- ============================================================
    --  プロファイル:所在地1、2の文字数チェック
    -- ============================================================
    IF (LENGTHB(gv_address_nm1) > cv_address_length) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00214             -- 文字数制限エラー
                      ,iv_token_name1  => cv_tkn_profile           -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_address_nm1       -- プロファイル名(所在地1)
                      ,iv_token_name2  => cv_tkn_length            -- トークン(NG_LENGTH)
                      ,iv_token_value2 => cv_address_length        -- 所在地1の最大文字数
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    IF (LENGTHB(gv_address_nm2) > cv_address_length) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00214             -- 文字数制限エラー
                      ,iv_token_name1  => cv_tkn_profile           -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_address_nm2       -- プロファイル名(所在地2)
                      ,iv_token_name2  => cv_tkn_length            -- トークン(NG_LENGTH)
                      ,iv_token_value2 => cv_address_length        -- 所在地2の最大文字数
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================================
    --  ファイルオープン
    -- =========================================================
-- 2009/07/17 delete start by Yutaka.Kuboshima
--    BEGIN
--      gf_file_hand := UTL_FILE.FOPEN(gv_filepath
--                                    ,gv_filename
--                                    ,cv_open_mode_w);
--    EXCEPTION
--      WHEN UTL_FILE.INVALID_PATH THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
--                        ,iv_name         => cv_msg_00003           -- ファイルパス不正エラー
--                       );
--        lv_errbuf := lv_errmsg;
--        RAISE global_api_expt;
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
-- 2009/07/17 delete end by Yutaka.Kuboshima
--
    -- =========================================================
    --  業務日付、取得次のシステム稼働日の取得
    -- =========================================================
    -- 業務日付の取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00018             -- 業務処理日付取得エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 取得次のシステム稼働日を取得
    gd_select_next_date := xxccp_common_pkg2.get_working_day(gd_process_date,1,gv_cal_code);
    IF (gd_select_next_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00036             -- 次のシステム稼働日取得エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2009/10/02 Ver1.4 add start by Yutaka.Kuboshima
    -- =========================================================
    --  前払/仮払金勘定科目CCID取得
    -- =========================================================
    -- 前払/仮払金勘定科目AFF2の設定
    -- 財務経理部の部門コードを設定
    g_aff_segments_tab( 2 ) := gv_pay_bumon_cd;
    -- CCID取得関数呼び出し
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name  => cv_short_name          -- アプリケーション短縮名(GL)
                ,key_flex_code           => gv_id_flex_code        -- キーフレックスコード
                ,structure_number        => gn_chart_of_acct_id    -- 勘定科目体系番号
                ,validation_date         => SYSDATE                -- 日付チェック
                ,n_segments              => 8                      -- セグメント数
                ,segments                => g_aff_segments_tab     -- セグメント値配列
                ,combination_id          => ln_ccid                -- CCID
              );
    IF (lb_ret) THEN
      -- 正常終了時
      gv_prepay_ccid := TO_CHAR(ln_ccid);
    ELSE
      -- 異常終了時
      lv_errmsg := fnd_flex_ext.get_message;
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- =========================================================
    --  仕入先従業員情報中間I/Fテーブルロック
    -- =========================================================
    BEGIN
      OPEN get_vendors_interface_cur;
      CLOSE get_vendors_interface_cur;
    EXCEPTION
      -- テーブルロックエラー
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        ,iv_name         => cv_msg_00008           -- ロック取得NGメッセージ
                        ,iv_token_name1  => cv_tkn_table           -- トークン(NG_TABLE)
                        ,iv_token_value1 => cv_tkn_table_nm        -- テーブル名(仕入先従業員情報中間I/Fテーブル)
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00002             -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile           -- トークン(NG_PROFILE)
                      ,iv_token_value1 => lv_tkn_nm                -- トークン名
                     );
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_u_people_data
   * Description      : 新規登録以外の社員データ取得プロシージャ(A-3)
   ***********************************************************************************/
  PROCEDURE get_u_people_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_u_people_data';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
   -- カーソルオープン
    OPEN get_u_people_data_cur;
--
    -- データの一括取得
    FETCH get_u_people_data_cur BULK COLLECT INTO gt_u_people_data;
--
    -- 新規登録以外の対象件数をセット
    gn_target_update_cnt := gt_u_people_data.COUNT;
--
    -- カーソルクローズ
    CLOSE get_u_people_data_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
--#####################################  固定部 END   ##########################################
--
  END get_u_people_data;
--
  /**********************************************************************************
   * Procedure Name   : update_output_csv
   * Description      : 中間I/Fテーブルデータ登録(更新)プロシージャ(A-7)
   ***********************************************************************************/
  PROCEDURE update_output_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_output_csv';     -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
-- 2009/07/17 Ver1.3 delete start by Yutaka.Kuboshima
--    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV区切り文字
-- 2009/07/17 Ver1.3 delete end by Yutaka.Kuboshima
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- 単語囲み文字
    cv_t                CONSTANT VARCHAR2(1)  := 'T';                -- 退職した社員
    cv_i                CONSTANT VARCHAR2(1)  := 'I';                -- 異動した社員
    cv_o                CONSTANT VARCHAR2(1)  := 'O';                -- 異動も退職もしなかった社員
-- 2010/04/12 Ver1.5 E_本稼動_02240 add start by Y.Kuboshima
    cv_s                CONSTANT VARCHAR2(1)  := 'S';                -- 再雇用社員
-- 2010/04/12 Ver1.5 E_本稼動_02240 add end by Y.Kuboshima
--
    -- *** ローカル変数 ***
    ln_loop_cnt         NUMBER;                   -- ループカウンタ
    lv_csv_text         VARCHAR2(32000);          -- 出力１行分文字列変数
    lv_old_pay_group    VARCHAR2(25);             -- 以前の支払グループコード
    lv_new_pay_group    VARCHAR2(50);             -- 現在の支払グループコード
    lv_ret_flg          VARCHAR2(1);              -- 現在の支払グループコード取得処理用フラグ
    lv_pay_flg          VARCHAR2(1);              -- 支払可能部門フラグ
    lv_kbn              VARCHAR2(1);              -- 処理区分(T:退職した社員/I:異動した社員/O:異動も退職もしなかった社員)
    ld_end_date_active  DATE;                     -- 無効日
    lv_employee_number  VARCHAR2(22);             -- 従業員番号重複チェック用
    ln_o_cnt            NUMBER;                   -- 異動も退職もしなかった社員の件数(対象件数に含まない)
-- 2009/07/17 Ver1.3 add start by Yutaka.Kuboshima
    l_vend_if_rec       xx03_vendors_interface%ROWTYPE; -- 仕入先従業員情報中間I/Fテーブルレコード型
-- 2009/07/17 Ver1.3 add end by Yutaka.Kuboshima
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 初期化
    ln_o_cnt := 0;
    --
    <<u_out_loop>>
    FOR ln_loop_cnt IN gt_u_people_data.FIRST..gt_u_people_data.LAST LOOP
-- Ver1.2  2009/04/21  Add  障害：T1_0388対応
      gn_s_vendor_site_id := gt_u_people_data(ln_loop_cnt).vendor_site_id;
-- End Ver1.2
      --========================================
      -- 従業員番号重複チェック(A-3-1)
      --========================================
      -- 従業員番号が重複している場合、警告メッセージを表示
      IF (lv_employee_number = gt_u_people_data(ln_loop_cnt).employee_number) THEN
        -- 警告フラグにオンをセット
        gv_warn_flg := '1';
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                  -- 'XXCMM'
                        ,iv_name         => cv_msg_00209                                    -- 従業員番号重複メッセージ
                        ,iv_token_name1  => cv_tkn_word                                     -- トークン(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                    -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                     -- トークン(NG_DATA)
                        ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number   -- NG_WORDのDATA
                                              || cv_tkn_word2
                                              || gt_u_people_data(ln_loop_cnt).per_information18
                                              || '　'
                                              || gt_u_people_data(ln_loop_cnt).per_information19
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
      --========================================
      -- 部門コードチェック(A-3-2)
      --========================================
      IF (gt_u_people_data(ln_loop_cnt).ass_attribute3 IS NULL) THEN
        -- 警告フラグにオンをセット
        gv_warn_flg := '1';
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                  -- 'XXCMM'
                        ,iv_name         => cv_msg_00208                                    -- 勤務地拠点コード(新)未入力エラー
                        ,iv_token_name1  => cv_tkn_word                                     -- トークン(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                    -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                     -- トークン(NG_DATA)
                        ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number   -- NG_WORDのDATA
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- スキップ件数をカウント
        gn_warn_cnt := gn_warn_cnt + 1;
      ELSE
        --========================================
        -- 以前の支払グループ取得(A-3-3)
        --========================================
        BEGIN
-- Ver1.2  2009/04/21  Mod  障害：T1_0388対応  営業ＯＵの「会社」のみ取得するよう修正
--          SELECT   pay_group_lookup_code,         -- 以前の支払グループ
--                   vendor_site_id                 -- 仕入先サイトID
--          INTO     lv_old_pay_group,
--                   gn_s_vendor_site_id
--          FROM     po_vendor_sites_all
--          WHERE    vendor_id = gt_u_people_data(ln_loop_cnt).vendor_id;
          --
          SELECT   pay_group_lookup_code         -- 以前の支払グループ
          INTO     lv_old_pay_group
          FROM     po_vendor_sites
          WHERE    vendor_site_id = gn_s_vendor_site_id;
-- End Ver1.2
          --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                            ,iv_name         => cv_msg_00211                                  -- 以前の支払グループ取得エラー
                            ,iv_token_name1  => cv_tkn_word                                   -- トークン(NG_WORD)
                            ,iv_token_value1 => cv_tkn_word1                                  -- NG_WORD
                            ,iv_token_name2  => cv_tkn_data                                   -- トークン(NG_DATA)
                            ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number -- NG_WORDのDATA
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        --========================================
        -- 現在の支払グループ取得(A-3-4)
        --========================================
        BEGIN
-- 2010/04/12 Ver1.5 E_本稼動_02240 add start by Y.Kuboshima
          -- 小口現金用の支払グループを生成します。
          lv_new_pay_group := gt_u_people_data(ln_loop_cnt).ass_attribute3 || '-' || gv_koguti_genkin_nm;
-- 2010/04/12 Ver1.5 E_本稼動_02240 add end by Y.Kuboshima
          SELECT   '1'
          INTO     lv_ret_flg
          FROM     fnd_lookup_values_vl
          WHERE    lookup_type = gv_group_type_nm
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify start by Y.Kuboshima
--          AND      attribute2 = gt_u_people_data(ln_loop_cnt).ass_attribute3
          AND      lookup_code = lv_new_pay_group
          AND      NVL(attribute3, cv_n_flag) = cv_n_flag
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify end by Y.Kuboshima
          AND      ROWNUM = 1;
          IF (gt_u_people_data(ln_loop_cnt).ass_attribute3 = gv_pay_bumon_cd) THEN
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--            lv_new_pay_group := gv_pay_bumon_nm || '-' || gv_pay_method_nm || '/' || gv_pay_bank|| '/' || gv_pay_type_nm;
            lv_new_pay_group := gv_pay_bumon_cd || '-' || gv_pay_method_nm || '-' || gv_pay_bank;
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
            -- 支払可能部門フラグになしをセット
            lv_pay_flg := 'N';
          ELSE
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--            lv_new_pay_group := gt_u_people_data(ln_loop_cnt).ass_attribute3 || '-' || gv_koguti_genkin_nm || '/' || gv_pay_type_nm;
            lv_new_pay_group := gt_u_people_data(ln_loop_cnt).ass_attribute3 || '-' || gv_koguti_genkin_nm;
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
            -- 支払可能部門フラグにありをセット
            lv_pay_flg := 'Y';
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--            lv_new_pay_group := gv_pay_bumon_nm || '-' || gv_pay_method_nm || '/' || gv_pay_bank|| '/' || gv_pay_type_nm;
            lv_new_pay_group := gv_pay_bumon_cd || '-' || gv_pay_method_nm || '-' || gv_pay_bank;
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
            -- 支払可能部門フラグになしをセット
            lv_pay_flg := 'N';
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        IF (LENGTHB(lv_new_pay_group) > cv_pay_group_length) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                          ,iv_name         => cv_msg_00215                                  -- 支払グループコード文字数制限エラー
                          ,iv_token_name1  => cv_tkn_length                                 -- トークン(NG_LENGTH)
                          ,iv_token_value1 => cv_pay_group_length                           -- 支払グループコードの最大文字数
                          ,iv_token_name2  => cv_tkn_word                                   -- トークン(NG_WORD)
                          ,iv_token_value2 => cv_tkn_word1                                  -- NG_WORD
                          ,iv_token_name3  => cv_tkn_data                                   -- トークン(NG_DATA)
                          ,iv_token_value3 => gt_u_people_data(ln_loop_cnt).employee_number -- NG_WORDのDATA
                                                || cv_tkn_word3
                                                || lv_new_pay_group
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --========================================
        -- 更新対象データチェック(A-3-5)
        --========================================
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify start by Y.Kuboshima
--        IF ((gd_process_date <= gt_u_people_data(ln_loop_cnt).actual_termination_date)
--          AND (gt_u_people_data(ln_loop_cnt).actual_termination_date < gd_select_next_date))
--        THEN
        IF (gt_u_people_data(ln_loop_cnt).actual_termination_date IS NOT NULL) THEN
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify end by Y.Kuboshima
          -- 退職した社員
          lv_kbn := cv_t;
        ELSIF ((lv_old_pay_group = lv_new_pay_group)
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--          OR (lv_pay_flg = 'N' AND SUBSTRB(lv_old_pay_group,1,INSTRB(lv_old_pay_group,'-')-1) = gv_pay_bumon_nm))
          -- 比較対象を本社総振込支払部門名称 -> 本社総振込支払部門コードに変更
          OR (lv_pay_flg = 'N' AND SUBSTRB(lv_old_pay_group,1,INSTRB(lv_old_pay_group,'-')-1) = gv_pay_bumon_cd))
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
-- 2010/04/12 Ver1.5 E_本稼動_02240 add start by Y.Kuboshima
          OR (gt_u_people_data(ln_loop_cnt).ass_attribute3 = gt_u_people_data(ln_loop_cnt).attribute5)
-- 2010/04/12 Ver1.5 E_本稼動_02240 add end by Y.Kuboshima
        THEN
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify start by Y.Kuboshima
--          -- 異動も退職もしなかった社員
--          lv_kbn := cv_o;
          IF (gt_u_people_data(ln_loop_cnt).end_date_active IS NOT NULL) THEN
            -- 再雇用社員
            lv_kbn := cv_s;
          ELSE
            -- 異動も退職もしなかった社員
            lv_kbn := cv_o;
          END IF;
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify end by Y.Kuboshima
        ELSE
          -- 異動した社員
          lv_kbn := cv_i;
        END IF;
        --
        IF (lv_kbn = cv_o) THEN
          -- 異動も退職もしなかった社員の件数をカウント
          ln_o_cnt := ln_o_cnt + 1;
        ELSE
          --========================================
          -- 仕入先マスタデータ取得(A-4)
          --========================================
          BEGIN
            SELECT   SUBSTRB(vendor_name,1,80),                     -- 仕入先仕入先名
                     segment1,                                      -- 仕入先仕入先番号
                     SUBSTRB(employee_id,1,22),                     -- 仕入先従業員ID
                     vendor_type_lookup_code,                       -- 仕入先仕入先タイプ
                     SUBSTRB(terms_id,1,22),                        -- 仕入先支払条件
                     pay_group_lookup_code,                         -- 仕入先支払グループコード
                     SUBSTRB(invoice_amount_limit,1,22),            -- 仕入先請求限度額
                     SUBSTRB(accts_pay_code_combination_id,1,22),   -- 仕入先負債勘定科目ID
                     SUBSTRB(prepay_code_combination_id,1,22),      -- 仕入先前払／仮払金勘定科目ID
                     end_date_active,                               -- 仕入先無効日
                     small_business_flag,                           -- 仕入先中小法人フラグ
                     receipt_required_flag,                         -- 仕入先入金確認フラグ
                     attribute_category,                            -- 仕入先予備カテゴリ
                     attribute1,                                    -- 仕入先予備1
                     attribute2,                                    -- 仕入先予備2
                     attribute3,                                    -- 仕入先予備3
                     attribute4,                                    -- 仕入先予備4
                     attribute5,                                    -- 仕入先予備5
                     attribute6,                                    -- 仕入先予備6
                     attribute7,                                    -- 仕入先予備7
                     attribute8,                                    -- 仕入先予備8
                     attribute9,                                    -- 仕入先予備9
                     attribute10,                                   -- 仕入先予備10
                     attribute11,                                   -- 仕入先予備11
                     attribute12,                                   -- 仕入先予備12
                     attribute13,                                   -- 仕入先予備13
                     attribute14,                                   -- 仕入先予備14
                     attribute15,                                   -- 仕入先予備15
                     allow_awt_flag,                                -- 仕入先源泉徴収税使用フラグ
                     vendor_name_alt,                               -- 仕入先仕入先カナ名称
                     ap_tax_rounding_rule,                          -- 仕入先請求税自動計算端数処理規
                     auto_tax_calc_flag,                            -- 仕入先請求税自動計算計算レベル
                     auto_tax_calc_override,                        -- 仕入先請求税自動計算上書きの許
                     bank_charge_bearer                             -- 仕入先銀行手数料負担者
            INTO     gv_v_vendor_name,
                     gv_v_segment1,
                     gn_v_employee_id,
                     gv_v_vendor_type,
                     gn_v_terms_id,
                     gv_v_pay_group,
                     gn_v_invoice_amount_limit,
                     gn_v_accts_pay_ccid,
                     gn_v_prepay_ccid,
                     ld_end_date_active,
                     gv_v_sb_flag,
                     gv_v_rr_flag,
                     gv_v_attribute_category,
                     gv_v_attribute1,
                     gv_v_attribute2,
                     gv_v_attribute3,
                     gv_v_attribute4,
                     gv_v_attribute5,
                     gv_v_attribute6,
                     gv_v_attribute7,
                     gv_v_attribute8,
                     gv_v_attribute9,
                     gv_v_attribute10,
                     gv_v_attribute11,
                     gv_v_attribute12,
                     gv_v_attribute13,
                     gv_v_attribute14,
                     gv_v_attribute15,
                     gv_v_allow_awt_flag,
                     gv_v_vendor_name_alt,
                     gv_v_ap_tax_rounding_rule,
                     gv_v_atc_flag,
                     gv_v_atc_override,
                     gv_v_bank_charge_bearer
            FROM     po_vendors
            WHERE    vendor_id = gt_u_people_data(ln_loop_cnt).vendor_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                              ,iv_name         => cv_msg_00212                                  -- 仕入先マスタデータ取得エラー
                              ,iv_token_name1  => cv_tkn_word                                   -- トークン(NG_WORD)
                              ,iv_token_value1 => cv_tkn_word1                                  -- NG_WORD
                              ,iv_token_name2  => cv_tkn_data                                   -- トークン(NG_DATA)
                              ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number -- NG_WORDのDATA
                             );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
          IF (lv_kbn = cv_i) THEN
            --========================================
            -- 仕入先サイトマスタデータ取得(A-5)
            --========================================
            BEGIN
              SELECT   vendor_site_code,                            -- 仕入先サイト仕入先サイト名
                       SUBSTRB(address_line1,1,35),                 -- 仕入先サイト所在地1
                       SUBSTRB(address_line2,1,35),                 -- 仕入先サイト所在地2
                       SUBSTRB(address_line3,1,35),                 -- 仕入先サイト所在地3
                       city,                                        -- 仕入先サイト住所・郡市区
                       SUBSTRB(state,1,25),                         -- 仕入先サイト住所・都道府県
                       zip,                                         -- 仕入先サイト住所・郵便番号
                       SUBSTRB(province,1,25),                      -- 仕入先サイト住所・州
                       country,                                     -- 仕入先サイト国
                       area_code,                                   -- 仕入先サイト市外局番
                       phone,                                       -- 仕入先サイト電話番号
                       fax,                                         -- 仕入先サイトFAX
                       fax_area_code,                               -- 仕入先サイトFAX市外局番
                       payment_method_lookup_code,                  -- 仕入先サイト支払方法
                       bank_account_name,                           -- 仕入先サイト口座名称
                       bank_account_num,                            -- 仕入先サイト口座番号
                       bank_num,                                    -- 仕入先サイト銀行コード
                       bank_account_type,                           -- 仕入先サイト預金種別
                       vat_code,                                    -- 仕入先サイト請求書税金コード
                       SUBSTRB(distribution_set_id,1,22),           -- 仕入先サイト配分セットID
                       SUBSTRB(accts_pay_code_combination_id,1,22), -- 仕入先サイト負債勘定科目ID
                       SUBSTRB(prepay_code_combination_id,1,22),    -- 仕入先サイト前払／仮払金勘定科
                       SUBSTRB(terms_id,1,22),                      -- 仕入先サイト支払条件
                       SUBSTRB(invoice_amount_limit,1,22),          -- 仕入先サイト請求限度額
                       attribute_category,                          -- 仕入先サイト予備カテゴリ
                       attribute1,                                  -- 仕入先サイト予備1
                       attribute2,                                  -- 仕入先サイト予備2
                       attribute3,                                  -- 仕入先サイト予備3
                       attribute4,                                  -- 仕入先サイト予備4
                       attribute5,                                  -- 仕入先サイト予備5
                       attribute6,                                  -- 仕入先サイト予備6
                       attribute7,                                  -- 仕入先サイト予備7
                       attribute8,                                  -- 仕入先サイト予備8
                       attribute9,                                  -- 仕入先サイト予備9
                       attribute10,                                 -- 仕入先サイト予備10
                       attribute11,                                 -- 仕入先サイト予備11
                       attribute12,                                 -- 仕入先サイト予備12
                       attribute13,                                 -- 仕入先サイト予備13
                       attribute14,                                 -- 仕入先サイト予備14
                       attribute15,                                 -- 仕入先サイト予備15
                       bank_number,                                 -- 仕入先サイト銀行支店コード
                       SUBSTRB(address_line4,1,35),                 -- 仕入先サイト所在地4
                       SUBSTRB(county,1,25),                        -- 仕入先サイト郡
                       allow_awt_flag,                              -- 仕入先サイト源泉徴収税使用フラ
                       awt_group_id,                                -- 仕入先サイト源泉徴収税グループ
                       vendor_site_code_alt,                        -- 仕入先サイト仕入先サイト名（カ
                       address_lines_alt,                           -- 仕入先サイト住所カナ
                       ap_tax_rounding_rule,                        -- 仕入先サイト請求税自動計算端数
                       auto_tax_calc_flag,                          -- 仕入先サイト請求税自動計算計算
                       auto_tax_calc_override,                      -- 仕入先サイト請求税自動計算上書
                       bank_charge_bearer,                          -- 仕入先サイト銀行手数料負担者
                       bank_branch_type,                            -- 仕入先サイト銀行支店タイプ
                       create_debit_memo_flag,                      -- 仕入先サイトRTS取引からデビッ
                       supplier_notif_method,                       -- 仕入先サイト仕入先通知方法
                       email_address,                               -- 仕入先サイトEメールアドレス
                       primary_pay_site_flag,                       -- 仕入先サイト主支払サイトフラグ
                       purchasing_site_flag                         -- 仕入先サイト購買フラグ
              INTO     gv_s_vendor_site_code,
                       gv_s_address_line1,
                       gv_s_address_line2,
                       gv_s_address_line3,
                       gv_s_city,
                       gv_s_state,
                       gv_s_zip,
                       gv_s_province,
                       gv_s_country,
                       gv_s_area_code,
                       gv_s_phone,
                       gv_s_fax,
                       gv_s_fax_area_code,
                       gv_s_payment_method,
                       gv_s_bank_account_name,
                       gv_s_bank_account_num,
                       gv_s_bank_num,
                       gv_s_bank_account_type,
                       gv_s_vat_code,
                       gn_s_distribution_set_id,
                       gn_s_accts_pay_ccid,
                       gn_s_prepay_ccid,
                       gn_s_terms_id,
                       gn_s_invoice_amount_limit,
                       gv_s_attribute_category,
                       gv_s_attribute1,
                       gv_s_attribute2,
                       gv_s_attribute3,
                       gv_s_attribute4,
                       gv_s_attribute5,
                       gv_s_attribute6,
                       gv_s_attribute7,
                       gv_s_attribute8,
                       gv_s_attribute9,
                       gv_s_attribute10,
                       gv_s_attribute11,
                       gv_s_attribute12,
                       gv_s_attribute13,
                       gv_s_attribute14,
                       gv_s_attribute15,
                       gv_s_bank_number,
                       gv_s_address_line4,
                       gv_s_county,
                       gv_s_allow_awt_flag,
                       gn_s_awt_group_id,
                       gv_s_vendor_site_code_alt,
                       gv_s_address_lines_alt,
                       gv_s_ap_tax_rounding_rule,
                       gv_s_atc_flag,
                       gv_s_atc_override,
                       gv_s_bank_charge_bearer,
                       gv_s_bank_branch_type,
                       gv_s_cdm_flag,
                       gv_s_sn_method,
                       gv_s_email_address,
                       gv_s_pps_flag,
                       gv_s_ps_flag
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--              FROM     po_vendor_sites_all
              FROM     po_vendor_sites
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
              WHERE    vendor_site_id = gn_s_vendor_site_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                                ,iv_name         => cv_msg_00213                                  -- 仕入先サイトマスタデータ取得エラー
                                ,iv_token_name1  => cv_tkn_word                                   -- トークン(NG_WORD)
                                ,iv_token_value1 => cv_tkn_word1                                  -- NG_WORD
                                ,iv_token_name2  => cv_tkn_data                                   -- トークン(NG_DATA)
                                ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number -- NG_WORDのDATA
                               );
                lv_errbuf := lv_errmsg;
                RAISE global_api_expt;
              WHEN OTHERS THEN
                RAISE global_api_others_expt;
            END;
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify start by Y.Kuboshima
--            -- 異動の場合、無効日に無効日をセット
--            gd_v_end_date_active := ld_end_date_active;
            -- 異動の場合、無効日にNULLをセット
            gd_v_end_date_active := NULL;
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify end by Y.Kuboshima
          ELSIF (lv_kbn = cv_t) THEN
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify start by Y.Kuboshima
--            -- 退職の場合、無効日に退職年月日の次の日をセット
--            gd_v_end_date_active := xxccp_common_pkg2.get_working_day(
--                                        gt_u_people_data(ln_loop_cnt).actual_termination_date
--                                       ,1
--                                       ,gv_cal_code
--                                      );
--            IF (gd_v_end_date_active IS NULL) THEN
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
--                              ,iv_name         => cv_msg_00036             -- 次のシステム稼働日取得エラー
--                             );
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--            END IF;
            -- 退職の場合、無効日に退職年月日の１ヶ月後をセット
            gd_v_end_date_active := ADD_MONTHS(gt_u_people_data(ln_loop_cnt).actual_termination_date, 1);
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify end by Y.Kuboshima
-- 2010/04/12 Ver1.5 E_本稼動_02240 add start by Y.Kuboshima
          ELSIF (lv_kbn = cv_s) THEN
            -- 再雇用の場合、無効日にNULLをセット
            gd_v_end_date_active := NULL;
-- 2010/04/12 Ver1.5 E_本稼動_02240 add end by Y.Kuboshima
          END IF;
          --
-- Ver1.2  2009/04/21  Add  障害：T1_0255対応  シーケンスを取得処理を追加
          SELECT   xxcso_xx03_vendors_if_s01.NEXTVAL
          INTO     gn_v_interface_id
          FROM     dual;
-- End Ver1.2
          --
          --========================================
          -- CSVファイル出力(A-6)
          --========================================
-- 2009/07/17 Ver1.3 modify start by Yutaka.Kuboshima
-- CSVファイル出力から中間テーブル直INSERTに変更
--          lv_csv_text := gn_v_interface_id || cv_delimiter                                  -- 仕入先インターフェースID(連番)
--            || cv_enclosed || cv_update_flg || cv_enclosed || cv_delimiter                  -- 追加更新フラグ
--            || SUBSTRB(gt_u_people_data(ln_loop_cnt).vendor_id,1,22) || cv_delimiter        -- 仕入先仕入先ID
--            || cv_enclosed || gv_v_vendor_name || cv_enclosed || cv_delimiter               -- 仕入先仕入先名
--            || cv_enclosed || gv_v_segment1 || cv_enclosed || cv_delimiter                  -- 仕入先仕入先番号
--            || gn_v_employee_id || cv_delimiter                                             -- 仕入先従業員ID
--            || cv_enclosed || gv_v_vendor_type || cv_enclosed || cv_delimiter               -- 仕入先仕入先タイプ
--            || gn_v_terms_id || cv_delimiter                                                -- 仕入先支払条件
--            || cv_enclosed || gv_v_pay_group || cv_enclosed || cv_delimiter                 -- 仕入先支払グループコード
--            || gn_v_invoice_amount_limit || cv_delimiter                                    -- 仕入先請求限度額
--            || gn_v_accts_pay_ccid || cv_delimiter                                          -- 仕入先負債勘定科目ID
--            || gn_v_prepay_ccid || cv_delimiter                                             -- 仕入先前払／仮払金勘定科目ID
--            || TO_CHAR(gd_v_end_date_active,'YYYYMMDD') || cv_delimiter                     -- 仕入先無効日
--            || cv_enclosed || gv_v_sb_flag || cv_enclosed || cv_delimiter                   -- 仕入先中小法人フラグ
--            || cv_enclosed || gv_v_rr_flag || cv_enclosed || cv_delimiter                   -- 仕入先入金確認フラグ
--            || cv_enclosed || gv_v_attribute_category || cv_enclosed || cv_delimiter        -- 仕入先予備カテゴリ
--            || cv_enclosed || gv_v_attribute1 || cv_enclosed || cv_delimiter                -- 仕入先予備1
--            || cv_enclosed || gv_v_attribute2 || cv_enclosed || cv_delimiter                -- 仕入先予備2
--            || cv_enclosed || gv_v_attribute3 || cv_enclosed || cv_delimiter                -- 仕入先予備3
--            || cv_enclosed || gv_v_attribute4 || cv_enclosed || cv_delimiter                -- 仕入先予備4
--            || cv_enclosed || gv_v_attribute5 || cv_enclosed || cv_delimiter                -- 仕入先予備5
--            || cv_enclosed || gv_v_attribute6 || cv_enclosed || cv_delimiter                -- 仕入先予備6
--            || cv_enclosed || gv_v_attribute7 || cv_enclosed || cv_delimiter                -- 仕入先予備7
--            || cv_enclosed || gv_v_attribute8 || cv_enclosed || cv_delimiter                -- 仕入先予備8
--            || cv_enclosed || gv_v_attribute9 || cv_enclosed || cv_delimiter                -- 仕入先予備9
--            || cv_enclosed || gv_v_attribute10 || cv_enclosed || cv_delimiter               -- 仕入先予備10
--            || cv_enclosed || gv_v_attribute11 || cv_enclosed || cv_delimiter               -- 仕入先予備11
--            || cv_enclosed || gv_v_attribute12 || cv_enclosed || cv_delimiter               -- 仕入先予備12
--            || cv_enclosed || gv_v_attribute13 || cv_enclosed || cv_delimiter               -- 仕入先予備13
--            || cv_enclosed || gv_v_attribute14 || cv_enclosed || cv_delimiter               -- 仕入先予備14
--            || cv_enclosed || gv_v_attribute15 || cv_enclosed || cv_delimiter               -- 仕入先予備15
--            || cv_enclosed || gv_v_allow_awt_flag || cv_enclosed || cv_delimiter            -- 仕入先源泉徴収税使用フラグ
--            || cv_enclosed || gv_v_vendor_name_alt || cv_enclosed || cv_delimiter           -- 仕入先仕入先カナ名称
--            || cv_enclosed || gv_v_ap_tax_rounding_rule || cv_enclosed || cv_delimiter      -- 仕入先請求税自動計算端数処理規
--            || cv_enclosed || gv_v_atc_flag || cv_enclosed || cv_delimiter                  -- 仕入先請求税自動計算計算レベル
--            || cv_enclosed || gv_v_atc_override || cv_enclosed || cv_delimiter              -- 仕入先請求税自動計算上書きの許
--            || cv_enclosed || gv_v_bank_charge_bearer || cv_enclosed || cv_delimiter        -- 仕入先銀行手数料負担者
--          ;
--          IF (lv_kbn = cv_i) THEN
--            -- 異動の場合、仕入先サイトマスタデータをセット
--            lv_csv_text := lv_csv_text || SUBSTRB(gn_s_vendor_site_id,1,22) || cv_delimiter -- 仕入先サイト仕入先サイトID
--              || cv_enclosed || gv_s_vendor_site_code || cv_enclosed || cv_delimiter        -- 仕入先サイト仕入先サイト名
--              || cv_enclosed || gv_s_address_line1 || cv_enclosed || cv_delimiter           -- 仕入先サイト所在地1
--              || cv_enclosed || gv_s_address_line2 || cv_enclosed || cv_delimiter           -- 仕入先サイト所在地2
--              || cv_enclosed || gv_s_address_line3 || cv_enclosed || cv_delimiter           -- 仕入先サイト所在地3
--              || cv_enclosed || gv_s_city || cv_enclosed || cv_delimiter                    -- 仕入先サイト住所・郡市区
--              || cv_enclosed || gv_s_state || cv_enclosed || cv_delimiter                   -- 仕入先サイト住所・都道府県
--              || cv_enclosed || gv_s_zip || cv_enclosed || cv_delimiter                     -- 仕入先サイト住所・郵便番号
--              || cv_enclosed || gv_s_province || cv_enclosed || cv_delimiter                -- 仕入先サイト住所・州
--              || cv_enclosed || gv_s_country || cv_enclosed || cv_delimiter                 -- 仕入先サイト国
--              || cv_enclosed || gv_s_area_code || cv_enclosed || cv_delimiter               -- 仕入先サイト市外局番
--              || cv_enclosed || gv_s_phone || cv_enclosed || cv_delimiter                   -- 仕入先サイト電話番号
--              || cv_enclosed || gv_s_fax || cv_enclosed || cv_delimiter                     -- 仕入先サイトFAX
--              || cv_enclosed || gv_s_fax_area_code || cv_enclosed || cv_delimiter           -- 仕入先サイトFAX市外局番
--              || cv_enclosed || gv_s_payment_method || cv_enclosed || cv_delimiter          -- 仕入先サイト支払方法
--              || cv_enclosed || gv_s_bank_account_name || cv_enclosed || cv_delimiter       -- 仕入先サイト口座名称
--              || cv_enclosed || gv_s_bank_account_num || cv_enclosed || cv_delimiter        -- 仕入先サイト口座番号
--              || cv_enclosed || gv_s_bank_num || cv_enclosed || cv_delimiter                -- 仕入先サイト銀行コード
--              || cv_enclosed || gv_s_bank_account_type || cv_enclosed || cv_delimiter       -- 仕入先サイト預金種別
--              || cv_enclosed || gv_s_vat_code || cv_enclosed || cv_delimiter                -- 仕入先サイト請求書税金コード
--              || gn_s_distribution_set_id || cv_delimiter                                   -- 仕入先サイト配分セットID
--              || gn_s_accts_pay_ccid || cv_delimiter                                        -- 仕入先サイト負債勘定科目ID
--              || gn_s_prepay_ccid || cv_delimiter                                           -- 仕入先サイト前払／仮払金勘定科
--              || cv_enclosed || lv_new_pay_group || cv_enclosed || cv_delimiter             -- 仕入先サイト支払グループコード
--              || gn_s_terms_id || cv_delimiter                                              -- 仕入先サイト支払条件
--              || gn_s_invoice_amount_limit || cv_delimiter                                  -- 仕入先サイト請求限度額
--              || cv_enclosed || gv_s_attribute_category || cv_enclosed || cv_delimiter      -- 仕入先サイト予備カテゴリ
--              || cv_enclosed || gv_s_attribute1 || cv_enclosed || cv_delimiter              -- 仕入先サイト予備1
--              || cv_enclosed || gv_s_attribute2 || cv_enclosed || cv_delimiter              -- 仕入先サイト予備2
--              || cv_enclosed || gv_s_attribute3 || cv_enclosed || cv_delimiter              -- 仕入先サイト予備3
--              || cv_enclosed || gv_s_attribute4 || cv_enclosed || cv_delimiter              -- 仕入先サイト予備4
--              || cv_enclosed || gt_u_people_data(ln_loop_cnt).ass_attribute3                -- 仕入先サイト予備5
--              || cv_enclosed || cv_delimiter
--              || cv_enclosed || gv_s_attribute6 || cv_enclosed || cv_delimiter              -- 仕入先サイト予備6
--              || cv_enclosed || gv_s_attribute7 || cv_enclosed || cv_delimiter              -- 仕入先サイト予備7
--              || cv_enclosed || gv_s_attribute8 || cv_enclosed || cv_delimiter              -- 仕入先サイト予備8
--              || cv_enclosed || gv_s_attribute9 || cv_enclosed || cv_delimiter              -- 仕入先サイト予備9
--              || cv_enclosed || gv_s_attribute10 || cv_enclosed || cv_delimiter             -- 仕入先サイト予備10
--              || cv_enclosed || gv_s_attribute11 || cv_enclosed || cv_delimiter             -- 仕入先サイト予備11
--              || cv_enclosed || gv_s_attribute12 || cv_enclosed || cv_delimiter             -- 仕入先サイト予備12
--              || cv_enclosed || gv_s_attribute13 || cv_enclosed || cv_delimiter             -- 仕入先サイト予備13
--              || cv_enclosed || gv_s_attribute14 || cv_enclosed || cv_delimiter             -- 仕入先サイト予備14
--              || cv_enclosed || gv_s_attribute15 || cv_enclosed || cv_delimiter             -- 仕入先サイト予備15
--              || cv_enclosed || gv_s_bank_number || cv_enclosed || cv_delimiter             -- 仕入先サイト銀行支店コード
--              || cv_enclosed || gv_s_address_line4 || cv_enclosed || cv_delimiter           -- 仕入先サイト所在地4
--              || cv_enclosed || gv_s_county || cv_enclosed || cv_delimiter                  -- 仕入先サイト郡
--              || cv_enclosed || gv_s_allow_awt_flag || cv_enclosed || cv_delimiter          -- 仕入先サイト源泉徴収税使用フラ
--              || gn_s_awt_group_id || cv_delimiter                                          -- 仕入先サイト源泉徴収税グループ
--              || cv_enclosed || gv_s_vendor_site_code_alt || cv_enclosed || cv_delimiter    -- 仕入先サイト仕入先サイト名（カ
--              || cv_enclosed || gv_s_address_lines_alt || cv_enclosed || cv_delimiter       -- 仕入先サイト住所カナ
--              || cv_enclosed || gv_s_ap_tax_rounding_rule || cv_enclosed || cv_delimiter    -- 仕入先サイト請求税自動計算端数
--              || cv_enclosed || gv_s_atc_flag || cv_enclosed || cv_delimiter                -- 仕入先サイト請求税自動計算計算
--              || cv_enclosed || gv_s_atc_override || cv_enclosed || cv_delimiter            -- 仕入先サイト請求税自動計算上書
--              || cv_enclosed || gv_s_bank_charge_bearer || cv_enclosed || cv_delimiter      -- 仕入先サイト銀行手数料負担者
--              || cv_enclosed || gv_s_bank_branch_type || cv_enclosed || cv_delimiter        -- 仕入先サイト銀行支店タイプ
--              || cv_enclosed || gv_s_cdm_flag || cv_enclosed || cv_delimiter                -- 仕入先サイトRTS取引からデビッ
--              || cv_enclosed || gv_s_sn_method || cv_enclosed || cv_delimiter               -- 仕入先サイト仕入先通知方法
--              || cv_enclosed || gv_s_email_address || cv_enclosed || cv_delimiter           -- 仕入先サイトEメールアドレス
--              || cv_enclosed || gv_s_pps_flag || cv_enclosed || cv_delimiter                -- 仕入先サイト主支払サイトフラグ
--              || cv_enclosed || gv_s_ps_flag || cv_enclosed || cv_delimiter                 -- 仕入先サイト購買フラグ
--              || cv_enclosed || gv_bank_number || cv_enclosed || cv_delimiter               -- 銀行口座銀行支店コード
--              || cv_enclosed || gv_bank_num || cv_enclosed || cv_delimiter                  -- 銀行口座銀行コード
--              || cv_enclosed || gv_bank_nm || '/' || gv_shiten_nm                           -- 銀行口座口座名称
--              || cv_enclosed || cv_delimiter
--              || cv_enclosed || gv_account_num || cv_enclosed || cv_delimiter               -- 銀行口座口座番号
--              || cv_enclosed || gv_currency_cd || cv_enclosed || cv_delimiter               -- 銀行口座通貨コード
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座摘要
--              || NULL || cv_delimiter                                                       -- 銀行口座現預金勘定科目ID
--              || cv_enclosed || gv_account_type || cv_enclosed || cv_delimiter              -- 銀行口座預金種別
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備カテゴリ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備1
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備2
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備3
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備4
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備5
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備6
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備7
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備8
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備9
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備10
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備11
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備12
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備13
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備14
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備15
--              || NULL || cv_delimiter                                                       -- 銀行口座資金決済勘定科目ID
--              || NULL || cv_delimiter                                                       -- 銀行口座銀行手数料勘定科目ID
--              || NULL || cv_delimiter                                                       -- 銀行口座銀行エラー勘定科目ID
--              || cv_enclosed || gv_holder_nm || cv_enclosed || cv_delimiter                 -- 銀行口座口座名義人名
--              || cv_enclosed || gv_holder_alt_nm || cv_enclosed || cv_delimiter             -- 銀行口座口座名義人名(カナ)
--              || TO_CHAR(gd_process_date,'YYYYMMDD') || cv_delimiter                        -- 銀行口座割当開始日
--              || NULL || cv_delimiter                                                       -- 銀行口座割当終了日
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備カテゴリ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備1
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備2
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備3
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備4
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備5
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備6
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備7
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備8
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備9
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備10
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備11
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備12
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備13
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備14
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備15
--              || cv_enclosed || cv_status_flg || cv_enclosed                                -- ステータスフラグ
--            ;
--          ELSIF (lv_kbn = cv_t) THEN
--            -- 退職の場合、NULLをセット
--            lv_csv_text := lv_csv_text || NULL || cv_delimiter                              -- 仕入先サイト仕入先サイトID
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト仕入先サイト名
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト所在地1
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト所在地2
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト所在地3
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト住所・郡市区
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト住所・都道府県
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト住所・郵便番号
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト住所・州
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト国
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト市外局番
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト電話番号
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイトFAX
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイトFAX市外局番
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト支払方法
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト口座名称
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト口座番号
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト銀行コード
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト預金種別
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト請求書税金コード
--              || NULL || cv_delimiter                                                       -- 仕入先サイト配分セットID
--              || NULL || cv_delimiter                                                       -- 仕入先サイト負債勘定科目ID
--              || NULL || cv_delimiter                                                       -- 仕入先サイト前払／仮払金勘定科
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト支払グループコード
--              || NULL || cv_delimiter                                                       -- 仕入先サイト支払条件
--              || NULL || cv_delimiter                                                       -- 仕入先サイト請求限度額
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備カテゴリ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備1
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備2
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備3
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備4
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備5
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備6
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備7
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備8
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備9
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備10
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備11
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備12
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備13
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備14
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト予備15
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト銀行支店コード
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト所在地4
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト郡
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト源泉徴収税使用フラ
--              || NULL || cv_delimiter                                                       -- 仕入先サイト源泉徴収税グループ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト仕入先サイト名（カ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト住所カナ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト請求税自動計算端数
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト請求税自動計算計算
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト請求税自動計算上書
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト銀行手数料負担者
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト銀行支店タイプ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイトRTS取引からデビッ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト仕入先通知方法
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイトEメールアドレス
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト主支払サイトフラグ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 仕入先サイト購買フラグ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座銀行支店コード
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座銀行コード
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座口座名称
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座口座番号
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座通貨コード
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座摘要
--              || NULL || cv_delimiter                                                       -- 銀行口座現預金勘定科目ID
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座預金種別
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備カテゴリ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備1
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備2
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備3
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備4
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備5
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備6
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備7
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備8
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備9
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備10
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備11
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備12
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備13
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備14
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座予備15
--              || NULL || cv_delimiter                                                       -- 銀行口座資金決済勘定科目ID
--              || NULL || cv_delimiter                                                       -- 銀行口座銀行手数料勘定科目ID
--              || NULL || cv_delimiter                                                       -- 銀行口座銀行エラー勘定科目ID
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座口座名義人名
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座口座名義人名(カナ)
--              || NULL || cv_delimiter                                                       -- 銀行口座割当開始日
--              || NULL || cv_delimiter                                                       -- 銀行口座割当終了日
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備カテゴリ
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備1
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備2
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備3
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備4
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備5
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備6
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備7
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備8
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備9
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備10
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備11
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備12
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備13
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備14
--              || cv_enclosed || NULL || cv_enclosed || cv_delimiter                         -- 銀行口座割当予備15
--              || cv_enclosed || cv_status_flg || cv_enclosed                                -- ステータスフラグ
--            ;
--          END IF;
--          BEGIN
--            -- ファイル書き込み
--            UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
--          EXCEPTION
--            -- ファイルアクセス権限エラー
--            WHEN UTL_FILE.INVALID_OPERATION THEN
--              lv_errmsg := xxcmn_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
--                              ,iv_name         => cv_msg_00007                                   -- ファイルアクセス権限エラー
--                             );
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--            --
--            -- CSVデータ出力エラー
--            WHEN UTL_FILE.WRITE_ERROR THEN
--              lv_errmsg := xxcmn_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
--                              ,iv_name         => cv_msg_00009                                   -- CSVデータ出力エラー
--                              ,iv_token_name1  => cv_tkn_word                                    -- トークン(NG_WORD)
--                              ,iv_token_value1 => cv_tkn_word1                                   -- NG_WORD
--                              ,iv_token_name2  => cv_tkn_data                                    -- トークン(NG_DATA)
--                              ,iv_token_value2 => gt_u_people_data(ln_loop_cnt).employee_number  -- NG_WORDのDATA
--                             );
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--            WHEN OTHERS THEN
--              RAISE global_api_others_expt;
--          END;
          -----------------
          -- 値設定
          -----------------
          l_vend_if_rec.vendors_interface_id        := gn_v_interface_id;                                     -- 仕入先インターフェースID(連番)
          l_vend_if_rec.insert_update_flag          := cv_update_flg;                                         -- 追加更新フラグ
          l_vend_if_rec.vndr_vendor_id              := SUBSTRB(gt_u_people_data(ln_loop_cnt).vendor_id,1,22); -- 仕入先仕入先ID
          l_vend_if_rec.vndr_vendor_name            := gv_v_vendor_name;                                      -- 仕入先仕入先名
          l_vend_if_rec.vndr_segment1               := gv_v_segment1;                                         -- 仕入先仕入先番号
          l_vend_if_rec.vndr_employee_id            := gn_v_employee_id;                                      -- 仕入先従業員ID
          l_vend_if_rec.vndr_vendor_type_lkup_code  := gv_v_vendor_type;                                      -- 仕入先仕入先タイプ
          l_vend_if_rec.vndr_terms_id               := gn_v_terms_id;                                         -- 仕入先支払条件
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--          l_vend_if_rec.vndr_pay_group_lkup_code    := gv_v_pay_group;                                        -- 仕入先支払グループコード
          -- 仕入先サイト支払条件と同値をセット
          l_vend_if_rec.vndr_pay_group_lkup_code    := lv_new_pay_group;                                      -- 仕入先支払グループコード
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
          l_vend_if_rec.vndr_invoice_amount_limit   := gn_v_invoice_amount_limit;                             -- 仕入先請求限度額
          l_vend_if_rec.vndr_accts_pay_ccid         := gn_v_accts_pay_ccid;                                   -- 仕入先負債勘定科目ID
          l_vend_if_rec.vndr_prepay_ccid            := gn_v_prepay_ccid;                                      -- 仕入先前払／仮払金勘定科目ID
          l_vend_if_rec.vndr_end_date_active        := gd_v_end_date_active;                                  -- 仕入先無効日
          l_vend_if_rec.vndr_small_business_flag    := gv_v_sb_flag;                                          -- 仕入先中小法人フラグ
          l_vend_if_rec.vndr_receipt_required_flag  := gv_v_rr_flag;                                          -- 仕入先入金確認フラグ
          l_vend_if_rec.vndr_attribute_category     := gv_v_attribute_category;                               -- 仕入先予備カテゴリ
          l_vend_if_rec.vndr_attribute1             := gv_v_attribute1;                                       -- 仕入先予備1
          l_vend_if_rec.vndr_attribute2             := gv_v_attribute2;                                       -- 仕入先予備2
          l_vend_if_rec.vndr_attribute3             := gv_v_attribute3;                                       -- 仕入先予備3
          l_vend_if_rec.vndr_attribute4             := gv_v_attribute4;                                       -- 仕入先予備4
          l_vend_if_rec.vndr_attribute5             := gv_v_attribute5;                                       -- 仕入先予備5
          l_vend_if_rec.vndr_attribute6             := gv_v_attribute6;                                       -- 仕入先予備6
          l_vend_if_rec.vndr_attribute7             := gv_v_attribute7;                                       -- 仕入先予備7
          l_vend_if_rec.vndr_attribute8             := gv_v_attribute8;                                       -- 仕入先予備8
          l_vend_if_rec.vndr_attribute9             := gv_v_attribute9;                                       -- 仕入先予備9
          l_vend_if_rec.vndr_attribute10            := gv_v_attribute10;                                      -- 仕入先予備10
          l_vend_if_rec.vndr_attribute11            := gv_v_attribute11;                                      -- 仕入先予備11
          l_vend_if_rec.vndr_attribute12            := gv_v_attribute12;                                      -- 仕入先予備12
          l_vend_if_rec.vndr_attribute13            := gv_v_attribute13;                                      -- 仕入先予備13
          l_vend_if_rec.vndr_attribute14            := gv_v_attribute14;                                      -- 仕入先予備14
          l_vend_if_rec.vndr_attribute15            := gv_v_attribute15;                                      -- 仕入先予備15
          l_vend_if_rec.vndr_allow_awt_flag         := gv_v_allow_awt_flag;                                   -- 仕入先源泉徴収税使用フラグ
          l_vend_if_rec.vndr_vendor_name_alt        := gv_v_vendor_name_alt;                                  -- 仕入先仕入先カナ名称
          l_vend_if_rec.vndr_ap_tax_rounding_rule   := gv_v_ap_tax_rounding_rule;                             -- 仕入先請求税自動計算端数処理規
          l_vend_if_rec.vndr_auto_tax_calc_flag     := gv_v_atc_flag;                                         -- 仕入先請求税自動計算計算レベル
          l_vend_if_rec.vndr_auto_tax_calc_override := gv_v_atc_override;                                     -- 仕入先請求税自動計算上書きの許
          l_vend_if_rec.vndr_bank_charge_bearer     := gv_v_bank_charge_bearer;                               -- 仕入先銀行手数料負担者
          -- 異動の場合
          IF (lv_kbn = cv_i) THEN
            l_vend_if_rec.site_vendor_site_id           := SUBSTRB(gn_s_vendor_site_id,1,22);                     -- 仕入先サイト仕入先サイトID
            l_vend_if_rec.site_vendor_site_code         := gv_s_vendor_site_code;                                 -- 仕入先サイト仕入先サイト名
            l_vend_if_rec.site_address_line1            := gv_s_address_line1;                                    -- 仕入先サイト所在地1
            l_vend_if_rec.site_address_line2            := gv_s_address_line2;                                    -- 仕入先サイト所在地2
            l_vend_if_rec.site_address_line3            := gv_s_address_line3;                                    -- 仕入先サイト所在地3
            l_vend_if_rec.site_city                     := gv_s_city;                                             -- 仕入先サイト住所・郡市区
            l_vend_if_rec.site_state                    := gv_s_state;                                            -- 仕入先サイト住所・都道府県
            l_vend_if_rec.site_zip                      := gv_s_zip;                                              -- 仕入先サイト住所・郵便番号
            l_vend_if_rec.site_province                 := gv_s_province;                                         -- 仕入先サイト住所・州
            l_vend_if_rec.site_country                  := gv_s_country;                                          -- 仕入先サイト国
            l_vend_if_rec.site_area_code                := gv_s_area_code;                                        -- 仕入先サイト市外局番
            l_vend_if_rec.site_phone                    := gv_s_phone;                                            -- 仕入先サイト電話番号
            l_vend_if_rec.site_fax                      := gv_s_fax;                                              -- 仕入先サイトFAX
            l_vend_if_rec.site_fax_area_code            := gv_s_fax_area_code;                                    -- 仕入先サイトFAX市外局番
            l_vend_if_rec.site_payment_method_lkup_code := gv_s_payment_method;                                   -- 仕入先サイト支払方法
            l_vend_if_rec.site_bank_account_name        := gv_s_bank_account_name;                                -- 仕入先サイト口座名称
            l_vend_if_rec.site_bank_account_num         := gv_s_bank_account_num;                                 -- 仕入先サイト口座番号
            l_vend_if_rec.site_bank_num                 := gv_s_bank_num;                                         -- 仕入先サイト銀行コード
            l_vend_if_rec.site_bank_account_type        := gv_s_bank_account_type;                                -- 仕入先サイト預金種別
            l_vend_if_rec.site_vat_code                 := gv_s_vat_code;                                         -- 仕入先サイト請求書税金コード
            l_vend_if_rec.site_distribution_set_id      := gn_s_distribution_set_id;                              -- 仕入先サイト配分セットID
            l_vend_if_rec.site_accts_pay_ccid           := gn_s_accts_pay_ccid;                                   -- 仕入先サイト負債勘定科目ID
            l_vend_if_rec.site_prepay_ccid              := gn_s_prepay_ccid;                                      -- 仕入先サイト前払／仮払金勘定科
            l_vend_if_rec.site_pay_group_lkup_code      := lv_new_pay_group;                                      -- 仕入先サイト支払グループコード
            l_vend_if_rec.site_terms_id                 := gn_s_terms_id;                                         -- 仕入先サイト支払条件
            l_vend_if_rec.site_invoice_amount_limit     := gn_s_invoice_amount_limit;                             -- 仕入先サイト請求限度額
            l_vend_if_rec.site_attribute_category       := gv_s_attribute_category;                               -- 仕入先サイト予備カテゴリ
            l_vend_if_rec.site_attribute1               := gv_s_attribute1;                                       -- 仕入先サイト予備1
            l_vend_if_rec.site_attribute2               := gv_s_attribute2;                                       -- 仕入先サイト予備2
            l_vend_if_rec.site_attribute3               := gv_s_attribute3;                                       -- 仕入先サイト予備3
            l_vend_if_rec.site_attribute4               := gv_s_attribute4;                                       -- 仕入先サイト予備4
            l_vend_if_rec.site_attribute5               := gt_u_people_data(ln_loop_cnt).ass_attribute3;          -- 仕入先サイト予備5
            l_vend_if_rec.site_attribute6               := gv_s_attribute6;                                       -- 仕入先サイト予備6
            l_vend_if_rec.site_attribute7               := gv_s_attribute7;                                       -- 仕入先サイト予備7
            l_vend_if_rec.site_attribute8               := gv_s_attribute8;                                       -- 仕入先サイト予備8
            l_vend_if_rec.site_attribute9               := gv_s_attribute9;                                       -- 仕入先サイト予備9
            l_vend_if_rec.site_attribute10              := gv_s_attribute10;                                      -- 仕入先サイト予備10
            l_vend_if_rec.site_attribute11              := gv_s_attribute11;                                      -- 仕入先サイト予備11
            l_vend_if_rec.site_attribute12              := gv_s_attribute12;                                      -- 仕入先サイト予備12
            l_vend_if_rec.site_attribute13              := gv_s_attribute13;                                      -- 仕入先サイト予備13
            l_vend_if_rec.site_attribute14              := gv_s_attribute14;                                      -- 仕入先サイト予備14
            l_vend_if_rec.site_attribute15              := gv_s_attribute15;                                      -- 仕入先サイト予備15
            l_vend_if_rec.site_bank_number              := gv_s_bank_number;                                      -- 仕入先サイト銀行支店コード
            l_vend_if_rec.site_address_line4            := gv_s_address_line4;                                    -- 仕入先サイト所在地4
            l_vend_if_rec.site_county                   := gv_s_county;                                           -- 仕入先サイト郡
            l_vend_if_rec.site_allow_awt_flag           := gv_s_allow_awt_flag;                                   -- 仕入先サイト源泉徴収税使用フラ
            l_vend_if_rec.site_awt_group_id             := gn_s_awt_group_id;                                     -- 仕入先サイト源泉徴収税グループ
            l_vend_if_rec.site_vendor_site_code_alt     := gv_s_vendor_site_code_alt;                             -- 仕入先サイト仕入先サイト名（カ
            l_vend_if_rec.site_address_lines_alt        := gv_s_address_lines_alt;                                -- 仕入先サイト住所カナ
            l_vend_if_rec.site_ap_tax_rounding_rule     := gv_s_ap_tax_rounding_rule;                             -- 仕入先サイト請求税自動計算端数
            l_vend_if_rec.site_auto_tax_calc_flag       := gv_s_atc_flag;                                         -- 仕入先サイト請求税自動計算計算
            l_vend_if_rec.site_auto_tax_calc_override   := gv_s_atc_override;                                     -- 仕入先サイト請求税自動計算上書
            l_vend_if_rec.site_bank_charge_bearer       := gv_s_bank_charge_bearer;                               -- 仕入先サイト銀行手数料負担者
            l_vend_if_rec.site_bank_branch_type         := gv_s_bank_branch_type;                                 -- 仕入先サイト銀行支店タイプ
            l_vend_if_rec.site_create_debit_memo_flag   := gv_s_cdm_flag;                                         -- 仕入先サイトRTS取引からデビッ
            l_vend_if_rec.site_supplier_notif_method    := gv_s_sn_method;                                        -- 仕入先サイト仕入先通知方法
            l_vend_if_rec.site_email_address            := gv_s_email_address;                                    -- 仕入先サイトEメールアドレス
            l_vend_if_rec.site_primary_pay_site_flag    := gv_s_pps_flag;                                         -- 仕入先サイト主支払サイトフラグ
            l_vend_if_rec.site_purchasing_site_flag     := gv_s_ps_flag;                                          -- 仕入先サイト購買フラグ
            l_vend_if_rec.acnt_bank_number              := gv_bank_number;                                        -- 銀行口座銀行支店コード
            l_vend_if_rec.acnt_bank_num                 := gv_bank_num;                                           -- 銀行口座銀行コード
            l_vend_if_rec.acnt_bank_account_name        := gv_bank_nm || '/' || gv_shiten_nm;                     -- 銀行口座口座名称
            l_vend_if_rec.acnt_bank_account_num         := gv_account_num;                                        -- 銀行口座口座番号
            l_vend_if_rec.acnt_currency_code            := gv_currency_cd;                                        -- 銀行口座通貨コード
            l_vend_if_rec.acnt_description              := NULL;                                                  -- 銀行口座摘要
            l_vend_if_rec.acnt_asset_id                 := NULL;                                                  -- 銀行口座現預金勘定科目ID
            l_vend_if_rec.acnt_bank_account_type        := gv_account_type;                                       -- 銀行口座預金種別
            l_vend_if_rec.acnt_attribute_category       := NULL;                                                  -- 銀行口座予備カテゴリ
            l_vend_if_rec.acnt_attribute1               := NULL;                                                  -- 銀行口座予備1
            l_vend_if_rec.acnt_attribute2               := NULL;                                                  -- 銀行口座予備2
            l_vend_if_rec.acnt_attribute3               := NULL;                                                  -- 銀行口座予備3
            l_vend_if_rec.acnt_attribute4               := NULL;                                                  -- 銀行口座予備4
            l_vend_if_rec.acnt_attribute5               := NULL;                                                  -- 銀行口座予備5
            l_vend_if_rec.acnt_attribute6               := NULL;                                                  -- 銀行口座予備6
            l_vend_if_rec.acnt_attribute7               := NULL;                                                  -- 銀行口座予備7
            l_vend_if_rec.acnt_attribute8               := NULL;                                                  -- 銀行口座予備8
            l_vend_if_rec.acnt_attribute9               := NULL;                                                  -- 銀行口座予備9
            l_vend_if_rec.acnt_attribute10              := NULL;                                                  -- 銀行口座予備10
            l_vend_if_rec.acnt_attribute11              := NULL;                                                  -- 銀行口座予備11
            l_vend_if_rec.acnt_attribute12              := NULL;                                                  -- 銀行口座予備12
            l_vend_if_rec.acnt_attribute13              := NULL;                                                  -- 銀行口座予備13
            l_vend_if_rec.acnt_attribute14              := NULL;                                                  -- 銀行口座予備14
            l_vend_if_rec.acnt_attribute15              := NULL;                                                  -- 銀行口座予備15
            l_vend_if_rec.acnt_cash_clearing_ccid       := NULL;                                                  -- 銀行口座資金決済勘定科目ID
            l_vend_if_rec.acnt_bank_charges_ccid        := NULL;                                                  -- 銀行口座銀行手数料勘定科目ID
            l_vend_if_rec.acnt_bank_errors_ccid         := NULL;                                                  -- 銀行口座銀行エラー勘定科目ID
            l_vend_if_rec.acnt_account_holder_name      := gv_holder_nm;                                          -- 銀行口座口座名義人名
            l_vend_if_rec.acnt_account_holder_name_alt  := gv_holder_alt_nm;                                      -- 銀行口座口座名義人名(カナ)
            l_vend_if_rec.uses_start_date               := gd_process_date;                                       -- 銀行口座割当開始日
            l_vend_if_rec.uses_end_date                 := NULL;                                                  -- 銀行口座割当終了日
            l_vend_if_rec.uses_attribute_category       := NULL;                                                  -- 銀行口座割当予備カテゴリ
            l_vend_if_rec.uses_attribute1               := NULL;                                                  -- 銀行口座割当予備1
            l_vend_if_rec.uses_attribute2               := NULL;                                                  -- 銀行口座割当予備2
            l_vend_if_rec.uses_attribute3               := NULL;                                                  -- 銀行口座割当予備3
            l_vend_if_rec.uses_attribute4               := NULL;                                                  -- 銀行口座割当予備4
            l_vend_if_rec.uses_attribute5               := NULL;                                                  -- 銀行口座割当予備5
            l_vend_if_rec.uses_attribute6               := NULL;                                                  -- 銀行口座割当予備6
            l_vend_if_rec.uses_attribute7               := NULL;                                                  -- 銀行口座割当予備7
            l_vend_if_rec.uses_attribute8               := NULL;                                                  -- 銀行口座割当予備8
            l_vend_if_rec.uses_attribute9               := NULL;                                                  -- 銀行口座割当予備9
            l_vend_if_rec.uses_attribute10              := NULL;                                                  -- 銀行口座割当予備10
            l_vend_if_rec.uses_attribute11              := NULL;                                                  -- 銀行口座割当予備11
            l_vend_if_rec.uses_attribute12              := NULL;                                                  -- 銀行口座割当予備12
            l_vend_if_rec.uses_attribute13              := NULL;                                                  -- 銀行口座割当予備13
            l_vend_if_rec.uses_attribute14              := NULL;                                                  -- 銀行口座割当予備14
            l_vend_if_rec.uses_attribute15              := NULL;                                                  -- 銀行口座割当予備15
            l_vend_if_rec.status_flag                   := cv_status_flg;                                         -- ステータスフラグ
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify start by Y.Kuboshima
--          -- 退社の場合
--          ELSIF (lv_kbn = cv_t) THEN
          -- 退社、再雇用の場合
          ELSIF (lv_kbn IN (cv_t, cv_s)) THEN
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify start by Y.Kuboshima
            l_vend_if_rec.site_vendor_site_id           := NULL;                                                  -- 仕入先サイト仕入先サイトID
            l_vend_if_rec.site_vendor_site_code         := NULL;                                                  -- 仕入先サイト仕入先サイト名
            l_vend_if_rec.site_address_line1            := NULL;                                                  -- 仕入先サイト所在地1
            l_vend_if_rec.site_address_line2            := NULL;                                                  -- 仕入先サイト所在地2
            l_vend_if_rec.site_address_line3            := NULL;                                                  -- 仕入先サイト所在地3
            l_vend_if_rec.site_city                     := NULL;                                                  -- 仕入先サイト住所・郡市区
            l_vend_if_rec.site_state                    := NULL;                                                  -- 仕入先サイト住所・都道府県
            l_vend_if_rec.site_zip                      := NULL;                                                  -- 仕入先サイト住所・郵便番号
            l_vend_if_rec.site_province                 := NULL;                                                  -- 仕入先サイト住所・州
            l_vend_if_rec.site_country                  := NULL;                                                  -- 仕入先サイト国
            l_vend_if_rec.site_area_code                := NULL;                                                  -- 仕入先サイト市外局番
            l_vend_if_rec.site_phone                    := NULL;                                                  -- 仕入先サイト電話番号
            l_vend_if_rec.site_fax                      := NULL;                                                  -- 仕入先サイトFAX
            l_vend_if_rec.site_fax_area_code            := NULL;                                                  -- 仕入先サイトFAX市外局番
            l_vend_if_rec.site_payment_method_lkup_code := NULL;                                                  -- 仕入先サイト支払方法
            l_vend_if_rec.site_bank_account_name        := NULL;                                                  -- 仕入先サイト口座名称
            l_vend_if_rec.site_bank_account_num         := NULL;                                                  -- 仕入先サイト口座番号
            l_vend_if_rec.site_bank_num                 := NULL;                                                  -- 仕入先サイト銀行コード
            l_vend_if_rec.site_bank_account_type        := NULL;                                                  -- 仕入先サイト預金種別
            l_vend_if_rec.site_vat_code                 := NULL;                                                  -- 仕入先サイト請求書税金コード
            l_vend_if_rec.site_distribution_set_id      := NULL;                                                  -- 仕入先サイト配分セットID
            l_vend_if_rec.site_accts_pay_ccid           := NULL;                                                  -- 仕入先サイト負債勘定科目ID
            l_vend_if_rec.site_prepay_ccid              := NULL;                                                  -- 仕入先サイト前払／仮払金勘定科
            l_vend_if_rec.site_pay_group_lkup_code      := NULL;                                                  -- 仕入先サイト支払グループコード
            l_vend_if_rec.site_terms_id                 := NULL;                                                  -- 仕入先サイト支払条件
            l_vend_if_rec.site_invoice_amount_limit     := NULL;                                                  -- 仕入先サイト請求限度額
            l_vend_if_rec.site_attribute_category       := NULL;                                                  -- 仕入先サイト予備カテゴリ
            l_vend_if_rec.site_attribute1               := NULL;                                                  -- 仕入先サイト予備1
            l_vend_if_rec.site_attribute2               := NULL;                                                  -- 仕入先サイト予備2
            l_vend_if_rec.site_attribute3               := NULL;                                                  -- 仕入先サイト予備3
            l_vend_if_rec.site_attribute4               := NULL;                                                  -- 仕入先サイト予備4
            l_vend_if_rec.site_attribute5               := NULL;                                                  -- 仕入先サイト予備5
            l_vend_if_rec.site_attribute6               := NULL;                                                  -- 仕入先サイト予備6
            l_vend_if_rec.site_attribute7               := NULL;                                                  -- 仕入先サイト予備7
            l_vend_if_rec.site_attribute8               := NULL;                                                  -- 仕入先サイト予備8
            l_vend_if_rec.site_attribute9               := NULL;                                                  -- 仕入先サイト予備9
            l_vend_if_rec.site_attribute10              := NULL;                                                  -- 仕入先サイト予備10
            l_vend_if_rec.site_attribute11              := NULL;                                                  -- 仕入先サイト予備11
            l_vend_if_rec.site_attribute12              := NULL;                                                  -- 仕入先サイト予備12
            l_vend_if_rec.site_attribute13              := NULL;                                                  -- 仕入先サイト予備13
            l_vend_if_rec.site_attribute14              := NULL;                                                  -- 仕入先サイト予備14
            l_vend_if_rec.site_attribute15              := NULL;                                                  -- 仕入先サイト予備15
            l_vend_if_rec.site_bank_number              := NULL;                                                  -- 仕入先サイト銀行支店コード
            l_vend_if_rec.site_address_line4            := NULL;                                                  -- 仕入先サイト所在地4
            l_vend_if_rec.site_county                   := NULL;                                                  -- 仕入先サイト郡
            l_vend_if_rec.site_allow_awt_flag           := NULL;                                                  -- 仕入先サイト源泉徴収税使用フラ
            l_vend_if_rec.site_awt_group_id             := NULL;                                                  -- 仕入先サイト源泉徴収税グループ
            l_vend_if_rec.site_vendor_site_code_alt     := NULL;                                                  -- 仕入先サイト仕入先サイト名（カ
            l_vend_if_rec.site_address_lines_alt        := NULL;                                                  -- 仕入先サイト住所カナ
            l_vend_if_rec.site_ap_tax_rounding_rule     := NULL;                                                  -- 仕入先サイト請求税自動計算端数
            l_vend_if_rec.site_auto_tax_calc_flag       := NULL;                                                  -- 仕入先サイト請求税自動計算計算
            l_vend_if_rec.site_auto_tax_calc_override   := NULL;                                                  -- 仕入先サイト請求税自動計算上書
            l_vend_if_rec.site_bank_charge_bearer       := NULL;                                                  -- 仕入先サイト銀行手数料負担者
            l_vend_if_rec.site_bank_branch_type         := NULL;                                                  -- 仕入先サイト銀行支店タイプ
            l_vend_if_rec.site_create_debit_memo_flag   := NULL;                                                  -- 仕入先サイトRTS取引からデビッ
            l_vend_if_rec.site_supplier_notif_method    := NULL;                                                  -- 仕入先サイト仕入先通知方法
            l_vend_if_rec.site_email_address            := NULL;                                                  -- 仕入先サイトEメールアドレス
            l_vend_if_rec.site_primary_pay_site_flag    := NULL;                                                  -- 仕入先サイト主支払サイトフラグ
            l_vend_if_rec.site_purchasing_site_flag     := NULL;                                                  -- 仕入先サイト購買フラグ
            l_vend_if_rec.acnt_bank_number              := NULL;                                                  -- 銀行口座銀行支店コード
            l_vend_if_rec.acnt_bank_num                 := NULL;                                                  -- 銀行口座銀行コード
            l_vend_if_rec.acnt_bank_account_name        := NULL;                                                  -- 銀行口座口座名称
            l_vend_if_rec.acnt_bank_account_num         := NULL;                                                  -- 銀行口座口座番号
            l_vend_if_rec.acnt_currency_code            := NULL;                                                  -- 銀行口座通貨コード
            l_vend_if_rec.acnt_description              := NULL;                                                  -- 銀行口座摘要
            l_vend_if_rec.acnt_asset_id                 := NULL;                                                  -- 銀行口座現預金勘定科目ID
            l_vend_if_rec.acnt_bank_account_type        := NULL;                                                  -- 銀行口座預金種別
            l_vend_if_rec.acnt_attribute_category       := NULL;                                                  -- 銀行口座予備カテゴリ
            l_vend_if_rec.acnt_attribute1               := NULL;                                                  -- 銀行口座予備1
            l_vend_if_rec.acnt_attribute2               := NULL;                                                  -- 銀行口座予備2
            l_vend_if_rec.acnt_attribute3               := NULL;                                                  -- 銀行口座予備3
            l_vend_if_rec.acnt_attribute4               := NULL;                                                  -- 銀行口座予備4
            l_vend_if_rec.acnt_attribute5               := NULL;                                                  -- 銀行口座予備5
            l_vend_if_rec.acnt_attribute6               := NULL;                                                  -- 銀行口座予備6
            l_vend_if_rec.acnt_attribute7               := NULL;                                                  -- 銀行口座予備7
            l_vend_if_rec.acnt_attribute8               := NULL;                                                  -- 銀行口座予備8
            l_vend_if_rec.acnt_attribute9               := NULL;                                                  -- 銀行口座予備9
            l_vend_if_rec.acnt_attribute10              := NULL;                                                  -- 銀行口座予備10
            l_vend_if_rec.acnt_attribute11              := NULL;                                                  -- 銀行口座予備11
            l_vend_if_rec.acnt_attribute12              := NULL;                                                  -- 銀行口座予備12
            l_vend_if_rec.acnt_attribute13              := NULL;                                                  -- 銀行口座予備13
            l_vend_if_rec.acnt_attribute14              := NULL;                                                  -- 銀行口座予備14
            l_vend_if_rec.acnt_attribute15              := NULL;                                                  -- 銀行口座予備15
            l_vend_if_rec.acnt_cash_clearing_ccid       := NULL;                                                  -- 銀行口座資金決済勘定科目ID
            l_vend_if_rec.acnt_bank_charges_ccid        := NULL;                                                  -- 銀行口座銀行手数料勘定科目ID
            l_vend_if_rec.acnt_bank_errors_ccid         := NULL;                                                  -- 銀行口座銀行エラー勘定科目ID
            l_vend_if_rec.acnt_account_holder_name      := NULL;                                                  -- 銀行口座口座名義人名
            l_vend_if_rec.acnt_account_holder_name_alt  := NULL;                                                  -- 銀行口座口座名義人名（カナ）
            l_vend_if_rec.uses_start_date               := NULL;                                                  -- 銀行口座割当開始日
            l_vend_if_rec.uses_end_date                 := NULL;                                                  -- 銀行口座割当終了日
            l_vend_if_rec.uses_attribute_category       := NULL;                                                  -- 銀行口座割当予備カテゴリ
            l_vend_if_rec.uses_attribute1               := NULL;                                                  -- 銀行口座割当予備1
            l_vend_if_rec.uses_attribute2               := NULL;                                                  -- 銀行口座割当予備2
            l_vend_if_rec.uses_attribute3               := NULL;                                                  -- 銀行口座割当予備3
            l_vend_if_rec.uses_attribute4               := NULL;                                                  -- 銀行口座割当予備4
            l_vend_if_rec.uses_attribute5               := NULL;                                                  -- 銀行口座割当予備5
            l_vend_if_rec.uses_attribute6               := NULL;                                                  -- 銀行口座割当予備6
            l_vend_if_rec.uses_attribute7               := NULL;                                                  -- 銀行口座割当予備7
            l_vend_if_rec.uses_attribute8               := NULL;                                                  -- 銀行口座割当予備8
            l_vend_if_rec.uses_attribute9               := NULL;                                                  -- 銀行口座割当予備9
            l_vend_if_rec.uses_attribute10              := NULL;                                                  -- 銀行口座割当予備10
            l_vend_if_rec.uses_attribute11              := NULL;                                                  -- 銀行口座割当予備11
            l_vend_if_rec.uses_attribute12              := NULL;                                                  -- 銀行口座割当予備12
            l_vend_if_rec.uses_attribute13              := NULL;                                                  -- 銀行口座割当予備13
            l_vend_if_rec.uses_attribute14              := NULL;                                                  -- 銀行口座割当予備14
            l_vend_if_rec.uses_attribute15              := NULL;                                                  -- 銀行口座割当予備15
            l_vend_if_rec.status_flag                   := cv_status_flg;                                         -- ステータスフラグ
          END IF;
          BEGIN
            -- 中間テーブルへINSERT
            INSERT INTO xx03_vendors_interface(
              vendors_interface_id                                  -- 仕入先インターフェースID
             ,insert_update_flag                                    -- 追加更新フラグ
             ,vndr_vendor_id                                        -- 仕入先仕入先ID
             ,vndr_vendor_name                                      -- 仕入先仕入先名
             ,vndr_segment1                                         -- 仕入先仕入先番号
             ,vndr_employee_id                                      -- 仕入先従業員ID
             ,vndr_vendor_type_lkup_code                            -- 仕入先仕入先タイプ
             ,vndr_terms_id                                         -- 仕入先支払条件
             ,vndr_pay_group_lkup_code                              -- 仕入先支払グループコード
             ,vndr_invoice_amount_limit                             -- 仕入先請求限度額
             ,vndr_accts_pay_ccid                                   -- 仕入先負債勘定科目ID
             ,vndr_prepay_ccid                                      -- 仕入先前払／仮払金勘定科目ID
             ,vndr_end_date_active                                  -- 仕入先無効日
             ,vndr_small_business_flag                              -- 仕入先中小法人フラグ
             ,vndr_receipt_required_flag                            -- 仕入先入金確認フラグ
             ,vndr_attribute_category                               -- 仕入先予備カテゴリ
             ,vndr_attribute1                                       -- 仕入先予備1
             ,vndr_attribute2                                       -- 仕入先予備2
             ,vndr_attribute3                                       -- 仕入先予備3
             ,vndr_attribute4                                       -- 仕入先予備4
             ,vndr_attribute5                                       -- 仕入先予備5
             ,vndr_attribute6                                       -- 仕入先予備6
             ,vndr_attribute7                                       -- 仕入先予備7
             ,vndr_attribute8                                       -- 仕入先予備8
             ,vndr_attribute9                                       -- 仕入先予備9
             ,vndr_attribute10                                      -- 仕入先予備10
             ,vndr_attribute11                                      -- 仕入先予備11
             ,vndr_attribute12                                      -- 仕入先予備12
             ,vndr_attribute13                                      -- 仕入先予備13
             ,vndr_attribute14                                      -- 仕入先予備14
             ,vndr_attribute15                                      -- 仕入先予備15
             ,vndr_allow_awt_flag                                   -- 仕入先源泉徴収税使用フラグ
             ,vndr_vendor_name_alt                                  -- 仕入先仕入先カナ名称
             ,vndr_ap_tax_rounding_rule                             -- 仕入先請求税自動計算端数処理規
             ,vndr_auto_tax_calc_flag                               -- 仕入先請求税自動計算計算レベル
             ,vndr_auto_tax_calc_override                           -- 仕入先請求税自動計算上書きの許
             ,vndr_bank_charge_bearer                               -- 仕入先銀行手数料負担者
             ,site_vendor_site_id                                   -- 仕入先サイト仕入先サイトID
             ,site_vendor_site_code                                 -- 仕入先サイト仕入先サイト名
             ,site_address_line1                                    -- 仕入先サイト所在地1
             ,site_address_line2                                    -- 仕入先サイト所在地2
             ,site_address_line3                                    -- 仕入先サイト所在地3
             ,site_city                                             -- 仕入先サイト住所・郡市区
             ,site_state                                            -- 仕入先サイト住所・都道府県
             ,site_zip                                              -- 仕入先サイト住所・郵便番号
             ,site_province                                         -- 仕入先サイト住所・州
             ,site_country                                          -- 仕入先サイト国
             ,site_area_code                                        -- 仕入先サイト市外局番
             ,site_phone                                            -- 仕入先サイト電話番号
             ,site_fax                                              -- 仕入先サイトFAX
             ,site_fax_area_code                                    -- 仕入先サイトFAX市外局番
             ,site_payment_method_lkup_code                         -- 仕入先サイト支払方法
             ,site_bank_account_name                                -- 仕入先サイト口座名称
             ,site_bank_account_num                                 -- 仕入先サイト口座番号
             ,site_bank_num                                         -- 仕入先サイト銀行コード
             ,site_bank_account_type                                -- 仕入先サイト預金種別
             ,site_vat_code                                         -- 仕入先サイト請求書税金コード
             ,site_distribution_set_id                              -- 仕入先サイト配分セットID
             ,site_accts_pay_ccid                                   -- 仕入先サイト負債勘定科目ID
             ,site_prepay_ccid                                      -- 仕入先サイト前払／仮払金勘定科
             ,site_pay_group_lkup_code                              -- 仕入先サイト支払グループコード
             ,site_terms_id                                         -- 仕入先サイト支払条件
             ,site_invoice_amount_limit                             -- 仕入先サイト請求限度額
             ,site_attribute_category                               -- 仕入先サイト予備カテゴリ
             ,site_attribute1                                       -- 仕入先サイト予備1
             ,site_attribute2                                       -- 仕入先サイト予備2
             ,site_attribute3                                       -- 仕入先サイト予備3
             ,site_attribute4                                       -- 仕入先サイト予備4
             ,site_attribute5                                       -- 仕入先サイト予備5
             ,site_attribute6                                       -- 仕入先サイト予備6
             ,site_attribute7                                       -- 仕入先サイト予備7
             ,site_attribute8                                       -- 仕入先サイト予備8
             ,site_attribute9                                       -- 仕入先サイト予備9
             ,site_attribute10                                      -- 仕入先サイト予備10
             ,site_attribute11                                      -- 仕入先サイト予備11
             ,site_attribute12                                      -- 仕入先サイト予備12
             ,site_attribute13                                      -- 仕入先サイト予備13
             ,site_attribute14                                      -- 仕入先サイト予備14
             ,site_attribute15                                      -- 仕入先サイト予備15
             ,site_bank_number                                      -- 仕入先サイト銀行支店コード
             ,site_address_line4                                    -- 仕入先サイト所在地4
             ,site_county                                           -- 仕入先サイト郡
             ,site_allow_awt_flag                                   -- 仕入先サイト源泉徴収税使用フラ
             ,site_awt_group_id                                     -- 仕入先サイト源泉徴収税グループ
             ,site_vendor_site_code_alt                             -- 仕入先サイト仕入先サイト名（カ
             ,site_address_lines_alt                                -- 仕入先サイト住所カナ
             ,site_ap_tax_rounding_rule                             -- 仕入先サイト請求税自動計算端数
             ,site_auto_tax_calc_flag                               -- 仕入先サイト請求税自動計算計算
             ,site_auto_tax_calc_override                           -- 仕入先サイト請求税自動計算上書
             ,site_bank_charge_bearer                               -- 仕入先サイト銀行手数料負担者
             ,site_bank_branch_type                                 -- 仕入先サイト銀行支店タイプ
             ,site_create_debit_memo_flag                           -- 仕入先サイトRTS取引からデビッ
             ,site_supplier_notif_method                            -- 仕入先サイト仕入先通知方法
             ,site_email_address                                    -- 仕入先サイトEメールアドレス
             ,site_primary_pay_site_flag                            -- 仕入先サイト主支払サイトフラグ
             ,site_purchasing_site_flag                             -- 仕入先サイト購買フラグ
             ,acnt_bank_number                                      -- 銀行口座銀行支店コード
             ,acnt_bank_num                                         -- 銀行口座銀行コード
             ,acnt_bank_account_name                                -- 銀行口座口座名称
             ,acnt_bank_account_num                                 -- 銀行口座口座番号
             ,acnt_currency_code                                    -- 銀行口座通貨コード
             ,acnt_description                                      -- 銀行口座摘要
             ,acnt_asset_id                                         -- 銀行口座現預金勘定科目ID
             ,acnt_bank_account_type                                -- 銀行口座預金種別
             ,acnt_attribute_category                               -- 銀行口座予備カテゴリ
             ,acnt_attribute1                                       -- 銀行口座予備1
             ,acnt_attribute2                                       -- 銀行口座予備2
             ,acnt_attribute3                                       -- 銀行口座予備3
             ,acnt_attribute4                                       -- 銀行口座予備4
             ,acnt_attribute5                                       -- 銀行口座予備5
             ,acnt_attribute6                                       -- 銀行口座予備6
             ,acnt_attribute7                                       -- 銀行口座予備7
             ,acnt_attribute8                                       -- 銀行口座予備8
             ,acnt_attribute9                                       -- 銀行口座予備9
             ,acnt_attribute10                                      -- 銀行口座予備10
             ,acnt_attribute11                                      -- 銀行口座予備11
             ,acnt_attribute12                                      -- 銀行口座予備12
             ,acnt_attribute13                                      -- 銀行口座予備13
             ,acnt_attribute14                                      -- 銀行口座予備14
             ,acnt_attribute15                                      -- 銀行口座予備15
             ,acnt_cash_clearing_ccid                               -- 銀行口座資金決済勘定科目ID
             ,acnt_bank_charges_ccid                                -- 銀行口座銀行手数料勘定科目ID
             ,acnt_bank_errors_ccid                                 -- 銀行口座銀行エラー勘定科目ID
             ,acnt_account_holder_name                              -- 銀行口座口座名義人名
             ,acnt_account_holder_name_alt                          -- 銀行口座口座名義人名（カナ）
             ,uses_start_date                                       -- 銀行口座割当開始日
             ,uses_end_date                                         -- 銀行口座割当終了日
             ,uses_attribute_category                               -- 銀行口座割当予備カテゴリ
             ,uses_attribute1                                       -- 銀行口座割当予備1
             ,uses_attribute2                                       -- 銀行口座割当予備2
             ,uses_attribute3                                       -- 銀行口座割当予備3
             ,uses_attribute4                                       -- 銀行口座割当予備4
             ,uses_attribute5                                       -- 銀行口座割当予備5
             ,uses_attribute6                                       -- 銀行口座割当予備6
             ,uses_attribute7                                       -- 銀行口座割当予備7
             ,uses_attribute8                                       -- 銀行口座割当予備8
             ,uses_attribute9                                       -- 銀行口座割当予備9
             ,uses_attribute10                                      -- 銀行口座割当予備10
             ,uses_attribute11                                      -- 銀行口座割当予備11
             ,uses_attribute12                                      -- 銀行口座割当予備12
             ,uses_attribute13                                      -- 銀行口座割当予備13
             ,uses_attribute14                                      -- 銀行口座割当予備14
             ,uses_attribute15                                      -- 銀行口座割当予備15
             ,status_flag                                           -- ステータスフラグ
            ) VALUES (
              l_vend_if_rec.vendors_interface_id                    -- 仕入先インターフェースID
             ,l_vend_if_rec.insert_update_flag                      -- 追加更新フラグ
             ,l_vend_if_rec.vndr_vendor_id                          -- 仕入先仕入先ID
             ,l_vend_if_rec.vndr_vendor_name                        -- 仕入先仕入先名
             ,l_vend_if_rec.vndr_segment1                           -- 仕入先仕入先番号
             ,l_vend_if_rec.vndr_employee_id                        -- 仕入先従業員ID
             ,l_vend_if_rec.vndr_vendor_type_lkup_code              -- 仕入先仕入先タイプ
             ,l_vend_if_rec.vndr_terms_id                           -- 仕入先支払条件
             ,l_vend_if_rec.vndr_pay_group_lkup_code                -- 仕入先支払グループコード
             ,l_vend_if_rec.vndr_invoice_amount_limit               -- 仕入先請求限度額
             ,l_vend_if_rec.vndr_accts_pay_ccid                     -- 仕入先負債勘定科目ID
             ,l_vend_if_rec.vndr_prepay_ccid                        -- 仕入先前払／仮払金勘定科目ID
             ,l_vend_if_rec.vndr_end_date_active                    -- 仕入先無効日
             ,l_vend_if_rec.vndr_small_business_flag                -- 仕入先中小法人フラグ
             ,l_vend_if_rec.vndr_receipt_required_flag              -- 仕入先入金確認フラグ
             ,l_vend_if_rec.vndr_attribute_category                 -- 仕入先予備カテゴリ
             ,l_vend_if_rec.vndr_attribute1                         -- 仕入先予備1
             ,l_vend_if_rec.vndr_attribute2                         -- 仕入先予備2
             ,l_vend_if_rec.vndr_attribute3                         -- 仕入先予備3
             ,l_vend_if_rec.vndr_attribute4                         -- 仕入先予備4
             ,l_vend_if_rec.vndr_attribute5                         -- 仕入先予備5
             ,l_vend_if_rec.vndr_attribute6                         -- 仕入先予備6
             ,l_vend_if_rec.vndr_attribute7                         -- 仕入先予備7
             ,l_vend_if_rec.vndr_attribute8                         -- 仕入先予備8
             ,l_vend_if_rec.vndr_attribute9                         -- 仕入先予備9
             ,l_vend_if_rec.vndr_attribute10                        -- 仕入先予備10
             ,l_vend_if_rec.vndr_attribute11                        -- 仕入先予備11
             ,l_vend_if_rec.vndr_attribute12                        -- 仕入先予備12
             ,l_vend_if_rec.vndr_attribute13                        -- 仕入先予備13
             ,l_vend_if_rec.vndr_attribute14                        -- 仕入先予備14
             ,l_vend_if_rec.vndr_attribute15                        -- 仕入先予備15
             ,l_vend_if_rec.vndr_allow_awt_flag                     -- 仕入先源泉徴収税使用フラグ
             ,l_vend_if_rec.vndr_vendor_name_alt                    -- 仕入先仕入先カナ名称
             ,l_vend_if_rec.vndr_ap_tax_rounding_rule               -- 仕入先請求税自動計算端数処理規
             ,l_vend_if_rec.vndr_auto_tax_calc_flag                 -- 仕入先請求税自動計算計算レベル
             ,l_vend_if_rec.vndr_auto_tax_calc_override             -- 仕入先請求税自動計算上書きの許
             ,l_vend_if_rec.vndr_bank_charge_bearer                 -- 仕入先銀行手数料負担者
             ,l_vend_if_rec.site_vendor_site_id                     -- 仕入先サイト仕入先サイトID
             ,l_vend_if_rec.site_vendor_site_code                   -- 仕入先サイト仕入先サイト名
             ,l_vend_if_rec.site_address_line1                      -- 仕入先サイト所在地1
             ,l_vend_if_rec.site_address_line2                      -- 仕入先サイト所在地2
             ,l_vend_if_rec.site_address_line3                      -- 仕入先サイト所在地3
             ,l_vend_if_rec.site_city                               -- 仕入先サイト住所・郡市区
             ,l_vend_if_rec.site_state                              -- 仕入先サイト住所・都道府県
             ,l_vend_if_rec.site_zip                                -- 仕入先サイト住所・郵便番号
             ,l_vend_if_rec.site_province                           -- 仕入先サイト住所・州
             ,l_vend_if_rec.site_country                            -- 仕入先サイト国
             ,l_vend_if_rec.site_area_code                          -- 仕入先サイト市外局番
             ,l_vend_if_rec.site_phone                              -- 仕入先サイト電話番号
             ,l_vend_if_rec.site_fax                                -- 仕入先サイトFAX
             ,l_vend_if_rec.site_fax_area_code                      -- 仕入先サイトFAX市外局番
             ,l_vend_if_rec.site_payment_method_lkup_code           -- 仕入先サイト支払方法
             ,l_vend_if_rec.site_bank_account_name                  -- 仕入先サイト口座名称
             ,l_vend_if_rec.site_bank_account_num                   -- 仕入先サイト口座番号
             ,l_vend_if_rec.site_bank_num                           -- 仕入先サイト銀行コード
             ,l_vend_if_rec.site_bank_account_type                  -- 仕入先サイト預金種別
             ,l_vend_if_rec.site_vat_code                           -- 仕入先サイト請求書税金コード
             ,l_vend_if_rec.site_distribution_set_id                -- 仕入先サイト配分セットID
             ,l_vend_if_rec.site_accts_pay_ccid                     -- 仕入先サイト負債勘定科目ID
             ,l_vend_if_rec.site_prepay_ccid                        -- 仕入先サイト前払／仮払金勘定科
             ,l_vend_if_rec.site_pay_group_lkup_code                -- 仕入先サイト支払グループコード
             ,l_vend_if_rec.site_terms_id                           -- 仕入先サイト支払条件
             ,l_vend_if_rec.site_invoice_amount_limit               -- 仕入先サイト請求限度額
             ,l_vend_if_rec.site_attribute_category                 -- 仕入先サイト予備カテゴリ
             ,l_vend_if_rec.site_attribute1                         -- 仕入先サイト予備1
             ,l_vend_if_rec.site_attribute2                         -- 仕入先サイト予備2
             ,l_vend_if_rec.site_attribute3                         -- 仕入先サイト予備3
             ,l_vend_if_rec.site_attribute4                         -- 仕入先サイト予備4
             ,l_vend_if_rec.site_attribute5                         -- 仕入先サイト予備5
             ,l_vend_if_rec.site_attribute6                         -- 仕入先サイト予備6
             ,l_vend_if_rec.site_attribute7                         -- 仕入先サイト予備7
             ,l_vend_if_rec.site_attribute8                         -- 仕入先サイト予備8
             ,l_vend_if_rec.site_attribute9                         -- 仕入先サイト予備9
             ,l_vend_if_rec.site_attribute10                        -- 仕入先サイト予備10
             ,l_vend_if_rec.site_attribute11                        -- 仕入先サイト予備11
             ,l_vend_if_rec.site_attribute12                        -- 仕入先サイト予備12
             ,l_vend_if_rec.site_attribute13                        -- 仕入先サイト予備13
             ,l_vend_if_rec.site_attribute14                        -- 仕入先サイト予備14
             ,l_vend_if_rec.site_attribute15                        -- 仕入先サイト予備15
             ,l_vend_if_rec.site_bank_number                        -- 仕入先サイト銀行支店コード
             ,l_vend_if_rec.site_address_line4                      -- 仕入先サイト所在地4
             ,l_vend_if_rec.site_county                             -- 仕入先サイト郡
             ,l_vend_if_rec.site_allow_awt_flag                     -- 仕入先サイト源泉徴収税使用フラ
             ,l_vend_if_rec.site_awt_group_id                       -- 仕入先サイト源泉徴収税グループ
             ,l_vend_if_rec.site_vendor_site_code_alt               -- 仕入先サイト仕入先サイト名（カ
             ,l_vend_if_rec.site_address_lines_alt                  -- 仕入先サイト住所カナ
             ,l_vend_if_rec.site_ap_tax_rounding_rule               -- 仕入先サイト請求税自動計算端数
             ,l_vend_if_rec.site_auto_tax_calc_flag                 -- 仕入先サイト請求税自動計算計算
             ,l_vend_if_rec.site_auto_tax_calc_override             -- 仕入先サイト請求税自動計算上書
             ,l_vend_if_rec.site_bank_charge_bearer                 -- 仕入先サイト銀行手数料負担者
             ,l_vend_if_rec.site_bank_branch_type                   -- 仕入先サイト銀行支店タイプ
             ,l_vend_if_rec.site_create_debit_memo_flag             -- 仕入先サイトRTS取引からデビッ
             ,l_vend_if_rec.site_supplier_notif_method              -- 仕入先サイト仕入先通知方法
             ,l_vend_if_rec.site_email_address                      -- 仕入先サイトEメールアドレス
             ,l_vend_if_rec.site_primary_pay_site_flag              -- 仕入先サイト主支払サイトフラグ
             ,l_vend_if_rec.site_purchasing_site_flag               -- 仕入先サイト購買フラグ
             ,l_vend_if_rec.acnt_bank_number                        -- 銀行口座銀行支店コード
             ,l_vend_if_rec.acnt_bank_num                           -- 銀行口座銀行コード
             ,l_vend_if_rec.acnt_bank_account_name                  -- 銀行口座口座名称
             ,l_vend_if_rec.acnt_bank_account_num                   -- 銀行口座口座番号
             ,l_vend_if_rec.acnt_currency_code                      -- 銀行口座通貨コード
             ,l_vend_if_rec.acnt_description                        -- 銀行口座摘要
             ,l_vend_if_rec.acnt_asset_id                           -- 銀行口座現預金勘定科目ID
             ,l_vend_if_rec.acnt_bank_account_type                  -- 銀行口座預金種別
             ,l_vend_if_rec.acnt_attribute_category                 -- 銀行口座予備カテゴリ
             ,l_vend_if_rec.acnt_attribute1                         -- 銀行口座予備1
             ,l_vend_if_rec.acnt_attribute2                         -- 銀行口座予備2
             ,l_vend_if_rec.acnt_attribute3                         -- 銀行口座予備3
             ,l_vend_if_rec.acnt_attribute4                         -- 銀行口座予備4
             ,l_vend_if_rec.acnt_attribute5                         -- 銀行口座予備5
             ,l_vend_if_rec.acnt_attribute6                         -- 銀行口座予備6
             ,l_vend_if_rec.acnt_attribute7                         -- 銀行口座予備7
             ,l_vend_if_rec.acnt_attribute8                         -- 銀行口座予備8
             ,l_vend_if_rec.acnt_attribute9                         -- 銀行口座予備9
             ,l_vend_if_rec.acnt_attribute10                        -- 銀行口座予備10
             ,l_vend_if_rec.acnt_attribute11                        -- 銀行口座予備11
             ,l_vend_if_rec.acnt_attribute12                        -- 銀行口座予備12
             ,l_vend_if_rec.acnt_attribute13                        -- 銀行口座予備13
             ,l_vend_if_rec.acnt_attribute14                        -- 銀行口座予備14
             ,l_vend_if_rec.acnt_attribute15                        -- 銀行口座予備15
             ,l_vend_if_rec.acnt_cash_clearing_ccid                 -- 銀行口座資金決済勘定科目ID
             ,l_vend_if_rec.acnt_bank_charges_ccid                  -- 銀行口座銀行手数料勘定科目ID
             ,l_vend_if_rec.acnt_bank_errors_ccid                   -- 銀行口座銀行エラー勘定科目ID
             ,l_vend_if_rec.acnt_account_holder_name                -- 銀行口座口座名義人名
             ,l_vend_if_rec.acnt_account_holder_name_alt            -- 銀行口座口座名義人名（カナ）
             ,l_vend_if_rec.uses_start_date                         -- 銀行口座割当開始日
             ,l_vend_if_rec.uses_end_date                           -- 銀行口座割当終了日
             ,l_vend_if_rec.uses_attribute_category                 -- 銀行口座割当予備カテゴリ
             ,l_vend_if_rec.uses_attribute1                         -- 銀行口座割当予備1
             ,l_vend_if_rec.uses_attribute2                         -- 銀行口座割当予備2
             ,l_vend_if_rec.uses_attribute3                         -- 銀行口座割当予備3
             ,l_vend_if_rec.uses_attribute4                         -- 銀行口座割当予備4
             ,l_vend_if_rec.uses_attribute5                         -- 銀行口座割当予備5
             ,l_vend_if_rec.uses_attribute6                         -- 銀行口座割当予備6
             ,l_vend_if_rec.uses_attribute7                         -- 銀行口座割当予備7
             ,l_vend_if_rec.uses_attribute8                         -- 銀行口座割当予備8
             ,l_vend_if_rec.uses_attribute9                         -- 銀行口座割当予備9
             ,l_vend_if_rec.uses_attribute10                        -- 銀行口座割当予備10
             ,l_vend_if_rec.uses_attribute11                        -- 銀行口座割当予備11
             ,l_vend_if_rec.uses_attribute12                        -- 銀行口座割当予備12
             ,l_vend_if_rec.uses_attribute13                        -- 銀行口座割当予備13
             ,l_vend_if_rec.uses_attribute14                        -- 銀行口座割当予備14
             ,l_vend_if_rec.uses_attribute15                        -- 銀行口座割当予備15
             ,l_vend_if_rec.status_flag                             -- ステータスフラグ
            );
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxcmn_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                              ,iv_name         => cv_msg_00221             -- 仕入先従業員情報中間I/Fテーブル登録エラー
                              ,iv_token_name1  => cv_tkn_err_msg           -- トークン(NG_PROFILE)
                              ,iv_token_value1 => SQLERRM                  -- プロファイル名(所在地2)
                             );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
          END;
-- 2009/07/17 Ver1.3 modify end by Yutaka.Kuboshima
          gn_normal_cnt := gn_normal_cnt + 1;
-- Ver1.2  2009/04/21  Del  障害：T1_0255対応  シーケンスを取得するため削除
--          gn_v_interface_id := gn_v_interface_id + 1;
-- End Ver1.2
-- 2009/07/17 Ver1.3 add start by Yutaka.Kuboshima
          -- 変数初期化
          l_vend_if_rec := NULL;
-- 2009/07/17 Ver1.3 add end by Yutaka.Kuboshima
        END IF;
      END IF;
      lv_employee_number := gt_u_people_data(ln_loop_cnt).employee_number;
    END LOOP u_out_loop;
    -- 対象件数の取得
    gn_target_cnt := gn_target_update_cnt - ln_o_cnt;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--
--#####################################  固定部 END   ##########################################
--
  END update_output_csv;
--
  /**********************************************************************************
   * Procedure Name   : get_i_people_data
   * Description      : 新規登録の社員データ取得プロシージャ(A-8)
   ***********************************************************************************/
  PROCEDURE get_i_people_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_i_people_data';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
   -- カーソルオープン
    OPEN get_i_people_data_cur;
--
    -- データの一括取得
    FETCH get_i_people_data_cur BULK COLLECT INTO gt_i_people_data;
--
    -- 新規登録以外の対象件数をセット
    gn_target_add_cnt := gt_i_people_data.COUNT;
--
    -- カーソルクローズ
    CLOSE get_i_people_data_cur;
--
    -- 対象件数の取得
    gn_target_cnt := gn_target_cnt + gn_target_add_cnt;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
--#####################################  固定部 END   ##########################################
--
  END get_i_people_data;
--
  /**********************************************************************************
   * Procedure Name   : add_output_csv
   * Description      : 中間I/Fテーブルデータ登録(新規登録)プロシージャ(A-10)
   ***********************************************************************************/
  PROCEDURE add_output_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_output_csv';     -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf           VARCHAR2(5000);           -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);              -- リターン・コード
    lv_errmsg           VARCHAR2(5000);           -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV区切り文字
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- 単語囲み文字
--
    -- *** ローカル変数 ***
    ln_loop_cnt         NUMBER;                   -- ループカウンタ
    lv_csv_text         VARCHAR2(32000);          -- 出力１行分文字列変数
    lv_pay_group        VARCHAR2(50);             -- 支払グループコード
    lv_ret_flg          VARCHAR2(1);              -- 支払グループコード取得処理用フラグ
    lv_employee_number  VARCHAR2(22);             -- 従業員番号重複チェック用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    <<i_out_loop>>
    FOR ln_loop_cnt IN gt_i_people_data.FIRST..gt_i_people_data.LAST LOOP
      --========================================
      -- 従業員番号重複チェック(A-8-1)
      --========================================
      -- 従業員番号が重複している場合、警告メッセージを表示
      IF (lv_employee_number = gt_i_people_data(ln_loop_cnt).employee_number) THEN
        -- 警告フラグにオンをセット
        gv_warn_flg := '1';
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                  -- 'XXCMM'
                        ,iv_name         => cv_msg_00209                                    -- 従業員番号重複メッセージ
                        ,iv_token_name1  => cv_tkn_word                                     -- トークン(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                    -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                     -- トークン(NG_DATA)
                        ,iv_token_value2 => gt_i_people_data(ln_loop_cnt).employee_number   -- NG_WORDのDATA
                                              || cv_tkn_word2
                                              || gt_i_people_data(ln_loop_cnt).per_information18
                                              || '　'
                                              || gt_i_people_data(ln_loop_cnt).per_information19
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
      END IF;
      --========================================
      -- 部門コードチェック(A-8-2)
      --========================================
      IF (gt_i_people_data(ln_loop_cnt).ass_attribute3 IS NULL) THEN
        -- 警告フラグにオンをセット
        gv_warn_flg := '1';
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                  -- 'XXCMM'
                        ,iv_name         => cv_msg_00208                                    -- 勤務地拠点コード(新)未入力エラー
                        ,iv_token_name1  => cv_tkn_word                                     -- トークン(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                    -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                     -- トークン(NG_DATA)
                        ,iv_token_value2 => gt_i_people_data(ln_loop_cnt).employee_number   -- NG_WORDのDATA
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        -- スキップ件数をカウント
        gn_warn_cnt := gn_warn_cnt + 1;
      ELSE
        --========================================
        -- 支払グループ取得(A-8-3)
        --========================================
        BEGIN
-- 2010/04/12 Ver1.5 E_本稼動_02240 add start by Y.Kuboshima
          -- 小口現金用の支払グループを生成します。
          lv_pay_group := gt_i_people_data(ln_loop_cnt).ass_attribute3 || '-' || gv_koguti_genkin_nm;
-- 2010/04/12 Ver1.5 E_本稼動_02240 add end by Y.Kuboshima
          SELECT   '1'
          INTO     lv_ret_flg
          FROM     fnd_lookup_values_vl
          WHERE    lookup_type = gv_group_type_nm
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify start by Y.Kuboshima
--          AND      attribute2 = gt_i_people_data(ln_loop_cnt).ass_attribute3
          AND      lookup_code = lv_pay_group
          AND      NVL(attribute3, cv_n_flag) = cv_n_flag
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify end by Y.Kuboshima
          AND      ROWNUM = 1;
          IF (gt_i_people_data(ln_loop_cnt).ass_attribute3 = gv_pay_bumon_cd) THEN
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--            lv_pay_group := gv_pay_bumon_nm || '-' || gv_pay_method_nm || '/' || gv_pay_bank|| '/' || gv_pay_type_nm;
            lv_pay_group := gv_pay_bumon_cd || '-' || gv_pay_method_nm || '-' || gv_pay_bank;
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
          ELSE
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--            lv_pay_group := gt_i_people_data(ln_loop_cnt).ass_attribute3 || '-' || gv_koguti_genkin_nm || '/' || gv_pay_type_nm;
            lv_pay_group := gt_i_people_data(ln_loop_cnt).ass_attribute3 || '-' || gv_koguti_genkin_nm;
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--            lv_pay_group := gv_pay_bumon_nm || '-' || gv_pay_method_nm || '/' || gv_pay_bank|| '/' || gv_pay_type_nm;
            lv_pay_group := gv_pay_bumon_cd || '-' || gv_pay_method_nm || '-' || gv_pay_bank;
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        IF (LENGTHB(lv_pay_group) > cv_pay_group_length) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                          ,iv_name         => cv_msg_00215                                  -- 支払グループコード文字数制限エラー
                          ,iv_token_name1  => cv_tkn_length                                 -- トークン(NG_LENGTH)
                          ,iv_token_value1 => cv_pay_group_length                           -- 支払グループコードの最大文字数
                          ,iv_token_name2  => cv_tkn_word                                   -- トークン(NG_WORD)
                          ,iv_token_value2 => cv_tkn_word1                                  -- NG_WORD
                          ,iv_token_name3  => cv_tkn_data                                   -- トークン(NG_DATA)
                          ,iv_token_value3 => gt_i_people_data(ln_loop_cnt).employee_number -- NG_WORDのDATA
                                                || cv_tkn_word3
                                                || lv_pay_group
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
-- Ver1.2  2009/04/21  Add  障害：T1_0255対応  シーケンスを取得処理を追加
        SELECT   xxcso_xx03_vendors_if_s01.NEXTVAL
        INTO     gn_v_interface_id
        FROM     dual;
-- End Ver1.2
        --
        --========================================
        -- CSVファイル出力(A-9)
        --========================================
-- 2009/07/17 Ver1.3 modify start by Yutaka.Kuboshima
-- CSVファイル出力から中間テーブル直INSERTに変更
--        lv_csv_text := gn_v_interface_id || cv_delimiter                                    -- 仕入先インターフェースID(連番)
--          || cv_enclosed || cv_insert_flg || cv_enclosed || cv_delimiter                    -- 追加更新フラグ
---- Ver1.2  2009/04/24  Add  仕入先登録済み、サイト「会社」未登録対応
----          || NULL || cv_delimiter                                                           -- 仕入先仕入先ID
--          || gt_i_people_data(ln_loop_cnt).vendor_id || cv_delimiter                        -- 仕入先仕入先ID
---- End Ver1.2
--          || cv_enclosed || SUBSTRB(gt_i_people_data(ln_loop_cnt).per_information18         -- 仕入先仕入先名
--          || gt_i_people_data(ln_loop_cnt).per_information19 || '／'
--          || TO_MULTI_BYTE(gt_i_people_data(ln_loop_cnt).employee_number),1,80)
--          || cv_enclosed || cv_delimiter
--          || cv_enclosed || SUBSTRB(cv_9000                                                 -- 仕入先仕入先番号
--          || gt_i_people_data(ln_loop_cnt).employee_number,1,30)
--          || cv_enclosed || cv_delimiter
--          || SUBSTRB(gt_i_people_data(ln_loop_cnt).person_id,1,22) || cv_delimiter          -- 仕入先従業員ID
--          || cv_enclosed || gv_vendor_type || cv_enclosed || cv_delimiter                   -- 仕入先仕入先タイプ
--          || NULL || cv_delimiter                                                           -- 仕入先支払条件
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先支払グループコード
--          || NULL || cv_delimiter                                                           -- 仕入先請求限度額
--          || NULL || cv_delimiter                                                           -- 仕入先負債勘定科目ID
--          || NULL || cv_delimiter                                                           -- 仕入先前払／仮払金勘定科目ID
--          || NULL || cv_delimiter                                                           -- 仕入先無効日
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先中小法人フラグ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先入金確認フラグ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備カテゴリ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備1
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備2
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備3
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備4
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備5
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備6
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備7
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備8
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備9
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備10
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備11
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備12
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備13
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備14
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先予備15
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先源泉徴収税使用フラグ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先仕入先カナ名称
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先請求税自動計算端数処理規
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先請求税自動計算計算レベル
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先請求税自動計算上書きの許
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先銀行手数料負担者
--          || NULL || cv_delimiter                                                           -- 仕入先サイト仕入先サイトID
--
---- Ver1.2  2009/04/21  Mod  障害：T1_0438対応  サイトコードを「会社」に修正
----          || cv_enclosed || SUBSTRB(cv_9000                                                 -- 仕入先サイト仕入先サイト名
----          || gt_i_people_data(ln_loop_cnt).employee_number,1,15)
----          || cv_enclosed || cv_delimiter
--          || cv_enclosed || cv_site_code_comp || cv_enclosed || cv_delimiter                -- 仕入先サイト仕入先サイト名
---- End Ver1.2
--          || cv_enclosed || gv_address_nm1 || cv_enclosed || cv_delimiter                   -- 仕入先サイト所在地1
--          || cv_enclosed || gv_address_nm2 || cv_enclosed || cv_delimiter                   -- 仕入先サイト所在地2
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト所在地3
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト住所・郡市区
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト住所・都道府県
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト住所・郵便番号
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト住所・州
--          || cv_enclosed || gv_country || cv_enclosed || cv_delimiter                       -- 仕入先サイト国
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト市外局番
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト電話番号
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイトFAX
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイトFAX市外局番
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト支払方法
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト口座名称
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト口座番号
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト銀行コード
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト預金種別
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト請求書税金コード
--          || NULL || cv_delimiter                                                           -- 仕入先サイト配分セットID
--          || gv_accts_pay_ccid || cv_delimiter                                              -- 仕入先サイト負債勘定科目ID
--          || gv_prepay_ccid || cv_delimiter                                                 -- 仕入先サイト前払／仮払金勘定科
--          || cv_enclosed || lv_pay_group || cv_enclosed || cv_delimiter                     -- 仕入先サイト支払グループコード
--          || gv_terms_id || cv_delimiter                                                    -- 仕入先サイト支払条件
--          || NULL || cv_delimiter                                                           -- 仕入先サイト請求限度額
---- Ver1.1 2009/03/03 Mod  仕入先サイトのATTRIBUTE_CATEGORYにORG_IDを設定
----          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備カテゴリ
--          || cv_enclosed || gn_org_id || cv_enclosed || cv_delimiter                        -- 仕入先サイト予備カテゴリ
---- End
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備1
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備2
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備3
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備4
--          || cv_enclosed || gt_i_people_data(ln_loop_cnt).ass_attribute3                    -- 仕入先サイト予備5
--          || cv_enclosed || cv_delimiter
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備6
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備7
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備8
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備9
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備10
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備11
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備12
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備13
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備14
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト予備15
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト銀行支店コード
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト所在地4
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト郡
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト源泉徴収税使用フラ
--          || NULL || cv_delimiter                                                           -- 仕入先サイト源泉徴収税グループ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト仕入先サイト名（カ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト住所カナ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト請求税自動計算端数
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト請求税自動計算計算
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト請求税自動計算上書
---- Ver1.2  2009/04/21  Add  障害：T1_0438対応  銀行手数料負担者を追加
----          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト銀行手数料負担者
--          || cv_enclosed || gv_s_bank_charge_new || cv_enclosed || cv_delimiter             -- 仕入先サイト銀行手数料負担者
---- End Ver1.2
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト銀行支店タイプ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイトRTS取引からデビッ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト仕入先通知方法
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイトEメールアドレス
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト主支払サイトフラグ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 仕入先サイト購買フラグ
--          || cv_enclosed || gv_bank_number || cv_enclosed || cv_delimiter                   -- 銀行口座銀行支店コード
--          || cv_enclosed || gv_bank_num || cv_enclosed || cv_delimiter                      -- 銀行口座銀行コード
--          || cv_enclosed || SUBSTRB(gv_bank_nm || '/' || gv_shiten_nm,1,80)                 -- 銀行口座口座名称
--          || cv_enclosed || cv_delimiter
--          || cv_enclosed || gv_account_num || cv_enclosed || cv_delimiter                   -- 銀行口座口座番号
--          || cv_enclosed || gv_currency_cd || cv_enclosed || cv_delimiter                   -- 銀行口座通貨コード
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座摘要
--          || NULL || cv_delimiter                                                           -- 銀行口座現預金勘定科目ID
--          || cv_enclosed || gv_account_type || cv_enclosed || cv_delimiter                  -- 銀行口座預金種別
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備カテゴリ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備1
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備2
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備3
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備4
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備5
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備6
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備7
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備8
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備9
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備10
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備11
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備12
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備13
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備14
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座予備15
--          || NULL || cv_delimiter                                                           -- 銀行口座資金決済勘定科目ID
--          || NULL || cv_delimiter                                                           -- 銀行口座銀行手数料勘定科目ID
--          || NULL || cv_delimiter                                                           -- 銀行口座銀行エラー勘定科目ID
--          || cv_enclosed || gv_holder_nm || cv_enclosed || cv_delimiter                     -- 銀行口座口座名義人名
--          || cv_enclosed || gv_holder_alt_nm || cv_enclosed || cv_delimiter                 -- 銀行口座口座名義人名(カナ)
--          || TO_CHAR(gd_process_date,'YYYYMMDD') || cv_delimiter                            -- 銀行口座割当開始日
--          || NULL || cv_delimiter                                                           -- 銀行口座割当終了日
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備カテゴリ
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備1
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備2
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備3
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備4
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備5
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備6
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備7
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備8
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備9
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備10
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備11
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備12
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備13
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備14
--          || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- 銀行口座割当予備15
--          || cv_enclosed || cv_status_flg || cv_enclosed                                    -- ステータスフラグ
--        ;
--        BEGIN
--          -- ファイル書き込み
--          UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
--        EXCEPTION
--          -- ファイルアクセス権限エラー
--          WHEN UTL_FILE.INVALID_OPERATION THEN
--            lv_errmsg := xxcmn_common_pkg.get_msg(
--                             iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
--                            ,iv_name         => cv_msg_00007                                   -- ファイルアクセス権限エラー
--                           );
--            lv_errbuf := lv_errmsg;
--            RAISE global_api_expt;
--          --
--          -- CSVデータ出力エラー
--          WHEN UTL_FILE.WRITE_ERROR THEN
--            lv_errmsg := xxcmn_common_pkg.get_msg(
--                             iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
--                            ,iv_name         => cv_msg_00009                                   -- CSVデータ出力エラー
--                            ,iv_token_name1  => cv_tkn_word                                    -- トークン(NG_WORD)
--                            ,iv_token_value1 => cv_tkn_word1                                   -- NG_WORD
--                            ,iv_token_name2  => cv_tkn_data                                    -- トークン(NG_DATA)
--                            ,iv_token_value2 => gt_i_people_data(ln_loop_cnt).employee_number  -- NG_WORDのDATA
--                           );
--            lv_errbuf := lv_errmsg;
--            RAISE global_api_expt;
--          WHEN OTHERS THEN
--            RAISE global_api_others_expt;
--        END;
--
        BEGIN
          -- 中間テーブルへINSERT
          INSERT INTO xx03_vendors_interface(
            vendors_interface_id                                  -- 仕入先インターフェースID
           ,insert_update_flag                                    -- 追加更新フラグ
           ,vndr_vendor_id                                        -- 仕入先仕入先ID
           ,vndr_vendor_name                                      -- 仕入先仕入先名
           ,vndr_segment1                                         -- 仕入先仕入先番号
           ,vndr_employee_id                                      -- 仕入先従業員ID
           ,vndr_vendor_type_lkup_code                            -- 仕入先仕入先タイプ
           ,vndr_terms_id                                         -- 仕入先支払条件
           ,vndr_pay_group_lkup_code                              -- 仕入先支払グループコード
           ,vndr_invoice_amount_limit                             -- 仕入先請求限度額
           ,vndr_accts_pay_ccid                                   -- 仕入先負債勘定科目ID
           ,vndr_prepay_ccid                                      -- 仕入先前払／仮払金勘定科目ID
           ,vndr_end_date_active                                  -- 仕入先無効日
           ,vndr_small_business_flag                              -- 仕入先中小法人フラグ
           ,vndr_receipt_required_flag                            -- 仕入先入金確認フラグ
           ,vndr_attribute_category                               -- 仕入先予備カテゴリ
           ,vndr_attribute1                                       -- 仕入先予備1
           ,vndr_attribute2                                       -- 仕入先予備2
           ,vndr_attribute3                                       -- 仕入先予備3
           ,vndr_attribute4                                       -- 仕入先予備4
           ,vndr_attribute5                                       -- 仕入先予備5
           ,vndr_attribute6                                       -- 仕入先予備6
           ,vndr_attribute7                                       -- 仕入先予備7
           ,vndr_attribute8                                       -- 仕入先予備8
           ,vndr_attribute9                                       -- 仕入先予備9
           ,vndr_attribute10                                      -- 仕入先予備10
           ,vndr_attribute11                                      -- 仕入先予備11
           ,vndr_attribute12                                      -- 仕入先予備12
           ,vndr_attribute13                                      -- 仕入先予備13
           ,vndr_attribute14                                      -- 仕入先予備14
           ,vndr_attribute15                                      -- 仕入先予備15
           ,vndr_allow_awt_flag                                   -- 仕入先源泉徴収税使用フラグ
           ,vndr_vendor_name_alt                                  -- 仕入先仕入先カナ名称
           ,vndr_ap_tax_rounding_rule                             -- 仕入先請求税自動計算端数処理規
           ,vndr_auto_tax_calc_flag                               -- 仕入先請求税自動計算計算レベル
           ,vndr_auto_tax_calc_override                           -- 仕入先請求税自動計算上書きの許
           ,vndr_bank_charge_bearer                               -- 仕入先銀行手数料負担者
           ,site_vendor_site_id                                   -- 仕入先サイト仕入先サイトID
           ,site_vendor_site_code                                 -- 仕入先サイト仕入先サイト名
           ,site_address_line1                                    -- 仕入先サイト所在地1
           ,site_address_line2                                    -- 仕入先サイト所在地2
           ,site_address_line3                                    -- 仕入先サイト所在地3
           ,site_city                                             -- 仕入先サイト住所・郡市区
           ,site_state                                            -- 仕入先サイト住所・都道府県
           ,site_zip                                              -- 仕入先サイト住所・郵便番号
           ,site_province                                         -- 仕入先サイト住所・州
           ,site_country                                          -- 仕入先サイト国
           ,site_area_code                                        -- 仕入先サイト市外局番
           ,site_phone                                            -- 仕入先サイト電話番号
           ,site_fax                                              -- 仕入先サイトFAX
           ,site_fax_area_code                                    -- 仕入先サイトFAX市外局番
           ,site_payment_method_lkup_code                         -- 仕入先サイト支払方法
           ,site_bank_account_name                                -- 仕入先サイト口座名称
           ,site_bank_account_num                                 -- 仕入先サイト口座番号
           ,site_bank_num                                         -- 仕入先サイト銀行コード
           ,site_bank_account_type                                -- 仕入先サイト預金種別
           ,site_vat_code                                         -- 仕入先サイト請求書税金コード
           ,site_distribution_set_id                              -- 仕入先サイト配分セットID
           ,site_accts_pay_ccid                                   -- 仕入先サイト負債勘定科目ID
           ,site_prepay_ccid                                      -- 仕入先サイト前払／仮払金勘定科
           ,site_pay_group_lkup_code                              -- 仕入先サイト支払グループコード
           ,site_terms_id                                         -- 仕入先サイト支払条件
           ,site_invoice_amount_limit                             -- 仕入先サイト請求限度額
           ,site_attribute_category                               -- 仕入先サイト予備カテゴリ
           ,site_attribute1                                       -- 仕入先サイト予備1
           ,site_attribute2                                       -- 仕入先サイト予備2
           ,site_attribute3                                       -- 仕入先サイト予備3
           ,site_attribute4                                       -- 仕入先サイト予備4
           ,site_attribute5                                       -- 仕入先サイト予備5
           ,site_attribute6                                       -- 仕入先サイト予備6
           ,site_attribute7                                       -- 仕入先サイト予備7
           ,site_attribute8                                       -- 仕入先サイト予備8
           ,site_attribute9                                       -- 仕入先サイト予備9
           ,site_attribute10                                      -- 仕入先サイト予備10
           ,site_attribute11                                      -- 仕入先サイト予備11
           ,site_attribute12                                      -- 仕入先サイト予備12
           ,site_attribute13                                      -- 仕入先サイト予備13
           ,site_attribute14                                      -- 仕入先サイト予備14
           ,site_attribute15                                      -- 仕入先サイト予備15
           ,site_bank_number                                      -- 仕入先サイト銀行支店コード
           ,site_address_line4                                    -- 仕入先サイト所在地4
           ,site_county                                           -- 仕入先サイト郡
           ,site_allow_awt_flag                                   -- 仕入先サイト源泉徴収税使用フラ
           ,site_awt_group_id                                     -- 仕入先サイト源泉徴収税グループ
           ,site_vendor_site_code_alt                             -- 仕入先サイト仕入先サイト名（カ
           ,site_address_lines_alt                                -- 仕入先サイト住所カナ
           ,site_ap_tax_rounding_rule                             -- 仕入先サイト請求税自動計算端数
           ,site_auto_tax_calc_flag                               -- 仕入先サイト請求税自動計算計算
           ,site_auto_tax_calc_override                           -- 仕入先サイト請求税自動計算上書
           ,site_bank_charge_bearer                               -- 仕入先サイト銀行手数料負担者
           ,site_bank_branch_type                                 -- 仕入先サイト銀行支店タイプ
           ,site_create_debit_memo_flag                           -- 仕入先サイトRTS取引からデビッ
           ,site_supplier_notif_method                            -- 仕入先サイト仕入先通知方法
           ,site_email_address                                    -- 仕入先サイトEメールアドレス
           ,site_primary_pay_site_flag                            -- 仕入先サイト主支払サイトフラグ
           ,site_purchasing_site_flag                             -- 仕入先サイト購買フラグ
           ,acnt_bank_number                                      -- 銀行口座銀行支店コード
           ,acnt_bank_num                                         -- 銀行口座銀行コード
           ,acnt_bank_account_name                                -- 銀行口座口座名称
           ,acnt_bank_account_num                                 -- 銀行口座口座番号
           ,acnt_currency_code                                    -- 銀行口座通貨コード
           ,acnt_description                                      -- 銀行口座摘要
           ,acnt_asset_id                                         -- 銀行口座現預金勘定科目ID
           ,acnt_bank_account_type                                -- 銀行口座預金種別
           ,acnt_attribute_category                               -- 銀行口座予備カテゴリ
           ,acnt_attribute1                                       -- 銀行口座予備1
           ,acnt_attribute2                                       -- 銀行口座予備2
           ,acnt_attribute3                                       -- 銀行口座予備3
           ,acnt_attribute4                                       -- 銀行口座予備4
           ,acnt_attribute5                                       -- 銀行口座予備5
           ,acnt_attribute6                                       -- 銀行口座予備6
           ,acnt_attribute7                                       -- 銀行口座予備7
           ,acnt_attribute8                                       -- 銀行口座予備8
           ,acnt_attribute9                                       -- 銀行口座予備9
           ,acnt_attribute10                                      -- 銀行口座予備10
           ,acnt_attribute11                                      -- 銀行口座予備11
           ,acnt_attribute12                                      -- 銀行口座予備12
           ,acnt_attribute13                                      -- 銀行口座予備13
           ,acnt_attribute14                                      -- 銀行口座予備14
           ,acnt_attribute15                                      -- 銀行口座予備15
           ,acnt_cash_clearing_ccid                               -- 銀行口座資金決済勘定科目ID
           ,acnt_bank_charges_ccid                                -- 銀行口座銀行手数料勘定科目ID
           ,acnt_bank_errors_ccid                                 -- 銀行口座銀行エラー勘定科目ID
           ,acnt_account_holder_name                              -- 銀行口座口座名義人名
           ,acnt_account_holder_name_alt                          -- 銀行口座口座名義人名（カナ）
           ,uses_start_date                                       -- 銀行口座割当開始日
           ,uses_end_date                                         -- 銀行口座割当終了日
           ,uses_attribute_category                               -- 銀行口座割当予備カテゴリ
           ,uses_attribute1                                       -- 銀行口座割当予備1
           ,uses_attribute2                                       -- 銀行口座割当予備2
           ,uses_attribute3                                       -- 銀行口座割当予備3
           ,uses_attribute4                                       -- 銀行口座割当予備4
           ,uses_attribute5                                       -- 銀行口座割当予備5
           ,uses_attribute6                                       -- 銀行口座割当予備6
           ,uses_attribute7                                       -- 銀行口座割当予備7
           ,uses_attribute8                                       -- 銀行口座割当予備8
           ,uses_attribute9                                       -- 銀行口座割当予備9
           ,uses_attribute10                                      -- 銀行口座割当予備10
           ,uses_attribute11                                      -- 銀行口座割当予備11
           ,uses_attribute12                                      -- 銀行口座割当予備12
           ,uses_attribute13                                      -- 銀行口座割当予備13
           ,uses_attribute14                                      -- 銀行口座割当予備14
           ,uses_attribute15                                      -- 銀行口座割当予備15
           ,status_flag                                           -- ステータスフラグ
          ) VALUES (
            gn_v_interface_id                                     -- 仕入先インターフェースID(連番)
           ,cv_insert_flg                                         -- 追加更新フラグ
           ,gt_i_people_data(ln_loop_cnt).vendor_id               -- 仕入先仕入先ID
           ,SUBSTRB(gt_i_people_data(ln_loop_cnt).per_information18
           || gt_i_people_data(ln_loop_cnt).per_information19 || '／'
           || TO_MULTI_BYTE(gt_i_people_data(ln_loop_cnt).employee_number),1,80)   -- 仕入先仕入先名
           ,SUBSTRB(cv_9000 || gt_i_people_data(ln_loop_cnt).employee_number,1,30) -- 仕入先仕入先番号
           ,SUBSTRB(gt_i_people_data(ln_loop_cnt).person_id,1,22) -- 仕入先従業員ID
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify start by Y.Kuboshima
--           ,gv_v_vendor_type                                      -- 仕入先仕入先タイプ
           ,gv_vendor_type                                        -- 仕入先仕入先タイプ
-- 2010/04/12 Ver1.5 E_本稼動_02240 modify end by Y.Kuboshima
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先支払条件
--           ,NULL                                                  -- 仕入先支払グループコード
           -- 仕入先サイト支払条件と同値をセット
           ,gv_terms_id                                           -- 仕入先支払条件
           -- 仕入先サイト支払グループコードと同値をセット
           ,lv_pay_group                                          -- 仕入先支払グループコード
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,NULL                                                  -- 仕入先請求限度額
           ,NULL                                                  -- 仕入先負債勘定科目ID
           ,NULL                                                  -- 仕入先前払／仮払金勘定科目ID
           ,NULL                                                  -- 仕入先無効日
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先中小法人フラグ
--           ,NULL                                                  -- 仕入先入金確認フラグ
           -- 固定値：「N」をセット
           ,cv_n_flag                                             -- 仕入先中小法人フラグ
           -- 固定値：「Y」をセット
           ,cv_y_flag                                             -- 仕入先入金確認フラグ
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,NULL                                                  -- 仕入先予備カテゴリ
           ,NULL                                                  -- 仕入先予備1
           ,NULL                                                  -- 仕入先予備2
           ,NULL                                                  -- 仕入先予備3
           ,NULL                                                  -- 仕入先予備4
           ,NULL                                                  -- 仕入先予備5
           ,NULL                                                  -- 仕入先予備6
           ,NULL                                                  -- 仕入先予備7
           ,NULL                                                  -- 仕入先予備8
           ,NULL                                                  -- 仕入先予備9
           ,NULL                                                  -- 仕入先予備10
           ,NULL                                                  -- 仕入先予備11
           ,NULL                                                  -- 仕入先予備12
           ,NULL                                                  -- 仕入先予備13
           ,NULL                                                  -- 仕入先予備14
           ,NULL                                                  -- 仕入先予備15
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先源泉徴収税使用フラグ
           -- 会計オプション：控除対象消費税使用可をセット
           ,gv_non_recover_tax_flag                               -- 仕入先源泉徴収税使用フラグ
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,NULL                                                  -- 仕入先仕入先カナ名称
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先請求税自動計算端数処理規
--           ,NULL                                                  -- 仕入先請求税自動計算計算レベル
--           ,NULL                                                  -- 仕入先請求税自動計算上書きの許
--           ,NULL                                                  -- 仕入先銀行手数料負担者
           -- 会計オプション：端数処理規則をセット
           ,gv_tax_rounding_rule                                  -- 仕入先請求税自動計算端数処理規
           -- 買掛/未払金オプション：計算レベルをセット
           ,gv_auto_tax_calc_flag                                 -- 仕入先請求税自動計算計算レベル
           -- 買掛/未払金オプション：計算レベル上書きの許可をセット
           ,gv_auto_tax_calc_override                             -- 仕入先請求税自動計算上書きの許
           -- 固定値：「I」をセット
           ,gv_s_bank_charge_new                                  -- 仕入先銀行手数料負担者
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,NULL                                                  -- 仕入先サイト仕入先サイトID
           ,cv_site_code_comp                                     -- 仕入先サイト仕入先サイト名
           ,gv_address_nm1                                        -- 仕入先サイト所在地1
           ,gv_address_nm2                                        -- 仕入先サイト所在地2
           ,NULL                                                  -- 仕入先サイト所在地3
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先サイト住所・郡市区
--           ,NULL                                                  -- 仕入先サイト住所・都道府県
--           ,NULL                                                  -- 仕入先サイト住所・郵便番号
           -- 固定値「*」をセット
           ,cv_dummy                                              -- 仕入先サイト住所・郡市区
           -- 固定値「*」をセット
           ,cv_dummy                                              -- 仕入先サイト住所・都道府県
           -- 固定値「*」をセット
           ,cv_dummy                                              -- 仕入先サイト住所・郵便番号
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,NULL                                                  -- 仕入先サイト住所・州
           ,gv_country                                            -- 仕入先サイト国
           ,NULL                                                  -- 仕入先サイト市外局番
           ,NULL                                                  -- 仕入先サイト電話番号
           ,NULL                                                  -- 仕入先サイトFAX
           ,NULL                                                  -- 仕入先サイトFAX市外局番
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先サイト支払方法
           -- 固定値「WIRE」をセット
           ,gv_pay_method_cd                                      -- 仕入先サイト支払方法
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,NULL                                                  -- 仕入先サイト口座名称
           ,NULL                                                  -- 仕入先サイト口座番号
           ,NULL                                                  -- 仕入先サイト銀行コード
           ,NULL                                                  -- 仕入先サイト預金種別
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先サイト請求書税金コード
           -- 固定値「1205」をセット
           ,gv_site_vat_cd                                        -- 仕入先サイト請求書税金コード
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,NULL                                                  -- 仕入先サイト配分セットID
           ,TO_NUMBER(gv_accts_pay_ccid)                          -- 仕入先サイト負債勘定科目ID
           ,TO_NUMBER(gv_prepay_ccid)                             -- 仕入先サイト前払／仮払金勘定科
           ,lv_pay_group                                          -- 仕入先サイト支払グループコード
           ,gv_terms_id                                           -- 仕入先サイト支払条件
           ,NULL                                                  -- 仕入先サイト請求限度額
           ,TO_CHAR(gn_org_id)                                    -- 仕入先サイト予備カテゴリ
           ,NULL                                                  -- 仕入先サイト予備1
           ,NULL                                                  -- 仕入先サイト予備2
           ,NULL                                                  -- 仕入先サイト予備3
           ,NULL                                                  -- 仕入先サイト予備4
           ,gt_i_people_data(ln_loop_cnt).ass_attribute3          -- 仕入先サイト予備5
           ,NULL                                                  -- 仕入先サイト予備6
           ,NULL                                                  -- 仕入先サイト予備7
           ,NULL                                                  -- 仕入先サイト予備8
           ,NULL                                                  -- 仕入先サイト予備9
           ,NULL                                                  -- 仕入先サイト予備10
           ,NULL                                                  -- 仕入先サイト予備11
           ,NULL                                                  -- 仕入先サイト予備12
           ,NULL                                                  -- 仕入先サイト予備13
           ,NULL                                                  -- 仕入先サイト予備14
           ,NULL                                                  -- 仕入先サイト予備15
           ,NULL                                                  -- 仕入先サイト銀行支店コード
           ,NULL                                                  -- 仕入先サイト所在地4
           ,NULL                                                  -- 仕入先サイト郡
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先サイト源泉徴収税使用フラ
           -- 会計オプション：控除対象消費税使用可をセット
           ,gv_non_recover_tax_flag                               -- 仕入先サイト源泉徴収税使用フラ
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,NULL                                                  -- 仕入先サイト源泉徴収税グループ
           ,NULL                                                  -- 仕入先サイト仕入先サイト名（カ
           ,NULL                                                  -- 仕入先サイト住所カナ
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先サイト請求税自動計算端数
--           ,NULL                                                  -- 仕入先サイト請求税自動計算計算
--           ,NULL                                                  -- 仕入先サイト請求税自動計算上書
           -- 会計オプション：端数処理規則をセット
           ,gv_tax_rounding_rule                                  -- 仕入先サイト請求税自動計算端数
           -- 買掛/未払金オプション：計算レベルをセット
           ,gv_auto_tax_calc_flag                                 -- 仕入先サイト請求税自動計算計算
           -- 買掛/未払金オプション：計算レベル上書きの許可をセット
           ,gv_auto_tax_calc_override                             -- 仕入先サイト請求税自動計算上書
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,gv_s_bank_charge_new                                  -- 仕入先サイト銀行手数料負担者
           ,NULL                                                  -- 仕入先サイト銀行支店タイプ
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先サイトRTS取引からデビッ
           -- 固定値：「N」をセット
           ,cv_n_flag                                             -- 仕入先サイトRTS取引からデビッ
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,NULL                                                  -- 仕入先サイト仕入先通知方法
           ,NULL                                                  -- 仕入先サイトEメールアドレス
-- 2009/10/02 Ver1.4 modify start by Yutaka.Kuboshima
--           ,NULL                                                  -- 仕入先サイト主支払サイトフラグ
--           ,NULL                                                  -- 仕入先サイト購買フラグ
           -- 固定値：「N」をセット
           ,cv_n_flag                                             -- 仕入先サイト主支払サイトフラグ
           -- 固定値：「N」をセット
           ,cv_n_flag                                             -- 仕入先サイト購買フラグ
-- 2009/10/02 Ver1.4 modify end by Yutaka.Kuboshima
           ,gv_bank_number                                        -- 銀行口座銀行支店コード
           ,gv_bank_num                                           -- 銀行口座銀行コード
           ,SUBSTRB(gv_bank_nm || '/' || gv_shiten_nm,1,80)       -- 銀行口座口座名称
           ,gv_account_num                                        -- 銀行口座口座番号
           ,gv_currency_cd                                        -- 銀行口座通貨コード
           ,NULL                                                  -- 銀行口座摘要
           ,NULL                                                  -- 銀行口座現預金勘定科目ID
           ,gv_account_type                                       -- 銀行口座預金種別
           ,NULL                                                  -- 銀行口座予備カテゴリ
           ,NULL                                                  -- 銀行口座予備1
           ,NULL                                                  -- 銀行口座予備2
           ,NULL                                                  -- 銀行口座予備3
           ,NULL                                                  -- 銀行口座予備4
           ,NULL                                                  -- 銀行口座予備5
           ,NULL                                                  -- 銀行口座予備6
           ,NULL                                                  -- 銀行口座予備7
           ,NULL                                                  -- 銀行口座予備8
           ,NULL                                                  -- 銀行口座予備9
           ,NULL                                                  -- 銀行口座予備10
           ,NULL                                                  -- 銀行口座予備11
           ,NULL                                                  -- 銀行口座予備12
           ,NULL                                                  -- 銀行口座予備13
           ,NULL                                                  -- 銀行口座予備14
           ,NULL                                                  -- 銀行口座予備15
           ,NULL                                                  -- 銀行口座資金決済勘定科目ID
           ,NULL                                                  -- 銀行口座銀行手数料勘定科目ID
           ,NULL                                                  -- 銀行口座銀行エラー勘定科目ID
           ,gv_holder_nm                                          -- 銀行口座口座名義人名
           ,gv_holder_alt_nm                                      -- 銀行口座口座名義人名(カナ)
           ,gd_process_date                                       -- 銀行口座割当開始日
           ,NULL                                                  -- 銀行口座割当終了日
           ,NULL                                                  -- 銀行口座割当予備カテゴリ
           ,NULL                                                  -- 銀行口座割当予備1
           ,NULL                                                  -- 銀行口座割当予備2
           ,NULL                                                  -- 銀行口座割当予備3
           ,NULL                                                  -- 銀行口座割当予備4
           ,NULL                                                  -- 銀行口座割当予備5
           ,NULL                                                  -- 銀行口座割当予備6
           ,NULL                                                  -- 銀行口座割当予備7
           ,NULL                                                  -- 銀行口座割当予備8
           ,NULL                                                  -- 銀行口座割当予備9
           ,NULL                                                  -- 銀行口座割当予備10
           ,NULL                                                  -- 銀行口座割当予備11
           ,NULL                                                  -- 銀行口座割当予備12
           ,NULL                                                  -- 銀行口座割当予備13
           ,NULL                                                  -- 銀行口座割当予備14
           ,NULL                                                  -- 銀行口座割当予備15
           ,cv_status_flg                                         -- ステータスフラグ
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                            ,iv_name         => cv_msg_00221             -- 仕入先従業員情報中間I/Fテーブル登録エラー
                            ,iv_token_name1  => cv_tkn_err_msg           -- トークン(NG_PROFILE)
                            ,iv_token_value1 => SQLERRM                  -- プロファイル名(所在地2)
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
-- 2009/07/17 Ver1.3 modify start by Yutaka.Kuboshima
        gn_normal_cnt := gn_normal_cnt + 1;
-- Ver1.2  2009/04/21  Del  障害：T1_0255対応  シーケンスを取得するため削除
--        gn_v_interface_id := gn_v_interface_id + 1;
-- End Ver1.2
      END IF;
      lv_employee_number := gt_i_people_data(ln_loop_cnt).employee_number;
    END LOOP i_out_loop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--
--#####################################  固定部 END   ##########################################
--
  END add_output_csv;
--
  /**********************************************************************************
   * Procedure Name   : delete_table
   * Description      : 仕入先従業員情報中間I/Fテーブルデータ削除プロシージャ(A-2)
   ***********************************************************************************/
  PROCEDURE delete_table(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_table';       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
-- Ver1.2  2009/04/21  Mod  障害：T1_0255対応  会計とバッティングしないよう条件を追加
--      DELETE FROM xx03_vendors_interface;
      DELETE FROM xx03_vendors_interface
      WHERE  vndr_vendor_type_lkup_code = gv_vendor_type;
-- End Ver1.2
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                        ,iv_name         => cv_msg_00012             -- データ削除エラー
                        ,iv_token_name1  => cv_tkn_table             -- トークン(NG_TABLE)
                        ,iv_token_value1 => cv_tkn_table_nm          -- テーブル名(仕入先従業員情報中間I/Fテーブル)
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
--#####################################  固定部 END   ##########################################
--
  END delete_table;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_warn_cnt   := 0;
    gn_error_cnt  := 0;
    gv_warn_flg   := '0';
-- Ver1.2  2009/04/21  Del  障害：T1_0255対応  シーケンスを取得するため削除
--    -- インターフェースID
--    gn_v_interface_id := 1;
-- End Ver1.2
    --
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --
    -- =============================================================
    --  初期処理プロシージャ(A-1)
    -- =============================================================
    init(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
--2009/07/17 Ver1.3 add start by Yutaka.Kuboshima
    -- =============================================================
    --  仕入先従業員情報中間I/Fテーブルデータ削除プロシージャ(A-2)
    -- =============================================================
    delete_table(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--2009/07/17 Ver1.3 add end by Yutaka.Kuboshima
    -- =============================================================
    --  新規登録以外の社員データ取得プロシージャ(A-3)
    -- =============================================================
    get_u_people_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =============================================================
    --  中間I/Fテーブルデータ登録(更新)プロシージャ(A-7)
    -- =============================================================
    IF (gn_target_update_cnt > 0) THEN
      update_output_csv(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- =============================================================
    --  新規登録の社員データ取得プロシージャ(A-8)
    -- =============================================================
    get_i_people_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =============================================================
    --  中間I/Fテーブルデータ登録(新規登録)プロシージャ(A-10)
    -- =============================================================
    IF (gn_target_add_cnt > 0) THEN
      add_output_csv(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- =============================================================
    --  仕入先従業員情報中間I/Fテーブルデータ削除プロシージャ(A-10)
    -- =============================================================
-- 2009/07/17 Ver1.3 delete start by Yutaka.Kuboshima
--    delete_table(
--       lv_errbuf             -- エラー・メッセージ           --# 固定 #
--      ,lv_retcode            -- リターン・コード             --# 固定 #
--      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
-- 2009/07/17 Ver1.3 delete end by Yutaka.Kuboshima
    --
    -- =====================================================
    --  終了処理プロシージャ(A-11)
    -- =====================================================
    -- CSVファイルをクローズする
-- 2009/07/17 Ver1.3 delete start by Yutaka.Kuboshima
--    UTL_FILE.FCLOSE(gf_file_hand);
-- 2009/07/17 Ver1.3 delete end by Yutaka.Kuboshima

--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf   -- エラー・メッセージ            --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      IF (gv_warn_flg = '1') THEN
        -- 空行挿入(警告メッセージとエラーメッセージの間)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        -- 空行挿入(警告メッセージとエラーメッセージの間)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      -- 空行挿入(エラーメッセージと件数の間)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    ELSE
      IF (gv_warn_flg = '1') THEN
        --警告の場合、リターン・コードに警告をセットする
        lv_retcode := cv_status_warn;
        -- 空行挿入(警告メッセージと件数の間)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --CSVファイルがクローズされていなかった場合、クローズする
-- 2009/007/16 Ver1.3 delete start by Yutaka.Kuboshima
--    IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
--      UTL_FILE.FCLOSE(gf_file_hand);
--    END IF;
-- 2009/007/16 Ver1.3 delete end by Yutaka.Kuboshima
    --
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCMM002A05C;
/
