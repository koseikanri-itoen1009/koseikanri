CREATE OR REPLACE PACKAGE BODY xxwip720001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip720001c(body)
 * Description      : 配送距離アドオンマスタ取込処理
 * MD.050           : 運賃計算（マスタ） T_MD050_BPO_720
 * MD.070           : 配送距離アドオンマスタ取込処理(72D) T_MD070_BPO_72D
 * Version          : 1.3
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                       Description
 * --------------------------- ----------------------------------------------------------
 *  get_lock                    ロック取得処理(D-2)
 *  get_data_dump               データダンプ取得処理(D-4)
 *  del_duplication_data        重複データ除外処理(D-3)
 *  master_data_chk             マスタデータチェック処理(D-6)
 *  set_ins_tab                 登録用PL/SQL表投入(D-7)
 *  set_upd_tab                 更新用PL/SQL表投入(D-9)
 *  get_ins_data                登録データ取得処理(D-5)
 *  get_upd_data                更新データ取得処理(D-8)
 *  ins_table_batch             一括登録処理(D-10)
 *  upd_table_batch             一括更新処理(D-11)
 *  update_end_date_active_all  適用終了日更新処理(D-12)
 *  del_table_data              データ削除処理(D-13)
 *  put_dump_msg                データダンプ一括出力処理(D-14)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/12    1.0   H.Itou           新規作成
 *  2008/09/02    1.1   A.Shiina         内部変更要求#204対応
 *  2009/04/03    1.2   A.Shiina         本番#432対応
 *  2016/06/22    1.3   K.Kiriu          E_本稼動_13659対応
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
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwip720001c'; -- パッケージ名
  -- モジュール名略称
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';        -- モジュール名略称：XXCMN 共通
  gv_xxwip           CONSTANT VARCHAR2(100) := 'XXWIP';        -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
--
  -- メッセージ
  gv_msg_xxwip10004  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10004'; -- メッセージ：APP-XXWIP-10004 ロックエラー詳細メッセージ
  gv_msg_xxwip10023  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10023'; -- メッセージ：APP-XXWIP-10023 データ重複エラーメッセージ
  gv_msg_xxcmn10001  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10001'; -- メッセージ：APP-XXCMN-10001 対象データなし
  gv_msg_xxxip10059  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10059'; -- メッセージ：APP-XXWIP-10059 出荷管理元区分エラー
  gv_msg_xxxip10060  CONSTANT VARCHAR2(100) := 'APP-XXWIP-10060'; -- メッセージ：APP-XXWIP-10060 出荷管理元区分エラー(配送先)
  gv_msg_xxcmn10002  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
  gv_msg_xxcmn00005  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005'; -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
  gv_msg_xxcmn00007  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00007'; -- メッセージ：APP-XXCMN-00007 スキップデータ（見出し）
--
  -- トークン
  gv_tkn_value              CONSTANT VARCHAR2(100) := 'VALUE';            -- トークン：VALUE
  gv_tkn_item               CONSTANT VARCHAR2(100) := 'ITEM';             -- トークン：ITEM
  gv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';            -- トークン：TABLE
  gv_tkn_key                CONSTANT VARCHAR2(100) := 'KEY';              -- トークン：KEY
  gv_tkn_goods_classe       CONSTANT VARCHAR2(100) := 'GOODS_CLASSE';     -- トークン：GOODS_CLASSE
  gv_tkn_location_id        CONSTANT VARCHAR2(100) := 'LOCATION_ID';      -- トークン：LOCATION_ID
  gv_tkn_party_site_number  CONSTANT VARCHAR2(100) := 'PARTY_SITE_NUMBER';-- トークン：PARTY_SITE_NUMBER
  gv_tkn_ng_profile         CONSTANT VARCHAR2(100) := 'NG_PROFILE';       -- トークン：NG_PROFILE
--
  -- YES/NO
  gv_y               CONSTANT VARCHAR2(1) := 'Y';
  gv_n               CONSTANT VARCHAR2(1) := 'N';
--
  -- 商品区分
  gv_goods_classe_reaf  CONSTANT VARCHAR2(1) := '1';   -- 商品区分：1(リーフ)
  gv_goods_classe_drink CONSTANT VARCHAR2(1) := '2';   -- 商品区分：2(ドリンク)
--
  -- 出荷管理元区分
  gv_shipment_management_sales  CONSTANT VARCHAR2(1) := '0';  -- 出荷管理元区分：0(販売拠点)
  gv_shipment_management_reaf   CONSTANT VARCHAR2(1) := '1';  -- 出荷管理元区分：1(出荷管理元リーフ)
  gv_shipment_management_drink  CONSTANT VARCHAR2(1) := '2';  -- 出荷管理元区分：2(出荷管理元ドリンク)
  gv_shipment_management_both   CONSTANT VARCHAR2(1) := '3';  -- 出荷管理元区分：3(出荷管理元・両方)
--
  -- コード区分
  gv_code_type_location         CONSTANT VARCHAR2(1) := '1';  -- コード区分：1(倉庫)
  gv_code_type_customer         CONSTANT VARCHAR2(1) := '2';  -- コード区分：2(取引先)
  gv_code_type_delivery         CONSTANT VARCHAR2(1) := '3';  -- コード区分：3(配送先)
--
-- 2009/04/03 v1.2 ADD START
  gv_on                         CONSTANT VARCHAR2(1) := '1';  -- 変更フラグ：変更あり
--
-- 2009/04/03 v1.2 ADD END
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- メッセージPL/SQL表型
  TYPE msg_ttype                    IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- 登録・更新用PL/SQL表型
  TYPE delivery_distance_id_ttype   IS TABLE OF  xxwip_delivery_distance.delivery_distance_id     %TYPE INDEX BY BINARY_INTEGER;  -- 配送距離ID
  TYPE goods_classe_ttype           IS TABLE OF  xxwip_delivery_distance.goods_classe             %TYPE INDEX BY BINARY_INTEGER;  -- 商品区分
  TYPE delivery_company_code_ttype  IS TABLE OF  xxwip_delivery_distance.delivery_company_code    %TYPE INDEX BY BINARY_INTEGER;  -- 運送業者コード
  TYPE origin_shipment_ttype        IS TABLE OF  xxwip_delivery_distance.origin_shipment          %TYPE INDEX BY BINARY_INTEGER;  -- 出庫元
  TYPE code_division_ttype          IS TABLE OF  xxwip_delivery_distance.code_division            %TYPE INDEX BY BINARY_INTEGER;  -- コード区分
  TYPE shipping_address_code_ttype  IS TABLE OF  xxwip_delivery_distance.shipping_address_code    %TYPE INDEX BY BINARY_INTEGER;  -- 配送先コード
  TYPE start_date_active_ttype      IS TABLE OF  xxwip_delivery_distance.start_date_active        %TYPE INDEX BY BINARY_INTEGER;  -- 適用開始日
  TYPE end_date_active_ttype        IS TABLE OF  xxwip_delivery_distance.end_date_active          %TYPE INDEX BY BINARY_INTEGER;  -- 適用終了日
  TYPE post_distance_ttype          IS TABLE OF  xxwip_delivery_distance.post_distance            %TYPE INDEX BY BINARY_INTEGER;  -- 車立距離
  TYPE small_distance_ttype         IS TABLE OF  xxwip_delivery_distance.small_distance           %TYPE INDEX BY BINARY_INTEGER;  -- 小口距離
  TYPE consolid_add_dist_ttype      IS TABLE OF  xxwip_delivery_distance.consolid_add_distance    %TYPE INDEX BY BINARY_INTEGER;  -- 混載割増距離
  TYPE actual_distance_ttype        IS TABLE OF  xxwip_delivery_distance.actual_distance          %TYPE INDEX BY BINARY_INTEGER;  -- 実際距離
  TYPE area_a_ttype                 IS TABLE OF  xxwip_delivery_distance.area_a                   %TYPE INDEX BY BINARY_INTEGER;  -- エリアA
  TYPE area_b_ttype                 IS TABLE OF  xxwip_delivery_distance.area_b                   %TYPE INDEX BY BINARY_INTEGER;  -- エリアB
  TYPE area_c_ttype                 IS TABLE OF  xxwip_delivery_distance.area_c                   %TYPE INDEX BY BINARY_INTEGER;  -- エリアC
--
  -- 要求ID用PL/SQL表型
  TYPE request_id_ttype             IS TABLE OF  fnd_concurrent_requests.request_id               %TYPE INDEX BY BINARY_INTEGER;  -- 要求ID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 警告データダンプPL/SQL表
  warn_dump_tab         msg_ttype;
--
  -- 正常データダンプPL/SQL表
  normal_dump_tab      msg_ttype; 
--
  -- 登録用PL/SQL表
  delivery_distance_id_ins_tab      delivery_distance_id_ttype;   -- 配送距離ID
  goods_classe_ins_tab              goods_classe_ttype;           -- 商品区分
  delivery_company_code_ins_tab    delivery_company_code_ttype;  -- 運送業者コード
  origin_shipment_ins_tab           origin_shipment_ttype;        -- 出庫元
  code_division_ins_tab             code_division_ttype;          -- コード区分
  shipping_address_code_ins_tab     shipping_address_code_ttype;  -- 配送先コード
  start_date_active_ins_tab         start_date_active_ttype;      -- 適用開始日
  end_date_active_ins_tab           end_date_active_ttype;        -- 適用終了日
  post_distance_ins_tab             post_distance_ttype;          -- 車立距離
  small_distance_ins_tab            small_distance_ttype;         -- 小口距離
  consolid_add_dist_ins_tab         consolid_add_dist_ttype;      -- 混載割増距離
  actual_distance_ins_tab           actual_distance_ttype;        -- 実際距離
  area_a_ins_tab                    area_a_ttype;                 -- エリアA
  area_b_ins_tab                    area_b_ttype;                 -- エリアB
  area_c_ins_tab                    area_c_ttype;                 -- エリアC
--
  -- 更新用PL/SQL表
  delivery_distance_id_upd_tab      delivery_distance_id_ttype;   -- 配送距離ID
  goods_classe_upd_tab              goods_classe_ttype;           -- 商品区分
  delivery_company_code_upd_tab    delivery_company_code_ttype;  -- 運送業者コード
  origin_shipment_upd_tab           origin_shipment_ttype;        -- 出庫元
  code_division_upd_tab             code_division_ttype;          -- コード区分
  shipping_address_code_upd_tab     shipping_address_code_ttype;  -- 配送先コード
  start_date_active_upd_tab         start_date_active_ttype;      -- 適用開始日
  end_date_active_upd_tab           end_date_active_ttype;        -- 適用終了日
  post_distance_upd_tab             post_distance_ttype;          -- 車立距離
  small_distance_upd_tab            small_distance_ttype;         -- 小口距離
  consolid_add_dist_upd_tab         consolid_add_dist_ttype;      -- 混載割増距離
  actual_distance_upd_tab           actual_distance_ttype;        -- 実際距離
  area_a_upd_tab                    area_a_ttype;                 -- エリアA
  area_b_upd_tab                    area_b_ttype;                 -- エリアB
  area_c_upd_tab                    area_c_ttype;                 -- エリアC
