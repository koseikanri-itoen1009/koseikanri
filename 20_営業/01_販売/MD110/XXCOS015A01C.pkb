CREATE OR REPLACE PACKAGE BODY APPS.XXCOS015A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS015A01C(body)
 * Description      : 情報系システム向け販売実績データの作成を行う
 * MD.050           : 情報系システム向け販売実績データの作成 MD050_COS_015_A01
 * Version          : 2.15
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  get_external_code           顧客に紐付く物件コード取得
 *  edit_sales_amount           売上金額の編集
 *  init                        初期処理(A-1)
 *  file_open                   ファイルオープン(A-2)
 *  get_sales_actual_data       販売実績データ抽出(A-3)
 *  output_for_seles_actual     売上実績CSV作成(A-4)
 *  get_ar_deal_info            AR取引情報データ抽出(A-5)
 *  output_for_ar_deal          売上実績CSV作成(AR取引情報)(A-6)
 *  update_sales_header_status  売上実績ヘッダステータス更新(A-7)
 *  file_colse                  ファイルクローズ(A-8)
 *  expt_proc                   例外処理(A-9)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/03    1.0   K.Atsushiba      新規作成
 *  2009/02/09    1.1   K.Atsushiba      非在庫品目の数量対応
 *                1.2   K.Atsushiba      売掛金訂正対応（AR取引）
 *                                          ・元取引情報を参照して「直販売上」、「インショップ売上」であれば対象
 *                                          ・元取引情報が参照できない場合、出荷先顧客(消化計算対象顧客)の業態小分類
 *                                            が、「インショップ」、「当社直営店」であれば対象
 *  2009/02/13    1.3   K.Atsushiba      CSVの出力先をディレクトリ・オブジェクトに変更
 *  2009/02/16    1.4   K.Atsushiba      SCS_075 対応
 *                1.5   K.Atsushiba      SCS_077 対応
 *  2009/02/17    1.6   K.Atsushiba      SCS_086 対応
 *                1.7   K.Atsushiba      get_msgのパッケージ名修正
 *                1.8   K.Atsushiba      SCS_093 対応
 *  2009/02/19    1.9   K.Atsushiba      SCS_104 対応 消化計算の黒伝連携
 *  2009/02/20    2.0   K.Atsushiba      パラメータのログファイル出力対応
 *  2009/03/25    2.1   S.Kayahara       最終行にスラッシュ追加
 *  2009/03/30    2.2   N.Maeda          【ST障害T1-0035対応対応】
 *                                       販売実績データ抽出時、下記内容データ条件の削除
 *                                       ・取引データ(取引タイプ「売掛金訂正」(元情報あり)) 
 *                                       ・取引データ(取引タイプ「売掛金訂正」(元情報なし)) 
 *                                       【ST障害T1-0187対応対応】
 *                                       ・検収予定日のフォーマットを「YYYY/MM/DD」から「YYYYMMDD」に変更する。
 *                                       ・以下の項目をダブルクォーテーションで囲む
 *                                         会社コード,伝票番号,顧客コード,商品コード,物件コード,
 *                                         Ｈ／Ｃ,売上拠点コード,成績者コード,カード売り区分,
 *                                         納品拠点コード,売上返品区分,売上区分,納品形態区分,
 *                                         コラムNo,消費税区分(税コード?),請求先顧客コード,
 *  2009/04/23    2.3   T.Kitajima       [T1_0727]1.H/CのNULL⇒[1]の変換対応
 *                                                2.売上金額、消費税金額端数処理
 *                                                3.コラムNoのNULL⇒[00]の変換
 *                                                4.納品単価変換
 *                                                5.請求先顧客コードを["]で括る(カード)。
 *                                                6.コンカレント出力の件数
 *  2009/05/21    2.4   S.Kayahara       [T1_1060]売上実績CSV作成(A-4)に参照タイプ（納品伝票区分特定マスタ）取得処理追加
 *  2009/05/29    2.5   T.Kitajima       [T1_1120]org_id追加
 *  2009/06/02    2.6   N.Maeda          [T1_1291]端数処理修正
 *  2009/06/05    2.7   S.Kayahara       [T1_1330]売上金額の編集処理(edit_sales_amount)削除
 *  2009/06/09    2.8   N.Maeda          [T1_1133]MC顧客対応
 *  2009/07/03    2.9   T.Miyata         [0000234]販売実績読み込み0件時は情報連携区分更新処理を行わない
 *  2009/09/18    2.10  N.Maeda          [0001351]PT対応
 *  2009/09/25    2.10  N.Maeda          [0001351]レビュー指摘対応
 *  2009/09/28    2.10  N.Maeda          [0001351]レビュー指摘対応
 *  2009/09/28    2.11  N.Maeda          [0001299]販売実績ヘッダ更新時エラー時出力内容修正
 *  2009/11/24    2.12  N.Maeda          [E_本番_XXXX] 販売実績対象データ取得条件「検収日」⇒「納品日」へ修正
 *  2009/12/29    2.13  K.Kiriu          [E_本番_00531]伝票番号の桁数オーバー切捨て対応
 *  2010/01/06    2.14  K.Atsushiba      [E_本稼働_00922]情報系への売上実績連携のAR情報不正対応
 *  2010/02/02    2.15  K.Atsushiba      [E_本稼動_01386]消化VDのAR(速報用)対応
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOS015A01C';       -- パッケージ名
  cv_xxcos_short_name         CONSTANT VARCHAR2(10)  := 'XXCOS';              -- アプリケーション短縮名:XXCOS
  cv_xxccp_short_name         CONSTANT VARCHAR2(10)  := 'XXCCP';              -- アプリケーション短縮名:XXCCP
  cv_xxcoi_short_name         CONSTANT VARCHAR2(10)  := 'XXCOI';              -- アプリケーション短縮名:XXCOI
  -- メッセージ
  cv_msg_non_parameter        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- 入力項目なし
  cv_msg_lock_error           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    -- ロックエラー
  cv_msg_notfound_data        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003';    -- 処理対象データなし
  cv_msg_notfound_profile     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    -- プロファイル取得エラー
  cv_msg_file_open_error      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00009';    -- ファイルオープンエラー
  cv_msg_update_error         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    -- データ更新エラー
  cv_msg_data_extra_error     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    -- データ抽出エラー
  cv_msg_non_business_date    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014';    -- 業務日付取得エラー
  cv_msg_file_name            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00044';    -- ファイル名
  cv_msg_org_id               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047';    -- 営業単位
  cv_msg_sales_header         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13302';    -- 販売実績ヘッダ
  cv_msg_sales_line           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13303';    -- 販売実績
  cv_msg_ar_deal              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13304';    -- AR取引情報
  cv_msg_mk_org_cls           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13305';    -- 作成元区分特定マスタ取得エラー
  cv_msg_card_sale_class      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13306';    -- カード売区分取得エラー
  cv_msg_hc_class             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13307';    -- H/C区分取得エラー
  cv_msg_dlv_slp_cls          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13308';    -- 納品伝票区分特定マスタ取得エラー
  cv_msg_zyoho_file_name      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13309';    -- 情報系売上実績ファイル名
  cv_msg_outbound_dir         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13310';    -- 情報系ディレクトリパス
  cv_msg_elec_fee_item_code   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13311';    -- 変動電気料品目コード
  cv_msg_company_code         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13312';    -- 会社コード
  cv_msg_mk_org_cls_name      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13313';    -- 作成元特定区分
  cv_msg_card_sales_name      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13314';    -- カード売区分
  cv_msg_hc_class_name        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13315';    -- H/C区分
  cv_msg_ar_txn_name          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13316';    -- 取引タイプ特定マスタ
  cv_msg_notfound_ar_deal     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13317';    -- AR取引データなし
  cv_msg_non_item             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13318';    -- 非在庫品目
  cv_msg_book_id              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13319';    -- 会計帳簿ID
  cv_msg_dlv_ptn_cls          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13320';    -- 納品形態区分
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD START ******************************--
  cv_msg_count                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13321';    -- 件数メッセージ
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD  END  ******************************--
-- ************** 2009/09/28 2.11 N.Maeda ADD START **************** --
  cv_msg_details              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13322';    -- メッセージ用文字列:「詳細」
-- ************** 2009/09/28 2.11 N.Maeda ADD  END  **************** --
/* 2009/12/29 Ver2.13 Add Start */
  cv_msg_ar_trx_number        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13323';    -- AR伝票番号桁数オーバーエラー
/* 2009/12/29 Ver2.13 Add End   */
-- 2010/02/02 Ver.2.15 Add Start
  cv_msg_vd_digestion_data    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13324';    -- 消化計算(消化VD)データ取得エラー
  cv_msg_ar_start_date        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13325';    -- 消化VDのAR対象開始日
-- 2010/02/02 Ver.2.15 Add End
  -- メッセージトークン
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20) := 'PROFILE';             -- プロファイル名
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';               -- テーブル名
  cv_tkn_key_data             CONSTANT VARCHAR2(20) := 'KEY_DATA';            -- キー項目
  cv_tkn_table_name           CONSTANT VARCHAR2(20) := 'TABLE_NAME';          -- テーブル名
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';           -- ファイル名
  cv_tkn_count                CONSTANT VARCHAR2(20) := 'COUNT';               -- 件数
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';         -- 参照タイプ
  cv_tkn_meaning              CONSTANT VARCHAR2(20) := 'MEANING';             -- 意味
  cv_tkn_attribute1           CONSTANT VARCHAR2(20) := 'ATTRIBUTE1';          -- 属性
  cv_tkn_attribute2           CONSTANT VARCHAR2(20) := 'ATTRIBUTE2';          -- 属性2
  cv_tkn_attribute3           CONSTANT VARCHAR2(20) := 'ATTRIBUTE3';          -- 属性3
  cv_tkn_account_name         CONSTANT VARCHAR2(20) := 'ACCOUNT_NAME';        -- 顧客名
  cv_tkn_account_id           CONSTANT VARCHAR2(20) := 'ACCOUNT_ID';          -- 顧客ID
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD START ******************************--
  cv_tkn_count_1              CONSTANT VARCHAR2(20) := 'COUNT1';              -- 件数1
  cv_tkn_count_2              CONSTANT VARCHAR2(20) := 'COUNT2';              -- 件数2
  cv_tkn_count_3              CONSTANT VARCHAR2(20) := 'COUNT3';              -- 件数3
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD  END  ******************************--
/* 2009/12/29 Ver2.13 Add Start */
  cv_tkn_base_code            CONSTANT VARCHAR2(20) := 'BASE_CODE';           -- 売上拠点
  cv_tkn_account_number       CONSTANT VARCHAR2(20) := 'ACCOUNT_NUMBER';      -- 顧客コード
  cv_tkn_gl_date              CONSTANT VARCHAR2(20) := 'GL_DATE';             -- GL記帳日
  cv_tkn_ar_trx_number        CONSTANT VARCHAR2(20) := 'TRX_NUMBER';          -- AR伝票番号
/* 2009/12/29 Ver2.13 Add End   */
-- 2010/02/02 Ver.2.15 Add Start
  cv_tkn_delivery_date        CONSTANT VARCHAR2(20) := 'DELIVERY_DATE';
  cv_tkn_sales_header_id      CONSTANT VARCHAR2(20) := 'SALES_HEADER_ID';
-- 2010/02/02 Ver.2.15 Add End
  -- プロファイル
  cv_pf_output_directory      CONSTANT VARCHAR2(50) := 'XXCOS1_OUTBOUND_ZYOHO_DIR';        -- ディレクトリパス
  cv_pf_company_code          CONSTANT VARCHAR2(50) := 'XXCOI1_COMPANY_CODE';              -- 会社コード
  cv_pf_csv_file_name         CONSTANT VARCHAR2(50) := 'XXCOS1_ZYOHO_FILE_NAME';           -- 売上実績ファイル名
  cv_pf_org_id                CONSTANT VARCHAR2(50) := 'ORG_ID';                           -- MO:営業単位
  cv_pf_var_elec_item_cd      CONSTANT VARCHAR2(50) := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';    -- 変動電気品目コード
  cv_pro_bks_id               CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';                 -- 会計帳簿ID
  cv_pf_sls_calc_dlv_ptn_cls  CONSTANT VARCHAR2(40) := 'XXCOS1_PROD_SLS_CALC_DLV_PTN_CLS'; -- 納品形態区分
-- 2010/02/02 Ver.2.15 Add Start
  cv_pf_vd_ar_start_date      CONSTANT VARCHAR2(40) := 'XXCOS1_VD_AR_START_DATE';          -- 消化VDのAR対象開始日
-- 2010/02/02 Ver.2.15 Add End
  -- 参照タイプ
  cv_ref_t_mk_org_cls_mst     CONSTANT VARCHAR2(50) := 'XXCOS1_MK_ORG_CLS_MST_015_A01';   -- 作成元特定区分マスタ
  cv_ref_t_dlv_slp_cls_mst    CONSTANT VARCHAR2(50) := 'XXCOS1_DLV_SLP_CLS_MST_015_A01';  -- 納品伝票区分特定マスタ
  cv_ref_t_card_sale_class    CONSTANT VARCHAR2(50) := 'XXCOS1_CARD_SALE_CLASS';          -- カード売区分
  cv_ref_t_hc_class           CONSTANT VARCHAR2(50) := 'XXCOS1_HC_CLASS';                 -- H/C区分
  cv_ref_t_txn_type_mst       CONSTANT VARCHAR2(50) := 'XXCOS1_AR_TXN_TYPE_MST_015_A01';  -- 取引タイプ特定マスタ
  cv_non_inv_item_mst_t       CONSTANT VARCHAR2(50) := 'XXCOS1_NO_INV_ITEM_CODE';         -- 非在庫品目
  cv_gyotai_sho_mst_t         CONSTANT VARCHAR2(50) := 'XXCOS1_GYOTAI_SHO_MST_004_A01';   -- 業態区分
  cv_gyotai_sho_mst_c         CONSTANT VARCHAR2(50) := 'XXCOS_004_A01%';                  -- 業態区分
  cv_txn_type_01              CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_01';                -- 直販売上
--  cv_txn_type_02              CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_02';                -- ｲﾝｼｮｯﾌﾟ売上
--  cv_txn_type_03              CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_03';                -- 売掛金訂正*/
-- 2010/02/02 Ver.2.15 Mod Start
  cv_txn_sales_type           CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_0%';                 -- 取引タイプ
--  cv_txn_sales_type           CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_%';                 -- 取引タイプ
-- 2010/02/02 Ver.2.15 Mod End
  -- 日付フォーマット
/* 2009/12/29 Ver2.13 Mod Start */
  cv_date_format              CONSTANT VARCHAR2(20) := 'YYYY/MM/DD';
