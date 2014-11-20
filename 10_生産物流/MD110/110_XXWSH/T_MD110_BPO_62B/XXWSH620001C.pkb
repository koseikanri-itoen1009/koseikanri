CREATE OR REPLACE PACKAGE BODY xxwsh620001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620001c(body)
 * Description      : 在庫不足確認リスト
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_620
 * MD.070           : 在庫不足確認リスト T_MD070_BPO_62B
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  fnc_chgdt_d            FUNCTION  : 日付型変換(YYYY/MM/DD形式の文字列 → 日付型)
 *  fnc_chgdt_c            FUNCTION  : 日付型変換(日付型 → YYYY/MM/DD形式の文字列)
 *  prc_set_tag_data       PROCEDURE : タグ情報設定処理
 *  prc_set_tag_data       PROCEDURE : タグ情報設定処理(開始・終了タグ用)
 *  prc_initialize         PROCEDURE : 初期処理
 *  prc_get_report_data    PROCEDURE : 帳票データ取得処理
 *  prc_create_xml_data    PROCEDURE : XML生成処理
 *  fnc_convert_into_xml   FUNCTION  : XMLデータ変換
 *  submain                PROCEDURE : メイン処理プロシージャ
 *  main                   PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -----------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -----------------------------------------------
 *  2008/05/05    1.0   Nozomi Kashiwagi   新規作成
 *  2008/07/08    1.1   Akiyoshi Shiina    禁則文字「'」「"」「<」「>」「＆」対応
 *  2008/09/26    1.2   Hitomi Itou        T_TE080_BPO_600 指摘38
 *                                         T_TE080_BPO_600 指摘37
 *                                         T_S_533(PT対応 動的SQLに変更)
 *  2008/10/03    1.3   Hitomi Itou        T_TE080_BPO_600 指摘37 在庫不足の場合、ロット別数には不足数を表示する
 *  2008/11/13    1.4   Tsuyoki Yoshimoto  内部変更#168
 *  2008/12/10    1.5   T.Miyata           本番#637 パフォーマンス対応
 *  2008/12/10    1.6   Hitomi Itou        本番障害#650
 *  2009/01/07    1.7   Akiyoshi Shiina    本番障害#873
 *  2009/01/14    1.8   Hisanobu Sakuma    本番障害#661
 *  2009/01/20    1.9   Hisanobu Sakuma    本番障害#800
 *  2009/01/21    1.10  Hisanobu Sakuma    本番障害#1065
 *  2009/01/27    1.11  Hisanobu Sakuma    本番障害#1066
 *  2009/03/06    1.12  Yuki Kazama        本番障害#785
 *  2009/05/18    1.13  D.Sugahara         本番障害#1482 パフォーマンス対応
 *  2009/05/21    1.14  H.Itou             本番障害#1476,1398
 *  2012/03/30    1.15  K.Nakamura         E_本稼動_09296 パフォーマンス対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
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
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--###########################  固定部 END   ############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** 処理部共通例外 ***
  no_data_expt       EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- 帳票情報
  gc_pkg_name                CONSTANT  VARCHAR2(12) := 'xxwsh620001c' ;  -- パッケージ名
  gc_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620001T' ;  -- 帳票ID
  -- 日付フォーマット
  gc_date_fmt_all            CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- 年月日時分秒
  gc_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;            -- 年月日
  gc_date_fmt_hm             CONSTANT  VARCHAR2(10) := 'HH24:MI' ;               -- 時分秒
  gc_date_fmt_ymd_ja         CONSTANT  VARCHAR2(20) := 'YYYY"年"MM"月"DD"日' ;   -- 時分
  -- 時間
  gc_time_start              CONSTANT  VARCHAR2(5) := '00:00' ;
  gc_time_end                CONSTANT  VARCHAR2(5) := '23:59' ;
  -- 出力タグ
  gc_tag_type_tag            CONSTANT  VARCHAR2(1)  := 'T' ;                 -- グループタグ
  gc_tag_type_data           CONSTANT  VARCHAR2(1)  := 'D' ;                 -- データタグ
  -- 業務種別
  gc_biz_type_nm_ship        CONSTANT  VARCHAR2(4)  := '出荷' ;     -- 出荷
  gc_biz_type_nm_move        CONSTANT  VARCHAR2(4)  := '移動' ;     -- 移動
  -- 削除・取消フラグ
  gc_delete_flg              CONSTANT  VARCHAR2(1)  := 'Y' ;        -- 鮮度不備
  -- 文書タイプ
  gc_doc_type_ship           CONSTANT  VARCHAR2(2)  := '10' ;       -- 出荷依頼
  gc_doc_type_move           CONSTANT  VARCHAR2(2)  := '20' ;       -- 移動
  -- レコードタイプ
  gc_rec_type_shiji          CONSTANT  VARCHAR2(2)  := '10' ;       -- 指示
  ------------------------------
  -- 出荷関連
  ------------------------------
  -- 出荷支給区分
  gc_ship_pro_kbn_s          CONSTANT  VARCHAR2(1)  := '1' ;        -- 出荷依頼
  -- 受注カテゴリ
  gc_order_cate_ret          CONSTANT  VARCHAR2(10) := 'RETURN' ;   -- 返品(受注のみ)
  -- 最新フラグ
  gc_new_flg                 CONSTANT  VARCHAR2(1)  := 'Y' ;        -- 最新フラグ
  -- 出荷依頼ステータス
  gc_ship_status_close       CONSTANT  VARCHAR2(2)  := '03' ;       -- 締め済み
  gc_ship_status_delete      CONSTANT  VARCHAR2(2)  := '99' ;       -- 取消
-- 2009/01/07 v1.7 ADD START
  gc_ship_status_confirm     CONSTANT  VARCHAR2(2)  := '04' ;       -- 出荷実績計上済
-- 2009/01/07 v1.7 ADD END

  ------------------------------
  -- 移動関連
  ------------------------------
  -- 移動タイプ
  gc_mov_type_not_ship       CONSTANT  VARCHAR2(5)  := '2' ;        -- 積送なし
  -- 移動ステータス
  gc_move_status_ordered     CONSTANT  VARCHAR2(2)  := '02' ;       -- 依頼済
-- 2008/11/13 v1.4 T.Yoshimoto Add Start
  -- 指示なし実績区分
  gc_move_instr_actual_class      CONSTANT  VARCHAR2(1)  := 'Y' ;        -- 指示なし実績
-- 2008/11/13 v1.4 T.Yoshimoto Add End
-- 2008/12/10 v1.5 H.Itou Add Start
  -- 通知ステータス
  gc_notif_status_ktz        CONSTANT  VARCHAR2(2)  := '40' ;       -- 確定通知済
-- 2009/01/07 v1.7 ADD START
  gc_notif_status_mt         CONSTANT  VARCHAR2(2)  := '10' ;       -- 未通知
  gc_notif_status_sty        CONSTANT  VARCHAR2(2)  := '20' ;       -- 再通知要
-- 2009/01/07 v1.7 ADD END
-- 2008/12/10 v1.5 H.Itou Add End
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_lookup_cd_block         CONSTANT  VARCHAR2(30)  := 'XXCMN_D12' ;          -- 物流ブロック
  gc_lookup_cd_lot_status    CONSTANT  VARCHAR2(30)  := 'XXCMN_LOT_STATUS' ;   -- ロットステータス
  gc_lookup_cd_conreq        CONSTANT  VARCHAR2(30)  := 'XXWSH_LG_CONFIRM_REQ_CLASS' ; -- 確認依頼
  ------------------------------
  -- プロファイル関連
  ------------------------------
  gc_prof_name_item_div      CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_DIV_SECURITY' ; -- 商品区分
  ------------------------------
  -- メッセージ関連
  ------------------------------
  --アプリケーション名
  gc_application_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH' ;            -- ｱﾄﾞｵﾝ:出荷･引当･配車
  gc_application_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN' ;            -- ｱﾄﾞｵﾝ:ﾏｽﾀ･経理･共通
  --メッセージID
  gc_msg_id_not_get_prof     CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12301' ;  -- ﾌﾟﾛﾌｧｲﾙ取得ｴﾗｰ
  gc_msg_id_no_data          CONSTANT  VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- 帳票0件エラー
  gc_msg_id_prm_chk          CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12256' ;  -- ﾊﾟﾗﾒｰﾀﾁｪｯｸｴﾗｰ
  --メッセージ-トークン名
  gc_msg_tkn_nm_prof         CONSTANT  VARCHAR2(10) := 'PROF_NAME' ;        -- プロファイル名
  --メッセージ-トークン値
  gc_msg_tkn_val_prof_prod   CONSTANT  VARCHAR2(30) := 'XXCMN：商品区分(セキュリティ)' ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- レコード型宣言用テーブル別名宣言
  xoha   xxwsh_order_headers_all%ROWTYPE ;        -- 受注ヘッダアドオン
  xola   xxwsh_order_lines_all%ROWTYPE ;          -- 受注明細アドオン
  xmrih  xxinv_mov_req_instr_headers%ROWTYPE ;    -- 移動依頼/指示ヘッダ(アドオン)
  xmril  xxinv_mov_req_instr_lines%ROWTYPE ;      -- 移動依頼/指示明細(アドオン)
  xmld   xxinv_mov_lot_details%ROWTYPE ;          -- 移動ロット詳細(アドオン)
  ilm    ic_lots_mst%ROWTYPE ;                    -- OPMロットマスタ
  xottv  xxwsh_oe_transaction_types2_v%ROWTYPE ;  -- 受注タイプ情報VIEW2
  xtc    xxwsh_tightening_control%ROWTYPE ;       -- 出荷依頼締め管理(アドオン)
  xilv   xxcmn_item_locations2_v%ROWTYPE ;        -- OPM保管場所情報(出庫元)
  xcav   xxcmn_cust_accounts2_v%ROWTYPE ;         -- 顧客情報
  xcasv  xxcmn_cust_acct_sites2_v%ROWTYPE ;       -- 顧客サイト情報
  ximv   xxcmn_item_mst2_v%ROWTYPE ;              -- OPM品目情報
  xicv   xxcmn_item_categories4_v%ROWTYPE ;       -- OPM品目カテゴリ割当情報
  xlvv   xxcmn_lookup_values2_v%ROWTYPE ;         -- クイックコード
--
  ------------------------------
  -- 入力パラメータ関連
  ------------------------------
  -- 入力パラメータ格納用レコード
  TYPE rec_param_data IS RECORD(
     block1              xilv.distribution_block%TYPE      -- 01:ブロック1
    ,block2              xilv.distribution_block%TYPE      -- 02:ブロック2
    ,block3              xilv.distribution_block%TYPE      -- 03:ブロック3
    ,tighten_date        DATE                              -- 04:締め実施日
    ,tighten_time_from   VARCHAR2(5)                       -- 05:締め実施時間From
    ,tighten_time_to     VARCHAR2(5)                       -- 06:締め実施時間To
    ,shipped_cd          xoha.deliver_from%TYPE            -- 07:出庫元
    ,item_cd             xola.shipping_item_code%TYPE      -- 08:品目
    ,shipped_date_from   DATE                              -- 09:出庫日From  ※必須
    ,shipped_date_to     DATE                              -- 10:出庫日To    ※必須
  );
--
  ------------------------------
  -- 出力データ関連
  ------------------------------
  -- 出力データ格納用レコード
  TYPE rec_report_data IS RECORD(
     block_cd          xilv.distribution_block%TYPE          -- ブロックコード
    ,block_nm          xlvv.meaning%TYPE                     -- ブロック名称
    ,shipped_cd        xoha.deliver_from%TYPE                -- 出庫元コード
    ,shipped_nm        xilv.description%TYPE                 -- 出庫元名
    ,item_cd           xola.shipping_item_code%TYPE          -- 品目コード
    ,item_nm           ximv.item_name%TYPE                   -- 品目名称
    ,shipped_date      xoha.schedule_ship_date%TYPE          -- 出庫日
    ,arrival_date      xoha.schedule_arrival_date%TYPE       -- 着日
    ,biz_type          VARCHAR2(4)                           -- 業務種別
    ,req_move_no       xoha.request_no%TYPE                  -- 依頼No/移動No
    ,base_cd           xoha.head_sales_branch%TYPE           -- 管轄拠点
    ,base_nm           xcav.party_short_name%TYPE            -- 管轄拠点名称
    ,delivery_to_cd    xoha.deliver_to%TYPE                  -- 配送先/入庫先
    ,delivery_to_nm    xcasv.party_site_full_name%TYPE       -- 配送先名称
    ,description       xoha.shipping_instructions%TYPE       -- 摘要
    ,conf_req          xlvv.meaning%TYPE                     -- 確認依頼
    ,de_prod_date      xola.warning_date%TYPE                -- 指定製造日
-- 2008/09/26 H.Itou Add Start T_TE080_BPO_600指摘38
    ,de_prod_date_sort xola.warning_date%TYPE                -- 指定製造日(ソート用)
-- 2008/09/26 H.Itou Add End
    ,prod_date         ilm.attribute1%TYPE                   -- 製造日
    ,best_before_date  ilm.attribute3%TYPE                   -- 賞味期限
    ,native_sign       ilm.attribute2%TYPE                   -- 固有記号
-- 2009/05/21 v1.14 H.Itou Mod Start 本番障害#1476 不足なし→不足あり(ロットNoなしレコード)の順に抽出するため、ロットNoを復活
-- 2009/03/06 v1.12 Y.Kazama Del Start 本番障害#785
    ,lot_no            xmld.lot_no%TYPE                      -- ロットNo
-- 2009/03/06 v1.12 Y.Kazama Del End   本番障害#785
-- 2009/05/21 v1.14 H.Itou Mod End
    ,lot_status        xlvv.meaning%TYPE                     -- 品質
-- 2009/03/06 v1.12 Y.Kazama Add Start 本番障害#785
    ,req_sum_qty       NUMBER                                -- 依頼数
-- 2009/03/06 v1.12 Y.Kazama Add End   本番障害#785
    ,req_qty           NUMBER                                -- ロット別数
    ,ins_qty           NUMBER                                -- 不足数
    ,reserve_order     xcav.reserve_order%TYPE               -- 引当順
    ,time_from         xoha.arrival_time_from%TYPE           -- 時間指定From
  );
  type_report_data      rec_report_data;
  TYPE list_report_data IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_param              rec_param_data ;        -- 入力パラメータ情報
  gt_report_data        list_report_data ;      -- 出力データ
  gt_xml_data_table     xml_data ;              -- XMLデータ
  gv_dept_cd            VARCHAR2(10) ;          -- 担当部署
  gv_dept_nm            VARCHAR2(14) ;          -- 担当者
--
  -- プロファイル値取得結果格納用
  gv_user_id            fnd_user.user_id%TYPE;  -- ユーザID
  gv_prod_kbn           VARCHAR2(1);            -- 商品区分
--
  /**********************************************************************************
   * Function Name    : fnc_chgdt_d
   * Description      : 日付型変換(YYYY/MM/DD形式の文字列 → 日付型)
   *                  文字列の日付(YYYY/MM/DD形式)を日付型に変換して返却
   *                  (例：2008/04/01 → 01-APR-08)
   ***********************************************************************************/
  FUNCTION fnc_chgdt_d(
    iv_date  IN  VARCHAR2  -- YYYY/MM/DD形式の日付
  )RETURN DATE
  IS
  BEGIN
    RETURN( FND_DATE.STRING_TO_DATE(iv_date, gc_date_fmt_ymd) ) ;
  END fnc_chgdt_d;
--
  /**********************************************************************************
   * Function Name    : fnc_chgdt_c
   * Description      : 日付型変換(日付型 → YYYY/MM/DD形式の文字列)
   *                  日付型を「YYYY/MM/DD形式」の文字列に変換して返却
   *                  (例：01-APR-08 → 2008/04/01 )
   ***********************************************************************************/
  FUNCTION fnc_chgdt_c(
    id_date  IN  DATE
  )RETURN VARCHAR2
  IS
  BEGIN
    RETURN( TO_CHAR(id_date, gc_date_fmt_ymd) ) ;
  END fnc_chgdt_c;
--
  /**********************************************************************************
   * Procedure Name   : prc_set_tag_data
   * Description      : タグ情報設定処理
   ***********************************************************************************/
  PROCEDURE prc_set_tag_data(
     iv_tag_name       IN  VARCHAR2                 -- タグ名
    ,iv_tag_value      IN  VARCHAR2                 -- データ
    ,iv_tag_type       IN  VARCHAR2  DEFAULT NULL   -- データ
  )
  IS
    ln_data_index  NUMBER ;    -- XMLデータのインデックス
  BEGIN
    ln_data_index := gt_xml_data_table.COUNT + 1 ;
--
    -- タグ名を設定
    gt_xml_data_table(ln_data_index).tag_name := iv_tag_name ;
--
    IF ((iv_tag_value IS NULL) AND (iv_tag_type = gc_tag_type_tag)) THEN
      -- グループタグ設定
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
    ELSE
      -- データタグ設定
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
      gt_xml_data_table(ln_data_index).tag_value := iv_tag_value;
    END IF;
  END prc_set_tag_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_set_tag_data
   * Description      : タグ情報設定処理(開始・終了タグ用)
   ***********************************************************************************/
  PROCEDURE prc_set_tag_data(
     iv_tag_name       IN  VARCHAR2  -- タグ名
  )
  IS
  BEGIN
    prc_set_tag_data(iv_tag_name, NULL, gc_tag_type_tag);
  END prc_set_tag_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 初期処理
   ***********************************************************************************/
  PROCEDURE prc_initialize(
    ov_errbuf     OUT  VARCHAR2         -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT  VARCHAR2         -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT  VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_initialize' ;  -- プログラム名
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
    -- *** ローカル・例外処理 ***
    prm_check_expt    EXCEPTION ;     -- パラメータチェック例外
    get_prof_expt     EXCEPTION ;     -- プロファイル取得例外
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
    -- パラメータチェック
    -- ====================================================
    -- 締め実施日、締め実施時間チェック
    IF ((gt_param.tighten_date IS NULL)
      AND ((gt_param.tighten_time_from IS NOT NULL) OR (gt_param.tighten_time_to IS NOT NULL))) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh, gc_msg_id_prm_chk ) ;
      RAISE prm_check_expt ;
    END IF;
--
    -- ====================================================
    -- プロファイル取得
    -- ====================================================
    -- ユーザID
    gv_user_id := FND_GLOBAL.USER_ID ;
