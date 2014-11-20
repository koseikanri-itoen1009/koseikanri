CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A06C (body)
 * Description      : 販売実績ヘッダデータ、販売実績明細データを取得して、販売実績データファイルを
 *                    作成する。
 * MD.050           : 販売実績データ作成（MD050_COS_011_A06）
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  input_param_check      入力パラメータチェック処理(A-1)
 *  get_custom_data        処理対象顧客取得処理(A-2)
 *  init                   初期処理(A-3)
 *  output_header          ファイル初期処理(A-4)
 *  get_sale_data          販売実績情報抽出(A-5)
 *  edit_sale_data         データ編集(A-6,A-7)
 *  output_footer          ファイル終了処理(A-8)
 *  upd_sale_exp_head_send 販売実績ヘッダTBLフラグ更新（作成）(A-9)
 *  upd_sale_exp_head_rep  販売実績ヘッダTBLフラグ更新（解除）(A-11)
 *  upd_no_target          販売実績抽出対象外更新(A-12)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   K.Watanabe      新規作成
 *  2009/03/10    1.1   K.Kiriu         [COS_157]請求開始日NULL考慮の修正、届け先住所不正修正
 *  2009/04/15    1.2   K.Kiriu         [T1_0495]JP1起動の為パラメータの追加
 *  2009/04/28    1.3   K.Kiriu         [T1_0756]レコード長変更対応
 *  2009/05/28    1.4   T.Tominaga      [T1_0540]販売実績の対象データ取得カーソルのORDER BY句の変更
 *                                               ファイル出力の行Ｎｏのセット値を連番に変更
 *  2009/06/12    1.5   N.Maeda         [T1_1356]ファイルNo出力項目修正
 *  2009/06/25    1.5   M.Sano          [T1_1359]数量換算対応
 *  2009/07/07    1.5   N.Maeda         [T1_1356]レビュー指摘対応
 *  2009/07/13    1.5   N.Maeda         [T1_1359]レビュー指摘対応
 *  2009/07/29    1.5   K.Kiriu         [T1_1359]レビュー指摘対応
 *  2009/09/03    1.6   N.Maeda         [0001199]販売実績明細の排他制御削除
 *  2009/11/05    1.7   M.Sano          [E_T4_00088]伝票区分の算出方法変更
 *                                      [E_T4_00142]顧客使用目的（請求先）のセット項目修正
 *  2009/11/24    1.8   K.Atsushiba     [E_本番_00348]PT対応
 *  2009/11/27    1.9   K.Kiriu         [E_本番_00114]相手先発注番号設定対応
 *  2010/03/16    1.10  K.Kiriu         [E_本稼動_01153]EDI販売実績対象顧客追加時の対応
 *                                      [E_本稼動_01301]PT対応(対象外データの更新追加）
 *                                                      顧客マスタモデルの対応
 *  2010/06/22    1.11  S.Arizumi       [E_本稼動_02995] 菱食EDI販売実績のオーダーNo.（注文伝票番号）不具合対応
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
  -- 日付
  cd_sysdate                CONSTANT DATE        := SYSDATE;                            -- システム日付
  cd_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date; -- 業務処理日
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
  global_data_check_expt    EXCEPTION;     -- initチェック時のエラー
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  --ロックエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOS011A06C'; -- パッケージ名
--
  cv_application        CONSTANT VARCHAR2(10)  := 'XXCOS';        -- アプリケーション名
  -- プロファイル
  cv_prf_if_header      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_HEADER';             -- XXCCP:IFレコード区分_ヘッダ
  cv_prf_if_data        CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_DATA';               -- XXCCP:IFレコード区分_データ
  cv_prf_if_footer      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_FOOTER';             -- XXCCP:IFレコード区分_フッタ
  cv_prf_utl_m_line     CONSTANT VARCHAR2(50)  := 'XXCOS1_UTL_MAX_LINESIZE';      -- XXCOS:UTL_MAX行サイズ
  cv_prf_outbound_d     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_OUTBOUND_OM_DIR';   -- XXCOS:EDI%ディレクトリパス(名称略)
  cv_prf_dept_code      CONSTANT VARCHAR2(50)  := 'XXCOS1_BIZ_MAN_DEPT_CODE';     -- XXCOS:業務管理部コード
  cv_prf_orga_code1     CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';     -- XXCOI:在庫組織コード
  cv_prf_def_item_rate  CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_DEFAULT_ITEM_RATE'; -- XXCOS:EDIデフォルト歩率
  cv_prf_org_id         CONSTANT VARCHAR2(50)  := 'ORG_ID';                       -- MO:営業単位
/* 2010/03/16 Ver1.10 Add Start */
  cv_prf_max_date       CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';              -- XXCOS:MAX日付
  cv_prf_min_date       CONSTANT VARCHAR2(50)  := 'XXCOS1_MIN_DATE';              -- XXCOS:MIN日付
  cv_prf_trg_hold_m     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_TARGET_HOLD_MONTH'; -- XXCOS:EDI販売実績対象保持月数
/* 2010/03/16 Ver1.10 Add End   */
  -- メッセージコード
  cv_msg_param_create   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12368';  -- パラメーター出力(作成)
  cv_msg_param_cancel   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12352';  -- パラメーター出力(解除)
  cv_msg_file_name      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00044';  -- ファイル名出力
  cv_msg_lock_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ロックエラー
  cv_msg_date_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00171';  -- 日付書式エラー
  cv_msg_no_target_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- 対象データなしエラー
  cv_msg_prf_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- プロファイル取得エラー
  cv_msg_param_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';  -- 必須入力パラメータ未設定エラー
  cv_msg_file_o_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00009';  -- ファイルオープンエラー
  cv_msg_data_get_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';  -- データ抽出エラー
  cv_msg_in_param_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00019';  -- 入力パラメータ不正エラーメッセージ
  cv_msg_base_code_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00035';  -- 拠点情報取得エラー
  cv_msg_edi_c_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00036';  -- EDIチェーン店情報取得エラー
  cv_msg_proc_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00037';  -- 共通関数エラー
  cv_msg_out_inf_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00038';  -- 出力情報編集エラー
  cv_msg_file_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00040';  -- IFファイルレイアウト定義情報取得エラー
  gv_msg_orga_id_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00091';  -- 在庫組織ID取得エラーメッセージ
  cv_msg_mst_chk_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';  -- マスタチェックエラー
  cv_msg_upd_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';  -- データ更新エラー
  cv_msg_edi_m_class_c  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12308';  -- クイックコード取得条件(EDI媒体区分)
  cv_msg_sales_class_c  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12369';  -- クイックコード取得条件(売上区分)
  cv_msg_prf_if_h       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00104';  -- XXCCP:IFレコード区分_ヘッダ(文言)
  cv_msg_prf_if_d       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00105';  -- XXCCP:IFレコード区分_データ(文言)
  cv_msg_prf_if_f       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00106';  -- XXCCP:IFレコード区分_フッタ(文言)
  cv_msg_prf_utl_m      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00107';  -- XXCOS:UTL_MAX行サイズ(文言)
  cv_msg_prf_out_d      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00145';  -- XXCOS:受注系アウトバウンド用ディレクトリパス(文言)
  cv_msg_prf_dept_c     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12358';  -- XXCOS:業務管理部コード(文言)
  cv_msg_prf_edi_r      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12359';  -- XXCOS:EDIデフォルト歩率(文言)
  cv_msg_orga_code      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12360';  -- XXCOI:在庫組織コード(文言)
  cv_msg_org_id         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';  -- MO:営業単位
  cv_msg_table_tkn1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';  -- クイックコード(文言)
  cv_msg_table_tkn2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12364';  -- 販売実績ヘッダテーブル(文言)
  cv_msg_sales_class    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10046';  -- 売上区分（文言）
  cv_msg_create         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12353';  -- 作成(文言)
  cv_msg_cancel         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12354';  -- 解除(文言)
  cv_msg_bill_account   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12355';  -- 請求先顧客コード(文言)
  cv_msg_send_date      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12356';  -- 送信日(文言)
  cv_msg_run_class      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12357';  -- 実行区分(文言)
  cv_msg_data_type_c    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12362';  -- データ種コード(文言)
  cv_msg_edi_m_class_n  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00110';  -- EDI媒体区分(文言)
  cv_msg_in_file_name   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00109';  -- ファイル名(文言)
  cv_msg_layout         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12367';  -- レイアウト定義情報(文言)
/* 2010/03/16 Ver1.10 Add Start */
  cv_msg_prf_min_d      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00120';  -- XXCOS:MIN日付(文言)
  cv_msg_prf_max_d      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';  -- XXCOS:MAX日付(文言)
  cv_msg_prf_hold_m     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12370';  -- XXCOS:EDI販売実績対象保持月数(文言)
  cv_msg_param_update   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12371';  -- パラメーター出力(対象外更新)
/* 2010/03/16 Ver1.10 Add End   */
  -- トークンコード
  cv_tkn_parame1        CONSTANT VARCHAR2(20)  := 'PARAME1';           -- パラメーター１
  cv_tkn_parame2        CONSTANT VARCHAR2(20)  := 'PARAME2';           -- パラメーター２
  cv_tkn_parame3        CONSTANT VARCHAR2(20)  := 'PARAME3';           -- パラメーター３
  cv_tkn_para_d         CONSTANT VARCHAR2(20)  := 'PARA_DATE';         -- パラメーター日付
  cv_tkn_in_param       CONSTANT VARCHAR2(20)  := 'IN_PARAM';          -- パラメータ名称
  cv_tkn_prf            CONSTANT VARCHAR2(20)  := 'PROFILE';           -- プロファイル名称
  cv_tkn_chain_s        CONSTANT VARCHAR2(20)  := 'CHAIN_SHOP_CODE';   -- チェーン店
  cv_tkn_err_m          CONSTANT VARCHAR2(20)  := 'ERRMSG';            -- エラーメッセージ名
  cv_tkn_column         CONSTANT VARCHAR2(20)  := 'COLMUN';            -- カラム名
  cv_tkn_table          CONSTANT VARCHAR2(20)  := 'TABLE';             -- テーブル名
  cv_tkn_file_n         CONSTANT VARCHAR2(20)  := 'FILE_NAME';         -- ファイル名
  cv_tkn_file_l         CONSTANT VARCHAR2(20)  := 'LAYOUT';            -- ファイルレイアウト情報
  cv_tkn_table_n        CONSTANT VARCHAR2(20)  := 'TABLE_NAME';        -- テーブル名
  cv_tkn_key            CONSTANT VARCHAR2(20)  := 'KEY_DATA';          -- キーデータ
  cv_base_code1         CONSTANT VARCHAR2(20)  := 'CODE';              -- 拠点情報取得
  cv_tkn_org_code       CONSTANT VARCHAR2(50)  := 'ORG_CODE_TOK';      -- 在庫組織コード（在庫組織ID）
  cv_tkn_profile        CONSTANT VARCHAR2(50)  := 'PROFILE';           --プロファイル
--
  -- 顧客マスタ取得用固定値
  cv_cust_code_chain    CONSTANT VARCHAR2(2)   := '18';                -- 顧客区分(チェーン店)
  cv_status_a           CONSTANT VARCHAR2(1)   := 'A';                 -- ステータス
  cv_cust_site_use_code CONSTANT VARCHAR2(10)  := 'SHIP_TO';           -- 顧客使用目的：出荷先
/* 2009/11/05 Ver1.7 Add Start */
  cv_bill_to            CONSTANT VARCHAR2(10)  := 'BILL_TO';           -- 顧客使用目的：請求先
/* 2009/11/05 Ver1.7 Add End   */
  -- クイックコードタイプ
  cv_lkt_edi_s_exe_type CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_SALES_EXP_EXE_TYPE'; --EDI販売実績作成実行区分
  cv_lkt_sales_edi_cust CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_SALES_EXP_CUST';     --請求先顧客コード
  cv_lkt_ship_to_pb     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_PB_CHAIN_SHOP';      --納品先チェーンコードPB
  cv_lkt_ship_to_nb     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_NB_CHAIN_SHOP';      --納品先チェーンコードNB
  cv_lkt_pb_item        CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_PB_ITEM';            --PB商品コード
  cv_lkt_edi_filename   CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_SALES_EXP_FILENAME'; --EDI販売実績ファイル名
  cv_lkt_edi_m_class    CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_MEDIA_CLASS';        --EDI媒体区分
  cv_lkt_data_type_code CONSTANT VARCHAR2(50)  := 'XXCOS1_DATA_TYPE_CODE';         --データ種
  cv_lkt_edi_sale_class CONSTANT VARCHAR2(50)  := 'XXCOS1_SALE_CLASS';             --売上区分
  cv_lkt_no_inv_item    CONSTANT VARCHAR2(50)  := 'XXCOS1_NO_INV_ITEM_CODE';       --非在庫品目コード
  -- クイックコード値
  cv_lkc_data_type_code CONSTANT VARCHAR2(3)   := '180';                     --販売実績
  -- その他固定値
  cv_date_format        CONSTANT VARCHAR2(10)  := 'YYYYMMDD';          -- 日付フォーマット(年月日)
  cv_d_format_yyyymm    CONSTANT VARCHAR2(10)  := 'YYYYMM';            -- 日付フォーマット(月)
/* 2010/03/16 Ver1.10 Add Start */
  cv_date_format_sl     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        -- 日付フォーマット(年月日スラッシュ付き)
  cv_d_format_mm        CONSTANT VARCHAR2(10)  := 'MM';                -- TRUNC用日付フォーマット(月)
/* 2010/03/16 Ver1.10 Add End   */
  cv_d_format_dd        CONSTANT VARCHAR2(10)  := 'DD';                -- 日付フォーマット(日)
  cv_time_format        CONSTANT VARCHAR2(10)  := 'HH24MISS';          -- 日付フォーマット(時間)
  cn_0                  CONSTANT NUMBER        := 0;                   -- 固定値:0(NUMBER)
  cn_1                  CONSTANT NUMBER        := 1;                   -- 固定値:1(NUMBER)
  cn_2                  CONSTANT NUMBER        := 2;                   -- 固定値:2(NUMBER)
  cn_4                  CONSTANT NUMBER        := 4;                   -- 固定値:4(NUMBER)
  cn_5                  CONSTANT NUMBER        := 5;                   -- 固定値:5(NUMBER)
  cn_8                  CONSTANT NUMBER        := 8;                   -- 固定値:8(NUMBER)
  cn_9                  CONSTANT NUMBER        := 9;                   -- 固定値:9(NUMBER)
  cn_15                 CONSTANT NUMBER        := 15;                  -- 固定値:15(NUMBER)
  cn_16                 CONSTANT NUMBER        := 16;                  -- 固定値:16(NUMBER)
  cn_32                 CONSTANT NUMBER        := 32;                  -- 固定値:32(NUMBER)
  cv_0                  CONSTANT VARCHAR2(1)   := '0';                 -- 固定値:0(VARCHAR2)
  cv_1                  CONSTANT VARCHAR2(1)   := '1';                 -- 固定値:1(VARCHAR2)
  cv_2                  CONSTANT VARCHAR2(1)   := '2';                 -- 固定値:2(VARCHAR2)
  cv_3                  CONSTANT VARCHAR2(1)   := '3';                 -- 固定値:3(VARCHAR2)
  cv_4                  CONSTANT VARCHAR2(1)   := '4';                 -- 固定値:4(VARCHAR2)
  cv_5                  CONSTANT VARCHAR2(1)   := '5';                 -- 固定値:5(VARCHAR2)
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                 -- 固定値:Y
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';                 -- 固定値:N
  cv_w                  CONSTANT VARCHAR2(1)   := 'W';                 -- 固定値:W
  cv_0000               CONSTANT VARCHAR2(4)   := '0000';              -- 倉直区分判定用
/* 2010/03/16 Ver1.10 Add Start */
  cv_s                  CONSTANT VARCHAR2(1)   := 'S';                 -- 固定値:S
  gv_run_class_cd_create CONSTANT VARCHAR2(1)  := '0';                 -- 実行区分：「作成」コード
  gv_run_class_cd_cancel CONSTANT VARCHAR2(1)  := '1';                 -- 実行区分：「解除」コード
  gv_run_class_cd_update CONSTANT VARCHAR2(1)  := '2';                 -- 実行区分：「対象外更新」コード
/* 2010/03/16 Ver1.10 Add End   */
  -- データ成型共通関数用
  cv_medium_class             CONSTANT VARCHAR2(50)  := 'MEDIUM_CLASS';                  --媒体区分
  cv_data_type_code           CONSTANT VARCHAR2(50)  := 'DATA_TYPE_CODE';                --データ種コード
  cv_file_no                  CONSTANT VARCHAR2(50)  := 'FILE_NO';                       --ファイルNo
  cv_info_class               CONSTANT VARCHAR2(50)  := 'INFO_CLASS';                    --情報区分
  cv_process_date             CONSTANT VARCHAR2(50)  := 'PROCESS_DATE';                  --処理日
  cv_process_time             CONSTANT VARCHAR2(50)  := 'PROCESS_TIME';                  --処理時刻
  cv_base_code                CONSTANT VARCHAR2(50)  := 'BASE_CODE';                     --拠点(部門)コード
  cv_base_name                CONSTANT VARCHAR2(50)  := 'BASE_NAME';                     --拠点名(正式名)
  cv_base_name_alt            CONSTANT VARCHAR2(50)  := 'BASE_NAME_ALT';                 --拠点名(カナ)
  cv_edi_chain_code           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_CODE';                --EDIチェーン店コード
  cv_edi_chain_name           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME';                --EDIチェーン店名(漢字)
  cv_edi_chain_name_alt       CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME_ALT';            --EDIチェーン店名(カナ)
  cv_chain_code               CONSTANT VARCHAR2(50)  := 'CHAIN_CODE';                    --チェーン店コード
  cv_chain_name               CONSTANT VARCHAR2(50)  := 'CHAIN_NAME';                    --チェーン店名(漢字)
  cv_chain_name_alt           CONSTANT VARCHAR2(50)  := 'CHAIN_NAME_ALT';                --チェーン店名(カナ)
  cv_report_code              CONSTANT VARCHAR2(50)  := 'REPORT_CODE';                   --帳票コード
  cv_report_show_name         CONSTANT VARCHAR2(50)  := 'REPORT_SHOW_NAME';              --帳票表示名
  cv_cust_code                CONSTANT VARCHAR2(50)  := 'CUSTOMER_CODE';                 --顧客コード
  cv_cust_name                CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME';                 --顧客名(漢字)
  cv_cust_name_alt            CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME_ALT';             --顧客名(カナ)
  cv_comp_code                CONSTANT VARCHAR2(50)  := 'COMPANY_CODE';                  --社コード
  cv_comp_name                CONSTANT VARCHAR2(50)  := 'COMPANY_NAME';                  --社名(漢字)
  cv_comp_name_alt            CONSTANT VARCHAR2(50)  := 'COMPANY_NAME_ALT';              --社名(カナ)
  cv_shop_code                CONSTANT VARCHAR2(50)  := 'SHOP_CODE';                     --店コード
  cv_shop_name                CONSTANT VARCHAR2(50)  := 'SHOP_NAME';                     --店名(漢字)
  cv_shop_name_alt            CONSTANT VARCHAR2(50)  := 'SHOP_NAME_ALT';                 --店名(カナ)
  cv_delv_cent_code           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_CODE';          --納入センターコード
  cv_delv_cent_name           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME';          --納入センター名(漢字)
  cv_delv_cent_name_alt       CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME_ALT';      --納入先センター名(カナ)
  cv_order_date               CONSTANT VARCHAR2(50)  := 'ORDER_DATE';                    --発注日
  cv_cent_delv_date           CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_DATE';          --センター納品日
  cv_result_delv_date         CONSTANT VARCHAR2(50)  := 'RESULT_DELIVERY_DATE';          --実納品日
  cv_shop_delv_date           CONSTANT VARCHAR2(50)  := 'SHOP_DELIVERY_DATE';            --店舗納品日
  cv_dc_date_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_DATE_EDI_DATA';   --データ作成日(EDIデータ中)
  cv_dc_time_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_TIME_EDI_DATA';   --データ作成時刻(EDIデータ中)
  cv_invc_class               CONSTANT VARCHAR2(50)  := 'INVOICE_CLASS';                 --伝票区分
  cv_small_classif_code       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_CODE';     --小分類コード
  cv_small_classif_name       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_NAME';     --小分類名
  cv_middle_classif_code      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_CODE';    --中分類コード
  cv_middle_classif_name      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_NAME';    --中分類名
  cv_big_classif_code         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_CODE';       --大分類コード
  cv_big_classif_name         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_NAME';       --大分類名
  cv_op_department_code       CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_DEPARTMENT_CODE';   --相手先部門コード
  cv_op_order_number          CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_ORDER_NUMBER';      --相手先発注番号
  cv_check_digit_class        CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT_CLASS';             --チェックデジット有無区分
  cv_invc_number              CONSTANT VARCHAR2(50)  := 'INVOICE_NUMBER';                --伝票番号
  cv_check_digit              CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT';                   --チェックデジット
  cv_close_date               CONSTANT VARCHAR2(50)  := 'CLOSE_DATE';                    --月限
  cv_order_no_ebs             CONSTANT VARCHAR2(50)  := 'ORDER_NO_EBS';                  --受注No(EBS)
  cv_ar_sale_class            CONSTANT VARCHAR2(50)  := 'AR_SALE_CLASS';                 --特売区分
  cv_delv_classe              CONSTANT VARCHAR2(50)  := 'DELIVERY_CLASSE';               --配送区分
  cv_opportunity_no           CONSTANT VARCHAR2(50)  := 'OPPORTUNITY_NO';                --便No
  cv_contact_to               CONSTANT VARCHAR2(50)  := 'CONTACT_TO';                    --連絡先
  cv_route_sales              CONSTANT VARCHAR2(50)  := 'ROUTE_SALES';                   --ルートセールス
  cv_corporate_code           CONSTANT VARCHAR2(50)  := 'CORPORATE_CODE';                --法人コード
  cv_maker_name               CONSTANT VARCHAR2(50)  := 'MAKER_NAME';                    --メーカー名
  cv_area_code                CONSTANT VARCHAR2(50)  := 'AREA_CODE';                     --地区コード
  cv_area_name                CONSTANT VARCHAR2(50)  := 'AREA_NAME';                     --地区名(漢字)
  cv_area_name_alt            CONSTANT VARCHAR2(50)  := 'AREA_NAME_ALT';                 --地区名(カナ)
  cv_vendor_code              CONSTANT VARCHAR2(50)  := 'VENDOR_CODE';                   --取引先コード
  cv_vendor_name              CONSTANT VARCHAR2(50)  := 'VENDOR_NAME';                   --取引先名(漢字)
  cv_vendor_name1_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME1_ALT';              --取引先名1(カナ)
  cv_vendor_name2_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME2_ALT';              --取引先名2(カナ)
  cv_vendor_tel               CONSTANT VARCHAR2(50)  := 'VENDOR_TEL';                    --取引先TEL
  cv_vendor_charge            CONSTANT VARCHAR2(50)  := 'VENDOR_CHARGE';                 --取引先担当者
  cv_vendor_address           CONSTANT VARCHAR2(50)  := 'VENDOR_ADDRESS';                --取引先住所(漢字)
  cv_delv_to_code_itouen      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_ITOUEN';        --届け先コード(伊藤園)
  cv_delv_to_code_chain       CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_CHAIN';         --届け先コード(チェーン店)
  cv_delv_to                  CONSTANT VARCHAR2(50)  := 'DELIVER_TO';                    --届け先(漢字)
  cv_delv_to1_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO1_ALT';               --届け先1(カナ)
  cv_delv_to2_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO2_ALT';               --届け先2(カナ)
  cv_delv_to_address          CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS';            --届け先住所(漢字)
  cv_delv_to_address_alt      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS_ALT';        --届け先住所(カナ)
  cv_delv_to_tel              CONSTANT VARCHAR2(50)  := 'DELIVER_TO_TEL';                --届け先TEL
  cv_bal_acc_code             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_CODE';         --帳合先コード
  cv_bal_acc_comp_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_COMPANY_CODE'; --帳合先社コード
  cv_bal_acc_shop_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_SHOP_CODE';    --帳合先店コード
  cv_bal_acc_name             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME';         --帳合先名(漢字)
  cv_bal_acc_name_alt         CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME_ALT';     --帳合先名(カナ)
  cv_bal_acc_address          CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS';      --帳合先住所(漢字)
  cv_bal_acc_address_alt      CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS_ALT';  --帳合先住所(カナ)
  cv_bal_acc_tel              CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_TEL';          --帳合先TEL
  cv_order_possible_date      CONSTANT VARCHAR2(50)  := 'ORDER_POSSIBLE_DATE';           --受注可能日
  cv_perm_possible_date       CONSTANT VARCHAR2(50)  := 'PERMISSION_POSSIBLE_DATE';      --許容可能日
  cv_forward_month            CONSTANT VARCHAR2(50)  := 'FORWARD_MONTH';                 --先限年月日
  cv_payment_settlement_date  CONSTANT VARCHAR2(50)  := 'PAYMENT_SETTLEMENT_DATE';       --支払決済日
  cv_handbill_start_date_act  CONSTANT VARCHAR2(50)  := 'HANDBILL_START_DATE_ACTIVE';    --チラシ開始日
  cv_billing_due_date         CONSTANT VARCHAR2(50)  := 'BILLING_DUE_DATE';              --請求締日
  cv_ship_time                CONSTANT VARCHAR2(50)  := 'SHIPPING_TIME';                 --出荷時刻
  cv_delv_schedule_time       CONSTANT VARCHAR2(50)  := 'DELIVERY_SCHEDULE_TIME';        --納品予定時間
  cv_order_time               CONSTANT VARCHAR2(50)  := 'ORDER_TIME';                    --発注時間
  cv_gen_date_item1           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM1';            --汎用日付項目1
  cv_gen_date_item2           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM2';            --汎用日付項目2
  cv_gen_date_item3           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM3';            --汎用日付項目3
  cv_gen_date_item4           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM4';            --汎用日付項目4
  cv_gen_date_item5           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM5';            --汎用日付項目5
  cv_arrival_ship_class       CONSTANT VARCHAR2(50)  := 'ARRIVAL_SHIPPING_CLASS';        --入出荷区分
  cv_vendor_class             CONSTANT VARCHAR2(50)  := 'VENDOR_CLASS';                  --取引先区分
  cv_invc_detailed_class      CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED_CLASS';        --伝票内訳区分
  cv_unit_price_use_class     CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_USE_CLASS';          --単価使用区分
  cv_sub_distb_cent_code      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_CODE';  --サブ物流センターコード
  cv_sub_distb_cent_name      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_NAME';  --サブ物流センターコード名
  cv_cent_delv_method         CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_METHOD';        --センター納品方法
  cv_cent_use_class           CONSTANT VARCHAR2(50)  := 'CENTER_USE_CLASS';              --センター利用区分
  cv_cent_whse_class          CONSTANT VARCHAR2(50)  := 'CENTER_WHSE_CLASS';             --センター倉庫区分
  cv_cent_area_class          CONSTANT VARCHAR2(50)  := 'CENTER_AREA_CLASS';             --センター地域区分
  cv_cent_arrival_class       CONSTANT VARCHAR2(50)  := 'CENTER_ARRIVAL_CLASS';          --センター入荷区分
  cv_depot_class              CONSTANT VARCHAR2(50)  := 'DEPOT_CLASS';                   --デポ区分
  cv_tcdc_class               CONSTANT VARCHAR2(50)  := 'TCDC_CLASS';                    --TCDC区分
  cv_upc_flag                 CONSTANT VARCHAR2(50)  := 'UPC_FLAG';                      --UPCフラグ
  cv_simultaneously_class     CONSTANT VARCHAR2(50)  := 'SIMULTANEOUSLY_CLASS';          --一斉区分
  cv_business_id              CONSTANT VARCHAR2(50)  := 'BUSINESS_ID';                   --業務ID
  cv_whse_directly_class      CONSTANT VARCHAR2(50)  := 'WHSE_DIRECTLY_CLASS';           --倉直区分
  cv_premium_rebate_class     CONSTANT VARCHAR2(50)  := 'PREMIUM_REBATE_CLASS';          --項目種別
  cv_item_type                CONSTANT VARCHAR2(50)  := 'ITEM_TYPE';                     --景品割戻区分
  cv_cloth_house_food_class   CONSTANT VARCHAR2(50)  := 'CLOTH_HOUSE_FOOD_CLASS';        --衣家食区分
  cv_mix_class                CONSTANT VARCHAR2(50)  := 'MIX_CLASS';                     --混在区分
  cv_stk_class                CONSTANT VARCHAR2(50)  := 'STK_CLASS';                     --在庫区分
  cv_last_modify_site_class   CONSTANT VARCHAR2(50)  := 'LAST_MODIFY_SITE_CLASS';        --最終修正場所区分
  cv_report_class             CONSTANT VARCHAR2(50)  := 'REPORT_CLASS';                  --帳票区分
  cv_addition_plan_class      CONSTANT VARCHAR2(50)  := 'ADDITION_PLAN_CLASS';           --追加・計画区分
  cv_registration_class       CONSTANT VARCHAR2(50)  := 'REGISTRATION_CLASS';            --登録区分
  cv_specific_class           CONSTANT VARCHAR2(50)  := 'SPECIFIC_CLASS';                --特定区分
  cv_dealings_class           CONSTANT VARCHAR2(50)  := 'DEALINGS_CLASS';                --取引区分
  cv_order_class              CONSTANT VARCHAR2(50)  := 'ORDER_CLASS';                   --発注区分
  cv_sum_line_class           CONSTANT VARCHAR2(50)  := 'SUM_LINE_CLASS';                --集計明細区分
  cv_ship_guidance_class      CONSTANT VARCHAR2(50)  := 'SHIPPING_GUIDANCE_CLASS';       --出荷案内以外区分
  cv_ship_class               CONSTANT VARCHAR2(50)  := 'SHIPPING_CLASS';                --出荷区分
  cv_prod_code_use_class      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_USE_CLASS';        --商品コード使用区分
  cv_cargo_item_class         CONSTANT VARCHAR2(50)  := 'CARGO_ITEM_CLASS';              --積送品区分
  cv_ta_class                 CONSTANT VARCHAR2(50)  := 'TA_CLASS';                      --T／A区分
  cv_plan_code                CONSTANT VARCHAR2(50)  := 'PLAN_CODE';                     --企画ｺｰﾄﾞ
  cv_category_code            CONSTANT VARCHAR2(50)  := 'CATEGORY_CODE';                 --カテゴリーコード
  cv_category_class           CONSTANT VARCHAR2(50)  := 'CATEGORY_CLASS';                --カテゴリー区分
  cv_carrier_means            CONSTANT VARCHAR2(50)  := 'CARRIER_MEANS';                 --運送手段
  cv_counter_code             CONSTANT VARCHAR2(50)  := 'COUNTER_CODE';                  --売場コード
  cv_move_sign                CONSTANT VARCHAR2(50)  := 'MOVE_SIGN';                     --移動サイン
  cv_eos_handwriting_class    CONSTANT VARCHAR2(50)  := 'EOS_HANDWRITING_CLASS';         --EOS・手書区分
  cv_delv_to_section_code     CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_SECTION_CODE';      --納品先課コード
  cv_invc_detailed            CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED';              --伝票内訳
  cv_attach_qty               CONSTANT VARCHAR2(50)  := 'ATTACH_QTY';                    --添付数
  cv_op_floor                 CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_FLOOR';             --フロア
  cv_text_no                  CONSTANT VARCHAR2(50)  := 'TEXT_NO';                       --TEXTNo
  cv_in_store_code            CONSTANT VARCHAR2(50)  := 'IN_STORE_CODE';                 --インストアコード
  cv_tag_data                 CONSTANT VARCHAR2(50)  := 'TAG_DATA';                      --タグ
  cv_competition_code         CONSTANT VARCHAR2(50)  := 'COMPETITION_CODE';              --競合
  cv_billing_chair            CONSTANT VARCHAR2(50)  := 'BILLING_CHAIR';                 --請求口座
  cv_chain_store_code         CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_CODE';              --チェーンストアーコード
  cv_chain_store_short_name   CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_SHORT_NAME';        --ﾁｪｰﾝｽﾄｱｰｺｰﾄﾞ略式名称
  cv_direct_delv_rcpt_fee     CONSTANT VARCHAR2(50)  := 'DIRECT_DELIVERY_RCPT_FEE';      --直配送／引取料
  cv_bill_info                CONSTANT VARCHAR2(50)  := 'BILL_INFO';                     --手形情報
  cv_description              CONSTANT VARCHAR2(50)  := 'DESCRIPTION';                   --摘要1
  cv_interior_code            CONSTANT VARCHAR2(50)  := 'INTERIOR_CODE';                 --内部コード
  cv_order_info_delv_category CONSTANT VARCHAR2(50)  := 'ORDER_INFO_DELIVERY_CATEGORY';  --発注情報 納品カテゴリー
  cv_purchase_type            CONSTANT VARCHAR2(50)  := 'PURCHASE_TYPE';                 --仕入形態
  cv_delv_to_name_alt         CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_NAME_ALT';          --納品場所名(カナ)
  cv_shop_opened_site         CONSTANT VARCHAR2(50)  := 'SHOP_OPENED_SITE';              --店出場所
  cv_counter_name             CONSTANT VARCHAR2(50)  := 'COUNTER_NAME';                  --売場名
  cv_extension_number         CONSTANT VARCHAR2(50)  := 'EXTENSION_NUMBER';              --内線番号
  cv_charge_name              CONSTANT VARCHAR2(50)  := 'CHARGE_NAME';                   --担当者名
  cv_price_tag                CONSTANT VARCHAR2(50)  := 'PRICE_TAG';                     --値札
  cv_tax_type                 CONSTANT VARCHAR2(50)  := 'TAX_TYPE';                      --税種
  cv_consumption_tax_class    CONSTANT VARCHAR2(50)  := 'CONSUMPTION_TAX_CLASS';         --消費税区分
  cv_brand_class              CONSTANT VARCHAR2(50)  := 'BRAND_CLASS';                   --BR
  cv_id_code                  CONSTANT VARCHAR2(50)  := 'ID_CODE';                       --IDコード
  cv_department_code          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_CODE';               --百貨店コード
  cv_department_name          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_NAME';               --百貨店名
  cv_item_type_number         CONSTANT VARCHAR2(50)  := 'ITEM_TYPE_NUMBER';              --品別番号
  cv_description_department   CONSTANT VARCHAR2(50)  := 'DESCRIPTION_DEPARTMENT';        --摘要2(百貨店)
  cv_price_tag_method         CONSTANT VARCHAR2(50)  := 'PRICE_TAG_METHOD';              --値札方法
  cv_reason_column            CONSTANT VARCHAR2(50)  := 'REASON_COLUMN';                 --自由欄
  cv_a_column_header          CONSTANT VARCHAR2(50)  := 'A_COLUMN_HEADER';               --A欄ヘッダ
  cv_d_column_header          CONSTANT VARCHAR2(50)  := 'D_COLUMN_HEADER';               --D欄ヘッダ
  cv_brand_code               CONSTANT VARCHAR2(50)  := 'BRAND_CODE';                    --ブランドコード
  cv_line_code                CONSTANT VARCHAR2(50)  := 'LINE_CODE';                     --ラインコード
  cv_class_code               CONSTANT VARCHAR2(50)  := 'CLASS_CODE';                    --クラスコード
  cv_a1_column                CONSTANT VARCHAR2(50)  := 'A1_COLUMN';                     --A－1欄
  cv_b1_column                CONSTANT VARCHAR2(50)  := 'B1_COLUMN';                     --B－1欄
  cv_c1_column                CONSTANT VARCHAR2(50)  := 'C1_COLUMN';                     --C－1欄
  cv_d1_column                CONSTANT VARCHAR2(50)  := 'D1_COLUMN';                     --D－1欄
  cv_e1_column                CONSTANT VARCHAR2(50)  := 'E1_COLUMN';                     --E－1欄
  cv_a2_column                CONSTANT VARCHAR2(50)  := 'A2_COLUMN';                     --A－2欄
  cv_b2_column                CONSTANT VARCHAR2(50)  := 'B2_COLUMN';                     --B－2欄
  cv_c2_column                CONSTANT VARCHAR2(50)  := 'C2_COLUMN';                     --C－2欄
  cv_d2_column                CONSTANT VARCHAR2(50)  := 'D2_COLUMN';                     --D－2欄
  cv_e2_column                CONSTANT VARCHAR2(50)  := 'E2_COLUMN';                     --E－2欄
  cv_a3_column                CONSTANT VARCHAR2(50)  := 'A3_COLUMN';                     --A－3欄
  cv_b3_column                CONSTANT VARCHAR2(50)  := 'B3_COLUMN';                     --B－3欄
  cv_c3_column                CONSTANT VARCHAR2(50)  := 'C3_COLUMN';                     --C－3欄
  cv_d3_column                CONSTANT VARCHAR2(50)  := 'D3_COLUMN';                     --D－3欄
  cv_e3_column                CONSTANT VARCHAR2(50)  := 'E3_COLUMN';                     --E－3欄
  cv_f1_column                CONSTANT VARCHAR2(50)  := 'F1_COLUMN';                     --F－1欄
  cv_g1_column                CONSTANT VARCHAR2(50)  := 'G1_COLUMN';                     --G－1欄
  cv_h1_column                CONSTANT VARCHAR2(50)  := 'H1_COLUMN';                     --H－1欄
  cv_i1_column                CONSTANT VARCHAR2(50)  := 'I1_COLUMN';                     --I－1欄
  cv_j1_column                CONSTANT VARCHAR2(50)  := 'J1_COLUMN';                     --J－1欄
  cv_k1_column                CONSTANT VARCHAR2(50)  := 'K1_COLUMN';                     --K－1欄
  cv_l1_column                CONSTANT VARCHAR2(50)  := 'L1_COLUMN';                     --L－1欄
  cv_f2_column                CONSTANT VARCHAR2(50)  := 'F2_COLUMN';                     --F－2欄
  cv_g2_column                CONSTANT VARCHAR2(50)  := 'G2_COLUMN';                     --G－2欄
  cv_h2_column                CONSTANT VARCHAR2(50)  := 'H2_COLUMN';                     --H－2欄
  cv_i2_column                CONSTANT VARCHAR2(50)  := 'I2_COLUMN';                     --I－2欄
  cv_j2_column                CONSTANT VARCHAR2(50)  := 'J2_COLUMN';                     --J－2欄
  cv_k2_column                CONSTANT VARCHAR2(50)  := 'K2_COLUMN';                     --K－2欄
  cv_l2_column                CONSTANT VARCHAR2(50)  := 'L2_COLUMN';                     --L－2欄
  cv_f3_column                CONSTANT VARCHAR2(50)  := 'F3_COLUMN';                     --F－3欄
  cv_g3_column                CONSTANT VARCHAR2(50)  := 'G3_COLUMN';                     --G－3欄
  cv_h3_column                CONSTANT VARCHAR2(50)  := 'H3_COLUMN';                     --H－3欄
  cv_i3_column                CONSTANT VARCHAR2(50)  := 'I3_COLUMN';                     --I－3欄
  cv_j3_column                CONSTANT VARCHAR2(50)  := 'J3_COLUMN';                     --J－3欄
  cv_k3_column                CONSTANT VARCHAR2(50)  := 'K3_COLUMN';                     --K－3欄
  cv_l3_column                CONSTANT VARCHAR2(50)  := 'L3_COLUMN';                     --L－3欄
  cv_chain_pec_area_header    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_HEADER';    --チェーン店固有エリア(ヘッダ)
  cv_order_connection_number  CONSTANT VARCHAR2(50)  := 'ORDER_CONNECTION_NUMBER';       --受注関連番号(仮)
  cv_line_no                  CONSTANT VARCHAR2(50)  := 'LINE_NO';                       --行No
  cv_stkout_class             CONSTANT VARCHAR2(50)  := 'STOCKOUT_CLASS';                --欠品区分
  cv_stkout_reason            CONSTANT VARCHAR2(50)  := 'STOCKOUT_REASON';               --欠品理由
  cv_prod_code_itouen         CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITOUEN';           --商品コード(伊藤園)
  cv_prod_code1               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE1';                 --商品コード1
  cv_prod_code2               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE2';                 --商品コード2
  cv_jan_code                 CONSTANT VARCHAR2(50)  := 'JAN_CODE';                      --JANコード
  cv_itf_code                 CONSTANT VARCHAR2(50)  := 'ITF_CODE';                      --ITFコード
  cv_extension_itf_code       CONSTANT VARCHAR2(50)  := 'EXTENSION_ITF_CODE';            --内箱ITFコード
  cv_case_prod_code           CONSTANT VARCHAR2(50)  := 'CASE_PRODUCT_CODE';             --ケース商品コード
  cv_ball_prod_code           CONSTANT VARCHAR2(50)  := 'BALL_PRODUCT_CODE';             --ボール商品コード
  cv_prod_code_item_type      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITEM_TYPE';        --商品コード品種
  cv_prod_class               CONSTANT VARCHAR2(50)  := 'PROD_CLASS';                    --商品区分
  cv_prod_name                CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME';                  --商品名(漢字)
  cv_prod_name1_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME1_ALT';             --商品名1(カナ)
  cv_prod_name2_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME2_ALT';             --商品名2(カナ)
  cv_item_standard1           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD1';                --規格1
  cv_item_standard2           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD2';                --規格2
  cv_qty_in_case              CONSTANT VARCHAR2(50)  := 'QTY_IN_CASE';                   --入数
  cv_num_of_cases             CONSTANT VARCHAR2(50)  := 'NUM_OF_CASES';                  --ケース入数
  cv_num_of_ball              CONSTANT VARCHAR2(50)  := 'NUM_OF_BALL';                   --ボール入数
  cv_item_color               CONSTANT VARCHAR2(50)  := 'ITEM_COLOR';                    --色
  cv_item_size                CONSTANT VARCHAR2(50)  := 'ITEM_SIZE';                     --サイズ
  cv_expiration_date          CONSTANT VARCHAR2(50)  := 'EXPIRATION_DATE';               --賞味期限日
  cv_prod_date                CONSTANT VARCHAR2(50)  := 'PRODUCT_DATE';                  --製造日
  cv_order_uom_qty            CONSTANT VARCHAR2(50)  := 'ORDER_UOM_QTY';                 --発注単位数
  cv_ship_uom_qty             CONSTANT VARCHAR2(50)  := 'SHIPPING_UOM_QTY';              --出荷単位数
  cv_packing_uom_qty          CONSTANT VARCHAR2(50)  := 'PACKING_UOM_QTY';               --梱包単位数
  cv_deal_code                CONSTANT VARCHAR2(50)  := 'DEAL_CODE';                     --引合
  cv_deal_class               CONSTANT VARCHAR2(50)  := 'DEAL_CLASS';                    --引合区分
  cv_collation_code           CONSTANT VARCHAR2(50)  := 'COLLATION_CODE';                --照合
  cv_uom_code                 CONSTANT VARCHAR2(50)  := 'UOM_CODE';                      --単位
  cv_unit_price_class         CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_CLASS';              --単価区分
  cv_parent_packing_number    CONSTANT VARCHAR2(50)  := 'PARENT_PACKING_NUMBER';         --親梱包番号
  cv_packing_number           CONSTANT VARCHAR2(50)  := 'PACKING_NUMBER';                --梱包番号
  cv_prod_group_code          CONSTANT VARCHAR2(50)  := 'PRODUCT_GROUP_CODE';            --商品群コード
  cv_case_dismantle_flag      CONSTANT VARCHAR2(50)  := 'CASE_DISMANTLE_FLAG';           --ケース解体不可フラグ
  cv_case_class               CONSTANT VARCHAR2(50)  := 'CASE_CLASS';                    --ケース区分
  cv_indv_order_qty           CONSTANT VARCHAR2(50)  := 'INDV_ORDER_QTY';                --発注数量(バラ)
  cv_case_order_qty           CONSTANT VARCHAR2(50)  := 'CASE_ORDER_QTY';                --発注数量(ケース)
  cv_ball_order_qty           CONSTANT VARCHAR2(50)  := 'BALL_ORDER_QTY';                --発注数量(ボール)
  cv_sum_order_qty            CONSTANT VARCHAR2(50)  := 'SUM_ORDER_QTY';                 --発注数量(合計、バラ)
  cv_indv_ship_qty            CONSTANT VARCHAR2(50)  := 'INDV_SHIPPING_QTY';             --出荷数量(バラ)
  cv_case_ship_qty            CONSTANT VARCHAR2(50)  := 'CASE_SHIPPING_QTY';             --出荷数量(ケース)
  cv_ball_ship_qty            CONSTANT VARCHAR2(50)  := 'BALL_SHIPPING_QTY';             --出荷数量(ボール)
  cv_pallet_ship_qty          CONSTANT VARCHAR2(50)  := 'PALLET_SHIPPING_QTY';           --出荷数量(パレット)
  cv_sum_ship_qty             CONSTANT VARCHAR2(50)  := 'SUM_SHIPPING_QTY';              --出荷数量(合計、バラ)
  cv_indv_stkout_qty          CONSTANT VARCHAR2(50)  := 'INDV_STOCKOUT_QTY';             --欠品数量(バラ)
  cv_case_stkout_qty          CONSTANT VARCHAR2(50)  := 'CASE_STOCKOUT_QTY';             --欠品数量(ケース)
  cv_ball_stkout_qty          CONSTANT VARCHAR2(50)  := 'BALL_STOCKOUT_QTY';             --欠品数量(ボール)
  cv_sum_stkout_qty           CONSTANT VARCHAR2(50)  := 'SUM_STOCKOUT_QTY';              --欠品数量(合計、バラ)
  cv_case_qty                 CONSTANT VARCHAR2(50)  := 'CASE_QTY';                      --ケース個口数
  cv_fold_container_indv_qty  CONSTANT VARCHAR2(50)  := 'FOLD_CONTAINER_INDV_QTY';       --オリコン(バラ)個口数
  cv_order_unit_price         CONSTANT VARCHAR2(50)  := 'ORDER_UNIT_PRICE';              --原単価(発注)
  cv_ship_unit_price          CONSTANT VARCHAR2(50)  := 'SHIPPING_UNIT_PRICE';           --原単価(出荷)
  cv_order_cost_amt           CONSTANT VARCHAR2(50)  := 'ORDER_COST_AMT';                --原価金額(発注)
  cv_ship_cost_amt            CONSTANT VARCHAR2(50)  := 'SHIPPING_COST_AMT';             --原価金額(出荷)
  cv_stkout_cost_amt          CONSTANT VARCHAR2(50)  := 'STOCKOUT_COST_AMT';             --原価金額(欠品)
  cv_selling_price            CONSTANT VARCHAR2(50)  := 'SELLING_PRICE';                 --売単価
  cv_order_price_amt          CONSTANT VARCHAR2(50)  := 'ORDER_PRICE_AMT';               --売価金額(発注)
  cv_ship_price_amt           CONSTANT VARCHAR2(50)  := 'SHIPPING_PRICE_AMT';            --売価金額(出荷)
  cv_stkout_price_amt         CONSTANT VARCHAR2(50)  := 'STOCKOUT_PRICE_AMT';            --売価金額(欠品)
  cv_a_column_department      CONSTANT VARCHAR2(50)  := 'A_COLUMN_DEPARTMENT';           --A欄(百貨店)
  cv_d_column_department      CONSTANT VARCHAR2(50)  := 'D_COLUMN_DEPARTMENT';           --D欄(百貨店)
  cv_standard_info_depth      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_DEPTH';           --規格情報・奥行き
  cv_standard_info_height     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_HEIGHT';          --規格情報・高さ
  cv_standard_info_width      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WIDTH';           --規格情報・幅
  cv_standard_info_weight     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WEIGHT';          --規格情報・重量
  cv_gen_suc_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM1';       --汎用引継ぎ項目1
  cv_gen_suc_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM2';       --汎用引継ぎ項目2
  cv_gen_suc_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM3';       --汎用引継ぎ項目3
  cv_gen_suc_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM4';       --汎用引継ぎ項目4
  cv_gen_suc_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM5';       --汎用引継ぎ項目5
  cv_gen_suc_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM6';       --汎用引継ぎ項目6
  cv_gen_suc_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM7';       --汎用引継ぎ項目7
  cv_gen_suc_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM8';       --汎用引継ぎ項目8
  cv_gen_suc_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM9';       --汎用引継ぎ項目9
  cv_gen_suc_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM10';      --汎用引継ぎ項目10
  cv_gen_add_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM1';             --汎用付加項目1
  cv_gen_add_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM2';             --汎用付加項目2
  cv_gen_add_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM3';             --汎用付加項目3
  cv_gen_add_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM4';             --汎用付加項目4
  cv_gen_add_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM5';             --汎用付加項目5
  cv_gen_add_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM6';             --汎用付加項目6
  cv_gen_add_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM7';             --汎用付加項目7
  cv_gen_add_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM8';             --汎用付加項目8
  cv_gen_add_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM9';             --汎用付加項目9
  cv_gen_add_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM10';            --汎用付加項目10
  cv_chain_pec_area_line      CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_LINE';      --チェーン店固有エリア(明細)
  cv_invc_indv_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_ORDER_QTY';        --(伝票計)発注数量(バラ)
  cv_invc_case_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_ORDER_QTY';        --(伝票計)発注数量(ケース)
  cv_invc_ball_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_ORDER_QTY';        --(伝票計)発注数量(ボール)
  cv_invc_sum_order_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_ORDER_QTY';         --(伝票計)発注数量(合計、バラ)
  cv_invc_indv_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_SHIPPING_QTY';     --(伝票計)出荷数量(バラ)
  cv_invc_case_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_SHIPPING_QTY';     --(伝票計)出荷数量(ケース)
  cv_invc_ball_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_SHIPPING_QTY';     --(伝票計)出荷数量(ボール)
  cv_invc_pallet_ship_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_PALLET_SHIPPING_QTY';   --(伝票計)出荷数量(パレット)
  cv_invc_sum_ship_qty        CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_SHIPPING_QTY';      --(伝票計)出荷数量(合計、バラ)
  cv_invc_indv_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_STOCKOUT_QTY';     --(伝票計)欠品数量(バラ)
  cv_invc_case_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_STOCKOUT_QTY';     --(伝票計)欠品数量(ケース)
  cv_invc_ball_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_STOCKOUT_QTY';     --(伝票計)欠品数量(ボール)
  cv_invc_sum_stkout_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_STOCKOUT_QTY';      --(伝票計)欠品数量(合計、バラ)
  cv_invc_case_qty            CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_QTY';              --(伝票計)ケース個口数
  cv_invc_fold_container_qty  CONSTANT VARCHAR2(50)  := 'INVOICE_FOLD_CONTAINER_QTY';    --(伝票計)オリコン(バラ)個口数
  cv_invc_order_cost_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_COST_AMT';        --(伝票計)原価金額(発注)
  cv_invc_ship_cost_amt       CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_COST_AMT';     --(伝票計)原価金額(出荷)
  cv_invc_stkout_cost_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_COST_AMT';     --(伝票計)原価金額(欠品)
  cv_invc_order_price_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_PRICE_AMT';       --(伝票計)売価金額(発注)
  cv_invc_ship_price_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_PRICE_AMT';    --(伝票計)売価金額(出荷)
  cv_invc_stkout_price_amt    CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_PRICE_AMT';    --(伝票計)売価金額(欠品)
  cv_t_indv_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_ORDER_QTY';          --(総合計)発注数量(バラ)
  cv_t_case_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_ORDER_QTY';          --(総合計)発注数量(ケース)
  cv_t_ball_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_ORDER_QTY';          --(総合計)発注数量(ボール)
  cv_t_sum_order_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_ORDER_QTY';           --(総合計)発注数量(合計、バラ)
  cv_t_indv_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_SHIPPING_QTY';       --(総合計)出荷数量(バラ)
  cv_t_case_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_SHIPPING_QTY';       --(総合計)出荷数量(ケース)
  cv_t_ball_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_SHIPPING_QTY';       --(総合計)出荷数量(ボール)
  cv_t_pallet_ship_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_PALLET_SHIPPING_QTY';     --(総合計)出荷数量(パレット)
  cv_t_sum_ship_qty           CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_SHIPPING_QTY';        --(総合計)出荷数量(合計、バラ)
  cv_t_indv_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_STOCKOUT_QTY';       --(総合計)欠品数量(バラ)
  cv_t_case_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_STOCKOUT_QTY';       --(総合計)欠品数量(ケース)
  cv_t_ball_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_STOCKOUT_QTY';       --(総合計)欠品数量(ボール)
  cv_t_sum_stkout_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_STOCKOUT_QTY';        --(総合計)欠品数量(合計、バラ)
  cv_t_case_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_QTY';                --(総合計)ケース個口数
  cv_t_fold_container_qty     CONSTANT VARCHAR2(50)  := 'TOTAL_FOLD_CONTAINER_QTY';      --(総合計)オリコン(バラ)個口数
  cv_t_order_cost_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_COST_AMT';          --(総合計)原価金額(発注)
  cv_t_ship_cost_amt          CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_COST_AMT';       --(総合計)原価金額(出荷)
  cv_t_stkout_cost_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_COST_AMT';       --(総合計)原価金額(欠品)
  cv_t_order_price_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_PRICE_AMT';         --(総合計)売価金額(発注)
  cv_t_ship_price_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_PRICE_AMT';      --(総合計)売価金額(出荷)
  cv_t_stkout_price_amt       CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_PRICE_AMT';      --(総合計)売価金額(欠品)
  cv_t_line_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_LINE_QTY';                --トータル行数
  cv_t_invc_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_INVOICE_QTY';             --トータル伝票枚数
  cv_chain_pec_area_footer    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_FOOTER';    --チェーン店固有エリア(フッタ)
/* 2009/04/28 Ver1.3 Add Start */
  cv_attribute                CONSTANT VARCHAR2(50)  := 'ATTRIBUTE';                     -- 予備エリア
/* 2009/04/28 Ver1.3 Add End   */
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  gt_f_handle                 UTL_FILE.FILE_TYPE;                              -- ファイルハンドラ
  gt_data_type_table          xxcos_common2_pkg.g_record_layout_ttype;         -- ファイルレイアウト
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --処理件数取得用
  gn_no_inv_item_cnt          NUMBER DEFAULT 0;                        -- 非在庫品件数
  gn_chain_store_cnt          NUMBER DEFAULT 0;                        -- 対象件数(チェーン店)
  gn_data_cnt                 NUMBER DEFAULT 0;                        -- 対象件数(チェーン店内の対象顧客販売実績)
  --データ取得用
  gv_prf_organization_code    VARCHAR2(50)  DEFAULT NULL;              -- XXCOI:在庫組織コード
  gv_prf_organization_id      VARCHAR2(50)  DEFAULT NULL;              -- XXCOS:在庫組織ID
  gn_org_id                   NUMBER        DEFAULT NULL;              -- MO:営業単位
  -- ファイル出力項目用
  gv_f_o_date                 CHAR(8);                                 -- 処理日
  gv_f_o_time                 CHAR(6);                                 -- 処理時刻
  gt_edi_media_class          xxcos_lookup_values_v.lookup_code%TYPE;  -- EDI媒体区分
  gt_data_type_code           xxcos_lookup_values_v.lookup_code%TYPE;  -- データ種コード
  gt_edi_seales_class         fnd_lookup_values_vl.lookup_code%TYPE;   -- 売上区分（協賛）
  -- 条件判定、共通関数用
  gt_from_series              xxcos_lookup_values_v.attribute1%TYPE;   -- IF元業務系列コード
  gv_if_header                VARCHAR2(2)   DEFAULT NULL;              -- ヘッダレコード区分
  gv_if_data                  VARCHAR2(2)   DEFAULT NULL;              -- データレコード区分
  gv_if_footer                VARCHAR2(2)   DEFAULT NULL;              -- フッタレコード区分
  gv_utl_m_line               VARCHAR2(100) DEFAULT NULL;              -- UTL_MAX行サイズ
  gv_outbound_d               VARCHAR2(100) DEFAULT NULL;              -- アウトバウンド用ディレクトリパス
  gv_dept_code                VARCHAR2(100) DEFAULT NULL;              -- 業務管理部コード
  gv_prf_def_item_rate        VARCHAR2(100) DEFAULT NULL;              -- XXCOS:EDIデフォルト歩率
  gv_in_file_name             VARCHAR2(240) DEFAULT NULL;              -- ファイル名
/* 2010/03/16 Ver1.10 Del Start */
--  gv_run_class_create         VARCHAR2(50)  DEFAULT NULL;              -- 実行区分：「作成」文言
--  gv_run_class_cancel         VARCHAR2(50)  DEFAULT NULL;              -- 実行区分：「解除」文言
--  gv_run_class_cd_create      VARCHAR2(2)   DEFAULT NULL;              -- 実行区分：「作成」コード
--  gv_run_class_cd_cancel      VARCHAR2(2)   DEFAULT NULL;              -- 実行区分：「解除」コード
/* 2010/03/16 Ver1.10 Del End   */
/* 2010/03/16 Ver1.10 Add Start */
  gd_min_date                 DATE;                                    -- MIN日付
  gd_max_date                 DATE;                                    -- MAX日付
  gn_edi_trg_hold_m           NUMBER;                                  -- EDI販売実績対象保持月数
/* 2010/03/16 Ver1.10 Add End   */
  --ファイルヘッダ情報
  gt_sales_base_name          hz_parties.party_name%TYPE;                   --拠点名
  gt_edi_chain_name           hz_parties.party_name%TYPE;                   --EDIチェーン店名
  gt_edi_chain_name_phonetic  hz_parties.organization_name_phonetic%TYPE;   --EDIチェーン店カナ
--****************　2009/07/07   N.Maeda  Ver1.5   ADD   START  *********************************************--
  gt_parallel_num             xxcos_lookup_values_v.attribute1%TYPE;   -- ファイルNo
--****************　2009/07/07   N.Maeda  Ver1.5   ADD    END   *********************************************--
  -- ===================================
  -- ユーザー定義グローバルRECORD型宣言
  -- ===================================
  --処理対象顧客(チェーン店単位)
  TYPE g_chain_store_rtype IS RECORD(
    chain_store_code  fnd_lookup_values.description%TYPE,  --チェーン店コード
    process_pattern   fnd_lookup_values.attribute1%TYPE    --処理パターン
  );
  --販売実績情報
  TYPE g_edi_sales_data_rtype IS RECORD(
    sales_exp_header_id          xxcos_sales_exp_headers.sales_exp_header_id%TYPE,          --販売実績ヘッダID
    sales_exp_line_id            xxcos_sales_exp_lines.sales_exp_line_id%TYPE,              --販売実績明細ID
    sales_base_code              xxcos_sales_exp_headers.sales_base_code%TYPE,              --拠点(部門)コード
    sales_base_name              hz_parties.party_name%TYPE,                                --拠点名(正式名)
    sales_base_phonetic          hz_parties.organization_name_phonetic%TYPE,                --拠点名(カナ)
/* 2009/11/27 Ver1.9 Add Start */
    order_invoice_number         xxcos_sales_exp_headers.order_invoice_number%TYPE,         --相手先発注番号
/* 2009/11/27 Ver1.9 Add End   */
    ship_to_customer_code        xxcos_sales_exp_headers.ship_to_customer_code%TYPE,        --顧客コード
    customer_name                hz_parties.party_name%TYPE,                                --顧客名(漢字)
    customer_phonetic            hz_parties.organization_name_phonetic%TYPE,                --顧客名(カナ)
    orig_delivery_date           xxcos_sales_exp_headers.orig_delivery_date%TYPE,           --店舗納品日
    invoice_class                xxcos_sales_exp_headers.invoice_class%TYPE,                --伝票区分
    invoice_classification_code  xxcos_sales_exp_headers.invoice_classification_code%TYPE,  --大分類コード
    dlv_invoice_number           xxcos_sales_exp_headers.dlv_invoice_number%TYPE,           --伝票番号
    address                      VARCHAR2(255),                                             --届け先住所(漢字)
    sales_exp_day                ra_terms_vl.due_cutoff_day%TYPE,                           --請求開始日*請求締日の編集元*
    orig_inspect_date            xxcos_sales_exp_headers.orig_inspect_date%TYPE,            --汎用日付項目１、２
    dlv_invoice_class            xxcos_sales_exp_headers.dlv_invoice_class%TYPE,            --出荷区分
    bill_cred_rec_code2          hz_cust_site_uses_all.attribute5%TYPE,                     --チェーン店固有エリア(ヘッダー)
    dlv_invoice_line_number      xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE,        --行No
    item_code                    xxcos_sales_exp_lines.item_code%TYPE,                      --商品コード(伊藤園)
    jan_code                     ic_item_mst_b.attribute21%TYPE,                            --JANコード
    itf_code                     ic_item_mst_b.attribute22%TYPE,                            --ITFコード
    item_div_code                mtl_categories_b.segment1%TYPE,                            --商品区分
    item_name                    xxcmn_item_mst_b.item_name%TYPE,                           --商品名(漢字)
    item_phonetic1               VARCHAR2(15),                                              --商品名２(カナ)
    item_phonetic2               VARCHAR2(15),                                              --規格２
    case_inc_num                 ic_item_mst_b.attribute11%TYPE,                            --ケース入数
    bowl_inc_num                 xxcmm_system_items_b.bowl_inc_num%TYPE,                    --ボール入数
    standard_qty                 xxcos_sales_exp_lines.standard_qty%TYPE,                   --出荷数量(バラ),(合計、バラ)
    standard_unit_price          xxcos_sales_exp_lines.standard_unit_price%TYPE,            --原単価(発注)
    sale_amount                  xxcos_sales_exp_lines.sale_amount%TYPE,                    --原価金額(出荷)
    sales_class                  xxcos_sales_exp_lines.sales_class%TYPE,                    --汎用付加項目２
    sum_standard_qty             NUMBER(10,1),                                              --(伝票計)出荷数量(バラ),(合計、バラ)
    sum_sale_amount              NUMBER(14,2),                                              --(伝票計)原価金額(出荷)
    send_code1                    hz_cust_site_uses_all.attribute4%TYPE,                    --売掛コード1(請求書)*未使用
    send_code3                    hz_cust_site_uses_all.attribute6%TYPE,                    --売掛コード3(その他)*未使用
--****************　2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
    edi_forward_number           xxcmm_cust_accounts.edi_forward_number%TYPE,               --EDI伝票追番
--****************　2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
-- 2009/06/25 M.Sano Ver.1.5 add Start
    standard_uom_code            xxcos_sales_exp_lines.standard_uom_code%TYPE               --基準数量
-- 2009/06/25 M.Sano Ver.1.5 add End
  );
--
/* 2009/07/29 Ver1.5 Add Start */
  --伝票計情報
  TYPE g_sum_qty_rtype IS RECORD(
    invc_indv_qty_sum  NUMBER,  --(伝票計)出荷数量(バラ)
    invc_case_qty_sum  NUMBER,  --(伝票計)出荷数量(ケース)
    invc_ball_qty_sum  NUMBER   --(伝票計)出荷数量(ボール)
  );
/* 2009/07/29 Ver1.5 Add End   */
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  --非在庫品情報
  TYPE g_no_inv_item_ttype IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE INDEX BY BINARY_INTEGER;
  gt_no_inv_item         g_no_inv_item_ttype;
  --処理対象顧客(チェーン店単位)
  TYPE g_chain_store_ttype IS TABLE OF g_chain_store_rtype INDEX BY BINARY_INTEGER;
  gt_chain_store         g_chain_store_ttype;
  --販売実績情報
  TYPE g_edi_sales_data_ttype IS TABLE OF g_edi_sales_data_rtype INDEX BY BINARY_INTEGER;
  gt_edi_sales_data      g_edi_sales_data_ttype;
  gt_edi_sales_data_c    g_edi_sales_data_ttype;  --テーブル型変数初期化用
  --販売実績ヘッダ更新
  TYPE g_header_id_ttype IS TABLE OF xxcos_sales_exp_headers.sales_exp_header_id%TYPE INDEX BY BINARY_INTEGER;
  gt_update_header_id    g_header_id_ttype;
  gt_update_header_id_c  g_header_id_ttype;  --テーブル型変数初期化用
/* 2009/07/29 Ver1.5 Add Start */
  --伝票計情報 テーブル型
  TYPE g_sum_qty_ttype IS TABLE OF g_sum_qty_rtype INDEX BY VARCHAR2(21);
  gt_sum_qty             g_sum_qty_ttype;
/* 2009/07/29 Ver1.5 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : input_param_check
   * Description      : 入力パラメタチェック処理(A-1)
   ***********************************************************************************/
  PROCEDURE input_param_check(
    iv_run_class        IN  VARCHAR2,  --   実行区分：「0:作成」「1:解除」「2:対象外更新」
    iv_inv_cust_code    IN  VARCHAR2,  --   請求先顧客コード
    iv_send_date        IN  VARCHAR2,  --   送信日(YYYYMMDD)
/* 2009/04/15 Add Start */
    iv_sales_exp_ptn    IN VARCHAR2,   --   EDI販売実績処理パターン
/* 2009/04/15 Add End   */
    ov_errbuf           OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_param_check'; -- プログラム名
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
    lv_param_msg      VARCHAR2(5000)  DEFAULT NULL;  --パラメーター出力用
    lv_tkn_name       VARCHAR2(50)    DEFAULT NULL;  --トークン取得用
    ld_date_value     DATE;
/* 2010/03/16 Ver1.10 Add Start */
    lv_run_class_chk  VARCHAR2(1);                   --実行区分チェック用
/* 2010/03/16 Ver1.10 Add End   */
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    --  コンカレント入力項目出力
    --==============================================================
    IF  ( iv_run_class = cv_0 ) THEN
      --* -------------------------------------------------------------
      -- 実行区分：「作成」
      --* -------------------------------------------------------------
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       --アプリケーション
                        ,iv_name         => cv_msg_param_create  --パラメーター出力(作成)
                        ,iv_token_name1  => cv_tkn_parame1       --トークンコード１
                        ,iv_token_value1 => iv_run_class         --実行区分
                        ,iv_token_name2  => cv_tkn_parame2       --トークンコード２
/* 2009/04/15 Mod Start */
--                        ,iv_token_value2 => iv_inv_cust_code     --請求先顧客コード
                        ,iv_token_value2 => iv_sales_exp_ptn     --EDI販売実績処理パターン
/* 2009/04/15 Mod Start */
                      );
    ELSIF ( iv_run_class = cv_1 ) THEN
      --* -------------------------------------------------------------
      -- 実行区分：「解除」
      --* ------------------------------------------------------------- 
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       --アプリケーション
                        ,iv_name         => cv_msg_param_cancel  --パラメーター出力(解除)
                        ,iv_token_name1  => cv_tkn_parame1       --トークンコード１
                        ,iv_token_value1 => iv_run_class         --実行区分
                        ,iv_token_name2  => cv_tkn_parame2       --トークンコード２
                        ,iv_token_value2 => iv_inv_cust_code     --請求先顧客コード
                        ,iv_token_name3  => cv_tkn_parame3       --トークンコード３
                        ,iv_token_value3 => iv_send_date         --送信日(YYYYMMDD)
                     );
