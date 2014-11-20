CREATE OR REPLACE PACKAGE BODY XXCMN960005C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960005C(body)
 * Description      : OPM保留在庫トランザクション（標準）バックアップ
 * MD.050           : T_MD050_BPO_96E_OPM保留在庫トランザクション（標準）バックアップ
 * Version          : 1.00
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
 *  2012/11/19   1.00   Miyamoto         新規作成
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
  gn_arc_cnt_pnd            NUMBER;                                             -- バックアップ件数（OPM保留在庫トランザクション（標準））
  gn_arc_cnt_cmp            NUMBER;                                             -- バックアップ件数（OPM完了在庫トランザクション（標準））
  gn_pnd_trans_id           ic_tran_pnd.trans_id%TYPE;                          -- 対象OPM保留在庫トランザクションID
  gn_cmp_trans_id           ic_tran_cmp.trans_id%TYPE;                          -- 対象OPM完了在庫トランザクションID
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
  local_process_expt        EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name       CONSTANT VARCHAR2(100) := 'XXCMN960005C'; -- パッケージ名
  cv_proc_date_msg  CONSTANT VARCHAR2(50)  := 'APP-XXCMN-11014';         --処理日出力
  cv_par_token      CONSTANT VARCHAR2(10)  := 'PAR';                     --処理日MSG用ﾄｰｸﾝ名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date  IN  VARCHAR2,     --   1.処理日
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
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
    cv_purge_def_code         CONSTANT VARCHAR2(30)  := 'XXCMN960005';          -- パージ定義コード
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCMN';                -- アドオン：共通・IF領域
    cv_purge_type             CONSTANT VARCHAR2(1)   := '1';                    -- パージタイプ(1:バックアップ処理期間)
    cv_purge_code             CONSTANT VARCHAR2(30)  := '9601';                 -- パージ定義コード
--
    cv_get_priod_msg          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11012';      -- バックアップ期間の取得に失敗しました。
    cv_get_profile_msg        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';      -- プロファイル[ ＆NG_PROFILE ]の取得に失敗しました。
    cv_local_others_msg       CONSTANT VARCHAR2(100) := 'APP-XXCMN-11026';      -- ＆SHORI 処理に失敗しました。【 ＆KINOUMEI 】 ＆KEYNAME ： ＆KEY
    cv_token_profile          CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_shori            CONSTANT VARCHAR2(10)  := 'SHORI';
    cv_token_kinoumei         CONSTANT VARCHAR2(10)  := 'KINOUMEI';
    cv_token_keyname          CONSTANT VARCHAR2(10)  := 'KEYNAME';
    cv_token_key              CONSTANT VARCHAR2(10)  := 'KEY';
    cv_token_bkup             CONSTANT VARCHAR2(100) := 'バックアップ';
    cv_token_opm_pnd          CONSTANT VARCHAR2(100) := 'OPM保留在庫トランザクション';
    cv_token_opm_cmp          CONSTANT VARCHAR2(100) := 'OPM完了在庫トランザクション';
    cv_token_trans_id         CONSTANT VARCHAR2(100) := '取引ID';

--
    cv_xxcmn_commit_range     CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';   --XXCMN:分割コミット数
    cv_xxcmn_archive_range    CONSTANT VARCHAR2(100) := 'XXCMN_ARCHIVE_RANGE';  --XXCMN:バックアップレンジ
    cv_xxcmn_org_id           CONSTANT VARCHAR2(100) := 'ORG_ID';               --営業単位
--
    cv_date_format            CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
    cv_doc_type_omso          CONSTANT VARCHAR2(30)  := 'OMSO';
    cv_doc_type_porc          CONSTANT VARCHAR2(30)  := 'PORC';
    cv_doc_type_xfer          CONSTANT VARCHAR2(30)  := 'XFER';
    cv_doc_type_trni          CONSTANT VARCHAR2(30)  := 'TRNI';
    cv_doc_type_adji          CONSTANT VARCHAR2(30)  := 'ADJI';
    cv_order                  CONSTANT VARCHAR2(30)  := 'ORDER';
    cv_return                 CONSTANT VARCHAR2(30)  := 'RETURN';
    cv_closed                 CONSTANT VARCHAR2(30)  := 'CLOSED';
    cv_reason_code_x122       CONSTANT VARCHAR2(30)  := 'X122';
    cv_reason_code_x123       CONSTANT VARCHAR2(30)  := 'X123';
    cv_move                   CONSTANT  VARCHAR2(2)  := '20';
    cv_actual_move            CONSTANT VARCHAR2(30)  := '移動実績';
    cv_status_wsh_keijozumi   CONSTANT  VARCHAR2(2)  := '04';--04:出荷実績計上済
    cv_status_po_keijozumi    CONSTANT  VARCHAR2(2)  := '08';--08:出荷実績計上済
    cv_move_booked            CONSTANT  VARCHAR2(2)  := '06';
    cv_actual_ship            CONSTANT  VARCHAR2(2)  := '20';
    cv_actual_arrival         CONSTANT  VARCHAR2(2)  := '30';
