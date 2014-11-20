CREATE OR REPLACE PACKAGE BODY xxwsh400007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400007c(BODY)
 * Description      : 出荷依頼締め処理
 * MD.050           : T_MD050_BPO_401_出荷依頼
 * MD.070           : 出荷依頼締め処理 T_MD070_BPO_40H
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  ship_tightening        出荷依頼締め処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/4/10     1.0   R.Matusita       新規作成
 *  2008/5/19     1.1   Oracle 上原正好  内部変更要求#80対応 パラメータ「拠点」追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
  gn_all           CONSTANT NUMBER      := -999;
  gv_all           CONSTANT VARCHAR2(3) := 'ALL';
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
  lock_expt                 EXCEPTION;     -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxwsh400007c'; -- パッケージ名
--
  gv_xxcmn          CONSTANT VARCHAR2(100)  := 'XXCMN';        -- モジュール名省略：XXCMNマスタ共通
  gv_cnst_msg_kbn   CONSTANT VARCHAR2(5)    := 'XXWSH';
--
  -- メッセージ
  gv_msg_xxcmn10146 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10146';
                                            -- メッセージ：ロック取得エラー
  gv_msg_xxcmn10036 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10036';
                                            -- メッセージ：データ取得エラー
  gv_msg_xxcmn00005 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-00005';
                                            -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
  gv_cnst_msg_null  CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11218';  -- 必須チェックエラーメッセージ
  gv_cnst_msg_prop  CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11219';  -- 妥当性チェックエラーメッセージ
  gv_cnst_msg_fomt  CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11214';  -- マスタ書式エラー
  gv_cnst_msg_215   CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11215';  -- 共通関数エラー
  gv_cnst_msg_216   CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11216';  -- 共通関数警告終了
  gv_cnst_msg_222   CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11222';  -- 
  gv_cnst_msg_224   CONSTANT VARCHAR2(15)   := 'APP-XXWSH-11225';  -- 択一選択エラーメッセージ
--
  gn_status_error   CONSTANT NUMBER := 1;
  gv_line_feed      CONSTANT VARCHAR2(1)    := CHR(10); -- 改行コード;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_upd_cnt          NUMBER DEFAULT 0;      -- 更新件数
