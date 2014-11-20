create or replace PACKAGE BODY xxinv570001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv570001c(body)
 * Description      : 移動入出庫実績登録
 * MD.050           : 移動入出庫実績登録(T_MD050_BPO_570)
 * MD.070           : 移動入出庫実績登録(T_MD070_BPO_57A)
 * Version          : 1.23
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc               初期処理 (A-1)
 *  check_mov_num_proc      移動番号重複チェック
 *  get_move_data_proc      移動依頼/指示データ取得 (A-2)
 *  check_proc              妥当性チェック (A-3)
 *  get_data_proc           関連データ取得(A-4)
 *  regist_adji_proc        実績訂正全赤情報登録 (A-6)
 *  regist_xfer_proc        積送あり実績登録 (A-5)
 *  regist_trni_proc        積送なし実績登録 (A-8)
 *  update_flg_proc         実績計上済フラグ,実績訂正フラグ更新(A-10,A-11)
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/19    1.0   Sumie Nakamura   新規作成
 *  2008/04/08    1.1   Sumie Nakamura   内部変更要求No49
 *  2008/06/02    1.2   Kazuo Kumamoto   結合テスト障害対応(出庫実績数量≠入庫実績数量のステータス変更)
 *  2008/07/24    1.3   Takao Ohashi     T_TE080_BPO_540 指摘5対応
 *  2008/08/21    1.4   Yuko  Kawano     内部変更要求対応 #202
 *  2008/09/26    1.5   Yuko  Kawano     統合テスト指摘#156,課題T_S_457,T_S_629対応
 *  2008/12/09    1.6   Naoki Fukuda     本番障害#470,#519(移動番号重複チェックcheck_mov_num_proc追加)
 *  2008/12/11    1.7   Yuko  Kawano     本番障害#633(移動実績訂正不具合対応)
 *  2008/12/11    1.8   Naoki Fukuda     本番障害#441
 *  2008/12/11    1.9   Takao Ohashi     本番障害#672
 *  2008/12/11    1.10  Yuko  Kawano     本番障害#633(移動実績訂正不具合対応)
 *  2008/12/13    1.11  Yuko  Kawano     本番障害#633(移動実績訂正不具合対応)
 *  2008/12/16    1.12  Yuko  Kawano     本番障害#633(移動実績訂正不具合対応)
 *  2008/12/17    1.13  Yuko  Kawano     本番障害(移動実績訂正前数量の更新不具合対応)
 *  2008/12/25    1.14  Hitomi Itou      本番障害#821(出庫実績日・着荷実績日の未来日チェックを追加)
 *  2008/12/25    1.15  Yuko  Kawano     本番障害#844(パラメータ予定日を実績日に変更)
 *  2009/01/16    1.16  Yuko  Kawano     本番障害#988(実績訂正(新規明細追加時の不具合対応))
 *  2009/01/28    1.17  Yuko  Kawano     本番障害#1093(実績ロット不一致対応)
 *  2009/02/04    1.18  Yuko  Kawano     本番障害#1142(実績訂正(標準未反映の不具合対応))
 *  2009/02/19    1.19  Akiyoshi Shiina  本番障害#1179(ロット実績数量0が存在する移動実績情報の処理)
 *  2009/02/19    1.20  Akiyoshi Shiina  本番障害#1194(ロックエラーを警告にする)
 *  2009/02/24    1.21  Akiyoshi Shiina  再対応_本番障害#1179(ロット実績数量0が存在する移動実績情報の処理)
 *  2009/06/09    1.22  Hitomi Itou      本番障害#1526(最新標準データ抽出はMAX(最終更新日)とする)
 *  2010/03/02    1.23  Mariko Miyagawa  E_本稼動_01612(処理対象データの移動ロット詳細フラグをYにする)
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
  gn_target_cnt    NUMBER;      -- 対象件数
  gn_normal_cnt    NUMBER;      -- 正常件数
  gn_error_cnt     NUMBER;      -- エラー件数
  gn_warn_cnt      NUMBER;      -- スキップ件数
--2008/09/26 Y.Kawano Add Start
  gn_out_cnt      NUMBER;      -- 対象外件数
--2008/09/26 Y.Kawano Add End
--
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
  check_lock_expt           EXCEPTION;     -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name    CONSTANT VARCHAR2(100)                := 'xxinv570001c'; -- パッケージ名
--
  gv_c_msg_kbn_inv   CONSTANT VARCHAR2(5)                  := 'XXINV';
  gv_c_msg_kbn_cmn   CONSTANT VARCHAR2(5)                  := 'XXCMN';
--
  -- メッセージ番号
  gv_c_msg_57a_001   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10010'; -- パラメータエラー
  gv_c_msg_57a_002   CONSTANT VARCHAR2(15) := 'APP-XXINV-10032'; -- ロックエラー
  gv_c_msg_57a_003   CONSTANT VARCHAR2(15) := 'APP-XXINV-10000'; -- APIエラー
  gv_c_msg_57a_004   CONSTANT VARCHAR2(15) := 'APP-XXINV-10056'; -- 日付不一致メッセージ
  gv_c_msg_57a_005   CONSTANT VARCHAR2(15) := 'APP-XXINV-10003'; -- カレンダクローズメッセージ
  gv_c_msg_57a_006   CONSTANT VARCHAR2(15) := 'APP-XXINV-10009'; -- データ取得失敗
  gv_c_msg_57a_007   CONSTANT VARCHAR2(15) := 'APP-XXINV-10008'; -- データ取得不可
--
--2008/09/26 Y.Kawano Add Start
  gv_c_msg_57a_008   CONSTANT VARCHAR2(15) := 'APP-XXINV-10174'; -- 同一入出庫保管倉庫エラー
  gv_c_msg_57a_009   CONSTANT VARCHAR2(15) := 'APP-XXINV-10175'; -- 手持数量なしエラー
  gv_c_msg_57a_010   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002'; -- プロファイル取得エラー
--2008/09/26 Y.Kawano Add End
  gv_c_msg_57a_011   CONSTANT VARCHAR2(15) := 'APP-XXINV-10181'; -- 移動番号重複エラー 2008/12/09 本番障害#470,#512 Add
--
-- 2008/12/25 H.Itou Add Start
  gv_c_msg_57a_012   CONSTANT VARCHAR2(15)   := 'APP-XXINV-10182'; -- 未来日エラー
-- 2008/12/25 H.Itou Add End
  -- トークン
  gv_c_tkn_parameter           CONSTANT VARCHAR2(30)  := 'PARAMETER';
  gv_c_tkn_value               CONSTANT VARCHAR2(30)  := 'VALUE';
  gv_c_tkn_api                 CONSTANT VARCHAR2(30)  := 'API_NAME';
  gv_c_tkn_mov_num             CONSTANT VARCHAR2(30)  := 'MOV_NUM';
  gv_c_tkn_mov_line_num        CONSTANT VARCHAR2(30)  := 'MOV_LINE_NUM';
  gv_c_tkn_item                CONSTANT VARCHAR2(30)  := 'ITEM';
  gv_c_tkn_lot_num             CONSTANT VARCHAR2(30)  := 'LOT_NUM';
  gv_c_tkn_shipped_day         CONSTANT VARCHAR2(30)  := 'SHIPPED_DAY';
  gv_c_tkn_ship_to_day         CONSTANT VARCHAR2(30)  := 'SHIP_TO_DAY';
  gv_c_tkn_errmsg              CONSTANT VARCHAR2(30)  := 'ERR_MSG';
  gv_c_tkn_msg                 CONSTANT VARCHAR2(30)  := 'MSG';
--2008/09/26 Y.Kawano Add Start
  gv_c_tkn_profile             CONSTANT VARCHAR2(30)  := 'NG_PROFILE';
--
  gv_c_tkn_shipped_loct        CONSTANT VARCHAR2(30)  := 'SHIPPED_LOCATION';
  gv_c_tkn_ship_to_loct        CONSTANT VARCHAR2(30)  := 'SHIP_TO_LOCATION';
--2008/09/26 Y.Kawano Add End
--
  gv_c_tkn_parameter_val       CONSTANT VARCHAR2(30)  := '移動番号';
  gv_c_tkn_table               CONSTANT VARCHAR2(30)  := 'TABLE';
  gv_c_tkn_table_val           CONSTANT VARCHAR2(60)  := '移動依頼/指示ヘッダ(アドオン)';
  gv_c_tkn_err_val             CONSTANT VARCHAR2(60)  := '移動依頼/指示情報';
-- 2010/03/02 M.Miyagawa Add Start
  gv_c_tkn_table_val_lot       CONSTANT VARCHAR2(60)  := '移動ロット詳細';
-- 2010/03/02 M.Miyagawa Add End
--mod start 1.3
--  gv_c_tkn_api_val_a           CONSTANT VARCHAR2(60)  := '在庫数量API';
--  gv_c_tkn_api_val_x           CONSTANT VARCHAR2(60)  := '在庫転送API';
  gv_c_tkn_api_val_a           CONSTANT VARCHAR2(60)  := '在庫数量';
  gv_c_tkn_api_val_x           CONSTANT VARCHAR2(60)  := '在庫転送';
--mod end 1.3
--
  gv_c_tkn_val_mov_num         CONSTANT VARCHAR2(60)  := '移動番号';
  gv_c_tkn_val_line_num        CONSTANT VARCHAR2(60)  := '明細番号';
  gv_c_tkn_val_item            CONSTANT VARCHAR2(60)  := '品目';
  gv_c_tkn_val_lot_num         CONSTANT VARCHAR2(60)  := 'ロットNo';
  gv_c_tkn_val_o_date          CONSTANT VARCHAR2(60)  := '出庫実績日';
  gv_c_tkn_val_i_date          CONSTANT VARCHAR2(60)  := '入庫実績日';
--
--2008/09/26 Y.Kawano Add Start
  gv_c_tkn_prf_start_day       CONSTANT VARCHAR2(60)  := 'XXINV:在庫転送用ユーザー';
--2008/09/26 Y.Kawano Add End
--
  gv_c_out_date                CONSTANT VARCHAR2(60)   := '出庫実績日';
  gv_c_in_date                 CONSTANT VARCHAR2(60)   := '入庫実績日';
  gv_c_calendar                CONSTANT VARCHAR2(60)   := '在庫カレンダー';
  gv_c_no_data_msg             CONSTANT VARCHAR2(100)  := '会社・組織・倉庫情報取得エラー 移動番号:';
--
  -- 在庫転送API取引タイプ
  gv_c_trans_type1             CONSTANT NUMBER          := '1';  -- Insert
  gv_c_trans_type2             CONSTANT NUMBER          := '2';  -- Release
  gv_c_trans_type3             CONSTANT NUMBER          := '3';  -- Receive
--
  -- 事由コード
  gv_c_msg                     CONSTANT VARCHAR2(100)   := '事由コード 移動実績';
  gv_c_msg_cr                  CONSTANT VARCHAR2(100)   := '事由コード 移動実績訂正';
  gv_c_reason_desc             CONSTANT VARCHAR2(100)   := '移動実績';       -- 移動実績
  gv_c_reason_desc_correct     CONSTANT VARCHAR2(100)   := '移動実績訂正';   -- 移動実績訂正
--
  -- EBS標準文書タイプ
  gv_c_doc_type_xfer           CONSTANT VARCHAR2(10)    := 'XFER';         -- 在庫トラン文書タイプ
  gv_c_doc_type_trni           CONSTANT VARCHAR2(10)    := 'TRNI';         -- 在庫トラン文書タイプ
  gv_c_doc_type_adji           CONSTANT VARCHAR2(10)    := 'ADJI';         -- 在庫トラン文書タイプ
--
  -- ロット管理区分
--  gv_c_lot_ctl_y               CONSTANT NUMBER    := 1;                 -- ロット管理：有
--  gv_c_lot_ctl_n               CONSTANT NUMBER    := 0;                 -- ロット管理：無
--
  gv_status_code               VARCHAR2(10);                -- 移動ステータスコード値
  gv_yn_code                   VARCHAR2(10);                -- YES_NO区分コード値
--
  -- クイックコード 移動タイプ
  gv_c_move_type_y                     CONSTANT VARCHAR2(10)   := '1';             -- 積送あり
  gv_c_move_type_n                     CONSTANT VARCHAR2(10)   := '2';             -- 積送なし
--
  -- クイックコード 移動ステータス
  gv_c_move_status                     CONSTANT VARCHAR2(10)   := '06';            -- 入出庫報告有
--
  -- クイックコード YES_NO区分
  gv_c_ynkbn_y                         CONSTANT VARCHAR2(10)   := 'Y';             -- YES
  gv_c_ynkbn_n                         CONSTANT VARCHAR2(10)   := 'N';             -- NO
--
  -- クイックコード 文書タイプ
  gv_c_document_type                   CONSTANT VARCHAR2(10)   := '20';            -- 移動
--
  -- クイックコード レコードタイプ
  gv_c_document_type_out               CONSTANT VARCHAR2(10)   := '20';            -- 出庫
  gv_c_document_type_in                CONSTANT VARCHAR2(10)   := '30';            -- 入庫
--
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 移動依頼指示データを格納するレコード
  TYPE move_data_rec IS RECORD(
    mov_hdr_id              xxinv_mov_req_instr_headers.mov_hdr_id%TYPE            -- 移動ヘッダID
   ,mov_num                 xxinv_mov_req_instr_headers.mov_num%TYPE               -- 移動番号
   ,mov_type                xxinv_mov_req_instr_headers.mov_type%TYPE              -- 移動タイプ
   ,comp_actual_flg         xxinv_mov_req_instr_headers.comp_actual_flg%TYPE       -- 実績計上済フラグ
   ,correct_actual_flg      xxinv_mov_req_instr_headers.correct_actual_flg%TYPE    -- 実績訂正フラグ
   ,shipped_locat_id        xxinv_mov_req_instr_headers.shipped_locat_id%TYPE      -- 出庫元ID
   ,shipped_locat_code      xxinv_mov_req_instr_headers.shipped_locat_code%TYPE    -- 出庫元保管場所
   ,ship_to_locat_id        xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE      -- 入庫先ID
   ,ship_to_locat_code      xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE    -- 入庫先保管場所
   ,schedule_ship_date      xxinv_mov_req_instr_headers.schedule_ship_date%TYPE    -- 出庫予定日
   ,schedule_arrival_date   xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE -- 入庫予定日
   ,actual_ship_date        xxinv_mov_req_instr_headers.actual_ship_date%TYPE      -- 出庫実績日
   ,actual_arrival_date     xxinv_mov_req_instr_headers.actual_arrival_date%TYPE   -- 入庫実績日
   ,mov_line_id             xxinv_mov_req_instr_lines.mov_line_id%TYPE           -- 移動明細ID
   ,line_number             xxinv_mov_req_instr_lines.line_number%TYPE           -- 明細番号
   ,item_id                 xxinv_mov_req_instr_lines.item_id%TYPE               -- OPM品目ID
   ,item_code               xxinv_mov_req_instr_lines.item_code%TYPE             -- 品目
   ,uom_code                xxinv_mov_req_instr_lines.uom_code%TYPE              -- 単位
   ,shipped_quantity        xxinv_mov_req_instr_lines.shipped_quantity%TYPE      -- 出庫実績数量
   ,ship_to_quantity        xxinv_mov_req_instr_lines.ship_to_quantity%TYPE      -- 入庫実績数量
-- add start 1.3
   ,mov_lot_dtl_id          xxinv_mov_lot_details.mov_lot_dtl_id%TYPE            -- ロット詳細ID(出庫用)
   ,mov_lot_dtl_id2         xxinv_mov_lot_details.mov_lot_dtl_id%TYPE            -- ロット詳細ID(入庫用)
-- add end 1.3
   ,lot_id                  xxinv_mov_lot_details.lot_id%TYPE                    -- ロットID
   ,lot_no                  xxinv_mov_lot_details.lot_no%TYPE                    -- ロットNo
   ,lot_out_actual_date     xxinv_mov_lot_details.actual_date%TYPE               -- 実績日  [出庫]
   ,lot_out_actual_quantity xxinv_mov_lot_details.actual_quantity%TYPE           -- 実績数量[出庫]
   ,lot_in_actual_date      xxinv_mov_lot_details.actual_date%TYPE               -- 実績日  [入庫]
   ,lot_in_actual_quantity  xxinv_mov_lot_details.actual_quantity%TYPE           -- 実績数量[入庫]
--2008/12/11 Y.Kawano Add Start
   ,lot_out_bf_act_quantity xxinv_mov_lot_details.before_actual_quantity%TYPE    -- 訂正前実績数量[出庫]
   ,lot_in_bf_act_quantity  xxinv_mov_lot_details.before_actual_quantity%TYPE    -- 訂正前実績数量[入庫]
--2008/12/11 Y.Kawano Add End
   ,ng_flag                 NUMBER                                               -- NGフラグ
   ,skip_flag               NUMBER                                               -- skipフラグ
--2008/09/26 Y.Kawano Add Start
   ,exist_flag              NUMBER                                               -- 存在チェックフラグ
--2008/09/26 Y.Kawano Add End
   ,err_msg                 varchar2(5000)                                       -- エラー内容
  );
--
  -- 移動依頼指示データを格納するPLSQL表
  TYPE move_data_tbl IS TABLE OF move_data_rec INDEX BY BINARY_INTEGER;
  move_data_rec_tbl     move_data_tbl;  -- 移動情報格納PLSQL表
  move_data_rec_tmp     move_data_tbl;  -- tmp用
  move_target_tbl       move_data_tbl;  -- 実績処理対象用PLSQL表
--
  -- 移動情報を格納するレコード
  TYPE mov_hdr_rec IS RECORD(
    mov_hdr_id            xxinv_mov_req_instr_headers.mov_hdr_id%TYPE,         -- 移動ヘッダID
    mov_num               xxinv_mov_req_instr_headers.mov_num%TYPE             -- 移動番号
--2008/09/26 Y.Kawano Add Start
   ,skip_flag             NUMBER                                               -- skipフラグ
   ,exist_flag            NUMBER                                               -- 存在チェックフラグ
   ,out_flag              NUMBER                                               -- 処理対象外フラグ
--2008/09/26 Y.Kawano Add End
  );
--
  -- 更新対象を格納するPLSQL表
  TYPE mov_hdr_tbl IS TABLE OF mov_hdr_rec INDEX BY BINARY_INTEGER;
  mov_num_rec_tbl     mov_hdr_tbl; -- 更新対象移動キー情報格納用
  err_mov_rec_tbl     mov_hdr_tbl; -- 移動キー情報エラー格納用
  mov_num_ok_tbl      mov_hdr_tbl; -- 更新対象移動キー情報格納用
  err_mov_tmp_rec_tbl mov_hdr_tbl; -- 移動キー情報エラー格納wk用
--
  -- エラー内容格納レコード
  TYPE err_rec IS RECORD(
    out_msg            VARCHAR2(5000)          -- メッセージ内容
  );
--
  -- エラー内容PLSQL表
  TYPE err_rec_tbl IS TABLE OF err_rec INDEX BY BINARY_INTEGER;
  out_err_tbl     err_rec_tbl;                 -- 出力エラーメッセージ
  out_err_tbl2    err_rec_tbl;                 -- 出力エラーメッセージ
--
  -- 在庫数量API実行対象レコード
  TYPE adji_api_rec IS RECORD(
     item_no         IC_ITEM_MST.ITEM_NO%TYPE         -- 品目コード
    ,from_whse_code  IC_WHSE_MST.WHSE_CODE%TYPE       -- 倉庫コード
    ,to_whse_code    IC_WHSE_MST.WHSE_CODE%TYPE       -- 倉庫コード
    ,lot_no          IC_LOTS_MST.LOT_NO%TYPE          -- ロットNo
    ,from_location   MTL_ITEM_LOCATIONS.SEGMENT1%TYPE -- 保管倉庫コード
    ,to_location     MTL_ITEM_LOCATIONS.SEGMENT1%TYPE -- 保管倉庫コード
    ,trans_qty_out   NUMBER                           -- 数量
    ,trans_qty_in    NUMBER                           -- 数量
    ,from_co_code    SY_ORGN_MST_B.CO_CODE%TYPE       -- 会社コード
    ,to_co_code      SY_ORGN_MST_B.CO_CODE%TYPE       -- 会社コード
    ,from_orgn_code  SY_ORGN_MST_B.ORGN_CODE%TYPE     -- 組織コード
    ,to_orgn_code    SY_ORGN_MST_B.ORGN_CODE%TYPE     -- 組織コード
    ,trans_date_out  DATE                             -- 取引日
    ,trans_date_in   DATE                             -- 取引日
    ,attribute1      VARCHAR2(240)                    -- 移動明細ID(DFF1)
   );
--
  TYPE adji_data_tbl IS TABLE OF adji_api_rec INDEX BY BINARY_INTEGER;
  adji_data_rec_tbl      adji_data_tbl;  -- ADJI用
--
  -- 移動API実行対象レコード
  TYPE move_api_rec IS RECORD(
    orgn_code               SY_ORGN_MST_B.ORGN_CODE%TYPE      -- 組織コード
   ,item_no                 IC_ITEM_MST.ITEM_NO%TYPE          -- 品目コード
   ,lot_no                  IC_LOTS_MST.LOT_NO%TYPE           -- ロットNo
   ,source_warehouse        IC_WHSE_MST.WHSE_CODE%TYPE        -- 倉庫コード
   ,source_location         MTL_ITEM_LOCATIONS.SEGMENT1%TYPE  -- 保管倉庫コード
   ,target_warehouse        IC_WHSE_MST.WHSE_CODE%TYPE        -- 倉庫コード
   ,target_location         MTL_ITEM_LOCATIONS.SEGMENT1%TYPE  -- 保管倉庫コード
   ,scheduled_release_date  DATE                              -- リリース予定日
   ,scheduled_receive_date  DATE                              -- 受入予定日
   ,actual_release_date     DATE                              -- リリース実績日
   ,actual_receive_date     DATE                              -- 受入実績日
   ,release_quantity1       NUMBER                            -- 数量
   ,attribute1              VARCHAR2(240)                     -- 移動明細ID(DFF1)
   );
--
  TYPE move_api_tbl IS TABLE OF move_api_rec INDEX BY BINARY_INTEGER;
  move_api_rec_tbl     move_api_tbl;  -- XFER用
--
  -- 移動API実行対象レコード
  TYPE trni_api_rec IS RECORD(
    item_no                 IC_ITEM_MST.ITEM_NO%TYPE          -- 品目コード
   ,from_whse_code          IC_WHSE_MST.WHSE_CODE%TYPE        -- 倉庫コード
   ,to_whse_code            IC_WHSE_MST.WHSE_CODE%TYPE        -- 倉庫コード
   ,lot_no                  IC_LOTS_MST.LOT_NO%TYPE           -- ロットNo
   ,from_location           MTL_ITEM_LOCATIONS.SEGMENT1%TYPE  -- 保管倉庫コード
   ,to_location             MTL_ITEM_LOCATIONS.SEGMENT1%TYPE  -- 保管倉庫コード
   ,trans_qty               NUMBER                            -- 数量
   ,co_code                 SY_ORGN_MST_B.CO_CODE%TYPE        -- 会社コード
   ,orgn_code               SY_ORGN_MST_B.ORGN_CODE%TYPE      -- 組織コード
   ,trans_date              DATE                              -- 取引日
   ,attribute1              VARCHAR2(240)                     -- 移動明細ID(DFF1)
   );
--
  TYPE trni_api_tbl IS TABLE OF trni_api_rec INDEX BY BINARY_INTEGER;
  trni_api_rec_tbl      trni_api_tbl;  -- TRNI用
--
-- 2010/03/02 M.Miyagawa Add Start E_本稼動_01612対応
  TYPE mov_lot_lock_type IS TABLE OF NUMBER(1) INDEX BY BINARY_INTEGER;
  mov_lot_lock_rec     mov_lot_lock_type;  -- 移動ロット詳細ロック取得用
-- 2010/03/02 M.Miyagawa Add End
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_rec_idx        NUMBER DEFAULT 1;   -- 移動依頼指示データ PLSQL表INDEX
  gn_idx            NUMBER DEFAULT 1;   -- INDEX
--
  gd_sysdate                DATE;             -- システム日付
  gn_user_id                NUMBER;           -- ユーザID
  gv_user_name              VARCHAR2(100);    -- ユーザ名
  gn_login_id               NUMBER;           -- 最終更新ログイン
  gn_conc_request_id        NUMBER;           -- 要求ID
  gn_prog_appl_id           NUMBER;           -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
  gn_conc_program_id        NUMBER;           -- コンカレント・プログラムID
--
--
--2008/09/26 Y.Kawano Add Start
    gv_xfer_user_name       VARCHAR2(100);    -- ユーザ名
--2008/09/26 Y.Kawano Add End
--
  gn_created_by             NUMBER(15);                      -- 作成者
  gd_creation_date          DATE;                            -- 作成日
  gv_check_proc_retcode     VARCHAR2(1);                     -- 妥当性チェックステータス
--
  gv_reason_code            SY_REAS_CDS_B.REASON_CODE%TYPE;  -- 移動実績事由コード値
  gv_reason_code_cor        SY_REAS_CDS_B.REASON_CODE%TYPE;  -- 移動実績訂正事由コード値
--
  -- 在庫カレンダ
  gd_close_period_date      DATE;            -- 在庫カレンダークローズ日
--
-- 移動情報抽出対象データなし
   gn_no_data_flg           NUMBER := 0;
-- 2009/02/19 v1.20 ADD START
--
  gb_lock_expt_flg          BOOLEAN := FALSE; -- ロックエラーフラグ
-- 2009/02/19 v1.20 ADD END
--
  /**********************************************************************************
  * Procedure Name   : init_proc
  * Description      : 初期処理 (A-1)
  ***********************************************************************************/
  PROCEDURE init_proc(
    iv_mov_num      IN  VARCHAR2,     --   移動番号
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    ln_cnt                NUMBER;    -- 存在チェック用カウント
    l_setup_return_sts    BOOLEAN;   -- GMI系API呼出用戻り値
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- システム日付取得
    gd_sysdate := SYSDATE;
    -- WHOカラム情報取得
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- コンカレント・プログラムID
    gv_user_name        := FND_GLOBAL.USER_NAME;            -- ユーザー名
--
--2008/09/26 Y.Kawano Add Start
    gv_xfer_user_name   := FND_PROFILE.VALUE('XXINV_XFER_USER');
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_xfer_user_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_cmn,
                                            gv_c_msg_57a_010,         -- プロファイル取得エラー
                                            gv_c_tkn_profile,         -- トークンPROFILE
                                            gv_c_tkn_prf_start_day    -- XXINV:在庫転送用ユーザー
                                            );
       lv_errbuf := lv_errmsg;
       RAISE global_api_expt;
    END IF;
--2008/09/26 Y.Kawano Add End
--
    -- 初期化
    gn_normal_cnt    := 0;
    gn_warn_cnt      := 0;
    gn_target_cnt    := 0;
--2008/09/26 Y.Kawano Add Start
    gn_out_cnt       := 0;
--2008/09/26 Y.Kawano Add End
--
    ------------------------------------------
    -- 入力パラメータ移動番号の存在チェック
    ------------------------------------------
    BEGIN
      -- 入力パラメータ移動番号がNULLでない場合
      IF (iv_mov_num IS NOT NULL) THEN
--
        SELECT count(*)
        INTO   ln_cnt
        FROM   xxinv_mov_req_instr_headers  -- 移動依頼/指示ヘッダ(アドオン)
        WHERE  mov_num = iv_mov_num         -- 移動番号
        --AND    status  = gv_c_move_status   -- ステータス
        ;
--
        -- 存在しない場合
        IF (ln_cnt) = 0 THEN                           --*** パラメータエラー ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_cmn,
                                                gv_c_msg_57a_001,         -- パラメータエラー
                                                gv_c_tkn_parameter,       -- トークンPARAMETER
                                                gv_c_tkn_parameter_val,   -- 移動番号
                                                gv_c_tkn_value,           -- トークンVALUE
                                                iv_mov_num                -- パラメータ入力値
                                                );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN                             --*** パラメータエラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_cmn,
                                              gv_c_msg_57a_001,       -- パラメータエラー
                                              gv_c_tkn_parameter,     -- トークンPARAMETER
                                              gv_c_tkn_parameter_val, -- 移動番号
                                              gv_c_tkn_value,         -- トークンVALUE
                                              iv_mov_num              -- パラメータ入力値
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    ------------------------------------------
    -- 事由コード取得 実績
    ------------------------------------------
    BEGIN
      SELECT srcb.reason_code                       -- 実績用コード
      INTO   gv_reason_code
      FROM   sy_reas_cds_b      srcb                -- 事由コード
            ,sy_reas_cds_tl     srct                -- 事由コード
      WHERE srcb.reason_code  = srct.reason_code
      AND   srct.language     = 'JA'
      AND   srct.source_lang  = 'JA'
      AND   srct.reason_desc1 = gv_c_reason_desc   -- 実績用摘要
      AND   srcb.delete_mark  = 0                  -- 削除マーク
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_006, -- データ取得エラー
                                              gv_c_tkn_msg,     -- トークンMSG
                                              gv_c_msg          -- トークン値
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN                             --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_006, -- データ取得エラー
                                              gv_c_tkn_msg,     -- トークンMSG
                                              gv_c_msg          -- トークン値
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    ------------------------------------------
    -- 事由コード取得 実績訂正
    ------------------------------------------
    BEGIN
      SELECT srcb.reason_code                       -- 実績用コード
      INTO   gv_reason_code_cor
      FROM   sy_reas_cds_b      srcb                -- 事由コード
            ,sy_reas_cds_tl     srct                -- 事由コード
      WHERE srcb.reason_code  = srct.reason_code
      AND   srct.language     = 'JA'
      AND   srct.source_lang  = 'JA'
      AND   srct.reason_desc1 = gv_c_reason_desc_correct   -- 実績用摘要
      AND   srcb.delete_mark  = 0                          -- 削除マーク
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_006, -- データ取得エラー
                                              gv_c_tkn_msg,     -- トークンMSG
                                              gv_c_msg_cr       -- トークン値
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN                             --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_006, -- データ取得エラー
                                              gv_c_tkn_msg,     -- トークンMSG
                                              gv_c_msg_cr       -- トークン値
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    ------------------------------------------
    -- 共通関数により在庫カレンダーの直近クローズ日の取得
    ------------------------------------------
    BEGIN
      -- 在庫カレンダークローズ日取得
      gd_close_period_date :=
          TRUNC(LAST_DAY(FND_DATE.STRING_TO_DATE(xxcmn_common_pkg.get_opminv_close_period(),
               'YYYY/MM')));
    EXCEPTION
      WHEN OTHERS THEN                             --*** データ取得エラー ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_006, -- データ取得エラー
                                              gv_c_tkn_msg,     -- トークンMSG
                                              gv_c_calendar     -- トークン値
                                              );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--

    ------------------------------------------
    -- GMI系API呼出のセットアップ
    ------------------------------------------
    l_setup_return_sts := GMIGUTL.Setup(gv_user_name);
    IF NOT (l_setup_return_sts) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*** Failed to call GMIGUTL.Setup(). ***');
      RAISE global_api_expt;
    END IF;
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
  END init_proc;
--
  -- 2008/12/09 本番障害#470,#519 Add Start ----------------------------------------------------
  /**********************************************************************************
   * Procedure Name   : check_mov_num_proc
   * Description      : 移動番号重複チェック
   ***********************************************************************************/
  PROCEDURE check_mov_num_proc(
    iv_mov_num    IN  VARCHAR2,     --   移動番号
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mov_num_proc'; -- プログラム名
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
    lv_mov_num        xxinv_mov_req_instr_headers.mov_num%TYPE;          -- 移動番号
    ln_rec_cnt        NUMBER;                                            -- レコード件数
--
    -- *** ローカル・カーソル ***
    CURSOR xxinv_move_cur
    IS
      SELECT xmrih2.mov_num
      INTO   ln_rec_cnt
      FROM (
        SELECT xmrih.mov_num
              ,COUNT(xmrih.mov_num) AS mov_num_cnt
        FROM   xxinv_mov_req_instr_headers xmrih                -- 移動依頼/指示ヘッダ(アドオン)
        GROUP BY xmrih.mov_num
      ) xmrih2
      WHERE xmrih2.mov_num_cnt > 1                              -- 重複している
      ORDER BY xmrih2.mov_num;
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
    ln_rec_cnt   := 0;        -- レコード件数初期化
--
    -- **************************************************
    -- パラメータ移動番号が指定されている場合
    -- **************************************************
    IF (iv_mov_num IS NOT NULL) THEN
--
      SELECT COUNT(xmrih.mov_num)
      INTO   ln_rec_cnt
      FROM   xxinv_mov_req_instr_headers xmrih               -- 移動依頼/指示ヘッダ(アドオン)
      WHERE  xmrih.mov_num = iv_mov_num;                     -- 移動番号
--
      IF ln_rec_cnt > 1 THEN  -- パラメータ指定された移動番号が複数件ある場合
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_011,     -- 移動番号重複エラー
                                              gv_c_tkn_mov_num,     -- トークン移動番号
                                              iv_mov_num            -- 重複移動番号
                                              );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
        ov_retcode := gv_status_error;
      END IF;
