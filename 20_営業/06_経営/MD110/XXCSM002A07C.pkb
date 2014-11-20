create or replace PACKAGE BODY XXCSM002A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A07C(body)
 * Description      : 商品計画群別チェックリスト出力
 * MD.050           : 商品計画群別チェックリスト出力 MD050_CSM_002_A07
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  chk_plandata           年間商品計画データ存在チェック(A-2)
 *  set_gun_name           商品群名称の取得および年間計の粗利率算出(A-4)
 *  insert_data            商品群データの登録(A-5,11)
 *  set_gun_data           商品群年間データを変数へ設定(A-6)
 *  set_gun_sum_data       群計の年間データを変数へ設定(A-9)
 *  set_gun_sum_name       群計名称の取得および年間計の粗利率算出(A-10)
 *  set_kyoten_name        拠点名称の取得および年間計の粗利率、差額算出(A-12)
 *  insert_kyoten_data     拠点計を商品計画群別ワークテーブルへ登録(A-13)
 *  set_kyoten_data        拠点の年間データを変数へ設定(A-14)
 *  output_check_list      チェックリストデータ出力(A-15)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-17    1.0   K.Yamada         新規作成
 *  2009-02-10    1.1   M.Ohtsuki       ［障害CT_005］類似機能動作統一修正
 *  2009-02-16    1.2   M.Ohtsuki       ［障害CT_019］分母0の不具合の対応
 *  2009-02-23    1.3   K.Yamada        ［障害CT_058］粗利益率不具合の対応
 *  2011-01-18    1.4   Y.Kanami        ［E_本稼動_05803］
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM'; 
--*** ADD TEMPLETE Start****************************************
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --想定外エラーメッセージ
--*** ADD TEMPLETE Start****************************************
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
  global_data_check_expt    EXCEPTION;     -- データ存在チェック
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCSM002A07C';                 -- パッケージ名
  cv_flg_y         CONSTANT VARCHAR2(1)   := 'Y';                            -- フラグY

  --メッセージーコード
  cv_prof_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';             -- プロファイル取得エラー
  cv_noplandt_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00087';             -- 商品計画未設定
  cv_lst_head_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00091';             -- 年間商品計画群別チェックリストヘッダ用
  cv_nogun_nm_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00105';             -- 商品群名称未設定
  cv_nokyo_nm_msg  CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00106';             -- 拠点名称未設定
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
  cv_csm1_msg_10003         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10003';                           -- 入力パラメータ取得メッセージ(対象年度)
  cv_csm1_msg_00048         CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';                           -- 入力パラメータ取得メッセージ(拠点コード)
--//+ADD END   2009/02/10   CT005 M.Ohtsuki

  --トークン
  cv_tkn_cd_prof   CONSTANT VARCHAR2(100) := 'PROF_NAME';                    -- カスタム・プロファイル・オプションの英名
  cv_tkn_cd_tsym   CONSTANT VARCHAR2(100) := 'TAISYOU_YM';                   -- 対象年度
  cv_tkn_cd_kyoten CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                    -- 拠点コード
  cv_tkn_nm_kyoten CONSTANT VARCHAR2(100) := 'KYOTEN_NM';                    -- 拠点名
  cv_tkn_nichiji   CONSTANT VARCHAR2(100) := 'SAKUSEI_NICHIJI';              -- 作成日時
  cv_tkn_gun_cd    CONSTANT VARCHAR2(100) := 'SHOUHIN_GUN_CD';               -- 商品群コード
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
  cv_tkn_year               CONSTANT VARCHAR2(100) := 'YYYY';                                       -- 対象年度
--//+ADD END   2009/02/10   CT005 M.Ohtsuki
  cv_chk2_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_2';      -- リスト項目テキスト（売上値引）プロファイル名
  cv_chk3_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_3';      -- リスト項目テキスト（入金値引）プロファイル名
  cv_chk5_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_5';      -- リスト項目テキスト（売上予算）プロファイル名
  cv_chk6_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_6';      -- リスト項目テキスト（粗利益額）プロファイル名
  cv_chk7_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_7';      -- リスト項目テキスト（粗利益率）プロファイル名
  cv_chk8_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_8';      -- リスト項目テキスト（値引前売上）プロファイル名
  cv_chk9_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_9';      -- リスト項目テキスト（値引後売上）プロファイル名
  cv_chk10_profile CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_10';     -- リスト項目テキスト（差額）プロファイル名
  cv_chk11_profile CONSTANT VARCHAR2(100) := 'XXCSM1_CHECKLIST_ITEM_11';     -- リスト項目テキスト（群計）プロファイル名

  cv_lookup_type   CONSTANT VARCHAR2(100) := 'XXCSM1_FORM_PARAMETER_VALUE';  -- 全拠点コード取得用

  cv_item_gun      CONSTANT VARCHAR2(1)   := '0';                            -- 商品区分（商品群）

  cv_max_margin_rate CONSTANT NUMBER(15,2):= 9999999999999.99;               -- 格納できる最大粗利益率
  cv_max_rate        CONSTANT NUMBER(15,2):= NULL;                           -- 精度を超える場合の率

--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_work_gun_rtype IS RECORD(
       group_cd                xxcsm_tmp_item_plan_gun.code%TYPE          -- コード
      ,group_nm                xxcsm_tmp_item_plan_gun.code_nm%TYPE       -- 名称
      ,sales_bf_disc_nm        xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- 値引前売上名
      ,sales_bf_disc05         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上５月
      ,sales_bf_disc06         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上６月
      ,sales_bf_disc07         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上７月
      ,sales_bf_disc08         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上８月
      ,sales_bf_disc09         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上９月
      ,sales_bf_disc10         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上１０月
      ,sales_bf_disc11         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上１１月
      ,sales_bf_disc12         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上１２月
      ,sales_bf_disc01         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上１月
      ,sales_bf_disc02         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上２月
      ,sales_bf_disc03         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上３月
      ,sales_bf_disc04         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上４月
      ,sales_bf_disc_total     xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引前売上年間計
      ,sales_af_disc_nm        xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- 値引後売上名
      ,sales_af_disc05         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上５月
      ,sales_af_disc06         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上６月
      ,sales_af_disc07         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上７月
      ,sales_af_disc08         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上８月
      ,sales_af_disc09         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上９月
      ,sales_af_disc10         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上１０月
      ,sales_af_disc11         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上１１月
      ,sales_af_disc12         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上１２月
      ,sales_af_disc01         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上１月
      ,sales_af_disc02         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上２月
      ,sales_af_disc03         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上３月
      ,sales_af_disc04         xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上４月
      ,sales_af_disc_total     xxcsm_tmp_item_plan_gun.total%TYPE         -- 値引後売上年間計
      ,sales_disc_nm           xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- 売上値引名
      ,sales_disc05            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引５月
      ,sales_disc06            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引６月
      ,sales_disc07            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引７月
      ,sales_disc08            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引８月
      ,sales_disc09            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引９月
      ,sales_disc10            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引１０月
      ,sales_disc11            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引１１月
      ,sales_disc12            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引１２月
      ,sales_disc01            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引１月
      ,sales_disc02            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引２月
      ,sales_disc03            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引３月
      ,sales_disc04            xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引４月
      ,sales_disc_total        xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上値引年間計
      ,receipt_disc_nm         xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- 入金値引名
      ,receipt_disc05          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引５月
      ,receipt_disc06          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引６月
      ,receipt_disc07          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引７月
      ,receipt_disc08          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引８月
      ,receipt_disc09          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引９月
      ,receipt_disc10          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引１０月
      ,receipt_disc11          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引１１月
      ,receipt_disc12          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引１２月
      ,receipt_disc01          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引１月
      ,receipt_disc02          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引２月
      ,receipt_disc03          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引３月
      ,receipt_disc04          xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引４月
      ,receipt_disc_total      xxcsm_tmp_item_plan_gun.total%TYPE         -- 入金値引年間計
      ,sales_budget_nm         xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- 売上予算名
      ,sales_budget05          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算５月
      ,sales_budget06          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算６月
      ,sales_budget07          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算７月
      ,sales_budget08          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算８月
      ,sales_budget09          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算９月
      ,sales_budget10          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算１０月
      ,sales_budget11          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算１１月
      ,sales_budget12          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算１２月
      ,sales_budget01          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算１月
      ,sales_budget02          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算２月
      ,sales_budget03          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算３月
      ,sales_budget04          xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算４月
      ,sales_budget_total      xxcsm_tmp_item_plan_gun.total%TYPE         -- 売上予算年間計
      ,margin_nm               xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- 粗利益額名
      ,margin05                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額５月
      ,margin06                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額６月
      ,margin07                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額７月
      ,margin08                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額８月
      ,margin09                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額９月
      ,margin10                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額１０月
      ,margin11                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額１１月
      ,margin12                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額１２月
      ,margin01                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額１月
      ,margin02                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額２月
      ,margin03                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額３月
      ,margin04                xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額４月
      ,margin_total            xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益額年間計
      ,margin_rate_nm          xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- 粗利益率名
      ,margin_rate05           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率５月
      ,margin_rate06           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率６月
      ,margin_rate07           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率７月
      ,margin_rate08           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率８月
      ,margin_rate09           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率９月
      ,margin_rate10           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率１０月
      ,margin_rate11           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率１１月
      ,margin_rate12           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率１２月
      ,margin_rate01           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率１月
      ,margin_rate02           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率２月
      ,margin_rate03           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率３月
      ,margin_rate04           xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率４月
      ,margin_rate_total       xxcsm_tmp_item_plan_gun.total%TYPE         -- 粗利益率年間計
      ,sagaku_nm               xxcsm_tmp_item_plan_gun.item_nm%TYPE       -- 差額名
      ,sagaku05                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額５月
      ,sagaku06                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額６月
      ,sagaku07                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額７月
      ,sagaku08                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額８月
      ,sagaku09                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額９月
      ,sagaku10                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額１０月
      ,sagaku11                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額１１月
      ,sagaku12                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額１２月
      ,sagaku01                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額１月
      ,sagaku02                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額２月
      ,sagaku03                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額３月
      ,sagaku04                xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額４月
      ,sagaku_total            xxcsm_tmp_item_plan_gun.total%TYPE         -- 差額年間計
   );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate           DATE;
  gt_allkyoten_cd      fnd_lookup_values.lookup_code%TYPE;     -- 全拠点コード
  gv_sales_disc_nm     xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- チェックリスト項目名（売上値引）
  gv_receipt_disc_nm   xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- チェックリスト項目名（入金値引）
  gv_sales_budget_nm   xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- チェックリスト項目名（売上予算）
  gv_margin_amt_nm     xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- チェックリスト項目名（粗利益額）
  gv_margin_rate_nm    xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- チェックリスト項目名（粗利益率）
  gv_sales_bf_disc_nm  xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- チェックリスト項目名（値引前売上）
  gv_sales_af_disc_nm  xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- チェックリスト項目名（値引後売上）
  gv_sagaku_nm         xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- チェックリスト項目名（差額）
  gv_total_gun_nm      xxcsm_tmp_item_plan_gun.item_nm%TYPE;   -- チェックリスト項目名（群計）
  gb_all_kyoten        BOOLEAN;                                -- 全拠点チェック
