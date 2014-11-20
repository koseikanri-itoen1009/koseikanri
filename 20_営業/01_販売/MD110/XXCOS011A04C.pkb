CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A04C (body)
 * Description      : 入庫予定データの作成を行う
 * MD.050           : 入庫予定データ作成 (MD050_COS_011_A04)
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0,A-1)
 *  output_header          ファイル初期処理(A-2)
 *  get_edi_stc_data       入庫予定情報抽出(A-3)
 *  chk_line_cnt           明細件数チェック処理(A-12)
 *  edit_edi_stc_data      データ編集(A-4,A-5,A-6)
 *  output_footer          ファイル終了処理(A-7)
 *  upd_edi_send_flag      フラグ更新(A-8)
 *  del_edi_stc_data       入庫予定パージ(A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/18    1.0  K.Kiriu          新規作成
 *  2008/02/27    1.1  K.Kiriu          [COS_147]税率の取得条件追加
 *  2009/03/10    1.2  T.Kitajima       [T1_0030]顧客品目の無効エラー対応
 *  2009/04/06    1.3  T.Kitajima       [T1_0043]顧客品目の絞り込み条件に単位を追加
 *  2009/04/28    1.4  K.Kiriu          [T1_0756]レコード長変更対応
 *  2009/06/15    1.5  N.Maeda          [T1_1356]出力データファイルNo値修正
 *  2009/07/02    1.5  T.Tominaga       [T1_1359]数量換算対応
 *  2009/07/08    1.5  N.Maeda          [T1_1356]レビュー指摘対応
 *  2009/07/15    1.5  N.Maeda          [T1_1357]レビュー指摘対応
 *  2009/08/17    1.6  N.Maeda          [0000439]PT対応
 *  2009/08/24    1.6  N.Maeda          [0000439]レビュー指摘対応
 *  2009/09/25    1.7  N.Maeda          [0001156]顧客品目からの品目導出条件追加
 *  2010/03/16    1.8  Y.Kuboshima      [E_本稼動_01223]・対象件数0件時のステータス変更対応
 *                                      [E_本稼動_01833]・ソート順の変更 (伝票番号 -> 伝票番号, 品目コード)
 *                                                      ・伝票番号, 品目コードのサマリを削除
 *                                                      ・入庫予定ヘッダテーブル,移動オーダーヘッダテーブルの
 *                                                        更新の条件にEDIチェーン店コードを追加
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
  global_data_check_expt    EXCEPTION;     -- データチェック時のエラー
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  --ロックエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOS011A04C'; -- パッケージ名
--
  cv_application        CONSTANT VARCHAR2(5)   := 'XXCOS';        -- アプリケーション名
  -- プロファイル
  cv_prf_edi_p_term     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_PURGE_TERM';        -- XXCOS:EDI情報削除期間
  cv_prf_if_header      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_HEADER';             -- XXCCP:IFレコード区分_ヘッダ
  cv_prf_if_data        CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_DATA';               -- XXCCP:IFレコード区分_データ
  cv_prf_if_footer      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_FOOTER';             -- XXCCP:IFレコード区分_フッタ
  cv_prf_utl_m_line     CONSTANT VARCHAR2(50)  := 'XXCOS1_UTL_MAX_LINESIZE';      -- XXCOS:UTL_MAX行サイズ
  cv_prf_outbound_d     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_OUTBOUND_INV_DIR';  -- XXCOS:EDI%ディレクトリパス(名称略)
  cv_prf_bks_id         CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';             -- GL会計帳簿ID
  cv_prf_org_id         CONSTANT VARCHAR2(50)  := 'ORG_ID';                       -- MO:営業単位
  -- メッセージコード
  cv_msg_no_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- 対象データなしエラー
  cv_msg_lock_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ロックエラー
  cv_msg_param_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';  -- 必須入力パラメータ未設定エラー
  cv_msg_prf_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- プロファイル取得エラー
  cv_msg_base_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12301';  -- 拠点情報取得エラー
  cv_msg_edi_c_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00036';  -- EDIチェーン店情報取得エラー
  cv_msg_data_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12302';  -- データ種情報取得エラー
  cv_msg_edi_i_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00023';  -- EDI連携品目コード区分エラー
  cv_msg_tax_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12315';  -- 税率取得エラー
  cv_msg_out_inf_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00038';  -- 出力情報編集エラー
  cv_msg_upd_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12303';  -- データ更新エラー
  cv_msg_purge_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12304';  -- パージエラー
  cv_msg_file_o_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00009';  -- ファイルオープンエラー
  cv_msg_file_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00040';  -- IFファイルレイアウト定義情報取得エラー
  cv_msg_data_get_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';  -- データ抽出エラー
  cv_msg_line_cnt_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12316';  -- 入庫予定データ作成エラー
  cv_msg_param          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12305';  -- パラメーター出力
  cv_msg_file_nmae      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00044';  -- ファイル名出力
  cv_msg_l_meaning1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12308';  -- クイックコード取得条件(EDI媒体区分)
  cv_msg_param_tkn1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12309';  -- 搬送先保管場所
  cv_msg_param_tkn2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12310';  -- EDIチェーン店コード
  cv_msg_param_tkn3     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12311';  -- ファイル名
  cv_msg_prf_tkn1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12306';  -- EDI情報削除期間
  cv_msg_prf_tkn2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00104';  -- IFレコード区分_ヘッダ
  cv_msg_prf_tkn3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00105';  -- IFレコード区分_データ
  cv_msg_prf_tkn4       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00106';  -- IFレコード区分_フッタ
  cv_msg_prf_tkn5       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00107';  -- UTL_MAX行サイズ
  cv_msg_prf_tkn6       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00108';  -- 在庫系アウトバウンド用ディレクトリパス
  cv_msg_prf_tkn7       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';  -- GL会計帳簿ID
  cv_msg_prf_tkn8       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';  -- 営業単位
  cv_msg_layout_tkn1    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00071';  -- 受注系レイアウト
  cv_msg_lookup_tkn1    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00110';  -- クイックコード(EDI媒体区分)
  cv_msg_table_tkn1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';  -- クイックコード
  cv_msg_tbale_tkn2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12312';  -- 入庫予定テーブル
  cv_msg_tbale_tkn3     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12313';  -- 移動オーダーヘッダテーブル
  cv_msg_tbale_tkn4     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12314';  -- 入庫予定ヘッダテーブル
-- ************ 2009/08/24 N.Maeda 1.6 ADD START ***************** --
  cv_msg_category_err             CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12954';     --カテゴリセットID取得エラーメッセージ
  cv_msg_item_div_h               CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12955';     --本社商品区分
-- ************ 2009/08/24 N.Maeda 1.6 ADD  END  ***************** --
  -- トークンコード
  cv_tkn_in_param       CONSTANT VARCHAR2(8)   := 'IN_PARAM';          -- パラメータ名称
  cv_tkn_prf            CONSTANT VARCHAR2(7)   := 'PROFILE';           -- プロファイル名称
  cv_tkn_sub_i          CONSTANT VARCHAR2(6)   := 'SUBINV';            -- 搬送先保管場所
  cv_tkn_forw_n         CONSTANT VARCHAR2(12)  := 'EDI_PARA_NUM';      -- EDI伝送追番
  cv_tkn_chain_s        CONSTANT VARCHAR2(15)  := 'CHAIN_SHOP_CODE';   -- チェーン店
  cv_tkn_err_m          CONSTANT VARCHAR2(6)   := 'ERRMSG';            -- エラーメッセージ名
  cv_tkn_table          CONSTANT VARCHAR2(5)   := 'TABLE';             -- テーブル名
  cv_tkn_file_n         CONSTANT VARCHAR2(9)   := 'FILE_NAME';         -- ファイル名
  cv_tkn_file_l         CONSTANT VARCHAR2(6)   := 'LAYOUT';            -- ファイルレイアウト情報
  cv_tkn_table_n        CONSTANT VARCHAR2(10)  := 'TABLE_NAME';        -- テーブル名
  cv_tkn_key            CONSTANT VARCHAR2(8)   := 'KEY_DATA';          -- キーデータ
  cv_tkn_cnt            CONSTANT VARCHAR2(5)   := 'COUNT';             -- 件数
  cv_tkn_pram1          CONSTANT VARCHAR2(6)   := 'PARAM1';            -- パラメーター１
  cv_tkn_pram2          CONSTANT VARCHAR2(6)   := 'PARAM2';            -- パラメーター２
  cv_tkn_pram3          CONSTANT VARCHAR2(6)   := 'PARAM3';            -- パラメーター３
  cv_tkn_invoice_num    CONSTANT VARCHAR2(11)  := 'INVOICE_NUM';       -- 伝票番号
  cv_tkn_item_code      CONSTANT VARCHAR2(20)  := 'ITEM_CODE';         -- 品目コード
  cv_tkn_cust_item_code CONSTANT VARCHAR2(20)  := 'CUST_ITEM_CODE';    -- 顧客品目コード
-- ************ 2009/08/24 N.Maeda 1.6 ADD START ***************** --
  ct_item_div_h                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ITEM_DIV_H';
-- ************ 2009/08/24 N.Maeda 1.6 ADD  END  ***************** --
-- ************ 2009/08/24 N.Maeda 1.6 ADD START ***************** --
  ct_user_lang                    CONSTANT mtl_category_sets_tl.language%TYPE := userenv('LANG'); --LANG
-- ************ 2009/08/24 N.Maeda 1.6 ADD  END  ***************** --
  -- 日付
  cd_sysdate            CONSTANT DATE          := SYSDATE;                            -- システム日付
  cd_process_date       CONSTANT DATE          := xxccp_common_pkg2.get_process_date; -- 業務処理日
  -- 顧客マスタ取得用固定値
  cv_cust_code_chain    CONSTANT VARCHAR2(2)   := '18';                -- 顧客区分(チェーン店)
  cv_cust_code_cust     CONSTANT VARCHAR2(2)   := '10';                -- 顧客区分(顧客)
  cv_cust_status        CONSTANT VARCHAR2(2)   := '90';                -- 顧客ステータス(中止決裁済)
  cv_status_a           CONSTANT VARCHAR2(1)   := 'A';                 -- ステータス(顧客有効)
  -- クイックコードタイプ
  cv_edi_media_class_t  CONSTANT VARCHAR2(22)  := 'XXCOS1_EDI_MEDIA_CLASS';  -- EDI媒体区分
  cv_data_type_code_t   CONSTANT VARCHAR2(21)  := 'XXCOS1_DATA_TYPE_CODE';   -- データ種
  -- クイックコード
  cv_data_type_code_c   CONSTANT VARCHAR2(3)   := '050';               -- データ種(入庫予定)
  -- その他固定値
  cv_date_format        CONSTANT VARCHAR2(8)   := 'YYYYMMDD';          -- 日付フォーマット(日)
  cv_time_format        CONSTANT VARCHAR2(8)   := 'HH24MISS';          -- 日付フォーマット(時間)
-- ********** 2009/08/17 N.Maeda 1.6 ADD START ************** --
  cv_date_time_format   CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';  -- 日付フォーマット(日時)
-- ********** 2009/08/17 N.Maeda 1.6 ADD  END  ************** --
  cv_0                  CONSTANT VARCHAR2(1)   := '0';                 -- 固定値:0(VARCHAR2)
  cn_0                  CONSTANT NUMBER        := 0;                   -- 固定値:0(NUMBER)
  cv_1                  CONSTANT VARCHAR2(1)   := '1';                 -- 固定値:1(VARCHAR2)
  cn_1                  CONSTANT NUMBER        := 1;                   -- 固定値:1(NUMBER)
  cv_2                  CONSTANT VARCHAR2(1)   := '2';                 -- 固定値:2
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                 -- 固定値:Y
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';                 -- 固定値:N
  cv_w                  CONSTANT VARCHAR2(1)   := 'W';                 -- 固定値:W
--****************************** 2009/07/02 1.5 T.Tominaga ADD START ******************************
  cv_x                  CONSTANT VARCHAR2(1)   := 'X';                 -- 単位（ダミー値）
--****************************** 2009/07/02 1.5 T.Tominaga ADD END   ******************************
-- ********** 2009/08/17 N.Maeda 1.6 ADD START ************** --
  cv_time_data          CONSTANT VARCHAR2(8)   := '235959';
-- ********** 2009/08/17 N.Maeda 1.6 ADD  END  ************** --
  -- データ編集共通関数用
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
  cv_description_department   CONSTANT VARCHAR2(50)  := 'DESCRIPTION_DEPARTMENT';        --摘要2
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
/* 2009/04/28 Ver1.4 Add Start */
  cv_attribute                CONSTANT VARCHAR2(50)  := 'ATTRIBUTE';                     --予備エリア
/* 2009/04/28 Ver1.4 Add End   */
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  gt_f_handle           UTL_FILE.FILE_TYPE;                            --ファイルハンドラ
  gt_data_type_table    xxcos_common2_pkg.g_record_layout_ttype;       --ファイルレイアウト
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル出力項目用
  gv_f_o_date           CHAR(8);                                       --処理日
  gv_f_o_time           CHAR(6);                                       --処理時刻
  gt_tax_rate           ar_vat_tax_all_b.tax_rate%TYPE;                --税率
  gt_edi_media_class    fnd_lookup_values_vl.lookup_code%TYPE;         --EDI媒体区分
  gt_data_type_code     fnd_lookup_values_vl.lookup_code%TYPE;         --データ種コード
  -- 条件判定、共通関数用
  gt_edi_item_code_div  xxcmm_cust_accounts.edi_item_code_div%TYPE;    --EDI連携品目コード区分
  gt_chain_cust_acct_id hz_cust_accounts.cust_account_id%TYPE;         --顧客ID(チェーン店)
  gt_from_series        fnd_lookup_values_vl.attribute1%TYPE;          --IF元業務系列コード
  gv_edi_p_term         VARCHAR2(4);                                   --EDI情報削除期間
  gv_if_header          VARCHAR2(2);                                   --ヘッダレコード区分
  gv_if_data            VARCHAR2(2);                                   --データレコード区分
  gv_if_footer          VARCHAR2(2);                                   --フッタレコード区分
  gv_utl_m_line         VARCHAR2(100);                                 --UTL_MAX行サイズ
  gv_outbound_d         VARCHAR2(100);                                 --アウトバウンド用ディレクトリパス
  gn_bks_id             NUMBER;                                        --会計帳簿ID
  gn_org_id             NUMBER;                                        --営業単位
--********************  2009/07/08    1.5  N.Maeda ADD Start ********************
  gt_edi_f_number       xxcmm_cust_accounts.edi_forward_number%TYPE;   --EDI伝票追番
--********************  2009/07/08    1.5  N.Maeda ADD  End  ********************
-- ************ 2009/08/24 N.Maeda 1.6 ADD START ***************** --
   gt_category_set_id   mtl_category_sets_tl.category_set_id%TYPE;     --カテゴリセットID
-- ************ 2009/08/24 N.Maeda 1.6 ADD  END  ***************** --
  -- ===============================
  -- ユーザー定義グローバルRECORD型宣言
  -- ===============================
  --ヘッダ情報
  TYPE g_header_data_rtype IS RECORD(
    delivery_base_code        xxcmm_cust_accounts.delivery_base_code%TYPE,  --納品拠点コード
    delivery_base_name        hz_parties.party_name%TYPE,                   --納品拠点名
    delivery_base_phonetic    hz_parties.organization_name_phonetic%TYPE,   --納品拠点カナ
    delivery_base_l_phonetic  hz_locations.address_lines_phonetic%TYPE,     --納品拠点電話番号
    edi_chain_name            hz_parties.party_name%TYPE,                   --EDIチェーン店名
    edi_chain_name_phonetic   hz_parties.organization_name_phonetic%TYPE    --EDIチェーン店カナ
  );
  gt_header_data  g_header_data_rtype;
  --入庫予定情報
  TYPE g_edi_stc_data_rtype IS RECORD(
    header_id                    xxcos_edi_stc_headers.header_id%TYPE,                    --ヘッダID
    move_order_header_id         xxcos_edi_stc_headers.move_order_header_id%TYPE,         --移動オーダーヘッダID
    move_order_num               xxcos_edi_stc_headers.move_order_num%TYPE,               --移動オーダー番号
    to_subinventory_code         xxcos_edi_stc_headers.to_subinventory_code%TYPE,         --搬送先保管場所
    customer_code                xxcos_edi_stc_headers.customer_code%TYPE,                --顧客コード
    customer_name                hz_parties.party_name%TYPE,                              --顧客名称
    customer_phonetic            hz_parties.organization_name_phonetic%TYPE,              --顧客名カナ
    edi_chain_code               xxcos_edi_stc_headers.edi_chain_code%TYPE,               --EDIチェーン店コード
    shop_code                    xxcos_edi_stc_headers.shop_code%TYPE,                    --店コード
    shop_name                    xxcmm_cust_accounts.cust_store_name%TYPE,                --店名(漢字)
    center_code                  xxcos_edi_stc_headers.center_code%TYPE,                  --センターコード
    invoice_number               xxcos_edi_stc_headers.invoice_number%TYPE,               --伝票番号
    other_party_department_code  xxcos_edi_stc_headers.other_party_department_code%TYPE,  --相手先部門コード
    schedule_shipping_date       xxcos_edi_stc_headers.schedule_shipping_date%TYPE,       --出荷予定日
    schedule_arrival_date        xxcos_edi_stc_headers.schedule_arrival_date%TYPE,        --入庫予定日
    rcpt_possible_date           xxcos_edi_stc_headers.rcpt_possible_date%TYPE,           --受入可能日
    inspect_schedule_date        xxcos_edi_stc_headers.inspect_schedule_date%TYPE,        --検品予定日
    invoice_class                xxcos_edi_stc_headers.invoice_class%TYPE,                --伝票区分
    classification_class         xxcos_edi_stc_headers.classification_class%TYPE,         --分類区分
    whse_class                   xxcos_edi_stc_headers.whse_class%TYPE,                   --倉庫区分
    regular_ar_sale_class        xxcos_edi_stc_headers.regular_ar_sale_class%TYPE,        --定番特売区分
    opportunity_code             xxcos_edi_stc_headers.opportunity_code%TYPE,             --便コード
    inventory_item_id            xxcos_edi_stc_lines.inventory_item_id%TYPE,              --品目ID
    organization_id              xxcos_edi_stc_headers.organization_id%TYPE,              --組織ID
    item_code                    mtl_system_items_b.segment1%TYPE,                        --品目コード
    item_name                    xxcmn_item_mst_b.item_name%TYPE,                         --品目名漢字
    item_phonetic1               VARCHAR2(15),                                            --品目名カナ１
    item_phonetic2               VARCHAR2(15),                                            --品目名カナ２
    case_inc_num                 ic_item_mst_b.attribute11%TYPE,                          --ケース入数
    bowl_inc_num                 xxcmm_system_items_b.bowl_inc_num%TYPE,                  --ボール入数
    jan_code                     ic_item_mst_b.attribute21%TYPE,                          --JANコード
    itf_code                     ic_item_mst_b.attribute22%TYPE,                          --ITFコード
    item_div_code                mtl_categories_b.segment1%TYPE,                          --本社商品区分
    customer_item_number         mtl_customer_items.customer_item_number%TYPE,            --顧客品目コード
    case_qty                     NUMBER,                                                  --ケース数
    indv_qty                     NUMBER,                                                  --バラ数
--********************  2009/03/10    1.2  T.Kitajima ADD Start ********************
--    ship_qty                     NUMBER                                                   --出荷数量(合計、バラ)
    ship_qty                     NUMBER,                                                  --出荷数量(合計、バラ)
    inactive_flag                mtl_customer_items.inactive_flag%TYPE,                   --顧客品目.有効フラグ
    inactive_ref_flag            mtl_customer_item_xrefs.inactive_flag%TYPE              --顧客品目相互参照.有効フラグ
--********************  2009/03/10    1.2  T.Kitajima ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL Start ********************
----********************  2009/06/15    1.5  N.Maeda ADD Start ********************
--    edi_forward_number           xxcmm_cust_accounts.edi_forward_number%TYPE              --EDI伝票追番
----********************  2009/06/15    1.5  N.Maeda ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL  End  ********************
  );
-- ************************ 2009/07/15 N.Maeda 1.5 N.Maeda ADD start ********************* --
  TYPE g_inv_qty_sum_rtype IS RECORD(
     case_inc_num                ic_item_mst_b.attribute11%TYPE                            -- ケース入数
    ,indv_qty_sum                NUMBER                                                    --バラ、合計数量
    );
-- ************************ 2009/07/15 N.Maeda 1.5 N.Maeda ADD  end  ********************* --
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  --入庫予定情報 テーブル型
  TYPE g_edi_stc_data_ttype IS TABLE OF g_edi_stc_data_rtype INDEX BY BINARY_INTEGER;
  gt_edi_stc_date  g_edi_stc_data_ttype;
  --フラグ行進用伝票番号 テーブル型
  TYPE g_invoice_num_ttype IS TABLE OF xxcos_edi_stc_headers.invoice_number%TYPE INDEX BY BINARY_INTEGER;
  gt_invoice_num    g_invoice_num_ttype;
-- ************************ 2009/07/15 N.Maeda 1.5 N.Maeda ADD start ********************* --
  --ヘッダ数量算出用
  TYPE g_inv_qty_sum_ttype IS TABLE OF g_inv_qty_sum_rtype INDEX BY PLS_INTEGER;
  g_inv_qty_sum     g_inv_qty_sum_ttype;
-- ************************ 2009/07/15 N.Maeda 1.5 N.Maeda ADD  end  ********************* --
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0,A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_name        IN  VARCHAR2,                                           --  ファイル名
    it_to_s_code        IN  mtl_txn_request_headers.to_subinventory_code%TYPE,  --  搬送先保管場所
    it_edi_c_code       IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --  EDIチェーン店コード
    iv_edi_f_number     IN  xxcmm_cust_accounts.edi_forward_number%TYPE,        --  EDI伝送追番
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
    lv_param_msg   VARCHAR2(5000);  --パラメーター出力用
    lv_tkn_name1   VARCHAR2(50);    --トークン取得用1
    lv_tkn_name2   VARCHAR2(50);    --トークン取得用2
    ln_err_chk     NUMBER(1);       --プロファイルエラーチェック用
    lv_err_msg     VARCHAR2(5000);  --プロファイルエラー出力用(取得エラーごとに出力する為)
    lv_l_meaning fnd_lookup_values_vl.meaning%TYPE;  --クイックコード条件取得用
    lv_dummy       VARCHAR2(1);     --レイアウト定義のCSVヘッダー用(ファイルタイプが固定長なので使用されない)
-- ************ 2009/08/24 N.Maeda 1.6 ADD START ***************** --
    lt_item_div_h                           fnd_profile_option_values.profile_option_value%TYPE;
-- ************ 2009/08/24 N.Maeda 1.6 ADD  END  ***************** --
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
    --コンカレントの共通の初期出力
    --==============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --パラメータ出力メッセージ取得
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --アプリケーション
                     ,iv_name         => cv_msg_param       --パラメーター出力
                     ,iv_token_name1  => cv_tkn_pram1       --トークンコード１
                     ,iv_token_value1 => it_to_s_code       --搬送先保管場所
                     ,iv_token_name2  => cv_tkn_pram2       --トークンコード２
                     ,iv_token_value2 => it_edi_c_code      --EDIチェーン店コード
                     ,iv_token_name3  => cv_tkn_pram3       --トークンコード３
                     ,iv_token_value3 => iv_edi_f_number    --EDI伝送追番
                    );
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
    --ファイル名メッセージ取得
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --アプリケーション
                     ,iv_name         => cv_msg_file_nmae   --ファイル名出力
                     ,iv_token_name1  => cv_tkn_file_n      --トークンコード１
                     ,iv_token_value1 => iv_file_name       --ファイル名
                    );
    --ファイル名をメッセージに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --==============================================================
    --システム日付取得
    --==============================================================
    gv_f_o_date := TO_CHAR(cd_sysdate, cv_date_format);  --処理日
    gv_f_o_time := TO_CHAR(cd_sysdate, cv_time_format);  --処理時刻
    --==============================================================
    --パラメータチェック
    --==============================================================
    -- 搬送先保管場所
    IF ( it_to_s_code IS NULL ) THEN
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_param_tkn1  --搬送先保管場所
                      );
    -- EDIチェーン店コード
    ELSIF ( it_edi_c_code IS NULL ) THEN
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_param_tkn2  --EDIチェーン店コード
                      );
    -- EDI伝送追番
    ELSIF ( iv_edi_f_number IS NULL ) THEN
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_param_tkn3  --ファイル名
                      );
    END IF;
    --メッセージ設定
    IF ( it_to_s_code IS NULL )
      OR ( it_edi_c_code IS NULL )
      OR ( iv_edi_f_number IS NULL )
    THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application   --アプリケーション
                    ,iv_name         => cv_msg_param_err --パラメーター必須エラー
                    ,iv_token_name1  => cv_tkn_in_param  --トークンコード１
                    ,iv_token_value1 => lv_tkn_name1     --パラメータ名
                   );
      RAISE global_api_others_expt;
    END IF;
    --==============================================================
    --プロファイル情報の取得
    --==============================================================
    ln_err_chk     := 0;                                                --エラーチェック用変数の初期化
    gv_edi_p_term  := FND_PROFILE.VALUE( cv_prf_edi_p_term );           --EDI情報削除期間
    gv_if_header   := FND_PROFILE.VALUE( cv_prf_if_header );            --ヘッダレコード区分
    gv_if_data     := FND_PROFILE.VALUE( cv_prf_if_data );              --データレコード区分
    gv_if_footer   := FND_PROFILE.VALUE( cv_prf_if_footer );            --フッタレコード区分
    gv_utl_m_line  := FND_PROFILE.VALUE( cv_prf_utl_m_line );           --UTL_MAX行サイズ
    gv_outbound_d  := FND_PROFILE.VALUE( cv_prf_outbound_d );           --アウトバウンド用ディレクトリパス
    gn_bks_id      := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_bks_id ) );  --GL会計帳簿ID
    gn_org_id      := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_org_id ) );  --営業単位
