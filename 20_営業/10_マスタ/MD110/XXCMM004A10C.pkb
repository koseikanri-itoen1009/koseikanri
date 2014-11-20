CREATE OR REPLACE PACKAGE BODY XXCMM004A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A10C(body)
 * Description      : 品目一覧作成
 * MD.050           : 品目一覧作成 MD050_CMM_004_A10
 * Version          : Issue3.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              初期処理
 *  get_cmp_cost           標準原価取得
 *  get_item_mst           品目情報取得
 *  get_item_header        項目タイトル取得
 *  output_csv             CSV形式データ出力
 *  submain                処理の実行部
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.0   N.Nishimura      main新規作成
 *  2009/01/20    1.1   N.Nishimura      単体テストバグ修正
 *  2009/01/23    1.2   N.Nishimura      定数共通化
 *  2009/02/03    1.3   N.Nishimura      対象期間 現在設定値：検索対象日時に変更
 *                                                予約設定値：適用日に変更
 *                                       品目ステータスがNULLの場合も出力する
 *  2009/02/12    1.4   H.Yoshikawa      単体テストバグ修正
 *                                        1.経理容器群のLOOKUP_TYPE名を修正
 *                                        2.予約値取得カーソルのソートを修正
 *                                        3.対象期間(開始、終了)の未指定時のチェックを修正
 *                                          (どちらも指定されている場合のみ期間のチェックを実施する)
 *                                        4.現在値、予約値とも期間未指定時は全件取得するよう修正
 *                                        5.標準原価計の取得を修正
 *                                           ①対象期間(開始) ②業務日付（対象期間(開始)未指定時）
 *                                        6.親品目コード取得方法を修正
 *                                        7.Disc品目アドオンの数値項目「内容量」「内訳入数」桁数変更に伴う修正
 *  2009/02/17    1.5   R.Takigawa       単体テストバグ修正
 *                                        1.本社商品区分と商品製品区分の入れ替え
 *  2009/04/14    1.6   H.Yoshikawa      障害T1_0214対応  Disc品目アドオン「内容量」「内訳入数」桁数変更
 *  2009/05/26    1.7   H.Yoshikawa      障害T1_0317対応  品目コードの不要な範囲設定を削除
 *  2009/07/13    1.8   H.Yoshikawa      障害0000366対応  コンポーネント原価(01:01GEN～07:07KEI)を追加
 *  2009/08/12    1.9   Y.Kuboshima      障害0000894対応  日付項目の修正(SYSDATE -> 業務日付)
 *  2009/10/16    1.10  S.Niki           E_T4_00022対応   ケース換算入数を追加 
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  --パッケージ名
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCMM004A10C';
  --アプリケーション短縮名
  cv_app_name_xxcmm       CONSTANT VARCHAR2(5)   := 'XXCMM';
  --メッセージ
  cv_msg_xxcmm_00001      CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001'; -- 対象データ無し
  cv_msg_xxcmm_00019      CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019'; -- 対象期間指定エラー
  cv_msg_xxcmm_00473      CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00473'; -- 入力パラメータ
  cv_msg_xxcmm_00475      CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00475'; -- 品名コード指定エラー
  cv_msg_xxcmm_00485      CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00485'; -- データ抽出エラー
  --トークン
  cv_tkn_count            CONSTANT VARCHAR2(10)  := 'COUNT';
  cv_tkn_date_name        CONSTANT VARCHAR2(10)  := 'DATE_NAME';
  cv_tkn_item_code        CONSTANT VARCHAR2(10)  := 'ITEM_CODE';
  cv_tkn_name             CONSTANT VARCHAR2(10)  := 'NAME';
  cv_tkn_value            CONSTANT VARCHAR2(10)  := 'VALUE';
  --入力項目
  cv_inp_output_div       CONSTANT VARCHAR2(30)  := '出力対象設定値';     -- 出力対象設定値
  cv_inp_item_status      CONSTANT VARCHAR2(30)  := '出力対象ステータス'; -- 出力対象ステータス
  cv_inp_date_from        CONSTANT VARCHAR2(30)  := '対象期間開始';       -- 対象期間開始
  cv_inp_date_to          CONSTANT VARCHAR2(30)  := '対象期間終了';       -- 対象期間終了
  cv_inp_item_code_from   CONSTANT VARCHAR2(30)  := '品名コード開始';     -- 品名コード開始
  cv_inp_item_code_to     CONSTANT VARCHAR2(30)  := '品名コード終了';     -- 品名コード終了
  --ルックアップ
  cv_lookup_cost_cmpt     CONSTANT VARCHAR2(30)  := 'XXCMM1_COST_CMPT';          -- 標準原価
  cv_lookup_itm_status    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_STATUS';          -- 品目ステータス
  cv_lookup_sales_class   CONSTANT VARCHAR2(30)  := 'XXCMN_SALES_TARGET_CLASS';  -- 売上対象区分
  cv_lookup_rate_class    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_RATE_CLASS';      -- 率区分
  cv_lookup_nets_uom      CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_NET_UOM_CODE';    -- 内容量
  cv_lookup_baracha       CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_BARACHAKUBUN';    -- バラ茶区分
  cv_lookup_procuct_class CONSTANT VARCHAR2(30)  := 'XXCMN_D02';                 -- 商品分類
  cv_lookup_obso_class    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_HAISHI_KUBUN';    -- 廃止区分
  cv_lookup_vessel        CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_YOKIGUN';         -- 容器群
  cv_lookup_new_item      CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_SHINSYOHINKUBUN'; -- 新商品区分
  cv_lookup_acnt_grp      CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_KERIGUN';         -- 経理群
-- Ver1.4 2009/02/12  経理容器群のLOOKUP_TYPEを修正
--  cv_lookup_acnt_vessel   CONSTANT VARCHAR2(30)  := 'XXCMN_BOTTLE_CLASS';        -- 経理容器群
  cv_lookup_acnt_vessel   CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_KERIYOKIGUN';     -- 経理容器群
-- End
  cv_lookup_brand         CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_BRANDGUN';        -- ブランド群
  cv_lookup_supplier      CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_SENMONTEN_SHIIRESAKI'; -- 専門店仕入先
  cv_lookup_item_head     CONSTANT VARCHAR2(30)  := 'XXCMM1_004A10_ITEMLIST';       -- 本社商品区分
  -- 品目カテゴリセット名
  cv_categ_set_seisakugun CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_seisakugun;
                                                                                -- 政策群
  cv_categ_set_hon_prod   CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_hon_prod;
                                                                                -- 本社商品区分
  cv_categ_set_item_prod  CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_prod;
                                                                                -- 商品製品区分
  --共通化のためコメントアウト 2009/01/23
  --cv_seisakugun           CONSTANT VARCHAR2(20) := '政策群コード';              -- 政策群
  --cv_product_class        CONSTANT VARCHAR2(20) := '商品製品区分';              -- 商品製品区分
  --cv_hon_product_class    CONSTANT VARCHAR2(20) := '本社商品区分';              -- 本社商品区分
  --
  -- 定数
  cv_get_item             CONSTANT VARCHAR2(20)  := '品目情報';   -- 品目情報
  cv_cmpt_cost            CONSTANT VARCHAR2(20)  := '標準原価';   -- 標準原価
  cv_sep_com              CONSTANT VARCHAR2(1)   := ',';          -- CSV形式データ区切り文字
  cv_csv_file             CONSTANT VARCHAR2(1)   := '0';          -- CSVファイル
  cv_sep                  CONSTANT VARCHAR2(1)   := ':';          -- セパレータ
  cv_output_div           CONSTANT VARCHAR2(1)   := '1';          -- 出力対象設定値(現在設定値)
  cv_output_log           CONSTANT VARCHAR2(3)   := 'LOG';
  cv_date_fmt_std         CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_std;
                                                                  -- 日付書式
-- Ver1.8  2009/07/13  Add  0000364対応
  cv_cost_cmpnt_01gen     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_01gen;   -- 原料
  cv_cost_cmpnt_02sai     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_02sai;   -- 再製費
  cv_cost_cmpnt_03szi     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_03szi;   -- 資材費
  cv_cost_cmpnt_04hou     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_04hou;   -- 包装費
  cv_cost_cmpnt_05gai     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_05gai;   -- 外注加工費
  cv_cost_cmpnt_06hkn     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_06hkn;   -- 保管費
  cv_cost_cmpnt_07kei     CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_cost_cmpnt_07kei;   -- その他経費
  --
  cv_yes                  CONSTANT VARCHAR2(1)   := 'Y';          -- 'Y'
-- End1.8
  cv_no                   CONSTANT VARCHAR2(1)   := 'N';          -- 'N'
-- Ver1.6 2009/04/14  障害：T1_0214 内容量、内訳入数 桁数変更に伴う修正
---- Ver1.4 2009/02/13  7.Disc品目アドオンの数値項目「内容量」桁数変更に伴う修正
--  cv_number_fmt           CONSTANT VARCHAR2(5)   := '999D9';      -- NUMBER(4,1)
---- End1.4
  cv_number_fmt           CONSTANT VARCHAR2(6)   := '9999D9';     -- NUMBER(5,1)
-- End1.6
  --共通化のためコメントアウト 2009/01/23
  --cv_date_format          CONSTANT VARCHAR2(10) := 'YYYY/MM/DD'; -- 日付書式
  --
-- Ver1.7 2009/05/27  Del  不要なため削除
--  --デフォルト値
--  cv_item_code_from       CONSTANT VARCHAR2(20)  := '0000001';    -- 品名コード開始
--  cv_item_code_to         CONSTANT VARCHAR2(20)  := '3999999';    -- 品名コード終了
-- End1.7
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date    DATE;          -- 業務日付
  gv_output_div      VARCHAR2(1);   -- 出力対象設定値
  gn_item_status     NUMBER;        -- 品目ステータス
  gd_date_from       DATE;          -- 対象期間開始
  gd_date_to         DATE;          -- 対象期間終了
  gv_item_code_from  ic_item_mst_b.item_no%TYPE;  -- 品名コード開始
  gv_item_code_to    ic_item_mst_b.item_no%TYPE;  -- 品名コード終了
--
-- Ver1.8  2009/07/13  Add  0000364対応
  -- 標準原価取得用レコード型変数
  TYPE g_opmcost_rtype IS RECORD(
    cmpnt_cost1           NUMBER        -- 原料
   ,cmpnt_cost2           NUMBER        -- 再製費
   ,cmpnt_cost3           NUMBER        -- 資材費
   ,cmpnt_cost4           NUMBER        -- 包装費
   ,cmpnt_cost5           NUMBER        -- 外注加工費
   ,cmpnt_cost6           NUMBER        -- 保管費
   ,cmpnt_cost7           NUMBER        -- その他経費
   ,cmpnt_cost            NUMBER        -- 標準原価計
   ,start_date            DATE          -- 適用開始日
  );
