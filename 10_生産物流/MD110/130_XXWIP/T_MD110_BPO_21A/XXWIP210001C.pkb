CREATE OR REPLACE PACKAGE BODY xxwip210001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip210001c(body)
 * Description      : 生産バッチ一括クローズ処理
 * MD.050           : 生産クローズ T_MD050_BPO_210
 * MD.070           : 生産バッチ一括クローズ処理(21A) T_MD070_BPO_21A
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  parameter_check        パラメータチェック処理  (A-1)
 *  get_common_data        共通データ取得処理      (A-2)
 *  get_lock               ロック取得処理          (A-4)
 *  certify_batch_api      生産完了処理            (A-5)
 *  close_batch_api        生産クローズ処理        (A-6)
 *  save_batch_api         生産セーブ処理          (A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/11/12    1.0   H.Itou           新規作成
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
  parameter_expt         EXCEPTION;        -- パラメータ例外
  lock_expt              EXCEPTION;        -- ロック取得例外
  not_alloc_expt         EXCEPTION;        -- 未割当例外
  skip_expt              EXCEPTION;        -- スキップ例外
  api_expt               EXCEPTION;        -- API例外
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'XXWIP210001C'; -- パッケージ名
  -- モジュール名略称
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';        -- モジュール名略称：XXCMN 共通
  gv_xxwip           CONSTANT VARCHAR2(100) := 'XXWIP';        -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
--
  -- メッセージ
  gv_msg_xxcmn10010  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10010'; -- メッセージ：APP-XXCMN-10010 パラメータエラー
  gv_msg_xxcmn10012  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10012'; -- メッセージ：APP-XXCMN-10012 日付不正エラー
  gv_msg_xxcmn10001  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10001'; -- メッセージ：APP-XXCMN-10001 対象データなし
  gv_msg_xxwip10055  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10055'; -- メッセージ：APP-XXWIP-10055 対象月チェックエラー
  gv_msg_xxwip10002  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10002'; -- メッセージ：APP-XXWIP-10002 日付大小比較エラー
  gv_msg_xxwip10004  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10004'; -- メッセージ：APP-XXWIP-10004 ロックエラー詳細メッセージ
  gv_msg_xxwip10027  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10027'; -- メッセージ：APP-XXWIP-10027 未割当エラーメッセージ
  gv_msg_xxwip10049  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10049'; -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
  gv_batch_no        CONSTANT VARCHAR2(100) := 'バッチNo.';
--
  -- トークン
  gv_tkn_parameter   CONSTANT VARCHAR2(100) := 'PARAMETER';       -- トークン：PARAMETER
  gv_tkn_value       CONSTANT VARCHAR2(100) := 'VALUE';           -- トークン：VALUE
  gv_tkn_item        CONSTANT VARCHAR2(100) := 'ITEM';            -- トークン：ITEM
  gv_tkn_date        CONSTANT VARCHAR2(100) := 'DATE';            -- トークン：DATE
  gv_tkn_from        CONSTANT VARCHAR2(100) := 'FROM';            -- トークン：FROM
  gv_tkn_to          CONSTANT VARCHAR2(100) := 'TO';              -- トークン：TO
  gv_tkn_table       CONSTANT VARCHAR2(100) := 'TABLE';           -- トークン：TABLE
  gv_tkn_key         CONSTANT VARCHAR2(100) := 'KEY';             -- トークン：KEY
  gv_tkn_batch_no    CONSTANT VARCHAR2(100) := 'BATCH_NO';        -- トークン：BATCH_NO
  gv_tkn_api_name    CONSTANT VARCHAR2(100) := 'API_NAME';        -- トークン：API_NAME
--
  -- ラインタイプ
  gt_line_type_goods   CONSTANT gme_material_details.line_type%TYPE := 1;    -- ラインタイプ：1（完成品）
--
  -- 業務ステータス
  gt_duty_status_com   CONSTANT gme_batch_header.attribute4%TYPE    := '7';  -- 業務ステータス：7（完了）
  gt_duty_status_cls   CONSTANT gme_batch_header.attribute4%TYPE    := '8';  -- 業務ステータス：8（クローズ）
--
  -- バッチステータス
  gt_batch_status_com  CONSTANT gme_batch_header.batch_status%TYPE  := 3;    -- バッチステータス：3（完了）
--
  -- 割当フラグ
  gt_alloc_ind_n       CONSTANT gme_material_details.alloc_ind%TYPE := 0;    -- 割当フラグ：0（未割当）
--
  -- APIリターン・コード
  gv_api_s             CONSTANT VARCHAR2(1) := 'S';   -- APIリターン・コード：S （成功）
--
  -- xxcmn共通関数リターン・コード
  gn_e                 CONSTANT NUMBER := 1;     -- xxcmn共通関数リターン・コード：1（エラー）
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_close_date         DATE;                      -- クローズ日付
  gr_gme_batch_header  gme_batch_header%ROWTYPE;   -- 更新用生産バッチレコード
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : パラメータチェック処理(A-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_plant_code         IN     VARCHAR2,      -- 1.プラントコード
    iov_product_date_from IN OUT VARCHAR2,      -- 2.生産日（FROM）
    iov_product_date_to   IN OUT VARCHAR2,      -- 3.生産日（TO）
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check'; -- プログラム名
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
    -- パラメータ名
    cv_product_date_from  VARCHAR2(20) := '生産日（FROM）';  -- パラメータ名：生産日（FROM）
    cv_product_date_to    VARCHAR2(20) := '生産日（TO）';    -- パラメータ名：生産日（TO）
--
    -- テーブル名
    cv_sy_orgn_mst_b      VARCHAR2(20) := 'OPMプラントマスタ';  -- テーブル名：OPMプラントマスタ
--
    -- *** ローカル変数 ***
    ld_product_date_from  DATE;   -- 生産日（FROM）
    ld_product_date_to    DATE;   -- 生産日（TO）
    ln_temp               NUMBER; -- 一時格納
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
    -- ***          必須チェック           ***
    -- ***************************************
    -- 生産日（TO）
    IF (iov_product_date_to IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn               -- モジュール名略称：XXCMN 共通
                     ,gv_msg_xxcmn10010      -- メッセージ：APP-XXCMN-10010 パラメータエラー
                     ,gv_tkn_parameter       -- トークン：PARAMETER
                     ,cv_product_date_to     -- パラメータ名：生産日（TO）
                     ,gv_tkn_value           -- トークン：VALUE
                     ,iov_product_date_to    -- INパラメータ.生産日（TO）
                    ),1,5000);
      RAISE parameter_expt;
    END IF;
--
    -- ***************************************
    -- ***          日付チェック           ***
    -- ***************************************
    -- 生産日（FROM）
    -- 入力がある場合のみチェック
    IF (iov_product_date_from IS NOT NULL) THEN
      IF (xxcmn_common_pkg.check_param_date_yyyymmdd(iov_product_date_from) = gn_e) THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- モジュール名略称：XXCMN 共通
                       ,gv_msg_xxcmn10012      -- メッセージ：APP-XXCMN-10012 日付不正エラー
                       ,gv_tkn_item            -- トークン：ITEM
                       ,cv_product_date_from   -- パラメータ名：生産日（FROM）
                       ,gv_tkn_value           -- トークン：VALUE
                       ,iov_product_date_from  -- INパラメータ.生産日（FROM）
                      ),1,5000);
        RAISE parameter_expt;