-- ************ 2009/08/24 N.Maeda 1.6 ADD START ***************** --
    lt_item_div_h  := FND_PROFILE.VALUE(ct_item_div_h);                 --XXCOS:本社商品区分
-- ************ 2009/08/24 N.Maeda 1.6 ADD  END  ***************** --
    --EDI情報削除期間のチェック
    IF ( gv_edi_p_term IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --アプリケーション
                       ,iv_name         => cv_msg_prf_tkn1  --EDI情報削除期間
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
      ln_err_chk := 1;  --エラー有り
    END IF;
    --ヘッダレコード区分のチェック
    IF ( gv_if_header IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --アプリケーション
                       ,iv_name         => cv_msg_prf_tkn2  --ヘッダレコード区分
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
      ln_err_chk := 1;  --エラー有り
    END IF;
    --データレコード区分のチェック
    IF ( gv_if_data IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --アプリケーション
                       ,iv_name         => cv_msg_prf_tkn3  --データレコード区分
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
      ln_err_chk := 1;  --エラー有り
    END IF;
    --フッタレコード区分のチェック
    IF ( gv_if_footer IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --アプリケーション
                       ,iv_name         => cv_msg_prf_tkn4  --フッタレコード区分
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
      ln_err_chk := 1;  --エラー有り
    END IF;
    --UTL_MAX行サイズのチェック
    IF ( gv_utl_m_line IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --アプリケーション
                       ,iv_name         => cv_msg_prf_tkn5  --UTL_MAX行サイズ
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
      ln_err_chk := 1;  --エラー有り
    END IF;
    --アウトバウンド用ディレクトリパスのチェック
    IF ( gv_outbound_d IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --アプリケーション
                       ,iv_name         => cv_msg_prf_tkn6  --アウトバウンド用ディレクトリパス
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
      ln_err_chk := 1;  --エラー有り
    END IF;
    --GL会計帳簿IDのチェック
    IF ( gn_bks_id IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --アプリケーション
                       ,iv_name         => cv_msg_prf_tkn7  --GL会計帳簿ID
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
      ln_err_chk := 1;  --エラー有り
    END IF;
    --営業単位のチェック
    IF ( gn_org_id IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --アプリケーション
                       ,iv_name         => cv_msg_prf_tkn8  --営業単位
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
      ln_err_chk := 1;  --エラー有り
    END IF;
-- ************ 2009/08/24 N.Maeda 1.6 ADD START ***************** --
    IF ( lt_item_div_h IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application   --アプリケーション
                       ,iv_name         => cv_msg_item_div_h
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
      ln_err_chk := 1;  --エラー有り
    END IF;
-- ************ 2009/08/24 N.Maeda 1.6 ADD  END  ***************** --
    --プロファイル取得でエラーの場合
    IF ( ln_err_chk = 1 ) THEN
      RAISE global_api_others_expt;
    END IF;
    --==============================================================
    --クイックコード情報の取得
    --==============================================================
    --レイアウト定義情報
    xxcos_common2_pkg.get_layout_info(
      iv_file_type        =>  cv_0                --ファイル形式(固定長)
     ,iv_layout_class     =>  cv_0                --情報区分(受注系)
     ,ov_data_type_table  =>  gt_data_type_table  --データ型表
     ,ov_csv_header       =>  lv_dummy            --CSVヘッダ
     ,ov_errbuf           =>  lv_errbuf           --エラーメッセージ
     ,ov_retcode          =>  lv_retcode          --リターンコード
     ,ov_errmsg           =>  lv_errmsg           --ユーザー・エラー・メッセージ
    );
    IF (lv_retcode <> cv_status_normal) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application      --アプリケーション
                       ,iv_name         => cv_msg_layout_tkn1  --受注系レイアウト
                      );
      --メッセージ取得
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       --アプリケーション
                    ,iv_name         => cv_msg_file_inf_err  --IFファイルレイアウト定義情報取得エラー
                    ,iv_token_name1  => cv_tkn_file_l        --トークンコード１
                    ,iv_token_value1 => lv_tkn_name1         --受注系レイアウト
                   );
      RAISE global_data_check_expt;
    END IF;
    -- EDI連携品目コード区分
    BEGIN
      SELECT  xca.edi_item_code_div  edi_item_code_div  --EDI連携品目コード
             ,hca.cust_account_id    cust_account_id    --顧客ID(チェーン店)
      INTO    gt_edi_item_code_div
             ,gt_chain_cust_acct_id
      FROM    hz_cust_accounts    hca  --顧客
             ,xxcmm_cust_accounts xca  --顧客追加情報
      WHERE   hca.customer_class_code =  cv_cust_code_chain  --顧客区分(チェーン店)
      AND     hca.cust_account_id     =  xca.customer_id
      AND     xca.chain_store_code    =  it_edi_c_code       --EDIチェーン店コード
      ;
    EXCEPTION
      WHEN OTHERS THEN
        gt_edi_item_code_div := NULL;
        lv_errbuf            := SQLERRM;
    END;
    --取得できない、NULL、取得した区分がJANか、顧客以外の場合エラー
    IF ( gt_edi_item_code_div IS NULL )
      OR ( gt_edi_item_code_div NOT IN ( cv_1, cv_2 ) )
    THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       --アプリケーション
                    ,iv_name         => cv_msg_edi_i_inf_err --EDIチェーン店情報取得エラー
                    ,iv_token_name1  => cv_tkn_chain_s       --トークンコード１
                    ,iv_token_value1 => it_edi_c_code        --パラメータ名
                   );
      RAISE global_data_check_expt;
    END IF;
    -- 税率
    BEGIN
      SELECT  xtrv.tax_rate             --税率
      INTO    gt_tax_rate
      FROM    hz_cust_accounts    hca   --顧客
             ,hz_parties          hp    --パーティ
             ,xxcmm_cust_accounts xca   --顧客追加情報
             ,xxcos_tax_rate_v    xtrv  --消費税率ビュー
      WHERE   xtrv.set_of_books_id    =  gn_bks_id           --会計帳簿ID
      AND     (
                ( xtrv.start_date_active IS NULL )
                OR
                ( xtrv.start_date_active <= cd_process_date )
              )
      AND     (
                ( xtrv.end_date_active IS NULL )
                OR
                ( xtrv.end_date_active >= cd_process_date )
              )                                              --業務日付がFROM-TO内
      AND     xtrv.tax_start_date <= cd_process_date         --税開始日が業務開始日以前
      AND     (
                ( xtrv.tax_end_date IS NULL )
                OR
                ( xtrv.tax_end_date >= cd_process_date )
              )                                              --税終了日がNULLもしくは業務開始日以降
      AND     xtrv.account_number     =  hca.account_number
      AND     hp.duns_number_c        <> cv_cust_status      --顧客ステータス(中止決裁済以外)
      AND     hca.party_id            =  hp.party_id
      AND     hca.status              =  cv_status_a         --ステータス(有効)
      AND     hca.customer_class_code =  cv_cust_code_cust   --顧客区分(顧客)
      AND     hca.cust_account_id     =  xca.customer_id
      AND     xca.chain_store_code    =  it_edi_c_code       --EDIチェーン店
      AND     xca.ship_storage_code   =  it_to_s_code        --搬送先保管場所
      AND     rownum                  =  cn_1
      ;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  --アプリケーション
                      ,iv_name         => cv_msg_tax_err  --税率取得エラー
                      ,iv_token_name1  => cv_tkn_chain_s  --トークンコード１
                      ,iv_token_value1 => it_edi_c_code   --パラメータ名
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_data_check_expt;
    END;
    -- EDI媒体区分
    BEGIN
      --メッセージより内容を取得
      lv_l_meaning := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --アプリケーション
                       ,iv_name         => cv_msg_l_meaning1  --クイックコード取得条件(EDI媒体区分)
                      );
      --クイックコード取得
      SELECT flvv.lookup_code lookup_code
      INTO   gt_edi_media_class
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type   = cv_edi_media_class_t
      AND    flvv.meaning       = lv_l_meaning
      AND    flvv.enabled_flag  = cv_y          --有効
      AND    (
               ( flvv.start_date_active IS NULL )
               OR
               ( flvv.start_date_active <= cd_process_date )
             )
      AND    (
               ( flvv.end_date_active IS NULL )
               OR
               ( flvv.end_date_active >= cd_process_date )
             )  --業務日付がFROM-TO内
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --アプリケーション
                        ,iv_name         => cv_msg_table_tkn1  --クイックコード
                       );
        lv_tkn_name2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --アプリケーション
                        ,iv_name         => cv_msg_lookup_tkn1 --クイックコード(EDI媒体区分)
                       );
        ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application       --アプリケーション
                      ,iv_name         => cv_msg_data_get_err  --データ抽出エラー
                      ,iv_token_name1  => cv_tkn_table_n       --トークンコード１
                      ,iv_token_value1 => lv_tkn_name1         --パラメータ名
                      ,iv_token_name2  => cv_tkn_key           --トークンコード２
                      ,iv_token_value2 => lv_tkn_name2         --パラメータ名
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_data_check_expt;
    END;
    -- データ種情報
    BEGIN
      SELECT  flvv.meaning     meaning     --データ種
             ,flvv.attribute1  attribute1  --IF元業務系列コード
      INTO    gt_data_type_code
             ,gt_from_series
      FROM    fnd_lookup_values_vl flvv
      WHERE   flvv.lookup_type  = cv_data_type_code_t
      AND     flvv.lookup_code  = cv_data_type_code_c
      AND     flvv.enabled_flag = cv_y          --有効
      AND    (
               ( flvv.start_date_active IS NULL )
               OR
               ( flvv.start_date_active <= cd_process_date )
             )
      AND    (
               ( flvv.end_date_active IS NULL )
               OR
               ( flvv.end_date_active >= cd_process_date )
             )  --業務日付がFROM-TO内
      ;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application       --アプリケーション
                      ,iv_name         => cv_msg_data_inf_err  --データ抽出エラー
                     );
        lv_errbuf  := SQLERRM;
      RAISE global_data_check_expt;
    END;
--
-- ************ 2009/08/24 N.Maeda 1.6 ADD START ***************** --
    IF ( lt_item_div_h IS NOT NULL ) THEN
    -- =============================================================
    -- カテゴリセットID取得
    -- =============================================================
      BEGIN
        SELECT  mcst.category_set_id   category_set_id
        INTO    gt_category_set_id
        FROM    mtl_category_sets_tl   mcst
        WHERE   mcst.category_set_name = lt_item_div_h
        AND     mcst.language          = ct_user_lang;
      EXCEPTION
        WHEN OTHERS THEN
          ov_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application,
                           iv_name         =>  cv_msg_category_err
                           );
          lv_errbuf  := SQLERRM;
          RAISE global_data_check_expt;
      END;
    END IF;
-- ************ 2009/08/24 N.Maeda 1.6 ADD  END  ***************** --
--
    --==============================================================
    -- ファイルオープン
    --==============================================================
    BEGIN
      gt_f_handle := UTL_FILE.FOPEN(
                       location      =>  gv_outbound_d  --アウトバウンド用ディレクトリパス
                      ,filename      =>  iv_file_name   --ファイル名
                      ,open_mode     =>  cv_w           --オープンモード
                      ,max_linesize  =>  gv_utl_m_line  --MAXサイズ
                     );
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                       cv_application
                      ,cv_msg_file_o_err
                      ,cv_tkn_file_n
                      ,iv_file_name
                     );
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
    -- *** クイックコード取得エラー ****
    WHEN global_data_check_expt THEN
      --値がNULL、もしくは対象外
      IF ( lv_errbuf IS NULL ) THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      --その他例外
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
   * Procedure Name   : output_header
   * Description      : ファイル初期処理(A-2)
   ***********************************************************************************/
  PROCEDURE output_header(
    it_to_s_code     IN  mtl_txn_request_headers.to_subinventory_code%TYPE,  --  1.搬送先保管場所
    it_edi_c_code    IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --  2.EDIチェーン店コード
    iv_edi_f_number  IN  xxcmm_cust_accounts.edi_forward_number%TYPE,        --  3.EDI伝送追番
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
/* 2009/04/28 Ver1.4 Mod Start */
--    lv_header_output  VARCHAR2(1000);  --ヘッダー出力用
    lv_header_output  VARCHAR2(5000);  --ヘッダー出力用
/* 2009/04/28 Ver1.4 Mod End   */
    ln_dummy          NUMBER;          --ヘッダ出力のレコード件数用(使用されない)
--
    -- *** ローカル・カーソル ***
    --拠点情報
    CURSOR cust_base_cur
    IS
      SELECT  hca.account_number             delivery_base_code         --納品拠点コード
             ,hp.party_name                  delivery_base_name         --納品拠点名
             ,hp.organization_name_phonetic  delivery_base_phonetic     --納品拠点名カナ
             ,hl.address_lines_phonetic      delivery_base_l_phonetic1  --納品拠点電話番号
      FROM    hz_cust_accounts        hca   --拠点(顧客)
             ,hz_parties              hp    --拠点(パーティ)
             ,hz_cust_acct_sites_all  hcas  --顧客所在地
             ,hz_party_sites          hps   --パーティサイト
             ,hz_locations            hl    --顧客所在地(アカウントサイト)
      WHERE   hps.location_id          = hl.location_id        --結合(パーティサイト = 顧客所在地(アカウント))
      AND     hcas.org_id              = gn_org_id             --営業単位
      AND     hcas.party_site_id       = hps.party_site_id     --結合(顧客所在地 = パーティサイト)
      AND     hca.cust_account_id      = hcas.cust_account_id  --結合(拠点(顧客) = 顧客所在地)
      AND     hca.party_id             = hp.party_id           --結合(拠点(顧客) = 拠点(パーティ))
      AND     hca.account_number       = 
                ( SELECT  xca1.delivery_base_code
                  FROM    hz_cust_accounts     hca1  --顧客
                         ,hz_parties           hp1   --パーティ
                         ,xxcmm_cust_accounts  xca1  --顧客追加情報
                  WHERE   hp1.duns_number_c        <> cv_cust_status     --顧客ステータス(中止決裁済以外)
                  AND     hca1.party_id            =  hp1.party_id       --結合(顧客 = パーティ)
                  AND     hca1.status              =  cv_status_a        --ステータス(顧客有効)
                  AND     hca1.customer_class_code =  cv_cust_code_cust  --顧客区分(顧客)
                  AND     hca1.cust_account_id     =  xca1.customer_id   --結合(顧客 = 顧客追加)
                  AND     xca1.ship_storage_code   =  it_to_s_code       --搬送先保管場所
                  AND     xca1.chain_store_code    =  it_edi_c_code      --EDIチェーン店コード
                  AND     ROWNUM                   =  cn_1
                )
      ;
    --EDIチェーン店情報
    CURSOR edi_chain_cur
    IS
      SELECT  hp.party_name                  edi_chain_name      --EDIチェーン店名
             ,hp.organization_name_phonetic  edi_chain_phonetic  --EDIチェーン店名カナ
      FROM    hz_parties          hp   --パーティ
             ,hz_cust_accounts    hca  --顧客
      WHERE   hca.party_id         =  hp.party_id            --結合(顧客 = パーティ)
      AND     hca.cust_account_id  =  gt_chain_cust_acct_id  --顧客ID(チェーン店)
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
    --各情報の取得
    --==============================================================
    --拠点情報
    OPEN cust_base_cur;
    FETCH cust_base_cur
      INTO  gt_header_data.delivery_base_code        --納品拠点コード
           ,gt_header_data.delivery_base_name        --納品拠点名
           ,gt_header_data.delivery_base_phonetic    --納品拠点名カナ
           ,gt_header_data.delivery_base_l_phonetic  --納品拠点電話番号
    ;
    --データが取得できない場合エラー
    IF ( cust_base_cur%NOTFOUND )THEN
      CLOSE cust_base_cur;
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       --アプリケーション
                    ,iv_name         => cv_msg_base_inf_err  --拠点情報取得エラー
                    ,iv_token_name1  => cv_tkn_sub_i         --トークンコード１
                    ,iv_token_value1 => it_to_s_code         --搬送先保管場所
                    ,iv_token_name2  => cv_tkn_chain_s       --トークンコード１
                    ,iv_token_value2 => it_edi_c_code        --EDIチェーン店コード
                    ,iv_token_name3  => cv_tkn_forw_n        --トークンコード１
                    ,iv_token_value3 => iv_edi_f_number      --EDI伝送追番
                    
                   );
      RAISE global_api_others_expt;
    END IF;
    CLOSE cust_base_cur;
    --EDIチェーン店情報
    OPEN edi_chain_cur;
    FETCH edi_chain_cur
      INTO  gt_header_data.edi_chain_name           --EDIチェーン店名
           ,gt_header_data.edi_chain_name_phonetic  --EDIチェーン店カナ
    ;
    --データが取得できない場合エラー
    IF ( edi_chain_cur%NOTFOUND )THEN
      CLOSE edi_chain_cur;
      --メッセージ
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       --アプリケーション
                    ,iv_name         => cv_msg_edi_c_inf_err --EDIチェーン店情報取得エラー
                    ,iv_token_name1  => cv_tkn_chain_s       --トークンコード１
                    ,iv_token_value1 => it_edi_c_code        --EDIチェーン店コード
                   );
      RAISE global_api_others_expt;
    END IF;
    CLOSE edi_chain_cur;
    --==============================================================
    --共通関数呼び出し
    --==============================================================
    --EDIヘッダ・フッタ付与
    xxccp_ifcommon_pkg.add_edi_header_footer(
      iv_add_area        =>  gv_if_header    --付与区分
     ,iv_from_series     =>  gt_from_series  --IF元業務系列コード
     ,iv_base_code       =>  gt_header_data.delivery_base_code
     ,iv_base_name       =>  gt_header_data.delivery_base_name
     ,iv_chain_code      =>  it_edi_c_code
     ,iv_chain_name      =>  gt_header_data.edi_chain_name
     ,iv_data_kind       =>  gt_data_type_code
     ,iv_row_number      =>  iv_edi_f_number
     ,in_num_of_records  =>  ln_dummy
     ,ov_retcode         =>  lv_retcode
     ,ov_output          =>  lv_header_output
     ,ov_errbuf          =>  lv_errbuf
     ,ov_errmsg          =>  lv_errmsg
    );
    IF (lv_retcode <> cv_status_normal) THEN
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
-- ********************* 2009/07/08 1.5  N.Maeda MOD Start ********************--
   -- ファイルNo.用
   gt_edi_f_number := iv_edi_f_number;
