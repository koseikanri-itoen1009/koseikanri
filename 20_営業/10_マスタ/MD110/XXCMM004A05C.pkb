CREATE OR REPLACE PACKAGE BODY XXCMM004A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A05C(body)
 * Description      : 品目一括登録ワークテーブルに取込まれた品目一括登録データを品目テーブルに登録します。
 * MD.050           : 品目一括登録 CMM_004_A05
 * Version          : Issue3.12
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_exists_category    カテゴリ存在チェック
 *  chk_exists_lookup      LOOKUP表存在チェック
 *  proc_comp              終了処理 (A-6)
 *  ins_data               データ登録 (A-5)
 *  validate_item          品目一括登録ワークデータ取得 (A-3)
 *                         品目一括登録ワークデータ妥当性チェック (A-4)
 *                            ・chk_exists_lookup
 *                            ・chk_exists_category
 *  get_if_data            ファイルアップロードIFデータ取得 (A-2)
 *  proc_init              初期処理 (A-1)
 *  submain                メイン処理プロシージャ
 *                            ・proc_init
 *                            ・get_if_data
 *                            ・validate_item
 *                            ・ins_data
 *                            ・proc_comp
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                            ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   K.Ito            main新規作成
 *  2009/02/06    1.1   K.Ito            TE070不具合修正
 *  2009/02/12    1.2   K.Ito            商品製品区分、NETの設定方法変更
 *  2009/02/13                           コンカレント実行結果判定修正
 *  2009/02/16    1.3   K.Ito            TE070レビュー指摘事項反映
 *  2009/02/18    1.4   K.Ito            商品製品区分の設定方法
 *  2009/02/24    1.5   K.Ito            不具合ID.No.005:Disc品目アドオンの検索対象更新日にセットする値を変更
 *                                                       (SYSDATE -> 業務日付)
 *                                       業務日付取得後NULLチェック
 *                                       不具合ID.No.006:子品目でDisc品目変更履歴アドオン登録時、
 *                                       親値継承項目となる定価,営業原価,政策群はセット不要
 *  2009/03/17    1.6   N.Nishimura      本社商品区分によって重量容積区分、容積、重量を設定するよう変更
 *                                      「適用済フラグ」の初期値を「N」から「Y」に変更
 *                                       OPM品目マスタの「マスタ受信日時」にSYSDATEをセットする
 *                                       OPM品目マスタの「試験有無区分」をセットする
 *  2009/04/10    1.7   H.Yoshikawa      障害T1_0215,T1_0219,T1_0220,T1_0437 対応
 *  2009/05/18    1.8   H.Yoshikawa      障害T1_0317,T1_0318,T1_0322,T1_0737,T1_0906 対応
 *  2009/05/27    1.9   H.Yoshikawa      障害T1_0219 再対応
 *  2009/06/04    1.10  N.Nishimura      障害T1_1319 重量または容積がNULLの場合、'0'をセットするように修正
 *                                                   品名コードの半角数値チェックを追加
 *                                       障害T1_1323 品名コードの１桁目が５、６の場合、「ロット」を０に設定する(プロファイルから)
 *  2009/06/11    1.11  N.Nishimura      障害T1_1366 品目カテゴリ割当(バラ茶区分、マーケ用群コード、群コード)追加
 *  2009/07/07    1.12  H.Yoshikawa      障害0000364 未設定標準原価0円登録、08～10の登録を追加
 *  2009/07/24    1.13  Y.Kuboshima      障害0000842 OPM品目アドオンマスタの適用開始日にセットする値を変更
 *                                                   (業務日付 -> プロファイル:XXCMM:適用開始日初期値)
 *  2009/08/07    1.14  Y.Kuboshima      障害0000862 資材品目の場合、標準原価合計値が小数点二桁まで許容するように修正
 *  2009/09/07    1.15  Y.Kuboshima      障害0000948 基準単位のチェックを変更
 *                                                   (本,kg以外はエラー -> LOOKUP(XXCMM_UNITS_OF_MEASURE)に存在しない場合はエラー)
 *                                       障害0001258 品目カテゴリ割当(品目区分,内外区分,商品区分,品質区分,工場群コード,経理用群コード)追加
 *                                                   OPM品目,OPM品目アドオンに設定する値を追加
 *                                                   OPM品目 検査L/T,原価管理区分,代表入数,仕入単価導出日タイプ,判定回数,仕向区分,発注可能判定回数
 *                                                   OPM品目アドオン 工場群,賞味期間区分,賞味期間,消費期間,納入期間,ケース重量容積,
 *                                                                   原料使用量,標準歩留,型種別,商品分類,商品種別,パレ配数,
 *                                                                   パレ段数,容器区分,単位区分,棚卸区分,トレース区分
 *  2009/10/14    1.16  Y.Kuboshima      障害0001370 以下項目0以下の場合、エラーとするように修正
 *                                                   ケース入数、ケース換算入数、NET、重量/体積、内容量、内訳入数、配数、段数
 *  2009/12/07    1.17  Y.Kuboshima      E_本稼動_00358 本社商品区分が「1：リーフ」の場合は0を許容するように修正
 *                                                      本社商品区分が「2：ドリンク」の場合は0を許容しないように修正
 *  2010/01/04    1.18  Shigeto.Niki     E_本稼動_00614 以下項目について親品目の値を継承しないように修正
 *                                                      重量/体積,ITFコード,配数,段数,商品分類,ボール入数
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCMM004A05C';                                  -- パッケージ名
--
  -- メッセージ
  cv_msg_xxcmm_00002     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';                              -- プロファイル取得エラー
  --
  cv_msg_xxcmm_00021     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00021';                              -- ファイルアップロード名称ノート
  cv_msg_xxcmm_00022     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';                              -- CSVファイル名ノート
  cv_msg_xxcmm_00023     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00023';                              -- FILE_IDノート
  cv_msg_xxcmm_00024     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00024';                              -- フォーマットノート
  cv_msg_xxcmm_00028     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00028';                              -- データ項目数エラー
  --
  cv_msg_xxcmm_00401     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00401';                              -- パラメータNULLエラー
  cv_msg_xxcmm_00402     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00402';                              -- IFロック取得エラー
  cv_msg_xxcmm_00403     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00403';                              -- ファイル項目チェックエラー
  cv_msg_xxcmm_00404     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00404';                              -- マスタ存在チェックエラー
  cv_msg_xxcmm_00405     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00405';                              -- 品目重複エラー
  cv_msg_xxcmm_00406     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00406';                              -- 親品目ステータスエラー
  cv_msg_xxcmm_00407     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00407';                              -- データ登録エラー
  cv_msg_xxcmm_00408     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00408';                              -- OPM品目トリガー起動ノート
  cv_msg_xxcmm_00409     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00409';                              -- データ抽出エラー
  cv_msg_xxcmm_00410     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00410';                              -- 品名コード7桁必須エラー
  cv_msg_xxcmm_00411     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00411';                              -- 品名コード区分エラー
  cv_msg_xxcmm_00412     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00412';                              -- 半角文字使用禁止エラー
  cv_msg_xxcmm_00413     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00413';                              -- 全角文字使用禁止エラー
  cv_msg_xxcmm_00414     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00414';                              -- 売上対象時率区分エラー
  cv_msg_xxcmm_00415     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00415';                              -- 基準単位エラー
  cv_msg_xxcmm_00416     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00416';                              -- 本社商品区分ドリンク時必須エラー
  cv_msg_xxcmm_00417     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00417';                              -- 商品製品区分商品時必須エラー
  cv_msg_xxcmm_00418     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00418';                              -- データ削除エラー
  cv_msg_xxcmm_00419     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00419';                              -- 親品目必須エラー
  cv_msg_xxcmm_00420     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00420';                              -- 商品製品区分DFF未設定エラー
-- Ver1.7  2009/04/10  Add  障害T1_0219 対応
  cv_msg_xxcmm_00428     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00428';                              -- ＮＥＴ桁数エラー
-- End
-- Ver1.8  2009/05/18 Add  T1_0322 子品目で商品製品区分導出時に親品目の商品製品区分と比較処理を追加
  cv_msg_xxcmm_00431     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00431';                              -- 商品製品区分エラー
-- End
--Ver1.12  2009/07/07  Mod  0000364対応
  cv_msg_xxcmm_00434     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00434';                              -- 営業エラー
--End1.12
-- Ver.1.5 20090224 Add START
  cv_msg_xxcmm_00435     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00435';                              -- 取得失敗エラー
-- Ver.1.5 20090224 Add END
  cv_msg_xxcmm_00438     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00438';                              -- 標準原価エラー
  cv_msg_xxcmm_00439     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00439';                              -- データ抽出エラー
-- 2009/06/04 Ver1.8 障害T1_1319 Add start
  cv_msg_xxcmm_00474     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00474';                              -- 品名コード数値エラー
-- 2009/06/04 Ver1.8 障害T1_1319 End
--
-- 2009/10/14 Ver1.13 障害0001370 add start by Y.Kuboshima
  cv_msg_xxcmm_00493     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00493';                              -- 項目数値不正エラー
-- 2009/10/14 Ver1.13 障害0001370 add end by Y.Kuboshima
--
  -- トークン
  cv_tkn_value           CONSTANT VARCHAR2(20)  := 'VALUE';                                         --
  cv_tkn_ng_profile      CONSTANT VARCHAR2(20)  := 'NG_PROFILE';                                    --
  cv_tkn_up_name         CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';                                   -- ファイルアップロード名称
  cv_tkn_file_id         CONSTANT VARCHAR2(20)  := 'FILE_ID';                                       -- ファイルID
  cv_tkn_file_format     CONSTANT VARCHAR2(20)  := 'FORMAT';                                        -- フォーマット
  cv_tkn_file_name       CONSTANT VARCHAR2(20)  := 'FILE_NAME';                                     -- ファイル名
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';                                         -- 処理件数
  cv_tkn_table           CONSTANT VARCHAR2(20)  := 'TABLE';                                         -- テーブル名
  cv_tkn_key             CONSTANT VARCHAR2(20)  := 'KEY';                                           -- キー名
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERR_MSG';                                       -- エラー内容
  cv_tkn_input_line_no   CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';                                 -- インタフェースの行番号
  cv_tkn_input_item_code CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';                               -- インタフェースの品名コード
  cv_tkn_input_col_name  CONSTANT VARCHAR2(20)  := 'INPUT_COL_NAME';                                -- インタフェースの項目名
  cv_tkn_item_status     CONSTANT VARCHAR2(20)  := 'ITEM_STATUS';                                   -- 品目ステータス
  cv_tkn_req_id          CONSTANT VARCHAR2(20)  := 'REQ_ID';                                        -- 要求ID
  cv_tkn_input           CONSTANT VARCHAR2(20)  := 'INPUT';                                         -- 項目
  cv_tkn_item_um         CONSTANT VARCHAR2(20)  := 'ITEM_UM';                                       -- 基準単位
  cv_tkn_cs_qty          CONSTANT VARCHAR2(20)  := 'PALETTE_MAX_CS_QTY';                            -- 配数
  cv_tkn_step_qty        CONSTANT VARCHAR2(20)  := 'PALETTE_MAX_STEP_QTY';                          -- 段数
  cv_tkn_sp_supplier     CONSTANT VARCHAR2(20)  := 'SP_SUPPLIER_CODE';                              -- 専門店仕入先
--Ver1.12  2009/07/07  Mod  0000364対応
  cv_tkn_disc_cost       CONSTANT VARCHAR2(20)  := 'DISC_COST';                                     -- 営業原価
--End1.12  
  cv_tkn_opm_cost        CONSTANT VARCHAR2(20)  := 'OPM_COST';                                      -- 標準原価(合計値)
  cv_tkn_msg             CONSTANT VARCHAR2(20)  := 'MSG';                                           -- コンカレント終了メッセージ
-- Ver1.7  2009/04/10  Add  障害T1_0219 対応
  cv_tkn_nets_uom_code   CONSTANT VARCHAR2(20)  := 'INPUT_NETS_UOM_CODE';                           -- 内容量単位
  cv_tkn_nets            CONSTANT VARCHAR2(20)  := 'INPUT_NETS';                                    -- 内容量
  cv_tkn_inc_num         CONSTANT VARCHAR2(20)  := 'INPUT_INC_NUM';                                 -- 内訳入数
-- End
-- Ver1.8  2009/05/18 Add  T1_0322 子品目で商品製品区分導出時に親品目の商品製品区分と比較処理を追加
  cv_tkn_item_prd        CONSTANT VARCHAR2(20)  := 'ITEM_PRD_CLASS';                                -- 商品製品区分
  cv_tkn_par_item_prd    CONSTANT VARCHAR2(25)  := 'PARENT_ITEM_PRD_CLASS';                         -- 商品製品区分(親)
-- End
--
  -- アプリケーション短縮名
  cv_appl_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';                                         --
  cv_appl_name_xxcmn     CONSTANT VARCHAR2(5)   := 'XXCMN';                                         --
  --
  cv_log                 CONSTANT VARCHAR2(5)   := 'LOG';                                           -- ログ
  cv_output              CONSTANT VARCHAR2(6)   := 'OUTPUT';                                        -- アウトプット
  --
  cv_file_id             CONSTANT VARCHAR2(20)  := 'FILE_ID';                                       -- ファイルID
-- Ver1.3 Mod 20090216
  cv_format              CONSTANT VARCHAR2(20)  := 'フォーマットパターン';                          -- フォーマット
--  cv_format              CONSTANT VARCHAR2(20)  := 'FORMAT';                                        -- フォーマット
  cv_lookup_type_upload_obj
                         CONSTANT VARCHAR2(30)  := xxcmm_004common_pkg.cv_lookup_type_upload_obj;   -- ファイルアップロードオブジェクト
  cv_prof_item_num       CONSTANT VARCHAR2(30)  := 'XXCMM1_004A05_ITEM_NUM';                        -- 品目一括登録データ項目数
  cv_lookup_item_def     CONSTANT VARCHAR2(30)  := 'XXCMM1_004A05_ITEM_DEF';                        -- 品目一括登録データ項目定義
  cv_lookup_item_defname CONSTANT VARCHAR2(60)  := 'XXCMM:品目一括登録データ項目数';                -- 「品目一括登録データ項目定義」名
--Ver1.10 2009/06/04 Add start
  cv_prof_lot_ctl        CONSTANT VARCHAR2(30)  := 'XXCMM1_004A01F_INI_LOT_VALUE';                  -- XXCMM:品目登録画面_ロットデフォルト値
  cv_lot_ctl_defname     CONSTANT VARCHAR2(60)  := 'XXCMM:品目登録画面_ロットデフォルト値';         -- 「XXCMM:品目登録画面_ロットデフォルト値」名
--Ver1.10 End
--Ver1.11 2009/06/11 Add start
  cv_prof_baracha_div    CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_BARACHA_DIV';                    -- XXCMM:バラ茶区分初期値
  cv_prof_mark_pg        CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_MARK_GUN_CODE';                  -- XXCMM:マーケ用群コード初期値
  cv_baracha_div_def     CONSTANT VARCHAR2(60)  := 'XXCMM:バラ茶区分初期値';                        -- XXCMM:バラ茶区分初期値
  cv_mark_pg_def         CONSTANT VARCHAR2(60)  := 'XXCMM:マーケ用群コード初期値';                  -- XXCMM:マーケ用群コード初期値
--Ver1.11 End
-- 2009/09/07 Ver1.15 障害0001258 add start by Y.Kuboshima
  cv_prof_item_div       CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_ITEM_DIV';                       -- XXCMM:品目区分初期値
  cv_prof_inout_div      CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_INOUT_DIV';                      -- XXCMM:内外区分初期値
  cv_prof_product_div    CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_PRODUCT_DIV';                    -- XXCMM:商品区分初期値
  cv_prof_quality_div    CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_QUALITY_DIV';                    -- XXCMM:品質区分初期値
  cv_prof_fact_pg        CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_FACT_GUN_CODE';                  -- XXCMM:工場群コード初期値
  cv_prof_acnt_pg        CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_ACNT_GUN_CODE';                  -- XXCMM:経理部用群コード初期値
  cv_item_div_def        CONSTANT VARCHAR2(60)  := 'XXCMM:品目区分初期値';                          -- XXCMM:品目区分初期値
  cv_inout_div_def       CONSTANT VARCHAR2(60)  := 'XXCMM:内外区分初期値';                          -- XXCMM:内外区分初期値
  cv_product_div_def     CONSTANT VARCHAR2(60)  := 'XXCMM:商品区分初期値';                          -- XXCMM:商品区分初期値
  cv_quality_div_def     CONSTANT VARCHAR2(60)  := 'XXCMM:品質区分初期値';                          -- XXCMM:品質区分初期値
  cv_fact_pg_def         CONSTANT VARCHAR2(60)  := 'XXCMM:工場群コード初期値';                      -- XXCMM:工場群コード初期値
  cv_acnt_pg_def         CONSTANT VARCHAR2(60)  := 'XXCMM:経理部用群コード初期値';                  -- XXCMM:経理部用群コード初期値
-- 2009/09/07 Ver1.15 障害0001258 add end by Y.Kuboshima
-- Ver.1.5 20090224 Add START
  cv_process_date        CONSTANT VARCHAR2(30)  := '業務日付';                                      -- 業務日付
-- Ver.1.5 20090224 Add END
--
-- Ver1.13 2009/07/24 Add Start
  cv_prof_apply_date     CONSTANT VARCHAR2(30)  := 'XXCMM1_004_INI_OPM_APPLY_DATE';                 -- XXCMM:適用開始日初期値
  cv_apply_date_def      CONSTANT VARCHAR2(60)  := 'XXCMM:適用開始日初期値';                        -- XXCMM:適用開始日初期値
-- Ver1.13 End
--
  -- LOOKUP
  cv_lookup_cost_cmpt    CONSTANT VARCHAR2(30)  := 'XXCMM1_COST_CMPT';                              -- OPM標準原価取得するコンポーネント
  --
  cv_lookup_sales_target CONSTANT VARCHAR2(30)  := 'XXCMN_SALES_TARGET_CLASS';                      -- 売上対象
  cv_lookup_rate_class   CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_RATE_CLASS';                          -- 率区分
  cv_lookup_nets_uom_code
                         CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_NET_UOM_CODE';                        -- 内容量単位
  cv_lookup_barachakubun CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_BARACHAKUBUN';                        -- バラ茶区分
  cv_lookup_product_class
                         CONSTANT VARCHAR2(30)  := 'XXCMN_D02';                                     -- 商品分類
  cv_lookup_vessel_group CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_YOKIGUN';                             -- 容器群
  cv_lookup_new_item_div CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_SHINSYOHINKUBUN';                     -- 新商品区分
  cv_lookup_acnt_group   CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_KERIGUN';                             -- 経理群
  cv_lookup_acnt_vessel_group
                         CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_KERIYOKIGUN';                         -- 経理容器群
  cv_lookup_brand_group  CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_BRANDGUN';                            -- ブランド群
  cv_lookup_senmonten    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_SENMONTEN_SHIIRESAKI';                -- 専門店仕入先
-- 2009/09/07 Ver1.15 障害0000948 add start by Y.Kuboshima
  cv_lookup_units_of_measure
                         CONSTANT VARCHAR2(30)  := 'XXCMM_UNITS_OF_MEASURE';                        -- 基準単位
-- 2009/09/07 Ver1.15 障害0000948 add end by Y.Kuboshima
--
  -- TABLE NAME
  cv_table_flv           CONSTANT VARCHAR2(30)  := 'LOOKUP表';                                      -- FND_LOOKUP_VALUES_VL
  cv_table_mcv           CONSTANT VARCHAR2(30)  := 'カテゴリ';                                      -- MTL_CATEGORIES_VL
  cv_table_iimb          CONSTANT VARCHAR2(30)  := 'OPM品目マスタ';                                 -- IC_ITEM_MST_B
  cv_table_ximb          CONSTANT VARCHAR2(30)  := 'OPM品目アドオン';                               -- XXCMN_ITEM_MST_B
  cv_table_gic_ssk       CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(商品製品区分)';             -- GMI_ITEM_CATEGORIES
  cv_table_gic_hsk       CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(本社商品区分)';             -- GMI_ITEM_CATEGORIES
  cv_table_gic_sg        CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(政策群)';                   -- GMI_ITEM_CATEGORIES
--Ver1.11  2009/06/11 Add Start
  cv_table_gic_bd        CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(バラ茶区分)';               -- GMI_ITEM_CATEGORIES
  cv_table_gic_mgc       CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(マーケ用群コード)';         -- GMI_ITEM_CATEGORIES
  cv_table_gic_pg        CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(群コード)';                 -- GMI_ITEM_CATEGORIES
--Ver1.11  2009/06/11 End
-- 2009/09/07 Ver1.15 障害0001258 add start by Y.Kuboshima
  cv_table_gic_itd       CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(品目区分)';                 -- GMI_ITEM_CATEGORIES
  cv_table_gic_ind       CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(内外区分)';                 -- GMI_ITEM_CATEGORIES
  cv_table_gic_pd        CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(商品区分)';                 -- GMI_ITEM_CATEGORIES
  cv_table_gic_qd        CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(品質区分)';                 -- GMI_ITEM_CATEGORIES
  cv_table_gic_fpg       CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(工場群コード)';             -- GMI_ITEM_CATEGORIES
  cv_table_gic_apg       CONSTANT VARCHAR2(60)  := 'OPM品目カテゴリ割当(経理部用群コード)';         -- GMI_ITEM_CATEGORIES
-- 2009/09/07 Ver1.15 障害0001258 add end by Y.Kuboshima
--
  cv_table_ccd           CONSTANT VARCHAR2(30)  := 'OPM標準原価';                                   -- CM_CMPT_DTL
  cv_table_xsib          CONSTANT VARCHAR2(30)  := 'Disc品目アドオン';                              -- XXCMM_SYSTEM_ITEMS_B
  cv_table_xsibh         CONSTANT VARCHAR2(30)  := 'Disc品目変更履歴アドオン';                      -- XXCMM_SYSTEM_ITEMS_B_HST
  cv_table_xwibr         CONSTANT VARCHAR2(30)  := '品目一括登録ワーク';                            -- XXCMM_WK_ITEM_BATCH_REGIST
  cv_tkn_val_file_ul_if  CONSTANT VARCHAR2(30)  := 'ファイルアップロードIF';                        -- XXCCP_MRP_FILE_UL_INTERFACE
--
  -- ITEM
  cv_item_code           CONSTANT VARCHAR2(30)  := '品名コード';                                    --
  cv_item_batch_regist   CONSTANT VARCHAR2(30)  := '品目一括登録';                                  --
  cv_item_name           CONSTANT VARCHAR2(30)  := '正式名';                                        --
  cv_item_short_name     CONSTANT VARCHAR2(30)  := '略称';                                          --
  cv_item_name_alt       CONSTANT VARCHAR2(30)  := 'カナ';                                          --
  cv_sales_target_flag   CONSTANT VARCHAR2(30)  := '売上対象区分';                                  --
  cv_case_inc_num        CONSTANT VARCHAR2(30)  := 'ケース入数';                                    --
  cv_item_um             CONSTANT VARCHAR2(30)  := '基準単位';                                      --
  cv_item_product_class  CONSTANT VARCHAR2(30)  := '商品製品区分';                                  --
  cv_rate_class          CONSTANT VARCHAR2(30)  := '率区分';                                        --
  cv_weight_volume_class CONSTANT VARCHAR2(30)  := '重量容積区分';                                  --
  cv_weight_volume       CONSTANT VARCHAR2(30)  := '重量／体積';                                    --
  cv_nets                CONSTANT VARCHAR2(30)  := '内容量';                                        --
  cv_nets_uom_code       CONSTANT VARCHAR2(30)  := '内容量単位';                                    --
  cv_inc_num             CONSTANT VARCHAR2(30)  := '内訳入数';                                      --
  cv_hon_product_class   CONSTANT VARCHAR2(30)  := '本社商品区分';                                  --
  cv_baracha_div         CONSTANT VARCHAR2(30)  := 'バラ茶区分';                                    --
  cv_jan_code            CONSTANT VARCHAR2(30)  := 'JANコード';                                     --
  cv_case_jan_code       CONSTANT VARCHAR2(30)  := 'ケースJANコード';                               --
  cv_itf_code            CONSTANT VARCHAR2(30)  := 'ITFコード';                                     --
  cv_policy_group        CONSTANT VARCHAR2(30)  := '政策群';                                        --
  cv_list_price          CONSTANT VARCHAR2(30)  := '定価';                                          --
  cv_standard_price      CONSTANT VARCHAR2(30)  := '標準原価';                                      --
  cv_business_price      CONSTANT VARCHAR2(30)  := '営業原価';                                      --
-- 2009/10/14 障害0001370 add start by Y.Kuboshima
  cv_case_conv_inc_num   CONSTANT VARCHAR2(30)  := 'ケース換算入数';                                --
  cv_net                 CONSTANT VARCHAR2(30)  := 'ＮＥＴ';                                        --
  cv_pale_max_cs_qty     CONSTANT VARCHAR2(30)  := '配数';                                          --
  cv_pale_max_step_qty   CONSTANT VARCHAR2(30)  := '段数';                                          --
-- 2009/10/14 障害0001370 add end by Y.Kuboshima
--
  cv_yes                 CONSTANT VARCHAR2(1)   := 'Y';                                             --
  cv_no                  CONSTANT VARCHAR2(1)   := 'N';                                             --
  cv_null_ok             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ok;                  -- 任意項目
  cv_null_ng             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ng;                  -- 必須項目
  cv_varchar             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_varchar;                  -- 文字列
  cv_number              CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_number;                   -- 数値
  cv_date                CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date;                     -- 日付
  cv_varchar_cd          CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_varchar_cd;               -- 文字列項目
  cv_number_cd           CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_number_cd;                -- 数値項目
  cv_date_cd             CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_date_cd;                  -- 日付項目
  cv_not_null            CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_not_null;                 -- 必須
  cv_msg_comma           CONSTANT VARCHAR2(1)   := ',';                                             -- カンマ
  cv_msg_comma_double    CONSTANT VARCHAR2(2)   := '、';                                            -- カンマ(全角)
  cv_max_date            CONSTANT VARCHAR2(10)  := '9999/12/31';                                    -- MAX日付
  cv_date_format_rmd     CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                                    --
  cv_date_fmt_std        CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_std;             --
--
--ito->20090213 Add
  cv_status_val_normal   CONSTANT VARCHAR2(10)  := '正常';                                          -- 正常:0
  cv_status_val_warn     CONSTANT VARCHAR2(10)  := '警告';                                          -- 警告:1
  cv_status_val_error    CONSTANT VARCHAR2(10)  := 'エラー';                                        -- エラー:2
--
  -- 品目ステータス
  cn_itm_status_num_tmp  CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_num_tmp;       -- 仮採番
  cn_itm_status_pre_reg  CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_pre_reg;       -- 仮登録
  cn_itm_status_regist   CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_regist;        -- 本登録
  cn_itm_status_no_sch   CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_sch;        -- 廃
  cn_itm_status_trn_only CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_trn_only;      -- Ｄ’
  cn_itm_status_no_use   CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;        -- Ｄ
--
  -- コンポーネント区分
  cv_cost_cmpnt_01gen    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_01gen;         -- 原料
  cv_cost_cmpnt_02sai    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_02sai;         -- 再製費
  cv_cost_cmpnt_03szi    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_03szi;         -- 資材費
  cv_cost_cmpnt_04hou    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_04hou;         -- 包装費
  cv_cost_cmpnt_05gai    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_05gai;         -- 外注管理費
  cv_cost_cmpnt_06hkn    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_06hkn;         -- 保管費
  cv_cost_cmpnt_07kei    CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_07kei;         -- その他経費
--
  cv_categ_set_item_prod CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_prod;      -- 商品製品区分
  cv_categ_set_hon_prod  CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_hon_prod;       -- 本社商品区分
  cv_categ_set_seisakugun
                         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_seisakugun;     -- 政策群
--Ver1.11  2009/06/11 Add start
  cv_categ_set_baracha_div
                         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_baracha_div;    -- バラ茶区分
  cv_categ_set_mark_pg   CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_mark_pg;        -- マーケ用群コード
  cv_categ_set_gun_code  CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_gun_code;       -- 群コード
