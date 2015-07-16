create or replace
PACKAGE BODY XXCOI009A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A02R(body)
 * Description      : 倉替出庫明細リスト
 * MD.050           : 倉替出庫明細リスト MD050_COI_009_A02
 * Version          : 1.14
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_work               ワークテーブルデータ削除(A-11)
 *  svf_request            SVF起動(A-10)
 *  ins_work               ワークテーブルデータ登録(A-9)
 *  get_div_cost           運送費算出処理(A-8)
 *  get_drink_data         ドリンク振替運賃アドオンマスタ情報抽出処理(A-7)
 *  get_customer_data      顧客マスタ情報抽出処理(A-6)
 *  get_cs_data            数量(C/S)算出処理(A-5)
 *  get_item_data          品目マスタ情報抽出処理(A-4)
 *  get_kuragae_data       倉替出庫明細データ取得(A-3)
 *  get_base_data          拠点情報取得処理(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05    1.0   K.Tsuboi         新規作成
 *  2009/02/23    1.1   K.Tsuboi         [障害COI_025] 営業原価額の符号反転表示対応
 *  2009/02/26    1.2   K.Tsuboi         [障害COI_027] 工場倉替,工場返品の出庫拠点桁数を指定するよう修正
 *  2009/03/02    1.3   K.Tsuboi         [障害COI_030] 営業原価額に取引数量*営業原価の値を設定
 *  2009/04/30    1.4   T.Nakamura       最終行にバックスラッシュを追加
 *  2009/05/21    1.5   T.Nakamura       [障害T1_0987] 営業原価額を四捨五入し整数値に変換するよう修正
 *                                       [障害T1_1030] 倉替データ取得時の取得条件を追加
 *  2009/05/22    1.6   H.Sasaki         [障害T1_1162] 運送費算出処理の実行条件を追加（倉替のみ）
 *  2009/05/29    1.7   H.Sasaki         [T1_1113]伝票番号の桁数を修正
 *  2009/06/03    1.8   H.Sasaki         [T1_1202]保管場所マスタの結合条件に在庫組織IDを追加
 *  2009/07/09    1.9   H.Sasaki         [0000338]SVF起動関数のパラメータ修正
 *  2009/07/30    1.10  N.Abe            [0000638]単位の取得項目修正
 *  2009/09/08    1.11  H.Sasaki         [0001266]OPM品目アドオンの版管理対応
 *  2010/10/27    1.12  H.Sasaki         [E_本稼動_05114]PT対応
 *  2014/03/27    1.13  K.Nakamura       [E_本稼動_11556]資材取引の抽出条件修正、不要な定数・変数削除
 *  2015/03/16    1.14  K.Nakamura       [E_本稼動_12906]在庫確定文字の追加
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
  get_value_expt            EXCEPTION;    -- 値取得エラー
-- == 2014/03/27 V1.13 Deleted START ===============================================================
--  lock_expt                 EXCEPTION;    -- ロック取得エラー
--  get_no_data_expt          EXCEPTION;    -- 取得データ0件
-- == 2014/03/27 V1.13 Deleted END   ===============================================================
  svf_request_err_expt      EXCEPTION;    -- SVF起動APIエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCOI009A02R';   -- パッケージ名
  cv_app_name          CONSTANT VARCHAR2(5)   := 'XXCOI';          -- アプリケーション短縮名
  cv_0                 CONSTANT VARCHAR2(1)   := '0';              -- 定数
  cv_1                 CONSTANT VARCHAR2(1)   := '1';              -- 定数
  cv_2                 CONSTANT VARCHAR2(1)   := '2';              -- 定数
  cv_3                 CONSTANT VARCHAR2(1)   := '3';              -- 定数
-- == 2014/03/27 V1.13 Deleted START ===============================================================
--  cv_31                CONSTANT VARCHAR2(2)   := '31';             -- 定数
-- == 2014/03/27 V1.13 Deleted END   ===============================================================
  cv_dellivary_classe  CONSTANT VARCHAR2(2)   := '41';             -- 大型車
  cn_baracya_type      CONSTANT VARCHAR2(1)   := '1';              -- バラ茶区分
  cv_office_item_drink CONSTANT VARCHAR2(1)   := '2';              -- ドリンク
  cv_log               CONSTANT VARCHAR2(3)   := 'LOG';            -- コンカレントヘッダ出力先
-- == 2015/03/16 V1.14 Added START ==============================================================
  cv_format_yyyymmdd   CONSTANT VARCHAR2(10)  :=  'YYYY/MM/DD';    --  DATE型 年月日（YYYY/MM/DD）
-- == 2015/03/16 V1.14 Added END   ==============================================================
--
  -- メッセージ
  cv_msg_xxcoi00008  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00008';   -- 0件メッセージ
  cv_msg_xxcoi10003  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10003';   -- 日付入力エラー
  cv_msg_xxcoi00005  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00005';   -- 在庫組織コード取得エラー
  cv_msg_xxcoi00006  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00006';   -- 在庫組織ID取得エラー
  cv_msg_xxcoi00011  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00011';   -- 業務日付取得エラー
  cv_msg_xxcoi00022  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00022';   -- 取引タイプ名取得エラー
  cv_msg_xxcoi00012  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00012';   -- 取引タイプ取得エラー
  cv_msg_xxcoi00030  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00030';   -- マスタ組織コード取得エラー
  cv_msg_xxcoi00031  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00031';   -- マスタ組織ID取得エラー
-- == 2014/03/27 V1.13 Added START ===============================================================
  cv_msg_xxcoi00032  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00032';   -- プロファイル値取得エラー
-- == 2014/03/27 V1.13 Added END   ===============================================================
-- == 2014/03/27 V1.13 Deleted START ===============================================================
--  cv_msg_xxcoi10069  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10069';   -- 日付範囲(年月)エラー
-- == 2014/03/27 V1.13 Deleted END   ===============================================================
  cv_msg_xxcoi10070  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10070';   -- 日付範囲(日)エラー
  cv_msg_xxcoi10092  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10092';   -- 所属拠点取得エラー
  cv_msg_xxcoi10066  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10066';   -- パラメータ.取引タイプメッセージ
  cv_msg_xxcoi10067  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10067';   -- パラメータ.年月日メッセージ
  cv_msg_xxcoi10068  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10068';   -- パラメータ.出庫拠点メッセージ
-- == 2014/03/27 V1.13 Deleted START ===============================================================
--  cv_msg_xxcoi10011  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10011';   -- 品目マスタ情報未取得エラー
-- == 2014/03/27 V1.13 Deleted END   ===============================================================
  cv_msg_xxcoi10012  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10012';   -- 品目マスタ情報複数件エラー
-- == 2014/03/27 V1.13 Deleted START ===============================================================
--  cv_msg_xxcoi10013  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10013';   -- 顧客マスタ情報未取得エラー
-- == 2014/03/27 V1.13 Deleted END   ===============================================================
  cv_msg_xxcoi10014  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10014';   -- 顧客マスタ情報複数件エラー
  cv_msg_xxcoi10016  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10016';   -- 設定単価未取得エラー
  cv_msg_xxcoi10017  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10017';   -- 設定単価複数件エラー
  cv_msg_xxcoi10292  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10292';   -- ケース入数取得エラー
  cv_msg_xxcoi10293  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10293';   -- 営業原価取得失敗エラー
-- == 2009/05/29 V1.7 Added START ===============================================================
  cv_msg_xxcoi10381  CONSTANT VARCHAR2(30) := 'APP-XXCOI1-10381';   -- 伝票№マスク取得エラーメッセージ
-- == 2009/05/29 V1.7 Added END   ===============================================================
-- == 2015/03/16 V1.14 Added START ==============================================================
  cv_msg_xxcoi00026  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00026';   -- 在庫会計期間ステータス取得エラーメッセージ
  cv_msg_xxcoi10451  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-10451';   -- 在庫確定印字文字取得エラーメッセージ
-- == 2015/03/16 V1.14 Added END   ==============================================================
--
  -- トークン名
  cv_token_pro                CONSTANT VARCHAR2(30) := 'PRO_TOK';
  cv_token_org_code           CONSTANT VARCHAR2(30) := 'ORG_CODE_TOK';
  cv_token_mst_org_code       CONSTANT VARCHAR2(30) := 'MST_ORG_CODE_TOK';
  cv_token_transaction_type   CONSTANT VARCHAR2(30) := 'P_TRAN_TYPE';
  cv_token_date               CONSTANT VARCHAR2(30) := 'P_DATE';
  cv_token_base_code          CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_token_lookup_type        CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';            -- 参照タイプ
  cv_token_lookup_code        CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';            -- 参照コード
  cv_token_tran_type          CONSTANT VARCHAR2(20) := 'TRANSACTION_TYPE_TOK';   -- 取引タイプ
  cv_token_item_code          CONSTANT VARCHAR2(20) := 'ITEM_CODE';              -- 品目コード
  cv_token_product_class      CONSTANT VARCHAR2(20) := 'PRODUCT_CLASS';          -- 拠点分類
  cv_token_location_code      CONSTANT VARCHAR2(20) := 'LOCATION_CODE';          -- 拠点コード
  cv_token_base_major         CONSTANT VARCHAR2(20) := 'BASE_MAJOR_DIVISION';    -- 拠点大分類
-- == 2015/03/16 V1.14 Added START ==============================================================
  cv_token_target_data        CONSTANT VARCHAR2(20) := 'TARGET_DATE';            -- 対象日
-- == 2015/03/16 V1.14 Added END   ==============================================================
--
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE gr_param_rec  IS RECORD(
      transaction_type  VARCHAR2(3)       -- 01 : 取引タイプ    (任意)
     ,year_month        VARCHAR2(7)       -- 01 : 処理年月      (必須)
     ,a_day             VARCHAR2(2)       -- 02 : 処理日        (任意)
     ,out_kyoten        VARCHAR2(4)       -- 03 : 出庫拠点      (任意)
     ,output_dpt        VARCHAR2(1)       -- 04 : 帳票出力場所  (必須)
    );
--
  -- 拠点情報格納用レコード変数
  TYPE gr_base_num_rec IS RECORD
    (
      hca_cust_num                   hz_cust_accounts.account_number%TYPE    -- 拠点コード
    );
--
  --  拠点情報格納用テーブル
  TYPE gt_base_num_ttype IS TABLE OF gr_base_num_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date           DATE;                                             -- 業務日付
  gv_base_code              hz_cust_accounts.account_number%TYPE;             -- 拠点コード
  -- カウンタ
  gn_base_cnt               NUMBER;                                           -- 拠点コード件数
  gn_base_loop_cnt          NUMBER;                                           -- 拠点コードループカウンタ
-- == 2014/03/27 V1.13 Deleted START ===============================================================
--  gn_kuragae_cnt            NUMBER;                                           -- 倉替出庫情報件数
--  gn_kuragae_loop_cnt       NUMBER;                                           -- 倉替出庫情報ループカウンタ
-- == 2014/03/27 V1.13 Deleted END   ===============================================================
  gn_organization_id        mtl_parameters.organization_id%TYPE;              -- 在庫組織ID
  gn_mst_organization_id    mtl_parameters.organization_id%TYPE;              -- マスタ組織ID
  gv_item_div_h             VARCHAR2(20);                                     -- 本社商品区分名
  gv_transaction_type_name  mtl_transaction_types.transaction_type_name%TYPE; -- 取引タイプ名
  -- 
  gr_param                  gr_param_rec;
  gt_base_num_tab           gt_base_num_ttype;
-- == 2009/05/13 V1.1 Added START ===============================================================
  gn_slip_number_mask       NUMBER;                                           -- 伝票№マスク(990000000000)
-- == 2009/05/13 V1.1 Added END   ===============================================================
-- == 2010/10/27 V1.12 Added START ===============================================================
  gd_trans_date_from        DATE;                                             --  取引日FROM
  gd_trans_date_to          DATE;                                             --  取引日TO
-- == 2010/10/27 V1.12 Added END   ===============================================================
-- == 2015/03/16 V1.14 Added START ==============================================================
  gt_inv_cl_char            fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 在庫確定印字文字
-- == 2015/03/16 V1.14 Added END   ==============================================================
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ワークテーブルデータ削除(A-11)
   ***********************************************************************************/
  PROCEDURE del_work(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_work'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --帳票用ワークテーブルから削除
    DELETE xxcoi_rep_kuragae_ship_list xrk
    WHERE  xrk.request_id = cn_request_id
    ;
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
  END del_work;
--  
  /**********************************************************************************
   * Procedure Name   : svf_request
   * Description      : SVF起動(A-10)
   ***********************************************************************************/
  PROCEDURE svf_request(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'svf_request'; -- プログラム名
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
    cv_output_mode  CONSTANT VARCHAR2(1)  := '1';                    -- 出力区分(PDF出力)
    cv_frm_file     CONSTANT VARCHAR2(30) := 'XXCOI009A02S.xml';     -- フォーム様式ファイル名
    cv_vrq_file     CONSTANT VARCHAR2(30) := 'XXCOI009A02S.vrq';     -- クエリー様式ファイル名
    cv_api_name     CONSTANT VARCHAR2(7)  := 'SVF起動';              -- SVF起動API名
--
    -- エラーコード
    cv_msg_xxcoi00010  CONSTANT VARCHAR2(16) := 'APP-XXCOI1-00010';   -- APIエラー
--
    -- トークン名
    cv_token_name_1  CONSTANT VARCHAR2(30) := 'API_NAME';
--
    -- *** ローカル変数 ***
    ld_date       VARCHAR2(8);   -- 日付
    lv_file_name  VARCHAR2(100); -- 出力ファイル名
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
    -- 日付書式変換
    ld_date := TO_CHAR( cd_creation_date, 'YYYYMMDD' );
--
    -- 出力ファイル名
-- == 2009/07/09 V1.9 Modified START ===============================================================
--    lv_file_name := cv_pkg_name || ld_date || TO_CHAR(cn_request_id);
    lv_file_name := cv_pkg_name || ld_date || TO_CHAR(cn_request_id) || '.pdf';
-- == 2009/07/09 V1.9 Modified START ===============================================================
--
    --SVF起動処理
      xxccp_svfcommon_pkg.submit_svf_request(
        ov_retcode      => lv_retcode             -- リターンコード
       ,ov_errbuf       => lv_errbuf              -- エラーメッセージ
       ,ov_errmsg       => lv_errmsg              -- ユーザー・エラーメッセージ
       ,iv_conc_name    => cv_pkg_name            -- コンカレント名
-- == 2009/07/09 V1.9 Modified START ===============================================================
--       ,iv_file_name    => cv_frm_file            -- 出力ファイル名
       ,iv_file_name    => lv_file_name           -- 出力ファイル名
-- == 2009/07/09 V1.9 Modified END   ===============================================================
       ,iv_file_id      => cv_pkg_name            -- 帳票ID
       ,iv_output_mode  => cv_output_mode         -- 出力区分
       ,iv_frm_file     => cv_frm_file            -- フォーム様式ファイル名
       ,iv_vrq_file     => cv_vrq_file            -- クエリー様式ファイル名
       ,iv_org_id       => fnd_global.org_id      -- ORG_ID
-- == 2009/07/09 V1.9 Modified START ===============================================================
--       ,iv_user_name    => cn_created_by          -- ログイン・ユーザ名
       ,iv_user_name    => fnd_global.user_name   -- ログイン・ユーザ名
-- == 2009/07/09 V1.9 Modified END   ===============================================================
       ,iv_resp_name    => fnd_global.resp_name   -- ログイン・ユーザの職責名
       ,iv_doc_name     => NULL                   -- 文書名
       ,iv_printer_name => NULL                   -- プリンタ名
       ,iv_request_id   => cn_request_id          -- 要求ID
       ,iv_nodata_msg   => NULL                   -- データなしメッセージ
      );
--
    --==============================================================
    --エラーメッセージ出力
    --==============================================================
    IF lv_retcode <> cv_status_normal THEN
      RAISE svf_request_err_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** SVF起動APIエラー ***
    WHEN svf_request_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                    , iv_name         => cv_msg_xxcoi00010
                    , iv_token_name1  => cv_token_name_1
                    , iv_token_value1 => cv_api_name
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END svf_request;
--
  /**********************************************************************************
   * Procedure Name   : ins_work
   * Description      : ワークテーブルデータ登録(A-9)
   ***********************************************************************************/
  PROCEDURE ins_work(
    it_out_base_code           IN hz_cust_accounts.account_number%TYPE,                -- 出庫拠点
    it_out_base_name           IN hz_cust_accounts.account_name%TYPE,                  -- 出庫拠点名
    it_transaction_type_id     IN mtl_material_transactions.transaction_id%TYPE,       -- 取引タイプID
    it_transaction_type_name   IN mtl_transaction_types.transaction_type_name%TYPE,    -- 取引タイプ名
    it_transaction_type_id_sub IN mtl_material_transactions.transaction_id%TYPE,       -- 取引タイプサブID
    it_in_base_code            IN hz_cust_accounts.account_number%TYPE,                -- 入庫拠点
    it_in_base_name            IN hz_cust_accounts.account_name%TYPE,                  -- 入庫拠点名
    it_transaction_date        IN mtl_material_transactions.transaction_date%TYPE,     -- 取引日
    it_item_code               IN mtl_system_items_b.segment1%TYPE,                    -- 商品
    it_item_name               IN xxcmn_item_mst_b.item_short_name%TYPE,               -- 商品名
    it_slip_no                 IN mtl_material_transactions.attribute1%TYPE,           -- 伝票No
-- == 2009/07/30 V2.0 Modified START   ==================================================================
--    it_transaction_qty         IN mtl_material_transactions.transaction_quantity%TYPE, -- 取引数量
    it_transaction_qty         IN mtl_material_transactions.primary_quantity%TYPE,     -- 基準単位数量
-- == 2009/07/30 V2.0 Modified END   ==================================================================
    iv_trading_cost            IN NUMBER,                  -- 営業原価額
    iv_dlv_cost                IN NUMBER,                  -- 振替運送費
    iv_nodata_msg              IN VARCHAR2,               -- ０件メッセージ
    ov_errbuf                  OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --工場入庫明細リスト帳票ワークテーブル登録処理
    INSERT INTO xxcoi_rep_kuragae_ship_list(
       target_term
-- == 2015/03/16 V1.14 Added START ==============================================================
      ,inv_cl_char
-- == 2015/03/16 V1.14 Added END   ==============================================================
      ,ship_base_code
      ,ship_base_name
      ,transaction_type_id
      ,transaction_type_name
      ,transaction_type_id_sub
      ,store_base_code
      ,store_base_name
      ,transaction_date
      ,item_code
      ,item_name
      ,slip_no
      ,transaction_qty
      ,trading_cost
      ,dlv_cost
      ,nodata_msg
      --WHOカラム
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       gr_param.year_month||gr_param.a_day          -- 対象年月日
-- == 2015/03/16 V1.14 Added START ==============================================================
      ,gt_inv_cl_char                               -- 在庫確定印字文字
-- == 2015/03/16 V1.14 Added END   ==============================================================
      ,it_out_base_code                             -- 出庫拠点
      ,it_out_base_name                             -- 出庫拠点名
      ,it_transaction_type_id                       -- 取引タイプID
      ,it_transaction_type_name                     -- 取引タイプ名
      ,it_transaction_type_id_sub                   -- 取引タイプサブID
      ,it_in_base_code                              -- 入庫拠点
      ,it_in_base_name                              -- 入庫拠点名
      ,TO_CHAR(it_transaction_date,'YYYYMMDD')      -- 取引日
      ,it_item_code                                 -- 商品
      ,it_item_name                                 -- 商品名
      ,it_slip_no                                   -- 伝票No
      ,it_transaction_qty                           -- 取引数量
      ,iv_trading_cost                              -- 営業原価額
      ,iv_dlv_cost                                  -- 振替運送費
      ,iv_nodata_msg                                -- ０件メッセージ
      --WHOカラム
      ,cn_created_by
      ,sysdate
      ,cn_last_updated_by
      ,sysdate
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,sysdate
     );
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
  END ins_work;
--
  /**********************************************************************************
   * Procedure Name   : get_div_cost
   * Description      : 運送費予算金額算出処理(A-8)
   ***********************************************************************************/
  PROCEDURE get_div_cost(
     in_cs_qty               IN  NUMBER                                            -- 数量（CS）
    ,it_set_unit_price       IN  xxwip_drink_trans_deli_chrgs.setting_amount%TYPE  -- 設定単価
    ,on_dlv_cost_budget_amt  OUT NUMBER                                            -- 運送費予算金額
    ,ov_errbuf               OUT VARCHAR2                                          -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2                                          -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2                                          -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_div_cost'; -- プログラム名
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
    -- 運送費予算金額算出
    on_dlv_cost_budget_amt := in_cs_qty * it_set_unit_price;
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
  END get_div_cost;
--
  /**********************************************************************************
   * Procedure Name   : get_drink_data
   * Description      : ドリンク振替運賃アドオンマスタ情報抽出処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_drink_data(
     it_transaction_date     IN  mtl_material_transactions.transaction_date%TYPE    -- 取引日
    ,it_base_code            IN  hz_cust_accounts.account_number%TYPE               -- 拠点コード
    ,it_product_class        IN  xxcmn_item_mst_b.product_class%TYPE                -- 商品分類
    ,it_base_major_division  IN  xxcmn_parties.base_major_division%TYPE             -- 拠点大分類
    ,ot_set_unit_price       OUT xxwip_drink_trans_deli_chrgs.setting_amount%TYPE   -- 設定単価
    ,ov_errbuf               OUT VARCHAR2                                           -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2                                           -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2                                           -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_drink_data'; -- プログラム名
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
    -- ドリンク振替運賃アドオンマスタ情報取得
    SELECT xdtd.setting_amount  setting_amount    -- 設定単価
    INTO   ot_set_unit_price
    FROM   xxwip_drink_trans_deli_chrgs xdtd
    WHERE  xdtd.godds_classification   = TO_CHAR( it_product_class )
    AND    xdtd.foothold_macrotaxonomy = it_base_major_division
    AND    xdtd.dellivary_classe       = cv_dellivary_classe
-- == 2014/03/27 V1.13 Modified START ===============================================================
--    AND    it_transaction_date BETWEEN xdtd.start_date_active AND NVL( xdtd.end_date_active, SYSDATE )
    AND    TRUNC(it_transaction_date)  BETWEEN xdtd.start_date_active AND xdtd.end_date_active
-- == 2014/03/27 V1.13 Modified END   ===============================================================
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** ドリンク振替運賃アドオンマスタ情報取得例外ハンドラ ****
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_xxcoi10016
                      ,iv_token_name1  => cv_token_product_class
                      ,iv_token_value1 => TO_CHAR( it_product_class )
                      ,iv_token_name2  => cv_token_base_major
                      ,iv_token_value2 => it_base_major_division
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    WHEN TOO_MANY_ROWS THEN
      -- *** ドリンク振替運賃アドオンマスタ情報複数件例外ハンドラ ****
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_xxcoi10017
                      ,iv_token_name1  => cv_token_product_class
                      ,iv_token_value1 => TO_CHAR( it_product_class )
                      ,iv_token_name2  => cv_token_base_major
                      ,iv_token_value2 => it_base_major_division
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_drink_data;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_mst_info
   * Description      : 顧客マスタ情報抽出処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_cust_mst_info(
     it_base_code            IN  hz_cust_accounts.account_number%TYPE      -- 拠点コード
    ,ot_base_major_division  OUT xxcmn_parties.base_major_division%TYPE    -- 拠点大分類
    ,ov_errbuf               OUT VARCHAR2                                  -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2                                  -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2                                  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_mst_info'; -- プログラム名
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
    lv_base_major_division    xxcmn_parties.base_major_division%TYPE;
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
    -- 顧客マスタ情報取得
    SELECT xp.base_major_division  base_major_division   -- 拠点大分類
    INTO   ot_base_major_division
    FROM   hz_parties        hp       -- パーティマスタ
          ,xxcmn_parties     xp       -- パーティアドオンマスタ
          ,hz_cust_accounts  hca      -- 顧客マスタ
    WHERE xp.party_id             = hp.party_id
    AND   hp.party_id             = hca.party_id
    AND   hca.account_number      = it_base_code
    AND   hca.customer_class_code = cv_1
    AND   ROWNUM                  = 1
    ;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN NO_DATA_FOUND THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_xxcoi10014
                      ,iv_token_name1  => cv_token_location_code
                      ,iv_token_value1 => it_base_code
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_cust_mst_info;
--
  /**********************************************************************************
   * Procedure Name   : get_cs_data
   * Description      : 数量(C/S)算出処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_cs_data(
-- == 2009/07/30 V2.0 Modified START ===============================================================
--     it_transaction_qty        IN  mtl_material_transactions.transaction_quantity%TYPE  -- 数量
     it_transaction_qty        IN  mtl_material_transactions.primary_quantity%TYPE      -- 基準単位数量
-- == 2009/07/30 V2.0 Modified START ===============================================================
    ,it_godds_classification   IN  ic_item_mst_b.attribute11%TYPE                       -- ケース入数
    ,on_cs_qty                 OUT NUMBER                                               -- 数量（CS）
    ,ov_errbuf                 OUT VARCHAR2                                             -- エラー・メッセージ
    ,ov_retcode                OUT VARCHAR2                                             -- リターン・コード
    ,ov_errmsg                 OUT VARCHAR2                                             -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cs_data'; -- プログラム名
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

    -- 数量（CS）算出
    on_cs_qty := ROUND( it_transaction_qty / TO_NUMBER( it_godds_classification ) );
--
  EXCEPTION
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_cs_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item_data
   * Description      : 品目マスタ情報抽出処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_item_data(
     it_item_no                IN  mtl_system_items_b.segment1%TYPE        -- 商品コード
-- == 2009/09/08 V1.11 Added START ==================================================================
    ,it_transaction_date       IN  mtl_material_transactions.transaction_date%TYPE     -- 取引日
-- == 2009/09/08 V1.11 Added END   ==================================================================
    ,ot_product_class          OUT xxcmn_item_mst_b.product_class%TYPE     -- 商品分類
    ,ot_godds_classification   OUT ic_item_mst_b.attribute11%TYPE          -- ケース入数
    ,ot_baracha_div            OUT xxcmm_system_items_b.baracha_div%TYPE   -- バラ茶区分
    ,ot_office_item_type       OUT mtl_categories_b.segment1%TYPE          -- 本社商品区分
    ,ov_errbuf                 OUT VARCHAR2                                -- エラー・メッセージ
    ,ov_retcode                OUT VARCHAR2                                -- リターン・コード
    ,ov_errmsg                 OUT VARCHAR2                                -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_data'; -- プログラム名
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
    -- ===============================
    -- 品目マスタ情報取得
    -- ===============================
    -- 
    SELECT ximb.product_class   AS product_class         -- 商品分類
          ,iimb.attribute11     AS godds_classification  -- ケース入数
          ,xsib.baracha_div     AS baracha_div           -- バラ茶区分
          ,mcb.segment1         AS item_div_h            -- 本社商品区分
    INTO   ot_product_class
          ,ot_godds_classification
          ,ot_baracha_div
          ,ot_office_item_type
    FROM   mtl_system_items_b      msib     -- 品目マスタ
          ,ic_item_mst_b           iimb     -- OPM品目マスタ
          ,mtl_category_sets_b     mcsb     -- 品目カテゴリセット
          ,mtl_category_sets_tl    mcst     -- 品目カテゴリセット日本語
          ,mtl_categories_b        mcb      -- 品目カテゴリマスタ
          ,mtl_item_categories     mic      -- 品目カテゴリ割当
          ,xxcmm_system_items_b    xsib     -- 品目アドオンマスタ
          ,xxcmn_item_mst_b        ximb     -- OPM品目アドオンマスタ
    WHERE  msib.segment1                = iimb.item_no
    AND    iimb.item_id                 = ximb.item_id
-- == 2014/03/27 V1.13 Modified START ===============================================================
---- == 2009/09/08 V1.11 Added START ==================================================================
--    AND    it_transaction_date  BETWEEN ximb.start_date_active
--                                AND     NVL(ximb.end_date_active, it_transaction_date)
---- == 2009/09/08 V1.11 Added END   ==================================================================
    AND    TRUNC(it_transaction_date)   BETWEEN ximb.start_date_active AND ximb.end_date_active
-- == 2014/03/27 V1.13 Modified END   ===============================================================
    AND    msib.segment1                = xsib.item_code
    AND    msib.inventory_item_id       = mic.inventory_item_id
    AND    msib.organization_id         = mic.organization_id
    AND    mic.category_id              = mcb.category_id
    AND    mcb.structure_id             = mcsb.structure_id
    AND    mic.category_set_id          = mcsb.category_set_id
    AND    mcst.category_set_id         = mcsb.category_set_id
    AND    msib.segment1                = it_item_no
    AND    mcst.language                = USERENV( 'LANG' )
    AND    mcst.category_set_name       = gv_item_div_h
    AND    msib.organization_id         = gn_organization_id
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** 品目マスタ情報取得例外ハンドラ ****
      ov_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_xxcoi10012
                      ,iv_token_name1  => cv_token_item_code
                      ,iv_token_value1 => it_item_no
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
  END get_item_data;
--
  /**********************************************************************************
   * Procedure Name   : get_kuragae_data（ループ部）
   * Description      : 倉替出庫明細データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_kuragae_data(
    gn_base_loop_cnt IN NUMBER,       --   カウント
    ov_errbuf        OUT VARCHAR2,    --   エラー・メッセージ                --# 固定 #
    ov_retcode       OUT VARCHAR2,    --   リターン・コード                  --# 固定 #
    ov_errmsg        OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_kuragae_data'; -- プログラム名
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
    cn_ido_order                   CONSTANT NUMBER   := 64;                           -- 取引タイプ 移動オーダー移動
    cv_flag                        CONSTANT VARCHAR2(1)  := 'Y';                      -- 使用可能フラグ 'Y'
--
    -- 参照タイプ
    -- ユーザー定義取引タイプ名称
    cv_tran_type                   CONSTANT VARCHAR2(30)  := 'XXCOI1_TRANSACTION_TYPE_NAME';
    -- 工場返品倉替先コード
    cv_mfg_fctory_cd               CONSTANT VARCHAR2(30) := 'XXCOI_MFG_FCTORY_CD'; 
--
    -- 参照コード
    cv_tran_type_kuragae           CONSTANT VARCHAR2(2)   := '20';   -- 取引タイプコード 倉替
    cv_tran_type_kojo_henpin       CONSTANT VARCHAR2(2)   := '90';   -- 取引タイプコード 工場返品
    cv_tran_type_kojo_henpin_b     CONSTANT VARCHAR2(3)   := '100';  -- 取引タイプコード 工場返品振戻
    cv_tran_type_kojo_kuragae      CONSTANT VARCHAR2(3)   := '110';  -- 取引タイプコード 工場倉替
    cv_tran_type_kojo_kuragae_b    CONSTANT VARCHAR2(3)   := '120';  -- 取引タイプコード 工場倉替振戻
    cv_tran_type_haikyaku          CONSTANT VARCHAR2(3)   := '130';  -- 取引タイプコード 廃却
    cv_tran_type_haikyaku_b        CONSTANT VARCHAR2(3)   := '140';  -- 取引タイプコード 廃却振戻
--   
    -- *** ローカル変数 ***
    lv_tran_type_kuragae           mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 倉替
    ln_tran_type_kuragae           mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 倉替
    lv_tran_type_kojo_henpin       mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 工場返品
    ln_tran_type_kojo_henpin       mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 工場返品
    lv_tran_type_kojo_henpin_b     mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 工場返品振戻
    ln_tran_type_kojo_henpin_b     mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 工場返品振戻
    lv_tran_type_kojo_kuragae      mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 工場倉替
    ln_tran_type_kojo_kuragae      mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 工場倉替
    lv_tran_type_kojo_kuragae_b    mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 工場倉替振戻
    ln_tran_type_kojo_kuragae_b    mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 工場倉替振戻
    lv_tran_type_haikyaku          mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 廃却
    ln_tran_type_haikyaku          mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 廃却
    lv_tran_type_haikyaku_b        mtl_transaction_types.transaction_type_name%TYPE;   -- 取引タイプ名 廃却振戻
    ln_tran_type_haikyaku_b        mtl_transaction_types.transaction_type_id%TYPE;     -- 取引タイプID 廃却振戻
    lv_product_class               xxcmn_item_mst_b.product_class%TYPE;                -- 商品分類
    lv_godds_classification        ic_item_mst_b.attribute11%TYPE;                     -- ケース入数
    lv_baracha_div                 xxcmm_system_items_b.baracha_div%TYPE;              -- バラ茶区分
    lv_office_item_type            mtl_categories_b.segment1%TYPE;                     -- 本社商品区分
    lv_base_major_division         xxcmn_parties.base_major_division%TYPE;             -- 拠点大分類
    ln_cs_qty                      NUMBER;
    ln_set_unit_price              xxwip_drink_trans_deli_chrgs.setting_amount%TYPE;   -- 設定単価
    ln_dlv_cost_budget_amt         NUMBER;                                             -- 運送費
    lv_discrete_cost               xxcmm_system_items_b_hst.discrete_cost%TYPE;        -- 営業原価
    ln_discrete_cost               NUMBER;                                             -- 営業原価(型変換) 
-- == 2014/03/27 V1.13 Deleted START ===============================================================
--    ln_cnt                         NUMBER       DEFAULT  0;          -- ループカウンタ
--    lv_zero_message                VARCHAR2(30) DEFAULT  NULL;       -- ゼロ件メッセージ
--    ln_sql_cnt                     NUMBER       DEFAULT  0;
-- == 2014/03/27 V1.13 Deleted END   ===============================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 倉替出庫明細情報
    CURSOR info_kuragae_cur(ln_kojo_henpin            NUMBER
                           ,ln_kojo_henpin_b          NUMBER 
                           ,ln_kojo_kuragae           NUMBER
                           ,ln_kojo_kuragae_b         NUMBER
                           ,ln_haikyaku               NUMBER
                           ,ln_haikyaku_b             NUMBER
                           ,ln_kuragae                NUMBER
                           ,cn_ido_order              NUMBER
                           ,lv_tran_type_kojo_henpin  VARCHAR2
                           ,lv_tran_type_kojo_kuragae VARCHAR2
                           ,lv_tran_type_haikyaku     VARCHAR2)
    IS
      -- 倉替・移動オーダー
      SELECT  mmt.transaction_id
             ,mmt.transaction_type_id        transaction_type_id        -- 取引タイプID
             ,mmt.transaction_type_id        transaction_type_id_sub    -- 取引タイプIDサブ
             ,mtt.transaction_type_name      transaction_type_name      -- 取引タイプ名
             ,msi1.attribute7                out_base_code              -- 出庫拠点 
             ,SUBSTRB(hca1.account_name,1,8) out_base_name              -- 出庫拠点名
             ,msi2.attribute7                in_base_code               -- 入庫拠点 
             ,SUBSTRB(hca2.account_name,1,8) in_base_name               -- 入庫拠点名
             ,mmt.transaction_date           transaction_date           -- 取引日
             ,mmt.attribute1                 slip_no                    -- 伝票No
             ,mmt.inventory_item_id          inventory_item_id          -- 品目ID
             ,msib.segment1                  item_no                    -- 品目コード
             ,ximb.item_short_name           item_short_name            -- 略称
-- == 2009/07/30 V2.0 Modified START ===============================================================
--             ,mmt.transaction_quantity       transaction_qty            -- 取引数量
             ,mmt.primary_quantity           transaction_qty            -- 基準単位数量
-- == 2009/07/30 V2.0 Modified END ===============================================================
      FROM    mtl_material_transactions  mmt                            -- 資材取引
             ,mtl_transaction_types      mtt                            -- 取引タイプマスタ
             ,mtl_secondary_inventories  msi1                           -- 保管場所マスタ1
             ,mtl_secondary_inventories  msi2                           -- 保管場所マスタ2
             ,hz_cust_accounts           hca1                           -- 顧客マスタ１
             ,hz_cust_accounts           hca2                           -- 顧客マスタ２
             ,mtl_system_items_b         msib                           -- 品目マスタ
             ,ic_item_mst_b              iimb                           -- OPM品目マスタ  
             ,xxcmn_item_mst_b           ximb                           -- OPM品目アドオンマスタ
      WHERE   mmt.transaction_type_id            =  mtt.transaction_type_id
        AND  ( ( ( gr_param.transaction_type = ln_kuragae ) AND
               ( mmt.transaction_type_id  = ln_kuragae ) )
          OR ( ( gr_param.transaction_type = cn_ido_order ) AND
               ( mmt.transaction_type_id  = cn_ido_order ) )
          OR ( ( gr_param.transaction_type IS NULL ) AND
               ( mmt.transaction_type_id  = ln_kuragae) ) )
-- == 2010/10/27 V1.12 Modified START ===============================================================
--        AND  ( ( ( gr_param.a_day IS NULL ) AND 
--               ( TO_CHAR ( mmt.transaction_date, 'YYYYMM' ) = gr_param.year_month ) )
--          OR ( ( gr_param.a_day IS NOT NULL ) AND 
--               ( TO_CHAR ( mmt.transaction_date, 'YYYYMMDD' ) = gr_param.year_month||gr_param.a_day ) ) )
        AND   mmt.transaction_date              >=  gd_trans_date_from
        AND   mmt.transaction_date              <   gd_trans_date_to
-- == 2010/10/27 V1.12 Modified END   ===============================================================
        AND  mmt.subinventory_code               =  msi1.secondary_inventory_name
        AND  mmt.transfer_subinventory           =  msi2.secondary_inventory_name
-- == 2009/06/03 V1.8 Added START ===============================================================
        AND  mmt.organization_id                 =  msi1.organization_id
        AND  mmt.transfer_organization_id        =  msi2.organization_id
-- == 2009/06/03 V1.8 Added END   ===============================================================
        AND  msi1.attribute7                     =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
        AND  hca1.account_number                 =  msi1.attribute7
        AND  hca1.customer_class_code            =  cv_1
        AND  hca2.account_number                 =  msi2.attribute7
        AND  hca2.customer_class_code            =  cv_1
        AND  msib.inventory_item_id              =  mmt.inventory_item_id
        AND  msib.organization_id                =  gn_organization_id
        AND  msib.segment1                       =  iimb.item_no
        AND  iimb.item_id                        =  ximb.item_id
-- == 2014/03/27 V1.13 Modified START ===============================================================
---- == 2009/09/08 V1.11 Added START ==================================================================
--        AND  mmt.transaction_date  BETWEEN ximb.start_date_active
--                                   AND     NVL(ximb.end_date_active, mmt.transaction_date)
---- == 2009/09/08 V1.11 Added END   ==================================================================
        AND  TRUNC(mmt.transaction_date)         BETWEEN ximb.start_date_active AND ximb.end_date_active
-- == 2014/03/27 V1.13 Modified END   ===============================================================
-- == 2009/05/21 V1.5 Added START ==================================================================
        AND  mmt.transaction_quantity            <  0
-- == 2009/05/21 V1.5 Added END   ==================================================================
-- == 2010/10/27 V1.12 Modified START ===============================================================
--      UNION
      UNION ALL
-- == 2010/10/27 V1.12 Modified END   ===============================================================
      --廃却
      SELECT  mmt.transaction_id
             ,DECODE(mmt.transaction_type_id,ln_haikyaku_b,ln_haikyaku
                     ,mmt.transaction_type_id ) transaction_type_id     -- 取引タイプID
             ,mmt.transaction_type_id         transaction_type_id_sub   -- 取引タイプIDサブ
             ,DECODE(mmt.transaction_type_id,ln_haikyaku
                    ,mtt.transaction_type_name,lv_tran_type_haikyaku)
                     transaction_type_name                              -- 取引タイプ名
             ,msi.attribute7                  out_base_code             -- 出庫拠点 
             ,SUBSTRB(hca.account_name,1,8)   out_base_name             -- 出庫拠点名
             ,NULL                            in_base_code              -- 入庫拠点 
             ,NULL                            in_base_name              -- 入庫拠点名
             ,mmt.transaction_date            transaction_date          -- 取引日
             ,mmt.attribute1                  slip_no                   -- 伝票No
             ,mmt.inventory_item_id           inventory_item_id         -- 品目ID
             ,msib.segment1                   item_no                   -- 品目コード
             ,ximb.item_short_name            item_short_name           -- 略称
-- == 2009/07/30 V2.0 Modified START ===============================================================
--             ,mmt.transaction_quantity        transaction_qty           -- 取引数量
             ,mmt.primary_quantity            transaction_qty           -- 基準単位数量
-- == 2009/07/30 V2.0 Modified END   ===============================================================
      FROM    mtl_material_transactions  mmt                            -- 資材取引
             ,mtl_transaction_types      mtt                            -- 取引タイプマスタ
             ,mtl_secondary_inventories  msi                            -- 保管場所マスタ
             ,hz_cust_accounts           hca                            -- 顧客マスタ１
             ,mtl_system_items_b         msib                           -- 品目マスタ
             ,ic_item_mst_b              iimb                           -- OPM品目マスタ  
             ,xxcmn_item_mst_b           ximb                           -- OPM品目アドオンマスタ
      WHERE  mmt.transaction_type_id             =  mtt.transaction_type_id
        AND  ( ( ( gr_param.transaction_type = ln_haikyaku ) AND 
               ( mmt.transaction_type_id IN (ln_haikyaku,ln_haikyaku_b) ) )
          OR ( ( gr_param.transaction_type IS NULL ) AND
               ( mmt.transaction_type_id IN (ln_haikyaku,ln_haikyaku_b) ) ) )
-- == 2010/10/27 V1.12 Modified START ===============================================================
--        AND  ( ( ( gr_param.a_day IS NULL ) AND 
--               ( TO_CHAR ( mmt.transaction_date, 'YYYYMM' ) = gr_param.year_month ) )
--          OR ( ( gr_param.a_day IS NOT NULL ) AND 
--               ( TO_CHAR ( mmt.transaction_date, 'YYYYMMDD' ) = gr_param.year_month||gr_param.a_day ) ) )
        AND   mmt.transaction_date              >=  gd_trans_date_from
        AND   mmt.transaction_date              <   gd_trans_date_to
-- == 2010/10/27 V1.12 Modified END   ===============================================================
        AND  mmt.subinventory_code               =  msi.secondary_inventory_name
-- == 2009/06/03 V1.8 Added START ===============================================================
        AND  mmt.organization_id                 =  msi.organization_id
-- == 2009/06/03 V1.8 Added END   ===============================================================
        AND  msi.attribute7                      =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
        AND  hca.account_number                  =  msi.attribute7
        AND  hca.customer_class_code             =  cv_1
        AND  msib.inventory_item_id              =  mmt.inventory_item_id
        AND  msib.organization_id                =  gn_organization_id
        AND  msib.segment1                       =  iimb.item_no
        AND  iimb.item_id                        =  ximb.item_id
-- == 2014/03/27 V1.13 Modified START ===============================================================
---- == 2009/09/08 V1.11 Added START ==================================================================
--        AND  mmt.transaction_date  BETWEEN ximb.start_date_active
--                                   AND     NVL(ximb.end_date_active, mmt.transaction_date)
---- == 2009/09/08 V1.11 Added END   ==================================================================
        AND  TRUNC(mmt.transaction_date)         BETWEEN ximb.start_date_active AND ximb.end_date_active
-- == 2014/03/27 V1.13 Modified END   ===============================================================
-- == 2010/10/27 V1.12 Modified START ===============================================================
--      UNION
      UNION ALL
-- == 2010/10/27 V1.12 Modified END   ===============================================================
      --工場倉替,工場返品
      SELECT  mmt.transaction_id
             ,DECODE(mmt.transaction_type_id,ln_kojo_henpin_b,ln_kojo_henpin,
                     ln_kojo_kuragae_b,ln_kojo_kuragae,
                     mmt.transaction_type_id) transaction_type_id       -- 取引タイプID
             ,mmt.transaction_type_id        transaction_type_id_sub    -- 取引タイプIDサブ
             ,DECODE(mmt.transaction_type_id,
                     ln_kojo_henpin,transaction_type_name,
                     ln_kojo_henpin_b,lv_tran_type_kojo_henpin,
                     ln_kojo_kuragae,transaction_type_name,
                     ln_kojo_kuragae_b,lv_tran_type_kojo_kuragae)
                     transaction_type_name                              -- 取引タイプ名
             ,msi.attribute7                 out_base_code              -- 出庫拠点 
             ,SUBSTRB(hca.account_name,1,8)  out_base_name              -- 出庫拠点名
             ,mmt.attribute2                 in_base_code               -- 入庫拠点(工場) 
             ,SUBSTRB(flv.description,1,8)   in_base_name               -- 入庫拠点名
             ,mmt.transaction_date           transaction_date           -- 取引日
-- == 2009/05/29 V1.7 Modified START ===============================================================
--             ,mmt.attribute1                 slip_no                    -- 伝票No
             ,TO_CHAR(gn_slip_number_mask + mmt.transaction_set_id)
                                             slip_no                    -- 伝票No
-- == 2009/05/29 V1.7 Modified END   ===============================================================
             ,mmt.inventory_item_id          inventory_item_id          -- 品目ID
             ,msib.segment1                  item_no                    -- 品目コード
             ,ximb.item_short_name           item_short_name            -- 略称
-- == 2009/07/30 V2.0 Modified START ===============================================================
--             ,mmt.transaction_quantity       transaction_qty            -- 取引数量
             ,mmt.primary_quantity           transaction_qty            -- 基準単位数量
-- == 2009/07/30 V2.0 Modified END   ===============================================================
      FROM    mtl_material_transactions  mmt                            -- 資材取引
             ,mtl_transaction_types      mtt                            -- 取引タイプマスタ
             ,mtl_secondary_inventories  msi                            -- 保管場所マスタ
             ,fnd_lookup_values          flv                            -- クイックコードマスタ
             ,hz_cust_accounts           hca                            -- 顧客マスタ
             ,mtl_system_items_b         msib                           -- 品目マスタ
             ,ic_item_mst_b              iimb                           -- OPM品目マスタ  
             ,xxcmn_item_mst_b           ximb                           -- OPM品目アドオンマスタ
      WHERE  mmt.transaction_type_id             =  mtt.transaction_type_id
        AND  ( ( ( gr_param.transaction_type = ln_kojo_henpin ) AND 
               ( mmt.transaction_type_id IN (ln_kojo_henpin,ln_kojo_henpin_b) ) )
          OR ( ( gr_param.transaction_type = ln_kojo_kuragae ) AND 
               ( mmt.transaction_type_id IN (ln_kojo_kuragae,ln_kojo_kuragae_b) ) )
          OR ( ( gr_param.transaction_type IS NULL ) AND
               ( mmt.transaction_type_id IN (ln_kojo_henpin,ln_kojo_henpin_b,ln_kojo_kuragae,ln_kojo_kuragae_b) ) ) )
-- == 2010/10/27 V1.12 Modified START ===============================================================
--        AND  ( ( ( gr_param.a_day IS NULL ) AND 
--               ( TO_CHAR ( mmt.transaction_date, 'YYYYMM' ) = gr_param.year_month ) )
--          OR ( ( gr_param.a_day IS NOT NULL ) AND 
--               ( TO_CHAR ( mmt.transaction_date, 'YYYYMMDD' ) = gr_param.year_month||gr_param.a_day ) ) )
        AND   mmt.transaction_date              >=  gd_trans_date_from
        AND   mmt.transaction_date              <   gd_trans_date_to
-- == 2010/10/27 V1.12 Modified END   ===============================================================
        AND  mmt.subinventory_code               =  msi.secondary_inventory_name
-- == 2009/06/03 V1.8 Added START ===============================================================
        AND  mmt.organization_id                 =  msi.organization_id
-- == 2009/06/03 V1.8 Added END   ===============================================================
        AND  msi.attribute7                      =  gt_base_num_tab(gn_base_loop_cnt).hca_cust_num
        AND  hca.account_number                  =  msi.attribute7
        AND  hca.customer_class_code             =  cv_1
        AND  flv.lookup_type                     =  cv_mfg_fctory_cd
        AND  flv.lookup_code                     =  mmt.attribute2
        AND  flv.enabled_flag                    =  cv_flag
        AND  flv.language                        =  USERENV( 'LANG' )
        AND  msib.inventory_item_id              =  mmt.inventory_item_id
        AND  msib.organization_id                =  gn_organization_id
        AND  msib.segment1                       =  iimb.item_no
        AND  iimb.item_id                        =  ximb.item_id
-- == 2014/03/27 V1.13 Modified START ===============================================================
---- == 2009/09/08 V1.11 Added START ==================================================================
--        AND  mmt.transaction_date  BETWEEN ximb.start_date_active
--                                   AND     NVL(ximb.end_date_active, mmt.transaction_date)
---- == 2009/09/08 V1.11 Added END   ==================================================================
        AND  TRUNC(mmt.transaction_date)         BETWEEN ximb.start_date_active AND ximb.end_date_active
-- == 2014/03/27 V1.13 Modified END   ===============================================================
-- == 2010/10/27 V1.12 Deleted START ===============================================================
--        ORDER BY out_base_code
--                ,in_base_code
--                ,transaction_date
--                ,slip_no
--                ,inventory_item_id
--                ,transaction_type_id
-- == 2010/10/27 V1.12 Deleted END   ===============================================================
      ;
--
    -- ローカル・レコード
    lr_info_kuragae_rec info_kuragae_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 取引タイプ名取得：倉替
    -- ===============================
    lv_tran_type_kuragae := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_kuragae);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：倉替
    -- ===============================
    ln_tran_type_kuragae := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_kuragae);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得：工場返品
    -- ===============================
    lv_tran_type_kojo_henpin := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_kojo_henpin);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_kojo_henpin IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_kojo_henpin
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：工場返品
    -- ===============================
    ln_tran_type_kojo_henpin := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_kojo_henpin);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_kojo_henpin IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_kojo_henpin
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得：工場返品振戻
    -- ===============================
    lv_tran_type_kojo_henpin_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_kojo_henpin_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_kojo_henpin_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_kojo_henpin_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：工場返品振戻
    -- ===============================
    ln_tran_type_kojo_henpin_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_kojo_henpin_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_kojo_henpin_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_kojo_henpin_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得：工場倉替
    -- ===============================
    lv_tran_type_kojo_kuragae := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_kojo_kuragae);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_kojo_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_kojo_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：工場倉替
    -- ===============================
    ln_tran_type_kojo_kuragae := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_kojo_kuragae);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_kojo_kuragae IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_kojo_kuragae
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得：工場倉替振戻
    -- ===============================
    lv_tran_type_kojo_kuragae_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_kojo_kuragae_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_kojo_kuragae_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_kojo_kuragae_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：工場倉替振戻
    -- ===============================
    ln_tran_type_kojo_kuragae_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_kojo_kuragae_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_kojo_kuragae_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_kojo_kuragae_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得：廃却
    -- ===============================
    lv_tran_type_haikyaku := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_haikyaku);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_haikyaku IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_haikyaku
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：廃却
    -- ===============================
    ln_tran_type_haikyaku := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_haikyaku);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_haikyaku IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_haikyaku
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプ名取得：廃却振戻
    -- ===============================
    lv_tran_type_haikyaku_b := xxcoi_common_pkg.get_meaning(cv_tran_type,cv_tran_type_haikyaku_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( lv_tran_type_haikyaku_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00022
                     ,iv_token_name1  => cv_token_lookup_type
                     ,iv_token_value1 => cv_tran_type
                     ,iv_token_name2  => cv_token_lookup_code
                     ,iv_token_value2 => cv_tran_type_haikyaku_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 取引タイプID取得：廃却振戻
    -- ===============================
    ln_tran_type_haikyaku_b := xxcoi_common_pkg.get_transaction_type_id(lv_tran_type_haikyaku_b);
    --
    -- リターンコードがNULLの場合はエラー
    IF ( ln_tran_type_haikyaku_b IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00012
                     ,iv_token_name1  => cv_token_tran_type
                     ,iv_token_value1 => lv_tran_type_haikyaku_b
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
-- == 2014/03/27 V1.13 Deleted START ===============================================================
--    -- 倉替出庫情報件数初期化
--    gn_kuragae_cnt := 0;
-- == 2014/03/27 V1.13 Deleted END   ===============================================================
--
    -- カーソルオープン
    OPEN  info_kuragae_cur(ln_tran_type_kojo_henpin
                          ,ln_tran_type_kojo_henpin_b
                          ,ln_tran_type_kojo_kuragae
                          ,ln_tran_type_kojo_kuragae_b
                          ,ln_tran_type_haikyaku
                          ,ln_tran_type_haikyaku_b
                          ,ln_tran_type_kuragae
                          ,cn_ido_order
                          ,lv_tran_type_kojo_henpin
                          ,lv_tran_type_kojo_kuragae
                          ,lv_tran_type_haikyaku);
    --
    <<ins_work_loop>>
    LOOP
    FETCH info_kuragae_cur INTO lr_info_kuragae_rec;
    EXIT WHEN info_kuragae_cur%NOTFOUND;
--
    -- 対象件数カウント
    gn_target_cnt :=  gn_target_cnt + 1;
    -- 運送費初期化
    ln_dlv_cost_budget_amt := 0;
    -- 営業原価初期化
    ln_discrete_cost := 0;
--
      -- ==============================================
      --  営業原価取得
      -- ==============================================
      xxcoi_common_pkg.get_discrete_cost(in_item_id       => lr_info_kuragae_rec.inventory_item_id   -- 品目ID
                                        ,in_org_id        => gn_mst_organization_id                  -- 在庫組織ID
                                        ,id_target_date   => lr_info_kuragae_rec.transaction_date    -- 取引日
                                        ,ov_discrete_cost => lv_discrete_cost                        -- 営業原価
                                        ,ov_retcode       => lv_retcode                              -- リターンコード
                                        ,ov_errbuf        => lv_errbuf                               -- エラーメッセージ
                                        ,ov_errmsg        => lv_errmsg);                             -- エラーメッセージ
--
      IF (lv_retcode <> cv_status_normal) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10293
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
-- == 2009/05/21 V1.5 Modified START ===============================================================
      -- 営業原価額の符号変換
--      ln_discrete_cost := TO_NUMBER(lv_discrete_cost)*lr_info_kuragae_rec.transaction_qty;
      ln_discrete_cost := ROUND(TO_NUMBER(lv_discrete_cost)*lr_info_kuragae_rec.transaction_qty);
-- == 2009/05/21 V1.5 Modified END   ===============================================================
--
      -- =====================================================
      -- 品目マスタ情報抽出処理(A-4)
      -- =====================================================
      get_item_data(
         it_item_no                 =>  lr_info_kuragae_rec.item_no -- 商品コード
-- == 2009/09/08 V1.11 Added START ==================================================================
        ,it_transaction_date        =>  lr_info_kuragae_rec.transaction_date    -- 取引日
-- == 2009/09/08 V1.11 Added END   ==================================================================
        ,ot_product_class           =>  lv_product_class            -- 商品分類
        ,ot_godds_classification    =>  lv_godds_classification     -- ケース入数
        ,ot_baracha_div             =>  lv_baracha_div              -- バラ茶区分
        ,ot_office_item_type        =>  lv_office_item_type         -- 本社商品区分
        ,ov_errbuf                  =>  lv_errbuf                   -- エラー・メッセージ
        ,ov_retcode                 =>  lv_retcode                  -- リターン・コード
        ,ov_errmsg                  =>  lv_errmsg                   -- ユーザー・エラー・メッセージ
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- バラ茶区分1:バラ茶または、本社商品区分'2'ドリンク以外の場合は次レコード
      IF(  ( lv_baracha_div      =  cn_baracya_type      )
        OR( lv_office_item_type <> cv_office_item_drink ) ) THEN
        -- スキップ件数
        gn_warn_cnt   := gn_warn_cnt + 1;
      ELSE
        -- ケース入数未取得
        IF( ( lv_godds_classification IS NULL )
          OR( lv_godds_classification = 0 ) )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcoi10292
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        -- 処理続行
        -- ================================================
        -- 数量(C/S)算出処理(A-5)
        -- ================================================
        get_cs_data(
           it_transaction_qty           =>  lr_info_kuragae_rec.transaction_qty  -- 数量
          ,it_godds_classification      =>  lv_godds_classification              -- ケース入数
          ,on_cs_qty                    =>  ln_cs_qty                            -- 数量（CS）
          ,ov_errbuf                    =>  lv_errbuf                            -- エラー・メッセージ
          ,ov_retcode                   =>  lv_retcode                           -- リターン・コード
          ,ov_errmsg                    =>  lv_errmsg                            -- ユーザー・エラー・メッセージ
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        --顧客マスタ情報抽出処理(A-6)
        -- ================================================
        get_cust_mst_info(
           it_base_code              =>   lr_info_kuragae_rec.out_base_code -- 拠点コード
          ,ot_base_major_division    =>   lv_base_major_division            -- 拠点大分類
          ,ov_errbuf                 =>   lv_errbuf                         -- エラー・メッセージ
          ,ov_retcode                =>   lv_retcode                        -- リターン・コード
          ,ov_errmsg                 =>   lv_errmsg                         -- ユーザー・エラー・メッセージ
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- ドリンク振替運賃アドオンマスタ情報抽出処理(A-7)
        -- ================================================
        get_drink_data(
           it_transaction_date          =>   lr_info_kuragae_rec.transaction_date  -- 取引日
          ,it_base_code                 =>   lr_info_kuragae_rec.out_base_code     -- 出庫拠点コード
          ,it_product_class             =>   lv_product_class                      -- 商品分類
          ,it_base_major_division       =>   lv_base_major_division                -- 拠点大分類
          ,ot_set_unit_price            =>   ln_set_unit_price                     -- 設定単価
          ,ov_errbuf                    =>   lv_errbuf                     -- エラー・メッセージ
          ,ov_retcode                   =>   lv_retcode                    -- リターン・コード
          ,ov_errmsg                    =>   lv_errmsg                     -- ユーザー・エラー・メッセージ
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- 運送費算出処理(A-8)
        -- ================================================
-- == 2009/05/22 V1.6 Modified START ==================================================================
--        get_div_cost(
--           in_cs_qty                    =>   ln_cs_qty                -- 数量（CS）
--          ,it_set_unit_price            =>   ln_set_unit_price        -- 設定単価
--          ,on_dlv_cost_budget_amt       =>   ln_dlv_cost_budget_amt   -- 運送費予算金額
--          ,ov_errbuf                    =>   lv_errbuf                -- エラー・メッセージ
--          ,ov_retcode                   =>   lv_retcode               -- リターン・コード
--          ,ov_errmsg                    =>   lv_errmsg                -- ユーザー・エラー・メッセージ
--        );
--
        IF (lr_info_kuragae_rec.transaction_type_id = ln_tran_type_kuragae) THEN
          get_div_cost(
             in_cs_qty                    =>   ln_cs_qty                -- 数量（CS）
            ,it_set_unit_price            =>   ln_set_unit_price        -- 設定単価
            ,on_dlv_cost_budget_amt       =>   ln_dlv_cost_budget_amt   -- 運送費予算金額
            ,ov_errbuf                    =>   lv_errbuf                -- エラー・メッセージ
            ,ov_retcode                   =>   lv_retcode               -- リターン・コード
            ,ov_errmsg                    =>   lv_errmsg                -- ユーザー・エラー・メッセージ
          );
        END IF;
-- == 2009/05/22 V1.6 Modified END   ==================================================================
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;

      -- ==============================================
      --  ワークテーブルデータ登録(A-9)
      -- ==============================================
      ins_work(
          lr_info_kuragae_rec.out_base_code             -- 出庫拠点
         ,lr_info_kuragae_rec.out_base_name             -- 出庫拠点名
         ,lr_info_kuragae_rec.transaction_type_id       -- 取引タイプID
         ,lr_info_kuragae_rec.transaction_type_name     -- 取引タイプ名
         ,lr_info_kuragae_rec.transaction_type_id_sub   -- 取引タイプサブID
         ,lr_info_kuragae_rec.in_base_code              -- 入庫拠点
         ,lr_info_kuragae_rec.in_base_name              -- 入庫拠点名
         ,lr_info_kuragae_rec.transaction_date          -- 取引日
         ,lr_info_kuragae_rec.item_no                   -- 商品
         ,lr_info_kuragae_rec.item_short_name           -- 略称
         ,lr_info_kuragae_rec.slip_no                   -- 伝票No
         ,NVL(lr_info_kuragae_rec.transaction_qty,0)*-1 -- 取引数量
         ,ln_discrete_cost*-1                           -- 営業原価額
         ,NVL(ln_dlv_cost_budget_amt,0)*-1              -- 振替運送費
         ,NULL                                          -- ０件メッセージ
         ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
         ,lv_retcode           -- リターン・コード             --# 固定 #
         ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt ;
      END IF;
--
    END LOOP;
--    
    -- カーソルクローズ
    CLOSE info_kuragae_cur;
--
    -- コミット処理
    COMMIT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_kuragae_cur%ISOPEN ) THEN
        CLOSE info_kuragae_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_kuragae_cur%ISOPEN ) THEN
        CLOSE info_kuragae_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_kuragae_cur%ISOPEN ) THEN
        CLOSE info_kuragae_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_kuragae_cur%ISOPEN ) THEN
        CLOSE info_kuragae_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_kuragae_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : 拠点情報取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_data'; -- プログラム名
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
    -- 拠点情報(管理元拠点)
    CURSOR info_base1_cur
    IS
      SELECT hca.account_number account_num                         -- 顧客コード
      FROM   hz_cust_accounts hca                                   -- 顧客マスタ
            ,xxcmm_cust_accounts xca                                -- 顧客追加情報アドオンマスタ
      WHERE  hca.cust_account_id = xca.customer_id
        AND  hca.customer_class_code = cv_1
        AND  hca.account_number = NVL( gr_param.out_kyoten,hca.account_number )
        AND  xca.management_base_code = gv_base_code
      ORDER BY hca.account_number
    ;
--    
    -- 拠点情報(商品部)
    CURSOR info_base2_cur
    IS
      SELECT  hca.account_number account_num                         -- 顧客コード
        FROM  hz_cust_accounts hca                                   -- 顧客マスタ
       WHERE  hca.customer_class_code = cv_1
         AND  hca.account_number = NVL( gr_param.out_kyoten,hca.account_number )
       ORDER BY hca.account_number
    ;
--
    -- *** ローカル・レコード ***
-- == 2014/03/27 V1.13 Deleted START ===============================================================
--    lr_info_base1_rec   info_base1_cur%ROWTYPE;
--    lr_info_base2_rec   info_base2_cur%ROWTYPE;
-- == 2014/03/27 V1.13 Deleted END   ===============================================================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 管理元拠点で起動の時
    IF ( gr_param.output_dpt = cv_2 ) THEN
      OPEN info_base1_cur;
--
      -- レコード読み込み
      FETCH info_base1_cur BULK COLLECT INTO gt_base_num_tab;
      -- 拠点コード件数
      gn_base_cnt := gt_base_num_tab.COUNT;
      -- カーソルクローズ
      CLOSE info_base1_cur;
--
    -- 拠点・商品部で起動の時
    ELSIF ( ( gr_param.output_dpt = cv_1 ) OR ( gr_param.output_dpt = cv_3 ) ) THEN
      OPEN info_base2_cur;
      -- レコード読み込み
      FETCH info_base2_cur BULK COLLECT INTO gt_base_num_tab;
      -- 拠点コード件数
      gn_base_cnt := gt_base_num_tab.COUNT;
      -- カーソルクローズ
      CLOSE info_base2_cur;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがOPENしている場合
      IF ( info_base1_cur%ISOPEN ) THEN
        CLOSE info_base1_cur;
      ELSIF ( info_base2_cur%ISOPEN ) THEN
        CLOSE info_base2_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_base_data;
--
    /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)  := 'init';                      -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 定数
-- == 2014/03/27 V1.13 Deleted START ===============================================================
--    cv_01                   CONSTANT VARCHAR2(2)    := '01';                            -- 妥当性チェック用(1月)
--    cv_12                   CONSTANT VARCHAR2(2)    := '12';                            -- 妥当性チェック用(12月)
-- == 2014/03/27 V1.13 Deleted END   ===============================================================
    cv_mstorg_code          CONSTANT VARCHAR2(30)   := 'XXCOI1_MST_ORGANIZATION_CODE';  -- プロファイル名(マスタ組織コード)
    cv_profile_name         CONSTANT VARCHAR2(24)   := 'XXCOI1_ORGANIZATION_CODE';      -- プロファイル名(在庫組織コード)
    cv_item_div_h           CONSTANT VARCHAR2(30)   := 'XXCOS1_ITEM_DIV_H';             -- XXCOS:本社商品区分
-- == 2009/05/29 V1.7 Added START ===============================================================
    cv_prf_slip_number_mask CONSTANT VARCHAR2(30)   := 'XXCOI1_SLIP_NUMBER_MASK';       -- プロファイル名（伝票番号マスク）
-- == 2009/05/29 V1.7 Added END   ===============================================================
-- == 2015/03/16 V1.14 Added START ==============================================================
    cv_prf_inv_cl_char      CONSTANT VARCHAR2(30) :=  'XXCOI1_INV_CL_CHARACTER';        -- プロファイル名（在庫確定印字文字）
-- == 2015/03/16 V1.14 Added END   ==============================================================
--
    -- *** ローカル変数 ***
    lv_organization_code     mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
    lv_mst_organization_code mtl_parameters.organization_code%TYPE;  -- マスタ組織コード
    ld_date                  DATE;
-- == 2015/03/16 V1.14 Added START ==============================================================
    lb_chk_result            BOOLEAN DEFAULT TRUE;                   -- 在庫会計期間チェック結果
-- == 2015/03/16 V1.14 Added END   ==============================================================
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
    -- =====================================
    -- 業務日付取得(共通関数)
    -- =====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- 業務日付が取得できない場合はエラー
    IF ( gd_process_date IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00011
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- パラメータ妥当性チェック(日)
    -- =====================================
    -- パラメータ.日がNULLでない場合
    IF gr_param.a_day IS NOT NULL THEN
      --
-- == 2009/09/08 V1.11 Added END   ==================================================================
--      IF ( ( gr_param.a_day < cv_01 ) OR ( gr_param.a_day  > cv_31 ) ) THEN
      IF (   (TO_NUMBER(gr_param.a_day) < 1)
          OR (TO_NUMBER(gr_param.a_day) > 31)
         )
      THEN
-- == 2009/09/08 V1.11 Added END   ==================================================================
          
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10070
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_value_expt;
      ELSE 
        -- パラメータ.日が1桁だったら、前に0を付加
        IF length(gr_param.a_day) = 1 THEN
          gr_param.a_day := cv_0||gr_param.a_day; 
        END IF;
        -- 
        -- パラメータ.年月とパラメータ.日を結合し日付の妥当性チェックを行う
        ld_date := TO_DATE((gr_param.year_month||gr_param.a_day),'YYYYMMDD');
        --
        -- パラメータ.年月とパラメータ.日を結合し、業務日付と比較
        IF ( TO_CHAR( ( gd_process_date ), 'YYYYMMDD' ) < 
            ( gr_param.year_month||gr_param.a_day ) ) THEN
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcoi10003
                      );
          lv_errbuf := lv_errmsg;
          RAISE get_value_expt;
        END IF;
      END IF;
    END IF;
--    
    -- パラメータ.日がNULLの場合
    IF gr_param.a_day IS NULL THEN
      -- パラメータ.年月と業務日付(年月)を比較
      IF ( TO_CHAR( ( gd_process_date ), 'YYYYMM' ) < ( gr_param.year_month ) ) THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcoi10003
                    );
        lv_errbuf := lv_errmsg;
        RAISE get_value_expt;
      END IF;
    END IF;
--
    -- =====================================
    -- プロファイル値取得(在庫組織コード)
    -- =====================================
    lv_organization_code := FND_PROFILE.VALUE(cv_profile_name);
    IF ( lv_organization_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00005
                     ,iv_token_name1  => cv_token_pro
                     ,iv_token_value1 => cv_profile_name
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- 在庫組織ID取得
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
    IF ( gn_organization_id IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00006
                     ,iv_token_name1  => cv_token_org_code
                     ,iv_token_value1 => lv_organization_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;         
--
    -- =====================================
    -- プロファイル値取得(マスタ組織コード)
    -- =====================================
    lv_mst_organization_code := FND_PROFILE.VALUE(cv_mstorg_code);
    IF ( lv_mst_organization_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00030
                     ,iv_token_name1  => cv_token_pro
                     ,iv_token_value1 => cv_mstorg_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;         
--
    -- =====================================
    -- マスタ品目組織ID取得
    -- =====================================
    gn_mst_organization_id := xxcoi_common_pkg.get_organization_id(lv_mst_organization_code);
    IF ( gn_mst_organization_id IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00031
                     ,iv_token_name1  => cv_token_mst_org_code
                     ,iv_token_value1 => lv_mst_organization_code
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;         
--    
    -- =====================================
    -- 所属拠点取得
    -- =====================================
    gv_base_code := xxcoi_common_pkg.get_base_code( 
                        in_user_id     => cn_created_by     -- ユーザーID
                       ,id_target_date => gd_process_date); -- 対象日
    IF ( gv_base_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi10092);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================================
    -- 本社商品区分名取得
    -- =====================================
    gv_item_div_h := FND_PROFILE.VALUE( cv_item_div_h );
    IF ( gv_item_div_h IS NULL ) THEN
      -- エラーメッセージ
      lv_errmsg := xxcmn_common_pkg.get_msg( 
-- == 2014/03/27 V1.13 Modified START ==================================================================
--                      iv_application  => cv_app_name
--                     ,iv_name         => cv_msg_xxcoi10092);
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcoi00032
                     ,iv_token_name1  => cv_token_pro
                     ,iv_token_value1 => cv_item_div_h
                  );
-- == 2014/03/27 V1.13 Modified END   ==================================================================
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;    
    --==============================================================
    -- コンカレント入力パラメータ出力
    --==============================================================
    -- パラメータ.取引タイプ
    IF( gr_param.transaction_type IS NOT NULL ) THEN
      SELECT transaction_type_name
      INTO   gv_transaction_type_name
      FROM   mtl_transaction_types
      WHERE  transaction_type_id = gr_param.transaction_type;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10066
                    ,iv_token_name1  => cv_token_transaction_type
                    ,iv_token_value1 => gv_transaction_type_name
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- パラメータ.年月日
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10067
                    ,iv_token_name1  => cv_token_date
                    ,iv_token_value1 => gr_param.year_month||gr_param.a_day
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
    -- パラメータ.出庫拠点
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_app_name
                    ,iv_name         =>  cv_msg_xxcoi10068
                    ,iv_token_name1  => cv_token_base_code
                    ,iv_token_value1 => gr_param.out_kyoten
                  );
    fnd_file.put_line(
      which  => FND_FILE.LOG
    , buff   => gv_out_msg
    );
--
-- == 2009/05/13 V1.1 Added START ===============================================================
    -- ===============================
    -- 伝票№マスク取得
    -- ===============================
    gn_slip_number_mask  :=  TO_NUMBER(fnd_profile.value( cv_prf_slip_number_mask ));
    -- 共通関数の戻り値がNULLの場合、またはパラメータ.在庫組織コードと相違する場合
    IF (gn_slip_number_mask IS NULL) THEN
      -- 伝票№マスク取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                     , iv_name         => cv_msg_xxcoi10381
                     , iv_token_name1  => cv_token_pro
                     , iv_token_value1 => cv_prf_slip_number_mask
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- == 2009/05/13 V1.1 Added END   ===============================================================
--
-- == 2010/10/27 V1.12 Added START ===============================================================
    --  取引日はXX以上(>=)、XX未満(<)で範囲指定する
    -- ===============================
    -- 対象取引日指定
    -- ===============================
    IF  (gr_param.a_day IS NULL)  THEN
      --  月指定のみの場合、指定月１日から翌月１日
      gd_trans_date_from    :=  TRUNC(TO_DATE(gr_param.year_month || '01', 'YYYYMMDD'));
      gd_trans_date_to      :=  ADD_MONTHS(gd_trans_date_from, 1);
    ELSE
      --  日付指定ありの場合、指定年月日から翌日
      gd_trans_date_from    :=  TRUNC(TO_DATE(gr_param.year_month || gr_param.a_day, 'YYYYMMDD'));
      gd_trans_date_to      :=  gd_trans_date_from + 1;
    END IF;
-- == 2010/10/27 V1.12 Added END   ===============================================================
-- == 2015/03/16 V1.14 Added START ==============================================================
    --====================================
    -- 在庫会計期間チェック
    --====================================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gn_organization_id
      , id_target_date     => gd_trans_date_to - 1
      , ob_chk_result      => lb_chk_result
      , ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                     , iv_name         => cv_msg_xxcoi00026
                     , iv_token_name1  => cv_token_target_data
                     , iv_token_value1 => TO_CHAR(gd_trans_date_to - 1, cv_format_yyyymmdd)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --====================================
    -- 帳票印字文字取得
    --====================================
    IF NOT(lb_chk_result) THEN
      gt_inv_cl_char := FND_PROFILE.VALUE(cv_prf_inv_cl_char);
      --
      IF ( gt_inv_cl_char IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                       , iv_name         => cv_msg_xxcoi10451
                       , iv_token_name1  => cv_token_pro
                       , iv_token_value1 => cv_prf_inv_cl_char
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
-- == 2015/03/16 V1.14 Added END   ==============================================================
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    --*** 値エラー ***
    WHEN get_value_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_transaction_type  IN  VARCHAR2,         --   1.取引タイプ
    iv_year_month        IN  VARCHAR2,         --   2.年月
    iv_day               IN  VARCHAR2,         --   3.日
    iv_out_kyoten        IN  VARCHAR2,         --   4.出庫拠点
    iv_output_dpt        IN  VARCHAR2,         --   5.帳票出力場所
    ov_errbuf            OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_nodata_msg VARCHAR2(50);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
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
    -- =====================================================
    -- パラメータ値の格納
    -- =====================================================

    gr_param.transaction_type  := TO_NUMBER(iv_transaction_type); -- 01 : 取引タイプ    (任意)
    gr_param.year_month        := SUBSTRB(iv_year_month,1,4)
                                  ||SUBSTRB(iv_year_month,6,7);  -- 02 : 処理年月      (必須)
    gr_param.a_day             := iv_day;                        -- 03 : 処理日        (任意)
    gr_param.out_kyoten        := iv_out_kyoten;                 -- 04 : 出庫拠点     （任意)
    gr_param.output_dpt        := iv_output_dpt;                 -- 05 : 出力場所      (必須)
--
    -- =====================================================
    -- 初期処理(A-1)
    -- =====================================================
    init(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- 拠点情報取得処理(A-2)
    -- =====================================================
    get_base_data(
        lv_errbuf            -- エラー・メッセージ           --# 固定 #
      , lv_retcode           -- リターン・コード             --# 固定 #
      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 拠点情報が１件以上取得出来た場合
    IF ( gn_base_cnt > 0 ) THEN
--
      -- 拠点単位ループ開始
      <<gt_param_tab_loop>>
       FOR gn_base_loop_cnt IN 1 .. gn_base_cnt LOOP
--
         -- =====================================================
         -- 倉替出庫明細データ取得(A-3)
         -- =====================================================
         get_kuragae_data(
             gn_base_loop_cnt
            ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
            ,lv_retcode           -- リターン・コード             --# 固定 #
            ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
         );
         IF ( lv_retcode = cv_status_error ) THEN
           -- エラー処理
           RAISE global_process_expt ;
         END IF;
--
       END LOOP gt_param_tab_loop;
    END IF;
--
    -- 出力対象件数が0件の場合、ワークテーブルにパラメータ情報のみを登録
    IF (gn_target_cnt = 0) THEN
--
      -- 0件メッセージの取得
      lv_nodata_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcoi00008
                         );
--
      -- ==============================================
      --  ワークテーブルデータ登録(A-4)
      -- ==============================================
      ins_work(
          NULL                                      -- 出庫拠点
         ,NULL                                      -- 出庫拠点名
         ,NULL                                      -- 取引タイプID
         ,gv_transaction_type_name                  -- 取引タイプ名
         ,NULL                                      -- 取引タイプサブID
         ,NULL                                      -- 入庫拠点
         ,NULL                                      -- 入庫拠点名
         ,NULL                                      -- 取引日
         ,NULL                                      -- 商品
         ,NULL                                      -- 商品名
         ,NULL                                      -- 伝票No
         ,NULL                                      -- 取引数量
         ,NULL                                      -- 営業原価額
         ,NULL                                      -- 振替運送費
         ,lv_nodata_msg                             -- 0件メッセージ
         ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
         ,lv_retcode           -- リターン・コード             --# 固定 #
         ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- 終了パラメータ判定
      IF ( lv_retcode = cv_status_error ) THEN
        -- エラー処理
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =====================================================
    -- SVF起動(A-5)
    -- =====================================================
    svf_request(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- ワークテーブルデータ削除(A-6)
    -- =====================================================
    del_work(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- 正常終了件数
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- 処理件数
      gn_error_cnt  :=  gn_error_cnt + 1;
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
    errbuf               OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode              OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_transaction_type  IN  VARCHAR2,      --   1.取引タイプ
    iv_year_month        IN  VARCHAR2,      --   2.年月
    iv_day               IN  VARCHAR2,      --   3.日
    iv_out_kyoten        IN  VARCHAR2,      --   4.出庫拠点
    iv_output_dpt        IN  VARCHAR2)      --   5.帳票出力場所
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
       iv_which   =>  cv_log
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
       iv_transaction_type  --   1.取引タイプ
      ,iv_year_month        --   2.年月
      ,iv_day               --   3.日
      ,iv_out_kyoten        --   4.出庫拠点
      ,iv_output_dpt        --   5.帳票出力場所
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
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
END XXCOI009A02R;
/