/* 2010/03/16 Ver1.10 Add Start */
    ELSIF ( iv_run_class = cv_2 ) THEN
      --* -------------------------------------------------------------
      -- 実行区分：「対象外更新」
      --* ------------------------------------------------------------- 
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       --アプリケーション
                        ,iv_name         => cv_msg_param_update  --パラメーター出力(対象外更新)
                        ,iv_token_name1  => cv_tkn_parame1       --トークンコード１
                        ,iv_token_value1 => iv_run_class         --実行区分
                     );
/* 2010/03/16 Ver1.10 Add End   */
    END IF;
    --パラメータをメッセージに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --パラメータをログに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
  --
    --==============================================================
    --  コンカレント入力項目チェック
    --==============================================================
    --* -------------------------------------------------------------
    --  実行区分NULLチェック
    --* -------------------------------------------------------------
    IF  ( iv_run_class  IS NULL ) THEN
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_application
                       ,iv_name         =>  cv_msg_run_class  --「実行区分」
                     );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                iv_application   =>  cv_application,
                iv_name          =>  cv_msg_param_err, --必須入力パラメータ未設定エラー
                iv_token_name1   =>  cv_tkn_in_param,
                iv_token_value1  =>  lv_tkn_name
                );
      RAISE global_api_expt;
    END IF;
