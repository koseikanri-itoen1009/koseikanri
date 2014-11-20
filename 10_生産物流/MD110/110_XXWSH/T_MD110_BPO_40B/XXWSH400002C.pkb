CREATE OR REPLACE PACKAGE BODY xxwsh400002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400002C(body)
 * Description      : 顧客発注からの出荷依頼自動作成
 * MD.050/070       : 出荷依頼                        (T_MD050_BPO_400)
 *                    顧客発注からの出荷依頼自動作成  (T_MD070_BPO_40B)
 * Version          : 1.26
 *
 * Program List
 * ------------------------ ----------------------------------------------------------
 *  Name                     Description
 * ------------------------ ----------------------------------------------------------
 *  pro_err_list_make        P エラーリスト作成
 *  pro_get_cus_option       P 関連データ取得                     (B-1)
 *  pro_param_chk            P 入力パラメータチェック             (B-2)
 *  pro_get_head_line        P 出荷依頼インターフェース情報取得   (B-3)
 *  pro_interface_chk        P インターフェイス情報チェック       (B-4)
 *  pro_day_time_chk         P 稼働日/リードタイムチェック        (B-5)
 *  pro_item_chk             P 明細情報マスタ存在チェック         (B-6)
 *  pro_xsr_chk              P 物流構成存在チェック               (B-7)
 *  pro_total_we_ca          P 合計重量/合計容積算出              (B-8)
 *  pro_ship_y_n_chk         P 出荷可否チェック                   (B-9)
 *  pro_lines_create         P 受注明細アドオンレコード作成       (B-10)
 *  pro_duplication_item_chk P 品目重複チェック                   (B-15)  -- 2008/10/14 H.Itou Add 統合テスト指摘118
 *  pro_load_eff_chk         P 積載効率チェック                   (B-11)
 *  pro_headers_create       P 受注ヘッダアドオンレコード作成     (B-12)
 *  pro_order_ins_del        P 受注アドオン出力                   (B-13)
 *  pro_purge_del            P パージ処理                         (B-14)
 *  submain                  P メイン処理プロシージャ
 *  main                     P コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/31    1.0   Tatsuya Kurata   新規作成
 *  2008/04/23    1.1   Tatsuya Kurata   内部変更要求#65対応
 *  2008/06/04    1.2   石渡  賢和       [pro_item_chk]IFされる数量をそのままセットするよう変更
 *                                       [pro_ship_y_n_chk]出荷可否チェック異常終了処理を追加
 *                                       [pro_order_ins_del]最新フラグを追加
 *  2008/06/04    1.3   椎名  昭圭       積載効率チェック修正
 *  2008/06/05    1.4   石渡  賢和       [pro_ship_y_n_chk]出荷可否チェックで出荷元IDを渡す変更
 *  2008/06/05    1.5   石渡  賢和       削除フラグにデフォルト値をセット
 *                                       １ヘッダ目は明細が削除されないため修正
 *  2008/06/10    1.6   石渡  賢和       エラーリストの数値項目前スペース埋めを削除
 *                                       xxwsh_common910_pkgの帰り値判定を修正
 *  2008/06/13    1.7   石渡  賢和       共通関数異常終了時のエラーリストを再調整
 *                                       明細重量の計算方法を修正
 *  2008/06/17    1.8   石渡  賢和       基本重量・基本容積のセット判断を修正
 *  2008/06/19    1.9   新藤  義勝       内部変更要求#143対応
 *  2008/06/24    1.10  石渡  賢和       ST不具合#247、#284対応
 *  2008/06/27    1.11  石渡  賢和       ST不具合#318対応
 *  2008/07/01    1.12  椎名  昭圭       ST不具合#247④対応
 *  2008/07/04    1.13  上原  正好       ST不具合#392対応
 *  2008/07/07    1.14  上原  正好       ST不具合#401対応
 *                                       積載効率チェックでのパレット最大枚数超過チェックの対象を
 *                                       ドリンク製品のみとする。
 *  2008/07/09    1.15  Oracle 山根一浩  I_S_192対応
 *  2008/08/05    1.16  二瓶  大輔       ST不具合#489対応
 *                                       カテゴリ情報VIEW変更
 *  2008/08/11    1.17  伊藤  ひとみ     結合テスト指摘#74 売上対象区分チェックは親品目の時のみ行う
 *                                       T_S_476,変更要求#178 品目廃止区分 「廃止」を「1」に変更
 *                                       内部課題#32 出荷単位換算数の換算ロジック変更
 *                                       変更要求#166 出荷単位換算数を明細単位で切り上げるように変更
 *  2008/08/20    1.18  伊藤  ひとみ     結合テスト指摘#87 出荷停止日エラー時 エラー項目：出荷予定日を「YYYY/MM/DD」形式で出力
 *                                       結合テスト指摘#89 配数整数倍チェックを警告に変更
 *                                       結合テスト指摘#91 エラーリスト出力項目から「摘要」「顧客発注番号」を削除
 *                                       出荷追加_1 積載効率チェックをヘッダ単位で行い、明細分エラーリストを出力する
 *  2008/08/26    1.19  伊藤  ひとみ     T_S_618 締めステータスチェックを追加
 *  2008/10/10    1.20  丸下             「依頼区分」から『受注タイプID』を取得の条件修正
 *  2008/10/14    1.21  伊藤  ひとみ     統合テスト指摘118 1依頼に重複品目がある場合はエラー終了とする。
 *                                       統合テスト指摘240 積載効率チェック(合計値算出)のINパラメータに基準日を追加。
 *  2008/11/20    1.22  伊藤  ひとみ     統合テスト指摘141,658対応
 *  2009/01/09    1.23  伊藤  ひとみ     本番障害#894対応
 *  2009/02/19    1.24  加波  由香里     本番障害#147対応
 *  2009/08/03    1.25  宮田  隆史       SCS障害管理表（0000918）対応：営業システム対応
 *  2011/03/28    1.26  堀籠  直樹       E_本稼動_2538対応
 *
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
--
--################################  固定部 END   ###############################
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
  -- 入力Ｐ格納用レコード変数
  TYPE rec_param_data  IS RECORD
    (
      in_base        VARCHAR2(30)   -- 入力拠点
     ,jur_base       VARCHAR2(30)   -- 管轄拠点
    );
--
  -- 出荷依頼インターフェース情報取得データ格納用レコード変数
  TYPE rec_head_line IS RECORD
    ( h_id         xxwsh_shipping_headers_if.header_id%TYPE             -- ヘッダID
     ,p_s_code     xxwsh_shipping_headers_if.party_site_code%TYPE       -- 出荷先
     ,ship_ins     xxwsh_shipping_headers_if.shipping_instructions%TYPE -- 摘要
     ,c_po_num     xxwsh_shipping_headers_if.cust_po_number%TYPE        -- 顧客発注
     ,o_r_ref      xxwsh_shipping_headers_if.order_source_ref%TYPE      -- 受注ソース参照
     ,ship_date    xxwsh_shipping_headers_if.schedule_ship_date%TYPE    -- 出荷予定日
     ,arr_date     xxwsh_shipping_headers_if.schedule_arrival_date%TYPE -- 着荷予定日
     ,lo_code      xxwsh_shipping_headers_if.location_code%TYPE         -- 出荷元保管場所
     ,h_s_branch   xxwsh_shipping_headers_if.head_sales_branch%TYPE     -- 管轄拠点
     ,data_type    xxwsh_shipping_headers_if.data_type%TYPE             -- データタイプ
     ,arr_t_from   xxwsh_shipping_headers_if.arrival_time_from%TYPE     -- 着荷時間From
     ,order_class  xxwsh_shipping_headers_if.ordered_class%TYPE         -- 依頼区分
     ,ord_i_code   xxwsh_shipping_lines_if.orderd_item_code%TYPE        -- 品目
     ,ord_quant    xxwsh_shipping_lines_if.orderd_quantity%TYPE         -- 数量
     ,in_sales_br  xxwsh_shipping_headers_if.input_sales_branch%TYPE    -- 入力拠点
-- 2008/08/20 H.Itou Add Start 出荷追加_1
     ,we_loading_msg_seq NUMBER                                         -- 積載効率(重量)メッセージ格納SEQ
     ,ca_loading_msg_seq NUMBER                                         -- 積載効率(容積)メッセージ格納SEQ
     ,prt_max_msg_seq    NUMBER                                         -- パレット最大枚数メッセージ格納SEQ
-- 2008/08/20 H.Itou Add End
-- 2008/10/14 H.Itou Add Start 統合テスト指摘240
     ,dup_item_msg_seq   NUMBER                                         -- 品目重複メッセージ格納SEQ
-- 2008/10/14 H.Itou Add End
-- 2009/08/03 T.Miyata Add Start SCS障害管理表（0000918）対応
     ,arr_t_to     xxwsh_shipping_headers_if.arrival_time_to%TYPE       -- 着荷時間To
-- 2009/08/03 T.Miyata Add End   SCS障害管理表（0000918）対応
    );
  TYPE tab_data_head_line IS TABLE OF rec_head_line INDEX BY PLS_INTEGER;
--
  -- エラーメッセージ出力用
  TYPE rec_err_msg IS RECORD
    (
      err_msg     VARCHAR2(10000)
    );
  TYPE tab_data_err_msg IS TABLE OF rec_err_msg INDEX BY BINARY_INTEGER;
--
  -- IFテーブル削除用
  TYPE tab_data_del_if IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;
  gn_normal_cnt    NUMBER;
  gn_error_cnt     NUMBER;
  gn_warn_cnt      NUMBER;
--
--################################  固定部 END   ###############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  err_expt                 EXCEPTION;
  err_header_expt          EXCEPTION;     -- エラーメッセージ作成後判定
  lock_error_expt          EXCEPTION;     -- ロックエラー
--
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ==================================================
  -- ユーザー定義グローバル定数
  -- ==================================================
-- 2008/11/20 H.Itou Add Start 統合テスト指摘658
  -- 共通関数戻り値判定
  gn_status_normal   CONSTANT NUMBER := 0; -- 正常
  gn_status_error    CONSTANT NUMBER := 1; -- 異常
-- 2008/11/20 H.Itou Add End
  gv_pkg_name        CONSTANT VARCHAR2(15) := 'xxwsh400002c';          -- パッケージ名
  -- プロファイル
  gv_prf_m_org       CONSTANT VARCHAR2(50) := 'XXCMN_MASTER_ORG_ID';   -- XXCMN:マスタ組織
  -- エラーメッセージコード
  gv_application     CONSTANT VARCHAR2(5)  := 'XXWSH';                 -- アプリケーション
  gv_err_cik         CONSTANT VARCHAR2(20) := 'APP-XXCMN-10121';
                                                     -- クイックコード取得エラーメッセージ
  gv_err_pro         CONSTANT VARCHAR2(20) := 'APP-XXWSH-11051';
                                                     -- プロファイル取得エラーメッセージ
  gv_err_lock        CONSTANT VARCHAR2(20) := 'APP-XXWSH-11052';
                                                     -- ロックエラーメッセージ
  gv_err_p_name      CONSTANT VARCHAR2(20) := 'APP-XXWSH-11054';
                                                     -- 入力パラメータマスタ未登録エラーメッセージ
  gv_err_para        CONSTANT VARCHAR2(20) := 'APP-XXWSH-11055';
                                                     -- 入力パラメータ未設定エラーメッセージ
  gv_err_no_con      CONSTANT VARCHAR2(20) := 'APP-XXWSH-11056';
                                                     -- 入力パラメータ不適合エラーメッセージ
  -- トークン
  gv_tkn_prof_name   CONSTANT VARCHAR2(10) := 'PROF_NAME';
  gv_tkn_lookup_type CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';
  gv_tkn_meaning     CONSTANT VARCHAR2(10) := 'MEANING';
  gv_tkn_para_name   CONSTANT VARCHAR2(15) := 'PARAMETER_NAME';
  gv_tkn_kyoten      CONSTANT VARCHAR2(10) := 'KYOTEN';
  -- トークン内メッセージ
  gv_tkn_msg_org     CONSTANT VARCHAR2(20) := 'XXCMN:マスタ組織';
  gv_tkn_msg_in_b    CONSTANT VARCHAR2(8)  := '入力拠点';
  gv_tkn_msg_ju_b    CONSTANT VARCHAR2(8)  := '管轄拠点';
  -- クイックコード
  gv_ship_method     CONSTANT VARCHAR2(20) := 'XXCMN_SHIP_METHOD';
  gv_tr_status       CONSTANT VARCHAR2(25) := 'XXWSH_TRANSACTION_STATUS';
  gv_notif_status    CONSTANT VARCHAR2(20) := 'XXWSH_NOTIF_STATUS';
  gv_shipping_class  CONSTANT VARCHAR2(20) := 'XXWSH_SHIPPING_CLASS';
--
  gv_all_item        CONSTANT VARCHAR2(7)  := 'ZZZZZZZ'; -- 全品目
  gv_order_c_code    CONSTANT VARCHAR2(5)  := 'ORDER';   -- 受注カテゴリコード
--
  gv_yes             CONSTANT VARCHAR2(1)  := 'Y';
  gv_no              CONSTANT VARCHAR2(1)  := 'N';
  gv_0               CONSTANT VARCHAR2(1)  := '0';
  gv_1               CONSTANT VARCHAR2(1)  := '1';
  gv_2               CONSTANT VARCHAR2(1)  := '2';
  gv_3               CONSTANT VARCHAR2(1)  := '3';
  gv_4               CONSTANT VARCHAR2(1)  := '4';
  gv_5               CONSTANT VARCHAR2(1)  := '5';
  gv_6               CONSTANT VARCHAR2(1)  := '6';
  gv_9               CONSTANT VARCHAR2(1)  := '9';
  gv_10              CONSTANT VARCHAR2(2)  := '10';
  gv_01              CONSTANT VARCHAR2(2)  := '01';
  gv_99              CONSTANT VARCHAR2(2)  := '99';
-- 2008/08/11 H.Itou MOD START 変更要求#178
--  gv_delete          CONSTANT VARCHAR2(1)  := 'D';
  gv_delete          CONSTANT VARCHAR2(1)  := '1';
-- 2008/08/11 H.Itou MOD END
-- 2008/08/26 H.Itou Add Start T_S_618
  -- 締めステータスチェック ステータス
  gv_inside_err         CONSTANT VARCHAR2(2)   := '-1'; -- 内部エラー
  gv_close_proc_n_enfo  CONSTANT VARCHAR2(1)   := '1';  -- 締め処理未実施
  gv_first_close_fin    CONSTANT VARCHAR2(1)   := '2';  -- 初回締め済
  gv_close_cancel       CONSTANT VARCHAR2(1)   := '3';  -- 締め解除
  gv_re_close_fin       CONSTANT VARCHAR2(1)   := '4';  -- 再締め済
-- 2008/08/26 H.Itou Add End
--
  gv_ship_st         CONSTANT VARCHAR2(6)  := '入力中';
  gv_notice_st       CONSTANT VARCHAR2(6)  := '未通知';
  -- エラーリスト項目名
  gv_name_kind       CONSTANT VARCHAR2(4)  := '種別';
  gv_name_dec        CONSTANT VARCHAR2(4)  := '確定';
  gv_name_req_no     CONSTANT VARCHAR2(8)  := '依頼Ｎｏ';
  gv_name_ship_to    CONSTANT VARCHAR2(6)  := '配送先';
  gv_name_descrip    CONSTANT VARCHAR2(4)  := '摘要';
  gv_name_cust_pono  CONSTANT VARCHAR2(12) := '顧客発注番号';
  gv_name_ship_date  CONSTANT VARCHAR2(6)  := '出庫日';
  gv_name_arr_date   CONSTANT VARCHAR2(4)  := '着日';
  gv_name_ship_from  CONSTANT VARCHAR2(6)  := '出荷元';
  gv_name_item_a     CONSTANT VARCHAR2(4)  := '品目';
  gv_name_qty        CONSTANT VARCHAR2(4)  := '数量';
  gv_name_err_msg    CONSTANT VARCHAR2(16) := 'エラーメッセージ';
  gv_name_err_clm    CONSTANT VARCHAR2(10) := 'エラー項目';
  gv_line            CONSTANT VARCHAR2(25) := '-------------------------';
  -- エラーリスト表示内容
  gv_msg_hfn         CONSTANT VARCHAR2(2)  := '－';
  gv_msg_err         CONSTANT VARCHAR2(6)  := 'エラー';
  gv_msg_war         CONSTANT VARCHAR2(4)  := '警告';
  gv_msg_1           CONSTANT VARCHAR2(28) := '『出荷先』設定されていません';
  gv_msg_2           CONSTANT VARCHAR2(36) := '『受注ソース参照』設定されていません';
  gv_msg_3           CONSTANT VARCHAR2(32) := '『出荷予定日』設定されていません';
  gv_msg_4           CONSTANT VARCHAR2(32) := '『着荷予定日』設定されていません';
  gv_msg_5           CONSTANT VARCHAR2(36) := '『出荷元保管場所』設定されていません';
  gv_msg_6           CONSTANT VARCHAR2(30) := '『管轄拠点』設定されていません';
  gv_msg_7           CONSTANT VARCHAR2(34) := '『データタイプ』設定されていません';
  gv_msg_8           CONSTANT VARCHAR2(26) := '『品目』設定されていません';
  gv_msg_9           CONSTANT VARCHAR2(26) := '『数量』設定されていません';
  gv_msg_10          CONSTANT VARCHAR2(46) := '『出荷先』がパーティマスタに登録されていません';
  gv_msg_11          CONSTANT VARCHAR2(50) := '『出荷元』がOPM保管場所マスタに登録されていません';
  gv_msg_12          CONSTANT VARCHAR2(48) := '『管轄拠点』がパーティマスタに登録されていません';
  gv_msg_13          CONSTANT VARCHAR2(34) := '『商品区分』が取得できませんでした';
  gv_msg_14          CONSTANT VARCHAR2(68) :=
                             '『依頼区分』に対する受注タイプが受注タイプマスタに登録されていません';
  gv_msg_15          CONSTANT VARCHAR2(52) := '『中止客申請フラグ』に「0」以外がセットされています';
  gv_msg_16          CONSTANT VARCHAR2(32) := '着荷予定日は稼働日ではありません';
  gv_msg_17          CONSTANT VARCHAR2(32) := '出荷予定日は稼働日ではありません';
  gv_msg_18          CONSTANT VARCHAR2(16) := 'リードタイム算出';
  gv_msg_19          CONSTANT VARCHAR2(30) := '配送リードタイムを満たせません';
  gv_msg_20          CONSTANT VARCHAR2(34) := '生産物流リードタイムを満たせません';
  gv_msg_21          CONSTANT VARCHAR2(26) := '在庫会計期間クローズエラー';
  gv_msg_22          CONSTANT VARCHAR2(30) := '品目マスタに登録されていません';
  gv_msg_23          CONSTANT VARCHAR2(26) := '出荷可能品目ではありません';
  gv_msg_24          CONSTANT VARCHAR2(48) := '『売上対象区分』に「1」以外がセットされています';
-- 2008/08/11 H.Itou MOD START 変更要求#178
--  gv_msg_25          CONSTANT VARCHAR2(40) := '『廃止区分』に「D」がセットされています';
  gv_msg_25          CONSTANT VARCHAR2(40) := '『廃止区分』に「1」がセットされています';
-- 2008/08/11 H.Itou MOD END
  gv_msg_26          CONSTANT VARCHAR2(42) := '『率区分』に「0」以外がセットされています';
  gv_msg_27          CONSTANT VARCHAR2(52) := '品目マスタにパレット当り最大段数が登録されていません';
  gv_msg_28          CONSTANT VARCHAR2(36) := '品目マスタに配数が登録されていません';
  gv_msg_29          CONSTANT VARCHAR2(34) := '物流ルートとして登録されていません';
  gv_msg_30          CONSTANT VARCHAR2(42) := '引取計画において、出荷可能数を超えています';
  gv_msg_31          CONSTANT VARCHAR2(50) := '出荷数制限(商品部)において出荷可能数を超えています';
  gv_msg_32          CONSTANT VARCHAR2(50) := '出荷数制限(物流部)において出荷可能数を超えています';
  gv_msg_33          CONSTANT VARCHAR2(62) :=
                             '出荷数制限(物流部)において出荷予定日が出荷停止日を過ぎています';
  gv_msg_34          CONSTANT VARCHAR2(48) := '計画商品引取計画において出荷可能数を超えています';
  gv_msg_35          CONSTANT VARCHAR2(40) := '『数量』が『配数』の整数倍ではありません';
  gv_msg_36          CONSTANT VARCHAR2(44) := '『数量』が『出荷入数』の整数倍ではありません';
  gv_msg_37          CONSTANT VARCHAR2(40) := '『数量』が『入数』の整数倍ではありません';
  gv_msg_38          CONSTANT VARCHAR2(32) := 'パレット最大枚数を超過しています';
  gv_msg_39          CONSTANT VARCHAR2(16) := '積載オーバーです';
  gv_msg_40          CONSTANT VARCHAR2(46) := '重量容積区分が異なっている品目が含まれています';
  gv_msg_41          CONSTANT VARCHAR2(56) :=
                             '対象の依頼Noデータがステータス確定済み以上で登録済みです';
  gv_msg_42          CONSTANT VARCHAR2(20) := '最大配送区分エラー';
  gv_msg_43          CONSTANT VARCHAR2(26) := '引当対象外の出庫元倉庫です';