--
      ELSE
        ld_product_date_from := FND_DATE.STRING_TO_DATE(iov_product_date_from,'YYYY/MM/DD HH24:MI:SS');
      END IF;
--
    END IF;
--
    -- 生産日（TO）
    IF (xxcmn_common_pkg.check_param_date_yyyymmdd(iov_product_date_to) = gn_e) THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn               -- モジュール名略称：XXCMN 共通
                     ,gv_msg_xxcmn10012      -- メッセージ：APP-XXCMN-10012 日付不正エラー
                     ,gv_tkn_item            -- トークン：ITEM
                     ,cv_product_date_to     -- パラメータ名：生産日（TO）
                     ,gv_tkn_value           -- トークン：VALUE
                     ,iov_product_date_to    -- INパラメータ.生産日（TO）
                    ),1,5000);
      RAISE parameter_expt;
--
    ELSE
      ld_product_date_to := FND_DATE.STRING_TO_DATE(iov_product_date_to,'YYYY/MM/DD HH24:MI:SS');
    END IF;
--
    -- ********************************************
    -- ***  対象月チェック（今月以降はエラー）  ***
    -- ********************************************
    -- 生産日（FROM）
    -- 入力がある場合のみチェック
    IF (iov_product_date_from IS NOT NULL) THEN
      IF (TO_CHAR(ld_product_date_from,'YYYYMM') >= TO_CHAR(SYSDATE,'YYYYMM')) THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_xxwip               -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                       ,gv_msg_xxwip10055      -- メッセージ：APP-XXCMN-10012 日付不正エラー
                       ,gv_tkn_date            -- トークン：DATE
                       ,cv_product_date_from   -- パラメータ名：生産日（FROM）
                       ,gv_tkn_value           -- トークン：VALUE
                       ,iov_product_date_from  -- INパラメータ.生産日（FROM）
                      ),1,5000);
        RAISE parameter_expt;
      END IF;
    END IF;
