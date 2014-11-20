CREATE OR REPLACE PACKAGE BODY APPS.XXCOS013A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS013A03C (body)
 * Description      : 販売実績情報より仕訳情報を作成し、一般会計OIFに連携する処理
 * MD.050           : GLへの販売実績データ連携 MD050_COS_013_A03
 * Version          : 1.11
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  roundup                切上関数
 *  init                   初期処理(A-1)
 *  get_data               販売実績データ取得(A-2)
 *  edit_work_data         一般会計OIF集約処理(A-3)
 *  edit_gl_data           一般会計OIF仕訳作成(A-4)
 *  insert_gl_data         一般会計OIF登録処理(A-5)
 *  upd_data               販売実績ヘッダ更新処理(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(終了処理A-7を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2008/12/01    1.0   R.HAN            新規作成
 *  2009/02/17    1.1   R.HAN            get_msgのパッケージ名修正
 *  2009/02/23    1.2   R.HAN            パラメータのログファイル出力対応
 *  2009/02/23    1.3   R.HAN            [COS_115]税コードの結合条件を追加
 *  2009/03/26    1.4   T.Kitajima       [T1_0106]警告処理対応
 *  2009/04/30    1.5   T.Miyata         [T1_0891]最終行に[/]付与
 *  2009/05/13    1.6   T.Kitajima       [T1_0764]OIF連携不正データ修正
 *  2009/07/06    1.7   T.Tominaga       [0000235]対象データ無しメッセージのトークン削除
 *  2009/08/25    1.8   M.Sano           [0001166]CCID取得関数の入力パラメータを変更
 *  2009/09/14    1.9   K.Atsushiba      [0001177]PT対応
 *                                       [0001360]BULK処理によるPGA領域不足対応
 *                                       [0001330]パフォーマンス対応
 *  2009/10/07    1.10  N.Maeda          [0001321]処理対象取得条件修正、(ワーニングデータ('W')、未処理データ('N'))
 *                                                連携フラグ更新処理追加(ワーニングエラー('W')、処理対象外('S'))
 *  2009/11/17    1.11  M.Sano           [E_T4_00213]OIFにセットする税コードのセット方法修正
 *                                       [E_T4_00216]返品,返品修正対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START  ###############################
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--#######################  固定グローバル定数宣言部 END   ################################
--
--#######################  固定グローバル変数宣言部 START ################################
--
  gv_out_msg       VARCHAR2(2000);            -- 出力メッセージ
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--#######################  固定グローバル変数宣言部 END   ###############################
--
--##########################  固定共通例外宣言部 START  #################################
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
--##########################  固定共通例外宣言部 END   ###############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);       -- ロックエラー
  global_proc_date_err_expt EXCEPTION;         -- 業務日付取得例外
  global_select_data_expt   EXCEPTION;         -- データ取得例外
  global_insert_data_expt   EXCEPTION;         -- 登録処理例外
  global_update_data_expt   EXCEPTION;         -- 更新処理例外
  global_get_profile_expt   EXCEPTION;         -- プロファイル取得例外
  global_no_data_expt       EXCEPTION;         -- 対象データ０件エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_xxccp_short_nm         CONSTANT VARCHAR2(10) := 'XXCCP';            -- 共通領域短縮アプリ名
  cv_xxcos_short_nm         CONSTANT VARCHAR2(10) := 'XXCOS';            -- 販物アプリケーション短縮名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOS013A03C';     -- パッケージ名
  cv_no_para_msg            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなしメッセージ
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014'; -- 業務日付取得エラー
  cv_pro_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004'; -- プロファイル取得エラー
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013'; -- データ抽出エラーメッセージ
  cv_no_data_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003'; -- 対象データ無しメッセージ
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001'; -- ロックエラーメッセージ（販売実績TB）
  cv_data_insert_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010'; -- データ登録エラーメッセージ
  cv_data_update_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011'; -- データ更新エラーメッセージ
  cv_card_sale_cls_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12851'; -- カード売区分取得エラー
  cv_tax_cls_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12852'; -- 消費税区分取得エラー
  cv_jour_nodata_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12853'; -- 仕訳パターン取得エラー
  cv_tkn_sales_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12854'; -- 販売実績ヘッダ
  cv_tkn_gloif_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12855'; -- 一般会計OIF
  cv_enter_dr_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12856'; -- 借方
  cv_enter_cr_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12857'; -- 貸方
  cv_cash_msg               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12858'; -- 現金(勘定科目用)
  cv_vd_msg                 CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12859'; -- VD未収金仮勘定(勘定科目用)
  cv_tax_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12860'; -- 仮受消費税等(勘定科目用)
  cv_source_nm_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12861'; -- 販売実績(仕訳ソース名)
  cv_tkn_ccid_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12863'; -- 勘定科目組合せマスタ
  cv_ccid_nodata_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12864'; -- CCID取得出来ないエラー
  cv_full_vd                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12866'; -- フルVD売上
  cv_vd_xiaoka              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12867'; -- フルVD（消化）売上
  cv_full_vd_cash           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12868'; -- フルVD現金
  cv_full_vd_card           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12869'; -- フルVDカード
  cv_vd_xiaoka_cash         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12870'; -- フルVD(消化)現金
  cv_vd_xiaoka_card         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12871'; -- フルVD(消化)カード
  cv_om_sales               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12872'; -- OM連携売上
  cv_cust_cls_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12873'; -- 上様
  cv_cust_cash              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12874'; -- 上様現金
  cv_cust_cash_sale         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12875'; -- 上様現金売上
  cv_pro_bks_id             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12876'; -- 会計帳簿ID
  cv_pro_bks_nm             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12877'; -- 会計帳簿名称
  cv_var_elec_item_cd       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12878'; -- 変動電気料(品目コード)
  cv_pro_company_cd         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12879'; -- 会社コード
  cv_pro_org_cd             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12880'; -- 在庫組織コード
  cv_org_id_get_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12881'; -- 在庫組織ID
  cv_cust_err_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12882'; -- 顧客区分取得エラー
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
  cv_skip_data_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12885'; -- スキップデータ
  cv_prof_bulk_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12886';  -- 結果セット取得件数（バルク）
  cv_prof_journal_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12887';  -- 仕訳バッチ作成件数
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
  cv_sales_exp_h_nomal      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12888';
  cv_sales_exp_h_warn       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12889';
  cv_sales_exp_h_elig       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12890';
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
  cv_acnt_title_err_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12891'; -- 勘定科目取得エラー
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
  -- トークン
  cv_tkn_pro                CONSTANT  VARCHAR2(20) := 'PROFILE';         -- プロファイル
  cv_tkn_tbl                CONSTANT  VARCHAR2(20) := 'TABLE';           -- テーブル名称
  cv_tkn_tbl_nm             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';      -- テーブル名称
  cv_tkn_lookup_type        CONSTANT  VARCHAR2(20) := 'LOOKUP_TYPE';     -- 参照タイプ
  cv_tkn_lookup_code        CONSTANT  VARCHAR2(20) := 'LOOKUP_CODE';     -- クイックコード
  cv_tkn_lookup_dff3        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE3';      -- 参照タイプのDFF3
  cv_tkn_lookup_dff4        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE4';      -- 参照タイプのDFF4
  cv_tkn_segment1           CONSTANT  VARCHAR2(20) := 'SEGMENT1';        -- 会社コード
  cv_tkn_segment2           CONSTANT  VARCHAR2(20) := 'SEGMENT2';        -- 部門コード
  cv_tkn_segment3           CONSTANT  VARCHAR2(20) := 'SEGMENT3';        -- 勘定科目コード
  cv_tkn_segment4           CONSTANT  VARCHAR2(20) := 'SEGMENT4';        -- 補助科目コード
  cv_tkn_segment5           CONSTANT  VARCHAR2(20) := 'SEGMENT5';        -- 顧客コード
  cv_tkn_segment6           CONSTANT  VARCHAR2(20) := 'SEGMENT6';        -- 企業コード
  cv_tkn_segment7           CONSTANT  VARCHAR2(20) := 'SEGMENT7';        -- 事業区分コード
  cv_tkn_segment8           CONSTANT  VARCHAR2(20) := 'SEGMENT8';        -- 予備
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
  cv_tkn_segment9           CONSTANT  VARCHAR2(20) := 'SEGMENT9';        --
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
  cv_tkn_header_from        CONSTANT  VARCHAR2(20) := 'HEADER_FROM';      -- 販売実績ヘッダID(FROM)
  cv_tkn_header_to          CONSTANT  VARCHAR2(20) := 'HEADER_TO';        -- 販売実績ヘッダID(TO)
  cv_tkn_count              CONSTANT  VARCHAR2(20) := 'HEADER_COUNT';     -- 販売実績ヘッダ件数
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--

  cv_blank                  CONSTANT VARCHAR2(1)   := '';                -- ブランク
  cv_tkn_key_data           CONSTANT VARCHAR2(20)  := 'KEY_DATA';        -- キー項目
--
  -- フラグ・区分定数
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';               -- フラグ値:Y
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';               -- フラグ値:N
  cv_card_class             CONSTANT  VARCHAR2(1)  := '1';               -- カード売り区分：カード= 1
  cv_cash_class             CONSTANT  VARCHAR2(1)  := '0';               -- カード売り区分：現金= 0
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
  cv_w_flag                 CONSTANT  VARCHAR2(1)  := 'W';               -- フラグ値:W(警告)
  cv_s_flag                 CONSTANT  VARCHAR2(1)  := 'S';               -- フラグ値:S(対象外)
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
  cv_dic_return             CONSTANT  VARCHAR2(1)  := '2';               -- 納品伝票区分:返品
  cv_dic_return_correction  CONSTANT  VARCHAR2(1)  := '4';               -- 納品伝票区分:返品訂正
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
  -- クイックコードタイプ
  ct_qct_gyotai_sho         CONSTANT  VARCHAR2(50) := 'XXCOS1_GYOTAI_SHO_MST_013_A03';  -- 業態小分類特定マスタ
  ct_qct_sale_class         CONSTANT  VARCHAR2(50) := 'XXCOS1_SALE_CLASS_MST_013_A03';  -- 売上区分特定マスタ
  ct_qct_dlv_slp_cls        CONSTANT  VARCHAR2(50) := 'XXCOS1_DLV_SLP_CLS_MST_013_A03'; -- 納品伝票区分特定マスタ
  ct_qct_card_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_CARD_SALE_CLASS';         -- カード売区分特定マスタ
  ct_qct_jour_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_JOUR_CLS_MST_013_A03';    -- GL仕訳特定マスタ
  ct_qct_tax_cls            CONSTANT  VARCHAR2(50) := 'XXCOS1_CONSUMPTION_TAX_CLASS';   -- 消費税区分特定マスタ
  ct_cust_cls_cd            CONSTANT  VARCHAR2(50) := 'XXCOS1_CUS_CLASS_MST_013_A03';   -- 顧客区分特定マスタ
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
  ct_qct_acnt_title_cd      CONSTANT  VARCHAR2(50) := 'XXCOS1_ACNT_TITLE_MST_013_A03';  --勘定科目特定マスタ
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
  -- クイックコード
  ct_qcc_code               CONSTANT  VARCHAR2(50) := 'XXCOS_013_A03%';                 -- クイックコード
  ct_attribute_y            CONSTANT  VARCHAR2(1)  := 'Y';                              -- DFF値'Y'
  ct_enabled_yes            CONSTANT  VARCHAR2(1)  := 'Y';                              -- 使用可能フラグ定数:有効
--
  -- 一般会計OIFテーブルに設定する固定値
  ct_status                CONSTANT  VARCHAR2(3)   := 'NEW';                            -- ステータス
  ct_currency_code         CONSTANT  VARCHAR2(3)   := 'JPY';                            -- 通貨コード
  ct_actual_flag           CONSTANT  VARCHAR2(1)   := 'A';                              -- 残高タイプ
  ct_segment5              CONSTANT  VARCHAR2(10)  := '000000000';                      -- 顧客コード(現金・仮受消費税)
  ct_group_id              CONSTANT  NUMBER        := 9000000003;                       -- グループID
  ct_underbar              CONSTANT  VARCHAR2(1)   := '_';                              -- 項目区切り用
  ct_date_format_non_sep   CONSTANT  VARCHAR2(20)  := 'YYYYMMDD';                       -- 日付フォマット
  ct_vd_xiaoka_cd          CONSTANT  VARCHAR2(20)  := '24';                             -- フルVD（消化）
  ct_full_vd_cd            CONSTANT  VARCHAR2(20)  := '25';                             -- フルVD
  ct_round_rule_up         CONSTANT  VARCHAR2(10)  := 'UP';                             -- 切り上げ
  ct_round_rule_down       CONSTANT  VARCHAR2(10)  := 'DOWN';                           -- 切り下げ
  ct_round_rule_nearest    CONSTANT  VARCHAR2(10)  := 'NEAREST';                        -- 四捨五入
  ct_percent               CONSTANT  NUMBER        := 100;                              -- 100
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
  ct_tax_code_null         CONSTANT  VARCHAR2(10)  := '0000';                           -- 税金コード(0000)
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--****************************** 2009/09/14 1.9 Atsushiba     ADD START ******************************--
--
  -- その他
  ct_lang                  CONSTANT  fnd_lookup_values.language%TYPE := USERENV('LANG'); -- 言語コード
  cv_exists_flag           CONSTANT  VARCHAR2(1)   := '1';                               -- EXISTS文表示用 
  cn_bulk_collect_count    NUMBER;                            -- 結果セット取得件数
  cn_journal_batch_count   NUMBER;                            -- 仕訳バッチ作成件数
  cn_commit_exec_flag      NUMBER DEFAULT 0;     -- コミット実行フラグ(0:未実行,1:実行あり)
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
  gn_last_flag             NUMBER DEFAULT 0;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 販売実績ワークテーブル定義
--****************************** 2009/05/12 1.6 T.KItajima MOD START ******************************--
--  TYPE gr_sales_exp_rec IS RECORD(
--      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- 販売実績ヘッダID
--    , dlv_invoice_number        xxcos_sales_exp_headers.dlv_invoice_number%TYPE     -- 納品伝票番号
--    , dlv_invoice_class         xxcos_sales_exp_headers.dlv_invoice_class%TYPE      -- 納品伝票区分
--    , cust_gyotai_sho           xxcos_sales_exp_headers.cust_gyotai_sho%TYPE        -- 業態小分類
--    , delivery_date             xxcos_sales_exp_headers.delivery_date%TYPE          -- 納品日
--    , inspect_date              xxcos_sales_exp_headers.inspect_date%TYPE           -- 検収日
--    , ship_to_customer_code     xxcos_sales_exp_headers.ship_to_customer_code%TYPE  -- 顧客【納品先】
--    , tax_code                  xxcos_sales_exp_headers.tax_code%TYPE               -- 税金コード
--    , tax_rate                  xxcos_sales_exp_headers.tax_rate%TYPE               -- 消費税率
--    , consumption_tax_class     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 消費区分
--    , results_employee_code     xxcos_sales_exp_headers.results_employee_code%TYPE  -- 成績計上者コード
--    , sales_base_code           xxcos_sales_exp_headers.sales_base_code%TYPE        -- 売上拠点コード
--    , card_sale_class           xxcos_sales_exp_headers.card_sale_class%TYPE        -- カード売り区分
--    , sales_class               xxcos_sales_exp_lines.sales_class%TYPE              -- 売上区分
--    , goods_prod_cls            xxcos_good_prod_class_v.goods_prod_class_code%TYPE  -- 品目区分コード（製品・商品）
--    , pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE              -- 本体金額
--    , tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE               -- 消費税金額
--    , cash_and_card             xxcos_sales_exp_lines.cash_and_card%TYPE            -- 現金・カード併用額
--    , customer_cls_code         hz_cust_accounts.customer_class_code%TYPE           -- 顧客区分
--    , gccs_segment3             gl_code_combinations.segment3%TYPE                  -- 売上勘定科目コード
--    , gcct_segment3             gl_code_combinations.segment3%TYPE                  -- 税金勘定科目コード
--    , bill_tax_round            xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE     -- 税金－端数処理
--    , xseh_rowid                ROWID                                               -- ROWID
--  );
--  -- 仕訳パターンワークテーブル定義
--  TYPE gr_jour_cls_rec IS RECORD(
--      dlv_invoice_class         fnd_lookup_values.attribute1%TYPE                   -- 納品伝票区分
--    , card_sale_class           fnd_lookup_values.attribute2%TYPE                   -- カード売り区分
--    , goods_prod_cls            fnd_lookup_values.attribute3%TYPE                   -- 品目区分コード（製品・商品）
--    , segment3                  fnd_lookup_values.attribute4%TYPE                   -- 勘定科目コード
--    , line_type                 fnd_lookup_values.attribute5%TYPE                   -- ラインタイプ
--    , jour_category             fnd_lookup_values.attribute6%TYPE                   -- 仕訳カテゴリ
--    , segment2                  fnd_lookup_values.attribute7%TYPE                   -- 部門コード
--    , jour_pattern              fnd_lookup_values.meaning%TYPE                      -- 仕訳パターン
--    , gl_segment3_nm            fnd_lookup_values.description%TYPE                  -- 勘定科目名
--    , segment4                  fnd_lookup_values.attribute8%TYPE                   -- 補助勘定科目コード
--    , segment5                  fnd_lookup_values.attribute9%TYPE                   -- 顧客コード
--    , segment6                  fnd_lookup_values.attribute10%TYPE                  -- 企業コード
--    , segment7                  fnd_lookup_values.attribute11%TYPE                  -- 予備１
--    , segment8                  fnd_lookup_values.attribute12%TYPE                  -- 予備２
--  );
--
  TYPE gr_sales_exp_rec IS RECORD(
      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- 販売実績ヘッダID
    , dlv_invoice_number        xxcos_sales_exp_headers.dlv_invoice_number%TYPE     -- 納品伝票番号
    , dlv_invoice_class         xxcos_sales_exp_headers.dlv_invoice_class%TYPE      -- 納品伝票区分
    , cust_gyotai_sho           xxcos_sales_exp_headers.cust_gyotai_sho%TYPE        -- 業態小分類
    , delivery_date             xxcos_sales_exp_headers.delivery_date%TYPE          -- 納品日
    , inspect_date              xxcos_sales_exp_headers.inspect_date%TYPE           -- 検収日
    , ship_to_customer_code     xxcos_sales_exp_headers.ship_to_customer_code%TYPE  -- 顧客【納品先】
    , tax_code                  xxcos_sales_exp_headers.tax_code%TYPE               -- 税金コード
    , tax_rate                  xxcos_sales_exp_headers.tax_rate%TYPE               -- 消費税率
    , consumption_tax_class     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 消費区分
    , results_employee_code     xxcos_sales_exp_headers.results_employee_code%TYPE  -- 成績計上者コード
    , sales_base_code           xxcos_sales_exp_headers.sales_base_code%TYPE        -- 売上拠点コード
    , card_sale_class           xxcos_sales_exp_headers.card_sale_class%TYPE        -- カード売り区分
    , sales_class               xxcos_sales_exp_lines.sales_class%TYPE              -- 売上区分
    , pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE              -- 本体金額
    , tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE               -- 消費税金額
    , cash_and_card             xxcos_sales_exp_lines.cash_and_card%TYPE            -- 現金・カード併用額
    , red_black_flag            xxcos_sales_exp_lines.cash_and_card%TYPE            -- 赤黒フラグ
    , customer_cls_code         hz_cust_accounts.customer_class_code%TYPE           -- 顧客区分
    , gcct_segment3             gl_code_combinations.segment3%TYPE                  -- 税金勘定科目コード
    , bill_tax_round            xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE     -- 税金－端数処理
    , xseh_rowid                ROWID                                               -- ROWID
  );
--
  -- 仕訳パターンワークテーブル定義
  TYPE gr_jour_cls_rec IS RECORD(
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
--      red_black_flag            fnd_lookup_values.attribute1%TYPE                   -- 赤黒フラグ
      dlv_invoice_class         fnd_lookup_values.attribute1%TYPE                   -- 納品伝票番号
    , red_black_flag            fnd_lookup_values.attribute12%TYPE                  -- 赤黒フラグ
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
    , card_sale_class           fnd_lookup_values.attribute2%TYPE                   -- カード売り区分
    , segment3                  fnd_lookup_values.attribute3%TYPE                   -- 勘定科目コード
    , line_type                 fnd_lookup_values.attribute4%TYPE                   -- ラインタイプ
    , jour_category             fnd_lookup_values.attribute5%TYPE                   -- 仕訳カテゴリ
    , jour_pattern              fnd_lookup_values.meaning%TYPE                      -- 仕訳パターン
    , gl_segment3_nm            fnd_lookup_values.description%TYPE                  -- 勘定科目名
    , segment4                  fnd_lookup_values.attribute6%TYPE                   -- 補助勘定科目コード
    , segment5                  fnd_lookup_values.attribute7%TYPE                   -- 顧客コード
    , segment6                  fnd_lookup_values.attribute8%TYPE                   -- 企業コード
    , segment7                  fnd_lookup_values.attribute9%TYPE                   -- 予備１
    , segment8                  fnd_lookup_values.attribute10%TYPE                  -- 予備２
    , segment2                  fnd_lookup_values.attribute2%TYPE                   -- 拠点コード
  );
--
--****************************** 2009/05/12 1.6 T.KItajima MOD  END  ******************************--
--
  -- CCIDワークテーブル定義
  TYPE gr_select_ccid IS RECORD(
      code_combination_id       gl_code_combinations.code_combination_id%TYPE       -- CCID
  );
--
  -- ワークテーブル型定義
  TYPE g_sales_exp_ttype  IS TABLE OF gr_sales_exp_rec     INDEX BY BINARY_INTEGER;
  gt_sales_exp_tbl                    g_sales_exp_ttype;                            -- 販売実績データ
  gt_sales_card_tbl                   g_sales_exp_ttype;                            -- 販売実績カードデータ
--
  TYPE g_sales_h_ttype    IS TABLE OF ROWID                INDEX BY BINARY_INTEGER;
  gt_sales_h_tbl                      g_sales_h_ttype;                              -- 販売実績フラグ更新用
  gt_sales_h_tbl2                     g_sales_h_ttype;                              -- 販売実績フラグ更新用
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
  gt_sales_h_tbl_work_w               g_sales_h_ttype;                              -- 販売実績フラグ更新用(警告データワーク)
  gt_sales_h_tbl_w                    g_sales_h_ttype;                              -- 販売実績フラグ更新用(警告データ)
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
  TYPE g_jour_cls_ttype   IS TABLE OF gr_jour_cls_rec      INDEX BY BINARY_INTEGER;
  gt_jour_cls_tbl                     g_jour_cls_ttype;                             -- 仕訳パターン
--
  TYPE g_gl_oif_ttype     IS TABLE OF gl_interface%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_gl_interface_tbl                 g_gl_oif_ttype;                               -- 一般会計OIF
  gt_gl_interface_tbl2                g_gl_oif_ttype;                               -- 一般会計OIF
--
  TYPE g_sel_ccid_ttype   IS TABLE OF gr_select_ccid       INDEX BY VARCHAR2( 200 );
  gt_sel_ccid_tbl                     g_sel_ccid_ttype;                             -- CCID
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
--
  gt_sales_exp_wk_tbl                 g_sales_exp_ttype;                            -- 販売実績データ(作業用)
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
  gt_sales_exp_evacu_tbl              g_sales_exp_ttype;                            -- 販売実績データ(退避用)
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
  --
  TYPE g_sales_header_ttype IS TABLE OF NUMBER INDEX BY VARCHAR(100);
  gt_sales_header_tbl                 g_sales_header_ttype;
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --初期取得
  gd_process_date                     DATE;                                         -- 業務日付
  gv_company_code                     VARCHAR2(30);                                 -- 会社コード
  gv_set_bks_id                       VARCHAR2(30);                                 -- 会計帳簿ID
  gv_set_bks_nm                       VARCHAR2(30);                                 -- 会計帳簿名称
  gv_org_cd                           VARCHAR2(30);                                 -- 在庫組織コード
  gv_org_id                           VARCHAR2(30);                                 -- 在庫組織ID
  gv_var_elec_item_cd                 VARCHAR2(30);                                 -- 変動電気料(品目コード)
  gt_cust_cls_cd                      hz_cust_accounts.customer_class_code%TYPE;    -- 顧客区分（上様）
  gt_card_sale_cls                    fnd_lookup_values.lookup_code%TYPE;           -- カード売り区分
  gt_no_tax_cls                       fnd_lookup_values.attribute3%TYPE;            -- 消費区分
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
  gt_segment3_cash                    fnd_lookup_values.attribute4%TYPE;            --勘定科目(現金)
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
--
  CURSOR sales_data_cur
  IS
    SELECT
          /*+ LEADING(xseh)
              INDEX(xseh xxcos_sales_exp_headers_n05 )
              USE_NL(xseh xsel msib )
              USE_NL(xseh hca avta gcct )
              USE_NL(xseh xchv)
              INDEX(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u2)
              INDEX(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u2)
              INDEX(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u2)
              INDEX(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u2)
           */
           xseh.sales_exp_header_id          sales_exp_header_id      -- 販売実績ヘッダID
         , xseh.dlv_invoice_number           dlv_invoice_number       -- 納品伝票番号
         , xseh.dlv_invoice_class            dlv_invoice_class        -- 納品伝票区分
         , xseh.cust_gyotai_sho              cust_gyotai_sho          -- 業態小分類
         , xseh.delivery_date                delivery_date            -- 納品日
         , xseh.inspect_date                 inspect_date             -- 検収日
         , xseh.ship_to_customer_code        ship_to_customer_code    -- 顧客【納品先】
         , xseh.tax_code                     tax_code                 -- 税金コード
         , xseh.tax_rate                     tax_rate                 -- 消費税率
         , xseh.consumption_tax_class        consumption_tax_class    -- 消費区分
         , xseh.results_employee_code        results_employee_code    -- 成績計上者コード
         , xseh.sales_base_code              sales_base_code          -- 売上拠点コード
         , NVL( xseh.card_sale_class, cv_cash_class )
                                             card_sale_class          -- カード売り区分
         , xsel.sales_class                  sales_class              -- 売上区分
         , xsel.pure_amount                  pure_amount              -- 本体金額
         , xsel.tax_amount                   tax_amount               -- 消費税金額
         , NVL( xsel.cash_and_card, 0 )      cash_and_card            -- 現金・カード併用額
         , xsel.red_black_flag               red_black_flag           -- 赤黒フラグ
         , hca.customer_class_code           customer_cls_code        -- 顧客区分
         , gcct.segment3                     gcct_segment3            -- 税金勘定科目コード
         , xchv.bill_tax_round_rule          tax_round_rule           -- 税金－端数処理
         , xseh.rowid                        xseh_rowid               -- ROWID
    FROM
           xxcos_sales_exp_headers           xseh                     -- 販売実績ヘッダテーブル
         , xxcos_sales_exp_lines             xsel                     -- 販売実績明細テーブル
         , mtl_system_items_b                msib                     -- 品目マスタ
         , gl_code_combinations              gcct                     -- 勘定科目組合せマスタ（TAX用）
         , ar_vat_tax_all_b                  avta                     -- 税金マスタ
         , hz_cust_accounts                  hca                      -- 顧客区分
         , xxcos_cust_hierarchy_v            xchv                     -- 顧客階層ビュー
    WHERE
        xseh.sales_exp_header_id             = xsel.sales_exp_header_id
    AND xseh.dlv_invoice_number              = xsel.dlv_invoice_number
-- ***************** 2009/10/07 1.10 N.Maeda MOD START ***************** --
--    AND xseh.gl_interface_flag               = cv_n_flag
    AND ( xseh.gl_interface_flag             = cv_n_flag
          OR xseh.gl_interface_flag          = cv_w_flag )
-- ***************** 2009/10/07 1.10 N.Maeda MOD  END  ***************** --
    AND xseh.inspect_date                   <= gd_process_date
    AND xsel.item_code                      <> gv_var_elec_item_cd
    AND hca.account_number                   = xseh.ship_to_customer_code
    AND xchv.ship_account_number             = xseh.ship_to_customer_code
    AND ( EXISTS (
          SELECT /*+ USE_NL(flvl1) */
              cv_exists_flag                 exists_flag
          FROM
              fnd_lookup_values              flvl1
          WHERE
              flvl1.lookup_type              = ct_qct_gyotai_sho
          AND flvl1.lookup_code              LIKE ct_qcc_code
          AND flvl1.meaning                  = xseh.cust_gyotai_sho
          AND flvl1.attribute1               = ct_attribute_y
          AND flvl1.enabled_flag             = ct_enabled_yes
          AND flvl1.language                 = ct_lang
          AND gd_process_date BETWEEN        NVL( flvl1.start_date_active, gd_process_date )
                              AND            NVL( flvl1.end_date_active,   gd_process_date )
          )
          OR hca.customer_class_code          = gt_cust_cls_cd
        )
    AND NOT EXISTS (
        SELECT /*+ USE_NL(flvl2) */
            cv_exists_flag                   exists_flag
        FROM
            fnd_lookup_values                flvl2
        WHERE
            flvl2.lookup_type                = ct_qct_sale_class
        AND flvl2.lookup_code                LIKE ct_qcc_code
        AND flvl2.meaning                    = xsel.sales_class
        AND flvl2.attribute1                 = ct_attribute_y
        AND flvl2.enabled_flag               = ct_enabled_yes
        AND flvl2.language                   = ct_lang
        AND gd_process_date BETWEEN          NVL( flvl2.start_date_active, gd_process_date )
                            AND              NVL( flvl2.end_date_active,   gd_process_date )
        )
    AND EXISTS (
        SELECT /*+ USE_NL(flvl3) */
            cv_exists_flag                   exists_flag
        FROM
            fnd_lookup_values                flvl3
        WHERE
            flvl3.lookup_type                = ct_qct_dlv_slp_cls
        AND flvl3.lookup_code                LIKE ct_qcc_code
        AND flvl3.meaning                    = xseh.dlv_invoice_class
--******************************* 2009/11/17 1.11 M.Sano DEL START *******************************--
--        AND flvl3.attribute1                 = ct_attribute_y
--******************************* 2009/11/17 1.11 M.Sano DEL END   *******************************--
        AND flvl3.enabled_flag               = ct_enabled_yes
        AND flvl3.language                   = ct_lang
        AND gd_process_date BETWEEN          NVL( flvl3.start_date_active, gd_process_date )
                            AND              NVL( flvl3.end_date_active,   gd_process_date )
        )
    AND msib.organization_id                 = gv_org_id
    AND xsel.item_code                       = msib.segment1
    AND avta.tax_code                        = xseh.tax_code
    AND gcct.code_combination_id             = avta.tax_account_id
    AND avta.set_of_books_id                 = TO_NUMBER( gv_set_bks_id )
    AND avta.enabled_flag                    = ct_enabled_yes
    ORDER BY xseh.sales_exp_header_id;
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
--
  /**********************************************************************************
   * Procedure Name   : roundup
   * Description      : 切上関数
   ***********************************************************************************/
  FUNCTION roundup(in_number IN NUMBER, in_place IN INTEGER := 0)
  RETURN NUMBER
  IS
    ln_base NUMBER;
  BEGIN
    IF (in_number = 0) 
      OR (in_number IS NULL) 
    THEN
      RETURN 0;
    END IF;
--
    ln_base := 10 ** in_place ;
    RETURN CEIL( ABS( in_number ) * ln_base ) / ln_base * SIGN( in_number );
  END;
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'init';             -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);               -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                  -- リターン・コード
    lv_errmsg  VARCHAR2(5000);               -- ユーザー・エラー・メッセージ
--
--#####################  固定ローカル変数宣言部 END     ########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    ct_pro_bks_id            CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';
                                                                      -- 会計帳簿ID
    ct_pro_bks_nm            CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_NAME';
                                                                      -- 会計帳簿名称
    ct_pro_org_cd            CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
                                                                      -- XXCOI:在庫組織コード
    ct_pro_company_cd        CONSTANT VARCHAR2(30) := 'XXCOI1_COMPANY_CODE';
                                                                      -- XXCOI:会社コード
    ct_var_elec_item_cd      CONSTANT VARCHAR2(30) := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
                                                                      -- XXCOS:変動電気料(品目コード)
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
-- ***************** 2009/10/07 1.10 N.Maeda MOD START ***************** --
--    ct_bulk_collect_count    CONSTANT VARCHAR2(30) := 'XXCOS1_BULK_COLLECT_COUNT';  -- 結果セット取得件数（バルク）
    ct_bulk_collect_count    CONSTANT VARCHAR2(30) := 'XXCOS1_GL_BULK_COLLECT_COUNT';  -- 結果セット取得件数（バルク）
-- ***************** 2009/10/07 1.10 N.Maeda MOD  END  ***************** --
    ct_journal_batch_count   CONSTANT VARCHAR2(30) := 'XXCOS1_JOURNAL_BATCH_COUNT'; -- 仕訳バッチ作成件数
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
--
    -- *** ローカル変数 ***
    lv_profile_name          VARCHAR2(50);                           -- プロファイル名
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
    lv_tmp                   VARCHAR2(100);
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
--
    -- *** ローカル例外 ***
    non_lookup_value_expt    EXCEPTION;                               -- LOOKUP取得エラー
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--##################  固定ステータス初期化部 END     ###################
--
    --==============================================================
    -- コンカレント入力パラメータなしメッセージ出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_xxccp_short_nm
                    , iv_name        => cv_no_para_msg
                  );
