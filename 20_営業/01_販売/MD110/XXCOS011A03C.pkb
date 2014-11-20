CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS011A03C (body)
 * Description      : 納品予定データの作成を行う
 * MD.050           : 納品予定データ作成 (MD050_COS_011_A03)
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  check_param            パラメータチェック(A-1)
 *  init                   初期処理(A-2)
 *  get_manual_order       手入力データ登録(A-3)
 *  output_header          ファイル初期処理(A-4)
 *  input_edi_order        EDI受注情報抽出(A-5)
 *  format_data            データ成形(A-7)
 *  edit_data              データ編集(A-6)
 *  output_data            ファイル出力(A-8)
 *  output_footer          ファイル終了処理(A-9)
 *  update_edi_order       EDI受注情報更新(A-10)
 *  generate_edi_trans     EDI納品予定送信ファイル作成(A-3...A-10)
 *  release_edi_trans      EDI納品予定送信済み解除(A-12)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   H.Fujimoto       新規作成
 *  2009/02/20    1.1   H.Fujimoto       結合不具合No.106
 *  2009/02/24    1.2   H.Fujimoto       結合不具合No.126,134
 *  2009/02/25    1.3   H.Fujimoto       結合不具合No.135
 *  2009/02/25    1.4   H.Fujimoto       結合不具合No.141
 *  2009/02/27    1.5   H.Fujimoto       結合不具合No.146,149
 *  2009/03/04    1.6   H.Fujimoto       結合不具合No.154
 *  2009/04/28    1.7   K.Kiriu          [T1_0756]レコード長変更対応
 *  2009/05/12    1.8   K.Kiriu          [T1_0677]ラベル作成対応
 *                                       [T1_0937]削除時の件数カウント対応
 *  2009/05/22    1.9   M.Sano           [T1_1073]ダミー品目時の数量項目変更対応
 *  2009/06/11    1.10  T.Kitajima       [T1_1348]行Noの結合条件変更
 *  2009/06/12    1.10  T.Kitajima       [T1_1350]メインカーソルソート条件変更
 *  2009/06/12    1.10  T.Kitajima       [T1_1356]ファイルNo→顧客アドオン.EDI伝送追番
 *  2009/06/12    1.10  T.Kitajima       [T1_1357]伝票番号数値チェック
 *  2009/06/12    1.10  T.Kitajima       [T1_1358]定番特売区分0→00,1→01,2→02
 *  2009/06/19    1.10  T.Kitajima       [T1_1436]受注データ、営業単位絞込み追加
 *  2009/06/24    1.10  T.Kitajima       [T1_1359]数量換算対応
 *  2009/07/08    1.10  M.Sano           [T1_1357]レビュー指摘事項対応
 *  2009/07/10    1.10  N.Maeda          [000063]情報区分によるデータ作成対象の制御追加
 *                                       [000064]受注DFF項目追加に伴う、連携項目追加
 *  2009/07/13    1.10  N.Maeda          [T1_1359]レビュー指摘事項対応
 *  2009/07/21    1.11  K.Kiriu          [0000644]原価金額の端数処理対応
 *  2009/07/24    1.11  K.Kiriu          [T1_1359]レビュー指摘事項対応
 *  2009/08/10    1.11  K.Kiriu          [0000438]指摘事項対応
 *  2009/09/03    1.12  N.Maeda          [0001065]『XXCOS_HEAD_PROD_CLASS_V』のMainSQL取込
 *  2009/09/25    1.13  N.Maeda          [0001306]伝票計集計単位修正
 *                                       [0001307]出荷数量取得元テーブル修正
 *  2009/10/05    1.14  N.Maeda          [0001464]受注明細分割による影響対応
 *  2010/03/01    1.15  S.Karikomi       [E_本稼働_01635]ヘッダ出力拠点修正
 *                                                       件数カウント単位の同期対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  global_data_check_expt    EXCEPTION;      -- データチェック時のエラー
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ロックエラー
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
  global_number_err_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_number_err_expt, -6502 );
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOS011A03C'; -- パッケージ名
--
  cv_application        CONSTANT VARCHAR2(5)   := 'XXCOS';        -- アプリケーション名
  -- プロファイル
  cv_prf_if_header      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_HEADER';            -- XXCCP:IFレコード区分_ヘッダ
  cv_prf_if_data        CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_DATA';              -- XXCCP:IFレコード区分_データ
  cv_prf_if_footer      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_FOOTER';            -- XXCCP:IFレコード区分_フッタ
  cv_prf_utl_m_line     CONSTANT VARCHAR2(50)  := 'XXCOS1_UTL_MAX_LINESIZE';     -- XXCOS:UTL_MAX行サイズ
  cv_prf_outbound_d     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_OUTBOUND_OM_DIR';  -- XXCOS:EDI受注系アウトバウンド用ディレクトリパス
  cv_prf_company_name   CONSTANT VARCHAR2(50)  := 'XXCOS1_COMPANY_NAME';         -- XXCOS:会社名
  cv_prf_company_kana   CONSTANT VARCHAR2(50)  := 'XXCOS1_COMPANY_NAME_KANA';    -- XXCOS:会社名カナ
  cv_prf_case_uom_code  CONSTANT VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';        -- XXCOS:ケース単位コード
  cv_prf_ball_uom_code  CONSTANT VARCHAR2(50)  := 'XXCOS1_BALL_UOM_CODE';        -- XXCOS:ボール単位コード
  cv_prf_organization   CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';    -- XXCOI:在庫組織コード
  cv_prf_max_date       CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';             -- XXCOS:MAX日付
  cv_prf_bks_id         CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';            -- GL会計帳簿ID
  cv_prf_org_id         CONSTANT VARCHAR2(50)  := 'ORG_ID';                      -- MO:営業単位
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
  ct_item_div_h         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ITEM_DIV_H'; -- XXCOS1:本社製品区分
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
-- 2009/05/22 Ver1.9 Add Start
  cv_prf_dum_stock_out  CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_DUMMY_STOCK_OUT';  -- XXCOS:EDI納品予定ダミー欠品区分
-- 2009/05/22 Ver1.9 Add End
  -- メッセージコード
  cv_msg_param_null     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';  -- 必須入力パラメータ未設定エラーメッセージ
  cv_msg_param_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00019';  -- 入力パラメータ不正エラーメッセージ
  cv_msg_date_reverse   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00005';  -- 日付逆転エラーメッセージ
  cv_msg_prf_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- プロファイル取得エラーメッセージ
  cv_msg_mast_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';  -- マスタチェックエラーメッセージ
  cv_msg_file_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00040';  -- IFファイルレイアウト定義情報取得エラーメッセージ
  cv_msg_org_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00091';  -- 在庫組織ID取得エラーメッセージ
  cv_msg_com_fnuc_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00037';  -- EDI共通関数エラーメッセージ
  cv_msg_file_o_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00009';  -- ファイルオープンエラーメッセージ
  cv_msg_base_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00035';  -- 拠点情報取得エラーメッセージ
  cv_msg_chain_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00036';  -- チェーン店情報取得エラーメッセージ
  cv_msg_lock_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ロックエラーメッセージ
  cv_msg_data_get_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';  -- データ抽出エラーメッセージ
  cv_msg_no_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- 対象データなしメッセージ
  cv_msg_product_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12253';  -- 商品コードエラーメッセージ
  cv_msg_out_inf_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00038';  -- 出力情報編集エラーメッセージ
  cv_msg_data_upd_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';  -- データ更新エラーメッセージ
  cv_msg_param1         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12251';  -- パラメータ出力１メッセージ
  cv_msg_param2         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12264';  -- パラメータ出力１メッセージ
  cv_msg_param3         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12252';  -- パラメータ出力２メッセージ
  -- メッセージ用文字列
  cv_msg_tkn_param1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12254';  -- 作成区分
  cv_msg_tkn_param2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12255';  -- EDIチェーン店コード
  cv_msg_tkn_param3     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00109';  -- ファイル名
  cv_msg_tkn_param4     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12256';  -- EDI伝送追番(ファイル名用)
  cv_msg_tkn_param5     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12257';  -- 店舗納品日From
  cv_msg_tkn_param6     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12258';  -- 店舗納品日To
  cv_msg_tkn_param7     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12259';  -- 処理日
  cv_msg_tkn_param8     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12260';  -- 処理時刻
  cv_msg_tkn_param9     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12262';  -- センター納品日
  cv_msg_tkn_prf1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00104';  -- XXCCP:IFレコード区分_ヘッダ
  cv_msg_tkn_prf2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00105';  -- XXCCP:IFレコード区分_データ
  cv_msg_tkn_prf3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00106';  -- XXCCP:IFレコード区分_フッタ
  cv_msg_tkn_prf4       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00099';  -- XXCOS:UTL_MAX行サイズ
  cv_msg_tkn_prf5       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00145';  -- XXCOS:EDI受注系アウトバウンド用ディレクトリパス
  cv_msg_tkn_prf6       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00058';  -- XXCOS:会社名
  cv_msg_tkn_prf7       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00098';  -- XXCOS:会社名カナ
  cv_msg_tkn_prf8       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00057';  -- XXCOS:ケース単位コード
  cv_msg_tkn_prf9       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00059';  -- XXCOS:ボール単位コード
  cv_msg_tkn_prf10      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';  -- XXCOI:在庫組織コード
  cv_msg_tkn_prf11      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';  -- XXCOS:MAX日付
  cv_msg_tkn_prf12      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';  -- GL会計帳簿ID
  cv_msg_tkn_prf13      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';  -- 営業単位
-- 2009/05/22 Ver1.9 Add Start
  cv_msg_tkn_prf14      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12266';  -- XXCOS:EDI納品予定ダミー欠品区分
-- 2009/05/22 Ver1.9 Add End
  cv_msg_tkn_column1    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12261';  -- データ種コード
  cv_msg_l_meaning2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12263';  -- クイックコード取得条件(EDI媒体区分)
  cv_msg_tkn_column2    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00110';  -- EDI媒体区分
  cv_msg_tkn_tbl1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';  -- クイックコード
  cv_msg_tkn_tbl2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00114';  -- EDIヘッダ情報テーブル
  cv_msg_tkn_tbl3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00115';  -- EDI明細情報テーブル
  cv_msg_tkn_layout     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00071';  -- 受注系項目レイアウト
  cv_msg_file_nmae      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00044';  -- ファイル名出力
/* 2009/05/12 Ver1.8 Add Start */
  cv_msg_tkn_param10    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12265';  -- EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Add End   */
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
  cv_msg_slip_no_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12267';  -- 伝票番号数値エラー
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
  cv_msg_category_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12954';     --カテゴリセットID取得エラーメッセージ
  cv_msg_item_div_h     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12955';     --本社商品区分
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
  cv_get_order_source_id_err CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12268';
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
  -- トークンコード
  cv_tkn_in_param       CONSTANT VARCHAR2(8)   := 'IN_PARAM';          -- 入力パラメータ名
  cv_tkn_date_from      CONSTANT VARCHAR2(9)   := 'DATE_FROM';         -- 日付期間チェックの開始日
  cv_tkn_date_to        CONSTANT VARCHAR2(7)   := 'DATE_TO';           -- 日付期間チェックの終了日
  cv_tkn_profile        CONSTANT VARCHAR2(7)   := 'PROFILE';           -- プロファイル名
  cv_tkn_column         CONSTANT VARCHAR2(6)   := 'COLMUN';            -- 項目名
  cv_tkn_table          CONSTANT VARCHAR2(5)   := 'TABLE';             -- テーブル名（論理名）
  cv_tkn_layout         CONSTANT VARCHAR2(6)   := 'LAYOUT';            -- ファイル定義レイアウト名
  cv_tkn_org_code       CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';      -- 在庫組織コード
  cv_tkn_err_msg        CONSTANT VARCHAR2(6)   := 'ERRMSG';            -- 共通関数のエラーメッセージ
  cv_tkn_file_name      CONSTANT VARCHAR2(9)   := 'FILE_NAME';         -- 納品予定ファイル名
  cv_tkn_code           CONSTANT VARCHAR2(4)   := 'CODE';              -- 拠点コード
  cv_tkn_chain_code     CONSTANT VARCHAR2(15)  := 'CHAIN_SHOP_CODE';   -- チェーン店コード
  cv_tkn_item_code      CONSTANT VARCHAR2(9)   := 'ITEM_CODE';         -- 品目コード
  cv_tkn_table_name     CONSTANT VARCHAR2(10)  := 'TABLE_NAME';        -- テーブル名（論理名）
  cv_tkn_key_data       CONSTANT VARCHAR2(8)   := 'KEY_DATA';          -- キー情報
  cv_tkn_count          CONSTANT VARCHAR2(5)   := 'COUNT';             -- 対象件数
  cv_tkn_param01        CONSTANT VARCHAR2(7)   := 'PARAME1';           -- 入力パラメータ値
  cv_tkn_param02        CONSTANT VARCHAR2(7)   := 'PARAME2';           -- 入力パラメータ値
  cv_tkn_param03        CONSTANT VARCHAR2(7)   := 'PARAME3';           -- 入力パラメータ値
  cv_tkn_param04        CONSTANT VARCHAR2(7)   := 'PARAME4';           -- 入力パラメータ値
  cv_tkn_param05        CONSTANT VARCHAR2(7)   := 'PARAME5';           -- 入力パラメータ値
  cv_tkn_param06        CONSTANT VARCHAR2(7)   := 'PARAME6';           -- 入力パラメータ値
  cv_tkn_param07        CONSTANT VARCHAR2(7)   := 'PARAME7';           -- 入力パラメータ値
  cv_tkn_param08        CONSTANT VARCHAR2(7)   := 'PARAME8';           -- 入力パラメータ値
  cv_tkn_param09        CONSTANT VARCHAR2(7)   := 'PARAME9';           -- 入力パラメータ値
  cv_tkn_param10        CONSTANT VARCHAR2(8)   := 'PARAME10';          -- 入力パラメータ値
  cv_tkn_param11        CONSTANT VARCHAR2(8)   := 'PARAME11';          -- 入力パラメータ値
/* 2009/05/12 Ver1.8 Add Start */
  cv_tkn_param12        CONSTANT VARCHAR2(8)   := 'PARAME12';          -- 入力パラメータ値
/* 2009/05/12 Ver1.8 Add End   */
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
  cv_order_source            CONSTANT VARCHAR2(20) := 'ORDER_SOURCE';
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
  -- 日付
  cd_sysdate            CONSTANT DATE          := SYSDATE;                            -- システム日付
  cd_process_date       CONSTANT DATE          := xxccp_common_pkg2.get_process_date; -- 業務処理日
  -- データ取得/編集用固定値
  cv_cust_code_base     CONSTANT VARCHAR2(1)   := '1';                 -- 顧客区分:拠点
  cv_cust_code_cust     CONSTANT VARCHAR2(2)   := '10';                -- 顧客区分:顧客
  cv_cust_code_chain    CONSTANT VARCHAR2(2)   := '18';                -- 顧客区分:チェーン店
  cv_cust_status_30     CONSTANT VARCHAR2(2)   := '30';                -- 顧客ステータス:承認済
  cv_cust_status_40     CONSTANT VARCHAR2(2)   := '40';                -- 顧客ステータス:顧客
  cv_cust_status_90     CONSTANT VARCHAR2(2)   := '90';                -- 顧客ステータス:中止決裁済
  cv_status_a           CONSTANT VARCHAR2(1)   := 'A';                 -- ステータス:顧客有効
  cv_tukzik_div_tuk     CONSTANT VARCHAR2(2)   := '11';                -- 通過在庫型区分:センター納品(通過型・受注)
  cv_tukzik_div_zik     CONSTANT VARCHAR2(2)   := '12';                -- 通過在庫型区分:センター納品(在庫型・受注)
  cv_tukzik_div_tnp     CONSTANT VARCHAR2(2)   := '24';                -- 通過在庫型区分:店舗納品
  cv_data_type_edi      CONSTANT VARCHAR2(2)   := '11';                -- データ種コード:受注EDI
  cv_medium_class_edi   CONSTANT VARCHAR2(2)   := '00';                -- 媒体区分:EDI
  cv_medium_class_mnl   CONSTANT VARCHAR2(2)   := '01';                -- 媒体区分:手入力
  cv_position           CONSTANT VARCHAR2(3)   := '002';               -- 職位:支店長
  cv_stockout_class_00  CONSTANT VARCHAR2(2)   := '00';                -- 欠品区分:欠品なし
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
--  cv_sale_class_all     CONSTANT VARCHAR2(1)   := '0';                 -- 定番特売区分:両方
  cv_sale_class_all     CONSTANT VARCHAR2(2)   := '00';                -- 定番特売区分:両方
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
  cv_entity_code_line   CONSTANT VARCHAR2(4)   := 'LINE';              -- エンティティコード:LINE
  cv_reason_type        CONSTANT VARCHAR2(11)  := 'CANCEL_CODE';       -- 事由タイプ:取消
  cv_err_reason_code    CONSTANT VARCHAR2(2)   := 'XX';                -- エラー取消事由
  -- クイックコードタイプ
  cv_edi_shipping_exp_t CONSTANT VARCHAR2(28)  := 'XXCOS1_EDI_SHIPPING_EXP_TYPE';  -- 作成区分
  cv_edi_media_class_t  CONSTANT VARCHAR2(22)  := 'XXCOS1_EDI_MEDIA_CLASS';        -- EDI媒体区分
  cv_data_type_code_t   CONSTANT VARCHAR2(21)  := 'XXCOS1_DATA_TYPE_CODE';         -- データ種
  cv_edi_item_err_t     CONSTANT VARCHAR2(24)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';      -- EDI品目エラータイプ
  cv_edi_create_class   CONSTANT VARCHAR2(23)  := 'XXCOS1_EDI_CREATE_CLASS';       -- EDI作成元区分
  -- クイックコード
  cv_data_type_code_c   CONSTANT VARCHAR2(3)   := '040';               -- データ種(納品予定)
/* 2009/05/12 Ver1.8 Del Start */
/* 2009/02/27 Ver1.5 Add Start */
--  cv_data_type_code_l   CONSTANT VARCHAR2(3)   := '200';               -- データ種(納品予定(ラベル))
/* 2009/02/27 Ver1.5 Add  End  */
/* 2009/05/12 Ver1.8 Del  End  */
  cv_edi_create_class_c CONSTANT VARCHAR2(2)   := '10';                -- EDI作成元区分(受注)
  -- 作成区分
  cv_make_class_transe  CONSTANT VARCHAR2(1)   := '1';                 -- 送信
  cv_make_class_label   CONSTANT VARCHAR2(1)   := '2';                 -- ラベル作成
  cv_make_class_release CONSTANT VARCHAR2(1)   := '9';                 -- 解除
  -- その他固定値
  cv_date_format        CONSTANT VARCHAR2(8)   := 'YYYYMMDD';          -- 日付フォーマット(日)
  cv_time_format        CONSTANT VARCHAR2(8)   := 'HH24MISS';          -- 日付フォーマット(時間)
  cv_max_date_format    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        -- MAX日付フォーマット
  cv_0                  CONSTANT VARCHAR2(1)   := '0';                 -- 固定値:0(VARCHAR2)
  cn_0                  CONSTANT NUMBER        := 0;                   -- 固定値:0(NUMBER)
  cv_1                  CONSTANT VARCHAR2(1)   := '1';                 -- 固定値:1(VARCHAR2)
  cn_1                  CONSTANT NUMBER        := 1;                   -- 固定値:1(NUMBER)
  cv_2                  CONSTANT VARCHAR2(1)   := '2';                 -- 固定値:2
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                 -- 固定値:Y
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';                 -- 固定値:N
  cv_w                  CONSTANT VARCHAR2(1)   := 'W';                 -- 固定値:W
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
  ct_user_lang                    CONSTANT mtl_category_sets_tl.language%TYPE := USERENV('LANG'); --LANG
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
  -- データ編集共通関数用
  cv_medium_class             CONSTANT VARCHAR2(50)  := 'MEDIUM_CLASS';                  -- 媒体区分
  cv_data_type_code           CONSTANT VARCHAR2(50)  := 'DATA_TYPE_CODE';                -- データ種コード
  cv_file_no                  CONSTANT VARCHAR2(50)  := 'FILE_NO';                       -- ファイルNo
  cv_info_class               CONSTANT VARCHAR2(50)  := 'INFO_CLASS';                    -- 情報区分
  cv_process_date             CONSTANT VARCHAR2(50)  := 'PROCESS_DATE';                  -- 処理日
  cv_process_time             CONSTANT VARCHAR2(50)  := 'PROCESS_TIME';                  -- 処理時刻
  cv_base_code                CONSTANT VARCHAR2(50)  := 'BASE_CODE';                     -- 拠点(部門)コード
  cv_base_name                CONSTANT VARCHAR2(50)  := 'BASE_NAME';                     -- 拠点名(正式名)
  cv_base_name_alt            CONSTANT VARCHAR2(50)  := 'BASE_NAME_ALT';                 -- 拠点名(カナ)
  cv_edi_chain_code           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_CODE';                -- EDIチェーン店コード
  cv_edi_chain_name           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME';                -- EDIチェーン店名(漢字)
  cv_edi_chain_name_alt       CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME_ALT';            -- EDIチェーン店名(カナ)
  cv_chain_code               CONSTANT VARCHAR2(50)  := 'CHAIN_CODE';                    -- チェーン店コード
  cv_chain_name               CONSTANT VARCHAR2(50)  := 'CHAIN_NAME';                    -- チェーン店名(漢字)
  cv_chain_name_alt           CONSTANT VARCHAR2(50)  := 'CHAIN_NAME_ALT';                -- チェーン店名(カナ)
  cv_report_code              CONSTANT VARCHAR2(50)  := 'REPORT_CODE';                   -- 帳票コード
  cv_report_show_name         CONSTANT VARCHAR2(50)  := 'REPORT_SHOW_NAME';              -- 帳票表示名
  cv_cust_code                CONSTANT VARCHAR2(50)  := 'CUSTOMER_CODE';                 -- 顧客コード
  cv_cust_name                CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME';                 -- 顧客名(漢字)
  cv_cust_name_alt            CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME_ALT';             -- 顧客名(カナ)
  cv_comp_code                CONSTANT VARCHAR2(50)  := 'COMPANY_CODE';                  -- 社コード
  cv_comp_name                CONSTANT VARCHAR2(50)  := 'COMPANY_NAME';                  -- 社名(漢字)
  cv_comp_name_alt            CONSTANT VARCHAR2(50)  := 'COMPANY_NAME_ALT';              -- 社名(カナ)
  cv_shop_code                CONSTANT VARCHAR2(50)  := 'SHOP_CODE';                     -- 店コード
  cv_shop_name                CONSTANT VARCHAR2(50)  := 'SHOP_NAME';                     -- 店名(漢字)
  cv_shop_name_alt            CONSTANT VARCHAR2(50)  := 'SHOP_NAME_ALT';                 -- 店名(カナ)
  cv_delv_cent_code           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_CODE';          -- 納入センターコード
  cv_delv_cent_name           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME';          -- 納入センター名(漢字)
  cv_delv_cent_name_alt       CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME_ALT';      -- 納入先センター名(カナ)
  cv_order_date               CONSTANT VARCHAR2(50)  := 'ORDER_DATE';                    -- 発注日
  cv_cent_delv_date           CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_DATE';          -- センター納品日
  cv_result_delv_date         CONSTANT VARCHAR2(50)  := 'RESULT_DELIVERY_DATE';          -- 実納品日
  cv_shop_delv_date           CONSTANT VARCHAR2(50)  := 'SHOP_DELIVERY_DATE';            -- 店舗納品日
  cv_dc_date_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_DATE_EDI_DATA';   -- データ作成日(EDIデータ中)
  cv_dc_time_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_TIME_EDI_DATA';   -- データ作成時刻(EDIデータ中)
  cv_invc_class               CONSTANT VARCHAR2(50)  := 'INVOICE_CLASS';                 -- 伝票区分
  cv_small_classif_code       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_CODE';     -- 小分類コード
  cv_small_classif_name       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_NAME';     -- 小分類名
  cv_middle_classif_code      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_CODE';    -- 中分類コード
  cv_middle_classif_name      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_NAME';    -- 中分類名
  cv_big_classif_code         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_CODE';       -- 大分類コード
  cv_big_classif_name         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_NAME';       -- 大分類名
  cv_op_department_code       CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_DEPARTMENT_CODE';   -- 相手先部門コード
  cv_op_order_number          CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_ORDER_NUMBER';      -- 相手先発注番号
  cv_check_digit_class        CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT_CLASS';             -- チェックデジット有無区分
  cv_invc_number              CONSTANT VARCHAR2(50)  := 'INVOICE_NUMBER';                -- 伝票番号
  cv_check_digit              CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT';                   -- チェックデジット
  cv_close_date               CONSTANT VARCHAR2(50)  := 'CLOSE_DATE';                    -- 月限
  cv_order_no_ebs             CONSTANT VARCHAR2(50)  := 'ORDER_NO_EBS';                  -- 受注No(EBS)
  cv_ar_sale_class            CONSTANT VARCHAR2(50)  := 'AR_SALE_CLASS';                 -- 特売区分
  cv_delv_classe              CONSTANT VARCHAR2(50)  := 'DELIVERY_CLASSE';               -- 配送区分
  cv_opportunity_no           CONSTANT VARCHAR2(50)  := 'OPPORTUNITY_NO';                -- 便No
  cv_contact_to               CONSTANT VARCHAR2(50)  := 'CONTACT_TO';                    -- 連絡先
  cv_route_sales              CONSTANT VARCHAR2(50)  := 'ROUTE_SALES';                   -- ルートセールス
  cv_corporate_code           CONSTANT VARCHAR2(50)  := 'CORPORATE_CODE';                -- 法人コード
  cv_maker_name               CONSTANT VARCHAR2(50)  := 'MAKER_NAME';                    -- メーカー名
  cv_area_code                CONSTANT VARCHAR2(50)  := 'AREA_CODE';                     -- 地区コード
  cv_area_name                CONSTANT VARCHAR2(50)  := 'AREA_NAME';                     -- 地区名(漢字)
  cv_area_name_alt            CONSTANT VARCHAR2(50)  := 'AREA_NAME_ALT';                 -- 地区名(カナ)
  cv_vendor_code              CONSTANT VARCHAR2(50)  := 'VENDOR_CODE';                   -- 取引先コード
  cv_vendor_name              CONSTANT VARCHAR2(50)  := 'VENDOR_NAME';                   -- 取引先名(漢字)
  cv_vendor_name1_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME1_ALT';              -- 取引先名1(カナ)
  cv_vendor_name2_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME2_ALT';              -- 取引先名2(カナ)
  cv_vendor_tel               CONSTANT VARCHAR2(50)  := 'VENDOR_TEL';                    -- 取引先TEL
  cv_vendor_charge            CONSTANT VARCHAR2(50)  := 'VENDOR_CHARGE';                 -- 取引先担当者
  cv_vendor_address           CONSTANT VARCHAR2(50)  := 'VENDOR_ADDRESS';                -- 取引先住所(漢字)
  cv_delv_to_code_itouen      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_ITOUEN';        -- 届け先コード(伊藤園)
  cv_delv_to_code_chain       CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_CHAIN';         -- 届け先コード(チェーン店)
  cv_delv_to                  CONSTANT VARCHAR2(50)  := 'DELIVER_TO';                    -- 届け先(漢字)
  cv_delv_to1_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO1_ALT';               -- 届け先1(カナ)
  cv_delv_to2_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO2_ALT';               -- 届け先2(カナ)
  cv_delv_to_address          CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS';            -- 届け先住所(漢字)
  cv_delv_to_address_alt      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS_ALT';        -- 届け先住所(カナ)
  cv_delv_to_tel              CONSTANT VARCHAR2(50)  := 'DELIVER_TO_TEL';                -- 届け先TEL
  cv_bal_acc_code             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_CODE';         -- 帳合先コード
  cv_bal_acc_comp_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_COMPANY_CODE'; -- 帳合先社コード
  cv_bal_acc_shop_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_SHOP_CODE';    -- 帳合先店コード
  cv_bal_acc_name             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME';         -- 帳合先名(漢字)
  cv_bal_acc_name_alt         CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME_ALT';     -- 帳合先名(カナ)
  cv_bal_acc_address          CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS';      -- 帳合先住所(漢字)
  cv_bal_acc_address_alt      CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS_ALT';  -- 帳合先住所(カナ)
  cv_bal_acc_tel              CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_TEL';          -- 帳合先TEL
  cv_order_possible_date      CONSTANT VARCHAR2(50)  := 'ORDER_POSSIBLE_DATE';           -- 受注可能日
  cv_perm_possible_date       CONSTANT VARCHAR2(50)  := 'PERMISSION_POSSIBLE_DATE';      -- 許容可能日
  cv_forward_month            CONSTANT VARCHAR2(50)  := 'FORWARD_MONTH';                 -- 先限年月日
  cv_payment_settlement_date  CONSTANT VARCHAR2(50)  := 'PAYMENT_SETTLEMENT_DATE';       -- 支払決済日
  cv_handbill_start_date_act  CONSTANT VARCHAR2(50)  := 'HANDBILL_START_DATE_ACTIVE';    -- チラシ開始日
  cv_billing_due_date         CONSTANT VARCHAR2(50)  := 'BILLING_DUE_DATE';              -- 請求締日
  cv_ship_time                CONSTANT VARCHAR2(50)  := 'SHIPPING_TIME';                 -- 出荷時刻
  cv_delv_schedule_time       CONSTANT VARCHAR2(50)  := 'DELIVERY_SCHEDULE_TIME';        -- 納品予定時間
  cv_order_time               CONSTANT VARCHAR2(50)  := 'ORDER_TIME';                    -- 発注時間
  cv_gen_date_item1           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM1';            -- 汎用日付項目1
  cv_gen_date_item2           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM2';            -- 汎用日付項目2
  cv_gen_date_item3           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM3';            -- 汎用日付項目3
  cv_gen_date_item4           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM4';            -- 汎用日付項目4
  cv_gen_date_item5           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM5';            -- 汎用日付項目5
  cv_arrival_ship_class       CONSTANT VARCHAR2(50)  := 'ARRIVAL_SHIPPING_CLASS';        -- 入出荷区分
  cv_vendor_class             CONSTANT VARCHAR2(50)  := 'VENDOR_CLASS';                  -- 取引先区分
  cv_invc_detailed_class      CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED_CLASS';        -- 伝票内訳区分
  cv_unit_price_use_class     CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_USE_CLASS';          -- 単価使用区分
  cv_sub_distb_cent_code      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_CODE';  -- サブ物流センターコード
  cv_sub_distb_cent_name      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_NAME';  -- サブ物流センターコード名
  cv_cent_delv_method         CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_METHOD';        -- センター納品方法
  cv_cent_use_class           CONSTANT VARCHAR2(50)  := 'CENTER_USE_CLASS';              -- センター利用区分
  cv_cent_whse_class          CONSTANT VARCHAR2(50)  := 'CENTER_WHSE_CLASS';             -- センター倉庫区分
  cv_cent_area_class          CONSTANT VARCHAR2(50)  := 'CENTER_AREA_CLASS';             -- センター地域区分
  cv_cent_arrival_class       CONSTANT VARCHAR2(50)  := 'CENTER_ARRIVAL_CLASS';          -- センター入荷区分
  cv_depot_class              CONSTANT VARCHAR2(50)  := 'DEPOT_CLASS';                   -- デポ区分
  cv_tcdc_class               CONSTANT VARCHAR2(50)  := 'TCDC_CLASS';                    -- TCDC区分
  cv_upc_flag                 CONSTANT VARCHAR2(50)  := 'UPC_FLAG';                      -- UPCフラグ
  cv_simultaneously_class     CONSTANT VARCHAR2(50)  := 'SIMULTANEOUSLY_CLASS';          -- 一斉区分
  cv_business_id              CONSTANT VARCHAR2(50)  := 'BUSINESS_ID';                   -- 業務ID
  cv_whse_directly_class      CONSTANT VARCHAR2(50)  := 'WHSE_DIRECTLY_CLASS';           -- 倉直区分
  cv_premium_rebate_class     CONSTANT VARCHAR2(50)  := 'PREMIUM_REBATE_CLASS';          -- 項目種別
  cv_item_type                CONSTANT VARCHAR2(50)  := 'ITEM_TYPE';                     -- 景品割戻区分
  cv_cloth_house_food_class   CONSTANT VARCHAR2(50)  := 'CLOTH_HOUSE_FOOD_CLASS';        -- 衣家食区分
  cv_mix_class                CONSTANT VARCHAR2(50)  := 'MIX_CLASS';                     -- 混在区分
  cv_stk_class                CONSTANT VARCHAR2(50)  := 'STK_CLASS';                     -- 在庫区分
  cv_last_modify_site_class   CONSTANT VARCHAR2(50)  := 'LAST_MODIFY_SITE_CLASS';        -- 最終修正場所区分
  cv_report_class             CONSTANT VARCHAR2(50)  := 'REPORT_CLASS';                  -- 帳票区分
  cv_addition_plan_class      CONSTANT VARCHAR2(50)  := 'ADDITION_PLAN_CLASS';           -- 追加・計画区分
  cv_registration_class       CONSTANT VARCHAR2(50)  := 'REGISTRATION_CLASS';            -- 登録区分
  cv_specific_class           CONSTANT VARCHAR2(50)  := 'SPECIFIC_CLASS';                -- 特定区分
  cv_dealings_class           CONSTANT VARCHAR2(50)  := 'DEALINGS_CLASS';                -- 取引区分
  cv_order_class              CONSTANT VARCHAR2(50)  := 'ORDER_CLASS';                   -- 発注区分
  cv_sum_line_class           CONSTANT VARCHAR2(50)  := 'SUM_LINE_CLASS';                -- 集計明細区分
  cv_ship_guidance_class      CONSTANT VARCHAR2(50)  := 'SHIPPING_GUIDANCE_CLASS';       -- 出荷案内以外区分
  cv_ship_class               CONSTANT VARCHAR2(50)  := 'SHIPPING_CLASS';                -- 出荷区分
  cv_prod_code_use_class      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_USE_CLASS';        -- 商品コード使用区分
  cv_cargo_item_class         CONSTANT VARCHAR2(50)  := 'CARGO_ITEM_CLASS';              -- 積送品区分
  cv_ta_class                 CONSTANT VARCHAR2(50)  := 'TA_CLASS';                      -- T／A区分
  cv_plan_code                CONSTANT VARCHAR2(50)  := 'PLAN_CODE';                     -- 企画ｺｰﾄﾞ
  cv_category_code            CONSTANT VARCHAR2(50)  := 'CATEGORY_CODE';                 -- カテゴリーコード
  cv_category_class           CONSTANT VARCHAR2(50)  := 'CATEGORY_CLASS';                -- カテゴリー区分
  cv_carrier_means            CONSTANT VARCHAR2(50)  := 'CARRIER_MEANS';                 -- 運送手段
  cv_counter_code             CONSTANT VARCHAR2(50)  := 'COUNTER_CODE';                  -- 売場コード
  cv_move_sign                CONSTANT VARCHAR2(50)  := 'MOVE_SIGN';                     -- 移動サイン
  cv_eos_handwriting_class    CONSTANT VARCHAR2(50)  := 'EOS_HANDWRITING_CLASS';         -- EOS・手書区分
  cv_delv_to_section_code     CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_SECTION_CODE';      -- 納品先課コード
  cv_invc_detailed            CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED';              -- 伝票内訳
  cv_attach_qty               CONSTANT VARCHAR2(50)  := 'ATTACH_QTY';                    -- 添付数
  cv_op_floor                 CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_FLOOR';             -- フロア
  cv_text_no                  CONSTANT VARCHAR2(50)  := 'TEXT_NO';                       -- TEXTNo
  cv_in_store_code            CONSTANT VARCHAR2(50)  := 'IN_STORE_CODE';                 -- インストアコード
  cv_tag_data                 CONSTANT VARCHAR2(50)  := 'TAG_DATA';                      -- タグ
  cv_competition_code         CONSTANT VARCHAR2(50)  := 'COMPETITION_CODE';              -- 競合
  cv_billing_chair            CONSTANT VARCHAR2(50)  := 'BILLING_CHAIR';                 -- 請求口座
  cv_chain_store_code         CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_CODE';              -- チェーンストアーコード
  cv_chain_store_short_name   CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_SHORT_NAME';        -- ﾁｪｰﾝｽﾄｱｰｺｰﾄﾞ略式名称
  cv_direct_delv_rcpt_fee     CONSTANT VARCHAR2(50)  := 'DIRECT_DELIVERY_RCPT_FEE';      -- 直配送／引取料
  cv_bill_info                CONSTANT VARCHAR2(50)  := 'BILL_INFO';                     -- 手形情報
  cv_description              CONSTANT VARCHAR2(50)  := 'DESCRIPTION';                   -- 摘要1
  cv_interior_code            CONSTANT VARCHAR2(50)  := 'INTERIOR_CODE';                 -- 内部コード
  cv_order_info_delv_category CONSTANT VARCHAR2(50)  := 'ORDER_INFO_DELIVERY_CATEGORY';  -- 発注情報 納品カテゴリー
  cv_purchase_type            CONSTANT VARCHAR2(50)  := 'PURCHASE_TYPE';                 -- 仕入形態
  cv_delv_to_name_alt         CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_NAME_ALT';          -- 納品場所名(カナ)
  cv_shop_opened_site         CONSTANT VARCHAR2(50)  := 'SHOP_OPENED_SITE';              -- 店出場所
  cv_counter_name             CONSTANT VARCHAR2(50)  := 'COUNTER_NAME';                  -- 売場名
  cv_extension_number         CONSTANT VARCHAR2(50)  := 'EXTENSION_NUMBER';              -- 内線番号
  cv_charge_name              CONSTANT VARCHAR2(50)  := 'CHARGE_NAME';                   -- 担当者名
  cv_price_tag                CONSTANT VARCHAR2(50)  := 'PRICE_TAG';                     -- 値札
  cv_tax_type                 CONSTANT VARCHAR2(50)  := 'TAX_TYPE';                      -- 税種
  cv_consumption_tax_class    CONSTANT VARCHAR2(50)  := 'CONSUMPTION_TAX_CLASS';         -- 消費税区分
  cv_brand_class              CONSTANT VARCHAR2(50)  := 'BRAND_CLASS';                   -- BR
  cv_id_code                  CONSTANT VARCHAR2(50)  := 'ID_CODE';                       -- IDコード
  cv_department_code          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_CODE';               -- 百貨店コード
  cv_department_name          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_NAME';               -- 百貨店名
  cv_item_type_number         CONSTANT VARCHAR2(50)  := 'ITEM_TYPE_NUMBER';              -- 品別番号
  cv_description_department   CONSTANT VARCHAR2(50)  := 'DESCRIPTION_DEPARTMENT';        -- 摘要2
  cv_price_tag_method         CONSTANT VARCHAR2(50)  := 'PRICE_TAG_METHOD';              -- 値札方法
  cv_reason_column            CONSTANT VARCHAR2(50)  := 'REASON_COLUMN';                 -- 自由欄
  cv_a_column_header          CONSTANT VARCHAR2(50)  := 'A_COLUMN_HEADER';               -- A欄ヘッダ
  cv_d_column_header          CONSTANT VARCHAR2(50)  := 'D_COLUMN_HEADER';               -- D欄ヘッダ
  cv_brand_code               CONSTANT VARCHAR2(50)  := 'BRAND_CODE';                    -- ブランドコード
  cv_line_code                CONSTANT VARCHAR2(50)  := 'LINE_CODE';                     -- ラインコード
  cv_class_code               CONSTANT VARCHAR2(50)  := 'CLASS_CODE';                    -- クラスコード
  cv_a1_column                CONSTANT VARCHAR2(50)  := 'A1_COLUMN';                     -- A－1欄
  cv_b1_column                CONSTANT VARCHAR2(50)  := 'B1_COLUMN';                     -- B－1欄
  cv_c1_column                CONSTANT VARCHAR2(50)  := 'C1_COLUMN';                     -- C－1欄
  cv_d1_column                CONSTANT VARCHAR2(50)  := 'D1_COLUMN';                     -- D－1欄
  cv_e1_column                CONSTANT VARCHAR2(50)  := 'E1_COLUMN';                     -- E－1欄
  cv_a2_column                CONSTANT VARCHAR2(50)  := 'A2_COLUMN';                     -- A－2欄
  cv_b2_column                CONSTANT VARCHAR2(50)  := 'B2_COLUMN';                     -- B－2欄
  cv_c2_column                CONSTANT VARCHAR2(50)  := 'C2_COLUMN';                     -- C－2欄
  cv_d2_column                CONSTANT VARCHAR2(50)  := 'D2_COLUMN';                     -- D－2欄
  cv_e2_column                CONSTANT VARCHAR2(50)  := 'E2_COLUMN';                     -- E－2欄
  cv_a3_column                CONSTANT VARCHAR2(50)  := 'A3_COLUMN';                     -- A－3欄
  cv_b3_column                CONSTANT VARCHAR2(50)  := 'B3_COLUMN';                     -- B－3欄
  cv_c3_column                CONSTANT VARCHAR2(50)  := 'C3_COLUMN';                     -- C－3欄
  cv_d3_column                CONSTANT VARCHAR2(50)  := 'D3_COLUMN';                     -- D－3欄
  cv_e3_column                CONSTANT VARCHAR2(50)  := 'E3_COLUMN';                     -- E－3欄
  cv_f1_column                CONSTANT VARCHAR2(50)  := 'F1_COLUMN';                     -- F－1欄
  cv_g1_column                CONSTANT VARCHAR2(50)  := 'G1_COLUMN';                     -- G－1欄
  cv_h1_column                CONSTANT VARCHAR2(50)  := 'H1_COLUMN';                     -- H－1欄
  cv_i1_column                CONSTANT VARCHAR2(50)  := 'I1_COLUMN';                     -- I－1欄
  cv_j1_column                CONSTANT VARCHAR2(50)  := 'J1_COLUMN';                     -- J－1欄
  cv_k1_column                CONSTANT VARCHAR2(50)  := 'K1_COLUMN';                     -- K－1欄
  cv_l1_column                CONSTANT VARCHAR2(50)  := 'L1_COLUMN';                     -- L－1欄
  cv_f2_column                CONSTANT VARCHAR2(50)  := 'F2_COLUMN';                     -- F－2欄
  cv_g2_column                CONSTANT VARCHAR2(50)  := 'G2_COLUMN';                     -- G－2欄
  cv_h2_column                CONSTANT VARCHAR2(50)  := 'H2_COLUMN';                     -- H－2欄
  cv_i2_column                CONSTANT VARCHAR2(50)  := 'I2_COLUMN';                     -- I－2欄
  cv_j2_column                CONSTANT VARCHAR2(50)  := 'J2_COLUMN';                     -- J－2欄
  cv_k2_column                CONSTANT VARCHAR2(50)  := 'K2_COLUMN';                     -- K－2欄
  cv_l2_column                CONSTANT VARCHAR2(50)  := 'L2_COLUMN';                     -- L－2欄
  cv_f3_column                CONSTANT VARCHAR2(50)  := 'F3_COLUMN';                     -- F－3欄
  cv_g3_column                CONSTANT VARCHAR2(50)  := 'G3_COLUMN';                     -- G－3欄
  cv_h3_column                CONSTANT VARCHAR2(50)  := 'H3_COLUMN';                     -- H－3欄
  cv_i3_column                CONSTANT VARCHAR2(50)  := 'I3_COLUMN';                     -- I－3欄
  cv_j3_column                CONSTANT VARCHAR2(50)  := 'J3_COLUMN';                     -- J－3欄
  cv_k3_column                CONSTANT VARCHAR2(50)  := 'K3_COLUMN';                     -- K－3欄
  cv_l3_column                CONSTANT VARCHAR2(50)  := 'L3_COLUMN';                     -- L－3欄
  cv_chain_pec_area_header    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_HEADER';    -- チェーン店固有エリア(ヘッダ)
  cv_order_connection_number  CONSTANT VARCHAR2(50)  := 'ORDER_CONNECTION_NUMBER';       -- 受注関連番号(仮)
  cv_line_no                  CONSTANT VARCHAR2(50)  := 'LINE_NO';                       -- 行No
  cv_stkout_class             CONSTANT VARCHAR2(50)  := 'STOCKOUT_CLASS';                -- 欠品区分
  cv_stkout_reason            CONSTANT VARCHAR2(50)  := 'STOCKOUT_REASON';               -- 欠品理由
  cv_prod_code_itouen         CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITOUEN';           -- 商品コード(伊藤園)
  cv_prod_code1               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE1';                 -- 商品コード1
  cv_prod_code2               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE2';                 -- 商品コード2
  cv_jan_code                 CONSTANT VARCHAR2(50)  := 'JAN_CODE';                      -- JANコード
  cv_itf_code                 CONSTANT VARCHAR2(50)  := 'ITF_CODE';                      -- ITFコード
  cv_extension_itf_code       CONSTANT VARCHAR2(50)  := 'EXTENSION_ITF_CODE';            -- 内箱ITFコード
  cv_case_prod_code           CONSTANT VARCHAR2(50)  := 'CASE_PRODUCT_CODE';             -- ケース商品コード
  cv_ball_prod_code           CONSTANT VARCHAR2(50)  := 'BALL_PRODUCT_CODE';             -- ボール商品コード
  cv_prod_code_item_type      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITEM_TYPE';        -- 商品コード品種
  cv_prod_class               CONSTANT VARCHAR2(50)  := 'PROD_CLASS';                    -- 商品区分
  cv_prod_name                CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME';                  -- 商品名(漢字)
  cv_prod_name1_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME1_ALT';             -- 商品名1(カナ)
  cv_prod_name2_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME2_ALT';             -- 商品名2(カナ)
  cv_item_standard1           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD1';                -- 規格1
  cv_item_standard2           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD2';                -- 規格2
  cv_qty_in_case              CONSTANT VARCHAR2(50)  := 'QTY_IN_CASE';                   -- 入数
  cv_num_of_cases             CONSTANT VARCHAR2(50)  := 'NUM_OF_CASES';                  -- ケース入数
  cv_num_of_ball              CONSTANT VARCHAR2(50)  := 'NUM_OF_BALL';                   -- ボール入数
  cv_item_color               CONSTANT VARCHAR2(50)  := 'ITEM_COLOR';                    -- 色
  cv_item_size                CONSTANT VARCHAR2(50)  := 'ITEM_SIZE';                     -- サイズ
  cv_expiration_date          CONSTANT VARCHAR2(50)  := 'EXPIRATION_DATE';               -- 賞味期限日
  cv_prod_date                CONSTANT VARCHAR2(50)  := 'PRODUCT_DATE';                  -- 製造日
  cv_order_uom_qty            CONSTANT VARCHAR2(50)  := 'ORDER_UOM_QTY';                 -- 発注単位数
  cv_ship_uom_qty             CONSTANT VARCHAR2(50)  := 'SHIPPING_UOM_QTY';              -- 出荷単位数
  cv_packing_uom_qty          CONSTANT VARCHAR2(50)  := 'PACKING_UOM_QTY';               -- 梱包単位数
  cv_deal_code                CONSTANT VARCHAR2(50)  := 'DEAL_CODE';                     -- 引合
  cv_deal_class               CONSTANT VARCHAR2(50)  := 'DEAL_CLASS';                    -- 引合区分
  cv_collation_code           CONSTANT VARCHAR2(50)  := 'COLLATION_CODE';                -- 照合
  cv_uom_code                 CONSTANT VARCHAR2(50)  := 'UOM_CODE';                      -- 単位
  cv_unit_price_class         CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_CLASS';              -- 単価区分
  cv_parent_packing_number    CONSTANT VARCHAR2(50)  := 'PARENT_PACKING_NUMBER';         -- 親梱包番号
  cv_packing_number           CONSTANT VARCHAR2(50)  := 'PACKING_NUMBER';                -- 梱包番号
  cv_prod_group_code          CONSTANT VARCHAR2(50)  := 'PRODUCT_GROUP_CODE';            -- 商品群コード
  cv_case_dismantle_flag      CONSTANT VARCHAR2(50)  := 'CASE_DISMANTLE_FLAG';           -- ケース解体不可フラグ
  cv_case_class               CONSTANT VARCHAR2(50)  := 'CASE_CLASS';                    -- ケース区分
  cv_indv_order_qty           CONSTANT VARCHAR2(50)  := 'INDV_ORDER_QTY';                -- 発注数量(バラ)
  cv_case_order_qty           CONSTANT VARCHAR2(50)  := 'CASE_ORDER_QTY';                -- 発注数量(ケース)
  cv_ball_order_qty           CONSTANT VARCHAR2(50)  := 'BALL_ORDER_QTY';                -- 発注数量(ボール)
  cv_sum_order_qty            CONSTANT VARCHAR2(50)  := 'SUM_ORDER_QTY';                 -- 発注数量(合計、バラ)
  cv_indv_ship_qty            CONSTANT VARCHAR2(50)  := 'INDV_SHIPPING_QTY';             -- 出荷数量(バラ)
  cv_case_ship_qty            CONSTANT VARCHAR2(50)  := 'CASE_SHIPPING_QTY';             -- 出荷数量(ケース)
  cv_ball_ship_qty            CONSTANT VARCHAR2(50)  := 'BALL_SHIPPING_QTY';             -- 出荷数量(ボール)
  cv_pallet_ship_qty          CONSTANT VARCHAR2(50)  := 'PALLET_SHIPPING_QTY';           -- 出荷数量(パレット)
  cv_sum_ship_qty             CONSTANT VARCHAR2(50)  := 'SUM_SHIPPING_QTY';              -- 出荷数量(合計、バラ)
  cv_indv_stkout_qty          CONSTANT VARCHAR2(50)  := 'INDV_STOCKOUT_QTY';             -- 欠品数量(バラ)
  cv_case_stkout_qty          CONSTANT VARCHAR2(50)  := 'CASE_STOCKOUT_QTY';             -- 欠品数量(ケース)
  cv_ball_stkout_qty          CONSTANT VARCHAR2(50)  := 'BALL_STOCKOUT_QTY';             -- 欠品数量(ボール)
  cv_sum_stkout_qty           CONSTANT VARCHAR2(50)  := 'SUM_STOCKOUT_QTY';              -- 欠品数量(合計、バラ)
  cv_case_qty                 CONSTANT VARCHAR2(50)  := 'CASE_QTY';                      -- ケース個口数
  cv_fold_container_indv_qty  CONSTANT VARCHAR2(50)  := 'FOLD_CONTAINER_INDV_QTY';       -- オリコン(バラ)個口数
  cv_order_unit_price         CONSTANT VARCHAR2(50)  := 'ORDER_UNIT_PRICE';              -- 原単価(発注)
  cv_ship_unit_price          CONSTANT VARCHAR2(50)  := 'SHIPPING_UNIT_PRICE';           -- 原単価(出荷)
  cv_order_cost_amt           CONSTANT VARCHAR2(50)  := 'ORDER_COST_AMT';                -- 原価金額(発注)
  cv_ship_cost_amt            CONSTANT VARCHAR2(50)  := 'SHIPPING_COST_AMT';             -- 原価金額(出荷)
  cv_stkout_cost_amt          CONSTANT VARCHAR2(50)  := 'STOCKOUT_COST_AMT';             -- 原価金額(欠品)
  cv_selling_price            CONSTANT VARCHAR2(50)  := 'SELLING_PRICE';                 -- 売単価
  cv_order_price_amt          CONSTANT VARCHAR2(50)  := 'ORDER_PRICE_AMT';               -- 売価金額(発注)
  cv_ship_price_amt           CONSTANT VARCHAR2(50)  := 'SHIPPING_PRICE_AMT';            -- 売価金額(出荷)
  cv_stkout_price_amt         CONSTANT VARCHAR2(50)  := 'STOCKOUT_PRICE_AMT';            -- 売価金額(欠品)
  cv_a_column_department      CONSTANT VARCHAR2(50)  := 'A_COLUMN_DEPARTMENT';           -- A欄(百貨店)
  cv_d_column_department      CONSTANT VARCHAR2(50)  := 'D_COLUMN_DEPARTMENT';           -- D欄(百貨店)
  cv_standard_info_depth      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_DEPTH';           -- 規格情報・奥行き
  cv_standard_info_height     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_HEIGHT';          -- 規格情報・高さ
  cv_standard_info_width      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WIDTH';           -- 規格情報・幅
  cv_standard_info_weight     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WEIGHT';          -- 規格情報・重量
  cv_gen_suc_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM1';       -- 汎用引継ぎ項目1
  cv_gen_suc_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM2';       -- 汎用引継ぎ項目2
  cv_gen_suc_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM3';       -- 汎用引継ぎ項目3
  cv_gen_suc_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM4';       -- 汎用引継ぎ項目4
  cv_gen_suc_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM5';       -- 汎用引継ぎ項目5
  cv_gen_suc_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM6';       -- 汎用引継ぎ項目6
  cv_gen_suc_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM7';       -- 汎用引継ぎ項目7
  cv_gen_suc_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM8';       -- 汎用引継ぎ項目8
  cv_gen_suc_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM9';       -- 汎用引継ぎ項目9
  cv_gen_suc_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM10';      -- 汎用引継ぎ項目10
  cv_gen_add_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM1';             -- 汎用付加項目1
  cv_gen_add_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM2';             -- 汎用付加項目2
  cv_gen_add_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM3';             -- 汎用付加項目3
  cv_gen_add_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM4';             -- 汎用付加項目4
  cv_gen_add_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM5';             -- 汎用付加項目5
  cv_gen_add_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM6';             -- 汎用付加項目6
  cv_gen_add_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM7';             -- 汎用付加項目7
  cv_gen_add_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM8';             -- 汎用付加項目8
  cv_gen_add_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM9';             -- 汎用付加項目9
  cv_gen_add_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM10';            -- 汎用付加項目10
  cv_chain_pec_area_line      CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_LINE';      -- チェーン店固有エリア(明細)
  cv_invc_indv_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_ORDER_QTY';        -- (伝票計)発注数量(バラ)
  cv_invc_case_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_ORDER_QTY';        -- (伝票計)発注数量(ケース)
  cv_invc_ball_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_ORDER_QTY';        -- (伝票計)発注数量(ボール)
  cv_invc_sum_order_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_ORDER_QTY';         -- (伝票計)発注数量(合計、バラ)
  cv_invc_indv_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_SHIPPING_QTY';     -- (伝票計)出荷数量(バラ)
  cv_invc_case_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_SHIPPING_QTY';     -- (伝票計)出荷数量(ケース)
  cv_invc_ball_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_SHIPPING_QTY';     -- (伝票計)出荷数量(ボール)
  cv_invc_pallet_ship_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_PALLET_SHIPPING_QTY';   -- (伝票計)出荷数量(パレット)
  cv_invc_sum_ship_qty        CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_SHIPPING_QTY';      -- (伝票計)出荷数量(合計、バラ)
  cv_invc_indv_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_STOCKOUT_QTY';     -- (伝票計)欠品数量(バラ)
  cv_invc_case_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_STOCKOUT_QTY';     -- (伝票計)欠品数量(ケース)
  cv_invc_ball_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_STOCKOUT_QTY';     -- (伝票計)欠品数量(ボール)
  cv_invc_sum_stkout_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_STOCKOUT_QTY';      -- (伝票計)欠品数量(合計、バラ)
  cv_invc_case_qty            CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_QTY';              -- (伝票計)ケース個口数
  cv_invc_fold_container_qty  CONSTANT VARCHAR2(50)  := 'INVOICE_FOLD_CONTAINER_QTY';    -- (伝票計)オリコン(バラ)個口数
  cv_invc_order_cost_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_COST_AMT';        -- (伝票計)原価金額(発注)
  cv_invc_ship_cost_amt       CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_COST_AMT';     -- (伝票計)原価金額(出荷)
  cv_invc_stkout_cost_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_COST_AMT';     -- (伝票計)原価金額(欠品)
  cv_invc_order_price_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_PRICE_AMT';       -- (伝票計)売価金額(発注)
  cv_invc_ship_price_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_PRICE_AMT';    -- (伝票計)売価金額(出荷)
  cv_invc_stkout_price_amt    CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_PRICE_AMT';    -- (伝票計)売価金額(欠品)
  cv_t_indv_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_ORDER_QTY';          -- (総合計)発注数量(バラ)
  cv_t_case_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_ORDER_QTY';          -- (総合計)発注数量(ケース)
  cv_t_ball_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_ORDER_QTY';          -- (総合計)発注数量(ボール)
  cv_t_sum_order_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_ORDER_QTY';           -- (総合計)発注数量(合計、バラ)
  cv_t_indv_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_SHIPPING_QTY';       -- (総合計)出荷数量(バラ)
  cv_t_case_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_SHIPPING_QTY';       -- (総合計)出荷数量(ケース)
  cv_t_ball_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_SHIPPING_QTY';       -- (総合計)出荷数量(ボール)
  cv_t_pallet_ship_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_PALLET_SHIPPING_QTY';     -- (総合計)出荷数量(パレット)
  cv_t_sum_ship_qty           CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_SHIPPING_QTY';        -- (総合計)出荷数量(合計、バラ)
  cv_t_indv_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_STOCKOUT_QTY';       -- (総合計)欠品数量(バラ)
  cv_t_case_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_STOCKOUT_QTY';       -- (総合計)欠品数量(ケース)
  cv_t_ball_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_STOCKOUT_QTY';       -- (総合計)欠品数量(ボール)
  cv_t_sum_stkout_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_STOCKOUT_QTY';        -- (総合計)欠品数量(合計、バラ)
  cv_t_case_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_QTY';                -- (総合計)ケース個口数
  cv_t_fold_container_qty     CONSTANT VARCHAR2(50)  := 'TOTAL_FOLD_CONTAINER_QTY';      -- (総合計)オリコン(バラ)個口数
  cv_t_order_cost_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_COST_AMT';          -- (総合計)原価金額(発注)
  cv_t_ship_cost_amt          CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_COST_AMT';       -- (総合計)原価金額(出荷)
  cv_t_stkout_cost_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_COST_AMT';       -- (総合計)原価金額(欠品)
  cv_t_order_price_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_PRICE_AMT';         -- (総合計)売価金額(発注)
  cv_t_ship_price_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_PRICE_AMT';      -- (総合計)売価金額(出荷)
  cv_t_stkout_price_amt       CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_PRICE_AMT';      -- (総合計)売価金額(欠品)
  cv_t_line_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_LINE_QTY';                -- トータル行数
  cv_t_invc_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_INVOICE_QTY';             -- トータル伝票枚数
  cv_chain_pec_area_footer    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_FOOTER';    -- チェーン店固有エリア(フッタ)
/* 2009/04/28 Ver1.7 Add Start */
  cv_attribute                CONSTANT VARCHAR2(50)  := 'ATTRIBUTE';                     -- 予備エリア
/* 2009/04/28 Ver1.7 Add End   */
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
  cv_online                   CONSTANT VARCHAR2(50)  := 'Online';                        -- 受注ソース(ONLINE)
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  gt_f_handle           UTL_FILE.FILE_TYPE;                            -- ファイルハンドラ
  gt_data_type_table    xxcos_common2_pkg.g_record_layout_ttype;       -- ファイルレイアウト
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル出力項目用
  gv_f_o_date           CHAR(8);                                       -- 処理日
  gv_f_o_time           CHAR(6);                                       -- 処理時刻
  gn_organization_id    NUMBER;                                        -- 在庫組織ID
  gt_tax_rate           ar_vat_tax_all_b.tax_rate%TYPE;                -- 税率
  gt_edi_media_class    fnd_lookup_values_vl.lookup_code%TYPE;         -- EDI媒体区分
  gt_data_type_code     fnd_lookup_values_vl.lookup_code%TYPE;         -- データ種コード
  -- テーブルカウンタ
  gn_dat_rec_cnt        NUMBER;                                        -- 出力データ用
  gn_head_cnt           NUMBER;                                        -- EDIヘッダ情報用
  gn_line_cnt           NUMBER;                                        -- EDI明細情報用
  -- 条件判定、共通関数用
  gt_edi_item_code_div  xxcmm_cust_accounts.edi_item_code_div%TYPE;    -- EDI連携品目コード区分
  gt_chain_cust_acct_id hz_cust_accounts.cust_account_id%TYPE;         -- 顧客ID(チェーン店)
  gt_from_series        fnd_lookup_values_vl.attribute1%TYPE;          -- IF元業務系列コード
  gt_edi_c_code         xxcos_edi_headers.edi_chain_code%TYPE;         -- EDIチェーン店コード
  gt_edi_f_number       xxcmm_cust_accounts.edi_forward_number%TYPE;   -- EDI伝送追番
  gt_shop_date_from     xxcos_edi_headers.shop_delivery_date%TYPE;     -- 店舗納品日From
  gt_shop_date_to       xxcos_edi_headers.shop_delivery_date%TYPE;     -- 店舗納品日To
  gt_sale_class         xxcos_edi_headers.ar_sale_class%TYPE;          -- 定番特売区分
  gt_area_code          xxcmm_cust_accounts.edi_district_code%TYPE;    -- 地区コード
  -- プロファイル値
  gv_if_header          VARCHAR2(2);                                   -- ヘッダレコード区分
  gv_if_data            VARCHAR2(2);                                   -- データレコード区分
  gv_if_footer          VARCHAR2(2);                                   -- フッタレコード区分
  gv_utl_m_line         VARCHAR2(100);                                 -- UTL_MAX行サイズ
  gv_outbound_d         VARCHAR2(100);                                 -- アウトバウンド用ディレクトリパス
  gv_company_name       VARCHAR2(100);                                 -- 会社名
  gv_company_kana       VARCHAR2(100);                                 -- 会社名カナ
  gv_case_uom_code      VARCHAR2(3);                                   -- ケース単位コード
  gv_ball_uom_code      VARCHAR2(3);                                   -- ボール単位コード
  gv_organization       VARCHAR2(3);                                   -- 在庫組織コード
  gd_max_date           DATE;                                          -- MAX日付
  gn_bks_id             NUMBER;                                        -- 会計帳簿ID
  gn_org_id             NUMBER;                                        -- 営業単位
-- 2009/05/22 Ver1.9 Add Start
  gn_dum_stock_out      VARCHAR2(3);                                   -- EDI納品予定ダミー欠品区分
-- 2009/05/22 Ver1.9 Add End
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
   gt_category_set_id      mtl_category_sets_tl.category_set_id%TYPE;          --カテゴリセットID
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
    gt_order_source_online oe_order_sources.order_source_id%TYPE;
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
--
  -- ===============================
  -- ユーザー定義グローバルカーソル宣言
  -- ===============================
  -- EDI受注データ
  CURSOR edi_order_cur
  IS
    SELECT 
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
           /*+ USE_NL(XEH) */
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
           xeh.edi_header_info_id               edi_header_info_id             -- EDIヘッダ情報.EDIヘッダ情報ID
          ,xeh.medium_class                     medium_class                   -- EDIヘッダ情報.媒体区分
          ,xeh.data_type_code                   data_type_code                 -- EDIヘッダ情報.データ種コード
          ,xeh.file_no                          file_no                        -- EDIヘッダ情報.ファイルNo
          ,xeh.info_class                       info_class                     -- EDIヘッダ情報.情報区分
          ,xca3.delivery_base_code              delivery_base_code             -- 顧客マスタ.納品拠点コード
          ,hp1.party_name                       base_name                      -- 拠点マスタ.顧客名称
          ,hp1.organization_name_phonetic       base_name_phonetic             -- 拠点マスタ.顧客名称(カナ)
          ,xeh.edi_chain_code                   edi_chain_code                 -- EDIヘッダ情報.ＥＤＩチェーン店コード
          ,hp2.party_name                       edi_chain_name                 -- チェーン店マスタ.顧客名称
          ,xeh.edi_chain_name_alt               edi_chain_name_alt             -- EDIヘッダ情報.ＥＤＩチェーン店名(カナ)
          ,hp2.organization_name_phonetic       edi_chain_name_phonetic        -- チェーン店マスタ.顧客名称(カナ)
          ,xca3.chain_store_code                edi_chain_store_code           -- 顧客マスタ.チェーン店コード(EDI)
          ,hca3.account_number                  account_number                 -- 顧客マスタ.顧客コード
          ,hp3.party_name                       customer_name                  -- 顧客マスタ.顧客名称
          ,hp3.organization_name_phonetic       customer_name_phonetic         -- 顧客マスタ.顧客名称(カナ)
          ,xeh.company_code                     company_code                   -- EDIヘッダ情報.社コード
          ,xeh.company_name                     company_name                   -- EDIヘッダ情報.社名(漢字)
          ,xeh.company_name_alt                 company_name_alt               -- EDIヘッダ情報.社名(カナ)
          ,xeh.shop_code                        shop_code                      -- EDIヘッダ情報.店コード
          ,xca3.cust_store_name                 cust_store_name                -- 顧客マスタ.顧客店舗名称
          ,xeh.shop_name_alt                    shop_name_alt                  -- EDIヘッダ情報.店名(カナ)
          ,hp3.organization_name_phonetic       shop_name_phonetic             -- 顧客マスタ.顧客名称(カナ)
          ,xeh.delivery_center_code             delivery_center_code           -- EDIヘッダ情報.納入センターコード
          ,xeh.delivery_center_name             delivery_center_name           -- EDIヘッダ情報.納入センター名(漢字)
          ,xeh.delivery_center_name_alt         delivery_center_name_alt       -- EDIヘッダ情報.納入センター名(カナ)
          ,xeh.order_date                       order_date                     -- EDIヘッダ情報.発注日
          ,xeh.center_delivery_date             center_delivery_date           -- EDIヘッダ情報.センター納品日
          ,xeh.result_delivery_date             result_delivery_date           -- EDIヘッダ情報.実納品日
          ,xeh.shop_delivery_date               shop_delivery_date             -- EDIヘッダ情報.店舗納品日
          ,xeh.data_creation_date_edi_data      data_creation_date_edi_data    -- EDIヘッダ情報.データ作成日(ＥＤＩデータ中)
          ,xeh.data_creation_time_edi_data      data_creation_time_edi_data    -- EDIヘッダ情報.データ作成時刻(ＥＤＩデータ中)
-- ***************************** 2009/07/10 1.10 N.Maeda    MOD START ******************************--
          ,NVL(ooha.attribute5,xeh.invoice_class) invoice_class                  -- EDIヘッダ情報.伝票区分
--          ,xeh.invoice_class                    invoice_class                  -- EDIヘッダ情報.伝票区分
-- ****************************** 2009/07/10 1.10 N.Maeda   MOD  END  *****************************--
          ,xeh.small_classification_code        small_classification_code      -- EDIヘッダ情報.小分類コード
          ,xeh.small_classification_name        small_classification_name      -- EDIヘッダ情報.小分類名
          ,xeh.middle_classification_code       middle_classification_code     -- EDIヘッダ情報.中分類コード
          ,xeh.middle_classification_name       middle_classification_name     -- EDIヘッダ情報.中分類名
-- ***************************** 2009/07/10 1.10 N.Maeda    MOD START ******************************--
          ,NVL(ooha.attribute20,xeh.big_classification_code) big_classification_code  -- EDIヘッダ情報.大分類コード
          ,CASE
             WHEN  ( xeh.big_classification_code = ooha.attribute20 ) THEN
               xeh.big_classification_name
             ELSE
               NULL
           END
                                                big_classification_name        -- EDIヘッダ情報.大分類名
--          ,xeh.big_classification_code          big_classification_code        -- EDIヘッダ情報.大分類コード
--          ,xeh.big_classification_name          big_classification_name        -- EDIヘッダ情報.大分類名
-- ****************************** 2009/07/10 1.10 N.Maeda    MOD  END  *****************************--
          ,xeh.other_party_department_code      other_party_department_code    -- EDIヘッダ情報.相手先部門コード
          ,xeh.other_party_order_number         other_party_order_number       -- EDIヘッダ情報.相手先発注番号
          ,xeh.check_digit_class                check_digit_class              -- EDIヘッダ情報.チェックデジット有無区分
          ,xeh.invoice_number                   invoice_number                 -- EDIヘッダ情報.伝票番号
          ,xeh.check_digit                      check_digit                    -- EDIヘッダ情報.チェックデジット
          ,xeh.close_date                       close_date                     -- EDIヘッダ情報.月限
          ,ooha.order_number                    order_number                   -- 受注ヘッダ.受注番号
          ,xeh.ar_sale_class                    ar_sale_class                  -- EDIヘッダ情報.特売区分
          ,xeh.delivery_classe                  delivery_classe                -- EDIヘッダ情報.配送区分
          ,xeh.opportunity_no                   opportunity_no                 -- EDIヘッダ情報.便Ｎｏ
          ,xeh.contact_to                       contact_to                     -- EDIヘッダ情報.連絡先
          ,xeh.route_sales                      route_sales                    -- EDIヘッダ情報.ルートセールス
          ,xeh.corporate_code                   corporate_code                 -- EDIヘッダ情報.法人コード
          ,xeh.maker_name                       maker_name                     -- EDIヘッダ情報.メーカー名
          ,xeh.area_code                        area_code                      -- EDIヘッダ情報.地区コード
          ,xca3.edi_district_code               edi_district_code              -- 顧客マスタ.EDI地区コード
          ,xeh.area_name                        area_name                      -- EDIヘッダ情報.地区名(漢字)
          ,xca3.edi_district_name               edi_district_name              -- 顧客マスタ.EDI地区名
          ,xeh.area_name_alt                    area_name_alt                  -- EDIヘッダ情報.地区名(カナ)
          ,xca3.edi_district_kana               edi_district_kana              -- 顧客マスタ.EDI地区名カナ
          ,xeh.vendor_code                      vendor_code                    -- EDIヘッダ情報.取引先コード
          ,xca3.torihikisaki_code               torihikisaki_code              -- 顧客マスタ.取引先コード
          ,xeh.vendor_name1_alt                 vendor_name1_alt               -- EDIヘッダ情報.取引先名１(カナ)
          ,xeh.vendor_name2_alt                 vendor_name2_alt               -- EDIヘッダ情報.取引先名２(カナ)
          ,papf.last_name                       last_name                      -- 従業員マスタ.カナ姓
          ,papf.first_name                      first_name                     -- 従業員マスタ.カナ名
          ,hl1.state                            state                          -- 拠点マスタ.都道府県
          ,hl1.city                             city                           -- 拠点マスタ.市・区
          ,hl1.address1                         address1                       -- 拠点マスタ.住所１
          ,hl1.address2                         address2                       -- 拠点マスタ.住所２
          ,hl1.address_lines_phonetic           address_lines_phonetic         -- 拠点マスタ.電話番号
          ,xeh.deliver_to_code_itouen           deliver_to_code_itouen         -- EDIヘッダ情報.届け先コード(伊藤園)
          ,xeh.deliver_to_code_chain            deliver_to_code_chain          -- EDIヘッダ情報.届け先コード(チェーン店)
          ,xeh.deliver_to                       deliver_to                     -- EDIヘッダ情報.届け先(漢字)
          ,xeh.deliver_to1_alt                  deliver_to1_alt                -- EDIヘッダ情報.届け先１(カナ)
          ,xeh.deliver_to2_alt                  deliver_to2_alt                -- EDIヘッダ情報.届け先２(カナ)
          ,xeh.deliver_to_address               deliver_to_address             -- EDIヘッダ情報.届け先住所(漢字)
          ,xeh.deliver_to_address_alt           deliver_to_address_alt         -- EDIヘッダ情報.届け先住所(カナ)
          ,xeh.deliver_to_tel                   deliver_to_tel                 -- EDIヘッダ情報.届け先ＴＥＬ
          ,xeh.balance_accounts_code            balance_accounts_code          -- EDIヘッダ情報.帳合先コード
          ,xeh.balance_accounts_company_code    balance_accounts_company_code  -- EDIヘッダ情報.帳合先社コード
          ,xeh.balance_accounts_shop_code       balance_accounts_shop_code     -- EDIヘッダ情報.帳合先店コード
          ,xeh.balance_accounts_name            balance_accounts_name          -- EDIヘッダ情報.帳合先名(漢字)
          ,xeh.balance_accounts_name_alt        balance_accounts_name_alt      -- EDIヘッダ情報.帳合先名(カナ)
          ,xeh.balance_accounts_address         balance_accounts_address       -- EDIヘッダ情報.帳合先住所(漢字)
          ,xeh.balance_accounts_address_alt     balance_accounts_address_alt   -- EDIヘッダ情報.帳合先住所(カナ)
          ,xeh.balance_accounts_tel             balance_accounts_tel           -- EDIヘッダ情報.帳合先ＴＥＬ
          ,xeh.order_possible_date              order_possible_date            -- EDIヘッダ情報.受注可能日
          ,xeh.permission_possible_date         permission_possible_date       -- EDIヘッダ情報.許容可能日
          ,xeh.forward_month                    forward_month                  -- EDIヘッダ情報.先限年月日
          ,xeh.payment_settlement_date          payment_settlement_date        -- EDIヘッダ情報.支払決済日
          ,xeh.handbill_start_date_active       handbill_start_date_active     -- EDIヘッダ情報.チラシ開始日
          ,xeh.billing_due_date                 billing_due_date               -- EDIヘッダ情報.請求締日
          ,xeh.shipping_time                    shipping_time                  -- EDIヘッダ情報.出荷時刻
          ,xeh.delivery_schedule_time           delivery_schedule_time         -- EDIヘッダ情報.納品予定時間
          ,xeh.order_time                       order_time                     -- EDIヘッダ情報.発注時間
          ,xeh.general_date_item1               general_date_item1             -- EDIヘッダ情報.汎用日付項目１
          ,xeh.general_date_item2               general_date_item2             -- EDIヘッダ情報.汎用日付項目２
          ,xeh.general_date_item3               general_date_item3             -- EDIヘッダ情報.汎用日付項目３
          ,xeh.general_date_item4               general_date_item4             -- EDIヘッダ情報.汎用日付項目４
          ,xeh.general_date_item5               general_date_item5             -- EDIヘッダ情報.汎用日付項目５
          ,xeh.arrival_shipping_class           arrival_shipping_class         -- EDIヘッダ情報.入出荷区分
          ,xeh.vendor_class                     vendor_class                   -- EDIヘッダ情報.取引先区分
          ,xeh.invoice_detailed_class           invoice_detailed_class         -- EDIヘッダ情報.伝票内訳区分
          ,xeh.unit_price_use_class             unit_price_use_class           -- EDIヘッダ情報.単価使用区分
          ,xeh.sub_distribution_center_code     sub_distribution_center_code   -- EDIヘッダ情報.サブ物流センターコード
          ,xeh.sub_distribution_center_name     sub_distribution_center_name   -- EDIヘッダ情報.サブ物流センターコード名
          ,xeh.center_delivery_method           center_delivery_method         -- EDIヘッダ情報.センター納品方法
          ,xeh.center_use_class                 center_use_class               -- EDIヘッダ情報.センター利用区分
          ,xeh.center_whse_class                center_whse_class              -- EDIヘッダ情報.センター倉庫区分
          ,xeh.center_area_class                center_area_class              -- EDIヘッダ情報.センター地域区分
          ,xeh.center_arrival_class             center_arrival_class           -- EDIヘッダ情報.センター入荷区分
          ,xeh.depot_class                      depot_class                    -- EDIヘッダ情報.デポ区分
          ,xeh.tcdc_class                       tcdc_class                     -- EDIヘッダ情報.ＴＣＤＣ区分
          ,xeh.upc_flag                         upc_flag                       -- EDIヘッダ情報.ＵＰＣフラグ
          ,xeh.simultaneously_class             simultaneously_class           -- EDIヘッダ情報.一斉区分
          ,xeh.business_id                      business_id                    -- EDIヘッダ情報.業務ＩＤ
          ,xeh.whse_directly_class              whse_directly_class            -- EDIヘッダ情報.倉直区分
          ,xeh.premium_rebate_class             premium_rebate_class           -- EDIヘッダ情報.景品割戻区分
          ,xeh.item_type                        item_type                      -- EDIヘッダ情報.項目種別
          ,xeh.cloth_house_food_class           cloth_house_food_class         -- EDIヘッダ情報.衣家食区分
          ,xeh.mix_class                        mix_class                      -- EDIヘッダ情報.混在区分
          ,xeh.stk_class                        stk_class                      -- EDIヘッダ情報.在庫区分
          ,xeh.last_modify_site_class           last_modify_site_class         -- EDIヘッダ情報.最終修正場所区分
          ,xeh.report_class                     report_class                   -- EDIヘッダ情報.帳票区分
          ,xeh.addition_plan_class              addition_plan_class            -- EDIヘッダ情報.追加・計画区分
          ,xeh.registration_class               registration_class             -- EDIヘッダ情報.登録区分
          ,xeh.specific_class                   specific_class                 -- EDIヘッダ情報.特定区分
          ,xeh.dealings_class                   dealings_class                 -- EDIヘッダ情報.取引区分
          ,xeh.order_class                      order_class                    -- EDIヘッダ情報.発注区分
          ,xeh.sum_line_class                   sum_line_class                 -- EDIヘッダ情報.集計明細区分
          ,xeh.shipping_guidance_class          shipping_guidance_class        -- EDIヘッダ情報.出荷案内以外区分
          ,xeh.shipping_class                   shipping_class                 -- EDIヘッダ情報.出荷区分
          ,xeh.product_code_use_class           product_code_use_class         -- EDIヘッダ情報.商品コード使用区分
          ,xeh.cargo_item_class                 cargo_item_class               -- EDIヘッダ情報.積送品区分
          ,xeh.ta_class                         ta_class                       -- EDIヘッダ情報.Ｔ／Ａ区分
          ,xeh.plan_code                        plan_code                      -- EDIヘッダ情報.企画コード
          ,xeh.category_code                    category_code                  -- EDIヘッダ情報.カテゴリーコード
          ,xeh.category_class                   category_class                 -- EDIヘッダ情報.カテゴリー区分
          ,xeh.carrier_means                    carrier_means                  -- EDIヘッダ情報.運送手段
          ,xeh.counter_code                     counter_code                   -- EDIヘッダ情報.売場コード
          ,xeh.move_sign                        move_sign                      -- EDIヘッダ情報.移動サイン
          ,xeh.eos_handwriting_class            eos_handwriting_class          -- EDIヘッダ情報.ＥＯＳ・手書区分
          ,xeh.delivery_to_section_code         delivery_to_section_code       -- EDIヘッダ情報.納品先課コード
          ,xeh.invoice_detailed                 invoice_detailed               -- EDIヘッダ情報.伝票内訳
          ,xeh.attach_qty                       attach_qty                     -- EDIヘッダ情報.添付数
          ,xeh.other_party_floor                other_party_floor              -- EDIヘッダ情報.フロア
          ,xeh.text_no                          text_no                        -- EDIヘッダ情報.ＴＥＸＴＮｏ
          ,xeh.in_store_code                    in_store_code                  -- EDIヘッダ情報.インストアコード
          ,xeh.tag_data                         tag_data                       -- EDIヘッダ情報.タグ
          ,xeh.competition_code                 competition_code               -- EDIヘッダ情報.競合
          ,xeh.billing_chair                    billing_chair                  -- EDIヘッダ情報.請求口座
          ,xeh.chain_store_code                 chain_store_code               -- EDIヘッダ情報.チェーンストアーコード
          ,xeh.chain_store_short_name           chain_store_short_name         -- EDIヘッダ情報.チェーンストアーコード略式名称
          ,xeh.direct_delivery_rcpt_fee         direct_delivery_rcpt_fee       -- EDIヘッダ情報.直配送／引取料
          ,xeh.bill_info                        bill_info                      -- EDIヘッダ情報.手形情報
          ,xeh.description                      description                    -- EDIヘッダ情報.摘要
          ,xeh.interior_code                    interior_code                  -- EDIヘッダ情報.内部コード
          ,xeh.order_info_delivery_category     order_info_delivery_category   -- EDIヘッダ情報.発注情報　納品カテゴリー
          ,xeh.purchase_type                    purchase_type                  -- EDIヘッダ情報.仕入形態
          ,xeh.delivery_to_name_alt             delivery_to_name_alt           -- EDIヘッダ情報.納品場所名(カナ)
          ,xeh.shop_opened_site                 shop_opened_site               -- EDIヘッダ情報.店出場所
          ,xeh.counter_name                     counter_name                   -- EDIヘッダ情報.売場名
          ,xeh.extension_number                 extension_number               -- EDIヘッダ情報.内線番号
          ,xeh.charge_name                      charge_name                    -- EDIヘッダ情報.担当者名
          ,xeh.price_tag                        price_tag                      -- EDIヘッダ情報.値札
          ,xeh.tax_type                         tax_type                       -- EDIヘッダ情報.税種
          ,xeh.consumption_tax_class            consumption_tax_class          -- EDIヘッダ情報.消費税区分
          ,xeh.brand_class                      brand_class                    -- EDIヘッダ情報.ＢＲ
          ,xeh.id_code                          id_code                        -- EDIヘッダ情報.ＩＤコード
          ,xeh.department_code                  department_code                -- EDIヘッダ情報.百貨店コード
          ,xeh.department_name                  department_name                -- EDIヘッダ情報.百貨店名
          ,xeh.item_type_number                 item_type_number               -- EDIヘッダ情報.品別番号
          ,xeh.description_department           description_department         -- EDIヘッダ情報.摘要(百貨店)
          ,xeh.price_tag_method                 price_tag_method               -- EDIヘッダ情報.値札方法
          ,xeh.reason_column                    reason_column                  -- EDIヘッダ情報.自由欄
          ,xeh.a_column_header                  a_column_header                -- EDIヘッダ情報.Ａ欄ヘッダ
          ,xeh.d_column_header                  d_column_header                -- EDIヘッダ情報.Ｄ欄ヘッダ
          ,xeh.brand_code                       brand_code                     -- EDIヘッダ情報.ブランドコード
          ,xeh.line_code                        line_code                      -- EDIヘッダ情報.ラインコード
          ,xeh.class_code                       class_code                     -- EDIヘッダ情報.クラスコード
          ,xeh.a1_column                        a1_column                      -- EDIヘッダ情報.Ａ－１欄
          ,xeh.b1_column                        b1_column                      -- EDIヘッダ情報.Ｂ－１欄
          ,xeh.c1_column                        c1_column                      -- EDIヘッダ情報.Ｃ－１欄
          ,xeh.d1_column                        d1_column                      -- EDIヘッダ情報.Ｄ－１欄
          ,xeh.e1_column                        e1_column                      -- EDIヘッダ情報.Ｅ－１欄
          ,xeh.a2_column                        a2_column                      -- EDIヘッダ情報.Ａ－２欄
          ,xeh.b2_column                        b2_column                      -- EDIヘッダ情報.Ｂ－２欄
          ,xeh.c2_column                        c2_column                      -- EDIヘッダ情報.Ｃ－２欄
          ,xeh.d2_column                        d2_column                      -- EDIヘッダ情報.Ｄ－２欄
          ,xeh.e2_column                        e2_column                      -- EDIヘッダ情報.Ｅ－２欄
          ,xeh.a3_column                        a3_column                      -- EDIヘッダ情報.Ａ－３欄
          ,xeh.b3_column                        b3_column                      -- EDIヘッダ情報.Ｂ－３欄
          ,xeh.c3_column                        c3_column                      -- EDIヘッダ情報.Ｃ－３欄
          ,xeh.d3_column                        d3_column                      -- EDIヘッダ情報.Ｄ－３欄
          ,xeh.e3_column                        e3_column                      -- EDIヘッダ情報.Ｅ－３欄
          ,xeh.f1_column                        f1_column                      -- EDIヘッダ情報.Ｆ－１欄
          ,xeh.g1_column                        g1_column                      -- EDIヘッダ情報.Ｇ－１欄
          ,xeh.h1_column                        h1_column                      -- EDIヘッダ情報.Ｈ－１欄
          ,xeh.i1_column                        i1_column                      -- EDIヘッダ情報.Ｉ－１欄
          ,xeh.j1_column                        j1_column                      -- EDIヘッダ情報.Ｊ－１欄
          ,xeh.k1_column                        k1_column                      -- EDIヘッダ情報.Ｋ－１欄
          ,xeh.l1_column                        l1_column                      -- EDIヘッダ情報.Ｌ－１欄
          ,xeh.f2_column                        f2_column                      -- EDIヘッダ情報.Ｆ－２欄
          ,xeh.g2_column                        g2_column                      -- EDIヘッダ情報.Ｇ－２欄
          ,xeh.h2_column                        h2_column                      -- EDIヘッダ情報.Ｈ－２欄
          ,xeh.i2_column                        i2_column                      -- EDIヘッダ情報.Ｉ－２欄
          ,xeh.j2_column                        j2_column                      -- EDIヘッダ情報.Ｊ－２欄
          ,xeh.k2_column                        k2_column                      -- EDIヘッダ情報.Ｋ－２欄
          ,xeh.l2_column                        l2_column                      -- EDIヘッダ情報.Ｌ－２欄
          ,xeh.f3_column                        f3_column                      -- EDIヘッダ情報.Ｆ－３欄
          ,xeh.g3_column                        g3_column                      -- EDIヘッダ情報.Ｇ－３欄
          ,xeh.h3_column                        h3_column                      -- EDIヘッダ情報.Ｈ－３欄
          ,xeh.i3_column                        i3_column                      -- EDIヘッダ情報.Ｉ－３欄
          ,xeh.j3_column                        j3_column                      -- EDIヘッダ情報.Ｊ－３欄
          ,xeh.k3_column                        k3_column                      -- EDIヘッダ情報.Ｋ－３欄
          ,xeh.l3_column                        l3_column                      -- EDIヘッダ情報.Ｌ－３欄
          ,xeh.chain_peculiar_area_header       chain_peculiar_area_header     -- EDIヘッダ情報.チェーン店固有エリア(ヘッダー)
          ,xeh.total_line_qty                   total_line_qty                 -- EDIヘッダ情報.トータル行数
          ,xeh.total_invoice_qty                total_invoice_qty              -- EDIヘッダ情報.トータル伝票枚数
          ,xeh.chain_peculiar_area_footer       chain_peculiar_area_footer     -- EDIヘッダ情報.チェーン店固有エリア(フッター)
          ,xeh.order_forward_flag               order_forward_flag             -- EDIヘッダ情報.受注連携済フラグ
          ,xeh.creation_class                   creation_class                 -- EDIヘッダ情報.作成元区分
          ,xeh.edi_delivery_schedule_flag       edi_delivery_schedule_flag     -- EDIヘッダ情報.EDI納品予定送信済フラグ
          ,xeh.price_list_header_id             price_list_header_id           -- EDIヘッダ情報.価格表ヘッダID
          ,xel.edi_line_info_id                 edi_line_info_id               -- EDI明細情報.EDI明細情報ID
          ,xel.line_no                          line_no                        -- EDI明細情報.行Ｎｏ
          ,DECODE(flvv1.attribute1, cv_y, ore.reason_code,
                                          cv_err_reason_code)
                                                stockout_class                 -- 変更事由.欠品区分
          ,xel.stockout_reason                  stockout_reason                -- EDI明細情報.欠品理由
          ,oola.ordered_item                    ordered_item                   -- 受注明細.受注品目
          ,xel.product_code1                    product_code1                  -- EDI明細情報.商品コード１
          ,xel.product_code2                    product_code2                  -- EDI明細情報.商品コード２
          ,iimb.attribute21                     opf_jan_code                   -- ＯＰＭ品目マスタ.JANコード
          ,xsib.case_jan_code                   case_jan_code                  -- Disc品目アドオン.ケースJANコード
          ,xel.itf_code                         itf_code                       -- EDI明細情報.ＩＴＦコード
          ,iimb.attribute22                     opm_itf_code                   -- ＯＰＭ品目マスタ.ITFコード
          ,xel.extension_itf_code               extension_itf_code             -- EDI明細情報.内箱ＩＴＦコード
          ,xel.case_product_code                case_product_code              -- EDI明細情報.ケース商品コード
          ,xel.ball_product_code                ball_product_code              -- EDI明細情報.ボール商品コード
          ,xel.product_code_item_type           product_code_item_type         -- EDI明細情報.商品コード品種
-- ******* 2009/09/03 1.12 N.Maeda MOD START ******* --
--          ,xhpcv.item_div_h_code                item_div_h_code                -- 本社商品区分ビュー.本社商品区分
          ,mcb.segment1                         item_div_h_code                -- 本社商品区分ビュー.本社商品区分
-- ******* 2009/09/03 1.12 N.Maeda MOD  END  ******* --
          ,xel.product_name                     product_name                   -- EDI明細情報.商品名(漢字)
/* 2009/03/04 Ver1.6 Add Start */
          ,msib.description                     item_name                      -- Disc品目.摘要
/* 2009/03/04 Ver1.6 Add  End  */
          ,xel.product_name1_alt                product_name1_alt              -- EDI明細情報.商品名１(カナ)
          ,xel.product_name2_alt                product_name2_alt              -- EDI明細情報.商品名２(カナ)
          ,SUBSTRB(ximb.item_name_alt, 1, 15)   item_name_alt                  -- 品目_商品名２（カナ）
          ,xel.item_standard1                   item_standard1                 -- EDI明細情報.規格１
          ,xel.item_standard2                   item_standard2                 -- EDI明細情報.規格２
          ,SUBSTRB(ximb.item_name_alt, 16, 15)  item_name_alt2                 -- 品目_規格２
          ,xel.qty_in_case                      qty_in_case                    -- EDI明細情報.入数
          ,iimb.attribute11                     num_of_case                    -- ＯＰＭ品目マスタ.ケース入数
          ,xel.num_of_ball                      num_of_ball                    -- EDI明細情報.ボール入数
          ,xsib.bowl_inc_num                    bowl_inc_num                   -- Disc品目アドオン.ボール入数
          ,xel.item_color                       item_color                     -- EDI明細情報.色
          ,xel.item_size                        item_size                      -- EDI明細情報.サイズ
          ,xel.expiration_date                  expiration_date                -- EDI明細情報.賞味期限日
          ,xel.product_date                     product_date                   -- EDI明細情報.製造日
          ,xel.order_uom_qty                    order_uom_qty                  -- EDI明細情報.発注単位数
          ,xel.shipping_uom_qty                 shipping_uom_qty               -- EDI明細情報.出荷単位数
          ,xel.packing_uom_qty                  packing_uom_qty                -- EDI明細情報.梱包単位数
          ,xel.deal_code                        deal_code                      -- EDI明細情報.引合
          ,xel.deal_class                       deal_class                     -- EDI明細情報.引合区分
          ,xel.collation_code                   collation_code                 -- EDI明細情報.照合
          ,xel.uom_code                         uom_code                       -- EDI明細情報.単位
          ,xel.unit_price_class                 unit_price_class               -- EDI明細情報.単価区分
          ,xel.parent_packing_number            parent_packing_number          -- EDI明細情報.親梱包番号
          ,xel.packing_number                   packing_number                 -- EDI明細情報.梱包番号
          ,xel.product_group_code               product_group_code             -- EDI明細情報.商品群コード
          ,xel.case_dismantle_flag              case_dismantle_flag            -- EDI明細情報.ケース解体不可フラグ
          ,xel.case_class                       case_class                     -- EDI明細情報.ケース区分
          ,xel.indv_order_qty                   indv_order_qty                 -- EDI明細情報.発注数量(バラ)
          ,xel.case_order_qty                   case_order_qty                 -- EDI明細情報.発注数量(ケース)
          ,xel.ball_order_qty                   ball_order_qty                 -- EDI明細情報.発注数量(ボール)
          ,xel.sum_order_qty                    sum_order_qty                  -- EDI明細情報.発注数量(合計、バラ)
          ,xel.indv_shipping_qty                indv_shipping_qty              -- EDI明細情報.出荷数量(バラ)
          ,xel.case_shipping_qty                case_shipping_qty              -- EDI明細情報.出荷数量(ケース)
          ,xel.ball_shipping_qty                ball_shipping_qty              -- EDI明細情報.出荷数量(ボール)
          ,xel.pallet_shipping_qty              pallet_shipping_qty            -- EDI明細情報.出荷数量(パレット)
          ,xel.sum_shipping_qty                 sum_shipping_qty               -- EDI明細情報.出荷数量(合計、バラ)
          ,xel.indv_stockout_qty                indv_stockout_qty              -- EDI明細情報.欠品数量(バラ)
          ,xel.case_stockout_qty                case_stockout_qty              -- EDI明細情報.欠品数量(ケース)
          ,xel.ball_stockout_qty                ball_stockout_qty              -- EDI明細情報.欠品数量(ボール)
          ,xel.sum_stockout_qty                 sum_stockout_qty               -- EDI明細情報.欠品数量(合計、バラ)
          ,xel.case_qty                         case_qty                       -- EDI明細情報.ケース個口数
          ,xel.fold_container_indv_qty          fold_container_indv_qty        -- EDI明細情報.オリコン(バラ)個口数
          ,xel.order_unit_price                 order_unit_price               -- EDI明細情報.原単価(発注)
          ,oola.unit_selling_price              unit_selling_price             -- 受注明細.販売単価
          ,xel.order_cost_amt                   order_cost_amt                 -- EDI明細情報.原価金額(発注)
          ,xel.shipping_cost_amt                shipping_cost_amt              -- EDI明細情報.原価金額(出荷)
          ,xel.stockout_cost_amt                stockout_cost_amt              -- EDI明細情報.原価金額(欠品)
          ,xel.selling_price                    selling_price                  -- EDI明細情報.売単価
          ,xel.order_price_amt                  order_price_amt                -- EDI明細情報.売価金額(発注)
          ,xel.shipping_price_amt               shipping_price_amt             -- EDI明細情報.売価金額(出荷)
          ,xel.stockout_price_amt               stockout_price_amt             -- EDI明細情報.売価金額(欠品)
          ,xel.a_column_department              a_column_department            -- EDI明細情報.Ａ欄(百貨店)
          ,xel.d_column_department              d_column_department            -- EDI明細情報.Ｄ欄(百貨店)
          ,xel.standard_info_depth              standard_info_depth            -- EDI明細情報.規格情報・奥行き
          ,xel.standard_info_height             standard_info_height           -- EDI明細情報.規格情報・高さ
          ,xel.standard_info_width              standard_info_width            -- EDI明細情報.規格情報・幅
          ,xel.standard_info_weight             standard_info_weight           -- EDI明細情報.規格情報・重量
          ,xel.general_succeeded_item1          general_succeeded_item1        -- EDI明細情報.汎用引継ぎ項目１
          ,xel.general_succeeded_item2          general_succeeded_item2        -- EDI明細情報.汎用引継ぎ項目２
          ,xel.general_succeeded_item3          general_succeeded_item3        -- EDI明細情報.汎用引継ぎ項目３
          ,xel.general_succeeded_item4          general_succeeded_item4        -- EDI明細情報.汎用引継ぎ項目４
          ,xel.general_succeeded_item5          general_succeeded_item5        -- EDI明細情報.汎用引継ぎ項目５
          ,xel.general_succeeded_item6          general_succeeded_item6        -- EDI明細情報.汎用引継ぎ項目６
          ,xel.general_succeeded_item7          general_succeeded_item7        -- EDI明細情報.汎用引継ぎ項目７
          ,xel.general_succeeded_item8          general_succeeded_item8        -- EDI明細情報.汎用引継ぎ項目８
          ,xel.general_succeeded_item9          general_succeeded_item9        -- EDI明細情報.汎用引継ぎ項目９
          ,xel.general_succeeded_item10         general_succeeded_item10       -- EDI明細情報.汎用引継ぎ項目１０
          ,xel.general_add_item1                general_add_item1              -- EDI明細情報.汎用付加項目１
          ,xel.general_add_item2                general_add_item2              -- EDI明細情報.汎用付加項目２
          ,xel.general_add_item3                general_add_item3              -- EDI明細情報.汎用付加項目３
          ,xel.general_add_item4                general_add_item4              -- EDI明細情報.汎用付加項目４
          ,xel.general_add_item5                general_add_item5              -- EDI明細情報.汎用付加項目５
          ,xel.general_add_item6                general_add_item6              -- EDI明細情報.汎用付加項目６
          ,xel.general_add_item7                general_add_item7              -- EDI明細情報.汎用付加項目７
          ,xel.general_add_item8                general_add_item8              -- EDI明細情報.汎用付加項目８
          ,xel.general_add_item9                general_add_item9              -- EDI明細情報.汎用付加項目９
          ,xel.general_add_item10               general_add_item10             -- EDI明細情報.汎用付加項目１０
          ,xel.chain_peculiar_area_line         chain_peculiar_area_line       -- EDI明細情報.チェーン店固有エリア(明細)
          ,xel.item_code                        item_code                      -- EDI明細情報.品目コード
          ,xel.line_uom                         line_uom                       -- EDI明細情報.明細単位
          ,xel.order_connection_line_number     order_connection_line_number   -- EDI明細情報.受注関連明細番号
-- ******* 2009/10/05 1.14 N.Maeda MOD START ******* --
--          ,oola.ordered_quantity                ordered_quantity               -- 受注明細.受注数量
          ,CASE
             WHEN ( ooha.order_source_id = gt_order_source_online ) THEN
               oola.ordered_quantity
             ELSE
               ( SELECT SUM ( oola_ilv.ordered_quantity ) ordered_quantity
                 FROM   oe_order_lines_all oola_ilv
                 WHERE  oola_ilv.header_id    = oola.header_id
                 AND    oola_ilv.org_id       = oola.org_id
                 AND    NVL ( oola_ilv.global_attribute3 , oola_ilv.line_id ) = oola.line_id
                 AND    NVL ( oola_ilv.global_attribute4 , oola_ilv.orig_sys_line_ref ) = oola.orig_sys_line_ref
               )
           END                                  ordered_quantity
-- ******* 2009/10/05 1.14 N.Maeda MOD  END  ******* --
          ,xtrv.tax_rate                        tax_rate                       -- 消費税率ビュー.消費税率
--****************************** 2009/06/11 1.10 T.Kitajima ADD START ******************************--
          ,xca3.edi_forward_number              edi_forward_number             -- 顧客追加情報.EDI伝送追番
--****************************** 2009/06/11 1.10 T.Kitajima ADD  END ******************************--
--****************************** 2009/06/24 1.10 T.Kitajima ADD START ******************************--
          ,oola.order_quantity_uom              order_quantity_uom             -- 受注明細.単位
--****************************** 2009/06/24 1.10 T.Kitajima ADD  END ******************************--
    FROM   xxcos_edi_headers                    xeh    -- EDIヘッダ情報
          ,xxcos_edi_lines                      xel    -- EDI明細情報
          ,oe_order_headers_all                 ooha   -- 受注ヘッダ
          ,oe_order_lines_all                   oola   -- 受注明細
          ,hz_cust_accounts                     hca1   -- 拠点マスタ
          ,xxcmm_cust_accounts                  xca1   -- 拠点追加情報
          ,hz_parties                           hp1    -- 拠点パーティ
          ,hz_party_sites                       hps1   -- 拠点パーティサイト
          ,hz_locations                         hl1    -- 拠点事業所
          ,hz_cust_acct_sites_all               hcas1  -- 拠点所在地
          ,hz_cust_accounts                     hca2   -- チェーン店マスタ
          ,xxcmm_cust_accounts                  xca2   -- チェーン店追加情報
          ,hz_parties                           hp2    -- チェーン店パーティ
          ,hz_cust_accounts                     hca3   -- 顧客マスタ
          ,xxcmm_cust_accounts                  xca3   -- 顧客追加情報
          ,hz_parties                           hp3    -- 顧客パーティ
          ,xxcos_tax_rate_v                     xtrv   -- 消費税率ビュー
          ,xxcos_login_base_info_v              xlbiv  -- 拠点(管理元)ビュー
          ,per_all_people_f                     papf   -- 従業員マスタ
          ,per_all_assignments_f                paaf   -- 従業員割当マスタ
          ,ic_item_mst_b                        iimb   -- ＯＰＭ品目マスタ
          ,xxcmn_item_mst_b                     ximb   -- ＯＰＭ品目アドオン
          ,mtl_system_items_b                   msib   -- Disc品目マスタ
          ,xxcmm_system_items_b                 xsib   -- Disc品目アドオン
-- ******* 2009/09/03 1.12 N.Maeda DEL START ******* --
--          ,xxcos_head_prod_class_v              xhpcv  -- 本社商品区分ビュー
-- ******* 2009/09/03 1.12 N.Maeda DEL  END  ******* --
          ,(SELECT ore1.reason_code             reason_code
                  ,ore1.entity_id               entity_id
            FROM   oe_reasons                   ore1
/* 2009/08/10 Ver1.11 Mod Start */
--                  ,(SELECT ore2.entity_id           entity_id
                  ,(SELECT /*+ INDEX( ore2 xxcos_oe_reasons_n04 ) */
                           ore2.entity_id           entity_id
/* 2009/08/10 Ver1.11 Mod Start */
                          ,MAX(ore2.creation_date)  creation_date
                    FROM   oe_reasons               ore2
                    WHERE  ore2.reason_type = cv_reason_type
                    AND    ore2.entity_code = cv_entity_code_line
                    GROUP BY ore2.entity_id
                   )                            ore_max
            WHERE  ore1.entity_id     = ore_max.entity_id
            AND    ore1.creation_date = ore_max.creation_date
           )                                    ore    -- 変更事由
          ,fnd_lookup_values_vl                 flvv1  -- 事由コードマスタ
-- ******* 2009/09/03 1.12 N.Maeda ADD START ******* --
          ,mtl_item_categories            mic
          ,mtl_categories_b               mcb
-- ******* 2009/09/03 1.12 N.Maeda ADD  END  ******* --
    WHERE  xeh.edi_header_info_id         = xel.edi_header_info_id            -- EDIﾍｯﾀﾞ情報.EDIﾍｯﾀﾞ情報ID=EDI明細情報.EDIﾍｯﾀﾞ情報ID
    AND    xeh.creation_class             =                                   -- EDIﾍｯﾀﾞ情報.作成元区分='01'(受注ﾃﾞｰﾀ)
         ( SELECT flvv.meaning   creation_class
           FROM   fnd_lookup_values_vl  flvv
           WHERE  flvv.lookup_type        = cv_edi_create_class
           AND    flvv.lookup_code        = cv_edi_create_class_c
           AND    flvv.enabled_flag       = cv_y                -- 有効
           AND (( flvv.start_date_active IS NULL )
           OR   ( flvv.start_date_active <= cd_process_date ))
           AND (( flvv.end_date_active   IS NULL )
           OR   ( flvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
         )
    AND    xeh.edi_delivery_schedule_flag = cv_n                              -- EDIﾍｯﾀﾞ情報.EDI納品予定送信済ﾌﾗｸﾞ='N'(未送信)
    AND    xeh.data_type_code             = cv_data_type_edi                  -- EDIﾍｯﾀﾞ情報.ﾃﾞｰﾀ種ｺｰﾄﾞ='11'(受注EDI)
    AND    xeh.edi_chain_code             = gt_edi_c_code                     -- EDIﾍｯﾀﾞ情報.EDIﾁｪｰﾝ店ｺｰﾄﾞ=inﾊﾟﾗﾒｰﾀ.EDIﾁｪｰﾝ店ｺｰﾄﾞ
    AND    TRUNC(xeh.shop_delivery_date)    BETWEEN gt_shop_date_from         -- EDIﾍｯﾀﾞ情報.店舗納品日 BETWEEN inﾊﾟﾗﾒｰﾀ.店舗納品日From
                                                AND gt_shop_date_to           --                            AND inﾊﾟﾗﾒｰﾀ.店舗納品日To
    AND  ( gt_sale_class                 IS NULL                              -- inﾊﾟﾗﾒｰﾀ.定番特売区分 IS NULL
    OR     gt_sale_class                  = cv_sale_class_all                 -- inﾊﾟﾗﾒｰﾀ.定番特売区分='0'(両方)
    OR     xeh.ar_sale_class              = gt_sale_class )                   -- EDIﾍｯﾀﾞ情報.特売区分=inﾊﾟﾗﾒｰﾀ.定番特売区分
    AND    ooha.sold_to_org_id            = hca3.cust_account_id              -- 受注ﾍｯﾀﾞ.顧客ID=顧客ﾏｽﾀ.顧客ID
    AND    hca3.customer_class_code       = cv_cust_code_cust                 -- 顧客ﾏｽﾀ.顧客区分='10'(顧客)
    AND    xca3.tsukagatazaiko_div       IN (cv_tukzik_div_tuk,               -- 顧客ﾏｽﾀ.通過在庫型区分 IN ('11'(ｾﾝﾀｰ納品(通過型･受注)),
                                             cv_tukzik_div_zik,               --                            '12'(ｾﾝﾀｰ納品(在庫型･受注)),
                                             cv_tukzik_div_tnp)               --                            '24'(店舗納品))
    AND    xca3.chain_store_code          = gt_edi_c_code                     -- 顧客ﾏｽﾀ.ﾁｪｰﾝ店ｺｰﾄﾞ(EDI)=inﾊﾟﾗﾒｰﾀ.EDIﾁｪｰﾝ店ｺｰﾄﾞ
    AND    xca3.edi_forward_number        = gt_edi_f_number                   -- 顧客ﾏｽﾀ.EDI伝送追番=inﾊﾟﾗﾒｰﾀ.EDI伝送追番
    AND  ( gt_area_code                  IS NULL                              -- inﾊﾟﾗﾒｰﾀ.地区ｺｰﾄﾞ IS NULL
    OR     xca3.edi_district_code         = gt_area_code )                    -- 顧客ﾏｽﾀ.地区ｺｰﾄﾞ=inﾊﾟﾗﾒｰﾀ.地区ｺｰﾄﾞ
    AND    hca3.cust_account_id           = xtrv.cust_account_id              -- 顧客ﾏｽﾀ.顧客ID=消費税率ﾋﾞｭｰ.顧客ID
    AND    xca3.tax_div                   = xtrv.tax_div                      -- 顧客ﾏｽﾀ.消費税区分=消費税率ﾋﾞｭｰ.消費税区分
    AND    xtrv.set_of_books_id           = gn_bks_id                         -- 消費税率ﾋﾞｭｰ.GL会計帳簿ID=[A-2].GL会計帳簿ID
    AND    TRUNC(oola.request_date)      >= xtrv.start_date_active            -- 受注明細.要求日>=消費税率ﾋﾞｭｰ.適用開始日
    AND    TRUNC(oola.request_date)      <= NVL(xtrv.end_date_active,         -- 受注明細.要求日<=NVL(消費税率ﾋﾞｭｰ.適用終了日,
                                                gd_max_date)                  --                      [A-2].MAX日付)
/* 2009/02/25 Ver1.3 Add Start */
    AND    TRUNC(oola.request_date)      >= xtrv.tax_start_date               -- 受注明細.要求日>=消費税率ﾋﾞｭｰ.税開始日
    AND    TRUNC(oola.request_date)      <= NVL(xtrv.tax_end_date,            -- 受注明細.要求日<=NVL(消費税率ﾋﾞｭｰ.税終了日,
                                                gd_max_date)                  --                      [A-2].MAX日付)
/* 2009/02/25 Ver1.3 Add  End  */
    AND    xeh.edi_chain_code             = xca2.chain_store_code             -- EDIﾍｯﾀﾞ情報.EDIﾁｪｰﾝ店ｺｰﾄﾞ=ﾁｪｰﾝ店ﾏｽﾀ.ﾁｪｰﾝ店ｺｰﾄﾞ(EDI)
    AND    hca2.customer_class_code       = cv_cust_code_chain                -- ﾁｪｰﾝ店ﾏｽﾀ.顧客区分='18'(ﾁｪｰﾝ店)
/* 2009/02/20 Ver1.1 Mod Start */
--  AND (( xca2.handwritten_slip_div      = cv_n                              -- ﾁｪｰﾝ店ﾏｽﾀ.手書伝票伝送区分='N'(手書送信対象外)
    AND (( xca2.handwritten_slip_div      = cv_2                              -- ﾁｪｰﾝ店ﾏｽﾀ.手書伝票伝送区分='2'(手書送信対象外)
    AND    xeh.medium_class               = cv_medium_class_edi )             -- EDIﾍｯﾀﾞ情報.媒体区分='00'(EDI)
--  OR     xca2.handwritten_slip_div      = cv_y )                            -- ﾁｪｰﾝ店ﾏｽﾀ.手書伝票伝送区分='Y'(手書送信対象)
    OR     xca2.handwritten_slip_div      = cv_1 )                            -- ﾁｪｰﾝ店ﾏｽﾀ.手書伝票伝送区分='1'(手書送信対象)
/* 2009/02/20 Ver1.1 Mod  End  */
    AND    hca2.cust_account_id           = xca2.customer_id                  -- ﾁｪｰﾝ店ﾏｽﾀ.顧客ID=ﾁｪｰﾝ店追加情報.顧客ID
    AND    hca1.account_number            = xca3.delivery_base_code           -- 拠点ﾏｽﾀ.顧客ｺｰﾄﾞ=顧客ﾏｽﾀ.納品拠点ｺｰﾄﾞ
    AND    hca1.customer_class_code       = cv_cust_code_base                 -- 拠点ﾏｽﾀ.顧客区分='1'(拠点)
    AND    hca1.party_id                  = hp1.party_id                      -- 拠点ﾏｽﾀ.ﾊﾟｰﾃｨID=拠点ﾊﾟｰﾃｨ.ﾊﾟｰﾃｨID
    AND    hcas1.cust_account_id          = hca1.cust_account_id              -- 拠点所在地.顧客ID=顧客ﾏｽﾀ.顧客ID
    AND    hps1.location_id               = hl1.location_id                   -- 拠点ﾊﾟｰﾃｨｻｲﾄ.所在地ID=拠点事業所.所在地ID
    AND    hps1.party_site_id             = hcas1.party_site_id               -- 拠点ﾊﾟｰﾃｨｻｲﾄ.ﾊﾟｰﾃｨｻｲﾄID=拠点所在地.ﾊﾟｰﾃｨｻｲﾄID
    AND    hcas1.org_id                   = gn_org_id                         -- 拠点所在地.組織ID=[A-2].営業単位
    AND    hca1.cust_account_id           = xca1.customer_id                  -- 拠点ﾏｽﾀ.顧客ID=拠点追加情報.顧客ID
    AND    hca3.cust_account_id           = xca3.customer_id                  -- 顧客ﾏｽﾀ.顧客ID=顧客追加情報.顧客ID
    AND    hca2.party_id                  = hp2.party_id                      -- ﾁｪｰﾝ店ﾏｽﾀ.ﾊﾟｰﾃｨID=ﾁｪｰﾝ店ﾊﾟｰﾃｨ.ﾊﾟｰﾃｨID
    AND    hp2.duns_number_c             <> cv_cust_status_90                 -- ﾁｪｰﾝ店ﾊﾟｰﾃｨ.顧客ｽﾃｰﾀｽ<>'90'(中止決裁済)
    AND    hca3.party_id                  = hp3.party_id                      -- 顧客ﾏｽﾀ.ﾊﾟｰﾃｨID=顧客ﾊﾟｰﾃｨ.ﾊﾟｰﾃｨID
    AND    xca3.delivery_base_code        = xlbiv.base_code                   -- 顧客追加情報.納品拠点ｺｰﾄﾞ=拠点(管理元)ﾋﾞｭｰ.拠点ｺｰﾄﾞ
    AND    xca3.delivery_base_code        = paaf.ass_attribute5               -- 顧客追加情報.納品拠点ｺｰﾄﾞ=従業員割当ﾏｽﾀ.所属ｺｰﾄﾞ
    AND    paaf.effective_start_date     <= cd_process_date                   -- 従業員割当ﾏｽﾀ.適用開始日<=業務日付
    AND    paaf.effective_end_date       >= cd_process_date                   -- 従業員割当ﾏｽﾀ.適用終了日>=業務日付
    AND    papf.person_id                 = paaf.person_id                    -- 従業員ﾏｽﾀ.従業員ID=従業員割当ﾏｽﾀ.従業員ID
    AND    papf.attribute11               = cv_position                       -- 従業員ﾏｽﾀ.職位(新)='002'(支店長)
    AND    papf.effective_start_date     <= cd_process_date                   -- 従業員ﾏｽﾀ.適用開始日<=業務日付
    AND    papf.effective_end_date       >= cd_process_date                   -- 従業員ﾏｽﾀ.適用終了日>=業務日付
--****************************** 2009/06/19 1.10 T.Kitajima MOD START ******************************--
    AND    ooha.org_id                    = gn_org_id                         -- 受注ﾍｯﾀﾞ.組織ID=[A-2].営業単位
--****************************** 2009/06/19 1.10 T.Kitajima MOD  END  ******************************--
    AND    ooha.header_id                 = oola.header_id                    -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID=受注明細.受注ﾍｯﾀﾞID
    AND    ooha.orig_sys_document_ref     = xeh.order_connection_number       -- 受注ﾍｯﾀﾞ.外部ｼｽﾃﾑ受注関連番号=EDIﾍｯﾀﾞ情報.受注関連番号
    AND    oola.orig_sys_line_ref         = xel.order_connection_line_number  -- 受注明細.外部ｼｽﾃﾑ受注明細番号=EDI明細情報.受注関連明細番号
--****************************** 2009/06/11 1.10 T.Kitajima MOD START ******************************--
--    AND    xel.line_no                    = oola.line_number                  -- EDI明細情報.行No=受注明細.明細番号
    AND    xel.order_connection_line_number
                                          = oola.orig_sys_line_ref            -- EDI明細情報.受注関連明細番号 = 受注明細.外部ｼｽﾃﾑ受注明細番号
--****************************** 2009/06/11 1.10 T.Kitajima MOD  END  ******************************--
    AND    oola.inventory_item_id         = msib.inventory_item_id            -- 受注明細.品目ID=Disc品目ﾏｽﾀ.品目ID
    AND    msib.segment1                  = iimb.item_no                      -- Disc品目ﾏｽﾀ.品目ｺｰﾄﾞ=OPM品目ﾏｽﾀ.品目ｺｰﾄﾞ
    AND    iimb.item_id                   = ximb.item_id                      -- OPM品目ﾏｽﾀ.品目ID=OPM品目ｱﾄﾞｵﾝ.品目ID
    AND    ximb.start_date_active        <= cd_process_date                   -- OPM品目ｱﾄﾞｵﾝ.適用開始日<=業務日付
    AND    ximb.end_date_active          >= cd_process_date                   -- OPM品目ｱﾄﾞｵﾝ.適用終了日>=業務日付
    AND    msib.organization_id           = gn_organization_id                -- Disc品目ﾏｽﾀ.組織ID=[A-2].在庫組織ID
    AND    msib.segment1                  = xsib.item_code                    -- Disc品目ﾏｽﾀ.品目ｺｰﾄﾞ=Disc品目ｱﾄﾞｵﾝ.品目ｺｰﾄﾞ
-- ******* 2009/09/03 1.12 N.Maeda MOD START ******* --
--    AND    msib.inventory_item_id         = xhpcv.inventory_item_id           -- Disc品目ﾏｽﾀ.品目ID=本社商品区分ﾋﾞｭｰ.品目ID
    AND msib.organization_id = gn_organization_id
    AND gn_organization_id = mic.organization_id
    AND msib.inventory_item_id = mic.inventory_item_id
    AND mic.category_set_id    = gt_category_set_id
    AND mic.category_id        = mcb.category_id
    AND ( mcb.disable_date IS NULL OR mcb.disable_date > cd_process_date )
    AND   mcb.enabled_flag   = 'Y'      -- カテゴリ有効フラグ
    AND   cd_process_date BETWEEN NVL(mcb.start_date_active, cd_process_date)
                                     AND   NVL(mcb.end_date_active, cd_process_date)
    AND   msib.enabled_flag  = 'Y'      -- 品目マスタ有効フラグ
    AND   cd_process_date BETWEEN NVL(msib.start_date_active, cd_process_date)
                                     AND  NVL(msib.end_date_active, cd_process_date)
-- ******* 2009/09/03 1.12 N.Maeda MOD  END  ******* --
    AND    ore.entity_id(+)               = oola.line_id                      -- 変更事由.ID=受注明細.明細ID
    AND    flvv1.lookup_type(+)           = cv_reason_type                    -- 事由ｺｰﾄﾞﾏｽﾀ.ﾀｲﾌﾟ=変更事由
    AND    flvv1.lookup_code(+)           = ore.reason_code                   -- 事由ｺｰﾄﾞﾏｽﾀ.ｺｰﾄﾞ=変更事由.理由ｺｰﾄﾞ
    AND (( flvv1.start_date_active IS NULL )
    OR   ( flvv1.start_date_active <= cd_process_date ))
    AND (( flvv1.end_date_active   IS NULL )
    OR   ( flvv1.end_date_active   >= cd_process_date ))                      -- 業務日付がFROM-TO内
-- ***************************** 2009/07/10 1.10 N.Maeda    ADD START ******************************--
    AND (( ooha.global_attribute3 IS NULL )
    OR   ( ooha.global_attribute3 = '02' ) )
-- ***************************** 2009/07/10 1.10 N.Maeda    ADD  END  ******************************--
    ORDER BY
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
--           xeh.invoice_number                 -- EDIヘッダ情報.伝票番号
--          ,xel.line_no                        -- EDI明細情報.行Ｎｏ
           xeh.delivery_center_code            --1.EDIヘッダ情報.納入センターコード
          ,xeh.shop_code                       --2.EDIヘッダ情報.店コード
          ,xeh.invoice_number                  --3.EDIヘッダ情報.伝票番号
-- ********* 2009/09/25 1.13 N.Maeda ADD START ********* --
          ,xeh.edi_header_info_id              -- EDIヘッダ情報.EDIヘッダ情報ID
-- ********* 2009/09/25 1.13 N.Maeda ADD  END  ********* --
          ,xel.line_no                         --4.EDI明細情報.行No
          ,xel.packing_number                  --5.EDI明細情報.梱包番号
--****************************** 2009/06/12 1.10 T.Kitajima MOD  END  ******************************--
    FOR UPDATE OF
           xeh.edi_header_info_id             -- EDIヘッダ情報
          ,xel.edi_header_info_id             -- EDI明細情報
          NOWAIT
    ;
--
  -- ===============================
  -- ユーザー定義グローバルRECORD型宣言
  -- ===============================
  -- ヘッダ情報
  TYPE g_header_data_rtype IS RECORD(
    delivery_base_code        xxcmm_cust_accounts.delivery_base_code%TYPE  -- 納品拠点コード
   ,delivery_base_name        hz_parties.party_name%TYPE                   -- 納品拠点名
   ,delivery_base_phonetic    hz_parties.organization_name_phonetic%TYPE   -- 納品拠点カナ
   ,edi_chain_name            hz_parties.party_name%TYPE                   -- EDIチェーン店名
   ,edi_chain_name_phonetic   hz_parties.organization_name_phonetic%TYPE   -- EDIチェーン店カナ
  );
--
  -- 伝票別合計
  TYPE g_invoice_total_rtype IS RECORD(
    indv_order_qty       xxcos_edi_headers.invoice_indv_order_qty%TYPE       -- 発注数量(バラ)
   ,case_order_qty       xxcos_edi_headers.invoice_case_order_qty%TYPE       -- 発注数量(ケース)
   ,ball_order_qty       xxcos_edi_headers.invoice_ball_order_qty%TYPE       -- 発注数量(ボール)
   ,sum_order_qty        xxcos_edi_headers.invoice_sum_order_qty%TYPE        -- 発注数量(合計、バラ)
   ,indv_shipping_qty    xxcos_edi_headers.invoice_indv_shipping_qty%TYPE    -- 出荷数量(バラ)
   ,case_shipping_qty    xxcos_edi_headers.invoice_case_shipping_qty%TYPE    -- 出荷数量(ケース)
   ,ball_shipping_qty    xxcos_edi_headers.invoice_ball_shipping_qty%TYPE    -- 出荷数量(ボール)
   ,pallet_shipping_qty  xxcos_edi_headers.invoice_pallet_shipping_qty%TYPE  -- 出荷数量(パレット)
   ,sum_shipping_qty     xxcos_edi_headers.invoice_sum_shipping_qty%TYPE     -- 出荷数量(合計、バラ)
   ,indv_stockout_qty    xxcos_edi_headers.invoice_indv_stockout_qty%TYPE    -- 欠品数量(バラ)
   ,case_stockout_qty    xxcos_edi_headers.invoice_case_stockout_qty%TYPE    -- 欠品数量(ケース)
   ,ball_stockout_qty    xxcos_edi_headers.invoice_ball_stockout_qty%TYPE    -- 欠品数量(ボール)
   ,sum_stockout_qty     xxcos_edi_headers.invoice_sum_stockout_qty%TYPE     -- 欠品数量(合計、バラ)
   ,case_qty             xxcos_edi_headers.invoice_case_qty%TYPE             -- ケース個口数
   ,order_cost_amt       xxcos_edi_headers.invoice_order_cost_amt%TYPE       -- 原価金額(発注)
   ,shipping_cost_amt    xxcos_edi_headers.invoice_shipping_cost_amt%TYPE    -- 原価金額(出荷)
   ,stockout_cost_amt    xxcos_edi_headers.invoice_stockout_cost_amt%TYPE    -- 原価金額(欠品)
   ,order_price_amt      xxcos_edi_headers.invoice_order_price_amt%TYPE      -- 売価金額(発注)
   ,shipping_price_amt   xxcos_edi_headers.invoice_shipping_price_amt%TYPE   -- 売価金額(出荷)
   ,stockout_price_amt   xxcos_edi_headers.invoice_stockout_price_amt%TYPE   -- 売価金額(欠品)
  );
--
  -- EDIヘッダ情報
  TYPE g_edi_header_rtype IS RECORD(
    edi_header_info_id           xxcos_edi_headers.edi_header_info_id%TYPE           -- EDIヘッダ情報ID
   ,process_date                 xxcos_edi_headers.process_date%TYPE                 -- 処理日
   ,process_time                 xxcos_edi_headers.process_time%TYPE                 -- 処理時刻
   ,base_code                    xxcos_edi_headers.base_code%TYPE                    -- 拠点(部門)コード
   ,base_name                    xxcos_edi_headers.base_name%TYPE                    -- 拠点名(正式名)
   ,base_name_alt                xxcos_edi_headers.base_name_alt%TYPE                -- 拠点名(カナ)
   ,customer_code                xxcos_edi_headers.customer_code%TYPE                -- 顧客コード
   ,customer_name                xxcos_edi_headers.customer_name%TYPE                -- 顧客名(漢字)
   ,customer_name_alt            xxcos_edi_headers.customer_name_alt%TYPE            -- 顧客名(カナ)
   ,shop_code                    xxcos_edi_headers.shop_code%TYPE                    -- 店コード
   ,shop_name                    xxcos_edi_headers.shop_name%TYPE                    -- 店名(漢字)
   ,shop_name_alt                xxcos_edi_headers.shop_name_alt%TYPE                -- 店名(カナ)
   ,center_delivery_date         xxcos_edi_headers.center_delivery_date%TYPE         -- センター納品日
   ,order_no_ebs                 xxcos_edi_headers.order_no_ebs%TYPE                 -- 受注No(EBS)
   ,contact_to                   xxcos_edi_headers.contact_to%TYPE                   -- 連絡先
   ,area_code                    xxcos_edi_headers.area_code%TYPE                    -- 地区コード
   ,area_name                    xxcos_edi_headers.area_name%TYPE                    -- 地区名(漢字)
   ,area_name_alt                xxcos_edi_headers.area_name_alt%TYPE                -- 地区名(カナ)
   ,vendor_code                  xxcos_edi_headers.vendor_code%TYPE                  -- 取引先コード
   ,vendor_name                  xxcos_edi_headers.vendor_name%TYPE                  -- 取引先名(漢字)
   ,vendor_name1_alt             xxcos_edi_headers.vendor_name1_alt%TYPE             -- 取引先名1(カナ)
   ,vendor_name2_alt             xxcos_edi_headers.vendor_name2_alt%TYPE             -- 取引先名2(カナ)
   ,vendor_tel                   xxcos_edi_headers.vendor_tel%TYPE                   -- 取引先TEL
   ,vendor_charge                xxcos_edi_headers.vendor_charge%TYPE                -- 取引先担当者
   ,vendor_address               xxcos_edi_headers.vendor_address%TYPE               -- 取引先住所(漢字)
   ,delivery_schedule_time       xxcos_edi_headers.delivery_schedule_time%TYPE       -- 納品予定時間
   ,carrier_means                xxcos_edi_headers.carrier_means%TYPE                -- 運送手段
   ,eos_handwriting_class        xxcos_edi_headers.eos_handwriting_class%TYPE        -- EOS･手書区分
   ,invoice_indv_order_qty       xxcos_edi_headers.invoice_indv_order_qty%TYPE       -- (伝票計)発注数量(バラ)
   ,invoice_case_order_qty       xxcos_edi_headers.invoice_case_order_qty%TYPE       -- (伝票計)発注数量(ケース)
   ,invoice_ball_order_qty       xxcos_edi_headers.invoice_ball_order_qty%TYPE       -- (伝票計)発注数量(ボール)
   ,invoice_sum_order_qty        xxcos_edi_headers.invoice_sum_order_qty%TYPE        -- (伝票計)発注数量(合計、バラ)
   ,invoice_indv_shipping_qty    xxcos_edi_headers.invoice_indv_shipping_qty%TYPE    -- (伝票計)出荷数量(バラ)
   ,invoice_case_shipping_qty    xxcos_edi_headers.invoice_case_shipping_qty%TYPE    -- (伝票計)出荷数量(ケース)
   ,invoice_ball_shipping_qty    xxcos_edi_headers.invoice_ball_shipping_qty%TYPE    -- (伝票計)出荷数量(ボール)
   ,invoice_pallet_shipping_qty  xxcos_edi_headers.invoice_pallet_shipping_qty%TYPE  -- (伝票計)出荷数量(パレット)
   ,invoice_sum_shipping_qty     xxcos_edi_headers.invoice_sum_shipping_qty%TYPE     -- (伝票計)出荷数量(合計、バラ)
   ,invoice_indv_stockout_qty    xxcos_edi_headers.invoice_indv_stockout_qty%TYPE    -- (伝票計)欠品数量(バラ)
   ,invoice_case_stockout_qty    xxcos_edi_headers.invoice_case_stockout_qty%TYPE    -- (伝票計)欠品数量(ケース)
   ,invoice_ball_stockout_qty    xxcos_edi_headers.invoice_ball_stockout_qty%TYPE    -- (伝票計)欠品数量(ボール)
   ,invoice_sum_stockout_qty     xxcos_edi_headers.invoice_sum_stockout_qty%TYPE     -- (伝票計)欠品数量(合計、バラ)
   ,invoice_case_qty             xxcos_edi_headers.invoice_case_qty%TYPE             -- (伝票計)ケース個口数
   ,invoice_fold_container_qty   xxcos_edi_headers.invoice_fold_container_qty%TYPE   -- (伝票計)オリコン(バラ)個口数
   ,invoice_order_cost_amt       xxcos_edi_headers.invoice_order_cost_amt%TYPE       -- (伝票計)原価金額(発注)
   ,invoice_shipping_cost_amt    xxcos_edi_headers.invoice_shipping_cost_amt%TYPE    -- (伝票計)原価金額(出荷)
   ,invoice_stockout_cost_amt    xxcos_edi_headers.invoice_stockout_cost_amt%TYPE    -- (伝票計)原価金額(欠品)
   ,invoice_order_price_amt      xxcos_edi_headers.invoice_order_price_amt%TYPE      -- (伝票計)売価金額(発注)
   ,invoice_shipping_price_amt   xxcos_edi_headers.invoice_shipping_price_amt%TYPE   -- (伝票計)売価金額(出荷)
   ,invoice_stockout_price_amt   xxcos_edi_headers.invoice_stockout_price_amt%TYPE   -- (伝票計)売価金額(欠品)
   ,edi_delivery_schedule_flag   xxcos_edi_headers.edi_delivery_schedule_flag%TYPE   -- EDI納品予定送信済フラグ
  );
--
  -- EDI明細情報
  TYPE g_edi_line_rtype IS RECORD(
    edi_line_info_id     xxcos_edi_lines.edi_line_info_id%TYPE     -- EDI明細情報ID
   ,edi_header_info_id   xxcos_edi_lines.edi_header_info_id%TYPE   -- EDIヘッダ情報ID
   ,line_no              xxcos_edi_lines.line_no%TYPE              -- 行No
   ,stockout_class       xxcos_edi_lines.stockout_class%TYPE       -- 欠品区分
   ,stockout_reason      xxcos_edi_lines.stockout_reason%TYPE      -- 欠品理由
   ,product_code_itouen  xxcos_edi_lines.product_code_itouen%TYPE  -- 商品コード(伊藤園)
   ,jan_code             xxcos_edi_lines.jan_code%TYPE             -- JANコード
   ,itf_code             xxcos_edi_lines.itf_code%TYPE             -- ITFコード
   ,prod_class           xxcos_edi_lines.prod_class%TYPE           -- 商品区分
   ,product_name         xxcos_edi_lines.product_name%TYPE         -- 商品名(漢字)
   ,product_name2_alt    xxcos_edi_lines.product_name2_alt%TYPE    -- 商品名2(カナ)
   ,item_standard2       xxcos_edi_lines.item_standard2%TYPE       -- 規格2
   ,num_of_cases         xxcos_edi_lines.num_of_cases%TYPE         -- ケース入数
   ,num_of_ball          xxcos_edi_lines.num_of_ball%TYPE          -- ボール入数
   ,indv_order_qty       xxcos_edi_lines.indv_order_qty%TYPE       -- 発注数量(バラ)
   ,case_order_qty       xxcos_edi_lines.case_order_qty%TYPE       -- 発注数量(ケース)
   ,ball_order_qty       xxcos_edi_lines.ball_order_qty%TYPE       -- 発注数量(ボール)
   ,sum_order_qty        xxcos_edi_lines.sum_order_qty%TYPE        -- 発注数量(合計、バラ)
   ,indv_shipping_qty    xxcos_edi_lines.indv_shipping_qty%TYPE    -- 出荷数量(バラ)
   ,case_shipping_qty    xxcos_edi_lines.case_shipping_qty%TYPE    -- 出荷数量(ケース)
   ,ball_shipping_qty    xxcos_edi_lines.ball_shipping_qty%TYPE    -- 出荷数量(ボール)
   ,pallet_shipping_qty  xxcos_edi_lines.pallet_shipping_qty%TYPE  -- 出荷数量(パレット)
   ,sum_shipping_qty     xxcos_edi_lines.sum_shipping_qty%TYPE     -- 出荷数量(合計、バラ)
   ,indv_stockout_qty    xxcos_edi_lines.indv_stockout_qty%TYPE    -- 欠品数量(バラ)
   ,case_stockout_qty    xxcos_edi_lines.case_stockout_qty%TYPE    -- 欠品数量(ケース)
   ,ball_stockout_qty    xxcos_edi_lines.ball_stockout_qty%TYPE    -- 欠品数量(ボール)
   ,sum_stockout_qty     xxcos_edi_lines.sum_stockout_qty%TYPE     -- 欠品数量(合計、バラ)
   ,shipping_unit_price  xxcos_edi_lines.shipping_unit_price%TYPE  -- 原単価(出荷)
   ,shipping_cost_amt    xxcos_edi_lines.shipping_cost_amt%TYPE    -- 原価金額(出荷)
   ,stockout_cost_amt    xxcos_edi_lines.stockout_cost_amt%TYPE    -- 原価金額(欠品)
   ,shipping_price_amt   xxcos_edi_lines.shipping_price_amt%TYPE   -- 売価金額(出荷)
   ,stockout_price_amt   xxcos_edi_lines.stockout_price_amt%TYPE   -- 売価金額(欠品)
   ,general_add_item1    xxcos_edi_lines.general_add_item1%TYPE    -- 汎用付加項目1
   ,general_add_item2    xxcos_edi_lines.general_add_item2%TYPE    -- 汎用付加項目2
   ,general_add_item3    xxcos_edi_lines.general_add_item3%TYPE    -- 汎用付加項目3
   ,item_code            xxcos_edi_lines.item_code%TYPE            -- 品目コード
  );
--
  -- レコード定義
  gt_header_data        g_header_data_rtype;    -- ヘッダ情報
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型宣言
  -- ===============================
  TYPE g_edi_order_cur_ttype  IS TABLE OF edi_order_cur%ROWTYPE  INDEX BY BINARY_INTEGER;  -- EDI受注データ
  TYPE g_edi_header_ttype     IS TABLE OF g_edi_header_rtype     INDEX BY BINARY_INTEGER;  -- EDIヘッダ情報
  TYPE g_edi_line_ttype       IS TABLE OF g_edi_line_rtype       INDEX BY BINARY_INTEGER;  -- EDI明細情報
  TYPE g_data_record_ttype    IS TABLE OF VARCHAR2(32767)        INDEX BY BINARY_INTEGER;  -- 編集後のデータ取得用
  TYPE g_data_ttype           IS TABLE OF xxcos_common2_pkg.g_layout_ttype  INDEX BY BINARY_INTEGER;  -- 納品予定データ
--
  -- テーブル定義
  gt_edi_order_tab    g_edi_order_cur_ttype;  -- EDI受注データ
  gt_edi_header_tab   g_edi_header_ttype;     -- EDIヘッダ情報
  gt_edi_line_tab     g_edi_line_ttype;       -- EDI明細情報
  gt_data_record_tab  g_data_record_ttype;    -- 編集後のデータ取得用
  gt_data_tab         g_data_ttype;           -- 納品予定データ
--
  /**********************************************************************************
   * Procedure Name   : check_param
   * Description      : パラメータチェック(A-1)
   ***********************************************************************************/
  PROCEDURE check_param(
    iv_file_name        IN  VARCHAR2,     --   1.ファイル名
    iv_make_class       IN  VARCHAR2,     --   2.作成区分
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI伝送追番
    iv_edi_f_number_f   IN  VARCHAR2,     --   4.EDI伝送追番(ファイル名用)
    iv_edi_f_number_s   IN  VARCHAR2,     --   5.EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,     --   6.店舗納品日From
    iv_shop_date_to     IN  VARCHAR2,     --   7.店舗納品日To
    iv_sale_class       IN  VARCHAR2,     --   8.定番特売区分
    iv_area_code        IN  VARCHAR2,     --   9.地区コード
    iv_center_date      IN  VARCHAR2,     --  10.センター納品日
    iv_delivery_time    IN  VARCHAR2,     --  11.納品時刻
    iv_delivery_charge  IN  VARCHAR2,     --  12.納品担当者
    iv_carrier_means    IN  VARCHAR2,     --  13.輸送手段
    iv_proc_date        IN  VARCHAR2,     --  14.処理日
    iv_proc_time        IN  VARCHAR2,     --  15.処理時刻
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param'; -- プログラム名
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
    lv_param_msg   VARCHAR2(5000);  -- パラメーター出力用
    lv_tkn_value1  VARCHAR2(50);    -- トークン取得用1
    lv_tkn_value2  VARCHAR2(50);    -- トークン取得用2
    ln_err_chk     NUMBER(1);       -- エラーチェック用
    lv_err_msg     VARCHAR2(5000);  -- エラー出力用
    lt_make_class  fnd_lookup_values_vl.meaning%TYPE;  -- 作成区分
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
    --==============================================================
    -- コンカレントの共通の初期出力
    --==============================================================
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- 「作成区分」が、'送信'か'ラベル作成'の場合
    IF ( iv_make_class = cv_make_class_transe )
    OR ( iv_make_class = cv_make_class_label )
    THEN
      -- パラメータ出力メッセージ取得
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション
                        ,iv_name         => cv_msg_param1      -- パラメーター出力
                        ,iv_token_name1  => cv_tkn_param01     -- トークンコード１
                        ,iv_token_value1 => iv_make_class      -- 作成区分
                        ,iv_token_name2  => cv_tkn_param02     -- トークンコード２
                        ,iv_token_value2 => iv_edi_c_code      -- EDIチェーン店コード
                        ,iv_token_name3  => cv_tkn_param03     -- トークンコード３
/* 2009/05/12 Ver1.8 Mod Start */
--                        ,iv_token_value3 => iv_edi_f_number    -- EDI伝送追番
--                        ,iv_token_name4  => cv_tkn_param04     -- トークンコード４
--                        ,iv_token_value4 => iv_shop_date_from  -- 店舗納品日From
--                        ,iv_token_name5  => cv_tkn_param05     -- トークンコード５
--                        ,iv_token_value5 => iv_shop_date_to    -- 店舗納品日To
--                        ,iv_token_name6  => cv_tkn_param06     -- トークンコード６
--                        ,iv_token_value6 => iv_sale_class      -- 定番特売区分
--                        ,iv_token_name7  => cv_tkn_param07     -- トークンコード７
--                        ,iv_token_value7 => iv_area_code       -- 地区コード
--                        ,iv_token_name8  => cv_tkn_param08     -- トークンコード８
--                        ,iv_token_value8 => iv_center_date     -- センター納品日
                        ,iv_token_value3 => iv_edi_f_number_f  -- EDI伝送追番(ファイル名用)
                        ,iv_token_name4  => cv_tkn_param04     -- トークンコード４
                        ,iv_token_value4 => iv_edi_f_number_s  -- EDI伝送追番(抽出条件用)
                        ,iv_token_name5  => cv_tkn_param05     -- トークンコード５
                        ,iv_token_value5 => iv_shop_date_from  -- 店舗納品日From
                        ,iv_token_name6  => cv_tkn_param06     -- トークンコード６
                        ,iv_token_value6 => iv_shop_date_to    -- 店舗納品日To
                        ,iv_token_name7  => cv_tkn_param07     -- トークンコード７
                        ,iv_token_value7 => iv_sale_class      -- 定番特売区分
                        ,iv_token_name8  => cv_tkn_param08     -- トークンコード８
                        ,iv_token_value8 => iv_area_code       -- 地区コード
                        ,iv_token_name9  => cv_tkn_param09     -- トークンコード９
                        ,iv_token_value9 => iv_center_date     -- センター納品日
/* 2009/05/12 Ver1.8 Mod End   */
                      );
      lv_param_msg := lv_param_msg ||
                      xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- アプリケーション
                        ,iv_name         => cv_msg_param2       -- パラメーター出力
/* 2009/05/12 Ver1.8 Mod Start */
--                        ,iv_token_name1  => cv_tkn_param09      -- トークンコード９
                        ,iv_token_name1  => cv_tkn_param10      -- トークンコード１０
                        ,iv_token_value1 => iv_delivery_time    -- 納品時刻
--                        ,iv_token_name2  => cv_tkn_param10      -- トークンコード１０
                        ,iv_token_name2  => cv_tkn_param11      -- トークンコード１１
                        ,iv_token_value2 => iv_delivery_charge  -- 納品担当者
--                        ,iv_token_name3  => cv_tkn_param11      -- トークンコード１１
                        ,iv_token_name3  => cv_tkn_param12      -- トークンコード１２
                        ,iv_token_value3 => iv_carrier_means    -- 輸送手段
/* 2009/05/12 Ver1.8 Mod End   */
                      );
    -- 「作成区分」が、'解除'の場合
    ELSIF ( iv_make_class = cv_make_class_release ) THEN
      -- パラメータ出力メッセージ取得
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション
                        ,iv_name         => cv_msg_param3      -- パラメーター出力
                        ,iv_token_name1  => cv_tkn_param01     -- トークンコード１
                        ,iv_token_value1 => iv_make_class      -- 作成区分
                        ,iv_token_name2  => cv_tkn_param02     -- トークンコード２
                        ,iv_token_value2 => iv_edi_c_code      -- EDIチェーン店コード
                        ,iv_token_name3  => cv_tkn_param03     -- トークンコード３
                        ,iv_token_value3 => iv_proc_date       -- 処理日
                        ,iv_token_name4  => cv_tkn_param04     -- トークンコード４
                        ,iv_token_value4 => iv_proc_time       -- 処理時刻
                      );
    END IF;
    -- パラメータをメッセージに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_msg
    );
    -- パラメータをログに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
/* 2009/02/24 Ver1.2 Add Start */
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
/* 2009/02/24 Ver1.2 Add  End  */
    -- ファイル名メッセージ取得
    lv_param_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション
                      ,iv_name         => cv_msg_file_nmae   -- ファイル名出力
                      ,iv_token_name1  => cv_tkn_file_name   -- トークンコード１
                      ,iv_token_value1 => iv_file_name       -- ファイル名
                    );
    -- ファイル名をメッセージに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    ln_err_chk := cn_0;  -- エラーチェック用変数の初期化
--
    --==============================================================
    -- 必須チェック
    --==============================================================
    -- 「作成区分」が、NULLの場合
    IF ( iv_make_class IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- アプリケーション
                         ,iv_name         => cv_msg_tkn_param1  -- 作成区分
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション
                      ,iv_name         => cv_msg_param_null  -- 必須入力パラメータ未設定エラーメッセージ
                      ,iv_token_name1  => cv_tkn_in_param    -- 入力パラメータ名
                      ,iv_token_value1 => lv_tkn_value1      -- 作成区分
                     );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- 「EDIチェーン店コード」が、NULLの場合
    IF ( iv_edi_c_code IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- アプリケーション
                         ,iv_name         => cv_msg_tkn_param2  -- EDIチェーン店コード
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション
                      ,iv_name         => cv_msg_param_null  -- 必須入力パラメータ未設定エラーメッセージ
                      ,iv_token_name1  => cv_tkn_in_param    -- 入力パラメータ名
                      ,iv_token_value1 => lv_tkn_value1      -- EDIチェーン店コード
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    --==============================================================
    -- 作成区分内容チェック
    --==============================================================
    BEGIN
      SELECT flvv.meaning     meaning     -- 作成区分
      INTO   lt_make_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_edi_shipping_exp_t
      AND    flvv.lookup_code        = iv_make_class
      AND    flvv.enabled_flag       = cv_y                -- 有効
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- トークン取得
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- アプリケーション
                           ,iv_name         => cv_msg_tkn_param1  -- 作成区分
                         );
        -- メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application    -- アプリケーション
                        ,iv_name         => cv_msg_param_err  -- 入力パラメータ不正エラーメッセージ
                        ,iv_token_name1  => cv_tkn_in_param   -- 入力パラメータ名
                        ,iv_token_value1 => lv_tkn_value1     -- 作成区分
                      );
        -- メッセージに出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        lv_errbuf  := SQLERRM;
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- 「作成区分」が、'送信'か'ラベル作成'の場合のチェック
    --==============================================================
    IF ( iv_make_class = cv_make_class_transe )
    OR ( iv_make_class = cv_make_class_label )
    THEN
      -- 「ファイル名」「EDI伝送追番(ファイル名用)」「EDI伝送追番(抽出条件用)」「店舗納品日From」「店舗納品日To」のいずれかが、Nullの場合
      IF ( iv_file_name      IS NULL )
/* 2009/05/12 Ver1.8 Mod Start */
--      OR ( iv_edi_f_number   IS NULL )
      OR ( iv_edi_f_number_f IS NULL )
      OR ( iv_edi_f_number_s IS NULL )
/* 2009/05/12 Ver1.8 Mod End   */
      OR ( iv_shop_date_from IS NULL )
      OR ( iv_shop_date_to   IS NULL )
      THEN
        -- 「ファイル名」が、NULLの場合
        IF ( iv_file_name IS NULL ) THEN
          -- トークン取得
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- アプリケーション
                             ,iv_name         => cv_msg_tkn_param3  -- ファイル名
                           );
          -- メッセージ取得
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション
                          ,iv_name         => cv_msg_param_null  -- 必須入力パラメータ未設定エラーメッセージ
                          ,iv_token_name1  => cv_tkn_in_param    -- 入力パラメータ名
                          ,iv_token_value1 => lv_tkn_value1      -- ファイル名
                        );
          -- メッセージに出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        -- 「EDI伝送追番(ファイル名用)」が、NULLの場合
/* 2009/05/12 Ver1.8 Mod Start */
--        IF ( iv_edi_f_number IS NULL ) THEN
        IF ( iv_edi_f_number_f IS NULL ) THEN
/* 2009/05/12 Ver1.8 Mod End   */
          -- トークン取得
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- アプリケーション
                             ,iv_name         => cv_msg_tkn_param4  -- EDI伝送追番(ファイル名用)
                           );
          -- メッセージ取得
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション
                          ,iv_name         => cv_msg_param_null  -- 必須入力パラメータ未設定エラーメッセージ
                          ,iv_token_name1  => cv_tkn_in_param    -- 入力パラメータ名
                          ,iv_token_value1 => lv_tkn_value1      -- EDI伝送追番(ファイル名用)
                        );
          -- メッセージに出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
/* 2009/05/12 Ver1.8 Add Start */
        -- 「EDI伝送追番(抽出条件用)」が、NULLの場合
        IF ( iv_edi_f_number_s IS NULL ) THEN
          -- トークン取得
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- アプリケーション
                             ,iv_name         => cv_msg_tkn_param10 -- EDI伝送追番(抽出条件用)
                           );
          -- メッセージ取得
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション
                          ,iv_name         => cv_msg_param_null  -- 必須入力パラメータ未設定エラーメッセージ
                          ,iv_token_name1  => cv_tkn_in_param    -- 入力パラメータ名
                          ,iv_token_value1 => lv_tkn_value1      -- EDI伝送追番(抽出条件用)
                        );
          -- メッセージに出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
/* 2009/05/12 Ver1.8 Add End   */
--
        -- 「店舗納品日From」が、NULLの場合
        IF ( iv_shop_date_from IS NULL ) THEN
          -- トークン取得
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- アプリケーション
                             ,iv_name         => cv_msg_tkn_param5  -- 店舗納品日From
                           );
          -- メッセージ取得
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション
                          ,iv_name         => cv_msg_param_null  -- 必須入力パラメータ未設定エラーメッセージ
                          ,iv_token_name1  => cv_tkn_in_param    -- 入力パラメータ名
                          ,iv_token_value1 => lv_tkn_value1      -- 店舗納品日From
                        );
          -- メッセージに出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        -- 「店舗納品日To」が、NULLの場合
        IF ( iv_shop_date_to IS NULL ) THEN
          -- トークン取得
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- アプリケーション
                             ,iv_name         => cv_msg_tkn_param6  -- 店舗納品日To
                           );
          -- メッセージ取得
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション
                          ,iv_name         => cv_msg_param_null  -- 必須入力パラメータ未設定エラーメッセージ
                          ,iv_token_name1  => cv_tkn_in_param    -- 入力パラメータ名
                          ,iv_token_value1 => lv_tkn_value1      -- 店舗納品日To
                        );
          -- メッセージに出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        RAISE global_api_others_expt;
--
      END IF;
--
      -- 「店舗納品日From」が「店舗納品日To」より未来日付の場合
      IF ( iv_shop_date_from > iv_shop_date_to ) THEN
        -- トークン取得
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- アプリケーション
                           ,iv_name         => cv_msg_tkn_param5  -- 店舗納品日From
                         );
        -- トークン取得
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- アプリケーション
                           ,iv_name         => cv_msg_tkn_param6  -- 店舗納品日To
                         );
        -- メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       -- アプリケーション
                        ,iv_name         => cv_msg_date_reverse  -- 日付逆転エラーメッセージ
                        ,iv_token_name1  => cv_tkn_date_from     -- 日付期間チェックの開始日
                        ,iv_token_value1 => lv_tkn_value1        -- 店舗納品日From
                        ,iv_token_name2  => cv_tkn_date_to       -- 日付期間チェックの終了日
                        ,iv_token_value2 => lv_tkn_value2        -- 店舗納品日To
                      );
        -- メッセージに出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  -- エラー有り
      END IF;
--
      -- 「センター納品日」が入力されていて、
      -- 「センター納品日」が「店舗納品日To」より未来日付の場合
      IF  ( iv_center_date IS NOT NULL )
      AND ( iv_center_date > iv_shop_date_to )
      THEN
        -- トークン取得
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- アプリケーション
                           ,iv_name         => cv_msg_tkn_param9  -- センター納品日
                         );
        -- トークン取得
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- アプリケーション
                           ,iv_name         => cv_msg_tkn_param6  -- 店舗納品日To
                         );
        -- メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       -- アプリケーション
                        ,iv_name         => cv_msg_date_reverse  -- 日付逆転エラーメッセージ
                        ,iv_token_name1  => cv_tkn_date_from     -- 日付期間チェックの開始日
                        ,iv_token_value1 => lv_tkn_value1        -- センター納品日
                        ,iv_token_name2  => cv_tkn_date_to       -- 日付期間チェックの終了日
                        ,iv_token_value2 => lv_tkn_value2        -- 店舗納品日To
                      );
        -- メッセージに出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  -- エラー有り
      END IF;
    END IF;
--
    --==============================================================
    -- 「作成区分」が、'解除'の場合のチェック
    --==============================================================
    IF ( iv_make_class = cv_make_class_release ) THEN
      -- 「処理日」「処理時刻」のいずれかが、Nullの場合
      IF ( iv_proc_date IS NULL )
      OR ( iv_proc_time IS NULL )
      THEN
        -- 「処理日」が、NULLの場合
        IF ( iv_proc_date IS NULL ) THEN
          -- トークン取得
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- アプリケーション
                             ,iv_name         => cv_msg_tkn_param7  -- 処理日
                           );
          -- メッセージ取得
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション
                          ,iv_name         => cv_msg_param_null  -- 必須入力パラメータ未設定エラーメッセージ
                          ,iv_token_name1  => cv_tkn_in_param    -- 入力パラメータ名
                          ,iv_token_value1 => lv_tkn_value1      -- 処理日
                        );
          -- メッセージに出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        -- 「処理時刻」が、NULLの場合
        IF ( iv_proc_time IS NULL ) THEN
          -- トークン取得
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- アプリケーション
                             ,iv_name         => cv_msg_tkn_param8  -- 処理時刻
                           );
          -- メッセージ取得
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション
                          ,iv_name         => cv_msg_param_null  -- 必須入力パラメータ未設定エラーメッセージ
                          ,iv_token_name1  => cv_tkn_in_param    -- 入力パラメータ名
                          ,iv_token_value1 => lv_tkn_value1      -- 処理時刻
                        );
          -- メッセージに出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        RAISE global_api_others_expt;
--
      END IF;
    END IF;
--
    --==============================================================
    -- エラーの場合
    --==============================================================
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_api_others_expt;
    END IF;
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
  END check_param;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-2)
   ***********************************************************************************/
  PROCEDURE init(
    iv_make_class IN  VARCHAR2,     --   作成区分
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    lv_tkn_value1  VARCHAR2(50);    -- トークン取得用1
    lv_tkn_value2  VARCHAR2(50);    -- トークン取得用2
    ln_err_chk     NUMBER(1);       -- エラーチェック用
    lv_err_msg     VARCHAR2(5000);  -- エラー出力用
    lv_l_meaning   fnd_lookup_values_vl.meaning%TYPE;  -- クイックコード条件取得用
    lv_dummy       VARCHAR2(1);     -- レイアウト定義のCSVヘッダー用(ファイルタイプが固定長なので使用されない)
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
    lt_item_div_h  fnd_profile_option_values.profile_option_value%TYPE;  -- 本社製品区分
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
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
    -- 「作成区分」が、'解除'の場合
    IF ( iv_make_class = cv_make_class_release ) THEN
      RETURN;
    END IF;
--
    ln_err_chk     := cn_0;  -- エラーチェック用変数の初期化
    -- カウンタの初期化
    gn_dat_rec_cnt := cn_0;  -- 出力データ用
    gn_head_cnt    := cn_0;  -- EDIヘッダ情報用
    gn_line_cnt    := cn_0;  -- EDI明細情報用
--
    --==============================================================
    -- システム日付取得
    --==============================================================
    gv_f_o_date := TO_CHAR( cd_sysdate, cv_date_format );  -- 処理日
    gv_f_o_time := TO_CHAR( cd_sysdate, cv_time_format );  -- 処理時刻
--
    --==============================================================
    -- プロファイル情報取得
    --==============================================================
    -- ヘッダレコード区分
    gv_if_header := FND_PROFILE.VALUE( cv_prf_if_header );
    IF ( gv_if_header IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf1  -- XXCCP:IFレコード区分_ヘッダ
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- データレコード区分
    gv_if_data := FND_PROFILE.VALUE( cv_prf_if_data );
    IF ( gv_if_data IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf2  -- XXCCP:IFレコード区分_データ
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- フッタレコード区分
    gv_if_footer := FND_PROFILE.VALUE( cv_prf_if_footer );
    IF ( gv_if_footer IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf3  -- XXCCP:IFレコード区分_フッタ
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- UTL_MAX行サイズ
    gv_utl_m_line := FND_PROFILE.VALUE( cv_prf_utl_m_line );
    IF ( gv_utl_m_line IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf4  -- XXCOS:UTL_MAX行サイズ
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- アウトバウンド用ディレクトリパス
    gv_outbound_d := FND_PROFILE.VALUE( cv_prf_outbound_d );
    IF ( gv_outbound_d IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf5  -- XXCOS:EDI受注系アウトバウンド用ディレクトリパス
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- 会社名
    gv_company_name := FND_PROFILE.VALUE( cv_prf_company_name );
    IF ( gv_company_name IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf6  -- XXCOS:会社名
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- 会社名カナ
    gv_company_kana := FND_PROFILE.VALUE( cv_prf_company_kana );
    IF ( gv_company_kana IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf7  -- XXCOS:会社名カナ
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- ケース単位コード
    gv_case_uom_code := FND_PROFILE.VALUE( cv_prf_case_uom_code );
    IF ( gv_case_uom_code IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf8  -- XXCOS:ケース単位コード
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- ボール単位コード
    gv_ball_uom_code := FND_PROFILE.VALUE( cv_prf_ball_uom_code );
    IF ( gv_ball_uom_code IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf9  -- XXCOS:ボール単位コード
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- 在庫組織コード
    gv_organization := FND_PROFILE.VALUE( cv_prf_organization );
    IF ( gv_organization IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf10  -- XXCOI:在庫組織コード
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- MAX日付
    gd_max_date := TO_DATE( FND_PROFILE.VALUE( cv_prf_max_date ), cv_max_date_format );
    IF ( gd_max_date IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf11  -- XXCOS:MAX日付
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- 会計帳簿ID
    gn_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_bks_id ) );
    IF ( gn_bks_id IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf12  -- GL会計帳簿ID
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    -- 営業単位
    gn_org_id      := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf13  -- 営業単位
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
-- 2009/05/22 Ver1.9 Add Start
    gn_dum_stock_out := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_dum_stock_out ) );
    IF ( gn_dum_stock_out IS NULL ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- アプリケーション
                         ,iv_name         => cv_msg_tkn_prf14  -- EDI納品予定ダミー欠品区分
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
-- 2009/05/22 Ver1.9 Add End
    --==============================================================
    -- マスタ情報取得
    --==============================================================
    -- データ種情報
    BEGIN
      SELECT flvv.meaning     meaning     -- データ種
            ,flvv.attribute1  attribute1  -- IF元業務系列コード
      INTO   gt_data_type_code
            ,gt_from_series
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_data_type_code_t
/* 2009/05/12 Ver1.8 Mod Start */
/* 2009/02/27 Ver1.5 Mod Start */
      AND    flvv.lookup_code        = cv_data_type_code_c
--      AND (( iv_make_class           = cv_make_class_transe
--      AND    flvv.lookup_code        = cv_data_type_code_c )
--      OR   ( iv_make_class           = cv_make_class_label
--     AND    flvv.lookup_code        = cv_data_type_code_l ))
/* 2009/02/27 Ver1.5 Mod  End  */
/* 2009/05/12 Ver1.8 Mod  End  */
      AND    flvv.enabled_flag       = cv_y                -- 有効
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- アプリケーション
                           ,iv_name         => cv_msg_tkn_tbl1  -- クイックコード
                         );
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application      -- アプリケーション
                           ,iv_name         => cv_msg_tkn_column1  -- データ種コード
                         );
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application   -- アプリケーション
                        ,iv_name         => cv_msg_mast_err  -- マスタチェックエラーメッセージ
                        ,iv_token_name1  => cv_tkn_table     -- トークンコード１
                        ,iv_token_value1 => lv_tkn_value1    -- クイックコード
                        ,iv_token_name2  => cv_tkn_column    -- トークンコード２
                        ,iv_token_value2 => lv_tkn_value2    -- データ種コード
                      );
        -- メッセージに出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        lv_errbuf  := SQLERRM;
        ln_err_chk := cn_1;  -- エラー有り
    END;
--
    -- EDI媒体区分
    BEGIN
      -- メッセージより内容を取得
      lv_l_meaning := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション
                        ,iv_name         => cv_msg_l_meaning2  -- クイックコード取得条件(EDI媒体区分)
                      );
      -- クイックコード取得
      SELECT flvv.lookup_code      lookup_code
      INTO   gt_edi_media_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_edi_media_class_t
      AND    flvv.meaning            = lv_l_meaning
      AND    flvv.enabled_flag       = cv_y                -- 有効
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- アプリケーション
                           ,iv_name         => cv_msg_tkn_tbl1  -- クイックコード
                         );
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application      -- アプリケーション
                           ,iv_name         => cv_msg_tkn_column2  -- EDI媒体区分
                         );
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application   -- アプリケーション
                        ,iv_name         => cv_msg_mast_err  -- マスタチェックエラーメッセージ
                        ,iv_token_name1  => cv_tkn_table     -- トークンコード１
                        ,iv_token_value1 => lv_tkn_value1    -- クイックコード
                        ,iv_token_name2  => cv_tkn_column    -- トークンコード２
                        ,iv_token_value2 => lv_tkn_value2    -- EDI媒体区分
                      );
        -- メッセージに出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        lv_errbuf  := SQLERRM;
        ln_err_chk := cn_1;  -- エラー有り
    END;
--
    --==============================================================
    -- ファイルレイアウト情報取得
    --==============================================================
    -- レイアウト定義情報
    xxcos_common2_pkg.get_layout_info(
       iv_file_type        =>  cv_0                -- ファイル形式(固定長)
      ,iv_layout_class     =>  cv_0                -- 情報区分(受注系)
      ,ov_data_type_table  =>  gt_data_type_table  -- データ型表
      ,ov_csv_header       =>  lv_dummy            -- CSVヘッダ
      ,ov_errbuf           =>  lv_errbuf           -- エラーメッセージ
      ,ov_retcode          =>  lv_retcode          -- リターンコード
      ,ov_errmsg           =>  lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- アプリケーション
                         ,iv_name         => cv_msg_tkn_layout  -- 受注系項目レイアウト
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application       -- アプリケーション
                      ,iv_name         => cv_msg_file_inf_err  -- IFファイルレイアウト定義情報取得エラーメッセージ
                      ,iv_token_name1  => cv_tkn_layout        -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1        -- 受注系項目レイアウト
                   );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
    --==============================================================
    -- 在庫組織ID取得
    --==============================================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                             iv_organization_code => gv_organization  -- 在庫組織コード
                          );
    IF ( gn_organization_id IS NULL ) THEN
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application   -- アプリケーション
                      ,iv_name         => cv_msg_org_err   -- 在庫組織ID取得エラーメッセージ
                      ,iv_token_name1  => cv_tkn_org_code  -- トークンコード１
                      ,iv_token_value1 => gv_organization  -- 在庫組織コード
                   );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- エラー有り
    END IF;
--
-- ********** 2009/09/03 1.12 N.Maeda ADD START ********** --
    -- =============================================================
    -- プロファイル「XXCOS:本社商品区分」取得
    -- =============================================================
    lt_item_div_h := FND_PROFILE.VALUE(ct_item_div_h);
--
    IF ( lt_item_div_h IS NULL ) THEN
--
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- アプリケーション
                         ,iv_name         => cv_msg_item_div_h  -- 本社製品区分
                       );
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- アプリケーション
                      ,iv_name         => cv_msg_prf_err  -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile  -- トークンコード１
                      ,iv_token_value1 => lv_tkn_value1   -- プロファイル名
                    );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      lv_errbuf  := lv_err_msg;
      ln_err_chk := cn_1;  -- エラー有り
--
    ELSE
      -- =============================================================
      -- カテゴリセットID取得
      -- =============================================================
      BEGIN
        SELECT  mcst.category_set_id
        INTO    gt_category_set_id
        FROM    mtl_category_sets_tl   mcst
        WHERE   mcst.category_set_name = lt_item_div_h
        AND     mcst.language          = ct_user_lang;
      EXCEPTION
        WHEN OTHERS THEN
          lv_err_msg  :=  xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application,
                           iv_name         =>  cv_msg_category_err
                           );
          -- メッセージに出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
          lv_errbuf  := lv_err_msg;
          ln_err_chk := cn_1;  -- エラー有り
      END;
--
    END IF;
-- ********** 2009/09/03 1.12 N.Maeda ADD  END  ********** --
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
    BEGIN
      SELECT oos.order_source_id     order_source_id    -- 受注ソースID
      INTO   gt_order_source_online
      FROM   oe_order_sources        oos                -- 受注ソーステーブル
      WHERE  oos.name                = cv_online
      AND    oos.enabled_flag        = cv_y;
    EXCEPTION
      WHEN OTHERS THEN
          lv_err_msg  :=  xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application,
                           iv_name         =>  cv_get_order_source_id_err,
                           iv_token_name1  =>  cv_order_source,
                           iv_token_value1 =>  cv_online
                           );
          -- メッセージに出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
          lv_errbuf  := lv_err_msg;
          ln_err_chk := cn_1;  -- エラー有り
      END;
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
--
    --==============================================================
    -- エラーの場合
    --==============================================================
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_data_check_expt;
    END IF;
--
  EXCEPTION
    -- *** データチェックエラー ***
    WHEN global_data_check_expt THEN
      -- 値がNULL、もしくは対象外
      IF ( lv_errbuf IS NULL ) THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      -- その他例外
      ELSE
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
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
   * Procedure Name   : get_manual_order
   * Description      : 手入力データ登録(A-3)
   ***********************************************************************************/
  PROCEDURE get_manual_order(
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDIチェーン店コード
    iv_edi_f_number     IN  VARCHAR2,     --   5.EDI伝送追番(抽出条件用)
    iv_shop_date_from   IN  VARCHAR2,     --   6.店舗納品日From
    iv_shop_date_to     IN  VARCHAR2,     --   7.店舗納品日To
    iv_sale_class       IN  VARCHAR2,     --   8.定番特売区分
    iv_area_code        IN  VARCHAR2,     --   9.地区コード
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_manual_order'; -- プログラム名
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
    lv_tkn_value1  VARCHAR2(50);    -- トークン取得用1
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
    --==============================================================
    -- 手入力データ登録
    --==============================================================
    xxcos_edi_common_pkg.edi_manual_order_acquisition(
       iv_edi_chain_code          => iv_edi_c_code                               -- EDIチェーン店コード
      ,iv_edi_forward_number      => iv_edi_f_number                             -- EDI伝送追番
      ,id_shop_delivery_date_from => TO_DATE(iv_shop_date_from, cv_date_format)  -- 店舗納品日(From)
      ,id_shop_delivery_date_to   => TO_DATE(iv_shop_date_to, cv_date_format)    -- 店舗納品日(To)
      ,iv_regular_ar_sale_class   => iv_sale_class                               -- 定番特売区分
      ,iv_area_code               => iv_area_code                                -- 地区コード
      ,id_center_delivery_date    => NULL                                        -- センター納品日
      ,in_organization_id         => gn_organization_id                          -- 在庫組織ID
      ,ov_errbuf                  => lv_errbuf                                   -- エラー・メッセージ
      ,ov_retcode                 => lv_retcode                                  -- リターン・コード
      ,ov_errmsg                  => lv_errmsg                                   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ取得
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- アプリケーション
                     ,iv_name         => cv_msg_com_fnuc_err  -- EDI共通関数エラーメッセージ
                     ,iv_token_name1  => cv_tkn_err_msg       -- トークンコード１
                     ,iv_token_value1 => lv_errmsg            -- エラー・メッセージ
                   );
      RAISE global_api_others_expt;
    END IF;
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
  END get_manual_order;
--
--
  /**********************************************************************************
   * Procedure Name   : output_header
   * Description      : ファイル初期処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_header(
    iv_file_name        IN  VARCHAR2,     --   1.ファイル名
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDIチェーン店コード
    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI伝送追番(ファイル名用)
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_header'; -- プログラム名
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
/* 2009/04/28 Ver1.7 Mod Start */
--    lv_header_output  VARCHAR2(1000);  -- ヘッダー出力用
    lv_header_output  VARCHAR2(5000);  -- ヘッダー出力用
/* 2009/04/28 Ver1.7 Mod End   */
    ln_dummy          NUMBER;          -- ヘッダ出力のレコード件数用(使用されない)
--
    -- *** ローカル・カーソル ***
    -- 拠点情報
    CURSOR cust_base_cur
    IS
      SELECT  hca.account_number             delivery_base_code      -- 納品拠点コード
             ,hp.party_name                  delivery_base_name      -- 納品拠点名
             ,hp.organization_name_phonetic  delivery_base_phonetic  -- 納品拠点名カナ
      FROM    hz_cust_accounts        hca   -- 拠点(顧客)
             ,hz_parties              hp    -- 拠点(パーティ)
             ,hz_party_sites          hps   -- パーティサイト
             ,hz_cust_acct_sites_all  hcas  -- 顧客所在地
      WHERE   hcas.party_site_id  = hps.party_site_id     -- 結合(顧客所在地 = パーティサイト)
      AND     hca.cust_account_id = hcas.cust_account_id  -- 結合(拠点(顧客) = 顧客所在地)
      AND     hca.party_id        = hp.party_id           -- 結合(拠点(顧客) = 拠点(パーティ))
      AND     hcas.org_id         = gn_org_id             -- 営業単位
      AND     hca.account_number  =
/* 2010/02/26 Ver1.15 Mod Start */
--                ( SELECT  xca1.delivery_base_code
--                  FROM    hz_cust_accounts     hca1  -- 顧客
--                         ,hz_parties           hp1   -- パーティ
--                         ,xxcmm_cust_accounts  xca1  -- 顧客追加情報
--                  WHERE   hp1.duns_number_c       IN (cv_cust_status_30   -- 顧客ステータス(承認済)
--                                                     ,cv_cust_status_40)  -- 顧客ステータス(顧客)
--                  AND     hca1.party_id            =  hp1.party_id        -- 結合(顧客 = パーティ)
--                  AND     hca1.status              =  cv_status_a         -- ステータス(顧客有効)
--                  AND     hca1.customer_class_code =  cv_cust_code_cust   -- 顧客区分(顧客)
--                  AND     hca1.cust_account_id     =  xca1.customer_id    -- 結合(顧客 = 顧客追加)
--                  AND     xca1.chain_store_code    =  iv_edi_c_code       -- EDIチェーン店コード
--                  AND     ROWNUM                   =  cn_1
--                )
                ( SELECT xuif.base_code  AS base_code     -- ログインユーザーの拠点コード(新)
                  FROM   xxcos_user_info_v xuif           -- ユーザ情報ビュー
                  WHERE  xuif.user_id = cn_created_by     -- ログインユーザー
                )
/* 2010/02/26 Ver1.15 Mod  End  */
      ;
    -- EDIチェーン店情報
    CURSOR edi_chain_cur
    IS
      SELECT  hp.party_name                  edi_chain_name      -- EDIチェーン店名
             ,hp.organization_name_phonetic  edi_chain_phonetic  -- EDIチェーン店名カナ
      FROM    hz_parties           hp    -- パーティ
             ,hz_cust_accounts     hca   -- 顧客
             ,xxcmm_cust_accounts  xca   -- 顧客追加情報
      WHERE   hca.party_id            = hp.party_id         -- 結合(顧客 = パーティ)
      AND     hca.customer_class_code = cv_cust_code_chain  -- 顧客区分(チェーン店)
      AND     hca.cust_account_id     = xca.customer_id     -- 結合(顧客 = 顧客追加)
      AND     hca.status              = cv_status_a         -- ステータス(顧客有効)
      AND     xca.chain_store_code    = iv_edi_c_code       -- EDIチェーン店コード
      ;
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
    --==============================================================
    -- ファイルオープン
    --==============================================================
    BEGIN
      gt_f_handle := UTL_FILE.FOPEN(
                        location      =>  gv_outbound_d  -- アウトバウンド用ディレクトリパス
                       ,filename      =>  iv_file_name   -- ファイル名
                       ,open_mode     =>  cv_w           -- オープンモード
                       ,max_linesize  =>  gv_utl_m_line  -- MAXサイズ
                     );
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     -- アプリケーション
                       ,iv_name         => cv_msg_file_o_err  -- EDI共通関数エラーメッセージ
                       ,iv_token_name1  => cv_tkn_file_name   -- トークンコード１
                       ,iv_token_value1 => iv_file_name       -- ファイル名
                     );
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- ヘッダレコード出力
    --==============================================================
    -- 拠点情報取得
    OPEN  cust_base_cur;
    FETCH cust_base_cur
      INTO  gt_header_data.delivery_base_code        -- 納品拠点コード
           ,gt_header_data.delivery_base_name        -- 納品拠点名
           ,gt_header_data.delivery_base_phonetic    -- 納品拠点名カナ
    ;
    -- データが取得できない場合エラー
    IF ( cust_base_cur%NOTFOUND )THEN
      CLOSE cust_base_cur;
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- アプリケーション
                     ,iv_name         => cv_msg_base_inf_err  -- 拠点情報取得エラーメッセージ
                     ,iv_token_name1  => cv_tkn_code          -- トークンコード１
                     ,iv_token_value1 => iv_edi_c_code        -- EDIチェーン店コード
                   );
      RAISE global_api_others_expt;
    END IF;
    CLOSE cust_base_cur;
--
    -- EDIチェーン店情報取得
    OPEN  edi_chain_cur;
    FETCH edi_chain_cur
      INTO  gt_header_data.edi_chain_name           -- EDIチェーン店名
           ,gt_header_data.edi_chain_name_phonetic  -- EDIチェーン店カナ
    ;
    -- データが取得できない場合エラー
    IF ( edi_chain_cur%NOTFOUND )THEN
      CLOSE edi_chain_cur;
      -- メッセージ
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- アプリケーション
                     ,iv_name         => cv_msg_chain_inf_err -- チェーン店情報取得エラーメッセージ
                     ,iv_token_name1  => cv_tkn_chain_code    -- トークンコード１
                     ,iv_token_value1 => iv_edi_c_code        -- EDIチェーン店コード
                   );
      RAISE global_api_others_expt;
    END IF;
    CLOSE edi_chain_cur;
--
    --==============================================================
    -- EDIヘッダ付与
    --==============================================================
    xxccp_ifcommon_pkg.add_edi_header_footer(
       iv_add_area        =>  gv_if_header    -- 付与区分
      ,iv_from_series     =>  gt_from_series  -- IF元業務系列コード
      ,iv_base_code       =>  gt_header_data.delivery_base_code
/* 2009/02/24 Ver1.2 Mod Start */
--    ,iv_base_name       =>  gt_header_data.delivery_base_name
      ,iv_base_name       =>  SUBSTRB(gt_header_data.delivery_base_name, 1, 40)
      ,iv_chain_code      =>  iv_edi_c_code
--    ,iv_chain_name      =>  gt_header_data.edi_chain_name
      ,iv_chain_name      =>  SUBSTRB(gt_header_data.edi_chain_name, 1, 40)
/* 2009/02/24 Ver1.2 Mod  End  */
      ,iv_data_kind       =>  gt_data_type_code
      ,iv_row_number      =>  iv_edi_f_number
      ,in_num_of_records  =>  ln_dummy
      ,ov_retcode         =>  lv_retcode
      ,ov_output          =>  lv_header_output
      ,ov_errbuf          =>  lv_errbuf
      ,ov_errmsg          =>  lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ取得
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- アプリケーション
                     ,iv_name         => cv_msg_com_fnuc_err  -- EDI共通関数エラーメッセージ
                     ,iv_token_name1  => cv_tkn_err_msg       -- トークンコード１
                     ,iv_token_value1 => lv_errmsg            -- エラー・メッセージ
                   );
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- ファイル出力
    --==============================================================
    UTL_FILE.PUT_LINE(
       file   => gt_f_handle       -- ファイルハンドル
      ,buffer => lv_header_output  -- 出力文字(ヘッダ)
    );
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
  END output_header;
--
  /**********************************************************************************
   * Procedure Name   : input_edi_order
   * Description      : EDI受注データ抽出(A-5)
   ***********************************************************************************/
  PROCEDURE input_edi_order(
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDIチェーン店コード
    iv_edi_f_number     IN  VARCHAR2,     --   5.EDI伝送追番(抽出条件用)
    iv_shop_date_from   IN  VARCHAR2,     --   6.店舗納品日From
    iv_shop_date_to     IN  VARCHAR2,     --   7.店舗納品日To
    iv_sale_class       IN  VARCHAR2,     --   8.定番特売区分
    iv_area_code        IN  VARCHAR2,     --   9.地区コード
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_edi_order'; -- プログラム名
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
    lv_tkn_value1  VARCHAR2(50);    -- トークン取得用1
    lv_tkn_value2  VARCHAR2(50);    -- トークン取得用2
    lv_err_msg     VARCHAR2(5000);  -- エラー出力用
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
    --==============================================================
    -- 入力パラメータを条件へ設定
    --==============================================================
    gt_edi_c_code     := iv_edi_c_code;                               -- EDIチェーン店コード
    gt_edi_f_number   := iv_edi_f_number;                             -- EDI伝送追番
    gt_shop_date_from := TO_DATE(iv_shop_date_from, cv_date_format);  -- 店舗納品日From
    gt_shop_date_to   := TO_DATE(iv_shop_date_to, cv_date_format);    -- 店舗納品日To
    gt_sale_class     := iv_sale_class;                               -- 定番特売区分
    gt_area_code      := iv_area_code;                                -- 地区コード
--
    --==============================================================
    -- EDI受注データ抽出
    --==============================================================
    BEGIN
      OPEN  edi_order_cur;
      FETCH edi_order_cur BULK COLLECT INTO gt_edi_order_tab;
      CLOSE edi_order_cur;
    EXCEPTION
      -- *** ロックエラー ***
      WHEN lock_expt THEN
        -- カーソルクローズ
        IF ( edi_order_cur%ISOPEN ) THEN
          CLOSE edi_order_cur;
        END IF;
        -- トークン取得
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- アプリケーション
                           ,iv_name         => cv_msg_tkn_tbl2  -- EDIヘッダ情報テーブル
                         );
        -- メッセージ取得
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     -- アプリケーション
                       ,iv_name         => cv_msg_lock_err    -- ロックエラーメッセージ
                       ,iv_token_name1  => cv_tkn_table       -- トークンコード１
                       ,iv_token_value1 => lv_tkn_value1      -- EDIヘッダ情報テーブル
                     );
        RAISE global_api_others_expt;
--
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        -- カーソルクローズ
        IF ( edi_order_cur%ISOPEN ) THEN
          CLOSE edi_order_cur;
        END IF;
        -- トークン取得
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- アプリケーション
                           ,iv_name         => cv_msg_tkn_tbl2  -- EDIヘッダ情報テーブル
                         );
        -- メッセージ取得
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- アプリケーション
                       ,iv_name         => cv_msg_data_get_err  -- データ抽出エラーメッセージ
                       ,iv_token_name1  => cv_tkn_table_name    -- トークンコード１
                       ,iv_token_value1 => lv_tkn_value1        -- EDIヘッダ情報テーブル
                       ,iv_token_name2  => cv_tkn_key_data      -- トークンコード２
                       ,iv_token_value2 => iv_edi_c_code        -- EDIチェーン店コード
                     );
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- 処理対象レコード件数取得
    --==============================================================
    gn_target_cnt := gt_edi_order_tab.COUNT;
    IF ( gn_target_cnt = cn_0 ) THEN
      -- メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application    -- アプリケーション
                      ,iv_name         => cv_msg_no_target  -- 対象データなしメッセージ
                   );
      -- メッセージに出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    END IF;
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
  END input_edi_order;
--
  /**********************************************************************************
   * Procedure Name   : format_data
   * Description      : データ成形(A-7)
   ***********************************************************************************/
  PROCEDURE format_data(
    iv_make_class       IN  VARCHAR2,               --   2.作成区分
    ir_total_rec        IN  g_invoice_total_rtype,  -- 伝票計
    it_head_id          IN  xxcos_edi_headers.edi_header_info_id%TYPE,          -- EDIヘッダ情報ID
    it_delivery_flag    IN  xxcos_edi_headers.edi_delivery_schedule_flag%TYPE,  -- EDI納品予定送信済フラグ
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'format_data'; -- プログラム名
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
    --==============================================================
    -- EDIヘッダ情報編集
    --==============================================================
    gn_head_cnt := gn_head_cnt + cn_1;
    gt_edi_header_tab(gn_head_cnt).edi_header_info_id          := it_head_id;                                     -- EDIヘッダ情報ID
    gt_edi_header_tab(gn_head_cnt).process_date                := TO_DATE(gv_f_o_date, cv_date_format);           -- 処理日
    gt_edi_header_tab(gn_head_cnt).process_time                := gv_f_o_time;                                    -- 処理時刻
    gt_edi_header_tab(gn_head_cnt).base_code                   := gt_data_tab(cn_1)(cv_base_code);                -- 拠点(部門)コード
/* 2009/02/24 Ver1.2 Mod Start */
--  gt_edi_header_tab(gn_head_cnt).base_name                   := gt_data_tab(cn_1)(cv_base_name);                -- 拠点名(正式名)
--  gt_edi_header_tab(gn_head_cnt).base_name_alt               := gt_data_tab(cn_1)(cv_base_name_alt);            -- 拠点名(カナ)
    gt_edi_header_tab(gn_head_cnt).base_name                   := SUBSTRB(gt_data_tab(cn_1)(cv_base_name), 1, 40);      -- 拠点名(正式名)
    gt_edi_header_tab(gn_head_cnt).base_name_alt               := SUBSTRB(gt_data_tab(cn_1)(cv_base_name_alt), 1, 25);  -- 拠点名(カナ)
    gt_edi_header_tab(gn_head_cnt).customer_code               := gt_data_tab(cn_1)(cv_cust_code);                -- 顧客コード
--  gt_edi_header_tab(gn_head_cnt).customer_name               := gt_data_tab(cn_1)(cv_cust_name);                -- 顧客名(漢字)
--  gt_edi_header_tab(gn_head_cnt).customer_name_alt           := gt_data_tab(cn_1)(cv_cust_name_alt);            -- 顧客名(カナ)
    gt_edi_header_tab(gn_head_cnt).customer_name               := SUBSTRB(gt_data_tab(cn_1)(cv_cust_name), 1, 100);     -- 顧客名(漢字)
    gt_edi_header_tab(gn_head_cnt).customer_name_alt           := SUBSTRB(gt_data_tab(cn_1)(cv_cust_name_alt), 1, 50);  -- 顧客名(カナ)
    gt_edi_header_tab(gn_head_cnt).shop_code                   := gt_data_tab(cn_1)(cv_shop_code);                -- 店コード
--  gt_edi_header_tab(gn_head_cnt).shop_name                   := gt_data_tab(cn_1)(cv_shop_name);                -- 店名(漢字)
--  gt_edi_header_tab(gn_head_cnt).shop_name_alt               := gt_data_tab(cn_1)(cv_shop_name_alt);            -- 店名(カナ)
    gt_edi_header_tab(gn_head_cnt).shop_name                   := SUBSTRB(gt_data_tab(cn_1)(cv_shop_name), 1, 40);      -- 店名(漢字)
    gt_edi_header_tab(gn_head_cnt).shop_name_alt               := SUBSTRB(gt_data_tab(cn_1)(cv_shop_name_alt), 1, 20);  -- 店名(カナ)
    gt_edi_header_tab(gn_head_cnt).center_delivery_date        := TO_DATE(gt_data_tab(cn_1)(cv_cent_delv_date), cv_date_format);  -- センター納品日
    gt_edi_header_tab(gn_head_cnt).order_no_ebs                := gt_data_tab(cn_1)(cv_order_no_ebs);             -- 受注No(EBS)
    gt_edi_header_tab(gn_head_cnt).contact_to                  := gt_data_tab(cn_1)(cv_contact_to);               -- 連絡先
    gt_edi_header_tab(gn_head_cnt).area_code                   := gt_data_tab(cn_1)(cv_area_code);                -- 地区コード
--  gt_edi_header_tab(gn_head_cnt).area_name                   := gt_data_tab(cn_1)(cv_area_name);                -- 地区名(漢字)
--  gt_edi_header_tab(gn_head_cnt).area_name_alt               := gt_data_tab(cn_1)(cv_area_name_alt);            -- 地区名(カナ)
    gt_edi_header_tab(gn_head_cnt).area_name                   := SUBSTRB(gt_data_tab(cn_1)(cv_area_name), 1, 40);      -- 地区名(漢字)
    gt_edi_header_tab(gn_head_cnt).area_name_alt               := SUBSTRB(gt_data_tab(cn_1)(cv_area_name_alt), 1, 20);  -- 地区名(カナ)
    gt_edi_header_tab(gn_head_cnt).vendor_code                 := gt_data_tab(cn_1)(cv_vendor_code);              -- 取引先コード
--  gt_edi_header_tab(gn_head_cnt).vendor_name                 := gt_data_tab(cn_1)(cv_vendor_name);              -- 取引先名(漢字)
--  gt_edi_header_tab(gn_head_cnt).vendor_name1_alt            := gt_data_tab(cn_1)(cv_vendor_name1_alt);         -- 取引先名1(カナ)
--  gt_edi_header_tab(gn_head_cnt).vendor_name2_alt            := gt_data_tab(cn_1)(cv_vendor_name2_alt);         -- 取引先名2(カナ)
    gt_edi_header_tab(gn_head_cnt).vendor_name                 := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_name), 1, 40);       -- 取引先名(漢字)
    gt_edi_header_tab(gn_head_cnt).vendor_name1_alt            := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_name1_alt), 1, 20);  -- 取引先名1(カナ)
    gt_edi_header_tab(gn_head_cnt).vendor_name2_alt            := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_name2_alt), 1, 20);  -- 取引先名2(カナ)
--  gt_edi_header_tab(gn_head_cnt).vendor_tel                  := gt_data_tab(cn_1)(cv_vendor_tel);               -- 取引先TEL
--  gt_edi_header_tab(gn_head_cnt).vendor_charge               := gt_data_tab(cn_1)(cv_vendor_charge);            -- 取引先担当者
--  gt_edi_header_tab(gn_head_cnt).vendor_address              := gt_data_tab(cn_1)(cv_vendor_address);           -- 取引先住所(漢字)
    gt_edi_header_tab(gn_head_cnt).vendor_tel                  := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_tel), 1, 12);      -- 取引先TEL
    gt_edi_header_tab(gn_head_cnt).vendor_charge               := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_charge), 1, 12);   -- 取引先担当者
    gt_edi_header_tab(gn_head_cnt).vendor_address              := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_address), 1, 40);  -- 取引先住所(漢字)
/* 2009/02/24 Ver1.2 Mod  End  */
    gt_edi_header_tab(gn_head_cnt).delivery_schedule_time      := gt_data_tab(cn_1)(cv_delv_schedule_time);       -- 納品予定時間
    gt_edi_header_tab(gn_head_cnt).carrier_means               := gt_data_tab(cn_1)(cv_carrier_means);            -- 運送手段
    gt_edi_header_tab(gn_head_cnt).eos_handwriting_class       := gt_data_tab(cn_1)(cv_eos_handwriting_class);    -- EOS･手書区分
    gt_edi_header_tab(gn_head_cnt).invoice_indv_order_qty      := ir_total_rec.indv_order_qty;                    -- (伝票計)発注数量(バラ)
    gt_edi_header_tab(gn_head_cnt).invoice_case_order_qty      := ir_total_rec.case_order_qty;                    -- (伝票計)発注数量(ケース)
    gt_edi_header_tab(gn_head_cnt).invoice_ball_order_qty      := ir_total_rec.ball_order_qty;                    -- (伝票計)発注数量(ボール)
    gt_edi_header_tab(gn_head_cnt).invoice_sum_order_qty       := ir_total_rec.sum_order_qty;                     -- (伝票計)発注数量(合計、バラ)
    gt_edi_header_tab(gn_head_cnt).invoice_indv_shipping_qty   := ir_total_rec.indv_shipping_qty;                 -- (伝票計)出荷数量(バラ)
    gt_edi_header_tab(gn_head_cnt).invoice_case_shipping_qty   := ir_total_rec.case_shipping_qty;                 -- (伝票計)出荷数量(ケース)
    gt_edi_header_tab(gn_head_cnt).invoice_ball_shipping_qty   := ir_total_rec.ball_shipping_qty;                 -- (伝票計)出荷数量(ボール)
    gt_edi_header_tab(gn_head_cnt).invoice_pallet_shipping_qty := ir_total_rec.pallet_shipping_qty;               -- (伝票計)出荷数量(パレット)
    gt_edi_header_tab(gn_head_cnt).invoice_sum_shipping_qty    := ir_total_rec.sum_shipping_qty;                  -- (伝票計)出荷数量(合計、バラ)
    gt_edi_header_tab(gn_head_cnt).invoice_indv_stockout_qty   := ir_total_rec.indv_stockout_qty;                 -- (伝票計)欠品数量(バラ)
    gt_edi_header_tab(gn_head_cnt).invoice_case_stockout_qty   := ir_total_rec.case_stockout_qty;                 -- (伝票計)欠品数量(ケース)
    gt_edi_header_tab(gn_head_cnt).invoice_ball_stockout_qty   := ir_total_rec.ball_stockout_qty;                 -- (伝票計)欠品数量(ボール)
    gt_edi_header_tab(gn_head_cnt).invoice_sum_stockout_qty    := ir_total_rec.sum_stockout_qty;                  -- (伝票計)欠品数量(合計、バラ)
    gt_edi_header_tab(gn_head_cnt).invoice_case_qty            := ir_total_rec.case_qty;                          -- (伝票計)ケース個口数
    gt_edi_header_tab(gn_head_cnt).invoice_fold_container_qty  := gt_data_tab(cn_1)(cv_invc_fold_container_qty);  -- (伝票計)オリコン(バラ)個口数
    gt_edi_header_tab(gn_head_cnt).invoice_order_cost_amt      := ir_total_rec.order_cost_amt;                    -- (伝票計)原価金額(発注)
    gt_edi_header_tab(gn_head_cnt).invoice_shipping_cost_amt   := ir_total_rec.shipping_cost_amt;                 -- (伝票計)原価金額(出荷)
    gt_edi_header_tab(gn_head_cnt).invoice_stockout_cost_amt   := ir_total_rec.stockout_cost_amt;                 -- (伝票計)原価金額(欠品)
    gt_edi_header_tab(gn_head_cnt).invoice_order_price_amt     := ir_total_rec.order_price_amt;                   -- (伝票計)売価金額(発注)
    gt_edi_header_tab(gn_head_cnt).invoice_shipping_price_amt  := ir_total_rec.shipping_price_amt;                -- (伝票計)売価金額(出荷)
    gt_edi_header_tab(gn_head_cnt).invoice_stockout_price_amt  := ir_total_rec.stockout_price_amt;                -- (伝票計)売価金額(欠品)
    -- 「作成区分」が、'送信'の場合
    IF ( iv_make_class = cv_make_class_transe ) THEN
      gt_edi_header_tab(gn_head_cnt).edi_delivery_schedule_flag  := cv_y;                                         -- EDI納品予定送信済フラグ
    ELSE
      gt_edi_header_tab(gn_head_cnt).edi_delivery_schedule_flag  := it_delivery_flag;                             -- EDI納品予定送信済フラグ
    END IF;
--
    <<format_loop>>
    FOR ln_loop_cnt IN 1 .. gt_data_tab.COUNT LOOP
      --==============================================================
      -- 伝票計編集
      --==============================================================
      gt_data_tab(ln_loop_cnt)(cv_invc_indv_order_qty)   := ir_total_rec.indv_order_qty;       -- (伝票計)発注数量(バラ)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_order_qty)   := ir_total_rec.case_order_qty;       -- (伝票計)発注数量(ケース)
      gt_data_tab(ln_loop_cnt)(cv_invc_ball_order_qty)   := ir_total_rec.ball_order_qty;       -- (伝票計)発注数量(ボール)
      gt_data_tab(ln_loop_cnt)(cv_invc_sum_order_qty)    := ir_total_rec.sum_order_qty;        -- (伝票計)発注数量(合計、バラ)
      gt_data_tab(ln_loop_cnt)(cv_invc_indv_ship_qty)    := ir_total_rec.indv_shipping_qty;    -- (伝票計)出荷数量(バラ)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_ship_qty)    := ir_total_rec.case_shipping_qty;    -- (伝票計)出荷数量(ケース)
      gt_data_tab(ln_loop_cnt)(cv_invc_ball_ship_qty)    := ir_total_rec.ball_shipping_qty;    -- (伝票計)出荷数量(ボール)
      gt_data_tab(ln_loop_cnt)(cv_invc_pallet_ship_qty)  := ir_total_rec.pallet_shipping_qty;  -- (伝票計)出荷数量(パレット)
      gt_data_tab(ln_loop_cnt)(cv_invc_sum_ship_qty)     := ir_total_rec.sum_shipping_qty;     -- (伝票計)出荷数量(合計、バラ)
      gt_data_tab(ln_loop_cnt)(cv_invc_indv_stkout_qty)  := ir_total_rec.indv_stockout_qty;    -- (伝票計)欠品数量(バラ)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_stkout_qty)  := ir_total_rec.case_stockout_qty;    -- (伝票計)欠品数量(ケース)
      gt_data_tab(ln_loop_cnt)(cv_invc_ball_stkout_qty)  := ir_total_rec.ball_stockout_qty;    -- (伝票計)欠品数量(ボール)
      gt_data_tab(ln_loop_cnt)(cv_invc_sum_stkout_qty)   := ir_total_rec.sum_stockout_qty;     -- (伝票計)欠品数量(合計、バラ)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_qty)         := ir_total_rec.case_qty;             -- (伝票計)ケース個口数
      gt_data_tab(ln_loop_cnt)(cv_invc_order_cost_amt)   := ir_total_rec.order_cost_amt;       -- (伝票計)原価金額(発注)
      gt_data_tab(ln_loop_cnt)(cv_invc_ship_cost_amt)    := ir_total_rec.shipping_cost_amt;    -- (伝票計)原価金額(出荷)
      gt_data_tab(ln_loop_cnt)(cv_invc_stkout_cost_amt)  := ir_total_rec.stockout_cost_amt;    -- (伝票計)原価金額(欠品)
      gt_data_tab(ln_loop_cnt)(cv_invc_order_price_amt)  := ir_total_rec.order_price_amt;      -- (伝票計)売価金額(発注)
      gt_data_tab(ln_loop_cnt)(cv_invc_ship_price_amt)   := ir_total_rec.shipping_price_amt;   -- (伝票計)売価金額(出荷)
      gt_data_tab(ln_loop_cnt)(cv_invc_stkout_price_amt) := ir_total_rec.stockout_price_amt;   -- (伝票計)売価金額(欠品)
--
      --==============================================================
      -- データ成形
      --==============================================================
      gn_dat_rec_cnt := gn_dat_rec_cnt + cn_1;
      BEGIN
        xxcos_common2_pkg.makeup_data_record(
           iv_edit_data        =>  gt_data_tab(ln_loop_cnt)            -- 出力データ情報
          ,iv_file_type        =>  cv_0                                -- ファイル形式(固定長)
          ,iv_data_type_table  =>  gt_data_type_table                  -- レイアウト定義情報
          ,iv_record_type      =>  gv_if_data                          -- データレコード識別子
          ,ov_data_record      =>  gt_data_record_tab(gn_dat_rec_cnt)  -- データレコード
          ,ov_errbuf           =>  lv_errbuf                           -- エラーメッセージ
          ,ov_retcode          =>  lv_retcode                          -- リターンコード
          ,ov_errmsg           =>  lv_errmsg                           -- ユーザ・エラーメッセージ
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- メッセージ取得
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- アプリケーション
                         ,iv_name         => cv_msg_com_fnuc_err  -- EDI共通関数エラーメッセージ
                         ,iv_token_name1  => cv_tkn_err_msg       -- トークンコード１
                         ,iv_token_value1 => lv_errmsg            -- エラー・メッセージ
                       );
          RAISE global_api_others_expt;
      END;
--
    END LOOP format_loop;
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
  END format_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_data
   * Description      : データ編集(A-6)
   ***********************************************************************************/
  PROCEDURE edit_data(
    iv_make_class       IN  VARCHAR2,     --   2.作成区分
    iv_center_date      IN  VARCHAR2,     --   9.センター納品日
    iv_delivery_time    IN  VARCHAR2,     --  10.納品時刻
    iv_delivery_charge  IN  VARCHAR2,     --  11.納品担当者
    iv_carrier_means    IN  VARCHAR2,     --  12.輸送手段
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_data'; -- プログラム名
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
    lv_tkn_value1      VARCHAR2(50);    -- トークン取得用1
    lv_tkn_value2      VARCHAR2(50);    -- トークン取得用2
    lv_err_msg         VARCHAR2(5000);  -- エラー出力用
    ln_err_chk         NUMBER(1);       -- エラーチェック用
    ln_data_cnt        NUMBER;          -- データ件数
    lv_product_code    VARCHAR2(16);    -- 商品コード
    lv_jan_code        VARCHAR2(16);    -- JANコード
    lv_case_jan_code   VARCHAR2(16);    -- ケースJANコード
    ln_dummy_item      NUMBER;          -- DUMMY品目
    lt_invoice_number  xxcos_edi_headers.invoice_number%TYPE;              -- 伝票番号
    lt_header_id       xxcos_edi_headers.edi_header_info_id%TYPE;          -- EDIヘッダ情報ID
    lt_delivery_flag   xxcos_edi_headers.edi_delivery_schedule_flag%TYPE;  -- EDI納品予定送信済フラグ
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
    ln_invoice_number  NUMBER;          -- 数値チェック用
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
--
    -- *** ローカル・カーソル ***
    CURSOR dummy_item_cur
    IS
      SELECT flvv.lookup_code      dummy_item_code  -- ダミー品目コード
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_edi_item_err_t
      AND    flvv.enabled_flag       = cv_y                -- 有効
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
      ;
--
    -- *** ローカル・レコード ***
    l_invoice_total_rec  g_invoice_total_rtype;
--
    -- *** ローカル・テーブル ***
    TYPE lt_dummy_item_ttype  IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE  INDEX BY BINARY_INTEGER;  -- DUMMY品目
    lt_dummy_item_tab  lt_dummy_item_ttype;
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
    --==============================================================
    -- 初期化
    --==============================================================
    ln_err_chk        := cn_0;
    ln_data_cnt       := cn_0;
    lt_invoice_number := gt_edi_order_tab(cn_1).invoice_number;
    lt_header_id      := gt_edi_order_tab(cn_1).edi_header_info_id;
    lt_delivery_flag  := gt_edi_order_tab(cn_1).edi_delivery_schedule_flag;
    -- 伝票別合計
    l_invoice_total_rec.indv_order_qty      := cn_0;  -- 発注数量(バラ)
    l_invoice_total_rec.case_order_qty      := cn_0;  -- 発注数量(ケース)
    l_invoice_total_rec.ball_order_qty      := cn_0;  -- 発注数量(ボール)
    l_invoice_total_rec.sum_order_qty       := cn_0;  -- 発注数量(合計、バラ)
    l_invoice_total_rec.indv_shipping_qty   := cn_0;  -- 出荷数量(バラ)
    l_invoice_total_rec.case_shipping_qty   := cn_0;  -- 出荷数量(ケース)
    l_invoice_total_rec.ball_shipping_qty   := cn_0;  -- 出荷数量(ボール)
    l_invoice_total_rec.pallet_shipping_qty := cn_0;  -- 出荷数量(パレット)
    l_invoice_total_rec.sum_shipping_qty    := cn_0;  -- 出荷数量(合計、バラ)
    l_invoice_total_rec.indv_stockout_qty   := cn_0;  -- 欠品数量(バラ)
    l_invoice_total_rec.case_stockout_qty   := cn_0;  -- 欠品数量(ケース)
    l_invoice_total_rec.ball_stockout_qty   := cn_0;  -- 欠品数量(ボール)
    l_invoice_total_rec.sum_stockout_qty    := cn_0;  -- 欠品数量(合計、バラ)
    l_invoice_total_rec.case_qty            := cn_0;  -- ケース個口数
    l_invoice_total_rec.order_cost_amt      := cn_0;  -- 原価金額(発注)
    l_invoice_total_rec.shipping_cost_amt   := cn_0;  -- 原価金額(出荷)
    l_invoice_total_rec.stockout_cost_amt   := cn_0;  -- 原価金額(欠品)
    l_invoice_total_rec.order_price_amt     := cn_0;  -- 売価金額(発注)
    l_invoice_total_rec.shipping_price_amt  := cn_0;  -- 売価金額(出荷)
    l_invoice_total_rec.stockout_price_amt  := cn_0;  -- 売価金額(欠品)
--
    -- DUMMY品目取得
    OPEN  dummy_item_cur;
    FETCH dummy_item_cur BULK COLLECT INTO lt_dummy_item_tab;
    CLOSE dummy_item_cur;
--
    <<edit_loop>>
    FOR ln_loop_cnt IN 1 .. gn_target_cnt LOOP
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
      lt_invoice_number := gt_edi_order_tab(ln_loop_cnt).invoice_number;
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
      --数値チェック
      BEGIN
        IF INSTR( lt_invoice_number , '.' ) > 0 THEN
          RAISE global_number_err_expt;
        END IF;
        ln_invoice_number := TO_NUMBER( SUBSTRB( lt_invoice_number, 1,1) );
        ln_invoice_number := TO_NUMBER( lt_invoice_number );
      EXCEPTION
        WHEN global_number_err_expt THEN
--****************************** 2009/07/08 1.10 M.Sano     ADD START ******************************--
          gn_error_cnt := gn_error_cnt + 1;
          gn_warn_cnt  := gn_target_cnt - gn_error_cnt;
--****************************** 2009/07/08 1.10 M.Sano     ADD  END  ******************************--
          ov_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application                                -- アプリケーション
                          ,iv_name         => cv_msg_slip_no_err                            -- 伝票番号数値エラー
                          ,iv_token_name1  => cv_tkn_param01                                -- 入力パラメータ名
                          ,iv_token_value1 => lt_invoice_number                             -- 伝票番号
                          ,iv_token_name2  => cv_tkn_param02                                -- 入力パラメータ名
                          ,iv_token_value2 => gt_edi_order_tab(ln_loop_cnt).order_number    -- 受注番号
                        );
          RAISE global_api_others_expt;
      END;
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
-- ********* 2009/09/25 1.13 N.Maeda MOD START ********* --
      -- 「EDIヘッダ情報ID」がブレイクした場合
      IF ( lt_header_id <> gt_edi_order_tab(ln_loop_cnt).edi_header_info_id ) THEN
--      -- 「伝票番号」がブレイクした場合
--      IF ( lt_invoice_number <> gt_edi_order_tab(ln_loop_cnt).invoice_number ) THEN
-- ********* 2009/09/25 1.13 N.Maeda MOD  END  ********* --
        --==============================================================
        -- データ成形(A-7)
        --==============================================================
        format_data(
           iv_make_class        -- 2.作成区分
          ,l_invoice_total_rec  -- 伝票計
          ,lt_header_id         -- EDIヘッダ情報ID
          ,lt_delivery_flag     -- EDI納品予定送信済フラグ
          ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
          ,lv_retcode           -- リターン・コード             --# 固定 #
          ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- クリア
        --==============================================================
        gt_data_tab.DELETE;
        ln_data_cnt       := cn_0;
        lt_invoice_number := gt_edi_order_tab(ln_loop_cnt).invoice_number;
        lt_header_id      := gt_edi_order_tab(ln_loop_cnt).edi_header_info_id;
        lt_delivery_flag  := gt_edi_order_tab(ln_loop_cnt).edi_delivery_schedule_flag;
        -- 伝票別合計
        l_invoice_total_rec.indv_order_qty      := cn_0;  -- 発注数量(バラ)
        l_invoice_total_rec.case_order_qty      := cn_0;  -- 発注数量(ケース)
        l_invoice_total_rec.ball_order_qty      := cn_0;  -- 発注数量(ボール)
        l_invoice_total_rec.sum_order_qty       := cn_0;  -- 発注数量(合計、バラ)
        l_invoice_total_rec.indv_shipping_qty   := cn_0;  -- 出荷数量(バラ)
        l_invoice_total_rec.case_shipping_qty   := cn_0;  -- 出荷数量(ケース)
        l_invoice_total_rec.ball_shipping_qty   := cn_0;  -- 出荷数量(ボール)
        l_invoice_total_rec.pallet_shipping_qty := cn_0;  -- 出荷数量(パレット)
        l_invoice_total_rec.sum_shipping_qty    := cn_0;  -- 出荷数量(合計、バラ)
        l_invoice_total_rec.indv_stockout_qty   := cn_0;  -- 欠品数量(バラ)
        l_invoice_total_rec.case_stockout_qty   := cn_0;  -- 欠品数量(ケース)
        l_invoice_total_rec.ball_stockout_qty   := cn_0;  -- 欠品数量(ボール)
        l_invoice_total_rec.sum_stockout_qty    := cn_0;  -- 欠品数量(合計、バラ)
        l_invoice_total_rec.case_qty            := cn_0;  -- ケース個口数
        l_invoice_total_rec.order_cost_amt      := cn_0;  -- 原価金額(発注)
        l_invoice_total_rec.shipping_cost_amt   := cn_0;  -- 原価金額(出荷)
        l_invoice_total_rec.stockout_cost_amt   := cn_0;  -- 原価金額(欠品)
        l_invoice_total_rec.order_price_amt     := cn_0;  -- 売価金額(発注)
        l_invoice_total_rec.shipping_price_amt  := cn_0;  -- 売価金額(出荷)
        l_invoice_total_rec.stockout_price_amt  := cn_0;  -- 売価金額(欠品)
      END IF;
--
      ln_data_cnt := ln_data_cnt + cn_1;
      --==============================================================
      -- 納品予定データ編集
      --==============================================================
      -- ヘッダ
      gt_data_tab(ln_data_cnt)(cv_medium_class)             := gt_edi_order_tab(ln_loop_cnt).medium_class;                      -- 媒体区分
      gt_data_tab(ln_data_cnt)(cv_data_type_code)           := gt_data_type_code;                                               -- ﾃﾞｰﾀ種ｺｰﾄﾞ
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
--      gt_data_tab(ln_data_cnt)(cv_file_no)                  := gt_edi_order_tab(ln_loop_cnt).file_no;                           -- ﾌｧｲﾙNo
      gt_data_tab(ln_data_cnt)(cv_file_no)                  := gt_edi_order_tab(ln_loop_cnt).edi_forward_number;                -- ﾌｧｲﾙNo
--****************************** 2009/06/12 1.10 T.Kitajima MOD  END  ******************************--
      gt_data_tab(ln_data_cnt)(cv_info_class)               := gt_edi_order_tab(ln_loop_cnt).info_class;                        -- 情報区分
      gt_data_tab(ln_data_cnt)(cv_process_date)             := gv_f_o_date;                                                     -- 処理日
      gt_data_tab(ln_data_cnt)(cv_process_time)             := gv_f_o_time;                                                     -- 処理日
      gt_data_tab(ln_data_cnt)(cv_base_code)                := gt_edi_order_tab(ln_loop_cnt).delivery_base_code;                -- 拠点(部門)ｺｰﾄﾞ
/* 2009/02/24 Ver1.2 Mod Start */
--    gt_data_tab(ln_data_cnt)(cv_base_name)                := gt_edi_order_tab(ln_loop_cnt).base_name;                         -- 拠点名(正式名)
--    gt_data_tab(ln_data_cnt)(cv_base_name_alt)            := gt_edi_order_tab(ln_loop_cnt).base_name_phonetic;                -- 拠点名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_base_name)                := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).base_name, 1, 100);           -- 拠点名(正式名)
      gt_data_tab(ln_data_cnt)(cv_base_name_alt)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).base_name_phonetic, 1, 100);  -- 拠点名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_edi_chain_code)           := gt_edi_order_tab(ln_loop_cnt).edi_chain_code;                    -- EDIﾁｪｰﾝ店ｺｰﾄﾞ
--    gt_data_tab(ln_data_cnt)(cv_edi_chain_name)           := gt_edi_order_tab(ln_loop_cnt).edi_chain_name;                    -- EDIﾁｪｰﾝ店名(漢字)
--    gt_data_tab(ln_data_cnt)(cv_edi_chain_name_alt)       := NVL(gt_edi_order_tab(ln_loop_cnt).edi_chain_name_alt,
--                                                                 gt_edi_order_tab(ln_loop_cnt).edi_chain_name_phonetic);      -- EDIﾁｪｰﾝ店名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_edi_chain_name)           := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).edi_chain_name, 1, 100);   -- EDIﾁｪｰﾝ店名(漢字)
      gt_data_tab(ln_data_cnt)(cv_edi_chain_name_alt)       := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).edi_chain_name_alt,
                                                               gt_edi_order_tab(ln_loop_cnt).edi_chain_name_phonetic), 1, 100); -- EDIﾁｪｰﾝ店名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_chain_code)               := NULL;                                                            -- ﾁｪｰﾝ店ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_chain_name)               := NULL;                                                            -- ﾁｪｰﾝ店名(漢字)
      gt_data_tab(ln_data_cnt)(cv_chain_name_alt)           := NULL;                                                            -- ﾁｪｰﾝ店名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_report_code)              := NULL;                                                            -- 帳票ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_report_show_name)         := NULL;                                                            -- 帳票表示名
      gt_data_tab(ln_data_cnt)(cv_cust_code)                := gt_edi_order_tab(ln_loop_cnt).account_number;                    -- 顧客ｺｰﾄﾞ
--    gt_data_tab(ln_data_cnt)(cv_cust_name)                := gt_edi_order_tab(ln_loop_cnt).customer_name;                     -- 顧客名(漢字)
--    gt_data_tab(ln_data_cnt)(cv_cust_name_alt)            := gt_edi_order_tab(ln_loop_cnt).customer_name_phonetic;            -- 顧客名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_cust_name)                := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).customer_name, 1, 100);           -- 顧客名(漢字)
      gt_data_tab(ln_data_cnt)(cv_cust_name_alt)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).customer_name_phonetic, 1, 100);  -- 顧客名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_comp_code)                := gt_edi_order_tab(ln_loop_cnt).company_code;                      -- 社ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_comp_name)                := gt_edi_order_tab(ln_loop_cnt).company_name;                      -- 社名(漢字)
      gt_data_tab(ln_data_cnt)(cv_comp_name_alt)            := gt_edi_order_tab(ln_loop_cnt).company_name_alt;                  -- 社名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_shop_code)                := gt_edi_order_tab(ln_loop_cnt).shop_code;                         -- 店ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_shop_name)                := gt_edi_order_tab(ln_loop_cnt).cust_store_name;                   -- 店名(漢字)
--    gt_data_tab(ln_data_cnt)(cv_shop_name_alt)            := NVL(gt_edi_order_tab(ln_loop_cnt).shop_name_alt,
--                                                                 gt_edi_order_tab(ln_loop_cnt).shop_name_phonetic);           -- 店名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_shop_name_alt)            := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).shop_name_alt,
                                                               gt_edi_order_tab(ln_loop_cnt).shop_name_phonetic), 1, 100);      -- 店名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_delv_cent_code)           := gt_edi_order_tab(ln_loop_cnt).delivery_center_code;              -- 納入ｾﾝﾀｰｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_delv_cent_name)           := gt_edi_order_tab(ln_loop_cnt).delivery_center_name;              -- 納入ｾﾝﾀｰ名(漢字)
      gt_data_tab(ln_data_cnt)(cv_delv_cent_name_alt)       := gt_edi_order_tab(ln_loop_cnt).delivery_center_name_alt;          -- 納入先ｾﾝﾀｰ名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_order_date)               := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).order_date, cv_date_format);                   -- 発注日
      gt_data_tab(ln_data_cnt)(cv_cent_delv_date)           := NVL(iv_center_date,
                                                               TO_CHAR(gt_edi_order_tab(ln_loop_cnt).center_delivery_date, cv_date_format));        -- ｾﾝﾀｰ納品日
      gt_data_tab(ln_data_cnt)(cv_result_delv_date)         := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).result_delivery_date, cv_date_format);         -- 実納品日
      gt_data_tab(ln_data_cnt)(cv_shop_delv_date)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).shop_delivery_date, cv_date_format);           -- 店舗納品日
      gt_data_tab(ln_data_cnt)(cv_dc_date_edi_data)         := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).data_creation_date_edi_data, cv_date_format);  -- ﾃﾞｰﾀ作成日(EDIﾃﾞｰﾀ中)
      gt_data_tab(ln_data_cnt)(cv_dc_time_edi_data)         := gt_edi_order_tab(ln_loop_cnt).data_creation_time_edi_data;       -- ﾃﾞｰﾀ作成時刻(EDIﾃﾞｰﾀ中)
      gt_data_tab(ln_data_cnt)(cv_invc_class)               := gt_edi_order_tab(ln_loop_cnt).invoice_class;                     -- 伝票区分
      gt_data_tab(ln_data_cnt)(cv_small_classif_code)       := gt_edi_order_tab(ln_loop_cnt).small_classification_code;         -- 小分類ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_small_classif_name)       := gt_edi_order_tab(ln_loop_cnt).small_classification_name;         -- 小分類名
      gt_data_tab(ln_data_cnt)(cv_middle_classif_code)      := gt_edi_order_tab(ln_loop_cnt).middle_classification_code;        -- 中分類ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_middle_classif_name)      := gt_edi_order_tab(ln_loop_cnt).middle_classification_name;        -- 中分類名
      gt_data_tab(ln_data_cnt)(cv_big_classif_code)         := gt_edi_order_tab(ln_loop_cnt).big_classification_code;           -- 大分類ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_big_classif_name)         := gt_edi_order_tab(ln_loop_cnt).big_classification_name;           -- 大分類名
      gt_data_tab(ln_data_cnt)(cv_op_department_code)       := gt_edi_order_tab(ln_loop_cnt).other_party_department_code;       -- 相手先部門ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_op_order_number)          := gt_edi_order_tab(ln_loop_cnt).other_party_order_number;          -- 相手先発注番号
      gt_data_tab(ln_data_cnt)(cv_check_digit_class)        := gt_edi_order_tab(ln_loop_cnt).check_digit_class;                 -- ﾁｪｯｸﾃﾞｼﾞｯﾄ有無区分
      gt_data_tab(ln_data_cnt)(cv_invc_number)              := gt_edi_order_tab(ln_loop_cnt).invoice_number;                    -- 伝票番号
      gt_data_tab(ln_data_cnt)(cv_check_digit)              := gt_edi_order_tab(ln_loop_cnt).check_digit;                       -- ﾁｪｯｸﾃﾞｼﾞｯﾄ
      gt_data_tab(ln_data_cnt)(cv_close_date)               := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).close_date, cv_date_format);  -- 月限
      gt_data_tab(ln_data_cnt)(cv_order_no_ebs)             := gt_edi_order_tab(ln_loop_cnt).order_number;                      -- 受注No(EBS)
      gt_data_tab(ln_data_cnt)(cv_ar_sale_class)            := gt_edi_order_tab(ln_loop_cnt).ar_sale_class;                     -- 特売区分
      gt_data_tab(ln_data_cnt)(cv_delv_classe)              := gt_edi_order_tab(ln_loop_cnt).delivery_classe;                   -- 配送区分
      gt_data_tab(ln_data_cnt)(cv_opportunity_no)           := gt_edi_order_tab(ln_loop_cnt).opportunity_no;                    -- 便No
      gt_data_tab(ln_data_cnt)(cv_contact_to)               := NVL(gt_edi_order_tab(ln_loop_cnt).contact_to,
                                                                   gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic);       -- 連絡先
      gt_data_tab(ln_data_cnt)(cv_route_sales)              := gt_edi_order_tab(ln_loop_cnt).route_sales;                       -- ﾙｰﾄｾｰﾙｽ
      gt_data_tab(ln_data_cnt)(cv_corporate_code)           := gt_edi_order_tab(ln_loop_cnt).corporate_code;                    -- 法人ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_maker_name)               := gt_edi_order_tab(ln_loop_cnt).maker_name;                        -- ﾒｰｶｰ名
      gt_data_tab(ln_data_cnt)(cv_area_code)                := NVL(gt_edi_order_tab(ln_loop_cnt).area_code,
                                                                   gt_edi_order_tab(ln_loop_cnt).edi_district_code);            -- 地区ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_area_name)                := gt_edi_order_tab(ln_loop_cnt).edi_district_name;                 -- 地区名(漢字)
      gt_data_tab(ln_data_cnt)(cv_area_name_alt)            := NVL(gt_edi_order_tab(ln_loop_cnt).area_name_alt,
                                                                   gt_edi_order_tab(ln_loop_cnt).edi_district_kana);            -- 地区名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_vendor_code)              := NVL(gt_edi_order_tab(ln_loop_cnt).vendor_code,
                                                                   gt_edi_order_tab(ln_loop_cnt).torihikisaki_code);            -- 取引先ｺｰﾄﾞ
--    gt_data_tab(ln_data_cnt)(cv_vendor_name)              := gv_company_name || gt_edi_order_tab(ln_loop_cnt).base_name;      -- 取引先名(漢字)
--    gt_data_tab(ln_data_cnt)(cv_vendor_name1_alt)         := NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name1_alt,
--                                                                 gv_company_kana);                                            -- 取引先名1(ｶﾅ)
--    gt_data_tab(ln_data_cnt)(cv_vendor_name2_alt)         := NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name2_alt,
--                                                                 gt_edi_order_tab(ln_loop_cnt).base_name_phonetic);           -- 取引先名2(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_vendor_name)              := SUBSTRB(gv_company_name || gt_edi_order_tab(ln_loop_cnt).base_name, 1, 100);  -- 取引先名(漢字)
      gt_data_tab(ln_data_cnt)(cv_vendor_name1_alt)         := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name1_alt,
                                                                   gv_company_kana), 1, 100);                                   -- 取引先名1(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_vendor_name2_alt)         := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name2_alt,
                                                                   gt_edi_order_tab(ln_loop_cnt).base_name_phonetic), 1, 100);  -- 取引先名2(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_vendor_tel)               := gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic;            -- 取引先TEL
      gt_data_tab(ln_data_cnt)(cv_vendor_charge)            := NVL(iv_delivery_charge,
                                                                   gt_edi_order_tab(ln_loop_cnt).last_name ||
                                                                   gt_edi_order_tab(ln_loop_cnt).first_name);                   -- 取引先担当者
--    gt_data_tab(ln_data_cnt)(cv_vendor_address)           := gt_edi_order_tab(ln_loop_cnt).state    ||
--                                                             gt_edi_order_tab(ln_loop_cnt).city     ||
--                                                             gt_edi_order_tab(ln_loop_cnt).address1 ||
--                                                             gt_edi_order_tab(ln_loop_cnt).address2;                          -- 取引先住所(漢字)
      gt_data_tab(ln_data_cnt)(cv_vendor_address)           := SUBSTRB(
                                                               gt_edi_order_tab(ln_loop_cnt).state    ||
                                                               gt_edi_order_tab(ln_loop_cnt).city     ||
                                                               gt_edi_order_tab(ln_loop_cnt).address1 ||
                                                               gt_edi_order_tab(ln_loop_cnt).address2, 1, 100);                 -- 取引先住所(漢字)
/* 2009/02/24 Ver1.2 Mod  End  */
      gt_data_tab(ln_data_cnt)(cv_delv_to_code_itouen)      := gt_edi_order_tab(ln_loop_cnt).deliver_to_code_itouen;            -- 届け先ｺｰﾄﾞ(伊藤園)
      gt_data_tab(ln_data_cnt)(cv_delv_to_code_chain)       := gt_edi_order_tab(ln_loop_cnt).deliver_to_code_chain;             -- 届け先ｺｰﾄﾞ(ﾁｪｰﾝ店)
      gt_data_tab(ln_data_cnt)(cv_delv_to)                  := gt_edi_order_tab(ln_loop_cnt).deliver_to;                        -- 届け先(漢字)
      gt_data_tab(ln_data_cnt)(cv_delv_to1_alt)             := gt_edi_order_tab(ln_loop_cnt).deliver_to1_alt;                   -- 届け先1(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_delv_to2_alt)             := gt_edi_order_tab(ln_loop_cnt).deliver_to2_alt;                   -- 届け先2(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_delv_to_address)          := gt_edi_order_tab(ln_loop_cnt).deliver_to_address;                -- 届け先住所(漢字)
      gt_data_tab(ln_data_cnt)(cv_delv_to_address_alt)      := gt_edi_order_tab(ln_loop_cnt).deliver_to_address_alt;            -- 届け先住所(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_delv_to_tel)              := gt_edi_order_tab(ln_loop_cnt).deliver_to_tel;                    -- 届け先TEL
      gt_data_tab(ln_data_cnt)(cv_bal_acc_code)             := gt_edi_order_tab(ln_loop_cnt).balance_accounts_code;             -- 帳合先ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_bal_acc_comp_code)        := gt_edi_order_tab(ln_loop_cnt).balance_accounts_company_code;     -- 帳合先社ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_bal_acc_shop_code)        := gt_edi_order_tab(ln_loop_cnt).balance_accounts_shop_code;        -- 帳合先店ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_bal_acc_name)             := gt_edi_order_tab(ln_loop_cnt).balance_accounts_name;             -- 帳合先名(漢字)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_name_alt)         := gt_edi_order_tab(ln_loop_cnt).balance_accounts_name_alt;         -- 帳合先名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_address)          := gt_edi_order_tab(ln_loop_cnt).balance_accounts_address;          -- 帳合先住所(漢字)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_address_alt)      := gt_edi_order_tab(ln_loop_cnt).balance_accounts_address_alt;      -- 帳合先住所(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_tel)              := gt_edi_order_tab(ln_loop_cnt).balance_accounts_tel;              -- 帳合先TEL
      gt_data_tab(ln_data_cnt)(cv_order_possible_date)      := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).order_possible_date, cv_date_format);         -- 受注可能日
      gt_data_tab(ln_data_cnt)(cv_perm_possible_date)       := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).permission_possible_date, cv_date_format);    -- 許容可能日
      gt_data_tab(ln_data_cnt)(cv_forward_month)            := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).forward_month, cv_date_format);               -- 先限年月日
      gt_data_tab(ln_data_cnt)(cv_payment_settlement_date)  := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).payment_settlement_date, cv_date_format);     -- 支払決済日
      gt_data_tab(ln_data_cnt)(cv_handbill_start_date_act)  := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).handbill_start_date_active, cv_date_format);  -- ﾁﾗｼ開始日
      gt_data_tab(ln_data_cnt)(cv_billing_due_date)         := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).billing_due_date, cv_date_format);            -- 請求締日
      gt_data_tab(ln_data_cnt)(cv_ship_time)                := gt_edi_order_tab(ln_loop_cnt).shipping_time;                     -- 出荷時刻
      gt_data_tab(ln_data_cnt)(cv_delv_schedule_time)       := iv_delivery_time;                                                -- 納品予定時間
      gt_data_tab(ln_data_cnt)(cv_order_time)               := gt_edi_order_tab(ln_loop_cnt).order_time;                        -- 発注時間
      gt_data_tab(ln_data_cnt)(cv_gen_date_item1)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item1, cv_date_format);  -- 汎用日付項目1
      gt_data_tab(ln_data_cnt)(cv_gen_date_item2)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item2, cv_date_format);  -- 汎用日付項目2
      gt_data_tab(ln_data_cnt)(cv_gen_date_item3)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item3, cv_date_format);  -- 汎用日付項目3
      gt_data_tab(ln_data_cnt)(cv_gen_date_item4)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item4, cv_date_format);  -- 汎用日付項目4
      gt_data_tab(ln_data_cnt)(cv_gen_date_item5)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item5, cv_date_format);  -- 汎用日付項目5
      gt_data_tab(ln_data_cnt)(cv_arrival_ship_class)       := gt_edi_order_tab(ln_loop_cnt).arrival_shipping_class;            -- 入出荷区分
      gt_data_tab(ln_data_cnt)(cv_vendor_class)             := gt_edi_order_tab(ln_loop_cnt).vendor_class;                      -- 取引先区分
      gt_data_tab(ln_data_cnt)(cv_invc_detailed_class)      := gt_edi_order_tab(ln_loop_cnt).invoice_detailed_class;            -- 伝票内訳区分
      gt_data_tab(ln_data_cnt)(cv_unit_price_use_class)     := gt_edi_order_tab(ln_loop_cnt).unit_price_use_class;              -- 単価使用区分
      gt_data_tab(ln_data_cnt)(cv_sub_distb_cent_code)      := gt_edi_order_tab(ln_loop_cnt).sub_distribution_center_code;      -- ｻﾌﾞ物流ｾﾝﾀｰｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_sub_distb_cent_name)      := gt_edi_order_tab(ln_loop_cnt).sub_distribution_center_name;      -- ｻﾌﾞ物流ｾﾝﾀｰｺｰﾄﾞ名
      gt_data_tab(ln_data_cnt)(cv_cent_delv_method)         := gt_edi_order_tab(ln_loop_cnt).center_delivery_method;            -- ｾﾝﾀｰ納品方法
      gt_data_tab(ln_data_cnt)(cv_cent_use_class)           := gt_edi_order_tab(ln_loop_cnt).center_use_class;                  -- ｾﾝﾀｰ利用区分
      gt_data_tab(ln_data_cnt)(cv_cent_whse_class)          := gt_edi_order_tab(ln_loop_cnt).center_whse_class;                 -- ｾﾝﾀｰ倉庫区分
      gt_data_tab(ln_data_cnt)(cv_cent_area_class)          := gt_edi_order_tab(ln_loop_cnt).center_area_class;                 -- ｾﾝﾀｰ地域区分
      gt_data_tab(ln_data_cnt)(cv_cent_arrival_class)       := gt_edi_order_tab(ln_loop_cnt).center_arrival_class;              -- ｾﾝﾀｰ入荷区分
      gt_data_tab(ln_data_cnt)(cv_depot_class)              := gt_edi_order_tab(ln_loop_cnt).depot_class;                       -- ﾃﾞﾎﾟ区分
      gt_data_tab(ln_data_cnt)(cv_tcdc_class)               := gt_edi_order_tab(ln_loop_cnt).tcdc_class;                        -- TCDC区分
      gt_data_tab(ln_data_cnt)(cv_upc_flag)                 := gt_edi_order_tab(ln_loop_cnt).upc_flag;                          -- UPCﾌﾗｸﾞ
      gt_data_tab(ln_data_cnt)(cv_simultaneously_class)     := gt_edi_order_tab(ln_loop_cnt).simultaneously_class;              -- 一斉区分
      gt_data_tab(ln_data_cnt)(cv_business_id)              := gt_edi_order_tab(ln_loop_cnt).business_id;                       -- 業務ID
      gt_data_tab(ln_data_cnt)(cv_whse_directly_class)      := gt_edi_order_tab(ln_loop_cnt).whse_directly_class;               -- 倉直区分
      gt_data_tab(ln_data_cnt)(cv_premium_rebate_class)     := gt_edi_order_tab(ln_loop_cnt).premium_rebate_class;              -- 項目種別
      gt_data_tab(ln_data_cnt)(cv_item_type)                := gt_edi_order_tab(ln_loop_cnt).item_type;                         -- 景品割戻区分
      gt_data_tab(ln_data_cnt)(cv_cloth_house_food_class)   := gt_edi_order_tab(ln_loop_cnt).cloth_house_food_class;            -- 衣家食区分
      gt_data_tab(ln_data_cnt)(cv_mix_class)                := gt_edi_order_tab(ln_loop_cnt).mix_class;                         -- 混在区分
      gt_data_tab(ln_data_cnt)(cv_stk_class)                := gt_edi_order_tab(ln_loop_cnt).stk_class;                         -- 在庫区分
      gt_data_tab(ln_data_cnt)(cv_last_modify_site_class)   := gt_edi_order_tab(ln_loop_cnt).last_modify_site_class;            -- 最終修正場所区分
      gt_data_tab(ln_data_cnt)(cv_report_class)             := gt_edi_order_tab(ln_loop_cnt).report_class;                      -- 帳票区分
      gt_data_tab(ln_data_cnt)(cv_addition_plan_class)      := gt_edi_order_tab(ln_loop_cnt).addition_plan_class;               -- 追加･計画区分
      gt_data_tab(ln_data_cnt)(cv_registration_class)       := gt_edi_order_tab(ln_loop_cnt).registration_class;                -- 登録区分
      gt_data_tab(ln_data_cnt)(cv_specific_class)           := gt_edi_order_tab(ln_loop_cnt).specific_class;                    -- 特定区分
      gt_data_tab(ln_data_cnt)(cv_dealings_class)           := gt_edi_order_tab(ln_loop_cnt).dealings_class;                    -- 取引区分
      gt_data_tab(ln_data_cnt)(cv_order_class)              := gt_edi_order_tab(ln_loop_cnt).order_class;                       -- 発注区分
      gt_data_tab(ln_data_cnt)(cv_sum_line_class)           := gt_edi_order_tab(ln_loop_cnt).sum_line_class;                    -- 集計明細区分
      gt_data_tab(ln_data_cnt)(cv_ship_guidance_class)      := gt_edi_order_tab(ln_loop_cnt).shipping_guidance_class;           -- 出荷案内以外区分
      gt_data_tab(ln_data_cnt)(cv_ship_class)               := gt_edi_order_tab(ln_loop_cnt).shipping_class;                    -- 出荷区分
      gt_data_tab(ln_data_cnt)(cv_prod_code_use_class)      := gt_edi_order_tab(ln_loop_cnt).product_code_use_class;            -- 商品ｺｰﾄﾞ使用区分
      gt_data_tab(ln_data_cnt)(cv_cargo_item_class)         := gt_edi_order_tab(ln_loop_cnt).cargo_item_class;                  -- 積送品区分
      gt_data_tab(ln_data_cnt)(cv_ta_class)                 := gt_edi_order_tab(ln_loop_cnt).ta_class;                          -- T/A区分
      gt_data_tab(ln_data_cnt)(cv_plan_code)                := gt_edi_order_tab(ln_loop_cnt).plan_code;                         -- 企画ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_category_code)            := gt_edi_order_tab(ln_loop_cnt).category_code;                     -- ｶﾃｺﾞﾘｰｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_category_class)           := gt_edi_order_tab(ln_loop_cnt).category_class;                    -- ｶﾃｺﾞﾘｰ区分
      gt_data_tab(ln_data_cnt)(cv_carrier_means)            := iv_carrier_means;                                                -- 運送手段
      gt_data_tab(ln_data_cnt)(cv_counter_code)             := gt_edi_order_tab(ln_loop_cnt).counter_code;                      -- 売場ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_move_sign)                := gt_edi_order_tab(ln_loop_cnt).move_sign;                         -- 移動ｻｲﾝ
      gt_data_tab(ln_data_cnt)(cv_eos_handwriting_class)    := gt_edi_order_tab(ln_loop_cnt).medium_class;                      -- EOS･手書区分
      gt_data_tab(ln_data_cnt)(cv_delv_to_section_code)     := gt_edi_order_tab(ln_loop_cnt).delivery_to_section_code;          -- 納品先課ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_invc_detailed)            := gt_edi_order_tab(ln_loop_cnt).invoice_detailed;                  -- 伝票内訳
      gt_data_tab(ln_data_cnt)(cv_attach_qty)               := gt_edi_order_tab(ln_loop_cnt).attach_qty;                        -- 添付数
      gt_data_tab(ln_data_cnt)(cv_op_floor)                 := gt_edi_order_tab(ln_loop_cnt).other_party_floor;                 -- ﾌﾛｱ
      gt_data_tab(ln_data_cnt)(cv_text_no)                  := gt_edi_order_tab(ln_loop_cnt).text_no;                           -- TEXTNo
      gt_data_tab(ln_data_cnt)(cv_in_store_code)            := gt_edi_order_tab(ln_loop_cnt).in_store_code;                     -- ｲﾝｽﾄｱｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_tag_data)                 := gt_edi_order_tab(ln_loop_cnt).tag_data;                          -- ﾀｸﾞ
      gt_data_tab(ln_data_cnt)(cv_competition_code)         := gt_edi_order_tab(ln_loop_cnt).competition_code;                  -- 競合
      gt_data_tab(ln_data_cnt)(cv_billing_chair)            := gt_edi_order_tab(ln_loop_cnt).billing_chair;                     -- 請求口座
      gt_data_tab(ln_data_cnt)(cv_chain_store_code)         := gt_edi_order_tab(ln_loop_cnt).chain_store_code;                  -- ﾁｪｰﾝｽﾄｱｰｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_chain_store_short_name)   := gt_edi_order_tab(ln_loop_cnt).chain_store_short_name;            -- ﾁｪｰﾝｽﾄｱｰｺｰﾄﾞ略式名称
      gt_data_tab(ln_data_cnt)(cv_direct_delv_rcpt_fee)     := gt_edi_order_tab(ln_loop_cnt).direct_delivery_rcpt_fee;          -- 直配送/引取料
      gt_data_tab(ln_data_cnt)(cv_bill_info)                := gt_edi_order_tab(ln_loop_cnt).bill_info;                         -- 手形情報
      gt_data_tab(ln_data_cnt)(cv_description)              := gt_edi_order_tab(ln_loop_cnt).description;                       -- 摘要1
      gt_data_tab(ln_data_cnt)(cv_interior_code)            := gt_edi_order_tab(ln_loop_cnt).interior_code;                     -- 内部ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_order_info_delv_category) := gt_edi_order_tab(ln_loop_cnt).order_info_delivery_category;      -- 発注情報 納品ｶﾃｺﾞﾘｰ
      gt_data_tab(ln_data_cnt)(cv_purchase_type)            := gt_edi_order_tab(ln_loop_cnt).purchase_type;                     -- 仕入形態
      gt_data_tab(ln_data_cnt)(cv_delv_to_name_alt)         := gt_edi_order_tab(ln_loop_cnt).delivery_to_name_alt;              -- 納品場所名(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_shop_opened_site)         := gt_edi_order_tab(ln_loop_cnt).shop_opened_site;                  -- 店出場所
      gt_data_tab(ln_data_cnt)(cv_counter_name)             := gt_edi_order_tab(ln_loop_cnt).counter_name;                      -- 売場名
      gt_data_tab(ln_data_cnt)(cv_extension_number)         := gt_edi_order_tab(ln_loop_cnt).extension_number;                  -- 内線番号
      gt_data_tab(ln_data_cnt)(cv_charge_name)              := gt_edi_order_tab(ln_loop_cnt).charge_name;                       -- 担当者名
      gt_data_tab(ln_data_cnt)(cv_price_tag)                := gt_edi_order_tab(ln_loop_cnt).price_tag;                         -- 値札
      gt_data_tab(ln_data_cnt)(cv_tax_type)                 := gt_edi_order_tab(ln_loop_cnt).tax_type;                          -- 税種
      gt_data_tab(ln_data_cnt)(cv_consumption_tax_class)    := gt_edi_order_tab(ln_loop_cnt).consumption_tax_class;             -- 消費税区分
      gt_data_tab(ln_data_cnt)(cv_brand_class)              := gt_edi_order_tab(ln_loop_cnt).brand_class;                       -- BR
      gt_data_tab(ln_data_cnt)(cv_id_code)                  := gt_edi_order_tab(ln_loop_cnt).id_code;                           -- IDｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_department_code)          := gt_edi_order_tab(ln_loop_cnt).department_code;                   -- 百貨店ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_department_name)          := gt_edi_order_tab(ln_loop_cnt).department_name;                   -- 百貨店名
      gt_data_tab(ln_data_cnt)(cv_item_type_number)         := gt_edi_order_tab(ln_loop_cnt).item_type_number;                  -- 品別番号
      gt_data_tab(ln_data_cnt)(cv_description_department)   := gt_edi_order_tab(ln_loop_cnt).description_department;            -- 摘要2
      gt_data_tab(ln_data_cnt)(cv_price_tag_method)         := gt_edi_order_tab(ln_loop_cnt).price_tag_method;                  -- 値札方法
      gt_data_tab(ln_data_cnt)(cv_reason_column)            := gt_edi_order_tab(ln_loop_cnt).reason_column;                     -- 自由欄
      gt_data_tab(ln_data_cnt)(cv_a_column_header)          := gt_edi_order_tab(ln_loop_cnt).a_column_header;                   -- A欄ﾍｯﾀﾞ
      gt_data_tab(ln_data_cnt)(cv_d_column_header)          := gt_edi_order_tab(ln_loop_cnt).d_column_header;                   -- D欄ﾍｯﾀﾞ
      gt_data_tab(ln_data_cnt)(cv_brand_code)               := gt_edi_order_tab(ln_loop_cnt).brand_code;                        -- ﾌﾞﾗﾝﾄﾞｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_line_code)                := gt_edi_order_tab(ln_loop_cnt).line_code;                         -- ﾗｲﾝｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_class_code)               := gt_edi_order_tab(ln_loop_cnt).class_code;                        -- ｸﾗｽｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_a1_column)                := gt_edi_order_tab(ln_loop_cnt).a1_column;                         -- A-1欄
      gt_data_tab(ln_data_cnt)(cv_b1_column)                := gt_edi_order_tab(ln_loop_cnt).b1_column;                         -- B-1欄
      gt_data_tab(ln_data_cnt)(cv_c1_column)                := gt_edi_order_tab(ln_loop_cnt).c1_column;                         -- C-1欄
      gt_data_tab(ln_data_cnt)(cv_d1_column)                := gt_edi_order_tab(ln_loop_cnt).d1_column;                         -- D-1欄
      gt_data_tab(ln_data_cnt)(cv_e1_column)                := gt_edi_order_tab(ln_loop_cnt).e1_column;                         -- E-1欄
      gt_data_tab(ln_data_cnt)(cv_a2_column)                := gt_edi_order_tab(ln_loop_cnt).a2_column;                         -- A-2欄
      gt_data_tab(ln_data_cnt)(cv_b2_column)                := gt_edi_order_tab(ln_loop_cnt).b2_column;                         -- B-2欄
      gt_data_tab(ln_data_cnt)(cv_c2_column)                := gt_edi_order_tab(ln_loop_cnt).c2_column;                         -- C-2欄
      gt_data_tab(ln_data_cnt)(cv_d2_column)                := gt_edi_order_tab(ln_loop_cnt).d2_column;                         -- D-2欄
      gt_data_tab(ln_data_cnt)(cv_e2_column)                := gt_edi_order_tab(ln_loop_cnt).e2_column;                         -- E-2欄
      gt_data_tab(ln_data_cnt)(cv_a3_column)                := gt_edi_order_tab(ln_loop_cnt).a3_column;                         -- A-3欄
      gt_data_tab(ln_data_cnt)(cv_b3_column)                := gt_edi_order_tab(ln_loop_cnt).b3_column;                         -- B-3欄
      gt_data_tab(ln_data_cnt)(cv_c3_column)                := gt_edi_order_tab(ln_loop_cnt).c3_column;                         -- C-3欄
      gt_data_tab(ln_data_cnt)(cv_d3_column)                := gt_edi_order_tab(ln_loop_cnt).d3_column;                         -- D-3欄
      gt_data_tab(ln_data_cnt)(cv_e3_column)                := gt_edi_order_tab(ln_loop_cnt).e3_column;                         -- E-3欄
      gt_data_tab(ln_data_cnt)(cv_f1_column)                := gt_edi_order_tab(ln_loop_cnt).f1_column;                         -- F-1欄
      gt_data_tab(ln_data_cnt)(cv_g1_column)                := gt_edi_order_tab(ln_loop_cnt).g1_column;                         -- G-1欄
      gt_data_tab(ln_data_cnt)(cv_h1_column)                := gt_edi_order_tab(ln_loop_cnt).h1_column;                         -- H-1欄
      gt_data_tab(ln_data_cnt)(cv_i1_column)                := gt_edi_order_tab(ln_loop_cnt).i1_column;                         -- I-1欄
      gt_data_tab(ln_data_cnt)(cv_j1_column)                := gt_edi_order_tab(ln_loop_cnt).j1_column;                         -- J-1欄
      gt_data_tab(ln_data_cnt)(cv_k1_column)                := gt_edi_order_tab(ln_loop_cnt).k1_column;                         -- K-1欄
      gt_data_tab(ln_data_cnt)(cv_l1_column)                := gt_edi_order_tab(ln_loop_cnt).l1_column;                         -- L-1欄
      gt_data_tab(ln_data_cnt)(cv_f2_column)                := gt_edi_order_tab(ln_loop_cnt).f2_column;                         -- F-2欄
      gt_data_tab(ln_data_cnt)(cv_g2_column)                := gt_edi_order_tab(ln_loop_cnt).g2_column;                         -- G-2欄
      gt_data_tab(ln_data_cnt)(cv_h2_column)                := gt_edi_order_tab(ln_loop_cnt).h2_column;                         -- H-2欄
      gt_data_tab(ln_data_cnt)(cv_i2_column)                := gt_edi_order_tab(ln_loop_cnt).i2_column;                         -- I-2欄
      gt_data_tab(ln_data_cnt)(cv_j2_column)                := gt_edi_order_tab(ln_loop_cnt).j2_column;                         -- J-2欄
      gt_data_tab(ln_data_cnt)(cv_k2_column)                := gt_edi_order_tab(ln_loop_cnt).k2_column;                         -- K-2欄
      gt_data_tab(ln_data_cnt)(cv_l2_column)                := gt_edi_order_tab(ln_loop_cnt).l2_column;                         -- L-2欄
      gt_data_tab(ln_data_cnt)(cv_f3_column)                := gt_edi_order_tab(ln_loop_cnt).f3_column;                         -- F-3欄
      gt_data_tab(ln_data_cnt)(cv_g3_column)                := gt_edi_order_tab(ln_loop_cnt).g3_column;                         -- G-3欄
      gt_data_tab(ln_data_cnt)(cv_h3_column)                := gt_edi_order_tab(ln_loop_cnt).h3_column;                         -- H-3欄
      gt_data_tab(ln_data_cnt)(cv_i3_column)                := gt_edi_order_tab(ln_loop_cnt).i3_column;                         -- I-3欄
      gt_data_tab(ln_data_cnt)(cv_j3_column)                := gt_edi_order_tab(ln_loop_cnt).j3_column;                         -- J-3欄
      gt_data_tab(ln_data_cnt)(cv_k3_column)                := gt_edi_order_tab(ln_loop_cnt).k3_column;                         -- K-3欄
      gt_data_tab(ln_data_cnt)(cv_l3_column)                := gt_edi_order_tab(ln_loop_cnt).l3_column;                         -- L-3欄
      gt_data_tab(ln_data_cnt)(cv_chain_pec_area_header)    := gt_edi_order_tab(ln_loop_cnt).chain_peculiar_area_header;        -- ﾁｪｰﾝ店固有ｴﾘｱ(ﾍｯﾀﾞ)
      gt_data_tab(ln_data_cnt)(cv_order_connection_number)  := NULL;                                                            -- 受注関連番号
--
      -- 明細
      gt_data_tab(ln_data_cnt)(cv_line_no)                  := gt_edi_order_tab(ln_loop_cnt).line_no;                      -- 行No
      -- ダミー品目チェック
      ln_dummy_item := cn_0;
      <<dummy_item_loop>>
      FOR ln_dummy_item_loop_cnt IN 1 .. lt_dummy_item_tab.COUNT LOOP
        IF ( gt_edi_order_tab(ln_loop_cnt).ordered_item = lt_dummy_item_tab(ln_dummy_item_loop_cnt) ) THEN
          ln_dummy_item := cn_1;
          EXIT;
        END IF;
      END LOOP dummy_item_loop;
      -- 「商品コード(伊藤園)」が、ダミー品目の場合
      IF ( ln_dummy_item = cn_1) THEN
        gt_data_tab(ln_data_cnt)(cv_prod_code_itouen)       := NULL;                                                       -- 商品ｺｰﾄﾞ(伊藤園)
/* 2009/03/04 Ver1.6 Add Start */
        gt_data_tab(ln_data_cnt)(cv_prod_name)              := NULL;                                                       -- 商品名(漢字)
/* 2009/03/04 Ver1.6 Add  End  */
      -- 上記以外の場合
      ELSE
        gt_data_tab(ln_data_cnt)(cv_prod_code_itouen)       := gt_edi_order_tab(ln_loop_cnt).ordered_item;                 -- 商品ｺｰﾄﾞ(伊藤園)
/* 2009/03/04 Ver1.6 Add Start */
        gt_data_tab(ln_data_cnt)(cv_prod_name)              := gt_edi_order_tab(ln_loop_cnt).item_name;                    -- 商品名(漢字)
/* 2009/03/04 Ver1.6 Add  End  */
      END IF;
      gt_data_tab(ln_data_cnt)(cv_prod_code1)               := gt_edi_order_tab(ln_loop_cnt).product_code1;                -- 商品ｺｰﾄﾞ1
      -- 「媒体区分」が、'手入力'でかつ、「商品コード２」が、NULLの場合
      IF  ( gt_edi_order_tab(ln_loop_cnt).medium_class = cv_medium_class_mnl )
      AND ( gt_edi_order_tab(ln_loop_cnt).product_code2 IS NULL )
      THEN
        --品目コード変換（EBS→EDI)
        xxcos_common2_pkg.conv_edi_item_code(
           iv_edi_chain_code   =>  gt_edi_order_tab(ln_loop_cnt).edi_chain_code  -- EDIチェーン店コード
          ,iv_item_code        =>  gt_edi_order_tab(ln_loop_cnt).item_code       -- 品目コード
          ,iv_organization_id  =>  gn_organization_id                            -- 在庫組織ID
          ,iv_uom_code         =>  gt_edi_order_tab(ln_loop_cnt).line_uom        -- 単位コード
          ,ov_product_code2    =>  lv_product_code                               -- 商品コード２
          ,ov_jan_code         =>  lv_jan_code                                   -- JANコード
          ,ov_case_jan_code    =>  lv_case_jan_code                              -- ケースJANコード
          ,ov_errbuf           =>  lv_errbuf                                     -- エラーメッセージ
          ,ov_retcode          =>  lv_retcode                                    -- リターンコード
          ,ov_errmsg           =>  lv_errmsg                                     -- ユーザー・エラー・メッセージ
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- メッセージ取得
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- アプリケーション
                         ,iv_name         => cv_msg_com_fnuc_err  -- EDI共通関数エラーメッセージ
                         ,iv_token_name1  => cv_tkn_err_msg       -- トークンコード１
                         ,iv_token_value1 => lv_errmsg            -- エラー・メッセージ
                       );
          RAISE global_api_others_expt;
        END IF;
        -- 取得した商品コードが、NULLの場合
        IF ( lv_product_code IS NULL ) THEN
          -- メッセージ取得
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application      -- アプリケーション
                          ,iv_name         => cv_msg_product_err  -- 商品コードエラーメッセージ
                          ,iv_token_name1  => cv_tkn_chain_code   -- トークンコード１
                          ,iv_token_value1 => gt_edi_order_tab(ln_loop_cnt).edi_chain_code  -- EDIチェーン店コード
                          ,iv_token_name2  => cv_tkn_item_code    -- トークンコード２
                          ,iv_token_value2 => gt_edi_order_tab(ln_loop_cnt).item_code       -- 品目コード
                        );
          -- メッセージに出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  -- エラー有り
        END IF;
        gt_data_tab(ln_data_cnt)(cv_prod_code2)             := lv_product_code;                                            -- 商品ｺｰﾄﾞ2
      -- 上記以外の場合
      ELSE
        gt_data_tab(ln_data_cnt)(cv_prod_code2)             := gt_edi_order_tab(ln_loop_cnt).product_code2;                -- 商品ｺｰﾄﾞ2
      END IF;
      -- 「明細単位」が、'ケース単位コード'の場合
      IF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_case_uom_code ) THEN
        gt_data_tab(ln_data_cnt)(cv_jan_code)               := gt_edi_order_tab(ln_loop_cnt).case_jan_code;                -- JANｺｰﾄﾞ
      -- 上記以外の場合
      ELSE
        gt_data_tab(ln_data_cnt)(cv_jan_code)               := gt_edi_order_tab(ln_loop_cnt).opf_jan_code;                 -- JANｺｰﾄﾞ
      END IF;
      gt_data_tab(ln_data_cnt)(cv_itf_code)                 := NVL(gt_edi_order_tab(ln_loop_cnt).itf_code,
                                                                   gt_edi_order_tab(ln_loop_cnt).opm_itf_code);            -- ITFｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_extension_itf_code)       := gt_edi_order_tab(ln_loop_cnt).extension_itf_code;           -- 内箱ITFｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_case_prod_code)           := gt_edi_order_tab(ln_loop_cnt).case_product_code;            -- ｹｰｽ商品ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_ball_prod_code)           := gt_edi_order_tab(ln_loop_cnt).ball_product_code;            -- ﾎﾞｰﾙ商品ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_prod_code_item_type)      := gt_edi_order_tab(ln_loop_cnt).product_code_item_type;       -- 商品ｺｰﾄﾞ品種
      gt_data_tab(ln_data_cnt)(cv_prod_class)               := gt_edi_order_tab(ln_loop_cnt).item_div_h_code;              -- 商品区分
/* 2009/03/04 Ver1.6 Del Start */
--    gt_data_tab(ln_data_cnt)(cv_prod_name)                := gt_edi_order_tab(ln_loop_cnt).product_name;                 -- 商品名(漢字)
/* 2009/03/04 Ver1.6 Del  End  */
      gt_data_tab(ln_data_cnt)(cv_prod_name1_alt)           := gt_edi_order_tab(ln_loop_cnt).product_name1_alt;            -- 商品名1(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_prod_name2_alt)           := NVL(gt_edi_order_tab(ln_loop_cnt).product_name2_alt,
                                                                   gt_edi_order_tab(ln_loop_cnt).item_name_alt);           -- 商品名2(ｶﾅ)
      gt_data_tab(ln_data_cnt)(cv_item_standard1)           := gt_edi_order_tab(ln_loop_cnt).item_standard1;               -- 規格1
      gt_data_tab(ln_data_cnt)(cv_item_standard2)           := NVL(gt_edi_order_tab(ln_loop_cnt).item_standard2,
                                                                   gt_edi_order_tab(ln_loop_cnt).item_name_alt2);          -- 規格2
      gt_data_tab(ln_data_cnt)(cv_qty_in_case)              := gt_edi_order_tab(ln_loop_cnt).qty_in_case;                  -- 入数
      gt_data_tab(ln_data_cnt)(cv_num_of_cases)             := gt_edi_order_tab(ln_loop_cnt).num_of_case;                  -- ｹｰｽ入数
      gt_data_tab(ln_data_cnt)(cv_num_of_ball)              := NVL(gt_edi_order_tab(ln_loop_cnt).num_of_ball,
                                                                   gt_edi_order_tab(ln_loop_cnt).bowl_inc_num);            -- ﾎﾞｰﾙ入数
      gt_data_tab(ln_data_cnt)(cv_item_color)               := gt_edi_order_tab(ln_loop_cnt).item_color;                   -- 色
      gt_data_tab(ln_data_cnt)(cv_item_size)                := gt_edi_order_tab(ln_loop_cnt).item_size;                    -- ｻｲｽﾞ
      gt_data_tab(ln_data_cnt)(cv_expiration_date)          := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).expiration_date, cv_date_format);  -- 賞味期限日
      gt_data_tab(ln_data_cnt)(cv_prod_date)                := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).product_date, cv_date_format);     -- 製造日
      gt_data_tab(ln_data_cnt)(cv_order_uom_qty)            := gt_edi_order_tab(ln_loop_cnt).order_uom_qty;                -- 発注単位数
      gt_data_tab(ln_data_cnt)(cv_ship_uom_qty)             := gt_edi_order_tab(ln_loop_cnt).shipping_uom_qty;             -- 出荷単位数
      gt_data_tab(ln_data_cnt)(cv_packing_uom_qty)          := gt_edi_order_tab(ln_loop_cnt).packing_uom_qty;              -- 梱包単位数
      gt_data_tab(ln_data_cnt)(cv_deal_code)                := gt_edi_order_tab(ln_loop_cnt).deal_code;                    -- 引合
      gt_data_tab(ln_data_cnt)(cv_deal_class)               := gt_edi_order_tab(ln_loop_cnt).deal_class;                   -- 引合区分
      gt_data_tab(ln_data_cnt)(cv_collation_code)           := gt_edi_order_tab(ln_loop_cnt).collation_code;               -- 照合
      gt_data_tab(ln_data_cnt)(cv_uom_code)                 := gt_edi_order_tab(ln_loop_cnt).uom_code;                     -- 単位
      gt_data_tab(ln_data_cnt)(cv_unit_price_class)         := gt_edi_order_tab(ln_loop_cnt).unit_price_class;             -- 単価区分
      gt_data_tab(ln_data_cnt)(cv_parent_packing_number)    := gt_edi_order_tab(ln_loop_cnt).parent_packing_number;        -- 親梱包番号
      gt_data_tab(ln_data_cnt)(cv_packing_number)           := gt_edi_order_tab(ln_loop_cnt).packing_number;               -- 梱包番号
      gt_data_tab(ln_data_cnt)(cv_prod_group_code)          := gt_edi_order_tab(ln_loop_cnt).product_group_code;           -- 商品群ｺｰﾄﾞ
      gt_data_tab(ln_data_cnt)(cv_case_dismantle_flag)      := gt_edi_order_tab(ln_loop_cnt).case_dismantle_flag;          -- ｹｰｽ解体不可ﾌﾗｸﾞ
      gt_data_tab(ln_data_cnt)(cv_case_class)               := gt_edi_order_tab(ln_loop_cnt).case_class;                   -- ｹｰｽ区分
      -- 「媒体区分」が、'手入力'の場合
      IF ( gt_edi_order_tab(ln_loop_cnt).medium_class = cv_medium_class_mnl ) THEN
        -- 「明細単位」が、'ケース単位コード'の場合
        IF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_case_uom_code ) THEN
          gt_data_tab(ln_data_cnt)(cv_indv_order_qty)       := cn_0;                                                       -- 発注数量(ﾊﾞﾗ)
          gt_data_tab(ln_data_cnt)(cv_case_order_qty)       := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 発注数量(ｹｰｽ)
          gt_data_tab(ln_data_cnt)(cv_ball_order_qty)       := cn_0;                                                       -- 発注数量(ﾎﾞｰﾙ)
          gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 発注数量(合計､ﾊﾞﾗ)
        -- 「明細単位」が、'ボール単位コード'の場合
        ELSIF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_ball_uom_code ) THEN
          gt_data_tab(ln_data_cnt)(cv_indv_order_qty)       := cn_0;                                                       -- 発注数量(ﾊﾞﾗ)
          gt_data_tab(ln_data_cnt)(cv_case_order_qty)       := cn_0;                                                       -- 発注数量(ｹｰｽ)
          gt_data_tab(ln_data_cnt)(cv_ball_order_qty)       := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 発注数量(ﾎﾞｰﾙ)
          gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 発注数量(合計､ﾊﾞﾗ)
        -- 上記以外の場合
        ELSE
          gt_data_tab(ln_data_cnt)(cv_indv_order_qty)       := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 発注数量(ﾊﾞﾗ)
          gt_data_tab(ln_data_cnt)(cv_case_order_qty)       := cn_0;                                                       -- 発注数量(ｹｰｽ)
          gt_data_tab(ln_data_cnt)(cv_ball_order_qty)       := cn_0;                                                       -- 発注数量(ﾎﾞｰﾙ)
          gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 発注数量(合計､ﾊﾞﾗ)
        END IF;
      -- 上記以外の場合
      ELSE
        gt_data_tab(ln_data_cnt)(cv_indv_order_qty)         := gt_edi_order_tab(ln_loop_cnt).indv_order_qty;               -- 発注数量(ﾊﾞﾗ)
        gt_data_tab(ln_data_cnt)(cv_case_order_qty)         := gt_edi_order_tab(ln_loop_cnt).case_order_qty;               -- 発注数量(ｹｰｽ)
        gt_data_tab(ln_data_cnt)(cv_ball_order_qty)         := gt_edi_order_tab(ln_loop_cnt).ball_order_qty;               -- 発注数量(ﾎﾞｰﾙ)
        gt_data_tab(ln_data_cnt)(cv_sum_order_qty)          := gt_edi_order_tab(ln_loop_cnt).sum_order_qty;                -- 発注数量(合計､ﾊﾞﾗ)
      END IF;
--
--****************************** 2009/06/24 1.10 T.Kitajima MOD START ******************************--
--      -- 「明細単位」が、'ケース単位コード'の場合
--      IF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_case_uom_code ) THEN
--        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := cn_0;                                                       -- 出荷数量(ﾊﾞﾗ)
--        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 出荷数量(ｹｰｽ)
--        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := cn_0;                                                       -- 出荷数量(ﾎﾞｰﾙ)
--        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 出荷数量(合計､ﾊﾞﾗ)
--      -- 「明細単位」が、'ボール単位コード'の場合
--      ELSIF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_ball_uom_code ) THEN
--        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := cn_0;                                                       -- 出荷数量(ﾊﾞﾗ)
--        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := cn_0;                                                       -- 出荷数量(ｹｰｽ)
--        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 出荷数量(ﾎﾞｰﾙ)
--        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 出荷数量(合計､ﾊﾞﾗ)
--      -- 上記以外の場合
--      ELSE
--        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 出荷数量(ﾊﾞﾗ)
--        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := cn_0;                                                       -- 出荷数量(ｹｰｽ)
--        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := cn_0;                                                       -- 出荷数量(ﾎﾞｰﾙ)
--        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 出荷数量(合計､ﾊﾞﾗ)
--      END IF;
--
--      gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)             := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 出荷数量(合計､ﾊﾞﾗ)
-- ********* 2009/09/25 1.13 N.Maeda MOD START ********* --
      gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)             := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- 出荷数量(合計､ﾊﾞﾗ)
--      gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)             := gt_edi_order_tab(ln_loop_cnt).sum_shipping_qty;             -- 出荷数量(合計､ﾊﾞﾗ)
-- ********* 2009/09/25 1.13 N.Maeda MOD  END  ********* --
--
      xxcos_common2_pkg.convert_quantity(
/* 2009/07/24 Ver1.11 Mod Start */
--               iv_uom_code             => gt_data_tab(ln_data_cnt)(cv_uom_code)               --IN :単位コード
               iv_uom_code             => gt_edi_order_tab(ln_loop_cnt).order_quantity_uom --IN :単位コード
/* 2009/07/24 Ver1.11 Mod End   */
              ,in_case_qty             => gt_data_tab(ln_data_cnt)(cv_num_of_cases)        --IN :ケース入数
              ,in_ball_qty             => NVL( gt_edi_order_tab(ln_loop_cnt).num_of_ball
                                              ,gt_edi_order_tab(ln_loop_cnt).bowl_inc_num
                                             )                                             --IN :ボール入数
              ,in_sum_indv_order_qty   => gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        --IN :発注数量(合計・バラ)
              ,in_sum_shipping_qty     => gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)        --IN :出荷数量(合計・バラ)
              ,on_indv_shipping_qty    => gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)       --OUT:出荷数量(バラ)
              ,on_case_shipping_qty    => gt_data_tab(ln_data_cnt)(cv_case_ship_qty)       --OUT:出荷数量(ケース)
              ,on_ball_shipping_qty    => gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)       --OUT:出荷数量(ボール)
              ,on_indv_stockout_qty    => gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty)     --OUT:欠品数量(バラ)
              ,on_case_stockout_qty    => gt_data_tab(ln_data_cnt)(cv_case_stkout_qty)     --OUT:欠品数量(ケース)
              ,on_ball_stockout_qty    => gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty)     --OUT:欠品数量(ボール)
              ,on_sum_stockout_qty     => gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)      --OUT:欠品数量(合計・バラ)
              ,ov_errbuf               => lv_errbuf                                        --OUT:エラー・メッセージエラー #固定#
              ,ov_retcode              => lv_retcode                                       --OUT:リターン・コード         #固定#
              ,ov_errmsg               => lv_errmsg                                        --ユーザー・エラー・メッセージ #固定#
              );
      IF ( lv_retcode = cv_status_error ) THEN
--        lv_errmsg := lv_errbuf;
        RAISE global_api_expt;
      END IF;
--****************************** 2009/06/24 1.10 T.Kitajima MOD  END  ******************************--
-- 2009/05/22 Ver1.9 Add Start
      -- 商品コード(伊藤園)」が、ダミー品目の場合、全て"0"に変更
      IF ( ln_dummy_item = cn_1) THEN
        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := cn_0;                                                       -- 出荷数量(ﾊﾞﾗ)
        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := cn_0;                                                       -- 出荷数量(ｹｰｽ)
        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := cn_0;                                                       -- 出荷数量(ﾎﾞｰﾙ)
        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := cn_0;                                                       -- 出荷数量(合計､ﾊﾞﾗ)
      END IF;
-- 2009/05/22 Ver1.9 Add End
      gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty)          := NULL;                                                       -- 出荷数量(ﾊﾟﾚｯﾄ)
--****************************** 2009/06/24 1.10 T.Kitajima DEL START ******************************--
--/* 2009/02/25 Ver1.4 Mod Start */
--    gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty)          := gt_data_tab(ln_data_cnt)(cv_indv_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_indv_ship_qty);                 -- 欠品数量(ﾊﾞﾗ)
--    gt_data_tab(ln_data_cnt)(cv_case_stkout_qty)          := gt_data_tab(ln_data_cnt)(cv_case_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_case_ship_qty);                 -- 欠品数量(ｹｰｽ)
--    gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty)          := gt_data_tab(ln_data_cnt)(cv_ball_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_ball_ship_qty);                 -- 欠品数量(ﾎﾞｰﾙ)
--    gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)           := gt_data_tab(ln_data_cnt)(cv_sum_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_sum_ship_qty);                  -- 欠品数量(合計､ﾊﾞﾗ)
--      gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty)          := NVL(gt_data_tab(ln_data_cnt)(cv_indv_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_indv_ship_qty), 0);         -- 欠品数量(ﾊﾞﾗ)
--      gt_data_tab(ln_data_cnt)(cv_case_stkout_qty)          := NVL(gt_data_tab(ln_data_cnt)(cv_case_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_case_ship_qty), 0);         -- 欠品数量(ｹｰｽ)
--      gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty)          := NVL(gt_data_tab(ln_data_cnt)(cv_ball_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_ball_ship_qty), 0);         -- 欠品数量(ﾎﾞｰﾙ)
--      gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)           := NVL(gt_data_tab(ln_data_cnt)(cv_sum_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0);          -- 欠品数量(合計､ﾊﾞﾗ)
--/* 2009/02/25 Ver1.4 Mod  End  */
--****************************** 2009/06/24 1.10 T.Kitajima DEL  END  ******************************--
      -- 欠品数量(受注数量－出荷数量)＝０の場合
      IF ( gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty) = cn_0 ) THEN
        gt_data_tab(ln_data_cnt)(cv_stkout_class)           := cv_stockout_class_00;                                       -- 欠品区分
      ELSE
        gt_data_tab(ln_data_cnt)(cv_stkout_class)           := gt_edi_order_tab(ln_loop_cnt).stockout_class;               -- 欠品区分
      END IF;
-- 2009/05/22 Ver1.9 Mod Start
      -- 商品コード(伊藤園)」が、ダミー品目の場合、プロファイル値に修正
      IF ( ln_dummy_item = cn_1) THEN
        gt_data_tab(ln_data_cnt)(cv_stkout_class)           := gn_dum_stock_out;                                           -- 欠品区分
      END IF;
-- 2009/05/22 Ver1.9 Mod End
      gt_data_tab(ln_data_cnt)(cv_stkout_reason)            := NULL;                                                       -- 欠品理由
      gt_data_tab(ln_data_cnt)(cv_case_qty)                 := gt_edi_order_tab(ln_loop_cnt).case_qty;                     -- ｹｰｽ個口数
      gt_data_tab(ln_data_cnt)(cv_fold_container_indv_qty)  := gt_edi_order_tab(ln_loop_cnt).fold_container_indv_qty;      -- ｵﾘｺﾝ(ﾊﾞﾗ)個口数
      gt_data_tab(ln_data_cnt)(cv_order_unit_price)         := gt_edi_order_tab(ln_loop_cnt).order_unit_price;             -- 原単価(発注)
      gt_data_tab(ln_data_cnt)(cv_ship_unit_price)          := gt_edi_order_tab(ln_loop_cnt).unit_selling_price;           -- 原単価(出荷)
      gt_data_tab(ln_data_cnt)(cv_order_cost_amt)           := gt_edi_order_tab(ln_loop_cnt).order_cost_amt;               -- 原価金額(発注)
/* 2009/02/25 Ver1.4 Mod Start */
--    gt_data_tab(ln_data_cnt)(cv_ship_cost_amt)            := gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)
--                                                           * gt_data_tab(ln_data_cnt)(cv_ship_unit_price);               -- 原価金額(出荷)
--    gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt)          := gt_data_tab(ln_data_cnt)(cv_order_cost_amt)
--                                                           - gt_data_tab(ln_data_cnt)(cv_ship_cost_amt);                 -- 原価金額(欠品)
/* 2009/07/21 Ver1.11 Mod Start */
--      gt_data_tab(ln_data_cnt)(cv_ship_cost_amt)            := NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0)
--                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_ship_unit_price), 0);       -- 原価金額(出荷)
      gt_data_tab(ln_data_cnt)(cv_ship_cost_amt)            := TRUNC(NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0)
                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_ship_unit_price), 0));      -- 原価金額(出荷)
/* 2009/07/21 Ver1.11 Mod End   */
/* 2009/02/27 Ver1.5 Mod Start */
      -- 「媒体区分」が、'手入力'の場合
      IF ( gt_edi_order_tab(ln_loop_cnt).medium_class = cv_medium_class_mnl ) THEN
        gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt)        := cn_0;                                                       -- 原価金額(欠品)
      ELSE
        gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt)        := NVL(gt_data_tab(ln_data_cnt)(cv_order_cost_amt), 0)
                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_ship_cost_amt), 0);         -- 原価金額(欠品)
      END IF;
/* 2009/02/27 Ver1.5 Mod  End  */
      gt_data_tab(ln_data_cnt)(cv_selling_price)            := gt_edi_order_tab(ln_loop_cnt).selling_price;                -- 売単価
      gt_data_tab(ln_data_cnt)(cv_order_price_amt)          := gt_edi_order_tab(ln_loop_cnt).order_price_amt;              -- 売価金額(発注)
--    gt_data_tab(ln_data_cnt)(cv_ship_price_amt)           := gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)
--                                                           * gt_data_tab(ln_data_cnt)(cv_selling_price);                 -- 売価金額(出荷)
--    gt_data_tab(ln_data_cnt)(cv_stkout_price_amt)         := gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)
--                                                           * gt_data_tab(ln_data_cnt)(cv_selling_price);                 -- 売価金額(欠品)
      gt_data_tab(ln_data_cnt)(cv_ship_price_amt)           := NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0)
                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_selling_price), 0);         -- 売価金額(出荷)
      gt_data_tab(ln_data_cnt)(cv_stkout_price_amt)         := NVL(gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty), 0)
                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_selling_price), 0);         -- 売価金額(欠品)
/* 2009/02/25 Ver1.4 Mod  End  */
      gt_data_tab(ln_data_cnt)(cv_a_column_department)      := gt_edi_order_tab(ln_loop_cnt).a_column_department;          -- A欄(百貨店)
      gt_data_tab(ln_data_cnt)(cv_d_column_department)      := gt_edi_order_tab(ln_loop_cnt).d_column_department;          -- D欄(百貨店)
      gt_data_tab(ln_data_cnt)(cv_standard_info_depth)      := gt_edi_order_tab(ln_loop_cnt).standard_info_depth;          -- 規格情報･奥行き
      gt_data_tab(ln_data_cnt)(cv_standard_info_height)     := gt_edi_order_tab(ln_loop_cnt).standard_info_height;         -- 規格情報･高さ
      gt_data_tab(ln_data_cnt)(cv_standard_info_width)      := gt_edi_order_tab(ln_loop_cnt).standard_info_width;          -- 規格情報･幅
      gt_data_tab(ln_data_cnt)(cv_standard_info_weight)     := gt_edi_order_tab(ln_loop_cnt).standard_info_weight;         -- 規格情報･重量
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item1)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item1;      -- 汎用引継ぎ項目1
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item2)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item2;      -- 汎用引継ぎ項目2
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item3)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item3;      -- 汎用引継ぎ項目3
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item4)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item4;      -- 汎用引継ぎ項目4
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item5)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item5;      -- 汎用引継ぎ項目5
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item6)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item6;      -- 汎用引継ぎ項目6
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item7)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item7;      -- 汎用引継ぎ項目7
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item8)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item8;      -- 汎用引継ぎ項目8
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item9)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item9;      -- 汎用引継ぎ項目9
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item10)           := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item10;     -- 汎用引継ぎ項目10
      gt_data_tab(ln_data_cnt)(cv_gen_add_item1)            := gt_edi_order_tab(ln_loop_cnt).tax_rate;                     -- 汎用付加項目1
      gt_data_tab(ln_data_cnt)(cv_gen_add_item2)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic, 1, 10);
                                                                                                                           -- 汎用付加項目2
      gt_data_tab(ln_data_cnt)(cv_gen_add_item3)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic, 11, 10);
                                                                                                                           -- 汎用付加項目3
      gt_data_tab(ln_data_cnt)(cv_gen_add_item4)            := gt_edi_order_tab(ln_loop_cnt).general_add_item4;            -- 汎用付加項目4
      gt_data_tab(ln_data_cnt)(cv_gen_add_item5)            := gt_edi_order_tab(ln_loop_cnt).general_add_item5;            -- 汎用付加項目5
      gt_data_tab(ln_data_cnt)(cv_gen_add_item6)            := gt_edi_order_tab(ln_loop_cnt).general_add_item6;            -- 汎用付加項目6
      gt_data_tab(ln_data_cnt)(cv_gen_add_item7)            := gt_edi_order_tab(ln_loop_cnt).general_add_item7;            -- 汎用付加項目7
      gt_data_tab(ln_data_cnt)(cv_gen_add_item8)            := gt_edi_order_tab(ln_loop_cnt).general_add_item8;            -- 汎用付加項目8
      gt_data_tab(ln_data_cnt)(cv_gen_add_item9)            := gt_edi_order_tab(ln_loop_cnt).general_add_item9;            -- 汎用付加項目9
      gt_data_tab(ln_data_cnt)(cv_gen_add_item10)           := gt_edi_order_tab(ln_loop_cnt).general_add_item10;           -- 汎用付加項目10
      gt_data_tab(ln_data_cnt)(cv_chain_pec_area_line)      := gt_edi_order_tab(ln_loop_cnt).chain_peculiar_area_line;     -- ﾁｪｰﾝ店固有ｴﾘｱ(明細)
--
      -- フッタ
      gt_data_tab(ln_data_cnt)(cv_invc_indv_order_qty)        := NULL;  -- (伝票計)発注数量(ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_invc_case_order_qty)        := NULL;  -- (伝票計)発注数量(ｹｰｽ)
      gt_data_tab(ln_data_cnt)(cv_invc_ball_order_qty)        := NULL;  -- (伝票計)発注数量(ﾎﾞｰﾙ)
      gt_data_tab(ln_data_cnt)(cv_invc_sum_order_qty)         := NULL;  -- (伝票計)発注数量(合計､ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_invc_indv_ship_qty)         := NULL;  -- (伝票計)出荷数量(ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_invc_case_ship_qty)         := NULL;  -- (伝票計)出荷数量(ｹｰｽ)
      gt_data_tab(ln_data_cnt)(cv_invc_ball_ship_qty)         := NULL;  -- (伝票計)出荷数量(ﾎﾞｰﾙ)
      gt_data_tab(ln_data_cnt)(cv_invc_pallet_ship_qty)       := NULL;  -- (伝票計)出荷数量(ﾊﾟﾚｯﾄ)
      gt_data_tab(ln_data_cnt)(cv_invc_sum_ship_qty)          := NULL;  -- (伝票計)出荷数量(合計､ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_invc_indv_stkout_qty)       := NULL;  -- (伝票計)欠品数量(ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_invc_case_stkout_qty)       := NULL;  -- (伝票計)欠品数量(ｹｰｽ)
      gt_data_tab(ln_data_cnt)(cv_invc_ball_stkout_qty)       := NULL;  -- (伝票計)欠品数量(ﾎﾞｰﾙ)
      gt_data_tab(ln_data_cnt)(cv_invc_sum_stkout_qty)        := NULL;  -- (伝票計)欠品数量(合計､ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_invc_case_qty)              := NULL;  -- (伝票計)ｹｰｽ個口数
      gt_data_tab(ln_data_cnt)(cv_invc_fold_container_qty)    := gt_edi_order_tab(ln_loop_cnt).fold_container_indv_qty;     -- (伝票計)ｵﾘｺﾝ(ﾊﾞﾗ)個口数
      gt_data_tab(ln_data_cnt)(cv_invc_order_cost_amt)        := NULL;  -- (伝票計)原価金額(発注)
      gt_data_tab(ln_data_cnt)(cv_invc_ship_cost_amt)         := NULL;  -- (伝票計)原価金額(出荷)
      gt_data_tab(ln_data_cnt)(cv_invc_stkout_cost_amt)       := NULL;  -- (伝票計)原価金額(欠品)
      gt_data_tab(ln_data_cnt)(cv_invc_order_price_amt)       := NULL;  -- (伝票計)売価金額(発注)
      gt_data_tab(ln_data_cnt)(cv_invc_ship_price_amt)        := NULL;  -- (伝票計)売価金額(出荷)
      gt_data_tab(ln_data_cnt)(cv_invc_stkout_price_amt)      := NULL;  -- (伝票計)売価金額(欠品)
      gt_data_tab(ln_data_cnt)(cv_t_indv_order_qty)           := NULL;  -- (総合計)発注数量(ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_t_case_order_qty)           := NULL;  -- (総合計)発注数量(ｹｰｽ)
      gt_data_tab(ln_data_cnt)(cv_t_ball_order_qty)           := NULL;  -- (総合計)発注数量(ﾎﾞｰﾙ)
      gt_data_tab(ln_data_cnt)(cv_t_sum_order_qty)            := NULL;  -- (総合計)発注数量(合計､ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_t_indv_ship_qty)            := NULL;  -- (総合計)出荷数量(ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_t_case_ship_qty)            := NULL;  -- (総合計)出荷数量(ｹｰｽ)
      gt_data_tab(ln_data_cnt)(cv_t_ball_ship_qty)            := NULL;  -- (総合計)出荷数量(ﾎﾞｰﾙ)
      gt_data_tab(ln_data_cnt)(cv_t_pallet_ship_qty)          := NULL;  -- (総合計)出荷数量(ﾊﾟﾚｯﾄ)
      gt_data_tab(ln_data_cnt)(cv_t_sum_ship_qty)             := NULL;  -- (総合計)出荷数量(合計､ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_t_indv_stkout_qty)          := NULL;  -- (総合計)欠品数量(ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_t_case_stkout_qty)          := NULL;  -- (総合計)欠品数量(ｹｰｽ)
      gt_data_tab(ln_data_cnt)(cv_t_ball_stkout_qty)          := NULL;  -- (総合計)欠品数量(ﾎﾞｰﾙ)
      gt_data_tab(ln_data_cnt)(cv_t_sum_stkout_qty)           := NULL;  -- (総合計)欠品数量(合計､ﾊﾞﾗ)
      gt_data_tab(ln_data_cnt)(cv_t_case_qty)                 := NULL;  -- (総合計)ｹｰｽ個口数
      gt_data_tab(ln_data_cnt)(cv_t_fold_container_qty)       := NULL;  -- (総合計)ｵﾘｺﾝ(ﾊﾞﾗ)個口数
      gt_data_tab(ln_data_cnt)(cv_t_order_cost_amt)           := NULL;  -- (総合計)原価金額(発注)
      gt_data_tab(ln_data_cnt)(cv_t_ship_cost_amt)            := NULL;  -- (総合計)原価金額(出荷)
      gt_data_tab(ln_data_cnt)(cv_t_stkout_cost_amt)          := NULL;  -- (総合計)原価金額(欠品)
      gt_data_tab(ln_data_cnt)(cv_t_order_price_amt)          := NULL;  -- (総合計)売価金額(発注)
      gt_data_tab(ln_data_cnt)(cv_t_ship_price_amt)           := NULL;  -- (総合計)売価金額(出荷)
      gt_data_tab(ln_data_cnt)(cv_t_stkout_price_amt)         := NULL;  -- (総合計)売価金額(欠品)
      gt_data_tab(ln_data_cnt)(cv_t_line_qty)                 := gt_edi_order_tab(ln_loop_cnt).total_line_qty;              -- ﾄｰﾀﾙ行数
      gt_data_tab(ln_data_cnt)(cv_t_invc_qty)                 := gt_edi_order_tab(ln_loop_cnt).total_invoice_qty;           -- ﾄｰﾀﾙ伝票枚数
      gt_data_tab(ln_data_cnt)(cv_chain_pec_area_footer)      := gt_edi_order_tab(ln_loop_cnt).chain_peculiar_area_footer;  -- ﾁｪｰﾝ店固有ｴﾘｱ(ﾌｯﾀ)
/* 2009/04/28 Ver1.7 Add Start */
      gt_data_tab(ln_data_cnt)(cv_attribute)                  := NULL;  -- 予備エリア
/* 2009/04/28 Ver1.7 Add End   */
--
      --==============================================================
      -- 伝票別合計算出
      --==============================================================
/* 2009/02/25 Ver1.4 Mod Start */
/*
      l_invoice_total_rec.indv_order_qty      := l_invoice_total_rec.indv_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_indv_order_qty);    -- 発注数量(バラ)
      l_invoice_total_rec.case_order_qty      := l_invoice_total_rec.case_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_order_qty);    -- 発注数量(ケース)
      l_invoice_total_rec.ball_order_qty      := l_invoice_total_rec.ball_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_ball_order_qty);    -- 発注数量(ボール)
      l_invoice_total_rec.sum_order_qty       := l_invoice_total_rec.sum_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_sum_order_qty);     -- 発注数量(合計、バラ)
      l_invoice_total_rec.indv_shipping_qty   := l_invoice_total_rec.indv_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_indv_ship_qty);     -- 出荷数量(バラ)
      l_invoice_total_rec.case_shipping_qty   := l_invoice_total_rec.case_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_ship_qty);     -- 出荷数量(ケース)
      l_invoice_total_rec.ball_shipping_qty   := l_invoice_total_rec.ball_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_ball_ship_qty);     -- 出荷数量(ボール)
      l_invoice_total_rec.pallet_shipping_qty := l_invoice_total_rec.pallet_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty);   -- 出荷数量(パレット)
      l_invoice_total_rec.sum_shipping_qty    := l_invoice_total_rec.sum_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_sum_ship_qty);      -- 出荷数量(合計、バラ)
      l_invoice_total_rec.indv_stockout_qty   := l_invoice_total_rec.indv_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty);   -- 欠品数量(バラ)
      l_invoice_total_rec.case_stockout_qty   := l_invoice_total_rec.case_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_stkout_qty);   -- 欠品数量(ケース)
      l_invoice_total_rec.ball_stockout_qty   := l_invoice_total_rec.ball_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty);   -- 欠品数量(ボール)
      l_invoice_total_rec.sum_stockout_qty    := l_invoice_total_rec.sum_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty);    -- 欠品数量(合計、バラ)
      l_invoice_total_rec.case_qty            := l_invoice_total_rec.case_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_qty);          -- ケース個口数
      l_invoice_total_rec.order_cost_amt      := l_invoice_total_rec.order_cost_amt
                                               + gt_data_tab(ln_data_cnt)(cv_order_cost_amt);    -- 原価金額(発注)
      l_invoice_total_rec.shipping_cost_amt   := l_invoice_total_rec.shipping_cost_amt
                                               + gt_data_tab(ln_data_cnt)(cv_ship_cost_amt);     -- 原価金額(出荷)
      l_invoice_total_rec.stockout_cost_amt   := l_invoice_total_rec.stockout_cost_amt
                                               + gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt);   -- 原価金額(欠品)
      l_invoice_total_rec.order_price_amt     := l_invoice_total_rec.order_price_amt
                                               + gt_data_tab(ln_data_cnt)(cv_order_price_amt);   -- 売価金額(発注)
      l_invoice_total_rec.shipping_price_amt  := l_invoice_total_rec.shipping_price_amt
                                               + gt_data_tab(ln_data_cnt)(cv_ship_price_amt);    -- 売価金額(出荷)
      l_invoice_total_rec.stockout_price_amt  := l_invoice_total_rec.stockout_price_amt
                                               + gt_data_tab(ln_data_cnt)(cv_stkout_price_amt);  -- 売価金額(欠品)
*/
      l_invoice_total_rec.indv_order_qty      := l_invoice_total_rec.indv_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_indv_order_qty), 0);    -- 発注数量(バラ)
      l_invoice_total_rec.case_order_qty      := l_invoice_total_rec.case_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_order_qty), 0);    -- 発注数量(ケース)
      l_invoice_total_rec.ball_order_qty      := l_invoice_total_rec.ball_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ball_order_qty), 0);    -- 発注数量(ボール)
      l_invoice_total_rec.sum_order_qty       := l_invoice_total_rec.sum_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_sum_order_qty), 0);     -- 発注数量(合計、バラ)
      l_invoice_total_rec.indv_shipping_qty   := l_invoice_total_rec.indv_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_indv_ship_qty), 0);     -- 出荷数量(バラ)
      l_invoice_total_rec.case_shipping_qty   := l_invoice_total_rec.case_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_ship_qty), 0);     -- 出荷数量(ケース)
      l_invoice_total_rec.ball_shipping_qty   := l_invoice_total_rec.ball_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ball_ship_qty), 0);     -- 出荷数量(ボール)
      l_invoice_total_rec.pallet_shipping_qty := l_invoice_total_rec.pallet_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty), 0);   -- 出荷数量(パレット)
      l_invoice_total_rec.sum_shipping_qty    := l_invoice_total_rec.sum_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0);      -- 出荷数量(合計、バラ)
      l_invoice_total_rec.indv_stockout_qty   := l_invoice_total_rec.indv_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty), 0);   -- 欠品数量(バラ)
      l_invoice_total_rec.case_stockout_qty   := l_invoice_total_rec.case_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_stkout_qty), 0);   -- 欠品数量(ケース)
      l_invoice_total_rec.ball_stockout_qty   := l_invoice_total_rec.ball_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty), 0);   -- 欠品数量(ボール)
      l_invoice_total_rec.sum_stockout_qty    := l_invoice_total_rec.sum_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty), 0);    -- 欠品数量(合計、バラ)
      l_invoice_total_rec.case_qty            := l_invoice_total_rec.case_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_qty), 0);          -- ケース個口数
      l_invoice_total_rec.order_cost_amt      := l_invoice_total_rec.order_cost_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_order_cost_amt), 0);    -- 原価金額(発注)
      l_invoice_total_rec.shipping_cost_amt   := l_invoice_total_rec.shipping_cost_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ship_cost_amt), 0);     -- 原価金額(出荷)
      l_invoice_total_rec.stockout_cost_amt   := l_invoice_total_rec.stockout_cost_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt), 0);   -- 原価金額(欠品)
      l_invoice_total_rec.order_price_amt     := l_invoice_total_rec.order_price_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_order_price_amt), 0);   -- 売価金額(発注)
      l_invoice_total_rec.shipping_price_amt  := l_invoice_total_rec.shipping_price_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ship_price_amt), 0);    -- 売価金額(出荷)
      l_invoice_total_rec.stockout_price_amt  := l_invoice_total_rec.stockout_price_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_stkout_price_amt), 0);  -- 売価金額(欠品)
/* 2009/02/25 Ver1.4 Mod  End  */
--
      --==============================================================
      -- EDI明細情報編集
      --==============================================================
      gt_edi_line_tab(ln_loop_cnt).edi_line_info_id    := gt_edi_order_tab(ln_loop_cnt).edi_line_info_id;     -- EDI明細情報ID
      gt_edi_line_tab(ln_loop_cnt).edi_header_info_id  := gt_edi_order_tab(ln_loop_cnt).edi_header_info_id;   -- EDIヘッダ情報ID
      gt_edi_line_tab(ln_loop_cnt).line_no             := gt_data_tab(ln_data_cnt)(cv_line_no);               -- 行Ｎｏ
      gt_edi_line_tab(ln_loop_cnt).stockout_class      := gt_data_tab(ln_data_cnt)(cv_stkout_class);          -- 欠品区分
      gt_edi_line_tab(ln_loop_cnt).stockout_reason     := gt_data_tab(ln_data_cnt)(cv_stkout_reason);         -- 欠品理由
      gt_edi_line_tab(ln_loop_cnt).product_code_itouen := gt_data_tab(ln_data_cnt)(cv_prod_code_itouen);      -- 商品コード(伊藤園)
      gt_edi_line_tab(ln_loop_cnt).jan_code            := gt_data_tab(ln_data_cnt)(cv_jan_code);              -- JANコード
      gt_edi_line_tab(ln_loop_cnt).itf_code            := gt_data_tab(ln_data_cnt)(cv_itf_code);              -- ITFコード
      gt_edi_line_tab(ln_loop_cnt).prod_class          := gt_data_tab(ln_data_cnt)(cv_prod_class);            -- 商品区分
      gt_edi_line_tab(ln_loop_cnt).product_name        := gt_data_tab(ln_data_cnt)(cv_prod_name);             -- 商品名(漢字)
      gt_edi_line_tab(ln_loop_cnt).product_name2_alt   := gt_data_tab(ln_data_cnt)(cv_prod_name2_alt);        -- 商品名2(カナ)
      gt_edi_line_tab(ln_loop_cnt).item_standard2      := gt_data_tab(ln_data_cnt)(cv_item_standard2);        -- 規格2
      gt_edi_line_tab(ln_loop_cnt).num_of_cases        := gt_data_tab(ln_data_cnt)(cv_num_of_cases);          -- ケース入数
      gt_edi_line_tab(ln_loop_cnt).num_of_ball         := gt_data_tab(ln_data_cnt)(cv_num_of_ball);           -- ボール入数
      gt_edi_line_tab(ln_loop_cnt).indv_order_qty      := gt_data_tab(ln_data_cnt)(cv_indv_order_qty);        -- 発注数量(バラ)
      gt_edi_line_tab(ln_loop_cnt).case_order_qty      := gt_data_tab(ln_data_cnt)(cv_case_order_qty);        -- 発注数量(ケース)
      gt_edi_line_tab(ln_loop_cnt).ball_order_qty      := gt_data_tab(ln_data_cnt)(cv_ball_order_qty);        -- 発注数量(ボール)
      gt_edi_line_tab(ln_loop_cnt).sum_order_qty       := gt_data_tab(ln_data_cnt)(cv_sum_order_qty);         -- 発注数量(合計、バラ)
      gt_edi_line_tab(ln_loop_cnt).indv_shipping_qty   := gt_data_tab(ln_data_cnt)(cv_indv_ship_qty);         -- 出荷数量(バラ)
      gt_edi_line_tab(ln_loop_cnt).case_shipping_qty   := gt_data_tab(ln_data_cnt)(cv_case_ship_qty);         -- 出荷数量(ケース)
      gt_edi_line_tab(ln_loop_cnt).ball_shipping_qty   := gt_data_tab(ln_data_cnt)(cv_ball_ship_qty);         -- 出荷数量(ボール)
      gt_edi_line_tab(ln_loop_cnt).pallet_shipping_qty := gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty);       -- 出荷数量(パレット)
      gt_edi_line_tab(ln_loop_cnt).sum_shipping_qty    := gt_data_tab(ln_data_cnt)(cv_sum_ship_qty);          -- 出荷数量(合計、バラ)
      gt_edi_line_tab(ln_loop_cnt).indv_stockout_qty   := gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty);       -- 欠品数量(バラ)
      gt_edi_line_tab(ln_loop_cnt).case_stockout_qty   := gt_data_tab(ln_data_cnt)(cv_case_stkout_qty);       -- 欠品数量(ケース)
      gt_edi_line_tab(ln_loop_cnt).ball_stockout_qty   := gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty);       -- 欠品数量(ボール)
      gt_edi_line_tab(ln_loop_cnt).sum_stockout_qty    := gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty);        -- 欠品数量(合計、バラ)
      gt_edi_line_tab(ln_loop_cnt).shipping_unit_price := gt_data_tab(ln_data_cnt)(cv_ship_unit_price);       -- 原単価(出荷)
      gt_edi_line_tab(ln_loop_cnt).shipping_cost_amt   := gt_data_tab(ln_data_cnt)(cv_ship_cost_amt);         -- 原価金額(出荷)
      gt_edi_line_tab(ln_loop_cnt).stockout_cost_amt   := gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt);       -- 原価金額(欠品)
      gt_edi_line_tab(ln_loop_cnt).shipping_price_amt  := gt_data_tab(ln_data_cnt)(cv_ship_price_amt);        -- 売価金額(出荷)
      gt_edi_line_tab(ln_loop_cnt).stockout_price_amt  := gt_data_tab(ln_data_cnt)(cv_stkout_price_amt);      -- 売価金額(欠品)
      gt_edi_line_tab(ln_loop_cnt).general_add_item1   := gt_data_tab(ln_data_cnt)(cv_gen_add_item1);         -- 汎用付加項目1
      gt_edi_line_tab(ln_loop_cnt).general_add_item2   := gt_data_tab(ln_data_cnt)(cv_gen_add_item2);         -- 汎用付加項目2
      gt_edi_line_tab(ln_loop_cnt).general_add_item3   := gt_data_tab(ln_data_cnt)(cv_gen_add_item3);         -- 汎用付加項目3
      gt_edi_line_tab(ln_loop_cnt).item_code           := gt_data_tab(ln_data_cnt)(cv_prod_code_itouen);      -- 品目コード
    END LOOP edit_loop;
--
    --==============================================================
    -- エラーの場合
    --==============================================================
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- データ成形(A-7)
    --==============================================================
    format_data(
       iv_make_class        -- 2.作成区分
      ,l_invoice_total_rec  -- 伝票計
      ,lt_header_id         -- EDIヘッダ情報ID
      ,lt_delivery_flag     -- EDI納品予定送信済フラグ
      ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,lv_retcode           -- リターン・コード             --# 固定 #
      ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
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
  END edit_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : ファイル出力(A-8)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
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
    --==============================================================
    -- ファイル出力
    --==============================================================
    <<output_loop>>
    FOR ln_loop_cnt IN 1 .. gt_data_record_tab.COUNT LOOP
      -- データ出力
      UTL_FILE.PUT_LINE(
         file   => gt_f_handle                      -- ファイルハンドル
        ,buffer => gt_data_record_tab(ln_loop_cnt)  -- 出力文字(データ)
      );
      -- 正常処理件数カウント
      gn_normal_cnt := gn_normal_cnt + cn_1;
    END LOOP output_loop;
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : output_footer
   * Description      : ファイル終了処理(A-9)
   ***********************************************************************************/
  PROCEDURE output_footer(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_footer'; -- プログラム名
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
/* 2009/04/28 Ver1.7 Mod Start */
--    lv_footer_output  VARCHAR2(1000);  -- フッタ出力用
    lv_footer_output  VARCHAR2(5000);  -- フッタ出力用
/* 2009/04/28 Ver1.7 Mod End   */
    lv_dummy1         VARCHAR2(1);     -- IF元業務系列コード(フッタでは使用しない)
    lv_dummy2         VARCHAR2(1);     -- 拠点コード(フッタでは使用しない)
    lv_dummy3         VARCHAR2(1);     -- 拠点名称(フッタでは使用しない)
    lv_dummy4         VARCHAR2(1);     -- チェーン店コード(フッタでは使用しない)
    lv_dummy5         VARCHAR2(1);     -- チェーン店名称(フッタでは使用しない)
    lv_dummy6         VARCHAR2(1);     -- データ種コード(フッタでは使用しない)
    lv_dummy7         VARCHAR2(1);     -- 並列処理番号(フッタでは使用しない)
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
    --==============================================================
    -- 共通関数呼び出し
    --==============================================================
    -- EDIヘッダ・フッタ付与
    xxccp_ifcommon_pkg.add_edi_header_footer(
       iv_add_area        =>  gv_if_footer      -- 付与区分
      ,iv_from_series     =>  lv_dummy1         -- IF元業務系列コード
      ,iv_base_code       =>  lv_dummy2         -- 拠点コード
      ,iv_base_name       =>  lv_dummy3         -- 拠点名称
      ,iv_chain_code      =>  lv_dummy4         -- チェーン店コード
      ,iv_chain_name      =>  lv_dummy5         -- チェーン店名称
      ,iv_data_kind       =>  lv_dummy6         -- データ種コード
      ,iv_row_number      =>  lv_dummy7         -- 並列処理番号
      ,in_num_of_records  =>  gn_target_cnt     -- レコード件数
      ,ov_retcode         =>  lv_retcode        -- リターンコード
      ,ov_output          =>  lv_footer_output  -- フッタレコード
      ,ov_errbuf          =>  lv_errbuf         -- エラーメッセージ
      ,ov_errmsg          =>  lv_errmsg         -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ取得
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- アプリケーション
                     ,iv_name         => cv_msg_com_fnuc_err  -- EDI共通関数エラーメッセージ
                     ,iv_token_name1  => cv_tkn_err_msg       -- トークンコード１
                     ,iv_token_value1 => lv_errmsg            -- エラー・メッセージ
                   );
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- ファイル出力
    --==============================================================
    -- フッタ出力
    UTL_FILE.PUT_LINE(
       file   => gt_f_handle       -- ファイルハンドル
      ,buffer => lv_footer_output  -- 出力文字(フッタ)
    );
--
    --==============================================================
    -- ファイルクローズ
    --==============================================================
    UTL_FILE.FCLOSE(
       file => gt_f_handle
    );
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
  END output_footer;
--
  /**********************************************************************************
   * Procedure Name   : update_edi_order
   * Description      : EDI受注情報更新(A-10)
   ***********************************************************************************/
  PROCEDURE update_edi_order(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_edi_order'; -- プログラム名
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
    lv_tkn_value1      VARCHAR2(50);    -- トークン取得用1
    lv_tkn_value2      VARCHAR2(50);    -- トークン取得用2
    lv_err_msg         VARCHAR2(5000);  -- エラー出力用
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
    --==============================================================
    -- EDIヘッダ情報更新
    --==============================================================
    <<update_header_loop>>
    FOR ln_loop_cnt IN 1 .. gt_edi_header_tab.COUNT LOOP
      BEGIN
        UPDATE xxcos_edi_headers  xeh
        SET    xeh.process_date                = gt_edi_header_tab(ln_loop_cnt).process_date                 -- 処理日
              ,xeh.process_time                = gt_edi_header_tab(ln_loop_cnt).process_time                 -- 処理時刻
              ,xeh.base_code                   = gt_edi_header_tab(ln_loop_cnt).base_code                    -- 拠点(部門)コード
              ,xeh.base_name                   = gt_edi_header_tab(ln_loop_cnt).base_name                    -- 拠点名(正式名)
              ,xeh.base_name_alt               = gt_edi_header_tab(ln_loop_cnt).base_name_alt                -- 拠点名(カナ)
              ,xeh.customer_code               = gt_edi_header_tab(ln_loop_cnt).customer_code                -- 顧客コード
              ,xeh.customer_name               = gt_edi_header_tab(ln_loop_cnt).customer_name                -- 顧客名(漢字)
              ,xeh.customer_name_alt           = gt_edi_header_tab(ln_loop_cnt).customer_name_alt            -- 顧客名(カナ)
              ,xeh.shop_name                   = gt_edi_header_tab(ln_loop_cnt).shop_name                    -- 店名(漢字)
              ,xeh.shop_name_alt               = gt_edi_header_tab(ln_loop_cnt).shop_name_alt                -- 店名(カナ)
              ,xeh.center_delivery_date        = gt_edi_header_tab(ln_loop_cnt).center_delivery_date         -- センター納品日
              ,xeh.order_no_ebs                = gt_edi_header_tab(ln_loop_cnt).order_no_ebs                 -- 受注No(EBS)
              ,xeh.contact_to                  = gt_edi_header_tab(ln_loop_cnt).contact_to                   -- 連絡先
              ,xeh.area_code                   = gt_edi_header_tab(ln_loop_cnt).area_code                    -- 地区コード
              ,xeh.area_name                   = gt_edi_header_tab(ln_loop_cnt).area_name                    -- 地区名(漢字)
              ,xeh.area_name_alt               = gt_edi_header_tab(ln_loop_cnt).area_name_alt                -- 地区名(カナ)
              ,xeh.vendor_code                 = gt_edi_header_tab(ln_loop_cnt).vendor_code                  -- 取引先コード
              ,xeh.vendor_name                 = gt_edi_header_tab(ln_loop_cnt).vendor_name                  -- 取引先名(漢字)
              ,xeh.vendor_name1_alt            = gt_edi_header_tab(ln_loop_cnt).vendor_name1_alt             -- 取引先名1(カナ)
              ,xeh.vendor_name2_alt            = gt_edi_header_tab(ln_loop_cnt).vendor_name2_alt             -- 取引先名2(カナ)
              ,xeh.vendor_tel                  = gt_edi_header_tab(ln_loop_cnt).vendor_tel                   -- 取引先TEL
              ,xeh.vendor_charge               = gt_edi_header_tab(ln_loop_cnt).vendor_charge                -- 取引先担当者
              ,xeh.vendor_address              = gt_edi_header_tab(ln_loop_cnt).vendor_address               -- 取引先住所(漢字)
              ,xeh.delivery_schedule_time      = gt_edi_header_tab(ln_loop_cnt).delivery_schedule_time       -- 納品予定時間
              ,xeh.carrier_means               = gt_edi_header_tab(ln_loop_cnt).carrier_means                -- 運送手段
              ,xeh.eos_handwriting_class       = gt_edi_header_tab(ln_loop_cnt).eos_handwriting_class        -- EOS･手書区分
              ,xeh.invoice_indv_order_qty      = gt_edi_header_tab(ln_loop_cnt).invoice_indv_order_qty       -- (伝票計)発注数量(バラ)
              ,xeh.invoice_case_order_qty      = gt_edi_header_tab(ln_loop_cnt).invoice_case_order_qty       -- (伝票計)発注数量(ケース)
              ,xeh.invoice_ball_order_qty      = gt_edi_header_tab(ln_loop_cnt).invoice_ball_order_qty       -- (伝票計)発注数量(ボール)
              ,xeh.invoice_sum_order_qty       = gt_edi_header_tab(ln_loop_cnt).invoice_sum_order_qty        -- (伝票計)発注数量(合計、バラ)
              ,xeh.invoice_indv_shipping_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_indv_shipping_qty    -- (伝票計)出荷数量(バラ)
              ,xeh.invoice_case_shipping_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_case_shipping_qty    -- (伝票計)出荷数量(ケース)
              ,xeh.invoice_ball_shipping_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_ball_shipping_qty    -- (伝票計)出荷数量(ボール)
              ,xeh.invoice_pallet_shipping_qty = gt_edi_header_tab(ln_loop_cnt).invoice_pallet_shipping_qty  -- (伝票計)出荷数量(パレット)
              ,xeh.invoice_sum_shipping_qty    = gt_edi_header_tab(ln_loop_cnt).invoice_sum_shipping_qty     -- (伝票計)出荷数量(合計、バラ)
              ,xeh.invoice_indv_stockout_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_indv_stockout_qty    -- (伝票計)欠品数量(バラ)
              ,xeh.invoice_case_stockout_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_case_stockout_qty    -- (伝票計)欠品数量(ケース)
              ,xeh.invoice_ball_stockout_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_ball_stockout_qty    -- (伝票計)欠品数量(ボール)
              ,xeh.invoice_sum_stockout_qty    = gt_edi_header_tab(ln_loop_cnt).invoice_sum_stockout_qty     -- (伝票計)欠品数量(合計、バラ)
              ,xeh.invoice_case_qty            = gt_edi_header_tab(ln_loop_cnt).invoice_case_qty             -- (伝票計)ケース個口数
              ,xeh.invoice_fold_container_qty  = gt_edi_header_tab(ln_loop_cnt).invoice_fold_container_qty   -- (伝票計)オリコン(バラ)個口数
              ,xeh.invoice_order_cost_amt      = gt_edi_header_tab(ln_loop_cnt).invoice_order_cost_amt       -- (伝票計)原価金額(発注)
              ,xeh.invoice_shipping_cost_amt   = gt_edi_header_tab(ln_loop_cnt).invoice_shipping_cost_amt    -- (伝票計)原価金額(出荷)
              ,xeh.invoice_stockout_cost_amt   = gt_edi_header_tab(ln_loop_cnt).invoice_stockout_cost_amt    -- (伝票計)原価金額(欠品)
              ,xeh.invoice_order_price_amt     = gt_edi_header_tab(ln_loop_cnt).invoice_order_price_amt      -- (伝票計)売価金額(発注)
              ,xeh.invoice_shipping_price_amt  = gt_edi_header_tab(ln_loop_cnt).invoice_shipping_price_amt   -- (伝票計)売価金額(出荷)
              ,xeh.invoice_stockout_price_amt  = gt_edi_header_tab(ln_loop_cnt).invoice_stockout_price_amt   -- (伝票計)売価金額(欠品)
              ,xeh.edi_delivery_schedule_flag  = gt_edi_header_tab(ln_loop_cnt).edi_delivery_schedule_flag   -- EDI納品予定送信済フラグ
              ,xeh.last_updated_by             = cn_last_updated_by                                          -- 最終更新者
              ,xeh.last_update_date            = cd_last_update_date                                         -- 最終更新日
              ,xeh.last_update_login           = cn_last_update_login                                        -- 最終更新ﾛｸﾞｲﾝ
              ,xeh.request_id                  = cn_request_id                                               -- 要求ID
              ,xeh.program_application_id      = cn_program_application_id                                   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
              ,xeh.program_id                  = cn_program_id                                               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
              ,xeh.program_update_date         = cd_program_update_date                                      -- ﾌﾟﾛｸﾞﾗﾑ更新日
        WHERE  xeh.edi_header_info_id          = gt_edi_header_tab(ln_loop_cnt).edi_header_info_id           -- EDIヘッダ情報ID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- トークン取得
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application   -- アプリケーション
                             ,iv_name         => cv_msg_tkn_tbl2  -- EDIヘッダ情報テーブル
                           );
          -- メッセージ取得
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- アプリケーション
                         ,iv_name         => cv_msg_data_upd_err  -- データ更新エラーメッセージ
                         ,iv_token_name1  => cv_tkn_table_name    -- トークンコード１
                         ,iv_token_value1 => lv_tkn_value1        -- EDIヘッダ情報テーブル
                         ,iv_token_name2  => cv_tkn_key_data      -- トークンコード２
                         ,iv_token_value2 => NULL                 -- NULL
                       );
          RAISE global_api_others_expt;
      END;
    END LOOP update_header_loop;
--
    --==============================================================
    -- EDI明細情報更新
    --==============================================================
    <<update_line_loop>>
    FOR ln_loop_cnt IN 1 .. gt_edi_line_tab.COUNT LOOP
      BEGIN
        UPDATE xxcos_edi_lines  xel
        SET    xel.stockout_class          = gt_edi_line_tab(ln_loop_cnt).stockout_class       -- 欠品区分
              ,xel.stockout_reason         = gt_edi_line_tab(ln_loop_cnt).stockout_reason      -- 欠品理由
              ,xel.product_code_itouen     = gt_edi_line_tab(ln_loop_cnt).product_code_itouen  -- 商品コード(伊藤園)
              ,xel.jan_code                = gt_edi_line_tab(ln_loop_cnt).jan_code             -- JANコード
              ,xel.itf_code                = gt_edi_line_tab(ln_loop_cnt).itf_code             -- ITFコード
              ,xel.prod_class              = gt_edi_line_tab(ln_loop_cnt).prod_class           -- 商品区分
              ,xel.product_name            = gt_edi_line_tab(ln_loop_cnt).product_name         -- 商品名(漢字)
              ,xel.product_name2_alt       = gt_edi_line_tab(ln_loop_cnt).product_name2_alt    -- 商品名2(カナ)
              ,xel.item_standard2          = gt_edi_line_tab(ln_loop_cnt).item_standard2       -- 規格2
              ,xel.num_of_cases            = gt_edi_line_tab(ln_loop_cnt).num_of_cases         -- ケース入数
              ,xel.num_of_ball             = gt_edi_line_tab(ln_loop_cnt).num_of_ball          -- ボール入数
              ,xel.indv_order_qty          = gt_edi_line_tab(ln_loop_cnt).indv_order_qty       -- 発注数量(バラ)
              ,xel.case_order_qty          = gt_edi_line_tab(ln_loop_cnt).case_order_qty       -- 発注数量(ケース)
              ,xel.ball_order_qty          = gt_edi_line_tab(ln_loop_cnt).ball_order_qty       -- 発注数量(ボール)
              ,xel.sum_order_qty           = gt_edi_line_tab(ln_loop_cnt).sum_order_qty        -- 発注数量(合計、バラ)
              ,xel.indv_shipping_qty       = gt_edi_line_tab(ln_loop_cnt).indv_shipping_qty    -- 出荷数量(バラ)
              ,xel.case_shipping_qty       = gt_edi_line_tab(ln_loop_cnt).case_shipping_qty    -- 出荷数量(ケース)
              ,xel.ball_shipping_qty       = gt_edi_line_tab(ln_loop_cnt).ball_shipping_qty    -- 出荷数量(ボール)
              ,xel.pallet_shipping_qty     = gt_edi_line_tab(ln_loop_cnt).pallet_shipping_qty  -- 出荷数量(パレット)
              ,xel.sum_shipping_qty        = gt_edi_line_tab(ln_loop_cnt).sum_shipping_qty     -- 出荷数量(合計、バラ)
              ,xel.indv_stockout_qty       = gt_edi_line_tab(ln_loop_cnt).indv_stockout_qty    -- 欠品数量(バラ)
              ,xel.case_stockout_qty       = gt_edi_line_tab(ln_loop_cnt).case_stockout_qty    -- 欠品数量(ケース)
              ,xel.ball_stockout_qty       = gt_edi_line_tab(ln_loop_cnt).ball_stockout_qty    -- 欠品数量(ボール)
              ,xel.sum_stockout_qty        = gt_edi_line_tab(ln_loop_cnt).sum_stockout_qty     -- 欠品数量(合計、バラ)
              ,xel.shipping_unit_price     = gt_edi_line_tab(ln_loop_cnt).shipping_unit_price  -- 原単価(出荷)
              ,xel.shipping_cost_amt       = gt_edi_line_tab(ln_loop_cnt).shipping_cost_amt    -- 原価金額(出荷)
              ,xel.stockout_cost_amt       = gt_edi_line_tab(ln_loop_cnt).stockout_cost_amt    -- 原価金額(欠品)
              ,xel.shipping_price_amt      = gt_edi_line_tab(ln_loop_cnt).shipping_price_amt   -- 売価金額(出荷)
              ,xel.stockout_price_amt      = gt_edi_line_tab(ln_loop_cnt).stockout_price_amt   -- 売価金額(欠品)
              ,xel.general_add_item1       = gt_edi_line_tab(ln_loop_cnt).general_add_item1    -- 汎用付加項目1
              ,xel.general_add_item2       = gt_edi_line_tab(ln_loop_cnt).general_add_item2    -- 汎用付加項目2
              ,xel.general_add_item3       = gt_edi_line_tab(ln_loop_cnt).general_add_item3    -- 汎用付加項目3
              ,xel.item_code               = gt_edi_line_tab(ln_loop_cnt).item_code            -- 品目コード
              ,xel.last_updated_by         = cn_last_updated_by                                -- 最終更新者
              ,xel.last_update_date        = cd_last_update_date                               -- 最終更新日
              ,xel.last_update_login       = cn_last_update_login                              -- 最終更新ﾛｸﾞｲﾝ
              ,xel.request_id              = cn_request_id                                     -- 要求ID
              ,xel.program_application_id  = cn_program_application_id                         -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
              ,xel.program_id              = cn_program_id                                     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
              ,xel.program_update_date     = cd_program_update_date                            -- ﾌﾟﾛｸﾞﾗﾑ更新日
        WHERE  xel.edi_line_info_id        = gt_edi_line_tab(ln_loop_cnt).edi_line_info_id     -- EDI明細情報ID
        AND    xel.edi_header_info_id      = gt_edi_line_tab(ln_loop_cnt).edi_header_info_id   -- EDIヘッダ情報ID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- トークン取得
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application   -- アプリケーション
                             ,iv_name         => cv_msg_tkn_tbl3  -- EDIヘッダ情報テーブル
                           );
          -- メッセージ取得
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- アプリケーション
                         ,iv_name         => cv_msg_data_upd_err  -- データ更新エラーメッセージ
                         ,iv_token_name1  => cv_tkn_table_name    -- トークンコード１
                         ,iv_token_value1 => lv_tkn_value1        -- EDIヘッダ情報テーブル
                         ,iv_token_name2  => cv_tkn_key_data      -- トークンコード２
                         ,iv_token_value2 => NULL                 -- NULL
                       );
          RAISE global_api_others_expt;
      END;
    END LOOP update_line_loop;
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
  END update_edi_order;
--
  /**********************************************************************************
   * Procedure Name   : generate_edi_trans
   * Description      : EDI納品予定送信ファイル作成(A-3...A-10)
   ***********************************************************************************/
  PROCEDURE generate_edi_trans(
    iv_file_name        IN  VARCHAR2,     --   1.ファイル名
    iv_make_class       IN  VARCHAR2,     --   2.作成区分
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI伝送追番
    iv_edi_f_number_f   IN  VARCHAR2,     --   4.EDI伝送追番(ファイル名用)
    iv_edi_f_number_s   IN  VARCHAR2,     --   5.EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,     --   6.店舗納品日From
    iv_shop_date_to     IN  VARCHAR2,     --   7.店舗納品日To
    iv_sale_class       IN  VARCHAR2,     --   8.定番特売区分
    iv_area_code        IN  VARCHAR2,     --   9.地区コード
    iv_center_date      IN  VARCHAR2,     --  10.センター納品日
    iv_delivery_time    IN  VARCHAR2,     --  11.納品時刻
    iv_delivery_charge  IN  VARCHAR2,     --  12.納品担当者
    iv_carrier_means    IN  VARCHAR2,     --  13.輸送手段
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'generate_edi_trans'; -- プログラム名
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
    --==============================================================
    -- 手入力データ登録(A-3)
    --==============================================================
    get_manual_order(
       iv_edi_c_code       --  3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI伝送追番
      ,iv_edi_f_number_s   --  5.EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --  6.店舗納品日From
      ,iv_shop_date_to     --  7.店舗納品日To
      ,iv_sale_class       --  8.定番特売区分
      ,iv_area_code        --  9.地区コード
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ファイル初期処理(A-4)
    --==============================================================
    output_header(
       iv_file_name        --  1.ファイル名
      ,iv_edi_c_code       --  3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI伝送追番
      ,iv_edi_f_number_f   --  4.EDI伝送追番(ファイル名用)
/* 2009/05/12 Ver1.8 Mod End   */
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- EDI受注情報抽出(A-5)
    --==============================================================
    input_edi_order(
       iv_edi_c_code       --  3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI伝送追番
      ,iv_edi_f_number_s   --  5.EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --  6.店舗納品日From
      ,iv_shop_date_to     --  7.店舗納品日To
      ,iv_sale_class       --  8.定番特売区分
      ,iv_area_code        --  9.地区コード
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    IF ( gn_target_cnt <> cn_0 ) THEN
      --==============================================================
      -- データ編集(A-6)
      --==============================================================
      edit_data(
         iv_make_class       --  2.作成区分
        ,iv_center_date      --  9.センター納品日
        ,iv_delivery_time    -- 10.納品時刻
        ,iv_delivery_charge  -- 11.納品担当者
        ,iv_carrier_means    -- 12.輸送手段
        ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      -- ファイル出力(A-8)
      --==============================================================
      output_data(
         lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    --==============================================================
    -- ファイル終了処理(A-9)
    --==============================================================
    output_footer(
       lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    IF ( gn_target_cnt <> cn_0 ) THEN
    --==============================================================
    -- EDI受注情報更新(A-10)
    --==============================================================
      update_edi_order(
         lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
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
  END generate_edi_trans;
--
  /**********************************************************************************
   * Procedure Name   : release_edi_trans
   * Description      : EDI納品予定送信済み解除(A-12)
   ***********************************************************************************/
  PROCEDURE release_edi_trans(
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDIチェーン店コード
    iv_proc_date        IN  VARCHAR2,     --  13.処理日
    iv_proc_time        IN  VARCHAR2,     --  14.処理時刻
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'release_edi_trans'; -- プログラム名
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
    lv_tkn_value1  VARCHAR2(50);    -- トークン取得用1
--
/* 2009/05/12 Ver1.8 Add Start */
    -- *** ローカルTABLE型 ***
    TYPE l_header_id_ttype IS TABLE OF xxcos_edi_headers.edi_header_info_id%TYPE INDEX BY BINARY_INTEGER;
    lt_update_header_id    l_header_id_ttype;
/* 2009/05/12 Ver1.8 Add Start */
--
    -- *** ローカル・カーソル ***
    CURSOR edi_header_lock_cur
    IS
      SELECT xeh.edi_header_info_id  edi_header_info_id                              -- EDIヘッダ情報.EDIヘッダ情報ID
      FROM   xxcos_edi_headers       xeh                                             -- EDIヘッダ情報
      WHERE  TRUNC(xeh.process_date)        = TO_DATE(iv_proc_date, cv_date_format)  -- 入力パラメータの処理日
      AND    xeh.process_time               = iv_proc_time                           -- 入力パラメータの処理時刻
      AND    xeh.edi_chain_code             = iv_edi_c_code                          -- 入力パラメータのEDIチェーン店コード
      AND    xeh.edi_delivery_schedule_flag = cv_y                                   -- 送信済
      FOR UPDATE OF
             xeh.edi_header_info_id  NOWAIT
    ;
--
    -- *** ローカル・レコード ***
/* 2009/05/12 Ver1.8 Del Start */
--    lt_edi_header_lock  edi_header_lock_cur%ROWTYPE;
/* 2009/05/12 Ver1.8 Del End   */
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
    -- EDIヘッダ情報テーブルを行ロック
    OPEN  edi_header_lock_cur;
/* 2009/05/12 Ver1.8 Mod Start */
--    FETCH edi_header_lock_cur INTO lt_edi_header_lock;
    FETCH edi_header_lock_cur BULK COLLECT INTO lt_update_header_id;
    -- 抽出件数取得
/* 2010/03/01 Ver1.15 Del Start */
--    gn_target_cnt := edi_header_lock_cur%ROWCOUNT;
/* 2010/03/01 Ver1.15 Del  End  */
/* 2009/05/12 Ver1.8 Mod End */
    CLOSE edi_header_lock_cur;
/* 2010/03/01 Ver1.15 Add Start */
    SELECT COUNT(1)                                                                 -- 明細件数
    INTO   gn_target_cnt                                                            -- 対象件数
    FROM   xxcos_edi_lines  xel                                                     -- EDI明細情報テーブル
    WHERE  xel.edi_header_info_id IN (
                                       SELECT xeh.edi_header_info_id  edi_header_info_id                              -- EDIヘッダ情報.EDIヘッダ情報ID
                                       FROM   xxcos_edi_headers       xeh                                             -- EDIヘッダ情報
                                       WHERE  TRUNC(xeh.process_date)        = TO_DATE(iv_proc_date, cv_date_format)  -- 入力パラメータの処理日
                                       AND    xeh.process_time               = iv_proc_time                           -- 入力パラメータの処理時刻
                                       AND    xeh.edi_chain_code             = iv_edi_c_code                          -- 入力パラメータのEDIチェーン店コード
                                       AND    xeh.edi_delivery_schedule_flag = cv_y                                   -- 送信済
                                     );                                              -- EDIヘッダ情報ID = ロックを取得したEDIヘッダ情報ID
/* 2010/03/01 Ver1.15 Add  End  */
--
    -- EDIヘッダ情報テーブルを更新
    BEGIN
      UPDATE xxcos_edi_headers  xeh                                                  -- EDIヘッダ情報
      SET    xeh.edi_delivery_schedule_flag = cv_n                                   -- EDI納品予定送信済フラグ
            ,xeh.last_updated_by            = cn_last_updated_by                     -- 最終更新者
            ,xeh.last_update_date           = cd_last_update_date                    -- 最終更新日
            ,xeh.last_update_login          = cn_last_update_login                   -- 最終更新ﾛｸﾞｲﾝ
            ,xeh.request_id                 = cn_request_id                          -- 要求ID
            ,xeh.program_application_id     = cn_program_application_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
            ,xeh.program_id                 = cn_program_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
            ,xeh.program_update_date        = cd_program_update_date                 -- ﾌﾟﾛｸﾞﾗﾑ更新日
      WHERE  TRUNC(xeh.process_date)        = TO_DATE(iv_proc_date, cv_date_format)  -- 入力パラメータの処理日
      AND    xeh.process_time               = iv_proc_time                           -- 入力パラメータの処理時刻
      AND    xeh.edi_chain_code             = iv_edi_c_code                          -- 入力パラメータのEDIチェーン店コード
      AND    xeh.edi_delivery_schedule_flag = cv_y                                   -- 送信済
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- トークン取得
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- アプリケーション
                           ,iv_name         => cv_msg_tkn_tbl2  -- EDIヘッダ情報テーブル
                         );
        -- メッセージ取得
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- アプリケーション
                       ,iv_name         => cv_msg_data_upd_err  -- データ更新エラーメッセージ
                       ,iv_token_name1  => cv_tkn_table_name    -- トークンコード１
                       ,iv_token_value1 => lv_tkn_value1        -- EDIヘッダ情報テーブル
                       ,iv_token_name2  => cv_tkn_key_data      -- トークンコード２
                       ,iv_token_value2 => iv_edi_c_code        -- 入力パラメータのEDIチェーン店コード
                     );
        RAISE global_api_others_expt;
    END;
--
/* 2009/05/12 Ver1.8 Add Start */
    -- 正常件数取得
    gn_normal_cnt := gn_target_cnt;
/* 2009/05/12 Ver1.8 Add End */
--
  EXCEPTION
    -- *** ロックエラー ***
    WHEN lock_expt THEN
      -- カーソルクローズ
      IF ( edi_header_lock_cur%ISOPEN ) THEN
        CLOSE edi_header_lock_cur;
      END IF;
      -- トークン取得
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- アプリケーション
                         ,iv_name         => cv_msg_tkn_tbl2  -- EDIヘッダ情報テーブル
                       );
      -- メッセージ取得
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     -- アプリケーション
                     ,iv_name         => cv_msg_lock_err    -- ロックエラーメッセージ
                     ,iv_token_name1  => cv_tkn_table       -- トークンコード１
                     ,iv_token_value1 => lv_tkn_value1      -- EDIヘッダ情報テーブル
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
  END release_edi_trans;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name        IN  VARCHAR2,     --   1.ファイル名
    iv_make_class       IN  VARCHAR2,     --   2.作成区分
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI伝送追番
    iv_edi_f_number_f   IN  VARCHAR2,     --   4.EDI伝送追番(ファイル名用)
    iv_edi_f_number_s   IN  VARCHAR2,     --   5.EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,     --   6.店舗納品日From
    iv_shop_date_to     IN  VARCHAR2,     --   7.店舗納品日To
    iv_sale_class       IN  VARCHAR2,     --   8.定番特売区分
    iv_area_code        IN  VARCHAR2,     --   9.地区コード
    iv_center_date      IN  VARCHAR2,     --  10.センター納品日
    iv_delivery_time    IN  VARCHAR2,     --  11.納品時刻
    iv_delivery_charge  IN  VARCHAR2,     --  12.納品担当者
    iv_carrier_means    IN  VARCHAR2,     --  13.輸送手段
    iv_proc_date        IN  VARCHAR2,     --  14.処理日
    iv_proc_time        IN  VARCHAR2,     --  15.処理時刻
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- パラメータチェック(A-1)
    -- ===============================
    check_param(
       iv_file_name        --  1.ファイル名
      ,iv_make_class       --  2.作成区分
      ,iv_edi_c_code       --  3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI伝送追番
      ,iv_edi_f_number_f   --  4.EDI伝送追番(ファイル名用)
      ,iv_edi_f_number_s   --  5.EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --  6.店舗納品日From
      ,iv_shop_date_to     --  7.店舗納品日To
      ,iv_sale_class       --  8.定番特売区分
      ,iv_area_code        --  9.地区コード
      ,iv_center_date      -- 10.センター納品日
      ,iv_delivery_time    -- 11.納品時刻
      ,iv_delivery_charge  -- 12.納品担当者
      ,iv_carrier_means    -- 13.輸送手段
      ,iv_proc_date        -- 14.処理日
      ,iv_proc_time        -- 15.処理時刻
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 初期処理(A-2)
    -- ===============================
    init(
       iv_make_class       --  2.作成区分
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 「作成区分」が、'送信'か'ラベル作成'の場合
    IF ( iv_make_class = cv_make_class_transe )
    OR ( iv_make_class = cv_make_class_label )
    THEN
      -- ===============================
      -- EDI納品予定送信ファイル作成(A-3...A-10)
      -- ===============================
      generate_edi_trans(
         iv_file_name        --  1.ファイル名
        ,iv_make_class       --  2.作成区分
        ,iv_edi_c_code       --  3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--        ,iv_edi_f_number     --  4.EDI伝送追番
        ,iv_edi_f_number_f   --  4.EDI伝送追番(ファイル名用)
        ,iv_edi_f_number_s   --  5.EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Mod End   */
        ,iv_shop_date_from   --  6.店舗納品日From
        ,iv_shop_date_to     --  7.店舗納品日To
        ,iv_sale_class       --  8.定番特売区分
        ,iv_area_code        --  9.地区コード
        ,iv_center_date      -- 10.センター納品日
        ,iv_delivery_time    -- 11.納品時刻
        ,iv_delivery_charge  -- 12.納品担当者
        ,iv_carrier_means    -- 13.輸送手段
        ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- ファイルがOPENされている場合クローズ
        IF ( UTL_FILE.IS_OPEN( file => gt_f_handle )) THEN
          UTL_FILE.FCLOSE( file => gt_f_handle );
        END IF;
        RAISE global_process_expt;
      END IF;
--
    -- 「作成区分」が、'解除'の場合
    ELSIF ( iv_make_class = cv_make_class_release ) THEN
      -- ===============================
      -- EDI納品予定送信済み解除(A-12)
      -- ===============================
      release_edi_trans(
         iv_edi_c_code       --  3.EDIチェーン店コード
        ,iv_proc_date        -- 13.処理日
        ,iv_proc_time        -- 14.処理時刻
        ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
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
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_file_name        IN  VARCHAR2,      --   1.ファイル名
    iv_make_class       IN  VARCHAR2,      --   2.作成区分
    iv_edi_c_code       IN  VARCHAR2,      --   3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,      --   4.EDI伝送追番
    iv_edi_f_number_f   IN  VARCHAR2,      --   4.EDI伝送追番(ファイル名用)
    iv_edi_f_number_s   IN  VARCHAR2,      --   5.EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,      --   6.店舗納品日From
    iv_shop_date_to     IN  VARCHAR2,      --   7.店舗納品日To
    iv_sale_class       IN  VARCHAR2,      --   8.定番特売区分
    iv_area_code        IN  VARCHAR2,      --   9.地区コード
    iv_center_date      IN  VARCHAR2,      --  10.センター納品日
    iv_delivery_time    IN  VARCHAR2,      --  11.納品時刻
    iv_delivery_charge  IN  VARCHAR2,      --  12.納品担当者
    iv_carrier_means    IN  VARCHAR2,      --  13.輸送手段
    iv_proc_date        IN  VARCHAR2,      --  14.処理日
    iv_proc_time        IN  VARCHAR2       --  15.処理時刻
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
       iv_file_name        --   1.ファイル名
      ,iv_make_class       --   2.作成区分
      ,iv_edi_c_code       --   3.EDIチェーン店コード
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --   4.EDI伝送追番
      ,iv_edi_f_number_f   --   4.EDI伝送追番(ファイル名用)
      ,iv_edi_f_number_s   --   5.EDI伝送追番(抽出条件用)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --   6.店舗納品日From
      ,iv_shop_date_to     --   7.店舗納品日To
      ,iv_sale_class       --   8.定番特売区分
      ,iv_area_code        --   9.地区コード
      ,iv_center_date      --  10.センター納品日
      ,iv_delivery_time    --  11.納品時刻
      ,iv_delivery_charge  --  12.納品担当者
      ,iv_carrier_means    --  13.輸送手段
      ,iv_proc_date        --  14.処理日
      ,iv_proc_time        --  15.処理時刻
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
/* 2009/02/24 Ver1.2 Mod Start */
      IF (lv_errmsg IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
--  END IF;
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
/* 2009/02/24 Ver1.2 Mod  End  */
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
/* 2009/02/24 Ver1.2 Add Start */
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
/* 2009/02/24 Ver1.2 Add  End  */
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
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
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
END XXCOS011A03C;
/
