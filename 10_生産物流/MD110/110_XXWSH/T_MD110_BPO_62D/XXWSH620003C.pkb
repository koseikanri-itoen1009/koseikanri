CREATE OR REPLACE PACKAGE BODY xxwsh620003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620003c(body)
 * Description      : 入庫依頼表
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_620
 * MD.070           : 入庫依頼表 T_MD070_BPO_62D
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_initialize         PROCEDURE : 初期処理
 *  prc_get_report_data    PROCEDURE : 帳票データ取得処理
 *  prc_create_xml_data    PROCEDURE : XML生成処理
 *  fnc_convert_into_xml   FUNCTION  : XMLデータ変換
 *  submain                PROCEDURE : メイン処理プロシージャ
 *  main                   PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/13    1.0   Nozomi Kashiwagi 新規作成
 *  2008/06/04    1.1   Jun Nakada       確定処理未実施(通知日時=NULL)の場合の出力制御
 *
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
  gv_pkg_name                CONSTANT  VARCHAR2(100) := 'xxwsh620003c' ;     -- パッケージ名
  gc_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620003T' ;      -- 帳票ID
  -- 帳票タイトル
  gc_report_title_plan       CONSTANT  VARCHAR2(10) := '入庫予定表' ;        -- 入庫予定表
  gc_report_title_decide     CONSTANT  VARCHAR2(10) := '入庫依頼表' ;        -- 入庫依頼表
  -- 移動タイプ
  gc_mov_type_not_ship       CONSTANT  VARCHAR2(5)  := '2' ;                 -- 積送なし
  -- 移動ステータス
  gc_status_reqed            CONSTANT  VARCHAR2(2)  := '02' ;                -- 依頼済
  gc_status_not              CONSTANT  VARCHAR2(2)  := '99' ;                -- 取消
  -- 文書タイプ
  gc_doc_type_code_mv        CONSTANT  VARCHAR2(2)  := '20' ;                -- 移動
  -- レコードタイプ
  gc_rec_type_code_ins       CONSTANT  VARCHAR2(2)  := '10' ;                -- 指示
  -- 予定確定区分
  gc_plan_decide_p           CONSTANT  VARCHAR2(1)  := '1' ;                 -- 予定
  gc_plan_decide_d           CONSTANT  VARCHAR2(1)  := '2' ;                 -- 確定
  -- 通知ステータス
  gc_notif_status_notify     CONSTANT  VARCHAR2(2)  := '10' ;                -- 未通知
  gc_notif_status_not_notify CONSTANT  VARCHAR2(2)  := '20' ;                -- 再通知要
  gc_notif_status_notified   CONSTANT  VARCHAR2(2)  := '40' ;                -- 確定通知済
  -- ユーザー区分
  gc_user_kbn_inside         CONSTANT  VARCHAR2(1)  := '1' ;                 -- 内部
  gc_user_kbn_outside        CONSTANT  VARCHAR2(1)  := '2' ;                 -- 外部
  -- 商品区分
  gc_prod_cd_drink           CONSTANT  VARCHAR2(1)  := '2' ;                 -- ドリンク
  gc_item_cd_prdct           CONSTANT  VARCHAR2(1)  := '5' ;                 -- 製品
  gc_item_cd_material        CONSTANT  VARCHAR2(1)  := '1' ;                 -- 原料
  gc_item_cd_prdct_half      CONSTANT  VARCHAR2(1)  := '4' ;                 -- 半製品
  gc_item_cd_shizai          CONSTANT  VARCHAR2(1)  := '2' ;                 -- 資材
  -- ロット管理
  gc_lot_ctl_manage          CONSTANT  VARCHAR2(1)  := '1' ;                 -- ロット管理されている
  -- 日付フォーマット
  gc_date_fmt_all            CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- 年月日時分秒
  gc_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;            -- 年月日
  gc_date_fmt_hh24mi         CONSTANT  VARCHAR2(10) := 'HH24:MI' ;               -- 時分
  gc_date_fmt_ymd_ja         CONSTANT  VARCHAR2(20) := 'YYYY"年"MM"月"DD"日' ;   -- 時分
  -- 日付
  gc_date_start              CONSTANT  VARCHAR2(10) := '1900/01/01' ;
  gc_date_end                CONSTANT  VARCHAR2(10) := '9999/12/31' ;
  -- 時間
  gc_time_start              CONSTANT  VARCHAR2(5) := '00:00' ;
  gc_time_end                CONSTANT  VARCHAR2(5) := '23:59' ;
  -- ADD START 2008/06/04
  gc_time_ss_start           CONSTANT  VARCHAR2(3) := '00' ;
  gc_time_ss_end             CONSTANT  VARCHAR2(3) := '59' ;
  -- ADD END 2008/06/04
  -- 出力タグ
  gc_tag_type_tag            CONSTANT  VARCHAR2(1)  := 'T' ;                 -- グループタグ
  gc_tag_type_data           CONSTANT  VARCHAR2(1)  := 'D' ;                 -- データタグ
  -- 新規修正フラグ
  gc_new_modify_flg_mod      CONSTANT  VARCHAR2(1)  := 'M' ;                 -- 修正
  gc_asterisk                CONSTANT  VARCHAR2(1)  := '*' ;                 -- 固定値「*」
  ------------------------------
  -- プロファイル関連
  ------------------------------
  gc_prof_name_item_div      CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_DIV_SECURITY' ; -- 商品区分
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  --アプリケーション名
  gc_application_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH' ;             -- ｱﾄﾞｵﾝ:出荷･引当･配車
  gc_application_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN' ;             -- ｱﾄﾞｵﾝ:出荷･引当･配車
  --メッセージID
  gc_msg_id_required         CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12102' ;   -- ﾊﾟﾗﾒｰﾀ未入力ｴﾗｰ
  gc_msg_id_no_data          CONSTANT  VARCHAR2(15) := 'APP-XXCMN-10122' ;   -- 帳票0件エラー
  gc_msg_id_not_get_prof     CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12301' ;   -- ﾌﾟﾛﾌｧｲﾙ取得ｴﾗｰ
  gc_msg_id_prm_chk          CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12256' ;   -- ﾊﾟﾗﾒｰﾀﾁｪｯｸｴﾗｰ
  --メッセージ-トークン名
  gc_msg_tkn_nm_parmeta      CONSTANT  VARCHAR2(10) := 'PARMETA' ;           -- パラメータ名
  gc_msg_tkn_nm_prof         CONSTANT  VARCHAR2(10) := 'PROF_NAME' ;         -- プロファイル名
  --メッセージ-トークン値
  gc_msg_tkn_val_parmeta     CONSTANT  VARCHAR2(20) := '確定通知実施日' ;
  gc_msg_tkn_val_prof_prod   CONSTANT  VARCHAR2(30) := 'XXCMN：商品区分(セキュリティ)' ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  ------------------------------
  -- 入力パラメータ関連
  ------------------------------
  -- 入力パラメータ格納用レコード
  TYPE rec_param_data IS RECORD(
     dept                  VARCHAR2(10)    -- 01:部署
    ,plan_decide_kbn       VARCHAR2(1)     -- 02:予定/確定区分
    ,ship_from             DATE            -- 03:出庫日From
    ,ship_to               DATE            -- 04:出庫日To
  -- MOD START 2008/06/04 NAKADA 型の変更(DATE >> VARCHAR2)
    ,notif_date            VARCHAR2(10)    -- 05:確定通知実施日
  -- MOD END   2008/06/04 NAKADA
    ,notif_time_from       VARCHAR2(5)     -- 06:確定通知実施時間From
    ,notif_time_to         VARCHAR2(5)     -- 07:確定通知実施時間To
    ,block1                VARCHAR2(5)     -- 08:ブロック1
    ,block2                VARCHAR2(5)     -- 09:ブロック2
    ,block3                VARCHAR2(5)     -- 10:ブロック3
    ,ship_to_locat_code    VARCHAR2(4)     -- 11:入庫先
    ,shipped_locat_code    VARCHAR2(4)     -- 12:出庫元
    ,freight_carrier_code  VARCHAR2(4)     -- 13:運送業者
    ,delivery_no           VARCHAR2(12)    -- 14:配送No
    ,mov_num               VARCHAR2(12)    -- 15:移動No
    ,online_kbn            VARCHAR2(1)     -- 16:オンライン対象区分
    ,item_kbn              VARCHAR2(1)     -- 17:品目区分
    ,arrival_date_from     DATE            -- 18:着日From
    ,arrival_date_to       DATE            -- 19:着日To
  );
  type_rec_param_data   rec_param_data ;