-- ********************* 2009/07/08 1.5  N.Maeda MOD  End  ********************--
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
   * Procedure Name   : get_edi_stc_data
   * Description      : 入庫予定情報抽出(A-3)
   ***********************************************************************************/
  PROCEDURE get_edi_stc_data(
    it_to_s_code   IN  mtl_txn_request_headers.to_subinventory_code%TYPE,  --  1.搬送先保管場所
    it_edi_c_code  IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --  2.EDIチェーン店コード
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_edi_stc_data'; -- プログラム名
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
    --EDI連携品目コード「顧客品目」
    CURSOR cust_item_cur
    IS
      SELECT  xesh.header_id                          header_id                    --ヘッダID
             ,xesh.move_order_header_id               move_order_header_id         --移動オーダーヘッダID
             ,xesh.move_order_num                     move_order_num               --移動オーダー番号
             ,xesh.to_subinventory_code               to_subinventory_code         --搬送先保管場所
             ,xesh.customer_code                      customer_code                --顧客コード
             ,hca.party_name                          customer_name                --顧客名称
             ,hca.organization_name_phonetic          customer_phonetic            --顧客名カナ
             ,xesh.edi_chain_code                     edi_chain_code               --EDIチェーン店コード
             ,xesh.shop_code                          shop_code                    --店コード
             ,hca.cust_store_name                     shop_name                    --店名
             ,xesh.center_code                        center_code                  --センターコード
             ,xesh.invoice_number                     invoice_number               --伝票番号
             ,xesh.other_party_department_code        other_party_department_code  --相手先部門コード
             ,xesh.schedule_shipping_date             schedule_shipping_date       --出荷予定日
             ,xesh.schedule_arrival_date              schedule_arrival_date        --入庫予定日
             ,xesh.rcpt_possible_date                 rcpt_possible_date           --受入可能日
             ,xesh.inspect_schedule_date              inspect_schedule_date        --検品予定日
             ,xesh.invoice_class                      invoice_class                --伝票区分
             ,xesh.classification_class               classification_class         --分類区分
             ,xesh.whse_class                         whse_class                   --倉庫区分
             ,xesh.regular_ar_sale_class              regular_ar_sale_class        --定番特売区分
             ,xesh.opportunity_code                   opportunity_code             --便コード
             ,xesl.inventory_item_id                  inventory_item_id            --品目ID
             ,xesh.organization_id                    organization_id              --組織ID
             ,msib.segment1                           item_code                    --品目コード
             ,ximb.item_name                          item_name                    --品目名漢字
             ,SUBSTRB( ximb.item_name_alt, 1, 15 )    item_phonetic1               --品目名カナ１
             ,SUBSTRB( ximb.item_name_alt, 16, 15 )   item_phonetic2               --品目名カナ２
             ,iimb.attribute11                        case_inc_num                 --ケース入数
             ,xsib.bowl_inc_num                       bowl_inc_num                 --ボール入数
             ,iimb.attribute21                        jan_code                     --JANコード
             ,iimb.attribute22                        itf_code                     --ITFコード
-- ************* 2009/08/24 1.6 N.Maeda MOD START ******************** --
             ,mcb.segment1                            item_div_code                --本社商品区分
--             ,xhpc.item_div_h_code                    item_div_code                --本社商品区分
-- ************* 2009/08/24 1.6 N.Maeda MOD  END  ******************** --
--********************  2009/03/10    1.2  T.Kitajima MOD Start ********************
--             ,mci.customer_item_number                customer_item_number         --顧客品目
             ,mcis.customer_item_number               customer_item_number         --顧客品目
--********************  2009/03/10    1.2  T.Kitajima MOD  End  ********************
             ,xesl.case_qty_sum                       case_qty                     --ケース数
             ,xesl.indv_qty_sum                       indv_qty                     --バラ数
             ,(
                 ( xesl.case_qty_sum * TO_NUMBER( NVL( iimb.attribute11, cn_1 ) ) ) + xesl.indv_qty_sum
              )                                       ship_qty                     --出荷数量(合計、バラ)
--********************  2009/03/10    1.2  T.Kitajima ADD Start ********************
             ,mcis.inactive_flag                      inactive_flag                --顧客品目.有効フラグ
             ,mcis.inactive_ref_flag                  inactive_ref_flag            --顧客品目相互参照.有効フラグ
--********************  2009/03/10    1.2  T.Kitajima ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL Start ********************
----********************  2009/06/15    1.5  N.Maeda ADD Start ********************
--             ,hca.edi_forward_number                  edi_forward_number           --EDI伝票追番
----********************  2009/06/15    1.5  N.Maeda ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL  End  ********************
      FROM    xxcos_edi_stc_headers   xesh    --入庫予定ヘッダ
             ,mtl_txn_request_headers mtrh    --移動オーダーヘッダ
             ,( SELECT  hca.account_number             account_number
                       ,hp.party_name                  party_name
                       ,hp.organization_name_phonetic  organization_name_phonetic
                       ,xca.cust_store_name            cust_store_name
--********************  2009/07/08    1.5  N.Maeda DEL Start ********************
----********************  2009/06/15    1.5  N.Maeda ADD Start ********************
--                       ,xca.edi_forward_number         edi_forward_number
----********************  2009/06/15    1.5  N.Maeda ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL  End  ********************
                FROM    hz_cust_accounts    hca
                       ,xxcmm_cust_accounts xca
                       ,hz_parties          hp
                WHERE   hp.duns_number_c     <> cv_cust_status  --顧客ステータス(中止決裁済以外)
                AND     hca.party_id         =  hp.party_id
                AND     hca.cust_account_id  =  xca.customer_id
                AND     hca.status           =  cv_status_a     --ステータス(有効)
              )                        hca     --顧客
             ,( SELECT  xesl.header_id          header_id
                       ,xesl.inventory_item_id  inventory_item_id
--********************  2010/03/16    1.8  Y.Kuboshima MOD Start *******************
-- 伝票番号, 品目コードのサマリの削除
--                       ,SUM( xesl.case_qty )    case_qty_sum
--                       ,SUM( xesl.indv_qty )    indv_qty_sum
                       ,xesl.case_qty           case_qty_sum
                       ,xesl.indv_qty           indv_qty_sum
--********************  2010/03/16    1.8  Y.Kuboshima MOD  End  *******************
                FROM    xxcos_edi_stc_lines   xesl
-- ********** 2009/08/17 N.Maeda 1.6 ADD START ************** --
                        ,xxcos_edi_stc_headers   xesh    --入庫予定ヘッダ
                WHERE   xesl.header_id         = xesh.header_id
                AND    xesh.edi_send_flag        = cv_n              --EDI送信済フラグ(未送信)
                AND    xesh.fix_flag             = cv_y              --確定済フラグ(確定済)
                AND    xesh.edi_chain_code       = it_edi_c_code     --EDIチェーン店コード
                AND    xesh.to_subinventory_code = it_to_s_code      --搬送先保管場所
-- ********** 2009/08/17 N.Maeda 1.6 ADD  END  ************** --
--********************  2010/03/16    1.8  Y.Kuboshima DEL Start *******************
-- 伝票番号, 品目コードのサマリの削除
--                GROUP BY
--                        xesl.header_id
--                       ,xesl.inventory_item_id
--********************  2010/03/16    1.8  Y.Kuboshima DEL  End  *******************
              )                        xesl   --入庫予定明細(品目サマリ)
--********************  2009/03/10    1.2  T.Kitajima ADD Start ********************
             ,(
                SELECT
-- ************* 2009/08/24 1.6 N.Maeda ADD START ******************** --
                       /*+
                         INDEX ( MCIX MTL_CUSTOMER_ITEM_XREFS_U2 )
                       */
-- ************* 2009/08/24 1.6 N.Maeda ADD  END  ******************** --
                        mci.customer_id             customer_id
                       ,customer_item_number        customer_item_number
                       ,mci.inactive_flag           inactive_flag
                       ,mcix.inactive_flag          inactive_ref_flag
                       ,mcix.inventory_item_id      inventory_item_id
                       ,mp.organization_id          organization_id
--********************  2009/04/06    1.3  T.Kitajima ADD Start ********************
                       ,mci.attribute1              attribute1
--********************  2009/04/06    1.3  T.Kitajima ADD  End  ********************
                FROM    mtl_customer_item_xrefs  mcix   --顧客品目相互参照
                       ,mtl_customer_items       mci    --顧客品目
                       ,mtl_parameters           mp     --在庫組織
                WHERE  mcix.customer_item_id        = mci.customer_item_id        --結合(顧客品目相 = 顧客品目)
                AND    mp.master_organization_id    = mcix.master_organization_id --結合(在庫組織   = 顧客品目相)
-- ************* 2009/09/25 1.7 N.Maeda ADD START ************
                AND    mcix.preference_number       = (
                         SELECT MIN(mcix_min.preference_number)
                         FROM    mtl_customer_item_xrefs  mcix_min
                                ,mtl_customer_items       mci_min
                                ,mtl_parameters           mp_min
                         WHERE  mcix_min.inventory_item_id      = mcix.inventory_item_id
                         AND    mcix_min.master_organization_id = mcix.master_organization_id
                         AND    mci_min.customer_id             = mci.customer_id
                         AND    mp_min.organization_id          = mp.organization_id
                         AND    mcix_min.customer_item_id       = mci_min.customer_item_id        --結合(顧客品目相 = 顧客品目)
                         AND    mp_min.master_organization_id   = mcix_min.master_organization_id --結合(在庫組織   = 顧客品目相)
                         AND    mcix_min.inactive_flag          = cv_n
                         AND    mci_min.inactive_flag           = cv_n
                         )
-- ************* 2009/09/25 1.7 N.Maeda ADD  END  ************
              ) mcis
--********************  2009/03/10    1.2  T.Kitajima ADD  End  ********************
             ,mtl_system_items_b       msib   --Disc品目
             ,xxcmm_system_items_b     xsib   --Disc品目アドオン
             ,ic_item_mst_b            iimb   --OPM品目
             ,xxcmn_item_mst_b         ximb   --OPM品目アドオン
--********************  2009/03/10    1.2  T.Kitajima EDL Start ********************
--             ,mtl_customer_item_xrefs  mcix   --顧客品目相互参照
--             ,mtl_customer_items       mci    --顧客品目
--             ,mtl_parameters           mp     --在庫組織
--********************  2009/03/10    1.2  T.Kitajima DEL  End  ********************
-- ************* 2009/08/24 1.6 N.Maeda MOD START ******************** --
             ,mtl_item_categories      mic    --品目カテゴリマスタ
             ,mtl_categories_b         mcb    --カテゴリマスタ
--             ,xxcos_head_prod_class_v  xhpc   --本社商品区分ビュー
-- ************* 2009/08/24 1.6 N.Maeda MOD  END  ******************** --
-- ************* 2009/08/24 1.6 N.Maeda MOD START ******************** --
--      WHERE  msib.inventory_item_id       = xhpc.inventory_item_id       --結合(D品目 = 本社商品区分)
      WHERE  msib.inventory_item_id       = mic.inventory_item_id        --結合(D品目 = 品目カテゴリマスタ)(品目ID)
      AND    msib.organization_id         = mic.organization_id          --結合(D品目 = 品目カテゴリマスタ)(在庫組織ID)
      AND    mic.category_set_id          = gt_category_set_id           --カテゴリセットID = 初期処理で取得したカテゴリセットID
      AND    mcb.category_id              = mic.category_id              --結合(カテゴリマスタ = 品目カテゴリマスタ)
      AND    ( mcb.disable_date IS NULL OR mcb.disable_date > cd_process_date )
      AND    mcb.enabled_flag                      = cv_y
      AND    ( cd_process_date BETWEEN NVL(mcb.start_date_active, cd_process_date) AND NVL(mcb.end_date_active, cd_process_date) )
      AND    msib.enabled_flag                     = cv_y
      AND    ( cd_process_date BETWEEN NVL(msib.start_date_active, cd_process_date) AND NVL(msib.end_date_active, cd_process_date) )
-- ************* 2009/08/24 1.6 N.Maeda MOD  END  ******************** --
--********************  2009/03/10    1.2  T.Kitajima MOD Start ********************
--      AND    mci.inactive_flag            = cv_n                         --有効フラグ(有効)
--      AND    mci.customer_id              = gt_chain_cust_acct_id        --チェーン店の顧客品目
--      AND    mcix.customer_item_id        = mci.customer_item_id         --結合(顧客品目相 = 顧客品目)
--      AND    mcix.inactive_flag           = cv_n                         --有効フラグ(有効)
--      AND    mp.master_organization_id    = mcix.master_organization_id  --結合(在庫組織 = 顧客品目相)
--      AND    msib.inventory_item_id       = mcix.inventory_item_id       --結合(D品目 = 顧客品目相)
--      AND    xesh.organization_id         = mp.organization_id           --結合(入庫H = 在庫組織)
      AND    mcis.customer_id(+)          = gt_chain_cust_acct_id          --チェーン店の顧客品目
      AND    msib.organization_id         = mcis.organization_id(+)        --結合(D品目 = 顧客品目相)
      AND    msib.inventory_item_id       = mcis.inventory_item_id(+)      --結合(D品目 = 顧客品目相)
--********************  2009/04/06    1.3  T.Kitajima ADD Start ********************
      AND    msib.primary_unit_of_measure = mcis.attribute1(+)             --結合(D品目 = 顧客品目相)
--********************  2009/04/06    1.3  T.Kitajima ADD  End  ********************
--********************  2009/03/10    1.2  T.Kitajima MOD  End  ********************
-- ************* 2009/09/25 1.7 N.Maeda ADD START ************
      AND    mcis.organization_id         = xesh.organization_id
-- ************* 2009/09/25 1.7 N.Maeda ADD  END  ************
      AND    ( cd_process_date BETWEEN ximb.start_date_active AND  ximb.end_date_active )  --O品目A適用日FROM-TO
      AND    iimb.item_id                 = ximb.item_id                 --結合(O品目 = O品目A)
      AND    msib.segment1                = iimb.item_no                 --結合(D品目 = O品目)
      AND    msib.segment1                = xsib.item_code               --結合(D品目 = D品目A)
      AND    xesh.organization_id         = msib.organization_id         --結合(入庫H = D品目 ヘッダの組織で結合する)
      AND    xesl.inventory_item_id       = msib.inventory_item_id       --結合(入庫L = D品目)
      AND    xesh.header_id               = xesl.header_id               --結合(入庫H = 入庫L)
      AND    xesh.customer_code           = hca.account_number           --結合(入庫H = 顧客)
      AND    NVL( mtrh.attribute1, cv_n ) = cv_n                         --入庫予定連携済フラグ(未連携)
      AND    xesh.move_order_header_id    = mtrh.header_id(+)            --結合(入庫H = 移動H)
      AND    xesh.edi_send_flag           = cv_n                         --EDI送信済フラグ(未送信)
      AND    xesh.fix_flag                = cv_y                         --確定済フラグ(確定済)
      AND    xesh.edi_chain_code          = it_edi_c_code                --EDIチェーン店コード
      AND    xesh.to_subinventory_code    = it_to_s_code                 --搬送先保管場所
      ORDER BY
             xesh.invoice_number  --伝票番号昇順(A-4で伝票番号順に処理をする為)
--********************  2010/03/16    1.8  Y.Kuboshima ADD Start *******************
-- ソート順に品目コードを追加
            ,msib.segment1
--********************  2010/03/16    1.8  Y.Kuboshima ADD  End  *******************
      FOR UPDATE OF
             xesh.header_id
            ,mtrh.header_id NOWAIT
      ;
    --EDI連携品目コード「JANコード」
    CURSOR jan_item_cur
    IS
      SELECT  xesh.header_id                          header_id                    --ヘッダID
             ,xesh.move_order_header_id               move_order_header_id         --移動オーダーヘッダID
             ,xesh.move_order_num                     move_order_num               --移動オーダー番号
             ,xesh.to_subinventory_code               to_subinventory_code         --搬送先保管場所
             ,xesh.customer_code                      customer_code                --顧客コード
             ,hca.party_name                          customer_name                --顧客名称
             ,hca.organization_name_phonetic          customer_phonetic            --顧客名カナ
             ,xesh.edi_chain_code                     edi_chain_code               --EDIチェーン店コード
             ,xesh.shop_code                          shop_code                    --店コード
             ,hca.cust_store_name                     shop_name                    --店名
             ,xesh.center_code                        center_code                  --センターコード
             ,xesh.invoice_number                     invoice_number               --伝票番号
             ,xesh.other_party_department_code        other_party_department_code  --相手先部門コード
             ,xesh.schedule_shipping_date             schedule_shipping_date       --出荷予定日
             ,xesh.schedule_arrival_date              schedule_arrival_date        --入庫予定日
             ,xesh.rcpt_possible_date                 rcpt_possible_date           --受入可能日
             ,xesh.inspect_schedule_date              inspect_schedule_date        --検品予定日
             ,xesh.invoice_class                      invoice_class                --伝票区分
             ,xesh.classification_class               classification_class         --分類区分
             ,xesh.whse_class                         whse_class                   --倉庫区分
             ,xesh.regular_ar_sale_class              regular_ar_sale_class        --定番特売区分
             ,xesh.opportunity_code                   opportunity_code             --便コード
             ,xesl.inventory_item_id                  inventory_item_id            --品目ID
             ,xesh.organization_id                    organization_id              --組織ID
             ,msib.segment1                           item_code                    --品目コード
             ,ximb.item_name                          item_name                    --品目名漢字
             ,SUBSTRB( ximb.item_name_alt, 1, 15 )    item_phonetic1               --品目名カナ１
             ,SUBSTRB( ximb.item_name_alt, 16, 15 )   item_phonetic2               --品目名カナ２
             ,iimb.attribute11                        case_inc_num                 --ケース入数
             ,xsib.bowl_inc_num                       bowl_inc_num                 --ボール入数
             ,iimb.attribute21                        jan_code                     --JANコード
             ,iimb.attribute22                        itf_code                     --ITFコード
-- ************* 2009/08/24 1.6 N.Maeda MOD START ******************** --
             ,mcb.segment1                            item_div_code                --本社商品区分
--             ,xhpc.item_div_h_code                    item_div_code                --本社商品区分
-- ************* 2009/08/24 1.6 N.Maeda MOD  END  ******************** --
             ,iimb.attribute21                        customer_item_number         --顧客品目(JANコード)
             ,xesl.case_qty_sum                       case_qty                     --ケース数
             ,xesl.indv_qty_sum                       indv_qty                     --バラ数
             ,(
                 ( xesl.case_qty_sum * TO_NUMBER( NVL( iimb.attribute11, cn_1 ) ) ) + xesl.indv_qty_sum
              )                                       ship_qty                     --出荷数量(合計、バラ)
--********************  2009/03/10    1.2  T.Kitajima ADD Start ********************
             ,NULL                                    inactive_flag                --EDI連携品目コード「顧客品目」の項目と合せるためのダミー
             ,NULL                                    inactive_ref_flag            --EDI連携品目コード「顧客品目」の項目と合せるためのダミー
--********************  2009/03/10    1.2  T.Kitajima MOD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL Start ********************
----********************  2009/06/15    1.5  N.Maeda ADD Start ********************
--             ,hca.edi_forward_number                  edi_forward_number           --EDI伝票追番
----********************  2009/06/15    1.5  N.Maeda ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL  End  ********************
      FROM    xxcos_edi_stc_headers   xesh    --入庫予定ヘッダ
             ,mtl_txn_request_headers mtrh    --移動オーダーヘッダ
             ,( SELECT  hca.account_number             account_number
                       ,hp.party_name                  party_name
                       ,hp.organization_name_phonetic  organization_name_phonetic
                       ,xca.cust_store_name            cust_store_name
--********************  2009/07/08    1.5  N.Maeda DEL Start ********************
----********************  2009/06/15    1.5  N.Maeda ADD Start ********************
--                       ,xca.edi_forward_number         edi_forward_number
----********************  2009/06/15    1.5  N.Maeda ADD  End  ********************
--********************  2009/07/08    1.5  N.Maeda DEL  End  ********************
                FROM    hz_cust_accounts    hca
                       ,xxcmm_cust_accounts xca
                       ,hz_parties          hp
                WHERE   hp.duns_number_c     <> cv_cust_status  --顧客ステータス(中止決裁済以外)
                AND     hca.party_id         =  hp.party_id
                AND     hca.cust_account_id  =  xca.customer_id
                AND     hca.status           =  cv_status_a     --ステータス(有効)
              )                       hca     --顧客
             ,( SELECT  xesl.header_id          header_id
                       ,xesl.inventory_item_id  inventory_item_id
--********************  2010/03/16    1.8  Y.Kuboshima MOD Start *******************
-- 伝票番号, 品目コードのサマリの削除
--                       ,SUM( xesl.case_qty )    case_qty_sum
--                       ,SUM( xesl.indv_qty )    indv_qty_sum
                       ,xesl.case_qty           case_qty_sum
                       ,xesl.indv_qty           indv_qty_sum
--********************  2010/03/16    1.8  Y.Kuboshima MOD  End  *******************
                FROM    xxcos_edi_stc_lines   xesl
-- ********** 2009/08/17 N.Maeda 1.6 ADD START ************** --
                        ,xxcos_edi_stc_headers   xesh    --入庫予定ヘッダ
                WHERE   xesl.header_id         = xesh.header_id
                AND    xesh.edi_send_flag        = cv_n              --EDI送信済フラグ(未送信)
                AND    xesh.fix_flag             = cv_y              --確定済フラグ(確定済)
                AND    xesh.edi_chain_code       = it_edi_c_code     --EDIチェーン店コード
                AND    xesh.to_subinventory_code = it_to_s_code      --搬送先保管場所
-- ********** 2009/08/17 N.Maeda 1.6 ADD  END  ************** --
--********************  2010/03/16    1.8  Y.Kuboshima DEL Start *******************
-- 伝票番号, 品目コードのサマリの削除
--                GROUP BY
--                        xesl.header_id
--                       ,xesl.inventory_item_id
--********************  2010/03/16    1.8  Y.Kuboshima DEL  End  *******************
              )                        xesl   --入庫予定明細(品目サマリ)
             ,mtl_system_items_b       msib   --Disc品目
             ,xxcmm_system_items_b     xsib   --Disc品目アドオン
             ,ic_item_mst_b            iimb   --OPM品目
             ,xxcmn_item_mst_b         ximb   --OPM品目アドオン
-- ************* 2009/08/24 1.6 N.Maeda MOD START ******************** --
             ,mtl_item_categories      mic    --品目カテゴリマスタ
             ,mtl_categories_b         mcb    --カテゴリマスタ
--             ,xxcos_head_prod_class_v  xhpc   --本社商品区分ビュー
-- ************* 2009/08/24 1.6 N.Maeda MOD  END  ******************** --
-- ************* 2009/08/24 1.6 N.Maeda MOD START ******************** --
--      WHERE  msib.inventory_item_id       = xhpc.inventory_item_id       --結合(D品目 = 本社商品区分)
      WHERE  msib.inventory_item_id       = mic.inventory_item_id        --結合(D品目 = 品目カテゴリマスタ)(品目ID)
      AND    msib.organization_id         = mic.organization_id          --結合(D品目 = 品目カテゴリマスタ)(在庫組織ID)
      AND    mic.category_set_id          = gt_category_set_id           --カテゴリセットID = 初期処理で取得したカテゴリセットID
      AND    mcb.category_id              = mic.category_id              --結合(カテゴリマスタ = 品目カテゴリマスタ)
      AND    ( mcb.disable_date IS NULL OR mcb.disable_date > cd_process_date )
      AND    mcb.enabled_flag                      = cv_y
      AND    ( cd_process_date BETWEEN NVL(mcb.start_date_active, cd_process_date) AND NVL(mcb.end_date_active, cd_process_date) )
      AND    msib.enabled_flag                     = cv_y
      AND    ( cd_process_date BETWEEN NVL(msib.start_date_active, cd_process_date) AND NVL(msib.end_date_active, cd_process_date) )
-- ************* 2009/08/24 1.6 N.Maeda MOD  END  ******************** --
      AND    ( cd_process_date BETWEEN ximb.start_date_active AND  ximb.end_date_active )  --O品目A適用日FROM-TO
      AND    iimb.item_id                 = ximb.item_id                 --結合(O品目 = O品目A)
      AND    msib.segment1                = iimb.item_no                 --結合(D品目 = O品目)
      AND    msib.segment1                = xsib.item_code               --結合(D品目 = D品目A)
      AND    xesh.organization_id         = msib.organization_id         --結合(入庫H = D品目 ヘッダの組織で結合する)
      AND    xesl.inventory_item_id       = msib.inventory_item_id       --結合(入庫L = D品目)
      AND    xesh.header_id               = xesl.header_id               --結合(入庫H = 入庫L)
      AND    xesh.customer_code           = hca.account_number           --結合(入庫H = 顧客)
      AND    NVL( mtrh.attribute1, cv_n ) = cv_n                         --入庫予定連携済フラグ(未連携)
      AND    xesh.move_order_header_id    = mtrh.header_id(+)            --結合(入庫H = 移動H)
      AND    xesh.edi_send_flag           = cv_n                         --EDI送信済フラグ(未送信)
      AND    xesh.fix_flag                = cv_y                         --確定済フラグ(確定済)
      AND    xesh.edi_chain_code          = it_edi_c_code                --EDIチェーン店コード
      AND    xesh.to_subinventory_code    = it_to_s_code                 --搬送先保管場所
      ORDER BY
             xesh.invoice_number  --伝票番号昇順(A-4で伝票番号順に処理をする為)
--********************  2010/03/16    1.8  Y.Kuboshima ADD Start *******************
-- ソート順に品目コードを追加
            ,msib.segment1
--********************  2010/03/16    1.8  Y.Kuboshima ADD  End  *******************
      FOR UPDATE OF
             xesh.header_id
            ,mtrh.header_id NOWAIT
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
    --入庫予定データ抽出
    --==============================================================
    --顧客品目の場合
   IF ( gt_edi_item_code_div = cv_1 ) THEN
      OPEN cust_item_cur;
      FETCH cust_item_cur BULK COLLECT INTO gt_edi_stc_date;
      --対象件数取得
      gn_target_cnt := cust_item_cur%ROWCOUNT;
      CLOSE cust_item_cur;
    --JANコードの場合
    ELSIF ( gt_edi_item_code_div = cv_2 ) THEN
      OPEN jan_item_cur;
      FETCH jan_item_cur BULK COLLECT INTO gt_edi_stc_date;
      --対象件数取得
      gn_target_cnt := jan_item_cur%ROWCOUNT;
      CLOSE jan_item_cur;
    END IF;
--
  EXCEPTION
    -- *** ロックエラー ***
    WHEN lock_expt THEN
      --カーソルクローズ
      IF ( cust_item_cur%ISOPEN ) THEN
        CLOSE cust_item_cur;
      END IF;
      IF ( jan_item_cur%ISOPEN ) THEN
        CLOSE jan_item_cur;
      END IF;
      --トークン取得
      lv_tkn_name := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     --アプリケーション
                      ,iv_name         => cv_msg_tbale_tkn2  --入庫予定テーブル
                     );
      --メッセージ取得
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application     --アプリケーション
                    ,iv_name         => cv_msg_lock_err    --ロックエラー
                    ,iv_token_name1  => cv_tkn_table       --トークンコード１
                    ,iv_token_value1 => lv_tkn_name        --入庫予定テーブル
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
  END get_edi_stc_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_line_cnt
   * Description      : 明細件数チェック処理(A-12)
   ***********************************************************************************/
  PROCEDURE chk_line_cnt(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_line_cnt'; -- プログラム名
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
    lv_invc_break         xxcos_edi_stc_headers.invoice_number%TYPE;  --伝票番号ブレーク用
    ln_header_id          xxcos_edi_stc_headers.header_id%TYPE;       --ブレイク前のヘッダID保持用
    ln_db_cnt             NUMBER;                                     --入庫予定明細の件数
    ln_line_cnt           NUMBER;                                     --A-3で抽出した明細の件数
    lv_err_msg            VARCHAR2(5000);                             --メッセージ格納用
    lv_chk_flag           VARCHAR2(1);                                --エラーチェックフラグ
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
    --初期化処理
    lv_chk_flag := cv_0;
    ln_line_cnt := cn_0;
    ln_db_cnt   := cn_0;
--
    <<check_loop>>
    FOR i IN 1.. gn_target_cnt  LOOP
--********************  2009/03/10    1.2  T.Kitajima MOD Start ********************
--      --ループの初期設定
--      IF ( i = cn_1 ) THEN
--        lv_invc_break := gt_edi_stc_date(i).invoice_number;
--        ln_header_id  := gt_edi_stc_date(i).header_id;
--      END IF;
----
--      --伝票番号がブレイク、もしくは最終行の場合
--      IF ( lv_invc_break <> gt_edi_stc_date(i).invoice_number )
--        OR ( i = gn_target_cnt )
--      THEN
--        -----------------------------
--        --ブレイク前のデータチェック
--        -----------------------------
--        IF ( lv_invc_break <> gt_edi_stc_date(i).invoice_number ) THEN
--          --ブレイク前の明細件数の取得(同一品目はサマリ)
--          SELECT  COUNT( 1 )
--          INTO    ln_db_cnt
--          FROM    ( SELECT  1
--                    FROM    xxcos_edi_stc_lines   xesl
--                    WHERE   xesl.header_id = ln_header_id
--                    GROUP BY
--                          xesl.inventory_item_id
--                  )
--          ;
--          --ブレイク前の入庫予定明細とA-3で抽出された件数(抽出されなかった明細がないか)のチェック
--          IF ( ln_db_cnt <> ln_line_cnt ) THEN
--            --メッセージ取得
--            lv_err_msg := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_application       --アプリケーション
--                           ,iv_name         => cv_msg_line_cnt_err  --入庫予定データ作成エラー
--                           ,iv_token_name1  => cv_tkn_invoice_num   --トークンコード１
--                           ,iv_token_value1 => lv_invc_break        --伝票番号
--                          );
--            --メッセージに出力
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_msg
--            );
--            --チェックフラグを変更する。
--            lv_chk_flag := cv_1;
--          END IF;
--        END IF;
--        -----------------------------
--        --最終行のデータチェック
--        -----------------------------
--        --最終行(最後の伝票番号)の確認
--        IF ( i = gn_target_cnt ) THEN
--          --最後行が前行と同じ伝票番号の場合
--          IF ( lv_invc_break = gt_edi_stc_date(i).invoice_number ) THEN
--            --最終行抽出データ件数分をインクリメント
--            ln_line_cnt := ln_line_cnt + cn_1;
--          ELSE
--            --最終行の件数のみ
--            ln_line_cnt := cn_1;
--          END IF;
--          --最終行の伝票番号の明細件数取得(同一品目はサマリ)
--          SELECT  COUNT( 1 )
--          INTO    ln_db_cnt
--          FROM    ( SELECT  1
--                    FROM    xxcos_edi_stc_lines   xesl
--                    WHERE   xesl.header_id = gt_edi_stc_date(i).header_id
--                    GROUP BY
--                            xesl.inventory_item_id
--                  )
--          ;
--          --最終行の入庫予定明細とA-3で抽出された件数(抽出されなかった明細がないか)のチェック
--          IF ( ln_db_cnt <> ln_line_cnt ) THEN
--            --メッセージ取得
--            lv_err_msg := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_application                     --アプリケーション
--                           ,iv_name         => cv_msg_line_cnt_err                --入庫予定データ作成エラー
--                           ,iv_token_name1  => cv_tkn_invoice_num                 --トークンコード１
--                           ,iv_token_value1 => gt_edi_stc_date(i).invoice_number  --伝票番号
--                          );
--            --メッセージに出力
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_msg
--            );
--          --チェックフラグを変更する。
--          lv_chk_flag := cv_1;
--          END IF;
--        END IF;
--        --明細件数、ヘッダIDにブレイク時の値を設定
--        ln_line_cnt   := cn_1;
--        ln_header_id  := gt_edi_stc_date(i).header_id;
--        --ブレイク用伝票番号設定
--        lv_invc_break := gt_edi_stc_date(i).invoice_number;
--      ELSE
--        --抽出データ件数のインクリメント
--        ln_line_cnt := ln_line_cnt + cn_1;
--      END IF;
      --顧客品目がNULLまたは、
      --顧客品目.有効フラグが無効または、
      --顧客品目相互参照.有効フラグが無効の場合エラーとする。
      IF ( gt_edi_stc_date(i).customer_item_number IS NULL )
        OR ( gt_edi_stc_date(i).inactive_flag = cv_y ) 
        OR ( gt_edi_stc_date(i).inactive_ref_flag = cv_y ) 
      THEN
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application                           --アプリケーション
                       ,iv_name         => cv_msg_line_cnt_err                      --入庫予定データ作成エラー
                       ,iv_token_name1  => cv_tkn_invoice_num                       --トークンコード１
                       ,iv_token_value1 => gt_edi_stc_date(i).invoice_number        --伝票番号
                       ,iv_token_name2  => cv_tkn_item_code                         --トークンコード２
                       ,iv_token_value2 => gt_edi_stc_date(i).item_code             --品目コード
                       ,iv_token_name3  => cv_tkn_cust_item_code                    --トークンコード３
                       ,iv_token_value3 => gt_edi_stc_date(i).customer_item_number  --顧客品目
                      );
            --メッセージに出力
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_msg
            );
        --チェックフラグを変更する。
        lv_chk_flag := cv_1;
      END IF;