/* 2009/12/29 Ver2.13 Mod Start */
  cv_date_format_non_sep      CONSTANT VARCHAR2(20) := 'YYYYMMDD';
  cv_datetime_format          CONSTANT VARCHAR2(20) := 'YYYYMMDDHH24MISS';
  -- 切捨て時間要素
  cv_trunc_fmt                CONSTANT VARCHAR2(2) := 'MM';
  -- 有効無効フラグ
  cv_enabled_flag             CONSTANT VARCHAR2(1) := 'Y';             -- 有効
  -- NULL時の代替値
  cv_def_article_code         CONSTANT VARCHAR2(10) := '0000000000';   -- 物件コード
  cv_def_results_employee_cd  CONSTANT VARCHAR2(10) := '00000';        -- 成績者コード
  cv_def_card_sale_class      CONSTANT VARCHAR2(1)  := '0';            -- カード売上区分
  cv_def_column_no            CONSTANT VARCHAR2(2)  := '00';           -- コラムNo
  cv_def_delivery_base_code   CONSTANT VARCHAR2(4)  := '0000';         -- 納品拠点コード
  cn_non_sales_quantity       CONSTANT NUMBER  := 0;                   -- 売上数量
  cn_non_std_unit_price       CONSTANT NUMBER  := 0;                   -- 納品単価
  cn_non_cash_and_card        CONSTANT NUMBER  := 0;                   -- 現金・カード併用額
  -- 明細タイプ
  cv_line_type_line           CONSTANT VARCHAR2(5) := 'LINE';          -- 明細
  cv_line_type_tax            CONSTANT VARCHAR2(5) := 'TAX';           -- 税金
  -- 勘定区分
  cv_account_class_profit     CONSTANT VARCHAR2(3) := 'REV';           -- 収益
  -- 文字
  cv_blank                    CONSTANT VARCHAR2(1)  := '';             -- ブランク
  cv_flag_no                  CONSTANT VARCHAR2(1)  := 'N';            -- フラグ:No
  cv_delimiter                CONSTANT VARCHAR2(1)  := ',';            -- デリミタ
  cv_val_y                    CONSTANT VARCHAR2(1)  := 'Y';            -- 値：Y
  cv_d_cot                    CONSTANT VARCHAR2(1)  := '"';            -- ダブルクォーテーション
  -- 使用目的
  cv_site_ship_to             CONSTANT VARCHAR2(10) := 'SHIP_TO';      -- 出荷先
  cv_site_bill_to             CONSTANT VARCHAR2(10) := 'BILL_TO';      -- 請求先
--****************************** 2009/04/23 2.3 1 T.Kitajima ADD START ******************************--
  -- H/C
  cv_h_c_cold                 CONSTANT VARCHAR2(1) := '1';             -- COLD
  cv_h_c_hot                  CONSTANT VARCHAR2(1) := '3';             -- HOT
--****************************** 2009/04/23 2.3 1 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/23 2.3 4 T.Kitajima ADD START ******************************--
  cn_sub_1                    CONSTANT NUMBER      := 1;               -- 
  cv_zero                     CONSTANT VARCHAR2(1) := '0';             -- 
--****************************** 2009/04/23 2.3 4 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/08 2.8 N.Maeda ADD START ******************************--
  cv_cust_type_mc             CONSTANT VARCHAR2(2)     := '20';
  cv_cust_type_sp             CONSTANT VARCHAR2(2)     := '25';
  cv_relate_stat_a            CONSTANT VARCHAR2(1)     := 'A';
  cv_relate_attri_req         CONSTANT VARCHAR2(1)     := '1';
--****************************** 2009/06/08 2.8 N.Maeda ADD  END  ******************************--
/* 2009/12/29 Ver2.13 Add Start */
  cn_trx_num_length           CONSTANT NUMBER(2)       := 12;   --AR取引番号桁数
  cn_1                        CONSTANT NUMBER(1)       := 1;    --数値:1(汎用)
/* 2009/12/29 Ver2.13 Add End   */
-- 2010/02/02 Ver.2.15 Add Start
  cv_txn_type_02              CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_02';                -- 消化VD
  cv_lang                     CONSTANT VARCHAR2(5)  := USERENV('LANG');                   -- 言語
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';                     -- 参照コード
  cv_txn_vd_digestion_type    CONSTANT VARCHAR2(50) := 'XXCOS_015_A01_1%';                 -- 取引タイプ(消化VD)
-- 2010/02/02 Ver.2.15 Add Start
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_system_date        DATE;                                                     -- システム日付
  gd_business_date      DATE;                                                     -- 業務日付
  gt_output_directory   fnd_profile_option_values.profile_option_value%TYPE;      -- ディレクトリパス
  gt_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;      -- 売上実績ファイル名
  gt_org_id             fnd_profile_option_values.profile_option_value%TYPE;      -- MO:営業単位
  gt_company_code       fnd_profile_option_values.profile_option_value%TYPE;      -- 会社コード
  gt_var_elec_amount    fnd_profile_option_values.profile_option_value%TYPE;      -- 変動電気量
  gt_book_id            fnd_profile_option_values.profile_option_value%TYPE;      -- 会計帳簿ID
  gt_dlv_ptn_cls        fnd_profile_option_values.profile_option_value%TYPE;      -- 納品形態区分
  gt_mk_org_cls         fnd_lookup_values.meaning%TYPE;                           -- 作成元特定区分
  gt_file_handle        UTL_FILE.FILE_TYPE;                                       -- ファイルハンドル
  gn_sales_h_count      NUMBER DEFAULT 0;                                         -- 内部TBL用カウンタ(売上実績)
  gt_card_sale_class    fnd_lookup_values.lookup_code%TYPE;                       -- カード売区分
  gt_hc_class           fnd_lookup_values.meaning%TYPE;                           -- H/C区分
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD START ******************************--
  gn_card_count         NUMBER;                                                   -- カード分カウント
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD  END  ******************************--
/* 2009/12/29 Ver2.13 Add Start */
  gn_ar_trx_num_warn   NUMBER(1) DEFAULT 0;                                      -- AR伝票番号エラー警告保持
/* 2009/12/29 Ver2.13 Add End   */
-- 2010/02/02 Ver.2.15 Add Start
  gt_mk_org_cls_vd       fnd_lookup_values.meaning%TYPE;                           -- 作成元特定区分(消化計算)
  gt_ar_start_date       fnd_profile_option_values.profile_option_value%TYPE;      -- 納品形態区分
  gd_ar_start_date       DATE;
-- 2010/02/02 Ver.2.15 Add End
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- 販売実績データ抽出
  CURSOR get_sales_actual_cur
  IS
-- **************** 2009/09/18 2.10 N.Maeda MOD START **************** --
-- **************** 2009/09/28 2.10 N.Maeda MOD START **************** --
    SELECT /*+
           LEADING(xseh)
           USE_NL(xseh xsel)
           USE_NL(xseh hca xchv)
           INDEX(xseh xxcos_sales_exp_headers_n04)
           */
-- **************** 2009/09/28 2.10 N.Maeda MOD  END  **************** --
            xseh.inspect_date                   xseh_inspect_date              -- 検収日
--    SELECT  xseh.inspect_date                   xseh_inspect_date              -- 検収日
-- **************** 2009/09/18 2.10 N.Maeda MOD  END **************** --
           ,xseh.dlv_invoice_number             xseh_dlv_invoice_number        -- 納品伝票番号
           ,xsel.dlv_invoice_line_number        xsel_dlv_invoice_line_number   -- 納品明細番号
           ,xseh.ship_to_customer_code          xseh_ship_to_customer_code     -- 顧客【納品先】
           ,xsel.item_code                      xsel_item_code                 -- 品目コード
           ,xsel.hot_cold_class                 xsel_hot_cold_class            -- Ｈ/Ｃ
           ,xseh.sales_base_code                xseh_sales_base_code           -- 売上拠点コード
           ,xseh.results_employee_code          xseh_results_employee_code     -- 成績計上者コード
           ,NVL(xseh.card_sale_class
                ,cv_def_card_sale_class)        xseh_card_sale_class           -- カード売り区分
           ,xsel.delivery_base_code             xsel_delivery_base_code        -- 納品拠点コード
           ,xsel.pure_amount                    xsel_pure_amount               -- 本体金額
           ,xsel.standard_qty                   xsel_standard_qty              -- 基準数量
           ,xsel.tax_amount                     xsel_tax_amount                -- 消費税金額
           ,xseh.dlv_invoice_class              xseh_dlv_invoice_class         -- 納品伝票区分
           ,xsel.sales_class                    xsel_sales_class               -- 売上区分
           ,xsel.delivery_pattern_class         xsel_delivery_pattern_class    -- 納品形態
           ,xsel.column_no                      xsel_column_no                 -- コラムNO
           ,xseh.delivery_date                  xseh_delivery_date             -- 納品日
           ,xsel.standard_unit_price            xsel_standard_unit_price       -- 税抜基準単価
           ,xsel.standard_uom_code              xsel_standard_uom_code         -- 基準単位
           ,xseh.tax_rate                       xseh_tax_rate                  -- 消費税率
           ,xseh.tax_code                       xseh_tax_code                  -- 税コード
--****************************** 2009/04/23 2.3 4 T.Kitajima MOD START ******************************--
--           ,xsel.standard_unit_price_excluded   xsel_std_unit_price_excluded   -- 税抜基準単価
           ,DECODE(
                       SUBSTR(   TO_CHAR( xsel.standard_unit_price_excluded )
                              , cn_sub_1
                              , cn_sub_1
                             )
                      ,cv_msg_cont
                      ,cv_zero || TO_CHAR( xsel.standard_unit_price_excluded )
                      ,TO_CHAR( xsel.standard_unit_price_excluded )
                   )                            xsel_std_unit_price_excluded   -- 税抜基準単価
--****************************** 2009/04/23 2.3 4 T.Kitajima MOD  END  ******************************--
           ,xchv.bill_account_number            xchv_bill_account_number       -- 請求先顧客コード
           ,xchv.cash_account_number            xchv_cash_account_number       -- 入金先顧客コード
           ,NVL(xsel.cash_and_card,
                cn_non_cash_and_card)           xsel_cash_and_card             -- 現金・カード併用額
           ,xchv.bill_tax_round_rule            xchv_bill_tax_round_rule       -- 税金－端数処理
           ,xseh.create_class                   xseh_create_class              -- 作成元区分
           ,xchv.ship_account_id                xchv_ship_account_id           -- 出荷先顧客ID
           ,hca.cust_account_id                 hca_cust_account_id            -- 顧客アカウントID
           ,xchv.ship_account_name              xchv_ship_account_name         -- 出荷先顧客名
           ,xseh.rowid                          xseh_rowid
-- 2010/02/02 Ver.2.15 Add Start
           ,xseh.sales_exp_header_id            sales_exp_header_id            -- 販売実績ヘッダID
-- 2010/02/02 Ver.2.15 Add End
    FROM    xxcos_sales_exp_headers             xseh                           -- 販売実績ヘッダ
           ,xxcos_sales_exp_lines               xsel                           -- 販売実績明細
           ,xxcos_cust_hierarchy_v              xchv                           -- 顧客階層ビュー
           ,hz_cust_accounts                    hca                            -- 顧客アカウントマスタ
    WHERE  xseh.sales_exp_header_id     = xsel.sales_exp_header_id             -- ヘッダID
    AND    xseh.dlv_invoice_number      = xsel.dlv_invoice_number              -- 納品伝票番号
    AND    xseh.dwh_interface_flag      = cv_flag_no                           -- インタフェースフラグ
-- ************* 2009/11/24 2.12 N.Maeda MOD START ************* --
--    AND    xseh.inspect_date           <= gd_business_date                     -- 納品日
    AND    xseh.delivery_date          <= gd_business_date                     -- 納品日
-- ************* 2009/11/24 2.12 N.Maeda MOD  END  ************* --
    AND    xsel.item_code              <> gt_var_elec_amount                   -- 品目コード
    AND    xchv.ship_account_number     = xseh.ship_to_customer_code           -- 出荷先顧客コード
    AND    xchv.ship_account_id         = hca.cust_account_id                  -- 出荷先顧客ID
    AND    hca.account_number           = xseh.ship_to_customer_code           -- 顧客コード
--****************************** 2009/06/08 2.8 N.Maeda MOD START ******************************--
    UNION ALL
-- **************** 2009/09/18 2.10 N.Maeda MOD START **************** --
-- **************** 2009/09/25 2.10 N.Maeda MOD START **************** --
-- **************** 2009/09/28 2.10 N.Maeda MOD START **************** --
    SELECT /*+
           LEADING(xseh)
           USE_NL(xseh xsel)
           USE_NL(xseh hca hpt)
           USE_NL(hca_r)
           USE_NL(bill_hcasa)
           USE_NL(bill_hcsua)
           USE_NL(bill_hcara)
           INDEX(xseh xxcos_sales_exp_headers_n04)
           */
-- **************** 2009/09/28 2.10 N.Maeda MOD  END  **************** --
-- **************** 2009/09/25 2.10 N.Maeda MOD  END  **************** --
            xseh.inspect_date                   xseh_inspect_date              -- 検収日
--    SELECT xseh.inspect_date                   xseh_inspect_date              -- 検収日
-- **************** 2009/09/18 2.10 N.Maeda MOD  END **************** --
           ,xseh.dlv_invoice_number             xseh_dlv_invoice_number        -- 納品伝票番号
           ,xsel.dlv_invoice_line_number        xsel_dlv_invoice_line_number   -- 納品明細番号
           ,xseh.ship_to_customer_code          xseh_ship_to_customer_code     -- 顧客【納品先】
           ,xsel.item_code                      xsel_item_code                 -- 品目コード
           ,xsel.hot_cold_class                 xsel_hot_cold_class            -- Ｈ/Ｃ
           ,xseh.sales_base_code                xseh_sales_base_code           -- 売上拠点コード
           ,xseh.results_employee_code          xseh_results_employee_code     -- 成績計上者コード
           ,NVL(xseh.card_sale_class
                ,cv_def_card_sale_class)        xseh_card_sale_class           -- カード売り区分
           ,xsel.delivery_base_code             xsel_delivery_base_code        -- 納品拠点コード
           ,xsel.pure_amount                    xsel_pure_amount               -- 本体金額
           ,xsel.standard_qty                   xsel_standard_qty              -- 基準数量
           ,xsel.tax_amount                     xsel_tax_amount                -- 消費税金額
           ,xseh.dlv_invoice_class              xseh_dlv_invoice_class         -- 納品伝票区分
           ,xsel.sales_class                    xsel_sales_class               -- 売上区分
           ,xsel.delivery_pattern_class         xsel_delivery_pattern_class    -- 納品形態
           ,xsel.column_no                      xsel_column_no                 -- コラムNO
           ,xseh.delivery_date                  xseh_delivery_date             -- 納品日
           ,xsel.standard_unit_price            xsel_standard_unit_price       -- 税抜基準単価
           ,xsel.standard_uom_code              xsel_standard_uom_code         -- 基準単位
           ,NULL                                xseh_tax_rate                  -- 消費税率
           ,xseh.tax_code                       xseh_tax_code                  -- 税コード
           ,NULL                                xsel_std_unit_price_excluded   -- 税抜基準単価
           ,NVL(hca_r.account_number,
                xseh.ship_to_customer_code)     xchv_bill_account_number       -- 請求先顧客コード