--
  ------------------------------
  -- 出力データ関連
  ------------------------------
  -- レコード宣言用
  xcs     xxwsh_carriers_schedule%ROWTYPE ;          -- 配車配送計画(アドオン)
  xmrih   xxinv_mov_req_instr_headers%ROWTYPE ;      -- 移動依頼/指示ヘッダ（アドオン）
  xmril   xxinv_mov_req_instr_lines%ROWTYPE ;        -- 移動依頼/指示明細（アドオン）
  xmld    xxinv_mov_lot_details%ROWTYPE ;            -- 移動ロット詳細(アドオン)
  xilv1   xxcmn_item_locations2_v%ROWTYPE ;          -- OPM保管場所情報VIEW(入)
  xilv2   xxcmn_item_locations2_v%ROWTYPE ;          -- OPM保管場所情報VIEW(出)
  xcv     xxcmn_carriers2_v%ROWTYPE ;                -- 運送業者情報VIEW
  ximv    xxcmn_item_mst2_v%ROWTYPE ;                -- OPM品目情報VIEW2
  ilm     ic_lots_mst%ROWTYPE ;                      -- OPMロットマスタ
  xicv4   xxcmn_item_categories4_v%ROWTYPE ;         -- OPM品目カテゴリ割当情報VIEW4
  xsmv    xxwsh_ship_method2_v%ROWTYPE ;             -- 配送区分情報VIEW2