/* 2010/03/16 Ver1.10 Del Start */
--    --* -------------------------------------------------------------
--    --  取得したEDI販売実績作成実行区分とパラメータのチェック
--    --* -------------------------------------------------------------
--    --文言取得
--    gv_run_class_create := xxccp_common_pkg.get_msg(
--                              iv_application  =>  cv_application
--                             ,iv_name         =>  cv_msg_create  --「作成」
--                           );
--    gv_run_class_cancel := xxccp_common_pkg.get_msg(
--                              iv_application  =>  cv_application --アプリケーション
--                             ,iv_name         =>  cv_msg_cancel  --「解除」
--                           );
/* 2010/03/16 Ver1.10 Del End   */
    -- EDI販売実績作成実行区分チェック
    BEGIN
/* 2010/03/16 Ver1.10 Mod Start */
--      SELECT xlvv.lookup_code lookup_code
--      INTO   gv_run_class_cd_create
      SELECT 'X'
      INTO   lv_run_class_chk
/* 2010/03/16 Ver1.10 Mod End   */
      FROM   xxcos_lookup_values_v  xlvv
      WHERE  xlvv.lookup_type   = cv_lkt_edi_s_exe_type -- EDI販売実績作成実行区分
/* 2010/03/16 Ver1.10 Mod Start */
--      AND    xlvv.meaning       = gv_run_class_create   --「作成」
      AND    xlvv.lookup_code   = iv_run_class          -- 実行区分