--                uses_hca.account_number)         xchv_bill_account_number       -- 請求先顧客コード
           ,NULL                                xchv_cash_account_number       -- 入金先顧客コード
           ,NVL(xsel.cash_and_card,
                cn_non_cash_and_card)           xsel_cash_and_card             -- 現金・カード併用額
           ,NULL                                xchv_bill_tax_round_rule       -- 税金－端数処理
           ,NULL                                xseh_create_class              -- 作成元区分
           ,NULL                                xchv_ship_account_id           -- 出荷先顧客ID
           ,hca.cust_account_id                 hca_cust_account_id            -- 顧客アカウントID
           ,NULL                                xchv_ship_account_name         -- 出荷先顧客名
           ,xseh.rowid                          xseh_rowid
-- 2010/02/02 Ver.2.15 Add Start
           ,xseh.sales_exp_header_id            sales_exp_header_id            -- 販売実績ヘッダID
-- 2010/02/02 Ver.2.15 Add End
    FROM    xxcos_sales_exp_headers             xseh                           -- 販売実績ヘッダ
           ,xxcos_sales_exp_lines               xsel                           -- 販売実績明細
           ,hz_cust_accounts                    hca                            -- 顧客アカウントマスタ
           ,hz_parties                          hpt                               -- パーティーマスタ
           ,hz_cust_accounts                    hca_r                             -- 顧客マスタ顧客関連用
           ,hz_cust_acct_sites_all              bill_hcasa                        -- 請求先顧客所在地（請求先）
           ,hz_cust_site_uses_all               bill_hcsua                        -- 請求先顧客使用目的
           ,hz_cust_acct_relate_all             bill_hcara                        -- 顧客関連マスタ(請求関連)
--           ,hz_cust_acct_sites_all              uses_hcasa                        -- 使用目的所在地
--           ,hz_cust_accounts                    uses_hca                          -- 使用目的顧客
    WHERE  xseh.sales_exp_header_id     = xsel.sales_exp_header_id             -- ヘッダID
    AND    xseh.dlv_invoice_number      = xsel.dlv_invoice_number              -- 納品伝票番号
    AND    xseh.dwh_interface_flag      = cv_flag_no                           -- インタフェースフラグ
-- ************* 2009/11/24 2.12 N.Maeda MOD START ************* --
--    AND    xseh.inspect_date           <= gd_business_date                     -- 納品日
    AND    xseh.delivery_date           <= gd_business_date                     -- 納品日
-- ************* 2009/11/24 2.12 N.Maeda MOD  END  ************* --
    AND    xsel.item_code              <> gt_var_elec_amount                   -- 品目コード
    AND    hca.account_number           = xseh.ship_to_customer_code           -- 顧客コード
    AND    hca.party_id                 =  hpt.party_id
    AND    hpt.duns_number_c           IN ( cv_cust_type_mc , cv_cust_type_sp )  -- MC顧客,SP決済済み
    AND    hca.cust_account_id         = bill_hcasa.cust_account_id(+)
    AND    bill_hcasa.cust_acct_site_id = bill_hcsua.cust_acct_site_id(+)
    AND    bill_hcsua.site_use_code(+)     = cv_site_bill_to
    AND    bill_hcasa.org_id(+)            = gt_org_id
    AND    bill_hcsua.org_id(+)            = gt_org_id
    AND    hca.cust_account_id          = bill_hcara.related_cust_account_id(+) 
    AND    bill_hcara.status(+)            = cv_relate_stat_a 
    AND    bill_hcara.attribute1(+)        = cv_relate_attri_req
    AND    bill_hcara.org_id(+)            = gt_org_id
    AND    bill_hcara.cust_account_id   = hca_r.cust_account_id(+)
    AND    hca.account_number     = xseh.ship_to_customer_code     -- 出荷先顧客コード
