CREATE OR REPLACE PACKAGE BODY XXCMN800014C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMN800014C(body)
 * Description      : 生産バッチ情報をCSVファイル出力し、ワークフロー形式で連携します。
 * MD.050           : 生産バッチ情報インタフェース<T_MD050_BPO_801>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理                              (A-1)
 *  output_data            データ取得・CSV出力処理               (A-2)
 *  submain                 メイン処理プロシージャ
 *                         終了処理                              (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/07/11    1.0   S.Yamashita      新規作成
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
  cv_msg_sla                CONSTANT VARCHAR2(3) := '／';
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCMN800014C';         -- パッケージ名
  -- メッセージ関連
  cv_app_xxcmn                CONSTANT VARCHAR2(30)  := 'XXCMN';                -- アプリケーション短縮名(生産:マスタ)
  cv_msg_xxcmn_11044          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11044';      -- 生産バッチ情報連携パラメータ
  cv_msg_xxcmn_11047          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11047';      -- 日付逆転エラー
  cv_msg_xxcmn_11048          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11048';      -- 対象データ未取得エラー
  cv_msg_xxcmn_11055          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11055';      -- EOS宛先取得エラー
  -- トークン用メッセージ
  cv_msg_xxcmn_11045          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11045';      -- 完成品製造日(FROM)
  cv_msg_xxcmn_11046          CONSTANT VARCHAR2(16)  := 'APP-XXCMN-11046';      -- 完成品製造日(TO)
  --トークン
  cv_tkn_batch_no             CONSTANT VARCHAR2(20)  := 'BATCH_NO';             -- 入力パラメータ（バッチNO）
  cv_tkn_whse_code            CONSTANT VARCHAR2(20)  := 'WHSE_CODE';            -- 入力パラメータ（倉庫コード）
  cv_tkn_production_date_from CONSTANT VARCHAR2(20)  := 'PRODUCTION_DATE_FROM'; -- 入力パラメータ（完成品製造日(FROM)）
  cv_tkn_production_date_to   CONSTANT VARCHAR2(20)  := 'PRODUCTION_DATE_TO';   -- 入力パラメータ（完成品製造日(TO)）
  cv_tkn_p_routing            CONSTANT VARCHAR2(20)  := 'ROUTING';              -- 入力パラメータ（ラインNo）
  cv_tkn_from                 CONSTANT VARCHAR2(20)  := 'FROM';                 -- 日付（FROM）
  cv_tkn_to                   CONSTANT VARCHAR2(20)  := 'TO';                   -- 日付（TO）
  cv_tkn_ng_profile           CONSTANT VARCHAR2(20)  := 'NG_PROFILE';           -- プロファイル
--
  -- 言語コード
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  --フォーマット
  cv_fmt_month          CONSTANT VARCHAR2(30)  := 'YYYYMM';
  cv_fmt_date           CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD';
  cv_fmt_datetime       CONSTANT VARCHAR2(30)  := 'YYYYMMDDHH24MISS';
  cv_fmt_datetime2      CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';
  -- WF関連
  cv_ope_div_10         CONSTANT VARCHAR2(2)   := '10';  -- 処理区分:10(生産バッチ情報)
  cv_wf_class_1         CONSTANT VARCHAR2(1)   := '1';   -- 対象:1(外部倉庫)
  cv_eos_flag_1         CONSTANT VARCHAR2(1)   := '1';   -- EOS管理対象:1(対象）
  -- その他
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';   -- フラグ:'Y'
  cv_space              CONSTANT VARCHAR2(1)   := ' ';   -- 半角スペース１桁
  cv_separate_code      CONSTANT VARCHAR2(1)   := ',';   -- 区切り文字（カンマ）
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- ===============================
  -- カーソル定義
  -- ===============================
  -- 生産バッチ情報抽出
  CURSOR g_batch_info_cur ( iv_p_batch_no       VARCHAR2 -- バッチNO
                           ,iv_p_whse_code      VARCHAR2 -- 倉庫コード
                           ,iv_p_prod_date_from VARCHAR2 -- 完成品製造日(FROM)
                           ,iv_p_prod_date_to   VARCHAR2 -- 完成品製造日(TO)
                           ,iv_p_routing        VARCHAR2 -- ラインNo
                          )
  IS
    SELECT xsh.バッチNO              AS batch_no
          ,xsh.プラントコード        AS plant_code
          ,xsh.工順                  AS routing_no
          ,xsh.業務ステータス        AS business_status
          ,xsh.計画完了日            AS plan_cmplt_date
          ,xsh.実績完了日            AS actual_cmplt_date
          ,xsh.削除マーク            AS delete_mark
          ,xsh.伝票区分              AS invoice_type
          ,xsh.成績管理部署          AS result_manage_dept
          ,xsh.完成品_品目コード     AS prod_item_no
          ,xsh.完成品_ロットNO       AS prod_lot_no
          ,xsh.完成品_タイプ         AS prod_item_type
          ,xsh.完成品_製造年月日     AS prod_producted_date
          ,xsh.完成品_固有記号       AS prod_uniqe_sign
          ,xsh.完成品_賞味期限日     AS prod_use_by_date
          ,xsh.完成品_生産日         AS prod_manufactured_date
          ,xsh.完成品_原料入庫日     AS prod_material_stored_date
          ,xsh.完成品_実績数量       AS prod_actual_qty
          ,xsh.完成品_単位           AS prod_item_um
          ,xsh.完成品_ランク１       AS prod_rank1
          ,xsh.完成品_ランク２       AS prod_rank2
          ,xsh.完成品_ランク３       AS prod_rank3
          ,xsh.完成品_摘要           AS prod_discription
          ,xsh.完成品_在庫入数       AS prod_in_qty
          ,xsh.完成品_依頼総数       AS prod_request_qty
          ,xsh.完成品_指図総数       AS prod_instruct_qty
          ,xsh.完成品_移動場所コード AS prod_move_location
          ,TO_DATE( xsh.最終更新日, cv_fmt_datetime2 ) AS h_last_update_date
          ,xsl.ラインNO              AS line_no
          ,xsl.品目コード            AS item_no
          ,xsl.ロットNO              AS lot_no
          ,xsl.製造年月日            AS producted_date
          ,xsl.固有記号              AS uniqe_sign
          ,xsl.賞味期限日            AS use_by_date
          ,xsl.ラインタイプ          AS line_type
          ,xsl.タイプ                AS item_type
          ,xsl.投入口区分            AS inlet_type
          ,xsl.打込区分              AS actual_qty
          ,xsl.生産日                AS manufactured_date
          ,xsl.原料入庫日            AS material_stored_date
          ,xsl.単位                  AS item_um
          ,xsl.ランク１              AS rank1
          ,xsl.ランク２              AS rank2
          ,xsl.ランク３              AS rank3
          ,xsl.摘要                  AS discription
          ,xsl.在庫入数              AS in_qty
          ,xsl.依頼総数              AS request_qty
          ,xsl.原料削除フラグ        AS material_del_flag
          ,xsl.ロット_指示総数       AS lot_instruct_qty
          ,xsl.ロット_投入数量       AS lot_input_qty
          ,xsl.ロット_予定区分       AS lot_plan_type
          ,xsl.ロット_予定番号       AS lot_plan_num
          ,TO_DATE( xsl.最終更新日, cv_fmt_datetime2 ) AS l_last_update_date
    FROM   xxsky_生産ヘッダ_基本_v xsh
          ,xxsky_生産明細_基本_v   xsl
          ,xxsky_工順マスタ_基本_v xkm
    WHERE  xsh.工順 = xkm.工順番号
    AND    xsh.バッチNO             = xsl.バッチNO
    AND    xsh.プラントコード       = xsl.プラントコード
    AND    xkm.生産バッチ情報IF対象フラグ = cv_y
    AND    ( (iv_p_batch_no IS NULL)  OR (xsh.バッチNO = iv_p_batch_no) ) -- バッチNO
    AND    xsh.WIP倉庫 = iv_p_whse_code                                   -- 倉庫コード
    AND    NVL( TO_DATE( xsh.完成品_製造年月日, cv_fmt_date ) , xsh.計画開始日 )
             >= TO_DATE( iv_p_prod_date_from, cv_fmt_date )               -- 完成品製造日(FROM)
    AND    NVL( TO_DATE( xsh.完成品_製造年月日, cv_fmt_date ) , xsh.計画開始日 )
             <= TO_DATE( iv_p_prod_date_to, cv_fmt_date )                 -- 完成品製造日(TO)
    AND    ( (iv_p_routing IS NULL) OR (xsh.工順 = iv_p_routing) )        -- ラインNo
    ORDER BY xsh.バッチNO
            ,xsl.ラインタイプ
            ,xsl.品目コード
            ,xsl.ロットNO
  ;
  -- レコード型
  g_batch_info_rec  g_batch_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   **********************************************************************************/
  PROCEDURE init(
    iv_batch_no               IN  VARCHAR2  -- 1.バッチNO
   ,iv_whse_code              IN  VARCHAR2  -- 2.倉庫コード
   ,iv_production_date_from   IN  VARCHAR2  -- 3.完成品製造日(FROM)
   ,iv_production_date_to     IN  VARCHAR2  -- 4.完成品製造日(TO)
   ,iv_routing                IN  VARCHAR2  -- 5.ラインNo
   ,ov_errbuf                 OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg                 OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_production_date_from VARCHAR2(100); -- 完成品製造日(FROM)
    lv_production_date_to   VARCHAR2(100); -- 完成品製造日(TO)
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
    --==================================
    -- パラメータ出力
    --==================================
    lv_errmsg := xxcmn_common_pkg.get_msg(
                   iv_application        => cv_app_xxcmn
                  ,iv_name               => cv_msg_xxcmn_11044
                  ,iv_token_name1        => cv_tkn_batch_no
                  ,iv_token_value1       => iv_batch_no
                  ,iv_token_name2        => cv_tkn_whse_code
                  ,iv_token_value2       => iv_whse_code
                  ,iv_token_name3        => cv_tkn_production_date_from
                  ,iv_token_value3       => iv_production_date_from
                  ,iv_token_name4        => cv_tkn_production_date_to
                  ,iv_token_value4       => iv_production_date_to
                  ,iv_token_name5        => cv_tkn_p_routing
                  ,iv_token_value5       => iv_routing
                 );
--
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_errmsg
    );
    --1行空白
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => NULL
    );
--
    --==================================
    -- 日付逆転チェック
    --==================================
    IF ( TO_DATE( iv_production_date_from, cv_fmt_date ) > TO_DATE( iv_production_date_to, cv_fmt_date ) ) THEN
      -- トークン取得
      lv_production_date_from := xxcmn_common_pkg.get_msg(
                                   iv_application  => cv_app_xxcmn
                                  ,iv_name         => cv_msg_xxcmn_11045
                                 );
      lv_production_date_to   := xxcmn_common_pkg.get_msg(
                                   iv_application  => cv_app_xxcmn
                                  ,iv_name         => cv_msg_xxcmn_11046
                                 );
      -- 日付逆転チェックエラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_app_xxcmn
                    ,iv_name         => cv_msg_xxcmn_11047
                    ,iv_token_name1  => cv_tkn_from
                    ,iv_token_value1 => lv_production_date_from
                    ,iv_token_name2  => cv_tkn_to
                    ,iv_token_value2 => lv_production_date_to
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START  #######################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : CSV出力処理 (A-2)
   **********************************************************************************/
  PROCEDURE output_data(
    iv_batch_no               IN  VARCHAR2  -- 1.バッチNO
   ,iv_whse_code              IN  VARCHAR2  -- 2.倉庫コード
   ,iv_production_date_from   IN  VARCHAR2  -- 3.完成品製造日(FROM)
   ,iv_production_date_to     IN  VARCHAR2  -- 4.完成品製造日(TO)
   ,iv_routing                IN  VARCHAR2  -- 5.ラインNo
   ,ov_errbuf                 OUT VARCHAR2  -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode                OUT VARCHAR2  -- リターン・コード                    --# 固定 #
   ,ov_errmsg                 OUT VARCHAR2  -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
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
    cv_data_type_700    CONSTANT VARCHAR2(3) := '700';   -- データ種別:700(生産バッチ情報)
    cv_coop_name_itoen  CONSTANT VARCHAR2(5) := 'ITOEN'; -- 会社名:ITOEN
    cv_branch_no_10     CONSTANT VARCHAR2(2) := '10';    -- 伝送用枝番:10(ヘッダ)
    cv_branch_no_20     CONSTANT VARCHAR2(2) := '20';    -- 伝送用枝番:20(明細)
--
    -- *** ローカル変数 ***
    lr_wf_whs_rec       xxwsh_common3_pkg.wf_whs_rec; -- ファイル情報格納レコード
    lf_file_hand        UTL_FILE.FILE_TYPE;           -- ファイル・ハンドル
    lt_prev_batch_no    gme_batch_header.batch_no%TYPE;   -- 前レコードのバッチNO
    lt_eos_dist         ic_whse_mst.orgn_code%TYPE;       -- EOS宛先
    lv_file_name        VARCHAR2(150);  -- ファイル名
    lv_csv_data         VARCHAR2(4000); -- CSV文字列
    ln_cnt              NUMBER;         -- 対象件数
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    lv_csv_data        := NULL;
    lt_prev_batch_no   := NULL;
    lt_eos_dist        := NULL;
--
    -- 宛先情報取得
    BEGIN
      SELECT xilv.eos_detination AS eos_detination -- EOS宛先
      INTO   lt_eos_dist
      FROM   xxcmn_item_locations_v xilv  -- OPM保管場所情報VIEW
      WHERE  xilv.whse_code        = iv_whse_code  -- 倉庫コード
      AND    xilv.eos_control_type = cv_eos_flag_1 -- EOS管理対象
      AND    ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- EOS宛先取得エラー
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_app_xxcmn
                      ,iv_name         => cv_msg_xxcmn_11055
                      ,iv_token_name1  => cv_tkn_whse_code
                      ,iv_token_value1 => iv_whse_code
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- 共通関数「アウトバウンド処理取得関数」呼出
    xxwsh_common3_pkg.get_wsh_wf_info(
      iv_wf_ope_div       => cv_ope_div_10  -- 処理区分
     ,iv_wf_class         => cv_wf_class_1  -- 対象
     ,iv_wf_notification  => lt_eos_dist    -- 宛先
     ,or_wf_whs_rec       => lr_wf_whs_rec  -- ファイル情報
     ,ov_errbuf           => lv_errbuf      -- エラー・メッセージ
     ,ov_retcode          => lv_retcode     -- リターン・コード
     ,ov_errmsg           => lv_errmsg      -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ファイル名編集
    --==================================
    lv_file_name := cv_ope_div_10                                          -- 処理区分
                    || '-' || lt_eos_dist                                  -- 宛先
                    || '_' || TO_CHAR( SYSDATE, cv_fmt_datetime )          -- 処理時刻
                    || lr_wf_whs_rec.file_name                             -- ファイル名
    ;
--
    -- WFオーナーを起動ユーザへ変更
    lr_wf_whs_rec.wf_owner := fnd_global.user_name;
--
    --==================================
    -- ファイルオープン
    --==================================
    lf_file_hand := UTL_FILE.FOPEN( lr_wf_whs_rec.directory -- ディレクトリ
                                   ,lv_file_name            -- ファイル名
                                   ,'w' )                   -- モード（上書）
    ;
--
    --==================================
    -- 生産バッチ情報抽出
    --==================================
    <<batch_info_loop>>
    FOR g_batch_info_rec IN g_batch_info_cur ( iv_p_batch_no       => iv_batch_no             -- バッチNO
                                              ,iv_p_whse_code      => iv_whse_code            -- 倉庫コード
                                              ,iv_p_prod_date_from => iv_production_date_from -- 完成品製造日(FROM)
                                              ,iv_p_prod_date_to   => iv_production_date_to   -- 完成品製造日(TO)
                                              ,iv_p_routing        => iv_routing              -- ラインNo
                                             )
    LOOP
      -- 終了判定
      EXIT batch_info_loop WHEN g_batch_info_cur%NOTFOUND;
--
      --==================================
      -- 生産バッチ情報 CSV出力
      --==================================
--
      -- 1レコード目の場合、または、前レコードとバッチNOが異なる場合
      IF ( ( lt_prev_batch_no IS NULL )
        OR ( g_batch_info_rec.batch_no <> lt_prev_batch_no ))
      THEN
        -- ヘッダ行
        lv_csv_data :=                     cv_coop_name_itoen                         -- 会社名
                    || cv_separate_code || cv_data_type_700                           -- データ種別
                    || cv_separate_code || cv_branch_no_10                            -- 伝送用枝番
                    || cv_separate_code || g_batch_info_rec.batch_no                  -- バッチNO
                    || cv_separate_code || g_batch_info_rec.plant_code                -- プラントコード
                    || cv_separate_code || g_batch_info_rec.routing_no                -- 工順
                    || cv_separate_code || g_batch_info_rec.business_status           -- 業務ステータス
                    || cv_separate_code || TO_CHAR(g_batch_info_rec.plan_cmplt_date  , cv_fmt_date) -- 計画完了日
                    || cv_separate_code || TO_CHAR(g_batch_info_rec.actual_cmplt_date, cv_fmt_date) -- 実績完了日
                    || cv_separate_code || g_batch_info_rec.delete_mark               -- 削除マーク
                    || cv_separate_code || g_batch_info_rec.invoice_type              -- 伝票区分
                    || cv_separate_code || g_batch_info_rec.result_manage_dept        -- 成績管理部署
                    || cv_separate_code || g_batch_info_rec.prod_item_no              -- 完成品_品目コード
                    || cv_separate_code || g_batch_info_rec.prod_lot_no               -- 完成品_ロットNO
                    || cv_separate_code || g_batch_info_rec.prod_item_type            -- 完成品_タイプ
                    || cv_separate_code || g_batch_info_rec.prod_producted_date       -- 完成品_製造年月日
                    || cv_separate_code || g_batch_info_rec.prod_uniqe_sign           -- 完成品_固有記号
                    || cv_separate_code || g_batch_info_rec.prod_use_by_date          -- 完成品_賞味期限日
                    || cv_separate_code || g_batch_info_rec.prod_manufactured_date    -- 完成品_生産日
                    || cv_separate_code || g_batch_info_rec.prod_material_stored_date -- 完成品_原料入庫日
                    || cv_separate_code || g_batch_info_rec.prod_actual_qty           -- 完成品_実績数量
                    || cv_separate_code || g_batch_info_rec.prod_item_um              -- 完成品_単位
                    || cv_separate_code || g_batch_info_rec.prod_rank1                -- 完成品_ランク１
                    || cv_separate_code || g_batch_info_rec.prod_rank2                -- 完成品_ランク２
                    || cv_separate_code || g_batch_info_rec.prod_rank3                -- 完成品_ランク３
                    || cv_separate_code || g_batch_info_rec.prod_discription          -- 完成品_摘要
                    || cv_separate_code || g_batch_info_rec.prod_in_qty               -- 完成品_在庫入数
                    || cv_separate_code || g_batch_info_rec.prod_request_qty          -- 完成品_依頼総数
                    || cv_separate_code || g_batch_info_rec.prod_instruct_qty         -- 完成品_指図総数
                    || cv_separate_code || g_batch_info_rec.prod_move_location        -- 完成品_移動場所コード
                    || cv_separate_code || TO_CHAR(g_batch_info_rec.h_last_update_date, cv_fmt_date) -- ヘッダ最終更新日
                    || cv_separate_code || ''  -- ラインNO
                    || cv_separate_code || ''  -- 品目コード
                    || cv_separate_code || ''  -- ロットNO
                    || cv_separate_code || ''  -- 製造年月日
                    || cv_separate_code || ''  -- 固有記号
                    || cv_separate_code || ''  -- 賞味期限日
                    || cv_separate_code || ''  -- ラインタイプ
                    || cv_separate_code || ''  -- タイプ
                    || cv_separate_code || ''  -- 投入口区分
                    || cv_separate_code || ''  -- 打込区分
                    || cv_separate_code || ''  -- 生産日
                    || cv_separate_code || ''  -- 原料入庫日
                    || cv_separate_code || ''  -- 単位
                    || cv_separate_code || ''  -- ランク１
                    || cv_separate_code || ''  -- ランク２
                    || cv_separate_code || ''  -- ランク３
                    || cv_separate_code || ''  -- 摘要
                    || cv_separate_code || ''  -- 在庫入数
                    || cv_separate_code || ''  -- 依頼総数
                    || cv_separate_code || ''  -- 原料削除フラグ
                    || cv_separate_code || ''  -- ロット_指示総数
                    || cv_separate_code || ''  -- ロット_投入数量
                    || cv_separate_code || ''  -- ロット_予定区分
                    || cv_separate_code || ''  -- ロット_予定番号
                    || cv_separate_code || ''  -- 明細最終更新日
        ;
--
        -- ファイル出力
        UTL_FILE.PUT_LINE(
          lf_file_hand
         ,lv_csv_data
        );
--
      END IF;
--
      -- 明細行
      lv_csv_data :=                     cv_coop_name_itoen          -- 会社名
                  || cv_separate_code || cv_data_type_700            -- データ種別
                  || cv_separate_code || cv_branch_no_20             -- 伝送用枝番
                  || cv_separate_code || g_batch_info_rec.batch_no   -- バッチNO
                  || cv_separate_code || g_batch_info_rec.plant_code -- プラントコード
                  || cv_separate_code || ''  -- 工順
                  || cv_separate_code || ''  -- 業務ステータス
                  || cv_separate_code || ''  -- 計画完了日
                  || cv_separate_code || ''  -- 実績完了日
                  || cv_separate_code || ''  -- 削除マーク
                  || cv_separate_code || ''  -- 伝票区分
                  || cv_separate_code || ''  -- 成績管理部署
                  || cv_separate_code || ''  -- 完成品_品目コード
                  || cv_separate_code || ''  -- 完成品_ロットNO
                  || cv_separate_code || ''  -- 完成品_タイプ
                  || cv_separate_code || ''  -- 完成品_製造年月日
                  || cv_separate_code || ''  -- 完成品_固有記号
                  || cv_separate_code || ''  -- 完成品_賞味期限日
                  || cv_separate_code || ''  -- 完成品_生産日
                  || cv_separate_code || ''  -- 完成品_原料入庫日
                  || cv_separate_code || ''  -- 完成品_実績数量
                  || cv_separate_code || ''  -- 完成品_単位
                  || cv_separate_code || ''  -- 完成品_ランク１
                  || cv_separate_code || ''  -- 完成品_ランク２
                  || cv_separate_code || ''  -- 完成品_ランク３
                  || cv_separate_code || ''  -- 完成品_摘要
                  || cv_separate_code || ''  -- 完成品_在庫入数
                  || cv_separate_code || ''  -- 完成品_依頼総数
                  || cv_separate_code || ''  -- 完成品_指図総数
                  || cv_separate_code || ''  -- 完成品_移動場所コード
                  || cv_separate_code || ''  -- ヘッダ最終更新日
                  || cv_separate_code || g_batch_info_rec.line_no               -- ラインNO
                  || cv_separate_code || g_batch_info_rec.item_no               -- 品目コード
                  || cv_separate_code || g_batch_info_rec.lot_no                -- ロットNO
                  || cv_separate_code || g_batch_info_rec.producted_date        -- 製造年月日
                  || cv_separate_code || g_batch_info_rec.uniqe_sign            -- 固有記号
                  || cv_separate_code || g_batch_info_rec.use_by_date           -- 賞味期限日
                  || cv_separate_code || g_batch_info_rec.line_type             -- ラインタイプ
                  || cv_separate_code || g_batch_info_rec.item_type             -- タイプ
                  || cv_separate_code || g_batch_info_rec.inlet_type            -- 投入口区分
                  || cv_separate_code || g_batch_info_rec.actual_qty            -- 打込区分
                  || cv_separate_code || g_batch_info_rec.manufactured_date     -- 生産日
                  || cv_separate_code || g_batch_info_rec.material_stored_date  -- 原料入庫日
                  || cv_separate_code || g_batch_info_rec.item_um               -- 単位
                  || cv_separate_code || g_batch_info_rec.rank1                 -- ランク１
                  || cv_separate_code || g_batch_info_rec.rank2                 -- ランク２
                  || cv_separate_code || g_batch_info_rec.rank3                 -- ランク３
                  || cv_separate_code || g_batch_info_rec.discription           -- 摘要
                  || cv_separate_code || g_batch_info_rec.in_qty                -- 在庫入数
                  || cv_separate_code || g_batch_info_rec.request_qty           -- 依頼総数
                  || cv_separate_code || g_batch_info_rec.material_del_flag     -- 原料削除フラグ
                  || cv_separate_code || g_batch_info_rec.lot_instruct_qty      -- ロット_指示総数
                  || cv_separate_code || g_batch_info_rec.lot_input_qty         -- ロット_投入数量
                  || cv_separate_code || g_batch_info_rec.lot_plan_type         -- ロット_予定区分
                  || cv_separate_code || g_batch_info_rec.lot_plan_num          -- ロット_予定番号
                  || cv_separate_code || TO_CHAR(g_batch_info_rec.l_last_update_date, cv_fmt_date) -- 明細最終更新日
      ;
--
      -- ファイル出力
      UTL_FILE.PUT_LINE(
        lf_file_hand
       ,lv_csv_data
      );
--
      -- キー項目を保持
      lt_prev_batch_no   := g_batch_info_rec.batch_no;
--
      -- 対象件数をカウント
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP batch_info_loop;
--
    --==================================
    -- ファイルクローズ
    --==================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- 対象件数が0件の場合
    IF ( gn_target_cnt = 0 ) THEN
      -- 対象データ未取得エラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
               iv_application => cv_app_xxcmn
              ,iv_name        => cv_msg_xxcmn_11048
             );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      --1行空白
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => NULL
      );
--
      -- ステータス警告
      ov_retcode := cv_status_warn;
--
    ELSE
    -- 対象件数が存在する場合
      --==================================
      -- ワークフロー通知
      --==================================
      xxwsh_common3_pkg.wf_whs_start(
        ir_wf_whs_rec => lr_wf_whs_rec      -- ワークフロー関連情報
       ,iv_filename   => lv_file_name       -- ファイル名
       ,ov_errbuf     => lv_errbuf          -- エラー・メッセージ
       ,ov_retcode    => lv_retcode         -- リターン・コード
       ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--
--#####################################  固定部 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_batch_no               IN  VARCHAR2  -- 1.バッチNO
   ,iv_whse_code              IN  VARCHAR2  -- 2.倉庫コード
   ,iv_production_date_from   IN  VARCHAR2  -- 3.完成品製造日(FROM)
   ,iv_production_date_to     IN  VARCHAR2  -- 4.完成品製造日(TO)
   ,iv_routing                IN  VARCHAR2  -- 5.ラインNo
   ,ov_errbuf                 OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg                 OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --  初期処理(A-1)
    -- ===============================
    init(
      iv_batch_no             =>  iv_batch_no             -- 1.バッチNO
     ,iv_whse_code            =>  iv_whse_code            -- 2.倉庫コード
     ,iv_production_date_from =>  iv_production_date_from -- 3.完成品製造日(FROM)
     ,iv_production_date_to   =>  iv_production_date_to   -- 4.完成品製造日(TO)
     ,iv_routing              =>  iv_routing              -- 5.ラインNo
     ,ov_errbuf               =>  lv_errbuf               -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              =>  lv_retcode              -- リターン・コード             --# 固定 #
     ,ov_errmsg               =>  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- CSV出力処理(A-2)
    --==================================
    output_data(
      iv_batch_no             =>  iv_batch_no             -- 1.バッチNO
     ,iv_whse_code            =>  iv_whse_code            -- 2.倉庫コード
     ,iv_production_date_from =>  iv_production_date_from -- 3.完成品製造日(FROM)
     ,iv_production_date_to   =>  iv_production_date_to   -- 4.完成品製造日(TO)
     ,iv_routing              =>  iv_routing              -- 5.ラインNo
     ,ov_errbuf               =>  lv_errbuf               -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              =>  lv_retcode              -- リターン・コード             --# 固定 #
     ,ov_errmsg               =>  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 終了パラメータ判定
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
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
    errbuf                    OUT VARCHAR2        -- エラー・メッセージ  --# 固定 #
   ,retcode                   OUT VARCHAR2        -- リターン・コード    --# 固定 #
   ,iv_batch_no               IN  VARCHAR2        -- 1.バッチNO
   ,iv_whse_code              IN  VARCHAR2        -- 2.倉庫コード
   ,iv_production_date_from   IN  VARCHAR2        -- 3.完成品製造日(FROM)
   ,iv_production_date_to     IN  VARCHAR2        -- 4.完成品製造日(TO)
   ,iv_routing                IN  VARCHAR2        -- 5.ラインNo
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
    cv_sts_cd_normal   CONSTANT VARCHAR2(1)   := 'C';                -- ステータスコード:C(正常)
    cv_sts_cd_warn     CONSTANT VARCHAR2(1)   := 'G';                -- ステータスコード:G(警告)
    cv_sts_cd_error    CONSTANT VARCHAR2(1)   := 'E';                -- ステータスコード:E(エラー)
--
    cv_appl_name_xxcmn CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：生産(マスタ・経理・共通)
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00008';  -- 処理件数
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCMN-00009';  -- 成功件数
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- エラー件数
    cv_out_msg         CONSTANT VARCHAR2(100) := 'APP-XXCMN-00012';  -- 終了メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'CNT';              -- 件数メッセージ用トークン名
    cv_status_token    CONSTANT VARCHAR2(10)  := 'STATUS';           -- 処理ステータス用トークン名
    cv_cp_status_cd    CONSTANT VARCHAR2(100) := 'CP_STATUS_CODE';   -- ルックアップ
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
       ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
      iv_batch_no             =>  iv_batch_no             -- 1.バッチNO
     ,iv_whse_code            =>  iv_whse_code            -- 2.倉庫コード
     ,iv_production_date_from =>  iv_production_date_from -- 3.完成品製造日(FROM)
     ,iv_production_date_to   =>  iv_production_date_to   -- 4.完成品製造日(TO)
     ,iv_routing              =>  iv_routing              -- 5.ラインNo
     ,ov_errbuf               =>  lv_errbuf               -- エラー・メッセージ             --# 固定 #
     ,ov_retcode              =>  lv_retcode              -- リターン・コード               --# 固定 #
     ,ov_errmsg               =>  lv_errmsg               -- ユーザー・エラー・メッセージ   --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
    -- ステータスがエラーの場合
      -- 件数設定
      gn_target_cnt := 0;  -- 処理件数
      gn_normal_cnt := 0;  -- 成功件数
      gn_error_cnt  := 1;  -- エラー件数
--
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行を出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    ELSIF ( lv_retcode = cv_status_warn ) THEN
    -- ステータスが警告の場合(対象データ無しの場合)
      -- 件数設定
      gn_target_cnt := 0; -- 処理件数
      gn_normal_cnt := 0; -- 成功件数
      gn_error_cnt  := 0; -- エラー件数
    ELSE
    -- ステータスが正常の場合
      -- 件数設定
      gn_normal_cnt := gn_target_cnt; -- 成功件数
      gn_error_cnt  := 0;             -- エラー件数
    END IF;
--
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn
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
    gv_out_msg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn
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
    gv_out_msg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmn
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行を出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
--
    -- 終了ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = cv_cp_status_cd
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            cv_status_normal,cv_sts_cd_normal,
                                            cv_status_warn,cv_sts_cd_warn,
                                            cv_sts_cd_error)
    AND    ROWNUM                  = 1
    ;
    gv_out_msg := xxcmn_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcmn
                   ,iv_name         => cv_out_msg
                   ,iv_token_name1  => cv_status_token
                   ,iv_token_value1 => gv_conc_status
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --終了ステータスセット
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
END XXCMN800014C;
/