/* 2010/03/16 Ver1.10 Mod End   */
      AND    (
               ( xlvv.start_date_active IS NULL )
               OR
               ( xlvv.start_date_active <= cd_process_date )
             )
      AND    (
               ( xlvv.end_date_active   IS NULL )
               OR
               ( xlvv.end_date_active   >= cd_process_date )
             )  -- 業務日付がFROM-TO内
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                         ,iv_name         => cv_msg_run_class  --「実行区分」
                       );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_application
                       ,iv_name          =>  cv_msg_in_param_err  --入力パラメータ不正エラー
                       ,iv_token_name1   =>  cv_tkn_in_param
                       ,iv_token_value1  =>  lv_tkn_name
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
/* 2010/03/16 Ver1.10 Del Start */
--    -- EDI販売実績作成実行区分取得(解除)
--    BEGIN
--      SELECT xlvv.lookup_code lookup_code
--      INTO   gv_run_class_cd_cancel
--      FROM   xxcos_lookup_values_v  xlvv
--      WHERE  xlvv.lookup_type   = cv_lkt_edi_s_exe_type  -- EDI販売実績作成実行区分
--      AND    xlvv.meaning       = gv_run_class_cancel    --「解除」
--      AND    (
--               ( xlvv.start_date_active IS NULL )
--               OR
--               ( xlvv.start_date_active <= cd_process_date )
--             )
--      AND    (
--               ( xlvv.end_date_active   IS NULL )
--               OR
--               ( xlvv.end_date_active   >= cd_process_date )
--             )  -- 業務日付がFROM-TO内
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        lv_tkn_name := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_application
--                         ,iv_name         => cv_msg_run_class  --「実行区分」
--                       );
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application   =>  cv_application
--                       ,iv_name          =>  cv_msg_in_param_err  --入力パラメータ不正エラー
--                       ,iv_token_name1   =>  cv_tkn_in_param
--                       ,iv_token_value1  =>  lv_tkn_name
--                     );
--        lv_errbuf  := SQLERRM;
--        RAISE global_api_expt;
--    END;
--    -- チェック処理
--    IF ( ( iv_run_class <> gv_run_class_cd_create )
--      AND ( iv_run_class <> gv_run_class_cd_cancel ) )
--    THEN
--      lv_tkn_name := xxccp_common_pkg.get_msg(
--                        iv_application  =>  cv_application
--                       ,iv_name         =>  cv_msg_run_class  --「実行区分」
--                     );
--      lv_errmsg :=  xxccp_common_pkg.get_msg(
--                       iv_application   =>  cv_application
--                      ,iv_name          =>  cv_msg_in_param_err  --入力パラメータ不正エラー
--                      ,iv_token_name1   =>  cv_tkn_in_param
--                      ,iv_token_value1  =>  lv_tkn_name
--                    );
--      RAISE global_api_expt;
--    END IF;
--
/* 2010/03/16 Ver1.10 Del End  */
    --「解除」の場合
    IF  ( iv_run_class = gv_run_class_cd_cancel ) THEN
      --* -------------------------------------------------------------
      --  請求先顧客コードの必須チェック
      --* -------------------------------------------------------------
      IF ( iv_inv_cust_code IS NULL ) THEN
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_application
                         ,iv_name         =>  cv_msg_bill_account  --「請求先顧客コード」
                       );
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_application
                        ,iv_name          =>  cv_msg_param_err  --必須入力パラメータ未設定エラー
                        ,iv_token_name1   =>  cv_tkn_in_param
                        ,iv_token_value1  =>  lv_tkn_name
                      );
        RAISE global_api_expt;
      END IF;
      --* -------------------------------------------------------------
      --  送信日の必須チェック
      --* -------------------------------------------------------------
      IF ( iv_send_date IS NULL ) THEN
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_application
                         ,iv_name         =>  cv_msg_send_date  --「送信日」
                       );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_application
                       ,iv_name          =>  cv_msg_param_err  --必須入力パラメータ未設定エラー
                       ,iv_token_name1   =>  cv_tkn_in_param
                       ,iv_token_value1  =>  lv_tkn_name
                     );
        RAISE global_api_expt;
      END IF;
    END IF;
    --* -------------------------------------------------------------
    --  送信日の書式チェック
    --* -------------------------------------------------------------
    IF ( iv_send_date IS NOT NULL ) THEN
      --日付(YYYYMMDD)かどうかのチェック
      BEGIN
        SELECT  TO_DATE( iv_send_date, cv_date_format )
        INTO    ld_date_value
        FROM    DUAL;
      EXCEPTION
      -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lv_tkn_name := xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_application
                           ,iv_name         =>  cv_msg_send_date  --「送信日」
                         );
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_application
                         ,iv_name          =>  cv_msg_date_err  --日付書式エラー
                         ,iv_token_name1   =>  cv_tkn_para_d
                         ,iv_token_value1  =>  lv_tkn_name
                       );
          lv_errbuf  := SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
  EXCEPTION
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
  END input_param_check;
--
  /**********************************************************************************
   * Procedure Name   : get_custom_data
   * Description      : 処理対象顧客取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_custom_data(
    iv_inv_cust_code    IN  VARCHAR2,     --   請求先顧客コード
/* 2009/04/15 Add Start */
    iv_sales_exp_ptn    IN  VARCHAR2,     --   EDI販売実績処理パターン
/* 2009/04/15 Add End   */
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_custom_data'; -- プログラム名
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
    lv_tkn_name1  VARCHAR2(50)  DEFAULT NULL;  --トークン取得用1
    lv_tkn_name2  VARCHAR2(50)  DEFAULT NULL;  --トークン取得用2
--
    -- *** ローカル・カーソル ***
--
    --対象顧客取得カーソル(チェーン店単位)
    CURSOR chain_store_cur
    IS
      SELECT  xlvv.description         chain_store_code  --チェーン店
             ,MAX( xlvv.attribute1 )   process_pattern   --処理パターン
      FROM    xxcos_lookup_values_v  xlvv
      WHERE   xlvv.lookup_type = cv_lkt_sales_edi_cust  --請求先顧客コード
      AND     (
                ( xlvv.start_date_active IS NULL )
                OR
                ( xlvv.start_date_active <= cd_process_date )
              )
      AND     (
                ( xlvv.end_date_active   IS NULL )
                OR
                ( xlvv.end_date_active >= cd_process_date )
              )  -- 業務日付がFROM-TO内
      AND     ( 
                ( iv_inv_cust_code IS NOT NULL AND xlvv.lookup_code = iv_inv_cust_code )
                OR
                ( iv_inv_cust_code IS NULL )
              )  --パラメータの請求先顧客がある場合はクイックコードと同じ値のみ
/* 2009/04/15 Add Start */
      AND     (
                ( iv_sales_exp_ptn IS NOT NULL AND xlvv.attribute1 = iv_sales_exp_ptn )
                OR
                ( iv_sales_exp_ptn IS NULL )
              )  --パラメータのEDI販売実績処理パターンがある場合は同一チェーン店のみ(作成)
/* 2009/04/15 Add End   */
      GROUP BY
              xlvv.description
      ;
--
    -- *** ローカル・レコード ***
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
    OPEN chain_store_cur;
    FETCH chain_store_cur BULK COLLECT INTO gt_chain_store;
    gn_chain_store_cnt := chain_store_cur%ROWCOUNT;  --対象顧客(チェーン店)件数取得
    CLOSE chain_store_cur;
    --取得件数のチェック
    IF ( gn_chain_store_cnt = cn_0 ) THEN
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_bill_account  --「請求先顧客コード」
                      );
      lv_tkn_name2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_table_tkn1  --「クイックコード」
                      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --アプリケーション
                     ,iv_name         => cv_msg_mst_chk_err --マスタチェックエラー
                     ,iv_token_name1  => cv_tkn_column      --トークンコード１
                     ,iv_token_value1 => lv_tkn_name1       --請求先顧客コード
                     ,iv_token_name2  => cv_tkn_table       --トークンコード２
                     ,iv_token_value2 => lv_tkn_name2       --クイックコードテーブル
                   );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END get_custom_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-3)
   ***********************************************************************************/
  PROCEDURE init(
/* 2010/03/16 Ver1.10 Add Start */
    iv_run_class        IN  VARCHAR2,     --   実行区分
/* 2010/03/16 Ver1.10 Add End   */
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    lv_param_msg      VARCHAR2(5000)  DEFAULT NULL;  --パラメーター出力用
    lv_tkn_name1      VARCHAR2(50)    DEFAULT NULL;  --トークン取得用1
    lv_tkn_name2      VARCHAR2(50)    DEFAULT NULL;  --トークン取得用2
    ln_err_chk        NUMBER(1)       DEFAULT 0;     --プロファイルエラーチェック用
    lv_err_msg        VARCHAR2(5000)  DEFAULT NULL;  --プロファイルエラー出力用(取得エラーごとに出力する為)
    lv_l_meaning      xxcos_lookup_values_v.meaning%TYPE  DEFAULT NULL;  --クイックコード条件取得用
    lv_dummy          VARCHAR2(1)     DEFAULT NULL;  --レイアウト定義のCSVヘッダー用(ファイルタイプが固定長なので使用されない)
--
    -- *** ローカル・カーソル ***
    --非在庫品取得
    CURSOR no_inv_item_cur
    IS
      SELECT   xlvv.lookup_code lookup_code
/* 2010/03/16 Ver1.10 Mod Start */
--      FROM     fnd_lookup_values_vl  xlvv
      FROM     xxcos_lookup_values_v  xlvv
/* 2010/03/16 Ver1.10 Mod End   */
      WHERE    xlvv.lookup_type  = cv_lkt_no_inv_item
      AND      xlvv.attribute1   = cv_n  --エラー品目以外
/* 2010/03/16 Ver1.10 Add Start */
      AND      cd_process_date   BETWEEN NVL( xlvv.start_date_active, gd_min_date )
                                 AND     NVL( xlvv.end_date_active,   gd_max_date )
                                         -- 業務日付がFROM-TO内
/* 2010/03/16 Ver1.10 Add End   */
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
--
    --==============================================================
    --システム日付取得
    --==============================================================
    gv_f_o_date := TO_CHAR( cd_sysdate, cv_date_format );  --処理日
    gv_f_o_time := TO_CHAR( cd_sysdate, cv_time_format );  --処理時刻
    --==============================================================
    --プロファイル情報の取得
    --==============================================================
    gv_if_header             := FND_PROFILE.VALUE( cv_prf_if_header );      --ヘッダレコード区分
    gv_if_data               := FND_PROFILE.VALUE( cv_prf_if_data );        --データレコード区分
    gv_if_footer             := FND_PROFILE.VALUE( cv_prf_if_footer );      --フッタレコード区分
    gv_utl_m_line            := FND_PROFILE.VALUE( cv_prf_utl_m_line );     --EDI最大レコード長
    gv_outbound_d            := FND_PROFILE.VALUE( cv_prf_outbound_d );     --ディレクトリパス
    gv_dept_code             := FND_PROFILE.VALUE( cv_prf_dept_code );      --業務管理部コード
    gv_prf_def_item_rate     := FND_PROFILE.VALUE( cv_prf_def_item_rate );  --EDIデフォルト歩率
    gv_prf_organization_code := FND_PROFILE.VALUE( cv_prf_orga_code1  );    --在庫組織コードの取得
    gn_org_id                := FND_PROFILE.VALUE( cv_prf_org_id );         --営業単位の取得
/* 2010/03/16 Ver1.10 Add Start */
    gd_min_date              := TO_DATE( FND_PROFILE.VALUE( cv_prf_min_date ), cv_date_format_sl ); --MAX日付
    gd_max_date              := TO_DATE( FND_PROFILE.VALUE( cv_prf_max_date ), cv_date_format_sl ); --MAX日付
    gn_edi_trg_hold_m        := ABS( TO_NUMBER( FND_PROFILE.VALUE( cv_prf_trg_hold_m ) ) ); --EDI販売実績対象保持月数
--
    --実行区分 「作成」の場合
    IF ( iv_run_class = gv_run_class_cd_create ) THEN
/* 2010/03/16 Ver1.10 Add End   */
      --==================================
      --プロファイル情報のチェック
      --==================================
      --ヘッダレコード区分のチェック
      IF ( gv_if_header IS NULL ) THEN
        --トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_if_h  --「XXCCP:IFレコード区分_ヘッダ」
                        );
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --アプリケーション
                        ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                        ,iv_token_name1  => cv_tkn_prf      --トークンコード１
                        ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
      --データレコード区分のチェック
      IF ( gv_if_data IS NULL ) THEN
        --トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_if_d  --「XXCCP:IFレコード区分_データ」
                        );
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --アプリケーション
                        ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                        ,iv_token_name1  => cv_tkn_prf      --トークンコード１
                        ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
      --フッタレコード区分のチェック
      IF ( gv_if_footer IS NULL ) THEN
        --トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_if_f  --「XXCCP:IFレコード区分_フッタ」
                        );
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --アプリケーション
                        ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                        ,iv_token_name1  => cv_tkn_prf      --トークンコード１
                        ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
      --EDI最大レコード長のチェック
      IF ( gv_utl_m_line IS NULL ) THEN
        --トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_utl_m  --「XXCOS:UTL_MAX行サイズ」
                        );
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --アプリケーション
                        ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                        ,iv_token_name1  => cv_tkn_prf      --トークンコード１
                        ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
      --ディレクトリパスのチェック
      IF ( gv_outbound_d IS NULL ) THEN
        --トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_out_d  --「XXCOS:受注系アウトバウンド用ディレクトリパス」
                        );
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --アプリケーション
                        ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                        ,iv_token_name1  => cv_tkn_prf      --トークンコード１
                        ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
      --業務管理部コードのチェック
      IF ( gv_dept_code IS NULL ) THEN
        --トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_dept_c  --「XXCOS:業務管理部コード」
                        );
        --メッセージ取得
        lv_err_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application  --アプリケーション
                    ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                    ,iv_token_name1  => cv_tkn_prf      --トークンコード１
                    ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                   );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
      -- 在庫組織コードのチェック
      IF ( gv_prf_organization_code IS NULL ) THEN
        -- 在庫組織コード
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application => cv_application
                          ,iv_name        => cv_msg_orga_code  --「XXCOI:在庫組織コード」
                        );
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_application  --アプリケーション
                       ,iv_name         =>  cv_msg_prf_err  --プロファイル取得エラー
                       ,iv_token_name1  =>  cv_tkn_prf      --トークンコード１
                       ,iv_token_value1 =>  lv_tkn_name1    --プロファイル名
                     );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
      --EDIデフォルト歩率のチェック
      IF ( gv_prf_def_item_rate IS NULL ) THEN
        --トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_edi_r  --「XXCOS:EDIデフォルト歩率」
                        );
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --アプリケーション
                        ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                        ,iv_token_name1  => cv_tkn_prf      --トークンコード１
                        ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
      --営業単位のチェック
      IF  ( gn_org_id IS NULL )   THEN
        --トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application
                          ,iv_name         =>  cv_msg_org_id
                        );
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_application
                        ,iv_name          =>  cv_msg_prf_err
                        ,iv_token_name1   =>  cv_tkn_profile
                        ,iv_token_value1  =>  lv_tkn_name1
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
/* 2010/03/16 Ver1.10 Add Start */
      -- MIN日付
      IF ( gd_min_date IS NULL ) THEN
        -- トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application 
                           ,iv_name         => cv_msg_prf_min_d
                         );
        -- メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_prf_err
                        ,iv_token_name1  => cv_tkn_profile
                        ,iv_token_value1 => lv_tkn_name1
                      );
        -- メッセージに出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  -- エラー有り
      END IF;
      -- MAX日付
      IF ( gd_max_date IS NULL ) THEN
        -- トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_prf_max_d
                         );
        -- メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_prf_err
                        ,iv_token_name1  => cv_tkn_profile
                        ,iv_token_value1 => lv_tkn_name1
                      );
        -- メッセージに出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  -- エラー有り
      END IF;
/* 2010/03/16 Ver1.10 Add End   */
      --==================================
      -- データ種情報(マスタ情報取得)
      --==================================
      BEGIN
        SELECT  xlvv.meaning     meaning     --データ種
               ,xlvv.attribute1  attribute1  --IF元業務系列コード
        INTO    gt_data_type_code
               ,gt_from_series
        FROM    xxcos_lookup_values_v xlvv
        WHERE   xlvv.lookup_type  = cv_lkt_data_type_code  --データ種
        AND     xlvv.lookup_code  = cv_lkc_data_type_code  --「180」
        AND     (
                  ( xlvv.start_date_active IS NULL )
                  OR
                  ( xlvv.start_date_active <= cd_process_date )
                )
        AND     (
                  ( xlvv.end_date_active   IS NULL )
                  OR
                  ( xlvv.end_date_active >= cd_process_date )
                )  -- 業務日付がFROM-TO内
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tkn_name1 := xxccp_common_pkg.get_msg(
                             iv_application =>  cv_application
                            ,iv_name        =>  cv_msg_data_type_c  --「データ種コード」
                          );
          lv_tkn_name2 := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_table_tkn1   --「クイックコード」
                          );
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     --アプリケーション
                          ,iv_name         => cv_msg_mst_chk_err --マスタチェックエラー
                          ,iv_token_name1  => cv_tkn_column      --トークンコード１
                          ,iv_token_value1 => lv_tkn_name1       --データ種コード
                          ,iv_token_name2  => cv_tkn_table       --トークンコード２
                          ,iv_token_value2 => lv_tkn_name2       --クイックコードテーブル
                        );
          --メッセージに出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  --エラー有り
      END;
      --==================================
      -- EDI媒体区分
      --==================================
      BEGIN
        --メッセージより内容を取得
        lv_l_meaning := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_edi_m_class_c  --クイックコード取得条件(EDI媒体区分)
                        );
        --クイックコード取得
        SELECT xlvv.lookup_code lookup_code
        INTO   gt_edi_media_class
        FROM   xxcos_lookup_values_v xlvv
        WHERE  xlvv.lookup_type   = cv_lkt_edi_m_class  --EDI媒体区分
        AND    xlvv.meaning       = lv_l_meaning        --「EDI」
        AND    (
                 ( xlvv.start_date_active IS NULL )
                 OR
                 ( xlvv.start_date_active <= cd_process_date )
               )
        AND    (
                 ( xlvv.end_date_active IS NULL )
                 OR
                 ( xlvv.end_date_active >= cd_process_date )
               )  -- 業務日付がFROM-TO内
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tkn_name1 := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_edi_m_class_n  --「EDI媒体区分」
                          );
          lv_tkn_name2 := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_table_tkn1     --「クイックコード」
                          );
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     --アプリケーション
                          ,iv_name         => cv_msg_mst_chk_err --マスタチェックエラー
                          ,iv_token_name1  => cv_tkn_column      --トークンコード１
                          ,iv_token_value1 => lv_tkn_name1       --データ種コード
                          ,iv_token_name2  => cv_tkn_table       --トークンコード２
                          ,iv_token_value2 => lv_tkn_name2       --クイックコードテーブル
                        );
          --メッセージに出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  --エラー有り
      END;
      --==================================
      -- 売上区分（協賛＝５）取得
      --==================================
      BEGIN
        --メッセージより内容を取得
        lv_l_meaning := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_sales_class_c  --クイックコード取得条件(売上区分)
                        );
        --クイックコード取得
        SELECT xlvv.lookup_code lookup_code
        INTO   gt_edi_seales_class
/* 2010/03/16 Ver1.10 Mod Start */
--      FROM   fnd_lookup_values_vl xlvv
        FROM   xxcos_lookup_values_v xlvv
/* 2010/03/16 Ver1.10 Mod End   */
        WHERE  xlvv.lookup_type   = cv_lkt_edi_sale_class  --売上区分
        AND    xlvv.meaning       = lv_l_meaning           --「協賛」
/* 2010/03/16 Ver1.10 Add Start */
        AND     (
                  ( xlvv.start_date_active IS NULL )
                  OR
                  ( xlvv.start_date_active <= cd_process_date )
                )
        AND     (
                  ( xlvv.end_date_active   IS NULL )
                  OR
                  ( xlvv.end_date_active >= cd_process_date )
                )  -- 業務日付がFROM-TO内
/* 2010/03/16 Ver1.10 Add End   */
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tkn_name1 := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_sales_class  --「売上区分」
                          );
          lv_tkn_name2 := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_table_tkn1   --「クイックコード」
                          );
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application      --アプリケーション
                          ,iv_name         => cv_msg_mst_chk_err  --マスタチェックエラー
                          ,iv_token_name1  => cv_tkn_column       --トークンコード１
                          ,iv_token_value1 => lv_tkn_name1        --クイックコード
                          ,iv_token_name2  => cv_tkn_table        --トークンコード２
                          ,iv_token_value2 => lv_tkn_name2        --売上区分
                        );
          --メッセージに出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  --エラー有り
      END;
      --==================================
      -- 非在庫品取得
      --==================================
      OPEN no_inv_item_cur;
      FETCH no_inv_item_cur BULK COLLECT INTO gt_no_inv_item;
      gn_no_inv_item_cnt := no_inv_item_cur%ROWCOUNT;
      CLOSE no_inv_item_cur;
      --==================================
      --拠点情報の取得
      --==================================
      BEGIN
        SELECT  hp.party_name  sales_base_name --拠点名
        INTO    gt_sales_base_name
        FROM    hz_cust_accounts  hca  --拠点(顧客)
               ,hz_parties        hp   --拠点(パーティ)
        WHERE   hca.party_id             = hp.party_id   --結合(拠点(顧客) = 拠点(パーティ))
        AND     hca.account_number       = gv_dept_code  --業務管理部コード
        AND     hca.customer_class_code  = cv_1          --顧客区分=1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --メッセージ編集
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        --アプリケーション
                          ,iv_name         => cv_msg_base_code_err --拠点情報取得エラー
                          ,iv_token_name1  => cv_base_code1        --トークンコード１
                          ,iv_token_value1 => gv_dept_code         --業務管理部コード
                        );
          --メッセージに出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  --エラー有り
      END;
      --==================================
      -- 在庫組織ＩＤの取得
      --==================================
      --取得
      gv_prf_organization_id := xxcoi_common_pkg.get_organization_id( gv_prf_organization_code );
      --取得チェック
      IF ( gv_prf_organization_id  IS NULL )   THEN
        lv_err_msg :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_application            --アプリケーション
                         ,iv_name         =>  gv_msg_orga_id_err        --在庫組織ID取得エラー
                         ,iv_token_name1  =>  cv_tkn_org_code           --トークンコード１
                         ,iv_token_value1 =>  gv_prf_organization_code  --在庫組織コード
                       );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
      --==============================================================
      --ファイルレイアウト情報の取得
      --==============================================================
      xxcos_common2_pkg.get_layout_info(
         iv_file_type        => cv_0                --ファイル形式(固定長)
        ,iv_layout_class     => cv_0                --情報区分(受注系)
        ,ov_data_type_table  => gt_data_type_table  --データ型表
        ,ov_csv_header       => lv_dummy            --CSVヘッダ
        ,ov_errbuf           => lv_errbuf           --エラーメッセージ
        ,ov_retcode          => lv_retcode          --リターンコード
        ,ov_errmsg           => lv_errmsg           --ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application
                          ,iv_name         =>  cv_msg_layout    --「レイアウト定義情報」
                        );
          --メッセージ編集
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       --アプリケーション
                        ,iv_name         => cv_msg_file_inf_err  --レイアウト定義情報エラー
                        ,iv_token_name1  => cv_tkn_file_l        --トークンコード１
                        ,iv_token_value1 => lv_tkn_name1         --レイアウト定義情報
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
/* 2010/03/16 Ver1.10 Add Start */
    ELSIF ( iv_run_class = gv_run_class_cd_update ) THEN
      --EDI販売実績保持月数のチェック
      IF  ( gn_edi_trg_hold_m IS NULL )   THEN
        --トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application
                          ,iv_name         =>  cv_msg_prf_hold_m
                        );
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_application
                        ,iv_name          =>  cv_msg_prf_err
                        ,iv_token_name1   =>  cv_tkn_profile
                        ,iv_token_value1  =>  lv_tkn_name1
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --エラー有り
      END IF;
    END IF;
/* 2010/03/16 Ver1.10 Add End   */
    -- エラー判定
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_data_check_expt;
    END IF;
--
  EXCEPTION
    -- *** チェックエラー ****
    WHEN global_data_check_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      IF ( no_inv_item_cur%ISOPEN ) THEN
         CLOSE no_inv_item_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_header
   * Description      : ファイル初期処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_header(
    iv_chain_store_code  IN  fnd_lookup_values.description%TYPE,  --処理対象顧客のチェーン店コード
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_file_name      fnd_lookup_values.meaning%TYPE;     --ファイル名
    lv_parallel_num   fnd_lookup_values.attribute1%TYPE;  --並列処理番号
    lv_message        VARCHAR2(5000);                     --ファイル名メッセージ用
/* 2009/04/28 Ver1.3 Mod Start */
--    lv_header_output  VARCHAR2(1000) DEFAULT NULL;        --IFヘッダー出力用
    lv_header_output  VARCHAR2(5000) DEFAULT NULL;        --IFヘッダー出力用
/* 2009/04/28 Ver1.3 Mod End   */
    lv_tkn_name1      VARCHAR2(50);                       --トークン取得用１
    lv_tkn_name2      VARCHAR2(50);                       --トークン取得用２
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ファイル名取得
    --==============================================================
    BEGIN
      --クイックコード取得
      SELECT  xlvv.meaning     meaning     --EDI販売実績ファイル名
             ,xlvv.attribute1  attribute1  --並列処理番号
      INTO    lv_file_name
             ,lv_parallel_num
      FROM    xxcos_lookup_values_v xlvv
      WHERE   xlvv.lookup_type   = cv_lkt_edi_filename  --EDI販売実績ファイル名
      AND     xlvv.lookup_code   = iv_chain_store_code  --チェーン店コード
      AND     (
                ( xlvv.start_date_active IS NULL )
                OR
                ( xlvv.start_date_active <= cd_process_date )
              )
      AND     (
                ( xlvv.end_date_active IS NULL )
                OR
                ( xlvv.end_date_active >= cd_process_date )
              )  -- 業務日付がFROM-TO内
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_in_file_name  --「ファイル名」
                        );
        lv_tkn_name2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_table_tkn1    --「クイックコード」
                        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application      --アプリケーション
                       ,iv_name         => cv_msg_mst_chk_err  --マスタチェックエラー
                       ,iv_token_name1  => cv_tkn_column       --トークンコード１
                       ,iv_token_value1 => lv_tkn_name1        --クイックコード
                       ,iv_token_name2  => cv_tkn_table          --トークンコード２
                       ,iv_token_value2 => lv_tkn_name2        --ファイル名
                     );
        RAISE global_api_expt;
    END;