--
-- 要求ID用PL/SQL表
  request_id_tab                    request_id_ttype;             -- 要求ID
--
  -- カウント
  gn_err_msg_cnt      NUMBER := 0;   -- 警告エラーメッセージ表カウント
  gn_ins_tab_cnt      NUMBER := 0;   -- 登録用PL/SQL表カウント
  gn_upd_tab_cnt      NUMBER := 0;   -- 更新用PL/SQL表カウント
  gn_request_id_cnt   NUMBER := 0;   -- 要求IDカウント
--
-- v1.3 ADD START
  gv_prod_div         VARCHAR2(1);   -- 商品区分
-- v1.3 ADD END
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ロック取得処理(D-2)
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
    cv_xxwip_delivery_distance     VARCHAR2(50) := '配送距離アドオンマスタ';
    cv_xxwip_delivery_distance_if  VARCHAR2(50) := '配送距離アドオンマスタインタフェース';
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 配送距離アドオンマスタインタフェースカーソル
    CURSOR xxwip_delivery_charges_if_cur(lt_request_id xxwip_delivery_distance_if.request_id%TYPE)
    IS
      SELECT xddi.delivery_distance_if_id  delivery_distance_if_id   -- 配送距離アドオンマスタインタフェースID
      FROM   xxwip_delivery_distance_if    xddi                      -- 配送距離アドオンマスタインタフェース
      WHERE  xddi.request_id = lt_request_id                         -- 要求ID
      FOR UPDATE NOWAIT
    ;
--
    -- 配送距離アドオンマスタカーソル
    CURSOR xxwip_delivery_charges_cur
    IS
      SELECT xdd.delivery_distance_id  delivery_distance_id          -- 配送距離アドオンマスタID
      FROM   xxwip_delivery_distance    xdd                          -- 配送距離アドオンマスタ
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
    -- ==============================
    -- ロック取得
    -- ==============================
    -- 配送距離アドオンマスタインタフェースのロックを取得
    BEGIN
      <<request_id_loop>>
      FOR ln_count IN 1..request_id_tab.COUNT
      LOOP
        <<look_if_loop>>
        FOR lr_xxwip_delivery_charges_if IN xxwip_delivery_charges_if_cur(request_id_tab(ln_count))
        LOOP
          EXIT;
        END LOOP xxwip_deli_distance_if_loop;
      END LOOP request_id_loop;

--
    EXCEPTION
      WHEN lock_expt THEN                           --*** ロック取得エラー ***
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip               -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10004      -- メッセージ：APP-XXWIP-10004 ロックエラー詳細メッセージ
                     ,gv_tkn_table           -- トークンTABLE
                     ,cv_xxwip_delivery_distance_if    -- テーブル名：配送距離アドオンマスタインタフェース
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- 配送距離アドオンマスタのロックを取得
    BEGIN
       <<look_loop>>
      FOR lr_xxwip_delivery_charges IN xxwip_delivery_charges_cur LOOP
        EXIT;
      END LOOP xxwip_delivery_distance_loop;
