create or replace PACKAGE BODY xxcmn770003cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770003CP(body)
 * Description      : 受払残高表（Ⅱ）(プロト)
 * MD.050/070       : 月次〆切処理帳票Issue1.0(T_MD050_BPO_770)
 *                  : 月次〆切処理帳票Issue1.0(T_MD070_BPO_77C)
 * Version          : 1.21
 *
 * Program List
 * -------------------------- ------------------------------------------------------------
 *  Name                      Description
 * -------------------------- ------------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : XMLタグに変換する。
 *  fnc_item_unit_pric_get    FUNCTION  : 品目の原価の取得
 *  prc_initialize            PROCEDURE : 前処理(C-2)
 *  prc_get_report_data       PROCEDURE : 明細データ取得(C-3)
 *  prc_item_sum              PROCEDURE : 品目明細加算処理
 *  prc_item_init             PROCEDURE : 品目明細クリア処理
 *  prc_create_xml_data       PROCEDURE : XMLデータ作成(C-4)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/08    1.0   Y.Majikina       新規作成
 *  2008/05/15    1.1   Y.Majikina       パラメータ：処理年月がYYYYMで入力された時、エラー
 *                                       となる点を修正。
 *                                       担当部署、担当者名の最大長処理を修正。
 *  2008/05/30    1.2   Y.Ishikawa       実際原価を抽出する時、原価管理区分が実際原価の場合、
 *                                       ロット管理の対象の場合はロット別原価テーブル
 *                                       ロット管理の対象外の場合は標準原価マスタテーブルより取得
 *
 *  2008/06/12    1.3   I.Higa           取引区分が"棚卸増"または"棚卸減"の場合、マイナスデータが
 *                                       入っているので絶対値計算を行わず、設定値で集計を行う。
 *  2008/06/13    1.4   Y.Ishikawa       生産原料詳細(アドオン)の結合が不要の為削除。
 *  2008/06/24    1.5   Y.Ishikawa       金額、数量がNULLの場合は0を表示する。
 *  2008/06/25    1.6   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/05    1.7   R.Tomoyose       参照ビューの変更「xxcmn_rcv_pay_mst_porc_rma_v」→
 *                                                       「xxcmn_rcv_pay_mst_porc_rma03_v」
 *  2008/08/28    1.8   A.Shiina         取引数量は取得時に受払区分を掛ける。
 *  2008/10/22    1.9   N.Yoshida        T_S_524対応(PT対応)
 *  2008/11/04    1.10  N.Yoshida        移行リハ暫定対応
 *  2008/11/12    1.11  N.Fukuda         統合指摘#634対応(移行データ検証不具合対応)
 *  2008/11/19    1.12  N.Yoshida        I_S_684対応、移行データ検証不具合対応
 *  2008/12/08    1.13  H.Marushita      本番数値検証受注ヘッダ最新フラグおよび標準原価計算修正
 *  2008/12/08    1.14  A.Shiina         本番#562対応
 *  2008/12/11    1.15  N.Yoshida        本番障害580対応
 *  2008/12/12    1.16  N.Yoshida        本番障害669対応
 *  2009/01/13    1.17  N.Yoshida        本番障害997対応
 *  2009/03/05    1.18  H.Marushita      本番障害1274対応
 *  2009/05/29    1.19  Marushita        本番障害1511対応
 *  2009/08/12    1.20  Marushita        本番障害1608対応
 *  2009/09/07    1.21  Marushita        本番障害1639対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal          CONSTANT VARCHAR2(1)  := '0';
  gv_status_warn            CONSTANT VARCHAR2(1)  := '1';
  gv_status_error           CONSTANT VARCHAR2(1)  := '2';
  gv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  gv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
  gv_haifn                  CONSTANT VARCHAR2(1)  := '-';
  gv_ja                     CONSTANT VARCHAR2(2)  := 'JA';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'XXCMN770003CP' ;   -- パッケージ名
  gv_print_name           CONSTANT VARCHAR2(40) := '受 払 残 高 表 （Ⅱ）' ;    -- 帳票名
  gv_item_div             CONSTANT VARCHAR2(10) := '商品区分';
  gv_art_div              CONSTANT VARCHAR2(10) := '品目区分';
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gv_crowd_type           CONSTANT VARCHAR2(20)  :=  'XXCMN_MC_OUPUT_DIV';
  gv_report_type          CONSTANT VARCHAR2(100) := 'XXCMN_MONTH_TRANS_OUTPUT_TYPE';
--
  ------------------------------
  -- 出力項目の列位置最大値
  ------------------------------
  gc_print_pos_max        CONSTANT NUMBER := 13;--項目出力位置
--
  ------------------------------
  -- 原価区分
  ------------------------------
  gc_cost_ac              CONSTANT VARCHAR2(1) := '0';--実際原価
  gc_cost_st              CONSTANT VARCHAR2(1) := '1';--標準原価
--
  ------------------------------
  -- 取引区分
  ------------------------------
  gv_div_name             CONSTANT VARCHAR2(6) := '棚卸減';
--
  ------------------------------
  -- ロット管理区分
  ------------------------------
  gc_lot_n                CONSTANT xxcmn_lot_each_item_v.lot_ctl%TYPE := 0; -- ロット管理なし
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN';-- アプリケーション
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_format          CONSTANT VARCHAR2(30) := 'YYYYMMDD' ;
  gc_char_m_format        CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  gc_d                    CONSTANT VARCHAR2(1)  := 'D';
  gc_n                    CONSTANT VARCHAR2(1)  := 'N';
  gc_t                    CONSTANT VARCHAR2(1)  := 'T';
  gc_z                    CONSTANT VARCHAR2(1)  := 'Z';
  ------------------------------
  -- XML出力項目場所
  ------------------------------
  gc_hamaoka_num          CONSTANT NUMBER := 1;  -- 浜岡（受払）
  gc_rec_kind_num         CONSTANT NUMBER := 2;  -- 品種移動（受払）
  gc_rec_whse_num         CONSTANT NUMBER := 3;  -- 倉庫移動（受払）
  gc_rec_etc_num          CONSTANT NUMBER := 4;  -- その他（受払）
  gc_resale_num           CONSTANT NUMBER := 5;  -- 転売（払出）
  gc_aband_num            CONSTANT NUMBER := 6;  -- 廃却（払出）
  gc_sample_num           CONSTANT NUMBER := 7;  -- 見本（払出）
  gc_admin_num            CONSTANT NUMBER := 8;  -- 総務払出（払出）
  gc_acnt_num             CONSTANT NUMBER := 9;  -- 経理払出（払出）
  gc_dis_kind_num         CONSTANT NUMBER := 10; -- 品種移動（払出）
  gc_dis_whse_num         CONSTANT NUMBER := 11; -- 倉庫移動（払出）
  gc_dis_etc_num          CONSTANT NUMBER := 12; -- その他（払出）
  gc_inv_he_num           CONSTANT NUMBER := 13; -- 棚卸減耗（払出）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD (
    process_year        VARCHAR2(6),                             -- 処理年月
    item_division       mtl_categories_b.segment1%TYPE,          -- 商品区分
    art_division        mtl_categories_b.segment1%TYPE,          -- 品目区分
    report_type         NUMBER,                                  -- 帳票区分
    warehouse_code      ic_whse_mst.whse_code%TYPE,              -- 倉庫コード
    crowd_type          fnd_lookup_values.lookup_code%TYPE,      -- 群種別
    crowd_code          xxpo_categories_v.category_code%TYPE,    -- 群コード
    account_code        xxpo_categories_v.category_code%TYPE     -- 経理群コード
  );
--
  -- 品目明細集計レコード
  TYPE qty_array IS VARRAY(15) OF NUMBER;
  qty qty_array := qty_array(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
  TYPE amt_array IS VARRAY(15) OF NUMBER;
  amt qty_array := qty_array(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
--
  -- 受払残高表データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD (
    whse_code          ic_tran_pnd.whse_code%TYPE,              -- 倉庫コード
    whse_name          ic_whse_mst.whse_name%TYPE,              -- 倉庫名
    trans_qty          ic_tran_pnd.trans_qty%TYPE,              -- 取引数量
    trans_date         ic_tran_pnd.trans_date%TYPE,
    div_name           xxcmn_lookup_values_v.meaning%TYPE,      -- 取引区分
    pay_div            xxcmn_rcv_pay_mst.rcv_pay_div%TYPE,      -- 受払区分
    item_id            ic_item_mst_b.item_id%TYPE,              -- 品目ID
    item_code          ic_item_mst_b.item_desc1%TYPE,           -- 品目コード
    item_name          xxcmn_item_mst_b.item_short_name%TYPE,   -- 品目名称
    column_no          fnd_lookup_values.attribute3%TYPE,       -- 項目位置
    cost_div           ic_item_mst_b.attribute15%TYPE,          -- 原価管理区分
    lot_kbn            xxcmn_lot_each_item_v.lot_ctl%TYPE,      -- ロット管理区分
    crowd_code         mtl_categories_b.segment1%TYPE,          -- 詳群コード
    crowd_small        mtl_categories_b.segment1%TYPE,          -- 小群コード
    crowd_medium       mtl_categories_b.segment1%TYPE,          -- 中群コード
    crowd_large        mtl_categories_b.segment1%TYPE,          -- 大群コード
    act_unit_price     xxcmn_lot_cost.unit_ploce%TYPE           -- 実際単価
  ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_exec_start             DATE;             -- 処理年月の開始日
  gd_exec_end               DATE;             -- 処理年月の終了日
  gv_exec_start             VARCHAR2(20);     -- 処理年月の開始日
  gv_exec_end               VARCHAR2(20);     -- 処理年月の終了日
  ------------------------------
  -- ヘッダ情報取得用
  ------------------------------
-- 帳票種別
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;     -- 担当部署
  gv_user_name              per_all_people_f.per_information18%TYPE;          -- 担当者
  gv_report_div_name        fnd_lookup_values.meaning%TYPE;                   -- 帳票種別名
  gv_item_div_name          mtl_categories_tl.description%TYPE;               -- 商品区分名
  gv_art_div_name           mtl_categories_tl.description%TYPE;               -- 品目区分名
  gv_crowd_kind_name        mtl_categories_tl.description%TYPE;               -- 群種別名
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id              VARCHAR2(12);    -- 帳票ID
  gd_exec_date              DATE        ;    -- 実施日
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
--
  ------------------------------
  --  標準原価評価日付
  ------------------------------
  gd_st_unit_date         DATE; -- 2009/05/29 ADD
--
--#####################  固定共通例外宣言部 START   ####################
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
--###########################  固定部 END   ############################
--
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION fnc_conv_xml(
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml';   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_convert_data         VARCHAR2(2000);
--
  BEGIN
--
    --データの場合
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  固定部 END   #########################################
--
  END fnc_conv_xml;
--
--
--
--
  /**********************************************************************************
  * Function Name    : fnc_item_unit_pric_get
  * Description      : 品目の原価の取得
  ***********************************************************************************/
  FUNCTION fnc_item_unit_pric_get (
    in_pos   IN   NUMBER             -- 品目レコード配列位置
  )
  RETURN NUMBER
  IS
--
    -- *** ユーザ定義定数 ***
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_item_unit_pric_get';   -- プログラム名
    cn_zero        CONSTANT NUMBER        := 0;
    -- *** ユーザ定義変数 ***
    --原価戻り値
    ln_unit_price  NUMBER DEFAULT 0;
--
  BEGIN
    --原価区分＝標準原価のとき
    IF  ((gt_main_data(in_pos).cost_div = gc_cost_st)
      OR ((gt_main_data(in_pos).cost_div = gc_cost_ac)
      AND (gt_main_data(in_pos).lot_kbn = gc_lot_n))) THEN
      -- =========================================
      -- 標準原価マスタより標準単価を取得します。=
      -- =========================================
      BEGIN
-- 2008/10/22 v1.09 UPDATE START
        /*SELECT  price_v.stnd_unit_price  as price
          INTO  ln_unit_price
          FROM  xxcmn_stnd_unit_price_v price_v
         WHERE  price_v.item_id    = gt_main_data(in_pos).item_id
            AND  ((price_v.start_date_active IS NULL )
             OR   (price_v.start_date_active    <= gt_main_data(in_pos).trans_date))
            AND  ((price_v.end_date_active   IS NULL )
             OR   ( price_v.end_date_active     >= gt_main_data(in_pos).trans_date));*/
-- 2008/10/22 v1.09 UPDATE END
        SELECT  price_v.stnd_unit_price  as price
        INTO    ln_unit_price
        FROM    xxcmn_stnd_unit_price_v price_v
        WHERE   price_v.item_id    = gt_main_data(in_pos).item_id
-- 2009/05/29 MOD START
        AND     price_v.start_date_active <= gd_st_unit_date
        AND     price_v.end_date_active   >= gd_st_unit_date;
--        AND     price_v.start_date_active <= gt_main_data(in_pos).trans_date
--        AND     price_v.end_date_active   >= gt_main_data(in_pos).trans_date;
-- 2009/05/29 MOD END
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_unit_price := cn_zero;
      END;
      RETURN  ln_unit_price;
--
     --原価区分＝実際原価のとき
    ELSIF (gt_main_data(in_pos).cost_div = gc_cost_ac)  THEN
      RETURN NVL( gt_main_data(in_pos).act_unit_price, cn_zero );
    ELSE
      RETURN cn_zero;
    END IF;
--
  EXCEPTION
--###############################  固定例外処理部 START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  固定部 END   #########################################
--
  END fnc_item_unit_pric_get;
--
--
--
--
  /**********************************************************************************
  * Procedure Name   : prc_initialize
  * Description      : 前処理(C-1)
  ***********************************************************************************/
  PROCEDURE prc_initialize (
      ir_param      IN     rec_param_data,   --    入力パラメータ群
      ov_errbuf     OUT    VARCHAR2,         --    エラー・メッセージ           --# 固定 #
      ov_retcode    OUT    VARCHAR2,         --    リターン・コード             --# 固定 #
      ov_errmsg     OUT    VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    -- *** ローカル・例外処理 ***
    get_value_expt        EXCEPTION;     -- 値取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 担当部署名取得
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- 担当者名取得
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- =====================================================
    -- 商品区分名取得
    -- =====================================================
    BEGIN
-- 2008/10/22 v1.09 UPDATE START
      /*SELECT  cat.description
        INTO  gv_item_div_name
        FROM  xxcmn_categories2_v cat
       WHERE  cat.category_set_name = gv_item_div
         AND  cat.segment1          = ir_param.item_division;*/
      SELECT mct.description
      INTO   gv_item_div_name
      FROM   mtl_category_sets_b mcsb
            ,mtl_categories_b mcb
            ,mtl_categories_tl mct
      WHERE  mcsb.structure_id    = mcb.structure_id
      AND    mcsb.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'))
      AND    mcb.segment1         = ir_param.item_division
      AND    mcb.category_id      = mct.category_id
      AND    mct.language         = 'JA'
      ;
-- 2008/10/22 v1.09 UPDATE END
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- =====================================================
    -- 品目区分名取得
    -- =====================================================
    BEGIN
-- 2008/10/22 v1.09 UPDATE START
      /*SELECT  cat.description
        INTO  gv_art_div_name
        FROM  xxcmn_categories2_v cat
       WHERE  cat.category_set_name = gv_art_div
         AND  cat.segment1          = ir_param.art_division;*/
      SELECT mct.description
      INTO   gv_art_div_name
      FROM   mtl_category_sets_b mcsb
            ,mtl_categories_b mcb
            ,mtl_categories_tl mct
      WHERE  mcsb.structure_id    = mcb.structure_id
      AND    mcsb.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
      AND    mcb.segment1         = ir_param.art_division
      AND    mcb.category_id      = mct.category_id
      AND    mct.language         = 'JA'
      ;
-- 2008/10/22 v1.09 UPDATE END
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- ====================================================
    -- 帳票種別取得
    -- ====================================================
    BEGIN
      SELECT  lvv.meaning
        INTO  gv_report_div_name
        FROM  xxcmn_lookup_values_v lvv
       WHERE  lvv.lookup_type   = gv_report_type
         AND  lvv.lookup_code   = ir_param.report_type;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- ====================================================
    -- 群種別名取得
    -- ====================================================
    BEGIN
      SELECT  lvv.meaning
        INTO  gv_crowd_kind_name
        FROM  xxcmn_lookup_values_v lvv
       WHERE  lvv.lookup_type   = gv_crowd_type
         AND  lvv.lookup_code   = ir_param.crowd_type;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
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
  END prc_initialize;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(C-2)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ir_param      IN  rec_param_data,            --    入力パラメータ群
      ot_data_rec   OUT NOCOPY tab_data_type_dtl,  --    取得レコード群
      ov_errbuf     OUT VARCHAR2,                  --    エラー・メッセージ           --# 固定 #
      ov_retcode    OUT VARCHAR2,                  --    リターン・コード             --# 固定 #
      ov_errmsg     OUT VARCHAR2                   --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- プログラム名
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
    -- *** ローカル・定数 ***
    cv_process_year   CONSTANT VARCHAR2(8)  := '処理年月';
    cv_min            CONSTANT VARCHAR2(2)  := '-1';
    cv_one            CONSTANT VARCHAR2(1)  := '1';
    cv_two            CONSTANT VARCHAR2(1)  := '2';
    cv_three          CONSTANT VARCHAR2(1)  := '3';
    cv_four           CONSTANT VARCHAR2(1)  := '4';
    cv_yes            CONSTANT VARCHAR2(1)  := 'Y';
    cv_lang           CONSTANT VARCHAR2(2)  := 'JA';
    cv_lookup         CONSTANT VARCHAR2(40) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
    cv_lookup2        CONSTANT VARCHAR2(40) := 'XXCMN_DEALINGS_DIV';
    cv_meaning        CONSTANT VARCHAR2(10) := '品目振替';
    cn_zero           CONSTANT NUMBER       := 0;
    cn_one            CONSTANT NUMBER       := 1;
    cn_min            CONSTANT NUMBER       := -1;
    -- 文書タイプ
    cv_xfer           CONSTANT VARCHAR2(4)  := 'XFER';
    cv_trni           CONSTANT VARCHAR2(4)  := 'TRNI';
    cv_adji           CONSTANT VARCHAR2(4)  := 'ADJI';
    cv_prod           CONSTANT VARCHAR2(4)  := 'PROD';
    cv_omso           CONSTANT VARCHAR2(4)  := 'OMSO';
    cv_porc           CONSTANT VARCHAR2(4)  := 'PORC';
    -- 事由コード    
-- 2008/10/22 v1.09 ADD START
    cv_reason_122     CONSTANT VARCHAR2(4)  := 'X122';
    cv_reason_943     CONSTANT VARCHAR2(4)  := 'X943';
    cv_reason_950     CONSTANT VARCHAR2(4)  := 'X950';
-- 2008/10/22 v1.09 ADD END
    cv_reason_123     CONSTANT VARCHAR2(4)  := 'X123';
    cv_reason_911     CONSTANT VARCHAR2(4)  := 'X911';
    cv_reason_912     CONSTANT VARCHAR2(4)  := 'X912';
    cv_reason_921     CONSTANT VARCHAR2(4)  := 'X921';
    cv_reason_922     CONSTANT VARCHAR2(4)  := 'X922';
    cv_reason_941     CONSTANT VARCHAR2(4)  := 'X941';
    cv_reason_931     CONSTANT VARCHAR2(4)  := 'X931';
    cv_reason_932     CONSTANT VARCHAR2(4)  := 'X932';
    cv_reason_942     CONSTANT VARCHAR2(4)  := 'X942';
    cv_reason_951     CONSTANT VARCHAR2(4)  := 'X951';
    cv_reason_988     CONSTANT VARCHAR2(4)  := 'X988';
    cv_dealing_309    CONSTANT VARCHAR2(3)  := '309';
    lc_f_time         CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time         CONSTANT VARCHAR2(10) := ' 23:59:59';
      -- 2008/11/4 modify yoshida 暫定ロジック start
    cv_reason_953     CONSTANT VARCHAR2(4)  := 'X953';
    cv_reason_955     CONSTANT VARCHAR2(4)  := 'X955';
    cv_reason_957     CONSTANT VARCHAR2(4)  := 'X957';
    cv_reason_959     CONSTANT VARCHAR2(4)  := 'X959';
    cv_reason_961     CONSTANT VARCHAR2(4)  := 'X961';
    cv_reason_963     CONSTANT VARCHAR2(4)  := 'X963';
    cv_reason_952     CONSTANT VARCHAR2(4)  := 'X952';
    cv_reason_954     CONSTANT VARCHAR2(4)  := 'X954';
    cv_reason_956     CONSTANT VARCHAR2(4)  := 'X956';
    cv_reason_958     CONSTANT VARCHAR2(4)  := 'X958';
    cv_reason_960     CONSTANT VARCHAR2(4)  := 'X960';
    cv_reason_962     CONSTANT VARCHAR2(4)  := 'X962';
    cv_reason_964     CONSTANT VARCHAR2(4)  := 'X964';
    cv_reason_965     CONSTANT VARCHAR2(4)  := 'X965';
    cv_reason_966     CONSTANT VARCHAR2(4)  := 'X966';
      -- 2008/11/4 modify yoshida 暫定ロジック end
--
-- 2008/10/22 v1.09 ADD START
    cn_prod_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cn_acnt_crowd_code_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));
-- 2008/10/22 v1.09 ADD END
--
    -- *** ローカル・変数 ***
-- 2008/10/22 v1.09 DELETE START
    /*-- XFER
    lv_select_xfer       VARCHAR2(32000);
    lv_from_xfer         VARCHAR2(32000);
    lv_where_xfer        VARCHAR2(32000);
    lv_sql_xfer          VARCHAR2(32000);
    -- TRNI
    lv_select_trni       VARCHAR2(32000);
    lv_from_trni         VARCHAR2(32000);
    lv_where_trni        VARCHAR2(32000);
    lv_sql_trni          VARCHAR2(32000);
    -- ADJI_1
    lv_select_adji_1     VARCHAR2(32000);
    lv_from_adji_1       VARCHAR2(32000);
    lv_where_adji_1      VARCHAR2(32000);
    lv_sql_adji_1        VARCHAR2(32000);
    -- ADJI_2
    lv_select_adji_2     VARCHAR2(32000);
    lv_from_adji_2       VARCHAR2(32000);
    lv_where_adji_2      VARCHAR2(32000);
    lv_sql_adji_2        VARCHAR2(32000);
    --  ADJI_3
    lv_select_adji_3     VARCHAR2(32000);
    lv_from_adji_3       VARCHAR2(32000);
    lv_where_adji_3      VARCHAR2(32000);
    lv_sql_adji_3        VARCHAR2(32000);
    -- ADJI_4
    lv_select_adji_4     VARCHAR2(32000);
    lv_from_adji_4       VARCHAR2(32000);
    lv_where_adji_4      VARCHAR2(32000);
    lv_sql_adji_4        VARCHAR2(32000);
    -- PROD
    lv_select_prod       VARCHAR2(32000);
    lv_from_prod         VARCHAR2(32000);
    lv_where_prod        VARCHAR2(32000);
    lv_sql_prod          VARCHAR2(32000);
    --  OMSO
    lv_select_omso       VARCHAR2(32000);
    lv_from_omso         VARCHAR2(32000);
    lv_where_omso        VARCHAR2(32000);
    lv_sql_omso          VARCHAR2(32000);
    --  PORC
    lv_select_porc       VARCHAR2(32000);
    lv_from_porc         VARCHAR2(32000);
    lv_where_porc        VARCHAR2(32000);
    lv_sql_porc          VARCHAR2(32000);
    -- 共通SELECT
    lv_select            VARCHAR2(32000);
    -- 共通WHERE
    lv_where             VARCHAR2(32000);
    -- 共通WHERE itp
    lv_where_itp         VARCHAR2(32000);
    -- 共通WHERE itc
    lv_where_itc         VARCHAR2(32000);
    -- ORDER BY
    lv_order             VARCHAR2(32000);*/
-- 2008/10/22 v1.09 DELETE END
    ln_crowd_code_id NUMBER;
    lt_crowd_code    mtl_categories_b.segment1%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・カーソル ***
    TYPE ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
-- 2008/10/22 v1.09 ADD START
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 倉庫・品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力なし
    -- 検索条件.群コード          ⇒ 入力あり
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur01 IS --XFER
      -- ----------------------------------------------------
      -- XFER :経理受払区分移動積送あり
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             iwm.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_xfer_mst                ixm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_xfer
      AND    itp.completed_ind       = cn_one
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ixm.transfer_id         = itp.doc_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itp.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- TRNI :経理受払区分移動積送なし
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             iwm.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_trni
      AND    itc.reason_code         = cv_reason_122
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(他)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code              whse_code
            ,iwm.whse_name              whse_name
-- 2008/12/11 v1.15 N.Yoshida mod start
--            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            -- 棚卸増は、払出項目(棚卸減耗)に出力する為、数量の符号を変換する
            ,CASE WHEN xrpm.rcv_pay_div = cv_min
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
                  WHEN xrpm.rcv_pay_div = cv_one AND itc.reason_code = cv_reason_911
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) * cn_min
                  ELSE NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
-- 2008/12/11 v1.15 N.Yoshida mod start
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type          = cv_adji
      AND    itc.reason_code       IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_953
                                      ,cv_reason_955
                                      ,cv_reason_957
                                      ,cv_reason_959
                                      ,cv_reason_961
                                      ,cv_reason_963
                                      ,cv_reason_952
                                      ,cv_reason_954
                                      ,cv_reason_956
                                      ,cv_reason_958
                                      ,cv_reason_960
                                      ,cv_reason_962
                                      ,cv_reason_964
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_965
                                      ,cv_reason_966
-- 2008/11/19 v1.12 ADD END
                                      ,cv_reason_932)
      AND    itc.trans_date     >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date     <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(浜岡)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_988
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(移動)
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code              whse_code
            ,iwm.whse_name              whse_name
-- 2008/12/11 v1.15 UPDATE START
--            ,ABS(itc.trans_qty) * TO_NUMBER(cv_min) trans_qty
-- 2008/12/12 v1.16 UPDATE START
--            ,NVL(itc.trans_qty,0)       trans_qty
            ,NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)  trans_qty
