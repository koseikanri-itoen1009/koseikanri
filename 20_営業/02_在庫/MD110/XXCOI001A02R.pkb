CREATE OR REPLACE PACKAGE BODY XXCOI001A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A02R(body)
 * Description      : 指定された条件に紐づく入庫確認情報のリストを出力します。
 * MD.050           : 入庫未確認リスト MD050_COI_001_A02
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_output_base        出力拠点取得 (A-2)
 *  ins_storage_info       データ登録 (A-4)
 *  exec_svf_conc          SVFコンカレントの起動 (A-5)
 *  get_table_lock         ワークテーブルロック取得(A-7)
 *  del_storage_info       データ削除 (A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/08    1.0   S.Moriyama       main新規作成
 *  2009/03/05    1.1   H.Wada           障害番号 #034 成功件数修正
 *  2009/04/15    1.2   H.Sasaki         [T1_0397]拠点情報取得Viewの変更
 *  2009/04/23    1.3   H.Sasaki         [T1_0385]出庫拠点名の整形（8byte切捨て）
 *  2009/07/02    1.4   H.Sasaki         [0000273]パフォーマンス改善
 *  2009/08/07    1.5   N.Abe            [0000945]パフォーマンス改善
 *  2009/09/08    1.6   H.Sasaki         [0001266]OPM品目アドオン版管理対応
 *  2009/11/27    1.7   N.Abe            [E_本稼動_00089]同一伝票番号の他拠点を抽出しない
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  get_output_type_expt      EXCEPTION;                                -- 出力区分名称取得エラー
  prm_date_expt             EXCEPTION;                                -- 日付パラメータ不正エラー
  exec_svfapi_expt          EXCEPTION;                                -- SVF帳票共通関数エラー
  get_tbl_lock_expt         EXCEPTION;                                -- ワークテーブルロック取得エラー
  PRAGMA EXCEPTION_INIT( get_tbl_lock_expt, -54 );                    -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOI001A02R';          -- パッケージ名
  cv_application   CONSTANT VARCHAR2(100) := 'XXCOI';                 -- アプリケーション名
  cv_yes           CONSTANT VARCHAR2(100) := 'Y';                     -- 固定値'Y'
  cv_no            CONSTANT VARCHAR2(100) := 'N';                     -- 固定値'N'
--
  cv_output_type   CONSTANT VARCHAR2(100) := 'XXCOI1_UNCONFIRMED_LIST_DIV'; -- 入庫未確認リスト出力区分
  cv_list_type     CONSTANT VARCHAR2(100) := 'XXCOI1_STOCKED_VOUCH_DIV'; -- 入庫確認伝票区分
  cv_prf_org_code  CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE'; -- 在庫組織
--
  cv_msg_00008     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008';      -- 0件メッセージ
  cv_msg_00010     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00010';      -- APIエラーメッセージ
  cv_msg_10036     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10036';      -- パラメータ拠点値メッセージ
  cv_msg_10191     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10191';      -- パラメータ出力区分メッセージ
  cv_msg_10192     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10192';      -- パラメータ日付（自）メッセージ
  cv_msg_10193     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10193';      -- パラメータ日付（至）メッセージ
  cv_msg_10240     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10240';      -- 日付不正メッセージ
  cv_msg_10156     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10156';      -- ロック取得エラー
  cv_msg_10337     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10337';      -- 日付大小関係不正メッセージ
--
  cv_tok_base      CONSTANT VARCHAR2(100) := 'BASE_CODE';             -- トークン「BASE_CODE」
  cv_tok_output    CONSTANT VARCHAR2(100) := 'P_OUTPUT_TYPE';         -- トークン「P_OUTPUT_TYPE」
  cv_tok_from      CONSTANT VARCHAR2(100) := 'P_DATE_FROM';           -- トークン「P_DATE_FROM」
  cv_tok_to        CONSTANT VARCHAR2(100) := 'P_DATE_TO';             -- トークン「P_DATE_TO」
  cv_tok_api       CONSTANT VARCHAR2(100) := 'API_NAME';              -- トークン「API_NAME」
  cv_api_coicmn    CONSTANT VARCHAR2(100) := 'GET_MEANING';           -- トークン「APIセット内容」
  cv_api_belogin   CONSTANT VARCHAR2(100) := 'GET_BELONGING_BASE';    -- トークン「APIセット内容」
  cv_api_svfcmn    CONSTANT VARCHAR2(100) := 'SUBMIT_SVF_REQUEST';    -- トークン「APIセット内容」
--
  cv_frm_nm        CONSTANT VARCHAR2(100) := 'XXCOI001A02S.xml';      -- フォーム様式ファイル名
  cv_vrq_nm        CONSTANT VARCHAR2(100) := 'XXCOI001A02S.vrq';      -- クエリー様式ファイル名
  cv_pdf_nm        CONSTANT VARCHAR2(100) := 'XXCOI001A02S.pdf';      -- PDFファイル名
  cv_svf_id        CONSTANT VARCHAR2(100) := 'XXCOI001A02S';          -- 帳票ID
  cv_output_mode   CONSTANT VARCHAR2(1) := '1';                       -- 出力区分(PDF出力)
--
  cv_slip_type_1   CONSTANT VARCHAR2(10) := '10';                     -- 工場入庫
  cv_slip_type_2   CONSTANT VARCHAR2(10) := '20';                     -- 拠点間入庫
  cv_output_div_10 CONSTANT VARCHAR2(10) := '10';                     -- 入庫確認未実施
  cv_output_div_20 CONSTANT VARCHAR2(10) := '20';                     -- 入出庫差異有
  cv_output_div_30 CONSTANT VARCHAR2(10) := '30';                     -- 全データ対象
  cv_summary_kbn   CONSTANT VARCHAR2(1) := '1';                       -- データ種別:サマリ
  cv_detail_kbn    CONSTANT VARCHAR2(1) := '2';                       -- データ種別:詳細
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 出力拠点レコード型
  TYPE gr_output_base_rec IS RECORD(                                  -- 出力対象拠点情報格納レコード
-- == 2009/04/15 V1.2 Modified START ===============================================================
--      base_code              xxcoi_base_info_v.base_code%TYPE
--    , base_name              xxcoi_base_info_v.base_short_name%TYPE
-- == 2009/08/07 V1.5 Modified START ===============================================================
--      base_code              xxcoi_base_info2_v.base_code%TYPE
--    , base_name              xxcoi_base_info2_v.base_short_name%TYPE
      base_code              hz_cust_accounts.account_number%TYPE
    , base_name              hz_cust_accounts.account_name%TYPE
-- == 2009/08/07 V1.5 Modified END   ===============================================================
-- == 2009/04/15 V1.2 Modified END   ===============================================================
  );
  TYPE gt_output_base_ttype                                           -- 出力対象拠点格納用テーブル変数
  IS TABLE OF gr_output_base_rec INDEX BY BINARY_INTEGER;
--
  gt_base_tab                gt_output_base_ttype;                    -- 出力拠点情報格納用
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_output_type_meaning    fnd_lookup_values.meaning%TYPE;           -- 出力区分名称
  gv_date_from              VARCHAR2(10);                             -- 日付（自）
  gv_date_to                VARCHAR2(10);                             -- 日付（至）
  gn_output_base_num        NUMBER;                                   -- 出力拠点数
  gn_output_base_cnt        NUMBER;                                   -- 出力拠点カウンタ
  gn_output_rec_num         NUMBER;                                   -- 出力レコード件数
  gn_output_rec_cnt         NUMBER;                                   -- 出力レコードカウンタ
  gt_base_code              xxcoi_storage_information.base_code%TYPE; -- 拠点コード
-- == 2009/04/15 V1.2 Modified START ===============================================================
--  gt_base_name              xxcoi_base_info_v.base_short_name%TYPE;   -- 拠点名
-- == 2009/08/07 V1.5 Modified START ===============================================================
--  gt_base_name              xxcoi_base_info2_v.base_short_name%TYPE;   -- 拠点名
  gt_base_name              hz_cust_accounts.account_name%TYPE;         -- 拠点名
-- == 2009/08/07 V1.5 Modified END   ===============================================================
-- == 2009/04/15 V1.2 Modified END   ===============================================================
  gv_zero_message           VARCHAR2(200);                            -- 0件メッセージ格納
--
  CURSOR storage_info_cur(
             iv_base_code   VARCHAR2
           , iv_output_type VARCHAR2
           , iv_date_from   VARCHAR2
           , iv_date_to     VARCHAR2)
  IS
  SELECT xsi.base_code                            AS base_code        -- 拠点コード
        ,SUBSTRB(hca_b.account_name,1,8)          AS base_name        -- 拠点名
        ,xsi.slip_date                            AS slip_date        -- 伝票日付
        ,xsi.slip_num                             AS slip_num         -- 伝票番号
        ,xsi.check_warehouse_code                 AS check_warehouse_code
                                                                      -- 倉庫コード
        ,xsi.item_code                            AS item_code        -- 子品目コード
        ,SUBSTRB(ximb.item_short_name,1,20)       AS item_name        -- 品目略称
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NULL ELSE xsi.taste_term END   AS taste_term       -- 賞味期限
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NULL ELSE xsi.difference_summary_code END          -- 工場固有記号
                                                  AS factory_unique_mark
        ,xsi.case_in_qty                          AS case_in_qty      -- 入数
        ,xsi.ship_case_qty                        AS ship_case_qty    -- 出庫数量ケース数
        ,xsi.ship_singly_qty                      AS ship_singly_qty  -- 出庫数量バラ数
        ,xsi.ship_summary_qty                     AS ship_summary_qty -- 出庫数量総バラ数
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NVL(xsi.check_case_qty,0) ELSE NULL END            -- 確認数量ケース数
                                                  AS check_case_qty
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NVL(xsi.check_singly_qty,0) ELSE NULL END          -- 確認数量バラ数
                                                  AS check_singly_qty
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NVL(xsi.check_summary_qty,0) ELSE NULL END         -- 確認数量総バラ数
                                                  AS check_summary_qty
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN NVL(xsi.ship_summary_qty,0) - NVL(xsi.check_summary_qty,0) ELSE NULL END -- 差引合計数量
                                                  AS difference_summary_qty
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN flv.meaning ELSE NULL END      AS slip_type        -- 伝票区分
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN xsi.ship_base_code ELSE NULL END                   -- 出庫拠点コード
                                                  AS ship_base_code
-- == 2009/07/02 V1.4 Deleted START ===============================================================
--        ,CASE WHEN xsi.summary_data_flag = cv_yes
---- == 2009/04/23 V1.3 Modified START ===============================================================
----                THEN ship_base.ship_base_name
--                THEN SUBSTRB(ship_base.ship_base_name, 1, 8)
---- == 2009/04/23 V1.3 Modified END   ===============================================================
--                ELSE NULL
--              END                                 AS ship_base_name   -- 出庫拠点名
-- == 2009/07/02 V1.4 Deleted END   ===============================================================
-- == 2009/07/02 V1.4 Added START ===============================================================
        ,xsi.slip_type                            AS slip_type_code   -- 伝票区分コード
-- == 2009/07/02 V1.4 Added EDN   ===============================================================
        ,CASE WHEN xsi.summary_data_flag = cv_yes
              THEN cv_summary_kbn ELSE cv_detail_kbn END AS data_type -- データ種別
  FROM   xxcoi_storage_information xsi
        ,hz_cust_accounts  hca_b                                      -- 顧客マスタ（拠点）
        ,ic_item_mst_b     iimb                                       -- OPM品目マスタ（子）
        ,xxcmn_item_mst_b  ximb                                       -- OPM品目アドオンマスタ
        ,fnd_lookup_values flv                                        -- クイックコードマスタ
-- == 2009/07/02 V1.4 Deleted START ===============================================================
--        ,(SELECT   xsi.transaction_id
--                 , ship_base.ship_base_name
--          FROM     (SELECT   xsi.transaction_id
--                           , hca.account_name ship_base_name
--                    FROM     xxcoi_storage_information xsi
--                           , hz_cust_accounts hca
--                    WHERE    xsi.ship_base_code = hca.account_number
--                    AND      xsi.slip_type = cv_slip_type_2
--                    UNION
--                    SELECT   xsi.transaction_id
---- == 2009/04/23 V1.3 Modified START ===============================================================
----                           , mil.description ship_base_name
--                           , mil.attribute12    ship_base_name
---- == 2009/04/23 V1.3 Modified END   ===============================================================
--                    FROM     xxcoi_storage_information  xsi
--                           , mtl_item_locations         mil
--                    WHERE    xsi.ship_base_code = mil.segment1
--                    AND      xsi.slip_type      = cv_slip_type_1
--                   ) ship_base
--                   , xxcoi_storage_information xsi
--          WHERE  xsi.transaction_id = ship_base.transaction_id
--        )ship_base
-- == 2009/07/02 V1.4 Deleted END   ===============================================================
        ,(SELECT xsi.slip_num
          FROM   xxcoi_storage_information xsi
          WHERE  xsi.base_code = iv_base_code
          AND    TRUNC(xsi.slip_date) BETWEEN TO_DATE(iv_date_from,'YYYY/MM/DD') AND TO_DATE(iv_date_to,'YYYY/MM/DD')
          AND    xsi.summary_data_flag = cv_yes
          AND   ((iv_output_type = cv_output_div_10
                  AND xsi.store_check_flag = cv_no
                 )
                 OR(iv_output_type = cv_output_div_20
                    AND xsi.ship_summary_qty <> xsi.check_summary_qty
                   )
                 OR iv_output_type = cv_output_div_30
                )
          UNION
          SELECT xsi1.slip_num
          FROM   xxcoi_storage_information xsi1
                ,xxcoi_storage_information xsi2
          WHERE  xsi1.base_code         = iv_base_code
          AND    TRUNC(xsi1.slip_date) BETWEEN TO_DATE(iv_date_from,'YYYY/MM/DD') AND TO_DATE(iv_date_to,'YYYY/MM/DD')
          AND    xsi1.summary_data_flag = cv_yes
          AND    xsi1.slip_num          = xsi2.slip_num
          AND    TRUNC(xsi1.slip_date) <> TRUNC(xsi2.slip_date)
          AND    iv_output_type         = cv_output_div_20
        )xsii
  WHERE  xsi.base_code    = hca_b.account_number
-- == 2009/11/27 V1.7 Added START ===============================================================
  AND    xsi.base_code    = iv_base_code
-- == 2009/11/27 V1.7 Added END   ===============================================================
  AND    xsi.slip_type    = flv.lookup_code
  AND    iimb.item_id     = ximb.item_id
-- == 2009/09/08 V1.6 Added START ===============================================================
  AND    xsi.slip_date    BETWEEN ximb.start_date_active
                          AND     NVL(ximb.end_date_active, xsi.slip_date)
-- == 2009/09/08 V1.6 Added END   ===============================================================
  AND    xsi.item_code    = iimb.item_no
  AND    xsi.slip_num     = xsii.slip_num
  AND    flv.enabled_flag = cv_yes
  AND    flv.language     = userenv('LANG')
  AND    flv.lookup_type  = cv_list_type
  AND    TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active) AND NVL(flv.end_date_active,TRUNC(SYSDATE))
