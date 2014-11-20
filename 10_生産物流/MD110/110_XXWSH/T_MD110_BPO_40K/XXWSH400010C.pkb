CREATE OR REPLACE PACKAGE BODY xxwsh400010c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400010c(body)
 * Description      : 出荷依頼締め解除処理
 * MD.050           : 出荷依頼 T_MD050_BPO_401
 * MD.070           : 出荷依頼締め解除処理  T_MD070_BPO_40K
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *  ins_xxwsh_tightening_control
 *                         解除レコード登録プロシージャ
 *  check_tightening_status2 締めステータスチェック(締解除処理専用)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/04    1.0  Oracle 上原正好   初回作成
 *  2008/5/19     1.1  Oracle 上原正好   内部変更要求#80対応 パラメータ「拠点」追加
 *  2008/07/04    1.2  Oracle 北寒寺正夫 ST#366対応 締解除時の拠点、拠点カテゴリがALLの際の
 *                                       条件が共通関数の条件と異なるため共通関数からコピーし
 *                                       実装
 *  2009/01/20    1.3  Oracle 伊藤ひとみ 本番障害#1053対応
 *  2009/01/27    1.4  Oracle 上原正好   本番障害#1089対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0'; -- 正常
  gv_status_warn   CONSTANT VARCHAR2(1) := '1'; -- 警告
  gv_status_error  CONSTANT VARCHAR2(1) := '2'; -- エラー
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C'; -- ステータス(正常)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G'; -- ステータス(警告)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E'; -- ステータス(エラー)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  gv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxwsh400010c';
                                                                 -- パッケージ名
  gv_xxwsh                    CONSTANT VARCHAR2(100) := 'XXWSH';
                                                                 -- アプリケーション短縮名
  gv_line_feed                CONSTANT VARCHAR2(1)   := CHR(10);
                                                                 -- 改行コード
  gv_xxwsh_release_class      CONSTANT VARCHAR2(100) := '2';
                                                                 -- 解除（締め/解除区分）
  gv_tighten_status_1         CONSTANT VARCHAR2(100) := '1';
                                                                 -- 締めステータス 1:締め処理未実施
  gv_tighten_status_3         CONSTANT VARCHAR2(100) := '3';
                                                                 -- 締めステータス 3:締め解除
  gv_dummy_order_type_id      CONSTANT VARCHAR2(100) := '-999';
                                                                 -- ダミー受注タイプID
  gv_all                      CONSTANT VARCHAR2(100) := 'ALL';
                                                                 -- 「ALL」
  gv_output_msg               CONSTANT VARCHAR2(100) := 'APP-XXWSH-01701';
                                                                 -- 出力件数
  gv_mst_format_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11451';
                                                                 -- マスタ書式エラーメッセージ
  gv_tightening_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11452';
                                                                 -- 締め処理実施エラー
  gv_released_err             CONSTANT VARCHAR2(100) := 'APP-XXWSH-11453';
                                                                 -- 締め解除実施済みエラー
  gv_need_param_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11454';
                                                        -- 必須入力パラメータ未設定エラーメッセージ
  gv_suitable_err             CONSTANT VARCHAR2(100) := 'APP-XXWSH-11455';
                                                                 -- 妥当性チェック
  gv_alternative_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-11456';
                                                                 -- 択一入力項目エラーメッセージ
  gv_cnst_tkn_para            CONSTANT VARCHAR2(100) := 'PARAMETER';
                                                                 -- 入力パラメータ名
  gv_cnst_tkn_date            CONSTANT VARCHAR2(100) := 'DATE';
                                                                 -- 出庫日
  gv_tkn_sales_branch_category CONSTANT VARCHAR2(100) := '拠点」および「拠点カテゴリ';
                                                                 -- トークン「拠点および拠点カテゴリ」
  gv_tkn_lead_time_day        CONSTANT VARCHAR2(100) := '生産物流LT/引取変更LT';
                                                                 -- トークン「生産物流LT/引取変更LT」
  gv_tkn_schedule_ship_date   CONSTANT VARCHAR2(100) := '出庫日';
                                                                 -- トークン「出庫日」
  gv_tkn_base_record_class    CONSTANT VARCHAR2(100) := '基準レコード区分';
                                                                 -- トークン「基準レコード区分」
  gv_tkn_prod_class           CONSTANT VARCHAR2(100) := '商品区分';
                                                                 -- トークン「商品区分」
  gv_tkn_transaction_type_id CONSTANT VARCHAR2(100) := '出庫形態';
                                                                 -- トークン「出庫形態」
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- WHOカラム
  gt_user_id          xxcmn_txn_lot_cost.created_by%TYPE;             -- 作成者、最終更新者
  gt_login_id         xxcmn_txn_lot_cost.last_update_login%TYPE;      -- 最終更新ログイン
  gt_conc_request_id  xxcmn_txn_lot_cost.request_id%TYPE;             -- 要求ID
  gt_prog_appl_id     xxcmn_txn_lot_cost.program_application_id%TYPE; -- アプリケーションID
  gt_conc_program_id  xxcmn_txn_lot_cost.program_id%TYPE;             -- プログラムID
