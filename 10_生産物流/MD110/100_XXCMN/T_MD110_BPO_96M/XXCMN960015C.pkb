CREATE OR REPLACE PACKAGE BODY XXCMN960015C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960015C(body)
 * Description      : OPM保留／完了在庫トラン更新
 * MD.050           : T_MD050_BPO_96M_OPM保留／完了在庫トラン更新
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
 *  2012/11/20   1.00   K.Boku           新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := '0'; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := '1';   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := '2';  --異常:2
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
  gn_upd_cnt_suspen       NUMBER;             -- 更新件数(OPM保留在庫トランザクション（標準）)
  gn_upd_cnt_complete     NUMBER;             -- 更新件数(OPM完了在庫トランザクション（標準）)
  gt_trans_id_suspen     ic_tran_pnd.trans_id%TYPE;   --トランザクションID（保留）
  gt_trans_id_complete   ic_tran_pnd.trans_id%TYPE;   --トランザクションID（完了）
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMN960015C'; -- パッケージ名
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
    cv_prg_name                CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    cv_appl_short_name         CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：共通・IF領域
    cv_get_priod_msg           CONSTANT VARCHAR2(100) := 'APP-XXCMN-11011';  -- パージ期間の取得に失敗しました。
    cv_get_profile_msg         CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- プロファイル[ ＆NG_PROFILE ]の取得に失敗しました。
    cv_others_msg_suspen       CONSTANT VARCHAR2(100) := 'APP-XXCMN-11038';  -- 更新処理に失敗しました。（保留）
    cv_others_msg_cmp          CONSTANT VARCHAR2(100) := 'APP-XXCMN-11039';  -- 更新処理に失敗しました。（完了）
    cv_token_profile           CONSTANT VARCHAR2(10)  := 'NG_PROFILE';
    cv_token_key               CONSTANT VARCHAR2(10)  := 'KEY';
--
    cv_xxcmn_commit_range      CONSTANT VARCHAR2(100) := 'XXCMN_COMMIT_RANGE';
    cv_xxcmn_purge_range       CONSTANT VARCHAR2(100) := 'XXCMN_PURGE_RANGE';
    cv_org_id                  CONSTANT VARCHAR2(100) := 'ORG_ID';
--
    cv_order_04                CONSTANT VARCHAR2(2)   := '04';
    cv_order_08                CONSTANT VARCHAR2(2)   := '08';
    cv_mov_06                  CONSTANT VARCHAR2(2)   := '06';
    cv_doc_type                CONSTANT VARCHAR2(2)   := '20';
    cv_rec_type_20             CONSTANT VARCHAR2(2)   := '20';
    cv_rec_type_30             CONSTANT VARCHAR2(2)   := '30';
--
    cv_omso                    CONSTANT VARCHAR2(4)   := 'OMSO';
    cv_porc                    CONSTANT VARCHAR2(4)   := 'PORC';
    cv_xfer                    CONSTANT VARCHAR2(4)   := 'XFER';
    cv_trni                    CONSTANT VARCHAR2(4)   := 'TRNI';
    cv_order                   CONSTANT VARCHAR2(5)   := 'ORDER';
    cv_return                  CONSTANT VARCHAR2(6)   := 'RETURN';
    cv_adji                    CONSTANT VARCHAR2(4)   := 'ADJI';
--
    cv_move_actual             CONSTANT VARCHAR2(20)  := 'X122';
    cv_move_actual_upd         CONSTANT VARCHAR2(20)  := 'X123';
--
    cv_date_format             CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
    cv_gl_post_fla             CONSTANT NUMBER  := 1;
--
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
    cv_purge_type   CONSTANT VARCHAR2(1)  := '0';       -- パージタイプ（0:パージ処理期間）
    cv_purge_code   CONSTANT VARCHAR2(30) := '9601';    -- パージ定義コード
