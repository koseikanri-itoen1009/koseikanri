CREATE OR REPLACE PACKAGE BODY XXCOK015A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A03R(body)
 * Description      : 支払先の顧客より問合せがあった場合、
 *                    取引条件別の金額が印字された支払案内書を印刷します。
 * MD.050           : 支払案内書印刷（明細） MD050_COK_015_A03
 * Version          : 1.21
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  delete_xbsrw         出力対象ワーク削除(A-10)
 *  delete_xrbpd         ワークテーブルデータ削除(A-7)
 *  start_svf            SVF起動(A-6)
 *  update_xrbpd         支払案内書（明細）帳票ワークテーブル更新(A-5)
 *  get_xrbpd            ワークテーブル支払先毎集約データ取得(A-4)
 *  insert_xrbpd         データ取得(A-2)・ワークテーブルデータ登録(A-3)
 *  init                 初期処理(A-1)
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   K.Yamaguchi      新規作成
 *  2009/02/18    1.1   K.Yamaguchi      [障害COK_045] 最新の仕入先サイト情報を取得するよう変更
 *                                                     入力パラメータの書式を変更（YYYYMM => YYYY/MM）
 *  2009/03/03    1.2   M.Hiruta         [障害COK_067] 容器区分取得方法変更
 *  2009/05/11    1.3   K.Yamaguchi      [障害T1_0841] 支払額（税込）の取得方法を変更
 *                                       [障害T1_0866] 本振（案内書あり）の場合の抽出条件を変更
 *  2009/05/25    1.4   M.Hiruta         [障害T1_1168] 支払案内書(明細)の発行日をシステム日付から業務処理日付へ変更
 *  2009/09/10    1.5   S.Moriyama       [障害0000060] 住所の桁数変更対応
 *  2009/10/14    1.6   S.Moriyama       [変更依頼I_E_573] 仕入先名称、住所の設定内容変更対応
 *  2009/12/15    1.7   K.Nakamura       [障害E_本稼動_00477] 支払保留中のBM、また販売手数料が0円の場合は、出力しないよう修正
 *  2010/03/02    1.8   S.Moriyama       [障害E_本稼動_01299] 組み戻し後の本振残高出力対応
 *  2010/03/16    1.9   S.Moriyama       [障害E_本稼動_01897] 振込手数料出力対応
 *  2010/04/06    1.9   K.Yamaguchi      [障害E_本稼動_01897] 現金持参のシステムテストで発覚した障害
 *                                                            振込手数料負担者が設定されていない場合を考慮
 *  2011/01/05    1.10  S.Niki           [障害E_本稼動_01950] ソート順を本部コード、売上拠点コード、初回取引日、顧客コードに変更
 *  2011/03/28    1.11  S.Ochiai         [障害E_本稼動_05408,05409] 年次切替対応
 *  2017/12/29    1.12  K.Nara           [障害E_本稼動_14789] 事務センダー対応
 *  2018/01/18    1.13  K.Nara           [障害E_本稼動_14836] 事務センダー対応（本振案内書なし）
 *  2018/02/27    1.14  N.Watanabe       [障害E_本稼動_14897] 支払案内書PT対応
 *  2018/03/15    1.15  Y.Sekine         [障害E_本稼動_14900] 事務センター案件（支払案内書出力変更）
 *  2018/07/17    1.16  K.Nara           [障害E_本稼動_15005] 事務センター案件（支払案内書、販売報告書一括出力）
 *  2018/08/07    1.17  K.Nara           [障害E_本稼動_15202] 出力対象無し警告終了対応
 *  2018/11/15    1.18  E.Yazaki         [障害E_本稼動_15367]年号変更対応（営業・個別・販売）
 *  2019/08/08    1.19  Y.Koh            [障害E_本稼動_15784]
 *  2023/09/11    1.20  R.Oikawa         [障害E_本稼動_19179]【個別開発】インボイス対応（BM関連）
 *  2024/01/30    1.21  R.Oikawa         [障害E_本稼動_19496]グループ会社対応
 *
 *****************************************************************************************/
  --==================================================
  -- グローバル定数
  --==================================================
  -- パッケージ名
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK015A03R';
  -- アプリケーション短縮名
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
  cv_appl_short_name_gl            CONSTANT VARCHAR2(10)    := 'SQLGL';
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
  -- ステータス・コード
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- メッセージコード
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- 対象件数
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- 成功件数
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- エラー件数
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- 正常終了
-- Ver.1.17 [障害E_本稼動_15202] SCSK K.Nara ADD START
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- 警告終了
-- Ver.1.17 [障害E_本稼動_15202] SCSK K.Nara ADD END
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- エラー終了全ロールバック
  cv_msg_cok_00003                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00085                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00085';
  cv_msg_cok_00086                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00086';
  cv_msg_cok_00087                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00087';
  cv_msg_cok_00040                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00040';
  cv_msg_cok_10309                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-10309';
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  cv_msg_cok_10545                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-10545';
  cv_msg_cok_10546                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-10546';
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
  -- トークン
  cv_tkn_errmsg                    CONSTANT VARCHAR2(30)    := 'ERRMSG';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_base_code                 CONSTANT VARCHAR2(30)    := 'BASE_CODE';
  cv_tkn_target_ym                 CONSTANT VARCHAR2(30)    := 'TARGET_YM';
  cv_tkn_vendor_code               CONSTANT VARCHAR2(30)    := 'VENDOR_CODE';
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  cv_tkn_request_id                CONSTANT VARCHAR2(30)    := 'REQUEST_ID';
  cv_tkn_output_num                CONSTANT VARCHAR2(30)    := 'OUTPUT_NUM';
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
  -- セパレータ
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- プロファイル・オプション名
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_BM';   -- XXCOK:支払案内書_販売手数料見出し
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_EP';   -- XXCOK:支払案内書_電気料見出し
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'ORG_ID';                       -- MO: 営業単位
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
  cv_profile_name_04               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_FE';      -- XXCOK:支払案内書_振込手数料
  cv_profile_name_05               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF3_FEE';                 -- XXCOK:勘定科目_手数料
  cv_profile_name_06               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF4_TRANSFER_FEE';        -- XXCOK:補助科目_手数料_振込手数料
  cv_profile_name_07               CONSTANT VARCHAR2(50)    := 'XXCOK1_GL_CATEGORY_BM';           -- XXCOK:仕訳カテゴリ_販売手数料
  cv_profile_name_08               CONSTANT VARCHAR2(50)    := 'XXCOK1_GL_SOURCE_COK';            -- XXCOK:仕訳ソース_個別開発
  cv_profile_name_09               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_ID';                -- GL会計帳簿ID
  cv_profile_name_10               CONSTANT VARCHAR2(50)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION'; -- 銀行手数料_振込額基準
  cv_profile_name_11               CONSTANT VARCHAR2(50)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';  -- 銀行手数料_基準額未満
  cv_profile_name_12               CONSTANT VARCHAR2(50)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';  -- 銀行手数料_基準額以上
  cv_profile_name_13               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_TAX';                   -- 販売手数料_消費税率
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2017/12/29 Ver.1.12 [障害E_本稼動_14789] SCSK K.Nara ADD START
  cv_profile_name_14               CONSTANT VARCHAR2(50)    := 'XXCOK1_AFF2_DEPT_JIMU';           -- XXCOK:部門コード_事務センター
-- 2017/12/29 Ver.1.12 [障害E_本稼動_14789] SCSK K.Nara ADD END
  -- 参照タイプ名
-- Start 2009/03/03 M.Hiruta
--  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCMM_YOKI_KUBUN';    -- 容器区分
  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCSO1_SP_RULE_BOTTLE'; -- 容器区分
-- End   2009/03/03 M.Hiruta
  cv_lookup_type_02                CONSTANT VARCHAR2(30)    := 'XXCOK1_BM_CALC_TYPE';   -- 販手計算条件
-- 2019/08/08 Ver1.19 ADD Start
  cv_lookup_type_03                CONSTANT VARCHAR2(30)    := 'XXCOK1_TAX_INCLUDED_COMMENT'; -- 税込コメント
-- 2019/08/08 Ver1.19 ADD End
  -- 共通関数メッセージ出力区分
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- SVF起動パラメータ
  cv_file_id                       CONSTANT VARCHAR2(20)    := 'XXCOK015A03R';       -- 帳票ID
  cv_output_mode                   CONSTANT VARCHAR2(1)     := '1';                  -- 出力区分(PDF出力)
  cv_extension                     CONSTANT VARCHAR2(10)    := '.pdf';               -- 出力ファイル名拡張子(PDF出力)
  cv_frm_file                      CONSTANT VARCHAR2(20)    := 'XXCOK015A03S.xml';   -- フォーム様式ファイル名
  cv_vrq_file                      CONSTANT VARCHAR2(20)    := 'XXCOK015A03S.vrq';   -- クエリー様式ファイル名
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  cv_excl_code                     CONSTANT VARCHAR2(10)    := 'EXCL1';              -- SVF専用マネージャコード
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
  -- 書式フォーマット
  cv_format_fxrrrrmm               CONSTANT VARCHAR2(50)    := 'FXRRRR/MM';
  cv_format_fxrrrrmmdd             CONSTANT VARCHAR2(50)    := 'FXRRRRMMDD';
  cv_format_date                   CONSTANT VARCHAR2(50)    := 'RRRR"年"MM"月"DD"日"';
-- 2018/11/15 Ver.1.18 [障害E_本稼動_15367] SCSK E.Yazaki MOD START
--  cv_format_ee_month               CONSTANT VARCHAR2(50)    := 'EERR"年"MM"月分"';
--  cv_format_ee_date                CONSTANT VARCHAR2(50)    := 'EERR"年"MM"月"DD"日"';
  cv_format_yyyymm_month           CONSTANT VARCHAR2(50)    := 'YYYY"年"MM"月分"';
  cv_format_yyyymmdd_date          CONSTANT VARCHAR2(50)    := 'YYYY"年"MM"月"DD"日"';
  -- 各国語サポートパラメータ
--  cv_nls_param                     CONSTANT VARCHAR2(50)    := 'nls_calendar=''japanese imperial''';
-- 2018/11/15 Ver.1.18 [障害E_本稼動_15367] SCSK E.Yazaki MOD END
  -- BM支払区分
  cv_bm_type_1                     CONSTANT VARCHAR2(1)     := '1';                  -- 本振（案内有）
  cv_bm_type_2                     CONSTANT VARCHAR2(1)     := '2';                  -- 本振（案内無）
  cv_bm_type_3                     CONSTANT VARCHAR2(1)     := '3';                  -- AP支払
  cv_bm_type_4                     CONSTANT VARCHAR2(1)     := '4';                  -- 現金支払
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
  -- 銀行手数料負担者
  cv_bank_charge_bearer            CONSTANT VARCHAR2(1)     := 'I';                  -- 当方
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  ct_rep_id_bm                     CONSTANT xxcok_bm_sales_rep_work.output_rep%TYPE := 1;   -- 支払案内書
  ct_output_num_init               CONSTANT xxcok_bm_sales_rep_work.output_num%TYPE := -1;  -- カレント出力番号初期値
  cv_slash                         CONSTANT VARCHAR2(1)     := '/';
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
  cv_t_number                      CONSTANT VARCHAR2(30)    := 'XXCMM1_INVOICE_T_NO';              -- XXCMM:適格請求書発行事業者登録番号
  cv_profile_name_15               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_PROMPT_BM_SUM';   -- XXCOK:支払案内書_販売手数料計見出し
  cv_profile_name_16               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_TAX_FREE';        -- XXCOK:支払案内書_不課税
  cv_profile_name_17               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_TAX_RATE';        -- XXCOK:支払案内書_対象税率
  cv_profile_name_18               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_INC_TAX';         -- XXCOK:支払案内書_税込
  cv_profile_name_19               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_EX_TAX';          -- XXCOK:支払案内書_税抜
  cv_profile_name_20               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_TAX';             -- XXCOK:支払案内書_消費税
  cv_profile_name_21               CONSTANT VARCHAR2(50)    := 'XXCOK1_PAY_GUIDE_SALES_MFT';       -- XXCOK:支払案内書_販売手数料
  -- BM税区分
  cv_tax_type_1                    CONSTANT VARCHAR2(1)     := '1';                  -- 税込み
  cv_tax_type_2                    CONSTANT VARCHAR2(1)     := '2';                  -- 税抜き
  cv_tax_type_3                    CONSTANT VARCHAR2(1)     := '3';                  -- 非課税
  -- 税計算区分
  cv_tax_calc_type_1               CONSTANT VARCHAR2(1)     := '1';                  -- 案内書単位
  cv_tax_calc_type_2               CONSTANT VARCHAR2(1)     := '2';                  -- 明細単位
  cv_space                         CONSTANT VARCHAR2(1)     := ' ';                  -- スペース
  cv_msg_cok_10860                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-10860';
  cv_tkn_print_type                CONSTANT VARCHAR2(30)    := 'PRINT_TYPE';
  -- スナップタイミング
  cv_snapshot_timing_1             CONSTANT VARCHAR2(1)     := '1';                  -- 2営
  cv_snapshot_timing_2             CONSTANT VARCHAR2(1)     := '2';                  -- FB後
  -- 税率
  cv_ten                           CONSTANT VARCHAR2(2)     := '10';
-- Ver.1.20 ADD END
-- Ver.1.21 ADD START
  cv_flex_dept                     CONSTANT VARCHAR2(30)    := 'XX03_DEPARTMENT';            -- 部門
  cv_conv_company_code             CONSTANT VARCHAR2(30)    := 'XXCMM_CONV_COMPANY_CODE';    -- 会社コード変換
  cv_xxcmm_invoice_t_no            CONSTANT VARCHAR2(30)    := 'XXCMM_INVOICE_T_NO';         -- 適格請求書発行事業者情報
  cv_xml_format                    CONSTANT VARCHAR2(30)    := 'XXCOK1_XML_FORMAT';          -- 各社XMLフォーマット
  cv_msg_cok_00015                 CONSTANT VARCHAR2(20)    := 'APP-XXCOK1-00015';
  cv_tkn_lookup                    CONSTANT VARCHAR2(30)    := 'LOOKUP_VALUE_SET';
  cv_company_code                  CONSTANT VARCHAR2(3)     := '001';                        -- 会社コード：伊藤園
-- Ver.1.21 ADD END
  --==================================================
  -- グローバル変数
  --==================================================
  -- カウンタ
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- 対象件数
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- 正常件数
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- 異常件数
  -- 入力パラメータ
  gv_param_base_code               VARCHAR2(4)   DEFAULT NULL;  -- 問合せ先
  gv_param_target_ym               VARCHAR2(7)   DEFAULT NULL;  -- 案内書発行年月
  gv_param_vendor_code             VARCHAR2(9)   DEFAULT NULL;  -- 支払先
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  gn_param_request_id              NUMBER        DEFAULT NULL;  -- 要求ID
  gn_param_output_num              NUMBER        DEFAULT NULL;  -- 出力番号（対象取得検索時のみ使用）
  -- アップロード値
  gt_upload_cust_code              xxcok_bm_sales_rep_work.customer_code%TYPE  DEFAULT NULL;  -- 顧客
  gt_upload_output_num             xxcok_bm_sales_rep_work.output_num%TYPE     DEFAULT NULL;  -- 出力番号
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
  -- 初期処理取得値
  gd_process_date                  DATE          DEFAULT NULL;   -- 業務処理日付
  gn_org_id                        NUMBER        DEFAULT NULL;   -- 営業単位ID
  gv_prompt_bm                     VARCHAR2(100) DEFAULT NULL;   -- 支払案内書_販売手数料見出し
  gv_prompt_ep                     VARCHAR2(100) DEFAULT NULL;   -- 支払案内書_電気料見出し
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
  gv_prompt_fe                     VARCHAR2(100) DEFAULT NULL;                  -- 支払案内書_振込手数料
  gt_aff3_fee                      gl_code_combinations.segment3%TYPE;          -- 勘定科目：手数料
  gt_aff4_transfer_fee             gl_code_combinations.segment4%TYPE;          -- 補助科目：手数料-振込手数料
  gt_category_bm                   gl_je_categories.user_je_category_name%TYPE; -- 仕訳カテゴリ_販売手数料
  gt_source_cok                    gl_je_sources.user_je_source_name%TYPE;      -- 仕訳ソース_個別開発
  gt_set_of_books_id               gl_sets_of_books.set_of_books_id%TYPE;       -- 会計帳簿ID
  gn_bank_fee_trans                NUMBER;                                      -- 銀行手数料_振込額基準
  gn_bank_fee_less                 NUMBER;                                      -- 銀行手数料_基準額未満
  gn_bank_fee_more                 NUMBER;                                      -- 銀行手数料_基準額以上
  gn_bm_tax                        NUMBER;                                      -- 販売手数料_消費税率
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2017/12/29 Ver.1.12 [障害E_本稼動_14789] SCSK K.Nara ADD START
  gv_dept_jimu                     VARCHAR2(4);                                 -- 部門コード_事務センター
  gv_belong_base_cd                VARCHAR2(4);                                 -- 実行ユーザ所属拠点
-- 2017/12/29 Ver.1.12 [障害E_本稼動_14789] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
  gv_t_number                      VARCHAR2(14)  DEFAULT NULL;                  -- 登録番号
  gv_prompt_bm_sum                 VARCHAR2(50)  DEFAULT NULL;                  -- 支払案内書_販売手数料計見出し
  gv_tax_free                      VARCHAR2(20)  DEFAULT NULL;                  -- 支払案内書_不課税
  gv_tax_rate                      VARCHAR2(20)  DEFAULT NULL;                  -- 支払案内書_対象税率
  gv_inc_tax                       VARCHAR2(20)  DEFAULT NULL;                  -- 支払案内書_税込
  gv_ex_tax                        VARCHAR2(20)  DEFAULT NULL;                  -- 支払案内書_税抜
  gv_tax                           VARCHAR2(20)  DEFAULT NULL;                  -- 支払案内書_消費税
  gv_sales_mft                     VARCHAR2(20)  DEFAULT NULL;                  -- 支払案内書_販売手数料
  gv_param_target_yyyymm           VARCHAR2(6)   DEFAULT NULL;                  -- 案内書発行年月
-- Ver.1.20 ADD END
-- Ver.1.21 ADD START
  gd_company_reference_date        DATE;                                        -- 会社基準日