--
    -- *** ローカル変数 ***
    ln_arc_cnt_pnd            NUMBER DEFAULT 0;                                 -- 
    ln_arc_cnt_cmp            NUMBER DEFAULT 0;                                 -- 
    ln_arc_cnt_pnd_yet        NUMBER DEFAULT 0;                                 -- 未コミットバックアップ件数(OPM保留在庫トランザクション(標準))
    ln_arc_cnt_cmp_yet        NUMBER DEFAULT 0;                                 -- 未コミットバックアップ件数(OPM完了在庫トランザクション(標準))
    ln_archive_period         NUMBER;                                           -- バックアップ期間
    ln_archive_range          NUMBER;                                           -- バックアップレンジ
    ld_standard_date          DATE;                                             -- 基準日
    ln_commit_range           NUMBER;                                           -- 分割コミット数
    ln_org_id                 NUMBER;                                           -- 営業単位ID
    ln_transaction_id         NUMBER;
    ln_before_header_id       NUMBER;
    lv_token_kinoumei         VARCHAR2(100);
    lv_process_step           VARCHAR2(100);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    CURSOR バックアップ対象OPM保留在庫トランザクション(標準)取得
      id_基準日  IN DATE
      in_バックアップレンジ IN NUMBER
      in_営業単位ＩＤ IN 受注ヘッダ(標準)．営業単位ＩＤ%TYPE
    IS
      -- OPM保留在庫トランザクション(標準)(受注)
      SELECT 0
            ,受注ヘッダ(アドオン).ヘッダID
            ,OPM保留在庫トランザクション(標準)全カラム
      FROM 受注ヘッダ(アドオン)
           ,    受注タイプ(標準)
           ,    受注ヘッダ(標準)
           ,    OPM保留在庫トランザクション(標準)
      WHERE 受注ヘッダ(アドオン)．ステータス IN ('04','08')
      AND 受注ヘッダ(アドオン)．着荷日 >= id_基準日 - in_バックアップレンジ
      AND 受注ヘッダ(アドオン)．着荷日 < id_基準日
      AND 受注タイプ(標準)．受注タイプID = 受注ヘッダ(アドオン)．受注タイプID
      AND 受注タイプ(標準)．受注カテゴリコード = 'ORDER'
      AND 受注ヘッダ(標準).flow_status_code     = 'CLOSED'
      AND 受注ヘッダ(標準)．受注ヘッダID = 受注ヘッダ(アドオン)．受注ヘッダID
      AND 受注ヘッダ(標準)．営業単位ID = in_営業単位ID
      AND 受注明細(標準)．受注ヘッダID = 受注ヘッダ(標準)．受注ヘッダID
      AND OPM保留在庫トランザクション(標準)．明細ID = 受注明細(標準)．明細ID
      AND OPM保留在庫トランザクション(標準)．文書タイプ = 'OMSO'
      AND NOT EXISTS (
                SELECT 1
                FROM OPM保留在庫トランザクション(標準)バックアップ
                WHERE OPM保留在庫トランザクション(標準)バックアップ．トランザクションID = OPM保留在庫トランザクション(標準)．トランザクションID
                AND ROWNUM = 1
             )
    UNION
      -- OPM保留在庫トランザクション(標準)(返品)
      SELECT 1
            ,受注ヘッダ(アドオン).ヘッダID
            ,OPM保留在庫トランザクション(標準)全カラム
      FROM 受注ヘッダ(アドオン)
           ,    受注タイプ(標準)
           ,    受注ヘッダ(標準)
           ,    受注明細(標準)
           ,    受入明細(標準)
           ,    OPM保留在庫トランザクション(標準)
      WHERE 受注ヘッダ(アドオン)．ステータス IN ('04','08')
      AND 受注ヘッダ(アドオン)．着荷日 >= id_基準日 - in_バックアップレンジ
      AND 受注ヘッダ(アドオン)．着荷日 < id_基準日
      AND 受注タイプ(標準)．受注タイプID = 受注ヘッダ(アドオン)．受注タイプID
      AND 受注タイプ(標準)．受注カテゴリコード = 'RETURN'
      AND 受注ヘッダ(標準).flow_status_code     = 'CLOSED'
      AND 受注ヘッダ(標準)．受注ヘッダID = 受注ヘッダ(アドオン)．受注ヘッダID
      AND 受注ヘッダ(標準)．営業単位ID = in_営業単位ID
      AND 受注明細(標準)．受注ヘッダID = 受注ヘッダ(標準)．受注ヘッダID
      AND 受入明細(標準)．受注ヘッダID = 受注明細(標準)．受注ヘッダID
      AND 受入明細(標準)．受注明細ID = 受注明細(標準)．受注明細ID
      AND OPM保留在庫トランザクション(標準)．文書ID = 受入明細(標準)．受入ヘッダID
      AND OPM保留在庫トランザクション(標準)．取引明細番号 = 受入明細(標準)．明細番号
      AND OPM保留在庫トランザクション(標準)．文書タイプ = 'PORC'
      AND NOT EXISTS (
                SELECT 1
                FROM OPM保留在庫トランザクション(標準)バックアップ
                WHERE OPM保留在庫トランザクション(標準)バックアップ．トランザクションID = OPM保留在庫トランザクション(標準)．トランザクションID
                AND ROWNUM = 1
             )
      UNION
      -- OPM保留在庫トランザクション（標準）（移動）
      SELECT 2
            ,移動依頼/指示ヘッダ(アドオン)．移動ヘッダID
            ,OPM保留在庫トランザクション(標準)全カラム
      FROM 移動依頼/指示ヘッダ(アドオン)
           ,    移動依頼/指示明細(アドオン)
           ,    OPM在庫転送マスタ(標準)
           ,    OPM保留在庫トランザクション(標準)
      WHERE 移動依頼/指示ヘッダ(アドオン)．ステータス ＝ '06'
      AND 移動依頼/指示ヘッダ(アドオン)．入庫実績日 >= id_基準日 - in_バックアップレンジ
      AND 移動依頼/指示ヘッダ(アドオン)．入庫実績日 < id_基準日
      AND 移動依頼/指示明細(アドオン)．移動ヘッダID = 移動依頼/指示ヘッダ(アドオン)．移動ヘッダID
      AND OPM在庫転送マスタ(標準)．DFF1 = 移動依頼/指示明細(アドオン)．明細ID
      AND OPM保留在庫トランザクション(標準)．文書ID = OPM在庫転送マスタ(標準)．転送ID
      AND ( OPM保留在庫トランザクション(標準)．文書タイプ = 'XFER'
      AND OPM保留在庫トランザクション．事由コード = '移動実績'の事由コード )
      AND EXISTS (
              SELECT  1
              FROM    移動ロット詳細(アドオン)
              WHERE   移動ロット詳細(アドオン)．明細ID = 移動依頼/指示明細(アドオン)．移動明細ID
              AND 移動ロット詳細(アドオン)．文書タイプ = '20'
              AND 移動ロット詳細(アドオン)．レコードタイプ IN ('20','30')
              AND OPM保留在庫トランザクション(標準)．ロットID = 移動ロット詳細(アドオン)．ロットID
              And     ROWNUM                  = 1
              )
      AND NOT EXISTS (
                SELECT 1
                FROM OPM保留在庫トランザクション（標準）バックアップ
                WHERE OPM保留在庫トランザクション（標準）バックアップ．トランザクションID = OPM保留在庫トランザクション（標準）．トランザクションID
                AND ROWNUM = 1
             )
     */
    CURSOR archive_tran_pnd_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
     ,in_org_id                  oe_order_headers_all.org_id%TYPE
    )
    IS
      -- OPM保留在庫トランザクション(標準)(受注)
      SELECT  /*+ LEADING(xoha) USE_NL(xoha otta ooha oola itp) INDEX(xoha XXWSH_OH_N15) */
              0                           AS pre_sort_key
             ,xoha.header_id              AS header_id
             ,itp.trans_id                AS trans_id
             ,itp.item_id                 AS item_id
             ,itp.line_id                 AS line_id
             ,itp.co_code                 AS co_code
             ,itp.orgn_code               AS orgn_code
             ,itp.whse_code               AS whse_code
             ,itp.lot_id                  AS lot_id
             ,itp.location                AS location
             ,itp.doc_id                  AS doc_id
             ,itp.doc_type                AS doc_type
             ,itp.doc_line                AS doc_line
             ,itp.line_type               AS line_type
             ,itp.reason_code             AS reason_code
             ,itp.creation_date           AS creation_date
             ,itp.trans_date              AS trans_date
             ,itp.trans_qty               AS trans_qty
             ,itp.trans_qty2              AS trans_qty2
             ,itp.qc_grade                AS qc_grade
             ,itp.lot_status              AS lot_status
             ,itp.trans_stat              AS trans_stat
             ,itp.trans_um                AS trans_um
             ,itp.trans_um2               AS trans_um2
             ,itp.op_code                 AS op_code
             ,itp.completed_ind           AS completed_ind
             ,itp.staged_ind              AS staged_ind
             ,itp.gl_posted_ind           AS gl_posted_ind
             ,itp.event_id                AS event_id
             ,itp.delete_mark             AS delete_mark
             ,itp.text_code               AS text_code
             ,itp.last_update_date        AS last_update_date
             ,itp.created_by              AS created_by
             ,itp.last_updated_by         AS last_updated_by
             ,itp.last_update_login       AS last_update_login
             ,itp.program_application_id  AS program_application_id
             ,itp.program_id              AS program_id
             ,itp.program_update_date     AS program_update_date
             ,itp.request_id              AS request_id
             ,itp.reverse_id              AS reverse_id
             ,itp.pick_slip_number        AS pick_slip_number
             ,itp.mvt_stat_status         AS mvt_stat_status
             ,itp.movement_id             AS movement_id
             ,itp.line_detail_id          AS line_detail_id
             ,itp.invoiced_flag           AS invoiced_flag
             ,itp.intorder_posted_ind     AS intorder_posted_ind
             ,itp.lot_costed_ind          AS lot_costed_ind
      FROM    xxwsh_order_headers_all  xoha   --受注ヘッダ(アドオン)
             ,oe_transaction_types_all otta   --受注タイプ(標準)
             ,oe_order_headers_all     ooha   --受注ヘッダ(標準)
             ,oe_order_lines_all       oola   --受注明細(標準)
             ,ic_tran_pnd              itp    --OPM保留在庫トランザクション(標準)
      WHERE   xoha.req_status          IN (cv_status_wsh_keijozumi, cv_status_po_keijozumi)
      AND     xoha.arrival_date        >= id_standard_date - in_archive_range
      AND     xoha.arrival_date         < id_standard_date
      AND     otta.transaction_type_id  = xoha.order_type_id
      AND     otta.order_category_code  = cv_order
      AND     ooha.flow_status_code     = cv_closed
      AND     ooha.header_id            = xoha.header_id
      AND     ooha.org_id               = in_org_id
      AND     oola.header_id            = ooha.header_id
      AND     itp.line_id               = oola.line_id
      AND     itp.doc_type              = cv_doc_type_omso
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_ic_tran_pnd_arc  xitpa --OPM保留在庫トランザクション(標準)バックアップ
                WHERE   xitpa.trans_id = itp.trans_id
                AND     ROWNUM         = 1
              )
      UNION
      -- OPM保留在庫トランザクション(標準)(返品)
      SELECT  /*+ LEADING(xoha) USE_NL(xoha otta ooha oola rsl itp) INDEX(xoha XXWSH_OH_N15) */
              1                           AS pre_sort_key
             ,xoha.header_id              AS header_id
             ,itp.trans_id                AS trans_id
             ,itp.item_id                 AS item_id
             ,itp.line_id                 AS line_id
             ,itp.co_code                 AS co_code
             ,itp.orgn_code               AS orgn_code
             ,itp.whse_code               AS whse_code
             ,itp.lot_id                  AS lot_id
             ,itp.location                AS location
             ,itp.doc_id                  AS doc_id
             ,itp.doc_type                AS doc_type
             ,itp.doc_line                AS doc_line
             ,itp.line_type               AS line_type
             ,itp.reason_code             AS reason_code
             ,itp.creation_date           AS creation_date
             ,itp.trans_date              AS trans_date
             ,itp.trans_qty               AS trans_qty
             ,itp.trans_qty2              AS trans_qty2
             ,itp.qc_grade                AS qc_grade
             ,itp.lot_status              AS lot_status
             ,itp.trans_stat              AS trans_stat
             ,itp.trans_um                AS trans_um
             ,itp.trans_um2               AS trans_um2
             ,itp.op_code                 AS op_code
             ,itp.completed_ind           AS completed_ind
             ,itp.staged_ind              AS staged_ind
             ,itp.gl_posted_ind           AS gl_posted_ind
             ,itp.event_id                AS event_id
             ,itp.delete_mark             AS delete_mark
             ,itp.text_code               AS text_code
             ,itp.last_update_date        AS last_update_date
             ,itp.created_by              AS created_by
             ,itp.last_updated_by         AS last_updated_by
             ,itp.last_update_login       AS last_update_login
             ,itp.program_application_id  AS program_application_id
             ,itp.program_id              AS program_id
             ,itp.program_update_date     AS program_update_date
             ,itp.request_id              AS request_id
             ,itp.reverse_id              AS reverse_id
             ,itp.pick_slip_number        AS pick_slip_number
             ,itp.mvt_stat_status         AS mvt_stat_status
             ,itp.movement_id             AS movement_id
             ,itp.line_detail_id          AS line_detail_id
             ,itp.invoiced_flag           AS invoiced_flag
             ,itp.intorder_posted_ind     AS intorder_posted_ind
             ,itp.lot_costed_ind          AS lot_costed_ind
      FROM    xxwsh_order_headers_all  xoha   --受注ヘッダ(アドオン)
             ,oe_transaction_types_all otta   --受注タイプ(標準)
             ,oe_order_headers_all     ooha   --受注ヘッダ(標準)
             ,oe_order_lines_all       oola   --受注明細(標準)
             ,rcv_shipment_lines       rsl    --受入明細(標準)
             ,ic_tran_pnd              itp    --OPM保留在庫トランザクション(標準)
      WHERE   xoha.req_status          IN (cv_status_wsh_keijozumi, cv_status_po_keijozumi)
      AND     xoha.arrival_date        >= id_standard_date - in_archive_range
      AND     xoha.arrival_date         < id_standard_date
      AND     otta.transaction_type_id  = xoha.order_type_id
      AND     otta.order_category_code  = cv_return
      AND     ooha.flow_status_code     = cv_closed
      AND     ooha.header_id            = xoha.header_id
      AND     ooha.org_id               = in_org_id
      AND     oola.header_id            = ooha.header_id
      AND     rsl.oe_order_header_id    = ooha.header_id
      AND     rsl.oe_order_line_id      = oola.line_id
      AND     itp.doc_id                = rsl.shipment_header_id
      AND     itp.doc_line              = rsl.line_num
      AND     itp.doc_type              = cv_doc_type_porc
      AND     NOT EXISTS (
                SELECT  1
                FROM    xxcmn_ic_tran_pnd_arc  xitpa --OPM保留在庫トランザクション(標準)バックアップ
                WHERE   xitpa.trans_id = itp.trans_id
                AND     ROWNUM         = 1
              )
      UNION
    -- OPM保留在庫トランザクション（標準）（移動）
      SELECT  /*+ LEADING(xmrih) USE_NL(xmrih xmril ixm itp)*/
              2                           AS pre_sort_key
             ,xmrih.mov_hdr_id            AS header_id
             ,itp.trans_id                AS trans_id
             ,itp.item_id                 AS item_id
             ,itp.line_id                 AS line_id
             ,itp.co_code                 AS co_code
             ,itp.orgn_code               AS orgn_code
             ,itp.whse_code               AS whse_code
             ,itp.lot_id                  AS lot_id
             ,itp.location                AS location
             ,itp.doc_id                  AS doc_id
             ,itp.doc_type                AS doc_type
             ,itp.doc_line                AS doc_line
             ,itp.line_type               AS line_type
             ,itp.reason_code             AS reason_code
             ,itp.creation_date           AS creation_date
             ,itp.trans_date              AS trans_date
             ,itp.trans_qty               AS trans_qty
             ,itp.trans_qty2              AS trans_qty2
             ,itp.qc_grade                AS qc_grade
             ,itp.lot_status              AS lot_status
             ,itp.trans_stat              AS trans_stat
             ,itp.trans_um                AS trans_um
             ,itp.trans_um2               AS trans_um2
             ,itp.op_code                 AS op_code
             ,itp.completed_ind           AS completed_ind
             ,itp.staged_ind              AS staged_ind
             ,itp.gl_posted_ind           AS gl_posted_ind
             ,itp.event_id                AS event_id
             ,itp.delete_mark             AS delete_mark
             ,itp.text_code               AS text_code
             ,itp.last_update_date        AS last_update_date
             ,itp.created_by              AS created_by
             ,itp.last_updated_by         AS last_updated_by
             ,itp.last_update_login       AS last_update_login
             ,itp.program_application_id  AS program_application_id
             ,itp.program_id              AS program_id
             ,itp.program_update_date     AS program_update_date
             ,itp.request_id              AS request_id
             ,itp.reverse_id              AS reverse_id
             ,itp.pick_slip_number        AS pick_slip_number
             ,itp.mvt_stat_status         AS mvt_stat_status
             ,itp.movement_id             AS movement_id
             ,itp.line_detail_id          AS line_detail_id
             ,itp.invoiced_flag           AS invoiced_flag
             ,itp.intorder_posted_ind     AS intorder_posted_ind
             ,itp.lot_costed_ind          AS lot_costed_ind
      FROM    xxinv_mov_req_instr_headers   xmrih     --移動依頼/指示ヘッダ(アドオン)
             ,xxinv_mov_req_instr_lines     xmril     --移動依頼/指示明細(アドオン)
             ,ic_xfer_mst                   ixm       --OPM在庫転送マスタ
             ,ic_tran_pnd                   itp       --OPM保留在庫トランザクション(標準)
      WHERE
              xmrih.status            = cv_move_booked  --移動依頼/指示ヘッダ(アドオン)．ステータス = '06'
        AND   xmrih.actual_arrival_date  >= id_standard_date - in_archive_range
        AND   xmrih.actual_arrival_date   < id_standard_date
        AND   xmril.mov_hdr_id            = xmrih.mov_hdr_id
        AND   ixm.attribute1              = TO_CHAR(xmril.mov_line_id)
        AND   itp.doc_id                  = ixm.transfer_id
        AND   itp.doc_type                = cv_doc_type_xfer
        AND   itp.reason_code             = cv_reason_code_x122
      AND   EXISTS (
              SELECT  1
              FROM    xxinv_mov_lot_details  xmld             --移動ロット詳細(アドオン)
              WHERE   xmld.mov_line_id        = xmril.mov_line_id
              AND     xmld.document_type_code = cv_move          --移動ロット詳細(アドオン)．文書タイプ = '20'
              AND     xmld.record_type_code   IN (cv_actual_ship, cv_actual_arrival)  --移動ロット詳細(アドオン)．レコードタイプ IN ('20','30')
              AND     xmld.lot_id             = itp.lot_id
              And     ROWNUM                  = 1
              )
      AND   NOT EXISTS (
              SELECT  1
              FROM    xxcmn_ic_tran_pnd_arc  xitpa          --OPM保留在庫トランザクション(標準)バックアップ
              WHERE   xitpa.trans_id          = itp.trans_id
              AND     ROWNUM                  = 1
              )
      ORDER BY pre_sort_key,header_id
      ;
    /*
    -- OPM完了在庫トランザクション（標準）（移動）
    CURSOR バックアップ対象OPM完了在庫トランザクション（標準）取得
      id_基準日  IN DATE
      in_バックアップレンジ IN NUMBER
    IS
      SELECT 
             移動依頼/指示ヘッダ(アドオン)．移動ヘッダID
            ,OPM完了在庫トランザクション（標準）全カラム
      FROM 移動依頼/指示ヘッダ(アドオン)
           ,    移動依頼/指示明細(アドオン)
           ,    OPMジャーナルマスタ(標準)
           ,    OPM在庫調整ジャーナル(標準)
           ,    OPM完了在庫トランザクション(標準)
      WHERE 移動依頼/指示ヘッダ(アドオン)．ステータス ＝ '06'
      AND 移動依頼/指示ヘッダ(アドオン)．入庫実績日 >= id_基準日 - in_バックアップレンジ
      AND 移動依頼/指示ヘッダ(アドオン)．入庫実績日 < id_基準日
      AND 移動依頼/指示明細(アドオン)．移動ヘッダID = 移動依頼/指示ヘッダ(アドオン)．移動ヘッダID
      AND OPMジャーナルマスタ(標準)．DFF1 = 移動ロット詳細(アドオン)．明細ID
      AND OPM在庫調整ジャーナル(標準)．ジャーナルID = OPMジャーナルマスタ(標準)．ジャーナルID
      AND OPM完了在庫トランザクション(標準)．文書タイプ = OPM在庫調整ジャーナル(標準)．文書タイプ
      AND OPM完了在庫トランザクション(標準)．文書ID = OPM在庫調整ジャーナル(標準)．文書ID
      AND OPM完了在庫トランザクション(標準)．取引明細番号 = OPM在庫調整ジャーナル(標準)．取引明細番号
      AND ( ( OPM完了在庫トランザクション(標準)．文書タイプ = 'TRNI'
      AND OPM完了在庫トランザクション．事由コード = '移動実績'の事由コード )
       OR   ( OPM完了在庫トランザクション(標準)．文書タイプ = 'ADJI'
      AND OPM完了在庫トランザクション．事由コード = '移動実績訂正'の事由コード )
      AND EXISTS (
                SELECT  1
                FROM    移動ロット詳細(アドオン)
                WHERE   移動ロット詳細(アドオン)．明細ID = 移動依頼/指示明細(アドオン)．移動明細ID
                AND     移動ロット詳細(アドオン)．文書タイプ = '20'
                AND     移動ロット詳細(アドオン)．レコードタイプ IN ('20','30')
                AND     OPM完了在庫トランザクション(標準)．ロットID = 移動ロット詳細(アドオン)．ロットID
                And     ROWNUM                  = 1
                )
      AND NOT EXISTS (
                SELECT 1
                FROM OPM完了在庫トランザクション（標準）バックアップ
                WHERE OPM完了在庫トランザクション（標準）バックアップ．トランザクションID = OPM完了在庫トランザクション（標準）．トランザクションID
                AND ROWNUM = 1
             )
     */
    CURSOR archive_ic_tran_cmp_cur(
      id_standard_date           DATE
     ,in_archive_range           NUMBER
    )
    IS
      SELECT  /*+ LEADING(xmrih) USE_NL(xmrih xmril ijm iaj itc INDEX(ijm GMI_IJM_N01)*/
              xmrih.mov_hdr_id            AS header_id
             ,itc.trans_id                AS trans_id
             ,itc.item_id                 AS item_id
             ,itc.line_id                 AS line_id
             ,itc.co_code                 AS co_code
             ,itc.orgn_code               AS orgn_code
             ,itc.whse_code               AS whse_code
             ,itc.lot_id                  AS lot_id
             ,itc.location                AS location
             ,itc.doc_id                  AS doc_id
             ,itc.doc_type                AS doc_type
             ,itc.doc_line                AS doc_line
             ,itc.line_type               AS line_type
             ,itc.reason_code             AS reason_code
             ,itc.creation_date           AS creation_date
             ,itc.trans_date              AS trans_date
             ,itc.trans_qty               AS trans_qty
             ,itc.trans_qty2              AS trans_qty2
             ,itc.qc_grade                AS qc_grade
             ,itc.lot_status              AS lot_status
             ,itc.trans_stat              AS trans_stat
             ,itc.trans_um                AS trans_um
             ,itc.trans_um2               AS trans_um2
             ,itc.op_code                 AS op_code
             ,itc.gl_posted_ind           AS gl_posted_ind
             ,itc.event_id                AS event_id
             ,itc.text_code               AS text_code
             ,itc.last_update_date        AS last_update_date
             ,itc.created_by              AS created_by
             ,itc.last_updated_by         AS last_updated_by
             ,itc.last_update_login       AS last_update_login
             ,itc.program_application_id  AS program_application_id
             ,itc.program_id              AS program_id
             ,itc.program_update_date     AS program_update_date
             ,itc.request_id              AS request_id
             ,itc.movement_id             AS movement_id
             ,itc.mvt_stat_status         AS mvt_stat_status
             ,itc.line_detail_id          AS line_detail_id
             ,itc.invoiced_flag           AS invoiced_flag
             ,itc.staged_ind              AS staged_ind
             ,itc.intorder_posted_ind     AS intorder_posted_ind
             ,itc.lot_costed_ind          AS lot_costed_ind
      FROM    xxinv_mov_req_instr_headers   xmrih     --移動依頼/指示ヘッダ(アドオン)
             ,xxinv_mov_req_instr_lines     xmril     --移動依頼/指示明細(アドオン)
             ,ic_jrnl_mst                   ijm       --OPMジャーナルマスタ(標準)
             ,ic_adjs_jnl                   iaj       --OPM在庫調整ジャーナル(標準)
             ,ic_tran_cmp                   itc       --OPM完了在庫トランザクション(標準)
      WHERE
              xmrih.status            = cv_move_booked  --移動依頼/指示ヘッダ(アドオン)．ステータス = '06'
        AND   xmrih.actual_arrival_date >= id_standard_date - in_archive_range
        AND   xmrih.actual_arrival_date  < id_standard_date
        AND   xmril.mov_hdr_id        = xmrih.mov_hdr_id
        AND   ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
        AND   iaj.journal_id         = ijm.journal_id
        AND   itc.doc_type        = iaj.trans_type
        AND   itc.doc_id          = iaj.doc_id
        AND   itc.doc_line        = iaj.doc_line
        AND   ( ( ( itc.doc_type        = cv_doc_type_trni )           --OPM完了在庫トランザクション(標準).文書タイプ = 'TRNI'
          AND     ( itc.reason_code     = cv_reason_code_x122 ) )      --事由コード='移動実績'
           OR   ( ( itc.doc_type        = cv_doc_type_adji )           --OPM完了在庫トランザクション(標準).文書タイプ = 'ADJI'
          AND     ( itc.reason_code     = cv_reason_code_x123 ) ) )    --事由コード='移動実績訂正'
        AND   EXISTS (
                SELECT  1
                FROM    xxinv_mov_lot_details  xmld             --移動ロット詳細(アドオン)
                WHERE   xmld.mov_line_id        = xmril.mov_line_id
                AND     xmld.document_type_code = cv_move          --移動ロット詳細(アドオン)．文書タイプ = '20'
                AND     xmld.record_type_code   IN (cv_actual_ship, cv_actual_arrival)  --移動ロット詳細(アドオン)．レコードタイプ IN ('20','30')
                AND     xmld.lot_id             = itc.lot_id
                And     ROWNUM                  = 1
                )
        AND   NOT EXISTS (
                SELECT  1
                FROM    xxcmn_ic_tran_cmp_arc  xitca          --OPM保留在庫トランザクション(標準)バックアップ
                WHERE   xitca.trans_id = itc.trans_id
                AND     ROWNUM         = 1
              )
      ORDER BY header_id
      ;