--
    -- **************************************************
    -- パラメータ移動番号が指定されていない場合
    -- **************************************************
    ELSE
--
      OPEN xxinv_move_cur;
      <<xxinv_mov_cur_loop>>
      LOOP
        FETCH xxinv_move_cur
        INTO lv_mov_num       -- 移動番号
          ;
        EXIT when xxinv_move_cur%NOTFOUND;
--
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                              gv_c_msg_57a_011,     -- 移動番号重複エラー
                                              gv_c_tkn_mov_num,     -- トークン移動番号
                                              lv_mov_num            -- 重複移動番号
                                              );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
        ov_retcode := gv_status_error;
--
      END LOOP xxinv_mov_num_cur_loop;
--
      CLOSE xxinv_move_cur;  -- カーソルクローズ
--
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_mov_num_proc;
  -- 2008/12/09 本番障害#470,#519 Add End ------------------------------------------------------
--
  /**********************************************************************************
   * Procedure Name   : get_move_data_proc
   * Description      : 移動依頼/指示データ取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_move_data_proc(
    iv_mov_num    IN  VARCHAR2,     --   移動番号
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_move_data_proc'; -- プログラム名
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
    lv_mov_num               xxinv_mov_req_instr_headers.MOV_NUM%TYPE;          -- 移動番号
    ln_location_id           xxcmn_item_locations_v.inventory_location_id%TYPE; -- 保管倉庫ID
    ln_item_id               ic_tran_pnd.item_id%TYPE;                          -- 品目ID
    ln_lot_id                ic_tran_pnd.lot_id%TYPE;                           -- ロットID
    lv_location              ic_tran_pnd.location%TYPE;                         -- 保管倉庫コード
    lv_mov_line_id           ic_xfer_mst.attribute1%TYPE;                       -- 移動明細ID
    lv_mov_num_bk            xxinv_mov_req_instr_headers.MOV_NUM%TYPE;          -- 移動番号
-- 2010/03/02 M.Miyagawa Add Start E_本稼動_01612対応
    lv_c_tkn_table_val       VARCHAR(60);                                       -- ロックエラー時テーブル名取得用
-- 2010/03/02 M.Miyagawa Add End
--
    -- *** ローカル・カーソル ***
--
    -- ==================================
    -- 移動情報の取得カーソル
    -- ==================================
--2009/01/28 Y.Kawano Mod Start #1093
--    -- 抽出条件に移動番号あり
--    CURSOR xxinv_mov_num_cur(lv_mov_num IN xxinv_mov_req_instr_headers.mov_num%TYPE)
--    IS
--      SELECT xmrih.mov_hdr_id                                -- 移動ヘッダID
--            ,xmrih.mov_num                                   -- 移動番号
--            ,xmrih.mov_type                                  -- 移動タイプ
--            ,xmrih.comp_actual_flg                           -- 実績計上済フラグ
--            ,xmrih.correct_actual_flg                        -- 実績訂正フラグ
--            ,xmrih.shipped_locat_id                          -- 出庫元ID
--            ,xmrih.shipped_locat_code                        -- 出庫元保管場所
--            ,xmrih.ship_to_locat_id                          -- 入庫先ID
--            ,xmrih.ship_to_locat_code                        -- 入庫先保管場所
--            ,xmrih.schedule_ship_date                        -- 出庫予定日
--            ,xmrih.schedule_arrival_date                     -- 入庫予定日
--            ,xmrih.actual_ship_date                          -- 出庫実績日
--            ,xmrih.actual_arrival_date                       -- 入庫実績日
--            ,xmril.mov_line_id                               -- 移動明細ID
--            ,xmril.line_number                               -- 明細番号
--            ,xmril.item_id                                   -- OPM品目ID
--            ,xmril.item_code                                 -- 品目
--            ,xmril.uom_code                                  -- 単位
--            ,xmril.shipped_quantity                          -- 出庫実績数量
--            ,xmril.ship_to_quantity                          -- 入庫実績数量
---- add start 1.3
--            ,xmld.mov_lot_dtl_id                             -- ロット詳細ID(出庫用)
--            ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ロット詳細ID(入庫用)
---- add end 1.3
--            ,xmld.lot_id                                     -- ロットID
--            ,xmld.lot_no                                     -- ロットNo
--            ,xmld.actual_date       lot_out_actual_date      -- 実績日  [出庫]
--            ,xmld.actual_quantity   lot_out_actual_quantity  -- 実績数量[出庫]
--            ,xmld2.actual_date      lot_in_actual_date       -- 実績日  [入庫]
--            ,xmld2.actual_quantity  lot_in_actual_quantity   -- 実績数量[入庫]
----2008/12/11 Y.Kawano Add Start
--            ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- 実績数量[出庫]
--            ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- 実績数量[入庫]
----2008/12/11 Y.Kawano Add End
--      FROM   xxinv_mov_req_instr_headers xmrih                  -- 移動依頼/指示ヘッダ(アドオン)
--            ,xxinv_mov_req_instr_lines   xmril                  -- 移動依頼/指示明細(アドオン)
--            ,xxinv_mov_lot_details       xmld                   -- 移動ロット詳細(アドオン)  出庫用
--            ,xxinv_mov_lot_details       xmld2                  -- 移動ロット詳細(アドオン)  入庫用
--      WHERE  xmrih.mov_hdr_id          = xmril.mov_hdr_id            -- ヘッダID
--      AND    xmril.mov_line_id         = xmld.mov_line_id            -- 明細ID 出庫
--      AND    xmril.mov_line_id         = xmld2.mov_line_id           -- 明細ID 入庫
--      AND    xmld.document_type_code   = gv_c_document_type      -- 文書タイプ[移動]
--      AND    xmld2.document_type_code  = gv_c_document_type      -- 文書タイプ[移動]
--      AND    xmld.record_type_code     = gv_c_document_type_out      -- レコードタイプ[出庫]
--      AND    xmld2.record_type_code    = gv_c_document_type_in       -- レコードタイプ[入庫]
--      AND    xmld.lot_id               = xmld2.lot_id                -- ロットID
--      AND    xmrih.status              = gv_c_move_status            -- ステータス[ 入出庫報告有 ]
--      AND  (
--            (xmrih.comp_actual_flg    = gv_c_ynkbn_n)               -- 実績計上済フラグ[ OFF ]または
--             OR
--            ((xmrih.comp_actual_flg    = gv_c_ynkbn_y)  AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
--           )                                        -- 実績訂正フラグ[ ON ]かつ実績計上済フラグ[ ON ]
--      AND    xmril.delete_flg          = gv_c_ynkbn_n                -- 取消フラグ[N]
--      AND    xmrih.mov_num             = lv_mov_num                  -- 移動番号
----      ORDER BY xmrih.mov_hdr_id, xmril.line_number,
--      FOR UPDATE OF xmrih.mov_hdr_id NOWAIT;
--
--    -- 抽出条件に移動番号なし
--    CURSOR xxinv_move_cur
--    IS
--      SELECT xmrih.mov_hdr_id                                -- 移動ヘッダID
--            ,xmrih.mov_num                                   -- 移動番号
--            ,xmrih.mov_type                                  -- 移動タイプ
--            ,xmrih.comp_actual_flg                           -- 実績計上済フラグ
--            ,xmrih.correct_actual_flg                        -- 実績訂正フラグ
--            ,xmrih.shipped_locat_id                          -- 出庫元ID
--            ,xmrih.shipped_locat_code                        -- 出庫元保管場所
--            ,xmrih.ship_to_locat_id                          -- 入庫先ID
--            ,xmrih.ship_to_locat_code                        -- 入庫先保管場所
--            ,xmrih.schedule_ship_date                        -- 出庫予定日
--            ,xmrih.schedule_arrival_date                     -- 入庫予定日
--            ,xmrih.actual_ship_date                          -- 出庫実績日
--            ,xmrih.actual_arrival_date                       -- 入庫実績日
--            ,xmril.mov_line_id                               -- 移動明細ID
--            ,xmril.line_number                               -- 明細番号
--            ,xmril.item_id                                   -- OPM品目ID
--            ,xmril.item_code                                 -- 品目
--            ,xmril.uom_code                                  -- 単位
--            ,xmril.shipped_quantity                          -- 出庫実績数量
--            ,xmril.ship_to_quantity                          -- 入庫実績数量
---- add start 1.3
--            ,xmld.mov_lot_dtl_id                             -- ロット詳細ID(出庫用)
--            ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ロット詳細ID(入庫用)
---- add end 1.3
--            ,xmld.lot_id                                     -- ロットID
--            ,xmld.lot_no                                     -- ロット№
--            ,xmld.actual_date       lot_out_actual_date      -- 実績日  [出庫]
--            ,xmld.actual_quantity   lot_out_actual_quantity  -- 実績数量[出庫]
--            ,xmld2.actual_date      lot_in_actual_date       -- 実績日  [入庫]
--            ,xmld2.actual_quantity  lot_in_actual_quantity   -- 実績数量[入庫]
----2008/12/11 Y.Kawano Add Start
--            ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- 実績数量[出庫]
--            ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- 実績数量[入庫]
----2008/12/11 Y.Kawano Add End
--      FROM   xxinv_mov_req_instr_headers xmrih                  -- 移動依頼/指示ヘッダ(アドオン)
--            ,xxinv_mov_req_instr_lines   xmril                  -- 移動依頼/指示明細(アドオン)
--            ,xxinv_mov_lot_details       xmld                   -- 移動ロット詳細(アドオン)  出庫用
--            ,xxinv_mov_lot_details       xmld2                  -- 移動ロット詳細(アドオン)  入庫用
--      WHERE  xmrih.mov_hdr_id          = xmril.mov_hdr_id            -- ヘッダID
--      AND    xmril.mov_line_id         = xmld.mov_line_id            -- 明細ID 出庫
--      AND    xmril.mov_line_id         = xmld2.mov_line_id           -- 明細ID 入庫
--      AND    xmld.document_type_code   = gv_c_document_type      -- 文書タイプ[移動]
--      AND    xmld2.document_type_code  = gv_c_document_type      -- 文書タイプ[移動]
--      AND    xmld.record_type_code     = gv_c_document_type_out      -- レコードタイプ[出庫]
--      AND    xmld2.record_type_code    = gv_c_document_type_in       -- レコードタイプ[入庫]
--      AND    xmld.lot_id               = xmld2.lot_id                -- ロットID
--      AND    xmrih.status              = gv_c_move_status            -- ステータス[ 入出庫報告有 ]
--      AND   (
--             (xmrih.comp_actual_flg    = gv_c_ynkbn_n)               -- 実績計上済フラグ[ OFF ]
--              OR
--             ((xmrih.comp_actual_flg    = gv_c_ynkbn_y) AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
--             )                                          -- 実績訂正フラグ[ ON ] 実績計上済フラグ[ ON ]
--      AND    xmril.delete_flg          = gv_c_ynkbn_n               -- 取消フラグ[N]
--      ORDER BY xmrih.mov_num                                        -- 移動番号
--      FOR UPDATE OF xmrih.mov_hdr_id NOWAIT;
--
    -- 抽出条件に移動番号あり
    CURSOR xxinv_mov_num_cur(lv_mov_num IN xxinv_mov_req_instr_headers.mov_num%TYPE)
    IS
      SELECT main.mov_hdr_id                                -- 移動ヘッダID
            ,main.mov_num                                   -- 移動番号
            ,main.mov_type                                  -- 移動タイプ
            ,main.comp_actual_flg                           -- 実績計上済フラグ
            ,main.correct_actual_flg                        -- 実績訂正フラグ
            ,main.shipped_locat_id                          -- 出庫元ID
            ,main.shipped_locat_code                        -- 出庫元保管場所
            ,main.ship_to_locat_id                          -- 入庫先ID
            ,main.ship_to_locat_code                        -- 入庫先保管場所
            ,main.schedule_ship_date                        -- 出庫予定日
            ,main.schedule_arrival_date                     -- 入庫予定日
            ,main.actual_ship_date                          -- 出庫実績日
            ,main.actual_arrival_date                       -- 入庫実績日
            ,main.mov_line_id                               -- 移動明細ID
            ,main.line_number                               -- 明細番号
            ,main.item_id                                   -- OPM品目ID
            ,main.item_code                                 -- 品目
            ,main.uom_code                                  -- 単位
            ,main.shipped_quantity                          -- 出庫実績数量
            ,main.ship_to_quantity                          -- 入庫実績数量
            ,main.mov_lot_dtl_id                            -- ロット詳細ID(出庫用)
            ,main.mov_lot_dtl_id2                           -- ロット詳細ID(入庫用)
            ,main.lot_id                                     -- ロットID
            ,main.lot_no                                     -- ロットNo
            ,main.lot_out_actual_date                        -- 実績日  [出庫]
            ,main.lot_out_actual_quantity                    -- 実績数量[出庫]
            ,main.lot_in_actual_date                         -- 実績日  [入庫]
            ,main.lot_in_actual_quantity                     -- 実績数量[入庫]
            ,main.lot_out_bf_actual_quantity                 -- 実績数量[出庫]
            ,main.lot_in_bf_actual_quantity                  -- 実績数量[入庫]
      FROM (
          SELECT xmrih.mov_hdr_id                                -- 移動ヘッダID
                ,xmrih.mov_num                                   -- 移動番号
                ,xmrih.mov_type                                  -- 移動タイプ
                ,xmrih.comp_actual_flg                           -- 実績計上済フラグ
                ,xmrih.correct_actual_flg                        -- 実績訂正フラグ
                ,xmrih.shipped_locat_id                          -- 出庫元ID
                ,xmrih.shipped_locat_code                        -- 出庫元保管場所
                ,xmrih.ship_to_locat_id                          -- 入庫先ID
                ,xmrih.ship_to_locat_code                        -- 入庫先保管場所
                ,xmrih.schedule_ship_date                        -- 出庫予定日
                ,xmrih.schedule_arrival_date                     -- 入庫予定日
                ,xmrih.actual_ship_date                          -- 出庫実績日
                ,xmrih.actual_arrival_date                       -- 入庫実績日
                ,xmril.mov_line_id                               -- 移動明細ID
                ,xmril.line_number                               -- 明細番号
                ,xmril.item_id                                   -- OPM品目ID
                ,xmril.item_code                                 -- 品目
                ,xmril.uom_code                                  -- 単位
                ,xmril.shipped_quantity                          -- 出庫実績数量
                ,xmril.ship_to_quantity                          -- 入庫実績数量
                ,xmld.mov_lot_dtl_id                             -- ロット詳細ID(出庫用)
                ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ロット詳細ID(入庫用)
                ,xmld.lot_id                                     -- ロットID
                ,xmld.lot_no                                     -- ロットNo
                ,xmld.actual_date       lot_out_actual_date      -- 実績日  [出庫]
                ,xmld.actual_quantity   lot_out_actual_quantity  -- 実績数量[出庫]
                ,xmld2.actual_date      lot_in_actual_date       -- 実績日  [入庫]
                ,xmld2.actual_quantity  lot_in_actual_quantity   -- 実績数量[入庫]
                ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- 実績数量[出庫]
                ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- 実績数量[入庫]
          FROM   xxinv_mov_req_instr_headers xmrih                  -- 移動依頼/指示ヘッダ(アドオン)
                ,xxinv_mov_req_instr_lines   xmril                  -- 移動依頼/指示明細(アドオン)
                ,xxinv_mov_lot_details       xmld                   -- 移動ロット詳細(アドオン)  出庫用
                ,xxinv_mov_lot_details       xmld2                  -- 移動ロット詳細(アドオン)  入庫用
          WHERE  xmrih.mov_hdr_id             = xmril.mov_hdr_id            -- ヘッダID
          AND    xmril.mov_line_id            = xmld.mov_line_id            -- 明細ID 出庫
          AND    xmld.mov_line_id             = xmld2.mov_line_id(+)
          AND    xmld.document_type_code      = gv_c_document_type      -- 文書タイプ[移動]
          AND    xmld2.document_type_code(+)  = gv_c_document_type      -- 文書タイプ[移動]
          AND    xmld.record_type_code        = gv_c_document_type_out      -- レコードタイプ[出庫]
          AND    xmld2.record_type_code(+)    = gv_c_document_type_in       -- レコードタイプ[入庫]
          AND    xmld.lot_id                  = xmld2.lot_id(+)             -- ロットID
          AND    xmrih.status                 = gv_c_move_status            -- ステータス[ 入出庫報告有 ]
          AND  (
                (xmrih.comp_actual_flg        = gv_c_ynkbn_n)               -- 実績計上済フラグ[ OFF ]または
                 OR
                ((xmrih.comp_actual_flg       = gv_c_ynkbn_y) AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
               )                                        -- 実績訂正フラグ[ ON ]かつ実績計上済フラグ[ ON ]
          AND    xmril.delete_flg             = gv_c_ynkbn_n                -- 取消フラグ[N]
          AND    xmrih.mov_num                = lv_mov_num                  -- 移動番号
          UNION
          SELECT xmrih.mov_hdr_id                                -- 移動ヘッダID
                ,xmrih.mov_num                                   -- 移動番号
                ,xmrih.mov_type                                  -- 移動タイプ
                ,xmrih.comp_actual_flg                           -- 実績計上済フラグ
                ,xmrih.correct_actual_flg                        -- 実績訂正フラグ
                ,xmrih.shipped_locat_id                          -- 出庫元ID
                ,xmrih.shipped_locat_code                        -- 出庫元保管場所
                ,xmrih.ship_to_locat_id                          -- 入庫先ID
                ,xmrih.ship_to_locat_code                        -- 入庫先保管場所
                ,xmrih.schedule_ship_date                        -- 出庫予定日
                ,xmrih.schedule_arrival_date                     -- 入庫予定日
                ,xmrih.actual_ship_date                          -- 出庫実績日
                ,xmrih.actual_arrival_date                       -- 入庫実績日
                ,xmril.mov_line_id                               -- 移動明細ID
                ,xmril.line_number                               -- 明細番号
                ,xmril.item_id                                   -- OPM品目ID
                ,xmril.item_code                                 -- 品目
                ,xmril.uom_code                                  -- 単位
                ,xmril.shipped_quantity                          -- 出庫実績数量
                ,xmril.ship_to_quantity                          -- 入庫実績数量
                ,xmld.mov_lot_dtl_id                             -- ロット詳細ID(出庫用)
                ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ロット詳細ID(入庫用)
                ,xmld2.lot_id                                    -- ロットID
                ,xmld2.lot_no                                    -- ロットNo
                ,xmld.actual_date       lot_out_actual_date      -- 実績日  [出庫]
                ,xmld.actual_quantity   lot_out_actual_quantity  -- 実績数量[出庫]
                ,xmld2.actual_date      lot_in_actual_date       -- 実績日  [入庫]
                ,xmld2.actual_quantity  lot_in_actual_quantity   -- 実績数量[入庫]
                ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- 実績数量[出庫]
                ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- 実績数量[入庫]
          FROM   xxinv_mov_req_instr_headers xmrih                  -- 移動依頼/指示ヘッダ(アドオン)
                ,xxinv_mov_req_instr_lines   xmril                  -- 移動依頼/指示明細(アドオン)
                ,xxinv_mov_lot_details       xmld                   -- 移動ロット詳細(アドオン)  出庫用
                ,xxinv_mov_lot_details       xmld2                  -- 移動ロット詳細(アドオン)  入庫用
          WHERE  xmrih.mov_hdr_id             = xmril.mov_hdr_id            -- ヘッダID
          AND    xmril.mov_line_id            = xmld2.mov_line_id           -- 明細ID 入庫
          AND    xmld.mov_line_id(+)          = xmld2.mov_line_id
          AND    xmld.document_type_code(+)   = gv_c_document_type      -- 文書タイプ[移動]
          AND    xmld2.document_type_code     = gv_c_document_type      -- 文書タイプ[移動]
          AND    xmld.record_type_code(+)     = gv_c_document_type_out      -- レコードタイプ[出庫]
          AND    xmld2.record_type_code       = gv_c_document_type_in       -- レコードタイプ[入庫]
          AND    xmld.lot_id(+)               = xmld2.lot_id                -- ロットID
          AND    xmrih.status                 = gv_c_move_status            -- ステータス[ 入出庫報告有 ]
          AND  (
                (xmrih.comp_actual_flg        = gv_c_ynkbn_n)               -- 実績計上済フラグ[ OFF ]または
                 OR
                ((xmrih.comp_actual_flg    = gv_c_ynkbn_y)  AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
               )                                        -- 実績訂正フラグ[ ON ]かつ実績計上済フラグ[ ON ]
          AND    xmril.delete_flg             = gv_c_ynkbn_n                -- 取消フラグ[N]
          AND    xmrih.mov_num                = lv_mov_num                  -- 移動番号
          ) main
         ,xxinv_mov_req_instr_headers xih
      WHERE      main.mov_hdr_id = xih.mov_hdr_id
      FOR UPDATE OF xih.mov_hdr_id NOWAIT;
--
    -- 抽出条件に移動番号なし
    CURSOR xxinv_move_cur
    IS
      SELECT main.mov_hdr_id                                -- 移動ヘッダID
            ,main.mov_num                                   -- 移動番号
            ,main.mov_type                                  -- 移動タイプ
            ,main.comp_actual_flg                           -- 実績計上済フラグ
            ,main.correct_actual_flg                        -- 実績訂正フラグ
            ,main.shipped_locat_id                          -- 出庫元ID
            ,main.shipped_locat_code                        -- 出庫元保管場所
            ,main.ship_to_locat_id                          -- 入庫先ID
            ,main.ship_to_locat_code                        -- 入庫先保管場所
            ,main.schedule_ship_date                        -- 出庫予定日
            ,main.schedule_arrival_date                     -- 入庫予定日
            ,main.actual_ship_date                          -- 出庫実績日
            ,main.actual_arrival_date                       -- 入庫実績日
            ,main.mov_line_id                               -- 移動明細ID
            ,main.line_number                               -- 明細番号
            ,main.item_id                                   -- OPM品目ID
            ,main.item_code                                 -- 品目
            ,main.uom_code                                  -- 単位
            ,main.shipped_quantity                          -- 出庫実績数量
            ,main.ship_to_quantity                          -- 入庫実績数量
            ,main.mov_lot_dtl_id                            -- ロット詳細ID(出庫用)
            ,main.mov_lot_dtl_id2                           -- ロット詳細ID(入庫用)
            ,main.lot_id                                    -- ロットID
            ,main.lot_no                                    -- ロット№
            ,main.lot_out_actual_date                       -- 実績日  [出庫]
            ,main.lot_out_actual_quantity                   -- 実績数量[出庫]
            ,main.lot_in_actual_date                        -- 実績日  [入庫]
            ,main.lot_in_actual_quantity                    -- 実績数量[入庫]
            ,main.lot_out_bf_actual_quantity                -- 実績数量[出庫]
            ,main.lot_in_bf_actual_quantity                 -- 実績数量[入庫]
      FROM (
          SELECT xmrih.mov_hdr_id                                -- 移動ヘッダID
                ,xmrih.mov_num                                   -- 移動番号
                ,xmrih.mov_type                                  -- 移動タイプ
                ,xmrih.comp_actual_flg                           -- 実績計上済フラグ
                ,xmrih.correct_actual_flg                        -- 実績訂正フラグ
                ,xmrih.shipped_locat_id                          -- 出庫元ID
                ,xmrih.shipped_locat_code                        -- 出庫元保管場所
                ,xmrih.ship_to_locat_id                          -- 入庫先ID
                ,xmrih.ship_to_locat_code                        -- 入庫先保管場所
                ,xmrih.schedule_ship_date                        -- 出庫予定日
                ,xmrih.schedule_arrival_date                     -- 入庫予定日
                ,xmrih.actual_ship_date                          -- 出庫実績日
                ,xmrih.actual_arrival_date                       -- 入庫実績日
                ,xmril.mov_line_id                               -- 移動明細ID
                ,xmril.line_number                               -- 明細番号
                ,xmril.item_id                                   -- OPM品目ID
                ,xmril.item_code                                 -- 品目
                ,xmril.uom_code                                  -- 単位
                ,xmril.shipped_quantity                          -- 出庫実績数量
                ,xmril.ship_to_quantity                          -- 入庫実績数量
                ,xmld.mov_lot_dtl_id                             -- ロット詳細ID(出庫用)
                ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ロット詳細ID(入庫用)
                ,xmld.lot_id                                     -- ロットID
                ,xmld.lot_no                                     -- ロット№
                ,xmld.actual_date       lot_out_actual_date      -- 実績日  [出庫]
                ,xmld.actual_quantity   lot_out_actual_quantity  -- 実績数量[出庫]
                ,xmld2.actual_date      lot_in_actual_date       -- 実績日  [入庫]
                ,xmld2.actual_quantity  lot_in_actual_quantity   -- 実績数量[入庫]
                ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- 実績数量[出庫]
                ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- 実績数量[入庫]
          FROM   xxinv_mov_req_instr_headers xmrih                  -- 移動依頼/指示ヘッダ(アドオン)
                ,xxinv_mov_req_instr_lines   xmril                  -- 移動依頼/指示明細(アドオン)
                ,xxinv_mov_lot_details       xmld                   -- 移動ロット詳細(アドオン)  出庫用
                ,xxinv_mov_lot_details       xmld2                  -- 移動ロット詳細(アドオン)  入庫用
          WHERE  xmrih.mov_hdr_id             = xmril.mov_hdr_id            -- ヘッダID
          AND    xmril.mov_line_id            = xmld.mov_line_id            -- 明細ID 出庫
          AND    xmld.mov_line_id             = xmld2.mov_line_id(+)
          AND    xmld.document_type_code      = gv_c_document_type      -- 文書タイプ[移動]
          AND    xmld2.document_type_code(+)  = gv_c_document_type      -- 文書タイプ[移動]
          AND    xmld.record_type_code        = gv_c_document_type_out      -- レコードタイプ[出庫]
          AND    xmld2.record_type_code(+)    = gv_c_document_type_in       -- レコードタイプ[入庫]
          AND    xmld.lot_id                  = xmld2.lot_id(+)             -- ロットID
          AND    xmrih.status                 = gv_c_move_status            -- ステータス[ 入出庫報告有 ]
          AND   (
                 (xmrih.comp_actual_flg     = gv_c_ynkbn_n)               -- 実績計上済フラグ[ OFF ]
                  OR
                 ((xmrih.comp_actual_flg    = gv_c_ynkbn_y) AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
                 )                                          -- 実績訂正フラグ[ ON ] 実績計上済フラグ[ ON ]
          AND    xmril.delete_flg             = gv_c_ynkbn_n               -- 取消フラグ[N]
          UNION
          SELECT xmrih.mov_hdr_id                                -- 移動ヘッダID
                ,xmrih.mov_num                                   -- 移動番号
                ,xmrih.mov_type                                  -- 移動タイプ
                ,xmrih.comp_actual_flg                           -- 実績計上済フラグ
                ,xmrih.correct_actual_flg                        -- 実績訂正フラグ
                ,xmrih.shipped_locat_id                          -- 出庫元ID
                ,xmrih.shipped_locat_code                        -- 出庫元保管場所
                ,xmrih.ship_to_locat_id                          -- 入庫先ID
                ,xmrih.ship_to_locat_code                        -- 入庫先保管場所
                ,xmrih.schedule_ship_date                        -- 出庫予定日
                ,xmrih.schedule_arrival_date                     -- 入庫予定日
                ,xmrih.actual_ship_date                          -- 出庫実績日
                ,xmrih.actual_arrival_date                       -- 入庫実績日
                ,xmril.mov_line_id                               -- 移動明細ID
                ,xmril.line_number                               -- 明細番号
                ,xmril.item_id                                   -- OPM品目ID
                ,xmril.item_code                                 -- 品目
                ,xmril.uom_code                                  -- 単位
                ,xmril.shipped_quantity                          -- 出庫実績数量
                ,xmril.ship_to_quantity                          -- 入庫実績数量
                ,xmld.mov_lot_dtl_id                             -- ロット詳細ID(出庫用)
                ,xmld2.mov_lot_dtl_id   mov_lot_dtl_id2          -- ロット詳細ID(入庫用)
                ,xmld2.lot_id                                    -- ロットID
                ,xmld2.lot_no                                    -- ロット№
                ,xmld.actual_date       lot_out_actual_date      -- 実績日  [出庫]
                ,xmld.actual_quantity   lot_out_actual_quantity  -- 実績数量[出庫]
                ,xmld2.actual_date      lot_in_actual_date       -- 実績日  [入庫]
                ,xmld2.actual_quantity  lot_in_actual_quantity   -- 実績数量[入庫]
                ,xmld.before_actual_quantity   lot_out_bf_actual_quantity  -- 実績数量[出庫]
                ,xmld2.before_actual_quantity  lot_in_bf_actual_quantity   -- 実績数量[入庫]
          FROM   xxinv_mov_req_instr_headers xmrih                  -- 移動依頼/指示ヘッダ(アドオン)
                ,xxinv_mov_req_instr_lines   xmril                  -- 移動依頼/指示明細(アドオン)
                ,xxinv_mov_lot_details       xmld                   -- 移動ロット詳細(アドオン)  出庫用
                ,xxinv_mov_lot_details       xmld2                  -- 移動ロット詳細(アドオン)  入庫用
          WHERE  xmrih.mov_hdr_id             = xmril.mov_hdr_id            -- ヘッダID
          AND    xmril.mov_line_id            = xmld2.mov_line_id       -- 明細ID 入庫
          AND    xmld.mov_line_id(+)          = xmld2.mov_line_id
          AND    xmld.document_type_code(+)   = gv_c_document_type      -- 文書タイプ[移動]
          AND    xmld2.document_type_code     = gv_c_document_type      -- 文書タイプ[移動]
          AND    xmld.record_type_code(+)     = gv_c_document_type_out      -- レコードタイプ[出庫]
          AND    xmld2.record_type_code       = gv_c_document_type_in       -- レコードタイプ[入庫]
          AND    xmld.lot_id(+)               = xmld2.lot_id                -- ロットID
          AND    xmrih.status                 = gv_c_move_status            -- ステータス[ 入出庫報告有 ]
          AND   (
                 (xmrih.comp_actual_flg     = gv_c_ynkbn_n)               -- 実績計上済フラグ[ OFF ]
                  OR
                 ((xmrih.comp_actual_flg    = gv_c_ynkbn_y) AND (xmrih.correct_actual_flg = gv_c_ynkbn_y))
                 )                                          -- 実績訂正フラグ[ ON ] 実績計上済フラグ[ ON ]
          AND    xmril.delete_flg             = gv_c_ynkbn_n               -- 取消フラグ[N]
          ) main
         ,xxinv_mov_req_instr_headers xih
      WHERE      main.mov_hdr_id = xih.mov_hdr_id
      ORDER BY   main.mov_num                                        -- 移動番号
      FOR UPDATE OF xih.mov_hdr_id NOWAIT;
--2009/01/29 Y.Kawano Mod  End #1093
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
    -- **************************************************
    -- *** 移動依頼/指示データ取得
    -- **************************************************
--
-- 2010/03/02 M.Miyagawa Add Start E_本稼動_01612対応
    lv_c_tkn_table_val := gv_c_tkn_table_val; -- ロックエラー時テーブル名 '移動依頼/指示ヘッダ(アドオン)'
-- 2010/03/02 M.Miyagawa Add End
--    
    -- **************************************************
    -- パラメータ移動番号が指定されている場合
    -- **************************************************
    IF (iv_mov_num IS NOT NULL) THEN
--
      -------------------------------
      -- 抽出条件移動番号ありのカーソルをオープン
      -------------------------------
      OPEN xxinv_mov_num_cur(iv_mov_num);
--
      <<xxinv_mov_num_cur_loop>>
      LOOP
        FETCH xxinv_mov_num_cur
        INTO move_data_rec_tbl(gn_rec_idx).mov_hdr_id                 -- 移動ヘッダID
            ,move_data_rec_tbl(gn_rec_idx).mov_num                    -- 移動番号
            ,move_data_rec_tbl(gn_rec_idx).mov_type                   -- 移動タイプ
            ,move_data_rec_tbl(gn_rec_idx).comp_actual_flg            -- 実績計上済フラグ
            ,move_data_rec_tbl(gn_rec_idx).correct_actual_flg         -- 実績訂正フラグ
            ,move_data_rec_tbl(gn_rec_idx).shipped_locat_id           -- 出庫元ID
            ,move_data_rec_tbl(gn_rec_idx).shipped_locat_code         -- 出庫元保管場所
            ,move_data_rec_tbl(gn_rec_idx).ship_to_locat_id           -- 入庫先ID
            ,move_data_rec_tbl(gn_rec_idx).ship_to_locat_code         -- 入庫先保管場所
            ,move_data_rec_tbl(gn_rec_idx).schedule_ship_date         -- 出庫予定日
            ,move_data_rec_tbl(gn_rec_idx).schedule_arrival_date      -- 入庫予定日
            ,move_data_rec_tbl(gn_rec_idx).actual_ship_date           -- 出庫実績日
            ,move_data_rec_tbl(gn_rec_idx).actual_arrival_date        -- 入庫実績日
            ,move_data_rec_tbl(gn_rec_idx).mov_line_id                -- 移動明細ID
            ,move_data_rec_tbl(gn_rec_idx).line_number                -- 明細番号
            ,move_data_rec_tbl(gn_rec_idx).item_id                    -- OPM品目ID
            ,move_data_rec_tbl(gn_rec_idx).item_code                  -- 品目
            ,move_data_rec_tbl(gn_rec_idx).uom_code                   -- 単位
            ,move_data_rec_tbl(gn_rec_idx).shipped_quantity           -- 出庫実績数量
            ,move_data_rec_tbl(gn_rec_idx).ship_to_quantity           -- 入庫実績数量
-- add start 1.3
            ,move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id             -- ロット詳細ID(出庫用)
            ,move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id2            -- ロット詳細ID(入庫用)
-- add end 1.3
            ,move_data_rec_tbl(gn_rec_idx).lot_id                     -- ロットID
            ,move_data_rec_tbl(gn_rec_idx).lot_no                     -- ロットNo
            ,move_data_rec_tbl(gn_rec_idx).lot_out_actual_date        -- 実績日  [出庫]
            ,move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity    -- 実績数量[出庫]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_actual_date         -- 実績日  [入庫]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity     -- 実績数量[入庫]
-- 2008/12/11 Y.Kawano Add Start
            ,move_data_rec_tbl(gn_rec_idx).lot_out_bf_act_quantity    -- 訂正前実績数量[出庫]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_bf_act_quantity     -- 訂正前実績数量[入庫]
-- 2008/12/11 Y.Kawano Add End
          ;
        EXIT when xxinv_mov_num_cur%NOTFOUND;
--
        -- 対象データ
        IF (move_data_rec_tbl(gn_rec_idx).mov_num <> lv_mov_num_bk)
        OR (lv_mov_num_bk IS NULL)
        THEN
--
          -- 対象件数インクリメント
          gn_target_cnt := gn_target_cnt + 1;
          lv_mov_num_bk := move_data_rec_tbl(gn_rec_idx).mov_num;
--
        END IF;
--
        -- PL/SQL表INDEX インクリメント
        gn_rec_idx := gn_rec_idx + 1;
--
      END LOOP xxinv_mov_num_cur_loop;
--
      IF gn_target_cnt = 0 THEN
        -- 0件の場合、正常終了にする
        gn_no_data_flg := 1;
      END IF;
--
--
      -- カーソルクローズ
      CLOSE xxinv_mov_num_cur;
--
    -- **************************************************
    -- パラメータ移動番号が指定されていない場合
    -- **************************************************
    ELSE
      -------------------------------
      -- 抽出条件移動番号なしのカーソルをオープン
      -------------------------------
      OPEN xxinv_move_cur;
      <<xxinv_mov_cur_loop>>
      LOOP
        FETCH xxinv_move_cur
        INTO move_data_rec_tbl(gn_rec_idx).mov_hdr_id                 -- 移動ヘッダID
            ,move_data_rec_tbl(gn_rec_idx).mov_num                    -- 移動番号
            ,move_data_rec_tbl(gn_rec_idx).mov_type                   -- 移動タイプ
            ,move_data_rec_tbl(gn_rec_idx).comp_actual_flg            -- 実績計上済フラグ
            ,move_data_rec_tbl(gn_rec_idx).correct_actual_flg         -- 実績訂正フラグ
            ,move_data_rec_tbl(gn_rec_idx).shipped_locat_id           -- 出庫元ID
            ,move_data_rec_tbl(gn_rec_idx).shipped_locat_code         -- 出庫元保管場所
            ,move_data_rec_tbl(gn_rec_idx).ship_to_locat_id           -- 入庫先ID
            ,move_data_rec_tbl(gn_rec_idx).ship_to_locat_code         -- 入庫先保管場所
            ,move_data_rec_tbl(gn_rec_idx).schedule_ship_date         -- 出庫予定日
            ,move_data_rec_tbl(gn_rec_idx).schedule_arrival_date      -- 入庫予定日
            ,move_data_rec_tbl(gn_rec_idx).actual_ship_date           -- 出庫実績日
            ,move_data_rec_tbl(gn_rec_idx).actual_arrival_date        -- 入庫実績日
            ,move_data_rec_tbl(gn_rec_idx).mov_line_id                -- 移動明細ID
            ,move_data_rec_tbl(gn_rec_idx).line_number                -- 明細番号
            ,move_data_rec_tbl(gn_rec_idx).item_id                    -- OPM品目ID
            ,move_data_rec_tbl(gn_rec_idx).item_code                  -- 品目
            ,move_data_rec_tbl(gn_rec_idx).uom_code                   -- 単位
            ,move_data_rec_tbl(gn_rec_idx).shipped_quantity           -- 出庫実績数量
            ,move_data_rec_tbl(gn_rec_idx).ship_to_quantity           -- 入庫実績数量
-- add start 1.3
            ,move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id             -- ロット詳細ID(出庫用)
            ,move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id2            -- ロット詳細ID(入庫用)
-- add end 1.3
            ,move_data_rec_tbl(gn_rec_idx).lot_id                     -- ロットID
            ,move_data_rec_tbl(gn_rec_idx).lot_no                     -- ロットNo
            ,move_data_rec_tbl(gn_rec_idx).lot_out_actual_date        -- 実績日  [出庫]
            ,move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity    -- 実績数量[出庫]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_actual_date         -- 実績日  [入庫]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity     -- 実績数量[入庫]
-- 2008/12/11 Y.Kawano Add Start
            ,move_data_rec_tbl(gn_rec_idx).lot_out_bf_act_quantity    -- 訂正前実績数量[出庫]
            ,move_data_rec_tbl(gn_rec_idx).lot_in_bf_act_quantity     -- 訂正前実績数量[入庫]
-- 2008/12/11 Y.Kawano Add End
          ;
        EXIT when xxinv_move_cur%NOTFOUND;
--
        -- 対象データ
        IF (move_data_rec_tbl(gn_rec_idx).mov_num <> lv_mov_num_bk)
        OR (lv_mov_num_bk IS NULL)
        THEN
--
          -- 対象件数インクリメント
          gn_target_cnt := gn_target_cnt + 1;
          lv_mov_num_bk := move_data_rec_tbl(gn_rec_idx).mov_num;
--
        END IF;
--
        -- PL/SQL表INDEX インクリメント
        gn_rec_idx := gn_rec_idx + 1;
--
      END LOOP xxinv_mov_cur_loop;
--
      IF gn_target_cnt = 0 THEN
        -- 0件の場合、正常終了にする
        gn_no_data_flg := 1;
      END IF;
--
      -- カーソルクローズ
      CLOSE xxinv_move_cur;
--
    END IF;
-- 2010/03/02 M.Miyagawa Add Start E_本稼動_01612対応
    lv_c_tkn_table_val := gv_c_tkn_table_val_lot; -- '移動ロット詳細'
--
    <<mov_lot_lock_loop>>
    FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
      --移動ロット詳細ロック取得
      SELECT 1
      BULK   COLLECT INTO mov_lot_lock_rec
      FROM   XXINV_MOV_LOT_DETAILS xmld
      WHERE  xmld.mov_line_id         IN (SELECT xmril.mov_line_id
                                          FROM   xxinv_mov_req_instr_lines    xmril
                                          WHERE  xmril.mov_hdr_id = move_data_rec_tbl(gn_rec_idx).mov_hdr_id
                                         )
       AND   xmld.document_type_code   = gv_c_document_type
      FOR UPDATE NOWAIT;
    END LOOP mov_lot_lock_loop;
-- 2010/03/02 M.Miyagawa Add End
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN check_lock_expt THEN                           --*** ロック取得エラー ***
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
-- 2010/03/02 M.Miyagawa Add Start E_本稼動_01612対応
-- 移動ロット詳細ロックエラー時処理件数クリア
      gn_target_cnt := 0;
-- 2010/03/02 M.Miyagawa Add End
      -- エラーメッセージ取得
-- 2009/02/19 v1.20 UPDATE START
--      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
      lv_errmsg := '警告：'
                   || xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
-- 2009/02/19 v1.20 UPDATE END
                                            gv_c_msg_57a_002,   -- ロックエラー
                                            gv_c_tkn_table,     -- トークンTABLE
-- 2010/03/02 M.Miyagawa Mod Start E_本稼動_01612対応
                                            lv_c_tkn_table_val  -- トークン値
--                                            gv_c_tkn_table_val  -- トークン値
-- 2010/03/02 M.Miyagawa Mod End
                                            );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
-- 2009/02/19 v1.20 ADD START
      gb_lock_expt_flg := TRUE; -- ロックエラーフラグ
--
-- 2009/02/19 v1.20 ADD END
    WHEN NO_DATA_FOUND THEN                             --*** データなし ***
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      IF (xxinv_mov_num_cur%ISOPEN) THEN
        CLOSE xxinv_mov_num_cur;
      END IF;
--
      -- 0件の場合、正常終了にする
      gn_no_data_flg := 1;
--
--#################################  固定例外処理部 START   ####################################
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xxinv_move_cur%ISOPEN) THEN
        CLOSE xxinv_move_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_move_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_proc
   * Description      : 妥当性チェック (A-3)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf     OUT VARCHAR2,                 --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,                 --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)                 --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc'; -- プログラム名
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
    lv_msg_log           VARCHAR2(2000) := NULL;  -- メッセージ文字列格納用
    lv_wk_errmsg         VARCHAR2(2000) := NULL;  -- メッセージ文字列格納用
    lv_out_actual_date   VARCHAR2(20);            -- 出庫日ログ出力用
    lv_in_actual_date    VARCHAR2(20);            -- 入庫日ログ出力用
    lv_err_mov_num       xxinv_mov_req_instr_headers.mov_num%TYPE;    -- 移動番号wk用
    lv_mov_num_bk        xxinv_mov_req_instr_headers.mov_num%TYPE;    -- 移動番号wk用
    lv_mov_hdr_id_bk     xxinv_mov_req_instr_headers.mov_hdr_id%TYPE; -- 移動番号wk用
    lv_pre_mov_num       xxinv_mov_req_instr_headers.mov_num%TYPE;    -- 移動番号wk用
    ln_tmp_idx           NUMBER;
    ln_idx               NUMBER;
--
--2008/08/21 Y.Kawano Add Start
    lv_err_flg           VARCHAR(1);              -- エラーチェック用フラグ
--2008/08/21 Y.Kawano Add End
--2008/09/26 Y.Kawano Add Start
    ln_exist             NUMBER;                  -- 存在チェック用フラグ
    lt_bef_mov_num       xxinv_mov_req_instr_headers.mov_num%TYPE;    -- 移動番号wk用
--2008/09/26 Y.Kawano Add End
    lv_whse_code_from    xxcmn_item_locations_v.whse_code%TYPE;       -- 2008/12/11 本番障害#441 Add
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --------------------------------------------------------------
    FND_FILE.PUT_LINE(FND_FILE.LOG,'------ check_proc START ------');
    --------------------------------------------------------------
    -- **************************************************
    -- *** 取得したレコードの各チェック
    -- **************************************************
    <<check_loop>>
    FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
--
      -----------------------
      -- for debug
      FND_FILE.PUT_LINE(FND_FILE.LOG,'LOOP START');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')mov_num='|| move_data_rec_tbl(gn_rec_idx).mov_num);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')line_number='|| move_data_rec_tbl(gn_rec_idx).line_number);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')item_code='|| move_data_rec_tbl(gn_rec_idx).item_code);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_no='|| move_data_rec_tbl(gn_rec_idx).lot_no);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_out_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_in_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity);
      -----------------------
--
      -- フラグ初期化
      move_data_rec_tbl(gn_rec_idx).ng_flag   := 0;
--add start 1.2
      move_data_rec_tbl(gn_rec_idx).skip_flag := 0;
--add end 1.2
--2008/09/26 Y.Kawano Add Start
      ln_exist                                 := 0;
      move_data_rec_tbl(gn_rec_idx).exist_flag := 0;
--2008/09/26 Y.Kawano Add End
--
      -- **************************************************
      -- *** 出庫実績数量と入庫実績数量の比較
      -- **************************************************
      -- 出庫実績数量と入庫実績数量が異なる場合
--2009/01/28 Y.Kawano Mod Start #1093
--      IF ( move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity
--           <> move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity ) THEN
      IF (
           ( move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity
             <> move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity )
-- 2009/02/19 v1.19 UPDATE START
--        OR (  ( move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity IS NOT NULL )
        OR (  ( move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity > 0 )
-- 2009/02/19 v1.19 UPDATE END
          AND ( move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity  IS NULL ) )
        OR (  ( move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity IS NULL )
-- 2009/02/19 v1.19 UPDATE START
--          AND ( move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity  IS NOT NULL ) )
          AND ( move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity  > 0 ) )
-- 2009/02/19 v1.19 UPDATE END
         )
      THEN
--2009/01/28 Y.Kawano Mod End   #1093
--
        move_data_rec_tbl(gn_rec_idx).ng_flag   := 1;  -- NGフラグ
--add start 1.2
        move_data_rec_tbl(gn_rec_idx).skip_flag := 1;  -- スキップフラグ
--add end 1.2
--
      END IF;
--
--2008/09/26 Y.Kawano Add Start
      -- 前処理でエラーでない場合
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** 出庫元保管倉庫と入庫先保管倉庫の比較
        -- **************************************************
        -- 出庫元保管倉庫と入庫先保管倉庫が同じ保管倉庫の場合
        IF ( move_data_rec_tbl(gn_rec_idx).shipped_locat_id
                = move_data_rec_tbl(gn_rec_idx).ship_to_locat_id ) THEN
--
          -- エラーメッセージ
          lv_wk_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                   gv_c_msg_57a_008,      -- 同一入出庫保管倉庫エラー
                                                   gv_c_tkn_mov_num,      -- トークン移動番号
                                                   move_data_rec_tbl(gn_rec_idx).mov_num,
                                                   gv_c_tkn_shipped_loct, -- トークン出庫元保管倉庫
                                                   move_data_rec_tbl(gn_rec_idx).shipped_locat_code,
                                                   gv_c_tkn_ship_to_loct, -- トークン入庫先保管倉庫
                                                   move_data_rec_tbl(gn_rec_idx).ship_to_locat_code
                                                   );
          -- 後続処理対象外
          move_data_rec_tbl(gn_rec_idx).ng_flag := 1;  -- NGフラグ
          -- エラー内容格納
          move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
        END IF;
      END IF;
--
      -- 前処理でエラーでない場合
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** 出庫元保管倉庫の手持数量存在チェック
        -- **************************************************
        -- 移動タイプが積送ありの場合
        IF ( move_data_rec_tbl(gn_rec_idx).mov_type = gv_c_move_type_y ) THEN
--
          SELECT COUNT(1)
          INTO   ln_exist
          FROM   ic_loct_inv ili
          WHERE  ili.location = move_data_rec_tbl(gn_rec_idx).shipped_locat_code
          AND    ili.item_id  = move_data_rec_tbl(gn_rec_idx).item_id
          AND    ili.lot_id   = move_data_rec_tbl(gn_rec_idx).lot_id
          ;
          -- 手持数量が存在しない場合
          IF ( ln_exist = 0 ) THEN
--
            -- 2008/12/11 本番障害#441 Del Start -------------------------------------------
            ---- 警告メッセージ
            --lv_wk_errmsg
            --  := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,     -- 'XXINV'
            --                              gv_c_msg_57a_009,     -- 手持数量なしエラー
            --                              gv_c_tkn_shipped_loct,-- トークン出庫元保管倉庫
            --                              move_data_rec_tbl(gn_rec_idx).shipped_locat_code,
            --                              gv_c_tkn_item,        -- トークン品目
            --                              move_data_rec_tbl(gn_rec_idx).item_code,
            --                              gv_c_tkn_lot_num,     -- トークンロットNo
            --                              move_data_rec_tbl(gn_rec_idx).lot_no,
            --                              gv_c_tkn_mov_num,     -- トークン移動番号
            --                              move_data_rec_tbl(gn_rec_idx).mov_num
            --                             );
            --
            ---- 後続処理対象外
            --move_data_rec_tbl(gn_rec_idx).ng_flag    := 1;         -- NGフラグ
            ---- エラー内容格納
            --move_data_rec_tbl(gn_rec_idx).err_msg    := lv_wk_errmsg;
            ---- 存在エラーチェックフラグ
            --move_data_rec_tbl(gn_rec_idx).exist_flag := 1;  -- 存在チェックフラグ
            -- 2008/12/11 本番障害#441 Del End ---------------------------------------------
--
            -- 2008/12/11 本番障害#441 Add Start -------------------------------------------
            BEGIN
              SELECT xilv.whse_code   -- 倉庫コード
              INTO   lv_whse_code_from
              FROM   xxcmn_item_locations_v  xilv
                    ,ic_whse_mst             iwm
                    ,sy_orgn_mst_b           somb
              WHERE  xilv.whse_code = iwm.whse_code
              AND    iwm.orgn_code  = somb.orgn_code
              AND    xilv.segment1  = move_data_rec_tbl(gn_rec_idx).shipped_locat_code;  -- 出庫元保管場所コード
            EXCEPTION
              WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,
                  'GMIPAPI.INVENTORY_POSTING 倉庫コード取得エラー：'||move_data_rec_tbl(gn_rec_idx).shipped_locat_code);
                RAISE global_api_expt;
            END;
--
            INSERT INTO ic_loct_inv
              (item_id
              ,whse_code
              ,lot_id
              ,location
              ,loct_onhand
              ,loct_onhand2
              ,lot_status
              ,qchold_res_code
              ,delete_mark
              ,text_code
              ,last_updated_by
              ,created_by
              ,last_update_date
              ,creation_date
              ,last_update_login
              ,program_application_id
              ,program_id
              ,program_update_date
              ,request_id
              )
            VALUES
             ( move_data_rec_tbl(gn_rec_idx).item_id             -- item_id
              ,lv_whse_code_from                                 -- whse_code
              ,move_data_rec_tbl(gn_rec_idx).lot_id              -- lot_id
              ,move_data_rec_tbl(gn_rec_idx).shipped_locat_code  -- location
              ,0                                                 -- loct_onhand
              ,NULL                                              -- loct_onhand2
              ,NULL                                              -- lot_status
              ,NULL                                              -- qchold_res_code
              ,0                                                 -- delete_mark
              ,NULL                                              -- text_code
              ,gn_user_id                                        -- last_updated_by
              ,gn_user_id                                        -- created_by
              ,gd_sysdate                                        -- last_update_date
              ,gd_sysdate                                        -- creation_date
              ,NULL                                              -- last_update_login
              ,NULL                                              -- program_application_id
              ,NULL                                              -- program_id
              ,NULL                                              -- program_update_date
              ,NULL                                              -- request_id
             );
            -- 2008/12/11 本番障害#441 Add End ----------------------------------------------
--
          END IF;
        END IF;
      END IF;
--2008/09/26 Y.Kawano Add End
--
      -- 前処理でエラーでない場合
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** 出庫実績日と入庫実績日の比較
        -- **************************************************
        -- 移動タイプが積送なしの場合
        IF ( move_data_rec_tbl(gn_rec_idx).mov_type = gv_c_move_type_n ) THEN
--
          -- 出庫実績日と入庫実績日が異なる場合
          IF ( TRUNC(move_data_rec_tbl(gn_rec_idx).actual_ship_date)
               <> TRUNC(move_data_rec_tbl(gn_rec_idx).actual_arrival_date) ) THEN
--
            -- 書式変換 出庫実績日
            lv_out_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_ship_date,
                                          'YYYY/MM/DD');
            -- 書式変換 入庫実績日
            lv_in_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_arrival_date,
                                         'YYYY/MM/DD');
--
            -- 警告メッセージ
            lv_wk_errmsg
              := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,     -- 'XXINV'
                                          gv_c_msg_57a_004,     -- 日付不一致メッセージ
                                          gv_c_tkn_mov_num,                    -- トークン移動番号
                                          move_data_rec_tbl(gn_rec_idx).mov_num,
                                          gv_c_tkn_mov_line_num,               -- トークン明細番号
                                          move_data_rec_tbl(gn_rec_idx).line_number,
                                          gv_c_tkn_item,                       -- トークン品目
                                          move_data_rec_tbl(gn_rec_idx).item_code,
                                          gv_c_tkn_lot_num,                    -- トークンロットNo
                                          move_data_rec_tbl(gn_rec_idx).lot_no,
                                          gv_c_tkn_shipped_day,                -- トークン出庫実績日
                                          lv_out_actual_date,
                                          gv_c_tkn_ship_to_day,                -- トークン入庫実績日
                                          lv_in_actual_date
                                         );
--
            -- 後続処理対象外
            move_data_rec_tbl(gn_rec_idx).ng_flag := 1;         -- NGフラグ
            -- エラー内容格納
            move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
          END IF;
        END IF;
      END IF;
--
--      -- 前処理でエラーでない場合
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** 実績日の在庫カレンダチェック 出庫実績日
        -- **************************************************
        -- 出庫実績日が在庫カレンダーのオープンされていない場合
        IF ( TRUNC(move_data_rec_tbl(gn_rec_idx).actual_ship_date)
               <= gd_close_period_date ) THEN
--
          -- 書式変換 出庫実績日
          lv_out_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_ship_date,
                                        'YYYY/MM/DD');
--
          -- メッセージ出力する文字列
          lv_msg_log :=
            gv_c_tkn_val_mov_num  ||':'|| move_data_rec_tbl(gn_rec_idx).mov_num     ||','||
            gv_c_out_date         ||':'|| lv_out_actual_date
            ;
--
          -- エラーメッセージ
          lv_wk_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                   gv_c_msg_57a_005,  -- カレンダクローズメッセージ
                                                   gv_c_tkn_errmsg,   -- トークンMSG
                                                   lv_msg_log         -- トークン値
                                                   );
          -- 後続処理対象外
          move_data_rec_tbl(gn_rec_idx).ng_flag := 1;  -- NGフラグ
          -- エラー内容格納
          move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
        END IF;
      END IF;
--
      -- 前処理でエラーでない場合
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** 実績日の在庫カレンダチェック 入庫実績日
        -- **************************************************
        -- 入庫実績日が在庫カレンダーオープンされていない場合
        IF ( TRUNC(move_data_rec_tbl(gn_rec_idx).actual_arrival_date)
              <= gd_close_period_date ) THEN
--
          -- 書式変換 入庫実績日
          lv_in_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_arrival_date,
                                       'YYYY/MM/DD');
--
          -- メッセージ出力する文字列
          lv_msg_log :=
            gv_c_tkn_val_mov_num  ||':'|| move_data_rec_tbl(gn_rec_idx).mov_num     ||','||
            gv_c_in_date          ||':'|| lv_in_actual_date
            ;
--
          -- エラーメッセージ
          lv_wk_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                   gv_c_msg_57a_005, -- カレンダクローズメッセージ
                                                   gv_c_tkn_errmsg,  -- トークンMSG
                                                   lv_msg_log        -- トークン値
                                                   );
--
          -- 後続処理対象外
          move_data_rec_tbl(gn_rec_idx).ng_flag := 1;  -- NGフラグ
          -- エラー内容格納
          move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
        END IF;
      END IF;
--
-- 2008/12/25 H.Itou Add Start
      -- 前処理でエラーでない場合
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** 実績日の未来日チェック 出庫実績日
        -- **************************************************
        -- 出庫実績日が未来日の場合
        IF ( TRUNC(move_data_rec_tbl(gn_rec_idx).actual_ship_date) > TRUNC(SYSDATE) ) THEN
--
          -- 書式変換 出庫実績日
          lv_out_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_ship_date,
                                        'YYYY/MM/DD');
--
          -- メッセージ出力する文字列
          lv_msg_log :=
            gv_c_tkn_val_mov_num  ||':'|| move_data_rec_tbl(gn_rec_idx).mov_num     ||','||
            gv_c_out_date         ||':'|| lv_out_actual_date
            ;
--
          -- エラーメッセージ
          lv_wk_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                   gv_c_msg_57a_012,   -- 未来日エラーメッセージ
                                                   gv_c_tkn_value,     -- トークン
                                                   gv_c_out_date,      -- トークン値
                                                   gv_c_tkn_errmsg,    -- トークン
                                                   lv_msg_log          -- トークン値
                                                   );
          -- 後続処理対象外
          move_data_rec_tbl(gn_rec_idx).ng_flag := 1;  -- NGフラグ
          -- エラー内容格納
          move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
        END IF;
      END IF;
--
      -- 前処理でエラーでない場合
      IF ( move_data_rec_tbl(gn_rec_idx).ng_flag = 0 ) THEN
        -- **************************************************
        -- *** 実績日の未来日チェック 入庫実績日
        -- **************************************************
        -- 出庫実績日が未来日の場合
        IF ( TRUNC(move_data_rec_tbl(gn_rec_idx).actual_arrival_date) > TRUNC(SYSDATE) ) THEN
--
          -- 書式変換 入庫実績日
          lv_in_actual_date := TO_CHAR(move_data_rec_tbl(gn_rec_idx).actual_arrival_date,
                                       'YYYY/MM/DD');
--
          -- メッセージ出力する文字列
          lv_msg_log :=
            gv_c_tkn_val_mov_num  ||':'|| move_data_rec_tbl(gn_rec_idx).mov_num     ||','||
            gv_c_in_date          ||':'|| lv_in_actual_date
            ;
--
          -- エラーメッセージ
          lv_wk_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                   gv_c_msg_57a_012,   -- 未来日エラーメッセージ
                                                   gv_c_tkn_value,     -- トークン
                                                   gv_c_in_date,       -- トークン値
                                                   gv_c_tkn_errmsg,    -- トークン
                                                   lv_msg_log          -- トークン値
                                                   );
          -- 後続処理対象外
          move_data_rec_tbl(gn_rec_idx).ng_flag := 1;  -- NGフラグ
          -- エラー内容格納
          move_data_rec_tbl(gn_rec_idx).err_msg := lv_wk_errmsg;
--
        END IF;
      END IF;
-- 2008/12/25 H.Itou Add End
--
    END LOOP check_loop;
--
    --==============================================================
    -- チェック後データ分別
    --==============================================================
--
    -- 初期化
    lv_pre_mov_num   := NULL;
    lv_mov_hdr_id_bk := NULL;
    lv_mov_num_bk    := NULL;
    lv_err_mov_num   := NULL;
    ln_tmp_idx       := 1;
    ln_idx           := 1;
--
    <<data_loop>>
    FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
--
      -----------------------
      -- for debug
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----- 分別LOOP START -----');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lv_mov_num_bk='||lv_mov_num_bk);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'lv_err_mov_num='||lv_err_mov_num);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')mov_num='|| move_data_rec_tbl(gn_rec_idx).mov_num);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')line_number='|| move_data_rec_tbl(gn_rec_idx).line_number);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')item_code='|| move_data_rec_tbl(gn_rec_idx).item_code);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_no='|| move_data_rec_tbl(gn_rec_idx).lot_no);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_out_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_in_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity);
      -----------------------
--
      -- 初期化
      out_err_tbl(gn_rec_idx).out_msg := '0';
--
      IF ((move_data_rec_tbl(gn_rec_idx).mov_num <> lv_err_mov_num)
      OR (lv_err_mov_num IS NULL))
      THEN
        -----------------------------------------------
        -- チェックでエラーにならなかったデータの場合
        -----------------------------------------------
        IF (move_data_rec_tbl(gn_rec_idx).ng_flag = 0) THEN
--
          -----------------------
          -- for debug
          FND_FILE.PUT_LINE(FND_FILE.LOG,'--- NORMAL DATA ---');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')mov_num='|| move_data_rec_tbl(gn_rec_idx).mov_num);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')line_number='|| move_data_rec_tbl(gn_rec_idx).line_number);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')item_code='|| move_data_rec_tbl(gn_rec_idx).item_code);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_no='|| move_data_rec_tbl(gn_rec_idx).lot_no);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_out_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_in_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity);
          -----------------------
--
          -- tmpに格納
          move_data_rec_tmp(gn_rec_idx) := move_data_rec_tbl(gn_rec_idx);
          -- ブレイク処理用 移動番号格納
          lv_mov_num_bk    := move_data_rec_tbl(gn_rec_idx).mov_num;
          lv_mov_hdr_id_bk := move_data_rec_tbl(gn_rec_idx).mov_hdr_id;
--
        -----------------------------------------------
        -- チェックでエラーになったデータの場合
        -----------------------------------------------
        ELSE
--
          -----------------------
          -- for debug
          FND_FILE.PUT_LINE(FND_FILE.LOG,'--- ERROR DATA ---');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')mov_num='|| move_data_rec_tbl(gn_rec_idx).mov_num);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')line_number='|| move_data_rec_tbl(gn_rec_idx).line_number);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')item_code='|| move_data_rec_tbl(gn_rec_idx).item_code);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_no='|| move_data_rec_tbl(gn_rec_idx).lot_no);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_out_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'move_data_rec_tbl('||to_char(gn_rec_idx)||')lot_in_actual_quantity='|| move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity);
          -----------------------
--
          -- スキップ件数(移動番号単位)
--mod start 1.2
--          gn_warn_cnt := gn_warn_cnt + 1;
--2008/09/26 Y.Kawano Mod Start
--          --出庫実績数量≠入庫実績数量の場合は加算しない
--          IF (move_data_rec_tbl(gn_rec_idx).skip_flag = 0) THEN
          --出庫実績数量≠入庫実績数量の場合は加算しない
          --出庫元の手持数量が存在しない場合は加算しない
          IF (  (move_data_rec_tbl(gn_rec_idx).skip_flag = 0)
            AND (move_data_rec_tbl(gn_rec_idx).exist_flag = 0) )
          THEN
            gn_warn_cnt := gn_warn_cnt + 1;
          END IF;
--2008/09/26 Y.Kawano Mod End
--mod end 1.2
--
          IF (move_data_rec_tbl(gn_rec_idx).err_msg IS NOT NULL) THEN
            -- ログ出力用PLSQL表に格納
            out_err_tbl(gn_rec_idx).out_msg := move_data_rec_tbl(gn_rec_idx).err_msg;
          END IF;
--
          -- tmpクリア
          --move_data_rec_tmp.DELETE;
          move_data_rec_tmp(gn_rec_idx).mov_hdr_id := -1;
--
          -- ブレイク用移動番号
          lv_mov_num_bk    := NULL;
          lv_mov_hdr_id_bk := NULL;
          -- エラー移動番号格納
          lv_err_mov_num  := move_data_rec_tbl(gn_rec_idx).mov_num;
--
          ---------
          -- for debug
          FND_FILE.PUT_LINE(FND_FILE.LOG,'エラー移動番号格納 lv_err_mov_num='||lv_err_mov_num);
          ---------
--
          err_mov_tmp_rec_tbl(ln_tmp_idx).mov_num := move_data_rec_tbl(gn_rec_idx).mov_num;
--2008/09/26 Y.Kawano Add Start
          -- 出庫元の手持数量が存在しない場合は対象外とする
          IF ( move_data_rec_tbl(gn_rec_idx).skip_flag = 1 ) THEN
            --スキップフラグ格納
            err_mov_tmp_rec_tbl(ln_tmp_idx).skip_flag := 1;
            --対象外フラグ格納
            err_mov_tmp_rec_tbl(ln_tmp_idx).out_flag := 1;
          END IF;
          --
          -- 出庫実績数量≠入庫実績数量の場合は対象外とする
          IF ( move_data_rec_tbl(gn_rec_idx).exist_flag = 1 )
          THEN
            --存在チェックフラグ格納
            err_mov_tmp_rec_tbl(ln_tmp_idx).exist_flag := 1;
            --対象外フラグ格納
            err_mov_tmp_rec_tbl(ln_tmp_idx).out_flag := 1;
          END IF;
--2008/09/26 Y.Kawano Add End
--
          ln_tmp_idx := ln_tmp_idx + 1;
--
        END IF;
      END IF;
--
    END LOOP data_loop;
--
--2008/08/21 Y.Kawano Mod Start
--    <<rec_loop>>
--    FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
--
--      -- エラー移動番号がある場合
--      IF err_mov_tmp_rec_tbl.exists(1) then
--
--        <<target_loop>>
--        FOR ln_tmp_idx IN 1 .. err_mov_tmp_rec_tbl.COUNT LOOP
--
--          -- エラー移動番号でない場合
--          IF  move_data_rec_tbl(gn_rec_idx).mov_num <> err_mov_tmp_rec_tbl(ln_tmp_idx).mov_num THEN
--
--            -- 処理対象PLSQL表に格納
--            move_target_tbl(ln_idx) := move_data_rec_tbl(gn_rec_idx);
--            ln_idx := ln_idx + 1;
--
--          END IF;
--
--        END LOOP target_loop;
--
--      -- エラー移動番号がない場合
--      ELSE
--
--        -- 処理対象PLSQL表に格納
--        move_target_tbl := move_data_rec_tbl;
--
--      END IF;
--
--    END LOOP rec_loop;
--
    -- エラー移動番号がある場合
    IF err_mov_tmp_rec_tbl.exists(1) then
--
      <<rec_loop>>
      FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
--
     -- エラーチェックフラグの初期化
        lv_err_flg := gv_c_ynkbn_n;
--
        <<target_loop>>
        FOR ln_tmp_idx IN 1 .. err_mov_tmp_rec_tbl.COUNT LOOP
--
          -- エラー移動番号の場合
          IF move_data_rec_tbl(gn_rec_idx).mov_num = err_mov_tmp_rec_tbl(ln_tmp_idx).mov_num THEN
--
            lv_err_flg := gv_c_ynkbn_y;
--
--2008/09/26 Y.Kawano Add Start
            --同一移動番号配下に1件でも対象外が含まれる場合、全データを対象外とする。
            IF (err_mov_tmp_rec_tbl(ln_tmp_idx).out_flag = 1) THEN
              move_data_rec_tbl(gn_rec_idx).ng_flag := 1;
            END IF;
--2008/09/26 Y.Kawano Add End
--
          END IF;
--
          EXIT target_loop WHEN (lv_err_flg = gv_c_ynkbn_y);
--
        END LOOP target_loop;
--
        IF ( lv_err_flg = gv_c_ynkbn_n ) THEN
            -- 処理対象PLSQL表に格納
            move_target_tbl(ln_idx) := move_data_rec_tbl(gn_rec_idx);
            ln_idx := ln_idx + 1;
        END IF;
--
      END LOOP rec_loop;
--
    -- エラー移動番号がない場合
    ELSE
--
      -- 処理対象PLSQL表に全データを格納
      move_target_tbl := move_data_rec_tbl;
--
    END IF;
--2008/08/21 Y.Kawano Mod End
--
--2008/09/26 Y.Kawano Add Start
    -- スキップ件数取得
      <<skip_loop>>
    FOR ln_tmp_idx IN 1 .. err_mov_tmp_rec_tbl.COUNT LOOP
      --初期化
      lt_bef_mov_num := NULL;
      --
      IF ( ( err_mov_tmp_rec_tbl(ln_tmp_idx).mov_num <> lt_bef_mov_num )
        OR ( lt_bef_mov_num is null ) )
      THEN
        -- 出庫元の手持数量が存在しない場合は1伝票1スキップ件数とする
        IF ( err_mov_tmp_rec_tbl(ln_tmp_idx).exist_flag = 1 )
        THEN
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
        -- 出庫実績数量≠入庫実績数量の場合は対象外件数とする
        IF ( err_mov_tmp_rec_tbl(ln_tmp_idx).skip_flag = 1 )
        THEN
          gn_out_cnt := gn_out_cnt + 1;
        END IF;
      --
      END IF;
      --
      --移動番号退避
      lt_bef_mov_num := err_mov_tmp_rec_tbl(ln_tmp_idx).mov_num;
--
    END LOOP skip_loop;
    --
    --対象外件数が存在する場合、対象件数から減数する
    IF ( gn_out_cnt <> 0 )
    THEN
      gn_target_cnt := gn_target_cnt - gn_out_cnt;
    END IF;
--2008/09/26 Y.Kawano Add End
--
    -- スキップ件数が0件でない場合
    IF gn_warn_cnt <> 0 THEN
      -- ステータス警告セット
      ov_retcode := gv_status_warn;             -- 警告
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END check_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_data_proc
   * Description      : 関連データ取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_data_proc(
    ov_errbuf         OUT VARCHAR2,              --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,              --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)              --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data_proc'; -- プログラム名
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
    lv_out_orgn_code           IC_TRAN_PND.ORGN_CODE%TYPE;  -- 組織コード出庫用
    lv_out_co_code             IC_TRAN_PND.CO_CODE%TYPE;    -- 会社コード出庫用
    lv_from_whse_code          IC_TRAN_PND.WHSE_CODE%TYPE;  -- 出庫倉庫コード
--
    lv_in_orgn_code            IC_TRAN_PND.ORGN_CODE%TYPE;  -- 組織コード入庫用
    lv_in_co_code              IC_TRAN_PND.CO_CODE%TYPE;    -- 会社コード入庫用
    lv_to_whse_code            IC_TRAN_PND.WHSE_CODE%TYPE;  -- 入庫倉庫コード
--
    ld_out_trans_date          DATE;         -- 取引日(出庫) 実績
    ld_in_trans_date           DATE;         -- 取引日(入庫) 実績
    ln_out_pnd_trans_qty       NUMBER;       -- 出庫数(保留トラン)
    ln_out_cmp_trans_qty       NUMBER;       -- 出庫数(完了トラン)
    ln_in_pnd_trans_qty        NUMBER;       -- 入庫数(保留トラン)
    ln_in_cmp_trans_qty        NUMBER;       -- 入庫数(完了トラン)
    ln_out_cmp_a_trans_qty     NUMBER;       -- 訂正出庫数(完了トラン)
    ln_in_cmp_a_trans_qty      NUMBER;       -- 訂正入庫数(完了トラン)
--
    ld_a_out_trans_date        DATE;         -- 取引日(出庫)  実績訂正
    ld_a_in_trans_date         DATE;         -- 取引日(入庫)  実績訂正

--
    lv_from_orgn_code          SY_ORGN_MST_B.ORGN_CODE%TYPE; -- 組織コード(出庫用)
    lv_from_co_code            SY_ORGN_MST_B.CO_CODE%TYPE;   -- 会社コード(出庫用)
    lv_to_orgn_code            SY_ORGN_MST_B.ORGN_CODE%TYPE; -- 組織コード(入庫用)
    lv_to_co_code              SY_ORGN_MST_B.CO_CODE%TYPE;   -- 会社コード(入庫用)
    ln_err_flg                 NUMBER := 0;                  -- データ取得フラグ
--
    lv_err_msg_value           VARCHAR2(2000);               -- エラーメッセージ内容
--
    lv_mov_num_bk              xxinv_mov_req_instr_headers.mov_num%TYPE;    -- 移動番号wk用
    ln_idx_adji                NUMBER := 1;
    ln_idx_trni                NUMBER := 1;
    ln_idx_move                NUMBER := 1;
--
    -- *** ローカル・カーソル ***
--
    -- ==================================
    -- 組織,会社,倉庫の取得カーソル
    -- ==================================
    CURSOR xxcmn_locations_cur(
                            ln_from_location_id IN xxcmn_item_locations_v.inventory_location_id%TYPE
                           ,ln_to_location_id   IN xxcmn_item_locations_v.inventory_location_id%TYPE)
    IS
      SELECT somb.orgn_code   from_orgn_code            -- プラントコード(出庫元)
            ,somb.co_code     from_co_code              -- 会社コード    (出庫元)
            ,xilv.whse_code   from_whse_code            -- 倉庫コード    (出庫元)
            ,somb2.orgn_code  to_orgn_code              -- プラントコード(入庫先)
            ,somb2.co_code    to_co_code                -- 会社コード    (入庫先)
            ,xilv2.whse_code  to_whse_code              -- 倉庫コード    (入庫先)
      FROM   xxcmn_item_locations_v xilv              -- OPM保管場所情報VIEW(出庫元用)
            ,sy_orgn_mst_b          somb              -- OPMプラントマスタ(出庫元用)
            ,xxcmn_item_locations_v xilv2             -- OPM保管場所情報VIEW(入庫先用)
            ,sy_orgn_mst_b          somb2             -- OPMプラントマスタ(入庫先用)
      WHERE  xilv.orgn_code              = somb.orgn_code         -- プラントコード
      AND    xilv.inventory_location_id  = ln_from_location_id    -- 保管倉庫ID
      AND    xilv2.orgn_code             = somb2.orgn_code       -- プラントコード
      AND    xilv2.inventory_location_id = ln_to_location_id     -- 保管倉庫ID
      ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    <<rec_loop>>
    FOR gn_rec_idx IN 1 .. move_target_tbl.COUNT LOOP
--
      -- 変数初期化
      lv_out_orgn_code       := NULL;    -- 組織コード出庫用
      lv_out_co_code         := NULL;    -- 会社コード出庫用
      lv_from_whse_code      := NULL;    -- 出庫倉庫コード
      lv_in_orgn_code        := NULL;    -- 組織コード入庫用
      lv_in_co_code          := NULL;    -- 会社コード入庫用
      lv_to_whse_code        := NULL;    -- 入庫倉庫コード
      ld_out_trans_date      := NULL;    -- 取引日(出庫)
      ld_in_trans_date       := NULL;    -- 取引日(入庫)
      ln_out_pnd_trans_qty   := 0;       -- 出庫数(保留トラン)
      ln_out_cmp_trans_qty   := 0;       -- 出庫数(完了トラン)
      ln_in_pnd_trans_qty    := 0;       -- 入庫数(保留トラン)
      ln_in_cmp_trans_qty    := 0;       -- 入庫数(完了トラン)
      ln_out_cmp_a_trans_qty := 0;       -- 訂正出庫数(完了トラン)
      ln_in_cmp_a_trans_qty  := 0;       -- 訂正入庫数(完了トラン)
      lv_err_msg_value       := NULL;    -- エラーメッセージ
      lv_mov_num_bk          := NULL;    -- ブレイク用移動番号
      out_err_tbl2(gn_rec_idx).out_msg := '0';
      err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := -1;
--
      /*****************************************************/
      -- 実績計上済フラグ=ON,かつ,実績訂正フラグ=ONの場合
      /*****************************************************/
      IF (move_target_tbl(gn_rec_idx).comp_actual_flg = gv_c_ynkbn_y)
      AND (move_target_tbl(gn_rec_idx).correct_actual_flg = gv_c_ynkbn_y) THEN