--Ver1.11  2009/06/11 End
-- 2009/09/07 Ver1.15 障害0001258 add start by Y.Kuboshima
  cv_categ_set_item_div  CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_div;       -- 品目区分
  cv_categ_set_inout_div CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_inout_div;      -- 内外区分
  cv_categ_set_product_div
                         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_product_div;    -- 商品区分
  cv_categ_set_quality_div
                         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_quality_div;    -- 品質区分
  cv_categ_set_fact_pg   CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_fact_pg;        -- 工場群コード
  cv_categ_set_acnt_pg   CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_acnt_pg;        -- 経理部用群コード
-- 2009/09/07 Ver1.15 障害0001258 add end by Y.Kuboshima
--
  cv_prog_opmitem_trigger
                         CONSTANT VARCHAR2(20)  := 'XXCMN810003C';                                  -- 「OPM品目トリガー起動コンカレント」
--
  -- 売上対象
  cv_sales_target_0      CONSTANT VARCHAR2(1)   := '0';                                             -- 売上対象外
  cv_sales_target_1      CONSTANT VARCHAR2(1)   := '1';                                             -- 売上対象
  -- 基準単位
-- 2009/09/07 Ver1.15 障害0000948 delete start by Y.Kuboshima
--  cn_item_um_hon         CONSTANT VARCHAR2(2)   := '本';                                            -- 本
--  cn_item_um_kg          CONSTANT VARCHAR2(2)   := 'kg';                                            -- kg
-- 2009/09/07 Ver1.15 障害0000948 delete end by Y.Kuboshima
  -- 商品製品区分
  cn_item_prod_item      CONSTANT NUMBER        := 1;                                               -- 商品
  cn_item_prod_prod      CONSTANT NUMBER        := 2;                                               -- 製品
  -- 率区分
  cn_rate_class_0        CONSTANT NUMBER        := 0;                                               -- 通常
  cn_rate_class_1        CONSTANT NUMBER        := 1;                                               -- 率
  -- 本社商品区分
  cn_hon_prod_leaf       CONSTANT NUMBER        := 1;                                               -- リーフ
  cn_hon_prod_drink      CONSTANT NUMBER        := 2;                                               -- ドリンク
  -- バラ茶区分
  cn_baracha_etc         CONSTANT NUMBER        := 0;                                               -- その他
  cn_baracha_bara        CONSTANT NUMBER        := 1;                                               -- バラ茶
--
--↓2009/03/13 Add Start
  -- 重量容積区分
  cv_weight              CONSTANT VARCHAR2(1)   := '1';                                             -- 重量
  cv_volume              CONSTANT VARCHAR2(1)   := '2';                                             -- 容積
--↑Add End
---2009/03/17 Add start
  -- 試験有無区分
  cv_exam_class_0        CONSTANT NUMBER        := '0';                                             -- 「無」
  cv_exam_class_1        CONSTANT NUMBER        := '1';                                             -- 「有」
--Add End
-- 2009/08/07 Ver1.14 障害0000862 add start by Y.Kuboshima
  -- 資材品目
  cv_leaf_material       CONSTANT VARCHAR2(1)   := '5';                                             -- 資材品目(リーフ)
  cv_drink_material      CONSTANT VARCHAR2(1)   := '6';                                             -- 資材品目(ドリンク)
-- 2009/08/07 Ver1.14 障害0000862 add end by Y.Kuboshima
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_item_def_rtype    IS RECORD                                                                -- レコード型を宣言
      (item_name       VARCHAR2(100)                                                                -- 項目名
      ,item_attribute  VARCHAR2(100)                                                                -- 項目属性
      ,item_essential  VARCHAR2(100)                                                                -- 必須フラグ
      ,item_length     NUMBER                                                                       -- 項目の長さ(整数部分)
      ,decim           NUMBER                                                                       -- 項目の長さ(小数点以下)
      );
  --
  TYPE g_parent_item_rtype IS RECORD                                                                -- 親品目値継承レコード
      (parent_item_id           ic_item_mst_b.item_id%TYPE                                          -- 品目ID
      ,rate_class               xxcmn_item_mst_b.rate_class%TYPE                                    -- 率区分
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--      ,palette_max_cs_qty       xxcmn_item_mst_b.palette_max_cs_qty%TYPE                            -- 配数
--      ,palette_max_step_qty     xxcmn_item_mst_b.palette_max_step_qty%TYPE                          -- パレット当り最大段数
--      ,product_class            xxcmn_item_mst_b.product_class%TYPE                                 -- 商品分類
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
      ,nets                     xxcmm_system_items_b.nets%TYPE                                      -- 内容量
      ,nets_uom_code            xxcmm_system_items_b.nets_uom_code%TYPE                             -- 内容量単位
      ,inc_num                  xxcmm_system_items_b.inc_num%TYPE                                   -- 内訳入数
      ,vessel_group             xxcmm_system_items_b.vessel_group%TYPE                              -- 容器群
      ,acnt_group               xxcmm_system_items_b.acnt_group%TYPE                                -- 経理群
      ,acnt_vessel_group        xxcmm_system_items_b.acnt_vessel_group%TYPE                         -- 経理容器群
      ,brand_group              xxcmm_system_items_b.brand_group%TYPE                               -- ブランド群
      ,baracha_div              xxcmm_system_items_b.baracha_div%TYPE                               -- バラ茶区分
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--      ,bowl_inc_num             xxcmm_system_items_b.bowl_inc_num%TYPE                              -- ボール入数
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
      ,case_jan_code            xxcmm_system_items_b.case_jan_code%TYPE                             -- ケースJANコード
      ,sp_supplier_code         xxcmm_system_items_b.sp_supplier_code%TYPE                          -- 専門店仕入先
      ,case_number              VARCHAR2(240)                                                       -- ケース入数
-- Ver1.8  2009/05/18 Add  T1_0906 ケース換算入数を追加
      ,case_conv_inc_num        xxcmm_system_items_b.case_conv_inc_num%TYPE                         -- ケース換算入数
-- End
      ,net                      VARCHAR2(240)                                                       -- NET
      ,weight_volume_class      VARCHAR2(240)                                                       -- 重量容積区分
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--      ,weight_volume            VARCHAR2(240)                                                       -- 重量／体積
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
      ,jan_code                 VARCHAR2(240)                                                       -- JANコード
      ,item_um                  ic_item_mst_b.item_um%TYPE                                          -- 基準単位
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--      ,itf_code                 VARCHAR2(240)                                                       -- ITFコード
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
      ,sales_target             VARCHAR2(240)                                                       -- 売上対象区分
      ,item_product_class       VARCHAR2(240)                                                       -- 商品製品区分
      ,dualum_ind               ic_item_mst_b.dualum_ind%TYPE                                       -- 二重管理
      ,lot_ctl                  ic_item_mst_b.lot_ctl%TYPE                                          -- ロット
      ,autolot_active_indicator ic_item_mst_b.autolot_active_indicator%TYPE                         -- 自動ロット採番有効
      ,lot_suffix               ic_item_mst_b.lot_suffix%TYPE                                       -- ロット・サフィックス
      ,ssk_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(商品製品区分)
      ,ssk_category_id          mtl_categories_b.category_id%TYPE                                   -- カテゴリID(商品製品区分)
--Ver1.10 2009/06/04 Add start
      ,hon_product_class        VARCHAR2(240)                                                       -- 本社商品区分
--Ver1.10 2009/06/04 End
      ,hsk_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(本社商品区分)
      ,hsk_category_id          mtl_categories_b.category_id%TYPE                                   -- カテゴリID(本社商品区分)
      ,sg_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(政策群)
      ,sg_category_id           mtl_categories_b.category_id%TYPE                                   -- カテゴリID(政策群)
      );
  -- カテゴリ情報(親品目時に使用)
  TYPE g_item_ctg_rtype    IS RECORD                                                                -- レコード型を宣言
      (category_set_name        mtl_category_sets_tl.category_set_name%TYPE                         -- カテゴリ名
      ,category_val             VARCHAR2(240)                                                       -- カテゴリ値
      ,line_no                  VARCHAR2(240)                                                       -- 行番号
      ,item_code                VARCHAR2(240)                                                       -- 品名コード
      ,ssk_category_id          mtl_categories_b.category_id%TYPE                                   -- カテゴリID(商品製品区分)
      ,ssk_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(商品製品区分)
      ,dualum_ind               NUMBER                                                              -- 二重管理
      ,lot_ctl                  NUMBER                                                              -- ロット
      ,autolot_active_indicator NUMBER                                                              -- 自動ロット採番有効
      ,lot_suffix               NUMBER                                                              -- ロット・サフィックス
      ,hsk_category_id          mtl_categories_b.category_id%TYPE                                   -- カテゴリID(本社商品区分)
      ,hsk_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(本社商品区分)
      ,sg_category_id           mtl_categories_b.category_id%TYPE                                   -- カテゴリID(政策群)
      ,sg_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(政策群)
--Ver1.11  2009/06/11 Add start
      ,bd_category_id           mtl_categories_b.category_id%TYPE                                   -- カテゴリID(バラ茶区分)
      ,bd_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(バラ茶区分)
      ,mgc_category_id          mtl_categories_b.category_id%TYPE                                   -- カテゴリID(マーケ用群コード)
      ,mgc_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(マーケ用群コード)
      ,pg_category_id           mtl_categories_b.category_id%TYPE                                   -- カテゴリID(群コード)
      ,pg_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(群コード)
--Ver1.11 End
-- 2009/09/07 Ver1.15 障害0001258 add start by Y.Kuboshima
      ,itd_category_id          mtl_categories_b.category_id%TYPE                                   -- カテゴリID(品目区分)
      ,itd_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(品目区分)
      ,ind_category_id          mtl_categories_b.category_id%TYPE                                   -- カテゴリID(内外区分)
      ,ind_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(内外区分)
      ,pd_category_id           mtl_categories_b.category_id%TYPE                                   -- カテゴリID(商品区分)
      ,pd_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(商品区分)
      ,qd_category_id           mtl_categories_b.category_id%TYPE                                   -- カテゴリID(品質区分)
      ,qd_category_set_id       mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(品質区分)
      ,fpg_category_id          mtl_categories_b.category_id%TYPE                                   -- カテゴリID(工場群コード)
      ,fpg_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(工場群コード)
      ,apg_category_id          mtl_categories_b.category_id%TYPE                                   -- カテゴリID(経理部用群コード)
      ,apg_category_set_id      mtl_category_sets_b.category_set_id%TYPE                            -- カテゴリセットID(経理部用群コード)
-- 2009/09/07 Ver1.15 障害0001258 add end by Y.Kuboshima
      );
  -- LOOKUP情報(親品目時に使用)
  TYPE g_lookup_rtype    IS RECORD                                                                  -- レコード型を宣言
      (lookup_type              fnd_lookup_values.lookup_type%TYPE                                  -- LOOKUP_TYPE
      ,lookup_code              fnd_lookup_values.lookup_code%TYPE                                  -- LOOKUP_CODE
      ,meaning                  fnd_lookup_values.meaning%TYPE                                      -- meaning
      ,line_no                  VARCHAR2(240)                                                       -- 行番号
      ,item_code                VARCHAR2(240)                                                       -- 品名コード
      );
  -- その他情報
  TYPE g_etc_rtype       IS RECORD                                                                  -- レコード型を宣言
      (nets_uom_code            fnd_lookup_values.lookup_type%TYPE                                  -- 内容量単位のLOOKUP_CODE
      );
  --
  TYPE g_item_def_ttype   IS TABLE OF g_item_def_rtype      INDEX BY BINARY_INTEGER;                -- テーブル型の宣言
  --
  TYPE g_check_data_ttype IS TABLE OF VARCHAR2(4000)        INDEX BY BINARY_INTEGER;                -- テーブル型の宣言
--
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_file_id                NUMBER;                                                                 -- パラメータ格納用変数
  gv_format                 VARCHAR2(100);                                                          -- パラメータ格納用変数
  gn_item_num               NUMBER;                                                                 -- 品目一括登録データ項目数格納用
  gd_process_date           DATE;                                                                   -- 業務日付
  g_item_def_tab            g_item_def_ttype;                                                       -- テーブル型変数の宣言
--Ver1.10 2009/06/04 Add start
  gn_lot_ctl                NUMBER;                                                                 -- XXCMM:品目登録画面_ロットデフォルト値格納用
--Ver1.10 End
--Ver1.11 2009/06/11 Add start
  gn_baracha_div            NUMBER;                                                                 -- XXCMM:バラ茶区分初期値
  gv_mark_pg                VARCHAR2(4);                                                            -- XXCMM:マーケ用群コード
--Ver1.11 End
--Ver1.13 2009/07/26 Add Start
  gd_opm_apply_date         DATE;                                                                   -- XXCMM:適用開始日初期値
--Ver1.13 End
-- 2009/09/07 Ver1.15 障害0001258 add start by Y.Kuboshima
  gv_item_div               VARCHAR2(1);                                                            -- XXCMM:品目区分初期値
  gv_inout_div              VARCHAR2(1);                                                            -- XXCMM:内外区分初期値
  gv_product_div            VARCHAR2(1);                                                            -- XXCMM:商品区分初期値
  gv_quality_div            VARCHAR2(1);                                                            -- XXCMM:品質区分初期値
  gv_fact_pg                VARCHAR2(4);                                                            -- XXCMM:工場群コード初期値
  gv_acnt_pg                VARCHAR2(4);                                                            -- XXCMM:経理部用群コード初期値