--********************  2009/03/10    1.2  T.Kitajima MOD  End  ********************
--
    END LOOP check_loop;
--
    --チェックエラーがある場合、エラーとする。
    IF ( lv_chk_flag <> cv_0 ) THEN
      gn_warn_cnt := gn_target_cnt;  --スキップ件数(全件)を設定
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
  END chk_line_cnt;
--
--#####################################  固定部 END   ##########################################
--
  /**********************************************************************************
   * Procedure Name   : edit_edi_stc_data
   * Description      : データ編集(A-4,A-5,A-6)
   ***********************************************************************************/
  PROCEDURE edit_edi_stc_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_edi_stc_data'; -- プログラム名
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
    lv_invc_break         xxcos_edi_stc_headers.invoice_number%TYPE;  --伝票番号ブレーク用
    ln_line_no            NUMBER;                                     --行No用
    lv_data_record        VARCHAR2(32767);                            --編集後のデータ取得用
    ln_seq                INTEGER := 0;                               --添字
    ln_invc_case_qty_sum  NUMBER;                                     --(伝票計)ケース数
    ln_invc_indv_qty_sum  NUMBER;                                     --(伝票計)バラ数
    ln_invc_ship_qty_sum  NUMBER;                                     --(伝票計)出荷数量(合計、バラ)