--
    -- 職責：商品区分(セキュリティ)
    gv_prod_kbn := FND_PROFILE.VALUE(gc_prof_name_item_div) ;
    IF (gv_prod_kbn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
  EXCEPTION
    --*** パラメータチェック例外ハンドラ ***
    WHEN prm_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
    --*** プロファイル取得例外ハンドラ ***
    WHEN get_prof_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_initialize;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 帳票データ取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
    ov_errbuf      OUT   VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT   VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT   VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data' ;  -- プログラム名
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
    -- *** ローカル・カーソル ***
-- 2008/09/26 H.Itou Del Start T_S_533(PT対応)
--    CURSOR cur_data
--    IS
--      ----------------------------------------------------------------------------------
--      -- 不足分取得(出荷)
--      ----------------------------------------------------------------------------------
--      SELECT
--        ----------------------------------------------------------------------------------
--        -- ヘッダ部
--        ----------------------------------------------------------------------------------
--         xilv.distribution_block      AS  block_cd            -- ブロックコード
--        ,xlvv1.meaning                AS  block_nm            -- ブロック名称
--        ,xoha.deliver_from            AS  shipped_cd          -- 出庫元コード
--        ,xilv.description             AS  shipped_nm          -- 出庫元名
--        ----------------------------------------------------------------------------------
--        -- 明細部
--        ----------------------------------------------------------------------------------
--        ,xola.shipping_item_code      AS  item_cd             -- 品目コード
--        ,ximv.item_name               AS  item_nm             -- 品目名称
--        ,xoha.schedule_ship_date      AS  shipped_date        -- 出庫日
--        ,xoha.schedule_arrival_date   AS  arrival_date        -- 着日
--        ,TO_CHAR(gc_biz_type_nm_ship) AS  biz_type            -- 業務種別
--        ,xoha.request_no              AS  req_move_no         -- 依頼No/移動No
--        ,xoha.head_sales_branch       AS  base_cd             -- 管轄拠点
--        ,xcav.party_short_name        AS  base_nm             -- 管轄拠点名称
--        ,xoha.deliver_to              AS  delivery_to_cd      -- 配送先/入庫先
--        ,xcasv.party_site_full_name   AS  delivery_to_nm      -- 配送先名称
--        ,SUBSTRB(xoha.shipping_instructions, 1, 40)
--                                      AS  description         -- 摘要
--        ,xlvv2.meaning                AS  conf_req            -- 確認依頼
--        ,CASE
--           WHEN xola.warning_date IS NULL THEN xola.designated_production_date
--           ELSE xola.warning_date
--         END                          AS  de_prod_date        -- 指定製造日
--        ,NVL(xola.warning_date, NVL(xola.designated_production_date, TO_DATE('19000101', 'YYYYMMDD'))) 
--                                      AS  de_prod_date_sort   -- 指定製造日(ソート用) 2008/09/26 H.Itou Add T_TE080_BPO_600指摘38対応
--        ,NULL                         AS  prod_date           -- 製造日
--        ,NULL                         AS  best_before_date    -- 賞味期限
--        ,NULL                         AS  native_sign         -- 固有記号
--        ,NULL                         AS  lot_no              -- ロットNo
--        ,NULL                         AS  lot_status          -- 品質
---- 2008/09/26 H.Itou Mod Start T_TE080_BPO_600指摘37対応
----        ,TO_NUMBER(0)                 AS  req_qty             -- ロット別数
--        ,CASE 
--           WHEN ximv.conv_unit IS NULL THEN xola.quantity 
--           ELSE                            (xola.quantity / ximv.num_of_cases) 
--         END                          AS  req_qty '                 -- ロット別数 2008/09/26 H.Itou Mod T_TE080_BPO_600指摘37対応
---- 2008/09/26 H.Itou Mod End
--        ,CASE
--          WHEN ximv.conv_unit IS NULL THEN
--            (xola.quantity - NVL(xola.reserved_quantity, 0))
--          ELSE ((xola.quantity - NVL(xola.reserved_quantity, 0))
--               / TO_NUMBER(
--                   CASE
--                     WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases
--                     ELSE TO_CHAR(1)
--                   END)
--          )
--         END                          AS  ins_qty             -- 不足数
--        ,xcav.reserve_order           AS  reserve_order       -- 引当順
--        ,xoha.arrival_time_from       AS  time_from           -- 時間指定From
--      FROM
--         xxwsh_order_headers_all        xoha    -- 01:受注ヘッダアドオン
--        ,xxwsh_order_lines_all          xola    -- 02:受注明細アドオン
--        ,xxwsh_oe_transaction_types2_v  xottv   -- 03:受注タイプ情報
--        ,xxwsh_tightening_control       xtc     -- 04:出荷依頼締め管理(アドオン)
--        ,xxcmn_item_locations2_v        xilv    -- 05:OPM保管場所情報
--        ,xxcmn_cust_accounts2_v         xcav    -- 06:顧客情報(管轄拠点)
--        ,xxcmn_cust_acct_sites2_v       xcasv   -- 07:顧客サイト情報(出荷先)
--        ,xxcmn_item_mst2_v              ximv    -- 08:OPM品目情報
--        ,xxcmn_lookup_values2_v         xlvv1   -- 09:クイックコード(物流ブロック)
--        ,xxcmn_lookup_values2_v         xlvv2   -- 10:クイックコード(物流担当確認依頼区分)
--      WHERE
--        ----------------------------------------------------------------------------------
--        -- ヘッダ情報
--        ----------------------------------------------------------------------------------
--        -- 03:受注タイプ情報
--             xottv.shipping_shikyu_class  =  gc_ship_pro_kbn_s  -- 出荷支給区分:出荷依頼
--        AND  xottv.order_category_code   <>  gc_order_cate_ret  -- 受注カテゴリ:返品
--        -- 01:受注ヘッダアドオン
--        AND  xoha.order_type_id           =  xottv.transaction_type_id
--        AND  xoha.req_status             >=  gc_ship_status_close      -- ステータス:締め済み
--        AND  xoha.req_status             <>  gc_ship_status_delete     -- ステータス:取消
--        AND  xoha.latest_external_flag    =  gc_new_flg                -- 最新フラグ
--        AND  xoha.prod_class              =  gv_prod_kbn
--        AND  xoha.schedule_ship_date     >=  gt_param.shipped_date_from
--        AND  xoha.schedule_ship_date     <=  gt_param.shipped_date_to
--        -- 04:出荷依頼締め管理(アドオン)
--        AND  xoha.tightening_program_id  = xtc.concurrent_id(+)
--        AND  (gt_param.tighten_date IS NULL
--          OR  TRUNC(xtc.tightening_date)  = TRUNC(gt_param.tighten_date)
--        )
--        AND  (xtc.tightening_date IS NULL
--          OR (TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--              >= NVL(gt_param.tighten_time_from, gc_time_start)
--            AND  TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--              <= NVL(gt_param.tighten_time_to, gc_time_end)
--          )
--        )
--        -- 05:OPM保管場所情報
--        AND  xoha.deliver_from_id = xilv.inventory_location_id
--        AND  (
--              xilv.distribution_block = gt_param.block1
--          OR  xilv.distribution_block = gt_param.block2
--          OR  xilv.distribution_block = gt_param.block3
--          OR  xoha.deliver_from = gt_param.shipped_cd
--          OR  ( gt_param.block1 IS NULL
--            AND gt_param.block2 IS NULL
--            AND gt_param.block3 IS NULL
--            AND gt_param.shipped_cd IS NULL
--          )
--        )
--        -- 06:顧客情報(管轄拠点)
--        AND  xoha.head_sales_branch = xcav.party_number
--        -- 07:顧客サイト情報(出荷先)
--        AND  xoha.deliver_to_id     = xcasv.party_site_id
--        ----------------------------------------------------------------------------------
--        -- 明細情報
--        ----------------------------------------------------------------------------------
--        -- 02:受注明細アドオン
--        AND  xoha.order_header_id =  xola.order_header_id
--        AND  xola.delete_flag    <>  gc_delete_flg
--        -- 08:OPM品目情報
--        AND  (gt_param.item_cd IS NULL
--           OR xola.shipping_item_code = gt_param.item_cd
--        )
--        AND  xola.shipping_inventory_item_id = ximv.inventory_item_id
--        ----------------------------------------------------------------------------------
--        -- 不足分取得条件
--        ----------------------------------------------------------------------------------
--        AND  ((xola.quantity - xola.reserved_quantity) > 0
--           OR  xola.reserved_quantity IS NULL
--        )
--        ----------------------------------------------------------------------------------
--        -- クイックコード
--        ----------------------------------------------------------------------------------
--        -- 09:クイックコード(物流ブロック)
--        AND  xlvv1.lookup_type = gc_lookup_cd_block
--        AND  xilv.distribution_block = xlvv1.lookup_code
--        -- 10:クイックコード(物流担当確認依頼区分)
--        AND  xlvv2.lookup_type = gc_lookup_cd_conreq
--        AND  xoha.confirm_request_class = xlvv2.lookup_code
--        ----------------------------------------------------------------------------------
--        -- 適用日
--        ----------------------------------------------------------------------------------
--        -- 06:顧客情報(管轄拠点)
--        AND  xcav.start_date_active  <= xoha.schedule_ship_date
--        AND  (xcav.end_date_active IS NULL
--          OR  xcav.end_date_active  >= xoha.schedule_ship_date)
--        -- 07:顧客サイト情報(出荷先)
--        AND  xcasv.start_date_active <= xoha.schedule_ship_date
--        AND  (xcasv.end_date_active IS NULL
--          OR  xcasv.end_date_active >= xoha.schedule_ship_date)
--        -- 08:OPM品目情報
--        AND  ximv.start_date_active  <= xoha.schedule_ship_date
--        AND  (ximv.end_date_active IS NULL
--          OR  ximv.end_date_active  >= xoha.schedule_ship_date)
--      ----------------------------------------------------------------------------------
--      -- 不足無し分の取得(出荷)
--      ----------------------------------------------------------------------------------
--      UNION ALL
--      SELECT
--        ----------------------------------------------------------------------------------
--        -- ヘッダ部
--        ----------------------------------------------------------------------------------
--         xilv.distribution_block      AS  block_cd            -- ブロックコード
--        ,xlvv1.meaning                AS  block_nm            -- ブロック名称
--        ,xoha.deliver_from            AS  shipped_cd          -- 出庫元コード
--        ,xilv.description             AS  shipped_nm          -- 出庫元名
--        ----------------------------------------------------------------------------------
--        -- 明細部
--        ----------------------------------------------------------------------------------
--        ,xola.shipping_item_code      AS  item_cd             -- 品目コード
--        ,ximv.item_name               AS  item_nm             -- 品目名称
--        ,xoha.schedule_ship_date      AS  shipped_date        -- 出庫日
--        ,xoha.schedule_arrival_date   AS  arrival_date        -- 着日
--        ,TO_CHAR(gc_biz_type_nm_ship) AS  biz_type            -- 業務種別
--        ,xoha.request_no              AS  req_move_no         -- 依頼No/移動No
--        ,xoha.head_sales_branch       AS  base_cd             -- 管轄拠点
--        ,xcav.party_short_name        AS  base_nm             -- 管轄拠点名称
--        ,xoha.deliver_to              AS  delivery_to_cd      -- 配送先/入庫先
--        ,xcasv.party_site_full_name   AS  delivery_to_nm      -- 配送先名称
--        ,SUBSTRB(xoha.shipping_instructions, 1, 40) 
--                                      AS  description         -- 摘要
--        ,xlvv2.meaning                AS  conf_req            -- 確認依頼
--        ,CASE
--           WHEN xola.warning_date IS NULL THEN xola.designated_production_date
--           ELSE xola.warning_date
--         END                          AS  de_prod_date        -- 指定製造日
--        ,NVL(xola.warning_date, NVL(xola.designated_production_date, TO_DATE('19000101', 'YYYYMMDD'))) 
--                                      AS  de_prod_date_sort   -- 指定製造日(ソート用) 2008/09/26 H.Itou Add T_TE080_BPO_600指摘38対応
--        ,ilm.attribute1               AS  prod_date           -- 製造日
--        ,ilm.attribute3               AS  best_before_date    -- 賞味期限
--        ,ilm.attribute2               AS  native_sign         -- 固有記号
--        ,xmld.lot_no                  AS  lot_no              -- ロットNo
--        ,xlvv3.meaning                AS  lot_status          -- 品質
--        ,CASE
--          WHEN ximv.conv_unit IS NULL THEN xmld.actual_quantity
--          ELSE (xmld.actual_quantity / TO_NUMBER(
--                                         CASE
--                                           WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases
--                                           ELSE TO_CHAR(1)
--                                         END)
--          )
--         END                          AS  req_qty             -- ロット別数
--        ,TO_NUMBER(0)                 AS  ins_qty             -- 不足数
--        ,xcav.reserve_order           AS  reserve_order       -- 引当順
--        ,xoha.arrival_time_from       AS  time_from           -- 時間指定From
--      FROM
--        (
--          ----------------------------------------------------------------------------------
--          -- 引当済分を抽出するための不足品目の取得
--          ----------------------------------------------------------------------------------
--          SELECT
--             sub_data.shipped_cd         AS  shipped_cd    -- 出荷元保管場所(出庫元保管場所)
--            ,sub_data.item_cd            AS  item_cd       -- 出荷品目(品目)
--            ,MAX(sub_data.shipped_date)  AS  shipped_date  -- 出荷予定日(出庫予定日)
--          FROM
--            (
--              ----------------------------------------------------------------------------------
--              -- 引当済分を抽出するための不足品目の取得(出荷)
--              ----------------------------------------------------------------------------------
--              SELECT
--                 xoha.deliver_from             AS  shipped_cd    -- 出荷元保管場所
--                ,xola.shipping_item_code       AS  item_cd       -- 出荷品目
--                ,xoha.schedule_ship_date       AS  shipped_date  -- 出荷予定日
--              FROM
--                 xxwsh_order_headers_all        xoha    -- 01:受注ヘッダアドオン
--                ,xxwsh_order_lines_all          xola    -- 02:受注明細アドオン
--                ,xxwsh_oe_transaction_types2_v  xottv   -- 03:受注タイプ情報
--                ,xxwsh_tightening_control       xtc     -- 04:出荷依頼締め管理(アドオン)
--                ,xxcmn_item_locations2_v        xilv    -- 05:OPM保管場所情報
--              WHERE
--                ----------------------------------------------------------------------------------
--                -- ヘッダ情報
--                ----------------------------------------------------------------------------------
--                -- 01:受注ヘッダアドオン
--                     xoha.order_type_id       = xottv.transaction_type_id
--                AND  xoha.schedule_ship_date >= TO_DATE(gt_param.shipped_date_from)
--                AND  xoha.schedule_ship_date <= TO_DATE(gt_param.shipped_date_to)
--                AND  xoha.latest_external_flag  =  gc_new_flg    -- 最新フラグ
--                -- 04:出荷依頼締め管理(アドオン)
--                AND  xoha.tightening_program_id  = xtc.concurrent_id(+)
--                AND  (gt_param.tighten_date IS NULL
--                  OR  TRUNC(xtc.tightening_date)  = TRUNC(gt_param.tighten_date)
--                )
--                AND  (xtc.tightening_date IS NULL
--                  OR (TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--                      >= NVL(gt_param.tighten_time_from, gc_time_start)
--                    AND  TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--                      <= NVL(gt_param.tighten_time_to, gc_time_end)
--                  )
--                )
--                -- 05:OPM保管場所情報
--                AND  xoha.deliver_from_id = xilv.inventory_location_id
--                AND  (
--                      xilv.distribution_block = gt_param.block1
--                  OR  xilv.distribution_block = gt_param.block2
--                  OR  xilv.distribution_block = gt_param.block3
--                  OR  xoha.deliver_from = gt_param.shipped_cd
--                  OR  ( gt_param.block1 IS NULL
--                    AND gt_param.block2 IS NULL
--                    AND gt_param.block3 IS NULL
--                    AND gt_param.shipped_cd IS NULL
--                  )
--                )
--                ----------------------------------------------------------------------------------
--                -- 明細情報
--                ----------------------------------------------------------------------------------
--                -- 02:受注明細アドオン
--                AND  xoha.order_header_id = xola.order_header_id
--                AND  xola.delete_flag    <>  gc_delete_flg
--                -- 10:OPM品目情報
--                AND  (gt_param.item_cd IS NULL
--                   OR xola.shipping_item_code = gt_param.item_cd
--                )
--                AND  xoha.prod_class = gv_prod_kbn
--                ----------------------------------------------------------------------------------
--                -- 不足分取得条件
--                ----------------------------------------------------------------------------------
--                AND  ((xola.quantity - xola.reserved_quantity) > 0
--                   OR xola.reserved_quantity IS NULL
--                )
--              ----------------------------------------------------------------------------------
--              -- 引当済分を抽出するための不足品目の取得(移動)
--              ----------------------------------------------------------------------------------
--              UNION ALL
--              SELECT
--                 xmrih.shipped_locat_code       AS  shipped_cd   -- 出庫元保管場所
--                ,xmril.item_code                AS  item_cd      -- 品目
--                ,xmrih.schedule_ship_date       AS  shipped_date -- 出庫予定日
--              FROM
--                 xxinv_mov_req_instr_headers    xmrih     -- 01:移動依頼/指示ヘッダ（アドオン）
--                ,xxinv_mov_req_instr_lines      xmril     -- 02:移動依頼/指示明細（アドオン）
--                ,xxcmn_item_locations2_v        xilv1     -- 03:OPM保管場所情報(出庫元)
--              WHERE
--                ----------------------------------------------------------------------------------
--                -- ヘッダ情報
--                ----------------------------------------------------------------------------------
--                -- 01:移動依頼/指示ヘッダ（アドオン）
--                     xmrih.schedule_ship_date >= TO_DATE(gt_param.shipped_date_from)
--                AND  xmrih.schedule_ship_date <= TO_DATE(gt_param.shipped_date_to)
--                -- 03:OPM保管場所情報(出庫元)
--                AND  xilv1.inventory_location_id = xmrih.shipped_locat_id
--                AND  (
--                      xilv1.distribution_block = gt_param.block1
--                  OR  xilv1.distribution_block = gt_param.block2
--                  OR  xilv1.distribution_block = gt_param.block3
--                  OR  xmrih.shipped_locat_code = gt_param.shipped_cd
--                  OR  (  gt_param.block1 IS NULL
--                    AND  gt_param.block2 IS NULL
--                    AND  gt_param.block3 IS NULL
--                    AND  gt_param.shipped_cd IS NULL
--                  )
--                )
--                ----------------------------------------------------------------------------------
--                -- 明細情報
--                ----------------------------------------------------------------------------------
--                -- 02:移動依頼/指示明細（アドオン）
--                AND  xmrih.mov_hdr_id = xmril.mov_hdr_id
--                AND  xmril.delete_flg  <>  gc_delete_flg
--                AND  (gt_param.item_cd IS NULL
--                  OR  xmril.item_code = gt_param.item_cd
--                )
--                AND  xmrih.item_class = gv_prod_kbn
--                ----------------------------------------------------------------------------------
--                -- 不足分取得条件
--                ----------------------------------------------------------------------------------
--                AND  ((xmril.instruct_qty - xmril.reserved_quantity) > 0
--                  OR  xmril.reserved_quantity IS NULL
--                )
--            ) sub_data
--          GROUP BY
--             sub_data.shipped_cd
--            ,sub_data.item_cd
--        )data
--        ,xxwsh_order_headers_all        xoha    -- 01:受注ヘッダアドオン
--        ,xxwsh_order_lines_all          xola    -- 02:受注明細アドオン
--        ,xxwsh_oe_transaction_types2_v  xottv   -- 03:受注タイプ情報
--        ,xxwsh_tightening_control       xtc     -- 04:出荷依頼締め管理(アドオン)
--        ,xxcmn_item_locations2_v        xilv    -- 05:OPM保管場所情報
--        ,xxcmn_cust_accounts2_v         xcav    -- 06:顧客情報(管轄拠点)
--        ,xxcmn_cust_acct_sites2_v       xcasv   -- 07:顧客サイト情報(出荷先)
--        ,xxcmn_item_mst2_v              ximv    -- 08:OPM品目情報
--        ,xxinv_mov_lot_details          xmld    -- 09:移動ロット詳細(アドオン)
--        ,ic_lots_mst                    ilm     -- 10:OPMロットマスタ
--        ,xxcmn_lookup_values2_v         xlvv1   -- 11:クイックコード(物流ブロック)
--        ,xxcmn_lookup_values2_v         xlvv2   -- 12:クイックコード(物流担当確認依頼区分)
--        ,xxcmn_lookup_values2_v         xlvv3   -- 13:クイックコード(ロットステータス)
--      WHERE
--        ----------------------------------------------------------------------------------
--        -- 不足品目情報絞込み条件
--        ----------------------------------------------------------------------------------
--             xoha.deliver_from         =  data.shipped_cd
--        AND  xola.shipping_item_code   =  data.item_cd
--        AND  xoha.schedule_ship_date  >=  TO_DATE(gt_param.shipped_date_from)
--        AND  xoha.schedule_ship_date  <=  TO_DATE(data.shipped_date)
--        AND  (xola.quantity - xola.reserved_quantity) <= 0
--        ----------------------------------------------------------------------------------
--        -- ヘッダ情報
--        ----------------------------------------------------------------------------------
--        -- 03:受注タイプ情報
--        AND  xottv.shipping_shikyu_class  =  gc_ship_pro_kbn_s  -- 出荷支給区分:出荷依頼
--        AND  xottv.order_category_code   <>  gc_order_cate_ret  -- 受注カテゴリ:返品
--        -- 01:受注ヘッダアドオン
--        AND  xoha.order_type_id           =  xottv.transaction_type_id
--        AND  xoha.req_status             >=  gc_ship_status_close      -- ステータス:締め済み
--        AND  xoha.req_status             <>  gc_ship_status_delete     -- ステータス:取消
--        AND  xoha.latest_external_flag    =  gc_new_flg                -- 最新フラグ
--        -- 04:出荷依頼締め管理(アドオン)
--        AND  xoha.tightening_program_id  = xtc.concurrent_id(+)
--        AND  (gt_param.tighten_date IS NULL
--          OR  TRUNC(xtc.tightening_date)  = TRUNC(gt_param.tighten_date)
--        )
--        AND  (xtc.tightening_date IS NULL
--          OR (TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--              >= NVL(gt_param.tighten_time_from, gc_time_start)
--            AND  TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--              <= NVL(gt_param.tighten_time_to, gc_time_end)
--          )
--        )
--        -- 05:OPM保管場所情報
--        AND  xoha.deliver_from_id = xilv.inventory_location_id
--        -- 06:顧客情報(管轄拠点)
--        AND  xoha.head_sales_branch = xcav.party_number
--        -- 07:顧客サイト情報(出荷先)
--        AND  xoha.deliver_to_id     = xcasv.party_site_id
--        ----------------------------------------------------------------------------------
--        -- 明細情報
--        ----------------------------------------------------------------------------------
--        -- 02:受注明細アドオン
--        AND  xoha.order_header_id  =  xola.order_header_id
--        AND  xola.delete_flag     <>  gc_delete_flg
--        -- 10:OPM品目情報
--        AND  xola.shipping_inventory_item_id = ximv.inventory_item_id
--        ----------------------------------------------------------------------------------
--        -- ロット情報
--        ----------------------------------------------------------------------------------
--        -- 09:移動ロット詳細(アドオン)
--        AND  xola.order_line_id = xmld.mov_line_id
--        AND  xmld.document_type_code = gc_doc_type_ship   -- 文書タイプ:出荷依頼
--        AND  xmld.record_type_code   = gc_rec_type_shiji  -- レコードタイプ:指示
--        -- 10:OPMロットマスタ
--        AND  xmld.lot_id   =  ilm.lot_id
--        AND  xmld.item_id  =  ilm.item_id
--        ----------------------------------------------------------------------------------
--        -- クイックコード
--        ----------------------------------------------------------------------------------
--        -- 11:クイックコード(物流ブロック)
--        AND  xlvv1.lookup_type = gc_lookup_cd_block
--        AND  xilv.distribution_block = xlvv1.lookup_code
--        -- 12:クイックコード(物流担当確認依頼区分)
--        AND  xlvv2.lookup_type = gc_lookup_cd_conreq
--        AND  xoha.confirm_request_class = xlvv2.lookup_code
--        -- 13:クイックコード(ロットステータス)
--        AND  xlvv3.lookup_type = gc_lookup_cd_lot_status
--        AND  ilm.attribute23 = xlvv3.lookup_code
--        ----------------------------------------------------------------------------------
--        -- 適用日
--        ----------------------------------------------------------------------------------
--        -- 06:顧客情報(管轄拠点)
--        AND  xcav.start_date_active  <= xoha.schedule_ship_date
--        AND  (xcav.end_date_active IS NULL
--          OR  xcav.end_date_active  >= xoha.schedule_ship_date)
--        -- 07:顧客サイト情報(出荷先)
--        AND  xcasv.start_date_active <= xoha.schedule_ship_date
--        AND  (xcasv.end_date_active IS NULL
--          OR  xcasv.end_date_active >= xoha.schedule_ship_date)
--        -- 08:OPM品目情報
--        AND  ximv.start_date_active  <= xoha.schedule_ship_date
--        AND  (ximv.end_date_active IS NULL
--          OR  ximv.end_date_active  >= xoha.schedule_ship_date)
--      ----------------------------------------------------------------------------------
--      -- 不足分取得(移動)
--      ----------------------------------------------------------------------------------
--      UNION ALL
--      SELECT
--        ----------------------------------------------------------------------------------
--        -- ヘッダ情報
--        ----------------------------------------------------------------------------------
--         xilv1.distribution_block     AS  block_cd            -- ブロックコード
--        ,xlvv1.meaning                AS  block_nm            -- ブロック名称
--        ,xmrih.shipped_locat_code     AS  shipped_cd          -- 出庫元コード
--        ,xilv1.description            AS  shipped_nm          -- 出庫元名
--        ----------------------------------------------------------------------------------
--        -- 明細情報
--        ----------------------------------------------------------------------------------
--        ,xmril.item_code              AS  item_cd             -- 品目コード
--        ,ximv.item_name               AS  item_nm             -- 品目名称
--        ,xmrih.schedule_ship_date     AS  shipped_date        -- 出庫日
--        ,xmrih.schedule_arrival_date  AS  arrival_date        -- 着日
--        ,TO_CHAR(gc_biz_type_nm_move) AS  biz_type            -- 業務種別
--        ,xmrih.mov_num                AS  req_move_no         -- 依頼No/移動No
--        ,NULL                         AS  base_cd             -- 管轄拠点
--        ,NULL                         AS  base_nm             -- 管轄拠点名称
--        ,xmrih.ship_to_locat_code     AS  delivery_to_cd      -- 配送先/入庫先
--        ,xilv2.description            AS  delivery_to_nm      -- 配送先名称
--        ,SUBSTRB(xmrih.description, 1, 40) AS  description    -- 摘要
--        ,NULL                         AS  conf_req            -- 確認依頼
--        ,CASE
--          WHEN xmril.warning_date IS NULL THEN xmril.designated_production_date
--          ELSE xmril.warning_date
--         END                          AS  de_prod_date        -- 指定製造日
--        ,NVL(xmril.warning_date, NVL(xmril.designated_production_date, TO_DATE('19000101', 'YYYYMMDD'))) 
--                                      AS  de_prod_date_sort   -- 指定製造日(ソート用) 2008/09/26 H.Itou Add T_TE080_BPO_600指摘38対応
--        ,NULL                         AS  prod_date           -- 製造日
--        ,NULL                         AS  best_before_date    -- 賞味期限
--        ,NULL                         AS  native_sign         -- 固有記号
--        ,NULL                         AS  lot_no              -- ロットNo
--        ,NULL                         AS  lot_status          -- 品質
---- 2008/09/26 H.Itou Mod Start T_TE080_BPO_600指摘37対応
----        ,TO_NUMBER(0)                 AS  req_qty             -- ロット別数
--        ,CASE 
--           WHEN ximv.conv_unit IS NULL THEN xmril.instruct_qty 
--           ELSE                            (xmril.instruct_qty / ximv.num_of_cases) 
--         END                          AS  req_qty '                 -- ロット別数 2008/09/26 H.Itou Mod T_TE080_BPO_600指摘37対応
---- 2008/09/26 H.Itou Mod End
--        ,CASE
--          WHEN ximv.conv_unit IS NULL THEN
--            (xmril.instruct_qty - NVL(xmril.reserved_quantity, 0))
--          ELSE ((xmril.instruct_qty - NVL(xmril.reserved_quantity, 0))
--                / TO_NUMBER(
--                    CASE
--                      WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases
--                      ELSE TO_CHAR(1)
--                    END)
--          )
--         END                          AS  ins_qty             -- 不足数
--        ,NULL                         AS  reserve_order       -- 引当順
--        ,xmrih.arrival_time_from      AS  time_from           -- 時間指定From
--      FROM
--         xxinv_mov_req_instr_headers    xmrih     -- 01:移動依頼/指示ヘッダ（アドオン）
--        ,xxinv_mov_req_instr_lines      xmril     -- 02:移動依頼/指示明細（アドオン）
--        ,xxcmn_item_locations2_v        xilv1     -- 03:OPM保管場所情報(出庫元)
--        ,xxcmn_item_locations2_v        xilv2     -- 04:OPM保管場所情報(入庫先)
--        ,xxcmn_item_mst2_v              ximv      -- 05:OPM品目情報
--        ,xxcmn_lookup_values2_v         xlvv1     -- 06:クイックコード(物流ブロック)
--      WHERE
--        ----------------------------------------------------------------------------------
--        -- ヘッダ情報
--        ----------------------------------------------------------------------------------
--        -- 01:移動依頼/指示ヘッダ（アドオン）
--             xmrih.status               >=  gc_move_status_ordered  -- ステータス:依頼済
--        AND  xmrih.mov_type             <>  gc_mov_type_not_ship    -- 移動タイプ:積送なし
--        AND  xmrih.item_class            =  gv_prod_kbn
--        AND  xmrih.schedule_ship_date   >=  gt_param.shipped_date_from
--        AND  xmrih.schedule_ship_date   <=  gt_param.shipped_date_to
--        -- 03:OPM保管場所情報(出庫元)
--        AND  xilv1.inventory_location_id = xmrih.shipped_locat_id
--        AND  (
--              xilv1.distribution_block = gt_param.block1
--          OR  xilv1.distribution_block = gt_param.block2
--          OR  xilv1.distribution_block = gt_param.block3
--          OR  xmrih.shipped_locat_code = gt_param.shipped_cd
--          OR  (  gt_param.block1 IS NULL
--            AND  gt_param.block2 IS NULL
--            AND  gt_param.block3 IS NULL
--            AND  gt_param.shipped_cd IS NULL
--          )
--        )
--        -- 04:OPM保管場所情報(入庫先)
--        AND  xilv2.inventory_location_id = xmrih.ship_to_locat_id
--        ----------------------------------------------------------------------------------
--        -- 明細情報
--        ----------------------------------------------------------------------------------
--        -- 02:移動依頼/指示明細（アドオン）
--        AND  xmrih.mov_hdr_id   =  xmril.mov_hdr_id
--        AND  xmril.delete_flg  <>  gc_delete_flg
--        AND  (gt_param.item_cd IS NULL
--          OR  xmril.item_code = gt_param.item_cd
--        )
--        -- 05:OPM品目情報
--        AND  xmril.item_id = ximv.item_id
--        ----------------------------------------------------------------------------------
--        -- 不足分取得条件
--        ----------------------------------------------------------------------------------
--        AND  ((xmril.instruct_qty - xmril.reserved_quantity) > 0
--          OR  xmril.reserved_quantity IS NULL
--        )
--        ----------------------------------------------------------------------------------
--        -- クイックコード
--        ----------------------------------------------------------------------------------
--        -- 06:クイックコード(物流ブロック)
--        AND  xlvv1.lookup_type = gc_lookup_cd_block
--        AND  xilv1.distribution_block = xlvv1.lookup_code
--        ----------------------------------------------------------------------------------
--        -- 適用日
--        ----------------------------------------------------------------------------------
--        -- 05:OPM品目情報
--        AND  ximv.start_date_active  <= xmrih.schedule_ship_date
--        AND  (ximv.end_date_active IS NULL
--          OR  ximv.end_date_active  >= xmrih.schedule_ship_date)
--      ----------------------------------------------------------------------------------
--      -- 不足無し分の取得(移動)
--      ----------------------------------------------------------------------------------
--      UNION ALL
--      SELECT
--        ----------------------------------------------------------------------------------
--        -- ヘッダ情報
--        ----------------------------------------------------------------------------------
--         xilv1.distribution_block     AS  block_cd            -- ブロックコード
--        ,xlvv1.meaning                AS  block_nm            -- ブロック名称
--        ,xmrih.shipped_locat_code     AS  shipped_cd          -- 出庫元コード
--        ,xilv1.description            AS  shipped_nm          -- 出庫元名
--        ----------------------------------------------------------------------------------
--        -- 明細情報
--        ----------------------------------------------------------------------------------
--        ,xmril.item_code              AS  item_cd             -- 品目コード
--        ,ximv.item_name               AS  item_nm             -- 品目名称
--        ,xmrih.schedule_ship_date     AS  shipped_date        -- 出庫日
--        ,xmrih.schedule_arrival_date  AS  arrival_date        -- 着日
--        ,TO_CHAR(gc_biz_type_nm_move) AS  biz_type            -- 業務種別
--        ,xmrih.mov_num                AS  req_move_no         -- 依頼No/移動No
--        ,NULL                         AS  base_cd             -- 管轄拠点
--        ,NULL                         AS  base_nm             -- 管轄拠点名称
--        ,xmrih.ship_to_locat_code     AS  delivery_to_cd      -- 配送先/入庫先
--        ,xilv2.description            AS  delivery_to_nm      -- 配送先名称
--        ,SUBSTRB(xmrih.description, 1, 40) AS  description    -- 摘要
--        ,NULL                         AS  conf_req            -- 確認依頼
--        ,CASE
--          WHEN xmril.warning_date IS NULL THEN xmril.designated_production_date
--          ELSE xmril.warning_date
--         END                          AS  de_prod_date        -- 指定製造日
--        ,NVL(xmril.warning_date, NVL(xmril.designated_production_date, TO_DATE('19000101', 'YYYYMMDD'))) 
--                                      AS  de_prod_date_sort   -- 指定製造日(ソート用) 2008/09/26 H.Itou Add T_TE080_BPO_600指摘38対応
--        ,ilm.attribute1               AS  prod_date           -- 製造日
--        ,ilm.attribute3               AS  best_before_date    -- 賞味期限
--        ,ilm.attribute2               AS  native_sign         -- 固有記号
--        ,xmld.lot_no                  AS  lot_no              -- ロットNo
--        ,xlvv2.meaning                AS  lot_status          -- 品質
--        ,CASE
--          WHEN ximv.conv_unit IS NULL THEN xmld.actual_quantity
--          ELSE (xmld.actual_quantity / TO_NUMBER(
--                                         CASE
--                                           WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases
--                                           ELSE TO_CHAR(1)
--                                         END)
--          )
--         END                          AS  req_qty             -- ロット別数
--        ,TO_NUMBER(0)                 AS  ins_qty             -- 不足数
--        ,NULL                         AS  reserve_order       -- 引当順
--        ,xmrih.arrival_time_from      AS  time_from           -- 時間指定From
--      FROM
--        (
--          ----------------------------------------------------------------------------------
--          -- 引当済分を抽出するための不足品目の取得（出荷）
--          ----------------------------------------------------------------------------------
--          SELECT
--             sub_data.shipped_cd         AS  shipped_cd    -- 出荷元保管場所
--            ,sub_data.item_cd            AS  item_cd       -- 出荷品目
--            ,MAX(sub_data.shipped_date)  AS  shipped_date  -- 出荷予定日
--          FROM
--            (
--              ----------------------------------------------------------------------------------
--              -- 引当済分を抽出するための不足品目の取得（出荷）
--              ----------------------------------------------------------------------------------
--              SELECT
--                 xoha.deliver_from             AS  shipped_cd    -- 出荷元保管場所
--                ,xola.shipping_item_code       AS  item_cd       -- 出荷品目
--                ,xoha.schedule_ship_date       AS  shipped_date
--              FROM
--                 xxwsh_order_headers_all        xoha    -- 01:受注ヘッダアドオン
--                ,xxwsh_order_lines_all          xola    -- 02:受注明細アドオン
--                ,xxwsh_oe_transaction_types2_v  xottv   -- 03:受注タイプ情報
--                ,xxwsh_tightening_control       xtc     -- 04:出荷依頼締め管理(アドオン)
--                ,xxcmn_item_locations2_v        xilv    -- 05:OPM保管場所情報
--              WHERE
--                ----------------------------------------------------------------------------------
--                -- ヘッダ情報
--                ----------------------------------------------------------------------------------
--                -- 01:受注ヘッダアドオン
--                     xoha.order_type_id       = xottv.transaction_type_id
--                AND  xoha.schedule_ship_date >= gt_param.shipped_date_from
--                AND  xoha.schedule_ship_date <= gt_param.shipped_date_to
--                AND  xoha.latest_external_flag  =  gc_new_flg       -- 最新フラグ
--                -- 04:出荷依頼締め管理(アドオン)
--                AND  xoha.tightening_program_id  = xtc.concurrent_id(+)
--                AND  (gt_param.tighten_date IS NULL
--                  OR  TRUNC(xtc.tightening_date)  = TRUNC(gt_param.tighten_date)
--                )
--                AND  (xtc.tightening_date IS NULL
--                  OR (TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--                      >= NVL(gt_param.tighten_time_from, gc_time_start)
--                    AND  TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--                      <= NVL(gt_param.tighten_time_to, gc_time_end)
--                  )
--                )
--                -- 05:OPM保管場所情報
--                AND  xoha.deliver_from_id = xilv.inventory_location_id
--                AND  (
--                      xilv.distribution_block = gt_param.block1
--                  OR  xilv.distribution_block = gt_param.block2
--                  OR  xilv.distribution_block = gt_param.block3
--                  OR  xoha.deliver_from = gt_param.shipped_cd
--                  OR  ( gt_param.block1 IS NULL
--                    AND gt_param.block2 IS NULL
--                    AND gt_param.block3 IS NULL
--                    AND gt_param.shipped_cd IS NULL
--                  )
--                )
--                ----------------------------------------------------------------------------------
--                -- 明細情報
--                ----------------------------------------------------------------------------------
--                -- 02:受注明細アドオン
--                AND  xoha.order_header_id = xola.order_header_id
--                AND  xola.delete_flag    <>  gc_delete_flg
--                -- 10:OPM品目情報
--                AND  (gt_param.item_cd IS NULL
--                   OR xola.shipping_item_code = gt_param.item_cd
--                )
--                AND  xoha.prod_class = gv_prod_kbn
--                ----------------------------------------------------------------------------------
--                -- 不足分取得条件
--                ----------------------------------------------------------------------------------
--                AND  ((xola.quantity - xola.reserved_quantity) > 0
--                   OR xola.reserved_quantity IS NULL
--                )
--                ----------------------------------------------------------------------------------
--                -- 適用日
--                ----------------------------------------------------------------------------------
--                -- 05:OPM保管場所情報
--                AND  xilv.date_from <= xoha.schedule_ship_date
--                AND  (xilv.date_to IS NULL
--                  OR  xilv.date_to >= xoha.schedule_ship_date)
--              ----------------------------------------------------------------------------------
--              -- 引当済分を抽出するための不足品目の取得(移動)
--              ----------------------------------------------------------------------------------
--              UNION ALL
--              SELECT
--                 xmrih.shipped_locat_code       AS  shipped_cd   -- 出庫元保管場所
--                ,xmril.item_code                AS  item_cd      -- 品目
--                ,xmrih.schedule_ship_date       AS  shipped_date -- 出庫予定日
--              FROM
--                 xxinv_mov_req_instr_headers    xmrih     -- 01:移動依頼/指示ヘッダ（アドオン）
--                ,xxinv_mov_req_instr_lines      xmril     -- 02:移動依頼/指示明細（アドオン）
--                ,xxcmn_item_locations2_v        xilv1     -- 03:OPM保管場所情報(出庫元)
--              WHERE
--                ----------------------------------------------------------------------------------
--                -- ヘッダ情報
--                ----------------------------------------------------------------------------------
--                -- 01:移動依頼/指示ヘッダ（アドオン）
--                     xmrih.schedule_ship_date >= gt_param.shipped_date_from
--                AND  xmrih.schedule_ship_date <= gt_param.shipped_date_to
--                -- 03:OPM保管場所情報(出庫元)
--                AND  xilv1.inventory_location_id = xmrih.shipped_locat_id
--                AND  (
--                      xilv1.distribution_block = gt_param.block1
--                  OR  xilv1.distribution_block = gt_param.block2
--                  OR  xilv1.distribution_block = gt_param.block3
--                  OR  xmrih.shipped_locat_code = gt_param.shipped_cd
--                  OR  (  gt_param.block1 IS NULL
--                    AND  gt_param.block2 IS NULL
--                    AND  gt_param.block3 IS NULL
--                    AND  gt_param.shipped_cd IS NULL
--                  )
--                )
--                ----------------------------------------------------------------------------------
--                -- 明細情報
--                ----------------------------------------------------------------------------------
--                -- 02:移動依頼/指示明細（アドオン）
--                AND  xmrih.mov_hdr_id = xmril.mov_hdr_id
--                AND  xmril.delete_flg  <>  gc_delete_flg
--                AND  (gt_param.item_cd IS NULL
--                  OR  xmril.item_code = gt_param.item_cd
--                )
--                AND  xmrih.item_class = gv_prod_kbn
--                ----------------------------------------------------------------------------------
--                -- 不足分取得条件
--                ----------------------------------------------------------------------------------
--                AND  ((xmril.instruct_qty - xmril.reserved_quantity) > 0
--                  OR  xmril.reserved_quantity IS NULL
--                )
--            ) sub_data
--          GROUP BY
--             sub_data.shipped_cd
--            ,sub_data.item_cd
--        ) data
--        ,xxinv_mov_req_instr_headers    xmrih     -- 01:移動依頼/指示ヘッダ（アドオン）
--        ,xxinv_mov_req_instr_lines      xmril     -- 02:移動依頼/指示明細（アドオン）
--        ,xxcmn_item_locations2_v        xilv1     -- 03:OPM保管場所情報(出庫元)
--        ,xxcmn_item_locations2_v        xilv2     -- 04:OPM保管場所情報(入庫先)
--        ,xxcmn_item_mst2_v              ximv      -- 05:OPM品目情報
--        ,xxinv_mov_lot_details          xmld      -- 06:移動ロット詳細(アドオン)
--        ,ic_lots_mst                    ilm       -- 07:OPMロットマスタ
--        ,xxcmn_lookup_values2_v         xlvv1     -- 08:クイックコード(物流ブロック)
--        ,xxcmn_lookup_values2_v         xlvv2     -- 09:クイックコード(ロットステータス)
--      WHERE
--        ----------------------------------------------------------------------------------
--        -- 不足品目情報絞込み条件
--        ----------------------------------------------------------------------------------
--             xmrih.shipped_locat_code   =  data.shipped_cd
--        AND  xmril.item_code            =  data.item_cd
--        AND  xmrih.schedule_ship_date  >=  gt_param.shipped_date_from
--        AND  xmrih.schedule_ship_date  <=  data.shipped_date
--        AND  (xmril.instruct_qty - xmril.reserved_quantity) <= 0
--        ----------------------------------------------------------------------------------
--        -- ヘッダ情報
--        ----------------------------------------------------------------------------------
--        -- 01:移動依頼/指示ヘッダ（アドオン）
--        AND  xmrih.status    >=  gc_move_status_ordered  -- ステータス:依頼済
--        AND  xmrih.mov_type  <>  gc_mov_type_not_ship    -- 移動タイプ:積送なし
--        -- 03:OPM保管場所情報(出庫元)
--        AND  xilv1.inventory_location_id = xmrih.shipped_locat_id
--        -- 04:OPM保管場所情報(入庫先)
--        AND  xilv2.inventory_location_id = xmrih.ship_to_locat_id
--        ----------------------------------------------------------------------------------
--        -- 明細情報
--        ----------------------------------------------------------------------------------
--        -- 02:移動依頼/指示明細（アドオン）
--        AND  xmrih.mov_hdr_id  =  xmril.mov_hdr_id
--        AND  xmril.delete_flg  <>  gc_delete_flg
--        -- 05:OPM品目情報
--        AND  xmril.item_id = ximv.item_id
--        ----------------------------------------------------------------------------------
--        -- ロット情報
--        ----------------------------------------------------------------------------------
--        -- 06:移動ロット詳細(アドオン)
--        AND  xmril.mov_line_id =  xmld.mov_line_id
--        AND  xmril.item_id     =  xmld.item_id
--        AND  xmld.document_type_code = gc_doc_type_move   -- 文書タイプ:移動
--        AND  xmld.record_type_code   = gc_rec_type_shiji  -- レコードタイプ:指示
--        -- 07:OPMロットマスタ
--        AND  xmld.lot_id   =  ilm.lot_id
--        AND  xmld.item_id  =  ilm.item_id
--        ----------------------------------------------------------------------------------
--        -- クイックコード
--        ----------------------------------------------------------------------------------
--        -- 08:クイックコード(物流ブロック)
--        AND  xlvv1.lookup_type = gc_lookup_cd_block
--        AND  xilv1.distribution_block = xlvv1.lookup_code
--        -- 09:クイックコード(ロットステータス)
--        AND  xlvv2.lookup_type = gc_lookup_cd_lot_status
--        AND  ilm.attribute23 = xlvv2.lookup_code
--        ----------------------------------------------------------------------------------
--        -- 適用日
--        ----------------------------------------------------------------------------------
--        -- 05:OPM品目情報
--        AND  ximv.start_date_active  <= xmrih.schedule_ship_date
--        AND  (ximv.end_date_active IS NULL
--          OR  ximv.end_date_active  >= xmrih.schedule_ship_date)
--      ORDER BY
--         block_cd       ASC      -- 01:ブロック
--        ,shipped_cd     ASC      -- 02:出庫元
--        ,item_cd        ASC      -- 03:品目
--        ,shipped_date   ASC      -- 04:出庫日
--        ,arrival_date   ASC      -- 05:着日
----        ,de_prod_date   DESC     -- 06:指定製造日
--        ,de_prod_date_sort   DESC     -- 06:指定製造日 2008/09/26 H.Itou Add T_TE080_BPO_600指摘38対応
--        ,reserve_order  ASC      -- 07:引当順
--        ,base_cd        ASC      -- 08:管轄拠点
--        ,time_from      ASC      -- 09:時間指定From
--        ,req_move_no    ASC      -- 10:依頼No/移動No
--        ,lot_no         ASC      -- 11:ロットNo
--      ;
-- 2008/09/26 H.Itou Del End T_S_533(PT対応)
-- 2008/09/26 H.Itou Add Start T_S_533(PT対応)
    -- ===============================
    -- 定数宣言
    -- ===============================
    cv_union_all                   CONSTANT VARCHAR2(32767) := ' UNION ALL ';
--
    -- ===============================
    -- 型宣言
    -- ===============================
    TYPE ref_cursor                IS REF CURSOR ; -- カーソル型
--
    -- ===============================
    -- 変数宣言
    -- ===============================
    -- 動的SQL用変数
    lv_sql_wsh_short_stock         VARCHAR2(32767); -- 不足分取得(出荷)のSQL
    lv_sql_wsh_stock               VARCHAR2(32767); -- 不足無し分の取得(出荷)のSQL
    lv_sql_inv_short_stock         VARCHAR2(32767); -- 不足分取得(移動)のSQL
    lv_sql_inv_stock               VARCHAR2(32767); -- 不足無し分の取得(移動)のSQL
    lv_sql_item_short_stock        VARCHAR2(32767); -- 引当済分を抽出するための不足品目取得のSQL
    lv_where_block_or_deliver_from VARCHAR2(32767); -- 動的条件：物流ブロック・出庫元条件
    lv_where_tightening_date       VARCHAR2(32767); -- 動的条件：締め実施日条件
    lv_where_item_no               VARCHAR2(32767); -- 動的条件：品目条件
    lv_sql                         VARCHAR2(32767); -- 全SQL
    lv_order_by                    VARCHAR2(32767); -- ORDER BY
--
    cur_data                       ref_cursor ;    -- カーソル
--
-- 2008/09/26 H.Itou Add End T_S_533(PT対応)
-- 2009/01/14 v1.8 ADD START
--
    -- 帳票データ用変数
    lt_report_data       list_report_data ;                                 -- 出力データ（ワーク）
    lv_block_cd          xilv.distribution_block%TYPE DEFAULT NULL ;        -- 前回レコード格納用（ブロックコード）
    lv_tmp_shipped_cd    type_report_data.shipped_cd%TYPE DEFAULT NULL ;    -- 前回レコード格納用（出庫元コード）
    lv_tmp_item_cd       type_report_data.item_cd%TYPE DEFAULT NULL ;       -- 前回レコード格納用（品目コード）
    ln_report_data_fr    NUMBER DEFAULT 0;                                  -- 元帳票データの格納用番号（自）
    ln_report_data_to    NUMBER DEFAULT 0;                                  -- 元帳票データの格納用番号（至）
    ln_ins_qty           NUMBER DEFAULT 0;                                  -- 不足数の集計値
    ln_report_data_cnt   NUMBER DEFAULT 0;                                  -- 出力データ（ワーク）用配列カウンタ
-- 2009/01/14 v1.8 ADD END
---- 2009/01/20 v1.9 ADD START
--    lv_req_move_no       xoha.request_no%TYPE DEFAULT NULL ;                -- 依頼No/移動No
---- 2009/01/20 v1.9 ADD END
-- 2009/01/21 v1.10 ADD START
    lv_block_cd_null          xilv.distribution_block%TYPE DEFAULT NULL ;        -- 空白項目作成用（ブロックコード）
    lv_tmp_shipped_cd_null    type_report_data.shipped_cd%TYPE DEFAULT NULL ;    -- 空白項目作成用（出庫元コード）
    lv_tmp_item_cd_null       type_report_data.item_cd%TYPE DEFAULT NULL ;       -- 空白項目作成用（品目コード）
    lv_req_move_no_null       xoha.request_no%TYPE DEFAULT NULL ;                -- 空白項目作成用（依頼No/移動No）
-- 2009/01/21 v1.10 ADD END
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
    -- 担当者情報取得
    -- ====================================================
    -- 担当部署
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept(gv_user_id), 1, 10) ;
    -- 担当者
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(gv_user_id), 1, 14) ;
--
-- 2008/09/26 H.Itou Del START T_S_533(PT対応)
--    -- ====================================================
--    -- 帳票データ取得
--    -- ====================================================
--    OPEN cur_data ;
--    FETCH cur_data BULK COLLECT INTO gt_report_data ;
--    CLOSE cur_data ;
-- 2008/09/26 H.Itou Del END T_S_533(PT対応)
--
-- 2008/09/26 H.Itou Add START T_S_533(PT対応)
    -- ========================
    -- 締め実施日条件設定
    -- ========================
    -- 締め実施日に指定ありの場合
    IF (gt_param.tighten_date IS NOT NULL) THEN
     lv_where_tightening_date := 
        ' AND  TRUNC(xtc.tightening_date)  = TRUNC(:tighten_date) ';
    --
    -- 締め実施日に指定なしの場合
    ELSE
     lv_where_tightening_date := 
        ' AND  :tighten_date IS NULL ';
    END IF;