--
--2008/12/11 Y.Kawano Add Start
        /*****************************************/
        -- 訂正前後数量が0の場合
        /*****************************************/
        -- API登録処理をskipする
-- 2009/02/24 v1.21 UPDATE START
/*
        IF ((move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0)
          AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = 0)
          AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity = 0)
          AND (move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity = 0))
*/
        IF (
             (
               (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0)
                 AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = 0)
                   AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity = 0)
                     AND (move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity = 0)
             )
             OR
             (
               (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0)
                 AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity IS NULL)
             )
             OR
             (
               (move_target_tbl(gn_rec_idx).lot_out_actual_quantity IS NULL)
                 AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = 0)
             )
           )
-- 2009/02/24 v1.21 UPDATE END
        THEN
          NULL;
        ELSE
--2008/12/11 Y.Kawano Add End
--
          /*****************************************/
          -- 積送ありの場合
          /*****************************************/
          IF ( move_target_tbl(gn_rec_idx).mov_type = gv_c_move_type_y ) THEN  --(typeif)
--
          --for debug
          FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------  積送あり   -----------------');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'mov_line_id = '|| move_target_tbl(gn_rec_idx).mov_line_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'item_id='||to_char(move_target_tbl(gn_rec_idx).item_id));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'lot_id='||to_char(move_target_tbl(gn_rec_idx).lot_id));
