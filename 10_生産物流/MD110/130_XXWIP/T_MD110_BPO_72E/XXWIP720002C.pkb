CREATE OR REPLACE PACKAGE BODY xxwip720002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip720002c(body)
 * Description      : 運賃アドオンマスタ取込処理
 * MD.050           : 運賃計算（マスタ） T_MD050_BPO_720
 * MD.070           : 運賃アドオンマスタ取込処理（72E）T_MD070_BPO_72E
 * Version          : 1.3
 *
 * Program List
 * ------------------------ ----------------------------------------------------------
 *  Name                     Description
 * ------------------------ ----------------------------------------------------------
 *  get_lock                 表ロック取得処理(E-2) 
 *  del_duplication_data     重複データ除外処理(E-3)
 *  get_data_dump            データダンプ取得処理
 *  master_data_chk          マスタデータチェック処理(E-5)
 *  set_ins_tab              登録用PL/SQL表投入(E-6)
 *  get_ins_data             新規登録データ取得処理(E-4)
 *  set_upd_tab              更新用PL/SQL表投入(E-8)
 *  get_upd_data             更新データ取得処理(E-7)
 *  ins_table_batch          一括登録処理(E-9)
 *  upd_table_batch          一括更新処理(E-10)
 *  upd_end_date_active_all  適用終了日更新処理(E-11)
 *  del_table_data           データ削除処理(E-12)
 *  put_dump_msg             データダンプ一括出力処理
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/09    1.0   Y.Kanami         新規作成
 *  2008/11/11    1.1   N.Fukuda         統合指摘#589対応
 *  2009/04/03    1.2   A.Shiina         本番#432対応
 *  2016/06/22    1.3   S.Niki           E_本稼動_13659対応
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
  lock_expt                 EXCEPTION;     -- ロック取得例外
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxwip720002c';     -- パッケージ名
--
  -- モジュール名略称
  gv_xxcmn            CONSTANT VARCHAR2(100) := 'XXCMN';            -- モジュール名略称：XXCMN 共通
  gv_xxwip            CONSTANT VARCHAR2(100) := 'XXWIP';            
                                                -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
--
  -- メッセージ
  gv_msg_xxwip10004   CONSTANT VARCHAR2(100) := 'APP-XXWIP-10004';  
                                        -- メッセージ：APP-XXWIP-10004 ロックエラー詳細メッセージ
  gv_msg_xxwip10023   CONSTANT VARCHAR2(100) := 'APP-XXWIP-10023';  
                                        -- メッセージ：APP-XXWIP-10023 データ重複エラーメッセージ
  gv_msg_xxcmn10001   CONSTANT VARCHAR2(100) := 'APP-XXCMN-10001';  
                                        -- メッセージ：APP-XXCMN-10001 対象データなし
  gv_msg_xxcmn10002   CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  
                                        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
  gv_msg_xxcmn00005   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005';  
                                        -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
  gv_msg_xxcmn00007   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00007';  
                                        -- メッセージ：APP-XXCMN-00007 スキップデータ（見出し）
--
  -- トークン
  gv_tkn_table        CONSTANT VARCHAR2(100) := 'TABLE';            -- トークン：TABLE
  gv_tkn_item         CONSTANT VARCHAR2(100) := 'ITEM';             -- トークン：ITEM
  gv_tkn_key          CONSTANT VARCHAR2(100) := 'KEY';              -- トークン：KEY
  gv_tkn_ng_profile   CONSTANT VARCHAR2(100) := 'NG_PROFILE';       -- トークン：NG_PROFILE
--
-- 2009/04/03 v1.2 ADD START
  gv_on               CONSTANT VARCHAR2(1) := '1';                  -- 変更フラグ：変更あり
--
-- 2009/04/03 v1.2 ADD END
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 要求ID用PL/SQL表型
  TYPE request_id_ttype              IS TABLE OF fnd_concurrent_requests.request_id%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 要求ID
--
  -- 登録・更新用PL/SQL表型
  TYPE delivery_charges_id_ttype     IS TABLE OF xxwip_delivery_charges.delivery_charges_id%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 運賃マスタID
  TYPE p_b_classe_ttype              IS TABLE OF xxwip_delivery_charges.p_b_classe%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 支払請求区分
  TYPE goods_classe_ttype            IS TABLE OF xxwip_delivery_charges.goods_classe%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 商品区分
  TYPE delivery_company_code_ttype   IS TABLE OF xxwip_delivery_charges.delivery_company_code%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 運送業者
  TYPE shipping_address_classe_ttype IS TABLE OF xxwip_delivery_charges.shipping_address_classe%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 配送区分
  TYPE delivery_distance_ttype       IS TABLE OF xxwip_delivery_charges.delivery_distance%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 運賃距離
  TYPE delivery_weight_ttype         IS TABLE OF xxwip_delivery_charges.delivery_weight%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 重量
  TYPE start_date_active_ttype       IS TABLE OF xxwip_delivery_charges.start_date_active%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 適用開始日
  TYPE end_date_active_ttype         IS TABLE OF xxwip_delivery_charges.end_date_active%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 適用終了日
  TYPE shipping_expenses_ttype       IS TABLE OF xxwip_delivery_charges.shipping_expenses%TYPE
                                        INDEX BY BINARY_INTEGER;  -- 運送費
  TYPE leaf_consolid_add_ttype       IS TABLE OF xxwip_delivery_charges.leaf_consolid_add%TYPE
                                        INDEX BY BINARY_INTEGER;  -- リーフ混載割増
--
  -- メッセージPL/SQL表型
  TYPE msg_ttype                      IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 要求ID用PL/SQL表
  request_id_tab                    request_id_ttype;               -- 要求ID
--
  -- 登録用PL/SQL表
  delivery_charges_id_ins_tab       delivery_charges_id_ttype;      -- 運賃マスタID
  p_b_classe_ins_tab                p_b_classe_ttype;               -- 支払請求区分
  goods_classe_ins_tab              goods_classe_ttype;             -- 商品区分
  delivery_company_code_ins_tab     delivery_company_code_ttype;    -- 運送業者
  ship_address_classe_ins_tab       shipping_address_classe_ttype;  -- 配送区分
  delivery_distance_ins_tab         delivery_distance_ttype;        -- 運賃距離
  delivery_weight_ins_tab           delivery_weight_ttype;          -- 重量
  start_date_active_ins_tab         start_date_active_ttype;        -- 適用開始日
  end_date_active_ins_tab           end_date_active_ttype;          -- 適用終了日
  shipping_expenses_ins_tab         shipping_expenses_ttype;        -- 運送費
  leaf_consolid_add_ins_tab         leaf_consolid_add_ttype;        -- リーフ混載割増
--
  -- 更新用PL/SQL表
  delivery_charges_id_upd_tab       delivery_charges_id_ttype;      -- 運賃マスタID
  p_b_classe_upd_tab                p_b_classe_ttype;               -- 支払請求区分
  goods_classe_upd_tab              goods_classe_ttype;             -- 商品区分
  delivery_company_code_upd_tab     delivery_company_code_ttype;    -- 運送業者
  ship_address_classe_upd_tab       shipping_address_classe_ttype;  -- 配送区分
  delivery_distance_upd_tab         delivery_distance_ttype;        -- 運賃距離
  delivery_weight_upd_tab           delivery_weight_ttype;          -- 重量
  start_date_active_upd_tab         start_date_active_ttype;        -- 適用開始日
  end_date_active_upd_tab           end_date_active_ttype;          -- 適用終了日
  shipping_expenses_upd_tab         shipping_expenses_ttype;        -- 運送費
  leaf_consolid_add_upd_tab         leaf_consolid_add_ttype;        -- リーフ混載割増
--
  -- データダンプ用PL/SQL表
  warn_dump_tab                     msg_ttype;                      -- 警告データダンプ
  normal_dump_tab                   msg_ttype;                      -- 正常データダンプ
--
  -- カウンタ
  gn_request_id_cnt   NUMBER := 0;   -- 要求IDカウント
  gn_ins_tab_cnt      NUMBER := 0;   -- 登録用PL/SQL表カウント
  gn_upd_tab_cnt      NUMBER := 0;   -- 更新用PL/SQL表カウント
  gn_err_msg_cnt      NUMBER := 0;   -- 警告エラーメッセージ表カウント
--
-- v1.3 ADD START
  gv_prod_div         VARCHAR2(1);   -- 商品区分
-- v1.3 ADD END
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : 表ロック取得処理(E-2)
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
    cv_xxwip_delivery_charges     CONSTANT VARCHAR2(40) := '運賃アドオンマスタ';
    cv_xxwip_delivery_charges_if  CONSTANT VARCHAR2(40) := '運賃アドオンマスタインタフェース';
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- 運賃アドオンマスタインタフェースロックカーソル
    CURSOR xxwip_delivery_charges_if_cur(lt_request_id xxwip_delivery_charges_if.request_id%TYPE)
    IS
      SELECT /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */            -- 2008/11/11 統合指摘#589 Add
             xdci.delivery_charges_if_id        -- 運賃アドオンマスタインタフェースID
      FROM   xxwip_delivery_charges_if    xdci  -- 運賃アドオンマスタインタフェース
      WHERE  xdci.request_id = lt_request_id    -- 要求ID
      FOR UPDATE NOWAIT
    ;
