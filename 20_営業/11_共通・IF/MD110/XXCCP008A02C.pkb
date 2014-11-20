CREATE OR REPLACE PACKAGE BODY APPS.XXCCP008A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A02C(body)
 * Description      : リース物件データCSV出力
 * MD.050           : 
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  chk_input_param        入力パラメータチェック処理(A-2)
 *  output_csv             CSV出力処理(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/31    1.0   SCSK 谷口圭介    新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
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
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10)  := 'XXCCP';                  -- アプリケーション短縮名
  cv_pkg_name               CONSTANT VARCHAR2(20)  := 'XXCCP008A02C';           -- パッケージ名
  -- 物件コード指定有無フラグ コード値
  cv_obj_code_param_off     CONSTANT VARCHAR2(1)   := '0';                      -- 物件コードの指定無し
  cv_obj_code_param_on      CONSTANT VARCHAR2(1)   := '1';                      -- 物件コードの指定有り
  -- CSV出力用
  cv_delimit                CONSTANT VARCHAR2(10)  := ',';                      -- 区切り文字
  cv_enclosed               CONSTANT VARCHAR2(10)  := '"';                      -- 単語囲み文字
  -- 書式
  cv_date_format            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';  -- 標準日時
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_obj_code_param         VARCHAR2(1);                                  -- 物件コード指定有無フラグ
  -- 入力パラメータ格納用
  gv_contract_number        xxcff_contract_headers.contract_number%TYPE;  -- パラメータ：1. 契約番号
  gv_lease_company          xxcff_contract_headers.lease_company%TYPE;    -- パラメータ：2. リース会社
  gv_object_code_01         xxcff_object_headers.object_code%TYPE;        -- パラメータ：3. 物件コード1
  gv_object_code_02         xxcff_object_headers.object_code%TYPE;        -- パラメータ：4. 物件コード2
  gv_object_code_03         xxcff_object_headers.object_code%TYPE;        -- パラメータ：5. 物件コード3
  gv_object_code_04         xxcff_object_headers.object_code%TYPE;        -- パラメータ：6. 物件コード4
  gv_object_code_05         xxcff_object_headers.object_code%TYPE;        -- パラメータ：7. 物件コード5
  gv_object_code_06         xxcff_object_headers.object_code%TYPE;        -- パラメータ：8. 物件コード6
  gv_object_code_07         xxcff_object_headers.object_code%TYPE;        -- パラメータ：9. 物件コード7
  gv_object_code_08         xxcff_object_headers.object_code%TYPE;        -- パラメータ：10.物件コード8
  gv_object_code_09         xxcff_object_headers.object_code%TYPE;        -- パラメータ：11.物件コード9
  gv_object_code_10         xxcff_object_headers.object_code%TYPE;        -- パラメータ：12.物件コード10
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_contract_number  IN  VARCHAR2    -- 1. 契約番号
   ,iv_lease_company    IN  VARCHAR2    -- 2. リース会社
   ,iv_object_code_01   IN  VARCHAR2    -- 3. 物件コード1
   ,iv_object_code_02   IN  VARCHAR2    -- 4. 物件コード2
   ,iv_object_code_03   IN  VARCHAR2    -- 5. 物件コード3
   ,iv_object_code_04   IN  VARCHAR2    -- 6. 物件コード4
   ,iv_object_code_05   IN  VARCHAR2    -- 7. 物件コード5
   ,iv_object_code_06   IN  VARCHAR2    -- 8. 物件コード6
   ,iv_object_code_07   IN  VARCHAR2    -- 9. 物件コード7
   ,iv_object_code_08   IN  VARCHAR2    -- 10.物件コード8
   ,iv_object_code_09   IN  VARCHAR2    -- 11.物件コード9
   ,iv_object_code_10   IN  VARCHAR2    -- 12.物件コード10
   ,ov_errbuf           OUT VARCHAR2    --    エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2    --    リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)   --    ユーザー・エラー・メッセージ --# 固定 #
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
    -- ============================================
    -- パラメータをグローバル変数に格納
    -- ============================================
    gv_contract_number := iv_contract_number;  -- 1. 契約番号
    gv_lease_company   := iv_lease_company;    -- 2. リース会社
    gv_object_code_01  := iv_object_code_01;   -- 3. 物件コード1
    gv_object_code_02  := iv_object_code_02;   -- 4. 物件コード2
    gv_object_code_03  := iv_object_code_03;   -- 5. 物件コード3
    gv_object_code_04  := iv_object_code_04;   -- 6. 物件コード4
    gv_object_code_05  := iv_object_code_05;   -- 7. 物件コード5
    gv_object_code_06  := iv_object_code_06;   -- 8. 物件コード6
    gv_object_code_07  := iv_object_code_07;   -- 9. 物件コード7
    gv_object_code_08  := iv_object_code_08;   -- 10.物件コード8
    gv_object_code_09  := iv_object_code_09;   -- 11.物件コード9
    gv_object_code_10  := iv_object_code_10;   -- 12.物件コード10