--    AND    uses_hcasa.cust_acct_site_id(+) = bill_hcsua.cust_acct_site_id
--    AND    uses_hca.cust_account_id(+)    = uses_hcasa.cust_account_id
-- **************** 2009/09/25 2.10 N.Maeda MOD START **************** --
    AND    NOT EXISTS( SELECT
                       /*+ USE_NL(xchv)
                         INDEX(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u2)
                         INDEX(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u2)
                         INDEX(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u2)
                         INDEX(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u2)
                       */
                       'Y'
--    AND    NOT EXISTS( SELECT  'Y'
-- **************** 2009/09/25 2.10 N.Maeda MOD  END  **************** --
                       FROM    xxcos_cust_hierarchy_v  xchv
                       WHERE   xchv.ship_account_number   = xseh.ship_to_customer_code)
    ORDER BY  xseh_dlv_invoice_number                                          -- 納品伝票番号
             ,xsel_dlv_invoice_line_number;
--    ORDER BY  xseh.dlv_invoice_number                                          -- 納品伝票番号
--             ,xsel.dlv_invoice_line_number;
--    FOR UPDATE OF  xseh.sales_exp_header_id
--                  ,xsel.sales_exp_line_id
--    NOWAIT;
--****************************** 2009/06/08 2.8 N.Maeda MOD  END  ******************************--
    --
    -- AR取引データ抽出
    CURSOR get_ar_deal_info_cur(
-- 2010/02/02 Ver.2.15 Mod Start
       id_gl_date_from      DATE           -- GL記帳日(開始)
      ,id_gl_date_to        DATE           -- GL記帳日(終了)
      ,iv_lookup_code       VARCHAR2       -- 参照コード
--       id_delivery_date     DATE           -- 納品日
-- 2010/02/02 Ver.2.15 Mod End
      ,in_ship_account_id   NUMBER)        -- 出荷先顧客ID
    IS
      SELECT  cust.trx_date                 rcta_trx_date                -- 取引日
             ,cust.trx_number               rcta_trx_number              -- 取引番号
             ,cust.puroduct_code            puroduct_code                -- 商品コード
             ,cust.line_number              rctla_line_number            -- 取引明細番号
             ,line.delivery_base_code       delivery_base_code           -- セグメント2(拠点コード)
             ,line.revenue_amount           rctla_revenue_amount         -- 収益金額
             ,tax.extended_amount           rctla_t_revenue_amount       -- 収益金額
             ,cust.cust_trx_type_id         deal_cust_trx_type_id        -- 取引タイプ
             ,cust.tax_code                 avtab_tax_code               -- 税金コード
             ,cust.customer_id              rcta_bill_to_customer_id     -- 請求先顧客ID
             ,line.gl_date                  rctlgda_gl_date              -- GL記帳日
/* 2009/12/29 Ver2.13 Add Start */
             ,cust.ship_account_number      ship_account_number          -- 出荷先顧客
/* 2009/12/29 Ver2.13 Add End   */
      FROM
      -- 税金データ
      (  SELECT rctla.customer_trx_id                customer_trx_id
                ,rctla.link_to_cust_trx_line_id      link_to_cust_trx_line_id
                ,SUM(rctla.extended_amount)          extended_amount               -- 収益金額
         FROM   ra_customer_trx_lines_all     rctla                       -- AR取引情報明細
         WHERE  rctla.line_type             = cv_line_type_tax             -- 明細タイプ
         GROUP BY rctla.customer_trx_id
                  ,rctla.link_to_cust_trx_line_id
      ) tax,
      -- 明細データ
      (
         SELECT rctlgda.gl_date                gl_date                      -- GL記帳日
                ,gcc.segment2                  delivery_base_code           -- セグメント2(拠点コード)
                ,rctla.revenue_amount          revenue_amount               -- 収益金額
                ,rctla.customer_trx_id         customer_trx_id              -- 取引ID
                ,rctla.customer_trx_line_id    customer_trx_line_id          -- 取引明細ID
         FROM   ra_cust_trx_line_gl_dist_all   rctlgda                      -- AR取引配分(会計情報)
                ,ra_customer_trx_lines_all     rctla                        -- AR取引情報明細
                ,gl_code_combinations          gcc                          -- AFF組合せマスタ
                ,gl_sets_of_books              gsob                         -- GL会計帳簿
         WHERE rctla.customer_trx_id         = rctlgda.customer_trx_id       -- 取引データID
         AND    rctlgda.account_class        = cv_account_class_profit       -- 勘定区分
         AND    rctlgda.code_combination_id  = gcc.code_combination_id       -- CCID
         AND    rctlgda.set_of_books_id      = TO_NUMBER(gt_book_id)
         AND    rctla.line_type              = cv_line_type_line             -- 明細タイプ
         AND    gcc.chart_of_accounts_id     = gsob.chart_of_accounts_id     -- アカウントID
         AND    rctlgda.customer_trx_line_id = rctla.customer_trx_line_id
-- 2010/02/02 Ver.2.15 Mod Start
         AND    rctlgda.gl_date       BETWEEN  id_gl_date_from
                                      AND      id_gl_date_to                 -- GL記帳日
--         AND    rctlgda.gl_date       BETWEEN  TRUNC(id_delivery_date,cv_trunc_fmt)
--                                      AND      LAST_DAY(id_delivery_date)   -- GL記帳日
-- 2010/02/02 Ver.2.15 Mod End
      ) line,
      (
         -- 取引データ(取引タイプ「請求書」)
         SELECT rcta.trx_date                  trx_date                -- 取引日
                ,rcta.trx_number               trx_number              -- 取引番号
                ,rctta.attribute3              puroduct_code           -- 商品コード
                ,rctla.line_number             line_number             -- 取引明細番号
                ,rcta.cust_trx_type_id         cust_trx_type_id        -- 取引タイプ
                ,avtab.tax_code                tax_code                 -- 税金コード
                ,rcta.bill_to_customer_id      customer_id             -- 請求先顧客ID
                ,rctla.customer_trx_id         customer_trx_id              -- 取引ID
                ,rctla.customer_trx_line_id    customer_trx_line_id         -- 取引明細ID
/* 2009/12/29 Ver2.13 Add Start */
                ,hca.account_number            ship_account_number     --出荷先顧客
/* 2009/12/29 Ver2.13 Add End   */
         FROM    ra_customer_trx_all           rcta                         -- AR取引情報ヘッダ
                ,ra_customer_trx_lines_all     rctla                        -- AR取引情報明細
                ,ar_vat_tax_all_b              avtab                        -- 税金マスタ
                ,ra_cust_trx_types_all         rctta                        -- 取引タイプ
                ,fnd_lookup_values             flv                          -- 参照タイプ
                ,hz_cust_accounts              hca                            -- 顧客アカウントマスタ
                ,hz_cust_acct_sites_all        hcasa                          -- 顧客所在地（請求先）
                ,hz_cust_site_uses_all         hcsua                        -- 顧客使用目的
                ,ra_cust_trx_line_gl_dist_all   rctlgda                     -- AR取引配分(会計情報)
-- 2010/02/02 Ver.2.15 Add Start
                ,xxcfr_sales_data_reletes      xsdr                         -- 売上実績連携済テーブル
-- 2010/02/02 Ver.2.15 Add End
         WHERE  rcta.org_id                 = gt_org_id                     -- 営業単位ID
         AND    rcta.customer_trx_id        = rctla.customer_trx_id         -- 取引データID
-- 2010/02/02 Ver.2.15 Add Start
         AND    rcta.customer_trx_id        = xsdr.customer_trx_id          -- 取引データID
-- 2010/02/02 Ver.2.15 Add End
         AND    rctla.vat_tax_id            = avtab.vat_tax_id(+)           -- 税金ID
         AND    avtab.set_of_books_id       = TO_NUMBER(gt_book_id)         -- 会計帳簿ID
         AND    rctta.cust_trx_type_id      = rcta.cust_trx_type_id         -- 取引タイプID
         AND    rctta.org_id                = gt_org_id                     -- 営業単位
         AND    rctta.name                  = flv.meaning                   -- 名前
         AND    flv.lookup_type             = cv_ref_t_txn_type_mst         -- タイプ
         /*AND    flv.lookup_code             IN  (cv_txn_type_01
                                                ,cv_txn_type_02)            -- コード*/
-- 2010/02/02 Ver.2.15 Mod Start
         AND    flv.lookup_code             LIKE ( iv_lookup_code )         -- コード
--         AND    flv.lookup_code             LIKE ( cv_txn_sales_type )      -- コード
-- 2010/02/02 Ver.2.15 Mod End
         AND    flv.attribute1              = cv_val_y                      -- 属性1
         AND    flv.language                = USERENV('LANG')               -- 言語
         AND    rcta.cust_trx_type_id       = rctta.cust_trx_type_id        -- 取引タイプID
         AND    hca.cust_account_id         = in_ship_account_id
         AND    hca.cust_account_id         = hcasa.cust_account_id
         AND    hcasa.cust_acct_site_id     = hcsua.cust_acct_site_id
--****************************** 2009/05/29 2.5 T.Kitajima ADD START ******************************
         AND    hcasa.org_id                = gt_org_id
--****************************** 2009/05/29 2.5 T.Kitajima ADD  END  ******************************
         AND    hcsua.site_use_id           = rcta.ship_to_site_use_id
         AND    hcsua.site_use_code         = cv_site_ship_to
         AND    rctla.customer_trx_id       = rctlgda.customer_trx_id       -- 取引データID
         AND    rctla.customer_trx_line_id  = rctlgda.customer_trx_line_id
         AND    rctlgda.set_of_books_id     = TO_NUMBER(gt_book_id)
         AND    rcta.complete_flag          = cv_val_y
-- 2010/02/02 Ver.2.15 Mod Start
         AND    rctlgda.gl_date       BETWEEN  id_gl_date_from
                                      AND      id_gl_date_to                 -- GL記帳日
--         AND    rctlgda.gl_date       BETWEEN  TRUNC(id_delivery_date,cv_trunc_fmt)
--                                      AND      LAST_DAY(id_delivery_date)   -- GL記帳日
-- 2010/02/02 Ver.2.15 Mod End
         /*UNION ALL 
         -- 取引データ(取引タイプ「売掛金訂正」(元情報あり))
         SELECT  rcta.trx_date                 trx_date                     -- 取引日
                ,rcta.trx_number               trx_number                   -- 取引番号
                ,rctta.attribute3              puroduct_code                -- 商品コード
                ,rctla.line_number             line_number                  -- 取引明細番号
                ,rcta.cust_trx_type_id         cust_trx_type_id             -- 取引タイプ
                ,avtab.tax_code                tax_code                     -- 税金コード
                ,rcta.bill_to_customer_id      customer_id                  -- 請求先顧客ID
                ,rctla.customer_trx_id         customer_trx_id              -- 取引ID
                ,rctla.customer_trx_line_id    customer_trx_line_id         -- 取引明細ID
         FROM    ra_customer_trx_all           rcta                         -- AR取引情報ヘッダ
                ,ra_customer_trx_lines_all     rctla                        -- AR取引情報明細
                ,ar_vat_tax_all_b              avtab                        -- 税金マスタ
                ,ra_cust_trx_types_all         rctta                        -- 取引タイプ
                ,fnd_lookup_values             flv                          -- 参照タイプ
                ,fnd_lookup_values             flv_src                      -- 参照タイプ
                ,ra_customer_trx_all           rcta_src                     --請求取引情報テーブル(元)
                ,ra_cust_trx_types_all         rctta_src                    --請求取引タイプマスタ(元)
                ,hz_cust_accounts              hca                          -- 顧客アカウントマスタ
                ,hz_cust_acct_sites_all        hcasa                        -- 顧客所在地（請求先）
                ,hz_cust_site_uses_all         hcsua                        -- 顧客使用目的
                ,ra_cust_trx_line_gl_dist_all   rctlgda                     -- AR取引配分(会計情報)
         WHERE  rcta.org_id                    = gt_org_id                  -- 営業単位ID
         AND    rcta_src.org_id                = gt_org_id                  -- 営業単位ID
         AND    rcta.customer_trx_id           = rctla.customer_trx_id      -- 取引データID
         AND    rctla.vat_tax_id               = avtab.vat_tax_id(+)        -- 税金ID
         AND    avtab.set_of_books_id          = TO_NUMBER(gt_book_id)      -- 会計帳簿ID
         AND    rctta.cust_trx_type_id         = rcta.cust_trx_type_id      -- 取引タイプID
         AND    rctta.org_id                   = gt_org_id                  -- 営業単位
         AND    rctta_src.name                 = flv_src.meaning            -- 名前
         AND    flv.lookup_type                = cv_ref_t_txn_type_mst      -- タイプ
         AND    flv.lookup_code                = cv_txn_type_03
         AND    flv.attribute1                 = cv_val_y                         -- 属性1
         AND    flv.language                   = USERENV('LANG')                  -- 言語
         AND    flv_src.lookup_type                = cv_ref_t_txn_type_mst        -- タイプ
         AND    flv_src.lookup_code             IN  (cv_txn_type_01
                                                ,cv_txn_type_02)                  -- コード
--         AND    flv.lookup_code             LIKE ( cv_txn_sales_type )            -- コード
         AND    flv_src.attribute1                 = cv_val_y                     -- 属性1
         AND    flv_src.language                   = USERENV('LANG')              -- 言語
         AND    rcta.previous_customer_trx_id  = rcta_src.customer_trx_id         -- 取引ID
         AND    rcta_src.cust_trx_type_id      = rctta_src.cust_trx_type_id       -- 取引タイプID
         AND    hca.cust_account_id            = in_ship_account_id
         AND    hca.cust_account_id            = hcasa.cust_account_id
         AND    hcasa.cust_acct_site_id        = hcsua.cust_acct_site_id
         AND    hcsua.site_use_id              = rcta.ship_to_site_use_id
         AND    hcsua.site_use_code            = cv_site_ship_to
         AND    rctla.customer_trx_id          = rctlgda.customer_trx_id       -- 取引データID
         AND    rctla.customer_trx_line_id     = rctlgda.customer_trx_line_id
         AND    rctlgda.set_of_books_id        = TO_NUMBER(gt_book_id)
         AND    rcta.complete_flag             = cv_val_y
         AND    rcta_src.complete_flag         = cv_val_y
         AND    rctlgda.gl_date       BETWEEN  TRUNC(id_delivery_date,cv_trunc_fmt)
                                      AND      LAST_DAY(id_delivery_date)   -- GL記帳日
         UNION ALL
         -- 取引データ(取引タイプ「売掛金訂正」(元情報なし))
         SELECT rcta.trx_date                  trx_date                     -- 取引日
                ,rcta.trx_number               trx_number                   -- 取引番号
                ,rctta.attribute3              puroduct_code                -- 商品コード
                ,rctla.line_number             line_number                  -- 取引明細番号
                ,rcta.cust_trx_type_id         cust_trx_type_id             -- 取引タイプ
                ,avtab.tax_code                tax_code                     -- 税金コード
                ,rcta.ship_to_customer_id      customer_id                  -- 請求先顧客ID
                ,rctla.customer_trx_id         customer_trx_id              -- 取引ID
                ,rctla.customer_trx_line_id    customer_trx_line_id         -- 取引明細ID
         FROM    ra_customer_trx_all           rcta                            -- AR取引情報ヘッダ
                ,ra_customer_trx_lines_all     rctla                           -- AR取引情報明細
                ,ar_vat_tax_all_b              avtab                           -- 税金マスタ
                ,ra_cust_trx_types_all         rctta                           -- 取引タイプ
                ,fnd_lookup_values             flv_gyotai                      -- 参照タイプ
                ,fnd_lookup_values             flv_trx                         -- 参照タイプ
                ,hz_cust_accounts              hca                             -- 顧客アカウントマスタ
                ,hz_cust_acct_sites_all        hcasa                           -- 顧客所在地（請求先）
                ,hz_cust_site_uses_all         hcsua                           -- 顧客使用目的
                ,xxcmm_cust_accounts           xca
                ,ra_cust_trx_line_gl_dist_all   rctlgda                        -- AR取引配分(会計情報)
         WHERE  rcta.org_id                    = gt_org_id                          -- 営業単位ID
         AND    rcta.customer_trx_id           = rctla.customer_trx_id              -- 取引データID
         AND    rctla.vat_tax_id               = avtab.vat_tax_id(+)           -- 税金ID
         AND    avtab.set_of_books_id          = TO_NUMBER(gt_book_id)         -- 会計帳簿ID
         AND    rctta.cust_trx_type_id         = rcta.cust_trx_type_id              -- 取引タイプID
         AND    rctta.org_id                   = gt_org_id                          -- 営業単位
         AND    xca.customer_id                = hca.cust_account_id
         AND    xca.business_low_type          = flv_gyotai.meaning
         AND    flv_gyotai.lookup_type         = cv_gyotai_sho_mst_t
         AND    flv_gyotai.lookup_code         like cv_gyotai_sho_mst_c             -- コード
         AND    flv_gyotai.language            = USERENV('LANG')                    -- 言語 
         AND    rctta.name                     = flv_trx.meaning                    -- 内容
         AND    flv_trx.lookup_type            = cv_ref_t_txn_type_mst              -- タイプ
         AND    flv_trx.lookup_code            = cv_txn_type_03                     -- 業務形態
         AND    flv_trx.language               = USERENV('LANG')                    -- 言語 
         AND    rcta.previous_customer_trx_id  IS NULL                              -- 元取引ID
         AND    rcta.cust_trx_type_id          = rctta.cust_trx_type_id             -- 取引タイプID
         AND    hca.cust_account_id            = in_ship_account_id
         AND    hca.cust_account_id            = hcasa.cust_account_id
         AND    hcasa.cust_acct_site_id        = hcsua.cust_acct_site_id
         AND    hcsua.site_use_id              = rcta.ship_to_site_use_id
         AND    hcsua.site_use_code            = cv_site_ship_to
         AND    rctla.customer_trx_id          = rctlgda.customer_trx_id       -- 取引データID
         AND    rctla.customer_trx_line_id     = rctlgda.customer_trx_line_id
         AND    rctlgda.set_of_books_id        = TO_NUMBER(gt_book_id)
         AND    rcta.complete_flag             = cv_val_y
         AND    rctlgda.gl_date       BETWEEN  TRUNC(id_delivery_date,cv_trunc_fmt)
                                      AND      LAST_DAY(id_delivery_date)   -- GL記帳日*/
      ) cust 
      WHERE  cust.customer_trx_id      = tax.customer_trx_id(+)
      AND    cust.customer_trx_line_id = tax.link_to_cust_trx_line_id(+)
      AND    cust.customer_trx_id      = line.customer_trx_id
      AND    cust.customer_trx_line_id = line.customer_trx_line_id 
      ORDER BY  cust.customer_trx_id                                           -- 取引情報データID
               ,cust.customer_trx_line_id;                                     -- 取引明細ID
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  -- 販売実績ヘッダのROWID
  TYPE g_sales_h_ttype IS TABLE OF ROWID  INDEX BY BINARY_INTEGER;
  g_sales_h_tbl     g_sales_h_ttype;
  --
  -- 出力済み顧客情報
  TYPE g_ar_output_settled_ttype IS TABLE OF NUMBER INDEX BY VARCHAR2(30);
  g_ar_output_settled_tbl    g_ar_output_settled_ttype;
--
  -- 非在庫品目用レコード変数
  TYPE g_non_item_rtype IS RECORD(
     amount        NUMBER DEFAULT 0           -- 数量
  );
  -- 非在庫品目用テーブル
  TYPE g_non_item_ttype IS TABLE OF g_non_item_rtype INDEX BY VARCHAR2(50);
  -- 非在庫品目変数定義
  gt_non_item_tbl                   g_non_item_ttype;
  --
  -- AR情報テーブル
  TYPE g_ar_deal_ttype IS TABLE OF get_ar_deal_info_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  -- AR情報変数定義
  gt_ar_deal_tbl               g_ar_deal_ttype;
-- 2010/02/02 Ver.2.15 Add Start
  -- 出力済み消化VD情報
  TYPE g_ar_output_vd_ttype IS TABLE OF NUMBER INDEX BY VARCHAR2(30);
  g_ar_output_vd_tbl         g_ar_output_vd_ttype;
  g_vd_digestion_err_tbl     g_ar_output_vd_ttype;
-- 2010/02/02 Ver.2.15 Add Start
--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
  g_sales_actual_rec    get_sales_actual_cur%ROWTYPE;
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- レコードロックエラー
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
--
/************************************************************************
 * Function Name   : get_external_code
 * Description     : 顧客に紐付く物件コード取得
 ************************************************************************/
  FUNCTION get_external_code
  ( in_cust_account_id      IN NUMBER     -- 顧客コード
  )
  RETURN VARCHAR2                         -- 物件コード
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_external_code';       -- プログラム名
--
    -- *** ローカル変数 ***
    lt_external_code       csi_item_instances.external_reference%TYPE;

  BEGIN
    --==================================
    -- 物件コード取得
    --==================================
    SELECT csi.external_reference                                    -- 物件コード
    INTO   lt_external_code
    FROM   csi_item_instances         csi                            -- 物件マスタ
    WHERE  csi.owner_party_account_id  =in_cust_account_id          -- アカウントID
    AND    rownum                      = 1
    ORDER BY csi.external_reference ASC;                               -- 物件コード
--
    RETURN lt_external_code;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN cv_def_article_code;
  END;
--
--****************************** 2009/06/05 2.7 S.Kayahara MOD START ******************************--
--/************************************************************************
-- * Function Name   : edit_sales_amount
-- * Description     : 売上金額の編集(整数の場合、少数点以下を切り捨てる)
-- ************************************************************************/
--  FUNCTION edit_sales_amount
--  ( in_amount      IN NUMBER           -- 売上金額
--  )
--  RETURN VARCHAR2                      -- 売上金額
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name    CONSTANT VARCHAR2(100) := 'edit_sales_amount'; -- プログラム名
--
--    -- *** ローカル変数 ***
--    ln_amount          NUMBER;    -- 売上金額
--  BEGIN
--
--    ln_amount := in_amount - ROUND(in_amount);
--
--    -- 少数点判定
--    IF ( ln_amount = 0 ) THEN
--      -- 少数点がない場合
----****************************** 2009/04/23 2.3 2 T.Kitajima MOD START ******************************--
----      RETURN TO_CHAR(ROUND(in_amount));
--      RETURN TO_CHAR( in_amount );
----****************************** 2009/04/23 2.3 2 T.Kitajima MOD  END  ******************************--
--    ELSE
--      -- 少数点がある場合
----****************************** 2009/04/23 2.3 2 T.Kitajima MOD START ******************************--
----      RETURN TO_CHAR(in_amount);
--      RETURN TO_CHAR( ROUND( in_amount ) );
----****************************** 2009/04/23 2.3 2 T.Kitajima MOD  END  ******************************--
--    END IF;
--
--  EXCEPTION
--    WHEN OTHERS THEN
--      RETURN TO_CHAR(in_amount);
--  END;
--
--****************************** 2009/06/05 2.7 S.Kayahara MOD End ******************************--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_profile_name              VARCHAR2(50);   -- プロファイル名
    lv_directory_path            VARCHAR2(100);  -- ディレクトリ・パス
--
    -- *** ローカル・カーソル ***
    -- 非在庫品目取得
    CURSOR non_item_cur
    IS
      SELECT flv.lookup_code    lookup_code
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_non_inv_item_mst_t
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    --
    non_item_rec         non_item_cur%ROWTYPE;
    --
    -- *** ローカル例外 ***
    non_business_date_expt       EXCEPTION;     -- 業務日付取得エラー
    non_item_extra_expt          EXCEPTION;     -- 非在庫品目抽出エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 入力項目なしのメッセージ作成
    --==================================
    gv_out_msg :=  xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_msg_non_parameter);
    --
    --==================================
    -- コンカレント・メッセージ出力
    --==================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    --
    --==================================
    -- コンカレント・ログ出力
    --==================================
    -- 空行出力 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => cv_blank
    ); 
-- 
    -- メッセージログ 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => gv_out_msg
    ); 
-- 
    -- 空行出力 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => cv_blank
    ); 
--
    --==================================
    -- システム日付取得
    --==================================
    gd_system_date := SYSDATE;
--
    --==================================
    -- 業務日付取得
    --==================================
    gd_business_date :=  xxccp_common_pkg2.get_process_date;
--
    IF ( gd_business_date IS NULL ) THEN
      -- 業務日付が取得できない場合
      RAISE non_business_date_expt;
    END IF;
--
    --==================================
    -- ディレクトリパス取得
    --==================================
    gt_output_directory := FND_PROFILE.VALUE(
                             name => cv_pf_output_directory);