--
    -- 運賃アドオンマスタロックカーソル
    CURSOR xxwip_delivery_charges_cur
    IS
      SELECT xdc.delivery_charges_id            -- 運賃アドオンマスタID
      FROM   xxwip_delivery_charges    xdc      -- 運賃アドオンマスタ
      FOR UPDATE NOWAIT
    ;
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
    -- ==============================
    -- ロック取得
    -- ==============================
    -- 運賃アドオンマスタインタフェースのロックを取得
    BEGIN
      <<request_id_loop>>
      FOR req_id_cnt IN 1..request_id_tab.COUNT LOOP
        <<xdci_lock_loop>>
        FOR xdc_cnt IN xxwip_delivery_charges_if_cur(request_id_tab(req_id_cnt)) LOOP
          EXIT;
        END LOOP xdci_lock_loop;
      END LOOP request_id_loop;
--    
    EXCEPTION
      --*** ロック取得エラー ***
      WHEN lock_expt THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip          -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10004 -- メッセージ：APP-XXWIP-10004 ロックエラー詳細メッセージ
                     ,gv_tkn_table      -- トークンTABLE
                     ,cv_xxwip_delivery_charges_if  -- テーブル名：運賃アドオンマスタインタフェース
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- 運賃アドオンマスタのロックを取得
    BEGIN
      <<xdc_lock_loop>>
      FOR loop_cnt IN xxwip_delivery_charges_cur LOOP
        EXIT;
      END LOOP xdc_lock_loop;