--
--****************　2009/07/07   N.Maeda  Ver1.5   ADD   START  *********************************************--
   gt_parallel_num := lv_parallel_num;
--****************　2009/07/07   N.Maeda  Ver1.5   ADD    END   *********************************************--
--
    --==============================================================
    -- ファイル名出力
    --==============================================================
    lv_message := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application    --アプリケーション
                    ,iv_name         => cv_msg_file_name  --ファイル名出力
                    ,iv_token_name1  => cv_tkn_file_n     --トークンコード１
                    ,iv_token_value1 => lv_file_name      --ファイル名
                  );
    --ファイル名をメッセージに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_message
    );
    --空白出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => ''
    );
    --==============================================================
    --EDIチェーン店情報の取得
    --==============================================================
    BEGIN
      SELECT  hp.party_name                  edi_chain_name      --EDIチェーン店名
             ,hp.organization_name_phonetic  edi_chain_phonetic  --EDIチェーン店名カナ
      INTO    gt_edi_chain_name
             ,gt_edi_chain_name_phonetic
      FROM    hz_cust_accounts     hca  -- 顧客マスタ
             ,xxcmm_cust_accounts  xca  -- 顧客アドオンマスタ
             ,hz_parties           hp   -- パーティマスタ
      WHERE   hca.cust_account_id       =  xca.customer_id      -- 結合(顧客 = 顧客アドオン)
      AND     hca.party_id              =  hp.party_id          -- 結合(顧客 = パーティ)
      AND     xca.edi_chain_code        =  iv_chain_store_code  -- (チェーン店)
      AND     hca.customer_class_code   =  cv_cust_code_chain   -- 顧客区分(チェーン店)
      AND     hca.status                =  cv_status_a          --ステータス(有効)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application        --アプリケーション
                       ,iv_name         => cv_msg_edi_c_inf_err  --EDIチェーン店情報取得エラー
                       ,iv_token_name1  => cv_tkn_chain_s        --トークンコード１
                       ,iv_token_value1 => iv_chain_store_code   --EDIチェーン店コード
                     );
        RAISE global_api_expt;
    END;
    --==============================================================
    -- ファイルオープン
    --==============================================================
    BEGIN
      gt_f_handle := UTL_FILE.FOPEN(
                        location      =>  gv_outbound_d  --アウトバウンド用ディレクトリパス
                       ,filename      =>  lv_file_name   --ファイル名
                       ,open_mode     =>  cv_w           --オープンモード
                       ,max_linesize  =>  gv_utl_m_line  --MAXサイズ
                     );
    EXCEPTION
      WHEN OTHERS THEN
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application        --アプリケーション
                       ,iv_name         => cv_msg_file_o_err     --ファイルオープンエラー
                       ,iv_token_name1  => cv_tkn_file_n         --トークンコード１
                       ,iv_token_value1 => lv_file_name          --販売実績ファイル
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
    --==============================================================
    --共通関数呼び出し
    --==============================================================
    --EDIヘッダ・フッタ付与
    xxccp_ifcommon_pkg.add_edi_header_footer(
      iv_add_area        =>  gv_if_header         --付与区分
     ,iv_from_series     =>  gt_from_series       --IF元業務系列コード
     ,iv_base_code       =>  gv_dept_code         --拠点コード(業務処理部コード)
     ,iv_base_name       =>  gt_sales_base_name   --拠点名称
     ,iv_chain_code      =>  iv_chain_store_code  --チェーン店コード
     ,iv_chain_name      =>  gt_edi_chain_name    --チェーン店名称
     ,iv_data_kind       =>  gt_data_type_code    --データ種コード
     ,iv_row_number      =>  lv_parallel_num      --並列処理番号
     ,in_num_of_records  =>  NULL                 --レコード件数
     ,ov_retcode         =>  lv_retcode
     ,ov_output          =>  lv_header_output
     ,ov_errbuf          =>  lv_errbuf
     ,ov_errmsg          =>  lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application   --アプリケーション
                     ,iv_name         => cv_msg_proc_err  --共通関数エラー
                     ,iv_token_name1  => cv_tkn_err_m     --トークンコード１
                     ,iv_token_value1 => lv_errmsg        --共通関数のエラーメッセージ
                   );
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --ファイル出力
    --==============================================================
    --ヘッダ出力
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --ファイルハンドル
     ,buffer => lv_header_output  --出力文字(ヘッダ)
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
   * Procedure Name   : get_sale_data
   * Description      : 販売実績情報抽出(A-5)
   ***********************************************************************************/
  PROCEDURE get_sale_data(
    iv_chain_store_code  IN  fnd_lookup_values.description%TYPE,  --処理対象顧客のチェーン店コード
/* 2009/04/15 Del Start */
--    iv_inv_cust_code     IN  VARCHAR2,                            --請求先顧客コード
/* 2009/04/15 Del End   */
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sale_data'; -- プログラム名
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
    lv_tkn_name  VARCHAR2(50) DEFAULT NULL;  --トークン取得用１
/* 2009/07/29 Ver1.5 Add Start */
    lt_indv_shipping_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --出荷数量(バラ)
    lt_case_shipping_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --出荷数量(ケース)
    lt_ball_shipping_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --出荷数量(ボール)
    lt_indv_stockout_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --欠品数量(バラ)
    lt_case_stockout_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --欠品数量(ケース)
    lt_ball_stockout_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --欠品数量(ボール)
    lt_sum_stockout_qty   xxcos_sales_exp_lines.standard_qty%TYPE;           --欠品数量(合計、バラ)
    lv_breck_key          VARCHAR2(21); --伝票計ブレークキー(顧客【納品先】+納品伝票番号)
    ln_no_inv_item_flag   NUMBER(1);    --非在庫品フラグ
/* 2009/07/29 Ver1.5 Add End   */
--
    -- *** ローカル・カーソル ***
    --==============================================================
    --販売実績の対象データ取得カーソル
    --==============================================================
    CURSOR sale_data_cur
    IS
/* 2009/11/24 Ver1.8 Mod Start */
      SELECT  /*+ 
                 LEADING(xlvv xcchv xseh xsel iimb)
                 INDEX(xseh XXCOS_SALES_EXP_HEADERS_N03)
                 USE_NL(xhpc.msib xhpc.mic xhpc.mp xhpc.mcsb xhpc.mcst xhpc.mcb xhpc.mct)
                 USE_NL(xseh xsel1)
                 USE_NL(xseh xsel)
                 USE_NL(xsel iimb msib ximb xhpc)
                 USE_NL(xseh hcam hcan)
                 USE_NL(xseh xlvv xcchv)
              */
              xseh.sales_exp_header_id                header_id                    --販売実績ヘッダID
--      SELECT  xseh.sales_exp_header_id                header_id                    --販売実績ヘッダID
/* 2009/11/24 Ver1.8 Mod End */
             ,xsel.sales_exp_line_id                  line_id                      --販売実績明細ID
             ,xseh.sales_base_code                    sales_base_code              --売上拠点コード
             ,hcam.sales_base_name                    sales_base_name              --売上拠点名
             ,hcam.sales_base_phonetic                sales_base_phonetic          --売上拠点名カナ
-- 2010/06/22 S.Arizumi Ver1.11 Mod Start
--/* 2009/11/27 Ver1.9 Add Start */
--             ,xseh.order_invoice_number               order_invoice_number         --注文伝票番号
--/* 2009/11/27 Ver1.9 Add End   */
             ,CASE WHEN     xlvv.attribute1   <>  cv_5                            --処理パターン：スマイル 以外
                        AND xseh.create_class IN( cv_3                            --作成元区分  ：VD納品データ作成
                                                 ,cv_4                            --作成元区分  ：出荷確認処理(HHT納品データ)
                                                 ,cv_5                            --作成元区分  ：返品実績データ作成(HHT)
                                              )
                THEN NVL( xseh.order_invoice_number
                         ,xseh.invoice_classification_code || xseh.invoice_class
                     )
                ELSE xseh.order_invoice_number
              END                                     order_invoice_number         --注文伝票番号
-- 2010/06/22 S.Arizumi Ver1.11 Mod End
             ,xseh.ship_to_customer_code              ship_to_customer_code        --顧客【納品先】
             ,xcchv.ship_account_name                 ship_account_name            --納品先顧客名
             ,hcan.organization_name_phonetic         organization_name_phonetic   --納品先顧客名カナ
             ,xseh.orig_delivery_date                 orig_delivery_date           --オリジナル納品日
             ,xseh.invoice_class                      invoice_class                --伝票区分
             ,xseh.invoice_classification_code        invoice_classification_code  --伝票分類コード
             ,xseh.dlv_invoice_number                 dlv_invoice_number           --納品伝票番号
             ,hcan.address                            address                      --届け先住所(漢字)
             ,rtv.due_cutoff_day                      sales_exp_day                --請求開始日
             ,xseh.orig_inspect_date                  orig_inspect_date            --オリジナル検収日
             ,xseh.dlv_invoice_class                  dlv_invoice_class            --納品伝票区分
/* 2009/11/05 Ver1.7 Add Start */
--             ,xcchv.bill_cred_rec_code2               bill_cred_rec_code2          --売掛コード２（事業所）
             ,( SELECT ship_hsua.attribute5  attribute5
                FROM   hz_cust_acct_sites    ship_hasa                             --顧客所在地(出荷先)
                     , hz_cust_site_uses     ship_hsua                             --顧客使用目的
                WHERE  ship_hasa.cust_account_id   = xcchv.ship_account_id
                AND    ship_hsua.cust_acct_site_id = ship_hasa.cust_acct_site_id
                AND    ship_hsua.site_use_code     = cv_bill_to --'BILL_TO'
                AND    ship_hsua.primary_flag      = cv_y       --'Y'
/* 2010/03/16 Ver1.10 Add Start */
                AND    ship_hasa.org_id            = gn_org_id
                AND    ship_hasa.status            = cv_status_a  --'A'
                AND    ship_hsua.status            = cv_status_a  --'A'
/* 2010/03/16 Ver1.10 Add End   */
              )                                       bill_cred_rec_code2          --売掛コード２（事業所）
/* 2009/11/05 Ver1.7 Add End   */
             ,xsel.dlv_invoice_line_number            dlv_invoice_line_number      --納品明細番号
             ,xsel.item_code                          item_code                    --品目コード
             ,iimb.attribute21                        jan_code                     --JANコード
             ,iimb.attribute22                        itf_code                     --ITFコード
             ,xhpc.item_div_h_code                    item_div_code                --本社商品区分
             ,ximb.item_name                          item_name                    --品目摘要
             ,SUBSTRB( ximb.item_name_alt, cn_1, cn_15 )
                                                      item_phonetic1               --品目名カナ１
             ,SUBSTRB( ximb.item_name_alt, cn_16, cn_15 )
                                                      item_phonetic2               --品目名カナ２
             ,iimb.attribute11                        case_inc_num                 --ケース入数
             ,xsib.bowl_inc_num                       bowl_inc_num                 --ボール入数
             ,xsel.standard_qty                       standard_qty                 --基準数量
             ,xsel.standard_unit_price                standard_unit_price          --基準単価
             ,xsel.sale_amount                        sale_amount                  --売上金額
             ,DECODE(  xsel.sales_class
                      ,gt_edi_seales_class, xsel.sales_class
                      ,TO_CHAR(NULL) )                sales_class                  --売上区分
             ,xsel1.sum_standard_qty                  sum_standard_qty             --基準数量サマリー
             ,xsel1.sum_sale_amount                   sum_sale_amount              --売上金額サマリー
             ,xcchv.bill_cred_rec_code1               bill_cred_rec_code1          --売掛コード１（請求書）
             ,xcchv.bill_cred_rec_code3               bill_cred_rec_code3          --売掛コード３（その他）
--****************　2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
             ,hcan.edi_forward_number                 edi_forward_number           --EDI納品伝票追番
--****************　2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
-- 2009/06/25 M.Sano Ver.1.5 add Start
             ,xsel.standard_uom_code                  standard_uom_code            --基準数量
-- 2009/06/25 M.Sano Ver.1.5 add End
      FROM    xxcos_lookup_values_v     xlvv   --請求先顧客コード(顧客単位)
             ,xxcfr_cust_hierarchy_v    xcchv  --顧客マスタ階層ビュー
             ,ra_terms_vl               rtv    --支払条件
             ,xxcos_sales_exp_headers   xseh   --販売実績ヘッダ
/* 2009/11/24 Ver1.8 Mod Start */
             ,( SELECT  /*+ 
                          index(hca HZ_CUST_ACCOUNTS_U2)
                          USE_NL(hca hp xca_2 hcasa hcsua hps hl)
                        */
                        hca.account_number             account_number              --納品顧客コード
--             ,( SELECT  hca.account_number             account_number              --納品顧客コード
/* 2009/11/24 Ver1.8 Mod End */
                       ,hp.organization_name_phonetic  organization_name_phonetic  --納品先顧客名カナ
                       ,hl.state || hl.city || hl.address1 || hl.address2
                                                       address                     --都道府県+市区+住所1+住所2
--****************　2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
                       ,xca_2.edi_forward_number       edi_forward_number
--****************　2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
                FROM    hz_cust_accounts       hca
                       ,hz_parties             hp
                       ,hz_cust_acct_sites_all hcasa
                       ,hz_cust_site_uses_all  hcsua
                       ,hz_party_sites         hps
                       ,hz_locations           hl
--****************　2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
                       ,xxcmm_cust_accounts    xca_2
--****************　2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
                WHERE   hca.party_id            =  hp.party_id
                AND     hca.cust_account_id     =  hcasa.cust_account_id
                AND     hcasa.org_id            =  gn_org_id
                AND     hcasa.cust_acct_site_id =  hcsua.cust_acct_site_id
                AND     hcasa.org_id            =  hcsua.org_id
                AND     hcsua.site_use_code     =  cv_cust_site_use_code
                AND     hcasa.party_site_id     =  hps.party_site_id
                AND     hps.location_id         =  hl.location_id
--****************　2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
                AND     xca_2.customer_id         =  hca.cust_account_id
--****************　2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
/* 2010/03/16 Ver1.10 Add Start */
                AND     hcsua.primary_flag      = cv_y         --'Y'
                AND     hcsua.status            = cv_status_a  --'A'
                AND     hcasa.status            = cv_status_a  --'A'
/* 2010/03/16 Ver1.10 Add End   */
              )                         hcan   --納品顧客
/* 2009/11/24 Ver1.8 Mod Start */
             ,( SELECT  /*+ 
                          index(hca HZ_CUST_ACCOUNTS_U2)
                          USE_NL(hca hp xca1)
                        */
                        hca.account_number             sales_base_code         --売上拠点コード
--             ,( SELECT  hca.account_number             sales_base_code         --売上拠点コード
/* 2009/11/24 Ver1.8 Mod End */
                       ,hp.party_name                  sales_base_name         --売上拠点名
                       ,hp.organization_name_phonetic  sales_base_phonetic     --売上拠点名カナ
                FROM    hz_cust_accounts        hca
                       ,hz_parties              hp
                       ,xxcmm_cust_accounts     xca1
                WHERE   hca.party_id            =  hp.party_id          --結合(拠点(顧客) = 拠点(パーティ))
                AND     hca.customer_class_code =  cv_1                 --売上拠点(顧客) 顧客区分=1
                AND     hca.cust_account_id     =  xca1.customer_id     --結合(顧客 = 顧客追加)
              )                          hcam  --売上拠点
/* 2010/03/16 Ver1.10 Mod Start */
/* 2009/11/24 Ver1.8 Mod Start */
--             ,( SELECT  /*+ 
--                          INDEX(xseh XXCOS_SALES_EXP_HEADERS_N03)
--                          USE_NL(xseh xsel xlvv)
--                        */
             ,( SELECT  /*+
                          LEADING(xlvv2 xcchv xseh xsel xlvv)
                          INDEX(xseh XXCOS_SALES_EXP_HEADERS_N03)
                          USE_NL(xlvv2 xcchv xseh xsel xlvv)
                        */
/* 2010/03/16 Ver1.10 Mod End   */
                        xseh.ship_to_customer_code   ship_to_customer_code
--             ,( SELECT  xseh.ship_to_customer_code   ship_to_customer_code
/* 2009/11/24 Ver1.8 Mod End */
                       ,xseh.dlv_invoice_number      dlv_invoice_number
                       ,SUM( DECODE(  xlvv.lookup_code
                                     ,'', xsel.standard_qty
                                     ,cn_0 )
                        )                            sum_standard_qty     --基準数量サマリー(非在庫品は0とする)
                       ,SUM( xsel.sale_amount )      sum_sale_amount      --売上金額サマリー
                FROM    xxcos_sales_exp_headers  xseh
                       ,xxcos_sales_exp_lines    xsel
/* 2010/03/16 Ver1.10 Mod Start */
--                       ,fnd_lookup_values_vl     xlvv
                       ,xxcos_lookup_values_v    xlvv
                       ,xxcos_lookup_values_v    xlvv2   --請求先顧客コード(顧客単位)
                       ,xxcfr_cust_hierarchy_v   xcchv   --顧客マスタ階層ビュー
/* 2010/03/16 Ver1.10 Mod End   */
                WHERE   xseh.sales_exp_header_id = xsel.sales_exp_header_id
                AND     xseh.edi_interface_flag  = cv_n                         --未送信のみ
                AND     xlvv.lookup_type(+)      = cv_lkt_no_inv_item
                AND     xlvv.lookup_code(+)      = xsel.item_code
/* 2010/03/16 Ver1.10 Add Start */
                AND     cd_process_date BETWEEN NVL( xlvv.start_date_active(+), gd_min_date )
                                        AND     NVL( xlvv.end_date_active(+),   gd_max_date )
                AND     TRUNC( xseh.orig_delivery_date ) BETWEEN TO_DATE( xlvv2.attribute2, cv_date_format_sl )
                                                         AND     TO_DATE( xlvv2.attribute3, cv_date_format_sl )
                                                                                --オリジナル納品日がデータ取得日付範囲内
                AND     xcchv.ship_account_number = xseh.ship_to_customer_code
                AND     xlvv2.lookup_code         = xcchv.bill_account_number
                AND     TRUNC( xseh.orig_delivery_date ) BETWEEN NVL( xlvv2.start_date_active, gd_min_date )
                                                         AND     NVL( xlvv2.end_date_active,   gd_max_date )
                AND     xlvv2.lookup_type         = cv_lkt_sales_edi_cust       --クイックコードの請求先顧客コード
                AND     xlvv2.description         = iv_chain_store_code         --パラメータのチェーン店コード
/* 2010/03/16 Ver1.10 Add End   */
                GROUP BY
                        xseh.ship_to_customer_code
                       ,xseh.dlv_invoice_number
              )                         xsel1  --販売実績明細(サマリ)
             ,xxcos_sales_exp_lines     xsel   --販売実績明細
             ,ic_item_mst_b             iimb   --OPM品目
             ,xxcmn_item_mst_b          ximb   --OPM品目アドオン
             ,mtl_system_items_b        msib   --Disc品目
             ,xxcmm_system_items_b      xsib   --Disc品目アドオン
             ,xxcos_head_prod_class_v   xhpc   --本社商品区分ビュー
/* 2009/11/24 Ver1.8 Mod Start */
      WHERE   msib.inventory_item_id     = xhpc.inventory_item_id   --結合(Disc品目=本社商品区分)
--      WHERE   msib.inventory_item_id     = xhpc.inventory_item_id(+)   --結合(Disc品目=本社商品区分)
/* 2009/11/24 Ver1.8 Mod End */
      AND     msib.organization_id       = gv_prf_organization_id      --在庫組織ID
      AND     msib.segment1              = xsib.item_code              --結合(Disc品目=Disc品目A)
      AND     iimb.item_no               = msib.segment1               --結合(OPM品目=Disc品目)
      AND     ( xseh.orig_delivery_date BETWEEN ximb.start_date_active AND  ximb.end_date_active )  --OPM品目Aの適用日FROM-TO
      AND     iimb.item_id               = ximb.item_id                --結合(OPM品目=OPM品目A)
      AND     xsel.item_code             = iimb.item_no                --結合(明細=OPM品目)
      AND     xseh.sales_exp_header_id   = xsel.sales_exp_header_id    --結合(ヘッダ=明細)
      AND     xseh.ship_to_customer_code = xsel1.ship_to_customer_code --結合(ヘッダ=明細サマリー1)
      AND     xseh.dlv_invoice_number    = xsel1.dlv_invoice_number    --結合(ヘッダ=明細サマリー2)
      AND     xseh.sales_base_code       = hcam.sales_base_code        --結合(ヘッダ=売上拠点)
      AND     xseh.ship_to_customer_code = hcan.account_number         --結合(ヘッダ=納品顧客)
/* 2010/03/16 Ver1.10 Add Start */
      AND     TRUNC( xseh.orig_delivery_date )  BETWEEN TO_DATE( xlvv.attribute2, cv_date_format_sl )
                                                AND     TO_DATE( xlvv.attribute3, cv_date_format_sl )
                                                                       --オリジナル納品日がデータ取得日付範囲内
      AND     TRUNC( xseh.orig_delivery_date )  BETWEEN NVL( xlvv.start_date_active, gd_min_date )
                                                AND     NVL( xlvv.end_date_active,   gd_max_date )
/* 2010/03/16 Ver1.10 Add End   */
      AND     xseh.edi_interface_flag    = cv_n                        --EDI送信済フラグ(未送信)
      AND     xcchv.ship_account_number  = xseh.ship_to_customer_code  --結合(顧客階層=ヘッダ)
      AND     xcchv.bill_payment_term_id = rtv.term_id                 --結合(顧客階層=支払条件)
      AND     xlvv.lookup_code           = xcchv.bill_account_number   --結合(ルックアップ=顧客階層)
      AND     xlvv.lookup_type           = cv_lkt_sales_edi_cust       --クイックコードの請求先顧客コード
      AND     xlvv.description           = iv_chain_store_code         --パラメータのチェーン店コード
/* 2009/04/15 Del Start */
--      AND     (
--                ( iv_inv_cust_code IS NULL )
--                OR
--                ( iv_inv_cust_code IS NOT NULL AND iv_inv_cust_code = xlvv.lookup_code )
--              )                                                        --パラメータの請求顧客がある場合は指定された請求顧客のみ
/* 2009/04/15 Del End   */
      ORDER BY
              xseh.ship_to_customer_code
             ,xseh.dlv_invoice_number
--************************************* 2009/05/28 T.Tominaga Var1.4 MOD START ******************************************
--             ,xsel.dlv_invoice_line_number
             ,xseh.sales_exp_header_id
             ,xsel.sales_exp_line_id
--************************************* 2009/05/28 T.Tominaga Var1.4 MOD END   ******************************************
      FOR UPDATE OF
-- ************ 2009/09/03 1.6 N.Maeda MOD START ********* --
              xseh.sales_exp_header_id NOWAIT
--              xseh.sales_exp_header_id
--             ,xsel.sales_exp_line_id NOWAIT
-- ************ 2009/09/03 1.6 N.Maeda MOD  END  ********* --
      ;
    -- *** ローカル・レコード ***
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
    --販売実績の対象データを取得
    --==============================================================
    --1チェーン店内処理変数の初期化
    gn_data_cnt       := cn_0;                 --件数初期化
    gt_edi_sales_data := gt_edi_sales_data_c;  --テーブル型初期化
    BEGIN
      --ロック確認、データの取得
      OPEN  sale_data_cur;
      FETCH sale_data_cur BULK COLLECT INTO gt_edi_sales_data;
      --対象件数取得
      gn_data_cnt := sale_data_cur%ROWCOUNT;
      CLOSE sale_data_cur;
--
    EXCEPTION
      -- *** ロックエラー ***
      WHEN lock_expt THEN
        --カーソルクローズ
        IF ( sale_data_cur%ISOPEN ) THEN
          CLOSE sale_data_cur;
        END IF;
        --トークン取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     --アプリケーション
                         ,iv_name         => cv_msg_table_tkn2  --販売実績ヘッダテーブル
                       );
        --メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_lock_err    --ロックエラー
                       ,iv_token_name1  => cv_tkn_table       --トークンコード１
                       ,iv_token_value1 => lv_tkn_name        --販売実績ヘッダテーブル
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
      --その他例外
      WHEN OTHERS THEN
        --トークン１取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     --アプリケーション
                         ,iv_name         => cv_msg_table_tkn2  --販売実績ヘッダテーブル
                       );
        --メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       --アプリケーション
                       ,iv_name         => cv_msg_data_get_err  --データ抽出エラー
                       ,iv_token_name1  => cv_tkn_table_n       --トークンコード１
                       ,iv_token_value1 => lv_tkn_name          --販売実績ヘッダテーブル
                       ,iv_token_name2  => cv_tkn_key           --トークンコード２
                       ,iv_token_value2 => iv_chain_store_code  --チェーン店コード
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
/* 2009/07/29 Ver1.5 Add Start */
--
    --伝票計の取得
    <<sum_qty_loop>>
    FOR i IN 1.. gn_data_cnt LOOP
--
      --ループ内変数の初期化
      ln_no_inv_item_flag  := cn_0;
      lt_indv_shipping_qty := cn_0;
      lt_case_shipping_qty := cn_0;
      lt_ball_shipping_qty := cn_0;
--
      --非在庫品が存在する場合
      IF ( gn_no_inv_item_cnt <> cn_0 ) THEN
        --非在庫品目のチェック
        <<no_item_check_loop>>
        FOR i2 IN 1.. gn_no_inv_item_cnt LOOP
          --明細品目が非在庫品目の場合
          IF ( gt_no_inv_item(i2) = gt_edi_sales_data(i).item_code ) THEN
            ln_no_inv_item_flag := cn_1;  --フラグを立てる
            EXIT;
          END IF;
        END LOOP no_item_check_loop;
      END IF;
--
      --非在庫品目以外の場合
      IF ( ln_no_inv_item_flag = cn_0 ) THEN
--
        -- 出荷数量を取得する。
        xxcos_common2_pkg.convert_quantity(
          iv_uom_code           => gt_edi_sales_data(i).standard_uom_code  --(IN)基準単位
         ,in_case_qty           => gt_edi_sales_data(i).case_inc_num       --(IN)ケース入数
         ,in_ball_qty           => gt_edi_sales_data(i).bowl_inc_num       --(IN)ボール入数
         ,in_sum_indv_order_qty => gt_edi_sales_data(i).standard_qty       --(IN)発注数量(合計・バラ)
         ,in_sum_shipping_qty   => gt_edi_sales_data(i).standard_qty       --(IN)出荷数量(合計・バラ)
         ,on_indv_shipping_qty  => lt_indv_shipping_qty                    --(OUT)出荷数量(バラ)
         ,on_case_shipping_qty  => lt_case_shipping_qty                    --(OUT)出荷数量(ケース)
         ,on_ball_shipping_qty  => lt_ball_shipping_qty                    --(OUT)出荷数量(ボール)
         ,on_indv_stockout_qty  => lt_indv_stockout_qty                    --(OUT)欠品数量(バラ)
         ,on_case_stockout_qty  => lt_case_stockout_qty                    --(OUT)欠品数量(ケース)
         ,on_ball_stockout_qty  => lt_ball_stockout_qty                    --(OUT)欠品数量(ボール)
         ,on_sum_stockout_qty   => lt_sum_stockout_qty                     --(OUT)欠品数量(バラ･合計)
         ,ov_errbuf             => lv_errbuf
         ,ov_retcode            => lv_retcode
         ,ov_errmsg             => lv_errmsg
        );
--
        IF  ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
--
      ELSE
        --数量を0に設定する
        lt_indv_shipping_qty := cn_0;
        lt_case_shipping_qty := cn_0;
        lt_ball_shipping_qty := cn_0;
      END IF;
--
      --ループ初回、もしくはブレイクの場合
      IF ( lv_breck_key IS NULL )
        OR ( lv_breck_key <> gt_edi_sales_data(i).ship_to_customer_code || gt_edi_sales_data(i).dlv_invoice_number )
      THEN
        --ブレークキー設定、初期化
        lv_breck_key := gt_edi_sales_data(i).ship_to_customer_code || gt_edi_sales_data(i).dlv_invoice_number;
        gt_sum_qty(lv_breck_key).invc_indv_qty_sum := lt_indv_shipping_qty;
        gt_sum_qty(lv_breck_key).invc_case_qty_sum := lt_case_shipping_qty;
        gt_sum_qty(lv_breck_key).invc_ball_qty_sum := lt_ball_shipping_qty;
      ELSE
        --明細の数量を加算する
        gt_sum_qty(lv_breck_key).invc_indv_qty_sum := gt_sum_qty(lv_breck_key).invc_indv_qty_sum + lt_indv_shipping_qty;
        gt_sum_qty(lv_breck_key).invc_case_qty_sum := gt_sum_qty(lv_breck_key).invc_case_qty_sum + lt_case_shipping_qty;
        gt_sum_qty(lv_breck_key).invc_ball_qty_sum := gt_sum_qty(lv_breck_key).invc_ball_qty_sum + lt_ball_shipping_qty;
      END IF;
--
    END LOOP sum_qty_loop;
/* 2009/07/29 Ver1.5 Add End   */
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
  END get_sale_data;
--
--
  /**********************************************************************************
   * Procedure Name   : edit_sale_data
   * Description      : データ編集(A-6)
   ***********************************************************************************/
  PROCEDURE edit_sale_data(
    iv_chain_store_code IN  fnd_lookup_values.description%TYPE,  --処理対象顧客のチェーン店コード
    iv_process_pattern  IN  fnd_lookup_values.attribute1%TYPE,   --処理対象の処理パターン
    ov_errbuf           OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_sale_data'; -- プログラム名
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
    lv_split_bill_cred_1    VARCHAR2(4);                                       --売掛コード２（事業所）分割１
    lv_split_bill_cred_2    VARCHAR2(4);                                       --売掛コード２（事業所）分割２
    lv_split_bill_cred_3    VARCHAR2(4);                                       --売掛コード２（事業所）分割３
    lv_whse_directly_class  VARCHAR2(2);                                       --倉直区分
    ld_last_day             DATE;                                              --納品日の月の最終日
    ln_due_date_dd_num      NUMBER;                                            --請求開始日-1(請求締日)
    lv_billing_due_date     VARCHAR2(8);                                       --請求締日
    lv_address              VARCHAR2(255);                                     --届け先住所(漢字)
    lv_bill_cred_rec_code2  VARCHAR2(200);                                     --チェーン店固有エリア(ヘッダー)
    lv_pb_nb_rate           VARCHAR2(10);                                      --歩率
    lv_data_record          VARCHAR2(32767);                                   --編集後のデータ取得用
    ln_no_inv_item_flag     VARCHAR2(1);                                       --非在庫品品目フラグ
    lt_standard_qty         xxcos_sales_exp_lines.standard_qty%TYPE;           --出荷数量(バラ),(合計、バラ)
    lt_standard_unit_price  xxcos_sales_exp_lines.standard_unit_price%TYPE;    --原単価(発注)
    lt_header_break         xxcos_sales_exp_headers.sales_exp_header_id%TYPE;  --販売実績ヘッダブレーク用(A-9の処理用)
    ln_seq                  NUMBER;                                            --添字用(A-9の処理用)
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD START ******************************************
    ln_line_no              NUMBER(3);                                         --行Ｎｏ
    lv_ship_to_customer_code xxcos_sales_exp_headers.ship_to_customer_code%TYPE; --顧客【納品先】ブレイク処理用
    lv_dlv_invoice_number   xxcos_sales_exp_headers.dlv_invoice_number%TYPE;   --納品伝票番号ブレイク処理用
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD END   ******************************************
-- 2009/06/25 M.Sano Ver.1.5 add Start
    lt_indv_shipping_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --出荷数量(バラ)
    lt_case_shipping_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --出荷数量(ケース)
    lt_ball_shipping_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --出荷数量(ボール)
    lt_indv_stockout_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --欠品数量(バラ)
    lt_case_stockout_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --欠品数量(ケース)
    lt_ball_stockout_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --欠品数量(ボール)
    lt_sum_stockout_qty     xxcos_sales_exp_lines.standard_qty%TYPE;           --欠品数量(合計、バラ)
-- 2009/06/25 M.Sano Ver.1.5 add End
/* 2009/07/29 Ver1.5 Add Start */
    lv_sum_qty_seq          VARCHAR2(21);                                      --伝票計用変数の添字(顧客【納品先】+納品伝票番号)
/* 2009/07/29 Ver1.5 Add End   */
/* 2009/11/05 Ver1.7 Add Start */
    lv_invoice_class        xxcos_sales_exp_headers.invoice_class%TYPE;        --伝票区分
/* 2009/11/05 Ver1.7 Add End   */
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    l_data_tab  xxcos_common2_pkg.g_layout_ttype;    --出力データ情報
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
    --ループ外変数の初期化
    ln_seq               := cn_0;
    gt_update_header_id  := gt_update_header_id_c;
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD START ******************************************
    --行Ｎｏの編集用変数の初期化
    lv_ship_to_customer_code := NULL;
    lv_dlv_invoice_number    := NULL;
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD END   ******************************************
    --A-5で取得したデータの編集、及び、ファイル出力
    <<output_loop>>
    FOR i IN 1.. gn_data_cnt LOOP
      --ループ内変数の初期化
      ln_no_inv_item_flag := cn_0;
-- 2009/06/25 M.Sano Ver.1.5 add Start
      --出荷数量,欠品数量格納変数の初期化
      lt_indv_shipping_qty  := cn_0;
      lt_case_shipping_qty  := cn_0;
      lt_ball_shipping_qty  := cn_0;
      lt_indv_stockout_qty  := cn_0;
      lt_case_stockout_qty  := cn_0;
      lt_ball_stockout_qty  := cn_0;
      lt_sum_stockout_qty   := cn_0;
-- 2009/06/25 M.Sano Ver.1.5 add End
/* 2009/07/29 Ver1.5 Add Start */
      --伝票計用変数の添字を編集
      lv_sum_qty_seq := gt_edi_sales_data(i).ship_to_customer_code || gt_edi_sales_data(i).dlv_invoice_number;
/* 2009/07/29 Ver1.5 Add Start */
      --==============================================================
      -- 更新処理(A-9)で使用するIDの編集
      --==============================================================
      IF (
           ( lt_header_break IS NULL )
           OR 
           ( lt_header_break <> gt_edi_sales_data(i).sales_exp_header_id )
         )
      THEN
        ln_seq                      := ln_seq + 1;
        lt_header_break             := gt_edi_sales_data(i).sales_exp_header_id; --ブレーク変数
        gt_update_header_id(ln_seq) := lt_header_break;
      END IF;
      --==============================================================
      -- 項目の編集
      --==============================================================
      -----------------------------------------------------------
      --原単価(発注)、出荷数量(バラ)、出荷数量(バラ、合計)の編集
      -----------------------------------------------------------
      IF ( gn_no_inv_item_cnt <> cn_0 ) THEN
        --非在庫品目のチェック
        <<no_item_check_loop>>
        FOR i2 IN 1.. gn_no_inv_item_cnt LOOP
          --明細品目が非在庫品目の場合
          IF ( gt_no_inv_item(i2) = gt_edi_sales_data(i).item_code ) THEN
            ln_no_inv_item_flag := cn_1;  --フラグを立てる
            EXIT;
          END IF;
        END LOOP no_item_check_loop;
      END IF;
      --非在庫品目以外の場合
      IF ( ln_no_inv_item_flag = cn_0 ) THEN
        lt_standard_qty        := gt_edi_sales_data(i).standard_qty;        --基準数量を設定
        lt_standard_unit_price := gt_edi_sales_data(i).standard_unit_price; --基準単価を設定
-- 2009/06/25 M.Sano Ver.1.5 add Start
        -- 出荷数量を取得する。
        xxcos_common2_pkg.convert_quantity(
          iv_uom_code           => gt_edi_sales_data(i).standard_uom_code   --(IN)基準単位
         ,in_case_qty           => gt_edi_sales_data(i).case_inc_num        --(IN)ケース入数
         ,in_ball_qty           => gt_edi_sales_data(i).bowl_inc_num        --(IN)ボール入数
         ,in_sum_indv_order_qty => lt_standard_qty                          --(IN)基準数量
         ,in_sum_shipping_qty   => lt_standard_qty                          --(IN)基準数量
         ,on_indv_shipping_qty  => lt_indv_shipping_qty                     --(OUT)出荷数量(バラ)
         ,on_case_shipping_qty  => lt_case_shipping_qty                     --(OUT)出荷数量(ケース)
         ,on_ball_shipping_qty  => lt_ball_shipping_qty                     --(OUT)出荷数量(ボール)
         ,on_indv_stockout_qty  => lt_indv_stockout_qty                     --(OUT)欠品数量(バラ)
         ,on_case_stockout_qty  => lt_case_stockout_qty                     --(OUT)欠品数量(ケース)
         ,on_ball_stockout_qty  => lt_ball_stockout_qty                     --(OUT)欠品数量(ボール)
         ,on_sum_stockout_qty   => lt_sum_stockout_qty                      --(OUT)欠品数量(バラ･合計)
         ,ov_errbuf             => lv_errbuf
         ,ov_retcode            => lv_retcode
         ,ov_errmsg             => lv_errmsg
        );
        IF  ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
-- 2009/06/25 M.Sano Ver.1.5 add End
      ELSE
        lt_standard_qty        := cn_0;  --0を設定
        lt_standard_unit_price := cn_0;  --0を設定
      END IF;
      --売掛コード２（事業所）を分割する(倉直の編集用)
      lv_split_bill_cred_1 := SUBSTRB( gt_edi_sales_data(i).bill_cred_rec_code2, cn_1, cn_4 );  --1～4桁
      lv_split_bill_cred_2 := SUBSTRB( gt_edi_sales_data(i).bill_cred_rec_code2, cn_5, cn_4 );  --5～8桁
      lv_split_bill_cred_3 := SUBSTRB( gt_edi_sales_data(i).bill_cred_rec_code2, cn_9, cn_4 );  --9～12桁
      --納品日の月の最終日を取得する(請求締日編集用)
      ld_last_day          := LAST_DAY( gt_edi_sales_data(i).orig_delivery_date );
      --請求開始日-1を取得する(請求締日編集用)
      ln_due_date_dd_num   := gt_edi_sales_data(i).sales_exp_day - cn_1;
      --スマイル以外の場合
      IF ( iv_process_pattern <> cv_5 ) THEN
        --------------------------
        --請求締日の編集
        --------------------------
        --請求開始日がNULL以外の場合
        IF (  gt_edi_sales_data(i).sales_exp_day IS NOT NULL ) THEN
          --請求開始日が翌月１日の設定の場合
          IF ( gt_edi_sales_data(i).sales_exp_day IN ( cn_1, cn_32 )  ) THEN
            lv_billing_due_date := TO_CHAR( ld_last_day, cv_date_format ); --末日を設定
          ELSE
            -- 納品日の月の最終日が請求開始日-1の日(請求締日)より小さい場合
            IF ( TO_NUMBER( TO_CHAR( ld_last_day, cv_d_format_dd ) ) < ln_due_date_dd_num ) THEN
              lv_billing_due_date := TO_CHAR( ld_last_day, cv_date_format );  --末日を設定
            ELSE
              lv_billing_due_date := TO_CHAR( ld_last_day, cv_d_format_yyyymm ) ||
                                       LPAD( TO_CHAR( ln_due_date_dd_num ), cn_2, cn_0 ); --納品日の月+請求開始日-1を設定
            END IF;
          END IF;
        ELSE
          lv_billing_due_date := NULL;
        END IF;
        --------------------------
        --その他の編集
        --------------------------
        lv_address             := gt_edi_sales_data(i).address;              --届け先住所(漢字)
        lv_bill_cred_rec_code2 := gt_edi_sales_data(i).bill_cred_rec_code2;  --チェーン店固有エリア(ヘッダー)
        lv_pb_nb_rate          := NULL;                                      --歩率
      --スマイルの場合
      ELSE
        --------------------------
        --歩率の取得
        --------------------------
        BEGIN
          SELECT  DECODE(  xlvv3.lookup_code
                          ,'', xlvv2.description  --PB商品以外(NBの歩率)
                          ,xlvv1.description      --PB商品(PBの歩率)
                  )  rate
          INTO    lv_pb_nb_rate
          FROM    xxcos_sales_exp_lines    xsel
                 ,xxcos_sales_exp_headers  xseh
                 ,hz_cust_accounts         hca
                 ,xxcmm_cust_accounts      xca
                 ,xxcos_lookup_values_v    xlvv1 --納入先チェーン店コードPB
                 ,xxcos_lookup_values_v    xlvv2 --納入先チェーン店コードNB
                 ,xxcos_lookup_values_v    xlvv3 --PB商品コード
          WHERE   xsel.sales_exp_line_id      = gt_edi_sales_data(i).sales_exp_line_id
          AND     xsel.sales_exp_header_id    = xseh.sales_exp_header_id
          AND     xseh.ship_to_customer_code  = hca.account_number
          AND     hca.cust_account_id         = xca.customer_id
          AND     xlvv1.lookup_type           = cv_lkt_ship_to_pb
          AND     xlvv1.lookup_code           = xca.delivery_chain_code
          AND     xlvv2.lookup_type           = cv_lkt_ship_to_nb
          AND     xlvv2.lookup_code           = xca.delivery_chain_code
          AND     xlvv3.lookup_type(+)        = cv_lkt_pb_item
          AND     xlvv3.lookup_code(+)        = xsel.item_code
/* 2010/03/16 Ver1.10 Add Start */
          AND     TRUNC( gt_edi_sales_data(i).orig_delivery_date ) BETWEEN NVL( xlvv1.start_date_active, gd_min_date    )
                                                                   AND     NVL( xlvv1.end_date_active,   gd_max_date    )
          AND     TRUNC( gt_edi_sales_data(i).orig_delivery_date ) BETWEEN NVL( xlvv2.start_date_active, gd_min_date    )
                                                                   AND     NVL( xlvv2.end_date_active,   gd_max_date    )
          AND     TRUNC( gt_edi_sales_data(i).orig_delivery_date ) BETWEEN NVL( xlvv3.start_date_active(+), gd_min_date )
                                                                   AND     NVL( xlvv3.end_date_active(+),   gd_max_date )
/* 2010/03/16 Ver1.10 Add End   */
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --スマイルの歩率対象外
            lv_pb_nb_rate := gv_prf_def_item_rate;  --プロファイルの歩率
        END;
        --------------------------
        --その他の編集
        --------------------------
        lv_billing_due_date    := NULL;  --請求締日
        lv_address             := NULL;  --届け先住所(漢字)
        lv_bill_cred_rec_code2 := NULL;  --チェーン店固有エリア(ヘッダー)
      END IF;
      --------------------------
      --倉直の編集
      --------------------------
      --伊藤忠(処理パターン１)
      IF ( iv_process_pattern = cv_1 ) THEN
        IF (
             ( lv_split_bill_cred_1 <> cv_0000 )
             AND
             ( lv_split_bill_cred_2 <> cv_0000 )
           )
        THEN
          IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
            lv_whse_directly_class := cv_1;  --倉入れ
          ELSE
            lv_whse_directly_class := cv_2;  --直送
          END IF;
        ELSE
          lv_whse_directly_class := NULL;  --設定なし
        END IF;
      --国分(処理パターン２)
      ELSIF ( iv_process_pattern = cv_2 ) THEN
        IF ( lv_split_bill_cred_1 <> cv_0000 ) THEN
          IF ( lv_split_bill_cred_2 = cv_0000 ) THEN
            IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
              lv_whse_directly_class := cv_1;  --倉入れ
            ELSE
              lv_whse_directly_class := NULL;  --設定なし
            END IF;
          ELSE
              lv_whse_directly_class := cv_2;  --直送
          END IF;
        ELSE
          lv_whse_directly_class := NULL;  --設定なし
        END IF;
      --菱食(処理パターン３)
      ELSIF ( iv_process_pattern = cv_3 ) THEN
        IF ( lv_split_bill_cred_1 <> cv_0000 ) THEN
          IF ( lv_split_bill_cred_2 = cv_0000 ) THEN
            IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
              lv_whse_directly_class := cv_1;  --倉入れ
            ELSE
              lv_whse_directly_class := NULL;  --設定なし
            END IF;
          ELSE
            IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
              lv_whse_directly_class := cv_2;  --直送
            ELSE
              lv_whse_directly_class := cv_3;  --その他
            END IF;
          END IF;
        ELSE
          lv_whse_directly_class := NULL;  --設定なし
        END IF;
      --トーカン(処理パターン４)
      ELSIF ( iv_process_pattern = cv_4 ) THEN
        IF ( lv_split_bill_cred_1 <> cv_0000 ) THEN
          IF ( lv_split_bill_cred_2 = cv_0000 ) THEN
            IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
              lv_whse_directly_class := cv_1;  --倉入れ
            ELSE
              lv_whse_directly_class := NULL;  --設定なし
            END IF;
          ELSE
            IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
              lv_whse_directly_class := cv_2;  --直送
            ELSE
              lv_whse_directly_class := cv_3;  --その他
            END IF;
          END IF;
        ELSE
          lv_whse_directly_class := NULL;  --設定なし
        END IF;
      --スマイル(処理パターン５)
      ELSIF ( iv_process_pattern = cv_5 ) THEN
        lv_whse_directly_class  := NULL;
      END IF;
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD START ******************************************
      --------------------------
      --行Ｎｏの編集
      --------------------------
      IF ( lv_ship_to_customer_code IS NULL AND lv_dlv_invoice_number IS NULL )
        OR ( lv_ship_to_customer_code <> gt_edi_sales_data(i).ship_to_customer_code )
        OR ( lv_dlv_invoice_number <> gt_edi_sales_data(i).dlv_invoice_number )
      THEN
        ln_line_no := 1;
        lv_ship_to_customer_code := gt_edi_sales_data(i).ship_to_customer_code;
        lv_dlv_invoice_number    := gt_edi_sales_data(i).dlv_invoice_number;
      ELSE
        ln_line_no := ln_line_no + 1;
      END IF;
/* 2009/11/05 Ver1.7 Add Start */
      --------------------------
      --伝票番号の編集
      --------------------------
      IF ( LENGTHB(gt_edi_sales_data(i).invoice_class) >= 2 ) THEN
        lv_invoice_class := SUBSTRB(gt_edi_sales_data(i).invoice_class, -2);
      ELSE
        lv_invoice_class := gt_edi_sales_data(i).invoice_class;
      END IF;
/* 2009/11/05 Ver1.7 Add End   */
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD END   ******************************************
      --==============================================================
      --共通関数用の変数に値を設定
      --==============================================================
      -- ヘッダ部 --
      l_data_tab(cv_medium_class)             := gt_edi_media_class;                       -- 媒体区分
      l_data_tab(cv_data_type_code)           := gt_data_type_code;                        -- データ種コード
--****************　2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
--****************　2009/07/07   N.Maeda  Ver1.5   MOD   START  *********************************************--
      l_data_tab(cv_file_no)                  := gt_parallel_num;                          -- ファイルNo.
--      l_data_tab(cv_file_no)                  := gt_edi_sales_data(i).edi_forward_number;   -- ファイルNo.
--****************　2009/07/07   N.Maeda  Ver1.5   MOD    END   *********************************************--
--      l_data_tab(cv_file_no)                  := TO_CHAR(NULL);
--****************　2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
      l_data_tab(cv_info_class)               := TO_CHAR(NULL);
      l_data_tab(cv_process_date)             := gv_f_o_date;                              -- 処理日
      l_data_tab(cv_process_time)             := gv_f_o_time;                              -- 処理時間
      l_data_tab(cv_base_code)                := gt_edi_sales_data(i).sales_base_code;     -- 拠点コード
      l_data_tab(cv_base_name)                := gt_edi_sales_data(i).sales_base_name;     -- 拠点名（漢字）
      l_data_tab(cv_base_name_alt)            := gt_edi_sales_data(i).sales_base_phonetic; -- 拠点名（カナ）
      l_data_tab(cv_edi_chain_code)           := iv_chain_store_code;                      -- EDIチェーン店コード
      l_data_tab(cv_edi_chain_name)           := gt_edi_chain_name;                        -- EDIチェーン店名
      l_data_tab(cv_edi_chain_name_alt)       := gt_edi_chain_name_phonetic;               -- EDIチェーン店名（カナ）
      l_data_tab(cv_chain_code)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_report_code)              := TO_CHAR(NULL);
      l_data_tab(cv_report_show_name)         := TO_CHAR(NULL);
      l_data_tab(cv_cust_code)                := gt_edi_sales_data(i).ship_to_customer_code; -- 顧客コード
      l_data_tab(cv_cust_name)                := gt_edi_sales_data(i).customer_name;         -- 顧客名（漢字）
      l_data_tab(cv_cust_name_alt)            := gt_edi_sales_data(i).customer_phonetic;     -- 顧客名（カナ）
      l_data_tab(cv_comp_code)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name_alt)            := TO_CHAR(NULL);
      l_data_tab(cv_shop_code)                := TO_CHAR(NULL);
      l_data_tab(cv_shop_name)                := TO_CHAR(NULL);
      l_data_tab(cv_shop_name_alt)            := TO_CHAR(NULL);
      l_data_tab(cv_delv_cent_code)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_cent_name)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_cent_name_alt)       := TO_CHAR(NULL);
      l_data_tab(cv_order_date)               := TO_CHAR(NULL);
      l_data_tab(cv_cent_delv_date)           := TO_CHAR(NULL);
      l_data_tab(cv_result_delv_date)         := TO_CHAR(NULL);
      l_data_tab(cv_shop_delv_date)           := TO_CHAR(gt_edi_sales_data(i).orig_delivery_date, cv_date_format);  --店舗納品日
      l_data_tab(cv_dc_date_edi_data)         := TO_CHAR(NULL);
      l_data_tab(cv_dc_time_edi_data)         := TO_CHAR(NULL);