-- Ver.1.21 ADD END
  --==================================================
  -- グローバルカーソル
  --==================================================
  CURSOR g_summary_cur IS
    SELECT xrbpd.payment_code                     AS payment_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD START
         , xrbpd.contact_base_code                AS contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD END
         , SUM( xrbpd.selling_amt )               AS selling_amt_sum
         , gv_prompt_bm                           AS bm_index_1
         , SUM( CASE
                WHEN xrbpd.calc_type <> 50 THEN
                  xrbpd.backmargin
                END
           )                                      AS bm_amt_1
         , gv_prompt_ep                           AS bm_index_2
         , SUM( CASE
                WHEN xrbpd.calc_type = 50 THEN
                  xrbpd.backmargin
                END
           )                                      AS bm_amt_2
         , SUM( xrbpd.payment_amt_tax )           AS payment_amt_tax
         , MAX( xrbpd.closing_date )              AS closing_date
         , MIN( xrbpd.term_from_wk )              AS term_from
         , MAX( xrbpd.term_to_wk )                AS term_to
         , MAX( xrbpd.payment_date_wk )           AS payment_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
         , gv_prompt_fe                           AS bm_index_3
-- Ver.1.20 MOD START
--         , CASE WHEN xrbpd.org_slip_number IS NOT NULL THEN
---- Ver1.14 Mod Start
----               (SELECT SUM( NVL(gjl.entered_cr,0) - NVL(gjl.entered_dr,0) )
--               (SELECT /*+ INDEX( gjl GL_JE_LINES_N1 ) */
--                       SUM( NVL(gjl.entered_cr,0) - NVL(gjl.entered_dr,0) )
---- Ver1.14 Mod End
--                  FROM gl_sets_of_books     gsob
--                      ,gl_je_sources        gjs
--                      ,gl_je_categories     gjc
--                      ,gl_je_headers        gjh
--                      ,gl_je_lines          gjl
--                      ,gl_code_combinations gcc
--                      ,gl_period_statuses   gps
--                      ,fnd_application      fa
--                 WHERE gsob.set_of_books_id      = gt_set_of_books_id
--                   AND gjs.user_je_source_name   = gt_source_cok
--                   AND gjc.user_je_category_name = gt_category_bm
--                   AND gjs.language              = userenv('LANG')
--                   AND gjs.source_lang           = gjs.language
--                   AND gjs.source_lang           = gjc.language
--                   AND gjs.source_lang           = gjc.source_lang
--                   AND gsob.set_of_books_id      = gjh.set_of_books_id
--                   AND gjs.je_source_name        = gjh.je_source
--                   AND gjh.je_header_id          = gjl.je_header_id
--                   AND gjl.code_combination_id   = gcc.code_combination_id
--                   AND gcc.segment3              = gt_aff3_fee
--                   AND gcc.segment4              = gt_aff4_transfer_fee
--                   AND gjl.attribute7            = xrbpd.payment_code
--                   AND gjl.attribute3            = xrbpd.org_slip_number
--                   AND xrbpd.payment_date_wk     BETWEEN gps.start_date AND gps.end_date
--                   AND gps.set_of_books_id       = gsob.set_of_books_id
--                   AND gps.period_name           = gjh.period_name
---- Ver1.14 Add Start
--                   AND gps.period_name           = gjl.period_name
---- Ver1.14 Add End
--                   AND fa.application_short_name = cv_appl_short_name_gl
--                   AND fa.application_id         = gps.application_id
--               )
--           ELSE CASE WHEN xrbpd.bank_charge_bearer = cv_bank_charge_bearer THEN 0
--                     WHEN xrbpd.balance_cancel_date IS NOT NULL THEN 0
--                ELSE(SELECT CASE WHEN SUM( CASE WHEN xrbpd2.calc_type <> 50
--                                                 AND xrbpd2.balance_cancel_date IS NULL THEN xrbpd2.backmargin
--                                           ELSE 0 END
--                                         + CASE WHEN xrbpd2.calc_type =  50
--                                                 AND xrbpd2.balance_cancel_date IS NULL THEN xrbpd2.backmargin
--                                           ELSE 0 END
--                                         ) < gn_bank_fee_trans THEN gn_bank_fee_less
--                            ELSE gn_bank_fee_more END
--                       FROM xxcok_rep_bm_pg_detail xrbpd2
--                      WHERE xrbpd2.payment_code    = xrbpd.payment_code
--                        AND xrbpd2.payment_date_wk = xrbpd.payment_date_wk
--                    )
--                END
--           END * ( 1 + gn_bm_tax / 100 )          AS bm_amt_3
         , 0       AS bm_amt_3
-- Ver.1.20 MOD END
         , xrbpd.org_slip_number
         , xrbpd.payment_date_wk
         , xrbpd.bank_charge_bearer
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
         , xrbpd.output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
         , CASE
           WHEN pvsa.attribute8 IS NOT NULL AND pvsa.attribute9 IS NOT NULL THEN
             pvsa.attribute8 || pvsa.attribute9
           END                                    AS payment_t_no
         , SUM( xrbpd.selling_amt )               AS sales_amt_sum
         , gv_prompt_bm                           AS bm_index_name1
         , gv_prompt_ep                           AS bm_index_name2
         , gv_prompt_bm_sum                       AS bm_index_name3
         , gv_prompt_fe                           AS bm_index_name4
         , CASE xrbpd.tax_type
           WHEN cv_tax_type_3 THEN
             gv_tax_free
           ELSE
             gn_bm_tax || gv_tax_rate
           END                                    AS tax_type1
         , CASE xrbpd.tax_type
           WHEN cv_tax_type_3 THEN
             gv_tax_free
           ELSE
             gn_bm_tax || gv_tax_rate
           END                                    AS tax_type2
         , CASE xrbpd.tax_type
           WHEN cv_tax_type_3 THEN
             gv_tax_free
           ELSE
             gn_bm_tax || gv_tax_rate
           END                                    AS tax_type3
         , gn_bm_tax || gv_tax_rate               AS tax_type4       -- 振込手数料
         , NULL                                   AS tax_type5       -- お支払金額
         , SUM( CASE
                  WHEN xrbpd.calc_type <> 50 THEN
                    xrbpd.bm_amt1
                  END
              )                                   AS bm_sum_amt1_1   -- 1列1行目
         , SUM( CASE
                   WHEN xrbpd.calc_type = 50 THEN
                     xrbpd.bm_amt1
                   END
               )                                  AS bm_sum_amt1_2   -- 1列2行目
         , SUM( CASE
                  WHEN xrbpd.calc_type <> 50 THEN
                    xrbpd.bm_amt2
                  END
             )                                    AS bm_sum_amt2_1   -- 2列1行目
         , SUM( CASE
                  WHEN xrbpd.calc_type = 50 THEN
                    xrbpd.bm_amt2
                  END
             )                                    AS bm_sum_amt2_2   -- 2列2行目
         , SUM( CASE
                  WHEN xrbpd.calc_type <> 50 THEN
                    xrbpd.bm_amt3
                  END
             )                                    AS bm_sum_amt3_1   -- 3列1行目
         , SUM( CASE
                  WHEN xrbpd.calc_type = 50 THEN
                    xrbpd.bm_amt3
                  END
             )                                    AS bm_sum_amt3_2   -- 3列2行目
         , xrbpd.payment_type                     AS payment_type
         , xrbpd.tax_type                         AS tax_type
         , xrbpd.tax_calc_type                    AS tax_calc_type
-- Ver.1.20 ADD END
    FROM xxcok_rep_bm_pg_detail    xrbpd
-- Ver.1.20 ADD START
       , po_vendors               pv   -- 仕入先マスタ
       , po_vendor_sites_all      pvsa -- 仕入先サイトマスタ
-- Ver.1.20 ADD END
    WHERE xrbpd.request_id = cn_request_id
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
      AND xrbpd.output_num = gt_upload_output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
      AND xrbpd.payment_code   = pv.segment1
      AND pv.vendor_id         = pvsa.vendor_id
      AND pvsa.org_id          = gn_org_id
-- Ver.1.20 ADD END
    GROUP BY xrbpd.payment_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD START
            ,xrbpd.contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
            ,xrbpd.org_slip_number
            ,xrbpd.payment_date_wk
            ,xrbpd.bank_charge_bearer
            ,xrbpd.balance_cancel_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
            ,xrbpd.output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
            , CASE
              WHEN pvsa.attribute8 IS NOT NULL AND pvsa.attribute9 IS NOT NULL THEN
                pvsa.attribute8 || pvsa.attribute9
              END
            ,xrbpd.payment_type
            ,xrbpd.tax_type
            ,xrbpd.tax_calc_type
-- Ver.1.20 ADD END
    ;
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  --アップロード出力対象取得
  CURSOR g_upload_cur IS
    SELECT xbsrw.output_num                    AS output_num
          ,xbsrw.target_ym                     AS target_ym
          ,xbsrw.vendor_code                   AS vendor_code
          ,xbsrw.customer_code                 AS customer_code
    FROM  xxcok_bm_sales_rep_work    xbsrw
    WHERE xbsrw.request_id = gn_param_request_id
    AND   xbsrw.output_num = NVL(gn_param_output_num, xbsrw.output_num)
    AND   xbsrw.output_rep = ct_rep_id_bm
    ORDER BY xbsrw.output_num
    ;
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
  --==================================================
  -- グローバルコレクション型変数
  --==================================================
  TYPE g_summary_ttype             IS TABLE OF g_summary_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_summary_tab                    g_summary_ttype;
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  TYPE g_upload_ttype             IS TABLE OF g_upload_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_upload_tab                    g_upload_ttype;
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
  --==================================================
  -- 共通例外
  --==================================================
  --*** 処理部共通例外 ***
  global_process_expt              EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                  EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt           EXCEPTION;
  --==================================================
  -- 例外
  --==================================================
  --*** エラー終了 ***
  error_proc_expt                  EXCEPTION;
--
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  /**********************************************************************************
   * Procedure Name   : delete_xbsrw
   * Description      : 出力対象ワーク削除(A-10)
   ***********************************************************************************/
  PROCEDURE delete_xbsrw(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xbsrw';     -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR lock_xbsrw_cur
    IS
      SELECT 'X'
      FROM xxcok_bm_sales_rep_work    xbsrw
      WHERE xbsrw.request_id = gn_param_request_id
      AND   xbsrw.output_num = NVL(gn_param_output_num, xbsrw.output_num)
      AND   xbsrw.output_rep = ct_rep_id_bm
      FOR UPDATE OF xbsrw.output_num NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ロック取得
    --==================================================
    OPEN  lock_xbsrw_cur;
    CLOSE lock_xbsrw_cur;
    --==================================================
    -- ワークテーブルデータ削除
    --==================================================
    DELETE
    FROM xxcok_bm_sales_rep_work    xbsrw
    WHERE xbsrw.request_id = gn_param_request_id
    AND   xbsrw.output_num = NVL(gn_param_output_num, xbsrw.output_num)
    AND   xbsrw.output_rep = ct_rep_id_bm
    ;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END delete_xbsrw;
--
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
  /**********************************************************************************
   * Procedure Name   : delete_xrbpd
   * Description      : ワークテーブルデータ削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xrbpd';     -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    --==================================================
    -- ローカルカーソル
    --==================================================
    CURSOR lock_xrbpd_cur
    IS
      SELECT 'X'
      FROM xxcok_rep_bm_pg_detail  xrbpd
      WHERE xrbpd.request_id = cn_request_id
      FOR UPDATE OF xrbpd.payment_code NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ロック取得
    --==================================================
    OPEN  lock_xrbpd_cur;
    CLOSE lock_xrbpd_cur;
    --==================================================
    -- ワークテーブルデータ削除
    --==================================================
    DELETE
    FROM xxcok_rep_bm_pg_detail  xrbpd
    WHERE xrbpd.request_id = cn_request_id
    ;
    --==================================================
    -- 成功件数取得
    --==================================================
    gn_target_cnt := SQL%ROWCOUNT;
    gn_normal_cnt := SQL%ROWCOUNT;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END delete_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF起動(A-6)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'start_svf';     -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    lv_date                        VARCHAR2(8)    DEFAULT NULL;                 -- 出力ファイル名用日付
    lv_file_name                   VARCHAR2(100)  DEFAULT NULL;                 -- 出力ファイル名
-- Ver.1.21 ADD START
    lv_contact_base_code           xxcok_rep_bm_pg_detail.contact_base_code%TYPE;  -- 連絡先拠点コード
    lv_company_code                VARCHAR2(3)   DEFAULT NULL;                     -- 会社コード
    lv_frm_file                    VARCHAR2(20)  DEFAULT NULL;                     -- フォーム様式ファイル名
-- Ver.1.21 ADD END
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- システム日付型変換
    --==================================================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    --==================================================
    -- 出力ファイル名(帳票ID + YYYYMMDD + 要求ID)
    --==================================================
    lv_file_name := cv_file_id
                 || TO_CHAR( SYSDATE, cv_format_fxrrrrmmdd )
                 || TO_CHAR( cn_request_id )
                 || cv_extension
                 ;
-- Ver.1.21 ADD START
    --==================================================
    -- 出力フォーマットを決めるため連絡先拠点を取得
    --==================================================
    BEGIN
      SELECT xrbpd.contact_base_code
      INTO   lv_contact_base_code
      FROM   xxcok_rep_bm_pg_detail xrbpd
      WHERE  xrbpd.request_id   = cn_request_id
      AND    rownum = 1
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_contact_base_code := NULL;
    END;
    --==================================================
    -- 連絡先拠点が取得できない場合は対象データなし
    --==================================================
    IF ( lv_contact_base_code IS NULL ) THEN
      lv_frm_file := cv_frm_file;   -- デフォルトのフォーム様式
    ELSE
      --==================================================
      -- クイックコード取得(適格請求書発行事業者登録番号)
      --==================================================
      BEGIN
        SELECT flv2.lookup_code                  -- 会社コード
              ,flv2.meaning                      -- T番号
        INTO   lv_company_code
              ,gv_t_number
        FROM   fnd_flex_value_sets ffvs          -- 値セット定義マスタ
              ,fnd_flex_values     ffv           -- 値セット値定義マスタ
              ,fnd_lookup_values   flv           -- 会社コード変換
              ,fnd_lookup_values   flv2          -- 適格請求書発行事業者情報
        WHERE
               ffvs.flex_value_set_id   = ffv.flex_value_set_id
        AND    ffvs.flex_value_set_name = cv_flex_dept
        AND    ffv.flex_value           = lv_contact_base_code
        AND    flv.lookup_type          = cv_conv_company_code
        AND    flv.attribute1           = NVL(ffv.attribute10,cv_company_code)
        AND    flv.language             = USERENV( 'LANG' )
        AND    gd_company_reference_date BETWEEN NVL( flv.start_date_active, gd_company_reference_date )
                                 AND     NVL( flv.end_date_active, gd_company_reference_date )
        AND    flv2.lookup_type         = cv_xxcmm_invoice_t_no
        AND    flv2.lookup_code         = flv.attribute2
        AND    flv2.language            = USERENV( 'LANG' )
        AND    gd_company_reference_date BETWEEN NVL( flv2.start_date_active, gd_company_reference_date )
                                 AND     NVL( flv2.end_date_active, gd_company_reference_date )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00015
                      , iv_token_name1          => cv_tkn_lookup
                      , iv_token_value1         => cv_xxcmm_invoice_t_no
                      );
        RAISE error_proc_expt;
      END;
--
      --==================================================
      -- 帳票ワークテーブル更新(登録番号（伊藤園）)
      --==================================================
      BEGIN
        UPDATE xxcok_rep_bm_pg_detail xrbpd
        SET    xrbpd.invoice_t_no = gv_t_number
        WHERE  xrbpd.request_id   = cn_request_id
        ;
        -- コミット
        COMMIT;
      END;
--
      --==================================================
      -- フォーム様式ファイル名を会社ごとに切り替える
      --==================================================
      BEGIN
        SELECT flv.attribute1                  -- XMLフォーマット
        INTO   lv_frm_file
        FROM   fnd_lookup_values   flv         -- 各会社XMLフォーマット
        WHERE  flv.lookup_type   = cv_xml_format
        AND    flv.lookup_code   = lv_company_code
        AND    flv.language      = USERENV( 'LANG' )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00015
                      , iv_token_name1          => cv_tkn_lookup
                      , iv_token_value1         => cv_xml_format
                      );
        RAISE error_proc_expt;
      END;
    END IF;
-- Ver.1.21 ADD END
    --==================================================
    -- SVFコンカレント起動
    --==================================================
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--    xxccp_svfcommon_pkg.submit_svf_request(
    xxccp_svfcommon_excl_pkg.submit_svf_request(
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
      ov_errbuf                => lv_errbuf                 -- エラーバッファ
    , ov_retcode               => lv_retcode                -- リターンコード
    , ov_errmsg                => lv_errmsg                 -- エラーメッセージ
    , iv_conc_name             => cv_pkg_name               -- コンカレント名
    , iv_file_name             => lv_file_name              -- 出力ファイル名
    , iv_file_id               => cv_file_id                -- 帳票ID
    , iv_output_mode           => cv_output_mode            -- 出力区分
-- Ver.1.21 MOD START
--    , iv_frm_file              => cv_frm_file               -- フォーム様式ファイル名
    , iv_frm_file              => lv_frm_file               -- フォーム様式ファイル名
-- Ver.1.21 MOD END
    , iv_vrq_file              => cv_vrq_file               -- クエリー様式ファイル名
    , iv_org_id                => NULL                      -- ORG_ID
    , iv_user_name             => fnd_global.user_name      -- ログイン・ユーザ名
    , iv_resp_name             => fnd_global.resp_name      -- ログイン・ユーザ職責名
    , iv_doc_name              => NULL                      -- 文書名
    , iv_printer_name          => NULL                      -- プリンタ名
    , iv_request_id            => TO_CHAR( cn_request_id )  -- 要求ID
    , iv_nodata_msg            => NULL                      -- データなしメッセージ
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
    , iv_excl_code             => cv_excl_code              -- SVF専用マネージャコード
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cok
                    , iv_name         => cv_msg_cok_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_outmsg
                    , in_new_line => 0
                    );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
-- Ver.1.21 ADD START
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
-- Ver.1.21 ADD END
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END start_svf;
--
  /**********************************************************************************
   * Procedure Name   : update_xrbpd
   * Description      : 支払案内書（明細）帳票ワークテーブル更新(A-5)
   ***********************************************************************************/
  PROCEDURE update_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xrbpd';     -- プログラム名
-- Ver.1.20 ADD START
    cv_down                        CONSTANT VARCHAR2(4)  := 'DOWN';
    --セパレータ
    cv_sepa_period   CONSTANT VARCHAR2(1)  := '.';  -- ピリオド
    cv_sepa_colon    CONSTANT VARCHAR2(1)  := ':';  -- コロン
-- Ver.1.20 ADD END
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
-- Ver.1.20 ADD START
    ln_bm_sum_amt1_3               xxcok_rep_bm_pg_detail.bm_sum_amt1_3%TYPE;         -- 編集用合計手数料1_3
    ln_bm_sum_amt1_4               xxcok_rep_bm_pg_detail.bm_sum_amt1_4%TYPE;         -- 編集用合計手数料1_4
    ln_bm_sum_amt1_subtotal        xxcok_rep_bm_pg_detail.bm_sum_amt1_subtotal%TYPE;  -- 編集用合計手数料1小計
    ln_bm_sum_amt2_3               xxcok_rep_bm_pg_detail.bm_sum_amt2_3%TYPE;         -- 編集用合計手数料2_3
    ln_bm_sum_amt2_4               xxcok_rep_bm_pg_detail.bm_sum_amt2_4%TYPE;         -- 編集用合計手数料2_4
    ln_bm_sum_amt2_subtotal        xxcok_rep_bm_pg_detail.bm_sum_amt2_subtotal%TYPE;  -- 編集用合計手数料2小計
    ln_bm_sum_amt3_3               xxcok_rep_bm_pg_detail.bm_sum_amt3_3%TYPE;         -- 編集用合計手数料3_3
    ln_bm_sum_amt3_4               xxcok_rep_bm_pg_detail.bm_sum_amt3_4%TYPE;         -- 編集用合計手数料3_4
    ln_bm_sum_amt3_subtotal        xxcok_rep_bm_pg_detail.bm_sum_amt3_subtotal%TYPE;  -- 編集用合計手数料3小計
    ln_payment_amt_sum             xxcok_rep_bm_pg_detail.payment_amt_sum%TYPE;       -- お支払金額
    lv_total_title_name1           xxcok_rep_bm_pg_detail.total_title_name1%TYPE;     -- 合計欄タイトル(左)
    lv_total_title_name2           xxcok_rep_bm_pg_detail.total_title_name2%TYPE;     -- 合計欄タイトル(中)
    lv_total_title_name3           xxcok_rep_bm_pg_detail.total_title_name3%TYPE;     -- 合計欄タイトル(右)
    lv_bm_title1                   xxcok_rep_bm_pg_detail.bm_title1%TYPE;             -- 明細欄タイトル(左)
    lv_bm_title2                   xxcok_rep_bm_pg_detail.bm_title2%TYPE;             -- 明細欄タイトル(中)
    lv_bm_title3                   xxcok_rep_bm_pg_detail.bm_title3%TYPE;             -- 明細欄タイトル(右)
    ln_sales_amt_left              xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 販売手数料の合計額(左)
    ln_sales_amt_center            xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 販売手数料の合計額(中)
    ln_sales_amt_right             xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 販売手数料の合計額(右)
    ln_electric_amt_left           xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 電気料の合計額(左)
    ln_electric_amt_center         xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 電気料の合計額(中)
    ln_electric_amt_right          xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 電気料の合計額(右)
    ln_sales_amt_sum_left          xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 販売手数料計(左)
    ln_sales_amt_sum_center        xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 販売手数料計(中)
    ln_sales_amt_sum_right         xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 販売手数料計(右)
    ln_mft_left                    xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 振込手数料(左)
    ln_mft_center                  xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 振込手数料(中)
    ln_mft_right                   xxcok_rep_bm_pg_detail.bm_sum_amt1_1%TYPE;         -- 振込手数料(右)
-- Ver.1.20 ADD END
    --==================================================
    -- ローカル例外
    --==================================================
    --*** エラー終了 ***
    error_proc_expt                EXCEPTION;
-- Ver.1.20 ADD START
    recalc_pay_amt_err_expt        EXCEPTION;          -- 支払金額再計算エラー例外
    calc_bank_trans_fee_err_expt   EXCEPTION;          -- 振込手数料算出エラー例外
-- Ver.1.20 ADD END
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 支払先毎集約データ件数分ループ
    --==================================================
    << g_summary_tab_loop >>
    FOR i IN 1 .. g_summary_tab.COUNT LOOP
-- Ver.1.20 ADD START
      --==================================================
      -- 販売手数料計、振込手数料、お支払金額算出
      --==================================================
      -- 変数クリア
      ln_bm_sum_amt1_3        := NULL;
      ln_bm_sum_amt1_4        := NULL;
      ln_bm_sum_amt1_subtotal := NULL;
      ln_bm_sum_amt2_3        := NULL;
      ln_bm_sum_amt2_4        := NULL;
      ln_bm_sum_amt2_subtotal := NULL;
      ln_bm_sum_amt3_3        := NULL;
      ln_bm_sum_amt3_4        := NULL;
      ln_bm_sum_amt3_subtotal := NULL;
      ln_payment_amt_sum      := NULL;
      lv_total_title_name1    := NULL;
      lv_total_title_name2    := NULL;
      lv_total_title_name3    := NULL;
      lv_bm_title1            := NULL;
      lv_bm_title2            := NULL;
      lv_bm_title3            := NULL;
      ln_sales_amt_left       := NULL;
      ln_sales_amt_center     := NULL;
      ln_sales_amt_right      := NULL;
      ln_electric_amt_left    := NULL;
      ln_electric_amt_center  := NULL;
      ln_electric_amt_right   := NULL;
      ln_sales_amt_sum_left   := NULL;
      ln_sales_amt_sum_center := NULL;
      ln_sales_amt_sum_right  := NULL;
      ln_mft_left             := NULL;
      ln_mft_center           := NULL;
      ln_mft_right            := NULL;
--
      --==================================================
      -- 支払金額再計算
      --==================================================
      xxcok_common_pkg.recalc_pay_amt_p(
        ov_errbuf               => lv_errbuf                                 -- エラー・バッファ
      , ov_retcode              => lv_retcode                                -- リターンコード
      , ov_errmsg               => lv_errmsg                                 -- エラー・メッセージ
      , iv_pay_kbn              => g_summary_tab(i).payment_type             -- 支払区分（1:本振−WEB・ハガキ／2:本振−案内書なし／その他）
      , iv_tax_calc_kbn         => g_summary_tab(i).tax_calc_type            -- 税計算区分（1:案内書単位／2:明細単位）
      , iv_tax_kbn              => g_summary_tab(i).tax_type                 -- 税区分（1:税込み／2:税抜き／3:非課税）
      , iv_tax_rounding_rule    => cv_down                                   -- 端数処理区分（NEAREST:四捨五入／UP:切上げ／DOWN:切捨て）
      , in_tax_rate             => gn_bm_tax                                 -- 税率
      , in_pay_amt_no_tax       => ( NVL( g_summary_tab(i).bm_sum_amt2_1, 0) + NVL( g_summary_tab(i).bm_sum_amt2_2, 0) )   -- 支払金額（税抜）
      , in_pay_amt_tax          => ( NVL( g_summary_tab(i).bm_sum_amt3_1, 0) + NVL( g_summary_tab(i).bm_sum_amt3_2, 0) )   -- 支払金額（消費税）
      , in_pay_amt_with_tax     => ( NVL( g_summary_tab(i).bm_sum_amt1_1, 0) + NVL( g_summary_tab(i).bm_sum_amt1_2, 0) )   -- 支払金額（税込）
      , on_pay_amt_no_tax       => ln_bm_sum_amt2_3                          -- 算出後支払金額（税抜）
      , on_pay_amt_tax          => ln_bm_sum_amt3_3                          -- 算出後支払金額（消費税）
      , on_pay_amt_with_tax     => ln_bm_sum_amt1_3                          -- 算出後支払金額（税込）
      );
      --
      -- リターンコード判定
      IF ( lv_retcode = cv_status_normal ) THEN
        --==================================================
        -- 振込手数料算出
        --==================================================
        xxcok_common_pkg.calc_bank_trans_fee_p(
          ov_errbuf                   => lv_errbuf                           -- エラー・バッファ
        , ov_retcode                  => lv_retcode                          -- リターンコード
        , ov_errmsg                   => lv_errmsg                           -- エラー・メッセージ
        , in_bank_trans_amt           => ln_bm_sum_amt1_3                    -- 振込額
        , in_base_amt                 => gn_bank_fee_trans                   -- 基準額
        , in_fee_less_base_amt        => gn_bank_fee_less                    -- 基準額未満手数料
        , in_fee_more_base_amt        => gn_bank_fee_more                    -- 基準額以上手数料
        , in_fee_tax_rate             => gn_bm_tax                           -- 手数料税率
        , iv_bank_charge_bearer       => g_summary_tab(i).bank_charge_bearer -- 振込手数料負担者
        , on_bank_trans_fee_no_tax    => ln_bm_sum_amt2_4                    -- 振込手数料（税抜）
        , on_bank_trans_fee_tax       => ln_bm_sum_amt3_4                    -- 振込手数料（消費税）
        , on_bank_trans_fee_with_tax  => ln_bm_sum_amt1_4                    -- 振込手数料（税込）
        );
        -- リターンコード判定
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- 「正常」以外の場合
          RAISE calc_bank_trans_fee_err_expt;
        END IF;
      ELSE
        -- 「正常」以外の場合
        RAISE recalc_pay_amt_err_expt;
      END IF;
--
      -- 更新項目編集(税込み/税抜き/非課税)
      IF g_summary_tab(i).tax_type = cv_tax_type_1 THEN                      -- 税込み
        lv_total_title_name1     := gv_inc_tax;                              -- 合計欄タイトル(左)
        lv_total_title_name2     := gv_ex_tax;                               -- 合計欄タイトル(中)
        lv_total_title_name3     := gv_tax;                                  -- 合計欄タイトル(右)
        lv_bm_title1             := gv_sales_mft || cv_space || gv_ex_tax;   -- 明細欄タイトル(左)
        lv_bm_title2             := gv_tax;                                  -- 明細欄タイトル(中)
        lv_bm_title3             := gv_inc_tax;                              -- 明細欄タイトル(右)
        ln_sales_amt_left        := g_summary_tab(i).bm_sum_amt1_1;          -- 販売手数料の合計額(左)
        ln_sales_amt_center      := g_summary_tab(i).bm_sum_amt2_1;          -- 販売手数料の合計額(中)
        ln_sales_amt_right       := g_summary_tab(i).bm_sum_amt3_1;          -- 販売手数料の合計額(右)
        ln_electric_amt_left     := g_summary_tab(i).bm_sum_amt1_2;          -- 電気料の合計額(左)
        ln_electric_amt_center   := g_summary_tab(i).bm_sum_amt2_2;          -- 電気料の合計額(中)
        ln_electric_amt_right    := g_summary_tab(i).bm_sum_amt3_2;          -- 電気料の合計額(右)
        ln_sales_amt_sum_left    := ln_bm_sum_amt1_3;                        -- 販売手数料計(左)
        ln_sales_amt_sum_center  := ln_bm_sum_amt2_3;                        -- 販売手数料計(中)
        ln_sales_amt_sum_right   := ln_bm_sum_amt3_3;                        -- 販売手数料計(右)
        ln_mft_left              := ln_bm_sum_amt1_4;                        -- 振込手数料(左)
        ln_mft_center            := ln_bm_sum_amt2_4;                        -- 振込手数料(中)
        ln_mft_right             := ln_bm_sum_amt3_4;                        -- 振込手数料(右)
        ln_bm_sum_amt1_subtotal  := ln_bm_sum_amt1_3 - ln_bm_sum_amt1_4;     -- お支払金額(左)
        ln_bm_sum_amt2_subtotal  := ln_bm_sum_amt2_3 - ln_bm_sum_amt2_4;     -- お支払金額(中)
        ln_bm_sum_amt3_subtotal  := ln_bm_sum_amt3_3 - ln_bm_sum_amt3_4;     -- お支払金額(右)
        ln_payment_amt_sum       := ln_bm_sum_amt1_subtotal;                 -- お支払金額
      ELSIF g_summary_tab(i).tax_type IN (cv_tax_type_2,cv_tax_type_3) THEN  -- 税抜き/非課税
        lv_total_title_name1     := gv_ex_tax;                               -- 合計欄タイトル(左)
        lv_total_title_name2     := gv_tax;                                  -- 合計欄タイトル(中)
        lv_total_title_name3     := gv_inc_tax;                              -- 合計欄タイトル(右)
        lv_bm_title1             := gv_sales_mft || cv_space || gv_ex_tax;   -- 明細欄タイトル(左)
        lv_bm_title2             := gv_tax;                                  -- 明細欄タイトル(中)
        lv_bm_title3             := gv_inc_tax;                              -- 明細欄タイトル(右)
        ln_sales_amt_left        := g_summary_tab(i).bm_sum_amt2_1;          -- 販売手数料の合計額(左)
        ln_sales_amt_center      := g_summary_tab(i).bm_sum_amt3_1;          -- 販売手数料の合計額(中)
        ln_sales_amt_right       := g_summary_tab(i).bm_sum_amt1_1;          -- 販売手数料の合計額(右)
        ln_electric_amt_left     := g_summary_tab(i).bm_sum_amt2_2;          -- 電気料の合計額(左)
        ln_electric_amt_center   := g_summary_tab(i).bm_sum_amt3_2;          -- 電気料の合計額(中)
        ln_electric_amt_right    := g_summary_tab(i).bm_sum_amt1_2;          -- 電気料の合計額(右)
        ln_sales_amt_sum_left    := ln_bm_sum_amt2_3;                        -- 販売手数料計(左)
        ln_sales_amt_sum_center  := ln_bm_sum_amt3_3;                        -- 販売手数料計(中)
        ln_sales_amt_sum_right   := ln_bm_sum_amt1_3;                        -- 販売手数料計(右)
        ln_mft_left              := ln_bm_sum_amt2_4;                        -- 振込手数料(左)
        ln_mft_center            := ln_bm_sum_amt3_4;                        -- 振込手数料(中)
        ln_mft_right             := ln_bm_sum_amt1_4;                        -- 振込手数料(右)
        ln_bm_sum_amt1_subtotal  := ln_bm_sum_amt2_3 - ln_bm_sum_amt2_4;     -- お支払金額(左)
        ln_bm_sum_amt2_subtotal  := ln_bm_sum_amt3_3 - ln_bm_sum_amt3_4;     -- お支払金額(中)
        ln_bm_sum_amt3_subtotal  := ln_bm_sum_amt1_3 - ln_bm_sum_amt1_4;     -- お支払金額(右)
        ln_payment_amt_sum       := ln_bm_sum_amt3_subtotal;                 -- お支払金額
      END IF;
--
      -- 更新項目編集(案内書単位)
      IF g_summary_tab(i).tax_calc_type = cv_tax_calc_type_1 THEN
        lv_bm_title1             :=   NULL;             -- 明細欄タイトル(左)
        lv_bm_title2             :=   NULL;             -- 明細欄タイトル(中)
        lv_bm_title3             :=   gv_sales_mft;     -- 明細欄タイトル(右)
        ln_sales_amt_center      :=   NULL;             -- 販売手数料の合計額(中)
        ln_sales_amt_right       :=   NULL;             -- 販売手数料の合計額(右)
        ln_electric_amt_center   :=   NULL;             -- 電気料の合計額(中)
        ln_electric_amt_right    :=   NULL;             -- 電気料の合計額(右)
      END IF;
-- Ver.1.20 ADD END
      --==================================================
      -- 帳票ワークテーブル更新
      --==================================================
      UPDATE xxcok_rep_bm_pg_detail     xrbpd
      SET xrbpd.selling_amt_sum    = g_summary_tab(i).selling_amt_sum
        , xrbpd.bm_index_1         = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0 THEN
                                       g_summary_tab(i).bm_index_1
                                     ELSE
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama UPD START
--                                       g_summary_tab(i).bm_index_2
                                       CASE WHEN g_summary_tab(i).bm_amt_2 > 0 THEN
                                         g_summary_tab(i).bm_index_2
                                       ELSE g_summary_tab(i).bm_index_3
                                       END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama UPD END
                                     END
        , xrbpd.bm_amt_1           = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0 THEN
                                       g_summary_tab(i).bm_amt_1
                                     ELSE
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama UPD START
--                                       g_summary_tab(i).bm_amt_2
                                       CASE WHEN g_summary_tab(i).bm_amt_2 > 0 THEN
                                         g_summary_tab(i).bm_amt_2
                                       ELSE g_summary_tab(i).bm_amt_3
                                       END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama UPD END
                                     END
        , xrbpd.bm_index_2         = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0
                                      AND g_summary_tab(i).bm_amt_2 > 0 THEN
                                       g_summary_tab(i).bm_index_2
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama UPD START
--                                     ELSE
--                                       NULL
                                     ELSE
                                       CASE WHEN(g_summary_tab(i).bm_amt_1 > 0
                                                 OR g_summary_tab(i).bm_amt_2 > 0)
                                             AND g_summary_tab(i).bm_amt_3 > 0 THEN
                                              g_summary_tab(i).bm_index_3
                                       ELSE NULL
                                       END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama UPD END
                                     END
        , xrbpd.bm_amt_2           = CASE
                                     WHEN g_summary_tab(i).bm_amt_1 > 0
                                      AND g_summary_tab(i).bm_amt_2 > 0 THEN
                                       g_summary_tab(i).bm_amt_2
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama UPD START
--                                     ELSE
--                                       NULL
                                     ELSE
                                       CASE WHEN(g_summary_tab(i).bm_amt_1 > 0
                                                 OR g_summary_tab(i).bm_amt_2 > 0)
                                             AND g_summary_tab(i).bm_amt_3 > 0 THEN
                                              g_summary_tab(i).bm_amt_3 * -1
                                       ELSE NULL
                                       END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama UPD END
                                     END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama UPD START
--        , xrbpd.payment_amt_tax    = g_summary_tab(i).payment_amt_tax
        , xrbpd.payment_amt_tax    = g_summary_tab(i).payment_amt_tax - NVL(g_summary_tab(i).bm_amt_3 , 0)
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama UPD END
-- 2018/11/15 Ver.1.18 [障害E_本稼動_15367] SCSK E.Yazaki MOD START
        , xrbpd.target_month       = TO_CHAR( g_summary_tab(i).closing_date
--                                            , cv_format_ee_month
--                                            , cv_nls_param )
                                            , cv_format_yyyymm_month )
        , xrbpd.term_from          = TO_CHAR( g_summary_tab(i).term_from
--                                            , cv_format_ee_date
--                                            , cv_nls_param )
                                            , cv_format_yyyymmdd_date )
        , xrbpd.term_to            = TO_CHAR( g_summary_tab(i).term_to
--                                            , cv_format_ee_date
--                                            , cv_nls_param )
                                            , cv_format_yyyymmdd_date )
        , xrbpd.payment_date       = TO_CHAR( g_summary_tab(i).payment_date
--                                            , cv_format_ee_date
--                                            , cv_nls_param )
                                            , cv_format_yyyymmdd_date )