--
    -- ============================================
    -- パラメータログ出力
    -- ============================================
    -- 1. 契約番号
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '契約番号：' || gv_contract_number
    );
    -- 2. リース会社
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => 'リース会社：' || gv_lease_company
    );
    -- 3. 物件コード1
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード1：' || gv_object_code_01
    );
    -- 4. 物件コード2
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード2：' || gv_object_code_02
    );
    -- 5. 物件コード3
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード3：' || gv_object_code_03
    );
    -- 6. 物件コード4
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード4：' || gv_object_code_04
    );
    -- 7. 物件コード5
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード5：' || gv_object_code_05
    );
    -- 8. 物件コード6
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード6：' || gv_object_code_06
    );
    -- 9. 物件コード7
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード7：' || gv_object_code_07
    );
    -- 10.物件コード8
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード8：' || gv_object_code_08
    );
    -- 11.物件コード9
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード9：' || gv_object_code_09
    );
    -- 12.物件コード10
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '物件コード10：' || gv_object_code_10
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_input_param
   * Description      : 入力パラメータチェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE chk_input_param(
    ov_errbuf           OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2    --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_input_param'; -- プログラム名
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
    -- ============================================
    -- 物件コード指定有無フラグ設定
    -- ============================================
    -- パラメータ.物件コード1～10の内、一つでも指定されている場合は物件コード指定有無フラグを有りにする
    gv_obj_code_param := cv_obj_code_param_off;
    IF ( gv_object_code_01 IS NOT NULL ) OR
       ( gv_object_code_02 IS NOT NULL ) OR
       ( gv_object_code_03 IS NOT NULL ) OR
       ( gv_object_code_04 IS NOT NULL ) OR
       ( gv_object_code_05 IS NOT NULL ) OR
       ( gv_object_code_06 IS NOT NULL ) OR
       ( gv_object_code_07 IS NOT NULL ) OR
       ( gv_object_code_08 IS NOT NULL ) OR
       ( gv_object_code_09 IS NOT NULL ) OR
       ( gv_object_code_10 IS NOT NULL )
    THEN
       gv_obj_code_param := cv_obj_code_param_on;
    END IF;
--
    -- ============================================
    -- 必須チェック
    -- ============================================
    -- 契約番号が入力されている場合
    IF ( gv_contract_number IS NOT NULL ) THEN
--
      -- 物件コード、リース会社がともに未入力の場合
      IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
         ( gv_lease_company IS NULL )
      THEN
        lv_errmsg   := '物件コードが未指定時は、契約番号とリース会社を指定して下さい。';
        lv_errbuf   := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    -- 契約番号が未入力の場合
    ELSE
--
      -- 物件コードが未入力の場合
      IF ( gv_obj_code_param = cv_obj_code_param_off ) THEN
        lv_errmsg   := '物件コードが未指定時は、契約番号とリース会社を指定して下さい。';
        lv_errbuf   := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END chk_input_param;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSV出力処理(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    -- リース物件情報取得カーソル（契約番号指定あり）
    CURSOR l_object_cont_num_cur
    IS
      SELECT
          -- VARCHAR2に変換したリース物件全カラム
          TO_CHAR(xoh.object_header_id)                     AS  object_header_id        -- 物件内部ID
         ,xoh.object_code                                   AS  object_code             -- 物件コード
         ,xoh.lease_class                                   AS  lease_class             -- リース種別
         ,xoh.lease_type                                    AS  lease_type              -- リース区分
         ,TO_CHAR(xoh.re_lease_times)                       AS  re_lease_times          -- 再リース回数
         ,xoh.po_number                                     AS  po_number               -- 発注番号
         ,xoh.registration_number                           AS  registration_number     -- 登録番号
         ,xoh.age_type                                      AS  age_type                -- 年式
         ,xoh.model                                         AS  model                   -- 機種
         ,xoh.serial_number                                 AS  serial_number           -- 機番
         ,TO_CHAR(xoh.quantity)                             AS  quantity                -- 数量
         ,xoh.manufacturer_name                             AS  manufacturer_name       -- メーカー名
         ,xoh.department_code                               AS  department_code         -- 管理部門コード
         ,xoh.owner_company                                 AS  owner_company           -- 本社／工場
         ,xoh.installation_address                          AS  installation_address    -- 現設置場所
         ,xoh.installation_place                            AS  installation_place      -- 現設置先
         ,xoh.chassis_number                                AS  chassis_number          -- 車台番号
         ,xoh.re_lease_flag                                 AS  re_lease_flag           -- 再リース要フラグ
         ,xoh.cancellation_type                             AS  cancellation_type       -- 解約区分
         ,TO_CHAR(xoh.cancellation_date, cv_date_format)    AS  cancellation_date       -- 中途解約日
         ,TO_CHAR(xoh.dissolution_date , cv_date_format)    AS  dissolution_date        -- 中途解約キャンセル日
         ,xoh.bond_acceptance_flag                          AS  bond_acceptance_flag    -- 証書受領フラグ
         ,TO_CHAR(xoh.bond_acceptance_date, cv_date_format) AS  bond_acceptance_date    -- 証書受領日
         ,TO_CHAR(xoh.expiration_date, cv_date_format)      AS  expiration_date         -- 満了日
         ,xoh.object_status                                 AS  object_status           -- 物件ステータス
         ,xoh.active_flag                                   AS  active_flag             -- 物件有効フラグ
         ,TO_CHAR(xoh.info_sys_if_date, cv_date_format)     AS  info_sys_if_date        -- リース管理情報連携日
         ,TO_CHAR(xoh.generation_date, cv_date_format)      AS  generation_date         -- 発生日
         ,xoh.customer_code                                 AS  customer_code           -- 顧客コード
         ,TO_CHAR(xoh.created_by)                           AS  created_by              -- 作成者
         ,TO_CHAR(xoh.creation_date, cv_date_format)        AS  creation_date           -- 作成日
         ,TO_CHAR(xoh.last_updated_by)                      AS  last_updated_by         -- 最終更新者
         ,TO_CHAR(xoh.last_update_date, cv_date_format)     AS  last_update_date        -- 最終更新日
         ,TO_CHAR(xoh.last_update_login)                    AS  last_update_login       -- 最終更新ログイン
         ,TO_CHAR(xoh.request_id)                           AS  request_id              -- 要求ID
         ,TO_CHAR(xoh.program_application_id)               AS  program_application_id  -- コンカレント・プログラム・アプリケーションID
         ,TO_CHAR(xoh.program_id)                           AS  program_id              -- コンカレント・プログラムID
         ,TO_CHAR(xoh.program_update_date, cv_date_format)  AS  program_update_date     -- プログラム更新日
      FROM
          xxcff_contract_headers      xch   --  リース契約ヘッダ
         ,xxcff_contract_lines        xcl   --  リース契約明細
         ,xxcff_object_headers        xoh   --  リース物件
         ,( 
            -- 契約番号、リース会社ごとの最大再リース回数
            SELECT
                xch2.contract_number      AS contract_number      -- 契約番号
               ,xch2.lease_company        AS lease_company        -- リース会社
               ,MAX(xch2.re_lease_times)  AS re_lease_times       -- 再リース回数
            FROM
                xxcff_contract_headers    xch2                    -- リース契約ヘッダ
            WHERE
                xch2.contract_number      = gv_contract_number    -- 契約番号
            GROUP BY
                xch2.contract_number      -- 契約番号
               ,xch2.lease_company        -- リース会社
          )
          xch2_max
      WHERE
          xch.contract_header_id      = xcl.contract_header_id    -- 契約内部ID
      AND xcl.object_header_id        = xoh.object_header_id      -- 物件内部ID
      --
      --  リース契約ヘッダを再リース回数が最大のレコードに絞る
      AND xch.contract_number         = xch2_max.contract_number  -- 契約番号
      AND xch.lease_company           = xch2_max.lease_company    -- リース会社
      AND xch.re_lease_times          = xch2_max.re_lease_times   -- 再リース回数
      --
      --  入力パラメータ．契約番号
      AND xch.contract_number         = gv_contract_number
      -- 
      --  入力パラメータ．リース会社
      AND (   gv_lease_company        IS NULL
          OR  xch.lease_company       = gv_lease_company
          )
      --
      --  入力パラメータ．物件コード
      AND (   gv_obj_code_param       = cv_obj_code_param_off     -- 物件コード未入力
          OR  xoh.object_code         IN  ( gv_object_code_01
                                          , gv_object_code_02
                                          , gv_object_code_03
                                          , gv_object_code_04
                                          , gv_object_code_05
                                          , gv_object_code_06
                                          , gv_object_code_07
                                          , gv_object_code_08
                                          , gv_object_code_09
                                          , gv_object_code_10
                                          )
          )
      --
      ORDER BY
          xch.contract_number     -- 契約番号
         ,xoh.object_code         -- 物件コード
    ;
--
--
    -- リース物件情報取得カーソル（契約番号指定なし＆物件コード指定あり）
    CURSOR l_object_no_cont_num_cur
    IS
      SELECT
          -- VARCHAR2に変換したリース物件全カラム
          TO_CHAR(xoh.object_header_id)                     AS  object_header_id        -- 物件内部ID
         ,xoh.object_code                                   AS  object_code             -- 物件コード
         ,xoh.lease_class                                   AS  lease_class             -- リース種別
         ,xoh.lease_type                                    AS  lease_type              -- リース区分
         ,TO_CHAR(xoh.re_lease_times)                       AS  re_lease_times          -- 再リース回数
         ,xoh.po_number                                     AS  po_number               -- 発注番号
         ,xoh.registration_number                           AS  registration_number     -- 登録番号
         ,xoh.age_type                                      AS  age_type                -- 年式
         ,xoh.model                                         AS  model                   -- 機種
         ,xoh.serial_number                                 AS  serial_number           -- 機番
         ,TO_CHAR(xoh.quantity)                             AS  quantity                -- 数量
         ,xoh.manufacturer_name                             AS  manufacturer_name       -- メーカー名
         ,xoh.department_code                               AS  department_code         -- 管理部門コード
         ,xoh.owner_company                                 AS  owner_company           -- 本社／工場
         ,xoh.installation_address                          AS  installation_address    -- 現設置場所
         ,xoh.installation_place                            AS  installation_place      -- 現設置先
         ,xoh.chassis_number                                AS  chassis_number          -- 車台番号
         ,xoh.re_lease_flag                                 AS  re_lease_flag           -- 再リース要フラグ
         ,xoh.cancellation_type                             AS  cancellation_type       -- 解約区分
         ,TO_CHAR(xoh.cancellation_date, cv_date_format)    AS  cancellation_date       -- 中途解約日
         ,TO_CHAR(xoh.dissolution_date , cv_date_format)    AS  dissolution_date        -- 中途解約キャンセル日
         ,xoh.bond_acceptance_flag                          AS  bond_acceptance_flag    -- 証書受領フラグ
         ,TO_CHAR(xoh.bond_acceptance_date, cv_date_format) AS  bond_acceptance_date    -- 証書受領日
         ,TO_CHAR(xoh.expiration_date, cv_date_format)      AS  expiration_date         -- 満了日
         ,xoh.object_status                                 AS  object_status           -- 物件ステータス
         ,xoh.active_flag                                   AS  active_flag             -- 物件有効フラグ
         ,TO_CHAR(xoh.info_sys_if_date, cv_date_format)     AS  info_sys_if_date        -- リース管理情報連携日
         ,TO_CHAR(xoh.generation_date, cv_date_format)      AS  generation_date         -- 発生日
         ,xoh.customer_code                                 AS  customer_code           -- 顧客コード
         ,TO_CHAR(xoh.created_by)                           AS  created_by              -- 作成者
         ,TO_CHAR(xoh.creation_date, cv_date_format)        AS  creation_date           -- 作成日
         ,TO_CHAR(xoh.last_updated_by)                      AS  last_updated_by         -- 最終更新者
         ,TO_CHAR(xoh.last_update_date, cv_date_format)     AS  last_update_date        -- 最終更新日
         ,TO_CHAR(xoh.last_update_login)                    AS  last_update_login       -- 最終更新ログイン
         ,TO_CHAR(xoh.request_id)                           AS  request_id              -- 要求ID
         ,TO_CHAR(xoh.program_application_id)               AS  program_application_id  -- コンカレント・プログラム・アプリケーションID
         ,TO_CHAR(xoh.program_id)                           AS  program_id              -- コンカレント・プログラムID
         ,TO_CHAR(xoh.program_update_date, cv_date_format)  AS  program_update_date     -- プログラム更新日
      FROM
          xxcff_contract_headers      xch   --  リース契約ヘッダ
         ,xxcff_contract_lines        xcl   --  リース契約明細
         ,xxcff_object_headers        xoh   --  リース物件
      WHERE
          xch.contract_header_id      = xcl.contract_header_id    -- 契約内部ID
      AND xcl.object_header_id        = xoh.object_header_id      -- 物件内部ID
      --
      --  再リース回数（抽出対象を最新契約のみとする）
      AND xch.re_lease_times          = xoh.re_lease_times        -- 再リース回数
      -- 
      --  入力パラメータ．リース会社
      AND (   gv_lease_company        IS NULL
          OR  xch.lease_company       = gv_lease_company
          )
      --
      --  入力パラメータ．物件コード（必ずいずれかに指定あり）
      AND xoh.object_code             IN  ( gv_object_code_01
                                          , gv_object_code_02
                                          , gv_object_code_03
                                          , gv_object_code_04
                                          , gv_object_code_05
                                          , gv_object_code_06
                                          , gv_object_code_07
                                          , gv_object_code_08
                                          , gv_object_code_09
                                          , gv_object_code_10
                                          )
      --
      ORDER BY
          xch.contract_number     -- 契約番号
         ,xoh.object_code         -- 物件コード
    ;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・PL/SQL表 ***
--
    -- リース物件情報
    TYPE l_object_ttype IS TABLE OF l_object_cont_num_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_object_tab        l_object_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- リース物件情報取得
    -- ===============================================
    -- 契約番号が入力されている場合
    IF ( gv_contract_number IS NOT NULL ) THEN
      OPEN  l_object_cont_num_cur;
      FETCH l_object_cont_num_cur BULK COLLECT INTO l_object_tab;
      CLOSE l_object_cont_num_cur;
--
    -- 契約番号が未入力の場合（物件コードは必ず指定されている）
    ELSE
      OPEN  l_object_no_cont_num_cur;
      FETCH l_object_no_cont_num_cur BULK COLLECT INTO l_object_tab;
      CLOSE l_object_no_cont_num_cur;
    END IF;
--
    -- 対象件数格納
    gn_target_cnt := l_object_tab.COUNT;
--
    -- ===============================================
    -- CSV出力処理
    -- ===============================================
    -- 見出し
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_enclosed || 'リース物件' || cv_enclosed
    );
--
    -- 項目名
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   =>          cv_enclosed || '物件内部ID'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '物件コード'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース種別'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース区分'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '再リース回数'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '発注番号'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '登録番号'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '年式'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '機種'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '機番'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '数量'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || 'メーカー名'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '管理部門コード'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '本社／工場'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '現設置場所'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '現設置先'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '車台番号'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '再リース要フラグ'                             || cv_enclosed
         || cv_delimit || cv_enclosed || '解約区分'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '中途解約日'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '中途解約キャンセル日'                         || cv_enclosed
         || cv_delimit || cv_enclosed || '証書受領フラグ'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '証書受領日'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '満了日'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '物件ステータス'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '物件有効フラグ'                               || cv_enclosed
         || cv_delimit || cv_enclosed || 'リース管理情報連携日'                         || cv_enclosed
         || cv_delimit || cv_enclosed || '発生日'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '顧客コード'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '作成者'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '作成日'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新者'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新日'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '最終更新ログイン'                             || cv_enclosed
         || cv_delimit || cv_enclosed || '要求ID'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || 'コンカレント・プログラム・アプリケーションID' || cv_enclosed
         || cv_delimit || cv_enclosed || 'コンカレント・プログラムID'                   || cv_enclosed
         || cv_delimit || cv_enclosed || 'プログラム更新日'                             || cv_enclosed
    );