--
    -- <カーソル名>レコード型
    TYPE ic_tran_pnd_ttype  IS TABLE OF archive_tran_pnd_cur%ROWTYPE INDEX BY BINARY_INTEGER;        -- OPM保留在庫TRN(標準)(受注)テーブルタイプ
    TYPE ic_tran_cmp_ttype   IS TABLE OF archive_ic_tran_cmp_cur%ROWTYPE INDEX BY BINARY_INTEGER;         -- OPM完了在庫TRN(標準)(移動)テーブルタイプ
--
    TYPE xxcmn_ic_tran_pnd_arc_ttype  IS TABLE OF xxcmn_ic_tran_pnd_arc%ROWTYPE INDEX BY BINARY_INTEGER;      -- OPM保留在庫TRNバックアップテーブルタイプ
    TYPE xxcmn_ic_tran_cmp_arc_ttype  IS TABLE OF xxcmn_ic_tran_cmp_arc%ROWTYPE INDEX BY BINARY_INTEGER;      -- OPM完了在庫TRNバックアップテーブルタイプ
--
    l_ic_tran_pnd_tab     ic_tran_pnd_ttype;                             -- OPM保留在庫トランザクション(標準)(受注)テーブル
    l_ic_tran_cmp_tab      ic_tran_cmp_ttype;                              -- OPM完了在庫トランザクション(標準)(移動)テーブル
