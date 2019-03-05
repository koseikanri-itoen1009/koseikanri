CREATE OR REPLACE PACKAGE BODY XXCSM002A18C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCSM002A18C(body)
 * Description      : アップロードファイルから単品別の年間商品計画データの洗い替え
 * MD.050           : 年間商品計画単品別アップロード MD050_CSM_002_A18
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 メイン処理プロシージャ
 *  submain              サブメイン処理プロシージャ
 *  init_proc            初期処理(A-1)
 *  get_upload_line      アップロードデータ取得(A-2)
 *  chk_upload_item      アップロード項目チェック(A-3)
 *  chk_validate_item    妥当性チェック処理(A-4)
 *  chk_budget_item      アップロード予算値チェック
 *  set_item_bgt         単品予算設定(A-5)
 *  calc_budget_item     予算値算出
 *  exchange_item_bgt    単品予算洗い替え(A-6)
 *  del_upload_data      アップロードデータ削除(A-8)
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/01/30    1.0   K.Nara           新規作成
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
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  ------------------------------------------------------------
  -- ユーザー定義グローバル定数
  ------------------------------------------------------------
  -- パッケージ定義
  cv_pkg_name                      CONSTANT VARCHAR2(12) := 'XXCSM002A18C';      -- パッケージ名
  -- アプリケーション短縮名
  cv_appl_short_name_csm           CONSTANT VARCHAR2(10) := 'XXCSM';
  -- 共通メッセージ定義
  cv_nrmal_msg                     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
  cv_warn_msg                      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
  cv_error_msg                     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';  -- エラー終了メッセージ
  cv_mainmsg_90000                 CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';  -- 対象件数出力
  cv_mainmsg_90001                 CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';  -- 成功件数出力
  cv_mainmsg_90002                 CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';  -- エラー件数出力
  cv_mainmsg_90003                 CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003';  -- スキップ件数出力
  -- 個別メッセージ定義
  cv_msg_xxcsm00004                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00004';  -- 予算年度チェックエラー
  cv_msg_xxcsm00005                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00005';  -- プロファイル取得エラー
  cv_msg_xxcsm00006                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00006';  -- 年間販売計画カレンダー未存在エラー
  cv_msg_xxcsm00037                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00037';  -- 在庫組織ID取得エラーメッセージ
  cv_msg_xxcsm00050                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00050';  -- 月別売上の差分チェックエラーメッセージ
  cv_msg_xxcsm00051                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00051';  -- 政策群予算差分エラーメッセージ
  cv_msg_xxcsm00059                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00059';  -- ログインユーザー在籍拠点取得エラー
  cv_msg_xxcsm00101                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00101';  -- ファイルIDパラメータ
  cv_msg_xxcsm00102                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00102';  -- ファイルパターンパラメータ
  cv_msg_xxcsm10138                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10138';  -- 新商品コード取得エラーメッセージ
  --
  cv_msg_xxcsm10234                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10234';  -- ロックエラーメッセージ
  cv_msg_xxcsm10238                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10238';  -- 商品計画明細テーブル名
  cv_msg_xxcsm10301                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10301';  -- 項目数相違エラーメッセージ
  cv_msg_xxcsm10302                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10302';  -- 項目不備エラーメッセージ
  cv_msg_xxcsm10303                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10303';  -- 業務処理日付取得エラー
  cv_msg_xxcsm10304                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10304';  -- BLOBデータ変換エラー
  cv_msg_xxcsm10305                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10305';  -- アップロード処理対象なしエラー
  cv_msg_xxcsm10306                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10306';  -- 指定拠点エラー
  cv_msg_xxcsm10307                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10307';  -- 複数拠点エラー
  cv_msg_xxcsm10308                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10308';  -- 指定予算年度エラー
  cv_msg_xxcsm10309                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10309';  -- 複数予算年度エラー
  cv_msg_xxcsm10310                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10310';  -- レコード区分無しエラー
  cv_msg_xxcsm10311                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10311';  -- レコード区分複数エラー
  cv_msg_xxcsm10312                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10312';  -- レコード区分誤り
  cv_msg_xxcsm10313                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10313';  -- 商品群、商品コード組合せエラー
  cv_msg_xxcsm10314                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10314';  -- 商品群予算未登録エラー
  cv_msg_xxcsm10315                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10315';  -- 営業原価取得エラー
  cv_msg_xxcsm10316                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10316';  -- 定価取得エラー
  cv_msg_xxcsm10317                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10317';  -- 売上指定エラー
  cv_msg_xxcsm10318                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10318';  -- 粗利額、粗利率、掛率複数指定エラー
  cv_msg_xxcsm10319                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10319';  -- 許容範囲エラー
  cv_msg_xxcsm10320                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10320';  -- クイックコード取得エラー
  cv_msg_xxcsm10321                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10321';  -- ファイルアップロードロックエラー
  cv_msg_xxcsm10322                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10322';  -- ファイルアップロードIF削除エラー
  cv_msg_xxcsm10323                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10323';  -- 新商品売上、粗利益額マイナス警告メッセージ
  cv_msg_xxcsm10324                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10324';  -- 小数点以下指定エラー
  cv_msg_xxcsm10325                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10325';  -- 年間計画未登録エラー
  cv_msg_xxcsm10326                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10326';  -- 予算値算出エラー
  cv_msg_xxcsm10327                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10327';  -- 登録外商品指定エラー
  cv_msg_xxcsm10328                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10328';  -- 売上NULLエラー
  --
  -- メッセージトークン定義
  cv_tkn_file_id                   CONSTANT VARCHAR2(20) := 'FILE_ID';           -- ファイルIDトークン
  cv_tkn_format                    CONSTANT VARCHAR2(20) := 'FORMAT';            -- ファイルパターン
  cv_tkn_prof_name                 CONSTANT VARCHAR2(20) := 'PROF_NAME';         -- プロファイル名
  cv_tkn_item                      CONSTANT VARCHAR2(20) := 'ITEM';              -- 項目
  cv_tkn_user_id                   CONSTANT VARCHAR2(20) := 'USER_ID';           -- ユーザID
  cv_tkn_errmsg                    CONSTANT VARCHAR2(20) := 'ERRMSG';            -- エラー内容詳細
  cv_tkn_row_num                   CONSTANT VARCHAR2(20) := 'ROW_NUM';           -- エラー行
  cv_tkn_kyoten_cd                 CONSTANT VARCHAR2(20) := 'KYOTEN_CD';         -- 拠点コード
  cv_tkn_yosan_nendo               CONSTANT VARCHAR2(20) := 'YOSAN_NENDO';       -- 予算年度
  cv_tkn_yyyy                      CONSTANT VARCHAR2(100):= 'YYYY';              -- YYYY
  cv_tkn_month                     CONSTANT VARCHAR2(20) := 'MONTH';             -- 月
  cv_tkn_deal_cd                   CONSTANT VARCHAR2(20) := 'DEAL_CD';           -- 商品群
  cv_tkn_item_cd                   CONSTANT VARCHAR2(20) := 'ITEM_CD';           -- 商品コード
  cv_tkn_rec_type                  CONSTANT VARCHAR2(20) := 'REC_TYPE';          -- レコードタイプ
  cv_tkn_column                    CONSTANT VARCHAR2(20) := 'COLUMN';            -- 項目名
  cv_tkn_min                       CONSTANT VARCHAR2(20) := 'MIN';               -- 最小値
  cv_tkn_max                       CONSTANT VARCHAR2(20) := 'MAX';               -- 最小値
  cv_tkn_lookup_value_set          CONSTANT VARCHAR2(20) := 'LOOKUP_VALUE_SET';  -- タイプ
  cv_tkn_count                     CONSTANT VARCHAR2(20) := 'COUNT';             -- 件数
  cv_tkn_value                     CONSTANT VARCHAR2(20) := 'VALUE';             -- 値
  cv_tkn_org_code                  CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';      -- 在庫組織コード
  cv_tkn_table                     CONSTANT VARCHAR2(20) := 'TABLE';             --テーブル名
  cv_output                        CONSTANT VARCHAR2(6)  := 'OUTPUT';            -- ヘッダログ出力
  -- 初期値
  cv_y                             CONSTANT VARCHAR2(1)  := 'Y';                 -- 'Y'
  cv_n                             CONSTANT VARCHAR2(1)  := 'N';                 -- 'N'
  cn_0                             CONSTANT NUMBER       := 0;                   -- 数値:0
  cn_1                             CONSTANT NUMBER       := 1;                   -- 数値:1
  cv_a                             CONSTANT VARCHAR2(1)  := 'A';                 -- 'A'
  cv_b                             CONSTANT VARCHAR2(1)  := 'B';                 -- 'B'
  cv_c                             CONSTANT VARCHAR2(1)  := 'C';                 -- 'C'
  cv_d                             CONSTANT VARCHAR2(1)  := 'D';                 -- 'D'
  cv_z                             CONSTANT VARCHAR2(1)  := 'Z';                 -- 'Z'
  cv_blank                         CONSTANT VARCHAR2(1)  := ' ';                 --半角スペース
  ct_lang                          CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  cv_rec_type_a_name               CONSTANT VARCHAR2(10) := '売上';              -- レコード区分名
  cv_rec_type_b_name               CONSTANT VARCHAR2(10) := '粗利額';            -- レコード区分名
  cv_rec_type_c_name               CONSTANT VARCHAR2(10) := '粗利率';            -- レコード区分名
  cv_rec_type_d_name               CONSTANT VARCHAR2(10) := '掛率';              -- レコード区分名
  cv_amount                        CONSTANT VARCHAR2(10) := '数量';
  --範囲チェック用
  cn_min_gross                     CONSTANT NUMBER       := -999999999999;       -- 金額最小値
  cn_max_gross                     CONSTANT NUMBER       :=  999999999999;       -- 金額最大値
  cn_min_rate                      CONSTANT NUMBER       := -999.99;             -- 最小率
  cn_max_rate                      CONSTANT NUMBER       :=  999.99;             -- 最大率
  cn_min_crerate                   CONSTANT NUMBER       :=  1;                  -- 最小率
  cn_max_crerate                   CONSTANT NUMBER       :=  999.99;             -- 最大率
  cn_min_amount                    CONSTANT NUMBER       :=  0;                  -- 最小数量
  cn_max_amount                    CONSTANT NUMBER       :=  9999999999999.9;    -- 最大数量
  --参照タイプ
  cv_upload_item_chk_name          CONSTANT VARCHAR2(30) := 'XXCSM1_ITEM_BGT_UPLOAD_ITEM'; -- 年間商品計画単品別アップロード項目チェック
  cv_lookup_type_bara              CONSTANT VARCHAR2(30) := 'XXCSM1_UNIT_KG_G';            -- バラ数量単位
  cv_lookup_type_dmy_dept          CONSTANT VARCHAR2(30) := 'XXCSM1_DUMMY_DEPT';           -- ダミー階層
  cv_out_regist_item               CONSTANT VARCHAR2(30) := 'XXCSM1_OUT_REGIST_ITEM';      -- 登録外商品
  --プロファイルオプション名
  cv_prof_yearplan_calender        CONSTANT VARCHAR2(30) := 'XXCSM1_YEARPLAN_CALENDER';  -- XXCSM:年間販売計画カレンダー名
  cv_prof_deal_category            CONSTANT VARCHAR2(30) := 'XXCSM1_DEAL_CATEGORY';      -- XXCSM:政策群品目カテゴリ特定名
  cv_prof_organization_code        CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
  cv_xxcsm1_dummy_dept_ref         CONSTANT VARCHAR2(30) := 'XXCSM1_DUMMY_DEPT_REF';     -- XXCSM:ダミー部門階層参照
  cv_gl_set_of_bks_id_nm           CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';          -- GL会計帳簿ID
  -- 商品販売計画商品区分
  cv_item_kbn_group                CONSTANT VARCHAR2(1)  := '0';                  -- 0:商品群
  cv_item_kbn_tanpin               CONSTANT VARCHAR2(1)  := '1';                  -- 1:単品
  cv_item_kbn_new                  CONSTANT VARCHAR2(1)  := '2';                  -- 2:新商品
  -- 年間群予算区分
  cv_budget_kbn_month              CONSTANT VARCHAR2(1)  := '0';                  -- 0:各月単位予算
  cv_budget_kbn_year               CONSTANT VARCHAR2(1)  := '1';                  -- 1:年間群予算
  -- ステータス・コード
  cv_status_check                  CONSTANT VARCHAR2(1)  := '9';                  -- チェックエラー:9
  cv_ap_type_xxccp                 CONSTANT VARCHAR2(5)  := 'XXCCP';              -- 共通
  ------------------------------------------------------------
  -- ユーザー定義グローバル変数
  ------------------------------------------------------------
  gn_user_id                                NUMBER;                   -- ユーザーID
  gd_proc_date                              DATE         := NULL;     -- 業務処理日付
  gd_start_date                             DATE;
  gv_group_status                           VARCHAR2(1);
  -- チェック項目格納レコード
  TYPE g_chk_item_rtype IS RECORD(
      meaning           fnd_lookup_values.meaning%TYPE    -- 項目名称
    , attribute1        fnd_lookup_values.attribute1%TYPE -- 項目の長さ
    , attribute2        fnd_lookup_values.attribute2%TYPE -- 項目の長さ（小数点以下）
    , attribute3        fnd_lookup_values.attribute3%TYPE -- 必須フラグ
    , attribute4        fnd_lookup_values.attribute4%TYPE -- 属性
  );
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  g_chk_item_tab              g_chk_item_ttype;             -- 項目チェック
  --
  gn_item_cnt                               NUMBER := 0;    -- CSV規定項目数
  --プロファイル値
  gv_prof_yearplan_calender                 VARCHAR2(100);  --XXCSM:年間販売計画カレンダー名
  gv_prof_deal_category                     VARCHAR2(100);  --XXCSM:政策群品目カテゴリ特定名
  gv_prof_organization_code                 VARCHAR2(100);  --XXCOI:在庫組織コード
  gv_dummy_dept_ref                         VARCHAR2(1);    --XXCSM:ダミー部門階層参照
  gn_gl_set_of_bks_id                       NUMBER;         --会計帳簿ID
  --
  gn_organization_id                        NUMBER;         --在庫組織ID
  gv_user_foothold                          VARCHAR2(4);    --ユーザー在籍拠点コード(p_user_foothold)
  gt_plan_year                              xxcsm_item_plan_headers.plan_year%TYPE;    -- 予算年度
  gt_item_plan_header_id                    xxcsm_item_plan_headers.item_plan_header_id%TYPE;
  --
  -- アップロードレコードタイプ
  TYPE g_upload_data_rtype IS RECORD (
    location_cd     xxcsm_item_plan_headers.location_cd%TYPE
   ,plan_year       xxcsm_item_plan_headers.plan_year%TYPE
   ,item_group_no   xxcsm_item_plan_lines.item_group_no%TYPE
   ,item_no         xxcsm_item_plan_lines.item_no%TYPE
   ,item_name       xxcsm_commodity_group3_v.item_nm%TYPE
   ,rec_type        VARCHAR2(1)
   ,month_05        NUMBER(14,2)  --売上金額、粗利益、粗利益率、掛率の最大精度
   ,month_06        NUMBER(14,2)
   ,month_07        NUMBER(14,2)
   ,month_08        NUMBER(14,2)
   ,month_09        NUMBER(14,2)
   ,month_10        NUMBER(14,2)
   ,month_11        NUMBER(14,2)
   ,month_12        NUMBER(14,2)
   ,month_01        NUMBER(14,2)
   ,month_02        NUMBER(14,2)
   ,month_03        NUMBER(14,2)
   ,month_04        NUMBER(14,2)
   --以下処理中付加情報
   ,bara_kbn        VARCHAR2(1)  --バラ区分(Y:バラ単位、N:バラ単位でない)
   ,discrete_cost   xxcmm_system_items_b_hst.discrete_cost%TYPE  --営業原価
   ,fixed_price     xxcmm_system_items_b_hst.fixed_price%TYPE    --定価
  );
  -- アップロードテーブル（商品群、商品コード、レコード区分順）（INDEX = BINARY_INTEGER）
  TYPE g_upload_data_ttype_i IS TABLE OF g_upload_data_rtype INDEX BY BINARY_INTEGER;
  g_upload_data_tab     g_upload_data_ttype_i;
  -- 商品ごとのレコード区分件数を格納するレコード
  TYPE g_upload_item_rtype IS RECORD (
    location_cd     xxcsm_item_plan_headers.location_cd%TYPE
   ,plan_year       xxcsm_item_plan_headers.plan_year%TYPE
   ,item_group_no   xxcsm_item_plan_lines.item_group_no%TYPE
   ,item_no         xxcsm_item_plan_lines.item_no%TYPE
   ,rec_type_a      NUMBER
   ,rec_type_b      NUMBER
   ,rec_type_c      NUMBER
   ,rec_type_d      NUMBER
   ,else_type       NUMBER
  );
  -- 拠点、年度、商品ごとのレコード区分件数を格納するレコード
  TYPE g_upload_item_ttype IS TABLE OF g_upload_item_rtype INDEX BY BINARY_INTEGER;
  g_upload_item_tab   g_upload_item_ttype;
  --単品予算登録域
  TYPE t_item_plan_lines_ttype IS TABLE OF xxcsm_item_plan_lines%ROWTYPE INDEX BY BINARY_INTEGER;
  g_item_line_tab            t_item_plan_lines_ttype;
  --単品予算合計
  TYPE g_item_bgt_sum_rtype IS RECORD(
    sales_budget           NUMBER
   ,amount_gross_margin    NUMBER
  );
  TYPE g_item_bgt_sum_ttype       IS TABLE OF g_item_bgt_sum_rtype INDEX BY BINARY_INTEGER;
  g_item_bgt_sum_tab              g_item_bgt_sum_ttype;    -- 単品予算合計
  --バラ単位
  TYPE g_bara_unit_ttype IS TABLE OF VARCHAR2(80) INDEX BY BINARY_INTEGER;
  g_bara_unit_tab                 g_bara_unit_ttype;
  --登録外商品
  TYPE g_out_regist_item_ttype IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
  g_out_regist_item_tab           g_out_regist_item_ttype;

  --
  ------------------------------------------------------------
  -- ユーザー定義例外
  ------------------------------------------------------------
  -- 例外
  global_lock_expt       EXCEPTION; -- グローバル例外
  -- プラグマ
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : del_upload_data
   * Description      : アップロードデータ削除(A-8)
   ***********************************************************************************/
  PROCEDURE del_upload_data(
     ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
    ,ov_retcode OUT VARCHAR2 -- リターン・コード
    ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
    ,iv_file_id IN VARCHAR2  -- ファイルID
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_upload_data'; -- プログラム名
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
    CURSOR file_delete_cur
    IS
      SELECT xmf.file_id AS file_id          -- ファイルID
      FROM   xxccp_mrp_file_ul_interface xmf -- ファイルアップロードテーブル
      WHERE  xmf.file_id = TO_NUMBER(iv_file_id)
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
    -- 1,アップロードデータロック
    -------------------------------------------------
    -- ロック処理
    OPEN file_delete_cur;
    CLOSE file_delete_cur;
    -------------------------------------------------
    -- 2,アップロードデータ削除
    -------------------------------------------------
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmf
      WHERE xmf.file_id = TO_NUMBER(iv_file_id);
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
                       iv_application  => cv_appl_short_name_csm
                      ,iv_name         => cv_msg_xxcsm10321
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => iv_file_id
                    );    
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 削除例外ハンドラ ***
    WHEN delete_err_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm
                      ,iv_name         => cv_msg_xxcsm10322
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => iv_file_id
                    );    
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_blank
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
  END del_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : exchange_item_bgt
   * Description      : 単品予算洗い替え(A-6)
   ***********************************************************************************/
  PROCEDURE exchange_item_bgt(
     ov_errbuf        OUT VARCHAR2    -- エラー・メッセージ
    ,ov_retcode       OUT VARCHAR2    -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2    -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'exchange_item_bgt'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf      VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);    -- リターン・コード
    lv_errmsg      VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    lv_out_msg     VARCHAR2(2000); -- メッセージ
    lb_retcode     BOOLEAN;        -- メッセージ戻り値
    -- 単品削除ロックカーソル
    CURSOR item_line_lock_cur
    IS
      SELECT  item_plan_header_id
      FROM    xxcsm_item_plan_lines xipl
      WHERE  item_plan_header_id = gt_item_plan_header_id
      AND    item_group_no = g_item_line_tab(1).item_group_no
      AND    item_kbn = cv_item_kbn_tanpin      --1:単品
      FOR UPDATE NOWAIT
      ;
    -- 商品群別データ取得
    CURSOR item_group_cur
    IS
      SELECT  xipl.sales_budget           AS sales_budget                    --「売上金額」
             ,xipl.amount_gross_margin    AS amount_gross_margin             --「粗利益(新)」
             ,xipl.month_no               AS month_no                        --「月」
             ,xipl.year_month             AS year_month                      --「年月」
             ,xipl.item_group_no          AS item_group_no                   --「商品群コード」
      FROM    xxcsm_item_plan_lines    xipl                                  --『商品計画明細テーブル』
      WHERE   xipl.item_plan_header_id = gt_item_plan_header_id              -- 商品計画ヘッダID
      AND     xipl.item_kbn            = cv_item_kbn_group                   -- 商品区分(商品群)
      AND     xipl.item_group_no       = g_item_line_tab(1).item_group_no    -- 商品群コード
      AND     xipl.year_bdgt_kbn       = cv_budget_kbn_month                 -- 年間群予算区分(0:各月単位予算)
      ORDER BY xipl.year_month
    ;
    --
    lv_dummy               VARCHAR2(1);
    lt_new_item_no         mtl_categories_b.attribute3%TYPE;
    lv_tab_name            VARCHAR2(500);   --テーブル名
    ln_cnt                 NUMBER;
    l_rowid                UROWID;
    lv_step                VARCHAR2(200);
    --新商品
    lt_new_item_sales_budget        xxcsm_item_plan_lines.sales_budget%TYPE;         --売上
    lt_new_item_amount_gross_mgn    xxcsm_item_plan_lines.amount_gross_margin%TYPE;  --粗利額
    lt_new_item_credit_rate         xxcsm_item_plan_lines.credit_rate%TYPE;          --掛率
    lt_new_item_amount              xxcsm_item_plan_lines.amount%TYPE;               --数量
    lt_new_item_discrete_cost       xxcmm_system_items_b_hst.discrete_cost%TYPE;     --営業原価
    lt_new_item_fixed_price         xxcmm_system_items_b_hst.fixed_price%TYPE;       --定価
    --
  BEGIN
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    --
    IF gv_group_status = cv_status_normal THEN
      -------------------------------------------------
      -- 1.商品計画明細テーブル行ロック（単品予算）
      -------------------------------------------------
      lv_step := '単品予算削除 '||g_item_line_tab(1).item_group_no;
      OPEN item_line_lock_cur;
      CLOSE item_line_lock_cur;
      -------------------------------------------------
      -- 2.単品予算削除
      -------------------------------------------------
      DELETE xxcsm_item_plan_lines
      WHERE  item_plan_header_id = gt_item_plan_header_id
      AND    item_group_no = g_item_line_tab(1).item_group_no
      AND    item_kbn = '1'      --1:商品単品
      ;
      -------------------------------------------------
      -- 3.単品予算登録
      -------------------------------------------------
      lv_step := '単品予算登録 '||g_item_line_tab(1).item_group_no;
      FORALL i in 1..g_item_line_tab.COUNT
        INSERT INTO xxcsm_item_plan_lines VALUES g_item_line_tab(i);
    END IF;
    -------------------------------------------------
    -- 4.新商品予算更新
    -------------------------------------------------
    -------------------------------------------------
    -- 4-1.新商品コード取得
    -------------------------------------------------
    lv_step := '新商品コード取得 '||g_item_line_tab(1).item_group_no;
    BEGIN
      SELECT  DISTINCT mcb.attribute3     AS new_item_no
      INTO    lt_new_item_no
      FROM    mtl_categories_b       mcb              --『カテゴリ』
             ,mtl_category_sets_b    mcsb             --『カテゴリセット』 
             ,mtl_category_sets_tl   mcst             --『カテゴリセット日本語』
      WHERE  mcst.category_set_name  = gv_prof_deal_category
      AND    mcst.language           = ct_lang
      AND    mcst.category_set_id    = mcsb.category_set_id
      AND    mcsb.structure_id       = mcb.structure_id
      AND    mcb.segment1            LIKE SUBSTR(g_item_line_tab(1).item_group_no, 1, 3) || '_'
      AND    mcb.attribute3          IS NOT NULL
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10138
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => g_item_line_tab(1).item_group_no
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
    END;
    -------------------------------------------------
    -- 4-2.新商品営業原価取得
    -------------------------------------------------
    lv_step := '新商品営業原価取得 '||g_item_line_tab(1).item_group_no;
    BEGIN
      -- 前年度の営業原価を品目変更履歴から取得
      SELECT xsibh.discrete_cost                           -- 営業原価
      INTO   lt_new_item_discrete_cost
      FROM   xxcmm_system_items_b_hst   xsibh              -- 品目変更履歴テーブル
            ,(SELECT MAX(item_hst_id)   item_hst_id        -- 品目変更履歴ID
              FROM   xxcmm_system_items_b_hst              -- 品目変更履歴
              WHERE  item_code  = lt_new_item_no           -- 品目コード
              AND    apply_date < gd_start_date            -- 年度開始日前
              AND    apply_flag = cv_y                     -- 適用済み
              AND    discrete_cost IS NOT NULL             -- 営業原価 IS NOT NULL
             ) xsibh_view
      WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id    -- 品目変更履歴ID
      AND    xsibh.item_code   = lt_new_item_no            -- 新商品コード
      AND    xsibh.apply_flag  = cv_y                      -- 適用済み
      AND    xsibh.discrete_cost IS NOT NULL
      ;
        --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --営業原価取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm            -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10315                 -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                    -- トークンコード1
                       , iv_token_value1 => g_item_line_tab(1).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                    -- トークンコード2
                       , iv_token_value2 => lt_new_item_no                    -- トークン値2（商品コード）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
    END;
    --
    -------------------------------------------------
    -- 4-3.新商品定価取得
    -------------------------------------------------
    lv_step := '新商品定価取得 '||g_item_line_tab(1).item_group_no;
    BEGIN
      -- 前年度の定価を品目変更履歴から取得
      SELECT xsibh.fixed_price                             -- 定価
      INTO   lt_new_item_fixed_price
      FROM   xxcmm_system_items_b_hst   xsibh              -- 品目変更履歴テーブル
            ,(SELECT MAX(item_hst_id)   item_hst_id        -- 品目変更履歴ID
              FROM   xxcmm_system_items_b_hst              -- 品目変更履歴
              WHERE  item_code  = lt_new_item_no           -- 品目コード
              AND    apply_date < gd_start_date            -- 年度開始日前
              AND    apply_flag = cv_y                     -- 適用済み
              AND    fixed_price IS NOT NULL               -- 定価 IS NOT NULL
                ) xsibh_view
      WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id    -- 品目変更履歴ID
      AND    xsibh.item_code   = lt_new_item_no            -- 新商品コード
      AND    xsibh.apply_flag  = cv_y                      -- 適用済み
      AND    xsibh.fixed_price IS NOT NULL
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --定価取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm            -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10316                 -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                    -- トークンコード1
                       , iv_token_value1 => g_item_line_tab(1).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                    -- トークンコード2
                       , iv_token_value2 => lt_new_item_no                    -- トークン値2（商品コード）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
    END;
    --
    IF ov_retcode = cv_status_check THEN
      RETURN;
    END IF;
    -------------------------------------------------
    -- 4-4.新商品の売上、粗利額、掛率、数量算出
    -------------------------------------------------
    --商品群予算月別ループ
    ln_cnt := 1;
    FOR item_group_rec IN item_group_cur LOOP
      -------------------------------------------------
      -- 新商品登録値算出（売上、粗利額、掛率、数量）
      -------------------------------------------------
      --新商品売上
      lv_step := '新商品の売上算出['||item_group_rec.item_group_no||' / '||TO_CHAR(item_group_rec.year_month)||']';
      BEGIN
        lt_new_item_sales_budget     := item_group_rec.sales_budget - g_item_bgt_sum_tab(ln_cnt).sales_budget;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => item_group_rec.item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => lt_new_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => TO_CHAR(item_group_rec.year_month)
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '新商品の売上算出 > 商品群売上(千円)='||TO_CHAR(item_group_rec.sales_budget / 1000)||' 単品売上合計(千円)='||TO_CHAR(g_item_bgt_sum_tab(ln_cnt).sales_budget / 1000)||' エラー内容='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --新商品粗利額
      lv_step := '新商品の粗利額算出['||item_group_rec.item_group_no||' / '||TO_CHAR(item_group_rec.year_month)||']';
      BEGIN
        lt_new_item_amount_gross_mgn := item_group_rec.amount_gross_margin - g_item_bgt_sum_tab(ln_cnt).amount_gross_margin;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => item_group_rec.item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => lt_new_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => TO_CHAR(item_group_rec.year_month)
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '新商品の粗利額算出 > 商品群粗利額(千円)='||TO_CHAR(item_group_rec.amount_gross_margin / 1000)||' 単品粗利額合計(千円)='||TO_CHAR(g_item_bgt_sum_tab(ln_cnt).amount_gross_margin / 1000)||' エラー内容='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
      --新商品数量
      lv_step := '新商品の数量算出['||item_group_rec.item_group_no||' / '||TO_CHAR(item_group_rec.year_month)||']';
      IF lt_new_item_discrete_cost = 0 THEN
        lt_new_item_amount := 0;
      ELSE
        BEGIN
          --数量 = (売上 - 粗利益額) / 営業原価の小数点第1位を四捨五入
          lt_new_item_amount := ROUND( ( lt_new_item_sales_budget - lt_new_item_amount_gross_mgn ) / lt_new_item_discrete_cost, 0);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => item_group_rec.item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => lt_new_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(item_group_rec.year_month)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '新商品の数量算出 > 新商品売上(千円)='||TO_CHAR(lt_new_item_sales_budget / 1000)||' 新商品粗利額(千円)='||TO_CHAR(lt_new_item_amount_gross_mgn / 1000)||' 新商品営業原価='||TO_CHAR(lt_new_item_discrete_cost)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
        --
      END IF;
      --
      --新商品掛率
      lv_step := '新商品の掛率算出['||item_group_rec.item_group_no||' / '||TO_CHAR(item_group_rec.year_month)||']';
      IF lt_new_item_amount * lt_new_item_fixed_price = 0 THEN
        lt_new_item_credit_rate := 0;
      ELSE
        --掛率 = ( 売上 / (定価 * 数量) * 100 )の小数点第3位を四捨五入
        BEGIN
          lt_new_item_credit_rate := ROUND( ( lt_new_item_sales_budget / ( lt_new_item_fixed_price * lt_new_item_amount ) * 100 ), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => item_group_rec.item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => lt_new_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(item_group_rec.year_month)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '新商品の掛率算出 > 新商品売上(千円)='||TO_CHAR(lt_new_item_sales_budget / 1000)||' 新商品定価='||TO_CHAR(lt_new_item_fixed_price)||' 新商品数量='||TO_CHAR(lt_new_item_amount)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
        --
      END IF;
      --
      IF ov_retcode = cv_status_normal THEN
        -------------------------------------------------
        -- 新商品予算レコードロック（新商品、該当月）
        -------------------------------------------------
        SELECT rowid
        INTO   l_rowid
        FROM   xxcsm_item_plan_lines    xipl                               --『商品計画明細テーブル』
        WHERE   xipl.item_plan_header_id = gt_item_plan_header_id          -- 商品計画ヘッダID
        AND     year_month               = item_group_rec.year_month
        AND     xipl.year_bdgt_kbn       = cv_budget_kbn_month             -- 年間群予算区分(0:各月単位予算)
        AND     xipl.item_kbn            = cv_item_kbn_new                 -- 商品区分(新商品)
        AND     xipl.item_no             = lt_new_item_no
        AND     xipl.item_group_no       = g_item_line_tab(1).item_group_no
        FOR UPDATE NOWAIT
        ;
        --
        -------------------------------------------------
        -- 新商品予算更新
        -------------------------------------------------
        UPDATE xxcsm_item_plan_lines
        SET sales_budget           = lt_new_item_sales_budget
           ,amount_gross_margin    = lt_new_item_amount_gross_mgn
           ,credit_rate            = lt_new_item_credit_rate
           ,amount                 = lt_new_item_amount
           ,last_updated_by        = cn_last_updated_by
           ,last_update_date       = cd_last_update_date
           ,last_update_login      = cn_last_update_login
           ,request_id             = cn_request_id
           ,program_application_id = cn_program_application_id
           ,program_id             = cn_program_id
           ,program_update_date    = cd_program_update_date
        WHERE rowid = l_rowid
        ;
      END IF;
      --
      ln_cnt := ln_cnt + 1;
      --
    END LOOP;
    --
  EXCEPTION
    -- *** ロック例外ハンドラ ****
    WHEN global_lock_expt THEN
      lv_tab_name := xxccp_common_pkg.get_msg(
                               iv_application => cv_appl_short_name_csm
                              ,iv_name        => cv_msg_xxcsm10238
                             );
      -- メッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm
                      ,iv_name         => cv_msg_xxcsm10234
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => lv_tab_name
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
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
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      --
  END exchange_item_bgt;
--
  /**********************************************************************************
   * Procedure Name   : calc_budget_item
   * Description      : 予算値算出
   ***********************************************************************************/
  PROCEDURE calc_budget_item(
     ov_errbuf               OUT VARCHAR2    -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2    -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2    -- ユーザー・エラー・メッセージ
    ,iv_item_group_no        IN  VARCHAR2
    ,iv_item_no              IN  VARCHAR2
    ,in_month_no             IN  NUMBER
    ,in_sales_budget         IN  NUMBER      -- 入力_売上(単位：千円)（必須）
    ,in_amount_gross_margin  IN  NUMBER      -- 入力_粗利額(単位：千円)
    ,in_margin_rate          IN  NUMBER      -- 入力_粗利率
    ,in_credit_rate          IN  NUMBER      -- 入力_掛率
    ,iv_bara_kbn             IN  VARCHAR2    -- 入力_バラ区分
    ,in_discrete_cost        IN  XXCMM_SYSTEM_ITEMS_B_HST.DISCRETE_COST%TYPE      -- 営業原価
    ,in_fixed_price          IN  XXCMM_SYSTEM_ITEMS_B_HST.FIXED_PRICE%TYPE        -- 定価
    ,on_amount_gross_margin  OUT xxcsm_item_plan_lines.amount_gross_margin%TYPE   -- 算出結果_粗利額(単位：円)
    ,on_margin_rate          OUT xxcsm_item_plan_lines.margin_rate%TYPE           -- 算出結果_粗利率
    ,on_credit_rate          OUT xxcsm_item_plan_lines.credit_rate%TYPE           -- 算出結果_掛率
    ,on_amount               OUT xxcsm_item_plan_lines.amount%TYPE                -- 算出結果_数量
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'calc_budget_item'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf      VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);    -- リターン・コード
    lv_errmsg      VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    lv_out_msg     VARCHAR2(2000); -- メッセージ
    lb_retcode     BOOLEAN;        -- メッセージ戻り値
    lv_step        VARCHAR2(200);
    --
    ln_sales_budget             NUMBER;  -- 売上(単位：円)
    ln_sales_bdgt_per1          NUMBER;  -- 1本当たりの売値
    ln_gross_amount_per1        NUMBER;  -- 1本当たりの利益
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    lv_step := '初期化';
    --売上(円) = 売上(千円) * 1000
    ln_sales_budget := in_sales_budget * 1000;
    ln_sales_bdgt_per1   := 0;
    ln_gross_amount_per1 := 0;
    -------------------------------------------------
    -- 1.粗利額、粗利率、掛率、数量の算出
    -------------------------------------------------
    IF in_amount_gross_margin IS NOT NULL THEN
      -------------------------------------------------
      -- 粗利額が指定されている場合
      -------------------------------------------------
      lv_step := '粗利額指定 粗利額';
      --粗利額 = アップロード値 * 1000
      on_amount_gross_margin := in_amount_gross_margin * 1000;
      --粗利率 = ( 粗利益額 / 売上 * 100 ) の小数点第3位を四捨五入
      lv_step := '粗利額指定 粗利率';
      IF ln_sales_budget = 0 THEN
        on_margin_rate := 0;
      ELSE
        BEGIN
          on_margin_rate := ROUND( ( on_amount_gross_margin / ln_sales_budget * 100 ), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '粗利額指定 粗利率算出 > 粗利額(千円)='||TO_CHAR(on_amount_gross_margin / 1000)||' 売上(千円)='||TO_CHAR(ln_sales_budget / 1000)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      --1本当たりの売値
      lv_step := '粗利額指定 1本当たりの売値';
      IF (ln_sales_budget - on_amount_gross_margin) = 0 THEN
        ln_sales_bdgt_per1 := 0;
      ELSE
        --1本当たりの売値 = ( 売上 / (売上 - 粗利益額) * 営業原価 )の小数点第11位を四捨五入
        BEGIN
          ln_sales_bdgt_per1 := ROUND( ( ln_sales_budget / (ln_sales_budget - on_amount_gross_margin) * in_discrete_cost ), 10);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '粗利額指定 1本当たりの売値算出 > 売上(千円)='||TO_CHAR(ln_sales_budget / 1000)||' 粗利額(千円)='||TO_CHAR(on_amount_gross_margin / 1000)||' 営業原価='||TO_CHAR(in_discrete_cost)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      --掛率
      lv_step := '粗利額指定 掛率';
      IF in_fixed_price = 0 THEN
        on_credit_rate := 0;
      ELSE
        --掛率 = (1本当たりの売値 / 定価 * 100)の小数点第3位を四捨五入
        BEGIN
          on_credit_rate := ROUND( (ln_sales_bdgt_per1 / in_fixed_price * 100), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '粗利額指定 掛率算出 > 1本当たりの売値='||TO_CHAR(ln_sales_bdgt_per1)||' 定価='||TO_CHAR(in_fixed_price)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      --数量
      lv_step := '粗利額指定 数量';
      IF ln_sales_bdgt_per1 = 0 THEN
        on_amount := 0;
      ELSE
        BEGIN
          IF (iv_bara_kbn = cv_y) THEN
            --数量 = ( 売上 / 売値 )の小数点第2位を四捨五入
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 1);
          ELSE
            --数量 = ( 売上 / 売値 )の小数点第1位を四捨五入
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 0);
          END IF;
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '粗利額指定 数量算出 > 売上(千円)='||TO_CHAR(ln_sales_budget / 1000)||' 1本当たりの売値='||TO_CHAR(ln_sales_bdgt_per1)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
    ELSIF in_margin_rate IS NOT NULL THEN
      -------------------------------------------------
      -- 粗利率が指定されている場合
      -------------------------------------------------
      lv_step := '粗利率指定 粗利額';
      --粗利額 = ( 売上 * 粗利益率 / 100 / 1000 ) の小数点第1位を四捨五入して、単位を円に変更(×1000する)
      BEGIN
        on_amount_gross_margin := ROUND( ( ln_sales_budget * in_margin_rate / 100 / 1000), 0) * 1000;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => TO_CHAR(in_month_no)
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '粗利率指定 粗利額算出 > 売上(千円)='||TO_CHAR(ln_sales_budget / 1000)||' 粗利率='||TO_CHAR(in_margin_rate)||' エラー内容='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
      lv_step := '粗利率指定 粗利率';
      --粗利率 = アップロード値
      on_margin_rate := in_margin_rate;
      lv_step := '粗利率指定 1本当たりの売値';
      --1本当たりの売値
      IF (ln_sales_budget - on_amount_gross_margin) = 0 THEN
        ln_sales_bdgt_per1 := 0;
      ELSE
        --1本当たりの売値 = ( 売上 / (売上 - 粗利益額) * 営業原価 )の小数点第11位を四捨五入
        BEGIN
          ln_sales_bdgt_per1 := ROUND( ( ln_sales_budget / (ln_sales_budget - on_amount_gross_margin) * in_discrete_cost ), 10);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '粗利率指定 1本当たりの売値算出 > 売上(千円)='||TO_CHAR(ln_sales_budget / 1000)||' 粗利額(千円)='||TO_CHAR(on_amount_gross_margin / 1000)||' 営業原価='||TO_CHAR(in_discrete_cost)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      lv_step := '粗利率指定 掛率';
      --掛率
      IF in_fixed_price = 0 THEN
        on_credit_rate := 0;
      ELSE
        --掛率 = (1本当たりの売値 / 定価 * 100)の小数点第3位を四捨五入
        BEGIN
          on_credit_rate := ROUND( (ln_sales_bdgt_per1 / in_fixed_price * 100), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '粗利率指定 掛率算出 > 1本当たりの売値='||TO_CHAR(ln_sales_bdgt_per1)||' 定価='||TO_CHAR(in_fixed_price)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      lv_step := '粗利率指定 数量';
      --数量
      IF ln_sales_bdgt_per1 = 0 THEN
        on_amount := 0;
      ELSE
        BEGIN
          IF (iv_bara_kbn = cv_y) THEN
            --数量 = ( 売上 / 売値 )の小数点第2位を四捨五入
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 1);
          ELSE
            --数量 = ( 売上 / 売値 )の小数点第1位を四捨五入
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 0);
          END IF;
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '粗利率指定 数量算出 > 売上(千円)='||TO_CHAR(ln_sales_budget / 1000)||' 1本当たりの売値='||TO_CHAR(ln_sales_bdgt_per1)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
    ELSIF in_credit_rate IS NOT NULL THEN
      -------------------------------------------------
      -- 掛率が指定されている場合
      -------------------------------------------------
      --粗利額
      lv_step := '掛率指定 1本当たりの売値';
      --1本当たりの売値 = 定価 * 掛率 / 100
      BEGIN
        ln_sales_bdgt_per1 := in_fixed_price * in_credit_rate / 100;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => TO_CHAR(in_month_no)
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '掛率指定 1本当たりの売値算出 > 定価='||TO_CHAR(in_fixed_price)||' 掛率='||TO_CHAR(in_credit_rate)||' エラー内容='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      lv_step := '掛率指定 数量';
      --数量
      IF ln_sales_bdgt_per1 = 0 THEN
        on_amount := 0;
      ELSE
        --数量
        BEGIN
          IF (iv_bara_kbn = cv_y) THEN
            --数量 = ( 売上 / 売値 )の小数点第2位を四捨五入
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 1);
          ELSE
            --数量 = ( 売上 / 売値 )の小数点第1位を四捨五入
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 0);
          END IF;
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '掛率指定 数量算出 > 売上(千円)='||TO_CHAR(ln_sales_budget / 1000)||' 1本当たりの売値='||TO_CHAR(ln_sales_bdgt_per1)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      --
      lv_step := '掛率指定 1本当たりの利益';
      --1本当たりの利益 = 1本当たりの売値 - 営業原価
      ln_gross_amount_per1 := NVL(ln_sales_bdgt_per1 - in_discrete_cost, 0);
      --
      lv_step := '掛率指定 粗利額';
      --粗利額 = (1本当たりの利益 * 数量) / 1000の小数点第1位を四捨五入して、単位を円に変更(×1000する)
      BEGIN
        on_amount_gross_margin := ROUND( ( ln_gross_amount_per1 * on_amount / 1000 ), 0) * 1000;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => TO_CHAR(in_month_no)
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '掛率指定 粗利額算出 > 1本当たりの利益='||TO_CHAR(ln_gross_amount_per1)||' 数量='||TO_CHAR(on_amount)||' エラー内容='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
      lv_step := '掛率指定 粗利率';
      --粗利率 = (粗利益額 / 売上 * 100)の小数点第3位を四捨五入
      IF ln_sales_budget = 0 THEN
        on_margin_rate := 0;
      ELSE
        BEGIN
          on_margin_rate := ROUND( (on_amount_gross_margin / ln_sales_budget * 100 ), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10326          -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '掛率指定 粗利率算出 > 粗利額(千円)='||TO_CHAR(on_amount_gross_margin / 1000)||' 売上(千円)='||TO_CHAR(ln_sales_budget / 1000)||' エラー内容='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      --
      lv_step := '掛率指定 掛率';
      --掛率 = アップロード値
      on_credit_rate := in_credit_rate;
      --
    END IF;
    --
    -------------------------------------------------
    -- 2.許容範囲チェック
    -------------------------------------------------
    lv_step := '許容範囲チェック';
    --0
    IF ln_sales_budget = 0 AND on_amount_gross_margin = 0 AND on_margin_rate = 0
      AND on_credit_rate = 0 AND on_amount = 0
    THEN 
      --全項目0はokとする
      NULL;
    ELSE
      --粗利額
      IF ( ( on_amount_gross_margin / 1000 ) < cn_min_gross ) OR ( cn_max_gross < ( on_amount_gross_margin / 1000 ) ) THEN
        --粗利額は許容範囲を超えてしまいます。
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10319
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => TO_CHAR(in_month_no)
                       ,iv_token_name4          => cv_tkn_column
                       ,iv_token_value4         => cv_rec_type_b_name
                       ,iv_token_name5          => cv_tkn_min
                       ,iv_token_value5         => TO_CHAR(cn_min_gross)
                       ,iv_token_name6          => cv_tkn_max
                       ,iv_token_value6         => TO_CHAR(cn_max_gross)
                       ,iv_token_name7          => cv_tkn_value
                       ,iv_token_value7         => TO_CHAR(on_amount_gross_margin / 1000)
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
      --粗利率
      IF ( on_margin_rate < cn_min_rate ) OR ( cn_max_rate < on_margin_rate ) THEN
        --粗利率は許容範囲を超えてしまいます。
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10319
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => TO_CHAR(in_month_no)
                       ,iv_token_name4          => cv_tkn_column
                       ,iv_token_value4         => cv_rec_type_c_name
                       ,iv_token_name5          => cv_tkn_min
                       ,iv_token_value5         => TO_CHAR(cn_min_rate)
                       ,iv_token_name6          => cv_tkn_max
                       ,iv_token_value6         => TO_CHAR(cn_max_rate)
                       ,iv_token_name7          => cv_tkn_value
                       ,iv_token_value7         => TO_CHAR(on_margin_rate,'FM999999999990.09')
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
      --掛率
      IF ( on_credit_rate < cn_min_crerate ) OR ( cn_max_crerate < on_credit_rate ) THEN
        --掛率は許容範囲を超えてしまいます。
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10319
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => TO_CHAR(in_month_no)
                       ,iv_token_name4          => cv_tkn_column
                       ,iv_token_value4         => cv_rec_type_d_name
                       ,iv_token_name5          => cv_tkn_min
                       ,iv_token_value5         => TO_CHAR(cn_min_crerate)
                       ,iv_token_name6          => cv_tkn_max
                       ,iv_token_value6         => TO_CHAR(cn_max_crerate)
                       ,iv_token_name7          => cv_tkn_value
                       ,iv_token_value7         => TO_CHAR(on_credit_rate,'FM999999999990.09')
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
      --数量
      IF ( on_amount < cn_min_amount ) OR ( cn_max_amount < on_amount ) THEN
        --数量は許容範囲を超えてしまいます。
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10319
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => TO_CHAR(in_month_no)
                       ,iv_token_name4          => cv_tkn_column
                       ,iv_token_value4         => cv_amount
                       ,iv_token_name5          => cv_tkn_min
                       ,iv_token_value5         => TO_CHAR(cn_min_amount)
                       ,iv_token_name6          => cv_tkn_max
                       ,iv_token_value6         => TO_CHAR(cn_max_amount)
                       ,iv_token_name7          => cv_tkn_value
                       ,iv_token_value7         => TO_CHAR(on_amount,'FM999999999990.09')
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
        --
      END IF;
      --
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
  END calc_budget_item;
  --
  /**********************************************************************************
   * Procedure Name   : set_item_bgt
   * Description      : 単品予算設定(A-5)
   ***********************************************************************************/
  PROCEDURE set_item_bgt(
     ov_errbuf        OUT VARCHAR2    -- エラー・メッセージ
    ,ov_retcode       OUT VARCHAR2    -- リターン・コード
    ,ov_errmsg        OUT VARCHAR2    -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'set_item_bgt'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf      VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);    -- リターン・コード
    lv_errmsg      VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    lv_out_msg     VARCHAR2(2000); -- メッセージ
    lb_retcode     BOOLEAN;        -- メッセージ戻り値
    --
    ln_line_no                      NUMBER;   --行カウンタ
    ln_item_line_cnt                NUMBER;   --単品予算明細カウンタ
    lv_pre_item_group_no            xxcsm_item_plan_lines.item_group_no%TYPE;
    lv_step                         VARCHAR2(200);
    --
    ln_sales_budget                 NUMBER(14,2);
    ln_amount_gross_margin          NUMBER(14,2);
    ln_margin_rate                  NUMBER(14,2);
    ln_credit_rate                  NUMBER(14,2);
    lv_out_regist_item              VARCHAR2(1);      -- 登録外商品判定
    --===============================
    -- ローカル例外
    --===============================
    sub_proc_err_expt    EXCEPTION; -- 呼出しプログラムのエラー
  --
  BEGIN
    --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    lv_step     := NULL;
    --
    ln_line_no := 1;
    g_item_line_tab.DELETE;
    ln_item_line_cnt := 1;
    FOR i IN 1..12 LOOP
      g_item_bgt_sum_tab(i).sales_budget := 0;
      g_item_bgt_sum_tab(i).amount_gross_margin := 0;
    END LOOP;
    gv_group_status := cv_status_normal;
    --
    -------------------------------------------------
    -- 1.単品予算設定
    -------------------------------------------------
    lv_pre_item_group_no := NULL;
    --
    -- 商品群、商品コード、レコード区分順に処理を実施
    << upload_data_tab_loop >>
    LOOP
      EXIT WHEN ln_line_no > g_upload_data_tab.COUNT;
      -------------------------------------------------
      -- 1-1.カレント商品群判定
      -------------------------------------------------
      IF lv_pre_item_group_no <> g_upload_data_tab(ln_line_no).item_group_no THEN
        --前回処理商品群と今回処理商品群が異なる場合、
        -------------------------------------------------
        -- 単品予算洗い替え
        -------------------------------------------------
        exchange_item_bgt(
          ov_errbuf        => lv_errbuf          -- エラー・メッセージ
         ,ov_retcode       => lv_retcode         -- リターン・コード
         ,ov_errmsg        => lv_errmsg          -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_check ) THEN
          gv_group_status := cv_status_check;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE sub_proc_err_expt;
        END IF;
        --
        IF ( gv_group_status = cv_status_check ) THEN
          ov_retcode := cv_status_error;
        END IF;
        -------------------------------------------------
        -- 格納域初期化（商品計画明細テーブル登録値、合計金額、件数）
        -------------------------------------------------
        g_item_line_tab.DELETE;
        FOR i IN 1..12 LOOP
          g_item_bgt_sum_tab(i).sales_budget := 0;
          g_item_bgt_sum_tab(i).amount_gross_margin := 0;
        END LOOP;
        ln_item_line_cnt := 1;
        --
        gv_group_status := cv_status_normal;
        --
      END IF;
      --
      -------------------------------------------------
      -- 登録外商品判定
      -------------------------------------------------
      lv_out_regist_item := cv_n;
      --
      FOR i IN 1..g_out_regist_item_tab.COUNT LOOP
        IF g_upload_data_tab(ln_line_no).item_no = g_out_regist_item_tab(i) THEN
           lv_out_regist_item := cv_y;
        END IF;
      END LOOP;
      --
      -------------------------------------------------
      -- 1-2.商品計画明細テーブル項目設定
      -------------------------------------------------
      FOR i IN 1..12 LOOP
        g_item_line_tab(ln_item_line_cnt).item_plan_header_id := gt_item_plan_header_id;
        g_item_line_tab(ln_item_line_cnt).item_plan_lines_id  := xxcsm_item_plan_lines_s01.NEXTVAL;
        g_item_line_tab(ln_item_line_cnt).year_month          := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, i - 1),'YYYYMM'));
        g_item_line_tab(ln_item_line_cnt).month_no            := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, i - 1),'MM'));
        g_item_line_tab(ln_item_line_cnt).year_bdgt_kbn       := cv_budget_kbn_month;
        g_item_line_tab(ln_item_line_cnt).item_kbn            := cv_item_kbn_tanpin;
        g_item_line_tab(ln_item_line_cnt).item_no             := g_upload_data_tab(ln_line_no).item_no;
        g_item_line_tab(ln_item_line_cnt).item_group_no       := g_upload_data_tab(ln_line_no).item_group_no;
        --
        g_item_line_tab(ln_item_line_cnt).created_by              := cn_created_by;
        g_item_line_tab(ln_item_line_cnt).creation_date           := cd_creation_date;
        g_item_line_tab(ln_item_line_cnt).last_updated_by         := cn_last_updated_by;
        g_item_line_tab(ln_item_line_cnt).last_update_date        := cd_last_update_date;
        g_item_line_tab(ln_item_line_cnt).last_update_login       := cn_last_update_login;
        g_item_line_tab(ln_item_line_cnt).request_id              := cn_request_id;
        g_item_line_tab(ln_item_line_cnt).program_application_id  := cn_program_application_id;
        g_item_line_tab(ln_item_line_cnt).program_id              := cn_program_id;
        g_item_line_tab(ln_item_line_cnt).program_update_date     := cd_program_update_date;
        --
        lv_step := g_item_line_tab(ln_item_line_cnt).item_group_no || ' / ' || g_item_line_tab(ln_item_line_cnt).item_no  || ' / ' || TO_CHAR(g_item_line_tab(ln_item_line_cnt).year_month);
        --
        IF i = 1 THEN --5月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_05 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_05;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_05;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_05;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_05;            -- 入力_掛率
        ELSIF i = 2 THEN --6月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_06 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_06;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_06;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_06;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_06;            -- 入力_掛率
        ELSIF i = 3 THEN --7月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_07 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_07;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_07;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_07;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_07;            -- 入力_掛率
        ELSIF i = 4 THEN --8月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_08 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_08;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_08;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_08;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_08;            -- 入力_掛率
        ELSIF i = 5 THEN --9月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_09 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_09;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_09;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_09;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_09;            -- 入力_掛率
        ELSIF i = 6 THEN --10月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_10 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_10;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_10;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_10;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_10;            -- 入力_掛率
        ELSIF i = 7 THEN --11月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_11 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_11;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_11;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_11;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_11;            -- 入力_掛率
        ELSIF i = 8 THEN --12月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_12 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_12;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_12;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_12;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_12;            -- 入力_掛率
        ELSIF i = 9 THEN --1月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_01 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_01;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_01;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_01;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_01;            -- 入力_掛率
        ELSIF i = 10 THEN --2月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_02 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_02;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_02;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_02;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_02;            -- 入力_掛率
        ELSIF i = 11 THEN --3月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_03 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_03;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_03;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_03;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_03;            -- 入力_掛率
        ELSIF i = 12 THEN --4月分
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_04 * 1000;  --売上
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_04;                -- 入力_売上(単位：千円)（必須）
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_04;            -- 入力_粗利額(単位：千円)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_04;            -- 入力_粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_04;            -- 入力_掛率
        END IF;
        --
        IF lv_out_regist_item = cv_n THEN
          --通常商品の場合
          -------------------------------------------------
          -- 予算項目設定
          -------------------------------------------------
          calc_budget_item(
            ov_errbuf              => lv_errbuf                                             -- エラー・メッセージ
           ,ov_retcode             => lv_retcode                                            -- リターン・コード
           ,ov_errmsg              => lv_errmsg                                             -- ユーザー・エラー・メッセージ
           ,iv_item_group_no       => g_item_line_tab(ln_item_line_cnt).item_group_no
           ,iv_item_no             => g_item_line_tab(ln_item_line_cnt).item_no
           ,in_month_no            => g_item_line_tab(ln_item_line_cnt).month_no
           ,in_sales_budget        => ln_sales_budget                                       -- 入力_売上(単位：千円)（必須）
           ,in_amount_gross_margin => ln_amount_gross_margin                                -- 入力_粗利額(単位：千円)
           ,in_margin_rate         => ln_margin_rate                                        -- 入力_粗利率
           ,in_credit_rate         => ln_credit_rate                                        -- 入力_掛率
           ,iv_bara_kbn            => g_upload_data_tab(ln_line_no).bara_kbn                -- 入力_バラ区分
           ,in_discrete_cost       => g_upload_data_tab(ln_line_no).discrete_cost           -- 入力_営業原価
           ,in_fixed_price         => g_upload_data_tab(ln_line_no).fixed_price             -- 入力_定価
           ,on_amount_gross_margin => g_item_line_tab(ln_item_line_cnt).amount_gross_margin -- 算出結果_粗利額(単位：円)
           ,on_margin_rate         => g_item_line_tab(ln_item_line_cnt).margin_rate         -- 算出結果_粗利率
           ,on_credit_rate         => g_item_line_tab(ln_item_line_cnt).credit_rate         -- 算出結果_掛率
           ,on_amount              => g_item_line_tab(ln_item_line_cnt).amount              -- 算出結果_数量
          );
          --
          IF ( lv_retcode = cv_status_check ) THEN
            gv_group_status := cv_status_check;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE sub_proc_err_expt;
          END IF;
          --
        ELSE
          --登録外商品の場合
          g_item_line_tab(ln_item_line_cnt).amount_gross_margin := ln_amount_gross_margin * 1000;  -- 粗利額(単位：円)
          g_item_line_tab(ln_item_line_cnt).margin_rate         := 0;  -- 粗利率
          g_item_line_tab(ln_item_line_cnt).credit_rate         := 0;  -- 掛率
          g_item_line_tab(ln_item_line_cnt).amount              := 0;  -- 数量
        END IF;
        -------------------------------------------------
        -- 単品予算合計更新(対象商品群分)
        -------------------------------------------------
        --売上
        g_item_bgt_sum_tab(i).sales_budget        := g_item_bgt_sum_tab(i).sales_budget + ln_sales_budget * 1000;
        --粗利額
        g_item_bgt_sum_tab(i).amount_gross_margin := g_item_bgt_sum_tab(i).amount_gross_margin + g_item_line_tab(ln_item_line_cnt).amount_gross_margin;
        --
        ln_item_line_cnt := ln_item_line_cnt + 1;
        --
      END LOOP ;  --単品予算レコード設定ループ
      --
      lv_pre_item_group_no := g_upload_data_tab(ln_line_no).item_group_no;
      ln_line_no := ln_line_no + 4;
      --
    END LOOP  upload_data_tab_loop;
    --
    -------------------------------------------------
    -- 2.単品予算洗い替え（最後の商品群分）
    -------------------------------------------------
    exchange_item_bgt(
      ov_errbuf        => lv_errbuf          -- エラー・メッセージ
     ,ov_retcode       => lv_retcode         -- リターン・コード
     ,ov_errmsg        => lv_errmsg          -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_check ) THEN
      gv_group_status := cv_status_check;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    --
    IF gv_group_status = cv_status_check THEN
      ov_retcode := cv_status_error;
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- サブプログラム例外ハンドラ
    ----------------------------------------------------------
    WHEN sub_proc_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --
  END set_item_bgt;
  --
  /**********************************************************************************
   * Procedure Name   : chk_budget_item
   * Description      : アップロード予算値チェック
   ***********************************************************************************/
  PROCEDURE chk_budget_item(
     ov_errbuf               OUT VARCHAR2    -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2    -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2    -- ユーザー・エラー・メッセージ
    ,iv_item_group_no        IN  VARCHAR2    -- 商品群
    ,iv_item_no              IN  VARCHAR2    -- 商品コード
    ,iv_month                IN  VARCHAR2    -- 月
    ,in_sales_budget         IN  NUMBER      -- 売上
    ,in_amount_gross_margin  IN  NUMBER      -- 粗利額
    ,in_margin_rate          IN  NUMBER      -- 粗利率
    ,in_credit_rate          IN  NUMBER      -- 掛率
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_budget_item'; -- プログラム名
    --
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- メッセージ
    lb_retcode       BOOLEAN;             -- APIリターン・メッセージ用
    --
    ln_cnt              NUMBER;           -- カウンタ
    lv_out_regist_item  VARCHAR2(1);      -- 登録外商品判定
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    -------------------------------------------------
    -- 1.売上チェック
    -------------------------------------------------
    -------------------------------------------------
    -- NULL不可チェック
    -------------------------------------------------
    IF in_sales_budget IS NULL THEN
      --売上金額を指定してください
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcsm10328          -- メッセージコード
                     , iv_token_name1  => cv_tkn_deal_cd
                     , iv_token_value1 => iv_item_group_no
                     , iv_token_name2  => cv_tkn_item_cd
                     , iv_token_value2 => iv_item_no
                     , iv_token_name3  => cv_tkn_month
                     , iv_token_value3 => iv_month
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_check;
      --
    ELSE
      -------------------------------------------------
      -- マイナス不可チェック
      -------------------------------------------------
      IF in_sales_budget < 0 THEN  --この段階でNULLは無い
        --売上は0以上を設定してください
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10317          -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd
                       , iv_token_value1 => iv_item_group_no
                       , iv_token_name2  => cv_tkn_item_cd
                       , iv_token_value2 => iv_item_no
                       , iv_token_name3  => cv_tkn_month
                       , iv_token_value3 => iv_month
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
      -------------------------------------------------
      -- 売上小数点以下チェック
      -------------------------------------------------
      IF MOD(in_sales_budget, 1) > 0 THEN
        --売上、粗利額は小数点以下を指定できません
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm   -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcsm10324        -- メッセージコード
                     , iv_token_name1  => cv_tkn_deal_cd
                     , iv_token_value1 => iv_item_group_no
                     , iv_token_name2  => cv_tkn_item_cd
                     , iv_token_value2 => iv_item_no
                     , iv_token_name3  => cv_tkn_month
                     , iv_token_value3 => iv_month
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
    END IF;
    -------------------------------------------------
    -- 登録外商品判定
    -------------------------------------------------
    lv_out_regist_item := cv_n;
    --
    FOR i IN 1..g_out_regist_item_tab.COUNT LOOP
      IF iv_item_no = g_out_regist_item_tab(i) THEN
         lv_out_regist_item := cv_y;
      END IF;
    END LOOP;
    --
    -------------------------------------------------
    -- 2.粗利額、粗利率、掛率チェック
    -------------------------------------------------
    IF lv_out_regist_item = cv_n THEN
      --通常商品の場合
      --粗利額、粗利率、掛率
      SELECT NVL2(in_amount_gross_margin, 1, 0) + NVL2(in_margin_rate, 1, 0) + NVL2(in_credit_rate, 1, 0)
      INTO  ln_cnt
      FROM  dual
      ;
      IF ln_cnt = 1 THEN
        IF in_amount_gross_margin IS NOT NULL THEN
          --
          -------------------------------------------------
          -- 粗利額小数点以下チェック
          -------------------------------------------------
          IF MOD(in_amount_gross_margin, 1) > 0 THEN
            --粗利額は小数点以下を指定できません
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm  -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcsm10324       -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => iv_month
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
          END IF;
          --
        END IF;
        --
      ELSE
        -------------------------------------------------
        -- 1項目指定チェック
        -------------------------------------------------
        --粗利額、粗利率、掛率はいずれか1項目を設定してください
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10318
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => iv_month
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
    ELSE
      --登録外商品の場合
      IF in_amount_gross_margin IS NOT NULL
        AND in_margin_rate IS NULL
        AND in_credit_rate IS NULL
      THEN
        -------------------------------------------------
        -- 粗利額小数点以下チェック
        -------------------------------------------------
        IF MOD(in_amount_gross_margin, 1) > 0 THEN
          --粗利額は小数点以下を指定できません
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm  -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10324       -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd
                       , iv_token_value1 => iv_item_group_no
                       , iv_token_name2  => cv_tkn_item_cd
                       , iv_token_value2 => iv_item_no
                       , iv_token_name3  => cv_tkn_month
                       , iv_token_value3 => iv_month
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
      ELSE
        --登録外商品は粗利額のみを設定してください
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10327
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => iv_month
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
        --
      END IF;
      --
    END IF;
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
  END chk_budget_item;
  --
  /***********************************************************************************
   * Procedure Name   : chk_validate_item
   * Description      : 妥当性チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
   ,ov_retcode OUT VARCHAR2 -- リターン・コード
   ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- プログラム名
    --
    cv_security_mgr           CONSTANT VARCHAR2(1)  := '2';    -- 2:営業管理部･課
    cv_security_etc           CONSTANT VARCHAR2(1)  := '3';    -- 3:「営業企画」「営業管理」以外
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf      VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);    -- リターン・コード
    lv_errmsg      VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    lv_out_msg     VARCHAR2(2000); -- メッセージ
    lb_retcode     BOOLEAN;        -- メッセージ戻り値
    lv_chk_status  VARCHAR2(1);
    --
    lv_no_flv_tag               VARCHAR2(100);      -- セキュリティ制御戻値
    ln_cnt                      NUMBER;
    --
    lt_checked_location_cd      xxcsm_item_plan_headers.location_cd%TYPE;
    lt_checked_plan_year        xxcsm_item_plan_headers.plan_year%TYPE;
    lt_checked_item_group_no    xxcsm_item_plan_lines.item_group_no%TYPE;
    lt_checked_item_no          xxcsm_item_plan_lines.item_no%TYPE;
    lv_step                     VARCHAR2(200);
    --
    ln_month_count              NUMBER;           -- 月総数
    lv_month                    VARCHAR(100);     -- 差分存在月数
    lv_item_group_no            VARCHAR2(1000);   -- 商品群
    ln_item_cnt                 NUMBER;
    ln_line_no                  NUMBER;
    lt_group3_cd                xxcsm_commodity_group3_v.group3_cd%TYPE;
    lv_dmy                      VARCHAR(10);
    lt_unit_of_issue            xxcsm_commodity_group3_v.unit_of_issue%TYPE;
    --
    ln_sales_budget             NUMBER(14,2);
    ln_amount_gross_margin      NUMBER(14,2);
    ln_margin_rate              NUMBER(14,2);
    ln_credit_rate              NUMBER(14,2);
    --===============================
    -- ローカルカーソル定義
    --===============================
    --月別売上の差分チェック
    CURSOR kyoten_check_cur
    IS
      SELECT  xiplb.month_no              month_no                             --月
      FROM    xxcsm_item_plan_loc_bdgt xiplb                                   --商品計画拠点別予算テーブル
              ,(SELECT xipl.item_plan_header_id item_plan_header_id            --商品計画ヘッダID
                      ,xipl.month_no month_no                                  --月
                      ,SUM(xipl.sales_budget) sales_budget                     --売上金額
                FROM   xxcsm_item_plan_lines xipl                              --商品計画明細テーブル
                WHERE  xipl.item_plan_header_id = gt_item_plan_header_id
                AND    xipl.year_bdgt_kbn = cv_budget_kbn_month                --年間群予算区分(0：各月)
                AND    xipl.item_kbn = cv_item_kbn_group                       --商品区分
                GROUP BY xipl.item_plan_header_id
                        ,xipl.month_no
               ) xipl_view                                                     --商品計画明細月別予算インラインビュー
      WHERE   xipl_view.item_plan_header_id = xiplb.item_plan_header_id
      AND     xipl_view.month_no = xiplb.month_no
      AND     (xiplb.sales_budget + (xiplb.receipt_discount * -1) 
                 + (xiplb.sales_discount * -1)) <> xipl_view.sales_budget
      ORDER BY xiplb.month_no
      ;
    --群別売上の差分チェック
    CURSOR deal_check_cur
    IS
      SELECT xipl.item_group_no        item_group_no,     --商品群コード
             SUM(DECODE(xipl.year_bdgt_kbn, cv_budget_kbn_year, xipl.sales_budget, 0)) 
             - SUM(DECODE(xipl.year_bdgt_kbn, cv_budget_kbn_month, xipl.sales_budget, 0)) 
             sales_budget   -- SUM(年間群予算区分'1'の場合の売上金額) - SUM(年間群予算区分'0'の場合の売上金額)
      FROM   xxcsm_item_plan_lines   xipl                 --商品計画明細テーブル
      WHERE  xipl.item_plan_header_id = gt_item_plan_header_id
      AND    xipl.item_kbn = cv_item_kbn_group            --商品区分(0：商品群)
      GROUP BY xipl.item_group_no
      ORDER BY xipl.item_group_no
      ;
    --
    --===============================
    -- ローカル例外
    --===============================
    --
  BEGIN
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    --
    -------------------------------------------------
    -- 1.拠点コード、年度チェック
    -------------------------------------------------
    lv_step := '拠点、年度チェック';
    lt_checked_location_cd := NULL;
    lt_checked_plan_year   := NULL;
    lv_chk_status := cv_status_normal;
    << chk_upload_data_tab_loop >>
    FOR ln_line_no IN 1..g_upload_data_tab.COUNT LOOP
      IF ln_line_no = 1 THEN
        -------------------------------------------------
        -- 1-1. 1行目の拠点コードチェック
        -------------------------------------------------
        -------------------------------------------------
        -- 営業管理部・営業管理課・営業企画部判定
        -------------------------------------------------
        xxcsm_common_pkg.year_item_plan_security(
           in_user_id          => gn_user_id                    --ユーザID
          ,ov_lv6_kyoten_list  => lv_no_flv_tag                 --セキュリティ戻り値
          ,ov_retcode          => lv_retcode                    --リターンコード
          ,ov_errbuf           => lv_errbuf                     --エラーメッセージ
          ,ov_errmsg           => lv_errmsg                     --ユーザー・エラーメッセージ
        );
        -------------------------------------------------
        -- 商品計画対象拠点存在チェック
        -------------------------------------------------
        IF ( lv_no_flv_tag = cv_security_mgr   -- 2：営業管理部･課
          OR lv_no_flv_tag = cv_security_etc   -- 3：その他
          OR lv_retcode = cv_status_warn )
        THEN
          IF ( gv_dummy_dept_ref = cv_y ) THEN
            -- ユーザーが「営業企画部」「情報管理部」に所属していないと判定した場合
            -- または、リターンコード＝警告（自拠点未登録）の場合
            -- パラメータ.ダミー部門階層参照が'Y'の場合
            SELECT SUM(cnt)
            INTO   ln_cnt
            FROM (SELECT COUNT(*) AS cnt
                  FROM   fnd_lookup_values   flv
                  WHERE  flv.language        = ct_lang
                  AND    flv.lookup_type     = cv_lookup_type_dmy_dept
                  AND    flv.enabled_flag    = cv_y
                  AND    flv.attribute2      = gv_user_foothold  --ログインユーザ在席拠点
                  AND    flv.description     = g_upload_data_tab(ln_line_no).location_cd
                  UNION ALL
                  SELECT COUNT(*) AS cnt
                  FROM   apps.hz_cust_accounts    hca
                        ,apps.hz_parties          hps
                        ,apps.xxcmm_cust_accounts xca
                  WHERE  hca.party_id              = hps.party_id
                  AND    hca.cust_account_id       = xca.customer_id
                  AND   (hps.duns_number_c <> '90' OR hps.duns_number_c IS NULL)
                  AND   (xca.management_base_code  = gv_user_foothold
                  OR     hca.account_number        = gv_user_foothold)
                  AND    hca.account_number  = g_upload_data_tab(ln_line_no).location_cd
                 )
            ;
            --
          ELSE
            -- パラメータ.ダミー部門階層参照が'Y'以外の場合
            SELECT SUM(cnt)
            INTO   ln_cnt
            FROM (SELECT COUNT(*) AS cnt
                  FROM   hz_cust_accounts   hca
                        ,hz_parties         hps
                  WHERE  hca.party_id       = hps.party_id
                  AND    hca.customer_class_code = '1'
                  AND   (hps.duns_number_c <> '90' OR hps.duns_number_c IS NULL)
                  AND    hca.account_number = gv_user_foothold
                  AND    hca.account_number = g_upload_data_tab(ln_line_no).location_cd
                  UNION ALL
                  SELECT COUNT(*) AS cnt
                  FROM   hz_cust_accounts    hca
                        ,hz_parties          hps
                        ,xxcmm_cust_accounts xca
                  WHERE hca.party_id              = hps.party_id
                  AND    hca.cust_account_id      = xca.customer_id
                  AND   (hps.duns_number_c <> '90' OR hps.duns_number_c IS NULL)
                  AND    xca.management_base_code = gv_user_foothold
                  AND    hca.account_number = g_upload_data_tab(ln_line_no).location_cd
                 )
            ;
            --
          END IF;
          --
        ELSE
          -- 営業企画部の場合
          SELECT COUNT(*)
          INTO   ln_cnt
          FROM   hz_cust_accounts    hca
                ,hz_parties          hps
          WHERE hca.party_id            = hps.party_id
          AND   hca.customer_class_code = '1'
          AND  (hps.duns_number_c <> '90' OR hps.duns_number_c IS NULL)
          AND   hca.account_number = g_upload_data_tab(ln_line_no).location_cd
          ;
        END IF;
        --
        IF ln_cnt = 0 THEN
          -- 指定拠点エラーメッセージ出力し、異常終了
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm                      -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcsm10306                           -- メッセージコード
                         , iv_token_name1  => cv_tkn_kyoten_cd                            -- トークンコード1
                         , iv_token_value1 => g_upload_data_tab(ln_line_no).location_cd   -- トークン値1（拠点コード）
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        lt_checked_location_cd := g_upload_data_tab(ln_line_no).location_cd;
        --
        -------------------------------------------------
        -- 1-2. 1行目の予算年度チェック
        -------------------------------------------------
        IF g_upload_data_tab(ln_line_no).plan_year <> gt_plan_year THEN
          -- 年度エラーメッセージ出力し、異常終了
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcsm10308      -- メッセージコード
                         , iv_token_name1  => cv_tkn_yosan_nendo     -- トークンコード1
                         , iv_token_value1 => TO_CHAR(gt_plan_year)  -- トークン値1（予算年度）
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        lt_checked_plan_year := g_upload_data_tab(ln_line_no).plan_year;
        --
      ELSE
        IF lv_chk_status = cv_status_normal THEN
          --正常の場合のみチェックを続ける（大量メッセージ出力抑止）
          -------------------------------------------------
          -- 1-3. 2行目以降の拠点コードチェック
          -------------------------------------------------
          IF g_upload_data_tab(ln_line_no).location_cd <> lt_checked_location_cd THEN
            --複数拠点指定不可エラーメッセージを出力し処理中止
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10307      -- メッセージコード
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
            lv_chk_status := cv_status_check;
          END IF;
          --
          -------------------------------------------------
          -- 1-4. 2行目以降の予算年度チェック
          -------------------------------------------------
          IF g_upload_data_tab(ln_line_no).plan_year <> lt_checked_plan_year THEN
            --複数予算年度指定不可エラーメッセージを出力し処理中止
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10309      -- メッセージコード
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
            lv_chk_status := cv_status_check;
          END IF;
          --
        END IF;
        --
      END IF;
      --
    END LOOP  chk_upload_data_tab_loop;
    --2行目以降異値指定の場合
    IF lv_chk_status = cv_status_check THEN
      ov_retcode := cv_status_check;
    END IF;
    --チェックエラー有りの場合
    IF ov_retcode = cv_status_check THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    --拠点と年度が確定
    -------------------------------------------------
    -- 2.拠点予算、商品群予算登録チェック
    -------------------------------------------------
    lv_step := '拠点予算、商品群予算登録チェック';
    BEGIN
      SELECT xiph.item_plan_header_id
      INTO   gt_item_plan_header_id
      FROM   xxcsm_item_plan_headers xiph
      WHERE  xiph.plan_year = g_upload_data_tab(1).plan_year
      AND    xiph.location_cd = g_upload_data_tab(1).location_cd
      AND    EXISTS (SELECT 'x'
                     FROM xxcsm_item_plan_lines xipl
                     WHERE xiph.item_plan_header_id = xipl.item_plan_header_id
                    )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --年間計画未登録エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm            -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10325                 -- メッセージコード
                       , iv_token_name1  => cv_tkn_kyoten_cd                  -- トークンコード1
                       , iv_token_value1 => g_upload_data_tab(1).location_cd  -- トークン値1
                       , iv_token_name2  => cv_tkn_yosan_nendo                -- トークンコード2
                       , iv_token_value2 => g_upload_data_tab(1).plan_year    -- トークン値2
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_error;
        RETURN;
    END;
    -------------------------------------------------
    -- 3.商品計画売上チェック
    -------------------------------------------------
    -------------------------------------------------
    -- 3-1.月別売上の差分チェック
    -------------------------------------------------
    lv_step := '差分チェック';
    ln_month_count := 0;
    -- 月別売上の差分があるデータの月を取得
    FOR kyoten_check_rec IN kyoten_check_cur LOOP
      -- 月数
      ln_month_count := ln_month_count + 1;
      -- 差分がある月トークン作成/追記 
      IF lv_month IS NOT NULL THEN
        lv_month := lv_month || ',' || kyoten_check_rec.month_no;
      ELSE
        lv_month := kyoten_check_rec.month_no;
      END IF;
    END LOOP;
    --
    -- 差分存在する場合、エラーとする
    IF ln_month_count <> 0 THEN
      -- 月別売上の差分チェックエラーメッセージ出力し、異常終了
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcsm00050      -- メッセージコード
                     , iv_token_name1  => cv_tkn_yyyy            -- トークンコード1
                     , iv_token_value1 => TO_CHAR(gt_plan_year)  -- トークン値1（年）
                     , iv_token_name2  => cv_tkn_month           -- トークンコード1
                     , iv_token_value2 => lv_month               -- トークン値1（月）
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_check;
    END IF;
    --
    -------------------------------------------------
    -- 3-2.群別売上の差分チェック
    -------------------------------------------------
    --群別売上の差分チェック
    FOR deal_check_rec IN deal_check_cur LOOP
      -- 年間群計と年間群予算に差分がある場合
      IF deal_check_rec.sales_budget <> 0 THEN
        -- 差分がある商品群コードトークン作成/追記 
        IF lv_item_group_no IS NOT NULL THEN
          lv_item_group_no := lv_item_group_no || ',' || deal_check_rec.item_group_no;
        ELSE
          lv_item_group_no := deal_check_rec.item_group_no;
        END IF;
      END IF;
    END LOOP;
    -- 年間群計と年間群予算に差分がある場合、エラーとする
    IF lv_item_group_no IS NOT NULL THEN
      -- 政策群予算差分エラーメッセージ出力し、異常終了
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm  -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcsm00051       -- メッセージコード
                     , iv_token_name1  => cv_tkn_deal_cd          -- トークンコード1
                     , iv_token_value1 => lv_item_group_no        -- トークン値1（商品群）
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_check;
    END IF;
    --
    IF ov_retcode = cv_status_check THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    -------------------------------------------------
    -- 4.レコード区分チェック
    -------------------------------------------------
    lv_step := 'レコード区分チェック';
    --初期化
    lt_checked_item_group_no := cv_blank;
    lt_checked_item_no := cv_blank;
    --
    ln_item_cnt := 0;
    -- 商品群、商品コード、レコード区分順に処理を実施
    << chk_rec_type_loop >>
    -- 商品ごとのレコード区分件数をカウント
    FOR ln_line_no IN 1..g_upload_data_tab.COUNT LOOP
      -- チェック済商品と異なれば、商品別レコード区分件数ワーク初期化
      IF lt_checked_item_group_no <> g_upload_data_tab(ln_line_no).item_group_no
        OR lt_checked_item_no <> g_upload_data_tab(ln_line_no).item_no
      THEN
        ln_item_cnt := ln_item_cnt + 1;
        g_upload_item_tab(ln_item_cnt).item_group_no := g_upload_data_tab(ln_line_no).item_group_no;
        g_upload_item_tab(ln_item_cnt).item_no       := g_upload_data_tab(ln_line_no).item_no;
        g_upload_item_tab(ln_item_cnt).rec_type_a    := 0;
        g_upload_item_tab(ln_item_cnt).rec_type_b    := 0;
        g_upload_item_tab(ln_item_cnt).rec_type_c    := 0;
        g_upload_item_tab(ln_item_cnt).rec_type_d    := 0;
        g_upload_item_tab(ln_item_cnt).else_type     := 0;
      END IF;
      --
      --アップロード行レコード区分判定およびレコード区分数インクリメント
      IF g_upload_data_tab(ln_line_no).rec_type = cv_a THEN
        g_upload_item_tab(ln_item_cnt).rec_type_a := g_upload_item_tab(ln_item_cnt).rec_type_a + 1;
      ELSIF g_upload_data_tab(ln_line_no).rec_type = cv_b THEN
        g_upload_item_tab(ln_item_cnt).rec_type_b := g_upload_item_tab(ln_item_cnt).rec_type_b + 1;
      ELSIF g_upload_data_tab(ln_line_no).rec_type = cv_c THEN
        g_upload_item_tab(ln_item_cnt).rec_type_c := g_upload_item_tab(ln_item_cnt).rec_type_c + 1;
      ELSIF g_upload_data_tab(ln_line_no).rec_type = cv_d THEN
        g_upload_item_tab(ln_item_cnt).rec_type_d := g_upload_item_tab(ln_item_cnt).rec_type_d + 1;
      ELSE
        g_upload_item_tab(ln_item_cnt).else_type := g_upload_item_tab(ln_item_cnt).else_type + 1;
      END IF;
      --
      lt_checked_item_group_no := g_upload_data_tab(ln_line_no).item_group_no;
      lt_checked_item_no       := g_upload_data_tab(ln_line_no).item_no;
      --
    END LOOP  chk_rec_type_loop;
    --
    --対象レコード区分の件数エラーをログ出力
    << chk_rec_type_outlog_loop >>
    FOR ln_item_cnt IN 1..g_upload_item_tab.COUNT LOOP
      -- 売上レコード
      IF g_upload_item_tab(ln_item_cnt).rec_type_a = 0 THEN
        --未存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10310                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                                -- トークンコード1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                                -- トークンコード2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- トークン値2（商品コード）
                       , iv_token_name3  => cv_tkn_rec_type                               -- トークンコード3
                       , iv_token_value3 => cv_rec_type_a_name                            -- トークン値3（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF g_upload_item_tab(ln_item_cnt).rec_type_a > 1 THEN
        --複数存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10311                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                                -- トークンコード1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                                -- トークンコード2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- トークン値2（商品コード）
                       , iv_token_name3  => cv_tkn_rec_type                               -- トークンコード3
                       , iv_token_value3 => cv_rec_type_a_name                            -- トークン値3（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- 粗利額レコード
      IF g_upload_item_tab(ln_item_cnt).rec_type_b = 0 THEN
        --未存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10310                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                                -- トークンコード1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                                -- トークンコード2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- トークン値2（商品コード）
                       , iv_token_name3  => cv_tkn_rec_type                               -- トークンコード3
                       , iv_token_value3 => cv_rec_type_b_name                            -- トークン値3（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF g_upload_item_tab(ln_item_cnt).rec_type_b > 1 THEN
        --複数存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10311                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                                -- トークンコード1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                                -- トークンコード2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- トークン値2（商品コード）
                       , iv_token_name3  => cv_tkn_rec_type                               -- トークンコード3
                       , iv_token_value3 => cv_rec_type_b_name                            -- トークン値3（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- 粗利率レコード
      IF g_upload_item_tab(ln_item_cnt).rec_type_c = 0 THEN
        --未存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10310                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                                -- トークンコード1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                                -- トークンコード2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- トークン値2（商品コード）
                       , iv_token_name3  => cv_tkn_rec_type                               -- トークンコード3
                       , iv_token_value3 => cv_rec_type_c_name                            -- トークン値3（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF g_upload_item_tab(ln_item_cnt).rec_type_c > 1 THEN
        --複数存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10311                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                                -- トークンコード1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                                -- トークンコード2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- トークン値2（商品コード）
                       , iv_token_name3  => cv_tkn_rec_type                               -- トークンコード3
                       , iv_token_value3 => cv_rec_type_c_name                            -- トークン値3（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- 掛率レコード
      IF g_upload_item_tab(ln_item_cnt).rec_type_d = 0 THEN
        --未存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10310                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                                -- トークンコード1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                                -- トークンコード2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- トークン値2（商品コード）
                       , iv_token_name3  => cv_tkn_rec_type                               -- トークンコード3
                       , iv_token_value3 => cv_rec_type_d_name                            -- トークン値3（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF g_upload_item_tab(ln_item_cnt).rec_type_d > 1 THEN
        --複数存在エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10311                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                                -- トークンコード1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                                -- トークンコード2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- トークン値2（商品コード）
                       , iv_token_name3  => cv_tkn_rec_type                               -- トークンコード3
                       , iv_token_value3 => cv_rec_type_d_name                            -- トークン値3（レコード区分）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- 売上、粗利額、粗利率、掛率以外のレコード存在エラー
      IF g_upload_item_tab(ln_item_cnt).else_type > 0 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10312                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_deal_cd                                -- トークンコード1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- トークン値1（商品群）
                       , iv_token_name2  => cv_tkn_item_cd                                -- トークンコード2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- トークン値2（商品コード）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
    END LOOP  chk_rec_type_outlog_loop;
    --
    IF ov_retcode = cv_status_check THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    --レコード区分4行が確定
    -------------------------------------------------
    -- 5.アップロード商品チェック
    -------------------------------------------------
    -- 商品群、商品コード、レコード区分順に処理
    ln_line_no := 1;
    << chk_item_loop >>
    LOOP
      EXIT WHEN ln_line_no > g_upload_data_tab.COUNT;
      lv_step := '商品チェック:'||g_upload_data_tab(ln_line_no).item_no;
      --
      lv_chk_status := cv_status_normal;  --組合せなし時の以降のチェックスキップ用
      -------------------------------------------------
      -- 1.組合せ存在チェック
      -------------------------------------------------
      BEGIN
        SELECT xcg3v.unit_of_issue
        INTO   lt_unit_of_issue
        FROM   xxcsm_commodity_group3_v  xcg3v
        WHERE  xcg3v.group3_cd = g_upload_data_tab(ln_line_no).item_group_no
        AND    xcg3v.item_cd = g_upload_data_tab(ln_line_no).item_no
        AND    NOT EXISTS(SELECT 'X'
                          FROM   xxcsm_item_category_v xicv
                          WHERE  xicv.attribute3 = xcg3v.item_cd
                         )
       ;
       --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --商品群と商品コードの組合せが存在しません
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm                       -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcsm10313                            -- メッセージコード
                         , iv_token_name1  => cv_tkn_deal_cd                               -- トークンコード1
                         , iv_token_value1 => g_upload_data_tab(ln_line_no).item_group_no  -- トークン値1（商品群）
                         , iv_token_name2  => cv_tkn_item_cd                               -- トークンコード2
                         , iv_token_value2 => g_upload_data_tab(ln_line_no).item_no        -- トークン値2（商品コード）
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_chk_status := cv_status_check;
          ov_retcode := cv_status_check;
      END;
      --
      IF lv_chk_status = cv_status_normal THEN
        --マスタチェックokの場合のみ、以降の処理を継続
        -------------------------------------------------
        -- 2.バラ区分取得
        -------------------------------------------------
        g_upload_data_tab(ln_line_no).bara_kbn := cv_n;
        --
        FOR i IN 1..g_bara_unit_tab.COUNT LOOP
          IF lt_unit_of_issue = g_bara_unit_tab(i) THEN
            g_upload_data_tab(ln_line_no).bara_kbn := cv_y;
          END IF;
        END LOOP;
        --
        -------------------------------------------------
        -- 3.商品群予算存在チェック
        -------------------------------------------------
        BEGIN
          SELECT 'x'
          INTO   lv_dmy
          FROM   xxcsm_item_plan_lines    xipl
          WHERE  xipl.item_plan_header_id = gt_item_plan_header_id
          AND    xipl.item_group_no       =  g_upload_data_tab(ln_line_no).item_group_no
          AND    xipl.item_kbn            = cv_item_kbn_group
          AND    ROWNUM                   = 1
          ;
          --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --商品群予算が存在しません
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm                         -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10314                              -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd                                 -- トークンコード1
                           , iv_token_value1 => g_upload_data_tab(ln_line_no).item_group_no    -- トークン値1（商品群）
                           , iv_token_name2  => cv_tkn_item_cd                                 -- トークンコード2
                           , iv_token_value2 => g_upload_data_tab(ln_line_no).item_no          -- トークン値2（商品コード）
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
        END;
        --
        -------------------------------------------------
        -- 4.営業原価取得
        -------------------------------------------------
        BEGIN
          -- 切替前年度の営業原価を品目変更履歴から取得
          SELECT xsibh.discrete_cost                                           -- 営業原価
          INTO   g_upload_data_tab(ln_line_no).discrete_cost
          FROM   xxcmm_system_items_b_hst   xsibh                              -- 品目変更履歴テーブル
                ,(SELECT MAX(item_hst_id)   item_hst_id                        -- 品目変更履歴ID
                  FROM   xxcmm_system_items_b_hst                              -- 品目変更履歴
                  WHERE  item_code  = g_upload_data_tab(ln_line_no).item_no    -- 品目コード
                  AND    apply_date < gd_start_date                            -- 年度開始日前
                  AND    apply_flag = cv_y                                     -- 適用済み
                  AND    discrete_cost IS NOT NULL                             -- 営業原価 IS NOT NULL
                 ) xsibh_view
          WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id                    -- 品目変更履歴ID
          AND    xsibh.item_code   = g_upload_data_tab(ln_line_no).item_no     -- 商品コード
          AND    xsibh.apply_flag  = cv_y                                      -- 適用済み
          AND    xsibh.discrete_cost IS NOT NULL
          ;
          --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --営業原価取得エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm                       -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10315                            -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd                               -- トークンコード1
                           , iv_token_value1 => g_upload_data_tab(ln_line_no).item_group_no  -- トークン値1（商品群）
                           , iv_token_name2  => cv_tkn_item_cd                               -- トークンコード2
                           , iv_token_value2 => g_upload_data_tab(ln_line_no).item_no        -- トークン値2（商品コード）
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
        END;
        -------------------------------------------------
        -- 5.定価取得
        -------------------------------------------------
        BEGIN
          -- 切替前年度の定価を品目変更履歴から取得
          SELECT xsibh.fixed_price                                             -- 定価
          INTO   g_upload_data_tab(ln_line_no).fixed_price
          FROM   xxcmm_system_items_b_hst   xsibh                              -- 品目変更履歴テーブル
                ,(SELECT MAX(item_hst_id)   item_hst_id                        -- 品目変更履歴ID
                  FROM   xxcmm_system_items_b_hst                              -- 品目変更履歴
                  WHERE  item_code  = g_upload_data_tab(ln_line_no).item_no    -- 品目コード
                  AND    apply_date < gd_start_date                            -- 年度開始日前
                  AND    apply_flag = cv_y                                     -- 適用済み
                  AND    fixed_price IS NOT NULL                               -- 定価 IS NOT NULL
                    ) xsibh_view
          WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id                    -- 品目変更履歴ID
          AND    xsibh.item_code   = g_upload_data_tab(ln_line_no).item_no     -- 商品コード
          AND    xsibh.apply_flag  = cv_y                                      -- 適用済み
          AND    xsibh.fixed_price IS NOT NULL
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --定価取得エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm                       -- アプリケーション短縮名
                           , iv_name         => cv_msg_xxcsm10316                            -- メッセージコード
                           , iv_token_name1  => cv_tkn_deal_cd                               -- トークンコード1
                           , iv_token_value1 => g_upload_data_tab(ln_line_no).item_group_no  -- トークン値1（商品群）
                           , iv_token_name2  => cv_tkn_item_cd                               -- トークンコード2
                           , iv_token_value2 => g_upload_data_tab(ln_line_no).item_no        -- トークン値2（商品コード）
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
        END;
        --
      END IF;
      --
      ln_line_no := ln_line_no + 4;
      --
    END LOOP  chk_item_loop;
    --
    --商品群、商品の妥当性チェック終了
    IF ov_retcode = cv_status_check THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    --
    -------------------------------------------------
    -- 6.売上、粗利額、粗利率、掛率チェック
    -------------------------------------------------
    ln_line_no := 1;
    << chk_value_loop >>
    LOOP
      EXIT WHEN ln_line_no > g_upload_data_tab.COUNT;
      --
      --12ヶ月分ループ
      <<LOOP1>>
      FOR i IN 1..12 LOOP
        lv_step := '予算値チェック 商品:'||g_upload_data_tab(ln_line_no).item_no||' i='||TO_CHAR(i);
        IF i = 1 THEN
          lv_month               := '5';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_05;      -- 売上
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_05;  -- 粗利額
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_05;  -- 粗利率
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_05;  -- 掛率
        ELSIF i = 2 THEN
          lv_month               := '6';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_06;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_06;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_06;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_06;
        ELSIF i = 3 THEN
          lv_month               := '7';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_07;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_07;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_07;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_07;
        ELSIF i = 4 THEN
          lv_month               := '8';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_08;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_08;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_08;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_08;
        ELSIF i = 5 THEN
          lv_month               := '9';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_09;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_09;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_09;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_09;
        ELSIF i = 6 THEN
          lv_month               := '10';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_10;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_10;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_10;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_10;
        ELSIF i = 7 THEN
          lv_month               := '11';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_11;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_11;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_11;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_11;
        ELSIF i = 8 THEN
          lv_month               := '12';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_12;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_12;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_12;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_12;
        ELSIF i = 9 THEN
          lv_month               := '1';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_01;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_01;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_01;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_01;
        ELSIF i = 10 THEN
          lv_month               := '2';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_02;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_02;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_02;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_02;
        ELSIF i = 11 THEN
          lv_month               := '3';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_03;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_03;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_03;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_03;
        ELSE
          lv_month               := '4';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_04;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_04;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_04;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_04;
        END IF;
        --
        -------------------------------------------------
        -- 6-1.アップロード予算値チェック
        -------------------------------------------------
        chk_budget_item(
          ov_errbuf               => lv_errbuf          -- エラー・メッセージ
         ,ov_retcode              => lv_retcode         -- リターン・コード
         ,ov_errmsg               => lv_errmsg          -- ユーザー・エラー・メッセージ
         ,iv_item_group_no        => g_upload_data_tab(ln_line_no).item_group_no
         ,iv_item_no              => g_upload_data_tab(ln_line_no).item_no
         ,iv_month                => lv_month
         ,in_sales_budget         => ln_sales_budget         -- 売上
         ,in_amount_gross_margin  => ln_amount_gross_margin  -- 粗利額
         ,in_margin_rate          => ln_margin_rate          -- 粗利率
         ,in_credit_rate          => ln_credit_rate          -- 掛率
        );
        -- ステータスエラー判定
        IF ( lv_retcode = cv_status_check ) THEN
          ov_retcode := cv_status_check;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP  LOOP1;
      --
      ln_line_no := ln_line_no + 4;
      --
    END LOOP  chk_value_loop;
    --
    -- ステータスエラー判定
    IF ov_retcode = cv_status_check THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- 予算値チェック例外ハンドラ
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_validate_item;
  --
  --
  /**********************************************************************************
   * Procedure Name   : chk_upload_item
   * Description      : アップロード項目チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_upload_item(
     ov_errbuf     OUT VARCHAR2                           -- エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2                           -- リターン・コード
    ,ov_errmsg     OUT VARCHAR2                           -- ユーザー・エラー・メッセージ
    ,it_file_data  IN  xxccp_common_pkg2.g_file_data_tbl  -- BLOB変換後
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_upload_item'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf        VARCHAR2(5000);    -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);       -- リターン・コード
    lv_errmsg        VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);    -- メッセージ
    lb_retcode       BOOLEAN;           -- APIリターン・メッセージ用
    --アップロード項目チェック
    ln_col_cnt                  PLS_INTEGER := 0;                  -- アップロード項目数
    lt_csv_data_all             xxcok_common_pkg.g_split_csv_tbl;  -- CSV分割データ（TRIM前）
    lt_csv_data                 xxcok_common_pkg.g_split_csv_tbl;  -- CSV分割データ（TRIM後）
    --正常データ格納用  INDEX = 商品群(4) || 商品コード(7) || レコード区分(1) || カウンタ(5)
    TYPE l_upload_data_ttype_v IS TABLE OF g_upload_data_rtype INDEX BY VARCHAR2(17);
    lt_upload_data_tab_v        l_upload_data_ttype_v;
    lv_step                     VARCHAR2(200);
    --
    lv_index                    VARCHAR2(17);  --商品群(4) || 商品コード(7) || レコード区分(1) || カウンタ(5)
    --
    ln_line_cnt                 NUMBER;        --アップロードレコードカウンタ
    lv_item_err                 VARCHAR2(1);   --リターン・コード
    lv_chk_status               VARCHAR2(1);
    --===============================
    -- ローカル例外
    --===============================
    --
  BEGIN
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    -------------------------------------------------
    -- 1.アップロードデータ項目チェック
    -------------------------------------------------
    << split_item_loop >>
    FOR ln_line_no IN 1..it_file_data.COUNT LOOP
      -------------------------------------------------
      -- 1-1.アップロードデータ項目分割
      -------------------------------------------------
      xxcok_common_pkg.split_csv_data_p(
        ov_errbuf        => lv_errbuf                 -- エラー・メッセージ
       ,ov_retcode       => lv_retcode                -- リターン・コード
       ,ov_errmsg        => lv_errmsg                 -- ユーザー・エラー・メッセージ
       ,iv_csv_data      => it_file_data(ln_line_no)  -- CSV文字列（アップロード1行）
       ,on_csv_col_cnt   => ln_col_cnt                -- CSV項目数
       ,ov_split_csv_tab => lt_csv_data_all           -- CSV分割データ（配列で返す）TRIM前配列
      );
      --
      -------------------------------------------------
      -- 1-2.項目数チェック
      -------------------------------------------------
      IF ( gn_item_cnt <> ln_col_cnt ) THEN
        -- 項目数相違エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm  -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcsm10301       -- メッセージコード
                       , iv_token_name1  => cv_tkn_row_num          -- トークンコード1
                       , iv_token_value1 => ln_line_no + 1          -- トークン値1（見出し込みの行数）
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode  := cv_status_check;
        CONTINUE;
      END IF;
      --
      -------------------------------------------------
      -- 1-3.アップロード値項目チェック
      -------------------------------------------------
      lv_chk_status := cv_status_normal;
      << item_check_loop >>
      FOR ln_item_no IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
        --
        lt_csv_data(ln_item_no) := TRIM( lt_csv_data_all(ln_item_no) );  --TRIM後配列へ
        --
        lv_step := 'アップロード値項目チェック 行番号='||TO_CHAR(ln_line_no+1)||' 項目番号='||TO_CHAR(ln_item_no)||' 値=['||lt_csv_data(ln_item_no)||']';
        -- 項目チェック共通関数
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_chk_item_tab(ln_item_no).meaning     -- 項目名称
         ,iv_item_value   => lt_csv_data(ln_item_no)                -- 項目の値
         ,in_item_len     => g_chk_item_tab(ln_item_no).attribute1  -- 項目の長さ
         ,in_item_decimal => g_chk_item_tab(ln_item_no).attribute2  -- 項目の長さ(小数点以下)
         ,iv_item_nullflg => g_chk_item_tab(ln_item_no).attribute3  -- 必須フラグ
         ,iv_item_attr    => g_chk_item_tab(ln_item_no).attribute4  -- 項目属性
         ,ov_errbuf       => lv_errbuf                              -- エラー・メッセージ           --# 固定 #
         ,ov_retcode      => lv_retcode                             -- リターン・コード             --# 固定 #
         ,ov_errmsg       => lv_errmsg                              -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- リターンコードが正常以外の場合
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- 項目不備エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm               -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcsm10302                    -- メッセージコード
                         , iv_token_name1  => cv_tkn_item                          -- トークンコード1
                         , iv_token_value1 => g_chk_item_tab(ln_item_no).meaning   -- トークン値1
                         , iv_token_name2  => cv_tkn_errmsg                        -- トークンコード2
                         , iv_token_value2 => lv_errmsg                            -- トークン値2
                         , iv_token_name3  => cv_tkn_row_num                       -- トークンコード3
                         , iv_token_value3 => ln_line_no + 1                       -- トークン値3（見出し込みの行数）
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          --
          lv_chk_status := cv_status_error;
          --
        END IF;
        --
      END LOOP item_check_loop;
      --
      -------------------------------------------------
      -- 1-4.正常データ退避
      -------------------------------------------------
      lv_step := '正常データ退避 行番号='||TO_CHAR(ln_line_no+1);
      IF ( lv_chk_status = cv_status_normal ) THEN
        -- 正常データ退避
        -- index = 商品群 + 商品コード + レコード区分 + シーケンス
        lv_index := lt_csv_data(3) || lt_csv_data(4) || CASE lt_csv_data(6) 
                                                        WHEN cv_rec_type_a_name THEN cv_a
                                                        WHEN cv_rec_type_b_name THEN cv_b
                                                        WHEN cv_rec_type_c_name THEN cv_c
                                                        WHEN cv_rec_type_d_name THEN cv_d
                                                        ELSE cv_z
                                                        END
                                                     || TO_CHAR(ln_line_no, 'FM00000')
                                                        ;
        --
        lt_upload_data_tab_v(lv_index).location_cd   := lt_csv_data(1) ;   -- 拠点コード
        lt_upload_data_tab_v(lv_index).plan_year     := lt_csv_data(2) ;   -- 年度
        lt_upload_data_tab_v(lv_index).item_group_no := lt_csv_data(3) ;   -- 商品群
        lt_upload_data_tab_v(lv_index).item_no       := lt_csv_data(4) ;   -- 商品コード
        lt_upload_data_tab_v(lv_index).item_name     := lt_csv_data(5) ;   -- 商品名
        lt_upload_data_tab_v(lv_index).rec_type      := CASE lt_csv_data(6)
                                                        WHEN cv_rec_type_a_name THEN cv_a
                                                        WHEN cv_rec_type_b_name THEN cv_b
                                                        WHEN cv_rec_type_c_name THEN cv_c
                                                        WHEN cv_rec_type_d_name THEN cv_d
                                                        ELSE cv_z
                                                        END;           --レコード区分 
        lt_upload_data_tab_v(lv_index).month_05      := lt_csv_data(7) ;   --  5月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_06      := lt_csv_data(8) ;   --  6月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_07      := lt_csv_data(9) ;   --  7月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_08      := lt_csv_data(10);   --  8月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_09      := lt_csv_data(11);   --  9月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_10      := lt_csv_data(12);   -- 10月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_11      := lt_csv_data(13);   -- 11月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_12      := lt_csv_data(14);   -- 12月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_01      := lt_csv_data(15);   --  1月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_02      := lt_csv_data(16);   --  2月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_03      := lt_csv_data(17);   --  3月分（金額、率）
        lt_upload_data_tab_v(lv_index).month_04      := lt_csv_data(18);   --  4月分（金額、率）
        --
      ELSE
        ov_retcode := cv_status_check;
      END IF;
      --
    END LOOP  split_item_loop;
    --
    IF ( ov_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    --
    -------------------------------------------------
    -- 2.正常データ並び替え（商品群、商品、レコード区分順）
    -------------------------------------------------
    lv_index    := lt_upload_data_tab_v.FIRST;
    ln_line_cnt := 1;
    LOOP
      g_upload_data_tab(ln_line_cnt) := lt_upload_data_tab_v(lv_index);
      --
      EXIT WHEN lv_index = lt_upload_data_tab_v.LAST;
      lv_index := lt_upload_data_tab_v.NEXT(lv_index);
      ln_line_cnt := ln_line_cnt + 1;
      --
    END LOOP;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_upload_item;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_upload_line
   * Description      : アップロードデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_line(
    ov_errbuf       OUT VARCHAR2    -- エラー・メッセージ
   ,ov_retcode      OUT VARCHAR2    -- リターン・コード
   ,ov_errmsg       OUT VARCHAR2    -- ユーザー・エラー・メッセージ
   ,iv_file_id      IN  VARCHAR2    -- ファイルID
   ,ot_file_data    OUT xxccp_common_pkg2.g_file_data_tbl  -- BLOB変換後(見出し、空行無し)
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_upload_line'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf        VARCHAR2(5000);                                -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);                                   -- リターン・コード
    lv_errmsg        VARCHAR2(5000);                                -- ユーザー・エラー・メッセージ
    lb_retcode       BOOLEAN;                                       -- APIリターン・メッセージ用
    lv_out_msg       VARCHAR2(2000);                                -- メッセージ
    -- BLOB
    lt_file_data_all          xxccp_common_pkg2.g_file_data_tbl;    -- BLOB変換後データ退避(全データ)
    ln_line_cnt               NUMBER;                               -- CSV処理行カウンタ
    --===============================
    -- ローカル例外
    --===============================
    blob_err_expt    EXCEPTION; -- BLOB変換エラー
    no_data_err_expt EXCEPTION; -- アップロード処理対象なしエラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    ln_line_cnt := 0;
    --
    -------------------------------------------------
    -- 1.BLOBデータ変換
    -------------------------------------------------
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => TO_NUMBER(iv_file_id)  -- ファイルID
     ,ov_file_data => lt_file_data_all       -- BLOB変換後データ退避(空行、見出し含む)
     ,ov_errbuf    => lv_errbuf              -- エラー・メッセージ
     ,ov_retcode   => lv_retcode             -- リターン・コード
     ,ov_errmsg    => lv_errmsg              -- ユーザー・エラー・メッセージ 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE blob_err_expt;
    END IF;
    -------------------------------------------------
    -- 2.2.見出し、無効行除外
    -------------------------------------------------
    << blob_data_loop >>
    FOR i IN 2..lt_file_data_all.COUNT LOOP
      IF ( LENGTHB( REPLACE( lt_file_data_all(i), ',', '') ) <> 0 ) THEN
        ln_line_cnt := ln_line_cnt + 1;
        ot_file_data(ln_line_cnt) := lt_file_data_all(i);
      END IF;
    END LOOP blob_data_loop;
    -- 処理対象件数を退避
    gn_target_cnt := ln_line_cnt;  --見出し、空行を除いた件数
    -- 編集用のテーブル削除
    lt_file_data_all.DELETE;
    -- 処理対象存在チェック
    IF ( gn_target_cnt <= cn_0 ) THEN
      RAISE no_data_err_expt;
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- BLOB変換例外ハンドラ
    ----------------------------------------------------------
    WHEN blob_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm
                      ,iv_name         => cv_msg_xxcsm10304
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => iv_file_id
                    );
      -- エラーメッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_blank
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- アップロード処理対象なし例外ハンドラ
    ----------------------------------------------------------
    WHEN no_data_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm
                      ,iv_name         => cv_msg_xxcsm10305
                    );
      -- エラーメッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_blank
      );
      ov_errmsg  := NULL;
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
  END get_upload_line;
  --
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
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
    cv_prg_name               CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_out_msg     VARCHAR2(2000);  -- メッセージ
    lb_retcode     BOOLEAN;         -- メッセージ戻り値
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- アップロード項目チェックカーソル
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning       AS meaning     -- 項目名称
           , flv.attribute1    AS attribute1  -- 項目の長さ
           , flv.attribute2    AS attribute2  -- 項目の長さ（小数点以下）
           , flv.attribute3    AS attribute3  -- 必須フラグ
           , flv.attribute4    AS attribute4  -- 属性
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_upload_item_chk_name
      AND    gd_proc_date BETWEEN NVL( flv.start_date_active, gd_proc_date )
                              AND NVL( flv.end_date_active, gd_proc_date )
      AND    flv.enabled_flag = cv_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
    ;
    --
    -- 会計カレンダから当年度開始日を取得カーソル
    CURSOR cur_get_month_this_year
    IS 
      SELECT   glpds.start_date            AS start_date             -- 年度開始日
      FROM     gl_periods        glpds,                              -- 会計カレンダテーブル
               gl_sets_of_books  glsob                               -- 会計帳簿マスタ
      WHERE    glsob.set_of_books_id        = gn_gl_set_of_bks_id    -- 会計帳簿ID
      AND      glpds.period_set_name        = glsob.period_set_name  -- カレンダ名
      AND      glpds.period_year            = gt_plan_year           -- 予算年度
      AND      glpds.adjustment_period_flag = cv_n                   -- 調整会計期間外
      AND      glpds.period_num             = 1                      -- 年度開始月
    ;
    rec_get_month_this_year cur_get_month_this_year%ROWTYPE;
--
    -- 会計カレンダから昨年度開始日を取得
    CURSOR cur_get_month_last_year
    IS
    SELECT   glpds.start_date              AS start_date             -- 年度開始日
    FROM     gl_periods        glpds,                                -- 会計カレンダテーブル
             gl_sets_of_books  glsob                                 -- 会計帳簿マスタ
    WHERE    glsob.set_of_books_id        = gn_gl_set_of_bks_id      -- 会計帳簿ID
    AND      glpds.period_set_name        = glsob.period_set_name    -- カレンダ名
    AND      glpds.period_year            = gt_plan_year - 1         -- 予算年度
    AND      glpds.adjustment_period_flag = cv_n                     -- 調整会計期間外
    AND      glpds.period_num             = 1;                       -- 年度開始月
    rec_get_month_last_year cur_get_month_last_year%ROWTYPE;
--
    -- バラ単位取得カーソル
    CURSOR bara_unit_cur
    IS
      SELECT  flv.meaning                  AS meaning
      FROM    fnd_lookup_values   flv                   --「クイックコード値」
      WHERE   flv.lookup_type     = cv_lookup_type_bara
      AND     flv.language        = ct_lang
      AND     flv.enabled_flag    = cv_y
      AND     gd_proc_date  BETWEEN  NVL(flv.start_date_active ,gd_proc_date)
                                AND  NVL(flv.end_date_active, gd_proc_date)
    ;
    --
    -- 登録外商品取得カーソル
    CURSOR out_regist_item_cur
    IS
      SELECT flv.lookup_code               AS lookup_code
      FROM   fnd_lookup_values  flv                    -- クイックコード値
      WHERE  flv.lookup_type     = cv_out_regist_item  -- 参照タイプ：登録外商品コード
      AND    flv.language        = ct_lang             -- 言語
      AND    flv.enabled_flag    = cv_y                -- 有効フラグ
      AND    TRUNC(gd_proc_date)  BETWEEN  TRUNC(NVL(flv.start_date_active, gd_proc_date)) 
                                      AND  TRUNC(NVL(flv.end_date_active,   gd_proc_date))
    ;
    --
    -- 変数
    ln_count                   NUMBER;
    lv_status                  VARCHAR2(1);                          -- 共通関数ステータス
    lv_employee_code           per_people_f.employee_number%TYPE;    -- 従業員コード
    --===============================
    -- ローカル例外
    --===============================
    get_date_err_expt           EXCEPTION; -- 業務処理日付取得エラー
    get_item_chk_lookup_expt    EXCEPTION; -- 項目チェック用クイックコード取得エラー
    get_profile_expt            EXCEPTION; -- プロファイル取得エラー
    --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -------------------------------------------------
    -- 1.コンカレント入力パラメータメッセージ出力
    -------------------------------------------------
    -- コンカレントパラメータ.ファイルIDメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_csm
                   ,iv_name         => cv_msg_xxcsm00101
                   ,iv_token_name1  => cv_tkn_file_id
                   ,iv_token_value1 => iv_file_id
                  );
    -- コンカレントパラメータ.ファイルIDメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- コンカレントパラメータ.フォーマットパターンメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_csm
                   ,iv_name         => cv_msg_xxcsm00102
                   ,iv_token_name1  => cv_tkn_format
                   ,iv_token_value1 => iv_format
                  );
    -- コンカレントパラメータ.フォーマットパターンメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    -- ユーザーIDの取得
    gn_user_id   := FND_GLOBAL.USER_ID;
    -------------------------------------------------
    -- 2.業務処理日付取得
    -------------------------------------------------
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      RAISE get_date_err_expt;
    END IF;
    -------------------------------------------------
    -- 3.項目チェック用定義取得
    -------------------------------------------------
    OPEN  chk_item_cur;
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    CLOSE chk_item_cur;
    --
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      RAISE get_item_chk_lookup_expt;
    END IF;
    --
    gn_item_cnt := g_chk_item_tab.COUNT;  --項目数取得
    --
    -------------------------------------------------
    -- 4.プロファイル取得
    -------------------------------------------------
    -- XXCSM:年間販売計画カレンダー名
    gv_prof_yearplan_calender := FND_PROFILE.VALUE(cv_prof_yearplan_calender);
    IF( gv_prof_yearplan_calender IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00005
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- XXCSM:政策群品目カテゴリ特定名
    gv_prof_deal_category := FND_PROFILE.VALUE(cv_prof_deal_category);
    IF( gv_prof_deal_category IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00005
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_prof_deal_category
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- XXCOI:在庫組織コード
    gv_prof_organization_code  := FND_PROFILE.VALUE(cv_prof_organization_code);
    IF( gv_prof_organization_code IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00005
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_prof_organization_code
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- XXCSM:ダミー部門階層参照
    gv_dummy_dept_ref := FND_PROFILE.VALUE( cv_xxcsm1_dummy_dept_ref );
    IF( gv_dummy_dept_ref IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00005
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_xxcsm1_dummy_dept_ref
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- GL会計帳簿ID
    gn_gl_set_of_bks_id         := FND_PROFILE.VALUE( cv_gl_set_of_bks_id_nm );
    IF( gn_gl_set_of_bks_id IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00005
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_gl_set_of_bks_id_nm
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- 在庫組織ID取得処理
    gn_organization_id := xxcoi_common_pkg.get_organization_id(gv_prof_organization_code);
    IF( gn_organization_id IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00037
                     ,iv_token_name1          => cv_tkn_org_code
                     ,iv_token_value1         => gv_prof_organization_code
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    IF ov_retcode = cv_status_error THEN
      RETURN;
    END IF;
    --
    -------------------------------------------------
    -- 5.年間販売計画カレンダ存在チェック
    -------------------------------------------------
    SELECT COUNT(*)
    INTO   ln_count
    FROM   fnd_flex_value_sets ffvs
    WHERE  flex_value_set_name = gv_prof_yearplan_calender
    ;
    -- カレンダ定義が存在しない場合
    IF (ln_count = 0) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00006
                     ,iv_token_name1          => cv_tkn_item
                     ,iv_token_value1         => gv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -------------------------------------------------
    -- 6.予算年度取得
    -------------------------------------------------
    xxcsm_common_pkg.get_yearplan_calender(
      id_comparison_date => gd_proc_date           -- 運用日
     ,ov_status          => lv_status              -- 処理結果(0：正常、1：異常)
     ,on_active_year     => gt_plan_year           -- 取得した予算年度
     ,ov_retcode         => lv_retcode             -- リターンコード
     ,ov_errbuf          => lv_errbuf              -- エラーメッセージ
     ,ov_errmsg          => lv_errmsg              -- ユーザー・エラーメッセージ
    );
    -- 予算年度が存在しない場合
    IF ( lv_status <> cv_status_normal ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00004
                     ,iv_token_name1          => cv_tkn_item
                     ,iv_token_value1         => gv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -------------------------------------------------
    -- 7.ログインユーザー在籍拠点取得
    -------------------------------------------------
    xxcsm_common_pkg.get_login_user_foothold(
      in_user_id       => gn_user_id               --ユーザID
     ,ov_foothold_code => gv_user_foothold         --拠点コード
     ,ov_employee_code => lv_employee_code         --従業員コード
     ,ov_retcode       => lv_retcode               --リターンコード
     ,ov_errbuf        => lv_errbuf                --エラーメッセージ
     ,ov_errmsg        => lv_errmsg                --ユーザー・エラーメッセージ
    );
    -- ログインユーザー在籍拠点が存在しない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00059
                     ,iv_token_name1          => cv_tkn_user_id
                     ,iv_token_value1         => gn_user_id
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    IF ov_retcode = cv_status_error THEN
      RETURN;
    END IF;
    --
    -------------------------------------------------
    -- 8.年度開始日取得
    -------------------------------------------------
    -- パラメータの初期化
    gd_start_date := NULL;
    -- 年度開始日を取得
    OPEN cur_get_month_this_year;
    FETCH cur_get_month_this_year INTO rec_get_month_this_year;
    CLOSE cur_get_month_this_year;
    -- パラメータ.年度開始日をセット
    gd_start_date := rec_get_month_this_year.start_date;
    --
    -- 会計カレンダに翌年度の会計期間が定義されていなかった場合
    IF (gd_start_date IS NULL) THEN
      -- 年度開始日を取得
      OPEN cur_get_month_last_year;
      FETCH cur_get_month_last_year INTO rec_get_month_last_year;
      CLOSE cur_get_month_last_year;
      -- パラメータ.年度開始日をセット
      gd_start_date := rec_get_month_last_year.start_date;
    END IF;
    --
    -------------------------------------------------
    -- 9.バラ単位取得
    -------------------------------------------------
    OPEN  bara_unit_cur;
    FETCH bara_unit_cur BULK COLLECT INTO g_bara_unit_tab;
    CLOSE bara_unit_cur;
    --
    -------------------------------------------------
    -- 10.登録外商品取得
    -------------------------------------------------
    OPEN  out_regist_item_cur;
    FETCH out_regist_item_cur BULK COLLECT INTO g_out_regist_item_tab;
    CLOSE out_regist_item_cur;
    --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 業務処理日付取得例外ハンドラ
    ----------------------------------------------------------
    WHEN get_date_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_csm
                     ,iv_name         => cv_msg_xxcsm10303
                    );
      -- エラーメッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_blank
      );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- 項目チェック用クイックコード取得例外ハンドラ
    ----------------------------------------------------------
    WHEN get_item_chk_lookup_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm    -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcsm10320         -- メッセージコード
                     , iv_token_name1  => cv_tkn_lookup_value_set   -- トークンコード1
                     , iv_token_value1 => cv_upload_item_chk_name   -- トークン値1
                    );
      -- エラーメッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_blank
      );
      ov_errmsg  := NULL;
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
      IF ( cur_get_month_this_year%ISOPEN ) THEN
        CLOSE cur_get_month_this_year;
      END IF;
      IF ( cur_get_month_last_year%ISOPEN ) THEN
        CLOSE cur_get_month_last_year;
      END IF;
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
    -- ローカルカーソル定義
    --===============================
    -- 新商品金額マイナスデータ取得
    CURSOR new_item_minus_cur
    IS
      SELECT  xipl.item_group_no
      FROM    xxcsm_item_plan_lines    xipl                      --『商品計画明細テーブル』
      WHERE   xipl.item_plan_header_id = gt_item_plan_header_id  -- 商品計画ヘッダID
      AND     xipl.item_kbn            = cv_item_kbn_new         -- 商品区分(2:新商品)
      AND    (xipl.sales_budget        < 0                       -- 売上または粗利益がマイナス
              OR xipl.amount_gross_margin < 0 )
      GROUP BY xipl.item_group_no
      ORDER BY xipl.item_group_no
    ;
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf                 VARCHAR2(5000);             -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);             -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000);             -- メッセージ
    lb_retcode                BOOLEAN;                    -- メッセージ戻り値
    --BLOB変換後データ退避(見出し、空白行排除後)
    lt_file_data              xxccp_common_pkg2.g_file_data_tbl;
    --===============================
    -- ローカル例外
    --===============================
    sub_proc_err_expt    EXCEPTION; -- 呼出しプログラムのエラー
  --
  BEGIN
  --
    --===============================================
    -- A-0.初期化
    --===============================================
    ov_retcode := cv_status_normal;
    --===============================================
    -- A-1.初期処理
    --===============================================
    init_proc(
      ov_errbuf  => lv_errbuf  -- エラー・メッセージ
     ,ov_retcode => lv_retcode -- リターン・コード
     ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
     ,iv_file_id => iv_file_id -- ファイルID
     ,iv_format  => iv_format  -- フォーマット
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-2.アップロードデータ取得
    --===============================================
    get_upload_line(
      ov_errbuf    => lv_errbuf     -- エラー・メッセージ
     ,ov_retcode   => lv_retcode    -- リターン・コード
     ,ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ
     ,iv_file_id   => iv_file_id    -- ファイルID
     ,ot_file_data => lt_file_data  -- BLOB変換後(見出し、空行無し)
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-3.アップロード項目チェック
    --===============================================
    chk_upload_item(
      ov_errbuf    => lv_errbuf     -- エラー・メッセージ
     ,ov_retcode   => lv_retcode    -- リターン・コード
     ,ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ
     ,it_file_data => lt_file_data  -- BLOB変換後
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    lt_file_data.DELETE;
    --
    --===============================================
    -- A-4.妥当性チェック処理
    --===============================================
    chk_validate_item(
      ov_errbuf    => lv_errbuf     -- エラー・メッセージ
     ,ov_retcode   => lv_retcode    -- リターン・コード
     ,ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-5.単品予算設定
    --===============================================
    set_item_bgt(
      ov_errbuf    => lv_errbuf     -- エラー・メッセージ
     ,ov_retcode   => lv_retcode    -- リターン・コード
     ,ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-7.新商品金額チェック(登録後チェック)
    --===============================================
    FOR new_item_minus_rec IN new_item_minus_cur LOOP
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm10323
                     ,iv_token_name1          => cv_tkn_deal_cd
                     ,iv_token_value1         => new_item_minus_rec.item_group_no
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      ov_retcode := cv_status_warn;
    END LOOP;
    --===============================================
    -- A-8.アップロードデータ削除
    --===============================================
    del_upload_data(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      ,ov_retcode => lv_retcode -- リターン・コード
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
      ,iv_file_id => iv_file_id -- ファイルID
    );
    --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- サブプログラム例外ハンドラ
    ----------------------------------------------------------
    WHEN sub_proc_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      ROLLBACK;
      --
      del_upload_data(
         ov_errbuf  => lv_errbuf  -- エラー・メッセージ
        ,ov_retcode => lv_retcode -- リターン・コード
        ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
        ,iv_file_id => iv_file_id -- ファイルID
      );
      COMMIT;
      --
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    --
    --===============================================
    -- サブメイン処理
    --===============================================
    submain(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      ,ov_retcode => lv_retcode -- リターン・コード
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      ,iv_file_id => iv_file_id -- ファイルID
      ,iv_format  => iv_format  -- フォーマット
    );
    --
    IF ( lv_retcode <> cv_status_error ) THEN
      gn_normal_cnt := gn_target_cnt;
    ELSE
      -- エラーメッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_blank
      );
      -- エラー時処理件数設定
      gn_normal_cnt := cn_0;  -- 正常件数
      gn_error_cnt  := cn_1;  -- エラー件数
    END IF;
    --
    --===============================================
    -- 終了処理
    --===============================================
    -------------------------------------------------
    -- 1.対象件数メッセージ出力
    -------------------------------------------------
    -- メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    -- メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -------------------------------------------------
    -- 3.エラー件数メッセージ出力
    -------------------------------------------------
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    -- メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    -------------------------------------------------
    -- 4.終了メッセージ出力
    -------------------------------------------------
    -- 終了メッセージ判断
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_nrmal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSE
      lv_message_code := cv_error_msg;
    END IF;
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => lv_message_code
                   );
    -- メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
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
END XXCSM002A18C;
/
