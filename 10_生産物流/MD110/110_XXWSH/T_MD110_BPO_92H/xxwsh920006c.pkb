CREATE OR REPLACE PACKAGE BODY xxwsh920006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh920006c(body)
 * Description      : 倉庫品目マスタ取込処理
 * MD.050           : 生産物流共通（出荷・移動仮引当）T_MD050_BPO_922
 * MD.070           : 倉庫品目マスタ取込処理(92H) T_MD070_BPO_92H
 * Version          : 1.0
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                       Description
 * --------------------------- ----------------------------------------------------------
 *  init_proc                   関連データ取得処理(H-1)
 *  get_request_id              要求ID取得処理(H-2)
 *  get_lock                    ロック取得処理(H-3)
 *  del_duplication_data        重複データ除外処理(H-4)
 *  ins_data_loop               登録データ取得処理(H-5)
 *  upd_data_loop               更新データ取得処理(H-6)
 *  chk_master_data             マスタデータチェック処理(H-7)
 *  chk_consistency_data        妥当性チェック処理(H-8)
 *  set_ins_tab                 登録用PL/SQL表投入(H-9)
 *  set_upd_tab                 更新用PL/SQL表投入(H-10)
 *  ins_table_batch             一括登録処理(H-11)
 *  upd_table_batch             一括更新処理(H-12)
 *  del_data                    一括削除処理(H-13)
 *  put_dump_msg                データダンプ一括出力処理(H-14)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/12    1.0   H.Itou           新規作成
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
  lock_expt              EXCEPTION;        -- ロック取得例外
  skip_expt              EXCEPTION;        -- スキップ例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh920006c'; -- パッケージ名
  -- モジュール名略称
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';        -- モジュール名略称：XXCMN
  gv_xxwsh           CONSTANT VARCHAR2(100) := 'XXWSH';        -- モジュール名略称：XXWSH
--
  -- メッセージ
  gv_msg_xxcmn10002  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
  gv_msg_xxcmn10019  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; -- メッセージ：APP-XXCMN-10019 ロックエラー
  gv_msg_xxcmn10001  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10001'; -- メッセージ：APP-XXCMN-10001 対象データなし
  gv_msg_xxcmn00005  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005'; -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
  gv_msg_xxcmn00007  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00007'; -- メッセージ：APP-XXCMN-00007 スキップデータ（見出し）
  gv_msg_xxwsh13451  CONSTANT VARCHAR2(100) := 'APP-XXWSH-13451'; -- メッセージ：APP-XXWSH-13451 データ重複エラーメッセージ
  gv_msg_xxwsh13452  CONSTANT VARCHAR2(100) := 'APP-XXWSH-13452'; -- メッセージ：APP-XXWSH-13452 元倉庫エラー
  gv_msg_xxwsh13453  CONSTANT VARCHAR2(100) := 'APP-XXWSH-13453'; -- メッセージ：APP-XXWSH-13453 代表倉庫エラー
--
  -- トークン
  gv_tkn_value              CONSTANT VARCHAR2(100) := 'VALUE';            -- トークン：VALUE
  gv_tkn_item               CONSTANT VARCHAR2(100) := 'ITEM';             -- トークン：ITEM
  gv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';            -- トークン：TABLE
  gv_tkn_key                CONSTANT VARCHAR2(100) := 'KEY';              -- トークン：KEY
  gv_tkn_ng_profile         CONSTANT VARCHAR2(100) := 'NG_PROFILE';       -- トークン：NG_PROFILE
--
  -- トークン名称
  gv_xxwsh_frq_item_locations    CONSTANT VARCHAR2(50) := '倉庫品目アドオンマスタ';
  gv_xxwsh_frq_item_locations_if CONSTANT VARCHAR2(50) := '倉庫品目アドオンマスタインタフェース';
  gv_tkn_dummy_frequent_whse     CONSTANT VARCHAR2(100) := 'XXCMN:ダミー代表倉庫';
  gv_tkn_item_locations          CONSTANT VARCHAR2(100) := 'OPM保管場所情報';
  gv_tkn_item_mst                CONSTANT VARCHAR2(100) := 'OPM品目情報';
  gv_tkn_item_location_code      CONSTANT VARCHAR2(100) := '保管場所コード:';
  gv_tkn_item_code               CONSTANT VARCHAR2(100) := '品目コード:';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 要求ID用PL/SQL表型
  TYPE request_id_ttype         IS TABLE OF  fnd_concurrent_requests.request_id           %TYPE INDEX BY BINARY_INTEGER;  -- 要求ID
--
  -- メッセージPL/SQL表型
  TYPE msg_ttype                IS TABLE OF VARCHAR2(5000)                                      INDEX BY BINARY_INTEGER;