-- 2008/08/26 H.Itou Add Start T_S_618
  gv_msg_44          CONSTANT VARCHAR2(50) := '対象の出荷日は既に締め済みです';
  gv_msg_45          CONSTANT VARCHAR2(50) := '締めステータスチェックエラー';
-- 2008/08/26 H.Itou Add End
-- 2008/10/14 H.Itou Add Start 統合テスト指摘118
  gv_msg_46          CONSTANT VARCHAR2(50) := '１依頼内に同一品目が重複しています';
-- 2008/10/14 H.Itou Add End
-- 2008/11/20 H.Itou Add Start 統合テスト指摘658
  gv_msg_47          CONSTANT VARCHAR2(50) := '稼働日取得エラー';
-- 2008/11/20 H.Itou Add End
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate         DATE;              -- システム現在日付
  gv_err_flg         VARCHAR2(1);       -- エラー確認用フラグ
  gv_err_sts         VARCHAR2(1);       -- 共通エラーメッセージ 終了ST確認用F
  gv_name_m_org      VARCHAR2(20);      -- マスタ組織
  gv_del_if_flg      VARCHAR2(1);       -- IFテーブル削除対象フラグ
--
  -- WHOカラム取得用
  gn_created_by      NUMBER;            -- 作成者
  gd_creation_date   DATE;              -- 作成日
  gd_last_upd_date   DATE;              -- 最終更新日
  gn_last_upd_by     NUMBER;            -- 最終更新者
  gn_last_upd_login  NUMBER;            -- 最終更新ログイン
  gn_request_id      NUMBER;            -- 要求ID
  gn_prog_appl_id    NUMBER;            -- プログラムアプリケーションID
  gn_prog_id         NUMBER;            -- プログラムID
  gd_prog_upd_date   DATE;              -- プログラム更新日
--
  gv_err_report      VARCHAR2(5000);
--
  gd_arr_work_day    DATE;              -- 稼働日(着荷)
  gd_shi_work_day    DATE;              -- 稼働日(出荷)
  gd_de_past_day     DATE;              -- 稼働日日付(過・配送)
  gd_past_day        DATE;              -- 稼働日日付(過・生産)
  gv_req_no          VARCHAR2(12);      -- 採番したNo
  gv_leadtime        VARCHAR2(20);      -- 生産物流LT/引取変更LT
  gv_delivery_lt     VARCHAR2(20);      -- 配送リードタイム
  gv_max_kbn         VARCHAR2(2);       -- 最大配送区分
  gv_opm_c_p         VARCHAR2(6);       -- OPM在庫会計期間 CLOSE最大年月
  gv_wei_kbn         VARCHAR2(1);       -- 重量容積区分(B-12比較用)
  gv_over_kbn        VARCHAR2(1);       -- 積載オーバー区分
  gv_ship_way        VARCHAR2(2);       -- 出荷方法
  gv_mix_ship        VARCHAR2(2);       -- 混載配送区分
  gv_new_order_no    VARCHAR2(12);      -- 依頼No(12桁用)
  gn_drink_we        NUMBER;            -- ドリンク積載重量
  gn_leaf_we         NUMBER;            -- リーフ積載重量
  gn_drink_ca        NUMBER;            -- ドリンク積載容積
  gn_leaf_ca         NUMBER;            -- リーフ積載容積
  gn_prt_max         NUMBER;            -- パレット最大枚数
  gn_ttl_we          NUMBER;            -- 合計重量
  gn_ttl_ca          NUMBER;            -- 合計容積
  gn_ttl_prt_we      NUMBER;            -- 合計パレット重量
  gn_detail_we       NUMBER;            -- 明細重量
  gn_detail_ca       NUMBER;            -- 明細容積
  gn_ship_amount     NUMBER;            -- 出荷単位換算数
  gn_we_loading      NUMBER;            -- 重量積載効率
  gn_ca_loading      NUMBER;            -- 容積積載効率
  gn_we_dammy        NUMBER;            -- 重量積載効率(ダミー)
  gn_ca_dammy        NUMBER;            -- 容積積載効率(ダミー)
  gn_item_amount     NUMBER;            -- 数量
--
  gn_i               NUMBER;            -- LOOPカウント用
  gn_headers_seq     NUMBER;            -- 受注ヘッダアドオンID_SEQ
  gn_lines_seq       NUMBER;            -- 受注明細アドオンID_SEQ
--
  gn_cut             NUMBER DEFAULT 0;  -- エラーメッセージ用カウント
  gn_line_number     NUMBER DEFAULT 0;  -- 明細番号
  gn_p_max_case_am   NUMBER DEFAULT 0;  -- パレット当り最大ケース数
  gn_case_total      NUMBER DEFAULT 0;  -- ケース総合計
  gn_pallet_am       NUMBER DEFAULT 0;  -- パレット数
  gn_step_am         NUMBER DEFAULT 0;  -- 段数
  gn_case_am         NUMBER DEFAULT 0;  -- ケース数
  gn_pallet_co_am    NUMBER DEFAULT 0;  -- パレット枚数
  gn_pallet_t_c_am   NUMBER DEFAULT 0;  -- パレット合計枚数
  gn_ttl_ship_am     NUMBER DEFAULT 0;  -- 出荷単位換算数
  gn_h_ttl_weight    NUMBER DEFAULT 0;  -- 積載重量合計
  gn_h_ttl_capa      NUMBER DEFAULT 0;  -- 積載容積合計
  gn_h_ttl_pallet    NUMBER DEFAULT 0;  -- 合計パレット重量
  gn_basic_we        NUMBER DEFAULT 0;  -- 基本重量
  gn_basic_ca        NUMBER DEFAULT 0;  -- 基本容積
  gn_ttl_amount      NUMBER DEFAULT 0;  -- 合計数量
--
  gn_sh_h_cnt        NUMBER DEFAULT 0;  -- 出荷依頼インターフェイスヘッダ件数
  gn_req_cnt         NUMBER DEFAULT 0;  -- 出荷依頼作成件数(依頼Ｎｏ単位)
  gn_line_cnt        NUMBER DEFAULT 0;  -- 出荷依頼作成明細件数(依頼明細単位)
--
  gv_small_qty_flg   NUMBER DEFAULT 0;  -- 小口区分フラグ
--
  ord_l_all        xxwsh_order_lines_all%ROWTYPE;                   -- 受注明細アドオン登録用項目
  ord_h_all        xxwsh_order_headers_all%ROWTYPE;                 -- 受注ヘッダアドオン登録用項目
--
  gr_h_id          xxwsh_shipping_headers_if.header_id%TYPE;               -- ヘッダID
  gr_o_r_ref       xxwsh_shipping_headers_if.order_source_ref%TYPE;        -- 受注ソース参照
  gr_ship_st       xxcmn_lookup_values2_v.lookup_code%TYPE;                -- 出荷依頼ステータス
  gr_notice_st     xxcmn_lookup_values2_v.lookup_code%TYPE;                -- 通知ステータス
  gr_odr_type      xxwsh_oe_transaction_types2_v.transaction_type_id%TYPE; -- 受注タイプID
  gr_o_ship_div    xxcmn_locations_v.other_shipment_div%TYPE;          -- 他拠点出荷依頼作成可否区分
--
  gr_p_site_id     xxcmn_party_sites_v.party_site_id%TYPE;                 -- 出荷先ID
  gr_c_acc_num     xxcmn_parties_v.cust_account_id%TYPE;                   -- 顧客ID
  gr_party_num     xxcmn_parties_v.party_number%TYPE;                      -- 顧客
  gr_cus_c_code    xxcmn_parties_v.customer_class_code%TYPE;               -- 顧客区分
  gr_cus_en_flag   xxcmn_parties_v.cust_enable_flag%TYPE;                  -- 中止客申請フラグ
--
  gr_ship_id       xxcmn_item_locations_v.inventory_location_id%TYPE;      -- 保管棚ID
  gr_a_p_flag      xxcmn_item_locations_v.allow_pickup_flag%TYPE;          -- 出荷引当対象フラグ
  gr_fre_mover     xxcmn_item_locations_v.frequent_mover%TYPE;             -- 代表運送会社
--
  gr_party_number  xxcmn_carriers_v.party_number%TYPE;                     -- 代表運送会社
  gr_party_id      xxcmn_carriers_v.party_id%TYPE;                         -- 代表運送会社ID
--
  gr_skbn          xxcmn_item_categories5_v.prod_class_code%TYPE;          -- 商品区分
  gr_wei_kbn       xxcmn_item_mst_v.weight_capacity_class%TYPE;            -- 重量容積区分
--
  gr_i_item_id     xxcmn_item_mst2_v.inventory_item_id%TYPE;               -- 品目ID
  gr_item_um       xxcmn_item_mst2_v.item_um%TYPE;                         -- 単位
  gr_conv_unit     xxcmn_item_mst2_v.conv_unit%TYPE;                       -- 入出庫換算単位
  gr_case_am       xxcmn_item_mst2_v.num_of_cases%TYPE;                    -- 入数
  gr_item_skbn     xxcmn_item_categories5_v.prod_class_code%TYPE;          -- 商品区分
  gr_item_kbn      xxcmn_item_categories5_v.item_class_code%TYPE;          -- 品目区分
  gr_max_p_step    xxcmn_item_mst2_v.max_palette_steps%TYPE;               -- パレット当り最大段数
  gr_del_qty       xxcmn_item_mst2_v.delivery_qty%TYPE;                    -- 配数
  gr_i_wei_kbn     xxcmn_item_mst2_v.weight_capacity_class%TYPE;           -- 重量容積区分
  gr_out_kbn       xxcmn_item_mst2_v.ship_class%TYPE;                      -- 出荷区分
  gr_ship_am       xxcmn_item_mst2_v.num_of_deliver%TYPE;                  -- 出荷入数
  gr_sale_kbn      xxcmn_item_mst2_v.sales_div%TYPE;                       -- 売上対象区分
  gr_end_kbn       xxcmn_item_mst2_v.obsolete_class%TYPE;                  -- 廃止区分
  gr_rit_kbn       xxcmn_item_mst2_v.rate_class%TYPE;                      -- 率区分
-- 2008/08/11 H.Itou ADD START 結合指摘#74
  gr_parent_item_id xxcmn_item_mst2_v.parent_item_id%TYPE;                 -- 親品目ID
  gr_item_id        xxcmn_item_mst2_v.item_id%TYPE;                        -- OPM品目ID
-- 2008/08/11 H.Itou ADD END
  gr_ord_he_id     xxwsh_order_headers_all.order_header_id%TYPE;           -- 受注ヘッダアドオンID
  gr_req_status    xxwsh_order_headers_all.req_status%TYPE;                -- ステータス
