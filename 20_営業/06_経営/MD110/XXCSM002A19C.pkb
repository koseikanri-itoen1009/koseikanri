CREATE OR REPLACE PACKAGE BODY XXCSM002A19C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCSM002A19C(body)
 * Description      : 年間商品計画ダウンロード
 * MD.050           : 年間商品計画ダウンロード MD050_CSM_002_A19
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  location_group_csv     拠点別商品群別商品計画CSV出力 (A-2)
 *  item_csv               単品別商品計画CSV出力 (A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/02/08    1.0   Y.Sasaki         新規作成
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
  no_data           EXCEPTION;     -- 商品計画未取得警告
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100)  :=  'XXCSM002A19C';       -- パッケージ名
  cv_xxcsm                CONSTANT VARCHAR2(10)   :=  'XXCSM';              -- アプリケーション短縮名
  -- メッセージコード
  cv_msg_csm1_10401       CONSTANT VARCHAR2(30)   :=  'APP-XXCSM1-10401';   -- 入力パラメータ表示メッセージ
  cv_msg_csm1_10402       CONSTANT VARCHAR2(30)   :=  'APP-XXCSM1-10402';   -- 商品計画未取得警告
  -- トークン
  cv_tkn_output_kbn       CONSTANT VARCHAR2(100)  :=  'OUTPUT_KBN';
  cv_tkn_location_cd      CONSTANT VARCHAR2(100)  :=  'LOCATION_CD';
  cv_tkn_plan_year        CONSTANT VARCHAR2(100)  :=  'PLAN_YEAR';
  cv_tkn_item_group_3     CONSTANT VARCHAR2(100)  :=  'ITEM_GROUP_3';
  cv_tkn_output_data      CONSTANT VARCHAR2(100)  :=  'OUTPUT_DATA';
  -- 出力区分
  cv_item_sales_plan      CONSTANT VARCHAR2(2)    :=  '01';                 -- 出力区分:単品別
  -- 商品区分
  cv_item_kbn_0           CONSTANT VARCHAR2(1)    :=  '0';                  -- 商品区分:商品群
  cv_item_kbn_1           CONSTANT VARCHAR2(1)    :=  '1';                  -- 商品区分:商品単品
  -- 出力値コード
  cv_out_data_01          CONSTANT VARCHAR2(2)    :=  '01';                 -- 出力値：粗利額
  cv_out_data_02          CONSTANT VARCHAR2(2)    :=  '02';                 -- 出力値：粗利率
  cv_out_data_03          CONSTANT VARCHAR2(2)    :=  '03';                 -- 出力値：掛率
  cv_out_data_99          CONSTANT VARCHAR2(2)    :=  '99';                 -- 出力値：全て
  -- 計算用
  cn_1000                 CONSTANT NUMBER         :=  1000;                 -- 計算用:1000
  -- 出力文字列
  cv_comma                CONSTANT VARCHAR2(1)    :=  ',';
  cv_uriage               CONSTANT VARCHAR2(6)    :=  '売上';
  cv_ararigaku            CONSTANT VARCHAR2(9)    :=  '粗利額';
  cv_arariritu            CONSTANT VARCHAR2(9)    :=  '粗利率';
  cv_kakeritu             CONSTANT VARCHAR2(6)    :=  '掛率';
  cv_kyotenkei            CONSTANT VARCHAR2(9)    :=  '拠点計';
  cv_uriagenebiki         CONSTANT VARCHAR2(12)   :=  '売上値引';
  cv_nyuukinnebiki        CONSTANT VARCHAR2(12)   :=  '入金値引';
  cv_uriageyosan          CONSTANT VARCHAR2(12)   :=  '売上予算';
  cv_kyotenkodo           CONSTANT VARCHAR2(15)   :=  '拠点コード';
  cv_nendo                CONSTANT VARCHAR2(15)   :=  '年度';
  cv_yosankubun           CONSTANT VARCHAR2(15)   :=  '予算区分';
  cv_rekodokubun          CONSTANT VARCHAR2(15)   :=  'レコード区分';
  cv_syouhingun           CONSTANT VARCHAR2(15)   :=  '商品群';
  cv_syouhinkodo          CONSTANT VARCHAR2(15)   :=  '商品コード';
  cv_syouhinmei           CONSTANT VARCHAR2(15)   :=  '商品名';
  cv_5gatu                CONSTANT VARCHAR2(15)   :=  '5月分';
  cv_6gatu                CONSTANT VARCHAR2(15)   :=  '6月分';
  cv_7gatu                CONSTANT VARCHAR2(15)   :=  '7月分';
  cv_8gatu                CONSTANT VARCHAR2(15)   :=  '8月分';
  cv_9gatu                CONSTANT VARCHAR2(15)   :=  '9月分';
  cv_10gatu               CONSTANT VARCHAR2(15)   :=  '10月分';
  cv_11gatu               CONSTANT VARCHAR2(15)   :=  '11月分';
  cv_12gatu               CONSTANT VARCHAR2(15)   :=  '12月分';
  cv_1gatu                CONSTANT VARCHAR2(15)   :=  '1月分';
  cv_2gatu                CONSTANT VARCHAR2(15)   :=  '2月分';
  cv_3gatu                CONSTANT VARCHAR2(15)   :=  '3月分';
  cv_4gatu                CONSTANT VARCHAR2(15)   :=  '4月分';
  cv_nenkankei            CONSTANT VARCHAR2(15)   :=  '年間計';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ
  gv_output_kbn     VARCHAR2(30);     --  出力区分
  gv_location_cd    VARCHAR2(30);     --  拠点
  gn_plan_year      NUMBER;           --  年度
  gv_item_group_3   VARCHAR2(30);     --  商品群3
  gv_output_data    VARCHAR2(30);     --  出力値
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_output_kbn     IN  VARCHAR2      --  出力区分
    , iv_location_cd    IN  VARCHAR2      --  拠点
    , iv_plan_year      IN  VARCHAR2      --  年度
    , iv_item_group_3   IN  VARCHAR2      --  商品群3
    , iv_output_data    IN  VARCHAR2      --  出力値
    , ov_errbuf         OUT VARCHAR2      --  エラー・メッセージ           --# 固定 #
    , ov_retcode        OUT VARCHAR2      --  リターン・コード             --# 固定 #
    , ov_errmsg         OUT VARCHAR2      --  ユーザー・エラー・メッセージ --# 固定 #
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
    lv_pram_out VARCHAR2(1000);  -- 入力パラメータメッセージ
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
--  ************************************************
    -- 入力パラメータ出力