--
            ----------------------------------
            -- 出庫元情報
            ----------------------------------
            BEGIN
              -- 保留トラン情報 実績計上されている最新を取得
              SELECT itp.orgn_code               -- 組織コード
                    ,itp.co_code                 -- 会社コード
                    ,itp.whse_code               -- 倉庫
                    ,itp.trans_date              -- 取引日
                    ,itp.trans_qty               -- 数量
              INTO   lv_out_orgn_code
                    ,lv_out_co_code
                    ,lv_from_whse_code
                    ,ld_out_trans_date
                    ,ln_out_pnd_trans_qty
              FROM   ic_tran_pnd   itp                      -- OPM保留在庫トランザクション
                    ,ic_xfer_mst   ixm                      -- OPM在庫転送マスタ
              WHERE  itp.location      = move_target_tbl(gn_rec_idx).shipped_locat_code
                                                                                 -- 出庫元保管倉庫
                AND  itp.item_id       = move_target_tbl(gn_rec_idx).item_id     -- 品目ID
                AND  itp.lot_id        = move_target_tbl(gn_rec_idx).lot_id      -- ロットID
                AND  itp.doc_type      = gv_c_doc_type_xfer                      -- 文書タイプ
                AND  itp.doc_id        = ixm.transfer_id                         -- 文書ID
                AND  itp.completed_ind = 1                                       -- 完了フラグ
          ------ 2008/04/11 modify start  ------
            --AND  ixm.attribute1    = move_target_tbl(gn_rec_idx).mov_line_id -- 移動明細ID
            --AND  ROWNUM            = 1                                       -- 最新のデータ
          --ORDER BY itp.creation_date DESC                                    -- 作成日 降順
-- 2009/06/09 H.Itou Mod Start 本番障害#1527 MAX(ID)は最新でない場合があるので、MAX(最終更新日)に変更。
--              AND  ixm.transfer_id IN
--                                  (SELECT MAX(transfer_id)
              AND  ixm.attribute1      = move_target_tbl(gn_rec_idx).mov_line_id
              AND  ixm.last_update_date IN
                                  (SELECT MAX(last_update_date)
-- 2009/06/09 H.Itou Mod End
                                   FROM   ic_xfer_mst
                                   WHERE  item_id        = move_target_tbl(gn_rec_idx).item_id
                                   AND    lot_id         = move_target_tbl(gn_rec_idx).lot_id
                                   AND    from_location  = move_target_tbl(gn_rec_idx).shipped_locat_code
                                   AND    attribute1     = move_target_tbl(gn_rec_idx).mov_line_id
                                   )
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データ取得できない場合、数量を0とする
                ln_out_pnd_trans_qty := 0;
                lv_out_orgn_code     := NULL;
                lv_out_co_code       := NULL;
                lv_from_whse_code    := NULL;
                ld_out_trans_date    := NULL;
            END;
--
            BEGIN
              -- 完了トラン情報 実績計上されている最新の訂正情報を取得
              SELECT itc.trans_qty               -- 数量
                    ,itc.trans_date              -- 取引日 -- 2008/04/14 add
              INTO   ln_out_cmp_trans_qty
                    ,ld_a_out_trans_date                    -- 2008/04/14 add
              FROM   ic_tran_cmp   itc                      -- OPM完了在庫トランザクション
                    ,ic_adjs_jnl   iaj                      -- OPM在庫調整ジャーナル
                    ,ic_jrnl_mst   ijm                      -- OPMジャーナルマスタ
              WHERE  itc.location      = move_target_tbl(gn_rec_idx).shipped_locat_code
                                                                                  -- 出庫元保管倉庫
                AND  itc.item_id       = move_target_tbl(gn_rec_idx).item_id      -- 品目ID
                AND  itc.lot_id        = move_target_tbl(gn_rec_idx).lot_id       -- ロットID
                AND  itc.doc_type      = iaj.trans_type                           -- 文書タイプ
                AND  itc.doc_type      = gv_c_doc_type_adji                       -- 文書タイプ
--2008/12/13 Y.Kawano Upd Start
--              --AND  itc.doc_line      = iaj.doc_line                             -- 取引明細番号
                AND  itc.doc_line      = iaj.doc_line                             -- 取引明細番号
                AND  itc.doc_id        = iaj.doc_id                               -- 取引ID
--2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id    = iaj.journal_id                           -- ジャーナルID
--2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id    = itc.doc_id                               -- ジャーナルID
--2008/12/13 Y.Kawano Del End
            ------ 2008/04/11 modify start  ------
              --AND  ijm.attribute1    = move_target_tbl(gn_rec_idx).mov_line_id  -- 移動明細ID
                AND  itc.location   = iaj.location
                AND  itc.item_id    = iaj.item_id
                AND  itc.lot_id     = iaj.lot_id
-- 2009/06/09 H.Itou Mod Start 本番障害#1527 MAX(ID)は最新でない場合があるので、MAX(最終更新日)に変更。
--                AND  iaj.journal_id IN
--                                    (SELECT MAX(adj.journal_id)           -- 最新のデータ
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                    (SELECT MAX(adj.last_update_date)           -- 最新のデータ
-- 2009/06/09 H.Itou Mod End
                                     FROM   ic_adjs_jnl   adj
                                           ,ic_jrnl_mst   jrn
                                     WHERE adj.journal_id  = jrn.journal_id
                                     AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                     AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                     AND   adj.location    = move_target_tbl(gn_rec_idx).shipped_locat_code
                                     AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                     AND   adj.trans_type  = gv_c_doc_type_adji
                                     AND   adj.reason_code = gv_reason_code_cor
                                    )
              --AND  ROWNUM            = 1                                        -- 最新のデータ
              --ORDER BY itc.creation_date DESC                                     -- 作成日 降順
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データ取得できない場合、数量を0とする
                ln_out_cmp_trans_qty := 0;
--2009/01/16 Y.Kawano Add Start
                ld_a_out_trans_date    := NULL;
--2009/01/16 Y.Kawano Add End
            END;
--
            ----------------------------------
            -- 入庫先情報
            ----------------------------------
            -- 保留トラン情報 実績計上されている最新を取得
            BEGIN
              SELECT itp.orgn_code               -- 組織コード
                    ,itp.co_code                 -- 会社コード
                    ,itp.whse_code               -- 倉庫
                    ,itp.trans_date              -- 取引日
                    ,itp.trans_qty               -- 数量
              INTO   lv_in_orgn_code
                    ,lv_in_co_code
                    ,lv_to_whse_code
                    ,ld_in_trans_date
                    ,ln_in_pnd_trans_qty
              FROM   ic_tran_pnd   itp                      -- OPM保留在庫トランザクション
                    ,ic_xfer_mst   ixm                      -- OPM在庫転送マスタ
              WHERE  itp.location      = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                                                                -- 入庫先保管倉庫
                AND  itp.item_id       = move_target_tbl(gn_rec_idx).item_id    -- 品目ID
                AND  itp.lot_id        = move_target_tbl(gn_rec_idx).lot_id     -- ロットID
                AND  itp.doc_type      = gv_c_doc_type_xfer                     -- 文書タイプ
                AND  itp.doc_id        = ixm.transfer_id                        -- 文書ID
                AND  itp.completed_ind = 1                                      -- 完了フラグ
              ------ 2008/04/11 modify start  ------
             -- AND  ixm.attribute1    = move_target_tbl(gn_rec_idx).mov_line_id -- 移動明細ID
-- 2009/06/09 H.Itou Mod Start 本番障害#1527 MAX(ID)は最新でない場合があるので、MAX(最終更新日)に変更。
--                AND  ixm.transfer_id IN
--                                    (SELECT MAX(transfer_id)                     -- 最新のデータ
                AND  ixm.attribute1    = move_target_tbl(gn_rec_idx).mov_line_id
                AND  ixm.last_update_date IN
                                    (SELECT MAX(last_update_date)                     -- 最新のデータ
-- 2009/06/09 H.Itou Mod End
                                     FROM   ic_xfer_mst
                                     WHERE  item_id     = move_target_tbl(gn_rec_idx).item_id
                                     AND    lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                     AND    to_location = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                     AND    attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                     )
               --   AND  ROWNUM            = 1                                      -- 最新のデータ
             -- ORDER BY itp.creation_date DESC                                   -- 作成日 降順
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データ取得できない場合、数量を0とする
                ln_in_pnd_trans_qty := 0;
                lv_in_orgn_code     := NULL;
                lv_in_co_code       := NULL;
                lv_to_whse_code     := NULL;
                ld_in_trans_date    := NULL;
            END;
--
            -- 完了トラン情報 実績計上されている最新の訂正情報を取得
            BEGIN
              SELECT itc.trans_qty               -- 数量
                    ,itc.trans_date              -- 取引日 -- 2008/04/14 add
              INTO   ln_in_cmp_trans_qty
                    ,ld_a_in_trans_date                     -- 2008/04/14 add
              FROM   ic_tran_cmp   itc                      -- OPM完了在庫トランザクション
                    ,ic_adjs_jnl   iaj                      -- OPM在庫調整ジャーナル
                    ,ic_jrnl_mst   ijm                      -- OPMジャーナルマスタ
              WHERE  itc.location      = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                                                                -- 入庫先保管倉庫
                AND  itc.item_id       = move_target_tbl(gn_rec_idx).item_id
                                                                                -- 品目ID
                AND  itc.lot_id        = move_target_tbl(gn_rec_idx).lot_id
                                                                                -- ロットID
                AND  itc.doc_type      = iaj.trans_type                         -- 文書タイプ
                AND  itc.doc_type      = gv_c_doc_type_adji                     -- 文書タイプ
--2008/12/13 Y.Kawano Upd Start
--              --AND  itc.doc_line      = iaj.doc_line                           -- 取引明細番号
                AND  itc.doc_line      = iaj.doc_line                           -- 取引明細番号
                AND  itc.doc_id        = iaj.doc_id                             -- 取引ID
--2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id    = iaj.journal_id                         -- ジャーナルID
--2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id    = itc.doc_id                             -- ジャーナルID
--2008/12/13 Y.Kawano Del End
            ------ 2008/04/11 modify start  ------
            --  AND  ijm.attribute1    = move_target_tbl(gn_rec_idx).mov_line_id  -- 移動明細ID
                AND  itc.location   = iaj.location
                AND  itc.item_id    = iaj.item_id
                AND  itc.lot_id     = iaj.lot_id
-- 2009/06/09 H.Itou Mod Start 本番障害#1527 MAX(ID)は最新でない場合があるので、MAX(最終更新日)に変更。
--                AND  iaj.journal_id IN
--                                    (SELECT MAX(adj.journal_id)           -- 最新のデータ
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                    (SELECT MAX(adj.last_update_date)           -- 最新のデータ
-- 2009/06/09 H.Itou Mod End
                                     FROM   ic_adjs_jnl   adj
                                           ,ic_jrnl_mst   jrn
                                     WHERE adj.journal_id  = jrn.journal_id
                                     AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                     AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                     AND   adj.location    = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                     AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                     AND   adj.trans_type  = gv_c_doc_type_adji
                                     AND   adj.reason_code = gv_reason_code_cor
                                    )
            --    AND  ROWNUM            = 1                                      -- 最新のデータ
            --  ORDER BY itc.creation_date DESC                                   -- 作成日 降順
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データ取得できない場合、数量を0とする
                ln_in_cmp_trans_qty := 0;
--2009/01/16 Y.Kawano Add Start
                ld_a_in_trans_date  := NULL;
--2009/01/16 Y.Kawano Add End
            END;
          ---------------------------------------------------------
          -- 2008/04/08 Modify Start
          -----------------------
          -- for debug
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_pnd_trans_qty = '|| to_char(ln_out_pnd_trans_qty));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_pnd_trans_qty = '|| to_char(ln_in_pnd_trans_qty));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_cmp_trans_qty = '|| to_char(ln_out_cmp_trans_qty));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty = '|| to_char(ln_in_cmp_trans_qty));
--
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_out_trans_date = '|| to_char(ld_out_trans_date,'yyyy/mm/dd'));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_in_trans_date = '|| to_char(ld_in_trans_date,'yyyy/mm/dd'));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_ship_date = '|| to_char(move_target_tbl(gn_rec_idx).actual_ship_date,'yyyy/mm/dd'));
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_arrival_date = '|| to_char(move_target_tbl(gn_rec_idx).actual_arrival_date,'yyyy/mm/dd'));
          -- for debug
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_pnd_trans_qty = '|| to_char(ln_out_pnd_trans_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_pnd_trans_qty  = '|| to_char(ln_in_pnd_trans_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_cmp_trans_qty = '|| to_char(ln_out_cmp_trans_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty  = '|| to_char(ln_in_cmp_trans_qty));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'out_actual_quantity  = '|| to_char(move_target_tbl(gn_rec_idx).lot_out_actual_quantity));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'in_actual_quantity   = '|| to_char(move_target_tbl(gn_rec_idx).lot_in_actual_quantity));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'out_bef_actual_qty   = '|| to_char(move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'in_bef_actual_qty    = '|| to_char(move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity));
--
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_out_trans_date    = '|| to_char(ld_out_trans_date,'yyyy/mm/dd'));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_in_trans_date     = '|| to_char(ld_in_trans_date,'yyyy/mm/dd'));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_a_out_trans_date  = '|| to_char(ld_a_out_trans_date,'yyyy/mm/dd'));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_a_in_trans_date   = '|| to_char(ld_a_in_trans_date,'yyyy/mm/dd'));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_ship_date     = '|| to_char(move_target_tbl(gn_rec_idx).actual_ship_date,'yyyy/mm/dd'));
          FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_arrival_date  = '|| to_char(move_target_tbl(gn_rec_idx).actual_arrival_date,'yyyy/mm/dd'));
          -----------------------
--
            ---------------------------------------------------------
            -- 保留トラン出庫と入庫、または完了トランの出庫と入庫が異なる
            ---------------------------------------------------------
            IF (ABS(ln_out_pnd_trans_qty) <> ABS(ln_in_pnd_trans_qty))  -- 保留トランの入出庫数が違う
            OR (ABS(ln_out_cmp_trans_qty) <> ABS(ln_in_cmp_trans_qty))  -- 完了トランの入出庫数が違う
            THEN  --(s)
--
              -- 保留トランまたは完了トランのデータ不整合
              RAISE global_api_expt;
--
            ---------------------------------------------------------
            -- 保留トラン出庫と入庫、完了トランの出庫と入庫が同じ
            ---------------------------------------------------------
            ELSIF (ABS(ln_out_pnd_trans_qty) = ABS(ln_in_pnd_trans_qty)) -- 保留トランの入出庫数が同じ
              AND (ABS(ln_out_cmp_trans_qty) = ABS(ln_in_cmp_trans_qty)) -- 完了トランの入出庫数が同じ
            THEN  --(s)
--
              -- for debug -------------------------------------------
              FND_FILE.PUT_LINE(FND_FILE.LOG,'【1】保留トラン出庫と入庫、完了トランの出庫と入庫が同じ');
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_pnd_trans_qty = '|| to_char(ABS(ln_out_pnd_trans_qty)));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_pnd_trans_qty = '|| to_char(ABS(ln_in_pnd_trans_qty)));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_cmp_trans_qty = '|| to_char(ABS(ln_out_cmp_trans_qty)));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty = '|| to_char(ABS(ln_in_cmp_trans_qty)));
--
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty = '|| to_char(ABS(ln_in_cmp_trans_qty)));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty = '|| to_char(ABS(ln_in_cmp_trans_qty)));
              -- for debug -------------------------------------------
--
              --===========================================================
              -- 実績(保留トラン)の日付と移動ヘッダアドオンの実績日が異なる場合
              -- →全赤作る
              --===========================================================
              IF (TRUNC(ld_out_trans_date) <> TRUNC(move_target_tbl(gn_rec_idx).actual_ship_date))   -- 出庫実績日
              OR (TRUNC(ld_in_trans_date) <> TRUNC(move_target_tbl(gn_rec_idx).actual_arrival_date)) -- 入庫実績日
              THEN  --(r)
--
              -- for debug
              FND_FILE.PUT_LINE(FND_FILE.LOG,'【2】実績(保留トラン)の日付と移動ヘッダアドオンの実績日が異なる');
--
              -- 2008/04/14 modify start
              --  -----------------------------------------------------------------
              --  -- 実績(保留トラン)の数量と実績訂正(完了トラン)の数量が異なる場合
              --  -- 赤作る
              --  IF  (ABS(ln_out_pnd_trans_qty) <> ABS(ln_out_cmp_trans_qty))    -- 出庫数pndとcmp
              --  AND (ABS(ln_in_pnd_trans_qty)  <> ABS(ln_in_cmp_trans_qty))     -- 入庫数pndとcmp
              --  THEN
--
              -- for debug
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'【2-1】ld_out_trans_date='|| to_char(ld_out_trans_date,'yyyy/mm/dd'));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'【2-1】ld_a_out_trans_date='|| to_char(ld_a_out_trans_date,'yyyy/mm/dd'));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'【2-1】ld_in_trans_date='|| to_char(ld_in_trans_date,'yyyy/mm/dd'));
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'【2-1】ld_a_in_trans_date='|| to_char(ld_a_in_trans_date,'yyyy/mm/dd'));
--
                --=============================================================
                -- 実績(保留トラン)と実績訂正(完了トラン)の取引日が異なる場合
                --=============================================================
                IF  (TRUNC(ld_out_trans_date) <> TRUNC(ld_a_out_trans_date)) -- 出庫日 実績と実績訂正
                OR (TRUNC(ld_in_trans_date)  <> TRUNC(ld_a_in_trans_date))   -- 入庫日 実績と実績訂正
                OR ld_a_out_trans_date IS NULL
                OR ld_a_in_trans_date IS NULL
                THEN  --(q)
                -- 2008/04/14 modify end
--
              -- for debug
              FND_FILE.PUT_LINE(FND_FILE.LOG,'【3】実績(保留トラン)の数量と実績訂正(完了トラン)の実績日が異なる');
--              FND_FILE.PUT_LINE(FND_FILE.LOG,'【4】実績訂正情報格納  start');
--
                  -- 実績黒数量が0でない場合
                  IF (ln_out_pnd_trans_qty <> 0) THEN
                    -----------------------------------------------------------------
                    -- 赤情報
                    -- 実績訂正情報格納  在庫数量API実行対象レコードにデータを格納
                    adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                    adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                    adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                    adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                    adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                    adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                    adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
                    adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
                    adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                    adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                    adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                    adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                    adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                    adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                    adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                    -- インクリメント
                    ln_idx_adji := ln_idx_adji + 1;
                  END IF;
--
                -- for debug
--                FND_FILE.PUT_LINE(FND_FILE.LOG,'【5】実績訂正情報格納  end');
                  -----------------------------------------------------------------
                  -- 黒情報
                  -- 移動ロット詳細の数量が0の場合(実績登録しない)
                  IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  --(o)
                    -- 何もしない
                    NULL;
--
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【6】移動ロット詳細の数量が0');
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'何もしない');
--
                  -----------------------------------------------------------------
                  -- 移動ロット詳細の数量が0以外の場合(実績登録する)
                  ELSE  --(o)
--
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【7】移動ロット詳細の数量が0じゃない');
--
                    -- 実績(保留トラン)の数量が0の場合は前回0実績計上されているから保留トランにデータなし
                    -- 倉庫組織会社情報がないため取得する
                    IF (ln_out_pnd_trans_qty = 0) THEN  --(p)
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【8】実績(保留トラン)の数量が0だから組織情報取得');
--
                      BEGIN
                        -- 変数初期化
                        lv_from_orgn_code := NULL;
                        lv_from_co_code   := NULL;
                        lv_from_whse_code := NULL;
                        lv_to_orgn_code   := NULL;
                        lv_to_co_code     := NULL;
                        lv_to_whse_code   := NULL;
                        ln_err_flg        := 0;
--
                        -- 組織,会社,倉庫の取得カーソルオープン
                        OPEN xxcmn_locations_cur(
                                  move_target_tbl(gn_rec_idx).shipped_locat_id    -- 出庫元
                                 ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- 入庫先
--
                        <<xxcmn_locations_cur_loop>>
                        LOOP
                          FETCH xxcmn_locations_cur
                          INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                               ,lv_from_co_code         -- 会社コード(出庫用)
                               ,lv_from_whse_code       -- 倉庫コード(出庫用)
                               ,lv_to_orgn_code         -- 組織コード(入庫用)
                               ,lv_to_co_code           -- 会社コード(入庫用)
                               ,lv_to_whse_code         -- 倉庫コード(入庫用)
                               ;
                          EXIT WHEN xxcmn_locations_cur%NOTFOUND;

                        END LOOP xxcmn_locations_cur_loop;
--
                        -- カーソルクローズ
                        CLOSE xxcmn_locations_cur;
--
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN                             -- データ取得エラー
                          -- エラーフラグ
                          ln_err_flg  := 1;
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- カーソルクローズ
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- エラーメッセージ内容
                          lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- データ取得エラー
                                                                gv_c_tkn_msg,     -- トークンMSG
                                                                lv_err_msg_value  -- トークン値
                                                                );
                          -- エラー内容格納
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- エラー移動番号PLSQL表に格納
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        WHEN TOO_MANY_ROWS THEN                             -- データ取得エラー
                          -- エラーフラグ
                          ln_err_flg  := 1;
--
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- カーソルクローズ
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- エラーメッセージ内容
                          lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- データ取得エラー
                                                                gv_c_tkn_msg,     -- トークンMSG
                                                                lv_err_msg_value  -- トークン値
                                                                );
                          -- エラー内容格納
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- エラー移動番号PLSQL表に格納
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                      END;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【9】組織情報取得  END');
--
                      -----------------------------------------------------------------
                      -- 組織、会社、倉庫情報が取得できた場合
                      IF (ln_err_flg = 0) THEN
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【10】実績登録用に格納 start');
--
                        -- 実績登録用レコードにデータを格納
                        move_api_rec_tbl(ln_idx_move).orgn_code              := lv_from_orgn_code;
                        move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                        move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                        move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                        move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                        move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                        move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
-- 2008/12/25 Y.Kawano Upd Start #844
--                        move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                        move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                        move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                        move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                        move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- 出庫実績日
                        move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- 入庫実績日
                        move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                        move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- インクリメント
                        ln_idx_move := ln_idx_move + 1;
--
                      END IF;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【11】実績登録用に格納 end');
--
                    -----------------------------------------------------
                    -- 実績(保留トラン)の数量が0でない場合
                    -- 前回実績計上されているから倉庫組織会社情報がある
                    -----------------------------------------------------
                    ELSE  --(p)
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【12】組織情報あるから  データだけ格納 START');
--
                      -- 実績登録用レコードにデータを格納
                      move_api_rec_tbl(ln_idx_move).orgn_code              := lv_out_orgn_code;
                      move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                      move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                      move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                      move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                      move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                      move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