--
  -- 出力データ格納用レコード
  TYPE rec_report_data IS RECORD(
     ship_to_locat_code     xmrih.ship_to_locat_code%TYPE     -- 入庫先(コード)
    ,ship_to_locat_name     xilv1.description%TYPE            -- 入庫先名称
    ,schedule_arrival_date  xmrih.schedule_arrival_date%TYPE  -- 着日
    ,item_class_name        xicv4.item_class_name%TYPE        -- 品目区分
    ,new_modify_flg         xmrih.new_modify_flg%TYPE         -- 新規修正フラグ
    ,schedule_ship_date     xmrih.schedule_ship_date%TYPE     -- 出庫日
    ,delivery_no            xmrih.delivery_no%TYPE            -- 配送No
    ,shipping_method_code   xmrih.shipping_method_code%TYPE   -- 配送区分
    ,shipping_method_name   xsmv.ship_method_meaning%TYPE     -- 配送区分（名称）
    ,career_id              xmrih.career_id%TYPE              -- 運送業者
    ,career_name            xcv.party_name%TYPE               -- 運送業者名称
    ,shipped_locat_code     xmrih.shipped_locat_code%TYPE     -- 出庫元
    ,shipped_locat_name     xilv2.description%TYPE            -- 出庫元(名称)
    ,prev_delivery_no       xmrih.prev_delivery_no%TYPE       -- 前回配送No
    ,mov_num                xmrih.mov_num%TYPE                -- 移動No
    ,arrival_time_from      xmrih.arrival_time_from%TYPE      -- 着荷時間From
    ,arrival_time_to        xmrih.arrival_time_to%TYPE        -- 着荷時間To
    ,description            xmrih.description%TYPE            -- 摘要
    ,batch_no               xmrih.batch_no%TYPE               -- 手配No
    ,item_code              xmril.item_code%TYPE              -- 品目(コード)
    ,item_name              ximv.item_desc1%TYPE              -- 品目(名称)
    ,net                    ximv.net%TYPE                     -- 重量(NET)
    ,lot_no                 xmld.lot_no%TYPE                  -- ロットNo
    ,prodct_date            ilm.attribute1%TYPE               -- 製造日
    ,best_before_date       ilm.attribute3%TYPE               -- 賞味期限
    ,uniqe_sign             ilm.attribute2%TYPE               -- 固有記号
    ,num_qty                NUMBER                            -- 入数
    ,quantity               NUMBER                            -- 数量
    ,conv_unit              VARCHAR2(3)                       -- 入出庫換算単位
  );
  type_report_data      rec_report_data;
  TYPE list_report_data IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_param              rec_param_data ;      -- 入力パラメータ情報
  gt_report_data        list_report_data ;    -- 出力データ
  gt_xml_data_table     XML_DATA ;            -- XMLデータ
  gv_report_title       VARCHAR2(20) ;        -- 帳票タイトル
  gv_dept_cd            VARCHAR2(10) ;        -- 担当部署
  gv_dept_nm            VARCHAR2(14) ;        -- 担当者
  gv_uom_weight         VARCHAR2(3);          -- 出荷重量単位
  gv_uom_capacity       VARCHAR2(3);          -- 出荷容積単位
  gv_prod_kbn           VARCHAR2(1);          -- 商品区分
  gd_common_sysdate     DATE;                 -- システム日付
  gd_notif_date_from    DATE;                 -- 確定ブロック実施日時_FROM
  gd_notif_date_to      DATE;                 -- 確定ブロック実施日時_TO
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
    prm_check_expt     EXCEPTION ;     -- パラメータチェック例外
    get_prof_expt      EXCEPTION ;     -- プロファイル取得例外
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
    -- 変数初期設定
    -- ===============================================
    gd_common_sysdate := SYSDATE ;    -- システム日付
--
    -- ====================================================
    -- パラメータチェック
    -- ====================================================
    -- 予定/確定区分チェック
    IF (gt_param.plan_decide_kbn = gc_plan_decide_d) THEN
      IF (gt_param.notif_date IS NULL) THEN
        -- メッセージセット
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                              ,gc_msg_id_required
                                              ,gc_msg_tkn_nm_parmeta
                                              ,gc_msg_tkn_val_parmeta
                                             ) ;
        RAISE prm_check_expt ;
      END IF ;
    END IF ;
--
    -- 確定通知実施日、確定通知実施時間チェック
    IF ((gt_param.notif_date IS NULL)
      AND ((gt_param.notif_time_from IS NOT NULL) OR (gt_param.notif_time_to IS NOT NULL))) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh, gc_msg_id_prm_chk ) ;
      RAISE prm_check_expt ;
    END IF;