--
  gr_param         rec_param_data;                        -- 入力パラメータ
  gt_head_line     tab_data_head_line;                    -- 出荷依頼インターフェース情報取得データ
  gt_err_msg       tab_data_err_msg;                      -- エラーメッセージ出力用
  gt_del_if        tab_data_del_if;                       -- IFテーブル削除用
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
  /**********************************************************************************
   * Procedure Name   : pro_err_list_make
   * Description      : エラーリスト作成
   ***********************************************************************************/
  PROCEDURE pro_err_list_make
    (
      iv_kind          IN VARCHAR2     --   エラー種別
     ,iv_dec           IN VARCHAR2     --   確定処理でのチェック
     ,iv_req_no        IN VARCHAR2     --   依頼No
     ,iv_kyoten        IN VARCHAR2     --   管轄拠点
     ,iv_ship_to       IN VARCHAR2     --   配送先
     ,iv_description   IN VARCHAR2     --   摘要
     ,iv_cust_pono     IN VARCHAR2     --   顧客発注番号
     ,iv_ship_date     IN VARCHAR2     --   出庫日
     ,iv_arrival_date  IN VARCHAR2     --   着日
     ,iv_ship_from     IN VARCHAR2     --   出荷元
     ,iv_item          IN VARCHAR2     --   品目
     ,in_qty           IN NUMBER       --   数量
     ,iv_err_msg       IN VARCHAR2     --   エラーメッセージ
     ,iv_err_clm       IN VARCHAR2     --   エラー項目
-- 2008/08/20 H.Itou Add Start 出荷追加_1
     ,in_msg_seq       IN NUMBER DEFAULT NULL-- -- メッセージ格納SEQ
-- 2008/08/20 H.Itou Add End
     ,ov_errbuf       OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode      OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg       OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_err_list_make'; -- プログラム名
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
    lv_err_msg        VARCHAR2(10000);
    lv_ship_date      VARCHAR2(10);
    ln_qty            NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 数量がNULLの場合、０表示
    IF (in_qty IS NULL) THEN
      ln_qty := NVL(in_qty,0);
    ELSE
      ln_qty := in_qty;
    END IF;
    ---------------------------------
    -- 共通エラーメッセージの作成  --
    ---------------------------------
-- 2008/08/20 H.Itou Del Start 出荷追加_1
--    -- テーブルカウント
--    gn_cut := gn_cut + 1;
-- 2008/08/20 H.Itou Del End
--
    lv_err_msg := iv_kind      || CHR(9) || iv_dec       || CHR(9) || iv_req_no       || CHR(9) ||
-- 2008/08/20 H.Itou Mod Start 結合テスト指摘#91
--                  iv_kyoten    || CHR(9) || iv_ship_to   || CHR(9) || iv_description  || CHR(9) ||
--                  iv_cust_pono || CHR(9) || iv_ship_date || CHR(9) || iv_arrival_date || CHR(9) ||
                  iv_kyoten    || CHR(9) || iv_ship_to   || CHR(9) || 
                  iv_ship_date || CHR(9) || iv_arrival_date || CHR(9) ||
-- 2008/08/20 H.Itou Mod End
                  iv_ship_from || CHR(9) || iv_item      || CHR(9) ||
                  TO_CHAR(ln_qty,'FM999,999,990.000')    || CHR(9) ||
                  iv_err_msg   || CHR(9) || iv_err_clm;
--
-- 2008/08/20 H.Itou Add Start 出荷追加_1
    -- 積載効率メッセージ格納SEQに値がある場合、積載効率エラーなので、指定箇所にセット
    IF (in_msg_seq IS NOT NULL) THEN
      gt_err_msg(in_msg_seq).err_msg  := lv_err_msg;
--
    -- それ以外は、テーブルカウントを進めてセット
    ELSE
      -- テーブルカウント
      gn_cut := gn_cut + 1;
-- 2008/08/20 H.Itou Add End
      -- 共通エラーメッセージ格納
      gt_err_msg(gn_cut).err_msg  := lv_err_msg;
-- 2008/08/20 H.Itou Add Start 出荷追加_1
    END IF;
-- 2008/08/20 H.Itou Add End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_err_list_make;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_cus_option
   * Description      : 関連データ取得 (B-1)
   ***********************************************************************************/
  PROCEDURE pro_get_cus_option
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_cus_option'; -- プログラム名
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
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- WHOカラム取得
    gn_created_by     := FND_GLOBAL.USER_ID;           -- 作成者
    gd_creation_date  := gd_sysdate;                   -- 作成日
    gn_last_upd_by    := FND_GLOBAL.USER_ID;           -- 最終更新日
    gd_last_upd_date  := gd_sysdate;                   -- 最終更新者
    gn_last_upd_login := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
    gn_request_id     := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
    gn_prog_appl_id   := FND_GLOBAL.PROG_APPL_ID;      -- プログラムアプリケーションID
    gn_prog_id        := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
    gd_prog_upd_date  := gd_sysdate;                   -- プログラム更新日
--
    --------------------------------------------------
    -- クイックコードから出荷依頼ステータス情報取得
    --------------------------------------------------
    BEGIN
--
      -- 出荷依頼ステータス[入力中]コード抽出
      SELECT xlvv.lookup_code
      INTO   gr_ship_st
      FROM   xxcmn_lookup_values_v  xlvv  -- クイックコード情報 V
      WHERE  xlvv.lookup_type = gv_tr_status
      AND    xlvv.meaning     = gv_ship_st;
--
    EXCEPTION
      -- クイックコードが存在しない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( 'XXCMN'
                                                       ,gv_err_cik          -- クイックＣ取得エラー
                                                       ,gv_tkn_lookup_type  -- トークン
                                                       ,gv_tr_status
                                                       ,gv_tkn_meaning      -- トークン
                                                       ,gv_ship_st
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
    END;
--
    --------------------------------------------------
    -- クイックコードから通知ステータス情報取得
    --------------------------------------------------
    BEGIN
--
      -- 通知ステータス[未通知]コード抽出
      SELECT xlvv.lookup_code
      INTO   gr_notice_st
      FROM   xxcmn_lookup_values_v  xlvv  -- クイックコード情報 V
      WHERE  xlvv.lookup_type = gv_notif_status
      AND    xlvv.meaning     = gv_notice_st;
--
    EXCEPTION
      -- クイックコードが存在しない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( 'XXCMN'
                                                       ,gv_err_cik          -- クイックＣ取得エラー
                                                       ,gv_tkn_lookup_type  -- トークン
                                                       ,gv_notif_status
                                                       ,gv_tkn_meaning      -- トークン
                                                       ,gv_notice_st
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
    END;
--
    ------------------------------------------
    -- プロファイルからマスタ組織取得
    ------------------------------------------
    gv_name_m_org := SUBSTRB(FND_PROFILE.VALUE(gv_prf_m_org),1,20);
    -- 取得エラー時
    IF (gv_name_m_org IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXWSH'
                                                     ,gv_err_pro        -- プロファイル取得エラー
                                                     ,gv_tkn_prof_name  -- トークン
                                                     ,gv_tkn_msg_org    -- メッセージ
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_get_cus_option;
--
  /**********************************************************************************
   * Procedure Name   : pro_param_chk
   * Description      : 入力パラメータチェック   (B-2)
   ***********************************************************************************/
  PROCEDURE pro_param_chk
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_param_chk'; -- プログラム名
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
    ln_in_base_cnt     NUMBER;       -- 入力拠点用
    ln_jur_base_cnt    NUMBER;       -- 管轄拠点用
    lv_party_number    VARCHAR2(4);  -- 組織番号
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------
    -- 入力Ｐ「入力拠点」の取得
    ------------------------------------------
    -- 取得エラー時
    IF (gr_param.in_base IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_para        -- 必須入力Ｐ未設定エラー
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    -------------------------------------------------------------------------
    -- 顧客マスタ・パーティマスタに拠点が登録されているかどうかの判定
    -------------------------------------------------------------------------
    SELECT COUNT (xcav.account_number)
    INTO   ln_in_base_cnt
    FROM   xxcmn_cust_accounts_v  xcav  -- 顧客情報 V
    WHERE  xcav.account_number      = gr_param.in_base   -- 入力Ｐ[入力拠点]
    AND    xcav.customer_class_code = gv_1               -- '拠点'を示す「コード区分」
    AND    ROWNUM                   = 1;
--
    -- 入力Ｐ[入力拠点]が顧客マスタに存在しない場合
    IF (ln_in_base_cnt = 0) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_p_name      -- マスタ未登録エラー
                                                     ,gv_tkn_para_name   -- トークン
                                                     ,gv_tkn_msg_in_b    -- '入力拠点'
                                                     ,gv_tkn_kyoten      -- トークン
                                                     ,gr_param.in_base   -- 入力Ｐ[入力拠点]
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ---------------------------------------------------------------------------------------------
    -- 入力Ｐ「入力拠点」がログインユーザの所属するパーティマスタ.組織番号と同一かどうかの判定
    ---------------------------------------------------------------------------------------------
    -- ログインユーザに紐づく事業所マスタ.他拠点出荷依頼作成可否区分取得
    SELECT xlv.other_shipment_div
    INTO gr_o_ship_div
    FROM  fnd_user               fu   -- ユーザマスタ     T
         ,per_all_assignments_f  paaf -- 従業員割当マスタ T
         ,xxcmn_locations_v      xlv  -- 事業所情報       V
    WHERE fu.user_id                 = FND_GLOBAL.USER_ID  -- ログインユーザのユーザID
    AND   paaf.person_id             = fu.employee_id      -- 従業員ID
    AND   xlv.location_id            = paaf.location_id    -- 事業所ID
    AND   paaf.effective_start_date <= gd_sysdate          -- 有効開始日
    AND   paaf.effective_end_date   >= gd_sysdate          -- 有効終了日
    ;
--
    -- 他拠点出荷依頼作成可否区分 = '0'(不可)の場合
    IF (gr_o_ship_div = gv_0) THEN
      BEGIN
        SELECT xcav.party_number           -- 組織番号
        INTO   lv_party_number
        FROM   fnd_user               fu   -- ユーザマスタ     T
              ,per_all_assignments_f  paaf -- 従業員割当マスタ T
              ,xxcmn_locations_v      xlv  -- 事業所情報       V
              ,xxcmn_cust_accounts_v  xcav -- 顧客情報        V
        WHERE  xcav.customer_class_code   = gv_1                -- 顧客区分 拠点 '1'
        AND    fu.user_id                 = FND_GLOBAL.USER_ID  -- ログインユーザのユーザID
        AND    paaf.person_id             = fu.employee_id      -- 従業員ID
        AND    xlv.location_id            = paaf.location_id    -- 事業所ID
        AND    xcav.party_number          = xlv.location_code   -- 事業所コード
        AND    paaf.effective_start_date <= gd_sysdate          -- 有効開始日
        AND    paaf.effective_end_date   >= gd_sysdate          -- 有効終了日
        ;
        -- 入力Ｐ「入力拠点」の値が、ログインユーザの所属部署と異なる場合、エラー
        IF (gr_param.in_base <> lv_party_number) THEN
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                         ,gv_err_no_con      -- 入力Ｐ不適合エラー
                                                         ,gv_tkn_kyoten      -- トークン
                                                         ,gr_param.in_base   -- 入力Ｐ[入力拠点]
                                                        )
                                                        ,1
                                                        ,5000);
          RAISE global_api_expt;
        END IF;
      EXCEPTION
        WHEN err_expt THEN
          RAISE global_api_expt;
      END;
    END IF;
--
    ------------------------------------------
    -- 入力Ｐ「管轄拠点」の取得
    ------------------------------------------
    -- 取得エラー時
    IF (gr_param.jur_base IS NOT NULL) THEN
      -- 顧客マスタ・パーティマスタに拠点が登録されているかどうかの判定
      SELECT COUNT (xcav.account_number)
      INTO   ln_jur_base_cnt
      FROM   xxcmn_cust_accounts_v   xcav  -- 顧客情報 V
      WHERE  xcav.account_number      = gr_param.jur_base  -- 入力Ｐ[管轄拠点]
      AND    xcav.customer_class_code = gv_1               -- '拠点'を示す「コード区分」
      AND    ROWNUM                   = 1;
    END IF;
--
    -- 入力Ｐ[管轄拠点]が顧客マスタに存在しない場合
    IF (ln_jur_base_cnt = 0) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_p_name      -- マスタ未登録エラー
                                                     ,gv_tkn_para_name   -- トークン
                                                     ,gv_tkn_msg_ju_b    -- '管轄拠点'
                                                     ,gv_tkn_kyoten      -- トークン
                                                     ,gr_param.jur_base  -- 入力Ｐ[管轄拠点]
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_param_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_head_line
   * Description      : 出荷依頼インターフェース情報取得   (B-3)
   ***********************************************************************************/
  PROCEDURE pro_get_head_line
    (
      ot_head_line    OUT NOCOPY tab_data_head_line    --   取得レコード群
     ,ov_errbuf       OUT VARCHAR2                     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode      OUT VARCHAR2                     --   リターン・コード             --# 固定 #
     ,ov_errmsg       OUT VARCHAR2                     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_head_line'; -- プログラム名
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
    -- ローカル・カーソル
    -- ===============================
    -- 行ロック用カーソル
    CURSOR cur_get_lock
    IS
      SELECT xshi.header_id
      FROM  xxwsh_shipping_headers_if  xshi -- 出荷依頼インタフェースヘッダ（アドオン）
           ,xxwsh_shipping_lines_if    xsli -- 出荷依頼インタフェース明細（アドオン）
      WHERE xshi.data_type          = gv_10      -- [出荷依頼]を表すクイックコード「データタイプ」
      AND   xshi.header_id          = xsli.header_id     -- ヘッダID
      AND   xshi.input_sales_branch = gr_param.in_base   -- 入力Ｐ[入力拠点]
      FOR UPDATE NOWAIT
      ;
--
    -- 入力Ｐ「入力拠点」のみデータが存在している場合
    CURSOR cur_get_head_line
    IS
      SELECT xshi.header_id              AS h_id        -- ヘッダID
            ,xshi.party_site_code        AS p_s_code    -- 出荷先
            ,xshi.shipping_instructions  AS ship_ins    -- 出荷指示
            ,xshi.cust_po_number         AS c_po_num    -- 顧客発注
            ,xshi.order_source_ref       AS o_r_ref     -- 受注ソース参照
            ,xshi.schedule_ship_date     AS ship_date   -- 出荷予定日
            ,xshi.schedule_arrival_date  AS arr_date    -- 着荷予定日
            ,xshi.location_code          AS lo_code     -- 出荷元
            ,xshi.head_sales_branch      AS h_s_branch  -- 管轄拠点
            ,xshi.data_type              AS data_type   -- データタイプ
            ,xshi.arrival_time_from      AS arr_t_from  -- 着荷時間From
            ,xshi.ordered_class          AS order_class -- 依頼区分
            ,xsli.orderd_item_code       AS ord_i_code  -- 受注品目
            ,xsli.orderd_quantity        AS ord_quant   -- 数量
            ,xshi.input_sales_branch     AS in_sales_br -- 入力拠点
-- 2008/08/20 H.Itou Add Start 出荷追加_1
            ,NULL                                       -- 積載効率(重量)メッセージ格納SEQ
            ,NULL                                       -- 積載効率(容積)メッセージ格納SEQ
            ,NULL                                       -- パレット最大枚数メッセージ格納SEQ
-- 2008/08/20 H.Itou Add End
-- 2008/10/14 H.Itou Add Start 統合テスト指摘240
            ,NULL                                       -- 品目重複メッセージ格納SEQ
-- 2008/10/14 H.Itou Add End
-- 2009/08/03 T.Miyata Add Start SCS障害管理表（0000918）対応
            ,xshi.arrival_time_to        AS arr_t_to    -- 着荷時間To
-- 2009/08/03 T.Miyata Add End   SCS障害管理表（0000918）対応
      FROM (SELECT xshi1.header_id
                  ,MAX (xshi1.last_update_date)
                   OVER (PARTITION BY xshi1.order_source_ref) max_date
            FROM  xxwsh_shipping_headers_if xshi1
           ) max_id
           ,xxwsh_shipping_headers_if  xshi -- 出荷依頼インタフェースヘッダ（アドオン）
           ,xxwsh_shipping_lines_if    xsli -- 出荷依頼インタフェース明細（アドオン）
      WHERE xshi.header_id          = max_id.header_id    -- 最終更新日が最大のヘッダID
      AND   xshi.last_update_date   = max_id.max_date     -- 最終更新日(最大)
      AND   xshi.data_type          = gv_10      -- [出荷依頼]を表すクイックコード「データタイプ」
      AND   xshi.header_id          = xsli.header_id     -- ヘッダID
      AND   xshi.input_sales_branch = gr_param.in_base   -- 入力Ｐ[入力拠点]
      ORDER BY xshi.order_source_ref -- 受注ソース参照
              ,xsli.line_id          -- 明細ID
      ;
    -- 入力Ｐ「入力拠点」「管轄拠点」の両方にデータが存在している場合
    CURSOR cur_get_head_line_2
    IS
      SELECT xshi.header_id              AS h_id        -- ヘッダID
            ,xshi.party_site_code        AS p_s_code    -- 出荷先
            ,xshi.shipping_instructions  AS ship_ins    -- 出荷指示
            ,xshi.cust_po_number         AS c_po_num    -- 顧客発注
            ,xshi.order_source_ref       AS o_r_ref     -- 受注ソース参照
            ,xshi.schedule_ship_date     AS ship_date   -- 出荷予定日
            ,xshi.schedule_arrival_date  AS arr_date    -- 着荷予定日
            ,xshi.location_code          AS lo_code     -- 出荷元
            ,xshi.head_sales_branch      AS h_s_branch  -- 管轄拠点
            ,xshi.data_type              AS data_type   -- データタイプ
            ,xshi.arrival_time_from      AS arr_t_from  -- 着荷時間From
            ,xshi.ordered_class          AS order_class -- 依頼区分
            ,xsli.orderd_item_code       AS ord_i_code  -- 受注品目
            ,xsli.orderd_quantity        AS ord_quant   -- 数量
            ,xshi.input_sales_branch     AS in_sales_br -- 入力拠点
-- 2008/08/20 H.Itou Add Start 出荷追加_1
            ,NULL                                       -- 積載効率(重量)メッセージ格納SEQ
            ,NULL                                       -- 積載効率(容積)メッセージ格納SEQ
            ,NULL                                       -- パレット最大枚数メッセージ格納SEQ
-- 2008/08/20 H.Itou Add End
-- 2008/10/14 H.Itou Add Start 統合テスト指摘240
            ,NULL                                       -- 品目重複メッセージ格納SEQ
-- 2008/10/14 H.Itou Add End
-- 2009/08/03 T.Miyata Add Start SCS障害管理表（0000918）対応
            ,xshi.arrival_time_to        AS arr_t_to    -- 着荷時間To
-- 2009/08/03 T.Miyata Add End   SCS障害管理表（0000918）対応
      FROM (SELECT xshi1.header_id
                  ,MAX (xshi1.last_update_date)
                   OVER (PARTITION BY xshi1.order_source_ref) max_date
            FROM  xxwsh_shipping_headers_if xshi1
           ) max_id
           ,xxwsh_shipping_headers_if  xshi -- 出荷依頼インタフェースヘッダ（アドオン）
           ,xxwsh_shipping_lines_if    xsli -- 出荷依頼インタフェース明細（アドオン）
      WHERE xshi.header_id          = max_id.header_id    -- 最終更新日(最大)のヘッダID
      AND   xshi.last_update_date   = max_id.max_date     -- 最終更新日(最大)
      AND   xshi.data_type          = gv_10        -- [出荷依頼]を表すクイックコード「データタイプ」
      AND   xshi.header_id          = xsli.header_id     -- ヘッダID
      AND   xshi.input_sales_branch = gr_param.in_base   -- 入力Ｐ[入力拠点]
      AND   xshi.head_sales_branch  = gr_param.jur_base  -- 入力Ｐ[管轄拠点]
      ORDER BY xshi.order_source_ref -- 受注ソース参照
              ,xsli.line_id          -- 明細ID
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
    --   出荷依頼インタフェース情報を抽出
    -- ====================================================
    -- 行ロック用カーソルオープン
    OPEN cur_get_lock;
    -- 行ロック用カーソルクローズ
    CLOSE cur_get_lock;
--
    -- 入力Ｐ[管轄拠点]がNULLの場合
    IF (gr_param.jur_base IS NULL) THEN
      -- カーソルオープン
      OPEN cur_get_head_line;
      -- バルクフェッチ
      FETCH cur_get_head_line BULK COLLECT INTO ot_head_line;
      -- カーソルクローズ
      CLOSE cur_get_head_line;
    ELSE
      -- カーソルオープン
      OPEN cur_get_head_line_2;
      -- バルクフェッチ
      FETCH cur_get_head_line_2 BULK COLLECT INTO ot_head_line;
      -- カーソルクローズ
      CLOSE cur_get_head_line_2;
    END IF;
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_error_expt THEN
      -- カーソルオープン時、クローズへ
      IF (cur_get_head_line%ISOPEN) THEN
        CLOSE cur_get_head_line;
      ELSIF (cur_get_head_line_2%ISOPEN) THEN
        CLOSE cur_get_head_line_2;
      END IF;
--
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application   -- 'XXWSH'
                                                     ,gv_err_lock      -- ロックエラー
                                                    )
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルオープン時、クローズへ
      IF (cur_get_head_line%ISOPEN) THEN
        CLOSE cur_get_head_line;
      ELSIF (cur_get_head_line_2%ISOPEN) THEN
        CLOSE cur_get_head_line_2;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルオープン時、クローズへ
      IF (cur_get_head_line%ISOPEN) THEN
        CLOSE cur_get_head_line;
      ELSIF (cur_get_head_line_2%ISOPEN) THEN
        CLOSE cur_get_head_line_2;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルオープン時、クローズへ
      IF (cur_get_head_line%ISOPEN) THEN
        CLOSE cur_get_head_line;
      ELSIF (cur_get_head_line_2%ISOPEN) THEN
        CLOSE cur_get_head_line_2;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_get_head_line;
--
  /**********************************************************************************
   * Procedure Name   : pro_interface_chk
   * Description      : インターフェイス情報チェック (B-4)
   ***********************************************************************************/
  PROCEDURE pro_interface_chk
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_interface_chk'; -- プログラム名
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
    ln_result          NUMBER;
    ln_in_base_cnt     NUMBER;    -- 入力拠点用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    ---------------------------------------------------------------------------
    --  B-3にて取得した項目「出荷先」「受注ソース参照」「出荷予定日」        --
    -- 「着荷予定日」「出荷元保管場所」「管轄拠点」「データタイプ」「品目」  --
    -- 「数量」に値がセットしているかどうかのチェック                        --
    ---------------------------------------------------------------------------
    -- 「出荷先」チェック NULL時、エラー
    IF (gt_head_line(gn_i).p_s_code IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_1                       --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 「受注ソース参照」チェック NULL時、エラー
    IF (gt_head_line(gn_i).o_r_ref IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_2                       --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 「出荷予定日」チェック NULL時、エラー
    IF (gt_head_line(gn_i).ship_date IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_3                       --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 「着荷予定日」チェック NULL時、エラー
    IF (gt_head_line(gn_i).arr_date IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_4                       --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 「出荷元保管場所」チェック NULL時、エラー
    IF (gt_head_line(gn_i).lo_code IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_5                       --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 「管轄拠点」チェック NULL時、エラー
    IF (gt_head_line(gn_i).h_s_branch IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_6                       --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 「データタイプ」チェック NULL時、エラー
    IF (gt_head_line(gn_i).data_type IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_7                       --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 「品目」チェック NULL時、エラー
    IF (gt_head_line(gn_i).ord_i_code IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_8                       --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 「数量」チェック NULL時、エラー
    IF (gt_head_line(gn_i).ord_quant IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_9                       --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
-- 2009/08/03 T.Miyata Mod Start SCS障害管理表（0000918）対応
--    ---------------------------------------------------------------------------
--    -- 共通関数「依頼Noコンバート関数」にて、9桁の依頼Noを12桁依頼Noへ変換
--    ---------------------------------------------------------------------------
--    ln_result := xxwsh_common_pkg.convert_request_number
--                                  (
--                                    gv_1                          -- in  '1'拠点からのInBound用
--                                   ,gt_head_line(gn_i).o_r_ref    -- in  受注ソース参照 変更前依頼No
--                                   ,gv_new_order_no               -- out 変更後
--                                  );
--
    -- 依頼No12桁の設定
    gv_new_order_no := gt_head_line(gn_i).o_r_ref;
-- 2009/08/03 T.Miyata Mod End   SCS障害管理表（0000918）対応
--
    -- 出荷依頼作成件数(依頼Ｎｏ単位)用カウント
    IF ((gn_i       = 1)
    OR  (gr_o_r_ref <> gt_head_line(gn_i).o_r_ref))
    THEN
      gn_req_cnt := gn_req_cnt + 1;
    END IF;
--
    --==========================================================================
    -- 1. パーティサイト、パーティマスタ、顧客マスタ内「出荷先」のチェック
    --==========================================================================
    BEGIN
--
      SELECT xpsv.party_site_id      -- パーティサイトID
            ,xpv.party_id            -- 顧客ID
            ,xpv.party_number        -- 組織番号
            ,xpv.customer_class_code -- 顧客区分
            ,xpv.cust_enable_flag    -- 中止客申請フラグ
      INTO   gr_p_site_id
            ,gr_c_acc_num
            ,gr_party_num
            ,gr_cus_c_code
            ,gr_cus_en_flag
      FROM   xxcmn_parties_v     xpv  -- パーティ情報VIEW
            ,xxcmn_party_sites_v xpsv -- パーティサイト情報VIEW
      WHERE xpv.party_id           = xpsv.party_id  -- パーティID
      AND   xpsv.ship_to_no        = gt_head_line(gn_i).p_s_code
      ;
--
      -- 『中止客申請フラグ』が、「0」以外の場合、ワーニング
      IF (gr_cus_en_flag <> 0) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in 種別   '警告'
           ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
           ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => gv_msg_15                      --  in エラーメッセージ
           ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    EXCEPTION
      -- 「出荷先」がパーティサイトマスタに登録されていない場合、エラー
      WHEN OTHERS THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in 種別   'エラー'
           ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => gv_msg_10                      --  in エラーメッセージ
           ,iv_err_clm      => gt_head_line(gn_i).p_s_code    --  in エラー項目  出荷先
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了ST エラー登録
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
    END;
--
    --==========================================================================
    -- 2. OPM保管場所マスタ内「出荷保管場所」のチェック
    --==========================================================================
    BEGIN
--
      SELECT xilv.inventory_location_id  -- 保管棚ID
            ,xilv.allow_pickup_flag      -- 出荷引当対象フラグ
            ,xilv.frequent_mover         -- 代表運送会社
      INTO   gr_ship_id
            ,gr_a_p_flag
            ,gr_fre_mover
      FROM   xxcmn_item_locations_v   xilv    -- OPM保管場所情報VIEW
      WHERE  xilv.segment1 = gt_head_line(gn_i).lo_code   -- 出荷元保管場所
      ;
--
      -- 「出荷引当対象フラグ」が引当不可『0』、ワーニング
      IF (gr_a_p_flag = gv_0) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in 種別   '警告'
           ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
           ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => gv_msg_43                      --  in エラーメッセージ
           ,iv_err_clm      => gt_head_line(gn_i).lo_code     --  in エラー項目  出荷元保管場所
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    EXCEPTION
      -- 「出荷保管場所」がOPM保管場所マスタに登録されていない場合、エラー
      WHEN OTHERS THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in 種別   'エラー'
           ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => gv_msg_11                      --  in エラーメッセージ
           ,iv_err_clm      => gt_head_line(gn_i).lo_code     --  in エラー項目  出荷元保管場所
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了ST エラー登録
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
    END;
--
    --===========================================================================================
    -- 3. 上記2でデータ取得でき、かつ[代表運送会社]が設定されている場合、[代表運送会社]の取得
    --===========================================================================================
    IF (gr_fre_mover IS NOT NULL) THEN
      SELECT xcv.party_number    -- 組織番号
            ,xcv.party_id        -- パーティID
      INTO   gr_party_number
            ,gr_party_id
      FROM   xxcmn_carriers_v  xcv  -- 運送業者情報VIEW
      WHERE  xcv.party_number = gr_fre_mover   -- 代表運送会社
      ;
    ELSE
      -- 未設定時はNULLをセット
      gr_party_number := NULL;
      gr_party_id     := NULL;
    END IF;
--
    --==========================================================================
    -- 4. パーティマスタ・顧客マスタ「管轄拠点」
    --==========================================================================
    SELECT COUNT(xcav.account_number)
    INTO   ln_in_base_cnt
    FROM   xxcmn_cust_accounts_v  xcav  -- 顧客情報 V
    WHERE  xcav.account_number      = gt_head_line(gn_i).h_s_branch  -- 管轄拠点
    AND    xcav.customer_class_code = gv_1                           -- '拠点'を示す「コード区分」
    AND    ROWNUM                   = 1
    ;
--
    -- 「管轄拠点」が、パーティマスタ・顧客マスタに存在しない場合、エラー
    IF (ln_in_base_cnt = 0) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_12                      --  in エラーメッセージ
         ,iv_err_clm      => gt_head_line(gn_i).h_s_branch  --  in エラー項目 管轄拠点
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 同一出荷依頼ヘッダの場合は、1回のみの取得とする。
    IF ((gn_i    = 1)
    OR (gr_h_id <> gt_head_line(gn_i).h_id))
    THEN
      ----------------------------------------------------------------------------
      -- 「品目」から『商品区分』『重量容積区分』取得
      ----------------------------------------------------------------------------
      BEGIN
--
        SELECT xicv.prod_class_code           -- 商品区分
              ,ximv.weight_capacity_class     -- 重量容積区分
        INTO   gr_skbn
              ,gr_wei_kbn
        FROM   xxcmn_item_mst_v          ximv        -- OPM品目情報VIEW
              ,xxcmn_item_categories5_v  xicv        -- OPM品目カテゴリ割当情報VIEW5
        WHERE  ximv.item_id = xicv.item_id                   -- 品目ID
        AND    ximv.item_no = gt_head_line(gn_i).ord_i_code  -- 品目
        ;
--
      EXCEPTION
        -- 『商品区分』が取得できない場合、エラー
        WHEN OTHERS THEN
          pro_err_list_make
            (
              iv_kind         => gv_msg_err                     --  in 種別   'エラー'
             ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
             ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
             ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
             ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
             ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
             ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
             ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                                --  in 出庫日
             ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                                --  in 着日
             ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
             ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
             ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
             ,iv_err_msg      => gv_msg_13                      --  in エラーメッセージ
             ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in エラー項目   品目
             ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
             ,ov_retcode      => lv_retcode                     -- out リターン・コード
             ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
            );
          -- 共通エラーメッセージ 終了ST エラー登録
          gv_err_sts := gv_status_error;
--
          RAISE err_header_expt;
      END;
    END IF;
--
    -- 共通関数「最大配送区分算出関数」にて『最大配送区分』算出
    ln_result := xxwsh_common_pkg.get_max_ship_method
                           (
                             gv_4                         -- コード区分1       in 倉庫'4'
                            ,gt_head_line(gn_i).lo_code   -- 入出庫場所コード1 in 出荷元保管場所
                            ,gv_9                         -- コード区分2       in 配送先'9'
                            ,gt_head_line(gn_i).p_s_code  -- 入出庫場所コード2 in 出荷先
                            ,gr_skbn                      -- 商品区分          in 商品区分
                            ,gr_wei_kbn                   -- 重量容積区分      in 重量容積区分
                            ,NULL                         -- 自動配車対象区分  in NULL
                            ,gt_head_line(gn_i).ship_date -- 基準日            in 出荷予定日
                            ,gv_max_kbn                   -- 最大配送区分     out 最大配送区分
                            ,gn_drink_we                  -- ドリンク積載重量 out ドリンク積載重量
                            ,gn_leaf_we                   -- リーフ積載重量   out リーフ積載重量
                            ,gn_drink_ca                  -- ドリンク積載容積 out ドリンク積載容積
                            ,gn_leaf_ca                   -- リーフ積載容積   out リーフ積載容積
                            ,gn_prt_max                   -- パレット最大枚数 out パレット最大枚数
                           );
--
    -- 最大配送区分算出関数が正常ではない場合、エラー
    IF (ln_result = 1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_42                      --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST  エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -------------------------------------------------------------------------------
    -- 「依頼区分」から『受注タイプID』を取得
    -------------------------------------------------------------------------------
    BEGIN
--
--2008/10/10 MOD↓
--      SELECT xettv.transaction_type_id           -- 引取タイプID
--      INTO   gr_odr_type
--      FROM   xxcmn_lookup_values_v  xlvv            -- クイックコード情報View
--            ,xxwsh_oe_transaction_types_v  xettv    -- 受注タイプ情報View
--      WHERE  xlvv.lookup_type            = gv_shipping_class
--      AND    xlvv.attribute2             = gt_head_line(gn_i).order_class  -- 依頼区分
--      AND    xettv.order_category_code   = gv_order_c_code                 -- 受注カテゴリコード
--      AND    xettv.transaction_type_name = xlvv.attribute5                 -- 取引タイプ
--
      SELECT xettv.transaction_type_id           -- 引取タイプID
      INTO   gr_odr_type
      FROM   xxwsh_shipping_class_v xscv
            ,xxwsh_oe_transaction_types_v  xettv    -- 受注タイプ情報View
      WHERE  xscv.request_class          = gt_head_line(gn_i).order_class  -- 依頼区分
      AND    xettv.order_category_code   = gv_order_c_code                 -- 受注カテゴリコード
      AND    xscv.order_transaction_type_name = xettv.transaction_type_name
      AND    xscv.order_transaction_type_name = 
        CASE 
          WHEN xscv.request_class in ('2','4') THEN '出荷依頼'
          WHEN xscv.request_class in ('1','3') THEN xscv.order_transaction_type_name
        END
--2008/10/10 MOD↑
      ;
--
    EXCEPTION
      -- 『受注タイプID』が取得できない場合、エラー
      WHEN OTHERS THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in 種別   'エラー'
           ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => gv_msg_14                      --  in エラーメッセージ
           ,iv_err_clm      => gt_head_line(gn_i).order_class --  in エラー項目   '依頼区分'
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了ST  エラー登録
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
    END;
--
  EXCEPTION
    -- *** エラーメッセージ作成後 ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
     ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_interface_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_day_time_chk
   * Description      : 稼働日/リードタイムチェック (B-5)
   ***********************************************************************************/
  PROCEDURE pro_day_time_chk
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_day_time_chk'; -- プログラム名
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
    ln_result    NUMBER;
--
    -- *** ローカル変数 ***
    lv_errmsg_code  VARCHAR2(30);  -- エラー・メッセージ・コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -----------------------------------------------------------------------------------
    -- 1.共通関数「稼働日算出関数」にて『着荷予定日』が稼働日かであるかチェック      --
    -----------------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_oprtn_day
                                (
                                  gt_head_line(gn_i).arr_date  -- 日付           in 着荷予定日
                                 ,NULL                         -- 保管倉庫コード in NULL
                                 ,gt_head_line(gn_i).p_s_code  -- 配送先コード   in 出荷先
                                 ,0                            -- リードタイム   in 0
                                 ,gr_skbn                      -- 商品区分       in 商品区分
                                 ,gd_arr_work_day              -- 稼働日日付    out 稼働日(着荷)
                                );
--
-- 2008/11/20 H.Itou Add Start 統合テスト指摘658
    -- 共通関数エラー時、エラー
    IF (ln_result = gn_status_error) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_47                      --  in エラー項目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
-- 2008/11/20 H.Itou Add End
-- 2008/11/20 H.Itou Mod Start 統合テスト指摘658
    -- 稼働日ではない場合、ワーニング
--    IF (gd_arr_work_day IS NULL) THEN
    IF (gd_arr_work_day <> gt_head_line(gn_i).arr_date) THEN
-- 2008/11/20 H.Itou Mod End
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
-- 2008/11/20 H.Itou Mod Start 統合テスト指摘658
--         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_dec          => gv_msg_war                     --  in 確定   '警告'
-- 2008/11/20 H.Itou Mod End
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_16                      --  in エラーメッセージ
         ,iv_err_clm      => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in エラー項目  着荷予定日
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -----------------------------------------------------------------------------------
    -- 2.共通関数「稼働日算出関数」にて『出荷予定日』が稼働日かであるかチェック      --
    -----------------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_oprtn_day
                                (
                                  gt_head_line(gn_i).ship_date -- 日付           in 出荷予定日
                                 ,gt_head_line(gn_i).lo_code   -- 保管倉庫コード in 出荷元保管場所
                                 ,NULL                         -- 配送先コード   in NULL
                                 ,0                            -- リードタイム   in 0
                                 ,gr_skbn                      -- 商品区分       in 商品区分
                                 ,gd_shi_work_day              -- 稼働日日付    out 稼働日(出荷)
                                );
--
-- 2008/11/20 H.Itou Add Start 統合テスト指摘658
    -- 共通関数エラー時、エラー
    IF (ln_result = gn_status_error) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_47                      --  in エラー項目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
-- 2008/11/20 H.Itou Add End
-- 2008/11/20 H.Itou Mod Start 統合テスト指摘658
    -- 稼働日ではない場合、ワーニング
--    IF (gd_shi_work_day IS NULL) THEN
    IF (gd_shi_work_day <> gt_head_line(gn_i).ship_date) THEN
-- 2008/11/20 H.Itou Mod End
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_17                      --  in エラーメッセージ
         ,iv_err_clm      => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in エラー項目  着荷予定日
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -----------------------------------------------------------------------------------------------
    -- 3.共通関数「リードタイム算出」にて『生産物流リードタイム』『配送リードタイム』取得        --
    -----------------------------------------------------------------------------------------------
    xxwsh_common910_pkg.calc_lead_time
                                (
                                  gv_4                         -- コード区分From   in 倉庫'4'
                                 ,gt_head_line(gn_i).lo_code   -- 入出庫区分From   in 出荷元保管場所
                                 ,gv_9                         -- コード区分To     in 配送先'9'
                                 ,gt_head_line(gn_i).p_s_code  -- 入出庫区分To     in 出荷先
                                 ,gr_skbn                      -- 商品区分         in 商品区分
                                 ,gr_odr_type                  -- 出庫形態ID       in 受注タイプID
                                 ,gt_head_line(gn_i).ship_date -- 基準日           in 出荷予定日
                                 ,lv_retcode                   -- リターン・コード
                                 ,lv_errmsg_code               -- エラー・メッセージ・コード
                                 ,lv_errmsg                    -- ユーザー・エラー・メッセージ
                                 ,gv_leadtime                  -- 生産物流LT/引取変更LT
                                 ,gv_delivery_lt               -- 配送リードタイム
                                );
--
    -- 共通関数エラー時、エラー
    IF (lv_retcode = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_18                      --  in エラー項目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    ------------------------------------------------------------------------------------
    -- 4.共通関数「稼働日算出関数」にて配送リードタイムの日数分、過去の稼働日算出     --
    ------------------------------------------------------------------------------------
-- 2008/11/20 H.Itou Mod Start 統合テスト指摘658
--    ln_result := xxwsh_common_pkg.get_oprtn_day
--                          (
--                            gt_head_line(gn_i).arr_date  -- 日付           in 着荷予定日
--                           ,NULL                         -- 保管倉庫コード in NULL
--                           ,gt_head_line(gn_i).p_s_code  -- 配送先コード   in 出荷先
--                           ,gv_delivery_lt               -- リードタイム   in 配送リードタイム
--                           ,gr_skbn                      -- 商品区分       in 商品区分
--                           ,gd_de_past_day               -- 稼働日日付    out 稼働日日付(過去・配送)
--                          );
    -- 着荷予定日 － 配送LT（稼動日を考慮しない。）
    gd_de_past_day := gt_head_line(gn_i).arr_date - gv_delivery_lt;
-- 2008/11/20 H.Itou Mod End
--
    ----------------------------------------------------------------------------
    -- 5.稼働日日付が出荷予定日より過去かどうかの判定                         --
    ----------------------------------------------------------------------------
    IF (gt_head_line(gn_i).ship_date > gd_de_past_day) THEN
      -- 過去の場合、配送リードタイムを満たしていない場合、ワーニング
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_19                      --  in エラーメッセージ
         ,iv_err_clm      => gv_delivery_lt                 --  in エラー項目  配送リードタイム
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    --------------------------------------------------------------------------------------
    -- 6.共通関数「稼働日算出関数」にて生産物流リードタイムの日数分『過去稼働日』算出   --
    --------------------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_oprtn_day
                          (
                            gt_head_line(gn_i).ship_date  -- 日付           in 出荷予定日
                           ,NULL                          -- 保管倉庫コード in NULL
                           ,gt_head_line(gn_i).p_s_code   -- 配送先コード   in 出荷先
                           ,gv_leadtime                   -- リードタイム   in 生産物流LT/引取変更LT
                           ,gr_skbn                       -- 商品区分       in 商品区分
                           ,gd_past_day                   -- 稼働日日付    out 稼働日日付(過・生産)
                           );
--
-- 2008/11/20 H.Itou Add Start 統合テスト指摘658
    -- 共通関数エラー時、エラー
    IF (ln_result = gn_status_error) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_47                      --  in エラー項目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
-- 2008/11/20 H.Itou Add End
    ----------------------------------------------------------------------------
    -- 7.稼働日日付(引取変更LTの過去日)がシステム日付より過去かどうかの判定   --
    ----------------------------------------------------------------------------
-- 2008/11/20 H.Itou Add Start 統合テスト指摘141
    -- 当日出荷の場合を考慮して+1
    gd_past_day := gd_past_day + 1;
-- 2008/11/20 H.Itou Add End
--
    IF (gd_sysdate > gd_past_day) THEN
      -- 過去の場合、生産物流リードタイムを満たしていない。ワーニング
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_20                      --  in エラーメッセージ
         ,iv_err_clm      => gv_leadtime                    --  in エラー項目  生産物流リードタイム
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 8.共通関数「OPM在庫会計期間 CLOSE年月取得関数」にて                    --
    --   『出荷予定日』の会計期間がOpenされているかチェック                   --
    ----------------------------------------------------------------------------
    -- クローズの最大年月取得
    gv_opm_c_p := xxcmn_common_pkg.get_opminv_close_period;
--
    -- 出荷予定日がOPM在庫会計期間でクローズの場合
-- 2008/10/14 H.Itou Mod Start クローズ年月と同じ年月の場合もエラー
--    IF (gv_opm_c_p > TO_CHAR(gt_head_line(gn_i).ship_date,'YYYYMM')) THEN
    IF (gv_opm_c_p >= TO_CHAR(gt_head_line(gn_i).ship_date,'YYYYMM')) THEN
-- 2008/10/14 H.Itou Mod End
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_21                      --  in エラーメッセージ
-- 2008/08/20 H.Itou Mod Start 結合テスト指摘#87
--         ,iv_err_clm      => gt_head_line(gn_i).ship_date   --  in エラー項目  出荷予定日
         ,iv_err_clm      => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in エラー項目  出荷予定日
-- 2008/08/20 H.Itou Mod End
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
-- 2008/08/26 H.Itou Add Start T_S_618
    ----------------------------------------------------------------------------
    -- 9.出庫日が締め済みかどうかの判定                                       --
    ----------------------------------------------------------------------------
    -- 締めステータスチェック関数
    lv_retcode :=xxwsh_common_pkg.check_tightening_status(
                   in_order_type_id         =>  gr_odr_type                   -- 1.受注タイプID
                  ,iv_deliver_from          =>  gt_head_line(gn_i).lo_code    -- 2.出荷元保管場所
                  ,iv_sales_branch          =>  gt_head_line(gn_i).h_s_branch -- 3.拠点
                  ,iv_sales_branch_category =>  NULL                          -- 4.拠点カテゴリ
                  ,in_lead_time_day         =>  gv_leadtime                   -- 5.生産物流LT
                  ,id_ship_date             =>  gt_head_line(gn_i).ship_date  -- 6.出庫日
                  ,iv_prod_class            =>  gr_skbn                       -- 7.商品区分
                 );
--
    -- 締めステータスが'-1'の場合は関数エラー
    IF (lv_retcode = gv_inside_err) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_45                      --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目  '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
--
    END IF;
--
    -- 締めステータスが'2'または'4'の場合は、締め済みエラー
    IF (lv_retcode IN (gv_first_close_fin, gv_re_close_fin)) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_44                      --  in エラーメッセージ
         ,iv_err_clm      => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in エラー項目  出荷予定日
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
--
    END IF;
-- 2008/08/26 H.Itou Add End
--
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_day_time_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_item_chk
   * Description      : 明細情報マスタ存在チェック (B-6)
   ***********************************************************************************/
  PROCEDURE pro_item_chk
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_item_chk'; -- プログラム名
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
    ln_amount    NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 数量をセット
    ln_amount := gt_head_line(gn_i).ord_quant;  -- 数量
--
    SELECT ximv.inventory_item_id        -- 品目ID
          ,ximv.item_um                  -- 単位
          ,ximv.conv_unit                -- 入出庫換算単位
          ,ximv.num_of_cases             -- 入数
          ,xicv.prod_class_code          -- 商品区分
          ,xicv.item_class_code          -- 品目区分
--          ,CASE
--             WHEN ximv.conv_unit IS NULL     THEN ln_amount
--             WHEN ximv.conv_unit IS NOT NULL THEN (ln_amount * ximv.num_of_cases)
--           END    AS gn_item_amount      -- 数量
          ,ln_amount                     -- 数量
          ,ximv.max_palette_steps        -- パレット当り最大段数
          ,ximv.delivery_qty             -- 配数
          ,ximv.weight_capacity_class    -- 重量容積区分
          ,ximv.ship_class               -- 出荷区分
          ,ximv.num_of_deliver           -- 出荷入数
          ,ximv.sales_div                -- 売上対象区分
          ,ximv.obsolete_class           -- 廃止区分
          ,ximv.rate_class               -- 率区分
-- 2008/08/11 H.Itou ADD START 結合指摘#74
          ,ximv.parent_item_id parent_item_id -- 親品目ID
          ,ximv.item_id        item_id        -- OPM品目ID
-- 2008/08/11 H.Itou ADD END
    INTO   gr_i_item_id
          ,gr_item_um
          ,gr_conv_unit
          ,gr_case_am
          ,gr_item_skbn
          ,gr_item_kbn
          ,gn_item_amount
          ,gr_max_p_step
          ,gr_del_qty
          ,gr_i_wei_kbn
          ,gr_out_kbn
          ,gr_ship_am
          ,gr_sale_kbn
          ,gr_end_kbn
          ,gr_rit_kbn
-- 2008/08/11 H.Itou ADD START 結合指摘#74
          ,gr_parent_item_id
          ,gr_item_id
-- 2008/08/11 H.Itou ADD END
    FROM  xxcmn_item_mst2_v         ximv     -- OPM品目情報VIEW
         ,xxcmn_item_categories5_v  xicv     -- OPM品目カテゴリ割当情報VIEW5
    WHERE ximv.item_no            = gt_head_line(gn_i).ord_i_code -- 品目
    AND   ximv.item_id            = xicv.item_id                  -- 品目ID
    AND   ximv.start_date_active <= gd_sysdate
    AND   ximv.end_date_active   >= gd_sysdate
    ;
--
    -- 「出荷区分」が『否』の場合。ワーニング
    IF (gr_out_kbn = gv_0) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_23                      --  in エラーメッセージ
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in エラー項目   品目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 「売上対象区分」が「1」以外の場合。ワーニング
-- 2008/08/11 H.Itou ADD START 結合指摘#74
      -- 売上対象区分チェックは親品目の場合のみ。
--    IF (gr_sale_kbn <> gv_1) THEN
      IF ((gr_sale_kbn <> gv_1) 
      AND (gr_parent_item_id = gr_item_id)) THEN
-- 2008/08/11 H.Itou ADD END
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_24                      --  in エラーメッセージ
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in エラー項目  品目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 「廃止区分」が「D」の場合。ワーニング
    IF (gr_end_kbn = gv_delete) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_25                      --  in エラーメッセージ
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in エラー項目  品目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 「率区分」が「0」以外の場合。ワーニング
    IF (gr_rit_kbn <> gv_0) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_26                      --  in エラーメッセージ
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in エラー項目  品目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    --------------------------------------------------------------------
    -- 商品区分「ドリンク」かつ品目区分「製品」の場合で、
    --「パレット当り最大段数」が『0』またはNULL、エラー
    --------------------------------------------------------------------
    IF ((gr_item_skbn   = gv_2)
    AND (gr_item_kbn    = gv_5)
    AND ((gr_max_p_step IS NULL)
      OR (gr_max_p_step  = gv_0)))
    THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_27                      --  in エラーメッセージ
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in エラー項目   品目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    --------------------------------------------------------------------
    -- 商品区分「ドリンク」かつ品目区分「製品」の場合で、
    --「配数」が『0』またはNULL、エラー
    --------------------------------------------------------------------
    IF ((gr_item_skbn  = gv_2)
    AND (gr_item_kbn   = gv_5)
    AND ((gr_del_qty   IS NULL)
      OR (gr_del_qty    = gv_0)))
    THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_28                      --  in エラーメッセージ
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in エラー項目   品目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
  EXCEPTION
    -- 「品目」がOPM品目マスタに登録されていない場合、エラー
    WHEN NO_DATA_FOUND THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_22                      --  in エラーメッセージ
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in エラー項目   品目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
      gv_err_flg := gv_2;
--
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_item_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_xsr_chk
   * Description      : 物流構成存在チェック (B-7)
   ***********************************************************************************/
  PROCEDURE pro_xsr_chk
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ        --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_xsr_chk'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_cnt      NUMBER;
    lv_yn_flg   VARCHAR2(1);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 存在チェックフラグ、カウント変数初期化
    ln_cnt    := 0;
    lv_yn_flg := gv_no;
--
-- 2009/01/08 H.Itou Mod Start 本番障害#894
--    ----------------------------------------------------------------------------
--    -- 1.品目/出荷先/出荷元保管場所にて物流構成アドオンへの存在チェック       --
--    ----------------------------------------------------------------------------
--    SELECT COUNT (xsr.item_code)
--    INTO   ln_cnt
--    FROM   xxcmn_sourcing_rules  xsr   -- 物流構成アドオンマスタ T
--    WHERE  xsr.item_code          = gt_head_line(gn_i).ord_i_code
--    AND    xsr.ship_to_code       = gt_head_line(gn_i).p_s_code
--    AND    xsr.delivery_whse_code = gt_head_line(gn_i).lo_code
--    AND    xsr.start_date_active <= gt_head_line(gn_i).ship_date
--    AND    xsr.end_date_active   >= gt_head_line(gn_i).ship_date
--    AND    ROWNUM                 = 1
--    ;
----
--    IF (ln_cnt = 1) THEN
--      lv_yn_flg := gv_yes;
--    END IF;
----
--    ----------------------------------------------------------------------------
--    -- 2.品目/管轄拠点/出荷元保管場所にて物流構成アドオンへの存在チェック     --
--    ----------------------------------------------------------------------------
--    -- 上記1にて0件の場合
--    IF (lv_yn_flg = gv_no) THEN
--      SELECT COUNT (xsr.item_code)
--      INTO   ln_cnt
--      FROM   xxcmn_sourcing_rules  xsr  -- 物流構成アドオンマスタ T
--      WHERE  xsr.item_code          = gt_head_line(gn_i).ord_i_code
--      AND    xsr.base_code          = gt_head_line(gn_i).h_s_branch
--      AND    xsr.delivery_whse_code = gt_head_line(gn_i).lo_code
--      AND    xsr.start_date_active <= gt_head_line(gn_i).ship_date
--      AND    xsr.end_date_active   >= gt_head_line(gn_i).ship_date
--      AND    ROWNUM                 = 1
--      ;
----
--      IF (ln_cnt = 1) THEN
--        lv_yn_flg := gv_yes;
--      END IF;
--    END IF;
----
--    ----------------------------------------------------------------------------
--    -- 3.全品目/出荷先/出荷元保管場所にて物流構成アドオンへの存在チェック     --
--    ----------------------------------------------------------------------------
--    -- 上記2にて0件の場合
--    IF (lv_yn_flg = gv_no) THEN
--      SELECT COUNT (xsr.item_code)
--      INTO   ln_cnt
--      FROM   xxcmn_sourcing_rules  xsr  -- 物流構成アドオンマスタ T
--      WHERE  xsr.item_code          = gv_all_item
--      AND    xsr.ship_to_code       = gt_head_line(gn_i).p_s_code
--      AND    xsr.delivery_whse_code = gt_head_line(gn_i).lo_code
--      AND    xsr.start_date_active <= gt_head_line(gn_i).ship_date
--      AND    xsr.end_date_active   >= gt_head_line(gn_i).ship_date
--      AND    ROWNUM                 = 1
--      ;
----
--      IF (ln_cnt = 1) THEN
--        lv_yn_flg := gv_yes;
--      END IF;
--    END IF;
----
--    ----------------------------------------------------------------------------
--    -- 4.全品目/管轄拠点/出荷元保管場所にて物流構成アドオンへの存在チェック   --
--    ----------------------------------------------------------------------------
--    -- 上記3にて0件の場合
--    IF (lv_yn_flg = gv_no) THEN
--      SELECT COUNT (xsr.item_code)
--      INTO   ln_cnt
--      FROM   xxcmn_sourcing_rules  xsr  -- 物流構成アドオンマスタ T
--      WHERE  xsr.item_code          = gv_all_item
--      AND    xsr.base_code          = gt_head_line(gn_i).h_s_branch
--      AND    xsr.delivery_whse_code = gt_head_line(gn_i).lo_code
--      AND    xsr.start_date_active <= gt_head_line(gn_i).ship_date
--      AND    xsr.end_date_active   >= gt_head_line(gn_i).ship_date
--      AND    ROWNUM                 = 1
--      ;
----
--      IF (ln_cnt = 1) THEN
--        lv_yn_flg := gv_yes;
--      END IF;
--    END IF;
--
    -- 物流構成存在チェック関数
    lv_retcode := xxwsh_common_pkg.chk_sourcing_rules(
                    it_item_code          => gt_head_line(gn_i).ord_i_code -- 1.品目コード
                   ,it_base_code          => gt_head_line(gn_i).h_s_branch -- 2.管轄拠点
                   ,it_ship_to_code       => gt_head_line(gn_i).p_s_code   -- 3.配送先
                   ,it_delivery_whse_code => gt_head_line(gn_i).lo_code    -- 4.出庫倉庫
                   ,id_standard_date      => gt_head_line(gn_i).ship_date  -- 5.基準日(適用日基準日)
                  );
--
-- 2009/01/08 H.Itou Mod End
--
-- 2009/01/08 H.Itou Mod Start 本番障害#894
--    -- 上記4にて0件の場合、ワーニング
--    IF (lv_yn_flg = gv_no) THEN
     -- 戻り値が正常でない場合、ワーニング
     IF (lv_retcode <> gv_status_normal) THEN
-- 2009/01/08 H.Itou Mod End
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_29                      --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_xsr_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_total_we_ca
   * Description      : 合計重量/合計容積算出 (B-8)
   ***********************************************************************************/
  PROCEDURE pro_total_we_ca
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_total_we_ca'; -- プログラム名
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
    lv_kougti      CONSTANT VARCHAR2(6)  := '%小口%';
--
    -- *** ローカル変数 ***
    --ln_cnt         NUMBER;
    lv_errmsg_code VARCHAR2(30);  -- エラー・メッセージ・コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -----------------------------------------------------------------------------------
    -- 共通関数「積載効率チェック(合計値算出)」にて『合計重量/合計容積』を算出       --
    -----------------------------------------------------------------------------------
    xxwsh_common910_pkg.calc_total_value
                            (
                              gt_head_line(gn_i).ord_i_code -- 品目コード   in 品目
                             ,gn_item_amount                -- 数量         in 数量
                             ,lv_retcode                    -- リターン・コード
                             ,lv_errmsg_code                -- エラー・メッセージ・コード
                             ,lv_errmsg                     -- エラー・メッセージ
                             ,gn_ttl_we                     -- 合計重量         out 合計重量
                             ,gn_ttl_ca                     -- 合計容積         out 合計容積
                             ,gn_ttl_prt_we                 -- 合計パレット重量 out 合計パレット重量
-- 2008/10/14 H.Itou Add Start 統合テスト指摘240
                             ,gt_head_line(gn_i).ship_date  -- 基準日       in 出荷予定日
-- 2008/10/14 H.Itou Add End
                            );
--
    -------------------------------------------------------------------------------
    -- ｢最大配送区分｣に紐づく｢小口区分｣が対象かどうかチェック                    --
    -------------------------------------------------------------------------------
--
    SELECT COUNT (xlvv.meaning)
    INTO   gv_small_qty_flg
    FROM   xxcmn_lookup_values_v  xlvv  -- クイックコード情報 V
    WHERE  xlvv.lookup_type = gv_ship_method
    AND    xlvv.lookup_code = gv_max_kbn
    AND    xlvv.attribute6  = gv_1;          -- 対象
-- 2011/03/28 N.Horigome Del Start
--    AND    xlvv.meaning  LIKE lv_kougti;
-- 2011/03/28 N.Horigome Del End
--
    -- ｢明細重量｣｢明細容積｣算出
    --IF (gv_small_qty_flg = 1) THEN
      -- 『対象』場合
      gn_detail_we := NVL(gn_ttl_we,0);                         -- 明細重量
      gn_detail_ca := NVL(gn_ttl_ca,0);                         -- 明細容積
    --ELSE
      -- 上記以外
      --gn_detail_we := NVL(gn_ttl_we,0) + NVL(gn_ttl_prt_we,0);  -- 明細重量
      --gn_detail_ca := NVL(gn_ttl_ca,0) + NVL(gn_ttl_prt_we,0);  -- 明細容積
    --END IF;
--
    -- 共通関数にて、リターンコードがエラー時。エラー
    IF (lv_retcode = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
         ,iv_err_clm      => lv_errmsg                      --  in エラー項目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_total_we_ca;
--
  /**********************************************************************************
   * Procedure Name   : pro_ship_y_n_chk
   * Description      : 出荷可否チェック (B-9)
   ***********************************************************************************/
  PROCEDURE pro_ship_y_n_chk
    (
      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_ship_y_n_chk'; -- プログラム名
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
    ln_cnt      NUMBER;
    ln_result   NUMBER;
--
    -- *** ローカル変数 ***
    lv_errmsg_code VARCHAR2(30);  -- エラー・メッセージ・コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    --------------------------------
    -- 1.計画商品フラグチェック   --
    --------------------------------
    -- 存在チェックフラグ、カウント変数初期化
    ln_cnt    := 0;
--
    -- 物流構成アドオンから「計画商品フラグ」がONであるがどうかのチェック
    SELECT COUNT (xsr.item_code)
    INTO   ln_cnt
    FROM   xxcmn_sourcing_rules  xsr   -- 物流構成アドオンマスタ T
    WHERE  xsr.item_code          = gt_head_line(gn_i).ord_i_code
    AND    xsr.base_code          = gt_head_line(gn_i).h_s_branch
    AND    xsr.delivery_whse_code = gt_head_line(gn_i).lo_code
    AND    xsr.start_date_active <= gt_head_line(gn_i).ship_date
    AND    xsr.end_date_active   >= gt_head_line(gn_i).ship_date
    AND    xsr.plan_item_flag     = gv_1
    AND    ROWNUM                 = 1
    ;
--
    --------------------------------
    -- 2.出荷可否チェック         --
    --------------------------------
    -- 出荷数制限(商品部) チェック
    xxwsh_common910_pkg.check_shipping_judgment
                          (
                            gv_2                           -- チェック方法区分 in 『2』:商品部
                           ,gt_head_line(gn_i).h_s_branch  -- 拠点             in 管轄拠点
                           ,gr_i_item_id                   -- 品目ID           in 品目ID
                           ,gn_item_amount                 -- 数量             in 数量
                           ,gt_head_line(gn_i).arr_date    -- 対象日           in 着荷予定日
                           ,gr_ship_id                     -- 出荷元ID         in 出荷元ID
                           ,gv_new_order_no                -- 依頼No           6/19追加
                           ,lv_retcode                     -- リターン・コード
                           ,lv_errmsg_code                 -- エラー・メッセージ・コード
                           ,lv_errmsg                      -- ユーザー・エラー・メッセージ
                           ,ln_result                      -- 処理結果
                          );
--
    -- 出荷数制限(商品部) 出荷可否チェック 異常終了の場合、エラー
    IF (lv_retcode = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
         ,iv_err_clm      => lv_errmsg_code                 --  in エラー項目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 出荷数制限(商品部)チェックにて「処理結果」='1'(数量オーバーエラー)時、ワーニング
    IF (ln_result = 1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_31                      --  in エラーメッセージ
         ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in エラー項目  数量
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 出荷数制限(物流部) チェック
    xxwsh_common910_pkg.check_shipping_judgment
                          (
                            gv_3                           -- チェック方法区分 in 『3』:物流部
                           ,gt_head_line(gn_i).h_s_branch  -- 拠点             in 管轄拠点
                           ,gr_i_item_id                   -- 品目ID           in 品目ID
                           ,gn_item_amount                 -- 数量             in 数量
                           ,gt_head_line(gn_i).ship_date   -- 対象日           in 出荷予定日
                           ,gr_ship_id                     -- 出荷元ID         in 出荷元ID
                           ,gv_new_order_no                -- 依頼No           6/19追加
                           ,lv_retcode                     -- リターン・コード
                           ,lv_errmsg_code                 -- エラー・メッセージ・コード
                           ,lv_errmsg                      -- ユーザー・エラー・メッセージ
                           ,ln_result                      -- 処理結果
                          );
--
    -- 出荷数制限(物流部) 出荷可否チェック 異常終了の場合、エラー
    IF (lv_retcode = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
         ,iv_err_clm      => lv_errmsg_code                 --  in エラー項目
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- 出荷数制限(物流部)チェックにて「処理結果」='1'(数量オーバーエラー)時、ワーニング
    IF (ln_result = 1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_32                      --  in エラーメッセージ
         ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in エラー項目  数量
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 出荷数制限(物流部)チェックにて「処理結果」='2'(出荷停止日エラー)時、ワーニング
    IF (ln_result = 2) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_33                      --  in エラーメッセージ
-- 2008/08/20 H.Itou Mod Start 結合テスト指摘#87
--         ,iv_err_clm      => gt_head_line(gn_i).ship_date   --  in エラー項目  出荷予定日
         ,iv_err_clm      => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in エラー項目  出荷予定日
-- 2008/08/20 H.Itou Mod End
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 商品区分が「リーフ」の場合、引取計画チェック実施
    IF (gr_skbn = gv_1) THEN
      xxwsh_common910_pkg.check_shipping_judgment
                            (
                              gv_1                           -- チェック方法区分 in 『1』
                             ,gt_head_line(gn_i).h_s_branch  -- 拠点             in 管轄拠点
                             ,gr_i_item_id                   -- 品目ID           in 品目ID
                             ,gn_item_amount                 -- 数量             in 数量
                             ,gt_head_line(gn_i).arr_date    -- 対象日           in 着荷予定日
                             ,gr_ship_id                     -- 出荷元ID         in 出荷元ID
                             ,gv_new_order_no                -- 依頼No           6/19追加
                             ,lv_retcode                     -- リターン・コード
                             ,lv_errmsg_code                 -- エラー・メッセージ・コード
                             ,lv_errmsg                      -- ユーザー・エラー・メッセージ
                             ,ln_result                      -- 処理結果
                            );
--
      -- 引取計画チェック 異常終了の場合、エラー
      IF (lv_retcode = gv_1) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in 種別   'エラー'
           ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
           ,iv_err_clm      => lv_errmsg_code                 --  in エラー項目
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了ST エラー登録
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
      END IF;
      -- 「処理結果」='1'(数量オーバーエラー)時、ワーニング
      IF (ln_result = 1) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in 種別   '警告'
           ,iv_dec          => gv_msg_war                     --  in 確定   '警告'
           ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => gv_msg_30                      --  in エラーメッセージ
           ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in エラー項目  数量
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
    END IF;
--
    -- 計画商品フラグがONの場合、計画商品チェック
    IF (ln_cnt = 1) THEN
      xxwsh_common910_pkg.check_shipping_judgment
                            (
                              gv_4                           -- チェック方法区分 in 『4』:計画商品
                             ,gt_head_line(gn_i).h_s_branch  -- 拠点             in 管轄拠点
                             ,gr_i_item_id                   -- 品目ID           in 品目ID
                             ,gn_item_amount                 -- 数量             in 数量
                             ,gt_head_line(gn_i).ship_date   -- 対象日           in 出荷予定日
                             ,gr_ship_id                     -- 出荷元ID         in 出荷元ID
                             ,gv_new_order_no                -- 依頼No           6/19追加
                             ,lv_retcode                     -- リターン・コード
                             ,lv_errmsg_code                 -- エラー・メッセージ・コード
                             ,lv_errmsg                      -- ユーザー・エラー・メッセージ
                             ,ln_result                      -- 処理結果
                            );
--
      -- 計画商品引取計画チェック 異常終了の場合、エラー
      IF (lv_retcode = gv_1) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in 種別   'エラー'
           ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
           ,iv_err_clm      => lv_errmsg_code                 --  in エラー項目
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了ST エラー登録
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
      END IF;
      -- 「処理結果」='1'(数量オーバーエラー)時、ワーニング
      IF (ln_result = 1) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in 種別   '警告'
           ,iv_dec          => gv_msg_war                     --  in 確定   '警告'
           ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => gv_msg_34                      --  in エラーメッセージ
           ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in エラー項目  数量
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_ship_y_n_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_lines_create
   * Description      : 受注明細アドオンレコード生成 (B-10)
   ***********************************************************************************/
  PROCEDURE pro_lines_create
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_lines_create'; -- プログラム名
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
    ln_mod_chk      NUMBER DEFAULT 0;      -- 整数倍チェック
    lv_dsc          VARCHAR2(6);           -- エラーメッセージ内容項目
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 明細番号の採番、ヘッダ項目用合計数初期化
    IF ((gr_h_id    = gt_head_line(gn_i).h_id)
    AND (gr_o_r_ref = gt_head_line(gn_i).o_r_ref))
    THEN
      -- 明細番号カウント＋１
      gn_line_number := gn_line_number + 1;
    -- 初回レコード時か、[ヘッダID][受注ソース参照]が前データと異なる場合
    ELSE
      -- 明細番号は[1]セット
      gn_line_number := 1;
      -- ヘッダ項目用合計数初期化
      gn_ttl_ship_am  := 0;  -- 出荷単位換算数
      gn_h_ttl_weight := 0;  -- 積載重量合計
      gn_h_ttl_capa   := 0;  -- 積載容積合計
      gn_h_ttl_pallet := 0;  -- 合計パレット重量
      gn_pallet_t_c_am  := 0;  -- パレット合計枚数
    END IF;
--
    ------------------------------------------------------
    -- 1.「パレット数」「段数」「ケース数」算出         --
    ------------------------------------------------------
    -- 各値の初期化
    gn_p_max_case_am  := 0;  -- パレット当り最大ケース数
    gn_case_total     := 0;  -- ケース総合計
    gn_pallet_am      := 0;  -- パレット数
    gn_step_am        := 0;  -- 段数
    gn_case_am        := 0;  -- ケース数
    gn_pallet_co_am   := 0;  -- パレット枚数
--
-- 2008/08/05 D.Nihei ADD START
    -- 商品区分「ドリンク」かつ品目区分「製品」の場合
    IF ( ( gr_item_skbn = gv_2 ) 
     AND ( gr_item_kbn  = gv_5 ) ) 
    THEN
-- 2008/08/05 D.Nihei ADD END
      -- (1).各値の最適化
      -- 「パレット当り最大ケース数」= 配数 * パレット当り最大段数
      gn_p_max_case_am := gr_del_qty * gr_max_p_step;
--
      -- 「ケース入数」0除算判定
      IF (gr_case_am = 0) THEN
        gn_case_total := 0;                -- ケース総合計
      ELSE
        -- 「ケース総合計」= B-3の数量 / ケース入数 [小数点以下切捨て]
        gn_case_total := TRUNC(gt_head_line(gn_i).ord_quant / gr_case_am);
      END IF;
--
      -- 「パレット当り最大ケース数」0除算判定
      IF (gn_p_max_case_am = 0) THEN
        gn_pallet_am  := 0;                -- パレット数
      ELSE
        -- 「パレット数」= ケース総合計 / パレット当り最大ケース数 [小数点以下切捨て]
        gn_pallet_am  := TRUNC(gn_case_total / gn_p_max_case_am);
      END IF;
--
      -- 「配数」0除算判定
      IF (TO_NUMBER(gr_del_qty) = 0) THEN
        gn_step_am    := 0;                -- 段数
        gn_case_am    := 0;                -- ケース数
      ELSE
        -- 「段数」= ((ケース総合計 / パレット当り最大ケース数)の剰余) / 配数 [小数点以下切捨て]
        gn_step_am := TRUNC(MOD(gn_case_total,gn_p_max_case_am) / TO_NUMBER(gr_del_qty));
        -- 「ケース数」= (((ケース総合計 / パレット当り最大ケース数)の剰余) / 配数)の剰余
        gn_case_am := MOD(MOD(gn_case_total,gn_p_max_case_am),TO_NUMBER(gr_del_qty));
      END IF;
--
      -- (2).パレット枚数の算出
      -- 「段数」又は「ケース数」が0以上の場合
      IF ((gn_step_am > 0)
      OR  (gn_case_am > 0))
      THEN
        gn_pallet_co_am := gn_pallet_am + 1;
      ELSE
        gn_pallet_co_am := gn_pallet_am;
      END IF;
--
      -- (3).パレット合計枚数の算出
      gn_pallet_t_c_am  := gn_pallet_t_c_am + gn_pallet_co_am;
-- 2008/08/05 D.Nihei ADD START
    END IF;
-- 2008/08/05 D.Nihei ADD END
--
-- 2008/08/05 D.Nihei MOD START
--    -- ｢数量｣が｢配数｣の整数倍ではない場合。ワーニング
--    ln_mod_chk := MOD(gn_item_amount,TO_NUMBER(gr_del_qty));
--    IF (ln_mod_chk <> 0) THEN
    -- ｢ケース数｣が0以外の場合。ワーニング
    IF (gn_case_am <> 0) THEN
-- 2008/08/05 D.Nihei MOD END
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in 種別   '警告'
-- 2008/08/20 H.Itou Mod Start 結合テスト指摘#89
--         ,iv_dec          => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_war                     --  in 種別   '警告'
-- 2008/08/20 H.Itou Mod End
         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_35                      --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目  '-'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    ------------------------------------------------------
    -- 2.受注明細アドオン作成用レコード変数へ格納       --
    ------------------------------------------------------
    ord_l_all.order_line_id              := gn_lines_seq;                  -- 受注明細アドオンID
    ord_l_all.order_header_id            := gn_headers_seq;                -- 受注ヘッダアドオンID
    ord_l_all.order_line_number          := gn_line_number;                -- 明細番号
    ord_l_all.request_no                 := gv_new_order_no;               -- 依頼No
    ord_l_all.shipping_inventory_item_id := gr_i_item_id;                  -- 出荷品目ID
    ord_l_all.shipping_item_code         := gt_head_line(gn_i).ord_i_code; -- 出荷品目
    ord_l_all.quantity                   := gn_item_amount;                -- 数量
    ord_l_all.uom_code                   := gr_item_um;                    -- 単位
    ord_l_all.based_request_quantity     := gt_head_line(gn_i).ord_quant;  -- 拠点依頼数量
    ord_l_all.weight                     := NVL(gn_detail_we,0);           -- 重量
    ord_l_all.capacity                   := NVL(gn_detail_ca,0);           -- 容積
    ord_l_all.pallet_weight              := NVL(gn_ttl_prt_we,0);          -- パレット重量
    ord_l_all.request_item_id            := gr_i_item_id;                  -- 依頼品目ID
    ord_l_all.request_item_code          := gt_head_line(gn_i).ord_i_code; -- 依頼品目
    ord_l_all.pallet_quantity            := gn_pallet_am;                  -- パレット数
    ord_l_all.layer_quantity             := gn_step_am;                    -- 段数
    ord_l_all.case_quantity              := gn_case_am;                    -- ケース数
    ord_l_all.pallet_qty                 := gn_pallet_co_am;               -- パレット枚数
    ord_l_all.delete_flag                := gv_no;                         -- 削除フラグ
    ord_l_all.shipping_request_if_flg    := gv_no;
    ord_l_all.shipping_result_if_flg     := gv_no;
    ord_l_all.created_by                 := gn_created_by;                 -- 作成者
    ord_l_all.creation_date              := gd_creation_date;              -- 作成日
    ord_l_all.last_updated_by            := gn_last_upd_by;                -- 最終更新者
    ord_l_all.last_update_date           := gd_last_upd_date;              -- 最終更新日
    ord_l_all.last_update_login          := gn_last_upd_login;             -- 最終更新ログイン
    ord_l_all.request_id                 := gn_request_id;                 -- 要求ID
    ord_l_all.program_application_id     := gn_prog_appl_id;               -- プログラムアプリID
    ord_l_all.program_id                 := gn_prog_id;                    -- プログラムID
    ord_l_all.program_update_date        := gd_prog_upd_date;              -- プログラム更新日
    gv_wei_kbn                           := gr_i_wei_kbn;                  -- 重量容積区分
--
    -- 出荷依頼作成明細件数(依頼明細単位) カウント
    gn_line_cnt := gn_line_cnt + 1;
--
    ------------------------------------------------------
    -- 3.出荷単位換算数の算出                           --
    ------------------------------------------------------
-- 2008/08/11 H.Itou MOD START 内部課題#32
--    -- (1).｢出荷入数｣が設定されている場合、「数量」/「出荷入数」(小数点以下四捨五入)
--    IF (gr_ship_am IS NOT NULL) THEN
--      -- 0除算判定
--      IF (gr_ship_am = 0) THEN
--        gn_ship_amount := 0;
--      ELSE
--        gn_ship_amount := ROUND(gn_item_amount / gr_ship_am,0);
--      END IF;
    -- (1).｢出荷入数｣が0より大きい場合、「数量」/「出荷入数」
    IF (gr_ship_am > 0) THEN
        gn_ship_amount := gn_item_amount / gr_ship_am;
-- 2008/08/11 H.Itou MOD END
--
      -- ｢数量｣が｢出荷入数｣の整数倍ではない場合、ワーニング
      ln_mod_chk := MOD(gn_item_amount,gr_ship_am);
      IF (ln_mod_chk <> 0) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in 種別   '警告'
           ,iv_dec          => gv_msg_err                     --  in 種別   'エラー'
           ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => gv_msg_36                      --  in エラーメッセージ
           ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目  '-'
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
-- 2008/08/11 H.Itou MOD START 内部課題#32
--    -- (2).(1)以外、｢入数｣が設定されている場合、「数量」/「入数」(小数点以下四捨五入)
--    ELSIF (gr_case_am IS NOT NULL) THEN
--      -- 0除算判定
--      IF (gr_case_am = 0) THEN
--        gn_ship_amount := 0;
--      ELSE
--        gn_ship_amount := ROUND(gn_item_amount / gr_case_am,0);
--      END IF;
    -- (2).(1)以外、｢入数｣が設定されている場合、「数量」/「入数」
    ELSIF (gr_conv_unit IS NOT NULL) THEN
        gn_ship_amount := gn_item_amount / gr_case_am;
-- 2008/08/11 H.Itou MOD END
--
      -- ｢数量｣が｢入数｣の整数倍ではない場合。ワーニング
      ln_mod_chk := MOD(gn_item_amount,gr_case_am);
      IF (ln_mod_chk <> 0) THEN
        -- 入出庫換算単位の判定
        IF (gr_conv_unit IS NOT NULL) THEN
          -- 入出庫換算単位が設定されている場合、確定項目 'エラー'
          lv_dsc := gv_msg_err;
        ELSE
          -- 入出庫換算単位が未設定の場合、確定項目 '－'
          lv_dsc := gv_msg_hfn;
        END IF;
--
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in 種別   '警告'
           ,iv_dec          => lv_dsc                         --  in 確定
           ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => gv_msg_37                      --  in エラーメッセージ
           ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目  '-'
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    -- (3).(2)以外、「数量」設定
    ELSE
      gn_ship_amount := gn_item_amount;
    END IF;
--
    -- 受注ヘッダアドオン項目用変数 加算
-- 2008/08/11 H.Itou MOD START 変更要求#166 切り上げてから合計する。
--    gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;             -- 出荷単位換算数
    gn_ttl_ship_am  := gn_ttl_ship_am  + CEIL(gn_ship_amount);       -- 出荷単位換算数
-- 2008/08/11 H.Itou MOD END
    gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_ttl_we,0);           -- 積載重量合計
    gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_ttl_ca,0);           -- 積載容積合計
    gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);       -- 合計パレット重量
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_lines_create;
--
-- 2008/10/14 H.Itou Add Start 統合テスト指摘118
  /**********************************************************************************
   * Procedure Name   : pro_duplication_item_chk
   * Description      : 品目重複チェック (B-15)
   ***********************************************************************************/
  PROCEDURE pro_duplication_item_chk
    (
      iv_line_if_cnt IN NUMBER       -- ヘッダ毎明細IFカウント
     ,ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_duplication_item_chk'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_dup_item_err_flg VARCHAR2(1);  -- 品目重複エラーフラグ
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
    <<line_loop>>  -- ヘッダに紐付く明細全件ループ
    FOR ln_line_loop_cnt IN gn_i - iv_line_if_cnt + 1..gn_i LOOP
      <<chk_loop>>  -- 品目重複エラーチェックループ
      FOR ln_chk_loop_cnt IN gn_i - iv_line_if_cnt + 1..gn_i LOOP
        -- 同一品目がある場合、品目重複エラー
        IF ((ln_line_loop_cnt <> ln_chk_loop_cnt)
        AND (gt_head_line(ln_line_loop_cnt).ord_i_code  = gt_head_line(ln_chk_loop_cnt).ord_i_code)) THEN
          -- エラーリスト作成
          pro_err_list_make
            (
              iv_kind         => gv_msg_err                                        --  in 種別   'エラー'
             ,iv_dec          => gv_msg_hfn                                        --  in 確定   '－'
             ,iv_req_no       => gv_new_order_no                                   --  in 依頼No
             ,iv_kyoten       => gt_head_line(ln_line_loop_cnt).h_s_branch         --  in 管轄拠点
             ,iv_ship_to      => gt_head_line(ln_line_loop_cnt).p_s_code           --  in 出荷先
             ,iv_description  => gt_head_line(ln_line_loop_cnt).ship_ins           --  in 摘要
             ,iv_cust_pono    => gt_head_line(ln_line_loop_cnt).c_po_num           --  in 顧客発注番号
             ,iv_ship_date    => TO_CHAR(gt_head_line(ln_line_loop_cnt).ship_date,'YYYY/MM/DD')
                                                                                   --  in 出庫日
             ,iv_arrival_date => TO_CHAR(gt_head_line(ln_line_loop_cnt).arr_date,'YYYY/MM/DD')
                                                                                   --  in 着日
             ,iv_ship_from    => gt_head_line(ln_line_loop_cnt).lo_code            --  in 出荷元
             ,iv_item         => gt_head_line(ln_line_loop_cnt).ord_i_code         --  in 品目
             ,in_qty          => gt_head_line(ln_line_loop_cnt).ord_quant          --  in 数量
             ,iv_err_msg      => gv_msg_46                                         --  in エラーメッセージ
             ,iv_err_clm      => gv_msg_hfn                                        --  in エラー項目 '－'
             ,in_msg_seq      => gt_head_line(ln_line_loop_cnt).dup_item_msg_seq   --  in 品目重複メッセージ格納SEQ
             ,ov_errbuf       => lv_errbuf                                         -- out エラー・メッセージ
             ,ov_retcode      => lv_retcode                                        -- out リターン・コード
             ,ov_errmsg       => lv_errmsg                                         -- out ユーザー・エラー・メッセージ
            );
--
          -- 品目重複エラーフラグ：エラーあり
          lv_dup_item_err_flg := gv_status_error;
--
          -- 品目重複エラーをみつけたら、品目重複エラーチェックループ終了
          EXIT;
        END IF;
      END LOOP chk_loop;
    END LOOP line_loop;
--
    -- 品目重複エラーがあった場合
    IF (lv_dup_item_err_flg = gv_status_error) THEN
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
      RAISE err_header_expt;
    END IF;
--
  EXCEPTION
--
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_duplication_item_chk;
-- 2008/10/14 H.Itou Add End
--
  /**********************************************************************************
   * Procedure Name   : pro_load_eff_chk
   * Description      : 積載効率チェック (B-11)
   ***********************************************************************************/
  PROCEDURE pro_load_eff_chk
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
-- 2008/08/20 H.Itou Add Start 出荷追加_1
     ,iv_line_if_cnt IN NUMBER       -- ヘッダ毎明細IFカウント
-- 2008/08/20 H.Itou Add End
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_load_eff_chk'; -- プログラム名
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
    lv_errmsg_code VARCHAR2(30);  -- エラー・メッセージ・コード
    --
    ln_h_ttl_weight NUMBER;
    --
    lv_errbuf2  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode2 VARCHAR2(1);     -- リターン・コード
    lv_errmsg2  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 商品区分「ドリンク」かつ品目区分「製品」の場合
    IF (gr_item_skbn  = gv_2)
    AND (gr_item_kbn   = gv_5) THEN
      -- 「パレット最大枚数」と「パレット合計枚数」の比較
      --  出荷方法(アドオン)のパレット最大枚数を超えた場合エラーとする
      IF (gn_prt_max < gn_pallet_t_c_am) THEN
-- 2008/08/20 H.Itou ADD START 出荷追加_1 積載効率エラーのワーニングは明細ごとに出力
        <<warn_loop>>
        FOR i IN gn_i - iv_line_if_cnt + 1..gn_i LOOP
-- 2008/08/20 H.Itou ADD END
-- 2008/08/20 H.Itou MOD START 出荷追加_1
--        pro_err_list_make
--          (
--            iv_kind         => gv_msg_war                     --  in 種別   '警告'
--           ,iv_dec          => gv_msg_err                     --  in 種別   'エラー'
--           ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
--           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
--           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
--           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
--           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
--           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
--                                                              --  in 出庫日
--           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
--                                                              --  in 着日
--           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
--           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
--           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
--           ,iv_err_msg      => gv_msg_38                      --  in エラーメッセージ
--           ,iv_err_clm      => gn_pallet_t_c_am               --  in エラー項目  パレット合計枚数
--           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
--           ,ov_retcode      => lv_retcode                     -- out リターン・コード
--           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
--          );
          pro_err_list_make
            (
              iv_kind         => gv_msg_war                      --  in 種別   '警告'
             ,iv_dec          => gv_msg_err                      --  in 種別   'エラー'
             ,iv_req_no       => gv_new_order_no                 --  in 依頼No(12桁)
             ,iv_kyoten       => gt_head_line(i).h_s_branch      --  in 管轄拠点
             ,iv_ship_to      => gt_head_line(i).p_s_code        --  in 出荷先
             ,iv_description  => gt_head_line(i).ship_ins        --  in 摘要
             ,iv_cust_pono    => gt_head_line(i).c_po_num        --  in 顧客発注番号
             ,iv_ship_date    => TO_CHAR(gt_head_line(i).ship_date,'YYYY/MM/DD')
                                                                 --  in 出庫日
             ,iv_arrival_date => TO_CHAR(gt_head_line(i).arr_date,'YYYY/MM/DD')
                                                                 --  in 着日
             ,iv_ship_from    => gt_head_line(i).lo_code         --  in 出荷元
             ,iv_item         => gt_head_line(i).ord_i_code      --  in 品目
             ,in_qty          => gt_head_line(i).ord_quant       --  in 数量
             ,iv_err_msg      => gv_msg_38                       --  in エラーメッセージ
             ,iv_err_clm      => gn_pallet_t_c_am                --  in エラー項目  パレット合計枚数
             ,in_msg_seq      => gt_head_line(i).prt_max_msg_seq -- in メッセージ格納SEQ
             ,ov_errbuf       => lv_errbuf                       -- out エラー・メッセージ
             ,ov_retcode      => lv_retcode                      -- out リターン・コード
             ,ov_errmsg       => lv_errmsg                       -- out ユーザー・エラー・メッセージ
            );
-- 2008/08/20 H.Itou MOD END
-- 2008/08/20 H.Itou ADD START
        END LOOP warn_loop;
-- 2008/08/20 H.Itou ADD END
        -- 共通エラーメッセージ 終了STの判定
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
    END IF;
--
    --
    IF ( gv_small_qty_flg = 0 ) THEN
      ln_h_ttl_weight :=  gn_h_ttl_weight + gn_h_ttl_pallet;
    ELSE
      ln_h_ttl_weight := gn_h_ttl_weight;
    END IF;
    --
    -- 共通関数｢積載効率チェック(積載効率算出)｣にてチェック (明細重量の場合)
    xxwsh_common910_pkg.calc_load_efficiency
                            (
                              ln_h_ttl_weight              -- 合計重量         in 積載重量合計
                             ,NULL                         -- 合計容積         in NULL
                             ,gv_4                         -- コード区分From   in 倉庫'4'
                             ,gt_head_line(gn_i).lo_code   -- 入出庫区分From   in 出荷元保管場所
                             ,gv_9                         -- コード区分To     in 配送先'9'
                             ,gt_head_line(gn_i).p_s_code  -- 入出庫区分To     in 出荷先
                             ,gv_max_kbn                   -- 最大配送区分     in 最大配送区分
-- 2008/08/20 H.Itou MOD START 出荷追加_1
--                             ,gr_item_skbn                 -- 商品区分         in 商品区分
                             ,gr_skbn                      -- 商品区分         in 商品区分
-- 2008/08/20 H.Itou MOD END
                             ,NULL                         -- 自動配車対象区分 in NULL
                             ,gt_head_line(gn_i).ship_date -- 基準日           in 出荷予定日
                             ,lv_retcode                   -- リターン・コード
                             ,lv_errmsg_code               -- エラー・メッセージ・コード
                             ,lv_errmsg                    -- エラー・メッセージ
                             ,gv_over_kbn                  -- 積載オーバー区分 0:正常,1:オーバー
                             ,gv_ship_way                  -- 出荷方法
                             ,gn_we_loading                -- 重量積載効率
                             ,gn_ca_dammy                  -- 容積積載効率
                             ,gv_mix_ship                  -- 混載配送区分
                            );
--
    -- リターンコードがエラー時。エラー
    IF (lv_retcode = gv_1) THEN
-- 2008/08/20 H.Itou ADD START 出荷追加_1 積載効率エラーのワーニングは明細ごとに出力
      <<err_loop>>
      FOR i IN gn_i - iv_line_if_cnt + 1..gn_i LOOP
-- 2008/08/20 H.Itou ADD END
-- 2008/08/20 H.Itou MOD START 出荷追加_1
--      pro_err_list_make
--        (
--          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
--         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
--         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
--         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
--         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
--         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
--         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
--         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
--                                                            --  in 出庫日
--         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
--                                                            --  in 着日
--         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
--         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
--         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
--         ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
--         ,iv_err_clm      => lv_errmsg                      --  in エラー項目   品目
--         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
--         ,ov_retcode      => lv_retcode                     -- out リターン・コード
--         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
--        );
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                         --  in 種別   'エラー'
           ,iv_dec          => gv_msg_hfn                         --  in 確定   '－'
           ,iv_req_no       => gt_head_line(i).o_r_ref            --  in 依頼No
           ,iv_kyoten       => gt_head_line(i).h_s_branch         --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(i).p_s_code           --  in 出荷先
           ,iv_description  => gt_head_line(i).ship_ins           --  in 摘要
           ,iv_cust_pono    => gt_head_line(i).c_po_num           --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(i).ship_date,'YYYY/MM/DD')
                                                                  --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(i).arr_date,'YYYY/MM/DD')
                                                                  --  in 着日
           ,iv_ship_from    => gt_head_line(i).lo_code            --  in 出荷元
           ,iv_item         => gt_head_line(i).ord_i_code         --  in 品目
           ,in_qty          => gt_head_line(i).ord_quant          --  in 数量
           ,iv_err_msg      => lv_errmsg                          --  in エラーメッセージ
           ,iv_err_clm      => lv_errmsg                          --  in エラー項目   品目
           ,in_msg_seq      => gt_head_line(i).we_loading_msg_seq --  in メッセージ格納SEQ
           ,ov_errbuf       => lv_errbuf2                         -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode2                        -- out リターン・コード
           ,ov_errmsg       => lv_errmsg2                         -- out ユーザー・エラー・メッセージ
          );
-- 2008/08/20 H.Itou MOD END
-- 2008/08/20 H.Itou ADD START
      END LOOP err_loop;
-- 2008/08/20 H.Itou ADD END
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
-- 2008/08/20 H.Itou Mod Start 出荷追加_1
--    -- 積載オーバー時、ワーニング
--    IF (gv_over_kbn = gv_1) THEN
    -- 重量容積区分が重量で積載オーバー時、ワーニング
    IF ((gv_over_kbn = gv_1) AND (gr_wei_kbn = gv_1)) THEN
-- 2008/08/20 H.Itou Mod End
-- 2008/08/20 H.Itou ADD START 出荷追加_1 積載効率エラーのワーニングは明細ごとに出力
      <<warn_loop>>
      FOR i IN gn_i - iv_line_if_cnt + 1..gn_i LOOP
-- 2008/08/20 H.Itou ADD END
-- 2008/08/20 H.Itou MOD START 出荷追加_1
--      pro_err_list_make
--        (
--          iv_kind         => gv_msg_war                     --  in 種別   '警告'
--         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
--         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
--         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
--         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
--         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
--         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
--         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
--                                                            --  in 出庫日
--         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
--                                                            --  in 着日
--         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
--         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
--         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
--         ,iv_err_msg      => gv_msg_39                      --  in エラーメッセージ
--         ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in エラー項目   数量
--         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
--         ,ov_retcode      => lv_retcode                     -- out リターン・コード
--         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
--        );
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                         --  in 種別   '警告'
           ,iv_dec          => gv_msg_err                         --  in 確定   'エラー'
           ,iv_req_no       => gv_new_order_no                    --  in 依頼No(12桁)
           ,iv_kyoten       => gt_head_line(i).h_s_branch         --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(i).p_s_code           --  in 出荷先
           ,iv_description  => gt_head_line(i).ship_ins           --  in 摘要
           ,iv_cust_pono    => gt_head_line(i).c_po_num           --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(i).ship_date,'YYYY/MM/DD')
                                                                  --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(i).arr_date,'YYYY/MM/DD')
                                                                  --  in 着日
           ,iv_ship_from    => gt_head_line(i).lo_code            --  in 出荷元
           ,iv_item         => gt_head_line(i).ord_i_code         --  in 品目
           ,in_qty          => gt_head_line(i).ord_quant          --  in 数量
           ,iv_err_msg      => gv_msg_39                          --  in エラーメッセージ
           ,iv_err_clm      => gt_head_line(i).ord_quant          --  in エラー項目   数量
           ,in_msg_seq      => gt_head_line(i).we_loading_msg_seq --  in メッセージ格納SEQ
           ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                         -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
          );
-- 2008/08/20 H.Itou MOD END
-- 2008/08/20 H.Itou ADD START
      END LOOP warn_loop;
-- 2008/08/20 H.Itou ADD END
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- 共通関数｢積載効率チェック(積載効率算出)｣にてチェック (明細容積の場合)
    xxwsh_common910_pkg.calc_load_efficiency
                            (
                              NULL                         -- 合計重量         in NULL
                             ,gn_h_ttl_capa                -- 合計容積         in 積載容積合計
                             ,gv_4                         -- コード区分From   in 倉庫'4'
                             ,gt_head_line(gn_i).lo_code   -- 入出庫区分From   in 出荷元保管場所
                             ,gv_9                         -- コード区分To     in 配送先'9'
                             ,gt_head_line(gn_i).p_s_code  -- 入出庫区分To     in 出荷先
                             ,gv_max_kbn                   -- 最大配送区分     in 最大配送区分
-- 2008/08/20 H.Itou MOD START 出荷追加_1
--                             ,gr_item_skbn                 -- 商品区分         in 商品区分
                             ,gr_skbn                      -- 商品区分         in 商品区分
-- 2008/08/20 H.Itou MOD END
                             ,NULL                         -- 自動配車対象区分 in NULL
                             ,gt_head_line(gn_i).ship_date -- 基準日           in 出荷予定日
                             ,lv_retcode                   -- リターン・コード
                             ,lv_errmsg_code               -- エラー・メッセージ・コード
                             ,lv_errmsg                    -- エラー・メッセージ
                             ,gv_over_kbn                  -- 積載オーバー区分 0:正常,1:オーバー
                             ,gv_ship_way                  -- 出荷方法
                             ,gn_we_dammy                  -- 重量積載効率
                             ,gn_ca_loading                -- 容積積載効率
                             ,gv_mix_ship                  -- 混載配送区分
                            );
--
    -- リターンコードがエラー時。エラー
    IF (lv_retcode = gv_1) THEN
-- 2008/08/20 H.Itou ADD START 出荷追加_1 積載効率エラーのワーニングは明細ごとに出力
      <<err_loop>>
      FOR i IN gn_i - iv_line_if_cnt + 1..gn_i LOOP
-- 2008/08/20 H.Itou ADD END
-- 2008/08/20 H.Itou MOD START 出荷追加_1
--      pro_err_list_make
--        (
--          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
--         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
--         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
--         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
--         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
--         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
--         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
--         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
--                                                            --  in 出庫日
--         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
--                                                            --  in 着日
--         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
--         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
--         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
--         ,iv_err_msg      => lv_errmsg                      --  in エラーメッセージ
--         ,iv_err_clm      => lv_errmsg                      --  in エラー項目   品目
--         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
--         ,ov_retcode      => lv_retcode                     -- out リターン・コード
--         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
--        );
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                         --  in 種別   'エラー'
           ,iv_dec          => gv_msg_hfn                         --  in 確定   '－'
           ,iv_req_no       => gt_head_line(i).o_r_ref            --  in 依頼No
           ,iv_kyoten       => gt_head_line(i).h_s_branch         --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(i).p_s_code           --  in 出荷先
           ,iv_description  => gt_head_line(i).ship_ins           --  in 摘要
           ,iv_cust_pono    => gt_head_line(i).c_po_num           --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(i).ship_date,'YYYY/MM/DD')
                                                                  --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(i).arr_date,'YYYY/MM/DD')
                                                                  --  in 着日
           ,iv_ship_from    => gt_head_line(i).lo_code            --  in 出荷元
           ,iv_item         => gt_head_line(i).ord_i_code         --  in 品目
           ,in_qty          => gt_head_line(i).ord_quant          --  in 数量
           ,iv_err_msg      => lv_errmsg                          --  in エラーメッセージ
           ,iv_err_clm      => lv_errmsg                          --  in エラー項目   品目
           ,in_msg_seq      => gt_head_line(i).ca_loading_msg_seq -- in メッセージ格納SEQ
           ,ov_errbuf       => lv_errbuf2                         -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode2                        -- out リターン・コード
           ,ov_errmsg       => lv_errmsg2                         -- out ユーザー・エラー・メッセージ
          );
-- 2008/08/20 H.Itou MOD END
-- 2008/08/20 H.Itou ADD START
      END LOOP err_loop;
-- 2008/08/20 H.Itou ADD END
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
-- 2008/08/20 H.Itou Mod Start 出荷追加_1
--    -- 積載オーバー時、ワーニング
--    IF (gv_over_kbn = gv_1) THEN
    -- 重量容積区分が容積で積載オーバー時、ワーニング
    IF ((gv_over_kbn = gv_1) AND (gr_wei_kbn = gv_2)) THEN
-- 2008/08/20 H.Itou Mod End
-- 2008/08/20 H.Itou ADD START 出荷追加_1 積載効率エラーのワーニングは明細ごとに出力
      <<warn_loop>>
      FOR i IN gn_i - iv_line_if_cnt + 1..gn_i LOOP
-- 2008/08/20 H.Itou ADD END
-- 2008/08/20 H.Itou MOD START 出荷追加_1
--      pro_err_list_make
--        (
--          iv_kind         => gv_msg_war                     --  in 種別   '警告'
--         ,iv_dec          => gv_msg_err                     --  in 確定   'エラー'
--         ,iv_req_no       => gv_new_order_no                --  in 依頼No(12桁)
--         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
--         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
--         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
--         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
--         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
--                                                            --  in 出庫日
--         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
--                                                            --  in 着日
--         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
--         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
--         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
--         ,iv_err_msg      => gv_msg_39                      --  in エラーメッセージ
--         ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in エラー項目   数量
--         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
--         ,ov_retcode      => lv_retcode                     -- out リターン・コード
--         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
--        );
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                         --  in 種別   '警告'
           ,iv_dec          => gv_msg_err                         --  in 確定   'エラー'
           ,iv_req_no       => gv_new_order_no                    --  in 依頼No(12桁)
           ,iv_kyoten       => gt_head_line(i).h_s_branch         --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(i).p_s_code           --  in 出荷先
           ,iv_description  => gt_head_line(i).ship_ins           --  in 摘要
           ,iv_cust_pono    => gt_head_line(i).c_po_num           --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(i).ship_date,'YYYY/MM/DD')
                                                                  --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(i).arr_date,'YYYY/MM/DD')
                                                                  --  in 着日
           ,iv_ship_from    => gt_head_line(i).lo_code            --  in 出荷元
           ,iv_item         => gt_head_line(i).ord_i_code         --  in 品目
           ,in_qty          => gt_head_line(i).ord_quant          --  in 数量
           ,iv_err_msg      => gv_msg_39                          --  in エラーメッセージ
           ,iv_err_clm      => gt_head_line(i).ord_quant          --  in エラー項目   数量
           ,in_msg_seq      => gt_head_line(i).ca_loading_msg_seq --  in メッセージ格納SEQ
           ,ov_errbuf       => lv_errbuf                          -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                         -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                          -- out ユーザー・エラー・メッセージ
          );
-- 2008/08/20 H.Itou MOD END
-- 2008/08/20 H.Itou ADD START
      END LOOP warn_loop;
-- 2008/08/20 H.Itou ADD END
      -- 共通エラーメッセージ 終了STの判定
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_load_eff_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_headers_create
   * Description      : 受注ヘッダアドオンレコード生成 (B-12)
   ***********************************************************************************/
  PROCEDURE pro_headers_create
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_headers_create'; -- プログラム名
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
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 合計数量の算出
    IF (gr_h_id = gt_head_line(gn_i).h_id) THEN
      -- 同一ヘッダIDの場合、明細の数量を加算
      gn_ttl_amount := gn_ttl_amount + gn_item_amount;
    ELSE
      gn_ttl_amount := gn_item_amount;
    END IF;
--
    -- 基本重量・基本容積判定
    -- 商品区分「リーフ」の場合
    IF (gr_item_skbn = gv_1) THEN
      gn_basic_we := gn_leaf_we;
      gn_basic_ca := gn_leaf_ca;
    -- 商品区分「ドリンク」の場合
    ELSIF (gr_item_skbn = gv_2) THEN
      gn_basic_we := gn_drink_we;
      gn_basic_ca := gn_drink_ca;
    END IF;
--
    ------------------------------------------------------
    -- 受注ヘッダアドオン作成用レコード変数へ格納       --
    ------------------------------------------------------
    ord_h_all.order_header_id              := gn_headers_seq;                -- 受注ヘッダアドオンID
    ord_h_all.order_type_id                := gr_odr_type;                     -- 受注タイプID
    ord_h_all.organization_id              := gv_name_m_org;                   -- 組織ID
    ord_h_all.latest_external_flag         := gv_yes;                          -- 最新フラグ
    ord_h_all.ordered_date                 := gd_sysdate;                      -- 受注日
    ord_h_all.customer_id                  := gr_c_acc_num;                    -- 顧客ID
    ord_h_all.customer_code                := gr_party_num;                    -- 顧客
    ord_h_all.deliver_to_id                := gr_p_site_id;                    -- 出荷先ID
    ord_h_all.deliver_to                   := gt_head_line(gn_i).p_s_code;     -- 出荷先
    ord_h_all.shipping_instructions        := gt_head_line(gn_i).ship_ins;     -- 出荷指示
    ord_h_all.career_id                    := gr_party_id;                     -- 運送業者ID
    ord_h_all.freight_carrier_code         := gr_party_number;                 -- 運送業者
    ord_h_all.shipping_method_code         := gv_max_kbn;                      -- 配送区分
    ord_h_all.cust_po_number               := gt_head_line(gn_i).c_po_num;     -- 顧客発注
    ord_h_all.request_no                   := gv_new_order_no;                 -- 依頼No
    ord_h_all.req_status                   := gr_ship_st;                      -- ステータス
    ord_h_all.schedule_ship_date           := gt_head_line(gn_i).ship_date;    -- 出荷予定日
    ord_h_all.schedule_arrival_date        := gt_head_line(gn_i).arr_date;     -- 着荷予定日
    ord_h_all.confirm_request_class        := gv_0;                            -- 物流担当確認依頼区分
    ord_h_all.freight_charge_class         := gv_1;                            -- 運賃区分
    ord_h_all.no_cont_freight_class        := gv_0;                            -- 契約外運賃区分
    ord_h_all.deliver_from_id              := gr_ship_id;                      -- 出荷元ID
    ord_h_all.deliver_from                 := gt_head_line(gn_i).lo_code;      -- 出荷元保管場所
    ord_h_all.Head_sales_branch            := gt_head_line(gn_i).h_s_branch;   -- 管轄拠点
    ord_h_all.input_sales_branch           := gt_head_line(gn_i).in_sales_br;  -- 入力拠点
    ord_h_all.prod_class                   := gr_skbn;                         -- 商品区分
    ord_h_all.arrival_time_from            := gt_head_line(gn_i).arr_t_from;   -- 着荷時間FROM
-- 2009/08/03 T.Miyata Add Start SCS障害管理表（0000918）対応
    ord_h_all.arrival_time_to              := gt_head_line(gn_i).arr_t_to;     -- 着荷時間To
-- 2009/08/03 T.Miyata Add End   SCS障害管理表（0000918）対応
    ord_h_all.sum_quantity                 := gn_ttl_amount;                   -- 合計数量
    ord_h_all.small_quantity               := gn_ttl_ship_am;                  -- 小口個数
    ord_h_all.label_quantity               := gn_ttl_ship_am;                  -- ラベル枚数
    ord_h_all.loading_efficiency_weight    := gn_we_loading;                   -- 重量積載効率
    ord_h_all.loading_efficiency_capacity  := gn_ca_loading;                   -- 容積積載効率
    ord_h_all.based_weight                 := gn_basic_we;                     -- 基本重量
    ord_h_all.based_capacity               := gn_basic_ca;                     -- 基本容積
    ord_h_all.sum_weight                   := gn_h_ttl_weight;                 -- 積載重量合計
    ord_h_all.sum_capacity                 := gn_h_ttl_capa;                   -- 積載容積合計
    ord_h_all.sum_pallet_weight            := gn_h_ttl_pallet;                 -- 合計パレット重量
    ord_h_all.pallet_sum_quantity          := gn_pallet_t_c_am;                -- パレット合計枚数
    ord_h_all.order_source_ref             := NULL;                            -- 受注ソース参照
    ord_h_all.weight_capacity_class        := gr_wei_kbn;                      -- 重量容積区分
    ord_h_all.actual_confirm_class         := gv_no;                           -- 実績計上済区分
    ord_h_all.notif_status                 := gr_notice_st;                    -- 通知ステータス
    ord_h_all.new_modify_flg               := gv_no;                           -- 新規修正フラグ
    ord_h_all.performance_management_dept  := NULL;                            -- 成績管理部署
    ord_h_all.created_by                   := gn_created_by;                   -- 作成者
    ord_h_all.creation_date                := gd_creation_date;                -- 作成日
    ord_h_all.last_updated_by              := gn_last_upd_by;                  -- 最終更新者
    ord_h_all.last_update_date             := gd_last_upd_date;                -- 最終更新日
    ord_h_all.last_update_login            := gn_last_upd_login;               -- 最終更新ログイン
    ord_h_all.request_id                   := gn_request_id;                   -- 要求ID
    ord_h_all.program_application_id       := gn_prog_appl_id;                 -- プログラムアプリID
    ord_h_all.program_id                   := gn_prog_id;                      -- プログラムID
    ord_h_all.program_update_date          := gd_prog_upd_date;                -- プログラム更新日
--
    -- 重量容積区分のチェック
    IF (gr_wei_kbn <> gv_wei_kbn) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in 種別   'エラー'
         ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in 出庫日
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in 着日
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
         ,iv_err_msg      => gv_msg_40                      --  in エラーメッセージ
         ,iv_err_clm      => gv_msg_hfn                     --  in エラー項目   '－'
         ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
         ,ov_retcode      => lv_retcode                     -- out リターン・コード
         ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
        );
      -- 共通エラーメッセージ 終了ST エラー登録
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_headers_create;
--
  /**********************************************************************************
   * Procedure Name   : pro_order_ins_del
   * Description      : 受注アドオン出力  (B-13)
   ***********************************************************************************/
  PROCEDURE pro_order_ins_del
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_order_ins_del'; -- プログラム名
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
    ln_chk      NUMBER DEFAULT 0;      -- 受注ヘッダアドオン存在チェック
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    ----------------------------------------------------------------------------
    -- 1.受注ヘッダアドオンの登録状況／ステータスチェック
    ----------------------------------------------------------------------------
    SELECT COUNT (xoha.order_header_id)    -- 受注ヘッダアドオンID
    INTO   ln_chk
    FROM   xxwsh_order_headers_all   xoha   -- 受注ヘッダアドオン
    WHERE  xoha.request_no = gv_new_order_no  -- 依頼No
    AND    ROWNUM          = 1
    ;
--
    -- 受注ヘッダアドオンに存在している場合
    IF (ln_chk = 1) THEN
      SELECT xoha.order_header_id    -- 受注ヘッダアドオンID
            ,xoha.req_status         -- ステータス
      INTO   gr_ord_he_id
            ,gr_req_status
      FROM   xxwsh_order_headers_all   xoha   -- 受注ヘッダアドオン
      WHERE  xoha.request_no           = gv_new_order_no  -- 依頼No
      AND    xoha.latest_external_flag = gv_yes           -- 最新フラグ'Y'
      ;
--
      -- 上記にて取得したデータのステータスが拠点確定以上の場合、エラー
      --IF ((gr_req_status > gv_01)
      --AND (gr_req_status < gv_99))
      IF (gr_req_status <> gv_01)
      THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in 種別   'エラー'
           ,iv_dec          => gv_msg_hfn                     --  in 確定   '－'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in 依頼No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in 管轄拠点
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in 出荷先
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in 摘要
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in 顧客発注番号
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in 出庫日
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in 着日
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in 出荷元
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in 品目
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in 数量
           ,iv_err_msg      => gv_msg_41                      --  in エラーメッセージ
           ,iv_err_clm      => gn_pallet_t_c_am               --  in エラー項目  パレット合計枚数
           ,ov_errbuf       => lv_errbuf                      -- out エラー・メッセージ
           ,ov_retcode      => lv_retcode                     -- out リターン・コード
           ,ov_errmsg       => lv_errmsg                      -- out ユーザー・エラー・メッセージ
          );
        -- 共通エラーメッセージ 終了ST エラー登録
        gv_err_sts := gv_status_error;
--
        -- IFテーブル削除対象
        gv_del_if_flg := gv_yes;
--
        RAISE err_header_expt;
      END IF;
--
      ----------------------------------------------------------------------------
      -- 2.データ削除処理                                                       --
      ----------------------------------------------------------------------------
      -- 登録対象「依頼No」のステータスが『入力中』の場合、受注ヘッダアドオン/受注明細アドオン削除
      IF (((gr_h_id      <> gt_head_line(gn_i).h_id) OR ( gr_h_id IS NULL ))
      AND (gr_req_status = gr_ship_st))
      THEN
        -- 受注明細アドオン削除
        DELETE
        FROM   xxwsh_order_lines_all   xola    -- 受注明細アドオン
        WHERE  xola.order_header_id    = gr_ord_he_id   -- 受注ヘッダアドオンID
        ;
      END IF;
--
      IF (gr_req_status = gr_ship_st) THEN
        -- 受注ヘッダアドオン削除
        DELETE
        FROM   xxwsh_order_headers_all xoha    -- 受注ヘッダアドオン
        WHERE  xoha.order_header_id    = gr_ord_he_id   -- 受注ヘッダアドオンID
        ;
--
      END IF;
    END IF;
--
--
    ----------------------------------------------------------------------------
    -- 3.受注ヘッダアドオン・受注明細アドオンへデータ登録                     --
    ----------------------------------------------------------------------------
    -- *************************************************
    -- ***  受注ヘッダアドオンテーブル登録           ***
    -- *************************************************
    INSERT INTO xxwsh_order_headers_all
      ( order_header_id
       ,order_type_id
       ,organization_id
       ,latest_external_flag
       ,ordered_date
       ,customer_id
       ,customer_code
       ,deliver_to_id
       ,deliver_to
       ,shipping_instructions
       ,career_id
       ,freight_carrier_code
       ,shipping_method_code
       ,cust_po_number
       ,request_no
       ,req_status
       ,schedule_ship_date
       ,schedule_arrival_date
       ,confirm_request_class
       ,freight_charge_class
       ,no_cont_freight_class
       ,deliver_from_id
       ,deliver_from
       ,head_sales_branch
       ,input_sales_branch
       ,prod_class
       ,arrival_time_from
-- 2009/08/03 T.Miyata Add Start SCS障害管理表（0000918）対応
       ,arrival_time_to
-- 2009/08/03 T.Miyata Add End   SCS障害管理表（0000918）対応
       ,sum_quantity
       ,small_quantity
       ,label_quantity
       ,loading_efficiency_weight
       ,loading_efficiency_capacity
       ,based_weight
       ,based_capacity
       ,sum_weight
       ,sum_capacity
       ,sum_pallet_weight
       ,pallet_sum_quantity
       ,order_source_ref
       ,weight_capacity_class
       ,actual_confirm_class
       ,notif_status
       ,new_modify_flg
       ,performance_management_dept
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
      ) VALUES
      ( ord_h_all.order_header_id
       ,ord_h_all.order_type_id
       ,ord_h_all.organization_id
       ,ord_h_all.latest_external_flag
       ,ord_h_all.ordered_date
       ,ord_h_all.customer_id
       ,ord_h_all.customer_code
       ,ord_h_all.deliver_to_id
       ,ord_h_all.deliver_to
       ,ord_h_all.shipping_instructions
       ,ord_h_all.career_id
       ,ord_h_all.freight_carrier_code
       ,ord_h_all.shipping_method_code
       ,ord_h_all.cust_po_number
       ,ord_h_all.request_no
       ,ord_h_all.req_status
       ,ord_h_all.schedule_ship_date
       ,ord_h_all.schedule_arrival_date
       ,ord_h_all.confirm_request_class
       ,ord_h_all.freight_charge_class
       ,ord_h_all.no_cont_freight_class
       ,ord_h_all.deliver_from_id
       ,ord_h_all.deliver_from
       ,ord_h_all.Head_sales_branch
       ,ord_h_all.input_sales_branch
       ,ord_h_all.prod_class
       ,ord_h_all.arrival_time_from
-- 2009/08/03 T.Miyata Add Start SCS障害管理表（0000918）対応
       ,ord_h_all.arrival_time_to
-- 2009/08/03 T.Miyata Add End   SCS障害管理表（0000918）対応
       ,ord_h_all.sum_quantity
       ,ord_h_all.small_quantity
       ,ord_h_all.label_quantity
       ,ord_h_all.loading_efficiency_weight
       ,ord_h_all.loading_efficiency_capacity
       ,ord_h_all.based_weight
       ,ord_h_all.based_capacity
       ,ord_h_all.sum_weight
       ,ord_h_all.sum_capacity
       ,ord_h_all.sum_pallet_weight
       ,ord_h_all.pallet_sum_quantity
       ,ord_h_all.order_source_ref
       ,ord_h_all.weight_capacity_class
       ,ord_h_all.actual_confirm_class
       ,ord_h_all.notif_status
       ,ord_h_all.new_modify_flg
       ,ord_h_all.performance_management_dept
       ,ord_h_all.created_by
       ,ord_h_all.creation_date
       ,ord_h_all.last_updated_by
       ,ord_h_all.last_update_date
       ,ord_h_all.last_update_login
       ,ord_h_all.request_id
       ,ord_h_all.program_application_id
       ,ord_h_all.program_id
       ,ord_h_all.program_update_date
      );
--
    -- *************************************************
    -- ***  受注明細アドオンテーブル登録             ***
    -- *************************************************
    INSERT INTO xxwsh_order_lines_all
      ( order_line_id
       ,order_header_id
       ,order_line_number
       ,request_no
       ,shipping_inventory_item_id
       ,shipping_item_code
       ,quantity
       ,uom_code
       ,based_request_quantity
       ,weight
       ,capacity
       ,pallet_weight
       ,request_item_id
       ,request_item_code
       ,pallet_quantity
       ,layer_quantity
       ,case_quantity
       ,pallet_qty
       ,delete_flag
       ,shipping_request_if_flg
       ,shipping_result_if_flg
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
      ) VALUES
      ( ord_l_all.order_line_id
       ,ord_l_all.order_header_id
       ,ord_l_all.order_line_number
       ,ord_l_all.request_no
       ,ord_l_all.shipping_inventory_item_id
       ,ord_l_all.shipping_item_code
       ,ord_l_all.quantity
       ,ord_l_all.uom_code
       ,ord_l_all.based_request_quantity
       ,ord_l_all.weight
       ,ord_l_all.capacity
       ,ord_l_all.pallet_weight
       ,ord_l_all.request_item_id
       ,ord_l_all.request_item_code
       ,ord_l_all.pallet_quantity
       ,ord_l_all.layer_quantity
       ,ord_l_all.case_quantity
       ,ord_l_all.pallet_qty
       ,ord_l_all.delete_flag
       ,ord_l_all.shipping_request_if_flg
       ,ord_l_all.shipping_result_if_flg
       ,ord_l_all.created_by
       ,ord_l_all.creation_date
       ,ord_l_all.last_updated_by
       ,ord_l_all.last_update_date
       ,ord_l_all.last_update_login
       ,ord_l_all.request_id
       ,ord_l_all.program_application_id
       ,ord_l_all.program_id
       ,ord_l_all.program_update_date
      );
--
  EXCEPTION
    -- *** 共通関数 警告・エラー ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_order_ins_del;
--
  /**********************************************************************************
   * Procedure Name   : pro_purge_del
   * Description      : パージ処理   (B-14)
   ***********************************************************************************/
  PROCEDURE pro_purge_del
    (
      ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_purge_del'; -- プログラム名
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
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 入力パラメータ「入力拠点」のみ設定の場合
    IF (gr_param.jur_base IS NULL) THEN
      -- 出荷依頼インタフェース明細（アドオン）対象データ削除
      DELETE
      FROM  xxwsh_shipping_lines_if    xsli -- 出荷依頼インタフェース明細（アドオン）
      WHERE xsli.header_id IN
        (SELECT xshi.header_id
         FROM   xxwsh_shipping_headers_if  xshi -- 出荷依頼インタフェースヘッダ（アドオン）
         WHERE  xshi.header_id          = xshi.header_id     -- ヘッダID
         AND    xshi.input_sales_branch = gr_param.in_base   -- 入力拠点
         AND    xshi.data_type          = gv_10     -- [出荷依頼]を示すクイックコード(データタイプ)
        )
      ;
--
      -- 出荷依頼インタフェースヘッダ（アドオン）対象データ削除
      DELETE
      FROM   xxwsh_shipping_headers_if  xshi -- 出荷依頼インタフェースヘッダ（アドオン）
      WHERE  xshi.header_id          = xshi.header_id     -- ヘッダID
      AND    xshi.input_sales_branch = gr_param.in_base   -- 入力拠点
      AND    xshi.data_type          = gv_10     -- [出荷依頼]を示すクイックコード(データタイプ)
      ;
--
    -- 入力パラメータ「入力拠点」「管轄拠点」両方設定の場合
    ELSE
      -- 出荷依頼インタフェース明細（アドオン）対象データ削除
      DELETE
      FROM  xxwsh_shipping_lines_if    xsli -- 出荷依頼インタフェース明細（アドオン）
      WHERE xsli.header_id IN
        (SELECT xshi.header_id
         FROM   xxwsh_shipping_headers_if  xshi -- 出荷依頼インタフェースヘッダ（アドオン）
         WHERE  xshi.header_id          = xshi.header_id     -- ヘッダID
         AND    xshi.input_sales_branch = gr_param.in_base   -- 入力拠点
         AND    xshi.head_sales_branch  = gr_param.jur_base  -- 管轄拠点
         AND    xshi.data_type          = gv_10     -- [出荷依頼]を示すクイックコード(データタイプ)
        )
      ;
--
      -- 出荷依頼インタフェースヘッダ（アドオン）対象データ削除
      DELETE
      FROM   xxwsh_shipping_headers_if  xshi -- 出荷依頼インタフェースヘッダ（アドオン）
      WHERE  xshi.header_id          = xshi.header_id     -- ヘッダID
      AND    xshi.input_sales_branch = gr_param.in_base   -- 入力拠点
      AND    xshi.head_sales_branch  = gr_param.jur_base  -- 管轄拠点
      AND    xshi.data_type          = gv_10     -- [出荷依頼]を示すクイックコード(データタイプ)
      ;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END pro_purge_del;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_in_base    IN  VARCHAR2    --  01.入力拠点
     ,iv_jur_base   IN  VARCHAR2    --  02.管轄拠点
     ,ov_errbuf     OUT VARCHAR2    --  エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2    --  リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2    --  ユーザー・エラー・メッセージ --# 固定 #
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
    ln_j       NUMBER;          -- カウンタ変数(明細)
    ln_k       NUMBER;          -- カウンタ変数(ヘッダ)
--
-- 2008/08/20 H.Itou Add Start 出荷追加_1 積載効率チェックはヘッダ単位で実施。B-4でエラーの場合は実施しない。
    lv_load_eff_chk_flag  VARCHAR2(1);  -- 積載効率チェック実施フラグ
    ln_line_if_cnt        NUMBER;       -- ヘッダ毎明細IF件数カウント
-- 2008/08/20 H.Itou Add End
--###########################  固定部 END   ####################################
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
    -- 初期処理
    -- =====================================================
    -- -----------------------------------------------------
    -- パラメータ格納
    -- -----------------------------------------------------
    gr_param.in_base   := iv_in_base;     -- 入力拠点
    gr_param.jur_base  := iv_jur_base;    -- 管轄拠点
--
    -- 開始時のシステム現在日付を代入
    gd_sysdate         := TRUNC( SYSDATE );
--
    -- 共通エラーメッセージ 終了ST初期化
    gv_err_sts         := gv_status_normal;
--
    -- =====================================================
    --  関連データ取得 (B-1)
    -- =====================================================
    pro_get_cus_option
      (
        ov_errbuf         => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  入力パラメータチェック    (B-2)
    -- =====================================================
    pro_param_chk
      (
        ov_errbuf         => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  出荷依頼インターフェース情報取得   (B-3)
    -- =====================================================
    pro_get_head_line
      (
        ot_head_line    => gt_head_line     -- 取得レコード群
       ,ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 2008/07/09 Add ↓
    IF (gt_head_line.COUNT = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10036');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    END IF;
    -- 2008/07/09 Add ↑
--
    <<headers_data_loop>>
    FOR i IN 1..gt_head_line.COUNT LOOP
      -- LOOPカウント用変数へカウント数挿入
      gn_i := i;
--
      -- エラー確認用フラグ初期化
      gv_err_flg := gv_0;
--
      -- 初回レコード時かヘッダIDが異なった場合、実行
      IF ((gn_i     = 1)
      OR  (gr_h_id <> gt_head_line(gn_i).h_id))
      THEN
        ---------------------------------------------
        -- 受注ヘッダアドオンID シーケンス取得     --
        ---------------------------------------------
        SELECT xxwsh_order_headers_all_s1.NEXTVAL
        INTO   gn_headers_seq
        FROM   dual
        ;
--
        -- 出荷依頼インターフェイスヘッダ件数カウント
        gn_sh_h_cnt := gn_sh_h_cnt + 1;
--
-- 2008/08/20 H.Itou Add Start 出荷追加_1
        lv_load_eff_chk_flag := gv_0;   -- 積載効率チェック実施フラグ ON
        ln_line_if_cnt := 0;            -- ヘッダ毎明細IF件数カウント
-- 2008/08/20 H.Itou Add End
      END IF;
--
-- 2008/08/20 H.Itou Add Start 出荷追加_1
      ln_line_if_cnt := ln_line_if_cnt + 1; -- ヘッダ毎明細IF件数カウント
-- 2008/08/20 H.Itou Add End
--
      -- =====================================================
      --  インターフェイス情報チェック   (B-4)
      -- =====================================================
      pro_interface_chk
        (
          ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
         ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
         ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- エラー確認用フラグ (B-4にてエラーの場合は、下記処理実施しない)
      IF (gv_err_flg <> gv_1) THEN
        -- =====================================================
        --  稼働日/リードタイムチェック   (B-5)
        -- =====================================================
        pro_day_time_chk
          (
            ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
-- 2008/08/20 H.Itou Add Start 出荷追加_1
      ELSE
        lv_load_eff_chk_flag := gv_1;  -- 積載効率チェック実施フラグ OFF
-- 2008/08/20 H.Itou Add End
      END IF;
--
      -- エラー確認用フラグ (B-5にてエラーの場合は、下記処理実施しない)
      IF (gv_err_flg <> gv_1) THEN
        ---------------------------------------------
        -- 受注明細アドオンID シーケンス取得       --
        ---------------------------------------------
        SELECT xxwsh_order_lines_all_s1.NEXTVAL
        INTO   gn_lines_seq
        FROM   dual;
--
        -- =====================================================
        --  明細情報マスタ存在チェック (B-6)
        -- =====================================================
        pro_item_chk
          (
            ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- エラー確認用フラグ (B-6にてエラーの場合は、下記処理実施しない)
        IF (gv_err_flg <> gv_2) THEN
          -- =====================================================
          --  物流構成存在チェック (B-7)
          -- =====================================================
          pro_xsr_chk
            (
              ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
             ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
             ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- エラー確認用フラグ (B-7にてエラーの場合は、下記処理実施しない)
        IF (gv_err_flg <> gv_2) THEN
          -- =====================================================
          --  合計重量/合計容積算出 (B-8)
          -- =====================================================
          pro_total_we_ca
            (
              ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
             ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
             ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- エラー確認用フラグ (B-8にてエラーの場合は、下記処理実施しない)
        IF (gv_err_flg <> gv_2) THEN
          -- =====================================================
          --  出荷可否チェック (B-9)
          -- =====================================================
          pro_ship_y_n_chk
            (
              ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
             ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
             ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- =====================================================
        --  受注明細アドオンレコード生成 (B-10)
        -- =====================================================
        pro_lines_create
          (
            ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- エラー確認用フラグ戻し
        IF (gv_err_flg = gv_2) THEN
          gv_err_flg := gv_0;
        END IF;
      END IF;
--
-- 2008/10/14 H.Itou Add Start 統合テスト指摘118
      gn_cut := gn_cut + 1; -- テーブルカウント
      gt_err_msg(gn_cut).err_msg  := NULL;
      gt_head_line(gn_i).dup_item_msg_seq := gn_cut; -- 品目重複メッセージ格納SEQ
-- 2008/10/14 H.Itou Add End
-- 2008/08/20 H.Itou Add Start 積載効率(重量)・積載効率(容積)・パレット最大枚数エラーメッセージ用にダミーエラーメッセージ作成。
      gn_cut := gn_cut + 1; -- テーブルカウント
      gt_err_msg(gn_cut).err_msg  := NULL;
      gt_head_line(gn_i).we_loading_msg_seq := gn_cut; -- 積載効率(重量)メッセージ格納SEQ
--
      gn_cut := gn_cut + 1; -- テーブルカウント
      gt_err_msg(gn_cut).err_msg  := NULL;
      gt_head_line(gn_i).ca_loading_msg_seq := gn_cut; -- 積載効率(容積)メッセージ格納SEQ
--
      gn_cut := gn_cut + 1; -- テーブルカウント
      gt_err_msg(gn_cut).err_msg  := NULL;
      gt_head_line(gn_i).prt_max_msg_seq := gn_cut; -- パレット最大枚数メッセージ格納SEQ
-- 2008/08/20 H.Itou Add End
--
-- 2008/08/20 H.Itou Mod Start 出荷追加_1
--      -- エラー確認用フラグ (B-5にてエラーの場合は、下記処理実施しない)
--      IF (gv_err_flg <> gv_1) THEN
--        -- =====================================================
--        --  積載効率チェック (B-11)
--        -- =====================================================
--        pro_load_eff_chk
--          (
--            ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
--           ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
--           ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
--          );
--        IF (lv_retcode = gv_status_error) THEN
--          RAISE global_process_expt;
--        END IF;
--      END IF;
--
      -- 最終レコードで、ヘッダに紐付く明細すべてにB-4エラーがない場合
      IF ((lv_load_eff_chk_flag = gv_0)
      AND (gn_i = gt_head_line.COUNT)) THEN
-- 2008/10/14 H.Itou Add Start 統合テスト指摘118
        -- =====================================================
        --  品目重複チェック (B-15)
        -- =====================================================
        pro_duplication_item_chk
          (
            iv_line_if_cnt  => ln_line_if_cnt   -- ヘッダ毎明細IFカウント
           ,ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
-- 2008/10/14 H.Itou Add End
--
        -- =====================================================
        --  積載効率チェック (B-11)
        -- =====================================================
        pro_load_eff_chk
          (
            ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
           ,iv_line_if_cnt  => ln_line_if_cnt   -- ヘッダ毎明細IFカウント
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      -- 次レコードが現在レコードのヘッダIDと異なる場合で、ヘッダに紐付く明細すべてにB-4エラーがない場合
      ELSIF ((lv_load_eff_chk_flag = gv_0)
      AND    (gt_head_line(gn_i).h_id <> gt_head_line(gn_i + 1).h_id)) THEN
-- 2008/10/14 H.Itou Add Start 統合テスト指摘118
        -- =====================================================
        --  品目重複チェック (B-15)
        -- =====================================================
        pro_duplication_item_chk
          (
            iv_line_if_cnt  => ln_line_if_cnt   -- ヘッダ毎明細IFカウント
           ,ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
-- 2008/10/14 H.Itou Add End
--
        -- =====================================================
        --  積載効率チェック (B-11)
        -- =====================================================
        pro_load_eff_chk
          (
            ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
           ,iv_line_if_cnt  => ln_line_if_cnt   -- ヘッダ毎明細IFカウント
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
-- 2008/08/20 H.Itou Mod End
--
      -- エラー確認用フラグ (B-11まででエラーの場合は、下記処理実施しない)
      IF (gv_err_flg <> gv_1) THEN
        -- =====================================================
        --  受注ヘッダアドオンレコード生成 (B-12)
        -- =====================================================
        pro_headers_create
          (
            ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        --  受注アドオン出力  (B-13)
        -- =====================================================
        pro_order_ins_del
          (
            ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
           ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
           ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- ヘッダID、受注ソース参照判定用項目更新
      gr_h_id    := gt_head_line(gn_i).h_id;
      gr_o_r_ref := gt_head_line(gn_i).o_r_ref;
--
      -- 取得したデータのステータスが拠点確定以上の場合、ヘッダIDを保持する。
      IF (gv_del_if_flg = gv_yes) THEN
        gt_del_if(gn_i) := gt_head_line(gn_i).h_id;
      END IF;
--
      -- IFテーブル削除対象フラグを初期化
      gv_del_if_flg := NULL;
--
    END LOOP headers_data_loop;
--
    -- ステータスを挿入
    IF (gt_head_line.COUNT = 0) THEN
      ov_retcode := gv_status_normal;
    ELSIF ((gv_err_sts = gv_status_warn)
    OR     (gv_err_sts = gv_status_error))
    THEN
      ov_retcode := gv_err_sts;
    END IF;
--
-- 2009/02/19 本番障害#147対応 DEL Start --
--    -- ステータスがエラーの場合は処理実施しない
--    IF (ov_retcode <> gv_status_error) THEN
-- 2009/02/19 本番障害#147対応 DEL End   --
--
-- 2009/02/19 本番障害#147対応 ADD Start --
    -- ステータスがエラーの場合はロールバックする
    IF (ov_retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
-- 2009/02/19 本番障害#147対応 ADD End   --
--
    -- =====================================================
    --  パージ処理   (B-14)
    -- =====================================================
    pro_purge_del
      (
        ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--    
-- 2009/02/19 本番障害#147対応 ADD Start --
    -- ステータスがエラーの場合はコミットする
    IF (ov_retcode = gv_status_error) THEN
      COMMIT;
    END IF;
-- 2009/02/19 本番障害#147対応 ADD End   --
--
-- 2009/02/19 本番障害#147対応 DEL Start --
--    END IF;
-- 2009/02/19 本番障害#147対応 DEL End   --
--
    -- 取得したデータのステータスが拠点確定以上のレコードをIFから消去する。
    IF (gt_del_if.COUNT > 0) THEN
-- 2008/08/20 H.Itou Add Start
      -- 拠点確定がある場合はエラー終了なのでROLLBACK
      ROLLBACK;
-- 2008/08/20 H.Itou Add End
-- 2008/08/20 H.Itou Mod Start レコードカウントは1から順番の値ではない
--      FORALL ln_j IN 1 .. gt_del_if.COUNT
      FORALL ln_j IN INDICES OF gt_del_if
-- 2008/08/20 H.Itou Mod End
        DELETE xxwsh_shipping_lines_if    xsli -- 出荷依頼インタフェース明細（アドオン）
        WHERE  xsli.header_id = gt_del_if(ln_j);
--
-- 2008/08/20 H.Itou Mod Start レコードカウントは1から順番の値ではない
--      FORALL ln_k IN 1 .. gt_del_if.COUNT
      FORALL ln_k IN INDICES OF gt_del_if
-- 2008/08/20 H.Itou Mod End
        DELETE xxwsh_shipping_headers_if  xshi -- 出荷依頼インタフェースヘッダ（アドオン）
        WHERE  xshi.header_id = gt_del_if(ln_k);
--
      COMMIT;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
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
  PROCEDURE main
    (
      errbuf        OUT VARCHAR2      --  エラー・メッセージ  --# 固定 #
     ,retcode       OUT VARCHAR2      --  リターン・コード    --# 固定 #
     ,iv_in_base    IN  VARCHAR2      --  01.入力拠点
     ,iv_jur_base   IN  VARCHAR2      --  02.管轄拠点
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
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain
      (
        iv_in_base   => iv_in_base   --  01.入力拠点
       ,iv_jur_base  => iv_jur_base  --  02.管轄拠点
       ,ov_errbuf    => lv_errbuf    -- エラー・メッセージ           --# 固定 #
       ,ov_retcode   => lv_retcode   -- リターン・コード             --# 固定 #
       ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    -----------------------------------------------
    -- 入力パラメータ出力                        --
    -----------------------------------------------
    -- 入力パラメータ「入力拠点」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11057','IN_KYOTEN',gr_param.in_base);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「管轄拠点」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11008','KYOTEN',gr_param.jur_base);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- エラーリスト出力
    IF (gt_err_msg.COUNT > 0) THEN
      -- 項目名出力
      gv_err_report := gv_name_kind      || CHR(9) || gv_name_dec       || CHR(9) ||
                       gv_name_req_no    || CHR(9) || gv_tkn_msg_ju_b   || CHR(9) ||
-- 2008/08/20 H.Itou Mod Start 結合テスト指摘#91
--                       gv_name_ship_to   || CHR(9) || gv_name_descrip   || CHR(9) ||
--                       gv_name_cust_pono || CHR(9) || gv_name_ship_date || CHR(9) ||
                       gv_name_ship_to   || CHR(9) || gv_name_ship_date || CHR(9) ||
-- 2008/08/20 H.Itou Mod End
                       gv_name_arr_date  || CHR(9) || gv_name_ship_from || CHR(9) ||
                       gv_name_item_a    || CHR(9) || gv_name_qty       || CHR(9) ||
                       gv_name_err_msg   || CHR(9) || gv_name_err_clm;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- 項目区切り線出力
      gv_err_report := gv_line || gv_line || gv_line || gv_line || gv_line || gv_line || gv_line;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- エラーリスト内容出力
      <<err_report_loop>>
      FOR i IN 1..gt_err_msg.COUNT LOOP
-- 2008/08/20 H.Itou Add Start 出荷追加_1
        -- ダミーエラーメッセージ（NULL）は出力しない
        IF (gt_err_msg(i).err_msg IS NOT NULL) THEN
-- 2008/08/20 H.Itou Add End
-- 2008/08/20 H.Itou Mod Start
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gt_err_msg(i).err_msg);
-- 2008/08/20 H.Itou Mod End
-- 2008/08/20 H.Itou Add Start
        END IF;
-- 2008/08/20 H.Itou Add End
      END LOOP err_report_loop;
--
      --区切り文字列出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    END IF;
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
      ELSIF (lv_errbuf IS NULL) THEN
        --ユーザー・エラー・メッセージのコピー
        lv_errbuf := lv_errmsg;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      --区切り文字列出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    END IF;
--
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --処理件数出力(出荷依頼インターフェイスヘッダ件数)
    gv_out_msg := xxcmn_common_pkg.get_msg( 'XXWSH'
                                           ,'APP-XXWSH-11058'
                                           ,'CNT'
                                           ,TO_CHAR(gn_sh_h_cnt)
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --処理件数出力(出荷依頼インターフェイス明細件数)
    gv_out_msg := xxcmn_common_pkg.get_msg( 'XXWSH'
                                           ,'APP-XXWSH-11059'
                                           ,'CNT'
                                           ,TO_CHAR(gt_head_line.COUNT)
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --処理件数出力(出荷依頼作成件数(依頼Ｎｏ単位))
    gv_out_msg := xxcmn_common_pkg.get_msg( 'XXWSH'
                                           ,'APP-XXWSH-11010'
                                           ,'CNT'
                                           ,TO_CHAR(gn_req_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --処理件数出力(出荷依頼作成件数(依頼明細単位))
    gv_out_msg := xxcmn_common_pkg.get_msg( 'XXWSH'
                                           ,'APP-XXWSH-11011'
                                           ,'CNT'
                                           ,TO_CHAR(gn_line_cnt)
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
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
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh400002c;
/