--
  gv_msg_kbn          CONSTANT VARCHAR2(5)  DEFAULT 'XXCMN';
  --トークン
  gv_tkn_api_name     CONSTANT VARCHAR2(15) DEFAULT 'API_NAME';
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_order_type_id         IN  VARCHAR2  DEFAULT NULL, -- 出庫形態ID
    iv_deliver_from          IN  VARCHAR2  DEFAULT NULL, -- 出荷元
    iv_sales_base            IN  VARCHAR2  DEFAULT NULL, -- 拠点
    iv_sales_base_category   IN  VARCHAR2  DEFAULT NULL, -- 拠点カテゴリ
    iv_lead_time_day         IN  VARCHAR2  DEFAULT NULL, -- 生産物流LT
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- 出庫日
    iv_base_record_class     IN  VARCHAR2  DEFAULT NULL, -- 基準レコード区分
    iv_request_no            IN  VARCHAR2  DEFAULT NULL, -- 依頼No
    iv_tighten_class         IN  VARCHAR2  DEFAULT NULL, -- 締め処理区分
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- 商品区分
    iv_tightening_program_id IN  VARCHAR2  DEFAULT NULL, -- 締めコンカレントID
    iv_instruction_dept      IN  VARCHAR2  DEFAULT NULL, -- 部署
    ov_errbuf                OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    cv_tighten_class_1     VARCHAR2(1)   := '1'; -- 締め処理区分1:初回
    cv_tighten_class_2     VARCHAR2(1)   := '2'; -- 締め処理区分2:再
    cv_tightening_status_chk_cla_1   VARCHAR2(1)    := '1'; -- 締めステータスチェック区分1
    cv_callfrom_flg_1                VARCHAR2(1)    := '1'; -- 呼出元フラグ1
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
    lv_cnst_msg       CONSTANT VARCHAR2(30)  := '締めステータスチェック区分';
    lv_cnst_01        CONSTANT VARCHAR2(30)  := '出庫形態ID';
    lv_cnst_03        CONSTANT VARCHAR2(30)  := '生産物流LT';
    lv_cnst_04        CONSTANT VARCHAR2(30)  := '出庫日';
    lv_cnst_05        CONSTANT VARCHAR2(30)  := '基準レコード区分';
    lv_cnst_06        CONSTANT VARCHAR2(30)  := '締め処理区分';
    lv_cnst_07        CONSTANT VARCHAR2(30)  := '締めコンカレントID';
    lv_cnst_08        CONSTANT VARCHAR2(30)  := '商品区分';
    lv_cnst_09        CONSTANT VARCHAR2(30)  := '部署';
    lv_cnst_10        CONSTANT VARCHAR2(30)  := '入力パラメータ「出庫日」の値';
    lv_cnst_11        CONSTANT VARCHAR2(30)  := 'ステータスの更新';
    lv_cnst_12        CONSTANT VARCHAR2(30)  := '出荷依頼情報取得';
    lv_cnst_13        CONSTANT VARCHAR2(30)  := '締めコンカレントID';
    lv_cnst_14        CONSTANT VARCHAR2(30)  := '出庫形態ID';
    lv_cnst_15        CONSTANT VARCHAR2(30)  := '生産物流LT';
    lv_type           CONSTANT VARCHAR2(30)  := '数値';
    cv_prod_class_1   CONSTANT VARCHAR2(1)   := '1'; -- 1：リーフ
--
    -- *** ローカル変数 ***
--
    ln_tightening_program_id   NUMBER ; -- 締めコンカレントID
    ln_order_type_id           NUMBER ; -- 出庫形態ID
    ln_lead_time_day           NUMBER ; -- 生産物流LT
    lv_deliver_from           xxwsh_tightening_control.deliver_from%TYPE; -- 出荷元保管場所
    lv_sales_base             xxwsh_tightening_control.sales_branch%TYPE; -- 拠点
    lv_sales_base_category    xxwsh_tightening_control.sales_branch_category%TYPE; -- 拠点カテゴリ
    ld_schedule_ship_date     xxwsh_tightening_control.schedule_ship_date%TYPE;    -- 出庫日
    lv_base_record_class      xxwsh_tightening_control.base_record_class%TYPE;     -- 基準レコード区分
    lv_para                    VARCHAR2(30);
    lv_err_message             VARCHAR2(4000); -- エラーメッセージ
--
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    lv_para := lv_cnst_14;
    ln_order_type_id := TO_NUMBER(iv_order_type_id); -- 出庫形態ID
--
    lv_para := lv_cnst_15;
    ln_lead_time_day := TO_NUMBER(iv_lead_time_day); -- 生産物流LT
--
    lv_err_message := NULL;
--
    -- ==================================================
    -- パラメータチェック(H-1)
    -- ==================================================
--
    IF (iv_tighten_class IS NULL) THEN
      -- 締め処理区分のNULLチェックを行います
      lv_err_message := lv_err_message ||
      xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                               gv_cnst_msg_null,
                               'PARAMETER',
                               lv_cnst_06) || gv_line_feed;
    END IF;
--
    IF (iv_tighten_class = cv_tighten_class_1) THEN
      -- 締め処理区分に1:初回の場合
      ln_tightening_program_id := NULL;
--
      IF (iv_prod_class = cv_prod_class_1) THEN
        -- パラメータ.商品区分がリーフの場合
        IF (ln_order_type_id IS NULL) THEN
          -- 出庫形態IDのNULLチェックを行います
          lv_err_message := lv_err_message ||
          xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                   gv_cnst_msg_null,
                                   'PARAMETER',
                                   lv_cnst_01) || gv_line_feed;
        END IF;