--
    -- メッセージ出力
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
    --===================================================
    -- コンカレント入力パラメータなしログ出力
    --===================================================
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_blank
    );
--
    -- メッセージ出力
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
    -- 業務日付取得
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務日付取得エラーの場合
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcos_short_nm, cv_process_date_msg );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得：会計帳簿ID
    -- ===============================
    gv_set_bks_id := FND_PROFILE.VALUE( ct_pro_bks_id );
    -- プロファイルが取得できない場合
    IF ( gv_set_bks_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm               -- アプリケーション短縮名
        ,iv_name        => cv_pro_bks_id                   -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得：会計帳簿名称
    -- ===============================
    gv_set_bks_nm := FND_PROFILE.VALUE( ct_pro_bks_nm );
    -- プロファイルが取得できない場合
    IF ( gv_set_bks_nm IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm               -- アプリケーション短縮名
        ,iv_name        => cv_pro_bks_nm                   -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得：在庫組織コード
    -- ===============================
    gv_org_cd := FND_PROFILE.VALUE( ct_pro_org_cd );
    -- プロファイルが取得できない場合
    IF ( gv_org_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm               -- アプリケーション短縮名
        ,iv_name        => cv_pro_org_cd                   -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 在庫組織ID取得
    -- ===============================
    gv_org_id := xxcoi_common_pkg.get_organization_id( gv_org_cd );
    -- 在庫組織ID取得できない場合はエラー
    IF ( gv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_nm
                     , iv_name        => cv_org_id_get_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -----------------------------------------------------------------------
--
    --==================================
    -- XXCOI:会社コード
    --==================================
    gv_company_code := FND_PROFILE.VALUE( ct_pro_company_cd );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_company_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm               -- アプリケーション短縮名
        ,iv_name        => cv_pro_company_cd               -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:変動電気料(品目コード)取得
    --==================================
    gv_var_elec_item_cd := FND_PROFILE.VALUE( ct_var_elec_item_cd );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_var_elec_item_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm               -- アプリケーション短縮名
        ,iv_name        => cv_var_elec_item_cd             -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 5.クイックコード取得
    --==================================
    -- カード売り区分=現金:0
    BEGIN
      SELECT flvl.lookup_code
      INTO   gt_card_sale_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = ct_qct_card_cls
        AND  flvl.attribute3             = ct_attribute_y
        AND  flvl.enabled_flag           = ct_enabled_yes
--****************************** 2009/09/14 1.9 Atsushiba     MOD START ******************************--
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
--****************************** 2009/09/14 1.9 Atsushiba     MOD END   ******************************--
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_short_nm
                       , iv_name          => cv_card_sale_cls_msg
                       , iv_token_name1   => cv_tkn_lookup_type
                       , iv_token_value1  => ct_qct_card_cls
                       , iv_token_name2   => cv_tkn_lookup_dff3
                       , iv_token_value2  => ct_attribute_y
                     );
        lv_errbuf := lv_errmsg;
        RAISE non_lookup_value_expt;
    END;
--
    -- 消費税区分=非課税:4
    BEGIN
      SELECT flvl.attribute3
      INTO   gt_no_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = ct_qct_tax_cls
        AND  flvl.attribute4             = ct_attribute_y
        AND  flvl.enabled_flag           = ct_enabled_yes
--****************************** 2009/09/14 1.9 Atsushiba     MOD START ******************************--
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
--****************************** 2009/09/14 1.9 Atsushiba     MOD END   ******************************--
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_tax_cls_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => ct_qct_tax_cls
                      , iv_token_name2   => cv_tkn_lookup_dff4
                      , iv_token_value2  => ct_attribute_y
                     );
        lv_errbuf := lv_errmsg;
        RAISE non_lookup_value_expt;
    END;
--
    -- 顧客区分=上様:12
    BEGIN
      SELECT flvl.meaning
      INTO   gt_cust_cls_cd
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = ct_cust_cls_cd
        AND  flvl.lookup_code            LIKE ct_qcc_code
        AND  flvl.enabled_flag           = ct_enabled_yes
--****************************** 2009/09/14 1.9 Atsushiba     MOD START ******************************--
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
--****************************** 2009/09/14 1.9 Atsushiba     MOD END   ******************************--
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_cust_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => ct_cust_cls_cd
                     );
        lv_errbuf := lv_errmsg;
        RAISE non_lookup_value_expt;
    END;
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
--
    --==================================
    -- XXCOI:結果セット取得件数
    --==================================
    lv_tmp := FND_PROFILE.VALUE( ct_bulk_collect_count );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_tmp IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm               -- アプリケーション短縮名
        ,iv_name        => cv_prof_bulk_msg                -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    cn_bulk_collect_count := TO_NUMBER(lv_tmp);
--
    --==================================
    -- XXCOI:仕訳バッチ作成件数
    --==================================
    lv_tmp := FND_PROFILE.VALUE( ct_journal_batch_count );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_tmp IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm               -- アプリケーション短縮名
        ,iv_name        => cv_prof_journal_msg               -- メッセージID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    cn_journal_batch_count := TO_NUMBER(lv_tmp);
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
--
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
    -- 勘定科目=現金
    BEGIN
      SELECT flvl.meaning
      INTO   gt_segment3_cash
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = ct_qct_acnt_title_cd
        AND  flvl.lookup_code            LIKE ct_qcc_code
        AND  flvl.enabled_flag           = ct_enabled_yes
        AND  flvl.language               = ct_lang
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- クイックコード取得出来ない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_acnt_title_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => ct_qct_acnt_title_cd
                     );
        lv_errbuf := lv_errmsg;
        RAISE non_lookup_value_expt;
    END;
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
  EXCEPTION