--
    IF ( gt_output_directory IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_outbound_dir             -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_notfound_profile     -- メッセージ
                    ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
                    ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 売上実績ファイル名取得
    --==================================
    gt_csv_file_name := FND_PROFILE.VALUE(
                             name => cv_pf_csv_file_name);
--
    IF ( gt_csv_file_name IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_zyoho_file_name          -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_notfound_profile     -- メッセージ
                    ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
                    ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- MO:営業単位取得
    --==================================
    gt_org_id := FND_PROFILE.VALUE(
                             name => cv_pf_org_id);
--
    IF ( gt_org_id IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_org_id                   -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_notfound_profile     -- メッセージ
                    ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
                    ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 会社コード取得
    --==================================
    gt_company_code := FND_PROFILE.VALUE(
                             name => cv_pf_company_code);
--
    IF ( gt_company_code IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_company_code             -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_notfound_profile     -- メッセージ
                    ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
                    ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 変動電気量(品目コード)取得
    --==================================
    gt_var_elec_amount := FND_PROFILE.VALUE(
                             name => cv_pf_var_elec_item_cd);
--
    IF ( gt_var_elec_amount IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_elec_fee_item_code       -- メッセージID
      );
      -- プロファイルが取得できない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_notfound_profile     -- メッセージ
                    ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
                    ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 会計帳簿ID取得
    --==================================
    gt_book_id := FND_PROFILE.VALUE(
                             name => cv_pro_bks_id);
--
    IF ( gt_book_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_book_id                  -- メッセージID
      );
      -- プロファイルが取得できない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_notfound_profile     -- メッセージ
                    ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
                    ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --==================================
    -- 納品形態区分取得
    --==================================
    gt_dlv_ptn_cls := FND_PROFILE.VALUE(
                             name => cv_pf_sls_calc_dlv_ptn_cls);
--
    IF ( gt_dlv_ptn_cls IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_dlv_ptn_cls              -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_notfound_profile     -- メッセージ
                    ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
                    ,iv_token_value1 => lv_profile_name);        -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ファイル名出力
    --==================================
    SELECT ad.directory_path
    INTO   lv_directory_path
    FROM   all_directories  ad
    WHERE  ad.directory_name = gt_output_directory;
    --
    gv_out_msg :=  xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_file_name
                    ,iv_token_name1  => cv_tkn_file_name                -- トークン1名
                    ,iv_token_value1 => lv_directory_path 
                                        || '/' 
                                        || gt_csv_file_name);           -- トークン1値
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    --
    --==================================
    -- クイック・コード取得(非在庫品目)
    --==================================
    BEGIN
      OPEN non_item_cur;
    EXCEPTION
      WHEN OTHERS THEN
        -- データ抽出エラー
        RAISE non_item_extra_expt;
    END;
    --
    <<non_item_loop>>
    LOOP
      FETCH non_item_cur INTO non_item_rec;
      EXIT WHEN non_item_cur%NOTFOUND;
      --
      gt_non_item_tbl(non_item_rec.lookup_code).amount := 0;
    END LOOP non_item_loop;
    --
    -- 取得件数チェック
    IF ( non_item_cur%ROWCOUNT = 0 ) THEN
      RAISE non_item_extra_expt;
    END IF;
    --
    CLOSE non_item_cur;
--
-- 2010/02/02 Ver.2.15 Add Start
    --==================================
    -- AR対象開始日(消化VD)
    --==================================
    gt_ar_start_date := FND_PROFILE.VALUE(
                             name => cv_pf_vd_ar_start_date);
--
    IF ( gt_ar_start_date IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_ar_start_date            -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_notfound_profile     -- メッセージ
                    ,iv_token_name1  => cv_tkn_pro_tok              -- トークン1名
                    ,iv_token_value1 => lv_profile_name);        -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_ar_start_date := TO_DATE(gt_ar_start_date,cv_date_format);
    END IF;
-- 2010/02/02 Ver.2.15 Add End
--
  EXCEPTION
    --*** 業務日付取得エラー ***
    WHEN non_business_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                    ,iv_name         => cv_msg_non_business_date    -- メッセージ
      );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --*** 非在庫品目取得エラー ***
    WHEN non_item_extra_expt THEN
      IF ( non_item_cur%ISOPEN ) THEN
        CLOSE non_item_cur;
      END IF;
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_short_name
                   ,iv_name         => cv_msg_non_item
      );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( non_item_cur%ISOPEN ) THEN
        CLOSE non_item_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( non_item_cur%ISOPEN ) THEN
        CLOSE non_item_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( non_item_cur%ISOPEN ) THEN
        CLOSE non_item_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : file_open
   * Description      : ファイルオープン(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    ov_errbuf      OUT NOCOPY VARCHAR2,             --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,             --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- プログラム名
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
    cv_file_mode_overwrite      CONSTANT VARCHAR2(1) := 'W';     -- 上書
--
    -- *** ローカル例外 ***
    file_open_expt              EXCEPTION;      -- ファイルオープンエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- ファイルオープン
    --==================================
    BEGIN
      gt_file_handle := UTL_FILE.FOPEN(
                          location  => gt_output_directory           -- ディレクトリ
                         ,filename  => gt_csv_file_name              -- ファイル名
                         ,open_mode => cv_file_mode_overwrite);      -- ファイルモード
    EXCEPTION
      WHEN OTHERS THEN
        RAISE file_open_expt;
    END;
    --
    --==================================
    -- ファイル番号のチェック
    --==================================
    IF ( UTL_FILE.IS_OPEN(gt_file_handle) = FALSE ) THEN
      RAISE file_open_expt;
    END IF;
--
  EXCEPTION
    --*** ファイルオープンエラー ***
    WHEN file_open_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_file_open_error      -- メッセージ
                     ,iv_token_name1  => cv_tkn_file_name            -- トークン1名
                     ,iv_token_value1 => gt_csv_file_name);          -- トークン1値
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_actual_data
   * Description      : 実績データ抽出(A-3)
   ***********************************************************************************/
  PROCEDURE get_sales_actual_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_actual_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_table_name      VARCHAR2(50);
    lv_type_name       VARCHAR2(50);
--
    -- *** ローカル・レコード ***
    lt_ar_deal_rec     get_ar_deal_info_cur%ROWTYPE;
--
    -- *** ローカル例外 ***
    sales_actual_extra_expt       EXCEPTION;    -- 売上明細データ抽出エラー
    non_lookup_value_expt         EXCEPTION;    -- LOOKUP取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --=========================================
    -- 参照タイプ（作成元区分特定マスタ）取得
    --=========================================
    BEGIN
      SELECT flv.meaning         flv_meaning
      INTO   gt_mk_org_cls
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_ref_t_mk_org_cls_mst
      AND    flv.lookup_code   = cv_txn_type_01
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    flv.attribute1    = cv_val_y
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_mk_org_cls_name          -- メッセージID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_mk_org_cls
                     ,iv_token_name1  => cv_tkn_lookup_type
-- 2010/02/02 Ver.2.15 Mod Start
                     ,iv_token_value1 => cv_ref_t_mk_org_cls_mst
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => cv_txn_type_01);
--                     ,iv_token_value1 => lv_type_name
--                     ,iv_token_name2  => cv_tkn_attribute1
--                     ,iv_token_value2 => cv_val_y);
-- 2010/02/02 Ver.2.15 Mod Start
      RAISE non_lookup_value_expt;  
    END;
--
    --=========================================
    -- 参照タイプ（カード売区分）取得
    --=========================================
    BEGIN
      SELECT flv.lookup_code         flv_lookup_code
      INTO   gt_card_sale_class
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_ref_t_card_sale_class
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    flv.attribute3    = cv_val_y
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_card_sales_name          -- メッセージID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_card_sale_class
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => lv_type_name
                     ,iv_token_name2  => cv_tkn_attribute3
                     ,iv_token_value2 => cv_val_y);
        RAISE non_lookup_value_expt;
    END;
--
    --=========================================
    -- 参照タイプ（H/C区分）取得
    --=========================================
    BEGIN
      SELECT flv.lookup_code         flv_lookup_code
      INTO   gt_hc_class
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_ref_t_hc_class
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    flv.attribute2    = cv_val_y
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_hc_class_name            -- メッセージID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_hc_class
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => lv_type_name
                     ,iv_token_name2  => cv_tkn_attribute2
                     ,iv_token_value2 => cv_val_y);
      RAISE non_lookup_value_expt;
    END;
--
-- 2010/02/02 Ver.2.15 Add Start
    --=========================================
    -- 消化計算（消化VD）の作成元区分取得
    --=========================================
    BEGIN
      SELECT flv.meaning         flv_meaning
      INTO   gt_mk_org_cls_vd
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_ref_t_mk_org_cls_mst
      AND    flv.lookup_code   = cv_txn_type_02
      AND    flv.language      = cv_lang
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_mk_org_cls_name          -- メッセージID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_mk_org_cls
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_ref_t_mk_org_cls_mst
                     ,iv_token_name2  => cv_tkn_lookup_code
                     ,iv_token_value2 => cv_txn_type_02);
      RAISE non_lookup_value_expt;  
    END;
-- 2010/02/02 Ver.2.15 Add End
--
    --==================================
    -- 売上明細データ取得
    --==================================
    BEGIN
      OPEN get_sales_actual_cur;
    EXCEPTION
--****************************** 2009/06/08 2.8 N.Maeda DEL START ******************************--
--      -- ロックエラー
--      WHEN record_lock_expt THEN
--        RAISE record_lock_expt;
--****************************** 2009/06/08 2.8 N.Maeda DEL  END  ******************************--
      -- データ抽出エラー
      WHEN OTHERS THEN
        RAISE sales_actual_extra_expt;
    END;
--
  EXCEPTION
--****************************** 2009/06/08 2.8 N.Maeda DEL START ******************************--
--    --*** ロックエラー ***
--    WHEN record_lock_expt THEN
-- --     IF ( get_sales_actual_cur%ISOPEN ) THEN
-- --       CLOSE get_sales_actual_cur;
-- --     END IF;
--      lv_table_name := xxccp_common_pkg.get_msg(
--          iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
--         ,iv_name        => cv_msg_sales_line               -- メッセージID
--      );
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcos_short_name
--                     ,iv_name         => cv_msg_lock_error
--                     ,iv_token_name1  => cv_tkn_table
--                     ,iv_token_value1 => lv_table_name);
--      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
--      ov_retcode := cv_status_error;
--****************************** 2009/06/08 2.8 N.Maeda DEL  END  ******************************--
    --
    --*** 売上明細データ抽出エラー ***
    WHEN sales_actual_extra_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      lv_table_name := xxccp_common_pkg.get_msg(
          iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
         ,iv_name        => cv_msg_sales_line               -- メッセージID
      );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_data_extra_error
                     ,iv_token_name1  => cv_tkn_table_name
                     ,iv_token_value1 => lv_table_name
                     ,iv_token_name2  => cv_tkn_key_data
                     ,iv_token_value2 => cv_blank);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    --*** LOOKUPエラー ***
    WHEN non_lookup_value_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sales_actual_data;
--
  /**********************************************************************************
   * Procedure Name   : output_for_seles_actual
   * Description      : 売上実績CSV作成(A-4)
   ***********************************************************************************/
  PROCEDURE output_for_seles_actual(
    it_sales_actual  IN  get_sales_actual_cur%ROWTYPE,  -- 売上実績
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_for_seles_actual'; -- プログラム名
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
    ln_sales_quantity_card   CONSTANT NUMBER := 0;                 -- カード：売上数量
    cn_output_flag_off       CONSTANT NUMBER := 1;                 -- オフ：出力しない
    cn_output_flag_on        CONSTANT NUMBER := 0;                 -- オン：出力する
    cv_round_rule_up         CONSTANT VARCHAR2(10) := 'UP';        -- 切り上げ
    cv_round_rule_down       CONSTANT VARCHAR2(10) := 'DOWN';      -- 切り下げ
    cv_round_rule_nearest    CONSTANT VARCHAR2(10) := 'NEAREST';   -- 四捨五入
--
    -- *** ローカル変数 ***
    ln_sales_amount_cash    NUMBER;                     -- 現金：売上金額
    ln_tax_cash             NUMBER;                     -- 現金：売上数量
    ln_sales_quantity_cash  NUMBER;                     -- 現金：売上数量
    ln_sales_amount_card    NUMBER;                     -- カード：売上金額
    ln_tax_card             NUMBER;                     -- カード：売上数量
    ln_card_rec_flag        NUMBER DEFAULT 0;           -- カードレコード出力フラグ(デフォルトはオフ)
    lv_buffer               VARCHAR2(2000);             -- 出力データ
--****************************** 2009/05/21 2.4 S.Kayahara MOD  START  ******************************--
    lt_dlv_invoice_class    fnd_lookup_values.attribute1%TYPE;   -- 納品伝票区分
    lv_type_name            VARCHAR2(50);
    -- *** ローカル例外 ***
    non_lookup_value_expt   EXCEPTION;
--****************************** 2009/05/21 2.4 S.Kayahara MOD  END  ******************************--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--****************************** 2009/06/02 Var2.6  N.Maeda MOD START ******************************--
    IF ( ( it_sales_actual.xseh_card_sale_class = gt_card_sale_class )
        AND ( it_sales_actual.xsel_cash_and_card <> 0 ) )
    THEN
--    IF ( ( it_sales_actual.xseh_card_sale_class = gt_card_sale_class )
--        AND ( it_sales_actual.xsel_cash_and_card > 0 ) )
--    THEN
--****************************** 2009/06/02 Var2.6  N.Maeda MOD  END  ******************************--
--****************************** 2009/04/23 2.3 2 T.Kitajima MOD START ******************************--
--      -- *** 併用の場合  ***
--      -- ===============================
--      -- 売上金額の編集
--      -- ===============================
--      -- カードレコードの計算
--      ln_sales_amount_card := it_sales_actual.xsel_cash_and_card / (1 + (it_sales_actual.xseh_tax_rate / 100));
----
--      -- 端数処理
--      IF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_up ) THEN
--        -- 切り上げの場合
--        ln_sales_amount_card := CEIL(ln_sales_amount_card);
----
--      ELSIF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_down ) THEN
--        -- 切り下げの場合
--        ln_sales_amount_card := FLOOR(ln_sales_amount_card);
----
--      ELSIF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_nearest ) THEN
--        -- 四捨五入の場合
--        ln_sales_amount_card := ROUND(ln_sales_amount_card);
--      END IF;
----
--      -- 現金レコードの計算
--      ln_sales_amount_cash := it_sales_actual.xsel_pure_amount - ln_sales_amount_card;
--
--      -- ===============================
--      -- 売上数量の編集
--      -- ===============================
--      -- 現金レコードの計算
--      ln_sales_quantity_cash := it_sales_actual.xsel_standard_qty;
----
--      -- ===============================
--      -- 消費税額の編集
--      -- ===============================
--      -- カードレコードの計算
--      ln_tax_card := it_sales_actual.xsel_cash_and_card - ln_sales_amount_card;
----
--      -- 現金レコードの計算
--      ln_tax_cash := it_sales_actual.xsel_tax_amount - ln_tax_card;
----
--
      -- *** 併用の場合  ***
      -- ===============================
      -- 売上金額の編集
      -- ===============================
      --カード消費税計算(現金・カード併用額*消費税率)
      ln_tax_card             := it_sales_actual.xsel_cash_and_card * (it_sales_actual.xseh_tax_rate / 100);
      --消費税額の端数処理
--****************************** 2009/06/02 Var2.6  N.Maeda MOD START ******************************--
      IF ( TRUNC(ln_tax_card) <> ln_tax_card ) THEN
        IF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_up ) THEN
          -- 切り上げの場合
--          ln_tax_card           := CEIL(ln_tax_card);
          IF ( SIGN( ln_tax_card ) <> -1 ) THEN
            ln_tax_card           := TRUNC(ln_tax_card) + 1;
          ELSE
            ln_tax_card           := TRUNC(ln_tax_card) - 1;
          END IF;
--
        ELSIF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_down ) THEN
          -- 切り下げの場合
--          ln_tax_card           := FLOOR(ln_tax_card);
          ln_tax_card           := TRUNC(ln_tax_card);
--
        ELSIF ( it_sales_actual.xchv_bill_tax_round_rule = cv_round_rule_nearest ) THEN
          -- 四捨五入の場合
          ln_tax_card           := ROUND(ln_tax_card);
        END IF;
      END IF;
--****************************** 2009/06/02 Var2.6  N.Maeda MOD  END  ******************************--
      --カード売上金額計算(現金・カード併用額-端数処理のカード消費税)
      ln_sales_amount_card    := it_sales_actual.xsel_cash_and_card - ln_tax_card;
      --現金売上金額計算(本体金額-カード売上金額)
      ln_sales_amount_cash    := it_sales_actual.xsel_pure_amount   - ln_sales_amount_card;
      --現金消費税額計算(消費税-端数処理のカード消費税)
      ln_tax_cash             := it_sales_actual.xsel_tax_amount    - ln_tax_card;
      --売上数量
      ln_sales_quantity_cash  := it_sales_actual.xsel_standard_qty;
