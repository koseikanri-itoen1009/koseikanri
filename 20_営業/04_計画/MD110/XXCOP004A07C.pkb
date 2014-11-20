CREATE OR REPLACE PACKAGE BODY XXCOP004A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A07C(body)
 * Description      : 親コード出荷実績作成
 * MD.050           : 親コード出荷実績作成 MD050_COP_004_A07
 * Version          : 1.10
 *
 * Program List
 * ----------------------   ----------------------------------------------------------
 *  Name                     Description
 * ----------------------   ----------------------------------------------------------
 *  main                     コンカレント実行ファイル登録プロシージャ
 *  init                     初期処理(A-1)
 *  del_shipment_results     親コード出荷実績過去データ削除(A-2)
 *  renew_shipment_results   出荷倉庫コード最新化(A-3)
 *  get_shipment_results     出荷実績情報抽出(A-4)
 *  get_latest_code          最新出荷倉庫取得(A-5)
 *  ins_shipment_results     親コード出荷実績データ作成(A-7)
 *  upd_shipment_results     親コード出荷実績データ更新(A-8)
 *  upd_appl_contorols       前回処理日時時更新(A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   SCS.Tsubomatsu   新規作成
 *  2009/02/09    1.1   SCS.Kikuchi      結合不具合No.004対応(A-5.該当データ無しの場合の処理変更)
 *  2009/02/16    1.2   SCS.Tsubomatsu   結合不具合No.010対応(A-3.更新条件見直し)
 *  2009/04/13    1.3   SCS.Kikuchi      T1_0507対応
 *  2009/05/12    1.4   SCS.Kikuchi      T1_0951対応
 *  2009/06/15    1.5   SCS.Goto         T1_1193,T1_1194対応
 *  2009/06/29    1.6   SCS.Fukada       統合テスト障害:0000169対応
 *  2009/07/07    1.7   SCS.Sasaki       統合テスト障害:0000482対応
 *  2009/07/21    1.8   SCS.Fukada       統合テスト障害:0000800対応
 *  2009/11/09    1.9   SCS.Hokkanji     I_E_637対応
 *  2009/12/21    1.10  SCS.Kikuchi      E_本稼動_00546対応（着荷日を追加）
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
  -- ユーザー定義例外
  -- ===============================
  expt_XXCOP004A07          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP004A07C';           -- パッケージ名
  cv_date_format1           CONSTANT VARCHAR2(6)   := 'YYYYMM';                 -- 日付フォーマット
  -- プロファイル
  cv_prof_retention_period  CONSTANT VARCHAR2(28)  := 'XXCOP1_DATA_RETENTION_PERIOD';   -- 親コード出荷実績保持期間
  cv_prof_itoe_ou_mfg       CONSTANT VARCHAR2(18)  := 'XXCOP1_ITOE_OU_MFG';             -- 生産営業単位取得名称
  cv_prof_whse_code         CONSTANT VARCHAR2(26)  := 'XXCMN_COST_PRICE_WHSE_CODE';     -- 原価倉庫
  -- メッセージ・アプリケーション名（アドオン：販物・計画領域）
  cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP';
  -- メッセージ名
  cv_message_00002          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00002';
  cv_message_00007          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00007';
  cv_message_00027          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00027';
  cv_message_00028          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00028';
  cv_message_00048          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00048';
--20090629_Ver1.6_0000169_SCS.Fukada_ADD_START
  cv_message_00065          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00065';
--20090629_Ver1.6_0000169_SCS.Fukada_ADD_END
  cv_message_10017          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-10017';
  -- メッセージトークン
  cv_message_00002_token_1  CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_message_00007_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_00027_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_00028_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_00048_token_1  CONSTANT VARCHAR2(9)   := 'ITEM_NAME';
  -- テーブル名
  cv_table_xsr              CONSTANT VARCHAR2(100) := '親コード出荷実績表アドオンテーブル';
  cv_table_xac              CONSTANT VARCHAR2(100) := '計画用コントロールテーブル';
  -- 項目名
  cv_last_process_date      CONSTANT VARCHAR2(100) := '前回処理日時';
  cv_data_retention_period  CONSTANT VARCHAR2(100) := '親コード出荷実績保持期間';
  cv_delete_start_date      CONSTANT VARCHAR2(100) := '削除基準日';
  cv_itoe_ou_mfg            CONSTANT VARCHAR2(100) := '生産営業単位';
  cv_org_id                 CONSTANT VARCHAR2(100) := '生産組織ID';
  -- 固定値
  cv_req_status             CONSTANT VARCHAR2(2)   := '04';           -- 受注ヘッダアドオン.ステータス（実績計上済）
  cv_wild_item_code         CONSTANT VARCHAR2(7)   := 'ZZZZZZZ';      -- 品目ワイルドカード
  cv_chr_y                  CONSTANT VARCHAR2(1)   := 'Y';
  cv_chr_1                  CONSTANT VARCHAR2(1)   := '1';
  cv_chr_2                  CONSTANT VARCHAR2(1)   := '2';
  cv_order_categ_ord        CONSTANT VARCHAR2(5)   := 'ORDER';
  cv_order_categ_ret        CONSTANT VARCHAR2(6)   := 'RETURN';
--20090721_Ver1.8_0000800_SCS.Fukada_MOD_START
  cv_orgn_code              CONSTANT VARCHAR2(4)   := 'ITOE';
--20090721_Ver1.8_0000800_SCS.Fukada_MOD_START
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_whse_code              VARCHAR2(3);    --   OPM倉庫別カレンダ.倉庫コード（原価倉庫）
  gd_last_process_date      DATE;           --   前回処理日時
--20090629_Ver1.6_0000169_SCS.Fukada_ADD_START
  gd_process_date           DATE;           --   業務日付
  gd_last_sysdate           DATE;           --   前回処理システム日付（時分秒付き）
  gd_sysdate                DATE;           --   システム日付設定（時分秒付き）
--20090629_Ver1.6_0000169_SCS.Fukada_ADD_END
  gn_data_retention_period  NUMBER;         --   親コード出荷実績保持期間
  gd_delete_start_date      DATE;           --   過去データ削除基準日
  gv_itoe_ou_mfg            VARCHAR2(40);   --   生産営業単位
  gn_org_id                 NUMBER;         --   生産組織ID
--
  -- ===============================
  -- ユーザー定義グローバルRECORD型
  -- ===============================
  TYPE g_shipment_result_rtype IS RECORD (
    order_header_id       xxwsh_order_headers_all.order_header_id%TYPE      -- 受注ヘッダアドオン.受注ヘッダID
   ,order_line_id         xxwsh_order_lines_all.order_line_id%TYPE          -- 受注明細アドオン.受注明細ID
   ,shipping_item_code    xxwsh_order_lines_all.shipping_item_code%TYPE     -- 受注明細アドオン.出荷品目
--20091109 Ver1.9 I_E_637対応 SCS.Hokkanji ADD START
--   ,parent_item_no_ship   xxcop_item_categories1_v.parent_item_no%TYPE      -- 計画_品目カテゴリビュー1(出荷日基準).親品目No
   ,parent_item_no_ship   xxcop_item_categories2_v.parent_item_no%TYPE      -- 計画_品目カテゴリビュー2(出荷日基準).親品目No
--20091109 Ver1.9 I_E_637対応 SCS.Hokkanji ADD END
   ,result_deliver_to     xxwsh_order_headers_all.result_deliver_to%TYPE    -- 受注ヘッダアドオン.出荷先_実績
   ,deliver_from          xxwsh_order_headers_all.deliver_from%TYPE         -- 受注ヘッダアドオン.出荷元保管場所
   ,head_sales_branch     xxwsh_order_headers_all.head_sales_branch%TYPE    -- 受注ヘッダアドオン.管轄拠点
   ,shipped_date          xxwsh_order_headers_all.shipped_date%TYPE         -- 受注ヘッダアドオン.出荷日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_START
   ,arrival_date          xxwsh_order_headers_all.arrival_date%TYPE         -- 受注ヘッダアドオン.着荷日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_END
   ,shipped_quantity      xxwsh_order_lines_all.shipped_quantity%TYPE       -- 受注明細アドオン.数量
   ,uom_code              xxwsh_order_lines_all.uom_code%TYPE               -- 受注明細アドオン.単位
--20090615_Ver1.5_T1_1194_SCS.Goto_DEL_START
--   ,parent_item_no_now    xxcop_item_categories1_v.parent_item_no%TYPE      -- 計画_品目カテゴリビュー1(システム日付基準).親品目No
--20090615_Ver1.5_T1_1194_SCS.Goto_DEL_END
  );
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  TYPE g_shipment_result_ttype  IS TABLE OF g_shipment_result_rtype INDEX BY BINARY_INTEGER;  -- 出荷実績情報
  
  -- デバッグ出力判定用
  gv_debug_mode                VARCHAR2(30);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_errmsg_wk      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    ln_fiscal_year    NUMBER;          -- 現在会計年度
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・ユーザ定義例外 ***
    init_expt EXCEPTION;
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
--20090629_Ver1.6_0000169_SCS.Fukada_ADD_START
    --==============================================================
    -- システム日付取得（時分秒付き）
    --==============================================================
    gd_sysdate := SYSDATE;
--
    --==============================================================
    -- 共通関数＜業務処理日取得＞の呼び出し
    --==============================================================
    gd_process_date  :=  xxccp_common_pkg2.get_process_date;
--
    -- 業務処理日取得エラーの場合
    IF ( gd_process_date IS NULL ) THEN
        --BR100に業務処理日取得エラーメッセージを追加する
        lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_application, cv_message_00065 );
      RAISE init_expt;
    END IF;