-- End1.8
  --
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_output_div        IN  VARCHAR2,     -- 出力対象設定値
    iv_item_status       IN  VARCHAR2,     -- 品目ステータス
    iv_date_from         IN  VARCHAR2,     -- 対象期間開始
    iv_date_to           IN  VARCHAR2,     -- 対象期間終了
    iv_item_code_from    IN  VARCHAR2,     -- 品名コード開始
    iv_item_code_to      IN  VARCHAR2,     -- 品名コード終了
    ov_errbuf            OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- プログラム名
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
    lv_step       VARCHAR2(100);   -- ステップ
    lv_msg_token  VARCHAR2(100);   -- デバッグ用トークン
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    init_err_expt  EXCEPTION;
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
    -- ===============================
    -- 初期処理(A-1.1) 業務日付取得
    -- ===============================
    lv_step      := 'A-1.1';
    lv_msg_token := '業務日付取得';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => ''
    );
    -----------------------------------------
    -- 入力パラメータをグローバル変数に格納
    -----------------------------------------
    gv_output_div     := iv_output_div;
    gn_item_status    := TO_NUMBER( iv_item_status );
    gd_date_from      := FND_DATE.CANONICAL_TO_DATE( iv_date_from );
    gd_date_to        := FND_DATE.CANONICAL_TO_DATE( iv_date_to );
    gv_item_code_from := iv_item_code_from;
    gv_item_code_to   := iv_item_code_to;
    --
    ------------------------------------------
    -- 入力パラメータメッセージ出力、ログ出力
    ------------------------------------------
    lv_step      := 'A-1.1';
    lv_msg_token := '入力パラメータメッセージ出力';
    -- 出力対象設定値
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_output_div,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => gv_output_div
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    -- 出力対象ステータス
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_item_status,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => gn_item_status
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    -- 対象期間開始
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_date_from,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => TO_CHAR( gd_date_from, cv_date_fmt_std )
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    -- 対象期間終了
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_date_to,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => TO_CHAR( gd_date_to, cv_date_fmt_std )
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    -- 品名コード開始
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_item_code_from,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => gv_item_code_from
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    -- 品名コード終了
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name_xxcmm,
                   iv_name         => cv_msg_xxcmm_00473,
                   iv_token_name1  => cv_tkn_name,
                   iv_token_value1 => cv_inp_item_code_to,
                   iv_token_name2  => cv_tkn_value,
                   iv_token_value2 => gv_item_code_to
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errmsg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => ''
    );
    -- ========================================
    -- 初期処理(A-1.2) 入力項目の妥当性チェック
    -- ========================================
    -- 対象期間
    lv_step      := 'A-1.2';
    lv_msg_token := '対象期間チェック';
-- Ver1.4 2009/02/12  対象期間(開始、終了)の未指定時のチェックを修正
--    -- 対象期間（開始）がNULLなら業務日付をセット 2009/01/20追加
--    IF ( gd_date_from IS NULL ) THEN
--      gd_date_from := gd_process_date;
--    END IF;
--    -- 対象期間（終了）がNULLなら業務日付をセット 2009/01/20追加
--    IF ( gd_date_to IS NULL ) THEN
--      gd_date_to := gd_process_date;
--    END IF;
--    -- 対象期間（開始）と対象期間（終了）の比較
--    IF ( gd_date_from > gd_date_to ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--          iv_application  => cv_app_name_xxcmm,
--          iv_name         => cv_msg_xxcmm_00019
--      );
--      RAISE init_err_expt;
--    END IF;
    -- 開始、終了とも指定時にチェックする
    IF  ( gd_date_from IS NOT NULL )
    AND ( gd_date_to   IS NOT NULL ) THEN
      -- 対象期間（開始）と対象期間（終了）の比較
      IF ( gd_date_from > gd_date_to ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application  => cv_app_name_xxcmm,
            iv_name         => cv_msg_xxcmm_00019
        );
        RAISE init_err_expt;
      END IF;
    END IF;
-- End
    -- 品名コード
    lv_step      := 'A-1.2';
    lv_msg_token := '品名コードチェック';
-- Ver1.7 2009/05/27  Del  不要なため削除
--    -- 品名コード（開始）がNULLなら'0000001'をセット 2009/01/20追加
--    IF ( gv_item_code_from IS NULL ) THEN
--      gv_item_code_from := cv_item_code_from;
--    END IF;
--    -- 品名コード（終了）がNULLなら'3999999'をセット 2009/01/20追加
--    IF ( gv_item_code_to IS NULL ) THEN
--      gv_item_code_to := cv_item_code_to;
--    END IF;
-- End1.7
--
-- Ver1.7 2009/05/27  Mod  不要な品目コード範囲設定を削除に伴う修正
    -- 品名コード（開始）と品名コード（終了）の比較
    -- 開始、終了とも指定時にチェックする
--    IF ( gv_item_code_from > gv_item_code_to ) THEN
    IF  ( gv_item_code_from IS NOT NULL )
    AND ( gv_item_code_to   IS NOT NULL )
    AND ( gv_item_code_from > gv_item_code_to ) THEN
-- End1.7
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_app_name_xxcmm,
          iv_name         => cv_msg_xxcmm_00475
      );
      RAISE init_err_expt;
    END IF;
--
  EXCEPTION
    WHEN init_err_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step ||
                    cv_msg_part || lv_errmsg, 1, 5000 );
      --ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
      --              cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_init;
--
--
  /**********************************************************************************
   * Procedure Name   : get_cmp_cost
   * Description      : 標準原価取得(A-2.3, A-3.2)
   ***********************************************************************************/
  PROCEDURE get_cmp_cost(
    in_item_id     IN  NUMBER,           -- 品目ID
-- Ver1.8  2009/07/13  Mod  0000364対応
--    on_cmp_cost    OUT NUMBER,           -- 標準原価計
--    od_apply_date  OUT DATE,             -- 標準原価適用開始日
    o_opmcost_rec  OUT g_opmcost_rtype,  -- 標準原価レコード
-- End1.8
    ov_errbuf      OUT VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'get_cmp_cost'; -- プログラム名
-- Ver1.4 2009/02/12  標準原価計の取得を修正
    -- 標準原価
    cv_whse_code               CONSTANT VARCHAR2(3)   := xxcmm_004common_pkg.cv_whse_code;
                                                                               -- 倉庫
    cv_cost_mthd_code          CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_mthd_code;
                                                                               -- 原価方法
    cv_cost_analysis_code      CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_analysis_code;
                                                                               -- 分析コード
-- End
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- Ver1.8  2009/07/13  Add  0000364対応
    l_opmcost_rec     g_opmcost_rtype;  -- 標準原価レコード
-- End1.8
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step           VARCHAR2(100);    -- ステップ
    lv_msg_token      VARCHAR2(100);    -- デバッグ用トークン
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
-- Ver1.8 2009/07/13  Mod  0000366対応
---- Ver1.4 2009/02/12  標準原価計の取得を修正
----  対象期間(開始)指定時は、対象期間(開始)が期間に含まれるカレンダ、期間の標準原価を取得
----  対象期間(開始)未指定時は、業務日付が期間に含まれるカレンダ、期間の標準原価を取得
----    -- 標準原価と適用開始日を取得する
----    CURSOR      cnp_cost_cur
----    IS
----      SELECT    ccmd.cmpnt_cost,
----                ccld.start_date
----      FROM      cm_cmpt_dtl          ccmd,
----                cm_cldr_dtl          ccld,
----                cm_cmpt_mst_vl       ccmv,
----                fnd_lookup_values_vl flv
----      WHERE     ccmd.calendar_code       = ccld.calendar_code
----      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id
----      AND       ccmv.cost_cmpntcls_code  = flv.meaning
----      AND       ccmd.item_id             = in_item_id
----      AND       flv.lookup_type          = cv_lookup_cost_cmpt
----      ORDER BY  ccmv.cost_cmpntcls_code;
----  指定日がカレンダ期間に含まれる原価合計、開始日を取得
--    CURSOR      cnp_cost_cur
--    IS
--      SELECT    SUM( NVL( ccmd.cmpnt_cost, 0 ) )    -- 標準原価
--               ,cclr.start_date
--      FROM      cm_cmpt_dtl          ccmd           -- OPM標準原価
--               ,cm_cldr_dtl          cclr           -- OPM原価カレンダ
--               ,cm_cmpt_mst_vl       ccmv           -- 原価コンポーネント
--               ,fnd_lookup_values_vl flv            -- 参照コード値
--      WHERE     ccmd.item_id             = in_item_id                 -- 品目ID
--      AND       cclr.start_date         <= NVL( gd_date_from, gd_process_date )
--                                                                      -- 開始日
--      AND       cclr.end_date           >= NVL( gd_date_from, gd_process_date )
--                                                                      -- 終了日
--      AND       flv.lookup_type          = cv_lookup_cost_cmpt        -- 参照タイプ
--      AND       flv.enabled_flag         = cv_yes                     -- 使用可能
--      AND       ccmv.cost_cmpntcls_code  = flv.meaning                -- 原価コンポーネントコード
--      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id      -- 原価コンポーネントID
--      AND       ccmd.calendar_code       = cclr.calendar_code         -- カレンダコード
--      AND       ccmd.period_code         = cclr.period_code           -- 期間コード
--      AND       ccmd.whse_code           = cv_whse_code               -- 倉庫
--      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code          -- 原価方法
--      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code      -- 分析コード
--      GROUP BY  cclr.start_date;
---- End
    --
    CURSOR      cnp_cost_cur
    IS
      SELECT    DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_01gen, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_01gen, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                     cmpnt_cost1      -- 01GEN:原料
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_02sai, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_02sai, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                     cmpnt_cost2      -- 02SAI:再製費
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_03szi, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_03szi, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                      cmpnt_cost3     -- 03SZI:資材費
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_04hou, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_04hou, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                      cmpnt_cost4     -- 04HOU:包装費
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_05gai, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_05gai, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                      cmpnt_cost5     -- 05GAI:外注加工費
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_06hkn, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_06hkn, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                      cmpnt_cost6     -- 06HKN:保管費
               ,DECODE( MAX( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_07kei, cv_yes, cv_no ))
                       ,cv_yes, SUM( DECODE( ccmv.cost_cmpntcls_code, cv_cost_cmpnt_07kei, ccmd.cmpnt_cost, 0 ))
                       ,cv_no,  NULL )                                      cmpnt_cost7     -- 07KEI:その他経費
               ,SUM( ccmd.cmpnt_cost )                                      opm_cost_total  -- 標準原価計
               ,cclr.start_date
      FROM      cm_cmpt_dtl          ccmd           -- OPM標準原価
               ,cm_cldr_dtl          cclr           -- OPM原価カレンダ
               ,cm_cmpt_mst_vl       ccmv           -- 原価コンポーネント
               ,fnd_lookup_values_vl flv            -- 参照コード値
      WHERE     ccmd.item_id             = in_item_id                 -- 品目ID
      AND       cclr.start_date         <= NVL( gd_date_from, gd_process_date )
                                                                      -- 開始日
      AND       cclr.end_date           >= NVL( gd_date_from, gd_process_date )
                                                                      -- 終了日
      AND       flv.lookup_type          = cv_lookup_cost_cmpt        -- 参照タイプ
      AND       flv.enabled_flag         = cv_yes                     -- 使用可能
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                -- 原価コンポーネントコード
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id      -- 原価コンポーネントID
      AND       ccmd.calendar_code       = cclr.calendar_code         -- カレンダコード
      AND       ccmd.period_code         = cclr.period_code           -- 期間コード
      AND       ccmd.whse_code           = cv_whse_code               -- 倉庫
      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code          -- 原価方法
      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code      -- 分析コード
      GROUP BY  cclr.start_date;