--
  -- 登録・更新用PL/SQL表型
  TYPE pk_id_ttype              IS TABLE OF  xxwsh_frq_item_locations.pk_id               %TYPE INDEX BY BINARY_INTEGER;  -- 倉庫品目ID
  TYPE item_location_id_ttype   IS TABLE OF  xxcmn_item_locations_v.inventory_location_id %TYPE INDEX BY BINARY_INTEGER;  -- 保管倉庫ID
  TYPE item_location_code_ttype IS TABLE OF  xxcmn_item_locations_v.segment1              %TYPE INDEX BY BINARY_INTEGER;  -- 保管倉庫コード
  TYPE item_id_ttype            IS TABLE OF  xxcmn_item_mst_v.item_id                     %TYPE INDEX BY BINARY_INTEGER;  -- 品目ID
  TYPE item_code_ttype          IS TABLE OF  xxcmn_item_mst_v.item_no                     %TYPE INDEX BY BINARY_INTEGER;  -- 品目コード
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 要求ID用PL/SQL表
  request_id_tab   request_id_ttype;
--
  -- 警告データダンプPL/SQL表
  warn_dump_tab    msg_ttype;
--
  -- 正常データダンプPL/SQL表
  normal_dump_tab  msg_ttype; 
--
  -- 登録用PL/SQL表
  pk_id_tab                       pk_id_ttype;                -- 倉庫品目ID
  item_location_id_ins_tab        item_location_id_ttype;     -- 元倉庫ID
  item_location_code_ins_tab      item_location_code_ttype;   -- 元倉庫コード
  item_id_ins_tab                 item_id_ttype;              -- 品目ID
  item_code_ins_tab               item_code_ttype;            -- 品目コード
  frq_item_location_id_ins_tab    item_location_id_ttype;     -- 代表倉庫ID
  frq_item_location_code_ins_tab  item_location_code_ttype;   -- 代表倉庫コード
--
  -- 更新用PL/SQL表
  frq_item_location_id_upd_tab    item_location_id_ttype;     -- 代表倉庫ID
  item_location_code_upd_tab      item_location_code_ttype;   -- 元倉庫コード
  item_code_upd_tab               item_code_ttype;            -- 品目コード
  frq_item_location_code_upd_tab  item_location_code_ttype;   -- 代表倉庫
--
  -- カウント
  gn_request_id_cnt   NUMBER := 0;   -- 要求IDカウント
  gn_warn_msg_cnt     NUMBER := 0;   -- 警告エラーメッセージ表カウント
  gn_ins_tab_cnt      NUMBER := 0;   -- 登録用PL/SQL表カウント
  gn_upd_tab_cnt      NUMBER := 0;   -- 更新用PL/SQL表カウント
--
  -- プロファイルオプション
  gv_dummy_frequent_whse    VARCHAR2(100);
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
    -- 倉庫品目アドオンマスタインタフェース登録カーソル
    CURSOR ins_cur(lt_request_id    xxwsh_frq_item_locations_if.request_id%TYPE)
    IS
      SELECT xfili.item_location_code      item_location_code       -- 元倉庫コード
            ,xilv1.inventory_location_id   item_location_id         -- 元倉庫ID
            ,xilv1.frequent_whse           frequent_whse            -- 元倉庫_代表倉庫
            ,xfili.frq_item_location_code  frq_item_location_code   -- 代表倉庫コード
            ,xilv2.inventory_location_id   frq_item_location_id     -- 代表倉庫ID
            ,xilv2.frequent_whse           frq_frequent_whse        -- 代表倉庫_代表倉庫
            ,xfili.item_code               item_code                -- 品目コード
            ,ximv.item_id                  item_id                  -- 品目ID
            ,xfili.item_location_code     || gv_msg_comma ||
             xfili.item_code              || gv_msg_comma ||
             xfili.frq_item_location_code  data_dump                -- データダンプ
      FROM   xxwsh_frq_item_locations_if   xfili                    -- 倉庫品目アドオンマスタインタフェース
            ,xxcmn_item_locations_v        xilv1                    -- OPM保管場所情報VIEW(元倉庫情報)
            ,xxcmn_item_locations_v        xilv2                    -- OPM保管場所情報VIEW(代表倉庫情報)
            ,xxcmn_item_mst_v              ximv                     -- OPM品目情報VIEW(品目情報)
      WHERE  -- ** 結合条件 元倉庫情報 ** --
             xfili.item_location_code     = xilv1.segment1(+)
             -- ** 結合条件 代表倉庫情報 ** --
      AND    xfili.frq_item_location_code = xilv2.segment1(+)
             -- ** 結合条件 品目情報 ** --
      AND    xfili.item_code              = ximv.item_no(+)
             -- ** 抽出条件 ** --
      AND    xfili.request_id             = lt_request_id           -- 要求ID
      AND    NOT EXISTS( -- 倉庫品目アドオンマスタに存在しないキー項目を持つデータ
                   SELECT 1
                   FROM   xxwsh_frq_item_locations  xfil                      -- 倉庫品目アドオンマスタ
                   WHERE  xfil.item_location_code = xfili.item_location_code  -- 元倉庫
                   AND    xfil.item_code          = xfili.item_code           -- 品目コード
                 )
      ;