--
-- クイックコード取得エラー
    WHEN non_lookup_value_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
--##################################  固定例外処理部部 END ####################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
      ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_table_name VARCHAR2(255);            -- テーブル名
--
    -- *** ローカル・カーソル (販売実績データ抽出)***
--****************************** 2009/05/13 1.6 MOD START ******************************--
--    CURSOR sales_data_cur
--    IS
--      SELECT
--             xseh.sales_exp_header_id          sales_exp_header_id      -- 販売実績ヘッダID
--           , xseh.dlv_invoice_number           dlv_invoice_number       -- 納品伝票番号
--           , xseh.dlv_invoice_class            dlv_invoice_class        -- 納品伝票区分
--           , xseh.cust_gyotai_sho              cust_gyotai_sho          -- 業態小分類
--           , xseh.delivery_date                delivery_date            -- 納品日
--           , xseh.inspect_date                 inspect_date             -- 検収日
--           , xseh.ship_to_customer_code        ship_to_customer_code    -- 顧客【納品先】
--           , xseh.tax_code                     tax_code                 -- 税金コード
--           , xseh.tax_rate                     tax_rate                 -- 消費税率
--           , xseh.consumption_tax_class        consumption_tax_class    -- 消費区分
--           , xseh.results_employee_code        results_employee_code    -- 成績計上者コード
--           , xseh.sales_base_code              sales_base_code          -- 売上拠点コード
--           , NVL( xseh.card_sale_class, cv_cash_class )
--                                               card_sale_class          -- カード売り区分
--           , xsel.sales_class                  sales_class              -- 売上区分
--           , xgpc.goods_prod_class_code        goods_prod_cls           -- 品目区分コード（製品・商品）
--           , xsel.pure_amount                  pure_amount              -- 本体金額
--           , xsel.tax_amount                   tax_amount               -- 消費税金額
--           , NVL( xsel.cash_and_card, 0 )      cash_and_card            -- 現金・カード併用額
--           , hca.customer_class_code           customer_cls_code        -- 顧客区分
--           , gcc.segment3                      gccs_segment3            -- 売上勘定科目コード
--           , gcct.segment3                     gcct_segment3            -- 税金勘定科目コード
--           , xchv.bill_tax_round_rule          tax_round_rule           -- 税金－端数処理
--           , xseh.rowid                        xseh_rowid               -- ROWID
--      FROM
--             xxcos_sales_exp_headers           xseh                     -- 販売実績ヘッダテーブル
--           , xxcos_sales_exp_lines             xsel                     -- 販売実績明細テーブル
--           , mtl_system_items_b                msib                     -- 品目マスタ
--           , gl_code_combinations              gcc                      -- 勘定科目組合せマスタ
--           , gl_code_combinations              gcct                     -- 勘定科目組合せマスタ（TAX用）
--           , ar_vat_tax_all_b                  avta                     -- 税金マスタ
--           , xxcos_good_prod_class_v           xgpc                     -- 品目区分View
--           , hz_cust_accounts                  hca                      -- 顧客区分
--           , xxcos_cust_hierarchy_v            xchv                     -- 顧客階層ビュー
--      WHERE
--          xseh.sales_exp_header_id             = xsel.sales_exp_header_id
--      AND xseh.dlv_invoice_number              = xsel.dlv_invoice_number
--      AND xseh.gl_interface_flag               = cv_n_flag
--      AND xseh.inspect_date                   <= gd_process_date
--      AND xsel.item_code                      <> gv_var_elec_item_cd
--      AND hca.account_number                   = xseh.ship_to_customer_code
--      AND xchv.ship_account_number             = xseh.ship_to_customer_code
--      AND ( xseh.cust_gyotai_sho                 IN (
--            SELECT
--                flvl.meaning                   meaning
--            FROM
--                fnd_lookup_values              flvl
--            WHERE
--                flvl.lookup_type               = ct_qct_gyotai_sho
--            AND flvl.lookup_code               LIKE ct_qcc_code
--            AND flvl.attribute1                = ct_attribute_y
--            AND flvl.enabled_flag              = ct_enabled_yes
--            AND flvl.language                  = USERENV( 'LANG' )
--            AND gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
--                                AND            NVL( flvl.end_date_active,   gd_process_date )
--            )
--            OR hca.customer_class_code          = gt_cust_cls_cd
--          )
--      AND xsel.sales_class                     NOT IN (
--          SELECT
--              flvl.meaning                     meaning
--          FROM
--              fnd_lookup_values                flvl
--          WHERE
--              flvl.lookup_type                 = ct_qct_sale_class
--          AND flvl.lookup_code                 LIKE ct_qcc_code
--          AND flvl.attribute1                  = ct_attribute_y
--          AND flvl.enabled_flag                = ct_enabled_yes
--          AND flvl.language                    = USERENV( 'LANG' )
--          AND gd_process_date BETWEEN          NVL( flvl.start_date_active, gd_process_date )
--                              AND              NVL( flvl.end_date_active,   gd_process_date )
--          )
--      AND xseh.dlv_invoice_class               IN (
--          SELECT
--              flvl.meaning                     meaning
--          FROM
--              fnd_lookup_values                flvl
--          WHERE
--              flvl.lookup_type                 = ct_qct_dlv_slp_cls
--          AND flvl.lookup_code                 LIKE ct_qcc_code
--          AND flvl.attribute1                  = ct_attribute_y
--          AND flvl.enabled_flag                = ct_enabled_yes
--          AND flvl.language                    = USERENV( 'LANG' )
--          AND gd_process_date BETWEEN          NVL( flvl.start_date_active, gd_process_date )
--                              AND              NVL( flvl.end_date_active,   gd_process_date )
--          )
--      AND msib.organization_id                 = gv_org_id
--      AND xsel.item_code                       = msib.segment1
--      AND avta.tax_code                        = xseh.tax_code
--      AND gcct.code_combination_id             = avta.tax_account_id
--      AND avta.set_of_books_id                 = TO_NUMBER( gv_set_bks_id )
--      AND avta.enabled_flag                    = ct_enabled_yes
--      AND gd_process_date BETWEEN              NVL( avta.start_date, gd_process_date )
--                          AND                  NVL( avta.end_date,   gd_process_date )
--      AND gcc.code_combination_id              = msib.sales_account
--      AND xgpc.segment1                        = xsel.item_code
--      ORDER BY xseh.dlv_invoice_number
--             , xseh.dlv_invoice_class
--             , NVL( xseh.card_sale_class, cv_cash_class )
--             , xsel.item_code
--             , gcc.segment3
--             , xseh.tax_code
--    FOR UPDATE OF  xseh.sales_exp_header_id
--    NOWAIT;
--
--****************************** 2009/09/14 1.9 Atsushiba  Del START ******************************--
--    CURSOR sales_data_cur
--    IS
--      SELECT
--            /*+ LEADING(xseh)
--                INDEX(xseh xxcos_sales_exp_headers_n05 )
--                USE_NL(xseh xsel msib )
--                USE_NL(xseh hca avta gcct )
--                USE_NL(xseh xchv)
--             */
--             xseh.sales_exp_header_id          sales_exp_header_id      -- 販売実績ヘッダID
--           , xseh.dlv_invoice_number           dlv_invoice_number       -- 納品伝票番号
--           , xseh.dlv_invoice_class            dlv_invoice_class        -- 納品伝票区分
--           , xseh.cust_gyotai_sho              cust_gyotai_sho          -- 業態小分類
--           , xseh.delivery_date                delivery_date            -- 納品日
--           , xseh.inspect_date                 inspect_date             -- 検収日
--           , xseh.ship_to_customer_code        ship_to_customer_code    -- 顧客【納品先】
--           , xseh.tax_code                     tax_code                 -- 税金コード
--           , xseh.tax_rate                     tax_rate                 -- 消費税率
--           , xseh.consumption_tax_class        consumption_tax_class    -- 消費区分
--           , xseh.results_employee_code        results_employee_code    -- 成績計上者コード
--           , xseh.sales_base_code              sales_base_code          -- 売上拠点コード
--           , NVL( xseh.card_sale_class, cv_cash_class )
--                                               card_sale_class          -- カード売り区分
--           , xsel.sales_class                  sales_class              -- 売上区分
--           , xsel.pure_amount                  pure_amount              -- 本体金額
--           , xsel.tax_amount                   tax_amount               -- 消費税金額
--           , NVL( xsel.cash_and_card, 0 )      cash_and_card            -- 現金・カード併用額
--           , xsel.red_black_flag               red_black_flag           -- 赤黒フラグ
--           , hca.customer_class_code           customer_cls_code        -- 顧客区分
--           , gcct.segment3                     gcct_segment3            -- 税金勘定科目コード
--           , xchv.bill_tax_round_rule          tax_round_rule           -- 税金－端数処理
--           , xseh.rowid                        xseh_rowid               -- ROWID
--      FROM
--             xxcos_sales_exp_headers           xseh                     -- 販売実績ヘッダテーブル
--           , xxcos_sales_exp_lines             xsel                     -- 販売実績明細テーブル
--           , mtl_system_items_b                msib                     -- 品目マスタ
--           , gl_code_combinations              gcct                     -- 勘定科目組合せマスタ（TAX用）
--           , ar_vat_tax_all_b                  avta                     -- 税金マスタ
--           , hz_cust_accounts                  hca                      -- 顧客区分
--           , xxcos_cust_hierarchy_v            xchv                     -- 顧客階層ビュー
--      WHERE
--          xseh.sales_exp_header_id             = xsel.sales_exp_header_id
--      AND xseh.dlv_invoice_number              = xsel.dlv_invoice_number
--      AND xseh.gl_interface_flag               = cv_n_flag
--      AND xseh.inspect_date                   <= gd_process_date
--      AND xsel.item_code                      <> gv_var_elec_item_cd
--      AND hca.account_number                   = xseh.ship_to_customer_code
--      AND xchv.ship_account_number             = xseh.ship_to_customer_code
--      AND ( xseh.cust_gyotai_sho                 IN (
--            SELECT
--                flvl.meaning                   meaning
--            FROM
--                fnd_lookup_values              flvl
--            WHERE
--                flvl.lookup_type               = ct_qct_gyotai_sho
--            AND flvl.lookup_code               LIKE ct_qcc_code
--            AND flvl.attribute1                = ct_attribute_y
--            AND flvl.enabled_flag              = ct_enabled_yes
--            AND flvl.language                  = USERENV( 'LANG' )
--            AND gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
--                                AND            NVL( flvl.end_date_active,   gd_process_date )
--            )
--            OR hca.customer_class_code          = gt_cust_cls_cd
--          )
--      AND xsel.sales_class                     NOT IN (
--          SELECT
--              flvl.meaning                     meaning
--          FROM
--              fnd_lookup_values                flvl
--          WHERE
--              flvl.lookup_type                 = ct_qct_sale_class
--          AND flvl.lookup_code                 LIKE ct_qcc_code
--          AND flvl.attribute1                  = ct_attribute_y
--          AND flvl.enabled_flag                = ct_enabled_yes
--          AND flvl.language                    = USERENV( 'LANG' )
--          AND gd_process_date BETWEEN          NVL( flvl.start_date_active, gd_process_date )
--                              AND              NVL( flvl.end_date_active,   gd_process_date )
--          )
--      AND xseh.dlv_invoice_class               IN (
--          SELECT
--              flvl.meaning                     meaning
--          FROM
--              fnd_lookup_values                flvl
--          WHERE
--              flvl.lookup_type                 = ct_qct_dlv_slp_cls
--          AND flvl.lookup_code                 LIKE ct_qcc_code
--          AND flvl.attribute1                  = ct_attribute_y
--          AND flvl.enabled_flag                = ct_enabled_yes
--          AND flvl.language                    = USERENV( 'LANG' )
--          AND gd_process_date BETWEEN          NVL( flvl.start_date_active, gd_process_date )
--                              AND              NVL( flvl.end_date_active,   gd_process_date )
--          )
--      AND msib.organization_id                 = gv_org_id
--      AND xsel.item_code                       = msib.segment1
--      AND avta.tax_code                        = xseh.tax_code
--      AND gcct.code_combination_id             = avta.tax_account_id
--      AND avta.set_of_books_id                 = TO_NUMBER( gv_set_bks_id )
--      AND avta.enabled_flag                    = ct_enabled_yes
--      ORDER BY xseh.sales_exp_header_id
--    FOR UPDATE OF  xseh.sales_exp_header_id
--    NOWAIT;
----****************************** 2009/05/13 1.6 MOD  END  ******************************--
--****************************** 2009/09/14 1.9 Atsushiba  DEL END ******************************--
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- カーソルオープン
    OPEN  sales_data_cur;
--****************************** 2009/09/14 1.9 Atsushiba  DEL START ******************************--
--    FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_tbl;
----
--    -- 対象処理件数
--    gn_target_cnt   := gt_sales_exp_tbl.COUNT;
----
--    -- カーソルクローズ
--    CLOSE sales_data_cur;
--****************************** 2009/09/14 1.9 Atsushiba  DEL END ******************************--
--
  EXCEPTION
--****************************** 2009/09/14 1.9 Atsushiba  DEL START ******************************--
--    -- ロックエラー
--    WHEN lock_expt THEN
----      lv_table_name := xxccp_common_pkg.get_msg(
--                           iv_application => cv_xxcos_short_nm               -- アプリケーション短縮名
--                         , iv_name        => cv_tkn_sales_msg                -- メッセージID
--                       );
--      lv_errmsg     := xxccp_common_pkg.get_msg(
--                           iv_application   => cv_xxcos_short_nm
--                         , iv_name          => cv_table_lock_msg
--                         , iv_token_name1   => cv_tkn_tbl
--                         , iv_token_value1  => lv_table_name
--                       );
--      lv_errbuf     := lv_errmsg;
--      ov_errmsg     := lv_errmsg;
--      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode    := cv_status_error;
--****************************** 2009/09/14 1.9 Atsushiba  DEL END ******************************--
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_nm
                      , iv_name         => cv_data_get_msg
                    );
      lv_errbuf  := lv_errmsg;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_gl_data
   * Description      : 一般会計OIF仕訳作成(A-4)
   ***********************************************************************************/
  PROCEDURE edit_gl_data(
      ov_errbuf         OUT VARCHAR2         -- エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2         -- リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
    , in_gl_idx         IN  NUMBER           -- GL OIF データインデックス
    , in_sale_idx       IN  NUMBER           -- 販売実績データインデックス
    , iv_card_flg       IN  VARCHAR2         -- 仕訳フラグ
    , in_card_idx       IN  NUMBER           -- カードデータインデックス
    , in_jcls_idx       IN  NUMBER           -- 仕訳パターンインデックス
    , iv_gl_segment3    IN  VARCHAR2         -- 勘定科目コード
    , in_entered_dr     IN  NUMBER           -- 借方金額
    , in_entered_cr     IN  NUMBER           -- 貸方金額
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_gl_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);               -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                  -- リターン・コード
    lv_errmsg  VARCHAR2(5000);               -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_user_je_source_name  VARCHAR2(225);    -- 販売実績(仕訳ソース名)
    lv_ccid_idx             VARCHAR2(225);    -- セグメント１0８の結合（CCIDインデックス用）
    lv_tbl_nm               VARCHAR2(225);    -- 勘定科目組合せマスタテーブル
    lv_vd_nm                VARCHAR2(225);    -- 仕訳名
    lv_detail               VARCHAR2(225);    -- 明細摘要
    lv_om_sales             VARCHAR2(225);    -- OM連携売上
--****************************** 209/05/13 1.6 T.Kitajima ADD START ******************************--
    lv_section_code         VARCHAR2(225);    -- 部門コード
    lv_category_name        VARCHAR2(225);    -- 仕訳カテゴリ名