--
      END IF;
--
      IF (ln_lead_time_day IS NULL) THEN
        -- 生産物流LTのNULLチェックを行います
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_03) || gv_line_feed;
      END IF;
--
      IF (id_schedule_ship_date IS NULL) THEN
        -- 出庫日のNULLチェックを行います
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_04) || gv_line_feed;
      END IF;
--
      IF (iv_base_record_class IS NULL) THEN
        -- 基準レコード区分のNULLチェックを行います
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_05) || gv_line_feed;
      END IF;
--
      IF (iv_prod_class IS NULL) THEN
        -- 商品区分のNULLチェックを行います
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_08) || gv_line_feed;
      END IF;
--
      -- 「出庫日」形式チェック
      IF (gn_status_error
          = xxcmn_common_pkg.check_param_date_yyyymmdd(id_schedule_ship_date)) THEN
        -- 出庫日がYYYY/MM/DDでない場合、エラーを返す
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_fomt,
                                 'PARAMETER',
                                 lv_cnst_04,
                                 'DATE',
                                 lv_cnst_10) || gv_line_feed;
      END IF;
--
--
    ELSIF (iv_tighten_class = cv_tighten_class_2) THEN
      -- 締め処理区分に2:再締めの場合
      lv_para := lv_cnst_13;
      ln_tightening_program_id := TO_NUMBER(iv_tightening_program_id);
--
      IF (iv_tighten_class IS NULL) THEN
        -- 締め処理区分のNULLチェックを行います
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_06) || gv_line_feed;
      END IF;
--
      IF (ln_tightening_program_id IS NULL) THEN
        -- 締めコンカレントIDのNULLチェックを行います
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_07) || gv_line_feed;
      END IF;
--
      IF (iv_prod_class IS NULL) THEN
        -- 商品区分のNULLチェックを行います
        lv_err_message := lv_err_message ||
        xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                 gv_cnst_msg_null,
                                 'PARAMETER',
                                 lv_cnst_08) || gv_line_feed;
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** メッセージの整形
    -- **************************************************
    -- メッセージが登録されている場合
    IF (lv_err_message IS NOT NULL) THEN
      -- 最後の改行コードを削除しOUTパラメータに設定
      lv_errmsg := RTRIM(lv_err_message, gv_line_feed);
      -- エラーとして終了
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- パラメータ設定(H-2)
    -- ==================================================
    -- 締め処理区分が1:初回締めの場合
    IF (iv_tighten_class = cv_tighten_class_1) THEN
      lv_deliver_from        := iv_deliver_from;
      lv_sales_base          := iv_sales_base;
      lv_sales_base_category := iv_sales_base_category;
      ld_schedule_ship_date  := id_schedule_ship_date;
      lv_base_record_class   := iv_base_record_class;
    -- 締め処理区分が2:再締めの場合
    ELSIF (iv_tighten_class = cv_tighten_class_2) THEN
      -- 締め管理アドオン情報取得
      SELECT
        DECODE(order_type_id,gn_all,NULL
                            ,order_type_id), -- 出庫形態ID
        DECODE(deliver_from,gv_all,NULL
                           ,deliver_from),  -- 出庫元
        DECODE(sales_branch,gv_all,NULL
                           ,sales_branch),  -- 拠点
        DECODE(sales_branch_category,gv_all,NULL
                                    ,sales_branch_category), -- 拠点カテゴリ
        lead_time_day,               -- 生産物流LT
        schedule_ship_date           -- 出庫日
      INTO
        ln_order_type_id,               -- 出庫形態ID
        lv_deliver_from,                -- 出庫元
        lv_sales_base,                  -- 拠点
        lv_sales_base_category,         -- 拠点カテゴリ
        ln_lead_time_day,               -- 生産物流LT
        ld_schedule_ship_date           -- 出庫日
      FROM
        xxwsh_tightening_control xtc
      WHERE 
        xtc.concurrent_id = ln_tightening_program_id
      ;
      lv_base_record_class   := 'N';   -- 基準レコード区分
    END IF;
    -- ==================================================
    -- 出荷依頼確定関数起動(H-3)
    -- ==================================================
    xxwsh400004c.ship_tightening(
      ln_order_type_id,               -- 出庫形態ID
      lv_deliver_from,                -- 出荷元
      lv_sales_base,                  -- 拠点
      lv_sales_base_category,         -- 拠点カテゴリ
      ln_lead_time_day,               -- 生産物流LT
      ld_schedule_ship_date,          -- 出庫日
      lv_base_record_class,           -- 基準レコード区分
      iv_request_no,                  -- 依頼No
      iv_tighten_class,               -- 締め処理区分
      ln_tightening_program_id,       -- 締めコンカレントID
      cv_tightening_status_chk_cla_1, -- 締めステータスチェック区分 1：チェック有り
      cv_callfrom_flg_1,              -- 呼出元フラグ 1：コンカレント
      iv_prod_class,                  -- 商品区分
      iv_instruction_dept,            -- 部署
      lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
      lv_retcode,                     -- リターン・コード             --# 固定 #
      lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_warn) THEN
      -- ワーニングの場合
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_216,
                                            gv_tkn_api_name,
                                            lv_cnst_12,
                                            'ERR_MSG',
                                            lv_errmsg);
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
    ELSIF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_215,
                                            gv_tkn_api_name,
                                            lv_cnst_11,
                                            'ERR_MSG',
                                            lv_errmsg,
                                            'REQUEST_NO',
                                            iv_request_no);