--****************************** 2009/07/02 1.5 T.Tominaga ADD START ******************************
    lv_ball_ship_qty      NUMBER;                                     --出荷数量(ボール)
    lv_indv_stkout_qty    NUMBER;                                     --欠品数量(バラ)
    lv_case_stkout_qty    NUMBER;                                     --欠品数量(ケース)
    lv_ball_stkout_qty    NUMBER;                                     --欠品数量(ボール)
    lv_sum_stkout_qty     NUMBER;                                     --欠品数量(合計・バラ)
--****************************** 2009/07/02 1.5 T.Tominaga ADD END   ******************************
-- ************************ 2009/07/15 N.Maeda 1.5 N.Maeda ADD start ********************* --
    ln_invc_case_qty      NUMBER;                                     --ケース数
    ln_invc_indv_qty      NUMBER;                                     --バラ数
    ln_invc_ship_qty      NUMBER;                                     --出荷数量(合計、バラ)
    ln_invc_ball_ship_qty      NUMBER;                                --(伝票計)出荷数量(ボール)
    ln_invc_indv_stkout_qty    NUMBER;                                --(伝票計)欠品数量(バラ)
    ln_invc_case_stkout_qty    NUMBER;                                --(伝票計)欠品数量(ケース)
    ln_invc_ball_stkout_qty    NUMBER;                                --(伝票計)欠品数量(ボール)
    ln_invc_sum_stkout_qty     NUMBER;                                --(伝票計)欠品数量(合計・バラ)