--
    -- 倉庫品目アドオンマスタインタフェース更新カーソル
    CURSOR upd_cur(lt_request_id    xxwsh_frq_item_locations_if.request_id%TYPE)
    IS
      SELECT xfili.item_location_code      item_location_code       -- 元倉庫コード
            ,xilv1.inventory_location_id   item_location_id         -- 元倉庫ID
            ,xilv1.frequent_whse           frequent_whse            -- 元倉庫_代表倉庫
            ,xfili.frq_item_location_code  frq_item_location_code   -- 代表倉庫コード
            ,xilv2.inventory_location_id   frq_item_location_id     -- 代表倉庫ID
            ,xilv2.frequent_whse           frq_frequent_whse        -- 代表倉庫_代表倉庫
            ,xfili.item_code               item_code                -- 品目コード
            ,ximv.item_id                  item_id                  -- 品目ID
            ,xfili.item_location_code     || gv_msg_comma ||
             xfili.item_code              || gv_msg_comma ||
             xfili.frq_item_location_code  data_dump                -- データダンプ
      FROM   xxwsh_frq_item_locations_if   xfili                    -- 倉庫品目アドオンマスタインタフェース
            ,xxcmn_item_locations_v        xilv1                    -- OPM保管場所情報VIEW(元倉庫情報)
            ,xxcmn_item_locations_v        xilv2                    -- OPM保管場所情報VIEW(代表倉庫情報)
            ,xxcmn_item_mst_v              ximv                     -- OPM品目情報VIEW(品目情報)
      WHERE  -- ** 結合条件 元倉庫情報 ** --
             xfili.item_location_code     = xilv1.segment1(+)
             -- ** 結合条件 代表倉庫情報 ** --
      AND    xfili.frq_item_location_code = xilv2.segment1(+)
             -- ** 結合条件 品目情報 ** --
      AND    xfili.item_code              = ximv.item_no(+)
             -- ** 抽出条件 ** --
      AND    xfili.request_id             = lt_request_id           -- 要求ID
      AND    EXISTS( -- 倉庫品目アドオンマスタに存在するキー項目を持つデータ
               SELECT 1
               FROM   xxwsh_frq_item_locations  xfil                      -- 倉庫品目アドオンマスタ
               WHERE  xfil.item_location_code = xfili.item_location_code  -- 元倉庫
               AND    xfil.item_code          = xfili.item_code           -- 品目コード
             )
      ;
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 関連データ取得処理(H-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    cv_dummy_frequent_whse   VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';   -- ダミー代表倉庫
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
    -- ===========================
    -- プロファイルオプション取得
    -- ===========================
    gv_dummy_frequent_whse   := FND_PROFILE.VALUE(cv_dummy_frequent_whse);   -- ダミー代表倉庫
--
    -- =========================================
    -- プロファイルオプション取得エラーチェック
    -- =========================================
    IF (gv_dummy_frequent_whse IS NULL) THEN -- ダミー代表倉庫プロファイル取得エラー
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002            -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile            -- トークン:NGプロファイル名
                       ,gv_tkn_dummy_frequent_whse)  -- ダミー代表倉庫
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_request_id
   * Description      : 要求ID取得処理(H-2)
   ***********************************************************************************/
  PROCEDURE get_request_id(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_request_id'; -- プログラム名
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
    -- 要求IDカーソル
    CURSOR xfili_request_id_cur
    IS
      SELECT fcr.request_id request_id
      FROM   fnd_concurrent_requests fcr   -- コンカレント要求IDテーブル
      WHERE  EXISTS (
               SELECT 1
               FROM   xxwsh_frq_item_locations_if xfili   -- 倉庫品目アドオンマスタインタフェース
               WHERE  xfili.request_id = fcr.request_id   -- 要求ID
               AND    ROWNUM          = 1
             )
      ORDER BY request_id
    ;
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
    <<get_request_id_loop>>
    FOR lr_xfili_request_id IN xfili_request_id_cur
    LOOP
      gn_request_id_cnt := gn_request_id_cnt + 1 ;
      request_id_tab(gn_request_id_cnt) := lr_xfili_request_id.request_id;
    END LOOP get_request_id_loop;
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
  END get_request_id;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ロック取得処理(H-3)
   ***********************************************************************************/
  PROCEDURE get_lock(
    ov_errbuf     OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 倉庫品目アドオンマスタインタフェースカーソル
    CURSOR if_lock_cur(lt_request_id xxwsh_frq_item_locations_if.request_id%TYPE)
    IS
      SELECT xfili.seq_number  seq_number
      FROM   xxwsh_frq_item_locations_if    xfili -- 倉庫品目アドオンマスタインタフェース
      WHERE  xfili.request_id = lt_request_id     -- 要求ID
      FOR UPDATE NOWAIT
    ;
--
    -- 倉庫品目アドオンマスタカーソル
    CURSOR lock_cur
    IS
      SELECT xfil.pk_id  pk_id
      FROM   xxwsh_frq_item_locations   xfil     -- 倉庫品目アドオンマスタ
      FOR UPDATE NOWAIT
    ;
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
    -- ==================================================
    -- 倉庫品目アドオンマスタインタフェース ロック取得
    -- ==================================================
    BEGIN
      <<request_id_loop>>
      FOR ln_count IN 1..request_id_tab.COUNT
      LOOP
        <<if_lock_loop>>
        FOR lr_if_lock IN if_lock_cur(request_id_tab(ln_count))
        LOOP
          EXIT;
        END LOOP look_if_loop;
      END LOOP request_id_loop;
--
    EXCEPTION
      WHEN lock_expt THEN --*** ロック取得エラー ***
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn                        -- モジュール名略称：XCMN
                         ,gv_msg_xxcmn10019               -- メッセージ：APP-XXCMN-10019 ロックエラー
                         ,gv_tkn_table                    -- トークンTABLE
                         ,gv_xxwsh_frq_item_locations_if) -- テーブル名：倉庫品目アドオンマスタインタフェース
                       ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- 倉庫品目アドオンマスタ ロック取得
    -- =====================================
    BEGIN
       <<lock_loop>>
      FOR lr_lock IN lock_cur
      LOOP
        EXIT;
      END LOOP lock_loop;
--
    EXCEPTION
      WHEN lock_expt THEN --*** ロック取得エラー ***
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn                        -- モジュール名略称：XCMN
                         ,gv_msg_xxcmn10019               -- メッセージ：APP-XXCMN-10019 ロックエラー
                         ,gv_tkn_table                    -- トークンTABLE
                         ,gv_xxwsh_frq_item_locations)    -- テーブル名：倉庫品目アドオンマスタ
                       ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END get_lock;