-- End1.8
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
    -- 標準原価取得(A-2.4, A-3.2)
    -- ===============================
    -- 標準原価計格納変数初期化
    lv_step      := 'A-2.3, A-3.2';
    lv_msg_token := '標準原価取得';
-- Ver1.4 2009/02/12  標準原価計の取得を修正
--    on_cmp_cost := 0;
--    <<cnp_cost_loop>>
--    FOR lt_cost_rec IN cnp_cost_cur LOOP
--      on_cmp_cost   := on_cmp_cost + lt_cost_rec.cmpnt_cost;
--      od_apply_date := lt_cost_rec.start_date;
--    END LOOP cnp_cost_loop;
    --
    OPEN  cnp_cost_cur;
-- Ver1.8 2009/07/13  Mod  0000366対応
--    FETCH cnp_cost_cur INTO on_cmp_cost, od_apply_date;
    FETCH cnp_cost_cur INTO l_opmcost_rec;
-- End1.8
    CLOSE cnp_cost_cur;
-- End1.4
--
-- Ver1.8 2009/07/13  Add  0000366対応
    o_opmcost_rec := l_opmcost_rec;
-- End1.8
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_cmp_cost;
--
--
  /**********************************************************************************
   * Procedure Name   : get_item_mst
   * Description      : 品目一覧情報取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_item_mst(
    ov_errbuf            OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_mst'; -- プログラム名
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
    ln_cmp_cost      NUMBER;          -- 標準原価計
    ld_apply_date    DATE;            -- 標準原価適用開始日
    ln_cnt           NUMBER;          -- 件数用変数
    lv_step          VARCHAR2(100);   -- ステップ
    lv_msg_token     VARCHAR2(100);   -- デバッグ用トークン
    --
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 出力対象設定値：現在設定値
    CURSOR      item_csv_cur1
    IS
      SELECT    xoiv.item_id,                     --品目ID
                xoiv.item_code,                   --品名コード
                xoiv.item_name,                   --正式名
                xoiv.item_short_name,             --略称
                xoiv.item_name_alt,               --カナ名
                xoiv.item_status,                 --品目ステータス
                isn.item_status_name,             --品目ステータス名
                xoiv.sales_div,                   --売上対象区分
                sdn.sales_div_name,               --売上対象区分名
-- Ver1.4 2009/02/12  親品目コード取得方法を修正
--                p_itm.parent_item_code,           --親品目コード
                p_itm.item_no        AS parent_item_code,
                                                  --親品目コード
-- End
                xoiv.num_of_cases,                --ケース入数
-- 2009/10/16 Ver1.10 add start by Shigeto.Niki
                xoiv.case_conv_inc_num,           --ケース換算入数
-- 2009/10/16 Ver1.10 add end by Shigeto.Niki
                xoiv.item_um,                     --単位
                ipc.item_product_class,           --商品製品区分
                ipc.item_product_class_name,      --商品製品区分名
                xoiv.rate_class,                  --率区分
                rcn.rate_class_name,              --率区分名
                xoiv.net,                         --NET
                xoiv.unit,                        --重量
                xoiv.jan_code,                    --JANコード
                xoiv.nets,                        --内容量
                nuc.nets_uom_code_name,           --内容量単位
                xoiv.inc_num,                     --内訳入数
                xoiv.case_jan_code,               --ケースJANコード
                hpc.hon_product_class,            --本社商品区分
                hpc.hon_product_class_name,       --本社商品区分名
                xoiv.baracha_div,                 --バラ茶区分
                bdn.baracha_div_name,             --バラ茶区分名
                xoiv.itf_code,                    --ITFコード
                xoiv.product_class,               --商品分類
                pcn.product_class_name,           --商品分類名
                xoiv.palette_max_cs_qty,          --配数
                xoiv.palette_max_step_qty,        --パレット当り最大段数
                xoiv.bowl_inc_num,                --ボール入数
                xoiv.sell_start_date,             --発売（製造）開始日
                xoiv.obsolete_date,               --廃止日（製造中止日）
                xoiv.obsolete_class,              --廃止区分
                ocn.obsolete_class_name,          --廃止区分名
                xoiv.vessel_group,                --容器群
                vgn.vessel_group_name,            --容器群名
                xoiv.new_item_div,                --新商品区分
                nid.new_item_div_name,            --新商品区分名
                xoiv.acnt_group,                  --経理群
                agn.acnt_group_name,              --経理群名
                xoiv.acnt_vessel_group,           --経理容器群
                avg.acnt_vessel_group_name,       --経理容器群名
                xoiv.brand_group,                 --ブランド群
                bgn.brand_group_name,             --ブランド群名
                se.seisakugun,                    --政策群
                se.seisakugun_name,               --政策群名
                xoiv.price_old,                   --定価（旧）
                xoiv.price_new,                   --定価（新）
                xoiv.price_apply_date,            --定価適用開始日
                xoiv.opt_cost_old,                --営業原価（旧）
                xoiv.opt_cost_new,                --営業原価（新）
                xoiv.opt_cost_apply_date,         --営業原価適用開始日
                xoiv.renewal_item_code,           --リニューアル元商品コード
                xoiv.sp_supplier_code,            --専門店仕入先コード
                scn.ss_code_name                  --専門店仕入先
      FROM      xxcmm_opmmtl_items_v  xoiv,
-- Ver1.4 2009/02/12  親品目コード取得方法を修正
--              ( SELECT    chi_itm.item_id,
--                          o_itm.item_no          AS parent_item_code
--                FROM      ic_item_mst_b          chi_itm,
--                          xxcmn_item_mst_b       ximb,
--                          ic_item_mst_b          o_itm
--                WHERE     chi_itm.item_id = ximb.item_id
--                AND       ximb.parent_item_id    = o_itm.item_id
--                AND       ximb.start_date_active <= TRUNC( SYSDATE )
--                AND       ximb.end_date_active   >= TRUNC( SYSDATE )
--              ) p_itm,  --親品目コード
                ic_item_mst_b          p_itm,  --親品目コード
-- End
-- Ver1.4 2009/02/13  8.暗黙型変換が実施されないよう修正
--              ( SELECT    flvv_isn.lookup_code  AS item_status,
              ( SELECT    TO_NUMBER( flvv_isn.lookup_code ) AS item_status,
                          flvv_isn.meaning      AS item_status_name
                FROM      fnd_lookup_values_vl  flvv_isn
                WHERE     flvv_isn.lookup_type  = cv_lookup_itm_status
              ) isn,    --品目ステータス
              ( SELECT    flvv_sdn.lookup_code  AS sales_div,
                          flvv_sdn.meaning      AS sales_div_name
                FROM      fnd_lookup_values_vl  flvv_sdn
                WHERE     flvv_sdn.lookup_type  = cv_lookup_sales_class
              ) sdn,    --売上対象区分
              ( SELECT    flvv_rcn.lookup_code  AS rate_class,
                          flvv_rcn.meaning      AS rate_class_name
                FROM      fnd_lookup_values_vl  flvv_rcn
                WHERE     flvv_rcn.lookup_type  = cv_lookup_rate_class
              ) rcn,    --率区分
              ( SELECT    flvv_nuc.lookup_code  AS nets_uom_code,
                          flvv_nuc.meaning      AS nets_uom_code_name
                FROM      fnd_lookup_values_vl  flvv_nuc
                WHERE     flvv_nuc.lookup_type  = cv_lookup_nets_uom
              ) nuc,    --内容量単位
--              ( SELECT    flvv_bdn.lookup_code  AS baracha_div,
              ( SELECT    TO_NUMBER( flvv_bdn.lookup_code ) AS baracha_div,
                          flvv_bdn.meaning      AS baracha_div_name
                FROM      fnd_lookup_values_vl  flvv_bdn
                WHERE     flvv_bdn.lookup_type  = cv_lookup_baracha
              ) bdn,    --バラ茶区分
--              ( SELECT    flvv_pcn.lookup_code  AS product_class,
              ( SELECT    TO_NUMBER( flvv_pcn.lookup_code ) AS product_class,
                          flvv_pcn.meaning      AS product_class_name
                FROM      fnd_lookup_values_vl  flvv_pcn
                WHERE     flvv_pcn.lookup_type  = cv_lookup_procuct_class
              ) pcn,    --商品分類
              ( SELECT    flvv_ocn.lookup_code  AS obsolete_class,
                          flvv_ocn.meaning      AS obsolete_class_name
                FROM      fnd_lookup_values_vl  flvv_ocn
                WHERE     flvv_ocn.lookup_type  = cv_lookup_obso_class
              ) ocn,    --廃止区分
              ( SELECT    flvv_vgn.lookup_code  AS vessel_group,
                          flvv_vgn.meaning      AS vessel_group_name
                FROM      fnd_lookup_values_vl  flvv_vgn
                WHERE     flvv_vgn.lookup_type  = cv_lookup_vessel
              ) vgn,    --容器群
              ( SELECT    flvv_nid.lookup_code  AS new_item_div,
                          flvv_nid.meaning      AS new_item_div_name
                FROM      fnd_lookup_values_vl  flvv_nid
                WHERE     flvv_nid.lookup_type  = cv_lookup_new_item
              ) nid,    --新商品区分
              ( SELECT    flvv_agn.lookup_code  AS acnt_group,
                          flvv_agn.meaning      AS acnt_group_name
                FROM      fnd_lookup_values_vl  flvv_agn
                WHERE     flvv_agn.lookup_type  = cv_lookup_acnt_grp
              ) agn,    --経理群
              ( SELECT    flvv_avg.lookup_code  AS acnt_vessel_group,
                          flvv_avg.meaning      AS acnt_vessel_group_name
                FROM      fnd_lookup_values_vl  flvv_avg
                WHERE     flvv_avg.lookup_type  = cv_lookup_acnt_vessel
              ) avg,    --経理容器群
              ( SELECT    flvv_bgn.lookup_code  AS brand_group,
                          flvv_bgn.meaning      AS brand_group_name
                FROM      fnd_lookup_values_vl  flvv_bgn
                WHERE     flvv_bgn.lookup_type  = cv_lookup_brand
              ) bgn,    --ブランド群
              ( SELECT    flvv_scn.lookup_code  AS sp_supplier_code,
                          flvv_scn.description  AS ss_code_name
                          --meaningからdescriptionに変更 2009/01/20
                FROM      fnd_lookup_values_vl  flvv_scn
                WHERE     flvv_scn.lookup_type  = cv_lookup_supplier
              ) scn,    --専門店仕入先
              ( SELECT    gic_se.item_id             AS item_id,
                          mcv_se.segment1            AS seisakugun,
                          mcv_se.description         AS seisakugun_name
                FROM      gmi_item_categories        gic_se,
                          mtl_category_sets_vl       mcsv_se,
                          mtl_categories_vl          mcv_se
                WHERE     gic_se.category_set_id     = mcsv_se.category_set_id
                AND       gic_se.category_id         = mcv_se.category_id
                AND       mcsv_se.category_set_name  = cv_categ_set_seisakugun
              ) se,     --政策群
              ( SELECT    gic_ipc.item_id            AS item_id,
                          mcv_ipc.segment1           AS item_product_class,
                          mcv_ipc.description        AS item_product_class_name
                FROM      gmi_item_categories        gic_ipc,
                          mtl_category_sets_vl       mcsv_ipc,
                          mtl_categories_vl          mcv_ipc
                WHERE     gic_ipc.category_set_id    = mcsv_ipc.category_set_id
                AND       gic_ipc.category_id        = mcv_ipc.category_id
-- Ver1.5 2009/02/17  1.本社商品区分と商品製品区分の入れ替え
--                AND       mcsv_ipc.category_set_name = cv_categ_set_hon_prod
                AND       mcsv_ipc.category_set_name = cv_categ_set_item_prod
              ) ipc,  --商品製品区分
              ( SELECT    gic_hpc.item_id            AS item_id,
                          mcv_hpc.segment1           AS hon_product_class,
                          mcv_hpc.description        AS hon_product_class_name
                FROM      gmi_item_categories        gic_hpc,
                          mtl_category_sets_vl       mcsv_hpc,
                          mtl_categories_vl          mcv_hpc
                WHERE     gic_hpc.category_set_id    = mcsv_hpc.category_set_id
                AND       gic_hpc.category_id        = mcv_hpc.category_id
--                AND       mcsv_hpc.category_set_name = cv_categ_set_item_prod
                AND       mcsv_hpc.category_set_name = cv_categ_set_hon_prod
-- End1.5
              ) hpc    --本社商品区分
      WHERE     xoiv.parent_item_id     =  p_itm.item_id(+)             --親品目コード
      AND       xoiv.item_status        =  isn.item_status(+)           --品目ステータス
      AND       xoiv.sales_div          =  sdn.sales_div(+)             --売上対象区分
      AND       xoiv.rate_class         =  rcn.rate_class(+)            --率区分
      AND       xoiv.nets_uom_code      =  nuc.nets_uom_code(+)         --内容量単位
      AND       xoiv.baracha_div        =  bdn.baracha_div(+)           --バラ茶区分
      AND       xoiv.product_class      =  pcn.product_class(+)         --商品分類
      AND       xoiv.obsolete_class     =  ocn.obsolete_class(+)        --廃止区分
      AND       xoiv.vessel_group       =  vgn.vessel_group(+)          --容器群
      AND       xoiv.new_item_div       =  nid.new_item_div(+)          --新商品区分
      AND       xoiv.acnt_group         =  agn.acnt_group(+)            --経理群
      AND       xoiv.acnt_vessel_group  =  avg.acnt_vessel_group(+)     --経理容器群
      AND       xoiv.brand_group        =  bgn.brand_group(+)           --ブランド群
      AND       xoiv.sp_supplier_code   =  scn.sp_supplier_code(+)      --専門店仕入先
      AND       xoiv.item_id            =  se.item_id(+)                --政策群
      AND       xoiv.item_id            =  ipc.item_id(+)               --商品製品区分
      AND       xoiv.item_id            =  hpc.item_id(+)               --本社商品区分
-- 2009/08/12 Ver1.9 modify start by Y.Kuboshima
--      AND       xoiv.start_date_active  <= TRUNC( SYSDATE )
--      AND       xoiv.end_date_active    >= TRUNC( SYSDATE )
      AND       xoiv.start_date_active  <= gd_process_date
      AND       xoiv.end_date_active    >= gd_process_date
-- 2009/08/12 Ver1.9 modify end by Y.Kuboshima
-- Ver1.4 2009/02/12  期間未指定時は全件取得するよう修正
--      AND     ( TRUNC( xoiv.search_update_date ) >= gd_date_from        --検索対象日時に変更 2009/02/03
--      AND       TRUNC( xoiv.search_update_date ) <= gd_date_to )        --対象期間
      AND     ( (   gd_date_from IS NULL )
             OR (   gd_date_from IS NOT NULL
                AND TRUNC( xoiv.search_update_date ) >= gd_date_from ))
      AND     ( (   gd_date_to   IS NULL )
             OR (   gd_date_to   IS NOT NULL
                AND TRUNC( xoiv.search_update_date ) <= gd_date_to   ))
-- End
-- Ver1.7 2009/05/27  Mod  不要な品目コード範囲設定を削除に伴う修正
--      AND     ( xoiv.item_code   >= gv_item_code_from
--      AND       xoiv.item_code   <= gv_item_code_to )                   --品名コード
      AND     ( (   gv_item_code_from IS NULL )
             OR (   gv_item_code_from IS NOT NULL
                AND xoiv.item_code   >= gv_item_code_from ))
      AND     ( (   gv_item_code_to   IS NULL )
             OR (   gv_item_code_to   IS NOT NULL
                AND xoiv.item_code   <= gv_item_code_to   ))
-- End1.7
      AND   ( ( gn_item_status IS NULL )
      OR      ( gn_item_status IS NOT NULL AND xoiv.item_status = gn_item_status ) ) -- 品目ステータス
      ORDER BY  se.seisakugun,
                xoiv.item_code;
      --BETWEENをやめる 2009/01/20
--
    -- 出力対象設定値：予約設定値
    -- 抽出条件の品目ステータスはDisc品目変更履歴アドオンを見る 2009/01/20修正
    CURSOR      item_csv_cur2
    IS
      SELECT    xsibh.item_hst_id,                                      --品目変更履歴ID
                xsibh.item_id,                                          --品目ID
                xsibh.item_code,                                        --品目コード
                xoiv.item_name,                                         --正式名
                xsibh.apply_date,                                       --適用日（適用開始日）
                xsibh.item_status,                                      --品目ステータス
                isn.item_status_name,                                   --品目ステータス名
                xsibh.fixed_price,                                      --定価
                xsibh.discrete_cost,                                    --営業原価
                xsibh.policy_group,                                     --政策群コード
                se.policy_grp_name                                      --政策群名
      FROM      xxcmm_system_items_b_hst  xsibh,
                xxcmm_opmmtl_items_v      xoiv,
-- Ver1.4 2009/02/13  8.暗黙型変換が実施されないよう修正
--              ( SELECT    flvv_isn.lookup_code  AS item_status,
              ( SELECT    TO_NUMBER( flvv_isn.lookup_code ) AS item_status,
                          flvv_isn.meaning      AS item_status_name
                FROM      fnd_lookup_values_vl  flvv_isn
                WHERE     flvv_isn.lookup_type  = cv_lookup_itm_status
              ) isn,  --品目ステータス
              ( SELECT    xsibh.item_hst_id,
                          xsibh.policy_group,
                          mcv.description      policy_grp_name
                FROM      xxcmm_system_items_b_hst   xsibh,
                          mtl_categories_vl          mcv,
                          mtl_category_sets_vl       mcsv
                WHERE     xsibh.policy_group         = mcv.segment1
                AND       mcv.structure_id           = mcsv.structure_id
                AND       mcsv.category_set_name     = cv_categ_set_seisakugun
              ) se  --政策群コード
      WHERE     xsibh.item_code         = xoiv.item_code                        -- 品名コード
      AND       xsibh.item_status       = isn.item_status(+)                    -- 品目ステータス
      AND       xsibh.item_hst_id       = se.item_hst_id(+)                     -- 政策群
      AND       xsibh.apply_flag        = cv_no                                 -- 適用フラグ
-- 2009/08/12 Ver1.9 modify start by Y.Kuboshima
--      AND       xoiv.start_date_active  <= TRUNC( SYSDATE )
--      AND       xoiv.end_date_active    >= TRUNC( SYSDATE )
      AND       xoiv.start_date_active  <= gd_process_date
      AND       xoiv.end_date_active    >= gd_process_date
-- 2009/08/12 Ver1.9 modify end by Y.Kuboshima
-- Ver1.4 2009/02/12  期間未指定時は全件取得するよう修正
--      AND     ( TRUNC( xsibh.apply_date ) >= gd_date_from                       -- 適用日に変更 2009/02/03
--      AND       TRUNC( xsibh.apply_date ) <= gd_date_to )                       -- 対象期間
      AND     ( (   gd_date_from IS NULL )
             OR (   gd_date_from IS NOT NULL
                AND xsibh.apply_date >= gd_date_from ))
      AND     ( (   gd_date_to   IS NULL )
             OR (   gd_date_to   IS NOT NULL
                AND xsibh.apply_date <= gd_date_to   ))
-- End
-- Ver1.7 2009/05/27  Mod  不要な品目コード範囲設定を削除に伴う修正
--      AND     ( xoiv.item_code    >= gv_item_code_from
--      AND       xoiv.item_code    <= gv_item_code_to )                          -- 品名コード
      AND     ( (   gv_item_code_from IS NULL )
             OR (   gv_item_code_from IS NOT NULL
                AND xoiv.item_code   >= gv_item_code_from ))
      AND     ( (   gv_item_code_to   IS NULL )
             OR (   gv_item_code_to   IS NOT NULL
                AND xoiv.item_code   <= gv_item_code_to   ))
-- End1.7
      AND   ( ( gn_item_status IS NULL )
      OR      ( gn_item_status IS NOT NULL AND xsibh.item_status = gn_item_status ) ) -- 品目ステータス
-- Ver1.4 2009/02/12  ソートを修正
--   ・ 同一品目で適用日がばらばらに出力されるので修正
--   ・ 品目順に並ばなくなるのはありえんので、政策群順にソートするのはとりあえず削除
--      ※政策群をソートに加えるのであれば、設定されている値でソートすること。
--      ORDER BY  xsibh.policy_group,
--                xoiv.item_code;
      ORDER BY  xoiv.item_code,
                xsibh.apply_date;
-- End
      --BETWEENをやめる 2009/01/20
--
-- Ver1.8  2009/07/13  Add  0000364対応
    l_opmcost_rec    g_opmcost_rtype;  -- 標準原価レコード
-- End1.8
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    no_data_expt     EXCEPTION;
    select_err_expt  EXCEPTION;
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カウント用変数初期化
    lv_step := 'A-2.1';
    ln_cnt := 0;
    IF ( gv_output_div = cv_output_div ) THEN
      <<item_csv_cur1_loop>>
      -- ===============================
      -- 品目一覧情報取得(A-2.1)
      -- ===============================
      FOR lt_item01_rec IN item_csv_cur1 LOOP
        -- =======================
        -- 標準原価取得(A-2.4)
        -- =======================
        lv_step      := 'A-2.4';
        lv_msg_token := '標準原価取得';
        get_cmp_cost(
          in_item_id     => lt_item01_rec.item_id,    -- IN  品目ID
-- Ver1.8  2009/07/13  Mod  0000364対応
--          on_cmp_cost    => ln_cmp_cost,              -- OUT 標準原価計
--          od_apply_date  => ld_apply_date,            -- OUT 標準原価適用開始日
          o_opmcost_rec  => l_opmcost_rec,            -- OUT 標準原価レコード
-- End1.8
          ov_errbuf      => lv_errbuf,                -- OUT エラー・メッセージ           --# 固定 #
          ov_retcode     => lv_retcode,               -- OUT リターン・コード             --# 固定 #
          ov_errmsg      => lv_errmsg                 -- OUT ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name_xxcmm,
                          iv_name         => cv_msg_xxcmm_00485,
                          iv_token_name1  => cv_tkn_date_name,
                          iv_token_value1 => cv_cmpt_cost,
                          iv_token_name2  => cv_tkn_item_code,
                          iv_token_value2 => lt_item01_rec.item_code
                        );
          RAISE select_err_expt;
        END IF;
        --
        ln_cnt := ln_cnt + 1;    -- 件数
        --
        -- ワークテーブルにデータをinsert
        INSERT INTO xxcmm_wk_item_csv(
          item_id,                      -- 品目ID
          item_code,                    -- 品名コード
          item_name,                    -- 正式名
          item_short_name,              -- 略称
          item_name_alt,                -- カナ名
          item_status,                  -- 品目ステータス
          item_status_name,             -- 品目ステータス名
          sales_div,                    -- 売上対象区分
          sales_div_name,               -- 売上対象区分名
          parent_item_code,             -- 親品目コード
          num_of_cases,                 -- ケース入数
-- 2009/10/16 Ver1.10 add start by Shigeto.Niki
          case_conv_inc_num,            -- ケース換算入数
-- 2009/10/16 Ver1.10 add end by Shigeto.Niki
          item_um,                      -- 単位
          item_product_class,           -- 商品製品区分
          item_product_class_name,      -- 商品製品区分名
          rate_class,                   -- 率区分
          rate_class_name,              -- 率区分名
          net,                          -- NET
          unit,                         -- 重量
          jan_code,                     -- JANコード
          nets,                         -- 内容量
          nets_uom_code_name,           -- 内容量単位
          inc_num,                      -- 内訳入数
          case_jan_code,                -- ケースJANコード
          hon_product_class,            -- 本社商品区分
          hon_product_class_name,       -- 本社商品区分名
          baracha_div,                  -- バラ茶区分
          baracha_div_name,             -- バラ茶区分名
          itf_code,                     -- ITFコード
          product_class,                -- 商品分類
          product_class_name,           -- 商品分類名
          palette_max_cs_qty,           -- 配数
          palette_max_step_qty,         -- パレット当り最大段数
          bowl_inc_num,                 -- ボール入数
          sell_start_date,              -- 発売(製造)開始日
          obsolete_date,                -- 廃止日(製造中止日)
          obsolete_class,               -- 廃止区分
          obsolete_class_name,          -- 廃止区分名
          vessel_group,                 -- 容器群
          vessel_group_name,            -- 容器群名
          new_item_div,                 -- 新商品区分
          new_item_div_name,            -- 新商品区分名
          acnt_group,                   -- 経理群
          acnt_group_name,              -- 経理群名
          acnt_vessel_group,            -- 経理容器群
          acnt_vessel_group_name,       -- 経理容器群名
          brand_group,                  -- ブランド群
          brand_group_name,             -- ブランド群名
          seisakugun,                   -- 政策群
          seisakugun_name,              -- 政策群名
          price_old,                    -- 定価(旧)
          price_new,                    -- 定価(新)
          price_apply_date,             -- 定価適用開始日
          opt_cost_old,                 -- 営業原価(旧)
          opt_cost_new,                 -- 営業原価(新)
          opt_cost_apply_date,          -- 営業原価適用開始日
          cmpnt_cost,                   -- 標準原価計
-- Ver1.8  2009/07/13  Add  0000366対応
          cmpnt_01gen,                  -- 標準原価（原料）
          cmpnt_02sai,                  -- 標準原価（再製費）
          cmpnt_03szi,                  -- 標準原価（資材費）
          cmpnt_04hou,                  -- 標準原価（包装費）
          cmpnt_05gai,                  -- 標準原価（外注加工費）
          cmpnt_06hkn,                  -- 標準原価（保管費）
          cmpnt_07kei,                  -- 標準原価（その他経費）
-- End1.8
          cmp_cost_apply_date,          -- 標準原価適用開始日
          renewal_item_code,            -- リニューアル商品元コード
          sp_supplier_code,             -- 専門店仕入先コード
          ss_code_name,                 -- 専門店仕入先
          created_by,                   -- CREATED_BY
          creation_date,                -- CREATION_DATE
          last_updated_by,              -- LAST_UPDATED_BY
          last_update_date,             -- LAST_UPDATE_DATE
          last_update_login,            -- LAST_UPDATE_LOGIN
          request_id,                   -- REQUEST_ID
          program_application_id,       -- PROGRAM_APPLICATION_ID
          program_id,                   -- PROGRAM_ID
          program_update_date           -- PROGRAM_UPDATE_DATE
        ) VALUES (
          lt_item01_rec.item_id,                  -- 品目ID
          lt_item01_rec.item_code,                -- 品名コード
          lt_item01_rec.item_name,                -- 正式名
          lt_item01_rec.item_short_name,          -- 略称
          lt_item01_rec.item_name_alt,            -- カナ名
          lt_item01_rec.item_status,              -- 品目ステータス
          lt_item01_rec.item_status_name,         -- 品目ステータス名
          lt_item01_rec.sales_div,                -- 売上対象区分
          lt_item01_rec.sales_div_name,           -- 売上対象区分名
          lt_item01_rec.parent_item_code,         -- 親品目ID
          lt_item01_rec.num_of_cases,             -- ケース入数
-- 2009/10/16 Ver1.10 add start by Shigeto.Niki
          lt_item01_rec.case_conv_inc_num,        -- ケース換算入数
-- 2009/10/16 Ver1.10 add end by Shigeto.Niki
          lt_item01_rec.item_um,                  -- 単位
          lt_item01_rec.item_product_class,       -- 商品製品区分
          lt_item01_rec.item_product_class_name,  -- 商品製品区分名
          lt_item01_rec.rate_class,               -- 率区分
          lt_item01_rec.rate_class_name,          -- 率区分名
          lt_item01_rec.net,                      -- NET
          lt_item01_rec.unit,                     -- 重量
          lt_item01_rec.jan_code,                 -- JANコード
          lt_item01_rec.nets,                     -- 内容量
          lt_item01_rec.nets_uom_code_name,       -- 内容量単位
          lt_item01_rec.inc_num,                  -- 内訳入数
          lt_item01_rec.case_jan_code,            -- ケースJANコード
          lt_item01_rec.hon_product_class,        -- 本社商品区分
          lt_item01_rec.hon_product_class_name,   -- 本社商品区分名
          lt_item01_rec.baracha_div,              -- バラ茶区分
          lt_item01_rec.baracha_div_name,         -- バラ茶区分名
          lt_item01_rec.itf_code,                 -- ITFコード
          lt_item01_rec.product_class,            -- 商品分類
          lt_item01_rec.product_class_name,       -- 商品分類名
          lt_item01_rec.palette_max_cs_qty,       -- 配数
          lt_item01_rec.palette_max_step_qty,     -- パレット当り最大段数
          lt_item01_rec.bowl_inc_num,             -- ボール入数
          lt_item01_rec.sell_start_date,          -- 発売(製造)開始日
          lt_item01_rec.obsolete_date,            -- 廃止日(製造中止日)
          lt_item01_rec.obsolete_class,           -- 廃止区分
          lt_item01_rec.obsolete_class_name,      -- 廃止区分名
          lt_item01_rec.vessel_group,             -- 容器群
          lt_item01_rec.vessel_group_name,        -- 容器群名
          lt_item01_rec.new_item_div,             -- 新商品区分
          lt_item01_rec.new_item_div_name,        -- 新商品区分名
          lt_item01_rec.acnt_group,               -- 経理群
          lt_item01_rec.acnt_group_name,          -- 経理群名
          lt_item01_rec.acnt_vessel_group,        -- 経理容器群
          lt_item01_rec.acnt_vessel_group_name,   -- 経理容器群名
          lt_item01_rec.brand_group,              -- ブランド群
          lt_item01_rec.brand_group_name,         -- ブランド群名
          lt_item01_rec.seisakugun,               -- 政策群
          lt_item01_rec.seisakugun_name,          -- 政策群名
          lt_item01_rec.price_old,                -- 定価(旧)
          lt_item01_rec.price_new,                -- 定価(新)
          lt_item01_rec.price_apply_date,         -- 定価適用開始日
          lt_item01_rec.opt_cost_old,             -- 営業原価(旧)
          lt_item01_rec.opt_cost_new,             -- 営業原価(新)
          lt_item01_rec.opt_cost_apply_date,      -- 営業原価適用開始日
-- Ver1.8  2009/07/13  Mod  0000364対応
--          ln_cmp_cost,                            -- 標準原価計
--          ld_apply_date,                          -- 標準原価適用開始日
          l_opmcost_rec.cmpnt_cost,               -- 標準原価計
          l_opmcost_rec.cmpnt_cost1,              -- 原料
          l_opmcost_rec.cmpnt_cost2,              -- 再製費
          l_opmcost_rec.cmpnt_cost3,              -- 資材費
          l_opmcost_rec.cmpnt_cost4,              -- 包装費
          l_opmcost_rec.cmpnt_cost5,              -- 外注加工費
          l_opmcost_rec.cmpnt_cost6,              -- 保管費
          l_opmcost_rec.cmpnt_cost7,              -- その他経費
          l_opmcost_rec.start_date,               -- 標準原価適用開始日
-- End1.8
          lt_item01_rec.renewal_item_code,        -- リニューアル商品元コード
          lt_item01_rec.sp_supplier_code,         -- 専門店仕入先コード
          lt_item01_rec.ss_code_name,             -- 専門店仕入先
          cn_created_by,                          -- CREATED_BY
          cd_creation_date,                       -- CREATION_DATE
          cn_last_updated_by,                     -- LAST_UPDATED_BY
          cd_last_update_date,                    -- LAST_UPDATE_DATE
          cn_last_update_login,                   -- LAST_UPDATE_LOGIN
          cn_request_id,                          -- REQUEST_ID
          cn_program_application_id,              -- PROGRAM_APPLICATION_ID
          cn_program_id,                          -- PROGRAM_ID
          cd_program_update_date                  -- PROGRAM_UPDATE_DATE
        );
        -- エラー発生時までの件数を表示するためループ中に件数をセットする 2009/01/20修正
        -- 件数のカウント数をメッセージ用の変数に代入
        gn_target_cnt := ln_cnt;
      END LOOP item_csv_cur1_loop;
    ELSE
      -- ===============================
      -- 品目一覧情報取得(A-3.1)
      -- ===============================
      <<item_csv_cur2_loop>>
      FOR lt_item01_rec IN item_csv_cur2 LOOP
        -- =======================
        -- 標準原価取得(A-3.2)
        -- =======================
        lv_step      := 'A-3.2';
        lv_msg_token := '標準原価取得';
        get_cmp_cost(
          in_item_id     => lt_item01_rec.item_id,    -- IN  品目ID
-- Ver1.8  2009/07/13  Mod  0000364対応
--          on_cmp_cost    => ln_cmp_cost,              -- OUT 標準原価計
--          od_apply_date  => ld_apply_date,            -- OUT 標準原価適用開始日
          o_opmcost_rec  => l_opmcost_rec,            -- OUT 標準原価レコード
-- End1.8
          ov_errbuf      => lv_errbuf,                -- OUT エラー・メッセージ           --# 固定 #
          ov_retcode     => lv_retcode,               -- OUT リターン・コード             --# 固定 #
          ov_errmsg      => lv_errmsg                 -- OUT ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name_xxcmm,
                          iv_name         => cv_msg_xxcmm_00485,
                          iv_token_name1  => cv_tkn_date_name,
                          iv_token_value1 => cv_cmpt_cost,
                          iv_token_name2  => cv_tkn_item_code,
                          iv_token_value2 => lt_item01_rec.item_code
                        );
          RAISE select_err_expt;
        END IF;
        --
        ln_cnt := ln_cnt + 1;    -- 件数
        --
        -- ワークテーブルにデータをinsert
        INSERT INTO xxcmm_wk_itemrsv_csv(
          item_id,                 -- 品目ID
          item_code,               -- 品名コード
          item_name,               -- 正式名
          apply_date,              -- 適用開始日
          item_status,             -- 品目ステータス
          item_status_name,        -- 品目ステータス名
          fixed_price,             -- 定価
          cmpnt_cost,              -- 標準原価計
-- Ver1.8  2009/07/13  Add  0000366対応
          cmpnt_01gen,             -- 標準原価（原料）
          cmpnt_02sai,             -- 標準原価（再製費）
          cmpnt_03szi,             -- 標準原価（資材費）
          cmpnt_04hou,             -- 標準原価（包装費）
          cmpnt_05gai,             -- 標準原価（外注加工費）
          cmpnt_06hkn,             -- 標準原価（保管費）
          cmpnt_07kei,             -- 標準原価（その他経費）
-- End1.8
          cmp_cost_apply_date,     -- 標準原価適用開始日
          discrete_cost,           -- 営業原価
          policy_group,            -- 政策群
          policy_grp_name,         -- 政策群名
          created_by,              -- CREATED_BY
          creation_date,           -- CREATION_DATE
          last_updated_by,         -- LAST_UPDATED_BY
          last_update_date,        -- LAST_UPDATE_DATE
          last_update_login,       -- LAST_UPDATE_LOGIN
          request_id,              -- REQUEST_ID
          program_application_id,  -- PROGRAM_APPLICATION_ID
          program_id,              -- PROGRAM_ID
          program_update_date      -- PROGRAM_UPDATE_DATE
        ) VALUES (
          lt_item01_rec.item_id,           -- 品目ID
          lt_item01_rec.item_code,         -- 品名コード
          lt_item01_rec.item_name,         -- 正式名
          lt_item01_rec.apply_date,        -- 適用開始日
          lt_item01_rec.item_status,       -- 品目ステータス
          lt_item01_rec.item_status_name,  -- 品目ステータス名
          lt_item01_rec.fixed_price,       -- 定価
-- Ver1.8  2009/07/13  Mod  0000364対応
--          ln_cmp_cost,                     -- 標準原価計
--          ld_apply_date,                   -- 標準原価適用開始日
          l_opmcost_rec.cmpnt_cost,        -- 標準原価計
          l_opmcost_rec.cmpnt_cost1,       -- 原料
          l_opmcost_rec.cmpnt_cost2,       -- 再製費
          l_opmcost_rec.cmpnt_cost3,       -- 資材費
          l_opmcost_rec.cmpnt_cost4,       -- 包装費
          l_opmcost_rec.cmpnt_cost5,       -- 外注加工費
          l_opmcost_rec.cmpnt_cost6,       -- 保管費
          l_opmcost_rec.cmpnt_cost7,       -- その他経費
          l_opmcost_rec.start_date,        -- 標準原価適用開始日
-- End1.8
          lt_item01_rec.discrete_cost,     -- 営業原価
          lt_item01_rec.policy_group,      -- 政策群
          lt_item01_rec.policy_grp_name,   -- 政策群名
          cn_created_by,                   -- CREATED_BY
          cd_creation_date,                -- CREATION_DATE
          cn_last_updated_by,              -- LAST_UPDATED_BY
          cd_last_update_date,             -- LAST_UPDATE_DATE
          cn_last_update_login,            -- LAST_UPDATE_LOGIN
          cn_request_id,                   -- REQUEST_ID
          cn_program_application_id,       -- PROGRAM_APPLICATION_ID
          cn_program_id,                   -- PROGRAM_ID
          cd_program_update_date           -- PROGRAM_UPDATE_DATE
        );
        -- エラー発生時までの件数を表示するためループ中に件数をセットする 2009/01/20修正
        -- 件数のカウント数をメッセージ用の変数に代入
        gn_target_cnt := ln_cnt;
      END LOOP item_csv_cur2_loop;
    END IF;
    -- カウント用変数が'0'の時、データなし
    IF ( ln_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
    --
--
  EXCEPTION
    -- リターンコード：エラーを外して正常終了するように修正 2009/01/20
    WHEN no_data_expt THEN  --対象データ無し
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm,
                      iv_name         => cv_msg_xxcmm_00001
                    );
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step ||
                    cv_msg_part || lv_errmsg, 1, 5000 );
      --ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
      --              cv_msg_part||SQLERRM;
    WHEN select_err_expt THEN
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step ||
                    cv_msg_part || lv_errmsg, 1, 5000 );
      --ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
      --              cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_item_mst;
--
--
  /**********************************************************************************
   * Procedure Name   : get_item_header
   * Description      : 項目タイトル取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_item_header(
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- リターン・コード                    --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_header'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_csv_file     VARCHAR2(5000);  -- 出力情報
    ln_cnt          NUMBER;
    lv_step         VARCHAR2(100);   -- ステップ
    lv_msg_token    VARCHAR2(100);   -- デバッグ用トークン
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR      lookup_itemlist_cur
    IS
      SELECT    flv.lookup_code,
                flv.description
      FROM      fnd_lookup_values_vl flv
      WHERE     flv.lookup_type = cv_lookup_item_head
      AND       flv.attribute1  = gv_output_div
      ORDER BY  flv.lookup_code;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    no_data_expt  EXCEPTION;
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
    -- 項目タイトル取得(A-4)
    -- ===============================
    lv_step      := 'A-4';
    lv_msg_token := '項目タイトル取得';
    -- 変数初期化
    lv_csv_file := NULL;
    ln_cnt      := 0;
    -- ルックアップから項目タイトルを取得しCSV形式にする
    <<head_info_loop>>
    FOR lt_head_info_rec IN lookup_itemlist_cur LOOP
      ln_cnt := ln_cnt + 1;
      lv_csv_file := lv_csv_file || lt_head_info_rec.description || cv_sep_com;
    END LOOP head_info_loop;
    --
    -- カウント変数が'0'の時、データなし
    IF ( ln_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
    --
    lv_csv_file := SUBSTRB(lv_csv_file, 1, LENGTHB(lv_csv_file) - 1);
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_file
    );
--
  EXCEPTION
    -- リターンコード：エラーを外して正常終了するように修正 2009/01/20
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm,
                      iv_name         => cv_msg_xxcmm_00001
                    );
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step ||
                    cv_msg_part || lv_errmsg, 1, 5000 );
      --ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
      --              cv_msg_part||SQLERRM;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_item_header;
--
--
  /**********************************************************************************
   * Procedure Name   : output_csv（ループ部）
   * Description      : CSVファイル出力(A-5)
   ***********************************************************************************/
  PROCEDURE output_csv(
    iv_file_type  IN  VARCHAR2,            -- ファイル種別
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード                    --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_csv_file     VARCHAR2(5000);  -- 出力情報
    ln_c            NUMBER;
    lv_step         VARCHAR2(100);   -- ステップ
    lv_msg_token    VARCHAR2(100);   -- デバッグ用トークン
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- データ取得(現在設定値)
    CURSOR      csv_data_cur1
    IS
      SELECT    xicw.item_code,                -- 品名コード
                xicw.item_name,                -- 正式名
                xicw.item_short_name,          -- 略称
                xicw.item_name_alt,            -- カナ名
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
--                xicw.item_status,
                TO_CHAR( xicw.item_status )    AS item_status,
                                               -- 品目ステータス
-- End
                xicw.item_status_name,         -- 品目ステータス名
                xicw.sales_div,                -- 売上対象区分
                xicw.sales_div_name,           -- 売上対象区分名
                xicw.parent_item_code,         -- 親品目コード
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
--                xicw.num_of_cases,
                TO_CHAR( xicw.num_of_cases )   AS num_of_cases,
                                               -- ケース入数
-- End
-- 2009/10/16 Ver1.10 add start by Shigeto.Niki
                TO_CHAR( xicw.case_conv_inc_num )   AS case_conv_inc_num,
                                               -- ケース換算入数
-- 2009/10/16 Ver1.10 add end by Shigeto.Niki
                xicw.item_um,                  -- 単位
                xicw.item_product_class,       -- 商品製品区分
                xicw.item_product_class_name,  -- 商品製品区分名
                xicw.rate_class,               -- 率区分
                xicw.rate_class_name,          -- 率区分名
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
--                xicw.net,
--                xicw.unit,
                TO_CHAR( xicw.net )            AS net,
                                               -- NET
                TO_CHAR( xicw.unit )           AS unit,
                                               -- 重量
-- End
                xicw.jan_code,                 -- JANコード
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
--                xicw.nets,
-- Ver1.4 2009/02/13  7.Disc品目アドオンの数値項目「内容量」桁数変更に伴う修正
--                TO_CHAR( xicw.nets )           AS nets,
                TRIM ( TO_CHAR( xicw.nets , cv_number_fmt) )           AS nets,
                                               -- 内容量
-- End1.4
                xicw.nets_uom_code_name,       -- 内容量単位
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
--                xicw.inc_num,
-- Ver1.4 2009/02/13  7.Disc品目アドオンの数値項目「内訳入数」桁数変更に伴う修正
--                TO_CHAR( xicw.inc_num )        AS inc_num,
                TRIM ( TO_CHAR( xicw.inc_num , cv_number_fmt ) )        AS inc_num,
                                               -- 内訳入数
-- End1.4
                xicw.case_jan_code,            -- ケースJANコード
                xicw.hon_product_class,        -- 本社商品区分
                xicw.hon_product_class_name,   -- 本社商品区分名
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
--                xicw.baracha_div,
                TO_CHAR( xicw.baracha_div )    AS baracha_div,
                                               -- バラ茶区分
-- End
                xicw.baracha_div_name,         -- バラ茶区分名
                xicw.itf_code,                 -- ITFコード
                xicw.product_class,            -- 商品分類
                xicw.product_class_name,       -- 商品分類名
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
--                xicw.palette_max_cs_qty,
--                xicw.palette_max_step_qty,
--                xicw.bowl_inc_num,
                TO_CHAR( xicw.palette_max_cs_qty )    AS palette_max_cs_qty,
                                               -- 配数
                TO_CHAR( xicw.palette_max_step_qty )  AS palette_max_step_qty,
                                               -- パレット当り最大段数
                TO_CHAR( xicw.bowl_inc_num )   AS bowl_inc_num,
                                               -- ボール入数
-- End
                xicw.sell_start_date,          -- 発売(製造)開始日
                xicw.obsolete_date,            -- 廃止日(製造中止日)
                xicw.obsolete_class,           -- 廃止区分
                xicw.obsolete_class_name,      -- 廃止区分名
                xicw.vessel_group,             -- 容器群
                xicw.vessel_group_name,        -- 容器群名
                xicw.new_item_div,             -- 新商品区分
                xicw.new_item_div_name,        -- 新商品区分名
                xicw.acnt_group,               -- 経理群
                xicw.acnt_group_name,          -- 経理群名
                xicw.acnt_vessel_group,        -- 経理容器群
                xicw.acnt_vessel_group_name,   -- 経理容器群名
                xicw.brand_group,              -- ブランド群
                xicw.brand_group_name,         -- ブランド群名
                xicw.renewal_item_code,        -- リニューアル商品元コード
                xicw.sp_supplier_code,         -- 専門店仕入先コード
                xicw.ss_code_name,             -- 専門店仕入先
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
                TO_CHAR( xicw.price_old )      AS price_old,
                                               -- 定価(旧)
                TO_CHAR( xicw.price_new )      AS price_new,
                                               -- 定価(新)
-- End
                xicw.price_apply_date,         -- 定価適用開始日
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
                TO_CHAR( xicw.opt_cost_old )   AS opt_cost_old,
                                               -- 営業原価(旧)
                TO_CHAR( xicw.opt_cost_new )   AS opt_cost_new,
                                               -- 営業原価(新)
-- End
                xicw.opt_cost_apply_date,      -- 営業原価適用開始日
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
                TO_CHAR( xicw.cmpnt_cost )     AS cmpnt_cost,
                                               -- 標準原価計
-- End
-- Ver1.8  2009/07/13  Add  0000366対応
                TO_CHAR( xicw.cmpnt_01gen )    AS cmpnt_01gen,
                                               -- 標準原価（原料）
                TO_CHAR( xicw.cmpnt_02sai )    AS cmpnt_02sai,
                                               -- 標準原価（再製費）
                TO_CHAR( xicw.cmpnt_03szi )    AS cmpnt_03szi,
                                               -- 標準原価（資材費）
                TO_CHAR( xicw.cmpnt_04hou )    AS cmpnt_04hou,
                                               -- 標準原価（包装費）
                TO_CHAR( xicw.cmpnt_05gai )    AS cmpnt_05gai,
                                               -- 標準原価（外注加工費）
                TO_CHAR( xicw.cmpnt_06hkn )    AS cmpnt_06hkn,
                                               -- 標準原価（保管費）
                TO_CHAR( xicw.cmpnt_07kei )    AS cmpnt_07kei,
                                               -- 標準原価（その他経費）
-- End1.8
                xicw.cmp_cost_apply_date,      -- 標準原価適用開始日
                xicw.seisakugun,               -- 政策群
                xicw.seisakugun_name           -- 政策群名
      FROM      xxcmm_wk_item_csv xicw
      WHERE     xicw.request_id = cn_request_id
      ORDER BY  xicw.seisakugun,
                xicw.item_code;
--
    -- データ取得(予約設定値)
    CURSOR      csv_data_cur2
    IS
      SELECT    xicw.item_code,                -- 品名コード
                xicw.item_name,                -- 正式名
                xicw.apply_date,               -- 適用開始日
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
--                xicw.item_status,
                TO_CHAR( xicw.item_status )    AS item_status,
                                               -- 品目ステータス
-- End
                xicw.item_status_name,         -- 品目ステータス名
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
--                xicw.fixed_price,
--                xicw.cmpnt_cost,
                TO_CHAR( xicw.fixed_price )    AS fixed_price,
                                               -- 定価
                TO_CHAR( xicw.cmpnt_cost )     AS cmpnt_cost,
                                               -- 標準原価計
-- End
-- Ver1.8  2009/07/13  Add  0000366対応
                TO_CHAR( xicw.cmpnt_01gen )    AS cmpnt_01gen,
                                               -- 標準原価（原料）
                TO_CHAR( xicw.cmpnt_02sai )    AS cmpnt_02sai,
                                               -- 標準原価（再製費）
                TO_CHAR( xicw.cmpnt_03szi )    AS cmpnt_03szi,
                                               -- 標準原価（資材費）
                TO_CHAR( xicw.cmpnt_04hou )    AS cmpnt_04hou,
                                               -- 標準原価（包装費）
                TO_CHAR( xicw.cmpnt_05gai )    AS cmpnt_05gai,
                                               -- 標準原価（外注加工費）
                TO_CHAR( xicw.cmpnt_06hkn )    AS cmpnt_06hkn,
                                               -- 標準原価（保管費）
                TO_CHAR( xicw.cmpnt_07kei )    AS cmpnt_07kei,
                                               -- 標準原価（その他経費）
-- End1.8
                xicw.cmp_cost_apply_date,      -- 標準原価適用開始日
-- Ver1.4 2009/02/12  暗黙型変換が実施されないよう修正
                TO_CHAR( xicw.discrete_cost )  AS discrete_cost,
                                               -- 営業原価
-- End
                xicw.policy_group,             -- 政策群
                xicw.policy_grp_name           -- 政策群名
      FROM      xxcmm_wk_itemrsv_csv xicw
      WHERE     xicw.request_id = cn_request_id
-- Ver1.8  209/07/13  Mod  品目コード、適用日順に変更
--      ORDER BY  xicw.policy_group,
--                xicw.item_code;
      ORDER BY  xicw.item_code,
                xicw.apply_date;
-- End1.8
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    no_data_expt  EXCEPTION;
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カウント用変数初期化
    lv_step      := 'A-5';
    lv_msg_token := 'CSV形式のデータ出力';
    ln_c := 0;
    -- ===============================
    -- CSV形式のデータ出力(A-5)
    -- ===============================
    -- 出力対象設定値が現在設定値の場合
    IF ( gv_output_div = cv_output_div ) THEN
      lv_step      := 'A-5';
      lv_msg_token := 'CSV形式のデータ出力:現在設定値';
      <<item_info1_loop>>
      FOR lt_item01_rec IN csv_data_cur1 LOOP
        ln_c := ln_c + 1;
        lv_csv_file :=
          lt_item01_rec.item_code
          || cv_sep_com       -- 品名コード
          || lt_item01_rec.item_name
          || cv_sep_com       -- 正式名
          || lt_item01_rec.item_short_name
          || cv_sep_com       -- 略称
          || lt_item01_rec.item_name_alt
          || cv_sep_com ||    -- カナ名
          ( CASE
              WHEN ( lt_item01_rec.item_status IS NOT NULL ) THEN
                lt_item01_rec.item_status || cv_sep || lt_item01_rec.item_status_name
              ELSE
                NULL
            END    -- 品目ステータス：品目ステータス名
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.sales_div IS NOT NULL ) THEN
                lt_item01_rec.sales_div || cv_sep || lt_item01_rec.sales_div_name
              ELSE
                NULL
            END    -- 売上対象区分：売上対象区分名
          )
          || cv_sep_com
          || lt_item01_rec.parent_item_code
          || cv_sep_com      -- 親品目ID
          || lt_item01_rec.num_of_cases
          || cv_sep_com      -- ケース入数