--
  -- ===============================
  -- ローカル・カーソル
  -- ===============================
  -- 商品群データ(A-3)
  CURSOR item_gun_cur(
    in_yyyy         IN  NUMBER,         -- 1.対象年度
    iv_kyoten_cd    IN  VARCHAR2)       -- 2.拠点コード
  IS
    SELECT
       iph.plan_year                    plan_year      -- 予算年度
      ,iph.location_cd                  location_cd    -- 拠点コード
      ,ipl.item_group_no                group_cd       -- 商品群コード
      ,ipl.month_no                     month_no       -- 月
      ,NVL(ipl.sales_budget, 0)         sales_budget   -- 売上金額
      ,NVL(ipl.amount_gross_margin, 0)  margin         -- 粗利益(新)
    FROM
      xxcsm_item_plan_headers    iph,           -- 商品計画ヘッダテーブル
      xxcsm_item_plan_lines      ipl            -- 商品計画明細テーブル
    WHERE
      iph.item_plan_header_id  = ipl.item_plan_header_id
    AND
      iph.plan_year            = in_yyyy
    AND
      iph.location_cd          = iv_kyoten_cd
    AND
      ipl.item_kbn             = cv_item_gun
    ORDER BY
       ipl.item_group_no         -- 商品群コード
      ,ipl.year_month            -- 年月
    ;
    -- 商品群データレコード型
    item_gun_rec                 item_gun_cur%ROWTYPE;

  -- 拠点データ(A-7)
  CURSOR kyoten_cur(
    in_yyyy          IN  NUMBER,         -- 1.対象年度
    iv_kyoten_cd     IN  VARCHAR2,       -- 2.拠点コード
    iv_all_kyoten_cd IN  VARCHAR2)       -- 3.拠点コード
  IS
    SELECT
       iph.plan_year             plan_year      -- 予算年度
      ,iph.location_cd           location_cd    -- 拠点コード
      ,ipl.month_no              month_no       -- 月
      ,NVL(SUM(ipl.amount_gross_margin), 0)     margin               -- 粗利益(新)
      ,NVL(ipb.sales_discount, 0)               sales_disc           -- 売上値引
      ,NVL(ipb.receipt_discount, 0)             receipt_disc         -- 入金値引
      ,NVL(ipb.sales_budget, 0)                 sales_af_disc        -- 値引後売上
      ,NVL(ipb.sales_budget, 0)                 -- 値引後売上
        - NVL(ipb.sales_discount, 0)            -- 売上値引
        - NVL(ipb.receipt_discount, 0)          -- 入金値引
                                                sales_bf_disc        -- 値引前売上
    FROM
       xxcsm_item_plan_headers   iph            -- 商品計画ヘッダテーブル
      ,xxcsm_item_plan_lines     ipl            -- 商品計画明細テーブル
      ,xxcsm_item_plan_loc_bdgt  ipb            -- 商品計画拠点別予算テーブル
    WHERE
      iph.item_plan_header_id  = ipl.item_plan_header_id
    AND
      iph.item_plan_header_id  = ipb.item_plan_header_id
    AND
      iph.plan_year   = in_yyyy
    AND
      ipb.month_no    = ipl.month_no
    AND
      iph.location_cd = DECODE(iv_kyoten_cd, iv_all_kyoten_cd, iph.location_cd, iv_kyoten_cd)
    AND
      ipl.item_kbn    = cv_item_gun
    GROUP BY
       iph.plan_year             -- 予算年度
      ,iph.location_cd           -- 拠点コード
      ,ipl.month_no              -- 月
      ,ipb.sales_discount        -- 売上値引
      ,ipb.receipt_discount      -- 入金値引
      ,ipb.sales_budget          -- 売上予算
    ORDER BY
       iph.plan_year             -- 予算年度
      ,iph.location_cd           -- 拠点コード
      ,ipl.month_no              -- 月
    ;
    -- 拠点データレコード型
    kyoten_rec                   kyoten_cur%ROWTYPE;
--

  -- 群計データ(A-8)
  CURSOR item_gun_sum_cur(
    in_yyyy         IN  NUMBER,         -- 1.対象年度
    iv_kyoten_cd    IN  VARCHAR2)       -- 2.拠点コード
  IS
    SELECT
       iph.plan_year                         plan_year       -- 予算年度
      ,iph.location_cd                       location_cd     -- 拠点コード
      ,ipl.month_no                          month_no        -- 月
      ,NVL(SUM(ipl.sales_budget), 0)         sales_budget    -- 売上金額
      ,NVL(SUM(ipl.amount_gross_margin), 0)  margin          -- 粗利益(新)
    FROM
      xxcsm_item_plan_headers    iph,   --商品計画ヘッダテーブル
      xxcsm_item_plan_lines      ipl    --商品計画明細テーブル
    WHERE
      iph.item_plan_header_id    = ipl.item_plan_header_id
    AND
      iph.plan_year              = in_yyyy
    AND
      iph.location_cd            = iv_kyoten_cd
    AND
      ipl.item_kbn               = cv_item_gun
    GROUP BY
       iph.plan_year             -- 予算年度
      ,iph.location_cd           -- 拠点コード
      ,ipl.month_no              -- 月
    ORDER BY
       iph.plan_year             -- 予算年度
      ,iph.location_cd           -- 拠点コード
      ,ipl.month_no              -- 月
    ;
    -- 群計データレコード型
    item_gun_sum_rec             item_gun_sum_cur%ROWTYPE;

  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_yyyy       IN  VARCHAR2,            -- 1.対象年度
    iv_kyoten_cd  IN  VARCHAR2,            -- 2.拠点コード
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_pram_op      VARCHAR2(100);     -- パラメータメッセージ出力
    ld_process_date DATE;              -- 業務日付
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
    lv_pram_op_1            VARCHAR2(100);                                                          --パラメータ出力用
    lv_pram_op_2            VARCHAR2(100);                                                          --パラメータ出力用
--//+ADD END 2009/02/10   CT005 M.Ohtsuki
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
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
    lv_pram_op_1 := xxccp_common_pkg.get_msg(                                                       -- 拠点コードの出力
                      iv_application  => cv_xxcsm                                                   -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_10003                                          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_year                                                -- トークンコード1（対象年度）
                     ,iv_token_value1 => iv_yyyy                                                    -- トークン値1
                     );
    lv_pram_op_2 := xxccp_common_pkg.get_msg(                                                       -- 対象年度の出力
                      iv_application  => cv_xxcsm                                                   -- アプリケーション短縮名
                     ,iv_name         => cv_csm1_msg_00048                                          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_cd_kyoten                                           -- トークンコード1(拠点コード）
                     ,iv_token_value1 => iv_kyoten_cd                                               -- トークン値1
                     );
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ログに表示
                     ,buff   => lv_pram_op_1  || CHR(10) ||
                                lv_pram_op_2  || CHR(10) ||
                                ''            || CHR(10)                                            -- 空行の挿入
                                );