--
--
  /**********************************************************************************
   * Procedure Name   : del_duplication_data
   * Description      : 重複データ除外処理(H-4)
   ***********************************************************************************/
  PROCEDURE del_duplication_data(
    it_request_id IN  xxwsh_frq_item_locations_if.request_id%TYPE,     -- 1.要求ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_duplication_data'; -- プログラム名
    cv_item       CONSTANT VARCHAR2(100) := 'データ';
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
    -- 重複チェックカーソル
    CURSOR duplication_chk_cur
    IS
      SELECT xfili2.cnt                     cnt                      -- カウント
            ,xfili1.item_location_code      item_location_code       -- 元倉庫
            ,xfili1.item_code               item_code                -- 品目コード
            ,xfili1.request_id              request_id               -- 要求ID
            ,xfili1.item_location_code     || gv_msg_comma ||
             xfili1.item_code              || gv_msg_comma ||
             xfili1.frq_item_location_code  data_dump                -- データダンプ
      FROM   xxwsh_frq_item_locations_if    xfili1                   -- 倉庫品目アドオンマスタインタフェース
            ,(SELECT COUNT(xfili.seq_number)      cnt                -- カウント
                    ,xfili.item_location_code     item_location_code -- 元倉庫
                    ,xfili.item_code              item_code          -- 品目コード
                    ,xfili.request_id             request_id         -- 要求ID
              FROM   xxwsh_frq_item_locations_if  xfili              -- 倉庫品目アドオンマスタインタフェース
              GROUP BY 
                     xfili.item_location_code                        -- 元倉庫
                    ,xfili.item_code                                 -- 品目コード
                    ,xfili.request_id                                -- 要求ID
             )                            xfili2                     -- 重複カウント用副問合せ
      WHERE -- ** 結合条件 ** --
            xfili1.item_location_code = xfili2.item_location_code    -- 元倉庫
      AND   xfili1.item_code          = xfili2.item_code             -- 品目コード
      AND   xfili1.request_id         = xfili2.request_id            -- 要求ID
            -- ** 抽出条件 ** --
      AND   xfili1.request_id         = it_request_id                -- 要求ID
      AND   xfili2.cnt                > 1                            -- 同一キーが2件以上
    ;
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
    -- ===============================
    -- 重複チェック
    -- ===============================
    <<duplication_chk_loop>>
    FOR lr_duplication_chk IN duplication_chk_cur LOOP
      -- 重複警告メッセージ取得
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxwsh               -- モジュール名略称：XXWSH
                       ,gv_msg_xxwsh13451)     -- メッセージ：APP-XXWSH-13451 データ重複エラーメッセージ
                     ,1,5000);
--
      -- 警告ダンプPL/SQL表にダンプをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lr_duplication_chk.data_dump;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      --  リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
      -- スキップ件数カウント
      gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- ===============================
      -- エラーデータ削除
      -- ===============================
      DELETE xxwsh_frq_item_locations_if xfili   -- 倉庫品目アドオンマスタインタフェース
      WHERE  xfili.item_location_code = lr_duplication_chk.item_location_code       -- 元倉庫
      AND    xfili.item_code          = lr_duplication_chk.item_code                -- 品目コード
      AND    xfili.request_id         = lr_duplication_chk.request_id               -- 要求ID
      ;