-- 2018/11/15 Ver.1.18 [障害E_本稼動_15367] SCSK E.Yazaki MOD END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
        , xrbpd.bm_index_3         = CASE WHEN g_summary_tab(i).bm_amt_1 > 0
                                           AND g_summary_tab(i).bm_amt_2 > 0
                                           AND g_summary_tab(i).bm_amt_3 > 0 THEN
                                          g_summary_tab(i).bm_index_3
                                     ELSE NULL END
        , xrbpd.bm_amt_3           = CASE WHEN g_summary_tab(i).bm_amt_1 > 0
                                           AND g_summary_tab(i).bm_amt_2 > 0
                                           AND g_summary_tab(i).bm_amt_3 > 0 THEN
                                          g_summary_tab(i).bm_amt_3 * -1
                                     ELSE NULL END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2019/08/08 Ver1.19 ADD Start
        , xrbpd.tax_included_comment = ( SELECT flv.MEANING
                                         FROM   fnd_lookup_values flv
                                         WHERE flv.lookup_type  = cv_lookup_type_03
                                           AND flv.language     = USERENV( 'LANG' )
                                           AND flv.enabled_flag = 'Y'
                                           AND g_summary_tab(i).closing_date BETWEEN to_date(flv.ATTRIBUTE1,'YYYY/MM/DD') and to_date(flv.ATTRIBUTE2,'YYYY/MM/DD')
                                       ) 
