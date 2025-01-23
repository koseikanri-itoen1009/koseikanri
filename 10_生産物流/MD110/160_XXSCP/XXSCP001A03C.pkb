create or replace PACKAGE BODY APPS.XXSCP001A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXSCP001A03C(body)
 * Description      : 前日在庫メジャー生産計画FBDI連携
 *                    前日の在庫数量をCSV出力する。
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2025/1/10     1.0  SCSK M.Sato      [E_本稼動_20298]新規作成
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXSCP001A03C'; -- パッケージ名
--
  --プロファイル
  cv_file_name_enter    CONSTANT VARCHAR2(30)  := 'XXSCP1_FILE_NAME_ON_HAND';         -- XXSCP:前日在庫ファイル名称
  cv_file_dir_enter     CONSTANT VARCHAR2(100) := 'XXSCP1_FILE_DIR_SUPPLY_PLANNING';  -- XXSCP:生産計画ファイル格納パス
  cv_scaling_number     CONSTANT VARCHAR2(50)  := 'XXSCP1_SCALING_NUMBER';            -- XXSCP:スケール値
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date       DATE;             -- 業務日付
  gv_file_name_enter    VARCHAR2(100) ;   -- XXSCP:前日在庫ファイル名称
  gv_file_dir_enter     VARCHAR2(500) ;   -- XXSCP:前日在庫ファイル格納パス
  gn_scaling_number     NUMBER  ;         -- XXSCP:スケール値
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_open_mode_w      CONSTANT VARCHAR2(10) := 'w';     -- ファイルオープンモード（上書き）
--
    -- *** ローカル変数 ***
--
    -- 変数型の宣言
    ln_transaction_count           NUMBER; 
    ln_transaction_value           NUMBER;
    ln_transaction_version         NUMBER;
    Id_transaction_close_day       DATE;
    lv_csv_text_h                  VARCHAR2(3000);
    lv_csv_text_l                  VARCHAR2(3000);
    lf_file_hand                   UTL_FILE.FILE_TYPE ;  -- ファイル・ハンドルの宣言
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- CSV出力用カーソル
    CURSOR history_on_hand_cur
      IS
        SELECT  xhoh.item_name                   item_name                   -- 品目コード
               ,xhoh.organization_code           organization_code           -- 代表組織コード
               ,xhoh.sr_instance_code            sr_instance_code            -- ソース・システム・コード
               ,xhoh.new_order_quantity          new_order_quantity          -- 在庫数量
               ,xhoh.subinventory_code           subinventory_code           -- 固定値「S」
               ,xhoh.deleted_flag                deleted_flag                -- 削除フラグ
               ,xhoh.end_value                   end_value                   -- 終端記号
        FROM   xxscp_his_on_hand xhoh
        WHERE  xhoh.version = ln_transaction_version
        ORDER BY xhoh.item_name
                ,xhoh.organization_code
        ;
--
    -- レコード型の宣言
    TYPE history_on_hand_rec IS RECORD (
     item_name                    VARCHAR2(250)    -- 品目コード
    ,organization_code            VARCHAR2(13)     -- 代表組織コード
    ,sr_instance_code             VARCHAR2(30)     -- ソース・システム・コード
    ,new_order_quantity           NUMBER(10,3)     -- 在庫数量
    ,subinventory_code            VARCHAR2(10)     -- 固定値「S」
    ,deleted_flag                 VARCHAR2(3)      -- 削除フラグ
    ,end_value                    VARCHAR2(3)      -- 終端記号
    );
    history_on_hand_record history_on_hand_rec; 
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 処理部
    -- ===============================
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --==============================================================
    -- 業務日付取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := '業務日付の取得に失敗しました。';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF
    ;
--
    --==============================================================
    -- プロファイル取得
    --==============================================================
    -- XXSCP:生産計画ファイル格納パスの取得
    gv_file_dir_enter := FND_PROFILE.VALUE(cv_file_dir_enter);
    IF (gv_file_dir_enter IS NULL) THEN
      lv_errmsg := 'XXSCP:生産計画ファイル格納パスの取得に失敗しました。';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXSCP:前日在庫ファイル名称の取得
    gv_file_name_enter      := FND_PROFILE.VALUE(cv_file_name_enter);
    IF (gv_file_name_enter IS NULL) THEN
      lv_errmsg := 'XXSCP:前日在庫ファイル名称の取得に失敗しました。';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXSCP:スケール値の取得
    gn_scaling_number       := TO_NUMBER(FND_PROFILE.VALUE(cv_scaling_number));
    IF (gn_scaling_number  IS NULL) THEN
      lv_errmsg := 'XXSCP:スケール値の取得に失敗しました。';
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 最新バージョンの取得
    SELECT xxscp_on_hand_ver_s1.NEXTVAL
    INTO   ln_transaction_version
    FROM   dual
    ;
--
    -- 倉庫の最終棚卸年月から集計開始日を取得
    SELECT ADD_MONTHS(TO_DATE(xxcmn_common_pkg.get_opminv_close_period || '01' ,'YYYYMMDD'),1)
    INTO   Id_transaction_close_day
    FROM   dual
    ;