--
    -- 物件情報ループ
    <<object_loop>>
    FOR i IN 1 .. l_object_tab.COUNT LOOP
--
      -- 項目値
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   =>          cv_enclosed || l_object_tab( i ).object_header_id       || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).object_code            || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).lease_class            || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).lease_type             || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).re_lease_times         || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).po_number              || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).registration_number    || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).age_type               || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).model                  || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).serial_number          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).quantity               || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).manufacturer_name      || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).department_code        || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).owner_company          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).installation_address   || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).installation_place     || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).chassis_number         || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).re_lease_flag          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).cancellation_type      || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).cancellation_date      || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).dissolution_date       || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).bond_acceptance_flag   || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).bond_acceptance_date   || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).expiration_date        || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).object_status          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).active_flag            || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).info_sys_if_date       || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).generation_date        || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).customer_code          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).created_by             || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).creation_date          || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).last_updated_by        || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).last_update_date       || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).last_update_login      || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).request_id             || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).program_application_id || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).program_id             || cv_enclosed
           || cv_delimit || cv_enclosed || l_object_tab( i ).program_update_date    || cv_enclosed
      );
--
      --成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP object_loop;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_contract_number  IN  VARCHAR2    --  1.契約番号
   ,iv_lease_company    IN  VARCHAR2    --  2.リース会社
   ,iv_object_code_01   IN  VARCHAR2    --  3.物件コード1
   ,iv_object_code_02   IN  VARCHAR2    --  4.物件コード2
   ,iv_object_code_03   IN  VARCHAR2    --  5.物件コード3
   ,iv_object_code_04   IN  VARCHAR2    --  6.物件コード4
   ,iv_object_code_05   IN  VARCHAR2    --  7.物件コード5
   ,iv_object_code_06   IN  VARCHAR2    --  8.物件コード6
   ,iv_object_code_07   IN  VARCHAR2    --  9.物件コード7
   ,iv_object_code_08   IN  VARCHAR2    -- 10.物件コード8
   ,iv_object_code_09   IN  VARCHAR2    -- 11.物件コード9
   ,iv_object_code_10   IN  VARCHAR2    -- 12.物件コード10
   ,ov_errbuf           OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2    --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- グローバル変数の初期化
    gn_target_cnt   := 0;   -- 対象件数
    gn_normal_cnt   := 0;   -- 正常件数
    gn_error_cnt    := 0;   -- エラー件数
    gn_warn_cnt     := 0;   -- スキップ件数