--//+ADD END 2009/02/10   CT005 M.Ohtsuki
    -- ===========================
    -- システム日付取得処理 
    -- ===========================
    gd_sysdate := SYSDATE;
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- =====================
    -- プロファイル取得処理 
    -- =====================
    --リスト項目テキスト（売上値引）取得
    gv_sales_disc_nm := FND_PROFILE.VALUE(cv_chk2_profile);
    IF (gv_sales_disc_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk2_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --リスト項目テキスト（入金値引）取得
    gv_receipt_disc_nm := FND_PROFILE.VALUE(cv_chk3_profile);
    IF (gv_receipt_disc_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk3_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --リスト項目テキスト（売上予算）取得
    gv_sales_budget_nm := FND_PROFILE.VALUE(cv_chk5_profile);
    IF (gv_sales_budget_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk5_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --リスト項目テキスト（粗利益額）取得
    gv_margin_amt_nm := FND_PROFILE.VALUE(cv_chk6_profile);
    IF (gv_margin_amt_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk6_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --リスト項目テキスト（粗利益率）取得
    gv_margin_rate_nm := FND_PROFILE.VALUE(cv_chk7_profile);
    IF (gv_margin_rate_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk7_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --商品計画リスト項目名（値引前売上）取得
    gv_sales_bf_disc_nm := FND_PROFILE.VALUE(cv_chk8_profile);
    IF (gv_sales_bf_disc_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk8_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --商品計画リスト項目名（値引後売上）取得
    gv_sales_af_disc_nm := FND_PROFILE.VALUE(cv_chk9_profile);
    IF (gv_sales_af_disc_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk9_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --商品計画リスト項目名（差額）取得
    gv_sagaku_nm := FND_PROFILE.VALUE(cv_chk10_profile);
    IF (gv_sagaku_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk10_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    --商品計画リスト項目名（群計）取得
    gv_total_gun_nm := FND_PROFILE.VALUE(cv_chk11_profile);
    IF (gv_total_gun_nm IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_prof_err_msg
                                           ,iv_token_name1  => cv_tkn_cd_prof
                                           ,iv_token_value1 => cv_chk11_profile
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

--
    -- =====================
    -- 全拠点コード取得処理 
    -- =====================
    SELECT
      flv.lookup_code     allkyoten_cd
    INTO
      gt_allkyoten_cd
    FROM
      fnd_lookup_values  flv --クイックコード値
    WHERE
      flv.lookup_type = cv_lookup_type
    AND
      (flv.start_date_active <= ld_process_date OR flv.start_date_active IS NULL)
    AND
      (flv.end_date_active >= ld_process_date OR flv.end_date_active IS NULL)
    AND
      flv.enabled_flag = cv_flg_y
    AND
      ROWNUM = 1
    ;

    IF iv_kyoten_cd = gt_allkyoten_cd THEN
      gb_all_kyoten := TRUE;
    ELSE
      gb_all_kyoten := FALSE;
    END IF;

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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_plandata
   * Description      : 年間商品計画データ存在チェック(A-2)
   ***********************************************************************************/
  PROCEDURE chk_plandata(
    iv_yyyy       IN  VARCHAR2,            -- 1.対象年度
    iv_kyoten_cd  IN  VARCHAR2,            -- 2.拠点コード
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_plandata'; -- プログラム名
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
    ln_cnt           NUMBER;
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
    SELECT
      COUNT(ipl.item_plan_header_id)    cnt
    INTO
      ln_cnt
    FROM
       xxcsm_item_plan_headers  iph   --商品計画ヘッダテーブル
      ,xxcsm_item_plan_lines    ipl   --商品計画明細テーブル
--//+DEL START E_本稼動_05803 Y.Kanami
--      ,xxcsm_item_plan_result   ipr   --商品計画用販売実績テーブル
--//+DEL END E_本稼動_05803 Y.Kanami
    WHERE
        iph.item_plan_header_id = ipl.item_plan_header_id
    AND iph.plan_year           = TO_NUMBER(iv_yyyy)
--//+DEL START E_本稼動_05803 Y.Kanami
--    AND iph.location_cd         = ipr.location_cd
--//+DEL END E_本稼動_05803 Y.Kanami
--//+UPD START E_本稼動_05803 Y.Kanami
--    AND ipr.location_cd         = DECODE(iv_kyoten_cd, gt_allkyoten_cd, ipr.location_cd, iv_kyoten_cd)
    AND iph.location_cd         = DECODE(iv_kyoten_cd, gt_allkyoten_cd, iph.location_cd, iv_kyoten_cd)
--//+UPD END E_本稼動_05803 Y.Kanami
    AND ipl.item_kbn            = cv_item_gun
    AND ROWNUM = 1;

    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_noplandt_msg
                                           ,iv_token_name1  => cv_tkn_cd_tsym
                                           ,iv_token_value1 => iv_yyyy
                                           ,iv_token_name2  => cv_tkn_cd_kyoten
                                           ,iv_token_value2 => iv_kyoten_cd
                                           );
      RAISE global_data_check_expt;
    END IF;

--
  EXCEPTION
    -- *** データ存在チェックエラー ***
    WHEN global_data_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_plandata;
--
  /**********************************************************************************
   * Procedure Name   : set_gun_name
   * Description      : 商品群名称の取得および年間計の粗利率算出(A-4)
   ***********************************************************************************/
  PROCEDURE set_gun_name(
    ior_work_rec   IN OUT g_work_gun_rtype,                -- 商品群変数レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_gun_name'; -- プログラム名
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
    ln_margin_rate         NUMBER;                               -- 粗利益率
    lv_group_nm            mtl_categories_tl.description%TYPE;   -- 商品群名称
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

    --商品群名称取得
    BEGIN
      SELECT
        g3v.item_group_nm     group_nm
      INTO
        lv_group_nm
      FROM
        xxcsm_item_group_3_nm_v      g3v           -- 商品群3桁名称ビュー
      WHERE
        g3v.item_group_cd = ior_work_rec.group_cd  -- 商品群コード
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_nogun_nm_msg
                                             ,iv_token_name1  => cv_tkn_gun_cd
                                             ,iv_token_value1 => ior_work_rec.group_cd
                                             );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff => lv_errmsg --エラーメッセージ
        );
      WHEN OTHERS THEN
        RAISE;
    END;

    --粗利益率年間計
    IF (ior_work_rec.sales_budget_total = 0) THEN
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--    ln_margin_rate := NULL;
      ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
    ELSE
      ln_margin_rate := ROUND(ior_work_rec.margin_total / ior_work_rec.sales_budget_total * 100, 2);
      ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
    END IF;

    -- 登録処理
    ior_work_rec.group_nm            := lv_group_nm;       -- 商品群名称
    ior_work_rec.margin_rate_total   := ln_margin_rate;    -- 粗利益率
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_gun_name;
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : データ登録(A-5,11)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_work_rec    IN  g_work_gun_rtype,                   -- 対象レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 登録処理1行目

    INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
       toroku_no          -- 出力順
      ,code               -- コード
      ,code_nm            -- コード名称
      ,item_nm            -- 項目名
      ,data_05            -- ５月
      ,data_06            -- ６月
      ,data_07            -- ７月
      ,data_08            -- ８月
      ,data_09            -- ９月
      ,data_10            -- １０月
      ,data_11            -- １１月
      ,data_12            -- １２月
      ,data_01            -- １月
      ,data_02            -- ２月
      ,data_03            -- ３月
      ,data_04            -- ４月
      ,total              -- 年間計
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,ir_work_rec.group_cd                  -- 商品群コード
      ,ir_work_rec.group_nm                  -- 商品群名称
      ,ir_work_rec.sales_budget_nm           -- 売上予算名
      ,ir_work_rec.sales_budget05            -- 売上予算５月
      ,ir_work_rec.sales_budget06            -- 売上予算６月
      ,ir_work_rec.sales_budget07            -- 売上予算７月
      ,ir_work_rec.sales_budget08            -- 売上予算８月
      ,ir_work_rec.sales_budget09            -- 売上予算９月
      ,ir_work_rec.sales_budget10            -- 売上予算１０月
      ,ir_work_rec.sales_budget11            -- 売上予算１１月
      ,ir_work_rec.sales_budget12            -- 売上予算１２月
      ,ir_work_rec.sales_budget01            -- 売上予算１月
      ,ir_work_rec.sales_budget02            -- 売上予算２月
      ,ir_work_rec.sales_budget03            -- 売上予算３月
      ,ir_work_rec.sales_budget04            -- 売上予算４月
      ,ir_work_rec.sales_budget_total        -- 売上予算年間計
    );
--
    -- 登録処理2行目
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
       toroku_no          -- 出力順
      ,code               -- コード
      ,code_nm            -- コード名称
      ,item_nm            -- 項目名
      ,data_05            -- ５月
      ,data_06            -- ６月
      ,data_07            -- ７月
      ,data_08            -- ８月
      ,data_09            -- ９月
      ,data_10            -- １０月
      ,data_11            -- １１月
      ,data_12            -- １２月
      ,data_01            -- １月
      ,data_02            -- ２月
      ,data_03            -- ３月
      ,data_04            -- ４月
      ,total              -- 年間計
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- 商品群コード
      ,NULL                                  -- 商品群名称
      ,ir_work_rec.margin_nm                 -- 粗利益額名
      ,ir_work_rec.margin05                  -- 粗利益額５月
      ,ir_work_rec.margin06                  -- 粗利益額６月
      ,ir_work_rec.margin07                  -- 粗利益額７月
      ,ir_work_rec.margin08                  -- 粗利益額８月
      ,ir_work_rec.margin09                  -- 粗利益額９月
      ,ir_work_rec.margin10                  -- 粗利益額１０月
      ,ir_work_rec.margin11                  -- 粗利益額１１月
      ,ir_work_rec.margin12                  -- 粗利益額１２月
      ,ir_work_rec.margin01                  -- 粗利益額１月
      ,ir_work_rec.margin02                  -- 粗利益額２月
      ,ir_work_rec.margin03                  -- 粗利益額３月
      ,ir_work_rec.margin04                  -- 粗利益額４月
      ,ir_work_rec.margin_total              -- 粗利益額年間計
    );
--
    -- 登録処理3行目
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
       toroku_no          -- 出力順
      ,code               -- コード
      ,code_nm            -- コード名称
      ,item_nm            -- 項目名
      ,data_05            -- ５月
      ,data_06            -- ６月
      ,data_07            -- ７月
      ,data_08            -- ８月
      ,data_09            -- ９月
      ,data_10            -- １０月
      ,data_11            -- １１月
      ,data_12            -- １２月
      ,data_01            -- １月
      ,data_02            -- ２月
      ,data_03            -- ３月
      ,data_04            -- ４月
      ,total              -- 年間計
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- 商品群コード
      ,NULL                                  -- 商品群名称
      ,ir_work_rec.margin_rate_nm            -- 粗利益率名
      ,ir_work_rec.margin_rate05             -- 粗利益率５月
      ,ir_work_rec.margin_rate06             -- 粗利益率６月
      ,ir_work_rec.margin_rate07             -- 粗利益率７月
      ,ir_work_rec.margin_rate08             -- 粗利益率８月
      ,ir_work_rec.margin_rate09             -- 粗利益率９月
      ,ir_work_rec.margin_rate10             -- 粗利益率１０月
      ,ir_work_rec.margin_rate11             -- 粗利益率１１月
      ,ir_work_rec.margin_rate12             -- 粗利益率１２月
      ,ir_work_rec.margin_rate01             -- 粗利益率１月
      ,ir_work_rec.margin_rate02             -- 粗利益率２月
      ,ir_work_rec.margin_rate03             -- 粗利益率３月
      ,ir_work_rec.margin_rate04             -- 粗利益率４月
      ,ir_work_rec.margin_rate_total         -- 粗利益率年間計
    );
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : set_gun_data
   * Description      : 商品群年間データを変数へ設定(A-6)
   ***********************************************************************************/
  PROCEDURE set_gun_data(
    ir_gun_rec     IN  item_gun_cur%ROWTYPE,               -- 商品群年間レコード
    ior_work_rec   IN OUT g_work_gun_rtype,                -- 商品群変数レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_gun_data'; -- プログラム名
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
    ln_margin_rate         NUMBER;    --粗利益率
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
    --粗利益率
    IF (ir_gun_rec.sales_budget = 0) THEN
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--    ln_margin_rate := NULL;
      ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
    ELSE
      ln_margin_rate := ROUND(ir_gun_rec.margin / ir_gun_rec.sales_budget * 100, 2);
      ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
    END IF;

    -- 登録処理
    ior_work_rec.group_cd            := ir_gun_rec.group_cd;      -- 商品群コード
    ior_work_rec.sales_budget_nm     := gv_sales_budget_nm;       -- 売上予算名
    ior_work_rec.margin_nm           := gv_margin_amt_nm;         -- 粗利益額名
    ior_work_rec.margin_rate_nm      := gv_margin_rate_nm;        -- 粗利益率名
    CASE ir_gun_rec.month_no
    WHEN 5 THEN
      ior_work_rec.sales_budget05      := ir_gun_rec.sales_budget;  -- 売上予算５月
      ior_work_rec.margin05            := ir_gun_rec.margin;        -- 粗利益額５月
      ior_work_rec.margin_rate05       := ln_margin_rate;           -- 粗利益率５月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 6 THEN
      ior_work_rec.sales_budget06      := ir_gun_rec.sales_budget;  -- 売上予算６月
      ior_work_rec.margin06            := ir_gun_rec.margin;        -- 粗利益額６月
      ior_work_rec.margin_rate06       := ln_margin_rate;           -- 粗利益率６月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 7 THEN
      ior_work_rec.sales_budget07      := ir_gun_rec.sales_budget;  -- 売上予算７月
      ior_work_rec.margin07            := ir_gun_rec.margin;        -- 粗利益額７月
      ior_work_rec.margin_rate07       := ln_margin_rate;           -- 粗利益率７月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 8 THEN
      ior_work_rec.sales_budget08      := ir_gun_rec.sales_budget;  -- 売上予算８月
      ior_work_rec.margin08            := ir_gun_rec.margin;        -- 粗利益額８月
      ior_work_rec.margin_rate08       := ln_margin_rate;           -- 粗利益率８月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 9 THEN
      ior_work_rec.sales_budget09      := ir_gun_rec.sales_budget;  -- 売上予算９月
      ior_work_rec.margin09            := ir_gun_rec.margin;        -- 粗利益額９月
      ior_work_rec.margin_rate09       := ln_margin_rate;           -- 粗利益率９月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 10 THEN
      ior_work_rec.sales_budget10      := ir_gun_rec.sales_budget;  -- 売上予算１０月
      ior_work_rec.margin10            := ir_gun_rec.margin;        -- 粗利益額１０月
      ior_work_rec.margin_rate10       := ln_margin_rate;           -- 粗利益率１０月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 11 THEN
      ior_work_rec.sales_budget11      := ir_gun_rec.sales_budget;  -- 売上予算１１月
      ior_work_rec.margin11            := ir_gun_rec.margin;        -- 粗利益額１１月
      ior_work_rec.margin_rate11       := ln_margin_rate;           -- 粗利益率１１月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 12 THEN
      ior_work_rec.sales_budget12      := ir_gun_rec.sales_budget;  -- 売上予算１２月
      ior_work_rec.margin12            := ir_gun_rec.margin;        -- 粗利益額１２月
      ior_work_rec.margin_rate12       := ln_margin_rate;           -- 粗利益率１２月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 1 THEN
      ior_work_rec.sales_budget01      := ir_gun_rec.sales_budget;  -- 売上予算１月
      ior_work_rec.margin01            := ir_gun_rec.margin;        -- 粗利益額１月
      ior_work_rec.margin_rate01       := ln_margin_rate;           -- 粗利益率１月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 2 THEN
      ior_work_rec.sales_budget02      := ir_gun_rec.sales_budget;  -- 売上予算２月
      ior_work_rec.margin02            := ir_gun_rec.margin;        -- 粗利益額２月
      ior_work_rec.margin_rate02       := ln_margin_rate;           -- 粗利益率２月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 3 THEN
      ior_work_rec.sales_budget03      := ir_gun_rec.sales_budget;  -- 売上予算３月
      ior_work_rec.margin03            := ir_gun_rec.margin;        -- 粗利益額３月
      ior_work_rec.margin_rate03       := ln_margin_rate;           -- 粗利益率３月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    WHEN 4 THEN
      ior_work_rec.sales_budget04      := ir_gun_rec.sales_budget;  -- 売上予算４月
      ior_work_rec.margin04            := ir_gun_rec.margin;        -- 粗利益額４月
      ior_work_rec.margin_rate04       := ln_margin_rate;           -- 粗利益率４月
      ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_gun_rec.sales_budget;  -- 売上予算年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_gun_rec.margin;        -- 粗利益額年間計
    ELSE
      NULL;
    END CASE;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_gun_data;
--
  /**********************************************************************************
   * Procedure Name   : set_gun_sum_data
   * Description      : 群計の年間データを変数へ設定(A-9)
   ***********************************************************************************/
  PROCEDURE set_gun_sum_data(
    ir_sum_rec     IN  item_gun_sum_cur%ROWTYPE,           -- 群計レコード
    ior_work_rec   IN OUT g_work_gun_rtype,                -- 群計変数レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_gun_sum_data'; -- プログラム名
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
    ln_margin_rate         NUMBER;    --粗利益率
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
    -- 全拠点の場合は売上予算のみ対象（拠点計の計算のため）
    IF (gb_all_kyoten = TRUE) THEN
      CASE ir_sum_rec.month_no
      WHEN 5 THEN
        ior_work_rec.sales_budget05      := ir_sum_rec.sales_budget;  -- 売上予算５月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 6 THEN
        ior_work_rec.sales_budget06      := ir_sum_rec.sales_budget;  -- 売上予算６月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 7 THEN
        ior_work_rec.sales_budget07      := ir_sum_rec.sales_budget;  -- 売上予算７月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 8 THEN
        ior_work_rec.sales_budget08      := ir_sum_rec.sales_budget;  -- 売上予算８月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 9 THEN
        ior_work_rec.sales_budget09      := ir_sum_rec.sales_budget;  -- 売上予算９月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 10 THEN
        ior_work_rec.sales_budget10      := ir_sum_rec.sales_budget;  -- 売上予算１０月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 11 THEN
        ior_work_rec.sales_budget11      := ir_sum_rec.sales_budget;  -- 売上予算１１月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 12 THEN
        ior_work_rec.sales_budget12      := ir_sum_rec.sales_budget;  -- 売上予算１２月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 1 THEN
        ior_work_rec.sales_budget01      := ir_sum_rec.sales_budget;  -- 売上予算１月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 2 THEN
        ior_work_rec.sales_budget02      := ir_sum_rec.sales_budget;  -- 売上予算２月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 3 THEN
        ior_work_rec.sales_budget03      := ir_sum_rec.sales_budget;  -- 売上予算３月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      WHEN 4 THEN
        ior_work_rec.sales_budget04      := ir_sum_rec.sales_budget;  -- 売上予算４月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
      ELSE
        NULL;
      END CASE;
    ELSE
      --粗利益率
      IF (ir_sum_rec.sales_budget = 0) THEN
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--      ln_margin_rate := NULL;
        ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
      ELSE
        ln_margin_rate := ROUND(ir_sum_rec.margin / ir_sum_rec.sales_budget * 100, 2);
        ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
      END IF;

      -- 登録処理
      ior_work_rec.group_cd            := NULL;                     -- コード
      ior_work_rec.sales_budget_nm     := gv_sales_budget_nm;       -- 売上予算名
      ior_work_rec.margin_nm           := gv_margin_amt_nm;         -- 粗利益額名
      ior_work_rec.margin_rate_nm      := gv_margin_rate_nm;        -- 粗利益率名
      CASE ir_sum_rec.month_no
      WHEN 5 THEN
        ior_work_rec.sales_budget05      := ir_sum_rec.sales_budget;  -- 売上予算５月
        ior_work_rec.margin05            := ir_sum_rec.margin;        -- 粗利益額５月
        ior_work_rec.margin_rate05       := ln_margin_rate;           -- 粗利益率５月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 6 THEN
        ior_work_rec.sales_budget06      := ir_sum_rec.sales_budget;  -- 売上予算６月
        ior_work_rec.margin06            := ir_sum_rec.margin;        -- 粗利益額６月
        ior_work_rec.margin_rate06       := ln_margin_rate;           -- 粗利益率６月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 7 THEN
        ior_work_rec.sales_budget07      := ir_sum_rec.sales_budget;  -- 売上予算７月
        ior_work_rec.margin07            := ir_sum_rec.margin;        -- 粗利益額７月
        ior_work_rec.margin_rate07       := ln_margin_rate;           -- 粗利益率７月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 8 THEN
        ior_work_rec.sales_budget08      := ir_sum_rec.sales_budget;  -- 売上予算８月
        ior_work_rec.margin08            := ir_sum_rec.margin;        -- 粗利益額８月
        ior_work_rec.margin_rate08       := ln_margin_rate;           -- 粗利益率８月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 9 THEN
        ior_work_rec.sales_budget09      := ir_sum_rec.sales_budget;  -- 売上予算９月
        ior_work_rec.margin09            := ir_sum_rec.margin;        -- 粗利益額９月
        ior_work_rec.margin_rate09       := ln_margin_rate;           -- 粗利益率９月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 10 THEN
        ior_work_rec.sales_budget10      := ir_sum_rec.sales_budget;  -- 売上予算１０月
        ior_work_rec.margin10            := ir_sum_rec.margin;        -- 粗利益額１０月
        ior_work_rec.margin_rate10       := ln_margin_rate;           -- 粗利益率１０月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 11 THEN
        ior_work_rec.sales_budget11      := ir_sum_rec.sales_budget;  -- 売上予算１１月
        ior_work_rec.margin11            := ir_sum_rec.margin;        -- 粗利益額１１月
        ior_work_rec.margin_rate11       := ln_margin_rate;           -- 粗利益率１１月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 12 THEN
        ior_work_rec.sales_budget12      := ir_sum_rec.sales_budget;  -- 売上予算１２月
        ior_work_rec.margin12            := ir_sum_rec.margin;        -- 粗利益額１２月
        ior_work_rec.margin_rate12       := ln_margin_rate;           -- 粗利益率１２月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 1 THEN
        ior_work_rec.sales_budget01      := ir_sum_rec.sales_budget;  -- 売上予算１月
        ior_work_rec.margin01            := ir_sum_rec.margin;        -- 粗利益額１月
        ior_work_rec.margin_rate01       := ln_margin_rate;           -- 粗利益率１月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 2 THEN
        ior_work_rec.sales_budget02      := ir_sum_rec.sales_budget;  -- 売上予算２月
        ior_work_rec.margin02            := ir_sum_rec.margin;        -- 粗利益額２月
        ior_work_rec.margin_rate02       := ln_margin_rate;           -- 粗利益率２月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 3 THEN
        ior_work_rec.sales_budget03      := ir_sum_rec.sales_budget;  -- 売上予算３月
        ior_work_rec.margin03            := ir_sum_rec.margin;        -- 粗利益額３月
        ior_work_rec.margin_rate03       := ln_margin_rate;           -- 粗利益率３月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      WHEN 4 THEN
        ior_work_rec.sales_budget04      := ir_sum_rec.sales_budget;  -- 売上予算４月
        ior_work_rec.margin04            := ir_sum_rec.margin;        -- 粗利益額４月
        ior_work_rec.margin_rate04       := ln_margin_rate;           -- 粗利益率４月
        -- 売上予算年間計
        ior_work_rec.sales_budget_total  := NVL(ior_work_rec.sales_budget_total, 0) + ir_sum_rec.sales_budget;
        -- 粗利益額年間計
        ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)       + ir_sum_rec.margin;
      ELSE
        NULL;
      END CASE;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_gun_sum_data;
--
  /**********************************************************************************
   * Procedure Name   : set_gun_sum_name
   * Description      : 群計名称の取得および年間計の粗利率算出(A-10)
   ***********************************************************************************/
  PROCEDURE set_gun_sum_name(
    ior_work_rec   IN OUT g_work_gun_rtype,                -- 群計変数レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_gun_sum_name'; -- プログラム名
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
    ln_margin_rate         NUMBER;                               -- 粗利益率
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

    --粗利益率年間計
    IF (ior_work_rec.sales_budget_total = 0) THEN
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--    ln_margin_rate := NULL;
      ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
    ELSE
      ln_margin_rate := ROUND(ior_work_rec.margin_total / ior_work_rec.sales_budget_total * 100, 2);
      ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
    END IF;

    -- 登録処理
    ior_work_rec.group_nm            := gv_total_gun_nm;   -- 群計名称
    ior_work_rec.margin_rate_total   := ln_margin_rate;    -- 粗利益率
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_gun_sum_name;
--
  /**********************************************************************************
   * Procedure Name   : set_kyoten_name
   * Description      : 拠点名称の取得および年間計の粗利率、差額算出(A-12)
   ***********************************************************************************/
  PROCEDURE set_kyoten_name(
    ir_sum_rec     IN  g_work_gun_rtype,                   -- 群計変数レコード
    ior_work_rec   IN OUT g_work_gun_rtype,                -- 拠点変数レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_kyoten_name'; -- プログラム名
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
    cv_kyoten          CONSTANT VARCHAR2(1)  := '1';             -- 顧客区分（拠点名称）
--
    -- *** ローカル変数 ***
    ln_margin_rate         NUMBER;                               -- 粗利益率
    lv_kyoten_nm           hz_parties.party_name%TYPE;           -- 拠点名称
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

    --拠点名称取得
    BEGIN
      SELECT
        hps.party_name         kyoten_nm
      INTO
        lv_kyoten_nm
      FROM
         hz_cust_accounts      hca                     -- 顧客マスタ
        ,hz_parties            hps
      WHERE
        hca.party_id = hps.party_id                    -- 
      AND
        hca.customer_class_code = cv_kyoten            -- 顧客区分
      AND
        hca.account_number = ior_work_rec.group_cd     -- 顧客コード
      AND
        ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_nokyo_nm_msg
                                             ,iv_token_name1  => cv_tkn_cd_kyoten
                                             ,iv_token_value1 => ior_work_rec.group_cd
                                             );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff => lv_errmsg --エラーメッセージ
        );
      WHEN OTHERS THEN
        RAISE;
    END;

    --粗利益率年間計
--//+UPD START 2009/02/23   CT058 K.Yamada
--  IF (ior_work_rec.sales_af_disc_total = 0) THEN
    IF (ior_work_rec.sales_bf_disc_total = 0) THEN
--//+UPD END   2009/02/23   CT058 K.Yamada
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--    ln_margin_rate := NULL;
      ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
    ELSE
--//+UPD START 2009/02/23   CT058 K.Yamada
--    ln_margin_rate := ROUND(ior_work_rec.margin_total / ior_work_rec.sales_af_disc_total * 100, 2);
      ln_margin_rate := ROUND(ior_work_rec.margin_total / ior_work_rec.sales_bf_disc_total * 100, 2);
--//+UPD END   2009/02/23   CT058 K.Yamada
      ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
    END IF;

    -- 登録処理
    ior_work_rec.group_nm            := lv_kyoten_nm;      -- 拠点名称
    ior_work_rec.margin_rate_total   := ln_margin_rate;    -- 粗利益率

    ior_work_rec.sagaku_nm           := gv_sagaku_nm;      -- 差額名

    ior_work_rec.sagaku05        := ior_work_rec.sales_bf_disc05     - ir_sum_rec.sales_budget05;      -- 差額５月
    ior_work_rec.sagaku06        := ior_work_rec.sales_bf_disc06     - ir_sum_rec.sales_budget06;      -- 差額６月
    ior_work_rec.sagaku07        := ior_work_rec.sales_bf_disc07     - ir_sum_rec.sales_budget07;      -- 差額７月
    ior_work_rec.sagaku08        := ior_work_rec.sales_bf_disc08     - ir_sum_rec.sales_budget08;      -- 差額８月
    ior_work_rec.sagaku09        := ior_work_rec.sales_bf_disc09     - ir_sum_rec.sales_budget09;      -- 差額９月
    ior_work_rec.sagaku10        := ior_work_rec.sales_bf_disc10     - ir_sum_rec.sales_budget10;      -- 差額１０月
    ior_work_rec.sagaku11        := ior_work_rec.sales_bf_disc11     - ir_sum_rec.sales_budget11;      -- 差額１１月
    ior_work_rec.sagaku12        := ior_work_rec.sales_bf_disc12     - ir_sum_rec.sales_budget12;      -- 差額１２月
    ior_work_rec.sagaku01        := ior_work_rec.sales_bf_disc01     - ir_sum_rec.sales_budget01;      -- 差額１月
    ior_work_rec.sagaku02        := ior_work_rec.sales_bf_disc02     - ir_sum_rec.sales_budget02;      -- 差額２月
    ior_work_rec.sagaku03        := ior_work_rec.sales_bf_disc03     - ir_sum_rec.sales_budget03;      -- 差額３月
    ior_work_rec.sagaku04        := ior_work_rec.sales_bf_disc04     - ir_sum_rec.sales_budget04;      -- 差額４月
    ior_work_rec.sagaku_total    := ior_work_rec.sales_bf_disc_total - ir_sum_rec.sales_budget_total;

--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_kyoten_name;
--
  /**********************************************************************************
   * Procedure Name   : insert_kyoten_data
   * Description      : 拠点計を商品計画群別ワークテーブルへ登録(A-13)
   ***********************************************************************************/
  PROCEDURE insert_kyoten_data(
    ir_work_rec    IN  g_work_gun_rtype,                   -- 拠点変数レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_kyoten_data'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF NOT ((gb_all_kyoten = TRUE) AND (gn_target_cnt = 1)) THEN
      -- 空行
      INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
         toroku_no          -- 出力順
      )VALUES(
         xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      );
    END IF;
--


    -- 登録処理1行目
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
       toroku_no          -- 出力順
      ,code               -- コード
      ,code_nm            -- コード名称
      ,item_nm            -- 項目名
      ,data_05            -- ５月
      ,data_06            -- ６月
      ,data_07            -- ７月
      ,data_08            -- ８月
      ,data_09            -- ９月
      ,data_10            -- １０月
      ,data_11            -- １１月
      ,data_12            -- １２月
      ,data_01            -- １月
      ,data_02            -- ２月
      ,data_03            -- ３月
      ,data_04            -- ４月
      ,total              -- 年間計
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,ir_work_rec.group_cd                  -- コード
      ,ir_work_rec.group_nm                  -- 名称
      ,ir_work_rec.sales_bf_disc_nm          -- 値引前売上名
      ,ir_work_rec.sales_bf_disc05           -- 値引前売上５月
      ,ir_work_rec.sales_bf_disc06           -- 値引前売上６月
      ,ir_work_rec.sales_bf_disc07           -- 値引前売上７月
      ,ir_work_rec.sales_bf_disc08           -- 値引前売上８月
      ,ir_work_rec.sales_bf_disc09           -- 値引前売上９月
      ,ir_work_rec.sales_bf_disc10           -- 値引前売上１０月
      ,ir_work_rec.sales_bf_disc11           -- 値引前売上１１月
      ,ir_work_rec.sales_bf_disc12           -- 値引前売上１２月
      ,ir_work_rec.sales_bf_disc01           -- 値引前売上１月
      ,ir_work_rec.sales_bf_disc02           -- 値引前売上２月
      ,ir_work_rec.sales_bf_disc03           -- 値引前売上３月
      ,ir_work_rec.sales_bf_disc04           -- 値引前売上４月
      ,ir_work_rec.sales_bf_disc_total       -- 値引前売上年間計
    );
--
    -- 登録処理2行目
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
       toroku_no          -- 出力順
      ,code               -- コード
      ,code_nm            -- コード名称
      ,item_nm            -- 項目名
      ,data_05            -- ５月
      ,data_06            -- ６月
      ,data_07            -- ７月
      ,data_08            -- ８月
      ,data_09            -- ９月
      ,data_10            -- １０月
      ,data_11            -- １１月
      ,data_12            -- １２月
      ,data_01            -- １月
      ,data_02            -- ２月
      ,data_03            -- ３月
      ,data_04            -- ４月
      ,total              -- 年間計
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- コード
      ,NULL                                  -- 名称
      ,ir_work_rec.sales_disc_nm             -- 売上値引名
      ,ir_work_rec.sales_disc05              -- 売上値引５月
      ,ir_work_rec.sales_disc06              -- 売上値引６月
      ,ir_work_rec.sales_disc07              -- 売上値引７月
      ,ir_work_rec.sales_disc08              -- 売上値引８月
      ,ir_work_rec.sales_disc09              -- 売上値引９月
      ,ir_work_rec.sales_disc10              -- 売上値引１０月
      ,ir_work_rec.sales_disc11              -- 売上値引１１月
      ,ir_work_rec.sales_disc12              -- 売上値引１２月
      ,ir_work_rec.sales_disc01              -- 売上値引１月
      ,ir_work_rec.sales_disc02              -- 売上値引２月
      ,ir_work_rec.sales_disc03              -- 売上値引３月
      ,ir_work_rec.sales_disc04              -- 売上値引４月
      ,ir_work_rec.sales_disc_total          -- 売上値引年間計
    );
--
    -- 登録処理3行目
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
       toroku_no          -- 出力順
      ,code               -- コード
      ,code_nm            -- コード名称
      ,item_nm            -- 項目名
      ,data_05            -- ５月
      ,data_06            -- ６月
      ,data_07            -- ７月
      ,data_08            -- ８月
      ,data_09            -- ９月
      ,data_10            -- １０月
      ,data_11            -- １１月
      ,data_12            -- １２月
      ,data_01            -- １月
      ,data_02            -- ２月
      ,data_03            -- ３月
      ,data_04            -- ４月
      ,total              -- 年間計
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- コード
      ,NULL                                  -- 名称
      ,ir_work_rec.receipt_disc_nm           -- 入金値引名
      ,ir_work_rec.receipt_disc05            -- 入金値引５月
      ,ir_work_rec.receipt_disc06            -- 入金値引６月
      ,ir_work_rec.receipt_disc07            -- 入金値引７月
      ,ir_work_rec.receipt_disc08            -- 入金値引８月
      ,ir_work_rec.receipt_disc09            -- 入金値引９月
      ,ir_work_rec.receipt_disc10            -- 入金値引１０月
      ,ir_work_rec.receipt_disc11            -- 入金値引１１月
      ,ir_work_rec.receipt_disc12            -- 入金値引１２月
      ,ir_work_rec.receipt_disc01            -- 入金値引１月
      ,ir_work_rec.receipt_disc02            -- 入金値引２月
      ,ir_work_rec.receipt_disc03            -- 入金値引３月
      ,ir_work_rec.receipt_disc04            -- 入金値引４月
      ,ir_work_rec.receipt_disc_total        -- 入金値引年間計
    );
--
    -- 登録処理4行目
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
       toroku_no          -- 出力順
      ,code               -- コード
      ,code_nm            -- コード名称
      ,item_nm            -- 項目名
      ,data_05            -- ５月
      ,data_06            -- ６月
      ,data_07            -- ７月
      ,data_08            -- ８月
      ,data_09            -- ９月
      ,data_10            -- １０月
      ,data_11            -- １１月
      ,data_12            -- １２月
      ,data_01            -- １月
      ,data_02            -- ２月
      ,data_03            -- ３月
      ,data_04            -- ４月
      ,total              -- 年間計
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- コード
      ,NULL                                  -- 名称
      ,ir_work_rec.sales_af_disc_nm          -- 値引後売上名
      ,ir_work_rec.sales_af_disc05           -- 値引後売上５月
      ,ir_work_rec.sales_af_disc06           -- 値引後売上６月
      ,ir_work_rec.sales_af_disc07           -- 値引後売上７月
      ,ir_work_rec.sales_af_disc08           -- 値引後売上８月
      ,ir_work_rec.sales_af_disc09           -- 値引後売上９月
      ,ir_work_rec.sales_af_disc10           -- 値引後売上１０月
      ,ir_work_rec.sales_af_disc11           -- 値引後売上１１月
      ,ir_work_rec.sales_af_disc12           -- 値引後売上１２月
      ,ir_work_rec.sales_af_disc01           -- 値引後売上１月
      ,ir_work_rec.sales_af_disc02           -- 値引後売上２月
      ,ir_work_rec.sales_af_disc03           -- 値引後売上３月
      ,ir_work_rec.sales_af_disc04           -- 値引後売上４月
      ,ir_work_rec.sales_af_disc_total       -- 値引後売上年間計
    );
--
    -- 登録処理5行目
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
       toroku_no          -- 出力順
      ,code               -- コード
      ,code_nm            -- コード名称
      ,item_nm            -- 項目名
      ,data_05            -- ５月
      ,data_06            -- ６月
      ,data_07            -- ７月
      ,data_08            -- ８月
      ,data_09            -- ９月
      ,data_10            -- １０月
      ,data_11            -- １１月
      ,data_12            -- １２月
      ,data_01            -- １月
      ,data_02            -- ２月
      ,data_03            -- ３月
      ,data_04            -- ４月
      ,total              -- 年間計
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- コード
      ,NULL                                  -- 名称
      ,ir_work_rec.margin_nm                 -- 粗利益額名
      ,ir_work_rec.margin05                  -- 粗利益額５月
      ,ir_work_rec.margin06                  -- 粗利益額６月
      ,ir_work_rec.margin07                  -- 粗利益額７月
      ,ir_work_rec.margin08                  -- 粗利益額８月
      ,ir_work_rec.margin09                  -- 粗利益額９月
      ,ir_work_rec.margin10                  -- 粗利益額１０月
      ,ir_work_rec.margin11                  -- 粗利益額１１月
      ,ir_work_rec.margin12                  -- 粗利益額１２月
      ,ir_work_rec.margin01                  -- 粗利益額１月
      ,ir_work_rec.margin02                  -- 粗利益額２月
      ,ir_work_rec.margin03                  -- 粗利益額３月
      ,ir_work_rec.margin04                  -- 粗利益額４月
      ,ir_work_rec.margin_total              -- 粗利益額年間計
    );
--
    -- 登録処理6行目
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
       toroku_no          -- 出力順
      ,code               -- コード
      ,code_nm            -- コード名称
      ,item_nm            -- 項目名
      ,data_05            -- ５月
      ,data_06            -- ６月
      ,data_07            -- ７月
      ,data_08            -- ８月
      ,data_09            -- ９月
      ,data_10            -- １０月
      ,data_11            -- １１月
      ,data_12            -- １２月
      ,data_01            -- １月
      ,data_02            -- ２月
      ,data_03            -- ３月
      ,data_04            -- ４月
      ,total              -- 年間計
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- 商品群コード
      ,NULL                                  -- 商品群名称
      ,ir_work_rec.margin_rate_nm            -- 粗利益率名
      ,ir_work_rec.margin_rate05             -- 粗利益率５月
      ,ir_work_rec.margin_rate06             -- 粗利益率６月
      ,ir_work_rec.margin_rate07             -- 粗利益率７月
      ,ir_work_rec.margin_rate08             -- 粗利益率８月
      ,ir_work_rec.margin_rate09             -- 粗利益率９月
      ,ir_work_rec.margin_rate10             -- 粗利益率１０月
      ,ir_work_rec.margin_rate11             -- 粗利益率１１月
      ,ir_work_rec.margin_rate12             -- 粗利益率１２月
      ,ir_work_rec.margin_rate01             -- 粗利益率１月
      ,ir_work_rec.margin_rate02             -- 粗利益率２月
      ,ir_work_rec.margin_rate03             -- 粗利益率３月
      ,ir_work_rec.margin_rate04             -- 粗利益率４月
      ,ir_work_rec.margin_rate_total         -- 粗利益率年間計
    );