--
    -- 生産日（TO）
    IF (TO_CHAR(ld_product_date_to,'YYYYMM') >= TO_CHAR(SYSDATE,'YYYYMM')) THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip               -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10055      -- メッセージ：APP-XXCMN-10012 日付不正エラー
                     ,gv_tkn_date            -- トークン：DATE
                     ,cv_product_date_to     -- パラメータ名：生産日（TO）
                     ,gv_tkn_value           -- トークン：VALUE
                     ,iov_product_date_to    -- INパラメータ.生産日（TO）
                    ),1,5000);
      RAISE parameter_expt;
    END IF;
--
    -- ********************************************
    -- ***  妥当性チェック（FROM > TOはエラー） ***
    -- ********************************************
    -- 生産日（FROM）に入力がある場合のみチェック
    IF (iov_product_date_from IS NOT NULL) THEN
      IF (ld_product_date_from > ld_product_date_to) THEN
         -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        gv_xxwip               -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                       ,gv_msg_xxwip10002      -- メッセージ：APP-XXWIP-10002 日付大小比較エラー
                       ,gv_tkn_from            -- トークン：FROM
                       ,cv_product_date_from || gv_msg_part || TO_CHAR(ld_product_date_from,'YYYY/MM/DD')
                                               -- INパラメータ.生産日（FROM）
                       ,gv_tkn_to              -- トークン：TO
                       ,cv_product_date_to   || gv_msg_part || TO_CHAR(ld_product_date_to,'YYYY/MM/DD')
                                               -- INパラメータ.生産日（TO）
                      ),1,5000);
        RAISE parameter_expt;
      END IF;
      -- OUTパラメータセット
      iov_product_date_from := TO_CHAR(ld_product_date_from,'YYYY/MM/DD');
      iov_product_date_to   := TO_CHAR(ld_product_date_to,  'YYYY/MM/DD');
    ELSE
      -- OUTパラメータセット
      iov_product_date_to   := TO_CHAR(ld_product_date_to,  'YYYY/MM/DD');
    END IF;
--
    -- ********************************************
    -- ***         プラント存在チェック         ***
    -- ********************************************
    -- 入力がある場合のみチェック
    IF (iv_plant_code IS NOT NULL) THEN
      SELECT COUNT(somb.orgn_code) cnt       -- 存在カウント
      INTO   ln_temp                         -- 存在カウント
      FROM   sy_orgn_mst_b somb              -- OPMプラントマスタ
      WHERE  somb.orgn_code = iv_plant_code  -- オルグコード = INパラメータ.プラントコード
      AND    ROWNUM = 1
      ;
--
      IF ln_temp = 0 THEN
          -- エラーメッセージ取得
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxcmn               -- モジュール名略称：XXCMN 共通
                         ,gv_msg_xxcmn10001      -- メッセージ：APP-XXCMN-10001 対象データなし
                         ,gv_tkn_table           -- トークン：TABLE
                         ,cv_sy_orgn_mst_b       -- テーブル名：OPMプラントマスタ
                         ,gv_tkn_key             -- トークン：KEY
                         ,iv_plant_code          -- INパラメータ.プラントコード
                        ),1,5000);
          RAISE parameter_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** パラメータ例外 ***
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : get_common_data
   * Description      : 共通データ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_common_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_common_data'; -- プログラム名
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
    -- ***        クローズ日付取得         ***
    -- ***************************************
    gd_close_date := TRUNC(SYSDATE);