-- 2008/12/12 v1.16 UPDATE END
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
-- 2008/12/08 v1.14 UPDATE START
--            ,xrpm.rcv_pay_div           pay_div
--            ,TO_CHAR(TO_NUMBER(xrpm.rcv_pay_div) * TO_NUMBER(cv_min)) pay_div
            ,xrpm.rcv_pay_div           pay_div
-- 2008/12/08 v1.14 UPDATE END
-- 2008/12/11 v1.15 UPDATE END
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmrl
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_123
      AND    xmrih.mov_hdr_id        = xmrl.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/12/11 v1.15 UPDATE START
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
--                                         THEN cv_one
                                         THEN cv_min
                                         WHEN itc.trans_qty <  cn_zero
--                                         THEN cv_min
                                         THEN cv_one
                                         ELSE xrpm.rcv_pay_div
                                       END
-- 2008/12/11 v1.15 UPDATE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(その他払出)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code        IN (cv_reason_942,cv_reason_943,cv_reason_950,cv_reason_951)
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/11/19 v1.12 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                   WHEN itc.trans_qty >= cn_zero
      --                                   THEN cv_one
      --                                   ELSE cv_min
      --                                 END
-- 2008/11/19 v1.12 DELETE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- PROD :経理受払区分生産関連（Reverse_idなし）品種・品目振替なし
      -- ----------------------------------------------------
      SELECT /*+ leading (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm) use_nl (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm)*/
             iwm.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_prod
      AND    itp.completed_ind       = cn_one
      AND    itp.reverse_id          IS NULL
      AND    itp.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itp.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
-- 2009/08/12 DEL START
--      AND    mcb2.segment1           IN ('1','4')
-- 2009/08/12 DEL END
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/08/12 MOD START
-- 2009/09/07 MOD START
--      AND    xrpm.dealings_div IN('306','309')
      AND    ((xrpm.dealings_div = '306' AND mcb2.segment1 = '5') OR 
              (xrpm.dealings_div = '309' AND mcb2.segment1 IN ('1','4'))
             )
-- 2009/09/07 MOD END
      AND ((xrpm.routing_class    <> '70') OR 
           ((xrpm.routing_class     = '70')
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd2
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd2.batch_id   = gmd.batch_id
                            AND    gmd2.line_no    = gmd.line_no
                            AND    gmd2.line_type  = -1
                            AND    gic.item_id     = gmd2.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_origin))
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd3
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd3.batch_id   = gmd.batch_id
                            AND    gmd3.line_no    = gmd.line_no
                            AND    gmd3.line_type  = 1
                            AND    gic.item_id     = gmd3.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_ahead))
            ))
--      AND    xrpm.dealings_div       = cv_dealing_309
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd2
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd2.batch_id   = gmd.batch_id
--                      AND    gmd2.line_no    = gmd.line_no
--                      AND    gmd2.line_type  = -1
--                      AND    gic.item_id     = gmd2.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_origin))
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd3
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd3.batch_id   = gmd.batch_id
--                      AND    gmd3.line_no    = gmd.line_no
--                     AND    gmd3.line_type  = 1
--                      AND    gic.item_id     = gmd3.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_ahead))
-- 2009/08/12 MOD END
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
    -- ----------------------------------------------------
    -- OMSO8 :経理受払区分受注関連 (見本,廃却)
    -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) */
             iwm.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- PORC8 :経理受払区分購買関連 (見本,廃却)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */
             iwm.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      ORDER BY whse_code ASC, crowd_code ASC,item_code ASC
      ;
--
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 倉庫・品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力なし
    -- 検索条件.群コード          ⇒ 入力なし
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur02 IS --XFER
      -- ----------------------------------------------------
      -- XFER :経理受払区分移動積送あり
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_xfer_mst                ixm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_xfer
      AND    itp.completed_ind       = cn_one
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ixm.transfer_id         = itp.doc_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itp.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- TRNI :経理受払区分移動積送なし
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_trni
      AND    itc.reason_code         = cv_reason_122
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(他)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
-- 2008/12/11 v1.15 N.Yoshida mod start
--            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            -- 棚卸増は、払出項目(棚卸減耗)に出力する為、数量の符号を変換する
            ,CASE WHEN xrpm.rcv_pay_div = cv_min
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
                  WHEN xrpm.rcv_pay_div = cv_one AND itc.reason_code = cv_reason_911
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) * cn_min
                  ELSE NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
-- 2008/12/11 v1.15 N.Yoshida mod start
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type          = cv_adji
      AND    itc.reason_code       IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_953
                                      ,cv_reason_955
                                      ,cv_reason_957
                                      ,cv_reason_959
                                      ,cv_reason_961
                                      ,cv_reason_963
                                      ,cv_reason_952
                                      ,cv_reason_954
                                      ,cv_reason_956
                                      ,cv_reason_958
                                      ,cv_reason_960
                                      ,cv_reason_962
                                      ,cv_reason_964
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_965
                                      ,cv_reason_966
-- 2008/11/19 v1.12 ADD END
                                      ,cv_reason_932)
      AND    itc.trans_date     >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date     <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(浜岡)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_988
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(移動)
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
-- 2008/12/11 v1.15 UPDATE START
--            ,ABS(itc.trans_qty) * TO_NUMBER(cv_min) trans_qty
-- 2008/12/12 v1.16 UPDATE START
--            ,NVL(itc.trans_qty,0)       trans_qty
            ,NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)  trans_qty
-- 2008/12/12 v1.16 UPDATE END
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
-- 2008/12/08 v1.14 UPDATE START
--            ,xrpm.rcv_pay_div           pay_div
--            ,TO_CHAR(TO_NUMBER(xrpm.rcv_pay_div) * TO_NUMBER(cv_min)) pay_div
            ,xrpm.rcv_pay_div           pay_div
-- 2008/12/08 v1.14 UPDATE END
-- 2008/12/11 v1.15 UPDATE END
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmrl
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_123
      AND    xmrih.mov_hdr_id        = xmrl.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/12/11 v1.15 UPDATE START
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
--                                         THEN cv_one
                                         THEN cv_min
                                         WHEN itc.trans_qty <  cn_zero
--                                         THEN cv_min
                                         THEN cv_one
                                         ELSE xrpm.rcv_pay_div
                                       END
-- 2008/12/11 v1.15 UPDATE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(その他払出)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code        IN (cv_reason_942,cv_reason_943,cv_reason_950,cv_reason_951)
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/11/19 v1.12 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                   WHEN itc.trans_qty >= cn_zero
      --                                   THEN cv_one
      --                                   ELSE cv_min
      --                                 END
-- 2008/11/19 v1.12 DELETE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- PROD :経理受払区分生産関連（Reverse_idなし）品種・品目振替なし
      -- ----------------------------------------------------
      SELECT /*+ leading (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm) use_nl (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm)*/
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_prod
      AND    itp.completed_ind       = cn_one
      AND    itp.reverse_id          IS NULL
      AND    itp.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itp.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
-- 2009/08/12 DEL START
--      AND    mcb2.segment1           IN ('1','4')
-- 2009/08/12 DEL END
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/08/12 MOD START
-- 2009/09/07 MOD START
--      AND    xrpm.dealings_div IN('306','309')
      AND    ((xrpm.dealings_div = '306' AND mcb2.segment1 = '5') OR 
              (xrpm.dealings_div = '309' AND mcb2.segment1 IN ('1','4'))
             )
-- 2009/09/07 MOD END
      AND ((xrpm.routing_class    <> '70') OR 
           ((xrpm.routing_class     = '70')
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd2
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd2.batch_id   = gmd.batch_id
                            AND    gmd2.line_no    = gmd.line_no
                            AND    gmd2.line_type  = -1
                            AND    gic.item_id     = gmd2.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_origin))
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd3
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd3.batch_id   = gmd.batch_id
                            AND    gmd3.line_no    = gmd.line_no
                            AND    gmd3.line_type  = 1
                            AND    gic.item_id     = gmd3.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_ahead))
            ))
--      AND    xrpm.dealings_div       = cv_dealing_309
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd2
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd2.batch_id   = gmd.batch_id
--                      AND    gmd2.line_no    = gmd.line_no
--                      AND    gmd2.line_type  = -1
--                      AND    gic.item_id     = gmd2.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_origin))
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd3
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd3.batch_id   = gmd.batch_id
--                      AND    gmd3.line_no    = gmd.line_no
--                      AND    gmd3.line_type  = 1
--                      AND    gic.item_id     = gmd3.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_ahead))
-- 2009/08/12 MOD END
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
    -- ----------------------------------------------------
    -- OMSO8 :経理受払区分受注関連 (見本,廃却)
    -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- PORC8 :経理受払区分購買関連 (見本,廃却)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      ORDER BY h_whse_code ASC, crowd_code ASC,item_code ASC
      ;