-- 2008/12/25 Y.Kawano Upd Start #844
--                      move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                      move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                      move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                      move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                      move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- 出庫実績日
                      move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- 入庫実績日
                      move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                      move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- インクリメント
                      ln_idx_move := ln_idx_move + 1;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【13】組織情報あるから  データだけ格納 End');
--
                    END IF;  --(p)
--
                  END IF;  --(o)
--
              -- 2008/04/14 modify start
              --  ---------------------------------------------------------------
              --  -- 実績(保留トラン)と実績訂正(完了トラン)のが同じ場合
              --  ---------------------------------------------------------------
              --  ELSIF (ABS(ln_out_pnd_trans_qty) = ABS(ln_out_cmp_trans_qty))   -- 出庫数
              --  AND   (ABS(ln_in_pnd_trans_qty)  = ABS(ln_in_cmp_trans_qty))    -- 入庫数
              --  THEN
--
                --=============================================================
                -- 実績(保留トラン)と実績訂正(完了トラン)の取引日が同じ場合
                --=============================================================
                ELSIF (TRUNC(ld_out_trans_date) = TRUNC(ld_a_out_trans_date))  -- 出庫日 実績と実績訂正
                AND (TRUNC(ld_in_trans_date)  = TRUNC(ld_a_in_trans_date))  -- 入庫日 実績と実績訂正
                THEN  --(q)
--
                -- for debug
                FND_FILE.PUT_LINE(FND_FILE.LOG,'【14a 実績(保留トラン)と実績訂正(完了トラン)の取引日が同じ】');
--
                ---------------------------------------------------------------
                -- 実績(保留トラン)と実績訂正(完了トラン)の数量が同じ場合
                ---------------------------------------------------------------
                  IF (ABS(ln_out_pnd_trans_qty) = ABS(ln_out_cmp_trans_qty))   -- 出庫数
                  AND (ABS(ln_in_pnd_trans_qty) = ABS(ln_in_cmp_trans_qty))    -- 入庫数
                  THEN  --(m)
--
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【14b 実績(保留トラン)と実績訂正(完了トラン)の数量が同じ】');
--
                    -- 2008/04/15 modify start
                    -- 何もしない
                    -- NULL;
--
                    -- ロット詳細の実績数量が0の場合
                    IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN
                      -- 何もしない
                      NULL;
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【14c ロット詳細の実績数量が0  何もしない】');
--
                    -- ロット詳細の実績数量が0以外の場合
                    ELSE
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【14c ロット詳細の実績数量が0じゃない  黒作成】');
--
                      -- 黒作成
                      move_api_rec_tbl(ln_idx_move).orgn_code              := lv_out_orgn_code;
                      move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                      move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                      move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                      move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                      move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                      move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
-- 2008/12/25 Y.Kawano Upd Start #844
--                      move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                      move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                      move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                      move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                      move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- 出庫実績日
                      move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- 入庫実績日
                      move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                      move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- インクリメント
                      ln_idx_move := ln_idx_move + 1;
--
                    END IF;
                    -- 2008/04/15 modify end
--
                  ---------------------------------------------------------------
                  -- 実績(保留トラン)と実績訂正(完了トラン)の数量が異なる場合
                  ---------------------------------------------------------------
                  ELSE  --(m)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【14】実績(保留トラン)と実績訂正(完了トラン)の数量が異なる');
--
                    -- 2008/04/14 modify start
                    -- 赤作成
                    -- 黒数量が0以外(実績あり)の場合、赤作る
                    IF (ln_out_pnd_trans_qty <> 0) THEN
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【14-1】赤作成  格納 start');
--
                      -- 実績訂正情報格納  在庫数量API実行対象レコードにデータを格納
                      adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                      adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                      adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                      adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                      adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- インクリメント
                      ln_idx_adji := ln_idx_adji + 1;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【14-1】赤作成  格納 end');
--
                    END IF;
                    -- 2008/04/14 modify end
--
                    -- 黒作成
                    -----------------------------------------------------------------
                    -- 移動ロット詳細の数量が0の場合(実績登録しない)
                    IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  --(l)
--
                      -- 何もしない
                      NULL;
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【15】移動ロット詳細の数量が0');
--
                   -----------------------------------------------------------------
                    -- 移動ロット詳細の数量が0以外の場合(実績登録する)
                    ELSE  --(l)
                      --for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【16】移動ロット詳細の数量が0以外');
--
                      -- 実績(保留トラン)の数量が0の場合は前回0実績計上されているから保留トランにデータなし
                      -- 倉庫組織会社情報がないため取得する
                      IF (ln_out_pnd_trans_qty = 0) THEN  --(k)
--
                        --for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【17】実績(保留トラン)の数量が0だから組織情報取得');
--
                        BEGIN
                          -- 変数初期化
                          lv_from_orgn_code := NULL;
                          lv_from_co_code   := NULL;
                          lv_from_whse_code := NULL;
                          lv_to_orgn_code   := NULL;
                          lv_to_co_code     := NULL;
                          lv_to_whse_code   := NULL;
                          ln_err_flg        := 0;
--
                          -- 組織,会社,倉庫の取得カーソルオープン
                          OPEN xxcmn_locations_cur(
                                    move_target_tbl(gn_rec_idx).shipped_locat_id    -- 出庫元
                                   ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- 入庫先
--
                          <<xxcmn_locations_cur_loop>>
                          LOOP
                            FETCH xxcmn_locations_cur
                            INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                                 ,lv_from_co_code         -- 会社コード(出庫用)
                                 ,lv_from_whse_code       -- 倉庫コード(出庫用)
                                 ,lv_to_orgn_code         -- 組織コード(入庫用)
                                 ,lv_to_co_code           -- 会社コード(入庫用)
                                 ,lv_to_whse_code         -- 倉庫コード(入庫用)
                                 ;
                            EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                          END LOOP xxcmn_locations_cur_loop;
--
                          -- カーソルクローズ
                          CLOSE xxcmn_locations_cur;
--
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN                             -- データ取得エラー
                            -- エラーフラグ
                            ln_err_flg  := 1;
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- カーソルクローズ
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- エラーメッセージ内容
                            lv_err_msg_value
                                  := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- データ取得エラー
                                                                  gv_c_tkn_msg,     -- トークンMSG
                                                                  lv_err_msg_value  -- トークン値
                                                                  );
                            -- エラー内容格納
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- エラー移動番号PLSQL表に格納
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                          WHEN TOO_MANY_ROWS THEN                             -- データ取得エラー
                            -- エラーフラグ
                            ln_err_flg  := 1;
--
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- カーソルクローズ
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- エラーメッセージ内容
                            lv_err_msg_value
                                  := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- データ取得エラー
                                                                  gv_c_tkn_msg,     -- トークンMSG
                                                                  lv_err_msg_value  -- トークン値
                                                                  );
                            -- エラー内容格納
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- エラー移動番号PLSQL表に格納
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        END;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【18】組織情報取得 END');
--
                        -----------------------------------------------------------------
                        -- 組織、会社、倉庫情報が取得できた場合
                        IF (ln_err_flg = 0) THEN
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【19】実績登録用格納 start');
--
                          -- 実績登録用レコードにデータを格納
                          move_api_rec_tbl(ln_idx_move).orgn_code              := lv_from_orgn_code;
                          move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                          move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                          move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                          move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                          move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                          move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
-- 2008/12/25 Y.Kawano Upd Start #844
--                          move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                          move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                          move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                          move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                          move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- 出庫実績日
                          move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- 入庫実績日
                          move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                          move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);

--
                          -- インクリメント
                          ln_idx_move := ln_idx_move + 1;
--
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【20】実績登録用格納 end');
--
                        END IF;
--
                      -----------------------------------------------------
                      -- 実績(保留トラン)の数量が0でない場合
                      -- 前回実績計上されているから倉庫組織会社情報がある
                      -----------------------------------------------------
                      ELSE  --(k)
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【21】実績登録用格納 start');
--
                        -- 実績登録用レコードにデータを格納
                        move_api_rec_tbl(ln_idx_move).orgn_code              := lv_out_orgn_code;
                        move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                        move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                        move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                        move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                        move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                        move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
-- 2008/12/25 Y.Kawano Upd Start #844
--                        move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                        move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                        move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                        move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                        move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- 出庫実績日
                        move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- 入庫実績日
                        move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                        move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- インクリメント
                        ln_idx_move := ln_idx_move + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【22】実績登録用格納 end');
--
                      END IF;  --(k)
--
                    END IF;  --(l)
--
                  END IF;  --(m)
--
                END IF;--(q)
--
              --===========================================================
              -- 実績(保留トラン)の日付と移動ヘッダアドオンの実績日が同じ場合
              -- →数量が変更されているデータのみ処理対象にする
              --===========================================================
              ELSE  --(r)
-- add start 1.9
                IF((move_target_tbl(gn_rec_idx).lot_out_actual_quantity = move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity)
                  AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity))
                THEN  --(j)
                  NULL;
                ELSE  --(j)
-- add end 1.9
                  --for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【23】保留トランの日付とアドオンの実績日が同じ');
--
-- 2008/12/16 Y.Kawano Del Start
-- 上記IF文(j)で、変更なし分は対象外となっている為、不要なIF文を削除
--                  ------------------------------------------------------------------
--                  -- ロット詳細アドオンの数量と実績(保留トラン)の数量が同じ場合
--                  -- →ロット詳細アドオンの数量が変更されていない
--                  ------------------------------------------------------------------
--                  IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = ABS(ln_out_pnd_trans_qty)) THEN  --(i)
--
--                    -- 何もしない
--                    NULL;
--                    --for debug
--                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【24】ロット詳細アドオン数量と実績(保留トラン)の数量が同じ');
--                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【24-1】何もしない');
--
--                  ------------------------------------------------------------------
--                  -- ロット詳細アドオンの数量と実績(保留トラン)の数量が異なる場合
--                  -- →ロット詳細アドオンの数量が変更されている
--                  ------------------------------------------------------------------
--                  ELSE  --(i)
-- 2008/12/16 Y.Kawano Del End
--
                    --for debug
--                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【25】ロット詳細アドオンの数量と実績(保留トラン)の数量が異なる');
--
                    --================================================================
                    -- 実績(保留トラン)の数量と実績訂正(完了トラン)の数量が異なる場合
                    --================================================================
                    -- 2008/4/14 modify start
                    --  IF (ABS(ln_out_pnd_trans_qty) <> ABS(ln_out_cmp_trans_qty))    -- 出庫数
                    --  AND (ABS(ln_in_pnd_trans_qty)  <> ABS(ln_in_cmp_trans_qty))    -- 入庫数
                    --  THEN
--
                    IF (TRUNC(ld_out_trans_date) <> TRUNC(ld_a_out_trans_date))  -- 出庫日 実績と実績訂正
                    OR (TRUNC(ld_in_trans_date)  <> TRUNC(ld_a_in_trans_date))  -- 入庫日 実績と実績訂正
                    OR ld_a_out_trans_date IS NULL
                    OR ld_a_in_trans_date IS NULL
                    THEN  --(h)
--
                      --for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【26】実績(保留トラン)と実績訂正(完了トラン)の実績日が異なる');
--
                      ------------------------------------------------------------------
                      -- 実績(保留トラン)の数量が0でない場合
                      -- 赤作る
                      ------------------------------------------------------------------
                      IF ( ABS(ln_out_pnd_trans_qty) <> 0 ) THEN
--
                        --for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【27】実績(保留トラン)の数量が0でない 赤作る');
--
                        -- 実績訂正作成情報格納
                        -- 実績訂正情報格納  在庫数量API実行対象レコードにデータを格納
                        adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                        adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                        adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- インクリメント
                        ln_idx_adji := ln_idx_adji + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【28】赤作る END');
--
                      END IF;
--
                    ------------------------------------------------------------------
                      -- 黒情報
                      -- 移動ロット詳細の数量が0の場合(実績登録しない)
                      IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  --(g)
                        -- 何もしない
                        NULL;
--
                      --for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【29】移動ロット詳細の数量が0だよ');
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【29-1】何もしない');
--
                      -- 移動ロット詳細の数量が0以外の場合(実績登録する)
                      ELSE  --(g)
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【30】移動ロット詳細の数量が0以外だよ');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【31】実績登録用格納  START');
--
                        BEGIN
                          -- 変数初期化
                          lv_from_orgn_code := NULL;
                          lv_from_co_code   := NULL;
                          lv_from_whse_code := NULL;
                          lv_to_orgn_code   := NULL;
                          lv_to_co_code     := NULL;
                          lv_to_whse_code   := NULL;
                          ln_err_flg        := 0;
--
                          -- 組織,会社,倉庫の取得カーソルオープン
                          OPEN xxcmn_locations_cur(
                                    move_target_tbl(gn_rec_idx).shipped_locat_id    -- 出庫元
                                   ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- 入庫先
--
                          <<xxcmn_locations_cur_loop>>
                          LOOP
                            FETCH xxcmn_locations_cur
                            INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                                 ,lv_from_co_code         -- 会社コード(出庫用)
                                 ,lv_from_whse_code       -- 倉庫コード(出庫用)
                                 ,lv_to_orgn_code         -- 組織コード(入庫用)
                                 ,lv_to_co_code           -- 会社コード(入庫用)
                                 ,lv_to_whse_code         -- 倉庫コード(入庫用)
                                 ;
                            EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                          END LOOP xxcmn_locations_cur_loop;
--
                          -- カーソルクローズ
                          CLOSE xxcmn_locations_cur;
--
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN                             -- データ取得エラー
                            -- エラーフラグ
                            ln_err_flg  := 1;
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- カーソルクローズ
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- エラーメッセージ内容
                            lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- データ取得エラー
                                                                  gv_c_tkn_msg,     -- トークンMSG
                                                                  lv_err_msg_value  -- トークン値
                                                                  );
                            -- エラー内容格納
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- エラー移動番号PLSQL表に格納
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                          WHEN TOO_MANY_ROWS THEN                             -- データ取得エラー
                            -- エラーフラグ
                            ln_err_flg  := 1;
--
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- カーソルクローズ
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- エラーメッセージ内容
                            lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- データ取得エラー
                                                                  gv_c_tkn_msg,     -- トークンMSG
                                                                  lv_err_msg_value  -- トークン値
                                                                  );
                            -- エラー内容格納
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- エラー移動番号PLSQL表に格納
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        END;
--
                        -- 組織、会社、倉庫情報が取得できた場合
                        IF (ln_err_flg = 0) THEN
                          -- 実績登録用レコードにデータを格納
                          move_api_rec_tbl(ln_idx_move).orgn_code              := lv_from_orgn_code;
                          move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                          move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                          move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                          move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                          move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                          move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
-- 2008/12/25 Y.Kawano Upd Start #844
--                          move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                          move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                          move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                          move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                          move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- 出庫実績日
                          move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- 入庫実績日
                          move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                          move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- インクリメント
                          ln_idx_move := ln_idx_move + 1;
--
                        END IF;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【32】実績登録用格納  END');
--
                      END IF;  --(g)
--
                  --================================================================
                  -- 実績(保留トラン)の数量と実績訂正(完了トラン)の数量が同じ場合
                  -- 赤作らない 黒だけ作る
                  --================================================================
                  -- 2008/4/14 modify start
                  --  ELSIF (ABS(ln_out_pnd_trans_qty) = ABS(ln_out_cmp_trans_qty))   -- 出庫数
                  --    AND (ABS(ln_in_pnd_trans_qty)  = ABS(ln_in_cmp_trans_qty))    -- 入庫数
                  --  THEN
--
                    ELSIF (TRUNC(ld_out_trans_date) = TRUNC(ld_a_out_trans_date))  -- 出庫日 実績と実績訂正
                    AND (TRUNC(ld_in_trans_date)  = TRUNC(ld_a_in_trans_date))  -- 入庫日 実績と実績訂正
                    THEN  --(h)
--
                    --for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【33】実績(保留トラン)と実績訂正(完了トラン)の実績日が同じ');
--
-- 2008/12/13 Y.Kawano Del Start
---- 2008/12/11 Y.Kawano Add Start
--                    ------------------------------------------------------------------
--                    -- 実績(保留トラン)の数量が0でない場合
--                    -- 赤作る
--                    ------------------------------------------------------------------
--                    IF ( ABS(ln_out_pnd_trans_qty) <> 0 ) THEN
--
--                      --for debug
--                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【33-1】実績(保留トラン)の数量が0でない 赤作る');
--
--                      -- 実績訂正作成情報格納
--                      -- 実績訂正情報格納  在庫数量API実行対象レコードにデータを格納
--                      adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
--                      adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
--                      adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
--                      adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
--                      adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
--                      adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
--                      adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
--                      adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
--                      adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
--                      adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
--                      adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
--                      -- インクリメント
--                      ln_idx_adji := ln_idx_adji + 1;
--
--                      -- for debug
--                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【28】赤作る END');
--
--                    END IF;
-- 2008/12/11 Y.Kawano Add End
-- 2008/12/13 Y.Kawano Del End
--
                      IF (ABS(ln_out_pnd_trans_qty) = ABS(ln_out_cmp_trans_qty))   -- 出庫数
                      AND (ABS(ln_in_pnd_trans_qty) = ABS(ln_in_cmp_trans_qty))    -- 入庫数
                      THEN  --(f)
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【34】実績(保留トラン)と実績訂正(完了トラン)の数量も同じ');
--
-- 2008/12/13 Y.Kawano Upd Strat
--                      --何もしない
--                      NULL;
--
-- 2009/02/04 Y.Kawano Add Start #1142
                        ------------------------------------------------------------------
                        -- アドオンの実績数量と訂正前数量が異なる場合
                        -- 赤作る
                        ------------------------------------------------------------------
                        IF  ( (move_target_tbl(gn_rec_idx).lot_out_actual_quantity
                                                        <> move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity)
                          AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity
                                                        <> move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity)
                          AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity <> 0)
                          AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity <> 0)
                            )
                        THEN
--
                         --for debug
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'【34】アドオンの実績数量と訂正前数量が異なる 赤作る');
--
                          -- 実績訂正作成情報格納
                          -- 実績訂正情報格納  在庫数量API実行対象レコードにデータを格納
                          adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                          adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                          adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                          adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                          adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                          adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                          adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
                          adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
                          adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                          adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                          adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                          adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                          adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                          adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                          adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- インクリメント
                          ln_idx_adji := ln_idx_adji + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【34】赤作る END');
--
                        END IF;
-- 2009/02/04 Y.Kawano Add End   #1142
--
                        -- 移動ロット詳細の数量が0以外の場合(実績登録する)
                        IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity <> 0) THEN  --(e)
--
--                        -- 移動ロット詳細の数量が0以外の場合(実績登録する)
--                        ELSE
                        -- 2008/4/14 modify end
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【35】移動ロット詳細の数量が0以外で');
--
                          -------------------------------------------------------------
                          -- 実績(保留トラン)の数量が0の場合は前回0実績計上されているから保留トランにデータなし
                          -- 倉庫組織会社情報がないため取得する
                          -------------------------------------------------------------
                          IF (ln_out_pnd_trans_qty = 0) THEN  --(d)
                            --for debug
--                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【36】ln_out_pnd_trans_qty = 0');
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【37】組織情報取得  START');
--
                            BEGIN
                              -- 変数初期化
                              lv_from_orgn_code := NULL;
                              lv_from_co_code   := NULL;
                              lv_from_whse_code := NULL;
                              lv_to_orgn_code   := NULL;
                              lv_to_co_code     := NULL;
                              lv_to_whse_code   := NULL;
                              ln_err_flg        := 0;
--
                              -- 組織,会社,倉庫の取得カーソルオープン
                              OPEN xxcmn_locations_cur(
                                        move_target_tbl(gn_rec_idx).shipped_locat_id    -- 出庫元
                                       ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- 入庫先
--
                              <<xxcmn_locations_cur_loop>>
                              LOOP
                                FETCH xxcmn_locations_cur
                                INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                                     ,lv_from_co_code         -- 会社コード(出庫用)
                                     ,lv_from_whse_code       -- 倉庫コード(出庫用)
                                     ,lv_to_orgn_code         -- 組織コード(入庫用)
                                     ,lv_to_co_code           -- 会社コード(入庫用)
                                     ,lv_to_whse_code         -- 倉庫コード(入庫用)
                                     ;
                                EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                              END LOOP xxcmn_locations_cur_loop;
--
                              -- カーソルクローズ
                              CLOSE xxcmn_locations_cur;
--
                            EXCEPTION
                              WHEN NO_DATA_FOUND THEN                             -- データ取得エラー
                                -- エラーフラグ
                                ln_err_flg  := 1;
                                IF (xxcmn_locations_cur%ISOPEN) THEN
                                  -- カーソルクローズ
                                  CLOSE xxcmn_locations_cur;
                                END IF;
                                -- エラーメッセージ内容
                                lv_err_msg_value
                                      := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                                lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                      gv_c_msg_57a_006, -- データ取得エラー
                                                                      gv_c_tkn_msg,     -- トークンMSG
                                                                      lv_err_msg_value  -- トークン値
                                                                      );
                                -- エラー内容格納
                                out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                                -- エラー移動番号PLSQL表に格納
                                err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                                err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                              WHEN TOO_MANY_ROWS THEN                             -- データ取得エラー
                                -- エラーフラグ
                                ln_err_flg  := 1;
--
                                IF (xxcmn_locations_cur%ISOPEN) THEN
                                  -- カーソルクローズ
                                  CLOSE xxcmn_locations_cur;
                                END IF;
                                -- エラーメッセージ内容
                                lv_err_msg_value
                                      := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                                lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                      gv_c_msg_57a_006, -- データ取得エラー
                                                                      gv_c_tkn_msg,     -- トークンMSG
                                                                      lv_err_msg_value  -- トークン値
                                                                      );
                                -- エラー内容格納
                                out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                                -- エラー移動番号PLSQL表に格納
                                err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                                err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                            END;
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【38】組織情報取得  END');
--
                            -----------------------------------------------------------------
                            -- 組織、会社、倉庫情報が取得できた場合
                            IF (ln_err_flg = 0) THEN
                              -- for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'【39】実績格納  START');
--
                              -- 実績登録用レコードにデータを格納
                              move_api_rec_tbl(ln_idx_move).orgn_code              := lv_from_orgn_code;
                              move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                              move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                              move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                              move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                              move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                              move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
-- 2008/12/25 Y.Kawano Upd Start #844
--                              move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                              move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                             move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                             move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                              move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- 出庫実績日
                              move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- 入庫実績日
                              move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                              move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                              -- インクリメント
                              ln_idx_move := ln_idx_move + 1;
--
                              --for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'【40】実績格納  END');
--
                            END IF;
--
                          -----------------------------------------------------
                          -- 実績(保留トラン)の数量が0でない場合
                          -- 前回実績計上されているから倉庫組織会社情報がある
                          -----------------------------------------------------
                          ELSE  --(d)
--
                            -- for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【41】実績だけ格納  START');
--
                            -- 実績登録用レコードにデータを格納
                            move_api_rec_tbl(ln_idx_move).orgn_code              := lv_out_orgn_code;
                            move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                            move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                            move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                            move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                            move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                            move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
-- 2008/12/25 Y.Kawano Upd Start #844
--                            move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                            move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                            move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                            move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                            move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- 出庫実績日
                            move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- 入庫実績日
                            move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                            move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                            -- インクリメント
                            ln_idx_move := ln_idx_move + 1;
--
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【42】実績だけ格納  end');
--
                          END IF;  -- (d)
--
                        END IF;  --(e)
--
-- 2008/12/13 Y.Kawano Upd End
                      -- 黒数量と赤数量が違う場合
                      ELSE  --(f)
                        --for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【33-2】実績(保留トラン)と実績訂正(完了トラン)の数量違う');
                      -- 2008/04/14 modify end
--
                        -- 2008/4/14 modify start
                        -- 黒情報
                        -- 移動ロット詳細の数量が0の場合(実績登録しない)
                        --IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN
                        --  -- 何もしない
                        --  NULL;
                        --  --for debug
                        --  --FND_FILE.PUT_LINE(FND_FILE.LOG,'【34】移動ロット詳細の数量が0だから何もしない');
--
--2008/12/13 Y.Kawano Upd Start
--                        -- 移動ロット詳細の数量が0の場合
--                        IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN
--2008/12/13 Y.Kawano Upd Start
--
                        -- 2008/4/14 modify start
                        --実績黒数量 0以外の場合 赤作る
                        IF (ln_out_pnd_trans_qty <> 0) THEN  -- (c)
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【34】赤作る');
--
                          -- 実績訂正作成情報格納
                          -- 実績訂正情報格納  在庫数量API実行対象レコードにデータを格納
                          adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                          adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                          adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                          adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                          adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                          adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                          adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_pnd_trans_qty);
                          adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_pnd_trans_qty);
                          adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                          adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                          adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                          adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                          adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                          adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                          adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- インクリメント
                          ln_idx_adji := ln_idx_adji + 1;
--
                        END IF;  -- (c)
--
--2008/12/13 Y.Kawano Upd Start
--                      END IF;
--2008/12/13 Y.Kawano Upd End
--
                        -- 移動ロット詳細の数量が0以外の場合(実績登録する)
                        IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity <> 0) THEN  --(b)
--
--                        -- 移動ロット詳細の数量が0以外の場合(実績登録する)
--                        ELSE
                        -- 2008/4/14 modify end
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【35】移動ロット詳細の数量が0以外で');
--
                          -------------------------------------------------------------
                          -- 実績(保留トラン)の数量が0の場合は前回0実績計上されているから保留トランにデータなし
                          -- 倉庫組織会社情報がないため取得する
                          -------------------------------------------------------------
                          IF (ln_out_pnd_trans_qty = 0) THEN --(a)
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【36】ln_out_pnd_trans_qty = 0');
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【37】組織情報取得  START');
--
                            BEGIN
                              -- 変数初期化
                              lv_from_orgn_code := NULL;
                              lv_from_co_code   := NULL;
                              lv_from_whse_code := NULL;
                              lv_to_orgn_code   := NULL;
                              lv_to_co_code     := NULL;
                              lv_to_whse_code   := NULL;
                              ln_err_flg        := 0;
--
                              -- 組織,会社,倉庫の取得カーソルオープン
                              OPEN xxcmn_locations_cur(
                                        move_target_tbl(gn_rec_idx).shipped_locat_id    -- 出庫元
                                       ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- 入庫先
--
                              <<xxcmn_locations_cur_loop>>
                              LOOP
                                FETCH xxcmn_locations_cur
                                INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                                     ,lv_from_co_code         -- 会社コード(出庫用)
                                     ,lv_from_whse_code       -- 倉庫コード(出庫用)
                                     ,lv_to_orgn_code         -- 組織コード(入庫用)
                                     ,lv_to_co_code           -- 会社コード(入庫用)
                                     ,lv_to_whse_code         -- 倉庫コード(入庫用)
                                     ;
                                EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                              END LOOP xxcmn_locations_cur_loop;
--
                              -- カーソルクローズ
                              CLOSE xxcmn_locations_cur;
--
                            EXCEPTION
                              WHEN NO_DATA_FOUND THEN                             -- データ取得エラー
                                -- エラーフラグ
                                ln_err_flg  := 1;
                                IF (xxcmn_locations_cur%ISOPEN) THEN
                                  -- カーソルクローズ
                                  CLOSE xxcmn_locations_cur;
                                END IF;
                                -- エラーメッセージ内容
                                lv_err_msg_value
                                      := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                                lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                      gv_c_msg_57a_006, -- データ取得エラー
                                                                      gv_c_tkn_msg,     -- トークンMSG
                                                                      lv_err_msg_value  -- トークン値
                                                                      );
                                -- エラー内容格納
                                out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                                -- エラー移動番号PLSQL表に格納
                                err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                                err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                              WHEN TOO_MANY_ROWS THEN                             -- データ取得エラー
                                -- エラーフラグ
                                ln_err_flg  := 1;
--
                                IF (xxcmn_locations_cur%ISOPEN) THEN
                                  -- カーソルクローズ
                                  CLOSE xxcmn_locations_cur;
                                END IF;
                                -- エラーメッセージ内容
                                lv_err_msg_value
                                      := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                                lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                      gv_c_msg_57a_006, -- データ取得エラー
                                                                      gv_c_tkn_msg,     -- トークンMSG
                                                                      lv_err_msg_value  -- トークン値
                                                                      );
                                -- エラー内容格納
                                out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                                -- エラー移動番号PLSQL表に格納
                                err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                                err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                            END;
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【38】組織情報取得  END');
--
                            -----------------------------------------------------------------
                            -- 組織、会社、倉庫情報が取得できた場合
                            IF (ln_err_flg = 0) THEN
                              -- for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'【39】実績格納  START');
--
                              -- 実績登録用レコードにデータを格納
                              move_api_rec_tbl(ln_idx_move).orgn_code              := lv_from_orgn_code;
                              move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                              move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                              move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                              move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                              move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                              move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
-- 2008/12/25 Y.Kawano Upd Start #844
--                              move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                              move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                              move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                              move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                              move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- 出庫実績日
                              move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- 入庫実績日
                              move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                              move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                              -- インクリメント
                              ln_idx_move := ln_idx_move + 1;
--
                              --for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'【40】実績格納  END');
--
                            END IF;
--
                          -----------------------------------------------------
                          -- 実績(保留トラン)の数量が0でない場合
                          -- 前回実績計上されているから倉庫組織会社情報がある
                          -----------------------------------------------------
                          ELSE
--
                            -- for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【41】実績だけ格納  START');
--
                            -- 実績登録用レコードにデータを格納
                            move_api_rec_tbl(ln_idx_move).orgn_code              := lv_out_orgn_code;
                            move_api_rec_tbl(ln_idx_move).item_no                := move_target_tbl(gn_rec_idx).item_code;
                            move_api_rec_tbl(ln_idx_move).lot_no                 := move_target_tbl(gn_rec_idx).lot_no;
                            move_api_rec_tbl(ln_idx_move).source_warehouse       := lv_from_whse_code;
                            move_api_rec_tbl(ln_idx_move).source_location        := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                            move_api_rec_tbl(ln_idx_move).target_warehouse       := lv_to_whse_code;
                            move_api_rec_tbl(ln_idx_move).target_location        := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
-- 2008/12/25 Y.Kawano Upd Start #844
--                            move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                            move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).schedule_arrival_date;
                            move_api_rec_tbl(ln_idx_move).scheduled_release_date := move_target_tbl(gn_rec_idx).actual_ship_date;
                            move_api_rec_tbl(ln_idx_move).scheduled_receive_date := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
                            move_api_rec_tbl(ln_idx_move).actual_release_date    := move_target_tbl(gn_rec_idx).actual_ship_date;    -- 出庫実績日
                            move_api_rec_tbl(ln_idx_move).actual_receive_date    := move_target_tbl(gn_rec_idx).actual_arrival_date; -- 入庫実績日
                            move_api_rec_tbl(ln_idx_move).release_quantity1      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                            move_api_rec_tbl(ln_idx_move).attribute1             := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                            -- インクリメント
                            ln_idx_move := ln_idx_move + 1;
--
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【42】実績だけ格納  end');
--
                          END IF;  --(a)
--
                        END IF;  --(b)
--
                      END IF;  --(f)
--
                    END IF;  --(h)
--
-- 2008/12/16 Y.Kawano Del Start
--                  END IF;  --(i)
-- 2008/12/16 Y.Kawano Del End
-- add start 1.9
                END IF;  --(j)
-- add end 1.9
--
              END IF;  --(r)
--
            END IF;  --(s)
--
          -- 2008/04/08 Modify End
          ---------------------------------------------------------
          /*****************************************/
          -- 積送なしの場合
          /*****************************************/
          ELSIF ( move_target_tbl(gn_rec_idx).mov_type = gv_c_move_type_n ) THEN  --(typeif)
            --for debug
            FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------- 積送なし ------------------');
--
            ----------------------------------
            -- 出庫元情報
            ----------------------------------
            -- 完了トラン情報 実績計上されている最新を取得
            BEGIN
              SELECT itc.orgn_code               -- プラントコード
                    ,itc.co_code                 -- 会社コード
                    ,itc.whse_code               -- 倉庫
                    ,itc.trans_date              -- 取引日
                    ,itc.trans_qty               -- 数量
              INTO   lv_out_orgn_code
                    ,lv_out_co_code
                    ,lv_from_whse_code
                    ,ld_out_trans_date
                    ,ln_out_cmp_trans_qty
              FROM   ic_tran_cmp   itc                      -- OPM完了在庫トランザクション
                    ,ic_adjs_jnl   iaj                      -- OPM在庫調整ジャーナル
                    ,ic_jrnl_mst   ijm                      -- OPMジャーナルマスタ
              WHERE  itc.location   = move_target_tbl(gn_rec_idx).shipped_locat_code
                                                                              -- 出庫保管倉庫コード
                AND  itc.item_id    = move_target_tbl(gn_rec_idx).item_id     -- 品目ID
                AND  itc.lot_id     = move_target_tbl(gn_rec_idx).lot_id      -- ロットID
                AND  itc.doc_type   = iaj.trans_type                          -- 文書タイプ
                AND  itc.doc_type   = gv_c_doc_type_trni                      -- 文書タイプ