--
    -- 登録処理7行目
    INSERT INTO xxcsm_tmp_item_plan_gun(     -- 商品計画群別ワークテーブル
       toroku_no          -- 出力順
      ,code               -- コード
      ,code_nm            -- コード名称
      ,item_nm            -- 項目名
      ,data_05            -- ５月
      ,data_06            -- ６月
      ,data_07            -- ７月
      ,data_08            -- ８月
      ,data_09            -- ９月
      ,data_10            -- １０月
      ,data_11            -- １１月
      ,data_12            -- １２月
      ,data_01            -- １月
      ,data_02            -- ２月
      ,data_03            -- ３月
      ,data_04            -- ４月
      ,total              -- 年間計
    )VALUES(
       xxcsm_tmp_item_plan_gun_s01.NEXTVAL
      ,NULL                                  -- 商品群コード
      ,NULL                                  -- 商品群名称
      ,ir_work_rec.sagaku_nm            -- 差額名
      ,ir_work_rec.sagaku05             -- 差額５月
      ,ir_work_rec.sagaku06             -- 差額６月
      ,ir_work_rec.sagaku07             -- 差額７月
      ,ir_work_rec.sagaku08             -- 差額８月
      ,ir_work_rec.sagaku09             -- 差額９月
      ,ir_work_rec.sagaku10             -- 差額１０月
      ,ir_work_rec.sagaku11             -- 差額１１月
      ,ir_work_rec.sagaku12             -- 差額１２月
      ,ir_work_rec.sagaku01             -- 差額１月
      ,ir_work_rec.sagaku02             -- 差額２月
      ,ir_work_rec.sagaku03             -- 差額３月
      ,ir_work_rec.sagaku04             -- 差額４月
      ,ir_work_rec.sagaku_total         -- 差額年間計
    );
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_kyoten_data;
--
  /**********************************************************************************
   * Procedure Name   : set_kyoten_data
   * Description      : 拠点年間データを変数へ設定(A-14)
   ***********************************************************************************/
  PROCEDURE set_kyoten_data(
    ir_kyoten_rec  IN  kyoten_cur%ROWTYPE,                 -- 拠点レコード
    ior_work_rec   IN OUT g_work_gun_rtype,                -- 拠点変数レコード
    ov_errbuf      OUT NOCOPY VARCHAR2,                    -- エラー・メッセージ
    ov_retcode     OUT NOCOPY VARCHAR2,                    -- リターン・コード
    ov_errmsg      OUT NOCOPY VARCHAR2)                    -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_kyoten_data'; -- プログラム名
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
    ln_margin_rate         NUMBER;    --粗利益率
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
    -- 粗利益率