--****************************** 2009/04/23 2.3 2 T.Kitajima MOD  END  ******************************--
      -- カードレコードをCSVに出力
      ln_card_rec_flag := cn_output_flag_on;
    ELSE
      -- *** 併用でない場合  ***
      -- 現金レコード用変数に設定
      ln_sales_amount_cash   := it_sales_actual.xsel_pure_amount;                -- 売上金額
      ln_sales_quantity_cash := NVL(it_sales_actual.xsel_standard_qty,0);        -- 売上数量
      ln_tax_cash            := it_sales_actual.xsel_tax_amount;                 -- 消費税
--
      -- カードレコードをCSVに出力しない
      ln_card_rec_flag := cn_output_flag_off;
    END IF;
    --
    -- 非在庫品目の場合、数量をゼロに設定
    IF ( gt_non_item_tbl.EXISTS(it_sales_actual.xsel_item_code) ) THEN
      -- 非在庫品目の場合
      ln_sales_quantity_cash := cn_non_sales_quantity;        -- 売上数量
    END IF;
--
--****************************** 2009/05/21 2.4 S.Kayahara MOD  START  ******************************--
    --=========================================
    -- 参照タイプ（納品伝票区分特定マスタ）取得
    --=========================================
    BEGIN
      SELECT flv.attribute1     flv_attribute1
      INTO   lt_dlv_invoice_class
      FROM   fnd_lookup_values  flv
      WHERE  flv.meaning       = it_sales_actual.xseh_dlv_invoice_class
      AND    flv.lookup_type   = cv_ref_t_dlv_slp_cls_mst
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_ar_txn_name              -- メッセージID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name
                       ,iv_name         => cv_msg_dlv_slp_cls
                       ,iv_token_name1  => cv_tkn_lookup_type
                       ,iv_token_value1 => lv_type_name
                       ,iv_token_name2  => cv_tkn_meaning
                       ,iv_token_value2 => it_sales_actual.xseh_dlv_invoice_class);
        RAISE non_lookup_value_expt;
    END;
--
    IF ( lt_dlv_invoice_class IS NULL ) THEN
      lv_type_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_ar_txn_name              -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_dlv_slp_cls
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => lv_type_name
                     ,iv_token_name2  => cv_tkn_meaning
                     ,iv_token_value2 => it_sales_actual.xseh_dlv_invoice_class);
      RAISE non_lookup_value_expt;
    END IF;
--****************************** 2009/05/21 2.4 S.Kayahara MOD  END  ******************************--
    -- ===============================
    -- CSVファイル出力
    -- ===============================
    -- 併用（現金レコード）、併用以外データの出力
    lv_buffer :=
      cv_d_cot || gt_company_code || cv_d_cot                                        || cv_delimiter
      -- 会社コード
      || TO_CHAR(it_sales_actual.xseh_delivery_date,cv_date_format_non_sep)          || cv_delimiter
      -- 納品日
      || cv_d_cot || TO_CHAR(it_sales_actual.xseh_dlv_invoice_number) || cv_d_cot    || cv_delimiter
      -- 伝票番号
      || TO_CHAR(it_sales_actual.xsel_dlv_invoice_line_number)                       || cv_delimiter
      -- 行No
      || cv_d_cot || it_sales_actual.xseh_ship_to_customer_code       || cv_d_cot    || cv_delimiter 
      -- 顧客コード
      || cv_d_cot || it_sales_actual.xsel_item_code                   || cv_d_cot    || cv_delimiter 
      -- 商品コード
      || cv_d_cot || get_external_code(it_sales_actual.hca_cust_account_id) || cv_d_cot || cv_delimiter 
      -- 物件コード
      || cv_d_cot || NVL(it_sales_actual.xsel_hot_cold_class,gt_hc_class)   || cv_d_cot || cv_delimiter 
      -- H/C
      || cv_d_cot || it_sales_actual.xseh_sales_base_code || cv_d_cot                || cv_delimiter 
      -- 売上拠点コード
      || cv_d_cot || NVL(it_sales_actual.xseh_results_employee_code,cv_def_results_employee_cd) || cv_d_cot || cv_delimiter 
      -- 成績者コード
      || cv_d_cot || NVL(it_sales_actual.xseh_card_sale_class,cv_def_card_sale_class) || cv_d_cot || cv_delimiter 
      -- カード売上区分
      || cv_d_cot || it_sales_actual.xsel_delivery_base_code || cv_d_cot             || cv_delimiter 
      -- 納品拠点コード
--****************************** 2009/06/05 2.7 S.Kayahara MOD START ******************************--
--      || edit_sales_amount(ln_sales_amount_cash)                                     || cv_delimiter
      || ln_sales_amount_cash                                                        || cv_delimiter 
      -- 売上金額
--****************************** 2009/06/05 2.7 S.Kayahara MOD End ******************************--
      || ln_sales_quantity_cash                                                      || cv_delimiter 
      -- 売上数量
      || ln_tax_cash                                                                 || cv_delimiter 
      -- 消費税額
--****************************** 2009/05/21 2.4 S.Kayahara MOD  START  ******************************--
--      || cv_d_cot || it_sales_actual.xseh_dlv_invoice_class || cv_d_cot              || cv_delimiter 
      || cv_d_cot || lt_dlv_invoice_class || cv_d_cot                                || cv_delimiter              
--****************************** 2009/05/21 2.4 S.Kayahara MOD  END  ******************************--      
      -- 売上返品区分
      || cv_d_cot || it_sales_actual.xsel_sales_class || cv_d_cot                    || cv_delimiter 
      -- 売上区分
      || cv_d_cot || it_sales_actual.xsel_delivery_pattern_class || cv_d_cot         || cv_delimiter 
      -- 納品形態区分
      || cv_d_cot || NVL(it_sales_actual.xsel_column_no,cv_def_column_no) || cv_d_cot || cv_delimiter 
      -- コラムNo
--      || TO_CHAR(it_sales_actual.xseh_inspect_date,cv_date_format)                  || cv_delimiter -- 検収予定日
      || TO_CHAR(it_sales_actual.xseh_inspect_date,cv_date_format_non_sep)                  || cv_delimiter 
      -- 検収予定日
      || it_sales_actual.xsel_std_unit_price_excluded                                || cv_delimiter 
      -- 納品単価
      || cv_d_cot || it_sales_actual.xseh_tax_code || cv_d_cot                       || cv_delimiter 
      -- 税コード
      || cv_d_cot || it_sales_actual.xchv_bill_account_number || cv_d_cot            || cv_delimiter 
      -- 請求先顧客コード
      || TO_CHAR(gd_system_date,cv_datetime_format);
      -- 連携日時
--
    -- CSVファイル出力
    UTL_FILE.PUT_LINE(
       file   => gt_file_handle
      ,buffer => lv_buffer
    );
    -- 出力件数カウント
    gn_normal_cnt := gn_normal_cnt + 1;
    --
    IF ( ln_card_rec_flag = cn_output_flag_on) THEN
      -- 併用（カード）データの出力
      lv_buffer :=
        cv_d_cot || gt_company_code || cv_d_cot                                       || cv_delimiter 
        -- 会社コード
        || TO_CHAR(it_sales_actual.xseh_delivery_date,cv_date_format_non_sep)         || cv_delimiter 
        -- 納品日
        || cv_d_cot || TO_CHAR(it_sales_actual.xseh_dlv_invoice_number) || cv_d_cot   || cv_delimiter 
        -- 伝票番号
        || TO_CHAR(it_sales_actual.xsel_dlv_invoice_line_number)                      || cv_delimiter 
        -- 行No
        || cv_d_cot || it_sales_actual.xseh_ship_to_customer_code || cv_d_cot         || cv_delimiter 
        -- 顧客コード
        || cv_d_cot || it_sales_actual.xsel_item_code || cv_d_cot                     || cv_delimiter 
        -- 商品コード
        || cv_d_cot || get_external_code(it_sales_actual.hca_cust_account_id) || cv_d_cot || cv_delimiter 
        -- 物件コード
        || cv_d_cot || NVL(it_sales_actual.xsel_hot_cold_class,gt_hc_class) || cv_d_cot || cv_delimiter 
        -- H/C
        || cv_d_cot || it_sales_actual.xseh_sales_base_code || cv_d_cot               || cv_delimiter 
        -- 売上拠点コード
        || cv_d_cot || NVL(it_sales_actual.xseh_results_employee_code,cv_def_results_employee_cd) || cv_d_cot || cv_delimiter 
        -- 成績者コード
        || cv_d_cot || NVL(it_sales_actual.xseh_card_sale_class,cv_def_card_sale_class) || cv_d_cot || cv_delimiter 
        -- カード売上区分
        || cv_d_cot || it_sales_actual.xsel_delivery_base_code || cv_d_cot            || cv_delimiter 
        -- 納品拠点コード
--****************************** 2009/06/05 2.7 S.Kayahara MOD START ******************************--
--        || edit_sales_amount(ln_sales_amount_card)                                    || cv_delimiter 
        || ln_sales_amount_card                                                       || cv_delimiter
        -- 売上金額
--****************************** 2009/06/05 2.7 S.Kayahara MOD END   ******************************--
        || ln_sales_quantity_card                                                     || cv_delimiter 
        -- 売上数量
        || ln_tax_card                                                                || cv_delimiter 
        -- 消費税額
--****************************** 2009/05/21 2.4 S.Kayahara MOD  START  ******************************--
--      || cv_d_cot || it_sales_actual.xseh_dlv_invoice_class || cv_d_cot              || cv_delimiter 
      || cv_d_cot || lt_dlv_invoice_class || cv_d_cot                                || cv_delimiter              
--****************************** 2009/05/21 2.4 S.Kayahara MOD  END    ******************************--      
        -- 売上返品区分
        || cv_d_cot || it_sales_actual.xsel_sales_class || cv_d_cot                   || cv_delimiter 
        -- 売上区分
        || cv_d_cot || it_sales_actual.xsel_delivery_pattern_class || cv_d_cot        || cv_delimiter 
        -- 納品形態区分
        || cv_d_cot || NVL(it_sales_actual.xsel_column_no,cv_def_column_no) || cv_d_cot || cv_delimiter 
        -- コラムNo
--        || TO_CHAR(it_sales_actual.xseh_inspect_date,cv_date_format)                  || cv_delimiter -- 検収予定日
        || TO_CHAR(it_sales_actual.xseh_inspect_date,cv_date_format_non_sep)          || cv_delimiter 
        -- 検収予定日
        || it_sales_actual.xsel_std_unit_price_excluded                               || cv_delimiter 
        -- 納品単価
        || cv_d_cot || it_sales_actual.xseh_tax_code || cv_d_cot                      || cv_delimiter 
        -- 税コード
--****************************** 2009/04/23 2.3 5 T.Kitajima MOD START ******************************--
--        || it_sales_actual.xchv_cash_account_number                                   || cv_delimiter 
        || cv_d_cot || it_sales_actual.xchv_cash_account_number || cv_d_cot           || cv_delimiter 
--****************************** 2009/04/23 2.3 5 T.Kitajima MOD  END  ******************************--
        -- 入金先顧客コード
        || TO_CHAR(gd_system_date,cv_datetime_format);
        -- 連携日時
--
      -- CSVファイル出力
      UTL_FILE.PUT_LINE(
         file    => gt_file_handle
        ,buffer  => lv_buffer
      );
      -- 出力件数カウント
--****************************** 2009/04/23 2.3 6 T.Kitajima MOD START ******************************--
--      gn_normal_cnt := gn_normal_cnt + 1;
      gn_card_count := gn_card_count + 1;
--****************************** 2009/04/23 2.3 6 T.Kitajima MOD  END  ******************************--

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
  END output_for_seles_actual;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_deal_info
   * Description      : AR取引情報データ抽出(A-5)
   ***********************************************************************************/
  PROCEDURE get_ar_deal_info(
-- 2010/02/02 Ver.2.15 Mod Start
    id_gl_date_from       IN  DATE,             -- GL記帳日(開始)
    id_gl_date_to         IN  DATE,             -- GL記帳日(終了)
    iv_lookup_code        IN  VARCHAR2,         -- 参照コード
    iv_ship_account_code  IN  VARCHAR2,         -- 出荷先顧客コード
--    id_delivery_date      IN  DATE,             --   納品日
-- 2010/02/02 Ver.2.15 Mod End
    in_ship_account_id    IN  NUMBER,           --   出荷先顧客ID
    iv_ship_account_name  IN  VARCHAR2,         --   出荷先顧客名
    ov_errbuf             OUT NOCOPY VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_deal_info'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_table_name         VARCHAR2(100);            -- テーブル名格納
--
    -- *** ローカル例外 ***
    dealing_info_extra_expt     EXCEPTION;   -- AR取引情報抽出データなし
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
    BEGIN
      OPEN get_ar_deal_info_cur(
-- 2010/02/02 Ver.2.15 Mod Start
               id_gl_date_from    => id_gl_date_from        -- GL記帳日(開始)
              ,id_gl_date_to      => id_gl_date_to          -- GL記帳日(終了)
              ,iv_lookup_code     => iv_lookup_code         -- 参照コード
--              id_delivery_date    => id_delivery_date       -- 納品日
-- 2010/02/02 Ver.2.15 Mod End
             ,in_ship_account_id  => in_ship_account_id     -- 出荷先顧客ID
           );
      --
      -- レコード読込み
      FETCH get_ar_deal_info_cur BULK COLLECT INTO gt_ar_deal_tbl;
      --
      -- 抽出件数設定
      gn_target_cnt := gn_target_cnt + gt_ar_deal_tbl.COUNT;
      --
      -- クローズ
      CLOSE get_ar_deal_info_cur;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE dealing_info_extra_expt;
    END;
--
    IF ( gt_ar_deal_tbl.COUNT = 0 ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_notfound_ar_deal
                     ,iv_token_name1  => cv_tkn_account_name
                     ,iv_token_value1 => iv_ship_account_name
-- 2010/02/02 Ver.2.15 Mod Start
                     ,iv_token_name2  => cv_tkn_account_number
                     ,iv_token_value2 => iv_ship_account_code);
--                     ,iv_token_name2  => cv_tkn_account_id
--                     ,iv_token_value2 => TO_CHAR(in_ship_account_id));
-- 2010/02/02 Ver.2.15 Mod End
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2010/02/02 Ver.2.15 Add Start
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
-- 2010/02/02 Ver.2.15 Add End
      -- データが取得できない場合、警告
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    --*** AR取引情報抽出データなし ***
    WHEN dealing_info_extra_expt THEN
      IF ( get_ar_deal_info_cur%ISOPEN ) THEN
        CLOSE get_ar_deal_info_cur;
      END IF;
      lv_table_name := xxccp_common_pkg.get_msg(
          iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
         ,iv_name        => cv_msg_ar_deal                  -- メッセージID
      );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_data_extra_error
                     ,iv_token_name1  => cv_tkn_table_name
                     ,iv_token_value1 => lv_table_name
                     ,iv_token_name2  => cv_tkn_key_data
                     ,iv_token_value2 => cv_blank);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( get_ar_deal_info_cur%ISOPEN ) THEN
        CLOSE get_ar_deal_info_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( get_ar_deal_info_cur%ISOPEN ) THEN
        CLOSE get_ar_deal_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( get_ar_deal_info_cur%ISOPEN ) THEN
        CLOSE get_ar_deal_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_deal_info;
  --
  /**********************************************************************************
   * Procedure Name   : output_for_ar_deal
   * Description      : 売上実績CSV作成(AR取引情報)(A-6)
   ***********************************************************************************/
  PROCEDURE output_for_ar_deal(
    it_sales_rec   IN  get_sales_actual_cur%ROWTYPE,         --   売上実績(レコード型)
    ov_errbuf      OUT NOCOPY VARCHAR2,                      --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,                      --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)                      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_for_ar_deal'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_buffer               VARCHAR2(2000);                      -- 出力データ
    lt_dlv_invoice_class    fnd_lookup_values.attribute1%TYPE;   -- 納品伝票区分
    lv_type_name            VARCHAR2(50);
    --
    -- *** ローカル・レコード型 ***
    it_ar_deal_rec          get_ar_deal_info_cur%ROWTYPE;
    --
    -- *** ローカル例外 ***
    non_lookup_value_expt   EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --=========================================
    -- 参照タイプ（納品伝票区分特定マスタ）取得
    --=========================================
    BEGIN
      SELECT flv.attribute1     flv_attribute1
      INTO   lt_dlv_invoice_class
      FROM   fnd_lookup_values  flv
      WHERE  flv.meaning       = it_sales_rec.xseh_dlv_invoice_class
      AND    flv.lookup_type   = cv_ref_t_dlv_slp_cls_mst
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag
      AND    gd_business_date BETWEEN NVL(flv.start_date_active,gd_business_date)
                              AND     NVL(flv.end_date_active,  gd_business_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_type_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_ar_txn_name              -- メッセージID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name
                       ,iv_name         => cv_msg_dlv_slp_cls
                       ,iv_token_name1  => cv_tkn_lookup_type
                       ,iv_token_value1 => lv_type_name
                       ,iv_token_name2  => cv_tkn_meaning
                       ,iv_token_value2 => it_sales_rec.xseh_dlv_invoice_class);
        RAISE non_lookup_value_expt;
    END;