--
    EXCEPTION
      WHEN lock_expt THEN                           --*** ロック取得エラー ***
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip               -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                     ,gv_msg_xxwip10004      -- メッセージ：APP-XXWIP-10004 ロックエラー詳細メッセージ
                     ,gv_tkn_table           -- トークンTABLE
                     ,cv_xxwip_delivery_distance    -- テーブル名：配送距離アドオンマスタ
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
   * Procedure Name   : get_data_dump
   * Description      : データダンプ取得処理(D-4)
   ***********************************************************************************/
  PROCEDURE get_data_dump(
    ir_xxwip_delivery_distance_if xxwip_delivery_distance_if%ROWTYPE, -- 1.xxwip_delivery_distance_ifレコード型
    ov_dump       OUT VARCHAR2,     -- 1.データダンプ文字列
    ov_errbuf     OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    ov_dump := ir_xxwip_delivery_distance_if.goods_classe                            || gv_msg_comma ||  -- 商品区分
               ir_xxwip_delivery_distance_if.delivery_company_code                   || gv_msg_comma ||  -- 運送業者コード
               ir_xxwip_delivery_distance_if.origin_shipment                         || gv_msg_comma ||  -- 出庫元
               ir_xxwip_delivery_distance_if.area_a                                  || gv_msg_comma ||  -- エリアA
               ir_xxwip_delivery_distance_if.area_b                                  || gv_msg_comma ||  -- エリアB
               ir_xxwip_delivery_distance_if.area_c                                  || gv_msg_comma ||  -- エリアC
               ir_xxwip_delivery_distance_if.code_division                           || gv_msg_comma ||  -- コード区分
               ir_xxwip_delivery_distance_if.shipping_address_code                   || gv_msg_comma ||  -- 配送先コード
               TO_CHAR(ir_xxwip_delivery_distance_if.start_date_active,'YYYY/MM/DD') || gv_msg_comma ||  -- 適用開始日
               TO_CHAR(ir_xxwip_delivery_distance_if.post_distance)                  || gv_msg_comma ||  -- 車立距離
               TO_CHAR(ir_xxwip_delivery_distance_if.small_distance)                 || gv_msg_comma ||  -- 小口距離
               TO_CHAR(ir_xxwip_delivery_distance_if.consolid_add_distance)          || gv_msg_comma ||  -- 混載割増距離
               TO_CHAR(ir_xxwip_delivery_distance_if.actual_distance)                                    -- 実際距離
               ;
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
  END get_data_dump;
--
  /**********************************************************************************
   * Procedure Name   : del_duplication_data
   * Description      : 重複データ除外処理(D-3)
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
    lv_dump VARCHAR2(5000);  -- データダンプ
    lr_xxwip_delivery_distance_if xxwip_delivery_distance_if%ROWTYPE;  -- xxwip_delivery_distance_ifレコード型
--
    -- *** ローカル・カーソル ***
    -- 重複チェックカーソル
    CURSOR xddi_duplication_chk_cur
    IS
      SELECT COUNT(xddi.delivery_distance_if_id) cnt -- カウント
            ,xddi.goods_classe                       -- 商品区分
            ,xddi.delivery_company_code              -- 運送業者コード
            ,xddi.origin_shipment                    -- 出庫元
            ,xddi.start_date_active                  -- 適用開始日
            ,xddi.code_division                      -- コード区分
            ,xddi.shipping_address_code              -- 配送先コード
      FROM   xxwip_delivery_distance_if  xddi        -- 配送距離アドオンマスタインタフェース
      WHERE  xddi.request_id = it_request_id         -- 要求ID
-- v1.3 ADD START
      AND    xddi.goods_classe = gv_prod_div         -- 商品区分
-- v1.3 ADD END
      GROUP BY 
             xddi.goods_classe          -- 商品区分
            ,xddi.delivery_company_code -- 運送業者コード
            ,xddi.origin_shipment       -- 出庫元
            ,xddi.start_date_active     -- 適用開始日
            ,xddi.code_division         -- コード区分
            ,xddi.shipping_address_code -- 配送先コード
    ;
--
    -- エラーデータカーソル
    CURSOR xddi_err_data_cur(
      lt_goods_classe          xxwip_delivery_distance_if.goods_classe%TYPE            -- 商品区分
     ,lt_delivery_company_code xxwip_delivery_distance_if.delivery_company_code%TYPE   -- 運送業者コード
     ,lt_origin_shipment       xxwip_delivery_distance_if.origin_shipment%TYPE         -- 出庫元
     ,lt_start_date_active     xxwip_delivery_distance_if.start_date_active%TYPE       -- 適用開始日
     ,lt_code_division         xxwip_delivery_distance_if.code_division%TYPE           -- コード区分
     ,lt_shipping_address_code xxwip_delivery_distance_if.shipping_address_code%TYPE   -- 配送先コード
    )
    IS
      SELECT xddi.goods_classe                goods_classe                 -- 商品区分
            ,xddi.delivery_company_code       delivery_company_code        -- 運送業者コード
            ,xddi.origin_shipment             origin_shipment              -- 出庫元
            ,xddi.area_a                      area_a                       -- エリアA
            ,xddi.area_b                      area_b                       -- エリアB
            ,xddi.area_c                      area_c                       -- エリアC
            ,xddi.code_division               code_division                -- コード区分
            ,xddi.shipping_address_code       shipping_address_code        -- 配送先コード
            ,xddi.start_date_active           start_date_active            -- 適用開始日
            ,xddi.post_distance               post_distance                -- 車立距離
            ,xddi.small_distance              small_distance               -- 小口距離
            ,xddi.consolid_add_distance       consolid_add_distance        -- 混載割増距離
            ,xddi.actual_distance             actual_distance              -- 実際距離
      FROM   xxwip_delivery_distance_if  xddi        -- 配送距離アドオンマスタインタフェース
      WHERE  xddi.goods_classe           = lt_goods_classe                 -- 商品区分
      AND    xddi.delivery_company_code  = lt_delivery_company_code        -- 運送業者コード
      AND    xddi.origin_shipment        = lt_origin_shipment              -- 出庫元
      AND    xddi.start_date_active      = lt_start_date_active            -- 適用開始日
      AND    xddi.code_division          = lt_code_division                -- コード区分
      AND    xddi.shipping_address_code  = lt_shipping_address_code        -- 配送先コード
      ORDER BY xddi.delivery_distance_if_id
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
    <<xddi_duplication_chk_loop>>
    FOR lr_xddi_duplication_chk IN xddi_duplication_chk_cur LOOP
      -- カウントが2件以上ある場合、重複しているのでエラー
      IF (lr_xddi_duplication_chk.cnt > 1) THEN
        -- ===============================
        -- エラーデータカーソル
        -- ===============================
        <<xddi_xddi_err_data_loop>>
        FOR lr_xddi_err_data IN  
          xddi_err_data_cur(
            lr_xddi_duplication_chk.goods_classe           -- 商品区分
           ,lr_xddi_duplication_chk.delivery_company_code  -- 運送業者コード
           ,lr_xddi_duplication_chk.origin_shipment        -- 出庫元
           ,lr_xddi_duplication_chk.start_date_active      -- 適用開始日
           ,lr_xddi_duplication_chk.code_division          -- コード区分
           ,lr_xddi_duplication_chk.shipping_address_code  -- 配送先コード
          ) LOOP
--
          -- レコードにデータセット
          lr_xxwip_delivery_distance_if.goods_classe           := lr_xddi_err_data.goods_classe;                 -- 商品区分
          lr_xxwip_delivery_distance_if.delivery_company_code  := lr_xddi_err_data.delivery_company_code;        -- 運送業者コード
          lr_xxwip_delivery_distance_if.origin_shipment        := lr_xddi_err_data.origin_shipment;              -- 出庫元
          lr_xxwip_delivery_distance_if.area_a                 := lr_xddi_err_data.area_a;                       -- エリアA
          lr_xxwip_delivery_distance_if.area_b                 := lr_xddi_err_data.area_b;                       -- エリアB
          lr_xxwip_delivery_distance_if.area_c                 := lr_xddi_err_data.area_c;                       -- エリアC
          lr_xxwip_delivery_distance_if.code_division          := lr_xddi_err_data.code_division;                -- コード区分
          lr_xxwip_delivery_distance_if.shipping_address_code  := lr_xddi_err_data.shipping_address_code;        -- 配送先コード
          lr_xxwip_delivery_distance_if.start_date_active      := lr_xddi_err_data.start_date_active;            -- 適用開始日
          lr_xxwip_delivery_distance_if.post_distance          := lr_xddi_err_data.post_distance;                -- 車立距離
          lr_xxwip_delivery_distance_if.small_distance         := lr_xddi_err_data.small_distance;               -- 小口距離
          lr_xxwip_delivery_distance_if.consolid_add_distance  := lr_xddi_err_data.consolid_add_distance;        -- 混載割増距離
          lr_xxwip_delivery_distance_if.actual_distance        := lr_xddi_err_data.actual_distance;              -- 実際距離
--
          -- ===============================
          -- D-4.データダンプ取得処理
          -- ===============================
          get_data_dump(
            ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if -- 1.xxwip_delivery_distance_ifレコード型
           ,ov_dump    => lv_dump            -- 1.データダンプ文字列
           ,ov_errbuf  => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          -- エラーの場合
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 警告エラーメッセージ取得
          -- ===============================
          IF (lv_errmsg IS NULL) THEN
               -- エラーメッセージ取得
              lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                              gv_xxwip               -- モジュール名略称：XXWIP 生産・品質管理・運賃計算
                             ,gv_msg_xxwip10023      -- メッセージ：APP-XXWIP-10023 データ重複エラーメッセージ
                             ,gv_tkn_item            -- トークンitem
                             ,cv_item                -- item名
                              ),1,5000);
--
          END IF;
--
          -- ===============================
          -- 警告データダンプPL/SQL表投入
          -- ===============================
          -- データダンプ
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_dump;
          
--
          -- 警告メッセージ
          gn_err_msg_cnt := gn_err_msg_cnt + 1;
          warn_dump_tab(gn_err_msg_cnt) := lv_errmsg;
--
          -- スキップ件数カウント
          gn_warn_cnt   := gn_warn_cnt + 1;
--
        END LOOP xddi_xddi_err_data_loop;
--
        -- ===============================
        -- エラーデータ削除
        -- ===============================
        DELETE xxwip_delivery_distance_if xddi   -- 配送距離アドオンマスタインタフェース
        WHERE  xddi.goods_classe           = lr_xddi_duplication_chk.goods_classe                 -- 商品区分
        AND    xddi.delivery_company_code  = lr_xddi_duplication_chk.delivery_company_code        -- 運送業者コード
        AND    xddi.origin_shipment        = lr_xddi_duplication_chk.origin_shipment              -- 出庫元
        AND    xddi.start_date_active      = lr_xddi_duplication_chk.start_date_active            -- 適用開始日
        AND    xddi.code_division          = lr_xddi_duplication_chk.code_division                -- コード区分
        AND    xddi.shipping_address_code  = lr_xddi_duplication_chk.shipping_address_code        -- 配送先コード
        ;
--
       -- ===============================
       --  OUTパラメータセット
       -- ===============================
       ov_retcode := gv_status_warn;
--
      END IF;
--
    END LOOP xddi_duplication_chk_loop;
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (xddi_duplication_chk_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      IF (xddi_err_data_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xddi_duplication_chk_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      IF (xddi_err_data_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xddi_duplication_chk_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      IF (xddi_err_data_cur%ISOPEN) THEN
        CLOSE xddi_duplication_chk_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_duplication_data;
--
--
  /**********************************************************************************
   * Procedure Name   : master_data_chk
   * Description      : マスタデータチェック処理(D-6)
   ***********************************************************************************/
  PROCEDURE master_data_chk(
    ir_xxwip_delivery_distance_if IN  xxwip_delivery_distance_if%ROWTYPE, -- 1.xxwip_delivery_distance_ifレコード型
    iv_dump                       IN VARCHAR2,                            -- 2.データダンプ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_category_set          VARCHAR2(50) := 'カテゴリセット名';     -- エラーキー項目：カテゴリセット名
    cv_category_set_name     VARCHAR2(50) := '商品区分';             -- エラーキー項目：商品区分
    cv_delivery_company_code VARCHAR2(50) := '運送業者コード';       -- エラーキー項目：運送業者コード
    cv_item_location_code    VARCHAR2(50) := '保管倉庫コード';       -- エラーキー項目：保管倉庫コード
    cv_vendor_site_code      VARCHAR2(50) := '仕入先サイト名';       -- エラーキー項目：仕入先サイト名
    cv_party_site_number     VARCHAR2(50) := 'サイト番号';           -- エラーキー項目：サイト番号
    cv_lookup_type           VARCHAR2(50) := 'クイックコードタイプ'; -- エラーキー項目：クイックコードタイプ
    cv_lookup_code           VARCHAR2(50) := 'クイックコード';       -- エラーキー項目：クイックコード
    cv_location_id           VARCHAR2(50) := '事業所ID';             -- エラーキー項目：事業所ID
--
    cv_xxcmn_categories_v     VARCHAR2(50) := '品目カテゴリ情報VIEW';         -- エラーテーブル名：品目カテゴリ情報VIEW
    cv_xxwip_delivery_company VARCHAR2(50) := '運賃用運送業者アドオンマスタ'; -- エラーテーブル名：運賃用運送業者アドオンマスタ
    cv_xxcmn_item_locations_v VARCHAR2(50) := 'OPM保管場所情報VIEW';          -- エラーテーブル名：OPM保管場所情報VIEW
    cv_xxcmn_locations_v      VARCHAR2(50) := '事業所情報VIEW';               -- エラーテーブル名：事業所情報VIEW
    cv_xxcmn_lookup_values_v  VARCHAR2(50) := 'クイックコード情報VIEW';       -- エラーテーブル名：クイックコード情報VIEW
    cv_xxcmn_vendor_sites_v   VARCHAR2(50) := '仕入先サイト情報VIEW';         -- エラーテーブル名：仕入先サイト情報VIEW
    cv_xxcmn_party_sites_v    VARCHAR2(50) := 'パーティサイト情報VIEW';       -- エラーテーブル名：パーティサイト情報VIEW
    cv_xxcmn_parties_v        VARCHAR2(50) := 'パーティ情報VIEW';             -- エラーテーブル名：パーティ情報VIEW
--
    -- クイックコード
    cv_xxwip_code_type       VARCHAR2(50) := 'XXWIP_CODE_TYPE';  -- クイックコードタイプ：コード区分
    cv_xxwip_area_a          VARCHAR2(50) := 'XXWIP_AREA_A';     -- クイックコードタイプ：エリアA
    cv_xxwip_area_b          VARCHAR2(50) := 'XXWIP_AREA_B';     -- クイックコードタイプ：エリアB
    cv_xxwip_area_c          VARCHAR2(50) := 'XXWIP_AREA_C';     -- クイックコードタイプ：エリアC
    cv_xxwip_code_type_name  VARCHAR2(50) := 'XXWIP:コード区分'; -- クイックコードタイプ：コード区分
    cv_xxwip_area_a_name     VARCHAR2(50) := 'XXWIP:エリアA';    -- クイックコードタイプ：エリアA
    cv_xxwip_area_b_name     VARCHAR2(50) := 'XXWIP:エリアB';    -- クイックコードタイプ：エリアB
    cv_xxwip_area_c_name     VARCHAR2(50) := 'XXWIP:エリアC';    -- クイックコードタイプ：エリアC
--
    -- *** ローカル変数 ***
    ln_temp                 NUMBER;
    lv_err_tbl              VARCHAR2(50);  -- エラーテーブル名
    lv_err_key              VARCHAR2(2000);-- エラーキー項目
    lt_shipment_management  xxcmn_locations_v.ship_mng_code%TYPE;     -- 出荷管理元区分
    lt_location_id          xxcmn_item_locations_v.location_id%TYPE;  -- 事業所ID
    lt_party_id             hz_party_sites.party_id      %TYPE; -- パーティID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- 内部関数
    -- ===============================
    -- *** 警告エラーメッセージ表投入 ***
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
    -- *** 対象データなしメッセージ取得 *** --
    PROCEDURE get_no_data_msg
    IS
    BEGIN
      -- 対象データなしメッセージ取得
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
    -- *** 出荷管理元区分チェック *** --
    PROCEDURE shipment_management_chk(
      iv_msg     IN VARCHAR2
     ,iv_tkn     IN VARCHAR2  -- トークン
     ,it_value   IN xxcmn_locations_v.location_id%TYPE  -- 値
    )
    IS
    BEGIN
      -- 商品区分が1：リーフかつ、出荷管理元区分が1(出荷管理元リーフ)または、3(出荷管理元・両方)以外はエラー
      IF ((ir_xxwip_delivery_distance_if.goods_classe = gv_goods_classe_reaf)
      AND((lt_shipment_management NOT IN (gv_shipment_management_reaf,gv_shipment_management_both))
      OR  (lt_shipment_management IS NULL)))
      -- 商品区分が2：ドリンクかつ、出荷管理元区分が2(出荷管理元ドリンク)または、3(出荷管理元・両方)以外はエラー
      OR ((ir_xxwip_delivery_distance_if.goods_classe = gv_goods_classe_drink)
      AND((lt_shipment_management NOT IN (gv_shipment_management_drink,gv_shipment_management_both))
      OR  (lt_shipment_management IS NULL)))
      THEN
        -- 出荷管理元区分エラーメッセージ取得
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxwip               -- モジュール名略称：XXWIP 
                     ,iv_msg                 -- メッセージ：APP-XXWIP-10059 出荷管理元区分エラー
                     ,gv_tkn_goods_classe    -- トークン：GOODS_CLASSE
                     ,ir_xxwip_delivery_distance_if.goods_classe             -- 商品区分
                     ,iv_tkn                 -- トークン
                     ,it_value               -- 値
                    ),1,5000);
--
        -- 警告エラーメッセージ表投入
        set_err_msg;
      END IF;
    END shipment_management_chk;
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
    -- 商品区分チェック
    -- ===============================
    -- 品目カテゴリ情報VIEWをチェック
    SELECT COUNT(1) cnt
    INTO   ln_temp
    FROM   xxcmn_categories_v xcv  -- 品目カテゴリ情報VIEW
    WHERE  xcv.category_set_name = cv_category_set_name -- カテゴリセット名
    AND    xcv.segment1          = ir_xxwip_delivery_distance_if.goods_classe      -- 商品区分
    ;
--
    -- データがない場合はエラー
    IF (ln_temp = 0) THEN
       -- エラーテーブル名、エラーキー項目セット
      lv_err_tbl := cv_xxcmn_categories_v; -- エラーテーブル名：商品区分
      lv_err_key := cv_category_set_name || 
                    gv_msg_part          || 
                    ir_xxwip_delivery_distance_if.goods_classe;     -- エラーキー項目 商品区分：goods_classe
--
      -- 対象データなしメッセージ取得
      get_no_data_msg;
    END IF;	