--
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 倉庫・品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力あり
    -- 検索条件.群コード          ⇒ 入力あり
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur03 IS --XFER
      -- ----------------------------------------------------
      -- XFER :経理受払区分移動積送あり
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_xfer_mst                ixm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_xfer
      AND    itp.completed_ind       = cn_one
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ixm.transfer_id         = itp.doc_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itp.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- TRNI :経理受払区分移動積送なし
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_trni
      AND    itc.reason_code         = cv_reason_122
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(他)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
-- 2008/12/11 v1.15 N.Yoshida mod start
--            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            -- 棚卸増は、払出項目(棚卸減耗)に出力する為、数量の符号を変換する
            ,CASE WHEN xrpm.rcv_pay_div = cv_min
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
                  WHEN xrpm.rcv_pay_div = cv_one AND itc.reason_code = cv_reason_911
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) * cn_min
                  ELSE NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
-- 2008/12/11 v1.15 N.Yoshida mod start
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type          = cv_adji
      AND    itc.reason_code       IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_953
                                      ,cv_reason_955
                                      ,cv_reason_957
                                      ,cv_reason_959
                                      ,cv_reason_961
                                      ,cv_reason_963
                                      ,cv_reason_952
                                      ,cv_reason_954
                                      ,cv_reason_956
                                      ,cv_reason_958
                                      ,cv_reason_960
                                      ,cv_reason_962
                                      ,cv_reason_964
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_965
                                      ,cv_reason_966
-- 2008/11/19 v1.12 ADD END
                                      ,cv_reason_932)
      AND    itc.trans_date     >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date     <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(浜岡)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_988
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(移動)
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
-- 2008/12/11 v1.15 UPDATE START
--            ,ABS(itc.trans_qty) * TO_NUMBER(cv_min) trans_qty
-- 2008/12/12 v1.16 UPDATE START
--            ,NVL(itc.trans_qty,0)       trans_qty
            ,NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)  trans_qty
-- 2008/12/12 v1.16 UPDATE END
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
-- 2008/12/08 v1.14 UPDATE START
--            ,xrpm.rcv_pay_div           pay_div
--            ,TO_CHAR(TO_NUMBER(xrpm.rcv_pay_div) * TO_NUMBER(cv_min)) pay_div
            ,xrpm.rcv_pay_div           pay_div
-- 2008/12/08 v1.14 UPDATE END
-- 2008/12/11 v1.15 UPDATE END
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmrl
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_123
      AND    xmrih.mov_hdr_id        = xmrl.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/12/11 v1.15 UPDATE START
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
--                                         THEN cv_one
                                         THEN cv_min
                                         WHEN itc.trans_qty <  cn_zero
--                                         THEN cv_min
                                         THEN cv_one
                                         ELSE xrpm.rcv_pay_div
                                       END
-- 2008/12/11 v1.15 UPDATE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(その他払出)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code        IN (cv_reason_942,cv_reason_943,cv_reason_950,cv_reason_951)
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/11/19 v1.12 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                   WHEN itc.trans_qty >= cn_zero
      --                                   THEN cv_one
      --                                   ELSE cv_min
      --                                 END
-- 2008/11/19 v1.12 DELETE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- PROD :経理受払区分生産関連（Reverse_idなし）品種・品目振替なし
      -- ----------------------------------------------------
      SELECT /*+ leading (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm) use_nl (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm)*/
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_prod
      AND    itp.completed_ind       = cn_one
      AND    itp.reverse_id          IS NULL
      AND    itp.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itp.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
-- 2009/08/12 DEL START
--      AND    mcb2.segment1           IN ('1','4')
-- 2009/08/12 DEL END
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/08/12 MOD START
-- 2009/09/07 MOD START
--      AND    xrpm.dealings_div IN('306','309')
      AND    ((xrpm.dealings_div = '306' AND mcb2.segment1 = '5') OR 
              (xrpm.dealings_div = '309' AND mcb2.segment1 IN ('1','4'))
             )
-- 2009/09/07 MOD END
      AND ((xrpm.routing_class    <> '70') OR 
           ((xrpm.routing_class     = '70')
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd2
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd2.batch_id   = gmd.batch_id
                            AND    gmd2.line_no    = gmd.line_no
                            AND    gmd2.line_type  = -1
                            AND    gic.item_id     = gmd2.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_origin))
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd3
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd3.batch_id   = gmd.batch_id
                            AND    gmd3.line_no    = gmd.line_no
                            AND    gmd3.line_type  = 1
                            AND    gic.item_id     = gmd3.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_ahead))
            ))
--      AND    xrpm.dealings_div       = cv_dealing_309
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd2
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd2.batch_id   = gmd.batch_id
--                      AND    gmd2.line_no    = gmd.line_no
--                      AND    gmd2.line_type  = -1
--                      AND    gic.item_id     = gmd2.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_origin))
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd3
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd3.batch_id   = gmd.batch_id
--                      AND    gmd3.line_no    = gmd.line_no
--                      AND    gmd3.line_type  = 1
--                      AND    gic.item_id     = gmd3.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_ahead))
-- 2009/08/12 MOD START
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
    -- ----------------------------------------------------
    -- OMSO8 :経理受払区分受注関連 (見本,廃却)
    -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- PORC8 :経理受払区分購買関連 (見本,廃却)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    mcb3.segment1           = lt_crowd_code
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      ORDER BY h_whse_code ASC, crowd_code ASC,item_code ASC
      ;
--
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 倉庫・品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力あり
    -- 検索条件.群コード          ⇒ 入力なし
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur04 IS --XFER
      -- ----------------------------------------------------
      -- XFER :経理受払区分移動積送あり
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_xfer_mst                ixm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_xfer
      AND    itp.completed_ind       = cn_one
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ixm.transfer_id         = itp.doc_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itp.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- TRNI :経理受払区分移動積送なし
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_trni
      AND    itc.reason_code         = cv_reason_122
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(他)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
-- 2008/12/11 v1.15 N.Yoshida mod start
--            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            -- 棚卸増は、払出項目(棚卸減耗)に出力する為、数量の符号を変換する
            ,CASE WHEN xrpm.rcv_pay_div = cv_min
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
                  WHEN xrpm.rcv_pay_div = cv_one AND itc.reason_code = cv_reason_911
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) * cn_min
                  ELSE NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
-- 2008/12/11 v1.15 N.Yoshida mod start
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type          = cv_adji
      AND    itc.reason_code       IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_953
                                      ,cv_reason_955
                                      ,cv_reason_957
                                      ,cv_reason_959
                                      ,cv_reason_961
                                      ,cv_reason_963
                                      ,cv_reason_952
                                      ,cv_reason_954
                                      ,cv_reason_956
                                      ,cv_reason_958
                                      ,cv_reason_960
                                      ,cv_reason_962
                                      ,cv_reason_964
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_965
                                      ,cv_reason_966
-- 2008/11/19 v1.12 ADD END
                                      ,cv_reason_932)
      AND    itc.trans_date     >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date     <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(浜岡)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_988
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(移動)
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
-- 2008/12/11 v1.15 UPDATE START
--            ,ABS(itc.trans_qty) * TO_NUMBER(cv_min) trans_qty
-- 2008/12/12 v1.16 UPDATE START
--            ,NVL(itc.trans_qty,0)       trans_qty
            ,NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)  trans_qty
-- 2008/12/12 v1.16 UPDATE END
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
-- 2008/12/08 v1.14 UPDATE START
--            ,xrpm.rcv_pay_div           pay_div
--            ,TO_CHAR(TO_NUMBER(xrpm.rcv_pay_div) * TO_NUMBER(cv_min)) pay_div
            ,xrpm.rcv_pay_div           pay_div
-- 2008/12/08 v1.14 UPDATE END
-- 2008/12/11 v1.15 UPDATE END
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmrl
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_123
      AND    xmrih.mov_hdr_id        = xmrl.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/12/11 v1.15 UPDATE START
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
--                                         THEN cv_one
                                         THEN cv_min
                                         WHEN itc.trans_qty <  cn_zero
--                                         THEN cv_min
                                         THEN cv_one
                                         ELSE xrpm.rcv_pay_div
                                       END
-- 2008/12/11 v1.15 UPDATE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(その他払出)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code        IN (cv_reason_942,cv_reason_943,cv_reason_950,cv_reason_951)
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/11/19 v1.12 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                   WHEN itc.trans_qty >= cn_zero
      --                                   THEN cv_one
      --                                   ELSE cv_min
      --                                 END
-- 2008/11/19 v1.12 DELETE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- PROD :経理受払区分生産関連（Reverse_idなし）品種・品目振替なし
      -- ----------------------------------------------------
      SELECT /*+ leading (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm) use_nl (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm)*/
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_prod
      AND    itp.completed_ind       = cn_one
      AND    itp.reverse_id          IS NULL
      AND    itp.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itp.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
-- 2009/08/12 DEL START
--      AND    mcb2.segment1           IN ('1','4')
-- 2009/08/12 DEL END
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/08/12 MOD START
-- 2009/09/07 MOD START
--      AND    xrpm.dealings_div IN('306','309')
      AND    ((xrpm.dealings_div = '306' AND mcb2.segment1 = '5') OR 
              (xrpm.dealings_div = '309' AND mcb2.segment1 IN ('1','4'))
             )
-- 2009/09/07 MOD END
      AND ((xrpm.routing_class    <> '70') OR 
           ((xrpm.routing_class     = '70')
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd2
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd2.batch_id   = gmd.batch_id
                            AND    gmd2.line_no    = gmd.line_no
                            AND    gmd2.line_type  = -1
                            AND    gic.item_id     = gmd2.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_origin))
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd3
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd3.batch_id   = gmd.batch_id
                            AND    gmd3.line_no    = gmd.line_no
                            AND    gmd3.line_type  = 1
                            AND    gic.item_id     = gmd3.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_ahead))
            ))
--      AND    xrpm.dealings_div       = cv_dealing_309
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd2
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd2.batch_id   = gmd.batch_id
--                      AND    gmd2.line_no    = gmd.line_no
--                      AND    gmd2.line_type  = -1
--                      AND    gic.item_id     = gmd2.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_origin))
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd3
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd3.batch_id   = gmd.batch_id
--                      AND    gmd3.line_no    = gmd.line_no
--                      AND    gmd3.line_type  = 1
--                      AND    gic.item_id     = gmd3.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_ahead))
-- 2009/08/12 MOD END
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
    -- ----------------------------------------------------
    -- OMSO8 :経理受払区分受注関連 (見本,廃却)
    -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.whse_code           = ir_param.warehouse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- PORC8 :経理受払区分購買関連 (見本,廃却)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */
             iwm.whse_code              h_whse_code
            ,iwm.whse_name              h_whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                      iwm
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      AND    iwm.whse_code           = ir_param.warehouse_code
      ORDER BY h_whse_code ASC, crowd_code ASC,item_code ASC
      ;
--
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力なし
    -- 検索条件.群コード          ⇒ 入力あり
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur05 IS --XFER
      -- ----------------------------------------------------
      -- XFER :経理受払区分移動積送あり
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_xfer_mst                ixm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_xfer
      AND    itp.completed_ind       = cn_one
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ixm.transfer_id         = itp.doc_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itp.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- TRNI :経理受払区分移動積送なし
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_trni
      AND    itc.reason_code         = cv_reason_122
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(他)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             NULL                       whse_code
            ,NULL                       whse_name
-- 2008/12/11 v1.15 N.Yoshida mod start
--            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            -- 棚卸増は、払出項目(棚卸減耗)に出力する為、数量の符号を変換する
            ,CASE WHEN xrpm.rcv_pay_div = cv_min
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
                  WHEN xrpm.rcv_pay_div = cv_one AND itc.reason_code = cv_reason_911
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) * cn_min
                  ELSE NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
-- 2008/12/11 v1.15 N.Yoshida mod start
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type          = cv_adji
      AND    itc.reason_code       IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_953
                                      ,cv_reason_955
                                      ,cv_reason_957
                                      ,cv_reason_959
                                      ,cv_reason_961
                                      ,cv_reason_963
                                      ,cv_reason_952
                                      ,cv_reason_954
                                      ,cv_reason_956
                                      ,cv_reason_958
                                      ,cv_reason_960
                                      ,cv_reason_962
                                      ,cv_reason_964
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_965
                                      ,cv_reason_966
-- 2008/11/19 v1.12 ADD END
                                      ,cv_reason_932)
      AND    itc.trans_date     >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date     <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(浜岡)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_988
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(移動)
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             NULL                       whse_code
            ,NULL                       whse_name
-- 2008/12/11 v1.15 UPDATE START
--            ,ABS(itc.trans_qty) * TO_NUMBER(cv_min) trans_qty
-- 2008/12/12 v1.16 UPDATE START
--            ,NVL(itc.trans_qty,0)       trans_qty
            ,NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)  trans_qty
-- 2008/12/12 v1.16 UPDATE END
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
-- 2008/12/08 v1.14 UPDATE START
--            ,xrpm.rcv_pay_div           pay_div
--            ,TO_CHAR(TO_NUMBER(xrpm.rcv_pay_div) * TO_NUMBER(cv_min)) pay_div
            ,xrpm.rcv_pay_div           pay_div
-- 2008/12/08 v1.14 UPDATE END
-- 2008/12/11 v1.15 UPDATE END
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmrl
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_123
      AND    xmrih.mov_hdr_id        = xmrl.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/12/11 v1.15 UPDATE START
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
--                                         THEN cv_one
                                         THEN cv_min
                                         WHEN itc.trans_qty <  cn_zero
--                                         THEN cv_min
                                         THEN cv_one
                                         ELSE xrpm.rcv_pay_div
                                       END
-- 2008/12/11 v1.15 UPDATE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(その他払出)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code        IN (cv_reason_942,cv_reason_943,cv_reason_950,cv_reason_951)
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/11/19 v1.12 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                   WHEN itc.trans_qty >= cn_zero
      --                                   THEN cv_one
      --                                   ELSE cv_min
      --                                 END
-- 2008/11/19 v1.12 DELETE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- PROD :経理受払区分生産関連（Reverse_idなし）品種・品目振替なし
      -- ----------------------------------------------------
      SELECT /*+ leading (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm) use_nl (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm)*/
             NULL                       whse_code
            ,NULL                       whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_prod
      AND    itp.completed_ind       = cn_one
      AND    itp.reverse_id          IS NULL
      AND    itp.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itp.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
-- 2009/08/12 DEL START
--      AND    mcb2.segment1           IN ('1','4')
-- 2009/08/12 DEL END
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/08/12 MOD START
-- 2009/09/07 MOD START
--      AND    xrpm.dealings_div IN('306','309')
      AND    ((xrpm.dealings_div = '306' AND mcb2.segment1 = '5') OR 
              (xrpm.dealings_div = '309' AND mcb2.segment1 IN ('1','4'))
             )
-- 2009/09/07 MOD END
      AND ((xrpm.routing_class    <> '70') OR 
           ((xrpm.routing_class     = '70')
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd2
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd2.batch_id   = gmd.batch_id
                            AND    gmd2.line_no    = gmd.line_no
                            AND    gmd2.line_type  = -1
                            AND    gic.item_id     = gmd2.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_origin))
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd3
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd3.batch_id   = gmd.batch_id
                            AND    gmd3.line_no    = gmd.line_no
                            AND    gmd3.line_type  = 1
                            AND    gic.item_id     = gmd3.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_ahead))
            ))
--      AND    xrpm.dealings_div       = cv_dealing_309
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd2
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd2.batch_id   = gmd.batch_id
--                      AND    gmd2.line_no    = gmd.line_no
--                      AND    gmd2.line_type  = -1
--                      AND    gic.item_id     = gmd2.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_origin))
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd3
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd3.batch_id   = gmd.batch_id
--                      AND    gmd3.line_no    = gmd.line_no
--                      AND    gmd3.line_type  = 1
--                      AND    gic.item_id     = gmd3.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_ahead))
-- 2009/08/12 MOD END
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
    -- ----------------------------------------------------
    -- OMSO8 :経理受払区分受注関連 (見本,廃却)
    -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      UNION ALL
      -- ----------------------------------------------------
      -- PORC8 :経理受払区分購買関連 (見本,廃却)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      AND    mcb3.segment1           = lt_crowd_code
      ORDER BY crowd_code ASC,item_code ASC
      ;
--
    --===============================================================
    -- 検索条件.帳票種別          ⇒ 品目別
    -- 検索条件.群種別            ⇒ 群別
    -- 検索条件.倉庫コード        ⇒ 入力なし
    -- 検索条件.群コード          ⇒ 入力なし
    -- 検索条件.経理群コード      ⇒ 入力なし/入力あり
    --===============================================================
    CURSOR get_data_cur06 IS --XFER
      -- ----------------------------------------------------
      -- XFER :経理受払区分移動積送あり
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrih xmril ixm itp gic2 mcb2 gic1 mcb1 iimb ximb) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_xfer_mst                ixm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_xfer
      AND    itp.completed_ind       = cn_one
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ixm.transfer_id         = itp.doc_id
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itp.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- TRNI :経理受払区分移動積送なし
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmril
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_trni
      AND    itc.reason_code         = cv_reason_122
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
                                         THEN cv_one
                                         ELSE cv_min
                                       END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(他)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2) use_nl (itc gic1 mcb1 gic2 mcb2) */
             NULL                       whse_code
            ,NULL                       whse_name