--
    IF ( lt_dlv_invoice_class IS NULL ) THEN
      lv_type_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_ar_txn_name              -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_dlv_slp_cls
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => lv_type_name
                     ,iv_token_name2  => cv_tkn_meaning
                     ,iv_token_value2 => it_sales_rec.xseh_dlv_invoice_class);
      RAISE non_lookup_value_expt;
    END IF;
--
    <<ar_output_loop>>
    FOR ln_idx IN gt_ar_deal_tbl.FIRST..gt_ar_deal_tbl.LAST LOOP
      --
/*2009/12/29 Ver2.13 Add Start */
      --伝票番号(取引番号)の桁数チェック(警告)
      IF ( lengthb( gt_ar_deal_tbl(ln_idx).rcta_trx_number ) > cn_trx_num_length ) THEN
        --12桁以上の場合は、メッセージ出力(明細単位で出力)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_ar_trx_number
                     ,iv_token_name1  => cv_tkn_base_code
                     ,iv_token_value1 => gt_ar_deal_tbl(ln_idx).delivery_base_code
                     ,iv_token_name2  => cv_tkn_account_number
                     ,iv_token_value2 => gt_ar_deal_tbl(ln_idx).ship_account_number
                     ,iv_token_name3  => cv_tkn_gl_date
                     ,iv_token_value3 => TO_CHAR( gt_ar_deal_tbl(ln_idx).rctlgda_gl_date, cv_date_format )
                     ,iv_token_name4  => cv_tkn_ar_trx_number
                     ,iv_token_value4 => TO_CHAR( gt_ar_deal_tbl(ln_idx).rcta_trx_number )
                     );
        --ログ
        FND_FILE.PUT_LINE( 
          which  => FND_FILE.LOG 
         ,buff   => lv_errmsg
        );
        --出力
        FND_FILE.PUT_LINE( 
          which  => FND_FILE.OUTPUT 
         ,buff   => lv_errmsg
        );
-- 2010/02/02 Ver.2.15 Add Start
        --ログ
        FND_FILE.PUT_LINE( 
          which  => FND_FILE.LOG 
         ,buff   => ''
        );
        --出力
        FND_FILE.PUT_LINE( 
          which  => FND_FILE.OUTPUT 
         ,buff   => ''
        );
-- 2010/02/02 Ver.2.15 Add End
        
        
        --コンカレントを警告とする為、フラグで保持
        gn_ar_trx_num_warn := cn_1;
        --12桁に切捨て
        gt_ar_deal_tbl(ln_idx).rcta_trx_number
/*2010/01/06 Ver2.14 Mod Start   */
          := SUBSTRB( gt_ar_deal_tbl(ln_idx).rcta_trx_number , 1, cn_trx_num_length );
--          := TO_NUMBER( SUBSTRB( TO_CHAR( gt_ar_deal_tbl(ln_idx).rcta_trx_number ), 1, cn_trx_num_length ) );
/*2010/01/06 Ver2.14 Mod End   */
      END IF;
      --
/*2009/12/29 Ver2.13 Add End   */
      lv_buffer :=
        cv_d_cot || gt_company_code || cv_d_cot                                  || cv_delimiter    -- 会社コード
/*2010/01/06 Ver2.14 Mod Start   */
        || TO_CHAR(gt_ar_deal_tbl(ln_idx).rctlgda_gl_date,cv_date_format_non_sep)  || cv_delimiter    -- 納品日
--        || TO_CHAR(gt_ar_deal_tbl(ln_idx).rcta_trx_date,cv_date_format_non_sep)  || cv_delimiter    -- 納品日
/*2010/01/06 Ver2.14 Mod End   */
        || cv_d_cot || TO_CHAR(gt_ar_deal_tbl(ln_idx).rcta_trx_number) || cv_d_cot || cv_delimiter    -- 伝票番号
        || TO_CHAR(gt_ar_deal_tbl(ln_idx).rctla_line_number)                     || cv_delimiter    -- 行No
        || cv_d_cot || it_sales_rec.xseh_ship_to_customer_code || cv_d_cot       || cv_delimiter    -- 顧客コード
        || cv_d_cot || gt_ar_deal_tbl(ln_idx).puroduct_code || cv_d_cot          || cv_delimiter    -- 商品コード
        || cv_d_cot || get_external_code(it_sales_rec.hca_cust_account_id) || cv_d_cot || cv_delimiter -- 物件コード
--****************************** 2009/04/23 2.3 1 T.Kitajima MOD START ******************************--
--        || cv_d_cot || gt_hc_class || cv_d_cot                                   || cv_delimiter    -- H/C
        || cv_d_cot || NVL( gt_hc_class, cv_h_c_cold ) || cv_d_cot               || cv_delimiter    -- H/C
--****************************** 2009/04/23 2.3 1 T.Kitajima MOD  END  ******************************--
        || cv_d_cot || gt_ar_deal_tbl(ln_idx).delivery_base_code || cv_d_cot     || cv_delimiter    -- 売上拠点コード
        || cv_d_cot || cv_def_results_employee_cd || cv_d_cot                    || cv_delimiter    -- 成績者コード
        || cv_d_cot || cv_def_card_sale_class || cv_d_cot                        || cv_delimiter    -- カード売上区分
        || cv_d_cot || cv_def_delivery_base_code || cv_d_cot                     || cv_delimiter    -- 納品拠点コード
--****************************** 2009/06/05 2.7 S.Kayahara MOD START ******************************--
--        || (-1) * edit_sales_amount(gt_ar_deal_tbl(ln_idx).rctla_revenue_amount) || cv_delimiter    -- 売上金額
        || (-1) * gt_ar_deal_tbl(ln_idx).rctla_revenue_amount                    || cv_delimiter    -- 売上金額
--****************************** 2009/06/05 2.7 S.Kayahara MOD END   ******************************--
        || cn_non_sales_quantity                                                 || cv_delimiter    -- 売上数量
        || (-1) * gt_ar_deal_tbl(ln_idx).rctla_t_revenue_amount                  || cv_delimiter    -- 消費税額
        || cv_d_cot || lt_dlv_invoice_class || cv_d_cot                          || cv_delimiter    -- 売上返品区分
        || cv_d_cot || it_sales_rec.xsel_sales_class || cv_d_cot                 || cv_delimiter    -- 売上区分
        || cv_d_cot || gt_dlv_ptn_cls || cv_d_cot                                || cv_delimiter    -- 納品形態区分
--****************************** 2009/04/23 2.3 3 T.Kitajima MOD START ******************************--
--        || cv_def_column_no                                                      || cv_delimiter    -- コラムNo
        || cv_d_cot || cv_def_column_no || cv_d_cot                              || cv_delimiter    -- コラムNo
--****************************** 2009/04/23 2.3 3 T.Kitajima MOD  END  ******************************--
        || cv_blank                                                              || cv_delimiter    -- 検収予定日
        || cn_non_std_unit_price                                                 || cv_delimiter    -- 納品単価
        || cv_d_cot || gt_ar_deal_tbl(ln_idx).avtab_tax_code || cv_d_cot         || cv_delimiter    -- 税コード
        || cv_d_cot || it_sales_rec.xchv_bill_account_number || cv_d_cot         || cv_delimiter    -- 請求先顧客コード
        || TO_CHAR(gd_system_date,cv_datetime_format);                                              -- 連携日時
  --
      -- CSVファイル出力
      UTL_FILE.PUT_LINE(
         file     => gt_file_handle
        ,buffer   => lv_buffer
      );
      -- 出力件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP ar_output_loop;
--
  EXCEPTION
    WHEN non_lookup_value_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END output_for_ar_deal;
--
  /**********************************************************************************
   * Procedure Name   : update_sales_header_status
   * Description      : 売上実績ヘッダステータス更新(A-7)
   ***********************************************************************************/
  PROCEDURE update_sales_header_status(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sales_header_status'; -- プログラム名
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
    cv_interface_flag_comp    CONSTANT VARCHAR2(1) := 'Y';   -- インターフェース済み
--
    -- *** ローカル変数 ***
    lv_item_name              VARCHAR2(255);      -- 項目名
    lv_table_name             VARCHAR2(255);      -- テーブル名
    ln_dlv_invoice_number     NUMBER;
-- ************** 2009/09/28 2.11 N.Maeda ADD START **************** --
    lv_update_err_info        VARCHAR2(5000);     -- 更新エラー詳細
-- ************** 2009/09/28 2.11 N.Maeda ADD  END  **************** --
--
    -- *** ローカル例外 ***
    update_expt               EXCEPTION;          -- 更新エラー
--
--****************************** 2009/06/08 2.8 N.Maeda ADD START ******************************--
--
    CURSOR get_lock_cur ( in_rowid ROWID )
    IS
      SELECT  'Y'
      FROM    xxcos_sales_exp_headers xseh
      WHERE   xseh.ROWID = in_rowid
    FOR UPDATE NOWAIT;
--
--****************************** 2009/06/08 2.8 N.Maeda ADD  END  ******************************--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--****************************** 2009/06/08 2.8 N.Maeda ADD START ******************************--
        --
    FOR l IN g_sales_h_tbl.FIRST..g_sales_h_tbl.LAST LOOP
      OPEN get_lock_cur (g_sales_h_tbl(l));
      CLOSE get_lock_cur;
    END LOOP;
        --
--****************************** 2009/06/08 2.8 N.Maeda ADD  END  ******************************--
    BEGIN
      FORALL ln_idx IN g_sales_h_tbl.FIRST..g_sales_h_tbl.LAST
        UPDATE xxcos_sales_exp_headers  xseh                                  -- 販売実績ヘッダ
        SET     xseh.dwh_interface_flag     = cv_interface_flag_comp          -- 情報システムインタフェースフラグ
               ,xseh.last_updated_by        = cn_last_updated_by              -- 最終更新者
               ,xseh.last_update_date       = cd_last_update_date             -- 最終更新日
               ,xseh.last_update_login      = cn_last_update_login            -- 最終更新ログイン
               ,xseh.request_id             = cn_request_id                   -- 要求ID
               ,xseh.program_application_id = cn_program_application_id       -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
               ,xseh.program_id             = cn_program_id                   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
               ,xseh.program_update_date    = cd_program_update_date          -- プログラム更新日
        WHERE  xseh.rowid                   = g_sales_h_tbl(ln_idx);          -- ROWID
    EXCEPTION
      WHEN OTHERS THEN
-- ************** 2009/09/28 2.11 N.Maeda ADD START **************** --
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1  => xxccp_common_pkg.get_msg(
                              iv_application => cv_xxcos_short_name,
                              iv_name        => cv_msg_details
                              ),              -- 文字列「詳細」
          iv_data_value1 => SQLERRM,          -- エラー詳細
          ov_key_info    => lv_update_err_info,      -- 
          ov_errbuf      => lv_errbuf,        -- エラー・メッセージエラー       #固定#
          ov_retcode     => lv_retcode,       -- リターン・コード               #固定#
          ov_errmsg      => lv_errmsg         -- ユーザー・エラー・メッセージ   #固定#
          );
-- ************** 2009/09/28 2.11 N.Maeda ADD  END  **************** --
        -- 更新に失敗した場合
        RAISE update_expt;
      -- ロックエラー
    END;
--
  EXCEPTION
    --*** 更新エラー ***
    WHEN update_expt THEN
     lv_table_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_sales_header             -- メッセージID
     );
     lv_errmsg :=  xxccp_common_pkg.get_msg(
         iv_application   => cv_xxcos_short_name
        ,iv_name          => cv_msg_update_error
        ,iv_token_name1   => cv_tkn_table_name
        ,iv_token_value1  => lv_table_name
        ,iv_token_name2   => cv_tkn_key_data
        ,iv_token_value2  => cv_blank
      );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