--
    l_arc_ic_tran_pnd_tab     xxcmn_ic_tran_pnd_arc_ttype;                  -- OPM保留在庫TRNバックアップテーブル
    l_arc_ic_tran_cmp_tab      xxcmn_ic_tran_cmp_arc_ttype;                  -- OPM完了在庫TRNバックアップテーブル
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_arc_cnt_cmp    := 0;
    gn_arc_cnt_pnd    := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- バックアップ期間取得
    -- ===============================================
    lv_process_step := 'バックアップ期間取得';
    /*
    ln_バックアップ期間 := バックアップ期間取得共通関数（cv_パージ定義コード）;
     */
    ln_archive_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
    IF ( ln_archive_period IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'バックアップ期間:' || TO_CHAR(ln_archive_period));
--
    -- ===============================================
    -- ＩＮパラメータの確認
    -- ===============================================
    lv_process_step := 'パラメータ確認';
    BEGIN
      /*
      iv_proc_dateがNULLの場合
--
        ld_基準日 := 処理日取得共通関数から取得した処理日 - ln_バックアップ期間;
--
      iv_proc_dateがNULLでないの場合
--
        ld_基準日 := TO_DATE(iv_proc_date) - ln_バックアップ期間;
       */
      IF ( iv_proc_date IS NULL ) THEN