-- 2008/12/11 v1.15 N.Yoshida mod start
--            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            -- 棚卸増は、払出項目(棚卸減耗)に出力する為、数量の符号を変換する
            ,CASE WHEN xrpm.rcv_pay_div = cv_min
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
                  WHEN xrpm.rcv_pay_div = cv_one AND itc.reason_code = cv_reason_911
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) * cn_min
                  ELSE NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
-- 2008/12/11 v1.15 N.Yoshida mod start
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type          = cv_adji
      AND    itc.reason_code       IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_953
                                      ,cv_reason_955
                                      ,cv_reason_957
                                      ,cv_reason_959
                                      ,cv_reason_961
                                      ,cv_reason_963
                                      ,cv_reason_952
                                      ,cv_reason_954
                                      ,cv_reason_956
                                      ,cv_reason_958
                                      ,cv_reason_960
                                      ,cv_reason_962
                                      ,cv_reason_964
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_965
                                      ,cv_reason_966
-- 2008/11/19 v1.12 ADD END
                                      ,cv_reason_932)
      AND    itc.trans_date     >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date     <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(浜岡)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_988
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(移動)
      -- ----------------------------------------------------
      SELECT /*+ leading (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) use_nl (xmrih xmrl ijm iaj itc gic1 mcb1 gic2 mcb2) */
             NULL                       whse_code
            ,NULL                       whse_name
-- 2008/12/11 v1.15 UPDATE START
--            ,ABS(itc.trans_qty) * TO_NUMBER(cv_min) trans_qty
-- 2008/12/12 v1.16 UPDATE START
--            ,NVL(itc.trans_qty,0)       trans_qty
            ,NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)  trans_qty
-- 2008/12/12 v1.16 UPDATE END
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
-- 2008/12/08 v1.14 UPDATE START
--            ,xrpm.rcv_pay_div           pay_div
--            ,TO_CHAR(TO_NUMBER(xrpm.rcv_pay_div) * TO_NUMBER(cv_min)) pay_div
            ,xrpm.rcv_pay_div           pay_div
-- 2008/12/08 v1.14 UPDATE END
-- 2008/12/11 v1.15 UPDATE END
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxinv_mov_req_instr_lines   xmrl
            ,xxinv_mov_req_instr_headers xmrih
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code         = cv_reason_123
      AND    xmrih.mov_hdr_id        = xmrl.mov_hdr_id
      AND    xmrih.actual_arrival_date  >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xmrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = itc.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/12/11 v1.15 UPDATE START
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= cn_zero
--                                         THEN cv_one
                                         THEN cv_min
                                         WHEN itc.trans_qty <  cn_zero
--                                         THEN cv_min
                                         THEN cv_one
                                         ELSE xrpm.rcv_pay_div
                                       END
-- 2008/12/11 v1.15 UPDATE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :経理受払区分在庫調整(その他払出)
      -- ----------------------------------------------------
      SELECT /*+ leading (itc gic1 mcb1 gic2 mcb2 xrpm) use_nl (itc gic1 mcb1 gic2 mcb2 xrpm) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itc.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_cmp                itc
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itc.doc_type            = cv_adji
      AND    itc.reason_code        IN (cv_reason_942,cv_reason_943,cv_reason_950,cv_reason_951)
      AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itc.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itc.item_id
      AND    ilm.lot_id              = itc.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itc.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
      AND    gic1.item_id            = itc.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itc.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = itc.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
-- 2008/11/19 v1.12 DELETE START
      --AND    xrpm.rcv_pay_div        = CASE
      --                                   WHEN itc.trans_qty >= cn_zero
      --                                   THEN cv_one
      --                                   ELSE cv_min
      --                                 END
-- 2008/11/19 v1.12 DELETE END
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itc.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- PROD :経理受払区分生産関連（Reverse_idなし）品種・品目振替なし
      -- ----------------------------------------------------
      SELECT /*+ leading (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm) use_nl (itp gic2 mcb2 gic1 mcb1 gmd gbh grb xrpm)*/
             NULL                       whse_code
            ,NULL                       whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                itp
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_prod
      AND    itp.completed_ind       = cn_one
      AND    itp.reverse_id          IS NULL
      AND    itp.trans_date         >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    itp.trans_date         <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = itp.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = itp.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
-- 2009/08/12 DEL START
--      AND    mcb2.segment1           IN ('1','4')
-- 2009/08/12 DEL END
      AND    gic3.item_id            = itp.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/08/12 MOD START
-- 2009/09/07 MOD START
--      AND    xrpm.dealings_div IN('306','309')
      AND    ((xrpm.dealings_div = '306' AND mcb2.segment1 = '5') OR 
              (xrpm.dealings_div = '309' AND mcb2.segment1 IN ('1','4'))
             )
-- 2009/09/07 MOD END
      AND ((xrpm.routing_class    <> '70') OR 
           ((xrpm.routing_class     = '70')
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd2
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd2.batch_id   = gmd.batch_id
                            AND    gmd2.line_no    = gmd.line_no
                            AND    gmd2.line_type  = -1
                            AND    gic.item_id     = gmd2.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_origin))
            AND    (EXISTS (SELECT 1
                            FROM   gme_material_details gmd3
                                  ,gmi_item_categories  gic
                                  ,mtl_categories_b     mcb
                            WHERE  gmd3.batch_id   = gmd.batch_id
                            AND    gmd3.line_no    = gmd.line_no
                            AND    gmd3.line_type  = 1
                            AND    gic.item_id     = gmd3.item_id
                            AND    gic.category_set_id = cn_item_class_id
                            AND    gic.category_id = mcb.category_id
                            AND    mcb.segment1    = xrpm.item_div_ahead))
            ))
--      AND    xrpm.dealings_div       = cv_dealing_309
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd2
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd2.batch_id   = gmd.batch_id
--                      AND    gmd2.line_no    = gmd.line_no
--                      AND    gmd2.line_type  = -1
--                      AND    gic.item_id     = gmd2.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_origin))
--      AND    (EXISTS (SELECT 1
--                      FROM   gme_material_details gmd3
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd3.batch_id   = gmd.batch_id
--                      AND    gmd3.line_no    = gmd.line_no
--                      AND    gmd3.line_type  = 1
--                      AND    gic.item_id     = gmd3.item_id
--                      AND    gic.category_set_id = cn_item_class_id
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_ahead))
-- 2009/08/12 MOD END
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
    -- ----------------------------------------------------
    -- OMSO8 :経理受払区分受注関連 (見本,廃却)
    -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta wdd itp) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,wsh_delivery_details             wdd
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_omso
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      UNION ALL
      -- ----------------------------------------------------
      -- PORC8 :経理受払区分購買関連 (見本,廃却)
      -- ----------------------------------------------------
      SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */
             NULL                       whse_code
            ,NULL                       whse_name
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,itp.trans_date             trans_date
            ,xrpm.dealings_div_name     div_name
            ,xrpm.rcv_pay_div           pay_div
            ,iimb.item_id               item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,xrpm.break_col_03          column_no
            ,iimb.attribute15           cost_div
            ,iimb.lot_ctl               lot_ctl
            ,mcb3.segment1              crowd_code
            ,SUBSTR(mcb3.segment1, 1, 3) crowd_small
            ,SUBSTR(mcb3.segment1, 1, 2) crowd_medium
            ,SUBSTR(mcb3.segment1, 1, 1) crowd_large
            ,xlc.unit_ploce             act_unit_price
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,oe_order_headers_all             ooha
            ,oe_transaction_types_all         otta
            ,xxwsh_order_headers_all          xoha
            ,xxwsh_order_lines_all            xola
            ,ic_item_mst_b                    iimb
            ,xxcmn_item_mst_b                 ximb
            ,ic_lots_mst                      ilm
            ,xxcmn_lot_cost                   xlc
            ,ic_item_mst_b                    iimb2
            ,gmi_item_categories              gic1
            ,mtl_categories_b                 mcb1
            ,gmi_item_categories              gic2
            ,mtl_categories_b                 mcb2
            ,gmi_item_categories              gic3
            ,mtl_categories_b                 mcb3
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_whse_mst                iwm
      WHERE  itp.doc_type            = cv_porc
      AND    itp.completed_ind       = cn_one
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date      >= FND_DATE.STRING_TO_DATE(gv_exec_start,gc_char_dt_format)
      AND    xoha.arrival_date      <= FND_DATE.STRING_TO_DATE(gv_exec_end,gc_char_dt_format)
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    iimb2.item_no           = xola.shipping_item_code
      AND    ilm.item_id             = itp.item_id
      AND    ilm.lot_id              = itp.lot_id
      AND    iimb.item_id            = itp.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(itp.trans_date)
      AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.item_division
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.art_division
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = ln_crowd_code_id
      AND    gic3.category_id        = mcb3.category_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
      AND    iwm.whse_code           = itp.whse_code
      AND    iwm.attribute1          = '0'
      ORDER BY crowd_code ASC,item_code ASC
      ;