-- ************** 2009/09/28 2.11 N.Maeda MOD START **************** --
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg||lv_update_err_info,1,5000);
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
-- ************** 2009/09/28 2.11 N.Maeda MOD  END  **************** --
      ov_retcode := cv_status_error;                                            --# 任意 #
    --*** ロックエラー ***
    WHEN record_lock_expt THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_table_name := xxccp_common_pkg.get_msg(
          iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
         ,iv_name        => cv_msg_sales_line               -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name
                     ,iv_name         => cv_msg_lock_error
                     ,iv_token_name1  => cv_tkn_table
                     ,iv_token_value1 => lv_table_name);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;   
    --
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
  END update_sales_header_status;
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : ファイルクローズ(A-8)
   ***********************************************************************************/
  PROCEDURE file_close(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_close'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- ファイルクローズ
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gt_file_handle
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
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : expt_proc
   * Description      : 例外処理(A-9)
   ***********************************************************************************/
  PROCEDURE expt_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'expt_proc'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF ( UTL_FILE.IS_OPEN(gt_file_handle) = TRUE ) THEN
      -- ファイルがオープンされている場合
      UTL_FILE.FCLOSE(
        file => gt_file_handle
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
  END expt_proc;
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
    -- *** ローカル変数 ***
    lv_errbuf_wk  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_wk VARCHAR2(1);     -- リターン・コード
    lv_errmsg_wk  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_index      VARCHAR2(30);    -- インデックス・キー
-- 2010/02/02 Ver.2.15 Add Start
    ld_pre_digestion_due_date     DATE;
    ld_digestion_due_date         DATE;
-- 2010/02/02 Ver.2.15 Add Start
--
    -- *** ローカル例外 ***
    sub_program_expt      EXCEPTION;
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
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD START ******************************--
    gn_card_count := 0;
--****************************** 2009/04/23 2.3 6 T.Kitajima ADD  END  ******************************--
--
    BEGIN
      -- ===============================
      -- A-1.初期処理
      -- ===============================
      init(
         ov_errbuf   => lv_errbuf        -- エラー・メッセージ
        ,ov_retcode  => lv_retcode       -- リターン・コード
        ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      -- ===============================
      -- A-2.ファイルオープン
      -- ===============================
      file_open(
         ov_errbuf   => lv_errbuf        -- エラー・メッセージ
        ,ov_retcode  => lv_retcode       -- リターン・コード
        ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      -- ===============================
      -- A-3.販売実績データ抽出
      -- ===============================
      get_sales_actual_data(
         ov_errbuf   => lv_errbuf        -- エラー・メッセージ
        ,ov_retcode  => lv_retcode       -- リターン・コード
        ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
      <<sales_actual_loop>>
      LOOP
        FETCH get_sales_actual_cur INTO g_sales_actual_rec;
        EXIT WHEN get_sales_actual_cur%NOTFOUND;
        gn_target_cnt := gn_target_cnt + 1;
--
-- 2010/02/02 Ver.2.15 Add Start
        IF ( g_sales_actual_rec.xseh_create_class <> gt_mk_org_cls_vd ) THEN
-- 2010/02/02 Ver.2.15 Add Start
        --==================================
        -- 売上実績CSV作成(A-4)
        --==================================
        output_for_seles_actual(
           it_sales_actual => g_sales_actual_rec     -- 売上実績レコード型
          ,ov_errbuf       => lv_errbuf              -- エラー・メッセージ
          ,ov_retcode      => lv_retcode             -- リターン・コード
          ,ov_errmsg       => lv_errmsg);            -- ユーザー・エラー・メッセージ
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE sub_program_expt;
        END IF;
-- 2010/02/02 Ver.2.15 Add Start
        END IF;
-- 2010/02/02 Ver.2.15 Add Start
        --
        IF ( g_sales_actual_rec.xseh_create_class = gt_mk_org_cls ) THEN
          -- 消化計算の場合、売上実績（AR取引情報)CSVファイル作成
          lv_index := TO_CHAR(g_sales_actual_rec.xchv_ship_account_id)
                     || TO_CHAR(TRUNC(g_sales_actual_rec.xseh_delivery_date,cv_trunc_fmt),cv_date_format_non_sep);
          IF (g_ar_output_settled_tbl.EXISTS(lv_index) = FALSE ) THEN
            -- 未出力の場合
            --==================================
            -- AR取引情報データ抽出(A-5)
            --==================================
            get_ar_deal_info(
-- 2010/02/02 Ver.2.15 Mod Start
               id_gl_date_from      => TRUNC(g_sales_actual_rec.xseh_delivery_date,cv_trunc_fmt)   -- GL記帳日(開始)
              ,id_gl_date_to        => LAST_DAY(g_sales_actual_rec.xseh_delivery_date)             -- GL記帳日(終了)
              ,iv_lookup_code       => cv_txn_sales_type                                           -- 参照コード
              ,iv_ship_account_code => g_sales_actual_rec.xseh_ship_to_customer_code               -- 出荷先顧客コード
--               id_delivery_date     => g_sales_actual_rec.xseh_delivery_date       -- 納品日
-- 2010/02/02 Ver.2.15 Mod End
              ,in_ship_account_id   => g_sales_actual_rec.xchv_ship_account_id     -- 出荷先顧客ID
              ,iv_ship_account_name => g_sales_actual_rec.xchv_ship_account_name   -- 請求先顧客名
              ,ov_errbuf            => lv_errbuf                                   -- エラー・メッセージ
              ,ov_retcode           => lv_retcode                                  -- リターン・コード
              ,ov_errmsg            => lv_errmsg);                                 -- ユーザ・エラー・メッセージ
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE sub_program_expt;
            END IF;
--
            IF ( lv_retcode = cv_status_normal) THEN
              --==================================
              --  売上実績CSV作成(AR取引情報)(A-6)
              --==================================
              output_for_ar_deal(
                 it_sales_rec    => g_sales_actual_rec    -- 売上実績(レコード型)
                ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ
                ,ov_retcode      => lv_retcode            -- リターン・コード
                ,ov_errmsg       => lv_errmsg);           -- ユーザ・エラー・メッセージ
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE sub_program_expt;
              END IF;
            ELSE
              -- 対象データなし
              -- エラー件数カウント
              gn_error_cnt := gn_error_cnt + 1;
            END IF;
            -- AR出力済み顧客情報に設定
            g_ar_output_settled_tbl(lv_index) := NULL;
          END IF;
 -- 2010/02/02 Ver.2.15 Add Start
        ELSIF ( g_sales_actual_rec.xseh_create_class = gt_mk_org_cls_vd ) THEN
          -- 消化VDの消化計算の場合
          lv_index := TO_CHAR(g_sales_actual_rec.sales_exp_header_id);
          IF ( g_ar_output_vd_tbl.EXISTS(lv_index) = FALSE ) THEN
            -- 未出力の場合
            BEGIN
              SELECT  xvdh.pre_digestion_due_date                           -- 前回消化計算締年月日
                     ,xvdh.digestion_due_date                               -- 消化計算締年月日
              INTO    ld_pre_digestion_due_date
                     ,ld_digestion_due_date
              FROM   xxcos_vd_digestion_hdrs    xvdh
              WHERE  xvdh.sales_exp_header_id          = g_sales_actual_rec.sales_exp_header_id
              ;
              --
              IF ( ld_pre_digestion_due_date IS NULL ) THEN
                ld_pre_digestion_due_date := gd_ar_start_date;
              ELSE
                ld_pre_digestion_due_date := ld_pre_digestion_due_date + 1;
              END IF;
              --
              -- GL記帳日(開始)の判定
              IF ( ld_pre_digestion_due_date < gd_ar_start_date ) THEN
                -- 前回消化計算締年月日がAR対象開始日より過去の場合、AR対象開始日を設定
                ld_pre_digestion_due_date    := gd_ar_start_date;
              END IF;
              --
              --==================================
              -- AR取引情報データ抽出(A-5)
              --==================================
              get_ar_deal_info(
                 id_gl_date_from      => ld_pre_digestion_due_date                        -- GL記帳日(開始)
                ,id_gl_date_to        => ld_digestion_due_date                            -- GL記帳日(終了)
                ,iv_lookup_code       => cv_txn_vd_digestion_type                         -- 参照コード
                ,iv_ship_account_code => g_sales_actual_rec.xseh_ship_to_customer_code    -- 出荷先顧客コード
                ,in_ship_account_id   => g_sales_actual_rec.xchv_ship_account_id          -- 出荷先顧客ID
                ,iv_ship_account_name => g_sales_actual_rec.xchv_ship_account_name        -- 請求先顧客名
                ,ov_errbuf            => lv_errbuf                                        -- エラー・メッセージ
                ,ov_retcode           => lv_retcode                                       -- リターン・コード
                ,ov_errmsg            => lv_errmsg);                                      -- メッセージ
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE sub_program_expt;
              END IF;
              --
              IF ( lv_retcode = cv_status_normal) THEN
                -- AR情報がある場合
                --==================================
                --  売上実績CSV作成(AR取引情報)(A-6)
                --==================================
                output_for_ar_deal(
                   it_sales_rec    => g_sales_actual_rec    -- 売上実績(レコード型)
                  ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ
                  ,ov_retcode      => lv_retcode            -- リターン・コード
                  ,ov_errmsg       => lv_errmsg);           -- ユーザ・エラー・メッセージ
                IF ( lv_retcode = cv_status_error ) THEN
                  RAISE sub_program_expt;
                END IF;
              ELSE
                -- 対象データなし
                -- エラー件数カウント
                gn_error_cnt := gn_error_cnt + 1;
              END IF;
            EXCEPTION
              -- 消化VDの消化計算が取得できない場合
              WHEN OTHERS THEN
                -- エラーテーブルに設定
                g_vd_digestion_err_tbl(lv_index) := NULL;
                --
                -- メッセージ作成
                lv_errmsg_wk := xxccp_common_pkg.get_msg(
                   iv_application  => cv_xxcos_short_name                             -- アプリケーション短縮名
                  ,iv_name         => cv_msg_vd_digestion_data                        -- メッセージ
                  ,iv_token_name1  => cv_tkn_account_number                           -- 出荷先顧客コード
                  ,iv_token_value1 => g_sales_actual_rec.xseh_ship_to_customer_code
                  ,iv_token_name2  => cv_tkn_delivery_date                            -- 納品日
                  ,iv_token_value2 => TO_CHAR(g_sales_actual_rec.xseh_delivery_date,cv_date_format)
                  ,iv_token_name3  => cv_tkn_sales_header_id                          -- 販売実績ID
                  ,iv_token_value3 => g_sales_actual_rec.sales_exp_header_id
                );
                -- メッセージ出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => lv_errmsg_wk
                );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => ''
                );
                -- エラー件数カウント
                gn_error_cnt := gn_error_cnt + 1;
                -- 警告を設定
                ov_retcode := cv_status_warn;
            END;
            -- AR出力済み顧客情報に設定
            g_ar_output_vd_tbl(lv_index) := NULL;
          END IF;
--
        IF ( g_vd_digestion_err_tbl.EXISTS(TO_CHAR(g_sales_actual_rec.sales_exp_header_id)) = FALSE ) THEN
          -- エラーテーブルに販売実績ヘッダが設定されていない場合
          --==================================
          -- 売上実績CSV作成(A-4)
          --==================================
          output_for_seles_actual(
             it_sales_actual => g_sales_actual_rec     -- 売上実績レコード型
            ,ov_errbuf       => lv_errbuf              -- エラー・メッセージ
            ,ov_retcode      => lv_retcode             -- リターン・コード
            ,ov_errmsg       => lv_errmsg);            -- ユーザー・エラー・メッセージ
          --
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE sub_program_expt;
          END IF;
        END IF;
-- 2010/02/02 Ver.2.15 Add End
        END IF;
--
-- 2010/02/02 Ver.2.15 Add Start
        -- 消化VDの消化計算情報の取得エラーが発生していない場合、フラグ更新用テーブルに設定
        IF ( g_vd_digestion_err_tbl.EXISTS(TO_CHAR(g_sales_actual_rec.sales_exp_header_id)) = FALSE ) THEN
-- 2010/02/02 Ver.2.15 Add End
        -- ROWIDと納品伝票番号を内部テーブルに設定
        g_sales_h_tbl(gn_sales_h_count) := g_sales_actual_rec.xseh_rowid;
        gn_sales_h_count := gn_sales_h_count + 1;
-- 2010/02/02 Ver.2.15 Add Start
        END IF;
-- 2010/02/02 Ver.2.15 Add End
  --
      END LOOP sales_actual_loop;
      --
      -- 処理データ件数チェック
      IF ( get_sales_actual_cur%ROWCOUNT = 0 ) THEN
        -- 処理対象データなし
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name
                       ,iv_name         => cv_msg_notfound_data);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--****************************** 2009/07/03 2.9 T.Miyata ADD START ******************************--
      ELSE
        -- 処理対象データあり
-- 2010/02/02 Ver.2.15 Add End
        IF ( g_sales_h_tbl.COUNT > 0 ) THEN
-- 2010/02/02 Ver.2.15 Add End
        -- ===============================
        -- A-7.売上実績ヘッダステータス更新
        -- ===============================
        update_sales_header_status(
           ov_errbuf   => lv_errbuf        -- エラー・メッセージ
          ,ov_retcode  => lv_retcode       -- リターン・コード
          ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE sub_program_expt;
        END IF;
-- 2010/02/02 Ver.2.15 Add End
        END IF;
-- 2010/02/02 Ver.2.15 Add End
--****************************** 2009/07/03 2.9 T.Miyata ADD  END  ******************************--
      END IF;
      --
      CLOSE get_sales_actual_cur;
--
--****************************** 2009/07/03 2.9 T.Miyata DELETE START ******************************--
--      -- ===============================
--      -- A-7.売上実績ヘッダステータス更新
--      -- ===============================
--      update_sales_header_status(
--         ov_errbuf   => lv_errbuf        -- エラー・メッセージ
--        ,ov_retcode  => lv_retcode       -- リターン・コード
--        ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
--      IF ( lv_retcode = cv_status_error ) THEN
--        RAISE sub_program_expt;
--      END IF;
--****************************** 2009/07/03 2.9 T.Miyata DELETE END   ******************************--
--
      -- ===============================
      -- A-8.ファイルクローズ
      -- ===============================
      file_close(
         ov_errbuf   => lv_errbuf        -- エラー・メッセージ
        ,ov_retcode  => lv_retcode       -- リターン・コード
        ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE sub_program_expt;
      END IF;
--
    EXCEPTION
      WHEN sub_program_expt THEN
        -- プロシージャが異常終了
        -- メッセージを退避
        lv_errbuf_wk := lv_errbuf;
        lv_retcode_wk := lv_retcode;
        lv_errmsg_wk := lv_errmsg;
--
        -- ===============================
        -- A-9.例外処理
        -- ===============================
        expt_proc(
           ov_errbuf   => lv_errbuf        -- エラー・メッセージ
          ,ov_retcode  => lv_retcode       -- リターン・コード
          ,ov_errmsg   => lv_errmsg);      -- ユーザ・エラー・メッセージ
        IF ( lv_retcode = cv_status_error ) THEN
          IF ( UTL_FILE.IS_OPEN(gt_file_handle) = TRUE ) THEN
            -- ファイルがオープンされている場合
            UTL_FILE.FCLOSE(
              file => gt_file_handle
            );
          END IF;
        END IF;
--
        -- メッセージを戻す
        lv_errbuf  := lv_errbuf_wk;
        lv_retcode := lv_retcode_wk;
        lv_errmsg  := lv_errmsg_wk;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
          IF ( get_sales_actual_cur%ISOPEN ) THEN
        CLOSE get_sales_actual_cur;
      END IF;
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
    --
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode != cv_status_normal) THEN
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
--
--****************************** 2009/04/23 2.3 6 T.Kitajima MOD START ******************************--
--    --対象件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_target_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
--    --成功件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_success_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
--                   );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_count
                    ,iv_token_name1  => cv_tkn_count_1
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                    ,iv_token_name2  => cv_tkn_count_2
                    ,iv_token_value2 => TO_CHAR(gn_normal_cnt)
                    ,iv_token_name3  => cv_tkn_count_3
                    ,iv_token_value3 => TO_CHAR(gn_card_count)
                   );
--****************************** 2009/04/23 2.3 6 T.Kitajima MOD  END  ******************************--
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
/* 2009/12/29 Ver2.13 Add Start */
    --伝票番号桁数エラーの場合、警告とする
    IF ( lv_retcode <> cv_status_error )
      AND( gn_ar_trx_num_warn = cn_1 ) THEN
      lv_retcode := cv_status_warn;
    END IF;
/* 2009/12/29 Ver2.13 Add End   */
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
END XXCOS015A01C;
/