/* 2009/11/05 Ver1.7 Add Start */
--      l_data_tab(cv_invc_class)               := gt_edi_sales_data(i).invoice_class;  -- 伝票区分
      l_data_tab(cv_invc_class)               := lv_invoice_class; -- 伝票区分
/* 2009/11/05 Ver1.7 Mod End   */
      l_data_tab(cv_small_classif_code)       := TO_CHAR(NULL);
      l_data_tab(cv_small_classif_name)       := TO_CHAR(NULL);
      l_data_tab(cv_middle_classif_code)      := TO_CHAR(NULL);
      l_data_tab(cv_middle_classif_name)      := TO_CHAR(NULL);
      l_data_tab(cv_big_classif_code)         := gt_edi_sales_data(i).invoice_classification_code; -- 大分類コード
      l_data_tab(cv_big_classif_name)         := TO_CHAR(NULL);
      l_data_tab(cv_op_department_code)       := TO_CHAR(NULL);
/* 2009/11/27 Ver1.9 Mod Start */
--      l_data_tab(cv_op_order_number)          := TO_CHAR(NULL);
      l_data_tab(cv_op_order_number)          := gt_edi_sales_data(i).order_invoice_number;  --相手先発注番号
/* 2009/11/27 Ver1.9 Mod End */
      l_data_tab(cv_check_digit_class)        := TO_CHAR(NULL);
      l_data_tab(cv_invc_number)              := gt_edi_sales_data(i).dlv_invoice_number;  --伝票番号
      l_data_tab(cv_check_digit)              := TO_CHAR(NULL);
      l_data_tab(cv_close_date)               := TO_CHAR(NULL);
      l_data_tab(cv_order_no_ebs)             := TO_CHAR(NULL);
      l_data_tab(cv_ar_sale_class)            := TO_CHAR(NULL);
      l_data_tab(cv_delv_classe)              := TO_CHAR(NULL);
      l_data_tab(cv_opportunity_no)           := TO_CHAR(NULL);
      l_data_tab(cv_contact_to)               := TO_CHAR(NULL);
      l_data_tab(cv_route_sales)              := TO_CHAR(NULL);
      l_data_tab(cv_corporate_code)           := TO_CHAR(NULL);
      l_data_tab(cv_maker_name)               := TO_CHAR(NULL);
      l_data_tab(cv_area_code)                := TO_CHAR(NULL);
      l_data_tab(cv_area_name)                := TO_CHAR(NULL);
      l_data_tab(cv_area_name_alt)            := TO_CHAR(NULL);
      l_data_tab(cv_vendor_code)              := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name)              := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name1_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name2_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_vendor_tel)               := TO_CHAR(NULL);
      l_data_tab(cv_vendor_charge)            := TO_CHAR(NULL);
      l_data_tab(cv_vendor_address)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_code_itouen)      := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_code_chain)       := TO_CHAR(NULL);
      l_data_tab(cv_delv_to)                  := TO_CHAR(NULL);
      l_data_tab(cv_delv_to1_alt)             := TO_CHAR(NULL);
      l_data_tab(cv_delv_to2_alt)             := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_address)          := lv_address;     --届け先住所（漢字）
      l_data_tab(cv_delv_to_address_alt)      := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_tel)              := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_code)             := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_comp_code)        := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_shop_code)        := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_name)             := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_name_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_address)          := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_address_alt)      := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_tel)              := TO_CHAR(NULL);
      l_data_tab(cv_order_possible_date)      := TO_CHAR(NULL);
      l_data_tab(cv_perm_possible_date)       := TO_CHAR(NULL);
      l_data_tab(cv_forward_month)            := TO_CHAR(NULL);
      l_data_tab(cv_payment_settlement_date)  := TO_CHAR(NULL);
      l_data_tab(cv_handbill_start_date_act)  := TO_CHAR(NULL);
      l_data_tab(cv_billing_due_date)         := lv_billing_due_date;  --請求締日
      l_data_tab(cv_ship_time)                := TO_CHAR(NULL);
      l_data_tab(cv_delv_schedule_time)       := TO_CHAR(NULL);
      l_data_tab(cv_order_time)               := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item1)           := TO_CHAR(gt_edi_sales_data(i).orig_inspect_date, cv_date_format); --汎用日付項目1
      l_data_tab(cv_gen_date_item2)           := TO_CHAR(gt_edi_sales_data(i).orig_inspect_date, cv_date_format); --汎用日付項目2
      l_data_tab(cv_gen_date_item3)           := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item4)           := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item5)           := TO_CHAR(NULL);
      l_data_tab(cv_arrival_ship_class)       := TO_CHAR(NULL);
      l_data_tab(cv_vendor_class)             := TO_CHAR(NULL);
      l_data_tab(cv_invc_detailed_class)      := TO_CHAR(NULL);
      l_data_tab(cv_unit_price_use_class)     := TO_CHAR(NULL);
      l_data_tab(cv_sub_distb_cent_code)      := TO_CHAR(NULL);
      l_data_tab(cv_sub_distb_cent_name)      := TO_CHAR(NULL);
      l_data_tab(cv_cent_delv_method)         := TO_CHAR(NULL);
      l_data_tab(cv_cent_use_class)           := TO_CHAR(NULL);
      l_data_tab(cv_cent_whse_class)          := TO_CHAR(NULL);
      l_data_tab(cv_cent_area_class)          := TO_CHAR(NULL);
      l_data_tab(cv_cent_arrival_class)       := TO_CHAR(NULL);
      l_data_tab(cv_depot_class)              := TO_CHAR(NULL);
      l_data_tab(cv_tcdc_class)               := TO_CHAR(NULL);
      l_data_tab(cv_upc_flag)                 := TO_CHAR(NULL);
      l_data_tab(cv_simultaneously_class)     := TO_CHAR(NULL);
      l_data_tab(cv_business_id)              := TO_CHAR(NULL);
      l_data_tab(cv_whse_directly_class)      := lv_whse_directly_class;  --倉直区分
      l_data_tab(cv_premium_rebate_class)     := TO_CHAR(NULL);
      l_data_tab(cv_item_type)                := TO_CHAR(NULL);
      l_data_tab(cv_cloth_house_food_class)   := TO_CHAR(NULL);
      l_data_tab(cv_mix_class)                := TO_CHAR(NULL);
      l_data_tab(cv_stk_class)                := TO_CHAR(NULL);
      l_data_tab(cv_last_modify_site_class)   := TO_CHAR(NULL);
      l_data_tab(cv_report_class)             := TO_CHAR(NULL);
      l_data_tab(cv_addition_plan_class)      := TO_CHAR(NULL);
      l_data_tab(cv_registration_class)       := TO_CHAR(NULL);
      l_data_tab(cv_specific_class)           := TO_CHAR(NULL);
      l_data_tab(cv_dealings_class)           := TO_CHAR(NULL);
      l_data_tab(cv_order_class)              := TO_CHAR(NULL);
      l_data_tab(cv_sum_line_class)           := TO_CHAR(NULL);
      l_data_tab(cv_ship_guidance_class)      := TO_CHAR(NULL);
      l_data_tab(cv_ship_class)               := gt_edi_sales_data(i).dlv_invoice_class;  --出荷区分
      l_data_tab(cv_prod_code_use_class)      := TO_CHAR(NULL);
      l_data_tab(cv_cargo_item_class)         := TO_CHAR(NULL);
      l_data_tab(cv_ta_class)                 := TO_CHAR(NULL);
      l_data_tab(cv_plan_code)                := TO_CHAR(NULL);
      l_data_tab(cv_category_code)            := TO_CHAR(NULL);
      l_data_tab(cv_category_class)           := TO_CHAR(NULL);
      l_data_tab(cv_carrier_means)            := TO_CHAR(NULL);
      l_data_tab(cv_counter_code)             := TO_CHAR(NULL);
      l_data_tab(cv_move_sign)                := TO_CHAR(NULL);
      l_data_tab(cv_eos_handwriting_class)    := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_section_code)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_detailed)            := TO_CHAR(NULL);
      l_data_tab(cv_attach_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_op_floor)                 := TO_CHAR(NULL);
      l_data_tab(cv_text_no)                  := TO_CHAR(NULL);
      l_data_tab(cv_in_store_code)            := TO_CHAR(NULL);
      l_data_tab(cv_tag_data)                 := TO_CHAR(NULL);
      l_data_tab(cv_competition_code)         := TO_CHAR(NULL);
      l_data_tab(cv_billing_chair)            := TO_CHAR(NULL);
      l_data_tab(cv_chain_store_code)         := TO_CHAR(NULL);
      l_data_tab(cv_chain_store_short_name)   := TO_CHAR(NULL);
      l_data_tab(cv_direct_delv_rcpt_fee)     := TO_CHAR(NULL);
      l_data_tab(cv_bill_info)                := TO_CHAR(NULL);
      l_data_tab(cv_description)              := TO_CHAR(NULL);
      l_data_tab(cv_interior_code)            := TO_CHAR(NULL);
      l_data_tab(cv_order_info_delv_category) := TO_CHAR(NULL);
      l_data_tab(cv_purchase_type)            := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_name_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_shop_opened_site)         := TO_CHAR(NULL);
      l_data_tab(cv_counter_name)             := TO_CHAR(NULL);
      l_data_tab(cv_extension_number)         := TO_CHAR(NULL);
      l_data_tab(cv_charge_name)              := TO_CHAR(NULL);
      l_data_tab(cv_price_tag)                := TO_CHAR(NULL);
      l_data_tab(cv_tax_type)                 := TO_CHAR(NULL);
      l_data_tab(cv_consumption_tax_class)    := TO_CHAR(NULL);
      l_data_tab(cv_brand_class)              := TO_CHAR(NULL);
      l_data_tab(cv_id_code)                  := TO_CHAR(NULL);
      l_data_tab(cv_department_code)          := TO_CHAR(NULL);
      l_data_tab(cv_department_name)          := TO_CHAR(NULL);
      l_data_tab(cv_item_type_number)         := TO_CHAR(NULL);
      l_data_tab(cv_description_department)   := TO_CHAR(NULL);
      l_data_tab(cv_price_tag_method)         := TO_CHAR(NULL);
      l_data_tab(cv_reason_column)            := TO_CHAR(NULL);
      l_data_tab(cv_a_column_header)          := TO_CHAR(NULL);
      l_data_tab(cv_d_column_header)          := TO_CHAR(NULL);
      l_data_tab(cv_brand_code)               := TO_CHAR(NULL);
      l_data_tab(cv_line_code)                := TO_CHAR(NULL);
      l_data_tab(cv_class_code)               := TO_CHAR(NULL);
      l_data_tab(cv_a1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_a2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_a3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_header)    := lv_bill_cred_rec_code2;  --チェーン店固有エリア(ヘッダー)
      l_data_tab(cv_order_connection_number)  := TO_CHAR(NULL);
      --明細部 --