--****************************** 209/05/13 1.6 T.Kitajima ADD  END  ******************************--
--
    -- *** ローカル例外 ***
    non_ccid_expt           EXCEPTION;        -- CCID取得出来ないエラー
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_ccid                 gl_code_combinations.code_combination_id%TYPE;
                                              -- CCID
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --  一般会計OIF仕訳作成(A-4)
    --==============================================================
--
    -- 文字列取得
    -- １．仕訳ソース名
    lv_user_je_source_name := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                , iv_name              => cv_source_nm_msg        -- メッセージID
                              );
--
    -- ２．OM連携売上
    lv_om_sales            := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                , iv_name              => cv_om_sales             -- メッセージID
                              );
--
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    -- ３．上様の場合、仕訳名、明細摘要取得
--    IF ( iv_card_flg = cv_y_flag ) THEN
--      -- 生成したカードレコードの場合
--      IF ( gt_sales_card_tbl ( in_card_idx ).customer_cls_code = gt_cust_cls_cd ) THEN
--        -- 仕訳名:上様現金売上
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                  , iv_name              => cv_cust_cash_sale       -- メッセージID
--                                );
--        -- 明細摘要：上様現金
--        lv_detail            := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                  , iv_name              => cv_cust_cash            -- メッセージID
--                                );
--      END IF;
----
--      -- ４．フルVD（消化）売上の場合、仕訳名、明細摘要取得
--      IF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho = ct_full_vd_cd ) THEN
--        -- フルVD
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                  , iv_name              => cv_full_vd              -- メッセージID
--                                );
--        -- フルVDカード
--        lv_detail          := xxccp_common_pkg.get_msg(
--                                  iv_application       => cv_xxcos_short_nm          -- アプリケーション短縮名
--                                , iv_name              => cv_full_vd_card            -- メッセージID
--                              );
--      ELSIF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho = ct_vd_xiaoka_cd ) THEN
--        -- フルVD（消化）売上
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                  , iv_name              => cv_vd_xiaoka            -- メッセージID
--                                );
--        -- フルVD（消化）カード
--        lv_detail          := xxccp_common_pkg.get_msg(
--                                  iv_application       => cv_xxcos_short_nm         -- アプリケーション短縮名
--                                , iv_name              => cv_vd_xiaoka_card         -- メッセージID
--                            );
--      END IF;
--    ELSE
--      IF ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd ) THEN
--        -- 仕訳名:上様現金売上
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                  , iv_name              => cv_cust_cash_sale       -- メッセージID
--                                );
--        -- 明細摘要：上様現金
--        lv_detail            := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                  , iv_name              => cv_cust_cash            -- メッセージID
--                                );
--      END IF;
----
--      -- ４．フルVD（消化）売上の場合、仕訳名、明細摘要取得
--      IF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho = ct_full_vd_cd ) THEN
--        -- フルVD
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                  , iv_name              => cv_full_vd              -- メッセージID
--                                );
--        IF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_card_class ) THEN
--        -- カード売上の場合：フルVDカード
--        lv_detail          := xxccp_common_pkg.get_msg(
--                                  iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                , iv_name              => cv_full_vd_card         -- メッセージID
--                              );
--        ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_cash_class ) THEN
--          -- 現金売上の場合：フルVD現金
--          lv_detail          := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                  , iv_name              => cv_full_vd_cash         -- メッセージID
--                              );
--        END IF;
--      ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho = ct_vd_xiaoka_cd ) THEN
--        -- フルVD（消化）売上
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                  , iv_name              => cv_vd_xiaoka            -- メッセージID
--                                );
--        IF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_card_class ) THEN
--          -- カード売上の場合：フルVD（消化）カード
--          lv_detail          := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                  , iv_name              => cv_vd_xiaoka_card       -- メッセージID
--                              );
--        ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_cash_class ) THEN
--          -- 現金売上の場合：フルVD（消化）現金
--            lv_detail          := xxccp_common_pkg.get_msg(
--                                      iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
--                                    , iv_name              => cv_vd_xiaoka_cash       -- メッセージID
--                                );
--        END IF;
--      END IF;
--    END IF;
--
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--    --仕訳カテゴリ名
--    --上様顧客 AND 本体仕訳 AND フルVD以外 AND フルVD（消化）以外 AND 現金
--    IF ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
    --仕訳カテゴリ名
    --納品伝票区分：返品 or 返品訂正
    IF ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return            ) OR
       ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return_correction )
    THEN
      lv_category_name  := xxccp_common_pkg.get_msg(
                              iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                            , iv_name              => cv_cust_cash_sale       -- メッセージID
                           );
    --上様顧客 AND 本体仕訳 AND フルVD以外 AND フルVD（消化）以外 AND 現金
    ELSIF
       ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
--******************************* 2009/11/17 1.11 M.Sano MOD  END  *******************************--
       ( iv_card_flg                                        = cv_n_flag       ) AND
       ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_full_vd_cd   ) AND
       ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_vd_xiaoka_cd ) AND
       ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class   = cv_cash_class   )
    THEN
        -- 仕訳名:上様現金売上
      lv_category_name  := xxccp_common_pkg.get_msg(
                              iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                            , iv_name              => cv_cust_cash_sale       -- メッセージID
                           );
    --併用カード、カード、フルVD、フルVD（消化）はこちら
    ELSE
      lv_category_name  := gt_jour_cls_tbl( in_jcls_idx ).jour_category;
    END IF;
--
    --仕訳名
    --併用カード仕訳(併用で上様は無い前提)
    IF ( iv_card_flg = cv_y_flag  ) THEN
      --フルVD
      IF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho  = ct_full_vd_cd ) THEN
        lv_vd_nm        := xxccp_common_pkg.get_msg(
                               iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                             , iv_name              => cv_full_vd              -- メッセージID
                           );
      --フルVD（消化）
      ELSIF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho  = ct_vd_xiaoka_cd ) THEN
        lv_vd_nm        := xxccp_common_pkg.get_msg(
                               iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                             , iv_name              => cv_vd_xiaoka            -- メッセージID
                           );
      END IF;
    --本体仕訳
    ELSE
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--      --上様顧客で現金のみ。かつフルVD、フルVD（消化）では無い。
--      --カードで上様は無い前提
--      IF ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
      --納品伝票区分：返品 or 返品訂正
      IF ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return            ) OR
         ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return_correction )
      THEN
        lv_vd_nm             := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_cust_cash_sale       -- メッセージID
                                );
      --上様顧客で現金のみ。かつフルVD、フルVD（消化）では無い。
      --カードで上様は無い前提
      ELSIF
         ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
--******************************* 2009/11/17 1.11 M.Sano MOD  END  *******************************--
         ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_full_vd_cd   ) AND
         ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_vd_xiaoka_cd ) AND
         ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class   = cv_cash_class   )
      THEN
        lv_vd_nm             := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_cust_cash_sale       -- メッセージID
                                );
      --フルVD
      ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  = ct_full_vd_cd ) THEN
        lv_vd_nm             := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_full_vd              -- メッセージID
                                );
      --フルVD（消化）
      ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  = ct_vd_xiaoka_cd ) THEN
        lv_vd_nm             := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_vd_xiaoka            -- メッセージID
                                );
      END IF;
    END IF;
--
    --仕訳明細摘要
    --併用カード仕訳
    IF ( iv_card_flg = cv_y_flag  ) THEN
      --フルVDカード
      IF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho  = ct_full_vd_cd ) THEN
        lv_detail            := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_full_vd_card         -- メッセージID
                                );
      --フルVD（消化）カード
      ELSIF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho  = ct_vd_xiaoka_cd ) THEN
        lv_detail            := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_vd_xiaoka_card       -- メッセージID
                                );
      END IF;
    --本体仕訳
    ELSE
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--      --上様顧客で現金のみ。かつフルVD、フルVD（消化）では無い。
--      --カードで上様は無い前提
--      IF ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
      --納品伝票区分：返品 or 返品訂正
      IF ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return            ) OR
         ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return_correction )
      THEN
        lv_detail            := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_cust_cash            -- メッセージID
                                );
      --上様顧客で現金のみ。かつフルVD、フルVD（消化）では無い。
      --カードで上様は無い前提
      ELSIF 
         ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
--******************************* 2009/11/17 1.11 M.Sano MOD  END  *******************************--
         ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_full_vd_cd   ) AND
         ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_vd_xiaoka_cd ) AND
         ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class   = cv_cash_class   )
      THEN
        -- 明細摘要：上様現金
        lv_detail            := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_cust_cash            -- メッセージID
                                );
      --フルVD
      ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  = ct_full_vd_cd ) THEN
        IF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_card_class ) THEN
          -- カード売上の場合：フルVDカード
          lv_detail          := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_full_vd_card         -- メッセージID
                                );
        ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_cash_class ) THEN
          -- 現金売上の場合：フルVD現金
          lv_detail          := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_full_vd_cash         -- メッセージID
                              );
        END IF;
      --フルVD（消化）
      ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  = ct_vd_xiaoka_cd ) THEN
        IF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_card_class ) THEN
          -- カード売上の場合：フルVD（消化）カード
          lv_detail          := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                  , iv_name              => cv_vd_xiaoka_card       -- メッセージID
                              );
        ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_cash_class ) THEN
          -- 現金売上の場合：フルVD（消化）現金
            lv_detail          := xxccp_common_pkg.get_msg(
                                      iv_application       => cv_xxcos_short_nm       -- アプリケーション短縮名
                                    , iv_name              => cv_vd_xiaoka_cash       -- メッセージID
                                );
        END IF;
      END IF;
    END IF;
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
--****************************** 2009/05/13 1.6 T.Kitajima ADD START ******************************--
    --拠点コード
    lv_section_code := NVL( gt_jour_cls_tbl( in_jcls_idx ).segment2, gt_sales_exp_tbl( in_sale_idx ).sales_base_code);
--****************************** 2009/05/13 1.6 T.Kitajima ADD  END  ******************************--
--
    -- 勘定科目セグメント１からセグメント８よりCCID取得
    lv_ccid_idx            :=   gv_company_code
                                                               -- セグメント１(会社コード)
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--                             || NVL( gt_jour_cls_tbl( in_jcls_idx ).segment2,
--                                                               -- セグメント２（部門コード）
--                                     gt_sales_exp_tbl( in_sale_idx ).sales_base_code )
--                                                               -- セグメント２(販売実績の売上拠点コード)
                             || lv_section_code                  -- セグメント２(拠点コード)
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
                             || iv_gl_segment3
                                                               -- セグメント３(勘定科目コード)
                             || gt_jour_cls_tbl( in_jcls_idx ).segment4
                                                               -- セグメント４(補助科目コード:現金のみ設定)
                             || gt_jour_cls_tbl( in_jcls_idx ).segment5
                                                               -- セグメント５(顧客コード)
                             || gt_jour_cls_tbl( in_jcls_idx ).segment6
                                                               -- セグメント６(企業コード)
                             || gt_jour_cls_tbl( in_jcls_idx ).segment7
                                                               -- セグメント７(予備)
                             || gt_jour_cls_tbl( in_jcls_idx ).segment8;
                                                               -- セグメント８(予備)
--
    -- CCIDの存在チェック-->存在している場合、取得必要がない
    IF ( gt_sel_ccid_tbl.EXISTS(  lv_ccid_idx ) ) THEN
      lt_ccid := gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id;
    ELSE
      -- CCID取得共通関数よりCCIDを取得する
      lt_ccid := xxcok_common_pkg.get_code_combination_id_f (
--****************************** 2009/08/25 1.8 M.Sano     MOD START ******************************--
--                     gd_process_date
                     gt_sales_exp_tbl( in_sale_idx ).delivery_date
--****************************** 2009/08/25 1.8 M.Sano     MOD  END  ******************************--
                   , gv_company_code
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--                   , NVL( gt_jour_cls_tbl( in_jcls_idx ).segment2,
--                          gt_sales_exp_tbl( in_sale_idx ).sales_base_code )
                   , lv_section_code
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
                   , iv_gl_segment3
                   , gt_jour_cls_tbl( in_jcls_idx ).segment4
                   , gt_jour_cls_tbl( in_jcls_idx ).segment5
                   , gt_jour_cls_tbl( in_jcls_idx ).segment6
                   , gt_jour_cls_tbl( in_jcls_idx ).segment7
                   , gt_jour_cls_tbl( in_jcls_idx ).segment8
                 );
      IF ( lt_ccid IS NULL ) THEN
        -- CCIDが取得できない場合
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application       => cv_xxcos_short_nm
                        , iv_name              => cv_ccid_nodata_msg
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--                        , iv_token_name1       => cv_tkn_segment1
--                        , iv_token_value1      => gv_company_code
--                        , iv_token_name2       => cv_tkn_segment2
--                        , iv_token_value2      => NVL( gt_jour_cls_tbl( in_jcls_idx ).segment2,
--                                                       gt_sales_exp_tbl( in_sale_idx ).sales_base_code )
--                        , iv_token_name3       => cv_tkn_segment3
--                        , iv_token_value3      => iv_gl_segment3
--                        , iv_token_name4       => cv_tkn_segment4
--                        , iv_token_value4      => gt_jour_cls_tbl( in_jcls_idx ).segment4
--                        , iv_token_name5       => cv_tkn_segment5
--                        , iv_token_value5      => gt_jour_cls_tbl( in_jcls_idx ).segment5
--                        , iv_token_name6       => cv_tkn_segment6
--                        , iv_token_value6      => gt_jour_cls_tbl( in_jcls_idx ).segment6
--                        , iv_token_name7       => cv_tkn_segment7
--                        , iv_token_value7      => gt_jour_cls_tbl( in_jcls_idx ).segment7
--                        , iv_token_name8       => cv_tkn_segment8
--                        , iv_token_value8      => gt_jour_cls_tbl( in_jcls_idx ).segment8
                        , iv_token_name1       => cv_tkn_segment1
                        , iv_token_value1      => gt_sales_exp_tbl( in_sale_idx ).dlv_invoice_number
                        , iv_token_name2       => cv_tkn_segment2
                        , iv_token_value2      => gv_company_code
                        , iv_token_name3       => cv_tkn_segment3
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--                        , iv_token_value3      => NVL( gt_jour_cls_tbl( in_jcls_idx ).segment2,
--                                                       gt_sales_exp_tbl( in_sale_idx ).sales_base_code )
                        , iv_token_value3      => lv_section_code
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
                        , iv_token_name4       => cv_tkn_segment4
                        , iv_token_value4      => iv_gl_segment3
                        , iv_token_name5       => cv_tkn_segment5
                        , iv_token_value5      => gt_jour_cls_tbl( in_jcls_idx ).segment4
                        , iv_token_name6       => cv_tkn_segment6
                        , iv_token_value6      => gt_jour_cls_tbl( in_jcls_idx ).segment5
                        , iv_token_name7       => cv_tkn_segment7
                        , iv_token_value7      => gt_jour_cls_tbl( in_jcls_idx ).segment6
                        , iv_token_name8       => cv_tkn_segment8
                        , iv_token_value8      => gt_jour_cls_tbl( in_jcls_idx ).segment7
                        , iv_token_name9       => cv_tkn_segment9
                        , iv_token_value9      => gt_jour_cls_tbl( in_jcls_idx ).segment8
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
                      );
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--****************************** 2009/08/25 1.8 M.Sano     ADD START ******************************--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
--****************************** 2009/08/25 1.8 M.Sano     ADD  END  ******************************--
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
        lv_errbuf  := lv_errmsg;
        RAISE non_ccid_expt;
      END IF;
--
      -- 取得したCCIDをワークテーブルに設定する
      gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
--
    END IF;
--
    -- 一般会計OIFの値セット
    gt_gl_interface_tbl( in_gl_idx ).status                := ct_status;
                                                              -- ステータス
    gt_gl_interface_tbl( in_gl_idx ).set_of_books_id       := gv_set_bks_id;
                                                              -- 会計帳簿ID
    gt_gl_interface_tbl( in_gl_idx ).currency_code         := ct_currency_code;
                                                              -- 通貨コード
    gt_gl_interface_tbl( in_gl_idx ).actual_flag           := ct_actual_flag;
                                                              -- 残高タイプ
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    IF ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd ) THEN
--      gt_gl_interface_tbl( in_gl_idx ).user_je_category_name := lv_vd_nm;
--                                                              -- 仕訳カテゴリ名
--    ELSE
--      gt_gl_interface_tbl( in_gl_idx ).user_je_category_name := gt_jour_cls_tbl( in_jcls_idx ).jour_category;
--                                                              -- 仕訳カテゴリ名
--    END IF;
    gt_gl_interface_tbl( in_gl_idx ).user_je_category_name := lv_category_name;
--****************************** 2009/05/13 1.6 T.Kitajima MOD  MOD  ******************************--
    gt_gl_interface_tbl( in_gl_idx ).user_je_source_name   := lv_user_je_source_name;
                                                              -- 仕訳ソース名
    gt_gl_interface_tbl( in_gl_idx ).code_combination_id   := lt_ccid;
                                                              -- CCID
    gt_gl_interface_tbl( in_gl_idx ).entered_dr            := in_entered_dr;
                                                              -- 借方金額
    gt_gl_interface_tbl( in_gl_idx ).entered_cr            := in_entered_cr;
                                                              -- 貸方金額
    gt_gl_interface_tbl( in_gl_idx ).reference1            := TO_CHAR( gd_process_date , ct_date_format_non_sep )
                                                              || ct_underbar
                                                              || lv_om_sales;
                                                              -- リファレンス1（バッチ名）
    gt_gl_interface_tbl( in_gl_idx ).reference2            := TO_CHAR( gd_process_date , ct_date_format_non_sep )
                                                              || ct_underbar
                                                              || lv_om_sales;
                                                              -- リファレンス2（バッチ摘要）