-- 2008/12/13 Y.Kawano Upd Start
--                --AND  itc.doc_line   = iaj.doc_line                           -- 取引明細番号
                AND  itc.doc_line   = iaj.doc_line                             -- 取引明細番号
                AND  itc.doc_id     = iaj.doc_id                               -- 取引明細ID
-- 2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id = iaj.journal_id                          -- ジャーナルID
-- 2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id = itc.doc_id                              -- ジャーナルID
-- 2008/12/13 Y.Kawano Del End
            ------ 2008/04/11 modify start  ------
              --AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id -- 移動明細ID
                AND  itc.location   = iaj.location
                AND  itc.item_id    = iaj.item_id
                AND  itc.lot_id     = iaj.lot_id
-- 2009/06/09 H.Itou Mod Start 本番障害#1527 MAX(ID)は最新でない場合があるので、MAX(最終更新日)に変更。
--                AND  iaj.journal_id IN
--                                    (SELECT MAX(adj.journal_id)           -- 最新のデータ
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                    (SELECT MAX(adj.last_update_date)           -- 最新のデータ
-- 2009/06/09 H.Itou Mod End
                                     FROM   ic_adjs_jnl   adj
                                           ,ic_jrnl_mst   jrn
                                     WHERE adj.journal_id  = jrn.journal_id
                                     AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                     AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                     AND   adj.location    = move_target_tbl(gn_rec_idx).shipped_locat_code
                                     AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                     AND   adj.trans_type  = gv_c_doc_type_trni
                                     AND   adj.reason_code = gv_reason_code
                                    )
              --  AND  ROWNUM         = 1                                       -- 最新のデータ
            --ORDER BY itc.creation_date DESC                                 -- 作成日 降順
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データ取得できない場合、数量を0とする
                ln_out_cmp_trans_qty := 0;
                lv_out_orgn_code     := NULL;
                lv_out_co_code       := NULL;
                lv_from_whse_code    := NULL;
                ld_out_trans_date    := NULL;
            END;
--
            -- 完了トラン情報 実績計上されている最新の訂正情報を取得
            BEGIN
              SELECT itc.trans_qty               -- 数量
                    ,itc.trans_date              -- 取引日 -- 2008/04/14 add
              INTO   ln_out_cmp_a_trans_qty
                    ,ld_a_out_trans_date                    -- 2008/04/14 add
              FROM   ic_tran_cmp   itc                      -- OPM完了在庫トランザクション
                    ,ic_adjs_jnl   iaj                      -- OPM在庫調整ジャーナル
                    ,ic_jrnl_mst   ijm                      -- OPMジャーナルマスタ
              WHERE  itc.location   = move_target_tbl(gn_rec_idx).shipped_locat_code
                                                                              -- 出庫保管倉庫コード
                AND  itc.item_id    = move_target_tbl(gn_rec_idx).item_id     -- 品目ID
                AND  itc.lot_id     = move_target_tbl(gn_rec_idx).lot_id      -- ロットID
                AND  itc.doc_type   = iaj.trans_type                          -- 文書タイプ
                AND  itc.doc_type   = gv_c_doc_type_adji                      -- 文書タイプ
-- 2008/12/13 Y.Kawano Upd Start
--                --AND  itc.doc_line   = iaj.doc_line                           -- 取引明細番号
                AND  itc.doc_line   = iaj.doc_line                             -- 取引明細番号
                AND  itc.doc_id     = iaj.doc_id                               -- 取引明細ID
-- 2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id = iaj.journal_id                          -- ジャーナルID
-- 2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id = itc.doc_id                              -- ジャーナルID
-- 2008/12/13 Y.Kawano Del End
            ------ 2008/04/11 modify start  ------
              -- AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id  -- 移動明細ID
              -- AND  ROWNUM         = 1                                        -- 最新のデータ
              -- ORDER BY itc.creation_date DESC                                -- 作成日 降順
-- 2009/06/09 H.Itou Mod Start 本番障害#1527 MAX(ID)は最新でない場合があるので、MAX(最終更新日)に変更。
--                AND  iaj.journal_id IN
--                                      (SELECT MAX(adj.journal_id)           -- 最新のデータ
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                      (SELECT MAX(adj.last_update_date)           -- 最新のデータ
-- 2009/06/09 H.Itou Mod End
                                       FROM   ic_adjs_jnl   adj
                                             ,ic_jrnl_mst   jrn
                                       WHERE adj.journal_id  = jrn.journal_id
                                       AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                       AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                       AND   adj.location    = move_target_tbl(gn_rec_idx).shipped_locat_code
                                       AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                       AND   adj.trans_type  = gv_c_doc_type_adji
                                       AND   adj.reason_code = gv_reason_code_cor
                                      )
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データ取得できない場合、数量を0とする
                ln_out_cmp_a_trans_qty := 0;
                ld_a_out_trans_date    := NULL;
            END;
--
            ----------------------------------
            -- 入庫先情報
            ----------------------------------
            -- 完了トラン情報 実績計上されている最新を取得
            BEGIN
              SELECT itc.orgn_code               -- プラントコード
                    ,itc.co_code                 -- 会社コード
                    ,itc.whse_code               -- 倉庫
                    ,itc.trans_date              -- 取引日
                    ,itc.trans_qty               -- 数量
              INTO   lv_in_orgn_code
                    ,lv_in_co_code
                    ,lv_to_whse_code
                    ,ld_in_trans_date
                    ,ln_in_cmp_trans_qty
              FROM   ic_tran_cmp   itc                      -- OPM完了在庫トランザクション
                    ,ic_adjs_jnl   iaj                      -- OPM在庫調整ジャーナル
                    ,ic_jrnl_mst   ijm                      -- OPMジャーナルマスタ
              WHERE  itc.location   = move_target_tbl(gn_rec_idx).ship_to_locat_code -- 入庫保管倉庫コード
                AND  itc.item_id    = move_target_tbl(gn_rec_idx).item_id    -- 品目ID
                AND  itc.lot_id     = move_target_tbl(gn_rec_idx).lot_id     -- ロットID
                AND  itc.doc_type   = iaj.trans_type                         -- 文書タイプ
                AND  itc.doc_type   = gv_c_doc_type_trni                     -- 文書タイプ
-- 2008/12/13 Y.Kawano Upd Start
--                --AND  itc.doc_line   = iaj.doc_line                           -- 取引明細番号
                AND  itc.doc_line   = iaj.doc_line                           -- 取引明細番号
                AND  itc.doc_id     = iaj.doc_id                             -- 取引明細ID
-- 2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id = iaj.journal_id                         -- ジャーナルID
-- 2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id = itc.doc_id                              -- ジャーナルID
-- 2008/12/13 Y.Kawano Del End
          ------ 2008/04/11 modify start  ------
              -- AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id -- 移動明細ID
                AND  itc.location   = iaj.location
                AND  itc.item_id    = iaj.item_id
                AND  itc.lot_id     = iaj.lot_id
-- 2009/06/09 H.Itou Mod Start 本番障害#1527 MAX(ID)は最新でない場合があるので、MAX(最終更新日)に変更。
--                AND  iaj.journal_id IN
--                                      (SELECT MAX(adj.journal_id)           -- 最新のデータ
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                      (SELECT MAX(adj.last_update_date)           -- 最新のデータ
-- 2009/06/09 H.Itou Mod End
                                       FROM   ic_adjs_jnl   adj
                                             ,ic_jrnl_mst   jrn
                                       WHERE adj.journal_id  = jrn.journal_id
                                       AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                       AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                       AND   adj.location    = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                       AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                       AND   adj.trans_type  = gv_c_doc_type_trni
                                       AND   adj.reason_code = gv_reason_code
                                      )
--                AND  ROWNUM         = 1                                       -- 最新のデータ
--              ORDER BY itc.creation_date DESC                                 -- 作成日 降順
            ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データ取得できない場合、数量を0とする
                ln_in_cmp_trans_qty := 0;
                lv_in_orgn_code     := NULL;
                lv_in_co_code       := NULL;
                lv_to_whse_code     := NULL;
                ld_in_trans_date    := NULL;
            END;
--
            -- 完了トラン情報 実績計上されている最新の訂正情報を取得
            BEGIN
              SELECT itc.trans_qty               -- 数量
                    ,itc.trans_date              -- 取引日 -- 2008/04/14 add
              INTO   ln_in_cmp_a_trans_qty
                    ,ld_a_in_trans_date                     -- 2008/04/14 add
              FROM   ic_tran_cmp   itc                      -- OPM完了在庫トランザクション
                    ,ic_adjs_jnl   iaj                      -- OPM在庫調整ジャーナル
                    ,ic_jrnl_mst   ijm                      -- OPMジャーナルマスタ
              WHERE  itc.location   = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                                                             -- 入庫保管倉庫コード
                AND  itc.item_id    = move_target_tbl(gn_rec_idx).item_id     -- 品目ID
                AND  itc.lot_id     = move_target_tbl(gn_rec_idx).lot_id      -- ロットID
                AND  itc.doc_type   = iaj.trans_type                         -- 文書タイプ
                AND  itc.doc_type   = gv_c_doc_type_adji                     -- 文書タイプ
-- 2008/12/13 Y.Kawano Upd Start
--                --AND  itc.doc_line   = iaj.doc_line                           -- 取引明細番号
                AND  itc.doc_line   = iaj.doc_line                           -- 取引明細番号
                AND  itc.doc_id     = iaj.doc_id                             -- 取引明細ID
-- 2008/12/13 Y.Kawano Upd End
                AND  ijm.journal_id = iaj.journal_id                         -- ジャーナルID
-- 2008/12/13 Y.Kawano Del Start
--                AND  ijm.journal_id = itc.doc_id                              -- ジャーナルID
-- 2008/12/13 Y.Kawano Del End
          ------ 2008/04/11 modify start  ------
              -- AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id -- 移動明細ID
                AND  itc.location   = iaj.location
                AND  itc.item_id    = iaj.item_id
                AND  itc.lot_id     = iaj.lot_id
-- 2009/06/09 H.Itou Mod Start 本番障害#1527 MAX(ID)は最新でない場合があるので、MAX(最終更新日)に変更。
--                AND  iaj.journal_id IN
--                                      (SELECT MAX(adj.journal_id)           -- 最新のデータ
                AND  ijm.attribute1 = move_target_tbl(gn_rec_idx).mov_line_id
                AND  iaj.last_update_date IN
                                      (SELECT MAX(adj.last_update_date)           -- 最新のデータ
-- 2009/06/09 H.Itou Mod End
                                       FROM   ic_adjs_jnl   adj
                                             ,ic_jrnl_mst   jrn
                                       WHERE adj.journal_id  = jrn.journal_id
                                       AND   adj.item_id     = move_target_tbl(gn_rec_idx).item_id
                                       AND   adj.lot_id      = move_target_tbl(gn_rec_idx).lot_id
                                       AND   adj.location    = move_target_tbl(gn_rec_idx).ship_to_locat_code
                                       AND   jrn.attribute1  = move_target_tbl(gn_rec_idx).mov_line_id
                                       AND   adj.trans_type  = gv_c_doc_type_adji
                                       AND   adj.reason_code = gv_reason_code_cor
                                      )
--              AND  ROWNUM         = 1                                       -- 最新のデータ
--            ORDER BY itc.creation_date DESC                                 -- 作成日 降順
          ------ 2008/04/11 modify end    ------
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- データ取得できない場合、数量を0とする
                ln_in_cmp_a_trans_qty := 0;
                ld_a_in_trans_date    := NULL;
            END;
          ---------------------------------------------------------
            -- 2008/04/08 Modify Start
            -- for debug
            FND_FILE.PUT_LINE(FND_FILE.LOG,'【1】');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'mov_line_id='||move_target_tbl(gn_rec_idx).mov_line_id);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'item_id='||to_char(move_target_tbl(gn_rec_idx).item_id));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'lot_id='||to_char(move_target_tbl(gn_rec_idx).lot_id));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_cmp_trans_qty='||to_char(ln_out_cmp_trans_qty));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_trans_qty='||to_char(ln_in_cmp_trans_qty));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_out_cmp_a_trans_qty= '||to_char(ln_out_cmp_a_trans_qty));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_in_cmp_a_trans_qty = '||to_char(ln_in_cmp_a_trans_qty));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'out_actual_quantity   = '|| to_char(move_target_tbl(gn_rec_idx).lot_out_actual_quantity));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'in_actual_quantity    = '|| to_char(move_target_tbl(gn_rec_idx).lot_in_actual_quantity));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'out_bef_actual_qty    = '|| to_char(move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'in_bef_actual_qty     = '|| to_char(move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity));
            --
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_out_trans_date='||to_char(ld_out_trans_date,'yyyy/mm/dd'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_in_trans_date=' ||to_char(ld_in_trans_date,'yyyy/mm/dd'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_a_out_trans_date = '||to_char(ld_a_out_trans_date,'yyyy/mm/dd'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_a_in_trans_date  = '||to_char(ld_a_in_trans_date,'yyyy/mm/dd'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_ship_date    = '|| to_char(move_target_tbl(gn_rec_idx).actual_ship_date,'yyyy/mm/dd'));
            FND_FILE.PUT_LINE(FND_FILE.LOG,'actual_arrival_date = '|| to_char(move_target_tbl(gn_rec_idx).actual_arrival_date,'yyyy/mm/dd'));
--
            ---------------------------------------------------------
            -- 実績(黒)の出庫と入庫、または訂正(赤)の出庫と入庫が異なる
            ---------------------------------------------------------
            IF (ABS(ln_out_cmp_trans_qty) <> ABS(ln_in_cmp_trans_qty))      -- 保留トランの入出庫数が違う
            OR (ABS(ln_out_cmp_a_trans_qty) <> ABS(ln_in_cmp_a_trans_qty))  -- 完了トランの入出庫数が違う
            THEN  -- (A)
--
              -- 完了トラン(TRNI)または完了トラン(ADJI)のデータ不整合
              RAISE global_api_expt;
--
            ---------------------------------------------------------
            -- 実績(黒)の出庫と入庫、訂正(赤)の出庫と入庫が同じ
            ---------------------------------------------------------
            ELSIF (ABS(ln_out_cmp_trans_qty) = ABS(ln_in_cmp_trans_qty))     -- 保留トランの入出庫数が同じ
              AND (ABS(ln_out_cmp_a_trans_qty) = ABS(ln_in_cmp_a_trans_qty)) -- 完了トランの入出庫数が同じ
            THEN  -- (A)
            --for debug
            FND_FILE.PUT_LINE(FND_FILE.LOG,'【2】実績(黒)の出庫と入庫、または訂正(赤)の出庫と入庫が同じ');
--
              --===========================================================
              -- 実績(完了トラン)の日付と移動ヘッダアドオンの実績日が異なる場合
              -- →全赤作る
              --===========================================================
              IF (TRUNC(ld_out_trans_date) <> move_target_tbl(gn_rec_idx).actual_ship_date)   -- 出庫実績日
              OR (TRUNC(ld_in_trans_date) <> move_target_tbl(gn_rec_idx).actual_arrival_date) -- 入庫実績日
              THEN  -- (B)
--
              -- for debug
              FND_FILE.PUT_LINE(FND_FILE.LOG,'【3】実績(完了トラン)の日付と移動ヘッダアドオンの実績日が異なる');
--
              -- 2008/04/14 modify start
              --  -----------------------------------------------------------------
              --  -- 実績の数量と実績訂正の数量が異なる場合
              --  -- 赤作る
              --  IF (ABS(ln_out_cmp_trans_qty) <> ABS(ln_out_cmp_a_trans_qty))    -- 出庫数cmpとcmp_a
              --  AND (ABS(ln_in_cmp_trans_qty)  <> ABS(ln_in_cmp_a_trans_qty))    -- 入庫数cmpとcmp_a
              --  THEN
--
                --=============================================================
                -- 実績と実績訂正の取引日が異なる場合
                --=============================================================
                IF  (TRUNC(ld_out_trans_date) <> TRUNC(ld_a_out_trans_date)) -- 出庫日 実績と実績訂正
                OR (TRUNC(ld_in_trans_date)  <> TRUNC(ld_a_in_trans_date))   -- 入庫日 実績と実績訂正
                OR ld_a_out_trans_date IS NULL
                OR ld_a_in_trans_date IS NULL
                THEN  -- (C)
              -- 2008/04/14 modify end
                -- for debug
                FND_FILE.PUT_LINE(FND_FILE.LOG,'【4】実績と実績訂正の実績日が異なる');
--
                  -- 黒数量が0でない場合
                  IF (ln_out_cmp_trans_qty <> 0) THEN  -- (D)
                    --for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【6】黒数量が0でない');
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【7】実績訂正情報格納 START');
--
                  -----------------------------------------------------------------
                  -- 赤情報
                  -- 実績訂正情報格納  在庫数量API実行対象レコードにデータを格納
                    adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                    adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                    adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                    adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                    adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                    adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                    adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
                    adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
                    adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                    adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                    adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                    adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                    adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                    adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                    adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                    -- インクリメント
                    ln_idx_adji := ln_idx_adji + 1;
--
                    --for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【8】実績訂正情報格納 End');
                  END IF;  -- (D)
--
                  -----------------------------------------------------------------
                  -- 黒情報
                  -- 移動情報の数量が0の場合(実績登録しない)
                  IF ( move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0 ) THEN  -- (E)
                    -- 何もしない
                    NULL;
                  --for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【9】ロット詳細数量=0');
--
                  -----------------------------------------------------------------
                  -- 移動情報の数量が0でない場合(実績登録する)
                  ELSE  -- (E)
--
                  --for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【10】ロット詳細数量<>0');
                  -----------------------------------------------------------------
                  -- 実績(保留トラン)の数量が0の場合は前回0実績計上されているから保留トランにデータなし
                  -- 倉庫組織会社情報がないため取得する
                  -----------------------------------------------------------------
                    IF (ln_out_cmp_trans_qty = 0) THEN  -- (F)
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【11】cmp_qty<>0');
--
                      BEGIN
                        -- 変数初期化
                        lv_from_orgn_code := NULL;
                        lv_from_co_code   := NULL;
                        lv_from_whse_code := NULL;
                        lv_to_orgn_code   := NULL;
                        lv_to_co_code     := NULL;
                        lv_to_whse_code   := NULL;
                        ln_err_flg        := 0;
--
                        -- 組織,会社,倉庫の取得カーソルオープン
                        OPEN xxcmn_locations_cur(
                                move_target_tbl(gn_rec_idx).shipped_locat_id    -- 出庫元
                               ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- 入庫先
--
                        <<xxcmn_locations_cur_loop>>
                        LOOP
                          FETCH xxcmn_locations_cur
                          INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                               ,lv_from_co_code         -- 会社コード(出庫用)
                               ,lv_from_whse_code       -- 倉庫コード(出庫用)
                               ,lv_to_orgn_code         -- 組織コード(入庫用)
                               ,lv_to_co_code           -- 会社コード(入庫用)
                               ,lv_to_whse_code         -- 倉庫コード(入庫用)
                               ;
                          EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                        END LOOP xxcmn_locations_cur_loop;
--
                        -- カーソルクローズ
                        CLOSE xxcmn_locations_cur;
--
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN                             -- データ取得エラー
                          -- エラーフラグ
                          ln_err_flg  := 1;
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- カーソルクローズ
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- エラーメッセージ内容
                          lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- データ取得エラー
                                                                gv_c_tkn_msg,     -- トークンMSG
                                                                lv_err_msg_value  -- トークン値
                                                                );
                          -- エラー内容格納
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- エラー移動番号PLSQL表に格納
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        WHEN TOO_MANY_ROWS THEN                             -- データ取得エラー
                          -- エラーフラグ
                          ln_err_flg  := 1;
--
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- カーソルクローズ
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- エラーメッセージ内容
                          lv_err_msg_value
                              := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- データ取得エラー
                                                                gv_c_tkn_msg,     -- トークンMSG
                                                                lv_err_msg_value  -- トークン値
                                                                );
                          -- エラー内容格納
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- エラー移動番号PLSQL表に格納
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                      END;
--
                      -----------------------------------------------------------------
                      -- 組織、会社、倉庫情報が取得できた場合
                      IF (ln_err_flg = 0) THEN  --(G)
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【12】trni実績格納 START');
--
                        -- trni実績登録用レコードにデータを格納
                        trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                        trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                        trni_api_rec_tbl(ln_idx_trni).co_code        := lv_from_co_code;
                        trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_from_orgn_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- 出庫実績日
                        trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- インクリメント
                        ln_idx_trni := ln_idx_trni + 1;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【13】trni実績格納 End');
--
                      END IF;   -- (G)
--
                    -----------------------------------------------------
                    -- 実績(保留トラン)の数量が0でない場合
                    -- 前回実績計上されているから倉庫組織会社情報がある
                    -----------------------------------------------------
                    ELSE  --(F)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【14】trni実績格納 Start');
--
                      -- trni実績登録用レコードにデータを格納
                      trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                      trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                      trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                      trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                      trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                      trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
                      trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                      trni_api_rec_tbl(ln_idx_trni).co_code        := lv_out_co_code;
                      trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_out_orgn_code;
                      trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- 出庫実績日
                      trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- インクリメント
                      ln_idx_trni := ln_idx_trni + 1;
--
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【15】trni実績格納 End');
--
                    END IF;  -- (F)
--
                  END IF; --移動情報の数量判定 -- (E)
--
                -- for debug
                FND_FILE.PUT_LINE(FND_FILE.LOG,'【16】');
--
              -- 2008/04/14 modify start
              --  ---------------------------------------------------------------
              --  -- 実績(cmp)の数量と実績訂正(cmp_a)の数量が同じ場合
              --  -- 赤作らない 黒だけ作る
              --  ---------------------------------------------------------------
              --  ELSIF (ABS(ln_out_cmp_trans_qty) = ABS(ln_out_cmp_a_trans_qty))   -- 出庫数
              --  AND   (ABS(ln_in_cmp_trans_qty)  = ABS(ln_in_cmp_a_trans_qty))    -- 入庫数
              --  THEN
--
                --=============================================================
                -- 実績(cmp)と実績訂正(cmp_a)の取引日が同じ場合
                --=============================================================
                ELSIF (TRUNC(ld_out_trans_date) = TRUNC(ld_a_out_trans_date)) -- 出庫日 実績と実績訂正
                AND (TRUNC(ld_in_trans_date)  = TRUNC(ld_a_in_trans_date))    -- 入庫日 実績と実績訂正
                THEN  -- (D)
--
                -- for debug
                FND_FILE.PUT_LINE(FND_FILE.LOG,'【17】実績と実績訂正の実績日が同じ');
--
                  -- 実績(cmp)と実績訂正(cmp_a)の数量が同じ場合
                  IF (ABS(ln_out_cmp_trans_qty) = ABS(ln_out_cmp_a_trans_qty))   -- 出庫数
                  AND (ABS(ln_in_cmp_trans_qty)  = ABS(ln_in_cmp_a_trans_qty))   -- 入庫数
                  THEN  -- (H)
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【18】実績と実績訂正の数量が同じ');
--
                  -- 2008/04/15 modify start
                  -- 何もしない
                  --NULL;
                  -- ロット詳細の実績数量が0の場合
                    IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  -- (I)
                      -- 何もしない
                      NULL;
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【18a ロット詳細の実績数量が0  何もしない】');
--
                    ELSE  -- (I)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【18b ロット詳細の実績数量が0じゃない  黒作成】');
--
                    -- 黒作成
                    -- 実績登録用レコードにデータを格納
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【18c】trni実績格納 Start');
--
                      -- trni実績登録用レコードにデータを格納
                      trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                      trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                      trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                      trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                      trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                      trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code; -- 入庫先
                      trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                      trni_api_rec_tbl(ln_idx_trni).co_code        := lv_out_co_code;
                      trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_out_orgn_code;
                      trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- 出庫実績日
                      trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- インクリメント
                      ln_idx_trni := ln_idx_trni + 1;
--
                    --FND_FILE.PUT_LINE(FND_FILE.LOG,'【18c】trni実績格納 End');
--
                    END IF;  -- (I)
--
                  -- 黒数量と赤数量が違う場合
                  ELSE  -- (H)
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【18-1】黒数量と赤数量が違う');
                    -- 赤作成
                    -- 黒数量が0以外(実績あり)の場合、赤作る
                    IF (ln_out_cmp_trans_qty <> 0) THEN  -- (J)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【18-2】赤  格納Start');
--
                      -- 赤情報
                      -- 実績訂正情報格納  在庫数量API実行対象レコードにデータを格納
                      adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                      adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                      adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                      adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                      adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- インクリメント
                      ln_idx_adji := ln_idx_adji + 1;
--
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【18-2】赤  格納End');
--
                    END IF;  -- (J)
--
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'【19】');
--
                    -----------------------------------------------------------------
                    -- 移動ロット詳細の数量が0の場合(実績登録しない)
                    IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  -- (K)
--
                      -- 何もしない
                      NULL;
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【20】ロット詳細が0');
--
                    -----------------------------------------------------------------
                    -- 移動ロット詳細の数量が0以外の場合(実績登録する)
                    ELSE  -- (K)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【21】ロット詳細が0以外');
--
                      -- 実績(cmp)の数量が0の場合は前回0実績計上されているからデータなし
                      -- 倉庫組織会社情報がないため取得する
                      IF (ln_out_cmp_trans_qty = 0) THEN  -- (L)
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【22】ln_out_cmp_trans_qtyが0');
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【23】組織情報取得START');
--
                        BEGIN
                          -- 変数初期化
                          lv_from_orgn_code := NULL;
                          lv_from_co_code   := NULL;
                          lv_from_whse_code := NULL;
                          lv_to_orgn_code   := NULL;
                          lv_to_co_code     := NULL;
                          lv_to_whse_code   := NULL;
                          ln_err_flg        := 0;
--
                          -- 組織,会社,倉庫の取得カーソルオープン
                          OPEN xxcmn_locations_cur(
                                    move_target_tbl(gn_rec_idx).shipped_locat_id    -- 出庫元
                                   ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- 入庫先
--
                          <<xxcmn_locations_cur_loop>>
                          LOOP
                            FETCH xxcmn_locations_cur
                            INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                                 ,lv_from_co_code         -- 会社コード(出庫用)
                                 ,lv_from_whse_code       -- 倉庫コード(出庫用)
                                 ,lv_to_orgn_code         -- 組織コード(入庫用)
                                 ,lv_to_co_code           -- 会社コード(入庫用)
                                 ,lv_to_whse_code         -- 倉庫コード(入庫用)
                                 ;
                            EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                          END LOOP xxcmn_locations_cur_loop;
--
                          -- カーソルクローズ
                          CLOSE xxcmn_locations_cur;
--
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN                             -- データ取得エラー
                            -- エラーフラグ
                            ln_err_flg  := 1;
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- カーソルクローズ
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- エラーメッセージ内容
                            lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- データ取得エラー
                                                                  gv_c_tkn_msg,     -- トークンMSG
                                                                  lv_err_msg_value  -- トークン値
                                                                  );
                            -- エラー内容格納
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- エラー移動番号PLSQL表に格納
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                          WHEN TOO_MANY_ROWS THEN                             -- データ取得エラー
                            -- エラーフラグ
                            ln_err_flg  := 1;
--
                            IF (xxcmn_locations_cur%ISOPEN) THEN
                              -- カーソルクローズ
                              CLOSE xxcmn_locations_cur;
                            END IF;
                            -- エラーメッセージ内容
                            lv_err_msg_value
                                  := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                            lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                  gv_c_msg_57a_006, -- データ取得エラー
                                                                  gv_c_tkn_msg,     -- トークンMSG
                                                                  lv_err_msg_value  -- トークン値
                                                                  );
                            -- エラー内容格納
                            out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                            -- エラー移動番号PLSQL表に格納
                            err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                            err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        END;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【24】組織情報取得 End');
                        -----------------------------------------------------------------
                        -- 組織、会社、倉庫情報が取得できた場合
                        IF (ln_err_flg = 0) THEN  -- (M)
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【25】trni実績格納  START');
--
                          -- trni実績登録用レコードにデータを格納
                          trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                          trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                          trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                          trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                          trni_api_rec_tbl(ln_idx_trni).co_code        := lv_from_co_code;
                          trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_from_orgn_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- 出庫実績日
                          trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- インクリメント
                          ln_idx_trni := ln_idx_trni + 1;
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【26】trni実績格納  End');
--
                        END IF;  -- (M)

--
                      -----------------------------------------------------
                      -- 実績(cmp)の数量が0でない場合
                      -- 前回実績計上されているから倉庫組織会社情報がある
                      -----------------------------------------------------
                      ELSE  -- (L)
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【27】trni実績格納するだけ  START');
--
                        -- trni実績登録用レコードにデータを格納
                        trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元保管倉庫
                        trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                        trni_api_rec_tbl(ln_idx_trni).co_code    := lv_out_co_code;
                        trni_api_rec_tbl(ln_idx_trni).orgn_code  := lv_out_orgn_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_date := move_target_tbl(gn_rec_idx).actual_ship_date; -- 出庫実績日
                        trni_api_rec_tbl(ln_idx_trni).attribute1 := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- インクリメント
                        ln_idx_trni := ln_idx_trni + 1;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【27】trni実績格納するだけ  End');
--
                      END IF;  -- (L)
--
                    END IF;  -- (K)
--
                  END IF;  -- (H)
--
                END IF;  -- (D)
--
              --===========================================================
              -- 実績(cmp)の日付と移動ヘッダアドオンの実績日が同じ場合
              -- →数量が変更されているデータのみ処理対象にする
              --===========================================================
              ELSE  -- (B)
-- add start 1.9
                IF ((move_target_tbl(gn_rec_idx).lot_out_actual_quantity = move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity)
                  AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity))
                THEN  -- (N)
                  NULL;
                ELSE  -- (N)
-- add end 1.9
                --for debug
                FND_FILE.PUT_LINE(FND_FILE.LOG,'【28】実績(cmp)の日付と移動ヘッダアドオンの実績日が同じ');
--
-- 2008/12/16 Y.Kawano Del Start
-- 上記IF文で、変更なし分は対象外となっている為、不要なIF文を削除
--                ------------------------------------------------------------------
--                -- ロット詳細アドオンの数量と実績(保留トラン)の数量が同じ場合
--                -- →ロット詳細アドオンの数量が変更されていない
--                ------------------------------------------------------------------
--                IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = ABS(ln_out_cmp_trans_qty)) THEN
--                  -- 何もしない
--                  NULL;
--
--                  -- for debug
--                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【29】ロット詳細アドオンの数量と実績(保留トラン)の数量が同じ');
--                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【29】何もしない');
--
--                ------------------------------------------------------------------
--                -- ロット詳細アドオンの数量と実績(cmp)の数量が異なる場合
--                -- →ロット詳細アドオンの数量が変更されている
--                ------------------------------------------------------------------
--                ELSE
-- 2008/12/16 Y.Kawano Del End
                  -- for debug
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'【30】ロット詳細アドオンの数量と実績(保留トラン)の数量が違う');
--
                  --================================================================
                  -- 実績(cmp)の数量と実績訂正(cmp_a)の数量が異なる場合
                  --================================================================
                  -- 2008/4/14 modify start
                  --  IF (ABS(ln_out_cmp_trans_qty) <> ABS(ln_out_cmp_a_trans_qty))    -- 出庫数
                  --  AND (ABS(ln_in_cmp_trans_qty)  <> ABS(ln_in_cmp_a_trans_qty))    -- 入庫数
                  --  THEN
--
                  IF (TRUNC(ld_out_trans_date) <> TRUNC(ld_a_out_trans_date))  -- 出庫日 実績と実績訂正
                  OR (TRUNC(ld_in_trans_date)  <> TRUNC(ld_a_in_trans_date))  -- 入庫日 実績と実績訂正
                  OR ld_a_out_trans_date IS NULL
                  OR ld_a_in_trans_date IS NULL
                  THEN  -- (O)
                    -- for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【31】実績(cmp)と実績訂正(cmp_a)の実績日が異なる');
--
                    ------------------------------------------------------------------
                    -- 実績(cmp)の数量が0でない場合
                    -- 赤作る
                    ------------------------------------------------------------------
                    IF ( ABS(ln_out_cmp_trans_qty) <> 0 ) THEN  -- (P)
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【32】実績(cmp)の数量が0でない');
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【33】実績訂正格納 Start');
--
                      -- 実績訂正作成情報格納
                      -- 在庫数量API実行対象レコードにデータを格納 出庫データ
                      adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                      adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                      adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                      adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
                      adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                      adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                      adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                      adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                      -- インクリメント
                      ln_idx_adji := ln_idx_adji + 1;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【33】実績訂正格納 End');
--
                    END IF;  -- (P)