--************************************* 2009/05/28 T.Tominaga Var1.4 MOD START ******************************************
--      l_data_tab(cv_line_no)                  := TO_CHAR(gt_edi_sales_data(i).dlv_invoice_line_number); --行NO
      l_data_tab(cv_line_no)                  := TO_CHAR(ln_line_no); --行NO
--************************************* 2009/05/28 T.Tominaga Var1.4 MOD END   ******************************************
      l_data_tab(cv_stkout_class)             := TO_CHAR(NULL);
      l_data_tab(cv_stkout_reason)            := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_itouen)         := gt_edi_sales_data(i).item_code;  --商品コード(伊藤園)
      l_data_tab(cv_prod_code1)               := TO_CHAR(NULL);
      l_data_tab(cv_prod_code2)               := TO_CHAR(NULL);
      l_data_tab(cv_jan_code)                 := gt_edi_sales_data(i).jan_code;  --JANコード
      l_data_tab(cv_itf_code)                 := gt_edi_sales_data(i).itf_code;  --ITFコード
      l_data_tab(cv_extension_itf_code)       := TO_CHAR(NULL);
      l_data_tab(cv_case_prod_code)           := TO_CHAR(NULL);
      l_data_tab(cv_ball_prod_code)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_item_type)      := TO_CHAR(NULL);
      l_data_tab(cv_prod_class)               := gt_edi_sales_data(i).item_div_code;  --商品区分
      l_data_tab(cv_prod_name)                := gt_edi_sales_data(i).item_name;  --商品名(漢字)
      l_data_tab(cv_prod_name1_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_name2_alt)           := gt_edi_sales_data(i).item_phonetic1;  --商品名(カナ)
      l_data_tab(cv_item_standard1)           := TO_CHAR(NULL);
      l_data_tab(cv_item_standard2)           := gt_edi_sales_data(i).item_phonetic2;  --商品名(カナ)
      l_data_tab(cv_qty_in_case)              := TO_CHAR(NULL);
      l_data_tab(cv_num_of_cases)             := gt_edi_sales_data(i).case_inc_num;  --ケース入数
      l_data_tab(cv_num_of_ball)              := TO_CHAR(gt_edi_sales_data(i).bowl_inc_num);  --ボール入数
      l_data_tab(cv_item_color)               := TO_CHAR(NULL);
      l_data_tab(cv_item_size)                := TO_CHAR(NULL);
      l_data_tab(cv_expiration_date)          := TO_CHAR(NULL);
      l_data_tab(cv_prod_date)                := TO_CHAR(NULL);
      l_data_tab(cv_order_uom_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_ship_uom_qty)             := TO_CHAR(NULL);
      l_data_tab(cv_packing_uom_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_deal_code)                := TO_CHAR(NULL);
      l_data_tab(cv_deal_class)               := TO_CHAR(NULL);
      l_data_tab(cv_collation_code)           := TO_CHAR(NULL);
      l_data_tab(cv_uom_code)                 := TO_CHAR(NULL);
      l_data_tab(cv_unit_price_class)         := TO_CHAR(NULL);
      l_data_tab(cv_parent_packing_number)    := TO_CHAR(NULL);
      l_data_tab(cv_packing_number)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_group_code)          := TO_CHAR(NULL);
      l_data_tab(cv_case_dismantle_flag)      := TO_CHAR(NULL);
      l_data_tab(cv_case_class)               := TO_CHAR(NULL);
      l_data_tab(cv_indv_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_case_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_ball_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_sum_order_qty)            := TO_CHAR(NULL);
-- 2009/06/25 M.Sano Ver.1.5 mod Start
--      l_data_tab(cv_indv_ship_qty)            := TO_CHAR(lt_standard_qty);  --出荷数量(バラ)
--      l_data_tab(cv_case_ship_qty)            := TO_CHAR(NULL);
--      l_data_tab(cv_ball_ship_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_indv_ship_qty)            := TO_CHAR(lt_indv_shipping_qty);  --出荷数量(バラ)
      l_data_tab(cv_case_ship_qty)            := TO_CHAR(lt_case_shipping_qty);  --出荷数量(ケース)
      l_data_tab(cv_ball_ship_qty)            := TO_CHAR(lt_ball_shipping_qty);  --出荷数量(ボール)
-- 2009/06/25 M.Sano Ver.1.5 mod End
      l_data_tab(cv_pallet_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_sum_ship_qty)             := TO_CHAR(lt_standard_qty);  --出荷数量(合計、バラ)
-- 2009/06/25 M.Sano Ver.1.5 mod Start
--      l_data_tab(cv_indv_stkout_qty)          := TO_CHAR(NULL);
--      l_data_tab(cv_case_stkout_qty)          := TO_CHAR(NULL);
--      l_data_tab(cv_ball_stkout_qty)          := TO_CHAR(NULL);
--      l_data_tab(cv_sum_stkout_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_indv_stkout_qty)          := TO_CHAR(lt_indv_stockout_qty);   --欠品数量(バラ)
      l_data_tab(cv_case_stkout_qty)          := TO_CHAR(lt_case_stockout_qty);    --欠品数量(ケース)
      l_data_tab(cv_ball_stkout_qty)          := TO_CHAR(lt_ball_stockout_qty);   --欠品数量(ボール)
      l_data_tab(cv_sum_stkout_qty)           := TO_CHAR(lt_sum_stockout_qty);     --欠品数量(合計、バラ)
-- 2009/06/25 M.Sano Ver.1.5 mod End
      l_data_tab(cv_case_qty)                 := TO_CHAR(NULL);
      l_data_tab(cv_fold_container_indv_qty)  := TO_CHAR(NULL);
      l_data_tab(cv_order_unit_price)         := TO_CHAR(lt_standard_unit_price); --原単価(発注)
      l_data_tab(cv_ship_unit_price)          := TO_CHAR(NULL);
      l_data_tab(cv_order_cost_amt)           := TO_CHAR(NULL);
      l_data_tab(cv_ship_cost_amt)            := TO_CHAR(gt_edi_sales_data(i).sale_amount); --売上金額
      l_data_tab(cv_stkout_cost_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_selling_price)            := TO_CHAR(NULL);
      l_data_tab(cv_order_price_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_ship_price_amt)           := TO_CHAR(NULL);
      l_data_tab(cv_stkout_price_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_a_column_department)      := TO_CHAR(NULL);
      l_data_tab(cv_d_column_department)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_depth)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_height)     := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_width)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_weight)     := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item1)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item2)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item3)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item4)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item5)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item6)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item7)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item8)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item9)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item10)           := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item1)            := lv_pb_nb_rate ;                    --汎用付加項目１
      l_data_tab(cv_gen_add_item2)            := gt_edi_sales_data(i).sales_class;  --汎用付加項目２
      l_data_tab(cv_gen_add_item3)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item4)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item5)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item6)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item7)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item8)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item9)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item10)           := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_line)      := TO_CHAR(NULL);
      --フッタ部 --
      l_data_tab(cv_invc_indv_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_ball_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_order_qty)       := TO_CHAR(NULL);
/* 2009/07/29 Ver1.5 Mod Start */
--      l_data_tab(cv_invc_indv_ship_qty)       := TO_CHAR(gt_edi_sales_data(i).sum_standard_qty);  --(伝票計)出荷数量(バラ)
--      l_data_tab(cv_invc_case_ship_qty)       := TO_CHAR(NULL);
--      l_data_tab(cv_invc_ball_ship_qty)       := TO_CHAR(NULL);
      l_data_tab(cv_invc_indv_ship_qty)       := TO_CHAR(gt_sum_qty(lv_sum_qty_seq).invc_indv_qty_sum); --(伝票計)出荷数量(バラ)
      l_data_tab(cv_invc_case_ship_qty)       := TO_CHAR(gt_sum_qty(lv_sum_qty_seq).invc_case_qty_sum); --(伝票計)出荷数量(ケース)
      l_data_tab(cv_invc_ball_ship_qty)       := TO_CHAR(gt_sum_qty(lv_sum_qty_seq).invc_ball_qty_sum); --(伝票計)出荷数量(ボール)
/* 2009/07/29 Ver1.5 Mod End   */
      l_data_tab(cv_invc_pallet_ship_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_ship_qty)        := TO_CHAR(gt_edi_sales_data(i).sum_standard_qty);  --(伝票計)出荷数量(バラ)
      l_data_tab(cv_invc_indv_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_ball_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_stkout_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_invc_fold_container_qty)  := TO_CHAR(NULL);
      l_data_tab(cv_invc_order_cost_amt)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_ship_cost_amt)       := TO_CHAR(gt_edi_sales_data(i).sum_sale_amount);   --(伝票計)原価金額(バラ)
      l_data_tab(cv_invc_stkout_cost_amt)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_order_price_amt)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_ship_price_amt)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_stkout_price_amt)    := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_case_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_order_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_case_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_pallet_ship_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_ship_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_case_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_stkout_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_case_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_t_fold_container_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_t_order_cost_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_t_ship_cost_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_t_stkout_cost_amt)        := TO_CHAR(NULL);
      l_data_tab(cv_t_order_price_amt)        := TO_CHAR(NULL);
      l_data_tab(cv_t_ship_price_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_t_stkout_price_amt)       := TO_CHAR(NULL);
      l_data_tab(cv_t_line_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_t_invc_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_footer)    := TO_CHAR(NULL);
/* 2009/04/28 Ver1.3 Add Start */
      l_data_tab(cv_attribute)                := TO_CHAR(NULL);