--
    IF ( iv_card_flg = cv_y_flag ) THEN
    -- 生成したカードレコードの場合
      gt_gl_interface_tbl( in_gl_idx ).accounting_date     := gt_sales_card_tbl ( in_card_idx ).delivery_date;
                                                              -- 記帳日
      gt_gl_interface_tbl( in_gl_idx ).reference4          :=    gt_sales_card_tbl ( in_card_idx ).sales_base_code
                                                              || ct_underbar
                                                              || gt_sales_card_tbl ( in_card_idx ).dlv_invoice_number
                                                              || ct_underbar
                                                              || lv_vd_nm;
                                                              -- リファレンス4（仕訳名）
      gt_gl_interface_tbl( in_gl_idx ).reference5          :=    gt_sales_card_tbl ( in_card_idx ).sales_base_code
                                                              || ct_underbar
                                                              || gt_sales_card_tbl ( in_card_idx ).dlv_invoice_number
                                                              || ct_underbar
                                                              || lv_vd_nm;
                                                              -- リファレンス5（仕訳名摘要）
      gt_gl_interface_tbl( in_gl_idx ).attribute1          := gt_sales_card_tbl ( in_card_idx ).tax_code;
                                                              -- 属性1（消費税コード）
      gt_gl_interface_tbl( in_gl_idx ).attribute3          := gt_sales_card_tbl ( in_card_idx ).dlv_invoice_number;
                                                              -- 属性3（伝票番号）
      gt_gl_interface_tbl( in_gl_idx ).attribute4          := gt_sales_card_tbl ( in_card_idx ).sales_base_code;
                                                              -- 属性4（起票部門）
      gt_gl_interface_tbl( in_gl_idx ).attribute5          := gt_sales_card_tbl ( in_card_idx ).results_employee_code;
                                                              -- 属性5（ユーザID）
    ELSE
      gt_gl_interface_tbl( in_gl_idx ).accounting_date     := gt_sales_exp_tbl ( in_sale_idx ).delivery_date;
                                                              -- 記帳日
      gt_gl_interface_tbl( in_gl_idx ).reference4          := gt_sales_exp_tbl ( in_sale_idx ).sales_base_code
                                                              || ct_underbar
                                                              || gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_number
                                                              || ct_underbar
                                                              || lv_vd_nm;
                                                              -- リファレンス4（仕訳名）
      gt_gl_interface_tbl( in_gl_idx ).reference5          := gt_sales_exp_tbl ( in_sale_idx ).sales_base_code
                                                              || ct_underbar
                                                              || gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_number
                                                              || ct_underbar
                                                              || lv_vd_nm;
                                                              -- リファレンス5（仕訳名摘要）
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
--      gt_gl_interface_tbl( in_gl_idx ).attribute1          := gt_sales_exp_tbl( in_sale_idx ).tax_code;
--                                                              -- 属性1（消費税コード）
      IF ( iv_gl_segment3 = gt_segment3_cash ) THEN
        gt_gl_interface_tbl( in_gl_idx ).attribute1        := ct_tax_code_null;
      ELSE
        gt_gl_interface_tbl( in_gl_idx ).attribute1        := gt_sales_exp_tbl( in_sale_idx ).tax_code;
      END IF;
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
      gt_gl_interface_tbl( in_gl_idx ).attribute3          := gt_sales_exp_tbl( in_sale_idx ).dlv_invoice_number;
                                                              -- 属性3（伝票番号）
      gt_gl_interface_tbl( in_gl_idx ).attribute4          := gt_sales_exp_tbl( in_sale_idx ).sales_base_code;
                                                              -- 属性4（起票部門）
      gt_gl_interface_tbl( in_gl_idx ).attribute5          := gt_sales_exp_tbl( in_sale_idx ).results_employee_code;
                                                              -- 属性5（ユーザID）
      IF ( gt_sales_exp_tbl( in_sale_idx ).card_sale_class = cv_cash_class ) THEN
        gt_gl_interface_tbl( in_gl_idx ).jgzz_recon_ref    := gt_sales_exp_tbl( in_sale_idx ).ship_to_customer_code;
                                                              -- 消込参照(現金勘定のみ)
      END IF;
    END IF;
--
    gt_gl_interface_tbl( in_gl_idx ).reference10           := lv_detail;
                                                              -- リファレンス10（仕訳明細摘要）
    gt_gl_interface_tbl( in_gl_idx ).group_id              := ct_group_id;
                                                              -- グループID
    gt_gl_interface_tbl( in_gl_idx ).context               := gv_set_bks_nm;
                                                              -- コンテキスト
    gt_gl_interface_tbl( in_gl_idx ).created_by            := cn_created_by;
                                                              -- 新規作成者
    gt_gl_interface_tbl( in_gl_idx ).date_created          := cd_creation_date;
                                                              -- 新規作成日
    gt_gl_interface_tbl( in_gl_idx ).request_id            := cn_request_id;
                                                              -- 要求ID
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN non_ccid_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
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
  END edit_gl_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_work_data
   * Description      : 一般会計OIF集約処理(A-3)
   ***********************************************************************************/
  PROCEDURE edit_work_data(
      ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2            -- リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_work_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
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
    ln_pure_amount     NUMBER DEFAULT 0;                                   -- カードレコードの本体金額
    ln_tax_amount      NUMBER DEFAULT 0;                                   -- カードレコードの消費税金額
    ln_gl_tax          NUMBER DEFAULT 0;                                   -- 集約後消費税金額
    ln_gl_amount       NUMBER DEFAULT 0;                                   -- 集約後金額
    ln_gl_tax_card     NUMBER DEFAULT 0;                                   -- 集約後消費税金額(カードレコード)
    ln_gl_amount_card  NUMBER DEFAULT 0;                                   -- 集約後金額(カードレコード)
    ln_gl_total        NUMBER DEFAULT 0;                                   -- 集約後GLに記入金額
    ln_gl_total_card   NUMBER DEFAULT 0;                                   -- 集約後GLに記入金額(カードレコード)
    ln_entered_dr      NUMBER DEFAULT 0;                                   -- GLに記入金額->借方行
    ln_entered_cr      NUMBER DEFAULT 0;                                   -- GLに記入金額->貸方行
    lt_gl_segment3     fnd_lookup_values.attribute4%TYPE;                  -- 勘定科目コード
--
    -- インデックス
    ln_card_idx        NUMBER DEFAULT 0;                                   -- カードレコードのインデックス
    ln_gl_idx          NUMBER DEFAULT 0;                                   -- GL OIFのインデックス
    ln_card_pt         NUMBER DEFAULT 1;                                   -- カードレコードの現ポイント
    lv_ccid_idx        VARCHAR2(225);                                      -- CCID のインデックス
    ln_card_jour       NUMBER DEFAULT 1;                                   -- カードレコード仕訳用
--******************************* 2009/03/26 1.4 T.Kitajima ADD START ****************************
    ln_index_work      NUMBER;
    ln_sale_idx        NUMBER;
    ln_index           NUMBER;
    sale_idx           NUMBER;
--******************************* 2009/03/26 1.4 T.Kitajima ADD  END  ****************************
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
    ln_warn_ind        NUMBER;                                             -- 警告データindex用
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
    -- 集計キー(販売実績)
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    lt_invoice_number  xxcos_sales_exp_headers.dlv_invoice_number%TYPE;    -- 集計キー：納品伝票番号
--    lt_invoice_class   xxcos_sales_exp_headers.dlv_invoice_class%TYPE;     -- 集計キー：納品伝票区分
--    lt_card_sale_class xxcos_sales_exp_headers.card_sale_class%TYPE;       -- 集計キー：カード売り区分
--    lt_goods_prod_cls  xxcos_good_prod_class_v.goods_prod_class_code%TYPE; -- 集計キー：品目区分コード（製品・商品）
--    lt_gccs_segment3   gl_code_combinations.segment3%TYPE;                 -- 集計キー：売上勘定科目コード
--    lt_tax_code        xxcos_sales_exp_headers.tax_code%TYPE;              -- 集計キー：税金コード
    lt_sales_exp_header_id  xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- 集計キー：販売実績ヘッダ
--
    --仕訳パターン用
    lt_card_sale_class      xxcos_sales_exp_headers.card_sale_class%TYPE;     -- カード売り区分
    lt_red_black_flag       xxcos_sales_exp_lines.red_black_flag%TYPE;        -- 赤黒フラグ
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
    lt_dlv_invoice_class    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;   -- 納品伝票区分
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
    lv_sum_flag        VARCHAR2(1);                                        -- 集計フラグ
    lv_sum_card_flag   VARCHAR2(1);                                        -- カード集計フラグ
--
    -- 集計キー(生成したカードレコード)
 --****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    lt_invoice_number_card  xxcos_sales_exp_headers.dlv_invoice_number%TYPE;-- 集計キー：納品伝票番号
--    lt_invoice_class_card   xxcos_sales_exp_headers.dlv_invoice_class%TYPE; -- 集計キー：納品伝票区分
--    lt_goods_prod_cls_card  xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
--                                                                            -- 集計キー：品目区分（製品・商品）
--    lt_gccs_segment3_card   gl_code_combinations.segment3%TYPE;             -- 集計キー：売上勘定科目コード
--    lt_tax_code_card        xxcos_sales_exp_headers.tax_code%TYPE;          -- 集計キー：税金コード
    lt_sales_exp_header_id_card  xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- 集計キー：販売実績ヘッダ
--
    --仕訳パターン用
    lt_red_black_flag_card       xxcos_sales_exp_lines.red_black_flag%TYPE;        -- 赤黒フラグ
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
    lt_dlv_invoice_class_card    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;    -- 納品伝票区分
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
--
    -- GL OIFに設定する値
    lv_enter_dr_msg    VARCHAR2(225);                                      -- 借方
    lv_enter_cr_msg    VARCHAR2(225);                                      -- 貸方
    lv_cash_msg        VARCHAR2(225);                                      -- 現金(勘定科目用)
    lv_vd_msg          VARCHAR2(225);                                      -- VD未収金仮勘定(勘定科目用)
    lv_tax_msg         VARCHAR2(225);                                      -- 仮受消費税等(勘定科目用)
    lv_err_code        VARCHAR2(1);
--
--
--****************************** 2009/05/13 1.6 T.Kitajima ADD START ******************************--
    lnsale_idx_plus    NUMBER;                                             -- 販売実績データ次明細用
--****************************** 2009/05/13 1.6 T.Kitajima ADD  END  ******************************--
--
    -- *** ローカル・カーソル （仕訳パターン）***
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    CURSOR jour_cls_cur
--    IS
--      SELECT
--             flvl.attribute1              dlv_invoice_class                -- 納品伝票区分
--           , flvl.attribute2              card_sale_class                  -- カード売り区分
--           , flvl.attribute3              goods_prod_cls                   -- 品目区分コード（製品・商品）
--           , flvl.attribute4              gl_segment3                      -- 勘定科目コード
--           , flvl.attribute5              gl_line_type                     -- ラインタイプ
--           , flvl.attribute6              gl_jour_category                 -- 仕訳カテゴリ
--           , flvl.attribute7              gl_segment2                      -- 部門コード
--           , flvl.meaning                 gl_jour_pattern                  -- 仕訳パターン
--           , flvl.description             gl_segment3_nm                   -- 勘定科目名
--           , flvl.attribute8              gl_segment4                      -- 補助勘定科目コード
--           , flvl.attribute9              gl_segment5                      -- 顧客コード
--           , flvl.attribute10             gl_segment6                      -- 企業コード
--           , flvl.attribute11             gl_segment7                      -- 予備１
--           , flvl.attribute12             gl_segment8                      -- 予備２
--      FROM
--              fnd_lookup_values           flvl
--      WHERE
--              flvl.lookup_type            = ct_qct_jour_cls
--        AND   flvl.lookup_code            LIKE ct_qcc_code
--        AND   flvl.enabled_flag           = ct_enabled_yes
--        AND   flvl.language               = USERENV( 'LANG' )
--        AND   gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
--                              AND         NVL( flvl.end_date_active,   gd_process_date )
--      ;
    CURSOR jour_cls_cur
    IS
      SELECT
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--             flvl.attribute1              red_black_flag                   -- 赤黒フラグ
             flvl.attribute1              dlv_invoice_class                -- 納品伝票区分
           , flvl.attribute12             red_black_flag                   -- 赤黒フラグ
--******************************* 2009/11/17 1.11 M.Sano MOD  END  *******************************--
           , flvl.attribute2              card_sale_class                  -- カード売り区分
           , flvl.attribute3              gl_segment3                      -- 勘定科目コード
           , flvl.attribute4              gl_line_type                     -- ラインタイプ
           , flvl.attribute5              gl_jour_category                 -- 仕訳カテゴリ
           , flvl.meaning                 gl_jour_pattern                  -- 仕訳パターン
           , flvl.description             gl_segment3_nm                   -- 勘定科目名
           , flvl.attribute6              gl_segment4                      -- 補助勘定科目コード
           , flvl.attribute7              gl_segment5                      -- 顧客コード
           , flvl.attribute8              gl_segment6                      -- 企業コード
           , flvl.attribute9              gl_segment7                      -- 予備１
           , flvl.attribute10             gl_segment8                      -- 予備２
           , flvl.attribute11             gl_segment2                      -- 拠点コード
      FROM
              fnd_lookup_values           flvl
      WHERE
              flvl.lookup_type            = ct_qct_jour_cls
        AND   flvl.lookup_code            LIKE ct_qcc_code
        AND   flvl.enabled_flag           = ct_enabled_yes
--****************************** 2009/09/14 1.9 Atsushiba     MOD START ******************************--
--        AND   flvl.language               = USERENV( 'LANG' )
        AND   flvl.language               = ct_lang
--****************************** 2009/09/14 1.9 Atsushiba     MOD END   ******************************--
        AND   gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                              AND         NVL( flvl.end_date_active,   gd_process_date )
      ;
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    non_jour_cls_expt         EXCEPTION;                                   -- 仕訳パターンなし
    edit_gl_expt              EXCEPTION;                                   -- 一般会計作成エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --=====================================
    -- 0.全角文字列取得
    --=====================================
    -- 借方
    lv_enter_dr_msg  := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_nm            -- アプリケーション短縮名
                          , iv_name        => cv_enter_dr_msg              -- メッセージID(借方)
                        );
--
    -- 貸方
    lv_enter_cr_msg  := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_nm            -- アプリケーション短縮名
                          , iv_name        => cv_enter_cr_msg              -- メッセージID(貸方)
                        );
--
    -- 現金
    lv_cash_msg      := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_nm            -- アプリケーション短縮名
                          , iv_name        => cv_cash_msg                  -- メッセージID(現金)
                        );
--
    -- VD未収金仮勘定
    lv_vd_msg        := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_nm            -- アプリケーション短縮名
                          , iv_name        => cv_vd_msg                    -- メッセージID(VD未収金仮勘定)
                        );
--
    --仮受消費税等
    lv_tax_msg        := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_short_nm           -- アプリケーション短縮名
                           , iv_name        => cv_tax_msg                  -- メッセージID(仮受消費税等)
                         );
--
    --=====================================
    -- 1.仕訳パターンの取得
    --=====================================
--
    -- カーソルオープン
    BEGIN
      OPEN  jour_cls_cur;
      FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
    EXCEPTION
    -- 仕訳パターン取得失敗した場合
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_jour_nodata_msg
                         , iv_token_name1  => cv_tkn_lookup_type
                         , iv_token_value1 => ct_qct_jour_cls
                       );
        lv_errbuf := lv_errmsg;
        RAISE non_jour_cls_expt;
    END;
    -- 仕訳パターン取得失敗した場合
    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_jour_nodata_msg
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => ct_qct_jour_cls
                     );
      lv_errbuf := lv_errmsg;
      RAISE non_jour_cls_expt;
    END IF;
--
    -- カーソルクローズ
    CLOSE jour_cls_cur;
--
    -- 抽出された販売実績併用データの編集
    <<gt_sales_exp_tbl_loop>>
    FOR sale_idx IN 1 .. gn_target_cnt LOOP
      --=====================================================================
      -- 2.現金・カード併用データを基に、カード売上データを作成する処理
      --=====================================================================
--****************************** 2009/05/13 1.6 MOD START ******************************--
--      -- 現金・カード併用の場合-->カード売り区分=現金:0 かつ 現金カード併用額>0
--      IF ( ( gt_sales_exp_tbl( sale_idx ).card_sale_class =  gt_card_sale_cls
--        AND  gt_sales_exp_tbl( sale_idx ).cash_and_card > 0 ) )   THEN
      -- 現金・カード併用の場合-->カード売り区分=現金:0 かつ 現金カード併用額!=0
      IF ( ( gt_sales_exp_tbl( sale_idx ).card_sale_class =  gt_card_sale_cls
        AND  gt_sales_exp_tbl( sale_idx ).cash_and_card != 0 ) )   THEN