--
    -- 前日のトランザクションを取得し、履歴テーブルに投入
    INSERT INTO xxscp_his_on_hand(
          his_on_hand_id                   -- テーブルID
         ,version                          -- バージョン
         ,item_name                        -- 品目コード
         ,organization_code                -- 代表組織
         ,sr_instance_code                 -- ソース・システム・コード(固定値「KI」)
         ,new_order_quantity               -- 在庫数量
         ,subinventory_code                -- 固定値「S」
         ,deleted_flag                     -- 削除フラグ
         ,end_value                        -- 終端記号
         ,created_by                       -- CREATED_BY
         ,creation_date                    -- CREATION_DATE
         ,last_updated_by                  -- LAST_UPDATED_BY
         ,last_update_date                 -- LAST_UPDATE_DATE
         ,last_update_login                -- LAST_UPDATE_LOGIN
         ,request_id                       -- REQUEST_ID
         ,program_application_id           -- PROGRAM_APPLICATION_ID
         ,program_id                       -- PROGRAM_ID
         ,program_update_date              -- PROGRAM_UPDATE_DATE
     )
    SELECT
          xxscp_on_hand_id_s1.NEXTVAL      his_on_hand_id            -- テーブルID
         ,ln_transaction_version           version                   -- バージョン
         ,toh.item_code                    item_code                 -- 品目
         ,toh.rep_org_code                 rep_org_code              -- 代表組織
         ,'KI'                             sr_instance_code          -- ソース・システム・コード(固定値「KI」)
         ,toh.on_hand_cs_num               on_hand_cs_num            -- 前日在庫ケース数
         ,'S'                              subinventory_code         -- 固定値「S」
         ,''                               deleted_flag              -- 削除フラグ
         ,'END'                            end_value                 -- 終端記号
         ,cn_created_by                    created_by                -- CREATED_BY
         ,cd_creation_date                 creation_date             -- CREATION_DATE
         ,cn_last_updated_by               last_updated_by           -- LAST_UPDATED_BY
         ,cd_last_update_date              last_update_date          -- LAST_UPDATE_DATE
         ,cn_last_update_login             last_update_login         -- LAST_UPDATE_LOGIN
         ,cn_request_id                    request_id                -- REQUEST_ID
         ,cn_program_application_id        program_application_id    -- PROGRAM_APPLICATION_ID
         ,cn_program_id                    program_id                -- PROGRAM_ID
         ,cd_program_update_date           program_update_date       -- PROGRAM_UPDATE_DATE
    FROM
          (  --組織コード、品目コード単位で集計
             SELECT
                      tran.rep_org_code                                    rep_org_code        -- 組織コード
                     ,tran.item_code                                       item_code           -- 品目コード
                     ,SUM( tran.month_qty)/gn_scaling_number               on_hand_cs_num      -- 前日在庫ケース数(スケール値で桁数を調整)
               FROM(
                       --======================================================================
                       -- 棚卸月末在庫テーブルから月首在庫数として最後に締まった月の月末在庫数を取得
                       --   ⇒【月首在庫数＋前日までの入出庫数の積み上げ】によって前日の在庫数を求める
                       --======================================================================
                        SELECT
                                xwm.rep_org_code              rep_org_code        -- 組織コード
                               ,xsim.item_code                item_code           -- 品目コード
                               ,(NVL( xsim.monthly_stock, 0 ) + NVL( xsim.cargo_stock, 0 ))/iimb.attribute11
                                                              month_qty           -- 月末在庫ケース数
                        FROM
                                xxinv_stc_inventory_month_stck    xsim            -- 棚卸月末在庫アドオン
                               ,ic_item_mst_b                     iimb            -- OPM品目マスタ
                               ,xxcmn_item_locations_v            xilv            -- ロケーションアイテムView
                               ,xxscp_warehouse_mst               xwm             -- 品目倉庫マスタ
                        WHERE
                              ( xsim.cargo_stock <> 0  OR  xsim.monthly_stock <> 0 )
                           AND  xsim.invent_ym                = TO_CHAR(Id_transaction_close_day-1,'YYYYMM')
                           AND  xsim.item_id                  = iimb.item_id
                           AND  xsim.whse_code                = xilv.whse_code
                           AND  xilv.segment1                 = xwm.whse_code
                           AND  xsim.item_code                = xwm.item_code
                           AND  xwm.rep_org_code             <> 'DUMMY'
                           AND  xilv.description       NOT LIKE '取置%' 
                       --<< 棚卸月末在庫テーブから月首在庫数として前月の月末在庫数を取得 END >>--
                      UNION ALL
                       --======================================================================
                       -- 各トランザクションから月間入庫数を取得
                       --  １．仕入先返品
                       --  ２．発注受入実績
                       --  ３．移動入庫実績
                          -- ３-１．移動入庫予定（03:調整中）
                          -- ３-２．移動入庫予定（04:出庫報告済）
                          -- ３-３．移動入庫実績（05:入庫報告済）
                          -- ３-４．移動入庫実績（06:入出庫報告済）
                       --  ４．倉替返品入庫実績
                          -- ４-１．倉替返品入庫実績
                          -- ４-２．倉替返品入庫実績（取消）
                       --  ５．その他入庫
                       -- 各トランザクションから月間出庫数を取得
                       --  １．出荷実績
                          -- １-１．出荷実績（04:実績計上済）
                          -- １-２．出荷実績（03:締め済）-- 実績未入力の出荷数量を集計
                       --  ２．有償支給実績
                          -- ２-１．有償支給実績（返品の場合入庫扱い）
                          -- ２-２．有償支給実績
                       --  ３．見本･廃棄出荷実績
                       --  ４．移動出庫実績
                          -- ４-１．移動出庫予定（03：調整中）
                          -- ４-２．移動出庫実績（04：出庫報告済）
                          -- ４-３．移動出庫実績（05：入庫報告済）
                       --======================================================================
                        ----------------------------------------------------------------------
                        -- １．仕入先返品  …マイナス値で出力
                        ----------------------------------------------------------------------
                        SELECT
                               /*+
                                  LEADING(xrp)
                                  USE_NL(xrp itc)
                                */
                                xwm.rep_org_code               rep_org_code        -- 組織コード
                               ,iimb.item_no                   item_code           -- 品目コード
                               ,itc.trans_qty/iimb.attribute11 month_qty           -- ケース数量
                         FROM
                                xxcmn_rcv_pay_mst              xrp                 -- 受払区分アドオンマスタ
                               ,ic_tran_cmp                    itc                 -- OPM完了在庫トランザクション
                               ,xxcmn_item_locations_v         xilv                -- ロケーションアイテムView
                               ,ic_item_mst_b                  iimb                -- OPM品目マスタ
                               ,xxscp_warehouse_mst            xwm                 -- 品目倉庫マスタ
                         WHERE
                                xrp.doc_type                  = 'ADJI'
                           AND  xrp.reason_code               = 'X201'             -- 仕入返品出庫
                           AND  xrp.rcv_pay_div               = '1'                -- 受入
                           AND  xrp.use_div_invent            = 'Y'
                           AND  itc.trans_qty                <> 0
                           AND  itc.doc_type                  = xrp.doc_type
                           AND  itc.reason_code               = xrp.reason_code
                           AND  itc.trans_date               >= Id_transaction_close_day
                                                                                   -- 最後に在庫が締まった月の翌月初日から
                           AND  itc.trans_date                < gd_process_date    -- 前日まで
                           AND  itc.item_id                   = iimb.item_id
                           AND  iimb.item_no                  = xwm.item_code
                           AND  itc.location                  = xwm.whse_code
                           AND  xwm.rep_org_code             <> 'DUMMY'
                           AND  xwm.whse_code                 = xilv.segment1
                           AND  xilv.description       NOT LIKE '取置%' 
                        --[ １．仕入先返品 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ２．発注受入実績
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code        -- 組織コード
                               ,xrt.item_code                 item_code           -- 品目ID
                               ,xrt.quantity/iimb.attribute11 month_qty           -- 月末在庫バラ数
                         FROM
                                po_headers_all                pha                 -- 発注ヘッダ
                               ,po_lines_all                  pla                 -- 発注明細
                               ,xxpo_rcv_and_rtn_txns         xrt                 -- 受入返品実績(アドオン)
                               ,ic_item_mst_b                 iimb                -- OPM品目マスタ
                               ,xxscp_warehouse_mst           xwm                 -- 品目倉庫マスタ
                               ,xxcmn_item_locations_v        xilv                -- ロケーションアイテムView
                         WHERE
                                pha.attribute1                IN ( '25'           -- 受入あり
                                                                 , '30'           -- 数量確定済
                                                                 , '35' )         -- 金額確定済
                           AND  pla.attribute13               = 'Y'               -- 承諾済
                           AND  pla.cancel_flag              <> 'Y'               -- キャンセル以外
                           AND  pha.po_header_id              = pla.po_header_id
                           AND  xrt.source_document_number    = pha.segment1
                           AND  xrt.source_document_line_num  = pla.line_num
                           AND  xrt.txns_type                 = '1'               -- 受入
                           AND  xrt.quantity                 <> 0
                           AND  xrt.txns_date                >= Id_transaction_close_day
                                                                                  -- 最後に在庫が締まった月の翌月初日から
                           AND  xrt.txns_date                 < gd_process_date   -- 前日まで
                           AND  xrt.item_id                   = iimb.item_id
                           AND  xrt.item_code                 = xwm.item_code
                           AND  pha.attribute5                = xwm.whse_code
                           AND  xwm.rep_org_code             <> 'DUMMY'
                           AND  xwm.whse_code                 = xilv.segment1
                           AND  xilv.description       NOT LIKE '取置%' 
                        --[ ２．発注受入実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ３-１．移動入庫予定（03:調整中）
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm2.rep_org_code             rep_org_code        -- 組織コード（TO）
                               ,xmril.item_code               item_code           -- 品目コード
                               ,xmril.instruct_qty /iimb.attribute11
                                                              month_qty           -- ケース数量
                          FROM
                                xxinv_mov_req_instr_headers   xmrih               -- 移動依頼/指示ヘッダ(アドオン)
                               ,xxinv_mov_req_instr_lines     xmril               -- 移動依頼/指示明細(アドオン)
                               ,ic_item_mst_b                 iimb                -- OPM品目マスタ
                               ,xxscp_warehouse_mst           xwm1                -- 品目倉庫マスタ(FROM)
                               ,xxscp_warehouse_mst           xwm2                -- 品目倉庫マスタ(TO)
                               ,xxcmn_item_locations_v        xilv1               -- ロケーションアイテムView(出庫元)
                               ,xxcmn_item_locations_v        xilv2               -- ロケーションアイテムView(入庫先)
                         WHERE
                                xmrih.status                    = '03'             -- 03：調整中
                           AND  xmrih.notif_status              = '40'             -- 40確定通知済
                           AND  xmrih.schedule_arrival_date    >= Id_transaction_close_day
                                                                                   -- 最後に在庫が締まった月の翌月初日から
                           AND  xmrih.schedule_arrival_date     < gd_process_date  -- 前日まで
                           AND  xmril.delete_flg                = 'N'             -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           -- DUMMY倉庫に仕入れた商品を在庫として移動する場合があるため、コメントアウト
                           --AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code            -- 同一組織間の移動は対象外
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '取置%' 
                           AND  xilv2.description        NOT LIKE '取置%' 
                        --[ ３-１．移動入庫実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ３-２．移動入庫予定（04:出庫報告済）
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm2.rep_org_code             rep_org_code        -- 組織コード（TO）
                               ,xmril.item_code               item_code           -- 品目コード
                               ,xmril.shipped_quantity /iimb.attribute11
                                                              month_qty           -- ケース数量
                          FROM
                                xxinv_mov_req_instr_headers   xmrih               -- 移動依頼/指示ヘッダ(アドオン)
                               ,xxinv_mov_req_instr_lines     xmril               -- 移動依頼/指示明細(アドオン)
                               ,ic_item_mst_b                 iimb                -- OPM品目マスタ
                               ,xxscp_warehouse_mst           xwm1                -- 品目倉庫マスタ(FROM)
                               ,xxscp_warehouse_mst           xwm2                -- 品目倉庫マスタ(TO)
                               ,xxcmn_item_locations_v        xilv1               -- ロケーションアイテムView(出庫元)
                               ,xxcmn_item_locations_v        xilv2               -- ロケーションアイテムView(入庫先)
                         WHERE
                                xmrih.status                    = '04'            -- 04:出庫報告済
                           AND  xmrih.schedule_arrival_date    >= Id_transaction_close_day
                                                                                  -- 最後に在庫が締まった月の翌月初日から
                           AND  xmrih.schedule_arrival_date     < gd_process_date -- 前日まで
                           AND  xmril.delete_flg                = 'N'             -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           -- DUMMY倉庫に仕入れた商品を在庫として移動する場合があるため、コメントアウト
                           --AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code            -- 同一組織間の移動は対象外
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '取置%' 
                           AND  xilv2.description        NOT LIKE '取置%' 
                        --[ ３-２．移動入庫実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ３-３．移動入庫実績（05:入庫報告済）
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm2.rep_org_code             rep_org_code        -- 組織コード（TO）
                               ,xmril.item_code               item_code           -- 品目コード
                               ,xmril.ship_to_quantity/iimb.attribute11
                                                              month_qty           -- ケース数量
                          FROM
                                xxinv_mov_req_instr_headers   xmrih               -- 移動依頼/指示ヘッダ(アドオン)
                               ,xxinv_mov_req_instr_lines     xmril               -- 移動依頼/指示明細(アドオン)
                               ,ic_item_mst_b                 iimb                -- OPM品目マスタ
                               ,xxscp_warehouse_mst           xwm1                -- 品目倉庫マスタ(FROM)
                               ,xxscp_warehouse_mst           xwm2                -- 品目倉庫マスタ(TO)
                               ,xxcmn_item_locations_v        xilv1               -- ロケーションアイテムView(出庫元)
                               ,xxcmn_item_locations_v        xilv2               -- ロケーションアイテムView(入庫先)
                         WHERE
                                xmrih.status                    = '05'            -- 05:入庫報告有
                           AND  xmrih.actual_arrival_date      >= Id_transaction_close_day
                                                                                  -- 最後に在庫が締まった月の翌月初日から
                           AND  xmrih.actual_arrival_date       < gd_process_date -- 当月前日まで
                           AND  xmril.delete_flg                = 'N'             -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           -- DUMMY倉庫に仕入れた商品を在庫として移動する場合があるため、コメントアウト
                           --AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code            -- 同一組織間の移動は対象外
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '取置%' 
                           AND  xilv2.description        NOT LIKE '取置%' 
                        --[ ３-３．移動入庫実績 END ]--
                      UNION ALL
                       ----------------------------------------------------------------------
                        -- ３-４．移動入庫実績（06:入出庫報告済）
                        ----------------------------------------------------------------------
                       SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm2.rep_org_code             rep_org_code        -- 組織コード（TO）
                               ,xmril.item_code               item_code             -- 品目コード
                               ,xmril.ship_to_quantity/iimb.attribute11
                                                              month_qty           -- ケース数量
                          FROM
                                xxinv_mov_req_instr_headers   xmrih               -- 移動依頼/指示ヘッダ(アドオン)
                               ,xxinv_mov_req_instr_lines     xmril               -- 移動依頼/指示明細(アドオン)
                               ,ic_item_mst_b                 iimb                -- OPM品目マスタ
                               ,xxscp_warehouse_mst           xwm1                -- 品目倉庫マスタ(FROM)
                               ,xxscp_warehouse_mst           xwm2                -- 品目倉庫マスタ(TO)
                               ,xxcmn_item_locations_v        xilv1               -- ロケーションアイテムView(出庫元)
                               ,xxcmn_item_locations_v        xilv2               -- ロケーションアイテムView(入庫先)
                         WHERE
                                xmrih.status                    = '06'            -- 06:入出庫報告
                           AND  xmrih.actual_arrival_date      >= Id_transaction_close_day
                                                                                  -- 最後に在庫が締まった月の翌月初日から
                           AND  xmrih.actual_arrival_date       < gd_process_date -- 当月前日まで
                           AND  xmril.delete_flg                = 'N'             -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           -- DUMMY倉庫に仕入れた商品を在庫として移動する場合があるため、コメントアウト
                           --AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code            -- 同一組織間の移動は対象外
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '取置%' 
                           AND  xilv2.description        NOT LIKE '取置%' 
                        --[ ３-４．移動入庫実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ４-１．倉替返品入庫実績
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code         -- 組織コード
                               ,xola.shipping_item_code       item_code            -- 品目コード
                               ,xola.shipped_quantity/iimb.attribute11
                                                              month_qty            -- ケース数量
                          FROM
                                xxwsh_order_headers_all       xoha                 -- 受注ヘッダ
                               ,xxwsh_order_lines_all         xola                 -- 受注明細
                               ,oe_transaction_types_all      ota                  -- 受注タイプ
                               ,xxscp_warehouse_mst           xwm                  -- 品目倉庫マスタ
                               ,ic_item_mst_b                 iimb                 -- OPM品目マスタ
                         WHERE
                                xoha.req_status                       = '04'       -- 実績計上済
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'        -- ON
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                           AND  xoha.arrival_date                     < gd_process_date
                           AND  ota.attribute1                        = '3'        -- 倉替返品
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  ota.order_category_code               = 'ORDER'
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'        -- 無効明細以外
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ ４．倉替返品入庫実績 END ]--
                      UNION ALL
                       ----------------------------------------------------------------------
                        -- ４-２．倉替返品入庫実績（取消）
                        ----------------------------------------------------------------------
                         SELECT
                                xwm.rep_org_code              rep_org_code               -- 組織コード
                               ,xola.shipping_item_code       item_code                  -- 品目コード
                               ,xola.shipped_quantity/iimb.attribute11 * - 1             -- 取消なら出庫扱い
                                                              month_qty                  -- ケース数量
                          FROM
                                xxwsh_order_headers_all       xoha                       -- 受注ヘッダ
                               ,xxwsh_order_lines_all         xola                       -- 受注明細
                               ,oe_transaction_types_all      ota                        -- 受注タイプ
                               ,xxscp_warehouse_mst           xwm                        -- 品目倉庫マスタ
                               ,ic_item_mst_b                 iimb                       -- OPM品目マスタ
                         WHERE
                                xoha.req_status                       = '04'             -- 実績計上済
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'              -- ON
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                                                                                         -- 最後に在庫が締まった月の翌月初日から
                           AND  xoha.arrival_date                     < gd_process_date  -- 前日まで
                           AND  ota.attribute1                        = '3'              -- 倉替返品
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  ota.order_category_code               = 'RETURN'
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'              -- 無効明細以外
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ ４．倉替返品入庫実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ５．その他入庫
                        ----------------------------------------------------------------------
                        SELECT
                               /*+
                                  LEADING(xrp)
                                  USE_NL(xrp itc)
                                */
                                xwm.rep_org_code               rep_org_code        -- 組織コード
                               ,iimb.item_no                   item_code           -- 品目コード
                               ,itc.trans_qty/iimb.attribute11 month_qty           -- ケース数量
                         FROM
                                xxcmn_rcv_pay_mst              xrp                 -- 受払区分アドオンマスタ
                               ,ic_tran_cmp                    itc                 -- OPM完了在庫トランザクション
                               ,xxcmn_item_locations_v         xilv                -- ロケーションアイテムView
                               ,ic_item_mst_b                  iimb                -- OPM品目マスタ
                               ,xxscp_warehouse_mst            xwm                 -- 品目倉庫マスタ
                         WHERE
                                XRP.doc_type                  = 'ADJI'
                           AND  XRP.reason_code              <> 'X977'             -- 相手先在庫
                           AND  XRP.reason_code              <> 'X988'             -- 浜岡入庫
                           AND  XRP.reason_code              <> 'X123'             -- 移動実績訂正（出庫）
                           AND  XRP.reason_code              <> 'X201'             -- 仕入先返品
                           AND  XRP.rcv_pay_div               = '1'                -- 受入
                           AND  XRP.use_div_invent            = 'Y'
                           AND  itc.trans_qty                <> 0
                           AND  itc.doc_type                  = xrp.doc_type
                           AND  itc.reason_code               = xrp.reason_code
                           AND  itc.trans_date               >= Id_transaction_close_day
                                                                                   -- 最後に在庫が締まった月の翌月初日から
                           AND  itc.trans_date                < gd_process_date    -- 当月前日まで
                           AND  itc.item_id                   = iimb.item_id
                           AND  iimb.item_no                  = xwm.item_code
                           AND  itc.location                  = xwm.whse_code
                           AND  xwm.rep_org_code             <> 'DUMMY'
                           AND  xwm.whse_code                 = xilv.segment1
                           AND  xilv.description       NOT LIKE '取置%' 
                        --[ ５．その他入庫 END ]--
                       --<< 各トランザクションから月間入庫数を取得 END >>--
                      UNION ALL
                       --======================================================================
                       -- 各トランザクションから月間出庫数を取得
                       --  １．出荷実績
                       --  ２．有償支給実績
                       --  ３．見本･廃棄出荷実績
                       --  ４．移動出庫実績
                       --  ５．その他出庫
                       --======================================================================
                        ----------------------------------------------------------------------
                        -- １-１．出荷実績（04:実績計上済）
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code                -- 組織コード
                               ,xola.shipping_item_code       item_code                   -- 品目コード
                               ,xola.shipped_quantity/iimb.attribute11 * -1
                                                              month_qty                   -- ケース数量
                          FROM
                                xxwsh_order_headers_all       xoha                        -- 受注ヘッダ
                               ,xxwsh_order_lines_all         xola                        -- 受注明細
                               ,oe_transaction_types_all      ota                         -- 受注タイプ
                               ,xxscp_warehouse_mst           xwm                         -- 品目倉庫マスタ
                               ,ic_item_mst_b                 iimb                        -- OPM品目マスタ
                         WHERE
                                xoha.req_status                       = '04'              -- 実績計上済
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'               -- ON
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                                                                                          -- 最後に在庫が締まった月の翌月初日から
                           AND  xoha.arrival_date                     < gd_process_date   -- 前日まで
                           AND  ota.attribute1                        = '1'               -- 出荷依頼
                           AND  ota.attribute4                        = '1'               -- 通常出荷
                           AND  ota.order_category_code               = 'ORDER'
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'               -- 無効明細以外
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ １．出荷･倉返実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- １-２．出荷実績（03:締め済）-- 実績未入力の出荷数量を集計
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code                -- 組織コード
                               ,xola.shipping_item_code       item_code                   -- 品目コード
                               ,xola.quantity/iimb.attribute11 * -1
                                                              month_qty                   -- ケース数量
                          FROM
                                xxwsh_order_headers_all       xoha                        -- 受注ヘッダ
                               ,xxwsh_order_lines_all         xola                        -- 受注明細
                               ,oe_transaction_types_all      ota                         -- 受注タイプ
                               ,xxscp_warehouse_mst           xwm                         -- 品目倉庫マスタ
                               ,ic_item_mst_b                 iimb                        -- OPM品目マスタ
                         WHERE
                                xoha.req_status                       = '03'              -- 実績計上済
                           AND  xoha.notif_status                     = '40'              -- 確定通知済
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'               -- ON
                           AND  xoha.schedule_arrival_date           >= Id_transaction_close_day
                                                                                          -- 最後に在庫が締まった月の翌月初日から
                           AND  xoha.schedule_arrival_date            < gd_process_date   -- 前日まで
                           AND  ota.attribute1                        = '1'               -- 出荷依頼
                           AND  ota.attribute4                        = '1'               -- 通常出荷
                           AND  ota.order_category_code               = 'ORDER'
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'               -- 無効明細以外
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ １．出荷･倉返実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ２-１．有償支給実績（返品の場合入庫扱い）
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code               -- 組織コード
                               ,xola.shipping_item_code       item_code                  -- 品目コード
                               ,xola.shipped_quantity/iimb.attribute11                   -- 返品なら入庫扱い
                                                              month_qty                  -- ケース数量
                          FROM
                                xxwsh_order_headers_all       xoha                       -- 受注ヘッダ
                               ,xxwsh_order_lines_all         xola                       -- 受注明細
                               ,oe_transaction_types_all      ota                        -- 受注タイプ
                               ,xxscp_warehouse_mst           xwm                        -- 品目倉庫マスタ
                               ,ic_item_mst_b                 iimb                       -- OPM品目マスタ
                         WHERE
                                xoha.req_status                       = '08'             -- 実績計上済
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'              -- ON
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                                                                                         -- 最後に在庫が締まった月の翌月初日から
                           AND  xoha.arrival_date                     < gd_process_date  -- 前日まで
                           AND  ota.attribute1                        = '2'              -- 支給
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  ota.order_category_code               = 'RETURN'
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'              -- 無効明細以外
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ ２-１．有償支給実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ２-２．有償支給実績
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code               -- 組織コード
                               ,xola.shipping_item_code       item_code                  -- 品目コード
                               ,xola.shipped_quantity/iimb.attribute11 * -1
                                                              month_qty                  -- ケース数量
                          FROM
                                xxwsh_order_headers_all       xoha                       -- 受注ヘッダ
                               ,xxwsh_order_lines_all         xola                       -- 受注明細
                               ,oe_transaction_types_all      ota                        -- 受注タイプ
                               ,xxscp_warehouse_mst           xwm                        -- 品目倉庫マスタ
                               ,ic_item_mst_b                 iimb                       -- OPM品目マスタ
                         WHERE
                                xoha.req_status                       = '08'             -- 実績計上済
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'              -- ON
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                                                                                         -- 最後に在庫が締まった月の翌月初日から
                           AND  xoha.arrival_date                     < gd_process_date  -- 前日まで
                           AND  ota.attribute1                        = '2'              -- 支給
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  ota.order_category_code               = 'ORDER'
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'              -- 無効明細以外
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ ２-２．有償支給実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ３．見本･廃棄出荷実績
                        ----------------------------------------------------------------------
                        SELECT
                                xwm.rep_org_code              rep_org_code                -- 組織コード
                               ,xola.shipping_item_code       item_code                   -- 品目コード
                               ,xola.shipped_quantity/iimb.attribute11 * -1
                                                              month_qty                   -- ケース数量
                          FROM
                                xxwsh_order_headers_all       xoha                        -- 受注ヘッダ
                               ,xxwsh_order_lines_all         xola                        -- 受注明細
                               ,oe_transaction_types_all      ota                         -- 受注タイプ
                               ,xxscp_warehouse_mst           xwm                         -- 品目倉庫マスタ
                               ,ic_item_mst_b                 iimb                        -- OPM品目マスタ
                         WHERE
                                xoha.req_status                       = '04'              -- 実績計上済
                           AND  NVL( xoha.latest_external_flag, 'N' ) = 'Y'               -- ON
                           AND  ota.attribute1                        = '1'               -- 出荷依頼
                           AND  ota.attribute4                        = '2'               -- 見本･廃棄出荷
                           AND  ota.order_category_code               = 'ORDER'
                           AND  xoha.order_type_id                    = ota.transaction_type_id
                           AND  NVL( xola.delete_flag, 'N' )         <> 'Y'               -- 無効明細以外
                           AND  xoha.order_header_id                  = xola.order_header_id
                           AND  xoha.arrival_date                    >= Id_transaction_close_day
                                                                                          -- 最後に在庫が締まった月の翌月初日から
                           AND  xoha.arrival_date                     < gd_process_date   -- 前日まで
                           AND  xola.shipping_item_code               = xwm.item_code
                           AND  xoha.deliver_from                     = xwm.whse_code
                           AND  xwm.rep_org_code                     <> 'DUMMY'
                           AND  xola.shipping_item_code               = iimb.item_no
                        --[ ３．出荷･倉返実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ４-１．移動出庫予定（03：調整中）
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm1.rep_org_code             rep_org_code         -- 組織コード
                               ,xmril.item_code               item_code            -- 品目コード
                               ,xmril.instruct_qty /iimb.attribute11 * - 1
                                                              month_qty            -- ケース数量
                          FROM
                                xxinv_mov_req_instr_headers   xmrih                -- 移動依頼/指示ヘッダ(アドオン)
                               ,xxinv_mov_req_instr_lines     xmril                -- 移動依頼/指示明細(アドオン)
                               ,ic_item_mst_b                 iimb                 -- OPM品目マスタ
                               ,xxcmn_item_locations_v        xilv1                -- ロケーションアイテムView(出庫元)
                               ,xxcmn_item_locations_v        xilv2                -- ロケーションアイテムView(入庫先)
                               ,xxscp_warehouse_mst           xwm1                 -- 品目倉庫マスタ(FROM)
                               ,xxscp_warehouse_mst           xwm2                 -- 品目倉庫マスタ(TO)
                         WHERE
                                xmrih.status                    = '03'             -- 03：調整中
                           AND  xmrih.notif_status              = '40'             -- 40確定通知済
                           AND  xmrih.schedule_arrival_date    >= Id_transaction_close_day
                                                                                   -- 最後に在庫が締まった月の翌月初日から
                           AND  xmrih.schedule_arrival_date     < gd_process_date  -- 当月前日まで
                           AND  xmril.delete_flg                = 'N'              -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           -- DUMMY倉庫に移動する場合があるのでコメントアウト
                           -- AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code <> xwm2.rep_org_code             -- 同一組織間の移動は対象外
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '取置%' 
                           AND  xilv2.description        NOT LIKE '取置%' 
                        --[ ４-１．移動出荷実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ４-２．移動出庫実績（04：出庫報告済）
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm1.rep_org_code             rep_org_code         -- 組織コード
                               ,xmril.item_code               item_code            -- 品目コード
                               ,xmril.shipped_quantity /iimb.attribute11 * - 1
                                                              month_qty            -- ケース数量
                          FROM
                                xxinv_mov_req_instr_headers   xmrih                -- 移動依頼/指示ヘッダ(アドオン)
                               ,xxinv_mov_req_instr_lines     xmril                -- 移動依頼/指示明細(アドオン)
                               ,ic_item_mst_b                 iimb                 -- OPM品目マスタ
                               ,xxcmn_item_locations_v        xilv1                -- ロケーションアイテムView(出庫元)
                               ,xxcmn_item_locations_v        xilv2                -- ロケーションアイテムView(入庫先)
                               ,xxscp_warehouse_mst           xwm1                 -- 品目倉庫マスタ(FROM)
                               ,xxscp_warehouse_mst           xwm2                 -- 品目倉庫マスタ(TO)
                         WHERE
                                xmrih.status                    = '04'             -- 04：出庫報告済
                           AND  xmrih.schedule_arrival_date    >= Id_transaction_close_day
                                                                                   -- 最後に在庫が締まった月の翌月初日から
                           AND  xmrih.schedule_arrival_date     < gd_process_date  -- 当月前日まで
                           AND  xmril.delete_flg                = 'N'              -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           -- DUMMY倉庫に移動する場合があるのでコメントアウト
                           -- AND  xwm2.rep_org_code              <> 'DUMMY'
                           AND  xwm1.rep_org_code <> xwm2.rep_org_code             -- 同一組織間の移動は対象外
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '取置%' 
                           AND  xilv2.description        NOT LIKE '取置%' 
                        --[ ４-２．移動出荷実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ４-３．移動出庫実績（05：入庫報告済）
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm1.rep_org_code             rep_org_code         -- 組織コード
                               ,xmril.item_code               item_code            -- 品目コード
                               ,xmril.shipped_quantity /iimb.attribute11 * - 1
                                                              month_qty            -- ケース数量
                          FROM
                                xxinv_mov_req_instr_headers   xmrih                -- 移動依頼/指示ヘッダ(アドオン)
                               ,xxinv_mov_req_instr_lines     xmril                -- 移動依頼/指示明細(アドオン)
                               ,ic_item_mst_b                 iimb                 -- OPM品目マスタ
                               ,xxcmn_item_locations_v        xilv1                -- ロケーションアイテムView(出庫元)
                               ,xxcmn_item_locations_v        xilv2                -- ロケーションアイテムView(入庫先)
                               ,xxscp_warehouse_mst           xwm1                 -- 品目倉庫マスタ(FROM)
                               ,xxscp_warehouse_mst           xwm2                 -- 品目倉庫マスタ(TO)
                         WHERE
                                xmrih.status                    = '05'             -- 05：入庫報告済
                           AND  xmrih.actual_arrival_date      >= Id_transaction_close_day
                                                                                   -- 最後に在庫が締まった月の翌月初日から
                           AND  xmrih.actual_arrival_date       < gd_process_date  -- 当月前日まで
                           AND  xmril.delete_flg                = 'N'              -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           -- DUMMY倉庫に移動する場合があるのでコメントアウト
                           -- AND  xwm2.rep_org_code           <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code             -- 同一組織間の移動は対象外
                           -- xxcmn_item_locations_vとの結合
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '取置%' 
                           AND  xilv2.description        NOT LIKE '取置%' 
                        --[ ４-３．移動出荷実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ４-４．移動出庫実績（06：入出庫報告済）
                        ----------------------------------------------------------------------
                        SELECT
                        /*+
                                LEADING(xmrih xmril xwm1)
                                INDEX(xmril XXINV_MRIL_N02)
                        */
                                xwm1.rep_org_code             rep_org_code         -- 組織コード
                               ,xmril.item_code               item_code            -- 品目コード
                               ,xmril.shipped_quantity /iimb.attribute11 * - 1
                                                              month_qty            -- ケース数量
                          FROM
                                xxinv_mov_req_instr_headers   xmrih                -- 移動依頼/指示ヘッダ(アドオン)
                               ,xxinv_mov_req_instr_lines     xmril                -- 移動依頼/指示明細(アドオン)
                               ,ic_item_mst_b                 iimb                 -- OPM品目マスタ
                               ,xxcmn_item_locations_v        xilv1                -- ロケーションアイテムView(出庫元)
                               ,xxcmn_item_locations_v        xilv2                -- ロケーションアイテムView(入庫先)
                               ,xxscp_warehouse_mst           xwm1                 -- 品目倉庫マスタ(FROM)
                               ,xxscp_warehouse_mst           xwm2                 -- 品目倉庫マスタ(TO)
                         WHERE
                                xmrih.status                    = '06'             -- 06：入出庫報告済
                           AND  xmrih.actual_arrival_date      >= Id_transaction_close_day
                                                                                   -- 最後に在庫が締まった月の翌月初日から
                           AND  xmrih.actual_arrival_date       < gd_process_date  -- 当月前日まで
                           AND  xmril.delete_flg                = 'N'              -- OFF
                           AND  xmrih.mov_hdr_id                = xmril.mov_hdr_id
                           AND  xmril.item_code                 = iimb.item_no
                           AND  xmril.item_code                 = xwm1.item_code
                           AND  xmrih.shipped_locat_code        = xwm1.whse_code
                           AND  xwm1.rep_org_code              <> 'DUMMY'
                           AND  xmril.item_code                 = xwm2.item_code
                           AND  xmrih.ship_to_locat_code        = xwm2.whse_code
                           -- DUMMY倉庫に移動する場合があるのでコメントアウト
                           -- AND  xwm2.rep_org_code           <> 'DUMMY'
                           AND  xwm1.rep_org_code              <> xwm2.rep_org_code             -- 同一組織間の移動は対象外
                           AND  xmrih.shipped_locat_id          = xilv1.inventory_location_id
                           AND  xmrih.ship_to_locat_id          = xilv2.inventory_location_id
                           AND  xilv1.description        NOT LIKE '取置%' 
                           AND  xilv2.description        NOT LIKE '取置%' 
                        --[ ４-４．移動出荷実績 END ]--
                      UNION ALL
                        ----------------------------------------------------------------------
                        -- ５．その他出庫
                        ----------------------------------------------------------------------
                        SELECT
                               /*+
                                  LEADING(xrp)
                                  USE_NL(xrp itc)
                                */
                                xwm.rep_org_code               rep_org_code        -- 組織コード
                               ,iimb.item_no                   item_code           -- 品目コード
                               ,itc.trans_qty/iimb.attribute11 month_qty           -- ケース数量
                        FROM
                                xxcmn_rcv_pay_mst             xrp                  -- 受払区分アドオンマスタ
                               ,ic_tran_cmp                   itc                  -- OPM完了在庫トランザクション
                               ,xxcmn_item_locations_v        xilv                 -- 確認①保管場所名称をsysdateで取得しているが問題ないか
                               ,ic_item_mst_b                 iimb                 -- OPM品目マスタ
                               ,xxscp_warehouse_mst           xwm                  -- 品目倉庫マスタ
                         WHERE
                                XRP.doc_type                  = 'ADJI'
                           AND  XRP.reason_code              <> 'X977'             --相手先在庫
                           AND  XRP.reason_code              <> 'X123'             --移動実績訂正（出庫）
                           AND  XRP.rcv_pay_div               = '-1'               --払出
                           AND  XRP.use_div_invent            = 'Y'
                           AND  itc.trans_qty                <> 0
                           AND  itc.doc_type                  = xrp.doc_type
                           AND  itc.reason_code               = xrp.reason_code
                           AND  itc.trans_date               >= Id_transaction_close_day
                                                                                   -- 最後に在庫が締まった月の翌月初日から
                           AND  itc.trans_date                < gd_process_date    -- 当月前日まで
                           AND  itc.item_id                   = iimb.item_id
                           AND  iimb.item_no                  = xwm.item_code
                           AND  itc.location                  = xwm.whse_code
                           AND  xwm.rep_org_code             <> 'DUMMY'
                           AND  xwm.whse_code                 = xilv.segment1
                           AND  xilv.description       NOT LIKE '取置%' 
                        --[ ５．その他入庫 END ]--
                       --<< 各トランザクションから月間出庫数を取得 END >>--
                     )  tran
             GROUP BY  tran.rep_org_code
                      ,tran.item_code
          )toh
    ;
--
    -- コミット処理
    COMMIT;
--
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN(gv_file_dir_enter,
                                   gv_file_name_enter,
                                   cv_open_mode_w,
                                   32767
                                  );
--
    -- ===============================
    -- CSVヘッダ部処理
    -- ===============================
--
    -- ヘッダー部設定
    lv_csv_text_h := 'ITEM_NAME,ORGANIZATION_CODE,SR_INSTANCE_CODE,NEW_ORDER_QUANTITY,SUBINVENTORY_CODE,LOT_NUMBER,EXPIRATION_DATE,DELETED_FLAG,GLOBAL_ATTRIBUTE_NUMBER11,GLOBAL_ATTRIBUTE_NUMBER12,GLOBAL_ATTRIBUTE_NUMBER13,GLOBAL_ATTRIBUTE_NUMBER14,GLOBAL_ATTRIBUTE_NUMBER15,GLOBAL_ATTRIBUTE_NUMBER16,GLOBAL_ATTRIBUTE_NUMBER17,GLOBAL_ATTRIBUTE_NUMBER18,GLOBAL_ATTRIBUTE_NUMBER19,GLOBAL_ATTRIBUTE_NUMBER20,GLOBAL_ATTRIBUTE_NUMBER21,GLOBAL_ATTRIBUTE_NUMBER22,GLOBAL_ATTRIBUTE_NUMBER23,GLOBAL_ATTRIBUTE_NUMBER24,GLOBAL_ATTRIBUTE_NUMBER25,HOLD_DATE,GLOBAL_ATTRIBUTE_CHAR21,GLOBAL_ATTRIBUTE_CHAR22,GLOBAL_ATTRIBUTE_CHAR23,MATURITY_DATE,END'
;
--
    -- ヘッダー部設定ログ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_text_h
    );
--
    -- ====================================================
    -- ヘッダー部CSV出力
    -- ====================================================
    UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text_h ) ;
--
    -- ===============================
    -- CSV明細部処理
    -- ===============================
--
    -- カーソルのオープン
    OPEN history_on_hand_cur;
--
    -- データ部出力
    LOOP
      FETCH history_on_hand_cur INTO history_on_hand_record;
      EXIT WHEN history_on_hand_cur%NOTFOUND;
--
      --件数セット
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 明細部設定
      lv_csv_text_l :=    history_on_hand_record.item_name                                            || ','
                       || history_on_hand_record.organization_code                                    || ','
                       || history_on_hand_record.sr_instance_code                                     || ','
                       || RTRIM(TO_CHAR(history_on_hand_record.new_order_quantity, 'FM9999990.999'), '.')  || ','
                       || history_on_hand_record.subinventory_code                                    || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_on_hand_record.deleted_flag                                         || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || ''                                                                          || ','
                       || history_on_hand_record.end_value
                       ;
--
      -- 明細部設定ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_csv_text_l)
      ;
--
      -- ====================================================
      -- 明細部CSV出力
      -- ====================================================
      UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text_l ) ;
--
    END LOOP;
    CLOSE history_on_hand_cur;
--
    -- ====================================================
    -- ＵＴＬファイルクローズ
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- 成功件数＝対象件数
    gn_normal_cnt  := gn_target_cnt;
--
    -- 対象件数=0であれば警告
    IF (gn_target_cnt = 0) THEN
      ov_retcode     := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
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
      IF UTL_FILE.IS_OPEN  ( lf_file_hand ) THEN
         UTL_FILE.FCLOSE   ( lf_file_hand );
      END IF;
--
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
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2      --   リターン・コード             --# 固定 #
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
       iv_which   => 'LOG'
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
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
      gn_error_cnt := 1;
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
    --終了ステータスがエラーの場合はROLLBACKする
    IF (lv_retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
    --ステータスセット
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      lv_retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      lv_retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXSCP001A03C;
/