--
  -- 出荷依頼締め管理情報抽出用
  gt_order_type_id           XXWSH_TIGHTENING_CONTROL.ORDER_TYPE_ID%TYPE;         -- 受注タイプID
  gt_deliver_from            XXWSH_TIGHTENING_CONTROL.DELIVER_FROM%TYPE;          -- 出荷元保管場所
  gt_prod_class_type         XXWSH_TIGHTENING_CONTROL.PROD_CLASS%TYPE;            -- 商品区分
  gt_sales_branch            XXWSH_TIGHTENING_CONTROL.SALES_BRANCH%TYPE; -- 拠点
  gt_sales_branch_category   XXWSH_TIGHTENING_CONTROL.SALES_BRANCH_CATEGORY%TYPE; -- 拠点カテゴリ
  gt_lead_time_day           XXWSH_TIGHTENING_CONTROL.LEAD_TIME_DAY%TYPE;         -- 生産物流LT/引取変更LT
  gt_schedule_ship_date      XXWSH_TIGHTENING_CONTROL.SCHEDULE_SHIP_DATE%TYPE;    -- 出荷予定日
  gt_tighten_release_class   XXWSH_TIGHTENING_CONTROL.TIGHTEN_RELEASE_CLASS%TYPE; -- 締め／解除区分
  gt_base_record_class       XXWSH_TIGHTENING_CONTROL.BASE_RECORD_CLASS%TYPE;     -- 基準レコード区分
  gt_system_date             DATE;                                                -- システム日付
--
  /**********************************************************************************
   * Procedure Name   : ins_xxwsh_tightening_control
   * Description      : 解除レコードの登録(K-3)
   ***********************************************************************************/
  PROCEDURE ins_xxwsh_tightening_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxwsh_tightening_control'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***************************************