-- 2009/10/16 Ver1.10 add start by Shigeto.Niki
          || lt_item01_rec.case_conv_inc_num
          || cv_sep_com      -- ケース換算入数
-- 2009/10/16 Ver1.10 add end by Shigeto.Niki
          || lt_item01_rec.item_um
          || cv_sep_com ||   -- 単位
          ( CASE
              WHEN ( lt_item01_rec.item_product_class IS NOT NULL ) THEN
                lt_item01_rec.item_product_class || cv_sep || lt_item01_rec.item_product_class_name
              ELSE
                NULL
            END    -- 商品製品区分：商品製品区分名
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.rate_class IS NOT NULL ) THEN
                lt_item01_rec.rate_class || cv_sep || lt_item01_rec.rate_class_name
              ELSE
                NULL
            END    -- 率区分：率区分名
          )
          || cv_sep_com
          || lt_item01_rec.net
          || cv_sep_com      -- NET
          || lt_item01_rec.unit
          || cv_sep_com      -- 重量
          || lt_item01_rec.jan_code
          || cv_sep_com ||   -- JANコード
          ( CASE
              WHEN ( lt_item01_rec.nets IS NOT NULL ) THEN
                lt_item01_rec.nets || cv_sep || lt_item01_rec.nets_uom_code_name
              ELSE
                NULL
            END    -- 内容量
          )
          || cv_sep_com
          || lt_item01_rec.inc_num
          || cv_sep_com    -- 内訳入数
          || lt_item01_rec.case_jan_code
          || cv_sep_com ||  -- ケースJANコード
          ( CASE
              WHEN ( lt_item01_rec.hon_product_class IS NOT NULL ) THEN
                lt_item01_rec.hon_product_class || cv_sep || lt_item01_rec.hon_product_class_name
              ELSE
                NULL
            END    -- 本社商品区分：本社商品区分名
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.baracha_div IS NOT NULL ) THEN
                lt_item01_rec.baracha_div || cv_sep || lt_item01_rec.baracha_div_name
              ELSE
                NULL
            END    -- バラ茶区分：バラ茶区分名
          )
          || cv_sep_com
          || lt_item01_rec.itf_code
          || cv_sep_com ||  -- ITFコード
          ( CASE
              WHEN ( lt_item01_rec.product_class IS NOT NULL ) THEN
                lt_item01_rec.product_class || cv_sep || lt_item01_rec.product_class_name
              ELSE
                NULL
            END    -- 商品分類：商品分類名
          )
          || cv_sep_com
          || lt_item01_rec.palette_max_cs_qty
          || cv_sep_com    -- 配数
          || lt_item01_rec.palette_max_step_qty
          || cv_sep_com    -- パレット当り最大段数
          || lt_item01_rec.bowl_inc_num
          || cv_sep_com    -- ボール入数
          || TO_CHAR( lt_item01_rec.sell_start_date, cv_date_fmt_std )
          || cv_sep_com    -- 発売(製造)開始日
          || TO_CHAR( lt_item01_rec.obsolete_date, cv_date_fmt_std )
          || cv_sep_com ||  -- 廃止日(製造)中止日
          ( CASE
              WHEN ( lt_item01_rec.obsolete_class IS NOT NULL ) THEN
                lt_item01_rec.obsolete_class || cv_sep || lt_item01_rec.obsolete_class_name
              ELSE
                NULL
            END    -- 廃止区分：廃止区分名
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.vessel_group IS NOT NULL ) THEN
                lt_item01_rec.vessel_group || cv_sep || lt_item01_rec.vessel_group_name
              ELSE
                NULL
            END    -- 容器群：容器群名
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.new_item_div IS NOT NULL ) THEN
                lt_item01_rec.new_item_div || cv_sep || lt_item01_rec.new_item_div_name
              ELSE
                NULL
            END    -- 新商品区分：新商品区分名
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.acnt_group IS NOT NULL ) THEN
                lt_item01_rec.acnt_group || cv_sep || lt_item01_rec.acnt_group_name
              ELSE
                NULL
            END    -- 経理群：経理群名
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.acnt_vessel_group IS NOT NULL ) THEN
                lt_item01_rec.acnt_vessel_group || cv_sep || lt_item01_rec.acnt_vessel_group_name
              ELSE
                NULL
            END    -- 経理容器群：経理容器群名
          )
          || cv_sep_com ||
          ( CASE
              WHEN ( lt_item01_rec.brand_group IS NOT NULL ) THEN
                lt_item01_rec.brand_group || cv_sep || lt_item01_rec.brand_group_name
              ELSE
                NULL
            END    -- ブランド群：ブランド群名
          )
          || cv_sep_com
          || lt_item01_rec.renewal_item_code
          || cv_sep_com ||  -- リニューアル商品元コード
          ( CASE
              WHEN ( lt_item01_rec.sp_supplier_code IS NOT NULL ) THEN
                lt_item01_rec.sp_supplier_code || cv_sep || lt_item01_rec.ss_code_name
              ELSE
                NULL
            END    -- 専門店仕入先コード：専門店仕入先
          )
          || cv_sep_com
          || lt_item01_rec.price_old
          || cv_sep_com    -- 定価(旧)
          || lt_item01_rec.price_new
          || cv_sep_com    -- 定価(新)
          || TO_CHAR( lt_item01_rec.price_apply_date, cv_date_fmt_std )
          || cv_sep_com    -- 定価適用開始日
          || lt_item01_rec.cmpnt_cost
          || cv_sep_com    -- 標準原価計