--
    -- ====================================================
    -- プロファイル値取得
    -- ====================================================
    -- 職責：商品区分(セキュリティ)取得
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
    -- ADD START 2008/06/04 NAKADA
    -- 確定通知実施日、確定通知実施時間の編集
    gd_notif_date_from
      := TO_DATE(NVL(gt_param.notif_date, gc_date_start)
                 || ' '
                 || NVL(gt_param.notif_time_from, gc_time_start)
                 || ':'
                 || gc_time_ss_start
                , gc_date_fmt_all);
    gd_notif_date_to
      := TO_DATE(NVL(gt_param.notif_date, gc_date_end)
                 || ' '
                 || NVL(gt_param.notif_time_to, gc_time_end)
                 || ':'
                 || gc_time_ss_end
                , gc_date_fmt_all);
    -- ADD END 2008/06/04 NAKADA
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
    CURSOR cur_main_data
    IS
      SELECT
             xmrih.ship_to_locat_code      AS  ship_to_locat_code        -- 入庫先(コード)
            ,xilv1.description             AS  description_in            -- 入庫先名称
            ,xmrih.schedule_arrival_date   AS  schedule_arrival_date     -- 着日
            ,xicv4.item_class_name         AS  item_class_name           -- 品目区分
            ,CASE
              WHEN (xmrih.new_modify_flg = gc_new_modify_flg_mod)
                THEN gc_asterisk
              ELSE  NULL
             END                           AS  new_modify_flg            -- 新規修正フラグ
            ,xmrih.schedule_ship_date      AS  schedule_ship_date        -- 出庫日
            ,xmrih.delivery_no             AS  delivery_no               -- 配送No
            ,xmrih.shipping_method_code    AS  shipping_method_code      -- 配送区分
            ,xsmv.ship_method_meaning      AS  shipping_method_name      -- 配送区分(名称)
            ,xmrih.career_id               AS  career_id                 -- 運送業者
            ,xcv.party_name                AS  career_name               -- 運送業者名称
            ,xmrih.shipped_locat_code      AS  shipped_locat_code        -- 出庫元
            ,xilv2.description             AS  description_out           -- 出庫元(名称)
            ,xmrih.prev_delivery_no        AS  prev_delivery_no          -- 前回配送No
            ,xmrih.mov_num                 AS  mov_num                   -- 移動No
            ,xmrih.arrival_time_from       AS  arrival_time_from         -- 着荷時間From
            ,xmrih.arrival_time_to         AS  arrival_time_to           -- 着荷時間To
            ,xmrih.description             AS  description               -- 摘要
            ,xmrih.batch_no                AS  batch_no                  -- 手配No
            ,xmril.item_code               AS  item_code                 -- 品目(コード)
            ,ximv.item_short_name          AS  item_name                 -- 品目(名称)
            ,ximv.net                      AS  net                       -- NET
            ,CASE
              WHEN (xmril.reserved_quantity IS NOT NULL) THEN xmld.lot_no
              ELSE NULL
             END                           AS  lot_no                    -- ロットNo
            ,ilm.attribute1                AS  prodct_date               -- 製造日
            ,ilm.attribute3                AS  best_before_date          -- 賞味期限
            ,ilm.attribute2                AS  uniqe_sign                -- 固有記号
            ,CASE
              -- 製品の場合
              WHEN ((xicv4.item_class_code = gc_item_cd_prdct) 
                AND (ximv.lot_ctl = gc_lot_ctl_manage)
                AND (ilm.attribute6 IS NOT NULL)
              ) THEN ximv.num_of_cases
              -- その他の品目の場合
              WHEN (((xicv4.item_class_code = gc_item_cd_material) 
                OR  (xicv4.item_class_code = gc_item_cd_prdct_half))
                AND (ximv.lot_ctl = gc_lot_ctl_manage)
                AND (ilm.attribute6 IS NOT NULL)
              ) THEN ilm.attribute6
              -- 在庫入数が設定されていない,資材他,ロット管理していない場合
              WHEN ((xicv4.item_class_code = gc_item_cd_shizai)
                OR  (ilm.attribute6 IS NULL)
                OR  (ximv.lot_ctl <> gc_lot_ctl_manage)
              ) THEN ximv.frequent_qty
             END                           AS  num_qty                   -- 入数
            ,CASE
               -- 引当されている場合
               WHEN (xmril.reserved_quantity IS NOT NULL) THEN (
                 CASE 
                  WHEN ( xicv4.prod_class_code = gc_prod_cd_drink
                     AND xicv4.item_class_code = gc_item_cd_prdct
                     AND ximv.conv_unit IS NOT NULL
                  ) THEN (xmld.actual_quantity / TO_NUMBER(
                                                   CASE WHEN ximv.num_of_cases > 0 
                                                          THEN  ximv.num_of_cases
                                                        ELSE TO_CHAR(1)
                                                   END)
                         )
                  ELSE xmld.actual_quantity
                 END
               )
               -- 引当されていない場合
               WHEN ((xmril.reserved_quantity IS NULL) OR (xmril.reserved_quantity = 0)) THEN (
                 CASE 
                  WHEN ( xicv4.prod_class_code = gc_prod_cd_drink
                     AND xicv4.item_class_code = gc_item_cd_prdct
                     AND ximv.conv_unit IS NOT NULL
                  ) THEN (xmril.instruct_qty / TO_NUMBER(
                                                   CASE WHEN ximv.num_of_cases > 0 
                                                          THEN  ximv.num_of_cases
                                                        ELSE TO_CHAR(1)
                                                   END)
                         )
                  ELSE xmril.instruct_qty
                 END
               )
             END                           AS  quantity                  --数量
            ,CASE 
              WHEN ( xicv4.prod_class_code = gc_prod_cd_drink
                 AND xicv4.item_class_code = gc_item_cd_prdct
                 AND ximv.conv_unit IS NOT NULL
              ) THEN ximv.conv_unit
              ELSE ximv.item_um
             END                           AS  conv_unit                 --入出庫換算単位
      FROM
             xxwsh_carriers_schedule        xcs       -- 配車配送計画(アドオン)
            ,xxinv_mov_req_instr_headers    xmrih     -- 移動依頼/指示ヘッダ（アドオン）
            ,xxinv_mov_req_instr_lines      xmril     -- 移動依頼/指示明細（アドオン）
            ,xxinv_mov_lot_details          xmld      -- 移動ロット詳細(アドオン)
            ,xxcmn_item_locations2_v        xilv1     -- OPM保管場所情報VIEW(入)
            ,xxcmn_item_locations2_v        xilv2     -- OPM保管場所情報VIEW(出)
            ,xxcmn_carriers2_v              xcv       -- 運送業者情報VIEW
            ,xxcmn_item_mst2_v              ximv      -- OPM品目情報VIEW2
            ,ic_lots_mst                    ilm       -- OPMロットマスタ
            ,xxcmn_item_categories4_v       xicv4     -- OPM品目カテゴリ割当情報VIEW4
            ,fnd_user                       fu        -- ユーザーマスタ
            ,per_all_people_f               papf      -- 従業員マスタ
            ,xxwsh_ship_method2_v           xsmv      -- 配送区分情報VIEW2
      WHERE
        ----------------------------------------------------------------------------------
        -- ヘッダ情報
             xmrih.mov_num               =  NVL(gt_param.mov_num, xmrih.mov_num)
        AND  xmrih.delivery_no           =  xcs.delivery_no(+)
        AND  (gt_param.delivery_no IS NULL
          OR  xmrih.delivery_no = gt_param.delivery_no
        )
        AND  xmrih.mov_type             <>  gc_mov_type_not_ship
        AND  xmrih.status               >=  gc_status_reqed
        AND  xmrih.status               <>  gc_status_not
        AND  (gt_param.dept IS NULL
          OR  xmrih.instruction_post_code = gt_param.dept
        )
        ----------------------------------------------------------------------------------
        -- 出庫日From～To、着日From～To
        AND  xmrih.schedule_ship_date  >= gt_param.ship_from
        AND  (gt_param.ship_to IS NULL
          OR  xmrih.schedule_ship_date <= gt_param.ship_to
        )
        AND  (gt_param.arrival_date_from IS NULL
          OR  xmrih.schedule_arrival_date >= gt_param.arrival_date_from
        )
        AND  (gt_param.arrival_date_to IS NULL
          OR  xmrih.schedule_arrival_date <= gt_param.arrival_date_to
        )
        ----------------------------------------------------------------------------------
        -- 入庫先情報
        AND  xmrih.ship_to_locat_id      =  xilv1.inventory_location_id
        AND  ( (gt_param.online_kbn IS NULL)
            OR (xilv1.eos_control_type = gt_param.online_kbn)
        )
        AND  (
              (xilv1.distribution_block = gt_param.block1)
          OR  (xilv1.distribution_block = gt_param.block2)
          OR  (xilv1.distribution_block = gt_param.block3)
          OR  (xmrih.ship_to_locat_code = gt_param.ship_to_locat_code)
          OR  ((gt_param.block1 IS NULL) AND (gt_param.block2 IS NULL) AND (gt_param.block3 IS NULL)
           AND (gt_param.ship_to_locat_code IS NULL)
          )
        )
        ----------------------------------------------------------------------------------
        -- 出庫元情報
        AND  xmrih.shipped_locat_id    =  xilv2.inventory_location_id
        AND  ((gt_param.shipped_locat_code IS NULL)
            OR (xmrih.shipped_locat_code = gt_param.shipped_locat_code)
        )
        ----------------------------------------------------------------------------------
        -- 運送業者情報
        AND  ((gt_param.freight_carrier_code IS NULL)
            OR (xmrih.freight_carrier_code = gt_param.freight_carrier_code)
        )
        AND  xmrih.career_id        =  xcv.party_id(+)
        AND  (xcv.party_id IS NULL
          OR (xcv.start_date_active <= xmrih.schedule_ship_date
            AND  (xcv.end_date_active >= xmrih.schedule_ship_date
              OR  xcv.end_date_active IS NULL
            )
          )
        )
        ----------------------------------------------------------------------------------
        -- 確定通知実施日
        -- MOD START 2008/06/04 NAKADA   パラメータ実施日未入力で実施日時が未設定の場合も出力
        --                               その他の場合には、パラメータの入力条件に従って抽出。
        AND  ((gt_param.notif_date IS NULL AND
               xmrih.notif_date IS NULL)
               OR
              (xmrih.notif_date >= gd_notif_date_from AND
               xmrih.notif_date >= gd_notif_date_from)
        )
        -- MOD END   2008/06/04 NAKADA
        ----------------------------------------------------------------------------------
        -- 明細情報
        AND  xmrih.mov_hdr_id         =  xmril.mov_hdr_id
        AND  xmril.item_id            =  ximv.item_id
        AND  ximv.start_date_active  <=  xmrih.schedule_ship_date
        AND (ximv.end_date_active    >=  xmrih.schedule_ship_date
          OR ximv.end_date_active IS NULL
        )
        ----------------------------------------------------------------------------------
        -- OPM品目カテゴリ割当情報
        AND  ximv.item_id                =  xicv4.item_id
        AND  (gt_param.item_kbn IS NULL
          OR  xicv4.item_class_code = gt_param.item_kbn
        )
        AND  xicv4.prod_class_code = gv_prod_kbn
        ----------------------------------------------------------------------------------
        -- 移動ロット詳細情報
        AND  xmril.mov_line_id           =  xmld.mov_line_id(+)
        AND  xmld.document_type_code(+)  =  gc_doc_type_code_mv
        AND  xmld.record_type_code(+)    =  gc_rec_type_code_ins
        AND  xmld.lot_id                 =  ilm.lot_id(+)
        AND  xmld.item_id                =  ilm.item_id(+)
        ----------------------------------------------------------------------------------
        -- 配送区分情報
        AND  xsmv.ship_method_code       =  xmrih.shipping_method_code
        ----------------------------------------------------------------------------------
        -- 予定確定区分
        AND  (
              -- 予定の場合
              ((gt_param.plan_decide_kbn = gc_plan_decide_p)
                AND  (xmrih.notif_status = gc_notif_status_notify
                  OR  xmrih.notif_status = gc_notif_status_not_notify)
              )
              -- 確定の場合
          OR  ((gt_param.plan_decide_kbn = gc_plan_decide_d)
                AND  (xmrih.notif_status = gc_notif_status_notified)
              )
        )
        ----------------------------------------------------------------------------------
        -- ユーザー情報の抽出
        AND  fu.user_id                  =  FND_GLOBAL.USER_ID
        AND  papf.person_id            =  fu.employee_id
        AND  (
              -- 内部ユーザーの場合
              (papf.attribute3  = gc_user_kbn_inside)
              -- 外部ユーザーの場合
          OR  ((papf.attribute3 = gc_user_kbn_outside)
                AND (
                      -- 倉庫業者の場合
                      (((papf.attribute4 IS NOT NULL) AND (papf.attribute5 IS NULL))
                        AND ( xilv1.purchase_code = papf.attribute4 
                          OR  xilv2.purchase_code = papf.attribute4)
                      )
                      -- 倉庫兼運送業者の場合
                  OR  (((papf.attribute4 IS NOT NULL)  AND  (papf.attribute5 IS NOT NULL))
                        AND ( xmrih.freight_carrier_code = papf.attribute5
                          OR  xilv1.purchase_code        = papf.attribute4
                          OR  xilv2.purchase_code        = papf.attribute4)
                      )
                      -- 運送業者の場合
                  OR  (((papf.attribute4 IS NULL) AND (papf.attribute5 IS NOT NULL))
                        AND  xmrih.freight_carrier_code = papf.attribute5
                      )
                )
          )
        )
      ORDER BY
             ship_to_locat_code     ASC   -- 入庫先
            ,schedule_arrival_date  ASC   -- 入庫予定日
            ,shipped_locat_code     ASC   -- 出庫元
            ,schedule_ship_date     ASC   -- 出庫予定日
            ,delivery_no            ASC   -- 配送No
            ,mov_num                ASC   -- 移動番号
            ,item_code              ASC   -- 品目コード
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
    -- ====================================================
    -- 帳票タイトル判定
    -- ====================================================
    -- 予定/確定区分が「予定」の場合
    IF (gt_param.plan_decide_kbn = gc_plan_decide_p) THEN
      gv_report_title := gc_report_title_plan;