-- == 2009/07/02 V1.4 Deleted START ===============================================================
--  AND    xsi.transaction_id = ship_base.transaction_id
-- == 2009/07/02 V1.4 Deleted END   ===============================================================
  ORDER BY  xsi.slip_num
           ,xsi.slip_date
           ,xsi.base_code
           ,xsi.check_warehouse_code
           ,xsi.item_code
           ,xsi.slip_type
           ,xsi.summary_data_flag DESC;
--
  storage_info_rec storage_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_base_code   IN VARCHAR2                                      -- 1.拠点コード
    , iv_output_type IN VARCHAR2                                      -- 2.出力区分
    , iv_date_from   IN VARCHAR2                                      -- 3.出力日付（自）
    , iv_date_to     IN VARCHAR2                                      -- 4.出力日付（至）
    , ov_errbuf     OUT VARCHAR2                                      -- 5.エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2                                      -- 6.リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 7.ユーザー・エラー・メッセージ --# 固定 #
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
    lv_org_code               VARCHAR2(200);
    ld_date_from              DATE;
    ld_date_to                DATE;
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
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_10036
                    , iv_token_name1  => cv_tok_base
                    , iv_token_value1 => iv_base_code
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_10191
                    , iv_token_name1  => cv_tok_output
                    , iv_token_value1 => iv_output_type
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_10192
                    , iv_token_name1  => cv_tok_from
                    , iv_token_value1 => iv_date_from
                   );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_10193
                    , iv_token_name1  => cv_tok_to
                    , iv_token_value1 => iv_date_to
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
--
    --==============================================================
    --パラメータ日付（至）指定チェック
    --==============================================================
    gv_date_from := SUBSTRB(iv_date_from,1,10);