-- 2019/08/08 Ver1.19 ADD End
-- Ver.1.20 ADD START
        , xrbpd.invoice_t_no       = gv_t_number
        , xrbpd.payment_t_no       = g_summary_tab(i).payment_t_no
        , xrbpd.payment_amt_sum    = ln_payment_amt_sum
        , xrbpd.sales_amt_sum      = g_summary_tab(i).sales_amt_sum
        , total_title_name1        = lv_total_title_name1                         -- 合計欄タイトル(左)
        , total_title_name2        = lv_total_title_name2                         -- 合計欄タイトル(中)
        , total_title_name3        = lv_total_title_name3                         -- 合計欄タイトル(右)
        , bm_title1                = lv_bm_title1                                 -- 明細欄タイトル(左)
        , bm_title2                = lv_bm_title2                                 -- 明細欄タイトル(中)
        , bm_title3                = lv_bm_title3                                 -- 明細欄タイトル(右)
        -- 合計欄1行目
        , xrbpd.bm_index_name1     = CASE
                                     WHEN ln_sales_amt_left > 0 THEN
                                       g_summary_tab(i).bm_index_name1
                                     ELSE
                                       CASE WHEN ln_electric_amt_left > 0 THEN
                                         g_summary_tab(i).bm_index_name2
                                       END
                                     END
        , xrbpd.tax_type1          = CASE
                                     WHEN ln_sales_amt_left > 0 THEN
                                       g_summary_tab(i).tax_type1
                                     ELSE
                                       CASE WHEN ln_electric_amt_left > 0 THEN
                                         g_summary_tab(i).tax_type2
                                       END
                                     END
        , xrbpd.bm_sum_amt1_1      = CASE
                                     WHEN ln_sales_amt_left > 0 THEN
                                       ln_sales_amt_left
                                     ELSE
                                       CASE WHEN ln_electric_amt_left > 0 THEN
                                         ln_electric_amt_left
                                       END
                                     END
        , xrbpd.bm_sum_amt2_1      = CASE
                                     WHEN ln_sales_amt_left > 0 THEN
                                       ln_sales_amt_center
                                     ELSE
                                       CASE WHEN ln_electric_amt_left > 0 THEN
                                         ln_electric_amt_center
                                       END
                                     END
        , xrbpd.bm_sum_amt3_1      = CASE
                                     WHEN ln_sales_amt_left > 0 THEN
                                       ln_sales_amt_right
                                     ELSE
                                       CASE WHEN ln_electric_amt_left > 0 THEN
                                         ln_electric_amt_right
                                       END
                                     END
        -- 合計欄2行目
        , xrbpd.bm_index_name2     = CASE
                                     WHEN ln_sales_amt_left > 0
                                      AND ln_electric_amt_left > 0 THEN
                                       g_summary_tab(i).bm_index_name2
                                     END
        , xrbpd.tax_type2          = CASE
                                     WHEN ln_sales_amt_left > 0
                                      AND ln_electric_amt_left > 0 THEN
                                       g_summary_tab(i).tax_type2
                                     END
        , xrbpd.bm_sum_amt1_2      = CASE
                                     WHEN ln_sales_amt_left > 0
                                      AND ln_electric_amt_left > 0 THEN
                                        ln_electric_amt_left
                                     END
        , xrbpd.bm_sum_amt2_2      = CASE
                                     WHEN ln_sales_amt_left > 0
                                      AND ln_electric_amt_left > 0 THEN
                                        ln_electric_amt_center
                                     END
        , xrbpd.bm_sum_amt3_2      = CASE
                                     WHEN ln_sales_amt_left > 0
                                      AND ln_electric_amt_left > 0 THEN
                                        ln_electric_amt_right
                                     END
        -- 合計欄3行目
        , xrbpd.bm_index_name3     = CASE
                                     WHEN ln_sales_amt_sum_left > 0 THEN
                                        g_summary_tab(i).bm_index_name3
                                     END
        , xrbpd.tax_type3          = CASE
                                     WHEN ln_sales_amt_sum_left > 0 THEN
                                        g_summary_tab(i).tax_type3
                                     END
        , xrbpd.bm_sum_amt1_3      = CASE
                                     WHEN ln_sales_amt_sum_left > 0 THEN
                                        ln_sales_amt_sum_left
                                     END
        , xrbpd.bm_sum_amt2_3      = CASE
                                     WHEN ln_sales_amt_sum_left > 0 THEN
                                        ln_sales_amt_sum_center
                                     END
        , xrbpd.bm_sum_amt3_3      = CASE
                                     WHEN ln_sales_amt_sum_left > 0 THEN
                                        ln_sales_amt_sum_right
                                     END
        -- 合計欄4行目
        , xrbpd.bm_index_name4     = CASE
                                     WHEN ln_mft_left > 0 THEN
                                        g_summary_tab(i).bm_index_name4
                                     END
        , xrbpd.tax_type4          = CASE
                                     WHEN ln_mft_left > 0 THEN
                                        g_summary_tab(i).tax_type4
                                     END
        , xrbpd.bm_sum_amt1_4      = CASE
                                     WHEN ln_mft_left > 0 THEN
                                        ln_mft_left * -1
                                     END
        , xrbpd.bm_sum_amt2_4      = CASE
                                     WHEN ln_mft_center > 0 THEN
                                        ln_mft_center * -1
                                     END
        , xrbpd.bm_sum_amt3_4      = CASE
                                     WHEN ln_mft_right > 0 THEN
                                        ln_mft_right * -1
                                     END
        -- 明細欄金額(左)
        , xrbpd.bm_amt1            = CASE
                                     WHEN g_summary_tab(i).tax_calc_type = cv_tax_calc_type_1 THEN             -- 案内書単位
                                       NULL
                                     WHEN g_summary_tab(i).tax_calc_type = cv_tax_calc_type_2 THEN             -- 明細単位
                                       xrbpd.bm_amt2
                                     END
        -- 明細欄金額(中)
        , xrbpd.bm_amt2            = CASE
                                     WHEN g_summary_tab(i).tax_calc_type = cv_tax_calc_type_1 THEN             -- 案内書単位
                                       NULL
                                     WHEN g_summary_tab(i).tax_calc_type = cv_tax_calc_type_2 THEN             -- 明細単位
                                       xrbpd.bm_amt3
                                     END
        -- 明細欄金額(右)
        , xrbpd.bm_amt3            = CASE
                                     WHEN g_summary_tab(i).tax_calc_type = cv_tax_calc_type_1 THEN             -- 案内書単位
                                       CASE WHEN g_summary_tab(i).tax_type = cv_tax_type_1    THEN             -- 税込み
                                         xrbpd.bm_amt1
                                       WHEN g_summary_tab(i).tax_type IN (cv_tax_type_2,cv_tax_type_3)   THEN  -- 税抜き/非課税
                                         xrbpd.bm_amt2
                                       END
                                     WHEN g_summary_tab(i).tax_calc_type = cv_tax_calc_type_2 THEN             -- 明細単位
                                       xrbpd.bm_amt1
                                     END
        -- お支払金額
        , xrbpd.tax_type5            = g_summary_tab(i).tax_type5
        , xrbpd.bm_sum_amt1_subtotal = ln_bm_sum_amt1_subtotal
        , xrbpd.bm_sum_amt2_subtotal = ln_bm_sum_amt2_subtotal
        , xrbpd.bm_sum_amt3_subtotal = ln_bm_sum_amt3_subtotal
-- Ver.1.20 ADD END
      WHERE xrbpd.request_id       = cn_request_id
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
        AND xrbpd.output_num       = gt_upload_output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
        AND xrbpd.payment_code     = g_summary_tab(i).payment_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD START
        AND xrbpd.contact_base_code = g_summary_tab(i).contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD END
-- 2010/04/06 Ver.1.9 [障害E_本稼動_01897] SCS K.Yamaguchi UPD START
---- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
--        AND NVL(xrbpd.org_slip_number,'X') = NVL(g_summary_tab(i).org_slip_number,'X')
--        AND xrbpd.payment_date_wk    = g_summary_tab(i).payment_date_wk
--        AND xrbpd.bank_charge_bearer = g_summary_tab(i).bank_charge_bearer
---- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
        AND (    ( xrbpd.org_slip_number                  = g_summary_tab(i).org_slip_number            )
              OR ( xrbpd.org_slip_number IS NULL        AND g_summary_tab(i).org_slip_number IS NULL    )
            )
        AND (    ( xrbpd.payment_date_wk                  = g_summary_tab(i).payment_date_wk            )
              OR ( xrbpd.payment_date_wk IS NULL        AND g_summary_tab(i).payment_date_wk IS NULL    )
            )
        AND (    ( xrbpd.bank_charge_bearer               = g_summary_tab(i).bank_charge_bearer         )
              OR ( xrbpd.bank_charge_bearer IS NULL     AND g_summary_tab(i).bank_charge_bearer IS NULL )
            )
-- 2010/04/06 Ver.1.9 [障害E_本稼動_01897] SCS K.Yamaguchi UPD END
      ;
    END LOOP;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
-- Ver.1.20 ADD START
    -- 支払金額再計算エラー
    WHEN recalc_pay_amt_err_expt THEN
      ov_errbuf  := SUBSTRB(  lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- 振込手数料算出エラー
    WHEN calc_bank_trans_fee_err_expt THEN
      ov_errbuf  := SUBSTRB(  lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
-- Ver.1.20 ADD END
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : get_xrbpd
   * Description      : ワークテーブル支払先毎集約データ取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_xrbpd';        -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    --==================================================
    -- ローカル例外
    --==================================================
    --*** エラー終了 ***
    error_proc_expt                EXCEPTION;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 支払先毎集約データ取得
    --==================================================
    OPEN  g_summary_cur;
    FETCH g_summary_cur BULK COLLECT INTO g_summary_tab;
    CLOSE g_summary_cur;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : insert_xrbpd
   * Description      : データ取得(A-2)・ワークテーブルデータ登録(A-3)
   ***********************************************************************************/
  PROCEDURE insert_xrbpd(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xrbpd';     -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 本振（案内有）
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- 支払先コード
    , publication_date                 -- 発行日
    , payment_zip_code                 -- 支払先郵便番号
    , payment_addr_1                   -- 支払先住所1
    , payment_addr_2                   -- 支払先住所2
    , payment_name_1                   -- 支払先宛名1
    , payment_name_2                   -- 支払先宛名2
    , contact_base                     -- 地区コード（連絡先拠点）
    , contact_base_code                -- 連絡先拠点コード
    , contact_base_name                -- 連絡先拠点名
    , contact_addr_1                   -- 連絡先住所1
    , contact_addr_2                   -- 連絡先住所2
    , contact_phone_no                 -- 連絡先電話番号
    , selling_amt_sum                  -- 販売金額合計
    , bm_index_1                       -- 合計見出し1
    , bm_amt_1                         -- 合計手数料1
    , bm_index_2                       -- 合計見出し2
    , bm_amt_2                         -- 合計手数料2
    , payment_amt_tax                  -- 支払金額（税込）
    , closing_date                     -- 締め日
    , term_from_wk                     -- 対象期間（From）_ワーク
    , term_to_wk                       -- 対象期間（To）_ワーク
    , payment_date_wk                  -- お支払日_ワーク
    , cust_code                        -- 顧客コード
    , cust_name                        -- 顧客名
    , selling_base                     -- 地区コード（売上計上拠点）
    , selling_base_code                -- 売上計上拠点コード
    , selling_base_name                -- 売上計上拠点名
    , calc_type                        -- 計算条件
    , calc_type_sort                   -- 計算条件ソート順
    , container_type_code              -- 容器区分コード
    , selling_price                    -- 売価
    , detail_name                      -- 明細名
    , selling_amt                      -- 販売金額
    , selling_qty                      -- 販売数量
    , backmargin                       -- 販売手数料
    , created_by                       -- 作成者
    , creation_date                    -- 作成日
    , last_updated_by                  -- 最終更新者
    , last_update_date                 -- 最終更新日
    , last_update_login                -- 最終更新ログイン
    , request_id                       -- 要求ID
    , program_application_id           -- コンカレント・プログラム・アプリケーションID
    , program_id                       -- コンカレント・プログラムID
    , program_update_date              -- プログラム更新日
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
    , bm_index_3                       -- 合計見出し3
    , bm_amt_3                         -- 合計手数料3
    , org_slip_number                  -- 元伝票番号
    , bank_charge_bearer               -- 手数料負担者
    , balance_cancel_date              -- 残高取消日
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
    , start_tran_date                  -- 初回取引日
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
    , output_num                       -- 出力番号
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
    , bm_amt1                          -- 販売手数料1
    , bm_amt2                          -- 販売手数料2
    , bm_amt3                          -- 販売手数料3
    , payment_type                     -- 支払区分
    , tax_type                         -- 税区分
    , tax_calc_type                    -- 税計算区分
-- Ver.1.20 ADD END
    )
-- Ver.1.20 MOD START
--    SELECT xbb.supplier_code                                    AS payment_code
    SELECT /*+ LEADING(xbb xcbs)
               USE_NL(xcbs)
               USE_NL(pv)
               USE_NL(pvsa)
               USE_NL(hca1)
               USE_NL(hca2)
               USE_NL(hca3)
               USE_NL(flv1)
               USE_NL(flv2)
               USE_NL(xbbs1)
               USE_NL(xbbs2)
               */
           xbb.supplier_code                                    AS payment_code
-- Ver.1.20 MOD END
-- Start 2009/05/25 Ver_1.4 T1_1168 M.Hiruta
--         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
-- End   2009/05/25 Ver_1.4 T1_1168 M.Hiruta
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , pvsa.zip                                             AS payment_zip_code
--         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
--         , pvsa.address_line2                                   AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD START
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 1 , 20 )  AS payment_addr_1
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 21, 20 )  AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 20 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 21, 20 )                     AS payment_name_2
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD START
--         , hca2.contact_area_code                               AS contact_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
              WHERE   xdv.flex_value  = hca2.contact_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD END
         , hca2.contact_code                                    AS contact_base_code
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca2.contact_name                                    AS contact_base_name
--         , hca2.contact_address1                                AS contact_addr_1
--         , hca2.contact_address2                                AS contact_addr_2
--         , hca2.contact_phone_num                               AS contact_phone_no
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [障害T1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [障害T1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR START
--         , MAX( xbb.expect_payment_date )                       AS payment_date
         , MAX( xbb.publication_date )                          AS payment_date
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR END
         , xcbs.delivery_cust_code                              AS cust_code
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca1.cust_name                                       AS cust_name
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS selling_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = xcbs.base_code
              WHERE   xdv.flex_value  = hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS selling_base
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_code                                       AS selling_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS selling_base_name
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
-- Ver.1.20 MOD START
--         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , NVL(xbbs2.bank_charge_bearer,
             NVL(xbbs1.bank_charge_bearer, pvsa.bank_charge_bearer
             )
           )                                                    AS bank_charge_bearer
-- Ver.1.20 MOD END
         , xbb.balance_cancel_date                              AS balance_cancel_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
         , hca1.start_tran_date                                 AS start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                ELSE
                  xcbs.cond_bm_amt_tax
                END
              )                                                 AS bm_amt1
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_no_tax
                ELSE
                  xcbs.cond_bm_amt_no_tax
                END
              )                                                 AS bm_amt2
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_tax_amt
                ELSE
                  xcbs.cond_tax_amt
                END
              )                                                 AS bm_amt3
         , NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 ))                        AS payment_type  -- 支払区分
         , NVL(xbbs2.bm_tax_kbn, NVL(xbbs1.bm_tax_kbn, NVL(pvsa.attribute6,cv_tax_type_1)))            AS tax_type      -- 税区分
         , NVL(xbbs2.tax_calc_kbn, NVL(xbbs1.tax_calc_kbn, NVL(pvsa.attribute10,cv_tax_calc_type_2)))  AS tax_calc_type -- 税計算区分
-- Ver.1.20 ADD END
    FROM xxcok_cond_bm_support    xcbs -- 条件別販手販協テーブル
       , xxcok_backmargin_balance xbb  -- 販手残高テーブル
       , po_vendors               pv   -- 仕入先マスタ
       , po_vendor_sites_all      pvsa -- 仕入先サイトマスタ
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
                , xca.start_tran_date            AS start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_parties                  hp        -- パーティマスタ
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
              , xxcmm_cust_accounts         xca       -- 顧客アドオン
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
           WHERE hca.party_id        = hp.party_id
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
             AND xca.customer_id     = hca.cust_account_id
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--                ,    hl.state
--                  || hl.city 
--                  || hl.address1                 AS contact_address1
--                , hl.address2                    AS contact_address2
                ,    hl.city 
                  || hl.address1
                  || hl.address2                 AS contact_address1
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
-- Ver.1.20 ADD START
       , xxcok_bm_balance_snap    xbbs1 -- 販手残高SNAP(2営)
       , xxcok_bm_balance_snap    xbbs2 -- 販手残高SNAP(FB後)
-- Ver.1.20 ADD END
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--      AND xcbs.base_code               = hca3.base_code
      AND xbb.base_code                = hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND pvsa.attribute5              = hca2.contact_code
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
-- Ver.1.20 DEL START
--      AND pvsa.attribute4              = cv_bm_type_1
-- Ver.1.20 DEL END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      AND pvsa.attribute5              = gv_param_base_code
      AND pvsa.attribute5              = NVL( gv_param_base_code, pvsa.attribute5 )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR START