--
    -- 予定/確定区分が「確定」の場合
    ELSE
      gv_report_title := gc_report_title_decide;
    END IF ;
--
    -- ====================================================
    -- 担当者情報取得
    -- ====================================================
    -- 担当部署
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID), 1, 10) ;
    -- 担当者
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14) ;
--
    -- ====================================================
    -- 帳票データ取得
    -- ====================================================
    -- カーソルオープン
    OPEN cur_main_data ;
    -- バルクフェッチ
    FETCH cur_main_data BULK COLLECT INTO gt_report_data ;
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
  END prc_get_report_data;
--
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- 前回レコード格納用
    lv_tmp_nyuko_cd             type_report_data.ship_to_locat_code%TYPE ;    -- 入庫先コード毎情報
    lv_tmp_nyuko_date           type_report_data.schedule_arrival_date%TYPE ; -- 入庫予定日毎情報
    lv_tmp_delivery_no          type_report_data.delivery_no%TYPE ;           -- 配送No毎情報
    lv_tmp_move_no              type_report_data.mov_num%TYPE ;               -- 移動No毎情報
    lv_tmp_item_code            type_report_data.item_code%TYPE ;             -- 品目コード毎情報
    -- タグ出力判定フラグ
    lb_dispflg_nyuko_cd         BOOLEAN := TRUE ;       -- 入庫先コード毎情報
    lb_dispflg_nyuko_date       BOOLEAN := TRUE ;       -- 入庫予定日毎情報
    lb_dispflg_delivery_no      BOOLEAN := TRUE ;       -- 配送No毎情報
    lb_dispflg_move_no          BOOLEAN := TRUE ;       -- 移動No毎情報
    lb_dispflg_item_code        BOOLEAN := TRUE ;       -- 品目コード毎情報
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : タグ情報設定処理
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2                 -- タグ名
      ,ivsub_tag_value      IN  VARCHAR2                 -- データ
      ,ivsub_tag_type       IN  VARCHAR2  DEFAULT NULL   -- データ
    )IS
      ln_data_index  NUMBER ;    -- XMLデータを設定するインデックス
    BEGIN
      ln_data_index := gt_xml_data_table.COUNT + 1 ;
      
      gt_xml_data_table(ln_data_index).tag_name := ivsub_tag_name ;
      
      IF ((ivsub_tag_value IS NULL) AND (ivsub_tag_type = gc_tag_type_tag)) THEN
        -- タグ出力
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
      ELSE
        -- データ出力
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
        gt_xml_data_table(ln_data_index).tag_value := ivsub_tag_value;
      END IF;
    END prcsub_set_xml_data ;
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : タグ情報設定処理(開始・終了タグ用)
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2  -- タグ名
    )IS
    BEGIN
      prcsub_set_xml_data(ivsub_tag_name, NULL, gc_tag_type_tag);
    END prcsub_set_xml_data ;
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
    -- 変数初期設定
    -- -----------------------------------------------------
    gt_xml_data_table.DELETE ;
    lv_tmp_nyuko_cd    := NULL ;
    lv_tmp_nyuko_date  := NULL ;
    lv_tmp_delivery_no := NULL ;
    lv_tmp_move_no     := NULL ;
    lv_tmp_item_code   := NULL ;