--
                    ------------------------------------------------------------------
                    -- 黒情報
                    -- 移動ロット詳細の数量が0の場合(実績登録しない)
                    IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  -- (Q)
                      -- 何もしない
                      NULL;
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【34】ロット詳細の数量が0');
--
                    ------------------------------------------------------------------
                    -- 移動ロット詳細の数量が0以外の場合(実績登録する)
                    ELSE  -- (Q)
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【35】ロット詳細の数量が0じゃない');
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【36】trni実績  格納START');
--
                      BEGIN
                        -- 変数初期化
                        lv_from_orgn_code := NULL;
                        lv_from_co_code   := NULL;
                        lv_from_whse_code := NULL;
                        lv_to_orgn_code   := NULL;
                        lv_to_co_code     := NULL;
                        lv_to_whse_code   := NULL;
                        ln_err_flg        := 0;
--
                        -- 組織,会社,倉庫の取得カーソルオープン
                        OPEN xxcmn_locations_cur(
                                  move_target_tbl(gn_rec_idx).shipped_locat_id    -- 出庫元
                                 ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- 入庫先
--
                        <<xxcmn_locations_cur_loop>>
                        LOOP
                          FETCH xxcmn_locations_cur
                          INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                               ,lv_from_co_code         -- 会社コード(出庫用)
                               ,lv_from_whse_code       -- 倉庫コード(出庫用)
                               ,lv_to_orgn_code         -- 組織コード(入庫用)
                               ,lv_to_co_code           -- 会社コード(入庫用)
                               ,lv_to_whse_code         -- 倉庫コード(入庫用)
                               ;
                          EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                        END LOOP xxcmn_locations_cur_loop;
--
                        -- カーソルクローズ
                        CLOSE xxcmn_locations_cur;
--
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN                             -- データ取得エラー
                          -- エラーフラグ
                          ln_err_flg  := 1;
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- カーソルクローズ
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- エラーメッセージ内容
                          lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- データ取得エラー
                                                                gv_c_tkn_msg,     -- トークンMSG
                                                                lv_err_msg_value  -- トークン値
                                                                );
                          -- エラー内容格納
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- エラー移動番号PLSQL表に格納
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                        WHEN TOO_MANY_ROWS THEN                             -- データ取得エラー
                          -- エラーフラグ
                          ln_err_flg  := 1;
--
                          IF (xxcmn_locations_cur%ISOPEN) THEN
                            -- カーソルクローズ
                            CLOSE xxcmn_locations_cur;
                          END IF;
                          -- エラーメッセージ内容
                          lv_err_msg_value
                                := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                gv_c_msg_57a_006, -- データ取得エラー
                                                                gv_c_tkn_msg,     -- トークンMSG
                                                                lv_err_msg_value  -- トークン値
                                                                );
                          -- エラー内容格納
                          out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                          -- エラー移動番号PLSQL表に格納
                          err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                          err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                      END;
--
                      -----------------------------------------------------------------
                      -- 組織、会社、倉庫情報が取得できた場合
                      IF (ln_err_flg = 0) THEN  -- (R)
--
                        -- trni実績登録用レコードにデータを格納
                        trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                        trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元保管倉庫
                        trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                        trni_api_rec_tbl(ln_idx_trni).co_code    := lv_from_co_code;
                        trni_api_rec_tbl(ln_idx_trni).orgn_code  := lv_from_orgn_code;
                        trni_api_rec_tbl(ln_idx_trni).trans_date := move_target_tbl(gn_rec_idx).actual_ship_date; -- 出庫実績日
                        trni_api_rec_tbl(ln_idx_trni).attribute1 := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- インクリメント
                        ln_idx_trni := ln_idx_trni + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【36】trni実績  格納End');
                      END IF;  -- (R)
--
                    END IF;  -- (Q)
--
                  -- 2008/4/14 modify start
                  --================================================================
                  -- 実績(cmp)の数量と実績訂正(cmp_a)の数量が同じ場合
                  -- 赤作らない 黒だけ作る
                  --================================================================
                  --  ELSIF (ABS(ln_out_cmp_trans_qty) = ABS(ln_out_cmp_a_trans_qty))   -- 出庫数
                  --    AND (ABS(ln_in_cmp_trans_qty)  = ABS(ln_in_cmp_a_trans_qty))    -- 入庫数
                  --  THEN
--
                  ELSIF (TRUNC(ld_out_trans_date) = TRUNC(ld_a_out_trans_date))  -- 出庫日 実績と実績訂正
                  AND (TRUNC(ld_in_trans_date)  = TRUNC(ld_a_in_trans_date))  -- 入庫日 実績と実績訂正
                  THEN  -- (O)
                    --for debug
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'【37】実績と実績訂正の実績日同じ');
--
--2008/12/13 Y.Kawano Del Start
--2008/12/11 Y.Kawano Add Start
--                    ------------------------------------------------------------------
--                    -- 実績(cmp)の数量が0でない場合
--                    -- 赤作る
--                    ------------------------------------------------------------------
--                    IF ( ABS(ln_out_cmp_trans_qty) <> 0 ) THEN
--
--                      -- for debug
--                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【32】実績(cmp)の数量が0でない');
--                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【33】実績訂正格納 Start');
--
--                      -- 実績訂正作成情報格納
--                      -- 在庫数量API実行対象レコードにデータを格納 出庫データ
--                      adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
--                      adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
--                      adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
--                      adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
--                      adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
--                      adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
--                      adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
--                      adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
--                      adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
--                      adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
--                      adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
--                      adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
--                      -- インクリメント
--                      ln_idx_adji := ln_idx_adji + 1;
--
--                      -- for debug
--                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【33】実績訂正格納 End');
--
--                    END IF;
--2008/12/11 Y.Kawano Add End
--2008/12/13 Y.Kawano Del End
--
                    IF (ABS(ln_out_cmp_trans_qty) = ABS(ln_out_cmp_a_trans_qty))   -- 出庫数
                    AND (ABS(ln_in_cmp_trans_qty) = ABS(ln_in_cmp_a_trans_qty))    -- 入庫数
                    THEN  -- (S)
--
-- 2009/02/04 Y.Kawano Add Start #1142
                      ------------------------------------------------------------------
                      -- アドオンの実績数量と訂正前数量が異なる場合
                      -- 赤作る
                      ------------------------------------------------------------------
                      IF  ( (move_target_tbl(gn_rec_idx).lot_out_actual_quantity
                                                      <> move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity)
                        AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity
                                                      <> move_target_tbl(gn_rec_idx).lot_in_bf_act_quantity)
                        AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity <> 0)
                        AND (move_target_tbl(gn_rec_idx).lot_out_bf_act_quantity <> 0)
                          )
                      THEN
--
                       --for debug
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'【38】アドオンの実績数量と訂正前数量が異なる 赤作る');
--
                        -- 実績訂正作成情報格納
                        -- 在庫数量API実行対象レコードにデータを格納 出庫データ
                        adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                        adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                        adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- インクリメント
                        ln_idx_adji := ln_idx_adji + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【38】赤作る END');
--
                      END IF;
-- 2009/02/04 Y.Kawano Add End   #1142
--
--2008/12/13 Y.Kawano Upd Start
--                      NULL;
                      ------------------------------------------------------------------
                      -- 黒情報
                      -- 移動ロット詳細の数量が0の場合(実績登録しない)
                      IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  -- (T)
                        -- 何もしない
                        NULL;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【40】ロット詳細の数量が0');
--
                      ------------------------------------------------------------------
                      -- 移動ロット詳細の数量が0以外の場合(実績登録する)
                      ELSE  -- (T)
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【41】ロット詳細の数量が0じゃない');
--
                        ------------------------------------------------------------------
                        -- 実績(cmp)の数量が0の場合は前回0実績計上されているからデータなし
                        -- 倉庫組織会社情報がないため取得する
                        ------------------------------------------------------------------
                        IF (ln_out_cmp_trans_qty = 0) THEN  -- (U)
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【42】ln_out_cmp_trans_qty = 0');
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【43】組織情報取得 Start');
--
                          BEGIN
                            -- 変数初期化
                            lv_from_orgn_code := NULL;
                            lv_from_co_code   := NULL;
                            lv_from_whse_code := NULL;
                            lv_to_orgn_code   := NULL;
                            lv_to_co_code     := NULL;
                            lv_to_whse_code   := NULL;
                            ln_err_flg        := 0;
--
                            -- 組織,会社,倉庫の取得カーソルオープン
                            OPEN xxcmn_locations_cur(
                                      move_target_tbl(gn_rec_idx).shipped_locat_id    -- 出庫元
                                     ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- 入庫先
--
                            <<xxcmn_locations_cur_loop>>
                            LOOP
                              FETCH xxcmn_locations_cur
                              INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                                   ,lv_from_co_code         -- 会社コード(出庫用)
                                   ,lv_from_whse_code       -- 倉庫コード(出庫用)
                                   ,lv_to_orgn_code         -- 組織コード(入庫用)
                                   ,lv_to_co_code           -- 会社コード(入庫用)
                                   ,lv_to_whse_code         -- 倉庫コード(入庫用)
                                   ;
                              EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                            END LOOP xxcmn_locations_cur_loop;
--
                            -- カーソルクローズ
                            CLOSE xxcmn_locations_cur;
--
                          EXCEPTION
                            WHEN NO_DATA_FOUND THEN                             -- データ取得エラー
                              -- エラーフラグ
                              ln_err_flg  := 1;
                              IF (xxcmn_locations_cur%ISOPEN) THEN
                                -- カーソルクローズ
                                CLOSE xxcmn_locations_cur;
                              END IF;
                              -- エラーメッセージ内容
                              lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                              lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                    gv_c_msg_57a_006, -- データ取得エラー
                                                                    gv_c_tkn_msg,     -- トークンMSG
                                                                    lv_err_msg_value  -- トークン値
                                                                    );
                              -- エラー内容格納
                              out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                              -- エラー移動番号PLSQL表に格納
                              err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                              err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                            WHEN TOO_MANY_ROWS THEN                             -- データ取得エラー
                              -- エラーフラグ
                              ln_err_flg  := 1;
--
                              IF (xxcmn_locations_cur%ISOPEN) THEN
                                -- カーソルクローズ
                                CLOSE xxcmn_locations_cur;
                              END IF;
                              -- エラーメッセージ内容
                              lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                              lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                    gv_c_msg_57a_006, -- データ取得エラー
                                                                    gv_c_tkn_msg,     -- トークンMSG
                                                                    lv_err_msg_value  -- トークン値
                                                                    );
                              -- エラー内容格納
                              out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                              -- エラー移動番号PLSQL表に格納
                              err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                              err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                          END;
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【44】組織情報取得 End');
--
                          -----------------------------------------------------------------
                          -- 組織、会社、倉庫情報が取得できた場合
                          IF (ln_err_flg = 0) THEN  -- (V)
--
                            -- for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【45】trni実績格納 START');
--
                            -- trni実績登録用レコードにデータを格納
                            trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                            trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                            trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                            trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                            trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                            trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                            trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                            trni_api_rec_tbl(ln_idx_trni).co_code        := lv_from_co_code;
                            trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_from_orgn_code;
                            trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- 出庫実績日
                            trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                            -- インクリメント
                            ln_idx_trni := ln_idx_trni + 1;
--
                            --for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【46】trni実績格納 End');
--
                          END IF;  -- (V)
--
                        -----------------------------------------------------
                        -- 実績(cmp)の数量が0でない場合
                        -- 前回実績計上されているから倉庫組織会社情報がある
                        -----------------------------------------------------
                        ELSE  -- (U)
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【45】trni実績格納するだけ Start');
--
                          -- trni実績登録用レコードにデータを格納
                          trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                          trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                          trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元保管倉庫
                          trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                          trni_api_rec_tbl(ln_idx_trni).co_code        := lv_out_co_code;
                          trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_out_orgn_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- 出庫実績日
                          trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- インクリメント
                          ln_idx_trni := ln_idx_trni + 1;
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【46】trni実績格納するだけ End');
--
                        END IF;  -- (U)
--
                      END IF;  -- (T)
--
--                      END IF;
--2008/12/13 Y.Kawano Upd End
--
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【38】実績と実績訂正の数量も同じ');
                  -- 黒数量と赤数量が違う場合
                    ELSE  -- (S)
                    -- 2008/04/14 modify end
                      -- for debug
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'【39】実績と実績訂正の数量が違う');
--
--2008/12/13 Y.Kawano Add Start
                      ------------------------------------------------------------------
                      -- 実績(cmp)の数量が0でない場合
                      -- 赤作る
                      ------------------------------------------------------------------
                      IF ( ABS(ln_out_cmp_trans_qty) <> 0 ) THEN  -- (W)
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【32】実績(cmp)の数量が0でない');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【33】実績訂正格納 Start');
--
                        -- 実績訂正作成情報格納
                        -- 在庫数量API実行対象レコードにデータを格納 出庫データ
                        adji_data_rec_tbl(ln_idx_adji).item_no        := move_target_tbl(gn_rec_idx).item_code;
                        adji_data_rec_tbl(ln_idx_adji).from_whse_code := lv_from_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).to_whse_code   := lv_to_whse_code;
                        adji_data_rec_tbl(ln_idx_adji).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                        adji_data_rec_tbl(ln_idx_adji).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_out  := ABS(ln_out_cmp_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).trans_qty_in   := ABS(ln_in_cmp_trans_qty);
                        adji_data_rec_tbl(ln_idx_adji).from_co_code   := lv_out_co_code;
                        adji_data_rec_tbl(ln_idx_adji).to_co_code     := lv_in_co_code;
                        adji_data_rec_tbl(ln_idx_adji).from_orgn_code := lv_out_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).to_orgn_code   := lv_in_orgn_code;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_out := ld_out_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).trans_date_in  := ld_in_trans_date;
                        adji_data_rec_tbl(ln_idx_adji).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                        -- インクリメント
                        ln_idx_adji := ln_idx_adji + 1;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【33】実績訂正格納 End');
--
                      END IF;  -- (W)
--2008/12/13 Y.Kawano Add End
--
                      ------------------------------------------------------------------
                      -- 黒情報
                      -- 移動ロット詳細の数量が0の場合(実績登録しない)
                      IF (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0) THEN  -- (X)
                        -- 何もしない
                        NULL;
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【40】ロット詳細の数量が0');
--
                      ------------------------------------------------------------------
                      -- 移動ロット詳細の数量が0以外の場合(実績登録する)
                      ELSE  -- (X)
--
                        -- for debug
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'【41】ロット詳細の数量が0じゃない');
--
                        ------------------------------------------------------------------
                        -- 実績(cmp)の数量が0の場合は前回0実績計上されているからデータなし
                        -- 倉庫組織会社情報がないため取得する
                        ------------------------------------------------------------------
                        IF (ln_out_cmp_trans_qty = 0) THEN  -- (Y)
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【42】ln_out_cmp_trans_qty = 0');
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【43】組織情報取得 Start');
--
                          BEGIN
                            -- 変数初期化
                            lv_from_orgn_code := NULL;
                            lv_from_co_code   := NULL;
                            lv_from_whse_code := NULL;
                            lv_to_orgn_code   := NULL;
                            lv_to_co_code     := NULL;
                            lv_to_whse_code   := NULL;
                            ln_err_flg        := 0;
--
                            -- 組織,会社,倉庫の取得カーソルオープン
                            OPEN xxcmn_locations_cur(
                                      move_target_tbl(gn_rec_idx).shipped_locat_id    -- 出庫元
                                     ,move_target_tbl(gn_rec_idx).ship_to_locat_id ); -- 入庫先
--
                            <<xxcmn_locations_cur_loop>>
                            LOOP
                              FETCH xxcmn_locations_cur
                              INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                                   ,lv_from_co_code         -- 会社コード(出庫用)
                                   ,lv_from_whse_code       -- 倉庫コード(出庫用)
                                   ,lv_to_orgn_code         -- 組織コード(入庫用)
                                   ,lv_to_co_code           -- 会社コード(入庫用)
                                   ,lv_to_whse_code         -- 倉庫コード(入庫用)
                                   ;
                              EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
                            END LOOP xxcmn_locations_cur_loop;
--
                            -- カーソルクローズ
                            CLOSE xxcmn_locations_cur;
--
                          EXCEPTION
                            WHEN NO_DATA_FOUND THEN                             -- データ取得エラー
                              -- エラーフラグ
                              ln_err_flg  := 1;
                              IF (xxcmn_locations_cur%ISOPEN) THEN
                                -- カーソルクローズ
                                CLOSE xxcmn_locations_cur;
                              END IF;
                              -- エラーメッセージ内容
                              lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                              lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                    gv_c_msg_57a_006, -- データ取得エラー
                                                                    gv_c_tkn_msg,     -- トークンMSG
                                                                    lv_err_msg_value  -- トークン値
                                                                    );
                              -- エラー内容格納
                              out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                              -- エラー移動番号PLSQL表に格納
                              err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                              err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                            WHEN TOO_MANY_ROWS THEN                             -- データ取得エラー
                              -- エラーフラグ
                              ln_err_flg  := 1;
--
                              IF (xxcmn_locations_cur%ISOPEN) THEN
                                -- カーソルクローズ
                                CLOSE xxcmn_locations_cur;
                              END IF;
                              -- エラーメッセージ内容
                              lv_err_msg_value
                                    := gv_c_no_data_msg|| move_target_tbl(gn_rec_idx).mov_num;
--
                              lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                                    gv_c_msg_57a_006, -- データ取得エラー
                                                                    gv_c_tkn_msg,     -- トークンMSG
                                                                    lv_err_msg_value  -- トークン値
                                                                    );
                              -- エラー内容格納
                              out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
                              -- エラー移動番号PLSQL表に格納
                              err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
                              err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
--
                          END;
--
                            -- for debug
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'【44】組織情報取得 End');
--
                          -----------------------------------------------------------------
                          -- 組織、会社、倉庫情報が取得できた場合
                          IF (ln_err_flg = 0) THEN  -- (Z)
--
                              -- for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'【45】trni実績格納 START');
--
                            -- trni実績登録用レコードにデータを格納
                            trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                            trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                            trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                            trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                            trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元
                            trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                            trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                            trni_api_rec_tbl(ln_idx_trni).co_code        := lv_from_co_code;
                            trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_from_orgn_code;
                            trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- 出庫実績日
                            trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                            -- インクリメント
                            ln_idx_trni := ln_idx_trni + 1;
--
                              --for debug
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'【46】trni実績格納 End');
--
                          END IF;  -- (Z)
--
                        -----------------------------------------------------
                        -- 実績(cmp)の数量が0でない場合
                        -- 前回実績計上されているから倉庫組織会社情報がある
                        -----------------------------------------------------
                        ELSE  -- (Y)
                          --for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【45】trni実績格納するだけ Start');
--
                          -- trni実績登録用レコードにデータを格納
                          trni_api_rec_tbl(ln_idx_trni).item_no        := move_target_tbl(gn_rec_idx).item_code;
                          trni_api_rec_tbl(ln_idx_trni).from_whse_code := lv_from_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).to_whse_code   := lv_to_whse_code;
                          trni_api_rec_tbl(ln_idx_trni).lot_no         := move_target_tbl(gn_rec_idx).lot_no;
                          trni_api_rec_tbl(ln_idx_trni).from_location  := move_target_tbl(gn_rec_idx).shipped_locat_code; -- 出庫元保管倉庫
                          trni_api_rec_tbl(ln_idx_trni).to_location    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_qty      := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
                          trni_api_rec_tbl(ln_idx_trni).co_code        := lv_out_co_code;
                          trni_api_rec_tbl(ln_idx_trni).orgn_code      := lv_out_orgn_code;
                          trni_api_rec_tbl(ln_idx_trni).trans_date     := move_target_tbl(gn_rec_idx).actual_ship_date; -- 出庫実績日
                          trni_api_rec_tbl(ln_idx_trni).attribute1     := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
--
                          -- インクリメント
                          ln_idx_trni := ln_idx_trni + 1;
--
                          -- for debug
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'【46】trni実績格納するだけ End');
--
                        END IF;  -- (Y)
--
                      END IF;  -- (X)
--
                    END IF;  -- (S)
--
                  END IF;  -- (O)
--
                END IF;  -- (N)
--
--
-- 2008/12/16 Y.Kawano Del Start
--                END IF;
-- 2008/12/16 Y.Kawano Del End
--
--
-- add start 1.9
              END IF;  -- (B)
-- add end 1.9
--
            END IF;  -- (A)
            -- 2008/04/08 Modify End
            ---------------------------------------------------------
          END IF;  --(typeif)  -- 積送ありなしの分岐
          --
--2008/12/11 Y.Kawano Add Start
        END IF;      -- 実績訂正前後数量0条件分岐
--2008/12/11 Y.Kawano Add End
--
      /*****************************************************/
      -- 実績計上済フラグ = OFF の場合
      /*****************************************************/
      ELSIF ( move_target_tbl(gn_rec_idx).comp_actual_flg = gv_c_ynkbn_n ) THEN
--
        -- for debug
        FND_FILE.PUT_LINE(FND_FILE.LOG,'【1】実績計上済フラグ = OFF Start');
--
        -- 出庫と入庫で移動実績数量が同数が前提のため出庫数のみで判断
        -- 移動情報の数量が0の場合(実績登録しない)
-- 2009/02/24 v1.21 UPDATE START
--        IF ( move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0 ) THEN
        IF (
             ( move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0 )
             OR
             (
               (move_target_tbl(gn_rec_idx).lot_out_actual_quantity = 0)
                 AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity IS NULL)
             )
             OR
             (
               (move_target_tbl(gn_rec_idx).lot_out_actual_quantity IS NULL)
                 AND (move_target_tbl(gn_rec_idx).lot_in_actual_quantity = 0)
             )
           ) THEN
-- 2009/02/24 v1.21 UPDATE END
          -- 何もしない
          NULL;
--
        -- 移動情報の数量が0でない場合(実績登録対象)
        ELSE
--
          ln_err_flg := 0;
--
          BEGIN
            -- 組織,会社,倉庫の取得カーソルオープン
            OPEN xxcmn_locations_cur(
                            move_target_tbl(gn_rec_idx).shipped_locat_id     -- 出庫元
                           ,move_target_tbl(gn_rec_idx).ship_to_locat_id );  -- 入庫先
            <<xxcmn_locations_cur_loop>>
            LOOP
              FETCH xxcmn_locations_cur
              INTO  lv_from_orgn_code       -- 組織コード(出庫用)
                   ,lv_from_co_code         -- 会社コード(出庫用)
                   ,lv_from_whse_code       -- 倉庫コード(出庫用)
                   ,lv_to_orgn_code         -- 組織コード(入庫用)
                   ,lv_to_co_code           -- 会社コード(入庫用)
                   ,lv_to_whse_code         -- 倉庫コード(入庫用)
                   ;
              EXIT WHEN xxcmn_locations_cur%NOTFOUND;
--
            END LOOP xxcmn_locations_cur_loop;
            -- カーソルクローズ
            CLOSE xxcmn_locations_cur;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN                             --*** データ取得エラー ***
              ln_err_flg   := 1;
              -- カーソルクローズ
              IF (xxcmn_locations_cur%ISOPEN) THEN
                CLOSE xxcmn_locations_cur;
              END IF;
              -- エラーメッセージ内容
              lv_err_msg_value
                    := gv_c_no_data_msg || move_target_tbl(gn_rec_idx).mov_num;
--
              lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                    gv_c_msg_57a_006, -- データ取得エラー
                                                    gv_c_tkn_msg,     -- トークンMSG
                                                    lv_err_msg_value  -- トークン値
                                                    );
              -- エラー内容格納
              out_err_tbl2(gn_rec_idx).out_msg := lv_errmsg;
              -- エラー移動番号PLSQL表に格納
              err_mov_rec_tbl(gn_rec_idx).mov_hdr_id := move_target_tbl(gn_rec_idx).mov_hdr_id;
              err_mov_rec_tbl(gn_rec_idx).mov_num    := move_target_tbl(gn_rec_idx).mov_num;
              -- スキップ件数
              gn_warn_cnt  := gn_warn_cnt + 1;
          END;
--
          -- データ取得できた場合
          IF (ln_err_flg = 0) THEN
            -- 積送ありの場合
            IF ( move_target_tbl(gn_rec_idx).mov_type = gv_c_move_type_y ) THEN
--
              -- 実績登録用レコードにデータを格納
              move_api_rec_tbl(ln_idx_move).orgn_code                      -- 組織コード
                                  := lv_from_orgn_code;
              move_api_rec_tbl(ln_idx_move).item_no                        -- 品目コード
                                  := move_target_tbl(gn_rec_idx).item_code;
              move_api_rec_tbl(ln_idx_move).lot_no                         -- ロットNo
                                  := move_target_tbl(gn_rec_idx).lot_no;
              move_api_rec_tbl(ln_idx_move).source_warehouse               -- 出庫もと倉庫
                                  := lv_from_whse_code;
              move_api_rec_tbl(ln_idx_move).source_location                -- 出庫元保管倉庫
                                  := move_target_tbl(gn_rec_idx).shipped_locat_code;
              move_api_rec_tbl(ln_idx_move).target_warehouse               -- 入庫先倉庫
                                  := lv_to_whse_code;
              move_api_rec_tbl(ln_idx_move).target_location                -- 入庫先保管倉庫
                                  := move_target_tbl(gn_rec_idx).ship_to_locat_code;
-- 2008/12/25 Y.Kawano Upd Start #844
--                move_api_rec_tbl(ln_idx_move).scheduled_release_date         -- 出庫予定日
--                                    := move_target_tbl(gn_rec_idx).schedule_ship_date;
--                move_api_rec_tbl(ln_idx_move).scheduled_receive_date         -- 入庫予定日
--                                    := move_target_tbl(gn_rec_idx).schedule_arrival_date;
              move_api_rec_tbl(ln_idx_move).scheduled_release_date         -- 出庫予定日
                                  := move_target_tbl(gn_rec_idx).actual_ship_date;
              move_api_rec_tbl(ln_idx_move).scheduled_receive_date         -- 入庫予定日
                                  := move_target_tbl(gn_rec_idx).actual_arrival_date;
-- 2008/12/25 Y.Kawano Upd End   #844
              move_api_rec_tbl(ln_idx_move).actual_release_date            -- 出庫実績日
                                  := move_target_tbl(gn_rec_idx).actual_ship_date;
              move_api_rec_tbl(ln_idx_move).actual_receive_date            -- 入庫実績日
                                  := move_target_tbl(gn_rec_idx).actual_arrival_date;
              move_api_rec_tbl(ln_idx_move).release_quantity1              -- 数量
                                  := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
              move_api_rec_tbl(ln_idx_move).attribute1                     -- 移動明細ID
                              := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
              -- インクリメント
              ln_idx_move := ln_idx_move + 1;
--
            -- 積送なしの場合
            ELSIF ( move_target_tbl(gn_rec_idx).mov_type = gv_c_move_type_n ) THEN
--
                -- trni実績登録用レコードにデータを格納
              trni_api_rec_tbl(ln_idx_trni).item_no                        -- 品目コード
                                    := move_target_tbl(gn_rec_idx).item_code;
              trni_api_rec_tbl(ln_idx_trni).from_whse_code                 -- 出庫倉庫
                                    := lv_from_whse_code;
              trni_api_rec_tbl(ln_idx_trni).to_whse_code                   -- 入庫倉庫
                                    := lv_to_whse_code;
              trni_api_rec_tbl(ln_idx_trni).lot_no                         -- ロットNo
                                    := move_target_tbl(gn_rec_idx).lot_no;
              trni_api_rec_tbl(ln_idx_trni).from_location                  -- 出庫元保管倉庫
                                    := move_target_tbl(gn_rec_idx).shipped_locat_code;
              trni_api_rec_tbl(ln_idx_trni).to_location                    -- 入庫先保管倉庫
                                    := move_target_tbl(gn_rec_idx).ship_to_locat_code;
              trni_api_rec_tbl(ln_idx_trni).trans_qty                      -- 数量
                                    := move_target_tbl(gn_rec_idx).lot_out_actual_quantity;
              trni_api_rec_tbl(ln_idx_trni).co_code                        -- 会社コード
                                    := lv_from_co_code;
              trni_api_rec_tbl(ln_idx_trni).orgn_code                      -- 組織コード
                                   := lv_from_orgn_code;
              trni_api_rec_tbl(ln_idx_trni).trans_date                     -- 出庫実績日
                                   := move_target_tbl(gn_rec_idx).actual_ship_date;
              trni_api_rec_tbl(ln_idx_trni).attribute1
                                   := to_char(move_target_tbl(gn_rec_idx).mov_line_id);
              -- インクリメント
              ln_idx_trni := ln_idx_trni + 1;
--
            END IF;  -- 積送ありなし
--
          END IF;  -- データ取得できた場合
--
        END IF;    -- 数量の条件分岐
--
      END IF;      -- 実績フラグ条件分岐
--
    END LOOP rec_loop;
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
      IF (xxcmn_locations_cur%ISOPEN) THEN
        CLOSE xxcmn_locations_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (xxcmn_locations_cur%ISOPEN) THEN
        CLOSE xxcmn_locations_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (xxcmn_locations_cur%ISOPEN) THEN
        CLOSE xxcmn_locations_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : regist_adji_proc
   * Description      : 実績訂正全赤情報登録 (A-6)
   ***********************************************************************************/
  PROCEDURE regist_adji_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_adji_proc'; -- プログラム名
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
    l_api_version_number  NUMBER      := 3.0;
    l_init_msg_list       VARCHAR2(1) := FND_API.G_FALSE;
    l_commit              VARCHAR2(1) := FND_API.G_FALSE;
    l_validation_level    NUMBER      := FND_API.G_VALID_LEVEL_FULL;
    l_return_status       VARCHAR2(1);
    l_msg_count           NUMBER;
    l_msg_data            VARCHAR2(2000);
    l_data                VARCHAR2(2000);
    l_qty_rec             GMIGAPI.qty_rec_typ;
    l_ic_jrnl_mst_row     ic_jrnl_mst%ROWTYPE;
    l_ic_adjs_jnl_row1    ic_adjs_jnl%ROWTYPE;
    l_ic_adjs_jnl_row2    ic_adjs_jnl%ROWTYPE;
    l_setup_return_sts    BOOLEAN;
-- add start 1.3
    l_loop_cnt            NUMBER;
    l_dummy_cnt           NUMBER;
-- add end 1.3
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ***************************************
    -- 対象データループ
    -- ***************************************
    IF adji_data_rec_tbl.exists(1) THEN
      <<adji_loop>>
      FOR gn_rec_idx IN 1 .. adji_data_rec_tbl.COUNT LOOP
--
        ------------------------
        -- 出庫情報
        ------------------------
        -- 作成する在庫トランザクションデータ
        l_qty_rec.trans_type     := 2;      --2:調整即時
        l_qty_rec.item_no        := adji_data_rec_tbl(gn_rec_idx).item_no;
        l_qty_rec.journal_no     := NULL;
        l_qty_rec.from_whse_code := adji_data_rec_tbl(gn_rec_idx).from_whse_code;
        l_qty_rec.to_whse_code   := adji_data_rec_tbl(gn_rec_idx).to_whse_code;
        l_qty_rec.lot_no         := adji_data_rec_tbl(gn_rec_idx).lot_no;
        l_qty_rec.from_location  := adji_data_rec_tbl(gn_rec_idx).from_location;
        l_qty_rec.to_location    := adji_data_rec_tbl(gn_rec_idx).to_location;
        l_qty_rec.trans_qty      := adji_data_rec_tbl(gn_rec_idx).trans_qty_out;
        l_qty_rec.co_code        := adji_data_rec_tbl(gn_rec_idx).from_co_code;
        l_qty_rec.orgn_code      := adji_data_rec_tbl(gn_rec_idx).from_orgn_code;
        l_qty_rec.trans_date     := adji_data_rec_tbl(gn_rec_idx).trans_date_out;
        l_qty_rec.reason_code    := gv_reason_code_cor;
        l_qty_rec.user_name      := gv_user_name;
        l_qty_rec.attribute1     := adji_data_rec_tbl(gn_rec_idx).attribute1;
--
        -- ***************************************
        -- 検証用ログ(2008/12/10)
        -- ***************************************
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'INV50A(A-6)-1::' );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_type:'     || l_qty_rec.trans_type     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' item_no:'        || l_qty_rec.item_no        );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' journal_no:'     || l_qty_rec.journal_no     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' from_whse_code:' || l_qty_rec.from_whse_code );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' to_whse_code:'   || l_qty_rec.to_location    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' lot_no:'         || l_qty_rec.lot_no         );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' from_location:'  || l_qty_rec.from_location  );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' to_location:'    || l_qty_rec.to_location    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_qty:'      || l_qty_rec.trans_qty      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' co_code:'        || l_qty_rec.co_code        );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' orgn_code:'      || l_qty_rec.orgn_code      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_date:'     || l_qty_rec.trans_date     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' reason_code:'    || l_qty_rec.reason_code    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' user_name:'      || l_qty_rec.user_name      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' attribute1:'     || l_qty_rec.attribute1     );
--
        -- API実行 在庫トランザクションの作成
        GMIPAPI.INVENTORY_POSTING(
                  p_api_version      =>l_api_version_number,
                  p_init_msg_list    =>l_init_msg_list,
                  p_commit           =>l_commit,
                  p_validation_level =>l_validation_level,
                  p_qty_rec          =>l_qty_rec,
                  x_ic_jrnl_mst_row  =>l_ic_jrnl_mst_row,
                  x_ic_adjs_jnl_row1 =>l_ic_adjs_jnl_row1,
                  x_ic_adjs_jnl_row2 =>l_ic_adjs_jnl_row2,
                  x_return_status    =>l_return_status,
                  x_msg_count        =>l_msg_count,
                  x_msg_data         =>l_msg_data
                  );