--
    -- ========================
    -- 品目条件設定
    -- ========================
    -- 品目に指定ありの場合
    IF (gt_param.item_cd IS NOT NULL) THEN
     lv_where_item_no := 
        ' AND ximv.item_no = :item_cd ';
--
    -- 品目に指定なしの場合
    ELSE
     lv_where_item_no := 
        ' AND  :item_cd IS NULL ';
    END IF;
--
    -- ===============================
    -- 物流ブロック・出庫元条件設定
    -- ==============================
    -- 出庫元・物流ブロック1・2・3いづれかに指定がある場合
    IF  ((gt_param.shipped_cd IS NOT NULL) 
      OR (gt_param.block1     IS NOT NULL)
      OR (gt_param.block2     IS NOT NULL)
      OR (gt_param.block3     IS NOT NULL)) THEN
--
--2009.05.18 D.Sugahara v1.13 Mod start --
--      lv_where_block_or_deliver_from := 
--         ' AND ((xilv.segment1           = :shipped_cd) '
--      || '  OR  (xilv.distribution_block = :block1) '
--      || '  OR  (xilv.distribution_block = :block2) '
--      || '  OR  (xilv.distribution_block = :block3)) '
--      ;
       --①出庫元倉庫だけに指定がある場合、
      IF  ((gt_param.shipped_cd IS NOT NULL) 
        AND (gt_param.block1     IS NULL)
        AND (gt_param.block2     IS NULL)
        AND (gt_param.block3     IS NULL)) THEN
        lv_where_block_or_deliver_from := 
           ' AND xilv.segment1 = :shipped_cd '
        || ' AND :block1 IS NULL '
        || ' AND :block2 IS NULL '
        || ' AND :block3 IS NULL '
        ;
      ELSE
        --②①以外の場合
        lv_where_block_or_deliver_from := 
           ' AND ((xilv.segment1           = :shipped_cd) '
        || '  OR  (xilv.distribution_block = :block1) '
        || '  OR  (xilv.distribution_block = :block2) '
        || '  OR  (xilv.distribution_block = :block3)) '
        ;
      END IF;