--
        ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_archive_period;
--
      ELSE
--
        ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_archive_period;
--
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        ov_errmsg := SQLERRM;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '基準日:' || TO_CHAR(ld_standard_date,cv_date_format));
--
    -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    lv_process_step := 'プロファイル取得';
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップ分割コミット数));
    ln_バックアップレンジ := TO_NUMBER(プロファイル・オプション取得(XXCMN:バックアップレンジ));
    ln_営業単位ID = TO_NUMBER(プロファイル・オプション取得(MO:営業単位));
     */
    BEGIN
      ln_commit_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
      IF ( ln_commit_range IS NULL ) THEN
--
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_commit_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '分割コミット数:' || TO_CHAR(ln_commit_range));
--
    BEGIN
      ln_archive_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_archive_range));
      IF ( ln_archive_range IS NULL ) THEN
--
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_archive_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_get_profile_msg
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => cv_xxcmn_archive_range
                     );
        ov_retcode := cv_status_error;
        RAISE local_process_expt;
    END;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'バックアップレンジ:' || TO_CHAR(ln_archive_range));
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'バックアップFrom:' || TO_CHAR(ld_standard_date-ln_archive_range,cv_date_format));
--
    ln_org_id               := TO_NUMBER(fnd_profile.value(cv_xxcmn_org_id));
--
    -- ===============================================
    -- バックアップ対象OPM保留在庫トランザクション（標準）取得
    -- ===============================================
    lv_process_step := 'バックアップ対象OPM保留在庫TRN（標準）取得';
    /*
    OPENバックアップ対OPM保留在庫トランザクション(標準)取得(
                                     ld_standard_date
                                    ,ln_archive_range
                                    ,ln_org_id
                                   );
    FETCH バックアップ対象OPM保留在庫トランザクション(標準) BULK COLLECT INTO lt_OPM保留在庫トランザクションテーブル;
     */
    OPEN archive_tran_pnd_cur(
                                     ld_standard_date
                                    ,ln_archive_range
                                    ,ln_org_id
                                   );
    FETCH archive_tran_pnd_cur BULK COLLECT INTO l_ic_tran_pnd_tab;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '保留トラン件数' || TO_CHAR(l_ic_tran_pnd_tab.COUNT));
    /*
    IF lt_OPM保留在庫トランザクションテーブル.count > 1 THEN
        BEGIN
          << archive_ic_tran_pnd_loop >>
          FOR ln_main_idx in 1 .. lt_OPM保留在庫トランザクションテーブル.COUNT
          LOOP
    */
    IF ( l_ic_tran_pnd_tab.COUNT ) > 0 THEN
      BEGIN
        << archive_ic_tran_pnd_loop >>
        FOR ln_main_idx in 1 .. l_ic_tran_pnd_tab.COUNT
        LOOP
          -- ===============================================
          -- 分割コミット
          -- ===============================================
          /*
          NVL(ln_分割コミット数, 0) <> 0の場合
           */
          IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
            /*
            前回処理したヘッダIDと取得したヘッダIDが異なる場合は未コミットバックアップ件数を+1
            */
            IF (ln_before_header_id != l_ic_tran_pnd_tab(ln_main_idx).header_id ) THEN
              ln_arc_cnt_pnd_yet := ln_arc_cnt_pnd_yet + 1;
            END IF;
            /*
            ln_未コミットバックアップ件数(OPM保留在庫トランザクション(標準)) > 0
            かつ MOD(ln_未コミットバックアップ件数(OPM保留在庫トランザクション(標準)), ln_分割コミット数) = 0の場合
             */
            IF (  (ln_arc_cnt_pnd_yet > 0)
              AND (MOD(ln_arc_cnt_pnd_yet, ln_commit_range) = 0)
               )
            THEN