-- 2008/10/22 v1.09 ADD END
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 日付情報取得
    -- ====================================================
    -- 処理年月・開始日
    gd_exec_start := FND_DATE.STRING_TO_DATE(ir_param.process_year , gc_char_m_format);
    IF ( gd_exec_start IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg ( gc_application
                                             ,'APP-XXCMN-10155'
                                             ,'ERROR_PARAM'
                                             ,cv_process_year
                                             ,'ERROR_VALUE'
                                             ,ir_param.process_year ) ;
      lv_retcode  := gv_status_error;
      RAISE global_api_expt;
    END IF;
    gv_exec_start := TO_CHAR(gd_exec_start, gc_char_d_format) || lc_f_time;
--
    -- 処理年月・終了日
    gd_exec_end   := LAST_DAY(gd_exec_start);
    gv_exec_end   := TO_CHAR(gd_exec_end, gc_char_d_format) || lc_e_time;
--
-- 2008/10/22 v1.09 ADD START
    -- 帳票種別＝「1：倉庫・品目別」が指定されている場合
    IF (ir_param.report_type = cv_one) THEN
--
      -- 倉庫コードが指定されていない場合
      IF (ir_param.warehouse_code IS NULL) THEN
--
        -- 群種別＝「3：郡別」が指定されている場合
        IF (ir_param.crowd_type = cv_three) THEN
--
            ln_crowd_code_id := cn_crowd_code_id;
            lt_crowd_code    := ir_param.crowd_code;
--
          -- 群コードが入力されている場合
          IF (ir_param.crowd_code  IS NOT NULL) THEN
--
            OPEN  get_data_cur01;
            FETCH get_data_cur01 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur01;
--
          -- 群コードが入力されていない場合
          ELSE
--
            OPEN  get_data_cur02;
            FETCH get_data_cur02 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur02;
--
          END IF;
--
        -- 群種別＝「4：経理郡別」が指定されている場合
        ELSIF (ir_param.crowd_type = cv_four) THEN
--
          ln_crowd_code_id := cn_acnt_crowd_code_id;
          lt_crowd_code    := ir_param.account_code;
--
          -- 経理群コードが入力されている場合
          IF (ir_param.account_code  IS NOT NULL) THEN
--
            OPEN  get_data_cur01;
            FETCH get_data_cur01 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur01;
--
          -- 経理群コードが入力されていない場合
          ELSE
--
            OPEN  get_data_cur02;
            FETCH get_data_cur02 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur02;
--
          END IF;
--
        END IF;
--
      -- 倉庫コードが指定されている場合
      ELSE
--
        -- 群種別＝「3：郡別」が指定されている場合
        IF (ir_param.crowd_type = cv_three) THEN
--
            ln_crowd_code_id := cn_crowd_code_id;
            lt_crowd_code    := ir_param.crowd_code;
--
          -- 群コードが入力されている場合
          IF (ir_param.crowd_code  IS NOT NULL) THEN
--
            OPEN  get_data_cur03;
            FETCH get_data_cur03 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur03;
--
          -- 群コードが入力されていない場合
          ELSE
--
            OPEN  get_data_cur04;
            FETCH get_data_cur04 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur04;
--
          END IF;
--
        -- 群種別＝「4：経理郡別」が指定されている場合
        ELSIF (ir_param.crowd_type = cv_four) THEN
--
          ln_crowd_code_id := cn_acnt_crowd_code_id;
          lt_crowd_code    := ir_param.account_code;
--
          -- 経理群コードが入力されている場合
          IF (ir_param.account_code  IS NOT NULL) THEN
--
            OPEN  get_data_cur03;
            FETCH get_data_cur03 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur03;
--
          -- 経理群コードが入力されていない場合
          ELSE
--
            OPEN  get_data_cur04;
            FETCH get_data_cur04 BULK COLLECT INTO ot_data_rec;
            CLOSE get_data_cur04;
          END IF;
--
        END IF;
--
      END IF;
--
    -- 帳票種別＝「2：品目別」が指定されている場合
    ELSIF (ir_param.report_type = cv_two) THEN
--
      -- 群種別＝「3：郡別」が指定されている場合
      IF (ir_param.crowd_type = cv_three) THEN
--
        ln_crowd_code_id := cn_crowd_code_id;
        lt_crowd_code    := ir_param.crowd_code;
--
        -- 群コードが入力されている場合
        IF (ir_param.crowd_code  IS NOT NULL) THEN
--
          OPEN  get_data_cur05;
          FETCH get_data_cur05 BULK COLLECT INTO ot_data_rec;
          CLOSE get_data_cur05;
--
        -- 群コードが入力されていない場合
        ELSE
--
          OPEN  get_data_cur06;
          FETCH get_data_cur06 BULK COLLECT INTO ot_data_rec;
          CLOSE get_data_cur06;
--
        END IF;
--
      -- 群種別＝「4：経理郡別」が指定されている場合
      ELSIF (ir_param.crowd_type = cv_four) THEN
--
        ln_crowd_code_id := cn_acnt_crowd_code_id;
        lt_crowd_code    := ir_param.account_code;
--
        -- 経理群コードが入力されている場合
        IF (ir_param.account_code  IS NOT NULL) THEN
--
          OPEN  get_data_cur05;
          FETCH get_data_cur05 BULK COLLECT INTO ot_data_rec;
          CLOSE get_data_cur05;
--
        -- 経理群コードが入力されていない場合
        ELSE
--
          OPEN  get_data_cur06;
          FETCH get_data_cur06 BULK COLLECT INTO ot_data_rec;
          CLOSE get_data_cur06;
--
        END IF;
--
      END IF;
--
    END IF;
-- 2008/10/22 v1.09 ADD END
--
-- 2008/10/22 v1.09 DELETE START
    /*-- ===============================================================================
    -- 共通 SELECT
    -- ===============================================================================
    lv_select := ' xleiv.item_id           AS  item_id, '    -- 品目ID
              || ' xleiv.item_code         AS  item_code, '  -- 品目コード
              || ' xleiv.item_short_name   AS  item_name, '  -- 品目名称
              || ' xlvv.attribute3         AS  column_no, '  -- 出力場所
              || ' xleiv.item_attribute15  AS  cost_div, '   -- 原価管理区分
              || ' xleiv.lot_ctl           AS  lot_ctl, ';   -- ロット管理区分
--
    -- =======================================
    -- 群種別に取得項目を変更
    -- =======================================
    -- 群種別が3：群別が選択されている場合
    IF ( ir_param.crowd_type = cv_three ) THEN
      lv_select := lv_select
                || ' xleiv.crowd_code                  AS crowd_code,   '   -- 詳群コード
                || ' SUBSTR( xleiv.crowd_code, 1, 3 )  AS crowd_small,  '   -- 小群コード
                || ' SUBSTR( xleiv.crowd_code, 1, 2 )  AS crowd_medium, '   -- 中群コード
                || ' SUBSTR( xleiv.crowd_code, 1, 1 )  AS crowd_large,  ';  -- 大群コード
    -- 群種別が4：経理群別が選択されている場合
    ELSIF ( ir_param.crowd_type = cv_four ) THEN
      lv_select := lv_select
                || ' xleiv.acnt_crowd_code                  AS crowd_code,   '   -- 詳群コード
                || ' SUBSTR( xleiv.acnt_crowd_code, 1, 3 )  AS crowd_small,  '   -- 小群コード
                || ' SUBSTR( xleiv.acnt_crowd_code, 1, 2 )  AS crowd_medium, '   -- 中群コード
                || ' SUBSTR( xleiv.acnt_crowd_code, 1, 1 )  AS crowd_large,  ';  -- 大群コード
    END IF;
    lv_select := lv_select
              || ' xleiv.actual_unit_price   AS act_unit_price '; -- 実際単価
--
    -- ===============================================================================
    -- 共通 WHERE
    -- ===============================================================================
    lv_where := ' AND  xlvv.enabled_flag      = '''  || cv_yes || ''''
             || ' AND  xlvv.lookup_type        = ''' || cv_lookup || ''''
             || ' AND  xlvv.language                = ''' || cv_lang || ''''
             || ' AND  xlvv.source_lang             = ''' || cv_lang || ''''
             || ' AND  xlvv.attribute3  IS NOT NULL '
             || ' AND  xleiv.prod_div     = ''' || ir_param.item_division || ''''
             || ' AND  xleiv.item_div     = ''' || ir_param.art_division  || '''';
--
    -- ====================================
    -- 群種別別に取得条件を追加
    -- ====================================
    -- 群種別が3：群別の場合
    IF (( ir_param.crowd_type = cv_three )
      AND ( ir_param.crowd_code IS NOT NULL )) THEN
      lv_where := lv_where
               || ' AND xleiv.crowd_code = ''' || ir_param.crowd_code || '''';
    -- 群種別が4：経理群別の場合
    ELSIF (( ir_param.crowd_type = cv_four )
      AND  ( ir_param.account_code IS NOT NULL )) THEN
      lv_where := lv_where
               || ' AND xleiv.acnt_crowd_code = ''' || ir_param.account_code || '''';
    END IF;
--
--
    -- ===============================================================================
    -- 共通 WHERE ITP
    -- ===============================================================================
    lv_where_itp := ' AND  itp.trans_date   >= FND_DATE.STRING_TO_DATE( '
                 || '''' || gv_exec_start || ''', ''' || gc_char_dt_format || ''' )'
                 || ' AND  itp.trans_date   <= FND_DATE.STRING_TO_DATE('
                 || '''' || gv_exec_end   || ''', ''' || gc_char_dt_format || ''' )'
                 || ' AND  ((xlvv.start_date_active IS NULL ) '
                 || '  OR   (xlvv.start_date_active    <= TRUNC(itp.trans_date))) '
                 || ' AND  ((xlvv.end_date_active   IS NULL ) '
                 || '  OR   ( xlvv.end_date_active     >= TRUNC(itp.trans_date))) '
                 || ' AND  itp.item_id                  = xleiv.item_id '
                 || ' AND  ((xleiv.start_date_active IS NULL ) '
                 || '  OR   (xleiv.start_date_active   <= TRUNC(itp.trans_date))) '
                 || ' AND  ((xleiv.end_date_active  IS NULL) '
                 || '  OR   (xleiv.end_date_active     >= TRUNC(itp.trans_date))) '
                 || ' AND  itp.completed_ind    = ' || cn_one
                 || ' AND  xleiv.lot_id                 = itp.lot_id ';
    -- ====================================
    -- 帳票種別が1：倉庫別・品目別の場合
    -- ====================================
    IF ( ir_param.report_type = cv_one ) THEN
      lv_where_itp := lv_where_itp
                    || ' AND iwm.whse_code = itp.whse_code ';
      -- 倉庫コードが指定されていた場合
      IF ( ir_param.warehouse_code IS NOT NULL ) THEN
        lv_where_itp := lv_where_itp
                      || ' AND iwm.whse_code  = ''' || ir_param.warehouse_code || '''';
      END IF;
    END IF;
--
    -- ===============================================================================
    -- 共通 WHERE ITC
    -- ===============================================================================
    lv_where_itc := '   AND  itc.trans_date     >= FND_DATE.STRING_TO_DATE( '
                 || '''' || gv_exec_start || ''', ''' || gc_char_dt_format || ''' )'
                 || '   AND  itc.trans_date     <= FND_DATE.STRING_TO_DATE('
                 || '''' || gv_exec_end || ''', '''   || gc_char_dt_format || ''' )'
                 || '   AND  ((xlvv.start_date_active IS NULL ) '
                 || '    OR   (xlvv.start_date_active  <= TRUNC(itc.trans_date))) '
                 || '   AND  ((xlvv.end_date_active   IS NULL ) '
                 || '    OR   ( xlvv.end_date_active  >= TRUNC(itc.trans_date))) '
                 || '   AND  itc.item_id               = xleiv.item_id '
                 || '   AND  ((xleiv.start_date_active IS NULL ) '
                 || '    OR   (xleiv.start_date_active  <= TRUNC(itc.trans_date))) '
                 || '   AND  ((xleiv.end_date_active IS NULL) '
                 || '    OR   (xleiv.end_date_active    >= TRUNC(itc.trans_date))) '
                 || '   AND  xleiv.lot_id                = itc.lot_id ';
--
    -- ====================================
    -- 帳票種別が1：倉庫別・品目別の場合
    -- ====================================
    IF ( ir_param.report_type = cv_one ) THEN
      lv_where_itc := lv_where_itc
                    || ' AND iwm.whse_code = itc.whse_code ';
      -- 倉庫コードが指定されていた場合
      IF ( ir_param.warehouse_code IS NOT NULL ) THEN
        lv_where_itc := lv_where_itc
                      || ' AND iwm.whse_code = ''' || ir_param.warehouse_code || '''';
      END IF;
    END IF;
--
    -- ============================================
    -- SELECT句生成
    -- ============================================
    -- ============================================================================
    -- XFER
    -- ============================================================================
    lv_select_xfer := ' SELECT ';
    -- 帳票区分が倉庫
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_xfer := lv_select_xfer
                     || ' iwm.whse_code        AS  whse_code, '   -- 倉庫コード
                     || ' iwm.whse_name        AS  whse_name, ';  -- 倉庫名称
    ELSE
      lv_select_xfer := lv_select_xfer
                     || ' NULL                 AS  whse_code, '
                     || ' NULL                 AS  whse_name, ';
    END IF;
    lv_select_xfer := lv_select_xfer
-- 2008/08/28 v1.8 UPDATE START
--                   || ' itp.trans_qty          AS  trans_qty, '  -- 取引数量
                   || ' itp.trans_qty * TO_NUMBER(xfer_v.rcv_pay_div) AS  trans_qty, '  -- 取引数量
-- 2008/08/28 v1.8 UPDATE END
                   || ' itp.trans_date         AS  trans_date, '  -- 取引日
                   || ' xfer_v.dealings_div_name AS  div_name, ' -- 取引区分名
                   || ' xfer_v.rcv_pay_div     AS  pay_div, ';    -- 受払区分
--
    -- ============================================
    -- FROM句生成
    -- ============================================
    lv_from_xfer := ' FROM '
                 || ' ic_tran_pnd                 itp, '     -- 在庫トラン
                 || ' xxcmn_rcv_pay_mst_xfer_v    xfer_v, '
                 || ' ic_xfer_mst                 ixm, '     -- OPM在庫転送マスタ
                 || ' xxinv_mov_req_instr_lines   xmril, '   -- 移動依頼／指示明細（アドオン）
                 || ' xxcmn_lookup_values2_v      xlvv, '    -- クイックコード情報VIEW2
                 || ' xxcmn_lot_each_item_v       xleiv  ';  -- ロット別品目情報View
    -- 帳票区分が倉庫別
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_xfer := lv_from_xfer
                   || ' , ic_whse_mst             iwm ';
    END IF;
--
    -- ============================================
    -- WHERE句生成
    -- ============================================
    lv_where_xfer := ' WHERE '
                  || '      itp.doc_type         = ''' || cv_xfer || ''''
                  || ' AND  itp.completed_ind    = '   || cn_one
                  || ' AND  itp.reason_code      = xfer_v.reason_code '
                  || ' AND  xfer_v.doc_type      = itp.doc_type '
                  || ' AND  xfer_v.rcv_pay_div   = CASE '
                  || '                              WHEN itp.trans_qty >= ' || cn_zero
                  || '                              THEN ''' || cv_one || ''''
                  || '                              ELSE ''' || cv_min || ''''
                  || '                             END '
                  || ' AND  itp.doc_id           = ixm.transfer_id '
                  || ' AND  ixm.attribute1       = xmril.mov_line_id '
                  || ' AND  xfer_v.dealings_div  = xlvv.meaning ';
--
    -- XFER:SQL
    lv_sql_xfer := lv_select_xfer || lv_select
                || lv_from_xfer   || lv_where_xfer
                || lv_where_itp   || lv_where ;
--
    -- ============================================
    -- SELECT句生成
    -- ============================================
    -- =========================================================================================
    -- TRNI
    -- =========================================================================================
    lv_select_trni := ' SELECT ';
    -- 帳票区分が倉庫
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_trni := lv_select_trni
                     || ' iwm.whse_code        AS  whse_code, '   -- 倉庫コード
                     || ' iwm.whse_name        AS  whse_name, ';  -- 倉庫名称
    ELSE
      lv_select_trni := lv_select_trni
                     || ' NULL                 AS whse_code, '
                     || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_trni := lv_select_trni
-- 2008/08/28 v1.8 UPDATE START
--                   || ' itc.trans_qty          AS  trans_qty, '  -- 取引数量
                   || ' itc.trans_qty * TO_NUMBER(trni_v.rcv_pay_div) AS  trans_qty, '  -- 取引数量
-- 2008/08/28 v1.8 UPDATE END
                   || ' itc.trans_date         AS  trans_date, '  -- 取引日
                   || ' trni_v.dealings_div_name AS  div_name, ' -- 取引区分名
                   || ' trni_v.rcv_pay_div     AS  pay_div, ';   -- 受払区分
--
    -- ============================================
    -- FROM句生成
    -- ============================================
    lv_from_trni := ' FROM '
                 || ' ic_tran_cmp                itc, '
                 || ' xxcmn_rcv_pay_mst_trni_v   trni_v, '
                 || ' ic_adjs_jnl                iaj, '    -- OPM在庫調整ジャーナル
                 || ' ic_jrnl_mst                ijm, '    -- OPMジャーナルマスタ
                 || ' xxinv_mov_req_instr_lines  xmril, '  -- 移動依頼／指示明細（アドオン）
                 || ' xxcmn_lookup_values2_v     xlvv, '   -- クイックコード情報VIEW2
                 || ' xxcmn_lot_each_item_v      xleiv ';  -- ロット別品目情報View
--
    -- 帳票区分が倉庫別
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_trni := lv_from_trni
                   || ' , ic_whse_mst            iwm ';
    END IF;
--
    -- ============================================
    -- WHERE句生成
    -- ============================================
    lv_where_trni := ' WHERE '
                  || '        itc.doc_type         = ''' || cv_trni || ''''
                  || '   AND  itc.doc_type         = trni_v.doc_type '
                  || '   AND  itc.reason_code      = trni_v.reason_code '
                  || '   AND  trni_v.rcv_pay_div  = CASE '
                  || '                                WHEN itc.trans_qty >= ' || cn_zero
                  || '                                THEN ''' || cv_one || ''''
                  || '                                ELSE ''' || cv_min || ''''
                  || '                              END '
                  || '   AND  itc.doc_type         = iaj.trans_type '
                  || '   AND  itc.doc_id           = iaj.doc_id '
                  || '   AND  itc.doc_line         = iaj.doc_line '
                  || '   AND  iaj.journal_id       = ijm.journal_id '
                  || '   AND  ijm.attribute1       = xmril.mov_line_id '
                  || '   AND  trni_v.dealings_div  = xlvv.meaning ';
    -- TRNI:SQL
    lv_sql_trni := lv_select_trni || lv_select
                || lv_from_trni   || lv_where_trni
                || lv_where_itc   || lv_where;
--
    -- ============================================
    -- SELECT句生成
    -- ============================================
    -- =========================================================================================
    -- ADJI
    -- =========================================================================================
    -- 在庫調整(仕入先返品、浜岡受入、移動実績訂正以外)
    lv_select_adji_1 := ' SELECT ';
    -- 帳票区分が倉庫
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_adji_1 := lv_select_adji_1
                       || ' iwm.whse_code        AS  whse_code, '   -- 倉庫コード
                       || ' iwm.whse_name        AS  whse_name, ';  -- 倉庫名称
    ELSE
      lv_select_adji_1 := lv_select_adji_1
                       || ' NULL                 AS whse_code, '
                       || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_adji_1 := lv_select_adji_1
-- 2008/08/28 v1.8 UPDATE START
--                     || ' itc.trans_qty          AS  trans_qty, '  -- 取引数量
                     || ' itc.trans_qty * TO_NUMBER(adji_v.rcv_pay_div) AS  trans_qty, ' -- 取引数量
-- 2008/08/28 v1.8 UPDATE END
                     || ' itc.trans_date         AS  trans_date, '  -- 取引日
                     || ' adji_v.dealings_div_name AS  div_name, ' -- 取引区分名
                     || ' adji_v.rcv_pay_div     AS  pay_div, ';   -- 受払区分
--
    -- ============================================
    -- FROM句生成
    -- ============================================
    lv_from_adji_1 := ' FROM '
                   || ' ic_tran_cmp               itc, '
                   || ' xxcmn_rcv_pay_mst_adji_v  adji_v, '
                   || ' xxcmn_lookup_values2_v    xlvv,  '  -- クイックコード情報VIEW2
                   || ' xxcmn_lot_each_item_v     xleiv ';  -- ロット別品目情報View
--
    -- 帳票区分が倉庫別
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_adji_1 := lv_from_adji_1
                     || ' , ic_whse_mst           iwm ';
    END IF;
--
    -- ============================================
    -- WHERE句生成
    -- ============================================
    lv_where_adji_1 := ' WHERE '
                    || '        itc.doc_type          = ''' || cv_adji || ''''
                    || '   AND  itc.doc_type          = adji_v.doc_type '
                    || '   AND  ((itc.reason_code     = ''' || cv_reason_911 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_912 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_921 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_922 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_941 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_931 || ''' )'
                    || '    OR   (itc.reason_code     = ''' || cv_reason_932 || ''' ))'
                    || '   AND  itc.reason_code       = adji_v.reason_code '
                    || '   AND  adji_v.dealings_div   = xlvv.meaning ';
    -- ADJI_1:SQL
    lv_sql_adji_1 := lv_select_adji_1 || lv_select
                  || lv_from_adji_1   || lv_where_adji_1
                  || lv_where_itc     || lv_where;
--
    -- ============================================
    -- SELECT句生成
    -- ============================================
    -- =========================================================================================
    -- ADJI
    -- =========================================================================================
    -- 在庫調整(浜岡受入)
    lv_select_adji_2 := ' SELECT ';
    -- 帳票区分が倉庫
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_adji_2 := lv_select_adji_2
                       || ' iwm.whse_code        AS  whse_code, '   -- 倉庫コード
                       || ' iwm.whse_name        AS  whse_name, ';  -- 倉庫名称
    ELSE
      lv_select_adji_2 := lv_select_adji_2
                       || ' NULL                 AS  whse_code, '
                       || ' NULL                 AS  whse_name, ';
    END IF;
    lv_select_adji_2 := lv_select_adji_2
-- 2008/08/28 v1.8 UPDATE START
--                     || ' itc.trans_qty          AS  trans_qty, '  -- 取引数量
                     || ' itc.trans_qty * TO_NUMBER(adji_v.rcv_pay_div) AS  trans_qty, ' -- 取引数量
-- 2008/08/28 v1.8 UPDATE END
                     || ' itc.trans_date         AS  trans_date, '  -- 取引日
                     || ' adji_v.dealings_div_name AS  div_name, ' -- 取引区分名
                     || ' adji_v.rcv_pay_div     AS  pay_div, ';   -- 受払区分
--
    -- ============================================
    -- FROM句生成
    -- ============================================
    lv_from_adji_2 := ' FROM '
                   || ' ic_tran_cmp               itc, '       -- OPM完了在庫トラン
                   || ' ic_adjs_jnl               iaj, '       -- OPM在庫調整ジャーナル
                   || ' ic_jrnl_mst               ijm, '       -- OPMジャーナルマスタ
                   || ' xxpo_namaha_prod_txns     xnpt, '      -- 精算実績アドオン
                   || ' xxcmn_rcv_pay_mst_adji_v  adji_v, '
                   || ' xxcmn_lookup_values2_v    xlvv, '      -- クイックコード情報view2
                   || ' xxcmn_lot_each_item_v     xleiv ';     -- ロット別品目情報View
--
    -- 帳票区分が倉庫別
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_adji_2 := lv_from_adji_2
                     || ' , ic_whse_mst           iwm ';
    END IF;
--
    -- ============================================
    -- WHERE句生成
    -- ============================================
    lv_where_adji_2 := ' WHERE '
                    || '       itc.doc_type         = ''' || cv_adji || ''''
                    || '   AND itc.doc_type         = adji_v.doc_type '
                    || '   AND itc.reason_code      = ''' || cv_reason_988 || ''''
                    || '   AND iaj.trans_type       = itc.doc_type '
                    || '   AND iaj.doc_id           = itc.doc_id '
                    || '   AND iaj.doc_line         = itc.doc_line '
                    || '   AND iaj.journal_id       = ijm.journal_id '
                    || '   AND xnpt.entry_number    = ijm.attribute1 '
                    || '   AND itc.reason_code      = adji_v.reason_code '
                    || '   AND adji_v.dealings_div  = xlvv.meaning ';
    -- ADJI_2:SQL
    lv_sql_adji_2 := lv_select_adji_2 || lv_select
                  || lv_from_adji_2   || lv_where_adji_2
                  || lv_where_itc     || lv_where;
--
    -- ============================================
    -- SELECT句生成
    -- ============================================
    -- =========================================================================================
    -- ADJI
    -- =========================================================================================
    -- 在庫調整(移動実績訂正)
    lv_select_adji_3 := ' SELECT ';
    -- 帳票区分が倉庫
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_adji_3 := lv_select_adji_3
                       || ' iwm.whse_code        AS  whse_code, '   -- 倉庫コード
                       || ' iwm.whse_name        AS  whse_name, ';  -- 倉庫名称
    ELSE
      lv_select_adji_3 := lv_select_adji_3
                       || ' NULL                 AS  whse_code, '
                       || ' NULL                 AS  whse_name, ';
    END IF;
    lv_select_adji_3 := lv_select_adji_3
-- 2008/08/28 v1.8 UPDATE START
--                     || ' itc.trans_qty          AS  trans_qty, '  -- 取引数量
                     || ' itc.trans_qty * TO_NUMBER(adji_v.rcv_pay_div) AS  trans_qty, ' -- 取引数量
-- 2008/08/28 v1.8 UPDATE END
                     || ' itc.trans_date         AS  trans_date, '  -- 取引日
                     || ' adji_v.dealings_div_name AS  div_name, ' -- 取引区分名
                     || ' adji_v.rcv_pay_div     AS  pay_div, ';   -- 受払区分
--
    -- ============================================
    -- FROM句生成
    -- ============================================
    lv_from_adji_3 := ' FROM '
                   || ' ic_tran_cmp                itc, '      -- opm完了在庫トラン
                   || ' ic_adjs_jnl                iaj, '      -- opm在庫調整ジャーナル
                   || ' ic_jrnl_mst                ijm, '      -- opmジャーナルマスタ
                   || ' xxinv_mov_req_instr_lines  xmrl  , '
                   || ' xxcmn_rcv_pay_mst_adji_v   adji_v, '
                   || ' xxcmn_lookup_values2_v     xlvv, '     -- クイックコード情報view2
                   || ' xxcmn_lot_each_item_v      xleiv ';    -- ロット別品目情報view
--
    -- 帳票区分が倉庫別
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_adji_3 := lv_from_adji_3
                     || ' , ic_whse_mst            iwm ';
    END IF;
--
    -- ============================================
    -- WHERE句生成
    -- ============================================
    lv_where_adji_3 := ' WHERE '
                    || '       itc.doc_type         = ''' || cv_adji || ''''
                    || '   AND itc.doc_type         = adji_v.doc_type '
                    || '   AND itc.reason_code      = ''' || cv_reason_123 || ''''
                    || '   AND adji_v.rcv_pay_div  = CASE '
                    || '                               WHEN itc.trans_qty >= ' ||  cn_zero
                    || '                                 THEN ''' || cv_min || ''''
                    || '                               WHEN itc.trans_qty <  ' ||  cn_zero
                    || '                                 THEN ''' || cv_one || ''''
                    || '                               ELSE adji_v.rcv_pay_div '
                    || '                             END '
                    || '   AND iaj.trans_type       = itc.doc_type '
                    || '   AND iaj.doc_id           = itc.doc_id '
                    || '   AND iaj.doc_line         = itc.doc_line '
                    || '   AND iaj.journal_id       = ijm.journal_id '
                    || '   AND xmrl.mov_line_id     = ijm.attribute1 '
                    || '   AND itc.reason_code      = adji_v.reason_code '
                    || '   AND adji_v.dealings_div  = xlvv.meaning ';
    -- ADJI_3:SQL
    lv_sql_adji_3 := lv_select_adji_3 || lv_select
                  || lv_from_adji_3   || lv_where_adji_3
                  || lv_where_itc     || lv_where;
--
    -- ============================================
    -- SELECT句生成
    -- ============================================
    -- =========================================================================================
    -- ADJI
    -- =========================================================================================
    -- 在庫調整(黙視品目払出、その他払出)
    lv_select_adji_4 := ' SELECT ';
    -- 帳票区分が倉庫
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_adji_4 := lv_select_adji_4
                       || ' iwm.whse_code        AS  whse_code, '   -- 倉庫コード
                       || ' iwm.whse_name        AS  whse_name, ';  -- 倉庫名称
    ELSE
      lv_select_adji_4 := lv_select_adji_4
                       || ' NULL                 AS whse_code, '
                       || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_adji_4 := lv_select_adji_4
-- 2008/08/28 v1.8 UPDATE START
--                     || ' itc.trans_qty          AS  trans_qty, '  -- 取引数量
                     || ' itc.trans_qty * TO_NUMBER(adji_v.rcv_pay_div) AS  trans_qty, ' -- 取引数量
-- 2008/08/28 v1.8 UPDATE END
                     || ' itc.trans_date         AS  trans_date, '  -- 取引日
                     || ' adji_v.dealings_div_name AS  div_name, ' -- 取引区分名
                     || ' adji_v.rcv_pay_div     AS  pay_div, ';   -- 受払区分
--
    -- ============================================
    -- FROM句生成
    -- ============================================
    lv_from_adji_4 := ' FROM '
                   || ' ic_tran_cmp               itc, '       -- OPM完了在庫トラン
                   || ' ic_adjs_jnl               iaj, '       -- OPM在庫調整ジャーナル
                   || ' ic_jrnl_mst               ijm, '       -- OPMジャーナルマスタ
                   || ' xxcmn_rcv_pay_mst_adji_v  adji_v, '
                   || ' xxcmn_lookup_values2_v    xlvv, '      -- クイックコード情報view2
                   || ' xxcmn_lot_each_item_v     xleiv ';     -- ロット別品目情報View
--
    -- 帳票区分が倉庫別
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_adji_4 := lv_from_adji_4
                     || ' , ic_whse_mst           iwm ';
    END IF;
--
    -- ============================================
    -- WHERE句生成
    -- ============================================
    lv_where_adji_4 := ' WHERE '
                    || '       itc.doc_type         = ''' || cv_adji || ''''
                    || '   AND itc.doc_type         = adji_v.doc_type '
                    || '   AND (( itc.reason_code   = ''' || cv_reason_942 || ''' )'
                    || '    OR  ( itc.reason_code   = ''' || cv_reason_951 || ''' ))'
                    || '   AND adji_v.rcv_pay_div  = CASE '
                    || '                               WHEN itc.trans_qty >= ' || cn_zero
                    || '                               THEN ''' || cv_one || ''''
                    || '                               ELSE ''' || cv_min || ''''
                    || '                             END '
                    || '   AND iaj.trans_type       = itc.doc_type '
                    || '   AND iaj.doc_id           = itc.doc_id '
                    || '   AND iaj.doc_line         = itc.doc_line '
                    || '   AND iaj.journal_id       = ijm.journal_id '
                    || '   AND itc.reason_code      = adji_v.reason_code '
                    || '   AND adji_v.dealings_div  = xlvv.meaning ';
    -- ADJI_2:SQL
    lv_sql_adji_4 := lv_select_adji_4 || lv_select
                  || lv_from_adji_4   || lv_where_adji_4
                  || lv_where_itc     || lv_where;
--
    -- ============================================
    -- SELECT句生成
    -- ============================================
    -- ============================================================================
    -- PROD reverse_id IS NULL
    -- ============================================================================
    lv_select_prod := ' SELECT ';
    -- 帳票区分が倉庫
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_prod := lv_select_prod
                     || ' iwm.whse_code        AS  whse_code, '   -- 倉庫コード
                     || ' iwm.whse_name        AS  whse_name, ';  -- 倉庫名称
    ELSE
      lv_select_prod := lv_select_prod
                     || ' NULL                 AS whse_code, '
                     || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_prod := lv_select_prod
-- 2008/08/28 v1.8 UPDATE START
--                   || ' itp.trans_qty          AS trans_qty, '
                   || ' itp.trans_qty * TO_NUMBER(prod_v.rcv_pay_div) AS trans_qty, '
-- 2008/08/28 v1.8 UPDATE END
                   || ' itp.trans_date         AS trans_date, '
                   || ' prod_v.dealings_div_name AS  div_name, ' -- 取引区分名
                   || ' prod_v.rcv_pay_div     AS pay_div, ';   -- 受払区分
--
    -- ============================================
    -- FROM句生成
    -- ============================================
    lv_from_prod := ' FROM '
                   || ' ic_tran_pnd                 itp, '
                   || ' ic_tran_pnd                 itp2, '
                   || ' xxcmn_rcv_pay_mst_prod_v    prod_v, '
                   || ' xxcmn_lookup_values2_v      xlvv, '    -- クイックコード情報view2
                   || ' xxcmn_lookup_values2_v      xlvv2, '
                   || ' xxcmn_lot_each_item_v       xleiv, '   -- ロット別品目情報view
                   || ' xxcmn_lot_each_item_v       xleiv2 ';  -- ロット別品目情報view
--
    -- 帳票区分が倉庫別
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_prod := lv_from_prod
                   || ' , ic_whse_mst         iwm ';
    END IF;
--
    -- ============================================
    -- WHERE句生成
    -- ============================================
    lv_where_prod := ' WHERE '
                  || ' itp.doc_type        = ''' || cv_prod || ''''
                  || ' AND itp.reverse_id      IS NULL '
                  || ' AND itp.doc_type        = prod_v.doc_type '
                  || ' AND itp.line_type       = prod_v.line_type '
                  || ' AND itp.doc_id          = prod_v.doc_id '
                  || ' AND itp.doc_line        = prod_v.doc_line '
                  || ' AND itp2.line_type      = CASE '
                  || '                             WHEN itp.line_type = ' || cn_min
                  || '                             THEN ' || cn_one
                  || '                             WHEN itp.line_type = ' || cn_one
                  || '                             THEN ' || cn_min
                  || '                           END '
                  || ' AND itp2.completed_ind  = ' || cn_one
                  || ' AND itp2.reverse_id     IS NULL '
                  || ' AND itp.doc_id          = itp2.doc_id '
                  || ' AND itp.doc_line        = itp2.doc_line '
                  || ' AND itp2.trans_date   >= FND_DATE.STRING_TO_DATE( '
                  || '''' || gv_exec_start || ''', ''' || gc_char_dt_format || ''' )'
                  || ' AND  itp2.trans_date   <= FND_DATE.STRING_TO_DATE('
                  || '''' || gv_exec_end   || ''', ''' || gc_char_dt_format || ''' )'
                  || ' AND prod_v.dealings_div = ''' || cv_dealing_309 || '''' -- 品目振替
                  || ' AND prod_v.dealings_div     = xlvv.meaning '
                  || ' AND itp2.item_id            = xleiv2.item_id '
                  || ' AND itp2.lot_id             = xleiv2.lot_id '
                  || ' AND ((xleiv2.start_date_active IS NULL) '
                  || '  OR  (xleiv2.start_date_active <= TRUNC(itp2.trans_date))) '
                  || ' AND ((xleiv2.end_date_active IS NULL) '
                  || '  OR  (xleiv2.end_date_active  >= TRUNC(itp2.trans_date))) '
                  || ' AND xleiv.item_div = CASE '
                  || '                         WHEN itp.line_type = ' || cn_min
                  || '                           THEN prod_v.item_div_origin '
                  || '                         WHEN itp.line_type = ' || cn_one
                  || '                           THEN prod_v.item_div_ahead '
                  || '                       END '
                  || ' AND xleiv2.item_div = CASE '
                  || '                         WHEN itp.line_type = ' || cn_one
                  || '                           THEN prod_v.item_div_origin '
                  || '                         WHEN itp.line_type = ' || cn_min
                  || '                           THEN prod_v.item_div_ahead '
                  || '                       END '
                  || ' AND prod_v.item_id  = itp.item_id '
                  || ' AND xlvv2.lookup_type          = '''  || cv_lookup2 || ''''
                  || ' AND xlvv2.meaning              = (''' || cv_meaning || ''' )'
                  || ' AND prod_v.dealings_div        = xlvv2.lookup_code '
                  || ' AND ((xlvv2.start_date_active IS NULL) '
                  || '  OR  (xlvv2.start_date_active <= TRUNC(itp.trans_date))) '
                  || ' AND ((xlvv2.end_date_active   IS NULL) '
                  || '  OR  (xlvv2.end_date_active    >= TRUNC(itp.trans_date))) ';
    -- PROD:SQL
    lv_sql_prod := lv_select_prod || lv_select
                || lv_from_prod   || lv_where_prod
                || lv_where_itp   || lv_where;
--
    -- ============================================
    -- SELECT句生成
    -- ============================================
    -- ============================================================================
    -- OMSO
    -- ============================================================================
    lv_select_omso := ' SELECT ';
    -- 帳票区分が倉庫
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_omso := lv_select_omso
                     || ' iwm.whse_code        AS  whse_code, '   -- 倉庫コード
                     || ' iwm.whse_name        AS  whse_name, ';  -- 倉庫名称
    ELSE
      lv_select_omso := lv_select_omso
                     || ' NULL                 AS whse_code, '
                     || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_omso := lv_select_omso
-- 2008/08/28 v1.8 UPDATE START
--                   || ' itp.trans_qty          AS  trans_qty, '  -- 取引数量
                   || ' itp.trans_qty * TO_NUMBER(omso_v.rcv_pay_div) AS  trans_qty, '  -- 取引数量
-- 2008/08/28 v1.8 UPDATE END
                   || ' itp.trans_date         AS  trans_date, '  -- 取引日
                   || ' omso_v.dealings_div_name AS  div_name, ' -- 取引区分名
                   || ' omso_v.rcv_pay_div     AS  pay_div, ';   -- 受払区分
--
    -- ============================================
    -- FROM句生成
    -- ============================================
    lv_from_omso := ' FROM '
                 || ' ic_tran_pnd               itp, '
                 || ' xxcmn_rcv_pay_mst_omso_v  omso_v, '
                 || ' xxcmn_lookup_values2_v    xlvv,  '   -- クイックコード情報VIEW2
                 || ' xxcmn_lot_each_item_v     xleiv  ';  -- ロット別品目情報View
--
    -- 帳票区分が倉庫別
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_omso := lv_from_omso
                   || ' , ic_whse_mst           iwm ';
    END IF;
--
    -- ============================================
    -- WHERE句生成
    -- ============================================
    lv_where_omso := ' WHERE '
                  || '        itp.doc_type         = ''' || cv_omso || ''''
                  || '   AND  itp.doc_type         = omso_v.doc_type '
                  || '   AND  itp.line_detail_id   = omso_v.doc_line '
                  || '   AND  omso_v.dealings_div  = xlvv.meaning ';
--
    -- OMSO:SQL
    lv_sql_omso := lv_select_omso || lv_select
                || lv_from_omso   || lv_where_omso
                || lv_where_itp   || lv_where;
--
    -- ============================================
    -- SELECT句生成
    -- ============================================
    -- ============================================================================
    -- PORC
    -- ============================================================================
    lv_select_porc := ' SELECT ';
    -- 帳票区分が倉庫
    IF ( ir_param.report_type = cv_one ) THEN
      lv_select_porc := lv_select_porc
                     || ' iwm.whse_code        AS  whse_code, '   -- 倉庫コード
                     || ' iwm.whse_name        AS  whse_name, ';  -- 倉庫名称
    ELSE
      lv_select_porc := lv_select_porc
                     || ' NULL                 AS whse_code, '
                     || ' NULL                 AS whse_name, ';
    END IF;
    lv_select_porc := lv_select_porc
-- 2008/08/28 v1.8 UPDATE START
--                   || ' itp.trans_qty          AS  trans_qty, '  -- 取引数量
                   || ' itp.trans_qty * TO_NUMBER(porc_v.rcv_pay_div) AS  trans_qty, '  -- 取引数量
-- 2008/08/28 v1.8 UPDATE END
                   || ' itp.trans_date         AS  trans_date, '  -- 取引日
                   || ' porc_v.dealings_div_name AS  div_name, ' -- 取引区分名
                   || ' porc_v.rcv_pay_div     AS  pay_div, ';   -- 受払区分
--
    -- ============================================
    -- FROM句生成
    -- ============================================
    lv_from_porc := ' FROM '
                 || ' ic_tran_pnd                     itp, '
                 || ' xxcmn_rcv_pay_mst_porc_rma03_v  porc_v, '
                 || ' xxcmn_lookup_values2_v          xlvv,  '   -- クイックコード情報VIEW2
                 || ' xxcmn_lot_each_item_v           xleiv  ';  -- ロット別品目情報View
--
    -- 帳票区分が倉庫別
    IF ( ir_param.report_type = cv_one ) THEN
      lv_from_porc := lv_from_porc
                   || ' , ic_whse_mst             iwm ';
    END IF;
--
    -- ============================================
    -- WHERE句生成
    -- ============================================
    lv_where_porc := ' WHERE '
                  || '        itp.doc_type           = ''' || cv_porc || ''''
                  || '   AND  itp.doc_type           = porc_v.doc_type '
                  || '   AND  itp.doc_id             = porc_v.doc_id '
                  || '   AND  itp.doc_line           = porc_v.doc_line '
                  || '   AND  porc_v.dealings_div    = xlvv.meaning ';
--
    -- PORC:SQL
    lv_sql_porc := lv_select_porc || lv_select
                || lv_from_porc   || lv_where_porc
                || lv_where_itp   || lv_where;
--
    -- ===========================================================
    -- ORDER BY句生成
    -- ===========================================================
    lv_order := ' ORDER BY ';
--
    -- 群種別が3：群別の場合
    IF ( ir_param.crowd_type = cv_three ) THEN
--
      -- 帳票種別が1：倉庫別・品目別の場合
      IF ( ir_param.report_type = cv_one ) THEN
        lv_order := lv_order
                 || ' whse_code   ASC, '
                 || ' crowd_code  ASC, '
                 || ' item_code   ASC  ';
      -- 帳票種別が2：品目別の場合
      ELSIF ( ir_param.report_type = cv_two ) THEN
        lv_order := lv_order
                 || ' crowd_code  ASC, '
                 || ' item_code   ASC  ';
      END IF;
    -- 群種別が4：経理群別の場合
    ELSIF ( ir_param.crowd_type = cv_four ) THEN
--
      -- 帳票種別が1：倉庫別・品目別の場合
      IF ( ir_param.report_type = cv_one ) THEN
        lv_order := lv_order
                 || ' whse_code    ASC, '
                 || ' crowd_code   ASC, '
                 || ' item_code    ASC  ';
      -- 帳票種別が2：品目別の場合
      ELSIF ( ir_param.report_type = cv_two ) THEN
        lv_order := lv_order
                 || ' crowd_code   ASC, '
                 || ' item_code    ASC  ';
      END IF;
    END IF;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- オープン
    OPEN lc_ref FOR lv_sql_xfer
           || ' UNION ALL ' || lv_sql_trni
           || ' UNION ALL ' || lv_sql_adji_1
           || ' UNION ALL ' || lv_sql_adji_2
           || ' UNION ALL ' || lv_sql_adji_3
           || ' UNION ALL ' || lv_sql_adji_4
           || ' UNION ALL ' || lv_sql_prod
           || ' UNION ALL ' || lv_sql_omso
           || ' UNION ALL ' || lv_sql_porc || lv_order ;
    -- バルクフェッチ
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE lc_ref ;*/
-- 2008/10/22 v1.09 DELETE START
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data;
--
--
--
--
  /********************************************************************************
  * Procedure Name      : prc_item_sum
  * Description         : 品目明細加算処理
  ********************************************************************************/
  PROCEDURE prc_item_sum(
    in_pos            IN   NUMBER,       --   品目レコード配列位置
    in_unit_price     IN   NUMBER,       --   原価
    ov_errbuf         OUT  VARCHAR2,     --    エラー・メッセージ           --# 固定 #
    ov_retcode        OUT  VARCHAR2,     --    リターン・コード             --# 固定 #
    ov_errmsg         OUT  VARCHAR2      --    ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_item_sum'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル定数 ***
    cv_one         CONSTANT VARCHAR2(1) := '1';
    cn_one         CONSTANT NUMBER := 1;
    cn_zero        CONSTANT NUMBER := 0;
    cn_min         CONSTANT NUMBER := -1;
    -- *** ローカル変数 ***
    ln_col_pos     NUMBER DEFAULT 0;  --受払区分毎の印字位置数値
    ln_instr       NUMBER DEFAULT 0;
--
  BEGIN
--
    -- 印字位置(集計列位置）を数値へ変換
    BEGIN
      ln_instr := INSTR( gt_main_data(in_pos).column_no, gv_haifn );
      IF ( ln_instr > cn_zero )  THEN    --２箇所判定
        -- 受入区分 受入 = 1
        IF (gt_main_data(in_pos).pay_div = cv_one)  THEN
          ln_col_pos  :=  TO_NUMBER(SUBSTR(gt_main_data(in_pos).column_no,
                                                         cn_one, ln_instr - cn_one));
        ELSE
          ln_col_pos  :=  TO_NUMBER(SUBSTR( gt_main_data(in_pos).column_no, ln_instr + cn_one ));
        END IF;
      END IF;
    EXCEPTION
      WHEN VALUE_ERROR THEN
        ln_col_pos :=  cn_zero;
    END;
--
    IF (( ln_col_pos >= cn_one )
      AND ( ln_col_pos <= gc_print_pos_max )) THEN
-- 2008/08/28 v1.8 UPDATE START
--      IF (gt_main_data(in_pos).pay_div = cv_one ) THEN
--      --数量加算
--        qty(ln_col_pos) :=  qty(ln_col_pos) + gt_main_data(in_pos).trans_qty;
--      ELSIF (gt_main_data(in_pos).div_name = gv_div_name ) THEN --棚卸減の場合
--        qty(ln_col_pos) :=  qty(ln_col_pos) + (gt_main_data(in_pos).trans_qty);
--      ELSE
--        qty(ln_col_pos) :=  qty(ln_col_pos) + (gt_main_data(in_pos).trans_qty * cn_min);
      -- 2008/11/4 modify yoshida 暫定ロジック start
      qty(ln_col_pos) :=  qty(ln_col_pos) + (gt_main_data(in_pos).trans_qty);
      /*IF (gt_main_data(in_pos).div_name = gv_div_name ) THEN --棚卸減の場合
        qty(ln_col_pos) :=  qty(ln_col_pos)
          + (gt_main_data(in_pos).trans_qty / gt_main_data(in_pos).pay_div);
      ELSE
        qty(ln_col_pos) :=  qty(ln_col_pos) + (gt_main_data(in_pos).trans_qty);
-- 2008/08/28 v1.8 UPDATE END
      --金額加算
      END IF;*/
-- 2008/12/06 MOD START 実際原価、標準原価ともに金額計算を実施する。
--      IF ( gt_main_data(in_pos).cost_div = gc_cost_ac ) THEN
--        amt(ln_col_pos) := amt(ln_col_pos)
--                          + ROUND( in_unit_price * gt_main_data(in_pos).trans_qty);
--        /*IF ( gt_main_data(in_pos).pay_div = cv_one ) THEN
--          amt(ln_col_pos) := amt(ln_col_pos)
--                          + ( in_unit_price * gt_main_data(in_pos).trans_qty);
--        ELSE
--          amt(ln_col_pos) := amt(ln_col_pos)
--                          + ( in_unit_price * gt_main_data(in_pos).trans_qty * cn_min);
--        END IF;*/
--      ELSE
--        amt(ln_col_pos) := cn_zero;
--      END IF;
        amt(ln_col_pos) := amt(ln_col_pos)
                          + ROUND( in_unit_price * gt_main_data(in_pos).trans_qty);
-- 2008/12/06 MOD END
      -- 2008/11/4 modify yoshida 暫定ロジック end
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
  END prc_item_sum;
--
--
--
--
  /***********************************************************************************
  * Procedure Name     : prc_item_init
  * Description        : 品目明細クリア処理
  ************************************************************************************/
  PROCEDURE prc_item_init (
    ov_errbuf     OUT VARCHAR2,                 --    エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                 --    リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2                  --    ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_item_init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
    <<item_rec_clear>>
    FOR i IN 1 .. gc_print_pos_max LOOP
      qty(i) := 0;
      amt(i) := 0;
    END LOOP  item_rec_clear;
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
  END prc_item_init;
--
--
--
--
  /************************************************************************************
  * Procedure Name     : prc_create_xml_data
  * Description        : ＸＭＬデータ作成
  *************************************************************************************/
  PROCEDURE prc_create_xml_data(
    ir_param          IN  rec_param_data,    -- 01.レコード  ：パラメータ
    ov_errbuf         OUT VARCHAR2,          --    エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,          --    リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2           --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル定数 ***
    -- キーブレイク判断用
    lc_break_init           CONSTANT VARCHAR2(100) := '*';            -- 初期値
    lc_break_null           CONSTANT VARCHAR2(100) := '**';           -- ＮＵＬＬ判定
--
    cn_one                  CONSTANT NUMBER := 1;
    cn_zero                 CONSTANT NUMBER := 0;
    cn_two                  CONSTANT NUMBER := 2;
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_whse_code            VARCHAR2(100) DEFAULT lc_break_init;  -- 倉庫コード
    lv_crowd_high           VARCHAR2(100) DEFAULT lc_break_init;  -- 大群コード
    lv_crowd_mid            VARCHAR2(100) DEFAULT lc_break_init;  -- 中群コード
    lv_crowd_low            VARCHAR2(100) DEFAULT lc_break_init;  -- 小群コード
    lv_crowd_dtl            VARCHAR2(100) DEFAULT lc_break_init;  -- 群コード
    lv_item_code            VARCHAR2(100) DEFAULT lc_break_init;  -- 品目コード
--
    -- 計算用
    ln_i                    NUMBER       DEFAULT 0;              -- カウンター用
    ln_pos                  NUMBER       DEFAULT 1;
    ln_price                NUMBER       DEFAULT 0;              -- 原価用
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION;             -- 取得レコードなし
--
    -- ===============================
    -- XMLタグ挿入処理
    -- ===============================
    PROCEDURE prc_set_xml (
      ic_type              IN    CHAR,                    -- タグタイプ  T:タグ
                                                          -- D:データ
                                                          -- N:データ(NULLの場合タグを書かない)
                                                          -- Z:データ(NULLの場合0表示)
      iv_name              IN    VARCHAR2,                -- タグ名
      iv_value             IN    VARCHAR2  DEFAULT NULL,  -- タグデータ(省略可
      in_lengthb           IN    NUMBER    DEFAULT NULL,  -- 文字長（バイト）(省略可
      iv_index             IN    NUMBER    DEFAULT NULL   -- インデックス(省略可
    )
    IS
      -- =====================================================
      -- ユーザー宣言部
      -- =====================================================
      -- *** ローカル定数 ***
--
      -- *** ローカル変数 ***
      ln_xml_idx NUMBER;
      ln_work    NUMBER;
--
    BEGIN
--
      IF (ic_type = gc_n) THEN
        --NULLの場合タグを書かない対応
        IF (iv_value IS NULL) THEN
          RETURN;
        END IF;
--
        BEGIN
          ln_work := TO_NUMBER(iv_value);
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            RETURN;
        END;
      END IF;
--
      IF (iv_index IS NULL) THEN
        ln_xml_idx := gt_xml_data_table.COUNT + 1 ;
      ELSE
        ln_xml_idx := iv_index;
      END IF;
--
      --タグセット
      gt_xml_data_table(ln_xml_idx).tag_name  := iv_name ; --<タグ名>
      IF (ic_type = gc_t) THEN
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_t ;  --<タグのみ>
      ELSE
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_d ;  --<タグ ＆ データ>
        IF (ic_type = gc_z) THEN
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(iv_value, 0) ; --Nullの場合０表示
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := iv_value ;         --Nullでもそのまま表示
        END IF;
      END IF;
--
      --文字切り
      IF (in_lengthb IS NOT NULL) THEN
        gt_xml_data_table(ln_xml_idx).tag_value
          := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value, cn_one, in_lengthb);
      END IF;
--
    END prc_set_xml ;
--
--
--
    -- ============================
    -- 明細項目 ＸＭＬ出力
    -- ============================
    PROCEDURE prc_xml_body_add (
      in_pos             IN  NUMBER,       --   品目レコード配列位置
      in_price           IN  NUMBER        --   品目原価
    )
    IS
--
    BEGIN
      -- =====================================================
      -- 明細出力編集
      -- =====================================================
      -- =========================================
      -- 品目ID
      -- =========================================
-- 2009/01/13 v1.17 DELETE START
--      IF ((qty(gc_hamaoka_num)    + qty(gc_rec_kind_num) + qty(gc_rec_whse_num)
--           + qty(gc_rec_etc_num)  + qty(gc_resale_num)   + qty(gc_aband_num)
--           + qty(gc_sample_num)   + qty(gc_admin_num)    + qty(gc_acnt_num)
--           + qty(gc_dis_kind_num) + qty(gc_dis_whse_num) + qty(gc_dis_etc_num)
--           + qty(gc_inv_he_num)) <> cn_zero ) THEN
-- 2009/01/13 v1.17 DELETE END
-- 2008/10/22 v1.09 ADD START
        prc_set_xml('T', 'g_line');
-- 2008/10/22 v1.09 ADD START
        prc_set_xml('D', 'item_code',    gt_main_data(in_pos).item_code);
--
        -- =========================================
        -- 品目名称
        -- =========================================
        prc_set_xml('D', 'item_name', gt_main_data(in_pos).item_name, 20);
--
        -- ==================================================
        -- 受入
        -- ==================================================
        -- =========================================
        -- 浜岡
        -- =========================================
        prc_set_xml('Z', 'hamaoka_qty',    qty(gc_hamaoka_num));
--
--2008/12/06 MOD START
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'hamaoka_amt',  ROUND(qty(gc_hamaoka_num) * in_price));
--        ELSE
--          prc_set_xml('Z', 'hamaoka_amt',  amt(gc_hamaoka_num));
--        END IF;
	    prc_set_xml('Z', 'hamaoka_amt',  amt(gc_hamaoka_num));
--2008/12/06 MOD END
--
        -- =========================================
        -- 品種移動
        -- =========================================
        prc_set_xml('Z', 'rec_kind_qty',   qty(gc_rec_kind_num));
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'rec_kind_amt',   ROUND(qty(gc_rec_kind_num) * in_price));
--        ELSE
          prc_set_xml('Z', 'rec_kind_amt',   amt(gc_rec_kind_num));
--        END IF;
--
        -- =========================================
        -- 倉庫移動
        -- =========================================
        prc_set_xml('Z', 'rec_whse_qty',   qty(gc_rec_whse_num));
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'rec_whse_amt',   ROUND(qty(gc_rec_whse_num) * in_price));
--        ELSE
          prc_set_xml('Z', 'rec_whse_amt',   amt(gc_rec_whse_num));
--        END IF;
--
        -- =========================================
        -- その他
        -- =========================================
        prc_set_xml('Z', 'rec_etc_qty',    qty(gc_rec_etc_num));
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'rec_etc_amt',    ROUND(qty(gc_rec_etc_num) * in_price));
--        ELSE
          prc_set_xml('Z', 'rec_etc_amt',    amt(gc_rec_etc_num));
--        END IF;
--
        -- =========================================
        -- 受払合計
        -- =========================================
        prc_set_xml('Z', 'rec_total_qty',  qty(gc_hamaoka_num)
                                        +  qty(gc_rec_kind_num)
                                        +  qty(gc_rec_whse_num)
                                        +  qty(gc_rec_etc_num));
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'rec_total_amt',  ROUND(qty(gc_hamaoka_num)  * in_price)
--                                          +  ROUND(qty(gc_rec_kind_num) * in_price)
--                                          +  ROUND(qty(gc_rec_whse_num) * in_price)
--                                          +  ROUND(qty(gc_rec_etc_num)  * in_price));
--        ELSE
          prc_set_xml('Z', 'rec_total_amt',  amt(gc_hamaoka_num)
                                          +  amt(gc_rec_kind_num)
                                          +  amt(gc_rec_whse_num)
                                          +  amt(gc_rec_etc_num));
--        END IF;
--
        -- ===================================================
        -- 払出
        -- ===================================================
        -- =========================================
        -- 転売
        -- =========================================
        prc_set_xml('Z', 'resale_qty',     qty(gc_resale_num));
--
--       IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'resale_amt',     ROUND(qty(gc_resale_num) * in_price));
--        ELSE
          prc_set_xml('Z', 'resale_amt',     amt(gc_resale_num) );
--        END IF;
--
        -- =========================================
        -- 廃却
        -- =========================================
        prc_set_xml('Z', 'aband_qty',      qty(gc_aband_num) );
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'aband_amt' ,     ROUND(qty(gc_aband_num) * in_price));
--        ELSE
          prc_set_xml('Z', 'aband_amt' ,     amt(gc_aband_num) );