--
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 数値変換エラーハンドラ ***
    WHEN INVALID_NUMBER THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_222,
                                              'PARAMETER',
                                              lv_para,
                                              'TYPE',
                                              lv_type);
      RAISE global_process_expt;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
    errbuf                   OUT NOCOPY VARCHAR2,         -- エラーメッセージ #固定#
    retcode                  OUT NOCOPY VARCHAR2,         -- エラーコード     #固定#
    iv_order_type_id         IN  VARCHAR2,                -- 出庫形態ID
    iv_deliver_from          IN  VARCHAR2,                -- 出荷元
    iv_sales_base            IN  VARCHAR2,                -- 拠点
    iv_sales_base_category   IN  VARCHAR2,                -- 拠点カテゴリ
    iv_lead_time_day         IN  VARCHAR2,                -- 生産物流LT
    iv_schedule_ship_date    IN  VARCHAR2,                -- 出庫日
    iv_base_record_class     IN  VARCHAR2,                -- 基準レコード区分
    iv_request_no            IN  VARCHAR2,                -- 依頼No
    iv_tighten_class         IN  VARCHAR2,                -- 締め処理区分
    iv_prod_class            IN  VARCHAR2,                -- 商品区分
    iv_tightening_program_id IN  VARCHAR2,                -- 締めコンカレントID
    iv_instruction_dept      IN  VARCHAR2                 -- 部署
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
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_order_type_id,                            -- 出庫形態ID
      iv_deliver_from,                             -- 出荷元
      iv_sales_base,                               -- 拠点
      iv_sales_base_category,                      -- 拠点カテゴリ
      iv_lead_time_day,                            -- 生産物流LT
      FND_DATE.STRING_TO_DATE(iv_schedule_ship_date, 'YYYY/MM/DD'),-- 出庫日
      iv_base_record_class,                        -- 基準レコード区分
      iv_request_no,                               -- 依頼No
      iv_tighten_class,                            -- 締め処理区分
      iv_prod_class,                               -- 商品区分
      iv_tightening_program_id,                    -- 締めコンカレントID
      iv_instruction_dept,                         -- 部署
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- ======================
    -- ワーニング・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
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
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
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
END xxwsh400007c;
/