--
    -- ***************************************
    -- ***       WHOカラム値取得           ***
    -- ***************************************
    -- 更新用生産バッチヘッダレコードにセットする
    gr_gme_batch_header.last_updated_by   := fnd_global.user_id;    -- 最終更新者
    gr_gme_batch_header.last_update_date  := SYSDATE;               -- 最終更新日
    gr_gme_batch_header.last_update_login := fnd_global.login_id;   -- 最終更新ログイン
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
  END get_common_data;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ロック取得処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_lock(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- プログラム名
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
    -- テーブル名
    cv_gme_batch_header     VARCHAR2(20):= '生産バッチヘッダ';  -- テーブル名：生産バッチヘッダ
--
    -- *** ローカル変数 ***
    lt_batch_id   gme_batch_header.batch_id%TYPE;  -- バッチID
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
    -- ***           ロック取得            ***
    -- ***************************************
--
    -- ロック取得
    SELECT gbh.batch_id      batch_id   -- バッチID
    INTO   lt_batch_id                  -- バッチID batch_id
    FROM   gme_batch_header  gbh        -- 生産バッチヘッダ
    WHERE  gbh.batch_id = gr_gme_batch_header.batch_id   -- バッチID
    FOR UPDATE NOWAIT
    ;
--
  EXCEPTION
    WHEN lock_expt THEN                   --*** ロック取得例外 ***
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip               -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10004      -- メッセージ：APP-XXWIP-10004 ロックエラー詳細メッセージ
                     ,gv_tkn_table           -- トークンTABLE
                     ,cv_gme_batch_header    -- テーブル名：生産バッチヘッダ
                    ),1,5000);
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;          -- 警告                            --# 任意 #
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
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   :  certify_batch
   * Description      :  生産完了処理(A-5)
   ***********************************************************************************/
  PROCEDURE certify_batch_api(
    it_batch_no   IN  gme_batch_header.batch_no%TYPE,  -- 1.バッチNO
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'certify_batch_api'; -- プログラム名
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
    cv_api_name   CONSTANT VARCHAR2(100) := '生産バッチヘッダ完了';
--
    -- *** ローカル変数 ***
    ln_message_count     NUMBER;         -- メッセージカウント
    lv_message_list      VARCHAR2(200);  -- メッセージリスト
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_gme_batch_header_temp  gme_batch_header%ROWTYPE;              -- 生産完了処理API実行戻り値格納
    lr_unallocated_materials  GME_API_PUB.UNALLOCATED_MATERIALS_TAB; -- 生産完了処理API実行戻り値格納
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
    -- **********************************************
    -- ***    生産バッチヘッダ 実績開始日更新     ***
    -- **********************************************
    -- 実績開始日 <> 生産日の場合、実績開始日を生産日で更新
    BEGIN
      UPDATE  gme_batch_header  -- 生産バッチヘッダ
      SET     actual_start_date =   gr_gme_batch_header.actual_cmplt_date -- 実績開始日
            , last_updated_by   =   gr_gme_batch_header.last_updated_by   -- 最終更新者
            , last_update_date  =   gr_gme_batch_header.last_update_date  -- 最終更新日
            , last_update_login =   gr_gme_batch_header.last_update_login -- 最終更新ログイン
      WHERE   batch_id          =   gr_gme_batch_header.batch_id            -- 条件：バッチID
      AND     actual_start_date <>  gr_gme_batch_header.actual_cmplt_date;  -- 条件：実績開始日<>生産日
    END;
--
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ***************************************
    -- ***    生産バッチヘッダ完了実行     ***
    -- ***************************************
    GME_API_PUB.CERTIFY_BATCH (
      p_api_version           => GME_API_PUB.API_VERSION   -- IN ：p_api_version
     ,p_validation_level      => GME_API_PUB.MAX_ERRORS    -- IN ：p_validation_level
     ,p_init_msg_list         => FALSE                     -- IN ：p_init_msg_list
     ,p_commit                => FALSE                     -- IN ：p_commit
     ,x_message_count         => ln_message_count          -- OUT：x_message_count
     ,x_message_list          => lv_message_list           -- OUT：x_message_list
     ,x_return_status         => lv_retcode                -- OUT：x_return_status
     ,p_del_incomplete_manual => TRUE                      -- IN ：p_del_incomplete_manual
     ,p_ignore_shortages      => FALSE                     -- IN ：p_ignore_shortages
     ,p_batch_header          => gr_gme_batch_header       -- IN ：p_batch_header  更新する値をセットしたレコード
     ,x_batch_header          => lr_gme_batch_header_temp  -- OUT：x_batch_header
     ,x_unallocated_material  => lr_unallocated_materials  -- OUT：x_unallocated_material
    );
--
    -- 正常終了以外の場合、警告
    IF (lv_retcode <> gv_api_s) THEN
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10049       -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
                     ,gv_tkn_api_name         -- トークン：API_NAME
                     ,cv_api_name             -- API名：生産バッチヘッダ完了
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                            --# 任意 #
      -- APIログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || it_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
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
  END certify_batch_api;
--
  /**********************************************************************************
   * Procedure Name   :  close_batch_api
   * Description      :  生産クローズ処理(A-6)
   ***********************************************************************************/
  PROCEDURE close_batch_api(
    it_batch_no   IN  gme_batch_header.batch_no%TYPE,  -- 1.バッチNO
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_batch_api'; -- プログラム名
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
    cv_api_name   CONSTANT VARCHAR2(100) := '生産クローズ';
--
    -- *** ローカル変数 ***
    ln_message_count     NUMBER;         -- メッセージカウント
    lv_message_list      VARCHAR2(200);  -- メッセージリスト
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lr_gme_batch_header_temp  gme_batch_header%ROWTYPE;              -- 生産完了処理API実行戻り値格納
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
    -- メッセージ初期化API
    FND_MSG_PUB.INITIALIZE();
--
    -- ***************************************
    -- ***        業務ステータス更新       ***
    -- ***************************************
    UPDATE gme_batch_header  gbh    -- 生産バッチヘッダ
       SET gbh.attribute4        = gt_duty_status_cls                    -- 業務ステータス
          ,gbh.last_updated_by   = gr_gme_batch_header.last_updated_by   -- 最終更新者
          ,gbh.last_update_date  = gr_gme_batch_header.last_update_date  -- 最終更新日
          ,gbh.last_update_login = gr_gme_batch_header.last_update_login -- 最終更新ログイン
     WHERE gbh.batch_id          = gr_gme_batch_header.batch_id          -- バッチID
    ;
--
    -- ***************************************
    -- ***        生産クローズ実行         ***
    -- ***************************************
    GME_API_PUB.CLOSE_BATCH (
      p_api_version           => GME_API_PUB.API_VERSION   -- IN ：p_api_version
     ,p_validation_level      => GME_API_PUB.MAX_ERRORS    -- IN ：p_validation_level
     ,p_init_msg_list         => FALSE                     -- IN ：p_init_msg_list
     ,p_commit                => FALSE                     -- IN ：p_commit
     ,x_message_count         => ln_message_count          -- OUT：x_message_count
     ,x_message_list          => lv_message_list           -- OUT：x_message_list
     ,x_return_status         => lv_retcode                -- OUT：x_return_status
     ,p_batch_header          => gr_gme_batch_header       -- IN ：p_batch_header  更新する値をセットしたレコード
     ,x_batch_header          => lr_gme_batch_header_temp  -- OUT：x_batch_header
    );
--
    -- 正常終了以外の場合、警告
    IF (lv_retcode <> gv_api_s) THEN
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10049       -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
                     ,gv_tkn_api_name         -- トークン：API_NAME
                     ,cv_api_name             -- API名：生産バッチヘッダ完了
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                            --# 任意 #
      -- APIログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || it_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
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
  END close_batch_api;
--
  /**********************************************************************************
   * Procedure Name   :  save_batch_api
   * Description      :  生産セーブ処理(A-7)
   ***********************************************************************************/
  PROCEDURE save_batch_api(
    it_batch_no   IN  gme_batch_header.batch_no%TYPE,  -- 1.バッチNO
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'save_batch_api'; -- プログラム名
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
    cv_api_name   CONSTANT VARCHAR2(100) := '生産バッチセーブ';
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
      -- メッセージ初期化API
      FND_MSG_PUB.INITIALIZE();
--
    -- ***************************************
    -- ***       生産バッチセーブ実行      ***
    -- ***************************************
    GME_API_PUB.SAVE_BATCH(
      p_batch_header   => gr_gme_batch_header   -- IN ：p_batch_header  更新する値をセットしたレコード
     ,x_return_status  => lv_retcode            -- OUT：x_return_status
     ,p_commit         => FALSE                 -- IN ：p_commit
    );
--
    -- 正常終了以外の場合、警告
    IF (lv_retcode <> gv_api_s) THEN
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    --*** API例外 ***
    WHEN api_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10049       -- メッセージ：APP-XXWIP-10049 APIエラーメッセージ
                     ,gv_tkn_api_name         -- トークン：API_NAME
                     ,cv_api_name             -- API名：生産バッチヘッダ完了
                    ),1,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                            --# 任意 #
      -- APIログ出力
      FND_FILE.PUT_LINE(FND_FILE.LOG,gv_batch_no || it_batch_no);
      xxcmn_common_pkg.put_api_log(
        ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
       ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
       ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
      );
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
  END save_batch_api;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_product_date_from IN  VARCHAR2,      -- 1.生産日（FROM）
    iv_product_date_to   IN  VARCHAR2,      -- 2.生産日（TO）
    iv_plant_code        IN  VARCHAR2,      -- 3.プラントコード
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_product_date_from VARCHAR2(100);  -- INパラメータ.生産日（FROM）格納用
    lv_product_date_to   VARCHAR2(100);  -- INパラメータ.生産日（TO）格納用
    lv_plant_code        VARCHAR2(100);  -- INパラメータ.プラント格納用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 生産バッチヘッダカーソル
    CURSOR gme_batch_header_cur
    IS
      SELECT gbh.batch_no                          batch_no          -- バッチNo
            ,gbh.batch_id                          batch_id          -- バッチID
            ,FND_DATE.STRING_TO_DATE(gmd.attribute11,'YYYY/MM/DD')
                                                   product_date      -- 生産日
            ,gbh.batch_status                      batch_status      -- バッチステータス
      FROM   gme_batch_header                      gbh               -- 生産バッチヘッダ
            ,gme_material_details                  gmd               -- 生産原料詳細
      WHERE  gbh.batch_id     = gmd.batch_id           -- バッチID（結合条件）
      AND    gmd.line_type    = gt_line_type_goods     -- ラインタイプ   = 1（完成品）
      AND    gbh.attribute4   = gt_duty_status_com     -- 業務ステータス = 7（完了）
      AND  ((lv_product_date_from IS NULL)             -- 生産日（FROM）に入力がない場合、生産日（FROM）を条件としない
        OR  (gmd.attribute11 >= lv_product_date_from)) -- 生産日（FROM）に入力がある場合、生産日（FROM）を条件に加える
      AND    gmd.attribute11 <= lv_product_date_to     -- 生産日（TO）
      AND  ((lv_plant_code IS NULL)                    -- プラントコードに入力がない場合、プラントコードを条件としない
        OR  (gbh.plant_code   = iv_plant_code))        -- プラントコードに入力がある場合、プラントコードを条件に加える
    ;
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
    -- ===============================
    -- A-1.パラメータチェック処理
    -- ===============================
    -- INパラメータ格納
    lv_product_date_from := iv_product_date_from;
    lv_product_date_to   := iv_product_date_to;
    lv_plant_code        := iv_plant_code;
--
    parameter_check(
      iv_plant_code         => lv_plant_code         -- IN    ：1.プラントコード
     ,iov_product_date_from => lv_product_date_from  -- IN OUT：2.生産日（FROM）
     ,iov_product_date_to   => lv_product_date_to    -- IN OUT：3.生産日（TO）
     ,ov_errbuf             => lv_errbuf             -- OUT   ：エラー・メッセージ
     ,ov_retcode            => lv_retcode            -- OUT   ：リターン・コード
     ,ov_errmsg             => lv_errmsg             -- OUT   ：ユーザー・エラー・メッセージ
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.共通データ取得処理
    -- ===============================
    get_common_data(
      ov_errbuf     => lv_errbuf     --   OUT：エラー・メッセージ
     ,ov_retcode    => lv_retcode    --   OUT：リターン・コード
     ,ov_errmsg     => lv_errmsg     --   OUT：ユーザー・エラー・メッセージ
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3.生産バッチヘッダ取得処理
    -- ===============================
    <<gme_batch_header_loop>>
    FOR lr_gme_batch_header IN gme_batch_header_cur LOOP
      -- 更新用生産バッチヘッダレコード初期化
      gr_gme_batch_header.actual_cmplt_date := NULL; -- 実績完了日
      gr_gme_batch_header.batch_close_date  := NULL; -- クローズ日付
--
      -- 更新用生産バッチヘッダレコードにバッチIDをセット
      gr_gme_batch_header.batch_id   := lr_gme_batch_header.batch_id;    -- バッチID
--
      BEGIN
        -- ===============================
        -- A-4.ロック処理
        -- ===============================
        get_lock(
          ov_errbuf    => lv_errbuf     -- OUT：エラー・メッセージ
         ,ov_retcode   => lv_retcode    -- OUT：リターン・コード
         ,ov_errmsg    => lv_errmsg     -- OUT：ユーザー・エラー・メッセージ
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 警告の場合
        ELSIF (lv_retcode = gv_status_warn) THEN
          -- 後続処理をスキップ
          RAISE skip_expt;
        END IF;
--
        -- バッチステータス = 完了の場合は生産完了処理を行わない
        IF (lr_gme_batch_header.batch_status <> gt_batch_status_com) THEN
          -- 更新用生産バッチヘッダレコードに値をセット
          gr_gme_batch_header.actual_cmplt_date := lr_gme_batch_header.product_date; -- 実績完了日
--
          -- ===============================
          -- A-5.生産完了処理
          -- ===============================
          certify_batch_api(
            it_batch_no  => lr_gme_batch_header.batch_no   -- IN ：1.バッチNo
           ,ov_errbuf    => lv_errbuf    -- OUT：エラー・メッセージ
           ,ov_retcode   => lv_retcode   -- OUT：リターン・コード
           ,ov_errmsg    => lv_errmsg    -- OUT：ユーザー・エラー・メッセージ
          );
--
          -- エラーの場合
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
--
          -- 警告の場合
          ELSIF (lv_retcode = gv_status_warn) THEN
            -- 後続処理をスキップ
            RAISE skip_expt;
          END IF;
        END IF;
--
        -- 更新用生産バッチヘッダレコードに値をセット
        gr_gme_batch_header.actual_cmplt_date := NULL; -- 実績完了日
        gr_gme_batch_header.batch_close_date  := gd_close_date; -- クローズ日付
--
        -- ===============================
        -- A-6.生産クローズ処理
        -- ===============================
        close_batch_api(
          it_batch_no  => lr_gme_batch_header.batch_no   -- IN ：1.バッチNo
         ,ov_errbuf    => lv_errbuf    -- OUT：エラー・メッセージ
         ,ov_retcode   => lv_retcode   -- OUT：リターン・コード
         ,ov_errmsg    => lv_errmsg    -- OUT：ユーザー・エラー・メッセージ
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 警告の場合
        ELSIF (lv_retcode = gv_status_warn) THEN
          -- 後続処理をスキップ
          RAISE skip_expt;
        END IF;
--
        -- ===============================
        -- A-7.生産セーブ処理
        -- ===============================
        save_batch_api(
          it_batch_no  => lr_gme_batch_header.batch_no   -- IN ：1.バッチNo
         ,ov_errbuf    => lv_errbuf    -- OUT：エラー・メッセージ
         ,ov_retcode   => lv_retcode   -- OUT：リターン・コード
         ,ov_errmsg    => lv_errmsg    -- OUT：ユーザー・エラー・メッセージ
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 警告の場合
        ELSIF (lv_retcode = gv_status_warn) THEN
          -- 後続処理をスキップ
          RAISE skip_expt;
--
        -- 正常の場合
        ELSE
          -- 成功カウント
          gn_normal_cnt := gn_normal_cnt + 1;
          -- COMMIT
          COMMIT;
        END IF;
--
      EXCEPTION
        WHEN skip_expt THEN        --*** スキップ ***
          -- 警告カウント
          gn_warn_cnt := gn_warn_cnt + 1;
          -- 警告メッセージ出力
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          -- リターン・コードに警告をセット
          ov_retcode := gv_status_warn;
          -- ROLLBACK
          ROLLBACK;
      END;
--
    END LOOP gme_batch_header_loop;
--
  EXCEPTION
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
    errbuf               OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode              OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_product_date_from IN  VARCHAR2,      -- 1.生産日（FROM）
    iv_product_date_to   IN  VARCHAR2,      -- 2.生産日（TO）
    iv_plant_code        IN  VARCHAR2)      -- 3.プラントコード

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
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_product_date_from,  -- 1.生産日（FROM）
      iv_product_date_to,    -- 2.生産日（TO）
      iv_plant_code,         -- 3.プラントコード
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- A-8.リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
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
END xxwip210001c;
/