--****************************** 2009/05/13 1.6 MOD  END  ******************************--
--
--****************************** 2009/05/13 1.6 MOD START ******************************--
--        -- カードレコードの本体金額
--        ln_pure_amount := gt_sales_exp_tbl( sale_idx ).cash_and_card
--                        / ( 1 + gt_sales_exp_tbl( sale_idx ).tax_rate/ct_percent );
--
--        -- 端数処理
--        IF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_up ) THEN
--          -- 切り上げの場合
--          ln_pure_amount := CEIL( ln_pure_amount );
--
--        ELSIF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_down ) THEN
--          -- 切り下げの場合
--          ln_pure_amount := TRUNC( ln_pure_amount );
--
--        ELSIF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_nearest ) THEN
--          -- 四捨五入の場合
--          ln_pure_amount := ROUND( ln_pure_amount );
--        END IF;
--
--        -- 課税の場合、カードレコードの消費税額を算出する
--        IF ( gt_sales_exp_tbl( sale_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_tax_amount := gt_sales_exp_tbl( sale_idx ).cash_and_card - ln_pure_amount;
--        ELSE
--          ln_tax_amount := 0;
--        END IF;
--
        -- カードレコードの本体金額
        ln_pure_amount := gt_sales_exp_tbl( sale_idx ).cash_and_card;
--
        --集計後に計算するのでとりあえず0円
        ln_tax_amount := 0;
--****************************** 2009/05/13 1.6 MOD  END  ******************************--
--
        --==============================================================
        --販売実績カードワークテーブルへのカードレコード登録
        --==============================================================
        ln_card_idx := ln_card_idx + 1;
--
        gt_sales_card_tbl( ln_card_idx ).sales_exp_header_id   := gt_sales_exp_tbl( sale_idx ).sales_exp_header_id;
                                                                                  -- 販売実績ヘッダID
        gt_sales_card_tbl( ln_card_idx ).dlv_invoice_number    := gt_sales_exp_tbl( sale_idx ).dlv_invoice_number;
                                                                                  -- 納品伝票番号
        gt_sales_card_tbl( ln_card_idx ).delivery_date         := gt_sales_exp_tbl( sale_idx ).delivery_date;
                                                                                  -- 納品日
        gt_sales_card_tbl( ln_card_idx ).inspect_date          := gt_sales_exp_tbl( sale_idx ).inspect_date;
                                                                                  -- 検収日
        gt_sales_card_tbl( ln_card_idx ).ship_to_customer_code := gt_sales_exp_tbl( sale_idx ).ship_to_customer_code;
                                                                                  -- 顧客【納品先】
        gt_sales_card_tbl( ln_card_idx ).cust_gyotai_sho       := gt_sales_exp_tbl( sale_idx ).cust_gyotai_sho;
                                                                                  -- 業態小分類
        gt_sales_card_tbl( ln_card_idx ).results_employee_code := gt_sales_exp_tbl( sale_idx ).results_employee_code;
                                                                                  -- 成績計上者コード
        gt_sales_card_tbl( ln_card_idx ).sales_base_code       := gt_sales_exp_tbl( sale_idx ).sales_base_code;
                                                                                  -- 売上拠点コード
        gt_sales_card_tbl( ln_card_idx ).card_sale_class       := cv_card_class;
                                                                                  -- カード売り区分（１：カード）
        gt_sales_card_tbl( ln_card_idx ).dlv_invoice_class     := gt_sales_exp_tbl( sale_idx ).dlv_invoice_class;
                                                                                  -- 納品伝票区分
--****************************** 2009/05/13 1.6 DEL START ******************************--
--       gt_sales_card_tbl( ln_card_idx ).goods_prod_cls        := gt_sales_exp_tbl( sale_idx ).goods_prod_cls;
--                                                                                  -- 品目コード
--****************************** 2009/05/13 1.6 DEL START ******************************--
        gt_sales_card_tbl( ln_card_idx ).pure_amount           := ln_pure_amount;
                                                                                  -- 本体金額
        gt_sales_card_tbl( ln_card_idx ).tax_amount            := ln_tax_amount;
                                                                                  -- 消費税金額
        gt_sales_card_tbl( ln_card_idx ).tax_rate              := gt_sales_exp_tbl( sale_idx ).tax_rate;
                                                                                  -- 消費税率
        gt_sales_card_tbl( ln_card_idx ).consumption_tax_class := gt_sales_exp_tbl( sale_idx ).consumption_tax_class;
                                                                                  -- 消費区分
        gt_sales_card_tbl( ln_card_idx ).tax_code              := gt_sales_exp_tbl( sale_idx ).tax_code;
                                                                                  -- 税金コード
        gt_sales_card_tbl( ln_card_idx ).customer_cls_code     :=  gt_sales_exp_tbl( sale_idx ).customer_cls_code;
                                                                                  -- 顧客区分
        gt_sales_card_tbl( ln_card_idx ).sales_class           := gt_sales_exp_tbl( sale_idx ).sales_class;
                                                                                  -- 売上区分
--****************************** 2009/05/13 1.6 DEL START ******************************--
--        gt_sales_card_tbl( ln_card_idx ).gccs_segment3         := gt_sales_exp_tbl( sale_idx ). gccs_segment3;
                                                                                  -- 売上勘定科目コード
--****************************** 2009/05/13 1.6 DEL START ******************************--
        gt_sales_card_tbl( ln_card_idx ).gcct_segment3         := gt_sales_exp_tbl( sale_idx ).gcct_segment3;
                                                                                  -- 税金勘定科目コード
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
        gt_sales_card_tbl( ln_card_idx ).red_black_flag        := gt_sales_exp_tbl( sale_idx ).red_black_flag;
                                                                                  -- 赤黒フラグ
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
      END IF;
--
    END LOOP gt_sales_exp_tbl_loop;                                               -- 販売実績併用データ編集終了
--
    -- 集約キーの値セット
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    lt_invoice_number   := gt_sales_exp_tbl( 1 ).dlv_invoice_number;
--    lt_invoice_class    := gt_sales_exp_tbl( 1 ).dlv_invoice_class;
--    lt_card_sale_class  := gt_sales_exp_tbl( 1 ).card_sale_class;
--    lt_goods_prod_cls   := gt_sales_exp_tbl( 1 ).goods_prod_cls;
--    lt_gccs_segment3    := gt_sales_exp_tbl( 1 ).gccs_segment3;
--    lt_tax_code         := gt_sales_exp_tbl( 1 ).tax_code;
    lt_sales_exp_header_id  := gt_sales_exp_tbl( 1 ).sales_exp_header_id; --販売実績ヘッダ
    --仕訳パターン用
    lt_red_black_flag       := gt_sales_exp_tbl( 1 ).red_black_flag;      --赤黒フラグ
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
    lt_dlv_invoice_class    := gt_sales_exp_tbl( 1 ).dlv_invoice_class;     --納品伝票区分
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
    lt_card_sale_class      := gt_sales_exp_tbl( 1 ).card_sale_class;     --カード売り区分
    lv_sum_flag             := cv_y_flag;                                 --OIF出力フラグ
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
--****************************** 2009/03/26 1.4 T.Kitajima ADD START ******************************--
    --スキップ件数初期化
    gn_warn_cnt := 0;
    -- INDEX保存
    ln_index_work := 1;
    ln_sale_idx   := 1;
    lv_err_code   := cv_status_normal;
--
--****************************** 2009/03/26 1.4 T.Kitajima ADD  END  ******************************--
--
    --データの集約
    <<gt_sales_exp_tbl_loop>>
    FOR sale_idx IN 1 .. gn_target_cnt LOOP
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--      --=====================================
--      --３.GL一般会計OIFデータの集約
--      --=====================================
--      IF (  lt_invoice_number   = gt_sales_exp_tbl( sale_idx ).dlv_invoice_number
--        AND lt_invoice_class    = gt_sales_exp_tbl( sale_idx ).dlv_invoice_class
--        AND lt_card_sale_class  = gt_sales_exp_tbl( sale_idx ).card_sale_class
--        AND lt_goods_prod_cls   = gt_sales_exp_tbl( sale_idx ).goods_prod_cls
--        AND lt_gccs_segment3    = gt_sales_exp_tbl( sale_idx ).gccs_segment3
--        AND lt_tax_code         = gt_sales_exp_tbl( sale_idx ).tax_code
--         ) THEN
----
--        -- 集約するフラグ初期設定
--        lv_sum_flag      := cv_y_flag;
--        lv_sum_card_flag := cv_y_flag;
----
----        -- 本体金額を集約する
--        ln_gl_amount := ln_gl_amount + gt_sales_exp_tbl( sale_idx ).pure_amount;
----
--        -- 課税の場合、消費税額を集約する
--        IF ( gt_sales_exp_tbl( sale_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_gl_tax := ln_gl_tax + gt_sales_exp_tbl( sale_idx ).tax_amount;
--        END IF;
----
--        -- カードレコードの場合、上記２で生成したカードレコードも集約
--        IF ( lt_card_sale_class = cv_card_class ) THEN
--          <<gt_sales_card_tbl_loop>>
--          FOR i IN ln_card_pt .. gt_sales_card_tbl.COUNT LOOP
--            IF (  lt_invoice_number = gt_sales_card_tbl( i ).dlv_invoice_number
--              AND lt_invoice_class  = gt_sales_card_tbl( i ).dlv_invoice_class
--              AND lt_goods_prod_cls = gt_sales_card_tbl( i ).goods_prod_cls
--              AND lt_gccs_segment3  = gt_sales_card_tbl( i ).gccs_segment3
--              AND lt_tax_code       = gt_sales_card_tbl( i ).tax_code
--            ) THEN
--              -- 本体金額を集約する
--              ln_gl_amount   := ln_gl_amount + gt_sales_card_tbl( i ).pure_amount;
--              -- 課税の場合、消費税額を集約する
--              IF ( gt_sales_card_tbl( ln_card_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--                ln_gl_tax := ln_gl_tax + gt_sales_card_tbl( i ).tax_amount;
--              END IF;
--              ln_card_pt := ln_card_pt + 1;
--            END IF;
--          END LOOP gt_sales_card_tbl_loop;
--        ELSIF ( sale_idx = gn_target_cnt AND ln_card_pt <= gt_sales_card_tbl.COUNT) THEN
--          -- 生成したカードレコードだけの集約
--
--          -- 集約キーの値セット
--          lt_invoice_number_card := gt_sales_card_tbl( ln_card_pt ).dlv_invoice_number;
--          lt_invoice_class_card  := gt_sales_card_tbl( ln_card_pt ).dlv_invoice_class;
--          lt_goods_prod_cls_card := gt_sales_card_tbl( ln_card_pt ).goods_prod_cls;
--          lt_gccs_segment3_card  := gt_sales_card_tbl( ln_card_pt ).gccs_segment3;
--          lt_tax_code_card       := gt_sales_card_tbl( ln_card_pt ).tax_code;
----
--          -- 生成したカードレコードだけの集約開始
--          FOR i IN ln_card_pt .. gt_sales_card_tbl.COUNT LOOP
--            IF (  lt_invoice_number_card = gt_sales_card_tbl( i ).dlv_invoice_number
--              AND lt_invoice_class_card  = gt_sales_card_tbl( i ).dlv_invoice_class
--              AND lt_goods_prod_cls_card = gt_sales_card_tbl( i ).goods_prod_cls
--              AND lt_gccs_segment3_card  = gt_sales_card_tbl( i ).gccs_segment3
--              AND lt_tax_code_card       = gt_sales_card_tbl( i ).tax_code
--            ) THEN
--              -- 本体金額を集約する
--              ln_gl_amount_card := ln_gl_amount_card + gt_sales_card_tbl( i ).pure_amount;
--              -- 課税の場合、消費税額を集約する
--              IF ( gt_sales_card_tbl( ln_card_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--                ln_gl_tax_card  := ln_gl_tax_card + gt_sales_card_tbl( i ).tax_amount;
--              END IF;
--              -- カードレコードの現ポイントをカウントする
--              ln_card_pt := ln_card_pt + 1;
--            END IF;
--
--          END LOOP gt_sales_card_tbl_loop;
----
--          -- 集約フラグ’N'を設定
--          lv_sum_card_flag := cv_n_flag;
--        END IF;
--      ELSE
--        lv_sum_flag := cv_n_flag;
--      END IF;
--
--      -- 最後のレコードになると集約フラグ’N'を設定
--      IF ( sale_idx = gn_target_cnt ) THEN
--        lv_sum_flag := cv_n_flag;
--      END IF;
--
      -- 販売実績ヘッダ更新のため：ROWIDの設定
      gt_sales_h_tbl( sale_idx )            := gt_sales_exp_tbl( sale_idx ).xseh_rowid;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
      gt_sales_h_tbl_work_w( sale_idx )     := gt_sales_exp_tbl( sale_idx ).xseh_rowid;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
      --=====================================
      --３.GL一般会計OIFデータの集約
      --=====================================
      --次明細のインデックス値を取得
      lnsale_idx_plus := sale_idx + 1;
      --現在行が最後か
      IF sale_idx = gn_target_cnt THEN
        --OIF出力
        lv_sum_flag := cv_n_flag;
      --集約キーに相違あるか。
      ELSIF  (    lt_sales_exp_header_id  <> gt_sales_exp_tbl( lnsale_idx_plus ).sales_exp_header_id ) THEN
        --OIF出力
        lv_sum_flag := cv_n_flag;
      END IF;
--
      -- 本体金額を集約する
      ln_gl_amount := ln_gl_amount + gt_sales_exp_tbl( sale_idx ).pure_amount;
--
      -- 課税の場合、消費税額を集約する
      IF ( gt_sales_exp_tbl( sale_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
        ln_gl_tax := ln_gl_tax + gt_sales_exp_tbl( sale_idx ).tax_amount;
      END IF;
--
      --OIF出力かつ併用カードデータがあれば、併用カード情報集約
      IF (lv_sum_flag = cv_n_flag AND ln_card_pt <= gt_sales_card_tbl.COUNT) THEN
        -- 生成したカードレコードだけの集約
        lt_sales_exp_header_id_card := gt_sales_exp_tbl( sale_idx ).sales_exp_header_id;   --販売実績ヘッダID
        --仕訳パターン用
        lt_red_black_flag_card      := gt_sales_exp_tbl( sale_idx ).red_black_flag;        --赤黒フラグ
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
        lt_dlv_invoice_class_card   := gt_sales_exp_tbl( sale_idx ).dlv_invoice_class;     --納品伝票区分
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
        -- 生成したカードレコードだけの集約開始
        FOR i IN ln_card_pt .. gt_sales_card_tbl.COUNT LOOP
          IF (  lt_sales_exp_header_id_card = gt_sales_card_tbl( i ).sales_exp_header_id ) THEN
            -- 本体金額を集約する
            ln_gl_amount_card := ln_gl_amount_card + gt_sales_card_tbl( i ).pure_amount;
            -- カードレコードの現ポイントをカウントする
            ln_card_pt := ln_card_pt + 1;
          END IF;
--
        END LOOP gt_sales_card_tbl_loop;
        --
        --カード消費税額算出
        ln_gl_tax_card   := ln_gl_amount_card * gt_sales_exp_tbl( sale_idx ).tax_rate / 
                              ( ct_percent + gt_sales_exp_tbl( sale_idx ).tax_rate );
       -- 端数処理
       IF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_up ) THEN
         -- 切り上げの場合
         ln_gl_tax_card   := roundup( ln_gl_tax_card );

       ELSIF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_down ) THEN
         -- 切り下げの場合
         ln_gl_tax_card   := TRUNC( ln_gl_tax_card );

       ELSIF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_nearest ) THEN
         -- 四捨五入の場合
         ln_gl_tax_card   := ROUND( ln_gl_tax_card );
       END IF;
        --カード本体(税抜)金額算出
        ln_gl_amount_card := ln_gl_amount_card - ln_gl_tax_card;
--
      END IF;
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
--
      -- -- 集約フラグ’N'の場合、下記OIF仕訳編集処理を行う
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--      IF ( lv_sum_flag = cv_n_flag OR lv_sum_card_flag = cv_n_flag ) THEN
      IF ( lv_sum_flag = cv_n_flag) THEN
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
--
        -- 仕訳パターンよりGL OIFの仕訳を編集する
        <<gt_jour_cls_tbl_loop>>
        FOR jcls_idx IN 1 .. gt_jour_cls_tbl.COUNT LOOP
--
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--          IF ( (    gt_jour_cls_tbl( jcls_idx ).dlv_invoice_class = lt_invoice_class
--                AND gt_jour_cls_tbl( jcls_idx ).card_sale_class   = lt_card_sale_class
--                AND gt_jour_cls_tbl( jcls_idx ).goods_prod_cls    = lt_goods_prod_cls
--                )
--            OR (    gt_jour_cls_tbl( jcls_idx ).dlv_invoice_class = lt_invoice_number_card
--                AND gt_jour_cls_tbl( jcls_idx ).card_sale_class   = cv_card_class
--                AND gt_jour_cls_tbl( jcls_idx ).goods_prod_cls    = lt_goods_prod_cls_card
--                )
--              ) THEN
--            -- 現金・VD未収金仮勘定の場合
--            IF (   gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm    = lv_cash_msg
--                OR gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm    = lv_vd_msg ) THEN
--              IF ( ln_gl_amount_card > 0 AND lv_sum_card_flag = cv_n_flag ) THEN
--                ln_gl_total_card := ln_gl_tax_card + ln_gl_amount_card;         -- 金額
--              END IF;
--              ln_gl_total        := ln_gl_tax + ln_gl_amount;                   -- 金額
--              lt_gl_segment3     := gt_jour_cls_tbl( jcls_idx ).segment3;       -- 勘定科目コード
--            -- 仮受消費税等の場合
--            ELSIF ( gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm = lv_tax_msg ) THEN
--              IF ( ln_gl_amount_card > 0 AND lv_sum_card_flag = cv_n_flag ) THEN
--                ln_gl_total_card := ln_gl_tax_card;                             -- 金額
--              END IF;
--              ln_gl_total        := ln_gl_tax;                                  -- 金額
--              lt_gl_segment3     := gt_sales_exp_tbl( sale_idx ).gcct_segment3; -- 勘定科目コード
--              -- 製品売上と商品売上の場合
--            ELSE
--              IF ( ln_gl_amount_card > 0 AND lv_sum_card_flag = cv_n_flag ) THEN
--                ln_gl_total_card := ln_gl_amount_card;                           -- 金額
--              END IF;
--              ln_gl_total        := ln_gl_amount;                               -- 金額
--              lt_gl_segment3     := gt_sales_exp_tbl( sale_idx ).gccs_segment3; --勘定科目コード
--            END IF;
--
          --現金仕分用データ
          IF (      gt_jour_cls_tbl( jcls_idx ).red_black_flag  = lt_red_black_flag
                AND gt_jour_cls_tbl( jcls_idx ).card_sale_class = lt_card_sale_class
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
                AND gt_jour_cls_tbl( jcls_idx ).dlv_invoice_class = lt_dlv_invoice_class
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
             )
          THEN
            -- 現金・VD未収金仮勘定の場合
            IF (    gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm  = lv_cash_msg
                 OR gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm  = lv_vd_msg
               )
            THEN
              ln_gl_total_card   := 0;                                                                          -- カード金額
              ln_gl_total        := abs( ( ln_gl_amount + ln_gl_tax ) - (ln_gl_tax_card + ln_gl_amount_card) ); -- 現金金額
              lt_gl_segment3     := gt_jour_cls_tbl( jcls_idx ).segment3;                                        -- 勘定科目コード
            -- 仮受消費税等の場合
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm = lv_tax_msg ) THEN
              ln_gl_total_card   := 0;                                                                      -- カード金額
              ln_gl_total        := abs( ln_gl_tax - ln_gl_tax_card );                                      -- 現金金額
              lt_gl_segment3     := gt_sales_exp_tbl( sale_idx ).gcct_segment3;                             -- 勘定科目コード
            -- 製品売上と商品売上の場合
            ELSE
              ln_gl_total_card   := 0;                                                                      -- カード金額
              ln_gl_total        := abs( ln_gl_amount - ln_gl_amount_card );                                -- 現金金額
              lt_gl_segment3     := gt_jour_cls_tbl( jcls_idx ).segment3;                                   -- 勘定科目コード
            END IF;
          --併用カード仕分用データ
          ELSIF  (     gt_jour_cls_tbl( jcls_idx ).red_black_flag    = lt_red_black_flag_card
                   AND gt_jour_cls_tbl( jcls_idx ).card_sale_class   = cv_card_class
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
                   AND gt_jour_cls_tbl( jcls_idx ).dlv_invoice_class = lt_dlv_invoice_class
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
                 )
          THEN
            -- 現金・VD未収金仮勘定の場合
            IF (    gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm    = lv_cash_msg
                 OR gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm    = lv_vd_msg
               )
            THEN
              ln_gl_total_card   := abs( ln_gl_tax_card + ln_gl_amount_card );                              -- カード金額
              ln_gl_total        := 0 ;                                                                     -- 現金金額
              lt_gl_segment3     := gt_jour_cls_tbl( jcls_idx ).segment3;                                   -- 勘定科目コード
            -- 仮受消費税等の場合
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm = lv_tax_msg ) THEN
              ln_gl_total_card   := abs( ln_gl_tax_card );                                                  -- カード金額
              ln_gl_total        := 0 ;                                                                     -- 現金金額
              lt_gl_segment3     := gt_sales_exp_tbl( sale_idx ).gcct_segment3;                             -- 勘定科目コード
            -- 製品売上と商品売上の場合
            ELSE
              ln_gl_total_card   := abs( ln_gl_amount_card );                                               -- カード金額
              ln_gl_total        := 0;                                                                      -- 現金金額
              lt_gl_segment3     := gt_jour_cls_tbl( jcls_idx ).segment3;                                   -- 勘定科目コード
            END IF;
          END IF;   -- 借方・貸方行毎にGL OIFデータ作成終了
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END *******************************--
--
          ln_card_jour := ln_card_pt - 1;
          IF (  gt_jour_cls_tbl( jcls_idx ).line_type = lv_enter_dr_msg ) THEN
            -- 借方行
--
            --===========================================
            --A-4.GL一般会計OIFデータ作成処理を呼び出し
            --===========================================
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--              IF ( ln_gl_total > 0 AND lv_sum_flag = cv_n_flag ) THEN
              --金額が発生している場合出力する
            IF ( ln_gl_total != 0) THEN
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END *******************************--
              --販売実績元データの集約
              ln_gl_idx := ln_gl_idx + 1;
              edit_gl_data(
                            ov_errbuf                 => lv_errbuf        -- エラー・メッセージ
                          , ov_retcode                => lv_retcode       -- リターン・コード
                          , ov_errmsg                 => lv_errmsg        -- ユーザー・エラー・メッセージ
                          , in_gl_idx                 => ln_gl_idx        -- GL OIF データインデックス
                          , in_sale_idx               => sale_idx         -- 販売実績データインデックス
                          , iv_card_flg               => cv_n_flag        -- 販売実績データ仕訳
                          , in_card_idx               => NULL             -- カードデータインデックス
                          , in_jcls_idx               => jcls_idx         -- 仕訳パターンインデックス
                          , iv_gl_segment3            => lt_gl_segment3   -- 勘定科目コード
                          , in_entered_dr             => ln_gl_total      -- 借方金額
                          , in_entered_cr             => NULL             -- 貸方金額
                        );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE edit_gl_expt;
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                lv_err_code := cv_status_warn;
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
              END IF;
              ln_gl_total := 0;
            END IF;
--
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--              IF ( ln_gl_total_card > 0 AND lv_sum_card_flag = cv_n_flag ) THEN
              --金額が発生している場合出力する
            IF ( ln_gl_total_card != 0 ) THEN
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END *******************************--
              --生成したカードレコードだけの集約データ
              ln_gl_idx  := ln_gl_idx  + 1;
              edit_gl_data(
                            ov_errbuf                 => lv_errbuf        -- エラー・メッセージ
                          , ov_retcode                => lv_retcode       -- リターン・コード
                          , ov_errmsg                 => lv_errmsg        -- ユーザー・エラー・メッセージ
                          , in_gl_idx                 => ln_gl_idx        -- GL OIF データインデックス
                          , in_sale_idx               => sale_idx         -- 販売実績データインデックス
                          , iv_card_flg               => cv_y_flag        -- 生成したカードデータ仕訳フラグ
                          , in_card_idx               => ln_card_jour     -- カードデータインデックス
                          , in_jcls_idx               => jcls_idx         -- 仕訳パターンインデックス
                          , iv_gl_segment3            => lt_gl_segment3   -- 勘定科目コード
                          , in_entered_dr             => ln_gl_total_card -- 借方金額
                          , in_entered_cr             => NULL             -- 貸方金額
                          );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE edit_gl_expt;
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                lv_err_code := cv_status_warn;
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
              END IF;
              ln_gl_total_card := 0;
            END IF;
--
          ELSIF ( gt_jour_cls_tbl( jcls_idx ).line_type = lv_enter_cr_msg ) THEN
            -- 貸方行
--
              --===========================================
              --A-4.GL一般会計OIFデータ作成処理を呼び出し
              --===========================================
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--              IF ( ln_gl_total > 0 AND lv_sum_flag = cv_n_flag ) THEN
            --金額が発生している場合出力する
            IF ( ln_gl_total != 0 ) THEN
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END *******************************--
              --販売実績データの集約
              ln_gl_idx := ln_gl_idx + 1;
              edit_gl_data(
                            ov_errbuf                 => lv_errbuf        -- エラー・メッセージ
                          , ov_retcode                => lv_retcode       -- リターン・コード
                          , ov_errmsg                 => lv_errmsg        -- ユーザー・エラー・メッセージ
                          , in_gl_idx                 => ln_gl_idx        -- GL OIF データインデックス
                          , in_sale_idx               => sale_idx         -- 販売実績データインデックス
                          , iv_card_flg               => cv_n_flag        -- 販売実績データ仕訳
                          , in_card_idx               => NULL             -- カードデータインデックス
                          , in_jcls_idx               => jcls_idx         -- 仕訳パターンインデックス
                          , iv_gl_segment3            => lt_gl_segment3   -- 勘定科目コード
                          , in_entered_dr             => NULL             -- 借方金額
                          , in_entered_cr             => ln_gl_total      -- 貸方金額
                        );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE edit_gl_expt;
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                lv_err_code := cv_status_warn;
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
              END IF;
              ln_gl_total := 0;
            END IF;
--
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--              IF ( ln_gl_total_card > 0 AND lv_sum_card_flag = cv_n_flag ) THEN
            --金額が発生している場合出力する
            IF ( ln_gl_total_card != 0 ) THEN
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END *******************************--
              ln_gl_idx  := ln_gl_idx  + 1;
              --生成したカードレコードだけの集約データ
              edit_gl_data(
                            ov_errbuf                 => lv_errbuf        -- エラー・メッセージ
                          , ov_retcode                => lv_retcode       -- リターン・コード
                          , ov_errmsg                 => lv_errmsg        -- ユーザー・エラー・メッセージ
                          , in_gl_idx                 => ln_gl_idx        -- GL OIF データインデックス
                          , in_sale_idx               => sale_idx         -- 販売実績データインデックス
                          , iv_card_flg               => cv_y_flag        -- 生成したカードデータ仕訳フラグ
                          , in_card_idx               => ln_card_jour     -- カードデータインデックス
                          , in_jcls_idx               => jcls_idx         -- 仕訳パターンインデックス
                          , iv_gl_segment3            => lt_gl_segment3   -- 勘定科目コード
                          , in_entered_dr             => NULL             -- 借方金額
                          , in_entered_cr             => ln_gl_total_card -- 貸方金額
                          );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE edit_gl_expt;
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                lv_err_code := cv_status_warn;
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
              END IF;
              ln_gl_total_card := 0;
            END IF;
--
          ELSE    -- 借方行と貸方行ではない場合、エラー
            lv_errmsg    := xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcos_short_nm
                              , iv_name         => cv_jour_nodata_msg
                              , iv_token_name1  => cv_tkn_lookup_type
                              , iv_token_value1 => ct_qct_jour_cls
                   );
            lv_errbuf := lv_errmsg;
            RAISE non_jour_cls_expt;
          END IF;
--
--******************************* 2009/05/13 1.6 T.Kitajima DEL START *******************************--
--          END IF;                                                       -- 借方・貸方行毎にGL OIFデータ作成終了
--******************************* 2009/05/13 1.6 T.Kitajima DEL  END  *******************************--
        END LOOP gt_jour_cls_tbl_loop;                                  -- 仕訳パターンよりデータ作成処理終了
--
        IF sale_idx < gn_target_cnt THEN
          -- 集約キーと集約金額のリセット
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--          lt_invoice_number   := gt_sales_exp_tbl( lnsale_idx_plus ).dlv_invoice_number;
--          lt_invoice_class    := gt_sales_exp_tbl( lnsale_idx_plus ).dlv_invoice_class;
--          lt_card_sale_class  := gt_sales_exp_tbl( lnsale_idx_plus ).card_sale_class;
--          lt_goods_prod_cls   := gt_sales_exp_tbl( lnsale_idx_plus ).goods_prod_cls;
--          lt_gccs_segment3    := gt_sales_exp_tbl( lnsale_idx_plus ).gccs_segment3;
--          lt_tax_code         := gt_sales_exp_tbl( lnsale_idx_plus ).tax_code;
          lt_sales_exp_header_id  := gt_sales_exp_tbl( lnsale_idx_plus ).sales_exp_header_id; --販売実績ヘッダ
          --仕訳パターン用
          lt_red_black_flag       := gt_sales_exp_tbl( lnsale_idx_plus ).red_black_flag;      --赤黒フラグ
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
          lt_dlv_invoice_class    := gt_sales_exp_tbl( lnsale_idx_plus ).dlv_invoice_class;   --納品伝票区分
--******************************* 2009/11/17 1.11 M.Sano MOD  END  *******************************--
          lt_card_sale_class      := gt_sales_exp_tbl( lnsale_idx_plus ).card_sale_class;     --カード売り区分
          lv_sum_flag             := cv_y_flag;                                               --OIF出力フラグ
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END  *******************************--
          ln_gl_amount := 0;
          ln_gl_tax    := 0;
          ln_gl_amount_card := 0;
          ln_gl_tax_card    := 0;
        END IF;
--
        --ループ中にA-4処理がワーニングだった場合
        IF ( lv_err_code = cv_status_warn ) THEN
          gt_gl_interface_tbl.DELETE(ln_index_work,ln_gl_idx);
          gt_sales_h_tbl.DELETE(ln_sale_idx,sale_idx);
          IF ln_index_work = 1 THEN
            gn_warn_cnt := ln_gl_idx;
          ELSE
            gn_warn_cnt   := gn_warn_cnt + ( ln_gl_idx - ln_index_work ) + 1;
          END IF;
          lv_err_code   := cv_status_normal;
          ov_retcode    := cv_status_warn;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
        ELSE
          gt_sales_h_tbl_work_w.DELETE(ln_sale_idx,sale_idx);
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
        END IF;
--
        ln_index_work := ln_gl_idx + 1;
        ln_sale_idx   := sale_idx + 1;
--
      END IF;                                                           -- 集約キー毎にGL OIFデータの集約終了
--
--******************************* 2009/05/13 1.6 T.Kitajima DEL START *******************************--
--      -- 販売実績ヘッダ更新のため：ROWIDの設定
--      gt_sales_h_tbl( sale_idx )            := gt_sales_exp_tbl( sale_idx ).xseh_rowid;
----******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
--
--      IF ( lv_sum_flag = cv_n_flag OR lv_sum_card_flag = cv_n_flag ) THEN
--        -- 集約キーと集約金額のリセット
--        lt_invoice_number   := gt_sales_exp_tbl( sale_idx ).dlv_invoice_number;
--        lt_invoice_class    := gt_sales_exp_tbl( sale_idx ).dlv_invoice_class;
--        lt_card_sale_class  := gt_sales_exp_tbl( sale_idx ).card_sale_class;
--        lt_goods_prod_cls   := gt_sales_exp_tbl( sale_idx ).goods_prod_cls;
--        lt_gccs_segment3    := gt_sales_exp_tbl( sale_idx ).gccs_segment3;
--        lt_tax_code         := gt_sales_exp_tbl( sale_idx ).tax_code;
----
--        ln_gl_amount        := gt_sales_exp_tbl( sale_idx ).pure_amount;
--        IF ( gt_sales_exp_tbl( sale_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_gl_tax         := gt_sales_exp_tbl( sale_idx ).tax_amount;
--        END IF;
--
--
----******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
--        --ループ中にA-4処理がワーニングだった場合
--        IF ( lv_err_code = cv_status_warn ) THEN
--          gt_gl_interface_tbl.DELETE(ln_index_work,ln_gl_idx);
--          gt_sales_h_tbl.DELETE(ln_sale_idx,sale_idx);
--          IF ln_index_work = 1 THEN
--            gn_warn_cnt := ln_gl_idx;
--          ELSE
--            gn_warn_cnt   := gn_warn_cnt + ( ln_gl_idx - ln_index_work ) + 1;
--          END IF;
--          lv_err_code   := cv_status_normal;
--          ov_retcode    := cv_status_warn;
--        END IF;
----
--        ln_index_work := ln_gl_idx + 1;
--        ln_sale_idx   := sale_idx + 1;
----******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
----
--      END IF;
--******************************* 2009/05/13 1.6 T.Kitajima DEL  END  *******************************--
--
--******************************** 2009/03/26 1.4 T.Kitajima DEL START *****************************
--      -- 販売実績ヘッダ更新のため：ROWIDの設定
--      gt_sales_h_tbl( sale_idx )            := gt_sales_exp_tbl( sale_idx ).xseh_rowid;
--******************************** 2009/03/26 1.4 T.Kitajima DEL  END  *****************************
--
    END LOOP gt_sales_exp_tbl_loop;                                     -- 販売実績データループ終了
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
    --コレクションの入れ替え
    ln_index := 1;
    FOR i IN 1 .. ln_gl_idx LOOP
      IF ( gt_gl_interface_tbl.EXISTS(i) ) THEN
        gt_gl_interface_tbl2(ln_index) := gt_gl_interface_tbl(i);
        ln_index := ln_index + 1;
      END IF;
    END LOOP;
--
    ln_index := 1;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
    ln_warn_ind := 1;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
    FOR i IN 1 .. gn_target_cnt LOOP
      IF ( gt_sales_h_tbl.EXISTS(i) ) THEN
        gt_sales_h_tbl2(ln_index) := gt_sales_h_tbl(i);
        ln_index := ln_index + 1;
      END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
      IF ( gt_sales_h_tbl_work_w.EXISTS(i) ) THEN
        gt_sales_h_tbl_w( ln_warn_ind )  := gt_sales_h_tbl_work_w(i);
        ln_warn_ind := ln_warn_ind + 1;
        gt_sales_h_tbl_work_w.DELETE(i);
      END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
    END LOOP;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
    gt_sales_h_tbl_work_w.DELETE;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
--
  EXCEPTION
    WHEN non_jour_cls_expt THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN edit_gl_expt THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END edit_work_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_gl_data
   * Description      : 一般会計OIF登録処理(A-5)
   ***********************************************************************************/
  PROCEDURE insert_gl_data(
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2 )        --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_gl_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_tbl_nm VARCHAR2(255);                -- テーブル名
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
    --==============================================================
    -- 一般会計OIFテーブルへデータ登録
    --==============================================================
    BEGIN
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--      FORALL i IN 1..gt_gl_interface_tbl.COUNT
      FORALL i IN 1..gt_gl_interface_tbl2.COUNT
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
        INSERT INTO
          gl_interface
        VALUES
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--          gt_gl_interface_tbl(i)
          gt_gl_interface_tbl2(i)
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
        ;
    EXCEPTION
      WHEN OTHERS THEN
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
        lv_errbuf := SQLERRM;
--******************************* 2009/11/17 1.11 M.Sano MOD  END   *******************************--
        RAISE global_insert_data_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      -- 登録に失敗した場合
      -- エラー件数設定
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm               -- アプリ短縮名
                      , iv_name              => cv_tkn_gloif_msg                -- メッセージID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                      , iv_token_name2  => cv_tkn_key_data
                      , iv_token_value2 => cv_blank
                    );
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||lv_errbuf,1,5000);
--******************************* 2009/11/17 1.11 M.Sano MOD  END   *******************************--
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
  END insert_gl_data;
--
  /***********************************************************************************
   * Procedure Name   : upd_data
   * Description      : 販売実績ヘッダ更新処理(A-6)
   ***********************************************************************************/
  PROCEDURE upd_data(
    ov_errbuf         OUT VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2 )        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'upd_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_tbl_nm VARCHAR2(255);                -- テーブル名
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- 販売実績ヘッダ更新処理
    --==============================================================
--
    -- 処理対象データのインタフェース済フラグを一括更新する
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
    IF ( gn_last_flag = 0 ) THEN
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
      IF ( gt_sales_h_tbl2.COUNT > 0 ) THEN
          -- 正常データ更新
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
        BEGIN
          <<update_interface_flag>>
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--      FORALL i IN gt_sales_h_tbl.FIRST..gt_sales_h_tbl.LAST
          FORALL i IN gt_sales_h_tbl2.FIRST..gt_sales_h_tbl2.LAST
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
            UPDATE
              xxcos_sales_exp_headers      xseh
            SET
              xseh.gl_interface_flag      = cv_y_flag,                           -- GLインタフェース済フラグ
              xseh.last_updated_by        = cn_last_updated_by,                  -- 最終更新者
              xseh.last_update_date       = cd_last_update_date,                 -- 最終更新日
              xseh.last_update_login      = cn_last_update_login,                -- 最終更新ログイン
              xseh.request_id             = cn_request_id,                       -- 要求ID
              xseh.program_application_id = cn_program_application_id,           -- コンカレント・プログラム・アプリID
              xseh.program_id             = cn_program_id,                       -- コンカレント・プログラムID
              xseh.program_update_date    = cd_program_update_date               -- プログラム更新日
            WHERE
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--          xseh.rowid                  = gt_sales_h_tbl( i );                 -- 販売実績ROWID
              xseh.rowid                  = gt_sales_h_tbl2( i );                 -- 販売実績ROWID
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
--
          EXCEPTION
            WHEN OTHERS THEN
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
              lv_tbl_nm    := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_xxcos_short_nm
                                , iv_name         => cv_sales_exp_h_nomal
                             );
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
              RAISE global_update_data_expt;
          END;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
        END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
        IF ( gt_sales_h_tbl_w.COUNT > 0 ) THEN
          -- 警告データ更新
          BEGIN
            FORALL w IN gt_sales_h_tbl_w.FIRST..gt_sales_h_tbl_w.LAST
              UPDATE
                xxcos_sales_exp_headers      xseh
              SET
                xseh.gl_interface_flag      = cv_w_flag,                           -- GLインタフェース済フラグ
                xseh.last_updated_by        = cn_last_updated_by,                  -- 最終更新者
                xseh.last_update_date       = cd_last_update_date,                 -- 最終更新日
                xseh.last_update_login      = cn_last_update_login,                -- 最終更新ログイン
                xseh.request_id             = cn_request_id,                       -- 要求ID
                xseh.program_application_id = cn_program_application_id,           -- コンカレント・プログラム・アプリID
                xseh.program_id             = cn_program_id,                       -- コンカレント・プログラムID
                xseh.program_update_date    = cd_program_update_date               -- プログラム更新日
              WHERE
                xseh.rowid                  = gt_sales_h_tbl_w(w)
                ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_tbl_nm    := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_xxcos_short_nm
                                , iv_name         => cv_sales_exp_h_warn
                             );
              RAISE global_update_data_expt;
          END;
        END IF;
--
    ELSE
        -- 対象外データ更新
      BEGIN
        UPDATE
          xxcos_sales_exp_headers      xseh
        SET
          xseh.gl_interface_flag      = cv_s_flag,                           -- GLインタフェース済フラグ
          xseh.last_updated_by        = cn_last_updated_by,                  -- 最終更新者
          xseh.last_update_date       = cd_last_update_date,                 -- 最終更新日
          xseh.last_update_login      = cn_last_update_login,                -- 最終更新ログイン
          xseh.request_id             = cn_request_id,                       -- 要求ID
          xseh.program_application_id = cn_program_application_id,           -- コンカレント・プログラム・アプリID
          xseh.program_id             = cn_program_id,                       -- コンカレント・プログラムID
          xseh.program_update_date    = cd_program_update_date             -- プログラム更新日
        WHERE
          xseh.gl_interface_flag      = cv_n_flag
        AND
          xseh.inspect_date           <= gd_process_date
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_tbl_nm    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_xxcos_short_nm
                            , iv_name         => cv_sales_exp_h_elig
                         );
          RAISE global_update_data_expt;
      END;
--      END IF;
    END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_update_data_expt THEN
      -- 更新に失敗した場合
      -- エラー件数設定
      gn_error_cnt := gn_target_cnt;
-- ***************** 2009/10/07 1.10 N.Maeda DEL START ***************** --
--      lv_tbl_nm    := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_xxcos_short_nm
--                        , iv_name         => cv_tkn_sales_msg
--                     );
-- ***************** 2009/10/07 1.10 N.Maeda DEL  END  ***************** --
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_data_update_msg
                        , iv_token_name1  => cv_tkn_tbl_nm
                        , iv_token_value1 => lv_tbl_nm
                        , iv_token_name2  => cv_tkn_key_data
                        , iv_token_value2 => cv_blank
                      );
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode   := cv_status_error;
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
  END upd_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
  (
      ov_errbuf    OUT VARCHAR2             --   エラー・メッセージ           --# 固定 #
    , ov_retcode   OUT VARCHAR2             --   リターン・コード             --# 固定 #
    , ov_errmsg    OUT VARCHAR2 )           --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_tbl_nm VARCHAR2(255);                -- テーブル名
    lv_retcode_tmp VARCHAR2(1);
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
--
    ln_pre_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE;    -- 販売実績ヘッダID
    ln_lock_header_id      xxcos_sales_exp_headers.sales_exp_header_id%TYPE;    -- 販売実績ヘッダID
    ln_header_id_wk        xxcos_sales_exp_headers.sales_exp_header_id%TYPE;    -- 販売実績ヘッダID
    ln_sales_idx           NUMBER DEFAULT 1;
    ln_target_wk_cnt       NUMBER DEFAULT 0;
    ln_fetch_end_flag      NUMBER DEFAULT 0;     -- 0:継続、1:終了
    ln_warn_wk_cnt         NUMBER DEFAULT 0;
    lv_table_name          VARCHAR2(100);
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
    ln_last_dara_count     NUMBER DEFAULT 0;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
    -- <カーソル名>レコード型
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
    gn_target_cnt    := 0;                  -- 対象件数
    gn_normal_cnt    := 0;                  -- 正常件数
    gn_error_cnt     := 0;                  -- エラー件数