-- ************************ 2009/07/15 N.Maeda 1.5 N.Maeda ADD  end  ********************* --
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    l_data_tab  xxcos_common2_pkg.g_layout_ttype;    --出力データ情報
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
    <<output_loop>>
    FOR i IN 1.. gn_target_cnt  LOOP
--
      --==============================================================
      --データ編集
      --==============================================================
      --行Noの編集、伝票系の取得、フラグ更新用の伝票番号取得
      IF ( lv_invc_break IS NULL )
        OR ( lv_invc_break <> gt_edi_stc_date(i).invoice_number )
      THEN
        --ブレーク時の設定
        lv_invc_break                   := gt_edi_stc_date(i).invoice_number;  --ブレーク変数に値を設定
        ln_line_no                      := cn_1;                               --行Noを1に戻す
        ln_seq                          := ln_seq + cn_1;                      --添字の編集
        gt_invoice_num(ln_seq)          := gt_edi_stc_date(i).invoice_number;  --更新用に伝票番号を保持
-- ************************ 2009/07/15 N.Maeda 1.5 N.Maeda MOD start ********************* --
        ln_invc_case_qty_sum            := 0;
        ln_invc_indv_qty_sum            := 0;
        ln_invc_ship_qty_sum            := 0;
        -- 配列の初期化
        g_inv_qty_sum.DELETE;
--
        --伝票計の取得
        SELECT iimb.attribute11 case_inc_num
               ,( xesl.case_qty * TO_NUMBER( NVL( iimb.attribute11, cn_1 ) ) ) + xesl.indv_qty
                                    indv_qty_sum  --(伝票計)出荷数量(合計、バラ)
        BULK COLLECT INTO g_inv_qty_sum
        FROM    xxcos_edi_stc_lines   xesl
               ,mtl_system_items_b    msi
               ,ic_item_mst_b         iimb
               ,xxcmn_item_mst_b      ximb
        WHERE  ( cd_process_date BETWEEN ximb.start_date_active AND  ximb.end_date_active )
        AND    iimb.item_id            = ximb.item_id
        AND    msi.segment1            = iimb.item_no
        AND    msi.organization_id     = gt_edi_stc_date(i).organization_id
        AND    msi.inventory_item_id   = xesl.inventory_item_id
        AND    xesl.header_id          = gt_edi_stc_date(i).header_id
        ;
     <<head_loop>>
     FOR h IN g_inv_qty_sum.FIRST..g_inv_qty_sum.LAST LOOP
       --===============
       --伝票計算出 
       --===============
       xxcos_common2_pkg.convert_quantity(
                                       cv_x                                             --IN :単位コード
                                      ,g_inv_qty_sum(h).case_inc_num                    --IN :ケース入数
                                      ,NULL                                             --IN :ボール入数
                                      ,g_inv_qty_sum(h).indv_qty_sum                    --IN :(伝票計)発注数量(合計・バラ)
                                      ,g_inv_qty_sum(h).indv_qty_sum                    --IN :(伝票計)出荷数量(合計・バラ)
                                      ,ln_invc_indv_qty                                 --OUT:(伝票計)出荷数量(バラ)
                                      ,ln_invc_case_qty                                 --OUT:(伝票計)出荷数量(ケース)
                                      ,ln_invc_ball_ship_qty                            --OUT:(伝票計)出荷数量(ボール)
                                      ,ln_invc_indv_stkout_qty                          --OUT:(伝票計)欠品数量(バラ)
                                      ,ln_invc_case_stkout_qty                          --OUT:(伝票計)欠品数量(ケース)
                                      ,ln_invc_ball_stkout_qty                          --OUT:(伝票計)欠品数量(ボール)
                                      ,ln_invc_sum_stkout_qty                           --OUT:(伝票計)欠品数量(合計・バラ)
                                      ,lv_errbuf                                        --OUT:エラー・メッセージエラー
                                      ,lv_retcode                                       --OUT:リターン・コード
                                      ,lv_errmsg                                        --ユーザー・エラー・メッセージ 
                                      );
       IF ( lv_retcode = cv_status_error ) THEN
         RAISE global_api_expt;
       END IF;
       --伝票計算出
       -- ケース数
       ln_invc_case_qty_sum := ln_invc_case_qty_sum + ln_invc_case_qty;
       -- バラ数
       ln_invc_indv_qty_sum := ln_invc_indv_qty_sum + ln_invc_indv_qty;
       -- 合計、バラ
       ln_invc_ship_qty_sum := ln_invc_ship_qty_sum + g_inv_qty_sum(h).indv_qty_sum;
--
     END LOOP head_loop;
--
--        SELECT  SUM( xesl.case_qty ) invc_case_qty_sum  --(伝票計)ケース数
--               ,SUM( xesl.indv_qty ) invc_indv_qty_sum  --(伝票計)バラ数
--               ,SUM(
--                  ( xesl.case_qty * TO_NUMBER( NVL( iimb.attribute11, cn_1 ) ) ) + xesl.indv_qty
--                )                    invc_ship_qty_sum  --(伝票計)出荷数量(合計、バラ)
--        INTO    ln_invc_case_qty_sum
--               ,ln_invc_indv_qty_sum
--               ,ln_invc_ship_qty_sum
--        FROM    xxcos_edi_stc_lines   xesl
--               ,mtl_system_items_b    msi
--               ,ic_item_mst_b         iimb
--               ,xxcmn_item_mst_b      ximb
--        WHERE  ( cd_process_date BETWEEN ximb.start_date_active AND  ximb.end_date_active )
--        AND    iimb.item_id            = ximb.item_id
--        AND    msi.segment1            = iimb.item_no
--        AND    msi.organization_id     = gt_edi_stc_date(i).organization_id
--        AND    msi.inventory_item_id   = xesl.inventory_item_id
--        AND    xesl.header_id          = gt_edi_stc_date(i).header_id
--        GROUP BY
--               xesl.header_id
--        ;
-- ************************ 2009/07/15 N.Maeda 1.5 N.Maeda MOD  end  ********************* --
      ELSE
        ln_line_no                      := ln_line_no + cn_1;                  --行Noインクリメント
      END IF;
      --共通関数用の変数に値を設定
      -- ヘッダ部 --
      l_data_tab(cv_medium_class)             := gt_edi_media_class;
      l_data_tab(cv_data_type_code)           := gt_data_type_code;