--
    END LOOP duplication_chk_loop;
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
  END del_duplication_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_master_data
   * Description      : マスタデータチェック処理(H-7)
   ***********************************************************************************/
  PROCEDURE chk_master_data(
    ir_chk_data   IN  ins_cur%ROWTYPE, -- チェックデータ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_master_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_cnt NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 元倉庫チェック
    -- ===========================
    -- 元倉庫IDを抽出できていない場合、警告
    IF (ir_chk_data.item_location_id IS NULL) THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10001      -- メッセージ:APP-XXCMN-10001 対象データなし
                       ,gv_tkn_table           -- トークン:TABLE
                       ,gv_tkn_item_locations  -- エラーテーブル名
                       ,gv_tkn_key             -- トークン:KEY
                       ,gv_tkn_item_location_code || ir_chk_data.item_location_code)  -- エラーキー項目
                     ,1,5000);
--
      -- 警告ダンプPL/SQL表にダンプをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := ir_chk_data.data_dump;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- 代表倉庫チェック
    -- ===========================
    -- 代表倉庫IDを抽出できていない場合、警告
    IF (ir_chk_data.frq_item_location_id IS NULL) THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10001      -- メッセージ:APP-XXCMN-10001 対象データなし
                       ,gv_tkn_table           -- トークン:TABLE
                       ,gv_tkn_item_locations  -- エラーテーブル名
                       ,gv_tkn_key             -- トークン:KEY
                       ,gv_tkn_item_location_code || ir_chk_data.frq_item_location_code)  -- エラーキー項目
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := ir_chk_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- 品目コードチェック
    -- ===========================
    -- 品目IDを抽出できていない場合、警告
    IF (ir_chk_data.item_id IS NULL) THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10001      -- メッセージ:APP-XXCMN-10001 対象データなし
                       ,gv_tkn_table           -- トークン:TABLE
                       ,gv_tkn_item_mst        -- エラーテーブル名
                       ,gv_tkn_key             -- トークン:KEY
                       ,gv_tkn_item_code || ir_chk_data.item_code)  -- エラーキー項目
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := ir_chk_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
    END IF;
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
  END chk_master_data;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_consistency_data
   * Description      : 妥当性チェック処理(H-8)
   ***********************************************************************************/
  PROCEDURE chk_consistency_data(
    ir_chk_data   IN  ins_cur%ROWTYPE, -- チェックデータ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_consistency_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_cnt NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 元倉庫妥当性チェック
    -- ===========================
    -- 元倉庫_代表倉庫がダミー代表倉庫でない場合、警告
    IF (ir_chk_data.frequent_whse <> gv_dummy_frequent_whse) THEN
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxwsh               -- モジュール名略称:XWSH
                       ,gv_msg_xxwsh13452)     -- メッセージ:APP-XXWSH-13452 元倉庫エラー
                     ,1,5000);
--
      -- 警告ダンプPL/SQL表にダンプをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := ir_chk_data.data_dump;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- 代表倉庫妥当性チェック
    -- ===========================
    -- 代表倉庫が代表倉庫_代表倉庫でない場合、警告
    IF (ir_chk_data.frq_item_location_code <> ir_chk_data.frq_frequent_whse) THEN
--
      -- 警告メッセージ出力
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxwsh               -- モジュール名略称:XWSH
                       ,gv_msg_xxwsh13453)     -- メッセージ:APP-XXWSH-13453 代表倉庫エラー
                     ,1,5000);
--
      -- すでに警告の場合は、ダンプ不要
      IF (ov_retcode <> gv_status_warn) THEN
        -- 警告ダンプPL/SQL表にダンプをセット
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := ir_chk_data.data_dump;
      END IF;
--
      -- 警告ダンプPL/SQL表に警告メッセージをセット
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- リターン・コードに警告をセット
      ov_retcode := gv_status_warn;
--
    END IF;
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
  END chk_consistency_data;