--
    -- -----------------------------------------------------
    -- ヘッダ情報設定
    -- -----------------------------------------------------
    prcsub_set_xml_data('root') ;
    prcsub_set_xml_data('data_info') ;
    prcsub_set_xml_data('lg_nyuko_info') ;
--
    -- -----------------------------------------------------
    -- 帳票0件用XMLデータ作成
    -- -----------------------------------------------------
    IF (gt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn, gc_msg_id_no_data ) ;
--
      prcsub_set_xml_data('g_nyuko_info') ;
      prcsub_set_xml_data('head_title' , gv_report_title) ;
      prcsub_set_xml_data('lg_nyuko_yotei_info') ;
      prcsub_set_xml_data('g_nyuko_yotei_info') ;
      prcsub_set_xml_data('msg' , ov_errmsg) ;
      prcsub_set_xml_data('/g_nyuko_yotei_info') ;
      prcsub_set_xml_data('/lg_nyuko_yotei_info') ;
      prcsub_set_xml_data('/g_nyuko_info');
    END IF ;
--
    -- -----------------------------------------------------
    -- XMLデータ作成
    -- -----------------------------------------------------
    <<detail_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- ====================================================
      -- XMLデータ設定
      -- ====================================================
      -- ヘッダ部(入庫先コード情報)
      IF (lb_dispflg_nyuko_cd) THEN
        prcsub_set_xml_data('g_nyuko_info') ;
        prcsub_set_xml_data('head_title'       , gv_report_title) ;
        prcsub_set_xml_data('chohyo_id'        , gc_report_id) ;
        prcsub_set_xml_data('exec_time'        , TO_CHAR(gd_common_sysdate, gc_date_fmt_all)) ;
        prcsub_set_xml_data('dep_cd'           , gv_dept_cd) ;
        prcsub_set_xml_data('dep_nm'           , gv_dept_nm) ;
        prcsub_set_xml_data('chakubi_from'
          , TO_CHAR(gt_param.arrival_date_from, gc_date_fmt_ymd_ja)) ;
        prcsub_set_xml_data('chakubi_to'
          , TO_CHAR(gt_param.arrival_date_to, gc_date_fmt_ymd_ja)) ;
        prcsub_set_xml_data('nyuko_cd'         , gt_report_data(i).ship_to_locat_code) ;
        prcsub_set_xml_data('nyuko_nm'         , gt_report_data(i).ship_to_locat_name) ;
        prcsub_set_xml_data('lg_nyuko_yotei_info') ;
      END IF ;