--
              /*
              FORALL ln_idx IN 1..ln_未コミットバックアップ件数(OPM保留在庫トランザクション(標準))
                INSERT INTO OPM保留在庫トランザクション(標準)バックアップ
                (
                    全カラム
                  , バックアップ登録日
                  , バックアップ要求ID
                )
                VALUES
                (
                    lt_OPM保留在庫トランザクション(標準)テーブル(ln_idx)全カラム
                  , SYSDATE
                  , 要求ID
                )
               */
              FORALL ln_idx IN 1..ln_arc_cnt_pnd
                INSERT INTO xxcmn_ic_tran_pnd_arc VALUES l_arc_ic_tran_pnd_tab(ln_idx);
--
              /*
              ln_バックアップ件数(OPM保留在庫トランザクション(標準)) := ln_バックアップ件数(OPM保留在庫トランザクション(標準))
                                                                         + ln_未コミットバックアップ件数(OPM保留在庫トランザクション(標準));
              ln_未コミットバックアップ件数(OPM保留在庫トランザクション(標準)) := 0;
              lt_OPM保留在庫トランザクション(標準)テーブル．DELETE;
               */
              gn_arc_cnt_pnd     := gn_arc_cnt_pnd + ln_arc_cnt_pnd;
              ln_arc_cnt_pnd     := 0;
              ln_arc_cnt_pnd_yet := 0;
              l_arc_ic_tran_pnd_tab.DELETE;
--
              /*
              COMMIT;
               */
              COMMIT;
--
            END IF;
--
          END IF;
--
          /*
          ln_カーソルフェッチカウント := ln_カーソルフェッチカウント + 1;
          lt_OPM保留在庫トランザクション(標準)テーブル(ln_未コミットバックアップ件数(OPM保留在庫トランザクション(標準))
                                                                                   := lt_OPM保留在庫トランザクションテーブル;
           */
          ln_arc_cnt_pnd := ln_arc_cnt_pnd + 1;
--
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_id               := l_ic_tran_pnd_tab(ln_main_idx).trans_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).item_id                := l_ic_tran_pnd_tab(ln_main_idx).item_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).line_id                := l_ic_tran_pnd_tab(ln_main_idx).line_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).co_code                := l_ic_tran_pnd_tab(ln_main_idx).co_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).orgn_code              := l_ic_tran_pnd_tab(ln_main_idx).orgn_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).whse_code              := l_ic_tran_pnd_tab(ln_main_idx).whse_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).lot_id                 := l_ic_tran_pnd_tab(ln_main_idx).lot_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).location               := l_ic_tran_pnd_tab(ln_main_idx).location;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).doc_id                 := l_ic_tran_pnd_tab(ln_main_idx).doc_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).doc_type               := l_ic_tran_pnd_tab(ln_main_idx).doc_type;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).doc_line               := l_ic_tran_pnd_tab(ln_main_idx).doc_line;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).line_type              := l_ic_tran_pnd_tab(ln_main_idx).line_type;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).reason_code            := l_ic_tran_pnd_tab(ln_main_idx).reason_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).creation_date          := l_ic_tran_pnd_tab(ln_main_idx).creation_date;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_date             := l_ic_tran_pnd_tab(ln_main_idx).trans_date;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_qty              := l_ic_tran_pnd_tab(ln_main_idx).trans_qty;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_qty2             := l_ic_tran_pnd_tab(ln_main_idx).trans_qty2;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).qc_grade               := l_ic_tran_pnd_tab(ln_main_idx).qc_grade;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).lot_status             := l_ic_tran_pnd_tab(ln_main_idx).lot_status;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_stat             := l_ic_tran_pnd_tab(ln_main_idx).trans_stat;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_um               := l_ic_tran_pnd_tab(ln_main_idx).trans_um;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).trans_um2              := l_ic_tran_pnd_tab(ln_main_idx).trans_um2;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).op_code                := l_ic_tran_pnd_tab(ln_main_idx).op_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).completed_ind          := l_ic_tran_pnd_tab(ln_main_idx).completed_ind;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).staged_ind             := l_ic_tran_pnd_tab(ln_main_idx).staged_ind;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).gl_posted_ind          := l_ic_tran_pnd_tab(ln_main_idx).gl_posted_ind;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).event_id               := l_ic_tran_pnd_tab(ln_main_idx).event_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).delete_mark            := l_ic_tran_pnd_tab(ln_main_idx).delete_mark;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).text_code              := l_ic_tran_pnd_tab(ln_main_idx).text_code;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).last_update_date       := l_ic_tran_pnd_tab(ln_main_idx).last_update_date;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).created_by             := l_ic_tran_pnd_tab(ln_main_idx).created_by;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).last_updated_by        := l_ic_tran_pnd_tab(ln_main_idx).last_updated_by;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).last_update_login      := l_ic_tran_pnd_tab(ln_main_idx).last_update_login;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).program_application_id := l_ic_tran_pnd_tab(ln_main_idx).program_application_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).program_id             := l_ic_tran_pnd_tab(ln_main_idx).program_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).program_update_date    := l_ic_tran_pnd_tab(ln_main_idx).program_update_date;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).request_id             := l_ic_tran_pnd_tab(ln_main_idx).request_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).reverse_id             := l_ic_tran_pnd_tab(ln_main_idx).reverse_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).pick_slip_number       := l_ic_tran_pnd_tab(ln_main_idx).pick_slip_number;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).mvt_stat_status        := l_ic_tran_pnd_tab(ln_main_idx).mvt_stat_status;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).movement_id            := l_ic_tran_pnd_tab(ln_main_idx).movement_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).line_detail_id         := l_ic_tran_pnd_tab(ln_main_idx).line_detail_id;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).invoiced_flag          := l_ic_tran_pnd_tab(ln_main_idx).invoiced_flag;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).intorder_posted_ind    := l_ic_tran_pnd_tab(ln_main_idx).intorder_posted_ind;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).lot_costed_ind         := l_ic_tran_pnd_tab(ln_main_idx).lot_costed_ind;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).archive_date           := SYSDATE;
          l_arc_ic_tran_pnd_tab(ln_arc_cnt_pnd).archive_request_id     := cn_request_id;
--
          /*
          ln_前ヘッダID := lt_OPM保留在庫トランザクションテーブル.ヘッダID;
          */
          ln_before_header_id := l_ic_tran_pnd_tab(ln_main_idx).header_id;
--
        END LOOP archive_ic_tran_pnd_loop;