--
  /**********************************************************************************
   * Procedure Name   : set_ins_tab
   * Description      : 登録用PL/SQL表投入(H-9)
   ***********************************************************************************/
  PROCEDURE set_ins_tab(
    ir_data       IN  ins_cur%ROWTYPE, -- データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_ins_tab'; -- プログラム名
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
    -- ===============================
    -- 登録用PL/SQL表にセット
    -- ===============================
    -- 登録用件数カウント
    gn_ins_tab_cnt := gn_ins_tab_cnt + 1;
--
    SELECT xxwsh_frq_item_locations_id_s1.NEXTVAL
    INTO   pk_id_tab(gn_ins_tab_cnt)                                   -- 倉庫品目ID
    FROM   DUAL;
    item_location_id_ins_tab(gn_ins_tab_cnt)       := ir_data.item_location_id;       -- 元倉庫ID
    item_location_code_ins_tab(gn_ins_tab_cnt)     := ir_data.item_location_code;     -- 元倉庫コード
    item_id_ins_tab(gn_ins_tab_cnt)                := ir_data.item_id;                -- 品目ID
    item_code_ins_tab(gn_ins_tab_cnt)              := ir_data.item_code;              -- 品目コード
    frq_item_location_id_ins_tab(gn_ins_tab_cnt)   := ir_data.frq_item_location_id;   -- 代表倉庫ID
    frq_item_location_code_ins_tab(gn_ins_tab_cnt) := ir_data.frq_item_location_code; -- 代表倉庫コード
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
  END set_ins_tab;
--
  /**********************************************************************************
   * Procedure Name   : set_upd_tab
   * Description      : 更新用PL/SQL表投入(H-10)
   ***********************************************************************************/
  PROCEDURE set_upd_tab(
    ir_data       IN  ins_cur%ROWTYPE, -- データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_upd_tab'; -- プログラム名
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
    -- ===============================
    -- 更新用PL/SQL表にセット
    -- ===============================
    -- 更新用カウント
    gn_upd_tab_cnt := gn_upd_tab_cnt + 1;
--
    item_location_code_upd_tab(gn_upd_tab_cnt)     := ir_data.item_location_code;     -- 元倉庫コード
    item_code_upd_tab(gn_upd_tab_cnt)              := ir_data.item_code;              -- 品目コード
    frq_item_location_id_upd_tab(gn_upd_tab_cnt)   := ir_data.frq_item_location_id;   -- 代表倉庫ID
    frq_item_location_code_upd_tab(gn_upd_tab_cnt) := ir_data.frq_item_location_code; -- 代表倉庫コード
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
  END set_upd_tab;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_data
   * Description      : 一括登録処理(H-11)
   ***********************************************************************************/
  PROCEDURE ins_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_data'; -- プログラム名
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
    -- ===============================
    -- 一括登録処理
    -- ===============================
    FORALL ln_cnt_loop IN 1 .. pk_id_tab.COUNT
      INSERT INTO xxwsh_frq_item_locations  xfil      -- 倉庫品目アドオンマスタ
        (xfil.pk_id                                   -- 倉庫品目ID
        ,xfil.item_location_id                        -- 元倉庫ID
        ,xfil.item_location_code                      -- 元倉庫コード
        ,xfil.item_id                                 -- 品目ID
        ,xfil.item_code                               -- 品目コード
        ,xfil.frq_item_location_id                    -- 代表倉庫ID
        ,xfil.frq_item_location_code                  -- 代表倉庫コード
        ,xfil.created_by                              -- 作成者
        ,xfil.creation_date                           -- 作成日
        ,xfil.last_updated_by                         -- 最終更新者
        ,xfil.last_update_date                        -- 最終更新日
        ,xfil.last_update_login                       -- 最終更新ログイン
        ,xfil.request_id                              -- 要求ID
        ,xfil.program_application_id                  -- コンカレント・プログラム・アプリケーションID
        ,xfil.program_id                              -- コンカレント・プログラムID
        ,xfil.program_update_date                     -- プログラム更新日
        )
      VALUES
        (pk_id_tab(ln_cnt_loop)                       -- 倉庫品目ID
        ,item_location_id_ins_tab(ln_cnt_loop)        -- 元倉庫ID
        ,item_location_code_ins_tab(ln_cnt_loop)      -- 元倉庫コード
        ,item_id_ins_tab(ln_cnt_loop)                 -- 品目ID
        ,item_code_ins_tab(ln_cnt_loop)               -- 品目コード
        ,frq_item_location_id_ins_tab(ln_cnt_loop)    -- 代表倉庫ID
        ,frq_item_location_code_ins_tab(ln_cnt_loop)  -- 代表倉庫コード
        ,FND_GLOBAL.USER_ID                           -- 作成者
        ,SYSDATE                                      -- 作成日
        ,FND_GLOBAL.USER_ID                           -- 最終更新者
        ,SYSDATE                                      -- 最終更新日
        ,FND_GLOBAL.LOGIN_ID                          -- 最終更新ログイン
        ,FND_GLOBAL.CONC_REQUEST_ID                   -- 要求ID
        ,FND_GLOBAL.PROG_APPL_ID                      -- コンカレント・プログラム・アプリケーションID
        ,FND_GLOBAL.CONC_PROGRAM_ID                   -- コンカレント・プログラムID
        ,SYSDATE                                      -- プログラム更新日
        );
--
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
  END ins_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_data
   * Description      : 一括更新処理(H-12)
   ***********************************************************************************/
  PROCEDURE upd_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_data'; -- プログラム名
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
    -- ===============================
    -- 一括更新処理
    -- ===============================
    FORALL ln_cnt_loop IN 1 .. frq_item_location_code_upd_tab.COUNT
      UPDATE xxwsh_frq_item_locations  xfil      -- 倉庫品目アドオンマスタ
      SET    xfil.frq_item_location_id   = frq_item_location_id_upd_tab(ln_cnt_loop)    -- 代表倉庫ID
            ,xfil.frq_item_location_code = frq_item_location_code_upd_tab(ln_cnt_loop)  -- 代表倉庫コード
            ,xfil.last_updated_by        = FND_GLOBAL.USER_ID                           -- 最終更新者
            ,xfil.last_update_date       = SYSDATE                                      -- 最終更新日
            ,xfil.last_update_login      = FND_GLOBAL.LOGIN_ID                          -- 最終更新ログイン
            ,xfil.request_id             = FND_GLOBAL.CONC_REQUEST_ID                   -- 要求ID
            ,xfil.program_application_id = FND_GLOBAL.PROG_APPL_ID                      -- コンカレント・プログラム・アプリケーションID
            ,xfil.program_id             = FND_GLOBAL.CONC_PROGRAM_ID                   -- コンカレント・プログラムID
            ,xfil.program_update_date    = SYSDATE                                      -- プログラム更新日
      WHERE xfil.item_location_code      = item_location_code_upd_tab(ln_cnt_loop)      -- 元倉庫
      AND   xfil.item_code               = item_code_upd_tab(ln_cnt_loop)               -- 品目コード
      ;
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
  END upd_data;
--
  /**********************************************************************************
   * Procedure Name   : del_data
   * Description      : 一括削除処理(H-13)
   ***********************************************************************************/
  PROCEDURE del_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_data'; -- プログラム名
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
    -- ===============================
    -- 倉庫品目アドオンマスタインタフェース削除
    -- ===============================
    FORALL ln_count IN 1..request_id_tab.COUNT
      DELETE xxwsh_frq_item_locations_if xfili             -- 倉庫品目アドオンマスタインタフェース
      WHERE  xfili.request_id = request_id_tab(ln_count)   -- 要求ID
      ;
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
  END del_data;
--
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : データダンプ一括出力処理(H-14)
   ***********************************************************************************/
  PROCEDURE put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_dump_msg'; -- プログラム名
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
    lv_msg  VARCHAR2(5000);  -- メッセージ
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
    -- ===============================
    -- データダンプ一括出力
    -- ===============================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 成功データ（見出し）
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- モジュール名略称：XXCMN
                  ,gv_msg_xxcmn00005)     -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- 正常データダンプ
    <<normal_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, normal_dump_tab(ln_cnt_loop));
    END LOOP normal_dump_loop;
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- スキップデータデータ（見出し）
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- モジュール名略称：XXCMN
                  ,gv_msg_xxcmn00007)     -- メッセージ：APP-XXCMN-00007 スキップデータ（見出し）
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- 警告データダンプ
    <<warn_dump_loop>>
    FOR ln_cnt_loop IN 1 .. warn_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, warn_dump_tab(ln_cnt_loop));
    END LOOP warn_dump_loop;
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
  END put_dump_msg;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_data_loop
   * Description      : 登録データ取得処理(H-5)
   ***********************************************************************************/
  PROCEDURE ins_data_loop(
    it_request_id IN  xxwsh_frq_item_locations_if.request_id%TYPE,           -- 要求ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_data_loop'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***\
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =============================
    -- H-5.登録データ取得
    -- =============================
    <<ins_data_loop>>
    FOR lr_ins_data IN ins_cur(it_request_id) LOOP
      BEGIN
        -- =============================
        -- H-7.マスタデータチェック処理
        -- =============================
        chk_master_data(
          ir_chk_data => lr_ins_data        -- チェックデータ
         ,ov_errbuf   => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode  => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 警告の場合
        ELSIF (lv_retcode = gv_status_warn) THEN
          RAISE skip_expt;
        END IF;
--
        -- =============================
        -- H-8.妥当性チェック処理
        -- =============================
        chk_consistency_data(
          ir_chk_data => lr_ins_data        -- チェックデータ
         ,ov_errbuf   => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode  => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 警告の場合
        ELSIF (lv_retcode = gv_status_warn) THEN
          RAISE skip_expt;
        END IF;
--
        -- =============================
        -- H-9.登録用PL/SQL表投入
        -- =============================
        set_ins_tab(
          ir_data     => lr_ins_data        -- チェックデータ
         ,ov_errbuf   => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode  => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 正常の場合
        ELSE
          -- 正常データ件数
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- 正常データダンプPL/SQL表投入
          normal_dump_tab(gn_normal_cnt) := lr_ins_data.data_dump;
        END IF;
--
      EXCEPTION
        WHEN skip_expt THEN  -- 警告発生時、スキップして次レコードの処理を行う。
          -- OUTパラメータを警告にセット
          ov_retcode := gv_status_warn;
          -- スキップ件数カウント
          gn_warn_cnt   := gn_warn_cnt + 1;
      END;
--
    END LOOP ins_data_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END ins_data_loop;
--
  /**********************************************************************************
   * Procedure Name   : upd_data_loop
   * Description      : 更新データ取得処理(H-6)
   ***********************************************************************************/
  PROCEDURE upd_data_loop(
    it_request_id IN  xxwsh_frq_item_locations_if.request_id%TYPE,           -- 要求ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_data_loop'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***\
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =============================
    -- H-6.更新データ取得
    -- =============================
    <<upd_data_loop>>
    FOR lr_upd_data IN upd_cur(it_request_id) LOOP
      BEGIN
        -- =============================
        -- H-7.マスタデータチェック処理
        -- =============================
        chk_master_data(
          ir_chk_data => lr_upd_data        -- チェックデータ
         ,ov_errbuf   => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode  => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 警告の場合
        ELSIF (lv_retcode = gv_status_warn) THEN
          RAISE skip_expt;
        END IF;
--
        -- =============================
        -- H-8.妥当性チェック処理
        -- =============================
        chk_consistency_data(
          ir_chk_data => lr_upd_data        -- チェックデータ
         ,ov_errbuf   => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode  => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 警告の場合
        ELSIF (lv_retcode = gv_status_warn) THEN
          RAISE skip_expt;
        END IF;
--
        -- =============================
        -- H-10.更新用PL/SQL表投入
        -- =============================
        set_upd_tab(
          ir_data     => lr_upd_data        -- チェックデータ
         ,ov_errbuf   => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode  => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 正常の場合
        ELSE
          -- 正常データ件数
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- 正常データダンプPL/SQL表投入
          normal_dump_tab(gn_normal_cnt) := lr_upd_data.data_dump;
        END IF;
--
      EXCEPTION
        WHEN skip_expt THEN  -- 警告発生時、スキップして次レコードの処理を行う。
          -- OUTパラメータを警告にセット
          ov_retcode := gv_status_warn;
          -- スキップ件数カウント
          gn_warn_cnt   := gn_warn_cnt + 1;
      END;
--
    END LOOP upd_data_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END upd_data_loop;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
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
    ln_request_count NUMBER;    -- 要求IDカウント
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
    -- H-1.関連データ取得処理
    -- ===============================
    init_proc(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- H-2.要求ID取得処理
    -- ===============================
    get_request_id(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- H-3.ロック取得処理
    -- ===============================
    get_lock(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 取得した要求ID分だけLOOP
    -- ===============================
    <<request_id_loop>>
    FOR ln_count IN 1..request_id_tab.COUNT
    LOOP
      -- 変数初期化
      -- 登録用・更新用PL/SQL表カウント
      gn_ins_tab_cnt := 0;
      gn_upd_tab_cnt := 0;
--
      -- 登録用PL/SQL表
      pk_id_tab.DELETE;       -- 倉庫品目ID
      item_location_id_ins_tab.DELETE;       -- 元倉庫ID
      item_location_code_ins_tab.DELETE;     -- 元倉庫コード
      item_id_ins_tab.DELETE;                -- 品目ID
      item_code_ins_tab.DELETE;              -- 品目コード
      frq_item_location_id_ins_tab.DELETE;   -- 代表倉庫ID
      frq_item_location_code_ins_tab.DELETE; -- 代表倉庫コード
--
      -- 更新用PL/SQL表
      item_location_code_upd_tab.DELETE;     -- 元倉庫コード
      item_code_upd_tab.DELETE;              -- 品目コード
      frq_item_location_id_upd_tab.DELETE;   -- 代表倉庫ID
      frq_item_location_code_upd_tab.DELETE; -- 代表倉庫コード
--
      -- ===============================
      -- H-4.重複データ除外処理
      -- ===============================
      del_duplication_data(
        it_request_id => request_id_tab(ln_count)    -- 1.要求ID
       ,ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- 警告の場合
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ===============================
      -- H-5.登録データ取得処理
      -- ===============================
      ins_data_loop(
        it_request_id => request_id_tab(ln_count)    -- 1.要求ID
       ,ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- 警告の場合
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ===============================
      -- H-6.更新データ取得処理
      -- ===============================
      upd_data_loop(
        it_request_id => request_id_tab(ln_count)    -- 1.要求ID
       ,ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- 警告の場合
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ===============================
      -- H-11.一括登録処理
      -- ===============================
      ins_data(
        ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- H-12.一括更新処理
      -- ===============================
      upd_data(
        ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP request_id_loop;
--
    -- ===============================
    -- H-13.データ削除処理
    -- ===============================
    del_data(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- H-14.データダンプ一括出力処理
    -- ===============================
    put_dump_msg(
      ov_errbuf     => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;

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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    -- H-15.リターン・コードのセット、終了処理
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
END xxwsh920006c;
/