--
        -- API実行結果エラーの場合
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
-- add start 1.3
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPAPI.INVENTORY_POSTING 実行結果 = '||l_return_status);
          -- エラー内容ログ出力
          IF l_msg_count > 0 THEN
            l_loop_cnt := 1;
            LOOP
              FND_MSG_PUB.Get(
                  p_msg_index     => l_loop_cnt,
                  p_data          => l_msg_data,
                  p_encoded       => FND_API.G_FALSE,
                  p_msg_index_out => l_dummy_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'エラーメッセージ ='||l_msg_data);
                  l_loop_cnt := l_loop_cnt+1;
              EXIT WHEN l_loop_cnt > l_msg_count;
            END LOOP;
          END IF;
-- add end 1.3
          -- エラーメッセージ
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- カレンダクローズメッセージ
                                                gv_c_tkn_api,      -- トークンAPI_NAME
                                                gv_c_tkn_api_val_a -- トークン値
                                                );
          RAISE global_api_expt;
        END IF;
--
        ------------------------
        -- 入庫情報
        ------------------------
        -- 作成する在庫トランザクションデータ
        l_qty_rec.trans_type     := 2;      --2:調整即時
        l_qty_rec.item_no        := adji_data_rec_tbl(gn_rec_idx).item_no;
        l_qty_rec.journal_no     := NULL;
        l_qty_rec.from_whse_code := adji_data_rec_tbl(gn_rec_idx).to_whse_code;
        l_qty_rec.to_whse_code   := adji_data_rec_tbl(gn_rec_idx).from_whse_code;
        l_qty_rec.lot_no         := adji_data_rec_tbl(gn_rec_idx).lot_no;
        l_qty_rec.from_location  := adji_data_rec_tbl(gn_rec_idx).to_location;
        l_qty_rec.to_location    := adji_data_rec_tbl(gn_rec_idx).from_location;
        l_qty_rec.trans_qty      := (adji_data_rec_tbl(gn_rec_idx).trans_qty_in * -1);
        l_qty_rec.co_code        := adji_data_rec_tbl(gn_rec_idx).to_co_code;
        l_qty_rec.orgn_code      := adji_data_rec_tbl(gn_rec_idx).to_orgn_code;
        l_qty_rec.trans_date     := adji_data_rec_tbl(gn_rec_idx).trans_date_in;
        l_qty_rec.reason_code    := gv_reason_code_cor;
        l_qty_rec.user_name      := gv_user_name;
        l_qty_rec.attribute1     := adji_data_rec_tbl(gn_rec_idx).attribute1;
--
        -- ***************************************
        -- 検証用ログ(2008/12/10)
        -- ***************************************
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'INV50A(A-6)-2::' );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_type:'     || l_qty_rec.trans_type     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' item_no:'        || l_qty_rec.item_no        );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' journal_no:'     || l_qty_rec.journal_no     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' from_whse_code:' || l_qty_rec.from_whse_code );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' to_whse_code:'   || l_qty_rec.to_location    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' lot_no:'         || l_qty_rec.lot_no         );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' from_location:'  || l_qty_rec.from_location  );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' to_location:'    || l_qty_rec.to_location    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_qty:'      || l_qty_rec.trans_qty      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' co_code:'        || l_qty_rec.co_code        );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' orgn_code:'      || l_qty_rec.orgn_code      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' trans_date:'     || l_qty_rec.trans_date     );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' reason_code:'    || l_qty_rec.reason_code    );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' user_name:'      || l_qty_rec.user_name      );
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' attribute1:'     || l_qty_rec.attribute1     );
--
        -- API実行 在庫トランザクションの作成
        GMIPAPI.INVENTORY_POSTING(
                  p_api_version      =>l_api_version_number,
                  p_init_msg_list    =>l_init_msg_list,
                  p_commit           =>l_commit,
                  p_validation_level =>l_validation_level,
                  p_qty_rec          =>l_qty_rec,
                  x_ic_jrnl_mst_row  =>l_ic_jrnl_mst_row,
                  x_ic_adjs_jnl_row1 =>l_ic_adjs_jnl_row1,
                  x_ic_adjs_jnl_row2 =>l_ic_adjs_jnl_row2,
                  x_return_status    =>l_return_status,
                  x_msg_count        =>l_msg_count,
                  x_msg_data         =>l_msg_data
                  );
--
        -- API実行結果エラーの場合
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
-- add start 1.3
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPAPI.INVENTORY_POSTING 実行結果 = '||l_return_status);
          -- エラー内容ログ出力
          IF l_msg_count > 0 THEN
            l_loop_cnt := 1;
            LOOP
              FND_MSG_PUB.Get(
                  p_msg_index     => l_loop_cnt,
                  p_data          => l_msg_data,
                  p_encoded       => FND_API.G_FALSE,
                  p_msg_index_out => l_dummy_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'エラーメッセージ ='||l_msg_data);
                  l_loop_cnt := l_loop_cnt+1;
              EXIT WHEN l_loop_cnt > l_msg_count;
            END LOOP;
          END IF;
-- add end 1.3
          -- エラーメッセージ
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- カレンダクローズメッセージ
                                                gv_c_tkn_api,      -- トークンAPI_NAME
                                                gv_c_tkn_api_val_a -- トークン値
                                                );
          RAISE global_api_expt;
        END IF;
--
      END LOOP adji_loop;
    END IF;
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
  END regist_adji_proc;
--
  /**********************************************************************************
   * Procedure Name   : regist_xfer_proc
   * Description      : 積送あり実績登録 (A-5)
   ***********************************************************************************/
  PROCEDURE regist_xfer_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_xfer_proc'; -- プログラム名
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
    l_api_version_number  CONSTANT NUMBER := 1.0;
    l_init_msg_list       VARCHAR2(1)     := FND_API.G_FALSE;
    l_commit              VARCHAR2(1)     := FND_API.G_FALSE;
    l_validation_level    NUMBER          := FND_API.G_VALID_LEVEL_FULL;
    l_return_status       VARCHAR2(2);
    l_msg_count           NUMBER;
    l_msg_data            VARCHAR2(2000);
    l_loop_cnt            NUMBER;
    l_dummy_cnt           NUMBER;
--
    l_xfer_rec            GMIGXFR.TYPE_XFER_REC;
    l_ic_xfer_mst_row     IC_XFER_MST%ROWTYPE;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    IF move_api_rec_tbl.exists(1) THEN
--
      <<xfer_loop>>
      FOR gn_rec_idx IN 1 .. move_api_rec_tbl.COUNT LOOP
--
        -----------------------------------
        -- Insert
        -----------------------------------
        -- 作成する在庫トランザクションデータ
        l_xfer_rec.transfer_action        := 1;           --1:Insert
        l_xfer_rec.transfer_no            := NULL;
        l_xfer_rec.transfer_batch         := NULL;
        l_xfer_rec.orgn_code              := move_api_rec_tbl(gn_rec_idx).orgn_code;
        l_xfer_rec.item_no                := move_api_rec_tbl(gn_rec_idx).item_no;
        l_xfer_rec.lot_no                 := move_api_rec_tbl(gn_rec_idx).lot_no;
        l_xfer_rec.sublot_no              := NULL;
        l_xfer_rec.source_warehouse       := move_api_rec_tbl(gn_rec_idx).source_warehouse;
        l_xfer_rec.source_location        := move_api_rec_tbl(gn_rec_idx).source_location;
        l_xfer_rec.target_warehouse       := move_api_rec_tbl(gn_rec_idx).target_warehouse;
        l_xfer_rec.target_location        := move_api_rec_tbl(gn_rec_idx).target_location;
        l_xfer_rec.scheduled_release_date := move_api_rec_tbl(gn_rec_idx).scheduled_release_date;
        l_xfer_rec.scheduled_receive_date := move_api_rec_tbl(gn_rec_idx).scheduled_receive_date;
        l_xfer_rec.actual_release_date    := move_api_rec_tbl(gn_rec_idx).actual_release_date;
        l_xfer_rec.actual_receive_date    := move_api_rec_tbl(gn_rec_idx).actual_receive_date;
        l_xfer_rec.cancel_date            := NULL;
        l_xfer_rec.release_quantity1      := move_api_rec_tbl(gn_rec_idx).release_quantity1;
        l_xfer_rec.release_quantity2      := NULL;
        l_xfer_rec.reason_code            := gv_reason_code;         -- 移動実績
        l_xfer_rec.comments               := NULL;
        l_xfer_rec.attribute1             := move_api_rec_tbl(gn_rec_idx).attribute1;
--
--2008/09/26 Y.Kawano Mod Start
--        l_xfer_rec.user_name              := gv_user_name;
        l_xfer_rec.user_name              := gv_xfer_user_name;
--2008/09/26 Y.Kawano Mod End
--
        -----------------------------------
        -- API実行 Insert
        -----------------------------------
        GMIPXFR.INVENTORY_TRANSFER(
                    p_api_version      => l_api_version_number
                   ,p_init_msg_list    => l_init_msg_list
                   ,p_commit           => l_commit
                   ,p_validation_level => l_validation_level
                   ,p_xfer_rec         => l_xfer_rec
                   ,x_ic_xfer_mst_row  => l_ic_xfer_mst_row
                   ,x_return_status    => l_return_status
                   ,x_msg_count        => l_msg_count
                   ,x_msg_data         => l_msg_data
                   );
--
        -- API実行結果エラーの場合
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
-- mod start 1.3
--          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPAPI.INVENTORY_POSTING 実行結果 = '||l_return_status);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPXFR.INVENTORY_TRANSFER 実行結果 = '||l_return_status);
-- mod end 1.3
          -------------------------
          -- for debug
          IF l_msg_count > 0 THEN
           l_loop_cnt := 1;
           LOOP
             FND_MSG_PUB.Get(
                 p_msg_index     => l_loop_cnt,
                 p_data          => l_msg_data,
                 p_encoded       => FND_API.G_FALSE,
                 p_msg_index_out => l_dummy_cnt);
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'エラーメッセージ='||l_msg_data);
                 l_loop_cnt := l_loop_cnt+1;
             EXIT WHEN l_loop_cnt > l_msg_count;
           END LOOP;
          END IF;
          ----------------------
          -- エラーメッセージ
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- カレンダクローズメッセージ
                                                gv_c_tkn_api,      -- トークンAPI_NAME
                                                gv_c_tkn_api_val_x -- トークン値
                                                );
          RAISE global_api_expt;
        END IF;
--
        -----------------------------------
        -- Release
        -----------------------------------
        -- 作成する在庫トランザクションデータ
        l_xfer_rec.transfer_action             := 2;           --2:Release
        l_xfer_rec.transfer_no                 := l_ic_xfer_mst_row.transfer_no;
        l_xfer_rec.orgn_code                   := l_ic_xfer_mst_row.orgn_code;
        l_xfer_rec.reason_code                 := gv_reason_code;
--
--2008/09/26 Y.Kawano Mod Start
--        l_xfer_rec.user_name                   := gv_user_name;
        l_xfer_rec.user_name                   := gv_xfer_user_name;
--2008/09/26 Y.Kawano Mod End
--
        -----------------------------------
        -- API実行 Release
        -----------------------------------
        GMIPXFR.INVENTORY_TRANSFER(
                    p_api_version      => l_api_version_number
                   ,p_init_msg_list    => l_init_msg_list
                   ,p_commit           => l_commit
                   ,p_validation_level => l_validation_level
                   ,p_xfer_rec         => l_xfer_rec
                   ,x_ic_xfer_mst_row  => l_ic_xfer_mst_row
                   ,x_return_status    => l_return_status
                   ,x_msg_count        => l_msg_count
                   ,x_msg_data         => l_msg_data
                   );
--
        -- API実行結果エラーの場合
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
-- add start 1.3
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPXFR.INVENTORY_TRANSFER 実行結果 = '||l_return_status);
          -- エラー内容ログ出力
          IF l_msg_count > 0 THEN
            l_loop_cnt := 1;
            LOOP
              FND_MSG_PUB.Get(
                  p_msg_index     => l_loop_cnt,
                  p_data          => l_msg_data,
                  p_encoded       => FND_API.G_FALSE,
                  p_msg_index_out => l_dummy_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'エラーメッセージ ='||l_msg_data);
                  l_loop_cnt := l_loop_cnt+1;
              EXIT WHEN l_loop_cnt > l_msg_count;
            END LOOP;
          END IF;
-- add end 1.3
          -- エラーメッセージ
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- カレンダクローズメッセージ
                                                gv_c_tkn_api,      -- トークンAPI_NAME
                                                gv_c_tkn_api_val_x -- トークン値
                                                );
          RAISE global_api_expt;
        END IF;
--
        -----------------------------------
        -- Receive
        -----------------------------------
        -- 作成する在庫トランザクションデータ
        l_xfer_rec.transfer_action             := 3;           --3:Receive
        l_xfer_rec.transfer_no                 := l_ic_xfer_mst_row.transfer_no;
        l_xfer_rec.orgn_code                   := l_ic_xfer_mst_row.orgn_code;
        l_xfer_rec.reason_code                 := gv_reason_code;
--
--2008/09/26 Y.Kawano Mod Start
--        l_xfer_rec.user_name                   := gv_user_name;
        l_xfer_rec.user_name                   := gv_xfer_user_name;
--2008/09/26 Y.Kawano Mod End
--
--
        -----------------------------------
        -- API実行 Receive
        -----------------------------------
        GMIPXFR.INVENTORY_TRANSFER(
                    p_api_version      => l_api_version_number
                   ,p_init_msg_list    => l_init_msg_list
                   ,p_commit           => l_commit
                   ,p_validation_level => l_validation_level
                   ,p_xfer_rec         => l_xfer_rec
                   ,x_ic_xfer_mst_row  => l_ic_xfer_mst_row
                   ,x_return_status    => l_return_status
                   ,x_msg_count        => l_msg_count
                   ,x_msg_data         => l_msg_data
                   );
--
        -- API実行結果エラーの場合
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
-- add start 1.3
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPXFR.INVENTORY_TRANSFER 実行結果 = '||l_return_status);
          -- エラー内容ログ出力
          IF l_msg_count > 0 THEN
            l_loop_cnt := 1;
            LOOP
              FND_MSG_PUB.Get(
                  p_msg_index     => l_loop_cnt,
                  p_data          => l_msg_data,
                  p_encoded       => FND_API.G_FALSE,
                  p_msg_index_out => l_dummy_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'エラーメッセージ ='||l_msg_data);
                  l_loop_cnt := l_loop_cnt+1;
              EXIT WHEN l_loop_cnt > l_msg_count;
            END LOOP;
          END IF;
-- add end 1.3
          -- エラーメッセージ
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- カレンダクローズメッセージ
                                                gv_c_tkn_api,      -- トークンAPI_NAME
                                                gv_c_tkn_api_val_x -- トークン値
                                                );
          RAISE global_api_expt;
        END IF;
--
      END LOOP xfer_loop;
    END IF;
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
  END regist_xfer_proc;
--
  /**********************************************************************************
   * Procedure Name   : regist_trni_proc
   * Description      : 積送なし実績登録 (A-8)
   ***********************************************************************************/
  PROCEDURE regist_trni_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_trni_proc'; -- プログラム名
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
    l_api_version_number  CONSTANT NUMBER   := 3.0;
    l_init_msg_list       VARCHAR2(1)       := FND_API.G_FALSE;
    l_commit              VARCHAR2(1)       := FND_API.G_FALSE;
    l_validation_level    NUMBER            := FND_API.G_VALID_LEVEL_FULL;
    l_return_status       VARCHAR2(1);
    l_msg_count           NUMBER;
    l_msg_data            VARCHAR2(2000);
    l_data                VARCHAR2(2000);
    l_qty_rec             GMIGAPI.qty_rec_typ;
    l_ic_jrnl_mst_row     ic_jrnl_mst%ROWTYPE;
    l_ic_adjs_jnl_row1    ic_adjs_jnl%ROWTYPE;
    l_ic_adjs_jnl_row2    ic_adjs_jnl%ROWTYPE;
    l_setup_return_sts    BOOLEAN;
    l_loop_cnt            NUMBER;
    l_dummy_cnt           NUMBER;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    IF trni_api_rec_tbl.exists(1) THEN
      <<trni_loop>>
      FOR gn_rec_idx IN 1 .. trni_api_rec_tbl.COUNT LOOP
--
        -------------------------------------
        -- 作成する在庫トランザクションデータ
        -------------------------------------
        l_qty_rec.trans_type     := 3;                                       --3:移動即時
        l_qty_rec.item_no        := trni_api_rec_tbl(gn_rec_idx).item_no;
        l_qty_rec.journal_no     := NULL;
        l_qty_rec.from_whse_code := trni_api_rec_tbl(gn_rec_idx).from_whse_code;
        l_qty_rec.to_whse_code   := trni_api_rec_tbl(gn_rec_idx).to_whse_code;
        l_qty_rec.lot_no         := trni_api_rec_tbl(gn_rec_idx).lot_no;
        l_qty_rec.sublot_no      := NULL;
        l_qty_rec.from_location  := trni_api_rec_tbl(gn_rec_idx).from_location;
        l_qty_rec.to_location    := trni_api_rec_tbl(gn_rec_idx).to_location;
        l_qty_rec.trans_qty      := trni_api_rec_tbl(gn_rec_idx).trans_qty;
        l_qty_rec.co_code        := trni_api_rec_tbl(gn_rec_idx).co_code;
        l_qty_rec.orgn_code      := trni_api_rec_tbl(gn_rec_idx).orgn_code;
        l_qty_rec.trans_date     := trni_api_rec_tbl(gn_rec_idx).trans_date;
        l_qty_rec.reason_code    := gv_reason_code;
        l_qty_rec.user_name      := gv_user_name;
        l_qty_rec.attribute1     := trni_api_rec_tbl(gn_rec_idx).attribute1;
--
        -------------------------------------
        -- API実行 在庫トランザクションの作成
        -------------------------------------
        GMIPAPI.INVENTORY_POSTING(
                  p_api_version      =>l_api_version_number,
                  p_init_msg_list    =>l_init_msg_list,
                  p_commit           =>l_commit,
                  p_validation_level =>l_validation_level,
                  p_qty_rec          =>l_qty_rec,
                  x_ic_jrnl_mst_row  =>l_ic_jrnl_mst_row,
                  x_ic_adjs_jnl_row1 =>l_ic_adjs_jnl_row1,
                  x_ic_adjs_jnl_row2 =>l_ic_adjs_jnl_row2,
                  x_return_status    =>l_return_status,
                  x_msg_count        =>l_msg_count,
                  x_msg_data         =>l_msg_data
                  );
--
        -- API実行結果エラーの場合
        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          ROLLBACK;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'GMIPAPI.INVENTORY_POSTING 実行結果 = '||l_return_status);
          -- エラー内容ログ出力
          IF l_msg_count > 0 THEN
            l_loop_cnt := 1;
            LOOP
              FND_MSG_PUB.Get(
                  p_msg_index     => l_loop_cnt,
                  p_data          => l_msg_data,
                  p_encoded       => FND_API.G_FALSE,
                  p_msg_index_out => l_dummy_cnt);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'エラーメッセージ ='||l_msg_data);
                  l_loop_cnt := l_loop_cnt+1;
              EXIT WHEN l_loop_cnt > l_msg_count;
            END LOOP;
          END IF;
--
          -- エラーメッセージ
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn_inv,
                                                gv_c_msg_57a_003,  -- カレンダクローズメッセージ
                                                gv_c_tkn_api,      -- トークンAPI_NAME
                                                gv_c_tkn_api_val_a -- トークン値
                                                );
          RAISE global_api_expt;
        END IF;
--
      END LOOP trni_loop;
    END IF;
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
  END regist_trni_proc;
--
  /**********************************************************************************
   * Procedure Name   : update_flg_proc
   * Description      : 実績計上済フラグ更新 (A-10,A-11)
   ***********************************************************************************/
  PROCEDURE update_flg_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_flg_proc'; -- プログラム名
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
    ln_idx   NUMBER := 1;
-- add start 1.3
    lt_pre_mov_hdr_id xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
    lt_pre_ng_flag    NUMBER;
-- add end 1.3
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    <<update_loop>>
    FOR gn_rec_idx IN 1 .. move_data_rec_tbl.COUNT LOOP
-- mod start 1.3
--      UPDATE XXINV_MOV_REQ_INSTR_HEADERS
--      SET    comp_actual_flg        = gv_c_ynkbn_y  -- 実績計上済フラグ=ON
--            ,correct_actual_flg     = gv_c_ynkbn_n  -- 実績訂正フラグ=OFF
--            ,last_updated_by        = gn_user_id
--            ,last_update_date       = gd_sysdate
--            ,last_update_login      = gn_login_id
--            ,request_id             = gn_conc_request_id
--            ,program_application_id = gn_prog_appl_id
--            ,program_id             = gn_conc_program_id
--            ,program_update_date    = gd_sysdate
--      WHERE mov_hdr_id        = move_data_rec_tbl(gn_rec_idx).mov_hdr_id;
--
      IF ((lt_pre_mov_hdr_id IS NULL AND move_data_rec_tbl(gn_rec_idx).ng_flag = 0)
        OR (lt_pre_mov_hdr_id <> move_data_rec_tbl(gn_rec_idx).mov_hdr_id AND move_data_rec_tbl(gn_rec_idx).ng_flag = 0)
        OR (lt_pre_mov_hdr_id = move_data_rec_tbl(gn_rec_idx).mov_hdr_id AND lt_pre_ng_flag = 0))THEN
--
        -- フラグ更新
        UPDATE XXINV_MOV_REQ_INSTR_HEADERS
        SET    comp_actual_flg        = gv_c_ynkbn_y  -- 実績計上済フラグ=ON
              ,correct_actual_flg     = gv_c_ynkbn_n  -- 実績訂正フラグ=OFF
              ,last_updated_by        = gn_user_id
              ,last_update_date       = gd_sysdate
              ,last_update_login      = gn_login_id
              ,request_id             = gn_conc_request_id
              ,program_application_id = gn_prog_appl_id
              ,program_id             = gn_conc_program_id
              ,program_update_date    = gd_sysdate
        WHERE mov_hdr_id        = move_data_rec_tbl(gn_rec_idx).mov_hdr_id;
--
-- 2010/03/02 M.Miyagawa Add Start E_本稼動_01612対応
        -- 実績計上済フラグ更新
        UPDATE XXINV_MOV_LOT_DETAILS xmld
        SET    xmld.actual_confirm_class   = gv_c_ynkbn_y
              ,xmld.last_updated_by        = gn_user_id
              ,xmld.last_update_date       = gd_sysdate
              ,xmld.last_update_login      = gn_login_id
              ,xmld.request_id             = gn_conc_request_id
              ,xmld.program_application_id = gn_prog_appl_id
              ,xmld.program_id             = gn_conc_program_id
              ,xmld.program_update_date    = gd_sysdate
        WHERE  xmld.mov_line_id            IN (SELECT xmril.mov_line_id
                                               FROM   xxinv_mov_req_instr_lines    xmril
                                               WHERE  xmril.mov_hdr_id = move_data_rec_tbl(gn_rec_idx).mov_hdr_id
                                              )
          AND  xmld.document_type_code     = gv_c_document_type
               ;
-- 2010/03/02 M.Miyagawa Add End
--
        -- 訂正前実績数量更新(出庫)
        UPDATE XXINV_MOV_LOT_DETAILS
--2008/12/17 Y.Kawano Upd Start
--        SET    before_actual_quantity = move_data_rec_tbl(gn_rec_idx).shipped_quantity
        SET    before_actual_quantity = move_data_rec_tbl(gn_rec_idx).lot_out_actual_quantity
--2008/12/17 Y.Kawano Upd End
--2008/12/13 Y.Kawano Add Start
              ,last_updated_by        = gn_user_id
              ,last_update_date       = gd_sysdate
              ,last_update_login      = gn_login_id
              ,request_id             = gn_conc_request_id
              ,program_application_id = gn_prog_appl_id
              ,program_id             = gn_conc_program_id
              ,program_update_date    = gd_sysdate
--2008/12/13 Y.Kawano Add End
        WHERE  mov_lot_dtl_id         = move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id;
--
        -- 訂正前実績数量更新(入庫)
        UPDATE XXINV_MOV_LOT_DETAILS
--2008/12/17 Y.Kawano Upd Start
--        SET    before_actual_quantity = move_data_rec_tbl(gn_rec_idx).ship_to_quantity
        SET    before_actual_quantity = move_data_rec_tbl(gn_rec_idx).lot_in_actual_quantity
--2008/12/17 Y.Kawano Upd End
--2008/12/13 Y.Kawano Add Start
              ,last_updated_by        = gn_user_id
              ,last_update_date       = gd_sysdate
              ,last_update_login      = gn_login_id
              ,request_id             = gn_conc_request_id
              ,program_application_id = gn_prog_appl_id
              ,program_id             = gn_conc_program_id
              ,program_update_date    = gd_sysdate
--2008/12/13 Y.Kawano Add End
        WHERE  mov_lot_dtl_id         = move_data_rec_tbl(gn_rec_idx).mov_lot_dtl_id2;
      ELSE
        lt_pre_mov_hdr_id := move_data_rec_tbl(gn_rec_idx).mov_hdr_id;
        lt_pre_ng_flag    := move_data_rec_tbl(gn_rec_idx).ng_flag;
      END IF;
-- mod end 1.3
--
    END LOOP update_loop;
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
  END update_flg_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_move_num    IN  VARCHAR2,     --   移動番号
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_out_rep VARCHAR2(1000);  -- レポート出力
    ln_o_ret   NUMBER;
    lv_outmsg  VARCHAR2(5000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 必須出力項目
    -- ===============================
    -- パラメータ移動番号入力値
    FND_FILE.PUT(FND_FILE.OUTPUT, '移動番号:');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, iv_move_num);
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'----INIT----');
--
    -- ===============================
    -- 初期処理
    -- ===============================
    init_proc(iv_move_num,    -- 移動番号
              lv_errbuf,      -- エラー・メッセージ           --# 固定 #
              lv_retcode,     -- リターン・コード             --# 固定 #
              lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 2008/12/09 本番障害#470,#519 Add Start -------------------
    -- ===============================
    -- 移動番号重複チェック
    -- ===============================
    check_mov_num_proc(iv_move_num,    -- 移動番号
                       lv_errbuf,      -- エラー・メッセージ           --# 固定 #
                       lv_retcode,     -- リターン・コード             --# 固定 #
                       lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'----check_mov_num_proc----');
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_target_cnt - gn_warn_cnt;
      RAISE global_process_expt;
    END IF;
    -- 2008/12/09 本番障害#470,#519 Add End -------------------
--
    -- ===============================
    -- 移動依頼/指示データ取得 (A-2)
    -- ===============================
    get_move_data_proc(iv_move_num,    -- 移動番号
                       lv_errbuf,      -- エラー・メッセージ           --# 固定 #
                       lv_retcode,     -- リターン・コード             --# 固定 #
                       lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'----get_move_data_proc----');
--
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_target_cnt - gn_warn_cnt;
      RAISE global_process_expt;
    END IF;
--
    -- 処理対象の移動依頼/指示データが存在する場合
    IF gn_no_data_flg = 0 THEN
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----check_proc----');
--
      -- ===============================
      -- 妥当性チェック (A-3)
      -- ===============================
      check_proc(lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                 lv_retcode,             -- リターン・コード             --# 固定 #
                 lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_target_cnt - gn_warn_cnt;
        RAISE global_process_expt;
      --警告の場合
      ELSIF (lv_retcode = gv_status_warn) THEN
        -- ステータスセット
        ov_retcode := gv_status_warn;
--
        -- 警告データが存在する場合
        IF (gn_warn_cnt <> 0) THEN
--
          FND_FILE.PUT_LINE(FND_FILE.LOG,'----- 警告メッセージ出力 START -----');
--
          -- 警告メッセージ内容ループ
          <<log_loop>>
          FOR gn_rec_idx IN 1 .. out_err_tbl.COUNT LOOP
            IF (out_err_tbl(gn_rec_idx).out_msg <> '0') THEN
              lv_outmsg := out_err_tbl(gn_rec_idx).out_msg;
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_outmsg);
            ELSE
              NULL;
            END IF;
          END LOOP log_loop;
--
        END IF;
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----- 警告メッセージ出力 END -----');
--
      END IF;
--
      -- ===============================
      -- 関連データ取得(A-4)
      -- ===============================
      IF (gn_target_cnt <> 0) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----get_data_proc----');
--
        get_data_proc(lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                      lv_retcode,             -- リターン・コード             --# 固定 #
                      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
--
        -- エラー内容がある場合
        IF out_err_tbl2.EXISTS(1) THEN
          -- エラー内容ループ
          <<log2_loop>>
          FOR gn_rec_idx IN 1 .. out_err_tbl2.COUNT LOOP
--
            IF (out_err_tbl2(gn_rec_idx).out_msg <> '0') THEN
              lv_outmsg := out_err_tbl2(gn_rec_idx).out_msg;
--
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_outmsg);
              FND_FILE.PUT_LINE(FND_FILE.LOG,lv_outmsg);
--
            ELSE
              NULL;
            END IF;
--
          END LOOP log2_loop;
        -- エラー内容がない場合
        ELSE
          NULL;
        END IF;
--
        gn_error_cnt := gn_target_cnt - gn_warn_cnt;
        RAISE global_process_expt;
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----- get_data_proc END -----');
--
--
      -- ===============================
      -- 実績訂正全赤情報登録 (A-6)
      -- ===============================
      IF (gn_target_cnt <> 0) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'---regist_adji_proc  start---');
--
        regist_adji_proc(lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                         lv_retcode,             -- リターン・コード             --# 固定 #
                         lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_target_cnt - gn_warn_cnt;
        RAISE global_process_expt;
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'---regist_adji_proc end ---');
--
      -- ===============================
      -- 積送あり実績登録 (A-5)
      -- ===============================
      IF (gn_target_cnt <> 0) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----regist_xfer_proc start ----');
--
        regist_xfer_proc(lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                         lv_retcode,             -- リターン・コード             --# 固定 #
                         lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_target_cnt - gn_warn_cnt;
        RAISE global_process_expt;
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'---regist_xfer_proc  end---');
--
      -- ===============================
      -- 積送なし実績登録 (A-8)
      -- ===============================
      IF (gn_target_cnt <> 0) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'----regist_trni_proc start ----');
--
        regist_trni_proc(lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                         lv_retcode,             -- リターン・コード             --# 固定 #
                         lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
--
      -- エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_target_cnt - gn_warn_cnt;
        RAISE global_process_expt;
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'----regist_trni_proc end ----');
--
      -- ===============================
      -- 実績計上済フラグ,実績訂正フラグ更新(A-10,A-11)
      -- ===============================
      IF (gn_target_cnt <> 0) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.LOG,'---update_flg_proc start ---');
--
        update_flg_proc(lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                        lv_retcode,             -- リターン・コード             --# 固定 #
                        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
-- 2010/03/02 M.Miyagawa Add Start E_本稼動_01612対応
        -- エラーの場合
        IF (lv_retcode = gv_status_error) THEN
          gn_error_cnt := gn_target_cnt - gn_warn_cnt;
          RAISE global_process_expt;
        END IF;
-- 2010/03/02 M.Miyagawa Add End
      END IF;
--
      FND_FILE.PUT_LINE(FND_FILE.LOG,'---update_flg_proc end  ---');
--
--
--
    END IF;  -- 処理対象の移動依頼/指示データが存在する場合のIF文
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
--
    -- 件数ログ出力
    FND_FILE.PUT_LINE(FND_FILE.LOG,'gn_target_cnt='||to_char(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'gn_normal_cnt='||to_char(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'gn_warn_cnt='||to_char(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'gn_error_cnt='||to_char(gn_error_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.LOG,'------ submain END -------');
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_move_num    IN  VARCHAR2       --   移動番号
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
    lv_outmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
      iv_move_num,    -- 移動番号
      lv_errbuf,      -- エラー・メッセージ           --# 固定 #
      lv_retcode,     -- リターン・コード             --# 固定 #
      lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
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
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
-- 2009/02/19 v1.20 ADD START
    IF (gb_lock_expt_flg) THEN
      lv_retcode := gv_status_warn;
    END IF;
--
-- 2009/02/19 v1.20 ADD END
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
-- 2009/02/19 v1.20 UPDATE START
/*
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal) THEN
*/
    --終了ステータスがエラーか、ロックエラーの場合はROLLBACKする
    IF (
         (
           (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal)
         )
         OR
         (gb_lock_expt_flg)
       ) THEN
-- 2009/02/19 v1.20 UPDATE END
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
END xxinv570001c;
/