--********************  2009/07/08    1.5  N.Maeda MOD Start ********************
----********************  2009/06/15    1.5  N.Maeda MOD Start ********************
----      l_data_tab(cv_file_no)                  := TO_CHAR(NULL);
--      l_data_tab(cv_file_no)                  := TO_CHAR(gt_edi_stc_date(i).edi_forward_number);
      l_data_tab(cv_file_no)                  := gt_edi_f_number;
----********************  2009/06/15    1.5  N.Maeda MOD  End  ********************
--********************  2009/07/08    1.5  N.Maeda MOD  End  ********************
      l_data_tab(cv_info_class)               := TO_CHAR(NULL);
      l_data_tab(cv_process_date)             := gv_f_o_date;
      l_data_tab(cv_process_time)             := gv_f_o_time;
      l_data_tab(cv_base_code)                := gt_header_data.delivery_base_code;
      l_data_tab(cv_base_name)                := gt_header_data.delivery_base_name;
      l_data_tab(cv_base_name_alt)            := gt_header_data.delivery_base_phonetic;
      l_data_tab(cv_edi_chain_code)           := gt_edi_stc_date(i).edi_chain_code;
      l_data_tab(cv_edi_chain_name)           := gt_header_data.edi_chain_name;
      l_data_tab(cv_edi_chain_name_alt)       := gt_header_data.edi_chain_name_phonetic;
      l_data_tab(cv_chain_code)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_report_code)              := TO_CHAR(NULL);
      l_data_tab(cv_report_show_name)         := TO_CHAR(NULL);
      l_data_tab(cv_cust_code)                := gt_edi_stc_date(i).customer_code;
      l_data_tab(cv_cust_name)                := gt_edi_stc_date(i).customer_name;
      l_data_tab(cv_cust_name_alt)            := gt_edi_stc_date(i).customer_phonetic;
      l_data_tab(cv_comp_code)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name_alt)            := TO_CHAR(NULL);
      --移動オーダーのデータの場合
      IF ( gt_edi_stc_date(i).move_order_num IS NOT NULL ) THEN
        l_data_tab(cv_shop_code)              := TO_CHAR(NULL);
        l_data_tab(cv_shop_name)              := TO_CHAR(NULL);
        l_data_tab(cv_shop_name_alt)          := TO_CHAR(NULL);
      --画面入力の場合
      ELSE
        l_data_tab(cv_shop_code)              := gt_edi_stc_date(i).shop_code;
        l_data_tab(cv_shop_name)              := gt_edi_stc_date(i).shop_name;
        l_data_tab(cv_shop_name_alt)          := gt_edi_stc_date(i).customer_phonetic;
      END IF;
      l_data_tab(cv_delv_cent_code)           := gt_edi_stc_date(i).center_code;
      l_data_tab(cv_delv_cent_name)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_cent_name_alt)       := TO_CHAR(NULL);
      l_data_tab(cv_order_date)               := TO_CHAR(NULL);
      l_data_tab(cv_cent_delv_date)           := TO_CHAR(gt_edi_stc_date(i).schedule_arrival_date, cv_date_format);
      l_data_tab(cv_result_delv_date)         := TO_CHAR(NULL);
      l_data_tab(cv_shop_delv_date)           := TO_CHAR(NULL);
      l_data_tab(cv_dc_date_edi_data)         := TO_CHAR(NULL);
      l_data_tab(cv_dc_time_edi_data)         := TO_CHAR(NULL);
      l_data_tab(cv_invc_class)               := gt_edi_stc_date(i).invoice_class;
      l_data_tab(cv_small_classif_code)       := TO_CHAR(NULL);
      l_data_tab(cv_small_classif_name)       := TO_CHAR(NULL);
      l_data_tab(cv_middle_classif_code)      := TO_CHAR(NULL);
      l_data_tab(cv_middle_classif_name)      := TO_CHAR(NULL);
      l_data_tab(cv_big_classif_code)         := gt_edi_stc_date(i).classification_class;
      l_data_tab(cv_big_classif_name)         := TO_CHAR(NULL);
      l_data_tab(cv_op_department_code)       := gt_edi_stc_date(i).other_party_department_code;
      l_data_tab(cv_op_order_number)          := TO_CHAR(NULL);
      l_data_tab(cv_check_digit_class)        := TO_CHAR(NULL);
      l_data_tab(cv_invc_number)              := gt_edi_stc_date(i).invoice_number;
      l_data_tab(cv_check_digit)              := TO_CHAR(NULL);
      l_data_tab(cv_close_date)               := TO_CHAR(NULL);
      l_data_tab(cv_order_no_ebs)             := gt_edi_stc_date(i).move_order_num;
      l_data_tab(cv_ar_sale_class)            := gt_edi_stc_date(i).regular_ar_sale_class;
      l_data_tab(cv_delv_classe)              := TO_CHAR(NULL);
      l_data_tab(cv_opportunity_no)           := gt_edi_stc_date(i).opportunity_code;
      l_data_tab(cv_contact_to)               := gt_header_data.delivery_base_l_phonetic;
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
      l_data_tab(cv_delv_to_address)          := TO_CHAR(NULL);
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
      l_data_tab(cv_billing_due_date)         := TO_CHAR(NULL);
      l_data_tab(cv_ship_time)                := TO_CHAR(NULL);
      l_data_tab(cv_delv_schedule_time)       := TO_CHAR(NULL);
      l_data_tab(cv_order_time)               := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item1)           := TO_CHAR(gt_edi_stc_date(i).schedule_shipping_date, cv_date_format);
      l_data_tab(cv_gen_date_item2)           := TO_CHAR(gt_edi_stc_date(i).rcpt_possible_date, cv_date_format);
      l_data_tab(cv_gen_date_item3)           := TO_CHAR(gt_edi_stc_date(i).inspect_schedule_date, cv_date_format);
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
      l_data_tab(cv_cent_whse_class)          := gt_edi_stc_date(i).whse_class;
      l_data_tab(cv_cent_area_class)          := TO_CHAR(NULL);
      l_data_tab(cv_cent_arrival_class)       := TO_CHAR(NULL);
      l_data_tab(cv_depot_class)              := TO_CHAR(NULL);
      l_data_tab(cv_tcdc_class)               := TO_CHAR(NULL);
      l_data_tab(cv_upc_flag)                 := TO_CHAR(NULL);
      l_data_tab(cv_simultaneously_class)     := TO_CHAR(NULL);
      l_data_tab(cv_business_id)              := TO_CHAR(NULL);
      l_data_tab(cv_whse_directly_class)      := TO_CHAR(NULL);
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
      l_data_tab(cv_ship_class)               := TO_CHAR(NULL);
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
      l_data_tab(cv_chain_pec_area_header)    := TO_CHAR(NULL);
      l_data_tab(cv_order_connection_number)  := TO_CHAR(NULL);
      --明細部 --
      l_data_tab(cv_line_no)                  := ln_line_no;
      l_data_tab(cv_stkout_class)             := TO_CHAR(NULL);
      l_data_tab(cv_stkout_reason)            := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_itouen)         := gt_edi_stc_date(i).item_code;
      l_data_tab(cv_prod_code1)               := TO_CHAR(NULL);
      l_data_tab(cv_prod_code2)               := gt_edi_stc_date(i).customer_item_number;
      l_data_tab(cv_jan_code)                 := gt_edi_stc_date(i).jan_code;
      l_data_tab(cv_itf_code)                 := gt_edi_stc_date(i).itf_code;
      l_data_tab(cv_extension_itf_code)       := TO_CHAR(NULL);
      l_data_tab(cv_case_prod_code)           := TO_CHAR(NULL);
      l_data_tab(cv_ball_prod_code)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_item_type)      := TO_CHAR(NULL);
      l_data_tab(cv_prod_class)               := gt_edi_stc_date(i).item_div_code;
      l_data_tab(cv_prod_name)                := gt_edi_stc_date(i).item_name;
      l_data_tab(cv_prod_name1_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_name2_alt)           := gt_edi_stc_date(i).item_phonetic1;
      l_data_tab(cv_item_standard1)           := TO_CHAR(NULL);
      l_data_tab(cv_item_standard2)           := gt_edi_stc_date(i).item_phonetic2;
      l_data_tab(cv_qty_in_case)              := TO_CHAR(NULL);
      l_data_tab(cv_num_of_cases)             := gt_edi_stc_date(i).case_inc_num;
      l_data_tab(cv_num_of_ball)              := gt_edi_stc_date(i).bowl_inc_num;
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
--****************************** 2009/07/02 1.5 T.Tominaga ADD START ******************************
      xxcos_common2_pkg.convert_quantity(
                                          cv_x                                             --IN :単位コード
                                         ,gt_edi_stc_date(i).case_inc_num                  --IN :ケース入数
                                         ,NULL                                             --IN :ボール入数
                                         ,gt_edi_stc_date(i).ship_qty                      --IN :発注数量(合計・バラ)
                                         ,gt_edi_stc_date(i).ship_qty                      --IN :出荷数量(合計・バラ)
                                         ,gt_edi_stc_date(i).indv_qty                      --OUT:出荷数量(バラ)
                                         ,gt_edi_stc_date(i).case_qty                      --OUT:出荷数量(ケース)
                                         ,lv_ball_ship_qty                                 --OUT:出荷数量(ボール)
                                         ,lv_indv_stkout_qty                               --OUT:欠品数量(バラ)
                                         ,lv_case_stkout_qty                               --OUT:欠品数量(ケース)
                                         ,lv_ball_stkout_qty                               --OUT:欠品数量(ボール)
                                         ,lv_sum_stkout_qty                                --OUT:欠品数量(合計・バラ)
                                         ,lv_errbuf                                        --OUT:エラー・メッセージエラー
                                         ,lv_retcode                                       --OUT:リターン・コード
                                         ,lv_errmsg                                        --ユーザー・エラー・メッセージ 
                                        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--****************************** 2009/07/02 1.5 T.Tominaga ADD END   ******************************
      l_data_tab(cv_indv_ship_qty)            := TO_CHAR( gt_edi_stc_date(i).indv_qty );
      l_data_tab(cv_case_ship_qty)            := TO_CHAR( gt_edi_stc_date(i).case_qty );
      l_data_tab(cv_ball_ship_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_pallet_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_sum_ship_qty)             := TO_CHAR( gt_edi_stc_date(i).ship_qty );
      l_data_tab(cv_indv_stkout_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_case_stkout_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_ball_stkout_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_sum_stkout_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_case_qty)                 := TO_CHAR(NULL);
      l_data_tab(cv_fold_container_indv_qty)  := TO_CHAR(NULL);
      l_data_tab(cv_order_unit_price)         := TO_CHAR(NULL);
      l_data_tab(cv_ship_unit_price)          := TO_CHAR(NULL);
      l_data_tab(cv_order_cost_amt)           := TO_CHAR(NULL);
      l_data_tab(cv_ship_cost_amt)            := TO_CHAR(NULL);
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
      l_data_tab(cv_gen_add_item1)            := TO_CHAR( gt_tax_rate );
      l_data_tab(cv_gen_add_item2)            := SUBSTRB( gt_header_data.delivery_base_l_phonetic, 1, 10 );
      l_data_tab(cv_gen_add_item3)            := SUBSTRB( gt_header_data.delivery_base_l_phonetic, 11, 10 );
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
      l_data_tab(cv_invc_indv_ship_qty)       := TO_CHAR( ln_invc_indv_qty_sum );
      l_data_tab(cv_invc_case_ship_qty)       := TO_CHAR( ln_invc_case_qty_sum );
      l_data_tab(cv_invc_ball_ship_qty)       := TO_CHAR(NULL);
      l_data_tab(cv_invc_pallet_ship_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_ship_qty)        := TO_CHAR( ln_invc_ship_qty_sum );
      l_data_tab(cv_invc_indv_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_ball_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_stkout_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_invc_fold_container_qty)  := TO_CHAR(NULL);
      l_data_tab(cv_invc_order_cost_amt)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_ship_cost_amt)       := TO_CHAR(NULL);
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
/* 2009/04/28 Ver1.4 Add Start */
      l_data_tab(cv_attribute)                := TO_CHAR(NULL);
/* 2009/04/28 Ver1.4 Add End   */
      --==============================================================
      --データ成型(A-5)
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
                        ,iv_token_value1 => lv_errmsg           --共通関数のエラーメッセージ
                       );
        RAISE global_api_expt;
      END;
      --==============================================================
      --ファイル出力(A-6)
      --==============================================================
      --データ出力
      UTL_FILE.PUT_LINE(
        file   => gt_f_handle     --ファイルハンドル
       ,buffer => lv_data_record  --出力文字(データ)
      );
      --正常処理件数カウント
      gn_normal_cnt := gn_normal_cnt + cn_1;
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
  END edit_edi_stc_data;
--
  /**********************************************************************************
   * Procedure Name   : output_footer
   * Description      : ファイル終了処理(A-7)
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
/* 2009/04/28 Ver1.4 Start */
--    lv_footer_output  VARCHAR2(1000);  --フッタ出力用
    lv_footer_output  VARCHAR2(5000);  --フッタ出力用