--20090629_Ver1.6_0000169_SCS.Fukada_ADD_END
--
    --==============================================================
    --原価倉庫の取得
    --==============================================================
    gv_whse_code := FND_PROFILE.VALUE( cv_prof_whse_code );
--
    --==============================================================
    --前回処理日時の取得
    --==============================================================
    lv_errmsg_wk  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_application
                       ,iv_name         => cv_message_00048
                       ,iv_token_name1  => cv_message_00048_token_1
                       ,iv_token_value1 => cv_last_process_date
                      );
--
    BEGIN
--20090629_Ver1.6_0000169_SCS.Fukada_ADD_START
--      SELECT xac.last_process_date  last_process_date
--      INTO   gd_last_process_date
      SELECT xac.last_process_date + (1/86400)  last_process_date     -- 前回処理日付（業務日付）+ 1秒
      ,      xac.last_update_date  + (1/86400)  last_update_date      -- 最終更新日（システム日付）+ 1秒
      INTO   gd_last_process_date
      ,      gd_last_sysdate
--20090629_Ver1.6_0000169_SCS.Fukada_ADD_END
      FROM   xxcop_appl_controls xac    -- 計画用コントロールテーブル
      WHERE  xac.function_id = cv_pkg_name
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := lv_errmsg_wk;
        lv_errbuf  := SQLERRM;
        RAISE init_expt;
    END;
--
    -- 取得できない場合はエラー
--20090629_Ver1.6_0000169_SCS.Fukada_ADD_START
--    IF ( gd_last_process_date IS NULL ) THEN
    IF ( gd_last_process_date IS NULL OR gd_last_sysdate IS NULL ) THEN
--20090629_Ver1.6_0000169_SCS.Fukada_ADD_END
      lv_errmsg  := lv_errmsg_wk;
      RAISE init_expt;
    END IF;
--
    --==============================================================
    --親コード出荷実績保持期間の取得
    --==============================================================
    lv_errmsg_wk  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_application
                       ,iv_name         => cv_message_00002
                       ,iv_token_name1  => cv_message_00002_token_1
                       ,iv_token_value1 => cv_data_retention_period
                      );
--
    BEGIN
      gn_data_retention_period := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_retention_period ) );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := lv_errmsg_wk;
        lv_errbuf  := SQLERRM;
        RAISE init_expt;
    END;
--
    -- 取得できない場合はエラー
    IF ( gn_data_retention_period IS NULL ) THEN
      lv_errmsg  := lv_errmsg_wk;
      RAISE init_expt;
    END IF;

    --==============================================================
    --過去データ削除基準日算出
    --==============================================================
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_MOD_START
    gd_delete_start_date := ADD_MONTHS(gd_process_date,gn_data_retention_period * -1);
--
--    lv_errmsg_wk  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_msg_application
--                       ,iv_name         => cv_message_00048
--                       ,iv_token_name1  => cv_message_00048_token_1
--                       ,iv_token_value1 => cv_delete_start_date
--                      );
----
--    BEGIN
----20090721_Ver1.8_0000800_SCS.Fukada_MOD_START
----      -- 現在会計年度の取得
----      SELECT TO_NUMBER( icd.fiscal_year )
----      INTO   ln_fiscal_year
----      FROM   ic_cldr_dtl icd    -- OPM在庫カレンダ詳細
----            ,ic_whse_sts iws    -- OPM倉庫別カレンダ
------20090629_Ver1.6_0000169_SCS.Fukada_ADD_START
------    業務日付で倉個別カレンダを参照
------      WHERE  TO_CHAR( icd.period_end_date, cv_date_format1 ) = TO_CHAR( SYSDATE, cv_date_format1 )
----      WHERE  TO_CHAR( icd.period_end_date, cv_date_format1 ) = TO_CHAR( ADD_MONTHS(gd_process_date,-1), cv_date_format1 )
------20090629_Ver1.6_0000169_SCS.Fukada_ADD_END
----      AND    icd.period_id = iws.period_id
----      AND    iws.whse_code = gv_whse_code
----      ;
--      --
--      -- 現在会計年度の取得
--      SELECT MAX( icd.fiscal_year )
--      INTO   ln_fiscal_year
--      FROM   ic_cldr_dtl icd    -- OPM在庫カレンダ詳細
--      -- 業務日付で倉個別カレンダを参照
--      WHERE  orgn_code = cv_orgn_code
--      AND    icd.period_end_date <= gd_process_date
--      ;
--      --
----20090721_Ver1.8_0000800_SCS.Fukada_MOD_END
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg  := lv_errmsg_wk;
--        lv_errbuf  := SQLERRM;
--        RAISE init_expt;
--    END;
----
--    -- 取得できない場合はエラー
--    IF ( ln_fiscal_year IS NULL ) THEN
--      lv_errmsg  := lv_errmsg_wk;
--      RAISE init_expt;
--    END IF;
----
--    BEGIN
--      -- 過去データ削除基準日の取得
--      SELECT MAX( icd.period_end_date )
--      INTO   gd_delete_start_date
--      FROM   ic_cldr_dtl icd    -- OPM在庫カレンダ詳細
--            ,ic_whse_sts iws    -- OPM倉庫別カレンダ
--      WHERE  icd.fiscal_year = TO_CHAR( ln_fiscal_year - gn_data_retention_period )
--      AND    icd.period_id   = iws.period_id
--      AND    iws.whse_code   = gv_whse_code
--      ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg  := lv_errmsg_wk;
--        lv_errbuf  := SQLERRM;
--        RAISE init_expt;
--    END;
----
--    -- 取得できない場合はエラー
--    IF ( gd_delete_start_date IS NULL ) THEN
--      lv_errmsg  := lv_errmsg_wk;
--      RAISE init_expt;
--    END IF;
--
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_MOD_END

    --==============================================================
    --生産営業単位組織ID取得
    --==============================================================
    lv_errmsg_wk  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_application
                       ,iv_name         => cv_message_00002
                       ,iv_token_name1  => cv_message_00002_token_1
                       ,iv_token_value1 => cv_itoe_ou_mfg
                      );
--
    BEGIN
      -- 生産営業単位を取得
      gv_itoe_ou_mfg := FND_PROFILE.VALUE( cv_prof_itoe_ou_mfg );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := lv_errmsg_wk;
        lv_errbuf  := SQLERRM;
        RAISE init_expt;
    END;
--
    -- 取得できない場合はエラー
    IF ( gv_itoe_ou_mfg IS NULL ) THEN
      lv_errmsg  := lv_errmsg_wk;
      RAISE init_expt;
    END IF;
--
    lv_errmsg_wk  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_application
                       ,iv_name         => cv_message_00048
                       ,iv_token_name1  => cv_message_00048_token_1
                       ,iv_token_value1 => cv_org_id
                      );
--
    BEGIN
      -- 生産組織IDを取得
      SELECT DISTINCT haou.organization_id
      INTO   gn_org_id
      FROM   hr_all_organization_units haou   -- 在庫組織マスタ
      WHERE  haou.name = gv_itoe_ou_mfg
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := lv_errmsg_wk;
        lv_errbuf  := SQLERRM;
        RAISE init_expt;
    END;
--
    -- 取得できない場合はエラー
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := lv_errmsg_wk;
      RAISE init_expt;
    END IF;
--
  EXCEPTION