-- Ver1.8  2009/07/13  Add  0000366対応
          || lt_item01_rec.cmpnt_01gen
          || cv_sep_com    -- 標準原価（原料）
          || lt_item01_rec.cmpnt_02sai
          || cv_sep_com    -- 標準原価（再製費）
          || lt_item01_rec.cmpnt_03szi
          || cv_sep_com    -- 標準原価（資材費）
          || lt_item01_rec.cmpnt_04hou
          || cv_sep_com    -- 標準原価（包装費）
          || lt_item01_rec.cmpnt_05gai
          || cv_sep_com    -- 標準原価（外注加工費）
          || lt_item01_rec.cmpnt_06hkn
          || cv_sep_com    -- 標準原価（保管費）
          || lt_item01_rec.cmpnt_07kei
          || cv_sep_com    -- 標準原価（その他経費）
-- End1.8
          || TO_CHAR( lt_item01_rec.cmp_cost_apply_date, cv_date_fmt_std )
          || cv_sep_com    -- 標準原価適用開始日
          || lt_item01_rec.opt_cost_old
          || cv_sep_com    -- 営業原価(旧)
          || lt_item01_rec.opt_cost_new
          || cv_sep_com    -- 営業原価(新)
          || TO_CHAR( lt_item01_rec.opt_cost_apply_date, cv_date_fmt_std )
          || cv_sep_com ||  -- 営業原価適用開始日
          ( CASE
              WHEN ( lt_item01_rec.seisakugun IS NOT NULL ) THEN
                lt_item01_rec.seisakugun || cv_sep || lt_item01_rec.seisakugun_name
              ELSE
                NULL
            END    -- 政策群：政策群名
          );
        -- 作成したCSVデータを出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_csv_file
        );
        -- 成功件数
        gn_normal_cnt := ln_c;
      END LOOP item_info1_loop;
    -- 出力対象設定値が予約設定値の場合
    ELSE
      lv_step      := 'A-5';
      lv_msg_token := 'CSV形式のデータ出力:予約設定値';
      <<item_info2_loop>>
      FOR lt_item01_rec IN csv_data_cur2 LOOP
        ln_c := ln_c + 1;
        lv_csv_file :=
          lt_item01_rec.item_code
          || cv_sep_com    -- 品名コード
          || lt_item01_rec.item_name
          || cv_sep_com    -- 正式名
          || TO_CHAR( lt_item01_rec.apply_date, cv_date_fmt_std )
          || cv_sep_com ||  -- 適用開始日
          ( CASE
              WHEN ( lt_item01_rec.item_status IS NOT NULL ) THEN
                lt_item01_rec.item_status || cv_sep || lt_item01_rec.item_status_name
              ELSE
                NULL
            END    -- 品目ステータス：品目ステータス名
          )
          || cv_sep_com
          || lt_item01_rec.fixed_price
          || cv_sep_com    -- 定価
          || lt_item01_rec.cmpnt_cost
          || cv_sep_com    -- 標準原価計