--
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      iv_contract_number  =>  iv_contract_number  --  1.契約番号
     ,iv_lease_company    =>  iv_lease_company    --  2.リース会社
     ,iv_object_code_01   =>  iv_object_code_01   --  3.物件コード1
     ,iv_object_code_02   =>  iv_object_code_02   --  4.物件コード2
     ,iv_object_code_03   =>  iv_object_code_03   --  5.物件コード3
     ,iv_object_code_04   =>  iv_object_code_04   --  6.物件コード4
     ,iv_object_code_05   =>  iv_object_code_05   --  7.物件コード5
     ,iv_object_code_06   =>  iv_object_code_06   --  8.物件コード6
     ,iv_object_code_07   =>  iv_object_code_07   --  9.物件コード7
     ,iv_object_code_08   =>  iv_object_code_08   -- 10.物件コード8
     ,iv_object_code_09   =>  iv_object_code_09   -- 11.物件コード9
     ,iv_object_code_10   =>  iv_object_code_10   -- 12.物件コード10
     ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          =>  lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg           =>  lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 入力パラメータチェック処理(A-2)
    -- ===============================================
    chk_input_param(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode  =>  lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- CSV出力処理(A-3)
    -- ===============================================
    output_csv(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode  =>  lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数０件の場合、終了ステータスを「警告」にする
    IF (gn_target_cnt = 0) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '対象データが存在しません。'
      );
      ov_retcode := cv_status_warn;
    END IF;
--
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf              OUT VARCHAR2,       --     エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,       --     リターン・コード    --# 固定 #
    iv_contract_number  IN  VARCHAR2,       --  1. 契約番号
    iv_lease_company    IN  VARCHAR2,       --  2. リース会社
    iv_object_code_01   IN  VARCHAR2,       --  3. 物件コード1
    iv_object_code_02   IN  VARCHAR2,       --  4. 物件コード2
    iv_object_code_03   IN  VARCHAR2,       --  5. 物件コード3
    iv_object_code_04   IN  VARCHAR2,       --  6. 物件コード4
    iv_object_code_05   IN  VARCHAR2,       --  7. 物件コード5
    iv_object_code_06   IN  VARCHAR2,       --  8. 物件コード6
    iv_object_code_07   IN  VARCHAR2,       --  9. 物件コード7
    iv_object_code_08   IN  VARCHAR2,       --  10.物件コード8
    iv_object_code_09   IN  VARCHAR2,       --  11.物件コード9
    iv_object_code_10   IN  VARCHAR2        --  12.物件コード10
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
       iv_which   => 'LOG'
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
      iv_contract_number  =>  iv_contract_number  -- 1. 契約番号
     ,iv_lease_company    =>  iv_lease_company    -- 2. リース会社
     ,iv_object_code_01   =>  iv_object_code_01   -- 3. 物件コード1
     ,iv_object_code_02   =>  iv_object_code_02   -- 4. 物件コード2
     ,iv_object_code_03   =>  iv_object_code_03   -- 5. 物件コード3
     ,iv_object_code_04   =>  iv_object_code_04   -- 6. 物件コード4
     ,iv_object_code_05   =>  iv_object_code_05   -- 7. 物件コード5
     ,iv_object_code_06   =>  iv_object_code_06   -- 8. 物件コード6
     ,iv_object_code_07   =>  iv_object_code_07   -- 9. 物件コード7
     ,iv_object_code_08   =>  iv_object_code_08   -- 10.物件コード8
     ,iv_object_code_09   =>  iv_object_code_09   -- 11.物件コード9
     ,iv_object_code_10   =>  iv_object_code_10   -- 12.物件コード10
     ,ov_errbuf           =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          =>  lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg           =>  lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- 終了処理(A-4)
    -- ===============================================
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
      -- 件数設定
      gn_normal_cnt := 0;   -- 成功件数クリア
      gn_error_cnt  := 1;   -- エラー件数設定
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
END XXCCP008A02C;
/