--
    WHEN init_expt THEN
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
   * Procedure Name   : del_shipment_results
   * Description      : 親コード出荷実績過去データ削除(A-2)
   ***********************************************************************************/
  PROCEDURE del_shipment_results(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_shipment_results'; -- プログラム名
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
    -- *** ローカルTABLE型 ***
    TYPE l_xsr_rowid_ttype      IS TABLE OF ROWID INDEX BY BINARY_INTEGER;    -- 親コード出荷実績アドオンテーブル.ROWID
--
    -- *** ローカルPL/SQL表 ***
    l_xsr_rowid_tab   l_xsr_rowid_ttype;  -- 親コード出荷実績アドオンテーブル.ROWID
--
    -- *** ローカル・ユーザ定義例外 ***
    del_shipment_results_expt EXCEPTION;
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
    --親コード出荷実績アドオンテーブルのロック
    --==============================================================
    BEGIN
      SELECT xsr.ROWID  xsr_rowid
      BULK COLLECT
      INTO   l_xsr_rowid_tab
      FROM   xxcop_shipment_results xsr   -- 親コード出荷実績表アドオン
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_START
--      WHERE  xsr.shipment_date <= gd_delete_start_date  -- 出荷日 ≦ 過去データ削除基準日
      WHERE  xsr.arrival_date < gd_delete_start_date  -- 着荷日 < 過去データ削除基準日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_END
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00007
                        ,iv_token_name1  => cv_message_00007_token_1
                        ,iv_token_value1 => cv_table_xsr
                       );
        lv_errbuf  := SQLERRM;
        RAISE del_shipment_results_expt;
    END;
--
    --==============================================================
    --親コード出荷実績アドオンテーブルの削除
    --==============================================================
    DELETE xxcop_shipment_results xsr   -- 親コード出荷実績表アドオン
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_START
--    WHERE  xsr.shipment_date <= gd_delete_start_date  -- 出荷日 ≦ 過去データ削除基準日
      WHERE  xsr.arrival_date < gd_delete_start_date  -- 着荷日 < 過去データ削除基準日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_END
    ;
--
--
  EXCEPTION
--
    WHEN del_shipment_results_expt THEN
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
  END del_shipment_results;