--
        lv_process_step := 'バックアップ対象OPM保留在庫TRN残処理';
        /*
        FORALL ln_idx IN 1..ln_未コミットバックアップ件数(OPM保留在庫トランザクション(標準))
          INSERT INTO OPM保留在庫トランザクション(標準)バックアップ
          (
               全カラム
            , バックアップ登録日
            , バックアップ要求ID
          )
          VALUES
          (
              lt_OPM保留在庫トランザクション(標準)テーブル(ln_idx)全カラム
            , SYSDATE
            , 要求ID
          )
         */
        FORALL ln_idx IN 1..ln_arc_cnt_pnd
          INSERT INTO xxcmn_ic_tran_pnd_arc VALUES l_arc_ic_tran_pnd_tab(ln_idx);
  --
        /*
        ln_バックアップ件数(OPM保留在庫トランザクション(標準)) := ln_バックアップ件数(OPM保留在庫トランザクション(標準))
                                                                   + ln_未コミットバックアップ件数(OPM保留在庫トランザクション(標準));
        ln_未コミットバックアップ件数(OPM保留在庫トランザクション(標準)) := 0;
        lt_OPM保留在庫トランザクション(標準)テーブル．DELETE;
        --保留在庫トランザクションは正常に終了したのでコミットする
        COMMIT;
         */
        gn_arc_cnt_pnd     := gn_arc_cnt_pnd + ln_arc_cnt_pnd;
        ln_arc_cnt_pnd     := 0;
        ln_arc_cnt_pnd_yet := 0;
        ln_before_header_id := NULL;
        l_arc_ic_tran_pnd_tab.DELETE;
        l_ic_tran_pnd_tab.DELETE;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          lv_token_kinoumei := cv_token_opm_pnd;
          FND_FILE.PUT_LINE (FND_FILE.LOG, SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
          ln_transaction_id := l_arc_ic_tran_pnd_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).trans_id;
          RAISE local_process_expt;
      END;
--
    END IF;
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'OPM保留在庫TRN完了:' || TO_CHAR(gn_arc_cnt_pnd));
--
    -- ===============================================
    -- バックアップ対象OPM完了在庫トランザクション(標準)(移動)取得
    -- ===============================================
    lv_process_step := 'バックアップ対象OPM完了在庫TRN(標準)取得';
    /*
    OPENバックアップ対OPM完了在庫トランザクション(標準)取得(
                                     ld_standard_date
                                    ,ln_archive_range
                                   );
    FETCH バックアップ対象OPM完了在庫トランザクション(標準) BULK COLLECT INTO lt_OPM完了在庫トランザクションテーブル;
     */
    OPEN archive_ic_tran_cmp_cur(
                                     ld_standard_date
                                    ,ln_archive_range
                                   );
    FETCH archive_ic_tran_cmp_cur BULK COLLECT INTO l_ic_tran_cmp_tab;
    FND_FILE.PUT_LINE (FND_FILE.LOG, '完了トラン件数' || TO_CHAR(l_ic_tran_cmp_tab.COUNT));
    /*
    IF lt_OPM完了在庫トランザクションテーブル.count > 1 THEN
        BEGIN
          << archive_ic_tran_cmp_loop >>
          FOR ln_main_idx in 1 .. lt_OPM完了在庫トランザクションテーブル.COUNT
          LOOP
    */
    IF ( l_ic_tran_cmp_tab.COUNT ) > 0 THEN
      BEGIN
        << archive_ic_tran_cmp_loop >>
        FOR ln_main_idx in 1 .. l_ic_tran_cmp_tab.COUNT
        LOOP
          -- ===============================================
          -- 分割コミット
          -- ===============================================
          /*
          NVL(ln_分割コミット数, 0) <> 0の場合
           */
          IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
            /*
            前回処理したヘッダIDと取得したヘッダIDが異なる場合は未コミットバックアップ件数を+1
            */
            IF ( ln_before_header_id != l_ic_tran_cmp_tab(ln_main_idx).header_id ) THEN
              ln_arc_cnt_cmp_yet := ln_arc_cnt_cmp_yet + 1;
            END IF;
            /*
            ln_未コミットバックアップ件数(OPM完了在庫庫トランザクション(標準)) > 0
            かつ MOD(ln_未コミットバックアップ件数(OPM完了在庫トランザクション(標準)), ln_分割コミット数) = 0の場合
             */
            IF (  (ln_arc_cnt_cmp_yet > 0)
              AND (MOD(ln_arc_cnt_cmp_yet, ln_commit_range) = 0)
               )
            THEN
--
              /*
              FORALL ln_idx IN 1..ln_未コミットバックアップ件数(OPM完了在庫トランザクション(標準))
                INSERT INTO OPM完了在庫トランザクション(標準)バックアップ
                (
                    全カラム
                  , バックアップ登録日
                  , バックアップ要求ID
                )
                VALUES
                (
                    lt_OPM完了在庫トランザクション(標準)テーブル(ln_idx)全カラム
                  , SYSDATE
                  , 要求ID
                )
               */
              FORALL ln_idx IN 1..ln_arc_cnt_cmp
                INSERT INTO xxcmn_ic_tran_cmp_arc VALUES l_arc_ic_tran_cmp_tab(ln_idx);
--
              /*
              ln_バックアップ件数(OPM完了在庫トランザクション(標準)) := ln_バックアップ件数(OPM完了在庫トランザクション(標準))
                                                                         + ln_未コミットバックアップ件数(OPM完了在庫トランザクション(標準));
              ln_未コミットバックアップ件数(OPM完了在庫トランザクション(標準)) := 0;
              lt_OPM完了在庫トランザクション(標準)テーブル．DELETE;
               */
              gn_arc_cnt_cmp     := gn_arc_cnt_cmp + ln_arc_cnt_cmp;
              ln_arc_cnt_cmp     := 0;
              ln_arc_cnt_cmp_yet := 0;
              l_arc_ic_tran_cmp_tab.DELETE;
--
              /*
              COMMIT;
               */
              COMMIT;
--
            END IF;
--
          END IF;
--
          /*
          ln_カーソルフェッチカウント := ln_カーソルフェッチカウント + 1;
          lt_OPM完了在庫トランザクション(標準)テーブル(ln_未コミットバックアップ件数(OPM完了在庫トランザクション(標準))
                                                                                   := lt_OPM完了在庫トランザクションテーブル;
           */
          ln_arc_cnt_cmp := ln_arc_cnt_cmp + 1;