--//+UPD START 2009/02/23   CT058 K.Yamada
--  IF (ir_kyoten_rec.sales_af_disc = 0) THEN
    IF (ir_kyoten_rec.sales_bf_disc = 0) THEN
--//+UPD END   2009/02/23   CT058 K.Yamada
--//+UPD START 2009/02/10   CT019 M.Ohtsuki
--    ln_margin_rate := NULL;
      ln_margin_rate := 0;
--//+UPD END   2009/02/10   CT019 M.Ohtsuki
    ELSE
--//+UPD START 2009/02/23   CT058 K.Yamada
--    ln_margin_rate := ROUND(ir_kyoten_rec.margin / ir_kyoten_rec.sales_af_disc * 100, 2);
      ln_margin_rate := ROUND(ir_kyoten_rec.margin / ir_kyoten_rec.sales_bf_disc * 100, 2);
--//+UPD END   2009/02/23   CT058 K.Yamada
      ln_margin_rate := CASE WHEN ABS(ln_margin_rate) > cv_max_margin_rate THEN cv_max_rate ELSE ln_margin_rate END;
    END IF;

    -- 登録処理
    ior_work_rec.group_cd            := ir_kyoten_rec.location_cd;   -- 拠点コード
    ior_work_rec.sales_bf_disc_nm    := gv_sales_bf_disc_nm;         -- 値引前売上名
    ior_work_rec.sales_disc_nm       := gv_sales_disc_nm;            -- 売上値引名
    ior_work_rec.receipt_disc_nm     := gv_receipt_disc_nm;          -- 入金値引名
    ior_work_rec.sales_af_disc_nm    := gv_sales_af_disc_nm;         -- 値引後売上名
    ior_work_rec.margin_nm           := gv_margin_amt_nm;            -- 粗利益額名
    ior_work_rec.margin_rate_nm      := gv_margin_rate_nm;           -- 粗利益率名
    CASE ir_kyoten_rec.month_no
    WHEN 5 THEN
      ior_work_rec.sales_bf_disc05     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上５月
      ior_work_rec.sales_disc05        := ir_kyoten_rec.sales_disc;    -- 売上値引５月
      ior_work_rec.receipt_disc05      := ir_kyoten_rec.receipt_disc;  -- 入金値引５月
      ior_work_rec.sales_af_disc05     := ir_kyoten_rec.sales_af_disc; -- 値引後売上５月
      ior_work_rec.margin05            := ir_kyoten_rec.margin;        -- 粗利益額５月
      ior_work_rec.margin_rate05       := ln_margin_rate;              -- 粗利益率５月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 6 THEN
      ior_work_rec.sales_bf_disc06     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上６月
      ior_work_rec.sales_disc06        := ir_kyoten_rec.sales_disc;    -- 売上値引６月
      ior_work_rec.receipt_disc06      := ir_kyoten_rec.receipt_disc;  -- 入金値引６月
      ior_work_rec.sales_af_disc06     := ir_kyoten_rec.sales_af_disc; -- 値引後売上６月
      ior_work_rec.margin06            := ir_kyoten_rec.margin;        -- 粗利益額６月
      ior_work_rec.margin_rate06       := ln_margin_rate;              -- 粗利益率６月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 7 THEN
      ior_work_rec.sales_bf_disc07     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上７月
      ior_work_rec.sales_disc07        := ir_kyoten_rec.sales_disc;    -- 売上値引７月
      ior_work_rec.receipt_disc07      := ir_kyoten_rec.receipt_disc;  -- 入金値引７月
      ior_work_rec.sales_af_disc07     := ir_kyoten_rec.sales_af_disc; -- 値引後売上７月
      ior_work_rec.margin07            := ir_kyoten_rec.margin;        -- 粗利益額７月
      ior_work_rec.margin_rate07       := ln_margin_rate;              -- 粗利益率７月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 8 THEN
      ior_work_rec.sales_bf_disc08     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上８月
      ior_work_rec.sales_disc08        := ir_kyoten_rec.sales_disc;    -- 売上値引８月
      ior_work_rec.receipt_disc08      := ir_kyoten_rec.receipt_disc;  -- 入金値引８月
      ior_work_rec.sales_af_disc08     := ir_kyoten_rec.sales_af_disc; -- 値引後売上８月
      ior_work_rec.margin08            := ir_kyoten_rec.margin;        -- 粗利益額８月
      ior_work_rec.margin_rate08       := ln_margin_rate;              -- 粗利益率８月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 9 THEN
      ior_work_rec.sales_bf_disc09     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上９月
      ior_work_rec.sales_disc09        := ir_kyoten_rec.sales_disc;    -- 売上値引９月
      ior_work_rec.receipt_disc09      := ir_kyoten_rec.receipt_disc;  -- 入金値引９月
      ior_work_rec.sales_af_disc09     := ir_kyoten_rec.sales_af_disc; -- 値引後売上９月
      ior_work_rec.margin09            := ir_kyoten_rec.margin;        -- 粗利益額９月
      ior_work_rec.margin_rate09       := ln_margin_rate;              -- 粗利益率９月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 10 THEN
      ior_work_rec.sales_bf_disc10     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上１０月
      ior_work_rec.sales_disc10        := ir_kyoten_rec.sales_disc;    -- 売上値引１０月
      ior_work_rec.receipt_disc10      := ir_kyoten_rec.receipt_disc;  -- 入金値引１０月
      ior_work_rec.sales_af_disc10     := ir_kyoten_rec.sales_af_disc; -- 値引後売上０月
      ior_work_rec.margin10            := ir_kyoten_rec.margin;        -- 粗利益額１０月
      ior_work_rec.margin_rate10       := ln_margin_rate;              -- 粗利益率１０月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 11 THEN
      ior_work_rec.sales_bf_disc11     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上１１月
      ior_work_rec.sales_disc11        := ir_kyoten_rec.sales_disc;    -- 売上値引１１月
      ior_work_rec.receipt_disc11      := ir_kyoten_rec.receipt_disc;  -- 入金値引１１月
      ior_work_rec.sales_af_disc11     := ir_kyoten_rec.sales_af_disc; -- 値引後売上１月
      ior_work_rec.margin11            := ir_kyoten_rec.margin;        -- 粗利益額１１月
      ior_work_rec.margin_rate11       := ln_margin_rate;              -- 粗利益率１１月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 12 THEN
      ior_work_rec.sales_bf_disc12     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上１２月
      ior_work_rec.sales_disc12        := ir_kyoten_rec.sales_disc;    -- 売上値引１２月
      ior_work_rec.receipt_disc12      := ir_kyoten_rec.receipt_disc;  -- 入金値引１２月
      ior_work_rec.sales_af_disc12     := ir_kyoten_rec.sales_af_disc; -- 値引後売上１２月
      ior_work_rec.margin12            := ir_kyoten_rec.margin;        -- 粗利益額１２月
      ior_work_rec.margin_rate12       := ln_margin_rate;              -- 粗利益率１２月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 1 THEN
      ior_work_rec.sales_bf_disc01     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上１月
      ior_work_rec.sales_disc01        := ir_kyoten_rec.sales_disc;    -- 売上値引１月
      ior_work_rec.receipt_disc01      := ir_kyoten_rec.receipt_disc;  -- 入金値引１月
      ior_work_rec.sales_af_disc01     := ir_kyoten_rec.sales_af_disc; -- 値引後売上１月
      ior_work_rec.margin01            := ir_kyoten_rec.margin;        -- 粗利益額１月
      ior_work_rec.margin_rate01       := ln_margin_rate;              -- 粗利益率１月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 2 THEN
      ior_work_rec.sales_bf_disc02     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上２月
      ior_work_rec.sales_disc02        := ir_kyoten_rec.sales_disc;    -- 売上値引２月
      ior_work_rec.receipt_disc02      := ir_kyoten_rec.receipt_disc;  -- 入金値引２月
      ior_work_rec.sales_af_disc02     := ir_kyoten_rec.sales_af_disc; -- 値引後売上２月
      ior_work_rec.margin02            := ir_kyoten_rec.margin;        -- 粗利益額２月
      ior_work_rec.margin_rate02       := ln_margin_rate;              -- 粗利益率２月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 3 THEN
      ior_work_rec.sales_bf_disc03     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上３月
      ior_work_rec.sales_disc03        := ir_kyoten_rec.sales_disc;    -- 売上値引３月
      ior_work_rec.receipt_disc03      := ir_kyoten_rec.receipt_disc;  -- 入金値引３月
      ior_work_rec.sales_af_disc03     := ir_kyoten_rec.sales_af_disc; -- 値引後売上３月
      ior_work_rec.margin03            := ir_kyoten_rec.margin;        -- 粗利益額３月
      ior_work_rec.margin_rate03       := ln_margin_rate;              -- 粗利益率３月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    WHEN 4 THEN
      ior_work_rec.sales_bf_disc04     := ir_kyoten_rec.sales_bf_disc; -- 値引前売上４月
      ior_work_rec.sales_disc04        := ir_kyoten_rec.sales_disc;    -- 売上値引４月
      ior_work_rec.receipt_disc04      := ir_kyoten_rec.receipt_disc;  -- 入金値引４月
      ior_work_rec.sales_af_disc04     := ir_kyoten_rec.sales_af_disc; -- 値引後売上４月
      ior_work_rec.margin04            := ir_kyoten_rec.margin;        -- 粗利益額４月
      ior_work_rec.margin_rate04       := ln_margin_rate;              -- 粗利益率４月
      ior_work_rec.sales_disc_total    := NVL(ior_work_rec.sales_disc_total, 0)    + ir_kyoten_rec.sales_disc;    -- 売上値引年間計
      ior_work_rec.receipt_disc_total  := NVL(ior_work_rec.receipt_disc_total, 0)  + ir_kyoten_rec.receipt_disc;  -- 入金値引年間計
      ior_work_rec.margin_total        := NVL(ior_work_rec.margin_total, 0)        + ir_kyoten_rec.margin;        -- 粗利益額年間計
      ior_work_rec.sales_bf_disc_total := NVL(ior_work_rec.sales_bf_disc_total, 0) + ir_kyoten_rec.sales_bf_disc; -- 値引前売上年間計
      ior_work_rec.sales_af_disc_total := NVL(ior_work_rec.sales_af_disc_total, 0) + ir_kyoten_rec.sales_af_disc; -- 値引後売上年間計
    ELSE
      NULL;
    END CASE;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_kyoten_data;