--  ************************************************
    -- メッセージを取得
    lv_pram_out :=  xxccp_common_pkg.get_msg(                          --   出力区分の出力
                        iv_application    =>  cv_xxcsm                 --   アプリケーション短縮名
                      , iv_name           =>  cv_msg_csm1_10401        --   メッセージコード
                      , iv_token_name1    =>  cv_tkn_output_kbn        --   トークンコード1（出力区分）
                      , iv_token_value1   =>  iv_output_kbn            --   トークン値1
                      , iv_token_name2    =>  cv_tkn_location_cd       --   トークンコード2（拠点）
                      , iv_token_value2   =>  iv_location_cd           --   トークン値2
                      , iv_token_name3    =>  cv_tkn_plan_year         --   トークンコード3（年度）
                      , iv_token_value3   =>  iv_plan_year             --   トークン値3
                      , iv_token_name4    =>  cv_tkn_item_group_3      --   トークンコード4（商品群）
                      , iv_token_value4   =>  iv_item_group_3          --   トークン値4
                      , iv_token_name5    =>  cv_tkn_output_data       --   トークンコード5（出力値）
                      , iv_token_value5   =>  iv_output_data           --   トークン値5
                    );
    --
    -- ログにパラメータを出力
    fnd_file.put_line(
        which   =>  FND_FILE.LOG
      , buff    =>  lv_pram_out
    );
    -- ログに空行を出力
    fnd_file.put_line(
        which   =>  FND_FILE.LOG
      , buff    =>  CHR(10)
    );
    --
    -- パラメータを保持
    gv_output_kbn       :=  iv_output_kbn;
    gv_location_cd      :=  iv_location_cd;
    gn_plan_year        :=  TO_NUMBER(iv_plan_year);
    gv_item_group_3     :=  iv_item_group_3;
    gv_output_data      :=  iv_output_data;
    --
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : location_group_csv
   * Description      : 拠点別商品群別商品計画データ出力処理(A-2)
   ***********************************************************************************/
  PROCEDURE location_group_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'location_group_csv'; -- プログラム名
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
    cv_asterisk_5   CONSTANT VARCHAR(5)  :=  '*****';-- 拠点別の年間計用出力値
    --
    -- *** ローカル変数 ***
    lv_header           VARCHAR2(1000);       --  ヘッダー格納変数
    lv_uriage           VARCHAR2(2000);       --  売上CSV出力行
    lv_agm              VARCHAR2(2000);       --  粗利額CSV出力行
    lv_mr               VARCHAR2(2000);       --  粗利率CSV出力行
    lv_cr               VARCHAR2(2000);       --  掛率CSV出力行
    lv_sales_dcnt       VARCHAR2(2000);       --  売上値引CSV出力行
    lv_receipt_dcnt     VARCHAR2(2000);       --  入金値引CSV出力行
    lv_sales_bdg        VARCHAR2(2000);       --  売上予算CSV出力行
    lv_item_group_no    VARCHAR2(10);         --  前回商品群
    ln_count            NUMBER;               --  ループカウンタ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 拠点別商品計画取得カーソル
    CURSOR get_location_sales_plan_cur
    IS
      SELECT   xiph.location_cd       AS  location_cd               --  拠点コード
             , xiph.plan_year         AS  plan_year                 --  年度
             , xiplb.sales_budget     AS  sales_budget              --  売上予算
             , xiplb.receipt_discount AS  receipt_discount          --  入金値引
             , xiplb.sales_discount   AS  sales_discount            --  売上値引
      FROM     xxcsm_item_plan_loc_bdgt  xiplb
             , xxcsm_item_plan_headers   xiph
      WHERE    xiplb.item_plan_header_id    =   xiph.item_plan_header_id
      AND      xiph.plan_year               =   gn_plan_year
      AND      xiph.location_cd             =   gv_location_cd
      ORDER BY xiph.location_cd
             , xiplb.year_month
      ;
    -- 商品群別商品計画取得カーソル
    CURSOR get_group_sales_plan_cur
    IS
      SELECT   xiph.location_cd         AS  location_cd             --  拠点コード
             , xiph.plan_year           AS  plan_year               --  年度
             , xipl.item_group_no       AS  item_group_no           --  商品群3
             , xipl.sales_budget        AS  sales_budget            --  売上
             , xipl.amount_gross_margin AS  amount_gross_margin     --  粗利額
             , xipl.margin_rate         AS  margin_rate             --  粗利率
      FROM     xxcsm_item_plan_lines     xipl
             , xxcsm_item_plan_headers   xiph
             , xxcsm_item_group_3_nm_v   xig3nv
      WHERE    xiph.item_plan_header_id   =   xipl.item_plan_header_id
      AND      xiph.plan_year             =   gn_plan_year
      AND      xipl.item_group_no         =   xig3nv.item_group_cd
      AND      xipl.item_kbn              =   cv_item_kbn_0
      AND      xiph.location_cd           =   gv_location_cd
      AND      xipl.item_group_no         =   NVL(gv_item_group_3,xipl.item_group_no)
      ORDER BY xipl.item_group_no
             , xipl.year_month
      ;
    --
    -- 拠点別商品計画取得カーソルレコード型
    get_location_sales_plan_rec     get_location_sales_plan_cur%ROWTYPE;
    -- 拠点別商品計画取得カーソルレコード型
    get_group_sales_plan_rec        get_group_sales_plan_cur%ROWTYPE;
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
    --  **************************************
    --    拠点別商品計画CSV整形
    --  **************************************
    --  出力情報の初期化
    ln_count         :=  0;
    lv_header        :=  gv_location_cd || cv_comma ||
                         TO_CHAR(gn_plan_year)
                     ;
    lv_sales_dcnt    :=  lv_header      || cv_comma ||
                         cv_kyotenkei   || cv_comma ||
                         cv_uriagenebiki
                     ;
    lv_receipt_dcnt  :=  lv_header      || cv_comma ||
                         cv_kyotenkei   || cv_comma ||
                         cv_nyuukinnebiki
                     ;
    lv_sales_bdg     :=  lv_header      || cv_comma ||
                         cv_kyotenkei   || cv_comma ||
                         cv_uriageyosan
                     ;
    --
    --  CSVファイルに見出しを出力
    fnd_file.put_line(
      which     =>  FND_FILE.OUTPUT
    , buff      =>  cv_kyotenkodo || cv_comma || cv_nendo || cv_comma || cv_yosankubun || cv_comma || cv_rekodokubun || cv_comma ||
                    cv_5gatu || cv_comma || cv_6gatu || cv_comma || cv_7gatu || cv_comma || cv_8gatu || cv_comma ||
                    cv_9gatu || cv_comma || cv_10gatu || cv_comma || cv_11gatu || cv_comma || cv_12gatu || cv_comma ||
                    cv_1gatu || cv_comma  || cv_2gatu || cv_comma || cv_3gatu || cv_comma || cv_4gatu ||cv_comma || cv_nenkankei
    );
    --
    <<base_loop>>
    FOR get_location_sales_plan_rec IN get_location_sales_plan_cur LOOP
      --  1年（12ヶ月）分のデータを、1行に結合
      --  出力用変数に文字列結合
      --
      lv_sales_dcnt     :=  lv_sales_dcnt   || cv_comma ||
                            TO_CHAR(get_location_sales_plan_rec.sales_discount / cn_1000)
      ;
      lv_receipt_dcnt   :=  lv_receipt_dcnt || cv_comma ||
                            TO_CHAR(get_location_sales_plan_rec.receipt_discount / cn_1000)
      ;
      lv_sales_bdg      :=  lv_sales_bdg    || cv_comma ||
                            TO_CHAR(get_location_sales_plan_rec.sales_budget / cn_1000)
      ;
      ln_count  :=  ln_count + 1;
    END LOOP  base_loop;
    --
    --  **************************************
    --    拠点別商品計画CSV出力
    --  **************************************
    IF ( ln_count > 0 ) THEN
      --  年間計を文字列結合
      lv_sales_dcnt    :=  lv_sales_dcnt   || cv_comma || cv_asterisk_5 ;
      lv_receipt_dcnt  :=  lv_receipt_dcnt || cv_comma || cv_asterisk_5 ;
      lv_sales_bdg     :=  lv_sales_bdg    || cv_comma || cv_asterisk_5 ;
      --
      -- 売上値引
      fnd_file.put_line(
        which     =>  FND_FILE.OUTPUT
      , buff      =>  lv_sales_dcnt
      );
      -- 入金値引
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_receipt_dcnt
      );
      -- 売上予算
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_sales_bdg
      );
      --  件数カウント
      gn_target_cnt  :=  gn_target_cnt + 1 ;
      gn_normal_cnt  :=  gn_normal_cnt + 1;
    ELSE
      --  拠点別予算計が取得できなかった場合
      gn_warn_cnt :=  gn_warn_cnt + 1;
      -- 年間商品計画ダウンロードデータなしメッセージ
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_xxcsm
                        , iv_name         =>  cv_msg_csm1_10402
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE no_data;
    END IF;
    --
    --
    --  **************************************
    --    商品群別商品計画CSV整形
    --  **************************************
    --  初期化
    lv_item_group_no  :=  NULL;
    lv_uriage         :=  cv_comma || cv_uriage ;
    lv_agm            :=  cv_comma || cv_ararigaku ;
    lv_mr             :=  cv_comma || cv_arariritu ;
    --
    <<group_loop>>
    FOR get_group_sales_plan_rec IN get_group_sales_plan_cur LOOP
      --
      IF ( lv_item_group_no IS NOT NULL AND get_group_sales_plan_rec.item_group_no <> lv_item_group_no ) THEN
        --  **************************************
        --    商品群別商品計画CSV出力
        --  **************************************
        --  群コードが変わったタイミングで出力を実施
        --
        --  売上
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_uriage
        );
        --  粗利額
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_agm
        );
        --  粗利率
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_mr
        );
        --
        --  件数カウント
        gn_target_cnt   :=  gn_target_cnt + 1;
        gn_normal_cnt   :=  gn_normal_cnt + 1;
        -- 出力情報の初期化
        lv_uriage   :=  cv_comma || cv_uriage ;
        lv_agm      :=  cv_comma || cv_ararigaku ;
        lv_mr       :=  cv_comma || cv_arariritu ;
      END IF;
      --
      --  1年（12ヶ月）分のデータを、1行に結合
      --  売上
      lv_uriage :=  lv_uriage || cv_comma || TO_CHAR(get_group_sales_plan_rec.sales_budget / cn_1000 ) ;
      --  粗利額：出力値が粗利額(01)または、全て(99)の場合取得値を設定、それ以外の場合は値を設定しない
      lv_agm    :=  lv_agm || cv_comma ||
                    CASE 
                      WHEN gv_output_data IN( cv_out_data_01, cv_out_data_99 )
                        THEN  TO_CHAR( get_group_sales_plan_rec.amount_gross_margin / cn_1000 )
                    END
      ;
      --  粗利率：出力値が粗利率(02)または、全て(99)の場合取得値を設定、それ以外の場合は値を設定しない
      lv_mr     :=  lv_mr || cv_comma ||
                    CASE
                      -- 出力値が粗利率または全ての場合
                      WHEN gv_output_data IN( cv_out_data_02, cv_out_data_99 )
                        THEN  TO_CHAR( get_group_sales_plan_rec.margin_rate )
                    END
      ;
      --
      --  商品群コードを保持
      lv_item_group_no  :=  get_group_sales_plan_rec.item_group_no;
    END LOOP  group_loop;
    --
    --
    IF ( lv_item_group_no IS NOT NULL ) THEN
      --  データが存在する場合は、最後の商品群コード分のデータを出力
      --  売上
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_uriage
      );
      --  粗利額
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_agm
      );
      --  粗利率
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || cv_comma || lv_item_group_no || lv_mr
      );
      --  件数カウント
      gn_target_cnt  :=  gn_target_cnt + 1;
      gn_normal_cnt  :=  gn_normal_cnt + 1;
    ELSE
      --  データが取得されなかった場合、警告終了する
      gn_warn_cnt    :=  gn_warn_cnt   + 1;
      -- 年間商品計画ダウンロードデータなしメッセージ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_xxcsm
                      , iv_name           =>  cv_msg_csm1_10402
                    );
      lv_errbuf :=  lv_errmsg ;
      RAISE no_data;
    END IF;
    --
  EXCEPTION
    -- *** 年間商品計画ダウンロードデータなしメッセージ ***
    WHEN no_data THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                             --# 任意 #