--
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_id               := l_ic_tran_cmp_tab(ln_main_idx).trans_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).item_id                := l_ic_tran_cmp_tab(ln_main_idx).item_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).line_id                := l_ic_tran_cmp_tab(ln_main_idx).line_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).co_code                := l_ic_tran_cmp_tab(ln_main_idx).co_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).orgn_code              := l_ic_tran_cmp_tab(ln_main_idx).orgn_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).whse_code              := l_ic_tran_cmp_tab(ln_main_idx).whse_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).lot_id                 := l_ic_tran_cmp_tab(ln_main_idx).lot_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).location               := l_ic_tran_cmp_tab(ln_main_idx).location;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).doc_id                 := l_ic_tran_cmp_tab(ln_main_idx).doc_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).doc_type               := l_ic_tran_cmp_tab(ln_main_idx).doc_type;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).doc_line               := l_ic_tran_cmp_tab(ln_main_idx).doc_line;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).line_type              := l_ic_tran_cmp_tab(ln_main_idx).line_type;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).reason_code            := l_ic_tran_cmp_tab(ln_main_idx).reason_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).creation_date          := l_ic_tran_cmp_tab(ln_main_idx).creation_date;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_date             := l_ic_tran_cmp_tab(ln_main_idx).trans_date;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_qty              := l_ic_tran_cmp_tab(ln_main_idx).trans_qty;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_qty2             := l_ic_tran_cmp_tab(ln_main_idx).trans_qty2;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).qc_grade               := l_ic_tran_cmp_tab(ln_main_idx).qc_grade;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).lot_status             := l_ic_tran_cmp_tab(ln_main_idx).lot_status;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_stat             := l_ic_tran_cmp_tab(ln_main_idx).trans_stat;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_um               := l_ic_tran_cmp_tab(ln_main_idx).trans_um;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).trans_um2              := l_ic_tran_cmp_tab(ln_main_idx).trans_um2;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).op_code                := l_ic_tran_cmp_tab(ln_main_idx).op_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).gl_posted_ind          := l_ic_tran_cmp_tab(ln_main_idx).gl_posted_ind;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).event_id               := l_ic_tran_cmp_tab(ln_main_idx).event_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).text_code              := l_ic_tran_cmp_tab(ln_main_idx).text_code;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).last_update_date       := l_ic_tran_cmp_tab(ln_main_idx).last_update_date;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).created_by             := l_ic_tran_cmp_tab(ln_main_idx).created_by;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).last_updated_by        := l_ic_tran_cmp_tab(ln_main_idx).last_updated_by;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).last_update_login      := l_ic_tran_cmp_tab(ln_main_idx).last_update_login;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).program_application_id := l_ic_tran_cmp_tab(ln_main_idx).program_application_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).program_id             := l_ic_tran_cmp_tab(ln_main_idx).program_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).program_update_date    := l_ic_tran_cmp_tab(ln_main_idx).program_update_date;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).request_id             := l_ic_tran_cmp_tab(ln_main_idx).request_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).movement_id            := l_ic_tran_cmp_tab(ln_main_idx).movement_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).mvt_stat_status        := l_ic_tran_cmp_tab(ln_main_idx).mvt_stat_status;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).line_detail_id         := l_ic_tran_cmp_tab(ln_main_idx).line_detail_id;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).invoiced_flag          := l_ic_tran_cmp_tab(ln_main_idx).invoiced_flag;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).intorder_posted_ind    := l_ic_tran_cmp_tab(ln_main_idx).intorder_posted_ind;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).staged_ind             := l_ic_tran_cmp_tab(ln_main_idx).staged_ind;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).lot_costed_ind         := l_ic_tran_cmp_tab(ln_main_idx).lot_costed_ind;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).archive_date           := SYSDATE;
          l_arc_ic_tran_cmp_tab(ln_arc_cnt_cmp).archive_request_id     := cn_request_id;

          /*
          ln_前ヘッダID := lt_OPM完了在庫トランザクションテーブル.ヘッダID;
          */
          ln_before_header_id := l_ic_tran_cmp_tab(ln_main_idx).header_id;
--
        END LOOP archive_ic_tran_cmp_loop;
--
        lv_process_step := 'バックアップ対象OPM完了在庫TRN(標準)残処理';
        /*
        FORALL ln_idx IN 1..ln_未コミットバックアップ件数(OPM完了在庫トランザクション(標準))
          INSERT INTO OPM完了在庫トランザクション(標準)バックアップ
          (
               全カラム
            , バックアップ登録日
            , バックアップ要求ID
          )
          VALUES
          (
              lt_OPM完了在庫トランザクション(標準)テーブル(ln_idx)全カラム
            , SYSDATE
            , 要求ID
          )
         */
        FORALL ln_idx IN 1..ln_arc_cnt_cmp
          INSERT INTO xxcmn_ic_tran_cmp_arc VALUES l_arc_ic_tran_cmp_tab(ln_idx);
--
        /*
        ln_バックアップ件数(OPM完了在庫トランザクション(標準)) := ln_バックアップ件数(OPM完了在庫トランザクション(標準))
                                                                   + ln_未コミットバックアップ件数(OPM完了在庫トランザクション(標準));
        ln_未コミットバックアップ件数(OPM完了在庫トランザクション(標準)) := 0;
        lt_OPM完了在庫トランザクション(標準)テーブル．DELETE;
         */
        gn_arc_cnt_cmp     := gn_arc_cnt_cmp + ln_arc_cnt_cmp;
        ln_arc_cnt_cmp     := 0;
        ln_arc_cnt_cmp_yet := 0;
        l_arc_ic_tran_cmp_tab.DELETE;
        l_ic_tran_cmp_tab.DELETE;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_token_kinoumei := cv_token_opm_cmp;
          FND_FILE.PUT_LINE (FND_FILE.LOG, SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
          ln_transaction_id := l_arc_ic_tran_cmp_tab(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX).trans_id;
          RAISE local_process_expt;
      END;
--
    END IF;
--
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'OPM完了在庫TRN(移動)完了:' || TO_CHAR(gn_arc_cnt_cmp));

--ここまで
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    WHEN local_process_expt THEN
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lv_process_step);
      IF ( ln_transaction_id IS NOT NULL ) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_local_others_msg
                      ,iv_token_name1  => cv_token_shori
                      ,iv_token_value1 => cv_token_bkup
                      ,iv_token_name2  => cv_token_kinoumei
                      ,iv_token_value2 => lv_token_kinoumei
                      ,iv_token_name3  => cv_token_keyname
                      ,iv_token_value3 => cv_token_trans_id
                      ,iv_token_name4  => cv_token_key
                      ,iv_token_value4 => TO_CHAR(ln_transaction_id)
                     );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lv_process_step);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lv_process_step);
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lv_process_step);
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_proc_date  IN  VARCHAR2       --   1.処理日
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：共通・IF領域

    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';             -- 正常件数： ＆CNT 件
    cv_arc_cnt_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';             -- ＆TBL_NAME ＆SHORI 件数： ＆CNT 件
    cv_token_cnt       CONSTANT VARCHAR2(100) := 'CNT';                         -- 件数メッセージ用トークン名（件数）
    cv_token_table     CONSTANT VARCHAR2(100) := 'TBL_NAME';                    -- 件数メッセージ用トークン名（テーブル名）
    cv_token_shori     CONSTANT VARCHAR2(100) := 'SHORI';                       -- 件数メッセージ用トークン名（処理名）
    cv_table_itp       CONSTANT VARCHAR2(100) := 'OPM保留在庫トランザクション'; -- 件数メッセージ用テーブル名
    cv_table_itc       CONSTANT VARCHAR2(100) := 'OPM完了在庫トランザクション'; -- 件数メッセージ用テーブル名
    cv_shori_name      CONSTANT VARCHAR2(100) := 'バックアップ';                -- 件数メッセージ用処理名

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
       ov_retcode => lv_retcode
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
       iv_proc_date -- 1.処理日
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- ログ出力処理
    -- ===============================================
    --パラメータ(処理日： PAR)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_proc_date_msg
                    ,iv_token_name1  => cv_par_token
                    ,iv_token_value1 => iv_proc_date
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --OPM保留在庫トランザクションバックアップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_arc_cnt_msg
                    ,iv_token_name1  => cv_token_table
                    ,iv_token_value1 => cv_table_itp
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori_name
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_pnd)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --OPM完了在庫トランザクションバックアップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_arc_cnt_msg
                    ,iv_token_name1  => cv_token_table
                    ,iv_token_value1 => cv_table_itc
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori_name
                    ,iv_token_name3  => cv_token_cnt
                    ,iv_token_value3 => TO_CHAR(gn_arc_cnt_cmp)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --正常件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_token_cnt
                    ,iv_token_value1 => TO_CHAR(gn_arc_cnt_pnd + gn_arc_cnt_cmp)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCMN960005C;
/