--2009.05.18 D.Sugahara v1.13 Mod End --
--
    -- 出庫元・物流ブロック1・2・3すべて指定なしの場合
    ELSE
--
      lv_where_block_or_deliver_from := 
         ' AND :shipped_cd IS NULL '
      || ' AND :block1 IS NULL '
      || ' AND :block2 IS NULL '
      || ' AND :block3 IS NULL '
      ;
    END IF;
--
    -- ===========================================================================================
    -- 引当済分を抽出するための不足品目の取得(不足無し分(出荷),不足無し分(移動)のSQLのサブクエリ
    -- ===========================================================================================
    lv_sql_item_short_stock :=
         ----------------------------------------------------------------------------------
         -- 引当済分を抽出するための不足品目の取得
         ----------------------------------------------------------------------------------
       ' SELECT '
    || '   sub_data.shipped_cd         AS  shipped_cd '   -- 出荷元保管場所(出庫元保管場所)
    || '  ,sub_data.item_cd            AS  item_cd '      -- 出荷品目(品目)
    || '  ,MAX(sub_data.shipped_date)  AS  shipped_date ' -- 出荷予定日(出庫予定日)
    || ' FROM '
    || '  ( '
           ----------------------------------------------------------------------------------
           -- 引当済分を抽出するための不足品目の取得(出荷)
           ----------------------------------------------------------------------------------
    || '   SELECT '
-- 2012/03/30 K.Nakamura Mod Start E_本稼動_09296
---- 2008/12/10 Miyata Add Start 本番#637 パフォーマンス改善
--    || '/*+ INDEX ( xtc xxwsh_tico_n02 ) INDEX ( xottv oe_transaction_types_all_u1 ) INDEX ( xilv mtl_item_locations_u1 ) */'
---- 2008/12/10 Miyata Add End 本番#637
    || '/*+ INDEX ( xtc       xxwsh_tico_n02 )
            INDEX ( xottv     oe_transaction_types_all_u1 )
            INDEX ( xilv      mtl_item_locations_u1 )
            INDEX ( ximv.ximb xxcmn_item_mst_b_pk )
            NO_INDEX ( ximv.ximb xxcmn_imb_n01 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n02 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n03 ) */'
-- 2012/03/30 K.Nakamura Mod End E_本稼動_09296
    || '     xoha.deliver_from             AS  shipped_cd '   -- 出荷元保管場所
    || '    ,xola.shipping_item_code       AS  item_cd '      -- 出荷品目
    || '    ,xoha.schedule_ship_date       AS  shipped_date ' -- 出荷予定日
    || '   FROM '
    || '     xxwsh_order_headers_all        xoha '   -- 01:受注ヘッダアドオン
    || '    ,xxwsh_order_lines_all          xola '   -- 02:受注明細アドオン
    || '    ,xxwsh_oe_transaction_types2_v  xottv '  -- 03:受注タイプ情報
    || '    ,xxwsh_tightening_control       xtc '    -- 04:出荷依頼締め管理(アドオン)
    || '    ,xxcmn_item_locations2_v        xilv '   -- 05:OPM保管場所情報
    || '    ,xxcmn_item_mst_v               ximv '   -- 06:OPM品目情報
    || '   WHERE '
           ----------------------------------------------------------------------------------
           -- ヘッダ情報
           ----------------------------------------------------------------------------------
           -- 01:受注ヘッダアドオン
    || '        xoha.order_type_id       = xottv.transaction_type_id '
    || '   AND  xoha.schedule_ship_date >= TO_DATE(:shipped_date_from) '
    || '   AND  xoha.schedule_ship_date <= TO_DATE(:shipped_date_to) '
    || '   AND  xoha.latest_external_flag  = ''' || gc_new_flg || ''' '   -- 最新フラグ
-- 2008/12/10 H.Itou Add Start
    || '   AND  xoha.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- 通知ステータスが確定通知済でないもの
-- 2008/12/10 H.Itou Add End
           -- 04:出荷依頼締め管理(アドオン)
    || '   AND  xoha.tightening_program_id  = xtc.concurrent_id(+) '
    || '   AND   ((xtc.tightening_date IS NULL) '
    || '     OR   ((TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  >= :tighten_time_from) '
    || '       AND (TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  <= :tighten_time_to ))) '
           -- 05:OPM保管場所情報
    || '   AND  xoha.deliver_from_id = xilv.inventory_location_id '
           ----------------------------------------------------------------------------------
           -- 明細情報
           ----------------------------------------------------------------------------------
           -- 02:受注明細アドオン
    || '   AND  xoha.order_header_id = xola.order_header_id '
    || '   AND  xola.delete_flag    <> ''' || gc_delete_flg || ''' '
           -- 06:OPM品目情報
    || '   AND  xola.shipping_inventory_item_id = ximv.inventory_item_id '
    || '   AND  xoha.prod_class = ''' || gv_prod_kbn || ''' '
           ----------------------------------------------------------------------------------
           -- 不足分取得条件
           ----------------------------------------------------------------------------------
    || '   AND (((xola.quantity - xola.reserved_quantity) > 0) '
    || '     OR  (xola.reserved_quantity IS NULL)) '
           ----------------------------------------------------------------------------------
           -- 適用日条件
           ----------------------------------------------------------------------------------
           -- 04:出荷依頼締め管理(アドオン)
    || '   AND  xottv.start_date_active <= xoha.schedule_ship_date '
    || '   AND  ((xottv.end_date_active IS NULL) '
    || '     OR  (xottv.end_date_active >= xoha.schedule_ship_date)) '
           -- 05:OPM保管場所
    || '   AND  xilv.date_from <= xoha.schedule_ship_date '
    || '   AND  ((xilv.date_to IS NULL) '
    || '     OR  (xilv.date_to >= xoha.schedule_ship_date)) '
           ----------------------------------------------------------------------------------
           -- 動的条件
           ----------------------------------------------------------------------------------
    ||     lv_where_tightening_date       -- 締め実施日条件
    ||     lv_where_item_no               -- 品目条件
    ||     lv_where_block_or_deliver_from -- 物流ブロック・出庫元条件
           ----------------------------------------------------------------------------------
           -- 引当済分を抽出するための不足品目の取得(移動)
           ----------------------------------------------------------------------------------
    || '   UNION ALL '
    || '   SELECT '
-- 2012/03/30 K.Nakamura Mod Start E_本稼動_09296
---- 2008/12/10 Miyata Add Start 本番#637 パフォーマンス改善
--    || '/*+ INDEX ( xilv mtl_item_locations_u1 ) */'
---- 2008/12/10 Miyata Add End 本番#637
    || '/*+ INDEX ( xilv      mtl_item_locations_u1 )
            INDEX ( ximv.ximb xxcmn_item_mst_b_pk )
            NO_INDEX ( ximv.ximb xxcmn_imb_n01 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n02 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n03 ) */'
-- 2012/03/30 K.Nakamura Mod End E_本稼動_09296
    || '     xmrih.shipped_locat_code       AS  shipped_cd '  -- 出庫元保管場所
    || '    ,xmril.item_code                AS  item_cd '     -- 品目
    || '    ,xmrih.schedule_ship_date       AS  shipped_date '-- 出庫予定日
    || '   FROM '
    || '     xxinv_mov_req_instr_headers    xmrih '    -- 01:移動依頼/指示ヘッダ（アドオン）
    || '    ,xxinv_mov_req_instr_lines      xmril '    -- 02:移動依頼/指示明細（アドオン）
    || '    ,xxcmn_item_locations2_v        xilv  '    -- 03:OPM保管場所情報(出庫元)
    ||  '   ,xxcmn_item_mst_v               ximv  '    -- 04:OPM品目情報
    || '   WHERE '
           ----------------------------------------------------------------------------------
           -- ヘッダ情報
           ----------------------------------------------------------------------------------
           -- 01:移動依頼/指示ヘッダ（アドオン）
    || '        xmrih.schedule_ship_date >= TO_DATE(:shipped_date_from) '
    || '   AND  xmrih.schedule_ship_date <= TO_DATE(:shipped_date_to) '
-- 2009/01/07 v1.7 UPDATE START
/*
-- 2008/12/10 H.Itou Add Start
    || '   AND  xmrih.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- 通知ステータスが確定通知済でないもの
-- 2008/12/10 H.Itou Add End
*/
    || '   AND  xmrih.notif_status IN ( ''' || gc_notif_status_mt || ''',''' || gc_notif_status_sty || ''') '   -- 通知ステータスが確定通知済でないもの
-- 2009/01/07 v1.7 UPDATE END
           -- 03:OPM保管場所情報(出庫元)
    || '   AND  xilv.inventory_location_id = xmrih.shipped_locat_id '
           ----------------------------------------------------------------------------------
           -- 明細情報
           ----------------------------------------------------------------------------------
           -- 02:移動依頼/指示明細（アドオン）
    || '   AND  xmrih.mov_hdr_id = xmril.mov_hdr_id '
    || '   AND  xmril.delete_flg  <> ''' || gc_delete_flg || ''' '
    || '   AND  xmrih.item_class   = ''' || gv_prod_kbn || ''' '
           -- 04:OPM品目情報
    || '   AND  xmril.item_id = ximv.item_id '
           ----------------------------------------------------------------------------------
           -- 不足分取得条件
           ----------------------------------------------------------------------------------
    || '   AND (((xmril.instruct_qty - xmril.reserved_quantity) > 0) '
    || '     OR  (xmril.reserved_quantity IS NULL)) '
           ----------------------------------------------------------------------------------
           -- 適用日条件
           ----------------------------------------------------------------------------------
           -- 04:OPM保管場所
    || '   AND  xilv.date_from <= xmrih.schedule_ship_date '
    || '   AND  ((xilv.date_to IS NULL) '
    || '     OR  (xilv.date_to >= xmrih.schedule_ship_date)) '
           ----------------------------------------------------------------------------------
           -- 動的条件
           ----------------------------------------------------------------------------------
    ||     lv_where_item_no               -- 品目条件
    ||     lv_where_block_or_deliver_from -- 物流ブロック・出庫元条件
    || '  ) sub_data '
    || ' GROUP BY '
    || '   sub_data.shipped_cd '
    || '  ,sub_data.item_cd '
    ;
--
    -- ======================================
    -- 不足分取得(出荷)SQL作成
    -- ======================================
    lv_sql_wsh_short_stock :=
       ' SELECT '
-- 2012/03/30 K.Nakamura Mod Start E_本稼動_09296
---- 2008/12/10 Miyata Add Start 本番#637 パフォーマンス改善
--    || '/*+ INDEX ( xtc xxwsh_tico_n02 ) INDEX ( xottv oe_transaction_types_all_u1 ) INDEX ( xilv mtl_item_locations_u1 ) */'
---- 2008/12/10 Miyata Add End 本番#637
    || '/*+ INDEX ( xtc       xxwsh_tico_n02 )
            INDEX ( xottv     oe_transaction_types_all_u1 )
            INDEX ( xilv      mtl_item_locations_u1 )
            INDEX ( ximv.ximb xxcmn_item_mst_b_pk )
            NO_INDEX ( ximv.ximb xxcmn_imb_n01 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n02 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n03 ) */'
-- 2012/03/30 K.Nakamura Mod End E_本稼動_09296
         ----------------------------------------------------------------------------------
         -- ヘッダ部
         ----------------------------------------------------------------------------------
    || '   xilv.distribution_block      AS  block_cd '                -- ブロックコード
    || '  ,xlvv1.meaning                AS  block_nm '                -- ブロック名称
    || '  ,xoha.deliver_from            AS  shipped_cd '              -- 出庫元コード
    || '  ,xilv.description             AS  shipped_nm '              -- 出庫元名
         ----------------------------------------------------------------------------------
         -- 明細部
         ----------------------------------------------------------------------------------
    || '  ,xola.shipping_item_code      AS  item_cd '                 -- 品目コード
    || '  ,ximv.item_name               AS  item_nm '                 -- 品目名称
    || '  ,xoha.schedule_ship_date      AS  shipped_date '            -- 出庫日
    || '  ,xoha.schedule_arrival_date   AS  arrival_date '            -- 着日
    || '  ,TO_CHAR( ''' || gc_biz_type_nm_ship || ''') AS  biz_type ' -- 業務種別
    || '  ,xoha.request_no              AS  req_move_no '             -- 依頼No/移動No
    || '  ,xoha.head_sales_branch       AS  base_cd '                 -- 管轄拠点
    || '  ,xcav.party_short_name        AS  base_nm '                 -- 管轄拠点名称
    || '  ,xoha.deliver_to              AS  delivery_to_cd '          -- 配送先/入庫先
    || '  ,xcasv.party_site_full_name   AS  delivery_to_nm '          -- 配送先名称
    || '  ,SUBSTRB(xoha.shipping_instructions, 1, 40) '
    || '                                AS  description '             -- 摘要
    || '  ,xlvv2.meaning                AS  conf_req '                -- 確認依頼
    || '  ,CASE '
    || '     WHEN xola.warning_date IS NULL THEN xola.designated_production_date '
    || '     ELSE xola.warning_date '
    || '   END                          AS  de_prod_date '            -- 指定製造日
-- 2009/01/27 v1.11 MOD START
--    || '  ,NVL(xola.warning_date, NVL(xola.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD''))) '
    || '  ,NVL(xola.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD'')) '
-- 2009/01/27 v1.11 MOD END
    || '                                AS  de_prod_date_sort '       -- 指定製造日(ソート用) 2008/09/26 H.Itou Add T_TE080_BPO_600指摘38対応
    || '  ,NULL                         AS  prod_date '               -- 製造日
    || '  ,NULL                         AS  best_before_date '        -- 賞味期限
    || '  ,NULL                         AS  native_sign '             -- 固有記号
-- 2009/05/21 v1.14 H.Itou Mod Start 本番障害#1476 不足なし→不足あり(ロットNoなしレコード)の順に抽出するため、ロットNoを復活
-- 2009/03/06 v1.12 Y.Kazama Del Start 本番障害#785
    || '  ,NULL                         AS  lot_no '                  -- ロットNo
-- 2009/03/06 v1.12 Y.Kazama Del End   本番障害#785
-- 2009/05/21 v1.14 H.Itou Mod End
    || '  ,NULL                         AS  lot_status '              -- 品質
-- 2009/03/06 v1.12 Y.Kazama Add Start 本番障害#785
    || '  ,CASE '
    || '     WHEN ximv.conv_unit IS NULL THEN '
    || '       xola.quantity '
    || '     ELSE (xola.quantity '
    || '            / TO_NUMBER( '
    || '                CASE  '
    || '                  WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                  ELSE TO_CHAR(1) '
    || '                END)) '
    || '   END                          AS  req_sum_qty '             -- 依頼数
-- 2009/03/06 v1.12 Y.Kazama Add End   本番障害#785
-- 2008/10/03 H.Itou Mod Start T_TE080_BPO_600指摘37 在庫不足の場合、ロット別数には不足数を表示
--    || '  ,CASE '
--    || '     WHEN ximv.conv_unit IS NULL THEN xola.quantity '
--    || '     ELSE                            (xola.quantity / ximv.num_of_cases) '
    || '  ,CASE '
    || '     WHEN ximv.conv_unit IS NULL THEN '
    || '       (xola.quantity - NVL(xola.reserved_quantity, 0)) '
    || '     ELSE ((xola.quantity - NVL(xola.reserved_quantity, 0)) '
    || '            / TO_NUMBER( '
    || '                CASE  '
    || '                  WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                  ELSE TO_CHAR(1) '
    || '                END)) '
-- 2008/10/03 H.Itou Mod End
    || '   END                          AS  req_qty '                 -- ロット別数
    || '  ,CASE '
    || '     WHEN ximv.conv_unit IS NULL THEN '
    || '       (xola.quantity - NVL(xola.reserved_quantity, 0)) '
    || '     ELSE ((xola.quantity - NVL(xola.reserved_quantity, 0)) '
    || '            / TO_NUMBER( '
    || '                CASE  '
    || '                  WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                  ELSE TO_CHAR(1) '
    || '                END)) '
    || '   END                          AS  ins_qty '                 -- 不足数
    || '  ,xcav.reserve_order           AS  reserve_order '           -- 引当順
    || '  ,xoha.arrival_time_from       AS  time_from '               -- 時間指定From
    || ' FROM '
    || '   xxwsh_order_headers_all        xoha   ' -- 01:受注ヘッダアドオン
    || '  ,xxwsh_order_lines_all          xola   ' -- 02:受注明細アドオン
    || '  ,xxwsh_oe_transaction_types2_v  xottv  ' -- 03:受注タイプ情報
    || '  ,xxwsh_tightening_control       xtc    ' -- 04:出荷依頼締め管理(アドオン)
    || '  ,xxcmn_item_locations2_v        xilv   ' -- 05:OPM保管場所情報
    || '  ,xxcmn_cust_accounts2_v         xcav   ' -- 06:顧客情報(管轄拠点)
    || '  ,xxcmn_cust_acct_sites2_v       xcasv  ' -- 07:顧客サイト情報(出荷先)
    || '  ,xxcmn_item_mst2_v              ximv   ' -- 08:OPM品目情報
    || '  ,xxcmn_lookup_values2_v         xlvv1  ' -- 09:クイックコード(物流ブロック)
    || '  ,xxcmn_lookup_values2_v         xlvv2  ' -- 10:クイックコード(物流担当確認依頼区分)
    || ' WHERE '
         ----------------------------------------------------------------------------------
         -- ヘッダ情報
         ----------------------------------------------------------------------------------
         -- 03:受注タイプ情報
    || '      xottv.shipping_shikyu_class  =  ''' || gc_ship_pro_kbn_s || ''' ' -- 出荷支給区分:出荷依頼
    || ' AND  xottv.order_category_code   <>  ''' || gc_order_cate_ret || ''' ' -- 受注カテゴリ:返品
         -- 01:受注ヘッダアドオン
    || ' AND  xoha.order_type_id           =  xottv.transaction_type_id '
-- 2009/01/07 v1.7 UPDATE START
--    || ' AND  xoha.req_status             >=  ''' || gc_ship_status_close  || ''' '      -- ステータス:締め済み
--    || ' AND  xoha.req_status             <>  ''' || gc_ship_status_delete || ''' '      -- ステータス:取消
    || ' AND  xoha.req_status IN ( ''' || gc_ship_status_close || ''',''' || gc_ship_status_confirm || ''') ' -- ステータス:締め済み
-- 2009/01/07 v1.7 UPDATE END
    || ' AND  xoha.latest_external_flag    =  ''' || gc_new_flg  || ''' '                -- 最新フラグ
    || ' AND  xoha.prod_class              =  ''' || gv_prod_kbn || ''' '
    || ' AND  xoha.schedule_ship_date     >=  :shipped_date_from '
    || ' AND  xoha.schedule_ship_date     <=  :shipped_date_to '
-- 2008/12/10 H.Itou Add Start
    || ' AND  xoha.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- 通知ステータスが確定通知済でないもの
-- 2008/12/10 H.Itou Add End
         -- 04:出荷依頼締め管理(アドオン)
    || ' AND  xoha.tightening_program_id  = xtc.concurrent_id(+) '
    || ' AND   ((xtc.tightening_date IS NULL) '
    || '   OR   ((TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  >= :tighten_time_from) '
    || '     AND (TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  <= :tighten_time_to ))) '
         -- 05:OPM保管場所情報
    || ' AND  xoha.deliver_from_id = xilv.inventory_location_id '
         -- 06:顧客情報(管轄拠点)
    || ' AND  xoha.head_sales_branch = xcav.party_number '
         -- 07:顧客サイト情報(出荷先)
-- 2009/05/21 v1.14 H.Itou Mod Start 本番障害#1398 IDは古い可能性があるため、コードで結合
--    || ' AND  xoha.deliver_to_id        = xcasv.party_site_id '
    || ' AND  xoha.deliver_to             = xcasv.party_site_number ' -- 出荷先
    || ' AND  xcasv.party_site_status     = ''A'' '                   -- 有効な出荷先
    || ' AND  xcasv.cust_acct_site_status = ''A'' '                   -- 有効な出荷先
-- 2009/05/21 v1.14 H.Itou Mod End
         ----------------------------------------------------------------------------------
         -- 明細情報
         ----------------------------------------------------------------------------------
         -- 02:受注明細アドオン
    || ' AND  xoha.order_header_id =  xola.order_header_id '
    || ' AND  xola.delete_flag    <>  ''' || gc_delete_flg || ''' '
         -- 08:OPM品目情報 '
    || ' AND  xola.shipping_inventory_item_id = ximv.inventory_item_id '
         ----------------------------------------------------------------------------------
         -- 不足分取得条件
         ----------------------------------------------------------------------------------
    || ' AND  (((xola.quantity - xola.reserved_quantity) > 0) '
    || '    OR  (xola.reserved_quantity IS NULL)) '
         ----------------------------------------------------------------------------------
         -- クイックコード
         ----------------------------------------------------------------------------------
         -- 09:クイックコード(物流ブロック)
    || ' AND  xlvv1.lookup_type = ''' || gc_lookup_cd_block || ''' '
    || ' AND  xilv.distribution_block = xlvv1.lookup_code '
         -- 10:クイックコード(物流担当確認依頼区分)
    || ' AND  xlvv2.lookup_type = ''' || gc_lookup_cd_conreq || ''' '
    || ' AND  xoha.confirm_request_class = xlvv2.lookup_code '
         ----------------------------------------------------------------------------------
         -- 適用日
         ----------------------------------------------------------------------------------
         -- 04:出荷依頼締め管理(アドオン)
    || ' AND  xottv.start_date_active <= xoha.schedule_ship_date '
    || ' AND  ((xottv.end_date_active IS NULL) '
    || '   OR  (xottv.end_date_active >= xoha.schedule_ship_date)) '
         -- 05:OPM保管場所
    || ' AND  xilv.date_from <= xoha.schedule_ship_date '
    || ' AND  ((xilv.date_to IS NULL) '
    || '   OR  (xilv.date_to >= xoha.schedule_ship_date)) '
         -- 06:顧客情報(管轄拠点)
    || ' AND  xcav.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xcav.end_date_active IS NULL) '
    || '   OR (xcav.end_date_active  >= xoha.schedule_ship_date)) '
         -- 07:顧客サイト情報(出荷先)
    || ' AND  xcasv.start_date_active <= xoha.schedule_ship_date '
    || ' AND ((xcasv.end_date_active IS NULL) '
    || '   OR (xcasv.end_date_active >= xoha.schedule_ship_date)) '
         -- 08:OPM品目情報
    || ' AND  ximv.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((ximv.end_date_active IS NULL) '
    || '   OR (ximv.end_date_active  >= xoha.schedule_ship_date)) '
         -- 09:クイックコード(物流ブロック)
    || ' AND  xlvv1.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xlvv1.end_date_active IS NULL) '
    || '   OR (xlvv1.end_date_active  >= xoha.schedule_ship_date)) '
         -- 10:クイックコード(物流担当確認依頼区分)
    || ' AND  xlvv2.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xlvv2.end_date_active IS NULL) '
    || '   OR (xlvv2.end_date_active  >= xoha.schedule_ship_date)) '
         ----------------------------------------------------------------------------------
         -- 動的条件
         ----------------------------------------------------------------------------------
    ||   lv_where_tightening_date       -- 締め実施日条件
    ||   lv_where_item_no               -- 品目条件
    ||   lv_where_block_or_deliver_from -- 物流ブロック・出庫元条件
    ;
--
    -- ======================================
    -- 不足無し分(出荷)SQL作成
    -- ======================================
    lv_sql_wsh_stock :=
       ' SELECT '
-- 2012/03/30 K.Nakamura Mod Start E_本稼動_09296
---- 2008/12/10 Miyata Add Start 本番#637 パフォーマンス改善
--    || '/*+ INDEX ( xtc xxwsh_tico_n02 ) INDEX ( xottv oe_transaction_types_all_u1 ) INDEX ( xilv mtl_item_locations_u1) */'
---- 2008/12/10 Miyata Add End 本番#637
    || '/*+ INDEX ( xtc       xxwsh_tico_n02 )
            INDEX ( xottv     oe_transaction_types_all_u1 )
            INDEX ( xilv      mtl_item_locations_u1)
            INDEX ( ximv.xibm xxcmn_item_mst_b_pk )
            NO_INDEX ( ximv.ximb xxcmn_imb_n01 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n02 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n03 ) */'
-- 2012/03/30 K.Nakamura Mod End E_本稼動_09296
         ----------------------------------------------------------------------------------
         -- ヘッダ部
         ----------------------------------------------------------------------------------
    || '   xilv.distribution_block      AS  block_cd '           -- ブロックコード
    || '  ,xlvv1.meaning                AS  block_nm '           -- ブロック名称
    || '  ,xoha.deliver_from            AS  shipped_cd '         -- 出庫元コード
    || '  ,xilv.description             AS  shipped_nm '         -- 出庫元名
         ----------------------------------------------------------------------------------
         -- 明細部
         ----------------------------------------------------------------------------------
    || '  ,xola.shipping_item_code      AS  item_cd '            -- 品目コード
    || '  ,ximv.item_name               AS  item_nm '            -- 品目名称
    || '  ,xoha.schedule_ship_date      AS  shipped_date '       -- 出庫日
    || '  ,xoha.schedule_arrival_date   AS  arrival_date '       -- 着日
    || '  ,TO_CHAR(''' || gc_biz_type_nm_ship || ''') AS  biz_type '           -- 業務種別
    || '  ,xoha.request_no              AS  req_move_no '        -- 依頼No/移動No
    || '  ,xoha.head_sales_branch       AS  base_cd '            -- 管轄拠点
    || '  ,xcav.party_short_name        AS  base_nm '            -- 管轄拠点名称
    || '  ,xoha.deliver_to              AS  delivery_to_cd '     -- 配送先/入庫先
    || '  ,xcasv.party_site_full_name   AS  delivery_to_nm '     -- 配送先名称
    || '  ,SUBSTRB(xoha.shipping_instructions, 1, 40) '
    || '                                AS  description '        -- 摘要
    || '  ,xlvv2.meaning                AS  conf_req '           -- 確認依頼
    || '  ,CASE '
    || '     WHEN xola.warning_date IS NULL THEN xola.designated_production_date '
    || '     ELSE xola.warning_date '
    || '   END                          AS  de_prod_date '       -- 指定製造日
-- 2009/01/27 v1.11 MOD START
--    || '  ,NVL(xola.warning_date, NVL(xola.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD''))) '
    || '  ,NVL(xola.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD'')) '
-- 2009/01/27 v1.11 MOD END
    || '                                AS  de_prod_date_sort '  -- 指定製造日(ソート用) 2008/09/26 H.Itou Add T_TE080_BPO_600指摘38対応
    || '  ,ilm.attribute1               AS  prod_date '          -- 製造日
    || '  ,ilm.attribute3               AS  best_before_date '   -- 賞味期限
    || '  ,ilm.attribute2               AS  native_sign '        -- 固有記号
-- 2009/05/21 v1.14 H.Itou Mod Start 本番障害#1476 不足なし→不足あり(ロットNoなしレコード)の順に抽出するため、ロットNoを復活
-- 2009/03/06 v1.12 Y.Kazama Del Start 本番障害#785
    || '  ,xmld.lot_no                  AS  lot_no '             -- ロットNo
-- 2009/03/06 v1.12 Y.Kazama Del End   本番障害#785
-- 2009/05/21 v1.14 H.Itou Mod End
    || '  ,xlvv3.meaning                AS  lot_status '         -- 品質
-- 2009/03/06 v1.12 Y.Kazama Add Start 本番障害#785
    || '  ,CASE '
    || '    WHEN ximv.conv_unit IS NULL THEN xola.quantity '
    || '    ELSE (xola.quantity '
    || '          / TO_NUMBER( '
    || '              CASE '
    || '                WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                ELSE TO_CHAR(1) '
    || '              END)) '
    || '   END                          AS  req_sum_qty '        -- 依頼数
-- 2009/03/06 v1.12 Y.Kazama Add End   本番障害#785
    || '  ,CASE '
    || '    WHEN ximv.conv_unit IS NULL THEN xmld.actual_quantity '
    || '    ELSE (xmld.actual_quantity '
    || '          / TO_NUMBER( '
    || '              CASE '
    || '                WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                ELSE TO_CHAR(1) '
    || '              END)) '
    || '   END                          AS  req_qty '            -- ロット別数
    || '  ,TO_NUMBER(0)                 AS  ins_qty '            -- 不足数
    || '  ,xcav.reserve_order           AS  reserve_order '      -- 引当順
    || '  ,xoha.arrival_time_from       AS  time_from '          -- 時間指定From
    || ' FROM '
    || '  ( ' || lv_sql_item_short_stock || ') data '   -- 00:引当済分を抽出するための不足品目のサブクエリ
    || '  ,xxwsh_order_headers_all        xoha '   -- 01:受注ヘッダアドオン
    || '  ,xxwsh_order_lines_all          xola '   -- 02:受注明細アドオン
    || '  ,xxwsh_oe_transaction_types2_v  xottv '  -- 03:受注タイプ情報
    || '  ,xxwsh_tightening_control       xtc '    -- 04:出荷依頼締め管理(アドオン)
    || '  ,xxcmn_item_locations2_v        xilv '   -- 05:OPM保管場所情報
    || '  ,xxcmn_cust_accounts2_v         xcav '   -- 06:顧客情報(管轄拠点)
    || '  ,xxcmn_cust_acct_sites2_v       xcasv '  -- 07:顧客サイト情報(出荷先)
    || '  ,xxcmn_item_mst2_v              ximv '   -- 08:OPM品目情報
    || '  ,xxinv_mov_lot_details          xmld '   -- 09:移動ロット詳細(アドオン)
    || '  ,ic_lots_mst                    ilm '    -- 10:OPMロットマスタ
    || '  ,xxcmn_lookup_values2_v         xlvv1 '  -- 11:クイックコード(物流ブロック)
    || '  ,xxcmn_lookup_values2_v         xlvv2 '  -- 12:クイックコード(物流担当確認依頼区分)
    || '  ,xxcmn_lookup_values2_v         xlvv3 '  -- 13:クイックコード(ロットステータス)
    || ' WHERE '
         ----------------------------------------------------------------------------------
         -- 不足品目情報絞込み条件
         ----------------------------------------------------------------------------------
    || '       xoha.deliver_from        =  data.shipped_cd '
    || ' AND  xola.shipping_item_code   =  data.item_cd '
    || ' AND  xoha.schedule_ship_date  >=  TO_DATE(:shipped_date_from) '
    || ' AND  xoha.schedule_ship_date  <=  TO_DATE(data.shipped_date) '
-- 2008/10/03 H.Itou Mod Start 部分引当か、全引当を抽出したいので、不等号変更
--    || ' AND  (xola.quantity - xola.reserved_quantity) <= 0 '
    || ' AND  (xola.quantity - xola.reserved_quantity) >= 0 '
-- 2008/10/03 H.Itou Del End
         ----------------------------------------------------------------------------------
         -- ヘッダ情報
         ----------------------------------------------------------------------------------
         -- 03:受注タイプ情報
    || ' AND  xottv.shipping_shikyu_class  = ''' || gc_ship_pro_kbn_s || ''' '  -- 出荷支給区分:出荷依頼
    || ' AND  xottv.order_category_code   <> ''' || gc_order_cate_ret || ''' '  -- 受注カテゴリ:返品
         -- 01:受注ヘッダアドオン
    || ' AND  xoha.order_type_id           =  xottv.transaction_type_id '
-- 2009/01/07 v1.7 UPDATE START
--    || ' AND  xoha.req_status             >= ''' || gc_ship_status_close || ''' '     -- ステータス:締め済み
--    || ' AND  xoha.req_status             <> ''' || gc_ship_status_delete || ''' '    -- ステータス:取消
    || ' AND  xoha.req_status IN ( ''' || gc_ship_status_close || ''',''' || gc_ship_status_confirm || ''') ' -- ステータス:締め済み
-- 2009/01/07 v1.7 UPDATE END
    || ' AND  xoha.latest_external_flag    = ''' || gc_new_flg || ''' '               -- 最新フラグ
-- 2008/12/10 H.Itou Add Start
    || ' AND  xoha.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- 通知ステータスが確定通知済でないもの
-- 2008/12/10 H.Itou Add End
         -- 04:出荷依頼締め管理(アドオン)
    || ' AND  xoha.tightening_program_id  = xtc.concurrent_id(+) '
    || ' AND   ((xtc.tightening_date IS NULL) '
    || '   OR   ((TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  >= :tighten_time_from) '
    || '     AND (TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  <= :tighten_time_to ))) '
         -- 05:OPM保管場所情報
    || ' AND  xoha.deliver_from_id = xilv.inventory_location_id '
         -- 06:顧客情報(管轄拠点)
    || ' AND  xoha.head_sales_branch = xcav.party_number '
         -- 07:顧客サイト情報(出荷先)
-- 2009/05/21 v1.14 H.Itou Mod Start 本番障害#1398 IDは古い可能性があるため、コードで結合
--    || ' AND  xoha.deliver_to_id     = xcasv.party_site_id '
    || ' AND  xoha.deliver_to             = xcasv.party_site_number ' -- 出荷先
    || ' AND  xcasv.party_site_status     = ''A'' '                   -- 有効な出荷先
    || ' AND  xcasv.cust_acct_site_status = ''A'' '                   -- 有効な出荷先
-- 2009/05/21 v1.14 H.Itou Mod End
         ----------------------------------------------------------------------------------
         -- 明細情報
         ----------------------------------------------------------------------------------
         -- 02:受注明細アドオン
    || ' AND  xoha.order_header_id  =  xola.order_header_id '
    || ' AND  xola.delete_flag     <> ''' || gc_delete_flg || ''' '
         -- 10:OPM品目情報
    || ' AND  xola.shipping_inventory_item_id = ximv.inventory_item_id '
         ----------------------------------------------------------------------------------
         -- ロット情報
         ----------------------------------------------------------------------------------
         -- 09:移動ロット詳細(アドオン)
    || ' AND  xola.order_line_id = xmld.mov_line_id '
    || ' AND  xmld.document_type_code = ''' || gc_doc_type_ship  || ''' '  -- 文書タイプ:出荷依頼
    || ' AND  xmld.record_type_code   = ''' || gc_rec_type_shiji || ''' '  -- レコードタイプ:指示
         -- 10:OPMロットマスタ
    || ' AND  xmld.lot_id   =  ilm.lot_id '
    || ' AND  xmld.item_id  =  ilm.item_id '
         ----------------------------------------------------------------------------------
         -- クイックコード
         ----------------------------------------------------------------------------------
         -- 11:クイックコード(物流ブロック)
    || ' AND  xlvv1.lookup_type = ''' || gc_lookup_cd_block || ''' '
    || ' AND  xilv.distribution_block = xlvv1.lookup_code '
         -- 12:クイックコード(物流担当確認依頼区分)
    || ' AND  xlvv2.lookup_type = ''' || gc_lookup_cd_conreq || ''' '
    || ' AND  xoha.confirm_request_class = xlvv2.lookup_code '
         -- 13:クイックコード(ロットステータス)
    || ' AND  xlvv3.lookup_type = ''' || gc_lookup_cd_lot_status || ''' '
    || ' AND  ilm.attribute23 = xlvv3.lookup_code '
         ----------------------------------------------------------------------------------
         -- 適用日
         ----------------------------------------------------------------------------------
         -- 04:出荷依頼締め管理(アドオン)
    || ' AND  xottv.start_date_active <= xoha.schedule_ship_date '
    || ' AND  ((xottv.end_date_active IS NULL) '
    || '   OR  (xottv.end_date_active >= xoha.schedule_ship_date)) '
         -- 05:OPM保管場所
    || ' AND  xilv.date_from <= xoha.schedule_ship_date '
    || ' AND  ((xilv.date_to IS NULL) '
    || '   OR  (xilv.date_to >= xoha.schedule_ship_date)) '
         -- 06:顧客情報(管轄拠点)
    || ' AND  xcav.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xcav.end_date_active IS NULL) '
    || '   OR (xcav.end_date_active  >= xoha.schedule_ship_date)) '
         -- 07:顧客サイト情報(出荷先)
    || ' AND  xcasv.start_date_active <= xoha.schedule_ship_date '
    || ' AND ((xcasv.end_date_active IS NULL) '
    || '   OR (xcasv.end_date_active >= xoha.schedule_ship_date)) '
         -- 08:OPM品目情報
    || ' AND  ximv.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((ximv.end_date_active IS NULL) '
    || '   OR (ximv.end_date_active  >= xoha.schedule_ship_date)) '
         -- 11:クイックコード(物流ブロック)
    || ' AND  xlvv1.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xlvv1.end_date_active IS NULL) '
    || '   OR (xlvv1.end_date_active  >= xoha.schedule_ship_date)) '
         -- 12:クイックコード(物流担当確認依頼区分)
    || ' AND  xlvv2.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xlvv2.end_date_active IS NULL) '
    || '   OR (xlvv2.end_date_active  >= xoha.schedule_ship_date)) '
         -- 13:クイックコード(ロットステータス)
    || ' AND  xlvv3.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xlvv3.end_date_active IS NULL) '
    || '   OR (xlvv3.end_date_active  >= xoha.schedule_ship_date)) '
         ----------------------------------------------------------------------------------
         -- 動的条件
         ----------------------------------------------------------------------------------
    ||   lv_where_tightening_date       -- 締め実施日条件
    ;
    -- ======================================
    -- 不足分取得(移動)
    -- ======================================
    lv_sql_inv_short_stock :=
       ' SELECT '
-- 2012/03/30 K.Nakamura Mod Start E_本稼動_09296
---- 2008/12/10 Miyata Add Start 本番#637 パフォーマンス改善
--    || '/*+ INDEX ( xilv mtl_item_locations_u1 ) INDEX (xilv2 mtl_item_locations_u1 ) */'
---- 2008/12/10 Miyata Add End 本番#637
    || '/*+ INDEX ( xilv      mtl_item_locations_u1 )
            INDEX ( xilv2     mtl_item_locations_u1 )
            INDEX ( ximv.ximb xxcmn_item_mst_b_pk )
            NO_INDEX ( ximv.ximb xxcmn_imb_n01 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n02 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n03 ) */'
-- 2012/03/30 K.Nakamura Mod End E_本稼動_09296
         ----------------------------------------------------------------------------------
         -- ヘッダ情報
         ----------------------------------------------------------------------------------
    || '   xilv.distribution_block      AS  block_cd '           -- ブロックコード
    || '  ,xlvv1.meaning                AS  block_nm '           -- ブロック名称
    || '  ,xmrih.shipped_locat_code     AS  shipped_cd '         -- 出庫元コード
    || '  ,xilv.description             AS  shipped_nm '         -- 出庫元名
         ----------------------------------------------------------------------------------
         -- 明細情報
         ----------------------------------------------------------------------------------
    || '  ,xmril.item_code              AS  item_cd '            -- 品目コード
    || '  ,ximv.item_name               AS  item_nm '            -- 品目名称
    || '  ,xmrih.schedule_ship_date     AS  shipped_date '       -- 出庫日
    || '  ,xmrih.schedule_arrival_date  AS  arrival_date '       -- 着日
    || '  ,TO_CHAR(''' || gc_biz_type_nm_move || ''') AS  biz_type '           -- 業務種別
    || '  ,xmrih.mov_num                AS  req_move_no '        -- 依頼No/移動No
    || '  ,NULL                         AS  base_cd '            -- 管轄拠点
    || '  ,NULL                         AS  base_nm '            -- 管轄拠点名称
    || '  ,xmrih.ship_to_locat_code     AS  delivery_to_cd '     -- 配送先/入庫先
    || '  ,xilv2.description            AS  delivery_to_nm '     -- 配送先名称
    || '  ,SUBSTRB(xmrih.description, 1, 40) AS  description '   -- 摘要
    || '  ,NULL                         AS  conf_req '           -- 確認依頼
    || '  ,CASE '
    || '    WHEN xmril.warning_date IS NULL THEN xmril.designated_production_date '
    || '    ELSE xmril.warning_date '
    || '   END                          AS  de_prod_date '       -- 指定製造日
-- 2009/01/27 v1.11 MOD START
--    || '  ,NVL(xmril.warning_date, NVL(xmril.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD''))) '
    || '  ,NVL(xmril.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD'')) '
-- 2009/01/27 v1.11 MOD END
    || '                                AS  de_prod_date_sort '  -- 指定製造日(ソート用) 2008/09/26 H.Itou Add T_TE080_BPO_600指摘38対応
    || '  ,NULL                         AS  prod_date '          -- 製造日
    || '  ,NULL                         AS  best_before_date '   -- 賞味期限
    || '  ,NULL                         AS  native_sign '        -- 固有記号
-- 2009/05/21 v1.14 H.Itou Mod Start 本番障害#1476 不足なし→不足あり(ロットNoなしレコード)の順に抽出するため、ロットNoを復活
-- 2009/03/06 v1.12 Y.Kazama Del Start 本番障害#785
    || '  ,NULL                         AS  lot_no '             -- ロットNo
-- 2009/03/06 v1.12 Y.Kazama Del End   本番障害#785
-- 2009/05/21 v1.14 H.Itou Mod End
    || '  ,NULL                         AS  lot_status '         -- 品質
-- 2009/03/06 v1.12 Y.Kazama Add Start 本番障害#785
    || '  ,CASE '
    || '    WHEN ximv.conv_unit IS NULL THEN '
    || '      xmril.instruct_qty '
    || '    ELSE (xmril.instruct_qty '
    || '          / TO_NUMBER( '
    || '              CASE '
    || '                WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                ELSE TO_CHAR(1) '
    || '              END)) '
    || '   END                          AS  req_sum_qty '        -- 依頼数
-- 2009/03/06 v1.12 Y.Kazama Add End   本番障害#785
-- 2008/10/03 H.Itou Mod Start T_TE080_BPO_600指摘37 在庫不足の場合、ロット別数には不足数を表示
--    || '  ,CASE '
--    || '     WHEN ximv.conv_unit IS NULL THEN xmril.instruct_qty '
--    || '     ELSE                            (xmril.instruct_qty / ximv.num_of_cases) '
    || '  ,CASE '
    || '    WHEN ximv.conv_unit IS NULL THEN '
    || '      (xmril.instruct_qty - NVL(xmril.reserved_quantity, 0)) '
    || '    ELSE ((xmril.instruct_qty - NVL(xmril.reserved_quantity, 0)) '
    || '          / TO_NUMBER( '
    || '              CASE '
    || '                WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                ELSE TO_CHAR(1) '
    || '              END)) '
-- 2008/10/03 H.Itou Mod End
    || '   END                          AS  req_qty '            -- ロット別数
    || '  ,CASE '
    || '    WHEN ximv.conv_unit IS NULL THEN '
    || '      (xmril.instruct_qty - NVL(xmril.reserved_quantity, 0)) '
    || '    ELSE ((xmril.instruct_qty - NVL(xmril.reserved_quantity, 0)) '
    || '          / TO_NUMBER( '
    || '              CASE '
    || '                WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                ELSE TO_CHAR(1) '
    || '              END)) '
    || '   END                          AS  ins_qty '            -- 不足数
    || '  ,NULL                         AS  reserve_order '      -- 引当順
    || '  ,xmrih.arrival_time_from      AS  time_from '          -- 時間指定From
    || ' FROM '
    || '   xxinv_mov_req_instr_headers    xmrih '    -- 01:移動依頼/指示ヘッダ（アドオン）
    || '  ,xxinv_mov_req_instr_lines      xmril '    -- 02:移動依頼/指示明細（アドオン）
    || '  ,xxcmn_item_locations2_v        xilv '     -- 03:OPM保管場所情報(出庫元)
    || '  ,xxcmn_item_locations2_v        xilv2 '    -- 04:OPM保管場所情報(入庫先)
    || '  ,xxcmn_item_mst2_v              ximv  '    -- 05:OPM品目情報
    || '  ,xxcmn_lookup_values2_v         xlvv1 '    -- 06:クイックコード(物流ブロック)
    || ' WHERE '
         ----------------------------------------------------------------------------------
         -- ヘッダ情報
         ----------------------------------------------------------------------------------
         -- 01:移動依頼/指示ヘッダ（アドオン）
    || '      xmrih.status               >=  ''' || gc_move_status_ordered || ''' ' -- ステータス:依頼済
    || ' AND  xmrih.mov_type             <>  ''' || gc_mov_type_not_ship   || ''' '   -- 移動タイプ:積送なし
    || ' AND  xmrih.item_class            =  ''' || gv_prod_kbn            || ''' '
    || ' AND  xmrih.schedule_ship_date   >=  :shipped_date_from '
    || ' AND  xmrih.schedule_ship_date   <=  :shipped_date_to '
-- 2009/01/07 v1.7 UPDATE START
/*
-- 2008/12/10 H.Itou Add Start
    || ' AND  xmrih.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- 通知ステータスが確定通知済でないもの
-- 2008/12/10 H.Itou Add End
*/
    || '   AND  xmrih.notif_status IN ( ''' || gc_notif_status_mt || ''',''' || gc_notif_status_sty || ''') '   -- 通知ステータスが確定通知済でないもの
-- 2009/01/07 v1.7 UPDATE START
        -- 03:OPM保管場所情報(出庫元)
    || ' AND  xilv.inventory_location_id = xmrih.shipped_locat_id '
         -- 04:OPM保管場所情報(入庫先)
    || ' AND  xilv2.inventory_location_id = xmrih.ship_to_locat_id '
         ----------------------------------------------------------------------------------
         -- 明細情報
         ----------------------------------------------------------------------------------
         -- 02:移動依頼/指示明細（アドオン）
    || ' AND  xmrih.mov_hdr_id   =  xmril.mov_hdr_id '
    || ' AND  xmril.delete_flg  <>  ''' || gc_delete_flg || ''' '
         -- 05:OPM品目情報
    || ' AND  xmril.item_id = ximv.item_id '
         ----------------------------------------------------------------------------------
         -- 不足分取得条件
         ----------------------------------------------------------------------------------
    || ' AND (((xmril.instruct_qty - xmril.reserved_quantity) > 0) '
    || '   OR  (xmril.reserved_quantity IS NULL)) '
         ----------------------------------------------------------------------------------
         -- クイックコード
         ----------------------------------------------------------------------------------
         -- 06:クイックコード(物流ブロック)
    || ' AND  xlvv1.lookup_type = ''' || gc_lookup_cd_block || ''' '
    || ' AND  xilv.distribution_block = xlvv1.lookup_code '
         ----------------------------------------------------------------------------------
         -- 適用日
         ----------------------------------------------------------------------------------
         -- 03:OPM保管場所(出庫元)
    || ' AND  xilv.date_from <= xmrih.schedule_ship_date '
    || ' AND  ((xilv.date_to IS NULL) '
    || '   OR  (xilv.date_to >= xmrih.schedule_ship_date)) '
         -- 04:OPM保管場所(入庫先)
    || ' AND  xilv2.date_from <= xmrih.schedule_ship_date '
    || ' AND  ((xilv2.date_to IS NULL) '
    || '   OR  (xilv2.date_to >= xmrih.schedule_ship_date)) '
         -- 05:OPM品目情報
    || ' AND  ximv.start_date_active  <= xmrih.schedule_ship_date '
    || ' AND ((ximv.end_date_active IS NULL) '
    || '   OR (ximv.end_date_active  >= xmrih.schedule_ship_date)) '
         -- 06:クイックコード(物流ブロック)
    || ' AND  xlvv1.start_date_active  <= xmrih.schedule_ship_date '
    || ' AND ((xlvv1.end_date_active IS NULL) '
    || '   OR (xlvv1.end_date_active  >= xmrih.schedule_ship_date)) '
-- 2008/11/13 v1.4 T.Yoshimoto Add Start
    || ' AND ((xmrih.no_instr_actual_class <> ''' || gc_move_instr_actual_class || ''') '
    || '   OR (xmrih.no_instr_actual_class IS NULL)) '
-- 2008/11/13 v1.4 T.Yoshimoto Add End

         ----------------------------------------------------------------------------------
         -- 動的条件
         ----------------------------------------------------------------------------------
    ||   lv_where_item_no               -- 品目条件
    ||   lv_where_block_or_deliver_from -- 物流ブロック・出庫元条件
    ;
--
    -- ======================================
    -- 不足無し分の取得(移動)
    -- ======================================
    lv_sql_inv_stock :=
       ' SELECT '
-- 2012/03/30 K.Nakamura Mod Start E_本稼動_09296
---- 2008/12/10 Miyata Add Start 本番#637 パフォーマンス改善
--    || '/*+ INDEX ( xilv1 mtl_item_locations_u1 ) INDEX ( xilv2 mtl_item_locations_u1 ) */'
---- 2008/12/10 Miyata Add End 本番#637
    || '/*+ INDEX ( xilv1     mtl_item_locations_u1 )
            INDEX ( xilv2     mtl_item_locations_u1 )
            INDEX ( ximv.ximb xxcmn_item_mst_b_pk )
            NO_INDEX ( ximv.ximb xxcmn_imb_n01 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n02 )
            NO_INDEX ( ximv.ximb xxcmn_imb_n03 ) */'
-- 2012/03/30 K.Nakamura Mod End E_本稼動_09296
         ----------------------------------------------------------------------------------
         -- ヘッダ情報
         ----------------------------------------------------------------------------------
    || '   xilv1.distribution_block     AS  block_cd '           -- ブロックコード
    || '  ,xlvv1.meaning                AS  block_nm '           -- ブロック名称
    || '  ,xmrih.shipped_locat_code     AS  shipped_cd '         -- 出庫元コード
    || '  ,xilv1.description            AS  shipped_nm '         -- 出庫元名
         ----------------------------------------------------------------------------------
         -- 明細情報
         ----------------------------------------------------------------------------------
    || '  ,xmril.item_code              AS  item_cd '            -- 品目コード
    || '  ,ximv.item_name               AS  item_nm '            -- 品目名称
    || '  ,xmrih.schedule_ship_date     AS  shipped_date '       -- 出庫日
    || '  ,xmrih.schedule_arrival_date  AS  arrival_date '       -- 着日
    || '  ,TO_CHAR(''' || gc_biz_type_nm_move || ''') AS  biz_type '           -- 業務種別
    || '  ,xmrih.mov_num                AS  req_move_no '        -- 依頼No/移動No
    || '  ,NULL                         AS  base_cd '            -- 管轄拠点
    || '  ,NULL                         AS  base_nm '            -- 管轄拠点名称
    || '  ,xmrih.ship_to_locat_code     AS  delivery_to_cd '     -- 配送先/入庫先
    || '  ,xilv2.description            AS  delivery_to_nm '     -- 配送先名称
    || '  ,SUBSTRB(xmrih.description, 1, 40) AS  description '   -- 摘要
    || '  ,NULL                         AS  conf_req '           -- 確認依頼
    || '  ,CASE '
    || '     WHEN xmril.warning_date IS NULL THEN xmril.designated_production_date '
    || '     ELSE xmril.warning_date '
    || '   END                          AS  de_prod_date '       -- 指定製造日
-- 2009/01/27 v1.11 MOD START
--    || '  ,NVL(xmril.warning_date, NVL(xmril.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD''))) '
    || '  ,NVL(xmril.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD'')) '
-- 2009/01/27 v1.11 MOD END
    || '                                AS  de_prod_date_sort '  -- 指定製造日(ソート用) 2008/09/26 H.Itou Add T_TE080_BPO_600指摘38対応
    || '  ,ilm.attribute1               AS  prod_date '          -- 製造日
    || '  ,ilm.attribute3               AS  best_before_date '   -- 賞味期限
    || '  ,ilm.attribute2               AS  native_sign '        -- 固有記号
-- 2009/05/21 v1.14 H.Itou Mod Start 本番障害#1476 不足なし→不足あり(ロットNoなしレコード)の順に抽出するため、ロットNoを復活
-- 2009/03/06 v1.12 Y.Kazama Del Start 本番障害#785
    || '  ,xmld.lot_no                  AS  lot_no '             -- ロットNo
-- 2009/03/06 v1.12 Y.Kazama Del End   本番障害#785
-- 2009/05/21 v1.14 H.Itou Mod End
    || '  ,xlvv2.meaning                AS  lot_status '         -- 品質
-- 2009/03/06 v1.12 Y.Kazama Add Start 本番障害#785
    || '  ,CASE '
    || '     WHEN ximv.conv_unit IS NULL THEN xmril.instruct_qty '
    || '     ELSE (xmril.instruct_qty '
    || '           / TO_NUMBER( '
    || '               CASE '
    || '                 WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                 ELSE TO_CHAR(1) '
    || '               END)) '
    || '   END                          AS  req_sum_qty '        -- 依頼数
-- 2009/03/06 v1.12 Y.Kazama Add Start 本番障害#785
    || '  ,CASE '
    || '     WHEN ximv.conv_unit IS NULL THEN xmld.actual_quantity '
    || '     ELSE (xmld.actual_quantity '
    || '           / TO_NUMBER( '
    || '               CASE '
    || '                 WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                 ELSE TO_CHAR(1) '
    || '               END)) '
    || '   END                          AS  req_qty '            -- ロット別数
    || '  ,TO_NUMBER(0)                 AS  ins_qty '            -- 不足数
    || '  ,NULL                         AS  reserve_order '      -- 引当順
    || '  ,xmrih.arrival_time_from      AS  time_from '          -- 時間指定From
    || ' FROM '
    || '  ( ' || lv_sql_item_short_stock || ') data ' -- 00:引当済分を抽出するための不足品目のサブクエリ
    || '  ,xxinv_mov_req_instr_headers    xmrih '    -- 01:移動依頼/指示ヘッダ（アドオン）
    || '  ,xxinv_mov_req_instr_lines      xmril '    -- 02:移動依頼/指示明細（アドオン）
    || '  ,xxcmn_item_locations2_v        xilv1 '    -- 03:OPM保管場所情報(出庫元)
    || '  ,xxcmn_item_locations2_v        xilv2 '    -- 04:OPM保管場所情報(入庫先)
    || '  ,xxcmn_item_mst2_v              ximv  '    -- 05:OPM品目情報
    || '  ,xxinv_mov_lot_details          xmld  '    -- 06:移動ロット詳細(アドオン)
    || '  ,ic_lots_mst                    ilm   '    -- 07:OPMロットマスタ
    || '  ,xxcmn_lookup_values2_v         xlvv1 '    -- 08:クイックコード(物流ブロック)
    || '  ,xxcmn_lookup_values2_v         xlvv2 '    -- 09:クイックコード(ロットステータス)
    || ' WHERE '
         ----------------------------------------------------------------------------------
         -- 不足品目情報絞込み条件
         ----------------------------------------------------------------------------------
    || '      xmrih.shipped_locat_code   =  data.shipped_cd '
    || ' AND  xmril.item_code            =  data.item_cd '
    || ' AND  xmrih.schedule_ship_date  >=  :shipped_date_from '
    || ' AND  xmrih.schedule_ship_date  <=  data.shipped_date '
-- 2008/10/03 H.Itou Mod Start 部分引当か、全引当を抽出したいので、不等号変更
--    || ' AND  (xmril.instruct_qty - xmril.reserved_quantity) <= 0 '
    || ' AND  (xmril.instruct_qty - xmril.reserved_quantity) >= 0 '
-- 2008/10/03 H.Itou Mod End
         ----------------------------------------------------------------------------------
         -- ヘッダ情報
         ----------------------------------------------------------------------------------
         -- 01:移動依頼/指示ヘッダ（アドオン）
    || ' AND  xmrih.status    >=  ''' || gc_move_status_ordered || ''' ' -- ステータス:依頼済
    || ' AND  xmrih.mov_type  <>  ''' || gc_mov_type_not_ship   || ''' ' -- 移動タイプ:積送なし
-- 2009/01/07 v1.7 UPDATE START
/*
-- 2008/12/10 H.Itou Add Start
    || ' AND  xmrih.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- 通知ステータスが確定通知済でないもの
-- 2008/12/10 H.Itou Add End
*/
    || ' AND  xmrih.notif_status IN ( ''' || gc_notif_status_mt || ''',''' || gc_notif_status_sty || ''') '   -- 通知ステータスが確定通知済でないもの
-- 2009/01/07 v1.7 UPDATE END
         -- 03:OPM保管場所情報(出庫元)
    || ' AND  xilv1.inventory_location_id = xmrih.shipped_locat_id '
         -- 04:OPM保管場所情報(入庫先)
    || ' AND  xilv2.inventory_location_id = xmrih.ship_to_locat_id '
         ----------------------------------------------------------------------------------
         -- 明細情報
         ----------------------------------------------------------------------------------
         -- 02:移動依頼/指示明細（アドオン）
    || ' AND  xmrih.mov_hdr_id  =  xmril.mov_hdr_id '
    || ' AND  xmril.delete_flg  <>  ''' || gc_delete_flg || ''' '
         -- 05:OPM品目情報
    || ' AND  xmril.item_id = ximv.item_id '
         ----------------------------------------------------------------------------------
         -- ロット情報
         ----------------------------------------------------------------------------------
         -- 06:移動ロット詳細(アドオン)
    || ' AND  xmril.mov_line_id =  xmld.mov_line_id '
    || ' AND  xmril.item_id     =  xmld.item_id '
    || ' AND  xmld.document_type_code = ''' || gc_doc_type_move  || ''' '  -- 文書タイプ:移動
    || ' AND  xmld.record_type_code   = ''' || gc_rec_type_shiji || ''' '  -- レコードタイプ:指示
         -- 07:OPMロットマスタ
    || ' AND  xmld.lot_id   =  ilm.lot_id '
    || ' AND  xmld.item_id  =  ilm.item_id '
         ----------------------------------------------------------------------------------
         -- クイックコード
         ----------------------------------------------------------------------------------
         -- 08:クイックコード(物流ブロック)
    || ' AND  xlvv1.lookup_type = ''' || gc_lookup_cd_block || ''' '
    || ' AND  xilv1.distribution_block = xlvv1.lookup_code '
         -- 09:クイックコード(ロットステータス)
    || ' AND  xlvv2.lookup_type = ''' || gc_lookup_cd_lot_status || ''' '
    || ' AND  ilm.attribute23 = xlvv2.lookup_code '
         ----------------------------------------------------------------------------------
         -- 適用日
         ----------------------------------------------------------------------------------
         -- 03:OPM保管場所(出庫元)
    || ' AND  xilv1.date_from <= xmrih.schedule_ship_date '
    || ' AND  ((xilv1.date_to IS NULL) '
    || '   OR  (xilv1.date_to >= xmrih.schedule_ship_date)) '
         -- 04:OPM保管場所(入庫元)
    || ' AND  xilv2.date_from <= xmrih.schedule_ship_date '
    || ' AND  ((xilv2.date_to IS NULL) '
    || '   OR  (xilv2.date_to >= xmrih.schedule_ship_date)) '
         -- 05:OPM品目情報
    || ' AND  ximv.start_date_active  <= xmrih.schedule_ship_date '
    || ' AND ((ximv.end_date_active IS NULL) '
    || '   OR (ximv.end_date_active  >= xmrih.schedule_ship_date)) '
         -- 08:クイックコード(物流ブロック)
    || ' AND  xlvv1.start_date_active  <= xmrih.schedule_ship_date '
    || ' AND ((xlvv1.end_date_active IS NULL) '
    || '   OR (xlvv1.end_date_active  >= xmrih.schedule_ship_date)) '
         -- 09:クイックコード(ロットステータス)
    || ' AND  xlvv2.start_date_active  <= xmrih.schedule_ship_date '
    || ' AND ((xlvv2.end_date_active IS NULL) '
    || '   OR (xlvv2.end_date_active  >= xmrih.schedule_ship_date)) '
-- 2008/11/13 v1.4 T.Yoshimoto Add Start
    || ' AND ((xmrih.no_instr_actual_class <> ''' || gc_move_instr_actual_class || ''') '
    || '   OR (xmrih.no_instr_actual_class IS NULL)) '
-- 2008/11/13 v1.4 T.Yoshimoto Add End
    ;
--
    -- ======================================
    -- ORDER BY句作成
    -- ======================================
    lv_order_by :=
       ' ORDER BY '
    || '   block_cd       ASC '     -- 01:ブロック
    || '  ,shipped_cd     ASC '     -- 02:出庫元
    || '  ,item_cd        ASC '     -- 03:品目
    || '  ,shipped_date   ASC '     -- 04:出庫日
    || '  ,arrival_date   ASC '     -- 05:着日
    || '  ,de_prod_date_sort  DESC '-- 06:指定製造日 2008/09/26 H.Itou Mod T_TE080_BPO_600指摘38対応
    || '  ,reserve_order  ASC '     -- 07:引当順
    || '  ,base_cd        ASC '     -- 08:管轄拠点
-- 2009/01/27 v1.11 ADD START
    || '  ,delivery_to_cd ASC '     -- 配送先/入庫先
-- 2009/01/27 v1.11 ADD END
    || '  ,time_from      ASC '     -- 09:時間指定From
    || '  ,req_move_no    ASC '     -- 10:依頼No/移動No
-- 2009/05/21 v1.14 H.Itou Mod Start 本番障害#1476 不足なし→不足あり(ロットNoなしレコード)の順に抽出するため、ロットNoを復活
-- 2009/03/06 v1.12 Y.Kazama Del Start 本番障害#785
    || '  ,lot_no         ASC '     -- 11:ロットNo
-- 2009/03/06 v1.12 Y.Kazama Del End   本番障害#785
-- 2009/05/21 v1.14 H.Itou Mod End   本番障害#1476
    ;
--
    -- ======================================
    -- SQL作成
    -- ======================================
    lv_sql := lv_sql_wsh_short_stock -- 不足分取得(出荷)SQL
           || cv_union_all           -- UNION ALL
           || lv_sql_wsh_stock       -- 不足無し分(出荷)SQL
           || cv_union_all           -- UNION ALL
           || lv_sql_inv_short_stock -- 不足分取得(移動)SQL
           || cv_union_all           -- UNION ALL
           || lv_sql_inv_stock       -- 不足無し分(移動)SQL
           || lv_order_by            -- ORDER BY句
           ;
--
    -- ======================================
    -- カーソルOPEN
    -- ======================================
    OPEN  cur_data FOR lv_sql
    USING ----------------------------------
          -- 不足分取得(出荷)SQLパラメータ
          ----------------------------------
          gt_param.shipped_date_from                      -- WHERE句 出庫日           >= INパラメータ.出庫日FROM
         ,gt_param.shipped_date_to                        -- WHERE句 出庫日           <= INパラメータ.出庫日TO
         ,NVL(gt_param.tighten_time_from, gc_time_start)  -- WHERE句 締め実施日(時間) >= INパラメータ.締め実施時間FROM
         ,NVL(gt_param.tighten_time_to,   gc_time_end)    -- WHERE句 締め実施日(時間) <= INパラメータ.締め実施時間TO
         ,gt_param.tighten_date                           -- WHERE句 締め実施日        = INパラメータ.締め実施日
         ,gt_param.item_cd                                -- WHERE句 品目              = INパラメータ.品目
         ,gt_param.shipped_cd                             -- WHERE句 出庫元            = INパラメータ.出庫元
         ,gt_param.block1                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック1
         ,gt_param.block2                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック2
         ,gt_param.block3                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック3
          ----------------------------------
          -- 不足無し取得(出荷)SQLパラメータ
          ----------------------------------
          -- ** サブクエリのパラメータ(引当済分を抽出するための不足品目の取得(出荷)) ** --
         ,gt_param.shipped_date_from                      -- WHERE句 出庫日           >= INパラメータ.出庫日FROM
         ,gt_param.shipped_date_to                        -- WHERE句 出庫日           <= INパラメータ.出庫日TO
         ,NVL(gt_param.tighten_time_from, gc_time_start)  -- WHERE句 締め実施日(時間) >= INパラメータ.締め実施時間FROM
         ,NVL(gt_param.tighten_time_to,   gc_time_end)    -- WHERE句 締め実施日(時間) <= INパラメータ.締め実施時間TO
         ,gt_param.tighten_date                           -- WHERE句 締め実施日        = INパラメータ.締め実施日
         ,gt_param.item_cd                                -- WHERE句 品目              = INパラメータ.品目
         ,gt_param.shipped_cd                             -- WHERE句 出庫元            = INパラメータ.出庫元
         ,gt_param.block1                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック1
         ,gt_param.block2                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック2
         ,gt_param.block3                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック3
          -- ** サブクエリのパラメータ(引当済分を抽出するための不足品目の取得(移動)) ** --
         ,gt_param.shipped_date_from                      -- WHERE句 出庫日           >= INパラメータ.出庫日FROM
         ,gt_param.shipped_date_to                        -- WHERE句 出庫日           <= INパラメータ.出庫日TO
         ,gt_param.item_cd                                -- WHERE句 品目              = INパラメータ.品目
         ,gt_param.shipped_cd                             -- WHERE句 出庫元            = INパラメータ.出庫元
         ,gt_param.block1                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック1
         ,gt_param.block2                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック2
         ,gt_param.block3                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック3
          -- ** メインのパラメータ ** --
         ,gt_param.shipped_date_from                      -- WHERE句 出庫日           >= INパラメータ.出庫日FROM
         ,NVL(gt_param.tighten_time_from, gc_time_start)  -- WHERE句 締め実施日(時間) >= INパラメータ.締め実施時間FROM
         ,NVL(gt_param.tighten_time_to,   gc_time_end)    -- WHERE句 締め実施日(時間) <= INパラメータ.締め実施時間TO
         ,gt_param.tighten_date                           -- WHERE句 締め実施日        = INパラメータ.締め実施日
          ----------------------------------
          -- 不足分取得(移動)SQLパラメータ
          ----------------------------------
         ,gt_param.shipped_date_from                      -- WHERE句 出庫日           >= INパラメータ.出庫日FROM
         ,gt_param.shipped_date_to                        -- WHERE句 出庫日           <= INパラメータ.出庫日TO
         ,gt_param.item_cd                                -- WHERE句 品目              = INパラメータ.品目
         ,gt_param.shipped_cd                             -- WHERE句 出庫元            = INパラメータ.出庫元
         ,gt_param.block1                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック1
         ,gt_param.block2                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック2
         ,gt_param.block3                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック3
          ----------------------------------
          -- 不足無し取得(移動)SQLパラメータ
          ----------------------------------
          -- ** サブクエリのパラメータ(引当済分を抽出するための不足品目の取得(出荷)) ** --
         ,gt_param.shipped_date_from                      -- WHERE句 出庫日           >= INパラメータ.出庫日FROM
         ,gt_param.shipped_date_to                        -- WHERE句 出庫日           <= INパラメータ.出庫日TO
         ,NVL(gt_param.tighten_time_from, gc_time_start)  -- WHERE句 締め実施日(時間) >= INパラメータ.締め実施時間FROM
         ,NVL(gt_param.tighten_time_to,   gc_time_end)    -- WHERE句 締め実施日(時間) <= INパラメータ.締め実施時間TO
         ,gt_param.tighten_date                           -- WHERE句 締め実施日        = INパラメータ.締め実施日
         ,gt_param.item_cd                                -- WHERE句 品目              = INパラメータ.品目
         ,gt_param.shipped_cd                             -- WHERE句 出庫元            = INパラメータ.出庫元
         ,gt_param.block1                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック1
         ,gt_param.block2                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック2
         ,gt_param.block3                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック3
          -- ** サブクエリのパラメータ(引当済分を抽出するための不足品目の取得(移動)) ** --
         ,gt_param.shipped_date_from                      -- WHERE句 出庫日           >= INパラメータ.出庫日FROM
         ,gt_param.shipped_date_to                        -- WHERE句 出庫日           <= INパラメータ.出庫日TO
         ,gt_param.item_cd                                -- WHERE句 品目              = INパラメータ.品目
         ,gt_param.shipped_cd                             -- WHERE句 出庫元            = INパラメータ.出庫元
         ,gt_param.block1                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック1
         ,gt_param.block2                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック2
         ,gt_param.block3                                 -- WHERE句 物流ブロック      = INパラメータ.ブロック3
          -- ** メインのパラメータ ** --
         ,gt_param.shipped_date_from                      -- WHERE句 出庫日           >= INパラメータ.出庫日FROM
    ;
--
    -- ======================================
    -- カーソルFETCH
    -- ======================================
    FETCH cur_data BULK COLLECT INTO gt_report_data ;
--
    -- ======================================
    -- カーソルCLOSE
    -- ======================================
    CLOSE cur_data ;
-- 2008/09/26 H.Itou Add End T_S_533(PT対応)
--
-- 2009/01/14 v1.8 ADD START
--
    -- ====================================================
    -- 帳票データ作成
    -- ====================================================
--
    <<select_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- 初期値設定
      IF (i = 1) THEN
        lv_block_cd       := gt_report_data(i).block_cd ;    -- 前回レコード格納用（ブロックコード）
        lv_tmp_shipped_cd := gt_report_data(i).shipped_cd;   -- 前回レコード格納用（出庫元コード）
        lv_tmp_item_cd    := gt_report_data(i).item_cd;      -- 前回レコード格納用（品目コード）
        ln_report_data_fr := i;                              -- 元帳票データの格納用番号（自）
      END IF;
--      
      -- ブロックコード、出庫元コード、品目コードの組合せが一致する場合
      IF   (lv_block_cd       = gt_report_data(i).block_cd)
      AND  (lv_tmp_shipped_cd = gt_report_data(i).shipped_cd)
      AND  (lv_tmp_item_cd    = gt_report_data(i).item_cd)    THEN
        -- 不足数の集計
        ln_ins_qty         := ln_ins_qty + NVL(gt_report_data(i).ins_qty,0);
        -- 元帳票データの格納用番号（至）の設定
        ln_report_data_to  := i;
      -- ブロックコード、出庫元コード、品目コードの組合せが一致しない場合
      ELSE
        -- ブロックコード、出庫元コード、品目コード単位の不足数の集計が0以外
        IF (ln_ins_qty <> 0) THEN
          -- 出力データ（ワーク）に値を設定する（ループ内）
          <<report_data_in_loop>>
          FOR ln_line_loop_cnt IN ln_report_data_fr..ln_report_data_to LOOP
            ln_report_data_cnt := ln_report_data_cnt + 1;
-- 2009/01/20 v1.9 ADD START
-- 2009/01/21 v1.10 MOD START
--            -- 依頼No/移動Noが前のレコードと同じ場合
            -- 空白作成項目データの場合
--            IF  (lv_req_move_no = gt_report_data(ln_line_loop_cnt).req_move_no) THEN
            IF  (lv_block_cd_null       = gt_report_data(ln_line_loop_cnt).block_cd)          -- 空白項目作成用（ブロックコード）
            AND (lv_tmp_shipped_cd_null = gt_report_data(ln_line_loop_cnt).shipped_cd)        -- 空白項目作成用（出庫元コード）
            AND (lv_tmp_item_cd_null    = gt_report_data(ln_line_loop_cnt).item_cd)           -- 空白項目作成用（品目コード）
            AND (lv_req_move_no_null    = gt_report_data(ln_line_loop_cnt).req_move_no) THEN  -- 空白項目作成用（依頼No/移動No）
-- 2009/01/21 v1.10 MOD END
              gt_report_data(ln_line_loop_cnt).req_move_no     :=  NULL;      -- 依頼No/移動No
              gt_report_data(ln_line_loop_cnt).base_cd         :=  NULL;      -- 管轄拠点
              gt_report_data(ln_line_loop_cnt).base_nm         :=  NULL;      -- 管轄拠点名称
              gt_report_data(ln_line_loop_cnt).delivery_to_cd  :=  NULL;      -- 配送先/入庫先
              gt_report_data(ln_line_loop_cnt).delivery_to_nm  :=  NULL;      -- 配送先名称
              gt_report_data(ln_line_loop_cnt).description     :=  NULL;      -- 摘要
              gt_report_data(ln_line_loop_cnt).conf_req        :=  NULL;      -- 確認依頼
-- 2009/01/21 v1.10 MOD START
-- 2009/03/06 v1.12 Y.Kazama Add Start 本番障害#785
              gt_report_data(ln_line_loop_cnt).req_sum_qty     :=  NULL;      -- 依頼数
-- 2009/03/06 v1.12 Y.Kazama Add End   本番障害#785
--            -- 依頼No/移動Noが前のレコードと異なる場合
            -- 空白作成項目データでない場合
-- 2009/01/21 v1.10 MOD END
            ELSE
-- 2009/01/21 v1.10 MOD START
--              lv_req_move_no := gt_report_data(ln_line_loop_cnt).req_move_no;
              lv_block_cd_null       := gt_report_data(ln_line_loop_cnt).block_cd;        -- 空白項目作成用（ブロックコード）
              lv_tmp_shipped_cd_null := gt_report_data(ln_line_loop_cnt).shipped_cd;      -- 空白項目作成用（出庫元コード）
              lv_tmp_item_cd_null    := gt_report_data(ln_line_loop_cnt).item_cd;         -- 空白項目作成用（品目コード）
              lv_req_move_no_null    := gt_report_data(ln_line_loop_cnt).req_move_no;     -- 空白項目作成用（依頼No/移動No）
-- 2009/01/21 v1.10 MOD END
            END IF;
-- 2009/01/20 v1.9 ADD END
            lt_report_data(ln_report_data_cnt) := gt_report_data(ln_line_loop_cnt);
          END LOOP report_data_in_loop;
        END IF;
        -- 値設定
        lv_block_cd       := gt_report_data(i).block_cd ;      -- 前回レコード格納用（ブロックコード）
        lv_tmp_shipped_cd := gt_report_data(i).shipped_cd;     -- 前回レコード格納用（出庫元コード）
        lv_tmp_item_cd    := gt_report_data(i).item_cd;        -- 前回レコード格納用（品目コード）
        ln_ins_qty        := NVL(gt_report_data(i).ins_qty,0); 
        ln_report_data_fr := i;                                -- 元帳票データの格納用番号（自）
        ln_report_data_to := i;                                -- 元帳票データの格納用番号（至）
      END IF;
    END LOOP select_data_loop;
--
    -- 出庫元コードと品目コードの単位の不足数の集計が0以外
    IF (ln_ins_qty <> 0) THEN
      -- 出力データ（ワーク）に値を設定する（ループ外）
      <<report_data_out_loop>>
      FOR ln_line_loop_cnt IN ln_report_data_fr..ln_report_data_to LOOP
          ln_report_data_cnt := ln_report_data_cnt + 1;
-- 2009/01/20 v1.9 ADD START
-- 2009/01/21 v1.10 MOD START
--          -- 依頼No/移動Noが前のレコードと同じ場合
          -- 空白作成項目データの場合
--          IF  (lv_req_move_no = gt_report_data(ln_line_loop_cnt).req_move_no) THEN
          IF  (lv_block_cd_null       = gt_report_data(ln_line_loop_cnt).block_cd)          -- 空白項目作成用（ブロックコード）
          AND (lv_tmp_shipped_cd_null = gt_report_data(ln_line_loop_cnt).shipped_cd)        -- 空白項目作成用（出庫元コード）
          AND (lv_tmp_item_cd_null    = gt_report_data(ln_line_loop_cnt).item_cd)           -- 空白項目作成用（品目コード）
          AND (lv_req_move_no_null    = gt_report_data(ln_line_loop_cnt).req_move_no) THEN  -- 空白項目作成用（依頼No/移動No）
-- 2009/01/21 v1.10 MOD END
            gt_report_data(ln_line_loop_cnt).req_move_no     :=  NULL;      -- 依頼No/移動No
            gt_report_data(ln_line_loop_cnt).base_cd         :=  NULL;      -- 管轄拠点
            gt_report_data(ln_line_loop_cnt).base_nm         :=  NULL;      -- 管轄拠点名称
            gt_report_data(ln_line_loop_cnt).delivery_to_cd  :=  NULL;      -- 配送先/入庫先
            gt_report_data(ln_line_loop_cnt).delivery_to_nm  :=  NULL;      -- 配送先名称
            gt_report_data(ln_line_loop_cnt).description     :=  NULL;      -- 摘要
            gt_report_data(ln_line_loop_cnt).conf_req        :=  NULL;      -- 確認依頼
-- 2009/03/06 v1.12 Y.Kazama Add Start 本番障害#785
            gt_report_data(ln_line_loop_cnt).req_sum_qty     :=  NULL;      -- 依頼数
-- 2009/03/06 v1.12 Y.Kazama Add End   本番障害#785

          -- 依頼No/移動Noが前のレコードと異なる場合
          ELSE
-- 2009/01/21 v1.10 MOD START
--            lv_req_move_no := gt_report_data(ln_line_loop_cnt).req_move_no;
            lv_block_cd_null       := gt_report_data(ln_line_loop_cnt).block_cd;        -- 空白項目作成用（ブロックコード）
            lv_tmp_shipped_cd_null := gt_report_data(ln_line_loop_cnt).shipped_cd;      -- 空白項目作成用（出庫元コード）
            lv_tmp_item_cd_null    := gt_report_data(ln_line_loop_cnt).item_cd;         -- 空白項目作成用（品目コード）
            lv_req_move_no_null    := gt_report_data(ln_line_loop_cnt).req_move_no;     -- 空白項目作成用（依頼No/移動No）
-- 2009/01/21 v1.10 MOD END
          END IF;
-- 2009/01/20 v1.9 ADD END
          lt_report_data(ln_report_data_cnt) := gt_report_data(ln_line_loop_cnt);
      END LOOP report_data_out_loop;
    END IF;
--
    gt_report_data.DELETE;
    gt_report_data := lt_report_data;
-- 2009/01/14 v1.8 ADD END
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( cur_data%ISOPEN ) THEN
        CLOSE cur_data ;
      END IF ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( cur_data%ISOPEN ) THEN
        CLOSE cur_data ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( cur_data%ISOPEN ) THEN
        CLOSE cur_data ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data;
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XML生成処理
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
    ov_errbuf     OUT  VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT  VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT  VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ;   -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル変数 ***
    -- 前回レコード格納用
    lv_tmp_shipped_cd    type_report_data.shipped_cd%TYPE DEFAULT NULL ;    -- 出庫元コード
    lv_tmp_item_cd       type_report_data.item_cd%TYPE DEFAULT NULL ;       -- 品目コード
    lv_tmp_shipped_date  type_report_data.shipped_date%TYPE DEFAULT NULL ;  -- 出庫日
    lv_tmp_arrival_date  type_report_data.arrival_date%TYPE DEFAULT NULL ;  -- 着日
    lv_tmp_biz_type      type_report_data.biz_type%TYPE DEFAULT NULL ;      -- 業務種別
--
    -- タグ出力判定フラグ
    lb_dispflg_shipped_cd   BOOLEAN DEFAULT TRUE ;       -- 出庫元コード
    lb_dispflg_item_cd      BOOLEAN DEFAULT TRUE ;       -- 品目コード
    lb_dispflg_shipped_date BOOLEAN DEFAULT TRUE ;       -- 出庫日
    lb_dispflg_arrival_date BOOLEAN DEFAULT TRUE ;       -- 着日
    lb_dispflg_biz_type     BOOLEAN DEFAULT TRUE ;       -- 業務種別
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- -----------------------------------------------------
    -- ヘッダ情報設定
    -- -----------------------------------------------------
    prc_set_tag_data('root') ;
    prc_set_tag_data('data_info') ;
    prc_set_tag_data('report_id', gc_report_id);
    prc_set_tag_data('exec_time', TO_CHAR(SYSDATE, gc_date_fmt_all));
    prc_set_tag_data('dep_cd', gv_dept_cd);
    prc_set_tag_data('dep_nm', gv_dept_nm);
    prc_set_tag_data('shipped_date_from', TO_CHAR(gt_param.shipped_date_from ,gc_date_fmt_ymd_ja));
    prc_set_tag_data('shipped_date_to', TO_CHAR(gt_param.shipped_date_to ,gc_date_fmt_ymd_ja));
    prc_set_tag_data('lg_shipped_info') ;
--
    -- -----------------------------------------------------
    -- 帳票0件用XMLデータ作成
    -- -----------------------------------------------------
    IF (gt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg(gc_application_cmn, gc_msg_id_no_data) ;
--
      prc_set_tag_data('g_shipped_info') ;
      prc_set_tag_data('msg', ov_errmsg) ;
      prc_set_tag_data('/g_shipped_info') ;
    END IF ;
--
    -- -----------------------------------------------------
    -- XMLデータ作成
    -- -----------------------------------------------------
    <<set_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- ====================================================
      -- XMLデータ設定
      -- ====================================================
      -- ヘッダ部(出庫元グループ)
      IF (lb_dispflg_shipped_cd) THEN
        prc_set_tag_data('g_shipped_info') ;
        prc_set_tag_data('block_cd', gt_report_data(i).block_cd) ;
        prc_set_tag_data('block_nm', gt_report_data(i).block_nm) ;
        prc_set_tag_data('shipped_cd', gt_report_data(i).shipped_cd) ;
        prc_set_tag_data('shipped_nm', gt_report_data(i).shipped_nm) ;
        prc_set_tag_data('lg_item_info') ;
      END IF ;
--
      -- ヘッダ部(品目グループ)
      IF (lb_dispflg_item_cd) THEN
        prc_set_tag_data('g_item_info') ;
        prc_set_tag_data('item_cd', gt_report_data(i).item_cd) ;
        prc_set_tag_data('item_nm', gt_report_data(i).item_nm) ;
        prc_set_tag_data('lg_shipped_date_info') ;
      END IF ;
--
      -- ヘッダ部(出庫日グループ)
      IF (lb_dispflg_shipped_date) THEN
        prc_set_tag_data('g_shipped_date_info') ;
        prc_set_tag_data('shipped_date', fnc_chgdt_c(gt_report_data(i).shipped_date)) ;
        prc_set_tag_data('lg_req_move_info') ;
      END IF ;
--
      -- 業務種別 表示判定
      IF ((lv_tmp_biz_type != gt_report_data(i).biz_type) OR lb_dispflg_shipped_date) THEN
        lb_dispflg_biz_type := TRUE ;
      ELSE
        lb_dispflg_biz_type := FALSE ;
      END IF ;
--
      -- 着日 表示判定
      IF ((lv_tmp_arrival_date != gt_report_data(i).arrival_date) OR lb_dispflg_shipped_date) THEN
        lb_dispflg_arrival_date := TRUE ;
        lb_dispflg_biz_type := TRUE ;
      ELSE
        lb_dispflg_arrival_date := FALSE ;
      END IF ;
--
      -- 明細部(依頼No/移動Noグループ)
      prc_set_tag_data('g_req_move_info') ;
--
      IF (lb_dispflg_arrival_date) THEN
        -- 着日 1行前と値が異なる場合のみ表示
        prc_set_tag_data('arrive_date', fnc_chgdt_c(gt_report_data(i).arrival_date));
      END IF ;
--
      IF (lb_dispflg_biz_type) THEN
        -- 業務種別 1行前と値が異なる場合のみ表示
        prc_set_tag_data('biz_type', gt_report_data(i).biz_type);
      END IF ;
--
      prc_set_tag_data('req_move_no'     , gt_report_data(i).req_move_no);
      prc_set_tag_data('base_cd'         , gt_report_data(i).base_cd);
      prc_set_tag_data('base_nm'         , gt_report_data(i).base_nm);
      prc_set_tag_data('deli_to_cd'      , gt_report_data(i).delivery_to_cd);
      prc_set_tag_data('deli_to_nm'      , gt_report_data(i).delivery_to_nm);
      prc_set_tag_data('description'     , gt_report_data(i).description);
      prc_set_tag_data('confirm_req'     , gt_report_data(i).conf_req);
      prc_set_tag_data('de_prod_date'    , fnc_chgdt_c(gt_report_data(i).de_prod_date)) ;
      prc_set_tag_data('prod_date'       , gt_report_data(i).prod_date) ;
      prc_set_tag_data('best_before_date', gt_report_data(i).best_before_date) ;
      prc_set_tag_data('native_sign'     , gt_report_data(i).native_sign) ;
-- 2009/03/06 v1.12 Y.Kazama Del Start 本番障害#785
--      prc_set_tag_data('lot_no'          , gt_report_data(i).lot_no) ;
-- 2009/03/06 v1.12 Y.Kazama Del End   本番障害#785
      prc_set_tag_data('lot_status'      , gt_report_data(i).lot_status) ;
-- 2009/03/06 v1.12 Y.Kazama Add Start 本番障害#785
      prc_set_tag_data('req_sum_qty'     , gt_report_data(i).req_sum_qty) ;
-- 2009/03/06 v1.12 Y.Kazama Add End   本番障害#785
      prc_set_tag_data('req_qty'         , gt_report_data(i).req_qty) ;
      prc_set_tag_data('ins_qty'         , gt_report_data(i).ins_qty) ;
      prc_set_tag_data('/g_req_move_info') ;
--
      -- ====================================================
      -- 現在処理中のデータを保持
      -- ====================================================
      lv_tmp_shipped_cd   := gt_report_data(i).shipped_cd ;    -- 出庫元コード
      lv_tmp_item_cd      := gt_report_data(i).item_cd ;       -- 品目コード
      lv_tmp_shipped_date := gt_report_data(i).shipped_date ;  -- 出庫日
      lv_tmp_arrival_date := gt_report_data(i).arrival_date ;  -- 着日
      lv_tmp_biz_type     := gt_report_data(i).biz_type ;      -- 業務種別
--
      -- ====================================================
      -- 出力判定
      -- ====================================================
      IF (i < gt_report_data.COUNT) THEN
        -- 出庫日
        IF (lv_tmp_shipped_date = gt_report_data(i + 1).shipped_date) THEN
          lb_dispflg_shipped_date := FALSE ;
        ELSE
          lb_dispflg_shipped_date := TRUE ;
        END IF ;
--
        -- 品目コード
        IF (lv_tmp_item_cd = gt_report_data(i + 1).item_cd) THEN
          lb_dispflg_item_cd      := FALSE ;
        ELSE
          lb_dispflg_shipped_date := TRUE ;
          lb_dispflg_item_cd      := TRUE ;
        END IF ;
--
        -- 出庫元コード
        IF (lv_tmp_shipped_cd = gt_report_data(i + 1).shipped_cd) THEN
          lb_dispflg_shipped_cd   := FALSE ;
        ELSE
          lb_dispflg_shipped_date := TRUE ;
          lb_dispflg_item_cd      := TRUE ;
          lb_dispflg_shipped_cd   := TRUE ;
        END IF ;
      ELSE
          lb_dispflg_shipped_date := TRUE ; 
          lb_dispflg_item_cd      := TRUE ; 
          lb_dispflg_shipped_cd   := TRUE ; 
      END IF;
--
      -- ====================================================
      -- 終了タグ設定
      -- ====================================================
      IF (lb_dispflg_shipped_date) THEN
        prc_set_tag_data('/lg_req_move_info') ;
        prc_set_tag_data('/g_shipped_date_info') ;
      END IF;
--
      IF (lb_dispflg_item_cd) THEN
        prc_set_tag_data('/lg_shipped_date_info') ;
        prc_set_tag_data('/g_item_info') ;
      END IF;
--
      IF (lb_dispflg_shipped_cd) THEN
        prc_set_tag_data('/lg_item_info') ;
        prc_set_tag_data('/g_shipped_info') ;
      END IF;
--
    END LOOP set_data_loop;
--
    -- ====================================================
    -- 終了タグ設定
    -- ====================================================
    prc_set_tag_data('/lg_shipped_info') ;
    prc_set_tag_data('/data_info') ;
    prc_set_tag_data('/root') ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Function Name    : fnc_convert_into_xml
   * Description      : XMLデータ変換
   ***********************************************************************************/
  FUNCTION fnc_convert_into_xml(
    ir_xml  IN  xml_rec
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_data VARCHAR2(2000);
--
  BEGIN
--
    --データの場合
    IF (ir_xml.tag_type = 'D') THEN
      lv_data :=
    '<'|| ir_xml.tag_name || '><![CDATA[' || ir_xml.tag_value || ']]></' || ir_xml.tag_name || '>';
    ELSE
      lv_data := '<' || ir_xml.tag_name || '>';
    END IF ;
--
    RETURN(lv_data);
--
  END fnc_convert_into_xml;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT   VARCHAR2      -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT   VARCHAR2      -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT   VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain' ;  -- プログラム名
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
    ln_retcode       NUMBER ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- 初期処理
    -- ===============================================
    prc_initialize(
      ov_errbuf     => lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ===============================================
    -- 帳票データ取得処理
    -- ===============================================
    prc_get_report_data(
      ov_errbuf        => lv_errbuf       --エラー・メッセージ           --# 固定 #
     ,ov_retcode       => lv_retcode      --リターン・コード             --# 固定 #
     ,ov_errmsg        => lv_errmsg       --ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML生成処理
    -- ==================================================
    prc_create_xml_data(
      ov_errbuf        => lv_errbuf       --エラー・メッセージ           --# 固定 #
     ,ov_retcode       => lv_retcode      --リターン・コード             --# 固定 #
     ,ov_errmsg        => lv_errmsg       --ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML出力処理
    -- ==================================================
    -- XMLヘッダ部出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>') ;
--
    -- XMLデータ部出力
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- XMLデータ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, fnc_convert_into_xml(gt_xml_data_table(i))) ;
    END LOOP xml_loop ;
--
    --XMLデータ削除
    gt_xml_data_table.DELETE ;
--
    IF ((lv_retcode = gv_status_warn) AND (gt_report_data.COUNT = 0)) THEN
      RAISE no_data_expt ;
    END IF ;
--
  EXCEPTION
    -- *** 帳票0件例外ハンドラ ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
     errbuf                 OUT    VARCHAR2      -- エラー・メッセージ  --# 固定 #
    ,retcode                OUT    VARCHAR2      -- リターン・コード    --# 固定 #
    ,iv_block1              IN     VARCHAR2      -- 01:ブロック1
    ,iv_block2              IN     VARCHAR2      -- 02:ブロック2
    ,iv_block3              IN     VARCHAR2      -- 03:ブロック3
    ,iv_tighten_date        IN     VARCHAR2      -- 04:締め実施日
    ,iv_tighten_time_from   IN     VARCHAR2      -- 05:締め実施時間From
    ,iv_tighten_time_to     IN     VARCHAR2      -- 06:締め実施時間To
    ,iv_shipped_cd          IN     VARCHAR2      -- 07:出庫元
    ,iv_item_cd             IN     VARCHAR2      -- 08:品目
    ,iv_shipped_date_from   IN     VARCHAR2      -- 09:出庫日From
    ,iv_shipped_date_to     IN     VARCHAR2      -- 10:出庫日To
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- 変数初期設定
    -- ===============================================
    -- 入力パラメータをグローバル変数に保持
    gt_param.block1            := iv_block1 ;                           -- 01:ブロック1
    gt_param.block2            := iv_block2 ;                           -- 02:ブロック2
    gt_param.block3            := iv_block3 ;                           -- 03:ブロック3
    gt_param.tighten_date      := fnc_chgdt_d(iv_tighten_date) ;        -- 04:締め実施日
    gt_param.tighten_time_from := iv_tighten_time_from ;                -- 05:締め実施時間From
    gt_param.tighten_time_to   := iv_tighten_time_to ;                  -- 06:締め実施時間To
    gt_param.shipped_cd        := iv_shipped_cd ;                       -- 07:出庫元
    gt_param.item_cd           := iv_item_cd ;                          -- 08:品目
    gt_param.shipped_date_from := fnc_chgdt_d(iv_shipped_date_from) ;   -- 09:出庫日From
    gt_param.shipped_date_to   := fnc_chgdt_d(iv_shipped_date_to) ;     -- 10:出庫日To
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf    => lv_errbuf       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode      -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part|| SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || SQLERRM ;
      retcode := gv_status_error ;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh620001c;
/