--
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
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_location_sales_plan_cur%ISOPEN) THEN
        CLOSE get_location_sales_plan_cur;
      END IF;
      IF (get_group_sales_plan_cur%ISOPEN) THEN
        CLOSE get_group_sales_plan_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END location_group_csv;
--
  /**********************************************************************************
   * Procedure Name   : item_csv
   * Description      : 単品別商品計画データ出力処理(A-3)
   ***********************************************************************************/
  PROCEDURE item_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_csv'; -- プログラム名
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
    lv_header  VARCHAR2(1000); -- ヘッダー格納変数
    lv_uriage  VARCHAR2(2000); -- 売上CSV出力行
    lv_agm     VARCHAR2(2000); -- 粗利額CSV出力行
    lv_mr      VARCHAR2(2000); -- 粗利率CSV出力行
    lv_cr      VARCHAR2(2000); -- 掛率CSV出力行
    lv_item_no VARCHAR2(20);   -- 前回品目コード
    ln_count   NUMBER;         -- ループカウンタ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 品目別商品計画取得カーソル
    CURSOR get_item_sales_plan_cur
    IS
      SELECT   xiph.location_cd         AS location_cd         -- 拠点コード
             , xiph.plan_year           AS plan_year           -- 年度
             , xipl.item_group_no       AS item_group_no       -- 商品群3
             , xipl.item_no             AS item_no             -- 商品コード
             , xcgv.item_nm             AS item_nm             -- 商品名
             , xipl.sales_budget        AS sales_budget        -- 売上
             , xipl.amount_gross_margin AS amount_gross_margin -- 粗利額
             , xipl.margin_rate         AS margin_rate         -- 粗利率
             , xipl.credit_rate         AS credit_rate         -- 掛率
      FROM     xxcsm_item_plan_lines     xipl
             , xxcsm_commodity_group3_v  xcgv
             , xxcsm_item_plan_headers   xiph
      WHERE    xiph.location_cd         = gv_location_cd
      AND      xiph.plan_year           = gn_plan_year
      AND      xiph.item_plan_header_id = xipl.item_plan_header_id
      AND      xipl.item_group_no       = NVL( gv_item_group_3 , xipl.item_group_no )
      AND      xipl.item_kbn            = cv_item_kbn_1
      AND      xipl.item_no             = xcgv.item_cd
      ORDER BY xipl.item_group_no
             , xipl.item_no
             , xipl.year_month
      ;
    --
    -- 品目別商品計画取得カーソルレコード型
    get_item_sales_plan_rec get_item_sales_plan_cur%ROWTYPE;

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
    --  **************************************
    --    品目別商品計画CSV整形
    --  **************************************
    --
    --出力情報の初期化
    lv_header  :=  NULL;
    lv_item_no :=  NULL;
    lv_uriage  :=  cv_uriage ;
    lv_agm     :=  cv_ararigaku ;
    lv_mr      :=  cv_arariritu ;
    lv_cr      :=  cv_kakeritu ;
    --
    --  CSVファイルに見出しを出力
    fnd_file.put_line(
      which     =>  FND_FILE.OUTPUT
    , buff      =>  cv_kyotenkodo || cv_comma || cv_nendo || cv_comma || cv_syouhingun || cv_comma ||
                    cv_syouhinkodo || cv_comma || cv_syouhinmei || cv_comma || cv_rekodokubun || cv_comma ||
                    cv_5gatu || cv_comma || cv_6gatu || cv_comma || cv_7gatu || cv_comma || cv_8gatu || cv_comma ||
                    cv_9gatu || cv_comma || cv_10gatu || cv_comma || cv_11gatu || cv_comma || cv_12gatu || cv_comma ||
                    cv_1gatu || cv_comma  || cv_2gatu || cv_comma || cv_3gatu || cv_comma || cv_4gatu
    );
    --
    <<item_loop>>
    FOR get_item_sales_plan_rec IN get_item_sales_plan_cur LOOP
      --
      IF ( lv_item_no IS NOT NULL AND get_item_sales_plan_rec.item_no <> lv_item_no ) THEN
        --  **************************************
        --    品目別商品計画CSV出力
        --  **************************************
        --  品目コードが変わったタイミングで出力を実施
        --
        -- 売上
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || lv_uriage
        );
        -- 粗利額
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || lv_agm
        );
        -- 粗利率
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || lv_mr
        );
        -- 掛率
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_header || lv_cr
        );
        --  件数カウント
        gn_target_cnt   :=  gn_target_cnt + 1;
        gn_normal_cnt   :=  gn_normal_cnt + 1;
        --出力情報の初期化
        lv_uriage   :=  cv_uriage;
        lv_agm      :=  cv_ararigaku;
        lv_mr       :=  cv_arariritu;
        lv_cr       :=  cv_kakeritu;
      END IF;
      --
      --  1年（12ヶ月）分のデータを、1行に結合
      -- 売上
      lv_uriage :=  lv_uriage || cv_comma || TO_CHAR(get_item_sales_plan_rec.sales_budget / cn_1000);
      -- 粗利額
      --  粗利額：出力値が粗利額(01)または、全て(99)の場合取得値を設定、それ以外の場合は値を設定しない
      lv_agm    :=  lv_agm || cv_comma ||
                    CASE
                      WHEN gv_output_data IN( cv_out_data_01, cv_out_data_99 )
                        THEN  TO_CHAR(get_item_sales_plan_rec.amount_gross_margin / cn_1000)
                    END
      ;
      -- 粗利率：出力値が粗利率(02)または、全て(99)の場合取得値を設定、それ以外の場合は値を設定しない
      lv_mr     :=  lv_mr || cv_comma ||
                    CASE
                      WHEN gv_output_data IN( cv_out_data_02, cv_out_data_99 )
                        THEN  TO_CHAR(get_item_sales_plan_rec.margin_rate)
                    END
      ;
      -- 掛率：出力値が掛率(03)または、全て(99)の場合取得値を設定、それ以外の場合は値を設定しない
      lv_cr     :=  lv_cr || cv_comma ||
                    CASE
                      WHEN gv_output_data IN( cv_out_data_03, cv_out_data_99 )
                        THEN  TO_CHAR(get_item_sales_plan_rec.credit_rate)
                    END
      ;
      --
      --  品目コードを保持
      lv_item_no  :=  get_item_sales_plan_rec.item_no;
      --  ヘッダ情報を保持
      lv_header  :=  get_item_sales_plan_rec.location_cd        || cv_comma ||
                     TO_CHAR(get_item_sales_plan_rec.plan_year) || cv_comma ||
                     get_item_sales_plan_rec.item_group_no      || cv_comma ||
                     get_item_sales_plan_rec.item_no            || cv_comma ||
                     get_item_sales_plan_rec.item_nm            || cv_comma
      ;
    END LOOP  item_loop;
    --
    --
    IF ( lv_item_no IS NOT NULL ) THEN
      --  データが存在する場合は、最後の品目コード分のデータを出力
      -- 売上
      fnd_file.put_line(
                         which  => FND_FILE.OUTPUT
                        ,buff   => lv_header || lv_uriage
                        );
      -- 粗利額
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || lv_agm
      );
      -- 粗利率
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || lv_mr
      );
      -- 掛率
      fnd_file.put_line(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_header || lv_cr
      );
      --  件数カウント
      gn_target_cnt   :=  gn_target_cnt + 1 ;
      gn_normal_cnt   :=  gn_normal_cnt + 1;
    ELSE
      --  データが取得されなかった場合、警告終了する
      gn_warn_cnt :=  gn_warn_cnt + 1;
      --  年間商品計画ダウンロードデータなしメッセージ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_xxcsm
                      , iv_name           =>  cv_msg_csm1_10402
                    );
      lv_errbuf :=  lv_errmsg ;
      RAISE no_data;
    END IF;
    --
  EXCEPTION
    --*** 年間商品計画ダウンロードデータなしメッセージ ***
    WHEN no_data THEN
      ov_errmsg := lv_errmsg;                                                  --# 任意 #
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 #
--
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
      -- ================================================
      -- カーソルのクローズ
      -- ================================================
      IF (get_item_sales_plan_cur%ISOPEN) THEN
        CLOSE get_item_sales_plan_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END item_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_output_kbn    IN VARCHAR2,   -- 1.出力区分
    iv_location_cd   IN VARCHAR2,   -- 2.拠点
    iv_plan_year     IN VARCHAR2,   -- 3.年度
    iv_item_group_3  IN VARCHAR2,   -- 4.商品群3
    iv_output_data   IN VARCHAR2,   -- 5.出力値
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
    --  (A-1)初期処理
    -- ===============================
    init(
        iv_output_kbn     =>  iv_output_kbn       --  1.出力区分
      , iv_location_cd    =>  iv_location_cd      --  2.拠点
      , iv_plan_year      =>  iv_plan_year        --  3.年度
      , iv_item_group_3   =>  iv_item_group_3     --  4.商品群3
      , iv_output_data    =>  iv_output_data      --  5.出力値
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    --  終了判定
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    --
    IF ( gv_output_kbn = cv_item_sales_plan )
      THEN
      -- ===============================
      --  (A-2)拠点別商品群別商品計画CSV出力
      -- ===============================
      --  出力区分01(拠点別商品群別)の場合
      location_group_csv(
          ov_errbuf   =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode  =>  lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg   =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --  終了判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    --
    ELSE
      -- ===============================
      --  (A-3)単品別商品計画CSV出力
      -- ===============================
      --  出力区分02(単品別)の場合
      item_csv(
          ov_errbuf   =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
        , ov_retcode  =>  lv_retcode        -- リターン・コード             --# 固定 #
        , ov_errmsg   =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --  終了判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- 戻り値に代入
    ov_retcode  :=  lv_retcode;
    ov_errbuf   :=  lv_errbuf;
    ov_errmsg   :=  lv_errmsg;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_output_kbn     IN VARCHAR2,          -- 1.出力区分
    iv_location_cd    IN VARCHAR2,          -- 2.拠点
    iv_plan_year      IN VARCHAR2,          -- 3.年度
    iv_item_group_3   IN VARCHAR2,          -- 4.商品群3
    iv_output_data    IN VARCHAR2           -- 5.出力値
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
        iv_output_kbn     =>  iv_output_kbn       --  1.出力区分
      , iv_location_cd    =>  iv_location_cd      --  2.拠点
      , iv_plan_year      =>  iv_plan_year        --  3.年度
      , iv_item_group_3   =>  iv_item_group_3     --  4.商品群3
      , iv_output_data    =>  iv_output_data      --  5.出力値
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
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
    --警告出力
    IF (lv_retcode = cv_status_warn) THEN
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
END XXCSM002A19C;
/