--
    --出荷依頼締め管理アドオンテーブルへの登録
    INSERT INTO xxwsh_tightening_control
       (transaction_id            -- トランザクションid
        ,concurrent_id            -- コンカレントid
        ,order_type_id            -- 受注タイプid
        ,deliver_from             -- 出荷元保管場所
        ,prod_class               -- 商品区分
        ,sales_branch             -- 拠点
        ,sales_branch_category    -- 拠点カテゴリ
        ,lead_time_day            -- 生産物流lt/引取変更lt
        ,schedule_ship_date       -- 出荷予定日
        ,tighten_release_class    -- 締め／解除区分
        ,tightening_date          -- 締め実施日時
        ,base_record_class        -- 基準レコード区分
        ,created_by               -- 作成者
        ,creation_date            -- 作成日
        ,last_updated_by          -- 最終更新者
        ,last_update_date         -- 最終更新日
        ,last_update_login        -- 最終更新ログイン
        ,request_id               -- 要求id
        ,program_application_id   -- コンカレント・プログラム・アプリケーションid
        ,program_id               -- コンカレント・プログラムid
        ,program_update_date      -- プログラム更新日
       )
       VALUES
       (xxwsh_tightening_control_s1.NEXTVAL  -- トランザクションID
        ,gt_conc_request_id                  -- コンカレントID
        ,gt_order_type_id                    -- 受注タイプID
        ,gt_deliver_from                     -- 出荷元保管場所
        ,gt_prod_class_type                  -- 商品区分
        ,gt_sales_branch                     -- 拠点
        ,gt_sales_branch_category            -- 拠点カテゴリ
        ,gt_lead_time_day                    -- 生産物流LT/引取変更LT
        ,gt_schedule_ship_date               -- 出荷予定日
        ,gt_tighten_release_class            -- 締め／解除区分
        ,gt_system_date                      -- 締め実施日時
        ,gt_base_record_class                -- 基準レコード区分
        ,gt_user_id                          -- 作成者
        ,gt_system_date                      -- 作成日
        ,gt_user_id                          -- 最終更新者
        ,gt_system_date                      -- 最終更新日
        ,gt_login_id                         -- 最終更新ログイン
        ,gt_conc_request_id                  -- 要求ID
        ,gt_prog_appl_id                     -- コンカレント・プログラム・アプリケーションID
        ,gt_conc_program_id                  -- コンカレント・プログラムID
        ,gt_system_date                      -- プログラム更新日
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_xxwsh_tightening_control;
-- Ver1.2 M.Hokkanji Start
-- 拠点ALL、拠点カテゴリ0(ALL)の場合の条件を共通関数と変更するため締めステータスチェック関数をコピー
--
  /**********************************************************************************
   * Function Name    : check_tightening_status2
   * Description      : 締めステータスチェック関数(締解除処理専用)
   ***********************************************************************************/
  FUNCTION check_tightening_status2(
    -- 1.受注タイプID
    in_order_type_id          IN  xxwsh_tightening_control.order_type_id%TYPE,
    -- 2.出荷元保管場所
    iv_deliver_from           IN  xxwsh_tightening_control.deliver_from%TYPE,
    -- 3.拠点
    iv_sales_branch           IN  xxwsh_tightening_control.sales_branch%TYPE,
    -- 4.拠点カテゴリ
    iv_sales_branch_category  IN  xxwsh_tightening_control.sales_branch_category%TYPE,
    -- 5.生産物流LT
    in_lead_time_day          IN  xxwsh_tightening_control.lead_time_day%TYPE,
    -- 6.出庫日
    id_ship_date              IN  xxwsh_tightening_control.schedule_ship_date%TYPE,
    -- 7.商品区分
    iv_prod_class             IN  xxwsh_tightening_control.prod_class%TYPE)
    RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'check_tightening_status2'; -- プログラム名
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_all                CONSTANT NUMBER        := -999;                      -- ALL(数値項目)
    cv_all                CONSTANT VARCHAR2(3)   := 'ALL';                     -- ALL(文字項目)
    cv_yes                CONSTANT VARCHAR2(1)   := 'Y';                       -- YES
    cv_no                 CONSTANT VARCHAR2(1)   := 'N';                       -- NO
    cv_close              CONSTANT VARCHAR2(1)   := '1';                       -- 締め
    cv_cancel             CONSTANT VARCHAR2(1)   := '2';                       -- 解除
    cv_inside_err         CONSTANT VARCHAR2(2)   := '-1';                      -- 内部エラー
    cv_close_proc_n_enfo  CONSTANT VARCHAR2(1)   := '1';                       -- 締め処理未実施
    cv_first_close_fin    CONSTANT VARCHAR2(1)   := '2';                       -- 初回締め済
    cv_close_cancel       CONSTANT VARCHAR2(1)   := '3';                       -- 締め解除
    cv_re_close_fin       CONSTANT VARCHAR2(1)   := '4';                       -- 再締め済
    cv_customer_class_code_1 CONSTANT VARCHAR2(1)   := '1';                    -- 顧客区分：1
    cv_prod_class_1       CONSTANT VARCHAR2(1)   := '1';                       -- 商品区分：1
    cv_prod_class_2       CONSTANT VARCHAR2(1)   := '2';                       -- 商品区分：2
    cv_sales_branch_category_0 CONSTANT VARCHAR2(1)   := '0';                  -- 拠点カテゴリ：0
--
    -- *** ローカル変数 ***
    ln_count                  NUMBER;            -- カウント件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    BEGIN
      -- 締め解除状態チェック
      -- パラメータ「拠点」が入力された場合
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- 「拠点」および、「拠点」に紐付く「拠点カテゴリ」で解除レコードを検索      
-- Ver1.3 H.Itou Mod Start 締め管理テーブルの拠点がALLの場合は顧客マスタを結合しない
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
--        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
--                                                ,xtc.sales_branch_category)
--                                          IN (DECODE(xtc.prod_class
--                                                     , cv_prod_class_2, xcav.drink_base_category
--                                                     , cv_prod_class_1, xcav.leaf_base_category)
--                                              ,cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_cancel
--        AND     xcav.party_number         =  iv_sales_branch
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  iv_sales_branch
                AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                        ,xtc.sales_branch_category)
                                                  IN (DECODE(xtc.prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                      ,cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel
                AND     xcav.party_number         =  xtc.sales_branch
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
-- Ver1.4 M.Uehara Add start
                AND     (xtc.sales_branch_category = ( SELECT  DECODE(iv_prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                        FROM xxcmn_cust_accounts2_v    xcav
                                                       WHERE xcav.party_number         =  iv_sales_branch
                                                         AND     xcav.start_date_active    <= id_ship_date
                                                         AND     xcav.end_date_active      >= id_ship_date)
                         OR xtc.sales_branch_category = cv_all)
-- Ver1.3 M.Uehara Add End
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- 合致するデータがあれば｢締め解除｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        END IF;
--
      -- パラメータ「拠点カテゴリ」が入力された場合
      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
        -- 「拠点カテゴリ」および、「拠点カテゴリ」に紐付く全ての「拠点」で解除レコードを検索
-- Ver1.3 H.Itou Mod Start 締め管理テーブルの拠点がALLの場合は顧客マスタを結合しない
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_cancel
--        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
--        AND     iv_sales_branch_category
--                                          IN (DECODE(iv_prod_class
--                                 , cv_prod_class_2, xcav.drink_base_category
--                                 , cv_prod_class_1, xcav.leaf_base_category)
--                                 ,cv_all)
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch         <>  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel
                AND     xtc.sales_branch          =  xcav.party_number
                AND     iv_sales_branch_category
                                                  IN (DECODE(iv_prod_class
                                         , cv_prod_class_2, xcav.drink_base_category
                                         , cv_prod_class_1, xcav.leaf_base_category)
                                         ,cv_all)
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_cancel)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- 合致するデータが1件でもあれば｢締め解除｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        END IF;
--
      -- パラメータ「拠点」および「拠点カテゴリ」が'ALL'の場合
      ELSIF ((NVL(iv_sales_branch,cv_all) = cv_all) AND (NVL(iv_sales_branch_category,cv_all) = cv_all)) THEN
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
-- Ver1.4 M.Uehara Del start
--        AND     xtc.sales_branch          =  cv_all
--        AND     xtc.sales_branch_category =  cv_all
-- Ver1.4 M.Uehara Del end
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_cancel;
--
        -- 合致するデータが1件でもあれば｢締め解除｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_close_cancel;
        END IF;
      END IF;
--
      -- 再締め状態チェック
      -- パラメータ「拠点」が入力された場合
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- 「拠点」および、「拠点」に紐付く「拠点カテゴリ」で解除レコードを検索
-- Ver1.3 H.Itou Mod Start 締め管理テーブルの拠点がALLの場合は顧客マスタを結合しない
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
--        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
--                                                ,xtc.sales_branch_category)
--                                          IN (DECODE(xtc.prod_class
--                                                     , cv_prod_class_2, xcav.drink_base_category
--                                                     , cv_prod_class_1, xcav.leaf_base_category)
--                                              ,cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xcav.party_number         =  iv_sales_branch
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          = iv_sales_branch
                AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                        ,xtc.sales_branch_category)
                                                  IN (DECODE(xtc.prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                      ,cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close
                AND     xcav.party_number         =  xtc.sales_branch
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
-- Ver1.4 M.Uehara Add start
                AND     (xtc.sales_branch_category = ( SELECT  DECODE(iv_prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                        FROM xxcmn_cust_accounts2_v    xcav
                                                       WHERE xcav.party_number         =  iv_sales_branch
                                                         AND     xcav.start_date_active    <= id_ship_date
                                                         AND     xcav.end_date_active      >= id_ship_date)
                         OR xtc.sales_branch_category = cv_all)
-- Ver1.3 M.Uehara Add End
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- 合致するデータがあれば｢再締め済み｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        END IF;
--
      -- パラメータ「拠点カテゴリ」が入力された場合
      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
        -- 「拠点カテゴリ」および、「拠点カテゴリ」に紐付く全ての「拠点」で解除レコードを検索
-- Ver1.3 H.Itou Mod Start 締め管理テーブルの拠点がALLの場合は顧客マスタを結合しない
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_no
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
--        AND     iv_sales_branch_category
--                                          IN (DECODE(iv_prod_class
--                                 , cv_prod_class_2, xcav.drink_base_category
--                                 , cv_prod_class_1, xcav.leaf_base_category)
--                                 ,cv_all)
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch         <>  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close
                AND     xtc.sales_branch          =  xcav.party_number
                AND     iv_sales_branch_category
                                                  IN (DECODE(iv_prod_class
                                         , cv_prod_class_2, xcav.drink_base_category
                                         , cv_prod_class_1, xcav.leaf_base_category)
                                         ,cv_all)
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_no
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- 合致するデータが1件でもあれば｢再締め済み｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        END IF;
--
      -- パラメータ「拠点」および「拠点カテゴリ」が'ALL'の場合
      ELSIF ((NVL(iv_sales_branch,cv_all) = cv_all) AND (NVL(iv_sales_branch_category,cv_all) = cv_all)) THEN
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.sales_branch          =  cv_all
        AND     xtc.sales_branch_category =  cv_all
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_no
        AND     xtc.tighten_release_class =  cv_close;
--
        -- 合致するデータが1件でもあれば｢再締め済み｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_re_close_fin;
        END IF;
      END IF;
--
      -- 初回締め状態チェック
      -- パラメータ「拠点」が入力された場合
      IF ((iv_sales_branch IS NOT NULL) AND (iv_sales_branch <> 'ALL')) THEN
        -- 「拠点」および、「拠点」に紐付く「拠点カテゴリ」で解除レコードを検索
-- Ver1.3 H.Itou Mod Start 締め管理テーブルの拠点がALLの場合は顧客マスタを結合しない
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch          IN (NVL(iv_sales_branch, cv_all), cv_all)
--        AND     DECODE(xtc.sales_branch_category,NULL,cv_all
--                                                ,xtc.sales_branch_category)
--                                          IN (DECODE(xtc.prod_class
--                                                     , cv_prod_class_2, xcav.drink_base_category
--                                                     , cv_prod_class_1, xcav.leaf_base_category)
--                                              ,cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_yes
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xcav.party_number         =  iv_sales_branch
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  iv_sales_branch
                AND     DECODE(xtc.sales_branch_category,NULL,cv_all
                                                        ,xtc.sales_branch_category)
                                                  IN (DECODE(xtc.prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                      ,cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close
                AND     xcav.party_number         =  xtc.sales_branch
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
-- Ver1.4 M.Uehara Add start
                AND     (xtc.sales_branch_category = ( SELECT  DECODE(iv_prod_class
                                                             , cv_prod_class_2, xcav.drink_base_category
                                                             , cv_prod_class_1, xcav.leaf_base_category)
                                                        FROM xxcmn_cust_accounts2_v    xcav
                                                       WHERE xcav.party_number         =  iv_sales_branch
                                                         AND     xcav.start_date_active    <= id_ship_date
                                                         AND     xcav.end_date_active      >= id_ship_date)
                         OR xtc.sales_branch_category = cv_all)
-- Ver1.3 M.Uehara Add End
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- 合致するデータがあれば｢初回締め済｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        END IF;
--
      -- パラメータ「拠点カテゴリ」が入力された場合
      ELSIF ((iv_sales_branch_category IS NOT NULL) AND (iv_sales_branch_category <> 'ALL')) THEN
        -- 「拠点カテゴリ」および、「拠点カテゴリ」に紐付く全ての「拠点」で解除レコードを検索
-- Ver1.3 H.Itou Mod Start 締め管理テーブルの拠点がALLの場合は顧客マスタを結合しない
--        SELECT  COUNT(*)
--        INTO    ln_count
--        FROM    xxwsh_tightening_control  xtc
--               ,xxcmn_cust_accounts2_v    xcav
--        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
--        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
--        AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
--        AND     xtc.lead_time_day         =  in_lead_time_day
--        AND     xtc.schedule_ship_date    =  id_ship_date
--        AND     xtc.prod_class            =  iv_prod_class
--        AND     xtc.base_record_class     =  cv_yes
--        AND     xtc.tighten_release_class =  cv_close
--        AND     xtc.sales_branch          IN (xcav.party_number, cv_all)
--        AND     iv_sales_branch_category
--                                          IN (DECODE(iv_prod_class
--                                 , cv_prod_class_2, xcav.drink_base_category
--                                 , cv_prod_class_1, xcav.leaf_base_category)
--                                 ,cv_all)
--        AND     xcav.start_date_active    <= id_ship_date
--        AND     xcav.end_date_active      >= id_ship_date
--        AND     xcav.customer_class_code  =  cv_customer_class_code_1;
--
        SELECT  COUNT(1) cnt
        INTO    ln_count
        FROM   (-- 拠点がALLでない場合(顧客マスタを結合)
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                       ,xxcmn_cust_accounts2_v    xcav
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch         <>  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close
                AND     xtc.sales_branch          =  xcav.party_number
                AND     iv_sales_branch_category
                                                  IN (DECODE(iv_prod_class
                                         , cv_prod_class_2, xcav.drink_base_category
                                         , cv_prod_class_1, xcav.leaf_base_category)
                                         ,cv_all)
                AND     xcav.start_date_active    <= id_ship_date
                AND     xcav.end_date_active      >= id_ship_date
                AND     xcav.customer_class_code  =  cv_customer_class_code_1
                -- 拠点がALLの場合
                UNION ALL
                SELECT  1
                FROM    xxwsh_tightening_control  xtc
                WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
                AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
                AND     xtc.sales_branch          =  cv_all
                AND     xtc.sales_branch_category IN (iv_sales_branch_category, cv_all)
                AND     xtc.lead_time_day         =  in_lead_time_day
                AND     xtc.schedule_ship_date    =  id_ship_date
                AND     xtc.prod_class            =  iv_prod_class
                AND     xtc.base_record_class     =  cv_yes
                AND     xtc.tighten_release_class =  cv_close)
                ;
-- Ver1.3 H.Itou Mod End
--
        -- 合致するデータが1件でもあれば｢初回締め済｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        END IF;
--
      -- パラメータ「拠点」および「拠点カテゴリ」が'ALL'の場合
      ELSIF ((NVL(iv_sales_branch,cv_all) = cv_all) AND (NVL(iv_sales_branch_category,cv_all) = cv_all)) THEN
        SELECT  COUNT(*)
        INTO    ln_count
        FROM    xxwsh_tightening_control  xtc
        WHERE   xtc.order_type_id         IN (NVL(in_order_type_id, cn_all), cn_all)
        AND     xtc.deliver_from          IN (NVL(iv_deliver_from, cv_all), cv_all)
        AND     xtc.sales_branch          =  cv_all
        AND     xtc.sales_branch_category =  cv_all
        AND     xtc.lead_time_day         =  in_lead_time_day
        AND     xtc.schedule_ship_date    =  id_ship_date
        AND     xtc.prod_class            =  iv_prod_class
        AND     xtc.base_record_class     =  cv_yes
        AND     xtc.tighten_release_class =  cv_close;
--
        -- 合致するデータが1件でもあれば｢初回締め済｣を返す
        IF (ln_count > 0) THEN
          RETURN cv_first_close_fin;
        END IF;
      END IF;
--
      -- 合致するデータがない場合は｢締め処理未実施｣を返す
      RETURN cv_close_proc_n_enfo;
--
    EXCEPTION
      -- その他の例外時には｢内部エラー｣を返す
      WHEN OTHERS THEN
        RETURN cv_inside_err;
    END;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_tightening_status2;
-- Ver1.2 M.Hokkanji End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_transaction_type_id    IN VARCHAR2,     --   出庫形態
    iv_shipped_locat_code     IN VARCHAR2,     --   出庫元
    iv_sales_branch           IN VARCHAR2,     --   拠点
    iv_sales_branch_category  IN VARCHAR2,     --   拠点カテゴリ
    iv_lead_time_day          IN VARCHAR2,     --   生産物流LT/引取変更LT
    iv_ship_date              IN VARCHAR2,     --   出庫日
    iv_base_record_class      IN VARCHAR2,     --   基準レコード区分
    iv_prod_class             IN VARCHAR2,     --   商品区分
    ov_errbuf                 OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    cv_prod_class        CONSTANT VARCHAR2(1) :=  '1';    -- 商品区分「リーフ」
    cv_prod_class2       CONSTANT VARCHAR2(1) :=  '2';    -- 商品区分「ドリンク」
-- Ver1.2 M.Hokkanji Start
    cv_sales_branch_category_0 CONSTANT VARCHAR2(1)   := '0';  -- 拠点カテゴリ：0
-- Ver1.2 M.Hokkanji End
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
    lv_tighten_status VARCHAR2(1);     -- 締めステータス
--
    -- *** ローカル変数 ***
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- WHOカラム取得
    gt_user_id          := FND_GLOBAL.USER_ID;          -- 作成者、最終更新者
    gt_login_id         := FND_GLOBAL.LOGIN_ID;         -- 最終更新ログイン
    gt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- 要求ID
    gt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- アプリケーションID
    gt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- プログラムID
--
    gt_system_date      := SYSDATE;                     -- システム日付
--
    -- **************************************************
    -- *** 入力パラメータチェック(K-1)
    -- **************************************************
--
--  必須チェック
--
    -- 「拠点」および「拠点カテゴリ」がNULLの場合
    IF (iv_sales_branch IS NULL) AND (iv_sales_branch_category IS NULL) THEN
      -- 拠点および拠点カテゴリの必須入力パラメータ未設定エラーメッセージをセットします
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_need_param_err,
                                        gv_cnst_tkn_para,
                                        gv_tkn_sales_branch_category) || gv_line_feed;
    -- 「拠点」および「拠点カテゴリ」の両方がNULLでない場合
    ELSIF (iv_sales_branch IS NOT NULL) AND (iv_sales_branch_category IS NOT NULL) THEN
      -- 択一入力項目エラーメッセージをセットします
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_alternative_err) || gv_line_feed;
    -- 「拠点」のみがNULLでない場合
    ELSIF  (iv_sales_branch IS NOT NULL) AND (iv_sales_branch_category IS NULL) THEN
      -- 「拠点」設定
      gt_sales_branch := iv_sales_branch; -- 拠点
      -- 「拠点カテゴリ」に「ALL」を設定
      gt_sales_branch_category := gv_all; -- 拠点カテゴリ
    -- 「拠点カテゴリ」のみがNULLでない場合
    ELSIF  (iv_sales_branch IS NULL) AND (iv_sales_branch_category IS NOT NULL) THEN
      -- 「拠点カテゴリ」設定
-- Ver1.2 M.Hokkanji Start
      -- 拠点カテゴリが0(ALL)の場合は'ALL'に変更
      IF ( iv_sales_branch_category = cv_sales_branch_category_0) THEN
        gt_sales_branch_category := gv_all; -- 拠点カテゴリ
      ELSE
        gt_sales_branch_category := iv_sales_branch_category; -- 拠点カテゴリ
      END IF;
-- Ver1.2 M.Hokkanji End
      -- 「拠点」に「ALL」を設定
      gt_sales_branch := gv_all; -- 拠点
    END IF;
--
    -- 「生産物流LT/引取変更LT」チェック
    IF (iv_lead_time_day IS NULL) THEN
      -- 生産物流LT/引取変更LTのNULLチェックを行います
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_need_param_err,
                                        gv_cnst_tkn_para,
                                        gv_tkn_lead_time_day) || gv_line_feed;
    ELSE
      -- 「生産物流LT/引取変更LT」の書式変換(NUMBER)
      gt_lead_time_day := TO_NUMBER(iv_lead_time_day);
    END IF;
--
    -- 「出庫日」チェック
    IF (iv_ship_date IS NULL) THEN
      -- 出庫日のNULLチェックを行います
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_need_param_err,
                                        gv_cnst_tkn_para,
                                        gv_tkn_schedule_ship_date) || gv_line_feed;
    ELSE
      -- 「出庫日」の書式変換(YYYY/MM/DD)
      gt_schedule_ship_date := FND_DATE.STRING_TO_DATE(iv_ship_date,'YYYY/MM/DD');
      -- 変換エラー時
      IF (gt_schedule_ship_date IS NULL) THEN
        lv_errmsg := lv_errmsg || xxcmn_common_pkg.get_msg( gv_xxwsh
                                                       ,gv_mst_format_err
                                                       ,gv_cnst_tkn_date
                                                       ,iv_ship_date
                                                      ) || gv_line_feed;
      END IF;
    END IF;
--
    -- 「基準レコード区分」チェック
    IF (iv_base_record_class IS NULL) THEN
      -- 基準レコード区分のNULLチェックを行います
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_need_param_err,
                                        gv_cnst_tkn_para,
                                        gv_tkn_base_record_class) || gv_line_feed;
    END IF;
--
--  妥当性チェック
--
    -- 「商品区分」妥当性チェック
    IF ((iv_prod_class <> cv_prod_class) AND (iv_prod_class <> cv_prod_class2)) THEN
      -- 商品区分区分に1、2以外のチェックを行います
      lv_errmsg := lv_errmsg ||
               xxcmn_common_pkg.get_msg(gv_xxwsh,
                                        gv_suitable_err) || gv_line_feed;
    ELSE
      gt_prod_class_type := iv_prod_class;
--
      -- 商品区分が1：「リーフ」の場合
      IF (iv_prod_class = cv_prod_class) THEN
        -- 「出庫形態」チェック
        IF (iv_transaction_type_id IS NULL) THEN
          -- 出庫形態のNULLチェックを行います
          lv_errmsg := lv_errmsg ||
                   xxcmn_common_pkg.get_msg(gv_xxwsh,
                                            gv_need_param_err,
                                            gv_cnst_tkn_para,
                                            gv_tkn_transaction_type_id) || gv_line_feed;
        ELSE
          -- 「受注タイプID」設定
          gt_order_type_id         := TO_NUMBER(iv_transaction_type_id); -- 受注タイプID
        END IF;
      -- 商品区分が2：「ドリンク」の場合
      ELSIF  (iv_prod_class = cv_prod_class2) THEN
        -- 「受注タイプID」設定
        IF (iv_transaction_type_id IS NULL) THEN
          -- 受注タイプIDがNULLの場合、「-999」をセット
          gt_order_type_id         := TO_NUMBER(gv_dummy_order_type_id); -- ダミー受注タイプID
        ELSE
          gt_order_type_id         := TO_NUMBER(iv_transaction_type_id); -- 受注タイプID
        END IF;
      END IF;
    END IF;
--
    -- 「出荷元保管場所」設定
    IF (iv_shipped_locat_code IS NULL) THEN
      -- 出庫元がNULLの場合、「ALL」をセット
      gt_deliver_from         := gv_all; -- ALL
    ELSE
      gt_deliver_from         := iv_shipped_locat_code; -- 出庫元
    END IF;
--
    -- 「基準レコード区分」設定
    gt_base_record_class     := iv_base_record_class;     -- 基準レコード区分
--
    -- 「締め／解除区分」設定
    gt_tighten_release_class := gv_xxwsh_release_class;     -- 締め／解除区分(2：解除)
--
    -- **************************************************
    -- *** メッセージの整形
    -- **************************************************
    -- メッセージが登録されている場合
    IF (lv_errmsg IS NOT NULL) THEN
      -- 最後の改行コードを削除しOUTパラメータに設定
      lv_errmsg := RTRIM(lv_errmsg, gv_line_feed);
      -- エラーとして終了
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 締め処理実施チェック (K-2)
    -- ===============================
-- Ver1.2 M.Hokkanji Start
-- 締め処理と締め解除処理でチェックを分ける必要があるため呼ぶ関数を変更
--    lv_tighten_status := xxwsh_common_pkg.check_tightening_status(
    lv_tighten_status := check_tightening_status2(
-- Ver1.2 M.Hokkanji End
      gt_order_type_id,                --   受注タイプID(出庫形態)
      gt_deliver_from,                 --   出庫元保管場所
      gt_sales_branch,                 --   拠点
      gt_sales_branch_category,        --   拠点カテゴリ
      gt_lead_time_day,                --   生産物流LT/引取変更LT
      gt_schedule_ship_date,           --   出庫日
      gt_prod_class_type               --   商品区分
      );
--
    -- 締めステータスが「1:締め処理未実施」の場合、締め処理実施エラー
    IF (lv_tighten_status = gv_tighten_status_1) THEN
      ov_retcode := gv_status_error;
      lv_errmsg := lv_errmsg ||
                 xxcmn_common_pkg.get_msg(gv_xxwsh,
                                          gv_tightening_err);
      RAISE global_process_expt;
    -- 締めステータスが「3:締め解除済み」の場合、締め解除済みエラー
    ELSIF (lv_tighten_status = gv_tighten_status_3) THEN
      ov_retcode := gv_status_error;
      lv_errmsg := lv_errmsg ||
                 xxcmn_common_pkg.get_msg(gv_xxwsh,
                                          gv_released_err);
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- 解除レコードの登録(K-3)
    -- ==============================================
    ins_xxwsh_tightening_control(
                               lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                               lv_retcode,        -- リターン・コード             --# 固定 #
                               lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    ELSIF (lv_retcode = gv_status_normal) THEN
      ov_retcode := lv_retcode;
      gn_normal_cnt := gn_normal_cnt + 1;
    END IF;
--
  EXCEPTION
--
    --*** 数値型に変換できなかった場合=TO_NUMBER() ***
    WHEN VALUE_ERROR THEN
      gn_error_cnt := gn_error_cnt + 1;   -- エラー件数カウント
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      gn_error_cnt := gn_error_cnt + 1;   -- エラー件数カウント
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := gn_error_cnt + 1;   -- エラー件数カウント
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;   -- エラー件数カウント
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf                    OUT VARCHAR2,    --   エラー・メッセージ  --# 固定 #
    retcode                   OUT VARCHAR2,     --   リターン・コード    --# 固定 #
    iv_transaction_type_id    IN VARCHAR2,     --   出庫形態
    iv_shipped_locat_code     IN VARCHAR2,     --   出庫元
    iv_sales_branch           IN VARCHAR2,     --   拠点
    iv_sales_branch_category  IN VARCHAR2,     --   拠点カテゴリ
    iv_lead_time_day          IN VARCHAR2,     --   生産物流LT/引取変更LT
    iv_ship_date              IN VARCHAR2,     --   出庫日
    iv_base_record_class      IN VARCHAR2,     --   基準レコード区分
    iv_prod_class             IN VARCHAR2      --   商品区分
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_transaction_type_id,       --   出庫形態
      iv_shipped_locat_code,        --   出庫元
      iv_sales_branch,              --   拠点
      iv_sales_branch_category,     --   拠点カテゴリ
      iv_lead_time_day,             --   生産物流LT/引取変更LT
      iv_ship_date,                 --   出庫日
      iv_base_record_class,         --   基準レコード区分
      iv_prod_class,                --   商品区分
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --出力件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH',gv_output_msg,'CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh400010c;
/