--
  /**********************************************************************************
   * Procedure Name   : output_check_list
   * Description      : チェックリストデータ出力(A-15)
   ***********************************************************************************/
  PROCEDURE output_check_list(
    iv_yyyy         IN  VARCHAR2,            -- 1.対象年度
    iv_kyoten_cd    IN  VARCHAR2,            -- 2.拠点コード
    iv_kyoten_nm    IN  VARCHAR2,            -- 3.拠点名
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_check_list'; -- プログラム名
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
    cv_sep_com           CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot         CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ローカル変数 ***
    ln_cnt               NUMBER;              -- 件数
    lv_header            VARCHAR2(4000);      -- CSV出力用ヘッダ情報
    lv_csv_data          VARCHAR2(4000);      -- CSV出力用データ格納
    lv_kyoten_nm         VARCHAR2(100);       -- 拠点名称

    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- CSV出力用全データ
    CURSOR output_all_cur
    IS
      SELECT
        -- toroku_no                  -- 出力順
           cv_sep_wquot || xti.code || cv_sep_wquot                       -- コード
        || cv_sep_com || cv_sep_wquot || xti.code_nm || cv_sep_wquot      -- コード名称
        || cv_sep_com || cv_sep_wquot || xti.item_nm || cv_sep_wquot      -- 項目名
        || DECODE(xti.item_nm, gv_margin_rate_nm, (
                     cv_sep_com || TO_CHAR(xti.data_05)                  -- ５月
                  || cv_sep_com || TO_CHAR(xti.data_06)                  -- ６月
                  || cv_sep_com || TO_CHAR(xti.data_07)                  -- ７月
                  || cv_sep_com || TO_CHAR(xti.data_08)                  -- ８月
                  || cv_sep_com || TO_CHAR(xti.data_09)                  -- ９月
                  || cv_sep_com || TO_CHAR(xti.data_10)                  -- １０月
                  || cv_sep_com || TO_CHAR(xti.data_11)                  -- １１月
                  || cv_sep_com || TO_CHAR(xti.data_12)                  -- １２月
                  || cv_sep_com || TO_CHAR(xti.data_01)                  -- １月
                  || cv_sep_com || TO_CHAR(xti.data_02)                  -- ２月
                  || cv_sep_com || TO_CHAR(xti.data_03)                  -- ３月
                  || cv_sep_com || TO_CHAR(xti.data_04)                  -- ４月
                  || cv_sep_com || TO_CHAR(xti.total)                    -- 年間計
                ),(
                     cv_sep_com || TO_CHAR(ROUND(xti.data_05/1000))      -- ５月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_06/1000))      -- ６月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_07/1000))      -- ７月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_08/1000))      -- ８月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_09/1000))      -- ９月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_10/1000))      -- １０月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_11/1000))      -- １１月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_12/1000))      -- １２月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_01/1000))      -- １月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_02/1000))      -- ２月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_03/1000))      -- ３月
                  || cv_sep_com || TO_CHAR(ROUND(xti.data_04/1000))      -- ４月
                  || cv_sep_com || TO_CHAR(ROUND(xti.total/1000))        -- 年間計
                ))
        output_list
      FROM
        xxcsm_tmp_item_plan_gun   xti   -- 商品計画群別ワークテーブル
      ORDER BY
        xti.toroku_no                   -- 出力順
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

    -- 全拠点の場合
    IF (gb_all_kyoten = TRUE) THEN
      -- 「全拠点」取得
      SELECT
        xlav.location_nm   location_nm
      INTO
        lv_kyoten_nm
      FROM
        xxcsm_location_all_v    xlav
      WHERE
        xlav.location_cd = iv_kyoten_cd
      ;
    ELSE
      lv_kyoten_nm := iv_kyoten_nm;
    END IF;

    lv_header := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcsm
                   ,iv_name         => cv_lst_head_msg
                   ,iv_token_name1  => cv_tkn_cd_kyoten
                   ,iv_token_value1 => iv_kyoten_cd
                   ,iv_token_name2  => cv_tkn_nm_kyoten
                   ,iv_token_value2 => lv_kyoten_nm
                   ,iv_token_name3  => cv_tkn_cd_tsym
                   ,iv_token_value3 => iv_yyyy
                   ,iv_token_name4  => cv_tkn_nichiji
                   ,iv_token_value4 => TO_CHAR(gd_sysdate, 'YYYY/MM/DD HH24:MI:SS')
                 );
    -- データ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_header
    );

    OPEN output_all_cur();

    <<output_all_loop>>
    LOOP
      FETCH output_all_cur INTO lv_csv_data;
      EXIT WHEN output_all_cur%NOTFOUND;

      -- データ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csv_data
      );
    END LOOP output_all_loop;
    CLOSE output_all_cur;