--
    -- *** ローカル変数 ***
    ln_upd_cnt_suspen_yet     NUMBER DEFAULT 0;                   -- 未コミット更新件数（OPM保留在庫トランザクション（標準））
    ln_upd_cnt_complete_yet   NUMBER DEFAULT 0;                   -- 未コミット更新件数（OPM完了在庫トランザクション（標準））
    ln_upd_cnt_suspen         NUMBER DEFAULT 0;                   -- 処理件数（OPM保留在庫トランザクション（標準））
    ln_upd_cnt_complete       NUMBER DEFAULT 0;                   -- 処理件数（OPM完了在庫トランザクション（標準））
    ln_purge_period           NUMBER;                             -- パージ期間
    ld_standard_date          DATE;                               -- 基準日
    ln_commit_range           NUMBER;                             -- 分割コミット数
    ln_purge_range            NUMBER;                             -- パージレンジ
    lt_org_id                 oe_order_headers_all.org_id%TYPE;   -- 営業単位
    lv_process_part           VARCHAR2(1000);                     -- 処理部
    ln_before_header_id       NUMBER;                             -- ヘッダID
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    /*
    -- OPM保留在庫トランザクション（標準）（受注）
    CURSOR 更新対象OPM保留在庫トランザクション（標準）（受注）取得
      id_基準日  IN DATE
      in_パージレンジ IN NUMBER
      in_営業単位ＩＤ IN 受注ヘッダ（標準）．営業単位ＩＤ%TYPE
    IS
      SELECT 
             OPM保留在庫トランザクション（標準）．トランザクションID
      FROM 受注ヘッダ（アドオン）バックアップ
           ,    受注タイプ（標準）
           ,    受注ヘッダ（標準）バックアップ
           ,    受注明細（標準）バックアップ
           ,    OPM保留在庫トランザクション（標準）バックアップ
           ,    OPM保留在庫トランザクション（標準）
      WHERE 受注ヘッダ（アドオン）バックアップ．ステータス IN ('04','08')
      AND 受注ヘッダ（アドオン）バックアップ．着荷日 >= id_基準日 - in_パージレンジ
      AND 受注ヘッダ（アドオン）バックアップ．着荷日 < id_基準日
      AND 受注タイプ（標準）．受注タイプID = 受注ヘッダ（アドオン）バックアップ．受注タイプID
      AND 受注タイプ（標準）．受注カテゴリコード = 'ORDER'
      AND 受注ヘッダ（標準）バックアップ．受注ヘッダID = 受注ヘッダ（アドオン）バックアップ．受注ヘッダID
      AND 受注ヘッダ（標準）バックアップ．営業単位ID = in_営業単位ID
      AND 受注明細（標準）バックアップ．受注ヘッダID = 受注ヘッダ（標準）バックアップ．受注ヘッダID
      AND OPM保留在庫トランザクション（標準）バックアップ．取引明細番号 = 受注明細（標準）バックアップ．受注明細ID
      AND OPM保留在庫トランザクション（標準）バックアップ．文書タイプ = 'OMSO'
      AND OPM保留在庫トランザクション（標準）．トランザクションID = OPM保留在庫トランザクション（標準）バックアップ．トランザクションID
      UNION
      -- OPM保留在庫トランザクション（標準）（返品）
      SELECT 
             OPM保留在庫トランザクション（標準）．トランザクションID
      FROM 受注ヘッダ（アドオン）バックアップ
           ,    受注タイプ（標準）
           ,    受注ヘッダ（標準）バックアップ
           ,    受注明細（標準）バックアップ
           ,    受入明細（標準）バックアップ
           ,    OPM保留在庫トランザクション（標準）バックアップ
           ,    OPM保留在庫トランザクション（標準）
      WHERE 受注ヘッダ（アドオン）バックアップ．ステータス IN ('04','08')
      AND 受注ヘッダ（アドオン）バックアップ．着荷日 >= id_基準日 - in_パージレンジ
      AND 受注ヘッダ（アドオン）バックアップ．着荷日 < id_基準日
      AND 受注タイプ（標準）．受注タイプID = 受注ヘッダ（アドオン）バックアップ．受注タイプID
      AND 受注タイプ（標準）．受注カテゴリコード = 'RETURN'
      AND 受注ヘッダ（標準）バックアップ．受注ヘッダID = 受注ヘッダ（アドオン）バックアップ．受注ヘッダID
      AND 受注ヘッダ（標準）バックアップ．営業単位ID = in_営業単位ID
      AND 受注明細（標準）バックアップ．受注ヘッダID = 受注ヘッダ（標準）バックアップ．受注ヘッダID
      AND 受入明細（標準）バックアップ．受注ヘッダID = 受注明細（標準）バックアップ．受注ヘッダID
      AND 受入明細（標準）バックアップ．受注明細ID = 受注明細（標準）バックアップ．受注明細ID
      AND OPM保留在庫トランザクション（標準）バックアップ．文書ID = 受入明細（標準）バックアップ．受入ヘッダID
      AND OPM保留在庫トランザクション（標準）バックアップ．取引明細番号 = 受入明細（標準）バックアップ．明細番号
      AND OPM保留在庫トランザクション（標準）バックアップ．文書タイプ = 'PORC'
      AND OPM保留在庫トランザクション（標準）．トランザクションID = OPM保留在庫トランザクション（標準）バックアップ．トランザクションID
      UNION
      -- OPM保留在庫トランザクション（標準）（移動）
      SELECT 
             OPM保留在庫トランザクション（標準）．トランザクションID
      FROM 移動依頼/指示ヘッダ(アドオン)バックアップ
           ,    移動依頼/指示明細(アドオン)バックアップ
           ,    OPM在庫転送マスタ(標準)
           ,    OPM保留在庫トランザクション(標準)バックアップ
           ,    OPM保留在庫トランザクション(標準)
      WHERE 移動依頼/指示ヘッダ(アドオン)バックアップ．ステータス ＝ '06'
      AND 移動依頼/指示ヘッダ(アドオン)バックアップ．入庫実績日 >= id_基準日 - in_パージレンジ
      AND 移動依頼/指示ヘッダ(アドオン)バックアップ．入庫実績日 < id_基準日
      AND 移動依頼/指示明細(アドオン)バックアップ．移動ヘッダID = 移動依頼/指示ヘッダ(アドオン)バックアップ．移動ヘッダID
      AND OPM保留在庫トランザクション(標準)バックアップ．文書ID = OPM在庫転送マスタ(標準)．転送ID
      AND OPM保留在庫トランザクション(標準)バックアップ．文書タイプ = 'XFER'
      AND OPM保留在庫トランザクション(標準)．トランザクションID = OPM保留在庫トランザクション(標準)バックアップ．トランザクションID
      AND EXISTS (
               SELECT 1
               FROM 移動ロット詳細(アドオン)バックアップ
               WHERE 移動ロット詳細(アドオン)バックアップ．明細ID = 移動依頼/指示明細(アドオン)バックアップ．移動明細ID
               AND 移動ロット詳細(アドオン)バックアップ．文書タイプ = '20'
               AND 移動ロット詳細(アドオン)バックアップ．レコードタイプ IN ('20','30')
               AND OPM在庫転送マスタ(標準)．DFF1 = 移動ロット詳細(アドオン)バックアップ．明細ID
               AND OPM保留在庫トランザクション(標準)バックアップ．ロットID = 移動ロット詳細(アドオン)バックアップ．ロットID
               AND ROWNUM = 1
             )
      AND OPM保留在庫トランザクション（標準）バックアップ．事由コード = 'X122'（移動実績）
     */
    CURSOR upd_suspen_tran_cur(
      id_standard_date           DATE
     ,in_purge_range             NUMBER
     ,it_org_id                  oe_order_headers_all.org_id%TYPE
    )
    IS
      SELECT  /*+ LEADING(xohaa) USE_NL(xohaa otta xoohaa xoolaa xitpa itp) INDEX(xohaa XXCMN_OHAA_N15) */
              0                 AS pre_sort_key
             ,xohaa.header_id   AS header_id
             ,itp.trans_id      AS trans_id
      FROM    xxcmn_order_headers_all_arc     xohaa          -- 受注ヘッダ（アドオン）バックアップ
             ,oe_transaction_types_all        otta           -- 受注タイプ（標準）
             ,xxcmn_oe_order_headers_all_arc  xoohaa         -- 受注ヘッダ（標準）バックアップ
             ,xxcmn_oe_order_lines_all_arc    xoolaa         -- 受注明細（標準）バックアップ
             ,xxcmn_ic_tran_pnd_arc           xitpa          -- OPM保留在庫トランザクション（標準）バックアップ
             ,ic_tran_pnd                     itp            -- OPM保留在庫トランザクション（標準）
      WHERE   xohaa.req_status          IN (cv_order_04, cv_order_08)
      AND     xohaa.arrival_date        >= id_standard_date - in_purge_range
      AND     xohaa.arrival_date         < id_standard_date
      AND     otta.transaction_type_id   = xohaa.order_type_id
      AND     otta.order_category_code   = cv_order
      AND     xoohaa.header_id           = xohaa.header_id
      AND     xoohaa.org_id              = it_org_id
      AND     xoolaa.header_id           = xoohaa.header_id
      AND     xitpa.line_id              = xoolaa.line_id
      AND     xitpa.doc_type             = cv_omso
      AND     itp.trans_id               = xitpa.trans_id
      UNION
      -- OPM保留在庫トランザクション(標準)(返品)
      SELECT  /*+ LEADING(xohaa) USE_NL(xohaa otta xoohaa xoolaa xrsla xitpa itp) INDEX(xohaa XXCMN_OHAA_N15) */
              1                 AS pre_sort_key
             ,xohaa.header_id   AS header_id
             ,itp.trans_id      AS trans_id
      FROM    xxcmn_order_headers_all_arc     xohaa          -- 受注ヘッダ（アドオン）バックアップ
             ,oe_transaction_types_all        otta           -- 受注タイプ（標準）
             ,xxcmn_oe_order_headers_all_arc  xoohaa         -- 受注ヘッダ（標準）バックアップ
             ,xxcmn_oe_order_lines_all_arc    xoolaa         -- 受注明細（標準）バックアップ
             ,xxcmn_rcv_shipment_lines_arc    xrsla          -- 受入明細（標準）バックアップ
             ,xxcmn_ic_tran_pnd_arc           xitpa          -- OPM保留在庫トランザクション（標準）バックアップ
             ,ic_tran_pnd                     itp            -- OPM保留在庫トランザクション（標準）
      WHERE   xohaa.req_status           IN (cv_order_04, cv_order_08)
      AND     xohaa.arrival_date         >= id_standard_date - in_purge_range
      AND     xohaa.arrival_date          < id_standard_date
      AND     otta.transaction_type_id    = xohaa.order_type_id
      AND     otta.order_category_code    = cv_return
      AND     xoohaa.header_id            = xohaa.header_id
      AND     xoohaa.org_id               = it_org_id
      AND     xoolaa.header_id            = xoohaa.header_id
      AND     xrsla.oe_order_header_id    = xoolaa.header_id
      AND     xrsla.oe_order_line_id      = xoolaa.line_id
      AND     xitpa.doc_id                = xrsla.shipment_header_id
      AND     xitpa.doc_line              = xrsla.line_num
      AND     xitpa.doc_type              = cv_porc
      AND     itp.trans_id                = xitpa.trans_id
      UNION
      -- OPM保留在庫トランザクション（標準）（移動）
      SELECT  /*+ LEADING(xmriha) USE_NL(xmriha xmrila ixm xitpa itp) */
              2                       AS pre_sort_key
             ,xmriha.mov_hdr_id       AS header_id
             ,itp.trans_id            AS trans_id
      FROM    xxcmn_mov_req_instr_hdrs_arc     xmriha        -- 移動依頼/指示ヘッダ(アドオン)バックアップ
             ,xxcmn_mov_req_instr_lines_arc    xmrila        -- 移動依頼/指示明細(アドオン)バックアップ
             ,ic_xfer_mst                      ixm           -- OPM在庫転送マスタ(標準)
             ,xxcmn_ic_tran_pnd_arc            xitpa         -- OPM保留在庫トランザクション(標準)バックアップ
             ,ic_tran_pnd                      itp           -- OPM保留在庫トランザクション(標準)
      WHERE   xmriha.status                   = cv_mov_06
      AND     xmriha.actual_arrival_date     >= id_standard_date - in_purge_range
      AND     xmriha.actual_arrival_date      < id_standard_date
      AND     xmrila.mov_hdr_id               = xmriha.mov_hdr_id
      AND     ixm.attribute1                  = TO_CHAR(xmrila.mov_line_id)
      AND     xitpa.doc_id                    = ixm.transfer_id
      AND     xitpa.doc_type                  = cv_xfer 
      AND     itp.trans_id                    = xitpa.trans_id
      AND EXISTS (
               SELECT  1
               FROM    xxcmn_mov_lot_details_arc  xmlda
               WHERE   xmlda.mov_line_id        = xmrila.mov_line_id
               AND     xmlda.document_type_code = cv_doc_type
               AND     xmlda.record_type_code  IN (cv_rec_type_20, cv_rec_type_30) 
               AND     xmlda.lot_id             = xitpa.lot_id
               AND     ROWNUM                   = 1
             )
      AND xitpa.reason_code = cv_move_actual
      ORDER BY pre_sort_key,header_id
      ;
    /*
    -- OPM完了在庫トランザクション（標準）（移動）
    CURSOR 更新対象OPM完了在庫トランザクション（標準）（移動）取得
      id_基準日  IN DATE
      in_パージレンジ IN NUMBER
    IS
      SELECT 
             OPM完了在庫トランザクション（標準）．トランザクションID
      FROM 移動依頼/指示ヘッダ(アドオン)バックアップ
           ,    移動依頼/指示明細(アドオン)バックアップ
           ,    移動ロット詳細(アドオン)バックアップ
           ,    OPMジャーナルマスタ(標準)
           ,    OPM在庫調整ジャーナル(標準)
           ,    OPM完了在庫トランザクション(標準)バックアップ
           ,    OPM完了在庫トランザクション(標準)
      WHERE 移動依頼/指示ヘッダ(アドオン)バックアップ．ステータス ＝ '06'
      AND 移動依頼/指示ヘッダ(アドオン)バックアップ．入庫実績日 >= id_基準日 - in_パージレンジ
      AND 移動依頼/指示ヘッダ(アドオン)バックアップ．入庫実績日 < id_基準日
      AND 移動依頼/指示明細(アドオン)バックアップ．移動ヘッダID = 移動依頼/指示ヘッダ(アドオン)バックアップ．移動ヘッダID
      AND OPM在庫調整ジャーナル(標準)．ジャーナルID = OPMジャーナルマスタ(標準)．ジャーナルID
      AND OPM完了在庫トランザクション(標準)バックアップ．文書タイプ = OPM在庫調整ジャーナル(標準)．文書タイプ
      AND OPM完了在庫トランザクション(標準)バックアップ．文書ID = OPM在庫調整ジャーナル(標準)．文書ID
      AND OPM完了在庫トランザクション(標準)バックアップ．取引明細番号 = OPM在庫調整ジャーナル(標準)．取引明細番号
      AND OPM完了在庫トランザクション(標準)バックアップ．文書タイプ = 'TRNI'
      AND OPM完了在庫トランザクション(標準)．トランザクションID = OPM完了在庫トランザクション(標準)バックアップ．トランザクションID
      AND EXISTS (
               SELECT 1
               FROM 移動ロット詳細(アドオン)バックアップ
               WHERE 移動ロット詳細(アドオン)バックアップ．明細ID = 移動依頼/指示明細(アドオン)バックアップ．移動明細ID
               AND 移動ロット詳細(アドオン)バックアップ．文書タイプ = '20'
               AND 移動ロット詳細(アドオン)バックアップ．レコードタイプ IN ('20','30')
               AND OPMジャーナルマスタ(標準)．DFF1 = 移動ロット詳細(アドオン)バックアップ．明細ID
               AND OPM完了在庫トランザクション(標準)バックアップ．ロットID = 移動ロット詳細(アドオン)バックアップ．ロットID
               AND ROWNUM = 1
             )
      AND （ 
               (          OPM完了在庫トランザクション(標準)バックアップ．文書タイプ = 'ADJI'
                   AND OPM完了在庫トランザクション(標準)バックアップ．ロットID = 移動ロット詳細(アドオン)バックアップ．ロットID
                   AND OPM完了在庫トランザクション（標準）バックアップ．事由コード = 'X122'（積送なし移動）
               )
             OR
               (          OPM完了在庫トランザクション(標準)バックアップ．文書タイプ = 'TRNI'
                   AND OPM完了在庫トランザクション(標準)バックアップ．ロットID = 移動ロット詳細(アドオン)バックアップ．ロットID
                   AND OPM完了在庫トランザクション（標準）バックアップ．事由コード = 'X123'（移動実績訂正）
               )
             )
     */
    CURSOR upd_complete_tran_cur(
      id_standard_date           DATE
     ,in_purge_range             NUMBER
    )
    IS
      SELECT  /*+ LEADING(xmriha) USE_NL(xmriha xmrila ijm iaj xitca itc) */
              xmriha.mov_hdr_id    AS header_id
             ,itc.trans_id         AS trans_id
      FROM    xxcmn_mov_req_instr_hdrs_arc     xmriha        -- 移動依頼/指示ヘッダ(アドオン)バックアップ
             ,xxcmn_mov_req_instr_lines_arc    xmrila        -- 移動依頼/指示明細(アドオン)バックアップ
             ,ic_jrnl_mst                      ijm           -- OPMジャーナルマスタ(標準)
             ,ic_adjs_jnl                      iaj           -- OPM在庫調整ジャーナル(標準)
             ,xxcmn_ic_tran_cmp_arc            xitca         -- OPM完了在庫トランザクション(標準)バックアップ
             ,ic_tran_cmp                      itc           -- OPM完了在庫トランザクション(標準)
      WHERE   xmriha.status                   = cv_mov_06
      AND     xmriha.actual_arrival_date     >= id_standard_date - in_purge_range
      AND     xmriha.actual_arrival_date      < id_standard_date
      AND     xmrila.mov_hdr_id               = xmriha.mov_hdr_id
      AND     ijm.attribute1                  = TO_CHAR(xmrila.mov_line_id)
      AND     iaj.journal_id                  = ijm.journal_id
      AND     xitca.doc_type                  = iaj.trans_type
      AND     xitca.doc_id                    = iaj.doc_id
      AND     xitca.doc_line                  = iaj.doc_line
      AND     itc.trans_id                    = xitca.trans_id
      AND EXISTS (
               SELECT  1
               FROM    xxcmn_mov_lot_details_arc  xmlda
               WHERE   xmlda.mov_line_id        = xmrila.mov_line_id
               AND     xmlda.document_type_code = cv_doc_type
               AND     xmlda.record_type_code  IN (cv_rec_type_20, cv_rec_type_30) 
               AND     xitca.lot_id             = xmlda.lot_id
               AND     ROWNUM                   = 1
             )
      AND     (
                (
                       xitca.doc_type         = cv_trni
                  AND xitca.reason_code       = cv_move_actual
                )
              OR
                (
                       xitca.doc_type         = cv_adji
                  AND xitca.reason_code       = cv_move_actual_upd
                )
              )
    ORDER BY header_id
    ;    
    -- <カーソル名>レコード型
    TYPE l_ic_tran_pnd_ttype  IS TABLE OF upd_suspen_tran_cur%ROWTYPE INDEX BY BINARY_INTEGER;    -- OPM保留在庫TRN(標準)テーブルタイプ
    TYPE l_ic_tran_cmp_ttype  IS TABLE OF upd_complete_tran_cur%ROWTYPE INDEX BY BINARY_INTEGER;  -- OPM完了在庫TRN(標準)テーブルタイプ
