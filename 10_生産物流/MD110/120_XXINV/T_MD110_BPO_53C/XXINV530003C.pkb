CREATE OR REPLACE PACKAGE BODY xxinv530003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv530003c (body)
 * Description      : 棚卸表
 * MD.050/070       : 棚卸Issue1.0 (T_MD050_BPO_530)
                      棚卸表Draft1A (T_MD070_BPO_530C)
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  proc_check_param          PROCEDURE : パラメータ・チェック(C-1)
 *  proc_get_data             PROCEDURE : データ取得(C-2)
 *  proc_create_xml_data      PROCEDURE : ＸＭＬデータ出力(C-4)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : 帳票実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-03-06    1.0   T.Ikehara        新規作成
 *  2008-05-02    1.1   T.Ikehara        パラメータ：品目コードを品目IDに変更対応
 *  2008-05-02    1.2   T.Ikehara        日付出力形式、倉庫コード条件不具合対応
 *  2008/06/03    1.3   T.Endou          担当部署または担当者名が未取得時は正常終了に修正
 *  2008/06/24    1.4   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *
 *****************************************************************************************/
--
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  固定部 END   ############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  global_user_expt          EXCEPTION;     -- ユーザーにて定義をした例外
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
-- 棚卸データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD (
      segment1              xxcmn_categories2_v.segment1%TYPE                -- カテゴリ1
     ,meaning               xxcmn_lookup_values2_v.meaning%TYPE              -- 内容(品目区分)
     ,customer_stock_whse   xxcmn_item_locations2_v.customer_stock_whse%TYPE -- 名義
     ,meaning2              xxcmn_lookup_values2_v.meaning%TYPE              -- 内容(在庫管理主体)
     ,invent_whse_code      xxinv_stc_inventory_result.invent_whse_code%TYPE -- 棚卸倉庫
     ,whse_name             xxcmn_item_locations2_v.whse_name%TYPE           -- 摘要
     ,item_code             xxinv_stc_inventory_result.item_code%TYPE        -- 品目
     ,item_short_name       xxcmn_item_mst_v.item_short_name%TYPE            -- 品目略称
     ,invent_seq            xxinv_stc_inventory_result.invent_seq%TYPE       -- 棚卸連番
     ,lot_no                xxinv_stc_inventory_result.lot_no%TYPE           -- ロットNo.
     ,maker_date            xxinv_stc_inventory_result.maker_date%TYPE       -- 製造日
     ,limit_date            xxinv_stc_inventory_result.limit_date%TYPE       -- 賞味期限
     ,proper_mark           xxinv_stc_inventory_result.proper_mark%TYPE      -- 固有記号
     ,rack_no1              xxinv_stc_inventory_result.rack_no1%TYPE         -- ラックNo1
     ,rack_no2              xxinv_stc_inventory_result.rack_no2%TYPE         -- ラックNo2
     ,rack_no3              xxinv_stc_inventory_result.rack_no3%TYPE         -- ラックNo3
     ,location              xxinv_stc_inventory_result.location%TYPE         -- ロケーション
     ,invent_date           xxinv_stc_inventory_result.invent_date%TYPE      -- 棚卸日
     ,case_amt              xxinv_stc_inventory_result.case_amt%TYPE         -- 棚卸ケース数
     ,content               xxinv_stc_inventory_result.content%TYPE          -- 入数
     ,num_of_cases          xxcmn_item_mst_v.num_of_cases%TYPE               -- ケース入数
     ,loose_amt             xxinv_stc_inventory_result.loose_amt%TYPE        -- 棚卸バラ
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxinv5300003c' ;   -- パッケージ名
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gv_param_date_format    CONSTANT VARCHAR2(10) := 'YYYYMM';
  gv_out_date_type        CONSTANT VARCHAR2(20) := 'YYYY/MM/DD' ;
  gv_out_date_year        CONSTANT VARCHAR2(10) := 'YYYY';
  gv_out_date_month       CONSTANT VARCHAR2(10) := 'MM';
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_cmn    CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- アプリケーション（XXCMN）
  gc_application_po     CONSTANT VARCHAR2(5)  := 'XXPO' ;             -- アプリケーション（XXPO）
  gv_application_xxbpo  CONSTANT VARCHAR2(10) := 'XXBPO';
  gv_msg_xxpo10010      CONSTANT VARCHAR2(20) := 'APP-XXCMN-10010';
  gv_msg_xxpo10122      CONSTANT VARCHAR2(20) := 'APP-XXCMN-10122';
  gv_tkn_param_name     CONSTANT VARCHAR2(20) := 'PARAMETER';
  gv_tkn_param_value    CONSTANT VARCHAR2(100) := 'VALUE';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_user_id             fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
  gv_user_dept           xxcmn_locations_all.location_short_name%TYPE DEFAULT NULL;
  gv_user_name           per_all_people_f.per_information18%TYPE DEFAULT NULL;
  gn_case_total          NUMBER DEFAULT 0;   -- 棚卸数(ケース)集計
  gn_scatteringly_total  NUMBER DEFAULT 0;   -- 棚卸数(バラ)集計
  gn_number_sum_total    NUMBER DEFAULT 0;   -- 棚卸数合計集計
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id              VARCHAR2(20) DEFAULT NULL;  -- 帳票ID
  gd_exec_date              DATE  DEFAULT NULL;         -- 実施日
  gt_main_data              tab_data_type_dtl ;         -- 取得レコード表
  gt_xml_data_table         XML_DATA ;                  -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER  DEFAULT 0;          -- ＸＭＬデータタグ表のインデックス
  gv_item_name              xxcmn_categories_v.category_set_name%TYPE DEFAULT  '*';
  gv_stock_whse_name        xxcmn_lookup_values2_v.meaning%TYPE DEFAULT  '*';
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION fnc_conv_xml (
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_convert_data         VARCHAR2(2000)  DEFAULT NULL;
--
  BEGIN
--
    --データの場合
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_check_param
   * Description      : C-1.パラメーター・チェック
   ***********************************************************************************/
  PROCEDURE proc_check_param(
     ov_errbuf             OUT     VARCHAR2    -- エラー・メッセージ
    ,ov_retcode            OUT     VARCHAR2    -- リターン・コード
    ,ov_errmsg             OUT     VARCHAR2    -- ユーザー・エラー・メッセージ
    ,iv_inventory_time     IN      VARCHAR2    -- 1.棚卸年月度
    ,iv_stock_name         IN      VARCHAR2    -- 2.名義
    ,iv_report_post        IN      VARCHAR2    -- 3.報告部署
    ,iv_warehouse_code     IN      VARCHAR2    -- 4.倉庫コード
    ,iv_distribution_block IN      VARCHAR2    -- 5.ブロック
    ,iv_item_type          IN      VARCHAR2    -- 6.品目区分
    ,iv_item_code          IN      VARCHAR2    -- 7.品目コード
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_check_param'; -- プログラム名
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
    cv_lookup_type_ctrl       CONSTANT VARCHAR2(20)  := 'XXCMN_INV_CTRL';
    cv_lookup_type_d12        CONSTANT VARCHAR2(20)  := 'XXCMN_D12';
    cv_param_inv_time         CONSTANT VARCHAR2(20)  := '棚卸年月度';
    cv_param_stock_name       CONSTANT VARCHAR2(20)  := '名義';
    cv_param_report_post      CONSTANT VARCHAR2(20)  := '報告部署';
    cv_param_warehouse_code   CONSTANT VARCHAR2(20)  := '倉庫コード';
    cv_param_block            CONSTANT VARCHAR2(20)  := 'ブロック';
    cv_param_item_type        CONSTANT VARCHAR2(20)  := '品目区分';
    cv_param_item_code        CONSTANT VARCHAR2(20)  := '品目コード';
--
    -- *** ローカル変数 ***
    lv_check_whse      ic_whse_mst.whse_code%TYPE DEFAULT NULL;
    lv_palam_check     xxcmn_lookup_values_v.lookup_code%TYPE DEFAULT NULL;
    ln_category_id     xxcmn_categories2_v.category_id%TYPE DEFAULT NULL;
    ln_palam_check     NUMBER  DEFAULT NULL;
    lv_date_check      VARCHAR2(20)  DEFAULT NULL;
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
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
  -- パラメータチェック.棚卸年月度
    lv_date_check := FND_DATE.STRING_TO_DATE(iv_inventory_time, gv_param_date_format);
--
    IF (lv_date_check IS NULL) THEN
      lv_errbuf  := xxcmn_common_pkg.get_msg(
                      iv_application  => gc_application_cmn,
                      iv_name         => gv_msg_xxpo10010,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => cv_param_inv_time,
                      iv_token_name2  => gv_tkn_param_value,
                      iv_token_value2 => iv_inventory_time
                    );
      lv_retcode := gv_status_error;
      RAISE global_user_expt;
    END IF;
--
  -- パラメータチェック.名義
    BEGIN
      SELECT
        xlvv2.meaning  AS meaning
      INTO
        gv_stock_whse_name
      FROM    xxcmn_lookup_values2_v xlvv2            -- クイックコード情報VIEW
      WHERE   xlvv2.lookup_code = iv_stock_name
        AND   xlvv2.lookup_type = cv_lookup_type_ctrl;
--
    EXCEPTION
    -- データがない場合はエラー
      WHEN NO_DATA_FOUND THEN
        lv_errbuf  := xxcmn_common_pkg.get_msg(
                        iv_application  => gc_application_cmn,
                        iv_name         => gv_msg_xxpo10010,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => cv_param_stock_name,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_stock_name
                      );
        RAISE global_user_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  -- パラメータチェック.報告部署
    BEGIN
      SELECT  xl2v.location_id  AS location_id
      INTO    ln_palam_check
      FROM    xxcmn_locations2_v  xl2v
      WHERE   location_code = iv_report_post
        AND   ROWNUM = 1;
    EXCEPTION
    -- データがない場合はエラー
      WHEN NO_DATA_FOUND THEN
        lv_errbuf  := xxcmn_common_pkg.get_msg(
                        iv_application  => gc_application_cmn,
                        iv_name         => gv_msg_xxpo10010,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => cv_param_report_post,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_report_post
                      );
        RAISE global_user_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  -- パラメータチェック.倉庫コード
    IF (iv_warehouse_code IS NOT NULL) THEN
      BEGIN
        SELECT  iwm.whse_code    AS whse_code
        INTO    lv_check_whse
        FROM    ic_whse_mst       iwm
        WHERE   iwm.whse_code = iv_warehouse_code
          AND   iwm.attribute1 = iv_stock_name
          AND   ROWNUM = 1;
      EXCEPTION
      -- データがない場合はエラー
        WHEN NO_DATA_FOUND THEN
          lv_errbuf  := xxcmn_common_pkg.get_msg(
                          iv_application  => gc_application_cmn,
                          iv_name         => gv_msg_xxpo10010,
                          iv_token_name1  => gv_tkn_param_name,
                          iv_token_value1 => cv_param_warehouse_code,
                          iv_token_name2  => gv_tkn_param_value,
                          iv_token_value2 => iv_warehouse_code
                        );
          RAISE global_user_expt;
        WHEN OTHERS THEN
          RAISE;
      END;
    END IF;
--
  -- パラメータチェック.ブロック
    IF (iv_distribution_block IS NOT NULL) THEN
      BEGIN
        SELECT  xlvv2.lookup_code AS lookup_code
        INTO    lv_palam_check
        FROM    xxcmn_lookup_values2_v  xlvv2
        WHERE   xlvv2.lookup_code = iv_distribution_block
          AND   xlvv2.lookup_type = cv_lookup_type_d12;
      EXCEPTION
      -- データがない場合はエラー
        WHEN NO_DATA_FOUND THEN
          lv_errbuf  := xxcmn_common_pkg.get_msg(
                          iv_application  => gc_application_cmn,
                          iv_name         => gv_msg_xxpo10010,
                          iv_token_name1  => gv_tkn_param_name,
                          iv_token_value1 => cv_param_block,
                          iv_token_name2  => gv_tkn_param_value,
                          iv_token_value2 => iv_distribution_block
                        );
          RAISE global_user_expt;
        WHEN OTHERS THEN
          RAISE;
      END;
    END IF;
--
  -- パラメータチェック.品目区分
    BEGIN
      SELECT
        xcv2.description AS description,
        xcv2.category_id  AS category_id
      INTO
        gv_item_name,
        ln_category_id
      FROM    xxcmn_categories2_v  xcv2
      WHERE   xcv2.segment1 = iv_item_type
        AND   xcv2.category_set_name = cv_param_item_type;
    EXCEPTION
    -- データがない場合はエラー
      WHEN NO_DATA_FOUND THEN
        lv_errbuf  := xxcmn_common_pkg.get_msg(
                        iv_application  => gc_application_cmn,
                        iv_name         => gv_msg_xxpo10010,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => cv_param_item_type,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_item_type
                      );
        RAISE global_user_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  -- パラメータチェック.品目コード
    IF (iv_item_code IS NOT NULL) THEN
      BEGIN
        SELECT  ximv2.item_id  AS item_id
        INTO    ln_palam_check
        FROM    xxcmn_item_mst2_v    ximv2,
                xxcmn_item_categories2_v  xicv2
        WHERE   ximv2.item_id = xicv2.item_id
          AND   xicv2.category_id = ln_category_id
          AND   ximv2.item_id = iv_item_code;
      EXCEPTION
      -- データがない場合はエラー
        WHEN NO_DATA_FOUND THEN
          lv_errbuf  := xxcmn_common_pkg.get_msg(
                          iv_application  => gc_application_cmn,
                          iv_name         => gv_msg_xxpo10010,
                          iv_token_name1  => gv_tkn_param_name,
                          iv_token_value1 => cv_param_item_code,
                          iv_token_name2  => gv_tkn_param_value,
                          iv_token_value2 => iv_item_code
                        );
          RAISE global_user_expt;
      END;
    END IF;
--
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      -- ログにパラメータ・エラーメッセージを出力する
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_check_param;
--
  /**********************************************************************************
   * Procedure Name   : proc_get_data
   * Description      : C-2.データ取得
   ***********************************************************************************/
  PROCEDURE proc_get_data(
     ov_errbuf             OUT     VARCHAR2   -- エラー・メッセージ
    ,ov_retcode            OUT     VARCHAR2   -- リターン・コード
    ,ov_errmsg             OUT     VARCHAR2   -- ユーザー・エラー・メッセージ
    ,iv_inventory_time     IN      VARCHAR2   -- 1.棚卸年月度
    ,iv_stock_name         IN      VARCHAR2   -- 2.名義
    ,iv_report_post        IN      VARCHAR2   -- 3.報告部署
    ,iv_warehouse_code     IN      VARCHAR2   -- 4.倉庫コード
    ,iv_distribution_block IN      VARCHAR2   -- 5.ブロック
    ,iv_item_type          IN      VARCHAR2   -- 6.品目区分
    ,iv_item_code          IN      VARCHAR2   -- 7.品目コード
    ,ot_data_rec           OUT     NOCOPY tab_data_type_dtl  -- 取得データ格納用
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_data'; -- プログラム名
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
    -- 注文書出力方法(DFF)
    cv_date_type        CONSTANT VARCHAR2(10) := 'YYYYMM';          -- 日付型
    cv_quickcode_ctrl   CONSTANT VARCHAR2(20) := 'XXCMN_INV_CTRL';  -- クイックコード(在庫管理主体)
    cv_item_type        CONSTANT VARCHAR2(10) := '品目区分';        -- カテゴリセット名
    cv_item_type_order  CONSTANT VARCHAR2(1)  := '5';               -- 品目タイプ(製造)
--
    -- *** ローカル変数 ***
    lv_req_number         VARCHAR2(100) DEFAULT NULL;      -- 購買依頼番号
    ld_request_date       DATE DEFAULT NULL;               -- 要求日
    ln_order_number       NUMBER DEFAULT 0 ;               -- 受注番号
    lv_party_site_number  VARCHAR2(30) DEFAULT NULL;       -- 顧客サイトコード
    lv_manag_office_code  VARCHAR2(200) DEFAULT NULL;      -- 管理事務所コード
    lv_department_code    VARCHAR2(10) DEFAULT NULL;       -- BOM部門コード
    lv_terms_flg          VARCHAR2(1) DEFAULT NULL;        -- 条件フラグ
    ld_object_date        DATE DEFAULT NULL;               -- 棚卸日(当月月初)
    ld_next_date          DATE DEFAULT NULL;               -- 棚卸日(翌月月初)
    lv_sql                VARCHAR2(32767) DEFAULT NULL;    -- 動的SQL文
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    TYPE   ref_cursor IS REF CURSOR ;
    cur_main_data ref_cursor ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    lv_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--棚卸対象期間取得
    ld_object_date := FND_DATE.STRING_TO_DATE(iv_inventory_time,cv_date_type);
    ld_next_date := FND_DATE.STRING_TO_DATE(iv_inventory_time + 1,cv_date_type);
--
    lv_sql :=
         'SELECT'
      || '   xcv2.segment1                 AS segment1'               -- カテゴリ1
      || ' ,xcv2.description               AS description'            -- 内容（品目区分）
      || ' ,iwm.attribute1                 AS customer_stock_whse'    -- 名義
      || ' ,xlvv2.meaning                  AS meaning'                -- 内容（在庫管理主体）
      || ' ,xsir.invent_whse_code          AS invent_whse_code'       -- 棚卸倉庫
      || ' ,iwm.whse_name                  AS whse_name'              -- 倉庫名称
      || ' ,xsir.item_code                 AS item_code'              -- 品目
      || ' ,ximv.item_short_name           AS item_short_name'        -- 略称
      || ' ,xsir.invent_seq                AS invent_seq'             -- 棚卸連番
      || ' ,xsir.lot_no                    AS lot_no'                 -- ロットNo.
      || ' ,xsir.maker_date                AS maker_date'             -- 製造日
      || ' ,xsir.limit_date                AS limit_date'             -- 賞味期限
      || ' ,xsir.proper_mark               AS proper_mark'            -- 固有記号
      || ' ,xsir.rack_no1                  AS rack_no1'               -- ラックNo1
      || ' ,xsir.rack_no2                  AS rack_no2'               -- ラックNo2
      || ' ,xsir.rack_no3                  AS rack_no3'               -- ラックNo3
      || ' ,xsir.location                  AS location'               -- ロケーション
      || ' ,xsir.invent_date               AS invent_date'            -- 棚卸日
      || ' ,xsir.case_amt                  AS case_amt'               -- 棚卸ケース数
      || ' ,xsir.content                   AS content'                -- 入数
      || ' ,ximv.num_of_cases              AS num_of_cases'           -- ケース入数
      || ' ,xsir.loose_amt                 AS loose_amt '             -- 棚卸バラ
--FROM句編集
      || 'FROM'
      || ' xxinv_stc_inventory_result    xsir'    -- 棚卸結果テーブル
      || ',ic_whse_mst                   iwm'     -- OPM倉庫マスタ
      || ',xxcmn_item_mst2_v             ximv'    -- OPM品目情報VIEW2
      || ',xxcmn_item_categories2_v      xicv'    -- OPM品目カテゴリ割当情報VIEW2
      || ',xxcmn_categories2_v           xcv2'    -- 品目カテゴリ情報VIEW2
      || ',xxcmn_lookup_values2_v        xlvv2 '  -- クイックコード情報VIEW2
--WHERE句編集
      || 'WHERE'
      || ' (xsir.invent_date >= ''' || ld_object_date  || ''''
      || '   AND xsir.invent_date < ''' || ld_next_date || ''')'
      || ' AND xsir.invent_whse_code = iwm.whse_code '
      || ' AND ximv.item_id = xsir.item_id '
      || ' AND ((ximv.start_date_active <= xsir.invent_date) '
      || '   AND (ximv.end_date_active >=xsir.invent_date))'
      || ' AND iwm.attribute1 = ''' || iv_stock_name || ''''
      || ' AND xlvv2.lookup_type = ''' || cv_quickcode_ctrl || ''''
      || ' AND xlvv2.lookup_code = iwm.attribute1'
      || ' AND xcv2.category_id =  xicv.category_id '
      || ' AND xcv2.category_set_name = ''' || cv_item_type || ''''
      || ' AND xcv2.segment1 = ''' || iv_item_type || ''''
      || ' AND xsir.report_post_code = ''' || iv_report_post || ''''
      || ' AND xsir.item_id = xicv.item_id';
--【入力パラメータ：倉庫コードが入力済の場合】
    IF (iv_warehouse_code IS NOT NULL) THEN
      lv_sql := lv_sql
        || ' AND iwm.whse_code = ''' || iv_warehouse_code || '''';
    END IF;
--【入力パラメータ：ブロックが入力済の場合】
    IF (iv_distribution_block IS NOT NULL) THEN
      lv_sql := lv_sql
        || ' AND EXISTS(SELECT  ilm.whse_code'
        || '        FROM   ic_loct_mst         ilm'
        || '              ,mtl_item_locations  mil '
        || '        WHERE ilm.whse_code = iwm.whse_code '
        || '          AND ilm.inventory_location_id = mil.inventory_location_id '
        || '          AND mil.attribute6 = ''' || iv_distribution_block || ''')';
    END IF;
--【入力パラメータ：品目が入力済の場合】
    IF (iv_item_code IS NOT NULL) THEN
      lv_sql := lv_sql
        || ' AND ximv.item_id = ' || iv_item_code;
    END IF;
--ORDER BY句編集
    lv_sql := lv_sql
      || ' ORDER BY'
      || ' xsir.invent_whse_code'
      || ',xsir.item_code';
    IF (iv_item_type = cv_item_type_order) THEN
      lv_sql := lv_sql
        || ',xsir.maker_date'
        || ',xsir.proper_mark';
    ELSE
    lv_sql := lv_sql
      || ',xsir.lot_no';
    END IF;
    lv_sql := lv_sql
      || ',xsir.invent_seq';
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- カーソルオープン
    OPEN cur_main_data FOR lv_sql ;
    -- バルクフェッチ
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE cur_main_data ;
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
  END proc_get_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_create_xml_data
   * Description      : C-4.ＸＭＬデータ出力
   **********************************************************************************/
  PROCEDURE proc_create_xml_data(
     ov_errbuf             OUT     VARCHAR2    -- エラー・メッセージ
    ,ov_retcode            OUT     VARCHAR2    -- リターン・コード
    ,ov_errmsg             OUT     VARCHAR2    -- ユーザー・エラー・メッセージ
    ,iv_inventory_time     IN      VARCHAR2    -- 1.棚卸年月度
    ,iv_stock_name         IN      VARCHAR2    -- 2.名義
    ,iv_report_post        IN      VARCHAR2    -- 3.報告部署
    ,iv_warehouse_code     IN      VARCHAR2    -- 4.倉庫コード
    ,iv_distribution_block IN      VARCHAR2    -- 5.ブロック
    ,iv_item_type          IN      VARCHAR2    -- 6.品目区分
    ,iv_item_code          IN      VARCHAR2    -- 7.品目コード
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_create_xml_data'; -- プログラム名
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
    -- キーブレイク判断用
    lc_break_init           VARCHAR2(100) := '*' ;   -- 初期値
    lc_break_null           VARCHAR2(100) := '**' ;  -- NULL判定
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_whse_class         VARCHAR2(100) DEFAULT '*' ;  -- 倉庫コード
    lv_item_class         VARCHAR2(100) DEFAULT '*' ;  -- 品目
--
    ln_pac_cases          NUMBER(20)    DEFAULT 0 ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    proc_get_data(
       ov_errbuf             => lv_errbuf              -- エラー・メッセージ
      ,ov_retcode            => lv_retcode             -- リターン・コード
      ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ
      ,iv_inventory_time     => iv_inventory_time      -- 1.棚卸年月度
      ,iv_stock_name         => iv_stock_name          -- 2.名義
      ,iv_report_post        => iv_report_post         -- 3.報告部署
      ,iv_warehouse_code     => iv_warehouse_code      -- 4.倉庫コード
      ,iv_distribution_block => iv_distribution_block  -- 5.ブロック
      ,iv_item_type          => iv_item_type           -- 6.品目区分
      ,iv_item_code          => iv_item_code           -- 7.品目コード
      ,ot_data_rec           => gt_main_data);         -- 取得データ格納用配列
--
    IF ( gt_main_data.COUNT = 0 ) THEN
      lv_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg(
                      iv_application  => gc_application_cmn,
                      iv_name         => gv_msg_xxpo10122
                    );
      RAISE global_user_expt ;
    END IF ;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- ユーザーＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ユーザーＧデータタグ出力
    -- -----------------------------------------------------
      -- 帳票ＩＤ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
      -- 実施日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(gd_exec_date, gc_char_dt_format) ;
      -- 担当(部署名)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gv_user_dept, 0, 10) ;
      -- 担当(名称)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gv_user_name, 0, 14) ;
      -- 棚卸年月度(年)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_year' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(iv_inventory_time, gv_param_date_format), gv_out_date_year);
      -- 棚卸年月度(月)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_month' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(iv_inventory_time, gv_param_date_format), gv_out_date_month);
      -- 品目区分コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_division_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := iv_item_type ;
      -- 品目区分名称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_division_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gv_item_name, 0, 6) ;
      -- 名義
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'nominal' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gv_stock_whse_name, 0, 22) ;
    -- -----------------------------------------------------
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- 明細データ出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- 倉庫コードブレイク
      -- =====================================================
      -- 倉庫コードが切り替わった場合
      IF ( NVL( gt_main_data(i).invent_whse_code, lc_break_null ) <> lv_whse_class ) THEN
        --商品G終了タグ判断用変数初期化
        lv_item_class := lc_break_init;
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_whse_class <> lc_break_init ) THEN
          ------------------------------
          -- 商品Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 商品LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 倉庫Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_warehouse' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 倉庫LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_warehouse' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 倉庫LＧ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_warehouse' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 倉庫Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_warehouse' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 倉庫Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 倉庫コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'warehouse_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value :=  gt_main_data(i).invent_whse_code;
        -- 倉庫名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'warehouse_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := substrb(gt_main_data(i).whse_name, 0, 20) ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_whse_class  := NVL( gt_main_data(i).invent_whse_code, lc_break_null )  ;
      END IF;
--
      -- =====================================================
      -- 商品コードブレイク
      -- =====================================================
      -- 商品コードが切り替わった場合
      IF ( NVL( gt_main_data(i).item_code, lc_break_null ) <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- 商品Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 商品LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- -----------------------------------------------------
        -- 商品LＧ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 商品Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 商品Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 商品コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value :=  gt_main_data(i).item_code;
        -- 商品名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := substrb(gt_main_data(i).item_short_name, 0,20);
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_item_class  := NVL( gt_main_data(i).item_code, lc_break_null )  ;
      END IF;
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
--
      -- -----------------------------------------------------
      -- 明細ＬＧ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- 明細Ｇ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- 明細Ｇデータタグ出力
      -- -----------------------------------------------------
      -- 棚卸連番
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_consecutive_numbers' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).invent_seq ;
      -- ロットNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_number' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).lot_no ;
      -- 製造年月日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'wip_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).maker_date, gv_out_date_type), gv_out_date_type);
      -- 賞味期限
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'best_before_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).limit_date, gv_out_date_type), gv_out_date_type);
      -- 固有記号
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'peculiar_mark' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gt_main_data(i).proper_mark, 0, 6) ;
      -- ラックNo1
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rack_no1' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).rack_no1 ;
      -- ラックNo2
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rack_no2' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).rack_no2 ;
      -- ラックNo3
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rack_no3' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).rack_no3 ;
      -- ロケーション
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'location' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := substrb(gt_main_data(i).location, 0, 10) ;
      -- 棚卸日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value :=
        TO_CHAR(gt_main_data(i).invent_date, gv_out_date_type) ;
      -- 棚卸数(ケース)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_number_case' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).case_amt ;
      -- 棚卸数(ケース)集計
      gn_case_total := gn_case_total + gt_main_data(i).case_amt;
      -- 入数
      IF (gt_main_data(i).content != 0) THEN
        ln_pac_cases := gt_main_data(i).content;
      ELSE
        ln_pac_cases := NVL(gt_main_data(i).num_of_cases, 0);
      END IF;
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'purchase_quantity' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_pac_cases;
      -- 棚卸数(バラ)
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_number_scatteringly' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).loose_amt ;
      -- 棚卸数(バラ)集計
      gn_scatteringly_total := gn_scatteringly_total + gt_main_data(i).loose_amt;
      -- 棚卸数合計
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pac_item_number_sum' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value :=
        (gt_main_data(i).case_amt *ln_pac_cases + gt_main_data(i).loose_amt) ;
      -- 棚卸数合計集計
      gn_number_sum_total := gn_number_sum_total +
        (gt_main_data(i).case_amt *ln_pac_cases + gt_main_data(i).loose_amt);
--
      -- -----------------------------------------------------
      -- 明細Ｇ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- 明細ＬＧ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    ------------------------------
    -- 商品Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 商品ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 集計棚卸数出力
    -- 棚卸数(ケース)総合計
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'number_case_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gn_case_total ;
    -- 棚卸数(バラ)総合計
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'number_scatteringly_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gn_scatteringly_total ;
    -- 棚卸数総合計
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'number_sum_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gn_number_sum_total ;
    ------------------------------
    -- 倉庫Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_warehouse' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 倉庫LＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_warehouse' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- データＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := lv_retcode;
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
  END proc_create_xml_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT     VARCHAR2,   -- エラー・メッセージ
    ov_retcode            OUT     VARCHAR2,   -- リターン・コード
    ov_errmsg             OUT     VARCHAR2,   -- ユーザー・エラー・メッセージ
    iv_inventory_time     IN      VARCHAR2,   -- 1.棚卸年月度
    iv_stock_name         IN      VARCHAR2,   -- 2.名義
    iv_report_post        IN      VARCHAR2,   -- 3.報告部署
    iv_warehouse_code     IN      VARCHAR2,   -- 4.倉庫コード
    iv_distribution_block IN      VARCHAR2,   -- 5.ブロック
    iv_item_type          IN      VARCHAR2,   -- 6.品目区分
    iv_item_code          IN      VARCHAR2    -- 7.品目コード
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
    -- *** ローカル変数 ***
    ln_podate_cnt     NUMBER DEFAULT 0;          -- 発注データ処理件数
    ln_data_cnt       NUMBER DEFAULT 0;          -- 処理件数
    lv_xml_string     VARCHAR2(32000) ;
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
    --初期処理
    gv_report_id              := 'XXINV530003T';                  -- 帳票ID
    gv_user_dept              := xxcmn_common_pkg.get_user_dept(gv_user_id);
    gv_user_name              := xxcmn_common_pkg.get_user_name(gv_user_id);
    gd_exec_date              := SYSDATE ;            -- 実施日
--
    -- ===============================
    -- 1.パラメーター・チェック
    -- ===============================
    proc_check_param(
       ov_errbuf             => lv_errbuf               -- エラー・メッセージ
      ,ov_retcode            => lv_retcode              -- リターン・コード
      ,ov_errmsg             => lv_errmsg               -- ユーザー・エラー・メッセージ
      ,iv_inventory_time     => iv_inventory_time       -- 1.棚卸年月度
      ,iv_stock_name         => iv_stock_name           -- 2.名義
      ,iv_report_post        => iv_report_post          -- 3.報告部署
      ,iv_warehouse_code     => iv_warehouse_code       -- 4.倉庫コード
      ,iv_distribution_block => iv_distribution_block   -- 5.ブロック
      ,iv_item_type          => iv_item_type            -- 6.品目区分
      ,iv_item_code          => iv_item_code);          -- 7.品目コード
--
    -- エラー処理
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 3.ＸＭＬデータ出力
    -- ===============================
    proc_create_xml_data(
       ov_errbuf             => lv_errbuf              -- エラー・メッセージ
      ,ov_retcode            => lv_retcode             -- リターン・コード
      ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ
      ,iv_inventory_time     => iv_inventory_time      -- 1.棚卸年月度
      ,iv_stock_name         => iv_stock_name          -- 2.名義
      ,iv_report_post        => iv_report_post         -- 3.報告部署
      ,iv_warehouse_code     => iv_warehouse_code      -- 4.倉庫コード
      ,iv_distribution_block => iv_distribution_block  -- 5.ブロック
      ,iv_item_type          => iv_item_type           -- 6.品目区分
      ,iv_item_code          => iv_item_code);         -- 7.品目コード
--
    -- エラー処理
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- ＸＭＬ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT,'<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
      AND ( lv_retcode = gv_status_warn ) THEN
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_warehouse>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_warehouse>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_warehouse>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_warehouse>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      -- ＸＭＬヘッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
      -- ＸＭＬデータ部出力
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := fnc_conv_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- タグタイプ
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- ＸＭＬフッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 帳票出力ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    ov_errbuf             OUT     VARCHAR2,   -- エラー・メッセージ
    ov_retcode            OUT     VARCHAR2,   -- リターン・コード
    iv_inventory_time     IN      VARCHAR2,   -- 1.棚卸年月度
    iv_stock_name         IN      VARCHAR2,   -- 2.名義
    iv_report_post        IN      VARCHAR2,   -- 3.報告部署
    iv_warehouse_code     IN      VARCHAR2,   -- 4.倉庫コード
    iv_distribution_block IN      VARCHAR2,   -- 5.ブロック
    iv_item_type          IN      VARCHAR2,   -- 6.品目区分
    iv_item_code          IN      VARCHAR2    -- 7.品目コード
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   エラー・メッセージ
    lv_retcode              VARCHAR2(1) ;         --   リターン・コード
    lv_errmsg               VARCHAR2(5000) ;      --   ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf             => lv_errbuf,               -- エラー・メッセージ
      ov_retcode            => lv_retcode,              -- リターン・コード
      ov_errmsg             => lv_errmsg,               -- ユーザー・エラー・メッセージ
      iv_inventory_time     => iv_inventory_time,       -- 1.棚卸年月度
      iv_stock_name         => iv_stock_name,           -- 2.名義
      iv_report_post        => iv_report_post,          -- 3.報告部署
      iv_warehouse_code     => iv_warehouse_code,       -- 4.倉庫コード
      iv_distribution_block => iv_distribution_block,   -- 5.ブロック
      iv_item_type          => iv_item_type,            -- 6.品目区分
      iv_item_code          => iv_item_code);           -- 7.品目コード
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      ov_errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --ステータスセット
    ov_retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxinv530003c;
/