--        END IF;
--
        -- =========================================
        -- 見本
        -- =========================================
        prc_set_xml('Z', 'sample_qty',     qty(gc_sample_num) );
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--         prc_set_xml('Z', 'sample_amt',     ROUND(qty(gc_sample_num) * in_price));
--        ELSE
          prc_set_xml('Z', 'sample_amt',     amt(gc_sample_num) );
--        END IF;
--
        -- =========================================
        -- 総務払出
        -- =========================================
        prc_set_xml('Z', 'admin_qty',      qty(gc_admin_num) );
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'admin_amt',      ROUND(qty(gc_admin_num)  * in_price));
--        ELSE
          prc_set_xml('Z', 'admin_amt',      amt(gc_admin_num) );
--        END IF;
--
        -- =========================================
        -- 経理払出
        -- =========================================
        prc_set_xml('Z', 'acnt_qty',       qty(gc_acnt_num));
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'acnt_amt',       ROUND(qty(gc_acnt_num) * in_price));
--        ELSE
          prc_set_xml('Z', 'acnt_amt',       amt(gc_acnt_num) );
--        END IF;
--
        -- =========================================
        -- 品種移動
        -- =========================================
        prc_set_xml('Z', 'dis_kind_qty',   qty(gc_dis_kind_num) );
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'dis_kind_amt',   ROUND(qty(gc_dis_kind_num) * in_price));
--        ELSE
          prc_set_xml('Z', 'dis_kind_amt',   amt(gc_dis_kind_num) );