--
    TYPE l_xxcmn_ic_tran_pnd_arc_ttype  IS TABLE OF xxcmn_ic_tran_pnd_arc%ROWTYPE INDEX BY BINARY_INTEGER;      -- OPM保留在庫TRNバックアップテーブルタイプ
    TYPE l_xxcmn_ic_tran_cmp_arc_ttype  IS TABLE OF xxcmn_ic_tran_cmp_arc%ROWTYPE INDEX BY BINARY_INTEGER;      -- OPM完了在庫TRNバックアップテーブルタイプ
--
    l_ic_tran_pnd_tab     l_ic_tran_pnd_ttype;        -- OPM保留在庫トランザクション(標準)テーブル
    l_ic_tran_cmp_tab     l_ic_tran_cmp_ttype;        -- OPM完了在庫トランザクション(標準)テーブル
--
    l_arc_ic_tran_pnd_tab     l_xxcmn_ic_tran_pnd_arc_ttype;         -- OPM保留在庫TRNバックアップテーブル
    l_arc_ic_tran_cmp_tab     l_xxcmn_ic_tran_cmp_arc_ttype;         -- OPM完了在庫TRNバックアップテーブル
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_upd_cnt_suspen := 0;
    gn_upd_cnt_complete   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- パージ期間取得
    -- ===============================================
    /*
    ln_パージ期間 := パージ期間取得共通関数（cv_パージ定義コード）;
     */
    lv_process_part := 'パージ期間取得';
    ln_purge_period := xxcmn_common4_pkg.get_purge_period(cv_purge_type, cv_purge_code);
    IF ( ln_purge_period IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_priod_msg
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- ＩＮパラメータの確認
    -- ===============================================
    /*
    iv_proc_dateがNULLの場合
--
      ld_基準日 := 処理日取得共通関数から取得した処理日 - ln_パージ期間;
--
    iv_proc_dateがNULLでないの場合
--
      ld_基準日 := TO_DATE(iv_proc_date) - ln_パージ期間;
     */
    lv_process_part := 'INパラメータの確認';
    IF ( iv_proc_date IS NULL ) THEN
--
      ld_standard_date := xxcmn_common4_pkg.get_syori_date - ln_purge_period;
--
    ELSE
--
      ld_standard_date := TO_DATE(iv_proc_date, cv_date_format) - ln_purge_period;
--
    END IF;
--
    -- ===============================================
    -- プロファイル・オプション値取得
    -- ===============================================
    /*
    ln_分割コミット数 := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージ/バックアップ分割コミット数));
    ln_パージレンジ := TO_NUMBER(プロファイル・オプション取得(XXCMN:パージレンジ));
    ln_営業単位ID := TO_NUMBER(プロファイル・オプション取得（MO:営業単位）);
     */
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_commit_range || '）';
    ln_commit_range := TO_NUMBER(fnd_profile.value(cv_xxcmn_commit_range));
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
--
    END IF;
    lv_process_part := 'プロファイル・オプション値取得（' || cv_xxcmn_purge_range || '）';
    ln_purge_range  := TO_NUMBER(fnd_profile.value(cv_xxcmn_purge_range));
    IF ( ln_purge_range IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_xxcmn_purge_range
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
    lv_process_part := 'プロファイル・オプション値取得（' || cv_org_id || '）';
    lt_org_id  := TO_NUMBER((fnd_profile.value(cv_org_id)));
    IF ( lt_org_id IS NULL ) THEN
--
      ov_errmsg := xxcmn_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_get_profile_msg
                    ,iv_token_name1  => cv_token_profile
                    ,iv_token_value1 => cv_org_id
                   );
      ov_retcode := cv_status_error;
      RAISE local_process_expt;
--
    END IF;
--
    -- ===============================================
    -- 更新対象OPM保留在庫トランザクション（標準）取得
    -- ===============================================
    /*
    OPEN 更新対象OPM保留在庫トランザクション(標準)取得(
                                     ld_standard_date
                                    ,ln_archive_range
                                    ,lt_org_id
                                   );
    FETCH 更新対象OPM保留在庫トランザクション(標準) BULK COLLECT INTO lt_OPM保留在庫トランザクションテーブル;
     */
    OPEN upd_suspen_tran_cur(
      ld_standard_date
     ,ln_purge_range
     ,lt_org_id
    );
    FETCH upd_suspen_tran_cur BULK COLLECT INTO l_ic_tran_pnd_tab;
    IF ( l_ic_tran_pnd_tab.COUNT ) > 0 THEN
      /*
      FOR ln_main_idx IN 1 .. 更新対象OPM保留在庫トランザクション（標準）テーブル.COUNT LOOP
       */
      << upd_suspen_tran_loop >>
      FOR ln_main_idx in 1 .. l_ic_tran_pnd_tab.COUNT
      LOOP
--
        -- ===============================================
        -- 分割コミット
        -- ===============================================
        /*
        NVL(ln_分割コミット数, 0) <> 0の場合
         */
        IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
          /*
          ln_前回ヘッダID <> lt_OPM保留在庫トランザクションテーブル.ヘッダIDの場合、コミットレンジをカウント;
           */
          IF ( ln_before_header_id <> l_ic_tran_pnd_tab(ln_main_idx).header_id ) THEN
            ln_upd_cnt_suspen_yet := ln_upd_cnt_suspen_yet + 1;
          END IF;
          /*
          ln_未コミット更新件数（OPM保留在庫トランザクション（標準）） > 0 
          かつ MOD(ln_未コミット更新件数（OPM保留在庫トランザクション（標準））, ln_分割コミット数) = 0の場合
           */
          IF (  (ln_upd_cnt_suspen_yet > 0)
            AND (MOD(ln_upd_cnt_suspen_yet, ln_commit_range) = 0)
             )
          THEN
--
            /*
            ln_更新件数（OPM保留在庫トランザクション（標準）） := ln_更新件数（OPM保留在庫トランザクション（標準））
                                                                               + ln_処理件数（OPM保留在庫トランザクション（標準））;
            ln_未コミット更新件数（OPM保留在庫トランザクション（標準）） := 0;
            COMMIT;
             */
            gn_upd_cnt_suspen    := gn_upd_cnt_suspen + ln_upd_cnt_suspen;
            ln_upd_cnt_suspen    := 0;
            ln_upd_cnt_suspen_yet:= 0;
            COMMIT;
--
          END IF;
--
        END IF;
--
        /*
        ln_処理件数 := ln_処理件数 + 1;
         */
        ln_upd_cnt_suspen := ln_upd_cnt_suspen + 1;
        l_arc_ic_tran_pnd_tab(ln_upd_cnt_suspen).trans_id := l_ic_tran_pnd_tab(ln_main_idx).trans_id;
        /*
        ln_対象保留在庫トランザクションID := l_ic_tran_pnd_tab(ln_main_idx)．トランザクションID;
        ln_対象保留在庫ヘッダID(一時) := l_ic_tran_pnd_tab(ln_main_idx).header_id;
         */
        gt_trans_id_suspen := l_ic_tran_pnd_tab(ln_main_idx).trans_id;
        ln_before_header_id := l_ic_tran_pnd_tab(ln_main_idx).header_id;
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===================================================
        -- 更新対象OPM保留在庫トランザクション（標準））ロック
        -- ===================================================
        /*
        SELECT
              OPM保留在庫トランザクション（標準）．トランザクションID
        FROM OPM保留在庫トランザクション（標準）
        WHERE OPM保留在庫トランザクション（標準）．トランザクションID = l_ic_tran_pnd_tab(ln_main_idx)．トランザクションID
        FOR UPDATE NOWAIT
         */
        lv_process_part := '更新対象OPM保留在庫トランザクション（標準））ロック';
        SELECT  itp.trans_id      AS trans_id
        INTO    gt_trans_id_suspen
        FROM    ic_tran_pnd  itp
        WHERE   itp.trans_id = l_ic_tran_pnd_tab(ln_main_idx).trans_id
        FOR UPDATE NOWAIT
        ;
--
        -- ===============================================
        -- OPM保留在庫トランザクション（標準）更新
        -- ===============================================
        /*
        UPDATE OPM保留在庫トランザクション（標準）
        SET GL転送済フラグ = 1
           ,   最終更新者 = ユーザーID
           ,   最終更新ログイン = ログインID
           ,   プログラムアプリケーションID = プログラムアプリケーションID
           ,   プログラムID = コンカレントプログラムID
           ,   プログラム更新日 = SYSDATE
           ,   リクエストID = コンカレントリクエストID
        WHERE トランザクションID = l_ic_tran_pnd_tab(ln_main_idx)．トランザクションID
        ;
         */
        lv_process_part := 'OPM保留在庫トランザクション（標準）更新';
        UPDATE ic_tran_pnd
        SET    gl_posted_ind            = cv_gl_post_fla
              ,last_updated_by          = cn_last_updated_by
              ,last_update_login        = cn_last_update_login
              ,program_application_id   = cn_program_application_id
              ,program_id               = cn_program_id
              ,program_update_date      = SYSDATE
              ,request_id               = cn_request_id
        WHERE  trans_id = l_ic_tran_pnd_tab(ln_main_idx).trans_id
        ;
--
      END LOOP upd_suspen_tran_loop;
--
      /*
      ln_更新件数（OPM保留在庫トランザクション（標準）） := ln_更新件数（OPM保留在庫トランザクション（標準））
                                                             + ln_処理件数（OPM保留在庫トランザクション（標準））;
      ln_処理件数（OPM保留在庫トランザクション（標準）） := 0;
      ln_未コミット更新件数（OPM保留在庫トランザクション（標準）） := 0;
      ln_前回ヘッダID := 0;
      lt_OPM完了在庫トランザクション(バックアップ)テーブル．DELETE;
      lt_OPM完了在庫トランザクション(標準)テーブル．DELETE;
       */
      gn_upd_cnt_suspen := gn_upd_cnt_suspen + ln_upd_cnt_suspen;
      ln_upd_cnt_suspen := 0;
      ln_upd_cnt_suspen_yet := 0;
      ln_before_header_id := NULL;
      l_arc_ic_tran_pnd_tab.DELETE;
      l_ic_tran_pnd_tab.DELETE;
      COMMIT;
    END IF;
--
    -- =======================================================
    -- 更新対象OPM完了在庫トランザクション（標準）取得（移動）
    -- =======================================================
    /*
    OPEN更新対象OPM完了在庫トランザクション(標準)取得(
                                     ld_standard_date
                                    ,ln_archive_range
                                   );
    FETCH 更新対象OPM完了在庫トランザクション(標準) BULK COLLECT INTO lt_OPM完了在庫トランザクションテーブル;
     */
    OPEN upd_complete_tran_cur(
      ld_standard_date
     ,ln_purge_range
    );
    FETCH upd_complete_tran_cur BULK COLLECT INTO l_ic_tran_cmp_tab;
    /*
    IF lt_OPM完了在庫トランザクションテーブル.count > 0 THEN
      << upd_complete_tran_loop >>
      FOR ln_main_idx in 1 .. lt_OPM完了在庫トランザクションテーブル.COUNT
      LOOP
    */
    IF ( l_ic_tran_cmp_tab.COUNT ) > 0 THEN
      << upd_complete_tran_loop >>
      FOR ln_main_idx in 1 .. l_ic_tran_cmp_tab.COUNT
      LOOP
--
        -- ===============================================
        -- 分割コミット
        -- ===============================================
        /*
        NVL(ln_分割コミット数, 0) <> 0の場合
         */
        IF ( NVL(ln_commit_range, 0) <> 0 ) THEN
--
          /*
          ln_前回ヘッダID <> lt_OPM完了在庫トランザクションテーブル.ヘッダIDの場合、コミットレンジをカウント;
           */
          IF ( ln_before_header_id <> l_ic_tran_cmp_tab(ln_main_idx).header_id ) THEN
            ln_upd_cnt_complete_yet := ln_upd_cnt_complete_yet + 1;
          END IF;
          /*
          ln_未コミット更新件数（OPM完了在庫トランザクション（標準）） > 0 
          かつ MOD(ln_未コミット更新件数（OPM完了在庫トランザクション（標準））, ln_分割コミット数) = 0の場合
           */
          IF (  (ln_upd_cnt_complete_yet > 0)
            AND (MOD(ln_upd_cnt_complete_yet, ln_commit_range) = 0)
             )
          THEN
--
            /*
            ln_更新件数（OPM完了在庫トランザクション（標準）） := ln_更新件数（OPM完了在庫トランザクション（標準））
                                                                               + ln_未コミット更新件数（OPM完了在庫トランザクション（標準））;
            ln_未コミット更新件数（OPM完了在庫トランザクション（標準）） := 0;
            COMMIT;
             */
            gn_upd_cnt_complete    := gn_upd_cnt_complete + ln_upd_cnt_complete;
            ln_upd_cnt_complete    := 0;
            ln_upd_cnt_complete_yet:= 0;
            COMMIT;
--
          END IF;
--
        END IF;
--
        /*
        ln_処理件数 := ln_処理件数 + 1;
        lt_OPM完了在庫トランザクション(標準)テーブルへバックアップ;
         */
        ln_upd_cnt_complete := ln_upd_cnt_complete + 1;
        l_arc_ic_tran_cmp_tab(ln_upd_cnt_complete).trans_id := l_ic_tran_cmp_tab(ln_main_idx).trans_id;
        /*
        ln_対象完了在庫トランザクションID := l_ic_tran_cmp_tab(ln_main_idx)．トランザクションID;
        ln_対象保留在庫ヘッダID(一時) := l_ic_tran_pnd_tab(ln_main_idx).header_id;
         */
        gt_trans_id_complete := l_ic_tran_cmp_tab(ln_main_idx).trans_id;
        ln_before_header_id := l_ic_tran_cmp_tab(ln_main_idx).header_id;
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===================================================
        -- 更新完了OPM保留在庫トランザクション（標準））ロック
        -- ===================================================
        /*
        SELECT
              OPM完了在庫トランザクション（標準）．トランザクションID
        FROM OPM完了在庫トランザクション（標準）
        WHERE OPM完了在庫トランザクション（標準）．トランザクションID = l_ic_tran_cmp_tab(ln_main_idx)．トランザクションID
        FOR UPDATE NOWAIT
         */
        lv_process_part := '更新対象OPM完了在庫トランザクション（標準））ロック';
        SELECT  itc.trans_id      AS trans_id
        INTO    gt_trans_id_complete
        FROM    ic_tran_cmp  itc
        WHERE   itc.trans_id = l_ic_tran_cmp_tab(ln_main_idx).trans_id
        FOR UPDATE NOWAIT
        ;
--
        -- ===============================================
        -- OPM完了在庫トランザクション（標準）更新
        -- ===============================================
        /*
        UPDATE OPM完了在庫トランザクション（標準）
        SET GL転送済フラグ = 1
           ,   最終更新日 = SYSDATE
           ,   最終更新者 = ユーザーID
           ,   最終更新ログイン = ログインID
           ,   プログラムアプリケーションID = プログラムアプリケーションID
           ,   プログラムID = コンカレントプログラムID
           ,   プログラム更新日 = SYSDATE
           ,   リクエストID = コンカレントリクエストID
        WHERE トランザクションID = l_ic_tran_cmp_tab(ln_main_idx)．トランザクションID
        ;
         */
        lv_process_part := 'OPM保留在庫トランザクション（標準）更新';
        UPDATE ic_tran_cmp
        SET    gl_posted_ind            = cv_gl_post_fla
              ,last_update_date         = SYSDATE
              ,last_updated_by          = cn_last_updated_by
              ,last_update_login        = cn_last_update_login
              ,program_application_id   = cn_program_application_id
              ,program_id               = cn_program_id
              ,program_update_date      = SYSDATE
              ,request_id               = cn_request_id
        WHERE  trans_id = l_ic_tran_cmp_tab(ln_main_idx).trans_id
        ;
--
      END LOOP upd_complete_tran_loop;
--      
    /*
    ln_更新件数（OPM完了在庫トランザクション（標準）） := ln_更新件数（OPM完了在庫トランザクション（標準））
                                                                       + ln_未コミット更新件数（OPM完了在庫トランザクション（標準））;
    ln_未コミット更新件数（OPM完了在庫トランザクション（標準）） := 0;
    lt_OPM完了在庫トランザクション(標準)テーブル．DELETE;
     */
    gn_upd_cnt_complete := gn_upd_cnt_complete + ln_upd_cnt_complete;
    ln_upd_cnt_complete := 0;
    ln_upd_cnt_complete_yet := 0;
    ln_before_header_id := NULL;
    l_ic_tran_cmp_tab.DELETE;
    l_arc_ic_tran_cmp_tab.DELETE;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
    WHEN local_process_expt THEN
      NULL;
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
      IF ( gt_trans_id_suspen IS NOT NULL AND gt_trans_id_complete IS NULL) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_msg_suspen
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(gt_trans_id_suspen)
                     );
      ELSIF ( gt_trans_id_complete IS NOT NULL) THEN
        ov_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_others_msg_cmp
                      ,iv_token_name1  => cv_token_key
                      ,iv_token_value1 => TO_CHAR(gt_trans_id_complete)
                     );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_process_part||cv_msg_part||SQLERRM;
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
    cv_prg_name           CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name    CONSTANT VARCHAR2(10)  := 'XXCMN';            -- アドオン：共通・IF領域
    cv_upd_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCMN-11040';  -- 更新件数： ＆CNT 件
    cv_target_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCMN-11008';  -- 対象件数： ＆CNT 件
    cv_success_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCMN-11009';  -- 正常件数： ＆CNT 件
    cv_error_rec_msg      CONSTANT VARCHAR2(100) := 'APP-XXCMN-00010';  -- エラー件数： ＆CNT 件
    cv_proc_date_msg      CONSTANT VARCHAR2(100) := 'APP-XXCMN-11014';  -- 処理日： ＆PAR
    cv_cnt_token          CONSTANT VARCHAR2(10)  := 'CNT';              -- 件数メッセージ用トークン名
    cv_par_token          CONSTANT VARCHAR2(10)  := 'PAR';              -- 処理日メッセージ用トークン名
    cv_token_tbl_name     CONSTANT VARCHAR2(10)  := 'TBL_NAME';
    cv_token_shori        CONSTANT VARCHAR2(10)  := 'SHORI';
    cv_tbl_name_suspen    CONSTANT VARCHAR2(100) := 'OPM保留在庫トランザクション（標準）';
    cv_tbl_name_cmp       CONSTANT VARCHAR2(100) := 'OPM完了在庫トランザクション（標準）';
    cv_shori              CONSTANT VARCHAR2(10)  := '更新';
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
    --処理日出力
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
    --更新件数１出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_upd_cnt_msg
                    ,iv_token_name1  => cv_token_tbl_name
                    ,iv_token_value1 => cv_tbl_name_suspen
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_upd_cnt_suspen)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --更新件数２出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_upd_cnt_msg
                    ,iv_token_name1  => cv_token_tbl_name
                    ,iv_token_value1 => cv_tbl_name_cmp
                    ,iv_token_name2  => cv_token_shori
                    ,iv_token_value2 => cv_shori
                    ,iv_token_name3  => cv_cnt_token
                    ,iv_token_value3 => TO_CHAR(gn_upd_cnt_complete)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_upd_cnt_suspen + gn_upd_cnt_complete)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    IF (lv_retcode = cv_status_error) THEN
--
      gn_error_cnt := 1;
--
    ELSE
--
      gn_error_cnt := 0;
--
    END IF;
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
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
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --
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
END XXCMN960015C;
/