--****************************** 2009/07/06 1.7 T.Tominaga ADL START ******************************
    gn_warn_cnt      := 0;                  --スキップ件数
--****************************** 2009/07/06 1.7 T.Tominaga ADL END   ******************************
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode            -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.データ取得
    -- ===============================
    get_data(
        ov_errbuf  => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode            -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
--****************************** 2009/09/14 1.9 Atsushiba  MOD START ******************************--
--
    -- 初期化
    gt_sales_exp_tbl.DELETE;
    lv_retcode_tmp := cv_status_normal;
    <<bulk_loop>>
    LOOP
      -- 初期化
      gt_sales_exp_wk_tbl.DELETE;
      ln_pre_header_id := NULL;
      ln_lock_header_id := NULL;
      --
      -- データ取得
      FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_wk_tbl LIMIT cn_bulk_collect_count;
      -- 
      EXIT WHEN ln_fetch_end_flag = 1;
--
      -- データ有無チェック
      IF ( sales_data_cur%NOTFOUND ) THEN
        ln_fetch_end_flag := 1;
      END IF;
      --
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
      IF ( ln_fetch_end_flag = 1 ) AND ( gt_sales_exp_wk_tbl.COUNT = 0 ) THEN
          gt_sales_exp_wk_tbl := gt_sales_exp_evacu_tbl;
          gt_sales_exp_evacu_tbl.DELETE;
          gn_target_cnt       := gn_target_cnt - gt_sales_exp_wk_tbl.COUNT;
          ln_target_wk_cnt    := ln_target_wk_cnt - gt_sales_exp_wk_tbl.COUNT;
      END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
      <<journal_loop>>
      FOR ln_idx IN 1..gt_sales_exp_wk_tbl.COUNT LOOP
-- 
        -- 販売実績IDの件数が基準値以上かつ販売実績IDがブレイク
        -- または、フェッチ読込終了かつ配列の最後
        IF ( ( gt_sales_header_tbl.COUNT >= cn_journal_batch_count
               AND ln_pre_header_id <> gt_sales_exp_wk_tbl(ln_idx).sales_exp_header_id)
             OR ( ln_fetch_end_flag = 1 AND ln_idx = gt_sales_exp_wk_tbl.COUNT )
           )
        THEN
          --
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
          ln_last_dara_count := 0;
          gt_sales_exp_evacu_tbl.DELETE;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
          -- フェッチ読込終了かつ配列の最後の場合
          IF ( ln_fetch_end_flag = 1 AND ln_idx = gt_sales_exp_wk_tbl.COUNT ) THEN
            gn_target_cnt := gn_target_cnt + 1;
            gt_sales_exp_tbl(ln_sales_idx) := gt_sales_exp_wk_tbl(ln_idx);
          END IF;
          --
          BEGIN
            -- 処理対象データをロック
            <<lock_loop>>
            FOR ln_lock_ind IN 1..gt_sales_exp_tbl.COUNT LOOP
              IF (ln_lock_header_id <> gt_sales_exp_tbl(ln_lock_ind).sales_exp_header_id) THEN
                SELECT  xseh.sales_exp_header_id
                INTO    ln_header_id_wk
                FROM    xxcos_sales_exp_headers xseh
                WHERE   xseh.sales_exp_header_id = gt_sales_exp_tbl(ln_lock_ind).sales_exp_header_id
                FOR UPDATE OF  xseh.sales_exp_header_id
                NOWAIT;
              END IF;
              --
              ln_lock_header_id := gt_sales_exp_tbl(ln_lock_ind).sales_exp_header_id;
            END LOOP lock_loop;
            --
            -- ===============================
            -- A-3.一般会計OIF集約処理 (A-4 処理の呼出を含め)
            -- ===============================
            edit_work_data(
                 ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
               , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
               , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode = cv_status_error ) THEN
              gn_error_cnt := 1;
              RAISE global_process_expt;
            ELSIF ( lv_retcode = cv_status_warn ) THEN
              lv_retcode_tmp := cv_status_warn;
            END IF;
  --
            -- ===============================
            -- A-5.一般会計OIFデータ登録処理
            -- ===============================
            insert_gl_data(
                  ov_errbuf       => lv_errbuf     -- エラー・メッセージ
                , ov_retcode      => lv_retcode    -- リターン・コード
                , ov_errmsg       => lv_errmsg     -- ユーザー・エラー・メッセージ
              );
            IF ( lv_retcode = cv_status_error ) THEN
              gn_error_cnt := 1;
              RAISE global_insert_data_expt;
            END IF;
    --
            -- ===============================
            -- A-6.販売実績データの更新処理
            -- ===============================
            upd_data(
                ov_errbuf  => lv_errbuf           -- エラー・メッセージ
              , ov_retcode => lv_retcode          -- リターン・コード
              , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
              );
            IF ( lv_retcode = cv_status_error ) THEN
              gn_error_cnt := 1;
              RAISE global_update_data_expt;
            END IF;
            --
            -- 正常処理件数設定
            gn_normal_cnt := gn_normal_cnt + gt_gl_interface_tbl2.COUNT;
            --
            -- 警告件数設定
            ln_warn_wk_cnt := ln_warn_wk_cnt + gn_warn_cnt;
            --
            -- コミット
            COMMIT;
            cn_commit_exec_flag := 1;
            --
          EXCEPTION
            -- ロックエラー
            WHEN lock_expt THEN
              -- ロックエラーメッセージ
              lv_table_name := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_short_nm               -- アプリケーション短縮名
                  , iv_name        => cv_tkn_sales_msg);                -- メッセージID
              lv_errmsg     := xxccp_common_pkg.get_msg(
                    iv_application   => cv_xxcos_short_nm
                  , iv_name          => cv_table_lock_msg
                  , iv_token_name1   => cv_tkn_tbl
                  , iv_token_value1  => lv_table_name);
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
              --
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => cv_blank
              );
              --
              -- スキップメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application   => cv_xxcos_short_nm
                  , iv_name          => cv_skip_data_msg
                  , iv_token_name1   => cv_tkn_header_from           -- ヘッダ(FROM)
                  , iv_token_value1  => TO_CHAR(gt_sales_exp_tbl(1).sales_exp_header_id)
                  , iv_token_name2   => cv_tkn_header_to             -- ヘッダ(TO)
                  , iv_token_value2  => TO_CHAR(gt_sales_exp_tbl(gt_sales_exp_tbl.COUNT).sales_exp_header_id)
                  , iv_token_name3   => cv_tkn_count                 -- ヘッダ件数
                  , iv_token_value3  => TO_CHAR(gt_sales_header_tbl.COUNT)
                  );
              -- メッセージ出力
              -- 空行出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
              --
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              lv_retcode_tmp := cv_status_warn;
              -- スキップ件数
              ln_warn_wk_cnt := ln_warn_wk_cnt + gt_sales_exp_tbl.COUNT;
          END;
          --
          -- 初期化
          gt_sales_header_tbl.DELETE;    -- 販売実績ヘッダID件数用
          gt_sales_card_tbl.DELETE;      -- カードデータ用
          gt_sales_exp_tbl.DELETE;       -- 販売実績データ用
          gt_sales_h_tbl.DELETE;         -- AR連携フラグ更新用
          gt_sales_h_tbl2.DELETE;        -- AR連携フラグ更新用
          gt_gl_interface_tbl.DELETE;    -- GL-OIFデータ編集用
          gt_gl_interface_tbl2.DELETE;   -- GL-OIF登録用
          ln_sales_idx := 1;
          gn_target_cnt := 0;
          gn_warn_cnt := 0;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
          gt_sales_h_tbl_w.DELETE;       -- 販売実績データ用(警告)
          gt_sales_h_tbl_work_w.DELETE;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
        END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
        IF ( cn_bulk_collect_count = gt_sales_exp_wk_tbl.COUNT ) THEN
          ln_last_dara_count := ln_last_dara_count + 1;
          gt_sales_exp_evacu_tbl( ln_last_dara_count ) := gt_sales_exp_wk_tbl(ln_idx);
        END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
        gt_sales_exp_tbl(ln_sales_idx) := gt_sales_exp_wk_tbl(ln_idx);
        ln_sales_idx := ln_sales_idx + 1;
        gt_sales_header_tbl(TO_CHAR(gt_sales_exp_wk_tbl(ln_idx).sales_exp_header_id)) := NULL;
        ln_target_wk_cnt := ln_target_wk_cnt + 1;
        gn_target_cnt := gn_target_cnt + 1;
        ln_pre_header_id := gt_sales_exp_wk_tbl(ln_idx).sales_exp_header_id;
      END LOOP journal_loop;
      --
    END LOOP bulk_loop;
    --
    gn_target_cnt := ln_target_wk_cnt;
    gn_warn_cnt   := ln_warn_wk_cnt;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
    gn_last_flag := 1;
    -- ===============================
    -- A-6.販売実績データの更新処理
    -- ===============================
    upd_data(
        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
      , ov_retcode => lv_retcode          -- リターン・コード
      , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
            );
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
      RAISE global_update_data_expt;
    END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
    --
    IF ((gn_warn_cnt > 0 )
        OR ( lv_retcode_tmp = cv_status_warn )) THEN
      -- 警告終了
      ov_retcode := cv_status_warn;
    END IF;
    --
    -- カーソルクローズ
    IF ( sales_data_cur%ISOPEN ) THEN
      CLOSE sales_data_cur;
    END IF;
    --
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_nm
                      , iv_name         => cv_no_data_msg);
      lv_errbuf  := lv_errmsg;
      lv_retcode := cv_status_warn;
      RAISE global_no_data_expt;
    END IF;
    --
    lv_retcode := lv_retcode_tmp;
    --