--        END IF;
--
        -- =========================================
        -- 倉庫移動
        -- =========================================
        prc_set_xml('Z', 'dis_whse_qty',   qty(gc_dis_whse_num));
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'dis_whse_amt',  ROUND(qty(gc_dis_whse_num) * in_price));
--        ELSE
          prc_set_xml('Z', 'dis_whse_amt',   amt(gc_dis_whse_num) );
--        END IF;
--
        -- =========================================
        -- その他
        -- =========================================
        prc_set_xml('Z', 'dis_etc_qty',    qty(gc_dis_etc_num) );
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'dis_etc_amt',    ROUND(qty(gc_dis_etc_num)  * in_price));
--        ELSE
          prc_set_xml('Z', 'dis_etc_amt',    amt(gc_dis_etc_num) );
--        END IF;
--
        -- =========================================
        -- 棚卸減耗
        -- =========================================
        prc_set_xml('Z', 'inv_he_qty',     qty(gc_inv_he_num));
--
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'inv_he_amt',     ROUND(qty(gc_inv_he_num) * in_price));
--        ELSE
          prc_set_xml('Z', 'inv_he_amt',     amt(gc_inv_he_num));
--        END IF;
--
        -- =========================================
        -- 払出合計
        -- =========================================
        prc_set_xml('Z', 'dis_total_qty', qty(gc_resale_num)
                                        + qty(gc_aband_num)
                                        + qty(gc_sample_num)
                                        + qty(gc_admin_num)
                                        + qty(gc_acnt_num)
                                        + qty(gc_dis_kind_num)
                                        + qty(gc_dis_whse_num)
                                        + qty(gc_dis_etc_num)
                                        + qty(gc_inv_he_num));