/* 2009/04/28 Ver1.3 Add End   */
      --==============================================================
      --データ成型(A-6)
      --==============================================================
      BEGIN
        xxcos_common2_pkg.makeup_data_record(
           iv_edit_data        =>  l_data_tab          --出力データ情報
          ,iv_file_type        =>  cv_0                --ファイル形式(固定長)
          ,iv_data_type_table  =>  gt_data_type_table  --レイアウト定義情報
          ,iv_record_type      =>  gv_if_data          --データレコード識別子
          ,ov_data_record      =>  lv_data_record      --データレコード
          ,ov_errbuf           =>  lv_errbuf           --エラーメッセージ
          ,ov_retcode          =>  lv_retcode          --リターンコード
          ,ov_errmsg           =>  lv_errmsg           --ユーザ・エラーメッセージ
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application      --アプリケーション
                          ,iv_name         => cv_msg_out_inf_err  --出力情報編集エラー
                          ,iv_token_name1  => cv_tkn_err_m        --トークンコード１
                         ,iv_token_value1  => lv_errmsg           --共通関数のエラーメッセージ
                       );
        RAISE global_api_expt;
      END;
      --==============================================================
      --ファイル出力(A-7)
      --==============================================================
      UTL_FILE.PUT_LINE(
        file   => gt_f_handle     --ファイルハンドル
       ,buffer => lv_data_record  --出力文字(データ)
      );
--
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
  END edit_sale_data;
--
  /**********************************************************************************
   * Procedure Name   : output_footer
   * Description      : ファイル終了処理(A-8)
   ***********************************************************************************/
  PROCEDURE output_footer(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
/* 2009/04/28 Ver1.3 Mod Start */
--    lv_footer_output  VARCHAR2(1000);  --フッタ出力用
    lv_footer_output  VARCHAR2(5000);  --フッタ出力用
/* 2009/04/28 Ver1.3 Mod End   */
    lv_dummy1         VARCHAR2(1);     --IF元業務系列コード(フッタでは使用しない)
    lv_dummy2         VARCHAR2(1);     --拠点コード(フッタでは使用しない)
    lv_dummy3         VARCHAR2(1);     --拠点名称(フッタでは使用しない)
    lv_dummy4         VARCHAR2(1);     --チェーン店コード(フッタでは使用しない)
    lv_dummy5         VARCHAR2(1);     --チェーン店名称(フッタでは使用しない)
    lv_dummy6         VARCHAR2(1);     --データ種コード(フッタでは使用しない)
    lv_dummy7         VARCHAR2(1);     --並列処理番号(フッタでは使用しない)
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    --共通関数呼び出し
    --==============================================================
    --EDIヘッダ・フッタ付与
    xxccp_ifcommon_pkg.add_edi_header_footer(
      iv_add_area        =>  gv_if_footer      --付与区分
     ,iv_from_series     =>  lv_dummy1         --IF元業務系列コード
     ,iv_base_code       =>  lv_dummy2         --拠点コード
     ,iv_base_name       =>  lv_dummy3         --拠点名称
     ,iv_chain_code      =>  lv_dummy4         --チェーン店コード
     ,iv_chain_name      =>  lv_dummy5         --チェーン店名称
     ,iv_data_kind       =>  lv_dummy6         --データ種コード
     ,iv_row_number      =>  lv_dummy7         --並列処理番号
     ,in_num_of_records  =>  gn_data_cnt       --レコード件数
     ,ov_retcode         =>  lv_retcode        --リターンコード
     ,ov_output          =>  lv_footer_output  --フッタレコード
     ,ov_errbuf          =>  lv_errbuf         --エラーメッセージ
     ,ov_errmsg          =>  lv_errmsg         --ユーザー・エラー・メッセージ
    );
    IF  ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application   --アプリケーション
                     ,iv_name         => cv_msg_proc_err  --共通関数エラー
                     ,iv_token_name1  => cv_tkn_err_m     --トークンコード１
                     ,iv_token_value1 => lv_errmsg        --共通関数のエラーメッセージ
                   );
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --ファイル出力
    --==============================================================
    --フッタ出力
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --ファイルハンドル
     ,buffer => lv_footer_output  --出力文字(フッタ)
    );
    --==============================================================
    --ファイルクローズ
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
   * Procedure Name   : upd_sale_exp_head_send
   * Description      : 販売実績ヘッダTBLフラグ更新（作成）(A-9)
   ***********************************************************************************/
  PROCEDURE upd_sale_exp_head_send(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_sale_exp_head_send'; -- プログラム名
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
    lv_tkn_name  VARCHAR2(50);  --トークン取得用
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
      -- 販売実績ヘッダTBLフラグ更新（作成）
      FORALL i IN  1.. gt_update_header_id.LAST
        UPDATE  xxcos_sales_exp_headers   xseh  --販売実績ヘッダ
        SET     xseh.edi_send_date           = cd_process_date            --EDI送信日時
               ,xseh.edi_interface_flag      = cv_y                       --EDI送信済みフラグ
               ,xseh.last_updated_by         = cn_last_updated_by         --最終更新者
               ,xseh.last_update_date        = cd_last_update_date        --最終更新日
               ,xseh.last_update_login       = cn_last_update_login       --最終更新ログイン
               ,xseh.request_id              = cn_request_id              --要求ID
               ,xseh.program_application_id  = cn_program_application_id  --コンカレント・プログラム・アプリケーションID
               ,xseh.program_id              = cn_program_id              --コンカレント・プログラムID
               ,xseh.program_update_date     = cd_program_update_date     --プログラム更新日
        WHERE   xseh.edi_interface_flag      = cv_n                       --EDI送信済フラグ(未送信)
        AND     xseh.sales_exp_header_id     = gt_update_header_id(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        --トークン取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     --アプリケーション
                         ,iv_name         => cv_msg_table_tkn2  --販売実績ヘッダテーブル
                       );
        --メッセージ編集
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application  --アプリケーション
                         ,iv_name         => cv_msg_upd_err  --データ更新エラー
                         ,iv_token_name1  => cv_tkn_table_n  --トークンコード１
                         ,iv_token_value1 => lv_tkn_name     --販売実績ヘッダ
                         ,iv_token_name2  => cv_tkn_key      --トークンコード２
                         ,iv_token_value2 => NULL            --NULL
                       );
        lv_errbuf   := SQLERRM;
        RAISE global_api_expt;
    END;
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
  END upd_sale_exp_head_send;
--
  /**********************************************************************************
   * Procedure Name   : upd_sale_exp_head_rep
   * Description      : 販売実績ヘッダTBLフラグ更新（解除）(A-11)
   ***********************************************************************************/
  PROCEDURE upd_sale_exp_head_rep(
    iv_inv_cust_code    IN  VARCHAR2,     -- 請求先顧客コード
    iv_send_date        IN  VARCHAR2,     -- 送信日
    ov_errbuf           OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_sale_exp_head_rep'; -- プログラム名
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
    lv_tkn_name   VARCHAR2(50);  --トークン取得用
--
    -- *** ローカル・カーソル ***
    --送信済の販売実績情報
    CURSOR sale_data_cur
    IS
      SELECT  xseh.sales_exp_header_id  header_id   --ヘッダID
      FROM    xxcos_sales_exp_headers   xseh        --販売実績ヘッダ
      WHERE   xseh.edi_interface_flag  = cv_y                                     --EDI送信済フラグ(送信)
      AND     xseh.edi_send_date       = TO_DATE( iv_send_date, cv_date_format )  --EDI送信日
      AND     xseh.ship_to_customer_code IN
        ( SELECT  xxchv.ship_account_number
          FROM    xxcfr_cust_hierarchy_v  xxchv   --顧客階層ビュー
          WHERE   xxchv.bill_account_number  = iv_inv_cust_code
        ) 
      FOR UPDATE NOWAIT;
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
    -- ロック取得、データ取得
    OPEN  sale_data_cur;
    FETCH sale_data_cur BULK COLLECT INTO gt_update_header_id;
    -- 抽出件数取得
    gn_target_cnt := sale_data_cur%ROWCOUNT;
    CLOSE sale_data_cur;
--
    IF  ( gn_target_cnt <> cn_0 ) THEN
      BEGIN
        ----------------------
        --販売実績ヘッダ更新
        ----------------------
        FORALL i IN 1.. gn_target_cnt
          UPDATE  xxcos_sales_exp_headers   xseh  --販売実績ヘッダ
          SET     xseh.edi_interface_flag      = cv_n                       --EDI送信済みフラグ(未送信)
                 ,xseh.last_updated_by         = cn_last_updated_by         --最終更新者
                 ,xseh.last_update_date        = cd_last_update_date        --最終更新日
                 ,xseh.last_update_login       = cn_last_update_login       --最終更新ログイン
                 ,xseh.request_id              = cn_request_id              --要求ID
                 ,xseh.program_application_id  = cn_program_application_id  --コンカレント・プログラム・アプリケーションID
                 ,xseh.program_id              = cn_program_id              --コンカレント・プログラムID
                 ,xseh.program_update_date     = cd_program_update_date     --プログラム更新日
          WHERE   xseh.sales_exp_header_id     = gt_update_header_id(i)
          ;
      EXCEPTION
        WHEN OTHERS THEN
          --トークン取得
          lv_tkn_name := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          ,iv_name          => cv_msg_table_tkn2  --販売実績ヘッダテーブル
                         );
          --メッセージ編集
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application  --アプリケーション
                         ,iv_name         => cv_msg_upd_err  --データ更新エラー
                         ,iv_token_name1  => cv_tkn_table_n  --トークンコード１
                         ,iv_token_value1 => lv_tkn_name     --販売実績ヘッダ
                         ,iv_token_name2  => cv_tkn_key      --トークンコード２
                         ,iv_token_value2 => NULL            --NULL
                       );
          lv_errbuf := SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
    ----------------------
    --正常件数の設定
    ----------------------
    gn_normal_cnt := gn_target_cnt;
--
  EXCEPTION
    -- *** ロックエラー ***
    WHEN lock_expt THEN
      --カーソルクローズ
      IF ( sale_data_cur%ISOPEN ) THEN
        CLOSE sale_data_cur;
      END IF;
      --トークン取得
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_table_tkn2  --販売実績ヘッダテーブル
                     );
      --メッセージ取得
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --アプリケーション
                     ,iv_name         => cv_msg_lock_err    --ロックエラー
                     ,iv_token_name1  => cv_tkn_table       --トークンコード１
                     ,iv_token_value1 => lv_tkn_name        --販売実績ヘッダテーブル
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
  END upd_sale_exp_head_rep;
/* 2010/03/16 Ver1.10 Add Start */
--
  /**********************************************************************************
   * Procedure Name   : upd_no_target
   * Description      : 販売実績抽出対象外更新(A-12)
   ***********************************************************************************/
  PROCEDURE upd_no_target(
    ov_errbuf           OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_no_target'; -- プログラム名
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
    ln_data_chk   NUMBER(1)     := 0; --存在チェック用
    lv_tkn_name   VARCHAR2(50);       --トークン取得用
--
    -- *** ローカル・カーソル ***
    --抽出対象外の販売実績情報
    CURSOR no_taget_cur
    IS
      SELECT  /*+
                INDEX(xseh xxcos_sales_exp_headers_n03)
              */
              1                         data_chk    --存在チェック
      FROM    xxcos_sales_exp_headers   xseh        --販売実績ヘッダ
      WHERE   xseh.edi_interface_flag  = cv_n       --EDI送信済フラグ(未送信)
      AND     xseh.business_date       < TRUNC( ADD_MONTHS( cd_process_date, - gn_edi_trg_hold_m ), cv_d_format_mm )
                                                    --登録業務日付が保持期間より前
      FOR UPDATE OF
        xseh.sales_exp_header_id
      NOWAIT
      ;
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
    -- ロック取得、データ取得
    OPEN no_taget_cur;
    FETCH no_taget_cur INTO ln_data_chk;
    CLOSE no_taget_cur;
--
    IF  ( ln_data_chk <> cn_0 ) THEN
      BEGIN
        ----------------------
        --販売実績ヘッダ更新
        ----------------------
        UPDATE  /*+
                  INDEX(xseh xxcos_sales_exp_headers_n03)
                */
                xxcos_sales_exp_headers   xseh  --販売実績ヘッダ
        SET     xseh.edi_interface_flag      = cv_s                       --EDI送信済みフラグ(対象外)
               ,xseh.last_updated_by         = cn_last_updated_by         --最終更新者
               ,xseh.last_update_date        = cd_last_update_date        --最終更新日
               ,xseh.last_update_login       = cn_last_update_login       --最終更新ログイン
               ,xseh.request_id              = cn_request_id              --要求ID
               ,xseh.program_application_id  = cn_program_application_id  --コンカレント・プログラム・アプリケーションID
               ,xseh.program_id              = cn_program_id              --コンカレント・プログラムID
               ,xseh.program_update_date     = cd_program_update_date     --プログラム更新日
       WHERE    xseh.edi_interface_flag      = cv_n                       --EDI送信済フラグ(未送信)
       AND      xseh.business_date           < TRUNC( ADD_MONTHS( cd_process_date, - gn_edi_trg_hold_m ), cv_d_format_mm )
       ;
       --件数取得
       gn_target_cnt := SQL%ROWCOUNT;
      EXCEPTION
        WHEN OTHERS THEN
          --トークン取得
          lv_tkn_name := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          ,iv_name          => cv_msg_table_tkn2  --販売実績ヘッダテーブル
                         );
          --メッセージ編集
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application  --アプリケーション
                         ,iv_name         => cv_msg_upd_err  --データ更新エラー
                         ,iv_token_name1  => cv_tkn_table_n  --トークンコード１
                         ,iv_token_value1 => lv_tkn_name     --販売実績ヘッダ
                         ,iv_token_name2  => cv_tkn_key      --トークンコード２
                         ,iv_token_value2 => NULL            --NULL
                       );
          lv_errbuf := SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
    ----------------------
    --正常件数の設定
    ----------------------
    gn_normal_cnt := gn_target_cnt;
--
  EXCEPTION
    -- *** ロックエラー ***
    WHEN lock_expt THEN
      --カーソルクローズ
      IF ( no_taget_cur%ISOPEN ) THEN
        CLOSE no_taget_cur;
      END IF;
      --トークン取得
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_table_tkn2  --販売実績ヘッダテーブル
                     );
      --メッセージ取得
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --アプリケーション
                     ,iv_name         => cv_msg_lock_err    --ロックエラー
                     ,iv_token_name1  => cv_tkn_table       --トークンコード１
                     ,iv_token_value1 => lv_tkn_name        --販売実績ヘッダテーブル
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
  END upd_no_target;
/* 2010/03/16 Ver1.10 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_run_class      IN VARCHAR2,   -- 実行区分：「0:作成」「1:解除」「2:対象外更新」
    iv_inv_cust_code  IN VARCHAR2,   -- 請求先顧客コード
    iv_send_date      IN VARCHAR2,   -- 送信日(YYYYMMDD)
/* 2009/04/15 Add Start */
    iv_sales_exp_ptn  IN VARCHAR2,   -- EDI販売実績処理パターン
/* 2009/04/15 Add End   */
    ov_errbuf         OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_no_target_msg      VARCHAR2(5000);  --対象なしメッセージ取得用
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
    -- 入力パラメタチェック処理(A-1)
    -- ===============================
    input_param_check(
      iv_run_class     -- 実行区分：「0:作成」「1:解除」「2:対象外更新」
     ,iv_inv_cust_code -- 請求先顧客コード
     ,iv_send_date     -- 送信日(YYYYMMDD)
/* 2009/04/15 Add Start */
     ,iv_sales_exp_ptn -- EDI販売実績処理パターン
/* 2009/04/15 Add End   */
     ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,lv_retcode       -- リターン・コード             --# 固定 #
     ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
/* 2010/03/16 Ver1.10 Add Start */
    --対象外更新処理以外の場合の請求先取得、存在チェックを実行
    IF ( iv_run_class <> gv_run_class_cd_update ) THEN
/* 2010/03/16 Ver1.10 Add End   */
      -- ===============================
      -- 処理対象顧客取得処理(A-2)
      -- ===============================
      get_custom_data(
        iv_inv_cust_code -- 請求先顧客コード
/* 2009/04/15 Add Start */
       ,iv_sales_exp_ptn -- EDI販売実績処理パターン
/* 2009/04/15 Add End   */
       ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,lv_retcode       -- リターン・コード             --# 固定 #
       ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
/* 2010/03/16 Ver1.10 Add Start */
    END IF;
/* 2010/03/16 Ver1.10 Add End   */
--
/* 2010/03/16 Ver1.10 Mod Start */
--    --==============================================================
--    --  作成処理の場合
--    --==============================================================
--    IF ( iv_run_class = gv_run_class_cd_create ) THEN
    IF ( iv_run_class <> gv_run_class_cd_cancel ) THEN
/* 2010/03/16 Ver1.10 Mod End   */
      -- ===============================
      -- 初期処理(A-3)
      -- ===============================
      init(
/* 2010/03/16 Ver1.10 Mod Start */
--        lv_errbuf        -- エラー・メッセージ           --# 固定 #
        iv_run_class     -- 実行区分
       ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
/* 2010/03/16 Ver1.10 Mod End   */
       ,lv_retcode       -- リターン・コード             --# 固定 #
       ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF  ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
/* 2010/03/16 Ver1.10 Add Start */
    END IF;
--
    --==============================================================
    --  作成処理の場合
    --==============================================================
    IF ( iv_run_class = gv_run_class_cd_create ) THEN
/* 2010/03/16 Ver1.10 Add End   */
      --処理対象顧客(チェーン店単位)ループ
      <<chain_store_loop>>
      FOR i IN 1.. gn_chain_store_cnt LOOP
        -- ===============================
        -- ファイル初期処理(A-4)
        -- ===============================
        output_header(
          gt_chain_store(i).chain_store_code  -- 処理対象顧客のチェーン店
         ,lv_errbuf                           -- エラー・メッセージ           --# 固定 #
         ,lv_retcode                          -- リターン・コード             --# 固定 #
         ,lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          --ファイルがOPENされている場合クローズ(A-10)
          IF ( UTL_FILE.IS_OPEN(
                 file => gt_f_handle
               )
             )
          THEN
            UTL_FILE.FCLOSE(
              file => gt_f_handle
            );
          END IF;
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- 販売実績情報抽出(A-5)
        -- ===============================
        get_sale_data(
          gt_chain_store(i).chain_store_code  -- 処理対象顧客のチェーン店
/* 2009/04/15 Del Start */
--         ,iv_inv_cust_code                    -- パラメータの請求先顧客コード
/* 2009/04/15 Del End   */
         ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
         ,lv_retcode       -- リターン・コード             --# 固定 #
         ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF  ( lv_retcode <> cv_status_normal ) THEN
          --ファイルがOPENされている場合クローズ(A-10)
          IF ( UTL_FILE.IS_OPEN(
                 file => gt_f_handle
               )
             )
          THEN
            UTL_FILE.FCLOSE(
              file => gt_f_handle
            );
          END IF;
          RAISE global_process_expt;
        END IF;
        --1チェーン店内の処理対象判定
        IF  ( gn_data_cnt <> cn_0 ) THEN
          -- ===============================
          -- データ編集(A-6),(A-7)
          -- ===============================
          edit_sale_data(
            gt_chain_store(i).chain_store_code  -- 処理対象顧客のチェーン店
           ,gt_chain_store(i).process_pattern   --処理対象の処理パターン
           ,lv_errbuf  -- エラー・メッセージ           --# 固定 #
           ,lv_retcode -- リターン・コード             --# 固定 #
           ,lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF  ( lv_retcode <> cv_status_normal ) THEN
            --ファイルがOPENされている場合クローズ(A-10)
            IF ( UTL_FILE.IS_OPEN(
                   file => gt_f_handle
                 )
               )
            THEN
              UTL_FILE.FCLOSE(
                file => gt_f_handle
              );
            END IF;
            RAISE global_process_expt;
          END IF;
          -- ===============================
          -- ファイル終了処理(A-8)
          -- ===============================
          output_footer(
            lv_errbuf   -- エラー・メッセージ           --# 固定 #
           ,lv_retcode  -- リターン・コード             --# 固定 #
           ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF  ( lv_retcode <> cv_status_normal ) THEN
            --ファイルがOPENされている場合クローズ(A-10)
            IF ( UTL_FILE.IS_OPEN(
                   file => gt_f_handle
                 )
               )
            THEN
              UTL_FILE.FCLOSE(
                file => gt_f_handle
              );
            END IF;
            RAISE global_process_expt;
          END IF;
          -- =========================================
          -- 販売実績ヘッダTBLフラグ更新（作成）(A-9)
          -- =========================================
          upd_sale_exp_head_send(
            lv_errbuf   -- エラー・メッセージ           --# 固定 #
           ,lv_retcode  -- リターン・コード             --# 固定 #
           ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF  ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          -- =========================================
          -- 処理件数の設定
          -- =========================================
          gn_target_cnt := gn_target_cnt + gn_data_cnt; --1チェーン店内の対象データを足す
        --対象なし
        ELSE
          --メッセージ取得
          lv_no_target_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_application        --アプリケーション
                                ,iv_name         => cv_msg_no_target_err  --パラメーター出力(処理対象なし)
                              );
          --メッセージに出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_no_target_msg
          );
          --空白出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => ''
          );
          -- ===============================
          -- ファイル終了処理(A-8)
          -- ===============================
          output_footer(
            lv_errbuf   -- エラー・メッセージ           --# 固定 #
           ,lv_retcode  -- リターン・コード             --# 固定 #
           ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF  ( lv_retcode <> cv_status_normal ) THEN
            --ファイルがOPENされている場合クローズ(A-10)
            IF ( UTL_FILE.IS_OPEN(
                   file => gt_f_handle
                 )
               )
            THEN
              UTL_FILE.FCLOSE(
                file => gt_f_handle
              );
            END IF;
            RAISE global_process_expt;
          END IF;
        END IF;
      END LOOP chain_store_loop;
      ----------------------
      --正常件数の設定
      ----------------------
      gn_normal_cnt := gn_target_cnt;
    --==============================================================
    --  解除処理
    --==============================================================
    ELSIF ( iv_run_class = gv_run_class_cd_cancel ) THEN
      -- ==========================================
      -- 販売実績ヘッダTBLフラグ更新（解除）(A-11)
      -- ==========================================
      upd_sale_exp_head_rep(
        iv_inv_cust_code -- 請求先顧客コード
       ,iv_send_date     -- 送信日
       ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,lv_retcode       -- リターン・コード             --# 固定 #
       ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
       );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
/* 2010/03/16 Ver1.10 Add Start */
    --==============================================================
    --  対象外更新処理
    --==============================================================
    ELSIF ( iv_run_class = gv_run_class_cd_update ) THEN
      -- ==========================================
      -- 販売実績抽出対象外更新(A-12)
      -- ==========================================
      upd_no_target(
        lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,lv_retcode       -- リターン・コード             --# 固定 #
       ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
       );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
/* 2010/03/16 Ver1.10 Add End   */
    END IF;
--
  EXCEPTION
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
    errbuf            OUT  VARCHAR2,     --   エラー・メッセージ  --# 固定 #
    retcode           OUT  VARCHAR2,     --   リターン・コード    --# 固定 #
    iv_run_class      IN   VARCHAR2,     --   実行区分：「0:作成」「1:解除」「2:対象外更新」
    iv_inv_cust_code  IN   VARCHAR2,     --   請求先顧客コード
/* 2009/04/15 Mod Start */
--    iv_send_date      IN   VARCHAR2      --   送信日(YYYYMMDD)
    iv_send_date      IN   VARCHAR2,     --   送信日(YYYYMMDD)
    iv_sales_exp_ptn  IN   VARCHAR2      --   EDI販売実績処理パターン
/* 2009/04/15 Mod End   */
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_run_class     -- 実行区分：「0:作成」「1:解除」「2:対象外更新」
      ,iv_inv_cust_code -- 請求先顧客コード
      ,iv_send_date     -- 送信日(YYYYMMDD)
/* 2009/04/15 Add Start */
      ,iv_sales_exp_ptn -- EDI販売実績処理パターン
/* 2009/04/15 Add End   */
      ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,lv_retcode       -- リターン・コード             --# 固定 #
      ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF  ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --エラーメッセージがある場合
    IF ( lv_errmsg IS NOT NULL ) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => ''
      );
    END IF;
    -- ===============================
    -- 終了処理(A-12)
    -- ===============================
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
   --*------------------------------------------------------------
    --終了メッセージ
    IF  ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF  ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF  ( lv_retcode = cv_status_error ) THEN
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
END XXCOS011A06C;
/