---- 2009/05/11 Ver.1.3 [障害T1_0866] SCS K.Yamaguchi REPAIR START
----      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
----                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
--      AND (    (     xbb.fb_interface_status      = '0'
--                 AND xbb.fb_interface_date       IS NULL
--                 AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
--                                                AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
--               )
--            OR
--               (     xbb.fb_interface_status      = '1'
--                 AND xbb.fb_interface_date  BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
--                                                AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
--               )
--          )
---- 2009/05/11 Ver.1.3 [障害T1_0866] SCS K.Yamaguchi REPAIR END
      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR END
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD START
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD END
-- Ver.1.20 ADD START
      AND xbb.balance_cancel_date IS NULL
      AND xbbs1.bm_balance_id(+)       = xbb.bm_balance_id
      AND xbbs1.snapshot_create_ym(+)  = gv_param_target_yyyymm
      AND xbbs1.snapshot_timing(+)     = cv_snapshot_timing_1   -- 2営
      AND xbbs2.bm_balance_id(+)       = xbb.bm_balance_id
      AND xbbs2.snapshot_create_ym(+)  = gv_param_target_yyyymm
      AND xbbs2.snapshot_timing(+)     = cv_snapshot_timing_2   -- FB後
      AND pvsa.attribute4              IS NOT NULL
      AND NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 )) = cv_bm_type_1
      AND 1 = 1
-- Ver.1.20 ADD END
    GROUP BY xbb.supplier_code
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
           , xbb.publication_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
           , pvsa.zip
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--           , pvsa.state || pvsa.city || pvsa.address_line1
--           , pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 15 )
--           , SUBSTR( pv.vendor_name, 16     )
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD START
--           , pvsa.city || pvsa.address_line1 || pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 20 )
--           , SUBSTR( pv.vendor_name, 21, 20 )
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
           , hca2.contact_area_code
           , hca2.contact_code
           , hca2.contact_name
           , hca2.contact_address1
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama DEL START
--           , hca2.contact_address2
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama DEL END
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--           , xcbs.base_code
           , hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
           , xbb.org_slip_number
-- Ver.1.20 MOD START
--           , pvsa.bank_charge_bearer
           , NVL(xbbs2.bank_charge_bearer,
               NVL(xbbs1.bank_charge_bearer, pvsa.bank_charge_bearer
               )
             )
-- Ver.1.20 MOD END
           , xbb.balance_cancel_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
           , hca1.start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD START
-- Ver.1.20 ADD START
           , NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 ))
           , NVL(xbbs2.bm_tax_kbn, NVL(xbbs1.bm_tax_kbn, NVL(pvsa.attribute6,cv_tax_type_1)))
           , NVL(xbbs2.tax_calc_kbn, NVL(xbbs1.tax_calc_kbn, NVL(pvsa.attribute10,cv_tax_calc_type_2)))
-- Ver.1.20 ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END 
                ) <> 0
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD END
-- 2018/03/15 Ver.1.15 [障害E_本稼動_14900] SCSK Y.Sekine ADD START
    UNION ALL
-- Ver.1.20 MOD START
--    SELECT xbb.supplier_code                                    AS payment_code
    SELECT /*+ LEADING(xbb xcbs)
               USE_NL(xcbs)
               USE_NL(pv)
               USE_NL(pvsa)
               USE_NL(hca1)
               USE_NL(hca2)
               USE_NL(hca3)
               USE_NL(flv1)
               USE_NL(flv2)
               USE_NL(xbbs1)
               USE_NL(xbbs2)
               */
           xbb.supplier_code                                    AS payment_code
-- Ver.1.20 MOD END
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
              WHERE   xdv.flex_value  = hca2.contact_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
         , hca2.contact_code                                    AS contact_base_code
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date     -- お支払日
         , xcbs.delivery_cust_code                              AS cust_code
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
              WHERE   xdv.flex_value  = hca3.base_code
                AND   ROWNUM = 1
           )                                                    AS selling_base
         , hca3.base_code                                       AS selling_base_code
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , xbb.balance_cancel_date                              AS balance_cancel_date
         , hca1.start_tran_date                                 AS start_tran_date
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                ELSE
                  xcbs.cond_bm_amt_tax
                END
              )                                                 AS bm_amt1
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_no_tax
                ELSE
                  xcbs.cond_bm_amt_no_tax
                END
              )                                                 AS bm_amt2
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_tax_amt
                ELSE
                  xcbs.cond_tax_amt
                END
              )                                                 AS bm_amt3
         , pvsa.attribute4                                      AS payment_type  -- 支払区分
         , NVL(pvsa.attribute6,cv_tax_type_1)                   AS tax_type      -- 税区分
         , NVL(xbbs1.tax_calc_kbn, NVL(pvsa.attribute10,cv_tax_calc_type_2))  AS tax_calc_type -- 税計算区分
-- Ver.1.20 ADD END
    FROM xxcok_cond_bm_support    xcbs -- 条件別販手販協テーブル
       , xxcok_backmargin_balance xbb  -- 販手残高テーブル
       , po_vendors               pv   -- 仕入先マスタ
       , po_vendor_sites_all      pvsa -- 仕入先サイトマスタ
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
                , xca.start_tran_date            AS start_tran_date
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_parties                  hp        -- パーティマスタ
              , xxcmm_cust_accounts         xca       -- 顧客アドオン
           WHERE hca.party_id        = hp.party_id
             AND xca.customer_id     = hca.cust_account_id
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city 
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
       , ( SELECT flv.attribute1                 AS container_type_code
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
-- Ver.1.20 ADD START
       , xxcok_bm_balance_snap    xbbs1 -- 販手残高SNAP(2営)
-- Ver.1.20 ADD END
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xbb.base_code                = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND pvsa.attribute5              = hca2.contact_code
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_1
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      AND pvsa.attribute5              = gv_param_base_code
      AND pvsa.attribute5              = NVL( gv_param_base_code, pvsa.attribute5 )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
      AND xbb.expect_payment_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
      AND gv_belong_base_cd            = gv_dept_jimu   -- 実行ユーザの所属部門が事務センタ
      AND xbb.publication_date         IS NULL          -- 販手残高テーブル．案内書発効日がNULL
-- Ver.1.20 ADD START
      AND xbb.balance_cancel_date IS NULL
      AND xbbs1.bm_balance_id(+)       = xbb.bm_balance_id
      AND xbbs1.snapshot_create_ym(+)  = gv_param_target_yyyymm
      AND xbbs1.snapshot_timing(+)     = cv_snapshot_timing_1   -- 2営
      AND pvsa.attribute4              IS NOT NULL
      AND 2 = 2
-- Ver.1.20 ADD END
    GROUP BY xbb.supplier_code
           , xbb.publication_date
           , pvsa.zip
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
           , hca2.contact_area_code
           , hca2.contact_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , hca3.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
           , hca1.start_tran_date
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
           , pvsa.attribute4
           , NVL(pvsa.attribute6,cv_tax_type_1)
           , NVL(xbbs1.tax_calc_kbn, NVL(pvsa.attribute10,cv_tax_calc_type_2))
-- Ver.1.20 ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END 
                ) <> 0
-- 2018/03/15 Ver.1.15 [障害E_本稼動_14900] SCSK Y.Sekine ADD END
    ;
    --==================================================
    -- 本振（案内無）
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- 支払先コード
    , publication_date                 -- 発行日
    , payment_zip_code                 -- 支払先郵便番号
    , payment_addr_1                   -- 支払先住所1
    , payment_addr_2                   -- 支払先住所2
    , payment_name_1                   -- 支払先宛名1
    , payment_name_2                   -- 支払先宛名2
    , contact_base                     -- 地区コード（連絡先拠点）
    , contact_base_code                -- 連絡先拠点コード
    , contact_base_name                -- 連絡先拠点名
    , contact_addr_1                   -- 連絡先住所1
    , contact_addr_2                   -- 連絡先住所2
    , contact_phone_no                 -- 連絡先電話番号
    , selling_amt_sum                  -- 販売金額合計
    , bm_index_1                       -- 合計見出し1
    , bm_amt_1                         -- 合計手数料1
    , bm_index_2                       -- 合計見出し2
    , bm_amt_2                         -- 合計手数料2
    , payment_amt_tax                  -- 支払金額（税込）
    , closing_date                     -- 締め日
    , term_from_wk                     -- 対象期間（From）_ワーク
    , term_to_wk                       -- 対象期間（To）_ワーク
    , payment_date_wk                  -- お支払日_ワーク
    , cust_code                        -- 顧客コード
    , cust_name                        -- 顧客名
    , selling_base                     -- 地区コード（売上計上拠点）
    , selling_base_code                -- 売上計上拠点コード
    , selling_base_name                -- 売上計上拠点名
    , calc_type                        -- 計算条件
    , calc_type_sort                   -- 計算条件ソート順
    , container_type_code              -- 容器区分コード
    , selling_price                    -- 売価
    , detail_name                      -- 明細名
    , selling_amt                      -- 販売金額
    , selling_qty                      -- 販売数量
    , backmargin                       -- 販売手数料
    , created_by                       -- 作成者
    , creation_date                    -- 作成日
    , last_updated_by                  -- 最終更新者
    , last_update_date                 -- 最終更新日
    , last_update_login                -- 最終更新ログイン
    , request_id                       -- 要求ID
    , program_application_id           -- コンカレント・プログラム・アプリケーションID
    , program_id                       -- コンカレント・プログラムID
    , program_update_date              -- プログラム更新日
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
    , bm_index_3                       -- 合計見出し3
    , bm_amt_3                         -- 合計手数料3
    , org_slip_number                  -- 元伝票番号
    , bank_charge_bearer               -- 手数料負担者
    , balance_cancel_date              -- 残高取消日
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
    , start_tran_date                  -- 初回取引日
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
    , output_num                       -- 出力番号
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
    , bm_amt1                          -- 販売手数料1
    , bm_amt2                          -- 販売手数料2
    , bm_amt3                          -- 販売手数料3
    , payment_type                     -- 支払区分
    , tax_type                         -- 税区分
    , tax_calc_type                    -- 税計算区分
-- Ver.1.20 ADD END
    )
-- Ver.1.20 MOD START
--    SELECT xbb.supplier_code                                    AS payment_code
    SELECT /*+ LEADING(xbb xcbs)
               USE_NL(xcbs)
               USE_NL(pv)
               USE_NL(pvsa)
               USE_NL(hca1)
               USE_NL(hca2)
               USE_NL(hca3)
               USE_NL(flv1)
               USE_NL(flv2)
               USE_NL(xbbs1)
               USE_NL(xbbs2)
               */
           xbb.supplier_code                                    AS payment_code
-- Ver.1.20 MOD END
-- Start 2009/05/25 Ver_1.4 T1_1168 M.Hiruta
--         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
-- End   2009/05/25 Ver_1.4 T1_1168 M.Hiruta
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , pvsa.zip                                             AS payment_zip_code
--         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
--         , pvsa.address_line2                                   AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD START
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 1 , 20 )  AS payment_addr_1
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 21, 20 )  AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 20 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 21, 20 )                     AS payment_name_2
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD START
--         , hca2.contact_area_code                               AS contact_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
              WHERE   xdv.flex_value  = hca2.contact_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD END
         , hca2.contact_code                                    AS contact_base_code
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca2.contact_name                                    AS contact_base_name
--         , hca2.contact_address1                                AS contact_addr_1
--         , hca2.contact_address2                                AS contact_addr_2
--         , hca2.contact_phone_num                               AS contact_phone_no
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [障害T1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [障害T1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR START
--         , MAX( xbb.expect_payment_date )                       AS payment_date
         , MAX( xbb.publication_date )                          AS payment_date
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR END
         , xcbs.delivery_cust_code                              AS cust_code
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca1.cust_name                                       AS cust_name
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS selling_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = xcbs.base_code
              WHERE   xdv.flex_value  = hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS selling_base
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_code                                       AS selling_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS selling_base_name
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
-- Ver.1.20 MOD START
--         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , NVL(xbbs2.bank_charge_bearer,
             NVL(xbbs1.bank_charge_bearer, pvsa.bank_charge_bearer
             )
           )                                                    AS bank_charge_bearer
-- Ver.1.20 MOD END
         , xbb.balance_cancel_date                              AS balance_cancel_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
         , hca1.start_tran_date                                 AS start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                ELSE
                  xcbs.cond_bm_amt_tax
                END
              )                                                 AS bm_amt1
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_no_tax
                ELSE
                  xcbs.cond_bm_amt_no_tax
                END
              )                                                 AS bm_amt2
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_tax_amt
                ELSE
                  xcbs.cond_tax_amt
                END
              )                                                 AS bm_amt3
         , NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 ))                        AS payment_type  -- 支払区分
         , NVL(xbbs2.bm_tax_kbn, NVL(xbbs1.bm_tax_kbn, NVL(pvsa.attribute6,cv_tax_type_1)))            AS tax_type      -- 税区分
         , NVL(xbbs2.tax_calc_kbn, NVL(xbbs1.tax_calc_kbn, NVL(pvsa.attribute10,cv_tax_calc_type_2)))  AS tax_calc_type -- 税計算区分
-- Ver.1.20 ADD END
    FROM xxcok_cond_bm_support    xcbs -- 条件別販手販協テーブル
       , xxcok_backmargin_balance xbb  -- 販手残高テーブル
       , po_vendors               pv   -- 仕入先マスタ
       , po_vendor_sites_all      pvsa -- 仕入先サイトマスタ
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
                , xca.start_tran_date            AS start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_parties                  hp        -- パーティマスタ
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
              , xxcmm_cust_accounts         xca       -- 顧客アドオン
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
           WHERE hca.party_id        = hp.party_id
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
             AND xca.customer_id     = hca.cust_account_id
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--                ,    hl.state
--                  || hl.city 
--                  || hl.address1                 AS contact_address1
--                , hl.address2                    AS contact_address2
                ,    hl.city 
                  || hl.address1
                  || hl.address2                 AS contact_address1
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
               , flv.meaning                     AS container_type_name
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
-- Ver.1.20 ADD START
       , xxcok_bm_balance_snap    xbbs1 -- 販手残高SNAP(2営)
       , xxcok_bm_balance_snap    xbbs2 -- 販手残高SNAP(FB後)
-- Ver.1.20 ADD END
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--      AND xcbs.base_code               = hca3.base_code
      AND xbb.base_code                = hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND pvsa.attribute5              = hca2.contact_code
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
-- Ver.1.20 DEL START
--      AND pvsa.attribute4              = cv_bm_type_2
-- Ver.1.20 DEL END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      AND pvsa.attribute5              = gv_param_base_code
      AND pvsa.attribute5              = NVL( gv_param_base_code, pvsa.attribute5 )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR START
--      AND xbb.fb_interface_date  BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
--                                      AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR END
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- 2009/05/11 Ver.1.3 [障害T1_0866] SCS K.Yamaguchi REPAIR START
--      AND xbb.edi_interface_status     = '1'
      AND xbb.fb_interface_status      = '1'
-- 2009/05/11 Ver.1.3 [障害T1_0866] SCS K.Yamaguchi REPAIR END
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD START
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD END
-- Ver.1.20 ADD START
      AND xbb.balance_cancel_date IS NULL
      AND xbbs1.bm_balance_id(+)       = xbb.bm_balance_id
      AND xbbs1.snapshot_create_ym(+)  = gv_param_target_yyyymm
      AND xbbs1.snapshot_timing(+)     = cv_snapshot_timing_1   -- 2営
      AND xbbs2.bm_balance_id(+)       = xbb.bm_balance_id
      AND xbbs2.snapshot_create_ym(+)  = gv_param_target_yyyymm
      AND xbbs2.snapshot_timing(+)     = cv_snapshot_timing_2   -- FB後
      AND pvsa.attribute4              IS NOT NULL
      AND NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 )) = cv_bm_type_2
      AND 3 = 3
-- Ver.1.20 ADD END
    GROUP BY xbb.supplier_code
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
           , xbb.publication_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
           , pvsa.zip
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--           , pvsa.state || pvsa.city || pvsa.address_line1
--           , pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 15 )
--           , SUBSTR( pv.vendor_name, 16     )
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD START
--           , pvsa.city || pvsa.address_line1 || pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 20 )
--           , SUBSTR( pv.vendor_name, 21, 20 )
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
           , hca2.contact_area_code
           , hca2.contact_code
           , hca2.contact_name
           , hca2.contact_address1
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama DEL START
--           , hca2.contact_address2
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama DEL END
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--           , xcbs.base_code
           , hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
           , xbb.org_slip_number
-- Ver.1.20 MOD START
--           , pvsa.bank_charge_bearer
           , NVL(xbbs2.bank_charge_bearer,
               NVL(xbbs1.bank_charge_bearer, pvsa.bank_charge_bearer
               )
             )
-- Ver.1.20 MOD END
           , xbb.balance_cancel_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
           , hca1.start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD START
-- Ver.1.20 ADD START
           , NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 ))
           , NVL(xbbs2.bm_tax_kbn, NVL(xbbs1.bm_tax_kbn, NVL(pvsa.attribute6,cv_tax_type_1)))
           , NVL(xbbs2.tax_calc_kbn, NVL(xbbs1.tax_calc_kbn, NVL(pvsa.attribute10,cv_tax_calc_type_2)))
-- Ver.1.20 ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD END
-- Ver.1.13 [障害E_本稼動_14836] SCSK K.Nara ADD START
    UNION ALL
-- Ver.1.20 MOD START
--    SELECT xbb.supplier_code                                    AS payment_code
    SELECT /*+ LEADING(xbb xcbs)
               USE_NL(xcbs)
               USE_NL(pv)
               USE_NL(pvsa)
               USE_NL(hca1)
               USE_NL(hca2)
               USE_NL(hca3)
               USE_NL(flv1)
               USE_NL(flv2)
               USE_NL(xbbs1)
               USE_NL(xbbs2)
               */
           xbb.supplier_code                                    AS payment_code