--
    EXCEPTION
      --*** ロック取得エラー ***
      WHEN lock_expt THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip          -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10004 -- メッセージ：APP-XXWIP-10004 ロックエラー詳細メッセージ
                     ,gv_tkn_table      -- トークンTABLE
                     ,cv_xxwip_delivery_charges     -- テーブル名：運賃アドオンマスタ
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (xxwip_delivery_charges_if_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_if_cur;
      END IF;
      IF (xxwip_delivery_charges_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xxwip_delivery_charges_if_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_if_cur;
      END IF;
      IF (xxwip_delivery_charges_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xxwip_delivery_charges_if_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_if_cur;
      END IF;
      IF (xxwip_delivery_charges_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_charges_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   : get_data_dump
   * Description      : データダンプ取得処理
   ***********************************************************************************/
  PROCEDURE get_data_dump(
    ir_xxwip_delivery_charges_if  IN  xxwip_delivery_charges_if%ROWTYPE,  
                                                  -- 1.運賃アドオンマスタI/Fレコード型
    ov_dump                       OUT VARCHAR2,   -- データダンプ文字列
    ov_errbuf                     OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode                    OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg                     OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data_dump'; -- プログラム名
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
    -- データダンプ作成
    -- ===============================
    ov_dump :=  ir_xxwip_delivery_charges_if.p_b_classe                 -- 支払請求区分
                || gv_msg_comma ||  
                ir_xxwip_delivery_charges_if.goods_classe               -- 商品区分
                || gv_msg_comma ||
                ir_xxwip_delivery_charges_if.delivery_company_code      -- 運送業者
                || gv_msg_comma ||
                ir_xxwip_delivery_charges_if.shipping_address_classe    -- 配送区分
                || gv_msg_comma ||
                TO_CHAR(ir_xxwip_delivery_charges_if.delivery_distance) -- 運賃距離
                || gv_msg_comma ||
                TO_CHAR(ir_xxwip_delivery_charges_if.delivery_weight)   -- 重量
                || gv_msg_comma ||
                TO_CHAR(ir_xxwip_delivery_charges_if.start_date_active, 'YYYY/MM/DD')  -- 適用開始日
                || gv_msg_comma ||
                TO_CHAR(ir_xxwip_delivery_charges_if.shipping_expenses) -- 運送費
                || gv_msg_comma ||
                TO_CHAR(ir_xxwip_delivery_charges_if.leaf_consolid_add) -- リーフ混載割増
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
  END get_data_dump;
--
  /**********************************************************************************
   * Procedure Name   : del_duplication_data
   * Description      : 重複データ除外処理（E-3）
   ***********************************************************************************/
  PROCEDURE del_duplication_data(
    it_request_id IN  xxwip_delivery_distance_if.request_id%TYPE,     -- 1.要求ID
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
    lr_xdci_if_data xxwip_delivery_charges_if%ROWTYPE;  -- 重複レコード
    lv_dump         VARCHAR2(5000);                     -- データダンプ
    lv_warn_msg     VARCHAR2(5000);                     -- 警告メッセージ
--
    -- *** ローカル・カーソル ***
    -- 重複データ取得カーソル
    CURSOR xdci_duplication_chk_cur IS
      SELECT /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */                  -- 2008/11/11 統合指摘#589 Add
          COUNT(xdci.delivery_charges_if_id) cnt  -- データカウント
        , xdci.p_b_classe                         -- 支払請求区分
        , xdci.goods_classe                       -- 商品区分
        , xdci.delivery_company_code              -- 運送業者
        , xdci.shipping_address_classe            -- 配送区分
        , xdci.delivery_distance                  -- 運賃距離
        , xdci.delivery_weight                    -- 重量
        , xdci.start_date_active                  -- 適用開始日
      FROM  xxwip_delivery_charges_if xdci        -- 運賃アドオンマスタインタフェース
      WHERE xdci.request_id   = it_request_id     -- 要求ID
-- v1.3 ADD START
        AND xdci.goods_classe = gv_prod_div       -- 商品区分
-- v1.3 ADD END
      GROUP BY 
          xdci.p_b_classe                         -- 支払請求区分
        , xdci.goods_classe                       -- 商品区分
        , xdci.delivery_company_code              -- 運送業者
        , xdci.shipping_address_classe            -- 配送区分
        , xdci.delivery_distance                  -- 運賃距離
        , xdci.delivery_weight                    -- 重量
        , xdci.start_date_active                  -- 適用開始日
      ;
--
    -- エラーデータカーソル
    CURSOR xdci_err_data_cur(
        lt_p_b_classe         xxwip_delivery_charges_if.p_b_classe%TYPE             -- 支払請求区分
      , lt_goods_classe       xxwip_delivery_charges_if.goods_classe%TYPE           -- 商品区分
      , lt_deli_company_code  xxwip_delivery_charges_if.delivery_company_code%TYPE  -- 運送業者
      , lt_ship_address_cls   xxwip_delivery_charges_if.shipping_address_classe%TYPE  -- 配送区分
      , lt_delivery_distance  xxwip_delivery_charges_if.delivery_distance%TYPE      -- 運賃距離
      , lt_delivery_weight    xxwip_delivery_charges_if.delivery_weight%TYPE        -- 重量
      , lt_start_date_active  xxwip_delivery_charges_if.start_date_active%TYPE      -- 適用開始日
      ) 
    IS
      SELECT  /*+ INDEX( xdci xxwip_deli_char_if_n02 ) */                 -- 2008/11/11 統合指摘#589 Add
              xdci.delivery_charges_if_id   delivery_charges_if_id        -- 運賃マスタID
          ,   xdci.p_b_classe               p_b_classe                    -- 支払請求区分
          ,   xdci.goods_classe             goods_classe                  -- 商品区分
          ,   xdci.delivery_company_code    delivery_company_code         -- 運送業者
          ,   xdci.shipping_address_classe  shipping_address_classe       -- 配送区分
          ,   xdci.delivery_distance        delivery_distance             -- 運賃距離
          ,   xdci.delivery_weight          delivery_weight               -- 重量
          ,   xdci.start_date_active        start_date_active             -- 適用開始日
          ,   xdci.shipping_expenses        shipping_expenses             -- 運送費
          ,   xdci.leaf_consolid_add        leaf_consolid_add             -- リーフ混載割増
      FROM    xxwip_delivery_charges_if     xdci                -- 運賃アドオンマスタインタフェース
      WHERE   xdci.p_b_classe               = lt_p_b_classe               -- 支払請求区分
        AND   xdci.goods_classe             = lt_goods_classe             -- 商品区分
        AND   xdci.delivery_company_code    = lt_deli_company_code        -- 運送業者
        AND   xdci.shipping_address_classe  = lt_ship_address_cls         -- 配送区分
        AND   xdci.delivery_distance        = lt_delivery_distance        -- 運賃距離
        AND   xdci.delivery_weight          = lt_delivery_weight          -- 重量
        AND   xdci.start_date_active        = lt_start_date_active        -- 適用開始日
      ORDER BY delivery_charges_if_id
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
    -- 重複チェックカーソル
    -- ===============================
    << xdci_dupl_chk_loop >>
    FOR xdci_dupl_chk IN xdci_duplication_chk_cur LOOP
      -- カウント2件以上はデータが重複している
      IF (xdci_dupl_chk.cnt > 1) THEN
        -- ===============================
        -- エラーデータカーソル
        -- ===============================
        <<xdci_err_data_loop>>
        FOR xdci_err_data IN xdci_err_data_cur(
              xdci_dupl_chk.p_b_classe              -- 支払請求区分
            , xdci_dupl_chk.goods_classe            -- 商品区分
            , xdci_dupl_chk.delivery_company_code   -- 運送業者
            , xdci_dupl_chk.shipping_address_classe -- 配送区分
            , xdci_dupl_chk.delivery_distance       -- 運賃距離
            , xdci_dupl_chk.delivery_weight         -- 重量
            , xdci_dupl_chk.start_date_active       -- 適用開始日
        ) LOOP
--
          -- 重複データをレコードにセット
          lr_xdci_if_data.p_b_classe              := xdci_err_data.p_b_classe;
                                                      -- 支払請求区分
          lr_xdci_if_data.goods_classe            := xdci_err_data.goods_classe;
                                                      -- 商品区分
          lr_xdci_if_data.delivery_company_code   := xdci_err_data.delivery_company_code;
                                                      -- 運送業者
          lr_xdci_if_data.shipping_address_classe := xdci_err_data.shipping_address_classe;
                                                      -- 配送区分
          lr_xdci_if_data.delivery_distance       := xdci_err_data.delivery_distance;
                                                      -- 運賃距離
          lr_xdci_if_data.delivery_weight         := xdci_err_data.delivery_weight;         
                                                      -- 重量
          lr_xdci_if_data.start_date_active       := xdci_err_data.start_date_active;
                                                      -- 適用開始日
          lr_xdci_if_data.shipping_expenses       := xdci_err_data.shipping_expenses;
                                                      -- 運送費
          lr_xdci_if_data.leaf_consolid_add       := xdci_err_data.leaf_consolid_add;
                                                      -- リーフ混載割増
--
          -- ===============================
          -- データダンプ取得処理
          -- ===============================
          get_data_dump(
              ir_xxwip_delivery_charges_if => lr_xdci_if_data -- 1.重複データレコード
            , ov_dump    => lv_dump       -- データダンプ文字列
            , ov_errbuf  => lv_errbuf     -- エラー・メッセージ           --# 固定 #
            , ov_retcode => lv_retcode    -- リターン・コード             --# 固定 #
            , ov_errmsg  => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
          );
--          
          -- データダンプ取得処理がエラーの場合
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- ===============================
          -- 警告エラーメッセージ取得
          -- ===============================
          -- エラーメッセージ取得
          lv_warn_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                          gv_xxwip     -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                        , gv_msg_xxwip10023 
                                       -- メッセージ：APP-XXWIP-10023 データ重複エラーメッセージ
                        , gv_tkn_item  -- トークンitem
                        , cv_item      -- item名
                        ),1,5000);
--
          -- ===============================
          -- 警告データダンプPL/SQL表投入
          -- ===============================
          -- データダンプを警告データダンプPL/SQL表にセット
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_dump;
--
          -- 警告メッセージを警告データダンプPL/SQL表にセット
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_warn_msg;
--
          -- スキップ件数カウント
          gn_warn_cnt   := gn_warn_cnt + 1;
--
        END LOOP xdci_err_data_loop;
--
        -- ===============================
        -- エラーデータ削除
        -- ===============================
        DELETE /*+ INDEX( xdci xxwip_deli_char_if_n02 ) */                            -- 2008/11/11 統合指摘#589 Add
        FROM xxwip_delivery_charges_if xdci  -- 運賃アドオンインタフェース
        WHERE   xdci.p_b_classe               = xdci_dupl_chk.p_b_classe              -- 支払請求区分
          AND   xdci.goods_classe             = xdci_dupl_chk.goods_classe            -- 商品区分
          AND   xdci.delivery_company_code    = xdci_dupl_chk.delivery_company_code   -- 運送業者
          AND   xdci.shipping_address_classe  = xdci_dupl_chk.shipping_address_classe -- 配送区分
          AND   xdci.delivery_distance        = xdci_dupl_chk.delivery_distance       -- 運賃距離
          AND   xdci.delivery_weight          = xdci_dupl_chk.delivery_weight         -- 重量
          AND   xdci.start_date_active        = xdci_dupl_chk.start_date_active       -- 適用開始日
        ;
--
       -- ===============================
       --  OUTパラメータセット
       -- ===============================
       ov_retcode := gv_status_warn;
--
      END IF;
--
    END LOOP xdci_dupl_chk_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (xdci_duplication_chk_cur%ISOPEN) THEN
        CLOSE xdci_duplication_chk_cur;
      END IF;
      IF (xdci_err_data_cur%ISOPEN) THEN
        CLOSE xdci_err_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xdci_duplication_chk_cur%ISOPEN) THEN
        CLOSE xdci_duplication_chk_cur;
      END IF;
      IF (xdci_err_data_cur%ISOPEN) THEN
        CLOSE xdci_err_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xdci_duplication_chk_cur%ISOPEN) THEN
        CLOSE xdci_duplication_chk_cur;
      END IF;
      IF (xdci_err_data_cur%ISOPEN) THEN
        CLOSE xdci_err_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_duplication_data;
--
  /**********************************************************************************
   * Procedure Name   : master_data_chk
   * Description      : マスタデータチェック処理(E-5)
   ***********************************************************************************/
  PROCEDURE master_data_chk(
    ir_xxwip_delivery_charges_if  IN  xxwip_delivery_charges_if%ROWTYPE,
                                  -- 1.運賃アドオンマスタI/Fレコード
    iv_dump       IN  VARCHAR2,   -- データダンプ
    ov_errbuf     OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'master_data_chk'; -- プログラム名
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
    -- エラーキー項目
    cv_category_set             CONSTANT VARCHAR2(50) :=  'カテゴリセット名';
                                -- エラーキー項目：カテゴリセット名
    cv_category_set_name        CONSTANT VARCHAR2(50) :=  '商品区分';
                                -- エラーキー項目：商品区分
    cv_lookup_type              CONSTANT VARCHAR2(50) :=  'クイックコードタイプ';
                                -- エラーキー項目：クイックコードタイプ
    cv_lookup_code              CONSTANT VARCHAR2(50) :=  'クイックコード';
                                -- エラーキー項目：クイックコード
    cv_delivery_company_code    CONSTANT VARCHAR2(50) :=  '運送業者コード';
                                -- エラーキー項目：運送業者コード
--
    -- クイックコード
    cv_p_b_classe_type          CONSTANT VARCHAR2(50) :=  'XXWIP_PAYCHARGE_TYPE';
                                -- クイックコードタイプ：支払請求区分
    cv_p_b_classe_type_name     CONSTANT VARCHAR2(50) :=  'XXWIP.支払請求区分';
                                -- クイックコードタイプ：支払請求区分
    cv_ship_address_cls_type    CONSTANT VARCHAR2(50) :=  'XXCMN_SHIP_METHOD';
                                -- クイックコードタイプ：配送区分
    cv_ship_addr_cls_type_name  CONSTANT VARCHAR2(50) :=  'XXWIP.配送区分';
                                -- クイックコードタイプ：配送区分
--
    -- エラーテーブル
    cv_xxcmn_categories_v       CONSTANT VARCHAR2(50) :=  '品目カテゴリ情報VIEW';
    cv_xxcmn_lookup_values_v    CONSTANT VARCHAR2(50) :=  'クイックコード情報VIEW';
    cv_xxwip_delivery_company   CONSTANT VARCHAR2(50) :=  '運送用運送業者アドオンマスタ';
--
    -- *** ローカル変数 ***
    lv_err_tbl                  VARCHAR2(50);   -- エラーテーブル名
    lv_err_key                  VARCHAR2(2000); -- エラーキー項目
    ln_exist_chk                NUMBER;         -- 存在チェックカウント
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    
    -- *** サブプログラム ***
    -- ===============================
    -- 警告エラーメッセージ表投入
    -- ===============================
    PROCEDURE set_err_msg
    IS
    BEGIN
      -- 警告データダンプPL/SQL表投入
      -- 1件目の警告の場合のみ、ダンプを投入
      IF (lv_retcode = gv_status_normal) THEN
        gn_err_msg_cnt := gn_err_msg_cnt + 1;
        warn_dump_tab(gn_err_msg_cnt) := iv_dump;
      END IF;
--
      -- 警告メッセージを投入
      gn_err_msg_cnt := gn_err_msg_cnt + 1;
      warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--
      -- 警告にセット
      lv_retcode := gv_status_warn;
--
    END set_err_msg;
--
    -- ===============================
    -- 対象データなしメッセージ取得
    -- ===============================
    PROCEDURE get_no_data_msg
    IS
    BEGIN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn               -- モジュール名略称：XXCMN 共通
                   ,gv_msg_xxcmn10001      -- メッセージ：APP-XXCMN-10001 対象データなし
                   ,gv_tkn_table           -- トークン：TABLE
                   ,lv_err_tbl             -- エラーテーブル名
                   ,gv_tkn_key             -- トークン：KEY
                   ,lv_err_key             -- エラーキー項目
                  ),1,5000);
--
      -- 警告エラーメッセージ表投入
      set_err_msg;
    END;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    lv_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 支払請求区分チェック
    -- ===============================
    SELECT  COUNT(xlvv.lookup_code)  -- ルックアップコード
    INTO    ln_exist_chk
    FROM    xxcmn_lookup_values_v xlvv                -- クイックコード情報VIEW
    WHERE   xlvv.lookup_type  = cv_p_b_classe_type    -- クイックコードタイプ：支払請求区分
      AND   xlvv.lookup_code  = ir_xxwip_delivery_charges_if.p_b_classe   -- 支払請求区分
      AND   xlvv.start_date_active  <= TRUNC(SYSDATE)   -- 適用開始日
      AND  (xlvv.end_date_active    IS NULL
            OR xlvv.end_date_active >= TRUNC(SYSDATE))  -- 適用終了日
      AND   ROWNUM = 1
    ;
--
    IF (ln_exist_chk = 0) THEN
      -- エラーテーブル名、エラーキー項目セット
      lv_err_tbl := cv_xxcmn_lookup_values_v;   -- エラーテーブル名：クイックコード情報VIEW
      lv_err_key := cv_lookup_type          ||  -- エラーキー項目：クイックコードタイプ
                    gv_msg_part             ||  -- 区切り文字
                    cv_p_b_classe_type_name ||  -- クイックコード：支払請求区分
                    gv_msg_comma            ||  -- 区切り文字
                    cv_lookup_code          ||  -- エラーキー項目：クイックコード
                    gv_msg_part             ||  -- 区切り文字
                    ir_xxwip_delivery_charges_if.p_b_classe;
--
      -- 対象データなしメッセージ取得
      get_no_data_msg;
    END IF;
--
    -- ===============================
    -- 商品区分チェック
    -- ===============================
    -- 品目カテゴリ情報VIEWをチェック
    SELECT  COUNT(xcv.category_set_id)
    INTO    ln_exist_chk
    FROM    xxcmn_categories_v xcv  -- 品目カテゴリ情報VIEW
    WHERE   xcv.category_set_name = cv_category_set_name                        -- カテゴリセット名
    AND     xcv.segment1          = ir_xxwip_delivery_charges_if.goods_classe   -- 商品区分
    AND     ROWNUM = 1
      ;
    IF (ln_exist_chk = 0) THEN
         -- エラーテーブル名、エラーキー項目セット
        lv_err_tbl := cv_xxcmn_categories_v;    -- エラーテーブル名：品目カテゴリ情報VIEW
        lv_err_key := cv_category_set_name  ||  -- エラーキー項目：商品区分
                      gv_msg_part           ||  -- 区切り文字
                      ir_xxwip_delivery_charges_if.goods_classe;
--
        -- 対象データなしメッセージ取得
        get_no_data_msg;
    ELSE
      -- 商品区分チェックが正常の場合
      -- ===============================
      -- 運送業者チェック
      -- ===============================
      SELECT  COUNT(xdc.delivery_company_id)  -- 運送業者
      INTO    ln_exist_chk
      FROM    xxwip_delivery_company xdc  -- 運賃用運送業者マスタ
      WHERE   xdc.goods_classe          = ir_xxwip_delivery_charges_if.goods_classe
                                                                    -- 商品区分
        AND   xdc.delivery_company_code = ir_xxwip_delivery_charges_if.delivery_company_code
                                                                    -- 運送業者
        AND   xdc.start_date_active    <= TRUNC(SYSDATE)            -- 適用開始日
        AND   xdc.end_date_active      >= TRUNC(SYSDATE)            -- 適用終了日
        AND   ROWNUM = 1
      ;
      IF (ln_exist_chk = 0) THEN
        -- エラーテーブル名、エラーキー項目セット
        lv_err_tbl := cv_xxwip_delivery_company; -- エラーテーブル名：運送用運送業者アドオンマスタ
        lv_err_key := cv_delivery_company_code     || -- エラーキー項目：運送業者コード
                      gv_msg_part                  || -- 区切り文字
                      ir_xxwip_delivery_charges_if.delivery_company_code;
--
        -- 対象データなしメッセージ取得
        get_no_data_msg;
      END IF;
--
    END IF;
--
    -- ===============================
    -- 配送区分チェック
    -- ===============================
    SELECT  COUNT(xlvv.lookup_code)
    INTO    ln_exist_chk
    FROM    xxcmn_lookup_values_v xlvv                    -- クイックコード情報VIEW
    WHERE   xlvv.lookup_type  = cv_ship_address_cls_type  -- クイックコードタイプ：配送区分
      AND   xlvv.lookup_code  = ir_xxwip_delivery_charges_if.shipping_address_classe -- 配送区分
      AND   xlvv.start_date_active  <= TRUNC(SYSDATE)   -- 適用開始日
      AND  (xlvv.end_date_active    IS NULL
            OR xlvv.end_date_active >= TRUNC(SYSDATE))  -- 適用終了日
      AND   ROWNUM = 1
    ;
    IF (ln_exist_chk = 0) THEN
       -- エラーテーブル名、エラーキー項目セット
      lv_err_tbl := cv_xxcmn_lookup_values_v; -- エラーテーブル名：クイックコード情報VIEW
      lv_err_key := cv_lookup_type              ||  -- エラーキー項目：クイックコードタイプ
                    gv_msg_part                 ||  -- 区切り文字
                    cv_ship_addr_cls_type_name  ||  -- クイックコード：配送区分
                    gv_msg_comma                ||  -- 区切り文字
                    cv_lookup_code              ||  -- エラーキー項目：クイックコード
                    gv_msg_part                 ||
                    ir_xxwip_delivery_charges_if.shipping_address_classe;
--
      -- 対象データなしメッセージ取得
      get_no_data_msg;
    END IF;
--
    -- ===============================
    -- OUTパラメータセット
    -- ===============================
    ov_retcode := lv_retcode;
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
  END master_data_chk;
--
  /**********************************************************************************
   * Procedure Name   : set_ins_tab
   * Description      : 登録用PL/SQL表投入(E-6)
   ***********************************************************************************/
  PROCEDURE set_ins_tab(
    ir_xxwip_delivery_charges_if  IN  xxwip_delivery_charges_if%ROWTYPE,  
                                                    -- 1.運賃アドオンマスタI/Fレコード型
    ov_errbuf                     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- 値セット
    SELECT xxwip_delivery_charges_id_s1.NEXTVAL       -- 運賃マスタID
    INTO   delivery_charges_id_ins_tab(gn_ins_tab_cnt)
    FROM   dual;
    p_b_classe_ins_tab(gn_ins_tab_cnt)              
        :=  ir_xxwip_delivery_charges_if.p_b_classe;              -- 支払請求区分
    goods_classe_ins_tab(gn_ins_tab_cnt)            
        :=  ir_xxwip_delivery_charges_if.goods_classe;            -- 商品区分
    delivery_company_code_ins_tab(gn_ins_tab_cnt)   
        :=  ir_xxwip_delivery_charges_if.delivery_company_code;   -- 運送業者
    ship_address_classe_ins_tab(gn_ins_tab_cnt)    
        :=  ir_xxwip_delivery_charges_if.shipping_address_classe; -- 配送区分
    delivery_distance_ins_tab(gn_ins_tab_cnt)       
        :=  ir_xxwip_delivery_charges_if.delivery_distance;       -- 運賃距離
    delivery_weight_ins_tab(gn_ins_tab_cnt)         
        :=  ir_xxwip_delivery_charges_if.delivery_weight;         -- 重量
    start_date_active_ins_tab(gn_ins_tab_cnt)       
        :=  ir_xxwip_delivery_charges_if.start_date_active;       -- 適用開始日
    shipping_expenses_ins_tab(gn_ins_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.shipping_expenses;       -- 運送費
    leaf_consolid_add_ins_tab(gn_ins_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.leaf_consolid_add;       -- リーフ混載割増
--
  EXCEPTION
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
   * Description      : 更新用PL/SQL表投入(E-8)
   ***********************************************************************************/
  PROCEDURE set_upd_tab(
    ir_xxwip_delivery_charges_if  IN  xxwip_delivery_charges_if%ROWTYPE,
                                                  -- 1.運賃アドオンマスタI/Fレコード型
    ov_errbuf                     OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode                    OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg                     OUT VARCHAR2    --   ユーザー・エラー・メッセージ --# 固定 #
  )IS
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
    -- 更新用件数カウント
    gn_upd_tab_cnt := gn_upd_tab_cnt + 1;
--
    -- 値セット
    p_b_classe_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.p_b_classe;              -- 支払請求区分
    goods_classe_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.goods_classe;            -- 商品区分
    delivery_company_code_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.delivery_company_code;   -- 運送業者
    ship_address_classe_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.shipping_address_classe; -- 配送区分
    delivery_distance_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.delivery_distance;       -- 運賃距離
    delivery_weight_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.delivery_weight;         -- 重量
    start_date_active_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.start_date_active;       -- 適用開始日
    shipping_expenses_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.shipping_expenses;       -- 運送費
    leaf_consolid_add_upd_tab(gn_upd_tab_cnt)
        :=  ir_xxwip_delivery_charges_if.leaf_consolid_add;       -- リーフ混載割増
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

  /**********************************************************************************
   * Procedure Name   : get_ins_data
   * Description      : 新規登録データ取得処理(E-4)
   ***********************************************************************************/
  PROCEDURE get_ins_data(
    it_request_id IN  xxwip_delivery_charges_if.request_id%TYPE,  -- 1.要求ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ins_data'; -- プログラム名
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
    lr_xdci_if_data xxwip_delivery_charges_if%ROWTYPE;  -- 運賃アドオンマスタI/Fレコード型
    lv_dump         VARCHAR2(5000);                     -- データダンプ
--
    -- *** ローカル・カーソル ***
    -- 登録データ取得カーソル
    CURSOR get_ins_data_cur IS
      SELECT  /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */                 -- 2008/11/11 統合指摘#589 Add
              xdci.p_b_classe               -- 支払請求区分
            , xdci.goods_classe             -- 商品区分
            , xdci.delivery_company_code    -- 運送業者
            , xdci.shipping_address_classe  -- 配送区分
            , xdci.delivery_distance        -- 運賃距離
            , xdci.delivery_weight          -- 重量
            , xdci.start_date_active        -- 適用開始日
            , xdci.shipping_expenses        -- 運送費
            , xdci.leaf_consolid_add        -- リーフ混載割増
      FROM  xxwip_delivery_charges_if xdci  -- 運賃アドオンインタフェース
      WHERE xdci.request_id   = it_request_id  -- 要求ID
-- v1.3 ADD START
        AND xdci.goods_classe = gv_prod_div    -- 商品区分
-- v1.3 ADD END
        AND NOT EXISTS(
                  SELECT  'X'
                  FROM    xxwip_delivery_charges xdc                           -- 運賃アドオンマスタ
                  WHERE   xdc.p_b_classe              = xdci.p_b_classe               -- 支払請求区分
                    AND   xdc.goods_classe            = xdci.goods_classe             -- 商品区分
                    AND   xdc.delivery_company_code   = xdci.delivery_company_code    -- 運送業者
                    AND   xdc.shipping_address_classe = xdci.shipping_address_classe  -- 配送区分
                    AND   xdc.delivery_distance       = xdci.delivery_distance        -- 運賃距離
                    AND   xdc.delivery_weight         = xdci.delivery_weight          -- 重量
                    AND   xdc.start_date_active       = xdci.start_date_active        -- 適用開始日
            );        
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
    -- =============================
    -- 登録データ取得
    -- =============================
    <<xdci_ins_data_loop>>
    FOR xdci_ins_dat IN get_ins_data_cur LOOP
      -- 運賃アドオンマスタI/Fレコード型にデータをセットする
      lr_xdci_if_data.p_b_classe
          := xdci_ins_dat.p_b_classe;               -- 支払請求区分
      lr_xdci_if_data.goods_classe
          := xdci_ins_dat.goods_classe;             -- 商品区分
      lr_xdci_if_data.delivery_company_code
          := xdci_ins_dat.delivery_company_code;    -- 運送業者
      lr_xdci_if_data.shipping_address_classe
          := xdci_ins_dat.shipping_address_classe;  -- 配送区分
      lr_xdci_if_data.delivery_distance
          := xdci_ins_dat.delivery_distance;        -- 運賃距離
      lr_xdci_if_data.delivery_weight
          := xdci_ins_dat.delivery_weight;          -- 重量
      lr_xdci_if_data.start_date_active
          := xdci_ins_dat.start_date_active;        -- 適用開始日
      lr_xdci_if_data.shipping_expenses
          := xdci_ins_dat.shipping_expenses;        -- 運送費
      lr_xdci_if_data.leaf_consolid_add
          := xdci_ins_dat.leaf_consolid_add;        -- リーフ混載割増
--
      -- ===============================
      -- データダンプ取得処理
      -- ===============================
      get_data_dump(
          ir_xxwip_delivery_charges_if => lr_xdci_if_data -- 1.運賃アドオンマスタI/Fレコード型
        , ov_dump    => lv_dump       -- データダンプ文字列
        , ov_errbuf  => lv_errbuf     -- エラー・メッセージ           --# 固定 #
        , ov_retcode => lv_retcode    -- リターン・コード             --# 固定 #
        , ov_errmsg  => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- E-5.マスタデータチェック処理
      -- =============================
      master_data_chk(
          ir_xxwip_delivery_charges_if  =>  lr_xdci_if_data -- 1.運賃アドオンマスタI/Fレコード型
        , iv_dump                       =>  lv_dump         -- 2.データダンプ
        , ov_errbuf                     =>  lv_errbuf   -- エラー・メッセージ           --# 固定 #
        , ov_retcode                    =>  lv_retcode  -- リターン・コード             --# 固定 #
        , ov_errmsg                     =>  lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      -- 警告の場合
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- OUTパラメータを警告にセット
        ov_retcode := gv_status_warn;
--
        -- スキップ件数カウント
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- 正常の場合
      ELSE
        -- =============================
        -- E-7.登録用PL/SQL表投入
        -- =============================
        set_ins_tab(
          ir_xxwip_delivery_charges_if => lr_xdci_if_data -- 1.運賃アドオンマスタI/Fレコード型
         ,ov_errbuf  => lv_errbuf                         -- エラー・メッセージ           --# 固定 #
         ,ov_retcode => lv_retcode                        -- リターン・コード             --# 固定 #
         ,ov_errmsg  => lv_errmsg                         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
--
        -- 正常の場合
        ELSIF (lv_retcode = gv_status_normal) THEN
          -- 正常データ件数
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- 正常データダンプPL/SQL表投入
          normal_dump_tab(gn_normal_cnt) := lv_dump;
        END IF;
--      
      END IF;
--
    END LOOP xdci_ins_data_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (get_ins_data_cur%ISOPEN) THEN
        CLOSE get_ins_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (get_ins_data_cur%ISOPEN) THEN
        CLOSE get_ins_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (get_ins_data_cur%ISOPEN) THEN
        CLOSE get_ins_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ins_data;
--
  /**********************************************************************************
   * Procedure Name   : get_upd_data
   * Description      : 更新データ取得処理(E-7)
   ***********************************************************************************/
  PROCEDURE get_upd_data(
    it_request_id IN  xxwip_delivery_charges_if.request_id%TYPE,  -- 1.要求ID,
    ov_errbuf     OUT VARCHAR2,   --   エラー・メッセージ           # 固定 #
    ov_retcode    OUT VARCHAR2,   --   リターン・コード             # 固定 #
    ov_errmsg     OUT VARCHAR2    --   ユーザー・エラー・メッセージ # 固定 #
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upd_data'; -- プログラム名
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
    lr_xdci_if_data xxwip_delivery_charges_if%ROWTYPE;  -- 運賃アドオンマスタI/Fレコード型
    lv_dump         VARCHAR2(5000);                     -- データダンプ
--
    -- *** ローカル・カーソル ***
    -- 更新データ取得カーソル
    CURSOR get_upd_data_cur IS
      SELECT  /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */                   -- 2008/11/11 統合指摘#589 Add
              xdci.p_b_classe               -- 支払請求区分
            , xdci.goods_classe             -- 商品区分
            , xdci.delivery_company_code    -- 運送業者
            , xdci.shipping_address_classe  -- 配送区分
            , xdci.delivery_distance        -- 運賃距離
            , xdci.delivery_weight          -- 重量
            , xdci.start_date_active        -- 適用開始日
            , xdci.shipping_expenses        -- 運送費
            , xdci.leaf_consolid_add        -- リーフ混載割増
      FROM  xxwip_delivery_charges_if xdci  -- 運賃アドオンインタフェース
      WHERE xdci.request_id   = it_request_id   -- 要求ID
-- v1.3 ADD START
        AND xdci.goods_classe = gv_prod_div     -- 商品区分
-- v1.3 ADD END
        AND EXISTS(
                  SELECT  'X'
                  FROM  xxwip_delivery_charges xdc  -- 運賃アドオンマスタ
                  WHERE xdc.p_b_classe              = xdci.p_b_classe               -- 支払請求区分
                    AND xdc.goods_classe            = xdci.goods_classe             -- 商品区分
                    AND xdc.delivery_company_code   = xdci.delivery_company_code    -- 運送業者
                    AND xdc.shipping_address_classe = xdci.shipping_address_classe  -- 配送区分
                    AND xdc.delivery_distance       = xdci.delivery_distance        -- 運賃距離
                    AND xdc.delivery_weight         = xdci.delivery_weight          -- 重量
                    AND xdc.start_date_active       = xdci.start_date_active        -- 適用開始日
            );        
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
    -- =============================
    -- 更新データ取得
    -- =============================
    <<xdci_upd_data_loop>>
    FOR xdci_upd_dat IN get_upd_data_cur LOOP
      -- 運賃アドオンマスタI/Fレコード型にデータをセットする
      lr_xdci_if_data.p_b_classe
          := xdci_upd_dat.p_b_classe;               -- 支払請求区分
      lr_xdci_if_data.goods_classe
          := xdci_upd_dat.goods_classe;             -- 商品区分
      lr_xdci_if_data.delivery_company_code
          := xdci_upd_dat.delivery_company_code;    -- 運送業者
      lr_xdci_if_data.shipping_address_classe
          := xdci_upd_dat.shipping_address_classe;  -- 配送区分
      lr_xdci_if_data.delivery_distance
          := xdci_upd_dat.delivery_distance;        -- 運賃距離
      lr_xdci_if_data.delivery_weight
          := xdci_upd_dat.delivery_weight;          -- 重量
      lr_xdci_if_data.start_date_active
          := xdci_upd_dat.start_date_active;        -- 適用開始日
      lr_xdci_if_data.shipping_expenses
          := xdci_upd_dat.shipping_expenses;        -- 運送費
      lr_xdci_if_data.leaf_consolid_add
          := xdci_upd_dat.leaf_consolid_add;        -- リーフ混載割増
--    
      -- ===============================
      -- データダンプ取得処理
      -- ===============================
      get_data_dump(
          ir_xxwip_delivery_charges_if => lr_xdci_if_data -- 1.運賃アドオンマスタI/Fレコード型
        , ov_dump    => lv_dump                           -- データダンプ文字列
        , ov_errbuf  => lv_errbuf                         -- エラー・メッセージ           # 固定 #
        , ov_retcode => lv_retcode                        -- リターン・コード             # 固定 #
        , ov_errmsg  => lv_errmsg                         -- ユーザー・エラー・メッセージ # 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- E-5.マスタデータチェック処理
      -- =============================
      master_data_chk(
          ir_xxwip_delivery_charges_if  =>  lr_xdci_if_data -- 1.運賃アドオンマスタI/Fレコード型
        , iv_dump                       =>  lv_dump         -- 2.データダンプ
        , ov_errbuf                     =>  lv_errbuf       -- エラー・メッセージ           # 固定 #
        , ov_retcode                    =>  lv_retcode      -- リターン・コード             # 固定 #
        , ov_errmsg                     =>  lv_errmsg       -- ユーザー・エラー・メッセージ # 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      -- 警告の場合
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- OUTパラメータを警告にセット
        ov_retcode := gv_status_warn;
--
        -- スキップ件数カウント
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- 正常の場合
      ELSE
        -- =============================
        -- E-8.更新用PL/SQL表投入
        -- =============================
        set_upd_tab(
          ir_xxwip_delivery_charges_if => lr_xdci_if_data -- 1.運賃アドオンマスタI/Fレコード型
         ,ov_errbuf  => lv_errbuf                         -- エラー・メッセージ           # 固定 #
         ,ov_retcode => lv_retcode                        -- リターン・コード             # 固定 #
         ,ov_errmsg  => lv_errmsg                         -- ユーザー・エラー・メッセージ # 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
--
        -- 正常の場合
        ELSIF (lv_retcode = gv_status_normal) THEN
          -- 正常データ件数
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- 正常データダンプPL/SQL表投入
          normal_dump_tab(gn_normal_cnt) := lv_dump;
        END IF;
--
      END IF;
--
    END LOOP xdci_upd_data_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (get_upd_data_cur%ISOPEN) THEN
        CLOSE get_upd_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (get_upd_data_cur%ISOPEN) THEN
        CLOSE get_upd_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (get_upd_data_cur%ISOPEN) THEN
        CLOSE get_upd_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_upd_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_table_batch
   * Description      : 一括登録処理(E-9)
   ***********************************************************************************/
  PROCEDURE ins_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_table_batch'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 一括登録処理
    -- ===============================
    FORALL ln_cnt IN 1..delivery_charges_id_ins_tab.COUNT
      INSERT INTO xxwip_delivery_charges(
          delivery_charges_id                         -- 運賃マスタID
        , p_b_classe                                  -- 支払請求区分
        , goods_classe                                -- 商品区分
        , delivery_company_code                       -- 運送業者
        , shipping_address_classe                     -- 配送区分
        , delivery_distance                           -- 運賃距離
        , delivery_weight                             -- 重量
        , start_date_active                           -- 適用開始日
        , shipping_expenses                           -- 運送費
        , leaf_consolid_add                           -- リーフ混載割増
        , created_by                                  -- 作成者
        , creation_date                               -- 作成日
        , last_updated_by                             -- 最終更新者
        , last_update_date                            -- 最終更新日
        , last_update_login                           -- 最終更新ログイン
        , request_id                                  -- 要求ID
        , program_application_id                      -- コンカレント・プログラム・アプリケーションID
        , program_id                                  -- コンカレント・プログラムID
        , program_update_date                         -- プログラム更新日
      ) VALUES (
          delivery_charges_id_ins_tab(ln_cnt)         -- 運賃マスタID
        , p_b_classe_ins_tab(ln_cnt)                  -- 支払請求区分
        , goods_classe_ins_tab(ln_cnt)                -- 商品区分
        , delivery_company_code_ins_tab(ln_cnt)       -- 運送業者
        , ship_address_classe_ins_tab(ln_cnt)         -- 配送区分
        , delivery_distance_ins_tab(ln_cnt)           -- 運賃距離
        , delivery_weight_ins_tab(ln_cnt)             -- 重量
        , start_date_active_ins_tab(ln_cnt)           -- 適用開始日
        , NVL(shipping_expenses_ins_tab(ln_cnt), 0)   -- 運送費
        , NVL(leaf_consolid_add_ins_tab(ln_cnt), 0)   -- リーフ混載割増
        , FND_GLOBAL.USER_ID                          -- 作成者
        , SYSDATE                                     -- 作成日
        , FND_GLOBAL.USER_ID                          -- 最終更新者
        , SYSDATE                                     -- 最終更新日
        , FND_GLOBAL.LOGIN_ID                         -- 最終更新ログイン
        , FND_GLOBAL.CONC_REQUEST_ID                  -- 要求ID
        , FND_GLOBAL.PROG_APPL_ID                     -- コンカレント・プログラム・アプリケーションID
        , FND_GLOBAL.CONC_PROGRAM_ID                  -- コンカレント・プログラムID
        , SYSDATE                                     -- プログラム更新日
      );
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
  END ins_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : upd_table_batch
   * Description      : 一括更新処理(E-10)
   ***********************************************************************************/
  PROCEDURE upd_table_batch(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_table_batch'; -- プログラム名
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
    FORALL ln_cnt IN 1..p_b_classe_upd_tab.COUNT
      UPDATE  xxwip_delivery_charges
        SET   shipping_expenses       = NVL(shipping_expenses_upd_tab(ln_cnt), 0)
                                        -- 運送費
          ,   leaf_consolid_add       = NVL(leaf_consolid_add_upd_tab(ln_cnt), 0)
                                        -- リーフ混載割増
-- 2009/04/03 v1.2 ADD START
          ,   change_flg              = gv_on
                                        -- 変更フラグ
-- 2009/04/03 v1.2 ADD END
          ,   last_updated_by         = FND_GLOBAL.USER_ID
                                        -- 最終更新者
          ,   last_update_date        = SYSDATE
                                        -- 最終更新日
          ,   last_update_login       = FND_GLOBAL.LOGIN_ID
                                        -- 最終更新ログイン
          ,   request_id              = FND_GLOBAL.CONC_REQUEST_ID
                                        -- 要求ID
          ,   program_application_id  = FND_GLOBAL.PROG_APPL_ID
                                        -- コンカレント・プログラム・アプリケーションID
          ,   program_id              = FND_GLOBAL.CONC_PROGRAM_ID
                                        -- コンカレント・プログラムID
          ,   program_update_date     = SYSDATE
                                        -- プログラム更新日
      WHERE   p_b_classe              = p_b_classe_upd_tab(ln_cnt)
                                        -- 支払請求区分
        AND   goods_classe            = goods_classe_upd_tab(ln_cnt)
                                        -- 商品区分
        AND   delivery_company_code   = delivery_company_code_upd_tab(ln_cnt)
                                        -- 運送業者
        AND   shipping_address_classe = ship_address_classe_upd_tab(ln_cnt)
                                        -- 配送区分
        AND   delivery_distance       = delivery_distance_upd_tab(ln_cnt)
                                        -- 運賃距離
        AND   delivery_weight         = delivery_weight_upd_tab(ln_cnt)
                                        -- 重量
        AND   start_date_active       = start_date_active_upd_tab(ln_cnt)
                                        -- 適用開始日
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
  END upd_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : upd_end_date_active_all
   * Description      : 適用終了日更新処理(E-11)
   ***********************************************************************************/
  PROCEDURE upd_end_date_active_all(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_end_date_active_all'; -- プログラム名
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
    cv_xxcmn_max_date       CONSTANT VARCHAR2(50) := 'XXCMN_MAX_DATE';  -- PROFILE_OPTION：MAX日付
    cv_xxcmn_max_date_name  CONSTANT VARCHAR2(50) := 'XXCMN:MAX日付';   -- PROFILE_OPTION：MAX日付
--
    -- *** ローカル変数 ***
    lt_max_date   fnd_profile_option_values.profile_option_value%TYPE;  -- MAX日付
    ld_max_date   DATE;                                                 -- 変換後MAX日付
    ln_count      NUMBER DEFAULT 0;                                     -- 処理カウント
--
    -- 比較用変数
    lt_pre_p_b_classe               xxwip_delivery_charges.p_b_classe%TYPE;          -- 支払請求区分
    lt_pre_goods_classe             xxwip_delivery_charges.goods_classe%TYPE;            -- 商品区分
    lt_pre_delivery_company_code    xxwip_delivery_charges.delivery_company_code%TYPE;   -- 運送業者
    lt_pre_shipping_address_classe  xxwip_delivery_charges.shipping_address_classe%TYPE; -- 配送区分
    lt_pre_delivery_distance        xxwip_delivery_charges.delivery_distance%TYPE;       -- 運賃距離
    lt_pre_delivery_weight          xxwip_delivery_charges.delivery_weight%TYPE;         -- 重量
    lt_pre_start_date_active        xxwip_delivery_charges.start_date_active%TYPE;   -- 適用開始日
    lt_pre_end_date_active          xxwip_delivery_charges.end_date_active%TYPE;     -- 適用終了日
--
    -- 更新用PL/SQL表
    p_b_classe_tab                  p_b_classe_ttype;                   -- 支払請求区分
    goods_classe_tab                goods_classe_ttype;                 -- 商品区分
    delivery_company_code_tab       delivery_company_code_ttype;        -- 運送業者
    ship_address_classe_tab         shipping_address_classe_ttype;      -- 配送区分
    delivery_distance_tab           delivery_distance_ttype;            -- 運賃距離
    delivery_weight_tab             delivery_weight_ttype;              -- 重量
    start_date_active_tab           start_date_active_ttype;            -- 適用開始日
    end_date_active_tab             end_date_active_ttype;              -- 適用終了日
--
    -- *** ローカル・カーソル ***
    -- 運賃アドオンマスタ
    CURSOR upd_end_date_cur IS
      SELECT  xdc.p_b_classe              -- 支払請求区分
          ,   xdc.goods_classe            -- 商品区分
          ,   xdc.delivery_company_code   -- 運送業者
          ,   xdc.shipping_address_classe -- 配送区分
          ,   xdc.delivery_distance       -- 運賃距離
          ,   xdc.delivery_weight         -- 重量
          ,   xdc.start_date_active       -- 適用開始日
          ,   xdc.end_date_active         -- 適用終了日
      FROM    xxwip_delivery_charges xdc  -- 運賃アドオンマスタ
-- v1.3 ADD START
      WHERE   xdc.goods_classe = gv_prod_div -- 商品区分
-- v1.3 ADD END
      ORDER BY
              p_b_classe                  -- 支払請求区分
          ,   goods_classe                -- 商品区分
          ,   delivery_company_code       -- 運送業者
          ,   shipping_address_classe     -- 配送区分
          ,   delivery_distance           -- 運賃距離
          ,   delivery_weight             -- 重量
          ,   start_date_active           -- 適用開始日
      ;
--
    -- *** ローカル・レコード ***
    lr_xxwip_delivery_charges   upd_end_date_cur%ROWTYPE;
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
    -- MAX日付取得
    -- ===============================
    lt_max_date :=  FND_PROFILE.VALUE(cv_xxcmn_max_date);
--
    -- 取得できなかった場合はエラー
    IF (lt_max_date IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn               -- モジュール名略称：XXCMN 共通
                   ,gv_msg_xxcmn10002      -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                   ,gv_tkn_ng_profile      -- トークン：NGプロファイル名
                   ,cv_xxcmn_max_date_name -- MAX日付
                   ),1,5000);
--
      RAISE global_api_expt;
    END IF;
--
    -- MAX日付をDATE型に変換
    ld_max_date :=  FND_DATE.STRING_TO_DATE(lt_max_date, 'YYYY/MM/DD');
--
    -- 変換できなかった場合はエラー
    IF (ld_max_date IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- カーソルオープン
    -- ===============================
    OPEN upd_end_date_cur;
    FETCH upd_end_date_cur INTO lr_xxwip_delivery_charges;
--
    IF (upd_end_date_cur%FOUND) THEN
      -- 比較用変数に値をセット
      lt_pre_p_b_classe               := lr_xxwip_delivery_charges.p_b_classe;      -- 支払請求区分
      lt_pre_goods_classe             := lr_xxwip_delivery_charges.goods_classe;    -- 商品区分
      lt_pre_delivery_company_code    := lr_xxwip_delivery_charges.delivery_company_code;   
                                                                                    -- 運送業者
      lt_pre_shipping_address_classe  := lr_xxwip_delivery_charges.shipping_address_classe; 
                                                                                    -- 配送区分
      lt_pre_delivery_distance        := lr_xxwip_delivery_charges.delivery_distance;
                                                                                    -- 運賃距離
      lt_pre_delivery_weight          := lr_xxwip_delivery_charges.delivery_weight; -- 重量
      lt_pre_start_date_active        := lr_xxwip_delivery_charges.start_date_active;
                                                                                    -- 適用開始日
      lt_pre_end_date_active          := lr_xxwip_delivery_charges.end_date_active; -- 適用終了日
--
      <<upd_end_date_loop>>
      LOOP
        -- レコード読込
        FETCH upd_end_date_cur INTO lr_xxwip_delivery_charges;
        EXIT WHEN upd_end_date_cur%NOTFOUND;
--
        -- ===============================
        -- 前回読込データと比較
        -- ===============================
        -- 異なる場合(キーブレイク時)
        IF    (lt_pre_p_b_classe              <> lr_xxwip_delivery_charges.p_b_classe)
                                                  -- 支払請求区分
          OR  (lt_pre_goods_classe            <> lr_xxwip_delivery_charges.goods_classe)
                                                  -- 商品区分
          OR  (lt_pre_delivery_company_code   <> lr_xxwip_delivery_charges.delivery_company_code)
                                                  -- 運送業者
          OR  (lt_pre_shipping_address_classe <> lr_xxwip_delivery_charges.shipping_address_classe)
                                                  -- 配送区分
          OR  (lt_pre_delivery_distance       <> lr_xxwip_delivery_charges.delivery_distance) 
                                                  -- 運賃距離
          OR  (lt_pre_delivery_weight         <> lr_xxwip_delivery_charges.delivery_weight)
                                                  -- 重量
        THEN
          -- 前回読込データの適用終了日が適正でない場合
          IF  ((lt_pre_end_date_active IS NULL)
            OR  (lt_pre_end_date_active <> ld_max_date))
          THEN
            ln_count  :=  ln_count + 1;
            -- 前回読込データを更新用PL/SQL表にセットする
            p_b_classe_tab(ln_count)            := lt_pre_p_b_classe;               -- 支払請求区分
            goods_classe_tab(ln_count)          := lt_pre_goods_classe;             -- 商品区分
            delivery_company_code_tab(ln_count) := lt_pre_delivery_company_code;    -- 運送業者
            ship_address_classe_tab(ln_count)   := lt_pre_shipping_address_classe;  -- 配送区分
            delivery_distance_tab(ln_count)     := lt_pre_delivery_distance;        -- 運賃距離
            delivery_weight_tab(ln_count)       := lt_pre_delivery_weight;          -- 重量
            start_date_active_tab(ln_count)     := lt_pre_start_date_active;        -- 適用開始日
            end_date_active_tab(ln_count)       := ld_max_date;              -- 適用終了日(MAX日付)
--
          END IF;
--
        ELSE
--
          -- キーブレイクしない場合で、適用終了日が適正でない場合、
          -- 現レコードの適用開始日-1日をセットする
          IF  ((lt_pre_end_date_active IS NULL)
            OR  (lt_pre_end_date_active <> lr_xxwip_delivery_charges.start_date_active - 1))
          THEN
            ln_count  :=  ln_count + 1;
            -- 前回読込データを更新用PL/SQL表にセットする
            p_b_classe_tab(ln_count)
                := lt_pre_p_b_classe;                               -- 支払請求区分
            goods_classe_tab(ln_count)
                := lt_pre_goods_classe;                             -- 商品区分
            delivery_company_code_tab(ln_count)
                := lt_pre_delivery_company_code;                    -- 運送業者
            ship_address_classe_tab(ln_count)
                := lt_pre_shipping_address_classe;                  -- 配送区分
            delivery_distance_tab(ln_count)
                := lt_pre_delivery_distance;                        -- 運賃距離
            delivery_weight_tab(ln_count)
                := lt_pre_delivery_weight;                          -- 重量
            start_date_active_tab(ln_count)
                := lt_pre_start_date_active;                        -- 適用開始日
            end_date_active_tab(ln_count)
                := lr_xxwip_delivery_charges.start_date_active - 1; -- 適用開始日-1日
--                 
          END IF;
--
        END IF;
--
        -- 比較用変数に現レコードをセット
        lt_pre_p_b_classe               := lr_xxwip_delivery_charges.p_b_classe;
                                                                                    -- 支払請求区分
        lt_pre_goods_classe             := lr_xxwip_delivery_charges.goods_classe;
                                                                                    -- 商品区分
        lt_pre_delivery_company_code    := lr_xxwip_delivery_charges.delivery_company_code;   
                                                                                    -- 運送業者
        lt_pre_shipping_address_classe  := lr_xxwip_delivery_charges.shipping_address_classe; 
                                                                                    -- 配送区分
        lt_pre_delivery_distance        := lr_xxwip_delivery_charges.delivery_distance;       
                                                                                    -- 運賃距離
        lt_pre_delivery_weight          := lr_xxwip_delivery_charges.delivery_weight;         
                                                                                    -- 重量
        lt_pre_start_date_active        := lr_xxwip_delivery_charges.start_date_active;
                                                                                    -- 適用開始日
        lt_pre_end_date_active          := lr_xxwip_delivery_charges.end_date_active;
                                                                                    -- 適用終了日
--
      END LOOP upd_end_date_loop;
--    
      -- ===============================
      -- カーソルクローズ
      -- ===============================
      CLOSE upd_end_date_cur;
--
      -- =====================================
      -- 最終読込レコードの適用終了日をセット
      -- =====================================
      IF  ((lt_pre_end_date_active IS NULL)
        OR  (lt_pre_end_date_active <> ld_max_date))
      THEN
        ln_count  :=  ln_count + 1;
        -- 前回読込データを更新用PL/SQL表にセットする
        p_b_classe_tab(ln_count)
                  := lt_pre_p_b_classe;               -- 支払請求区分
        goods_classe_tab(ln_count)
                  := lt_pre_goods_classe;             -- 商品区分
        delivery_company_code_tab(ln_count)
                  := lt_pre_delivery_company_code;    -- 運送業者
        ship_address_classe_tab(ln_count)
                  := lt_pre_shipping_address_classe;  -- 配送区分
        delivery_distance_tab(ln_count)
                  := lt_pre_delivery_distance;        -- 運賃距離
        delivery_weight_tab(ln_count)
                  := lt_pre_delivery_weight;          -- 重量
        start_date_active_tab(ln_count)
                  := lt_pre_start_date_active;        -- 適用開始日
        end_date_active_tab(ln_count)
                  := ld_max_date;                     -- 適用終了日(MAX日付)
--
      END IF;
--
      -- ===============================
      -- 一括更新処理
      -- ===============================
      FORALL ln_upd_cnt IN 1.. delivery_company_code_tab.COUNT  
        UPDATE  xxwip_delivery_charges xdc -- 運賃アドオンマスタ
          SET   end_date_active             = end_date_active_tab(ln_upd_cnt)
                                              -- 適用終了日
-- 2009/04/03 v1.2 ADD START
            ,   change_flg                  = gv_on
                                              -- 変更フラグ
-- 2009/04/03 v1.2 ADD END
            ,   last_updated_by             = FND_GLOBAL.USER_ID
                                              -- 最終更新者
            ,   last_update_date            = SYSDATE
                                              -- 最終更新日
            ,   last_update_login           = FND_GLOBAL.LOGIN_ID
                                              -- 最終更新ログイン
            ,   request_id                  = FND_GLOBAL.CONC_REQUEST_ID
                                              -- 要求ID
            ,   program_application_id      = FND_GLOBAL.PROG_APPL_ID
                                              -- コンカレント・プログラム・アプリケーションID
            ,   program_id                  = FND_GLOBAL.CONC_PROGRAM_ID
                                              -- コンカレント・プログラムID
            ,   program_update_date         = SYSDATE
                                              -- プログラム更新日
        WHERE   xdc.p_b_classe              = p_b_classe_tab(ln_upd_cnt)            -- 支払請求区分
          AND   xdc.goods_classe            = goods_classe_tab(ln_upd_cnt)          -- 商品区分
          AND   xdc.delivery_company_code   = delivery_company_code_tab(ln_upd_cnt) -- 運送業者
          AND   xdc.shipping_address_classe = ship_address_classe_tab(ln_upd_cnt)   -- 配送区分
          AND   xdc.delivery_distance       = delivery_distance_tab(ln_upd_cnt)     -- 運賃距離
          AND   xdc.delivery_weight         = delivery_weight_tab(ln_upd_cnt)       -- 重量
          AND   xdc.start_date_active       = start_date_active_tab(ln_upd_cnt)     -- 適用開始日
        ;    
--
    ELSE
      -- データが存在しない場合はカーソルを閉じる
      -- ===============================
      -- カーソルクローズ
      -- ===============================
      CLOSE upd_end_date_cur;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (upd_end_date_cur%ISOPEN) THEN
        CLOSE upd_end_date_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (upd_end_date_cur%ISOPEN) THEN
        CLOSE upd_end_date_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (upd_end_date_cur%ISOPEN) THEN
        CLOSE upd_end_date_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_end_date_active_all;
--
  /**********************************************************************************
   * Procedure Name   : del_table_data
   * Description      : データ削除処理(E-12)
   ***********************************************************************************/
  PROCEDURE del_table_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_table_data'; -- プログラム名
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
    -- =====================================
    -- 運賃アドオンマスタインタフェース削除
    -- =====================================
    FORALL ln_count IN 1..request_id_tab.COUNT
      DELETE /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */             -- 2008/11/11 統合指摘#589 Add
      FROM xxwip_delivery_charges_if xdci          -- 運賃アドオンマスタインタフェース
      WHERE   xdci.request_id   = request_id_tab(ln_count)  -- 要求ID
-- v1.3 ADD START
        AND   xdci.goods_classe = gv_prod_div               -- 商品区分
-- v1.3 ADD END
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
  END del_table_data;
--
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : データダンプ一括出力処理
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
--
    IF (gn_normal_cnt > 0) THEN
--
      --区切り文字列出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);

      -- 成功データ（見出し）
      lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- モジュール名略称：XXCMN 共通
                  ,gv_msg_xxcmn00005      -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
                  ),1,5000);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
      -- 正常データダンプ
      <<normal_dump_loop>>
      FOR loop_cnt IN 1..normal_dump_tab.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,normal_dump_tab(loop_cnt));
      END LOOP normal_dump_loop;
--
    END IF;
--
    IF (gn_warn_cnt > 0) THEN
      --区切り文字列出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);

      -- スキップデータデータ（見出し）
      lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- モジュール名略称：XXCMN 共通
                  ,gv_msg_xxcmn00007      -- メッセージ：APP-XXCMN-00007 スキップデータ（見出し）
                  ),1,5000);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
      -- 警告データダンプ
      <<warn_dump_loop>>
      FOR loop_cnt IN 1..warn_dump_tab.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,warn_dump_tab(loop_cnt));
      END LOOP warn_dump_loop;
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
  END put_dump_msg;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
-- v1.3 ADD START
    iv_prod_div   IN  VARCHAR2,     --   商品区分
-- v1.3 ADD END
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- 要求ID取得カーソル
    CURSOR xdci_request_id_cur
    IS
      SELECT fcr.request_id
      FROM   fnd_concurrent_requests fcr                -- コンカレント要求IDテーブル
      WHERE  EXISTS (
               SELECT /*+ INDEX( xdci xxwip_deli_char_if_n01 ) */       -- 2008/11/11 統合指摘#589 Add
                      'X'
               FROM   xxwip_delivery_charges_if xdci    -- 運賃アドオンマスタインタフェース
               WHERE  xdci.request_id   = fcr.request_id  -- 要求ID
-- v1.3 ADD START
               AND    xdci.goods_classe = gv_prod_div     -- 商品区分
-- v1.3 ADD END
               AND    ROWNUM = 1
             )
      ORDER BY fcr.request_id                           -- 要求ID
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
    gn_target_cnt := 0; -- 対象件数
    gn_normal_cnt := 0; -- 正常件数
    gn_error_cnt  := 0; -- エラー件数
    gn_warn_cnt   := 0; -- スキップ件数
--
-- v1.3 ADD START
    -- 入力パラメータ.商品区分をグローバル変数に格納
    gv_prod_div   := iv_prod_div;
-- v1.3 ADD END
    -- ===============================
    -- E-1.要求ID取得処理
    -- ===============================
    <<get_request_id_loop>>
    FOR lr_xdci_request_id IN xdci_request_id_cur
    LOOP
      gn_request_id_cnt := gn_request_id_cnt + 1 ;
      request_id_tab(gn_request_id_cnt)  := lr_xdci_request_id.request_id;
    END LOOP get_request_id_loop;
--
    IF (gn_request_id_cnt >= 1) THEN
--
      -- ===============================
      -- E-2.表ロック取得処理
      -- ===============================
      get_lock(
        ov_errbuf     => lv_errbuf    -- エラー・メッセージ           --# 固定 #
      , ov_retcode    => lv_retcode   -- リターン・コード             --# 固定 #
      , ov_errmsg     => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- ロック取得エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ==================================
      -- 取得した要求IDのレコード分処理する
      -- ==================================
      <<process_loop>>
      FOR loop_cnt IN 1..request_id_tab.COUNT LOOP
        -- 登録用・更新用PL/SQL表カウンタ初期化
        gn_ins_tab_cnt  :=  0;  -- 登録用
        gn_upd_tab_cnt  :=  0;  -- 更新用
--
        -- 登録用PL/SQL表初期化
        delivery_charges_id_ins_tab.DELETE;     -- 運賃マスタID
        p_b_classe_ins_tab.DELETE;              -- 支払請求区分
        goods_classe_ins_tab.DELETE;            -- 商品区分
        delivery_company_code_ins_tab.DELETE;   -- 運送業者
        ship_address_classe_ins_tab.DELETE;     -- 配送区分
        delivery_distance_ins_tab.DELETE;       -- 運賃距離
        delivery_weight_ins_tab.DELETE;         -- 重量
        start_date_active_ins_tab.DELETE;       -- 適用開始日
        end_date_active_ins_tab.DELETE;         -- 適用終了日
        shipping_expenses_ins_tab.DELETE;       -- 運送費
        leaf_consolid_add_ins_tab.DELETE;       -- リーフ混載割増
--
        -- 更新用PL/SQL表初期化
        delivery_charges_id_upd_tab.DELETE;     -- 運賃マスタID
        p_b_classe_upd_tab.DELETE;              -- 支払請求区分
        goods_classe_upd_tab.DELETE;            -- 商品区分
        delivery_company_code_upd_tab.DELETE;   -- 運送業者
        ship_address_classe_upd_tab.DELETE;     -- 配送区分
        delivery_distance_upd_tab.DELETE;       -- 運賃距離
        delivery_weight_upd_tab.DELETE;         -- 重量
        start_date_active_upd_tab.DELETE;       -- 適用開始日
        end_date_active_upd_tab.DELETE;         -- 適用終了日
        shipping_expenses_upd_tab.DELETE;       -- 運送費
        leaf_consolid_add_upd_tab.DELETE;       -- リーフ混載割増
--
      -- ===============================
      -- E-3.重複データ除外処理
      -- ===============================
        del_duplication_data(
            it_request_id => request_id_tab(loop_cnt) -- 1.要求ID
          , ov_errbuf     => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode    => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg     => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );                 
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        -- 警告の場合
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := gv_status_warn;
        END IF;
--
        -- ===============================
        -- E-4.新規登録データ取得処理
        -- ===============================
        get_ins_data(
            it_request_id => request_id_tab(loop_cnt) -- 1.要求ID
          , ov_errbuf     => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode    => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg     => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        -- 警告の場合
        ELSIF (lv_retcode = gv_status_warn) THEN
          ov_retcode := gv_status_warn;
        END IF;
--
        -- ===============================
        -- E-7.更新データ取得処理
        -- ===============================
        get_upd_data(
            it_request_id => request_id_tab(loop_cnt) -- 1.要求ID
          , ov_errbuf     => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode    => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg     => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
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
        -- E-9.一括登録処理
        -- ===============================
        ins_table_batch(
            ov_errbuf     => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode    => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg     => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- E-10.一括更新処理
        -- ===============================
        upd_table_batch(
            ov_errbuf     => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode    => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg     => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP process_loop;
--
      -- ===============================
      -- E-11.適用終了日更新処理
      -- ===============================
      upd_end_date_active_all(
            ov_errbuf     => lv_errbuf                -- エラー・メッセージ           --# 固定 #
          , ov_retcode    => lv_retcode               -- リターン・コード             --# 固定 #
          , ov_errmsg     => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- E-12.データ削除処理
      -- ===============================
      del_table_data(
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
      -- データダンプ一括出力処理
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
    ELSE
      -- 要求IDが取得できない場合は処理を行わない。
      NULL;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (xdci_request_id_cur%ISOPEN) THEN
        CLOSE xdci_request_id_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xdci_request_id_cur%ISOPEN) THEN
        CLOSE xdci_request_id_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xdci_request_id_cur%ISOPEN) THEN
        CLOSE xdci_request_id_cur;
      END IF;
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
    errbuf        OUT VARCHAR2, --   エラー・メッセージ  --# 固定 #
-- v1.3 MOD START
--    retcode       OUT VARCHAR2  --   リターン・コード    --# 固定 #
    retcode       OUT VARCHAR2, --   リターン・コード    --# 固定 #
    iv_prod_div   IN  VARCHAR2  --   商品区分
-- v1.3 MOD END
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
-- v1.3 ADD START
      iv_prod_div, --   商品区分
-- v1.3 ADD END
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
    -- リターン・コードのセット、終了処理
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
END xxwip720002c;
/