/* 2009/04/28 Ver1.4 End   */
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
     ,in_num_of_records  =>  gn_target_cnt     --レコード件数
     ,ov_retcode         =>  lv_retcode        --リターンコード
     ,ov_output          =>  lv_footer_output  --フッタレコード
     ,ov_errbuf          =>  lv_errbuf         --エラーメッセージ
     ,ov_errmsg          =>  lv_errmsg         --ユーザー・エラー・メッセージ
    );
    IF (lv_retcode <> cv_status_normal) THEN
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
   * Procedure Name   : upd_edi_send_flag
   * Description      : フラグ更新(A-8)
   ***********************************************************************************/
  PROCEDURE upd_edi_send_flag(
--********************  2010/03/16    1.8  Y.Kuboshima ADD Start *******************
-- パラメータにEDIチェーン店コードを追加
    it_edi_c_code IN  xxcmm_cust_accounts.chain_store_code%TYPE,          --  EDIチェーン店コード
--********************  2010/03/16    1.8  Y.Kuboshima ADD  End  *******************
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_edi_send_flag'; -- プログラム名
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
      --移動オーダーヘッダテーブル更新
      FORALL i IN 1.. gt_invoice_num.count
--
       UPDATE mtl_txn_request_headers mtrh
       SET    mtrh.attribute1 = cv_y  --入庫予定連携済フラグ
       WHERE  mtrh.header_id IN
                ( SELECT xesh.move_order_header_id
                  FROM   xxcos_edi_stc_headers xesh
                  WHERE  xesh.move_order_header_id IS NOT NULL
                  AND    xesh.invoice_number       = gt_invoice_num(i)
--********************  2010/03/16    1.8  Y.Kuboshima ADD Start *******************
-- 抽出条件にEDIチェーン店コードを追加
                  AND    xesh.edi_chain_code       = it_edi_c_code
--********************  2010/03/16    1.8  Y.Kuboshima ADD  End  *******************
                );
    EXCEPTION
      WHEN OTHERS THEN
        --トークン取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --アプリケーション
                        ,iv_name         => cv_msg_tbale_tkn3  --移動オーダーヘッダテーブル
                       );
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  --アプリケーション
                      ,iv_name         => cv_msg_upd_err  --データ更新エラー
                      ,iv_token_name1  => cv_tkn_table_n  --トークンコード１
                      ,iv_token_value1 => lv_tkn_name     --移動オーダーヘッダテーブル
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
    BEGIN
      --入庫予定ヘッダテーブル更新
      FORALL i IN 1.. gt_invoice_num.count
--
        UPDATE  xxcos_edi_stc_headers xesh
        SET     xesh.edi_send_date           = cd_sysdate                 --EDI送信日時
               ,xesh.edi_send_flag           = cv_y                       --EDI送信済みフラグ
               ,xesh.last_updated_by         = cn_last_updated_by         --最終更新者
               ,xesh.last_update_date        = cd_last_update_date        --最終更新日
               ,xesh.last_update_login       = cn_last_update_login       --最終更新ログイン
               ,xesh.request_id              = cn_request_id              --要求ID
               ,xesh.program_application_id  = cn_program_application_id  --コンカレント・プログラム・アプリケーションID
               ,xesh.program_id              = cn_program_id              --コンカレント・プログラムID
               ,xesh.program_update_date     = cd_program_update_date     --プログラム更新日
        WHERE   xesh.invoice_number  = gt_invoice_num(i)
--********************  2010/03/16    1.8  Y.Kuboshima ADD Start *******************
-- 抽出条件にEDIチェーン店コードを追加
        AND     xesh.edi_chain_code  = it_edi_c_code
--********************  2010/03/16    1.8  Y.Kuboshima ADD  End  *******************
        ;
    EXCEPTION
      WHEN OTHERS THEN
        --トークン取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --アプリケーション
                        ,iv_name         => cv_msg_tbale_tkn4  --入庫予定ヘッダヘッダテーブル
                       );
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  --アプリケーション
                      ,iv_name         => cv_msg_upd_err  --データ更新エラー
                      ,iv_token_name1  => cv_tkn_table_n  --トークンコード１
                      ,iv_token_value1 => lv_tkn_name     --移動オーダーヘッダテーブル
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    COMMIT;  --ファイル出力、フラグの更新までを確定させる為COMMIT
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
  END upd_edi_send_flag;
--
  /**********************************************************************************
   * Procedure Name   : del_edi_stc_data
   * Description      : 入庫予定パージ(A-9)
   ***********************************************************************************/
  PROCEDURE del_edi_stc_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_edi_stc_data'; -- プログラム名
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
    ld_term_date  DATE;          --削除対象日取得用
    lv_tkn_name   VARCHAR2(50);  --トークン取得用
--
    -- *** ローカル・TABLE型***
    --入庫予定ヘッダID テーブル型
    TYPE l_edi_stc_h_id_ttype IS TABLE OF rowid INDEX BY BINARY_INTEGER;
    l_edi_stc_h_id  l_edi_stc_h_id_ttype;
    --入庫予定明細ID テーブル型
    TYPE l_edi_stc_l_id_ttype IS TABLE OF rowid INDEX BY BINARY_INTEGER;
    l_edi_stc_l_id  l_edi_stc_l_id_ttype;
--
    -- *** ローカル・カーソル ***
    --入庫予定ヘッダ
    CURSOR del_header_cur
    IS
      SELECT xesh.rowid  row_id
      FROM   xxcos_edi_stc_headers xesh
      WHERE  xesh.edi_send_flag          = cv_y          --EDI送信済みフラグ(送信済)
-- ********** 2009/08/17 N.Maeda 1.6 MOD START ************** --
      AND    xesh.edi_send_date  <= ld_term_date  --対象日以前
--      AND    TRUNC(xesh.edi_send_date)  <= ld_term_date  --対象日以前
-- ********** 2009/08/17 N.Maeda 1.6 MOD  END  ************** --
      FOR UPDATE OF
             xesh.header_id NOWAIT
      ;
    --入庫予定明細
    CURSOR del_line_cur
    IS
-- ********** 2009/08/17 N.Maeda 1.6 MOD START ************** --
      SELECT xesl.rowid row_id
      FROM   xxcos_edi_stc_lines xesl
      WHERE  EXISTS ( SELECT 'Y'
                      FROM   xxcos_edi_stc_headers xesh
                      WHERE  xesh.edi_send_flag          = cv_y          --EDI送信済みフラグ(送信済)
                      AND    xesh.edi_send_date         <= ld_term_date  --対象日以前
                      AND    xesl.header_id              = xesh.header_id
                    ) --ヘッダの削除条件
--
--      SELECT xesl.rowid row_id
--      FROM   xxcos_edi_stc_lines xesl
--      WHERE  xesl.header_id IN 
--        ( SELECT xesh.header_id  header_id
--          FROM   xxcos_edi_stc_headers xesh
--          WHERE  xesh.edi_send_flag          = cv_y          --EDI送信済みフラグ(送信済)
--          AND    TRUNC(xesh.edi_send_date)  <= ld_term_date  --対象日以前
--        ) --ヘッダの削除条件
-- ********** 2009/08/17 N.Maeda 1.6 MOD  END  ************** --
      FOR UPDATE OF
             xesl.line_id NOWAIT
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
    --削除対象日の取得
    --==============================================================
-- ********** 2009/08/17 N.Maeda 1.6 MOD START ************** --
--    ld_term_date := TRUNC( cd_sysdate ) - TO_NUMBER( gv_edi_p_term ); --システム日付-EDI情報削除期間
    ld_term_date := TO_DATE (
                      ( TO_CHAR ( TRUNC ( cd_sysdate ) - TO_NUMBER ( gv_edi_p_term ),cv_date_format )|| cv_time_data )
                      ,cv_date_time_format ); --システム日付-EDI情報削除期間
-- ********** 2009/08/17 N.Maeda 1.6 MOD  END  ************** --
--
    --==============================================================
    --ロック処理
    --==============================================================
    --入庫予定ヘッダのロック
    OPEN del_header_cur;
    FETCH del_header_cur BULK COLLECT INTO l_edi_stc_h_id;
    CLOSE del_header_cur;
    --入庫予定明細のロック
    OPEN del_line_cur;
    FETCH del_line_cur BULK COLLECT INTO l_edi_stc_l_id;
    CLOSE del_line_cur;
    --==============================================================
    --パージ処理
    --==============================================================
    BEGIN
      --入庫予定ヘッダのパージ
      FORALL i IN 1.. l_edi_stc_h_id.count
--
        DELETE FROM xxcos_edi_stc_headers xesh
        WHERE  xesh.rowid = l_edi_stc_h_id(i)
        ;
--
      --入庫予定明細のパージ
      FORALL i IN 1.. l_edi_stc_l_id.count
--
        DELETE FROM xxcos_edi_stc_lines xesl
        WHERE  xesl.rowid  = l_edi_stc_l_id(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        --トークン取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     --アプリケーション
                        ,iv_name         => cv_msg_tbale_tkn2  --入庫予定テーブル
                       );
        --メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application    --アプリケーション
                      ,iv_name         => cv_msg_purge_err  --パージエラー
                      ,iv_token_name1  => cv_tkn_table      --トークンコード１
                      ,iv_token_value1 => lv_tkn_name       --入庫予定テーブル
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    -- *** ロックエラー ***
    WHEN lock_expt THEN
      --カーソルクローズ
      IF ( del_header_cur%ISOPEN ) THEN
        CLOSE del_header_cur;
      END IF;
      IF ( del_line_cur%ISOPEN ) THEN
        CLOSE del_line_cur;
      END IF;
      --トークン取得
      lv_tkn_name := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     --アプリケーション
                      ,iv_name         => cv_msg_tbale_tkn2  --入庫予定テーブル
                     );
      --メッセージ取得
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application     --アプリケーション
                    ,iv_name         => cv_msg_lock_err    --ロックエラー
                    ,iv_token_name1  => cv_tkn_table_n     --トークンコード１
                    ,iv_token_value1 => lv_tkn_name        --入庫予定テーブル
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
  END del_edi_stc_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name      IN  VARCHAR2,     --   1.ファイル名
    iv_to_s_code      IN  VARCHAR2,     --   2.搬送先保管場所
    iv_edi_c_code     IN  VARCHAR2,     --   3.EDIチェーン店コード
    iv_edi_f_number   IN  VARCHAR2,     --   4.EDI伝送対版
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- 初期処理(A-0,A-1)
    -- ===============================
    init(
      iv_file_name     -- ファイル名
     ,iv_to_s_code     -- 搬送先保管場所
     ,iv_edi_c_code    -- EDIチェーン店コード
     ,iv_edi_f_number  -- EDI伝送追番
     ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,lv_retcode       -- リターン・コード             --# 固定 #
     ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- ファイル初期処理(A-2)
    -- ===============================
    output_header(
      iv_to_s_code     -- 搬送先保管場所
     ,iv_edi_c_code    -- EDIチェーン店コード
     ,iv_edi_f_number  -- EDI伝送追番
     ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,lv_retcode       -- リターン・コード             --# 固定 #
     ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      --ファイルがOPENされている場合クローズ
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
    -- 入庫予定情報抽出(A-3)
    -- ===============================
    get_edi_stc_data(
      iv_to_s_code     -- 搬送先保管場所
     ,iv_edi_c_code    -- EDIチェーン店コード
     ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,lv_retcode       -- リターン・コード             --# 固定 #
     ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      --ファイルがOPENされている場合クローズ
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
    --処理対象判定
    IF ( gn_target_cnt <> 0 ) THEN
      -- ===============================
      -- 明細件数チェック処理(A-12)
      -- ===============================
--********************  2009/03/10    1.2  T.Kitajima MOD Start ********************
--      chk_line_cnt(
--        lv_errbuf  -- エラー・メッセージ           --# 固定 #
--       ,lv_retcode -- リターン・コード             --# 固定 #
--       ,lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF (lv_retcode <> cv_status_normal) THEN
--        --ファイルがOPENされている場合クローズ
--        IF ( UTL_FILE.IS_OPEN(
--               file => gt_f_handle
--             )
--           )
--        THEN
--          UTL_FILE.FCLOSE(
--            file => gt_f_handle
--          );
--        END IF;
--        RAISE global_process_expt;
--      END IF;
      --顧客品目の場合
      IF ( gt_edi_item_code_div = cv_1 ) THEN
        chk_line_cnt(
          lv_errbuf  -- エラー・メッセージ           --# 固定 #
         ,lv_retcode -- リターン・コード             --# 固定 #
         ,lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          --ファイルがOPENされている場合クローズ
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
--********************  2009/03/10    1.2  T.Kitajima MOD  End  ********************
      -- ===============================
      -- データ編集(A-4)
      -- ===============================
      edit_edi_stc_data(
        lv_errbuf  -- エラー・メッセージ           --# 固定 #
       ,lv_retcode -- リターン・コード             --# 固定 #
       ,lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        --ファイルがOPENされている場合クローズ
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
    --対象なし
    ELSE
      --メッセージ取得
      lv_no_target_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     --アプリケーション
                           ,iv_name         => cv_msg_no_target   --パラメーター出力(処理対象なし)
                          );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_no_target_msg
      );
    END IF;
    -- ===============================
    -- ファイル終了処理(A-7)
    -- ===============================
    output_footer(
      lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,lv_retcode  -- リターン・コード             --# 固定 #
     ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      --ファイルがOPENされている場合クローズ
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
    --処理対象判定
    IF ( gn_target_cnt <> 0 ) THEN
      -- ===============================
      -- フラグ更新(A-8)
      -- ===============================
      upd_edi_send_flag(
--********************  2010/03/16    1.8  Y.Kuboshima MOD Start *******************
-- パラメータにEDIチェーン店コードを追加
--        lv_errbuf   -- エラー・メッセージ           --# 固定 #
        iv_edi_c_code -- EDIチェーン店コード
       ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--********************  2010/03/16    1.8  Y.Kuboshima MOD  End  *******************
       ,lv_retcode  -- リターン・コード             --# 固定 #
       ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    -- ===============================
    -- 入庫予定パージ(A-9)
    -- ===============================
    del_edi_stc_data(
      lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,lv_retcode  -- リターン・コード             --# 固定 #
     ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
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
    errbuf          OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_file_name    IN  VARCHAR2,      --   1.ファイル名
    iv_to_s_code    IN  VARCHAR2,      --   2.搬送先保管場所
    iv_edi_c_code   IN  VARCHAR2,      --   3.EDIチェーン店コード
    iv_edi_f_number IN  VARCHAR2       --   4.EDI伝送追番
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
       iv_file_name     -- ファイル名
      ,iv_to_s_code     -- 搬送先保管場所
      ,iv_edi_c_code    -- EDIチェーン店コード
      ,iv_edi_f_number  -- EDI伝送追番
      ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,lv_retcode       -- リターン・コード             --# 固定 #
      ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--********************  2010/03/16    1.8  Y.Kuboshima ADD Start *******************
    --対象件数が0件の場合かつ、終了ステータスが「正常」の場合、終了ステータスを「警告」とする
    IF ( gn_target_cnt = cn_0 )
      AND ( lv_retcode = cv_status_normal )
    THEN
      lv_retcode := cv_status_warn;
    END IF;
--********************  2010/03/16    1.8  Y.Kuboshima ADD  End  *******************
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
END XXCOS011A04C;
/