--
    -- ===============================
    -- 運送業者チェック
    -- ===============================
    -- 運賃用運送業者マスタをチェック
    SELECT COUNT(1) cnt
    INTO   ln_temp
    FROM   xxwip_delivery_company xdc  -- 運賃用運送業者マスタ
    WHERE  xdc.goods_classe          = ir_xxwip_delivery_distance_if.goods_classe          -- 商品区分
    AND    xdc.delivery_company_code = ir_xxwip_delivery_distance_if.delivery_company_code -- 運送業者
    AND    xdc.start_date_active    <= TRUNC(SYSDATE)           -- 適用開始日
    AND    xdc.end_date_active      >= TRUNC(SYSDATE)           -- 適用終了日
    ;
--
    -- データがない場合はエラー
    IF (ln_temp = 0) THEN
      -- エラーテーブル名、エラーキー項目セット
      lv_err_tbl := cv_xxwip_delivery_company; -- エラーテーブル名：運賃用運送業者アドオンマスタ
      lv_err_key := cv_category_set_name                       ||
                    gv_msg_part                                ||
                    ir_xxwip_delivery_distance_if.goods_classe ||
                    gv_msg_comma                               ||
                    cv_delivery_company_code                   ||
                    gv_msg_part                                ||
                    ir_xxwip_delivery_distance_if.delivery_company_code ;
                                               -- エラーキー項目 商品区分：goods_classe,運送業者コード：delivery_company_code
--
      -- 対象データなしメッセージ取得
      get_no_data_msg;
    END IF;
--
    -- ===============================
    -- 出庫元チェック
    -- ===============================
    BEGIN
      -- OPM保管場所マスタをチェック
      SELECT xmilv.location_id  -- 事業所ID
      INTO   lt_location_id
      FROM   xxcmn_item_locations_v xmilv                     -- OPM保管場所情報VIEW
      WHERE  xmilv.segment1 = ir_xxwip_delivery_distance_if.origin_shipment -- 出庫元
      ;
--
    EXCEPTION
      -- データがない場合はエラー
      WHEN NO_DATA_FOUND THEN
         -- エラーテーブル名、エラーキー項目セット
        lv_err_tbl := cv_xxcmn_item_locations_v; -- エラーテーブル名：OPM保管場所情報VIEW
        lv_err_key := cv_item_location_code      ||
                      gv_msg_part                ||
                      ir_xxwip_delivery_distance_if.origin_shipment;
                                             -- エラーキー項目 保管場所コード：origin_shipment
--
      -- 対象データなしメッセージ取得
      get_no_data_msg;
    END;
--
    -- ===============================
    -- 出荷管理元区分チェック
    -- ===============================
    BEGIN
      -- 事業所マスタから出荷管理元区分を取得
      SELECT xlv.ship_mng_code shipment_management  -- 出荷管理元区分
      INTO   lt_shipment_management
      FROM   xxcmn_locations_v   xlv                -- 事業所情報VIEW
      WHERE  xlv.location_id = lt_location_id       -- 事業所ID
      ;
--
      -- 出荷管理元区分チェック
      shipment_management_chk(
        iv_msg   => gv_msg_xxxip10059       -- メッセージ：APP-XXWIP-10059 出荷管理元区分エラー
       ,iv_tkn   => gv_tkn_location_id      -- トークン：LOCATION_ID
       ,it_value => lt_location_id          -- 値
      );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN  -- *** データがない場合 ***--
        -- エラーテーブル名、エラーキー項目セット
        lv_err_tbl := cv_xxcmn_locations_v; -- エラーテーブル名：事業所情報VIEW
        lv_err_key := cv_location_id    ||
                      gv_msg_part       ||
                      lt_location_id;
                                           -- エラーキー項目 事業所ID：lt_location_id
--
      -- 対象データなしメッセージ取得
      get_no_data_msg;
    END;
--
    -- ===============================
    -- コード区分チェック
    -- ===============================
    -- クイックコード情報VIEWをチェック
    SELECT COUNT(1) cnt
    INTO   ln_temp
    FROM   xxcmn_lookup_values_v xlvv                                -- クイックコード情報VIEW
    WHERE  lookup_type = cv_xxwip_code_type                          -- クイックコードタイプ：コード区分
    AND    lookup_code = ir_xxwip_delivery_distance_if.code_division -- クイックコード
    ;
--
    -- データがない場合はエラー
    IF (ln_temp = 0) THEN
       -- エラーテーブル名、エラーキー項目セット
      lv_err_tbl := cv_xxcmn_lookup_values_v; -- エラーテーブル名：クイックコード情報VIEW
      lv_err_key := cv_lookup_type              ||
                    gv_msg_part                 ||
                    cv_xxwip_code_type_name     ||
                    gv_msg_comma                ||
                    cv_lookup_code              ||
                    gv_msg_part                 ||
                    ir_xxwip_delivery_distance_if.code_division;
                                              -- エラーキー項目 クイックコードタイプ：cv_xxwip_code_type,クイックコード：code_division
--
      -- 対象データなしメッセージ取得
      get_no_data_msg;
    END IF;
--
    -- 拠点コード初期化
    lt_location_id := NULL;
--
    -- コード区分：1(倉庫)の場合
    IF (ir_xxwip_delivery_distance_if.code_division = gv_code_type_location) THEN
      BEGIN
        -- ===============================
        -- 配送先コードチェック
        -- ===============================
        -- OPM保管場所マスタをチェック
        SELECT xmilv.location_id    -- 事業所ID
        INTO   lt_location_id
        FROM   xxcmn_item_locations_v xmilv                    -- OPM保管場所情報VIEW
        WHERE  xmilv.segment1 = ir_xxwip_delivery_distance_if.shipping_address_code -- 配送先コード
        ;
--
      EXCEPTION
        -- データがない場合はエラー
        WHEN NO_DATA_FOUND THEN
           -- エラーテーブル名、エラーキー項目セット
          lv_err_tbl := cv_xxcmn_item_locations_v; -- エラーテーブル名：OPM保管場所情報VIEW
          lv_err_key := cv_item_location_code      ||
                        gv_msg_part                ||
                        ir_xxwip_delivery_distance_if.shipping_address_code;
                                               -- エラーキー項目 保管場所コード：shipping_address_code
--
        -- 対象データなしメッセージ取得
        get_no_data_msg;
      END;
--
      -- ===============================
      -- 出荷管理元区分チェック
      -- ===============================
      BEGIN
        -- 事業所マスタから出荷管理元区分を取得
        SELECT xlv.ship_mng_code shipment_management -- 出荷管理元区分
        INTO   lt_shipment_management
        FROM   xxcmn_locations_v   xlv               -- 事業所情報VIEW
        WHERE  xlv.location_id = lt_location_id  -- 事業所ID
        ;
--
        -- 出荷管理元区分チェック
      shipment_management_chk(
        iv_msg   => gv_msg_xxxip10059       -- メッセージ：APP-XXWIP-10059 出荷管理元区分エラー
       ,iv_tkn   => gv_tkn_location_id      -- トークン：LOCATION_ID
       ,it_value => lt_location_id          -- 値
      );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  -- *** データがない場合 ***--
          -- エラーテーブル名、エラーキー項目セット
          lv_err_tbl := cv_xxcmn_locations_v; -- エラーテーブル名：事業所情報VIEW
          lv_err_key := cv_location_id      ||
                        gv_msg_part         ||
                        lt_location_id;
                                             -- エラーキー項目 拠点コード：lt_location_code
--
        -- 対象データなしメッセージ取得
        get_no_data_msg;
      END;
--
    -- コード区分：2(取引先)の場合
    ELSIF (ir_xxwip_delivery_distance_if.code_division = gv_code_type_customer) THEN
      -- ===============================
      -- 配送先コードチェック
      -- ===============================
      -- 仕入先サイトマスタをチェック
      SELECT COUNT(1) cnt
      INTO   ln_temp
      FROM   xxcmn_vendor_sites_v xvsv  -- 仕入先サイト情報VIEW
      WHERE  xvsv.vendor_site_code = ir_xxwip_delivery_distance_if.shipping_address_code -- 配送先コード
      ;
--
      -- データがない場合はエラー
      IF (ln_temp = 0) THEN
         -- エラーテーブル名、エラーキー項目セット
        lv_err_tbl := cv_xxcmn_vendor_sites_v; -- エラーテーブル名：仕入先サイト情報VIEW
        lv_err_key := cv_vendor_site_code  ||
                      gv_msg_part          ||
                      ir_xxwip_delivery_distance_if.shipping_address_code;
                                              -- エラーキー項目 仕入先サイト名：shipping_address_code
--
        -- 対象データなしメッセージ取得
        get_no_data_msg;
      END IF;
--
    -- コード区分：3(配送先)の場合
    ELSIF (ir_xxwip_delivery_distance_if.code_division = gv_code_type_delivery) THEN
      -- ===============================
      -- 配送先コードチェック
      -- ===============================
      BEGIN
        -- パーティサイトマスタをチェック
        SELECT xpsv.party_id   party_id  -- パーティID
        INTO   lt_party_id
        FROM   xxcmn_party_sites_v xpsv -- パーティサイト情報VIEW
        WHERE  xpsv.party_site_number  = ir_xxwip_delivery_distance_if.shipping_address_code -- 配送先コード
        ;
--
        -- データがない場合はエラー
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           -- エラーテーブル名、エラーキー項目セット
          lv_err_tbl := cv_xxcmn_party_sites_v; -- エラーテーブル名：パーティサイト情報VIEW
          lv_err_key := cv_party_site_number       ||
                        gv_msg_part                ||
                        ir_xxwip_delivery_distance_if.shipping_address_code;
                                                -- エラーキー項目 サイト番号：shipping_address_code
--
        -- 対象データなしメッセージ取得
        get_no_data_msg;
      END;
--
-- 2008/09/02 v1.1 UPDATE START
/*
      -- ===============================
      -- 出荷管理元区分チェック
      -- ===============================
      BEGIN
        -- 出荷管理元区分を取得
        SELECT xpv.ship_mng_code shipment_management -- 出荷管理元区分
        INTO   lt_shipment_management
        FROM   xxcmn_parties_v xpv                -- パーティ情報VIEW
        WHERE  xpv.party_id = lt_party_id         -- パーティID
        ;
--
        -- 出荷管理元区分チェック
        shipment_management_chk(
          iv_msg   => gv_msg_xxxip10060       -- メッセージ：APP-XXWIP-10060 出荷管理元区分エラー(配送先)
         ,iv_tkn   => gv_tkn_party_site_number-- トークン：PARTY_SITE_NUMBER
         ,it_value => ir_xxwip_delivery_distance_if.shipping_address_code        -- 値
        );
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  -- *** データがない場合 ***--
          -- エラーテーブル名、エラーキー項目セット
          lv_err_tbl := cv_xxcmn_parties_v; -- エラーテーブル名：パーティ情報VIEW
          lv_err_key := cv_party_site_number   ||
                        gv_msg_part            ||
                        ir_xxwip_delivery_distance_if.shipping_address_code;
                                             -- エラーキー項目 サイト番号：shipping_address_code
--
        -- 対象データなしメッセージ取得
        get_no_data_msg;
      END;
*/
-- 2008/09/02 v1.1 UPDATE END
    END IF;