-- Ver1.8  2009/07/13  Add  0000366対応
          || lt_item01_rec.cmpnt_01gen
          || cv_sep_com    -- 標準原価（原料）
          || lt_item01_rec.cmpnt_02sai
          || cv_sep_com    -- 標準原価（再製費）
          || lt_item01_rec.cmpnt_03szi
          || cv_sep_com    -- 標準原価（資材費）
          || lt_item01_rec.cmpnt_04hou
          || cv_sep_com    -- 標準原価（包装費）
          || lt_item01_rec.cmpnt_05gai
          || cv_sep_com    -- 標準原価（外注加工費）
          || lt_item01_rec.cmpnt_06hkn
          || cv_sep_com    -- 標準原価（保管費）
          || lt_item01_rec.cmpnt_07kei
          || cv_sep_com    -- 標準原価（その他経費）
-- End1.8
          || TO_CHAR( lt_item01_rec.cmp_cost_apply_date, cv_date_fmt_std )
          || cv_sep_com    -- 標準原価適用開始日
          || lt_item01_rec.discrete_cost
          || cv_sep_com ||  -- 営業原価
          ( CASE
              WHEN ( lt_item01_rec.policy_group IS NOT NULL ) THEN
                lt_item01_rec.policy_group || cv_sep || lt_item01_rec.policy_grp_name
              ELSE
                NULL
            END    -- 政策群：政策群名
          );
        -- 作成したCSVデータを出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_csv_file
        );
        -- 成功件数
        gn_normal_cnt := ln_c;
      END LOOP item_info1_loop;
    END IF;
    --
    -- カウント用変数が'0'の時、データなし
    IF ( ln_c = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
  EXCEPTION
    -- リターンコード：エラーを外して正常終了するように修正 2009/01/20
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm,
                      iv_name         => cv_msg_xxcmm_00001
                    );
      ov_errmsg  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step ||
                    cv_msg_part || lv_errmsg, 1, 5000 );
      --ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
      --              cv_msg_part||SQLERRM;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      gn_error_cnt := ln_c;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_output_div        IN  VARCHAR2,     -- 出力対象設定値
    iv_item_status       IN  VARCHAR2,     -- 品目ステータス
    iv_date_from         IN  VARCHAR2,     -- 対象期間開始
    iv_date_to           IN  VARCHAR2,     -- 対象期間終了
    iv_item_code_from    IN  VARCHAR2,     -- 品名コード開始
    iv_item_code_to      IN  VARCHAR2,     -- 品名コード終了
    ov_errbuf            OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_step           VARCHAR2(100);   -- ステップ
    lv_msg_token      VARCHAR2(100);   -- デバッグ用トークン
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    subprog_err_expt  EXCEPTION;
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
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    lv_step      := 'A-1';
    lv_msg_token := '初期処理';
    proc_init(
      iv_output_div      => iv_output_div,     -- 出力対象設定値
      iv_item_status     => iv_item_status,    -- 品目ステータス
      iv_date_from       => iv_date_from,      -- 対象期間開始
      iv_date_to         => iv_date_to,        -- 対象期間終了
      iv_item_code_from  => iv_item_code_from, -- 品名コード開始
      iv_item_code_to    => iv_item_code_to,   -- 品名コード終了
      ov_errbuf          => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode         => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    --
    -- =====================================================
    -- 品目一覧情報取得(A-2,A-3)、標準原価取得(A-2.4,A-3.2)
    -- =====================================================
    lv_step      := 'A-2,A-3';
    lv_msg_token := '品目一覧情報取得、標準原価取得';
    get_item_mst(
      ov_errbuf   => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode  => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    --
    -- ===============================
    -- 項目タイトル取得(A-4)
    -- ===============================
    lv_step      := 'A-4';
    lv_msg_token := '項目タイトル取得';
    get_item_header(
      ov_errbuf   => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode  => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    --
    -- ===============================
    -- CSV形式のデータ出力(A-5)
    -- ===============================
    lv_step      := 'A-5';
    lv_msg_token := 'CSV形式のデータ出力';
    output_csv(
      iv_file_type  => cv_csv_file,       -- CSVファイル
      ov_errbuf     => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode    => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE subprog_err_expt;
    END IF;
    --
    --メッセージ出力(対象データ無し時)
    IF ( lv_retcode = cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
  EXCEPTION
    WHEN subprog_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||
                    cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf               OUT VARCHAR2,    -- エラー・メッセージ  --# 固定 #
    retcode              OUT VARCHAR2,    -- リターン・コード    --# 固定 #
    iv_output_div        IN  VARCHAR2,    -- 出力対象設定値
    iv_item_status       IN  VARCHAR2,    -- 品目ステータス
    iv_date_from         IN  VARCHAR2,    -- 対象期間開始
    iv_date_to           IN  VARCHAR2,    -- 対象期間終了
    iv_item_code_from    IN  VARCHAR2,    -- 品名コード開始
    iv_item_code_to      IN  VARCHAR2     -- 品名コード終了
  )
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
       iv_which   => cv_output_log
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
      iv_output_div     => iv_output_div,     -- 出力対象設定値
      iv_item_status    => iv_item_status,    -- 品目ステータス
      iv_date_from      => iv_date_from,      -- 対象期間開始
      iv_date_to        => iv_date_to,        -- 対象期間終了
      iv_item_code_from => iv_item_code_from, -- 品名コード開始
      iv_item_code_to   => iv_item_code_to,   -- 品名コード終了
      ov_errbuf         => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode        => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ======================
    -- 終了処理(A-6)
    -- ======================
    -- ワークテーブルのデータを削除する
    IF ( gv_output_div = cv_output_div) THEN
      DELETE FROM xxcmm_wk_item_csv xicw
      WHERE       xicw.request_id = cn_request_id;
    ELSE
      DELETE FROM xxcmm_wk_itemrsv_csv xicw
      WHERE       xicw.request_id = cn_request_id;
    END IF;
    COMMIT;
    --
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
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
END XXCMM004A10C;
/