--
  /**********************************************************************************
   * Procedure Name   : renew_shipment_results
   * Description      : 出荷倉庫コード最新化(A-3)
   ***********************************************************************************/
  PROCEDURE renew_shipment_results(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'renew_shipment_results'; -- プログラム名
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
    l_xsr_rowid   ROWID;  -- 親コード出荷実績表アドオン.ROWID
--★1.2 2009/02/16 ADD START
    lv_delivery_whse_code   xxcmn_sourcing_rules.delivery_whse_code%TYPE;   -- 出荷保管倉庫コード
    lb_exist                BOOLEAN;  -- 物流構成表存在フラグ
    lb_update               BOOLEAN;  -- 最新出荷倉庫更新フラグ
--★1.2 2009/02/16 ADD END
--
    -- *** ローカル・カーソル ***
--★1.2 2009/02/16 UPD START
--★    CURSOR renew_shipment_results_cur IS
--★      SELECT xsr.ROWID                  xsr_rowid                 -- 親コード出荷実績表アドオン.ROWID
--★            ,xsrl.delivery_whse_code    latest_deliver_from_new   -- 物流構成表アドオンマスタ.出荷保管倉庫コード
--★      FROM   xxcop_shipment_results xsr       -- 親コード出荷実績表アドオン
--★            ,xxcmn_sourcing_rules xsrl        -- 物流構成表アドオンマスタ
--★      WHERE  xsr.item_no       = xsrl.item_code
--★      AND    xsr.base_code     = xsrl.base_code
--★      AND    xsr.deliver_to    = xsrl.ship_to_code
--★      AND    SYSDATE     BETWEEN xsrl.start_date_active
--★                         AND     xsrl.end_date_active
--★        -- 出荷保管倉庫コードが変わったデータを抽出
--★      AND      ( xsrl.delivery_whse_code             IS NOT NULL
--★      AND        NVL( xsr.latest_deliver_from, ' ' ) <> NVL( xsrl.delivery_whse_code, ' ' ) )
--★      ;
    -- 出荷倉庫コード最新化対象データ抽出
    CURSOR renew_data_cur IS
      -- ===================================================================================
      -- 変更のあった物流構成表アドオンマスタから見て、
      -- 変更を反映させる可能性のある親コード出荷実績表アドオンのデータを全て抽出する。
      -- （変更を反映させない場合も存在する）
      -- ===================================================================================
--20090616_Ver1.5_T1_1193_SCS.Goto_MOD_START
--      SELECT DISTINCT
--             xsr.ROWID                  xsr_rowid             -- 親コード出荷実績表アドオン.ROWID
--            ,xsr.item_no                item_no               -- 品目コード
--            ,xsr.deliver_to             deliver_to            -- 配送先コード
--            ,xsr.base_code              base_code             -- 拠点コード
--            ,xsr.latest_deliver_from    latest_deliver_from   -- 最新出荷倉庫コード
--      FROM   xxcop_shipment_results xsr       -- 親コード出荷実績表アドオン
--            ,xxcmn_sourcing_rules   xsrl      -- 物流構成表アドオンマスタ
--        -- システム日時時点で有効なデータ
--      WHERE  SYSDATE BETWEEN xsrl.start_date_active
--                     AND     xsrl.end_date_active
--          -- 前回処理日時からシステム日時までの間に有効開始となるデータ
--          -- または前回処理日時以降に更新されたデータ
--      AND  ( ( xsrl.start_date_active BETWEEN TRUNC( gd_last_process_date )
--                                      AND     SYSDATE )
--      OR     ( xsrl.last_update_date >= gd_last_process_date ) )
--          -- 配送先または拠点が一致するデータ
--      AND  ( xsr.deliver_to           = xsrl.ship_to_code
--      OR     xsr.base_code            = xsrl.base_code )
--          -- 品目が一致するデータ(ZZZZZZZ(品目ワイルドカード)の場合は除く)
--      AND    xsr.item_no              = DECODE( xsrl.item_code
--                                               ,cv_wild_item_code
--                                               ,xsr.item_no          -- 品目ワイルドカードの場合は全品目対象
--                                               ,xsrl.item_code )     -- それ以外の場合は一致する品目のみ
--      ;
      SELECT xsr.ROWID                  xsr_rowid             -- 親コード出荷実績表アドオン.ROWID
            ,xsr.item_no                item_no               -- 品目コード
            ,xsr.deliver_to             deliver_to            -- 配送先コード
            ,xsr.base_code              base_code             -- 拠点コード
            ,xsr.latest_deliver_from    latest_deliver_from   -- 最新出荷倉庫コード
      FROM   xxcop_shipment_results xsr       -- 親コード出荷実績表アドオン
      WHERE EXISTS
            ( SELECT 'X'
              FROM
                ( SELECT xsrl.base_code         base_code
                        ,xsrl.item_code         item_no
                  FROM   xxcmn_sourcing_rules   xsrl      -- 物流構成表アドオンマスタ
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--                  WHERE  xsrl.start_date_active BETWEEN TRUNC( gd_last_process_date )
--                                                    AND SYSDATE
                  -- 前回処理日時から業務日付までの間に有効開始となるデータ
                  WHERE  xsrl.start_date_active BETWEEN gd_last_process_date
                                                    AND gd_process_date
                  UNION ALL
                  SELECT xsrl.base_code         base_code
                        ,xsrl.item_code         item_no
                  FROM   xxcmn_sourcing_rules   xsrl      -- 物流構成表アドオンマスタ
--                  WHERE  xsrl.last_update_date  BETWEEN TRUNC( gd_last_process_date )
--                                                    AND SYSDATE
                  -- 前回処理日時から更新があったものを差分抽出
                  WHERE  xsrl.last_update_date  BETWEEN gd_last_sysdate
                                                    AND gd_sysdate
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
                ) xsrlv
              WHERE  xsr.base_code  = xsrlv.base_code
              AND    xsr.item_no LIKE DECODE( xsrlv.item_no
                                             ,cv_wild_item_code,'%'
                                             ,xsrlv.item_no )
            )
      UNION
      SELECT xsr.ROWID                  xsr_rowid             -- 親コード出荷実績表アドオン.ROWID
            ,xsr.item_no                item_no               -- 品目コード
            ,xsr.deliver_to             deliver_to            -- 配送先コード
            ,xsr.base_code              base_code             -- 拠点コード
            ,xsr.latest_deliver_from    latest_deliver_from   -- 最新出荷倉庫コード
      FROM   xxcop_shipment_results xsr       -- 親コード出荷実績表アドオン
      WHERE EXISTS
            ( SELECT 'X'
              FROM
                ( SELECT xsrl.ship_to_code      ship_to_code
                        ,xsrl.item_code         item_no
                  FROM   xxcmn_sourcing_rules   xsrl      -- 物流構成表アドオンマスタ
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--                  WHERE  xsrl.start_date_active BETWEEN TRUNC( gd_last_process_date )
--                                                    AND SYSDATE
                  -- 前回処理日時から業務日付までの間に有効開始となるデータ
                  WHERE  xsrl.start_date_active BETWEEN gd_last_process_date
                                                    AND gd_process_date
                  UNION ALL
                  SELECT xsrl.ship_to_code      ship_to_code
                        ,xsrl.item_code         item_no
                  FROM   xxcmn_sourcing_rules   xsrl      -- 物流構成表アドオンマスタ
--                  WHERE  xsrl.last_update_date  BETWEEN TRUNC( gd_last_process_date )
--                                                    AND SYSDATE
                  -- 前回処理日時から更新があったものを差分抽出
                  WHERE  xsrl.last_update_date  BETWEEN gd_last_sysdate
                                                    AND gd_sysdate
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
                ) xsrlv
              WHERE  xsr.deliver_to = xsrlv.ship_to_code
              AND    xsr.item_no LIKE DECODE( xsrlv.item_no
                                             ,cv_wild_item_code,'%'
                                             ,xsrlv.item_no )
            )
      ;
--20090616_Ver1.5_T1_1193_SCS.Goto_MOD_END
--
    -- 物流構成表アドオン参照パターン１(品目コード＋配送先コード)
    CURSOR get_sourcing_rules_cur1(
      lv_item_code      xxcmn_sourcing_rules.item_code%TYPE
     ,lv_ship_to_code   xxcmn_sourcing_rules.ship_to_code%TYPE )
    IS
      SELECT xsrl.delivery_whse_code  delivery_whse_code    -- 出荷保管倉庫コード
      FROM   xxcmn_sourcing_rules   xsrl  -- 物流構成表アドオンマスタ
      WHERE  xsrl.item_code      = lv_item_code
      AND    xsrl.ship_to_code   = lv_ship_to_code
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--      AND    SYSDATE BETWEEN xsrl.start_date_active
--                     AND     xsrl.end_date_active
      -- 業務日付時点で有効なデータ
      AND    gd_process_date BETWEEN xsrl.start_date_active
                             AND     xsrl.end_date_active
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
      ;
--
    -- 物流構成表アドオン参照パターン２(品目コード＋拠点コード)
    CURSOR get_sourcing_rules_cur2(
      lv_item_code      xxcmn_sourcing_rules.item_code%TYPE
     ,lv_base_code      xxcmn_sourcing_rules.base_code%TYPE )
    IS
      SELECT xsrl.delivery_whse_code  delivery_whse_code    -- 出荷保管倉庫コード
      FROM   xxcmn_sourcing_rules   xsrl  -- 物流構成表アドオンマスタ
      WHERE  xsrl.item_code      = lv_item_code
      AND    xsrl.base_code      = lv_base_code
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--      AND    SYSDATE BETWEEN xsrl.start_date_active
--                     AND     xsrl.end_date_active
      -- 業務日付時点で有効なデータ
      AND    gd_process_date BETWEEN xsrl.start_date_active
                             AND     xsrl.end_date_active
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
      ;
--
    -- 物流構成表アドオン参照パターン３(ZZZZZZZ(品目ワイルドカード)＋配送先コード)
    CURSOR get_sourcing_rules_cur3(
      lv_ship_to_code   xxcmn_sourcing_rules.ship_to_code%TYPE )
    IS
      SELECT xsrl.delivery_whse_code  delivery_whse_code    -- 出荷保管倉庫コード
      FROM   xxcmn_sourcing_rules   xsrl  -- 物流構成表アドオンマスタ
      WHERE  xsrl.item_code      = cv_wild_item_code    -- 品目ワイルドカード
      AND    xsrl.ship_to_code   = lv_ship_to_code
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--      AND    SYSDATE BETWEEN xsrl.start_date_active
--                     AND     xsrl.end_date_active
      -- 業務日付時点で有効なデータ
      AND    gd_process_date BETWEEN xsrl.start_date_active
                             AND     xsrl.end_date_active
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
      ;
--
    -- 物流構成表アドオン参照パターン４(ZZZZZZZ(品目ワイルドカード)＋拠点コード)
    CURSOR get_sourcing_rules_cur4(
      lv_base_code      xxcmn_sourcing_rules.base_code%TYPE )
    IS
      SELECT xsrl.delivery_whse_code  delivery_whse_code    -- 出荷保管倉庫コード
      FROM   xxcmn_sourcing_rules   xsrl  -- 物流構成表アドオンマスタ
      WHERE  xsrl.item_code      = cv_wild_item_code    -- 品目ワイルドカード
      AND    xsrl.base_code      = lv_base_code
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--      AND    SYSDATE BETWEEN xsrl.start_date_active
--                     AND     xsrl.end_date_active
      -- 業務日付時点で有効なデータ
      AND    gd_process_date BETWEEN xsrl.start_date_active
                             AND     xsrl.end_date_active
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
      ;
--
--★1.2 2009/02/16 UPD END
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・ユーザ定義例外 ***
    renew_shipment_results_expt EXCEPTION;
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
    --親コード、出荷倉庫コード最新化対象データのループ開始
    --==============================================================
--★1.2 2009/02/16 UPD START
--★    <<renew_shipment_results_loop>>
--★    FOR renew_shipment_results_rec IN renew_shipment_results_cur LOOP
--★--
--★      --==============================================================
--★      --親コード出荷実績アドオンテーブルのロック
--★      --==============================================================
--★      SELECT xsr.ROWID  xsr_rowid
--★      INTO   l_xsr_rowid
--★      FROM   xxcop_shipment_results xsr       -- 親コード出荷実績表アドオン
--★      WHERE  xsr.ROWID = renew_shipment_results_rec.xsr_rowid
--★      FOR UPDATE NOWAIT
--★      ;
--★--
--★      --==============================================================
--★      --親コード出荷実績のコード最新化
--★      --==============================================================
--★      UPDATE xxcop_shipment_results xsr
--★      SET    xsr.latest_deliver_from      = NVL( renew_shipment_results_rec.latest_deliver_from_new
--★                                                ,xsr.latest_deliver_from )  -- 最新出荷倉庫コード
--★            ,xsr.last_updated_by          = cn_last_updated_by                          -- 最終更新者
--★            ,xsr.last_update_date         = cd_last_update_date                         -- 最終更新日
--★            ,xsr.last_update_login        = cn_last_update_login                        -- 最終更新ログイン
--★            ,xsr.request_id               = cn_request_id                               -- 要求ID
--★            ,xsr.program_application_id   = cn_program_application_id                   -- プログラムアプリケーションID
--★            ,xsr.program_id               = cn_program_id                               -- プログラムID
--★            ,xsr.program_update_date      = cd_program_update_date                      -- プログラム更新日
--★      WHERE  xsr.ROWID = renew_shipment_results_rec.xsr_rowid
--★      ;
--★--
--★    END LOOP renew_shipment_results;
--★--
    --==============================================================
    --出荷倉庫コード最新化対象データ抽出
    --==============================================================
    <<renew_data_loop>>
    FOR renew_data_rec IN renew_data_cur LOOP
--
      -- 変数初期化
      lv_delivery_whse_code   := '';
      lb_exist                := FALSE;
      lb_update               := FALSE;
--
      --==============================================================
      --物流構成表アドオン参照パターン１(品目コード＋配送先コード)
      --==============================================================
      OPEN get_sourcing_rules_cur1(
        renew_data_rec.item_no
       ,renew_data_rec.deliver_to );
      FETCH get_sourcing_rules_cur1 INTO lv_delivery_whse_code;
      -- 該当データが存在する場合
      IF ( get_sourcing_rules_cur1%FOUND ) THEN
        -- 存在フラグをセット
        lb_exist := TRUE;
        -- 親コードの最新出荷倉庫コードと物流構成表の出荷倉庫コードが異なる場合
        IF ( NVL( renew_data_rec.latest_deliver_from, ' ' ) <> NVL( lv_delivery_whse_code, ' ' ) ) THEN
          -- 更新フラグをセット
          lb_update := TRUE;
        END IF;
      END IF;
      CLOSE get_sourcing_rules_cur1;
--
      -- 上位パターンに該当データが存在しない場合
      IF NOT lb_exist THEN
        --==============================================================
        --物流構成表アドオン参照パターン２(品目コード＋拠点コード)
        --==============================================================
        OPEN get_sourcing_rules_cur2(
          renew_data_rec.item_no
         ,renew_data_rec.base_code );
        FETCH get_sourcing_rules_cur2 INTO lv_delivery_whse_code;
        -- 該当データが存在する場合
        IF ( get_sourcing_rules_cur2%FOUND ) THEN
          -- 存在フラグをセット
          lb_exist := TRUE;
          -- 親コードの最新出荷倉庫コードと物流構成表の出荷倉庫コードが異なる場合
          IF ( NVL( renew_data_rec.latest_deliver_from, ' ' ) <> NVL( lv_delivery_whse_code, ' ' ) ) THEN
            -- 更新フラグをセット
            lb_update := TRUE;
          END IF;
        END IF;
        CLOSE get_sourcing_rules_cur2;
      END IF;
--
      -- 上位パターンに該当データが存在しない場合
      IF NOT lb_exist THEN
        --==============================================================
        --物流構成表アドオン参照パターン３(ZZZZZZZ(品目ワイルドカード)＋配送先コード)
        --==============================================================
        OPEN get_sourcing_rules_cur3( renew_data_rec.deliver_to );
        FETCH get_sourcing_rules_cur3 INTO lv_delivery_whse_code;
        -- 該当データが存在する場合
        IF ( get_sourcing_rules_cur3%FOUND ) THEN
          -- 存在フラグをセット
          lb_exist := TRUE;
          -- 親コードの最新出荷倉庫コードと物流構成表の出荷倉庫コードが異なる場合
          IF ( NVL( renew_data_rec.latest_deliver_from, ' ' ) <> NVL( lv_delivery_whse_code, ' ' ) ) THEN
            -- 更新フラグをセット
            lb_update := TRUE;
          END IF;
        END IF;
        CLOSE get_sourcing_rules_cur3;
      END IF;
--
      -- 上位パターンに該当データが存在しない場合
      IF NOT lb_exist THEN
        --==============================================================
        --物流構成表アドオン参照パターン４(ZZZZZZZ(品目ワイルドカード)＋拠点コード)
        --==============================================================
        OPEN get_sourcing_rules_cur4( renew_data_rec.base_code );
        FETCH get_sourcing_rules_cur4 INTO lv_delivery_whse_code;
        -- 該当データが存在する場合
        IF ( get_sourcing_rules_cur4%FOUND ) THEN
          -- 存在フラグをセット
          lb_exist := TRUE;
          -- 親コードの最新出荷倉庫コードと物流構成表の出荷倉庫コードが異なる場合
          IF ( NVL( renew_data_rec.latest_deliver_from, ' ' ) <> NVL( lv_delivery_whse_code, ' ' ) ) THEN
            -- 更新フラグをセット
            lb_update := TRUE;
          END IF;
        END IF;
        CLOSE get_sourcing_rules_cur4;
      END IF;
--
      -- 更新対象の場合
      IF lb_update THEN
        --==============================================================
        --親コード出荷実績アドオンテーブルのロック
        --==============================================================
        SELECT xsr.ROWID  xsr_rowid
        INTO   l_xsr_rowid
        FROM   xxcop_shipment_results xsr       -- 親コード出荷実績表アドオン
        WHERE  xsr.ROWID = renew_data_rec.xsr_rowid
        FOR UPDATE NOWAIT
        ;
--
        --==============================================================
        --親コード出荷実績のコード最新化
        --==============================================================
        UPDATE xxcop_shipment_results xsr
        SET    xsr.latest_deliver_from      = lv_delivery_whse_code       -- 最新出荷倉庫コード
              ,xsr.last_updated_by          = cn_last_updated_by          -- 最終更新者
              ,xsr.last_update_date         = cd_last_update_date         -- 最終更新日
              ,xsr.last_update_login        = cn_last_update_login        -- 最終更新ログイン
              ,xsr.request_id               = cn_request_id               -- 要求ID
              ,xsr.program_application_id   = cn_program_application_id   -- プログラムアプリケーションID
              ,xsr.program_id               = cn_program_id               -- プログラムID
              ,xsr.program_update_date      = cd_program_update_date      -- プログラム更新日
        WHERE  xsr.ROWID = renew_data_rec.xsr_rowid
        ;
      END IF;
--
    END LOOP renew_data_loop;
--
--★1.2 2009/02/16 UPD END
  EXCEPTION
--
    WHEN renew_shipment_results_expt THEN
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
  END renew_shipment_results;
--
  /**********************************************************************************
   * Procedure Name   : get_shipment_results
   * Description      : 出荷実績情報抽出(A-4)
   ***********************************************************************************/
  PROCEDURE get_shipment_results(
    o_shipment_result_tab OUT g_shipment_result_ttype,  -- 出荷実績情報
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_shipment_results'; -- プログラム名
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
    -- *** ローカル・ユーザ定義例外 ***
    get_shipment_results_expt EXCEPTION;
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
    --出荷実績情報抽出
    --==============================================================
    BEGIN
--20090413_Ver1.3_T1_0507_SCS.Kikuchi_MOD_START
--      SELECT xoha.order_header_id             order_header_id       -- 受注ヘッダアドオン.受注ヘッダアドオンID
--20090615_Ver1.5_T1_1194_SCS.Goto_MOD_START
--      SELECT /*+ ORDERED */
      SELECT
--20090615_Ver1.5_T1_1194_SCS.Goto_MOD_END
--20090707_Ver1.7_0000482_SCS.Sasaki_ADD_START
             /*+ leading(XOLA) index(xola XXWSH_OL_SALES_N01) */ 
--20090707_Ver1.7_0000482_SCS.Sasaki_ADD_END
             xoha.order_header_id             order_header_id       -- 受注ヘッダアドオン.受注ヘッダアドオンID
--20090413_Ver1.3_T1_0507_SCS.Kikuchi_MOD_END
            ,xola.order_line_id               order_line_id         -- 受注明細アドオン.受注明細アドオンID
            ,xola.shipping_item_code          shipping_item_code    -- 受注明細アドオン.出荷品目
            ,xicv_s.parent_item_no            parent_item_no_ship   -- 計画_品目カテゴリビュー1(出荷日基準).親品目No
            ,xoha.result_deliver_to           result_deliver_to     -- 受注ヘッダアドオン.出荷先_実績
            ,xoha.deliver_from                deliver_from          -- 受注ヘッダアドオン.出荷元保管場所
            ,xoha.head_sales_branch           head_sales_branch     -- 受注ヘッダアドオン.管轄拠点
            ,xoha.shipped_date                shipped_date          -- 受注ヘッダアドオン.出荷日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_START
            ,xoha.arrival_date                arrival_date          -- 受注ヘッダアドオン.着荷日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_END
--
            ,CASE
               WHEN ( otta.order_category_code = cv_order_categ_ord )
                 -- 受注タイプマスタ.受注カテゴリコードが'ORDER'の場合は数量をそのまま取得
                 THEN NVL( xola.shipped_quantity, 0 )
               WHEN ( otta.order_category_code = cv_order_categ_ret )
                 -- 受注タイプマスタ.受注カテゴリコードが'RETURN'の場合は数量×(-1)を取得
                 THEN NVL( xola.shipped_quantity, 0 ) * ( -1 )
             END                              quantity              -- 受注明細アドオン.数量
--
            ,xola.uom_code                    uom_code              -- 受注明細アドオン.単位
--20090615_Ver1.5_T1_1194_SCS.Goto_DEL_START
--            ,xicv_n.parent_item_no            parent_item_no_now    -- 計画_品目カテゴリビュー1(システム日付基準).親品目No
--20090615_Ver1.5_T1_1194_SCS.Goto_DEL_END
      BULK COLLECT
      INTO   o_shipment_result_tab
--20090413_Ver1.3_T1_0507_SCS.Kikuchi_MOD_START
--      FROM   xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
--            ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
--            ,xxcop_item_categories1_v   xicv_s    -- 品目カテゴリビュー(出荷日基準)
--            ,xxcop_item_categories1_v   xicv_n    -- 品目カテゴリビュー(システム日付基準)
--            ,oe_transaction_types_all   otta      -- 受注タイプマスタ
--            ,oe_transaction_types_tl    ottt      -- 受注タイプマスタ詳細
      FROM   oe_transaction_types_tl    ottt      -- 受注タイプマスタ詳細
            ,oe_transaction_types_all   otta      -- 受注タイプマスタ
            ,xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
--20090615_Ver1.5_T1_1194_SCS.Goto_DEL_START
--            ,xxcop_item_categories1_v   xicv_n    -- 品目カテゴリビュー(システム日付基準)
--20090615_Ver1.5_T1_1194_SCS.Goto_DEL_END
--20091109 Ver1.9 I_E_637対応 SCS.Hokkanji ADD START
            ,xxcop_item_categories2_v   xicv_s    -- 品目カテゴリビュー(出荷日基準)
--            ,xxcop_item_categories1_v   xicv_s    -- 品目カテゴリビュー(出荷日基準)
--20091109 Ver1.9 I_E_637対応 SCS.Hokkanji ADD END
--20090413_Ver1.3_T1_0507_SCS.Kikuchi_MOD_END
      WHERE  xoha.order_header_id = xola.order_header_id
--
        -- 品目カテゴリビューを出荷日基準で結合
      AND    xola.shipping_inventory_item_id     = xicv_s.inventory_item_id
      AND    xoha.shipped_date         BETWEEN     xicv_s.start_date_active
                                       AND         xicv_s.end_date_active
--20090615_Ver1.5_T1_1194_SCS.Goto_DEL_START
--        -- 品目カテゴリビューをシステム日付基準で結合
--      AND    xola.shipping_inventory_item_id     = xicv_n.inventory_item_id
--      AND    SYSDATE                   BETWEEN     xicv_n.start_date_active
--                                       AND         xicv_n.end_date_active
--20090615_Ver1.5_T1_1194_SCS.Goto_DEL_END
--
      AND    xoha.req_status                     = cv_req_status
--20090512_Ver1.4_T1_0951_SCS.Kikuchi_MOD_START
--      AND    xola.shipping_result_if_flg         = cv_chr_y
      AND    xoha.actual_confirm_class           = cv_chr_y                -- 実績計上済区分
--20090512_Ver1.4_T1_0951_SCS.Kikuchi_MOD_END
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--      AND    xola.last_update_date              >= gd_last_process_date
      -- 前回起動日時以降に更新、または新規作成されたデータ
      AND    xola.last_update_date              >= gd_last_sysdate
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
      AND    otta.attribute1                     = cv_chr_1
      AND    NVL( otta.attribute4, cv_chr_1 )   <> cv_chr_2
      AND    otta.org_id                         = gn_org_id
      AND    otta.transaction_type_id            = ottt.transaction_type_id
      AND    ottt.language                       = USERENV( 'LANG' )
      AND    xoha.order_type_id                  = otta.transaction_type_id
      ;
    EXCEPTION
      -- 対象データ0件の場合は正常終了
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
--
    WHEN get_shipment_results_expt THEN
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
  END get_shipment_results;
--
  /**********************************************************************************
   * Procedure Name   : get_latest_code
   * Description      : 最新出荷倉庫取得(A-5)
   ***********************************************************************************/
  PROCEDURE get_latest_code(
    i_shipment_result_rec IN  g_shipment_result_rtype,                        -- 出荷実績情報
    ov_delivery_whse_code OUT xxcmn_sourcing_rules.delivery_whse_code%TYPE,   -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL    ov_base_code          OUT xxcmn_sourcing_rules.base_code%TYPE,            -- 拠点コード
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_latest_code'; -- プログラム名
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
    -- *** ローカル・ユーザ定義例外 ***
    get_latest_code_expt EXCEPTION;
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
    --品目コード ＋ 配送先コードで検索
    --==============================================================
    BEGIN
      SELECT xsr.delivery_whse_code   delivery_whse_code    -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL            ,xsr.base_code            base_code             -- 拠点コード
      INTO   ov_delivery_whse_code
--★1.1 2009/02/09 DEL            ,ov_base_code
      FROM   xxcmn_sourcing_rules xsr   -- 物流構成表アドオンマスタ
      WHERE  xsr.item_code          = i_shipment_result_rec.shipping_item_code    -- 受注明細アドオン.出荷品目
      AND    xsr.ship_to_code       = i_shipment_result_rec.result_deliver_to     -- 受注ヘッダアドオン.出荷先_実績
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--      AND    SYSDATE          BETWEEN xsr.start_date_active
--                              AND     xsr.end_date_active
      -- 業務日付時点で有効なデータ
      AND    gd_process_date  BETWEEN xsr.start_date_active
                              AND     xsr.end_date_active
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
      ;
--
      -- データが取得できた場合は戻る
      RETURN;
--
    EXCEPTION
      -- 対象データ0件の場合は正常終了
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --品目コード ＋ 拠点コードで検索
    --==============================================================
    BEGIN
      SELECT xsr.delivery_whse_code   delivery_whse_code    -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL            ,xsr.base_code            base_code             -- 拠点コード
      INTO   ov_delivery_whse_code
--★1.1 2009/02/09 DEL            ,ov_base_code
      FROM   xxcmn_sourcing_rules xsr   -- 物流構成表アドオンマスタ
      WHERE  xsr.item_code          = i_shipment_result_rec.shipping_item_code    -- 受注明細アドオン.出荷品目
--★1.1 2009/02/09 UPD START
--★      AND    xsr.ship_to_code       = i_shipment_result_rec.head_sales_branch     -- 受注ヘッダアドオン.管轄拠点
      AND    xsr.base_code          = i_shipment_result_rec.head_sales_branch     -- 受注ヘッダアドオン.管轄拠点
--★1.1 2009/02/09 UPD END
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--      AND    SYSDATE          BETWEEN xsr.start_date_active
--                              AND     xsr.end_date_active
      -- 業務日付時点で有効なデータ
      AND    gd_process_date  BETWEEN xsr.start_date_active
                              AND     xsr.end_date_active
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
      ;
--
      -- データが取得できた場合は戻る
      RETURN;
--
    EXCEPTION
      -- 対象データ0件の場合は正常終了
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --ZZZZZZZ(品目ワイルドカード) ＋ 配送先コードで検索
    --==============================================================
    BEGIN
      SELECT xsr.delivery_whse_code   delivery_whse_code    -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL            ,xsr.base_code            base_code             -- 拠点コード
      INTO   ov_delivery_whse_code
--★1.1 2009/02/09 DEL            ,ov_base_code
      FROM   xxcmn_sourcing_rules xsr   -- 物流構成表アドオンマスタ
      WHERE  xsr.item_code          = cv_wild_item_code                           -- 品目ワイルドカード
      AND    xsr.ship_to_code       = i_shipment_result_rec.result_deliver_to     -- 受注ヘッダアドオン.出荷先_実績
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--      AND    SYSDATE          BETWEEN xsr.start_date_active
--                              AND     xsr.end_date_active
      -- 業務日付時点で有効なデータ
      AND    gd_process_date  BETWEEN xsr.start_date_active
                              AND     xsr.end_date_active
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
      ;
--
      -- データが取得できた場合は戻る
      RETURN;
--
    EXCEPTION
      -- 対象データ0件の場合は正常終了
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --ZZZZZZZ(品目ワイルドカード) ＋ 拠点コードで検索
    --==============================================================
    BEGIN
      SELECT xsr.delivery_whse_code   delivery_whse_code    -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL            ,xsr.base_code            base_code             -- 拠点コード
      INTO   ov_delivery_whse_code
--★1.1 2009/02/09 DEL            ,ov_base_code
      FROM   xxcmn_sourcing_rules xsr   -- 物流構成表アドオンマスタ
      WHERE  xsr.item_code          = cv_wild_item_code                           -- 品目ワイルドカード
--★1.1 2009/02/09 UPD START
--★      AND    xsr.ship_to_code       = i_shipment_result_rec.head_sales_branch     -- 受注ヘッダアドオン.管轄拠点
      AND    xsr.base_code          = i_shipment_result_rec.head_sales_branch     -- 受注ヘッダアドオン.管轄拠点
--★1.1 2009/02/09 UPD END
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--      AND    SYSDATE          BETWEEN xsr.start_date_active
--                              AND     xsr.end_date_active
      -- 業務日付時点で有効なデータ
      AND    gd_process_date  BETWEEN xsr.start_date_active
                              AND     xsr.end_date_active
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_END
      ;
--
      -- データが取得できた場合は戻る
      RETURN;
--
    EXCEPTION
      -- 対象データ0件の場合は正常終了
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
--
    WHEN get_latest_code_expt THEN
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
  END get_latest_code;
--
  /**********************************************************************************
   * Procedure Name   : ins_shipment_results
   * Description      : 親コード出荷実績データ作成(A-7)
   ***********************************************************************************/
  PROCEDURE ins_shipment_results(
    i_shipment_result_rec IN  g_shipment_result_rtype,                        -- 出荷実績情報
    iv_delivery_whse_code IN  xxcmn_sourcing_rules.delivery_whse_code%TYPE,   -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL    iv_base_code          IN  xxcmn_sourcing_rules.base_code%TYPE,            -- 拠点コード
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_shipment_results'; -- プログラム名
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
    -- *** ローカル・ユーザ定義例外 ***
    ins_shipment_results_expt EXCEPTION;
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
    --親コード出荷実績表アドオンテーブルへの登録
    --==============================================================
    BEGIN
      INSERT INTO xxcop_shipment_results (
        order_header_id               -- 受注ヘッダアドオンID
       ,order_line_id                 -- 受注明細アドオンID
       ,item_no                       -- 子品目コード
       ,parent_item_no                -- 親品目コード
       ,deliver_to                    -- 配送先コード
       ,deliver_from                  -- 出荷倉庫コード
       ,base_code                     -- 拠点コード
       ,shipment_date                 -- 出荷日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_START
       ,arrival_date                  -- 着荷日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_END
       ,quantity                      -- 数量
       ,uom_code                      -- 単位
       ,latest_parent_item_no         -- 最新親品目コード
       ,latest_deliver_from           -- 最新出荷倉庫コード
       ,created_by                    -- 作成者
       ,creation_date                 -- 作成日
       ,last_updated_by               -- 最終更新者
       ,last_update_date              -- 最終更新日
       ,last_update_login             -- 最終更新ログイン
       ,request_id                    -- 要求ID
       ,program_application_id        -- プログラムアプリケーションID
       ,program_id                    -- プログラムID
       ,program_update_date           -- プログラム更新日
      ) VALUES (
        i_shipment_result_rec.order_header_id         -- 受注ヘッダアドオンID
       ,i_shipment_result_rec.order_line_id           -- 受注明細アドオンID
       ,i_shipment_result_rec.shipping_item_code      -- 子品目コード
       ,i_shipment_result_rec.parent_item_no_ship     -- 親品目コード
       ,i_shipment_result_rec.result_deliver_to       -- 配送先コード
       ,i_shipment_result_rec.deliver_from            -- 出荷倉庫コード
--★1.1 2009/02/09 UPD START
--★       ,iv_base_code                                  -- 拠点コード
       ,i_shipment_result_rec.head_sales_branch       -- 拠点コード
--★1.1 2009/02/09 UPD END
       ,i_shipment_result_rec.shipped_date            -- 出荷日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_START
       ,i_shipment_result_rec.arrival_date            -- 着荷日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_END
       ,i_shipment_result_rec.shipped_quantity        -- 数量
       ,i_shipment_result_rec.uom_code                -- 単位
       ,NULL                                          -- 最新親品目コード
       ,iv_delivery_whse_code                         -- 最新出荷倉庫コード
       ,cn_created_by                                 -- 作成者
       ,cd_creation_date                              -- 作成日
       ,cn_last_updated_by                            -- 最終更新者
       ,cd_last_update_date                           -- 最終更新日
       ,cn_last_update_login                          -- 最終更新ログイン
       ,cn_request_id                                 -- 要求ID
       ,cn_program_application_id                     -- プログラムアプリケーションID
       ,cn_program_id                                 -- プログラムID
       ,cd_program_update_date                        -- プログラム更新日
      )
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00027
                        ,iv_token_name1  => cv_message_00027_token_1
                        ,iv_token_value1 => cv_table_xsr
                       );
        lv_errbuf  := SQLERRM;
        RAISE ins_shipment_results_expt;
    END;
--
  EXCEPTION
--
    WHEN ins_shipment_results_expt THEN
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
  END ins_shipment_results;
--
  /**********************************************************************************
   * Procedure Name   : upd_shipment_results
   * Description      : 親コード出荷実績データ更新(A-8)
   ***********************************************************************************/
  PROCEDURE upd_shipment_results(
    i_shipment_result_rec IN  g_shipment_result_rtype,                        -- 出荷実績情報
    iv_delivery_whse_code IN  xxcmn_sourcing_rules.delivery_whse_code%TYPE,   -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL    iv_base_code          IN  xxcmn_sourcing_rules.base_code%TYPE,            -- 拠点コード
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_shipment_results'; -- プログラム名
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
    l_xsr_rowid   ROWID;  -- 親コード出荷実績表アドオン.ROWID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・ユーザ定義例外 ***
    upd_shipment_results_expt EXCEPTION;
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
    --親コード出荷実績アドオンテーブルのロック
    --==============================================================
    BEGIN
      SELECT xsr.ROWID  xsr_rowid
      INTO   l_xsr_rowid
      FROM   xxcop_shipment_results xsr       -- 親コード出荷実績表アドオン
      WHERE  xsr.order_header_id = i_shipment_result_rec.order_header_id  -- 受注ヘッダアドオンID
      AND    xsr.order_line_id   = i_shipment_result_rec.order_line_id    -- 受注明細アドオンID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00007
                        ,iv_token_name1  => cv_message_00007_token_1
                        ,iv_token_value1 => cv_table_xsr
                       );
        lv_errbuf  := SQLERRM;
        RAISE upd_shipment_results_expt;
    END;
--
    --==============================================================
    --親コード出荷実績表アドオンテーブルの更新
    --==============================================================
    BEGIN
      UPDATE xxcop_shipment_results xsr   -- 親コード出荷実績表アドオン
      SET    xsr.item_no                  = i_shipment_result_rec.shipping_item_code    -- 子品目コード
            ,xsr.parent_item_no           = i_shipment_result_rec.parent_item_no_ship   -- 親品目コード
            ,xsr.deliver_to               = i_shipment_result_rec.result_deliver_to     -- 配送先コード
            ,xsr.deliver_from             = i_shipment_result_rec.deliver_from          -- 出荷倉庫コード
--★1.1 2009/02/09 UPD START
--★            ,xsr.base_code                = iv_base_code                                -- 拠点コード
            ,xsr.base_code                = i_shipment_result_rec.head_sales_branch     -- 拠点コード
--★1.1 2009/02/09 UPD END
            ,xsr.shipment_date            = i_shipment_result_rec.shipped_date          -- 出荷日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_START
            ,xsr.arrival_date             = i_shipment_result_rec.arrival_date          -- 着荷日
--20091221_Ver1.10_E_本稼動_00546_SCS.Kikuchi_ADD_END
            ,xsr.quantity                 = i_shipment_result_rec.shipped_quantity      -- 数量
            ,xsr.uom_code                 = i_shipment_result_rec.uom_code              -- 単位
            ,xsr.latest_parent_item_no    = NULL                                        -- 最新親品目コード
            ,xsr.latest_deliver_from      = iv_delivery_whse_code                       -- 最新出荷倉庫コード
            ,xsr.last_updated_by          = cn_last_updated_by                          -- 最終更新者
            ,xsr.last_update_date         = cd_last_update_date                         -- 最終更新日
            ,xsr.last_update_login        = cn_last_update_login                        -- 最終更新ログイン
            ,xsr.request_id               = cn_request_id                               -- 要求ID
            ,xsr.program_application_id   = cn_program_application_id                   -- プログラムアプリケーションID
            ,xsr.program_id               = cn_program_id                               -- プログラムID
            ,xsr.program_update_date      = cd_program_update_date                      -- プログラム更新日
      WHERE  xsr.ROWID                    = l_xsr_rowid
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00028
                        ,iv_token_name1  => cv_message_00028_token_1
                        ,iv_token_value1 => cv_table_xsr
                       );
        lv_errbuf  := SQLERRM;
        RAISE upd_shipment_results_expt;
    END;
--
  EXCEPTION
--
    WHEN upd_shipment_results_expt THEN
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
  END upd_shipment_results;
--
  /**********************************************************************************
   * Procedure Name   : upd_appl_contorols
   * Description      : 前回処理日時時更新(A-9)
   ***********************************************************************************/
  PROCEDURE upd_appl_contorols(
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_appl_contorols'; -- プログラム名
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
    l_xac_rowid   ROWID;  -- 計画用コントロールテーブル.ROWID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・ユーザ定義例外 ***
    upd_appl_contorols_expt EXCEPTION;
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
    --計画用コントロールテーブルのロック
    --==============================================================
    BEGIN
      SELECT xac.ROWID  xac_rowid
      INTO   l_xac_rowid
      FROM   xxcop_appl_controls xac    -- 計画用コントロールテーブル
      WHERE  xac.function_id = cv_pkg_name
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00007
                        ,iv_token_name1  => cv_message_00007_token_1
                        ,iv_token_value1 => cv_table_xac
                       );
        lv_errbuf  := SQLERRM;
        RAISE upd_appl_contorols_expt;
    END;
--
    --==============================================================
    --計画用コントロールテーブルの更新
    --==============================================================
    BEGIN
      UPDATE xxcop_appl_controls xac    -- 計画用コントロールテーブル
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
--      SET    xac.last_process_date        = SYSDATE                       -- 前回処理日時
      SET    xac.last_process_date        = gd_process_date               -- 前回処理日時（業務日付）
--20090629_Ver1.6_0000169_SCS.Fukada_MOD_START
            ,xac.last_updated_by          = cn_last_updated_by            -- 最終更新者
            ,xac.last_update_date         = cd_last_update_date           -- 最終更新日
            ,xac.last_update_login        = cn_last_update_login          -- 最終更新ログイン
            ,xac.request_id               = cn_request_id                 -- 要求ID
            ,xac.program_application_id   = cn_program_application_id     -- プログラムアプリケーションID
            ,xac.program_id               = cn_program_id                 -- プログラムID
            ,xac.program_update_date      = cd_program_update_date        -- プログラム更新日
      WHERE  xac.ROWID                    = l_xac_rowid
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_10017
                       );
        lv_errbuf  := SQLERRM;
        RAISE upd_appl_contorols_expt;
    END;
--
  EXCEPTION
--
    WHEN upd_appl_contorols_expt THEN
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
  END upd_appl_contorols;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_idx                   NUMBER;  -- PL/SQL表：出荷実績情報抽出のインデックス番号
    ln_xsr_count             NUMBER;  -- 親コード出荷実績表アドオン存在チェック用
    lv_delivery_whse_code    xxcmn_sourcing_rules.delivery_whse_code%TYPE;  -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL    lv_base_code             xxcmn_sourcing_rules.base_code%TYPE;           -- 拠点コード
--
    -- *** ローカルレコード ***
--    l_ifdata_rec           g_ifdata_rtype;  -- ファイルアップロードI/Fテーブル要素
--
    -- *** ローカルPL/SQL表 ***
    l_shipment_result_tab    g_shipment_result_ttype;   -- 出荷実績情報
--
    -- *** ローカル・ユーザ定義例外 ***
    submain_expt EXCEPTION;
    no_data_expt EXCEPTION;   -- 処理対象データなし
    loop_expt    EXCEPTION;   -- 対象データ処理エラー
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
    BEGIN
      -- ===============================
      -- A-1.初期処理
      -- ===============================
      init(
        ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- A-2.親コード出荷実績過去データ削除
      -- ===============================
      del_shipment_results(
        ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- A-3.親コード、出荷倉庫コード最新化
      -- ===============================
      renew_shipment_results(
        ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- A-4.出荷実績情報抽出
      -- ===============================
      get_shipment_results(
        o_shipment_result_tab  => l_shipment_result_tab   -- 出荷実績情報抽出
       ,ov_errbuf              => lv_errbuf               -- エラー・メッセージ           --# 固定 #
       ,ov_retcode             => lv_retcode              -- リターン・コード             --# 固定 #
       ,ov_errmsg              => lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- 対象件数を取得
      gn_target_cnt := l_shipment_result_tab.COUNT;
--
      -- 対象データが存在しない場合は処理をスキップする
      IF ( gn_target_cnt = 0 ) THEN
        RAISE no_data_expt;
      END IF;
--
      -- ===============================
      -- 出荷実績情報のループ開始
      -- ===============================
      <<shipment_results_loop>>
      FOR ln_idx IN l_shipment_result_tab.FIRST..l_shipment_result_tab.LAST LOOP
--
        -- ===============================
        -- A-5.最新出荷倉庫取得
        -- ===============================
        get_latest_code(
          i_shipment_result_rec  => l_shipment_result_tab( ln_idx )   -- 出荷実績情報抽出
         ,ov_delivery_whse_code  => lv_delivery_whse_code             -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL         ,ov_base_code           => lv_base_code                      -- 拠点コード
         ,ov_errbuf              => lv_errbuf                         -- エラー・メッセージ           --# 固定 #
         ,ov_retcode             => lv_retcode                        -- リターン・コード             --# 固定 #
         ,ov_errmsg              => lv_errmsg);                       -- ユーザー・エラー・メッセージ --# 固定 #
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE loop_expt;
        END IF;
--
--★1.1 2009/02/09 ADD START
        -- 最新出荷倉庫を取得できない場合は元の値を使用
        IF ( lv_delivery_whse_code IS NULL ) THEN
          lv_delivery_whse_code := l_shipment_result_tab( ln_idx ).deliver_from;
        END IF;
--
--★1.1 2009/02/09 ADD END
        -- ===============================
        -- A-6.親コード出荷実績データ存在チェック
        -- ===============================
        SELECT COUNT( 'X' ) cnt
        INTO   ln_xsr_count
        FROM   xxcop_shipment_results xsr   -- 親コード出荷実績表アドオン
        WHERE  xsr.order_header_id = l_shipment_result_tab( ln_idx ).order_header_id  -- 受注ヘッダアドオンID
        AND    xsr.order_line_id   = l_shipment_result_tab( ln_idx ).order_line_id    -- 受注明細アドオンID
        ;
--
        -- 親コード出荷実績にデータが存在しない場合
        IF ( ln_xsr_count = 0 ) THEN
--
          -- ===============================
          -- A-7.親コード出荷実績データ作成
          -- ===============================
          ins_shipment_results(
            i_shipment_result_rec  => l_shipment_result_tab( ln_idx )   -- 出荷実績情報抽出
           ,iv_delivery_whse_code  => lv_delivery_whse_code             -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL           ,iv_base_code           => lv_base_code                      -- 拠点コード
           ,ov_errbuf              => lv_errbuf                         -- エラー・メッセージ           --# 固定 #
           ,ov_retcode             => lv_retcode                        -- リターン・コード             --# 固定 #
           ,ov_errmsg              => lv_errmsg);                       -- ユーザー・エラー・メッセージ --# 固定 #
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE loop_expt;
          END IF;
--
        -- 親コード出荷実績にデータが存在しない場合
        ELSE
--
          -- ===============================
          -- A-8.親コード出荷実績データ更新
          -- ===============================
          upd_shipment_results(
            i_shipment_result_rec  => l_shipment_result_tab( ln_idx )   -- 出荷実績情報抽出
           ,iv_delivery_whse_code  => lv_delivery_whse_code             -- 出荷保管倉庫コード
--★1.1 2009/02/09 DEL           ,iv_base_code           => lv_base_code                      -- 拠点コード
           ,ov_errbuf              => lv_errbuf                         -- エラー・メッセージ           --# 固定 #
           ,ov_retcode             => lv_retcode                        -- リターン・コード             --# 固定 #
           ,ov_errmsg              => lv_errmsg);                       -- ユーザー・エラー・メッセージ --# 固定 #
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE loop_expt;
          END IF;
--
        END IF;
--
        -- 正常件数をカウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP shipment_results_loop;
--
    EXCEPTION
      WHEN no_data_expt THEN
        NULL;
      WHEN loop_expt THEN
        -- エラー件数をカウント
        gn_error_cnt := gn_error_cnt + 1;
        RAISE submain_expt;
    END;
--
    -- ===============================
    -- A-9.前回起動日時更新
    -- ===============================
    upd_appl_contorols(
      ov_errbuf              => lv_errbuf                         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode             => lv_retcode                        -- リターン・コード             --# 固定 #
     ,ov_errmsg              => lv_errmsg);                       -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE submain_expt;
    END IF;
--
    -- ===============================
    -- A-10.終了処理/エラー処理
    -- ===============================
    -- mainにて実施
--
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
    WHEN submain_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
    errbuf            OUT VARCHAR2,    --   エラー・メッセージ  --# 固定 #
    retcode           OUT VARCHAR2     --   リターン・コード    --# 固定 #
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    IF (lv_retcode = cv_status_error) THEN
      -- 正常件数を０に戻す
      gn_normal_cnt := 0;
--
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
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
--    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
--    ELSIF(lv_retcode = cv_status_warn) THEN
--      lv_message_code := cv_warn_msg;
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
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOP004A07C;
/