--
    -- ===============================
    -- エリアAチェック
    -- ===============================
    IF (ir_xxwip_delivery_distance_if.area_a IS NOT NULL) THEN
      -- クイックコード情報VIEWをチェック
      SELECT COUNT(1) cnt
      INTO   ln_temp
      FROM   xxcmn_lookup_values_v xlvv                         -- クイックコード情報VIEW
      WHERE  lookup_type = cv_xxwip_area_a                      -- クイックコードタイプ：エリアA
      AND    lookup_code = ir_xxwip_delivery_distance_if.area_a -- クイックコード
      ;
--
      -- データがない場合はエラー
      IF (ln_temp = 0) THEN
         -- エラーテーブル名、エラーキー項目セット
        lv_err_tbl := cv_xxcmn_lookup_values_v; -- エラーテーブル名：クイックコード情報VIEW
        lv_err_key := cv_lookup_type       ||
                      gv_msg_part          ||
                      cv_xxwip_area_a_name ||
                      gv_msg_comma         ||
                      cv_lookup_code       ||
                      gv_msg_part          ||
                      ir_xxwip_delivery_distance_if.area_a;
                                                -- エラーキー項目 クイックコードタイプ：cv_xxwip_area_a,クイックコード：area_a
--
        -- 対象データなしメッセージ取得
        get_no_data_msg;
      END IF;
    END IF;
--
    -- ===============================
    -- エリアBチェック
    -- ===============================
    IF (ir_xxwip_delivery_distance_if.area_b IS NOT NULL) THEN
      -- クイックコード情報VIEWをチェック
      SELECT COUNT(1) cnt
      INTO   ln_temp
      FROM   xxcmn_lookup_values_v xlvv                         -- クイックコード情報VIEW
      WHERE  lookup_type = cv_xxwip_area_b                      -- クイックコードタイプ：エリアB
      AND    lookup_code = ir_xxwip_delivery_distance_if.area_b -- クイックコード
      ;
--
      -- データがない場合はエラー
      IF (ln_temp = 0) THEN
         -- エラーテーブル名、エラーキー項目セット
        lv_err_tbl := cv_xxcmn_lookup_values_v; -- エラーテーブル名：クイックコード情報VIEW
        lv_err_key := cv_lookup_type         ||
                      gv_msg_part            ||
                      cv_xxwip_area_b_name   ||
                      gv_msg_comma           ||
                      cv_lookup_code         ||
                      gv_msg_part            ||
                      ir_xxwip_delivery_distance_if.area_b;
                                                -- エラーキー項目 クイックコードタイプ：cv_xxwip_area_b,クイックコード：area_b
--
        -- 対象データなしメッセージ取得
        get_no_data_msg;
      END IF;
    END IF;
--
    -- ===============================
    -- エリアCチェック
    -- ===============================
    IF (ir_xxwip_delivery_distance_if.area_c IS NOT NULL) THEN
      -- クイックコード情報VIEWをチェック
      SELECT COUNT(1) cnt
      INTO   ln_temp
      FROM   xxcmn_lookup_values_v xlvv                         -- クイックコード情報VIEW
      WHERE  lookup_type = cv_xxwip_area_c                      -- クイックコードタイプ：エリアC
      AND    lookup_code = ir_xxwip_delivery_distance_if.area_c -- クイックコード
      ;
--
      -- データがない場合はエラー
      IF (ln_temp = 0) THEN
         -- エラーテーブル名、エラーキー項目セット
        lv_err_tbl := cv_xxcmn_lookup_values_v; -- エラーテーブル名：クイックコード情報VIEW
        lv_err_key := cv_lookup_type         ||
                      gv_msg_part            ||
                      cv_xxwip_area_c_name   ||
                      gv_msg_comma           ||
                      cv_lookup_code         ||
                      gv_msg_part            ||
                      ir_xxwip_delivery_distance_if.area_c;
                                                -- エラーキー項目 クイックコードタイプ：cv_xxwip_area_c,クイックコード：area_c
--
        -- 対象データなしメッセージ取得
        get_no_data_msg;
      END IF;
    END IF;