--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_check_list;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_yyyy         IN  VARCHAR2,     -- 1.対象年度
    iv_kyoten_cd    IN  VARCHAR2,     -- 2.拠点コード
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
--
    cv_exit_group_cd   CONSTANT VARCHAR2(10)  := '!';                -- 最終商品群コード
--
    -- *** ローカル変数 ***
    lt_group_cd            xxcsm_item_plan_lines.item_group_no%TYPE; -- 商品群コード
    lt_kyoten_cd           xxcsm_item_plan_headers.location_cd%TYPE; -- 拠点コード
    lt_pre_group_cd        xxcsm_item_plan_lines.item_group_no%TYPE; -- 商品群コード（前レコード）
    lt_pre_kyoten_cd       xxcsm_item_plan_headers.location_cd%TYPE; -- 拠点コード（前レコード）

    lv_kyoten_nm           VARCHAR2(100); -- 拠点名退避用
    -- ===============================
    -- ローカル・カーソル
    -- ===============================

    -- 商品群変数レコード型
    lr_work_gun_rec         g_work_gun_rtype;
    -- 群計変数レコード型
    lr_work_gun_sum_rec     g_work_gun_rtype;
    -- 拠点変数レコード型
    lr_work_kyoten_rec      g_work_gun_rtype;
--
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
    no_data_expt            EXCEPTION;                                                              -- データ0件の場合