-- Ver.1.20 MOD END
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
              WHERE   xdv.flex_value  = hca2.contact_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
         , hca2.contact_code                                    AS contact_base_code
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date  --お支払日
         , xcbs.delivery_cust_code                              AS cust_code
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
              WHERE   xdv.flex_value  = hca3.base_code
                AND   ROWNUM = 1
           )                                                    AS selling_base
         , hca3.base_code                                       AS selling_base_code
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , xbb.balance_cancel_date                              AS balance_cancel_date
         , hca1.start_tran_date                                 AS start_tran_date
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                ELSE
                  xcbs.cond_bm_amt_tax
                END
              )                                                 AS bm_amt1
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_no_tax
                ELSE
                  xcbs.cond_bm_amt_no_tax
                END
              )                                                 AS bm_amt2
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_tax_amt
                ELSE
                  xcbs.cond_tax_amt
                END
              )                                                 AS bm_amt3
         , pvsa.attribute4                                      AS payment_type                -- 支払区分
         , NVL(pvsa.attribute6,cv_tax_type_1)                   AS tax_type                    -- 税区分
         , NVL(xbbs1.tax_calc_kbn, NVL(pvsa.attribute10,cv_tax_calc_type_2))  AS tax_calc_type -- 税計算区分
-- Ver.1.20 ADD END
    FROM xxcok_cond_bm_support    xcbs -- 条件別販手販協テーブル
       , xxcok_backmargin_balance xbb  -- 販手残高テーブル
       , po_vendors               pv   -- 仕入先マスタ
       , po_vendor_sites_all      pvsa -- 仕入先サイトマスタ
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
                , xca.start_tran_date            AS start_tran_date
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_parties                  hp        -- パーティマスタ
              , xxcmm_cust_accounts         xca       -- 顧客アドオン
           WHERE hca.party_id        = hp.party_id
             AND xca.customer_id     = hca.cust_account_id
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
       , ( SELECT flv.attribute1                 AS container_type_code
               , flv.meaning                     AS container_type_name
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
-- Ver.1.20 ADD START
       , xxcok_bm_balance_snap    xbbs1 -- 販手残高SNAP(2営)
-- Ver.1.20 ADD END
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xbb.base_code                = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND pvsa.attribute5              = hca2.contact_code
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_2
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      AND pvsa.attribute5              = gv_param_base_code
      AND pvsa.attribute5              = NVL( gv_param_base_code, pvsa.attribute5 )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
      AND gv_belong_base_cd            = gv_dept_jimu  --実行ユーザの所属部門が事務センタ
      AND xbb.expect_payment_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )  --支払予定日
                                        AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
      AND xbb.fb_interface_status      = '0'           --FB未連携
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
-- Ver.1.20 ADD START
      AND xbb.balance_cancel_date IS NULL
      AND xbbs1.bm_balance_id(+)       = xbb.bm_balance_id
      AND xbbs1.snapshot_create_ym(+)  = gv_param_target_yyyymm
      AND xbbs1.snapshot_timing(+)     = cv_snapshot_timing_1   -- 2営
      AND pvsa.attribute4              IS NOT NULL
      AND 4 = 4
-- Ver.1.20 ADD END
    GROUP BY xbb.supplier_code
           , xbb.publication_date
           , pvsa.zip
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
           , hca2.contact_area_code
           , hca2.contact_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , hca3.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
           , hca1.start_tran_date
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
           , pvsa.attribute4
           , NVL(pvsa.attribute6,cv_tax_type_1)
           , NVL(xbbs1.tax_calc_kbn, NVL(pvsa.attribute10,cv_tax_calc_type_2))
-- Ver.1.20 ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- Ver.1.13 [障害E_本稼動_14836] SCSK K.Nara ADD END
    ;
    --==================================================
    -- AP支払
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- 支払先コード
    , publication_date                 -- 発行日
    , payment_zip_code                 -- 支払先郵便番号
    , payment_addr_1                   -- 支払先住所1
    , payment_addr_2                   -- 支払先住所2
    , payment_name_1                   -- 支払先宛名1
    , payment_name_2                   -- 支払先宛名2
    , contact_base                     -- 地区コード（連絡先拠点）
    , contact_base_code                -- 連絡先拠点コード
    , contact_base_name                -- 連絡先拠点名
    , contact_addr_1                   -- 連絡先住所1
    , contact_addr_2                   -- 連絡先住所2
    , contact_phone_no                 -- 連絡先電話番号
    , selling_amt_sum                  -- 販売金額合計
    , bm_index_1                       -- 合計見出し1
    , bm_amt_1                         -- 合計手数料1
    , bm_index_2                       -- 合計見出し2
    , bm_amt_2                         -- 合計手数料2
    , payment_amt_tax                  -- 支払金額（税込）
    , closing_date                     -- 締め日
    , term_from_wk                     -- 対象期間（From）_ワーク
    , term_to_wk                       -- 対象期間（To）_ワーク
    , payment_date_wk                  -- お支払日_ワーク
    , cust_code                        -- 顧客コード
    , cust_name                        -- 顧客名
    , selling_base                     -- 地区コード（売上計上拠点）
    , selling_base_code                -- 売上計上拠点コード
    , selling_base_name                -- 売上計上拠点名
    , calc_type                        -- 計算条件
    , calc_type_sort                   -- 計算条件ソート順
    , container_type_code              -- 容器区分コード
    , selling_price                    -- 売価
    , detail_name                      -- 明細名
    , selling_amt                      -- 販売金額
    , selling_qty                      -- 販売数量
    , backmargin                       -- 販売手数料
    , created_by                       -- 作成者
    , creation_date                    -- 作成日
    , last_updated_by                  -- 最終更新者
    , last_update_date                 -- 最終更新日
    , last_update_login                -- 最終更新ログイン
    , request_id                       -- 要求ID
    , program_application_id           -- コンカレント・プログラム・アプリケーションID
    , program_id                       -- コンカレント・プログラムID
    , program_update_date              -- プログラム更新日
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
    , bm_index_3                       -- 合計見出し3
    , bm_amt_3                         -- 合計手数料3
    , org_slip_number                  -- 元伝票番号
    , bank_charge_bearer               -- 手数料負担者
    , balance_cancel_date              -- 残高取消日
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
    , start_tran_date                  -- 初回取引日
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
    , output_num                       -- 出力番号
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
    , bm_amt1                          -- 販売手数料1
    , bm_amt2                          -- 販売手数料2
    , bm_amt3                          -- 販売手数料3
    , payment_type                     -- 支払区分
    , tax_type                         -- 税区分
    , tax_calc_type                    -- 税計算区分
-- Ver.1.20 ADD END
    )
-- Ver.1.20 MOD START
--    SELECT xbb.supplier_code                                    AS payment_code
    SELECT /*+ LEADING(xbb xcbs)
               USE_NL(xcbs)
               USE_NL(pv)
               USE_NL(pvsa)
               USE_NL(hca1)
               USE_NL(hca2)
               USE_NL(hca3)
               USE_NL(flv1)
               USE_NL(flv2)
               USE_NL(xbbs1)
               USE_NL(xbbs2)
               */
           xbb.supplier_code                                    AS payment_code
-- Ver.1.20 MOD END
-- Start 2009/05/25 Ver_1.4 T1_1168 M.Hiruta
--         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
-- End   2009/05/25 Ver_1.4 T1_1168 M.Hiruta
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , pvsa.zip                                             AS payment_zip_code
--         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
--         , pvsa.address_line2                                   AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD START
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 1 , 20 )  AS payment_addr_1
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 21, 20 )  AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 20 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 21, 20 )                     AS payment_name_2
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS contact_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = hca3.base_code
              WHERE   xdv.flex_value  = hca1.contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS contact_base
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--         , hca3.base_code                                       AS contact_base_code
         , hca1.contact_base_code                               AS contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS contact_base_name
--         , hca3.base_address1                                   AS contact_addr_1
--         , hca3.base_address2                                   AS contact_addr_2
--         , hca3.base_phone_num                                  AS contact_phone_no
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--         , SUBSTR( hca3.base_name , 1 , 20 )                    AS contact_base_name
--         , SUBSTR( hca3.base_address1 , 1 , 20 )                AS contact_addr_1
--         , SUBSTR( hca3.base_address1 , 21, 20 )                AS contact_addr_2
--         , SUBSTRB( hca3.base_phone_num , 1 ,15 )               AS contact_phone_no
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [障害T1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [障害T1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR START
--         , MAX( xbb.expect_payment_date )                       AS payment_date
         , MAX( xbb.publication_date )                          AS payment_date
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR END
         , xcbs.delivery_cust_code                              AS cust_code
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca1.cust_name                                       AS cust_name
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS selling_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = xcbs.base_code
              WHERE   xdv.flex_value  = hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS selling_base
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_code                                       AS selling_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS selling_base_name
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
-- Ver.1.20 MOD START
-- 2017/12/29 Ver.1.12 [障害E_本稼動_14789] SCSK K.Nara MOD START
--         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
--         , cv_bank_charge_bearer                                AS bank_charge_bearer  --振込手数料を出力しないために当方とする
-- 2017/12/29 Ver.1.12 [障害E_本稼動_14789] SCSK K.Nara MOD END
         , cv_bank_charge_bearer                                AS bank_charge_bearer
-- Ver.1.20 MOD END
         , xbb.balance_cancel_date                              AS balance_cancel_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
         , hca1.start_tran_date                                 AS start_tran_date 
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                ELSE
                  xcbs.cond_bm_amt_tax
                END
              )                                                 AS bm_amt1
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_no_tax
                ELSE
                  xcbs.cond_bm_amt_no_tax
                END
              )                                                 AS bm_amt2
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_tax_amt
                ELSE
                  xcbs.cond_tax_amt
                END
              )                                                 AS bm_amt3
         , NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 ))             AS payment_type  -- 支払区分
         , NVL(xbbs2.bm_tax_kbn, NVL(xbbs1.bm_tax_kbn, NVL(pvsa.attribute6,cv_tax_type_1))) AS tax_type      -- 税区分
         , cv_tax_calc_type_2                                   AS tax_calc_type                             -- 税計算区分
-- Ver.1.20 ADD END
    FROM xxcok_cond_bm_support    xcbs -- 条件別販手販協テーブル
       , xxcok_backmargin_balance xbb  -- 販手残高テーブル
       , po_vendors               pv   -- 仕入先マスタ
       , po_vendor_sites_all      pvsa -- 仕入先サイトマスタ
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
                , xca.start_tran_date            AS start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD START
                , xca.past_sale_base_code        AS base_code
                , xca.sale_base_code             AS contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD END
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_parties                  hp        -- パーティマスタ
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
              , xxcmm_cust_accounts         xca       -- 顧客アドオン
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
           WHERE hca.party_id        = hp.party_id
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
             AND xca.customer_id     = hca.cust_account_id
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
         )                        hca1
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD START
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD END
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--                ,    hl.state
--                  || hl.city
--                  || hl.address1                 AS base_address1
--                , hl.address2                    AS base_address2
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS base_address1
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
                , hl.address_lines_phonetic      AS base_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
-- Ver.1.20 ADD START
       , xxcok_bm_balance_snap    xbbs1 -- 販手残高SNAP(2営)
       , xxcok_bm_balance_snap    xbbs2 -- 販手残高SNAP(FB後)
-- Ver.1.20 ADD END
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--      AND xcbs.base_code               = hca3.base_code
      AND xbb.base_code                = hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
      AND xcbs.delivery_cust_code      = hca1.cust_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD START
      AND hca2.contact_code            = hca1.contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD END
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
-- Ver.1.20 DEL START
--      AND pvsa.attribute4              = cv_bm_type_3
-- Ver.1.20 DEL END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--      AND xbb.base_code                = gv_param_base_code
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      AND hca1.base_code                = gv_param_base_code
      AND hca1.base_code               = NVL( gv_param_base_code, hca1.base_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR START
--      AND xbb.balance_cancel_date BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
--                                      AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR END
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
      AND xbb.expect_payment_amt_tax   = 0
      AND xbb.payment_amt_tax          > 0
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD START
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD END
-- Ver.1.20 ADD START
      AND xbb.balance_cancel_date IS NULL
      AND xbbs1.bm_balance_id(+)       = xbb.bm_balance_id
      AND xbbs1.snapshot_create_ym(+)  = gv_param_target_yyyymm
      AND xbbs1.snapshot_timing(+)     = cv_snapshot_timing_1   -- 2営
      AND xbbs2.bm_balance_id(+)       = xbb.bm_balance_id
      AND xbbs2.snapshot_create_ym(+)  = gv_param_target_yyyymm
      AND xbbs2.snapshot_timing(+)     = cv_snapshot_timing_2   -- FB後
      AND pvsa.attribute4              IS NOT NULL
      AND NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 )) = cv_bm_type_3
      AND 5 = 5
-- Ver.1.20 ADD END
    GROUP BY xbb.supplier_code
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
           , xbb.publication_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
           , pvsa.zip
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama DEL START
--           , pvsa.state || pvsa.city || pvsa.address_line1
--           , pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 15 )
--           , SUBSTR( pv.vendor_name, 16     )
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD START
--           , pvsa.city || pvsa.address_line1 || pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 20 )
--           , SUBSTR( pv.vendor_name, 21, 20 )
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--           , hca3.base_code
--           , hca3.base_name
--           , hca3.base_area_code
--           , hca3.base_address1
           , hca1.contact_base_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama DEL START
--           , hca3.base_address2
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama DEL END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai DEL START
--           , hca3.base_phone_num
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai DEL END
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--           , xcbs.base_code
           , hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
           , xbb.org_slip_number
-- Ver.1.20 DEL START
--           , pvsa.bank_charge_bearer
-- Ver.1.20 DEL END
           , xbb.balance_cancel_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
           , hca1.start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD START
-- Ver.1.20 ADD START
           , NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 ))
           , NVL(xbbs2.bm_tax_kbn, NVL(xbbs1.bm_tax_kbn, NVL(pvsa.attribute6,cv_tax_type_1)))
-- Ver.1.20 ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD END
-- 2017/12/29 Ver.1.12 [障害E_本稼動_14789] SCSK K.Nara ADD START
    UNION ALL
-- Ver.1.20 MOD START
--    SELECT xbb.supplier_code                                    AS payment_code
    SELECT /*+ LEADING(xbb xcbs)
               USE_NL(xcbs)
               USE_NL(pv)
               USE_NL(pvsa)
               USE_NL(hca1)
               USE_NL(hca2)
               USE_NL(hca3)
               USE_NL(flv1)
               USE_NL(flv2)
               USE_NL(xbbs1)
               USE_NL(xbbs2)
               */
           xbb.supplier_code                                    AS payment_code
-- Ver.1.20 MOD END
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
         , SUBSTRB( pvsa.zip , 1, 8 )                           AS payment_zip_code
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1, 20 )                    AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21, 20 )                    AS payment_name_2
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
              WHERE   xdv.flex_value  = hca1.contact_base_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
         , hca1.contact_base_code                               AS contact_base_code
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date
         , xcbs.delivery_cust_code                              AS cust_code
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
              WHERE   xdv.flex_value  = hca3.base_code
                AND   ROWNUM = 1
           )                                                    AS selling_base
         , hca3.base_code                                       AS selling_base_code
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , cv_bank_charge_bearer                                AS bank_charge_bearer  --振込手数料を出力しないために当方とする
         , xbb.balance_cancel_date                              AS balance_cancel_date
         , hca1.start_tran_date                                 AS start_tran_date 
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                ELSE
                  xcbs.cond_bm_amt_tax
                END
              )                                                 AS bm_amt1
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_no_tax
                ELSE
                  xcbs.cond_bm_amt_no_tax
                END
              )                                                 AS bm_amt2
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_tax_amt
                ELSE
                  xcbs.cond_tax_amt
                END
              )                                                 AS bm_amt3
         , pvsa.attribute4                                      AS payment_type  -- 支払区分
         , NVL(pvsa.attribute6,cv_tax_type_1)                   AS tax_type      -- 税区分
         , cv_tax_calc_type_2                                   AS tax_calc_type -- 税計算区分