--
    -- ===============================
    -- OUTパラメータセット
    -- ===============================
    ov_retcode := lv_retcode;
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
   * Description      : 登録用PL/SQL表投入(D-7)
   ***********************************************************************************/
  PROCEDURE set_ins_tab(
    ir_xxwip_delivery_distance_if IN  xxwip_delivery_distance_if%ROWTYPE,  -- 1.xxwip_delivery_distance_ifレコード型
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
    -- 値セット
    SELECT xxwip_delivery_distance_id_s1.NEXTVAL
    INTO   delivery_distance_id_ins_tab(gn_ins_tab_cnt)  -- 配送距離ID
    FROM   DUAL;
    goods_classe_ins_tab(gn_ins_tab_cnt)           := ir_xxwip_delivery_distance_if.goods_classe;           -- 商品区分
    delivery_company_code_ins_tab(gn_ins_tab_cnt) := ir_xxwip_delivery_distance_if.delivery_company_code;  -- 運送業者コード
    origin_shipment_ins_tab(gn_ins_tab_cnt)        := ir_xxwip_delivery_distance_if.origin_shipment;        -- 出庫元
    code_division_ins_tab(gn_ins_tab_cnt)          := ir_xxwip_delivery_distance_if.code_division;          -- コード区分
    shipping_address_code_ins_tab(gn_ins_tab_cnt)  := ir_xxwip_delivery_distance_if.shipping_address_code;  -- 配送先コード
    start_date_active_ins_tab(gn_ins_tab_cnt)      := ir_xxwip_delivery_distance_if.start_date_active;      -- 適用開始日
    post_distance_ins_tab(gn_ins_tab_cnt)          := ir_xxwip_delivery_distance_if.post_distance;          -- 車立距離
    small_distance_ins_tab(gn_ins_tab_cnt)         := ir_xxwip_delivery_distance_if.small_distance;         -- 小口距離
    consolid_add_dist_ins_tab(gn_ins_tab_cnt)      := ir_xxwip_delivery_distance_if.consolid_add_distance;  -- 混載割増距離
    actual_distance_ins_tab(gn_ins_tab_cnt)        := ir_xxwip_delivery_distance_if.actual_distance;        -- 実際距離
    area_a_ins_tab(gn_ins_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_a;                 -- エリアA
    area_b_ins_tab(gn_ins_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_b;                 -- エリアB
    area_c_ins_tab(gn_ins_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_c;                 -- エリアC
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
   * Description      : 更新用PL/SQL表投入(D-9)
   ***********************************************************************************/
  PROCEDURE set_upd_tab(
    ir_xxwip_delivery_distance_if IN  xxwip_delivery_distance_if%ROWTYPE,  -- 1.xxwip_delivery_distance_ifレコード型
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
    -- 更新用件数カウント
    gn_upd_tab_cnt := gn_upd_tab_cnt + 1;
--
    -- 値セット
    goods_classe_upd_tab(gn_upd_tab_cnt)           := ir_xxwip_delivery_distance_if.goods_classe;           -- 商品区分
    delivery_company_code_upd_tab(gn_upd_tab_cnt) := ir_xxwip_delivery_distance_if.delivery_company_code;  -- 運送業者コード
    origin_shipment_upd_tab(gn_upd_tab_cnt)        := ir_xxwip_delivery_distance_if.origin_shipment;        -- 出庫元
    code_division_upd_tab(gn_upd_tab_cnt)          := ir_xxwip_delivery_distance_if.code_division;          -- コード区分
    shipping_address_code_upd_tab(gn_upd_tab_cnt)  := ir_xxwip_delivery_distance_if.shipping_address_code;  -- 配送先コード
    start_date_active_upd_tab(gn_upd_tab_cnt)      := ir_xxwip_delivery_distance_if.start_date_active;      -- 適用開始日
    post_distance_upd_tab(gn_upd_tab_cnt)          := ir_xxwip_delivery_distance_if.post_distance;          -- 車立距離
    small_distance_upd_tab(gn_upd_tab_cnt)         := ir_xxwip_delivery_distance_if.small_distance;         -- 小口距離
    consolid_add_dist_upd_tab(gn_upd_tab_cnt)      := ir_xxwip_delivery_distance_if.consolid_add_distance;  -- 混載割増距離
    actual_distance_upd_tab(gn_upd_tab_cnt)        := ir_xxwip_delivery_distance_if.actual_distance;        -- 実際距離
    area_a_upd_tab(gn_upd_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_a;                 -- エリアA
    area_b_upd_tab(gn_upd_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_b;                 -- エリアB
    area_c_upd_tab(gn_upd_tab_cnt)                 := ir_xxwip_delivery_distance_if.area_c;                 -- エリアC
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
  /**********************************************************************************
   * Procedure Name   : get_ins_data
   * Description      : 登録データ取得処理(D-5)
   ***********************************************************************************/
  PROCEDURE get_ins_data(
    it_request_id IN  xxwip_delivery_distance_if.request_id%TYPE,            -- 1.要求ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ins_data'; -- プログラム名
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
    lr_xxwip_delivery_distance_if  xxwip_delivery_distance_if%ROWTYPE; -- xxwip_delivery_distance_ifレコード型
    lv_dump   VARCHAR2(5000); -- データダンプ
--
    -- *** ローカル・カーソル ***
    -- 配送距離アドオンマスタインタフェース登録カーソル
    CURSOR xddi_ins_cur 
    IS
      SELECT xddi.goods_classe                goods_classe                 -- 商品区分
            ,xddi.delivery_company_code       delivery_company_code        -- 運送業者コード
            ,xddi.origin_shipment             origin_shipment              -- 出庫元
            ,xddi.area_a                      area_a                       -- エリアA
            ,xddi.area_b                      area_b                       -- エリアB
            ,xddi.area_c                      area_c                       -- エリアC
            ,xddi.code_division               code_division                -- コード区分
            ,xddi.shipping_address_code       shipping_address_code        -- 配送先コード
            ,xddi.start_date_active           start_date_active            -- 適用開始日
            ,xddi.post_distance               post_distance                -- 車立距離
            ,xddi.small_distance              small_distance               -- 小口距離
            ,xddi.consolid_add_distance       consolid_add_distance        -- 混載割増距離
            ,xddi.actual_distance             actual_distance              -- 実際距離
      FROM   xxwip_delivery_distance_if  xddi        -- 配送距離アドオンマスタインタフェース
      WHERE  xddi.request_id = it_request_id         -- 要求ID
-- v1.3 ADD START
      AND    xddi.goods_classe = gv_prod_div         -- 商品区分
-- v1.3 ADD END
      AND    NOT EXISTS(                             -- 配送距離アドオンマスタのキー項目に存在しないデータ
             SELECT 1
             FROM   xxwip_delivery_distance   xdd    -- 配送距離アドオンマスタ
             WHERE  xdd.goods_classe           = xddi.goods_classe          -- 商品区分
             AND    xdd.delivery_company_code  = xddi.delivery_company_code -- 運送業者コード
             AND    xdd.origin_shipment        = xddi.origin_shipment       -- 出庫元
             AND    xdd.start_date_active      = xddi.start_date_active     -- 適用開始日
             AND    xdd.code_division          = xddi.code_division         -- コード区分
             AND    xdd.shipping_address_code  = xddi.shipping_address_code -- 配送先コード
             )
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
    -- =============================
    -- 登録データ取得
    -- =============================
    -- 配送距離アドオンマスタインタフェースカーソル
    <<xddi_ins_loop>>
    FOR lr_xddi_ins IN xddi_ins_cur LOOP
      -- レコードにデータセット
      lr_xxwip_delivery_distance_if.goods_classe           := lr_xddi_ins.goods_classe;                 -- 商品区分
      lr_xxwip_delivery_distance_if.delivery_company_code  := lr_xddi_ins.delivery_company_code;        -- 運送業者コード
      lr_xxwip_delivery_distance_if.origin_shipment        := lr_xddi_ins.origin_shipment;              -- 出庫元
      lr_xxwip_delivery_distance_if.area_a                 := lr_xddi_ins.area_a;                       -- エリアA
      lr_xxwip_delivery_distance_if.area_b                 := lr_xddi_ins.area_b;                       -- エリアB
      lr_xxwip_delivery_distance_if.area_c                 := lr_xddi_ins.area_c;                       -- エリアC
      lr_xxwip_delivery_distance_if.code_division          := lr_xddi_ins.code_division;                -- コード区分
      lr_xxwip_delivery_distance_if.shipping_address_code  := lr_xddi_ins.shipping_address_code;        -- 配送先コード
      lr_xxwip_delivery_distance_if.start_date_active      := lr_xddi_ins.start_date_active;            -- 適用開始日
      lr_xxwip_delivery_distance_if.post_distance          := lr_xddi_ins.post_distance;                -- 車立距離
      lr_xxwip_delivery_distance_if.small_distance         := lr_xddi_ins.small_distance;               -- 小口距離
      lr_xxwip_delivery_distance_if.consolid_add_distance  := lr_xddi_ins.consolid_add_distance;        -- 混載割増距離
      lr_xxwip_delivery_distance_if.actual_distance        := lr_xddi_ins.actual_distance;              -- 実際距離
--
      -- ===============================
      -- D-4.データダンプ取得処理
      -- ===============================
      get_data_dump(
        ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if -- 1.xxwip_delivery_distance_ifレコード型
       ,ov_dump    => lv_dump            -- 1.データダンプ文字列
       ,ov_errbuf  => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =============================
      -- D-6.マスタデータチェック処理
      -- =============================
      master_data_chk(
        ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if   -- 1.xxwip_delivery_distance_ifレコード型
       ,iv_dump                       => lv_dump                         -- 2.データダンプ
       ,ov_errbuf  => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
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
        -- D-7.登録用PL/SQL表投入
        -- =============================
        set_ins_tab(
          ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if   -- 1.xxwip_delivery_distance_ifレコード型
         ,ov_errbuf  => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 正常の場合
        ELSIF (lv_retcode = gv_status_normal) THEN
          -- 正常データ件数
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- 正常データダンプPL/SQL表投入
          normal_dump_tab(gn_normal_cnt) := lv_dump;
        END IF;
      END IF;
    END LOOP xddi_ins_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (xddi_ins_cur%ISOPEN) THEN
        CLOSE xddi_ins_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (xddi_ins_cur%ISOPEN) THEN
        CLOSE xddi_ins_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xddi_ins_cur%ISOPEN) THEN
        CLOSE xddi_ins_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xddi_ins_cur%ISOPEN) THEN
        CLOSE xddi_ins_cur;
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
   * Description      : 更新データ取得処理(D-8)
   ***********************************************************************************/
  PROCEDURE get_upd_data(
    it_request_id IN  xxwip_delivery_distance_if.request_id%TYPE,            -- 1.要求ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upd_data'; -- プログラム名
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
    lr_xxwip_delivery_distance_if  xxwip_delivery_distance_if%ROWTYPE; -- xxwip_delivery_distance_ifレコード型
    lv_dump   VARCHAR2(5000); -- データダンプ
--
    -- *** ローカル・カーソル ***
    -- 配送距離アドオンマスタインタフェース登録カーソル
    CURSOR xddi_upd_cur 
    IS
      SELECT xddi.goods_classe                goods_classe                 -- 商品区分
            ,xddi.delivery_company_code       delivery_company_code        -- 運送業者コード
            ,xddi.origin_shipment             origin_shipment              -- 出庫元
            ,xddi.area_a                      area_a                       -- エリアA
            ,xddi.area_b                      area_b                       -- エリアB
            ,xddi.area_c                      area_c                       -- エリアC
            ,xddi.code_division               code_division                -- コード区分
            ,xddi.shipping_address_code       shipping_address_code        -- 配送先コード
            ,xddi.start_date_active           start_date_active            -- 適用開始日
            ,xddi.post_distance               post_distance                -- 車立距離
            ,xddi.small_distance              small_distance               -- 小口距離
            ,xddi.consolid_add_distance       consolid_add_distance        -- 混載割増距離
            ,xddi.actual_distance             actual_distance              -- 実際距離
      FROM   xxwip_delivery_distance_if  xddi        -- 配送距離アドオンマスタインタフェース
      WHERE  xddi.request_id = it_request_id         -- 要求ID
-- v1.3 ADD START
      AND    xddi.goods_classe = gv_prod_div         -- 商品区分
-- v1.3 ADD END
      AND    EXISTS(                                 -- 配送距離アドオンマスタのキー項目に存在するデータ
             SELECT 1
             FROM   xxwip_delivery_distance   xdd    -- 配送距離アドオンマスタ
             WHERE  xdd.goods_classe           = xddi.goods_classe          -- 商品区分
             AND    xdd.delivery_company_code  = xddi.delivery_company_code -- 運送業者コード
             AND    xdd.origin_shipment        = xddi.origin_shipment       -- 出庫元
             AND    xdd.start_date_active      = xddi.start_date_active     -- 適用開始日
             AND    xdd.code_division          = xddi.code_division         -- コード区分
             AND    xdd.shipping_address_code  = xddi.shipping_address_code -- 配送先コード
             )
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
    -- =============================
    -- 更新データ取得
    -- =============================
    -- 配送距離アドオンマスタインタフェースカーソル
    <<xddi_upd_loop>>
    FOR lr_xddi_upd IN xddi_upd_cur LOOP
      -- レコードにデータセット
      lr_xxwip_delivery_distance_if.goods_classe           := lr_xddi_upd.goods_classe;                 -- 商品区分
      lr_xxwip_delivery_distance_if.delivery_company_code  := lr_xddi_upd.delivery_company_code;        -- 運送業者コード
      lr_xxwip_delivery_distance_if.origin_shipment        := lr_xddi_upd.origin_shipment;              -- 出庫元
      lr_xxwip_delivery_distance_if.area_a                 := lr_xddi_upd.area_a;                       -- エリアA
      lr_xxwip_delivery_distance_if.area_b                 := lr_xddi_upd.area_b;                       -- エリアB
      lr_xxwip_delivery_distance_if.area_c                 := lr_xddi_upd.area_c;                       -- エリアC
      lr_xxwip_delivery_distance_if.code_division          := lr_xddi_upd.code_division;                -- コード区分
      lr_xxwip_delivery_distance_if.shipping_address_code  := lr_xddi_upd.shipping_address_code;        -- 配送先コード
      lr_xxwip_delivery_distance_if.start_date_active      := lr_xddi_upd.start_date_active;            -- 適用開始日
      lr_xxwip_delivery_distance_if.post_distance          := lr_xddi_upd.post_distance;                -- 車立距離
      lr_xxwip_delivery_distance_if.small_distance         := lr_xddi_upd.small_distance;               -- 小口距離
      lr_xxwip_delivery_distance_if.consolid_add_distance  := lr_xddi_upd.consolid_add_distance;        -- 混載割増距離
      lr_xxwip_delivery_distance_if.actual_distance        := lr_xddi_upd.actual_distance;              -- 実際距離
--
      -- ===============================
      -- D-4.データダンプ取得処理
      -- ===============================
      get_data_dump(
        ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if -- 1.xxwip_delivery_distance_ifレコード型
       ,ov_dump    => lv_dump            -- 1.データダンプ文字列
       ,ov_errbuf  => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =============================
      -- D-6.マスタデータチェック処理
      -- =============================
      master_data_chk(
        ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if   -- 1.xxwip_delivery_distance_ifレコード型
       ,iv_dump                       => lv_dump                         -- 2.データダンプ
       ,ov_errbuf  => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- 警告の場合
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- OUTパラメータに警告をセット
        ov_retcode := gv_status_warn;
--
        -- スキップ件数カウント
        gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- 正常の場合
      ELSE
        -- =============================
        -- D-9.更新用PL/SQL表投入
        -- =============================
        set_upd_tab(
          ir_xxwip_delivery_distance_if => lr_xxwip_delivery_distance_if   -- 1.xxwip_delivery_distance_ifレコード型
         ,ov_errbuf  => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- 正常の場合
        ELSIF (lv_retcode = gv_status_normal) THEN
          -- 正常データ件数
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- 正常データダンプPL/SQL表投入
          normal_dump_tab(gn_normal_cnt) := lv_dump;
        END IF;
      END IF;
    END LOOP xddi_upd_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (xddi_upd_cur%ISOPEN) THEN
        CLOSE xddi_upd_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (xddi_upd_cur%ISOPEN) THEN
        CLOSE xddi_upd_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xddi_upd_cur%ISOPEN) THEN
        CLOSE xddi_upd_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xddi_upd_cur%ISOPEN) THEN
        CLOSE xddi_upd_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_upd_data;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_table_batch
   * Description      : 一括登録処理(D-10)
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
    FORALL ln_cnt_loop IN 1 .. delivery_distance_id_ins_tab.COUNT
      INSERT INTO xxwip_delivery_distance  xdd   -- 配送距離アドオンマスタ
        (xdd.delivery_distance_id   -- 配送距離ID
        ,xdd.goods_classe           -- 商品区分
        ,xdd.delivery_company_code  -- 運送業者コード
        ,xdd.origin_shipment        -- 出庫元
        ,xdd.code_division          -- コード区分
        ,xdd.shipping_address_code  -- 配送先コード
        ,xdd.start_date_active      -- 適用開始日
        ,xdd.post_distance          -- 車立距離
        ,xdd.small_distance         -- 小口距離
        ,xdd.consolid_add_distance  -- 混載割増距離
        ,xdd.actual_distance        -- 実際距離
        ,xdd.area_a                 -- エリアA
        ,xdd.area_b                 -- エリアB
        ,xdd.area_c                 -- エリアC
        ,xdd.created_by             -- 作成者
        ,xdd.creation_date          -- 作成日
        ,xdd.last_updated_by        -- 最終更新者
        ,xdd.last_update_date       -- 最終更新日
        ,xdd.last_update_login      -- 最終更新ログイン
        ,xdd.request_id             -- 要求ID
        ,xdd.program_application_id -- コンカレント・プログラム・アプリケーションID
        ,xdd.program_id             -- コンカレント・プログラムID
        ,xdd.program_update_date    -- プログラム更新日
        )
      VALUES
        (delivery_distance_id_ins_tab(ln_cnt_loop)    -- 配送距離ID
        ,goods_classe_ins_tab(ln_cnt_loop)            -- 商品区分
        ,delivery_company_code_ins_tab(ln_cnt_loop)  -- 運送業者コード
        ,origin_shipment_ins_tab(ln_cnt_loop)         -- 出庫元
        ,code_division_ins_tab(ln_cnt_loop)           -- コード区分
        ,shipping_address_code_ins_tab(ln_cnt_loop)   -- 配送先コード
        ,start_date_active_ins_tab(ln_cnt_loop)       -- 適用開始日
        ,NVL(post_distance_ins_tab(ln_cnt_loop),0)    -- 車立距離
        ,NVL(small_distance_ins_tab(ln_cnt_loop),0)   -- 小口距離
        ,NVL(consolid_add_dist_ins_tab(ln_cnt_loop),0)-- 混載割増距離
        ,NVL(actual_distance_ins_tab(ln_cnt_loop),0)  -- 実際距離
        ,area_a_ins_tab(ln_cnt_loop)                  -- エリアA
        ,area_b_ins_tab(ln_cnt_loop)                  -- エリアB
        ,area_c_ins_tab(ln_cnt_loop)                  -- エリアC
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
  END ins_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : upd_table_batch
   * Description      : 一括更新処理(D-11)
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
    <<upd_table_batch_loop>>
    FORALL ln_cnt_loop IN 1 .. delivery_company_code_upd_tab.COUNT
      UPDATE xxwip_delivery_distance  xdd   -- 配送距離アドオンマスタ
      SET    xdd.post_distance          = NVL(post_distance_upd_tab(ln_cnt_loop),0)    -- 車立距離
            ,xdd.small_distance         = NVL(small_distance_upd_tab(ln_cnt_loop),0)   -- 小口距離
            ,xdd.consolid_add_distance  = NVL(consolid_add_dist_upd_tab(ln_cnt_loop),0)-- 混載割増距離
            ,xdd.actual_distance        = NVL(actual_distance_upd_tab(ln_cnt_loop),0)  -- 実際距離
            ,xdd.area_a                 = area_a_upd_tab(ln_cnt_loop)                  -- エリアA
            ,xdd.area_b                 = area_b_upd_tab(ln_cnt_loop)                  -- エリアB
            ,xdd.area_c                 = area_c_upd_tab(ln_cnt_loop)                  -- エリアC
-- 2009/04/03 v1.2 ADD START
            ,xdd.change_flg             = gv_on                                        -- 変更フラグ
-- 2009/04/03 v1.2 ADD END
            ,xdd.last_updated_by        = FND_GLOBAL.USER_ID                           -- 最終更新者
            ,xdd.last_update_date       = SYSDATE                                      -- 最終更新日
            ,xdd.last_update_login      = FND_GLOBAL.LOGIN_ID                          -- 最終更新ログイン
            ,xdd.request_id             = FND_GLOBAL.CONC_REQUEST_ID                   -- 要求ID
            ,xdd.program_application_id = FND_GLOBAL.PROG_APPL_ID                      -- コンカレント・プログラム・アプリケーションID
            ,xdd.program_id             = FND_GLOBAL.CONC_PROGRAM_ID                   -- コンカレント・プログラムID
            ,xdd.program_update_date    = SYSDATE                                      -- プログラム更新日
      WHERE xdd.goods_classe            = goods_classe_upd_tab(ln_cnt_loop)            -- 商品区分
      AND   xdd.delivery_company_code   = delivery_company_code_upd_tab(ln_cnt_loop)  -- 運送業者コード
      AND   xdd.origin_shipment         = origin_shipment_upd_tab(ln_cnt_loop)         -- 出庫元
      AND   xdd.code_division           = code_division_upd_tab(ln_cnt_loop)           -- コード区分
      AND   xdd.shipping_address_code   = shipping_address_code_upd_tab(ln_cnt_loop)   -- 配送先コード
      AND   xdd.start_date_active       = start_date_active_upd_tab(ln_cnt_loop)       -- 適用開始日
      ;
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
  END upd_table_batch;
--
  /************************************************************************
   * Procedure Name  : update_end_date_active_all
   * Description     : 適用終了日更新処理(D-12)
   ************************************************************************/
  PROCEDURE update_end_date_active_all(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_end_date_active_all'; -- プログラム名
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
    cv_xxcmn_max_date          VARCHAR2(50) := 'XXCMN_MAX_DATE';           -- プロファイルオプション：MAX日付
    cv_xxcmn_max_date_name     VARCHAR2(50) := 'XXCMN:MAX日付';            -- プロファイルオプション：MAX日付
    cv_xxwip_delivery_distance VARCHAR2(50) := 'XXWIP_DELIVERY_DISTANCE';  -- 配送距離アドオンマスタ
--
    -- *** ローカル変数 ***

    lt_max_date                     fnd_profile_option_values.profile_option_value%TYPE;  -- MAX日付
    ld_max_date                     DATE;
    ln_count                        NUMBER DEFAULT 0;
--
    -- 比較用変数
    lt_temp_goods_classe           xxwip_delivery_distance.goods_classe         %TYPE; -- 商品区分
    lt_temp_delivery_company_code  xxwip_delivery_distance.delivery_company_code%TYPE; -- 運送業者コード
    lt_temp_origin_shipment        xxwip_delivery_distance.origin_shipment      %TYPE; -- 出庫元
    lt_temp_code_division          xxwip_delivery_distance.code_division        %TYPE; -- コード区分
    lt_temp_shipping_address_code  xxwip_delivery_distance.shipping_address_code%TYPE; -- 配送先コード
    lt_temp_start_date_active      xxwip_delivery_distance.start_date_active    %TYPE; -- 適用開始日
    lt_temp_end_date_active        xxwip_delivery_distance.end_date_active      %TYPE; -- 適用終了日
--
    -- 更新用PL/SQL表型
    goods_classe_tab           goods_classe_ttype;          -- 商品区分
    delivery_company_code_tab  delivery_company_code_ttype; -- 運送業者コード
    origin_shipment_tab        origin_shipment_ttype;       -- 出庫元
    code_division_tab          code_division_ttype;         -- コード区分
    shipping_address_code_tab  shipping_address_code_ttype; -- 配送先コード
    start_date_active_tab      start_date_active_ttype;     -- 適用開始日
    end_date_active_tab        end_date_active_ttype;       -- 適用終了日
--
    -- *** ローカル・カーソル ***
    -- 配送距離アドオンマスタカーソル
    CURSOR xxwip_delivery_distance_cur
    IS
      SELECT xdd.goods_classe          goods_classe          -- 商品区分
            ,xdd.delivery_company_code delivery_company_code -- 運送業者コード
            ,xdd.origin_shipment       origin_shipment       -- 出庫元
            ,xdd.code_division         code_division         -- コード区分
            ,xdd.shipping_address_code shipping_address_code -- 配送先コード
            ,xdd.start_date_active     start_date_active     -- 適用開始日
            ,xdd.end_date_active       end_date_active       -- 適用終了日
      FROM   xxwip_delivery_distance  xdd
-- v1.3 ADD START
      WHERE  xdd.goods_classe       =  gv_prod_div           -- 商品区分
-- v1.3 ADD END
      ORDER BY
             goods_classe          -- 商品区分
            ,delivery_company_code -- 運送業者コード
            ,origin_shipment       -- 出庫元
            ,code_division         -- コード区分
            ,shipping_address_code -- 配送先コード
            ,start_date_active     -- 適用開始日
      ;
--
    xxwip_delivery_distance_rec  xxwip_delivery_distance_cur%ROWTYPE;
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================
    -- MAX日付取得
    -- ====================================
    lt_max_date := FND_PROFILE.VALUE(cv_xxcmn_max_date);
--
    -- 取得できなかった場合はエラー
    IF (lt_max_date IS NULL) THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn               -- モジュール名略称：XXCMN 共通
                   ,gv_msg_xxcmn10002      -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                   ,gv_tkn_ng_profile      -- トークン：NGプロファイル名
                   ,cv_xxcmn_max_date_name -- MAX日付
                   ),1,5000);
--
      RAISE global_process_expt;
    END IF;
    -- 日付型に変換
    ld_max_date := FND_DATE.STRING_TO_DATE( lt_max_date, 'YYYY/MM/DD' );
--
    -- ====================================
    -- 配送距離アドオンマスタカーソルOPEN
    -- ====================================
    OPEN xxwip_delivery_distance_cur;
    FETCH xxwip_delivery_distance_cur INTO xxwip_delivery_distance_rec;
--
    -- データが存在する場合は処理を行う
    IF ( xxwip_delivery_distance_cur%FOUND ) THEN
--
      -- ====================================
      -- 値をTEMP変数にセット
      -- ====================================
      lt_temp_goods_classe          := xxwip_delivery_distance_rec.goods_classe;           -- 商品区分
      lt_temp_delivery_company_code := xxwip_delivery_distance_rec.delivery_company_code;  -- 運送業者コード
      lt_temp_origin_shipment       := xxwip_delivery_distance_rec.origin_shipment;        -- 出庫元
      lt_temp_code_division         := xxwip_delivery_distance_rec.code_division;          -- コード区分
      lt_temp_shipping_address_code := xxwip_delivery_distance_rec.shipping_address_code;  -- 配送先コード
      lt_temp_start_date_active     := xxwip_delivery_distance_rec.start_date_active;      -- 適用開始日
      lt_temp_end_date_active       := xxwip_delivery_distance_rec.end_date_active;        -- 適用終了日
--
      <<xxwip_delivery_distance_loop>>
      LOOP
        FETCH xxwip_delivery_distance_cur INTO xxwip_delivery_distance_rec;
        EXIT WHEN xxwip_delivery_distance_cur%NOTFOUND;
--
        -- ====================================
        -- 適用終了日セット
        -- ====================================
        -- キーブレイク時
        IF (lt_temp_goods_classe          <> xxwip_delivery_distance_rec.goods_classe)           -- 商品区分
        OR (lt_temp_delivery_company_code <> xxwip_delivery_distance_rec.delivery_company_code)  -- 運送業者コード
        OR (lt_temp_origin_shipment       <> xxwip_delivery_distance_rec.origin_shipment)        -- 出庫元
        OR (lt_temp_code_division         <> xxwip_delivery_distance_rec.code_division)          -- コード区分
        OR (lt_temp_shipping_address_code <> xxwip_delivery_distance_rec.shipping_address_code)  -- 配送先コード
        THEN
          -- 正しい適用終了日でない場合
          IF ((lt_temp_end_date_active IS NULL)
          OR  (lt_temp_end_date_active <> ld_max_date))
          THEN
            -- MAX日付を前レコードの適用終了日にセット
            ln_count := ln_count + 1;
            goods_classe_tab(ln_count)          := lt_temp_goods_classe;          -- 商品区分
            delivery_company_code_tab(ln_count) := lt_temp_delivery_company_code; -- 運送業者コード
            origin_shipment_tab(ln_count)       := lt_temp_origin_shipment;       -- 出庫元
            code_division_tab(ln_count)         := lt_temp_code_division;         -- コード区分
            shipping_address_code_tab(ln_count) := lt_temp_shipping_address_code; -- 配送先コード
            start_date_active_tab(ln_count)     := lt_temp_start_date_active;     -- 適用開始日
            end_date_active_tab(ln_count)       := ld_max_date;                   -- 適用終了日
--
          END IF;
--
        -- キーがブレイクしていない場合
        ELSE
          IF ((lt_temp_end_date_active IS NULL)
          OR  (lt_temp_end_date_active <> xxwip_delivery_distance_rec.start_date_active - 1))
          THEN
            -- 現レコードの適用開始日－1日を前レコードの適用終了日にセット
            ln_count := ln_count + 1;
            goods_classe_tab(ln_count)          := lt_temp_goods_classe;          -- 商品区分
            delivery_company_code_tab(ln_count) := lt_temp_delivery_company_code; -- 運送業者コード
            origin_shipment_tab(ln_count)       := lt_temp_origin_shipment;       -- 出庫元
            code_division_tab(ln_count)         := lt_temp_code_division;         -- コード区分
            shipping_address_code_tab(ln_count) := lt_temp_shipping_address_code; -- 配送先コード
            start_date_active_tab(ln_count)     := lt_temp_start_date_active;     -- 適用開始日
            end_date_active_tab(ln_count)       := xxwip_delivery_distance_rec.start_date_active - 1 ;-- 適用終了日
--
          END IF;
        END IF;
--
        -- ====================================
        -- 値をTEMP変数にセット
        -- ====================================
        lt_temp_goods_classe          := xxwip_delivery_distance_rec.goods_classe;           -- 商品区分
        lt_temp_delivery_company_code := xxwip_delivery_distance_rec.delivery_company_code;  -- 運送業者コード
        lt_temp_origin_shipment       := xxwip_delivery_distance_rec.origin_shipment;        -- 出庫元
        lt_temp_code_division         := xxwip_delivery_distance_rec.code_division;          -- コード区分
        lt_temp_shipping_address_code := xxwip_delivery_distance_rec.shipping_address_code;  -- 配送先コード
        lt_temp_start_date_active     := xxwip_delivery_distance_rec.start_date_active;      -- 適用開始日
        lt_temp_end_date_active       := xxwip_delivery_distance_rec.end_date_active;        -- 適用終了日
--
      END LOOP xxwip_delivery_distance_loop;
    END IF;
--
    -- カーソルクローズ
    IF (xxwip_delivery_distance_cur%ISOPEN) THEN
      CLOSE xxwip_delivery_distance_cur;
    END IF;
--
    -- ====================================
    -- 最終レコードの適用終了日セット
    -- ====================================
    -- 正しい適用終了日でない場合
    IF ((lt_temp_end_date_active IS NULL)
    OR  (lt_temp_end_date_active <> ld_max_date))
    THEN
      -- 最終レコードにMAX日付を設定
      ln_count := ln_count + 1;
      goods_classe_tab(ln_count)          := lt_temp_goods_classe;          -- 商品区分
      delivery_company_code_tab(ln_count) := lt_temp_delivery_company_code; -- 運送業者コード
      origin_shipment_tab(ln_count)       := lt_temp_origin_shipment;       -- 出庫元
      code_division_tab(ln_count)         := lt_temp_code_division;         -- コード区分
      shipping_address_code_tab(ln_count) := lt_temp_shipping_address_code; -- 配送先コード
      start_date_active_tab(ln_count)     := lt_temp_start_date_active;     -- 適用開始日
      end_date_active_tab(ln_count)       := ld_max_date;                   -- 適用終了日
--
    END IF;
--
    -- ===============================
    -- 一括更新処理
    -- ===============================
    FORALL ln_cnt_loop IN 1 .. delivery_company_code_tab.COUNT
      UPDATE xxwip_delivery_distance  xdd   -- 配送距離アドオンマスタ
      SET    xdd.end_date_active        = end_date_active_tab(ln_cnt_loop)      -- 適用終了日
-- 2009/04/03 v1.2 ADD START
            ,xdd.change_flg             = gv_on                                 -- 変更フラグ
-- 2009/04/03 v1.2 ADD END
            ,xdd.last_updated_by        = FND_GLOBAL.USER_ID                    -- 最終更新者
            ,xdd.last_update_date       = SYSDATE                               -- 最終更新日
            ,xdd.last_update_login      = FND_GLOBAL.LOGIN_ID                   -- 最終更新ログイン
            ,xdd.request_id             = FND_GLOBAL.CONC_REQUEST_ID            -- 要求ID
            ,xdd.program_application_id = FND_GLOBAL.PROG_APPL_ID               -- コンカレント・プログラム・アプリケーションID
            ,xdd.program_id             = FND_GLOBAL.CONC_PROGRAM_ID            -- コンカレント・プログラムID
            ,xdd.program_update_date    = SYSDATE                               -- プログラム更新日
      WHERE xdd.goods_classe            = goods_classe_tab(ln_cnt_loop)         -- 商品区分
      AND   xdd.delivery_company_code   = delivery_company_code_tab(ln_cnt_loop)-- 運送業者コード
      AND   xdd.origin_shipment         = origin_shipment_tab(ln_cnt_loop)      -- 出庫元
      AND   xdd.code_division           = code_division_tab(ln_cnt_loop)        -- コード区分
      AND   xdd.shipping_address_code   = shipping_address_code_tab(ln_cnt_loop)-- 配送先コード
      AND   xdd.start_date_active       = start_date_active_tab(ln_cnt_loop)    -- 適用開始日
      ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (xxwip_delivery_distance_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_distance_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xxwip_delivery_distance_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_distance_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xxwip_delivery_distance_cur%ISOPEN) THEN
        CLOSE xxwip_delivery_distance_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  固定部 END   ##########################################
  END update_end_date_active_all;
--
--
  /**********************************************************************************
   * Procedure Name   : del_table_data
   * Description      : データ削除処理(D-13)
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
    -- ===============================
    -- 配送距離アドオンマスタインタフェース削除
    -- ===============================
    FORALL ln_count IN 1..request_id_tab.COUNT
      DELETE xxwip_delivery_distance_if xddi             -- 配送距離アドオンマスタインタフェース
      WHERE  xddi.request_id    = request_id_tab(ln_count)  -- 要求ID
-- v1.3 ADD START
      AND    xddi.goods_classe  = gv_prod_div               -- 商品区分
-- v1.3 ADD END
      ;
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
  END del_table_data;
--
--
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : データダンプ一括出力処理(D-14)
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
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
    FOR ln_cnt_loop IN 1 .. normal_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,normal_dump_tab(ln_cnt_loop));
    END LOOP normal_dump_loop;
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
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
    FOR ln_cnt_loop IN 1 .. warn_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,warn_dump_tab(ln_cnt_loop));
    END LOOP warn_dump_loop;
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
    -- 要求IDカーソル
    CURSOR xddi_request_id_cur
    IS
      SELECT fcr.request_id request_id
      FROM   fnd_concurrent_requests fcr   -- コンカレント要求IDテーブル
      WHERE  EXISTS (
               SELECT 1
               FROM   xxwip_delivery_distance_if xddi   -- 配送距離アドオンマスタインタフェース
               WHERE  xddi.request_id   = fcr.request_id  -- 要求ID
-- v1.3 ADD START
               AND    xddi.goods_classe = gv_prod_div     -- 商品区分
-- v1.3 ADD END
               AND    ROWNUM            = 1
             )
      ORDER BY request_id
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
-- v1.3 ADD START
    -- 入力パラメータ.商品区分をグローバル変数に格納
    gv_prod_div   := iv_prod_div;
-- v1.3 ADD END
    -- ===============================
    -- D-1.要求ID取得処理
    -- ===============================
    <<get_request_id_loop>>
    FOR lr_xddi_request_id IN xddi_request_id_cur
    LOOP
      gn_request_id_cnt := gn_request_id_cnt + 1 ;
      request_id_tab(gn_request_id_cnt) := lr_xddi_request_id.request_id;
    END LOOP get_request_id_loop;
--
    -- ===============================
    -- D-2.ロック取得処理
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
    <<process_loop>>
    FOR ln_count IN 1..request_id_tab.COUNT
    LOOP
      -- 変数初期化
      -- 登録用・更新用PL/SQL表カウント
      gn_ins_tab_cnt := 0;
      gn_upd_tab_cnt := 0;
--
      -- 登録用PL/SQL表
      delivery_distance_id_ins_tab.DELETE;  -- 配送距離ID
      goods_classe_ins_tab.DELETE;          -- 商品区分
      delivery_company_code_ins_tab.DELETE;-- 運送業者コード
      origin_shipment_ins_tab.DELETE;       -- 出庫元
      code_division_ins_tab.DELETE;         -- コード区分
      shipping_address_code_ins_tab.DELETE; -- 配送先コード
      start_date_active_ins_tab.DELETE;     -- 適用開始日
      post_distance_ins_tab.DELETE;         -- 車立距離
      small_distance_ins_tab.DELETE;        -- 小口距離
      consolid_add_dist_ins_tab.DELETE;     -- 混載割増距離
      actual_distance_ins_tab.DELETE;       -- 実際距離
      area_a_ins_tab.DELETE;                -- エリアA
      area_b_ins_tab.DELETE;                -- エリアB
      area_c_ins_tab.DELETE;                -- エリアC
--
      -- 更新用PL/SQL表
      delivery_distance_id_upd_tab.DELETE;  -- 配送距離ID
      goods_classe_upd_tab.DELETE;          -- 商品区分
      delivery_company_code_upd_tab.DELETE;-- 運送業者コード
      origin_shipment_upd_tab.DELETE;       -- 出庫元
      code_division_upd_tab.DELETE;         -- コード区分
      shipping_address_code_upd_tab.DELETE; -- 配送先コード
      start_date_active_upd_tab.DELETE;     -- 適用開始日
      post_distance_upd_tab.DELETE;         -- 車立距離
      small_distance_upd_tab.DELETE;        -- 小口距離
      consolid_add_dist_upd_tab.DELETE;     -- 混載割増距離
      actual_distance_upd_tab.DELETE;       -- 実際距離
      area_a_upd_tab.DELETE;                -- エリアA
      area_b_upd_tab.DELETE;                -- エリアB
      area_c_upd_tab.DELETE;                -- エリアC
--
      -- ===============================
      -- D-3.重複データ除外処理
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
      -- D-5.登録データ取得処理
      -- ===============================
      get_ins_data(
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
      -- D-8.更新データ取得処理
      -- ===============================
      get_upd_data(
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
      -- D-10.一括登録処理
      -- ===============================
      ins_table_batch(
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
      -- D-11.一括更新処理
      -- ===============================
      upd_table_batch(
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
    END LOOP process_loop;
--
    -- ===============================
    -- D-12.適用終了日更新処理
    -- ===============================
    update_end_date_active_all(
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
    -- D-13.データ削除処理
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
    -- D-14.データダンプ一括出力処理
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
      IF (xddi_request_id_cur%ISOPEN) THEN
        CLOSE xddi_request_id_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xddi_request_id_cur%ISOPEN) THEN
        CLOSE xddi_request_id_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xddi_request_id_cur%ISOPEN) THEN
        CLOSE xddi_request_id_cur;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
-- v1.3 MOD START
--    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_prod_div   IN  VARCHAR2       --   商品区分
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
      iv_prod_div, -- 商品区分
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
    -- D-15.リターン・コードのセット、終了処理
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
END xxwip720001c;
/