--//+ADD END   2009/02/10   CT005 M.Ohtsuki
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;

    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(                                   -- initをコール
       iv_yyyy                              -- 対象年度
      ,iv_kyoten_cd                         -- 拠点コード
      ,lv_errbuf                            -- エラー・メッセージ
      ,lv_retcode                           -- リターン・コード
      ,lv_errmsg                            -- ユーザー・エラー・メッセージ
      );
    IF (lv_retcode = cv_status_error) THEN  -- 戻り値が異常の場合
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- 年間商品計画データ存在チェック(A-2)
    -- =============================================
    chk_plandata(
              iv_yyyy              -- 対象年度
             ,iv_kyoten_cd         -- 拠点コード
             ,lv_errbuf            -- エラー・メッセージ
             ,lv_retcode           -- リターン・コード
             ,lv_errmsg);
    -- 例外処理
--//+UPD START 2009/02/10   CT005 M.Ohtsuki
--    IF (lv_retcode <> cv_status_normal) THEN
--      --(エラー処理)
--      gn_error_cnt := gn_error_cnt + 1;
--      RAISE global_process_expt;
--    END IF;
--
--    ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    IF (lv_retcode = cv_status_warn) THEN
      --(エラー処理)
      gn_error_cnt := gn_error_cnt + 1;
      RAISE no_data_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--//+UPD END   2009/02/10   CT005 M.Ohtsuki
    IF (gb_all_kyoten = FALSE) THEN--③
      -- =============================================
      -- 商品群データの抽出(A-3)
      -- =============================================
      OPEN item_gun_cur(TO_NUMBER(iv_yyyy), iv_kyoten_cd);
      gn_target_cnt := gn_target_cnt + 1;

      <<loop1>>
      LOOP
        FETCH item_gun_cur INTO item_gun_rec;

        lt_pre_group_cd := lt_group_cd;
        IF item_gun_cur%NOTFOUND THEN
          lt_group_cd     := cv_exit_group_cd;
        ELSE
          lt_group_cd     := item_gun_rec.group_cd;
        END IF;

        -- 商品群が変わったら
        IF (lt_group_cd <> lt_pre_group_cd) THEN

          -- =============================================
          -- 商品群名称の取得および年間計の粗利率算出(A-4)
          -- =============================================
          set_gun_name(
                  lr_work_gun_rec      -- 商品群変数レコード
                 ,lv_errbuf            -- エラー・メッセージ
                 ,lv_retcode           -- リターン・コード
                 ,lv_errmsg);
          -- 例外処理
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;

          -- =============================================
          -- 商品群を商品計画群別ワークテーブルへ登録(A-5)
          -- =============================================
          insert_data(
                  lr_work_gun_rec      -- 商品群変数レコード
                 ,lv_errbuf            -- エラー・メッセージ
                 ,lv_retcode           -- リターン・コード
                 ,lv_errmsg);
          -- 例外処理
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
          lr_work_gun_rec := NULL;
        END IF;

        EXIT WHEN item_gun_cur%NOTFOUND;

        -- =============================================
        -- 商品群年間データを変数へ設定(A-6)
        -- =============================================
        set_gun_data(
                item_gun_rec         -- 対象レコード
               ,lr_work_gun_rec      -- 商品群変数レコード
               ,lv_errbuf            -- エラー・メッセージ
               ,lv_retcode           -- リターン・コード
               ,lv_errmsg);
        -- 例外処理
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;


      END LOOP loop1;
      CLOSE item_gun_cur;
    END IF;

    -- グローバル変数の初期化
    gn_target_cnt := 0;

    -- =============================================
    -- 拠点データの抽出(A-7)
    -- =============================================
    OPEN kyoten_cur(TO_NUMBER(iv_yyyy), iv_kyoten_cd, gt_allkyoten_cd);

    <<loop2>>
    LOOP
      FETCH kyoten_cur INTO kyoten_rec;

      lt_pre_kyoten_cd := lt_kyoten_cd;
      IF kyoten_cur%NOTFOUND THEN
        lt_kyoten_cd   := cv_exit_group_cd;
      ELSE
        lt_kyoten_cd   := kyoten_rec.location_cd;
      END IF;

      -- 拠点ブレーク
      IF (lt_kyoten_cd <> lt_pre_kyoten_cd) THEN
          gn_target_cnt := gn_target_cnt + 1;

        -- =============================================
        -- 群計データの抽出(A-8)
        -- =============================================
        OPEN item_gun_sum_cur(TO_NUMBER(iv_yyyy), lt_pre_kyoten_cd);

        <<loop3_1>>
        LOOP
          FETCH item_gun_sum_cur INTO item_gun_sum_rec;
          EXIT WHEN item_gun_sum_cur%NOTFOUND;

          -- =============================================
          -- 群計の年間データを変数へ設定(A-9)
          -- =============================================
          set_gun_sum_data(
                  item_gun_sum_rec     -- 対象レコード
                 ,lr_work_gun_sum_rec  -- 群計変数レコード
                 ,lv_errbuf            -- エラー・メッセージ
                 ,lv_retcode           -- リターン・コード
                 ,lv_errmsg);
          -- 例外処理
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
        END LOOP loop3_1;
        CLOSE item_gun_sum_cur;

        -- 各拠点の場合は群計を出力
        IF (gb_all_kyoten = FALSE) THEN
          -- =============================================
          -- 群計名称の取得および年間計の粗利率算出(A-10)
          -- =============================================
          set_gun_sum_name(
                  lr_work_gun_sum_rec  -- 群計変数レコード
                 ,lv_errbuf            -- エラー・メッセージ
                 ,lv_retcode           -- リターン・コード
                 ,lv_errmsg);
          -- 例外処理
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
          -- =============================================
          -- 群計を商品計画群別ワークテーブルへ登録(A-11)
          -- =============================================
          insert_data(
                lr_work_gun_sum_rec  -- 群計変数レコード
               ,lv_errbuf            -- エラー・メッセージ
               ,lv_retcode           -- リターン・コード
               ,lv_errmsg);
          -- 例外処理
          IF (lv_retcode = cv_status_error) THEN
            --(エラー処理)
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
        END IF;

        -- =============================================
        -- 拠点名称の取得および年間計の粗利率、差額算出(A-12)
        -- =============================================
        set_kyoten_name(
                lr_work_gun_sum_rec  -- 群計変数レコード
               ,lr_work_kyoten_rec   -- 拠点変数レコード
               ,lv_errbuf            -- エラー・メッセージ
               ,lv_retcode           -- リターン・コード
               ,lv_errmsg);
        -- 例外処理
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
        -- =============================================
        -- 拠点計を商品計画群別ワークテーブルへ登録(A-13)
        -- =============================================
        insert_kyoten_data(
              lr_work_kyoten_rec   -- 拠点変数レコード
             ,lv_errbuf            -- エラー・メッセージ
             ,lv_retcode           -- リターン・コード
             ,lv_errmsg);
        -- 例外処理
        IF (lv_retcode = cv_status_error) THEN
          --(エラー処理)
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
        lv_kyoten_nm  := lr_work_kyoten_rec.group_nm;       -- 拠点名退避
        lr_work_gun_sum_rec := NULL;
        lr_work_kyoten_rec  := NULL;
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;

      EXIT WHEN kyoten_cur%NOTFOUND;

      -- =============================================
      -- 拠点年間データを変数へ設定(A-14)
      -- =============================================
      set_kyoten_data(
              kyoten_rec           -- 拠点レコード
             ,lr_work_kyoten_rec   -- 拠点変数レコード
             ,lv_errbuf            -- エラー・メッセージ
             ,lv_retcode           -- リターン・コード
             ,lv_errmsg);
      -- 例外処理
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
    END LOOP loop2;
    CLOSE kyoten_cur;

    -- =============================================
    -- チェックリストデータ出力(A-15)
    -- =============================================
    output_check_list(
                iv_yyyy              -- 対象年度
               ,iv_kyoten_cd         -- 拠点コード
               ,lv_kyoten_nm         -- 拠点名
               ,lv_errbuf            -- エラー・メッセージ
               ,lv_retcode           -- リターン・コード
               ,lv_errmsg);
    -- 例外処理
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;

--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
    WHEN  no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--//+ADD END 2009/02/10   CT005 M.Ohtsuki
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_yyyy       IN  VARCHAR2,      -- 1.対象年度
    iv_kyoten_cd  IN  VARCHAR2       -- 2.拠点コード
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
    cv_which_log       CONSTANT VARCHAR2(10)  := 'LOG';              -- 出力先
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
       iv_which   => cv_which_log
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
       iv_yyyy                                     -- 対象年度
      ,iv_kyoten_cd                                -- 拠点コード
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
--*** UPD TEMPLETE Start****************************************
--    IF (lv_retcode = cv_status_error) THEN
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errbuf --エラーメッセージ
--      );
--    END IF;
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
/*↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓*/
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      --件数の振替(エラーの場合、エラー件数を1件のみ表示させる。）
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    END IF;
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
    IF (lv_retcode = cv_status_warn) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
    END IF;
--//+ADD START 2009/02/10   CT005 M.Ohtsuki
--*** UPD TEMPLETE End****************************************
    --空行挿入
    IF (lv_retcode <> cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
END XXCSM002A07C;
/