--
    IF (iv_date_to IS NULL) THEN
      gv_date_to := TO_CHAR(SYSDATE,'YYYY/MM/DD');
    ELSE
      gv_date_to := SUBSTRB(iv_date_to,1,10);
    END IF;
--
    BEGIN
      SELECT TO_DATE(gv_date_from,'YYYY/MM/DD')
            ,TO_DATE(gv_date_to,'YYYY/MM/DD')
      INTO   ld_date_from
            ,ld_date_to
      FROM   DUAL;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_10240
                     );
        lv_errbuf := lv_errmsg;
        RAISE prm_date_expt;
    END;
--
    IF ( TO_DATE(SUBSTRB(iv_date_from,1,10),'YYYY/MM/DD') > TO_DATE(gv_date_to,'YYYY/MM/DD') ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_10337
                   );
      lv_errbuf := lv_errmsg;
      RAISE prm_date_expt;
    END IF;
--
    --==============================================================
    --パラメータ出力区分より出力区分名称を取得
    --==============================================================
    gt_output_type_meaning := xxcoi_common_pkg.get_meaning(
                                  iv_lookup_type => cv_output_type
                                , iv_lookup_code => iv_output_type
                              );
    IF (gt_output_type_meaning IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_msg_00010
                     , iv_token_name1  => cv_tok_api
                     , iv_token_value1 => cv_api_coicmn
                   );
      lv_errbuf := lv_errmsg;
      RAISE get_output_type_expt;
    END IF;
  EXCEPTION
    WHEN prm_date_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    WHEN get_output_type_expt THEN                       --*** 出力区分名称取得エラー ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : get_output_base
   * Description      : 出力拠点取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_output_base(
      iv_base_code   IN VARCHAR2                                      -- 1.拠点コード
    , ov_errbuf     OUT VARCHAR2                                      -- 2.エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2                                      -- 3.リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 4.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_output_base'; -- プログラム名
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
    --==============================================================
    --出力対象拠点コード取得
    --==============================================================
    IF ( iv_base_code IS NULL ) THEN
      -- ===============================
      -- ログインユーザの所属拠点を取得
      -- ===============================
      xxcoi_common_pkg.get_belonging_base(
          in_user_id     => cn_created_by                             -- 1.ユーザーID
        , id_target_date => cd_creation_date                          -- 2.対象日
        , ov_base_code   => gt_base_code                              -- 3.拠点コード
        , ov_errbuf      => lv_errbuf                                 -- 4.エラー・メッセージ
        , ov_retcode     => lv_retcode                                -- 5.リターン・コード
        , ov_errmsg      => lv_errmsg                                 -- 6.ユーザー・エラー・メッセージ
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_00010
                       , iv_token_name1  => cv_tok_api
                       , iv_token_value1 => cv_api_belogin
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF ( gt_base_code IS NULL ) THEN
      gt_base_code := iv_base_code;
    END IF;
--
-- == 2009/08/07 V1.5 Modified START ===============================================================
--    SELECT xbiv.base_code
--          ,xbiv.base_short_name
--    BULK COLLECT INTO gt_base_tab
-- == 2009/04/15 V1.2 Modified START ===============================================================
--    FROM   xxcoi_base_info_v xbiv
--    FROM   xxcoi_base_info2_v xbiv
-- == 2009/04/15 V1.2 Modified END   ===============================================================
--    WHERE  xbiv.focus_base_code = gt_base_code;
    SELECT  acc.account_number
           ,SUBSTRB(acc.account_name, 1, 8)
    BULK COLLECT INTO gt_base_tab
    FROM   (SELECT hca.account_number                                 -- 拠点コード
                  ,hca.account_name                                   -- 拠点略称
            FROM   hz_cust_accounts hca                               -- 顧客マスタ
                  ,xxcmm_cust_accounts xca                            -- 顧客追加情報
            WHERE  xca.management_base_code = gt_base_code
            AND    hca.status               = 'A'
            AND    hca.customer_class_code  = '1'
            AND    hca.cust_account_id      = xca.customer_id
            UNION ALL
            SELECT hca.account_number                                 -- 拠点コード
                  ,hca.account_name                                   -- 拠点略称
            FROM   hz_cust_accounts hca                               -- 顧客マスタ
                  ,xxcmm_cust_accounts xca                            -- 顧客追加情報
            WHERE  hca.account_number       = gt_base_code
            AND    hca.status               = 'A'
            AND    hca.customer_class_code  = '1'
            AND    hca.cust_account_id      = xca.customer_id
            AND    hca.account_number      <> NVL(xca.management_base_code,'99999')
           ) acc
    ;
-- == 2009/08/07 V1.5 Modified END   ===============================================================
--
    gn_output_base_num := gt_base_tab.COUNT;
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
  END get_output_base;
--
  /**********************************************************************************
   * Procedure Name   : ins_storage_info（ループ部）
   * Description      : データ登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_storage_info(
      ir_storage_rec  IN storage_info_cur%ROWTYPE                     -- 1.入庫情報一時表レコード型
    , iv_zero_message IN VARCHAR2                                     -- 2.0件メッセージ
    , iv_output_type  IN VARCHAR2                                     -- 3.パラメータ拠点コード
    , iv_base_code    IN VARCHAR2                                     -- 4.パラメータ拠点名
    , iv_base_name    IN VARCHAR2                                     -- 5.パラメータ拠点名
    , iv_date_from    IN VARCHAR2                                     -- 6.パラメータ日付(From)
    , iv_date_to      IN VARCHAR2                                     -- 7.パラメータ日付(To)
    , ov_errbuf      OUT VARCHAR2                                     -- 8.エラー・メッセージ                  --# 固定 #
    , ov_retcode     OUT VARCHAR2                                     -- 9.リターン・コード                    --# 固定 #
    , ov_errmsg      OUT VARCHAR2 )                                   -- 10.ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_storage_info';       -- プログラム名
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
-- == 2009/07/02 V1.4 Added START ===============================================================
    lv_ship_base_name   xxcoi_rep_storage_info.ship_base_name%TYPE;
-- == 2009/07/02 V1.4 Added END   ===============================================================
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
-- == 2009/07/02 V1.4 Added START ===============================================================
    BEGIN
      IF (storage_info_rec.slip_type_code IS NULL) THEN
        lv_ship_base_name :=  NULL;
      ELSIF (storage_info_rec.slip_type_code = cv_slip_type_1) THEN
        SELECT  SUBSTRB(mil.attribute12, 1, 8)
        INTO    lv_ship_base_name
        FROM    mtl_item_locations    mil
        WHERE   mil.segment1    =   storage_info_rec.ship_base_code;
        --
      ELSIF (storage_info_rec.slip_type_code = cv_slip_type_2) THEN
        SELECT  SUBSTRB(hca.account_name, 1, 8)
        INTO    lv_ship_base_name
        FROM    hz_cust_accounts    hca
        WHERE   hca.account_number  =   storage_info_rec.ship_base_code;
        --
      ELSE
        lv_ship_base_name :=  NULL;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_ship_base_name :=  NULL;
    END;
-- == 2009/07/02 V1.4 Added END   ===============================================================
    --==============================================================
    --入庫未確認リスト帳票ワークテーブルへのデータ登録
    --==============================================================
    INSERT INTO xxcoi_rep_storage_info (
        unconfirmed_storage_id                      -- 01.入庫未確認情報ID
      , prm_output_kbn                              -- 02.パラメータ出力区分
      , prm_base_code                               -- 03.パラメータ拠点コード
      , prm_base_name                               -- 04.パラメータ拠点名
      , prm_date_from                               -- 05.パラメータ日付(From)
      , prm_date_to                                 -- 06.パラメータ日付(To)
      , base_code                                   -- 07.拠点コード
      , base_name                                   -- 08.拠点名
      , slip_date                                   -- 09.伝票日付
      , slip_num                                    -- 10.伝票No
      , warehouse_code                              -- 11.倉庫コード
      , item_code                                   -- 12.商品コード
      , item_name                                   -- 13.商品名
      , taste_term                                  -- 14.賞味期限
      , factory_unique_mark                         -- 15.工場固有記号
      , case_in_qty                                 -- 16.入数 
      , ship_case_qty                               -- 17.出庫数量ケース数
      , ship_singly_qty                             -- 18.出庫数量バラ数
      , ship_qty                                    -- 19.出庫数量本数
      , check_case_qty                              -- 20.確認数量ケース数
      , check_singly_qty                            -- 21.確認数量バラ数
      , check_qty                                   -- 22.確認数量本数
      , difference_summary_qty                      -- 23.差引合計数量
      , slip_type                                   -- 24.伝票区分
      , ship_base_code                              -- 25.出庫元拠点コード
      , ship_base_name                              -- 26.出庫元拠点名称
      , data_type                                   -- 27.データ種別
      , no_data_msg                                 -- 28.0件メッセージ格納エリア
      , last_update_date                            -- 29.最終更新日
      , last_updated_by                             -- 30.最終更新者
      , creation_date                               -- 31.作成日
      , created_by                                  -- 32.作成者
      , last_update_login                           -- 33.最終更新ユーザ
      , request_id                                  -- 34.要求ID
      , program_application_id                      -- 35.プログラムアプリケーションID
      , program_id                                  -- 36.プログラムID
      , program_update_date                         -- 37.プログラム更新日
    ) VALUES (
        xxcoi_rep_storage_info_s01.nextval          -- 01
      , iv_output_type                              -- 02
      , iv_base_code                                -- 03
      , iv_base_name                                -- 04
      , iv_date_from                                -- 05
      , iv_date_to                                  -- 06
      , storage_info_rec.base_code                  -- 07
      , storage_info_rec.base_name                  -- 08
      , storage_info_rec.slip_date                  -- 09
      , storage_info_rec.slip_num                   -- 10
      , storage_info_rec.check_warehouse_code       -- 11
      , storage_info_rec.item_code                  -- 12
      , storage_info_rec.item_name                  -- 13
      , storage_info_rec.taste_term                 -- 14
      , storage_info_rec.factory_unique_mark        -- 15
      , storage_info_rec.case_in_qty                -- 16
      , storage_info_rec.ship_case_qty              -- 17
      , storage_info_rec.ship_singly_qty            -- 18
      , storage_info_rec.ship_summary_qty           -- 19
      , storage_info_rec.check_case_qty             -- 20
      , storage_info_rec.check_singly_qty           -- 21
      , storage_info_rec.check_summary_qty          -- 22
      , storage_info_rec.difference_summary_qty     -- 23
      , storage_info_rec.slip_type                  -- 24
      , storage_info_rec.ship_base_code             -- 25
-- == 2009/07/02 V1.4 Modified START ===============================================================
--      , storage_info_rec.ship_base_name
      , lv_ship_base_name                             -- 26
-- == 2009/07/02 V1.4 Modified END   ===============================================================
      , storage_info_rec.data_type                  -- 27
      , iv_zero_message                             -- 28
      , cd_last_update_date                         -- 29
      , cn_last_updated_by                          -- 30
      , cd_creation_date                            -- 31
      , cn_created_by                               -- 32
      , cn_last_update_login                        -- 33
      , cn_request_id                               -- 34
      , cn_program_application_id                   -- 35
      , cn_program_id                               -- 36
      , cd_program_update_date                      -- 37
    );
--
    gn_normal_cnt := gn_normal_cnt + 1 ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
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
  END ins_storage_info;
--
  /**********************************************************************************
   * Procedure Name   : exec_svf_conc
   * Description      : SVFコンカレント起動(A-5)
   ***********************************************************************************/
  PROCEDURE exec_svf_conc(
      ov_errbuf     OUT VARCHAR2                                      -- 1.エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2                                      -- 2.リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_svf_conc'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --SVF帳票共通関数(SVFコンカレントの起動)
    --==============================================================
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_retcode      => lv_retcode                                  -- リターンコード
      ,ov_errbuf       => lv_errbuf                                   -- エラーメッセージ
      ,ov_errmsg       => lv_errmsg                                   -- ユーザー・エラーメッセージ
      ,iv_conc_name    => cv_pkg_name                                 -- コンカレント名
      ,iv_file_name    => cv_svf_id||TO_CHAR(SYSDATE,'YYYYMMDD')||cn_request_id     -- 出力ファイル名
      ,iv_file_id      => cv_svf_id                                   -- 帳票ID
      ,iv_output_mode  => cv_output_mode                              -- 出力区分
      ,iv_frm_file     => cv_frm_nm                                   -- フォーム様式ファイル名
      ,iv_vrq_file     => cv_vrq_nm                                   -- クエリー様式ファイル名
      ,iv_org_id       => fnd_global.org_id                           -- ORG_ID
      ,iv_user_name    => fnd_global.user_name                        -- ログイン・ユーザ名
      ,iv_resp_name    => fnd_global.resp_name                        -- ログイン・ユーザの職責名
      ,iv_doc_name     => cv_svf_id                                   -- 文書名
      ,iv_printer_name => NULL                                        -- プリンタ名
      ,iv_request_id   => cn_request_id                               -- 要求ID
      ,iv_nodata_msg   => gv_zero_message                             -- データなしメッセージ
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_00010
                     ,iv_token_name1  => cv_tok_api
                     ,iv_token_value1 => cv_api_svfcmn
                   );
      lv_errbuf := lv_errmsg;
      RAISE exec_svfapi_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN exec_svfapi_expt THEN                           --*** SVF帳票共通関数エラー ***
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
  END exec_svf_conc;
--
  /**********************************************************************************
   * Procedure Name   : get_table_lock
   * Description      : ワークテーブルロック取得(A-7)
   ***********************************************************************************/
  PROCEDURE get_table_lock(
      ov_errbuf     OUT VARCHAR2                                      -- 1.エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2                                      -- 2.リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_table_lock'; -- プログラム名
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
    CURSOR del_xrsi_tbl_cur
    IS
      SELECT 'X'
      FROM   xxcoi_rep_storage_info xrsi
      WHERE  xrsi.request_id = cn_request_id
      FOR UPDATE OF xrsi.request_id NOWAIT;
--
    -- *** ローカル・レコード ***
    del_xrsi_tbl_rec  del_xrsi_tbl_cur%ROWTYPE;
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
    --入庫未確認リスト帳票ワークテーブルロック取得
    --==============================================================
    -- カーソルオープン
    OPEN del_xrsi_tbl_cur;
    FETCH del_xrsi_tbl_cur INTO del_xrsi_tbl_rec;
    CLOSE del_xrsi_tbl_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN get_tbl_lock_expt THEN                          --*** ワークテーブルロック取得エラー ***
      IF ( del_xrsi_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrsi_tbl_cur;
      END IF;
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_10156
                   );
      lv_errbuf := lv_errmsg;
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( del_xrsi_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrsi_tbl_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( del_xrsi_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrsi_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( del_xrsi_tbl_cur%ISOPEN ) THEN
        CLOSE del_xrsi_tbl_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_table_lock;
--
  /**********************************************************************************
   * Procedure Name   : del_storage_info
   * Description      : ワークテーブルデータ削除(A-8)
   ***********************************************************************************/
  PROCEDURE del_storage_info(
      ov_errbuf     OUT VARCHAR2                                      -- 1.エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2                                      -- 2.リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_storage_info'; -- プログラム名
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    --==============================================================
    --入庫未確認リスト帳票ワークテーブル削除
    --==============================================================
    DELETE FROM xxcoi_rep_storage_info xrsi
    WHERE xrsi.request_id = cn_request_id
    ;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END del_storage_info;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_base_code   IN VARCHAR2                                      -- 1.拠点コード
    , iv_output_type IN VARCHAR2                                      -- 2.出力区分
    , iv_date_from   IN VARCHAR2                                      -- 3.出力日付（自）
    , iv_date_to     IN VARCHAR2                                      -- 4.出力日付（至）
    , ov_errbuf     OUT VARCHAR2                                      -- 5.エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2                                      -- 6.リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2 )                                    -- 7.ユーザー・エラー・メッセージ --# 固定 #
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
    lv_belonging_base         VARCHAR2(4);                            -- 所属拠点コード
    lv_prm_base_name          VARCHAR2(8);                            -- 拠点名
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
    -- A-1.初期処理
    -- ===============================
    init(
        iv_base_code   => iv_base_code                                -- 1.拠点コード
      , iv_output_type => iv_output_type                              -- 2.出力区分
      , iv_date_from   => SUBSTRB(iv_date_from,1,10)                  -- 3.出力日付（自）
      , iv_date_to     => SUBSTRB(iv_date_to,1,10)                    -- 4.出力日付（至）
      , ov_errbuf      => lv_errbuf                                   -- 5.エラー・メッセージ           --# 固定 #
      , ov_retcode     => lv_retcode                                  -- 6.リターン・コード             --# 固定 #
      , ov_errmsg      => lv_errmsg                                   -- 7.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.出力拠点取得
    -- ===============================
    get_output_base(
        iv_base_code => iv_base_code                                  -- 1.拠点コード
      , ov_errbuf    => lv_errbuf                                     -- 2.エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode                                    -- 3.リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg                                     -- 4.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 出力拠点が1件以上ある場合
    IF ( gn_output_base_num > 0 ) THEN
--
      <<gn_base_cnt_loop>>
      FOR gn_output_base_cnt IN 1 .. gn_output_base_num LOOP
    -- ===============================
    -- A-3.データ取得
    -- ===============================
        OPEN storage_info_cur( gt_base_tab(gn_output_base_cnt).base_code
                              , iv_output_type
                              , gv_date_from
                              , gv_date_to
                              );
        LOOP
          FETCH storage_info_cur INTO storage_info_rec;
          EXIT WHEN storage_info_cur%NOTFOUND;
--
          -- 対象件数カウント
          gn_target_cnt :=  gn_target_cnt + 1;
--
    -- ===============================
    -- A-4.データ登録（データ部）
    -- ===============================
          ins_storage_info(
              ir_storage_rec  => storage_info_rec                     -- 1.入庫情報一時表レコード型
            , iv_zero_message => gv_zero_message                      -- 2.0件メッセージ
            , iv_output_type  => gt_output_type_meaning               -- 3.出力区分
            , iv_base_code    => gt_base_tab(gn_output_base_cnt).base_code
                                                                      -- 4.拠点コード
            , iv_base_name    => gt_base_tab(gn_output_base_cnt).base_name
                                                                      -- 5.拠点名
            , iv_date_from    => SUBSTRB(iv_date_from,1,10)           -- 6.出力日付（自）
            , iv_date_to      => SUBSTRB(gv_date_to,1,10)             -- 7.出力日付（至）
            , ov_errbuf       => lv_errbuf                            -- 8.エラー・メッセージ           --# 固定 #
            , ov_retcode      => lv_retcode                           -- 9.リターン・コード             --# 固定 #
            , ov_errmsg       => lv_errmsg                            -- 10.ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END LOOP;
        CLOSE storage_info_cur;
      END LOOP;
    END IF;
--
    IF (gn_target_cnt = 0) THEN
    -- ===============================
    -- A-6.0件出力メッセージ
    -- ===============================
      -- 出力対象データ0件
      gv_zero_message := xxccp_common_pkg.get_msg(
                            iv_application => cv_application
                          , iv_name        => cv_msg_00008
                         );
--
      lv_belonging_base := xxcoi_common_pkg.get_base_code(
          in_user_id     => cn_created_by
        , id_target_date => xxccp_common_pkg2.get_process_date
      );
      IF ( lv_belonging_base IS NULL ) THEN
        RAISE global_api_others_expt;
      END IF;
--
      SELECT SUBSTRB(hca.account_name,1,8)
      INTO   lv_prm_base_name
      FROM   hz_cust_accounts hca
      WHERE  hca.customer_class_code = '1'
      AND    hca.account_number = gt_base_code;
--
      ins_storage_info(
          ir_storage_rec  => storage_info_rec                         -- 1.入庫情報一時表レコード型
        , iv_zero_message => gv_zero_message                          -- 2.0件メッセージ
        , iv_output_type  => gt_output_type_meaning                   -- 3.出力区分
        , iv_base_code    => gt_base_code                             -- 4.拠点コード
        , iv_base_name    => lv_prm_base_name                         -- 5.拠点名
        , iv_date_from    => SUBSTRB(iv_date_from,1,10)               -- 6.出力日付（自）
        , iv_date_to      => SUBSTRB(gv_date_to,1,10)                 -- 7.出力日付（至）
        , ov_errbuf       => lv_errbuf                                -- 9.エラー・メッセージ           --# 固定 #
        , ov_retcode      => lv_retcode                               -- 10.リターン・コード             --# 固定 #
        , ov_errmsg       => lv_errmsg                                -- 11.ユーザー・エラー・メッセージ --# 固定 #
      );
    END IF;
--
    COMMIT;
--
    -- ===============================
    -- A-5.SVFコンカレント起動
    -- ===============================
    exec_svf_conc(
        ov_errbuf    => lv_errbuf                                     -- 1.エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode                                    -- 2.リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg                                     -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-7.ワークテーブルロック取得
    -- ===============================
    get_table_lock(
        ov_errbuf    => lv_errbuf                                     -- 1.エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode                                    -- 2.リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg                                     -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-8.ワークテーブルデータ削除
    -- ===============================
    del_storage_info(
        ov_errbuf    => lv_errbuf                                     -- 1.エラー・メッセージ           --# 固定 #
      , ov_retcode   => lv_retcode                                    -- 2.リターン・コード             --# 固定 #
      , ov_errmsg    => lv_errmsg                                     -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      gn_error_cnt := gn_error_cnt + 1;
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
      errbuf        OUT VARCHAR2                                      -- 1.エラー・メッセージ  --# 固定 #
    , retcode       OUT VARCHAR2                                      -- 2.リターン・コード    --# 固定 #
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
    , iv_base_code   IN  VARCHAR2                                     -- 3.拠点コード
    , iv_output_type IN  VARCHAR2                                     -- 4.出力区分
    , iv_date_from   IN  VARCHAR2                                     -- 5.日付（From）
    , iv_date_to     IN  VARCHAR2                                     -- 6.日付（To）
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
        iv_base_code   => iv_base_code                                -- 1.拠点コード
      , iv_output_type => iv_output_type                              -- 2.出力区分
      , iv_date_from   => iv_date_from                                -- 3.出力日付（自）
      , iv_date_to     => iv_date_to                                  -- 4.出力日付（至）
      , ov_errbuf      => lv_errbuf                                   -- 5.エラー・メッセージ           --# 固定 #
      , ov_retcode     => lv_retcode                                  -- 6.リターン・コード             --# 固定 #
      , ov_errmsg      => lv_errmsg                                   -- 7.ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      fnd_file.put_line(
         which => fnd_file.log
        ,buff  => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which => fnd_file.log
        ,buff  => lv_errbuf --エラーメッセージ
      );
-- add 2009/03/05 1.1 H.Wada #034 ↓
      -- 成功件数の再設定
      gn_normal_cnt := 0;
-- add 2009/03/05 1.1 H.Wada #034 ↑
    END IF;
    --空行挿入
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
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
END XXCOI001A02R;
/