-- 2009/09/07 Ver1.15 障害0001258 add end by Y.Kuboshima
  --
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** ロックエラー例外 ***
  global_check_lock_expt     EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : chk_exists_category
   * Description      : カテゴリ存在チェック
   ***********************************************************************************/
  PROCEDURE chk_exists_category(
    io_item_ctg_rec      IN  OUT g_item_ctg_rtype  -- 1.カテゴリ情報
   ,ov_errbuf            OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg            OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exists_category'; -- プログラム名
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
    lv_sql                    VARCHAR2(5000);                         -- 動的SQL文字列
    ln_cnt                    NUMBER;                                 -- 抽出件数
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRM変数退避用
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- LOOKUP表動的SQL作成
    --==============================================================
    lv_sql :=           'SELECT mcv.category_id ';                              -- カテゴリID
    lv_sql := lv_sql || '      ,mcsv.category_set_id ';                         -- カテゴリセットID
    --
    -- 商品製品区分の場合
    IF ( io_item_ctg_rec.category_set_name = cv_categ_set_item_prod ) THEN
      lv_sql := lv_sql || '      ,TO_NUMBER(mcv.attribute1) ';                  -- 二重管理
      lv_sql := lv_sql || '      ,TO_NUMBER(mcv.attribute2) ';                  -- ロット
      lv_sql := lv_sql || '      ,TO_NUMBER(mcv.attribute3) ';                  -- 自動ロット採番有効
      lv_sql := lv_sql || '      ,TO_NUMBER(mcv.attribute4) ';                  -- ロット・サフィックス
    END IF;
    --
    lv_sql := lv_sql || '  FROM mtl_categories_vl mcv ';                        -- カテゴリ
    lv_sql := lv_sql || '      ,mtl_category_sets_vl mcsv ';                    -- カテゴリセット
    lv_sql := lv_sql || ' WHERE mcv.structure_id       = mcsv.structure_id ';
    lv_sql := lv_sql || '   AND mcsv.category_set_name = '''  ||  io_item_ctg_rec.category_set_name  || '''';      -- カテゴリセット名
    lv_sql := lv_sql || '   AND mcv.segment1           = '''  ||  io_item_ctg_rec.category_val       || '''';      -- カテゴリ値
    --
    -- 動的SQL実行
    BEGIN
      -- 商品製品区分の場合
      IF ( io_item_ctg_rec.category_set_name = cv_categ_set_item_prod ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.ssk_category_id
                                     ,io_item_ctg_rec.ssk_category_set_id
                                     ,io_item_ctg_rec.dualum_ind
                                     ,io_item_ctg_rec.lot_ctl
                                     ,io_item_ctg_rec.autolot_active_indicator
                                     ,io_item_ctg_rec.lot_suffix
                                     ;
      --
      -- 本社商品区分の場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_hon_prod ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.hsk_category_id
                                     ,io_item_ctg_rec.hsk_category_set_id
                                     ;
      --
      -- 政策群の場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_seisakugun ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.sg_category_id
                                     ,io_item_ctg_rec.sg_category_set_id
                                     ;
--Ver1.11  2009/06/11 Add start
      --
      -- バラ茶区分の場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_baracha_div ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.bd_category_id
                                     ,io_item_ctg_rec.bd_category_set_id
                                     ;
      --
      -- マーケ用群コードの場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_mark_pg ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.mgc_category_id
                                     ,io_item_ctg_rec.mgc_category_set_id
                                     ;
      --
      -- 群コードの場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_gun_code ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.pg_category_id
                                     ,io_item_ctg_rec.pg_category_set_id
                                     ;
--Ver1.11  2009/06/11 End
-- 2009/09/07 障害0001258 add start by Y.Kuboshima
      -- 品目区分の場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_item_div ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.itd_category_id
                                     ,io_item_ctg_rec.itd_category_set_id
                                     ;
      -- 内外区分の場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_inout_div ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.ind_category_id
                                     ,io_item_ctg_rec.ind_category_set_id
                                     ;
      -- 商品区分の場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_product_div ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.pd_category_id
                                     ,io_item_ctg_rec.pd_category_set_id
                                     ;
      -- 品質区分の場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_quality_div ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.qd_category_id
                                     ,io_item_ctg_rec.qd_category_set_id
                                     ;
      -- 工場群コードの場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_fact_pg ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.fpg_category_id
                                     ,io_item_ctg_rec.fpg_category_set_id
                                     ;
      -- 経理部用群コードの場合
      ELSIF ( io_item_ctg_rec.category_set_name = cv_categ_set_acnt_pg ) THEN
        EXECUTE IMMEDIATE lv_sql INTO io_item_ctg_rec.apg_category_id
                                     ,io_item_ctg_rec.apg_category_set_id
                                     ;
-- 2009/09/07 障害0001258 add end by Y.Kuboshima
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sqlerrm := SQLERRM;
        ln_cnt := 0;
    END;
    --
    -- 処理結果チェック
    IF ( ln_cnt = 0 ) THEN
      -- データ抽出エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                                          -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00409                                          -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                                                -- トークンコード1
                    ,iv_token_value1 => cv_table_mcv || '(' || io_item_ctg_rec.category_set_name || ')'       -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no                                        -- トークンコード2
                    ,iv_token_value2 => io_item_ctg_rec.line_no                                     -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_item_code                                      -- トークンコード3
                    ,iv_token_value3 => io_item_ctg_rec.item_code                                   -- トークン値3
                    ,iv_token_name4  => cv_tkn_errmsg                                               -- トークンコード4
                    ,iv_token_value4 => lv_sqlerrm                                                  -- トークン値4
                   );
      -- メッセージ出力
      xxcmm_004common_pkg.put_message(
        iv_message_buff => lv_errmsg
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
      --
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_exists_category;
--
  /**********************************************************************************
   * Procedure Name   : chk_exists_lookup
   * Description      : LOOKUP表存在チェック
   ***********************************************************************************/
  PROCEDURE chk_exists_lookup(
    io_lookup_rec  IN  OUT g_lookup_rtype    -- 1.LOOKUP情報
   ,ov_errbuf      OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exists_lookup'; -- プログラム名
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
    lv_sql                    VARCHAR2(5000);                         -- 動的SQL文字列
    ln_cnt                    NUMBER;                                 -- 抽出件数
    lv_lookup_code            fnd_lookup_values.lookup_code%TYPE;     -- 抽出LOOKUP_CODE
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRM変数退避用
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- LOOKUP表動的SQL作成
    --==============================================================
    lv_sql :=           'SELECT flvv.lookup_code ';
    lv_sql := lv_sql || '  FROM fnd_lookup_values_vl flvv ';                    -- LOOKUP表
    lv_sql := lv_sql || ' WHERE flvv.lookup_type   = :v1_lookup_type ';         -- LOOKUP_TYPE
    --
    -- 内容量単位の場合のみ条件を内容とします。
    IF ( io_lookup_rec.lookup_type = cv_lookup_nets_uom_code ) THEN
      lv_sql := lv_sql || '   AND flvv.meaning       = :v2_meaning ';           -- MEANING
    ELSE
      lv_sql := lv_sql || '   AND flvv.lookup_code   = :v2_lookup_code ';       -- LOOKUP_CODE
    END IF;
    --
-- Ver1.7  2009/04/10  Mod  障害T1_0220 対応
--    -- 容器群、経理容器群、ブランド群は(NOT LIKE '%*')を条件付加します。
--    IF ( io_lookup_rec.lookup_type IN ( cv_lookup_vessel_group
--                                       ,cv_lookup_acnt_vessel_group
--                                       ,cv_lookup_brand_group )) THEN
--      lv_sql := lv_sql || '   AND flvv.lookup_code   NOT LIKE ''%*'' ';         -- LOOKUP_CODE
--    -- 経理群は(NOT LIKE '%**')を条件付加します。
--    ELSIF ( io_lookup_rec.lookup_type = cv_lookup_acnt_group ) THEN
--      lv_sql := lv_sql || '   AND flvv.lookup_code   NOT LIKE ''%**'' ';        -- LOOKUP_CODE
--    END IF;
    --
    -- 容器群、経理容器群、ブランド群、経理群の場合、(NOT LIKE '%*')を条件付加します。
    IF ( io_lookup_rec.lookup_type IN ( cv_lookup_vessel_group
                                       ,cv_lookup_acnt_vessel_group
                                       ,cv_lookup_brand_group
                                       ,cv_lookup_acnt_group )) THEN
      lv_sql := lv_sql || '   AND flvv.lookup_code   NOT LIKE ''%*'' ';         -- LOOKUP_CODE
    END IF;
-- End
    --
    lv_sql := lv_sql || '   AND flvv.enabled_flag  = :v3_flag        ';         -- 使用可能フラグ
    lv_sql := lv_sql || '   AND NVL( flvv.start_date_active, :v4_process_date ) <= :v5_process_date ';   -- 適用開始日
    lv_sql := lv_sql || '   AND NVL( flvv.end_date_active,   :v6_process_date ) >= :v7_process_date ';   -- 適用終了日
    --
    --
    -- 動的SQL実行
    BEGIN
      -- 内容量単位の場合のみ条件を内容とします。
      IF ( io_lookup_rec.lookup_type = cv_lookup_nets_uom_code ) THEN
        EXECUTE IMMEDIATE lv_sql
        INTO  lv_lookup_code
        USING io_lookup_rec.lookup_type
             ,io_lookup_rec.meaning
             ,cv_yes
             ,gd_process_date
             ,gd_process_date
             ,gd_process_date
             ,gd_process_date
        ;
      ELSE
        EXECUTE IMMEDIATE lv_sql
        INTO  lv_lookup_code
        USING io_lookup_rec.lookup_type
             ,io_lookup_rec.lookup_code
             ,cv_yes
             ,gd_process_date
             ,gd_process_date
             ,gd_process_date
             ,gd_process_date
        ;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_sqlerrm := SQLERRM;
        lv_lookup_code := NULL;
    END;
    --
    -- 処理結果チェック
    IF ( lv_lookup_code IS NULL ) THEN
      -- データ抽出エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                                          -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00409                                          -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                                                -- トークンコード1
                    ,iv_token_value1 => cv_table_flv || '(' || io_lookup_rec.lookup_type || ')'                -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no                                        -- トークンコード2
                    ,iv_token_value2 => io_lookup_rec.line_no                                                  -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_item_code                                      -- トークンコード3
                    ,iv_token_value3 => io_lookup_rec.item_code                                                -- トークン値3
                    ,iv_token_name4  => cv_tkn_errmsg                                               -- トークンコード4
                    ,iv_token_value4 => lv_sqlerrm                                                  -- トークン値4
                   );
      -- メッセージ出力
      xxcmm_004common_pkg.put_message(
        iv_message_buff => lv_errmsg
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
      --
      ov_retcode := cv_status_error;
    ELSE
      -- 内容量単位の場合のみLOOKUP_CODEを戻します。
      IF ( io_lookup_rec.lookup_type = cv_lookup_nets_uom_code ) THEN
        io_lookup_rec.lookup_code := lv_lookup_code;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_exists_lookup;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : 終了処理 (A-6)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_comp'; -- プログラム名
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
    lv_step                   VARCHAR2(10);                           -- ステップ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    --==============================================================
    -- A-6.1 品目一括登録データ削除
    --==============================================================
    BEGIN
      lv_step := 'A-6.1';
      DELETE FROM xxcmm_wk_item_batch_regist
      ;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        --
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00418         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table               -- トークンコード1
                       ,iv_token_value1 => cv_table_xwibr             -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg              -- トークンコード2
                       ,iv_token_value2 => SQLERRM                    -- トークン値2
                      );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        --
        ov_retcode := cv_status_error;
    END;
    --
    --==============================================================
    -- A-6.2 ファイルアップロードIFテーブルデータ削除
    --==============================================================
    BEGIN
      lv_step := 'A-6.2';
      DELETE FROM xxccp_mrp_file_ul_interface
      WHERE  file_id = gn_file_id
      ;
      --
      COMMIT;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00418          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table                -- トークンコード1
                      ,iv_token_value1 => cv_tkn_val_file_ul_if       -- トークン値1
                      ,iv_token_name2  => cv_tkn_errmsg               -- トークンコード2
                      ,iv_token_value2 => SQLERRM                     -- トークン値2
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        --
        ov_retcode := cv_status_error;
    END;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_comp;
--
  /**********************************************************************************
   * Procedure Name   : ins_data
   * Description      : データ登録 (A-5)
   ***********************************************************************************/
  PROCEDURE ins_data(
    i_wk_item_rec  IN  xxcmm_wk_item_batch_regist%ROWTYPE                  -- 品目一括登録ワーク情報
   ,i_item_ctg_rec IN  g_item_ctg_rtype                                    -- カテゴリ情報
   ,i_etc_rec      IN  g_etc_rtype                                         -- その他情報
   ,ov_errbuf      OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_data'; -- プログラム名
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
-- Ver1.7  2009/04/10  Add  障害T1_0219 対応
    cn_net_uom_code_kg        CONSTANT NUMBER(1) := 2;
    cn_net_uom_code_l         CONSTANT NUMBER(1) := 4;
-- End
--
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(10);                                     -- ステップ
    --
    ln_opm_cost_cnt           NUMBER;                                           -- 行カウンタ(OPM原価明細)
    ln_conc_cnt               NUMBER;                                           -- 行カウンタ(コンカレント)
    --
    l_opm_item_rec            ic_item_mst_b%ROWTYPE;
    l_ctg_product_prod_rec    xxcmm_004common_pkg.opmitem_category_rtype;       -- 商品製品区分
    l_ctg_hon_prod_rec        xxcmm_004common_pkg.opmitem_category_rtype;       -- 本社商品区分
    ln_item_id                ic_item_mst_b.item_id%TYPE;                       -- シーケンスGET用品目ID
    ln_item_hst_id            xxcmm_system_items_b_hst.item_hst_id%TYPE;        -- シーケンスGET用品目変更履歴ID
    lv_check_flag             VARCHAR2(1);                                      -- チェックフラグ
    ln_cmpnt_cost             cm_cmpt_dtl.cmpnt_cost%TYPE;                      -- 原価
    l_set_parent_item_rec     g_parent_item_rtype;                              -- 親品目値継承レコード(セット用)
    lv_tkn_table              VARCHAR2(60);
-- Ver.1.5 20090224 Mod START
    ln_fixed_price            xxcmm_system_items_b_hst.fixed_price%TYPE;
    ln_discrete_cost          xxcmm_system_items_b_hst.discrete_cost%TYPE;
    lv_policy_group           xxcmm_system_items_b_hst.policy_group%TYPE;
-- Ver.1.5 20090224 Mod END
--
    ln_parent_item_id         xxcmn_item_mst_b.parent_item_id%TYPE;
--
-- 2009/09/07 Ver1.15 障害0001258 add start by Y.Kuboshima
    l_xxcmn_item_rec          xxcmn_item_mst_b%ROWTYPE;
-- 2009/09/07 Ver1.15 障害0001258 add end by Y.Kuboshima
--
    -- *** ローカル・カーソル ***
    --
    -- 親品目情報取得カーソル
    CURSOR parent_item_cur(
      pn_parent_item_id  NUMBER
    )
    IS
      SELECT  ximb.item_id
             ,ximb.rate_class
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--             ,ximb.palette_max_cs_qty
--             ,ximb.palette_max_step_qty
--             ,ximb.product_class
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
             ,xsib.nets
             ,xsib.nets_uom_code
             ,xsib.inc_num
             ,xsib.vessel_group
             ,xsib.acnt_group
             ,xsib.acnt_vessel_group
             ,xsib.brand_group
             ,xsib.baracha_div
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--             ,xsib.bowl_inc_num
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
             ,xsib.case_jan_code
             ,xsib.sp_supplier_code
             ,iimb.attribute11   AS case_number
-- Ver1.8  2009/05/18 Add  T1_0906 ケース換算入数を追加
             ,xsib.case_conv_inc_num
-- End
             ,iimb.attribute12   AS net
             ,iimb.attribute10   AS weight_volume_class  --2009/03/13 追加
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--             ,( CASE iimb.attribute10
--                     WHEN cv_weight THEN iimb.attribute25
--                     WHEN cv_volume THEN iimb.attribute16
--                     ELSE NULL
--               END )             AS weight_volume  -- 重量／体積  2009/03/16 追加
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
             --,iimb.attribute25   AS weight_volume  2009/03/16 重量容積区分の追加によってコメントアウト
             ,iimb.attribute21   AS jan_code
             ,iimb.item_um
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--             ,iimb.attribute22   AS itf_code
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
             ,cv_sales_target_0  AS sales_target  -- 子品目の場合、「0:対象外」固定
             ,ssk.item_product_class
             ,ssk.dualum_ind
             ,ssk.lot_ctl
             ,ssk.autolot_active_indicator
             ,ssk.lot_suffix
             ,ssk.ssk_category_set_id
             ,ssk.ssk_category_id
--Ver1.10 2009/06/04 Add start
             ,hsk.hon_product_class
--Ver1.10 2009/06/04 End
             ,hsk.hsk_category_set_id
             ,hsk.hsk_category_id
             ,sg.sg_category_set_id
             ,sg.sg_category_id
      FROM    xxcmn_item_mst_b     ximb
             ,ic_item_mst_b        iimb
             ,xxcmm_system_items_b xsib
             ,(SELECT       gicssk.item_id                  AS item_id
                           ,mcssk.segment1                  AS item_product_class
                           ,TO_NUMBER(mcssk.attribute1)     AS dualum_ind
                           ,TO_NUMBER(mcssk.attribute2)     AS lot_ctl
                           ,TO_NUMBER(mcssk.attribute3)     AS autolot_active_indicator
                           ,TO_NUMBER(mcssk.attribute4)     AS lot_suffix
                           ,mcssk.category_id               AS ssk_category_id
                           ,mcsssk.category_set_id          AS ssk_category_set_id
                FROM        gmi_item_categories  gicssk
                           ,mtl_category_sets_vl mcsssk
                           ,mtl_categories_vl    mcssk
                WHERE       gicssk.category_set_id    = mcsssk.category_set_id
                AND         mcsssk.category_set_name  = cv_categ_set_item_prod
                AND         gicssk.category_id        = mcssk.category_id
                AND         gicssk.category_id        = mcssk.category_id
              ) ssk      -- 商品製品区分
             ,(SELECT       gichsk.item_id                  AS item_id
                           ,mchsk.segment1                  AS hon_product_class
                           ,mchsk.category_id               AS hsk_category_id
                           ,mcshsk.category_set_id          AS hsk_category_set_id
                FROM        gmi_item_categories  gichsk
                           ,mtl_category_sets_vl mcshsk
                           ,mtl_categories_vl    mchsk
                WHERE       gichsk.category_set_id    = mcshsk.category_set_id
                AND         mcshsk.category_set_name  = cv_categ_set_hon_prod
                AND         gichsk.category_id        = mchsk.category_id
                AND         gichsk.category_id        = mchsk.category_id
              ) hsk      -- 本社商品区分
             ,(SELECT       gicsg.item_id                  AS item_id
                           ,mcsg.segment1                  AS policy_group
                           ,mcsg.category_id               AS sg_category_id
                           ,mcssg.category_set_id          AS sg_category_set_id
                FROM        gmi_item_categories  gicsg
                           ,mtl_category_sets_vl mcssg
                           ,mtl_categories_vl    mcsg
                WHERE       gicsg.category_set_id    = mcssg.category_set_id
                AND         mcssg.category_set_name  = cv_categ_set_seisakugun
                AND         gicsg.category_id        = mcsg.category_id
                AND         gicsg.category_id        = mcsg.category_id
              ) sg       -- 政策群
      WHERE   ximb.item_id = pn_parent_item_id
      AND     ximb.item_id = iimb.item_id
      AND     iimb.item_no = xsib.item_code
      AND     ximb.item_id = ssk.item_id
      AND     ximb.item_id = hsk.item_id
      AND     ximb.item_id = sg.item_id
      AND     ximb.start_date_active <= TRUNC(gd_process_date)
      AND     ximb.end_date_active   >= TRUNC(gd_process_date)
      ;
    --
    -- 標準原価コンポーネント取得カーソル
    CURSOR opmcost_cmpnt_cur(
      pd_apply_date  DATE )
    IS
      SELECT     cclr.calendar_code                                   -- カレンダコード
                ,cclr.period_code                                     -- 期間コード
                ,ccmv.cost_cmpntcls_id                                -- 原価コンポーネントID
                ,ccmv.cost_cmpntcls_code                              -- 原価コンポーネントコード
      FROM       cm_cldr_dtl    cclr                                  -- OPM原価カレンダ
                ,cm_cmpt_mst_vl ccmv                                  -- 原価コンポーネント
                ,fnd_lookup_values_vl flv                             -- LOOKUP表
      WHERE      flv.lookup_type          = cv_lookup_cost_cmpt       -- LOOKUPタイプ
      AND        flv.enabled_flag         = cv_yes                    -- 使用可能
      AND        ccmv.cost_cmpntcls_code  = flv.meaning               -- 原価コンポーネントコード
      AND        cclr.start_date         <= pd_apply_date             -- 開始日
      AND        cclr.end_date           >= pd_apply_date             -- 終了日
      ;
    --
    -- *** ローカル・レコード ***
    l_parent_item_rec         parent_item_cur%ROWTYPE;                -- 親品目値継承レコード
    -- OPM標準原価用
    l_opm_cost_header_rec     xxcmm_004common_pkg.opm_cost_header_rtype;
    l_opm_cost_dist_tab       xxcmm_004common_pkg.opm_cost_dist_ttype;
    --
    -- *** ローカルユーザー定義例外 ***
    ins_err_expt              EXCEPTION;                              -- データ登録エラー
    concurrent_expt           EXCEPTION;                              -- コンカレント実行エラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- A-5 データ登録
    --==============================================================
    lv_step := 'A-5.1';
    -- 初期化
    l_set_parent_item_rec := NULL;
    --
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      --==============================================================
      -- 親品目の場合、変数に親品目(品目一括登録データ)をセットします。
      --==============================================================
      lv_step := 'A-5.1.1';
      -- 変数にセット
      l_set_parent_item_rec.rate_class               := i_wk_item_rec.rate_class;                   -- 率区分
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--      l_set_parent_item_rec.palette_max_cs_qty       := TO_NUMBER(i_wk_item_rec.palette_max_cs_qty);     -- 配数
--      l_set_parent_item_rec.palette_max_step_qty     := TO_NUMBER(i_wk_item_rec.palette_max_step_qty);   -- 段数
--      l_set_parent_item_rec.product_class            := TO_NUMBER(i_wk_item_rec.product_class);     -- 商品分類
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
      l_set_parent_item_rec.nets                     := TO_NUMBER(i_wk_item_rec.nets);              -- 内容量
      l_set_parent_item_rec.nets_uom_code            := i_etc_rec.nets_uom_code;                    -- 内容量単位
      l_set_parent_item_rec.inc_num                  := TO_NUMBER(i_wk_item_rec.inc_num);           -- 内訳入数
      l_set_parent_item_rec.vessel_group             := i_wk_item_rec.vessel_group;                 -- 容器群
      l_set_parent_item_rec.acnt_group               := i_wk_item_rec.acnt_group;                   -- 経理群
      l_set_parent_item_rec.acnt_vessel_group        := i_wk_item_rec.acnt_vessel_group;            -- 経理容器群
      l_set_parent_item_rec.brand_group              := i_wk_item_rec.brand_group;                  -- ブランド群
      -- 本社商品区分が「2:ドリンク」の場合、バラ茶区分は「0:その他」をセットします。
      IF ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink ) THEN
        l_set_parent_item_rec.baracha_div              := cn_baracha_etc;                           -- バラ茶区分
      ELSE
        l_set_parent_item_rec.baracha_div              := TO_NUMBER(i_wk_item_rec.baracha_div);     -- バラ茶区分
      END IF;
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--      l_set_parent_item_rec.bowl_inc_num             := TO_NUMBER(i_wk_item_rec.bowl_inc_num);      -- ボール入数
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
      l_set_parent_item_rec.case_jan_code            := i_wk_item_rec.case_jan_code;                -- ケースJANコード
      l_set_parent_item_rec.sp_supplier_code         := i_wk_item_rec.sp_supplier_code;             -- 専門店仕入先コード
      l_set_parent_item_rec.case_number              := i_wk_item_rec.case_inc_num;                 -- ケース入数(DFF)
      -- NETは値が入っていなければ内容量×内訳入数をセットします。
      IF ( i_wk_item_rec.net IS NULL ) THEN
-- Ver1.7  2009/04/10  Add  障害T1_0219 対応
        IF ( i_etc_rec.nets_uom_code IN ( cn_net_uom_code_kg, cn_net_uom_code_l ) ) THEN
          -- KG, L 時は係数(1000)をかける【NETは g のため】
          l_set_parent_item_rec.net := TRUNC(TO_NUMBER(i_wk_item_rec.nets) * TO_NUMBER(i_wk_item_rec.inc_num) * 1000);
        ELSE
          l_set_parent_item_rec.net := TRUNC(TO_NUMBER(i_wk_item_rec.nets) * TO_NUMBER(i_wk_item_rec.inc_num));
        END IF;
-- End
      ELSE
        l_set_parent_item_rec.net := TO_NUMBER( i_wk_item_rec.net );        -- NET
      END IF;
--20090212 Add END
--
-- Ver1.8  2009/05/18 Add  T1_0906 ケース換算入数を追加
      -- ケース換算入数は値が入っていなければケース入数をセットする
      IF ( i_wk_item_rec.case_conv_inc_num IS NULL ) THEN
        l_set_parent_item_rec.case_conv_inc_num := TO_NUMBER( i_wk_item_rec.case_inc_num );
      ELSE
        l_set_parent_item_rec.case_conv_inc_num := i_wk_item_rec.case_conv_inc_num;
      END IF;
-- End
--
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--      l_set_parent_item_rec.weight_volume            := i_wk_item_rec.weight_volume;                -- 重量／体積(DFF)
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
      l_set_parent_item_rec.jan_code                 := i_wk_item_rec.jan_code;                     -- JANコード
      l_set_parent_item_rec.item_um                  := i_wk_item_rec.item_um;                      -- 基準単位
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--      l_set_parent_item_rec.itf_code                 := i_wk_item_rec.itf_code;                     -- ITFコード
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
      l_set_parent_item_rec.sales_target             := i_wk_item_rec.sales_target_flag;            -- 売上対象区分(DFF)
      --
      -- カテゴリ情報はvalidate_item時に取得したものをセットします。
      l_set_parent_item_rec.ssk_category_id          := i_item_ctg_rec.ssk_category_id;
      l_set_parent_item_rec.ssk_category_set_id      := i_item_ctg_rec.ssk_category_set_id;
      l_set_parent_item_rec.dualum_ind               := i_item_ctg_rec.dualum_ind;
--Ver1.10 2009/06/04 Add start
      IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1 ) IN ( '5', '6' ) ) THEN
        l_set_parent_item_rec.lot_ctl                := gn_lot_ctl;
      ELSE
        l_set_parent_item_rec.lot_ctl                := i_item_ctg_rec.lot_ctl;
      END IF;
--Ver1.10 End
      l_set_parent_item_rec.autolot_active_indicator := i_item_ctg_rec.autolot_active_indicator;
      l_set_parent_item_rec.lot_suffix               := i_item_ctg_rec.lot_suffix;
      l_set_parent_item_rec.hsk_category_id          := i_item_ctg_rec.hsk_category_id;
      l_set_parent_item_rec.hsk_category_set_id      := i_item_ctg_rec.hsk_category_set_id;
    ELSE
      --==============================================================
      -- 子品目の場合、親品目抽出し、変数にセットします。
      --==============================================================
      lv_step := 'A-5.1.2';
      SELECT  ximb.parent_item_id
      INTO    ln_parent_item_id
      FROM    xxcmn_item_mst_b  ximb
             ,ic_item_mst_b     iimb
      WHERE   ximb.parent_item_id     = iimb.item_id
      AND     iimb.item_no            = i_wk_item_rec.parent_item_code
      AND     ximb.item_id            = ximb.parent_item_id
      AND     ximb.start_date_active <= TRUNC(gd_process_date)
      AND     ximb.end_date_active   >= TRUNC(gd_process_date)
      ;
      -- 初期化
      l_parent_item_rec := NULL;
      OPEN parent_item_cur(
             pn_parent_item_id => ln_parent_item_id
           );
      FETCH parent_item_cur INTO l_parent_item_rec;
      CLOSE parent_item_cur;
      --
      -- 変数にセット
      l_set_parent_item_rec := l_parent_item_rec;
      --
      -- 子品目で商品製品区分(親品目値)が「1:商品」の場合、専門店仕入先コードは親品目値をセット
      -- それ以外は品目一括登録ワークをセット
      IF ( TO_NUMBER(l_set_parent_item_rec.item_product_class) <> cn_item_prod_item ) THEN
        l_set_parent_item_rec.sp_supplier_code := i_wk_item_rec.sp_supplier_code;
      END IF;
    END IF;
    --
    --==============================================================
    -- A-5.2 OPM品目登録処理
    --==============================================================
    lv_step := 'A-5.2';
    -- ※コメントにしているものは特に要件がない項目
    -- ※固定値設定は標準画面で初期値となっている項目(NOT NULL)
    -- 初期化
    l_opm_item_rec := NULL;
    --
    -- GET ic_item_mst_b.item_id SEQUENCE
    SELECT gem5_item_id_s.NEXTVAL
    INTO   ln_item_id
    FROM   DUAL;
    --
    -- 親品目の場合親品目IDに品目IDをセットします。
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      ln_parent_item_id := ln_item_id;
    END IF;
    --
    l_opm_item_rec.item_id                  := ln_item_id;                                          -- 品目ID
    l_opm_item_rec.item_no                  := i_wk_item_rec.item_code;                             -- 品目コード
    l_opm_item_rec.item_desc1               := i_wk_item_rec.item_name;                             -- 摘要
--    l_opm_item_rec.item_desc2               := NULL;                                                -- 注釈
--    l_opm_item_rec.alt_itema                := NULL;                                                -- 代替品目A
--    l_opm_item_rec.alt_itemb                := NULL;                                                -- 代替品目B
    l_opm_item_rec.item_um                  := l_set_parent_item_rec.item_um;                       -- 基準単位
    l_opm_item_rec.dualum_ind               := l_set_parent_item_rec.dualum_ind;                    -- 二重管理(子品目の場合、親値継承項目)
--    l_opm_item_rec.item_um2                 := NULL;                                                -- 単位二重
    l_opm_item_rec.deviation_lo             := 0;                                                   -- 偏差係数-
    l_opm_item_rec.deviation_hi             := 0;                                                   -- 偏差係数+
--    l_opm_item_rec.level_code               := NULL;                                                --
--Ver1.10 2009/06/04 Add start
    --l_opm_item_rec.lot_ctl                  := l_set_parent_item_rec.lot_ctl;                       -- ロット(子品目の場合、親値継承項目)
      IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1 ) IN ( '5', '6' ) ) THEN
        l_opm_item_rec.lot_ctl              := gn_lot_ctl;
      ELSE
        l_opm_item_rec.lot_ctl              := l_set_parent_item_rec.lot_ctl;                       -- ロット(子品目の場合、親値継承項目)
      END IF;
--Ver1.10 End
    l_opm_item_rec.lot_indivisible          := 0;                                                   -- 分割不可
    l_opm_item_rec.sublot_ctl               := 0;                                                   -- サブロット
-- Ver1.8  2009/05/18 Mod  T1_0737 保管場所に 1:検証済み を設定
--    l_opm_item_rec.loct_ctl                 := 0;                                                   -- 保管場所
    l_opm_item_rec.loct_ctl                 := 1;                                                   -- 保管場所
-- End
    l_opm_item_rec.noninv_ind               := 0;                                                   -- 非在庫
    l_opm_item_rec.match_type               := 3;                                                   -- 照合
    l_opm_item_rec.inactive_ind             := 0;                                                   -- 無効区分
--    l_opm_item_rec.inv_type                 := NULL;                                                -- コード.タイプ
    l_opm_item_rec.shelf_life               := 0;                                                   -- 保存期間
    l_opm_item_rec.retest_interval          := 0;                                                   -- 再テスト間隔
--    l_opm_item_rec.gl_class                 := NULL;                                                -- GL
--    l_opm_item_rec.inv_class                := NULL;                                                -- 在庫
--    l_opm_item_rec.sales_class              := NULL;                                                -- 売上
--    l_opm_item_rec.ship_class               := NULL;                                                -- 出荷
--    l_opm_item_rec.frt_class                := NULL;                                                -- 運送費
--    l_opm_item_rec.price_class              := NULL;                                                -- 価格
--    l_opm_item_rec.storage_class            := NULL;                                                -- 格納
--    l_opm_item_rec.purch_class              := NULL;                                                -- 購買
--    l_opm_item_rec.tax_class                := NULL;                                                --
--    l_opm_item_rec.customs_class            := NULL;                                                -- 通関
--    l_opm_item_rec.alloc_class              := NULL;                                                -- 割当
--    l_opm_item_rec.planning_class           := NULL;                                                -- 計画
--    l_opm_item_rec.itemcost_class           := NULL;                                                -- 原価
--    l_opm_item_rec.cost_mthd_code           := NULL;                                                -- 原価参照
--    l_opm_item_rec.upc_code                 := NULL;                                                -- UPCコード
    l_opm_item_rec.grade_ctl                := 0;                                                   -- グレード
    l_opm_item_rec.status_ctl               := 0;                                                   -- ステータス
--    l_opm_item_rec.qc_grade                 := NULL;                                                -- グレードデフォルト
--    l_opm_item_rec.lot_status               := NULL;                                                -- ロットステータス
--    l_opm_item_rec.bulk_id                  := NULL;                                                --
--    l_opm_item_rec.pkg_id                   := NULL;                                                --
--    l_opm_item_rec.qcitem_id                := NULL;                                                --
--    l_opm_item_rec.qchold_res_code          := NULL;                                                --
--    l_opm_item_rec.expaction_code           := NULL;                                                --
    l_opm_item_rec.fill_qty                 := 0;                                                   --
--    l_opm_item_rec.fill_um                  := NULL;                                                --
    l_opm_item_rec.expaction_interval       := 0;                                                   --
    l_opm_item_rec.phantom_type             := 0;                                                   --
    l_opm_item_rec.whse_item_id             := l_opm_item_rec.item_id;                              --
    l_opm_item_rec.experimental_ind         := 0;                                                   -- 試作
    l_opm_item_rec.exported_date            := gd_process_date;                                     --
--    l_opm_item_rec.trans_cnt                := NULL;                                                --
    l_opm_item_rec.delete_mark              := 0;                                                     --
--    l_opm_item_rec.text_code                := NULL;                                                --
--    l_opm_item_rec.seq_dpnd_class           := NULL;                                                -- 商品
--    l_opm_item_rec.commodity_code           := NULL;                                                -- 商品
    l_opm_item_rec.creation_date            := cd_creation_date;                                    -- 作成日
    l_opm_item_rec.created_by               := cn_created_by;                                       -- 作成者
    l_opm_item_rec.last_update_date         := cd_last_update_date;                                 -- 最終更新日
    l_opm_item_rec.last_updated_by          := cn_last_updated_by;                                  -- 最終更新者
    l_opm_item_rec.last_update_login        := cn_last_update_login;                                -- 最終更新ログインID
    l_opm_item_rec.program_application_id   := cn_program_application_id;                           -- コンカレント・プログラムのアプリケーション
    l_opm_item_rec.program_id               := cn_program_id;                                       -- コンカレント・プログラムID
    l_opm_item_rec.program_update_date      := cd_program_update_date;                              -- プログラムによる更新日
    l_opm_item_rec.request_id               := cn_request_id;                                       -- 要求ID
    -- 政策群は子品目の場合のみセットします。
--    -- ※親品目は変更予約適用で反映されます。
--    IF ( i_wk_item_rec.item_code <> i_wk_item_rec.parent_item_code ) THEN
--      l_opm_item_rec.attribute1               := NULL;                                              -- 旧・群ｺｰﾄﾞ
--      l_opm_item_rec.attribute2               := i_wk_item_rec.policy_group;                        -- 新・群ｺｰﾄﾞ
--      l_opm_item_rec.attribute3               := TO_CHAR(gd_process_date, cv_date_format_rmd);      -- 群ｺｰﾄﾞ適用開始日
--    END IF;
--    l_opm_item_rec.attribute4               := NULL;                                                -- 旧・定価
--    l_opm_item_rec.attribute5               := NULL;                                                -- 新・定価
--    l_opm_item_rec.attribute6               := NULL;                                                -- 定価適用開始日
--    l_opm_item_rec.attribute7               := NULL;                                                -- 旧・営業原価
--    l_opm_item_rec.attribute8               := NULL;                                                -- 新・営業原価
--    l_opm_item_rec.attribute9               := NULL;                                                -- 営業原価適用開始日
--    l_opm_item_rec.attribute10              := NULL;                                                -- 重量容積区分
--
--↓2009/03/13 Add Start
--    l_opm_item_rec.attribute10              := l_set_parent_item_rec.weight_volume_class;             -- 重量容積区分
--↑Add End
--↓2009/03/13 Add Start
      -- 本社商品区分が「1:リーフ」の場合、重量容積区分は「2:容積」
      --               「2:ドリンク」の場合、重量容積区分は「1:重量」
      IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
        IF ( i_wk_item_rec.hon_product_class = cn_hon_prod_leaf ) THEN
          l_opm_item_rec.attribute10          := cv_volume;                                           -- 重量容積区分(DFF)
        ELSIF ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink ) THEN
          l_opm_item_rec.attribute10          := cv_weight;                                           -- 重量容積区分(DFF)
        END IF;
      ELSE
        l_opm_item_rec.attribute10          := l_set_parent_item_rec.weight_volume_class;
      END IF;
--↑Add End
    l_opm_item_rec.attribute11              := l_set_parent_item_rec.case_number;                   -- ケース入数(子品目の場合、親値継承項目)
    l_opm_item_rec.attribute12              := l_set_parent_item_rec.net;                           -- NET(子品目の場合、親値継承項目)
    l_opm_item_rec.attribute13              := i_wk_item_rec.sale_start_date;                         -- 発売（製造）開始日
-- 2009/09/07 Ver1.15 障害0001258 modify start by Y.Kuboshima
--    l_opm_item_rec.attribute14              := NULL;                                                -- 検査L/T
--    l_opm_item_rec.attribute15              := NULL;                                                -- 原価管理区分
    l_opm_item_rec.attribute14              := '0';                                                 -- 検査L/T
    l_opm_item_rec.attribute15              := '1';                                                 -- 原価管理区分
-- 2009/09/07 Ver1.15 障害0001258 modify end by Y.Kuboshima
--    l_opm_item_rec.attribute16              := NULL;                                                -- 容積
--
--↓2009/03/13 Add Start
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      IF ( i_wk_item_rec.hon_product_class = cn_hon_prod_leaf ) THEN
        l_opm_item_rec.attribute16              := i_wk_item_rec.weight_volume;
      ELSE
-- 2009/06/04 Ver1.10 障害T1_1319 Add start
      --l_opm_item_rec.attribute16              := NULL;
        l_opm_item_rec.attribute16              := '0';
      END IF;
    ELSE
      IF ( l_set_parent_item_rec.weight_volume_class = cv_volume ) THEN
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify start by Shigeto.Niki
--        l_opm_item_rec.attribute16              :=l_set_parent_item_rec.weight_volume;
        l_opm_item_rec.attribute16              := i_wk_item_rec.weight_volume;
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify end by Shigeto.Niki
      ELSE
        l_opm_item_rec.attribute16              := '0';
      END IF;
-- 2009/06/04 Ver1.10 障害T1_1319 End
    END IF;                                                                                          -- 容積
--↑Add End
-- 2009/09/07 Ver1.15 障害0001258 modify start by Y.Kuboshima
--    l_opm_item_rec.attribute17              := NULL;                                                -- 代表入数
    l_opm_item_rec.attribute17              := '1';                                                 -- 代表入数
-- 2009/09/07 Ver1.15 障害0001258 modify end by Y.Kuboshima
-- Ver1.8  2009/05/18 Mod  T1_0318 出荷区分に 1:出荷可 を設定
--    l_opm_item_rec.attribute18              := NULL;                                                -- 出荷区分
    l_opm_item_rec.attribute18              := '1';                                                 -- 出荷区分
-- End
--    l_opm_item_rec.attribute19              := NULL;                                                -- －
-- 2009/09/07 Ver1.15 障害0001258 modify start by Y.Kuboshima
--    l_opm_item_rec.attribute20              := NULL;                                                -- 仕入単価導出日タイプ
    l_opm_item_rec.attribute20              := '2';                                                 -- 仕入単価導出日タイプ
-- 2009/09/07 Ver1.15 障害0001258 modify end by Y.Kuboshima
    l_opm_item_rec.attribute21              := l_set_parent_item_rec.jan_code;                      -- JANコード(子品目の場合、親値継承項目)
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify start by Shigeto.Niki
--    l_opm_item_rec.attribute22              := l_set_parent_item_rec.itf_code;                      -- ITFコード(子品目の場合、親値継承項目)
    l_opm_item_rec.attribute22              := i_wk_item_rec.itf_code;                                -- ITFコード
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify end by Shigeto.Niki
--    l_opm_item_rec.attribute23              := NULL;                                                -- 試験有無区分
--↓2009/03/17 Add Start
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      IF ( ( i_wk_item_rec.item_product_class = cn_item_prod_prod )
        AND ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink) ) THEN
        l_opm_item_rec.attribute23              := cv_exam_class_1;                                   -- 試験有無区分
      ELSE
        l_opm_item_rec.attribute23              := cv_exam_class_0;                                   -- 試験有無区分
      END IF;
    ELSE
      IF ( ( l_set_parent_item_rec.item_product_class = cn_item_prod_prod )
        AND ( l_set_parent_item_rec.hon_product_class = cn_hon_prod_drink) ) THEN
        l_opm_item_rec.attribute23              := cv_exam_class_1;                                   -- 試験有無区分
      ELSE
        l_opm_item_rec.attribute23              := cv_exam_class_0;                                   -- 試験有無区分
      END IF;
    END IF;
-- Add End
--    l_opm_item_rec.attribute24              := NULL;                                                -- 入出庫換算単位
--    l_opm_item_rec.attribute25              := l_set_parent_item_rec.weight_volume;                 -- 重量(子品目の場合、親値継承項目)
--↓2009/03/13 Add Start
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      IF ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink ) THEN
        l_opm_item_rec.attribute25              := i_wk_item_rec.weight_volume;
      ELSE
-- 2009/06/04 Ver1.10 障害T1_1319 Add start
      --l_opm_item_rec.attribute25              := NULL;
        l_opm_item_rec.attribute25              := '0';
      END IF;
    ELSE
      IF ( l_set_parent_item_rec.weight_volume_class = cv_weight ) THEN
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify start by Shigeto.Niki
--        l_opm_item_rec.attribute25              :=l_set_parent_item_rec.weight_volume;
        l_opm_item_rec.attribute25              := i_wk_item_rec.weight_volume;
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify end by Shigeto.Niki
      ELSE
        l_opm_item_rec.attribute25              := '0';
      END IF;
-- 2009/06/04 Ver1.10 障害T1_1319 End
    END IF;                                                                                           -- 重量(子品目の場合、親値継承項目)
--↑Add End
    l_opm_item_rec.attribute26              := l_set_parent_item_rec.sales_target;                  -- 売上対象区分(子品目の場合、親値継承項目)
-- 2009/09/07 Ver1.15 障害0001258 modify start by Y.Kuboshima
--    l_opm_item_rec.attribute27              := NULL;                                                -- 判定回数
--    l_opm_item_rec.attribute28              := NULL;                                                -- 仕向区分
--    l_opm_item_rec.attribute29              := NULL;                                                -- 発注可能判定回数
    l_opm_item_rec.attribute27              := '0';                                                   -- 判定回数
    l_opm_item_rec.attribute28              := '1';                                                   -- 仕向区分
    l_opm_item_rec.attribute29              := '0';                                                   -- 発注可能判定回数
-- 2009/09/07 Ver1.15 障害0001258 modify end by Y.Kuboshima
--    l_opm_item_rec.attribute30              := NULL;                                                -- マスタ受信日時
--↓2009/03/17 Add Start
    l_opm_item_rec.attribute30              := TO_CHAR( SYSDATE, cv_date_fmt_std );                   -- マスタ受信日時
--↑Add End
--    l_opm_item_rec.attribute_category       := NULL;                                                --
--    l_opm_item_rec.item_abccode             := NULL;                                                -- ABCランク
-- Ver1.8  2009/05/18 Mod  T1_0737 価格設定ソースに 0:オーダー を設定
--    l_opm_item_rec.ont_pricing_qty_source   := NULL;                                                -- 価格設定ソース
    l_opm_item_rec.ont_pricing_qty_source   := 0;                                                   -- 価格設定ソース
-- End
--    l_opm_item_rec.alloc_category_id        := NULL;                                                -- 割当カテゴリID
--    Z.customs_category_id      := NULL;                                                -- カスタム・カテゴリID
--    l_opm_item_rec.frt_category_id          := NULL;                                                -- 運送カテゴリID
--    l_opm_item_rec.gl_category_id           := NULL;                                                -- GLカテゴリID
--    l_opm_item_rec.inv_category_id          := NULL;                                                -- 在庫カテゴリID
--    l_opm_item_rec.cost_category_id         := NULL;                                                -- 原価カテゴリID
--    l_opm_item_rec.planning_category_id     := NULL;                                                -- 計画カテゴリID
--    l_opm_item_rec.price_category_id        := NULL;                                                -- 価格カテゴリID
--    l_opm_item_rec.purch_category_id        := NULL;                                                -- 購買カテゴリID
--    l_opm_item_rec.sales_category_id        := NULL;                                                -- 売上カテゴリID
--    l_opm_item_rec.seq_category_id          := NULL;                                                -- 順序カテゴリID
--    l_opm_item_rec.ship_category_id         := NULL;                                                -- 出荷カテゴリID
--    l_opm_item_rec.storage_category_id      := NULL;                                                -- 格納カテゴリID
--    l_opm_item_rec.tax_category_id          := NULL;                                                -- 税金カテゴリID
    l_opm_item_rec.autolot_active_indicator := l_set_parent_item_rec.autolot_active_indicator;      -- 自動ロット採番有効(子品目の場合、親値継承項目)
--    l_opm_item_rec.lot_prefix               := NULL;                                                -- ロット・プレフィックス
    l_opm_item_rec.lot_suffix               := l_set_parent_item_rec.lot_suffix;                    -- ロット・サフィックス(子品目の場合、親値継承項目)
--    l_opm_item_rec.sublot_prefix            := NULL;                                                -- サブロット・プレフィックス
--    l_opm_item_rec.sublot_suffix            := NULL;                                                -- サブロット・サフィックス
    --
    -- OPM品目登録
    xxcmm_004common_pkg.ins_opm_item(
      i_opm_item_rec => l_opm_item_rec
     ,ov_errbuf      => lv_errbuf
     ,ov_retcode     => lv_retcode
     ,ov_errmsg      => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_iimb;
      RAISE ins_err_expt;     -- データ登録例外
    END IF;
    --
    --==============================================================
    -- A-5.3 OPM品目アドオン登録処理
    --==============================================================
    lv_step := 'A-5.3';
-- 2009/09/07 Ver1.15 障害0001258 add start by Y.Kuboshima
    -- OPM品目アドオンに設定する項目の追加
    l_xxcmn_item_rec.model_type               := 50;                                                -- 型種別
    l_xxcmn_item_rec.product_type             := 1;                                                 -- 商品種別
    l_xxcmn_item_rec.expiration_day           := 0;                                                 -- 賞味期間
    l_xxcmn_item_rec.delivery_lead_time       := 0;                                                 -- 納入期間
    l_xxcmn_item_rec.whse_county_code         := gv_fact_pg;                                        -- 工場群コード
    l_xxcmn_item_rec.standard_yield           := 0;                                                 -- 標準歩留
    l_xxcmn_item_rec.shelf_life               := 0;                                                 -- 消費期間
    l_xxcmn_item_rec.shelf_life_class         := '10';                                              -- 賞味期間区分
    l_xxcmn_item_rec.bottle_class             := '10';                                              -- 容器区分
    l_xxcmn_item_rec.uom_class                := '10';                                              -- 単位区分
    l_xxcmn_item_rec.inventory_chk_class      := '10';                                              -- 棚卸区分
    l_xxcmn_item_rec.trace_class              := '10';                                              -- トレース区分
    l_xxcmn_item_rec.cs_weigth_or_capacity    := 1;                                                 -- ケース重量容積
    l_xxcmn_item_rec.raw_material_consumption := 1;                                                 -- 原料使用量
-- 2009/09/07 Ver1.15 障害0001258 add end by Y.Kuboshima
    BEGIN
      INSERT INTO xxcmn_item_mst_b(
        item_id
       ,start_date_active
       ,end_date_active
       ,active_flag
       ,item_name
       ,item_short_name
       ,item_name_alt
       ,parent_item_id
       ,obsolete_class
       ,obsolete_date
       ,model_type
       ,product_class
       ,product_type
       ,expiration_day
       ,delivery_lead_time
       ,whse_county_code
       ,standard_yield
       ,shipping_end_date
       ,rate_class
       ,shelf_life
       ,shelf_life_class
       ,bottle_class
       ,uom_class
       ,inventory_chk_class
       ,trace_class
       ,shipping_cs_unit_qty
       ,palette_max_cs_qty
       ,palette_max_step_qty
       ,palette_step_qty
       ,cs_weigth_or_capacity
       ,raw_material_consumption
       ,attribute1
       ,attribute2
       ,attribute3
       ,attribute4
       ,attribute5
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
      ) VALUES (
        ln_item_id                                          -- 品目ID
-- Ver1.7  2009/04/10  Mod  障害T1_0437 対応
--       ,gd_process_date                                     -- 適用開始日
-- Ver1.13 2009/07/24 Mod Start
--       ,TRUNC( SYSDATE )                                    -- 適用開始日
       ,gd_opm_apply_date                                   -- 適用開始日
-- End
-- Ver1.13 End
       ,TO_DATE(cv_max_date, cv_date_fmt_std)               -- 適用終了日
     --2009/03/16  適用済フラグの初期値を「Y」に変更したためコメントアウト
     --,cv_no                                               -- 適用済フラグ
       ,cv_yes                                              -- 適用済フラグ  2009/03/16 変更
       ,i_wk_item_rec.item_name                             -- 正式名
       ,i_wk_item_rec.item_short_name                       -- 略称
       ,i_wk_item_rec.item_name_alt                         -- カナ名
       ,ln_parent_item_id                                   -- 親品目ID
       ,NULL                                                -- 廃止区分
       ,NULL                                                -- 廃止日（製造中止日）
-- 2009/09/07 Ver1.15 障害0001258 modify start by Y.Kuboshima
--       ,NULL                                                -- 型種別
       ,l_xxcmn_item_rec.model_type                         -- 型種別
-- 2009/09/07 Ver1.15 障害0001258 modify end by Y.Kuboshima
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify start by Shigeto.Niki
--       ,l_set_parent_item_rec.product_class                 -- 商品分類(子品目の場合、親値継承項目)
       ,i_wk_item_rec.product_class                         -- 商品分類 
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify end by Shigeto.Niki
-- 2009/09/07 Ver1.15 障害0001258 modify start by Y.Kuboshima
--       ,NULL                                                -- 商品種別
--       ,NULL                                                -- 賞味期間
--       ,NULL                                                -- 納入期間
--       ,NULL                                                -- 工場群コード
--       ,NULL                                                -- 標準歩留
       ,l_xxcmn_item_rec.product_type                       -- 商品種別
       ,l_xxcmn_item_rec.expiration_day                     -- 賞味期間
       ,l_xxcmn_item_rec.delivery_lead_time                 -- 納入期間
       ,l_xxcmn_item_rec.whse_county_code                   -- 工場群コード
       ,l_xxcmn_item_rec.standard_yield                     -- 標準歩留
-- 2009/09/07 Ver1.15 障害0001258 modify end by Y.Kuboshima
       ,NULL                                                -- 出荷停止日
       ,l_set_parent_item_rec.rate_class                    -- 率区分(子品目の場合、親値継承項目)
-- 2009/09/07 Ver1.15 障害0001258 modify start by Y.Kuboshima
--       ,NULL                                                -- 消費期間
--       ,NULL                                                -- 賞味期間区分
--       ,NULL                                                -- 容器区分
--       ,NULL                                                -- 単位区分
--       ,NULL                                                -- 棚卸区分
--       ,NULL                                                -- トレース区分
       ,l_xxcmn_item_rec.shelf_life                         -- 消費期間
       ,l_xxcmn_item_rec.shelf_life_class                   -- 賞味期間区分
       ,l_xxcmn_item_rec.bottle_class                       -- 容器区分
       ,l_xxcmn_item_rec.uom_class                          -- 単位区分
       ,l_xxcmn_item_rec.inventory_chk_class                -- 棚卸区分
       ,l_xxcmn_item_rec.trace_class                        -- トレース区分
-- 2009/09/07 Ver1.15 障害0001258 modify end by Y.Kuboshima
       ,NULL                                                -- 出荷入数
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify start by Shigeto.Niki
--       ,l_set_parent_item_rec.palette_max_cs_qty            -- 配数(子品目の場合、親値継承項目)
--       ,l_set_parent_item_rec.palette_max_step_qty          -- パレット当り最大段数(子品目の場合、親値継承項目)
       ,i_wk_item_rec.palette_max_cs_qty                    -- 配数
       ,i_wk_item_rec.palette_max_step_qty                  -- パレット当り最大段数
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify end by Shigeto.Niki
       ,NULL                                                -- パレット段
-- 2009/09/07 Ver1.15 障害0001258 modify start by Y.Kuboshima
--       ,NULL                                                -- ケース重量容積
--       ,NULL                                                -- 原料使用量
       ,l_xxcmn_item_rec.cs_weigth_or_capacity              -- ケース重量容積
       ,l_xxcmn_item_rec.raw_material_consumption           -- 原料使用量
-- 2009/09/07 Ver1.15 障害0001258 modify end by Y.Kuboshima
       ,NULL                                                -- 予備１
       ,NULL                                                -- 予備２
       ,NULL                                                -- 予備３
       ,NULL                                                -- 予備４
       ,NULL                                                -- 予備５
       ,cn_created_by                                       -- 作成者
       ,cd_creation_date                                    -- 作成日
       ,cn_last_updated_by                                  -- 最終更新者
       ,cd_last_update_date                                 -- 最終更新日
       ,cn_last_update_login                                -- 最終更新ログイン
       ,cn_request_id                                       -- 要求ID
       ,cn_program_application_id                           -- コンカレント・プログラムのアプリケーションID
       ,cn_program_id                                       -- コンカレント・プログラムID
       ,cd_program_update_date                              -- プログラムによる更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        lv_tkn_table := cv_table_ximb;
        RAISE ins_err_expt;   -- データ登録例外
    END;
    --
    --==============================================================
    -- A-5.4 OPM品目カテゴリ割当(商品製品区分)登録処理
    --==============================================================
    lv_step := 'A-5.4';
    l_ctg_product_prod_rec.item_id         := ln_item_id;
    l_ctg_product_prod_rec.category_set_id := l_set_parent_item_rec.ssk_category_set_id;  -- (子品目の場合、親値継承項目)
    l_ctg_product_prod_rec.category_id     := l_set_parent_item_rec.ssk_category_id;      -- (子品目の場合、親値継承項目)
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_product_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_ssk;
      RAISE ins_err_expt;     -- データ登録例外
    END IF;
    --
    --==============================================================
    -- A-5.5 OPM品目カテゴリ割当(本社商品区分)登録処理
    --==============================================================
    lv_step := 'A-5.5';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := l_set_parent_item_rec.hsk_category_set_id;      -- (子品目の場合、親値継承項目)
    l_ctg_hon_prod_rec.category_id     := l_set_parent_item_rec.hsk_category_id;          -- (子品目の場合、親値継承項目)
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_hsk;
      RAISE ins_err_expt;     -- データ登録例外
    END IF;
    --
    --
    --==============================================================
    -- A-5.6 OPM品目カテゴリ割当(政策群)登録処理
    -- 子品目の場合のみ作成します。
    --==============================================================
    lv_step := 'A-5.6';
    IF ( i_wk_item_rec.item_code <> i_wk_item_rec.parent_item_code ) THEN
      l_ctg_hon_prod_rec.item_id         := ln_item_id;
      l_ctg_hon_prod_rec.category_set_id := l_set_parent_item_rec.sg_category_set_id;     -- (子品目の場合、親値継承項目)
      l_ctg_hon_prod_rec.category_id     := l_set_parent_item_rec.sg_category_id;         -- (子品目の場合、親値継承項目)
      xxcmm_004common_pkg.proc_opmitem_categ_ref(
        i_item_category_rec => l_ctg_hon_prod_rec
       ,ov_errbuf           => lv_errbuf
       ,ov_retcode          => lv_retcode
       ,ov_errmsg           => lv_errmsg
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_tkn_table := cv_table_gic_sg;
        RAISE ins_err_expt;   -- データ登録例外
      END IF;
    END IF;
    --
--Ver1.11  2009/06/11 Add start
    --==============================================================
    -- A-5.6-1 OPM品目カテゴリ割当(バラ茶区分)登録処理
    --==============================================================
    lv_step := 'A-5.6-1';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.bd_category_set_id;     -- (子品目の場合、親値継承項目)
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.bd_category_id;         -- (子品目の場合、親値継承項目)
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_bd;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- A-5.6-2 OPM品目カテゴリ割当(マーケ用群コード)登録処理
    --==============================================================
    lv_step := 'A-5.6-2';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.mgc_category_set_id;     -- (子品目の場合、親値継承項目)
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.mgc_category_id;         -- (子品目の場合、親値継承項目)
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_mgc;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- A-5.6-3 OPM品目カテゴリ割当(群コード)登録処理
    -- 親品目の場合、政策群コードが適用された時に設定される
    --==============================================================
    lv_step := 'A-5.6-3';
    IF ( i_wk_item_rec.item_code <> i_wk_item_rec.parent_item_code ) THEN
      l_ctg_hon_prod_rec.item_id         := ln_item_id;
      l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.pg_category_set_id;     -- (子品目の場合、親値継承項目)
      l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.pg_category_id;         -- (子品目の場合、親値継承項目)
      --
      xxcmm_004common_pkg.proc_opmitem_categ_ref(
        i_item_category_rec => l_ctg_hon_prod_rec
       ,ov_errbuf           => lv_errbuf
       ,ov_retcode          => lv_retcode
       ,ov_errmsg           => lv_errmsg
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_tkn_table := cv_table_gic_pg;
        RAISE ins_err_expt;   -- データ登録例外
      END IF;
    END IF;
--Ver1.11  2009/06/11 End
--
-- 2009/09/07 Ver1.15 障害0001258 add start by Y.Kuboshima
    --
    --==============================================================
    -- A-5.6-4 OPM品目カテゴリ割当(品目区分)登録処理
    --==============================================================
    lv_step := 'A-5.6-4';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.itd_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.itd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_itd;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- A-5.6-5 OPM品目カテゴリ割当(内外区分)登録処理
    --==============================================================
    lv_step := 'A-5.6-5';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.ind_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.ind_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_ind;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- A-5.6-6 OPM品目カテゴリ割当(商品区分)登録処理
    --==============================================================
    lv_step := 'A-5.6-6';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.pd_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.pd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_pd;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- A-5.6-7 OPM品目カテゴリ割当(品質区分)登録処理
    --==============================================================
    lv_step := 'A-5.6-7';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.qd_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.qd_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_qd;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- A-5.6-8 OPM品目カテゴリ割当(工場群コード)登録処理
    --==============================================================
    lv_step := 'A-5.6-8';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.fpg_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.fpg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_fpg;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
    --
    --==============================================================
    -- A-5.6-9 OPM品目カテゴリ割当(経理部用群コード)登録処理
    --==============================================================
    lv_step := 'A-5.6-9';
    l_ctg_hon_prod_rec.item_id         := ln_item_id;
    l_ctg_hon_prod_rec.category_set_id := i_item_ctg_rec.apg_category_set_id;
    l_ctg_hon_prod_rec.category_id     := i_item_ctg_rec.apg_category_id;
    --
    xxcmm_004common_pkg.proc_opmitem_categ_ref(
      i_item_category_rec => l_ctg_hon_prod_rec
     ,ov_errbuf           => lv_errbuf
     ,ov_retcode          => lv_retcode
     ,ov_errmsg           => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_tkn_table := cv_table_gic_apg;
      RAISE ins_err_expt;   -- データ登録例外
    END IF;
-- 2009/09/07 Ver1.15 障害0001258 add end by Y.Kuboshima
    --==============================================================
    -- A-5.7 OPM標準原価登録処理
    -- 子品目は変更予約適用で行います。
    --==============================================================
    lv_step := 'A-5.7.1';
    -- 親品目の場合のみ処理します。
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      -- 初期化
      ln_opm_cost_cnt := 0;
      ln_cmpnt_cost := NULL;
      --
      <<cmpnt_loop>>
      FOR opmcost_cmpnt_rec IN opmcost_cmpnt_cur( gd_process_date ) LOOP
        -- 原価の取得
        CASE opmcost_cmpnt_rec.cost_cmpntcls_code
--Ver1.12  2009/07/07  Mod  0000364対応
--          WHEN cv_cost_cmpnt_01gen THEN    -- '01GEN'
--            -- 原料
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_1);
--          WHEN cv_cost_cmpnt_02sai THEN    -- '02SAI'
--            -- 再製費
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_2);
--          WHEN cv_cost_cmpnt_03szi THEN    -- '03SZI'
--            -- 資材費
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_3);
--          WHEN cv_cost_cmpnt_04hou THEN    -- '04HOU'
--            -- 包装費
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_4);
--          WHEN cv_cost_cmpnt_05gai THEN    -- '05GAI'
--            -- 外注管理費
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_5);
--          WHEN cv_cost_cmpnt_06hkn THEN    -- '06HKN'
--            -- 保管費
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_6);
--          WHEN cv_cost_cmpnt_07kei THEN    -- '07KEI'
--            -- その他経費
--            ln_cmpnt_cost := TO_NUMBER(i_wk_item_rec.standard_price_7);
          --
          WHEN cv_cost_cmpnt_01gen THEN    -- '01GEN'
            -- 原料
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_1, 0) );
          WHEN cv_cost_cmpnt_02sai THEN    -- '02SAI'
            -- 再製費
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_2, 0) );
          WHEN cv_cost_cmpnt_03szi THEN    -- '03SZI'
            -- 資材費
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_3, 0) );
          WHEN cv_cost_cmpnt_04hou THEN    -- '04HOU'
            -- 包装費
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_4, 0) );
          WHEN cv_cost_cmpnt_05gai THEN    -- '05GAI'
            -- 外注管理費
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_5, 0) );
          WHEN cv_cost_cmpnt_06hkn THEN    -- '06HKN'
            -- 保管費
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_6, 0) );
          WHEN cv_cost_cmpnt_07kei THEN    -- '07KEI'
            -- その他経費
            ln_cmpnt_cost := TO_NUMBER( NVL( i_wk_item_rec.standard_price_7, 0) );
          ELSE
            -- 予備1～予備3
            ln_cmpnt_cost := 0;
--End1.12
        END CASE;
        --
        -- 原価設定判断
        IF ( ln_cmpnt_cost IS NOT NULL ) THEN
          -- OPM標準原価ヘッダパラメータ設定
          IF ( ln_opm_cost_cnt = 0 ) THEN
            -- カレンダコード
            l_opm_cost_header_rec.calendar_code := opmcost_cmpnt_rec.calendar_code;
            -- 期間コード
            l_opm_cost_header_rec.period_code   := opmcost_cmpnt_rec.period_code;
            -- 品目ID
            l_opm_cost_header_rec.item_id       := ln_item_id;
          END IF;
          --
          -- 原価登録
          ln_opm_cost_cnt := ln_opm_cost_cnt + 1;
          -- 原価明細
          -- 原価コンポーネントID
          l_opm_cost_dist_tab(ln_opm_cost_cnt).cost_cmpntcls_id := opmcost_cmpnt_rec.cost_cmpntcls_id;
          -- 原価
          l_opm_cost_dist_tab(ln_opm_cost_cnt).cmpnt_cost       := ln_cmpnt_cost;
          --
        END IF;
        --
      END LOOP cmpnt_loop;
      --
      lv_step := 'A-5.7.2';
      -- 標準原価登録
      xxcmm_004common_pkg.proc_opmcost_ref(
        i_cost_header_rec => l_opm_cost_header_rec                    -- 1.原価ヘッダレコードタイプ
       ,i_cost_dist_tab   => l_opm_cost_dist_tab                      -- 2.原価明細テーブルタイプ
       ,ov_errbuf         => lv_errbuf                                -- エラー・メッセージ
       ,ov_retcode        => lv_retcode                               -- リターン・コード
       ,ov_errmsg         => lv_errmsg                                -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_tkn_table := cv_table_ccd;
        RAISE ins_err_expt;   -- データ登録例外
      END IF;
    END IF;
    --
    --==============================================================
    -- A-5.8 Disc品目アドオン登録処理
    --==============================================================
    lv_step := 'A-5.8';
    BEGIN
      INSERT INTO xxcmm_system_items_b(
        item_id
       ,item_code
       ,tax_rate
       ,baracha_div
       ,nets
       ,nets_uom_code
       ,inc_num
       ,vessel_group
       ,acnt_group
       ,acnt_vessel_group
       ,brand_group
       ,sp_supplier_code
       ,case_jan_code
       ,new_item_div
       ,bowl_inc_num
       ,item_status_apply_date
       ,item_status
       ,renewal_item_code
       ,search_update_date
-- Ver1.8  2009/05/18 Add  T1_0906 ケース換算入数を追加
       ,case_conv_inc_num
-- End
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
      ) VALUES (
        ln_item_id                                -- 品目ID
       ,i_wk_item_rec.item_code                   -- 品目コード
       ,NULL                                      -- 消費税率
       ,l_set_parent_item_rec.baracha_div         -- バラ茶区分(子品目の場合、親値継承項目)
       ,l_set_parent_item_rec.nets                -- 内容量(子品目の場合、親値継承項目)
       ,l_set_parent_item_rec.nets_uom_code       -- 内容量単位(子品目の場合、親値継承項目)
       ,l_set_parent_item_rec.inc_num             -- 内訳入数(子品目の場合、親値継承項目)
       ,l_set_parent_item_rec.vessel_group        -- 容器群(子品目の場合、親値継承項目)
       ,l_set_parent_item_rec.acnt_group          -- 経理群(子品目の場合、親値継承項目)
       ,l_set_parent_item_rec.acnt_vessel_group   -- 経理容器群(子品目の場合、親値継承項目)
       ,l_set_parent_item_rec.brand_group         -- ブランド群(子品目の場合、親値継承項目)
       ,l_set_parent_item_rec.sp_supplier_code    -- 専門店仕入先コード(子品目の場合、親値継承項目※商品製品区分が「1:商品」の場合)
       ,l_set_parent_item_rec.case_jan_code       -- ケースJANコード(子品目の場合、親値継承項目)
       ,i_wk_item_rec.new_item_div                -- 新商品区分
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify start by Shigeto.Niki
--       ,l_set_parent_item_rec.bowl_inc_num        -- ボール入数(子品目の場合、親値継承項目)
       ,i_wk_item_rec.bowl_inc_num                -- ボール入数
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify end by Shigeto.Niki
       ,NULL                                      -- 品目ステータス適用日
       ,NULL                                      -- 品目ステータス
       ,i_wk_item_rec.renewal_item_code           -- リニューアル元商品コード
-- Ver.1.5 20090224 Mod START
       ,gd_process_date                           -- 検索対象更新日
--       ,cd_creation_date                          -- 検索対象更新日
-- Ver.1.5 20090224 Mod END
-- Ver1.8  2009/05/18 Add  T1_0906 ケース換算入数を追加
       ,l_set_parent_item_rec.case_conv_inc_num   -- ケース換算入数
-- End
       ,cn_created_by                             -- 作成者
       ,cd_creation_date                          -- 作成日
       ,cn_last_updated_by                        -- 最終更新者
       ,cd_last_update_date                       -- 最終更新日
       ,cn_last_update_login                      -- 最終更新ログイン
       ,cn_request_id                             -- 要求ID
       ,cn_program_application_id                 -- コンカレント・プログラムのアプリケーションID
       ,cn_program_id                             -- コンカレント・プログラムID
       ,cd_program_update_date                    -- プログラムによる更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        lv_tkn_table := cv_table_xsib;
        RAISE ins_err_expt;   -- データ登録例外
    END;
    --
    --==============================================================
    -- A-5.9 Disc品目変更履歴アドオン登録処理
    --==============================================================
    lv_step := 'A-5.9';
-- Ver.1.5 20090224 Add START
    -- 親品目の場合、csv値をセットします。
    IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
      ln_fixed_price   := TO_NUMBER(i_wk_item_rec.list_price);
      ln_discrete_cost := TO_NUMBER(i_wk_item_rec.business_price);
      lv_policy_group  := i_wk_item_rec.policy_group;
    ELSE
    -- 子品目の場合、親値継承項目(定価,営業原価,政策群)はNULLをセットします。
      ln_fixed_price   := NULL;
      ln_discrete_cost := NULL;
      lv_policy_group  := NULL;
    END IF;
-- Ver.1.5 20090224 Add END
    BEGIN
      INSERT INTO xxcmm_system_items_b_hst(
        item_hst_id
       ,item_id
       ,item_code
       ,apply_date
       ,apply_flag
       ,item_status
       ,policy_group
       ,fixed_price
       ,discrete_cost
       ,first_apply_flag
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
      ) VALUES (
        xxcmm_system_items_b_hst_s.NEXTVAL        -- 品目変更履歴ID
       ,ln_item_id                                -- 品目ID
       ,i_wk_item_rec.item_code                   -- 品目コード
       ,gd_process_date                           -- 適用日（適用開始日）
       ,cv_no                                     -- 適用有無(N固定)
       ,cn_itm_status_regist                      -- 品目ステータス(本登録固定)
-- Ver.1.5 20090224 Mod START
       ,lv_policy_group                           -- 群コード（政策群コード）
       ,ln_fixed_price                            -- 定価
       ,ln_discrete_cost                          -- 営業原価
--       ,i_wk_item_rec.policy_group                -- 群コード（政策群コード）
--       ,i_wk_item_rec.list_price                  -- 定価
--       ,i_wk_item_rec.business_price              -- 営業原価
-- Ver.1.5 20090224 Mod START
       ,cv_yes                                    -- 初回適用フラグ(Y固定)
       ,cn_created_by                             -- 作成者
       ,cd_creation_date                          -- 作成日
       ,cn_last_updated_by                        -- 最終更新者
       ,cd_last_update_date                       -- 最終更新日
       ,cn_last_update_login                      -- 最終更新ログイン
       ,cn_request_id                             -- 要求ID
       ,cn_program_application_id                 -- コンカレント・プログラムのアプリケーションID
       ,cn_program_id                             -- コンカレント・プログラムID
       ,cd_program_update_date                    -- プログラムによる更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        lv_tkn_table := cv_table_xsibh;
        RAISE ins_err_expt;   -- データ登録例外
    END;
  --
  EXCEPTION
    -- *** データ登録例外ハンドラ ***
    WHEN ins_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00407            -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => lv_tkn_table                  -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no          -- トークンコード2
                    ,iv_token_value2 => i_wk_item_rec.line_no         -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_item_code        -- トークンコード3
                    ,iv_token_value3 => i_wk_item_rec.item_code       -- トークン値3
                    ,iv_token_name4  => cv_tkn_errmsg                 -- トークンコード4
                    ,iv_token_value4 => lv_errbuf                     -- トークン値4
                   );
      -- メッセージ出力
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_data;
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : 品目一括登録ワークデータ妥当性チェック (A-4)
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_wk_item_rec  IN  xxcmm_wk_item_batch_regist%ROWTYPE                  -- 品目一括登録ワーク情報
   ,o_item_ctg_rec OUT g_item_ctg_rtype                                    -- カテゴリ情報
   ,o_etc_rec      OUT g_etc_rtype                                         -- その他情報
   ,ov_errbuf      OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_item';              -- プログラム名
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
-- Ver1.7  2009/04/10  Add  障害T1_0219 対応
    cv_uom_code_kg            CONSTANT VARCHAR2(3) := 'kg';
    cv_uom_code_l             CONSTANT VARCHAR2(3) := 'L';
-- End
--
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(10);                           -- ステップ
    lv_tkn_value              VARCHAR2(100);                          -- トークン値
    ln_cnt                    NUMBER;                                 -- カウント用
    ln_cnt_all                NUMBER;                                 -- カウント用(全件)
    ln_parent_item_status     xxcmm_system_items_b.item_status%TYPE;  -- 親品目ステータス
    lv_check_flag             VARCHAR2(1);                            -- チェックフラグ
    l_validate_item_tab       g_check_data_ttype;
    --
    l_item_ctg_rec            g_item_ctg_rtype;                       -- カテゴリ情報
    l_lookup_rec              g_lookup_rtype;                         -- LOOKUP情報
    --
    ln_opm_cost_total         cm_cmpt_dtl.cmpnt_cost%TYPE;            -- 標準原価合計値
    --
    lv_category_val           VARCHAR2(240);                          -- カテゴリ値
-- Ver1.8  2009/05/18 Add  T1_0322 子品目で商品製品区分導出時に親品目の商品製品区分と比較処理を追加
    lv_p_item_prod_class      VARCHAR2(240);                          -- 親品目 商品製品区分
-- End
-- Ver1.11  2009/06/11  Add Start
    ln_baracha_category_id     mtl_categories_b.category_id%TYPE;         -- カテゴリID（バラ茶区分）
    ln_baracha_category_set_id mtl_category_sets_b.category_set_id%TYPE;  -- カテゴリセットID（バラ茶区分）
    ln_markpg_category_id      mtl_categories_b.category_id%TYPE;         -- カテゴリID（マーケ用群コード）
    ln_markpg_category_set_id  mtl_category_sets_b.category_set_id%TYPE;  -- カテゴリセットID（マーケ用群コード）
    ln_pg_category_id          mtl_categories_b.category_id%TYPE;         -- カテゴリID（群コード）
    ln_pg_category_set_id      mtl_category_sets_b.category_set_id%TYPE;  -- カテゴリセットID（群コード）
-- Ver1.11  2009/06/11  End
    --
    ln_check_cnt              NUMBER;
    lv_required_item          VARCHAR2(2000);
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRM変数退避用
-- 2009/08/07 Ver1.14 障害0000948 add start by Y.Kuboshima
    ln_chk_stand_unit         NUMBER;                                 -- 基準単位存在チェック用変数
-- 2009/08/07 Ver1.14 障害0000948 add end by Y.Kuboshima
--
    -- *** ローカル・カーソル ***
-- Ver1.11  2009/06/11  Add Start
    -- カテゴリセットID・カテゴリID取得カーソル
    CURSOR get_categ_cur(
      pv_item_code    VARCHAR2
     ,pv_categ_name   VARCHAR2 )
    IS
      SELECT    mcv.category_id
               ,mcsv.category_set_id
      FROM      ic_item_mst_b         iimb
               ,gmi_item_categories  gic
               ,mtl_category_sets_vl mcsv
               ,mtl_categories_vl    mcv
      WHERE     iimb.item_no           = pv_item_code
      AND       mcsv.category_set_name = pv_categ_name
      AND       gic.item_id            = iimb.item_id
      AND       gic.category_set_id    = mcsv.category_set_id
      AND       gic.category_id        = mcv.category_id;
-- Ver1.11  2009/06/11  End
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- チェックフラグの初期化
    lv_check_flag := cv_status_normal;
    --
    -- カテゴリ情報初期化
    l_item_ctg_rec := NULL;
    --
    --==============================================================
    -- メイン処理LOOP
    --==============================================================
    lv_step := 'A-4.1';
    --
    l_validate_item_tab(1)  := i_wk_item_rec.line_no;                 -- 行番号
    l_validate_item_tab(2)  := i_wk_item_rec.item_code;               -- 品名コード
    l_validate_item_tab(3)  := i_wk_item_rec.item_name;               -- 正式名
    l_validate_item_tab(4)  := i_wk_item_rec.item_short_name;         -- 略称
    l_validate_item_tab(5)  := i_wk_item_rec.item_name_alt;           -- カナ名
    l_validate_item_tab(6)  := i_wk_item_rec.item_status;             -- 品目ステータス
    l_validate_item_tab(7)  := i_wk_item_rec.sales_target_flag;       -- 売上対象区分
    l_validate_item_tab(8)  := i_wk_item_rec.parent_item_code;        -- 親商品コード
    l_validate_item_tab(9)  := i_wk_item_rec.case_inc_num;            -- ケース入数
-- Ver1.8  2009/05/18 Add  T1_0906 ケース換算入数を追加
    l_validate_item_tab(10) := i_wk_item_rec.case_conv_inc_num;       -- ケース換算入数
-- End
    l_validate_item_tab(11) := i_wk_item_rec.item_um;                 -- 基準単位
    l_validate_item_tab(12) := i_wk_item_rec.item_product_class;      -- 商品製品区分
    l_validate_item_tab(13) := i_wk_item_rec.rate_class;              -- 率区分
    l_validate_item_tab(14) := i_wk_item_rec.net;                     -- NET
    l_validate_item_tab(15) := i_wk_item_rec.weight_volume;           -- 重量／体積
    l_validate_item_tab(16) := i_wk_item_rec.jan_code;                -- JANコード
    l_validate_item_tab(17) := i_wk_item_rec.nets;                    -- 内容量
    l_validate_item_tab(18) := i_wk_item_rec.nets_uom_code;           -- 内容量単位
    l_validate_item_tab(19) := i_wk_item_rec.inc_num;                 -- 内訳入数
    l_validate_item_tab(20) := i_wk_item_rec.case_jan_code;           -- ケースJANコード
    l_validate_item_tab(21) := i_wk_item_rec.hon_product_class;       -- 本社商品区分
    l_validate_item_tab(22) := i_wk_item_rec.baracha_div;             -- バラ茶区分
    l_validate_item_tab(23) := i_wk_item_rec.itf_code;                -- ITFコード
    l_validate_item_tab(24) := i_wk_item_rec.product_class;           -- 商品分類
    l_validate_item_tab(25) := i_wk_item_rec.palette_max_cs_qty;      -- 配数
    l_validate_item_tab(26) := i_wk_item_rec.palette_max_step_qty;    -- 段数
    l_validate_item_tab(27) := i_wk_item_rec.bowl_inc_num;            -- ボール入数
    l_validate_item_tab(28) := i_wk_item_rec.sale_start_date;         -- 発売開始日
    l_validate_item_tab(29) := i_wk_item_rec.vessel_group;            -- 容器群
    l_validate_item_tab(30) := i_wk_item_rec.new_item_div;            -- 新商品区分
    l_validate_item_tab(31) := i_wk_item_rec.acnt_group;              -- 経理群
    l_validate_item_tab(32) := i_wk_item_rec.acnt_vessel_group;       -- 経理容器群
    l_validate_item_tab(33) := i_wk_item_rec.brand_group;             -- ブランド群
    l_validate_item_tab(34) := i_wk_item_rec.policy_group;            -- 政策群
    l_validate_item_tab(35) := i_wk_item_rec.list_price;              -- 定価
    l_validate_item_tab(36) := i_wk_item_rec.standard_price_1;        -- 原料(標準原価)
    l_validate_item_tab(37) := i_wk_item_rec.standard_price_2;        -- 再製費(標準原価)
    l_validate_item_tab(38) := i_wk_item_rec.standard_price_3;        -- 資材費(標準原価)
    l_validate_item_tab(39) := i_wk_item_rec.standard_price_4;        -- 包装費(標準原価)
    l_validate_item_tab(40) := i_wk_item_rec.standard_price_5;        -- 外注管理費(標準原価)
    l_validate_item_tab(41) := i_wk_item_rec.standard_price_6;        -- 保管費(標準原価)
    l_validate_item_tab(42) := i_wk_item_rec.standard_price_7;        -- その他経費(標準原価)
    l_validate_item_tab(43) := i_wk_item_rec.business_price;          -- 営業原価
    l_validate_item_tab(44) := i_wk_item_rec.renewal_item_code;       -- リニューアル元商品コード
    l_validate_item_tab(45) := i_wk_item_rec.sp_supplier_code;        -- 専門店仕入先コード
    --
    -- カウンタの初期化
    ln_check_cnt := 0;
    --
    <<validate_column_loop>>
    LOOP
      EXIT WHEN ln_check_cnt >= gn_item_num;
      -- カウンタを加算
      ln_check_cnt := ln_check_cnt + 1;
-- Ver1.8  2009/05/19  バグ？？  上書きされた商品製品区分を見るよう修正
      -- クリア
      lv_p_item_prod_class := NULL;
-- End
      --
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => g_item_def_tab(ln_check_cnt).item_name                         -- 項目名称
       ,iv_item_value   => l_validate_item_tab(ln_check_cnt)                              -- 項目の値
       ,in_item_len     => g_item_def_tab(ln_check_cnt).item_length                       -- 項目の長さ(整数部分)
       ,in_item_decimal => g_item_def_tab(ln_check_cnt).decim                             -- 項目の長さ（小数点以下）
       ,iv_item_nullflg => g_item_def_tab(ln_check_cnt).item_essential                    -- 必須フラグ
       ,iv_item_attr    => g_item_def_tab(ln_check_cnt).item_attribute                    -- 項目の属性
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN                                          -- 戻り値が以上の場合
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm                          -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00403                          -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_input_line_no                        -- トークンコード1
                        ,iv_token_value1  =>  i_wk_item_rec.line_no                       -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_errmsg                               -- トークンコード2
                        ,iv_token_value2  =>  LTRIM(lv_errmsg)                            -- トークン値2
                       );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        lv_check_flag := cv_status_error;
      END IF;
    END LOOP validate_column_loop;
    --
    IF ( lv_check_flag = cv_status_normal ) THEN
      --==============================================================
      -- A-4.2 品目存在チェック
      --==============================================================
      lv_step := 'A-4.2';
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    ic_item_mst_b iimb
      WHERE   iimb.item_no = i_wk_item_rec.item_code
      AND     ROWNUM       = 1
      ;
      -- 処理結果チェック
      IF ( ln_cnt > 0 ) THEN
        -- マスタ存在チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00404          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input_line_no        -- トークンコード1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- トークン値1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- トークン値2
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.3 品目重複チェック
      --==============================================================
      lv_step := 'A-4.3';
      SELECT  COUNT(1)
             ,COUNT(DISTINCT xwibr.item_code)
      INTO    ln_cnt_all
             ,ln_cnt
      FROM    xxcmm_wk_item_batch_regist xwibr
      WHERE   xwibr.item_code = i_wk_item_rec.item_code
      AND     xwibr.request_id = cn_request_id
      ;
      -- 処理結果チェック
      IF ( ln_cnt_all <> ln_cnt ) THEN
        -- 品目重複エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00405          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input_line_no        -- トークンコード1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- トークン値1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- トークン値2
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.4 子品目時、親品目ステータスチェック
      --==============================================================
      lv_step := 'A-4.4';
      -- 子品目時
      IF ( i_wk_item_rec.item_code <> i_wk_item_rec.parent_item_code ) THEN
        -- 親品目ステータス抽出
        SELECT  xsib.item_status
        INTO    ln_parent_item_status
        FROM    ic_item_mst_b        iimb
               ,xxcmm_system_items_b xsib
        WHERE   iimb.item_no = xsib.item_code
        AND     iimb.item_no = i_wk_item_rec.parent_item_code
        ;
        -- 処理結果チェック
        IF ( NVL( ln_parent_item_status, cn_itm_status_num_tmp ) <> cn_itm_status_regist ) THEN
          -- 親品目ステータスエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm        -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00406        -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input_line_no      -- トークンコード1
                        ,iv_token_value1 => i_wk_item_rec.line_no     -- トークン値1
                        ,iv_token_name2  => cv_tkn_input_item_code    -- トークンコード2
                        ,iv_token_value2 => i_wk_item_rec.item_code   -- トークン値2
                        ,iv_token_name3  => cv_tkn_item_status        -- トークンコード3
                        ,iv_token_value3 => ln_parent_item_status     -- トークン値3
                       );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.5 親品目必須チェック
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify start by Shigeto.Niki
--      -- 売上対象,ケース入数,基準単位,商品製品区分,率区分,NET,重量／体積,
      -- 売上対象,ケース入数,基準単位,商品製品区分,率区分,      
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 modify end by Shigeto.Niki
      -- 内容量,内容量単位,内訳入数,本社商品区分,バラ茶区分,
      -- 政策群,定価,標準原価,営業原価
      --==============================================================
      lv_step := 'A-4.5';
      --
      -- 初期化
      lv_required_item := NULL;
      --
      -- 親品目時
      IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
        -- 売上対象区分
        IF ( i_wk_item_rec.sales_target_flag IS NULL ) THEN
          lv_required_item := cv_sales_target_flag;
        END IF;
        --
        -- ケース入数
        IF ( i_wk_item_rec.case_inc_num IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_case_inc_num;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_case_inc_num;
          END IF;
-- 2009/10/14 障害0001370 add start by Y.Kuboshima
        -- ケース入数が0以下の場合
        ELSIF ( i_wk_item_rec.case_inc_num < 1 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm           -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00493           -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                 -- トークンコード1
                        ,iv_token_value1 => cv_case_inc_num              -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                 -- トークンコード2
                        ,iv_token_value2 => i_wk_item_rec.case_inc_num   -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no         -- トークンコード3
                        ,iv_token_value3 => i_wk_item_rec.line_no        -- トークン値3
                        ,iv_token_name4  => cv_tkn_input_item_code       -- トークンコード4
                        ,iv_token_value4 => i_wk_item_rec.item_code      -- トークン値4
                       );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
-- 2009/10/14 障害0001370 add end by Y.Kuboshima
        END IF;
        --
-- 2009/10/14 障害0001370 add start by Y.Kuboshima
        -- ケース換算入数
        -- ケース換算入数がNOT NULLかつ、0以下の場合
        -- ※ケース換算入数がNULLの場合は自動計算されるため、エラーチェックはNOT NULLの場合のみ
        IF    ( i_wk_item_rec.case_conv_inc_num  IS NOT NULL)
          AND ( i_wk_item_rec.case_conv_inc_num < 1 )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm              -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00493              -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                    -- トークンコード1
                        ,iv_token_value1 => cv_case_conv_inc_num            -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                    -- トークンコード2
                        ,iv_token_value2 => i_wk_item_rec.case_conv_inc_num -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no            -- トークンコード3
                        ,iv_token_value3 => i_wk_item_rec.line_no           -- トークン値3
                        ,iv_token_name4  => cv_tkn_input_item_code          -- トークンコード4
                        ,iv_token_value4 => i_wk_item_rec.item_code         -- トークン値4
                       );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
-- 2009/10/14 障害0001370 add end by Y.Kuboshima
        --
        -- 基準単位
        IF ( i_wk_item_rec.item_um IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_item_um;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_item_um;
          END IF;
        END IF;
        --
        -- 商品製品区分
        IF ( i_wk_item_rec.item_product_class IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_item_product_class;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_item_product_class;
          END IF;
        END IF;
        --
        -- 率区分
        IF ( i_wk_item_rec.rate_class IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_rate_class;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_rate_class;
          END IF;
        END IF;
        --
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--        -- 重量／体積
--        IF ( i_wk_item_rec.weight_volume IS NULL ) THEN
--          IF ( lv_required_item IS NULL ) THEN
--            lv_required_item := cv_weight_volume;
--          ELSE
--            lv_required_item := lv_required_item || cv_msg_comma_double || cv_weight_volume;
--          END IF;
---- 2009/10/14 障害0001370 add start by Y.Kuboshima
--        -- 重量／体積が0以下の場合
--        ELSIF ( i_wk_item_rec.weight_volume < 1 ) THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm           -- アプリケーション短縮名
--                        ,iv_name         => cv_msg_xxcmm_00493           -- メッセージコード
--                        ,iv_token_name1  => cv_tkn_input                 -- トークンコード1
--                        ,iv_token_value1 => cv_weight_volume             -- トークン値1
--                        ,iv_token_name2  => cv_tkn_value                 -- トークンコード2
--                        ,iv_token_value2 => i_wk_item_rec.weight_volume  -- トークン値2
--                        ,iv_token_name3  => cv_tkn_input_line_no         -- トークンコード3
--                        ,iv_token_value3 => i_wk_item_rec.line_no        -- トークン値3
--                        ,iv_token_name4  => cv_tkn_input_item_code       -- トークンコード4
--                        ,iv_token_value4 => i_wk_item_rec.item_code      -- トークン値4
--                       );
--          -- メッセージ出力
--          xxcmm_004common_pkg.put_message(
--            iv_message_buff => lv_errmsg
--           ,ov_errbuf       => lv_errbuf
--           ,ov_retcode      => lv_retcode
--           ,ov_errmsg       => lv_errmsg
--          );
--          lv_check_flag := cv_status_error;
---- 2009/10/14 障害0001370 add end by Y.Kuboshima
--        END IF;
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
        --
        -- 内容量
        IF ( i_wk_item_rec.nets IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_nets;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_nets;
          END IF;
-- 2009/10/14 障害0001370 add start by Y.Kuboshima
        -- 内容量が0以下の場合
        ELSIF ( i_wk_item_rec.nets < 1 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm           -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00493           -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                 -- トークンコード1
                        ,iv_token_value1 => cv_nets                      -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                 -- トークンコード2
                        ,iv_token_value2 => i_wk_item_rec.nets           -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no         -- トークンコード3
                        ,iv_token_value3 => i_wk_item_rec.line_no        -- トークン値3
                        ,iv_token_name4  => cv_tkn_input_item_code       -- トークンコード4
                        ,iv_token_value4 => i_wk_item_rec.item_code      -- トークン値4
                       );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
-- 2009/10/14 障害0001370 add end by Y.Kuboshima
        END IF;
        --
        -- 内容量単位
        IF ( i_wk_item_rec.nets_uom_code IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_nets_uom_code;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_nets_uom_code;
          END IF;
        END IF;
        --
        -- 内訳入数
        IF ( i_wk_item_rec.inc_num IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_inc_num;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_inc_num;
          END IF;
-- 2009/10/14 障害0001370 add start by Y.Kuboshima
        -- 内訳入数が0以下の場合
        ELSIF ( i_wk_item_rec.inc_num < 1 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm           -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00493           -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                 -- トークンコード1
                        ,iv_token_value1 => cv_inc_num                   -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                 -- トークンコード2
                        ,iv_token_value2 => i_wk_item_rec.inc_num        -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no         -- トークンコード3
                        ,iv_token_value3 => i_wk_item_rec.line_no        -- トークン値3
                        ,iv_token_name4  => cv_tkn_input_item_code       -- トークンコード4
                        ,iv_token_value4 => i_wk_item_rec.item_code      -- トークン値4
                       );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
-- 2009/10/14 障害0001370 add end by Y.Kuboshima
        END IF;
        --
-- Ver1.7  2009/04/10  Add  障害T1_0219 対応
        -- NET（最大8桁）
        IF  ( i_wk_item_rec.nets_uom_code IN ( cv_uom_code_kg, cv_uom_code_l ))
        AND ( i_wk_item_rec.net IS NULL ) THEN
          -- 内容量単位が'KG'、'L'の場合、*1000する必要があるため、
          -- NET(6桁)をオーバーしないかチェック（5桁をオーバーしなければ最大8桁に収まる）
          IF ( TRUNC( NVL( i_wk_item_rec.nets, 0 ) * NVL( i_wk_item_rec.inc_num, 0 ) ) >= 100000 ) THEN
            -- 内容量、内訳入数 ともに設定されている場合、NET桁数エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm           -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmm_00428           -- メッセージコード
                          ,iv_token_name1  => cv_tkn_input_line_no         -- トークンコード1
                          ,iv_token_value1 => i_wk_item_rec.line_no        -- トークン値1
                          ,iv_token_name2  => cv_tkn_input_item_code       -- トークンコード2
                          ,iv_token_value2 => i_wk_item_rec.item_code      -- トークン値2
                          ,iv_token_name3  => cv_tkn_nets_uom_code         -- トークンコード3
                          ,iv_token_value3 => i_wk_item_rec.nets_uom_code  -- トークン値3
                          ,iv_token_name4  => cv_tkn_nets                  -- トークンコード4
                          ,iv_token_value4 => i_wk_item_rec.nets           -- トークン値4
                          ,iv_token_name5  => cv_tkn_inc_num               -- トークンコード5
                          ,iv_token_value5 => i_wk_item_rec.inc_num        -- トークン値5
                         );
            -- メッセージ出力
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
          END IF;
-- 2009/10/14 障害0001370 add start by Y.Kuboshima
        -- NETがNOT NULLかつ、0以下の場合
        -- ※NETがNULLの場合は自動計算されるため、エラーチェックはNOT NULLの場合のみ
        ELSIF ( i_wk_item_rec.net IS NOT NULL )
          AND ( i_wk_item_rec.net < 1 )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm           -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00493           -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                 -- トークンコード1
                        ,iv_token_value1 => cv_net                       -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                 -- トークンコード2
                        ,iv_token_value2 => i_wk_item_rec.net            -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no         -- トークンコード3
                        ,iv_token_value3 => i_wk_item_rec.line_no        -- トークン値3
                        ,iv_token_name4  => cv_tkn_input_item_code       -- トークンコード4
                        ,iv_token_value4 => i_wk_item_rec.item_code      -- トークン値4
                       );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
-- 2009/10/14 障害0001370 add end by Y.Kuboshima
        END IF;
-- End
-- 2010/01/06 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
---- 2009/10/14 障害0001370 add start by Y.Kuboshima
--        -- 配数
--        -- 配数がNOT NULLかつ、0以下の場合
--        -- ※配数のNULLチェックは後続で行うため、ここではNULLチェックは行わない
--        IF    ( i_wk_item_rec.palette_max_cs_qty  IS NOT NULL)
--          AND ( i_wk_item_rec.palette_max_cs_qty < 1 )
---- 2009/12/07 Ver1.17 E_本稼動_00358 add start by Y.Kuboshima
--          -- 本社商品区分が「2：ドリンク」の場合の条件追加
--          AND ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink)
---- 2009/12/07 Ver1.17 E_本稼動_00358 add end by Y.Kuboshima
--        THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm               -- アプリケーション短縮名
--                        ,iv_name         => cv_msg_xxcmm_00493               -- メッセージコード
--                        ,iv_token_name1  => cv_tkn_input                     -- トークンコード1
--                        ,iv_token_value1 => cv_pale_max_cs_qty               -- トークン値1
--                        ,iv_token_name2  => cv_tkn_value                     -- トークンコード2
--                        ,iv_token_value2 => i_wk_item_rec.palette_max_cs_qty -- トークン値2
--                        ,iv_token_name3  => cv_tkn_input_line_no             -- トークンコード3
--                        ,iv_token_value3 => i_wk_item_rec.line_no            -- トークン値3
--                        ,iv_token_name4  => cv_tkn_input_item_code           -- トークンコード4
--                        ,iv_token_value4 => i_wk_item_rec.item_code          -- トークン値4
--                       );
--          -- メッセージ出力
--          xxcmm_004common_pkg.put_message(
--            iv_message_buff => lv_errmsg
--           ,ov_errbuf       => lv_errbuf
--           ,ov_retcode      => lv_retcode
--           ,ov_errmsg       => lv_errmsg
--          );
--          lv_check_flag := cv_status_error;
--        END IF;
--        --
--        -- 段数
--        -- 段数がNOT NULLかつ、0以下の場合
--        -- ※段数のNULLチェックは後続で行うため、ここではNULLチェックは行わない
--        IF    ( i_wk_item_rec.palette_max_step_qty  IS NOT NULL)
--          AND ( i_wk_item_rec.palette_max_step_qty < 1 )
---- 2009/12/07 Ver1.17 E_本稼動_00358 add start by Y.Kuboshima
--          -- 本社商品区分が「2：ドリンク」の場合の条件追加
--          AND ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink)
---- 2009/12/07 Ver1.17 E_本稼動_00358 add end by Y.Kuboshima
--        THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm                 -- アプリケーション短縮名
--                        ,iv_name         => cv_msg_xxcmm_00493                 -- メッセージコード
--                        ,iv_token_name1  => cv_tkn_input                       -- トークンコード1
--                        ,iv_token_value1 => cv_pale_max_step_qty               -- トークン値1
--                        ,iv_token_name2  => cv_tkn_value                       -- トークンコード2
--                        ,iv_token_value2 => i_wk_item_rec.palette_max_step_qty -- トークン値2
--                        ,iv_token_name3  => cv_tkn_input_line_no               -- トークンコード3
--                        ,iv_token_value3 => i_wk_item_rec.line_no              -- トークン値3
--                        ,iv_token_name4  => cv_tkn_input_item_code             -- トークンコード4
--                        ,iv_token_value4 => i_wk_item_rec.item_code            -- トークン値4
--                       );
--          -- メッセージ出力
--          xxcmm_004common_pkg.put_message(
--            iv_message_buff => lv_errmsg
--           ,ov_errbuf       => lv_errbuf
--           ,ov_retcode      => lv_retcode
--           ,ov_errmsg       => lv_errmsg
--          );
--          lv_check_flag := cv_status_error;
--        END IF;
---- 2009/10/14 障害0001370 add end by Y.Kuboshima
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
        --
        -- 本社商品区分
        IF ( i_wk_item_rec.hon_product_class IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_hon_product_class;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_hon_product_class;
          END IF;
        END IF;
        --
        -- バラ茶区分
        IF ( i_wk_item_rec.baracha_div IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_baracha_div;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_baracha_div;
          END IF;
        END IF;
        --
        -- 政策群
        IF ( i_wk_item_rec.policy_group IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_policy_group;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_policy_group;
          END IF;
        END IF;
        --
        -- 定価
        IF ( i_wk_item_rec.list_price IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_list_price;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_list_price;
          END IF;
        END IF;
        --
        -- 標準原価(原料,再製費,資材費,包装費,外注管理費,保管費,その他経費)全てNULLの場合
        IF (  ( i_wk_item_rec.standard_price_1 IS NULL )
          AND ( i_wk_item_rec.standard_price_2 IS NULL )
          AND ( i_wk_item_rec.standard_price_3 IS NULL )
          AND ( i_wk_item_rec.standard_price_4 IS NULL )
          AND ( i_wk_item_rec.standard_price_5 IS NULL )
          AND ( i_wk_item_rec.standard_price_6 IS NULL )
          AND ( i_wk_item_rec.standard_price_7 IS NULL )) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_standard_price;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_standard_price;
          END IF;
        END IF;
        --
        -- 営業原価
        IF ( i_wk_item_rec.business_price IS NULL ) THEN
          IF ( lv_required_item IS NULL ) THEN
            lv_required_item := cv_business_price;
          ELSE
            lv_required_item := lv_required_item || cv_msg_comma_double || cv_business_price;
          END IF;
        END IF;
        --
        IF ( lv_required_item IS NOT NULL ) THEN
          -- 親品目必須エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00419          -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input_line_no        -- トークンコード1
                        ,iv_token_value1 => i_wk_item_rec.line_no       -- トークン値1
                        ,iv_token_name2  => cv_tkn_input_col_name       -- トークンコード2
                        ,iv_token_value2 => lv_required_item            -- トークン値2
                       );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.6 品名コードチェック
      --==============================================================
      lv_step := 'A-4.6.1';
      -- 品名コード7桁必須チェック
      IF ( LENGTHB( i_wk_item_rec.item_code ) <> 7 ) THEN
        -- 品名コード7桁必須エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00410          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input_line_no        -- トークンコード1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- トークン値1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- トークン値2
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      lv_step := 'A-4.6.2';
      -- 品名コード区分チェック
-- Ver1.8  2009/05/18 Add  T1_0317 '5'、'6'を登録可能に変更
--      IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1 ) NOT IN ( '0', '1', '2', '3' ) ) THEN
      IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1 ) NOT IN ( '0', '1', '2', '3', '5', '6' ) ) THEN
-- End
        -- 品名コード区分エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00411          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input_line_no        -- トークンコード1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- トークン値1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- トークン値2
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      lv_step := 'A-4.6.3';
      IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1) IN ( '0', '1' ) )
        AND ( SUBSTRB( i_wk_item_rec.item_code, 1, 2) NOT IN ( '00', '10' ) ) THEN
        -- 品名コード区分エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00411          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input_line_no        -- トークンコード1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- トークン値1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- トークン値2
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
-- 2009/06/04 Ver1.10 障害T1_1319 Add start
      lv_step := 'A-4.6.4';
      IF ( xxccp_common_pkg.chk_number( i_wk_item_rec.item_code ) <> TRUE ) THEN
        -- 品名コード数値エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00474          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input_line_no        -- トークンコード1
                      ,iv_token_value1 => i_wk_item_rec.line_no       -- トークン値1
                      ,iv_token_name2  => cv_tkn_input_item_code      -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.item_code     -- トークン値2
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
-- 2009/06/04 Ver1.10 障害T1_1319 End
--
      --==============================================================
      -- A-4.7 正式名チェック
      --==============================================================
      lv_step := 'A-4.7';
      -- 全角チェック
      IF ( xxccp_common_pkg.chk_double_byte( i_wk_item_rec.item_name ) <> TRUE ) THEN
        -- 全角チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00412          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                -- トークンコード1
                      ,iv_token_value1 => cv_item_name                -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.item_name     -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no        -- トークンコード3
                      ,iv_token_value3 => i_wk_item_rec.line_no       -- トークン値3
                      ,iv_token_name4  => cv_tkn_input_item_code      -- トークンコード4
                      ,iv_token_value4 => i_wk_item_rec.item_code     -- トークン値4
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.8 略称チェック
      --==============================================================
      lv_step := 'A-4.8';
      -- 全角チェック
      IF ( xxccp_common_pkg.chk_double_byte( i_wk_item_rec.item_short_name ) <> TRUE ) THEN
        -- 全角チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00412                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_item_name                          -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.item_short_name         -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_item_rec.line_no                 -- トークン値3
                      ,iv_token_name4  => cv_tkn_input_item_code                -- トークンコード4
                      ,iv_token_value4 => i_wk_item_rec.item_code               -- トークン値4
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.9 カナチェック
      --==============================================================
      lv_step := 'A-4.9';
      -- 半角チェック
-- Ver1.7  2009/04/10  Mod  障害T1_0215 対応
--ito->※最終的にはxxccp_common_pkgになる予定
--      IF ( xxcmm_004common_pkg.chk_single_byte( i_wk_item_rec.item_name_alt ) <> TRUE ) THEN
      IF ( xxccp_common_pkg.chk_single_byte( i_wk_item_rec.item_name_alt ) <> TRUE ) THEN
-- End
        -- 半角チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00413                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_item_name_alt                      -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.item_name_alt           -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_wk_item_rec.line_no                 -- トークン値3
                      ,iv_token_name4  => cv_tkn_input_item_code                -- トークンコード4
                      ,iv_token_value4 => i_wk_item_rec.item_code               -- トークン値4
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 add start by Shigeto.Niki
      --==============================================================
      -- A-4.10 ITFコードチェック
      --==============================================================
      lv_step := 'A-4.10';
      -- 半角チェック
      IF ( xxccp_common_pkg.chk_single_byte( i_wk_item_rec.itf_code ) <> TRUE ) THEN
        -- 半角チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                  -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00413                  -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                        -- トークンコード1
                      ,iv_token_value1 => cv_itf_code                         -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                        -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.itf_code              -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                -- トークンコード3
                      ,iv_token_value3 => i_wk_item_rec.line_no               -- トークン値3
                      ,iv_token_name4  => cv_tkn_input_item_code              -- トークンコード4
                      ,iv_token_value4 => i_wk_item_rec.item_code             -- トークン値4
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.11 商品分類チェック
      -- 本登録時必須項目ではないため、値が入っている場合チェックを行います。
      --==============================================================
      lv_step := 'A-4.11';
      IF ( i_wk_item_rec.product_class IS NOT NULL ) THEN
        -- LOOKUP表存在チェック
        -- 初期化
        l_lookup_rec := NULL;
        l_lookup_rec.lookup_type := cv_lookup_product_class;
        l_lookup_rec.lookup_code := i_wk_item_rec.product_class;
        l_lookup_rec.line_no     := i_wk_item_rec.line_no;
        l_lookup_rec.item_code   := i_wk_item_rec.item_code;
        -- LOOKUP表存在チェック
        chk_exists_lookup(
          io_lookup_rec => l_lookup_rec
         ,ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        );
        -- 処理結果チェック
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.12 配数、段数チェック
      --==============================================================
      lv_step := 'A-4.12.1';
      IF ( i_wk_item_rec.hon_product_class IS NOT NULL ) THEN
        -- 本社商品区分が「2:ドリンク」の場合、配数、段数は必須となります。
        IF ( TO_NUMBER(i_wk_item_rec.hon_product_class) = cn_hon_prod_drink ) THEN
          -- 配数,段数
          IF (( i_wk_item_rec.palette_max_cs_qty IS NULL )
            OR ( i_wk_item_rec.palette_max_step_qty IS NULL )) THEN
            -- 本社商品区分ドリンク時必須エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                        -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmm_00416                        -- メッセージコード
                          ,iv_token_name1  => cv_tkn_input_line_no                      -- トークンコード1
                          ,iv_token_value1 => i_wk_item_rec.line_no                     -- トークン値1
                          ,iv_token_name2  => cv_tkn_input_item_code                    -- トークンコード2
                          ,iv_token_value2 => i_wk_item_rec.item_code                   -- トークン値2
                          ,iv_token_name3  => cv_tkn_cs_qty                             -- トークンコード3
                          ,iv_token_value3 => i_wk_item_rec.palette_max_cs_qty          -- トークン値3
                          ,iv_token_name4  => cv_tkn_step_qty                           -- トークンコード4
                          ,iv_token_value4 => i_wk_item_rec.palette_max_step_qty        -- トークン値4
                         );
            -- メッセージ出力
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
      END IF;
      --
      lv_step := 'A-4.12.2';
      -- 配数
      -- 配数がNOT NULLかつ、0以下の場合
      -- ※配数のNULLチェックは後続で行うため、ここではNULLチェックは行わない
      IF    ( i_wk_item_rec.palette_max_cs_qty  IS NOT NULL)
        AND ( i_wk_item_rec.palette_max_cs_qty < 1 )
        AND ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink)
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm               -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00493               -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                     -- トークンコード1
                      ,iv_token_value1 => cv_pale_max_cs_qty               -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                     -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.palette_max_cs_qty -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no             -- トークンコード3
                      ,iv_token_value3 => i_wk_item_rec.line_no            -- トークン値3
                      ,iv_token_name4  => cv_tkn_input_item_code           -- トークンコード4
                      ,iv_token_value4 => i_wk_item_rec.item_code          -- トークン値4
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      -- 段数
      -- 段数がNOT NULLかつ、0以下の場合
      -- ※段数のNULLチェックは後続で行うため、ここではNULLチェックは行わない
      IF    ( i_wk_item_rec.palette_max_step_qty  IS NOT NULL)
        AND ( i_wk_item_rec.palette_max_step_qty < 1 )
        AND ( i_wk_item_rec.hon_product_class = cn_hon_prod_drink)
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                 -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00493                 -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                       -- トークンコード1
                      ,iv_token_value1 => cv_pale_max_step_qty               -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                       -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.palette_max_step_qty -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no               -- トークンコード3
                      ,iv_token_value3 => i_wk_item_rec.line_no              -- トークン値3
                      ,iv_token_name4  => cv_tkn_input_item_code             -- トークンコード4
                      ,iv_token_value4 => i_wk_item_rec.item_code            -- トークン値4
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.13 重量／体積チェック
      --==============================================================
      lv_step := 'A-4.13';
      IF ( i_wk_item_rec.weight_volume IS NULL ) THEN
        IF ( lv_required_item IS NULL ) THEN
          lv_required_item := cv_weight_volume;
        ELSE
          lv_required_item := lv_required_item || cv_msg_comma_double || cv_weight_volume;
        END IF;
      -- 重量／体積が0以下の場合
      ELSIF ( i_wk_item_rec.weight_volume < 1 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm           -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00493           -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                 -- トークンコード1
                      ,iv_token_value1 => cv_weight_volume             -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                 -- トークンコード2
                      ,iv_token_value2 => i_wk_item_rec.weight_volume  -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no         -- トークンコード3
                      ,iv_token_value3 => i_wk_item_rec.line_no        -- トークン値3
                      ,iv_token_name4  => cv_tkn_input_item_code       -- トークンコード4
                      ,iv_token_value4 => i_wk_item_rec.item_code      -- トークン値4
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 add end by Shigeto.Niki
      --
-- Ver1.8  2009/05/18 Add  T1_0317 品目コード先頭１バイトが'5'または'6'の場合、2:製品 を設定
--                         T1_0322 子品目で商品製品区分導出時に親品目の商品製品区分との比較処理を追加
      --==============================================================
      -- A-4.16 商品製品区分チェック
      -- 親品目時チェック(子品目は親値継承)
      -- 2009/05/15 追記
      --  子品目は親値を継承させるが、ルール通り設定される必要あり
      --  導出した商品製品区分と親品目の商品製品区分が異なる場合エラーとする
      --==============================================================
      lv_step := 'A-4.16';
      -- 品目コード体系で商品製品区分値を変更します。
      IF ( SUBSTRB(i_wk_item_rec.item_code, 1, 2 ) = '00' ) THEN
        lv_category_val := TO_CHAR(cn_item_prod_prod);
      ELSIF ( SUBSTRB(i_wk_item_rec.item_code, 1, 2 ) = '10' ) THEN
        lv_category_val := TO_CHAR(cn_item_prod_item);
      -- 品目コード先頭１バイトが'5'または'6'の場合、2:製品 を設定
      ELSIF ( SUBSTRB(i_wk_item_rec.item_code, 1, 1 ) IN ( '5', '6' ) ) THEN
        lv_category_val := TO_CHAR(cn_item_prod_prod);
      ELSE
        lv_category_val := NULL;
      END IF;
-- End
      --
      --==============================================================
      -- 親品目時
      -- 子品目の場合、親値継承項目はチェックしません。
      --==============================================================
      IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
        --==============================================================
        -- A-4.14 売上対象チェック
        -- 親品目時チェック(子品目は無条件で「0:売上対象外」となるためチェックしません。)
        --==============================================================
        lv_step := 'A-4.14.1';
        IF ( i_wk_item_rec.sales_target_flag IS NOT NULL ) THEN
          -- 初期化
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_sales_target;
          l_lookup_rec.lookup_code := i_wk_item_rec.sales_target_flag;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP表存在チェック
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
          --
          lv_step := 'A-4.14.2';
          -- 売上対象のLOOKUP表存在時
          IF ( lv_retcode = cv_status_normal ) THEN
            -- 売上対象が「1:売上対象」の場合、率区分が「1:率計算」はエラーチェック
            IF ( i_wk_item_rec.sales_target_flag = cv_sales_target_1 ) THEN
              IF ( i_wk_item_rec.rate_class = cn_rate_class_1 ) THEN
                -- 売上対象時率区分エラー
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                              ,iv_name         => cv_msg_xxcmm_00414            -- メッセージコード
                              ,iv_token_name1  => cv_tkn_input_line_no          -- トークンコード1
                              ,iv_token_value1 => i_wk_item_rec.line_no         -- トークン値1
                              ,iv_token_name2  => cv_tkn_input_item_code        -- トークンコード2
                              ,iv_token_value2 => i_wk_item_rec.item_code       -- トークン値2
                             );
                -- メッセージ出力
                xxcmm_004common_pkg.put_message(
                  iv_message_buff => lv_errmsg
                 ,ov_errbuf       => lv_errbuf
                 ,ov_retcode      => lv_retcode
                 ,ov_errmsg       => lv_errmsg
                );
                lv_check_flag := cv_status_error;
              END IF;
            END IF;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.15 基準単位チェック
        -- 親品目時チェック(子品目は親値継承)
        --==============================================================
        lv_step := 'A-4.15';
        IF ( i_wk_item_rec.item_um IS NOT NULL ) THEN
-- 2009/09/07 Ver1.15 障害0000948 modify start by Y.Kuboshima
--          -- 本、kg以外はエラー
--          IF ( i_wk_item_rec.item_um NOT IN ( cn_item_um_hon, cn_item_um_kg ) ) THEN
          -- 基準単位追加のため、LOOKUP(XXCMM_UNITS_OF_MEASURE)に存在しない場合エラーとするように修正
          -- 基準単位存在チェック
          SELECT COUNT(1)
          INTO   ln_chk_stand_unit
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type  = cv_lookup_units_of_measure
            AND  flvv.enabled_flag = cv_yes
            AND  flvv.meaning      = i_wk_item_rec.item_um;
          -- 基準単位が存在しない場合
          IF ( ln_chk_stand_unit = 0 ) THEN
-- 2009/09/07 Ver1.15 障害0000948 modify end by Y.Kuboshima
            -- 基準単位エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmm_00415                -- メッセージコード
                          ,iv_token_name1  => cv_tkn_item_um                    -- トークンコード1
                          ,iv_token_value1 => i_wk_item_rec.item_um             -- トークン値1
                          ,iv_token_name2  => cv_tkn_input_line_no              -- トークンコード2
                          ,iv_token_value2 => i_wk_item_rec.line_no             -- トークン値2
                          ,iv_token_name3  => cv_tkn_input_item_code            -- トークンコード3
                          ,iv_token_value3 => i_wk_item_rec.item_code           -- トークン値3
                         );
            -- メッセージ出力
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
-- Ver1.8  2009/05/18 Del  T1_0322 子品目時も製品商品区分を導出するよう修正のため削除
        --==============================================================
        -- A-4.12 商品製品区分チェック
        -- 親品目時チェック(子品目は親値継承)
        --=============================================================
--      導出処理は、親品目用チェック処理の前に移動しました。
--        lv_step := 'A-4.12';
--        IF ( i_wk_item_rec.item_product_class IS NOT NULL ) THEN
--          -- 商品製品区分情報を変数にセット
--          l_item_ctg_rec.category_set_name := cv_categ_set_item_prod;
----20090212 Mod START
--          -- 品目コード体系で商品製品区分値を変更します。
--          IF ( SUBSTRB(i_wk_item_rec.item_code, 1, 2 ) = '00' ) THEN
--            lv_category_val := TO_CHAR(cn_item_prod_prod);
--          ELSIF ( SUBSTRB(i_wk_item_rec.item_code, 1, 2 ) = '10' ) THEN
--            lv_category_val := TO_CHAR(cn_item_prod_item);
---- Ver1.4 20090218 Mod START
--          ELSE
--            lv_category_val := i_wk_item_rec.item_product_class;
---- Ver1.4 20090218 Mod END
--          END IF;
--
-- End
--
-- Ver1.8  2009/05/18 Add  T1_0322 商品製品区分未導出時の処理を追加
          IF ( lv_category_val IS NULL ) THEN
            lv_category_val := i_wk_item_rec.item_product_class;
          END IF;
          --
          l_item_ctg_rec.category_set_name := cv_categ_set_item_prod;
-- End
--          l_item_ctg_rec.category_val      := i_wk_item_rec.item_product_class;
          l_item_ctg_rec.category_val      := lv_category_val;
-- Ver1.8  2009/05/19  バグ？？  上書きされた商品製品区分を見るよう修正
          -- 商品製品区分値を設定
          lv_p_item_prod_class             := lv_category_val;
-- End

--20090212 Mod END
          l_item_ctg_rec.line_no           := i_wk_item_rec.line_no;
          l_item_ctg_rec.item_code         := i_wk_item_rec.item_code;
          --
          -- カテゴリ存在チェック
          chk_exists_category(
            io_item_ctg_rec => l_item_ctg_rec
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
-- Ver1.8  2009/05/18 Del  T1_0322 削除
--        END IF;
-- End
        --
        --==============================================================
        -- A-4.17 率区分チェック
        -- 親品目時チェック(子品目は親値継承)
        --==============================================================
        lv_step := 'A-4.17';
        IF ( i_wk_item_rec.rate_class IS NOT NULL ) THEN
          -- LOOKUP表存在チェック
          -- 初期化
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_rate_class;
          l_lookup_rec.lookup_code := i_wk_item_rec.rate_class;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP表存在チェック
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.18 内容量単位チェック
        -- 親品目時チェック(子品目は親値継承)
        --==============================================================
        lv_step := 'A-4.18';
        IF ( i_wk_item_rec.nets_uom_code IS NOT NULL ) THEN
          -- LOOKUP表存在チェック
          -- 初期化
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_nets_uom_code;
          l_lookup_rec.meaning     := i_wk_item_rec.nets_uom_code;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP表存在チェック
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          ELSE
            -- 内容量単位を戻します。(親品目の場合のみ値が入っている状態)
            o_etc_rec.nets_uom_code := l_lookup_rec.lookup_code;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.19 本社商品区分チェック
        -- 親品目時チェック(子品目は親値継承)
        --==============================================================
        lv_step := 'A-4.19';        
        IF ( i_wk_item_rec.hon_product_class IS NOT NULL ) THEN
          -- 本社商品区分情報を変数にセット
          l_item_ctg_rec.category_set_name := cv_categ_set_hon_prod;
          l_item_ctg_rec.category_val      := i_wk_item_rec.hon_product_class;
          -- カテゴリ存在チェック
          chk_exists_category(
            io_item_ctg_rec => l_item_ctg_rec
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.20 バラ茶区分チェック
        -- 親品目時チェック(子品目は親値継承)
        -- 本社商品区分「1:リーフ」の場合チェックします。※「2:ドリンク」の場合は「0:その他」をセットします。
        --==============================================================
        lv_step := 'A-4.20';
        IF ( i_wk_item_rec.hon_product_class IS NOT NULL ) THEN
          IF ( TO_NUMBER(i_wk_item_rec.hon_product_class) = cn_hon_prod_leaf ) THEN
            IF ( i_wk_item_rec.baracha_div IS NOT NULL ) THEN
              -- LOOKUP表存在チェック
              -- 初期化
              l_lookup_rec := NULL;
              l_lookup_rec.lookup_type := cv_lookup_barachakubun;
              l_lookup_rec.lookup_code := i_wk_item_rec.baracha_div;
              l_lookup_rec.line_no     := i_wk_item_rec.line_no;
              l_lookup_rec.item_code   := i_wk_item_rec.item_code;
              -- LOOKUP表存在チェック
              chk_exists_lookup(
                io_lookup_rec => l_lookup_rec
               ,ov_errbuf     => lv_errbuf
               ,ov_retcode    => lv_retcode
               ,ov_errmsg     => lv_errmsg
              );
              -- 処理結果チェック
              IF ( lv_retcode <> cv_status_normal ) THEN
                lv_check_flag := cv_status_error;
              END IF;
            END IF;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.21 JANコードチェック
        -- 親品目時チェック(子品目は親値継承)
        --==============================================================
        lv_step := 'A-4.21';
        -- 半角チェック
-- Ver1.7  2009/04/10  Mod  障害T1_0215 対応
--ito->※最終的にはxxccp_common_pkgになる予定
--        IF ( xxcmm_004common_pkg.chk_single_byte( i_wk_item_rec.jan_code ) <> TRUE ) THEN
        IF ( xxccp_common_pkg.chk_single_byte( i_wk_item_rec.jan_code ) <> TRUE ) THEN
-- End
          -- 半角チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00413                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                        ,iv_token_value1 => cv_jan_code                           -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                        ,iv_token_value2 => i_wk_item_rec.jan_code                -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                        ,iv_token_value3 => i_wk_item_rec.line_no                 -- トークン値3
                        ,iv_token_name4  => cv_tkn_input_item_code                -- トークンコード4
                        ,iv_token_value4 => i_wk_item_rec.item_code               -- トークン値4
                       );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
        --
        --==============================================================
        -- A-4.22 ケースJANコードチェック
        -- 親品目時チェック(子品目は親値継承)
        --==============================================================
        lv_step := 'A-4.22';
        -- 半角チェック
-- Ver1.7  2009/04/10  Mod  障害T1_0215 対応
--ito->※最終的にはxxccp_common_pkgになる予定
--        IF ( xxcmm_004common_pkg.chk_single_byte( i_wk_item_rec.case_jan_code ) <> TRUE ) THEN
        IF ( xxccp_common_pkg.chk_single_byte( i_wk_item_rec.case_jan_code ) <> TRUE ) THEN
-- End
          -- 半角チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                  -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00413                  -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                        -- トークンコード1
                        ,iv_token_value1 => cv_case_jan_code                    -- トークン値1
                        ,iv_token_name2  => cv_tkn_value                        -- トークンコード2
                        ,iv_token_value2 => i_wk_item_rec.case_jan_code         -- トークン値2
                        ,iv_token_name3  => cv_tkn_input_line_no                -- トークンコード3
                        ,iv_token_value3 => i_wk_item_rec.line_no               -- トークン値3
                        ,iv_token_name4  => cv_tkn_input_item_code              -- トークンコード4
                        ,iv_token_value4 => i_wk_item_rec.item_code             -- トークン値4
                       );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
        --
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete start by Shigeto.Niki
--        --==============================================================
--        -- A-4.19 ITFコードチェック
--        -- 親品目時チェック(子品目は親値継承)
--        --==============================================================
--        lv_step := 'A-4.19';
--        -- 半角チェック
---- Ver1.7  2009/04/10  Mod  障害T1_0215 対応
----ito->※最終的にはxxccp_common_pkgになる予定
----        IF ( xxcmm_004common_pkg.chk_single_byte( i_wk_item_rec.itf_code ) <> TRUE ) THEN
--        IF ( xxccp_common_pkg.chk_single_byte( i_wk_item_rec.itf_code ) <> TRUE ) THEN
---- End
--          -- 半角チェックエラー
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm                  -- アプリケーション短縮名
--                        ,iv_name         => cv_msg_xxcmm_00413                  -- メッセージコード
--                        ,iv_token_name1  => cv_tkn_input                        -- トークンコード1
--                        ,iv_token_value1 => cv_itf_code                         -- トークン値1
--                        ,iv_token_name2  => cv_tkn_value                        -- トークンコード2
--                        ,iv_token_value2 => i_wk_item_rec.itf_code              -- トークン値2
--                        ,iv_token_name3  => cv_tkn_input_line_no                -- トークンコード3
--                        ,iv_token_value3 => i_wk_item_rec.line_no               -- トークン値3
--                        ,iv_token_name4  => cv_tkn_input_item_code              -- トークンコード4
--                        ,iv_token_value4 => i_wk_item_rec.item_code             -- トークン値4
--                       );
--          -- メッセージ出力
--          xxcmm_004common_pkg.put_message(
--            iv_message_buff => lv_errmsg
--           ,ov_errbuf       => lv_errbuf
--           ,ov_retcode      => lv_retcode
--           ,ov_errmsg       => lv_errmsg
--          );
--          lv_check_flag := cv_status_error;
--        END IF;
--        --
--        --==============================================================
--        -- A-4.20 商品分類チェック
--        -- 親品目時チェック(子品目は親値継承)
--        -- 本登録時必須項目ではないため、値が入っている場合チェックを行います。
--        --==============================================================
--        lv_step := 'A-4.20';
--        IF ( i_wk_item_rec.product_class IS NOT NULL ) THEN
--          -- LOOKUP表存在チェック
--          -- 初期化
--          l_lookup_rec := NULL;
--          l_lookup_rec.lookup_type := cv_lookup_product_class;
--          l_lookup_rec.lookup_code := i_wk_item_rec.product_class;
--          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
--          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
--          -- LOOKUP表存在チェック
--          chk_exists_lookup(
--            io_lookup_rec => l_lookup_rec
--           ,ov_errbuf     => lv_errbuf
--           ,ov_retcode    => lv_retcode
--           ,ov_errmsg     => lv_errmsg
--          );
--          -- 処理結果チェック
--          IF ( lv_retcode <> cv_status_normal ) THEN
--            lv_check_flag := cv_status_error;
--          END IF;
--        END IF;
--        --
--        --==============================================================
--        -- A-4.21 配数、段数チェック
--        -- 親品目時チェック(子品目は親値継承)
--        --==============================================================
--        lv_step := 'A-4.21';
--        IF ( i_wk_item_rec.hon_product_class IS NOT NULL ) THEN
--          -- 本社商品区分が「2:ドリンク」の場合、配数、段数は必須となります。
--          IF ( TO_NUMBER(i_wk_item_rec.hon_product_class) = cn_hon_prod_drink ) THEN
--            -- 配数,段数
--            IF (( i_wk_item_rec.palette_max_cs_qty IS NULL )
--              OR ( i_wk_item_rec.palette_max_step_qty IS NULL )) THEN
--              -- 本社商品区分ドリンク時必須エラー
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                             iv_application  => cv_appl_name_xxcmm                        -- アプリケーション短縮名
--                            ,iv_name         => cv_msg_xxcmm_00416                        -- メッセージコード
--                            ,iv_token_name1  => cv_tkn_input_line_no                      -- トークンコード1
--                            ,iv_token_value1 => i_wk_item_rec.line_no                     -- トークン値1
--                            ,iv_token_name2  => cv_tkn_input_item_code                    -- トークンコード2
--                            ,iv_token_value2 => i_wk_item_rec.item_code                   -- トークン値2
--                            ,iv_token_name3  => cv_tkn_cs_qty                             -- トークンコード3
--                            ,iv_token_value3 => i_wk_item_rec.palette_max_cs_qty          -- トークン値3
--                            ,iv_token_name4  => cv_tkn_step_qty                           -- トークンコード4
--                            ,iv_token_value4 => i_wk_item_rec.palette_max_step_qty        -- トークン値4
--                           );
--              -- メッセージ出力
--              xxcmm_004common_pkg.put_message(
--                iv_message_buff => lv_errmsg
--               ,ov_errbuf       => lv_errbuf
--               ,ov_retcode      => lv_retcode
--               ,ov_errmsg       => lv_errmsg
--              );
--              lv_check_flag := cv_status_error;
--            END IF;
--          END IF;
--        END IF;
-- 2010/01/04 Ver1.18 障害E_本稼動_00614 delete end by Shigeto.Niki
        --
        --==============================================================
        -- A-4.23 政策群チェック
        -- 親品目時チェック(子品目は親値継承)
        --==============================================================
        lv_step := 'A-4.23';
        IF ( i_wk_item_rec.policy_group IS NOT NULL ) THEN
          -- 政策群情報を変数にセット
          l_item_ctg_rec.category_set_name := cv_categ_set_seisakugun;
          l_item_ctg_rec.category_val      := i_wk_item_rec.policy_group;
          -- カテゴリ存在チェック
          chk_exists_category(
            io_item_ctg_rec => l_item_ctg_rec
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          --
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.24 容器群チェック
        -- 親品目時チェック(子品目は親値継承)
        -- 本登録時必須項目ではないため、値が入っている場合チェックを行います。
        --==============================================================
        lv_step := 'A-4.24';
        IF ( i_wk_item_rec.vessel_group IS NOT NULL ) THEN
          -- LOOKUP表存在チェック
          -- 初期化
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_vessel_group;
          l_lookup_rec.lookup_code := i_wk_item_rec.vessel_group;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP表存在チェック
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.25 新商品区分チェック
        -- 親品目時チェック(子品目は親値継承)
        -- 本登録時必須項目ではないため、値が入っている場合チェックを行います。
        --==============================================================
        lv_step := 'A-4.25';
        IF ( i_wk_item_rec.new_item_div IS NOT NULL ) THEN
          -- LOOKUP表存在チェック
          -- 初期化
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_new_item_div;
          l_lookup_rec.lookup_code := i_wk_item_rec.new_item_div;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP表存在チェック
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.26 経理群チェック
        -- 親品目時チェック(子品目は親値継承)
        -- 本登録時必須項目ではないため、値が入っている場合チェックを行います。
        --==============================================================
        lv_step := 'A-4.26';
        IF ( i_wk_item_rec.acnt_group IS NOT NULL ) THEN
          -- LOOKUP表存在チェック
          -- 初期化
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_acnt_group;
          l_lookup_rec.lookup_code := i_wk_item_rec.acnt_group;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP表存在チェック
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.27 経理容器群チェック
        -- 親品目時チェック(子品目は親値継承)
        -- 本登録時必須項目ではないため、値が入っている場合チェックを行います。
        --==============================================================
        lv_step := 'A-4.27';
        IF ( i_wk_item_rec.acnt_vessel_group IS NOT NULL ) THEN
          -- LOOKUP表存在チェック
          -- 初期化
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_acnt_vessel_group;
          l_lookup_rec.lookup_code := i_wk_item_rec.acnt_vessel_group;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP表存在チェック
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.28 ブランド群チェック
        -- 親品目時チェック(子品目は親値継承)
        -- 本登録時必須項目ではないため、値が入っている場合チェックを行います。
        --==============================================================
        lv_step := 'A-4.28';
        IF ( i_wk_item_rec.brand_group IS NOT NULL ) THEN
          -- LOOKUP表存在チェック
          -- 初期化
          l_lookup_rec := NULL;
          l_lookup_rec.lookup_type := cv_lookup_brand_group;
          l_lookup_rec.lookup_code := i_wk_item_rec.brand_group;
          l_lookup_rec.line_no     := i_wk_item_rec.line_no;
          l_lookup_rec.item_code   := i_wk_item_rec.item_code;
          -- LOOKUP表存在チェック
          chk_exists_lookup(
            io_lookup_rec => l_lookup_rec
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
        --==============================================================
        -- A-4.29 標準原価チェック
        -- 親品目時チェック(子品目は親値継承)
        --==============================================================
        lv_step := 'A-4.29';
        -- 7つの合計値が整数でない場合はエラーとします。
        IF   ( i_wk_item_rec.standard_price_1 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_2 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_3 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_4 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_5 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_6 IS NOT NULL )
          OR ( i_wk_item_rec.standard_price_7 IS NOT NULL ) THEN
          ln_opm_cost_total := NVL(TO_NUMBER(i_wk_item_rec.standard_price_1), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_2), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_3), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_4), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_5), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_6), 0) +
                               NVL(TO_NUMBER(i_wk_item_rec.standard_price_7), 0);
-- 2009/08/07 Ver1.14 障害0000862 modify start by Y.Kuboshima
--          IF ( ln_opm_cost_total <> TRUNC(ln_opm_cost_total) ) THEN
--            -- 標準原価エラー
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_appl_name_xxcmm                          -- アプリケーション短縮名
--                          ,iv_name         => cv_msg_xxcmm_00438                          -- メッセージコード
--                          ,iv_token_name1  => cv_tkn_opm_cost                             -- トークンコード1
--                          ,iv_token_value1 => ln_opm_cost_total                           -- トークン値1
--                          ,iv_token_name2  => cv_tkn_input_line_no                        -- トークンコード1
--                          ,iv_token_value2 => i_wk_item_rec.line_no                       -- トークン値1
--                          ,iv_token_name3  => cv_tkn_input_item_code                      -- トークンコード2
--                          ,iv_token_value3 => i_wk_item_rec.item_code                     -- トークン値2
--                         );
--            -- メッセージ出力
--            xxcmm_004common_pkg.put_message(
--              iv_message_buff => lv_errmsg
--             ,ov_errbuf       => lv_errbuf
--             ,ov_retcode      => lv_retcode
--             ,ov_errmsg       => lv_errmsg
--            );
--            lv_check_flag := cv_status_error;
--          END IF;
          --
          -- 資材品目(品名コードの一桁目が'5','6')の場合
          IF ( SUBSTRB( i_wk_item_rec.item_code, 1, 1) IN ( cv_leaf_material, cv_drink_material ) ) THEN
            -- 標準原価合計値が小数点三桁以上の場合
            IF ( ln_opm_cost_total <> TRUNC( ln_opm_cost_total, 2 ) ) THEN
              -- 標準原価エラー
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_name_xxcmm                          -- アプリケーション短縮名
                            ,iv_name         => cv_msg_xxcmm_00438                          -- メッセージコード
                            ,iv_token_name1  => cv_tkn_opm_cost                             -- トークンコード1
                            ,iv_token_value1 => ln_opm_cost_total                           -- トークン値1
                            ,iv_token_name2  => cv_tkn_input_line_no                        -- トークンコード1
                            ,iv_token_value2 => i_wk_item_rec.line_no                       -- トークン値1
                            ,iv_token_name3  => cv_tkn_input_item_code                      -- トークンコード2
                            ,iv_token_value3 => i_wk_item_rec.item_code                     -- トークン値2
                           );
              -- メッセージ出力
              xxcmm_004common_pkg.put_message(
                iv_message_buff => lv_errmsg
               ,ov_errbuf       => lv_errbuf
               ,ov_retcode      => lv_retcode
               ,ov_errmsg       => lv_errmsg
              );
              lv_check_flag := cv_status_error;
            END IF;
          -- 資材品目以外の場合
          ELSE
            -- 小数点が含まれている場合
            IF ( ln_opm_cost_total <> TRUNC(ln_opm_cost_total) ) THEN
              -- 標準原価エラー
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_name_xxcmm                          -- アプリケーション短縮名
                            ,iv_name         => cv_msg_xxcmm_00438                          -- メッセージコード
                            ,iv_token_name1  => cv_tkn_opm_cost                             -- トークンコード1
                            ,iv_token_value1 => ln_opm_cost_total                           -- トークン値1
                            ,iv_token_name2  => cv_tkn_input_line_no                        -- トークンコード1
                            ,iv_token_value2 => i_wk_item_rec.line_no                       -- トークン値1
                            ,iv_token_name3  => cv_tkn_input_item_code                      -- トークンコード2
                            ,iv_token_value3 => i_wk_item_rec.item_code                     -- トークン値2
                           );
              -- メッセージ出力
              xxcmm_004common_pkg.put_message(
                iv_message_buff => lv_errmsg
               ,ov_errbuf       => lv_errbuf
               ,ov_retcode      => lv_retcode
               ,ov_errmsg       => lv_errmsg
              );
              lv_check_flag := cv_status_error;
            END IF;
          END IF;
-- 2009/08/07 Ver1.14 障害0000862 modify start by Y.Kuboshima
          --
--Ver1.12  2009/07/07  Add  標準原価計と営業原価の比較処理を追加
          -- 営業原価計 >= 営業原価の場合
          IF ( ln_opm_cost_total > TO_NUMBER( NVL( i_wk_item_rec.business_price, 0 ))) THEN
            -- 標準原価エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                          -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmm_00434                          -- メッセージコード
                          ,iv_token_name1  => cv_tkn_disc_cost                            -- トークンコード1
                          ,iv_token_value1 => i_wk_item_rec.business_price                -- トークン値1
                          ,iv_token_name2  => cv_tkn_opm_cost                             -- トークンコード2
                          ,iv_token_value2 => TO_CHAR( ln_opm_cost_total )                -- トークン値2
                          ,iv_token_name3  => cv_tkn_input_line_no                        -- トークンコード3
                          ,iv_token_value3 => i_wk_item_rec.line_no                       -- トークン値3
                          ,iv_token_name4  => cv_tkn_input_item_code                      -- トークンコード4
                          ,iv_token_value4 => i_wk_item_rec.item_code                     -- トークン値4
                         );
            -- メッセージ出力
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
          END IF;
--End1.12
          --
        END IF;
-- Ver1.8  2009/05/18 Add  T1_0322 子品目で商品製品区分導出時に親品目の商品製品区分との比較処理を追加
      ELSE
        --==============================================================
        -- A-4.32 商品製品区分チェック
        --==============================================================
        -- 子品目時のチェック処理
        -- 商品製品区分が品目コードによって導出されている場合
        lv_step := 'A-4.32.1';
        IF ( lv_category_val IS NOT NULL ) THEN
          lv_step := 'A-4.32.2';
          ----------------------------------------------------
          -- 導出した商品製品区分と親の製品商品区分を比較
          ----------------------------------------------------
          -- 親品目の商品製品区分を取得
          SELECT    mcssk.segment1        item_product_class
          INTO      lv_p_item_prod_class
          FROM      gmi_item_categories   gicssk
                   ,ic_item_mst_b         iimb
                   ,mtl_category_sets_vl  mcsssk
                   ,mtl_categories_vl     mcssk
          WHERE     mcsssk.category_set_name  = cv_categ_set_item_prod          -- 商品製品区分
          AND       iimb.item_no              = i_wk_item_rec.parent_item_code  -- 親品目コード
          AND       gicssk.category_set_id    = mcsssk.category_set_id          -- カテゴリセット
          AND       gicssk.item_id            = iimb.item_id                    -- 品目ＩＤ
          AND       gicssk.category_id        = mcssk.category_id;              -- カテゴリＩＤ
          --
          -- 商品製品区分の比較
          IF ( lv_category_val != lv_p_item_prod_class ) THEN
            -- 親と異なる商品製品区分の場合エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                          -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmm_00431                          -- メッセージコード
                          ,iv_token_name1  => cv_tkn_input_line_no                        -- トークンコード1
                          ,iv_token_value1 => i_wk_item_rec.line_no                       -- トークン値1
                          ,iv_token_name2  => cv_tkn_input_item_code                      -- トークンコード2
                          ,iv_token_value2 => i_wk_item_rec.item_code                     -- トークン値2
                          ,iv_token_name3  => cv_tkn_item_prd                             -- トークンコード3
                          ,iv_token_value3 => lv_category_val                             -- トークン値3
                          ,iv_token_name4  => cv_tkn_par_item_prd                         -- トークンコード4
                          ,iv_token_value4 => lv_p_item_prod_class                        -- トークン値4
                         );
            -- メッセージ出力
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            --
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
-- End
      END IF;
      --
      --==============================================================
      -- A-4.30 専門店仕入先チェック
      -- 商品製品区分が「1:商品」の場合、子品目は親値継承
      -- 商品製品区分が「2:製品」の場合、親子ともLOOKUP表存在チェックを行います。
      --==============================================================
      lv_step := 'A-4.30.1';
      -- 専門店仕入先 IS NULL時
      IF ( i_wk_item_rec.sp_supplier_code IS NULL ) THEN
        -- 親品目時
        IF ( i_wk_item_rec.item_code = i_wk_item_rec.parent_item_code ) THEN
          -- 商品製品区分が「1:商品」の場合、専門店仕入先は必須となります。
-- Ver1.8  2009/05/19  バグ？？  上書きされた商品製品区分を見るよう修正
--          IF ( TO_NUMBER(i_wk_item_rec.item_product_class) = cn_item_prod_item ) THEN
          IF ( TO_NUMBER( lv_p_item_prod_class ) = cn_item_prod_item ) THEN
-- End
            -- 商品製品区分商品時必須エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                          -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmm_00417                          -- メッセージコード
                          ,iv_token_name1  => cv_tkn_input_line_no                        -- トークンコード1
                          ,iv_token_value1 => i_wk_item_rec.line_no                       -- トークン値1
                          ,iv_token_name2  => cv_tkn_input_item_code                      -- トークンコード2
                          ,iv_token_value2 => i_wk_item_rec.item_code                     -- トークン値2
                         );
            -- メッセージ出力
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
        --
      -- 専門店仕入先 IS NOT NULL時
      ELSE
        lv_step := 'A-4.30.2';
        -- LOOKUP表存在チェック
        -- 初期化
        l_lookup_rec := NULL;
        l_lookup_rec.lookup_type := cv_lookup_senmonten;
        l_lookup_rec.lookup_code := i_wk_item_rec.sp_supplier_code;
        l_lookup_rec.line_no     := i_wk_item_rec.line_no;
        l_lookup_rec.item_code   := i_wk_item_rec.item_code;
        -- LOOKUP表存在チェック
        chk_exists_lookup(
          io_lookup_rec => l_lookup_rec
         ,ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        );
        -- 処理結果チェック
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_check_flag := cv_status_error;
        END IF;
        --
      END IF;
    END IF;
    --
--Ver1.11  2009/06/11 Add start
    --==============================================================
    -- 子品目時の継承チェック(親値があればそのまま設定する)
    --==============================================================
    IF ( i_wk_item_rec.item_code <> i_wk_item_rec.parent_item_code ) THEN
      --
      --==============================================================
      -- A-4.33 バラ茶区分(親値取得)
      --==============================================================
      lv_step := 'A-4.33';
      OPEN get_categ_cur( i_wk_item_rec.parent_item_code, cv_categ_set_baracha_div );
      --
      FETCH get_categ_cur INTO l_item_ctg_rec.bd_category_id, l_item_ctg_rec.bd_category_set_id;
      --
      CLOSE get_categ_cur;
      --
      --==============================================================
      -- A-4.34 マーケ用群コード(親値取得)
      --==============================================================
      lv_step := 'A-4.34';
      OPEN get_categ_cur( i_wk_item_rec.parent_item_code, cv_categ_set_mark_pg );
      --
      FETCH get_categ_cur INTO l_item_ctg_rec.mgc_category_id, l_item_ctg_rec.mgc_category_set_id;
      --
      CLOSE get_categ_cur;
      --
      --==============================================================
      -- A-4.35 群コード(親値取得)
      --==============================================================
      lv_step := 'A-4.35';
      OPEN get_categ_cur( i_wk_item_rec.parent_item_code, cv_categ_set_gun_code );
      --
      FETCH get_categ_cur INTO l_item_ctg_rec.pg_category_id, l_item_ctg_rec.pg_category_set_id;
      --
      CLOSE get_categ_cur;
      --
      IF ( l_item_ctg_rec.pg_category_set_id IS NULL ) THEN
        -- 群コード情報を変数にセット
        l_item_ctg_rec.category_set_name := cv_categ_set_gun_code;
        -- 親の政策群の現在値を抽出
        SELECT    iimb.attribute2
        INTO      l_item_ctg_rec.category_val
        FROM      ic_item_mst_b        iimb
        WHERE     iimb.item_no = i_wk_item_rec.parent_item_code;
        --
        -- カテゴリ存在チェック
        chk_exists_category(
          io_item_ctg_rec => l_item_ctg_rec
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        -- 処理結果チェック
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
    END IF;
    --
    --==============================================================
    -- 親品目時、または、子品目時親品目に設定されていなければ設定する
    --==============================================================
    -- バラ茶区分
    IF ( l_item_ctg_rec.bd_category_set_id IS NULL ) THEN
      l_item_ctg_rec.category_set_name := cv_categ_set_baracha_div;
      l_item_ctg_rec.category_val      := gn_baracha_div;
      --
      -- カテゴリ存在チェック
      chk_exists_category(
        io_item_ctg_rec => l_item_ctg_rec
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
    END IF;
    --
    -- マーケ用群コード
    IF ( l_item_ctg_rec.mgc_category_set_id IS NULL ) THEN
      l_item_ctg_rec.category_set_name := cv_categ_set_mark_pg;
      l_item_ctg_rec.category_val      := gv_mark_pg;
      --
      -- カテゴリ存在チェック
      chk_exists_category(
        io_item_ctg_rec => l_item_ctg_rec
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
    END IF;
--Ver1.11  2009/06/11 End
-- 2009/09/07 Ver1.15 障害0001258 add start by Y.Kuboshima
    --
    --==============================================================
    -- A-4.38 品目区分
    --==============================================================
    lv_step := 'A-4.38';
    l_item_ctg_rec.category_set_name := cv_categ_set_item_div;
    l_item_ctg_rec.category_val      := gv_item_div;
    --
    -- カテゴリ存在チェック
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- A-4.39 内外区分
    --==============================================================
    lv_step := 'A-4.39';
    l_item_ctg_rec.category_set_name := cv_categ_set_inout_div;
    l_item_ctg_rec.category_val      := gv_inout_div;
    --
    -- カテゴリ存在チェック
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- A-4.40 商品区分
    --==============================================================
    lv_step := 'A-4.40';
    l_item_ctg_rec.category_set_name := cv_categ_set_product_div;
    l_item_ctg_rec.category_val      := gv_product_div;
    --
    -- カテゴリ存在チェック
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- A-4.41 品質区分
    --==============================================================
    lv_step := 'A-4.41';
    l_item_ctg_rec.category_set_name := cv_categ_set_quality_div;
    l_item_ctg_rec.category_val      := gv_quality_div;
    --
    -- カテゴリ存在チェック
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- A-4.42 工場群コード
    --==============================================================
    lv_step := 'A-4.42';
    l_item_ctg_rec.category_set_name := cv_categ_set_fact_pg;
    l_item_ctg_rec.category_val      := gv_fact_pg;
    --
    -- カテゴリ存在チェック
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
    --
    --==============================================================
    -- A-4.43 経理部用群コード
    --==============================================================
    lv_step := 'A-4.43';
    l_item_ctg_rec.category_set_name := cv_categ_set_acnt_pg;
    l_item_ctg_rec.category_val      := gv_acnt_pg;
    --
    -- カテゴリ存在チェック
    chk_exists_category(
      io_item_ctg_rec => l_item_ctg_rec
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_check_flag := cv_status_error;
    END IF;
-- 2009/09/07 Ver1.15 障害0001258 add end by Y.Kuboshima
    --
    --==============================================================
    -- A-4.44 処理件数加算
    --==============================================================
    lv_step := 'A-4.44';
    IF ( lv_check_flag = cv_status_normal )THEN
      ov_retcode := cv_status_normal;
    ELSIF ( lv_check_flag = cv_status_error ) THEN
      ov_retcode := cv_status_error;
    END IF;
    --
    -- カテゴリ情報を戻します。(親品目の場合のみ値が入っている状態)
    o_item_ctg_rec := l_item_ctg_rec;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END validate_item;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : 品目一括登録ワークデータ取得 (A-3)
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- プログラム名
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
    lv_step                   VARCHAR2(10);                                     -- ステップ
    ln_line_cnt               NUMBER;                                           -- 行カウンタ
    lv_check_flag             VARCHAR2(1);                                      -- チェックフラグ
    lv_error_flg              VARCHAR2(1);                                      -- 退避用リターン・コード
    l_line_no_tab             g_check_data_ttype;                               -- テーブル型変数を宣言(行番号保持)
    l_item_code_tab           g_check_data_ttype;                               -- テーブル型変数を宣言(品名コード保持)
    lv_check_flag_item_prod   VARCHAR2(1);                                      -- チェックフラグ(商品製品区分)
    ln_request_id             NUMBER;                                           -- 要求ID
    l_conc_argument_tab       xxcmm_004common_pkg.conc_argument_ttype;          -- コンカレント(argument)
    l_item_ctg_rec            g_item_ctg_rtype;                                 -- カテゴリ情報
    l_etc_rec                 g_etc_rtype;                                      -- その他情報
--ito->20090213 Add
    lv_status_val             VARCHAR2(5000);                                   -- ステータス値
--
    -- *** ローカル・カーソル ***
    -- 品目一括登録ワークデータ取得カーソル
    CURSOR get_data_cur
    IS
      SELECT     xwibr.file_id                       AS file_id                 -- ファイルID
                ,xwibr.file_seq                      AS file_seq                -- ファイルシーケンス
                ,TRIM(xwibr.line_no)                 AS line_no                 -- 行番号
                ,TRIM(xwibr.item_code)               AS item_code               -- 品名コード
                ,TRIM(xwibr.item_name)               AS item_name               -- 正式名
                ,TRIM(xwibr.item_short_name)         AS item_short_name         -- 略称
                ,TRIM(xwibr.item_name_alt)           AS item_name_alt           -- カナ名
                ,TRIM(xwibr.item_status)             AS item_status             -- 品目ステータス
                ,TRIM(xwibr.sales_target_flag)       AS sales_target_flag       -- 売上対象区分
                ,TRIM(xwibr.parent_item_code)        AS parent_item_code        -- 親商品コード
                ,TRIM(xwibr.case_inc_num)            AS case_inc_num            -- ケース入数
-- Ver1.8  2009/05/18 Add  T1_0906 ケース換算入数を追加
                ,TRIM(case_conv_inc_num)             AS case_conv_inc_num       -- ケース換算入数
-- End
                ,TRIM(xwibr.item_um)                 AS item_um                 -- 基準単位
                ,TRIM(xwibr.item_product_class)      AS item_product_class      -- 商品製品区分
                ,TRIM(xwibr.rate_class)              AS rate_class              -- 率区分
                ,TRIM(xwibr.net)                     AS net                     -- NET
                ,TRIM(xwibr.weight_volume)           AS weight_volume           -- 重量／体積
                ,TRIM(xwibr.jan_code)                AS jan_code                -- JANコード
                ,TRIM(xwibr.nets)                    AS nets                    -- 内容量
                ,TRIM(xwibr.nets_uom_code)           AS nets_uom_code           -- 内容量単位
                ,TRIM(xwibr.inc_num)                 AS inc_num                 -- 内訳入数
                ,TRIM(xwibr.case_jan_code)           AS case_jan_code           -- ケースJANコード
                ,TRIM(xwibr.hon_product_class)       AS hon_product_class       -- 本社商品区分
                ,TRIM(xwibr.baracha_div)             AS baracha_div             -- バラ茶区分
                ,TRIM(xwibr.itf_code)                AS itf_code                -- ITFコード
                ,TRIM(xwibr.product_class)           AS product_class           -- 商品分類
                ,TRIM(xwibr.palette_max_cs_qty)      AS palette_max_cs_qty      -- 配数
                ,TRIM(xwibr.palette_max_step_qty)    AS palette_max_step_qty    -- 段数
                ,TRIM(xwibr.bowl_inc_num)            AS bowl_inc_num            -- ボール入数
                ,TRIM(xwibr.sale_start_date)         AS sale_start_date         -- 発売開始日
                ,TRIM(xwibr.vessel_group)            AS vessel_group            -- 容器群
                ,TRIM(xwibr.new_item_div)            AS new_item_div            -- 新商品区分
                ,TRIM(xwibr.acnt_group)              AS acnt_group              -- 経理群
                ,TRIM(xwibr.acnt_vessel_group)       AS acnt_vessel_group       -- 経理容器群
                ,TRIM(xwibr.brand_group)             AS brand_group             -- ブランド群
                ,TRIM(xwibr.policy_group)            AS policy_group            -- 政策群
                ,TRIM(xwibr.list_price)              AS list_price              -- 定価
                ,TRIM(xwibr.standard_price_1)        AS standard_price_1        -- 原料(標準原価)
                ,TRIM(xwibr.standard_price_2)        AS standard_price_2        -- 再製費(標準原価)
                ,TRIM(xwibr.standard_price_3)        AS standard_price_3        -- 資材費(標準原価)
                ,TRIM(xwibr.standard_price_4)        AS standard_price_4        -- 包装費(標準原価)
                ,TRIM(xwibr.standard_price_5)        AS standard_price_5        -- 外注管理費(標準原価)
                ,TRIM(xwibr.standard_price_6)        AS standard_price_6        -- 保管費(標準原価)
                ,TRIM(xwibr.standard_price_7)        AS standard_price_7        -- その他経費(標準原価)
                ,TRIM(xwibr.business_price)          AS business_price          -- 営業原価
                ,TRIM(xwibr.renewal_item_code)       AS renewal_item_code       -- リニューアル元商品コード
                ,TRIM(xwibr.sp_supplier_code)        AS sp_supplier_code        -- 専門店仕入先コード
                ,xwibr.created_by                                               -- 作成者
                ,xwibr.creation_date                                            -- 作成日
                ,xwibr.last_updated_by                                          -- 最終更新者
                ,xwibr.last_update_date                                         -- 最終更新日
                ,xwibr.last_update_login                                        -- 最終更新ログインID
                ,xwibr.request_id                                               -- 要求ID
                ,xwibr.program_application_id                                   -- コンカレント・プログラムのアプリケーションID
                ,xwibr.program_id                                               -- コンカレント・プログラムID
                ,xwibr.program_update_date                                      -- プログラムによる更新日
      FROM       xxcmm_wk_item_batch_regist  xwibr                              -- 品目一括登録ワーク
      WHERE      xwibr.request_id = cn_request_id                               -- 要求ID
      ORDER BY   file_seq                                                       -- ファイルシーケンス
      ;
    --
    -- 商品製品区分取得カーソル
    CURSOR get_item_prod_cur
    IS
      SELECT    mcv.attribute1      AS dualum_ind                               -- 二重管理
               ,mcv.attribute2      AS lot_ctl                                  -- ロット
      FROM      mtl_categories_vl      mcv,                                     -- カテゴリ
                mtl_category_sets_vl   mcsv                                     -- カテゴリセット
      WHERE     mcv.structure_id       = mcsv.structure_id
      AND       mcsv.category_set_name = cv_item_product_class
      ;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
--
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    -- チェックフラグの初期化
    lv_check_flag            := cv_status_normal;
    lv_check_flag_item_prod  := cv_status_normal;
    --
    --==============================================================
    -- 商品製品区分DFFチェック
    -- OPM品目の二重管理、ロットは商品製品区分のDFFより取得するが未設定の場合はエラーとします。(NOT NULL項目なので)
    --==============================================================
    lv_step := 'A-3.1';
    <<item_product_loop>>
    FOR get_item_prod_rec IN get_item_prod_cur LOOP
      -- 二重管理、ロットNULLチェック
      IF (( get_item_prod_rec.dualum_ind IS NULL ) OR ( get_item_prod_rec.lot_ctl IS NULL )) THEN
        lv_check_flag_item_prod := cv_status_error;
      END IF;
    END LOOP item_product_loop;
    --
    -- 処理結果チェック
    IF ( lv_check_flag_item_prod = cv_status_error ) THEN
      -- 商品製品区分DFF未設定エラー
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm                  -- アプリケーション短縮名
                      ,iv_name          =>  cv_msg_xxcmm_00420                  -- メッセージコード
                     );
      -- メッセージ出力
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
    END IF;
    --
    ln_line_cnt := 0;
    <<main_loop>>
    FOR get_data_rec IN get_data_cur LOOP
      -- 初期化
      lv_error_flg := cv_status_normal;
      --
      -- 行カウンタアップ
      ln_line_cnt := ln_line_cnt + 1;
      --==============================================================
      -- A-4  データ妥当性チェック
      --==============================================================
      lv_step := 'A-4';
      validate_item(
        i_wk_item_rec  => get_data_rec             -- 品目一括登録ワーク情報
       ,o_item_ctg_rec => l_item_ctg_rec           -- カテゴリ情報
       ,o_etc_rec      => l_etc_rec                -- その他情報
       ,ov_errbuf      => lv_errbuf                -- エラー・メッセージ
       ,ov_retcode     => lv_retcode               -- リターン・コード
       ,ov_errmsg      => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode = cv_status_normal ) THEN
        -- OPM品目の二重管理、ロットがNULLの場合、登録処理は行いません。
        IF ( lv_check_flag_item_prod = cv_status_normal ) THEN
          --==============================================================
          -- A-5  データ登録
          --==============================================================
          lv_step := 'A-5';
          ins_data(
            i_wk_item_rec  => get_data_rec             -- 品目一括登録ワーク情報
           ,i_item_ctg_rec => l_item_ctg_rec           -- カテゴリ情報
           ,i_etc_rec      => l_etc_rec                -- その他情報
           ,ov_errbuf      => lv_errbuf                -- エラー・メッセージ
           ,ov_retcode     => lv_retcode               -- リターン・コード
           ,ov_errmsg      => lv_errmsg                -- ユーザー・エラー・メッセージ
          );
          -- 処理結果チェック
          IF ( lv_retcode = cv_status_normal ) THEN
            -- 予め行番号、品名コードを変数に退避しておきます。
            -- A-5.2で使用します。
            l_line_no_tab(ln_line_cnt)   := get_data_rec.line_no;
            l_item_code_tab(ln_line_cnt) := get_data_rec.item_code;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            -- エラーステータス退避
            lv_error_flg := lv_retcode;
          END IF;
        END IF;
        --
      ELSE
        -- データ妥当性チェックエラーの場合
        -- エラーステータス退避
        lv_error_flg := lv_retcode;
      END IF;
      --
      --==============================================================
      -- 処理件数加算
      --==============================================================
      IF ( lv_error_flg = cv_status_normal ) THEN
        IF ( lv_check_flag_item_prod = cv_status_normal ) THEN
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSE
          gn_error_cnt  := gn_error_cnt + 1;
          lv_check_flag := cv_status_error;
        END IF;
      ELSE
        gn_error_cnt  := gn_error_cnt + 1;
        lv_check_flag := cv_status_error;
      END IF;
    END LOOP main_loop;
    --
    -- OPM品目の二重管理、ロットがNULLの場合、エラーをセット
    IF ( lv_check_flag_item_prod = cv_status_error ) THEN
      lv_retcode := cv_status_error;
    ELSE
      -- 妥当性、登録エラーの場合、エラーをセット
      IF ( lv_check_flag = cv_status_error ) THEN
        lv_retcode := cv_status_error;
      END IF;
    END IF;
    --
    -- 処理結果チェック
    IF ( lv_retcode = cv_status_normal ) THEN
      --==============================================================
      -- A-5.2 Disc品目登録処理
      -- 全ての登録処理が完了したら品目一括登録ワークのレコード分、コンカレントを起動します。
      --==============================================================
      lv_step := 'A-5.2';
      COMMIT;
      --
      -- Disc品目登録LOOP
      <<loop_conc>>
      FOR ln_conc_cnt IN 1..l_item_code_tab.COUNT LOOP
        -- ■「OPM品目トリガー起動コンカレント」実行
        -- argument設定
        l_conc_argument_tab(1).argument := l_item_code_tab(ln_conc_cnt);
        <<loop_arg>>
        FOR ln_cnt IN 2..100 LOOP
          l_conc_argument_tab(ln_cnt).argument := CHR(0);
        END LOOP loop_arg;
        --
        xxcmm_004common_pkg.proc_conc_request(
          iv_appl_short_name => cv_appl_name_xxcmn
         ,iv_program         => cv_prog_opmitem_trigger
         ,iv_description     => NULL
         ,iv_start_time      => NULL
         ,ib_sub_request     => FALSE
         ,i_argument_tab     => l_conc_argument_tab
         ,iv_wait_flag       => cv_yes
         ,on_request_id      => ln_request_id
         ,ov_errbuf          => lv_errbuf
         ,ov_retcode         => lv_retcode
         ,ov_errmsg          => lv_errmsg
        );
        --
--ito->20090213 Add START
        IF ( lv_retcode = cv_status_normal ) THEN
          lv_status_val := cv_status_val_normal;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          lv_status_val := SUBSTRB(cv_status_val_warn || cv_msg_part || lv_errmsg, 1, 5000);
        ELSE
          lv_status_val := SUBSTRB(cv_status_val_error || cv_msg_part || lv_errmsg, 1, 5000);
        END IF;
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          ov_retcode := cv_status_error;
          gn_normal_cnt := gn_normal_cnt - 1;
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
--ito->20090213 Add END
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00408                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_req_id                         -- トークンコード1
                      ,iv_token_value1 => ln_request_id                         -- トークン値1
                      ,iv_token_name2  => cv_tkn_input_line_no                  -- トークンコード2
                      ,iv_token_value2 => l_line_no_tab(ln_conc_cnt)            -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_item_code                -- トークンコード3
                      ,iv_token_value3 => l_item_code_tab(ln_conc_cnt)          -- トークン値3
                      ,iv_token_name4  => cv_tkn_msg                            -- トークンコード4
                      ,iv_token_value4 => lv_status_val                         -- トークン値4
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
      END LOOP loop_conc;
    ELSE
      ov_retcode := cv_status_error;
    END IF;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードIFデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';        -- プログラム名
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
    lv_step                   VARCHAR2(10);                           -- ステップ
    --
    ln_line_cnt               NUMBER;                                 -- 行カウンタ
    ln_item_num               NUMBER;                                 -- 項目数
    ln_item_cnt               NUMBER;                                 -- 項目数カウンタ
    lv_file_name              VARCHAR2(100);                          -- ファイル名格納用
    ln_ins_item_cnt           NUMBER;                                 -- 登録件数カウンタ
--
    l_wk_item_tab             g_check_data_ttype;                     --  テーブル型変数を宣言(項目分割)
    l_if_data_tab             xxccp_common_pkg2.g_file_data_tbl;      --  テーブル型変数を宣言
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    get_if_data_expt          EXCEPTION;                              -- データ項目数エラー例外
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    ln_ins_item_cnt := 0;
    --
    --==============================================================
    -- A-2.1 対象データの分割(レコード分割)
    --==============================================================
    lv_step := 'A-2.1';
    xxccp_common_pkg2.blob_to_varchar2(                               -- BLOBデータ変換共通関数
      in_file_id   => gn_file_id                                      -- ファイルＩＤ
     ,ov_file_data => l_if_data_tab                                   -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf                                       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode                                      -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg                                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- ワークテーブル登録LOOP
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 1..l_if_data_tab.COUNT LOOP
      --==============================================================
      -- A-2.2 項目数のチェック
      --==============================================================
      lv_step := 'A-2.2';
      -- データ項目数を格納
      ln_item_num := ( LENGTHB(l_if_data_tab( ln_line_cnt))
                   - ( LENGTHB(REPLACE(l_if_data_tab(ln_line_cnt), cv_msg_comma, '')))
                   + 1);
      -- 項目数が一致しない場合
      IF ( gn_item_num <> ln_item_num ) THEN
        RAISE get_if_data_expt;
      END IF;
      --
      --==============================================================
      -- A-2.3.1 対象データの分割(項目分割)
      --==============================================================
      lv_step := 'A-2.3.1';
      <<get_column_loop>>
      FOR ln_item_cnt IN 1..gn_item_num LOOP
        -- 変数に項目の値を格納
        l_wk_item_tab(ln_item_cnt) := xxccp_common_pkg.char_delim_partition(  -- デリミタ文字変換共通関数
                                        iv_char     => l_if_data_tab(ln_line_cnt)
                                       ,iv_delim    => cv_msg_comma
                                       ,in_part_num => ln_item_cnt
                                      );
      END LOOP get_column_loop;
      --
      --==============================================================
      -- A-2.3.2 品目一括登録ワークへ登録
      --==============================================================
      lv_step := 'A-2.3.2';
      BEGIN
        ln_ins_item_cnt := ln_ins_item_cnt + 1;
        --
        INSERT INTO xxcmm_wk_item_batch_regist(
          file_id                       -- ファイルID
         ,file_seq                      -- ファイルシーケンス
         ,line_no                       -- 行番号
         ,item_code                     -- 品名コード
         ,item_name                     -- 正式名
         ,item_short_name               -- 略称
         ,item_name_alt                 -- カナ名
         ,item_status                   -- 品目ステータス
         ,sales_target_flag             -- 売上対象区分
         ,parent_item_code              -- 親商品コード
         ,case_inc_num                  -- ケース入数
-- Ver1.8  2009/05/18 Add  T1_0906 ケース換算入数を追加
         ,case_conv_inc_num             -- ケース換算入数
-- End
         ,item_um                       -- 基準単位
         ,item_product_class            -- 商品製品区分
         ,rate_class                    -- 率区分
         ,net                           -- NET
         ,weight_volume                 -- 重量／体積
         ,jan_code                      -- JANコード
         ,nets                          -- 内容量
         ,nets_uom_code                 -- 内容量単位
         ,inc_num                       -- 内訳入数
         ,case_jan_code                 -- ケースJANコード
         ,hon_product_class             -- 本社商品区分
         ,baracha_div                   -- バラ茶区分
         ,itf_code                      -- ITFコード
         ,product_class                 -- 商品分類
         ,palette_max_cs_qty            -- 配数
         ,palette_max_step_qty          -- 段数
         ,bowl_inc_num                  -- ボール入数
         ,sale_start_date               -- 発売開始日
         ,vessel_group                  -- 容器群
         ,new_item_div                  -- 新商品区分
         ,acnt_group                    -- 経理群
         ,acnt_vessel_group             -- 経理容器群
         ,brand_group                   -- ブランド群
         ,policy_group                  -- 政策群
         ,list_price                    -- 定価
         ,standard_price_1              -- 原料(標準原価)
         ,standard_price_2              -- 再製費(標準原価)
         ,standard_price_3              -- 資材費(標準原価)
         ,standard_price_4              -- 包装費(標準原価)
         ,standard_price_5              -- 外注管理費(標準原価)
         ,standard_price_6              -- 保管費(標準原価)
         ,standard_price_7              -- その他経費(標準原価)
         ,business_price                -- 営業原価
         ,renewal_item_code             -- リニューアル元商品コード
         ,sp_supplier_code              -- 専門店仕入先コード
         ,created_by                    -- 作成者
         ,creation_date                 -- 作成日
         ,last_updated_by               -- 最終更新者
         ,last_update_date              -- 最終更新日
         ,last_update_login             -- 最終更新ログインID
         ,request_id                    -- 要求ID
         ,program_application_id        -- コンカレント・プログラムのアプリケーションID
         ,program_id                    -- コンカレント・プログラムID
         ,program_update_date           -- プログラムによる更新日
         ) VALUES (
          gn_file_id                    -- ファイルID
         ,ln_ins_item_cnt               -- ファイルシーケンス
         ,l_wk_item_tab(1)              -- 行番号
         ,l_wk_item_tab(2)              -- 品名コード
         ,l_wk_item_tab(3)              -- 正式名
         ,l_wk_item_tab(4)              -- 略称
         ,l_wk_item_tab(5)              -- カナ名
         ,l_wk_item_tab(6)              -- 品目ステータス
         ,l_wk_item_tab(7)              -- 売上対象区分
         ,l_wk_item_tab(8)              -- 親商品コード
         ,l_wk_item_tab(9)              -- ケース入数
-- Ver1.8  2009/05/18 Add  T1_0906 ケース換算入数を追加
         ,l_wk_item_tab(10)             -- ケース換算入数
-- End
         ,l_wk_item_tab(11)             -- 基準単位
         ,l_wk_item_tab(12)             -- 商品製品区分
         ,l_wk_item_tab(13)             -- 率区分
         ,l_wk_item_tab(14)             -- NET
         ,l_wk_item_tab(15)             -- 重量／体積
         ,l_wk_item_tab(16)             -- JANコード
         ,l_wk_item_tab(17)             -- 内容量
         ,l_wk_item_tab(18)             -- 内容量単位
         ,l_wk_item_tab(19)             -- 内訳入数
         ,l_wk_item_tab(20)             -- ケースJANコード
         ,l_wk_item_tab(21)             -- 本社商品区分
         ,l_wk_item_tab(22)             -- バラ茶区分
         ,l_wk_item_tab(23)             -- ITFコード
         ,l_wk_item_tab(24)             -- 商品分類
         ,l_wk_item_tab(25)             -- 配数
         ,l_wk_item_tab(26)             -- 段数
         ,l_wk_item_tab(27)             -- ボール入数
         ,l_wk_item_tab(28)             -- 発売開始日
         ,l_wk_item_tab(29)             -- 容器群
         ,l_wk_item_tab(30)             -- 新商品区分
         ,l_wk_item_tab(31)             -- 経理群
         ,l_wk_item_tab(32)             -- 経理容器群
         ,l_wk_item_tab(33)             -- ブランド群
         ,l_wk_item_tab(34)             -- 政策群
         ,l_wk_item_tab(35)             -- 定価
         ,l_wk_item_tab(36)             -- 原料(標準原価)
         ,l_wk_item_tab(37)             -- 再製費(標準原価)
         ,l_wk_item_tab(38)             -- 資材費(標準原価)
         ,l_wk_item_tab(39)             -- 包装費(標準原価)
         ,l_wk_item_tab(40)             -- 外注管理費(標準原価)
         ,l_wk_item_tab(41)             -- 保管費(標準原価)
         ,l_wk_item_tab(42)             -- その他経費(標準原価)
         ,l_wk_item_tab(43)             -- 営業原価
         ,l_wk_item_tab(44)             -- リニューアル元商品コード
         ,l_wk_item_tab(45)             -- 専門店仕入先コード
         ,cn_created_by                 -- 作成者
         ,cd_creation_date              -- 作成日
         ,cn_last_updated_by            -- 最終更新者
         ,cd_last_update_date           -- 最終更新日
         ,cn_last_update_login          -- 最終更新ログインID
         ,cn_request_id                 -- 要求ID
         ,cn_program_application_id     -- コンカレント・プログラムのアプリケーションID
         ,cn_program_id                 -- コンカレント・プログラムID
         ,cd_program_update_date        -- プログラムによる更新日
        );
      EXCEPTION
        -- *** データ登録例外ハンドラ ***
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcmm       -- アプリケーション短縮名
                         ,iv_name         => cv_msg_xxcmm_00407       -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table             -- トークンコード1
                         ,iv_token_value1 => cv_table_xwibr           -- トークン値1
                         ,iv_token_name2  => cv_tkn_input_line_no     -- トークンコード2
                         ,iv_token_value2 => l_wk_item_tab(1)         -- トークン値2
                         ,iv_token_name3  => cv_tkn_input_item_code   -- トークンコード3
                         ,iv_token_value3 => l_wk_item_tab(2)         -- トークン値3
                         ,iv_token_name4  => cv_tkn_errmsg            -- トークンコード4
                         ,iv_token_value4 => SQLERRM                  -- トークン値4
                        );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          --
          -- エラー件数カウントアップ
          -- ここでエラーとなったものは妥当性チェックは行いません。
          gn_error_cnt := gn_error_cnt + 1;
      END;
    END LOOP ins_wk_loop;
    --
    -- 処理対象件数を格納
    gn_target_cnt := l_if_data_tab.COUNT;
    --
  EXCEPTION
    -- *** データ項目数エラー例外ハンドラ ***
    WHEN get_if_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00028            -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => cv_item_batch_regist          -- トークン値1
                    ,iv_token_name2  => cv_tkn_count                  -- トークンコード2
                    ,iv_token_value2 => ln_item_num                   -- トークン値2
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_file_id    IN  VARCHAR2          -- 1.ファイルID
   ,iv_format     IN  VARCHAR2          -- 2.フォーマット
   ,ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init';              -- プログラム名
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
    lv_step                   VARCHAR2(10);                           -- ステップ
    lv_tkn_value              VARCHAR2(100);                          -- トークン値
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRMを退避
    --
    lv_upload_obj             VARCHAR2(100);                          -- ファイルアップロード名称
    lv_up_name                VARCHAR2(1000);                         -- アップロード名称出力用
    lv_file_id                VARCHAR2(1000);                         -- ファイルID出力用
    lv_file_format            VARCHAR2(1000);                         -- フォーマット出力用
    lv_file_name              VARCHAR2(1000);                         -- ファイル名出力用
-- Ver1.3 Mod 20090216 START
    -- ファイルアップロードIFテーブル項目
    lv_csv_file_name           xxccp_mrp_file_ul_interface.file_name%TYPE;                          -- ファイル名格納用
    ln_created_by              xxccp_mrp_file_ul_interface.created_by%TYPE;                         -- 作成者格納用
    ld_creation_date           xxccp_mrp_file_ul_interface.creation_date%TYPE;                      -- 作成日格納用
--    lv_created_by             VARCHAR2(100);                          -- 作成者格納用
--    lv_creation_date          VARCHAR2(100);                          -- 作成日格納用
-- Ver1.3 Mod 20090216 END
    ln_cnt                    NUMBER;                                 -- カウンタ
--
    -- *** ローカル・カーソル ***
    -- データ項目定義取得用カーソル
    CURSOR     get_def_info_cur
    IS
      SELECT   flv.meaning                         AS item_name                 -- 内容
              ,DECODE(flv.attribute1, cv_varchar, cv_varchar_cd
                                    , cv_number,  cv_number_cd
                                    , cv_date_cd)  AS item_attribute            -- 項目属性
              ,DECODE(flv.attribute2, cv_not_null, cv_null_ng
                                    , cv_null_ok)  AS item_essential            -- 必須フラグ
              ,TO_NUMBER(flv.attribute3)           AS item_length               -- 項目の長さ(整数部分)
              ,TO_NUMBER(flv.attribute4)           AS decim                     -- 項目の長さ(小数点以下)
      FROM     fnd_lookup_values_vl  flv                                        -- LOOKUP表
      WHERE    flv.lookup_type        = cv_lookup_item_def                      -- 品目一括登録データ項目定義
      AND      flv.enabled_flag       = cv_yes                                  -- 使用可能フラグ
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- 適用開始日
      AND      NVL(flv.end_date_active, gd_process_date)   >= gd_process_date   -- 適用終了日
      ORDER BY flv.lookup_code;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    get_param_expt            EXCEPTION;                              -- パラメータNULLエラー
    get_profile_expt          EXCEPTION;                              -- プロファイル取得例外
    select_expt               EXCEPTION;                              -- データ抽出エラー
-- Ver.1.5 20090224 Add START
    process_date_expt         EXCEPTION;                              -- 業務日付取得失敗エラー
-- Ver.1.5 20090224 Add END
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- A-1.1 入力パラメータ（FILE_ID、フォーマット）の「NULL」チェック
    --==============================================================
    lv_step := 'A-1.1';
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_file_id;
      RAISE get_param_expt;
    END IF;
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := cv_format;
      RAISE get_param_expt;
    END IF;
    --
    -- INパラメータを格納
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
    --
    --==============================================================
    -- A-1.2 業務日付の取得
    --==============================================================
    lv_step := 'A-1.2';
    gd_process_date := xxccp_common_pkg2.get_process_date;
-- Ver.1.5 20090224 Add START
    -- NULLチェック
    IF ( gd_process_date IS NULL ) THEN
      lv_tkn_value := cv_process_date;
      RAISE process_date_expt;
    END IF;
-- Ver.1.5 20090224 Add END
    --
    --==============================================================
    -- A-1.3 プロファイル取得
    --==============================================================
    lv_step := 'A-1.3';
    -- 品目マスタ（情報系）連携用CSVファイル名の取得
    gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prof_item_num));
    -- 取得エラー時
    IF ( gn_item_num IS NULL ) THEN
      lv_tkn_value := cv_lookup_item_defname;
      RAISE get_profile_expt;
    END IF;
    --
--Ver1.10  2009/06/04 Add start
    -- XXCMM:品目登録画面_ロットデフォルト値
    gn_lot_ctl := TO_NUMBER(FND_PROFILE.VALUE(cv_prof_lot_ctl));
    -- 取得エラー時
    IF ( gn_lot_ctl IS NULL ) THEN
      lv_tkn_value := cv_lot_ctl_defname;
      RAISE get_profile_expt;
    END IF;
--Ver1.10  2009/06/04 End
    --
--Ver1.11  2009/06/11 Add start
    -- XXCMM:バラ茶区分初期値
    gn_baracha_div := TO_NUMBER(FND_PROFILE.VALUE(cv_prof_baracha_div));
    -- 取得エラー時
    IF ( gn_baracha_div IS NULL ) THEN
      lv_tkn_value := cv_baracha_div_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:マーケ用群コード初期値
    gv_mark_pg := FND_PROFILE.VALUE(cv_prof_mark_pg);
    -- 取得エラー時
    IF ( gv_mark_pg IS NULL ) THEN
      lv_tkn_value := cv_mark_pg_def;
      RAISE get_profile_expt;
    END IF;
--Ver1.11  2009/06/11 End
    --
-- Ver1.13 2009/07/24 Add Start
    -- XXCMM:適用開始日初期値
    gd_opm_apply_date := TO_DATE(FND_PROFILE.VALUE(cv_prof_apply_date),cv_date_fmt_std);
    -- 取得エラー時
    IF ( gd_opm_apply_date IS NULL ) THEN
      lv_tkn_value := cv_apply_date_def;
      RAISE get_profile_expt;
    END IF;
-- Ver1.13 End
-- 2009/09/07 Ver1.15 障害0001258 add start by Y.Kuboshima
    -- XXCMM:品目区分初期値
    gv_item_div := FND_PROFILE.VALUE(cv_prof_item_div);
    -- 取得エラー時
    IF ( gv_item_div IS NULL ) THEN
      lv_tkn_value := cv_item_div_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:内外区分初期値
    gv_inout_div := FND_PROFILE.VALUE(cv_prof_inout_div);
    -- 取得エラー時
    IF ( gv_inout_div IS NULL ) THEN
      lv_tkn_value := cv_inout_div_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:商品区分初期値
    gv_product_div := FND_PROFILE.VALUE(cv_prof_product_div);
    -- 取得エラー時
    IF ( gv_product_div IS NULL ) THEN
      lv_tkn_value := cv_product_div_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:品質区分初期値
    gv_quality_div := FND_PROFILE.VALUE(cv_prof_quality_div);
    -- 取得エラー時
    IF ( gv_quality_div IS NULL ) THEN
      lv_tkn_value := cv_quality_div_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:工場群コード初期値
    gv_fact_pg := FND_PROFILE.VALUE(cv_prof_fact_pg);
    -- 取得エラー時
    IF ( gv_fact_pg IS NULL ) THEN
      lv_tkn_value := cv_fact_pg_def;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:経理部用群コード初期値
    gv_acnt_pg := FND_PROFILE.VALUE(cv_prof_acnt_pg);
    -- 取得エラー時
    IF ( gv_acnt_pg IS NULL ) THEN
      lv_tkn_value := cv_acnt_pg_def;
      RAISE get_profile_expt;
    END IF;
-- 2009/09/07 Ver1.15 障害0001258 add end by Y.Kuboshima
    --
    --==============================================================
    -- A-1.4 ファイルアップロード名称取得
    --==============================================================
    lv_step := 'A-1.4';
    BEGIN
      SELECT   flv.meaning
      INTO     lv_upload_obj
      FROM     fnd_lookup_values_vl flv
      WHERE    flv.lookup_type  = cv_lookup_type_upload_obj                     -- ファイルアップロードオブジェクト
      AND      flv.lookup_code  = gv_format                                     -- フォーマット
      AND      flv.enabled_flag = cv_yes                                        -- 使用可能フラグ
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- 適用開始日
      AND      NVL(flv.end_date_active,   gd_process_date) >= gd_process_date   -- 適用終了日
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        RAISE select_expt;
    END;
    --
    --==============================================================
    -- A-1.5 対象データロックの取得
    --==============================================================
    lv_step := 'A-1.5';
-- Ver1.3 Mod 20090216 START
    SELECT   fui.file_name                                            -- ファイル名
            ,fui.created_by                                           -- 作成者
            ,fui.creation_date                                        -- 作成日
    INTO     lv_csv_file_name
            ,ln_created_by
            ,ld_creation_date
    FROM     xxccp_mrp_file_ul_interface  fui                         -- ファイルアップロードIFテーブル
    WHERE    fui.file_id = gn_file_id                                 -- ファイルID
    FOR UPDATE NOWAIT
    ;
--    SELECT   fui.file_name         file_name                          -- ファイル名
--            ,fui.created_by        created_by                         -- 作成者
--            ,fui.creation_date     creation_date                      -- 作成日
--    INTO     lv_file_name
--            ,lv_created_by
--            ,lv_creation_date
--    FROM     xxccp_mrp_file_ul_interface  fui                         -- ファイルアップロードIFテーブル
--    WHERE    fui.file_id = gn_file_id                                 -- ファイルID
--    FOR UPDATE NOWAIT;
-- Ver1.3 Mod 20090216 END
    --
    --==============================================================
    -- A-1.6 品目一括登録ワーク定義情報の取得
    --==============================================================
    lv_step := 'A-1.6';
    -- 変数の初期化
    ln_cnt := 0;
    -- テーブル定義取得LOOP
    <<def_info_loop>>
    FOR get_def_info_rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      g_item_def_tab(ln_cnt).item_name      := get_def_info_rec.item_name;                -- 項目名
      g_item_def_tab(ln_cnt).item_attribute := get_def_info_rec.item_attribute;           -- 項目属性
      g_item_def_tab(ln_cnt).item_essential := get_def_info_rec.item_essential;           -- 必須フラグ
      g_item_def_tab(ln_cnt).item_length    := get_def_info_rec.item_length;              -- 項目の長さ(整数部分)
      g_item_def_tab(ln_cnt).decim    := get_def_info_rec.decim;                          -- 項目の長さ(小数点以下)
    END LOOP def_info_loop;
    --
    --==============================================================
    -- A-1.7 INパラメータの出力
    --==============================================================
    lv_step := 'A-1.7';
    lv_up_name     := xxccp_common_pkg.get_msg(                                                     -- アップロード名称の出力
                        iv_application  => cv_appl_name_xxcmm                                       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00021                                       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_up_name                                           -- トークンコード1
                       ,iv_token_value1 => lv_upload_obj                                            -- トークン値1
                      );
-- Ver1.3 Add 20090216 START
    lv_file_name   := xxccp_common_pkg.get_msg(                                                     -- ファイルIDの出力
                        iv_application  => cv_appl_name_xxcmm                                       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00022                                       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_name                                         -- トークンコード1
                       ,iv_token_value1 => lv_csv_file_name                                         -- トークン値1
                      );
-- Ver1.3 Add 20090216 END
    lv_file_id     := xxccp_common_pkg.get_msg(                                                     -- ファイルIDの出力
                        iv_application  => cv_appl_name_xxcmm                                       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00023                                       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_id                                           -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(gn_file_id)                                      -- トークン値1
                      );
    lv_file_format := xxccp_common_pkg.get_msg(                                                     -- フォーマットの出力
                       iv_application  => cv_appl_name_xxcmm                                        -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00024                                        -- メッセージコード
                      ,iv_token_name1  => cv_tkn_file_format                                        -- トークンコード1
                      ,iv_token_value1 => gv_format                                                 -- トークン値1
                      );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT                                                     -- 出力に表示
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG                                                        -- ログに表示
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
--
  EXCEPTION
-- Ver.1.5 20090224 Add START
    --*** 業務日付取得失敗エラー ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00435            -- メッセージ
                    ,iv_token_name1  => cv_tkn_value                  -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
-- Ver.1.5 20090224 Add END
    --
    --*** パラメータNULLエラー ***
    WHEN get_param_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00401            -- メッセージ
                    ,iv_token_name1  => cv_tkn_value                  -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** データ抽出エラー(アップロードファイル名称) ***
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00439            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => cv_table_flv                  -- トークン値1
                    ,iv_token_name2  => cv_tkn_errmsg                 -- トークンコード2
                    ,iv_token_value2 => lv_sqlerrm                    -- トークン値2
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** プロファイル取得エラー ***
    WHEN get_profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00002            -- メッセージ
                    ,iv_token_name1  => cv_tkn_ng_profile             -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00402            -- メッセージコード
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2          -- 1.ファイルID
   ,iv_format     IN  VARCHAR2          -- 2.フォーマット
   ,ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_step                   VARCHAR2(10);                           -- ステップ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    sub_proc_expt             EXCEPTION;                              -- サブプログラムエラー
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
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --==============================================================
    -- A-1.  初期処理
    --==============================================================
    lv_step := 'A-1';
    proc_init(
      iv_file_id => iv_file_id          -- ファイルID
     ,iv_format  => iv_format           -- フォーマット
     ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-2.  ファイルアップロードIFデータ取得
    --==============================================================
    lv_step := 'A-2';
    get_if_data(                        -- get_if_dataをコール
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    -- A-3  品目一括登録ワークデータ取得
    --  A-4  データ妥当性チェック
    --  A-5  データ登録
    --==============================================================
    lv_step := 'A-3';
    loop_main(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --==============================================================
    -- A-6  終了処理
    --==============================================================
    lv_step := 'A-6';
    proc_comp(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    -- エラーがあればリターン・コードをエラーで返します。
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
    END IF;
    --
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
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
    errbuf        OUT    VARCHAR2       --   エラー・メッセージ  --# 固定 #
   ,retcode       OUT    VARCHAR2       --   エラーコード     #固定#
   ,iv_file_id    IN     VARCHAR2       --   ファイルID
   ,iv_format     IN     VARCHAR2       --   フォーマット
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
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
      iv_which   => cv_log
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    -- メッセージ(OUTPUT)出力
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_output
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_file_id => iv_file_id          -- ファイルID
     ,iv_format  => iv_format           -- フォーマット
     ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode => lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => ''
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
    --
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCMM004A05C;
/