--
--    -- 販売実績情報抽出が0件時は、抽出レコードなしで終了
--    IF ( gn_target_cnt > 0 ) THEN
----
--    -- ===============================
--    -- A-3.一般会計OIF集約処理 (A-4 処理の呼出を含め)
--    -- ===============================
--        edit_work_data(
--             ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
--           , ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
--           , ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        ELSE
--          lv_retcode_tmp := lv_retcode;
--        END IF;
--
--      -- ===============================
--      -- A-5.一般会計OIFデータ登録処理
--      -- ===============================
--      insert_gl_data(
--            ov_errbuf       => lv_errbuf     -- エラー・メッセージ
--          , ov_retcode      => lv_retcode    -- リターン・コード
--          , ov_errmsg       => lv_errmsg     -- ユーザー・エラー・メッセージ
--        );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_insert_data_expt;
--      END IF;
----
--      -- ===============================
--      -- A-6.販売実績データの更新処理
--      -- ===============================
--      upd_data(
--          ov_errbuf  => lv_errbuf           -- エラー・メッセージ
--        , ov_retcode => lv_retcode          -- リターン・コード
--        , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
--        );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_update_data_expt;
--      END IF;
----
--      -- 正常件数設定
----      gn_normal_cnt      := gt_gl_interface_tbl.COUNT;
--      gn_normal_cnt      := gt_gl_interface_tbl2.COUNT;
--      IF ( lv_retcode_tmp = cv_status_warn ) THEN
--        ov_retcode := lv_retcode_tmp;
--      END IF;
--
--    ELSIF ( gn_target_cnt = 0 ) THEN
--      -- 対象データ無しメッセージ
----****************************** 2009/07/06 1.7 T.Tominaga DEL START ******************************
----      lv_tbl_nm  := xxccp_common_pkg.get_msg(
----                        iv_application => cv_xxcos_short_nm               -- アプリケーション短縮名
----                      , iv_name        => cv_tkn_sales_msg                -- メッセージID
----                    );
----****************************** 2009/07/06 1.7 T.Tominaga DEL END   ******************************
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_xxcos_short_nm
--                      , iv_name         => cv_no_data_msg
----****************************** 2009/07/06 1.7 T.Tominaga DEL START ******************************
----                      , iv_token_name1  => cv_tkn_tbl_nm
----                      , iv_token_value1 => lv_tbl_nm
----****************************** 2009/07/06 1.7 T.Tominaga DEL END   ******************************
--                    );
--      lv_errbuf  := lv_errmsg;
--      lv_retcode := cv_status_warn;
--      RAISE global_no_data_expt;
--    ELSE
--      RAISE global_select_data_expt;
--    END IF;
--****************************** 2009/09/14 1.9 Atsushiba  MOD END ******************************--
--
  EXCEPTION
    -- *** 対象データなし ***
    WHEN global_no_data_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** データ取得例外 ***
    WHEN global_select_data_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 登録処理例外 ***
    WHEN global_insert_data_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 更新処理例外 ***
    WHEN global_update_data_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
      gn_target_cnt := ln_target_wk_cnt;
      gn_warn_cnt   := ln_warn_wk_cnt;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- カーソルクローズ
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
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
      errbuf      OUT VARCHAR2               -- エラー・メッセージ  --# 固定 #
    , retcode     OUT VARCHAR2 )             -- リターン・コード    --# 固定 #
  IS
--
--###########################  固定部 START   ###########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(20)  := 'COUNT';             -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
    cv_error_part_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- エラー終了一部処理メッセージ
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);         -- リターン・コード
    lv_errmsg          VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);       -- 終了メッセージコード
    lv_sum_rec_msg     VARCHAR2(100);       -- 集約件数メッセージ
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
        ov_errbuf  => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode             -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error OR lv_retcode = cv_status_warn) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --エラーメッセージ
      );
    END IF;
--
    -- ===============================
    -- A-7.終了処理
    -- ===============================
    --空行挿入
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
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
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/09/14 1.9 Atsushiba  MOD START ******************************--
      IF ( cn_commit_exec_flag = 1 ) THEN
        -- コミット実行ありの場合
        lv_message_code := cv_error_part_msg;
      ELSE
        -- コミット未実行の場合
        lv_message_code := cv_error_msg;
      END IF;
--      lv_message_code := cv_error_msg;
--****************************** 2009/09/14 1.9 Atsushiba  MOD END ******************************--

    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_xxccp_short_nm
                    , iv_name        => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS013A03C;
/