--
      -- ヘッダ部(入庫予定日情報)
      IF (lb_dispflg_nyuko_date) THEN
        prcsub_set_xml_data('g_nyuko_yotei_info') ;
        prcsub_set_xml_data('chakubi'
          , TO_CHAR(gt_report_data(i).schedule_arrival_date, gc_date_fmt_ymd)) ;
        prcsub_set_xml_data('item_kbn'
          , gt_param.item_kbn) ;
        prcsub_set_xml_data('lg_delivery_info') ;
      END IF ;
--
      -- 明細部(配送No情報)
      IF (lb_dispflg_delivery_no) THEN
        prcsub_set_xml_data('g_delivery_info') ;
        prcsub_set_xml_data('new_modify_flg'   , gt_report_data(i).new_modify_flg) ;
        prcsub_set_xml_data('ship_date'
          , TO_CHAR(gt_report_data(i).schedule_ship_date, gc_date_fmt_ymd)) ;
        prcsub_set_xml_data('delivery_no'      , gt_report_data(i).delivery_no) ;
        prcsub_set_xml_data('delivery_kbn'     , gt_report_data(i).shipping_method_code) ;
        prcsub_set_xml_data('delivery_nm'      , gt_report_data(i).shipping_method_name) ;
        prcsub_set_xml_data('carrier_cd'       , gt_report_data(i).career_id) ;
        prcsub_set_xml_data('carrier_nm'       , gt_report_data(i).career_name) ;
        prcsub_set_xml_data('lg_move_info') ;
      END IF ;
--
      -- 明細部(移動No情報)
      IF (lb_dispflg_move_no) THEN
        prcsub_set_xml_data('g_move_info') ;
        prcsub_set_xml_data('zen_delivery_no'  , gt_report_data(i).prev_delivery_no) ;
        prcsub_set_xml_data('move_no'          , gt_report_data(i).mov_num) ;
        prcsub_set_xml_data('ship_cd'          , gt_report_data(i).shipped_locat_code) ;
        prcsub_set_xml_data('ship_nm'          , gt_report_data(i).shipped_locat_name) ;
        prcsub_set_xml_data('tehai_no'         , gt_report_data(i).batch_no) ;
        prcsub_set_xml_data('time_shitei_from' , gt_report_data(i).arrival_time_from) ;
        prcsub_set_xml_data('time_shitei_to'   , gt_report_data(i).arrival_time_to) ;
        prcsub_set_xml_data('tekiyo'           , gt_report_data(i).description) ;
        prcsub_set_xml_data('lg_dtl_info') ;
      END IF;
--
      -- 明細部(品目コード情報)
      prcsub_set_xml_data('g_dtl_info') ;
      prcsub_set_xml_data('item_cd'            , gt_report_data(i).item_code) ;
      prcsub_set_xml_data('item_nm'            , gt_report_data(i).item_name) ;
      prcsub_set_xml_data('net'                , gt_report_data(i).net) ;
      prcsub_set_xml_data('lot_no'             , gt_report_data(i).lot_no) ;
      prcsub_set_xml_data('lot_date'           , gt_report_data(i).prodct_date) ;
      prcsub_set_xml_data('best_bfr_date'      , gt_report_data(i).best_before_date) ;
      prcsub_set_xml_data('lot_sign'           , gt_report_data(i).uniqe_sign) ;
      prcsub_set_xml_data('num_qty'            , gt_report_data(i).num_qty) ;
      prcsub_set_xml_data('quantity'           , gt_report_data(i).quantity) ;
      prcsub_set_xml_data('tani'               , gt_report_data(i).conv_unit) ;
      prcsub_set_xml_data('/g_dtl_info') ;
--
      -- ====================================================
      -- 現在処理中のデータを保持
      -- ====================================================
      lv_tmp_nyuko_cd    := gt_report_data(i).ship_to_locat_code ;
      lv_tmp_nyuko_date  := gt_report_data(i).schedule_arrival_date ;
      lv_tmp_delivery_no := gt_report_data(i).delivery_no ;
      lv_tmp_move_no     := gt_report_data(i).mov_num ;
--
      -- ====================================================
      -- 出力判定
      -- ====================================================
      IF (i < gt_report_data.COUNT) THEN
        -- 移動No
        IF (lv_tmp_move_no = gt_report_data(i+1).mov_num) THEN
          lb_dispflg_move_no     := FALSE ;
        ELSE
          lb_dispflg_move_no     := TRUE ;
        END IF ;
--
        -- 配送No
        IF (lv_tmp_delivery_no = gt_report_data(i+1).delivery_no) THEN
          lb_dispflg_delivery_no := FALSE ;
        ELSE
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_move_no     := TRUE ;
        END IF ;
--
        -- 入庫予定日
        IF (lv_tmp_nyuko_date = gt_report_data(i+1).schedule_arrival_date) THEN
          lb_dispflg_nyuko_date  := FALSE ;
        ELSE
          lb_dispflg_nyuko_date  := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_move_no     := TRUE ;
        END IF ;
--
        -- 入庫先コード
        IF (lv_tmp_nyuko_cd = gt_report_data(i+1).ship_to_locat_code) THEN
          lb_dispflg_nyuko_cd    := FALSE ;
        ELSE
          lb_dispflg_nyuko_cd    := TRUE ;
          lb_dispflg_nyuko_date  := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_move_no     := TRUE ;
        END IF ;
--
      ELSE
          lb_dispflg_nyuko_cd    := TRUE ;
          lb_dispflg_nyuko_date  := TRUE ;
          lb_dispflg_delivery_no := TRUE ;
          lb_dispflg_move_no     := TRUE ;
      END IF;
--
      -- ====================================================
      -- 終了タグ設定
      -- ====================================================
      IF (lb_dispflg_move_no) THEN
        prcsub_set_xml_data('/lg_dtl_info') ;
        prcsub_set_xml_data('/g_move_info') ;
      END IF;