--        IF ( gt_main_data(in_pos).cost_div = gc_cost_st ) THEN
--          prc_set_xml('Z', 'dis_total_amt', ROUND(qty(gc_resale_num)   * in_price)
--                                          + ROUND(qty(gc_aband_num)    * in_price)
--                                          + ROUND(qty(gc_sample_num)   * in_price)
--                                          + ROUND(qty(gc_admin_num)    * in_price)
--                                          + ROUND(qty(gc_acnt_num)     * in_price)
--                                          + ROUND(qty(gc_dis_kind_num) * in_price)
--                                          + ROUND(qty(gc_dis_whse_num) * in_price)
--                                          + ROUND(qty(gc_dis_etc_num)  * in_price)
--                                          + ROUND(qty(gc_inv_he_num)   * in_price));
--        ELSE
          prc_set_xml('Z', 'dis_total_amt', amt(gc_resale_num)
                                          + amt(gc_aband_num)
                                          + amt(gc_sample_num)
                                          + amt(gc_admin_num)
                                          + amt(gc_acnt_num)
                                          + amt(gc_dis_kind_num)
                                          + amt(gc_dis_whse_num)
                                          + amt(gc_dis_etc_num)
                                          + amt(gc_inv_he_num));
--        END IF;
-- 2008/10/22 v1.09 ADD START
        prc_set_xml('T', '/g_line');
-- 2008/10/22 v1.09 ADD START
-- 2009/01/13 v1.17 DELETE START
--      END IF;
-- 2009/01/13 v1.17 DELETE END
--
    END prc_xml_body_add;
--
--
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
    -- =====================================================
    -- 項目データ抽出処理
    -- =====================================================
    prc_get_report_data(
        ir_param      => ir_param       -- 01.入力パラメータ群
       ,ot_data_rec   => gt_main_data   -- 02.取得レコード群
       ,ov_errbuf     => lv_errbuf      --    エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --    リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --    ユーザー・エラー・メッセージ --# 固定 #
      );
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
    -- 取得データが０件の場合
    ELSIF ( gt_main_data.COUNT = cn_zero ) THEN
      RAISE no_data_expt;
    END IF;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- ユーザーＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'user_info');
    -- -----------------------------------------------------
    -- ユーザーＧデータタグ出力
    -- -----------------------------------------------------
    -- 帳票ＩＤ
    prc_set_xml('D', 'report_id', gv_report_id);
    -- 実施日
    prc_set_xml('D', 'output_date', TO_CHAR( gd_exec_date, gc_char_dt_format ));
    -- 担当部署
    prc_set_xml('D', 'charge_dept', gv_user_dept, 10);
    -- 担当者名
    prc_set_xml('D', 'agent', gv_user_name, 14);
    -- 処理年
    prc_set_xml('D', 'process_year', SUBSTR(gv_exec_start,1,4));
    -- 処理月
    prc_set_xml('D', 'process_month', SUBSTR(gv_exec_start,6,2));
    -- 商品区分
    prc_set_xml('D', 'commodity_div', ir_param.item_division);
    -- 商品区分名称
    prc_set_xml('D', 'commodity_div_name', gv_item_div_name, 20);
    -- 品目区分
    prc_set_xml('D', 'item_div', ir_param.art_division);
    -- 品目区分名
    prc_set_xml('D', 'item_div_name', gv_art_div_name, 20);
    -- 帳票種別
    prc_set_xml('D', 'report_type', ir_param.report_type);
    -- 帳票種別名
    prc_set_xml('D', 'report_type_name', gv_report_div_name, 20);
    -- 群種別
    prc_set_xml('D', 'crowd_type', ir_param.crowd_type);
    -- 群種別名
    prc_set_xml('D', 'crowd_type_name', gv_crowd_kind_name, 20);
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', '/user_info');
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'data_info');
    -- レポートタイトル
    prc_set_xml('D', 'report_name', gv_print_name);
    -- -----------------------------------------------------
    -- 倉庫ＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'lg_locat');
--
    -- 配列位置カウンタの初期値設定
    ln_i  := cn_one;
   --=========================================総合計
    <<total_loop>>
    WHILE ( ln_i  <= gt_main_data.COUNT)                                             LOOP
      lv_whse_code  :=  NVL(gt_main_data(ln_i).whse_code, lc_break_null);
      prc_set_xml('T', 'g_locat');
      prc_set_xml('D', 'whse_code', gt_main_data(ln_i).whse_code);
      prc_set_xml('D', 'whse_name', gt_main_data(ln_i).whse_name, 20);
      -- 倉庫区分：フラグ
      IF (( ir_param.warehouse_code IS NOT NULL )
        OR ( ir_param.report_type = cn_two )) THEN
        prc_set_xml('D', 'whse_flg', cn_zero);
      ELSE
        prc_set_xml('D', 'whse_flg', cn_one);
      END IF;
      prc_set_xml('D', 'position', ln_pos);
      prc_set_xml('T', 'lg_crowd_large');
      --=============================================倉庫コード開始
      <<whse_code_loop>>
      WHILE (ln_i  <= gt_main_data.COUNT)
        AND (NVL( gt_main_data(ln_i).whse_code, lc_break_null )  = lv_whse_code)      LOOP
        lv_crowd_high  :=  NVL(gt_main_data(ln_i).crowd_large, lc_break_null);
        prc_set_xml('T', 'g_crowd_large');
        prc_set_xml('D', 'crowd_large_code', gt_main_data(ln_i).crowd_large);
        prc_set_xml('T', 'lg_crowd_medium');
        --===============================================大群コード開始
        <<large_grp_loop>>
        WHILE (ln_i  <= gt_main_data.COUNT)
          AND (NVL( gt_main_data(ln_i).whse_code, lc_break_null )  = lv_whse_code)
          AND (NVL( gt_main_data(ln_i).crowd_large, lc_break_null ) = lv_crowd_high)     LOOP
          lv_crowd_mid  :=  NVL(gt_main_data(ln_i).crowd_medium, lc_break_null);
          prc_set_xml('T', 'g_crowd_medium');
          prc_set_xml('D', 'crowd_medium_code', gt_main_data(ln_i).crowd_medium);
          prc_set_xml('T', 'lg_crowd_small');
          --================================================中群コード開始
          <<midle_grp_loop>>
          WHILE (ln_i  <= gt_main_data.COUNT)
            AND (NVL( gt_main_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
            AND (NVL( gt_main_data(ln_i).crowd_medium, lc_break_null ) = lv_crowd_mid)       LOOP
            lv_crowd_low  :=  NVL(gt_main_data(ln_i).crowd_small, lc_break_null);
            prc_set_xml('T', 'g_crowd_small');
            prc_set_xml('D', 'crowd_small_code', gt_main_data(ln_i).crowd_small);
            prc_set_xml('T', 'lg_crowd_detail');
            --====================================================小群コード開始
            <<minor_grp_loop>>
            WHILE (ln_i  <= gt_main_data.COUNT)
              AND (NVL( gt_main_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
              AND (NVL( gt_main_data(ln_i).crowd_small, lc_break_null ) = lv_crowd_low)       LOOP
              lv_crowd_dtl  :=  NVL(gt_main_data(ln_i).crowd_code, lc_break_null);
              prc_set_xml('T', 'g_crowd_detail');
              prc_set_xml('D', 'crowd_detail_code', gt_main_data(ln_i).crowd_code);
              prc_set_xml('T', 'lg_line');
              --========================================================群コード開始
              <<grp_loop>>
              WHILE (ln_i  <= gt_main_data.COUNT)
                AND (NVL( gt_main_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
                AND (NVL( gt_main_data(ln_i).crowd_code, lc_break_null ) = lv_crowd_dtl)      LOOP
                lv_item_code  :=  NVL(gt_main_data(ln_i).item_code, lc_break_null);
-- 2008/10/22 v1.09 DELETE START
                --prc_set_xml('T', 'g_line');
-- 2008/10/22 v1.09 DELETE START
                -- 品目明細クリア
                prc_item_init(
                  ov_errbuf     => lv_errbuf,
                  ov_retcode    => lv_retcode,
                  ov_errmsg     => lv_errmsg
                );
                IF ( lv_retcode = gv_status_error ) THEN
                  RAISE global_api_expt;
                END IF;
-- 2008/10/22 v1.09 DELETE START
                -- 原価取得
                --ln_price := fnc_item_unit_pric_get (
                --              in_pos   =>   ln_i
                --            );
-- 2008/10/22 v1.09 DELETE START
                --==========================================================品目開始
                <<item_loop>>
                WHILE (( ln_i  <= gt_main_data.COUNT )
                  AND  ( NVL( gt_main_data(ln_i).whse_code, lc_break_null ) = lv_whse_code )
                  AND  ( NVL( gt_main_data(ln_i).item_code, lc_break_null ) = lv_item_code ))  LOOP
-- 2008/10/22 v1.09 DELETE START
                  -- 原価取得
                  ln_price := fnc_item_unit_pric_get (
                                in_pos   =>   ln_i
                              );
-- 2008/10/22 v1.09 DELETE START
                  -- 品目明細加算処理
                  prc_item_sum (
                    in_pos         => ln_i,
                    in_unit_price  => ln_price,
                    ov_errbuf      => lv_errbuf,
                    ov_retcode     => lv_retcode,
                    ov_errmsg      => lv_errmsg
                  );
                  IF ( lv_retcode = gv_status_error ) THEN
                    RAISE global_api_expt;
                  END IF;
                  -- 次明細位置
                  ln_i  :=  ln_i  + cn_one;
                END LOOP  item_loop;--======================================品目終了
                -- 品目明細ＸＭＬ出力
                prc_xml_body_add (
                  in_pos        => ln_i - cn_one,
                  in_price      => ln_price
                );
                IF ( lv_retcode = gv_status_error ) THEN
                  RAISE global_api_expt;
                END IF;
-- 2008/10/22 v1.09 DELETE START
                --prc_set_xml('T', '/g_line');
-- 2008/10/22 v1.09 DELETE START
              END LOOP  grp_loop;--=====================================群コード終了
              prc_set_xml('T', '/lg_line');
              prc_set_xml('T', '/g_crowd_detail');
            END LOOP  minor_grp_loop;--===========================小群コード終了
            prc_set_xml('T', '/lg_crowd_detail');
            prc_set_xml('T', '/g_crowd_small');
          END LOOP  midle_grp_loop;--========================中群コード終了
          prc_set_xml('T', '/lg_crowd_small');
          prc_set_xml('T', '/g_crowd_medium');
        END LOOP  large_grp_loop;--======================大群コード終了
        prc_set_xml('T', '/lg_crowd_medium');
        prc_set_xml('T','/g_crowd_large');
      END LOOP  whse_code_loop;--====================倉庫計終了
      prc_set_xml('T','/lg_crowd_large');
      prc_set_xml('T','/g_locat');
      ln_pos := ln_pos + cn_one;
    END LOOP  total_loop;--====================総合計(ALL END)
--
    prc_set_xml('T', '/lg_locat');
    prc_set_xml('T', '/data_info');
--
  EXCEPTION
  -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' );
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
  END prc_create_xml_data;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain (
    iv_process_year       IN    VARCHAR2,  -- 処理年月
    iv_item_division      IN    VARCHAR2,  -- 商品区分
    iv_art_division       IN    VARCHAR2,  -- 品目区分
    iv_report_type        IN    VARCHAR2,  -- レポート区分
    iv_warehouse_code     IN    VARCHAR2,  -- 倉庫コード
    iv_crowd_type         IN    VARCHAR2,  -- 群種別
    iv_crowd_code         IN    VARCHAR2,  -- 群コード
    iv_account_code       IN    VARCHAR2,  -- 経理群コード
    ov_errbuf             OUT   VARCHAR2,  -- エラー・メッセージ            # 固定 #
    ov_retcode            OUT   VARCHAR2,  -- リターン・コード              # 固定 #
    ov_errmsg             OUT   VARCHAR2   -- ユーザー・エラー・メッセージ  # 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   エラー・メッセージ
    lv_retcode VARCHAR2(1) ;                      --   リターン・コード
    lv_errmsg  VARCHAR2(5000) ;                   --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
--
    lr_param_rec            rec_param_data ;          -- パラメータ受渡し用
    lv_xml_string           VARCHAR2(32000) DEFAULT '*';
    cv_num                  CONSTANT VARCHAR2(1)  := '1';
    ln_vendor_code          NUMBER DEFAULT 0; -- 取引先
    ln_art_code             NUMBER DEFAULT 0; -- 品目
    ld_year                 DATE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 初期処理
    -- =====================================================
    -- 帳票出力値格納
    gv_report_id                := 'XXCMN770003T';      -- 帳票ID
    gd_exec_date                := SYSDATE;            -- 実施日
    -- パラメータ格納
    -- 処理月
    lr_param_rec.process_year   := iv_process_year;
    lr_param_rec.item_division  := iv_item_division;
    lr_param_rec.art_division   := iv_art_division;
    lr_param_rec.report_type    := iv_report_type;
    lr_param_rec.warehouse_code := iv_warehouse_code;
    lr_param_rec.crowd_type     := iv_crowd_type;
    lr_param_rec.crowd_code     := iv_crowd_code;
    lr_param_rec.account_code   := iv_account_code;
--
    -- 2009/05/29 ADD START
    gd_st_unit_date := FND_DATE.STRING_TO_DATE(iv_process_year , gc_char_m_format);
    -- 2009/05/29 ADD END
    -- =====================================================
    -- 前処理
    -- =====================================================
    prc_initialize (
      ir_param          => lr_param_rec,       -- 入力パラメータ群
      ov_errbuf         => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      ov_retcode        => lv_retcode,         -- リターン・コード             --# 固定 #
      ov_errmsg         => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 帳票データ出力
    -- =====================================================
    prc_create_xml_data (
     ir_param         => lr_param_rec,       -- 入力パラメータレコード
     ov_errbuf        => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
     ov_retcode       => lv_retcode,         -- リターン・コード             --# 固定 #
     ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- ＸＭＬ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF (( lv_errmsg IS NOT NULL )
      AND ( lv_retcode = gv_status_warn )) THEN
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <report_name>' || gv_print_name || '</report_name>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <whse_flg>1</whse_flg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <lg_crowd_large>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <g_crowd_large>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <lg_crowd_medium>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <g_crowd_medium>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <lg_crowd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <g_crowd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <lg_crowd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <g_crowd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <msg>' || lv_errmsg || '</msg>' );
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </g_crowd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </lg_crowd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </g_crowd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </lg_crowd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </g_crowd_medium>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </lg_crowd_medium>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </g_crowd_large>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </lg_crowd_large>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- ０件メッセージログ出力
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10154'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
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
        lv_xml_string := fnc_conv_xml (
                           iv_name   => gt_xml_data_table(i).tag_name,    -- タグネーム
                           iv_value  => gt_xml_data_table(i).tag_value,   -- タグデータ
                           ic_type   => gt_xml_data_table(i).tag_type     -- タグタイプ
                         );
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
  END submain ;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main (
    errbuf                OUT   VARCHAR2,  -- エラーメッセージ
    retcode               OUT   VARCHAR2,  -- エラーコード
    iv_process_year       IN    VARCHAR2,  -- 処理年月
    iv_item_division      IN    VARCHAR2,  -- 商品区分
    iv_art_division       IN    VARCHAR2,  -- 品目区分
    iv_report_type        IN    VARCHAR2,  -- レポート区分
    iv_warehouse_code     IN    VARCHAR2,  -- 倉庫コード
    iv_crowd_type         IN    VARCHAR2,  -- 群種別
    iv_crowd_code         IN    VARCHAR2,  -- 群コード
    iv_account_code       IN    VARCHAR2   -- 経理群コード
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
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain (
      iv_process_year        =>  iv_process_year,     -- 処理年月
      iv_item_division       =>  iv_item_division,    -- 商品区分
      iv_art_division        =>  iv_art_division,     -- 品目区分
      iv_report_type         =>  iv_report_type,      -- 帳票種別
      iv_warehouse_code      =>  iv_warehouse_code,   -- 倉庫コード
      iv_crowd_type          =>  iv_crowd_type,       -- 群種別
      iv_crowd_code          =>  iv_crowd_code,       -- 群コード
      iv_account_code        =>  iv_account_code,     -- 経理群コード
      ov_errbuf              =>  lv_errbuf,           -- エラー・メッセージ            # 固定 #
      ov_retcode             =>  lv_retcode,          -- リターン・コード              # 固定 #
      ov_errmsg              =>  lv_errmsg            -- ユーザー・エラー・メッセージ  # 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF (( lv_retcode = gv_status_error )
      OR ( lv_retcode = gv_status_warn )) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxcmn770003cp ;
/