-- Ver.1.20 ADD END
    FROM xxcok_cond_bm_support    xcbs -- 条件別販手販協テーブル
       , xxcok_backmargin_balance xbb  -- 販手残高テーブル
       , po_vendors               pv   -- 仕入先マスタ
       , po_vendor_sites_all      pvsa -- 仕入先サイトマスタ
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
                , xca.start_tran_date            AS start_tran_date
                , xca.past_sale_base_code        AS base_code
                , xca.sale_base_code             AS contact_base_code
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_parties                  hp        -- パーティマスタ
              , xxcmm_cust_accounts         xca       -- 顧客アドオン
           WHERE hca.party_id        = hp.party_id
             AND xca.customer_id     = hca.cust_account_id
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS base_address1
                , hl.address_lines_phonetic      AS base_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
       , ( SELECT flv.attribute1                 AS container_type_code
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xbb.base_code                = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND hca2.contact_code            = hca1.contact_base_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_3
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      AND hca1.base_code               = gv_param_base_code
      AND hca1.base_code               = NVL( gv_param_base_code, hca1.base_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
      AND gv_belong_base_cd            = gv_dept_jimu  --実行ユーザが事務センタ
      AND xbb.expect_payment_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )  --支払予定日が対象内
                                        AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
      AND xbb.expect_payment_amt_tax   > 0  --未消込である
      AND xbb.payment_amt_tax          = 0  --未消込である
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
-- Ver.1.20 ADD START
      AND xbb.balance_cancel_date IS NULL
      AND 6 = 6
-- Ver.1.20 ADD END
    GROUP BY xbb.supplier_code
           , xbb.publication_date
           , pvsa.zip
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
           , hca1.contact_base_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , hca3.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
           , xbb.org_slip_number
-- Ver.1.20 DEL START
--           , pvsa.bank_charge_bearer
-- Ver.1.20 DEL END
           , xbb.balance_cancel_date
           , hca1.start_tran_date
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
           , pvsa.attribute4
           , NVL(pvsa.attribute6,cv_tax_type_1)
-- Ver.1.20 ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- 2017/12/29 Ver.1.12 [障害E_本稼動_14789] SCSK K.Nara ADD END
    ;
    --==================================================
    -- 現金支払
    --==================================================
    INSERT INTO xxcok_rep_bm_pg_detail(
      payment_code                     -- 支払先コード
    , publication_date                 -- 発行日
    , payment_zip_code                 -- 支払先郵便番号
    , payment_addr_1                   -- 支払先住所1
    , payment_addr_2                   -- 支払先住所2
    , payment_name_1                   -- 支払先宛名1
    , payment_name_2                   -- 支払先宛名2
    , contact_base                     -- 地区コード（連絡先拠点）
    , contact_base_code                -- 連絡先拠点コード
    , contact_base_name                -- 連絡先拠点名
    , contact_addr_1                   -- 連絡先住所1
    , contact_addr_2                   -- 連絡先住所2
    , contact_phone_no                 -- 連絡先電話番号
    , selling_amt_sum                  -- 販売金額合計
    , bm_index_1                       -- 合計見出し1
    , bm_amt_1                         -- 合計手数料1
    , bm_index_2                       -- 合計見出し2
    , bm_amt_2                         -- 合計手数料2
    , payment_amt_tax                  -- 支払金額（税込）
    , closing_date                     -- 締め日
    , term_from_wk                     -- 対象期間（From）_ワーク
    , term_to_wk                       -- 対象期間（To）_ワーク
    , payment_date_wk                  -- お支払日_ワーク
    , cust_code                        -- 顧客コード
    , cust_name                        -- 顧客名
    , selling_base                     -- 地区コード（売上計上拠点）
    , selling_base_code                -- 売上計上拠点コード
    , selling_base_name                -- 売上計上拠点名
    , calc_type                        -- 計算条件
    , calc_type_sort                   -- 計算条件ソート順
    , container_type_code              -- 容器区分コード
    , selling_price                    -- 売価
    , detail_name                      -- 明細名
    , selling_amt                      -- 販売金額
    , selling_qty                      -- 販売数量
    , backmargin                       -- 販売手数料
    , created_by                       -- 作成者
    , creation_date                    -- 作成日
    , last_updated_by                  -- 最終更新者
    , last_update_date                 -- 最終更新日
    , last_update_login                -- 最終更新ログイン
    , request_id                       -- 要求ID
    , program_application_id           -- コンカレント・プログラム・アプリケーションID
    , program_id                       -- コンカレント・プログラムID
    , program_update_date              -- プログラム更新日
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
    , bm_index_3                       -- 合計見出し3
    , bm_amt_3                         -- 合計手数料3
    , org_slip_number                  -- 元伝票番号
    , bank_charge_bearer               -- 手数料負担者
    , balance_cancel_date              -- 残高取消日
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
    , start_tran_date                  -- 初回取引日
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
    , output_num                       -- 出力番号
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
    , bm_amt1                          -- 販売手数料1
    , bm_amt2                          -- 販売手数料2
    , bm_amt3                          -- 販売手数料3
    , payment_type                     -- 支払区分
    , tax_type                         -- 税区分
    , tax_calc_type                    -- 税計算区分
-- Ver.1.20 ADD END
    )
-- Ver.1.20 MOD START
--    SELECT xbb.supplier_code                                    AS payment_code
    SELECT /*+ LEADING(xbb xcbs)
               USE_NL(xcbs)
               USE_NL(pv)
               USE_NL(pvsa)
               USE_NL(hca1)
               USE_NL(hca2)
               USE_NL(hca3)
               USE_NL(flv1)
               USE_NL(flv2)
               USE_NL(xbbs1)
               USE_NL(xbbs2)
               */
           xbb.supplier_code                                    AS payment_code
-- Ver.1.20 MOD END
-- Start 2009/05/25 Ver_1.4 T1_1168 M.Hiruta
--         , TO_CHAR( SYSDATE, cv_format_date )                   AS publication_date
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
-- End   2009/05/25 Ver_1.4 T1_1168 M.Hiruta
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , pvsa.zip                                             AS payment_zip_code
--         , pvsa.state || pvsa.city || pvsa.address_line1        AS payment_addr_1
--         , pvsa.address_line2                                   AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1, 15 )                     AS payment_name_1
--         , SUBSTR( pv.vendor_name, 16     )                     AS payment_name_2
         , SUBSTRB( pvsa.zip , 1 , 8 )                          AS payment_zip_code
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD START
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 1 , 20 )  AS payment_addr_1
--         , SUBSTR( pvsa.city  || pvsa.address_line1
--                              || pvsa.address_line2 , 21, 20 )  AS payment_addr_2
--         , SUBSTR( pv.vendor_name,  1 , 20 )                    AS payment_name_1
--         , SUBSTR( pv.vendor_name, 21 , 20 )                    AS payment_name_2
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1 , 20 )                   AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21 , 20 )                   AS payment_name_2
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS contact_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = hca3.base_code
              WHERE   xdv.flex_value  = hca1.contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS contact_base
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--         , hca3.base_code                                       AS contact_base_code
         , hca1.contact_base_code                               AS contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS contact_base_name
--         , hca3.base_address1                                   AS contact_addr_1
--         , hca3.base_address2                                   AS contact_addr_2
--         , hca3.base_phone_num                                  AS contact_phone_no
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--         , SUBSTR( hca3.base_name , 1 , 20 )                    AS contact_base_name
--         , SUBSTR( hca3.base_address1 , 1 , 20 )                AS contact_addr_1
--         , SUBSTR( hca3.base_address1 , 21, 20 )                AS contact_addr_2
--         , SUBSTRB( hca3.base_phone_num , 1 ,15 )               AS contact_phone_no
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
-- 2009/05/11 Ver.1.3 [障害T1_0841] SCS K.Yamaguchi REPAIR START
--         , SUM( xbb.expect_payment_amt_tax )                    AS payment_amt_tax
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
-- 2009/05/11 Ver.1.3 [障害T1_0841] SCS K.Yamaguchi REPAIR END
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR START
--         , MAX( xbb.expect_payment_date )                       AS payment_date
         , MAX( xbb.publication_date )                          AS payment_date
-- 2010/03/02 Ver.1.8 [障害E_本稼動_01299] SCS S.Moriyama REPAIR END
         , xcbs.delivery_cust_code                              AS cust_code
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca1.cust_name                                       AS cust_name
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD START
--         , hca3.base_area_code                                  AS selling_base
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--              WHERE   xdv.flex_value  = xcbs.base_code
              WHERE   xdv.flex_value  = hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
                AND   ROWNUM = 1
           )                                                    AS selling_base
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki UPD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--         , xcbs.base_code                                       AS selling_base_code
         , hca3.base_code                                       AS selling_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--         , hca3.base_name                                       AS selling_base_name
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
-- Ver.1.20 MOD START
--         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , NVL(xbbs2.bank_charge_bearer,
             NVL(xbbs1.bank_charge_bearer, pvsa.bank_charge_bearer
             )
           )                                                    AS bank_charge_bearer
-- Ver.1.20 MOD END
         , xbb.balance_cancel_date                              AS balance_cancel_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
         , hca1.start_tran_date                                 AS start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                ELSE
                  xcbs.cond_bm_amt_tax
                END
              )                                                 AS bm_amt1
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_no_tax
                ELSE
                  xcbs.cond_bm_amt_no_tax
                END
              )                                                 AS bm_amt2
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_tax_amt
                ELSE
                  xcbs.cond_tax_amt
                END
              )                                                 AS bm_amt3
         , NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 ))              AS payment_type  -- 支払区分
         , NVL(xbbs2.bm_tax_kbn, NVL(xbbs1.bm_tax_kbn, NVL(pvsa.attribute6,cv_tax_type_1)))  AS tax_type      -- 税区分
         , cv_tax_calc_type_2                                   AS tax_calc_type                              -- 税計算区分
-- Ver.1.20 ADD END
    FROM xxcok_cond_bm_support    xcbs -- 条件別販手販協テーブル
       , xxcok_backmargin_balance xbb  -- 販手残高テーブル
       , po_vendors               pv   -- 仕入先マスタ
       , po_vendor_sites_all      pvsa -- 仕入先サイトマスタ
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
                , xca.start_tran_date            AS start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD START
                , xca.past_sale_base_code        AS base_code
                , xca.sale_base_code             AS contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD END
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_parties                  hp        -- パーティマスタ
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
              , xxcmm_cust_accounts         xca       -- 顧客アドオン
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
           WHERE hca.party_id        = hp.party_id
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
             AND xca.customer_id     = hca.cust_account_id
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
         )                        hca1
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD START
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD END
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD START
--                ,    hl.state 
--                  || hl.city
--                  || hl.address1                 AS base_address1
--                , hl.address2                    AS base_address2
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS base_address1
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPD END
                , hl.address_lines_phonetic      AS base_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
-- Start 2009/03/03 M.Hiruta
--       , ( SELECT flv.lookup_code                AS container_type_code
       , ( SELECT flv.attribute1                 AS container_type_code
-- End   2009/03/03 M.Hiruta
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
-- Ver.1.20 ADD START
       , xxcok_bm_balance_snap    xbbs1 -- 販手残高SNAP(2営)
       , xxcok_bm_balance_snap    xbbs2 -- 販手残高SNAP(FB後)
-- Ver.1.20 ADD END
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--      AND xcbs.base_code               = hca3.base_code
      AND xbb.base_code                = hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
      AND xcbs.delivery_cust_code      = hca1.cust_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD START
      AND hca2.contact_code            = hca1.contact_base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai ADD END
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
-- Ver.1.20 DEL START
--      AND pvsa.attribute4              = cv_bm_type_4
-- Ver.1.20 DEL END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--      AND xbb.base_code                = gv_param_base_code
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      AND hca1.base_code               = gv_param_base_code
      AND hca1.base_code               = NVL( gv_param_base_code, hca1.base_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
      AND xbb.publication_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD START
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD END
-- Ver.1.20 ADD START
      AND xbb.balance_cancel_date IS NULL
      AND xbbs1.bm_balance_id(+)       = xbb.bm_balance_id
      AND xbbs1.snapshot_create_ym(+)  = gv_param_target_yyyymm
      AND xbbs1.snapshot_timing(+)     = cv_snapshot_timing_1   -- 2営
      AND xbbs2.bm_balance_id(+)       = xbb.bm_balance_id
      AND xbbs2.snapshot_create_ym(+)  = gv_param_target_yyyymm
      AND xbbs2.snapshot_timing(+)     = cv_snapshot_timing_2   -- FB後
      AND pvsa.attribute4              IS NOT NULL
      AND NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 )) = cv_bm_type_4
      AND 7 = 7
-- Ver.1.20 ADD END
    GROUP BY xbb.supplier_code
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
           , xbb.publication_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
           , pvsa.zip
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPS START
--           , pvsa.state || pvsa.city || pvsa.address_line1
--           , pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 15 )
--           , SUBSTR( pv.vendor_name, 16     )
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD START
--           , pvsa.city || pvsa.address_line1 || pvsa.address_line2
--           , SUBSTR( pv.vendor_name,  1, 20 )
--           , SUBSTR( pv.vendor_name, 21, 20 )
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
-- 2009/10/14 Ver.1.6 [変更依頼I_E_573] SCS S.Moriyama UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama UPS END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--           , hca3.base_code
--           , hca3.base_name
--           , hca3.base_area_code
--           , hca3.base_address1
           , hca1.contact_base_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama DEL START
--           , hca3.base_address2
-- 2009/09/10 Ver.1.5 [障害0000060] SCS S.Moriyama DEL END
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai DEL START
--           , hca3.base_phone_num
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai DEL END
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD START
--           , xcbs.base_code
           , hca3.base_code
-- 2011/02/03 Ver.1.11 [障害E_本稼動_05409] SCS S.Ochiai UPD END
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
           , xbb.org_slip_number
-- Ver.1.20 MOD START
--           , pvsa.bank_charge_bearer
           , NVL(xbbs2.bank_charge_bearer,
               NVL(xbbs1.bank_charge_bearer, pvsa.bank_charge_bearer
               )
             )
-- Ver.1.20 MOD END
           , xbb.balance_cancel_date
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD START
           , hca1.start_tran_date
-- 2011/01/05 Ver.1.10 [障害E_本稼動_01950] SCS S.Niki ADD END
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD START
-- Ver.1.20 ADD START
           , NVL(xbbs2.bm_paymet_kbn, NVL(xbbs1.bm_paymet_kbn, pvsa.attribute4 ))
           , NVL(xbbs2.bm_tax_kbn, NVL(xbbs1.bm_tax_kbn, NVL(pvsa.attribute6,cv_tax_type_1)))
-- Ver.1.20 ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- 2009/12/15 Ver.1.7 [障害E_本稼動_00477] SCS K.Nakamura ADD END
-- 2018/03/15 Ver.1.15 [障害E_本稼動_14900] SCSK Y.Sekine ADD START
    UNION ALL
-- Ver.1.20 MOD START
--    SELECT xbb.supplier_code                                    AS payment_code
    SELECT /*+ LEADING(xbb xcbs)
               USE_NL(xcbs)
               USE_NL(pv)
               USE_NL(pvsa)
               USE_NL(hca1)
               USE_NL(hca2)
               USE_NL(hca3)
               USE_NL(flv1)
               USE_NL(flv2)
               USE_NL(xbbs1)
               USE_NL(xbbs2)
               */
           xbb.supplier_code                                    AS payment_code
-- Ver.1.20 MOD END
         , TO_CHAR( gd_process_date, cv_format_date )           AS publication_date
         , SUBSTRB( pvsa.zip , 1 , 8 )                          AS payment_zip_code
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 1 , 20 )             AS payment_addr_1
         , SUBSTR( pvsa.address_line1
                   || pvsa.address_line2 , 21, 20 )             AS payment_addr_2
         , SUBSTR( pvsa.attribute1,  1 , 20 )                   AS payment_name_1
         , SUBSTR( pvsa.attribute1, 21 , 20 )                   AS payment_name_2
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
              WHERE   xdv.flex_value  = hca1.contact_base_code
                AND   ROWNUM = 1
           )                                                    AS contact_base
         , hca1.contact_base_code                               AS contact_base_code
         , SUBSTR( hca2.contact_name , 1 , 20 )                 AS contact_base_name
         , SUBSTR( hca2.contact_address1 , 1 , 20 )             AS contact_addr_1
         , SUBSTR( hca2.contact_address1 , 21, 20 )             AS contact_addr_2
         , SUBSTRB( hca2.contact_phone_num , 1 ,15 )            AS contact_phone_no
         , NULL                                                 AS selling_amt_sum
         , NULL                                                 AS bm_index_1
         , NULL                                                 AS bm_amt_1
         , NULL                                                 AS bm_index_2
         , NULL                                                 AS bm_amt_2
         , SUM( NVL( xcbs.cond_bm_amt_tax,  0 )
              + NVL( xcbs.electric_amt_tax, 0 ) )               AS payment_amt_tax
         , MAX( xbb.closing_date )                              AS target_month
         , MIN( xcbs.calc_target_period_from)                   AS term_from
         , MAX( xcbs.calc_target_period_to )                    AS term_to
         , MAX( xbb.expect_payment_date )                       AS payment_date     -- お支払日
         , xcbs.delivery_cust_code                              AS cust_code
         , SUBSTR( hca1.cust_name , 1 , 40)                     AS cust_name
         , (  SELECT  CASE WHEN TO_DATE( xdv.attribute6, cv_format_fxrrrrmmdd ) > gd_process_date
                        THEN xdv.attribute7 -- 本部コード(旧)
                        ELSE xdv.attribute9 -- 本部コード(新)
                      END
              FROM    xx03_departments_v  xdv -- 部門ビュー
              WHERE   xdv.flex_value  = hca3.base_code
                AND   ROWNUM = 1
           )                                                    AS selling_base
         , hca3.base_code                                       AS selling_base_code
         , SUBSTR( hca3.base_name , 1 , 20 )                    AS selling_base_name
         , xcbs.calc_type                                       AS calc_type
         , flv2.calc_type_sort                                  AS calc_type_sort
         , flv1.container_type_code                             AS container_type_code
         , xcbs.selling_price                                   AS selling_price
         ,    flv2.line_name
           || CASE xcbs.calc_type
              WHEN '10' THEN
                TO_CHAR( xcbs.selling_price )
              WHEN '20' THEN
                flv1.container_type_name
              END                                               AS detail_name
         , SUM( xcbs.selling_amt_tax )                          AS selling_amt
         , SUM( xcbs.delivery_qty )                             AS selling_qty
         , SUM( CASE xcbs.calc_type
                WHEN '10' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '20' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '30' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '40' THEN
                  xcbs.cond_bm_amt_tax
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                END
           )                                                    AS backmargin
         , cn_created_by                                        AS created_by
         , SYSDATE                                              AS creation_date
         , cn_last_updated_by                                   AS last_updated_by
         , SYSDATE                                              AS last_update_date
         , cn_last_update_login                                 AS last_update_login
         , cn_request_id                                        AS request_id
         , cn_program_application_id                            AS program_application_id
         , cn_program_id                                        AS program_id
         , SYSDATE                                              AS program_update_date
         , NULL                                                 AS bm_index_3
         , NULL                                                 AS bm_amt_3
         , xbb.org_slip_number                                  AS org_slip_number
         , pvsa.bank_charge_bearer                              AS bank_charge_bearer
         , xbb.balance_cancel_date                              AS balance_cancel_date
         , hca1.start_tran_date                                 AS start_tran_date
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
         , gt_upload_output_num                                 AS output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_tax
                ELSE
                  xcbs.cond_bm_amt_tax
                END
              )                                                 AS bm_amt1
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_amt_no_tax
                ELSE
                  xcbs.cond_bm_amt_no_tax
                END
              )                                                 AS bm_amt2
         , SUM( CASE xcbs.calc_type
                WHEN '50' THEN
                  xcbs.electric_tax_amt
                ELSE
                  xcbs.cond_tax_amt
                END
              )                                                 AS bm_amt3
         , pvsa.attribute4                                      AS payment_type  -- 支払区分
         , NVL(pvsa.attribute6,cv_tax_type_1)                   AS tax_type      -- 税区分
         , cv_tax_calc_type_2                                   AS tax_calc_type -- 税計算区分