--
      IF (lb_dispflg_delivery_no) THEN
        prcsub_set_xml_data('/lg_move_info') ;
        prcsub_set_xml_data('/g_delivery_info') ;
      END IF;
--
      IF (lb_dispflg_nyuko_date) THEN
        prcsub_set_xml_data('/lg_delivery_info') ;
        prcsub_set_xml_data('/g_nyuko_yotei_info') ;
      END IF;
--
      IF (lb_dispflg_nyuko_cd) THEN
        prcsub_set_xml_data('/lg_nyuko_yotei_info') ;
        prcsub_set_xml_data('/g_nyuko_info') ;
      END IF;
      
    END LOOP detail_data_loop;
--
    -- ====================================================
    -- 終了タグ設定
    -- ====================================================
    prcsub_set_xml_data('/lg_nyuko_info') ;
    prcsub_set_xml_data('/data_info') ;
    prcsub_set_xml_data('/root') ;
--
  EXCEPTION
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
  /**********************************************************************************
   * Function Name    : fnc_convert_into_xml
   * Description      : XMLデータ変換
   ***********************************************************************************/
  FUNCTION fnc_convert_into_xml(
    iv_name  IN VARCHAR2
   ,iv_value IN VARCHAR2
   ,ic_type  IN CHAR
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_convert_data VARCHAR2(2000);
--
  BEGIN
--
    --データの場合
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF ;
--
    RETURN(lv_convert_data);
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
    lv_xml_string    VARCHAR2(32000) ;
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
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- XMLデータ部出力
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      lv_xml_string := fnc_convert_into_xml(
                         gt_xml_data_table(i).tag_name
                        ,gt_xml_data_table(i).tag_value
                        ,gt_xml_data_table(i).tag_type
                       ) ;
      -- XMLデータ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_xml_string) ;
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
    errbuf                  OUT    VARCHAR2       -- エラー・メッセージ  --# 固定 #
   ,retcode                 OUT    VARCHAR2       -- リターン・コード    --# 固定 #
   ,iv_dept                 IN     VARCHAR2       -- 01:部署
   ,iv_plan_decide_kbn      IN     VARCHAR2       -- 02:予定/確定区分
   ,iv_ship_from            IN     VARCHAR2       -- 03:出庫日From
   ,iv_ship_to              IN     VARCHAR2       -- 04:出庫日To
   ,iv_notif_date           IN     VARCHAR2       -- 05:確定通知実施日
   ,iv_notif_time_from      IN     VARCHAR2       -- 06:確定通知実施時間From
   ,iv_notif_time_to        IN     VARCHAR2       -- 07:確定通知実施時間To
   ,iv_block1               IN     VARCHAR2       -- 08:ブロック1
   ,iv_block2               IN     VARCHAR2       -- 09:ブロック2
   ,iv_block3               IN     VARCHAR2       -- 10:ブロック3
   ,iv_ship_to_locat_code   IN     VARCHAR2       -- 11:入庫先
   ,iv_shipped_locat_code   IN     VARCHAR2       -- 12:出庫元
   ,iv_freight_carrier_code IN     VARCHAR2       -- 13:運送業者
   ,iv_delivery_no          IN     VARCHAR2       -- 14:配送No
   ,iv_mov_num              IN     VARCHAR2       -- 15:移動No
   ,iv_online_kbn           IN     VARCHAR2       -- 16:オンライン対象区分
   ,iv_item_kbn             IN     VARCHAR2       -- 17:品目区分
   ,iv_arrival_date_from    IN     VARCHAR2       -- 18:着日From
   ,iv_arrival_date_to      IN     VARCHAR2       -- 19:着日To
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
    gt_param.dept                 := iv_dept ;                            -- 01:部署
    gt_param.plan_decide_kbn      := iv_plan_decide_kbn ;                 -- 02:予定/確定区分
    gt_param.ship_from            := FND_DATE.CANONICAL_TO_DATE(iv_ship_from) ; -- 03:出庫日From
    gt_param.ship_to              := FND_DATE.CANONICAL_TO_DATE(iv_ship_to) ;   -- 04:出庫日To
    gt_param.notif_date           := FND_DATE.CANONICAL_TO_DATE(iv_notif_date) ;-- 05:確定通知実施日
    gt_param.notif_time_from      := iv_notif_time_from ;                 -- 06:確定通知実施時間From
    gt_param.notif_time_to        := iv_notif_time_to ;                   -- 07:確定通知実施時間To
    gt_param.block1               := iv_block1 ;                          -- 08:ブロック1
    gt_param.block2               := iv_block2 ;                          -- 09:ブロック2
    gt_param.block3               := iv_block3 ;                          -- 10:ブロック3
    gt_param.ship_to_locat_code   := iv_ship_to_locat_code ;              -- 11:入庫先
    gt_param.shipped_locat_code   := iv_shipped_locat_code ;              -- 12:出庫元
    gt_param.freight_carrier_code := iv_freight_carrier_code ;            -- 13:運送業者
    gt_param.delivery_no          := iv_delivery_no ;                     -- 14:配送No
    gt_param.mov_num              := iv_mov_num ;                         -- 15:移動No
    gt_param.online_kbn           := iv_online_kbn ;                      -- 16:オンライン対象区分
    gt_param.item_kbn             := iv_item_kbn ;                        -- 17:品目区分
    gt_param.arrival_date_from    := FND_DATE.CANONICAL_TO_DATE(iv_arrival_date_from);-- 18:着日From
    gt_param.arrival_date_to      := FND_DATE.CANONICAL_TO_DATE(iv_arrival_date_to) ; -- 19:着日To
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
      errbuf  := gv_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part|| SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || SQLERRM ;
      retcode := gv_status_error ;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh620003c;
/

