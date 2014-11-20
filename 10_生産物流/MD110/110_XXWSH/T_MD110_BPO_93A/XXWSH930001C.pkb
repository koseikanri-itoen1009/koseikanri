CREATE OR REPLACE PACKAGE BODY xxwsh930001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh930001c(body)
 * Description      : 生産物流(引当、配車)
 * MD.050           : 出荷・移動インタフェース         T_MD050_BPO_930
 * MD.070           : 外部倉庫入出庫実績インタフェース T_MD070_BPO_93A
 * Version          : 1.14
 *
 * Program List
 * ------------------------------------ -------------------------------------------------
 *  Name                                Description
 * ------------------------------------ -------------------------------------------------
 *  set_deliveryno_unit_errflg          指定配送No、EOSデータ種別単位にflag=1をセットする プロシージャ
 *  set_header_unit_reserveflg          ヘッダ単位(配送No、依頼No・移動番号、EOSデータ種別)にflag=1をセットする プロシージャ
 *  set_movreqno_unit_reserveflg        指定移動/依頼No単位にflag=1をセットする プロシージャ
 *  master_data_get                     マスタ(view)データ取得 プロシージャ
 *  upd_line_items_set                  重量容積小口個数設定 プロシージャ
 *  ord_results_quantity_set            受注実績数量の設定 プロシージャ
 *  mov_results_quantity_set            出荷依頼実績数量の設定 プロシージャ
 *  get_freight_charge_type             運賃形態取得 プロシージャ
 *  carriers_schedule_inup              配車配送計画アドオン作成 プロシージャ
 *  chk_param                           パラメータチェック プロシージャ (A-0)
 *  get_profile                         プロファイル値取得 プロシージャ (A-1)
 *  purge_processing                    パージ処理 プロシージャ (A-2)
 *  get_warehouse_results_info          外部倉庫入出庫実績情報抽出 プロシージャ (A-3)
 *  out_warehouse_number_check          外部倉庫発番チェック プロシージャ (A-4)
 *  err_chk_delivno                     エラーチェック_配送No単位 プロシージャ (A-5-1)
 *  err_chk_delivno_ordersrcref         エラーチェック_配送No受注ソース参照単位 プロシージャ(A-5-2)
 *  err_chk_line                        エラーチェック_明細単位 プロシージャ (A-5-3)
 *  appropriate_check                   妥当チェック プロシージャ (A-6)
 *  mov_table_outpout                   移動依頼/指示アドオン出力 プロシージャ (A-7)
 *  mov_req_instr_head_ins              移動依頼/指示ヘッダアドオン(外部倉庫編集)プロシージャ(A-7-1)
 *  mov_req_instr_head_upd              移動依頼/指示ヘッダアドオン(実績計上編集)プロシージャ(A-7-2)
 *  mov_req_instr_head_inup             移動依頼/指示ヘッダアドオン(実績訂正編集)プロシージャ(A-7-3)
 *  mov_req_instr_lines_ins             移動依頼/指示明細アドオンINSERT プロシージャ(A-7-4)
 *  mov_req_instr_lines_upd             移動依頼/指示明細アドオンUPDATE プロシージャ(A-7-5)
 *  mov_movlot_detail_ins               移動依頼/指示データ移動ロット詳細INSERT プロシージャ(A-7-6)
 *  movlot_detail_upd                   移動ロット詳細UPDATE プロシージャ(A-7-7)
 *  order_table_outpout                 受注アドオン出力 プロシージャ (A-8)
 *  order_headers_upd                   受注ヘッダアドオン(実績計上編集) プロシージャ (A-8-1)
 *  order_headers_ins                   受注ヘッダアドオン(外部倉庫編集) プロシージャ (A-8-2)
 *  order_headers_inup                  受注ヘッダアドオン(実績訂正元編集) プロシージャ (A-8-3,4)
 *  order_lines_upd                     受注明細アドオンUPDATE プロシージャ(A-8-5)
 *  order_lines_ins                     受注明細アドオンINSERT プロシージャ(A-8-6)
 *  order_movlot_detail_ins             受注データ移動ロット詳細INSERT プロシージャ(A-8-7)
 *  order_movlot_detail_up              受注データ移動ロット詳細UPDATE プロシージャ(A-8-8)
 *  lot_reversal_prevention_check       ロット逆転防止チェック プロシージャ (A-9)
 *  drawing_enable_check                引当可能チェック プロシージャ (A-10)
 *  origin_record_delete                抽出元レコード削除 プロシージャ (A-11)
 *  status_update                       ステータス更新 プロシージャ (A-12)
 *  err_check_delete                    エラー発生レベルによりレコード削除プロシージャ (A-13)
 *  err_output                          エラー内容出力プロシージャ (A-14)
 *  ins_upd_del_processing              登録更新削除処理プロシージャ (A-15)
 *  ship_results_regist_process         出荷実績登録処理プロシージャ (A-16)
 *  move_results_regist_process         入出庫実績登録処理プロシージャ (A-17)
 *  submain                             メイン処理プロシージャ
 *  main                                コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/07    1.0  Oracle 齋藤 俊治  初回作成
 *  2008/05/19    1.1  Oracle 宮田 隆史  指摘事項Seq262，263，
 *  2008/06/05    1.2  Oracle 宮田 隆史  結合テスト実施に伴う改修
 *  2008/06/13    1.3  Oracle 宮田 隆史  結合テスト実施に伴う改修
 *  2008/06/23    1.4  Oracle 宮田 隆史  ST不具合#230対応
 *  2008/06/24    1.5  Oracle 宮田 隆史  ST不具合#230対応(2)
 *  2008/06/27    1.6  Oracle 宮田 隆史  ST不具合#299対応
 *  2008/07/01    1.7  Oracle 宮田 隆史  ST不具合#333対応
 *  2008/07/02    1.8  Oracle 宮田 隆史  ST不具合#365対応
 *  2008/07/03    1.9  Oracle 宮田 隆史  ST不具合#392対応
 *  2008/07/04    1.10 Oracle 宮田 隆史  TE080指摘事項#26対応
 *  2008/07/07    1.11 Oracle 宮田 隆史  TE080指摘事項#1対応
 *  2008/07/11    1.12 Oracle 宮田 隆史  TE080指摘事項400#72対応
 *                                       TE080指摘事項930#13,17対応
 *                                       ST不具合420-001#195対応
 *                                       ST不具合440-002#374対応
 *                                       内部変更#168対応
 *                                       T_S_426対応
 *                                       I_S_192対応
 *                                       T_TE110_BPO_280#363対応
 *                                       課題#32,内部変更#173,174
 *  2008/08/01    1.13 Oracle 椎名 昭圭  ｢出荷先｣マスタチェックエラーメッセージ項目名修正
 *  2008/08/06    1.14 Oracle 福田 直樹  最大配送区分算出関数(get_max_ship_method)入力パラメータコード区分２
 *                                       支給の場合の設定値不正(正しくは11なのに9をセットしている)
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
  gv_msg_pnt       CONSTANT VARCHAR2(3) :=',';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);             -- 実行ユーザ名
  gv_conc_name     VARCHAR2(30);              -- 実行コンカレント名
  gv_conc_status   VARCHAR2(30);              -- 終了ステータス
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
  parameter_expt      EXCEPTION;     -- パラメータ例外
  get_prof_expt       EXCEPTION;     -- プロファイル取得エラー
  check_lock_expt     EXCEPTION;     -- ロック取得エラー
  no_data_expt        EXCEPTION;     -- 対象情報なし
  no_insert_expt      EXCEPTION;     -- 処理対象外
  no_record_expt      EXCEPTION;     -- 訂正レコード取得エラー
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxwsh930001c';     -- パッケージ名
  gv_msg_kbn              CONSTANT VARCHAR2(100) := 'XXWSH';            -- アプリケーション短縮名
--
  -- メッセージ番号
  -- 必須パラメータ未入力メッセージ
  gv_msg_93a_001                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13101';
  -- プロファイル取得エラーメッセージ
  gv_msg_93a_002                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13102';
  -- ロックエラーメッセージ
  gv_msg_93a_003                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13103';
  -- 対象データなしメッセージ
  gv_msg_93a_004                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13104';
  -- 同一依頼No/移動No上に同一品目が複数存在エラーメッセージ
  gv_msg_93a_005                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13105';
  -- 出荷依頼インタフェース明細(アドオン)非存在エラーメッセージ
  gv_msg_93a_006                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13106';
  -- 出荷依頼インタフェースヘッダ(アドオン)非存在エラーメッセージ
  gv_msg_93a_007                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13107';
  -- 業務種別ステータスチェックエラーメッセージ
  gv_msg_93a_008                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13108';
  -- 同一配送Noレコード値チェックエラーメッセージ
  gv_msg_93a_009                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13109';
  -- マスタチェックエラーメッセージ
  gv_msg_93a_010                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13110';
  -- 組合せと指示チェックエラーメッセージ
  gv_msg_93a_011                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13111';
  -- 重量容積区分混在エラーメッセージ
  gv_msg_93a_012                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13112';
  -- 商品区分混在エラーメッセージ
  gv_msg_93a_013                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13113';
  -- 品目区分混在エラーメッセージ
  gv_msg_93a_014                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13114';
  -- 有償金額確定区分確定エラーメッセージ
  gv_msg_93a_015                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13115';
  -- 在庫会計期間CLOSEエラー
  gv_msg_93a_016                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13116';
  -- 妥当チェックエラーメッセージ(移動予定実績警告)
  gv_msg_93a_017                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13117';
  -- 妥当チェックエラーメッセージ(出荷支給予定実績警告)
  gv_msg_93a_018                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13118';
  -- 妥当チェックエラーメッセージ(項目妥当チェックエラー)
  gv_msg_93a_019                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13119';
  -- 妥当チェックエラーメッセージ(ロット警告)
  gv_msg_93a_020                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13120';
  -- 妥当チェックエラーメッセージ(品質警告)
  gv_msg_93a_021                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13121';
  -- 妥当チェックエラーメッセージ(数量項目エラー)
  gv_msg_93a_022                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13122';
  -- 最大パレット枚数算出関数エラー
  gv_msg_93a_025                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13125';
  -- ロット逆転防止チェックエラーメッセージ
  gv_msg_93a_026                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13126';
  -- ロット逆転防止チェック処理エラー
  gv_msg_93a_027                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13127';
  -- 引当可能チェックエラーメッセージ
  gv_msg_93a_028                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13128';
  -- 出荷実績登録処理エラーメッセージ
  gv_msg_93a_029                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13129';
  -- 入出庫実績登録処理エラーメッセージ
  gv_msg_93a_030                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13130';
  -- 入力パラメータ(処理対象情報)
  gv_msg_93a_031                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13131';
  -- 入力パラメータ(報告部署)
  gv_msg_93a_032                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13132';
  -- 入力パラメータ(対象倉庫)
  gv_msg_93a_033                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13133';
  -- 処理件数(入力件数)
  gv_msg_93a_034                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13134';
  -- 処理件数(新規受注作成件数)
  gv_msg_93a_035                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13135';
  -- 処理件数(訂正受注作成件数)
  gv_msg_93a_036                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13136';
  -- 処理件数(取消情報件数)
  gv_msg_93a_037                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13137';
  -- 処理件数(異常件数)
  gv_msg_93a_038                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13138';
  -- 処理件数(警告件数)
  gv_msg_93a_039                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13139';
  -- 各処理結果件数
  gv_msg_93a_040                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13140';
  -- 商品区分混在エラー
  gv_msg_93a_142                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13142';
  -- 未来日エラーメッセージ
  gv_msg_93a_143                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13143';
  -- 出庫元引当不可エラーメッセージ
  gv_msg_93a_144                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13144';
  -- ロット管理品のロット数量未設定エラーメッセージ
  gv_msg_93a_146                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13146';
  -- 運賃形態取得警告メッセージ
  gv_msg_93a_147                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13147';
  -- 配送No-運賃区分組合せエラーメッセージ
  gv_msg_93a_148                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13148';
  -- ロット管理品の必須項目未設定エラー
  gv_msg_93a_149                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13149';
  -- ロットマスタ取得エラー
  gv_msg_93a_150                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13150';
  -- ロットマスタ取得複数件エラー
  gv_msg_93a_151                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13151';
  -- 最大配送区分算出関数エラー
  gv_msg_93a_152                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13152';
  -- 配送No-依頼/移動No関連エラーメッセージ
  gv_msg_93a_153                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13153';
  -- 実績計上／訂正不可エラーメッセージ
  gv_msg_93a_154                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13154';
  -- 重量容積小口個数更新関数エラーメッセージ
  gv_msg_93a_308                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13308';
  -- ＰＧでのコンカレント呼び出しエラー
  gv_msg_93a_102                 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10135';
  -- ＰＧでのコンカレント待機エラー
  gv_msg_93a_103                 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10136';
  -- ケース入数エラー
  gv_msg_93a_604                 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10604';
--
  -- トークン
  gv_tkn_cnt                     CONSTANT VARCHAR2(3)  := 'CNT';         -- カウントトークン
  gv_tkn_input_item              CONSTANT VARCHAR2(10) := 'INPUT_ITEM';  -- パラメータ値トークン
  gv_tkn_item                    CONSTANT VARCHAR2(4)  := 'ITEM';        -- 項目値トークン
  gv_prof_token                  CONSTANT VARCHAR2(9)  := 'PROF_NAME';   -- プロファイル名トークン
  gv_table_token                 CONSTANT VARCHAR2(10) := 'TABLE_NAME';  -- テーブル名トークン
  gv_date_token                  CONSTANT VARCHAR2(10) := 'PARA_DATE';   -- 日付名トークン
  gv_param1_token                CONSTANT VARCHAR2(6)  := 'PARAM1';      -- 参照値トークン
  gv_param2_token                CONSTANT VARCHAR2(6)  := 'PARAM2';      -- 参照値トークン
  gv_param3_token                CONSTANT VARCHAR2(6)  := 'PARAM3';      -- 参照値トークン
  gv_param4_token                CONSTANT VARCHAR2(6)  := 'PARAM4';      -- 参照値トークン
  gv_param5_token                CONSTANT VARCHAR2(6)  := 'PARAM5';      -- 参照値トークン
  gv_param6_token                CONSTANT VARCHAR2(6)  := 'PARAM6';      -- 参照値トークン
  gv_param7_token                CONSTANT VARCHAR2(6)  := 'PARAM7';      -- 参照値トークン
  gv_param8_token                CONSTANT VARCHAR2(6)  := 'PARAM8';      -- 参照値トークン
  gv_param9_token                CONSTANT VARCHAR2(6)  := 'PARAM9';      -- 参照値トークン
  gv_param10_token               CONSTANT VARCHAR2(7)  := 'PARAM10';     -- 参照値トークン
  gv_param11_token               CONSTANT VARCHAR2(7)  := 'PARAM11';     -- 参照値トークン
  gv_param1_token01_nm           CONSTANT VARCHAR2(30) := 'パレット回収枚数';
  gv_param1_token02_nm           CONSTANT VARCHAR2(30) := 'パレット使用枚数';
  gv_param1_token03_nm           CONSTANT VARCHAR2(30) := '出荷実績数量';
  gv_param1_token04_nm           CONSTANT VARCHAR2(30) := '内訳数量(インタフェース用)';
  gv_param1_token05_nm           CONSTANT VARCHAR2(30) := '出荷元';
  gv_param1_token06_nm           CONSTANT VARCHAR2(30) := '運送業者';
  gv_param1_token07_nm           CONSTANT VARCHAR2(30) := '受注品目';
  gv_param1_token08_nm           CONSTANT VARCHAR2(30) := '入庫倉庫';
  gv_param1_token09_nm           CONSTANT VARCHAR2(30) := '配送区分';
--********** 2008/08/01 ********** ADD    START ***
  gv_param1_token10_nm           CONSTANT VARCHAR2(30) := '出荷先';
--********** 2008/08/01 ********** ADD    END   ***
  gv_table_token01_nm            CONSTANT VARCHAR2(30) := '受注ヘッダ(アドオン)';
  gv_table_token02_nm            CONSTANT VARCHAR2(30) := '移動依頼/指示ヘッダ(アドオン)';
  gv_date_para_1                 CONSTANT VARCHAR2(6)  := '出荷日';
  gv_date_para_2                 CONSTANT VARCHAR2(6)  := '着荷日';
  gv_request_no_token            CONSTANT VARCHAR2(10) := 'REQUEST_NO';
  gv_item_no_token               CONSTANT VARCHAR2(7)  := 'ITEM_NO';
--
  -- メッセージPARAM1：処理件数名
  gv_c_file_id_name             CONSTANT VARCHAR2(50)   := '受注ヘッダ更新作成件数(実績計上)';
--
--********** 2008/07/07 ********** ADD    START ***
  -- 新規用の件数名称
  gv_ord_new_shikyu_cnt_nm       CONSTANT VARCHAR2(50) := '新規受注（支給）作成';
  gv_ord_new_syukka_cnt_nm       CONSTANT VARCHAR2(50) := '新規受注（出荷）作成';
  gv_mov_new_cnt_nm              CONSTANT VARCHAR2(50) := '新規移動　　　　作成';
  -- 訂正用の件数名称
  gv_ord_correct_shikyu_cnt_nm   CONSTANT VARCHAR2(50) := '訂正受注（支給）作成';
  gv_ord_correct_syukka_cnt_nm   CONSTANT VARCHAR2(50) := '訂正受注（出荷）作成';
  gv_mov_correct_cnt_nm          CONSTANT VARCHAR2(50) := '訂正移動　　　　作成';
--********** 2008/07/07 ********** ADD    START ***
--
--********** 2008/07/07 ********** DELETE START ***
--*  -- 受注ヘッダ
--*  gv_ord_h_upd_n_cnt_nm   CONSTANT VARCHAR2(50) := '受注ヘッダ更新作成(実績計上)';
--*  gv_ord_h_ins_cnt_nm     CONSTANT VARCHAR2(50) := '受注ヘッダ登録作成(外部倉庫発番)';
--*  gv_ord_h_upd_y_cnt_nm   CONSTANT VARCHAR2(50) := '受注ヘッダ更新作成(実績訂正)';
--*  -- 受注明細
--*  gv_ord_l_upd_n_cnt_nm   CONSTANT VARCHAR2(50) := '受注明細更新作成(実績計上品目あり)';
--*  gv_ord_l_ins_n_cnt_nm   CONSTANT VARCHAR2(50) := '受注明細登録作成(実績計上品目なし)';
--*  gv_ord_l_ins_cnt_nm     CONSTANT VARCHAR2(50) := '受注明細登録作成(外部倉庫発番)';
--*  gv_ord_l_ins_y_cnt_nm   CONSTANT VARCHAR2(50) := '受注明細登録作成(実績修正)';
--*  -- ロット詳細
--*  gv_ord_mov_ins_n_cnt_nm CONSTANT VARCHAR2(50) := 'ロット詳細新規作成(受注_実績計上)';
--*  gv_ord_mov_ins_cnt_nm   CONSTANT VARCHAR2(50) := 'ロット詳細新規作成(受注_外部倉庫発番)';
--*  gv_ord_mov_ins_y_cnt_nm CONSTANT VARCHAR2(50) := 'ロット詳細新規作成(受注_実績修正)';
--*  -- 移動依頼/指示ヘッダ
--*  gv_mov_h_ins_cnt_nm     CONSTANT VARCHAR2(50) := '移動依頼/指示ヘッダ登録作成(外部倉庫発番)';
--*  gv_mov_h_upd_n_cnt_nm   CONSTANT VARCHAR2(50) := '移動依頼/指示ヘッダ更新作成(実績計上)';
--*  gv_mov_h_upd_y_cnt_nm   CONSTANT VARCHAR2(50) := '移動依頼/指示ヘッダ更新作成(実績訂正)';
--*  -- 移動依頼/指示明細
--*  gv_mov_l_upd_n_cnt_nm   CONSTANT VARCHAR2(50) := '移動依頼/指示明細更新作成(実績計上品目あり)';
--*  gv_mov_l_ins_n_cnt_nm   CONSTANT VARCHAR2(50) := '移動依頼/指示明細登録作成(実績計上品目なし)';
--*  gv_mov_l_ins_cnt_nm     CONSTANT VARCHAR2(50) := '移動依頼/指示明細登録作成(外部倉庫発番)';
--*  gv_mov_l_upd_y_cnt_nm   CONSTANT VARCHAR2(50) := '移動依頼/指示明細登録作成(訂正元品目あり)';
--*  gv_mov_l_ins_y_cnt_nm   CONSTANT VARCHAR2(50) := '移動依頼/指示明細登録作成(訂正元品目なし)';
--*  -- ロット詳細
--*  gv_mov_mov_ins_n_cnt_nm CONSTANT VARCHAR2(50) := 'ロット詳細新規作成(移動依頼_実績計上)';
--*  gv_mov_mov_ins_cnt_nm   CONSTANT VARCHAR2(50) := 'ロット詳細新規作成(移動依頼_外部倉庫発番)';
--*  gv_mov_mov_upd_y_cnt_nm CONSTANT VARCHAR2(50) := 'ロット詳細新規作成(移動依頼_訂正ロットあり)';
--*  gv_mov_mov_ins_y_cnt_nm CONSTANT VARCHAR2(50) := 'ロット詳細新規作成(移動依頼_訂正ロットなし)';
--*  -- IFヘッダ・明細
--*  gv_header_cnt_nm        CONSTANT VARCHAR2(50) := '出荷依頼インタフェースヘッダ(アドオン)削除';
--********** 2008/07/07 ********** DELETE END   ***
--
--********** 2008/07/07 ********** MODIFY START ***
--*  gv_lines_cnt_nm         CONSTANT VARCHAR2(50) := '出荷依頼インタフェース明細(アドオン)削除';
  gv_lines_cnt_nm         CONSTANT VARCHAR2(50) := '出荷依頼インタフェースパージ削除';
--********** 2008/07/07 ********** MODIFY END   ***
  --
--********** 2008/07/07 ********** MODIFY START ***
--*  -- エラーデータ削除件数
--*  gv_err_data_del_cnt_nm         CONSTANT VARCHAR2(50) := 'エラーデータ削除';
  -- 出荷依頼インタフェースエラー削除
  gv_err_data_del_cnt_nm         CONSTANT VARCHAR2(50) := '出荷依頼インタフェースエラー削除';
--********** 2008/07/07 ********** MODIFY END   ***
--
  gv_err_code_token    CONSTANT VARCHAR2(8)  := 'ERR_CODE'; -- システムエラーコードトークン
  gv_err_msg_token     CONSTANT VARCHAR2(7)  := 'ERR_MSG';  -- システムエラーメッセージトークン
  -- プロファイル(パージ処理期間)
  gn_purge_period      NUMBER; -- プロファイルパージ処理期間
  gv_purge_period_930  CONSTANT VARCHAR2(22) := 'XXWSH_PURGE_PERIOD_930';
  gv_parge_period_jp   CONSTANT VARCHAR2(50) := 'XXWSH:パージ処理期間(入出庫実績インタフェース)';
  -- プロファイル(マスタ組織ID)
  gv_master_org_id               VARCHAR2(100);
  gv_master_org_id_type          CONSTANT VARCHAR2(19) := 'XXCMN_MASTER_ORG_ID';
  gv_master_org_id_jp            CONSTANT VARCHAR2(24) := 'XXCMN:マスタ組織';
  -- パージ処理
  gv_if_table_jp                 CONSTANT VARCHAR2(18) := '出荷依頼IFテーブル';
  -- 受注タイプ
  order_type_name_001            CONSTANT VARCHAR2(30) := '振替出荷';
  -- クイックコード：EOSデータ種別
  gv_eos_data_type               CONSTANT VARCHAR2(9)  := 'XXCMN_D17';
  gv_eos_data_cd_200             CONSTANT VARCHAR2(3)  := '200';  -- 200 有償出荷報告
  gv_eos_data_cd_210             CONSTANT VARCHAR2(3)  := '210';  -- 210 拠点出荷確定報告
  gv_eos_data_cd_215             CONSTANT VARCHAR2(3)  := '215';  -- 215 庭先出荷確定報告
  gv_eos_data_cd_220             CONSTANT VARCHAR2(3)  := '220';  -- 220 移動出庫確定報告
  gv_eos_data_cd_230             CONSTANT VARCHAR2(3)  := '230';  -- 230 移動入庫確定報告
  -- クイックコード：有償金額確定区分
  gv_amount_fix_type             CONSTANT VARCHAR2(22) := 'XXWSH_AMOUNT_FIX_CLASS';
  gv_amount_fix_1                CONSTANT VARCHAR2(1)  := '1';    -- 確定
  gv_amount_fix_2                CONSTANT VARCHAR2(1)  := '2';    -- 未確定
  -- クイックコード：ステータス(移動ステータス)
  gv_mov_status_type             CONSTANT VARCHAR2(17) := 'XXINV_MOVE_STATUS';
  gv_mov_status_01               CONSTANT VARCHAR2(2)  := '01';   -- 依頼中
  gv_mov_status_02               CONSTANT VARCHAR2(2)  := '02';   -- 依頼済
  gv_mov_status_03               CONSTANT VARCHAR2(2)  := '03';   -- 調整中
  gv_mov_status_04               CONSTANT VARCHAR2(2)  := '04';   -- 出庫報告有
  gv_mov_status_05               CONSTANT VARCHAR2(2)  := '05';   -- 入庫報告有
  gv_mov_status_06               CONSTANT VARCHAR2(2)  := '06';   -- 入出庫報告有
  gv_mov_status_99               CONSTANT VARCHAR2(2)  := '99';   -- 取消
  -- クイックコード：ステータス(出荷依頼/支給依頼ステータス)
  gv_req_status_type             CONSTANT VARCHAR2(25) := 'XXWSH_TRANSACTION_STATUS';
  gv_req_status_01               CONSTANT VARCHAR2(2)  := '01';   -- 入力中
  gv_req_status_02               CONSTANT VARCHAR2(2)  := '02';   -- 拠点確定
  gv_req_status_03               CONSTANT VARCHAR2(2)  := '03';   -- 締め済み
  gv_req_status_04               CONSTANT VARCHAR2(2)  := '04';   -- 出荷実績計上済
  gv_req_status_05               CONSTANT VARCHAR2(2)  := '05';   -- 入力中
  gv_req_status_06               CONSTANT VARCHAR2(2)  := '06';   -- 入力完了
  gv_req_status_07               CONSTANT VARCHAR2(2)  := '07';   -- 受領済
  gv_req_status_08               CONSTANT VARCHAR2(2)  := '08';   -- 出荷実績計上済
  gv_req_status_99               CONSTANT VARCHAR2(2)  := '99';   -- 取消
  -- クイックコード：通知ステータス(前回通知ステータス)
  gv_notif_status_type           CONSTANT VARCHAR2(18) := 'XXWSH_NOTIF_STATUS';
  gv_notif_status_10             CONSTANT VARCHAR2(2)  := '10';   -- 未通知
  gv_notif_status_20             CONSTANT VARCHAR2(2)  := '20';   -- 再通知要
  gv_notif_status_40             CONSTANT VARCHAR2(2)  := '40';   -- 確定通知済
  -- 品目区分
  gv_item_kbn_cd_1                CONSTANT VARCHAR2(1)  := '1';   -- 原料
  gv_item_kbn_cd_4                CONSTANT VARCHAR2(1)  := '4';   -- 半製品
  gv_item_kbn_cd_5                CONSTANT VARCHAR2(1)  := '5';   -- 製品
  -- 商品区分
  gv_prod_kbn_cd_1               CONSTANT VARCHAR2(1)  := '1';    -- リーフ
  gv_prod_kbn_cd_2               CONSTANT VARCHAR2(1)  := '2';    -- ドリンク
  -- OPM品目マスタ.ロット管理区分
  gv_lotkr_kbn_cd_0              CONSTANT VARCHAR2(1)  := '0';    -- 無(ロット管理品対象外)
  gv_lotkr_kbn_cd_1              CONSTANT VARCHAR2(1)  := '1';    -- 有(ロット管理品)
  -- クイックコード:ロットステータス
  gv_lot_status_type             CONSTANT VARCHAR2(16) := 'XXCMN_LOT_STATUS';
  gv_lot_status_01               CONSTANT VARCHAR2(2)  := '10';   -- 未判定
  gv_lot_status_02               CONSTANT VARCHAR2(2)  := '20';   -- 一部合格
  gv_lot_status_03               CONSTANT VARCHAR2(2)  := '30';   -- 条件付良品
  gv_lot_status_04               CONSTANT VARCHAR2(2)  := '40';   -- 納品鮮度切れ
  gv_lot_status_05               CONSTANT VARCHAR2(2)  := '50';   -- 合格
  gv_lot_status_06               CONSTANT VARCHAR2(2)  := '60';   -- 不合格
  gv_lot_status_07               CONSTANT VARCHAR2(2)  := '70';   -- 保留
  -- クイックコード：移動タイプ
  gv_move_type                   CONSTANT VARCHAR2(15) := 'XXINV_MOVE_TYPE';
  gv_move_type_1                 CONSTANT VARCHAR2(1)  := '1';    -- 積送あり
  gv_move_type_2                 CONSTANT VARCHAR2(1)  := '2';    -- 積送なし
  -- クイックコード：有無区分
  gv_presence_class_type         CONSTANT VARCHAR2(20) := 'XXINV_PRESENCE_CLASS';
  gv_presence_class_0            CONSTANT VARCHAR2(1)  := '0';    -- 無
  gv_presence_class_1            CONSTANT VARCHAR2(1)  := '1';    -- 有
  -- クイックコード：対象_対象外区分
  gv_include_exclude_type        CONSTANT VARCHAR2(21) := 'XXCMN_INCLUDE_EXCLUDE';
  gv_include_exclude_0           CONSTANT VARCHAR2(1)  := '0';    -- 対象外
  gv_include_exclude_1           CONSTANT VARCHAR2(1)  := '1';    -- 対象
  -- クイックコード：配送区分
  gv_ship_method_type            CONSTANT VARCHAR2(17) := 'XXCMN_SHIP_METHOD';
  gv_ship_method_11              CONSTANT VARCHAR2(2)  := '11';   -- 小口Ｂ
  gv_ship_method_12              CONSTANT VARCHAR2(2)  := '12';   -- 小口Ａ
  gv_ship_method_13              CONSTANT VARCHAR2(2)  := '13';   -- 小型
  gv_ship_method_14              CONSTANT VARCHAR2(2)  := '14';   -- 小型混載
  gv_ship_method_21              CONSTANT VARCHAR2(2)  := '21';   -- ４屯車
  gv_ship_method_22              CONSTANT VARCHAR2(2)  := '22';   -- ４屯車混載
  gv_ship_method_31              CONSTANT VARCHAR2(2)  := '31';   -- 中型車
  gv_ship_method_32              CONSTANT VARCHAR2(2)  := '32';   -- 中型車混載
  gv_ship_method_41              CONSTANT VARCHAR2(2)  := '41';   -- 大型車
  gv_ship_method_42              CONSTANT VARCHAR2(2)  := '42';   -- 大型車混載
  gv_ship_method_51              CONSTANT VARCHAR2(2)  := '51';   -- 増屯車
  gv_ship_method_52              CONSTANT VARCHAR2(2)  := '52';   -- 増屯車混載
  gv_ship_method_61              CONSTANT VARCHAR2(2)  := '61';   -- トレーラー
  gv_ship_method_62              CONSTANT VARCHAR2(2)  := '62';   -- トレーラー混載
  gv_ship_method_81              CONSTANT VARCHAR2(2)  := '81';   -- コンテナ
  gv_ship_method_82              CONSTANT VARCHAR2(2)  := '82';   -- 海上コンテナ
  gv_ship_method_91              CONSTANT VARCHAR2(2)  := '91';   -- 特殊車両
  -- クイックコード：着荷時間
  gv_arrival_time_type           CONSTANT VARCHAR2(18) := 'XXWSH_ARRIVAL_TIME';
  -- クイックコード：重量容積区分
  gv_weight_capacity_class_type  CONSTANT VARCHAR2(27) := 'XXCMN_WEIGHT_CAPACITY_CLASS';
  gv_weight_capacity_class_1     CONSTANT VARCHAR2(1)  := '1';    -- 重量
  gv_weight_capacity_class_2     CONSTANT VARCHAR2(1)  := '2';    -- 容積
  -- クイックコード：YES_NO区分
  gv_yesno_type                  CONSTANT VARCHAR2(27) := 'XXCMN_YESNO';
  gv_yesno_n                     CONSTANT VARCHAR2(27) := 'N';
  gv_yesno_y                     CONSTANT VARCHAR2(27) := 'Y';
  -- クイックコード：文書タイプ
  gv_document_type               CONSTANT VARCHAR2(19) := 'XXINV_DOCUMENT_TYPE';
  gv_document_type_10            CONSTANT VARCHAR2(2)  := '10';   -- 出荷依頼
  gv_document_type_20            CONSTANT VARCHAR2(2)  := '20';   -- 移動
  gv_document_type_30            CONSTANT VARCHAR2(2)  := '30';   -- 支給指示
  gv_document_type_40            CONSTANT VARCHAR2(2)  := '40';   -- 生産指示
  gv_document_type_50            CONSTANT VARCHAR2(2)  := '50';   -- 発注
  -- クイックコード：レコードタイプ
  gv_record_type                 CONSTANT VARCHAR2(19) := 'XXINV_RECORD_TYPE';
  gv_record_type_10              CONSTANT VARCHAR2(2)  := '10';   -- 指示
  gv_record_type_20              CONSTANT VARCHAR2(2)  := '20';   -- 出庫実績
  gv_record_type_30              CONSTANT VARCHAR2(2)  := '30';   -- 入庫実績
  gv_record_type_40              CONSTANT VARCHAR2(2)  := '40';   -- 投入済
  -- クイックコード：製品識別区分
  gv_product_class_type          CONSTANT VARCHAR2(19) := 'XXINV_PRODUCT_CLASS';
  gv_product_class_1             CONSTANT VARCHAR2(1)  := '1';    -- 製品
  gv_product_class_2             CONSTANT VARCHAR2(1)  := '2';    -- 製品以外
--
  gv_reserved_status             CONSTANT VARCHAR2(1)  := '1';    -- ステータス：保留
  gv_flg_on                      CONSTANT VARCHAR2(1)  := '1';    -- フラグON
  gv_flg_off                     CONSTANT VARCHAR2(1)  := '0';    -- フラグOFF
--
  gv_err_class                   CONSTANT VARCHAR2(1)  := '1';    -- エラー処理
  gv_reserved_class              CONSTANT VARCHAR2(1)  := '0';    -- 保留処理
  gv_logonly_class               CONSTANT VARCHAR2(1)  := '9';    -- ログのみ出力
--
  -- VIEWステータス
  gv_view_status                 CONSTANT VARCHAR2(1)  := 'A';    -- 有効
  gv_view_disable                CONSTANT VARCHAR2(1)  := '1';    -- 無効
  gn_view_disable                CONSTANT NUMBER(1)    := 1;      -- 無効
--
  gv_code_class_01               CONSTANT VARCHAR2(2)  := '1';    -- 拠点
  gv_code_class_04               CONSTANT VARCHAR2(2)  := '4';    -- 倉庫
  gv_code_class_09               CONSTANT VARCHAR2(2)  := '9';    -- 配送先
  gv_code_class_11               CONSTANT VARCHAR2(2)  := '11';   -- 支給先
--
  gv_prev_deliv_no_zero          CONSTANT VARCHAR2(1)  := '0';    -- 前回配送No
--
  gv_shipping_class_01           CONSTANT VARCHAR2(10)  := '出荷依頼';
  gv_shipping_class_08           CONSTANT VARCHAR2(10)  := '庭先出荷';
  -- ロット逆転処理種別
  gv_lot_biz_class_2             CONSTANT VARCHAR2(1)  := '2';   -- 出荷の実績計上
  gv_lot_biz_class_6             CONSTANT VARCHAR2(2)  := '6';   -- 移動の実績計上
  -- 重量容積小口個数更新関数 業務種別
  gv_biz_type_1                  CONSTANT VARCHAR2(1)  := '1';   -- 業務種別:1出荷
  gv_biz_type_2                  CONSTANT VARCHAR2(1)  := '2';   -- 業務種別:2支給
  gv_biz_type_3                  CONSTANT VARCHAR2(1)  := '3';   -- 業務種別:3移動
  -- 日付チェックパターン
  gv_date_chk_0                  CONSTANT VARCHAR2(1)  := '0';   -- 正常
  gv_date_chk_1                  CONSTANT VARCHAR2(1)  := '1';   -- 出荷日エラー
  gv_date_chk_2                  CONSTANT VARCHAR2(1)  := '2';   -- 着荷日エラー
  gv_date_chk_3                  CONSTANT VARCHAR2(1)  := '3';   -- 出荷日/着荷日エラー
  -- 処理データ件数パターン
  gv_cnt_kbn_1                   CONSTANT VARCHAR2(1)  := '1';   -- 指示品目=実績品目
  gv_cnt_kbn_2                   CONSTANT VARCHAR2(1)  := '2';   -- 指示品目≠実績品目
  gv_cnt_kbn_3                   CONSTANT VARCHAR2(1)  := '3';   -- 外部倉庫(指示なし)
  gv_cnt_kbn_4                   CONSTANT VARCHAR2(1)  := '4';   -- 実績修正
  gv_cnt_kbn_5                   CONSTANT VARCHAR2(1)  := '5';   -- 実績計上
  gv_cnt_kbn_6                   CONSTANT VARCHAR2(1)  := '6';   -- 訂正元品目あり
  gv_cnt_kbn_7                   CONSTANT VARCHAR2(1)  := '7';   -- 訂正元品目なし
  gv_cnt_kbn_8                   CONSTANT VARCHAR2(1)  := '8';   -- 訂正ロットあり
  gv_cnt_kbn_9                   CONSTANT VARCHAR2(1)  := '9';   -- 訂正ロットなし
  -- 処理種別(配車)
  gv_carrier_trn_type_1          CONSTANT VARCHAR2(1)  := '1';  -- 出荷依頼
  gv_carrier_trn_type_2          CONSTANT VARCHAR2(1)  := '2';  -- 支給指示
  gv_carrier_trn_type_3          CONSTANT VARCHAR2(1)  := '3';  -- 移動指示
  -- 自動配車対象区分
  gv_lv_auto_process_type_0      CONSTANT VARCHAR2(1)  := '0';  -- 対象外
  -- 混載種別
  gv_mixed_type_1                CONSTANT VARCHAR2(1)  := '1';  -- 集約
  -- 運賃形態
  gv_frt_chrg_type_set           CONSTANT VARCHAR2(1)  := '1';  -- 設定振替
  gv_frt_chrg_type_act           CONSTANT VARCHAR2(1)  := '2';  -- 実費振替
--
  gv_delivery_no_null            CONSTANT VARCHAR2(1)  := 'X';  -- 配送No＝NULL時の変換文字
--
  gn_normal                      NUMBER := 0;
  gn_warn                        NUMBER := 1;
  gn_error                       NUMBER := -1;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- レコード定義等を記述する
--
  -- インターフェーステーブルのデータを格納するレコード
  TYPE interface_rec IS RECORD(
    -- IF_H.出荷先
    party_site_code             xxwsh_shipping_headers_if.party_site_code%TYPE,
    -- IF_H.運送業者
    freight_carrier_code        xxwsh_shipping_headers_if.freight_carrier_code%TYPE,
    -- IF_H.配送区分
    shipping_method_code        xxwsh_shipping_headers_if.shipping_method_code%TYPE,
    -- IF_H.顧客発注
    cust_po_number              xxwsh_shipping_headers_if.cust_po_number%TYPE,
    -- IF_H.受注ソース参照
    order_source_ref            xxwsh_shipping_headers_if.order_source_ref%TYPE,
    -- IF_H.配送No
    delivery_no                 xxwsh_shipping_headers_if.delivery_no%TYPE,
    -- IF_H.運賃区分
    freight_charge_class        xxwsh_shipping_headers_if.filler14%TYPE,
    -- IF_H.パレット回収枚数
    collected_pallet_qty        xxwsh_shipping_headers_if.collected_pallet_qty%TYPE,
    -- IF_H.出荷元
    location_code               xxwsh_shipping_headers_if.location_code%TYPE,
    -- IF_H.着荷時間FROM
    arrival_time_from           xxwsh_shipping_headers_if.arrival_time_from%TYPE,
    -- IF_H.着荷時間TO
    arrival_time_to             xxwsh_shipping_headers_if.arrival_time_to%TYPE,
    -- IF_H.EOSデータ種別
    eos_data_type               xxwsh_shipping_headers_if.eos_data_type%TYPE,
    -- IF_H.入庫倉庫
    ship_to_location            xxwsh_shipping_headers_if.ship_to_location%TYPE,
    -- IF_H.出荷日
    shipped_date                xxwsh_shipping_headers_if.shipped_date%TYPE,
    -- IF_H.着荷日
    arrival_date                xxwsh_shipping_headers_if.arrival_date%TYPE,
    -- IF_H.受注タイプ
    order_type                  xxwsh_shipping_headers_if.order_type%TYPE,
    -- IF_H.パレット使用枚数
    used_pallet_qty             xxwsh_shipping_headers_if.used_pallet_qty%TYPE,
    -- IF_H.報告部署
    report_post_code            xxwsh_shipping_headers_if.report_post_code%TYPE,
    -- IF_L.ヘッダID
    header_id                   xxwsh_shipping_lines_if.header_id%TYPE,
    -- IF_L.明細ID
    line_id                     xxwsh_shipping_lines_if.line_id%TYPE,
    -- IF_L.明細番号
    line_number                 xxwsh_shipping_lines_if.line_number%TYPE,
    -- IF_L.受注品目
    orderd_item_code            xxwsh_shipping_lines_if.orderd_item_code%TYPE,
    -- IF_L.数量
    orderd_quantity             xxwsh_shipping_lines_if.orderd_quantity%TYPE,
    -- IF_L.出荷実績数量
    shiped_quantity             xxwsh_shipping_lines_if.shiped_quantity%TYPE,
    -- IF_L.入庫実績数量
    ship_to_quantity            xxwsh_shipping_lines_if.ship_to_quantity%TYPE,
    -- IF_L.ロットNo
    lot_no                      xxwsh_shipping_lines_if.lot_no%TYPE,
    -- IF_L.製造日
    designated_production_date  xxwsh_shipping_lines_if.designated_production_date%TYPE,
    -- IF_L.賞味期限
    use_by_date                 xxwsh_shipping_lines_if.use_by_date%TYPE,
    -- IF_L.固有記号
    original_character          xxwsh_shipping_lines_if.original_character%TYPE,
    -- IF_L.内訳数量
    detailed_quantity           xxwsh_shipping_lines_if.detailed_quantity%TYPE,
    -- OPM品目カテゴリ割当情報VIEW4.品目区分
    item_kbn_cd                 mtl_categories_b.segment1%TYPE,
    -- OPM品目カテゴリ割当情報VIEW4商品区分
    prod_kbn_cd                 mtl_categories_b.segment1%TYPE,
    -- OPM品目情報VIEW2.ロット管理区分
    lot_ctl                     xxcmn_item_mst2_v.lot_ctl%TYPE,
    -- OPM品目情報VIEW2.重量容積区分
    weight_capacity_class       xxcmn_item_mst2_v.weight_capacity_class%TYPE,
    -- OPM品目情報VIEW2.品目ID
    item_id                     xxcmn_item_mst2_v.item_id%TYPE,
    -- OPM品目情報VIEW2.品目
    item_no                     xxcmn_item_mst2_v.item_no%TYPE,
    -- OPM品目情報VIEW2.ケース入数
    num_of_cases                xxcmn_item_mst2_v.num_of_cases%TYPE,
    -- OPM品目情報VIEW2.入出庫換算単位
    conv_unit                   xxcmn_item_mst2_v.conv_unit%TYPE,
    -- 単位
    item_um                     xxcmn_item_mst2_v.item_um%TYPE,
    -- OPM品目情報VIEW2.倉庫品目
    whse_item_id                ic_item_mst_b.whse_item_id%TYPE,
    -- 顧客ID
    customer_id                 xxcmn_cust_accounts2_v.party_id%TYPE,
    -- 顧客
    customer_code               xxcmn_cust_accounts2_v.party_number%TYPE,
    -- 出荷先ID
    deliver_to_id               xxcmn_party_sites.party_site_id%TYPE,
    -- 出荷先_実績ID
    result_deliver_to_id        xxcmn_party_sites_v.party_site_id%TYPE,
    -- 運送業者ID
    career_id                   xxcmn_carriers_v.party_id%TYPE,
    -- 運送業者_実績ID
    result_freight_carrier_id   xxcmn_carriers_v.party_id%TYPE,
    -- ロットID
    lot_id                      ic_lots_mst.lot_id%TYPE,
    -- 出荷元ID
    deliver_from_id             xxcmn_item_locations_v.inventory_location_id%TYPE,
    -- 出庫元ID
    shipped_locat               xxcmn_item_locations_v.inventory_location_id%TYPE,
    -- 入庫先ID
    ship_to_locat               xxcmn_item_locations_v.inventory_location_id%TYPE,
    -- 出荷引当対象フラグ
    allow_pickup_flag           xxcmn_item_locations_v.allow_pickup_flag%TYPE,
    -- 管轄拠点
    base_code                   xxcmn_party_sites.base_code%TYPE,
    -- 仕入先サイトID
    vendor_site_id              xxcmn_vendor_sites2_v.vendor_site_id%TYPE,
    -- 仕入先ID
    vendor_id                   xxcmn_vendor_sites2_v.vendor_id%TYPE,
    -- 仕入先サイト名
    vendor_site_code            xxcmn_vendor_sites2_v.vendor_site_code%TYPE,
    -- 外部倉庫flag (1:外部倉庫の場合、0：外部倉庫でない)
    out_warehouse_flg           VARCHAR2(1),
    -- エラーflag (1:エラーの場合、0:正常)
    err_flg                     VARCHAR2(1),
    -- 保留flag (1:エラーの場合、0:正常)
    reserve_flg                 VARCHAR2(1),
    -- ログのみ出力flag (1:ログのみ出力の場合)
    logonly_flg                 VARCHAR2(1),
    -- メッセージ
    message                     VARCHAR2(5000),
    -- INV品目ID
    inventory_item_id           mtl_system_items_b.inventory_item_id%TYPE,
    -- INV倉庫品目ID
    whse_inventory_item_id      mtl_system_items_b.inventory_item_id%TYPE,
    -- INV倉庫品目
    whse_inventory_item_no      xxcmn_item_mst2_v.item_no%TYPE,
    -- 顧客区分(出荷先)
    customer_class_code         hz_cust_accounts.customer_class_code%TYPE
  );
--
  -- 移動ロット詳細(アドオン)
  TYPE movlot_detail_rec IS RECORD(
     mov_lot_dtl_id          xxinv_mov_lot_details.mov_lot_dtl_id%TYPE            --ロット詳細ID
    ,mov_line_id             xxinv_mov_lot_details.mov_line_id%TYPE               --明細ID
    ,document_type_code      xxinv_mov_lot_details.document_type_code%TYPE        --文書タイプ
    ,record_type_code        xxinv_mov_lot_details.record_type_code%TYPE          --レコードタイプ
    ,item_id                 xxinv_mov_lot_details.item_id%TYPE                   --opm品目ID
    ,item_code               xxinv_mov_lot_details.item_code%TYPE                 --品目
    ,lot_id                  xxinv_mov_lot_details.lot_id%TYPE                    --ロットID
    ,lot_no                  xxinv_mov_lot_details.lot_no%TYPE                    --ロットNO
    ,actual_date             xxinv_mov_lot_details.actual_date%TYPE               --実績日
    ,actual_quantity         xxinv_mov_lot_details.actual_quantity%TYPE           --実績数量
    ,automanual_reserve_class xxinv_mov_lot_details.automanual_reserve_class%TYPE --自動手動引当区分
  );
--
  -- 移動依頼/指示ヘッダ(アドオン)
  TYPE mov_req_instr_h_rec IS RECORD(
     mov_hdr_id                  xxinv_mov_req_instr_headers.mov_hdr_id%TYPE                  --移動ヘッダID
    ,mov_num                     xxinv_mov_req_instr_headers.mov_num%TYPE                     --移動番号
    ,mov_type                    xxinv_mov_req_instr_headers.mov_type%TYPE                    --移動タイプ
    ,entered_date                xxinv_mov_req_instr_headers.entered_date%TYPE                --入力日
    ,instruction_post_code       xxinv_mov_req_instr_headers.instruction_post_code%TYPE       --指示部署
    ,status                      xxinv_mov_req_instr_headers.status%TYPE                      --ステータス
    ,notif_status                xxinv_mov_req_instr_headers.notif_status%TYPE                --通知ステータス
    ,shipped_locat_id            xxinv_mov_req_instr_headers.shipped_locat_id%TYPE            --出庫元ID
    ,shipped_locat_code          xxinv_mov_req_instr_headers.shipped_locat_code%TYPE          --出庫元保管場所
    ,ship_to_locat_id            xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE            --入庫先ID
    ,ship_to_locat_code          xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE          --入庫先保管場所
    ,schedule_ship_date          xxinv_mov_req_instr_headers.schedule_ship_date%TYPE          --出庫予定日
    ,schedule_arrival_date       xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE       --入庫予定日
    ,freight_charge_class        xxinv_mov_req_instr_headers.freight_charge_class%TYPE        --運賃区分
    ,collected_pallet_qty        xxinv_mov_req_instr_headers.collected_pallet_qty%TYPE        --パレット回収枚数
    ,out_pallet_qty              xxinv_mov_req_instr_headers.out_pallet_qty%TYPE              --パレット枚数(出)
    ,in_pallet_qty               xxinv_mov_req_instr_headers.in_pallet_qty%TYPE               --パレット枚数(入)
    ,no_cont_freight_class       xxinv_mov_req_instr_headers.no_cont_freight_class%TYPE       --契約外運賃区分
    ,delivery_no                 xxinv_mov_req_instr_headers.delivery_no%TYPE                 --配送no
    ,description                 xxinv_mov_req_instr_headers.description%TYPE                 --摘要
    ,loading_efficiency_weight   xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE   --積載率(重量)
    ,loading_efficiency_capacity xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE --積載率(容積)
    ,organization_id             xxinv_mov_req_instr_headers.organization_id%TYPE             --組織ID
    ,career_id                   xxinv_mov_req_instr_headers.career_id%TYPE                   --運送業者_ID
    ,freight_carrier_code        xxinv_mov_req_instr_headers.freight_carrier_code%TYPE        --運送業者
    ,shipping_method_code        xxinv_mov_req_instr_headers.shipping_method_code%TYPE        --配送区分
    ,actual_career_id            xxinv_mov_req_instr_headers.actual_career_id%TYPE            --運送業者_ID_実績
    ,actual_freight_carrier_code xxinv_mov_req_instr_headers.actual_freight_carrier_code%TYPE --運送業者_実績
    ,actual_shipping_method_code xxinv_mov_req_instr_headers.actual_shipping_method_code%TYPE --配送区分_実績
    ,arrival_time_from           xxinv_mov_req_instr_headers.arrival_time_from%TYPE           --着荷時間from
    ,arrival_time_to             xxinv_mov_req_instr_headers.arrival_time_to%TYPE             --着荷時間to
    ,slip_number                 xxinv_mov_req_instr_headers.slip_number%TYPE                 --送り状no
    ,sum_quantity                xxinv_mov_req_instr_headers.sum_quantity%TYPE                --合計数量
    ,small_quantity              xxinv_mov_req_instr_headers.small_quantity%TYPE              --小口個数
    ,label_quantity              xxinv_mov_req_instr_headers.label_quantity%TYPE              --ラベル枚数
    ,based_weight                xxinv_mov_req_instr_headers.based_weight%TYPE                --基本重量
    ,based_capacity              xxinv_mov_req_instr_headers.based_capacity%TYPE              --基本容積
    ,sum_weight                  xxinv_mov_req_instr_headers.sum_weight%TYPE                  --積載重量合計
    ,sum_capacity                xxinv_mov_req_instr_headers.sum_capacity%TYPE                --積載容積合計
    ,sum_pallet_weight           xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE           --合計パレット重量
    ,pallet_sum_quantity         xxinv_mov_req_instr_headers.pallet_sum_quantity%TYPE         --パレット合計枚数
    ,mixed_ratio                 xxinv_mov_req_instr_headers.mixed_ratio%TYPE                 --混載率
    ,weight_capacity_class       xxinv_mov_req_instr_headers.weight_capacity_class%TYPE       --重量容積区分
    ,actual_ship_date            xxinv_mov_req_instr_headers.actual_ship_date%TYPE            --出庫実績日
    ,actual_arrival_date         xxinv_mov_req_instr_headers.actual_arrival_date%TYPE         --入庫実績日
    ,mixed_sign                  xxinv_mov_req_instr_headers.mixed_sign%TYPE                  --混載記号
    ,batch_no                    xxinv_mov_req_instr_headers.batch_no%TYPE                    --手配no
    ,item_class                  xxinv_mov_req_instr_headers.item_class%TYPE                  --商品区分
    ,product_flg                 xxinv_mov_req_instr_headers.product_flg%TYPE                 --製品識別区分
    ,no_instr_actual_class       xxinv_mov_req_instr_headers.no_instr_actual_class%TYPE       --指示なし実績区分
    ,comp_actual_flg             xxinv_mov_req_instr_headers.comp_actual_flg%TYPE             --実績計上済フラグ
    ,correct_actual_flg          xxinv_mov_req_instr_headers.correct_actual_flg%TYPE          --実績訂正フラグ
    ,prev_notif_status           xxinv_mov_req_instr_headers.prev_notif_status%TYPE           --前回通知ステータス
    ,notif_date                  xxinv_mov_req_instr_headers.notif_date%TYPE                  --確定通知実施日時
    ,prev_delivery_no            xxinv_mov_req_instr_headers.prev_delivery_no%TYPE            --前回配送no
    ,new_modify_flg              xxinv_mov_req_instr_headers.new_modify_flg%TYPE              --新規修正フラグ
    ,screen_update_by            xxinv_mov_req_instr_headers.screen_update_by%TYPE            --画面更新者
    ,screen_update_date          xxinv_mov_req_instr_headers.screen_update_date%TYPE          --画面更新日時
  );
--
  -- 移動依頼/指示明細(アドオン)
  TYPE mov_req_instr_l_rec IS RECORD(
    mov_line_id                  xxinv_mov_req_instr_lines.mov_line_id%TYPE                 --移動明細ID
    ,mov_hdr_id                  xxinv_mov_req_instr_lines.mov_hdr_id%TYPE                  --移動ヘッダID
    ,line_number                 xxinv_mov_req_instr_lines.line_number%TYPE                 --明細番号
    ,organization_id             xxinv_mov_req_instr_lines.organization_id%TYPE             --組織ID
    ,item_id                     xxinv_mov_req_instr_lines.item_id%TYPE                     --opm品目ID
    ,item_code                   xxinv_mov_req_instr_lines.item_code%TYPE                   --品目
    ,request_qty                 xxinv_mov_req_instr_lines.request_qty%TYPE                 --依頼数量
    ,pallet_quantity             xxinv_mov_req_instr_lines.pallet_quantity%TYPE             --パレット数
    ,layer_quantity              xxinv_mov_req_instr_lines.layer_quantity%TYPE              --段数
    ,case_quantity               xxinv_mov_req_instr_lines.case_quantity%TYPE               --ケース数
    ,instruct_qty                xxinv_mov_req_instr_lines.instruct_qty%TYPE                --指示数量
    ,reserved_quantity           xxinv_mov_req_instr_lines.reserved_quantity%TYPE           --引当数
    ,uom_code                    xxinv_mov_req_instr_lines.uom_code%TYPE                    --単位
    ,designated_production_date  xxinv_mov_req_instr_lines.designated_production_date%TYPE  --指定製造日
    ,pallet_qty                  xxinv_mov_req_instr_lines.pallet_qty%TYPE                  --パレット枚数
    ,move_num                    xxinv_mov_req_instr_lines.move_num%TYPE                    --参照移動番号
    ,po_num                      xxinv_mov_req_instr_lines.po_num%TYPE                      --参照発注番号
    ,first_instruct_qty          xxinv_mov_req_instr_lines.first_instruct_qty%TYPE          --初回指示数量
    ,shipped_quantity            xxinv_mov_req_instr_lines.shipped_quantity%TYPE            --出庫実績数量
    ,ship_to_quantity            xxinv_mov_req_instr_lines.ship_to_quantity%TYPE            --入庫実績数量
    ,weight                      xxinv_mov_req_instr_lines.weight%TYPE                      --重量
    ,capacity                    xxinv_mov_req_instr_lines.capacity%TYPE                    --容積
    ,pallet_weight               xxinv_mov_req_instr_lines.pallet_weight%TYPE               --パレット重量
    ,automanual_reserve_class    xxinv_mov_req_instr_lines.automanual_reserve_class%TYPE    --自動手動引当区分
    ,delete_flg                  xxinv_mov_req_instr_lines.delete_flg%TYPE                  --取消フラグ
    ,warning_date                xxinv_mov_req_instr_lines.warning_date%TYPE                --警告日付
    ,warning_class               xxinv_mov_req_instr_lines.warning_class%TYPE               --警告区分
  );
--
  -- 受注ヘッダ(アドオン)
  TYPE order_h_rec IS RECORD(
    order_header_id              xxwsh_order_headers_all.order_header_id%TYPE             --受注ヘッダアドオンID
    ,order_type_id               xxwsh_order_headers_all.order_type_id%TYPE               --受注タイプID
    ,organization_id             xxwsh_order_headers_all.organization_id%TYPE             --組織ID
    ,header_id                   xxwsh_order_headers_all.header_id%TYPE                   --受注ヘッダID
    ,latest_external_flag        xxwsh_order_headers_all.latest_external_flag%TYPE        --最新フラグ
    ,ordered_date                xxwsh_order_headers_all.ordered_date%TYPE                --受注日
    ,customer_id                 xxwsh_order_headers_all.customer_id%TYPE                 --顧客ID
    ,customer_code               xxwsh_order_headers_all.customer_code%TYPE               --顧客
    ,deliver_to_id               xxwsh_order_headers_all.deliver_to_id%TYPE               --出荷先ID
    ,deliver_to                  xxwsh_order_headers_all.deliver_to%TYPE                  --出荷先
    ,shipping_instructions       xxwsh_order_headers_all.shipping_instructions%TYPE       --出荷指示
    ,career_id                   xxwsh_order_headers_all.career_id%TYPE                   --運送業者ID
    ,freight_carrier_code        xxwsh_order_headers_all.freight_carrier_code%TYPE        --運送業者
    ,shipping_method_code        xxwsh_order_headers_all.shipping_method_code%TYPE        --配送区分
    ,cust_po_number              xxwsh_order_headers_all.cust_po_number%TYPE              --顧客発注
    ,price_list_id               xxwsh_order_headers_all.price_list_id%TYPE               --価格表
    ,request_no                  xxwsh_order_headers_all.request_no%TYPE                  --依頼no
    ,req_status                  xxwsh_order_headers_all.req_status%TYPE                  --ステータス
    ,delivery_no                 xxwsh_order_headers_all.delivery_no%TYPE                 --配送no
    ,prev_delivery_no            xxwsh_order_headers_all.prev_delivery_no%TYPE            --前回配送no
    ,schedule_ship_date          xxwsh_order_headers_all.schedule_ship_date%TYPE          --出荷予定日
    ,schedule_arrival_date       xxwsh_order_headers_all.schedule_arrival_date%TYPE       --着荷予定日
    ,mixed_no                    xxwsh_order_headers_all.mixed_no%TYPE                    --混載元no
    ,collected_pallet_qty        xxwsh_order_headers_all.collected_pallet_qty%TYPE        --パレット回収枚数
    ,confirm_request_class       xxwsh_order_headers_all.confirm_request_class%TYPE       --物流担当確認依頼区分
    ,freight_charge_class        xxwsh_order_headers_all.freight_charge_class%TYPE        --運賃区分
    ,shikyu_instruction_class    xxwsh_order_headers_all.shikyu_instruction_class%TYPE    --支給出庫指示区分
    ,shikyu_inst_rcv_class       xxwsh_order_headers_all.shikyu_inst_rcv_class%TYPE       --支給指示受領区分
    ,amount_fix_class            xxwsh_order_headers_all.amount_fix_class%TYPE            --有償金額確定区分
    ,takeback_class              xxwsh_order_headers_all.takeback_class%TYPE              --引取区分
    ,deliver_from_id             xxwsh_order_headers_all.deliver_from_id%TYPE             --出荷元ID
    ,deliver_from                xxwsh_order_headers_all.deliver_from%TYPE                --出荷元保管場所
    ,head_sales_branch           xxwsh_order_headers_all.head_sales_branch%TYPE           --管轄拠点
    ,po_no                       xxwsh_order_headers_all.po_no%TYPE                       --発注no
    ,prod_class                  xxwsh_order_headers_all.prod_class%TYPE                  --商品区分
    ,item_class                  xxwsh_order_headers_all.item_class%TYPE                  --品目区分
    ,no_cont_freight_class       xxwsh_order_headers_all.no_cont_freight_class%TYPE       --契約外運賃区分
    ,arrival_time_from           xxwsh_order_headers_all.arrival_time_from%TYPE           --着荷時間from
    ,arrival_time_to             xxwsh_order_headers_all.arrival_time_to%TYPE             --着荷時間to
    ,designated_item_id          xxwsh_order_headers_all.designated_item_id%TYPE          --製造品目ID
    ,designated_item_code        xxwsh_order_headers_all.designated_item_code%TYPE        --製造品目
    ,designated_production_date  xxwsh_order_headers_all.designated_production_date%TYPE  --製造日
    ,designated_branch_no        xxwsh_order_headers_all.designated_branch_no%TYPE        --製造枝番
    ,slip_number                 xxwsh_order_headers_all.slip_number%TYPE                 --送り状no
    ,sum_quantity                xxwsh_order_headers_all.sum_quantity%TYPE                --合計数量
    ,small_quantity              xxwsh_order_headers_all.small_quantity%TYPE              --小口個数
    ,label_quantity              xxwsh_order_headers_all.label_quantity%TYPE              --ラベル枚数
    ,loading_efficiency_weight   xxwsh_order_headers_all.loading_efficiency_weight%TYPE   --重量積載効率
    ,loading_efficiency_capacity xxwsh_order_headers_all.loading_efficiency_capacity%TYPE --容積積載効率
    ,based_weight                xxwsh_order_headers_all.based_weight%TYPE                --基本重量
    ,based_capacity              xxwsh_order_headers_all.based_capacity%TYPE              --基本容積
    ,sum_weight                  xxwsh_order_headers_all.sum_weight%TYPE                  --積載重量合計
    ,sum_capacity                xxwsh_order_headers_all.sum_capacity%TYPE                --積載容積合計
    ,mixed_ratio                 xxwsh_order_headers_all.mixed_ratio%TYPE                 --混載率
    ,pallet_sum_quantity         xxwsh_order_headers_all.pallet_sum_quantity%TYPE         --パレット合計枚数
    ,real_pallet_quantity        xxwsh_order_headers_all.real_pallet_quantity%TYPE        --パレット実績枚数
    ,sum_pallet_weight           xxwsh_order_headers_all.sum_pallet_weight%TYPE           --合計パレット重量
    ,order_source_ref            xxwsh_order_headers_all.order_source_ref%TYPE            --受注ソース参照
    ,result_freight_carrier_id   xxwsh_order_headers_all.result_freight_carrier_id%TYPE   --運送業者_実績ID
    ,result_freight_carrier_code xxwsh_order_headers_all.result_freight_carrier_code%TYPE --運送業者_実績
    ,result_shipping_method_code xxwsh_order_headers_all.result_shipping_method_code%TYPE --配送区分_実績
    ,result_deliver_to_id        xxwsh_order_headers_all.result_deliver_to_id%TYPE        --出荷先_実績ID
    ,result_deliver_to           xxwsh_order_headers_all.result_deliver_to%TYPE           --出荷先_実績
    ,shipped_date                xxwsh_order_headers_all.shipped_date%TYPE                --出荷日
    ,arrival_date                xxwsh_order_headers_all.arrival_date%TYPE                --着荷日
    ,weight_capacity_class       xxwsh_order_headers_all.weight_capacity_class%TYPE       --重量容積区分
    ,actual_confirm_class        xxwsh_order_headers_all.actual_confirm_class%TYPE        --実績計上済区分
    ,notif_status                xxwsh_order_headers_all.notif_status%TYPE                --通知ステータス
    ,prev_notif_status           xxwsh_order_headers_all.prev_notif_status%TYPE           --前回通知ステータス
    ,notif_date                  xxwsh_order_headers_all.notif_date%TYPE                  --確定通知実施日時
    ,new_modify_flg              xxwsh_order_headers_all.new_modify_flg%TYPE              --新規修正フラグ
    ,process_status              xxwsh_order_headers_all.process_status%TYPE              --処理経過ステータス
    ,performance_management_dept xxwsh_order_headers_all.performance_management_dept%TYPE --成績管理部署
    ,instruction_dept            xxwsh_order_headers_all.instruction_dept%TYPE            --指示部署
    ,transfer_location_id        xxwsh_order_headers_all.transfer_location_id%TYPE        --振替先ID
    ,transfer_location_code      xxwsh_order_headers_all.transfer_location_code%TYPE      --振替先
    ,mixed_sign                  xxwsh_order_headers_all.mixed_sign%TYPE                  --混載記号
    ,screen_update_date          xxwsh_order_headers_all.screen_update_date%TYPE          --画面更新日時
    ,screen_update_by            xxwsh_order_headers_all.screen_update_by%TYPE            --画面更新者
    ,tightening_date             xxwsh_order_headers_all.tightening_date%TYPE             --出荷依頼締め日時
    ,vendor_id                   xxwsh_order_headers_all.vendor_id%TYPE                   --取引先ID
    ,vendor_code                 xxwsh_order_headers_all.vendor_code%TYPE                 --取引先
    ,vendor_site_id              xxwsh_order_headers_all.vendor_site_id%TYPE              --取引先サイトID
    ,vendor_site_code            xxwsh_order_headers_all.vendor_site_code%TYPE            --取引先サイト
    ,registered_sequence         xxwsh_order_headers_all.registered_sequence%TYPE         --登録順序
    ,tightening_program_id       xxwsh_order_headers_all.tightening_program_id%TYPE       --締めコンカレントID
    ,corrected_tighten_class     xxwsh_order_headers_all.corrected_tighten_class%TYPE     --締め後修正区分
  );
--
  -- 受注明細(アドオン)
  TYPE order_l_rec IS RECORD(
    order_line_id                xxwsh_order_lines_all.order_line_id%TYPE               --受注明細アドオンID
    ,order_header_id             xxwsh_order_lines_all.order_header_id%TYPE             --受注ヘッダアドオンID
    ,order_line_number           xxwsh_order_lines_all.order_line_number%TYPE           --明細番号
    ,header_id                   xxwsh_order_lines_all.header_id%TYPE                   --受注ヘッダID
    ,line_id                     xxwsh_order_lines_all.line_id%TYPE                     --受注明細ID
    ,request_no                  xxwsh_order_lines_all.request_no%TYPE                  --依頼no
    ,shipping_inventory_item_id  xxwsh_order_lines_all.shipping_inventory_item_id%TYPE  --出荷品目ID
    ,shipping_item_code          xxwsh_order_lines_all.shipping_item_code%TYPE          --出荷品目
    ,quantity                    xxwsh_order_lines_all.quantity%TYPE                    --数量
    ,uom_code                    xxwsh_order_lines_all.uom_code%TYPE                    --単位
    ,unit_price                  xxwsh_order_lines_all.unit_price%TYPE                  --単価
    ,shipped_quantity            xxwsh_order_lines_all.shipped_quantity%TYPE            --出荷実績数量
    ,designated_production_date  xxwsh_order_lines_all.designated_production_date%TYPE  --指定製造日
    ,based_request_quantity      xxwsh_order_lines_all.based_request_quantity%TYPE      --拠点依頼数量
    ,request_item_id             xxwsh_order_lines_all.request_item_id%TYPE             --依頼品目ID
    ,request_item_code           xxwsh_order_lines_all.request_item_code%TYPE           --依頼品目
    ,ship_to_quantity            xxwsh_order_lines_all.ship_to_quantity%TYPE            --入庫実績数量
    ,futai_code                  xxwsh_order_lines_all.futai_code%TYPE                  --付帯コード
    ,designated_date             xxwsh_order_lines_all.designated_date%TYPE             --指定日付(リーフ)
    ,move_number                 xxwsh_order_lines_all.move_number%TYPE                 --移動no
    ,po_number                   xxwsh_order_lines_all.po_number%TYPE                   --発注no
    ,cust_po_number              xxwsh_order_lines_all.cust_po_number%TYPE              --顧客発注
    ,pallet_quantity             xxwsh_order_lines_all.pallet_quantity%TYPE             --パレット数
    ,layer_quantity              xxwsh_order_lines_all.layer_quantity%TYPE              --段数
    ,case_quantity               xxwsh_order_lines_all.case_quantity%TYPE               --ケース数
    ,weight                      xxwsh_order_lines_all.weight%TYPE                      --重量
    ,capacity                    xxwsh_order_lines_all.capacity%TYPE                    --容積
    ,pallet_qty                  xxwsh_order_lines_all.pallet_qty%TYPE                  --パレット枚数
    ,pallet_weight               xxwsh_order_lines_all.pallet_weight%TYPE               --パレット重量
    ,reserved_quantity           xxwsh_order_lines_all.reserved_quantity%TYPE           --引当数
    ,automanual_reserve_class    xxwsh_order_lines_all.automanual_reserve_class%TYPE    --自動手動引当区分
    ,delete_flag                 xxwsh_order_lines_all.delete_flag%TYPE                 --削除フラグ
    ,warning_class               xxwsh_order_lines_all.warning_class%TYPE               --警告区分
    ,warning_date                xxwsh_order_lines_all.warning_date%TYPE                --警告日付
    ,line_description            xxwsh_order_lines_all.line_description%TYPE            --摘要
    ,rm_if_flg                   xxwsh_order_lines_all.rm_if_flg%TYPE                   --倉替返品IF済フラグ
    ,shipping_request_if_flg     xxwsh_order_lines_all.shipping_request_if_flg%TYPE     --出荷依頼IF済フラグ
    ,shipping_result_if_flg      xxwsh_order_lines_all.shipping_result_if_flg%TYPE      --出荷実績IF済フラグ
  );
--
  -- データを格納する結合配列
  TYPE interface_tbl IS TABLE OF interface_rec INDEX BY PLS_INTEGER;
--
  -- 出荷依頼インタフェースヘッダ(アドオン)
  TYPE ship_header_id_del
    IS TABLE OF xxwsh_shipping_headers_if.header_id%TYPE INDEX BY BINARY_INTEGER;     --IF_H.ヘッダID\
  TYPE ship_line_id_del
    IS TABLE OF xxwsh_shipping_lines_if.line_id  %TYPE INDEX BY BINARY_INTEGER;       --IF_L.明細ID
  -- 出荷依頼インタフェース明細(アドオン)
  TYPE ship_line_id_upd
    IS TABLE OF xxwsh_shipping_lines_if.line_id%TYPE INDEX BY BINARY_INTEGER;         --IF_L.明細ID(更新用)
  TYPE ship_reserv_sts
    IS TABLE OF xxwsh_shipping_lines_if.reserved_status%TYPE INDEX BY BINARY_INTEGER; --IF_L.保留ステータス(更新用)
  TYPE request_id
    IS TABLE OF xxwsh_shipping_lines_if.request_id%TYPE INDEX BY BINARY_INTEGER;      --IF_L.要求ID
  TYPE ship_order_source_ref
    IS TABLE OF xxwsh_shipping_headers_if.order_source_ref%TYPE INDEX BY BINARY_INTEGER; --IF_H.受注ソース参照（メッセージ表示用）
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate            DATE;                 -- システム現在日付
  gn_target_cnt         NUMBER;               -- 入力件数
--
--********** 2008/07/07 ********** ADD    START ***
  -- 新規用のカウント
  gn_ord_new_shikyu_cnt     NUMBER;               -- 新規受注（支給）作成件数
  gn_ord_new_syukka_cnt     NUMBER;               -- 新規受注（出荷）作成件数
  gn_mov_new_cnt            NUMBER;               -- 新規移動作成件数
  -- 訂正用のカウント
  gn_ord_correct_shikyu_cnt NUMBER;               -- 訂正受注（支給）作成件数
  gn_ord_correct_syukka_cnt NUMBER;               -- 訂正受注（出荷）作成件数
  gn_mov_correct_cnt        NUMBER;               -- 訂正移動作成件数
--********** 2008/07/07 ********** ADD    END   ***
--
--********** 2008/07/07 ********** DELETE START ***
--*  -- 受注ヘッダ
--*  gn_ord_h_upd_n_cnt    NUMBER;               -- 受注ヘッダ更新作成件数(実績計上)
--*  gn_ord_h_ins_cnt      NUMBER;               -- 受注ヘッダ登録作成件数(外部倉庫発番)
--*  gn_ord_h_upd_y_cnt    NUMBER;               -- 受注ヘッダ更新作成件数(実績訂正)
--*  -- 受注明細
--*  gn_ord_l_upd_n_cnt    NUMBER;               -- 受注明細更新作成件数(実績計上品目あり)
--*  gn_ord_l_ins_n_cnt    NUMBER;               -- 受注明細登録作成件数(実績計上品目なし)
--*  gn_ord_l_ins_cnt      NUMBER;               -- 受注明細登録作成件数(外部倉庫発番)
--*  gn_ord_l_ins_y_cnt    NUMBER;               -- 受注明細登録作成件数(実績修正)
--*  -- ロット詳細
--*  gn_ord_mov_ins_n_cnt  NUMBER;               -- ロット詳細新規作成件数(受注_実績計上)
--*  gn_ord_mov_ins_cnt    NUMBER;               -- ロット詳細新規作成件数(受注_外部倉庫発番)
--*  gn_ord_mov_ins_y_cnt  NUMBER;               -- ロット詳細新規作成件数(受注_実績修正)
--*  -- 移動依頼/指示ヘッダ
--*  gn_mov_h_ins_cnt      NUMBER;               -- 移動依頼/指示ヘッダ登録作成件数(外部倉庫発番)
--*  gn_mov_h_upd_n_cnt    NUMBER;               -- 移動依頼/指示ヘッダ更新作成件数(実績計上)
--*  gn_mov_h_upd_y_cnt    NUMBER;               -- 移動依頼/指示ヘッダ更新作成件数(実績訂正)
--*--
--*  -- 移動依頼/指示明細
--*  gn_mov_l_upd_n_cnt    NUMBER;               -- 移動依頼/指示明細更新作成件数(実績計上品目あり)
--*  gn_mov_l_ins_n_cnt    NUMBER;               -- 移動依頼/指示明細登録作成件数(実績計上品目なし)
--*  gn_mov_l_ins_cnt      NUMBER;               -- 移動依頼/指示明細登録作成件数(外部倉庫発番)
--*  gn_mov_l_upd_y_cnt    NUMBER;               -- 移動依頼/指示明細登録作成件数(訂正元品目あり)
--*  gn_mov_l_ins_y_cnt    NUMBER;               -- 移動依頼/指示明細登録作成件数(訂正元品目なし)
--*  -- ロット詳細
--*  gn_mov_mov_ins_n_cnt  NUMBER;               -- ロット詳細新規作成件数(移動依頼_実績計上)
--*  gn_mov_mov_ins_cnt    NUMBER;               -- ロット詳細新規作成件数(移動依頼_外部倉庫発番)
--*  gn_mov_mov_upd_y_cnt  NUMBER;               -- ロット詳細新規作成件数(移動依頼_訂正ロットあり)
--*  gn_mov_mov_ins_y_cnt  NUMBER;               -- ロット詳細新規作成件数(移動依頼_訂正ロットなし)
--*  --
--*
--*  gn_del_headers_cnt    NUMBER;               -- IFヘッダ取消情報件数
--********** 2008/07/07 ********** DELETE END   ***
--
  gn_del_lines_cnt      NUMBER;               -- IF明細取消情報件数
  --
  gn_del_errdata_cnt    NUMBER;               -- エラーデータ削除件数
  --
  gn_warn_cnt           NUMBER;               -- 警告件数
--
--********** 2008/07/07 ********** DELETE START ***
--*  gn_error_cnt          NUMBER;               -- 異常件数
--********** 2008/07/07 ********** DELETE END   ***
--
  gr_interface_info_rec    interface_tbl;             -- インターフェーステーブルのデータ
  gr_movlot_detail_rec     movlot_detail_rec;         -- 移動ロット詳細のデータ
  gr_mov_req_instr_h_rec   mov_req_instr_h_rec;       -- 移動依頼/指示ヘッダのデータ
  gr_mov_req_instr_l_rec   mov_req_instr_l_rec;       -- 移動依頼/指示明細(アドオン)
  gr_order_h_rec           order_h_rec;               -- 受注ヘッダ(アドオン)のデータ
  gr_order_l_rec           order_l_rec;               -- 受注明細(アドオン)のデータ
--
  gr_movlot_detail_ini     movlot_detail_rec;         -- 移動ロット詳細のデータ初期化用
  gr_mov_req_instr_h_ini   mov_req_instr_h_rec;       -- 移動依頼/指示ヘッダのデータ初期化用
  gr_mov_req_instr_l_ini   mov_req_instr_l_rec;       -- 移動依頼/指示明細(アドオン)初期化用
  gr_order_h_ini           order_h_rec;               -- 受注ヘッダ(アドオン)のデータ初期化用
  gr_order_l_ini           order_l_rec;               -- 受注明細(アドオン)のデータ初期化用
--
  -- 出荷依頼IFヘッダ/明細
  gr_line_not_header       ship_header_id_del;        -- IFヘッダ.ヘッダID
  gr_header_id             ship_header_id_del;        -- IFヘッダ.ヘッダID
  gr_line_id               ship_line_id_del;          -- IF明細.明細ID
  gr_request_id            request_id;                -- IF明細.要求ID
  gr_order_source_ref      ship_order_source_ref;     -- IFヘッダ.受注ソース参照
  -- 抽出元エラーレコード削除用
  gr_header_id_del         ship_header_id_del;        -- IFヘッダ.ヘッダID
  gr_line_id_del           ship_line_id_del;          -- IF明細.明細ID
  -- 抽出元保留レコード更新用
  gr_line_id_upd           ship_line_id_upd;          -- IF明細.明細ID
  gr_reserv_sts            ship_reserv_sts;           -- IF明細.保留ステータス
--
  gb_mov_header_flg       BOOLEAN;      -- 移動(A-7) 外部倉庫(指示なし)判定 ヘッダ用
  gb_mov_line_flg         BOOLEAN;      -- 移動(A-7) 外部倉庫(指示なし)判定 明細用
--
  gb_ord_header_flg       BOOLEAN;      -- 受注(A-8) 外部倉庫(指示なし)判定 ヘッダ用
  gb_ord_line_flg         BOOLEAN;      -- 受注(A-8) 外部倉庫(指示なし)判定 明細用
--
  gb_mov_header_data_flg  BOOLEAN;      -- 移動(A-7) ヘッダ処理済判定
  gb_mov_line_data_flg    BOOLEAN;      -- 移動(A-7) 明細処理済判定
--
  gb_ord_header_data_flg  BOOLEAN;      -- 受注(A-8) ヘッダ処理済判定
  gb_ord_line_data_flg    BOOLEAN;      -- 受注(A-8) 明細処理済判定
--
  gb_mov_cnt_a7_flg       BOOLEAN;      -- 移動(A-7) 件数表示で計上か訂正か判断するのためのフラグ
  gb_ord_cnt_a8_flg       BOOLEAN;      -- 受注(A-8) 件数表示で計上か訂正か判断するのためのフラグ
--
  -- WHOカラム
  gt_user_id         xxinv_mov_lot_details.created_by%TYPE;             -- 作成者(最終更新者)
  gt_sysdate         xxinv_mov_lot_details.creation_date%TYPE;          -- 作成日(最終更新日)
  gt_login_id        xxinv_mov_lot_details.last_update_login%TYPE;      -- 最終更新ログイン
  gt_conc_request_id xxinv_mov_lot_details.request_id%TYPE;             -- 要求ID
  gt_prog_appl_id    xxinv_mov_lot_details.program_application_id%TYPE; -- アプリケーションID
  gt_conc_program_id xxinv_mov_lot_details.program_id%TYPE;             -- コンカレント・プログラムID
--
  -- デバッグ用
  gb_debug    BOOLEAN DEFAULT FALSE;    --デバッグログ出力用スイッチ
--
  /**********************************************************************************
   * Procedure Name   : set_debug_switch
   * Description      : デバッグ用ログ出力用切り替えスイッチ取得処理
   ***********************************************************************************/
  PROCEDURE set_debug_switch 
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_debug_switch'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_debug_switch_prof_name CONSTANT VARCHAR2(30) := 'XXWSH_93A_DEBUG_SWITCH';  -- ﾃﾞﾊﾞｯｸﾞﾌﾗｸﾞ
    cv_debug_switch_ON        CONSTANT VARCHAR2(1)  := '1';   --デバッグ出力する
    cv_debug_switch_OFF       CONSTANT VARCHAR2(1)  := '0';   --デバッグ出力しない
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
--
  BEGIN
--
    --デバッグ切り替えプロファイル取得
    IF (FND_PROFILE.VALUE(cv_debug_switch_prof_name) = cv_debug_switch_ON ) THEN
      gb_debug := TRUE;
    END IF;
--
  EXCEPTION
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      gb_debug := FALSE;
--
--#####################################  固定部 END   ##########################################
--
  END set_debug_switch;
--
  /**********************************************************************************
   * Procedure Name   : debug_log
   * Description      : デバッグ用ログ出力処理
   ***********************************************************************************/
  PROCEDURE debug_log(in_which in number,       -- 出力先：FND_FILE.LOG or FND_FILE.OUTPUT
                      iv_msg   in varchar2 )    -- メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'debug_log'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
--
  BEGIN
--
    --デバッグONなら出力
    IF (gb_debug) THEN
      FND_FILE.PUT_LINE(in_which, iv_msg);
    END IF;
--
  EXCEPTION
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      NULL ;
--
--#####################################  固定部 END   ##########################################
--
  END debug_log;
--
  /**********************************************************************************
   * Procedure Name   : set_deliveryno_unit_errflg
   * Description      : 指定配送No、EOSデータ種別単位にflag=1をセットする プロシージャ
   ***********************************************************************************/
  PROCEDURE set_deliveryno_unit_errflg(
    iv_delivery_no          IN  xxwsh_shipping_headers_if.delivery_no%TYPE,  -- 配送No
    iv_eos_data_type        IN  xxwsh_shipping_headers_if.eos_data_type%TYPE,  -- EOFデータ種別
    in_level                IN  VARCHAR2,            -- エラー種別
    iv_message              IN  VARCHAR2,            -- エラーメッセージ
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_deliveryno_unit_errflg'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    <<deliveryno_unit_errflg_set>>
    FOR j IN 1..gr_interface_info_rec.COUNT LOOP
--
      IF ((NVL(iv_delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(j).delivery_no,gv_delivery_no_null)) AND
          (iv_eos_data_type = gr_interface_info_rec(j).eos_data_type))
      THEN
--
        IF (in_level = 1) THEN
          gr_interface_info_rec(j).err_flg := gv_flg_on;
        ELSE
          gr_interface_info_rec(j).reserve_flg := gv_flg_on;
        END IF;
--
        gr_interface_info_rec(j).message := iv_message;
--
      END IF;
--
    END LOOP deliveryno_unit_errflg_set;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END set_deliveryno_unit_errflg;
--
  /**********************************************************************************
   * Procedure Name   : set_header_unit_reserveflg
   * Description      : ヘッダ単位(配送No、依頼No・移動番号、EOSデータ種別)にflag=1をセットする プロシージャ
   ***********************************************************************************/
  PROCEDURE set_header_unit_reserveflg(
    iv_delivery_no          IN  xxwsh_shipping_headers_if.delivery_no%TYPE,  -- 配送No
    iv_movreqno             IN  VARCHAR2,            -- 移動番号、依頼No
    iv_eos_data_type        IN  xxwsh_shipping_headers_if.eos_data_type%TYPE,  -- EOSデータ種別
    in_level                IN  VARCHAR2,            -- エラー種別
    iv_message              IN  VARCHAR2,            -- エラーメッセージ
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_header_unit_reserveflg'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    <<header_unit_reserveflg_set>>
    FOR j IN 1..gr_interface_info_rec.COUNT LOOP
--
      IF ((NVL(iv_delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(j).delivery_no,gv_delivery_no_null)) AND
          (iv_movreqno = gr_interface_info_rec(j).order_source_ref)  AND
          (iv_eos_data_type = gr_interface_info_rec(j).eos_data_type))
      THEN
--
        IF (in_level = gv_err_class) THEN                     -- エラー処理
          gr_interface_info_rec(j).err_flg := gv_flg_on;
        ELSIF (in_level = gv_reserved_class) THEN            -- 保留処理
          gr_interface_info_rec(j).reserve_flg := gv_flg_on;
        ELSIF (in_level = gv_logonly_class) THEN             -- ログのみ出力処理
          gr_interface_info_rec(j).logonly_flg := gv_flg_on;
        END IF;
--
        gr_interface_info_rec(j).message := iv_message;
--
      END IF;
--
    END LOOP header_unit_reserveflg_set;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END set_header_unit_reserveflg;
--
  /**********************************************************************************
   * Procedure Name   : master_data_get
   * Description      : マスタ(view)データ取得 プロシージャ
   ***********************************************************************************/
  PROCEDURE master_data_get(
    in_idx                  IN  NUMBER,              -- データindex
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'master_data_get'; -- プログラム名
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
    lt_customer_id                 xxcmn_cust_accounts2_v.party_id%TYPE;                --パーティーサイトID
    lt_customer_code               xxcmn_cust_accounts2_v.party_number%TYPE;            --パーティーサイトID
    lt_party_site_id               xxcmn_party_sites2_v.party_site_id%TYPE;             --パーティーサイトID
    lt_base_code                   xxcmn_party_sites2_v.base_code%TYPE;                 --管轄拠点
    lt_inventory_location_id       xxcmn_item_locations2_v.inventory_location_id%TYPE;  --倉庫ID
    lt_allow_pickup_flag           xxcmn_item_locations2_v.allow_pickup_flag%TYPE;      --出荷引当対象フラグ
    lt_career_id                   xxcmn_carriers2_v.party_id%TYPE;         --運送業者情報VIEW.パーティーID
    lt_lot_id                      ic_lots_mst.lot_id%TYPE;                             -- ロットID
    lt_item_class_code             xxcmn_item_categories5_v.item_class_code%TYPE;       -- 品目区分
    lt_prod_class_code             xxcmn_item_categories5_v.prod_class_code%TYPE;       -- 商品区分
    lt_lot_ctl                     xxcmn_item_mst2_v.lot_ctl%TYPE;                      -- ロット管理区分
    lt_weight_capacity_class       xxcmn_item_mst2_v.weight_capacity_class%TYPE;        -- 重量容積区分
    lt_item_id                     xxcmn_item_mst2_v.item_id%TYPE;                      -- 品目ID
    lt_item_no                     xxcmn_item_mst2_v.item_no%TYPE;                      -- 品目
    lt_num_of_cases                xxcmn_item_mst2_v.num_of_cases%TYPE;                 -- ケース入数
    lt_conv_unit                   xxcmn_item_mst2_v.conv_unit%TYPE;                    -- 入出庫換算単位
    lt_item_um                     xxcmn_item_mst2_v.item_um%TYPE;                      -- 単位
    lt_whse_item_id                xxcmn_item_mst2_v.whse_item_id%TYPE;                 -- 倉庫品目
    lt_vendor_site_id              xxcmn_vendor_sites2_v.vendor_site_id%TYPE;           -- 仕入先サイトID
    lt_vendor_id                   xxcmn_vendor_sites2_v.vendor_id%TYPE;                -- 仕入先ID
    lt_vendor_site_code            xxcmn_vendor_sites2_v.vendor_site_code%TYPE;         -- 仕入先サイト名
    lt_inventory_item_id           xxcmn_item_mst2_v.inventory_item_id%TYPE;            -- INV品目ID
    lt_whse_inventory_item_id      xxcmn_item_mst2_v.inventory_item_id%TYPE;            -- INV倉庫品目ID
    lt_whse_inventory_item_no      xxcmn_item_mst2_v.item_no%TYPE;                      -- INV倉庫品目
    lt_customer_class_code         xxcmn_cust_accounts2_v.customer_class_code%TYPE;     -- 顧客区分
--
    lv_msg_buff                    VARCHAR2(5000);
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
    -- 業務種別判定
    -- EOSデータ種別 = 200 有償出荷報告, 210 拠点出荷確定報告, 215 庭先出荷確定報告, 220 移動出庫確定報告
    -- 適用開始日・終了日を出荷日にて判定
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215) OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220))
    THEN
--
      ----顧客サイト情報VIEW・顧客情報VIEW
      IF (TRIM(gr_interface_info_rec(in_idx).party_site_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xcav.party_id
                 ,xcav.party_number
                 ,xcav.customer_class_code
          INTO    lt_customer_id
                 ,lt_customer_code
                 ,lt_customer_class_code
          FROM    xxcmn_cust_acct_sites2_v   xcas2v      -- 顧客サイト情報VIEW
                 ,xxcmn_cust_accounts2_v     xcav        -- 顧客情報VIEW
          WHERE   xcas2v.party_site_number     = gr_interface_info_rec(in_idx).party_site_code
          AND     xcas2v.party_site_status     = gv_view_status     -- サイトステータス = '有効'
          AND     xcas2v.cust_acct_site_status = gv_view_status     -- 顧客サイトステータス = '有効'
          AND     xcas2v.cust_site_uses_status = gv_view_status     -- 使用目的ステータス   = '有効'
          AND     xcas2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- 適用開始日 <= IF_H.出荷日
          AND     xcas2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- 適用終了日 >= IF_H.出荷日
          AND     xcas2v.party_id     = xcav.party_id    -- パーティーID=パーティーID
          AND     xcav.party_status   = gv_view_status   -- 組織ステータス = '有効'
          AND     xcav.account_status = gv_view_status   -- 顧客ステータス = '有効'
          AND     xcav.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date)  -- 適用開始日 <= 出荷日
          AND     xcav.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)  -- 適用終了日 >= 出荷日
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).customer_id     := lt_customer_id;
          gr_interface_info_rec(in_idx).customer_code   := lt_customer_code;
          gr_interface_info_rec(in_idx).customer_class_code := lt_customer_class_code;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).customer_id     := NULL;
          gr_interface_info_rec(in_idx).customer_code   := NULL;
          gr_interface_info_rec(in_idx).customer_class_code := NULL;
--
        END ;
--
      END IF;
--
      --パーティサイト情報VIEW(IF_H.出荷先より取得)
      IF (TRIM(gr_interface_info_rec(in_idx).party_site_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xps2v.party_site_id
                 ,xps2v.base_code
          INTO    lt_party_site_id
                 ,lt_base_code
          FROM    xxcmn_party_sites2_v       xps2v
          WHERE   xps2v.party_site_number     = gr_interface_info_rec(in_idx).party_site_code
          AND     xps2v.party_site_status     = gv_view_status     -- サイトステータス = '有効'
          AND     xps2v.cust_site_uses_status = gv_view_status     -- 使用目的ステータス = '有効'
          AND     xps2v.cust_acct_site_status = gv_view_status     -- 顧客サイトステータス= '有効'
          AND     xps2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- 適用開始日 <= 出荷日
          AND     xps2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- 適用終了日 >= 出荷日
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).deliver_to_id         := lt_party_site_id;
          gr_interface_info_rec(in_idx).result_deliver_to_id  := lt_party_site_id;
          gr_interface_info_rec(in_idx).base_code             := lt_base_code;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).deliver_to_id         := NULL;
          gr_interface_info_rec(in_idx).result_deliver_to_id  := NULL;
          gr_interface_info_rec(in_idx).base_code             := NULL;
--
        END ;
--
      END IF;
--
      --運送業者情報VIEW
      IF (TRIM(gr_interface_info_rec(in_idx).freight_carrier_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xcv.party_id
          INTO    lt_career_id
          FROM    xxcmn_carriers2_v          xcv
          WHERE   xcv.party_number       =  gr_interface_info_rec(in_idx).freight_carrier_code
          AND     xcv.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- 適用開始日 <= 出荷日
          AND     xcv.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- 適用終了日 >= 出荷日
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).career_id                 := lt_career_id;
          gr_interface_info_rec(in_idx).result_freight_carrier_id := lt_career_id;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).career_id                 := NULL;
          gr_interface_info_rec(in_idx).result_freight_carrier_id := NULL;
--
        END ;
--
      END IF;
--
      --OPM保管場所情報VIEW(IF_H.出荷元より取得)
      IF (TRIM(gr_interface_info_rec(in_idx).location_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xil2v_a.inventory_location_id
          INTO    lt_inventory_location_id
          FROM    xxcmn_item_locations2_v    xil2v_a
          WHERE   xil2v_a.segment1      =  gr_interface_info_rec(in_idx).location_code
            AND   xil2v_a.date_from  <=  TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- 組織有効開始日
            AND   ((xil2v_a.date_to IS NULL)
             OR   (xil2v_a.date_to >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)))  -- 組織有効終了日
            AND   xil2v_a.disable_date  IS NULL   -- 無効日
            AND   ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).deliver_from_id := lt_inventory_location_id; -- 出荷元ID
          gr_interface_info_rec(in_idx).shipped_locat   := lt_inventory_location_id; -- 出庫元ID
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).deliver_from_id := NULL;  -- 出荷元ID
          gr_interface_info_rec(in_idx).shipped_locat   := NULL;  -- 出庫元ID
--          gr_interface_info_rec(in_idx).err_flg         := gv_flg_on;
--
        END ;
--
      END IF;
--
      --OPM保管場所情報VIEW(IF_H.入庫倉庫より取得)
      IF (TRIM(gr_interface_info_rec(in_idx).ship_to_location) IS NOT NULL) THEN
--
        BEGIN
          lt_inventory_location_id := NULL;
--
          SELECT  xil2v_a.inventory_location_id
          INTO    lt_inventory_location_id
          FROM    xxcmn_item_locations2_v    xil2v_a
          WHERE   xil2v_a.segment1      =  gr_interface_info_rec(in_idx).ship_to_location
            AND   xil2v_a.date_from  <=  TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- 組織有効開始日
            AND   ((xil2v_a.date_to IS NULL)
             OR   (xil2v_a.date_to >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)))  -- 組織有効終了日
            AND   xil2v_a.disable_date  IS NULL   -- 無効日
            AND   ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).ship_to_locat := lt_inventory_location_id; -- 入庫先ID
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).ship_to_locat := NULL; -- 入庫先ID
--
        END ;
--
      END IF;
--
      --OPM保管場所情報VIEW(IF_H.出荷元より取得)
      IF (TRIM(gr_interface_info_rec(in_idx).location_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xil2v_a.allow_pickup_flag       -- 出荷引当対象フラグ(attribute4)
          INTO    lt_allow_pickup_flag
          FROM    xxcmn_item_locations2_v    xil2v_a
          WHERE   xil2v_a.segment1      =  gr_interface_info_rec(in_idx).location_code
            AND   xil2v_a.date_from  <=  TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- 組織有効開始日
            AND   ((xil2v_a.date_to IS NULL)
             OR   (xil2v_a.date_to >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)))  -- 組織有効終了日
            AND   xil2v_a.disable_date  IS NULL   -- 無効日
            AND   ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).allow_pickup_flag := lt_allow_pickup_flag;  -- 出荷引当対象フラグ
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
            gr_interface_info_rec(in_idx).allow_pickup_flag := NULL;
--
        END ;
--
      END IF;
--
      -- OPM品目情報VIEW(IF_L.受注品目より取得)
      IF (TRIM(gr_interface_info_rec(in_idx).orderd_item_code) IS NOT NULL) THEN
--
        BEGIN
--
          -- EOSデータ種別 = 210 拠点出荷確定報告, 215 庭先出荷確定報告の場合
          -- IFされた品目は倉庫品目として検索する
          IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210) OR
              (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215)) THEN
--
            SELECT xic5v.item_class_code                                     -- 品目区分
                  ,xic5v.prod_class_code                                     -- 商品区分
                  ,xim2v_whse.lot_ctl                                        -- ロット管理区分
                  ,xim2v_whse.weight_capacity_class                          -- 重量容積区分
                  ,xim2v_whse.item_id                                        -- 品目ID
                  ,xim2v_whse.item_no                                        -- 品目
                  ,xim2v_whse.num_of_cases                                   -- ケース入数
                  ,xim2v_whse.conv_unit                                      -- 入出庫換算単位
                  ,xim2v_whse.item_um                                        -- 単位
                  ,xim2v_whse.whse_item_id                                   -- 倉庫品目
                  ,xim2v_whse.inventory_item_id                              -- INV品目ID
                  ,NVL(xim2v.inventory_item_id,xim2v_whse.inventory_item_id) -- INV倉庫品目ID(出荷品目(依頼品目))
                  ,NVL(xim2v.item_no,xim2v_whse.item_no)                     -- INV倉庫品目  (出荷品目(依頼品目))
            INTO  lt_item_class_code
                 ,lt_prod_class_code
                 ,lt_lot_ctl
                 ,lt_weight_capacity_class
                 ,lt_item_id
                 ,lt_item_no
                 ,lt_num_of_cases
                 ,lt_conv_unit
                 ,lt_item_um
                 ,lt_whse_item_id
                 ,lt_inventory_item_id
                 ,lt_whse_inventory_item_id
                 ,lt_whse_inventory_item_no
            FROM  (SELECT  item_id                        -- 品目ID
                          ,item_no                        -- 品目
                          ,whse_item_id                   -- 倉庫品目
                          ,inventory_item_id              -- INV品目ID
                   FROM    xxcmn_item_mst2_v
                   WHERE   item_id           <> whse_item_id                         -- 品目と倉庫品目が違うもの
                   AND     inactive_ind      <> gn_view_disable                      -- 無効フラグ
                   AND     obsolete_class    <> gv_view_disable                      -- 廃止区分
                   AND     start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
                   AND     end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
                  )                         xim2v         -- 出荷品目ビュー
                 ,xxcmn_item_mst2_v         xim2v_whse    -- 倉庫品目ビュー
                 ,xxcmn_item_categories5_v  xic5v
            WHERE xim2v_whse.item_no            = gr_interface_info_rec(in_idx).orderd_item_code
            AND   xim2v_whse.item_id            = xim2v.whse_item_id(+)              -- IF品目が倉庫品目に設定されている出荷品目(依頼品目)
            AND   xim2v_whse.inactive_ind      <> gn_view_disable                    -- 無効フラグ
            AND   xim2v_whse.obsolete_class    <> gv_view_disable                    -- 廃止区分
            AND   xim2v_whse.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
            AND   xim2v_whse.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
            AND   xim2v_whse.item_id            = xic5v.item_id
            AND   ROWNUM                        = 1;
--
          -- EOSデータ種別 = 200 有償出荷報告, 220 移動出庫確定報告の場合
          ELSE
--
            SELECT xic5v.item_class_code              -- 品目区分
                  ,xic5v.prod_class_code              -- 商品区分
                  ,xim2v.lot_ctl                      -- ロット管理区分
                  ,xim2v.weight_capacity_class        -- 重量容積区分
                  ,xim2v.item_id                      -- 品目ID
                  ,xim2v.item_no                      -- 品目
                  ,xim2v.num_of_cases                 -- ケース入数
                  ,xim2v.conv_unit                    -- 入出庫換算単位
                  ,xim2v.item_um                      -- 単位
                  ,xim2v.whse_item_id                 -- 倉庫品目
                  ,xim2v.inventory_item_id            -- INV品目ID
                  ,xim2v_whse.inventory_item_id       -- INV倉庫品目ID
                  ,xim2v_whse.item_no                 -- INV倉庫品目
            INTO  lt_item_class_code
                 ,lt_prod_class_code
                 ,lt_lot_ctl
                 ,lt_weight_capacity_class
                 ,lt_item_id
                 ,lt_item_no
                 ,lt_num_of_cases
                 ,lt_conv_unit
                 ,lt_item_um
                 ,lt_whse_item_id
                 ,lt_inventory_item_id
                 ,lt_whse_inventory_item_id
                 ,lt_whse_inventory_item_no
            FROM  xxcmn_item_mst2_v         xim2v
                 ,xxcmn_item_mst2_v         xim2v_whse
                 ,xxcmn_item_categories5_v  xic5v
            WHERE xim2v.item_no            = gr_interface_info_rec(in_idx).orderd_item_code
            AND   xim2v.inactive_ind      <> gn_view_disable                    -- 無効フラグ
            AND   xim2v.obsolete_class    <> gv_view_disable                    -- 廃止区分
            AND   xim2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
            AND   xim2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
            AND   xim2v.item_id            = xic5v.item_id
            AND   xim2v_whse.item_id       = xim2v.whse_item_id  -- 倉庫品目ID(OPM)
            AND   ROWNUM                   = 1;
--
          END IF;
--
          gr_interface_info_rec(in_idx).item_kbn_cd            := lt_item_class_code;
          gr_interface_info_rec(in_idx).prod_kbn_cd            := lt_prod_class_code;
          gr_interface_info_rec(in_idx).lot_ctl                := lt_lot_ctl;
          gr_interface_info_rec(in_idx).weight_capacity_class  := lt_weight_capacity_class;
          gr_interface_info_rec(in_idx).item_id                := lt_item_id;
          gr_interface_info_rec(in_idx).item_no                := lt_item_no;
          gr_interface_info_rec(in_idx).num_of_cases           := lt_num_of_cases;
          gr_interface_info_rec(in_idx).conv_unit              := lt_conv_unit;
          gr_interface_info_rec(in_idx).item_um                := lt_item_um;
          gr_interface_info_rec(in_idx).whse_item_id           := lt_whse_item_id;
          gr_interface_info_rec(in_idx).inventory_item_id      := lt_inventory_item_id;
          gr_interface_info_rec(in_idx).whse_inventory_item_id := lt_whse_inventory_item_id;
          gr_interface_info_rec(in_idx).whse_inventory_item_no := lt_whse_inventory_item_no;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
--
            gr_interface_info_rec(in_idx).item_kbn_cd            := NULL;
            gr_interface_info_rec(in_idx).prod_kbn_cd            := NULL;
            gr_interface_info_rec(in_idx).lot_ctl                := NULL;
            gr_interface_info_rec(in_idx).weight_capacity_class  := NULL;
            gr_interface_info_rec(in_idx).item_id                := NULL;
            gr_interface_info_rec(in_idx).item_no                := NULL;
            gr_interface_info_rec(in_idx).num_of_cases           := NULL;
            gr_interface_info_rec(in_idx).conv_unit              := NULL;
            gr_interface_info_rec(in_idx).item_um                := NULL;
            gr_interface_info_rec(in_idx).whse_item_id           := NULL;
            gr_interface_info_rec(in_idx).inventory_item_id      := NULL;
            gr_interface_info_rec(in_idx).whse_inventory_item_id := NULL;
            gr_interface_info_rec(in_idx).whse_inventory_item_no := NULL;
--
        END ;
--
      END IF;
--
    END IF;
--
    -- EOSデータ種別 = 230:移動入庫確定報告
    -- 適用開始日・終了日を着荷日にて判定
    IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230)
    THEN
--
      ----顧客サイト情報VIEW・顧客情報VIEW
      IF (TRIM(gr_interface_info_rec(in_idx).party_site_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xcav.party_id
                 ,xcav.party_number
                 ,xcav.customer_class_code
          INTO    lt_customer_id
                 ,lt_customer_code
                 ,lt_customer_class_code
          FROM    xxcmn_cust_acct_sites2_v   xcas2v      -- 顧客サイト情報VIEW
                 ,xxcmn_cust_accounts2_v     xcav        -- 顧客情報VIEW
          WHERE   xcas2v.party_site_number     = gr_interface_info_rec(in_idx).party_site_code
          AND     xcas2v.party_site_status     = gv_view_status     -- サイトステータス = '有効'
          AND     xcas2v.cust_acct_site_status = gv_view_status     -- 顧客サイトステータス = '有効'
          AND     xcas2v.cust_site_uses_status = gv_view_status     -- 使用目的ステータス   = '有効'
          AND     xcas2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- 適用開始日 <= IF_H.着荷日
          AND     xcas2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- 適用終了日 >= IF_H.着荷日
          AND     xcas2v.party_id     = xcav.party_id    -- パーティーID=パーティーID
          AND     xcav.party_status   = gv_view_status   -- 組織ステータス = '有効'
          AND     xcav.account_status = gv_view_status   -- 顧客ステータス = '有効'
          AND     xcav.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).arrival_date)  -- 適用開始日 <= IF_H.着荷日
          AND     xcav.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).arrival_date)  -- 適用終了日 >= IF_H.着荷日
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).customer_id     := lt_customer_id;
          gr_interface_info_rec(in_idx).customer_code   := lt_customer_code;
          gr_interface_info_rec(in_idx).customer_class_code := lt_customer_class_code;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).customer_id     := NULL;
          gr_interface_info_rec(in_idx).customer_code   := NULL;
          gr_interface_info_rec(in_idx).customer_class_code := NULL;
--
        END ;
--
      END IF;
--
      IF (TRIM(gr_interface_info_rec(in_idx).party_site_code) IS NOT NULL) THEN
--
        --パーティサイト情報VIEW(IF_H.出荷先より取得)
        BEGIN
--
          SELECT  xps2v.party_site_id
                 ,xps2v.base_code
          INTO    lt_party_site_id
                 ,lt_base_code
          FROM    xxcmn_party_sites2_v       xps2v
          WHERE   xps2v.party_site_number     = gr_interface_info_rec(in_idx).party_site_code
          AND     xps2v.party_site_status     = gv_view_status     -- サイトステータス = '有効'
          AND     xps2v.cust_site_uses_status = gv_view_status     -- 使用目的ステータス = '有効'
          AND     xps2v.cust_acct_site_status = gv_view_status     -- 顧客サイトステータス= '有効'
          AND     xps2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- 適用開始日 <= IF_H.着荷日
          AND     xps2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- 適用終了日 >= IF_H.着荷日
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).deliver_to_id         := lt_party_site_id;
          gr_interface_info_rec(in_idx).result_deliver_to_id  := lt_party_site_id;
          gr_interface_info_rec(in_idx).base_code             := lt_base_code;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).deliver_to_id         := NULL;
          gr_interface_info_rec(in_idx).result_deliver_to_id  := NULL;
          gr_interface_info_rec(in_idx).base_code             := NULL;
--
        END ;
--
      END IF;
--
      --運送業者情報VIEW
      IF (TRIM(gr_interface_info_rec(in_idx).freight_carrier_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xcv.party_id
          INTO    lt_career_id
          FROM    xxcmn_carriers2_v xcv
          WHERE   xcv.party_number       =  gr_interface_info_rec(in_idx).freight_carrier_code
          AND     xcv.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- 適用開始日 <= IF_H.着荷日
          AND     xcv.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- 適用終了日 >= IF_H.着荷日
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).career_id                 := lt_career_id;
          gr_interface_info_rec(in_idx).result_freight_carrier_id := lt_career_id;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).career_id                 := NULL;
          gr_interface_info_rec(in_idx).result_freight_carrier_id := NULL;
--
        END ;
--
      END IF;
--
      --OPM保管場所情報VIEW(IF_H.出荷元より取得)
      IF (TRIM(gr_interface_info_rec(in_idx).location_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xil2v_a.inventory_location_id
          INTO    lt_inventory_location_id
          FROM    xxcmn_item_locations2_v    xil2v_a
          WHERE   xil2v_a.segment1      =  gr_interface_info_rec(in_idx).location_code
            AND   xil2v_a.date_from  <=  TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- 組織有効開始日
            AND   ((xil2v_a.date_to IS NULL)
             OR   (xil2v_a.date_to >= TRUNC(gr_interface_info_rec(in_idx).arrival_date)))  -- 組織有効終了日
            AND   xil2v_a.disable_date  IS NULL   -- 無効日
            AND   ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).deliver_from_id := lt_inventory_location_id;
          gr_interface_info_rec(in_idx).shipped_locat   := lt_inventory_location_id;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).deliver_from_id := NULL;
          gr_interface_info_rec(in_idx).shipped_locat   := NULL;
--
        END ;
--
      END IF;
--
      --OPM保管場所情報VIEW(IF_H.入庫倉庫より取得)
      IF (TRIM(gr_interface_info_rec(in_idx).ship_to_location) IS NOT NULL) THEN
--
        BEGIN
          lt_inventory_location_id := NULL;
--
          SELECT  xil2v_a.inventory_location_id
          INTO    lt_inventory_location_id
          FROM    xxcmn_item_locations2_v    xil2v_a
          WHERE   xil2v_a.segment1      =  gr_interface_info_rec(in_idx).ship_to_location
            AND   xil2v_a.date_from  <=  TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- 組織有効開始日
            AND   ((xil2v_a.date_to IS NULL)
             OR   (xil2v_a.date_to >= TRUNC(gr_interface_info_rec(in_idx).arrival_date)))  -- 組織有効終了日
            AND   xil2v_a.disable_date  IS NULL   -- 無効日
            AND   ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).ship_to_locat := lt_inventory_location_id;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).ship_to_locat := NULL;
--
        END ;
--
      END IF;
--
      -- OPM品目情報VIEW(IF_L.受注品目より取得)
      IF (TRIM(gr_interface_info_rec(in_idx).orderd_item_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT xic5v.item_class_code              -- 品目区分
                ,xic5v.prod_class_code              -- 商品区分
                ,xim2v.lot_ctl                      -- ロット管理区分
                ,xim2v.weight_capacity_class        -- 重量容積区分
                ,xim2v.item_id                      -- 品目ID
                ,xim2v.item_no                      -- 品目
                ,xim2v.num_of_cases                 -- ケース入数
                ,xim2v.conv_unit                    -- 入出庫換算単位
                ,xim2v.item_um                      -- 単位
                ,xim2v.whse_item_id                 -- 倉庫品目
                ,xim2v.inventory_item_id            -- INV品目ID
                ,xim2v_whse.inventory_item_id       -- INV倉庫品目ID
                ,xim2v_whse.item_no                 -- INV倉庫品目
          INTO  lt_item_class_code
               ,lt_prod_class_code
               ,lt_lot_ctl
               ,lt_weight_capacity_class
               ,lt_item_id
               ,lt_item_no
               ,lt_num_of_cases
               ,lt_conv_unit
               ,lt_item_um
               ,lt_whse_item_id
               ,lt_inventory_item_id
               ,lt_whse_inventory_item_id
               ,lt_whse_inventory_item_no
          FROM  xxcmn_item_mst2_v         xim2v
               ,xxcmn_item_mst2_v         xim2v_whse
               ,xxcmn_item_categories5_v  xic5v
          WHERE xim2v.item_no            = gr_interface_info_rec(in_idx).orderd_item_code
          AND   xim2v.inactive_ind      <> gn_view_disable                    -- 無効フラグ
          AND   xim2v.obsolete_class    <> gv_view_disable                    -- 廃止区分
          AND   xim2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).arrival_date)
          AND   xim2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).arrival_date)
          AND   xim2v.item_id            = xic5v.item_id
          AND   xim2v_whse.item_id       = xim2v.whse_item_id  -- 倉庫品目ID(OPM)
          AND   ROWNUM                   = 1;
--
          gr_interface_info_rec(in_idx).item_kbn_cd            := lt_item_class_code;
          gr_interface_info_rec(in_idx).prod_kbn_cd            := lt_prod_class_code;
          gr_interface_info_rec(in_idx).lot_ctl                := lt_lot_ctl;
          gr_interface_info_rec(in_idx).weight_capacity_class  := lt_weight_capacity_class;
          gr_interface_info_rec(in_idx).item_id                := lt_item_id;
          gr_interface_info_rec(in_idx).item_no                := lt_item_no;
          gr_interface_info_rec(in_idx).num_of_cases           := lt_num_of_cases;
          gr_interface_info_rec(in_idx).conv_unit              := lt_conv_unit;
          gr_interface_info_rec(in_idx).item_um                := lt_item_um;
          gr_interface_info_rec(in_idx).whse_item_id           := lt_whse_item_id;
          gr_interface_info_rec(in_idx).inventory_item_id      := lt_inventory_item_id;
          gr_interface_info_rec(in_idx).whse_inventory_item_id := lt_whse_inventory_item_id;
          gr_interface_info_rec(in_idx).whse_inventory_item_no := lt_whse_inventory_item_no;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
--
          gr_interface_info_rec(in_idx).item_kbn_cd            := NULL;
          gr_interface_info_rec(in_idx).prod_kbn_cd            := NULL;
          gr_interface_info_rec(in_idx).lot_ctl                := NULL;
          gr_interface_info_rec(in_idx).weight_capacity_class  := NULL;
          gr_interface_info_rec(in_idx).item_id                := NULL;
          gr_interface_info_rec(in_idx).item_no                := NULL;
          gr_interface_info_rec(in_idx).num_of_cases           := NULL;
          gr_interface_info_rec(in_idx).conv_unit              := NULL;
          gr_interface_info_rec(in_idx).item_um                := NULL;
          gr_interface_info_rec(in_idx).whse_item_id           := NULL;
          gr_interface_info_rec(in_idx).inventory_item_id      := NULL;
          gr_interface_info_rec(in_idx).whse_inventory_item_id := NULL;
          gr_interface_info_rec(in_idx).whse_inventory_item_no := NULL;
--
        END ;
--
      END IF;
--
    END IF;
--
    -- EOSデータ種別に関係なく取得
    -- ロットIDの取得
    IF (TRIM(gr_interface_info_rec(in_idx).lot_no) IS NOT NULL) THEN
--
      BEGIN
--
        SELECT  ilm.lot_id
        INTO    lt_lot_id
        FROM    ic_lots_mst     ilm         -- ロットマスタ
        WHERE   ilm.lot_no      =  gr_interface_info_rec(in_idx).lot_no
          AND   ilm.item_id     =  gr_interface_info_rec(in_idx).item_id
          AND   inactive_ind    = gn_normal
          AND   delete_mark     = gn_normal
          AND   ROWNUM          = 1;
--
        gr_interface_info_rec(in_idx).lot_id := lt_lot_id;
--
      EXCEPTION
--
        WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).lot_id  := 0;
--
      END ;
--
    ELSE
      gr_interface_info_rec(in_idx).lot_id  := 0;
--
    END IF;
--
    -- 仕入先サイトマスタの取得
    IF (TRIM(gr_interface_info_rec(in_idx).party_site_code) IS NOT NULL) THEN
--
      --仕入先サイト情報VIEW2(IF_H.出荷先より取得)
      BEGIN
--
        SELECT xvsv.vendor_site_id          -- 仕入先サイトID
              ,xvsv.vendor_id               -- 仕入先ID
              ,xvsv.vendor_site_code        -- 仕入先サイト名
        INTO   lt_vendor_site_id
              ,lt_vendor_id
              ,lt_vendor_site_code
        FROM   xxcmn_vendor_sites2_v xvsv
        WHERE  xvsv.vendor_site_code = gr_interface_info_rec(in_idx).party_site_code  --仕入先サイト情報VIEW2
        AND    xvsv.start_date_active <= gr_interface_info_rec(in_idx).shipped_date   --適用開始日<=出荷日
        AND    xvsv.end_date_active   >= gr_interface_info_rec(in_idx).shipped_date   --適用終了日>=出荷日
        AND     ROWNUM          = 1;
--
        gr_interface_info_rec(in_idx).vendor_site_id   := lt_party_site_id;
        gr_interface_info_rec(in_idx).vendor_id        := lt_party_site_id;
        gr_interface_info_rec(in_idx).vendor_site_code := lt_base_code;
--
      EXCEPTION
--
        WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).vendor_site_id   := NULL;
          gr_interface_info_rec(in_idx).vendor_id        := NULL;
          gr_interface_info_rec(in_idx).vendor_site_code := NULL;
--
      END ;
--
    END IF;
--
    -- 換算を実施する
    -- EOSデータ種別 = 210：拠点出荷確定報告 or 215：庭先出荷確定報告
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      -- 実績数量の設定を行う。
      IF ((gr_interface_info_rec(in_idx).conv_unit  IS NOT NULL) AND         --入出庫換算単位が設定済み
          (gr_interface_info_rec(in_idx).item_kbn_cd = gv_item_kbn_cd_5) AND --製品
          ((gr_interface_info_rec(in_idx).prod_kbn_cd = gv_prod_kbn_cd_1) OR --リーフ又はドリンク
           (gr_interface_info_rec(in_idx).prod_kbn_cd = gv_prod_kbn_cd_2)))
      THEN
--
        IF (NVL(gr_interface_info_rec(in_idx).num_of_cases,0) > 0)
        THEN
--
          --数量 x ケース入数を設定
          gr_interface_info_rec(in_idx).orderd_quantity
            := NVL(gr_interface_info_rec(in_idx).orderd_quantity,0) * gr_interface_info_rec(in_idx).num_of_cases;
--
          --内訳数量 x ケース入数を設定
          gr_interface_info_rec(in_idx).detailed_quantity
            := NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) * gr_interface_info_rec(in_idx).num_of_cases;
--
        ELSE
--
          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                         'XXCMN'
                        ,gv_msg_93a_604                                 -- ケース入り数エラー
                        ,gv_request_no_token
                        ,gr_interface_info_rec(in_idx).order_source_ref      -- IF_H.受注ソース参照
                        ,gv_item_no_token
                        ,gr_interface_info_rec(in_idx).orderd_item_code      -- IF_L.受注品目
                       )
                        ,1
                        ,5000);
--
          --配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
          set_header_unit_reserveflg(
            gr_interface_info_rec(in_idx).delivery_no,         -- 配送No
            gr_interface_info_rec(in_idx).order_source_ref,    -- 受注ソース参照(依頼/移動No)
            gr_interface_info_rec(in_idx).eos_data_type,       -- EOSデータ種別
            gv_err_class,           -- エラー種別：エラー
            lv_msg_buff,            -- エラー・メッセージ(出力用)
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          -- 処理ステータス：警告
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
    -- EOSデータ種別 = 220：移動出庫確定報告 or 230：移動入庫確定報告
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220)  OR
          (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230)
    THEN
--
      -- 実績数量の設定を行う。
      IF ((gr_interface_info_rec(in_idx).conv_unit  IS NOT NULL) AND         --入出庫換算単位が設定済み
          (gr_interface_info_rec(in_idx).item_kbn_cd = gv_item_kbn_cd_5) AND --製品
          (gr_interface_info_rec(in_idx).prod_kbn_cd = gv_prod_kbn_cd_2))    --ドリンク
      THEN
--
        IF (NVL(gr_interface_info_rec(in_idx).num_of_cases,0) > 0)
        THEN
--
          --数量 x ケース入数を設定
          gr_interface_info_rec(in_idx).orderd_quantity
            := NVL(gr_interface_info_rec(in_idx).orderd_quantity,0) * gr_interface_info_rec(in_idx).num_of_cases;
--
          --内訳数量 x ケース入数を設定
          gr_interface_info_rec(in_idx).detailed_quantity
            := NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) * gr_interface_info_rec(in_idx).num_of_cases;
--
        ELSE
--
          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                         'XXCMN'
                        ,gv_msg_93a_604                                 -- ケース入り数エラー
                        ,gv_request_no_token
                        ,gr_interface_info_rec(in_idx).order_source_ref      -- IF_H.受注ソース参照
                        ,gv_item_no_token
                        ,gr_interface_info_rec(in_idx).orderd_item_code      -- IF_L.受注品目
                       )
                        ,1
                        ,5000);
--
          --配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
          set_header_unit_reserveflg(
            gr_interface_info_rec(in_idx).delivery_no,         -- 配送No
            gr_interface_info_rec(in_idx).order_source_ref,    -- 受注ソース参照(依頼/移動No)
            gr_interface_info_rec(in_idx).eos_data_type,       -- EOSデータ種別
            gv_err_class,           -- エラー種別：エラー
            lv_msg_buff,            -- エラー・メッセージ(出力用)
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          -- 処理ステータス：警告
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -- ロット管理外の場合、数量または内訳数量の状態によりどちらかを実績数量項目へ設定する
    -- ロット管理区分 = 0:ロット管理外
    IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0) THEN
--
      -- EOSデータ種別 = 200:有償出荷報告 or 210：拠点出荷確定報告 or 215：庭先出荷確定報告 or 220：移動出庫確定報告
      IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200)  OR
          (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
          (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215)  OR
          (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220)) THEN
--
        IF NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0 THEN
--
          -- 数量を出荷実績数量へ設定
          gr_interface_info_rec(in_idx).shiped_quantity := NVL(gr_interface_info_rec(in_idx).orderd_quantity,0);
--
        ELSE
--
          -- 内訳数量を出荷実績数量へ設定
          gr_interface_info_rec(in_idx).shiped_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
        END IF;
--
      -- EOSデータ種別 = 230：移動入庫確定報告
      ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
--
        IF NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0 THEN
--
          -- 数量を入庫実績数量へ設定
          gr_interface_info_rec(in_idx).ship_to_quantity := NVL(gr_interface_info_rec(in_idx).orderd_quantity,0);
--
        ELSE
--
          -- 内訳数量を入庫実績数量へ設定
          gr_interface_info_rec(in_idx).ship_to_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
        END IF;
--
      END IF;
--
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END master_data_get;
--
  /**********************************************************************************
   * Procedure Name   : upd_line_items_set
   * Description      : 重量容積小口個数設定 プロシージャ
   ***********************************************************************************/
  PROCEDURE upd_line_items_set(
    in_idx                  IN  NUMBER,              -- データindex
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_line_items_set'; -- プログラム名
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
    lv_biz_type             VARCHAR2(1);     -- 業務種別
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
    -- 業務種別判定
    -- EOSデータ種別 = 210 拠点出荷確定報告,215 庭先出荷確定報告の場合
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      lv_biz_type     := gv_biz_type_1; --出荷
--
    -- EOSデータ種別 = 200 有償出荷報告の場合
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
      lv_biz_type     := gv_biz_type_2; --支給
--
    ELSE
--
      lv_biz_type     := gv_biz_type_3; --移動
--
    END IF;
--
    -- 重量容積小口個数更新関数実施
    lv_retcode := xxwsh_common_pkg.update_line_items(
                         lv_biz_type            -- 業務種別
                        ,gr_interface_info_rec(in_idx).order_source_ref    -- 変換前依頼No
                       );
--
    -- 重量容積小口個数更新関数の処理結果判定
    IF (lv_retcode <> gn_normal) THEN
--
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
           gv_msg_kbn                 -- 'XXWSH'
          ,gv_msg_93a_308             -- 重量容積小口個数更新関数エラーメッセージ
          )
          ,1
          ,5000);
--
      RAISE global_api_expt;
--
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END upd_line_items_set;
--
  /**********************************************************************************
   * F Name   : ord_results_quantity_set
   * Description      : 受注実績数量の設定 プロシージャ
   ***********************************************************************************/
  PROCEDURE ord_results_quantity_set(
    in_idx                  IN  NUMBER,              -- データindex
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ord_results_quantity_set'; -- プログラム名
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
    lt_order_header_id     xxwsh_order_headers_all.order_header_id%TYPE;          --受注ヘッダアドオンID
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR ord_results_quantity_cur
      (
      in_order_header_id          xxwsh_order_headers_all.order_header_id%TYPE,   -- 受注ヘッダアドオンID
      in_item_id                  xxinv_mov_lot_details.item_id%TYPE              -- OPM品目ID
      )
    IS
      SELECT xola.order_line_id
            ,xmld.item_id
            ,SUM(NVL(xmld.actual_quantity,0))
      FROM  xxwsh_order_headers_all xoha,
            xxwsh_order_lines_all   xola,
            xxinv_mov_lot_details   xmld
      WHERE xoha.order_header_id      = in_order_header_id    -- 受注ヘッダID
      AND   xoha.order_header_id      = xola.order_header_id  -- 受注ヘッダID
      AND   xola.order_line_id        = xmld.mov_line_id      -- 受注明細ID
      AND   xmld.item_id              = in_item_id            -- OPM品目ID
      AND   xoha.latest_external_flag = gv_yesno_y            -- 最新フラグ
      AND   xmld.record_type_code     = gv_record_type_20     -- レコードタイプ = 出庫実績(20)
      AND   ((xola.delete_flag = gv_yesno_n) OR (xola.delete_flag IS NULL))  -- 削除フラグ
      GROUP BY
                xola.order_line_id
                ,xmld.item_id
      ;
--
    -- *** ローカル・レコード ***
--
    --出庫実績数量取得用
    -- 明細ID
    TYPE order_line_id_type_rec IS TABLE OF
      xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
    -- 品目ID
    TYPE item_id_rec IS TABLE OF
      xxinv_mov_lot_details.item_id%TYPE INDEX BY BINARY_INTEGER;
    -- 出庫実績数量
    TYPE sum_actual_quantity IS TABLE OF
      xxinv_mov_lot_details.actual_quantity%TYPE INDEX BY BINARY_INTEGER;
--
    lt_order_line_id         order_line_id_type_rec;     -- 明細ID
    lt_item_id               item_id_rec;                -- 品目ID
    lt_sum_actual_quantity   sum_actual_quantity;        -- 出庫実績数量
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
    lt_order_header_id     := gr_order_h_rec.order_header_id; --受注ヘッダID
--
    --  移動ロット詳細より実数数量の合計を取得する
    OPEN ord_results_quantity_cur
      (
        lt_order_header_id
        ,gr_interface_info_rec(in_idx).item_id
      );
--
    --フェッチ
    FETCH ord_results_quantity_cur BULK COLLECT
     INTO lt_order_line_id
          ,lt_item_id
          ,lt_sum_actual_quantity;
--
    --クローズ
    CLOSE ord_results_quantity_cur;
--
    -- 更新処理(バルク処理)
    <<sum_actual_quantity_upd_loop>>
    FORALL i IN 1 .. lt_order_line_id.COUNT
      -- **************************************************
      -- *** 受注明細(アドオン)更新を行う
      -- **************************************************
      UPDATE
        xxwsh_order_lines_all    xola    -- 受注明細(アドオン)
      SET
         xola.shipped_quantity        = lt_sum_actual_quantity(i)               -- 出庫実績数量
        ,xola.last_updated_by         = gt_user_id                              -- 最終更新者
        ,xola.last_update_date        = gt_sysdate                              -- 最終更新日
        ,xola.last_update_login       = gt_login_id                             -- 最終更新ログイン
        ,xola.request_id              = gt_conc_request_id                      -- 要求ID
        ,xola.program_application_id  = gt_prog_appl_id                         -- アプリケーションID
        ,xola.program_id              = gt_conc_program_id                      -- プログラムID
        ,xola.program_update_date     = gt_sysdate                              -- プログラム更新日
      WHERE xola.order_line_id = lt_order_line_id(i) -- 受注明細ID
      AND   ((xola.delete_flag = gv_yesno_n) OR (xola.delete_flag IS NULL))
      ;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END ord_results_quantity_set;
--
  /**********************************************************************************
   * F Name   : mov_results_quantity_set
   * Description      : 出荷依頼実績数量の設定 プロシージャ
   ***********************************************************************************/
  PROCEDURE mov_results_quantity_set(
    in_idx                  IN  NUMBER,              -- データindex
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_results_quantity_set'; -- プログラム名
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
    lt_mov_hdr_id     xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;       --移動ヘッダID
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR mov_results_quantity_cur
      (
      in_mov_hdr_id        xxinv_mov_req_instr_headers.mov_hdr_id%TYPE,      -- 移動ヘッダID
      in_item_id           xxinv_mov_lot_details.item_id%TYPE,                -- OPM品目ID
      in_record_type       xxinv_mov_lot_details.record_type_code%TYPE       -- レコードタイプ
      )
    IS
      SELECT xmrql.mov_line_id
            ,xmld.item_id
            ,SUM(NVL(xmld.actual_quantity,0))
      FROM  xxinv_mov_req_instr_headers xmrif,
            xxinv_mov_req_instr_lines   xmrql,
            xxinv_mov_lot_details   xmld
      WHERE xmrif.mov_hdr_id        = in_mov_hdr_id       -- 移動ヘッダID
      AND   xmrif.mov_hdr_id        = xmrql.mov_hdr_id   -- 移動ヘッダID
      AND   xmrql.mov_line_id       = xmld.mov_line_id    -- 移動明細ID
      AND   xmld.item_id            = in_item_id -- OPM品目ID
      AND   xmld.record_type_code   = in_record_type      -- レコードタイプ
      AND   xmrif.status           <> gv_mov_status_99    -- ステータス<>取消以外
      AND   ((xmrql.delete_flg = gv_yesno_n) OR (xmrql.delete_flg IS NULL))
      GROUP BY
                xmrql.mov_line_id
                ,xmld.item_id
      ;
    -- *** ローカル・レコード ***
--
    -- 出庫実績数量取得用
    -- 明細ID
    TYPE mov_line_rec IS TABLE OF
      xxinv_mov_req_instr_lines.mov_line_id%TYPE INDEX BY BINARY_INTEGER;
    -- 品目ID
    TYPE item_id_rec IS TABLE OF
      xxinv_mov_req_instr_lines.item_id%TYPE INDEX BY BINARY_INTEGER;
    -- 出庫実績数量
    TYPE sum_actual_quantity IS TABLE OF
      xxinv_mov_lot_details.actual_quantity%TYPE INDEX BY BINARY_INTEGER;
--
    -- 初期化用
    lt_mov_line_rec_ini        mov_line_rec;               -- 移動明細ID
    lt_item_id_ini             item_id_rec;                -- 品目ID
    lt_sum_actual_quantity_ini sum_actual_quantity;        -- 出庫実績数量
--
    lt_mov_line_rec            mov_line_rec;               -- 移動明細ID
    lt_item_id                 item_id_rec;                -- 品目ID
    lt_sum_actual_quantity     sum_actual_quantity;        -- 出庫実績数量
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
    lt_mov_hdr_id          := gr_mov_req_instr_h_rec.mov_hdr_id; --移動ヘッダID
--
    -- 初期化
    lt_mov_line_rec        := lt_mov_line_rec_ini;
    lt_item_id             := lt_item_id_ini;
    lt_sum_actual_quantity := lt_sum_actual_quantity_ini;
--
    -- 移動出庫確定報告の場合、出庫実績数量の設定を行う
    IF gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220 THEN
      --  移動ロット詳細より実数数量の合計を取得する
      OPEN mov_results_quantity_cur
        (
          lt_mov_hdr_id
          ,gr_interface_info_rec(in_idx).item_id
          ,gv_record_type_20                      -- レコードタイプ = 出庫実績(20)
        );
--
      --フェッチ
      FETCH mov_results_quantity_cur BULK COLLECT
       INTO lt_mov_line_rec
            ,lt_item_id
            ,lt_sum_actual_quantity;
--
      --クローズ
      CLOSE mov_results_quantity_cur;
--
      -- 更新処理(バルク処理)
      <<sum_actual_quantity_upd_loop>>
      FORALL i IN 1 .. lt_mov_line_rec.COUNT
        -- **************************************************
        -- *** 依頼明細(アドオン)更新を行う
        -- **************************************************
        UPDATE
          xxinv_mov_req_instr_lines    xmrql    -- 移動明細(アドオン)
        SET
           xmrql.shipped_quantity        = lt_sum_actual_quantity(i) -- 出庫実績数量
          ,xmrql.last_updated_by         = gt_user_id                     -- 最終更新者
          ,xmrql.last_update_date        = gt_sysdate                     -- 最終更新日
          ,xmrql.last_update_login       = gt_login_id                    -- 最終更新ログイン
          ,xmrql.request_id              = gt_conc_request_id             -- 要求ID
          ,xmrql.program_application_id  = gt_prog_appl_id                -- アプリケーションID
          ,xmrql.program_id              = gt_conc_program_id             -- プログラムID
          ,xmrql.program_update_date     = gt_sysdate                     -- プログラム更新日
        WHERE 
              xmrql.mov_line_id = lt_mov_line_rec(i)                         -- 移動明細ID
        AND ((xmrql.delete_flg = gv_yesno_n) OR (xmrql.delete_flg IS NULL)) -- 削除フラグ=未削除
        ;
--
    END IF;
--
    -- 移動入庫確定報告の場合、入庫実績数量の設定を行う
    IF gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230 THEN
--
      --  移動ロット詳細より実数数量の合計を取得する
      OPEN mov_results_quantity_cur
        (
          lt_mov_hdr_id
          ,gr_interface_info_rec(in_idx).item_id
          ,gv_record_type_30                      -- レコードタイプ = 入庫実績(30)
        );
--
      --フェッチ
      FETCH mov_results_quantity_cur BULK COLLECT
       INTO lt_mov_line_rec
            ,lt_item_id
            ,lt_sum_actual_quantity;
--
      --クローズ
      CLOSE mov_results_quantity_cur;
--
      -- 更新処理(バルク処理)
      <<sum_actual_quantity_upd_loop>>
      FORALL i IN 1 .. lt_mov_line_rec.COUNT
        -- **************************************************
        -- *** 移動依頼/指示明細(アドオン)更新を行う
        -- **************************************************
--
        UPDATE
          xxinv_mov_req_instr_lines    xmrql    -- 移動依頼/指示明細(アドオン)
        SET
           xmrql.ship_to_quantity        = lt_sum_actual_quantity(i)       -- 入庫実績数量
          ,xmrql.last_updated_by         = gt_user_id                      -- 最終更新者
          ,xmrql.last_update_date        = gt_sysdate                      -- 最終更新日
          ,xmrql.last_update_login       = gt_login_id                     -- 最終更新ログイン
          ,xmrql.request_id              = gt_conc_request_id              -- 要求ID
          ,xmrql.program_application_id  = gt_prog_appl_id                 -- アプリケーションID
          ,xmrql.program_id              = gt_conc_program_id              -- プログラムID
          ,xmrql.program_update_date     = gt_sysdate                      -- プログラム更新日
        WHERE 
              xmrql.mov_line_id = lt_mov_line_rec(i)                        -- 移動明細ID
        AND ((xmrql.delete_flg = gv_yesno_n) OR (xmrql.delete_flg IS NULL)) -- 削除フラグ=未削除
        ;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END mov_results_quantity_set;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : パラメータチェック プロシージャ (A-0)
   ***********************************************************************************/
  PROCEDURE chk_param(
    iv_process_object_info  IN  VARCHAR2,            -- 処理対象情報
    iv_report_post          IN  VARCHAR2,            -- 報告部署
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- プログラム名
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
    cv_process_object_info   CONSTANT VARCHAR2(20) := '処理対象情報'; -- パラメータ名：処理対象情報
    cv_report_post           CONSTANT VARCHAR2(20) := '報告部署';     -- パラメータ名：報告部署
--
    -- *** ローカル変数 ***
    lv_process_object_info            VARCHAR2(2) := iv_process_object_info;   -- 処理対象情報
    lv_report_post                    VARCHAR2(4) := iv_report_post;           -- 報告部署
    ln_01_cnt                         NUMBER;                                 -- リーフ件数
    ln_02_cnt                         NUMBER;                                 -- ドリンク件数
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
    -- ***************************************
    -- ***     必須チェック(処理対象情報)    ***
    -- ***************************************
    --
    IF (lv_process_object_info IS NULL) THEN
--
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                     gv_msg_kbn,            -- アプリケーション短縮名：XXWSH
                     gv_msg_93a_001,        -- メッセージ：APP-XXWSH-13101 必須パラメータエラー
                     gv_tkn_item,           -- トークン：ITEM
                     cv_process_object_info -- パラメータ：処理対象情報
                   ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE parameter_expt;
--
    END IF;
--
    -- ***************************************
    -- ***      必須チェック(報告部署)     ***
    -- ***************************************
    --
    IF (lv_report_post IS NULL) THEN
--
      -- エラーメッセージ取得
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                     gv_msg_kbn,            -- アプリケーション短縮名：XXWSH
                     gv_msg_93a_001,        -- メッセージ：APP-XXWSH-13101 必須パラメータエラー
                     gv_tkn_item,           -- トークン：ITEM
                     cv_report_post         -- パラメータ：処理対象情報
                   ),1,5000);
      lv_errbuf := lv_errmsg;
--
      RAISE parameter_expt;
--
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN parameter_expt THEN                           --*** パラメータ例外 ***
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
  END chk_param;
--
 /**********************************************************************************
  * Procedure Name   : get_profile
  * Description      : プロファイル値取得 プロシージャ (A-1)
  ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- プログラム名
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
    lv_parge_period    VARCHAR2(100); -- パージ対象期間
    lv_master_org_id   VARCHAR2(100); -- 組織ID
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
    -- プロファイル「パージ対象期間」取得
    lv_parge_period := FND_PROFILE.VALUE(gv_purge_period_930);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_parge_period IS NULL) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg(
	                 gv_msg_kbn,               -- 'XXWSH'
                     gv_msg_93a_002,           -- プロファイル取得エラーメッセージ
                     gv_prof_token,            -- トークン'PROF_NAME'
                     gv_parge_period_jp);      -- パージ処理期間(入出庫実績インタフェース)
--
      lv_errbuf := lv_errmsg;
--
      RAISE global_api_expt;
--
    END IF;
--
    BEGIN
--
      gn_purge_period := TO_NUMBER(lv_parge_period);
--
    EXCEPTION
--
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       gv_msg_kbn,             -- 'XXWSH'
                       gv_msg_93a_002,         -- プロファイル取得エラーメッセージ
                       gv_prof_token,          -- トークン'PROF_NAME'
                       gv_parge_period_jp);    -- XXWSH:パージ処理期間(入出庫実績インタフェース)
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- プロファイル「システムプロファイル組織ID」取得
    gv_master_org_id := FND_PROFILE.VALUE(gv_master_org_id_type);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_master_org_id IS NULL) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg(
	                 gv_msg_kbn,               -- 'XXWSH'
                     gv_msg_93a_002,           -- プロファイル取得エラーメッセージ
                     gv_prof_token,            -- トークン'PROF_NAME'
                     gv_master_org_id_jp);     -- XXCMN:マスタ組織
      lv_errbuf := lv_errmsg;
--
      RAISE global_api_expt;
--
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END get_profile;
--
 /**********************************************************************************
  * Procedure Name   : purge_processing
  * Description      : パージ処理 プロシージャ (A-2)
  ***********************************************************************************/
  PROCEDURE purge_processing(
    iv_process_object_info  IN  VARCHAR2,            -- 処理対象情報
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'purge_processing'; -- プログラム名
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
    lv_no_lock          VARCHAR2(1);                         -- ロック取得ステータス
    In_not_cnt          NUMBER;                              -- IFヘッダ削除データ格納用カウント
    ln_count            NUMBER;                              -- IF明細存在データ件数格納
--
    -- *** ローカル・カーソル ***
    -- ファイルアップロードインタフェースデータ
    -- 時分秒(00:00:00)を考慮してパージ対象期間より-1日した期間を対象日付から引き作成日と比較を行う。
    CURSOR xshli_cur
    IS
      SELECT xshi.header_id
            ,xsli.line_id
      FROM   xxwsh_shipping_headers_if xshi   --IF_H
            ,xxwsh_shipping_lines_if   xsli   --IF_L
      WHERE  xsli.reserved_status = gv_reserved_status    --保留ステータス = 保留
      AND    xshi.header_id  = xsli.header_id
      AND    xshi.data_type = iv_process_object_info      --データタイプ
      AND    xshi.creation_date < (TRUNC(gd_sysdate) - (gn_purge_period -1))
      ORDER BY xshi.header_id,xsli.line_id
      FOR UPDATE OF xshi.header_id NOWAIT
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
    -- インタフェースデータ取得
    BEGIN
--
      -- ロック取得処理
      OPEN  xshli_cur;
--
    EXCEPTION
--
      WHEN check_lock_expt THEN  -- ロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn         -- 'XXWSH'
                                                       ,gv_msg_93a_003    -- テーブルロックエラー
                                                       ,gv_table_token    -- トークン'TABLE'
                                                       ,gv_if_table_jp)   -- 出荷依頼IFテーブル
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    -- 変数初期化
    In_not_cnt := 0;             -- IFヘッダ削除データ格納用カウント
    gr_line_not_header.delete;
    gr_header_id.delete;
    gr_line_id.delete;
--
    -- データの一括取得
    FETCH xshli_cur BULK COLLECT INTO gr_header_id,gr_line_id;
--
    gn_del_lines_cnt := gn_del_lines_cnt + gr_line_id.COUNT;
--
     -- 出荷依頼インタフェース明細(アドオン)削除
    <<if_purge_line_del_loop>>
    FORALL i IN 1 .. gr_line_id.COUNT
--
      DELETE FROM xxwsh_shipping_lines_if   xsli
      WHERE xsli.line_id = gr_line_id(i);
--
     -- IFヘッダ.ヘッダIDに紐づくIF明細データが存在するか否かの確認を行う。
     -- 存在しない場合、削除対象とする。
    <<if_purge_ifm_not_loop>>
    FOR i IN 1 .. gr_header_id.COUNT LOOP
      IF (i < gr_header_id.COUNT) THEN
        -- IF.ヘッダIDの比較
        IF ((gr_header_id(i)) <> (gr_header_id(i+1))) THEN
--
          -- IF明細存在チェックを行う。
          SELECT COUNT(xsli.line_id) cnt
          INTO   ln_count
          FROM   xxwsh_shipping_lines_if   xsli
          WHERE  xsli.header_id =  gr_header_id(i)
          ;
          -- 存在しない場合は、IFヘッダを削除対象し、削除データ格納領域に格納する。
          IF (ln_count = 0) THEN
--
             In_not_cnt :=In_not_cnt + 1;
             gr_line_not_header(In_not_cnt) := gr_header_id(i);
--
--********** 2008/07/07 ********** DELETE START ***
--*          gn_del_headers_cnt := gn_del_headers_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
          END IF;
--
        END IF;
--
      ELSE
        -- 最終データの処理
        -- IF明細存在チェックを行う。
        SELECT COUNT(xsli.line_id) cnt
        INTO   ln_count
        FROM   xxwsh_shipping_lines_if   xsli
        WHERE  xsli.header_id =  gr_header_id(i)
        ;
        -- 存在しない場合は、IFヘッダを削除対象し、削除データ格納領域に格納する。
        IF (ln_count = 0) THEN
--
           In_not_cnt :=In_not_cnt + 1;
           gr_line_not_header(In_not_cnt) := gr_header_id(i);
--
--********** 2008/07/07 ********** DELETE START ***
--*        gn_del_headers_cnt := gn_del_headers_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
        END IF;
--
      END IF;
--
    END LOOP if_purge_ifm_not_loop;
--
    -- 出荷依頼インタフェースヘッダ(アドオン)削除
    <<if_purge_headers_del_loop>>
    FORALL i IN 1 .. gr_line_not_header.COUNT
--
      DELETE FROM xxwsh_shipping_headers_if xshi  --IF_H
      WHERE xshi.header_id = gr_line_not_header(i);
--
    CLOSE xshli_cur;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( xshli_cur%ISOPEN ) THEN
        CLOSE xshli_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( xshli_cur%ISOPEN ) THEN
        CLOSE xshli_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( xshli_cur%ISOPEN ) THEN
        CLOSE xshli_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END purge_processing;
--
 /**********************************************************************************
  * Procedure Name   : get_warehouse_results_info
  * Description      : 外部倉庫入出庫実績情報抽出 プロシージャ (A-3)
  ***********************************************************************************/
  PROCEDURE get_warehouse_results_info(
    iv_process_object_info  IN  VARCHAR2,            -- 処理対象情報
    iv_report_post          IN  VARCHAR2,            -- 報告部署
    iv_object_warehouse     IN  VARCHAR2,            -- 対象倉庫
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_warehouse_results_info'; -- プログラム名
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
    lv_no_lock          VARCHAR2(1);        -- ロック取得ステータス
    In_not_cnt          NUMBER;             -- IFヘッダ削除データ格納用カウント
    ln_count            NUMBER;             -- IF明細存在データ件数格納
    lv_dspbuf           VARCHAR2(5000);     -- データ・ダンプ
    wk_sql              VARCHAR2(15000);
    ln_idx              NUMBER;             -- データindex
    lv_warn_flg         VARCHAR2(1);        -- 警告識別フラグ
--
    -- *** ローカル・カーソル ***
    -- 同一配送No-受注ソース参照-EOSデータ種別単位でプログラム更新日が最新の情報以外は削除
    CURSOR not_latest_request_id_cur
    IS
    SELECT  xshi_a.header_id                            --IF_H.ヘッダID
           ,xshi_a.request_id                           --IF_L.要求ID
    FROM    xxwsh_shipping_headers_if xshi_a            --IF_H
           ,xxwsh_shipping_lines_if   xsli_a            --IF_L
           ,(SELECT xshi.delivery_no                    --IF_H.配送No
                   ,xshi.order_source_ref               --IF_H.受注ソース参照
                   ,xshi.eos_data_type                  --IF_H.EOSデータ種別
                   ,MAX(xshi.program_update_date) max_program_update_date --IF_H.プログラム更新日
              FROM  xxwsh_shipping_headers_if  xshi     --IF_H
              GROUP BY xshi.delivery_no                 --IF_H.配送No
                      ,xshi.order_source_ref            --IF_H.受注ソース参照
                      ,xshi.eos_data_type               --IF_H.EOSデータ種別
            ) xshi_b
    WHERE   xshi_a.header_id = xsli_a.header_id
    AND     NVL(xshi_a.delivery_no,gv_delivery_no_null) = NVL(xshi_b.delivery_no,gv_delivery_no_null)
    AND     xshi_a.order_source_ref = xshi_b.order_source_ref
    AND     xshi_a.eos_data_type = xshi_b.eos_data_type
    AND     xshi_a.program_update_date <> xshi_b.max_program_update_date
    ORDER BY xshi_a.header_id
    FOR UPDATE OF xshi_a.header_id NOWAIT
    ;
--
    --IFヘッダは存在するが、IF明細が存在しない場合、警告をセットしログ出力します。
    CURSOR ifh_exists_ifm_not_cur
    IS
    SELECT xshi.header_id
          ,xshi.order_source_ref
    FROM   xxwsh_shipping_headers_if xshi
    WHERE NOT EXISTS (SELECT 'X'
                        FROM xxwsh_shipping_lines_if xsli
                       WHERE xshi.header_id = xsli.header_id)
    ;
--
    --IF明細は存在するが、ヘッダが存在しない場合、警告をセットしログ出力します。
    CURSOR ifm_exists_ifh_not_cur
    IS
    SELECT xsli.line_id
          ,xsli.header_id
    FROM   xxwsh_shipping_lines_if xsli
    WHERE NOT EXISTS (SELECT 'X'
                        FROM xxwsh_shipping_headers_if xshi
                       WHERE xshi.header_id = xsli.header_id)
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
    -- 変数初期化
    In_not_cnt := 0;
    gr_line_not_header.delete;
    gr_header_id.delete;
    gr_request_id.delete;
    gr_order_source_ref.delete;
--
    BEGIN
      -- =============================================================
      -- 同一配送No-受注ソース参照単位で要求IDが最新の情報以外は削除
      -- =============================================================
      -- ロック取得処理
      OPEN not_latest_request_id_cur;
--
    EXCEPTION
--
      WHEN check_lock_expt THEN  -- ロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn         -- 'XXWSH'
                                                       ,gv_msg_93a_003    -- テーブルロックエラー
                                                       ,gv_table_token    -- トークン'TABLE'
                                                       ,gv_if_table_jp)   -- 出荷依頼IFテーブル
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    -- データの一括取得
    FETCH not_latest_request_id_cur BULK COLLECT INTO gr_header_id,gr_request_id;
--
    gn_del_lines_cnt := gn_del_lines_cnt + gr_header_id.COUNT;
--
    -- 出荷依頼インタフェース明細(アドオン)削除
    <<not_latest_request_id_loop>>
    FORALL i IN 1 .. gr_header_id.COUNT
--
      DELETE FROM xxwsh_shipping_lines_if   xsli           --IF_L
      WHERE  xsli.header_id = gr_header_id(i)                 --IF_H.ヘッダID
      AND    xsli.request_id = gr_request_id(i)               --IF_L.要求ID
      ;
--
     -- IFヘッダ.ヘッダIDに紐づくIF明細データが存在するか否かの確認を行う。
     -- 存在しない場合、削除対象とする。
    <<if_purge_ifm_not_loop>>
    FOR i IN 1 .. gr_header_id.COUNT LOOP
--
      IF (i < gr_header_id.COUNT) THEN
        -- IF.ヘッダIDの比較
        IF ((gr_header_id(i)) <> (gr_header_id(i+1))) THEN
--
            In_not_cnt :=In_not_cnt + 1;
            gr_line_not_header(In_not_cnt) := gr_header_id(i);
--
--********** 2008/07/07 ********** DELETE START ***
--*         gn_del_headers_cnt := gn_del_headers_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
        END IF;
--
      ELSE
          -- 最終データの処理
          In_not_cnt :=In_not_cnt + 1;
          gr_line_not_header(In_not_cnt) := gr_header_id(i);
--
--********** 2008/07/07 ********** DELETE START ***
--*       gn_del_headers_cnt := gn_del_headers_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
      END IF;
--
    END LOOP if_purge_ifm_not_loop;
--
    -- 出荷依頼インタフェースヘッダ(アドオン)削除
    <<if_purge_headers_del_loop>>
    FORALL i IN 1 .. gr_line_not_header.COUNT
--
      DELETE FROM xxwsh_shipping_headers_if xshi  --IF_H
      WHERE xshi.header_id = gr_line_not_header(i);
--
    -- カーソルクローズ
    CLOSE not_latest_request_id_cur;
--
    -- =============================================================
    -- IFヘッダに存在するが、IF明細に存在しない場合
    -- 警告をセットしログ出力します。
    -- =============================================================
--
    gr_header_id.delete;
--
    OPEN ifh_exists_ifm_not_cur;
--
    -- データの一括取得
    FETCH ifh_exists_ifm_not_cur BULK COLLECT INTO gr_header_id,gr_order_source_ref;
--
    <<ifh_exists_ifm_not_loop>>
    FOR i IN 1 .. gr_header_id.COUNT LOOP
--
      lv_dspbuf := SUBSTRB( xxcmn_common_pkg.get_msg(
                     gv_msg_kbn          -- 'XXWSH'
                    ,gv_msg_93a_006 -- 出荷依頼インタフェース明細(アドオン)非存在エラーメッセージ
                    ,gv_param1_token     -- トークン'param1'
                    ,gr_header_id(i)     -- ヘッダID
                    ,gv_param2_token          -- トークン'param2'
                    ,gr_order_source_ref(i))  -- IF_H.受注ソース参照
                    ,1
                    ,5000);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
      lv_warn_flg := gv_status_warn;
--
    END LOOP ifh_exists_ifm_not_loop;
--
    -- カーソルクローズ
    CLOSE ifh_exists_ifm_not_cur;
--
    -- =============================================================
    -- IF明細に存在するが、IFヘッダが存在しない場合
    -- 警告をセットしログ出力します。
    -- =============================================================
--
    -- 初期化
    gr_line_id.delete;
    gr_header_id.delete;
--
    OPEN ifm_exists_ifh_not_cur;
--
    -- データの一括取得
    FETCH ifm_exists_ifh_not_cur BULK COLLECT INTO gr_line_id,gr_header_id;
--
    <<ifm_exists_ifh_not_loop>>
    FOR i IN 1 .. gr_line_id.COUNT LOOP
--
      lv_dspbuf := SUBSTRB( xxcmn_common_pkg.get_msg(
                     gv_msg_kbn          -- 'XXWSH'
                    ,gv_msg_93a_007 -- 出荷依頼インタフェースヘッダ(アドオン)非存在エラーメッセージ
                    ,gv_param1_token     -- トークン'param1'
                    ,gr_line_id(i)          -- 明細ID
                    ,gv_param2_token     -- トークン'param1'
                    ,gr_header_id(i))       -- ヘッダID
                    ,1
                    ,5000);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
      lv_warn_flg := gv_status_warn;
--
    END LOOP ifm_exists_ifh_not_loop;
--
    -- カーソルクローズ
    CLOSE ifm_exists_ifh_not_cur;
--
    -- =============================================================
    -- 外部倉庫入出庫実績情報取得
    -- =============================================================
    BEGIN
      -- ロック取得処理
      wk_sql := NULL;
      wk_sql := wk_sql || '  SELECT  ';
      wk_sql := wk_sql || '           xshi.party_site_code       AS party_site_code       ';  -- IF_H.出荷先
      wk_sql := wk_sql || '          ,xshi.freight_carrier_code  AS freight_carrier_code  ';  -- IF_H.運送業者
      wk_sql := wk_sql || '          ,xshi.shipping_method_code  AS shipping_method_code  ';  -- IF_H.配送区分
      wk_sql := wk_sql || '          ,xshi.cust_po_number        AS cust_po_number        ';  -- IF_H.顧客発注
      wk_sql := wk_sql || '          ,xshi.order_source_ref      AS order_source_ref      ';  -- IF_H.受注ソース参照
      wk_sql := wk_sql || '          ,xshi.delivery_no           AS delivery_no           ';  -- IF_H.配送No
      wk_sql := wk_sql || '          ,xshi.filler14              AS freight_charge_class  ';  -- IF_H.運賃区分
      wk_sql := wk_sql || '          ,xshi.collected_pallet_qty  AS collected_pallet_qty  ';  -- IF_H.パレット回収枚数
      wk_sql := wk_sql || '          ,xshi.location_code         AS location_code         ';  -- IF_H.出荷元
      wk_sql := wk_sql || '          ,xshi.arrival_time_from     AS arrival_time_from     ';  -- IF_H.着荷時間FROM
      wk_sql := wk_sql || '          ,xshi.arrival_time_to       AS arrival_time_to       ';  -- IF_H.着荷時間TO
      wk_sql := wk_sql || '          ,xshi.eos_data_type         AS eos_data_type         ';  -- IF_H.EOSデータ種別
      wk_sql := wk_sql || '          ,xshi.ship_to_location      AS ship_to_location      ';  -- IF_H.入庫倉庫
      wk_sql := wk_sql || '          ,xshi.shipped_date          AS shipped_date          ';  -- IF_H.出荷日
      wk_sql := wk_sql || '          ,xshi.arrival_date          AS arrival_date          ';  -- IF_H.着荷日
      wk_sql := wk_sql || '          ,xshi.order_type            AS order_type            ';  -- IF_H.受注タイプ
      wk_sql := wk_sql || '          ,xshi.used_pallet_qty       AS used_pallet_qty       ';  -- IF_H.パレット使用枚数
      wk_sql := wk_sql || '          ,xshi.report_post_code      AS report_post_code      ';  -- IF_H.報告部署
      wk_sql := wk_sql || '          ,xshi.header_id             AS header_id             ';  -- IF_H.ヘッダID
      wk_sql := wk_sql || '          ,xsli.line_id               AS line_id               ';  -- IF_L.明細ID
      wk_sql := wk_sql || '          ,xsli.line_number           AS line_number           ';  -- IF_L.明細番号
      wk_sql := wk_sql || '          ,xsli.orderd_item_code      AS orderd_item_code      ';  -- IF_L.受注品目
      wk_sql := wk_sql || '          ,xsli.orderd_quantity       AS orderd_quantity       ';  -- IF_L.数量
      wk_sql := wk_sql || '          ,xsli.shiped_quantity       AS shiped_quantity       ';  -- IF_L.出荷実績数量
      wk_sql := wk_sql || '          ,xsli.ship_to_quantity      AS ship_to_quantity      ';  -- IF_L.入庫実績数量
      wk_sql := wk_sql || '          ,xsli.lot_no                AS lot_no                ';  -- IF_L.ロットNo
      wk_sql := wk_sql || '          ,xsli.designated_production_date AS designated_production_date   ';  -- IF_L.製造日
      wk_sql := wk_sql || '          ,xsli.use_by_date           AS use_by_date           ';  -- IF_L.賞味期限
      wk_sql := wk_sql || '          ,xsli.original_character    AS original_character    ';  -- IF_L.固有記号
      wk_sql := wk_sql || '          ,xsli.detailed_quantity     AS detailed_quantity     ';  -- IF_L.内訳数量
      wk_sql := wk_sql || '          ,NULL                               ';  -- 品目区分
      wk_sql := wk_sql || '          ,NULL                               ';  -- 商品区分
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目情報VIEW2.ロット(ロット管理区分)
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目情報VIEW2.重量容積区分
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目情報VIEW2.品目ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目情報VIEW2.品目コード(品目)
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目情報VIEW2.ケース入数
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目情報VIEW2.入出庫換算単位
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目マスタ.単位(単位)
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目情報VIEW2.倉庫品目
      wk_sql := wk_sql || '          ,NULL                               ';  -- 顧客ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- 顧客
      wk_sql := wk_sql || '          ,NULL                               ';  -- 出荷先ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- 出荷先_実績ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- 運送業者ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- 運送業者_実績ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- ロットID
      wk_sql := wk_sql || '          ,NULL                               ';  -- 出荷元ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- 出庫元ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- 入庫先ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- 出荷引当対象フラグ
      wk_sql := wk_sql || '          ,NULL                               ';  -- 管轄拠点
      wk_sql := wk_sql || '          ,NULL                               ';  -- 仕入先サイトID
      wk_sql := wk_sql || '          ,NULL                               ';  -- 仕入先ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- 仕入先サイト名
      wk_sql := wk_sql || '          ,''' || gv_flg_off || ''''           ;  -- 外部倉庫flag
      wk_sql := wk_sql || '          ,''' || gv_flg_off || ''''           ;  -- エラーflag
      wk_sql := wk_sql || '          ,''' || gv_flg_off || ''''           ;  -- 保留flag
      wk_sql := wk_sql || '          ,''' || gv_flg_off || ''''           ;  -- ログのみ出力flag
      wk_sql := wk_sql || '          ,NULL                               ';  -- メッセージ
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目情報VIEW2.INV品目ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目情報VIEW2.INV品目ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM品目情報VIEW2.INV品目(倉庫品目)
      wk_sql := wk_sql || '          ,NULL                               ';  -- 顧客区分(出荷先)
      wk_sql := wk_sql || '     FROM  ';
      wk_sql := wk_sql || '           xxwsh_shipping_headers_if   xshi       ';  -- IF_H
      wk_sql := wk_sql || '           ,xxwsh_shipping_lines_if    xsli       ';  -- IF_L
      wk_sql := wk_sql || '     WHERE ';
      wk_sql := wk_sql || '           xshi.header_id = xsli.header_id        ';
      wk_sql := wk_sql || '     AND   xshi.data_type =  '''       || iv_process_object_info || '''';  -- IF_H.データタイプ＝パラメータ.処理対象情報
      IF TRIM(iv_report_post) IS NOT NULL THEN
        wk_sql := wk_sql || '     AND   xshi.report_post_code = ''' || iv_report_post || '''';          -- IF_H.報告部署＝パラメータ.報告部署
      END IF;
         --200:有償出荷報告,210:拠点出荷確定報告,215:庭先出荷確定報告,220:移動出庫確定報告  の場合、
         --IF_H.出荷元=パラメータ.対象倉庫
      wk_sql := wk_sql || '     AND  ((xshi.eos_data_type = ''' || gv_eos_data_cd_200 || ''')';
      wk_sql := wk_sql || '      OR  (xshi.eos_data_type = ''' || gv_eos_data_cd_210 || ''')';
      wk_sql := wk_sql || '      OR  (xshi.eos_data_type = ''' || gv_eos_data_cd_215 || ''')';
      wk_sql := wk_sql || '      OR  (xshi.eos_data_type = ''' || gv_eos_data_cd_220 || ''')';
      wk_sql := wk_sql || '      OR  (xshi.eos_data_type = ''' || gv_eos_data_cd_230 || '''))';
         --IF_H.出荷元=パラメータ.対象倉庫
      IF TRIM(iv_object_warehouse) IS NOT NULL THEN
        wk_sql := wk_sql || '   AND  (xshi.location_code = ''' || iv_object_warehouse || ''')';
      END IF;
      wk_sql := wk_sql || '  ORDER BY ';
      wk_sql := wk_sql || '           delivery_no ';        -- IF H.配送No
      wk_sql := wk_sql || '          ,order_source_ref ';   -- IF_H.受注ソース参照
      wk_sql := wk_sql || '          ,eos_data_type ';      -- IF_H.EOSデータ種別
      wk_sql := wk_sql || '          ,header_id ';          -- IF_L.ヘッダID
      wk_sql := wk_sql || '          ,orderd_item_code ';   -- IF_L.受注品目
      wk_sql := wk_sql || '          ,lot_no ';             -- IF_L.ロットNo
      wk_sql := wk_sql || '  FOR UPDATE OF xsli.line_id,xshi.header_id NOWAIT ';
--
      EXECUTE IMMEDIATE wk_sql BULK COLLECT INTO gr_interface_info_rec ;
--
    EXCEPTION
--
      WHEN check_lock_expt THEN  -- ロックできなかった
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn         -- 'XXWSH'
                                                       ,gv_msg_93a_003    -- テーブルロックエラー
                                                       ,gv_table_token    -- トークン'TABLE'
                                                       ,gv_if_table_jp)   -- 出荷依頼IFテーブル
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    -- 処理件数のセット
    gn_target_cnt := gr_interface_info_rec.COUNT;
--
    -- データがなかった場合は終了ステータスをエラーとし処理を中止する
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn        -- 'XXWSH'
                                                    ,gv_msg_93a_004    -- 対象データなし
                                                    ,NULL              -- トークン なし
                                                    ,NULL)             --  なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
--
    END IF;
--
    <<get_master_data_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      ln_idx := i;
      --------------------------
      -- マスタ(view)データ取得
      --------------------------
      master_data_get(
        ln_idx,                   -- データindex
        lv_errbuf,                -- エラー・メッセージ           --# 固定 #
        lv_retcode,               -- リターン・コード             --# 固定 #
        lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
       );
--
       IF (lv_retcode = gv_status_error) THEN
         RAISE global_api_expt;
       END IF;
--
    END LOOP get_master_data_loop;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
    IF (lv_warn_flg = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
--
      -- *** 任意で例外処理を記述する ****
    WHEN no_data_expt THEN                      --*** 対象データなし ***
      ov_errmsg  := lv_errmsg;                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( not_latest_request_id_cur%ISOPEN ) THEN
        CLOSE not_latest_request_id_cur;
      END IF;
      IF ( ifh_exists_ifm_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
      IF ( ifm_exists_ifh_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( not_latest_request_id_cur%ISOPEN ) THEN
        CLOSE not_latest_request_id_cur;
      END IF;
      IF ( ifh_exists_ifm_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
      IF ( ifm_exists_ifh_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( not_latest_request_id_cur%ISOPEN ) THEN
        CLOSE not_latest_request_id_cur;
      END IF;
      IF ( ifh_exists_ifm_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
      IF ( ifm_exists_ifh_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_warehouse_results_info;
--
 /**********************************************************************************
  * Procedure Name   : out_warehouse_number_check
  * Description      : 外部倉庫発番チェック プロシージャ (A-4)
  ***********************************************************************************/
  PROCEDURE out_warehouse_number_check(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_warehouse_number_check'; -- プログラム名
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
    ln_count NUMBER;
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
    <<out_warehouse_number_check>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      -- 業務種別判定
      -- EOSデータ種別 = 200 有償出荷報告, 210 拠点出荷確定報告, 215 庭先出荷確定報告, 220 移動出庫確定報告
      -- 適用開始日・終了日を出荷日にて判定
      IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
          (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
          (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
          (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
      THEN
--
        -- OPM保管場所マスタ／保管倉庫コードよりチェック
        SELECT COUNT(xilv2.inventory_location_id) cnt
        INTO   ln_count
        FROM   xxcmn_item_locations2_v xilv2
        WHERE  xilv2.segment1 = SUBSTRB(gr_interface_info_rec(i).order_source_ref, 1, 4)
        AND    xilv2.date_from  <=  TRUNC(gr_interface_info_rec(i).shipped_date) -- 組織有効開始日
        AND    ((xilv2.date_to IS NULL)
         OR    (xilv2.date_to >= TRUNC(gr_interface_info_rec(i).shipped_date)))  -- 組織有効終了日
        AND    xilv2.disable_date IS NULL   -- 無効日
        ;
--
      END IF;
--
      -- EOSデータ種別 = 230:移動入庫確定報告
      -- 適用開始日・終了日を着荷日にて判定
      IF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
        -- OPM保管場所マスタ／保管倉庫コードよりチェック
        SELECT COUNT(xilv2.inventory_location_id) cnt
        INTO   ln_count
        FROM   xxcmn_item_locations2_v xilv2
        WHERE  xilv2.segment1 = SUBSTRB(gr_interface_info_rec(i).order_source_ref, 1, 4)
        AND    xilv2.date_from  <=  TRUNC(gr_interface_info_rec(i).arrival_date) -- 組織有効開始日
        AND    ((xilv2.date_to IS NULL)
         OR    (xilv2.date_to >= TRUNC(gr_interface_info_rec(i).arrival_date)))  -- 組織有効終了日
        AND    xilv2.disable_date IS NULL   -- 無効日
        ;
--
      END IF;
--
      -- 存在する場合は、外部倉庫発番となる
      IF (ln_count > 0) THEN
--
        gr_interface_info_rec(i).out_warehouse_flg := gv_flg_on;
--
      END IF;
--
    END LOOP out_warehouse_number_check;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END out_warehouse_number_check;
--
 /**********************************************************************************
  * Procedure Name   : err_chk_delivno
  * Description      : エラーチェック_配送No単位 プロシージャ (A-5-1)
  ***********************************************************************************/
  PROCEDURE err_chk_delivno(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_chk_delivno'; -- プログラム名
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
    lt_delivery_no          xxwsh_shipping_headers_if.delivery_no%TYPE;          --IF_H.配送No
    lt_order_source_ref     xxwsh_shipping_headers_if.order_source_ref%TYPE;     --IF_H.受注ソース参照
    lt_freight_carrier_code xxwsh_shipping_headers_if.freight_carrier_code%TYPE; --IF_H.運送業者
    lt_shipping_method_code xxwsh_shipping_headers_if.shipping_method_code%TYPE; --IF_H.配送区分
    lt_shipped_date         xxwsh_shipping_headers_if.shipped_date%TYPE;         --IF_H.出荷日
    lt_arrival_date         xxwsh_shipping_headers_if.arrival_date%TYPE;         --IF_H.着荷日
    lt_freight_charge_class xxwsh_shipping_headers_if.filler14%TYPE;             --IF_H.運賃区分
    lv_msg_buff             VARCHAR2(5000);
    lv_dterr_flg            VARCHAR2(1) := '0';
    lv_date_msg             VARCHAR2(15);
    lv_error_flg            VARCHAR2(1);                          --エラーflag
    ln_err_flg              NUMBER := 0;
--
    lt_product_date         ic_lots_mst.attribute1%TYPE;          --IF_L.製造年月日
    lt_expiration_day       ic_lots_mst.attribute3%TYPE;          --IF_L.賞味期限
    lt_original_sign        ic_lots_mst.attribute2%TYPE;          --IF_L.固有記号
    lt_lot_no               ic_lots_mst.lot_no%TYPE;              --IF_L.ロットNo
    lt_lot_id               ic_lots_mst.lot_id%TYPE;              --IF_L.ロットid
    ld_search_date          DATE;                                 --IF_H.出荷日or着荷日
--
    ln_count                NUMBER;                               -- ロットマスタデータ件数格納 
--
    lv_search_product_date  ic_lots_mst.attribute1%TYPE;          --IF_L.製造年月日
    ln_warehouse_count      NUMBER;
    ln_data_count           NUMBER;
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
    --同一配送Noで複数の移動No(依頼No)をもつレコードの値チェック
    --運送業者
    --配送区分
    --出荷日
    --着荷日
    --が異なるレコードが存在する場合エラーとします。
    <<deliveryno_many_move_id>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      lt_delivery_no          := gr_interface_info_rec(i).delivery_no;           --IF_H.配送No
      lt_freight_carrier_code := gr_interface_info_rec(i).freight_carrier_code;  --IF_H.運送業者
      lt_shipping_method_code := gr_interface_info_rec(i).shipping_method_code;  --IF_H.配送区分
      lt_shipped_date         := gr_interface_info_rec(i).shipped_date;          --IF_H.出荷日
      lt_arrival_date         := gr_interface_info_rec(i).arrival_date;          --IF_H.着荷日
      lt_freight_charge_class := NVL(gr_interface_info_rec(i).freight_charge_class,gv_include_exclude_0);  --IF_H.運賃区分
      lv_error_flg            := gr_interface_info_rec(i).err_flg;               -- エラーフラグ
      lt_order_source_ref     := gr_interface_info_rec(i).order_source_ref;      --受注ソース参照(依頼/移動No)
--
      IF (lv_error_flg = '0') THEN
--
        ln_err_flg := 0;
--
        -- 配送Noが設定されていた場合、受注ソースと配送Noの発番内容をチェック
        IF (gr_interface_info_rec(i).delivery_no IS NOT NULL)
        THEN
          -- 業務種別判定
          -- EOSデータ種別 = 200 有償出荷報告, 210 拠点出荷確定報告, 215 庭先出荷確定報告, 220 移動出庫確定報告
          -- 適用開始日・終了日を出荷日にて判定
          IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
          THEN
            -- 出荷日をセットします。
            ld_search_date := gr_interface_info_rec(i).shipped_date;
--
          -- EOSデータ種別 = 230:移動入庫確定報告
          ELSE
            -- 着荷日をセットします。
            ld_search_date := gr_interface_info_rec(i).arrival_date;
--
          END IF;
--
          -- OPM保管場所マスタ／保管倉庫コードよりチェック
          SELECT COUNT(xilv2.inventory_location_id) cnt
          INTO   ln_warehouse_count
          FROM   xxcmn_item_locations2_v xilv2
          WHERE  xilv2.segment1 = SUBSTRB(gr_interface_info_rec(i).delivery_no, 1, 4)
          AND    xilv2.date_from  <=  TRUNC(ld_search_date) -- 出荷or着荷日
          AND    ((xilv2.date_to IS NULL)
           OR    (xilv2.date_to >= TRUNC(ld_search_date)))  -- 出荷or着荷日
          AND    xilv2.disable_date IS NULL   -- 無効日
          ;
--
          -- 受注ソース（業者発番）と配送No            の矛盾がある為、エラー
          -- 受注ソース            と配送No（業者発番）の矛盾がある為、エラー
          IF ((ln_warehouse_count = 0) AND (gr_interface_info_rec(i).out_warehouse_flg =  gv_flg_on)) OR
             ((ln_warehouse_count > 0) AND (gr_interface_info_rec(i).out_warehouse_flg <> gv_flg_on)) 
          THEN
--
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                 -- 'XXWSH'
                          ,gv_msg_93a_153                             -- 配送No-依頼/移動No関連エラーメッセージ
                          ,gv_param1_token
                          ,gr_interface_info_rec(i).delivery_no       -- IF_H.配送No
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).order_source_ref  -- IF_H.受注ソース参照(依頼/移動No)
                                                             )
                                                             ,1
                                                             ,5000);
--
            --配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
            set_header_unit_reserveflg(
              gr_interface_info_rec(i).delivery_no,         -- 配送No
              gr_interface_info_rec(i).order_source_ref,    -- 受注ソース参照(依頼/移動No)
              gr_interface_info_rec(i).eos_data_type,       -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- 実績計上／訂正処理が可能なデータが存在するかチェック
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        ln_err_flg := 0;
--
        -- 外部倉庫（指示なし）以外の場合、処理可能なデータが存在するかチェックを行う。
        IF (gr_interface_info_rec(i).out_warehouse_flg <> gv_flg_on)
        THEN
--
          -- 出荷or支給
          IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR        -- 拠点出荷確定報告
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR        -- 庭先出荷確定報告
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200))          -- 有償出荷報告
          THEN
--
            SELECT COUNT(xoha.request_no) item_cnt
            INTO   ln_data_count
            FROM   xxwsh_order_headers_all xoha
            -- 受注H.依頼No=抽出項目:受注ソース参照
            WHERE  xoha.request_no = gr_interface_info_rec(i).order_source_ref
            -- 出荷：締め済み or 出荷実績計上済　支給：受領済 or 支給実績計上済
            AND    xoha.req_status IN(gv_req_status_03,gv_req_status_04,gv_req_status_07,gv_req_status_08)
            AND    xoha.notif_status = gv_notif_status_40  -- 確定通知済
            AND    xoha.latest_external_flag = gv_yesno_y  -- 最新フラグ
            ;
--
          -- 移動
          ELSE
--
            SELECT COUNT(xmrih.mov_num) item_cnt
            INTO   ln_data_count
            FROM   xxinv_mov_req_instr_headers xmrih
            --移動H.移動番号=抽出項目:受注ソース参照
            WHERE  xmrih.mov_num = gr_interface_info_rec(i).order_source_ref
            --依頼済 or 調整中 or 出庫報告有 or 入庫報告有 or 入出庫報告有
            AND    xmrih.status IN(gv_mov_status_02,gv_mov_status_03,gv_mov_status_04,gv_mov_status_05,gv_mov_status_06)
            AND    xmrih.notif_status = gv_notif_status_40 --確定通知済
            ;
--
          END IF;
--
          --処理可能な指示データが存在しない場合、エラー
          IF (ln_data_count = 0) THEN
--
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                 -- 'XXWSH'
                          ,gv_msg_93a_154                             -- 実績計上／訂正不可エラーメッセージ
                          ,gv_param1_token
                          ,gr_interface_info_rec(i).delivery_no       -- IF_H.配送No
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).order_source_ref  -- IF_H.受注ソース参照(依頼/移動No)
                                                             )
                                                             ,1
                                                             ,5000);
--
            --配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
            set_header_unit_reserveflg(
              gr_interface_info_rec(i).delivery_no,         -- 配送No
              gr_interface_info_rec(i).order_source_ref,    -- 受注ソース参照(依頼/移動No)
              gr_interface_info_rec(i).eos_data_type,       -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        ln_err_flg := 0;
--
        -- 以下組み合わせ以外をエラーとする
        -- ・配送No＝NULL、運賃区分＝対象外(0)
        -- ・配送No≠NULL、運賃区分＝対象  (1)
        IF NOT ((lt_delivery_no IS NULL)     AND (lt_freight_charge_class = gv_include_exclude_0)  OR
                (lt_delivery_no IS NOT NULL) AND (lt_freight_charge_class = gv_include_exclude_1)) THEN
--
          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                                 -- 'XXWSH'
                        ,gv_msg_93a_148                             -- 配送No-運賃区分組合せエラーメッセージ
                        ,gv_param1_token
                        ,lt_delivery_no                             -- IF_H.配送No
                        ,gv_param2_token
                        ,gr_interface_info_rec(i).order_source_ref  -- IF_H.受注ソース参照(依頼/移動No)
                        ,gv_param3_token
                        ,lt_freight_charge_class                    -- IF_H.運賃区分
                                                           )
                                                           ,1
                                                           ,5000);
--
          --配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
          set_header_unit_reserveflg(
            lt_delivery_no,         -- 配送No
            lt_order_source_ref,    -- 受注ソース参照(依頼/移動No)
            gr_interface_info_rec(i).eos_data_type,  -- EOSデータ種別
            gv_err_class,           -- エラー種別：エラー
            lv_msg_buff,            -- エラー・メッセージ(出力用)
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          -- エラーフラグ
          ln_err_flg := 1;
          -- 処理ステータス：警告
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
      --ロット管理品の必須チェック
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        ln_err_flg := 0;
--
        -- チェック対象はロット管理品
        IF (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1) THEN   --ロット:有(ロット管理品)
--
        -- 以下のパターンで必須項目に値がない場合、エラーとする
        -- ・商品区分＝リーフ   且つ 品目区分＝製品：                 IF_L.賞味期限 且つ IF_L.固有記号 が必須
        -- ・商品区分＝ドリンク 且つ 品目区分＝製品：IF_L.製造日 且つ IF_L.賞味期限 且つ IF_L.固有記号 が必須
        -- ・                        品目区分≠製品：IF_L.ロットNo が必須
          IF  ((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_1)       AND   --商品区分:リーフ
               (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5)       AND   --品目区分＝製品
               ((gr_interface_info_rec(i).use_by_date IS NULL)                 OR    --賞味期限
                (gr_interface_info_rec(i).original_character IS NULL)))              --固有記号
             OR
              ((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_2)       AND   --商品区分:ドリンク
               (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5)       AND   --品目区分＝製品
               ((gr_interface_info_rec(i).designated_production_date IS NULL)  OR    --製造日
                (gr_interface_info_rec(i).use_by_date IS NULL)                 OR    --賞味期限
                (gr_interface_info_rec(i).original_character IS NULL)))              --固有記号
             OR
              ((gr_interface_info_rec(i).item_kbn_cd <> gv_item_kbn_cd_5)      AND   --品目区分≠製品
               (gr_interface_info_rec(i).lot_no IS NULL))                            --ロットNo
          THEN
--
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                 -- 'XXWSH'
                          ,gv_msg_93a_149                             -- ロット管理品の必須項目未設定エラー
                          ,gv_param1_token
                          ,lt_delivery_no                             -- IF_H.配送No
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).order_source_ref  -- IF_H.受注ソース参照(依頼/移動No)
                                                             )
                                                             ,1
                                                             ,5000);
--
            --配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
            set_header_unit_reserveflg(
              lt_delivery_no,         -- 配送No
              lt_order_source_ref,    -- 受注ソース参照(依頼/移動No)
              gr_interface_info_rec(i).eos_data_type,  -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
      --ロットマスタより情報取得
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        ln_err_flg := 0;
--
        -- 対象はロット管理品
        IF (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1) THEN   --ロット:有(ロット管理品)
--
          -- 検索に使用する日付を設定
          IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR  -- 有償出荷報告
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR  -- 拠点出荷確定報告
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR  -- 庭先出荷確定報告
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))    -- 移動出庫確定報告
          THEN
--
            -- IF_H.出荷日を設定
            ld_search_date := gr_interface_info_rec(i).shipped_date;
--
          ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN  -- 移動入庫確定報告
--
            -- IF_H.着荷日を設定
            ld_search_date := gr_interface_info_rec(i).arrival_date;
--
          END IF;
--
          -- 条件に該当する件数を取得
          -- 商品区分＝リーフ  、品目区分＝製品：            賞味期限、固有記号がKEY
          -- 商品区分＝ドリンク、品目区分＝製品：製造年月日、賞味期限、固有記号がKEY
          --                     品目区分≠製品：ロットNoがKEY
          SELECT COUNT(ilm.lot_id) cnt
          INTO   ln_count
          FROM   ic_lots_mst ilm,
                 xxcmn_item_mst2_v ximv
          WHERE  ximv.item_id   = ilm.item_id                                -- 品目id
          AND    ximv.item_no   = gr_interface_info_rec(i).orderd_item_code  -- 受注品目
          AND    ximv.lot_ctl   = gv_lotkr_kbn_cd_1                          -- ロット管理品
          AND    ((gr_interface_info_rec(i).designated_production_date IS NULL)   -- 製造年月日
                  OR
                  ((gr_interface_info_rec(i).designated_production_date IS NOT NULL)
                   AND (ilm.attribute1 = TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD'))))
          AND    ((gr_interface_info_rec(i).use_by_date IS NULL)                  -- 賞味期限
                  OR
                  ((gr_interface_info_rec(i).use_by_date IS NOT NULL)
                  AND (ilm.attribute3 = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD'))))
          AND    ilm.attribute2 = NVL(gr_interface_info_rec(i).original_character,ilm.attribute2) -- 固有記号   
          AND    ilm.lot_no     = NVL(gr_interface_info_rec(i).lot_no,ilm.lot_no)                 -- ロットNo
          AND    ximv.inactive_ind      <> gn_view_disable             -- 無効フラグ
          AND    ximv.obsolete_class    <> gv_view_disable             -- 廃止区分
          AND    ximv.start_date_active <= TRUNC(ld_search_date)       -- 出荷/着荷日
          AND    ximv.end_date_active   >= TRUNC(ld_search_date)       -- 出荷/着荷日
          ;
--
          -- 下の値取得ＳＱＬのKEYに使用するためセット
          IF (gr_interface_info_rec(i).designated_production_date IS NULL)
          THEN
--
            lv_search_product_date := NULL;
          ELSE
--
            lv_search_product_date := TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD');
          END IF;
--
          -- 検索結果が0件の場合
          IF (ln_count = 0) THEN
--
            -- リーフ製品の場合、製造年月日を検索KEYより外して再検索
            IF  ((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_1)       AND   --商品区分:リーフ
                 (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5))            --品目区分＝製品
            THEN
--
              SELECT COUNT(ilm.lot_id) cnt
              INTO   ln_count
              FROM   ic_lots_mst ilm,
                     xxcmn_item_mst2_v ximv
              WHERE  ximv.item_id   = ilm.item_id                                -- 品目id
              AND    ximv.item_no   = gr_interface_info_rec(i).orderd_item_code  -- 受注品目
              AND    ximv.lot_ctl   = gv_lotkr_kbn_cd_1                          -- ロット管理品
              AND    ((gr_interface_info_rec(i).use_by_date IS NULL)             -- 賞味期限
                      OR
                      ((gr_interface_info_rec(i).use_by_date IS NOT NULL)
                      AND (ilm.attribute3 = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD'))))
              AND    ilm.attribute2 = NVL(gr_interface_info_rec(i).original_character,ilm.attribute2) -- 固有記号   
              AND    ilm.lot_no     = NVL(gr_interface_info_rec(i).lot_no,ilm.lot_no)                 -- ロットNo
              AND    ximv.inactive_ind      <> gn_view_disable             -- 無効フラグ
              AND    ximv.obsolete_class    <> gv_view_disable             -- 廃止区分
              AND    ximv.start_date_active <= TRUNC(ld_search_date)       -- 出荷/着荷日
              AND    ximv.end_date_active   >= TRUNC(ld_search_date)       -- 出荷/着荷日
              ;
--
              -- 下の値取得ＳＱＬのKEYに使用するためリセット
              lv_search_product_date := NULL;
--
            END IF;
--
          END IF;
--
          IF (ln_count = 0) THEN
--
            -- データが取得できなかった場合
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                           -- 'XXWSH'
                          ,gv_msg_93a_150                                       -- ロットマスタ取得エラー
                          ,gv_param1_token
                          ,lt_delivery_no                                       -- IF_H.配送No
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).order_source_ref            -- IF_H.受注ソース参照(依頼/移動No)
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).orderd_item_code            -- IF_L.受注品目
                          ,gv_param4_token
                          ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  -- IF_L.製造日
                          ,gv_param5_token
                          ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 -- IF_L.賞味期限
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).original_character          -- IF_L.固有記号
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).lot_no                      -- IF_L.ロットNo
                                                             )
                                                             ,1
                                                             ,5000);
--
            --配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
            set_header_unit_reserveflg(
              lt_delivery_no,         -- 配送No
              lt_order_source_ref,    -- 受注ソース参照(依頼/移動No)
              gr_interface_info_rec(i).eos_data_type,  -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          ELSIF(ln_count > 1) THEN
--
            -- 複数件取得した場合
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn                                           -- 'XXWSH'
                            ,gv_msg_93a_151                                       -- ロットマスタ取得複数件エラー
                            ,gv_param1_token
                            ,lt_delivery_no                                       -- IF_H.配送No
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).order_source_ref            -- IF_H.受注ソース参照(依頼/移動No)
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).orderd_item_code            -- IF_L.受注品目
                            ,gv_param4_token
                            ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  -- IF_L.製造日
                            ,gv_param5_token
                            ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 -- IF_L.賞味期限
                            ,gv_param6_token
                            ,gr_interface_info_rec(i).original_character          -- IF_L.固有記号
                            ,gv_param7_token
                            ,gr_interface_info_rec(i).lot_no                      -- IF_L.ロットNo
                                                               )
                                                               ,1
                                                               ,5000);
--
            --配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
            set_header_unit_reserveflg(
              lt_delivery_no,         -- 配送No
              lt_order_source_ref,    -- 受注ソース参照(依頼/移動No)
              gr_interface_info_rec(i).eos_data_type,  -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          ELSE
--
            -- 1件だった場合、ロットマスタの登録情報を取得
            SELECT ilm.attribute1  product_date    -- 製造年月日
                  ,ilm.attribute3  expiration_day  -- 賞味期限
                  ,ilm.attribute2  original_sign   -- 固有記号
                  ,ilm.lot_no      lot_no          -- ロットNo 
                  ,ilm.lot_id      lot_id          -- ロットID
            INTO   lt_product_date
                  ,lt_expiration_day
                  ,lt_original_sign
                  ,lt_lot_no
                  ,lt_lot_id
            FROM   ic_lots_mst ilm,
                   xxcmn_item_mst2_v ximv
            WHERE  ximv.item_id   = ilm.item_id                                -- 品目id
            AND    ximv.item_no   = gr_interface_info_rec(i).orderd_item_code  -- 受注品目
            AND    ximv.lot_ctl   = gv_lotkr_kbn_cd_1                          -- ロット管理品
            AND    ((lv_search_product_date IS NULL)   -- 製造年月日
                    OR
                    ((lv_search_product_date IS NOT NULL)
                     AND (ilm.attribute1 = lv_search_product_date)))
            AND    ((gr_interface_info_rec(i).use_by_date IS NULL)                  -- 賞味期限
                    OR
                    ((gr_interface_info_rec(i).use_by_date IS NOT NULL)
                    AND (ilm.attribute3 = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD'))))
            AND    ilm.attribute2 = NVL(gr_interface_info_rec(i).original_character,ilm.attribute2) -- 固有記号   
            AND    ilm.lot_no     = NVL(gr_interface_info_rec(i).lot_no,ilm.lot_no)                 -- ロットNo
            AND    ximv.inactive_ind      <> gn_view_disable             -- 無効フラグ
            AND    ximv.obsolete_class    <> gv_view_disable             -- 廃止区分
            AND    ximv.start_date_active <= TRUNC(ld_search_date)       -- 出荷/着荷日
            AND    ximv.end_date_active   >= TRUNC(ld_search_date)       -- 出荷/着荷日
            ;
--
            IF (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5) THEN
--
              -- 品目区分＝製品の場合、ロットNoを取得
              gr_interface_info_rec(i).lot_no := lt_lot_no ;  -- ロットNo
              gr_interface_info_rec(i).lot_id := lt_lot_id ;  -- ロットID
--
            ELSE
--
              -- 品目区分≠製品の場合、製造日／賞味期限／固有記号を取得
              gr_interface_info_rec(i).designated_production_date := FND_DATE.STRING_TO_DATE(lt_product_date,'YYYY/MM/DD') ;    -- 製造日
              gr_interface_info_rec(i).use_by_date                := FND_DATE.STRING_TO_DATE(lt_expiration_day,'YYYY/MM/DD') ;  -- 賞味期限
              gr_interface_info_rec(i).original_character         := lt_original_sign ;            -- 固有記号
              gr_interface_info_rec(i).lot_id                     := lt_lot_id ;                   -- ロットID
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      --出荷日／着荷日の未来日付チェック
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        ln_err_flg := 0;
--
        IF ((TRUNC(lt_shipped_date) > TRUNC(gd_sysdate)) AND (TRUNC(lt_arrival_date) > TRUNC(gd_sysdate))) THEN
--
          lv_dterr_flg := gv_date_chk_3;
--
        ELSIF (TRUNC(lt_shipped_date) > TRUNC(gd_sysdate)) THEN
--
          lv_dterr_flg := gv_date_chk_1;
--
        ELSIF (TRUNC(lt_arrival_date) > TRUNC(gd_sysdate)) THEN
--
          lv_dterr_flg := gv_date_chk_2;
--
        END IF;
--
        IF (lv_dterr_flg <> gv_date_chk_0) THEN
--
          CASE lv_dterr_flg
            WHEN gv_date_chk_1 THEN
              lv_date_msg := gv_date_para_1;
            WHEN gv_date_chk_2 THEN
              lv_date_msg := gv_date_para_2;
            WHEN gv_date_chk_3 THEN
              lv_date_msg := gv_date_para_1 || '/' || gv_date_para_2;
          END CASE;
--
          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn         -- 'XXWSH'
                        ,gv_msg_93a_143     -- 未来日エラーメッセージ
                        ,gv_date_token
                        ,lv_date_msg
                        ,gv_param1_token
                        ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                        ,gv_param2_token
                        ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                        ,gv_param3_token
                        ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')  --IF_H.出荷日
                        ,gv_param4_token
                        ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')  --IF_H.着荷日
                                                           )
                                                           ,1
                                                           ,5000);
--
          --配送NO-EOSデータ種別単位にエラーflagセット
          set_deliveryno_unit_errflg(
            lt_delivery_no,         -- 配送No
            gr_interface_info_rec(i).eos_data_type,  -- EOSデータ種別
            gv_err_class,           -- エラー種別：エラー
            lv_msg_buff,            -- エラー・メッセージ(出力用)
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          -- エラーフラグ
          ln_err_flg := 1;
          -- 処理ステータス：警告
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
--
--
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        --チェック有無をIF_H.運賃区分で判定
        IF (lt_freight_charge_class = gv_include_exclude_1) THEN
--
          IF (i >= 2) THEN

            --IF_H.配送Noの同一チェック
            IF (lt_delivery_no = gr_interface_info_rec(i-1).delivery_no) THEN
--
              IF ((lt_freight_carrier_code <> gr_interface_info_rec(i-1).freight_carrier_code) OR --IF_H.運送業者
                  (lt_shipping_method_code <> gr_interface_info_rec(i-1).shipping_method_code) OR --IF_H.配送区分
                  (lt_shipped_date         <> gr_interface_info_rec(i-1).shipped_date)         OR --IF_H.出荷日
                  (lt_arrival_date         <> gr_interface_info_rec(i-1).arrival_date))           --IF_H.着荷日
              THEN
--
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn         -- 'XXWSH'
                              ,gv_msg_93a_009  -- 同一配送Noレコード値チェックエラーメッセージ
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                              ,gv_param6_token
                              ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')          --IF_H.出荷日
                              ,gv_param7_token
                              ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')          --IF_H.着荷日
                              ,gv_param8_token
                              ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                              ,gv_param9_token
                              ,gr_interface_info_rec(i).item_kbn_cd           --品目区分
                                                                 )
                                                                 ,1
                                                                 ,5000);
--
                --配送NO-EOSデータ種別単位にエラーflagセット
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- 配送No
                  gr_interface_info_rec(i).eos_data_type,  -- EOSデータ種別
                  gv_err_class,           -- エラー種別：エラー
                  lv_msg_buff,            -- エラー・メッセージ(出力用)
                  lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                  lv_retcode,             -- リターン・コード             --# 固定 #
                  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- エラーフラグ
                ln_err_flg := 1;
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP deliveryno_many_move_id;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END err_chk_delivno;
--
 /**********************************************************************************
  * Procedure Name   : err_chk_delivno_ordersrcref
  * Description      : エラーチェック_配送No受注ソース参照単位 プロシージャ (A-5-2)
  ***********************************************************************************/
  PROCEDURE err_chk_delivno_ordersrcref(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_chk_delivno_ordersrcref'; -- プログラム名
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
    lt_delivery_no            xxwsh_shipping_headers_if.delivery_no%TYPE;      --IF_H.配送No
    lt_order_source_ref       xxwsh_shipping_headers_if.order_source_ref%TYPE; --IF_H.受注ソース参照
    lt_freight_charge_class   xxwsh_shipping_headers_if.filler14%TYPE;         --IF_H.運賃区分
    lt_orderd_item_code       xxwsh_shipping_lines_if.orderd_item_code%TYPE;   --IF_L.受注品目
    lt_eos_data_type          xxwsh_shipping_headers_if.eos_data_type%TYPE;    --IF_H.EOSデータ種別
    lt_lot_no                 xxwsh_shipping_lines_if.lot_no%TYPE;             --IF_L.ロットNo
    lt_weight_capacity_class  xxcmn_item_mst2_v.weight_capacity_class%TYPE;    --OPM品目情報VIEW2.重量容積区分
    lt_prod_kbn_cd            mtl_categories_b.segment1%TYPE;                  --商品区分
    lt_item_kbn_cd            mtl_categories_b.segment1%TYPE;                  --品目区分
    lv_product_cd             VARCHAR2(1);                                     --製品の品目コード
    lv_error_flg              VARCHAR2(1);                                     --エラーflag
    ln_err_flg                NUMBER := 0;
    lv_msg_buff               VARCHAR2(5000);
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
    -- 同一配送No-受注ソース参照-EOSデータ種別単位で、複数の受注品目-ロットNoが存在する場合、エラーとし警告ログ出力します。
    <<deliveryno_src_manyitem>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      lt_delivery_no           := gr_interface_info_rec(i).delivery_no;           -- IF_H.配送No
      lt_order_source_ref      := gr_interface_info_rec(i).order_source_ref;      -- IF_H.受注ソース参照
      lt_freight_charge_class  := gr_interface_info_rec(i).freight_charge_class;  -- IF_H.運賃区分
      lt_orderd_item_code      := gr_interface_info_rec(i).orderd_item_code;      -- IF_L.受注品目
      lt_lot_no                := gr_interface_info_rec(i).lot_no;                -- IF_L.ロットNo
      lt_eos_data_type         := gr_interface_info_rec(i).eos_data_type;         -- IF_H.EOSデータ種別
      lt_weight_capacity_class := gr_interface_info_rec(i).weight_capacity_class; -- 重量容積区分
      lv_error_flg             := gr_interface_info_rec(i).err_flg;               -- エラーフラグ
--
      IF (lv_error_flg = '0') THEN
--
        ln_err_flg := 0;
--
        --チェック有無をIF_H.運賃区分で判定
        IF (lt_freight_charge_class = gv_include_exclude_1) THEN
--
          IF (i >= 2) THEN
--
            IF ((lt_delivery_no = gr_interface_info_rec(i-1).delivery_no) AND        -- IF_H.配送No
                (lt_order_source_ref = gr_interface_info_rec(i-1).order_source_ref) AND -- IF_H.受注ソース参照
                (lt_eos_data_type = gr_interface_info_rec(i-1).eos_data_type))       -- IF_H.EOSデータ種別
            THEN
--
              IF ((lt_orderd_item_code = gr_interface_info_rec(i-1).orderd_item_code) AND -- IF_L.受注品目
                  (lt_lot_no = gr_interface_info_rec(i-1).lot_no))
              THEN
--
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn         -- 'XXWSH'
                              ,gv_msg_93a_005 -- 同一依頼No/移動No上に同一品目が複数存在エラーメッセージ
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           -- IF_H.配送No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      -- IF_H.受注ソース参照
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.受注品目
                              )
                              ,1
                              ,5000);
--
                -- 配送NO-EOSデータ種別単位にエラーflagセット
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- 配送No
                  lt_eos_data_type,       -- EOSデータ種別
                  gv_err_class,           -- エラー種別：エラー
                  lv_msg_buff,            -- エラー・メッセージ(出力用)
                  lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                  lv_retcode,             -- リターン・コード             --# 固定 #
                  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- エラーフラグ
                ln_err_flg := 1;
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- 同一配送No-受注ソース参照-EOSデータ種別単位で、抽出項目：受注品目に紐づくOPM品目マスタ.重量容積区分の重量と
      -- 容積が混在していればエラーとします。
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        --チェック有無をIF_H.運賃区分で判定
        IF (lt_freight_charge_class = gv_include_exclude_1) THEN
--
          IF (i >= 2) THEN
--
            IF ((lt_delivery_no = gr_interface_info_rec(i-1).delivery_no) AND        -- IF_H.配送No
                (lt_order_source_ref = gr_interface_info_rec(i-1).order_source_ref) AND -- IF_H.受注ソース参照
                (lt_eos_data_type = gr_interface_info_rec(i-1).eos_data_type))       -- IF_H.EOSデータ種別
            THEN
              -- 重量容積区分
              IF (lt_weight_capacity_class <> gr_interface_info_rec(i-1).weight_capacity_class) THEN
--
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_012  -- 重量容積区分混在エラーメッセージ
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           -- IF_H.配送No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      -- IF_H.受注ソース参照
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.受注品目
                              )
                              ,1
                              ,5000);
--
                -- 配送NO-EOSデータ種別単位にエラーflagセット
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- 配送No
                  lt_eos_data_type,       -- EOSデータ種別
                  gv_err_class,           -- エラー種別：エラー
                  lv_msg_buff,            -- エラー・メッセージ(出力用)
                  lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                  lv_retcode,             -- リターン・コード             --# 固定 #
                  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- エラーフラグ
                ln_err_flg := 1;
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- 同一配送No-受注ソース参照-EOSデータ種別単位で、抽出項目：商品区分が混在していればエラーとします。
--
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        lt_delivery_no          := gr_interface_info_rec(i).delivery_no;      -- IF_H.配送No
        lt_order_source_ref     := gr_interface_info_rec(i).order_source_ref; -- IF_H.受注ソース参照
        lt_eos_data_type        := gr_interface_info_rec(i).eos_data_type;    -- IF_H.EOSデータ種別
        lt_freight_charge_class := gr_interface_info_rec(i).freight_charge_class;  -- IF_H.運賃区分
        lt_orderd_item_code     := gr_interface_info_rec(i).orderd_item_code; -- IF_L.受注品目
        lt_prod_kbn_cd          := gr_interface_info_rec(i).prod_kbn_cd;      -- 商品区分
--
        --チェック有無をIF_H.運賃区分で判定
        IF (lt_freight_charge_class = gv_include_exclude_1) THEN
--
          IF (i >= 2) THEN
--
            IF ((lt_delivery_no = gr_interface_info_rec(i-1).delivery_no) AND -- IF_H.配送No
                (lt_order_source_ref = gr_interface_info_rec(i-1).order_source_ref) AND -- IF_H.受注ソース参照
                (lt_eos_data_type = gr_interface_info_rec(i-1).eos_data_type)) -- IF_H.EOSデータ種別
--
            THEN
--
              IF (lt_prod_kbn_cd <> gr_interface_info_rec(i-1).prod_kbn_cd) THEN   -- 商品区分
--
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_013  -- 商品区分混在エラーメッセージ
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           -- IF_H.配送No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      -- IF_H.受注ソース参照
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.受注品目
                              )
                              ,1
                              ,5000);
--
                -- 配送NO-EOSデータ種別単位にエラーflagセット
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- 配送No
                  lt_eos_data_type,       -- EOSデータ種別
                  gv_err_class,           -- エラー種別：エラー
                  lv_msg_buff,            -- エラー・メッセージ(出力用)
                  lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                  lv_retcode,             -- リターン・コード             --# 固定 #
                  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- エラーフラグ
                ln_err_flg := 1;
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- EOSデータ種別＝移動出庫または移動入庫の場合、
      -- 同一配送No-受注ソース参照単位で、抽出項目：品目区分が、
      -- 製品と製品以外が混在していればエラーとします。
      -- 製品の品目区分コードを取得
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
        IF ((lt_eos_data_type = gv_eos_data_cd_220)  OR
            (lt_eos_data_type = gv_eos_data_cd_230))
        THEN
--
          lt_delivery_no        := gr_interface_info_rec(i).delivery_no;      --IF_H.配送No
          lt_order_source_ref   := gr_interface_info_rec(i).order_source_ref; --IF_H.受注ソース参照
          lt_eos_data_type      := gr_interface_info_rec(i).eos_data_type;    --IF_H.EOSデータ種別
          lt_freight_charge_class := gr_interface_info_rec(i).freight_charge_class;  -- IF_H.運賃区分
          lt_orderd_item_code   := gr_interface_info_rec(i).orderd_item_code; --IF_L.受注品目
          lt_prod_kbn_cd        := gr_interface_info_rec(i).prod_kbn_cd;      --商品区分
          lt_item_kbn_cd        := gr_interface_info_rec(i).item_kbn_cd;      --品目区分
--
          --チェック有無をIF_H.運賃区分で判定
          IF (lt_freight_charge_class = gv_include_exclude_1) THEN
--
            IF (i >= 2) THEN
--
              IF ((lt_delivery_no = gr_interface_info_rec(i-1).delivery_no) AND    --IF_H.配送No
                  (lt_order_source_ref = gr_interface_info_rec(i-1).order_source_ref) AND --IF_H.受注ソース参照
                  (lt_eos_data_type = gr_interface_info_rec(i-1).eos_data_type)) --IF_H.EOSデータ種別
              THEN
--
                IF (((lt_item_kbn_cd = gv_item_kbn_cd_5) AND
                     (gr_interface_info_rec(i-1).item_kbn_cd <> gv_item_kbn_cd_5)) OR
                    ((lt_item_kbn_cd <> gv_item_kbn_cd_5) AND
                     (gr_interface_info_rec(i-1).item_kbn_cd = gv_item_kbn_cd_5)))
                THEN
--
                  lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                 gv_msg_kbn          -- 'XXWSH'
                                ,gv_msg_93a_014  -- 品目区分混在エラーメッセージ
                                ,gv_param1_token
                                ,gr_interface_info_rec(i).delivery_no           -- IF_H.配送No
                                ,gv_param2_token
                                ,gr_interface_info_rec(i).order_source_ref      -- IF_H.受注ソース参照
                                ,gv_param3_token
                                ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.受注品目
                                )
                                ,1
                                ,5000);
--
                  --配送NO-EOSデータ種別単位にエラーflagセット
                  set_deliveryno_unit_errflg(
                    lt_delivery_no,         -- 配送No
                    lt_eos_data_type,       -- EOSデータ種別
                    gv_err_class,           -- エラー種別：エラー
                    lv_msg_buff,            -- エラー・メッセージ(出力用)
                    lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                    lv_retcode,             -- リターン・コード             --# 固定 #
                    lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
                  );
--
                  -- エラーフラグ
                  ln_err_flg := 1;
                  -- 処理ステータス：警告
                  ov_retcode := gv_status_warn;
--
                END IF;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- 出庫元が引当可能倉庫でなければエラーにする
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        IF ((lt_eos_data_type = gv_eos_data_cd_210)  OR
            (lt_eos_data_type = gv_eos_data_cd_215)) THEN    -- 出荷のみチェックする
--
          IF (gr_interface_info_rec(i).allow_pickup_flag = '0') OR         -- 引当不可
             (gr_interface_info_rec(i).allow_pickup_flag IS NULL) THEN
--
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                     -- 'XXWSH'
                          ,gv_msg_93a_144          -- 出庫元引当不可エラーメッセージ
                          ,gv_param1_token
                          ,gr_interface_info_rec(i).delivery_no           -- IF_H.配送No
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).order_source_ref      -- IF_H.受注ソース参照
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).location_code         -- IF_H.出庫元
                          )
                          ,1
                          ,5000);
--
            -- 配送NO-EOSデータ種別単位にエラーflagセット
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- 配送No
              lt_eos_data_type,       -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP deliveryno_src_manyitem;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END err_chk_delivno_ordersrcref;
--
 /**********************************************************************************
  * Procedure Name   : err_chk_line
  * Description      : エラーチェック_明細単位 プロシージャ (A-5-3)
  ***********************************************************************************/
  PROCEDURE err_chk_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_chk_line'; -- プログラム名
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
    lt_eos_data_type           xxwsh_shipping_headers_if.eos_data_type%TYPE; -- IF_H.EOSデータ種別
    lt_delivery_no             xxwsh_shipping_headers_if.delivery_no%TYPE;   -- IF_H.配送No
    lv_error_flg               VARCHAR2(1);                                  -- エラーflag
    ln_cnt                     NUMBER;
    lv_inv_close_period        NUMBER;
    ln_err_flg                 NUMBER := 0;
    lv_msg_buff                VARCHAR2(5000);
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
    <<line_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      lt_eos_data_type := gr_interface_info_rec(i).eos_data_type;         -- EOSデータ種別
      lt_delivery_no   := gr_interface_info_rec(i).delivery_no;           -- IF_H.配送No
      lv_error_flg     := gr_interface_info_rec(i).err_flg;               -- エラーフラグ
--
      IF (lv_error_flg = '0') THEN
--
        ln_err_flg := 0;
--
        -- 支給かつ外部倉庫発番の場合エラーとします。
        IF ((lt_eos_data_type = gv_eos_data_cd_200) AND
            (gr_interface_info_rec(i).out_warehouse_flg = gv_flg_on))
        THEN
--
          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn          -- 'XXWSH'
                        ,gv_msg_93a_008  -- 業務種別ステータスチェックエラーメッセージ
                        ,gv_param1_token
                        ,gr_interface_info_rec(i).delivery_no           -- IF_H.配送No
                        ,gv_param2_token
                        ,gr_interface_info_rec(i).order_source_ref      -- IF_H.受注ソース参照
                        )
                        ,1
                        ,5000);
--
          -- 配送NO-EOSデータ種別単位にエラーflagセット
          set_deliveryno_unit_errflg(
            lt_delivery_no,         -- 配送No
            lt_eos_data_type,       -- EOSデータ種別
            gv_err_class,           -- エラー種別：エラー
            lv_msg_buff,            -- エラー・メッセージ(出力用)
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          -- エラーフラグ
          ln_err_flg := 1;
          -- 処理ステータス：警告
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
      -- 移動出庫または移動入庫の場合、マスタチェック、配送No-移動Noの組み合わせのチェック
      IF ((lt_eos_data_type = gv_eos_data_cd_220)  OR
          (lt_eos_data_type = gv_eos_data_cd_230))
      THEN
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          IF (lt_eos_data_type = gv_eos_data_cd_220) THEN
--
            --マスタチェック[出荷元]
            SELECT COUNT(xil2v_a.segment1) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_locations2_v    xil2v_a
            -- OPM保管場所情報VIEW.保管倉庫コード
            WHERE  xil2v_a.segment1   = gr_interface_info_rec(i).location_code
              AND  xil2v_a.date_from <= TRUNC(gr_interface_info_rec(i).shipped_date)   -- 組織有効開始日
              AND  ((xil2v_a.date_to IS NULL)
               OR  (xil2v_a.date_to  >= TRUNC(gr_interface_info_rec(i).shipped_date))) -- 組織有効終了日
              AND  xil2v_a.disable_date  IS NULL   -- 無効日
            ;
--
          ELSIF (lt_eos_data_type = gv_eos_data_cd_230) THEN
--
            --マスタチェック[出荷元]
            SELECT COUNT(xil2v_a.segment1) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_locations2_v    xil2v_a
            -- OPM保管場所情報VIEW.保管倉庫コード
            WHERE  xil2v_a.segment1   = gr_interface_info_rec(i).location_code
              AND  xil2v_a.date_from <= TRUNC(gr_interface_info_rec(i).arrival_date)   -- 組織有効開始日
              AND  ((xil2v_a.date_to IS NULL)
               OR  (xil2v_a.date_to  >= TRUNC(gr_interface_info_rec(i).arrival_date))) -- 組織有効終了日
              AND  xil2v_a.disable_date  IS NULL   -- 無効日
            ;
--
          END IF;
--
          IF (ln_cnt = 0) THEN
--
            -- マスタに存在しなければ、配送No単位にエラーflagをセット
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn          -- 'XXWSH'
                          ,gv_msg_93a_010  -- マスタチェックエラーメッセージ
                          ,gv_param1_token
                          ,gv_param1_token05_nm                           --エラー項目名
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                          ,gv_param8_token
                          ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                          ,gv_param9_token
                          ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                          ,gv_param10_token
                          ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                          )
                          ,1
                          ,5000);
--
            -- 配送NO-EOSデータ種別単位にエラーflagセット
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- 配送No
              lt_eos_data_type,       -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- 運送業者≠NULLの場合のみチェックします。
          IF (TRIM(gr_interface_info_rec(i).freight_carrier_code) IS NOT NULL) THEN
--
            -- マスタチェック[運送業者]
            IF (lt_eos_data_type = gv_eos_data_cd_220) THEN     -- 移動出庫
--
              SELECT COUNT(xcv.party_number) item_cnt
              INTO   ln_cnt
              FROM   xxcmn_carriers2_v xcv
              WHERE  xcv.party_number = gr_interface_info_rec(i).freight_carrier_code --運送業者情報VIEW2.組織番号
              AND    xcv.start_date_active <= gr_interface_info_rec(i).shipped_date   --適用開始日<=出荷日
              AND    xcv.end_date_active >= gr_interface_info_rec(i).shipped_date     --適用終了日>=出荷日
              ;
--
            ELSIF (lt_eos_data_type = gv_eos_data_cd_230) THEN  -- 移動入庫
--
              SELECT COUNT(xcv.party_number) item_cnt
              INTO   ln_cnt
              FROM   xxcmn_carriers2_v xcv
              WHERE  xcv.party_number = gr_interface_info_rec(i).freight_carrier_code --運送業者情報VIEW2.組織番号
              AND    xcv.start_date_active <= gr_interface_info_rec(i).arrival_date   --適用開始日<=着荷日
              AND    xcv.end_date_active >= gr_interface_info_rec(i).arrival_date     --適用終了日>=着荷日
              ;
--
            END IF;
--
            IF (ln_cnt = 0) THEN
--
              -- マスタに存在しなければ、配送No単位にエラーflagをセット
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_010  -- マスタチェックエラーメッセージ
                            ,gv_param1_token
                            ,gv_param1_token06_nm                           --エラー項目名
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                            ,gv_param5_token
                            ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                            ,gv_param6_token
                            ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                            ,gv_param7_token
                            ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                            ,gv_param8_token
                            ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                            ,gv_param9_token
                            ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                            ,gv_param10_token
                            ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                            )
                            ,1
                            ,5000);
--
              -- 配送NO-EOSデータ種別単位にエラーflagセット
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- 配送No
                lt_eos_data_type,       -- EOSデータ種別
                gv_err_class,           -- エラー種別：エラー
                lv_msg_buff,            -- エラー・メッセージ(出力用)
                lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                lv_retcode,             -- リターン・コード             --# 固定 #
                lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              -- エラーフラグ
              ln_err_flg := 1;
              -- 処理ステータス：警告
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
          --マスタチェック[受注品目]
          IF (lt_eos_data_type = gv_eos_data_cd_220) THEN     --移動出庫
--
            SELECT COUNT(ximv.item_no) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_mst2_v ximv
            WHERE  ximv.item_no = gr_interface_info_rec(i).orderd_item_code --OPM品目情報VIEW2.品目コード
            AND    ximv.start_date_active <= gr_interface_info_rec(i).shipped_date --適用開始日<=出荷日
            AND    ximv.end_date_active >= ximv.end_date_active                    --適用終了日>=出荷日
            ;
--
          ELSIF (lt_eos_data_type = gv_eos_data_cd_230) THEN  --移動入庫
--
            SELECT COUNT(ximv.item_no) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_mst2_v ximv
            WHERE  ximv.item_no = gr_interface_info_rec(i).orderd_item_code --OPM品目情報VIEW2.品目コード
            AND ximv.start_date_active <= gr_interface_info_rec(i).arrival_date --適用開始日<=着荷日
            AND ximv.end_date_active >= gr_interface_info_rec(i).arrival_date   --適用終了日>=着荷日
            ;
--
          END IF;
--
          IF (ln_cnt = 0) THEN
--
            -- マスタに存在しなければ、配送No単位にエラーflagをセット
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn          -- 'XXWSH'
                          ,gv_msg_93a_010  -- マスタチェックエラーメッセージ
                          ,gv_param1_token
                          ,gv_param1_token07_nm                           --エラー項目名
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                          ,gv_param8_token
                          ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                          ,gv_param9_token
                          ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                          ,gv_param10_token
                          ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                          )
                          ,1
                          ,5000);
--
            -- 配送NO-EOSデータ種別単位にエラーflagセット
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- 配送No
              lt_eos_data_type,       -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          IF (lt_eos_data_type = gv_eos_data_cd_220) THEN
--
            -- マスタチェック[入庫倉庫]
            SELECT COUNT(xil2v_a.segment1) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_locations2_v    xil2v_a
            -- OPM保管場所情報VIEW.保管倉庫コード
            WHERE  xil2v_a.segment1   = gr_interface_info_rec(i).ship_to_location
              AND  xil2v_a.date_from <= TRUNC(gr_interface_info_rec(i).shipped_date)   -- 組織有効開始日
              AND  ((xil2v_a.date_to IS NULL)
               OR  (xil2v_a.date_to  >= TRUNC(gr_interface_info_rec(i).shipped_date))) -- 組織有効終了日
              AND  xil2v_a.disable_date  IS NULL   -- 無効日
            ;
--
          ELSIF (lt_eos_data_type = gv_eos_data_cd_230) THEN
--
            -- マスタチェック[入庫倉庫]
            SELECT COUNT(xil2v_a.segment1) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_locations2_v    xil2v_a
            -- OPM保管場所情報VIEW.保管倉庫コード
            WHERE  xil2v_a.segment1   = gr_interface_info_rec(i).ship_to_location
              AND  xil2v_a.date_from <= TRUNC(gr_interface_info_rec(i).arrival_date)   -- 組織有効開始日
              AND  ((xil2v_a.date_to IS NULL)
               OR  (xil2v_a.date_to  >= TRUNC(gr_interface_info_rec(i).arrival_date))) -- 組織有効終了日
              AND  xil2v_a.disable_date  IS NULL   -- 無効日
            ;
--
          END IF;
--
          IF (ln_cnt = 0) THEN
--
            -- マスタに存在しなければ、配送No単位にエラーflagをセット
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                            gv_msg_kbn          -- 'XXWSH'
                           ,gv_msg_93a_010  -- マスタチェックエラーメッセージ
                           ,gv_param1_token
                           ,gv_param1_token08_nm                           --エラー項目名
                           ,gv_param2_token
                           ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                           ,gv_param3_token
                           ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                           ,gv_param4_token
                           ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                           ,gv_param5_token
                           ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                           ,gv_param6_token
                           ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                           ,gv_param7_token
                           ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                           ,gv_param8_token
                           ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                           ,gv_param9_token
                           ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                           ,gv_param10_token
                           ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                           )
                           ,1
                           ,5000);
--
            -- 配送NO-EOSデータ種別単位にエラーflagセット
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- 配送No
              lt_eos_data_type,       -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          --チェック有無をIF_H.運賃区分で判定
          IF (gr_interface_info_rec(i).freight_charge_class = gv_include_exclude_1) THEN
--
            -- マスタチェック[配送区分]
            SELECT COUNT(xlvv.lookup_code) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_lookup_values_v  xlvv
            WHERE  xlvv.lookup_type = gv_ship_method_type
            AND    xlvv.lookup_code = gr_interface_info_rec(i).shipping_method_code
            ;
--
            IF (ln_cnt = 0) THEN
--
              -- マスタに存在しなければ、配送No単位にエラーflagをセット
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_010  -- マスタチェックエラーメッセージ
                            ,gv_param1_token
                            ,gv_param1_token09_nm                           --エラー項目名
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                            ,gv_param5_token
                            ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                            ,gv_param6_token
                            ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                            ,gv_param7_token
                            ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                            ,gv_param8_token
                            ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                            ,gv_param9_token
                            ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                            ,gv_param10_token
                            ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                            )
                            ,1
                            ,5000);
--
              -- 配送NO-EOSデータ種別単位にエラーflagセット
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- 配送No
                lt_eos_data_type,       -- EOSデータ種別
                gv_err_class,           -- エラー種別：エラー
                lv_msg_buff,            -- エラー・メッセージ(出力用)
                lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                lv_retcode,             -- リターン・コード             --# 固定 #
                lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              -- エラーフラグ
              ln_err_flg := 1;
              -- 処理ステータス：警告
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
          -- 配送Noと移動Noの組み合わせチェック。(外部倉庫発番の場合実施しない)
          IF (gr_interface_info_rec(i).out_warehouse_flg <> gv_flg_on) THEN
--
            --チェック有無をIF_H.運賃区分で判定
            IF (gr_interface_info_rec(i).freight_charge_class = gv_include_exclude_1) THEN
--
              SELECT COUNT(xmrih.mov_num) item_cnt
              INTO   ln_cnt
              FROM   xxinv_mov_req_instr_headers  xmrih
              WHERE  xmrih.mov_num = gr_interface_info_rec(i).order_source_ref --移動H.移動番号
              AND    xmrih.shipped_locat_code = gr_interface_info_rec(i).location_code    --移動H.出庫元保管場所
              AND    xmrih.ship_to_locat_code = gr_interface_info_rec(i).ship_to_location --移動H.入庫先保管場所
              AND    xmrih.delivery_no = gr_interface_info_rec(i).delivery_no  --移動H.配送No
              AND    xmrih.status     <> gv_mov_status_99                      --移動H.ステータス<>取消
              ;
--
              IF (ln_cnt = 0) THEN
--
                -- 存在しなければ、配送No単位にエラーflagをセット
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_011  -- 組合せと指示チェックエラーメッセージ
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                              ,gv_param6_token
                              ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                              )
                              ,1
                              ,5000);
--
                -- 配送NO-EOSデータ種別単位にエラーflagセット
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- 配送No
                  lt_eos_data_type,       -- EOSデータ種別
                  gv_err_class,           -- エラー種別：エラー
                  lv_msg_buff,            -- エラー・メッセージ(出力用)
                  lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                  lv_retcode,             -- リターン・コード             --# 固定 #
                  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- エラーフラグ
                ln_err_flg := 1;
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF; -- 移動出庫または移動入庫の場合、マスタチェック、配送No-移動Noの組み合わせのチェック
--
      -- 出庫または支給の場合、マスタチェック、配送No-依頼Noの組み合わせのチェック
      IF ((lt_eos_data_type = gv_eos_data_cd_210)  OR
          (lt_eos_data_type = gv_eos_data_cd_215)  OR
          (lt_eos_data_type = gv_eos_data_cd_200))
      THEN
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- マスタチェック[出荷元]
          SELECT COUNT(xil2v_a.segment1) item_cnt
          INTO   ln_cnt
          FROM   xxcmn_item_locations2_v    xil2v_a
          -- OPM保管場所情報VIEW.保管倉庫コード
          WHERE  xil2v_a.segment1   = gr_interface_info_rec(i).location_code
            AND  xil2v_a.date_from <= TRUNC(gr_interface_info_rec(i).shipped_date)   -- 組織有効開始日
            AND  ((xil2v_a.date_to IS NULL)
             OR  (xil2v_a.date_to  >= TRUNC(gr_interface_info_rec(i).shipped_date))) -- 組織有効終了日
            AND  xil2v_a.disable_date  IS NULL   -- 無効日
          ;
--
          IF (ln_cnt = 0) THEN
--
            -- マスタに存在しなければ、配送No単位にエラーflagをセット
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                     -- 'XXWSH'
                          ,gv_msg_93a_010  -- マスタチェックエラーメッセージ
                          ,gv_param1_token
                          ,gv_param1_token05_nm                           --エラー項目名
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                          ,gv_param8_token
                          ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                          ,gv_param9_token
                          ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                          ,gv_param10_token
                          ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                          )
                          ,1
                          ,5000);
--
            -- 配送NO-EOSデータ種別単位にエラーflagセット
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- 配送No
              lt_eos_data_type,       -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- マスタチェック[出荷先]
          IF ((lt_eos_data_type = gv_eos_data_cd_210)  OR
              (lt_eos_data_type = gv_eos_data_cd_215))
          THEN
--
            SELECT COUNT(xpsv.party_site_id) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_party_sites2_v xpsv
            WHERE  xpsv.party_site_number = gr_interface_info_rec(i).party_site_code --パーティサイト情報VIEW2.パーティサイトID
            AND    xpsv.start_date_active <= gr_interface_info_rec(i).shipped_date   --適用開始日<=出荷日
            AND    xpsv.end_date_active   >= gr_interface_info_rec(i).shipped_date   --適用終了日>=出荷日
            ;
--
          ELSIF (lt_eos_data_type = gv_eos_data_cd_200) THEN  --支給
--
            SELECT COUNT(xvsv.vendor_site_code) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_vendor_sites2_v xvsv
            WHERE  xvsv.vendor_site_code = gr_interface_info_rec(i).party_site_code  --仕入先サイト情報VIEW2
            AND    xvsv.start_date_active <= gr_interface_info_rec(i).shipped_date   --適用開始日<=出荷日
            AND    xvsv.end_date_active   >= gr_interface_info_rec(i).shipped_date   --適用終了日>=出荷日
            ;
--
          END IF;
--
          IF (ln_cnt = 0) THEN
--
            -- マスタに存在しなければ、配送No単位にエラーflagをセット
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn          -- 'XXWSH'
                          ,gv_msg_93a_010  -- マスタチェックエラーメッセージ
                          ,gv_param1_token
--********** 2008/08/01 ********** MODIFY START ***
--                          ,gv_param1_token05_nm                           --エラー項目名
                          ,gv_param1_token10_nm                           --エラー項目名
--********** 2008/08/01 ********** MODIFY START ***
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                          ,gv_param8_token
                          ,gr_interface_info_rec(i).orderd_item_code      --IF_H明細.受注品目
                          ,gv_param9_token
                          ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                          ,gv_param10_token
                          ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                          )
                          ,1
                          ,5000);
--
            -- 配送NO-EOSデータ種別単位にエラーflagセット
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- 配送No
              lt_eos_data_type,       -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- 運送業者≠NULLの場合のみチェックします。
          IF (TRIM(gr_interface_info_rec(i).freight_carrier_code) IS NOT NULL) THEN
--
            -- マスタチェック[運送業者]
            SELECT COUNT(xcv.party_number) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_carriers2_v xcv
            WHERE  xcv.party_number = gr_interface_info_rec(i).freight_carrier_code  --運送業者情報VIEW2.組織番号
            AND    xcv.start_date_active <= gr_interface_info_rec(i).shipped_date    --適用開始日<=出荷日
            AND    xcv.end_date_active   >= gr_interface_info_rec(i).shipped_date    --適用終了日>=出荷日
            ;
--
            IF (ln_cnt = 0) THEN
--
              -- マスタに存在しなければ、配送No単位にエラーflagをセット
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_010  -- マスタチェックエラーメッセージ
                            ,gv_param1_token
                            ,gv_param1_token06_nm                           --エラー項目名
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                            ,gv_param5_token
                            ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                            ,gv_param6_token
                            ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                            ,gv_param7_token
                            ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                            ,gv_param8_token
                            ,gr_interface_info_rec(i).orderd_item_code      --IF_L明細.受注品目
                            ,gv_param9_token
                            ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                            ,gv_param10_token
                            ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                            )
                            ,1
                            ,5000);
--
              -- 配送NO-EOSデータ種別単位にエラーflagセット
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- 配送No
                lt_eos_data_type,       -- EOSデータ種別
                gv_err_class,           -- エラー種別：エラー
                lv_msg_buff,            -- エラー・メッセージ(出力用)
                lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                lv_retcode,             -- リターン・コード             --# 固定 #
                lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              -- エラーフラグ
              ln_err_flg := 1;
              -- 処理ステータス：警告
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- マスタチェック[受注品目]
          SELECT COUNT(ximv.item_no) item_cnt
          INTO   ln_cnt
          FROM   xxcmn_item_mst2_v ximv
          WHERE  ximv.item_no = gr_interface_info_rec(i).orderd_item_code --OPM品目情報VIEW2.品目コード
          AND    ximv.start_date_active <= gr_interface_info_rec(i).shipped_date  --適用開始日<=出荷日
          AND    ximv.end_date_active   >= gr_interface_info_rec(i).shipped_date  --適用終了日>=出荷日
          ;
--
          IF (ln_cnt = 0) THEN
--
            -- マスタに存在しなければ、配送No単位にエラーflagをセット
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn          -- 'XXWSH'
                          ,gv_msg_93a_010  -- マスタチェックエラーメッセージ
                          ,gv_param1_token
                          ,gv_param1_token07_nm                           --エラー項目名
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                          ,gv_param8_token
                          ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                          ,gv_param9_token
                          ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                          ,gv_param10_token
                          ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                          )
                          ,1
                          ,5000);
--
            -- 配送NO-EOSデータ種別単位にエラーflagセット
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- 配送No
              lt_eos_data_type,       -- EOSデータ種別
              gv_err_class,           -- エラー種別：エラー
              lv_msg_buff,            -- エラー・メッセージ(出力用)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- エラーフラグ
            ln_err_flg := 1;
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          --チェック有無をIF_H.運賃区分で判定
          IF (gr_interface_info_rec(i).freight_charge_class = gv_include_exclude_1) THEN
--
            -- マスタチェック[配送区分]
            SELECT COUNT(xlvv.lookup_code) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_lookup_values_v  xlvv
            WHERE  xlvv.lookup_type = gv_ship_method_type
            AND    xlvv.lookup_code = gr_interface_info_rec(i).shipping_method_code
            ;
--
            IF (ln_cnt = 0) THEN
--
              -- マスタに存在しなければ、配送No単位にエラーflagをセット
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_010  -- マスタチェックエラーメッセージ
                            ,gv_param1_token
                            ,gv_param1_token09_nm                           --エラー項目名
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                            ,gv_param5_token
                            ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                            ,gv_param6_token
                            ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                            ,gv_param7_token
                            ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                            ,gv_param8_token
                            ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                            ,gv_param9_token
                            ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                            ,gv_param10_token
                            ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                            )
                            ,1
                            ,5000);
--
              -- 配送NO-EOSデータ種別単位にエラーflagセット
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- 配送No
                lt_eos_data_type,       -- EOSデータ種別
                gv_err_class,           -- エラー種別：エラー
                lv_msg_buff,            -- エラー・メッセージ(出力用)
                lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                lv_retcode,             -- リターン・コード             --# 固定 #
                lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              -- エラーフラグ
              ln_err_flg := 1;
              -- 処理ステータス：警告
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- 配送Noと移動Noの組み合わせチェック。(外部倉庫発番の場合実施しない)
          IF (gr_interface_info_rec(i).out_warehouse_flg <> gv_flg_on) THEN
--
            --チェック有無をIF_H.運賃区分で判定
            IF (gr_interface_info_rec(i).freight_charge_class = gv_include_exclude_1) THEN
--
              SELECT COUNT(xoha.request_no) item_cnt
              INTO   ln_cnt
              FROM   xxwsh_order_headers_all  xoha
              WHERE  xoha.request_no   = gr_interface_info_rec(i).order_source_ref  --受注H.依頼No
              AND    xoha.deliver_from = gr_interface_info_rec(i).location_code     --受注H.出荷元保管場所
              AND    xoha.delivery_no  = gr_interface_info_rec(i).delivery_no       --受注H.配送No
              AND    xoha.latest_external_flag = gv_yesno_y                         --最新フラグ
              ;
--
              IF (ln_cnt = 0) THEN
--
                -- 存在しなければ、配送No単位にエラーflagをセット
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_011  -- 組合せと指示チェックエラーメッセージ
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).location_code         --IF_H.出荷元
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                              ,gv_param6_token
                              ,gr_interface_info_rec(i).ship_to_location      --IF_H.入庫倉庫
                              )
                              ,1
                              ,5000);
--
                -- 配送NO-EOSデータ種別単位にエラーflagセット
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- 配送No
                  lt_eos_data_type,       -- EOSデータ種別
                  gv_err_class,           -- エラー種別：エラー
                  lv_msg_buff,            -- エラー・メッセージ(出力用)
                  lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                  lv_retcode,             -- リターン・コード             --# 固定 #
                  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- エラーフラグ
                ln_err_flg := 1;
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
          -- 抽出項目：EOSデータ種別＝有償出荷報告　かつ
          -- 受注ヘッダアドオン.有償金額確定区分=確定の場合、エラーとします。
          IF (lt_eos_data_type = gv_eos_data_cd_200) THEN  --支給
--
            IF (gr_interface_info_rec(i).out_warehouse_flg <> gv_flg_on) THEN
--
              SELECT COUNT(xoha.request_no) item_cnt
              INTO   ln_cnt
              FROM   xxwsh_order_headers_all  xoha
              --受注H.依頼No
              WHERE  xoha.request_no           = gr_interface_info_rec(i).order_source_ref
              AND    xoha.amount_fix_class     = gv_amount_fix_1  --受注H.有償金額確定区分=確定
              AND    xoha.latest_external_flag = gv_yesno_y       --最新フラグ
              ;
--
              IF (ln_cnt <> 0) THEN
--
                -- 存在しなければ、配送No単位にエラーflagをセット
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_015  -- 有償金額確定区分確定エラーメッセージ
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.受注品目
                              )
                              ,1
                              ,5000);
--
                -- 配送NO-EOSデータ種別単位にエラーflagセット
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- 配送No
                  lt_eos_data_type,       -- EOSデータ種別
                  gv_err_class,           -- エラー種別：エラー
                  lv_msg_buff,            -- エラー・メッセージ(出力用)
                  lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                  lv_retcode,             -- リターン・コード             --# 固定 #
                  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- エラーフラグ
                ln_err_flg := 1;
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
        --OPM在庫会計期間CLOSE年月チェック
        lv_inv_close_period := xxcmn_common_pkg.get_opminv_close_period;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
          -- 出荷or支給
          IF ((lt_eos_data_type = gv_eos_data_cd_200) OR
              (lt_eos_data_type = gv_eos_data_cd_210) OR
              (lt_eos_data_type = gv_eos_data_cd_215))
          THEN
--
            --出荷日
            IF (FND_DATE.STRING_TO_DATE(lv_inv_close_period,'YYYY/MM') >= gr_interface_info_rec(i).shipped_date)
            THEN
--
              -- 在庫会計期間がCLOSEなので、ログを出力し、配送No単位にエラーをセット
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_016  -- 在庫会計期間CLOSEエラー
                            ,gv_param1_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                            ,gv_param3_token
                            ,lv_inv_close_period          --OPM在庫会計期間CLOSE年月取得関数の戻り値
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                            ,gv_param5_token
                            ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')          --IF_H.出荷日
                            ,gv_param6_token
                            ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')          --IF_H.着荷日
                            )
                            ,1
                            ,5000);
--
              -- 配送NO-EOSデータ種別単位にエラーflagセット
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- 配送No
                lt_eos_data_type,       -- EOSデータ種別
                gv_err_class,           -- エラー種別：エラー
                lv_msg_buff,            -- エラー・メッセージ(出力用)
                lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                lv_retcode,             -- リターン・コード             --# 固定 #
                lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              -- エラーフラグ
              ln_err_flg := 1;
              -- 処理ステータス：警告
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
          -- 移動出庫or移動入庫
          IF ((lt_eos_data_type = gv_eos_data_cd_220)  OR
              (lt_eos_data_type = gv_eos_data_cd_230))
          THEN
--
            -- 出荷日/着荷日
            IF ((FND_DATE.STRING_TO_DATE(lv_inv_close_period,'YYYY/MM') >= gr_interface_info_rec(i).shipped_date) OR
                (FND_DATE.STRING_TO_DATE(lv_inv_close_period,'YYYY/MM') >= gr_interface_info_rec(i).arrival_date))
            THEN
--
              -- 在庫会計期間がCLOSEなので、ログを出力し、配送No単位にエラーをセット
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_016  -- 在庫会計期間CLOSEエラー
                            ,gv_param1_token
                            ,gr_interface_info_rec(i).delivery_no      --IF_H.配送No
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).order_source_ref --IF_H.受注ソース参照
                            ,gv_param3_token
                            ,lv_inv_close_period                    --OPM在庫会計期間CLS年月取得戻値
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type    --IF_H.EOSデータ種別
                            ,gv_param5_token
                            ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')     --IF_H.出荷日
                            ,gv_param6_token
                            ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')     --IF_H.着荷日
                            )
                            ,1
                            ,5000);
--
              -- 配送NO-EOSデータ種別単位にエラーflagセット
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- 配送No
                lt_eos_data_type,       -- EOSデータ種別
                gv_err_class,           -- エラー種別：エラー
                lv_msg_buff,            -- エラー・メッセージ(出力用)
                lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                lv_retcode,             -- リターン・コード             --# 固定 #
                lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              -- エラーフラグ
              ln_err_flg := 1;
              -- 処理ステータス：警告
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF; --出庫または支給の場合、マスタチェック、配送No-依頼Noの組み合わせのチェック
--
    END LOOP line_loop;
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
  END err_chk_line;
--
 /**********************************************************************************
  * Procedure Name   : appropriate_check
  * Description      : 妥当チェック プロシージャ (A-6)
  ***********************************************************************************/
  PROCEDURE appropriate_check(
    ov_errbuf               OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'appropriate_check'; -- プログラム名
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
    ln_cnt                         NUMBER;
    ln_cnt2                        NUMBER;
    ln_errflg                      NUMBER;
    wk_sql                         VARCHAR2(9000);
    lv_error_flg                   VARCHAR2(1);                    --エラーflag
    ld_todate_1                    DATE;             -- DATE型チェック用
    ld_todate_2                    DATE;             -- DATE型チェック用
    lv_msg_buff                    VARCHAR2(5000);
--
    -- IF_H.EOSデータ種別
    lt_eos_data_type               xxwsh_shipping_headers_if.eos_data_type%TYPE;
    -- 出庫予定日
    lt_mov_schedule_ship_date      xxinv_mov_req_instr_headers.schedule_ship_date%TYPE;
    -- 出庫実績日
    lt_mov_actual_ship_date        xxinv_mov_req_instr_headers.actual_ship_date%TYPE;
    -- 入庫予定日
    lt_mov_schedule_arrival_date   xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE;
    -- 入庫実績日
    lt_mov_actual_arrival_date     xxinv_mov_req_instr_headers.actual_arrival_date%TYPE;
    -- 運送業者
    lt_mov_freight_code            xxinv_mov_req_instr_headers.freight_carrier_code%TYPE;
    -- 運送業者_実績
    lt_mov_actual_freight_code     xxinv_mov_req_instr_headers.actual_freight_carrier_code%TYPE;
    -- 配送区分
    lt_mov_shipping_code           xxinv_mov_req_instr_headers.shipping_method_code%TYPE;
    -- 配送区分_実績
    lt_mov_actual_shipping_code    xxinv_mov_req_instr_headers.actual_shipping_method_code%TYPE;
    -- 配送No
    lt_mov_delivery_no             xxinv_mov_req_instr_headers.delivery_no%TYPE;
    -- 移動番号
    lt_mov_num                     xxinv_mov_req_instr_headers.mov_num%TYPE;
    -- 出荷予定日
    lt_req_schedule_ship_date      xxwsh_order_headers_all.schedule_ship_date%TYPE;
    -- 出荷日
    lt_req_shipped_date            xxwsh_order_headers_all.shipped_date%TYPE;
    -- 着荷予定日
    lt_req_schedule_arrival_date   xxwsh_order_headers_all.schedule_arrival_date%TYPE;
    -- 着荷日
    lt_req_arrival_date            xxwsh_order_headers_all.arrival_date%TYPE;
    -- 運送業者
    lt_req_freight_code            xxwsh_order_headers_all.freight_carrier_code%TYPE;
    -- 運送業者_実績
    lt_req_result_freight_code     xxwsh_order_headers_all.result_freight_carrier_code%TYPE;
    -- 配送区分
    lt_req_shipping_code           xxwsh_order_headers_all.shipping_method_code%TYPE;
    -- 配送区分_実績
    lt_req_result_shipping_code    xxwsh_order_headers_all.result_shipping_method_code%TYPE;
    -- 出荷先
    lt_req_deliver_to              xxwsh_order_headers_all.deliver_to%TYPE;
    -- 出荷先_実績ID
    lt_req_result_deliver_to       xxwsh_order_headers_all.result_deliver_to%TYPE;
    -- 配送No
    lt_req_delivery_no             xxwsh_order_headers_all.delivery_no%TYPE;
    -- 依頼No
    lt_request_no                  xxwsh_order_headers_all.request_no%TYPE;
    -- IF_H.パレット回収枚数
    lt_collected_pallet_qty        xxwsh_shipping_headers_if.collected_pallet_qty%TYPE;
    -- IF_H.パレット使用枚数
    lt_used_pallet_qty             xxwsh_shipping_headers_if.used_pallet_qty%TYPE;
    -- IF_L.出荷実績数量
    lt_shiped_quantity             xxwsh_shipping_lines_if.shiped_quantity%TYPE;
    -- IF_L.内訳数量(インタフェース用)
    lt_detailed_quantity           xxwsh_shipping_lines_if.detailed_quantity%TYPE;
--
    lt_product_date                ic_lots_mst.attribute1%TYPE;                     --製造年月日
    lt_expiration_day              ic_lots_mst.attribute3%TYPE;                     --賞味期限
    lt_original_sign               ic_lots_mst.attribute2%TYPE;                     --固有記号
    lt_lot_status                  ic_lots_mst.attribute23%TYPE;                    --ロットステータス
--
    lt_delivery_no                 xxwsh_shipping_headers_if.delivery_no%TYPE;      --IF_H.配送No
    lt_order_source_ref            xxwsh_shipping_headers_if.order_source_ref%TYPE; --IF_H.受注ソース参照
--
    lt_vendor_site_code            xxwsh_order_headers_all.vendor_site_code%TYPE;   --取引先サイト
    lt_pay_provision_rel           xxcmn_lot_status_v.pay_provision_rel%TYPE;       --有償支給(実績)
    lt_move_inst_rel               xxcmn_lot_status_v.move_inst_rel%TYPE;           --移動指示(実績)
    lt_ship_req_rel                xxcmn_lot_status_v.ship_req_rel%TYPE;            --出荷依頼(実績)
    ln_lot_err_flg                 NUMBER;
    lv_error_flag                  VARCHAR2(1) := 0;
--
    -- *** ローカル・カーソル ***
    CURSOR cur_lots_product_check
      (
      iv_orderd_item_code         xxwsh_shipping_lines_if.orderd_item_code%TYPE,    -- 受注品目
      iv_lot_no                   xxwsh_shipping_lines_if.lot_no%TYPE,              -- ロットNo
      iv_prod_kbn_cd              VARCHAR2,                                         -- 商品区分
      iv_item_kbn_cd              VARCHAR2,                                         -- 品目区分
      id_date                     DATE                                              -- 出荷/着荷日
      )
    IS
      SELECT ilm.attribute1  product_date    --製造年月日
            ,ilm.attribute3  expiration_day  --賞味期限
            ,ilm.attribute2  original_sign   --固有記号
      FROM   xxcmn_item_categories5_v xicv,
             ic_lots_mst ilm,
             xxcmn_item_mst2_v ximv
      WHERE  xicv.item_id = ilm.item_id
      AND    xicv.item_id = ximv.item_id
      AND    ximv.item_no = iv_orderd_item_code         -- 受注品目
      AND    ilm.lot_no   = iv_lot_no                   -- ロットNo
      AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1           -- ロット管理品
      AND    xicv.prod_class_code = iv_prod_kbn_cd      -- 商品区分
      AND    xicv.item_class_code = iv_item_kbn_cd      -- 品目区分
      AND    ximv.inactive_ind   <> gn_view_disable     -- 無効フラグ
      AND    ximv.obsolete_class <> gv_view_disable     -- 廃止区分
      AND    ximv.start_date_active <= TRUNC(id_date)   -- 出荷/着荷日
      AND    ximv.end_date_active   >= TRUNC(id_date)   -- 出荷/着荷日
      ;
--
/*
--  3.4.専用
    CURSOR cur_lots_product_check2
      (
      iv_orderd_item_code         xxwsh_shipping_lines_if.orderd_item_code%TYPE,    -- 受注品目
      iv_lot_no                   xxwsh_shipping_lines_if.lot_no%TYPE,              -- ロットNo
      iv_prod_kbn_cd              VARCHAR2,                                         -- 商品区分
      iv_item_kbn_cd              VARCHAR2,                                         -- 品目区分
      id_date                     DATE                                              -- 出荷/着荷日
      )
    IS
      SELECT ilm.attribute1  product_date    --製造年月日
            ,ilm.attribute3  expiration_day  --賞味期限
            ,ilm.attribute2  original_sign   --固有記号
      FROM   xxcmn_item_categories5_v xicv,
             ic_lots_mst ilm,
             xxcmn_item_mst2_v ximv
      WHERE  xicv.item_id = ilm.item_id
      AND    xicv.item_id = ximv.item_id
      AND    ximv.item_no = iv_orderd_item_code         -- 受注品目
      AND    ilm.lot_no   = iv_lot_no                   -- ロットNo
      AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1           -- ロット管理品
      AND    xicv.prod_class_code = iv_prod_kbn_cd      -- 商品区分
      AND    xicv.item_class_code <> iv_item_kbn_cd     -- 品目区分       --<>になっている
      AND    ximv.inactive_ind   <> gn_view_disable     -- 無効フラグ
      AND    ximv.obsolete_class <> gv_view_disable     -- 廃止区分
      AND    ximv.start_date_active <= TRUNC(id_date)   -- 出荷/着荷日
      AND    ximv.end_date_active   >= TRUNC(id_date)   -- 出荷/着荷日
      ;
*/
--
    CURSOR cur_lots_status_check
      (
      iv_orderd_item_code             xxwsh_shipping_lines_if.orderd_item_code%TYPE,            -- 受注品目
      iv_lot_no                       xxwsh_shipping_lines_if.lot_no%TYPE,                      -- ロットNo
      id_designated_production_date   xxwsh_shipping_lines_if.designated_production_date%TYPE,  -- 製造日
      iv_original_character           xxwsh_shipping_lines_if.original_character%TYPE,          -- 固有記号
      id_date                         DATE                                                      -- 出荷/着荷日
      )
    IS
      SELECT ilm.attribute3  expiration_day    --賞味期限
            ,ilm.attribute2  original_sign     --固有記号
            ,ilm.attribute23 lot_status        --ロットステータス
      FROM   xxcmn_item_categories5_v xicv,
             ic_lots_mst ilm,
             xxcmn_item_mst2_v ximv
      WHERE  xicv.item_id = ilm.item_id
      AND    xicv.item_id = ximv.item_id
      AND    ximv.item_no = iv_orderd_item_code                                     -- 受注品目
      AND    ilm.lot_no   = iv_lot_no                                               -- ロットNo
      AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                                       -- ロット管理品
      AND    ilm.attribute1 = TO_CHAR(id_designated_production_date,'YYYY/MM/DD')   -- 製造日
      AND    ilm.attribute2 = iv_original_character                                 -- 固有記号
      AND    ximv.inactive_ind   <> gn_view_disable                                 -- 無効フラグ
      AND    ximv.obsolete_class <> gv_view_disable                                 -- 廃止区分
      AND    ximv.start_date_active <= TRUNC(id_date)                               -- 出荷/着荷日
      AND    ximv.end_date_active   >= TRUNC(id_date)                               -- 出荷/着荷日
      ;
--
    -- *** ローカル・レコード ***
--
--     AA VARCHAR2(30) ;
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
    <<appropriate_chk_line_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
--      AA := gr_interface_info_rec(i).orderd_item_code;
--
      lt_eos_data_type    := gr_interface_info_rec(i).eos_data_type;
      lv_error_flg        := gr_interface_info_rec(i).err_flg;                  --エラーフラグ
      lt_delivery_no      := gr_interface_info_rec(i).delivery_no;              --配送No
      lt_order_source_ref := gr_interface_info_rec(i).order_source_ref;         --受注ソース参照
--
      IF (lv_error_flg = '0') THEN
--
        ln_errflg := 0;
--
        -- 1.
        -- 1.1 指示の項目と実績の項目を比較し、指示上の実績項目に値が設定されている場合は、
        --     指示データ上の指示項目と実績項目を比較します。(移動出庫or移動入庫)
        IF ((lt_eos_data_type = gv_eos_data_cd_220) OR (lt_eos_data_type = gv_eos_data_cd_230)) THEN
--
          SELECT COUNT(xmrih.mov_num) item_cnt
          INTO   ln_cnt
          FROM   xxinv_mov_req_instr_headers xmrih
          WHERE  xmrih.mov_num = gr_interface_info_rec(i).order_source_ref --移動H.移動番号=抽出項目:受注ソース参照
          --調整中or依頼済
          AND    ((xmrih.status = gv_mov_status_03) OR (xmrih.status = gv_mov_status_02))
          --確定通知済
          AND    xmrih.notif_status = gv_notif_status_40
          ;
--
          -- ヘッダレベルなので１件
          IF (ln_cnt > 0) THEN
--
            SELECT xmrih.schedule_ship_date           --出庫予定日
                  ,xmrih.actual_ship_date             --出庫実績日
                  ,xmrih.schedule_arrival_date        --入庫予定日
                  ,xmrih.actual_arrival_date          --入庫実績日
                  ,xmrih.freight_carrier_code         --運送業者
                  ,xmrih.actual_freight_carrier_code  --運送業者_実績
                  ,xmrih.shipping_method_code         --配送区分
                  ,xmrih.actual_shipping_method_code  --配送区分_実績
                  ,xmrih.delivery_no                  --配送No
                  ,xmrih.mov_num                      --移動番号
            INTO   lt_mov_schedule_ship_date          --出庫予定日
                  ,lt_mov_actual_ship_date            --出庫実績日
                  ,lt_mov_schedule_arrival_date       --入庫予定日
                  ,lt_mov_actual_arrival_date         --入庫実績日
                  ,lt_mov_freight_code                --運送業者
                  ,lt_mov_actual_freight_code         --運送業者_実績
                  ,lt_mov_shipping_code               --配送区分
                  ,lt_mov_actual_shipping_code        --配送区分_実績
                  ,lt_mov_delivery_no                 --配送No
                  ,lt_mov_num                         --移動番号
            FROM  xxinv_mov_req_instr_headers xmrih
            -- 移動H.移動番号=抽出項目:受注ソース参照
            WHERE xmrih.mov_num = gr_interface_info_rec(i).order_source_ref
            -- 調整中or依頼済
            AND   ((xmrih.status = gv_mov_status_03) OR (xmrih.status = gv_mov_status_02))
            -- 確定通知済
            AND   xmrih.notif_status = gv_notif_status_40
            AND   ROWNUM=1
            ;
--
            -- 出庫予定日、抽出項目:出荷日、出庫実績日の比較
            IF (lt_mov_schedule_ship_date <> gr_interface_info_rec(i).shipped_date) THEN
--
              ln_errflg := 1;
--
            ELSIF (lt_mov_actual_ship_date IS NOT NULL) THEN
--
              IF (lt_mov_schedule_ship_date <> lt_mov_actual_ship_date) THEN
                ln_errflg := 1;
              END IF;
--
            END IF;
--
            -- 入庫予定日、抽出項目:着荷日、入庫実績日の比較
            IF (lt_mov_schedule_arrival_date <> gr_interface_info_rec(i).arrival_date) THEN
--
              ln_errflg := 1;
--
            ELSIF (lt_mov_actual_arrival_date IS NOT NULL) THEN
--
              IF (lt_mov_schedule_arrival_date <> lt_mov_actual_arrival_date) THEN
                ln_errflg := 1;
              END IF;
--
            END IF;
--
            -- 運送業者、抽出項目:運送業者、運送業者_実績の比較
            IF (lt_mov_freight_code <> gr_interface_info_rec(i).freight_carrier_code) THEN
--
              ln_errflg := 1;
--
            ELSIF (lt_mov_actual_freight_code IS NOT NULL) THEN
--
              IF (lt_mov_freight_code <> lt_mov_actual_freight_code) THEN
                ln_errflg := 1;
              END IF;
--
            END IF;
--
            -- 配送区分、抽出項目:配送区分、配送区分_実績の比較
            IF (NVL(lt_mov_shipping_code,gv_delivery_no_null) <> NVL(gr_interface_info_rec(i).shipping_method_code,gv_delivery_no_null)) THEN
--
              ln_errflg := 1;
--
            ELSIF (lt_mov_actual_shipping_code IS NOT NULL) THEN
--
              IF (lt_mov_shipping_code <> lt_mov_actual_shipping_code) THEN
                ln_errflg := 1;
              END IF;
--
            END IF;
--
            IF (ln_errflg = 1) THEN
--
              -- ログ出力
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                              gv_msg_kbn          -- 'XXWSH'
                             ,gv_msg_93a_017  -- 妥当チェックエラーメッセージ(移動予定実績警告)
                             ,gv_param1_token
                             ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                             ,gv_param2_token
                             ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                             ,gv_param3_token
                             ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                             ,gv_param4_token
                             ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')          --IF_H.出荷日
                             ,gv_param5_token
                             ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')          --IF_H.着荷日
                             ,gv_param6_token
                             ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                             ,gv_param7_token
                             ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                             )
                             ,1
                             ,5000);
--
              -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
              set_header_unit_reserveflg(
                lt_delivery_no,       -- 配送No
                lt_order_source_ref,  -- 移動No/依頼No
                lt_eos_data_type,     -- EOSデータ種別
                gv_reserved_class,    -- エラー種別：保留
                lv_msg_buff,          -- エラー・メッセージ(出力用)
                lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                lv_retcode,           -- リターン・コード             --# 固定 #
                lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              -- 処理ステータス：警告
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        -- 2.
        -- 2.1 指示の項目と実績の項目を比較し、指示上の実績項目に値が設定されている場合は、
        --     指示データ上の指示項目と実績項目を比較します。(出荷or支給)
--
        IF (ln_errflg = 0) THEN
--
          -- 出荷or支給
          IF ((lt_eos_data_type = gv_eos_data_cd_210) OR        -- 拠点出荷確定報告
              (lt_eos_data_type = gv_eos_data_cd_215) OR        -- 庭先出荷確定報告
              (lt_eos_data_type = gv_eos_data_cd_200))          -- 有償出荷報告
          THEN
--
            SELECT COUNT(xoha.request_no) item_cnt
            INTO   ln_cnt
            FROM   xxwsh_order_headers_all xoha
            -- 受注H.依頼No=抽出項目:受注ソース参照
            WHERE  xoha.request_no = gr_interface_info_rec(i).order_source_ref
            -- 締め済みor受領済み
            AND    ((xoha.req_status = gv_req_status_03) OR (xoha.req_status = gv_req_status_07))
            AND    xoha.notif_status = gv_notif_status_40 -- 確定通知済
            AND    xoha.latest_external_flag = gv_yesno_y -- 最新フラグ
            ;
--
            -- ヘッダレベルなので１件
            IF (ln_cnt > 0) THEN
--
              SELECT xoha.schedule_ship_date             --出荷予定日
                    ,xoha.shipped_date                   --出荷日
                    ,xoha.schedule_arrival_date          --着荷予定日
                    ,xoha.arrival_date                   --着荷日
                    ,xoha.freight_carrier_code           --運送業者
                    ,xoha.result_freight_carrier_code    --運送業者_実績
                    ,xoha.shipping_method_code           --配送区分
                    ,xoha.result_shipping_method_code    --配送区分_実績
                    ,xoha.deliver_to                     --出荷先
                    ,xoha.result_deliver_to              --出荷先_実績
                    ,xoha.delivery_no                    --配送No
                    ,xoha.request_no                     --依頼No
                    ,xoha.vendor_site_code               --取引先サイト
              INTO   lt_req_schedule_ship_date           --出荷予定日
                    ,lt_req_shipped_date                 --出荷日
                    ,lt_req_schedule_arrival_date        --着荷予定日
                    ,lt_req_arrival_date                 --着荷日
                    ,lt_req_freight_code                 --運送業者
                    ,lt_req_result_freight_code          --運送業者_実績
                    ,lt_req_shipping_code                --配送区分
                    ,lt_req_result_shipping_code         --配送区分_実績
                    ,lt_req_deliver_to                   --出荷先
                    ,lt_req_result_deliver_to            --出荷先_実績
                    ,lt_req_delivery_no                  --配送No
                    ,lt_request_no                       --依頼No
                    ,lt_vendor_site_code                 --取引先サイト
              FROM   xxwsh_order_headers_all xoha
              -- 受注H.依頼No=抽出項目:受注ソース参照
              WHERE  xoha.request_no = gr_interface_info_rec(i).order_source_ref
              -- 締め済みor受領済み
              AND    ((xoha.req_status = gv_req_status_03) OR (xoha.req_status = gv_req_status_07))
              AND    xoha.notif_status = gv_notif_status_40 -- 確定通知済
              AND    xoha.latest_external_flag = gv_yesno_y -- 最新フラグ
              AND    ROWNUM=1
              ;
--
              -- 出荷予定日、抽出項目:出荷日、出荷日の比較
              IF (lt_req_schedule_ship_date <> gr_interface_info_rec(i).shipped_date) THEN
--
                ln_errflg := 1;
--
              ELSIF (lt_req_shipped_date IS NOT NULL) THEN
--
                IF (lt_req_schedule_ship_date <> lt_req_shipped_date) THEN
                  ln_errflg := 1;
                END IF;
--
              END IF;
--
              -- 着荷予定日、抽出項目:着荷日、着荷日の比較
              IF (lt_req_schedule_arrival_date <> gr_interface_info_rec(i).arrival_date) THEN
--
                ln_errflg := 1;
--
              ELSIF (lt_req_arrival_date IS NOT NULL) THEN
--
                IF (lt_req_schedule_arrival_date <> lt_req_arrival_date) THEN
                  ln_errflg := 1;
                END IF;
--
              END IF;
--
              -- 運送業者、抽出項目:運送業者、運送業者_実績の比較
              IF (lt_req_freight_code <> gr_interface_info_rec(i).freight_carrier_code) THEN
--
                ln_errflg := 1;
--
              ELSIF (lt_req_result_freight_code IS NOT NULL) THEN
--
                IF (lt_req_freight_code <> lt_req_result_freight_code) THEN
                  ln_errflg := 1;
                END IF;
--
              END IF;
--
              -- 配送区分、抽出項目:配送区分、配送区分_実績の比較
              IF (NVL(lt_req_shipping_code,gv_delivery_no_null) <> NVL(gr_interface_info_rec(i).shipping_method_code,gv_delivery_no_null)) THEN
--
                ln_errflg := 1;
--
              ELSIF (lt_req_result_shipping_code IS NOT NULL) THEN
--
                IF (lt_req_shipping_code <> lt_req_result_shipping_code) THEN
                  ln_errflg := 1;
                END IF;
--
              END IF;
--
              -- 出荷先、抽出項目:出荷先、出荷先_実績の比較
              -- 出荷
              -- 拠点出荷確定報告 or 庭先出荷確定報告
              IF ((lt_eos_data_type = gv_eos_data_cd_210)  OR
                  (lt_eos_data_type = gv_eos_data_cd_215)) THEN
--
                IF (lt_req_deliver_to <> gr_interface_info_rec(i).party_site_code) THEN
--
                  ln_errflg := 1;
--
                ELSIF (lt_req_result_deliver_to IS NOT NULL) THEN
--
                  IF (lt_req_deliver_to <> lt_req_result_deliver_to) THEN
                    ln_errflg := 1;
                  END IF;
--
                END IF;
--
              END IF;
--
              -- 支給時の比較
              IF (lt_eos_data_type <> gv_eos_data_cd_200) THEN  -- 有償出荷報告
--
                IF (lt_vendor_site_code <> gr_interface_info_rec(i).party_site_code) THEN
                  ln_errflg := 1;
                END IF;
--
              END IF;
--
              IF (ln_errflg = 1) THEN
--
                -- ログ出力
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_018 -- 妥当チェックエラーメッセージ(出荷支給予定実績警告)
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                              ,gv_param4_token
                              ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')          --IF_H.出荷日
                              ,gv_param5_token
                              ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')          --IF_H.着荷日
                              ,gv_param6_token
                              ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.運送業者
                              ,gv_param7_token
                              ,gr_interface_info_rec(i).shipping_method_code  --IF_H.配送区分
                              ,gv_param8_token
                              ,gr_interface_info_rec(i).party_site_code       --IF_H.出荷先
                              )
                              ,1
                              ,5000);
--
                -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- 配送No
                  lt_order_source_ref,  -- 移動No/依頼No
                  lt_eos_data_type,     -- EOSデータ種別
                  gv_reserved_class,    -- エラー種別：保留
                  lv_msg_buff,          -- エラー・メッセージ(出力用)
                  lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                  lv_retcode,           -- リターン・コード             --# 固定 #
                  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF; --err
--
            END IF;
--
          END IF; --EOS
--
        END IF;
--
        IF (ln_errflg = 0) THEN
--
          -- 4.数量項目の妥当性チェック
          -- IF_H.パレット回収枚数
          lt_collected_pallet_qty := gr_interface_info_rec(i).collected_pallet_qty;
          -- IF_H.パレット使用枚数
          lt_used_pallet_qty      := gr_interface_info_rec(i).used_pallet_qty;
          -- IF_L.出荷実績数量
          lt_shiped_quantity      := gr_interface_info_rec(i).shiped_quantity;
          -- IF_L.内訳数量(インタフェース用)
          lt_detailed_quantity    := gr_interface_info_rec(i).detailed_quantity;
--
          -- パレット回収枚数
          IF (lt_collected_pallet_qty IS NOT NULL) THEN
--
            IF (lt_collected_pallet_qty < 0) THEN
--
              ln_errflg := 1;
--
              -- ログ出力
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_022  -- 妥当チェックエラーメッセージ(数量項目エラー)
                            ,gv_param1_token
                            ,gv_param1_token01_nm
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                            ,gv_param5_token
                            ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                            )
                            ,1
                            ,5000);
--
              -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
              set_header_unit_reserveflg(
                lt_delivery_no,       -- 配送No
                lt_order_source_ref,  -- 移動No/依頼No
                lt_eos_data_type,     -- EOSデータ種別
                gv_reserved_class,    -- エラー種別：保留
                lv_msg_buff,          -- エラー・メッセージ(出力用)
                lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                lv_retcode,           -- リターン・コード             --# 固定 #
                lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              -- 処理ステータス：警告
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
          IF (ln_errflg = 0) THEN
--
            -- パレット使用枚数
            IF (lt_used_pallet_qty IS NOT NULL) THEN
--
              IF (lt_used_pallet_qty < 0) THEN
--
                ln_errflg := 1;
--
                -- ログ出力
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_022  -- 妥当チェックエラーメッセージ(数量項目エラー)
                              ,gv_param1_token
                              ,gv_param1_token02_nm
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                              )
                              ,1
                              ,5000);
--
                -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- 配送No
                  lt_order_source_ref,  -- 移動No/依頼No
                  lt_eos_data_type,     -- EOSデータ種別
                  gv_reserved_class,    -- エラー種別：保留
                  lv_msg_buff,          -- エラー・メッセージ(出力用)
                  lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                  lv_retcode,           -- リターン・コード             --# 固定 #
                  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
          IF (ln_errflg = 0) THEN
--
            -- 出荷実績数量
            IF (lt_shiped_quantity IS NOT NULL) THEN
--
              IF (lt_shiped_quantity < 0) THEN
--
                ln_errflg := 1;
--
                -- ログ出力
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_022  -- 妥当チェックエラーメッセージ(数量項目エラー)
                              ,gv_param1_token
                              ,gv_param1_token03_nm
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                              )
                              ,1
                              ,5000);
--
                -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- 配送No
                  lt_order_source_ref,  -- 移動No/依頼No
                  lt_eos_data_type,     -- EOSデータ種別
                  gv_reserved_class,    -- エラー種別：保留
                  lv_msg_buff,          -- エラー・メッセージ(出力用)
                  lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                  lv_retcode,           -- リターン・コード             --# 固定 #
                  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
          IF (ln_errflg = 0) THEN
--
            -- 内訳数量(インタフェース用)
            IF (lt_detailed_quantity IS NOT NULL) THEN
--
              IF (lt_detailed_quantity < 0) THEN
--
                ln_errflg := 1;
--
                -- ログ出力
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_022  -- 妥当チェックエラーメッセージ(数量項目エラー)
                              ,gv_param1_token
                              ,gv_param1_token04_nm
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.配送No
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.受注ソース参照
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOSデータ種別
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                              )
                              ,1
                              ,5000);
--
                -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- 配送No
                  lt_order_source_ref,  -- 移動No/依頼No
                  lt_eos_data_type,     -- EOSデータ種別
                  gv_reserved_class,    -- エラー種別：保留
                  lv_msg_buff,          -- エラー・メッセージ(出力用)
                  lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                  lv_retcode,           -- リターン・コード             --# 固定 #
                  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
        -- 3.  ロット導出、ステータスチェック
        -- 3.1 ドリンク,製品,ロット管理品
--
        IF (ln_errflg = 0) THEN
--
          IF ((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_2) AND --商品区分:ドリンク
              (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5) AND --品目区分:製品
              (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1))   --ロット:有(ロット管理品)
          THEN
--
            IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
            THEN
              OPEN cur_lots_product_check
              (
               gr_interface_info_rec(i).orderd_item_code
              ,gr_interface_info_rec(i).lot_no
              ,gv_prod_kbn_cd_2
              ,gv_item_kbn_cd_5
              ,gr_interface_info_rec(i).shipped_date
              );
            ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
              OPEN cur_lots_product_check
              (
               gr_interface_info_rec(i).orderd_item_code
              ,gr_interface_info_rec(i).lot_no
              ,gv_prod_kbn_cd_2
              ,gv_item_kbn_cd_5
              ,gr_interface_info_rec(i).arrival_date
              );
            END IF;
--
            <<cur_lots_product_loop>>
            LOOP
              -- 製造年月日、賞味期限、固有記号
              FETCH cur_lots_product_check INTO lt_product_date, lt_expiration_day, lt_original_sign;
              EXIT WHEN cur_lots_product_check%NOTFOUND;
--
              IF (ln_errflg = 0) THEN
--
                -- 3.1.1 製造年月日=0 or 賞味期限=0 or 固有記号=0 のチェック
                IF ((lt_product_date = '0') OR        --製造年月日
                    (lt_expiration_day = '0') OR      --賞味期限
                    (lt_original_sign = '0'))         --固有記号
                THEN
--
                  ln_errflg := 1;
--
                  -- (項目妥当チェックエラー)
                  lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                 gv_msg_kbn          -- 'XXWSH'
                                ,gv_msg_93a_019 -- 妥当チェックエラーメッセージ(項目妥当チェックエラー)
                                ,gv_param7_token
                                ,gr_interface_info_rec(i).delivery_no      --配送No
                                ,gv_param8_token
                                ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                ,gv_param1_token
                                ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                ,gv_param2_token
                                ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                ,gv_param3_token
                                ,gr_interface_info_rec(i).lot_ctl      --ロット
                                ,gv_param4_token
                                ,lt_product_date                       --製造年月日
                                ,gv_param5_token
                                ,lt_expiration_day                     --賞味期限
                                ,gv_param6_token
                                ,lt_original_sign                      --固有記号
                                )
                                ,1
                                ,5000);
--
                  -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                  set_header_unit_reserveflg(
                    lt_delivery_no,       -- 配送No
                    lt_order_source_ref,  -- 移動No/依頼No
                    lt_eos_data_type,     -- EOSデータ種別
                    gv_reserved_class,    -- エラー種別：保留
                    lv_msg_buff,          -- エラー・メッセージ(出力用)
                    lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                    lv_retcode,           -- リターン・コード             --# 固定 #
                    lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                  );
--
                  -- 処理ステータス：警告
                  ov_retcode := gv_status_warn;
--
                END IF;
--
              END IF;
--
              IF (ln_errflg = 0) THEN
--
                -- 3.1.2 製造年月日='YYYY/MM/DD'形式 or 賞味期限='YYYY/MM/DD' のチェック
                ld_todate_1 := FND_DATE.STRING_TO_DATE(lt_product_date, 'RR/MM/DD');
                ld_todate_2 := FND_DATE.STRING_TO_DATE(lt_expiration_day, 'RR/MM/DD');
--
                IF (ld_todate_1 IS NULL) OR
                   (ld_todate_2 IS NULL)
                THEN
--
                  ln_errflg := 1;
--
                  -- (項目妥当チェックエラー)
                  lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                 gv_msg_kbn          -- 'XXWSH'
                                ,gv_msg_93a_019  -- 妥当チェックエラーメッセージ(項目妥当チェックエラー)
                                ,gv_param7_token
                                ,gr_interface_info_rec(i).delivery_no      --配送No
                                ,gv_param8_token
                                ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                ,gv_param1_token
                                ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                ,gv_param2_token
                                ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                ,gv_param3_token
                                ,gr_interface_info_rec(i).lot_ctl      --ロット
                                ,gv_param4_token
                                ,lt_product_date                       --製造年月日
                                ,gv_param5_token
                                ,lt_expiration_day                     --賞味期限
                                ,gv_param6_token
                                ,lt_original_sign                      --固有記号
                                )
                                ,1
                                ,5000);
--
                  -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                  set_header_unit_reserveflg(
                    lt_delivery_no,       -- 配送No
                    lt_order_source_ref,  -- 移動No/依頼No
                    lt_eos_data_type,     -- EOSデータ種別
                    gv_reserved_class,    -- エラー種別：保留
                    lv_msg_buff,          -- エラー・メッセージ(出力用)
                    lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                    lv_retcode,           -- リターン・コード             --# 固定 #
                    lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                  );
--
                  -- 処理ステータス：警告
                  ov_retcode := gv_status_warn;
--
                END IF;
--
              END IF;
--
            END LOOP cur_lots_product_loop;
--
            CLOSE cur_lots_product_check;
--
            IF (ln_errflg = 0) THEN
--
              -- 3.1.3 品目検索
              IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
              THEN
--
                SELECT COUNT(xicv.item_id) item_cnt
                INTO   ln_cnt
                FROM   xxcmn_item_categories5_v xicv,
                       ic_lots_mst ilm,
                       xxcmn_item_mst2_v ximv
                WHERE  xicv.item_id = ilm.item_id
                AND    xicv.item_id = ximv.item_id
                AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code             --受注品目
                AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                       --ロットNo
                AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                                     --ロット管理品
                                                                                            --製造年月日
                AND    ilm.attribute1 = TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')
                AND    ilm.attribute2 = gr_interface_info_rec(i).original_character         --固有記号
                AND    ximv.inactive_ind   <> gn_view_disable                               -- 無効フラグ
                AND    ximv.obsolete_class <> gv_view_disable                               -- 廃止区分
                AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).shipped_date) -- 出荷日
                AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).shipped_date) -- 出荷日
                ;
--
              ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                SELECT COUNT(xicv.item_id) item_cnt
                INTO   ln_cnt
                FROM   xxcmn_item_categories5_v xicv,
                       ic_lots_mst ilm,
                       xxcmn_item_mst2_v ximv
                WHERE  xicv.item_id = ilm.item_id
                AND    xicv.item_id = ximv.item_id
                AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code             --受注品目
                AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                       --ロットNo
                AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                                     --ロット管理品
                                                                                            --製造年月日
                AND    ilm.attribute1 = TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')
                AND    ilm.attribute2 = gr_interface_info_rec(i).original_character         --固有記号
                AND    ximv.inactive_ind   <> gn_view_disable                               -- 無効フラグ
                AND    ximv.obsolete_class <> gv_view_disable                               -- 廃止区分
                AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).arrival_date) -- 着荷日
                AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).arrival_date) -- 着荷日
                ;
--
              END IF;
--
              -- 3.1.3.1 検索しヒット
              IF (ln_cnt > 0) THEN
--
                IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                THEN
                  OPEN cur_lots_status_check
                  (
                   gr_interface_info_rec(i).orderd_item_code
                  ,gr_interface_info_rec(i).lot_no
                  ,gr_interface_info_rec(i).designated_production_date
                  ,gr_interface_info_rec(i).original_character
                  ,gr_interface_info_rec(i).shipped_date
                  );
                ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
                  OPEN cur_lots_status_check
                  (
                   gr_interface_info_rec(i).orderd_item_code
                  ,gr_interface_info_rec(i).lot_no
                  ,gr_interface_info_rec(i).designated_production_date
                  ,gr_interface_info_rec(i).original_character
                  ,gr_interface_info_rec(i).arrival_date
                  );
                END IF;
--
                <<cur_lots_status_loop>>
                LOOP
                  -- 賞味期限、固有記号、ロットステータス
                  FETCH cur_lots_status_check INTO lt_expiration_day, lt_original_sign, lt_lot_status;
                  EXIT WHEN cur_lots_status_check%NOTFOUND;
--
                  IF (ln_errflg = 0) THEN
--
                    -- 賞味期限=抽出項目:賞味期限
                    IF (lt_expiration_day = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')) THEN
--
                      -- ステータス初期化
                      lt_pay_provision_rel := NULL;
                      lt_move_inst_rel     := NULL;
                      lt_ship_req_rel      := NULL;
--
                      -- ロットステータス情報取得
                      SELECT xlsv.pay_provision_rel                                       -- 有償支給(実績)
                            ,xlsv.move_inst_rel                                           -- 移動指示(実績)
                            ,xlsv.ship_req_rel                                            -- 出荷依頼(実績)
                      INTO  lt_pay_provision_rel
                           ,lt_move_inst_rel
                           ,lt_ship_req_rel
                      FROM  xxcmn_lot_status_v xlsv
                      WHERE xlsv.prod_class_code = gr_interface_info_rec(i).prod_kbn_cd   -- 商品区分
                      AND   xlsv.lot_status      = lt_lot_status;                         -- ロットステータス
--
                      ln_lot_err_flg := 0;    -- 初期化
--
                      -- ロットステータス判定
                      -- 有償出荷報告の場合
                      IF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) THEN
--
                        -- 保留設定
                        IF (lt_pay_provision_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      -- 拠点出荷確定報告/庭先出荷確定報告の場合
                      ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210)  OR
                             (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215))
                      THEN
--
                        -- 保留設定
                        IF (lt_ship_req_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      -- 移動出庫確定報告/移動入庫確定報告の場合
                      ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220)  OR
                             (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230))
                      THEN
--
                        -- 保留設定
                        IF (lt_move_inst_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      END IF;
--
                      IF (ln_lot_err_flg = 1) THEN
--
                        ln_errflg := 1;
--
                        -- (品質警告)
                        lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                       gv_msg_kbn          -- 'XXWSH'
                                      ,gv_msg_93a_021  -- 妥当チェックエラーメッセージ(品質警告)
                                      ,gv_param7_token
                                      ,gr_interface_info_rec(i).delivery_no      --配送No
                                      ,gv_param8_token
                                      ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                      ,gv_param1_token
                                      ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                      ,gv_param2_token
                                      ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                      ,gv_param3_token
                                      ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                                      ,gv_param4_token
                                      ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --製造年月日
                                      ,gv_param5_token
                                      ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --賞味期限
                                      ,gv_param6_token
                                      ,gr_interface_info_rec(i).original_character          --固有記号
                                      )
                                      ,1
                                      ,5000);
--
                        -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                        set_header_unit_reserveflg(
                          lt_delivery_no,       -- 配送No
                          lt_order_source_ref,  -- 移動No/依頼No
                          lt_eos_data_type,     -- EOSデータ種別
                          gv_reserved_class,    -- エラー種別：保留
                          lv_msg_buff,          -- エラー・メッセージ(出力用)
                          lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                          lv_retcode,           -- リターン・コード             --# 固定 #
                          lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                        );
--
                        -- 処理ステータス：警告
                        ov_retcode := gv_status_warn;
--
                      END IF;
--
                    ELSE
--
                      ln_errflg := 1;
--
                      -- (ロット警告)
                      lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                     gv_msg_kbn          -- 'XXWSH'
                                    ,gv_msg_93a_020  -- 妥当チェックエラーメッセージ(ロット警告)
                                    ,gv_param7_token
                                    ,gr_interface_info_rec(i).delivery_no      --配送No
                                    ,gv_param8_token
                                    ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                    ,gv_param1_token
                                    ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                    ,gv_param2_token
                                    ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                    ,gv_param3_token
                                    ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                                    ,gv_param4_token
                                    ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --製造年月日
                                    ,gv_param5_token
                                    ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --賞味期限
                                    ,gv_param6_token
                                    ,gr_interface_info_rec(i).original_character          --固有記号
                                    )
                                    ,1
                                    ,5000);
--
                      -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                      set_header_unit_reserveflg(
                        lt_delivery_no,       -- 配送No
                        lt_order_source_ref,  -- 移動No/依頼No
                        lt_eos_data_type,     -- EOSデータ種別
                        gv_reserved_class,    -- エラー種別：保留
                        lv_msg_buff,          -- エラー・メッセージ(出力用)
                        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                        lv_retcode,           -- リターン・コード             --# 固定 #
                        lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                      );
--
                      -- 処理ステータス：警告
                      ov_retcode := gv_status_warn;
--
                    END IF;
--
                  END IF;
--
                END LOOP cur_lots_status_loop;
--
                CLOSE cur_lots_status_check;
--
              -- 3.1.3.2 検索しヒットしなかった場合
              ELSE
--
                ln_errflg := 1;
--
                -- (ロット警告)
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_020  -- 妥当チェックエラーメッセージ(ロット警告)
                              ,gv_param7_token
                              ,gr_interface_info_rec(i).delivery_no      --配送No
                              ,gv_param8_token
                              ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                              ,gv_param4_token
                              ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --製造年月日
                              ,gv_param5_token
                              ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --賞味期限
                              ,gv_param6_token
                              ,gr_interface_info_rec(i).original_character          --固有記号
                              )
                              ,1
                              ,5000);
--
                -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- 配送No
                  lt_order_source_ref,  -- 移動No/依頼No
                  lt_eos_data_type,     -- EOSデータ種別
                  gv_reserved_class,    -- エラー種別：保留
                  lv_msg_buff,          -- エラー・メッセージ(出力用)
                  lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                  lv_retcode,           -- リターン・コード             --# 固定 #
                  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;  -- ドリンク,製品,ロット管理品
--
          END IF;
--
          -- 3.  ロット導出、ステータスチェック
          -- 3.2 リーフ,製品,ロット管理品
          IF (ln_errflg = 0) THEN
--
            IF ((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_1) AND   --商品区分:リーフ
                (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5) AND   --品目区分:製品
                (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1)) --ロット:有(ロット管理品)
            THEN
--
              IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
              THEN
                OPEN cur_lots_product_check
                (
                 gr_interface_info_rec(i).orderd_item_code --受注品目
                ,gr_interface_info_rec(i).lot_no           --ロットNo
                ,gv_prod_kbn_cd_1                          --商品区分
                ,gv_item_kbn_cd_5                          --品目区分
                ,gr_interface_info_rec(i).shipped_date
                );
              ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                OPEN cur_lots_product_check
                (
                 gr_interface_info_rec(i).orderd_item_code --受注品目
                ,gr_interface_info_rec(i).lot_no           --ロットNo
                ,gv_prod_kbn_cd_1                          --商品区分
                ,gv_item_kbn_cd_5                          --品目区分
                ,gr_interface_info_rec(i).arrival_date
                );
              END IF;
--
              <<cur_lots_product_r_loop>>
              LOOP
                -- 製造年月日、賞味期限、固有記号取得
                FETCH cur_lots_product_check INTO lt_product_date, lt_expiration_day, lt_original_sign;
                EXIT WHEN cur_lots_product_check%NOTFOUND;
--
                  -- 3.2.1 製造年月日=0 or 賞味期限=0 or 固有記号=0 のチェック
                IF (ln_errflg = 0) THEN
--
                  IF ((lt_expiration_day = '0') OR    --賞味期限
                      (lt_original_sign = '0'))       --固有記号
                  THEN
--
                    ln_errflg := 1;
--
                    -- (項目妥当チェックエラー)
                    lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                   gv_msg_kbn          -- 'XXWSH'
                                  ,gv_msg_93a_019 -- 妥当チェックエラーメッセージ(項目妥当チェックエラー)
                                  ,gv_param7_token
                                  ,gr_interface_info_rec(i).delivery_no      --配送No
                                  ,gv_param8_token
                                  ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                  ,gv_param1_token
                                  ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                  ,gv_param2_token
                                  ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                  ,gv_param3_token
                                  ,gr_interface_info_rec(i).lot_ctl      --ロット
                                  ,gv_param4_token
                                  ,lt_product_date                       --製造年月日
                                  ,gv_param5_token
                                  ,lt_expiration_day                     --賞味期限
                                  ,gv_param6_token
                                  ,lt_original_sign                      --固有記号
                                  )
                                  ,1
                                  ,5000);
--
                    -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                    set_header_unit_reserveflg(
                      lt_delivery_no,       -- 配送No
                      lt_order_source_ref,  -- 移動No/依頼No
                      lt_eos_data_type,     -- EOSデータ種別
                      gv_reserved_class,    -- エラー種別：保留
                      lv_msg_buff,          -- エラー・メッセージ(出力用)
                      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                      lv_retcode,           -- リターン・コード             --# 固定 #
                      lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                    );
--
                    -- 処理ステータス：警告
                    ov_retcode := gv_status_warn;
--
                  END IF;
--
                END IF;
--
                  -- 3.2.2 賞味期限='YYYY/MM/DD' のチェック
                IF (ln_errflg = 0) THEN
--
                  ld_todate_1 := FND_DATE.STRING_TO_DATE(lt_expiration_day, 'RR/MM/DD');
--
                  IF (ld_todate_1 IS NULL) THEN
--
                    ln_errflg := 1;
--
                    -- (項目妥当チェックエラー)
                    lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                   gv_msg_kbn          -- 'XXWSH'
                                  ,gv_msg_93a_019  -- 妥当チェックエラーメッセージ(項目妥当チェックエラー)
                                  ,gv_param7_token
                                  ,gr_interface_info_rec(i).delivery_no      --配送No
                                  ,gv_param8_token
                                  ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                  ,gv_param1_token
                                  ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                  ,gv_param2_token
                                  ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                  ,gv_param3_token
                                  ,gr_interface_info_rec(i).lot_ctl      --ロット
                                  ,gv_param4_token
                                  ,lt_product_date                       --製造年月日
                                  ,gv_param5_token
                                  ,lt_expiration_day                     --賞味期限
                                  ,gv_param6_token
                                  ,lt_original_sign                      --固有記号
                                  )
                                  ,1
                                  ,5000);
--
                    -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                    set_header_unit_reserveflg(
                      lt_delivery_no,       -- 配送No
                      lt_order_source_ref,  -- 移動No/依頼No
                      lt_eos_data_type,     -- EOSデータ種別
                      gv_reserved_class,    -- エラー種別：保留
                      lv_msg_buff,          -- エラー・メッセージ(出力用)
                      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                      lv_retcode,           -- リターン・コード             --# 固定 #
                      lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                    );
--
                    -- 処理ステータス：警告
                    ov_retcode := gv_status_warn;
--
                  END IF;
--
                END IF;
--
                IF (ln_errflg = 0) THEN
--
                  -- 3.2.3 検索
                  IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                      (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                      (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                      (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                  THEN
                    SELECT COUNT(xicv.item_id) item_cnt
                    INTO   ln_cnt
                    FROM   xxcmn_item_categories5_v xicv,
                           ic_lots_mst ilm,
                           xxcmn_item_mst2_v ximv
                    WHERE  xicv.item_id = ilm.item_id
                    AND    xicv.item_id = ximv.item_id
                    AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code             --受注品目
                    AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                       --ロットNo
                    AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                                     --ロット管理品
                    AND    ilm.attribute1 = TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD') --製造年月日
                    AND    ilm.attribute2 = gr_interface_info_rec(i).original_character         --固有記号
                    AND    ximv.inactive_ind   <> gn_view_disable                               -- 無効フラグ
                    AND    ximv.obsolete_class <> gv_view_disable                               -- 廃止区分
                    AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).shipped_date) -- 出荷日
                    AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).shipped_date) -- 出荷日
                    ;
--
                  ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                    SELECT COUNT(xicv.item_id) item_cnt
                    INTO   ln_cnt
                    FROM   xxcmn_item_categories5_v xicv,
                           ic_lots_mst ilm,
                           xxcmn_item_mst2_v ximv
                    WHERE  xicv.item_id = ilm.item_id
                    AND    xicv.item_id = ximv.item_id
                    AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code             --受注品目
                    AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                       --ロットNo
                    AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                                     --ロット管理品
                    AND    ilm.attribute1 = TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD') --製造年月日
                    AND    ilm.attribute2 = gr_interface_info_rec(i).original_character         --固有記号
                    AND    ximv.inactive_ind   <> gn_view_disable                               -- 無効フラグ
                    AND    ximv.obsolete_class <> gv_view_disable                               -- 廃止区分
                    AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).arrival_date) -- 着荷日
                    AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).arrival_date) -- 着荷日
                    ;
                  END IF;
--
                  -- 3.2.3.1 検索しヒット
                  IF (ln_cnt > 0) THEN  --*E
--
                    IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                    THEN
--
                      OPEN cur_lots_status_check
                      (
                       gr_interface_info_rec(i).orderd_item_code             --受注品目
                      ,gr_interface_info_rec(i).lot_no                       --ロットNo
                      ,gr_interface_info_rec(i).designated_production_date   --製造年月日
                      ,gr_interface_info_rec(i).original_character           --固有記号
                      ,gr_interface_info_rec(i).shipped_date
                      );
--
                    ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                      OPEN cur_lots_status_check
                      (
                       gr_interface_info_rec(i).orderd_item_code             --受注品目
                      ,gr_interface_info_rec(i).lot_no                       --ロットNo
                      ,gr_interface_info_rec(i).designated_production_date   --製造年月日
                      ,gr_interface_info_rec(i).original_character           --固有記号
                      ,gr_interface_info_rec(i).arrival_date
                      );
                    END IF;
--
                    <<cur_lots_status_r_loop>>
                    LOOP
                     --賞味期限、固有記号、ロットステータス取得
                      FETCH cur_lots_status_check INTO lt_expiration_day, lt_original_sign, lt_lot_status;
                      EXIT WHEN cur_lots_status_check%NOTFOUND;
--
                      -- 賞味期限=抽出項目:賞味期限
                      IF (lt_expiration_day = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')) THEN  --*Y
--
                        -- ステータス初期化
                        lt_pay_provision_rel := NULL;
                        lt_move_inst_rel     := NULL;
                        lt_ship_req_rel      := NULL;
--
                        -- ロットステータス情報取得
                        SELECT xlsv.pay_provision_rel                                       -- 有償支給(実績)
                              ,xlsv.move_inst_rel                                           -- 移動指示(実績)
                              ,xlsv.ship_req_rel                                            -- 出荷依頼(実績)
                        INTO  lt_pay_provision_rel
                             ,lt_move_inst_rel
                             ,lt_ship_req_rel
                        FROM  xxcmn_lot_status_v xlsv
                        WHERE xlsv.prod_class_code = gr_interface_info_rec(i).prod_kbn_cd   -- 商品区分
                        AND   xlsv.lot_status      = lt_lot_status;                         -- ロットステータス
--
                        ln_lot_err_flg := 0;    -- 初期化
--
                        -- ロットステータス判定
                        -- 有償出荷報告の場合
                        IF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) THEN
--
                          -- 保留設定
                          IF (lt_pay_provision_rel = gv_yesno_n) THEN
                            ln_lot_err_flg := 1;
                          END IF;
--
                        -- 拠点出荷確定報告/庭先出荷確定報告の場合
                        ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210)  OR
                               (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215))
                        THEN
--
                          -- 保留設定
                          IF (lt_ship_req_rel = gv_yesno_n) THEN
                            ln_lot_err_flg := 1;
                          END IF;
--
                        -- 移動出庫確定報告/移動入庫確定報告の場合
                        ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220)  OR
                               (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230))
                        THEN
--
                          -- 保留設定
                          IF (lt_move_inst_rel = gv_yesno_n) THEN
                            ln_lot_err_flg := 1;
                          END IF;
--
                        END IF;
--
                        IF (ln_lot_err_flg = 1) THEN
--
                          ln_errflg := 1;
--
                          -- (品質警告)
                          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                         gv_msg_kbn          -- 'XXWSH'
                                        ,gv_msg_93a_021  -- 妥当チェックエラーメッセージ(品質警告)
                                        ,gv_param7_token
                                        ,gr_interface_info_rec(i).delivery_no      --配送No
                                        ,gv_param8_token
                                        ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                        ,gv_param1_token
                                        ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                        ,gv_param2_token
                                        ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                        ,gv_param3_token
                                        ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                                        ,gv_param4_token
                                        ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD') --製造年月日
                                        ,gv_param5_token
                                        ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                --賞味期限
                                        ,gv_param6_token
                                        ,gr_interface_info_rec(i).original_character         --固有記号
                                        )
                                        ,1
                                        ,5000);
--
                          -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                          set_header_unit_reserveflg(
                            lt_delivery_no,       -- 配送No
                            lt_order_source_ref,  -- 移動No/依頼No
                            lt_eos_data_type,     -- EOSデータ種別
                            gv_reserved_class,    -- エラー種別：保留
                            lv_msg_buff,          -- エラー・メッセージ(出力用)
                            lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                            lv_retcode,           -- リターン・コード             --# 固定 #
                            lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                          );
--
                          -- 処理ステータス：警告
                          ov_retcode := gv_status_warn;
--
                        END IF;
--
                      -- 賞味期限<>抽出項目:賞味期限
                      ELSE  --*Y
--
                        ln_errflg := 1;
--
                        -- (ロット警告)
                        lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                       gv_msg_kbn          -- 'XXWSH'
                                      ,gv_msg_93a_020  -- 妥当チェックエラーメッセージ(ロット警告)
                                      ,gv_param7_token
                                      ,gr_interface_info_rec(i).delivery_no      --配送No
                                      ,gv_param8_token
                                      ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                      ,gv_param1_token
                                      ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                      ,gv_param2_token
                                      ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                      ,gv_param3_token
                                      ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                                      ,gv_param4_token
                                      ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD') --製造年月日
                                      ,gv_param5_token
                                      ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                --賞味期限
                                      ,gv_param6_token
                                      ,gr_interface_info_rec(i).original_character         --固有記号
                                      )
                                      ,1
                                      ,5000);
--
                        -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                        set_header_unit_reserveflg(
                          lt_delivery_no,       -- 配送No
                          lt_order_source_ref,  -- 移動No/依頼No
                          lt_eos_data_type,     -- EOSデータ種別
                          gv_reserved_class,    -- エラー種別：保留
                          lv_msg_buff,          -- エラー・メッセージ(出力用)
                          lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                          lv_retcode,           -- リターン・コード             --# 固定 #
                          lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                        );
--
                        -- 処理ステータス：警告
                        ov_retcode := gv_status_warn;
--
                      END IF;
--
                    END LOOP cur_lots_status_r_loop;
--
                    CLOSE cur_lots_status_check;
--
                  -- 3.2.3.2 検索しヒットしなかった場合
                  ELSE
--
                    IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                    THEN
--
                      SELECT COUNT(xicv.item_id) item_cnt
                      INTO   ln_cnt2
                      FROM   xxcmn_item_categories5_v xicv,
                             ic_lots_mst ilm,
                             xxcmn_item_mst2_v ximv
                      WHERE  xicv.item_id = ilm.item_id
                      AND    xicv.item_id = ximv.item_id
                      AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code       --受注品目
                      AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                 --ロットNo
                      AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                               --ロット管理品
                      AND    ilm.attribute3  = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD') --賞味期限
                      AND    ilm.attribute2  = gr_interface_info_rec(i).original_character  --固有記号
                      AND    ximv.inactive_ind   <> gn_view_disable                               -- 無効フラグ
                      AND    ximv.obsolete_class <> gv_view_disable                               -- 廃止区分
                      AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).shipped_date) -- 出荷日
                      AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).shipped_date) -- 出荷日
                      ;
--
                      IF (ln_cnt2 = 1) THEN
                        SELECT ilm.attribute23 lot_status      --ロットステータス
                        INTO   lt_lot_status
                        FROM   xxcmn_item_categories5_v xicv,
                               ic_lots_mst ilm,
                               xxcmn_item_mst2_v ximv
                        WHERE  xicv.item_id = ilm.item_id
                        AND    xicv.item_id = ximv.item_id
                        AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code       --受注品目
                        AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                 --ロットNo
                        AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                               --ロット管理品
                        AND    ilm.attribute3  = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD') --賞味期限
                        AND    ilm.attribute2  = gr_interface_info_rec(i).original_character  --固有記号
                        AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).shipped_date) -- 出荷日
                        AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).shipped_date) -- 出荷日
                        ;
                      END IF;
--
                    ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                      -- 検索なし-->検索しヒット
                      SELECT COUNT(xicv.item_id) item_cnt
                      INTO   ln_cnt2
                      FROM   xxcmn_item_categories5_v xicv,
                             ic_lots_mst ilm,
                             xxcmn_item_mst2_v ximv
                      WHERE  xicv.item_id = ilm.item_id
                      AND    xicv.item_id = ximv.item_id
                      AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code       --受注品目
                      AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                 --ロットNo
                      AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                               --ロット管理品
                      AND    ilm.attribute3  = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD') --賞味期限
                      AND    ilm.attribute2  = gr_interface_info_rec(i).original_character  --固有記号
                      AND    ximv.inactive_ind   <> gn_view_disable                               -- 無効フラグ
                      AND    ximv.obsolete_class <> gv_view_disable                               -- 廃止区分
                      AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).arrival_date) -- 着荷日
                      AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).arrival_date) -- 着荷日
                      ;
--
                      IF (ln_cnt2 = 1) THEN
                        SELECT ilm.attribute23 lot_status      --ロットステータス
                        INTO   lt_lot_status
                        FROM   xxcmn_item_categories5_v xicv,
                               ic_lots_mst ilm,
                               xxcmn_item_mst2_v ximv
                        WHERE  xicv.item_id = ilm.item_id
                        AND    xicv.item_id = ximv.item_id
                        AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code       --受注品目
                        AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                 --ロットNo
                        AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                               --ロット管理品
                        AND    ilm.attribute3  = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD') --賞味期限
                        AND    ilm.attribute2  = gr_interface_info_rec(i).original_character  --固有記号
                        AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).arrival_date) -- 着荷日
                        AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).arrival_date) -- 着荷日
                        ;
                      END IF;
--
                    END IF;
--
                    -- 3.2.3.2.1 １件ヒット
                    IF (ln_cnt2 = 1) THEN
--
                      -- ステータス初期化
                      lt_pay_provision_rel := NULL;
                      lt_move_inst_rel     := NULL;
                      lt_ship_req_rel      := NULL;
--
                      -- ロットステータス情報取得
                      SELECT xlsv.pay_provision_rel                                       -- 有償支給(実績)
                            ,xlsv.move_inst_rel                                           -- 移動指示(実績)
                            ,xlsv.ship_req_rel                                            -- 出荷依頼(実績)
                      INTO  lt_pay_provision_rel
                           ,lt_move_inst_rel
                           ,lt_ship_req_rel
                      FROM  xxcmn_lot_status_v xlsv
                      WHERE xlsv.prod_class_code = gr_interface_info_rec(i).prod_kbn_cd   -- 商品区分
                      AND   xlsv.lot_status      = lt_lot_status;                         -- ロットステータス
--
                      ln_lot_err_flg := 0;    -- 初期化
--
                      -- ロットステータス判定
                      -- 有償出荷報告の場合
                      IF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) THEN
--
                        -- 保留設定
                        IF (lt_pay_provision_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      -- 拠点出荷確定報告/庭先出荷確定報告の場合
                      ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210)  OR
                             (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215))
                      THEN
--
                        -- 保留設定
                        IF (lt_ship_req_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      -- 移動出庫確定報告/移動入庫確定報告の場合
                      ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220)  OR
                             (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230))
                      THEN
--
                        -- 保留設定
                        IF (lt_move_inst_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      END IF;
--
                      IF (ln_lot_err_flg = 1) THEN
--
                        ln_errflg := 1;
--
                        -- (品質警告)
                        lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                       gv_msg_kbn          -- 'XXWSH'
                                      ,gv_msg_93a_021  -- 妥当チェックエラーメッセージ(品質警告)
                                      ,gv_param7_token
                                      ,gr_interface_info_rec(i).delivery_no      --配送No
                                      ,gv_param8_token
                                      ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                      ,gv_param1_token
                                      ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                      ,gv_param2_token
                                      ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                      ,gv_param3_token
                                      ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                                      ,gv_param4_token
                                      ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --製造年月日
                                      ,gv_param5_token
                                      ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --賞味期限
                                      ,gv_param6_token
                                      ,gr_interface_info_rec(i).original_character          --固有記号
                                      )
                                      ,1
                                      ,5000);
--
                        -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                        set_header_unit_reserveflg(
                          lt_delivery_no,       -- 配送No
                          lt_order_source_ref,  -- 移動No/依頼No
                          lt_eos_data_type,     -- EOSデータ種別
                          gv_reserved_class,    -- エラー種別：保留
                          lv_msg_buff,          -- エラー・メッセージ(出力用)
                          lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                          lv_retcode,           -- リターン・コード             --# 固定 #
                          lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                        );
--
                        -- 処理ステータス：警告
                        ov_retcode := gv_status_warn;
--
                      END IF;
--
                    -- 3.2.3.2.2 複数件ヒット
                    ELSIF (ln_cnt2 > 1) THEN
--
                      ln_errflg := 1;
--
                      -- (ロット警告)
                      lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                     gv_msg_kbn          -- 'XXWSH'
                                    ,gv_msg_93a_020  -- 妥当チェックエラーメッセージ(ロット警告)
                                    ,gv_param7_token
                                    ,gr_interface_info_rec(i).delivery_no      --配送No
                                    ,gv_param8_token
                                    ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                    ,gv_param1_token
                                    ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                    ,gv_param2_token
                                    ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                    ,gv_param3_token
                                    ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                                    ,gv_param4_token
                                    ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --製造年月日
                                    ,gv_param5_token
                                    ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --賞味期限
                                    ,gv_param6_token
                                    ,gr_interface_info_rec(i).original_character          --固有記号
                                    )
                                    ,1
                                    ,5000);
--
                      -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                      set_header_unit_reserveflg(
                        lt_delivery_no,       -- 配送No
                        lt_order_source_ref,  -- 移動No/依頼No
                        lt_eos_data_type,     -- EOSデータ種別
                        gv_reserved_class,    -- エラー種別：保留
                        lv_msg_buff,          -- エラー・メッセージ(出力用)
                        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                        lv_retcode,           -- リターン・コード             --# 固定 #
                        lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                      );
--
                      -- 処理ステータス：警告
                      ov_retcode := gv_status_warn;
--
                    -- 3.2.3.2.3 ヒットなし
                    ELSIF (ln_cnt2 = 0) THEN
--
                     ln_errflg := 1;
--
                      -- (ロット警告)
                      lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                     gv_msg_kbn          -- 'XXWSH'
                                    ,gv_msg_93a_020  -- 妥当チェックエラーメッセージ(ロット警告)
                                    ,gv_param7_token
                                    ,gr_interface_info_rec(i).delivery_no      --配送No
                                    ,gv_param8_token
                                    ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                    ,gv_param1_token
                                    ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                    ,gv_param2_token
                                    ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                    ,gv_param3_token
                                    ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                                    ,gv_param4_token
                                    ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --製造年月日
                                    ,gv_param5_token
                                    ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --賞味期限
                                    ,gv_param6_token
                                    ,gr_interface_info_rec(i).original_character          --固有記号
                                    )
                                    ,1
                                    ,5000);
--
                      -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                      set_header_unit_reserveflg(
                        lt_delivery_no,       -- 配送No
                        lt_order_source_ref,  -- 移動No/依頼No
                        lt_eos_data_type,     -- EOSデータ種別
                        gv_reserved_class,    -- エラー種別：保留
                        lv_msg_buff,          -- エラー・メッセージ(出力用)
                        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                        lv_retcode,           -- リターン・コード             --# 固定 #
                        lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                      );
--
                      -- 処理ステータス：警告
                      ov_retcode := gv_status_warn;
--
                    END IF;
--
                  END IF;
--
                END IF;
--
              END LOOP cur_lots_product_r_loop;
--
              CLOSE cur_lots_product_check;
--
            END IF;  --リーフ,製品,ロット管理品
--
          END IF;
--
          -- 3.  ロット導出、ステータスチェック
          -- 3.3 ドリンクorリーフ,製品以外,ロット管理品
          IF (ln_errflg = 0) THEN
--
            IF (((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_2) OR   --商品区分:ドリンクorリーフ
                 (gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_1)) AND
                (gr_interface_info_rec(i).item_kbn_cd <> gv_item_kbn_cd_5)  AND --品目区分:製品以外
                (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1))         --ロット:有(ロット管理品)
            THEN
--
              -- 3.3.1 抽出項目:ロットID=0
              IF (gr_interface_info_rec(i).lot_id = 0) THEN
--
                ln_errflg := 1;
--
                -- (項目妥当チェックエラー)
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_019 -- 妥当チェックエラーメッセージ(項目妥当チェックエラー)
                              ,gv_param7_token
                              ,gr_interface_info_rec(i).delivery_no      --配送No
                              ,gv_param8_token
                              ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).lot_ctl      --ロット
                              ,gv_param4_token
                              ,lt_product_date                       --製造年月日
                              ,gv_param5_token
                              ,lt_expiration_day                     --賞味期限
                              ,gv_param6_token
                              ,lt_original_sign                      --固有記号
                              )
                              ,1
                              ,5000);
--
                -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- 配送No
                  lt_order_source_ref,  -- 移動No/依頼No
                  lt_eos_data_type,     -- EOSデータ種別
                  gv_reserved_class,    -- エラー種別：保留
                  lv_msg_buff,          -- エラー・メッセージ(出力用)
                  lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                  lv_retcode,           -- リターン・コード             --# 固定 #
                  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              ELSE
--
                -- 3.3.2 検索
                IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                THEN
--
                  SELECT COUNT(xicv.item_id) item_cnt
                  INTO   ln_cnt
                  FROM   xxcmn_item_categories5_v xicv,
                         ic_lots_mst ilm,
                         xxcmn_item_mst2_v ximv
                  WHERE  xicv.item_id = ilm.item_id
                  AND    xicv.item_id = ximv.item_id
                  AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code  --受注品目
                  AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                          --ロット管理品
                  AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no            --ロットNo
                  AND    ximv.inactive_ind   <> gn_view_disable                               -- 無効フラグ
                  AND    ximv.obsolete_class <> gv_view_disable                               -- 廃止区分
                  AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).shipped_date) -- 出荷日
                  AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).shipped_date) -- 出荷日
                  ;
--
                ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                  SELECT COUNT(xicv.item_id) item_cnt
                  INTO   ln_cnt
                  FROM   xxcmn_item_categories5_v xicv,
                         ic_lots_mst ilm,
                         xxcmn_item_mst2_v ximv
                  WHERE  xicv.item_id = ilm.item_id
                  AND    xicv.item_id = ximv.item_id
                  AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code  --受注品目
                  AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                          --ロット管理品
                  AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no            --ロットNo
                  AND    ximv.inactive_ind   <> gn_view_disable                               -- 無効フラグ
                  AND    ximv.obsolete_class <> gv_view_disable                               -- 廃止区分
                  AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).arrival_date) -- 着荷日
                  AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).arrival_date) -- 着荷日
                  ;
--
                END IF;
--
                -- ヒットしなかった場合
                IF (ln_cnt = 0) THEN
--
                  ln_errflg := 1;
--
                  -- (ロット警告)
                  lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                 gv_msg_kbn          -- 'XXWSH'
                                ,gv_msg_93a_020  -- 妥当チェックエラーメッセージ(ロット警告)
                                ,gv_param7_token
                                ,gr_interface_info_rec(i).delivery_no      --配送No
                                ,gv_param8_token
                                ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                ,gv_param1_token
                                ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                ,gv_param2_token
                                ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                ,gv_param3_token
                                ,gr_interface_info_rec(i).orderd_item_code      --IF_L.受注品目
                                ,gv_param4_token
                                ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --製造年月日
                                ,gv_param5_token
                                ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --賞味期限
                                ,gv_param6_token
                                ,gr_interface_info_rec(i).original_character          --固有記号
                                )
                                ,1
                                ,5000);
--
                  -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                  set_header_unit_reserveflg(
                    lt_delivery_no,       -- 配送No
                    lt_order_source_ref,  -- 移動No/依頼No
                    lt_eos_data_type,     -- EOSデータ種別
                    gv_reserved_class,    -- エラー種別：保留
                    lv_msg_buff,          -- エラー・メッセージ(出力用)
                    lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                    lv_retcode,           -- リターン・コード             --# 固定 #
                    lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                  );
--
                  -- 処理ステータス：警告
                  ov_retcode := gv_status_warn;
--
                END IF;
--
              END IF;
--
            END IF;
--
          END IF;
--
          -- 3.  ロット導出、ステータスチェック
          -- 3.4 ドリンクorリーフ,製品以外,ロット管理品対象外
          IF (ln_errflg = 0) THEN
--
            IF (((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_2) OR   --商品区分:ドリンクorリーフ
                 (gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_1)) AND
                (gr_interface_info_rec(i).item_kbn_cd <> gv_item_kbn_cd_5)  AND --品目区分:製品以外
                (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_0))         --ロット:無有(ロット管理品対象外)
            THEN
              -- 3.4.1 ロットID<>0の場合エラー
              IF (gr_interface_info_rec(i).lot_id <> 0) THEN
--
                ln_errflg := 1;
--
                -- (項目妥当チェックエラー)
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_019  -- 妥当チェックエラーメッセージ(項目妥当チェックエラー)
                              ,gv_param7_token
                              ,gr_interface_info_rec(i).delivery_no      --配送No
                              ,gv_param8_token
                              ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).lot_ctl      --ロット
                              ,gv_param4_token
                              ,lt_product_date                       --製造年月日
                              ,gv_param5_token
                              ,lt_expiration_day                     --賞味期限
                              ,gv_param6_token
                              ,lt_original_sign                      --固有記号
                              )
                              ,1
                              ,5000);
--
                -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- 配送No
                  lt_order_source_ref,  -- 移動No/依頼No
                  lt_eos_data_type,     -- EOSデータ種別
                  gv_reserved_class,    -- エラー種別：保留
                  lv_msg_buff,          -- エラー・メッセージ(出力用)
                  lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                  lv_retcode,           -- リターン・コード             --# 固定 #
                  lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
                -- 処理ステータス：警告
                ov_retcode := gv_status_warn;
--
              END IF;
--
              /*----------------------------------------------------------------------------------
              ロット管理品外だからチェック不要？
--
--            -- 製造年月日、賞味期限、固有記号のチェック
              IF (ln_errflg = 0) THEN
--
                IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                THEN
                  OPEN cur_lots_product_check2
                  (
                   gr_interface_info_rec(i).orderd_item_code
                  ,gr_interface_info_rec(i).lot_no
                  ,gr_interface_info_rec(i).prod_kbn_cd
                  ,gv_item_kbn_cd_5
                  ,gr_interface_info_rec(i).shipped_date
                  );
                ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
                  OPEN cur_lots_product_check2
                  (
                   gr_interface_info_rec(i).orderd_item_code
                  ,gr_interface_info_rec(i).lot_no
                  ,gr_interface_info_rec(i).prod_kbn_cd
                  ,gv_item_kbn_cd_5
                  ,gr_interface_info_rec(i).arrival_date
                  );
                END IF;
--
                <<cur_lots_product_loop2>>
                LOOP
                  -- 製造年月日、賞味期限、固有記号
                  FETCH cur_lots_product_check2 INTO lt_product_date, lt_expiration_day, lt_original_sign;
                  EXIT WHEN cur_lots_product_check%NOTFOUND;
--
                  -- 3.4.2
                  IF ((lt_product_date <> '0') OR       --製造年月日
                      (lt_expiration_day <> '0') OR     --賞味期限
                      (lt_original_sign <> '0'))        --固有記号
                  THEN
--
                    ln_errflg := 1;
--
                    -- (項目妥当チェックエラー)
                    lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                   gv_msg_kbn         -- 'XXWSH'
                                  ,gv_msg_93a_019 -- 妥当チェックエラーメッセージ(項目妥当チェックエラー)
                                  ,gv_param7_token
                                  ,gr_interface_info_rec(i).delivery_no      --配送No
                                  ,gv_param8_token
                                  ,gr_interface_info_rec(i).order_source_ref --受注ソース参照
                                  ,gv_param1_token
                                  ,gr_interface_info_rec(i).prod_kbn_cd  --商品区分
                                  ,gv_param2_token
                                  ,gr_interface_info_rec(i).item_kbn_cd  --品目区分
                                  ,gv_param3_token
                                  ,gr_interface_info_rec(i).lot_ctl      --ロット
                                  ,gv_param4_token
                                  ,lt_product_date                       --製造年月日
                                  ,gv_param5_token
                                  ,lt_expiration_day                     --賞味期限
                                  ,gv_param6_token
                                  ,lt_original_sign                      --固有記号
                                  )
                                  ,1
                                  ,5000);
--
                    -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
                    set_header_unit_reserveflg(
                      lt_delivery_no,       -- 配送No
                      lt_order_source_ref,  -- 移動No/依頼No
                      lt_eos_data_type,     -- EOSデータ種別
                      gv_reserved_class,    -- エラー種別：保留
                      lv_msg_buff,          -- エラー・メッセージ(出力用)
                      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                      lv_retcode,           -- リターン・コード             --# 固定 #
                      lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                    );
--
                    -- 処理ステータス：警告
                    ov_retcode := gv_status_warn;
--
                  END IF;
--
                END LOOP cur_lots_product_loop2;
--
                CLOSE cur_lots_product_check2;
--
              END IF;
              ---------------------------------------------------------------------------------*/
--
            END IF;
--
          END IF;
--
        END IF;
--
        -- 5.
        -- 5.1 ロット管理品のチェック
        IF (ln_errflg = 0) THEN
--
        -- ロット管理品の場合
          IF (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1) THEN
--
            -- ロット数量が設定されていない場合
            IF (gr_interface_info_rec(i).detailed_quantity IS NULL) THEN
--
              ln_errflg := 1;
--
              -- (内訳数量未設定エラー)
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn                                     -- 'XXWSH'
                            ,gv_msg_93a_146          -- ロット管理品の内訳数量未設定エラーメッセージ
                            ,gv_param1_token
                            ,gr_interface_info_rec(i).delivery_no           -- IF_H.配送No
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).order_source_ref      -- IF_H.受注ソース参照
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.受注品目
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).lot_no                -- IF_L.ロットNo
                            )
                            ,1
                            ,5000);
--
              -- 配送No/移動No-EOSデータ種別単位で妥当チェックエラーflagをセット
              set_header_unit_reserveflg(
                lt_delivery_no,       -- 配送No
                lt_order_source_ref,  -- 移動No/依頼No
                lt_eos_data_type,     -- EOSデータ種別
                gv_reserved_class,    -- エラー種別：保留
                lv_msg_buff,          -- エラー・メッセージ(出力用)
                lv_errbuf,            -- エラー・メッセージ           --# 固定 #
                lv_retcode,           -- リターン・コード             --# 固定 #
                lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
              );
--
              -- 処理ステータス：警告
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP appropriate_chk_line_loop;
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
  END appropriate_check;
--
 /**********************************************************************************
  * Procedure Name   : order_headers_ins
  * Description      : 受注ヘッダアドオン(外部倉庫編集) プロシージャ(A-8-2)
  ***********************************************************************************/
  PROCEDURE order_headers_ins(
    in_index                IN  NUMBER,                 -- データindex
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_headers_ins'; -- プログラム名
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
    lv_time_def                   CONSTANT VARCHAR2(1) := ':';
--
    -- *** ローカル変数 ***
    -- 受注ヘッダアドオンID
    lt_order_header_id             xxwsh_order_headers_all.order_header_id%TYPE;
    -- 成績管理部署
    lt_location_code               xxwsh_order_headers_all.performance_management_dept%TYPE;
    -- 取引タイプID
    lt_transaction_type_id         xxwsh_oe_transaction_types_v.transaction_type_id%TYPE;
--
    -- 最大パレット枚数算出関数パラメータ
    lv_code_class1                VARCHAR2(2);                -- 1.コード区分１
    lv_entering_despatching_code1 VARCHAR2(4);                -- 2.入出庫場所コード１
    lv_code_class2                VARCHAR2(2);                -- 3.コード区分２
    lv_entering_despatching_code2 VARCHAR2(9);                -- 4.入出庫場所コード２
    ld_standard_date              DATE;                       -- 5.基準日(適用日基準日)
    lv_ship_methods               VARCHAR2(2);                -- 6.配送区分
    on_drink_deadweight           NUMBER;                     -- 7.ドリンク積載重量
    on_leaf_deadweight            NUMBER;                     -- 8.リーフ積載重量
    on_drink_loading_capacity     NUMBER;                     -- 9.ドリンク積載容積
    on_leaf_loading_capacity      NUMBER;                     -- 10.リーフ積載容積
    on_palette_max_qty            NUMBER;                     -- 11.パレット最大枚数
--
    --着荷時間FROM,TO
    lv_arrival_time_from          VARCHAR2(4);
    lv_arrival_time_to            VARCHAR2(4);
    lv_arrival_from               VARCHAR2(5);
    lv_arrival_to                 VARCHAR2(5);
--
    ln_ret_code                   NUMBER;                     -- リターン・コード
--
    lv_shipping_class             VARCHAR2(10);
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
--  初期化
    gr_order_h_rec := gr_order_h_ini;
--
    -- 受注ヘッダID取得(シーケンス)
    SELECT xxwsh_order_headers_all_s1.NEXTVAL
    INTO   lt_order_header_id
    FROM   dual;
--
    -- 受注ヘッダアドオン編集処理
    -- 受注ヘッダID
    gr_order_h_rec.order_header_id          := lt_order_header_id;
--
    -- 受注タイプID
    -- 在庫受入用(受注カテゴリ=返品)の取引タイプIDを取得
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) THEN
      lv_shipping_class := gv_shipping_class_01;
    ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215) THEN
      lv_shipping_class := gv_shipping_class_08;
    END IF;
--
    BEGIN
      SELECT xtv.transaction_type_id         -- 取引タイプID
      INTO   lt_transaction_type_id
      FROM   xxwsh_oe_transaction_types_v  xtv  -- 受注タイプView
      WHERE  xtv.transaction_type_name = lv_shipping_class;  -- 取引タイプ名
--
      gr_order_h_rec.order_type_id   := lt_transaction_type_id;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_expt;     -- 受注タイプが取得できない場合はABENDにしてROLLBACKさせる
    END;
--
    -- 組織ID
    gr_order_h_rec.organization_id          := gv_master_org_id;
    -- 最新フラグ
    gr_order_h_rec.latest_external_flag     := gv_yesno_y;
    -- 受注日
    gr_order_h_rec.ordered_date             := gd_sysdate;
    -- 顧客ID
    gr_order_h_rec.customer_id              := gr_interface_info_rec(in_index).customer_id;
    -- 顧客
    gr_order_h_rec.customer_code            := gr_interface_info_rec(in_index).customer_code;
    -- 出荷先ID
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.deliver_to_id          := gr_interface_info_rec(in_index).deliver_to_id;
    END IF;
    -- 出荷先
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.deliver_to             := gr_interface_info_rec(in_index).party_site_code;
    END IF;
    -- 運送業者_ID
    gr_order_h_rec.career_id                := gr_interface_info_rec(in_index).career_id;
    -- 運送業者
    gr_order_h_rec.freight_carrier_code     := gr_interface_info_rec(in_index).freight_carrier_code;
    -- 顧客発注
    gr_order_h_rec.cust_po_number           := gr_interface_info_rec(in_index).cust_po_number;
    -- 依頼No
    gr_order_h_rec.request_no               := gr_interface_info_rec(in_index).order_source_ref;
    -- ステータス
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.req_status             := gv_req_status_04;
    END IF;
    -- 配送No
    gr_order_h_rec.delivery_no              := gr_interface_info_rec(in_index).delivery_no;
    -- 前回配送no
    gr_order_h_rec.prev_delivery_no         := gv_prev_deliv_no_zero;
    -- 出荷予定日
    gr_order_h_rec.schedule_ship_date       := gr_interface_info_rec(in_index).shipped_date;
    -- 着荷予定日
    gr_order_h_rec.schedule_arrival_date    := gr_interface_info_rec(in_index).arrival_date;
    -- パレット回収枚数
    gr_order_h_rec.collected_pallet_qty     := gr_interface_info_rec(in_index).collected_pallet_qty;
    -- 運賃区分
    IF (NVL(gr_interface_info_rec(in_index).delivery_no,'0') <> '0') THEN
      gr_order_h_rec.freight_charge_class   := gv_include_exclude_1;
    ELSE
      gr_order_h_rec.freight_charge_class   := gv_include_exclude_0;
    END IF;
    -- 出荷元ID
    gr_order_h_rec.deliver_from_id          := gr_interface_info_rec(in_index).deliver_from_id;
    -- 出荷元保管場所
    gr_order_h_rec.deliver_from             := gr_interface_info_rec(in_index).location_code;
    -- 管轄拠点
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.head_sales_branch      := gr_interface_info_rec(in_index).base_code;
    END IF;
    -- 商品区分
    gr_order_h_rec.prod_class               := gr_interface_info_rec(in_index).prod_kbn_cd;
--
    lv_arrival_from := SUBSTRB(gr_interface_info_rec(in_index).arrival_time_from, 1, 2)
                    || lv_time_def
                    || SUBSTRB(gr_interface_info_rec(in_index).arrival_time_from, 3, 2);
--
    lv_arrival_to := SUBSTRB(gr_interface_info_rec(in_index).arrival_time_to, 1, 2)
                  || lv_time_def
                  || SUBSTRB(gr_interface_info_rec(in_index).arrival_time_to, 3, 2);
--
    BEGIN
--
      SELECT  xlvv1.lookup_code arrival_time_from
             ,xlvv2.lookup_code arrival_time_to
      INTO    lv_arrival_time_from
             ,lv_arrival_time_to
      FROM    xxcmn_lookup_values_v  xlvv1
             ,xxcmn_lookup_values_v  xlvv2
      WHERE   xlvv1.lookup_type = gv_arrival_time_type
      AND     xlvv2.lookup_type = gv_arrival_time_type
      AND     xlvv1.meaning = lv_arrival_from
      AND     xlvv2.meaning = lv_arrival_to
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_arrival_time_from := '0000';
        lv_arrival_time_to := '0000';
    END;
--
    -- 着荷時間from
    gr_order_h_rec.arrival_time_from       := lv_arrival_time_from;
    -- 着荷時間to
    gr_order_h_rec.arrival_time_to         := lv_arrival_time_to;
--
    --チェック有無をIF_H.運賃区分で判定
    IF (gr_interface_info_rec(in_index).freight_charge_class = gv_include_exclude_1) THEN
--
      -- 基本重量
      -- パラメータ情報取得
      -- 1.コード区分１
      lv_code_class1                := gv_code_class_04;
      -- 2.入出庫場所コード１
      lv_entering_despatching_code1 := gr_interface_info_rec(in_index).location_code;
      -- 3.コード区分２
      -- 2008/08/06 Start --------------------------------------------------------
      --lv_code_class2                := gv_code_class_09;
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200) THEN
        lv_code_class2                := gv_code_class_11;  -- 支給の場合(200)
      ELSE
        lv_code_class2                := gv_code_class_09;  -- 出荷の場合(210,215)
      END IF;
      -- 2008/08/06 End ----------------------------------------------------------
      -- 4.入出庫場所コード２
      lv_entering_despatching_code2 := gr_interface_info_rec(in_index).party_site_code;
      -- 5.基準日(適用日基準日)
      ld_standard_date := gr_interface_info_rec(in_index).shipped_date;
      -- 6.配送区分
      lv_ship_methods               := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- 配送区分がNULLの場合、最大配送区分を取得して最大パレット枚数を取得する。
      IF (lv_ship_methods IS NULL) THEN
--
        -- 最大配送区分算出関数
        ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                   lv_code_class1                                        -- IN:コード区分1
                                  ,lv_entering_despatching_code1                         -- IN:入出庫場所コード1
                                  ,lv_code_class2                                        -- IN:コード区分2
                                  ,lv_entering_despatching_code2                         -- IN:入出庫場所コード2
                                  ,gr_interface_info_rec(in_index).prod_kbn_cd           -- IN:商品区分
                                  ,gr_interface_info_rec(in_index).weight_capacity_class -- IN:重量容積区分
                                  ,NULL                                                  -- IN:自動配車対象区分
                                  ,ld_standard_date                                      -- IN:基準日
                                  ,lv_ship_methods                -- OUT:最大配送区分
                                  ,on_drink_deadweight            -- OUT:ドリンク積載重量
                                  ,on_leaf_deadweight             -- OUT:リーフ積載重量
                                  ,on_drink_loading_capacity      -- OUT:ドリンク積載容積
                                  ,on_leaf_loading_capacity       -- OUT:リーフ積載容積
                                  ,on_palette_max_qty);           -- OUT:パレット最大枚数
--
        IF (ln_ret_code = gn_warn) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                       -- 'XXWSH'
                        ,gv_msg_93a_152                   -- 最大配送区分算出関数エラー
                        ,gv_param1_token
                        ,gr_interface_info_rec(in_index).delivery_no           --配送No
                        ,gv_param2_token
                        ,gr_interface_info_rec(in_index).order_source_ref      --受注ソース参照
                        ,gv_table_token                                        -- トークン：TABLE_NAME
                        ,gv_table_token01_nm                                   -- テーブル名：受注ヘッダ(アドオン)
                        ,gv_param3_token
                        ,lv_code_class1                                        -- パラメータ：コード区分１
                        ,gv_param4_token
                        ,lv_entering_despatching_code1                         -- パラメータ：入出庫場所コード１
                        ,gv_param5_token
                        ,lv_code_class2                                        -- パラメータ：コード区分２
                        ,gv_param6_token
                        ,lv_entering_despatching_code2                         -- パラメータ：入出庫場所コード２
                        ,gv_param7_token
                        ,gr_interface_info_rec(in_index).prod_kbn_cd           -- パラメータ：商品区分
                        ,gv_param8_token
                        ,gr_interface_info_rec(in_index).weight_capacity_class -- パラメータ：重量容積区分
                        ,gv_param9_token
                        ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                -- パラメータ：基準日
                        )
                        ,1
                        ,5000);
--
          RAISE global_api_expt;   -- 最大配送区分算出関数エラーの場合はABENDさせてすべてROLLBACKする
--
        END IF;
--
        gr_interface_info_rec(in_index).shipping_method_code := lv_ship_methods;
--
      END IF;
--
      -- 最大パレット枚数取得
      ln_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                                lv_code_class1,                 -- 1.コード区分１
                                lv_entering_despatching_code1,  -- 2.入出庫場所コード１
                                lv_code_class2,                 -- 3.コード区分２
                                lv_entering_despatching_code2,  -- 4.入出庫場所コード２
                                ld_standard_date,               -- 5.基準日(適用日基準日)
                                lv_ship_methods,                -- 6.配送区分
                                on_drink_deadweight,            -- 7.ドリンク積載重量
                                on_leaf_deadweight,             -- 8.リーフ積載重量
                                on_drink_loading_capacity,      -- 9.ドリンク積載容積
                                on_leaf_loading_capacity,       -- 10.リーフ積載容積
                                on_palette_max_qty);            -- 11.パレット最大枚数
--
      IF (ln_ret_code = gn_warn) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                       -- 'XXWSH'
                      ,gv_msg_93a_025                   -- 最大パレット枚数算出関数エラー
                      ,gv_param7_token
                      ,gr_interface_info_rec(in_index).delivery_no      --配送No
                      ,gv_param8_token
                      ,gr_interface_info_rec(in_index).order_source_ref --受注ソース参照
                      ,gv_table_token                   -- トークン：TABLE_NAME
                      ,gv_table_token01_nm              -- テーブル名：受注ヘッダ(アドオン)
                      ,gv_param1_token
                      ,lv_code_class1                   -- パラメータ：コード区分１
                      ,gv_param2_token
                      ,lv_entering_despatching_code1    -- パラメータ：入出庫場所コード１
                      ,gv_param3_token
                      ,lv_code_class2                   -- パラメータ：コード区分２
                      ,gv_param4_token
                      ,lv_entering_despatching_code2    -- パラメータ：入出庫場所コード２
                      ,gv_param5_token
                      ,TO_CHAR(ld_standard_date,'YYYY/MM/DD') -- パラメータ：基準日
                      ,gv_param6_token
                      ,lv_ship_methods                  -- パラメータ：配送区分
                      )
                      ,1
                      ,5000);
--
        RAISE global_api_expt;   -- 最大パレット枚数算出関数エラーの場合はABENDさせてすべてROLLBACKする
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        -- ドリンク積載
        gr_order_h_rec.based_weight              := on_drink_deadweight;
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        -- リーフ積載
        gr_order_h_rec.based_weight              := on_leaf_deadweight;
      END IF;
--
      -- 基本容積
      IF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        -- ドリンク容積
        gr_order_h_rec.based_capacity            := on_drink_loading_capacity;
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        -- リーフ容積
        gr_order_h_rec.based_capacity            := on_leaf_loading_capacity;
--
      END IF;
--
      -- 配送区分
      gr_order_h_rec.shipping_method_code     := gr_interface_info_rec(in_index).shipping_method_code;
      -- 配送区分_実績
      gr_order_h_rec.result_shipping_method_code := gr_interface_info_rec(in_index).shipping_method_code;
--
    END IF;
--
    -- パレット実績枚数
    gr_order_h_rec.real_pallet_quantity        := gr_interface_info_rec(in_index).used_pallet_qty;
    -- 運送業者_ID_実績
    gr_order_h_rec.result_freight_carrier_id   := gr_interface_info_rec(in_index).result_freight_carrier_id;
    -- 運送業者_実績
    gr_order_h_rec.result_freight_carrier_code := gr_interface_info_rec(in_index).freight_carrier_code;
    -- 出荷先_実績ID
    gr_order_h_rec.result_deliver_to_id        := gr_interface_info_rec(in_index).result_deliver_to_id;
    -- 出荷先_実績
    gr_order_h_rec.result_deliver_to           := gr_interface_info_rec(in_index).party_site_code;
    -- 出荷日
    gr_order_h_rec.shipped_date                := gr_interface_info_rec(in_index).shipped_date;
    -- 着荷日
    gr_order_h_rec.arrival_date                := gr_interface_info_rec(in_index).arrival_date;
    -- 重量容積区分
    gr_order_h_rec.weight_capacity_class       := gr_interface_info_rec(in_index).weight_capacity_class;
    -- 通知ステータス
    gr_order_h_rec.notif_status                := gv_notif_status_40;
    -- 前回通知ステータス
    gr_order_h_rec.prev_notif_status           := gv_notif_status_10;
    -- 確定通知実施日時
    gr_order_h_rec.notif_date                  := gd_sysdate;
--
    -- 成績管理部署
    -- (210)拠点出荷確定報告・(215)庭先出荷確定報告の場合のみセット
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) OR
       (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215) THEN
--
      BEGIN
        SELECT xlv2.location_code
        INTO   lt_location_code
        FROM  fnd_user fu
             ,per_all_assignments_f paaf
             ,xxcmn_locations2_v xlv2
        WHERE fu.user_id        = gt_user_id
        AND   paaf.person_id    = fu.employee_id
        AND   paaf.primary_flag = gv_yesno_y
        AND   gr_interface_info_rec(in_index).shipped_date
          BETWEEN paaf.effective_start_date AND paaf.effective_end_date
        AND   paaf.location_id  = xlv2.location_id
        AND   gr_interface_info_rec(in_index).shipped_date
          BETWEEN xlv2.start_date_active AND xlv2.end_date_active;
--
        gr_order_h_rec.performance_management_dept := lt_location_code;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            gr_order_h_rec.performance_management_dept := NULL;
      END;
--
    END IF;
--
    -- 指示部署
    gr_order_h_rec.instruction_dept := gr_interface_info_rec(in_index).report_post_code;
--
    -- 有償出荷報告の場合にのみセット
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200) THEN
      -- 取引先ID
      gr_order_h_rec.vendor_id        := gr_interface_info_rec(in_index).vendor_id;
      -- 取引先
      gr_order_h_rec.vendor_code      := gr_interface_info_rec(in_index).vendor_site_code;
      -- 取引先サイトID
      gr_order_h_rec.vendor_site_id   := gr_interface_info_rec(in_index).vendor_site_id;
      -- 取引先サイト
      gr_order_h_rec.vendor_site_code := gr_interface_info_rec(in_index).party_site_code;
--
   ELSE
      gr_order_h_rec.vendor_id        := NULL;      -- 取引先ID
      gr_order_h_rec.vendor_code      := NULL;      -- 取引先
      gr_order_h_rec.vendor_site_id   := NULL;      -- 取引先サイトID
      gr_order_h_rec.vendor_site_code := NULL;      -- 取引先サイト
   END iF;
--
    -- 画面更新日時
    gr_order_h_rec.screen_update_date          := gd_sysdate;
    -- 画面更新者
    gr_order_h_rec.screen_update_by            := gt_user_id;
--
    -- 登録処理実施
    INSERT INTO xxwsh_order_headers_all
      ( order_header_id                             -- 受注ヘッダアドオンID
       ,order_type_id                               -- 受注タイプID
       ,organization_id                             -- 組織ID
       ,latest_external_flag                        -- 最新フラグ
       ,ordered_date                                -- 受注日
       ,customer_id                                 -- 顧客ID
       ,customer_code                               -- 顧客
       ,deliver_to_id                               -- 出荷先ID
       ,deliver_to                                  -- 出荷先
       ,career_id                                   -- 運送業者ID
       ,freight_carrier_code                        -- 運送業者
       ,shipping_method_code                        -- 配送区分
       ,cust_po_number                              -- 顧客発注
       ,request_no                                  -- 依頼No
       ,req_status                                  -- ステータス
       ,delivery_no                                 -- 配送no
       ,prev_delivery_no                            -- 前回配送no
       ,schedule_ship_date                          -- 出荷予定日
       ,schedule_arrival_date                       -- 着荷予定日
       ,collected_pallet_qty                        -- パレット回収枚数
       ,confirm_request_class                       -- 物流担当確認依頼区分
       ,freight_charge_class                        -- 運賃区分
       ,deliver_from_id                             -- 出荷元ID
       ,deliver_from                                -- 出荷元保管場所
       ,head_sales_branch                           -- 管轄拠点
       ,prod_class                                  -- 商品区分
       ,no_cont_freight_class                       -- 契約外運賃区分
       ,arrival_time_from                           -- 着荷時間from
       ,arrival_time_to                             -- 着荷時間to
       ,based_weight                                -- 基本重量
       ,based_capacity                              -- 基本容積
       ,real_pallet_quantity                        -- パレット実績枚数
       ,result_freight_carrier_id                   -- 運送業者_実績ID
       ,result_freight_carrier_code                 -- 運送業者_実績
       ,result_shipping_method_code                 -- 配送区分_実績
       ,result_deliver_to_id                        -- 出荷先_実績ID
       ,result_deliver_to                           -- 出荷先_実績
       ,shipped_date                                -- 出荷日
       ,arrival_date                                -- 着荷日
       ,weight_capacity_class                       -- 重量容積区分
       ,notif_status                                -- 通知ステータス
       ,prev_notif_status                           -- 前回通知ステータス
       ,notif_date                                  -- 確定通知実施日時
       ,new_modify_flg                              -- 新規修正フラグ
       ,performance_management_dept                 -- 成績管理部署
       ,instruction_dept                            -- 指示部署
       ,vendor_id                                   -- 取引先ID
       ,vendor_code                                 -- 取引先
       ,vendor_site_id                              -- 取引先サイトID
       ,vendor_site_code                            -- 取引先サイト
       ,screen_update_date                          -- 画面更新日時
       ,screen_update_by                            -- 画面更新者
       ,corrected_tighten_class                     -- 締め後修正区分
       ,created_by                                  -- 作成者
       ,creation_date                               -- 作成日
       ,last_updated_by                             -- 最終更新者
       ,last_update_date                            -- 最終更新日
       ,last_update_login                           -- 最終更新ログイン
       ,request_id                                  -- 要求id
       ,program_application_id                      -- アプリケーションid
       ,program_id                                  -- コンカレント・プログラムid
       ,program_update_date                         -- プログラム更新日
      )
      VALUES
      ( gr_order_h_rec.order_header_id              -- 受注ヘッダアドオンID
       ,gr_order_h_rec.order_type_id                -- 受注タイプID
       ,gr_order_h_rec.organization_id              -- 組織ID
       ,gr_order_h_rec.latest_external_flag         -- 最新フラグ
       ,gr_order_h_rec.ordered_date                 -- 受注日
       ,gr_order_h_rec.customer_id                  -- 顧客ID
       ,gr_order_h_rec.customer_code                -- 顧客
       ,gr_order_h_rec.deliver_to_id                -- 出荷先ID
       ,gr_order_h_rec.deliver_to                   -- 出荷先
       ,gr_order_h_rec.career_id                    -- 運送業者ID
       ,gr_order_h_rec.freight_carrier_code         -- 運送業者
       ,gr_order_h_rec.shipping_method_code         -- 配送区分
       ,gr_order_h_rec.cust_po_number               -- 顧客発注
       ,gr_order_h_rec.request_no                   -- 依頼No
       ,gr_order_h_rec.req_status                   -- ステータス
       ,gr_order_h_rec.delivery_no                  -- 配送no
       ,gr_order_h_rec.prev_delivery_no             -- 前回配送no
       ,gr_order_h_rec.schedule_ship_date           -- 出荷予定日
       ,gr_order_h_rec.schedule_arrival_date        -- 着荷予定日
       ,gr_order_h_rec.collected_pallet_qty         -- パレット回収枚数
       ,gv_include_exclude_0                        -- 物流担当確認依頼区分
       ,gr_order_h_rec.freight_charge_class         -- 運賃区分
       ,gr_order_h_rec.deliver_from_id              -- 出荷元ID
       ,gr_order_h_rec.deliver_from                 -- 出荷元保管場所
       ,gr_order_h_rec.head_sales_branch            -- 管轄拠点
       ,gr_order_h_rec.prod_class                   -- 商品区分
       ,gv_include_exclude_0                        -- 物流担当確認依頼区分
       ,gr_order_h_rec.arrival_time_from            -- 着荷時間from
       ,gr_order_h_rec.arrival_time_to              -- 着荷時間to
       ,gr_order_h_rec.based_weight                 -- 基本重量
       ,gr_order_h_rec.based_capacity               -- 基本容積
       ,gr_order_h_rec.real_pallet_quantity         -- パレット実績枚数
       ,gr_order_h_rec.result_freight_carrier_id    -- 運送業者_実績ID
       ,gr_order_h_rec.result_freight_carrier_code  -- 運送業者_実績
       ,gr_order_h_rec.result_shipping_method_code  -- 配送区分_実績
       ,gr_order_h_rec.result_deliver_to_id         -- 出荷先_実績ID
       ,gr_order_h_rec.result_deliver_to            -- 出荷先_実績
       ,gr_order_h_rec.shipped_date                 -- 出荷日
       ,gr_order_h_rec.arrival_date                 -- 着荷日
       ,gr_order_h_rec.weight_capacity_class        -- 重量容積区分
       ,gr_order_h_rec.notif_status                 -- 通知ステータス
       ,gr_order_h_rec.prev_notif_status            -- 前回通知ステータス
       ,gr_order_h_rec.notif_date                   -- 確定通知実施日時
       ,gv_yesno_n                                  -- 新規修正フラグ
       ,gr_order_h_rec.performance_management_dept  -- 成績管理部署
       ,gr_order_h_rec.instruction_dept             -- 指示部署
       ,gr_order_h_rec.vendor_id                    -- 取引先ID
       ,gr_order_h_rec.vendor_code                  -- 取引先
       ,gr_order_h_rec.vendor_site_id               -- 取引先サイトID
       ,gr_order_h_rec.vendor_site_code             -- 取引先サイト
       ,gr_order_h_rec.screen_update_date           -- 画面更新日時
       ,gr_order_h_rec.screen_update_by             -- 画面更新者
       ,gv_yesno_n                                  -- 締め後修正区分
       ,gt_user_id                                  -- 作成者
       ,gt_sysdate                                  -- 作成日
       ,gt_user_id                                  -- 最終更新者
       ,gt_sysdate                                  -- 最終更新日
       ,gt_login_id                                 -- 最終更新ログイン
       ,gt_conc_request_id                          -- 要求ID
       ,gt_prog_appl_id                             -- アプリケーションID
       ,gt_conc_program_id                          -- コンカレント・プログラムID
       ,gt_sysdate                                  -- プログラム更新日
      );
--
--********** 2008/07/07 ********** DELETE START ***
--*     --受注ヘッダ登録作成件数(外部倉庫発番)
--*     gn_ord_h_ins_cnt := gn_ord_h_ins_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END order_headers_ins;
--
 /**********************************************************************************
  * Procedure Name   : order_headers_upd
  * Description      : 受注ヘッダアドオン(実績計上編集) プロシージャ(A-8-1)
  ***********************************************************************************/
  PROCEDURE order_headers_upd(
    in_index                IN  NUMBER,                 -- データindex
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_headers_upd'; -- プログラム名
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
    --受注ヘッダID
    lt_order_header_id            xxwsh_order_headers_all.order_header_id%TYPE;
    --依頼No
    lt_request_no                 xxwsh_order_headers_all.request_no%TYPE;
    --配送no
    lt_delivery_no                xxwsh_order_headers_all.delivery_no%TYPE;
    --成績管理部署
    lt_location_code              xxwsh_order_headers_all.performance_management_dept%TYPE;
--
    -- 最大パレット枚数算出関数パラメータ
    lv_code_class1                VARCHAR2(2);                -- 1.コード区分１
    lv_entering_despatching_code1 VARCHAR2(4);                -- 2.入出庫場所コード１
    lv_code_class2                VARCHAR2(2);                -- 3.コード区分２
    lv_entering_despatching_code2 VARCHAR2(9);                -- 4.入出庫場所コード２
    ld_standard_date              DATE;                       -- 5.基準日(適用日基準日)
    lv_ship_methods               VARCHAR2(2);                -- 6.配送区分
    on_drink_deadweight           NUMBER;                     -- 7.ドリンク積載重量
    on_leaf_deadweight            NUMBER;                     -- 8.リーフ積載重量
    on_drink_loading_capacity     NUMBER;                     -- 9.ドリンク積載容積
    on_leaf_loading_capacity      NUMBER;                     -- 10.リーフ積載容積
    on_palette_max_qty            NUMBER;                     -- 11.パレット最大枚数
--
    ln_ret_code                   NUMBER;                     -- リターン・コード
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
--  初期化
    gr_order_h_rec := gr_order_h_ini;
--
    -- 受注ヘッダアドオン編集処理
    -- 依頼No
    gr_order_h_rec.request_no           := gr_interface_info_rec(in_index).order_source_ref;
    -- 配送no
    gr_order_h_rec.delivery_no          := gr_interface_info_rec(in_index).delivery_no;
    -- ステータス
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.req_status         := gv_req_status_04;
    END IF;
    -- パレット回収枚数
    gr_order_h_rec.collected_pallet_qty := gr_interface_info_rec(in_index).collected_pallet_qty;
--
    --チェック有無をIF_H.運賃区分で判定
    IF (gr_interface_info_rec(in_index).freight_charge_class = gv_include_exclude_1) THEN
--
      -- 基本重量
      -- パラメータ情報取得
      -- 1.コード区分１
      lv_code_class1                := gv_code_class_04;
      -- 2.入出庫場所コード１
      lv_entering_despatching_code1 := gr_interface_info_rec(in_index).location_code;
--
      -- 3.コード区分２
      -- 2008/08/06 Start --------------------------------------------------------
      --lv_code_class2                := gv_code_class_09;
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200) THEN
        lv_code_class2                := gv_code_class_11;  -- 支給の場合(200)
      ELSE
        lv_code_class2                := gv_code_class_09;  -- 出荷の場合(210,215)
      END IF;
      -- 2008/08/06 End ----------------------------------------------------------
      -- 4.入出庫場所コード２
      lv_entering_despatching_code2 := gr_interface_info_rec(in_index).party_site_code;
      -- 5.基準日(適用日基準日)
      ld_standard_date := gr_interface_info_rec(in_index).shipped_date;
      -- 6.配送区分
      lv_ship_methods               := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- 配送区分がNULLの場合、最大配送区分を取得して最大パレット枚数を取得する。
      IF (lv_ship_methods IS NULL) THEN
--
        -- 最大配送区分算出関数
        ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                   lv_code_class1                                        -- IN:コード区分1
                                  ,lv_entering_despatching_code1                         -- IN:入出庫場所コード1
                                  ,lv_code_class2                                        -- IN:コード区分2
                                  ,lv_entering_despatching_code2                         -- IN:入出庫場所コード2
                                  ,gr_interface_info_rec(in_index).prod_kbn_cd           -- IN:商品区分
                                  ,gr_interface_info_rec(in_index).weight_capacity_class -- IN:重量容積区分
                                  ,NULL                                                  -- IN:自動配車対象区分
                                  ,ld_standard_date                                      -- IN:基準日
                                  ,lv_ship_methods                -- OUT:最大配送区分
                                  ,on_drink_deadweight            -- OUT:ドリンク積載重量
                                  ,on_leaf_deadweight             -- OUT:リーフ積載重量
                                  ,on_drink_loading_capacity      -- OUT:ドリンク積載容積
                                  ,on_leaf_loading_capacity       -- OUT:リーフ積載容積
                                  ,on_palette_max_qty);           -- OUT:パレット最大枚数
--
        IF (ln_ret_code = gn_warn) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                       -- 'XXWSH'
                        ,gv_msg_93a_152                   -- 最大配送区分算出関数エラー
                        ,gv_param1_token
                        ,gr_interface_info_rec(in_index).delivery_no           --配送No
                        ,gv_param2_token
                        ,gr_interface_info_rec(in_index).order_source_ref      --受注ソース参照
                        ,gv_table_token                                        -- トークン：TABLE_NAME
                        ,gv_table_token01_nm                                   -- テーブル名：受注ヘッダ(アドオン)
                        ,gv_param3_token
                        ,lv_code_class1                                        -- パラメータ：コード区分１
                        ,gv_param4_token
                        ,lv_entering_despatching_code1                         -- パラメータ：入出庫場所コード１
                        ,gv_param5_token
                        ,lv_code_class2                                        -- パラメータ：コード区分２
                        ,gv_param6_token
                        ,lv_entering_despatching_code2                         -- パラメータ：入出庫場所コード２
                        ,gv_param7_token
                        ,gr_interface_info_rec(in_index).prod_kbn_cd           -- パラメータ：商品区分
                        ,gv_param8_token
                        ,gr_interface_info_rec(in_index).weight_capacity_class -- パラメータ：重量容積区分
                        ,gv_param9_token
                        ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                -- パラメータ：基準日
                        )
                        ,1
                        ,5000);
--
          RAISE global_api_expt;   -- 最大配送区分算出関数エラーの場合はABENDさせてすべてROLLBACKする
--
        END IF;
--
        gr_interface_info_rec(in_index).shipping_method_code := lv_ship_methods;
--
      END IF;
--
      -- 最大パレット枚数取得
      ln_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                                lv_code_class1,                 -- 1.コード区分１
                                lv_entering_despatching_code1,  -- 2.入出庫場所コード１
                                lv_code_class2,                 -- 3.コード区分２
                                lv_entering_despatching_code2,  -- 4.入出庫場所コード２
                                ld_standard_date,               -- 5.基準日(適用日基準日)
                                lv_ship_methods,                -- 6.配送区分
                                on_drink_deadweight,            -- 7.ドリンク積載重量
                                on_leaf_deadweight,             -- 8.リーフ積載重量
                                on_drink_loading_capacity,      -- 9.ドリンク積載容積
                                on_leaf_loading_capacity,       -- 10.リーフ積載容積
                                on_palette_max_qty);            -- 11.パレット最大枚数
--
      IF (ln_ret_code = gn_warn) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                       -- 'XXWSH'
                      ,gv_msg_93a_025                   -- 最大パレット枚数算出関数エラー
                      ,gv_param7_token
                      ,gr_interface_info_rec(in_index).delivery_no      --配送No
                      ,gv_param8_token
                      ,gr_interface_info_rec(in_index).order_source_ref --受注ソース参照
                      ,gv_table_token                   -- トークン：TABLE_NAME
                      ,gv_table_token01_nm              -- テーブル名：受注ヘッダ(アドオン)
                      ,gv_param1_token
                      ,lv_code_class1                   -- パラメータ：コード区分１
                      ,gv_param2_token
                      ,lv_entering_despatching_code1    -- パラメータ：入出庫場所コード１
                      ,gv_param3_token
                      ,lv_code_class2                   -- パラメータ：コード区分２
                      ,gv_param4_token
                      ,lv_entering_despatching_code2    -- パラメータ：入出庫場所コード２
                      ,gv_param5_token
                      ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                 -- パラメータ：基準日
                      ,gv_param6_token
                      ,lv_ship_methods                  -- パラメータ：配送区分
                      )
                      ,1
                      ,5000);
--
        RAISE global_api_expt;    -- 最大パレット枚数算出関数エラーの場合はABENDさせてすべてROLLBACKする
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_order_h_rec.based_weight       := on_drink_deadweight;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_order_h_rec.based_weight       := on_leaf_deadweight;
      END IF;
--
      -- 基本容積
      IF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_order_h_rec.based_capacity     := on_drink_loading_capacity;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_order_h_rec.based_capacity     := on_leaf_loading_capacity;
      END IF;
--
      -- 配送区分_実績
      gr_order_h_rec.result_shipping_method_code := gr_interface_info_rec(in_index).shipping_method_code;
--
    END IF;
--
    -- パレット実績枚数
    gr_order_h_rec.real_pallet_quantity := gr_interface_info_rec(in_index).used_pallet_qty;
    -- 運送業者_ID_実績
    gr_order_h_rec.result_freight_carrier_id   := gr_interface_info_rec(in_index).result_freight_carrier_id;
    -- 運送業者_実績
    gr_order_h_rec.result_freight_carrier_code := gr_interface_info_rec(in_index).freight_carrier_code;
    -- 出荷先_実績ID
    gr_order_h_rec.result_deliver_to_id := gr_interface_info_rec(in_index).result_deliver_to_id;
    -- 出荷先_実績
    gr_order_h_rec.result_deliver_to    := gr_interface_info_rec(in_index).party_site_code;
    -- 出荷日
    gr_order_h_rec.shipped_date         := gr_interface_info_rec(in_index).shipped_date;
    -- 着荷日
    gr_order_h_rec.arrival_date         := gr_interface_info_rec(in_index).arrival_date;
--
    -- 成績管理部署
    -- (210)拠点出荷確定報告・(215)庭先出荷確定報告の場合のみセット
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) OR
       (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215) THEN
--
      BEGIN
        SELECT xlv2.location_code
        INTO   lt_location_code
        FROM  fnd_user fu
             ,per_all_assignments_f paaf
             ,xxcmn_locations2_v xlv2
        WHERE fu.user_id        = gt_user_id
        AND   paaf.person_id    = fu.employee_id
        AND   paaf.primary_flag = gv_yesno_y
        AND   gr_interface_info_rec(in_index).shipped_date
          BETWEEN paaf.effective_start_date AND paaf.effective_end_date
        AND   paaf.location_id  = xlv2.location_id
        AND   gr_interface_info_rec(in_index).shipped_date
          BETWEEN xlv2.start_date_active AND xlv2.end_date_active;
--
        gr_order_h_rec.performance_management_dept := lt_location_code;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gr_order_h_rec.performance_management_dept := NULL;
      END;
--
    ELSE
      gr_order_h_rec.performance_management_dept := NULL;
    END IF;
--
     -- (210)拠点出荷確定報告・(215)庭先出荷確定報告以外の場合
     -- (210)拠点出荷確定報告・(215)庭先出荷確定報告の場合で、成績管理部署がない場合
    IF (gr_order_h_rec.performance_management_dept IS NULL) THEN
      UPDATE xxwsh.xxwsh_order_headers_all xoha
      SET xoha.req_status                   = gr_order_h_rec.req_status
         ,xoha.collected_pallet_qty         = gr_order_h_rec.collected_pallet_qty
         ,xoha.based_weight                 = gr_order_h_rec.based_weight
         ,xoha.based_capacity               = gr_order_h_rec.based_capacity
         ,xoha.real_pallet_quantity         = gr_order_h_rec.real_pallet_quantity
         ,xoha.result_freight_carrier_id    = gr_order_h_rec.result_freight_carrier_id
         ,xoha.result_freight_carrier_code  = gr_order_h_rec.result_freight_carrier_code
         ,xoha.result_shipping_method_code  = gr_order_h_rec.result_shipping_method_code
         ,xoha.result_deliver_to_id         = gr_order_h_rec.result_deliver_to_id
         ,xoha.result_deliver_to            = gr_order_h_rec.result_deliver_to
         ,xoha.shipped_date                 = gr_order_h_rec.shipped_date
         ,xoha.arrival_date                 = gr_order_h_rec.arrival_date
         ----,xoha.performance_management_dept  = gr_order_h_rec.performance_management_dept --成績管理部署
         ,xoha.last_updated_by              = gt_user_id
         ,xoha.last_update_date             = gt_sysdate
         ,xoha.last_update_login            = gt_login_id
         ,xoha.request_id                   = gt_conc_request_id
         ,xoha.program_application_id       = gt_prog_appl_id
         ,xoha.program_id                   = gt_conc_program_id
         ,xoha.program_update_date          = gt_sysdate
      WHERE xoha.request_no           = gr_order_h_rec.request_no
      AND   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_order_h_rec.delivery_no,gv_delivery_no_null)
      AND   xoha.latest_external_flag = gv_yesno_y;
--
     -- (210)拠点出荷確定報告・(215)庭先出荷確定報告の場合で、成績管理部署がある場合
    ELSE
      UPDATE xxwsh.xxwsh_order_headers_all xoha
      SET xoha.req_status                   = gr_order_h_rec.req_status
         ,xoha.collected_pallet_qty         = gr_order_h_rec.collected_pallet_qty
         ,xoha.based_weight                 = gr_order_h_rec.based_weight
         ,xoha.based_capacity               = gr_order_h_rec.based_capacity
         ,xoha.real_pallet_quantity         = gr_order_h_rec.real_pallet_quantity
         ,xoha.result_freight_carrier_id    = gr_order_h_rec.result_freight_carrier_id
         ,xoha.result_freight_carrier_code  = gr_order_h_rec.result_freight_carrier_code
         ,xoha.result_shipping_method_code  = gr_order_h_rec.result_shipping_method_code
         ,xoha.result_deliver_to_id         = gr_order_h_rec.result_deliver_to_id
         ,xoha.result_deliver_to            = gr_order_h_rec.result_deliver_to
         ,xoha.shipped_date                 = gr_order_h_rec.shipped_date
         ,xoha.arrival_date                 = gr_order_h_rec.arrival_date
         ,xoha.performance_management_dept  = gr_order_h_rec.performance_management_dept --成績管理部署
         ,xoha.last_updated_by              = gt_user_id
         ,xoha.last_update_date             = gt_sysdate
         ,xoha.last_update_login            = gt_login_id
         ,xoha.request_id                   = gt_conc_request_id
         ,xoha.program_application_id       = gt_prog_appl_id
         ,xoha.program_id                   = gt_conc_program_id
         ,xoha.program_update_date          = gt_sysdate
      WHERE xoha.request_no           = gr_order_h_rec.request_no
      AND   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_order_h_rec.delivery_no,gv_delivery_no_null)
      AND   xoha.latest_external_flag = gv_yesno_y;
--
    END IF;
--
    -- 受注ヘッダIDの取得
    SELECT order_header_id
    INTO lt_order_header_id
    FROM xxwsh_order_headers_all xoha
    WHERE xoha.request_no           = gr_order_h_rec.request_no
    AND   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_order_h_rec.delivery_no,gv_delivery_no_null)
    AND   xoha.latest_external_flag = gv_yesno_y;
--
    gr_order_h_rec.order_header_id := lt_order_header_id;
--
--********** 2008/07/07 ********** DELETE START ***
--* -- 受注ヘッダ更新作成件数(実績計上)加算
--* gn_ord_h_upd_n_cnt := gn_ord_h_upd_n_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END order_headers_upd;
--
 /**********************************************************************************
  * Procedure Name   : order_headers_inup
  * Description      : 受注ヘッダアドオン(実績訂正元編集) プロシージャ(A-8-3,4)
  ***********************************************************************************/
  PROCEDURE order_headers_inup(
    in_index                IN  NUMBER,                 -- データindex
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_headers_inup'; -- プログラム名
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
    --最新フラグ
    lt_latest_external_flag        xxwsh_order_headers_all.latest_external_flag%TYPE;
    lt_order_header_id             xxwsh_order_headers_all.order_header_id%TYPE;
--
    lv_ret_code                    VARCHAR2(1);     -- OUT 11.リターンコード
    lv_err_msg_code                VARCHAR2(100);   -- OUT 12.エラーメッセージコード
    lv_err_msg                     VARCHAR2(5000);  -- OUT 13.エラーメッセージ
    lv_msg_buff                    VARCHAR2(5000);
--
    TYPE order_h_up_rec IS RECORD(
      request_no                   xxwsh_order_headers_all.request_no%TYPE        --依頼no
      ,delivery_no                 xxwsh_order_headers_all.delivery_no%TYPE       --配送no
      ,latest_external_flag        xxwsh_order_headers_all.latest_external_flag%TYPE  --最新フラグ
    );
    -- データを格納する結合配列
    TYPE order_h_up_tbl IS TABLE OF order_h_up_rec INDEX BY PLS_INTEGER;
--
    gr_order_h_rec_up2      order_h_up_tbl;
    gr_order_h_rec_up2_ini  order_h_up_tbl;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    lr_order_h_rec_ins      order_h_rec;
    lr_order_h_rec_ins_ini  order_h_rec;
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
--  初期化
    gr_order_h_rec     := gr_order_h_ini;
    gr_order_h_rec_up2 := gr_order_h_rec_up2_ini;
    lr_order_h_rec_ins := lr_order_h_rec_ins_ini;
--
    -- 受注ヘッダアドオン編集処理
    -- 依頼No
    gr_order_h_rec_up2(in_index).request_no           := gr_interface_info_rec(in_index).order_source_ref;
    -- 配送no
    gr_order_h_rec_up2(in_index).delivery_no          := gr_interface_info_rec(in_index).delivery_no;
    -- 最新フラグ
    gr_order_h_rec_up2(in_index).latest_external_flag := gv_yesno_n;
--
--********** 2008/07/11 ********** ADD    START ***
    BEGIN
--********** 2008/07/11 ********** ADD    END   ***
--
      SELECT xoha.order_header_id             --受注ヘッダアドオンID
            ,xoha.order_type_id               --受注タイプID
            ,xoha.organization_id             --組織ID
            ,xoha.header_id                   --受注ヘッダID
            ,xoha.latest_external_flag        --最新フラグ
            ,xoha.ordered_date                --受注日
            ,xoha.customer_id                 --顧客ID
            ,xoha.customer_code               --顧客
            ,xoha.deliver_to_id               --出荷先ID
            ,xoha.deliver_to                  --出荷先
            ,xoha.shipping_instructions       --出荷指示
            ,xoha.career_id                   --運送業者ID
            ,xoha.freight_carrier_code        --運送業者
            ,xoha.shipping_method_code        --配送区分
            ,xoha.cust_po_number              --顧客発注
            ,xoha.price_list_id               --価格表
            ,xoha.request_no                  --依頼no
            ,xoha.req_status                  --ステータス
            ,xoha.delivery_no                 --配送no
            ,xoha.prev_delivery_no            --前回配送no
            ,xoha.schedule_ship_date          --出荷予定日
            ,xoha.schedule_arrival_date       --着荷予定日
            ,xoha.mixed_no                    --混載元no
            ,xoha.collected_pallet_qty        --パレット回収枚数
            ,xoha.confirm_request_class       --物流担当確認依頼区分
            ,xoha.freight_charge_class        --運賃区分
            ,xoha.shikyu_instruction_class    --支給出庫指示区分
            ,xoha.shikyu_inst_rcv_class       --支給指示受領区分
            ,xoha.amount_fix_class            --有償金額確定区分
            ,xoha.takeback_class              --引取区分
            ,xoha.deliver_from_id             --出荷元ID
            ,xoha.deliver_from                --出荷元保管場所
            ,xoha.head_sales_branch           --管轄拠点
            ,xoha.po_no                       --発注no
            ,xoha.prod_class                  --商品区分
            ,xoha.item_class                  --品目区分
            ,xoha.no_cont_freight_class       --契約外運賃区分
            ,xoha.arrival_time_from           --着荷時間from
            ,xoha.arrival_time_to             --着荷時間to
            ,xoha.designated_item_id          --製造品目ID
            ,xoha.designated_item_code        --製造品目
            ,xoha.designated_production_date  --製造日
            ,xoha.designated_branch_no        --製造枝番
            ,xoha.slip_number                 --送り状no
            ,xoha.sum_quantity                --合計数量
            ,xoha.small_quantity              --小口個数
            ,xoha.label_quantity              --ラベル枚数
            ,xoha.loading_efficiency_weight   --重量積載効率
            ,xoha.loading_efficiency_capacity --容積積載効率
            ,xoha.based_weight                --基本重量
            ,xoha.based_capacity              --基本容積
            ,xoha.sum_weight                  --積載重量合計
            ,xoha.sum_capacity                --積載容積合計
            ,xoha.mixed_ratio                 --混載率
            ,xoha.pallet_sum_quantity         --パレット合計枚数
            ,xoha.real_pallet_quantity        --パレット実績枚数
            ,xoha.sum_pallet_weight           --合計パレット重量
            ,xoha.order_source_ref            --受注ソース参照
            ,xoha.result_freight_carrier_id   --運送業者_実績ID
            ,xoha.result_freight_carrier_code --運送業者_実績
            ,xoha.result_shipping_method_code --配送区分_実績
            ,xoha.result_deliver_to_id        --出荷先_実績ID
            ,xoha.result_deliver_to           --出荷先_実績
            ,xoha.shipped_date                --出荷日
            ,xoha.arrival_date                --着荷日
            ,xoha.weight_capacity_class       --重量容積区分
            ,xoha.actual_confirm_class        --実績計上済区分
            ,xoha.notif_status                --通知ステータス
            ,xoha.prev_notif_status           --前回通知ステータス
            ,xoha.notif_date                  --確定通知実施日時
            ,xoha.new_modify_flg              --新規修正フラグ
            ,xoha.process_status              --処理経過ステータス
            ,xoha.performance_management_dept --成績管理部署
            ,xoha.instruction_dept            --指示部署
            ,xoha.transfer_location_id        --振替先ID
            ,xoha.transfer_location_code      --振替先
            ,xoha.mixed_sign                  --混載記号
            ,xoha.screen_update_date          --画面更新日時
            ,xoha.screen_update_by            --画面更新者
            ,xoha.tightening_date             --出荷依頼締め日時
            ,xoha.vendor_id                   --取引先ID
            ,xoha.vendor_code                 --取引先
            ,xoha.vendor_site_id              --取引先サイトID
            ,xoha.vendor_site_code            --取引先サイト
            ,xoha.registered_sequence         --登録順序
            ,xoha.tightening_program_id       --締めコンカレントID
            ,xoha.corrected_tighten_class     --締め後修正区分
      INTO  lr_order_h_rec_ins
      FROM  xxwsh_order_headers_all xoha
      WHERE xoha.request_no           = gr_order_h_rec_up2(in_index).request_no
      AND   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_order_h_rec_up2(in_index).delivery_no,gv_delivery_no_null)
      AND   xoha.latest_external_flag = gv_yesno_y
      -- 出荷：出荷実績計上済　支給：支給実績計上済
      AND    xoha.req_status IN(gv_req_status_04,gv_req_status_08);
--    WHERE xoha.request_no           = gr_order_h_rec.request_no
--    AND   xoha.delivery_no          = gr_order_h_rec.delivery_no
--    AND   xoha.latest_external_flag = gv_yesno_y;
--
    EXCEPTION
--
      WHEN NO_DATA_FOUND THEN
      --処理可能な指示データが存在しない場合、エラー
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                                 -- 'XXWSH'
                      ,gv_msg_93a_154                             -- 実績計上／訂正不可エラーメッセージ
                      ,gv_param1_token
                      ,gr_interface_info_rec(in_index).delivery_no       -- IF_H.配送No
                      ,gv_param2_token
                      ,gr_interface_info_rec(in_index).order_source_ref  -- IF_H.受注ソース参照(依頼/移動No)
                                                         )
                                                         ,1
                                                         ,5000);
--
        RAISE no_record_expt;   -- A-8処理内の為、ABENDさせてすべてROLLBACKする
--
    END ;
--
    UPDATE xxwsh_order_headers_all xoha
    SET xoha.latest_external_flag   = gr_order_h_rec_up2(in_index).latest_external_flag
       ,xoha.last_updated_by        = gt_user_id
       ,xoha.last_update_date       = gt_sysdate
       ,xoha.last_update_login      = gt_login_id
       ,xoha.request_id             = gt_conc_request_id
       ,xoha.program_application_id = gt_prog_appl_id
       ,xoha.program_id             = gt_conc_program_id
       ,xoha.program_update_date    = gt_sysdate
    WHERE xoha.request_no           = gr_order_h_rec_up2(in_index).request_no
    AND   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_order_h_rec_up2(in_index).delivery_no,gv_delivery_no_null)
    AND   xoha.latest_external_flag = gv_yesno_y;
--
    -- 受注ヘッダID取得(シーケンス)
    SELECT xxwsh_order_headers_all_s1.NEXTVAL
    INTO lt_order_header_id
    FROM dual;
--
    gr_order_h_rec.order_header_id             := lt_order_header_id;
    gr_order_h_rec.order_type_id               := lr_order_h_rec_ins.order_type_id;
    gr_order_h_rec.organization_id             := lr_order_h_rec_ins.organization_id;
    gr_order_h_rec.latest_external_flag        := gv_yesno_y;
    gr_order_h_rec.ordered_date                := lr_order_h_rec_ins.ordered_date;
    gr_order_h_rec.customer_id                 := lr_order_h_rec_ins.customer_id;
    gr_order_h_rec.customer_code               := lr_order_h_rec_ins.customer_code;
    gr_order_h_rec.deliver_to_id               := lr_order_h_rec_ins.deliver_to_id;
    gr_order_h_rec.deliver_to                  := lr_order_h_rec_ins.deliver_to;
    gr_order_h_rec.shipping_instructions       := lr_order_h_rec_ins.shipping_instructions;
    gr_order_h_rec.career_id                   := lr_order_h_rec_ins.career_id;
    gr_order_h_rec.freight_carrier_code        := lr_order_h_rec_ins.freight_carrier_code;
    gr_order_h_rec.shipping_method_code        := lr_order_h_rec_ins.shipping_method_code;
    gr_order_h_rec.cust_po_number              := lr_order_h_rec_ins.cust_po_number;
    gr_order_h_rec.price_list_id               := lr_order_h_rec_ins.price_list_id;
    gr_order_h_rec.request_no                  := lr_order_h_rec_ins.request_no;
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.req_status                  := gv_req_status_04;
    END IF;
    gr_order_h_rec.delivery_no                 := lr_order_h_rec_ins.delivery_no;
    gr_order_h_rec.schedule_ship_date          := lr_order_h_rec_ins.schedule_ship_date;
    gr_order_h_rec.schedule_arrival_date       := lr_order_h_rec_ins.schedule_arrival_date;
    gr_order_h_rec.mixed_no                    := lr_order_h_rec_ins.mixed_no;
    gr_order_h_rec.collected_pallet_qty        := lr_order_h_rec_ins.collected_pallet_qty;
    gr_order_h_rec.confirm_request_class       := lr_order_h_rec_ins.confirm_request_class;
    gr_order_h_rec.freight_charge_class        := lr_order_h_rec_ins.freight_charge_class;
    gr_order_h_rec.shikyu_instruction_class    := lr_order_h_rec_ins.shikyu_instruction_class;
    gr_order_h_rec.shikyu_inst_rcv_class       := lr_order_h_rec_ins.shikyu_inst_rcv_class;
    gr_order_h_rec.deliver_from_id             := lr_order_h_rec_ins.deliver_from_id;
    gr_order_h_rec.deliver_from                := lr_order_h_rec_ins.deliver_from;
    gr_order_h_rec.head_sales_branch           := lr_order_h_rec_ins.head_sales_branch;
    gr_order_h_rec.po_no                       := lr_order_h_rec_ins.po_no;
    gr_order_h_rec.prod_class                  := lr_order_h_rec_ins.prod_class;
    gr_order_h_rec.no_cont_freight_class       := lr_order_h_rec_ins.no_cont_freight_class;
    gr_order_h_rec.arrival_time_from           := lr_order_h_rec_ins.arrival_time_from;
    gr_order_h_rec.arrival_time_to             := lr_order_h_rec_ins.arrival_time_to;
    gr_order_h_rec.designated_item_id          := lr_order_h_rec_ins.designated_item_id;
    gr_order_h_rec.designated_item_code        := lr_order_h_rec_ins.designated_item_code;
    gr_order_h_rec.designated_production_date  := lr_order_h_rec_ins.designated_production_date;
    gr_order_h_rec.designated_branch_no        := lr_order_h_rec_ins.designated_branch_no;
    gr_order_h_rec.slip_number                 := lr_order_h_rec_ins.slip_number;
    gr_order_h_rec.sum_quantity                := lr_order_h_rec_ins.sum_quantity;
    gr_order_h_rec.small_quantity              := lr_order_h_rec_ins.small_quantity;
    gr_order_h_rec.label_quantity              := lr_order_h_rec_ins.label_quantity;
    gr_order_h_rec.loading_efficiency_weight   := lr_order_h_rec_ins.loading_efficiency_weight;
    gr_order_h_rec.loading_efficiency_capacity := lr_order_h_rec_ins.loading_efficiency_capacity;
    gr_order_h_rec.based_weight                := lr_order_h_rec_ins.based_weight;
    gr_order_h_rec.based_capacity              := lr_order_h_rec_ins.based_capacity;
    gr_order_h_rec.mixed_ratio                 := lr_order_h_rec_ins.mixed_ratio;
    gr_order_h_rec.pallet_sum_quantity         := lr_order_h_rec_ins.pallet_sum_quantity;
    gr_order_h_rec.real_pallet_quantity        := gr_interface_info_rec(in_index).used_pallet_qty;
    gr_order_h_rec.result_freight_carrier_id   := gr_interface_info_rec(in_index).result_freight_carrier_id;
    gr_order_h_rec.result_freight_carrier_code := gr_interface_info_rec(in_index).freight_carrier_code;
    gr_order_h_rec.result_shipping_method_code := gr_interface_info_rec(in_index).shipping_method_code;
    gr_order_h_rec.result_deliver_to_id        := gr_interface_info_rec(in_index).result_deliver_to_id;
    gr_order_h_rec.result_deliver_to           := gr_interface_info_rec(in_index).party_site_code;
    gr_order_h_rec.shipped_date                := gr_interface_info_rec(in_index).shipped_date;
    gr_order_h_rec.arrival_date                := gr_interface_info_rec(in_index).arrival_date;
    gr_order_h_rec.weight_capacity_class       := lr_order_h_rec_ins.weight_capacity_class;
    gr_order_h_rec.notif_status                := lr_order_h_rec_ins.notif_status;
    gr_order_h_rec.performance_management_dept := lr_order_h_rec_ins.performance_management_dept;
    gr_order_h_rec.instruction_dept            := lr_order_h_rec_ins.instruction_dept;
    gr_order_h_rec.transfer_location_id        := lr_order_h_rec_ins.transfer_location_id;
    gr_order_h_rec.transfer_location_code      := lr_order_h_rec_ins.transfer_location_code;
    gr_order_h_rec.mixed_sign                  := lr_order_h_rec_ins.mixed_sign;
    gr_order_h_rec.screen_update_date          := lr_order_h_rec_ins.screen_update_date;
    gr_order_h_rec.screen_update_by            := lr_order_h_rec_ins.screen_update_by;
    gr_order_h_rec.tightening_date             := lr_order_h_rec_ins.tightening_date;
    gr_order_h_rec.vendor_id                   := lr_order_h_rec_ins.vendor_id;
    gr_order_h_rec.vendor_code                 := lr_order_h_rec_ins.vendor_code;
    gr_order_h_rec.vendor_site_id              := lr_order_h_rec_ins.vendor_site_id;
    gr_order_h_rec.vendor_site_code            := lr_order_h_rec_ins.vendor_site_code;
--
    INSERT INTO xxwsh_order_headers_all
      ( order_header_id                              -- 受注ヘッダアドオンID
       ,order_type_id                                -- 受注タイプID
       ,organization_id                              -- 組織ID
       ,latest_external_flag                         -- 最新フラグ
       ,ordered_date                                 -- 受注日
       ,customer_id                                  -- 顧客ID
       ,customer_code                                -- 顧客
       ,deliver_to_id                                -- 出荷先ID
       ,deliver_to                                   -- 出荷先
       ,shipping_instructions                        -- 出荷指示
       ,career_id                                    -- 運送業者ID
       ,freight_carrier_code                         -- 運送業者
       ,shipping_method_code                         -- 配送区分
       ,cust_po_number                               -- 顧客発注
       ,price_list_id                                -- 価格表
       ,request_no                                   -- 依頼No
       ,req_status                                   -- ステータス
       ,delivery_no                                  -- 配送no
       ,schedule_ship_date                           -- 出荷予定日
       ,schedule_arrival_date                        -- 着荷予定日
       ,mixed_no                                     -- 混載元No
       ,collected_pallet_qty                         -- パレット回収枚数
       ,confirm_request_class                        -- 物流担当確認依頼区分
       ,freight_charge_class                         -- 運賃区分
       ,shikyu_instruction_class                     -- 支給出庫指示区分
       ,shikyu_inst_rcv_class                        -- 支給指示受領区分
       ,deliver_from_id                              -- 出荷元ID
       ,deliver_from                                 -- 出荷元保管場所
       ,head_sales_branch                            -- 管轄拠点
       ,po_no                                        -- 発注No
       ,prod_class                                   -- 商品区分
       ,no_cont_freight_class                        -- 契約外運賃区分
       ,arrival_time_from                            -- 着荷時間from
       ,arrival_time_to                              -- 着荷時間to
       ,designated_item_id                           -- 製造品目ID
       ,designated_item_code                         -- 製造品目
       ,designated_production_date                   -- 製造日
       ,designated_branch_no                         -- 製造枝番
       ,slip_number                                  -- 送り状No
       ,sum_quantity                                 -- 合計数量
       ,small_quantity                               -- 小口個数
       ,label_quantity                               -- ラベル枚数
       ,loading_efficiency_weight                    -- 重量積載効率
       ,loading_efficiency_capacity                  -- 容積積載効率
       ,based_weight                                 -- 基本重量
       ,based_capacity                               -- 基本容積
       ,mixed_ratio                                  -- 混載率
       ,pallet_sum_quantity                          -- パレット合計枚数
       ,real_pallet_quantity                         -- パレット実績枚数
       ,result_freight_carrier_id                    -- 運送業者_実績ID
       ,result_freight_carrier_code                  -- 運送業者_実績
       ,result_shipping_method_code                  -- 配送区分_実績
       ,result_deliver_to_id                         -- 出荷先_実績ID
       ,result_deliver_to                            -- 出荷先_実績
       ,shipped_date                                 -- 出荷日
       ,arrival_date                                 -- 着荷日
       ,weight_capacity_class                        -- 重量容積区分
       ,notif_status                                 -- 通知ステータス
       ,new_modify_flg                               -- 新規修正フラグ
       ,performance_management_dept                  -- 成績管理部署
       ,instruction_dept                             -- 指示部署
       ,transfer_location_id                         -- 振替先ID
       ,transfer_location_code                       -- 振替先
       ,mixed_sign                                   -- 混載記号
       ,screen_update_date                           -- 画面更新日時
       ,screen_update_by                             -- 画面更新者
       ,tightening_date                              -- 出荷依頼締め日時
       ,vendor_id                                    -- 取引先ID
       ,vendor_code                                  -- 取引先
       ,vendor_site_id                               -- 取引先サイトID
       ,vendor_site_code                             -- 取引先サイト
       ,corrected_tighten_class                      -- 締め後修正区分
       ,created_by                                   -- 作成者
       ,creation_date                                -- 作成日
       ,last_updated_by                              -- 最終更新者
       ,last_update_date                             -- 最終更新日
       ,last_update_login                            -- 最終更新ログイン
       ,request_id                                   -- 要求id
       ,program_application_id                       -- アプリケーションid
       ,program_id                                   -- コンカレント・プログラムid
       ,program_update_date                          -- プログラム更新日
      )
      VALUES
      ( gr_order_h_rec.order_header_id               -- 受注ヘッダアドオンID
       ,gr_order_h_rec.order_type_id                 -- 受注タイプID
       ,gr_order_h_rec.organization_id               -- 組織ID
       ,gr_order_h_rec.latest_external_flag          -- 最新フラグ
       ,gr_order_h_rec.ordered_date                  -- 受注日
       ,gr_order_h_rec.customer_id                   -- 顧客ID
       ,gr_order_h_rec.customer_code                 -- 顧客
       ,gr_order_h_rec.deliver_to_id                 -- 出荷先ID
       ,gr_order_h_rec.deliver_to                    -- 出荷先
       ,gr_order_h_rec.shipping_instructions         -- 出荷指示
       ,gr_order_h_rec.career_id                     -- 運送業者ID
       ,gr_order_h_rec.freight_carrier_code          -- 運送業者
       ,gr_order_h_rec.shipping_method_code          -- 配送区分
       ,gr_order_h_rec.cust_po_number                -- 顧客発注
       ,gr_order_h_rec.price_list_id                 -- 価格表
       ,gr_order_h_rec.request_no                    -- 依頼No
       ,gr_order_h_rec.req_status                    -- ステータス
       ,gr_order_h_rec.delivery_no                   -- 配送no
       ,gr_order_h_rec.schedule_ship_date            -- 出荷予定日
       ,gr_order_h_rec.schedule_arrival_date         -- 着荷予定日
       ,gr_order_h_rec.mixed_no                      -- 混載元No
       ,gr_order_h_rec.collected_pallet_qty          -- パレット回収枚数
       ,gr_order_h_rec.confirm_request_class         -- 物流担当確認依頼区分
       ,gr_order_h_rec.freight_charge_class          -- 運賃区分
       ,gr_order_h_rec.shikyu_instruction_class      -- 支給出庫指示区分
       ,gr_order_h_rec.shikyu_inst_rcv_class         -- 支給指示受領区分
       ,gr_order_h_rec.deliver_from_id               -- 出荷元ID
       ,gr_order_h_rec.deliver_from                  -- 出荷元保管場所
       ,gr_order_h_rec.head_sales_branch             -- 管轄拠点
       ,gr_order_h_rec.po_no                         -- 発注No
       ,gr_order_h_rec.prod_class                    -- 商品区分
       ,gr_order_h_rec.no_cont_freight_class         -- 契約外運賃区分
       ,gr_order_h_rec.arrival_time_from             -- 着荷時間from
       ,gr_order_h_rec.arrival_time_to               -- 着荷時間to
       ,gr_order_h_rec.designated_item_id            -- 製造品目ID
       ,gr_order_h_rec.designated_item_code          -- 製造品目
       ,gr_order_h_rec.designated_production_date    -- 製造日
       ,gr_order_h_rec.designated_branch_no          -- 製造枝番
       ,gr_order_h_rec.slip_number                   -- 送り状No
       ,gr_order_h_rec.sum_quantity                  -- 合計数量
       ,gr_order_h_rec.small_quantity                -- 小口個数
       ,gr_order_h_rec.label_quantity                -- ラベル枚数
       ,gr_order_h_rec.loading_efficiency_weight     -- 重量積載効率
       ,gr_order_h_rec.loading_efficiency_capacity   -- 容積積載効率
       ,gr_order_h_rec.based_weight                  -- 基本重量
       ,gr_order_h_rec.based_capacity                -- 基本容積
       ,gr_order_h_rec.mixed_ratio                   -- 混載率
       ,gr_order_h_rec.pallet_sum_quantity           -- パレット合計枚数
       ,gr_order_h_rec.real_pallet_quantity          -- パレット実績枚数
       ,gr_order_h_rec.result_freight_carrier_id     -- 運送業者_実績ID
       ,gr_order_h_rec.result_freight_carrier_code   -- 運送業者_実績
       ,gr_order_h_rec.result_shipping_method_code   -- 配送区分_実績
       ,gr_order_h_rec.result_deliver_to_id          -- 出荷先_実績ID
       ,gr_order_h_rec.result_deliver_to             -- 出荷先_実績
       ,gr_order_h_rec.shipped_date                  -- 出荷日
       ,gr_order_h_rec.arrival_date                  -- 着荷日
       ,gr_order_h_rec.weight_capacity_class         -- 重量容積区分
       ,gr_order_h_rec.notif_status                  -- 通知ステータス
       ,gv_yesno_n                                   -- 新規修正フラグ
       ,gr_order_h_rec.performance_management_dept   -- 成績管理部署
       ,gr_order_h_rec.instruction_dept              -- 指示部署
       ,gr_order_h_rec.transfer_location_id          -- 振替先ID
       ,gr_order_h_rec.transfer_location_code        -- 振替先
       ,gr_order_h_rec.mixed_sign                    -- 混載記号
       ,gr_order_h_rec.screen_update_date            -- 画面更新日時
       ,gr_order_h_rec.screen_update_by              -- 画面更新者
       ,gr_order_h_rec.tightening_date               -- 出荷依頼締め日時
       ,gr_order_h_rec.vendor_id                     -- 取引先ID
       ,gr_order_h_rec.vendor_code                   -- 取引先
       ,gr_order_h_rec.vendor_site_id                -- 取引先サイトID
       ,gr_order_h_rec.vendor_site_code              -- 取引先サイト
       ,gv_yesno_n                                   -- 締め後修正区分
       ,gt_user_id                                   -- 作成者
       ,gt_sysdate                                   -- 作成日
       ,gt_user_id                                   -- 最終更新者
       ,gt_sysdate                                   -- 最終更新日
       ,gt_login_id                                  -- 最終更新ログイン
       ,gt_conc_request_id                           -- 要求ID
       ,gt_prog_appl_id                              -- アプリケーションID
       ,gt_conc_program_id                           -- コンカレント・プログラムID
       ,gt_sysdate                                   -- プログラム更新日
      );
--
--********** 2008/07/07 ********** DELETE START ***
--* -- 受注ヘッダ更新作成件数(実績訂正)加算
--* gn_ord_h_upd_y_cnt := gn_ord_h_upd_y_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
      -- *** 任意で例外処理を記述する ****
    WHEN no_record_expt THEN                           --*** 対象データなし ***
      ov_errmsg  := lv_errmsg;                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
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
  END order_headers_inup;
--
--
 /**********************************************************************************
  * F Name   : order_lines_upd
  * Description      : 受注明細アドオンUPDATE プロシージャ(A-8-5)
  ***********************************************************************************/
  PROCEDURE order_lines_upd(
    in_idx                  IN  NUMBER,              -- データindex
    in_order_line_id        IN  NUMBER,              -- 受注明細アドオンID
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_lines_upd'; -- プログラム名
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
    lt_order_header_id         xxwsh_order_headers_all.order_header_id%TYPE;
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
--  初期化
    gr_order_l_rec     := gr_order_l_ini;
--
    -- 出荷実績数量の設定を行う。
    -- ロット管理区分 = 0:ロット管理品対象外
    IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0) THEN
--
      -- 出荷依頼IF明細.出荷実績数量を設定
      gr_order_l_rec.shipped_quantity
             := gr_interface_info_rec(in_idx).shiped_quantity;
--
      -- **************************************************
      -- *** 受注明細(アドオン)更新を行う
      -- **************************************************
      UPDATE
        xxwsh_order_lines_all    xola    -- 受注明細(アドオン)
      SET
         xola.shipped_quantity        = gr_order_l_rec.shipped_quantity   -- 出庫実績数量
        ,xola.last_updated_by         = gt_user_id                        -- 最終更新者
        ,xola.last_update_date        = gt_sysdate                        -- 最終更新日
        ,xola.last_update_login       = gt_login_id                       -- 最終更新ログイン
        ,xola.request_id              = gt_conc_request_id                -- 要求ID
        ,xola.program_application_id  = gt_prog_appl_id                   -- アプリケーションID
        ,xola.program_id              = gt_conc_program_id                -- プログラムID
        ,xola.program_update_date     = gt_sysdate                        -- プログラム更新日
      WHERE xola.order_line_id = in_order_line_id                  -- 受注明細アドオンID
      AND   ((xola.delete_flag = gv_yesno_n) OR (xola.delete_flag IS NULL))
      ;
--
    END IF;
--
--********** 2008/07/07 ********** MODIFY START ***
--* --受注明細更新作成件数(実績計上品目あり)加算
--* gn_ord_l_upd_n_cnt := gn_ord_l_upd_n_cnt + 1;
--
    IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200)
    THEN
      -- 支給の場合
      gn_ord_new_shikyu_cnt := gn_ord_new_shikyu_cnt + 1;
--
    ELSE
      -- 出荷の場合
      gn_ord_new_syukka_cnt := gn_ord_new_syukka_cnt + 1;
--
    END IF;
--********** 2008/07/07 ********** MODIFY END   ***
--
    -- 受注明細IDを設定
    gr_order_l_rec.order_line_id := in_order_line_id;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END order_lines_upd;
--
 /**********************************************************************************
  * Procedure Name   : order_lines_ins
  * Description      : 受注明細アドオンINSERT プロシージャ(A-8-6)
  ***********************************************************************************/
  PROCEDURE order_lines_ins(
    in_idx                  IN  NUMBER,              -- データindex
    iv_cnt_kbn              IN  VARCHAR2,            -- データ件数カウント区分
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_lines_ins'; -- プログラム名
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
    --受注明細アドオンID
    lt_order_line_id_s1         xxwsh_order_lines_all.order_line_id%TYPE;
    -- *** ローカル変数 ***
    ln_order_line_seq           NUMBER;  --受注L.明細IDseq
    ln_line_number              NUMBER;  --明細番号
    ln_sum_actual_quantity      xxinv_mov_lot_details.actual_quantity%TYPE;
--
    ln_order_header_id          xxwsh_order_headers_all.order_header_id%TYPE;        --訂正前の受注ヘッダアドオンID
    ln_based_request_quantity   xxwsh_order_lines_all.based_request_quantity%TYPE;   --拠点依頼数量
    ln_reserved_quantity        xxwsh_order_lines_all.reserved_quantity%TYPE;        --引当数
    lv_automanual_reserve_class xxwsh_order_lines_all.automanual_reserve_class%TYPE; --自動手動引当区分
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
--  初期化
    gr_order_l_rec     := gr_order_l_ini;
--
    -- 受注明細の明細ID取得
    SELECT xxwsh_order_lines_all_s1.NEXTVAL
    INTO   lt_order_line_id_s1
    FROM   dual;
--
    -- 受注明細アドオンID
     gr_order_l_rec.order_line_id   := lt_order_line_id_s1;
--
    -- 受注ヘッダアドオンID
    gr_order_l_rec.order_header_id  := gr_order_h_rec.order_header_id;
    -- 明細番号
    -- 同一ヘッダのMAX(明細番号) + 1を取得
    SELECT NVL( MAX(order_line_number), 0 ) + 1
    INTO   ln_line_number
    FROM   xxwsh_order_lines_all xora
    WHERE  xora.order_header_id   = gr_order_h_rec.order_header_id   --受注ヘッダID
            ;
--
    gr_order_l_rec.order_line_number := ln_line_number; -- 同一ヘッダのMAX(明細番号) + 1
    -- 依頼No  (IF_H.依頼No)
    gr_order_l_rec.request_no        := gr_order_h_rec.request_no;
    -- 出荷品目ID  (OPM品目マスタ.OPM品目ID)
    gr_order_l_rec.shipping_inventory_item_id := gr_interface_info_rec(in_idx).inventory_item_id;
    -- 出荷品目  (IF_L.受注品目)
    gr_order_l_rec.shipping_item_code := gr_interface_info_rec(in_idx).orderd_item_code;
    -- 単位  (OPM品目マスタ.OPM品目ID)
    gr_order_l_rec.uom_code           := gr_interface_info_rec(in_idx).item_um;
--
    --依頼品目ID・依頼品目の設定を行う。
    --(EOSデータ種別 = 210 拠点出荷確定報告 又は EOSデータ種別 = 215 庭先出荷確定報告の場合
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
      --品目区分で設定値を切り替える
      IF  (gr_interface_info_rec(in_idx).item_kbn_cd <> gv_item_kbn_cd_5) THEN
--
        -- 依頼品目ID
        gr_order_l_rec.request_item_id   := gr_interface_info_rec(in_idx).whse_inventory_item_id;--OPM品目マスタ.倉庫品目ID
        -- 依頼品目
        gr_order_l_rec.request_item_code := gr_interface_info_rec(in_idx).whse_inventory_item_no;--OPM品目マスタ.品目(倉庫品目)
--
      ELSE
--
        -- 依頼品目ID
        gr_order_l_rec.request_item_id   := gr_interface_info_rec(in_idx).inventory_item_id;--INV品目マスタ.品目ID
        -- 依頼品目
        gr_order_l_rec.request_item_code := gr_interface_info_rec(in_idx).orderd_item_code; --IF_L.受注品目
--
      END IF;
--
    END IF;
--
    --(EOSデータ種別 = 200 有償出荷報告の場合)
    IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
      -- 依頼品目ID
      gr_order_l_rec.request_item_id   := gr_interface_info_rec(in_idx).whse_inventory_item_id; --OPM倉庫品目ID
      -- 依頼品目
      gr_order_l_rec.request_item_code := gr_interface_info_rec(in_idx).whse_inventory_item_no; --OPM品目マスタ.品目(倉庫品目)
--
    END IF;
--
    -- 出荷実績数量の設定を行う。
    -- ロット管理区分 = 0:ロット管理品対象外
    IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0) THEN
--
      -- 出荷依頼IF明細.出荷実績数量を設定
      gr_order_l_rec.shipped_quantity
             := gr_interface_info_rec(in_idx).shiped_quantity;
    END IF;
--
    -- 初期クリア　NULLセット
    gr_order_l_rec.based_request_quantity   := 0;        --拠点依頼数量
    gr_order_l_rec.reserved_quantity        := 0;        --引当数
    gr_order_l_rec.automanual_reserve_class := NULL;     --自動手動引当区分
--
    -- 訂正（同品目）の場合、ＩＦにない項目の値を訂正前レコードより受け継ぐ
    IF (iv_cnt_kbn = gv_cnt_kbn_4) THEN
--
      BEGIN
        -- 実績計上済みのMAXヘッダID取得
        SELECT    MAX(xoha.order_header_id) order_header_id
        INTO      ln_order_header_id       -- ヘッダID
        FROM      xxwsh_order_headers_all   xoha    -- 受注ヘッダ(アドオン)
        WHERE     NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null)
        AND       xoha.request_no = gr_interface_info_rec(in_idx).order_source_ref
        AND       actual_confirm_class = gv_yesno_y
        GROUP BY  xoha.delivery_no                 --配送No
                 ,xoha.order_source_ref            --受注ソース参照
        ;
--
        -- 訂正前の明細情報を取得
        SELECT   xola.based_request_quantity
                ,xola.reserved_quantity
                ,xola.automanual_reserve_class
        INTO     ln_based_request_quantity                      -- 拠点依頼数量
                ,ln_reserved_quantity                           -- 引当数
                ,lv_automanual_reserve_class                    -- 自動手動引当区分
        FROM    xxwsh_order_lines_all     xola                  -- 受注明細(アドオン)
        WHERE   xola.order_header_id = ln_order_header_id       -- 受注ヘッダアドオンID
        AND     xola.shipping_item_code = gr_interface_info_rec(in_idx).orderd_item_code -- 出荷品目
        AND     ((xola.delete_flag = gv_yesno_n) OR (xola.delete_flag IS NULL))
        ;
--
        -- 取得した値をセット
        gr_order_l_rec.based_request_quantity   := ln_based_request_quantity;   --拠点依頼数量
        gr_order_l_rec.reserved_quantity        := ln_reserved_quantity;        --引当数
        gr_order_l_rec.automanual_reserve_class := lv_automanual_reserve_class; --自動手動引当区分
--
      EXCEPTION
--
        WHEN NO_DATA_FOUND THEN
          gr_order_l_rec.based_request_quantity   := 0;        --拠点依頼数量
          gr_order_l_rec.reserved_quantity        := 0;        --引当数
          gr_order_l_rec.automanual_reserve_class := NULL;     --自動手動引当区分
--
      END;
--
    END IF;
--
    -- **************************************************
    -- *** 受注明細(アドオン)登録を行う
    -- **************************************************
    INSERT INTO xxwsh_order_lines_all
      (order_line_id                               -- 受注明細アドオンID
      ,order_header_id                             -- 受注ヘッダアドオンID
      ,order_line_number                           -- 明細番号
      ,request_no                                  -- 依頼No
      ,shipping_inventory_item_id                  -- 出荷品目ID
      ,shipping_item_code                          -- 出荷品目
      ,uom_code                                    -- 単位
      ,request_item_id                             -- 依頼品目ID
      ,request_item_code                           -- 依頼品目
      ,shipped_quantity                            -- 出庫実績数量
      ,based_request_quantity                      -- 拠点依頼数量
      ,reserved_quantity                           -- 引当数
      ,automanual_reserve_class                    -- 自動手動引当区分
      ,delete_flag                                 -- 削除フラグ
      ,rm_if_flg                                   -- 倉替返品インタフェース済フラグ
      ,shipping_request_if_flg                     -- 出荷依頼インタフェース済フラグ
      ,shipping_result_if_flg                      -- 出荷実績インタフェース済フラグ
      ,created_by                                  -- 作成者
      ,creation_date                               -- 作成日
      ,last_updated_by                             -- 最終更新者
      ,last_update_date                            -- 最終更新日
      ,last_update_login                           -- 最終更新ログイン
      ,request_id                                  -- 要求ID
      ,program_application_id                      -- アプリケーションID
      ,program_id                                  -- コンカレント・プログラムID
      ,program_update_date                         -- プログラム更新日
      )
    VALUES
      (gr_order_l_rec.order_line_id                --受注明細アドオンID
      ,gr_order_l_rec.order_header_id              --受注ヘッダアドオンID
      ,gr_order_l_rec.order_line_number            --明細番号
      ,gr_order_l_rec.request_no                   --依頼no
      ,gr_order_l_rec.shipping_inventory_item_id   --出荷品目ID
      ,gr_order_l_rec.shipping_item_code           --出荷品目
      ,gr_order_l_rec.uom_code                     --単位
      ,gr_order_l_rec.request_item_id              --依頼品目ID
      ,gr_order_l_rec.request_item_code            --依頼品目
      ,gr_order_l_rec.shipped_quantity             --出庫実績数量
      ,gr_order_l_rec.based_request_quantity       --拠点依頼数量
      ,gr_order_l_rec.reserved_quantity            --引当数
      ,gr_order_l_rec.automanual_reserve_class     --自動手動引当区分
      ,gv_yesno_n                                  --削除フラグ
      ,gv_yesno_n                                  --倉替返品インタフェース済フラグ
      ,gv_yesno_n                                  --出荷依頼インタフェース済フラグ
      ,gv_yesno_n                                  --出荷実績インタフェース済フラグ
      ,gt_user_id                                  --作成者
      ,gt_sysdate                                  --作成日
      ,gt_user_id                                  --最終更新者
      ,gt_sysdate                                  --最終更新日
      ,gt_login_id                                 --最終更新ログイン
      ,gt_conc_request_id                          --要求ID
      ,gt_prog_appl_id                             --アプリケーションID
      ,gt_conc_program_id                          --コンカレント・プログラムID
      ,gt_sysdate                                  --プログラム更新日
     );
--
    --件数加算
--********** 2008/07/07 ********** MODIFY START ***
--* IF (iv_cnt_kbn = gv_cnt_kbn_2) -- 指示品目≠実績品目に加算
--* THEN
--*
--*   gn_ord_l_ins_n_cnt := gn_ord_l_ins_n_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_3) -- 外部倉庫(指示なし)に加算
--*  THEN
--*
--*       gn_ord_l_ins_cnt := gn_ord_l_ins_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_4) -- 実績修正に加算
--*  THEN
--*
--*   gn_ord_l_ins_y_cnt := gn_ord_l_ins_y_cnt + 1;
--*
--* END IF;
--*
--
    IF ((iv_cnt_kbn = gv_cnt_kbn_2) OR
        (iv_cnt_kbn = gv_cnt_kbn_3))
    THEN
      -- 指示あり（実績計上）／指示なし（外部倉庫）の場合
--
      IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200)
      THEN
        -- 支給の場合
        gn_ord_new_shikyu_cnt := gn_ord_new_shikyu_cnt + 1;
--
      ELSE
        -- 出荷の場合
        gn_ord_new_syukka_cnt := gn_ord_new_syukka_cnt + 1;
--
      END IF;
--
    ELSIF (iv_cnt_kbn = gv_cnt_kbn_4) THEN
      -- 訂正の場合
--
      IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200)
      THEN
        -- 支給の場合
        gn_ord_correct_shikyu_cnt := gn_ord_correct_shikyu_cnt + 1;
--
      ELSE
        -- 出荷の場合
        gn_ord_correct_syukka_cnt := gn_ord_correct_syukka_cnt + 1;
--
      END IF;
--
    END IF;
--
--********** 2008/07/07 ********** MODIFY END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN no_insert_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                             --# 任意 #
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                             --# 任意 #
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
  END order_lines_ins;
--
 /**********************************************************************************
  * Procedure Name   : order_movlot_detail_ins
  * Description      : 受注データ移動ロット詳細INSERT プロシージャ(A-8-7)
  ***********************************************************************************/
  PROCEDURE order_movlot_detail_ins(
    in_idx                  IN  NUMBER,              -- データindex
    iv_cnt_kbn              IN  VARCHAR2,            -- データ件数カウント区分
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_movlot_detail_ins'; -- プログラム名
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
    ln_mov_lot_seq       NUMBER;  --移動ロット詳細(アドオン).ロット詳細IDseq
    ln_order_header_id        xxwsh_order_headers_all.order_header_id%TYPE;  -- 訂正前の受注ヘッダアドオンID
    lr_movlot_detail_ins      movlot_detail_rec;
    lr_movlot_detail_ins_ini  movlot_detail_rec;
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
    -- 訂正の場合、訂正前の情報から新規指示レコードを作成する。
    IF (iv_cnt_kbn = gv_cnt_kbn_4) THEN
--
      -- 初期化
      lr_movlot_detail_ins := lr_movlot_detail_ins_ini;
--
      BEGIN 
--
        -- 実績計上済みのMAXヘッダID取得
        SELECT    MAX(xoha.order_header_id) order_header_id
        INTO      ln_order_header_id       -- ヘッダID
        FROM      xxwsh_order_headers_all   xoha    -- 受注ヘッダ(アドオン)
        WHERE     NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null)
        AND       xoha.request_no = gr_interface_info_rec(in_idx).order_source_ref
        AND       actual_confirm_class = gv_yesno_y
        GROUP BY  xoha.delivery_no                 --配送No
                 ,xoha.order_source_ref            --受注ソース参照
        ;
--
        -- 訂正前の移動ロット情報（指示）を取得する。
        SELECT  xmld.mov_lot_dtl_id               -- ロット詳細ID
              , xmld.mov_line_id                  -- 明細ID
              , xmld.document_type_code           -- 文書タイプ
              , xmld.record_type_code             -- レコードタイプ
              , xmld.item_id                      -- opm品目ID
              , xmld.item_code                    -- 品目
              , xmld.lot_id                       -- ロットID
              , xmld.lot_no                       -- ロットNO
              , xmld.actual_date                  -- 実績日
              , xmld.actual_quantity              -- 実績数量
              , xmld.automanual_reserve_class     -- 自動手動引当区分
        INTO  lr_movlot_detail_ins
        FROM    xxwsh_order_headers_all   xoha    -- 受注ヘッダ(アドオン)
              , xxwsh_order_lines_all     xola    -- 受注明細(アドオン)
              , xxinv_mov_lot_details     xmld    -- 移動ロット詳細(アドオン)
        WHERE   xoha.order_header_id      = ln_order_header_id
        AND     xoha.order_header_id      = xola.order_header_id
        AND     ((xola.delete_flag        = gv_yesno_n) OR (xola.delete_flag IS NULL))
        AND     xola.order_line_id        = xmld.mov_line_id
        AND     xmld.document_type_code  IN (gv_document_type_10,gv_document_type_30)
        AND     xmld.record_type_code     = gv_record_type_10
        AND     xmld.item_id              = gr_interface_info_rec(in_idx).item_id
        AND     NVL(xmld.lot_no,'X')      = NVL(gr_interface_info_rec(in_idx).lot_no,'X')
        ;
--
      EXCEPTION
--
        WHEN NO_DATA_FOUND THEN
        lr_movlot_detail_ins.mov_lot_dtl_id := NULL;
--
      END;
--
      -- 訂正前の移動ロット詳細があった場合
      IF (lr_movlot_detail_ins.mov_lot_dtl_id IS NOT NULL) THEN
--
        -- ロット詳細ID取得
        SELECT xxinv_mov_lot_s1.nextval
        INTO   ln_mov_lot_seq
        FROM   dual
        ;
--
        lr_movlot_detail_ins.mov_lot_dtl_id     := ln_mov_lot_seq;
--
        lr_movlot_detail_ins.mov_line_id        := gr_order_l_rec.order_line_id;
--
      -- 訂正後の移動ロット情報（指示）を作成する。
      -- **************************************************
      -- *** 移動ロット詳細(アドオン)登録を行う
      -- **************************************************
        INSERT INTO xxinv_mov_lot_details                   -- 移動ロット詳細(アドオン)
        (  mov_lot_dtl_id                                   -- ロット詳細ID
          ,mov_line_id                                      -- 明細ID
          ,document_type_code                               -- 文書タイプ
          ,record_type_code                                 -- レコードタイプ
          ,item_id                                          -- opm品目ID
          ,item_code                                        -- 品目
          ,lot_id                                           -- ロットID
          ,lot_no                                           -- ロットNO
          ,actual_date                                      -- 実績日
          ,actual_quantity                                  -- 実績数量
          ,created_by                                       -- 作成者
          ,creation_date                                    -- 作成日
          ,last_updated_by                                  -- 最終更新者
          ,last_update_date                                 -- 最終更新日
          ,last_update_login                                -- 最終更新ログイン
          ,request_id                                       -- 要求ID
          ,program_application_id                           -- アプリケーションID
          ,program_id                                       -- コンカレント・プログラムID
          ,program_update_date                              -- プログラム更新日
        )
        VALUES
        (  lr_movlot_detail_ins.mov_lot_dtl_id              -- ロット詳細ID
          ,lr_movlot_detail_ins.mov_line_id                 -- 明細ID
          ,lr_movlot_detail_ins.document_type_code          -- 文書タイプ
          ,lr_movlot_detail_ins.record_type_code            -- レコードタイプ
          ,lr_movlot_detail_ins.item_id                     -- opm品目id
          ,lr_movlot_detail_ins.item_code                   -- 品目
          ,lr_movlot_detail_ins.lot_id                      -- ロットID
          ,lr_movlot_detail_ins.lot_no                      -- ロットno
          ,lr_movlot_detail_ins.actual_date                 -- 実績日
          ,lr_movlot_detail_ins.actual_quantity             -- 実績数量
          ,gt_user_id                                       -- 作成者
          ,gt_sysdate                                       -- 作成日
          ,gt_user_id                                       -- 最終更新者
          ,gt_sysdate                                       -- 最終更新日
          ,gt_login_id                                      -- 最終更新ログイン
          ,gt_conc_request_id                               -- 要求ID
          ,gt_prog_appl_id                                  -- アプリケーションID
          ,gt_conc_program_id                               -- コンカレント・プログラムID
          ,gt_sysdate                                       -- プログラム更新日
        );
--
      END IF;
--
    END IF; 
--
    --  初期化
    gr_movlot_detail_rec := gr_movlot_detail_ini;
--
    --
    -- 新規移動ロット詳細作成
    --
--
    -- ロット詳細ID
    SELECT xxinv_mov_lot_s1.nextval
    INTO   ln_mov_lot_seq
    FROM   dual
    ;
--
    gr_movlot_detail_rec.mov_lot_dtl_id     := ln_mov_lot_seq;
--
    -- 移動明細IDを設定
    gr_movlot_detail_rec.mov_line_id        := gr_order_l_rec.order_line_id;
--
    --文書タイプを設定
    -- EOSデータ種別 = 拠点出荷確定報告 又は 庭先出荷確定報告の場合
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      gr_movlot_detail_rec.document_type_code := gv_document_type_10; --出荷依頼
--
    --  EOSデータ種別 = 200 有償出荷報告
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
      gr_movlot_detail_rec.document_type_code := gv_document_type_30; --支給指示
--
    END IF;
--
    --レコードタイプを設定
    -- EOSデータ種別 = 有償出荷報告 又は EOSデータ種別 = 拠点出荷確定報告 又は庭先出荷確定報告の場合
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      gr_movlot_detail_rec.record_type_code := gv_record_type_20;   -- 出庫実績
--
    END IF;
--
    -- OPM品目IDを設定
    gr_movlot_detail_rec.item_id      := gr_interface_info_rec(in_idx).item_id;  -- 品目ID
    -- 品目を設定
    gr_movlot_detail_rec.item_code    := gr_interface_info_rec(in_idx).orderd_item_code; -- 受注品目
    -- ロットIDを設定
    gr_movlot_detail_rec.lot_id       := gr_interface_info_rec(in_idx).lot_id;     -- ロットID
    -- ロットNoを設定
    gr_movlot_detail_rec.lot_no       := gr_interface_info_rec(in_idx).lot_no;     -- ロットNo
    -- 実績日を設定
    gr_movlot_detail_rec.actual_date  := gr_interface_info_rec(in_idx).shipped_date; -- 出荷日
--
    -- 実績数量の設定を行う
    -- EOSデータ種別 = 拠点出荷確定報告 又は 庭先出荷確定報告の場合
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      --内訳数量を設定
      gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
      -- ロット数量0の対応
      IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
         (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
         --IF_L.出荷実績数量 を設定
         gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      END IF;
--
    --  EOSデータ種別 = 200 有償出荷報告
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
      --内訳数量を設定
      gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
      -- ロット数量0の対応
      IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
         (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
         --IF_L.出荷実績数量 を設定
         gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** 移動ロット詳細(アドオン)登録を行う
    -- **************************************************
      INSERT INTO xxinv_mov_lot_details                   -- 移動ロット詳細(アドオン)
        (mov_lot_dtl_id                                   -- ロット詳細ID
        ,mov_line_id                                      -- 明細ID
        ,document_type_code                               -- 文書タイプ
        ,record_type_code                                 -- レコードタイプ
        ,item_id                                          -- opm品目ID
        ,item_code                                        -- 品目
        ,lot_id                                           -- ロットID
        ,lot_no                                           -- ロットNO
        ,actual_date                                      -- 実績日
        ,actual_quantity                                  -- 実績数量
        ,created_by                                       -- 作成者
        ,creation_date                                    -- 作成日
        ,last_updated_by                                  -- 最終更新者
        ,last_update_date                                 -- 最終更新日
        ,last_update_login                                -- 最終更新ログイン
        ,request_id                                       -- 要求ID
        ,program_application_id                           -- アプリケーションID
        ,program_id                                       -- コンカレント・プログラムID
        ,program_update_date                              -- プログラム更新日
        )
      VALUES
        (gr_movlot_detail_rec.mov_lot_dtl_id              -- ロット詳細ID
        ,gr_movlot_detail_rec.mov_line_id                 -- 明細ID
        ,gr_movlot_detail_rec.document_type_code          -- 文書タイプ
        ,gr_movlot_detail_rec.record_type_code            -- レコードタイプ
        ,gr_movlot_detail_rec.item_id                     -- opm品目id
        ,gr_movlot_detail_rec.item_code                   -- 品目
        ,gr_movlot_detail_rec.lot_id                      -- ロットID
        ,gr_movlot_detail_rec.lot_no                      -- ロットno
        ,gr_movlot_detail_rec.actual_date                 -- 実績日
        ,gr_movlot_detail_rec.actual_quantity             -- 実績数量
        ,gt_user_id                                       -- 作成者
        ,gt_sysdate                                       -- 作成日
        ,gt_user_id                                       -- 最終更新者
        ,gt_sysdate                                       -- 最終更新日
        ,gt_login_id                                      -- 最終更新ログイン
        ,gt_conc_request_id                               -- 要求ID
        ,gt_prog_appl_id                                  -- アプリケーションID
        ,gt_conc_program_id                               -- コンカレント・プログラムID
        ,gt_sysdate                                       -- プログラム更新日
       );
--
--********** 2008/07/07 ********** DELETE START ***
--* --件数加算
--* IF (iv_cnt_kbn = gv_cnt_kbn_3) -- 外部倉庫(指示なし)に加算
--* THEN
--*
--*   gn_ord_mov_ins_cnt := gn_ord_mov_ins_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_4) -- 実績修正に加算
--*  THEN
--*
--*       gn_ord_mov_ins_y_cnt := gn_ord_mov_ins_y_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_5) -- 実績計上に加算
--*  THEN
--*
--*   gn_ord_mov_ins_n_cnt := gn_ord_mov_ins_n_cnt + 1;
--*
--* END IF;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END order_movlot_detail_ins;
--
 /**********************************************************************************
  * Procedure Name   : order_movlot_detail_up
  * Description      : 受注データ移動ロット詳細UPDATE プロシージャ (A-8-8)
  ***********************************************************************************/
  PROCEDURE order_movlot_detail_up(
    in_idx                  IN  NUMBER,              -- データindex
    in_mov_lot_dtl_id       IN  NUMBER,              -- ロット詳細ID
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_movlot_detail_up'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--  初期化
    gr_movlot_detail_rec := gr_movlot_detail_ini;
--
    -- 実績日を設定
    gr_movlot_detail_rec.actual_date      := gr_interface_info_rec(in_idx).shipped_date; -- 出荷日
--
    -- 実績数量の設定を行う
    -- EOSデータ種別 = 拠点出荷確定報告 又は 庭先出荷確定報告の場合
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      --内訳数量を設定
      gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
      -- ロット数量0の対応
      IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
         (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
         --IF_L.出荷実績数量 を設定
         gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      END IF;
--
    --  EOSデータ種別 = 200 有償出荷報告
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
      --内訳数量を設定
      gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
      -- ロット数量0の対応
      IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
         (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
         --IF_L.出荷実績数量 を設定
         gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** 移動ロット詳細(アドオン)更新を行う
    -- **************************************************
    UPDATE
      xxinv_mov_lot_details    xmld     -- 移動ロット詳細(アドオン)
    SET
       xmld.actual_date             = gr_movlot_detail_rec.actual_date        -- 実績日
      ,xmld.actual_quantity         = gr_movlot_detail_rec.actual_quantity    -- 実績数量
      ,xmld.last_updated_by         = gt_user_id                              -- 最終更新者
      ,xmld.last_update_date        = gt_sysdate                              -- 最終更新日
      ,xmld.last_update_login       = gt_login_id                             -- 最終更新ログイン
      ,xmld.request_id              = gt_conc_request_id                      -- 要求ID
      ,xmld.program_application_id  = gt_prog_appl_id                         -- アプリケーションID
      ,xmld.program_id              = gt_conc_program_id                      -- プログラムID
      ,xmld.program_update_date     = gt_sysdate                              -- プログラム更新日
    WHERE
        xmld.mov_lot_dtl_id         = in_mov_lot_dtl_id      -- ロット詳細ID
    ;
--
--********** 2008/07/07 ********** DELETE START ***
--* --ロット詳細新規作成件数(受注_実績計上) 加算
--* gn_ord_mov_ins_n_cnt := gn_ord_mov_ins_n_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END order_movlot_detail_up;
--
 /**********************************************************************************
  * Procedure Name   : mov_req_instr_head_ins
  * Description      : 移動依頼/指示ヘッダアドオン(外部倉庫編集) プロシージャ(A-7-1)
  ***********************************************************************************/
  PROCEDURE mov_req_instr_head_ins(
    in_index                IN  NUMBER,                 -- データindex
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_req_instr_head_ins'; -- プログラム名
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
    lv_time_def                   CONSTANT VARCHAR2(1) := ':';
--
    -- *** ローカル変数 ***
    --移動ヘッダID
    lt_mov_hdr_id                 xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
--
    -- 最大パレット枚数算出関数パラメータ
    lv_code_class1                VARCHAR2(2);                -- 1.コード区分１
    lv_entering_despatching_code1 VARCHAR2(4);                -- 2.入出庫場所コード１
    lv_code_class2                VARCHAR2(2);                -- 3.コード区分２
    lv_entering_despatching_code2 VARCHAR2(4);                -- 4.入出庫場所コード２
    ld_standard_date              DATE;                       -- 5.基準日(適用日基準日)
    lv_ship_methods               VARCHAR2(2);                -- 6.配送区分
    on_drink_deadweight           NUMBER;                     -- 7.ドリンク積載重量
    on_leaf_deadweight            NUMBER;                     -- 8.リーフ積載重量
    on_drink_loading_capacity     NUMBER;                     -- 9.ドリンク積載容積
    on_leaf_loading_capacity      NUMBER;                     -- 10.リーフ積載容積
    on_palette_max_qty            NUMBER;                     -- 11.パレット最大枚数
--
    -- 着荷時間FROM,TO
    lv_arrival_time_from          VARCHAR2(4);
    lv_arrival_time_to            VARCHAR2(4);
    lv_arrival_from               VARCHAR2(5);
    lv_arrival_to                 VARCHAR2(5);
--
    ln_ret_code                   NUMBER;                     -- リターン・コード
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
--  初期化
    gr_mov_req_instr_h_rec := gr_mov_req_instr_h_ini;
--
    -- 移動ヘッダID取得(シーケンス)
    SELECT xxinv_mov_hdr_s1.NEXTVAL
    INTO lt_mov_hdr_id
    FROM dual;
    -- 移動依頼/指示ヘッダアドオン編集処理
    -- 移動ヘッダID
    gr_mov_req_instr_h_rec.mov_hdr_id       := lt_mov_hdr_id;
    -- 移動番号
    gr_mov_req_instr_h_rec.mov_num          := gr_interface_info_rec(in_index).order_source_ref;
    -- 移動タイプ
    gr_mov_req_instr_h_rec.mov_type         := gv_move_type_1;
    -- 入力日
    gr_mov_req_instr_h_rec.entered_date     := gd_sysdate;
    -- 指示部署
    gr_mov_req_instr_h_rec.instruction_post_code
                                            := gr_interface_info_rec(in_index).report_post_code;
    -- ステータス
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
      gr_mov_req_instr_h_rec.status         := gv_mov_status_04;  -- 出庫報告有
    ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
      gr_mov_req_instr_h_rec.status         := gv_mov_status_05;  -- 入庫報告有
    END IF;
    -- 通知ステータス
    gr_mov_req_instr_h_rec.notif_status     := gv_notif_status_40;
    -- 出庫元ID
    gr_mov_req_instr_h_rec.shipped_locat_id := gr_interface_info_rec(in_index).shipped_locat;
    -- 出庫元保管場所
    gr_mov_req_instr_h_rec.shipped_locat_code
                                            := gr_interface_info_rec(in_index).location_code;
    -- 入庫先ID
    gr_mov_req_instr_h_rec.ship_to_locat_id := gr_interface_info_rec(in_index).ship_to_locat;
    -- 入庫先保管場所
    gr_mov_req_instr_h_rec.ship_to_locat_code
                                            := gr_interface_info_rec(in_index).ship_to_location;
    -- 出庫予定日
    gr_mov_req_instr_h_rec.schedule_ship_date
                                            := gr_interface_info_rec(in_index).shipped_date;
    -- 入庫予定日
    gr_mov_req_instr_h_rec.schedule_arrival_date
                                            := gr_interface_info_rec(in_index).arrival_date;
    -- 運賃区分
    IF (NVL(gr_interface_info_rec(in_index).delivery_no,'0') <> '0') THEN
      gr_mov_req_instr_h_rec.freight_charge_class
                                            := gv_include_exclude_1;
    ELSE
      gr_mov_req_instr_h_rec.freight_charge_class
                                            := gv_include_exclude_0;
    END IF;
    -- パレット回収枚数
    gr_mov_req_instr_h_rec.collected_pallet_qty
                                            := gr_interface_info_rec(in_index).collected_pallet_qty;
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
      -- パレット枚数(出)
      gr_mov_req_instr_h_rec.out_pallet_qty
                                            := gr_interface_info_rec(in_index).used_pallet_qty;
    ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
      -- パレット枚数(入)
      gr_mov_req_instr_h_rec.in_pallet_qty  := gr_interface_info_rec(in_index).used_pallet_qty;
    END IF;
    -- 配送No
    gr_mov_req_instr_h_rec.delivery_no      := gr_interface_info_rec(in_index).delivery_no;
    -- 組織ID
    gr_mov_req_instr_h_rec.organization_id  := gv_master_org_id;
    -- 運送業者_ID
    gr_mov_req_instr_h_rec.career_id        := gr_interface_info_rec(in_index).career_id;
    -- 運送業者
    gr_mov_req_instr_h_rec.freight_carrier_code
                                            := gr_interface_info_rec(in_index).freight_carrier_code;
    -- 運送業者_ID_実績
    gr_mov_req_instr_h_rec.actual_career_id := gr_interface_info_rec(in_index).result_freight_carrier_id;
    -- 運送業者_実績
    gr_mov_req_instr_h_rec.actual_freight_carrier_code
                                            := gr_interface_info_rec(in_index).freight_carrier_code;
--
    lv_arrival_from := SUBSTRB(gr_interface_info_rec(in_index).arrival_time_from, 1, 2)
                    || lv_time_def
                    || SUBSTRB(gr_interface_info_rec(in_index).arrival_time_from, 3, 2);
--
    lv_arrival_to := SUBSTRB(gr_interface_info_rec(in_index).arrival_time_to, 1, 2)
                  || lv_time_def
                  || SUBSTRB(gr_interface_info_rec(in_index).arrival_time_to, 3, 2);
--
    BEGIN
--
      SELECT  xlvv1.lookup_code arrival_time_from
             ,xlvv2.lookup_code arrival_time_to
      INTO    lv_arrival_time_from
             ,lv_arrival_time_to
      FROM    xxcmn_lookup_values_v  xlvv1
             ,xxcmn_lookup_values_v  xlvv2
      WHERE   xlvv1.lookup_type = gv_arrival_time_type
      AND     xlvv2.lookup_type = gv_arrival_time_type
      AND     xlvv1.meaning = lv_arrival_from
      AND     xlvv2.meaning = lv_arrival_to
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_arrival_time_from := '0000';
        lv_arrival_time_to := '0000';
    END;
--
    -- 着荷時間from
    gr_mov_req_instr_h_rec.arrival_time_from
                                            := lv_arrival_time_from;
    -- 着荷時間to
    gr_mov_req_instr_h_rec.arrival_time_to  := lv_arrival_time_to;
--
    --チェック有無をIF_H.運賃区分で判定
    IF (gr_interface_info_rec(in_index).freight_charge_class = gv_include_exclude_1) THEN
      -- 基本重量
--
      -- パラメータ情報取得
      -- 1.コード区分１
      lv_code_class1                := gv_code_class_04;
      -- 2.入出庫場所コード１
      lv_entering_despatching_code1 := gr_interface_info_rec(in_index).location_code;
      -- 3.コード区分２
      lv_code_class2                := gv_code_class_04;
      -- 4.入出庫場所コード２
      lv_entering_despatching_code2 := gr_interface_info_rec(in_index).ship_to_location;
      -- 5.基準日(適用日基準日)
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
        ld_standard_date := gr_interface_info_rec(in_index).shipped_date;
      ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
        ld_standard_date := gr_interface_info_rec(in_index).arrival_date;
      END IF;
      -- 6.配送区分
      lv_ship_methods               := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- 配送区分がNULLの場合、最大配送区分を取得して最大パレット枚数を取得する。
      IF (lv_ship_methods IS NULL) THEN
--
        -- 最大配送区分算出関数
        ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                   lv_code_class1                                        -- IN:コード区分1
                                  ,lv_entering_despatching_code1                         -- IN:入出庫場所コード1
                                  ,lv_code_class2                                        -- IN:コード区分2
                                  ,lv_entering_despatching_code2                         -- IN:入出庫場所コード2
                                  ,gr_interface_info_rec(in_index).prod_kbn_cd           -- IN:商品区分
                                  ,gr_interface_info_rec(in_index).weight_capacity_class -- IN:重量容積区分
                                  ,NULL                                                  -- IN:自動配車対象区分
                                  ,ld_standard_date                                      -- IN:基準日
                                  ,lv_ship_methods                -- OUT:最大配送区分
                                  ,on_drink_deadweight            -- OUT:ドリンク積載重量
                                  ,on_leaf_deadweight             -- OUT:リーフ積載重量
                                  ,on_drink_loading_capacity      -- OUT:ドリンク積載容積
                                  ,on_leaf_loading_capacity       -- OUT:リーフ積載容積
                                  ,on_palette_max_qty);           -- OUT:パレット最大枚数
--
        IF (ln_ret_code = gn_warn) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                       -- 'XXWSH'
                        ,gv_msg_93a_152                   -- 最大配送区分算出関数エラー
                        ,gv_param1_token
                        ,gr_interface_info_rec(in_index).delivery_no           --配送No
                        ,gv_param2_token
                        ,gr_interface_info_rec(in_index).order_source_ref      --受注ソース参照
                        ,gv_table_token                                        -- トークン：TABLE_NAME
                        ,gv_table_token02_nm                                   -- テーブル名：移動依頼/指示ヘッダ(アドオン)
                        ,gv_param3_token
                        ,lv_code_class1                                        -- パラメータ：コード区分１
                        ,gv_param4_token
                        ,lv_entering_despatching_code1                         -- パラメータ：入出庫場所コード１
                        ,gv_param5_token
                        ,lv_code_class2                                        -- パラメータ：コード区分２
                        ,gv_param6_token
                        ,lv_entering_despatching_code2                         -- パラメータ：入出庫場所コード２
                        ,gv_param7_token
                        ,gr_interface_info_rec(in_index).prod_kbn_cd           -- パラメータ：商品区分
                        ,gv_param8_token
                        ,gr_interface_info_rec(in_index).weight_capacity_class -- パラメータ：重量容積区分
                        ,gv_param9_token
                        ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                -- パラメータ：基準日
                        )
                        ,1
                        ,5000);
--
          RAISE global_api_expt;   -- 最大配送区分算出関数エラーの場合はABENDさせてすべてROLLBACKする
--
        END IF;
--
        gr_interface_info_rec(in_index).shipping_method_code := lv_ship_methods;
--
      END IF;
--
      -- 最大パレット枚数取得
      ln_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                                lv_code_class1,                 -- 1.コード区分１
                                lv_entering_despatching_code1,  -- 2.入出庫場所コード１
                                lv_code_class2,                 -- 3.コード区分２
                                lv_entering_despatching_code2,  -- 4.入出庫場所コード２
                                ld_standard_date,               -- 5.基準日(適用日基準日)
                                lv_ship_methods,                -- 6.配送区分
                                on_drink_deadweight,            -- 7.ドリンク積載重量
                                on_leaf_deadweight,             -- 8.リーフ積載重量
                                on_drink_loading_capacity,      -- 9.ドリンク積載容積
                                on_leaf_loading_capacity,       -- 10.リーフ積載容積
                                on_palette_max_qty);            -- 11.パレット最大枚数
--
      IF (ln_ret_code = gn_warn) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                       -- 'XXWSH'
                      ,gv_msg_93a_025                   -- 最大パレット枚数算出関数エラー
                      ,gv_param7_token
                      ,gr_interface_info_rec(in_index).delivery_no      --配送No
                      ,gv_param8_token
                      ,gr_interface_info_rec(in_index).order_source_ref --受注ソース参照
                      ,gv_table_token                   -- トークン：TABLE_NAME
                      ,gv_table_token02_nm              -- テーブル名：移動依頼/指示ヘッダ(アドオン)
                      ,gv_param1_token
                      ,lv_code_class1                   -- パラメータ：コード区分１
                      ,gv_param2_token
                      ,lv_entering_despatching_code1    -- パラメータ：入出庫場所コード１
                      ,gv_param3_token
                      ,lv_code_class2                   -- パラメータ：コード区分２
                      ,gv_param4_token
                      ,lv_entering_despatching_code2    -- パラメータ：入出庫場所コード２
                      ,gv_param5_token
                      ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                 -- パラメータ：基準日
                      ,gv_param6_token
                      ,lv_ship_methods                  -- パラメータ：配送区分
                      )
                      ,1
                      ,5000);
--
        RAISE global_api_expt;   -- 最大パレット枚数算出関数エラーの場合はABENDさせてすべてROLLBACKする
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_weight   := on_drink_deadweight;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_weight   := on_leaf_deadweight;
      END IF;
      -- 基本容積
      IF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_capacity := on_drink_loading_capacity;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_capacity := on_leaf_loading_capacity;
      END IF;
--
      -- 配送区分
      gr_mov_req_instr_h_rec.shipping_method_code
                                            := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- 配送区分_実績
      gr_mov_req_instr_h_rec.actual_shipping_method_code
                                            := gr_interface_info_rec(in_index).shipping_method_code;
--
    END IF;
--
    -- 重量容積区分
    gr_mov_req_instr_h_rec.weight_capacity_class
                                            := gr_interface_info_rec(in_index).weight_capacity_class;
    -- 出庫実績日
    gr_mov_req_instr_h_rec.actual_ship_date := gr_interface_info_rec(in_index).shipped_date;
    -- 入庫実績日
    gr_mov_req_instr_h_rec.actual_arrival_date
                                            := gr_interface_info_rec(in_index).arrival_date;
    -- 商品区分
    gr_mov_req_instr_h_rec.item_class       := gr_interface_info_rec(in_index).prod_kbn_cd;
    -- 製品識別区分
    IF (gr_interface_info_rec(in_index).item_kbn_cd = gv_item_kbn_cd_5) THEN
      gr_mov_req_instr_h_rec.product_flg    := gv_product_class_1;
    ELSE
      gr_mov_req_instr_h_rec.product_flg    := gv_product_class_2;
    END IF;
    -- 実績訂正フラグ
    gr_mov_req_instr_h_rec.correct_actual_flg
                                            := gv_yesno_n;
    -- 前回通知ステータス
    gr_mov_req_instr_h_rec.prev_notif_status
                                            := gv_notif_status_10;
    -- 確定通知実施日時
    gr_mov_req_instr_h_rec.notif_date       := gd_sysdate;
    -- 前回配送no
    gr_mov_req_instr_h_rec.prev_delivery_no := gv_prev_deliv_no_zero;
    -- 画面更新者
    gr_mov_req_instr_h_rec.screen_update_by := gt_user_id;
    -- 画面更新日時
    gr_mov_req_instr_h_rec.screen_update_date
                                            := gd_sysdate;
--
    -- 登録処理実施
    INSERT INTO xxinv_mov_req_instr_headers
      ( mov_hdr_id                                          -- 移動ヘッダid
       ,mov_num                                             -- 移動番号
       ,mov_type                                            -- 移動タイプ
       ,entered_date                                        -- 入力日
       ,instruction_post_code                               -- 指示部署
       ,status                                              -- ステータス
       ,notif_status                                        -- 通知ステータス
       ,shipped_locat_id                                    -- 出庫元ID
       ,shipped_locat_code                                  -- 出庫元保管場所
       ,ship_to_locat_id                                    -- 入庫先ID
       ,ship_to_locat_code                                  -- 入庫先保管場所
       ,schedule_ship_date                                  -- 出庫予定日
       ,schedule_arrival_date                               -- 入庫予定日
       ,freight_charge_class                                -- 運賃区分
       ,collected_pallet_qty                                -- パレット回収枚数
       ,out_pallet_qty                                      -- パレット枚数(出)
       ,in_pallet_qty                                       -- パレット枚数(入)
       ,no_cont_freight_class                               -- 契約外運賃区分
       ,delivery_no                                         -- 配送No
       ,organization_id                                     -- 組織ID
       ,career_id                                           -- 運送業者_ID
       ,freight_carrier_code                                -- 運送業者
       ,shipping_method_code                                -- 配送区分
       ,actual_career_id                                    -- 運送業者_ID_実績
       ,actual_freight_carrier_code                         -- 運送業者_実績
       ,actual_shipping_method_code                         -- 配送区分_実績
       ,arrival_time_from                                   -- 着荷時間FROM
       ,arrival_time_to                                     -- 着荷時間TO
       ,based_weight                                        -- 基本重量
       ,based_capacity                                      -- 基本容積
       ,weight_capacity_class                               -- 重量容積区分
       ,actual_ship_date                                    -- 出庫実績日
       ,actual_arrival_date                                 -- 入庫実績日
       ,item_class                                          -- 商品区分
       ,product_flg                                         -- 製品識別区分
       ,no_instr_actual_class                               -- 指示なし実績区分
       ,comp_actual_flg                                     -- 実績計上済フラグ
       ,correct_actual_flg                                  -- 実績訂正フラグ
       ,prev_notif_status                                   -- 前回通知ステータス
       ,notif_date                                          -- 確定通知実施日時
       ,prev_delivery_no                                    -- 前回配送No
       ,screen_update_by                                    -- 画面更新者
       ,screen_update_date                                  -- 画面更新日時
       ,created_by                                          -- 作成者
       ,creation_date                                       -- 作成日
       ,last_updated_by                                     -- 最終更新者
       ,last_update_date                                    -- 最終更新日
       ,last_update_login                                   -- 最終更新ログイン
       ,request_id                                          -- 要求id
       ,program_application_id                              -- アプリケーションid
       ,program_id                                          -- コンカレント・プログラムid
       ,program_update_date                                 -- プログラム更新日
      )
      VALUES
      ( gr_mov_req_instr_h_rec.mov_hdr_id                   -- 移動ヘッダID
       ,gr_mov_req_instr_h_rec.mov_num                      -- 移動番号
       ,gr_mov_req_instr_h_rec.mov_type                     -- 移動タイプ
       ,gr_mov_req_instr_h_rec.entered_date                 -- 入力日
       ,gr_mov_req_instr_h_rec.instruction_post_code        -- 指示部署
       ,gr_mov_req_instr_h_rec.status                       -- ステータス
       ,gr_mov_req_instr_h_rec.notif_status                 -- 通知ステータス
       ,gr_mov_req_instr_h_rec.shipped_locat_id             -- 出庫元ID
       ,gr_mov_req_instr_h_rec.shipped_locat_code           -- 出庫元保管場所
       ,gr_mov_req_instr_h_rec.ship_to_locat_id             -- 入庫先ID
       ,gr_mov_req_instr_h_rec.ship_to_locat_code           -- 入庫先保管場所
       ,gr_mov_req_instr_h_rec.schedule_ship_date           -- 出庫予定日
       ,gr_mov_req_instr_h_rec.schedule_arrival_date        -- 入庫予定日
       ,gr_mov_req_instr_h_rec.freight_charge_class         -- 運賃区分
       ,gr_mov_req_instr_h_rec.collected_pallet_qty         -- パレット回収枚数
       ,gr_mov_req_instr_h_rec.out_pallet_qty               -- パレット枚数(出)
       ,gr_mov_req_instr_h_rec.in_pallet_qty                -- パレット枚数(入)
       ,gv_include_exclude_0                                -- 契約外運賃区分
       ,gr_mov_req_instr_h_rec.delivery_no                  -- 配送No
       ,gr_mov_req_instr_h_rec.organization_id              -- 組織ID
       ,gr_mov_req_instr_h_rec.career_id                    -- 運送業者_ID
       ,gr_mov_req_instr_h_rec.freight_carrier_code         -- 運送業者
       ,gr_mov_req_instr_h_rec.shipping_method_code         -- 配送区分
       ,gr_mov_req_instr_h_rec.actual_career_id             -- 運送業者_ID_実績
       ,gr_mov_req_instr_h_rec.actual_freight_carrier_code  -- 運送業者_実績
       ,gr_mov_req_instr_h_rec.actual_shipping_method_code  -- 配送区分_実績
       ,gr_mov_req_instr_h_rec.arrival_time_from            -- 着荷時間FROM
       ,gr_mov_req_instr_h_rec.arrival_time_to              -- 着荷時間TO
       ,gr_mov_req_instr_h_rec.based_weight                 -- 基本重量
       ,gr_mov_req_instr_h_rec.based_capacity               -- 基本容積
       ,gr_mov_req_instr_h_rec.weight_capacity_class        -- 重量容積区分
       ,gr_mov_req_instr_h_rec.actual_ship_date             -- 出庫実績日
       ,gr_mov_req_instr_h_rec.actual_arrival_date          -- 入庫実績日
       ,gr_mov_req_instr_h_rec.item_class                   -- 商品区分
       ,gr_mov_req_instr_h_rec.product_flg                  -- 製品識別区分
       ,gv_yesno_y                                          -- 指示なし実績区分
       ,gv_yesno_n                                          -- 実績計上済フラグ
       ,gr_mov_req_instr_h_rec.correct_actual_flg           -- 実績訂正フラグ
       ,gr_mov_req_instr_h_rec.prev_notif_status            -- 前回通知ステータス
       ,gr_mov_req_instr_h_rec.notif_date                   -- 確定通知実施日時
       ,gr_mov_req_instr_h_rec.prev_delivery_no             -- 前回配送NO
       ,gr_mov_req_instr_h_rec.screen_update_by             -- 画面更新者
       ,gr_mov_req_instr_h_rec.screen_update_date           -- 画面更新日時
       ,gt_user_id                                          -- 作成者
       ,gt_sysdate                                          -- 作成日
       ,gt_user_id                                          -- 最終更新者
       ,gt_sysdate                                          -- 最終更新日
       ,gt_login_id                                         -- 最終更新ログイン
       ,gt_conc_request_id                                  -- 要求ID
       ,gt_prog_appl_id                                     -- アプリケーションID
       ,gt_conc_program_id                                  -- コンカレント・プログラムID
       ,gt_sysdate                                          -- プログラム更新日
      );
--
--********** 2008/07/07 ********** DELETE START ***
--* -- 移動依頼/指示ヘッダ登録作成件数(外部倉庫発番) に加算
--* gn_mov_h_ins_cnt := gn_mov_h_ins_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END mov_req_instr_head_ins;
--
 /**********************************************************************************
  * Procedure Name   : mov_req_instr_head_upd
  * Description      : 移動依頼/指示ヘッダアドオン(実績計上編集) プロシージャ(A-7-2)
  ***********************************************************************************/
  PROCEDURE mov_req_instr_head_upd(
    in_index                IN  NUMBER,                 -- データindex
    iv_status               IN  VARCHAR2,               -- ステータス
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_req_instr_head_upd'; -- プログラム名
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
    --移動番号
    lt_mov_num                    xxinv_mov_req_instr_headers.mov_num%TYPE;
--
    -- 最大パレット枚数算出関数パラメータ
    lv_code_class1                VARCHAR2(2);                -- 1.コード区分１
    lv_entering_despatching_code1 VARCHAR2(4);                -- 2.入出庫場所コード１
    lv_code_class2                VARCHAR2(2);                -- 3.コード区分２
    lv_entering_despatching_code2 VARCHAR2(4);                -- 4.入出庫場所コード２
    ld_standard_date              DATE;                       -- 5.基準日(適用日基準日)
    lv_ship_methods               VARCHAR2(2);                -- 6.配送区分
    on_drink_deadweight           NUMBER;                     -- 7.ドリンク積載重量
    on_leaf_deadweight            NUMBER;                     -- 8.リーフ積載重量
    on_drink_loading_capacity     NUMBER;                     -- 9.ドリンク積載容積
    on_leaf_loading_capacity      NUMBER;                     -- 10.リーフ積載容積
    on_palette_max_qty            NUMBER;                     -- 11.パレット最大枚数
--
    ln_ret_code                   NUMBER;                     -- リターン・コード
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_mov_hdr_id                 xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
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
--  初期化
    gr_mov_req_instr_h_rec := gr_mov_req_instr_h_ini;
--
    -- 移動依頼/指示ヘッダアドオン編集処理
    -- 移動番号
    gr_mov_req_instr_h_rec.mov_num        := gr_interface_info_rec(in_index).order_source_ref;
    -- 配送No
    gr_mov_req_instr_h_rec.delivery_no    := gr_interface_info_rec(in_index).delivery_no;
--
    -- ステータス
    gr_mov_req_instr_h_rec.status := iv_status;   -- まずは今入っている同じ値をセットしておく
--
    IF (iv_status = gv_mov_status_01) OR      -- 依頼中
       (iv_status = gv_mov_status_03) THEN    -- 調整中
--
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
        gr_mov_req_instr_h_rec.status := gv_mov_status_04; -- 出庫報告有をセット
      ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
        gr_mov_req_instr_h_rec.status := gv_mov_status_05; -- 入庫報告有をセット
      END IF;
--
    ELSIF (iv_status = gv_mov_status_05) THEN  -- 入庫報告有
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
        gr_mov_req_instr_h_rec.status := gv_mov_status_06; -- 入出庫報告有をセット
      END IF;
--
    ELSIF (iv_status = gv_mov_status_04) THEN  -- 出庫報告有
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
        gr_mov_req_instr_h_rec.status := gv_mov_status_06; -- 入出庫報告有をセット
      END IF;
    END IF;
--
    IF (gr_interface_info_rec(in_index).out_warehouse_flg = gv_flg_on)
    THEN
      --出庫予定日
      gr_mov_req_instr_h_rec.schedule_ship_date
                                            := gr_interface_info_rec(in_index).shipped_date;
      --入庫予定日
      gr_mov_req_instr_h_rec.schedule_arrival_date
                                            := gr_interface_info_rec(in_index).arrival_date;
    END IF;
--
    --パレット回収枚数
    gr_mov_req_instr_h_rec.collected_pallet_qty
                                          := gr_interface_info_rec(in_index).collected_pallet_qty;
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
      --パレット枚数(出)
      gr_mov_req_instr_h_rec.out_pallet_qty
                                          := gr_interface_info_rec(in_index).used_pallet_qty;
    ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
      --パレット枚数(入)
      gr_mov_req_instr_h_rec.in_pallet_qty
                                          := gr_interface_info_rec(in_index).used_pallet_qty;
    END IF;
    --運送業者_ID_実績
    gr_mov_req_instr_h_rec.actual_career_id
                                          := gr_interface_info_rec(in_index).result_freight_carrier_id;
    --運送業者_実績
    gr_mov_req_instr_h_rec.actual_freight_carrier_code
                                          := gr_interface_info_rec(in_index).freight_carrier_code;
--
    --チェック有無をIF_H.運賃区分で判定
    IF (gr_interface_info_rec(in_index).freight_charge_class = gv_include_exclude_1) THEN
--
      --基本重量
      -- パラメータ情報取得
      -- 1.コード区分１
      lv_code_class1                := gv_code_class_04;
      -- 2.入出庫場所コード１
      lv_entering_despatching_code1 := gr_interface_info_rec(in_index).location_code;
      -- 3.コード区分２
      lv_code_class2                := gv_code_class_04;
      -- 4.入出庫場所コード２
      lv_entering_despatching_code2 := gr_interface_info_rec(in_index).ship_to_location;
      -- 5.基準日(適用日基準日)
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
        ld_standard_date := gr_interface_info_rec(in_index).shipped_date;
      ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
        ld_standard_date := gr_interface_info_rec(in_index).arrival_date;
      END IF;
      -- 6.配送区分
      lv_ship_methods               := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- 配送区分がNULLの場合、最大配送区分を取得して最大パレット枚数を取得する。
      IF (lv_ship_methods IS NULL) THEN
--
        -- 最大配送区分算出関数
        ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                   lv_code_class1                                        -- IN:コード区分1
                                  ,lv_entering_despatching_code1                         -- IN:入出庫場所コード1
                                  ,lv_code_class2                                        -- IN:コード区分2
                                  ,lv_entering_despatching_code2                         -- IN:入出庫場所コード2
                                  ,gr_interface_info_rec(in_index).prod_kbn_cd           -- IN:商品区分
                                  ,gr_interface_info_rec(in_index).weight_capacity_class -- IN:重量容積区分
                                  ,NULL                                                  -- IN:自動配車対象区分
                                  ,ld_standard_date                                      -- IN:基準日
                                  ,lv_ship_methods                -- OUT:最大配送区分
                                  ,on_drink_deadweight            -- OUT:ドリンク積載重量
                                  ,on_leaf_deadweight             -- OUT:リーフ積載重量
                                  ,on_drink_loading_capacity      -- OUT:ドリンク積載容積
                                  ,on_leaf_loading_capacity       -- OUT:リーフ積載容積
                                  ,on_palette_max_qty);           -- OUT:パレット最大枚数
--
        IF (ln_ret_code = gn_warn) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                       -- 'XXWSH'
                        ,gv_msg_93a_152                   -- 最大配送区分算出関数エラー
                        ,gv_param1_token
                        ,gr_interface_info_rec(in_index).delivery_no           --配送No
                        ,gv_param2_token
                        ,gr_interface_info_rec(in_index).order_source_ref      --受注ソース参照
                        ,gv_table_token                                        -- トークン：TABLE_NAME
                        ,gv_table_token02_nm                                   -- テーブル名：移動依頼/指示ヘッダ(アドオン)
                        ,gv_param3_token
                        ,lv_code_class1                                        -- パラメータ：コード区分１
                        ,gv_param4_token
                        ,lv_entering_despatching_code1                         -- パラメータ：入出庫場所コード１
                        ,gv_param5_token
                        ,lv_code_class2                                        -- パラメータ：コード区分２
                        ,gv_param6_token
                        ,lv_entering_despatching_code2                         -- パラメータ：入出庫場所コード２
                        ,gv_param7_token
                        ,gr_interface_info_rec(in_index).prod_kbn_cd           -- パラメータ：商品区分
                        ,gv_param8_token
                        ,gr_interface_info_rec(in_index).weight_capacity_class -- パラメータ：重量容積区分
                        ,gv_param9_token
                        ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                -- パラメータ：基準日
                        )
                        ,1
                        ,5000);
--
          RAISE global_api_expt;   -- 最大配送区分算出関数エラーの場合はABENDさせてすべてROLLBACKする
--
        END IF;
--
        gr_interface_info_rec(in_index).shipping_method_code := lv_ship_methods;
--
      END IF;
--
      -- 最大パレット枚数取得
      ln_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                                lv_code_class1,                 -- 1.コード区分１
                                lv_entering_despatching_code1,  -- 2.入出庫場所コード１
                                lv_code_class2,                 -- 3.コード区分２
                                lv_entering_despatching_code2,  -- 4.入出庫場所コード２
                                ld_standard_date,               -- 5.基準日(適用日基準日)
                                lv_ship_methods,                -- 6.配送区分
                                on_drink_deadweight,            -- 7.ドリンク積載重量
                                on_leaf_deadweight,             -- 8.リーフ積載重量
                                on_drink_loading_capacity,      -- 9.ドリンク積載容積
                                on_leaf_loading_capacity,       -- 10.リーフ積載容積
                                on_palette_max_qty);            -- 11.パレット最大枚数
--
      IF (ln_ret_code = gn_warn) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                       -- 'XXWSH'
                      ,gv_msg_93a_025                   -- 最大パレット枚数算出関数エラー
                      ,gv_param7_token
                      ,gr_interface_info_rec(in_index).delivery_no      --配送No
                      ,gv_param8_token
                      ,gr_interface_info_rec(in_index).order_source_ref --受注ソース参照
                      ,gv_table_token                   -- トークン：TABLE_NAME
                      ,gv_table_token02_nm              -- テーブル名：移動依頼/指示ヘッダ(アドオン)
                      ,gv_param1_token
                      ,lv_code_class1                   -- パラメータ：コード区分１
                      ,gv_param2_token
                      ,lv_entering_despatching_code1    -- パラメータ：入出庫場所コード１
                      ,gv_param3_token
                      ,lv_code_class2                   -- パラメータ：コード区分２
                      ,gv_param4_token
                      ,lv_entering_despatching_code2    -- パラメータ：入出庫場所コード２
                      ,gv_param5_token
                      ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                 -- パラメータ：基準日
                      ,gv_param6_token
                      ,lv_ship_methods                  -- パラメータ：配送区分
                      )
                      ,1
                      ,5000);
--
        RAISE global_api_expt;   -- 最大パレット枚数算出関数エラーの場合はABENDさせてすべてROLLBACKする
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_weight := on_drink_deadweight;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_weight := on_leaf_deadweight;
      END IF;
      --基本容積
      IF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_capacity
                                            := on_drink_loading_capacity;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_capacity
                                            := on_leaf_loading_capacity;
      END IF;
--
      --配送区分_実績
      gr_mov_req_instr_h_rec.actual_shipping_method_code
                                            := gr_interface_info_rec(in_index).shipping_method_code;
--
    END IF;
--
    --出庫実績日
    gr_mov_req_instr_h_rec.actual_ship_date
                                          := gr_interface_info_rec(in_index).shipped_date;
    --入庫実績日
    gr_mov_req_instr_h_rec.actual_arrival_date
                                          := gr_interface_info_rec(in_index).arrival_date;
--
    -- 外部倉庫（指示なし）の場合、出庫／入庫予定日も出庫／入庫実績日で更新する。
    IF (gr_interface_info_rec(in_index).out_warehouse_flg = gv_flg_on)
    THEN
--
      UPDATE xxinv_mov_req_instr_headers xmrih
      SET xmrih.status                      = gr_mov_req_instr_h_rec.status
         ,xmrih.schedule_ship_date          = gr_mov_req_instr_h_rec.schedule_ship_date
         ,xmrih.schedule_arrival_date       = gr_mov_req_instr_h_rec.schedule_arrival_date
         ,xmrih.collected_pallet_qty        = gr_mov_req_instr_h_rec.collected_pallet_qty
         ,xmrih.out_pallet_qty              = DECODE(gr_mov_req_instr_h_rec.out_pallet_qty,NULL,xmrih.out_pallet_qty,gr_mov_req_instr_h_rec.out_pallet_qty)
         ,xmrih.in_pallet_qty               = DECODE(gr_mov_req_instr_h_rec.in_pallet_qty,NULL,xmrih.in_pallet_qty,gr_mov_req_instr_h_rec.in_pallet_qty)  
         ,xmrih.actual_career_id            = gr_mov_req_instr_h_rec.actual_career_id
         ,xmrih.actual_freight_carrier_code = gr_mov_req_instr_h_rec.actual_freight_carrier_code
         ,xmrih.actual_shipping_method_code = gr_mov_req_instr_h_rec.actual_shipping_method_code
         ,xmrih.based_weight                = gr_mov_req_instr_h_rec.based_weight
         ,xmrih.based_capacity              = gr_mov_req_instr_h_rec.based_capacity
         ,xmrih.actual_ship_date            = gr_mov_req_instr_h_rec.actual_ship_date
         ,xmrih.actual_arrival_date         = gr_mov_req_instr_h_rec.actual_arrival_date
         ,xmrih.last_updated_by             = gt_user_id
         ,xmrih.last_update_date            = gt_sysdate
         ,xmrih.last_update_login           = gt_login_id
         ,xmrih.request_id                  = gt_conc_request_id
         ,xmrih.program_application_id      = gt_prog_appl_id
         ,xmrih.program_id                  = gt_conc_program_id
         ,xmrih.program_update_date         = gt_sysdate
      WHERE xmrih.mov_num     = gr_mov_req_instr_h_rec.mov_num      -- 移動No
      AND   NVL(xmrih.delivery_no,gv_delivery_no_null) = NVL(gr_mov_req_instr_h_rec.delivery_no,gv_delivery_no_null)  -- 配送No
      AND   xmrih.status     <> gv_mov_status_99                    -- ステータス<>取消
      ;
--
    ELSE
--
      UPDATE xxinv_mov_req_instr_headers xmrih
      SET xmrih.status                      = gr_mov_req_instr_h_rec.status
         ,xmrih.collected_pallet_qty        = gr_mov_req_instr_h_rec.collected_pallet_qty
         ,xmrih.out_pallet_qty              = DECODE(gr_mov_req_instr_h_rec.out_pallet_qty,NULL,xmrih.out_pallet_qty,gr_mov_req_instr_h_rec.out_pallet_qty)
         ,xmrih.in_pallet_qty               = DECODE(gr_mov_req_instr_h_rec.in_pallet_qty,NULL,xmrih.in_pallet_qty,gr_mov_req_instr_h_rec.in_pallet_qty)  
         ,xmrih.actual_career_id            = gr_mov_req_instr_h_rec.actual_career_id
         ,xmrih.actual_freight_carrier_code = gr_mov_req_instr_h_rec.actual_freight_carrier_code
         ,xmrih.actual_shipping_method_code = gr_mov_req_instr_h_rec.actual_shipping_method_code
         ,xmrih.based_weight                = gr_mov_req_instr_h_rec.based_weight
         ,xmrih.based_capacity              = gr_mov_req_instr_h_rec.based_capacity
         ,xmrih.actual_ship_date            = gr_mov_req_instr_h_rec.actual_ship_date
         ,xmrih.actual_arrival_date         = gr_mov_req_instr_h_rec.actual_arrival_date
         ,xmrih.last_updated_by             = gt_user_id
         ,xmrih.last_update_date            = gt_sysdate
         ,xmrih.last_update_login           = gt_login_id
         ,xmrih.request_id                  = gt_conc_request_id
         ,xmrih.program_application_id      = gt_prog_appl_id
         ,xmrih.program_id                  = gt_conc_program_id
         ,xmrih.program_update_date         = gt_sysdate
      WHERE xmrih.mov_num     = gr_mov_req_instr_h_rec.mov_num      -- 移動No
      AND   NVL(xmrih.delivery_no,gv_delivery_no_null) = NVL(gr_mov_req_instr_h_rec.delivery_no,gv_delivery_no_null)  -- 配送No
      AND   xmrih.status     <> gv_mov_status_99                    -- ステータス<>取消
      ;
--
    END IF;
--
    -- 移動依頼/指示ヘッダIDの取得
    SELECT mov_hdr_id
    INTO lt_mov_hdr_id
    FROM xxinv_mov_req_instr_headers xmrih
    WHERE xmrih.mov_num     = gr_mov_req_instr_h_rec.mov_num      -- 移動No
    AND   NVL(xmrih.delivery_no,gv_delivery_no_null) = NVL(gr_mov_req_instr_h_rec.delivery_no,gv_delivery_no_null)  -- 配送No
    AND   xmrih.status     <> gv_mov_status_99                    -- ステータス<>取消
    ;
--
    gr_mov_req_instr_h_rec.mov_hdr_id := lt_mov_hdr_id;
--
--********** 2008/07/07 ********** DELETE START ***
--* -- 移動依頼/指示ヘッダ更新作成件数(実績計上) 加算
--* gn_mov_h_upd_n_cnt := gn_mov_h_upd_n_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END mov_req_instr_head_upd;
--
 /**********************************************************************************
  * Procedure Name   : mov_req_instr_head_inup
  * Description      : 移動依頼/指示ヘッダアドオン(実績訂正編集) プロシージャ(A-7-3)
  ***********************************************************************************/
  PROCEDURE mov_req_instr_head_inup(
    in_index                IN  NUMBER,                 -- データindex
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_req_instr_head_inup'; -- プログラム名
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
    --移動番号
    lt_mov_num                      xxinv_mov_req_instr_headers.mov_num%TYPE;
--
    -- 最大パレット枚数算出関数パラメータ
    lv_code_class1                VARCHAR2(2);                -- 1.コード区分１
    lv_entering_despatching_code1 VARCHAR2(4);                -- 2.入出庫場所コード１
    lv_code_class2                VARCHAR2(2);                -- 3.コード区分２
    lv_entering_despatching_code2 VARCHAR2(4);                -- 4.入出庫場所コード２
    ld_standard_date              DATE;                       -- 5.基準日(適用日基準日)
    lv_ship_methods               VARCHAR2(2);                -- 6.配送区分
    on_drink_deadweight           NUMBER;                     -- 7.ドリンク積載重量
    on_leaf_deadweight            NUMBER;                     -- 8.リーフ積載重量
    on_drink_loading_capacity     NUMBER;                     -- 9.ドリンク積載容積
    on_leaf_loading_capacity      NUMBER;                     -- 10.リーフ積載容積
    on_palette_max_qty            NUMBER;                     -- 11.パレット最大枚数
--
    ln_ret_code                   NUMBER;                     -- リターン・コード
--
    lt_mov_hdr_id                 xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
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
--  初期化
    gr_mov_req_instr_h_rec := gr_mov_req_instr_h_ini;
--
    -- 移動依頼/指示ヘッダアドオン編集処理
    --移動番号
    gr_mov_req_instr_h_rec.mov_num          := gr_interface_info_rec(in_index).order_source_ref;
    --配送No
    gr_mov_req_instr_h_rec.delivery_no      := gr_interface_info_rec(in_index).delivery_no;
    --パレット回収枚数
    gr_mov_req_instr_h_rec.collected_pallet_qty
                                            := gr_interface_info_rec(in_index).collected_pallet_qty;
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
      --パレット枚数(出)
      gr_mov_req_instr_h_rec.out_pallet_qty := gr_interface_info_rec(in_index).used_pallet_qty;
    ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
      --パレット枚数(入)
      gr_mov_req_instr_h_rec.in_pallet_qty  := gr_interface_info_rec(in_index).used_pallet_qty;
    END IF;
--
    --チェック有無をIF_H.運賃区分で判定
    IF (gr_interface_info_rec(in_index).freight_charge_class = gv_include_exclude_1) THEN
--
      --基本重量
      -- パラメータ情報取得
      -- 1.コード区分１
      lv_code_class1                := gv_code_class_04;
      -- 2.入出庫場所コード１
      lv_entering_despatching_code1 := gr_interface_info_rec(in_index).location_code;
      -- 3.コード区分２
      lv_code_class2                := gv_code_class_04;
      -- 4.入出庫場所コード２
      lv_entering_despatching_code2 := gr_interface_info_rec(in_index).ship_to_location;
      -- 5.基準日(適用日基準日)
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
        ld_standard_date := gr_interface_info_rec(in_index).shipped_date;
      ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
        ld_standard_date := gr_interface_info_rec(in_index).arrival_date;
      END IF;
      -- 6.配送区分
      lv_ship_methods               := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- 配送区分がNULLの場合、最大配送区分を取得して最大パレット枚数を取得する。
      IF (lv_ship_methods IS NULL) THEN
--
        -- 最大配送区分算出関数
        ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                   lv_code_class1                                        -- IN:コード区分1
                                  ,lv_entering_despatching_code1                         -- IN:入出庫場所コード1
                                  ,lv_code_class2                                        -- IN:コード区分2
                                  ,lv_entering_despatching_code2                         -- IN:入出庫場所コード2
                                  ,gr_interface_info_rec(in_index).prod_kbn_cd           -- IN:商品区分
                                  ,gr_interface_info_rec(in_index).weight_capacity_class -- IN:重量容積区分
                                  ,NULL                                                  -- IN:自動配車対象区分
                                  ,ld_standard_date                                      -- IN:基準日
                                  ,lv_ship_methods                -- OUT:最大配送区分
                                  ,on_drink_deadweight            -- OUT:ドリンク積載重量
                                  ,on_leaf_deadweight             -- OUT:リーフ積載重量
                                  ,on_drink_loading_capacity      -- OUT:ドリンク積載容積
                                  ,on_leaf_loading_capacity       -- OUT:リーフ積載容積
                                  ,on_palette_max_qty);           -- OUT:パレット最大枚数
--
        IF (ln_ret_code = gn_warn) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                       -- 'XXWSH'
                        ,gv_msg_93a_152                   -- 最大配送区分算出関数エラー
                        ,gv_param1_token
                        ,gr_interface_info_rec(in_index).delivery_no           --配送No
                        ,gv_param2_token
                        ,gr_interface_info_rec(in_index).order_source_ref      --受注ソース参照
                        ,gv_table_token                                        -- トークン：TABLE_NAME
                        ,gv_table_token02_nm                                   -- テーブル名：移動依頼/指示ヘッダ(アドオン)
                        ,gv_param3_token
                        ,lv_code_class1                                        -- パラメータ：コード区分１
                        ,gv_param4_token
                        ,lv_entering_despatching_code1                         -- パラメータ：入出庫場所コード１
                        ,gv_param5_token
                        ,lv_code_class2                                        -- パラメータ：コード区分２
                        ,gv_param6_token
                        ,lv_entering_despatching_code2                         -- パラメータ：入出庫場所コード２
                        ,gv_param7_token
                        ,gr_interface_info_rec(in_index).prod_kbn_cd           -- パラメータ：商品区分
                        ,gv_param8_token
                        ,gr_interface_info_rec(in_index).weight_capacity_class -- パラメータ：重量容積区分
                        ,gv_param9_token
                        ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                -- パラメータ：基準日
                        )
                        ,1
                        ,5000);
--
          RAISE global_api_expt;   -- 最大配送区分算出関数エラーの場合はABENDさせてすべてROLLBACKする
--
        END IF;
--
      END IF;
--
      -- 最大パレット枚数取得
      ln_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                                lv_code_class1,                 -- 1.コード区分１
                                lv_entering_despatching_code1,  -- 2.入出庫場所コード１
                                lv_code_class2,                 -- 3.コード区分２
                                lv_entering_despatching_code2,  -- 4.入出庫場所コード２
                                ld_standard_date,               -- 5.基準日(適用日基準日)
                                lv_ship_methods,                -- 6.配送区分
                                on_drink_deadweight,            -- 7.ドリンク積載重量
                                on_leaf_deadweight,             -- 8.リーフ積載重量
                                on_drink_loading_capacity,      -- 9.ドリンク積載容積
                                on_leaf_loading_capacity,       -- 10.リーフ積載容積
                                on_palette_max_qty);            -- 11.パレット最大枚数
--
      IF (ln_ret_code = gn_warn) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                       -- 'XXWSH'
                      ,gv_msg_93a_025                   -- 最大パレット枚数算出関数エラー
                      ,gv_param7_token
                      ,gr_mov_req_instr_h_rec.delivery_no --配送No
                      ,gv_param8_token
                      ,gr_mov_req_instr_h_rec.mov_num   --受注ソース参照(移動番号)
                      ,gv_table_token                   -- トークン：TABLE_NAME
                      ,gv_table_token02_nm              -- テーブル名：移動依頼/指示ヘッダ(アドオン)
                      ,gv_param1_token
                      ,lv_code_class1                   -- パラメータ：コード区分１
                      ,gv_param2_token
                      ,lv_entering_despatching_code1    -- パラメータ：入出庫場所コード１
                      ,gv_param3_token
                      ,lv_code_class2                   -- パラメータ：コード区分２
                      ,gv_param4_token
                      ,lv_entering_despatching_code2    -- パラメータ：入出庫場所コード２
                      ,gv_param5_token
                      ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')    -- パラメータ：基準日
                      ,gv_param6_token
                      ,lv_ship_methods                  -- パラメータ：配送区分
                      )
                      ,1
                      ,5000);
--
        RAISE global_api_expt;  -- 最大パレット枚数算出関数エラーの場合はABENDさせてすべてROLLBACKする
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_weight   := on_drink_deadweight;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_weight   := on_leaf_deadweight;
      END IF;
      --基本容積
      IF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_capacity := on_drink_loading_capacity;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_capacity := on_leaf_loading_capacity;
      END IF;
--
    END IF;
--
    --実績訂正フラグ
    gr_mov_req_instr_h_rec.correct_actual_flg := gv_yesno_y;
--
    UPDATE xxinv_mov_req_instr_headers xmrih
    SET xmrih.collected_pallet_qty        = gr_mov_req_instr_h_rec.collected_pallet_qty
       ,xmrih.out_pallet_qty              = DECODE(gr_mov_req_instr_h_rec.out_pallet_qty,NULL,xmrih.out_pallet_qty,gr_mov_req_instr_h_rec.out_pallet_qty)
       ,xmrih.in_pallet_qty               = DECODE(gr_mov_req_instr_h_rec.in_pallet_qty,NULL,xmrih.in_pallet_qty,gr_mov_req_instr_h_rec.in_pallet_qty)  
       ,xmrih.based_weight                = gr_mov_req_instr_h_rec.based_weight
       ,xmrih.based_capacity              = gr_mov_req_instr_h_rec.based_capacity
       ,xmrih.correct_actual_flg          = gr_mov_req_instr_h_rec.correct_actual_flg
       ,xmrih.last_updated_by             = gt_user_id
       ,xmrih.last_update_date            = gt_sysdate
       ,xmrih.last_update_login           = gt_login_id
       ,xmrih.request_id                  = gt_conc_request_id
       ,xmrih.program_application_id      = gt_prog_appl_id
       ,xmrih.program_id                  = gt_conc_program_id
       ,xmrih.program_update_date         = gt_sysdate
    WHERE xmrih.mov_num     = gr_mov_req_instr_h_rec.mov_num      -- 移動No
    AND   NVL(xmrih.delivery_no,gv_delivery_no_null) = NVL(gr_mov_req_instr_h_rec.delivery_no,gv_delivery_no_null)  -- 配送No
    AND   xmrih.status     <> gv_mov_status_99                    -- ステータス<>取消
    ;
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
    -- 移動依頼/指示ヘッダIDの取得
    SELECT mov_hdr_id
    INTO lt_mov_hdr_id
    FROM xxinv_mov_req_instr_headers xmrih
    WHERE xmrih.mov_num     = gr_mov_req_instr_h_rec.mov_num      -- 移動No
    AND   NVL(xmrih.delivery_no,gv_delivery_no_null) = NVL(gr_mov_req_instr_h_rec.delivery_no,gv_delivery_no_null)  -- 配送No
    AND   xmrih.status     <> gv_mov_status_99                    -- ステータス<>取消
    ;
--
    gr_mov_req_instr_h_rec.mov_hdr_id := lt_mov_hdr_id;
--
--********** 2008/07/07 ********** DELETE START ***
--* gn_mov_h_upd_y_cnt := gn_mov_h_upd_y_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
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
  END mov_req_instr_head_inup;
--
 /**********************************************************************************
  * Procedure Name   : mov_req_instr_lines_ins
  * Description      : 移動依頼/指示明細アドオンINSERT プロシージャ(A-7-4)
  ***********************************************************************************/
  PROCEDURE mov_req_instr_lines_ins(
    in_idx                  IN  NUMBER,              -- データindex
    iv_cnt_kbn              IN  VARCHAR2,            -- データ件数カウント区分
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_req_instr_lines_ins'; -- プログラム名
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
    lt_mov_hdr_id                               xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
    -- *** ローカル変数 ***
    ln_mov_line_seq                             NUMBER;
    ln_sum_actual_quantity                      xxinv_mov_lot_details.actual_quantity%TYPE;
    ln_line_number                              NUMBER;
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
--  初期化
    gr_mov_req_instr_l_rec := gr_mov_req_instr_l_ini;
--
    -- 移動依頼/指示ヘッダアドオン編集処理
--
    -- 移動明細IDの取得(シーケンス)
    SELECT xxinv_mov_line_s1.NEXTVAL
    INTO ln_mov_line_seq
    FROM dual;
    gr_mov_req_instr_l_rec.mov_line_id := ln_mov_line_seq;
--
    --移動ヘッダID
    gr_mov_req_instr_l_rec.mov_hdr_id := gr_mov_req_instr_h_rec.mov_hdr_id;
--
    -- 明細番号
    -- 同一ヘッダのMAX(明細番号) + 1を取得
    SELECT NVL(MAX(line_number), 0 ) + 1
    INTO   ln_line_number
    FROM   xxinv_mov_req_instr_lines xmril
    WHERE  xmril.mov_hdr_id = gr_mov_req_instr_h_rec.mov_hdr_id  --移動ヘッダID
    ;
--
    gr_mov_req_instr_l_rec.line_number     := ln_line_number;
    -- 組織ID    (システムプロファイルオプション)
    gr_mov_req_instr_l_rec.organization_id := TO_NUMBER(gv_master_org_id);
    -- OPM品目ID  (OPM品目マスタ.OPM品目IDを設定)
    gr_mov_req_instr_l_rec.item_id         := gr_interface_info_rec(in_idx).item_id;
    -- 品目  (IF_L.受注品目)
    gr_mov_req_instr_l_rec.item_code       := gr_interface_info_rec(in_idx).orderd_item_code;
    -- 単位  (OPM品目マスタ.単位)
    gr_mov_req_instr_l_rec.uom_code        := gr_interface_info_rec(in_idx).item_um;
--
    -- 出庫実績数量・入庫実績数量の設定を行う。
    -- ロット管理区分 = 0:ロット管理品対象外
    IF gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0 THEN
--
      -- 出荷依頼IF明細.出荷実績数量を設定
      gr_mov_req_instr_l_rec.shipped_quantity
             := gr_interface_info_rec(in_idx).shiped_quantity; -- 出庫実績数量
      -- 出荷依頼IF明細.入庫実績数量を設定
      gr_mov_req_instr_l_rec.ship_to_quantity
             := gr_interface_info_rec(in_idx).ship_to_quantity; -- 入庫実績数量
--
    END IF;
--
    gr_mov_req_instr_l_rec.delete_flg                  := gv_yesno_n;  --取消フラグ:'N'
--
    -- **************************************************
    -- *** 移動依頼/指示明細(アドオン)登録を行う
    -- **************************************************
    INSERT INTO xxinv_mov_req_instr_lines
      (mov_line_id                                        -- 移動明細ID
      ,mov_hdr_id                                         -- 移動ヘッダID
      ,line_number                                        -- 明細番号
      ,organization_id                                    -- 組織ID
      ,item_id                                            -- opm品目ID
      ,item_code                                          -- 品目
      ,uom_code                                           -- 単位
      ,shipped_quantity                                   -- 出庫実績数量
      ,ship_to_quantity                                   -- 入庫実績数量
      ,delete_flg                                         -- 取消フラグ
      ,created_by                                         -- 作成者
      ,creation_date                                      -- 作成日
      ,last_updated_by                                    -- 最終更新者
      ,last_update_date                                   -- 最終更新日
      ,last_update_login                                  -- 最終更新ログイン
      ,request_id                                         -- 要求ID
      ,program_application_id                             -- アプリケーションID
      ,program_id                                         -- コンカレント・プログラムID
      ,program_update_date                                -- プログラム更新日
      )
    VALUES
      (gr_mov_req_instr_l_rec.mov_line_id                 -- 移動明細ID
      ,gr_mov_req_instr_l_rec.mov_hdr_id                  -- 移動ヘッダID
      ,gr_mov_req_instr_l_rec.line_number                 -- 明細番号
      ,gr_mov_req_instr_l_rec.organization_id             -- 組織ID
      ,gr_mov_req_instr_l_rec.item_id                     -- OPM品目ID
      ,gr_mov_req_instr_l_rec.item_code                   -- 品目
      ,gr_mov_req_instr_l_rec.uom_code                    -- 単位
      ,gr_mov_req_instr_l_rec.shipped_quantity            -- 出庫実績数量
      ,gr_mov_req_instr_l_rec.ship_to_quantity            -- 入庫実績数量
      ,gr_mov_req_instr_l_rec.delete_flg                  -- 取消フラグ
      ,gt_user_id                                         -- 作成者
      ,gt_sysdate                                         -- 作成日
      ,gt_user_id                                         -- 最終更新者
      ,gt_sysdate                                         -- 最終更新日
      ,gt_login_id                                        -- 最終更新ログイン
      ,gt_conc_request_id                                 -- 要求ID
      ,gt_prog_appl_id                                    -- アプリケーションID
      ,gt_conc_program_id                                 -- コンカレント・プログラムID
      ,gt_sysdate                                         -- プログラム更新日
     );
--
    --件数加算
--********** 2008/07/07 ********** DELETE START ***
--* IF (iv_cnt_kbn = gv_cnt_kbn_2) -- 指示品目≠実績品目に加算
--* THEN
--*   gn_mov_l_ins_n_cnt := gn_mov_l_ins_n_cnt + 1;
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_3) -- 外部倉庫(指示なし)に加算
--*  THEN
--*       gn_mov_l_ins_cnt := gn_mov_l_ins_cnt + 1;
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_7) -- 訂正元品目なしに加算
--*  THEN
--*       gn_mov_l_ins_y_cnt := gn_mov_l_ins_y_cnt + 1;
--* END IF;
--
    IF ((iv_cnt_kbn = gv_cnt_kbn_2) OR
        (iv_cnt_kbn = gv_cnt_kbn_3))
    THEN
      -- 指示あり（実績計上）／指示なし（外部倉庫）の場合
      gn_mov_new_cnt := gn_mov_new_cnt + 1;
--
    ELSIF (iv_cnt_kbn = gv_cnt_kbn_7) THEN
      -- 訂正の場合
      gn_mov_correct_cnt := gn_mov_correct_cnt + 1;
--
    END IF;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END mov_req_instr_lines_ins;
--
 /**********************************************************************************
  * Procedure Name   : mov_req_instr_lines_upd
  * Description      : 移動依頼/指示明細アドオンUPDATE プロシージャ(A-7-5)
  ***********************************************************************************/
  PROCEDURE mov_req_instr_lines_upd(
    in_idx                  IN  NUMBER,              -- データindex
    in_mov_line_id          IN  NUMBER,              -- 移動明細ID
    iv_cnt_kbn              IN  VARCHAR2,            -- データ件数カウント区分
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_req_instr_lines_upd'; -- プログラム名
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
    ln_sum_actual_quantity     xxinv_mov_lot_details.actual_quantity%TYPE;
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
--  初期化
    gr_mov_req_instr_l_rec := gr_mov_req_instr_l_ini;
--
    -- 移動明細IDを設定
    -- ロット詳細のINSERTをするとき(A-7-6)に必要なキー項目なのでここで必ずセットする
    gr_mov_req_instr_l_rec.mov_line_id := in_mov_line_id;
--
    -- 出庫実績数量・入庫実績数量の設定を行う。
    -- ロット管理区分 = 0:ロット管理品対象外
    IF gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0 THEN
--
      -- 出荷依頼IF明細.出荷実績数量を設定
      gr_mov_req_instr_l_rec.shipped_quantity
             := gr_interface_info_rec(in_idx).shiped_quantity;-- 出庫実績数量
      -- 出荷依頼IF明細.入庫実績数量を設定
      gr_mov_req_instr_l_rec.ship_to_quantity
             := gr_interface_info_rec(in_idx).ship_to_quantity;-- 入庫実績数量
--
      -- **************************************************
      -- *** 移動依頼/指示明細(アドオン)更新を行う
      -- **************************************************
      UPDATE
        xxinv_mov_req_instr_lines    xmrl     -- 移動依頼/指示明細(アドオン)
      SET
         xmrl.shipped_quantity        = NVL(gr_mov_req_instr_l_rec.shipped_quantity,xmrl.shipped_quantity) -- 出庫実績数量
        ,xmrl.ship_to_quantity        = NVL(gr_mov_req_instr_l_rec.ship_to_quantity,xmrl.ship_to_quantity) -- 入庫実績数量
        ,xmrl.last_updated_by         = gt_user_id                              -- 最終更新者
        ,xmrl.last_update_date        = gt_sysdate                              -- 最終更新日
        ,xmrl.last_update_login       = gt_login_id                             -- 最終更新ログイン
        ,xmrl.request_id              = gt_conc_request_id                      -- 要求ID
        ,xmrl.program_application_id  = gt_prog_appl_id                         -- アプリケーションID
        ,xmrl.program_id              = gt_conc_program_id                      -- プログラムID
        ,xmrl.program_update_date     = gt_sysdate                              -- プログラム更新日
      WHERE
          xmrl.mov_line_id   = in_mov_line_id                                   -- 移動ヘッダID
      AND xmrl.item_code     = gr_interface_info_rec(in_idx).orderd_item_code   -- 品目
      AND ((xmrl.delete_flg = gv_yesno_n) OR (xmrl.delete_flg IS NULL))       -- 削除フラグ=未削除
      ;
--
    END IF;
--
    --件数加算
--********** 2008/07/07 ********** MODIFY START ***
--* IF (iv_cnt_kbn = gv_cnt_kbn_1)     -- 指示品目=実績品目に加算
--* THEN
--*   gn_mov_l_upd_n_cnt := gn_mov_l_upd_n_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_6) -- 訂正元品目ありに加算
--*  THEN
--*       gn_mov_l_upd_y_cnt := gn_mov_l_upd_y_cnt + 1;
--* END IF;
--
    IF (iv_cnt_kbn = gv_cnt_kbn_1)
    THEN
      -- 指示あり（実績計上）の場合
      gn_mov_new_cnt := gn_mov_new_cnt + 1;
--
    ELSIF (iv_cnt_kbn = gv_cnt_kbn_6) THEN
      -- 訂正の場合
      gn_mov_correct_cnt := gn_mov_correct_cnt + 1;
--
    END IF;
--********** 2008/07/07 ********** MODIFY END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END mov_req_instr_lines_upd;
--
 /**********************************************************************************
  * Procedure Name   : mov_movlot_detail_ins
  * Description      : 移動依頼/指示データ移動ロット詳細INSERT プロシージャ(A-7-6)
  ***********************************************************************************/
  PROCEDURE mov_movlot_detail_ins(
    in_idx                  IN  NUMBER,              -- データindex
    iv_cnt_kbn              IN  VARCHAR2,            -- データ件数カウント区分
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_movlot_detail_ins'; -- プログラム名
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
    ln_mov_lot_seq       NUMBER;  --移動ロット詳細(アドオン).ロット詳細IDseq
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
--  初期化
    gr_movlot_detail_rec := gr_movlot_detail_ini;
--
    -- ロット詳細ID
    SELECT xxinv_mov_lot_s1.nextval
    INTO   ln_mov_lot_seq
    FROM   dual
    ;
--
    gr_movlot_detail_rec.mov_lot_dtl_id     := ln_mov_lot_seq;
--
    -- 移動明細IDを設定
    gr_movlot_detail_rec.mov_line_id        := gr_mov_req_instr_l_rec.mov_line_id;
--
    -- 文書タイプを設定
    gr_movlot_detail_rec.document_type_code := gv_document_type_20; --移動
--
    -- EOSデータ種別 = 移動出庫確定報告の場合
    IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) THEN
--
      -- レコードタイプを設定
      gr_movlot_detail_rec.record_type_code := gv_record_type_20;   -- 出庫実績
      -- 実績日を設定
      gr_movlot_detail_rec.actual_date      := gr_interface_info_rec(in_idx).shipped_date; -- 出荷日
--
    -- EOSデータ種別 = 移動入庫確定報告の場合
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
--
      -- レコードタイプを設定
      gr_movlot_detail_rec.record_type_code := gv_record_type_30;   -- 入庫実績
      -- 実績日を設定
      gr_movlot_detail_rec.actual_date      := gr_interface_info_rec(in_idx).arrival_date; -- 着荷日
    END IF;
--
    -- OPM品目IDを設定
    gr_movlot_detail_rec.item_id            := gr_interface_info_rec(in_idx).item_id;
    -- 品目を設定
    gr_movlot_detail_rec.item_code          := gr_interface_info_rec(in_idx).orderd_item_code;
    -- ロット関連の編集
    IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0) THEN
      -- ロットIDを設定
      gr_movlot_detail_rec.lot_id             := 0;
      -- ロットNoを設定
      gr_movlot_detail_rec.lot_no             := NULL;
    ELSE
      -- ロットIDを設定
      gr_movlot_detail_rec.lot_id             := gr_interface_info_rec(in_idx).lot_id;
      -- ロットNoを設定
      gr_movlot_detail_rec.lot_no             := gr_interface_info_rec(in_idx).lot_no;
    END IF;
--
    --実績数量の設定を行う。
    --内訳数量を設定
    gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
    -- ロット数量0の対応
    IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
       (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
      -- EOSデータ種別 = 移動出庫確定報告の場合
      IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) THEN
--
        --IF_L.出荷実績数量 を設定
        gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      -- EOSデータ種別 = 移動入庫確定報告の場合
      ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
--
        --IF_L.入庫実績数量 を設定
        gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).ship_to_quantity;
--
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** 移動ロット詳細(アドオン)登録を行う
    -- **************************************************
      INSERT INTO xxinv_mov_lot_details                   -- 移動ロット詳細(アドオン)
        (mov_lot_dtl_id                                   -- ロット詳細ID
        ,mov_line_id                                      -- 明細ID
        ,document_type_code                               -- 文書タイプ
        ,record_type_code                                 -- レコードタイプ
        ,item_id                                          -- opm品目ID
        ,item_code                                        -- 品目
        ,lot_id                                           -- ロットID
        ,lot_no                                           -- ロットNO
        ,actual_date                                      -- 実績日
        ,actual_quantity                                  -- 実績数量
        ,created_by                                       -- 作成者
        ,creation_date                                    -- 作成日
        ,last_updated_by                                  -- 最終更新者
        ,last_update_date                                 -- 最終更新日
        ,last_update_login                                -- 最終更新ログイン
        ,request_id                                       -- 要求ID
        ,program_application_id                           -- アプリケーションID
        ,program_id                                       -- コンカレント・プログラムID
        ,program_update_date                              -- プログラム更新日
        )
      VALUES
        (gr_movlot_detail_rec.mov_lot_dtl_id              -- ロット詳細ID
        ,gr_movlot_detail_rec.mov_line_id                 -- 明細ID
        ,gr_movlot_detail_rec.document_type_code          -- 文書タイプ
        ,gr_movlot_detail_rec.record_type_code            -- レコードタイプ
        ,gr_movlot_detail_rec.item_id                     -- opm品目id
        ,gr_movlot_detail_rec.item_code                   -- 品目
        ,gr_movlot_detail_rec.lot_id                      -- ロットID
        ,gr_movlot_detail_rec.lot_no                      -- ロットno
        ,gr_movlot_detail_rec.actual_date                 -- 実績日
        ,gr_movlot_detail_rec.actual_quantity             -- 実績数量
        ,gt_user_id                                       -- 作成者
        ,gt_sysdate                                       -- 作成日
        ,gt_user_id                                       -- 最終更新者
        ,gt_sysdate                                       -- 最終更新日
        ,gt_login_id                                      -- 最終更新ログイン
        ,gt_conc_request_id                               -- 要求ID
        ,gt_prog_appl_id                                  -- アプリケーションID
        ,gt_conc_program_id                               -- コンカレント・プログラムID
        ,gt_sysdate                                       -- プログラム更新日
       );
--
--********** 2008/07/07 ********** DELETE START ***
--* --件数加算
--* IF (iv_cnt_kbn = gv_cnt_kbn_5) -- 実績計上に加算
--* THEN
--*   gn_mov_mov_ins_n_cnt := gn_mov_mov_ins_n_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_3) -- 外部倉庫(指示なし)に加算
--*  THEN
--*       gn_mov_mov_ins_cnt := gn_mov_mov_ins_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_9) -- 訂正ロットなしに加算
--*  THEN
--*   gn_mov_mov_ins_y_cnt := gn_mov_mov_ins_y_cnt + 1;
--* END IF;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END mov_movlot_detail_ins;
--
 /**********************************************************************************
  * Procedure Name   : movlot_detail_upd
  * Description      : 移動ロット詳細UPDATE プロシージャ(A-7-7)
  ***********************************************************************************/
  PROCEDURE movlot_detail_upd(
    in_idx                  IN  NUMBER,              -- データindex
    in_mov_lot_dtl_id       IN  NUMBER,              -- ロット詳細ID
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'movlot_detail_upd'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--  初期化
    gr_movlot_detail_rec := gr_movlot_detail_ini;
--
    -- EOSデータ種別 = 移動出庫確定報告の場合
    IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) THEN
--
      -- 実績日を設定
      gr_movlot_detail_rec.actual_date      := gr_interface_info_rec(in_idx).shipped_date; -- 出荷日
--
    -- EOSデータ種別 = 移動入庫確定報告の場合
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
--
      -- 実績日を設定
      gr_movlot_detail_rec.actual_date      := gr_interface_info_rec(in_idx).arrival_date; -- 着荷日
    END IF;
--
    --実績数量の設定を行う。
    --内訳数量を設定
    gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
    -- ロット数量0の対応
    IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
       (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
      -- EOSデータ種別 = 移動出庫確定報告の場合
      IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) THEN
--
        --IF_L.出荷実績数量 を設定
        gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      -- EOSデータ種別 = 移動入庫確定報告の場合
      ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
--
        --IF_L.入庫実績数量 を設定
        gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).ship_to_quantity;
--
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** 移動ロット詳細(アドオン)更新を行う
    -- **************************************************
    UPDATE
      xxinv_mov_lot_details    xmld     -- 移動ロット詳細(アドオン)
    SET
       xmld.actual_date             = gr_movlot_detail_rec.actual_date        -- 実績日
      ,xmld.actual_quantity         = gr_movlot_detail_rec.actual_quantity    -- 実績数量
      ,xmld.last_updated_by         = gt_user_id                              -- 最終更新者
      ,xmld.last_update_date        = gt_sysdate                              -- 最終更新日
      ,xmld.last_update_login       = gt_login_id                             -- 最終更新ログイン
      ,xmld.request_id              = gt_conc_request_id                      -- 要求ID
      ,xmld.program_application_id  = gt_prog_appl_id                         -- アプリケーションID
      ,xmld.program_id              = gt_conc_program_id                      -- プログラムID
      ,xmld.program_update_date     = gt_sysdate                              -- プログラム更新日
    WHERE
        xmld.mov_lot_dtl_id         = in_mov_lot_dtl_id      -- ロット詳細ID
    ;
--
--********** 2008/07/07 ********** DELETE START ***
--* --ロット詳細新規作成件数(移動依頼_訂正ロットあり) 加算
--* gn_mov_mov_upd_y_cnt := gn_mov_mov_upd_y_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END movlot_detail_upd;
--
 /**********************************************************************************
  * Procedure Name   : get_freight_charge_type
  * Description      : 運賃形態取得 プロシージャ
  ***********************************************************************************/
  PROCEDURE get_freight_charge_type(
    iv_transaction_type     IN  VARCHAR2,            --   処理種別(配車)
    iv_prod_kbn_cd          IN  VARCHAR2,            --   商品区分
    id_ship_date            IN  DATE,                --   基準日
    iv_delivery_no          IN  VARCHAR2,            --   配送No
    iv_request_no           IN  VARCHAR2,            --   依頼No
    ov_freight_charge_type  OUT NOCOPY VARCHAR2,     --   運賃形態
    ov_errbuf               OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_freight_charge_type'; -- プログラム名
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
    lv_transfer_standard_drink  xxcmn_cust_accounts2_v.drink_transfer_std%TYPE;     -- ドリンク運賃振替基準
    lv_transfer_standard_leaf   xxcmn_cust_accounts2_v.leaf_transfer_std%TYPE;      -- リーフ運賃振替基準
    lv_party_number             xxcmn_cust_accounts2_v.party_number%TYPE;           -- 組織番号
    lv_delivery_no              xxwsh_mixed_carriers_tmp.delivery_no%TYPE;          -- 配送No
    lv_default_line_number      xxwsh_mixed_carriers_tmp.default_line_number%TYPE;  -- 基準明細No
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
    -- 処理種別(配車)によって処理を振り分ける
    IF iv_transaction_type = gv_carrier_trn_type_1 THEN
      -- 出荷依頼(1)の場合
      -- 検索により求める
      BEGIN
--
        SELECT  xca.drink_transfer_std                               -- ドリンク運賃振替基準
               ,xca.leaf_transfer_std                                -- リーフ運賃振替基準
               ,xca.party_number                                     -- 組織番号
        INTO    lv_transfer_standard_drink
               ,lv_transfer_standard_leaf
               ,lv_party_number
        FROM    xxcmn_cust_accounts2_v    xca                        -- 顧客情報VIEW2
               ,xxwsh_order_headers_all   xoha                       -- 受注ヘッダアドオン
        WHERE   xca.party_number          = xoha.head_sales_branch
        AND     xca.start_date_active <= TRUNC(id_ship_date)         -- 基準日
        AND     (xca.end_date_active IS NULL OR
                 xca.end_date_active  >= TRUNC(id_ship_date))
        AND     xoha.delivery_no          = iv_delivery_no           -- 配送No
        AND     xoha.latest_external_flag = gv_yesno_y
        AND     xca.party_status          = gv_view_status
        AND     xca.account_status        = gv_view_status
        AND     ROWNUM = 1                                           -- 混載単位<->集約No単位での重複を排除
        ;
--
      EXCEPTION
        -- データ取得失敗時
        WHEN OTHERS THEN
          --取得値をNULLにセット
          ov_freight_charge_type     := NULL;    -- 運賃形態にNULL設定
          lv_transfer_standard_drink := NULL;    -- ドリンク運賃振替基準
          lv_transfer_standard_leaf  := NULL;    -- リーフ運賃振替基準
--
      END;
--
      --取得できたか
      IF (iv_prod_kbn_cd = gv_prod_kbn_cd_1 AND lv_transfer_standard_leaf  IS NULL) OR
         (iv_prod_kbn_cd = gv_prod_kbn_cd_2 AND lv_transfer_standard_drink IS NULL) THEN
--
          --取得値がNULLの場合、エラーメッセージ出力
          ov_retcode := gv_status_warn;
          ov_freight_charge_type := NULL;                                   -- 運賃形態にNULL設定
          ov_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_msg_kbn        -- 'XXWSH'
                                                         ,gv_msg_93a_147    -- メッセージ：APP-XXWSH-13147 運賃形態取得警告
                                                         ,gv_param1_token   -- トークン：配送No
                                                         ,iv_delivery_no
                                                         ,gv_param2_token   -- トークン：基準明細No(依頼No)
                                                         ,iv_request_no
                                                         ,gv_param3_token   -- トークン：顧客
                                                         ,lv_party_number
                                                          ),1,255);
--
      ELSE
--
        --運賃振替基準設定
        IF ( iv_prod_kbn_cd = gv_prod_kbn_cd_1 ) THEN
          --リーフ
          ov_freight_charge_type := lv_transfer_standard_leaf;      -- リーフ運賃振替基準
        ELSE
          --ドリンク
          ov_freight_charge_type := lv_transfer_standard_drink;     -- ドリンク運賃振替基準
        END IF;
--
      END IF;
--
    ELSE
      -- その他(支給指示(2),移動指示(3))の場合
      -- 実費振替を固定で設定する
      ov_freight_charge_type := gv_frt_chrg_type_act; -- 実費振替
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
  END get_freight_charge_type;
--
 /**********************************************************************************
  * Procedure Name   : carriers_schedule_inup
  * Description      : 配車配送計画アドオン作成 プロシージャ
  ***********************************************************************************/
  PROCEDURE carriers_schedule_inup(
    in_idx        IN  NUMBER,              --   データindex
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'carriers_schedule_inup'; -- プログラム名
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    -- 配車配送計画(アドオン)項目
    lv_transaction_type             xxwsh_carriers_schedule.transaction_type%TYPE;             -- 処理種別(配車)
    lv_mixed_type                   xxwsh_carriers_schedule.mixed_type%TYPE;                   -- 混載種別
    lv_delivery_no                  xxwsh_carriers_schedule.delivery_no%TYPE;                  -- 配送No
    lv_default_line_number          xxwsh_carriers_schedule.default_line_number%TYPE;          -- 基準明細No
    ln_carrier_id                   xxwsh_carriers_schedule.carrier_id%TYPE;                   -- 運送業者ID
    lv_carrier_code                 xxwsh_carriers_schedule.carrier_code%TYPE;                 -- 運送業者
    lv_deliver_to_code_class        xxwsh_carriers_schedule.deliver_to_code_class%TYPE;        -- 配送先コード区分
    lv_delivery_type                xxwsh_carriers_schedule.delivery_type%TYPE;                -- 配送区分
    lv_auto_process_type            xxwsh_carriers_schedule.auto_process_type%TYPE;            -- 自動配車対象区分
    ld_schedule_ship_date           xxwsh_carriers_schedule.schedule_ship_date%TYPE;           -- 出庫予定日
    ld_schedule_arrival_date        xxwsh_carriers_schedule.schedule_arrival_date%TYPE;        -- 着荷予定日
    lv_payment_freight_flag         xxwsh_carriers_schedule.payment_freight_flag%TYPE;         -- 支払運賃計算対象フラグ
    lv_demand_freight_flag          xxwsh_carriers_schedule.demand_freight_flag%TYPE;          -- 請求運賃計算対象フラグ
    ln_result_freight_carrier_id    xxwsh_carriers_schedule.result_freight_carrier_id%TYPE;    -- 運送業者_実績ID
    lv_result_freight_carrier_code  xxwsh_carriers_schedule.result_freight_carrier_code%TYPE;  -- 運送業者_実績
    lv_result_shipping_method_code  xxwsh_carriers_schedule.result_shipping_method_code%TYPE;  -- 配送区分_実績
    ld_shipped_date                 xxwsh_carriers_schedule.shipped_date%TYPE;                 -- 出荷日
    ld_arrival_date                 xxwsh_carriers_schedule.arrival_date%TYPE;                 -- 着荷日
    lv_weight_capacity_class        xxwsh_carriers_schedule.weight_capacity_class%TYPE;        -- 重量容積区分
    lv_prod_kbn_cd                  xxwsh_order_headers_all.prod_class%TYPE;                   -- 商品区分
    lv_freight_charge_type          xxwsh_carriers_schedule.freight_charge_type%TYPE;          -- 運賃形態
    -- 配車配送計画(アドオン)件数
    ln_carriers_schedule_cnt        NUMBER := 0;
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
--
    BEGIN
      -- 既存の配車配送計画(アドオン)データを検索する
      SELECT  COUNT(1)
      INTO    ln_carriers_schedule_cnt
      FROM    xxwsh_carriers_schedule
      WHERE   delivery_no = gr_interface_info_rec(in_idx).delivery_no
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_carriers_schedule_cnt := 0;
    END;
--
    IF ln_carriers_schedule_cnt < 1 THEN
    -- 配車配送計画(アドオン)データが無い場合、作成する
--
      -- 作成するための各項目値セット
      -- 処理種別(配車)
      -- EOSデータ種別より判定する
      IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210) OR      --210 拠点出荷確定報告
          (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))        --215 庭先出荷確定報告
      THEN
        -- 210 拠点出荷確定報告 or 215 庭先出荷確定報告
        -- 出荷依頼(1)を設定する
        lv_transaction_type := gv_carrier_trn_type_1;
--
      ELSIF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) OR   --220 移動出庫確定報告
             (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230))     --230 移動入庫確定報告
      THEN
        -- 220 移動出庫確定報告 or 230 移動入庫確定報告
         -- 移動指示(3)を設定する
        lv_transaction_type := gv_carrier_trn_type_3;
      ELSE                                                                           --200 有償出荷報告
        -- 200 有償出荷報告
        -- 支給指示(2)を設定する
        lv_transaction_type := gv_carrier_trn_type_2;
      END IF;
--
      -- 混載種別
      -- 集約(1)を設定する
      lv_mixed_type := gv_mixed_type_1;
--
      -- 配送No
      -- IFの配送Noを設定する
      lv_delivery_no := gr_interface_info_rec(in_idx).delivery_no;
--
      -- 基準明細No
      -- IFの依頼No(受注ソース参照)を設定する
      lv_default_line_number := gr_interface_info_rec(in_idx).order_source_ref;
--
      -- 運送業者ID
      -- IFの運送業者IDを設定する
      ln_carrier_id := gr_interface_info_rec(in_idx).career_id;
--
      -- 運送業者CD
      -- IFの運送業者CDを設定する
      lv_carrier_code := gr_interface_info_rec(in_idx).freight_carrier_code;
--
      -- 配送先コード区分
      -- IF配送先の顧客区分を設定する
      lv_deliver_to_code_class := gr_interface_info_rec(in_idx).customer_class_code;
--
      -- 配送区分
      -- IFの配送区分を設定する
      lv_delivery_type := gr_interface_info_rec(in_idx).shipping_method_code;
--
      -- 自動配車対象区分
      -- 対象外(0)を設定する
      lv_auto_process_type := gv_lv_auto_process_type_0;
--
      -- 出庫予定日
      -- IFの出荷日を設定する
      ld_schedule_ship_date := gr_interface_info_rec(in_idx).shipped_date;
--
      -- 着荷予定日
      -- IFの着荷日を設定する
      ld_schedule_arrival_date := gr_interface_info_rec(in_idx).arrival_date;
--
      -- 支払運賃計算対象フラグ
      --ON(1)を設定する。
      lv_payment_freight_flag := gv_flg_on;
--
      -- 請求運賃計算対象フラグ
      --ON(1)を設定する。
      lv_demand_freight_flag := gv_flg_on;
--
      -- 運送業者_実績ID
      -- IFの運送業者IDを設定する
      ln_result_freight_carrier_id := gr_interface_info_rec(in_idx).result_freight_carrier_id;
--
      -- 運送業者_実績
      -- IFの運送業者を設定する
      lv_result_freight_carrier_code := gr_interface_info_rec(in_idx).freight_carrier_code;
--
      -- 配送区分_実績
      -- IFの配送区分を設定する
      lv_result_shipping_method_code := gr_interface_info_rec(in_idx).shipping_method_code;
--
      -- 出荷日
      -- IFの出荷日を設定する
      ld_shipped_date := gr_interface_info_rec(in_idx).shipped_date;
--
      -- 着荷日
      -- IFの着荷日を設定する
      ld_arrival_date := gr_interface_info_rec(in_idx).arrival_date;
--
      -- 重量容積区分
      -- IFデータから取得した重量容積区分を設定する
      lv_weight_capacity_class := gr_interface_info_rec(in_idx).weight_capacity_class;
      -- 商品区分
      lv_prod_kbn_cd := gr_interface_info_rec(in_idx).prod_kbn_cd;
--
      -- 運賃形態
      -- 関数により取得
      get_freight_charge_type( lv_transaction_type      --   処理種別(配車)
                              ,lv_prod_kbn_cd           --   商品区分
                              ,ld_shipped_date          --   基準日(出荷日)
                              ,lv_delivery_no           --   配送No
                              ,lv_default_line_number   --   基準明細No(依頼No)
                              ,lv_freight_charge_type   --   運賃形態
                              ,lv_errbuf                --   エラー・メッセージ
                              ,lv_retcode               --   リターン・コード
                              ,lv_errmsg                --   ユーザー・エラー・メッセージ
                             );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      IF (lv_retcode = gv_status_warn) THEN
        gr_interface_info_rec(in_idx).logonly_flg := gv_flg_on;  -- ログのみ出力flag
        gr_interface_info_rec(in_idx).message     := lv_errmsg;  -- メッセージ(警告)
        ov_retcode := gv_status_warn;
      END IF;
--
      -- 配車配送計画アドオンに登録する
      INSERT INTO xxwsh_carriers_schedule
      (
         transaction_id                     -- トランザクションID
        ,transaction_type                   -- 処理種別(配車)
        ,mixed_type                         -- 混載種別
        ,delivery_no                        -- 配送No
        ,default_line_number                -- 基準明細No
        ,carrier_id                         -- 運送業者ID
        ,carrier_code                       -- 運送業者
        ,deliver_to_code_class              -- 配送先コード区分
        ,delivery_type                      -- 配送区分
        ,auto_process_type                  -- 自動配車対象区分
        ,schedule_ship_date                 -- 出庫予定日
        ,schedule_arrival_date              -- 着荷予定日
        ,payment_freight_flag               -- 支払運賃計算対象フラグ
        ,demand_freight_flag                -- 請求運賃計算対象フラグ
        ,result_freight_carrier_id          -- 運送業者_実績ID
        ,result_freight_carrier_code        -- 運送業者_実績
        ,result_shipping_method_code        -- 配送区分_実績
        ,shipped_date                       -- 出荷日
        ,arrival_date                       -- 着荷日
        ,weight_capacity_class              -- 重量容積区分
        ,freight_charge_type                -- 運賃形態
        ,created_by                         -- 作成者
        ,creation_date                      -- 作成日
        ,last_updated_by                    -- 最終更新者
        ,last_update_date                   -- 最終更新日
        ,last_update_login                  -- 最終更新ログイン
        ,request_id                         -- 要求ID
        ,program_application_id             -- アプリケーションID
        ,program_id                         -- コンカレント・プログラムID
        ,program_update_date                -- プログラム更新日
      )
      VALUES
      (
         xxwsh_careers_schedule_s1.NEXTVAL  -- トランザクションID
        ,lv_transaction_type                -- 処理種別(配車)
        ,lv_mixed_type                      -- 混載種別
        ,lv_delivery_no                     -- 配送No
        ,lv_default_line_number             -- 基準明細No
        ,ln_carrier_id                      -- 運送業者ID
        ,lv_carrier_code                    -- 運送業者
        ,lv_deliver_to_code_class           -- 配送先コード区分
        ,lv_delivery_type                   -- 配送区分
        ,lv_auto_process_type               -- 自動配車対象区分
        ,ld_schedule_ship_date              -- 出庫予定日
        ,ld_schedule_arrival_date           -- 着荷予定日
        ,lv_payment_freight_flag            -- 支払運賃計算対象フラグ
        ,lv_demand_freight_flag             -- 請求運賃計算対象フラグ
        ,ln_result_freight_carrier_id       -- 運送業者_実績ID
        ,lv_result_freight_carrier_code     -- 運送業者_実績
        ,lv_result_shipping_method_code     -- 配送区分_実績
        ,ld_shipped_date                    -- 出荷日
        ,ld_arrival_date                    -- 着荷日
        ,lv_weight_capacity_class           -- 重量容積区分
        ,lv_freight_charge_type             -- 運賃形態
        ,gt_user_id                         -- 作成者
        ,gt_sysdate                         -- 作成日
        ,gt_user_id                         -- 最終更新者
        ,gt_sysdate                         -- 最終更新日
        ,gt_login_id                        -- 最終更新ログイン
        ,gt_conc_request_id                 -- 要求ID
        ,gt_prog_appl_id                    -- アプリケーションID
        ,gt_conc_program_id                 -- コンカレント・プログラムID
        ,gt_sysdate                         -- プログラム更新日
      );
--
    ELSE
    -- 配車配送計画(アドオン)データが有る場合、更新する
--
      -- 出荷日
      -- IFの出荷日を設定する
      ld_shipped_date := gr_interface_info_rec(in_idx).shipped_date;
--
      -- 着荷日
      -- IFの着荷日を設定する
      ld_arrival_date := gr_interface_info_rec(in_idx).arrival_date;
--
      -- 運送業者_実績ID
      -- IFの運送業者IDを設定する
      ln_result_freight_carrier_id := gr_interface_info_rec(in_idx).result_freight_carrier_id;
--
      -- 運送業者_実績
      -- IFの運送業者を設定する
      lv_result_freight_carrier_code := gr_interface_info_rec(in_idx).freight_carrier_code;
--
      -- 配送区分_実績
      -- IFの配送区分を設定する
      lv_result_shipping_method_code := gr_interface_info_rec(in_idx).shipping_method_code;
--
      -- 配車配送計画アドオンに登録する
      UPDATE xxwsh_carriers_schedule
      SET shipped_date                = ld_shipped_date
         ,arrival_date                = ld_arrival_date
         ,result_freight_carrier_id   = ln_result_freight_carrier_id
         ,result_freight_carrier_code = lv_result_freight_carrier_code
         ,result_shipping_method_code = lv_result_shipping_method_code
         ,last_updated_by             = gt_user_id
         ,last_update_date            = gt_sysdate
         ,last_update_login           = gt_login_id
         ,request_id                  = gt_conc_request_id
         ,program_application_id      = gt_prog_appl_id
         ,program_id                  = gt_conc_program_id
         ,program_update_date         = gt_sysdate
      WHERE   delivery_no = gr_interface_info_rec(in_idx).delivery_no;
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
  END carriers_schedule_inup;
--
 /**********************************************************************************
  * Procedure Name   : mov_table_outpout
  * Description      : 移動依頼/指示アドオン出力 プロシージャ (A-7)
  ***********************************************************************************/
  PROCEDURE mov_table_outpout(
    in_idx        IN  NUMBER,              --   データindex
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_table_outpout'; -- プログラム名
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_data_cnt             NUMBER;                 -- 取得データ件数
--
    lb_line_upd_flg         BOOLEAN := FALSE;       -- 明細存在判定
    lb_lot_upd_flg          BOOLEAN := FALSE;       -- ロット存在判定フラグ
--
    lb_break_flg            BOOLEAN := FALSE;       -- ブレイク判定
    lb_header_warn          BOOLEAN := FALSE;       -- ヘッダ処理ワーニング
--
    ln_cnt_kbn              VARCHAR2(1);     -- データ件数カウント区分
--
    -- 実績計上済区分
    lt_actual_confirm_class xxwsh_order_headers_all.actual_confirm_class%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR mov_data_get_cur
      (
       in_delivery_no         xxwsh_shipping_headers_if.delivery_no%TYPE      -- 配送No
      ,in_order_source_ref    xxwsh_shipping_headers_if.order_source_ref%TYPE -- 受注ソース参照
      )
    IS
      SELECT  xmrif.mov_hdr_id                  -- 移動ヘッダID
              ,xmrif.delivery_no                -- 配送no
              ,xmrif.mov_num                    -- 移動番号
              ,xmrif.comp_actual_flg            -- 実績計上済フラグ
              ,xmrif.status                     -- ステータス
              ,xmrql.mov_line_id                -- 移動明細ID
              ,xmrql.item_code                  -- 品目
              ,xmrql.item_id                    -- opm品目ID
              ,xmld.mov_line_id                 -- ロット詳細の明細ID
              ,xmld.mov_lot_dtl_id              -- ロット詳細ID
              ,xmld.document_type_code          -- 文書タイプ
              ,xmld.record_type_code            -- レコードタイプ
              ,xmld.item_id                     -- opm品目ID
              ,xmld.lot_no                      -- ロットNo
      FROM    xxinv_mov_req_instr_headers xmrif    -- 移動依頼/指示ヘッダ(アドオン)
            , xxinv_mov_req_instr_lines   xmrql    -- 移動依頼/指示明細(アドオン)
            , xxinv_mov_lot_details       xmld     -- 移動ロット詳細(アドオン)
      WHERE   NVL(xmrif.delivery_no,gv_delivery_no_null) = NVL(in_delivery_no,gv_delivery_no_null) -- 配送No=配送No
      AND     xmrif.mov_num          = in_order_source_ref  -- 依頼No=受注ソース参照
      AND     xmrif.mov_hdr_id       = xmrql.mov_hdr_id     -- 移動ヘッダアドオンID=移動ヘッダアドオンID
      AND     xmrif.status          <> gv_mov_status_99     -- ステータス<>取消
      AND     ((xmrql.delete_flg     = gv_yesno_n)          -- 削除フラグ=未削除
       OR      (xmrql.delete_flg IS NULL))
      AND     xmrql.mov_line_id      = xmld.mov_line_id(+)  -- 移動明細アドオンID=明細ID
      ORDER BY
              xmrif.mov_hdr_id
              ,xmrql.mov_line_id
              ,xmld.mov_lot_dtl_id
    ;
--
    -- *** ローカル・レコード ***
    TYPE rec_data IS RECORD
      (
        mov_hdr_id         xxinv_mov_req_instr_headers.mov_hdr_id%TYPE      -- 移動ヘッダID
       ,delivery_no        xxinv_mov_req_instr_headers.delivery_no%TYPE     -- 配送no
       ,mov_num            xxinv_mov_req_instr_headers.mov_num%TYPE         -- 移動番号
       ,comp_actual_flg    xxinv_mov_req_instr_headers.comp_actual_flg%TYPE -- 実績計上済フラグ
       ,status             xxinv_mov_req_instr_headers.status%TYPE          -- ステータス
       ,mov_line_id        xxinv_mov_req_instr_lines.mov_line_id%TYPE       -- 移動明細ID
       ,item_code          xxinv_mov_req_instr_lines.item_code%TYPE         -- 品目
       ,lines_item_code    xxinv_mov_req_instr_lines.item_id%TYPE           -- 移動明細.opm品目ID
       ,lot_mov_line_id    xxinv_mov_lot_details.mov_line_id%TYPE           -- ロット詳細の明細ID
       ,mov_lot_dtl_id     xxinv_mov_lot_details.mov_lot_dtl_id%TYPE        -- ロット詳細ID
       ,document_type_code xxinv_mov_lot_details.document_type_code%TYPE    -- 文書タイプ
       ,record_type_code   xxinv_mov_lot_details.record_type_code%TYPE      -- レコードタイプ
       ,item_id            xxinv_mov_lot_details.item_id%TYPE               -- opm品目ID
       ,lot_no             xxinv_mov_lot_details.lot_no%TYPE                -- ロットNo
      );
    TYPE tab_data IS TABLE OF rec_data INDEX BY BINARY_INTEGER ;
--
    lr_tab_data              tab_data;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'【移動処理　開始】：' || in_idx || '件目');
debug_log(FND_FILE.LOG,'　　配送No：' || gr_interface_info_rec(in_idx).delivery_no);
debug_log(FND_FILE.LOG,'　　移動No：' || gr_interface_info_rec(in_idx).order_source_ref);
--********** debug_log ********** END   ***

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
    -- 件数初期化
    ln_data_cnt := 0;
    -------------------------------------------------------------------------
    -- 配送No、依頼Noに該当するデータを取得
    -------------------------------------------------------------------------
    -- カーソルオープン
    OPEN mov_data_get_cur
      (
        gr_interface_info_rec(in_idx).delivery_no
       ,gr_interface_info_rec(in_idx).order_source_ref
      );
--
    --フェッチ
    FETCH mov_data_get_cur BULK COLLECT INTO lr_tab_data;
--
    ln_data_cnt := mov_data_get_cur%ROWCOUNT;    -- カーソルレコード件数
--
    --クローズ
    CLOSE mov_data_get_cur;
--
    -------------------------------------------------------------------------
    -- 取得データより、移動依頼/指示ヘッダ(アドオン)、移動依頼/指示明細(アドオン)、
    -- 移動ロット詳細(アドオン)の登録・更新を行う
    --------------------------------------------------------------------------
    IF ((gr_interface_info_rec(in_idx).err_flg = gv_flg_off) AND         --エラーflag：0(正常)
        (gr_interface_info_rec(in_idx).reserve_flg = gv_flg_off))        --保留flag  ：0(正常)
    THEN
--
      IF (ln_data_cnt > 0 ) THEN
        -- 取得データが存在する場合
        lb_line_upd_flg    := FALSE;
        lb_lot_upd_flg     := FALSE;
--
        <<order_data_get_loop>>
        FOR i IN 1 .. ln_data_cnt LOOP
          -- 実績計上済区分退避
          lt_actual_confirm_class := lr_tab_data(i).comp_actual_flg;
--
--        ******-- 同一の品目が明細データに存在する場合
--        ******--IF (gr_interface_info_rec(in_idx).orderd_item_code = lr_tab_data(i).item_code) THEN
--
            -- 外部倉庫(指示なし)以外の場合
          IF (gb_mov_header_flg = FALSE) THEN
--
            --------------------------------------
            -- 移動依頼/指示ヘッダ(アドオン)の更新
            --------------------------------------
            -- ヘッダIDが同一でデータが1件目の場合(必ず読込データ1件目)
            IF (gb_mov_header_data_flg = FALSE) THEN
--
               -- 実績計上済区分＝'N'の場合
              IF (lr_tab_data(i).comp_actual_flg = gv_yesno_n) OR
                 (lr_tab_data(i).comp_actual_flg IS NULL) THEN
--
                 gb_mov_cnt_a7_flg := TRUE;      -- 移動(A-7) 件数表示で計上か訂正か判断するのためのフラグ
--
                -- 移動依頼/指示ヘッダアドオン  (A-7-2)実施
                mov_req_instr_head_upd(
                  in_idx,                   -- データindex
                  lr_tab_data(i).status,    -- ステータス
                  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
                  lv_retcode,               -- リターン・コード             --# 固定 #
                  lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
                 );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　移動依頼/指示ヘッダアドオン  (A-7-2)実施：mov_req_instr_head_upd');
--********** debug_log ********** END   ***
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
--
              ELSE -- 実績計上済区分＝'Y'
--
                  -- 移動依頼/指示ヘッダアドオン (A-7-3)実施
                mov_req_instr_head_inup(
                  in_idx,                   -- データindex
                  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
                  lv_retcode,               -- リターン・コード             --# 固定 #
                  lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　移動依頼/指示ヘッダアドオン (A-7-3)実施：mov_req_instr_head_inup');
--********** debug_log ********** END   ***
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
--
              END IF;
              gb_mov_header_data_flg := TRUE;  -- 移動依頼/指示ヘッダを処理済に設定
            END IF;
--
          END IF;
          -- 外部倉庫(指示なし)以外で、且つヘッダ登録・更新処理が正常終了の場合
          IF ((gb_mov_line_flg = FALSE) AND
             (lb_header_warn = FALSE))
          THEN
            --------------------------------------
            -- 移動依頼/指示明細(アドオン)の更新
            --------------------------------------
            -- 品目が同一、且つ明細データ未処理の場合
            IF ((gr_interface_info_rec(in_idx).orderd_item_code = lr_tab_data(i).item_code) AND
                (gb_mov_line_data_flg = FALSE))
            THEN
              -- 実績計上済区分が、'N'の場合
              IF (lr_tab_data(i).comp_actual_flg = gv_yesno_n) OR
                 (lr_tab_data(i).comp_actual_flg IS NULL) THEN
--
                -- 移動依頼/指示明細アドオン (A-7-5) 実施
                mov_req_instr_lines_upd(
                  in_idx,                     -- データindex
                  lr_tab_data(i).mov_line_id,  --移動明細ID
                  gv_cnt_kbn_1,               -- データ件数カウント区分
                  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
                  lv_retcode,               -- リターン・コード             --# 固定 #
                  lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　品目：' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'　　　移動依頼/指示明細アドオン (A-7-5) 実施：mov_req_instr_lines_upd');
--********** debug_log ********** END   ***
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
                lb_line_upd_flg  := TRUE; --移動依頼/指示明細が存在に設定
                gb_mov_line_data_flg := TRUE; --移動依頼/指示明細を処理済に設定
--
              ELSIF  (lt_actual_confirm_class = gv_yesno_y) THEN
--
                -- 移動依頼/指示明細アドオン (A-7-5) 実施
                mov_req_instr_lines_upd(
                  in_idx,                 -- データindex
                  lr_tab_data(i).mov_line_id,  --移動明細ID
                  gv_cnt_kbn_6,             -- データ件数カウント区分
                  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
                  lv_retcode,               -- リターン・コード             --# 固定 #
                  lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
                );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　品目：' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'　　　移動依頼/指示明細アドオン (A-7-5) 実施：mov_req_instr_lines_upd');
--********** debug_log ********** END   ***
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
                lb_line_upd_flg  := TRUE; --移動依頼/指示明細が存在に設定
                gb_mov_line_data_flg := TRUE; --移動依頼/指示明細データを処理済
              END IF;
--
            END IF;
--
          END IF;
--
          --------------------------------------
          -- 移動ロット詳細(アドオン)の更新
          --------------------------------------
          -- ヘッダ登録・更新処理が正常終了の場合
--********** 2008/06/27 ********** MODIFY START ***
--*         IF  (lt_actual_confirm_class = gv_yesno_y) AND
--*             (lb_header_warn = FALSE) THEN
          IF  (lb_header_warn = FALSE) THEN
--********** 2008/06/27 ********** MODIFY END   ***
--
            -- EOSデータ種別が、220:移動入庫確定報告の場合
            IF  (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) THEN
              -- 訂正ロットが存在する場合
              IF (((gr_interface_info_rec(in_idx).lot_no = lr_tab_data(i).lot_no) OR
                  (gr_interface_info_rec(in_idx).lot_no IS NULL)) AND
                  (gr_interface_info_rec(in_idx).item_id = lr_tab_data(i).item_id) AND
                  (lr_tab_data(i).document_type_code = gv_document_type_20) AND
                  (lr_tab_data(i).record_type_code = gv_record_type_20))
              THEN
--
--********** 2008/06/27 ********** DELETE START ***
--*             -- ロット管理品のみ移動ロット詳細UPDATE処理を行う
--*             IF  (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_1) 
--*             THEN
--********** 2008/06/27 ********** DELETE END   ***
--
                  -- 移動ロット詳細UPDATE プロシージャ (A-7-7) 実施
                  movlot_detail_upd(
                    in_idx,                         -- データindex
                    lr_tab_data(i).mov_lot_dtl_id,  --ロット詳細ID
                    lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
                    lv_retcode,                     -- リターン・コード             --# 固定 #
                    lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
                  );
--
--********** 2008/07/07 ********** DELETE START ***
--*--ZANTEI 2008/06/27 ADD START
--*                  IF (lt_actual_confirm_class <> gv_yesno_y) THEN
--*--
--*                    --ロット詳細新規作成件数(移動依頼_訂正ロットあり) 減算
--*                    gn_mov_mov_upd_y_cnt := gn_mov_mov_upd_y_cnt - 1;
--*--
--*                    --ロット詳細新規作成件数(移動依頼_実績計上) 加算
--*                    gn_mov_mov_ins_n_cnt := gn_mov_mov_ins_n_cnt + 1;
--*                  END IF;
--*--ZANTEI 2008/06/27 ADD END
--********** 2008/07/07 ********** DELETE END   ***
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　移動ロット詳細UPDATE プロシージャ (A-7-7) 実施：movlot_detail_upd');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
--********** 2008/06/27 ********** DELETE START ***
--*             END IF;
--********** 2008/06/27 ********** DELETE END   ***
--
                lb_lot_upd_flg := TRUE; --ロットデータを処理済に設定(ロット管理品外でも、訂正ロットが存在するので済に設定)
--
              END IF;
            -- EOSデータ種別が、230:移動入庫確定報告の場合
            ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
              -- 訂正ロットが存在する場合
              IF (((gr_interface_info_rec(in_idx).lot_no = lr_tab_data(i).lot_no) OR
                  (gr_interface_info_rec(in_idx).lot_no IS NULL)) AND
                  (gr_interface_info_rec(in_idx).item_id = lr_tab_data(i).item_id) AND
                  (lr_tab_data(i).document_type_code = gv_document_type_20) AND
                  (lr_tab_data(i).record_type_code = gv_record_type_30))
              THEN
--
--********** 2008/06/27 ********** DELETE START ***
--*             -- ロット管理品のみ移動ロット詳細UPDATE処理を行う
--*             IF  (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_1) 
--*             THEN
--********** 2008/06/27 ********** DELETE END   ***
--
                  -- 移動ロット詳細UPDATE プロシージャ (A-7-7) 実施
                  movlot_detail_upd(
                    in_idx,                         -- データindex
                    lr_tab_data(i).mov_lot_dtl_id,  -- ロット詳細ID
                    lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
                    lv_retcode,                     -- リターン・コード             --# 固定 #
                    lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
                  );
--
--********** 2008/07/07 ********** DELETE START ***
--*--ZANTEI 2008/06/27 ADD START
--*                  IF (lt_actual_confirm_class <> gv_yesno_y) THEN
--*--
--*                    --ロット詳細新規作成件数(移動依頼_訂正ロットあり) 減算
--*                    gn_mov_mov_upd_y_cnt := gn_mov_mov_upd_y_cnt - 1;
--*--
--*                    --ロット詳細新規作成件数(移動依頼_実績計上) 加算
--*                    gn_mov_mov_ins_n_cnt := gn_mov_mov_ins_n_cnt + 1;
--*                  END IF;
--*--ZANTEI 2008/06/27 ADD END
--********** 2008/07/07 ********** DELETE END   ***
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　移動ロット詳細UPDATE プロシージャ (A-7-7) 実施：movlot_detail_upd');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--

--********** 2008/06/27 ********** DELETE START ***
--*             END IF;
--********** 2008/06/27 ********** DELETE END   ***
--
                lb_lot_upd_flg := TRUE; --ロットデータを処理済に設定(ロット管理品外でも、訂正ロットが存在するので済に設定)
--
              END IF;
--
            END IF;
--
          END IF;
--
        END LOOP order_data_get_loop;
--
        --------------------------------------
        -- 移動依頼/指示明細(アドオン)の登録
        --------------------------------------
        -- ヘッダは存在するが、明細データ存在しない、且つヘッダ登録・更新処理が正常終了の場合
        IF ((gb_mov_line_flg = FALSE)     AND
           (lb_line_upd_flg = FALSE)      AND
           (gb_mov_line_data_flg = FALSE) AND
           (lb_header_warn = FALSE))
        THEN
          -- データ区分の判定
          IF (gb_mov_header_flg = TRUE)  THEN
             ln_cnt_kbn := gv_cnt_kbn_3; -- 外部倉庫(指示なし)
          ELSE
            IF (gb_mov_cnt_a7_flg = TRUE) THEN
               ln_cnt_kbn := gv_cnt_kbn_2; -- 実績計上の指示品目≠実績品目
            ELSE
               ln_cnt_kbn := gv_cnt_kbn_7; -- 訂正元品目なし
            END IF;
          END IF;
--
          -- 移動依頼/指示明細アドオン (A-7-4)実施 (INSERT)
          mov_req_instr_lines_ins(
            in_idx,                   -- データindex
            ln_cnt_kbn,               -- データ件数カウント区分
            lv_errbuf,                -- エラー・メッセージ           --# 固定 #
            lv_retcode,               -- リターン・コード             --# 固定 #
            lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　品目：' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'　　　移動依頼/指示明細アドオン (A-7-4)実施 (INSERT)：mov_req_instr_lines_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          gb_mov_line_flg  := TRUE;
          gb_mov_line_data_flg := TRUE;
        END IF;
--
        --------------------------------------
        -- 移動ロット詳細(アドオン)の登録
        --------------------------------------
        -- ヘッダ登録・更新処理が正常終了の場合
        IF ((lb_lot_upd_flg = FALSE) AND (lb_header_warn = FALSE)) THEN
--
           -- データ区分の判定を行う
          IF (gb_mov_header_flg = TRUE)  THEN
             ln_cnt_kbn := gv_cnt_kbn_3;  -- 外部倉庫(指示なし)
          ELSE
            IF (gb_mov_cnt_a7_flg = TRUE) THEN
               ln_cnt_kbn := gv_cnt_kbn_5;  -- 実績計上
            ELSE
               ln_cnt_kbn := gv_cnt_kbn_9;  -- 訂正ロットなし
            END IF;
          END IF;
--
          -- 移動依頼/指示データ移動ロット詳細 (A-7-6)実施(INSERT)
          mov_movlot_detail_ins(
            in_idx,                   -- データindex
            ln_cnt_kbn,               -- データ件数カウント区分
            lv_errbuf,                -- エラー・メッセージ           --# 固定 #
            lv_retcode,               -- リターン・コード             --# 固定 #
            lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　移動依頼/指示データ移動ロット詳細 (A-7-6)実施(INSERT)：mov_movlot_detail_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          IF gr_interface_info_rec(in_idx).freight_charge_class = gv_include_exclude_1 THEN
--
            -- 配車配送計画アドオン作成
            carriers_schedule_inup(
              in_idx,                   -- データindex
              lv_errbuf,                -- エラー・メッセージ           --# 固定 #
              lv_retcode,               -- リターン・コード             --# 固定 #
              lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　配車配送計画アドオン作成：carriers_schedule_inup');
--********** debug_log ********** END   ***
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            IF (lv_retcode = gv_status_warn) THEN
              ov_retcode := gv_status_warn;
            END IF;
--
          END IF;
--
        END IF;
--
      ELSE  --データが存在しない場合
        --------------------------------------
        -- 移動依頼/指示ヘッダ(アドオン)の登録
        --------------------------------------
--
        -- 移動依頼/指示ヘッダアドオン(外部倉庫編集) (A-7-1)実施(INSERT)
        mov_req_instr_head_ins(
          in_idx,                   -- データindex
          lv_errbuf,                -- エラー・メッセージ           --# 固定 #
          lv_retcode,               -- リターン・コード             --# 固定 #
          lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　移動依頼/指示ヘッダアドオン(外部倉庫編集) (A-7-1)実施(INSERT)：mov_req_instr_head_ins');
--********** debug_log ********** END   ***
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ヘッダ登録・更新処理が正常終了の場合
        IF (lb_header_warn = FALSE) THEN
          --------------------------------------
          -- 移動依頼/指示明細(アドオン)の登録
          --------------------------------------
          ln_cnt_kbn := gv_cnt_kbn_3; -- データ区分設定：外部倉庫(指示なし)
--
          -- 移動依頼/指示明細アドオン (A-7-4)実施(INSERT)
          mov_req_instr_lines_ins(
            in_idx,                   -- データindex
            ln_cnt_kbn,               -- データ件数カウント区分
            lv_errbuf,                -- エラー・メッセージ           --# 固定 #
            lv_retcode,               -- リターン・コード             --# 固定 #
            lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　品目：' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'　　　移動依頼/指示明細アドオン (A-7-4)実施(INSERT)：mov_req_instr_lines_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          --------------------------------------
          -- 移動ロット詳細(アドオン)の登録
          --------------------------------------
--
          -- 移動依頼/指示データ移動ロット詳細 (A-7-6)実施(INSERT)
          ln_cnt_kbn := gv_cnt_kbn_3;  -- データ区分設定：外部倉庫(指示なし)
          mov_movlot_detail_ins(
            in_idx,                   -- データindex
            ln_cnt_kbn,               -- データ件数カウント区分
            lv_errbuf,                -- エラー・メッセージ           --# 固定 #
            lv_retcode,               -- リターン・コード             --# 固定 #
            lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　移動依頼/指示データ移動ロット詳細 (A-7-6)実施(INSERT)：mov_movlot_detail_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          IF gr_interface_info_rec(in_idx).freight_charge_class = gv_include_exclude_1 THEN
--
            -- 配車配送計画アドオン作成
            carriers_schedule_inup(
              in_idx,                   -- データindex
              lv_errbuf,                -- エラー・メッセージ           --# 固定 #
              lv_retcode,               -- リターン・コード             --# 固定 #
              lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　配車配送計画アドオン作成：carriers_schedule_inup');
--********** debug_log ********** END   ***
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            IF (lv_retcode = gv_status_warn) THEN
              ov_retcode := gv_status_warn;
            END IF;
--
          END IF;
--
          gb_mov_header_flg  := TRUE;
          gb_mov_line_flg    := TRUE;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -------------------------------------------------------------------------
    -- 明細単位の処理
    -- 最終データ又は
    -- 前回の配送Noと前回の受注ソース参照と前回のEOSデータ種別が異なる場合(ヘッダブレイク)又は
    -- 前回の配送Noと前回の受注ソース参照と前回のEOSデータ種別が同一で品目が相違する場合
    --------------------------------------------------------------------------
    IF (in_idx = gn_target_cnt) THEN
        lb_break_flg := TRUE;
    ELSE
--
      IF ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) <> NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) OR
          (gr_interface_info_rec(in_idx).order_source_ref <> gr_interface_info_rec(in_idx + 1).order_source_ref) OR
          (gr_interface_info_rec(in_idx).eos_data_type <> gr_interface_info_rec(in_idx + 1).eos_data_type))
      OR
         ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) AND
          (gr_interface_info_rec(in_idx).order_source_ref = gr_interface_info_rec(in_idx + 1).order_source_ref) AND
          (gr_interface_info_rec(in_idx).eos_data_type = gr_interface_info_rec(in_idx + 1).eos_data_type) AND
          (gr_interface_info_rec(in_idx).orderd_item_code <> gr_interface_info_rec(in_idx + 1).orderd_item_code))
      THEN
--
        lb_break_flg := TRUE;
--
      END IF;
--
    END IF;
--
    IF ((lb_break_flg = TRUE) AND (lv_retcode = gv_status_normal)) THEN
      -- 出庫実績数量の設定を行う。
      -- ロット管理区分 = 1:有(ロット管理品)
      IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_1) THEN
--
        -- ===============================
        -- 出荷依頼実績数量の設定 プロシージャ
        -- ===============================
        mov_results_quantity_set(
          in_idx,                 -- データindex
          lv_errbuf,              -- エラー・メッセージ           --# 固定 #
          lv_retcode,             -- リターン・コード             --# 固定 #
          lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　出荷依頼実績数量の設定 プロシージャ：mov_results_quantity_set');
--********** debug_log ********** END   ***
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    IF (lb_break_flg = TRUE) THEN
      -- 処理制御変数を初期化
      gb_mov_line_data_flg := FALSE; -- 明細処理済判定
      lb_line_upd_flg      := FALSE; -- 明細存在判定
      lb_lot_upd_flg       := FALSE; -- ロット処理済判定判定
--
      gb_mov_line_flg      := FALSE; -- 外部倉庫(指示なし)判定 明細用
--
      lb_break_flg := FALSE;
--
    END IF;
    -------------------------------------------------------------------------
    -- ヘッダ単位の処理
    -- 前回の配送Noと前回の受注ソース参照と前回のEOSデータ種別が異なる場合(ヘッダブレイク)且つ 初回1件目以外の場合
    --------------------------------------------------------------------------
    IF (in_idx = gn_target_cnt) THEN
        lb_break_flg := TRUE;
--
    ELSE
--
      IF ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) <> NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) OR
          (gr_interface_info_rec(in_idx).order_source_ref <> gr_interface_info_rec(in_idx + 1).order_source_ref) OR
          (gr_interface_info_rec(in_idx).eos_data_type <> gr_interface_info_rec(in_idx + 1).eos_data_type))
      THEN
        lb_break_flg := TRUE;
--
      END IF;
--
    END IF;
--
    IF ((lb_break_flg = TRUE) AND (lv_retcode = gv_status_normal)) THEN
--
      IF ((gr_interface_info_rec(in_idx).err_flg = gv_flg_off) AND         --エラーflag：0(正常)
          (gr_interface_info_rec(in_idx).reserve_flg = gv_flg_off))        --保留flag  ：0(正常)
      THEN
--
        -- 重量容積小口個数更新関数を実施
        -- ===============================
        -- 重量容積小口個数設定 プロシージャ
        -- ===============================
        upd_line_items_set(
          in_idx,                   -- データindex
          lv_errbuf,                -- エラー・メッセージ           --# 固定 #
          lv_retcode,               -- リターン・コード             --# 固定 #
          lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    IF (lb_break_flg = TRUE) THEN
      -- 戻り値 = エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 処理制御変数を初期化
      gb_mov_header_data_flg   := FALSE; -- ヘッダ処理済判定
      gb_mov_line_data_flg     := FALSE; -- 明細処理済判定
      lb_line_upd_flg          := FALSE; -- 明細存在判定
      lb_lot_upd_flg           := FALSE; -- ロット処理済判定判定
      gb_mov_header_flg        := FALSE; -- 外部倉庫(指示なし)判定 ヘッダ用
      gb_mov_line_flg          := FALSE; -- 外部倉庫(指示なし)判定 明細用
      gb_mov_cnt_a7_flg        := FALSE; -- 移動(A-7) 件数表示で計上か訂正か判断するのためのフラグ
      lb_break_flg             := FALSE;
      gb_mov_cnt_a7_flg        := FALSE; -- 移動(A-7) 件数表示で計上か訂正か判断するのためのフラグ
--
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( mov_data_get_cur%ISOPEN ) THEN
        CLOSE mov_data_get_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( mov_data_get_cur%ISOPEN ) THEN
        CLOSE mov_data_get_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( mov_data_get_cur%ISOPEN ) THEN
        CLOSE mov_data_get_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END mov_table_outpout;
--
--
 /**********************************************************************************
  * Procedure Name   : order_table_outpout
  * Description      : 受注アドオン出力 プロシージャ (A-8)
  ***********************************************************************************/
  PROCEDURE order_table_outpout(
    in_idx        IN  NUMBER,              --   データindex
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_table_outpout'; -- プログラム名
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
    ln_data_cnt             NUMBER;                 -- 取得データ件数
--
    lb_line_upd_flg         BOOLEAN := FALSE;       -- 明細存在判定用
    lb_lot_upd_flg          BOOLEAN := FALSE;       -- ロット存在判定フラグ
--
    lb_break_flg            BOOLEAN := FALSE;       -- ブレイク判定
    lb_header_warn          BOOLEAN := FALSE;       -- ヘッダ処理ワーニング
--
    lv_document_type_code   VARCHAR2(2);            -- ドキュメントタイプ
--
    ln_cnt_kbn              VARCHAR2(1);   -- データ件数カウント区分
--
    -- 実績計上済区分
    lt_actual_confirm_class xxwsh_order_headers_all.actual_confirm_class%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR order_data_get_cur
      (
       in_delivery_no         xxwsh_shipping_headers_if.delivery_no%TYPE      -- 配送No
      ,in_order_source_ref    xxwsh_shipping_headers_if.order_source_ref%TYPE -- 受注ソース参照
      )
    IS
      SELECT  xoha.order_header_id              -- 受注ヘッダアドオンID
              ,xoha.delivery_no                 -- 配送no
              ,xoha.actual_confirm_class        -- 実績計上済フラグ
              ,xola.order_line_id               -- 受注明細アドオンID
              ,xola.shipping_item_code          -- 出荷品目
              ,xmld.mov_lot_dtl_id              -- ロット詳細ID
              ,xmld.document_type_code          -- 文書タイプ
              ,xmld.record_type_code            -- レコードタイプ
              ,xmld.item_id                     -- opm品目ID
              ,xmld.lot_no                      -- ロットNo
      FROM    xxwsh_order_headers_all   xoha    -- 受注ヘッダ(アドオン)
            , xxwsh_order_lines_all     xola    -- 受注明細(アドオン)
            , xxinv_mov_lot_details     xmld    -- 移動ロット詳細(アドオン)
      WHERE   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(in_delivery_no,gv_delivery_no_null)
      AND     xoha.request_no           = in_order_source_ref
      AND     xoha.order_header_id      = xola.order_header_id
      AND     xoha.latest_external_flag = gv_yesno_y
      AND     ((xola.delete_flag        = gv_yesno_n) OR (xola.delete_flag IS NULL))
      AND     xola.order_line_id        = xmld.mov_line_id(+)
      ORDER BY xoha.order_header_id
              ,xola.order_line_id
              ,xmld.mov_lot_dtl_id
    ;
--
    -- *** ローカル・レコード ***
    TYPE rec_data IS RECORD
      (
        order_header_id       xxwsh_order_headers_all.order_header_id%TYPE       -- 受注ヘッダアドオンID
       ,delivery_no           xxwsh_order_headers_all.delivery_no%TYPE           -- 配送no
       ,actual_confirm_class  xxwsh_order_headers_all.actual_confirm_class%TYPE  -- 実績計上済フラグ
       ,order_line_id         xxwsh_order_lines_all.order_line_id%TYPE           -- 受注明細アドオンID
       ,shipping_item_code    xxwsh_order_lines_all.shipping_item_code%TYPE      -- 出荷品目
       ,mov_lot_dtl_id        xxinv_mov_lot_details.mov_lot_dtl_id%TYPE          -- ロット詳細ID
       ,document_type_code    xxinv_mov_lot_details.document_type_code%TYPE      -- 文書タイプ
       ,record_type_code      xxinv_mov_lot_details.record_type_code%TYPE        -- レコードタイプ
       ,item_id               xxinv_mov_lot_details.item_id%TYPE                 -- opm品目ID
       ,lot_no                xxinv_mov_lot_details.lot_no%TYPE                  -- ロットNo
      );
--
    TYPE tab_data IS TABLE OF rec_data INDEX BY BINARY_INTEGER ;
--
    lr_tab_data               tab_data;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'【受注処理　開始】：' || in_idx || '件目');
debug_log(FND_FILE.LOG,'　　配送No：' || gr_interface_info_rec(in_idx).delivery_no);
debug_log(FND_FILE.LOG,'　　依頼No：' || gr_interface_info_rec(in_idx).order_source_ref);
--********** debug_log ********** END   ***
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
    ln_data_cnt := 0;
    -------------------------------------------------------------------------
    -- 配送No、依頼Noに該当するデータを取得
    -------------------------------------------------------------------------
    -- カーソルオープン
    OPEN order_data_get_cur
      (
        gr_interface_info_rec(in_idx).delivery_no
       ,gr_interface_info_rec(in_idx).order_source_ref
      );
--
    --フェッチ
    FETCH order_data_get_cur BULK COLLECT INTO lr_tab_data;
--
    --クローズ
    ln_data_cnt := order_data_get_cur%ROWCOUNT;    -- カーソルレコード件数
--
    CLOSE order_data_get_cur;
--
    -------------------------------------------------------------------------
    -- 取得データより、受注ヘッダ(アドオン)、受注明細(アドオン)、移動ロット詳細(アドオン)の
    -- 登録・更新を行う
    --------------------------------------------------------------------------
    IF ((gr_interface_info_rec(in_idx).err_flg = gv_flg_off) AND         --エラーflag：0(正常)
        (gr_interface_info_rec(in_idx).reserve_flg = gv_flg_off))        --保留flag  ：0(正常)
    THEN
--
      IF (ln_data_cnt > 0 ) THEN
        -- 取得データが存在する場合
        lb_line_upd_flg    := FALSE;
        lb_lot_upd_flg     := FALSE;
--
        <<order_data_get_loop>>
        FOR i IN 1 .. ln_data_cnt LOOP
          -- 実績計上済区分退避
          lt_actual_confirm_class := lr_tab_data(i).actual_confirm_class;
--
--        *****-- 同一の品目が受注明細データに存在する場合
--        *****  IF (gr_interface_info_rec(in_idx).orderd_item_code = lr_tab_data(i).shipping_item_code) THEN
--
            -- 外部倉庫(指示なし)以外の場合
            IF (gb_ord_header_flg = FALSE) THEN
--
              --------------------------------------
              -- 受注ヘッダ(アドオン)の更新
              --------------------------------------
              -- ヘッダIDが同一でデータが1件目の場合(必ず読込データ1件目)
              IF (gb_ord_header_data_flg = FALSE) THEN
--
                 -- 実績計上済区分＝'N' 又は NULLの場合
                IF  ((lr_tab_data(i).actual_confirm_class = gv_yesno_n) OR
                     (lr_tab_data(i).actual_confirm_class IS NULL))
                THEN
--
                  -- 受注(A-8-6) 件数表示で計上か訂正か判断するのためのフラグ
                  gb_ord_cnt_a8_flg := TRUE;
--
                  -- 受注ヘッダアドオン 実績計上 (A-8-1)実施 (UPDATE)
                  order_headers_upd(
                    in_idx,                   -- データindex
                    lv_errbuf,                -- エラー・メッセージ           --# 固定 #
                    lv_retcode,               -- リターン・コード             --# 固定 #
                    lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
                   );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　受注ヘッダアドオン 実績計上 (A-8-1)実施 (UPDATE)：order_headers_upd');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
                  gb_ord_header_data_flg := TRUE;  -- 受注ヘッダデータを処理済に設定
                ELSE -- 実績計上済区分＝'Y'
--
                  -- 受注ヘッダアドオン 実績訂正 (A-8-3,4)実施
                  order_headers_inup(
                    in_idx,                   -- データindex
                    lv_errbuf,                -- エラー・メッセージ           --# 固定 #
                    lv_retcode,               -- リターン・コード             --# 固定 #
                    lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
                  );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　受注ヘッダアドオン 実績訂正 (A-8-3,4)実施：order_headers_inup');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_warn) THEN
                    lb_header_warn := TRUE;
                    RAISE global_api_expt;
                  END IF;
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
                  gb_ord_header_data_flg := TRUE;  -- 受注ヘッダを処理済に設定
                END IF;
--
              END IF;
--
            END IF;
--
            -- 外部倉庫(指示なし)以外で、且つヘッダ登録・更新処理が正常終了の場合
            IF ((gb_ord_line_flg = FALSE) AND
                (lb_header_warn = FALSE))
            THEN
--
              --------------------------------------
              -- 受注明細(アドオン)の更新
              --------------------------------------
              -- 品目が同一、且つ明細データ未処理の場合
              IF ((gr_interface_info_rec(in_idx).orderd_item_code = lr_tab_data(i).shipping_item_code) AND
                  (gb_ord_line_data_flg = FALSE))
              THEN
                 -- 実績計上済区分＝'N' 又は NULLの場合
                IF  ((lr_tab_data(i).actual_confirm_class = gv_yesno_n) OR
                     (lr_tab_data(i).actual_confirm_class IS NULL))
                THEN
--
                  -- 受注明細アドオン 指示品目＝実績品目 (A-8-5)実施(UPDATE)
                  order_lines_upd(
                    in_idx,                       -- データindex
                    lr_tab_data(i).order_line_id, -- 受注明細アドオンID
                    lv_errbuf,                -- エラー・メッセージ           --# 固定 #
                    lv_retcode,               -- リターン・コード             --# 固定 #
                    lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
                  );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　品目：' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'　　　受注明細アドオン 指示品目＝実績品目 (A-8-5)実施(UPDATE)：order_lines_upd');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
                  lb_line_upd_flg  := TRUE; --受注明細が存在に設定
                  gb_ord_line_data_flg := TRUE; --受注明細を処理済に設定
--
                END IF;
--
--              *****END IF;
--
            END IF;
--
--********** 2008/06/27 ********** ADD    START ***
            --------------------------------------
            -- 移動ロット詳細(アドオン)の更新
            --------------------------------------
            -- ヘッダ登録・更新処理が正常終了の場合
            IF  (lb_header_warn = FALSE) THEN
--
                -- 実績計上済区分＝'N' 又は NULLの場合
              IF  ((lr_tab_data(i).actual_confirm_class = gv_yesno_n) OR
                   (lr_tab_data(i).actual_confirm_class IS NULL))
              THEN
--
                --文書タイプを設定
                -- EOSデータ種別 = 拠点出荷確定報告 又は 庭先出荷確定報告の場合
                lv_document_type_code := NULL;
--
                IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
                    (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
                THEN
--
                  lv_document_type_code := gv_document_type_10; --出荷依頼
--
                --  EOSデータ種別 = 200 有償出荷報告
                ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
                  lv_document_type_code := gv_document_type_30; --支給指示
--
                END IF;
--
                -- 訂正ロットが存在する場合
                IF (((gr_interface_info_rec(in_idx).lot_no = lr_tab_data(i).lot_no) OR
                    (gr_interface_info_rec(in_idx).lot_no IS NULL)) AND
                    (gr_interface_info_rec(in_idx).item_id = lr_tab_data(i).item_id) AND
                    (lr_tab_data(i).document_type_code = lv_document_type_code) AND
                    (lr_tab_data(i).record_type_code = gv_record_type_20))
                THEN
--
                  -- 受注データ移動ロット詳細UPDATE プロシージャ (A-8-8) 実施
                  order_movlot_detail_up(
                    in_idx,                         -- データindex
                    lr_tab_data(i).mov_lot_dtl_id,  -- ロット詳細ID
                    lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
                    lv_retcode,                     -- リターン・コード             --# 固定 #
                    lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
                  );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　受注データ移動ロット詳細UPDATE プロシージャ (A-8-8) 実施：order_movlot_detail_up');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
                  lb_lot_upd_flg := TRUE; --ロットデータを処理済に設定(ロット管理品外でも、訂正ロットが存在するので済に設定)
--
                END IF;
--
              END IF;
--
            END IF;
--********** 2008/06/27 ********** ADD    END   ***
--
          END IF;
--
        END LOOP order_data_get_loop;
--
        --------------------------------------
        -- 受注明細(アドオン)の登録
        --------------------------------------
        -- ヘッダは存在するが、明細データ存在しない、且つヘッダ登録・更新処理が正常終了の場合
        IF ((gb_ord_line_flg = FALSE)      AND
            (lb_line_upd_flg = FALSE)      AND
            (gb_ord_line_data_flg = FALSE) AND
            (lb_header_warn = FALSE))
        THEN
--
          -- データ区分の判定
          IF (gb_ord_header_flg = TRUE)  THEN
             ln_cnt_kbn := gv_cnt_kbn_3; -- 外部倉庫(指示なし)
          ELSE
            IF (gb_ord_cnt_a8_flg = TRUE) THEN
              ln_cnt_kbn := gv_cnt_kbn_2; -- 実績計上の指示品目≠実績品目
            ELSE
              ln_cnt_kbn := gv_cnt_kbn_4; -- 実績修正
            END IF;
          END IF;
--
          -- 受注明細アドオン 指示品目≠実績品目 (A-8-6)実施 (INSERT)
          order_lines_ins(
            in_idx,                                   -- データindex
            ln_cnt_kbn,                               -- データ件数カウント区分
            lv_errbuf,                                -- エラー・メッセージ           --# 固定 #
            lv_retcode,                               -- リターン・コード             --# 固定 #
            lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　品目：' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'　　　受注明細アドオン 指示品目≠実績品目 (A-8-6)実施 (INSERT)：order_lines_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          gb_ord_line_flg := TRUE;
          gb_ord_line_data_flg := TRUE;
        END IF;
--
        --------------------------------------
        -- 移動ロット詳細(アドオン)の登録
        --------------------------------------
        -- ヘッダ登録・更新処理が正常終了の場合
        IF ((lb_lot_upd_flg = FALSE) AND (lb_header_warn = FALSE)) THEN
--
          -- データ区分の判定
          IF (gb_ord_header_flg = TRUE)  THEN
             ln_cnt_kbn := gv_cnt_kbn_3; -- 外部倉庫(指示なし)
          ELSE
            IF (gb_ord_cnt_a8_flg = TRUE) THEN
              ln_cnt_kbn := gv_cnt_kbn_5; -- 実績計上
            ELSE
              ln_cnt_kbn := gv_cnt_kbn_4; -- 実績修正
            END IF;
          END IF;
--
          -- 受注データ移動ロット詳細 (A-8-7)実施(INSERT)
          order_movlot_detail_ins(
            in_idx,                 -- データindex
            ln_cnt_kbn,             -- データ件数カウント区分
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　受注データ移動ロット詳細 (A-8-7)実施(INSERT)：order_movlot_detail_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          IF gr_interface_info_rec(in_idx).freight_charge_class = gv_include_exclude_1 THEN
--
            -- 配車配送計画アドオン作成
            carriers_schedule_inup(
              in_idx,                   -- データindex
              lv_errbuf,                -- エラー・メッセージ           --# 固定 #
              lv_retcode,               -- リターン・コード             --# 固定 #
              lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　配車配送計画アドオン作成：carriers_schedule_inup');
--********** debug_log ********** END   ***
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            IF (lv_retcode = gv_status_warn) THEN
              ov_retcode := gv_status_warn;
            END IF;
--
          END IF;
--
        END IF;
--
      ELSE  --データが存在しない場合
--
        --------------------------------------
        -- 受注ヘッダ(アドオン)の登録
        --------------------------------------
        -- 受注ヘッダアドオン 外部倉庫(指示なし) (A-8-2)実施(INSERT)
        order_headers_ins(
          in_idx,                   -- データindex
          lv_errbuf,                -- エラー・メッセージ           --# 固定 #
          lv_retcode,               -- リターン・コード             --# 固定 #
          lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　受注ヘッダアドオン 外部倉庫(指示なし) (A-8-2)実施(INSERT)：order_headers_ins');
--********** debug_log ********** END   ***
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ヘッダ登録・更新処理が正常終了の場合
        IF (lb_header_warn = FALSE) THEN
          --------------------------------------
          -- 受注明細アドオン(アドオン)の登録
          --------------------------------------
          ln_cnt_kbn := gv_cnt_kbn_3; -- データ区分設定：外部倉庫(指示なし)
--
          -- 受注明細アドオン 実績修正 (A-8-6)実施(INSERT)
          order_lines_ins(
            in_idx,                   -- データindex
            ln_cnt_kbn,               -- データ件数カウント区分
            lv_errbuf,                -- エラー・メッセージ           --# 固定 #
            lv_retcode,               -- リターン・コード             --# 固定 #
            lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　品目：' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'　　　受注明細アドオン 実績修正 (A-8-6)実施(INSERT)：order_lines_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          --------------------------------------
          -- 移動ロット詳細(アドオン)の登録
          --------------------------------------
          -- 実績計上済区分にてデータ区分の判定
          ln_cnt_kbn := gv_cnt_kbn_3; -- 外部倉庫(指示なし)
--
          -- 受注データ移動ロット詳細 (A-8-7)実施(INSERT)
          order_movlot_detail_ins(
            in_idx,                   -- データindex
            ln_cnt_kbn,               -- データ件数カウント区分
            lv_errbuf,                -- エラー・メッセージ           --# 固定 #
            lv_retcode,               -- リターン・コード             --# 固定 #
            lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　受注データ移動ロット詳細 (A-8-7)実施(INSERT)：order_movlot_detail_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          IF gr_interface_info_rec(in_idx).freight_charge_class = gv_include_exclude_1 THEN
--
            -- 配車配送計画アドオン作成
            carriers_schedule_inup(
              in_idx,                   -- データindex
              lv_errbuf,                -- エラー・メッセージ           --# 固定 #
              lv_retcode,               -- リターン・コード             --# 固定 #
              lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　配車配送計画アドオン作成：carriers_schedule_inup');
--********** debug_log ********** END   ***
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            IF (lv_retcode = gv_status_warn) THEN
              ov_retcode := gv_status_warn;
            END IF;
--
          END IF;
--
          gb_ord_header_flg  := TRUE;
          gb_ord_line_flg    := TRUE;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -------------------------------------------------------------------------
    -- 明細単位の処理(次レコードと比較)
    -- 最終データ又は
    -- 配送Noと受注ソース参照が異なる場合(ヘッダブレイク)又は
    -- 配送Noと受注ソース参照が同一で受注品目が相違する場合
    --------------------------------------------------------------------------
--
    IF (in_idx = gn_target_cnt) THEN
        lb_break_flg := TRUE;
    ELSE
--
      IF ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) <> NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) OR
          (gr_interface_info_rec(in_idx).order_source_ref <> gr_interface_info_rec(in_idx + 1).order_source_ref))
      OR
         ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) AND
          (gr_interface_info_rec(in_idx).order_source_ref = gr_interface_info_rec(in_idx + 1).order_source_ref) AND
          (gr_interface_info_rec(in_idx).orderd_item_code <> gr_interface_info_rec(in_idx + 1).orderd_item_code))
      THEN
--
        lb_break_flg := TRUE;
--
      END IF;
--
    END IF;
--
    IF (lb_break_flg = TRUE) THEN
      -- 出庫実績数量の設定を行う。
      -- ロット管理区分 = 1:有(ロット管理品)
      IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_1)  THEN
--
        -- ===============================
        -- 受注実績数量の設定 プロシージャ
        -- ===============================
        ord_results_quantity_set(
          in_idx,                 -- データindex
          lv_errbuf,              -- エラー・メッセージ           --# 固定 #
          lv_retcode,             -- リターン・コード             --# 固定 #
          lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'　　　受注実績数量の設定 プロシージャ：ord_results_quantity_set');
--********** debug_log ********** END   ***
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- 処理制御変数を初期化
      gb_ord_line_data_flg     := FALSE; -- 明細処理済判定
      lb_line_upd_flg      := FALSE; -- 明細存在判定
      lb_lot_upd_flg       := FALSE; -- ロット処理済判定判定
--
      gb_ord_line_flg      := FALSE; -- 受注(A-8) 外部倉庫(指示なし)判定 明細用
--
      lb_break_flg         := FALSE;
--
    END IF;
    -------------------------------------------------------------------------
    -- ヘッダ単位の処理(次レコードと比較)
    -- 最終データ又は
    -- 配送Noと受注ソース参照が異なる場合(ヘッダブレイク)
    --------------------------------------------------------------------------
    IF (in_idx = gn_target_cnt) THEN
        lb_break_flg := TRUE;
--
    ELSE
--
      IF ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) <> NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) OR
         (gr_interface_info_rec(in_idx).order_source_ref <> gr_interface_info_rec(in_idx + 1).order_source_ref))
      THEN
        lb_break_flg := TRUE;
--
      END IF;
--
    END IF;
--
    IF ((lb_break_flg = TRUE) AND (lv_retcode = gv_status_normal)) THEN
--
      IF ((gr_interface_info_rec(in_idx).err_flg = gv_flg_off) AND         --エラーflag：0(正常)
          (gr_interface_info_rec(in_idx).reserve_flg = gv_flg_off))        --保留flag  ：0(正常)
      THEN
--
        -- 重量容積小口個数更新関数を実施
        -- ===============================
        -- 重量容積小口個数設定 プロシージャ
        -- ===============================
        upd_line_items_set(
          in_idx,                   -- データindex
          lv_errbuf,                -- エラー・メッセージ           --# 固定 #
          lv_retcode,               -- リターン・コード             --# 固定 #
          lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    IF (lb_break_flg = TRUE) THEN
      -- 戻り値 = エラーの場合
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 処理制御変数を初期化
      gb_ord_header_data_flg   := FALSE; -- ヘッダ処理済判定
      gb_ord_line_data_flg     := FALSE; -- 明細処理済判定
      lb_line_upd_flg      := FALSE; -- 明細存在判定
      lb_lot_upd_flg       := FALSE; -- ロット処理済判定判定
      gb_ord_header_flg    := FALSE; -- 外部倉庫(指示なし)判定 ヘッダ用
      gb_ord_line_flg      := FALSE; -- 外部倉庫(指示なし)判定 明細用
      lb_break_flg         := FALSE;
      gb_ord_cnt_a8_flg    := FALSE;      -- 受注(A-8) 件数表示で計上か訂正か判断するのためのフラグ
--
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( order_data_get_cur%ISOPEN ) THEN
        CLOSE order_data_get_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( order_data_get_cur%ISOPEN ) THEN
        CLOSE order_data_get_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END order_table_outpout;
--
 /**********************************************************************************
  * Procedure Name   : origin_record_delete
  * Description      : 抽出元レコード削除 プロシージャ (A-11)
  ***********************************************************************************/
  PROCEDURE origin_record_delete(
    in_idx        IN  NUMBER,              --   データindex
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'origin_record_delete'; -- プログラム名
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
    ln_count NUMBER;
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
    -- 正常レコードに対して出荷依頼IFヘッダ及び明細から対象データの削除を行う
--
    -- IF明細削除処理
    DELETE FROM xxwsh_shipping_lines_if   xsli
     WHERE xsli.line_id = gr_interface_info_rec(in_idx).line_id;
--
    -- 紐づくIF明細データが存在しない場合、IFヘッダの削除を行う。
--
    -- IFヘッダ削除処理
--
    -- IF明細存在チェックを行う。
    SELECT COUNT(xsli.line_id) cnt
    INTO   ln_count
    FROM   xxwsh_shipping_lines_if   xsli
    WHERE  xsli.header_id = gr_interface_info_rec(in_idx).header_id
    ;
    -- 存在しない場合は、紐づくIFヘッダの削除を行う。
    IF (ln_count = 0) THEN
--
      DELETE FROM xxwsh_shipping_headers_if xshi   --IF_H
      WHERE xshi.header_id = gr_interface_info_rec(in_idx).header_id;
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
  END origin_record_delete;
--
 /**********************************************************************************
  * Procedure Name   : lot_reversal_prevention_check
  * Description      : ロット逆転防止チェック プロシージャ (A-9)
  ***********************************************************************************/
  PROCEDURE lot_reversal_prevention_check(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lot_reversal_prevention_check'; -- プログラム名
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
    ln_party_site_id        NUMBER;                                          --パーティサイトID
    lv_error_flg            VARCHAR2(1);                                     --エラーflag
    lv_reserve_flg          VARCHAR2(1);                                     --保留flag
    lt_delivery_no          xxwsh_shipping_headers_if.delivery_no%TYPE;      --IF_H.配送No
    lt_order_source_ref     xxwsh_shipping_headers_if.order_source_ref%TYPE; --IF_H.受注ソース参照
    ln_inventory_location_id  mtl_item_locations.inventory_location_id%TYPE;
    iv_lot_biz_class        VARCHAR2(1);
    iv_item_no              xxcmn_item_mst_v.item_no%TYPE;
    iv_lot_no               ic_lots_mst.lot_no%TYPE;
    iv_move_to_id           xxcmn_party_sites2_v.party_site_id%TYPE;
    in_move_to_code         NUMBER;
    id_arrival_date         DATE;
    id_standard_date        DATE;
    on_result               NUMBER;
    on_reversal_date        DATE;
    lv_msg_buff             VARCHAR2(5000);
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
    -- ロット逆転防止チェック
    <<lot_reversal_prevention_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      lv_error_flg        := gr_interface_info_rec(i).err_flg;                  --エラーフラグ
      lv_reserve_flg      := gr_interface_info_rec(i).reserve_flg;              --保留フラグ
      lt_delivery_no      := gr_interface_info_rec(i).delivery_no;              --配送No
      lt_order_source_ref := gr_interface_info_rec(i).order_source_ref;         --受注ソース参照
--
      IF (lv_error_flg = '0') AND (lv_reserve_flg = '0') THEN
--
        -- ロット管理品で、EOSデータ種別が「有償出荷報告」以外のものを対象とする
        IF ((gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1) AND
            (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5) AND
            (gr_interface_info_rec(i).eos_data_type <> gv_eos_data_cd_200))
        THEN
--
          IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210)  OR
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215))
          THEN
--
            -- 出荷の実績計上時のチェック
            iv_lot_biz_class := gv_lot_biz_class_2;        -- 1.ロット逆転処理種別
            ln_party_site_id := gr_interface_info_rec(i).deliver_to_id;
            iv_move_to_id    := ln_party_site_id;          -- 4.配送先ID/取引先サイトID/入庫先ID
            in_move_to_code  := gr_interface_info_rec(i).party_site_code;
--
          ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220)  OR
                (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230))
          THEN
--
            -- 移動の実績計上時のチェック
            iv_lot_biz_class := gv_lot_biz_class_6;        -- 1.ロット逆転処理種別
--
            IF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220) THEN
--
              SELECT xilv2.inventory_location_id
              INTO   ln_inventory_location_id
              FROM   xxcmn_item_locations2_v xilv2
              WHERE  xilv2.segment1 = gr_interface_info_rec(i).ship_to_location
                AND  xilv2.date_from  <=  TRUNC(gr_interface_info_rec(i).shipped_date) -- 組織有効開始日
                AND  ((xilv2.date_to IS NULL)
                 OR  (xilv2.date_to >= TRUNC(gr_interface_info_rec(i).shipped_date)))  -- 組織有効終了日
                AND  xilv2.disable_date  IS NULL   -- 無効日
                  ;
--
            ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
              SELECT xilv2.inventory_location_id
              INTO   ln_inventory_location_id
              FROM   xxcmn_item_locations2_v xilv2
              WHERE  xilv2.segment1 = gr_interface_info_rec(i).ship_to_location
                AND  xilv2.date_from  <=  TRUNC(gr_interface_info_rec(i).arrival_date) -- 組織有効開始日
                AND  ((xilv2.date_to IS NULL)
                 OR  (xilv2.date_to >= TRUNC(gr_interface_info_rec(i).arrival_date)))  -- 組織有効終了日
                AND  xilv2.disable_date  IS NULL   -- 無効日
                  ;
--
            END IF;
--
            iv_move_to_id    := ln_inventory_location_id;     -- 4.配送先ID/取引先サイトID/入庫先ID
            in_move_to_code  := gr_interface_info_rec(i).ship_to_location;
--
          END IF;
--
          iv_item_no        := gr_interface_info_rec(i).orderd_item_code; -- 2.品目コード
          iv_lot_no         := gr_interface_info_rec(i).lot_no;           -- 3.ロットNo
          id_arrival_date   := gr_interface_info_rec(i).arrival_date;     -- 5.着日
          id_standard_date  := SYSDATE;                                   -- 6.基準日(適用日基準日)
--
          xxwsh_common910_pkg.check_lot_reversal(iv_lot_biz_class,        -- 1.ロット逆転処理種別
                                                 iv_item_no,              -- 2.品目コード
                                                 iv_lot_no,               -- 3.ロットNo
                                                 iv_move_to_id,           -- 4.配送先ID/取引先サイトID/入庫先ID
                                                 id_arrival_date,         -- 5.着日
                                                 id_standard_date,        -- 6.基準日(適用日基準日)
                                                 ov_retcode,              -- 7.リターンコード
                                                 lv_retcode,              -- 8.エラーメッセージコード
                                                 lv_errbuf,               -- 9.エラーメッセージ
                                                 on_result,               -- 10.処理結果
                                                 on_reversal_date);       -- 11.逆転日付
--
          IF (ov_retcode = 1) THEN
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                gv_msg_kbn              -- 'XXWSH'
                               ,gv_msg_93a_027          -- ロット逆転防止チェック処理エラーメッセージ
                               ,gv_err_code_token
                               ,lv_retcode              -- エラーメッセージコード
                               ,gv_err_msg_token
                               ,lv_errbuf               -- エラーメッセージ
                               )
                               ,1
                               ,5000);
--
            -- 配送No/依頼No-EOSデータ種別単位にエラーflagセット
            set_header_unit_reserveflg(
              lt_delivery_no,                     -- 配送No
              lt_order_source_ref,                -- 移動No/依頼No
              gr_interface_info_rec(i).eos_data_type, -- EOSデータ種別
              gv_logonly_class,                   -- エラー種別：ログのみ出力
              lv_msg_buff,                        -- エラー・メッセージ(出力用)
              lv_errbuf,                          -- エラー・メッセージ           --# 固定 #
              lv_retcode,                         -- リターン・コード             --# 固定 #
              lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
          IF ((ov_retcode = 0) AND (on_result = 1)) THEN
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                gv_msg_kbn              -- 'XXWSH'
                               ,gv_msg_93a_026          -- ロット逆転防止チェックエラーメッセージ
                               ,gv_param1_token
                               ,iv_lot_biz_class
                               ,gv_param2_token
                               ,iv_item_no
                               ,gv_param3_token
                               ,iv_lot_no
                               ,gv_param4_token
                               ,in_move_to_code
                               ,gv_param5_token
                               ,gr_interface_info_rec(i).delivery_no
                               ,gv_param6_token
                               ,gr_interface_info_rec(i).order_source_ref
                               )
                               ,1
                               ,5000);
--
            -- 配送NO-EOSデータ種別単位にエラーflagセット
            set_header_unit_reserveflg(
              lt_delivery_no,                     -- 配送No
              lt_order_source_ref,                -- 移動No/依頼No
              gr_interface_info_rec(i).eos_data_type, -- EOSデータ種別
              gv_logonly_class,                   -- エラー種別：ログのみ出力
              lv_msg_buff,                        -- エラー・メッセージ(出力用)
              lv_errbuf,                          -- エラー・メッセージ           --# 固定 #
              lv_retcode,                         -- リターン・コード             --# 固定 #
              lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP lot_reversal_prevention_loop;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END lot_reversal_prevention_check;
--
 /**********************************************************************************
  * Procedure Name   : drawing_enable_check
  * Description      : 引当可能チェック プロシージャ (A-10)
  ***********************************************************************************/
  PROCEDURE drawing_enable_check(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'drawing_enable_check'; -- プログラム名
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
    lt_inventory_location_id     xxcmn_item_locations_v.inventory_location_id%TYPE; --OPM保管倉庫ID
    ln_act_date_hikiate          NUMBER;     -- 有効日ベース引当可能数
    ln_act_total_hikiate         NUMBER;     -- 総引当可能数
    ln_act_hikiate               NUMBER;     -- 引当可能数
    ln_shiped_quantity           NUMBER;     -- 出荷実績数
    lv_msg_buff                  VARCHAR2(5000);
--
    lv_error_flg                 VARCHAR2(1);                                     --エラーflag
    lv_reserve_flg               VARCHAR2(1);                                     --保留flag
    lt_delivery_no               xxwsh_shipping_headers_if.delivery_no%TYPE;      --IF_H.配送No
    lt_order_source_ref          xxwsh_shipping_headers_if.order_source_ref%TYPE; --IF_H.受注ソース参照
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
    -- 変数初期化
    ln_act_date_hikiate      := 0;    -- 有効日ベース引当可能数
    ln_act_total_hikiate     := 0;    -- 総引当可能数
    ln_act_hikiate           := 0;    -- 引当可能数
    ln_shiped_quantity       := 0;    -- 出荷実績数
--
     <<status_update_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      lv_error_flg        := gr_interface_info_rec(i).err_flg;                  --エラーフラグ
      lv_reserve_flg      := gr_interface_info_rec(i).reserve_flg;              --保留フラグ
      lt_delivery_no      := gr_interface_info_rec(i).delivery_no;              --配送No
      lt_order_source_ref := gr_interface_info_rec(i).order_source_ref;         --受注ソース参照
--
      IF (lv_error_flg = '0') AND (lv_reserve_flg = '0') THEN
--
        -- EOSデータ種別 <> 230:移動入庫確定報告
        IF (gr_interface_info_rec(i).eos_data_type <> gv_eos_data_cd_230)
        THEN
--
          --共通関数：有効日ベース引当可能数算出API
          ln_act_date_hikiate := xxcmn_common_pkg.get_can_enc_in_time_qty(
                                 gr_interface_info_rec(i).shipped_locat  -- OPM保管倉庫ID
                               , gr_interface_info_rec(i).item_id        -- OPM品目ID
                               , gr_interface_info_rec(i).lot_id         -- ロットID
                               , gd_sysdate );                           -- 有効日
--
          -- 総引当可能数取得--
          -- 共通関数：総引当可能数算出API
          ln_act_total_hikiate := xxcmn_common_pkg.get_can_enc_total_qty(
                                  gr_interface_info_rec(i).shipped_locat  -- OPM保管倉庫ID
                                , gr_interface_info_rec(i).item_id        -- OPM品目ID
                                , gr_interface_info_rec(i).lot_id);       -- ロットID
--
          -- 総引当可能数と有効日ベース引当可能数のうち小さい方を訂正可能数とする
          ln_act_hikiate := LEAST( ln_act_date_hikiate, ln_act_total_hikiate );
--
          -- 引当可能数と比較する出荷実績数量を算出
          -- ロット管理区分の判定
          IF (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_0)
          THEN
            --ロット管理外の場合、出荷実績数量を使用
            ln_shiped_quantity := gr_interface_info_rec(i).shiped_quantity;
          ELSE
            --ロット管理の場合、内訳数量を使用
            ln_shiped_quantity := gr_interface_info_rec(i).detailed_quantity;
          END IF;
--
          -- 引当可能数 < 出荷実績数量の場合、警告として、ステータスを保留にする。
          IF (ln_act_hikiate < ln_shiped_quantity) THEN
--
            -- 警告メッセージ出力
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn          -- 'XXWSH'
                          ,gv_msg_93a_028                         -- 引当可能チェックエラーメッセージ
                          ,gv_param1_token
                          ,lt_delivery_no                             -- 配送No
                          ,gv_param2_token
                          ,lt_order_source_ref                        -- 受注ソース参照
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).item_no           -- 品目
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).lot_no            -- ロットNo
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code     -- 出荷元
                          ,gv_param6_token
                          ,ln_act_hikiate                             -- 引当可能数
                          ,gv_param7_token
                          ,ln_shiped_quantity                         -- 出荷実績数量
                          )
                          ,1
                          ,5000);
--
            -- ステータスを保留
            --配送No/依頼No-EOSデータ種別単位にエラーflagセット
            set_header_unit_reserveflg(
                                       lt_delivery_no,       -- 配送No
                                       lt_order_source_ref,  -- 移動No/依頼No
                                       gr_interface_info_rec(i).eos_data_type, -- EOSデータ種別
                                       gv_logonly_class,     -- エラー種別：ログのみ出力
                                       lv_msg_buff,        -- エラー・メッセージ(出力用)
                                       lv_errbuf,          -- エラー・メッセージ           --# 固定 #
                                       lv_retcode,         -- リターン・コード             --# 固定 #
                                       lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
                                        );
--
            -- 処理ステータス：警告
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP status_update_loop;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END drawing_enable_check;
--
 /**********************************************************************************
  * Procedure Name   : status_update
  * Description      :ステータス更新 プロシージャ (A-12)
  ***********************************************************************************/
  PROCEDURE status_update(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'status_update'; -- プログラム名
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
    ln_cnt  NUMBER := 0;
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
     <<status_update_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      -- 妥当性チェックの結果、受注ソース参照に紐づく保留ステータスの結合条件を元に
      -- 各保留レベルに応じてPL/SQL表の更新を行います。
      IF (gr_interface_info_rec(i).reserve_flg = gv_flg_on) THEN
        ln_cnt := ln_cnt + 1;
        gr_line_id_upd(ln_cnt)           := gr_interface_info_rec(i).line_id;     -- 明細ID
        gr_reserv_sts(ln_cnt)            := gv_reserved_status;   --保留ステータス = 1:保留
      END IF;
--
    END LOOP status_update_loop;
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
  END status_update;
--
 /**********************************************************************************
  * Procedure Name   : err_check_delete
  * Description      : エラー発生レベルによりレコード削除プロシージャ (A-13)
  ***********************************************************************************/
  PROCEDURE err_check_delete(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_check_delete'; -- プログラム名
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
    ln_head_cnt  NUMBER := 0;
    ln_line_cnt  NUMBER := 0;
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
    <<err_check_delete_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      -- 妥当性チェックの結果、受注ソース参照に紐づく保留ステータスの結合条件を元に
      -- 各保留レベルに応じてPL/SQL表の更新を行います。
      IF (gr_interface_info_rec(i).err_flg = gv_flg_on) THEN
--
        IF (i < gr_interface_info_rec.COUNT) THEN
--
          IF (gr_interface_info_rec(i).header_id <> gr_interface_info_rec(i+1).header_id) THEN
            ln_head_cnt := ln_head_cnt + 1;
            gr_header_id_del(ln_head_cnt) := gr_interface_info_rec(i).header_id;
          END IF;
--
        ELSE
          ln_head_cnt := ln_head_cnt + 1;
          gr_header_id_del(ln_head_cnt) := gr_interface_info_rec(i).header_id;
        END IF;
--
        ln_line_cnt := ln_line_cnt + 1;
        gr_line_id_del(ln_line_cnt) := gr_interface_info_rec(i).line_id;
      END IF;
--
    END LOOP err_check_delete_loop;
--
  EXCEPTION
--
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
  END err_check_delete;
--
 /**********************************************************************************
  * Procedure Name   : err_output
  * Description      : エラー内容出力プロシージャ (A-14)
  ***********************************************************************************/
  PROCEDURE err_output(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_output'; -- プログラム名
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
    lv_dspbuf     VARCHAR2(5000);     -- データ・ダンプ
    lv_dspmsg     VARCHAR2(5000);     -- エラー・メッセージ
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
    <<disp_report_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      IF (gr_interface_info_rec(i).err_flg     = gv_flg_on)
      OR (gr_interface_info_rec(i).reserve_flg = gv_flg_on)
      OR (gr_interface_info_rec(i).logonly_flg = gv_flg_on) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
        lv_dspbuf := '';
        lv_dspbuf := gr_interface_info_rec(i).party_site_code                         || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).freight_carrier_code       || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).shipping_method_code       || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).cust_po_number             || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).order_source_ref           || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).delivery_no                || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).collected_pallet_qty       || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).location_code              || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).arrival_time_from          || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).arrival_time_to            || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).eos_data_type              || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).ship_to_location           || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD') || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD') || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).order_type                 || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).used_pallet_qty            || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).report_post_code           || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).header_id                  || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).line_id                    || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).line_number                || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).orderd_item_code           || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).shiped_quantity            || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).ship_to_quantity           || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).lot_no                     || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD') || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD') || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).original_character         || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).detailed_quantity          || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).item_kbn_cd                || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).prod_kbn_cd                || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).weight_capacity_class      || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).lot_ctl;
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        lv_dspmsg := gr_interface_info_rec(i).message;
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspmsg);
--
      END IF;
--
    END LOOP disp_report_loop;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END err_output;
--
 /**********************************************************************************
  * Procedure Name   : ins_upd_del_processing
  * Description      : 登録更新削除処理プロシージャ (A-15)
  ***********************************************************************************/
  PROCEDURE ins_upd_del_processing(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_del_processing'; -- プログラム名
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
    In_not_cnt          NUMBER;                            -- IFヘッダ削除データ格納用カウント
    ln_count            NUMBER;                            -- IF明細存在データ件数格納
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
    -- 変数の初期化
    In_not_cnt  := 0;                          -- IFヘッダ削除データ格納用カウント
    gr_line_not_header.delete;
--
    -- ========================================
    -- 出荷IFテーブル(アドオン)  ステータス更新
    -- ========================================
--
    <<upd_sli_lot_loop>>
    FORALL i IN 1 .. gr_line_id_upd.COUNT
      UPDATE
        xxwsh_shipping_lines_if    xsli     -- 出荷依頼インタフェース明細(アドオン)
      SET
         xsli.reserved_status        = gr_reserv_sts(i)              -- 保留ステータス
        ,xsli.last_updated_by        = gt_user_id                    -- 最終更新者
        ,xsli.last_update_date       = gt_sysdate                    -- 最終更新日
        ,xsli.last_update_login      = gt_login_id                   -- 最終更新ログイン
        ,xsli.request_id             = gt_conc_request_id            -- 要求ID
        ,xsli.program_application_id = gt_prog_appl_id               -- アプリケーションID
        ,xsli.program_id             = gt_conc_program_id            -- コンカレント・プログラムID
        ,xsli.program_update_date    = gt_sysdate                    -- プログラム更新日
      WHERE
         xsli.line_id                = gr_line_id_upd(i);            -- 明細ID
--
    -- 訂正移動作成件数のセット
    gn_warn_cnt := gr_line_id_upd.COUNT;
--
    -- ==============================================
    -- 出荷IFテーブル(アドオン)  エラー発生データ削除
    -- ==============================================
--
     -- 出荷依頼インタフェース明細(アドオン)
    <<if_l_data_delete_loop>>
    FORALL i IN 1 .. gr_line_id_del.COUNT
--
      DELETE FROM xxwsh_shipping_lines_if   xsli
      WHERE xsli.line_id = gr_line_id_del(i);
--
    gn_del_errdata_cnt := gn_del_errdata_cnt + gr_line_id_del.COUNT;  -- 削除件数加算
--
     -- IFヘッダIDに紐づくIF明細データが存在するか否かの確認を行う。
     -- 存在しない場合、削除対象とする。
    <<if_ifm_not_loop>>
    FOR i IN 1 .. gr_header_id_del.COUNT LOOP
--
      -- IF明細存在チェックを行う。
      SELECT COUNT(xsli.line_id) cnt
      INTO   ln_count
      FROM   xxwsh_shipping_lines_if   xsli
      WHERE  xsli.header_id =  gr_header_id_del(i)
      ;
      -- 存在しない場合は、IFヘッダを削除対象し、削除データ格納領域に格納する。
      IF (ln_count = 0) THEN
        In_not_cnt :=In_not_cnt + 1;
        gr_line_not_header(In_not_cnt) := gr_header_id_del(i);
      END IF;
--
    END LOOP if_ifm_not_loop;
--
     -- 出荷依頼インタフェースヘッダ(アドオン)データ削除
    <<if_h_data_delete_loop>>
    FORALL i IN 1 .. gr_line_not_header.COUNT
--
      DELETE FROM xxwsh_shipping_headers_if xshi  --IF_H
      WHERE xshi.header_id = gr_line_not_header(i);
--
--********** 2008/07/07 ********** DELETE START ***
--* gn_del_errdata_cnt := gn_del_errdata_cnt + gr_line_not_header.COUNT;  -- 削除件数加算
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END ins_upd_del_processing;
--
 /**********************************************************************************
  * Procedure Name   : ship_results_regist_process
  * Description      : 出荷実績登録処理プロシージャ (A-16)
  ***********************************************************************************/
  PROCEDURE ship_results_regist_process(
    iv_object_warehouse     IN  VARCHAR2,            -- 対象倉庫
    ov_errbuf               OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ship_results_regist_process'; -- プログラム名
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
    cv_pkg_name             CONSTANT VARCHAR2(20) := 'xxwsh420001c' ;   -- パッケージ名
--
    -- *** ローカル変数 ***
    ln_req_id               NUMBER ;
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
    -- 出荷依頼出荷実績作成処理の呼び出しを行う。
    ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                  application       => gv_msg_kbn           -- アプリケーション短縮名
                 ,program           => cv_pkg_name          -- プログラム名
                 ,argument1         => NULL                 -- パラメータ０１(ブロック)
                 ,argument2         => iv_object_warehouse  -- パラメータ０２(出荷元)
                 ,argument3         => NULL                 -- パラメータ０３(依頼No)
                 );
--
    -- エラーの場合
    IF (ln_req_id = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
	                gv_msg_kbn,               -- 'XXWSH'
                    gv_msg_93a_029,           -- 出荷実績登録処理エラーメッセージ
                    gv_param1_token,          -- トークン'PARAM1'
                    NULL,                     -- パラメータ(ブロック)
                    gv_param2_token,          -- トークン'PARAM2'
                    iv_object_warehouse,      -- パラメータ(出荷元)
                    gv_param3_token,          -- トークン'PARAM3'
                    NULL);                    -- パラメータ(依頼元)
--
      lv_errbuf := lv_errmsg;
--
      RAISE global_api_expt;
--
    END IF ;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END ship_results_regist_process;
--
 /**********************************************************************************
  * Procedure Name   : move_results_regist_process
  * Description      : 入出庫実績登録処理プロシージャ (A-17)
  ***********************************************************************************/
  PROCEDURE move_results_regist_process(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'move_results_regist_process'; -- プログラム名
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
    cv_pkg_name             CONSTANT VARCHAR2(20)  := 'xxinv570001c' ;   -- パッケージ名
    cv_appl_name            CONSTANT VARCHAR2(100) := 'XXINV';           -- アプリケーション短縮名
--
    -- *** ローカル変数 ***
    ln_req_id               NUMBER ;
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
    -- 移動入出庫実績登録処理の呼び出しを行う。
    ln_req_id := FND_REQUEST.SUBMIT_REQUEST(
                  application       => cv_appl_name         -- アプリケーション短縮名
                 ,program           => cv_pkg_name          -- プログラム名
                 ,argument1         => NULL                 -- パラメータ０１(移動番号)
                 ) ;
--
    -- エラーの場合
    IF (ln_req_id = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
	                gv_msg_kbn,               -- 'XXINV'
                    gv_msg_93a_030,           -- 入出庫実績登録処理エラーメッセージ
                    gv_param1_token,          -- トークン'PARAM1'
                    NULL
                    );                        -- パラメータ(依頼元)
--
      lv_errbuf := lv_errmsg;
--
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力(エラー以外)をする必要がある場合は処理を記述
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
  END move_results_regist_process;
--
 /**********************************************************************************
  * Procedure Name   : submain
  * Description      : メイン処理プロシージャ
  **********************************************************************************/
  PROCEDURE submain(
    iv_process_object_info  IN  VARCHAR2,            -- 処理対象情報
    iv_report_post          IN  VARCHAR2,            -- 報告部署
    iv_object_warehouse     IN  VARCHAR2,            -- 対象倉庫
    ov_errbuf               OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    in_idx                  NUMBER;          -- データindex
    lv_warn_flg             VARCHAR2(1);     -- 警告識別フラグ
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理
    -- ===============================
--
    lv_warn_flg := gv_status_normal;
--
    -- 開始時のシステム現在日付を代入
    gd_sysdate := SYSDATE;
--
    -- WHOカラムの設定
    gt_user_id          := FND_GLOBAL.USER_ID;         -- 作成者(最終更新者)
    gt_sysdate          := gd_sysdate;                 -- 作成日(最終更新日)
    gt_login_id         := FND_GLOBAL.LOGIN_ID;        -- 最終更新ログイン
    gt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- 要求ID
    gt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- アプリケーションID
    gt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
    -- グローバル変数の初期化
    gn_purge_period := 0;              -- プロファイルパージ処理期間
    -- 処理件数の初期化
    gn_target_cnt             := 0;              -- 入力件数
--
--********** 2008/07/07 ********** ADD    START ***
    -- 新規用のカウント
    gn_ord_new_shikyu_cnt     := 0;              -- 新規受注（支給）作成件数
    gn_ord_new_syukka_cnt     := 0;              -- 新規受注（出荷）作成件数
    gn_mov_new_cnt            := 0;              -- 新規移動作成件数
    -- 訂正用のカウント
    gn_ord_correct_shikyu_cnt := 0;              -- 訂正受注（支給）作成件数
    gn_ord_correct_syukka_cnt := 0;              -- 訂正受注（出荷）作成件数
    gn_mov_correct_cnt        := 0;              -- 訂正移動作成件数
--********** 2008/07/07 ********** ADD    END   ***
--
--********** 2008/07/07 ********** DELETE START ***
--* -- 受注ヘッダ
--* gn_ord_h_upd_n_cnt        := 0;              -- 受注ヘッダ更新作成件数(実績計上)
--* gn_ord_h_ins_cnt          := 0;              -- 受注ヘッダ登録作成件数(外部倉庫発番)
--* gn_ord_h_upd_y_cnt        := 0;              -- 受注ヘッダ更新作成件数(実績訂正)
--* -- 受注明細
--* gn_ord_l_upd_n_cnt        := 0;              -- 受注明細更新作成件数(実績計上品目あり)
--* gn_ord_l_ins_n_cnt        := 0;              -- 受注明細登録作成件数(実績計上品目なし)
--* gn_ord_l_ins_cnt          := 0;              -- 受注明細登録作成件数(外部倉庫発番)
--* gn_ord_l_ins_y_cnt        := 0;              -- 受注明細登録作成件数(実績修正)
--* -- ロット詳細
--* gn_ord_mov_ins_n_cnt      := 0;              -- ロット詳細新規作成件数(受注_実績計上)
--* gn_ord_mov_ins_cnt        := 0;              -- ロット詳細新規作成件数(受注_外部倉庫発番)
--* gn_ord_mov_ins_y_cnt      := 0;              -- ロット詳細新規作成件数(受注_実績修正)
--* -- 移動依頼/指示ヘッダ
--* gn_mov_h_ins_cnt          := 0;              -- 移動依頼/指示ヘッダ登録作成件数(外部倉庫発番)
--* gn_mov_h_upd_n_cnt        := 0;              -- 移動依頼/指示ヘッダ更新作成件数(実績計上)
--* gn_mov_h_upd_y_cnt        := 0;              -- 移動依頼/指示ヘッダ更新作成件数(実績訂正)
--* -- 移動依頼/指示明細
--* gn_mov_l_upd_n_cnt        := 0;              -- 移動依頼/指示明細更新作成件数(実績計上品目あり)
--* gn_mov_l_ins_n_cnt        := 0;              -- 移動依頼/指示明細登録作成件数(実績計上品目なし)
--* gn_mov_l_ins_cnt          := 0;              -- 移動依頼/指示明細登録作成件数(外部倉庫発番)
--* gn_mov_l_upd_y_cnt        := 0;              -- 移動依頼/指示明細登録作成件数(訂正元品目あり)
--* gn_mov_l_ins_y_cnt        := 0;              -- 移動依頼/指示明細登録作成件数(訂正元品目なし)
--* -- ロット詳細
--* gn_mov_mov_ins_n_cnt      := 0;              -- ロット詳細新規作成件数(移動依頼_実績計上)
--* gn_mov_mov_ins_cnt        := 0;              -- ロット詳細新規作成件数(移動依頼_外部倉庫発番)
--* gn_mov_mov_upd_y_cnt      := 0;              -- ロット詳細新規作成件数(移動依頼_訂正ロットあり)
--* gn_mov_mov_ins_y_cnt      := 0;              -- ロット詳細新規作成件数(移動依頼_訂正ロットなし)
--* --
--* gn_del_headers_cnt        := 0;              -- IFヘッダ取消情報件数
--********** 2008/07/07 ********** DELETE END   ***
    gn_del_lines_cnt          := 0;              -- IF明細取消情報件数
    --
    gn_del_errdata_cnt        := 0;              -- エラーデータ削除件数
    --
    gn_warn_cnt               := 0;              -- 警告件数
--********** 2008/07/07 ********** DELETE START ***
--* gn_error_cnt              := 0;              -- 異常件数
--********** 2008/07/07 ********** DELETE END   ***
--
    -- ================================
    -- パラメータチェック (A-0)
    -- ================================
    chk_param(
      iv_process_object_info,    -- 処理対象情報
      iv_report_post,            -- 報告部署
      lv_errbuf,                 -- エラー・メッセージ           --# 固定 #
      lv_retcode,                -- リターン・コード             --# 固定 #
      lv_errmsg);                -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- プロファイル値取得 プロシージャ (A-1)
    -- ===============================
    get_profile(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- パージ処理 プロシージャ (A-2)
    -- ===============================
    purge_processing(
      iv_process_object_info, -- 処理対象情報
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 外部倉庫入出庫実績情報抽出 プロシージャ (A-3)
    -- ===============================
    get_warehouse_results_info(
      iv_process_object_info, -- 処理対象情報
      iv_report_post,         -- 報告部署
      iv_object_warehouse,    -- 対象倉庫
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (gr_interface_info_rec.COUNT = 0) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    END IF;
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 外部倉庫発番チェック プロシージャ (A-4)
    -- ===============================
    out_warehouse_number_check(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- エラーチェック_配送No単位 プロシージャ (A-5-1)
    -- ===============================
    err_chk_delivno(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- エラーチェック_配送No受注ソース参照単位 プロシージャ (A-5-2)
    -- ===============================
    err_chk_delivno_ordersrcref(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- エラーチェック_明細単位 プロシージャ (A-5-3)
    -- ===============================
    err_chk_line(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 妥当チェック プロシージャ (A-6)
    -- ===============================
    appropriate_check(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -----------------------------------------------------------------
    -- 外部倉庫入出庫実績情報抽出データ出荷依頼/指示データ1件毎の処理
    -----------------------------------------------------------------
--
    -- フラグ初期化
    gb_mov_header_flg      := FALSE;      -- 移動(A-7) 外部倉庫(指示なし)判定 ヘッダ用
    gb_mov_line_flg        := FALSE;      -- 移動(A-7) 外部倉庫(指示なし)判定 明細用
--
    gb_mov_header_data_flg := FALSE;      -- 移動(A-7) ヘッダ処理済判定
    gb_mov_line_data_flg   := FALSE;      -- 移動(A-7) 明細処理済判定
--
    gb_mov_cnt_a7_flg      := FALSE;      -- 移動(A-7) 件数表示で計上か訂正か判断するのためのフラグ
--
  <<mov_gr_interface_info_rec_loop>>
    FOR i IN gr_interface_info_rec.FIRST .. gr_interface_info_rec.LAST LOOP
--
      --index退避
      in_idx := i;
      --EOSデータ種別より判定を行い、出荷依頼/指示のデータ作成を行う。
      IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220) OR   --220 移動出庫確定報告
         (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230))      --230 移動入庫確定報告
      THEN
        --
          -- ===============================
          -- 移動依頼/指示アドオン出力 プロシージャ (A-7)
          -- ===============================
          mov_table_outpout(
            in_idx,                 -- データindex
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode = gv_status_warn) THEN
            lv_warn_flg := gv_status_warn;
          END IF;
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        --
        -- A-6,A-7にてエラー・保留が確定してるデータは処理対象外とする。
        --
        IF ((gr_interface_info_rec(i).err_flg = gv_flg_off) AND      --エラーflag：'0'(正常)
           (gr_interface_info_rec(i).reserve_flg = gv_flg_off))      --保留flag  ：'0'(正常)
        THEN
          -- ===============================
          -- 抽出元レコード削除 プロシージャ(A-11)
          -- ===============================
          origin_record_delete(
            in_idx,                 -- データindex
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP mov_gr_interface_info_rec_loop;
--
    -----------------------------------------------------------------
    -- 外部倉庫入出庫実績情報抽出データ受注データ1件毎の処理
    -----------------------------------------------------------------
--
    -- フラグ初期化
    gb_ord_header_flg      := FALSE;      -- 受注(A-8) 外部倉庫(指示なし)判定 ヘッダ用
    gb_ord_line_flg        := FALSE;      -- 受注(A-8) 外部倉庫(指示なし)判定 明細用
--
    gb_ord_header_data_flg := FALSE;      -- 受注(A-8) ヘッダ処理済判定
    gb_ord_line_data_flg   := FALSE;      -- 受注(A-8) 明細処理済判定
--
    gb_ord_cnt_a8_flg      := FALSE;      -- 受注(A-8) 件数表示で計上か訂正か判断するのためのフラグ
--
    <<ord_gr_interface_info_rec_loop>>
    FOR i IN gr_interface_info_rec.FIRST .. gr_interface_info_rec.LAST LOOP
--
      --index退避
      in_idx := i;
      --EOSデータ種別より判定を行い、受注データ作成を行う。
      IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR   --200 有償出荷報告
         (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210)  OR   --210 拠点出荷確定報告
         (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215))      --215 庭先出荷確定報告
      THEN
        --
          -- ===============================
          -- 受注アドオン出力 プロシージャ (A-8)
          -- ===============================
          order_table_outpout(
            in_idx,                 -- データindex
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode = gv_status_warn) THEN
            lv_warn_flg := gv_status_warn;
          END IF;
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        --
        -- A-6,A-7にてエラー・保留が確定してるデータは処理対象外とする。
        --
        IF ((gr_interface_info_rec(i).err_flg = gv_flg_off) AND      --エラーflag：'0'(正常)
           (gr_interface_info_rec(i).reserve_flg = gv_flg_off))      --保留flag  ：'0'(正常)
        THEN
          -- ===============================
          -- 抽出元レコード削除 プロシージャ(A-11)
          -- ===============================
          origin_record_delete(
            in_idx,                 -- データindex
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP ord_gr_interface_info_rec_loop;
--
    -- ===============================
    -- ロット逆転防止チェック プロシージャ(A-9)
    -- ===============================
    lot_reversal_prevention_check(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 引当可能チェック プロシージャ(A-10)
    -- ===============================
    drawing_enable_check(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- エラー発生レベルによりレコード削除プロシージャ(A-13)
    -- ===============================
    err_check_delete(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ステータス更新 プロシージャ(A-12)
    -- ===============================
    status_update(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 登録更新削除処理プロシージャ (A-15)
    -- ===============================
    ins_upd_del_processing(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- エラー内容出力プロシージャ (A-14)
    -- ===============================
      err_output(
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- ===============================
    -- 出荷実績登録処理プロシージャ (A-16)
    -- ===============================
--  受注アドオンへ登録又は更新するデータが1件以上存在した場合
--
--********** 2008/07/07 ********** MODIFY START ***
--* IF ((gn_ord_h_upd_n_cnt > 0) OR
--*    (gn_ord_h_ins_cnt > 0)    OR
--*    (gn_ord_h_upd_y_cnt > 0))
--
    IF ((gn_ord_new_shikyu_cnt     > 0) OR
        (gn_ord_new_syukka_cnt     > 0) OR
        (gn_ord_correct_shikyu_cnt > 0) OR
        (gn_ord_correct_syukka_cnt > 0))
--********** 2008/07/07 ********** MODIFY END   ***
--
    THEN
--
      ship_results_regist_process(
        iv_object_warehouse,    -- 対象倉庫
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 入出庫実績登録処理プロシージャ (A-17)
    -- ===============================
--  移動依頼/指示アドオンへ登録又は更新するデータが1件以上存在した場合
--
--********** 2008/07/07 ********** MODIFY START ***
--* IF ((gn_mov_h_ins_cnt > 0) OR
--*   (gn_mov_h_upd_n_cnt > 0) OR
--*   (gn_mov_h_upd_y_cnt > 0))
--* THEN
--
    IF ((gn_mov_new_cnt     > 0) OR
        (gn_mov_correct_cnt > 0))
    THEN
--********** 2008/07/07 ********** MODIFY END   ***
--
      move_results_regist_process(
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (lv_warn_flg = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
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
  PROCEDURE main(
    errbuf                    OUT NOCOPY VARCHAR2,     -- エラーメッセージ #固定#
    retcode                   OUT NOCOPY VARCHAR2,     -- エラーコード     #固定#
    iv_process_object_info    IN  VARCHAR2,            -- 処理対象情報
    iv_report_post            IN  VARCHAR2,            -- 報告部署
    iv_object_warehouse       IN  VARCHAR2             -- 対象倉庫
  )
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
    -- ログ出力フラグ設定
    set_debug_switch();
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
    --入力パラメータ(処理対象情報)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_031, gv_tkn_input_item,
                                           iv_process_object_info);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --入力パラメータ(報告部署)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_032, gv_tkn_input_item,
                                           iv_report_post);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --入力パラメータ(対象倉庫)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_033, gv_tkn_input_item,
                                           iv_object_warehouse);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
      iv_process_object_info,     -- 処理対象情報
      iv_report_post,             -- 報告部署
      iv_object_warehouse,        -- 対象倉庫
      lv_errbuf,                  -- エラー・メッセージ           --# 固定 #
      lv_retcode,                 -- リターン・コード             --# 固定 #
      lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
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
    --入力件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_034,gv_tkn_cnt,
                                           TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    IF (lv_retcode = gv_status_error) THEN
--
--********** 2008/07/07 ********** DELETE START ***
--*   -- 受注ヘッダ
--*   gn_ord_h_upd_n_cnt        := 0;              -- 受注ヘッダ更新作成件数(実績計上)
--*   gn_ord_h_ins_cnt          := 0;              -- 受注ヘッダ登録作成件数(外部倉庫発番)
--*   gn_ord_h_upd_y_cnt        := 0;              -- 受注ヘッダ更新作成件数(実績訂正)
--*   -- 受注明細
--*   gn_ord_l_upd_n_cnt        := 0;              -- 受注明細更新作成件数(実績計上品目あり)
--*   gn_ord_l_ins_n_cnt        := 0;              -- 受注明細登録作成件数(実績計上品目なし)
--*   gn_ord_l_ins_cnt          := 0;              -- 受注明細登録作成件数(外部倉庫発番)
--*   gn_ord_l_ins_y_cnt        := 0;              -- 受注明細登録作成件数(実績修正)
--*   -- ロット詳細
--*   gn_ord_mov_ins_n_cnt      := 0;              -- ロット詳細新規作成件数(受注_実績計上)
--*   gn_ord_mov_ins_cnt        := 0;              -- ロット詳細新規作成件数(受注_外部倉庫発番)
--*   gn_ord_mov_ins_y_cnt      := 0;              -- ロット詳細新規作成件数(受注_実績修正)
--*   -- 移動依頼/指示ヘッダ
--*   gn_mov_h_ins_cnt          := 0;              -- 移動依頼/指示ヘッダ登録作成件数(外部倉庫発番)
--*   gn_mov_h_upd_n_cnt        := 0;              -- 移動依頼/指示ヘッダ更新作成件数(実績計上)
--*   gn_mov_h_upd_y_cnt        := 0;              -- 移動依頼/指示ヘッダ更新作成件数(実績訂正)
--*   -- 移動依頼/指示明細
--*   gn_mov_l_upd_n_cnt        := 0;              -- 移動依頼/指示明細更新作成件数(実績計上品目あり)
--*   gn_mov_l_ins_n_cnt        := 0;              -- 移動依頼/指示明細登録作成件数(実績計上品目なし)
--*   gn_mov_l_ins_cnt          := 0;              -- 移動依頼/指示明細登録作成件数(外部倉庫発番)
--*   gn_mov_l_upd_y_cnt        := 0;              -- 移動依頼/指示明細登録作成件数(訂正元品目あり)
--*   gn_mov_l_ins_y_cnt        := 0;              -- 移動依頼/指示明細登録作成件数(訂正元品目なし)
--*   -- ロット詳細
--*   gn_mov_mov_ins_n_cnt      := 0;              -- ロット詳細新規作成件数(移動依頼_実績計上)
--*   gn_mov_mov_ins_cnt        := 0;              -- ロット詳細新規作成件数(移動依頼_外部倉庫発番)
--*   gn_mov_mov_upd_y_cnt      := 0;              -- ロット詳細新規作成件数(移動依頼_訂正ロットあり)
--*   gn_mov_mov_ins_y_cnt      := 0;              -- ロット詳細新規作成件数(移動依頼_訂正ロットなし)
--*   --
--*   gn_del_headers_cnt        := 0;              -- IFヘッダ取消情報件数
--********** 2008/07/07 ********** DELETE END   ***
--
--********** 2008/07/07 ********** ADD    START ***
    -- 新規用のカウント
    gn_ord_new_shikyu_cnt     := 0;                -- 新規受注（支給）作成件数
    gn_ord_new_syukka_cnt     := 0;                -- 新規受注（出荷）作成件数
    gn_mov_new_cnt            := 0;                -- 新規移動作成件数
    -- 訂正用のカウント
    gn_ord_correct_shikyu_cnt := 0;                -- 訂正受注（支給）作成件数
    gn_ord_correct_syukka_cnt := 0;                -- 訂正受注（出荷）作成件数
    gn_mov_correct_cnt        := 0;                -- 訂正移動作成件数
--********** 2008/07/07 ********** ADD    END   ***
--
      gn_del_lines_cnt          := 0;              -- IF明細取消情報件数
      --
      gn_del_errdata_cnt        := 0;              -- エラーデータ削除件数
      --
      gn_warn_cnt               := 0;              -- 警告件数
    END IF;
--
--********** 2008/07/07 ********** DELETE START ***
--*--受注ヘッダ更新作成件数(実績計上) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_ord_h_upd_n_cnt_nm,   -- 受注ヘッダ更新作成件数(実績計上)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_ord_h_upd_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 受注ヘッダ登録作成件数(外部倉庫発番) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_ord_h_ins_cnt_nm,     -- 受注ヘッダ登録作成件数(外部倉庫発番)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_ord_h_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 受注ヘッダ更新作成件数(実績訂正) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_ord_h_upd_y_cnt_nm,   -- 受注ヘッダ更新作成件数(実績訂正)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_ord_h_upd_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 受注明細更新作成件数(実績計上品目あり) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_ord_l_upd_n_cnt_nm,   -- 受注明細更新作成件数(実績計上品目あり)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_ord_l_upd_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 受注明細登録作成件数(実績計上品目なし) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_ord_l_ins_n_cnt_nm,   -- 受注明細登録作成件数(実績計上品目なし)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_ord_l_ins_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 受注明細登録作成件数(外部倉庫発番) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_ord_l_ins_cnt_nm,     -- 受注明細登録作成件数(外部倉庫発番)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_ord_l_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 受注明細登録作成件数(実績修正) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_ord_l_ins_y_cnt_nm,   -- 受注明細登録作成件数(実績修正)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_ord_l_ins_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ロット詳細新規作成件数(受注_実績計上) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_ord_mov_ins_n_cnt_nm, -- ロット詳細新規作成件数(受注_実績計上)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_ord_mov_ins_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ロット詳細新規作成件数(受注_外部倉庫発番) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_ord_mov_ins_cnt_nm,   -- ロット詳細新規作成件数(受注_外部倉庫発番)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_ord_mov_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ロット詳細新規作成件数(受注_実績修正) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_ord_mov_ins_y_cnt_nm, -- ロット詳細新規作成件数(受注_実績修正)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_ord_mov_ins_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 移動依頼/指示ヘッダ登録作成件数(外部倉庫発番) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_h_ins_cnt_nm, -- 移動依頼/指示ヘッダ登録作成件数(外部倉庫発番)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_h_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 移動依頼/指示ヘッダ更新作成件数(実績計上) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_h_upd_n_cnt_nm,   -- 移動依頼/指示ヘッダ更新作成件数(実績計上)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_h_upd_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 移動依頼/指示ヘッダ更新作成件数(実績訂正) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_h_upd_y_cnt_nm,   -- 移動依頼/指示ヘッダ更新作成件数(実績訂正)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_h_upd_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 移動依頼/指示明細更新作成件数(実績計上品目あり) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_l_upd_n_cnt_nm,   -- 移動依頼/指示明細更新作成件数(実績計上品目あり)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_l_upd_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 移動依頼/指示明細登録作成件数(実績計上品目なし) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_l_ins_n_cnt_nm,   -- 移動依頼/指示明細登録作成件数(実績計上品目なし)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_l_ins_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 移動依頼/指示明細登録作成件数(外部倉庫発番) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_l_ins_cnt_nm,     -- 移動依頼/指示明細登録作成件数(外部倉庫発番)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_l_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 移動依頼/指示明細登録作成件数(訂正元品目あり) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_l_upd_y_cnt_nm,   -- 移動依頼/指示明細登録作成件数(訂正元品目あり)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_l_upd_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- 移動依頼/指示明細登録作成件数(訂正元品目なし) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_l_ins_y_cnt_nm,   -- 移動依頼/指示明細登録作成件数(訂正元品目なし)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_l_ins_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ロット詳細新規作成件数(移動依頼_実績計上) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_mov_ins_n_cnt_nm, -- ロット詳細新規作成件数(移動依頼_実績計上)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_mov_ins_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ロット詳細新規作成件数(移動依頼_外部倉庫発番) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_mov_ins_cnt_nm,   -- ロット詳細新規作成件数(移動依頼_外部倉庫発番)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_mov_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ロット詳細新規作成件数(移動依頼_訂正ロットあり) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_mov_upd_y_cnt_nm, -- ロット詳細新規作成件数(移動依頼_訂正ロットあり)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_mov_upd_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ロット詳細新規作成件数(移動依頼_訂正ロットなし) 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_mov_mov_ins_y_cnt_nm, -- ロット詳細新規作成件数(移動依頼_訂正ロットなし)
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_mov_mov_ins_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--********** 2008/07/07 ********** DELETE END   ***
--
--********** 2008/07/07 ********** ADD    START ***
    -- 新規受注（支給）作成 出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,                 -- 'XXWSH'
                        gv_msg_93a_040,             -- 各処理結果件数メッセージ
                        gv_param1_token,            -- トークン'PARAM1'
                        gv_ord_new_shikyu_cnt_nm,   -- 新規受注（支給）作成
                        gv_tkn_cnt,                 -- トークン'CNT'
                        TO_CHAR(gn_ord_new_shikyu_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 新規受注（出荷）作成 出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,                 -- 'XXWSH'
                        gv_msg_93a_040,             -- 各処理結果件数メッセージ
                        gv_param1_token,            -- トークン'PARAM1'
                        gv_ord_new_syukka_cnt_nm,   -- 新規受注（出荷）作成
                        gv_tkn_cnt,                 -- トークン'CNT'
                        TO_CHAR(gn_ord_new_syukka_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 新規移動作成 出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,              -- 'XXWSH'
                        gv_msg_93a_040,          -- 各処理結果件数メッセージ
                        gv_param1_token,         -- トークン'PARAM1'
                        gv_mov_new_cnt_nm,       -- 新規移動作成
                        gv_tkn_cnt,              -- トークン'CNT'
                        TO_CHAR(gn_mov_new_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 訂正受注（支給）作成 出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,                   -- 'XXWSH'
                        gv_msg_93a_040,               -- 各処理結果件数メッセージ
                        gv_param1_token,              -- トークン'PARAM1'
                        gv_ord_correct_shikyu_cnt_nm, -- 訂正受注（支給）作成
                        gv_tkn_cnt,                   -- トークン'CNT'
                        TO_CHAR(gn_ord_correct_shikyu_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --訂正受注（出荷）作成 出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,                   -- 'XXWSH'
                        gv_msg_93a_040,               -- 各処理結果件数メッセージ
                        gv_param1_token,              -- トークン'PARAM1'
                        gv_ord_correct_syukka_cnt_nm, -- 訂正受注（出荷）作成
                        gv_tkn_cnt,                   -- トークン'CNT'
                        TO_CHAR(gn_ord_correct_syukka_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --訂正移動作成 出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,              -- 'XXWSH'
                        gv_msg_93a_040,          -- 各処理結果件数メッセージ
                        gv_param1_token,         -- トークン'PARAM1'
                        gv_mov_correct_cnt_nm,   -- 訂正移動作成
                        gv_tkn_cnt,              -- トークン'CNT'
                        TO_CHAR(gn_mov_correct_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
--********** 2008/07/07 ********** ADD    END   ***
--
--********** 2008/07/07 ********** DELETE START ***
--* -- 出荷依頼インタフェースヘッダ(アドオン)削除件数 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_header_cnt_nm,        -- 出荷依頼インタフェースヘッダ(アドオン)削除
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_del_headers_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--********** 2008/07/07 ********** DELETE END   ***
--
--********** 2008/07/07 ********** MODIFY START ***
--* -- 出荷依頼インタフェースヘッダ(アドオン)削除件数 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_lines_cnt_nm,         -- 出荷依頼インタフェース明細(アドオン)削除
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_del_lines_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 出荷依頼インタフェースパージ削除件数 出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,              -- 'XXWSH'
                        gv_msg_93a_040,          -- 各処理結果件数メッセージ
                        gv_param1_token,         -- トークン'PARAM1'
                        gv_lines_cnt_nm,         -- 出荷依頼インタフェースパージ削除
                        gv_tkn_cnt,              -- トークン'CNT'
                        TO_CHAR(gn_del_lines_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--********** 2008/07/07 ********** MODIFY END   ***
--
--********** 2008/07/07 ********** MODIFY START ***
--* -- エラーデータ削除件数 出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- 各処理結果件数メッセージ
--*                     gv_param1_token,         -- トークン'PARAM1'
--*                     gv_err_data_del_cnt_nm,  -- エラーデータ削除
--*                     gv_tkn_cnt,              -- トークン'CNT'
--*                     TO_CHAR(gn_del_errdata_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 出荷依頼インタフェースエラー削除件数 出力
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,              -- 'XXWSH'
                        gv_msg_93a_040,          -- 各処理結果件数メッセージ
                        gv_param1_token,         -- トークン'PARAM1'
                        gv_err_data_del_cnt_nm,  -- 出荷依頼インタフェースエラー削除
                        gv_tkn_cnt,              -- トークン'CNT'
                        TO_CHAR(gn_del_errdata_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--********** 2008/07/07 ********** MODIFY END   ***
--
--********** 2008/07/07 ********** DELETE START ***
--* --異常件数出力
--* gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_038,gv_tkn_cnt,
--*                                        TO_CHAR(gn_error_cnt));
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--********** 2008/07/07 ********** DELETE END   ***
--
    --警告件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_039,gv_tkn_cnt,
                                           TO_CHAR(gn_warn_cnt));
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
END xxwsh930001c;
/