-- Ver.1.20 ADD END
    FROM xxcok_cond_bm_support    xcbs -- 条件別販手販協テーブル
       , xxcok_backmargin_balance xbb  -- 販手残高テーブル
       , po_vendors               pv   -- 仕入先マスタ
       , po_vendor_sites_all      pvsa -- 仕入先サイトマスタ
       , ( SELECT hca.account_number             AS cust_code
                , hp.party_name                  AS cust_name
                , xca.start_tran_date            AS start_tran_date
                , xca.past_sale_base_code        AS base_code
                , xca.sale_base_code             AS contact_base_code
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_parties                  hp        -- パーティマスタ
              , xxcmm_cust_accounts         xca       -- 顧客アドオン
           WHERE hca.party_id        = hp.party_id
             AND xca.customer_id     = hca.cust_account_id
         )                        hca1
       , ( SELECT hca.account_number             AS contact_code
                , hp.party_name                  AS contact_name
                , hl.address3                    AS contact_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS contact_address1
                , hl.address_lines_phonetic      AS contact_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca2
       , ( SELECT hca.account_number             AS base_code
                , hp.party_name                  AS base_name
                , hl.address3                    AS base_area_code
                ,    hl.city
                  || hl.address1
                  || hl.address2                 AS base_address1
                , hl.address_lines_phonetic      AS base_phone_num
           FROM hz_cust_accounts            hca       -- 顧客マスタ
              , hz_cust_acct_sites_all      hcasa     -- 顧客所在地マスタ
              , hz_parties                  hp        -- パーティマスタ
              , hz_party_sites              hps       -- パーティサイトマスタ
              , hz_locations                hl        -- 顧客事業所マスタ
           WHERE hca.cust_account_id = hcasa.cust_account_id
             AND hca.party_id        = hp.party_id
             AND hcasa.party_site_id = hps.party_site_id
             AND hps.location_id     = hl.location_id
             AND hcasa.org_id        = gn_org_id
         )                        hca3
       , ( SELECT flv.attribute1                 AS container_type_code
                , flv.meaning                    AS container_type_name
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_01
             AND flv.language        = USERENV( 'LANG' )
         )                        flv1
       , ( SELECT flv.lookup_code                AS calc_type
                , flv.attribute1                 AS line_name
                , flv.attribute2                 AS calc_type_sort
           FROM fnd_lookup_values           flv       -- クイックコード
           WHERE flv.lookup_type     = cv_lookup_type_02
             AND flv.language        = USERENV( 'LANG' )
         )                        flv2
    WHERE xcbs.base_code               = xbb.base_code
      AND xcbs.delivery_cust_code      = xbb.cust_code
      AND xcbs.supplier_code           = xbb.supplier_code
      AND xcbs.closing_date            = xbb.closing_date
      AND xcbs.expect_payment_date     = xbb.expect_payment_date
      AND xbb.base_code                = hca3.base_code
      AND xcbs.delivery_cust_code      = hca1.cust_code
      AND hca2.contact_code            = hca1.contact_base_code
      AND xcbs.supplier_code           = pv.segment1
      AND pv.vendor_id                 = pvsa.vendor_id
      AND ( pvsa.inactive_date         > gd_process_date OR pvsa.inactive_date IS NULL )
      AND xcbs.container_type_code     = flv1.container_type_code(+)
      AND xcbs.calc_type               = flv2.calc_type
      AND pvsa.org_id                  = gn_org_id
      AND pvsa.attribute4              = cv_bm_type_4
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--      AND hca1.base_code               = gv_param_base_code
      AND hca1.base_code               = NVL( gv_param_base_code, hca1.base_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
      AND xbb.expect_payment_date   BETWEEN TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm )
                                     AND LAST_DAY( TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm ) )
      AND xbb.supplier_code            = NVL( gv_param_vendor_code, xbb.supplier_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
      AND xbb.cust_code                = NVL( gt_upload_cust_code, xbb.cust_code )
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
      AND NVL( xbb.resv_flag, 'N' )    != 'Y'
      AND gv_belong_base_cd            = gv_dept_jimu   -- 実行ユーザの所属部門が事務センタ
      AND xbb.publication_date         IS NULL          -- 販手残高テーブル．案内書発効日がNULL
-- Ver.1.20 ADD START
      AND xbb.balance_cancel_date IS NULL
      AND 8 = 8
-- Ver.1.20 ADD END
    GROUP BY xbb.supplier_code
           , xbb.publication_date
           , pvsa.zip
           , pvsa.address_line1 || pvsa.address_line2
           , SUBSTR( pvsa.attribute1,  1, 20 )
           , SUBSTR( pvsa.attribute1, 21, 20 )
           , hca1.contact_base_code
           , hca2.contact_name
           , hca2.contact_address1
           , hca2.contact_phone_num
           , xcbs.delivery_cust_code
           , hca1.cust_name
           , hca3.base_area_code
           , hca3.base_code
           , hca3.base_name
           , xcbs.calc_type
           , flv2.calc_type_sort
           , flv1.container_type_code
           , xcbs.selling_price
           ,    flv2.line_name
             || CASE xcbs.calc_type
                WHEN '10' THEN
                  TO_CHAR( xcbs.selling_price )
                WHEN '20' THEN
                  flv1.container_type_name
                END
           , xbb.org_slip_number
           , pvsa.bank_charge_bearer
           , xbb.balance_cancel_date
           , hca1.start_tran_date
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
           , gt_upload_output_num
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
           , pvsa.attribute4
           , NVL(pvsa.attribute6,cv_tax_type_1)
-- Ver.1.20 ADD END
    HAVING   SUM( CASE xcbs.calc_type
                  WHEN '10' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '20' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '30' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '40' THEN
                    xcbs.cond_bm_amt_tax
                  WHEN '50' THEN
                    xcbs.electric_amt_tax
                  END
                ) <> 0
-- 2018/03/15 Ver.1.15 [障害E_本稼動_14900] SCSK Y.Sekine ADD END
    ;
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xrbpd;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_base_code                   IN  VARCHAR2        -- 問合せ先
  , iv_target_ym                   IN  VARCHAR2        -- 案内書発行年月
  , iv_vendor_code                 IN  VARCHAR2        -- 支払先
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  , in_request_id                  IN  NUMBER          -- 要求ID
  , in_output_num                  IN  NUMBER          -- 出力番号
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'init';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ld_chk_date                    DATE           DEFAULT NULL;                 -- 日付型チェック用変数
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- プログラム入力項目を出力
    --==================================================
    -- 問合先
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00087
                  , iv_token_name1          => cv_tkn_base_code
                  , iv_token_value1         => iv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- 案内書発行年月
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00085
                  , iv_token_name1          => cv_tkn_target_ym
                  , iv_token_value1         => iv_target_ym
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- 支払先
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00086
                  , iv_token_name1          => cv_tkn_vendor_code
                  , iv_token_value1         => iv_vendor_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--                  , in_new_line             => 1
                  , in_new_line             => 0
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
                  );
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
    -- 要求ID
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_10545
                  , iv_token_name1          => cv_tkn_request_id
                  , iv_token_value1         => TO_CHAR(in_request_id)
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- 出力番号
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_10546
                  , iv_token_name1          => cv_tkn_output_num
                  , iv_token_value1         => TO_CHAR(in_output_num)
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 1
                  );
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
    --==================================================
    -- 業務処理日付取得
    --==================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF( gd_process_date IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- 案内書発行年月型チェック
    --==================================================
    BEGIN
      ld_chk_date := TO_DATE( iv_target_ym, cv_format_fxrrrrmm );
-- Ver.1.21 ADD START
      gd_company_reference_date   := ld_chk_date;               -- 会社基準日
-- Ver.1.21 ADD END
    EXCEPTION
      WHEN OTHERS THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_10309
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.LOG
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
    END;
    --==================================================
    -- プロファイル取得(MO: 営業単位)
    --==================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_03 ) );
    IF( gn_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_03
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払案内書_販売手数料見出し)
    --==================================================
    gv_prompt_bm := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_prompt_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払案内書_電気料見出し)
    --==================================================
    gv_prompt_ep := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_prompt_ep IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_02
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD START
    --==================================================
    -- プロファイル取得(支払案内書_振込手数料)
    --==================================================
    gv_prompt_fe := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF( gv_prompt_fe IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_04
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(勘定科目_手数料)
    --==================================================
    gt_aff3_fee := FND_PROFILE.VALUE( cv_profile_name_05 );
    IF( gt_aff3_fee IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_05
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(補助科目_手数料_振込手数料)
    --==================================================
    gt_aff4_transfer_fee := FND_PROFILE.VALUE( cv_profile_name_06 );
    IF( gt_aff4_transfer_fee IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_06
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(仕訳カテゴリ_販売手数料)
    --==================================================
    gt_category_bm := FND_PROFILE.VALUE( cv_profile_name_07 );
    IF( gt_category_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_07
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(仕訳ソース_個別開発)
    --==================================================
    gt_source_cok := FND_PROFILE.VALUE( cv_profile_name_08 );
    IF( gt_source_cok IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_08
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(GL会計帳簿ID)
    --==================================================
    gt_set_of_books_id := FND_PROFILE.VALUE( cv_profile_name_09 );
    IF( gt_set_of_books_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_09
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(銀行手数料_振込額基準)
    --==================================================
    gn_bank_fee_trans := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_10 ) );
    IF( gn_bank_fee_trans IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_10
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(銀行手数料_基準額未満)
    --==================================================
    gn_bank_fee_less := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_11 ) );
    IF( gn_bank_fee_less IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_11
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(銀行手数料_基準額以上)
    --==================================================
    gn_bank_fee_more := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_12 ) );
    IF( gn_bank_fee_more IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_12
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(販売手数料_消費税率)
    --==================================================
    gn_bm_tax := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_13 ) );
    IF( gn_bm_tax IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_13
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2010/03/16 Ver.1.9 [障害E_本稼動_01897] SCS S.Moriyama ADD END
-- 2017/12/29 Ver.1.12 [障害E_本稼動_14789] SCSK K.Nara ADD START
    --==================================================
    -- プロファイル取得(XXCOK:部門コード_事務センター)
    --==================================================
    gv_dept_jimu := FND_PROFILE.VALUE( cv_profile_name_14 );
    IF( gv_dept_jimu IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_14
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.LOG
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- 実行ユーザの所属部署を取得
    --==================================================
    gv_belong_base_cd := NVL( xxcok_common_pkg.get_base_code_f( gd_process_date, fnd_global.user_id ), '@' );
-- 2017/12/29 Ver.1.12 [障害E_本稼動_14789] SCSK K.Nara ADD END
    gv_param_base_code   := iv_base_code;
    gv_param_target_ym   := iv_target_ym;
    gv_param_vendor_code := iv_vendor_code;
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
    gn_param_request_id  := in_request_id;
    gn_param_output_num  := in_output_num;
    gt_upload_output_num := ct_output_num_init;    --カレント出力番号初期化
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
-- Ver.1.20 ADD START
    gv_param_target_yyyymm   := REPLACE(iv_target_ym,cv_slash);
-- Ver.1.21 DEL START
--    --==================================================
--    -- プロファイル取得(適格請求書発行事業者登録番号)
--    --==================================================
--    gv_t_number := FND_PROFILE.VALUE( cv_t_number );
--    IF( gv_t_number IS NULL ) THEN
--      lv_outmsg  := xxccp_common_pkg.get_msg(
--                      iv_application          => cv_appl_short_name_cok
--                    , iv_name                 => cv_msg_cok_00003
--                    , iv_token_name1          => cv_tkn_profile
--                    , iv_token_value1         => cv_t_number
--                    );
--      RAISE error_proc_expt;
--    END IF;
-- Ver.1.21 DEL END
    --==================================================
    -- プロファイル取得(支払案内書_販売手数料計見出し)
    --==================================================
    gv_prompt_bm_sum := FND_PROFILE.VALUE( cv_profile_name_15 );
    IF( gv_prompt_bm_sum IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_15
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払案内書_不課税)
    --==================================================
    gv_tax_free := FND_PROFILE.VALUE( cv_profile_name_16 );
    IF( gv_tax_free IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_16
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払案内書_対象税率)
    --==================================================
    gv_tax_rate := FND_PROFILE.VALUE( cv_profile_name_17 );
    IF( gv_tax_rate IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_17
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払案内書_税込)
    --==================================================
    gv_inc_tax := FND_PROFILE.VALUE( cv_profile_name_18 );
    IF( gv_inc_tax IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_18
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払案内書_税抜)
    --==================================================
    gv_ex_tax := FND_PROFILE.VALUE( cv_profile_name_19 );
    IF( gv_ex_tax IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_19
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払案内書_消費税)
    --==================================================
    gv_tax := FND_PROFILE.VALUE( cv_profile_name_20 );
    IF( gv_tax IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_20
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プロファイル取得(支払案内書_販売手数料)
    --==================================================
    gv_sales_mft := FND_PROFILE.VALUE( cv_profile_name_21 );
    IF( gv_sales_mft IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_21
                    );
      RAISE error_proc_expt;
    END IF;
-- Ver.1.20 ADD END
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_retcode := lv_end_retcode;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_base_code                   IN  VARCHAR2        -- 問合せ先
  , iv_target_ym                   IN  VARCHAR2        -- 案内書発行年月
  , iv_vendor_code                 IN  VARCHAR2        -- 支払先
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  , in_request_id                  IN  NUMBER          -- 要求ID
  , in_output_num                  IN  NUMBER          -- 出力番号
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';          -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 初期処理(A-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_base_code            => iv_base_code          -- 問合せ先
    , iv_target_ym            => iv_target_ym          -- 案内書発行年月
    , iv_vendor_code          => iv_vendor_code        -- 支払先
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
    , in_request_id           => in_request_id         -- 要求ID
    , in_output_num           => in_output_num         -- 出力番号
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD START
--    --==================================================
--    -- データ取得(A-2)・ワークテーブルデータ登録(A-3)
--    --==================================================
--    insert_xrbpd(
--      ov_errbuf               => lv_errbuf                -- エラー・メッセージ
--    , ov_retcode              => lv_retcode               -- リターン・コード
--    , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
    IF in_request_id IS NOT NULL THEN
      --アップロード起動の場合
      --==================================================
      -- 出力対象ワーク取得(A-8)
      --==================================================
      OPEN  g_upload_cur;
      FETCH g_upload_cur BULK COLLECT INTO g_upload_tab;
      CLOSE g_upload_cur;
      --==================================================
      -- アップロード出力対象件数分ループ
      --==================================================
      << g_upload_tab_loop >>
      FOR i IN 1 .. g_upload_tab.COUNT LOOP
        --出力番号が変わった場合
        IF gt_upload_output_num <> g_upload_tab(i).output_num
        AND gt_upload_output_num <> ct_output_num_init THEN
          --==================================================
          -- ワークテーブル支払先毎集約データ取得(A-4)
          --==================================================
          get_xrbpd(
            ov_errbuf               => lv_errbuf                -- エラー・メッセージ
          , ov_retcode              => lv_retcode               -- リターン・コード
          , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --==================================================
          -- 支払案内書（明細）帳票ワークテーブル更新(A-5)
          --==================================================
          update_xrbpd(
            ov_errbuf               => lv_errbuf                -- エラー・メッセージ
          , ov_retcode              => lv_retcode               -- リターン・コード
          , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --==================================================
        -- 検索条件、登録値更新(A-9)
        --==================================================
        gv_param_base_code   := NULL;
        gv_param_target_ym   := SUBSTRB(TO_CHAR(g_upload_tab(i).target_ym), 1, 4) || cv_slash || SUBSTRB(TO_CHAR(g_upload_tab(i).target_ym), 5, 2);
-- Ver.1.21 ADD START
        gd_company_reference_date   := TO_DATE( gv_param_target_ym, cv_format_fxrrrrmm );               -- 会社基準日
-- Ver.1.21 ADD END
        gv_param_vendor_code := g_upload_tab(i).vendor_code;
        gt_upload_cust_code  := g_upload_tab(i).customer_code;
        gt_upload_output_num := g_upload_tab(i).output_num;
        --==================================================
        -- データ取得(A-2)・ワークテーブルデータ登録(A-3)
        --==================================================
        insert_xrbpd(
          ov_errbuf               => lv_errbuf                -- エラー・メッセージ
        , ov_retcode              => lv_retcode               -- リターン・コード
        , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP;
      --
    ELSE
      --画面起動の場合
      --検索値設定
      gt_upload_cust_code := NULL;
      --==================================================
      -- データ取得(A-2)・ワークテーブルデータ登録(A-3)
      --==================================================
      insert_xrbpd(
        ov_errbuf               => lv_errbuf                -- エラー・メッセージ
      , ov_retcode              => lv_retcode               -- リターン・コード
      , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara MOD END
    --==================================================
    -- ワークテーブル支払先毎集約データ取得(A-4)
    --==================================================
    get_xrbpd(
      ov_errbuf               => lv_errbuf                -- エラー・メッセージ
    , ov_retcode              => lv_retcode               -- リターン・コード
    , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 支払案内書（明細）帳票ワークテーブル更新(A-5)
    --==================================================
    update_xrbpd(
      ov_errbuf               => lv_errbuf                -- エラー・メッセージ
    , ov_retcode              => lv_retcode               -- リターン・コード
    , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 確定
    --==================================================
    COMMIT;
    --==================================================
    -- SVF起動(A-6)
    --==================================================
    start_svf(
      ov_errbuf   => lv_errbuf   -- エラー・メッセージ
    , ov_retcode  => lv_retcode  -- リターン・コード
    , ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- ワークテーブルデータ削除(A-7)
    --==================================================
    delete_xrbpd(
      ov_errbuf               => lv_errbuf                -- エラー・メッセージ
    , ov_retcode              => lv_retcode               -- リターン・コード
    , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
    IF in_request_id IS NOT NULL THEN
      --==================================================
      -- 出力対象ワーク削除(A-10)
      --==================================================
      delete_xbsrw(
        ov_errbuf               => lv_errbuf                -- エラー・メッセージ
      , ov_retcode              => lv_retcode               -- リターン・コード
      , ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
    --==================================================
    -- 出力パラメータ設定
    --==================================================
-- Ver.1.17 [障害E_本稼動_15202] SCSK K.Nara MOD START
--    ov_retcode := lv_end_retcode;
    IF gn_target_cnt = 0 THEN
      ov_retcode := cv_status_warn;
    ELSE
      ov_retcode := lv_end_retcode;
    END IF;
-- Ver.1.17 [障害E_本稼動_15202] SCSK K.Nara MOD END
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- エラーメッセージ
  , retcode                        OUT VARCHAR2        -- エラーコード
  , iv_base_code                   IN  VARCHAR2        -- 問合せ先
  , iv_target_ym                   IN  VARCHAR2        -- 案内書発行年月
  , iv_vendor_code                 IN  VARCHAR2        -- 支払先
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
  , in_request_id                  IN  NUMBER          -- 要求ID
  , in_output_num                  IN  NUMBER          -- 出力番号
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- 終了メッセージコード
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    , iv_which                => cv_which_log
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --==================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_base_code            => iv_base_code          -- 問合せ先
    , iv_target_ym            => iv_target_ym          -- 案内書発行年月
    , iv_vendor_code          => iv_vendor_code        -- 支払先
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD START
    , in_request_id           => in_request_id         -- 要求ID
    , in_output_num           => in_output_num         -- 出力番号
-- Ver.1.16 [障害E_本稼動_15005] SCSK K.Nara ADD END
    );
    --==================================================
    -- エラー出力
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG   -- 出力区分
                    , iv_message               => lv_errmsg      -- メッセージ
                    , in_new_line              => 0              -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 1
                    );
    END IF;
    --==================================================
    -- 対象件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- 成功件数出力(エラー発生の場合、成功件数:0件 エラー件数:1件  対象件数0件の場合、成功件数:0件)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- エラー件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
    --==================================================
    -- 処理終了メッセージ出力
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
-- Ver.1.17 [障害E_本稼動_15202] SCSK K.Nara ADD START
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
-- Ver.1.17 [障害E_本稼動_15202] SCSK K.Nara ADD END
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.LOG
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ステータスセット
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- 終了ステータスエラー時、ロールバック
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK015A03R;
/
