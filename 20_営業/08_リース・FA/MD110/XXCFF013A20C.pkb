CREATE OR REPLACE PACKAGE BODY XXCFF013A20C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF013A20C(body)
 * Description      : FAアドオンIF
 * MD.050           : MD050_CFF_013_A20_FAアドオンIF
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                         初期処理                             (A-1)
 *  get_profile_values           プロファイル値取得                   (A-2)
 *  chk_period                   会計期間チェック                     (A-3)
 *  get_les_trn_add_data         リース取引(追加)登録データ抽出       (A-4)
 *  proc_les_trn_add_data        リース取引(追加)データ処理           (A-5)～(A-10)
 *  get_deprn_method             償却方法取得                         (A-8)
 *  insert_les_trn_add_data      リース取引(追加)登録                 (A-9)
 *  update_ctrct_line_acct_flag  リース契約明細履歴 会計IFフラグ更新  (A-10)
 *  get_les_trn_trnsf_data       リース取引(振替)登録データ抽出       (A-11)
 *  proc_les_trn_trnsf_data      リース取引(振替)データ処理           (A-12)～(A-16)
 *  lock_trnsf_data              リース取引(振替)データロック処理     (A-12)
 *  insert_les_trn_trnsf_data    リース取引(振替)登録                 (A-15)
 *  update_trnsf_data_acct_flag  リース契約明細履歴 会計IFフラグ更新  (A-16)
 *  get_deprn_ccid               減価償却費勘定CCID取得               (A-25)
 *  get_les_trn_retire_data      リース取引(解約)登録データ抽出       (A-17)
 *  insert_les_trn_ritire_data   リース取引(解約)登録                 (A-18)
 *  update_ritire_data_acct_flag リース契約明細履歴 会計IFフラグ更新  (A-19)
 *  get_les_trns_data            FAOIF登録データ抽出                  (A-20)
 *  insert_add_oif               追加OIF登録                          (A-21)
 *  insert_trnsf_oif             振替OIF登録                          (A-22)
 *  insert_retire_oif            除・売却OIF登録                      (A-23)
 *  update_les_trns_fa_if_flag   リース取引 FA連携フラグ更新          (A-24)
 *  update_lease_close_period    リース月次締め期間更新               (A-27)
 *  get_obj_hist_data            物件履歴取得                         (A-28)
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   SCS渡辺学        新規作成
 *  2008/02/23    1.1   SCS渡辺学        [障害CFF_047]除売却データ抽出条件不具合対応
 *  2009/04/23    1.2   SCS礒崎祐次      [障害T1_0759]
 *                                       ①資産カテゴリCCID取得処理における耐用年数に、
 *                                         リース期間（リース契約の支払回数/12）を設定を設定する。
 *                                       ②償却方法を取得時に、資産カテゴリ償却基準テーブルの計算月数
 *                                         を取得し、追加OIFの計算月数へ設定する。
 *  2009/05/19    1.3   SCS礒崎祐次      [障害T1_0893]
 *                                       ①リース法人税台帳で減価償却の計算が行われない。
 *  2009/05/29    1.4   SCS磯崎祐次      [障害T1_0893]追記
 *                                       ①リース取引(追加)登録時の事業供用日は
 *                                         リース開始日を設定する。
 *  2009/06/16    1.5   SCS中村祐基      [障害T1_1428]
 *                                       ①資産カテゴリCCID取得ロジックの
 *                                       パラメータ：資産勘定の値をNULL値固定に変更
 *  2009/07/15    1.6   SCS萱原伸哉      [統合テスト障害0000417]
 *                                       除・売却OIFの作成条件の変更
 *  2009/08/31    1.7   SCS渡辺学        [統合テスト障害0001058]
 *                                       統合テスト障害0000417の追加修正
 *  2012/01/16    1.8   SCSK白川         [E_本稼動_08123] 解約時のFA連携の条件に解約日を追加
 *  2016/08/03    1.9   SCSK郭           [E_本稼動_13658]自販機耐用年数変更対応
 *  2017/03/29    1.10  SCSK小路         [E_本稼動_14030]減価償却費を拠点へ振替える
 *  2018/03/29    1.11  SCSK大塚         [E_本稼動_14830]IFRSリース資産対応
 *  2018/09/07    1.12  SCSK小路         [E_本稼動_14830]IFRSリース追加対応
 *  2019/05/24    1.13  SCSK小路         [E_本稼動_15727]自販機の減価償却費の拠点振替対応
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
  --*** 会計期間チェックエラー
  chk_period_expt           EXCEPTION;
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  --*** 頻度チェックエラー
  payment_type_expt         EXCEPTION;
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- ロック(ビジー)エラー
  lock_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFF013A20C'; -- パッケージ名
--
  -- ***アプリケーション短縮名
  cv_msg_kbn_cmn   CONSTANT VARCHAR2(5) := 'XXCMN';
  cv_msg_kbn_ccp   CONSTANT VARCHAR2(5) := 'XXCCP';
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF';
--
  -- ***メッセージ名(本文)
  cv_msg_013a20_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; --プロファイル取得エラー
  cv_msg_013a20_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; --会計期間チェックエラー
  cv_msg_013a20_m_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; --ロックエラー
  cv_msg_013a20_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00101'; --償却方法取得エラー
  cv_msg_013a20_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00153'; --リース取引(追加)作成メッセージ
  cv_msg_013a20_m_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00154'; --リース取引(振替)作成メッセージ
  cv_msg_013a20_m_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00155'; --リース取引(解約)作成メッセージ
  cv_msg_013a20_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00156'; --FAOIF作成メッセージ
  cv_msg_013a20_m_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; --取得対象データ無し
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  cv_msg_013a20_m_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00284'; --頻度指定チェックエラー
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  cv_msg_013a20_m_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00285'; --成功件数メッセージ（FINリース台帳追加）
--  cv_msg_013a20_m_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00286'; --成功件数メッセージ（IFRSリース台帳追加）
--  cv_msg_013a20_m_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00287'; --成功件数メッセージ（FINリース台帳振替）
--  cv_msg_013a20_m_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00288'; --成功件数メッセージ（IFRSリース台帳振替）
--  cv_msg_013a20_m_025 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00289'; --成功件数メッセージ（FINリース台帳解約）
--  cv_msg_013a20_m_026 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00290'; --成功件数メッセージ（IFRSリース台帳解約）
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ***メッセージ名(トークン)
  cv_msg_013a20_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50076'; --XXCFF:会社コード_本社
  cv_msg_013a20_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50077'; --XXCFF:会社コード_相良会計
  cv_msg_013a20_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50078'; --XXCFF:部門コード_調整部門
  cv_msg_013a20_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50079'; --XXCFF:顧客コード_定義なし
  cv_msg_013a20_t_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50080'; --XXCFF:企業コード_定義なし
  cv_msg_013a20_t_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50081'; --XXCFF:予備1コード_定義なし
  cv_msg_013a20_t_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50082'; --XXCFF:予備2コード_定義なし
  cv_msg_013a20_t_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50083'; --XXCFF:資産カテゴリ_償却方法
  cv_msg_013a20_t_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50084'; --XXCFF:申告地_申告なし
  cv_msg_013a20_t_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50085'; --XXCFF:事業所_定義なし
  cv_msg_013a20_t_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50086'; --XXCFF:場所_定義なし
  cv_msg_013a20_t_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50087'; --XXCFF: 按分方法_月初
  cv_msg_013a20_t_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50093'; --XXCFF: 按分方法_月末
  cv_msg_013a20_t_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50094'; --リース契約明細履歴
  cv_msg_013a20_t_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50095'; --XXCFF: 本社工場区分_本社
  cv_msg_013a20_t_025 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50096'; --XXCFF: 本社工場区分_工場
  cv_msg_013a20_t_026 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50097'; --償却方法
  cv_msg_013a20_t_027 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50098'; --契約明細内部ID
  cv_msg_013a20_t_028 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50099'; --資産カテゴリCCID
  cv_msg_013a20_t_029 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50023'; --リース物件履歴
  cv_msg_013a20_t_030 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50112'; --リース取引
  cv_msg_013a20_t_031 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50142'; --リース取引（追加）情報
  cv_msg_013a20_t_032 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50143'; --リース取引（振替）情報
  cv_msg_013a20_t_033 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50144'; --リース取引（解約）情報
  cv_msg_013a20_t_034 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50145'; --FAOIF連携情報
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  cv_msg_013a20_t_035 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50287'; -- XXCFF:台帳名_FINリース台帳
  cv_msg_013a20_t_036 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50324'; -- XXCFF:台帳名_IFRSリース台帳
-- 2018/03/29 Ver1.11 Otsuka ADD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
  cv_msg_013a20_t_037 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50329'; -- XXCFF:IFRS帳簿ID
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
  -- ***トークン名
  -- プロファイル名
  cv_tkn_prof     CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type  CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period   CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_table    CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_info     CONSTANT VARCHAR2(20) := 'INFO';
  cv_tkn_get_data CONSTANT VARCHAR2(20) := 'GET_DATA';
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  cv_tkn_ls_cls   CONSTANT VARCHAR2(20) := 'LEASE_CLASS';
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ***プロファイル
--
  -- 会社コード_本社
  cv_comp_cd_itoen        CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_ITOEN';
  -- 会社コード_相良会計
  cv_comp_cd_sagara       CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_SAGARA';
  -- 部門コード_調整部門
  cv_dep_cd_chosei        CONSTANT VARCHAR2(30) := 'XXCFF1_DEP_CD_CHOSEI';
  -- 顧客コード_定義なし
  cv_ptnr_cd_dammy        CONSTANT VARCHAR2(30) := 'XXCFF1_PTNR_CD_DAMMY';
  -- 企業コード_定義なし
  cv_busi_cd_dammy        CONSTANT VARCHAR2(30) := 'XXCFF1_BUSI_CD_DAMMY';
  -- 予備1コード_定義なし
  cv_project_dammy        CONSTANT VARCHAR2(30) := 'XXCFF1_PROJECT_DAMMY';
  -- 予備2コード_定義なし
  cv_future_dammy         CONSTANT VARCHAR2(30) := 'XXCFF1_FUTURE_DAMMY';
  -- 資産カテゴリ_償却方法
  cv_cat_dprn_lease       CONSTANT VARCHAR2(30) := 'XXCFF1_CAT_DPRN_LEASE';
  -- 申告地_申告なし
  cv_dclr_place_no_report CONSTANT VARCHAR2(30) := 'XXCFF1_DCLR_PLACE_NO_REPORT';
  -- 事業所_定義なし
  cv_mng_place_dammy      CONSTANT VARCHAR2(30) := 'XXCFF1_MNG_PLACE_DAMMY';
  -- 場所_定義なし
  cv_place_dammy          CONSTANT VARCHAR2(30) := 'XXCFF1_PLACE_DAMMY';
  -- 按分方法_月初
  cv_prt_conv_cd_st       CONSTANT VARCHAR2(30) := 'XXCFF1_PRT_CONV_CD_ST';
  -- 按分方法_月末
  cv_prt_conv_cd_ed       CONSTANT VARCHAR2(30) := 'XXCFF1_PRT_CONV_CD_ED';
  -- 本社工場区分_本社
  cv_own_comp_itoen       CONSTANT VARCHAR2(30) := 'XXCFF1_OWN_COMP_ITOEN';
  -- 本社工場区分_工場
  cv_own_comp_sagara      CONSTANT VARCHAR2(30) := 'XXCFF1_OWN_COMP_SAGARA';
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  -- 台帳名_FINリース台帳
  cv_fin_lease_books      CONSTANT VARCHAR2(35) := 'XXCFF1_FIN_LEASE_BOOKS';
  -- 台帳名_IFRSリース台帳
  cv_ifrs_lease_books     CONSTANT VARCHAR2(35) := 'XXCFF1_IFRS_LEASE_BOOKS';
-- 2018/03/29 Ver1.11 Otsuka ADD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
  -- XXCFF:IFRS帳簿ID
  cv_set_of_books_id_ifrs CONSTANT VARCHAR2(35) := 'XXCFF1_IFRS_SET_OF_BKS_ID';
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
  -- ***ファイル出力
--
  -- メッセージ出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';
  -- ログ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';
--
  -- ***契約ステータス
  -- 契約
  cv_ctrt_ctrt           CONSTANT VARCHAR2(3) := '202';
  -- 情報変更
  cv_ctrt_info_change    CONSTANT VARCHAR2(3) := '209';
-- 2016/08/03 Ver.1.9 Y.Koh ADD Start
  -- 再リース
  cv_ctrt_re_lease       CONSTANT VARCHAR2(3) := '203';
-- 2016/08/03 Ver.1.9 Y.Koh ADD End
  -- 満了
  cv_ctrt_manryo         CONSTANT VARCHAR2(3) := '204';
  -- 中途解約(自己都合)
  cv_ctrt_cancel_jiko    CONSTANT VARCHAR2(3) := '206';
  -- 中途解約(保険対応)
  cv_ctrt_cancel_hoken   CONSTANT VARCHAR2(3) := '207';
  -- 中途解約(満了)
  cv_ctrt_cancel_manryo  CONSTANT VARCHAR2(3) := '208';
--
  -- ***物件ステータス
  -- 移動
  cv_obj_move        CONSTANT VARCHAR2(3) := '105';
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
  -- 物件情報変更
  cv_obj_modify      CONSTANT VARCHAR2(3) := '106';
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 0000417 2009/07/10 ADD START --
  -- 満了
  cv_obj_manryo         CONSTANT VARCHAR2(3) := '107';
  -- 中途解約(自己都合)
  cv_obj_cancel_jiko    CONSTANT VARCHAR2(3) := '110';
  -- 中途解約(保険対応)
  cv_obj_cancel_hoken   CONSTANT VARCHAR2(3) := '111';
  -- 中途解約(満了)
  cv_obj_cancel_manryo  CONSTANT VARCHAR2(3) := '112';
-- 0000417 2009/07/10 ADD END --
--
  -- ***リース種類
  cv_lease_kind_fin  CONSTANT VARCHAR2(1) := '0';  -- Finリース
  cv_lease_kind_lfin CONSTANT VARCHAR2(1) := '2';  -- 旧Finリース
--
  -- ***会計IFフラグ
  cv_if_yet  CONSTANT VARCHAR2(1) := '1';  -- 未送信
  cv_if_aft  CONSTANT VARCHAR2(1) := '2';  -- 連携済
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  cv_if_out  CONSTANT VARCHAR2(1) := '3';  -- 対象外
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ***リース区分
  cv_original  CONSTANT VARCHAR2(1) := '1';  -- 原契約
-- 2016/08/03 Ver.1.9 Y.Koh ADD Start
  cv_re_lease  CONSTANT VARCHAR2(1) := '2';  -- 再リース
-- 2016/08/03 Ver.1.9 Y.Koh ADD End
--
-- T1_0759 2009/04/23 ADD START --
  -- ***月数
  cv_months  CONSTANT NUMBER(2) := 12;  
-- T1_0759 2009/04/23 ADD END   --
--
-- 2016/08/03 Ver.1.9 Y.Koh ADD Start
  -- ***リース種別
  cv_lease_class_vd  CONSTANT VARCHAR2(2) := '11';  -- 自販機
-- 2016/08/03 Ver.1.9 Y.Koh ADD End
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
--
  -- ***取引タイプ
  cv_transaction_type_2  CONSTANT VARCHAR2(1) := '2';  -- 振替
  cv_transaction_type_4  CONSTANT VARCHAR2(1) := '4';  -- 部門振替
--
  -- ***参照タイプ
  cv_xxcff1_lease_class_check CONSTANT VARCHAR2(30) := 'XXCFF1_LEASE_CLASS_CHECK';
--
  -- ***フラグ判定用
  cv_flg_y               CONSTANT VARCHAR2(1) := 'Y';
  cv_flg_n               CONSTANT VARCHAR2(1) := 'N';
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  -- リース判定
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
  cv_lease_cls_chk1      CONSTANT VARCHAR2(1) := '1';
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
  cv_lease_cls_chk2      CONSTANT VARCHAR2(1) := '2';  -- リース判定結果
  -- 頻度
  cv_payment_type0       CONSTANT VARCHAR2(1) := '0';  -- 頻度：「月」
  cv_payment_type1       CONSTANT VARCHAR2(1) := '1';  -- 頻度：「年」
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ***バルクフェッチ用定義
  TYPE g_deprn_run_ttype             IS TABLE OF fa_deprn_periods.deprn_run%TYPE INDEX BY PLS_INTEGER;
  TYPE g_book_type_code_ttype        IS TABLE OF fa_deprn_periods.book_type_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_header_id_ttype    IS TABLE OF xxcff_contract_histories.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_id_ttype      IS TABLE OF xxcff_contract_histories.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_header_id_ttype      IS TABLE OF xxcff_contract_histories.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_history_num_ttype           IS TABLE OF xxcff_contract_histories.history_num%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_class_ttype           IS TABLE OF xxcff_contract_headers.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_kind_ttype            IS TABLE OF xxcff_contract_histories.lease_kind%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_category_ttype        IS TABLE OF xxcff_contract_histories.asset_category%TYPE INDEX BY PLS_INTEGER;
  TYPE g_comments_ttype              IS TABLE OF xxcff_contract_headers.comments%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_years_ttype         IS TABLE OF xxcff_contract_headers.payment_years%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_date_ttype         IS TABLE OF xxcff_contract_headers.contract_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_original_cost_ttype         IS TABLE OF xxcff_contract_histories.original_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_quantity_ttype              IS TABLE OF xxcff_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_department_code_ttype       IS TABLE OF xxcff_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_owner_company_ttype         IS TABLE OF xxcff_object_headers.owner_company%TYPE INDEX BY PLS_INTEGER;
  TYPE g_les_asset_acct_ttype        IS TABLE OF xxcff_lease_class_v.les_asset_acct%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_acct_ttype            IS TABLE OF xxcff_lease_class_v.deprn_acct%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_sub_acct_ttype        IS TABLE OF xxcff_lease_class_v.deprn_sub_acct%TYPE INDEX BY PLS_INTEGER;
  TYPE g_category_ccid_ttype         IS TABLE OF fa_categories.category_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_location_ccid_ttype         IS TABLE OF fa_locations.location_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_ccid_ttype            IS TABLE OF gl_code_combinations.code_combination_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_method_ttype          IS TABLE OF fa_category_book_defaults.deprn_method%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_number_ttype          IS TABLE OF fa_additions_b.asset_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment_ttype               IS TABLE OF gl_code_combinations.segment1%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_match_flag_ttype    IS TABLE OF xxcff_pay_planning.payment_match_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fa_transaction_id_ttype     IS TABLE OF xxcff_fa_transactions.fa_transaction_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_frequency_ttype     IS TABLE OF xxcff_contract_headers.payment_frequency%TYPE INDEX BY PLS_INTEGER;
  TYPE g_life_in_months_ttype        IS TABLE OF xxcff_contract_histories.life_in_months%TYPE INDEX BY PLS_INTEGER;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
  TYPE g_segment2_ttype              IS TABLE OF gl_code_combinations.segment2%TYPE INDEX BY PLS_INTEGER;
  TYPE g_transaction_type_ttype      IS TABLE OF xxcff_fa_transactions.transaction_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_customer_code_ttype         IS TABLE OF xxcff_object_headers.customer_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_vd_cust_flag_ttype          IS TABLE OF xxcff_lease_class_v.vd_cust_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_dept_tran_flg_ttype         IS TABLE OF fnd_lookup_values.attribute1%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment5_ttype              IS TABLE OF gl_code_combinations.segment5%TYPE INDEX BY PLS_INTEGER;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  TYPE g_lease_type_ttype            IS TABLE OF xxcff_contract_headers.lease_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_type_ttype          IS TABLE OF xxcff_contract_headers.payment_type%TYPE INDEX BY PLS_INTEGER;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  TYPE g_fin_coop_ttype              IS TABLE OF fnd_lookup_values.attribute4%TYPE INDEX BY PLS_INTEGER;
--  TYPE g_ifrs_coop_ttype             IS TABLE OF fnd_lookup_values.attribute5%TYPE INDEX BY PLS_INTEGER;
--  TYPE g_lease_cls_chk_ttype         IS TABLE OF fnd_lookup_values.attribute7%TYPE INDEX BY PLS_INTEGER;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
  TYPE g_fully_retired_ttype         IS TABLE OF fa_books.period_counter_fully_retired%TYPE INDEX BY PLS_INTEGER;
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ***バルクフェッチ用定義
  g_deprn_run_tab                       g_deprn_run_ttype;
  g_book_type_code_tab                  g_book_type_code_ttype;
  g_contract_header_id_tab              g_contract_header_id_ttype;
  g_contract_line_id_tab                g_contract_line_id_ttype;
  g_object_header_id_tab                g_object_header_id_ttype;
  g_history_num_tab                     g_history_num_ttype;
  g_lease_class_tab                     g_lease_class_ttype;
  g_lease_kind_tab                      g_lease_kind_ttype;
  g_asset_category_tab                  g_asset_category_ttype;
  g_comments_tab                        g_comments_ttype;
  g_payment_years_tab                   g_payment_years_ttype;
  g_contract_date_tab                   g_contract_date_ttype;
  g_original_cost_tab                   g_original_cost_ttype;
  g_quantity_tab                        g_quantity_ttype;
  g_department_code_tab                 g_department_code_ttype;
  g_owner_company_tab                   g_owner_company_ttype;
  g_les_asset_acct_tab                  g_les_asset_acct_ttype;
  g_deprn_acct_tab                      g_deprn_acct_ttype;
  g_deprn_sub_acct_tab                  g_deprn_sub_acct_ttype;
  g_category_ccid_tab                   g_category_ccid_ttype;
  g_location_ccid_tab                   g_location_ccid_ttype;
  g_deprn_ccid_tab                      g_deprn_ccid_ttype;
  g_deprn_method_tab                    g_deprn_method_ttype;
  g_asset_number_tab                    g_asset_number_ttype;
  g_trnsf_from_comp_cd_tab              g_segment_ttype;
  g_trnsf_to_comp_cd_tab                g_segment_ttype;
  g_payment_match_flag_tab              g_payment_match_flag_ttype;
  g_fa_transaction_id_tab               g_fa_transaction_id_ttype;
  g_payment_frequency_tab               g_payment_frequency_ttype;
  g_life_in_months_tab                  g_life_in_months_ttype;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
  g_trnsf_from_dep_cd_tab               g_segment2_ttype;
  g_transaction_type_tab                g_transaction_type_ttype;
  g_customer_code_tab                   g_customer_code_ttype;
  g_vd_cust_flag_tab                    g_vd_cust_flag_ttype;
  g_dept_tran_flg_tab                   g_dept_tran_flg_ttype;
  g_trnsf_from_cust_cd_tab              g_segment5_ttype;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  g_lease_type_tab                      g_lease_type_ttype;
  g_payment_type_tab                    g_payment_type_ttype;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  g_fin_coop_tab                        g_fin_coop_ttype;
--  g_ifrs_coop_tab                       g_ifrs_coop_ttype;
--  g_lease_cls_chk_tab                   g_lease_cls_chk_ttype;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
  g_fully_retired_tab                   g_fully_retired_ttype;
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ***処理件数
  -- リース取引(追加)登録処理における件数
  gn_les_add_target_cnt    NUMBER;     -- 対象件数
  gn_les_add_normal_cnt    NUMBER;     -- 正常件数
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  gn_les_add_ifrs_cnt      NUMBER;     -- 正常件数(IFRS)
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
  gn_les_add_error_cnt     NUMBER;     -- エラー件数
  -- リース取引(振替)登録処理における件数
  gn_les_trnsf_target_cnt  NUMBER;     -- 対象件数
  gn_les_trnsf_normal_cnt  NUMBER;     -- 正常件数
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  gn_les_trnsf_ifrs_cnt    NUMBER;     -- 正常件数(IFRS)
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
  gn_les_trnsf_error_cnt   NUMBER;     -- エラー件数
  -- リース取引(解約)登録処理における件数
  gn_les_retire_target_cnt NUMBER;     -- 対象件数
  gn_les_retire_normal_cnt NUMBER;     -- 正常件数
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  gn_les_retire_ifrs_cnt   NUMBER;     -- 正常件数(IFRS)
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
  gn_les_retire_error_cnt  NUMBER;     -- エラー件数
  -- FAOIF登録処理における件数
  gn_fa_oif_target_cnt     NUMBER;     -- 対象件数
  gn_fa_oif_error_cnt      NUMBER;     -- エラー件数
  -- 追加OIF登録件数
  gn_add_oif_ins_cnt       NUMBER;
  -- 振替OIF登録件数
  gn_trnsf_oif_ins_cnt     NUMBER;
  -- 解約OIF登録件数
  gn_retire_oif_ins_cnt    NUMBER;
--
  -- 初期値情報
  g_init_rec xxcff_common1_pkg.init_rtype;
--
  -- パラメータ会計期間名
  gv_period_name VARCHAR2(100);
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
  -- パラメータ台帳名
  gv_book_type_code VARCHAR2(100);
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
  -- 資産カテゴリCCID
  gt_category_id  fa_categories.category_id%TYPE;
  -- 事業所CCID
  gt_location_id  fa_locations.location_id%TYPE;
--
  -- ***プロファイル値
  -- 会社コード_本社
  gv_comp_cd_itoen         VARCHAR2(100);
  -- 会社コード_相良会計
  gv_comp_cd_sagara        VARCHAR2(100);
  -- 部門コード_調整部門
  gv_dep_cd_chosei         VARCHAR2(100);
  -- 顧客コード_定義なし
  gv_ptnr_cd_dammy         VARCHAR2(100);
  -- 企業コード_定義なし
  gv_busi_cd_dammy         VARCHAR2(100);
  -- 予備1コード_定義なし
  gv_project_dammy         VARCHAR2(100);
  -- 予備2コード_定義なし
  gv_future_dammy          VARCHAR2(100);
  -- 資産カテゴリ_償却方法
  gv_cat_dprn_lease        VARCHAR2(100);
  -- 申告地_申告なし
  gv_dclr_place_no_report  VARCHAR2(100);
  -- 事業所_定義なし
  gv_mng_place_dammy       VARCHAR2(100);
  -- 場所_定義なし
  gv_place_dammy           VARCHAR2(100);
  -- 按分方法_月初
  gv_prt_conv_cd_st        VARCHAR2(100);
  -- 按分方法_月末
  gv_prt_conv_cd_ed        VARCHAR2(100);
  -- 本社工場区分_本社
  gv_own_comp_itoen        VARCHAR2(100);
  -- 本社工場区分_工場
  gv_own_comp_sagara       VARCHAR2(100);
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  -- 台帳名_FINリース台帳
  gv_fin_lease_books       VARCHAR2(100);
  -- 台帳名_IFRSリース台帳
  gv_ifrs_lease_books      VARCHAR2(100);
-- 2018/03/29 Ver1.11 Otsuka ADD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
  -- XXCFF:IFRS帳簿ID
  gn_set_of_books_id_ifrs  NUMBER;
  -- リース判定処理
  gv_lease_class_att7      VARCHAR2(1);
  -- リース種類
  gv_lease_kind            VARCHAR2(1);
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
  -- セグメント値配列(EBS標準関数fnd_flex_ext用)
  g_segments_tab  fnd_flex_ext.segmentarray;
--
  /**********************************************************************************
   * Procedure Name   : delete_collections
   * Description      : コレクション削除
   ***********************************************************************************/
  PROCEDURE delete_collections(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_collections'; -- プログラム名
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
    --コレクション結合配列の削除
    g_deprn_run_tab.DELETE;
    g_book_type_code_tab.DELETE;
    g_contract_header_id_tab.DELETE;
    g_contract_line_id_tab.DELETE;
    g_object_header_id_tab.DELETE;
    g_history_num_tab.DELETE;
    g_lease_class_tab.DELETE;
    g_lease_kind_tab.DELETE;
    g_asset_category_tab.DELETE;
    g_comments_tab.DELETE;
    g_payment_years_tab.DELETE;
    g_contract_date_tab.DELETE;
    g_original_cost_tab.DELETE;
    g_quantity_tab.DELETE;
    g_department_code_tab.DELETE;
    g_owner_company_tab.DELETE;
    g_les_asset_acct_tab.DELETE;
    g_deprn_acct_tab.DELETE;
    g_deprn_sub_acct_tab.DELETE;
    g_category_ccid_tab.DELETE;
    g_location_ccid_tab.DELETE;
    g_deprn_ccid_tab.DELETE;
    g_deprn_method_tab.DELETE;
    g_asset_number_tab.DELETE;
    g_trnsf_from_comp_cd_tab.DELETE;
    g_trnsf_to_comp_cd_tab.DELETE;
    g_payment_match_flag_tab.DELETE;
    g_fa_transaction_id_tab.DELETE;
    g_payment_frequency_tab.DELETE;
    g_life_in_months_tab.DELETE;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
    g_trnsf_from_dep_cd_tab.DELETE;
    g_transaction_type_tab.DELETE;
    g_customer_code_tab.DELETE;
    g_trnsf_from_cust_cd_tab.DELETE;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2018/03/29 Ver1.11 Otsuka ADD Start
    g_lease_type_tab.DELETE;
    g_payment_type_tab.DELETE;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    g_fin_coop_tab.DELETE;
--    g_ifrs_coop_tab.DELETE;
--    g_lease_cls_chk_tab.DELETE;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
    g_fully_retired_tab.DELETE;
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_collections;
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
  /**********************************************************************************
   * Procedure Name   : get_obj_hist_data
   * Description      : 物件履歴取得 (A-28)
   ***********************************************************************************/
  PROCEDURE get_obj_hist_data(
     it_object_header_id  IN  xxcff_object_headers.object_header_id%TYPE    -- 1.物件ID
    ,ot_m_owner_company   OUT xxcff_object_histories.m_owner_company%TYPE   -- 2.移動元本社/工場
    ,ot_m_department_code OUT xxcff_object_histories.m_department_code%TYPE -- 3.移動元管理部門
    ,ot_customer_code     OUT xxcff_object_histories.customer_code%TYPE     -- 4.修正前元顧客コード
    ,ov_errbuf            OUT VARCHAR2                                      --   エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT VARCHAR2                                      --   リターン・コード             --# 固定 #
    ,ov_errmsg            OUT VARCHAR2)                                     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_obj_hist_data'; -- プログラム名
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
      --リース物件履歴が取得できる場合はリース物件履歴の移動元管理部門、移動元本社／工場を設定する。
      BEGIN
        SELECT   xoh1.m_department_code  m_department_code  -- 移動元管理部門
                ,xoh1.m_owner_company    m_owner_company    -- 移動元本社／工場
        INTO     ot_m_department_code
                ,ot_m_owner_company
        FROM     (SELECT xoh.m_department_code  m_department_code
                        ,xoh.m_owner_company    m_owner_company
                  FROM   xxcff_object_histories xoh
                  WHERE  xoh.object_header_id =  it_object_header_id
                  AND    xoh.accounting_date  >  LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
                  AND    xoh.object_status    =  cv_obj_move
                  ORDER BY xoh.creation_date ASC
                 ) xoh1
        WHERE    rownum = 1;
      --該当データが存在しない場合はNULLを設定する。
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ot_m_department_code := NULL;
          ot_m_owner_company   := NULL;
      END;
--
      --リース物件履歴が取得できる場合はリース物件履歴の顧客コードを設定する。
      BEGIN
        SELECT   xoh1.customer_code  customer_code  -- 顧客コード
        INTO     ot_customer_code
        FROM     (SELECT xoh.customer_code  customer_code
                  FROM   xxcff_object_histories xoh
                  WHERE  xoh.object_header_id =  it_object_header_id
                  AND    xoh.accounting_date  <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
                  AND    xoh.object_status    =  cv_obj_modify
                  ORDER BY xoh.creation_date DESC
                 ) xoh1
        WHERE    rownum = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ot_customer_code := NULL;
      END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_obj_hist_data;
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD Start
  /**********************************************************************************
   * Procedure Name   : update_lease_close_period
   * Description      : リース月次締め期間更新 (A-27)
   ***********************************************************************************/
  PROCEDURE update_lease_close_period(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_lease_close_period'; -- プログラム名
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
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    lt_set_of_books_id xxcff_lease_closed_periods.set_of_books_id%TYPE;  -- 帳簿ID
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
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
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    -- IFRSリース台帳の場合
    IF (gv_book_type_code = gv_ifrs_lease_books) THEN
      lt_set_of_books_id := gn_set_of_books_id_ifrs;
    -- IFRSリース台帳以外の場合
    ELSE
      lt_set_of_books_id := g_init_rec.set_of_books_id;
    END IF;
--
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
    UPDATE xxcff_lease_closed_periods
    SET
           period_name            = gv_period_name            -- 会計期間
          ,last_updated_by        = cn_last_updated_by        -- 最終更新者
          ,last_update_date       = cd_last_update_date       -- 最終更新日
          ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
          ,request_id             = cn_request_id             -- 要求ID
          ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
          ,program_id             = cn_program_id             -- コンカレントプログラムID
          ,program_update_date    = cd_program_update_date    -- プログラム更新日
    WHERE
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--           set_of_books_id        = g_init_rec.set_of_books_id
           set_of_books_id        = lt_set_of_books_id
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
    ;
--
    -- メイン処理前にリース月次締め期間の更新を確定
    COMMIT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_lease_close_period;
--
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD End
  /**********************************************************************************
   * Procedure Name   : update_les_trns_fa_if_flag
   * Description      : リース取引 FA連携フラグ更新 (A-24)
   ***********************************************************************************/
  PROCEDURE update_les_trns_fa_if_flag(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_les_trns_fa_if_flag'; -- プログラム名
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
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_fa_transaction_id_tab.COUNT
      UPDATE xxcff_fa_transactions
      SET
             fa_if_flag             = cv_if_aft                 -- FA連携フラグ 
            ,fa_if_date             = g_init_rec.process_date   -- 計上日
            ,last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,last_update_date       = cd_last_update_date       -- 最終更新日
            ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,request_id             = cn_request_id             -- 要求ID
            ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
            ,program_id             = cn_program_id             -- コンカレントプログラムID
            ,program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE
             fa_transaction_id      = g_fa_transaction_id_tab(ln_loop_cnt)
-- 2018/03/29 Ver1.11 Otsuka ADD Start
        AND  fa_if_flag             = cv_if_yet
-- 2018/03/29 Ver1.11 Otsuka ADD End
      ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_les_trns_fa_if_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_retire_oif
   * Description      : 除・売却OIF登録 (A-23)
   ***********************************************************************************/
  PROCEDURE insert_retire_oif(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_retire_oif'; -- プログラム名
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
    INSERT INTO xx01_retire_oif(
      retire_oif_id                   -- RETIRE_OIF_ID
     ,book_type_code                  -- 台帳名
     ,asset_number                    -- 資産番号
     ,created_by                      -- 作成者
     ,creation_date                   -- 作成日
     ,last_updated_by                 -- 最終更新者
     ,last_update_date                -- 最終更新日
     ,last_update_login               -- 最終更新ﾛｸﾞｲﾝ
     ,request_id                      -- ﾘｸｴｽﾄID
     ,program_application_id          -- ｱﾌﾟﾘｹｰｼｮﾝID
     ,program_id                      -- ﾌﾟﾛｸﾞﾗﾑID
     ,program_update_date             -- ﾌﾟﾛｸﾞﾗﾑ最終更新日
     ,date_retired                    -- 除･売却日
     ,posting_flag                    -- 転記ﾁｪｯｸﾌﾗｸﾞ
     ,status                          -- ｽﾃｰﾀｽ
     ,cost_retired                    -- 除･売却取得価格
     ,proceeds_of_sale                -- 売却価額
     ,cost_of_removal                 -- 撤去費用
     ,retirement_prorate_convention   -- 除･売却年度償却
    )
    SELECT
      xx01_retire_oif_s.NEXTVAL           -- ID
     ,xxcff_fa_trn.book_type_code         -- 台帳
     ,xxcff_fa_trn.asset_number           -- 資産番号
     ,cn_created_by                       -- 作成者ID
     ,cd_creation_date                    -- 作成日
     ,cn_last_updated_by                  -- 最終更新者
     ,cd_last_update_date                 -- 最終更新日
     ,cn_last_update_login                -- 最終更新ログインID
     ,cn_request_id                       -- リクエストID
     ,cn_program_application_id           -- アプリケーションID
     ,cn_program_id                       -- プログラムID
     ,cd_program_update_date              -- プログラム最終更新日
     ,xxcff_fa_trn.retirement_date        -- 除･売却日
     ,'Y'                                 -- 転記チェックフラグ
     ,'PENDING'                           -- ステータス
     ,xxcff_fa_trn.cost_retired           -- 除･売却取得価格
     ,0                                   -- 売却価額
     ,0                                   -- 撤去費用
     ,xxcff_fa_trn.ret_prorate_convention -- 除･売却年度償却
    FROM
          xxcff_fa_transactions  xxcff_fa_trn
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
      AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
      AND xxcff_fa_trn.transaction_type = 3 -- 解約
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
      AND xxcff_fa_trn.book_type_code   = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
    ;
--
    -- 解約OIF登録件数カウント
    gn_retire_oif_ins_cnt := SQL%ROWCOUNT;
--
-- T1_0893 2009/05/19 ADD START --
-- リース資産台帳の場合はリース法人税のデータも作成する。
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--    INSERT INTO xx01_retire_oif(
--      retire_oif_id                   -- RETIRE_OIF_ID
--     ,book_type_code                  -- 台帳名
--     ,asset_number                    -- 資産番号
--     ,created_by                      -- 作成者
--     ,creation_date                   -- 作成日
--     ,last_updated_by                 -- 最終更新者
--     ,last_update_date                -- 最終更新日
--     ,last_update_login               -- 最終更新ﾛｸﾞｲﾝ
--     ,request_id                      -- ﾘｸｴｽﾄID
--     ,program_application_id          -- ｱﾌﾟﾘｹｰｼｮﾝID
--     ,program_id                      -- ﾌﾟﾛｸﾞﾗﾑID
--     ,program_update_date             -- ﾌﾟﾛｸﾞﾗﾑ最終更新日
--     ,date_retired                    -- 除･売却日
--     ,posting_flag                    -- 転記ﾁｪｯｸﾌﾗｸﾞ
--     ,status                          -- ｽﾃｰﾀｽ
--     ,cost_retired                    -- 除･売却取得価格
--     ,proceeds_of_sale                -- 売却価額
--     ,cost_of_removal                 -- 撤去費用
--     ,retirement_prorate_convention   -- 除･売却年度償却
--    )
--    SELECT
--      xx01_retire_oif_s.NEXTVAL           -- ID
--     ,xlkv.book_type_code_tax             -- 台帳
--     ,xxcff_fa_trn.asset_number           -- 資産番号
--     ,cn_created_by                       -- 作成者ID
--     ,cd_creation_date                    -- 作成日
--     ,cn_last_updated_by                  -- 最終更新者
--     ,cd_last_update_date                 -- 最終更新日
--     ,cn_last_update_login                -- 最終更新ログインID
--     ,cn_request_id                       -- リクエストID
--     ,cn_program_application_id           -- アプリケーションID
--     ,cn_program_id                       -- プログラムID
--     ,cd_program_update_date              -- プログラム最終更新日
--     ,xxcff_fa_trn.retirement_date        -- 除･売却日
--     ,'Y'                                 -- 転記チェックフラグ
--     ,'PENDING'                           -- ステータス
--     ,xxcff_fa_trn.cost_retired           -- 除･売却取得価格
--     ,0                                   -- 売却価額
--     ,0                                   -- 撤去費用
--     ,xxcff_fa_trn.ret_prorate_convention -- 除･売却年度償却
--    FROM
--          xxcff_fa_transactions  xxcff_fa_trn
--         ,xxcff_contract_lines   xxcff_co_line
--         ,xxcff_lease_kind_v     xlkv
--    WHERE
--          xxcff_fa_trn.period_name        = gv_period_name
--      AND xxcff_fa_trn.fa_if_flag         = cv_if_yet
--      AND xxcff_fa_trn.transaction_type   = 3                     -- 解約
--      AND xxcff_fa_trn.contract_header_id = xxcff_co_line.contract_header_id
--      AND xxcff_fa_trn.contract_line_id   = xxcff_co_line.contract_line_id
--      AND xxcff_co_line.lease_kind        = xlkv.lease_kind_code  -- finリース 
--      AND xlkv.lease_kind_code            = cv_lease_kind_fin     -- finリース
--    ;
--
--    -- 解約OIF登録件数カウント
--    gn_retire_oif_ins_cnt := gn_retire_oif_ins_cnt + SQL%ROWCOUNT;
    IF ( gv_book_type_code = gv_fin_lease_books ) THEN
      INSERT INTO xx01_retire_oif(
        retire_oif_id                   -- RETIRE_OIF_ID
       ,book_type_code                  -- 台帳名
       ,asset_number                    -- 資産番号
       ,created_by                      -- 作成者
       ,creation_date                   -- 作成日
       ,last_updated_by                 -- 最終更新者
       ,last_update_date                -- 最終更新日
       ,last_update_login               -- 最終更新ﾛｸﾞｲﾝ
       ,request_id                      -- ﾘｸｴｽﾄID
       ,program_application_id          -- ｱﾌﾟﾘｹｰｼｮﾝID
       ,program_id                      -- ﾌﾟﾛｸﾞﾗﾑID
       ,program_update_date             -- ﾌﾟﾛｸﾞﾗﾑ最終更新日
       ,date_retired                    -- 除･売却日
       ,posting_flag                    -- 転記ﾁｪｯｸﾌﾗｸﾞ
       ,status                          -- ｽﾃｰﾀｽ
       ,cost_retired                    -- 除･売却取得価格
       ,proceeds_of_sale                -- 売却価額
       ,cost_of_removal                 -- 撤去費用
       ,retirement_prorate_convention   -- 除･売却年度償却
      )
      SELECT
        xx01_retire_oif_s.NEXTVAL           -- ID
       ,xlkv.book_type_code_tax             -- 台帳
       ,xxcff_fa_trn.asset_number           -- 資産番号
       ,cn_created_by                       -- 作成者ID
       ,cd_creation_date                    -- 作成日
       ,cn_last_updated_by                  -- 最終更新者
       ,cd_last_update_date                 -- 最終更新日
       ,cn_last_update_login                -- 最終更新ログインID
       ,cn_request_id                       -- リクエストID
       ,cn_program_application_id           -- アプリケーションID
       ,cn_program_id                       -- プログラムID
       ,cd_program_update_date              -- プログラム最終更新日
       ,xxcff_fa_trn.retirement_date        -- 除･売却日
       ,'Y'                                 -- 転記チェックフラグ
       ,'PENDING'                           -- ステータス
       ,xxcff_fa_trn.cost_retired           -- 除･売却取得価格
       ,0                                   -- 売却価額
       ,0                                   -- 撤去費用
       ,xxcff_fa_trn.ret_prorate_convention -- 除･売却年度償却
      FROM
            xxcff_fa_transactions  xxcff_fa_trn
           ,xxcff_contract_lines   xxcff_co_line
           ,xxcff_lease_kind_v     xlkv
      WHERE
            xxcff_fa_trn.period_name        = gv_period_name
        AND xxcff_fa_trn.fa_if_flag         = cv_if_yet
        AND xxcff_fa_trn.transaction_type   = 3                     -- 解約
        AND xxcff_fa_trn.book_type_code     = gv_book_type_code     -- FINリース台帳
        AND xxcff_fa_trn.contract_header_id = xxcff_co_line.contract_header_id
        AND xxcff_fa_trn.contract_line_id   = xxcff_co_line.contract_line_id
        AND xxcff_co_line.lease_kind        = xlkv.lease_kind_code  -- finリース 
        AND xlkv.lease_kind_code            = cv_lease_kind_fin     -- finリース
      ;
--
      -- 解約OIF登録件数カウント
      gn_retire_oif_ins_cnt := gn_retire_oif_ins_cnt + SQL%ROWCOUNT;
--
    END IF;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
--
-- T1_0893 2009/05/19 ADD END   --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_retire_oif;
--
  /**********************************************************************************
   * Procedure Name   : insert_trnsf_oif
   * Description      : 振替OIF登録 (A-22)
   ***********************************************************************************/
  PROCEDURE insert_trnsf_oif(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_trnsf_oif'; -- プログラム名
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
    INSERT INTO xx01_transfer_oif(
      transfer_oif_id           -- ID
     ,book_type_code            -- 台帳名
     ,asset_number              -- 資産番号
     ,created_by                -- 作成者
     ,creation_date             -- 作成日
     ,last_updated_by           -- 最終更新者
     ,last_update_date          -- 最終更新日
     ,last_update_login         -- 最終更新ログインID
     ,request_id                -- リクエストID
     ,program_application_id    -- アプリケーションID
     ,program_id                -- プログラムID
     ,program_update_date       -- プログラム最終更新日
     ,transaction_date_entered  -- 振替日
     ,transaction_units         -- 単位変更
     ,posting_flag              -- 転記チェックフラグ
     ,status                    -- ステータス
     ,segment1                  -- 減価償却費勘定セグメント-会社
     ,segment2                  -- 減価償却費勘定セグメント-部門
     ,segment3                  -- 減価償却費勘定セグメント-勘定科目
     ,segment4                  -- 減価償却費勘定セグメント-補助科目
     ,segment5                  -- 減価償却費勘定セグメント-顧客
     ,segment6                  -- 減価償却費勘定セグメント-企業
     ,segment7                  -- 減価償却費勘定セグメント-予備1
     ,segment8                  -- 減価償却費勘定セグメント-予備2
     ,loc_segment1              -- 申告地
     ,loc_segment2              -- 管理部門
     ,loc_segment3              -- 事業所
     ,loc_segment4              -- 場所
     ,loc_segment5              -- 本社工場区分
    )
    SELECT
      xx01_transfer_oif_s.NEXTVAL         -- ID
     ,xxcff_fa_trn.book_type_code         -- 台帳
     ,xxcff_fa_trn.asset_number           -- 資産番号
     ,cn_created_by                       -- 作成者ID
     ,cd_creation_date                    -- 作成日
     ,cn_last_updated_by                  -- 最終更新者
     ,cd_last_update_date                 -- 最終更新日
     ,cn_last_update_login                -- 最終更新ログインID
     ,cn_request_id                       -- リクエストID
     ,cn_program_application_id           -- アプリケーションID
     ,cn_program_id                       -- プログラムID
     ,cd_program_update_date              -- プログラム最終更新日
     ,xxcff_fa_trn.transfer_date          -- 振替日
     ,xxcff_fa_trn.quantity               -- 単位変更(数量)
     ,'Y'                                 -- 転記チェックフラグ
     ,'PENDING'                           -- ステータス
     ,xxcff_fa_trn.dprn_company_code      -- 減価償却費勘定セグメント-会社
     ,xxcff_fa_trn.dprn_department_code   -- 減価償却費勘定セグメント-部門
     ,xxcff_fa_trn.dprn_account_code      -- 減価償却費勘定セグメント-勘定科目
     ,xxcff_fa_trn.dprn_sub_account_code  -- 減価償却費勘定セグメント-補助科目
     ,xxcff_fa_trn.dprn_customer_code     -- 減価償却費勘定セグメント-顧客
     ,xxcff_fa_trn.dprn_enterprise_code   -- 減価償却費勘定セグメント-企業
     ,xxcff_fa_trn.dprn_reserve_1         -- 減価償却費勘定セグメント-予備1
     ,xxcff_fa_trn.dprn_reserve_2         -- 減価償却費勘定セグメント-予備2
     ,xxcff_fa_trn.dclr_place             -- 申告地
     ,xxcff_fa_trn.department_code        -- 管理部門
     ,xxcff_fa_trn.location_name          -- 事業所
     ,xxcff_fa_trn.location_place         -- 場所
     ,xxcff_fa_trn.owner_company          -- 本社工場区分
    FROM
          xxcff_fa_transactions  xxcff_fa_trn
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
      AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--      AND xxcff_fa_trn.transaction_type = 2              -- 振替
      AND xxcff_fa_trn.transaction_type IN (cv_transaction_type_2 ,cv_transaction_type_4)              -- 振替、修正
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
      AND xxcff_fa_trn.book_type_code   = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
    ;
--
    -- 振替OIF登録件数カウント
    gn_trnsf_oif_ins_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_trnsf_oif;
--
  /**********************************************************************************
   * Procedure Name   : insert_add_oif
   * Description      : 追加OIF登録 (A-21)
   ***********************************************************************************/
  PROCEDURE insert_add_oif(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_add_oif'; -- プログラム名
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
    INSERT INTO fa_mass_additions(
       mass_addition_id              -- ID
      ,description                   -- 摘要
      ,asset_category_id             -- 資産カテゴリCCID
      ,book_type_code                -- 台帳
      ,date_placed_in_service        -- 事業供用日
      ,fixed_assets_cost             -- 取得価額
      ,payables_units                -- AP数量
      ,fixed_assets_units            -- 資産数量
      ,expense_code_combination_id   -- 減価償却費勘定CCID
      ,location_id                   -- 事業所フレックスフィールドCCID
      ,last_update_date              -- 最終更新日
      ,last_updated_by               -- 最終更新者
      ,posting_status                -- 転記ステータス
      ,queue_name                    -- キュー名
      ,payables_cost                 -- 資産当初取得価額
      ,depreciate_flag               -- 償却費計上フラグ
      ,asset_type                    -- 資産タイプ
      ,created_by                    -- 作成者ID
      ,creation_date                 -- 作成日
      ,last_update_login             -- 最終更新ログインID
      ,attribute10                   -- リース契約明細内部ID
      ,deprn_method_code             -- 償却方法
      ,life_in_months                -- 計算月数
    )
    SELECT
      fa_mass_additions_s.NEXTVAL              -- ID
      ,xxcff_fa_trn.description                -- 摘要
      ,xxcff_fa_trn.category_id                -- 資産カテゴリCCID
      ,xxcff_fa_trn.book_type_code             -- 台帳
      ,xxcff_fa_trn.date_placed_in_service     -- 事業供用日
      ,xxcff_fa_trn.original_cost              -- 取得価額
      ,xxcff_fa_trn.quantity                   -- AP数量
      ,xxcff_fa_trn.quantity                   -- 資産数量
      ,xxcff_fa_trn.dprn_code_combination_id   -- 減価償却費勘定CCID
      ,xxcff_fa_trn.location_id                -- 事業所フレックスフィールドCCID
      ,cd_last_update_date                     -- 最終更新日
      ,cn_last_updated_by                      -- 最終更新者
      ,'POST'                                  -- 転記ステータス
      ,'POST'                                  -- キュー名
      ,xxcff_fa_trn.original_cost              -- 資産当初取得価額
      ,'YES'                                   -- 償却費計上フラグ
      ,'CAPITALIZED'                           -- 資産タイプ
      ,cn_created_by                           -- 作成者ID
      ,cd_creation_date                        -- 作成日
      ,cn_last_update_login                    -- 最終更新ログインID
      ,xxcff_fa_trn.contract_line_id           -- リース契約明細内部ID
      ,xxcff_fa_trn.deprn_method               -- 償却方法
      ,xxcff_fa_trn.payment_frequency          -- 計算月数(支払回数)
    FROM
          xxcff_fa_transactions  xxcff_fa_trn
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
      AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
      AND xxcff_fa_trn.transaction_type = 1         -- 追加
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
      AND xxcff_fa_trn.book_type_code   = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
    ;
--
    -- 追加OIF登録件数カウント
    gn_add_oif_ins_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_add_oif;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trns_data
   * Description      : FAOIF登録データ抽出 (A-20)
   ***********************************************************************************/
  PROCEDURE get_les_trns_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trns_data'; -- プログラム名
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース取引カーソル
    CURSOR les_trns_cur
    IS
      SELECT
             xxcff_fa_trn.fa_transaction_id  AS fa_transaction_id  -- リース取引内部ID
      FROM
            xxcff_fa_transactions   xxcff_fa_trn    -- リース取引
      WHERE
            xxcff_fa_trn.period_name      = gv_period_name
        AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
        AND xxcff_fa_trn.book_type_code   = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
        FOR UPDATE OF xxcff_fa_trn.fa_transaction_id
        NOWAIT
      ;
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
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN les_trns_cur;
    -- データの一括取得
    FETCH les_trns_cur
    BULK COLLECT INTO  g_fa_transaction_id_tab -- リース取引内部ID
    ;
    -- 対象件数カウント
    gn_fa_oif_target_cnt := g_fa_transaction_id_tab.COUNT;
    -- カーソルクローズ
    CLOSE les_trns_cur;
--
    IF ( gn_fa_oif_target_cnt = 0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_013a20_t_034) -- FAOIF連携情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      -- カーソルクローズ
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_013a20_m_012  -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,cv_msg_013a20_t_030) -- リース取引
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_les_trns_data;
--
  /**********************************************************************************
   * Procedure Name   : update_ritire_data_acct_flag
   * Description      : リース契約明細履歴 会計IFフラグ更新 (A-19)
   ***********************************************************************************/
  PROCEDURE update_ritire_data_acct_flag(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ritire_data_acct_flag'; -- プログラム名
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
      <<update_loop>>
      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
        UPDATE xxcff_contract_histories
        SET
               accounting_if_flag     = cv_if_aft                 -- 会計ifフラグ 2(連携済)
              ,last_updated_by        = cn_last_updated_by        -- 最終更新者
              ,last_update_date       = cd_last_update_date       -- 最終更新日
              ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
              ,request_id             = cn_request_id             -- 要求ID
              ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
              ,program_id             = cn_program_id             -- コンカレントプログラムID
              ,program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE
               contract_line_id = g_contract_line_id_tab(ln_loop_cnt)
          AND  history_num      = g_history_num_tab(ln_loop_cnt)
        ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_ritire_data_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_les_trn_ritire_data
   * Description      : リース取引(解約)登録 (A-18)
   ***********************************************************************************/
  PROCEDURE insert_les_trn_ritire_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_les_trn_ritire_data'; -- プログラム名
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
    IF (gn_les_retire_target_cnt > 0) THEN
--
      <<inert_loop>>
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
      FOR ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT LOOP
-- 2018/03/29 Ver1.11 Otsuka MOD End
        INSERT INTO xxcff_fa_transactions (
           fa_transaction_id                 -- リース取引内部ID
          ,contract_header_id                -- 契約内部ID
          ,contract_line_id                  -- 契約明細内部ID
          ,object_header_id                  -- 物件内部ID
          ,period_name                       -- 会計期間
          ,transaction_type                  -- 取引タイプ
          ,book_type_code                    -- 資産台帳名
          ,asset_number                      -- 資産番号
          ,lease_class                       -- リース種別
          ,department_code                   -- 管理部門
          ,owner_company                     -- 本社工場区分
          ,retirement_date                   -- 除却日
          ,cost_retired                      -- 除売却・取得価格
          ,ret_prorate_convention            -- 除・売却年度償却
          ,fa_if_flag                        -- FA連携フラグ
          ,gl_if_flag                        -- GL連携フラグ
          ,created_by                        -- 作成者
          ,creation_date                     -- 作成日
          ,last_updated_by                   -- 最終更新者
          ,last_update_date                  -- 最終更新日
          ,last_update_login                 -- 最終更新ﾛｸﾞｲﾝ
          ,request_id                        -- 要求ID
          ,program_application_id            -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          ,program_id                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          ,program_update_date               -- ﾌﾟﾛｸﾞﾗﾑ更新日
        )
        VALUES (
           xxcff_fa_transactions_s1.NEXTVAL             -- リース取引内部ID
          ,g_contract_header_id_tab(ln_loop_cnt)        -- 契約内部ID
          ,g_contract_line_id_tab(ln_loop_cnt)          -- 契約明細内部ID
          ,g_object_header_id_tab(ln_loop_cnt)          -- 物件内部ID
          ,gv_period_name                               -- 会計期間
          ,3                                            -- 取引タイプ
          ,g_book_type_code_tab(ln_loop_cnt)            -- 資産台帳名
          ,g_asset_number_tab(ln_loop_cnt)              -- 資産番号
          ,g_lease_class_tab(ln_loop_cnt)               -- リース種別
          ,g_department_code_tab(ln_loop_cnt)           -- 管理部門
          ,g_owner_company_tab(ln_loop_cnt)             -- 本社工場区分
          ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))  -- 除却日
          ,g_original_cost_tab(ln_loop_cnt)             -- 除売却・取得価格
          ,DECODE(g_payment_match_flag_tab(ln_loop_cnt)
                    ,0 , gv_prt_conv_cd_st
                    ,1 , gv_prt_conv_cd_ed)             -- 除・売却年度償却
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--          ,cv_if_yet                                    -- FA連携フラグ
          ,DECODE(g_fully_retired_tab(ln_loop_cnt)
                    ,NULL ,cv_if_yet
                    ,cv_if_out)                         -- FA連携フラグ
-- 2018/03/29 Ver1.11 Otsuka MOD End
          ,cv_if_yet                                    -- GL連携フラグ
          ,cn_created_by                                -- 作成者
          ,cd_creation_date                             -- 作成日
          ,cn_last_updated_by                           -- 最終更新者
          ,cd_last_update_date                          -- 最終更新日
          ,cn_last_update_login                         -- 最終更新ﾛｸﾞｲﾝ
          ,cn_request_id                                -- 要求ID
          ,cn_program_application_id                    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          ,cn_program_id                                -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          ,cd_program_update_date                       -- ﾌﾟﾛｸﾞﾗﾑ更新日
        );
--
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--        -- 成功件数カウント
--        gn_les_retire_normal_cnt := SQL%ROWCOUNT;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--        -- FINリース台帳の場合
--        IF (g_book_type_code_tab(ln_loop_cnt) = gv_fin_lease_books) THEN
--          -- 成功件数カウント
--          gn_les_retire_normal_cnt := gn_les_retire_normal_cnt + 1;
--        -- IFRSリース台帳の場合
--        ELSE
--          gn_les_retire_ifrs_cnt := gn_les_retire_ifrs_cnt + 1;
--        END IF;
        -- 成功件数カウント
        gn_les_retire_normal_cnt := gn_les_retire_normal_cnt + 1;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
--
      END LOOP;
-- 2018/03/29 Ver1.11 Otsuka MOD End
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_les_trn_ritire_data;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_retire_data
   * Description      : リース取引(解約)登録データ抽出 (A-17)
   ***********************************************************************************/
  PROCEDURE get_les_trn_retire_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_retire_data'; -- プログラム名
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース取引(解約)カーソル
    CURSOR les_trn_retire_cur
    IS
      SELECT
-- 2018/03/23 Ver.1.11 Otsuka ADD Start
             /*+
                LEADING(ctrct_hist)
                USE_NL(ctrct_hist ctrct_head obj_head)
                USE_NL(ctrct_hist faadds)
                INDEX(ctrct_hist XXCFF_CONTRACT_HISTORIES_N02)
                INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK)
                INDEX(obj_head XXCFF_OBJECT_HEADERS_PK)
                INDEX(fb FA_BOOKS_U2)
              */
-- 2018/03/23 Ver.1.11 Otsuka ADD Start
             ctrct_hist.contract_header_id        AS contract_header_id  -- 契約内部ID
            ,ctrct_hist.contract_line_id          AS contract_line_id    -- 契約明細内部ID
            ,ctrct_hist.object_header_id          AS object_header_id    -- 物件内部ID
            ,ctrct_hist.history_num               AS history_num         -- 変更履歴No
            ,ctrct_hist.original_cost             AS original_cost       -- 取得価格
            ,faadds.asset_number                  AS asset_number        -- 資産番号
-- 2018/03/23 Ver.1.11 Otsuka MOD Start
            --,les_kind.book_type_code              AS book_type_code      -- 資産台帳名
            ,fb.book_type_code                    AS book_type_code      -- 資産台帳名
            ,fb.period_counter_fully_retired      AS fully_retired       -- 全部除売却
-- 2018/03/23 Ver.1.11 Otsuka MOD Start
            ,NVL(pay_plan.payment_match_flag,1)   AS payment_match_flag  -- 照合済みフラグ
            ,obj_head.department_code             AS department_code     -- 管理部門
            ,obj_head.owner_company               AS owner_company       -- 本社工場区分
            ,ctrct_head.lease_class               AS lease_class         -- リース種別
      FROM
            xxcff_contract_histories  ctrct_hist    -- リース契約明細履歴
           ,xxcff_contract_headers    ctrct_head    -- リース契約
           ,xxcff_object_headers      obj_head      -- リース物件
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--           ,xxcff_lease_kind_v        les_kind      -- リース種類ビュー
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
           ,fa_additions_b            faadds        -- 資産詳細情報
           ,xxcff_pay_planning        pay_plan      -- リース支払計画
-- 2018/03/23 Ver.1.11 Otsuka ADD Start
           ,fnd_lookup_values         flv           -- 参照表
           ,fa_books                  fb            -- 資産台帳情報
-- 2018/03/23 Ver.1.11 Otsuka ADD End
      WHERE
-- 0001058 2009/08/31 DEL START --
---- 0000417 2009/07/15 MOD START --
----            ctrct_hist.contract_status     IN ( cv_ctrt_manryo
----                                               ,cv_ctrt_cancel_jiko
----                                               ,cv_ctrt_cancel_hoken
----                                               ,cv_ctrt_cancel_manryo
----                                               )      -- 満了,
----                                                      -- 中途解約(自己都合),中途解約(保険対応),中途解約(満了)
--              obj_head.object_status     IN ( cv_obj_manryo
--                                                  ,cv_obj_cancel_jiko
--                                                  ,cv_obj_cancel_hoken
--                                                  ,cv_obj_cancel_manryo
--                                                  )      -- 満了,
--                                                         -- 中途解約(自己都合),中途解約(保険対応),中途解約(満了)
---- 0000417 2009/07/15 MOD END --
-- 0001058 2009/08/31 DEL END --
-- 0001058 2009/08/31 ADD START --
              ctrct_hist.contract_status     IN ( cv_ctrt_manryo
                                                 ,cv_ctrt_cancel_jiko
                                                 ,cv_ctrt_cancel_hoken
                                                 ,cv_ctrt_cancel_manryo
                                                 )      -- 満了,
                                                      -- 中途解約(自己都合),中途解約(保険対応),中途解約(満了)
        AND   obj_head.object_status     IN ( cv_obj_manryo
                                             ,cv_obj_cancel_jiko
                                             ,cv_obj_cancel_hoken
                                             ,cv_obj_cancel_manryo
                                             )      -- 満了,
                                                         -- 中途解約(自己都合),中途解約(保険対応),中途解約(満了)
-- 0001058 2009/08/31 ADD END --
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD Start
        AND ((ctrct_hist.cancellation_date IS NULL)                                             -- 解約日 = NULL (満了or中途解約(満了)の場合)
          OR (ctrct_hist.cancellation_date < LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')) + 1)) -- 解約日 < 会計期間最終日 + 1日
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD End
        AND ctrct_hist.accounting_if_flag   = cv_if_yet                               -- 未送信
-- 2018/03/23 Ver.1.11 Otsuka MOD Start
--        AND ctrct_hist.lease_kind           IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,旧Fin
--        AND ctrct_hist.contract_header_id   = ctrct_head.contract_header_id
--        AND ctrct_hist.object_header_id     = obj_head.object_header_id
--        AND ctrct_head.lease_type           = cv_original                             -- 原契約
--        AND ctrct_hist.contract_line_id     = faadds.attribute10
--        AND ctrct_hist.lease_kind           = les_kind.lease_kind_code
        AND ctrct_hist.contract_header_id   = ctrct_head.contract_header_id
        AND ctrct_hist.object_header_id     = obj_head.object_header_id
        AND faadds.attribute10              = TO_CHAR(ctrct_hist.contract_line_id)
        AND faadds.asset_id                 = fb.asset_id
        AND fb.date_ineffective             IS NULL                                    -- 最新
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--        AND fb.book_type_code               IN (les_kind.book_type_code ,les_kind.book_type_code_ifrs)
--        AND ctrct_hist.lease_kind           = les_kind.lease_kind_code
        AND fb.book_type_code               = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
        AND ( ( ctrct_head.lease_type       = cv_original                              -- 原契約
            AND ctrct_hist.lease_kind       IN (cv_lease_kind_fin,cv_lease_kind_lfin)) -- Fin,旧Fin
          OR  ( ctrct_head.lease_type       = cv_re_lease                              -- 再リース
            AND flv.attribute7              = cv_lease_cls_chk2 ))                     -- リース判定結果：2
        AND ctrct_head.lease_class          = flv.lookup_code
        AND flv.lookup_type                 = cv_xxcff1_lease_class_check
        AND flv.language                    = USERENV('LANG')
        AND flv.enabled_flag                = cv_flg_y
        AND LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
-- 2018/03/23 Ver.1.11 Otsuka MOD End
        AND ctrct_hist.contract_line_id     = pay_plan.contract_line_id(+)
        AND pay_plan.period_name(+)         = gv_period_name
        FOR UPDATE OF ctrct_hist.contract_header_id
        NOWAIT
      ;
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
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN les_trn_retire_cur;
    -- データの一括取得
    FETCH les_trn_retire_cur
    BULK COLLECT INTO  g_contract_header_id_tab -- 契約内部ID
                      ,g_contract_line_id_tab   -- 契約明細内部ID
                      ,g_object_header_id_tab   -- 物件内部ID
                      ,g_history_num_tab        -- 変更履歴No
                      ,g_original_cost_tab      -- 取得価格
                      ,g_asset_number_tab       -- 資産番号
                      ,g_book_type_code_tab     -- 資産台帳名
-- 2018/03/29 Ver1.11 Otsuka ADD Start
                      ,g_fully_retired_tab      -- 全部除売却
-- 2018/03/29 Ver1.11 Otsuka ADD End
                      ,g_payment_match_flag_tab -- 照合済みフラグ
                      ,g_department_code_tab    -- 管理部門
                      ,g_owner_company_tab      -- 本社工場区分
                      ,g_lease_class_tab        -- リース種別
    ;
    -- 処理対象件数
    gn_les_retire_target_cnt := g_contract_header_id_tab.COUNT;
    -- カーソルクローズ
    CLOSE les_trn_retire_cur;
--
    IF ( gn_les_retire_target_cnt = 0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_013a20_t_033) -- リース取引（解約）情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      -- カーソルクローズ
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_013a20_m_012  -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,cv_msg_013a20_t_023) -- リース契約明細履歴
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_les_trn_retire_data;
--
  /**********************************************************************************
   * Procedure Name   : get_deprn_ccid
   * Description      : 減価償却費勘定CCID取得 (A-25)
   ***********************************************************************************/
  PROCEDURE get_deprn_ccid(
     iot_segments  IN OUT fnd_flex_ext.segmentarray                     -- 1.セグメント値配列
    ,ot_deprn_ccid OUT    gl_code_combinations.code_combination_id%TYPE -- 2.減価償却費勘定CCID
    ,ov_errbuf     OUT    VARCHAR2                                      --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT    VARCHAR2                                      --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT    VARCHAR2)                                     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deprn_ccid'; -- プログラム名
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
    -- 関数リターンコード
    lb_ret BOOLEAN;
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
-- 2017/03/29 Ver.1.10 Y.Shoji DEL Start
--    -- 部門コード設定
--    iot_segments(2) := gv_dep_cd_chosei;
--    -- 顧客コード設定
--    iot_segments(5) := gv_ptnr_cd_dammy;
-- 2017/03/29 Ver.1.10 Y.Shoji DEL End
    -- 企業コード設定
    iot_segments(6) := gv_busi_cd_dammy;
    -- 予備1設定
    iot_segments(7) := gv_project_dammy;
    -- 予備2設定
    iot_segments(8) := gv_future_dammy;
--
    -- CCID取得関数呼び出し
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name  => g_init_rec.gl_application_short_name -- アプリケーション短縮名(GL)
                ,key_flex_code           => g_init_rec.id_flex_code              -- キーフレックスコード
                ,structure_number        => g_init_rec.chart_of_accounts_id      -- 勘定科目体系番号
                ,validation_date         => g_init_rec.process_date              -- 日付チェック
                ,n_segments              => 8                                    -- セグメント数
                ,segments                => iot_segments                         -- セグメント値配列
                ,combination_id          => ot_deprn_ccid                        -- CCID
                );
    IF NOT lb_ret THEN
      lv_errmsg := fnd_flex_ext.get_message;
      lv_errbuf := lv_errmsg;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_deprn_ccid;
--
  /**********************************************************************************
   * Procedure Name   : update_trnsf_data_acct_flag
   * Description      : リース契約明細履歴 会計IFフラグ更新 (A-16)
   ***********************************************************************************/
  PROCEDURE update_trnsf_data_acct_flag(
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
    in_loop_cnt   IN  NUMBER,       --   ループカウント
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_trnsf_data_acct_flag'; -- プログラム名
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
    --リース物件履歴更新
    --==============================================================
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--    <<update_loop>>
--    FORALL ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT
--      UPDATE xxcff_object_histories
--      SET
--             accounting_if_flag     = cv_if_aft                 -- 会計ifフラグ 2(連携済)
--            ,last_updated_by        = cn_last_updated_by        -- 最終更新者
--            ,last_update_date       = cd_last_update_date       -- 最終更新日
--            ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
--            ,request_id             = cn_request_id             -- 要求ID
--            ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
--            ,program_id             = cn_program_id             -- コンカレントプログラムID
--            ,program_update_date    = cd_program_update_date    -- プログラム更新日
--      WHERE
--            object_header_id     = g_object_header_id_tab(ln_loop_cnt)
--        AND object_status        =  cv_obj_move    -- 移動
--        AND accounting_if_flag   =  cv_if_yet      -- 未送信
--        AND accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
--      ;
    UPDATE xxcff_object_histories
    SET
           accounting_if_flag     = cv_if_aft                 -- 会計ifフラグ 2(連携済)
          ,last_updated_by        = cn_last_updated_by        -- 最終更新者
          ,last_update_date       = cd_last_update_date       -- 最終更新日
          ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
          ,request_id             = cn_request_id             -- 要求ID
          ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
          ,program_id             = cn_program_id             -- コンカレントプログラムID
          ,program_update_date    = cd_program_update_date    -- プログラム更新日
    WHERE
          object_header_id     = g_object_header_id_tab(in_loop_cnt)
      AND object_status        IN (cv_obj_move ,cv_obj_modify)    -- 移動,物件情報変更
      AND accounting_if_flag   =  cv_if_yet      -- 未送信
      AND accounting_date      >= TO_DATE(gv_period_name,'YYYY-MM')
      AND accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
    ;
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
--
    --==============================================================
    --リース契約明細履歴更新
    --==============================================================
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--    <<update_loop>>
--    FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
--      UPDATE xxcff_contract_histories
--      SET
--             accounting_if_flag     = cv_if_aft                 -- 会計ifフラグ 2(連携済)
--            ,last_updated_by        = cn_last_updated_by        -- 最終更新者
--            ,last_update_date       = cd_last_update_date       -- 最終更新日
--            ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
--            ,request_id             = cn_request_id             -- 要求ID
--            ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
--            ,program_id             = cn_program_id             -- コンカレントプログラムID
--            ,program_update_date    = cd_program_update_date    -- プログラム更新日
--      WHERE
--             contract_line_id   = g_contract_line_id_tab(ln_loop_cnt)
--         AND contract_status    =  cv_ctrt_info_change  -- 情報変更
--         AND accounting_if_flag =  cv_if_yet            -- 未送信
--         AND accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
--      ;
    UPDATE xxcff_contract_histories
    SET
           accounting_if_flag     = cv_if_aft                 -- 会計ifフラグ 2(連携済)
          ,last_updated_by        = cn_last_updated_by        -- 最終更新者
          ,last_update_date       = cd_last_update_date       -- 最終更新日
          ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
          ,request_id             = cn_request_id             -- 要求ID
          ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
          ,program_id             = cn_program_id             -- コンカレントプログラムID
          ,program_update_date    = cd_program_update_date    -- プログラム更新日
    WHERE
           contract_line_id   = g_contract_line_id_tab(in_loop_cnt)
       AND contract_status    =  cv_ctrt_info_change  -- 情報変更
       AND accounting_if_flag =  cv_if_yet            -- 未送信
       AND accounting_date    >= TO_DATE(gv_period_name,'YYYY-MM')
       AND accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
    ;
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_trnsf_data_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_les_trn_trnsf_data
   * Description      : リース取引(振替)登録 (A-15)
   ***********************************************************************************/
  PROCEDURE insert_les_trn_trnsf_data(
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
    in_loop_cnt   IN  NUMBER,       --   ループカウント
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_les_trn_trnsf_data'; -- プログラム名
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
    IF (gn_les_trnsf_target_cnt > 0) THEN
--
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--      <<inert_loop>>
--      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
--        INSERT INTO xxcff_fa_transactions (
--           fa_transaction_id                 -- リース取引内部ID
--          ,contract_header_id                -- 契約内部ID
--          ,contract_line_id                  -- 契約明細内部ID
--          ,object_header_id                  -- 物件内部ID
--          ,period_name                       -- 会計期間
--          ,transaction_type                  -- 取引タイプ
--          ,movement_type                     -- 移動タイプ
--          ,book_type_code                    -- 資産台帳名
--          ,asset_number                      -- 資産番号
--          ,lease_class                       -- リース種別
--          ,quantity                          -- 数量
--          ,dprn_company_code                 -- 会F_会社コード
--          ,dprn_department_code              -- 会F_部門コード
--          ,dprn_account_code                 -- 会F_勘定科目コード
--          ,dprn_sub_account_code             -- 会F_補助科目コード
--          ,dprn_customer_code                -- 会F_顧客コード
--          ,dprn_enterprise_code              -- 会F_企業コード
--          ,dprn_reserve_1                    -- 会F_予備1
--          ,dprn_reserve_2                    -- 会F_予備2
--          ,dclr_place                        -- 申告地
--          ,department_code                   -- 管理部門コード
--          ,location_name                     -- 事業所
--          ,location_place                    -- 場所
--          ,owner_company                     -- 本社／工場
--          ,transfer_date                     -- 振替日
--          ,fa_if_flag                        -- FA連携フラグ
--          ,gl_if_flag                        -- GL連携フラグ
--          ,created_by                        -- 作成者
--          ,creation_date                     -- 作成日
--          ,last_updated_by                   -- 最終更新者
--          ,last_update_date                  -- 最終更新日
--          ,last_update_login                 -- 最終更新ﾛｸﾞｲﾝ
--          ,request_id                        -- 要求ID
--          ,program_application_id            -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--          ,program_id                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--          ,program_update_date               -- ﾌﾟﾛｸﾞﾗﾑ更新日
--        )
--        VALUES (
--           xxcff_fa_transactions_s1.NEXTVAL            -- リース取引内部ID
--          ,g_contract_header_id_tab(ln_loop_cnt)       -- 契約内部ID
--          ,g_contract_line_id_tab(ln_loop_cnt)         -- 契約明細内部ID
--          ,g_object_header_id_tab(ln_loop_cnt)         -- 物件内部ID
--          ,gv_period_name                              -- 会計期間
--          ,2                                           -- 取引タイプ
--          ,DECODE(g_trnsf_to_comp_cd_tab(ln_loop_cnt)
--                    ,gv_comp_cd_sagara , 1
--                    ,gv_comp_cd_itoen  , 2)            -- 移動タイプ
--          ,g_book_type_code_tab(ln_loop_cnt)           -- 資産台帳名
--          ,g_asset_number_tab(ln_loop_cnt)             -- 資産番号
--          ,g_lease_class_tab(ln_loop_cnt)              -- リース種別
--          ,g_quantity_tab(ln_loop_cnt)                 -- 数量
--          ,g_trnsf_to_comp_cd_tab(ln_loop_cnt)         -- 会F_会社コード
--          ,gv_dep_cd_chosei                            -- 会F_部門コード
--          ,g_deprn_acct_tab(ln_loop_cnt)               -- 会F_勘定科目コード
--          ,g_deprn_sub_acct_tab(ln_loop_cnt)           -- 会F_補助科目コード
--          ,gv_ptnr_cd_dammy                            -- 会F_顧客コード
--          ,gv_busi_cd_dammy                            -- 会F_企業コード
--          ,gv_project_dammy                            -- 会F_予備1
--          ,gv_future_dammy                             -- 会F_予備2
--          ,gv_dclr_place_no_report                     -- 申告地
--          ,g_department_code_tab(ln_loop_cnt)          -- 管理部門コード
--          ,gv_mng_place_dammy                          -- 事業所
--          ,gv_place_dammy                              -- 場所
--          ,g_owner_company_tab(ln_loop_cnt)            -- 本社／工場
--          ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) -- 振替日
--          ,cv_if_yet                                   -- FA連携フラグ
--          ,cv_if_yet                                   -- GL連携フラグ
--          ,cn_created_by                               -- 作成者
--          ,cd_creation_date                            -- 作成日
--          ,cn_last_updated_by                          -- 最終更新者
--          ,cd_last_update_date                         -- 最終更新日
--          ,cn_last_update_login                        -- 最終更新ﾛｸﾞｲﾝ
--          ,cn_request_id                               -- 要求ID
--          ,cn_program_application_id                   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--          ,cn_program_id                               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--          ,cd_program_update_date                      -- ﾌﾟﾛｸﾞﾗﾑ更新日
--        );
--
--      --成功件数カウント
--      gn_les_trnsf_normal_cnt := SQL%ROWCOUNT;
      INSERT INTO xxcff_fa_transactions (
         fa_transaction_id                 -- リース取引内部ID
        ,contract_header_id                -- 契約内部ID
        ,contract_line_id                  -- 契約明細内部ID
        ,object_header_id                  -- 物件内部ID
        ,period_name                       -- 会計期間
        ,transaction_type                  -- 取引タイプ
        ,movement_type                     -- 移動タイプ
        ,book_type_code                    -- 資産台帳名
        ,asset_number                      -- 資産番号
        ,lease_class                       -- リース種別
        ,quantity                          -- 数量
        ,dprn_company_code                 -- 会F_会社コード
        ,dprn_department_code              -- 会F_部門コード
        ,dprn_account_code                 -- 会F_勘定科目コード
        ,dprn_sub_account_code             -- 会F_補助科目コード
        ,dprn_customer_code                -- 会F_顧客コード
        ,dprn_enterprise_code              -- 会F_企業コード
        ,dprn_reserve_1                    -- 会F_予備1
        ,dprn_reserve_2                    -- 会F_予備2
        ,dclr_place                        -- 申告地
        ,department_code                   -- 管理部門コード
        ,location_name                     -- 事業所
        ,location_place                    -- 場所
        ,owner_company                     -- 本社／工場
        ,transfer_date                     -- 振替日
        ,fa_if_flag                        -- FA連携フラグ
        ,gl_if_flag                        -- GL連携フラグ
        ,created_by                        -- 作成者
        ,creation_date                     -- 作成日
        ,last_updated_by                   -- 最終更新者
        ,last_update_date                  -- 最終更新日
        ,last_update_login                 -- 最終更新ﾛｸﾞｲﾝ
        ,request_id                        -- 要求ID
        ,program_application_id            -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,program_id                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,program_update_date               -- ﾌﾟﾛｸﾞﾗﾑ更新日
      )
      VALUES (
         xxcff_fa_transactions_s1.NEXTVAL            -- リース取引内部ID
        ,g_contract_header_id_tab(in_loop_cnt)       -- 契約内部ID
        ,g_contract_line_id_tab(in_loop_cnt)         -- 契約明細内部ID
        ,g_object_header_id_tab(in_loop_cnt)         -- 物件内部ID
        ,gv_period_name                              -- 会計期間
        ,g_transaction_type_tab(in_loop_cnt)         -- 取引タイプ
        ,DECODE(g_trnsf_to_comp_cd_tab(in_loop_cnt)
                  ,gv_comp_cd_sagara , 1
                  ,gv_comp_cd_itoen  , 2)            -- 移動タイプ
        ,g_book_type_code_tab(in_loop_cnt)           -- 資産台帳名
        ,g_asset_number_tab(in_loop_cnt)             -- 資産番号
        ,g_lease_class_tab(in_loop_cnt)              -- リース種別
        ,g_quantity_tab(in_loop_cnt)                 -- 数量
        ,g_trnsf_to_comp_cd_tab(in_loop_cnt)         -- 会F_会社コード
        ,DECODE(g_dept_tran_flg_tab(in_loop_cnt)
                  ,cv_flg_y , g_department_code_tab(in_loop_cnt)
                            , gv_dep_cd_chosei)
                                                     -- 会F_部門コード
        ,g_deprn_acct_tab(in_loop_cnt)               -- 会F_勘定科目コード
        ,g_deprn_sub_acct_tab(in_loop_cnt)           -- 会F_補助科目コード
        ,DECODE(g_vd_cust_flag_tab(in_loop_cnt)
                  ,cv_flg_y , g_customer_code_tab(in_loop_cnt)
                            , gv_ptnr_cd_dammy)
                                                     -- 会F_顧客コード
        ,gv_busi_cd_dammy                            -- 会F_企業コード
        ,gv_project_dammy                            -- 会F_予備1
        ,gv_future_dammy                             -- 会F_予備2
        ,gv_dclr_place_no_report                     -- 申告地
        ,g_department_code_tab(in_loop_cnt)          -- 管理部門コード
        ,gv_mng_place_dammy                          -- 事業所
        ,gv_place_dammy                              -- 場所
        ,g_owner_company_tab(in_loop_cnt)            -- 本社／工場
        ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) -- 振替日
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--        ,cv_if_yet                                   -- FA連携フラグ
        ,DECODE(g_fully_retired_tab(in_loop_cnt)
                  ,NULL ,cv_if_yet
                  ,cv_if_out)                        -- FA連携フラグ
-- 2018/03/29 Ver1.11 Otsuka MOD End
        ,cv_if_yet                                   -- GL連携フラグ
        ,cn_created_by                               -- 作成者
        ,cd_creation_date                            -- 作成日
        ,cn_last_updated_by                          -- 最終更新者
        ,cd_last_update_date                         -- 最終更新日
        ,cn_last_update_login                        -- 最終更新ﾛｸﾞｲﾝ
        ,cn_request_id                               -- 要求ID
        ,cn_program_application_id                   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,cn_program_id                               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,cd_program_update_date                      -- ﾌﾟﾛｸﾞﾗﾑ更新日
      );
--
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--      --成功件数カウント
--      gn_les_trnsf_normal_cnt := gn_les_trnsf_normal_cnt + 1;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--      -- FINリース台帳の場合
--      IF (g_book_type_code_tab(in_loop_cnt) = gv_fin_lease_books) THEN
--        -- 成功件数カウント
--        gn_les_trnsf_normal_cnt := gn_les_trnsf_normal_cnt + 1;
--      -- IFRSリース台帳の場合
--      ELSE
--        gn_les_trnsf_ifrs_cnt := gn_les_trnsf_ifrs_cnt + 1;
--      END IF;
      --成功件数カウント
      gn_les_trnsf_normal_cnt := gn_les_trnsf_normal_cnt + 1;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2018/03/29 Ver1.11 Otsuka MOD End
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_les_trn_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : lock_trnsf_data
   * Description      : リース取引(振替)データロック処理 (A-12)
   ***********************************************************************************/
  PROCEDURE lock_trnsf_data(
    it_object_header_id IN xxcff_contract_histories.object_header_id%TYPE
   ,it_contract_line_id IN xxcff_contract_histories.contract_line_id%TYPE
   ,ov_errbuf           OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode          OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_trnsf_data'; -- プログラム名
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ロック用カーソル(物件履歴)
    CURSOR lock_obj_trnsf_data (in_object_header_id NUMBER)
    IS
      SELECT
             obj_hist.object_header_id     AS object_header_id  -- 物件内部ID
      FROM
            xxcff_object_histories    obj_hist      -- リース物件履歴
      WHERE
             obj_hist.object_header_id     =  in_object_header_id
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--         AND obj_hist.object_status        =  cv_obj_move    -- 移動
         AND obj_hist.object_status        IN (cv_obj_move ,cv_obj_modify)  -- 移動,物件情報変更
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
         AND obj_hist.accounting_if_flag   =  cv_if_yet      -- 未送信
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
         AND obj_hist.accounting_date      >= TO_DATE(gv_period_name,'YYYY-MM')
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
         AND obj_hist.accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
         FOR UPDATE NOWAIT
         ;
--
    -- ロック用カーソル(契約明細履歴)
    CURSOR lock_ctrct_trnsf_data (in_contract_line_id NUMBER)
    IS
      SELECT
             ctrct_hist.contract_line_id     AS contract_line_id  -- 物件内部ID
      FROM
            xxcff_contract_histories    ctrct_hist      -- リース契約明細履歴
      WHERE
             ctrct_hist.contract_line_id   =  in_contract_line_id
         AND ctrct_hist.contract_status    =  cv_ctrt_info_change  -- 情報変更
         AND ctrct_hist.accounting_if_flag =  cv_if_yet            -- 未送信
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
         AND ctrct_hist.accounting_date    >= TO_DATE(gv_period_name,'YYYY-MM')
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
         AND ctrct_hist.accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
         FOR UPDATE NOWAIT
         ;
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
    --ロック処理⇒物件履歴データ
    --==============================================================
    BEGIN
--
      -- カーソルオープン
      OPEN lock_obj_trnsf_data (it_object_header_id);
      -- カーソルクローズ
      CLOSE lock_obj_trnsf_data;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ロック(ビジー)エラー
        -- カーソルクローズ
        IF (lock_obj_trnsf_data%ISOPEN) THEN
          CLOSE lock_obj_trnsf_data;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_012  -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,cv_msg_013a20_t_029) -- リース物件履歴
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --ロック処理⇒契約明細履歴データ
    --==============================================================
    BEGIN
--
      -- カーソルオープン
      OPEN lock_ctrct_trnsf_data (it_contract_line_id);
      -- カーソルクローズ
      CLOSE lock_ctrct_trnsf_data;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ロック(ビジー)エラー
        -- カーソルクローズ
        IF (lock_ctrct_trnsf_data%ISOPEN) THEN
          CLOSE lock_ctrct_trnsf_data;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_012  -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,cv_msg_013a20_t_023) -- リース契約明細履歴
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (lock_obj_trnsf_data%ISOPEN) THEN
        CLOSE lock_obj_trnsf_data;
      END IF;
      IF (lock_ctrct_trnsf_data%ISOPEN) THEN
        CLOSE lock_ctrct_trnsf_data;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (lock_obj_trnsf_data%ISOPEN) THEN
        CLOSE lock_obj_trnsf_data;
      END IF;
      IF (lock_ctrct_trnsf_data%ISOPEN) THEN
        CLOSE lock_ctrct_trnsf_data;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (lock_obj_trnsf_data%ISOPEN) THEN
        CLOSE lock_obj_trnsf_data;
      END IF;
      IF (lock_ctrct_trnsf_data%ISOPEN) THEN
        CLOSE lock_ctrct_trnsf_data;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END lock_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_les_trn_trnsf_data（ループ部）
   * Description      : リース取引(振替)データ処理 (A-12)～(A-16)
   ***********************************************************************************/
  PROCEDURE proc_les_trn_trnsf_data(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_les_trn_trnsf_data'; -- プログラム名
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
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
    lt_m_owner_company    xxcff_object_histories.m_owner_company%TYPE;   -- 移動元本社/工場
    lt_m_department_code  xxcff_object_histories.m_department_code%TYPE; -- 移動元管理部門
    lt_customer_code      xxcff_object_histories.customer_code%TYPE;     -- 修正前顧客コード
    lv_trnsf_flg          VARCHAR2(1);                                   -- 振替対象フラグ
    lv_warnmsg            VARCHAR2(5000);                                -- 警告メッセージ
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --==============================================================
    --メインループ処理②
    --==============================================================
    <<proc_les_trn_trnsf_data>>
    FOR ln_loop_cnt IN 1 .. g_contract_header_id_tab.COUNT LOOP
--
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--      --==============================================================
--      --抽出対象データロック (A-12)
--      --==============================================================
--      lock_trnsf_data(
--         it_object_header_id    => g_object_header_id_tab(ln_loop_cnt) -- 物件内部ID
--        ,it_contract_line_id    => g_contract_line_id_tab(ln_loop_cnt) -- 契約明細内部ID
--        ,ov_errbuf              => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
--        ,ov_retcode             => lv_retcode                          -- リターン・コード             --# 固定 #
--        ,ov_errmsg              => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF (lv_retcode <> ov_retcode) THEN
--        RAISE global_api_expt;
--      END IF;
----
--      --==============================================================
--      --事業所CCID取得 (A-13)
--      --==============================================================
--      xxcff_common1_pkg.chk_fa_location(
--         iv_segment2      => g_department_code_tab(ln_loop_cnt) -- 管理部門
--        ,iv_segment5      => g_owner_company_tab(ln_loop_cnt)   -- 本社工場区分
--        ,on_location_id   => g_location_ccid_tab(ln_loop_cnt)   -- 事業所CCID
--        ,ov_errbuf        => lv_errbuf                          -- エラー・メッセージ           --# 固定 # 
--        ,ov_retcode       => lv_retcode                         -- リターン・コード             --# 固定 #
--        ,ov_errmsg        => lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF (lv_retcode <> ov_retcode) THEN
--        RAISE global_api_expt;
--      END IF;
----
--      --==============================================================
--      --減価償却費勘定CCID取得 (A-14)
--      --==============================================================
----
--      -- セグメント値配列設定(SEG1:会社)
--      g_segments_tab(1) :=  g_trnsf_to_comp_cd_tab(ln_loop_cnt);
----
--      -- セグメント値配列設定(SEG3:勘定科目)
--      g_segments_tab(3) := g_deprn_acct_tab(ln_loop_cnt);
--      -- セグメント値配列設定(SEG4:補助科目)
--      g_segments_tab(4) := g_deprn_sub_acct_tab(ln_loop_cnt);
----
--      -- 減価償却費勘定CCID取得
--      get_deprn_ccid(
--         iot_segments     => g_segments_tab                  -- セグメント値配列
--        ,ot_deprn_ccid    => g_deprn_ccid_tab(ln_loop_cnt)   -- 減価償却費勘定CCID
--        ,ov_errbuf        => lv_errbuf                       -- エラー・メッセージ           --# 固定 # 
--        ,ov_retcode       => lv_retcode                      -- リターン・コード             --# 固定 #
--        ,ov_errmsg        => lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF (lv_retcode <> ov_retcode) THEN
--        RAISE global_api_expt;
--      END IF;
----
--    END LOOP proc_les_trn_trnsf_data;
----
--    -- =========================================
--    -- リース取引(振替)登録 (A-15)
--    -- =========================================
--    insert_les_trn_trnsf_data(
--       lv_errbuf         -- エラー・メッセージ           --# 固定 #
--      ,lv_retcode        -- リターン・コード             --# 固定 #
--      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
--    );
--    IF (lv_retcode <> cv_status_normal) THEN
--      RAISE global_process_expt;
--    END IF;
----
--    -- ==============================================
--    -- 抽出対象データ 会計IFフラグ更新 (A-16)
--    -- ==============================================
--    update_trnsf_data_acct_flag(
--       lv_errbuf         -- エラー・メッセージ           --# 固定 #
--      ,lv_retcode        -- リターン・コード             --# 固定 #
--      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
--    );
--    IF (lv_retcode <> cv_status_normal) THEN
--      RAISE global_process_expt;
--    END IF;
      -- 物件履歴取得
      get_obj_hist_data(
         it_object_header_id   => g_object_header_id_tab(ln_loop_cnt) -- 1.物件ID
        ,ot_m_owner_company    => lt_m_owner_company                  -- 2.移動元本社/工場
        ,ot_m_department_code  => lt_m_department_code                -- 3.移動元管理部門
        ,ot_customer_code      => lt_customer_code                    -- 4.顧客コード
        ,ov_errbuf             => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode            => lv_retcode                          -- リターン・コード             --# 固定 #
        ,ov_errmsg             => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- 該当の履歴が存在する場合
      g_department_code_tab(ln_loop_cnt) := NVL(lt_m_department_code ,g_department_code_tab(ln_loop_cnt));
      g_owner_company_tab(ln_loop_cnt)   := NVL(lt_m_owner_company   ,g_owner_company_tab(ln_loop_cnt));
      g_customer_code_tab(ln_loop_cnt)   := NVL(lt_customer_code     ,g_customer_code_tab(ln_loop_cnt));
--
      -- 該当の移動履歴が存在する場合
      IF ( lt_m_owner_company IS NOT NULL ) THEN
        -- 本社工場区分が本社の場合
        IF g_owner_company_tab(ln_loop_cnt) = gv_own_comp_itoen THEN
          -- 振替先会社コードに本社コード設定
          g_trnsf_to_comp_cd_tab(ln_loop_cnt) := gv_comp_cd_itoen;
        -- 本社工場区分が工場の場合
        ELSE
          -- 振替先会社コードに工場コード設定
          g_trnsf_to_comp_cd_tab(ln_loop_cnt) := gv_comp_cd_sagara;
        END IF;
      END IF;
--
      -- 振替先会社コードと振替元会社コードが違う場合
      IF ( g_trnsf_to_comp_cd_tab(ln_loop_cnt) <> g_trnsf_from_comp_cd_tab(ln_loop_cnt) ) THEN
        -- 取引タイプに振替を設定
        g_transaction_type_tab(ln_loop_cnt) := cv_transaction_type_2;
        lv_trnsf_flg                        := cv_flg_y;
      -- 部門振替フラグが'Y'の時
      -- 管理部門と振替元管理部門が違う、または、VD顧客フラグが'Y'で顧客コードと振替元顧客コードが違う場合
      ELSIF ( g_dept_tran_flg_tab(ln_loop_cnt)     =  cv_flg_y
          AND ( g_department_code_tab(ln_loop_cnt) <> g_trnsf_from_dep_cd_tab(ln_loop_cnt)
            OR  ( g_vd_cust_flag_tab(ln_loop_cnt)   =  cv_flg_y
              AND g_customer_code_tab(ln_loop_cnt)  <> g_trnsf_from_cust_cd_tab(ln_loop_cnt) ) ) ) THEN
        -- 取引タイプに部門振替を設定
        g_transaction_type_tab(ln_loop_cnt) := cv_transaction_type_4;
        lv_trnsf_flg                        := cv_flg_y;
      -- 上記以外の場合
      ELSE
        lv_trnsf_flg                        := cv_flg_n;
      END IF;
--
      -- 対象の場合
      IF ( lv_trnsf_flg = cv_flg_y ) THEN
--
        -- 対象件数カウント
        gn_les_trnsf_target_cnt := gn_les_trnsf_target_cnt + 1;
--
        --==============================================================
        --抽出対象データロック (A-12)
        --==============================================================
        lock_trnsf_data(
           it_object_header_id    => g_object_header_id_tab(ln_loop_cnt) -- 物件内部ID
          ,it_contract_line_id    => g_contract_line_id_tab(ln_loop_cnt) -- 契約明細内部ID
          ,ov_errbuf              => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode             => lv_retcode                          -- リターン・コード             --# 固定 #
          ,ov_errmsg              => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        --事業所CCID取得 (A-13)
        --==============================================================
        xxcff_common1_pkg.chk_fa_location(
           iv_segment2      => g_department_code_tab(ln_loop_cnt) -- 管理部門
          ,iv_segment5      => g_owner_company_tab(ln_loop_cnt)   -- 本社工場区分
          ,on_location_id   => g_location_ccid_tab(ln_loop_cnt)   -- 事業所CCID
          ,ov_errbuf        => lv_errbuf                          -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode       => lv_retcode                         -- リターン・コード             --# 固定 #
          ,ov_errmsg        => lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        --減価償却費勘定CCID取得 (A-14)
        --==============================================================
--
        -- セグメント値配列設定(SEG1:会社)
        g_segments_tab(1) :=  g_trnsf_to_comp_cd_tab(ln_loop_cnt);
--
        -- セグメント値配列設定(SEG2:部門コード)
        -- 部門振替フラグが'Y'の時
        IF ( g_dept_tran_flg_tab(ln_loop_cnt) = cv_flg_y ) THEN
          -- 管理部門
          g_segments_tab(2) := g_department_code_tab(ln_loop_cnt);
        -- 部門振替フラグが'Y'以外の時
        ELSE
          -- XXCFF: 部門コード_調整部門
          g_segments_tab(2) := gv_dep_cd_chosei;
        END IF;
--
        -- セグメント値配列設定(SEG3:勘定科目)
        g_segments_tab(3) := g_deprn_acct_tab(ln_loop_cnt);
        -- セグメント値配列設定(SEG4:補助科目)
        g_segments_tab(4) := g_deprn_sub_acct_tab(ln_loop_cnt);
--
        -- セグメント値配列設定(SEG5:顧客コード)
        -- VD顧客フラグが'Y'の時
        IF ( g_vd_cust_flag_tab(ln_loop_cnt) = cv_flg_y ) THEN
          -- 顧客コード
          g_segments_tab(5) := g_customer_code_tab(ln_loop_cnt);
        -- VD顧客フラグが'Y'以外の時
        ELSE
          -- XXCFF: 顧客コード_定義なし
          g_segments_tab(5) := gv_ptnr_cd_dammy;
        END IF;
--
        -- 減価償却費勘定CCID取得
        get_deprn_ccid(
           iot_segments     => g_segments_tab                  -- セグメント値配列
          ,ot_deprn_ccid    => g_deprn_ccid_tab(ln_loop_cnt)   -- 減価償却費勘定CCID
          ,ov_errbuf        => lv_errbuf                       -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode       => lv_retcode                      -- リターン・コード             --# 固定 #
          ,ov_errmsg        => lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- =========================================
        -- リース取引(振替)登録 (A-15)
        -- =========================================
        insert_les_trn_trnsf_data(
           ln_loop_cnt       -- ループカウント
          ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
          ,lv_retcode        -- リターン・コード             --# 固定 #
          ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ==============================================
        -- 抽出対象データ 会計IFフラグ更新 (A-16)
        -- ==============================================
        update_trnsf_data_acct_flag(
           ln_loop_cnt       -- ループカウント
          ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
          ,lv_retcode        -- リターン・コード             --# 固定 #
          ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP proc_les_trn_trnsf_data;
--
    -- 抽出件数が1件以上で、処理対象件数が0件の場合
    IF (  g_contract_header_id_tab.COUNT > 0 
      AND gn_les_trnsf_target_cnt        = 0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_013a20_t_032) -- リース取引（振替）情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_les_trn_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_trnsf_data
   * Description      : リース取引(振替)登録データ抽出 (A-11)
   ***********************************************************************************/
  PROCEDURE get_les_trn_trnsf_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_trnsf_data'; -- プログラム名
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース取引(振替)カーソル
    CURSOR les_trn_trnsf_cur
    IS
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--      SELECT
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
--      SELECT /*+ INDEX(ctrct_line XXCFF_CONTRACT_LINES_N03) INDEX(faadds XXCFF_FA_ADDITIONS_B_N04) INDEX(fadist_hist FA_DISTRIBUTION_HISTORY_N2) INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK) INDEX(les_class.FFV FND_FLEX_VALUES_U1) */
      SELECT
       /*+ USE_NL(les_class.ffvs les_class.ffv les_class.ffvt)
           INDEX(ctrct_line XXCFF_CONTRACT_LINES_N03)
           INDEX(faadds XXCFF_FA_ADDITIONS_B_N04)
           INDEX(fadist_hist FA_DISTRIBUTION_HISTORY_N2) 
           INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK) */
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
             ctrct_line.contract_header_id                      AS contract_header_id -- 契約内部ID
            ,ctrct_line.contract_line_id                        AS contract_line_id   -- 契約明細内部ID
            ,ctrct_line.object_header_id                        AS object_header_id   -- 物件内部ID
            ,ctrct_head.contract_date                           AS contract_date      -- リース契約日
            ,obj_head.department_code                           AS department_code    -- 管理部門
            ,obj_head.owner_company                             AS owner_company      -- 本社工場区分
            ,1                                                  AS quantity           -- 数量
            ,ctrct_head.lease_class                             AS lease_class        -- リース種別
            ,faadds.asset_number                                AS asset_number       -- 資産番号
-- 2018/03/29 Ver1.11 Otsuka MOD Start
            --,les_kind.book_type_code                            AS book_type_code     -- 資産台帳名
            ,fadist_hist.book_type_code                         AS book_type_code     -- 資産台帳名
-- 2018/03/29 Ver1.11 Otsuka MOD End
            ,les_class.deprn_acct                               AS deprn_acct         -- 減価償却勘定
            ,les_class.deprn_sub_acct                           AS deprn_sub_acct     -- 減価償却補助勘定
            ,gcc.segment1                                       AS trnsf_from_comp_cd -- 振替元会社コード
            ,DECODE(obj_head.owner_company
                      ,gv_own_comp_itoen  , gv_comp_cd_itoen
                      ,gv_own_comp_sagara , gv_comp_cd_sagara)  AS trnsf_to_comp_cd   -- 振替先会社コード
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
            ,gcc.segment2                                       AS trnsf_from_dep_cd  -- 振替元管理部門
            ,gcc.segment5                                       AS trnsf_from_cust_cd -- 振替元顧客コード
            ,obj_head.customer_code                             AS customer_code      -- 振替先顧客コード
            ,les_class.vd_cust_flag                             AS vd_cust_flag       -- VD顧客フラグ
            ,flv.attribute1                                     AS dept_tran_flg      -- 部門振替フラグ
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
            ,NULL                                               AS location_ccid      -- 事業所CCID
            ,NULL                                               AS deprn_ccid         -- 減価償却費勘定CCID
-- 2018/03/29 Ver1.11 Otsuka ADD Start
            ,fb.period_counter_fully_retired                    AS fully_retired      -- 全部除売却
-- 2018/03/29 Ver1.11 Otsuka ADD End
      FROM
            xxcff_object_headers      obj_head      -- リース物件
           ,xxcff_contract_lines      ctrct_line    -- リース契約明細
           ,xxcff_contract_headers    ctrct_head    -- リース契約
           ,fa_additions_b            faadds        -- 資産詳細情報
           ,fa_distribution_history   fadist_hist   -- 資産割当履歴情報
           ,gl_code_combinations      gcc           -- GL組合せ
           ,xxcff_lease_class_v       les_class     -- リース種別ビュー
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--           ,xxcff_lease_kind_v        les_kind      -- リース種類ビュー
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
           ,fnd_lookup_values         flv           -- 参照表
           ,fa_books                  fb            -- 資産台帳情報
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
           ,( 
              SELECT  lse_trnsf_hist_data.object_header_id
-- 2016/08/03 Ver.1.9 Y.Koh DEL Start
--                     ,lse_trnsf_hist_data.contract_line_id
-- 2016/08/03 Ver.1.9 Y.Koh DEL End
              FROM (
-- 2019/05/24 Ver.1.13 Y.Shoji MOD Start
---- 2016/08/03 Ver.1.9 Y.Koh MOD Start
----                     SELECT
---- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
----                     SELECT /*+ INDEX(obj_hist XXCFF_OBJECT_HISTORIES_N02) INDEX(ctrct_line XXCFF_CONTRACT_LINES_N03) INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK) */
--                     SELECT
--                            /*+ USE_NL(obj_hist ctrct_line ctrct_head)
--                                INDEX(obj_hist XXCFF_OBJECT_HISTORIES_N02)
--                                INDEX(ctrct_line XXCFF_CONTRACT_LINES_N03)
--                                INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK) */ 
---- 2017/03/29 Ver.1.10 Y.Shoji ADD End
---- 2016/08/03 Ver.1.9 Y.Koh MOD End
--                             obj_hist.object_header_id   AS object_header_id
---- 2017/03/29 Ver.1.10 Y.Shoji DEL Start
----                            ,ctrct_line.contract_line_id AS contract_line_id
---- 2017/03/29 Ver.1.10 Y.Shoji DEL End
--                     FROM
--                           xxcff_object_histories  obj_hist    -- リース物件履歴
--                          ,xxcff_contract_lines    ctrct_line  -- リース契約明細
--                          ,xxcff_contract_headers  ctrct_head  -- リース契約
---- 2018/03/29 Ver1.11 Otsuka ADD Start
--                          ,fnd_lookup_values         flv       -- 参照表
---- 2018/03/29 Ver1.11 Otsuka ADD End
--                     WHERE 
--                           obj_hist.object_header_id   = ctrct_line.object_header_id
--                       AND ctrct_line.contract_status  IN ( cv_ctrt_ctrt
--                                                           ,cv_ctrt_manryo
---- 2016/08/03 Ver.1.9 Y.Koh ADD Start
--                                                           ,cv_ctrt_re_lease
---- 2016/08/03 Ver.1.9 Y.Koh ADD End
--                                                           ,cv_ctrt_cancel_jiko
--                                                           ,cv_ctrt_cancel_hoken
--                                                           ,cv_ctrt_cancel_manryo
--                                                           ) -- 契約
--                                                             -- 満了
--                                                             -- 中途解約(自己都合),中途解約(保険対応),中途解約(満了)
---- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
----                       AND obj_hist.object_status        = cv_obj_move  -- 移動
--                       AND obj_hist.object_status        IN (cv_obj_move ,cv_obj_modify)  -- 移動,物件情報変更
---- 2017/03/29 Ver.1.10 Y.Shoji MOD End
--                       AND obj_hist.accounting_if_flag   = cv_if_yet    -- 未送信
---- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
--                       AND obj_hist.accounting_date      >= TO_DATE(gv_period_name,'YYYY-MM')
---- 2017/03/29 Ver.1.10 Y.Shoji ADD End
--                       AND obj_hist.accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
--                       AND ctrct_head.contract_header_id = ctrct_line.contract_header_id
---- 2016/08/03 Ver.1.9 Y.Koh MOD Start
----                       AND ctrct_head.lease_type         =  cv_original                            -- 原契約
----                       AND ctrct_line.lease_kind         IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,旧Fin
---- 2018/03/29 Ver1.11 Otsuka DEL Start
----                       AND ( ctrct_head.lease_type         =  cv_original                            -- 原契約
----                       OR    ctrct_head.lease_type         =  cv_re_lease                            -- 再リース
----                       AND   ctrct_head.lease_class        =  cv_lease_class_vd                      -- 自販機
----                       AND   ctrct_head.re_lease_times     <= 3 )                                    -- 再リース回数
---- 2016/08/03 Ver.1.9 Y.Koh MOD End
---- 2018/03/29 Ver1.11 Otsuka DEL End
--                       AND obj_hist.re_lease_times       = ctrct_head.re_lease_times
---- 2018/03/29 Ver1.11 Otsuka ADD Start
--                       AND (  ctrct_head.lease_type      =  cv_original                            -- 原契約
--                         OR   (ctrct_head.lease_type     =  cv_re_lease                            -- 再リース
--                           AND ctrct_head.lease_class    =  cv_lease_class_vd                      -- 自販機
--                           AND ctrct_head.re_lease_times <= 3 )                                    -- 再リース回数
--                         OR   (ctrct_head.lease_type     =  cv_re_lease                            -- 再リース
--                           AND flv.attribute7            =  cv_lease_cls_chk2))                    -- リース判定結果：2
--                       AND  ctrct_head.lease_class       =  flv.lookup_code
--                       AND  flv.lookup_type              =  cv_xxcff1_lease_class_check
---- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
--                       AND   flv.attribute7              =  gv_lease_class_att7
---- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--                       AND  flv.language                 =  USERENV('LANG')
--                       AND  flv.enabled_flag             =  cv_flg_y
--                       AND  LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
--                                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
---- 2018/03/29 Ver1.11 Otsuka ADD End
                     SELECT
                            obj_hist.object_header_id   AS object_header_id
                     FROM
                            xxcff_object_histories  obj_hist    -- リース物件履歴
                           ,fnd_lookup_values       flv         -- 参照表
                     WHERE
                            obj_hist.object_status      IN (cv_obj_move ,cv_obj_modify)  -- 移動,物件情報変更
                     AND    obj_hist.accounting_if_flag = cv_if_yet    -- 未送信
                     AND    obj_hist.accounting_date    >= TO_DATE(gv_period_name,'YYYY-MM')
                     AND    obj_hist.accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
                     AND    ( obj_hist.lease_type       =  cv_original                            -- 原契約
                       OR     ( obj_hist.lease_type     =  cv_re_lease                            -- 再リース
                         AND    obj_hist.lease_class    =  cv_lease_class_vd                      -- 自販機
                         AND    obj_hist.re_lease_times <= 3 )                                    -- 再リース回数
                       OR     ( obj_hist.lease_type     =  cv_re_lease                            -- 再リース
                         AND    flv.attribute7          =  cv_lease_cls_chk2))                    -- リース判定結果：2
                     AND    obj_hist.lease_class         =  flv.lookup_code
                     AND    flv.lookup_type              =  cv_xxcff1_lease_class_check
                     AND    flv.attribute7               =  gv_lease_class_att7
                     AND    flv.language                 =  USERENV('LANG')
                     AND    flv.enabled_flag             =  cv_flg_y
                     AND    LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
                                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
-- 2019/05/24 Ver.1.13 Y.Shoji MOD End
                     UNION ALL
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--                     SELECT
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--                     SELECT /*+ INDEX(ctrct_hist XXCFF_CONTRACT_HISTORIES_N02) INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK) */
                     SELECT
                           /*+
                              LEADING(ctrct_hist)
                              INDEX(ctrct_hist XXCFF_CONTRACT_HISTORIES_N02)
                              INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK)
                            */
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
                             ctrct_hist.object_header_id   AS object_header_id
-- 2017/03/29 Ver.1.10 Y.Shoji DEL Start
--                            ,ctrct_hist.contract_line_id   AS contract_line_id
-- 2017/03/29 Ver.1.10 Y.Shoji DEL End
                     FROM
                           xxcff_contract_headers    ctrct_head  -- リース契約
                          ,xxcff_contract_histories  ctrct_hist  -- リース契約明細履歴
-- 2018/03/29 Ver1.11 Otsuka ADD Start
                          ,fnd_lookup_values         flv         -- 参照表
-- 2018/03/29 Ver1.11 Otsuka ADD End
                     WHERE 
                           ctrct_head.contract_header_id   =  ctrct_hist.contract_header_id
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--                       AND ctrct_head.lease_type           =  cv_original                            -- 原契約
--                       AND ctrct_hist.lease_kind           IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,旧Fin
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--                       AND ( ctrct_head.lease_type           =  cv_original                            -- 原契約
--                       OR    ctrct_head.lease_type           =  cv_re_lease                            -- 再リース
--                       AND   ctrct_head.lease_class          =  cv_lease_class_vd                      -- 自販機
--                       AND   ctrct_head.re_lease_times       <= 3 )                                    -- 再リース回数
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
                       AND (   ctrct_head.lease_type       =  cv_original                           -- 原契約
                         OR   (ctrct_head.lease_type       =  cv_re_lease                           -- 再リース
                           AND ctrct_head.lease_class      =  cv_lease_class_vd                     -- 自販機
                           AND ctrct_head.re_lease_times   <= 3 )                                   -- 再リース回数
                         OR   (ctrct_head.lease_type       =  cv_re_lease                           -- 再リース
                           AND flv.attribute7              =  cv_lease_cls_chk2))                   -- リース判定結果：2
                       AND   ctrct_head.lease_class        =  flv.lookup_code
                       AND   flv.lookup_type               =  cv_xxcff1_lease_class_check
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
                       AND   flv.attribute7                =  gv_lease_class_att7
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
                       AND   flv.language                  =  USERENV('LANG')
                       AND   flv.enabled_flag              =  cv_flg_y
                       AND   LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
                                                                         AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
-- 2018/03/29 Ver1.11 Otsuka MOD End
                       AND ctrct_hist.contract_status      =  cv_ctrt_info_change                    -- 情報変更
                       AND ctrct_hist.accounting_if_flag   =  cv_if_yet                              -- 未送信
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
                       AND ctrct_hist.accounting_date      >= TO_DATE(gv_period_name,'YYYY-MM')
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
                       AND ctrct_hist.accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
                       ) lse_trnsf_hist_data -- インラインビュー(物件移動履歴・契約情報変更履歴)
              GROUP BY
                 lse_trnsf_hist_data.object_header_id
-- 2017/03/29 Ver.1.10 Y.Shoji DEL Start
--                ,lse_trnsf_hist_data.contract_line_id
-- 2017/03/29 Ver.1.10 Y.Shoji DEL End
            ) lse_trnsf_hist
      WHERE
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--            ctrct_line.contract_line_id     =  lse_trnsf_hist.contract_line_id
--        AND ctrct_line.object_header_id     =  lse_trnsf_hist.object_header_id
            ctrct_line.object_header_id     =  lse_trnsf_hist.object_header_id
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
        AND ctrct_line.object_header_id     =  obj_head.object_header_id
        AND ctrct_line.contract_header_id   =  ctrct_head.contract_header_id
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--        AND ctrct_line.lease_kind           IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,旧Fin
--        AND ctrct_line.lease_kind           =  les_kind.lease_kind_code
--        AND ctrct_head.lease_type           =  cv_original                            -- 原契約
--        AND ctrct_head.lease_class          =  les_class.lease_class_code
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--        AND ctrct_line.contract_line_id     =  faadds.attribute10
--        AND faadds.attribute10              =  TO_CHAR(ctrct_line.contract_line_id)
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
--        AND faadds.asset_id                 =  fadist_hist.asset_id
--        AND fadist_hist.book_type_code      =  les_kind.book_type_code
--        AND fadist_hist.date_ineffective    IS NULL
--        AND fadist_hist.code_combination_id =  gcc.code_combination_id
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--        AND DECODE(obj_head.owner_company
--                     ,gv_own_comp_itoen  , gv_comp_cd_itoen
--                     ,gv_own_comp_sagara , gv_comp_cd_sagara) <> gcc.segment1
--        AND obj_head.lease_class            =  flv.lookup_code
--        AND flv.lookup_type                 =  cv_xxcff1_lease_class_check
--        AND flv.language                    =  USERENV('LANG')
--        AND flv.enabled_flag                =  cv_flg_y
--        AND LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
--                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--        AND ctrct_line.lease_kind           =  les_kind.lease_kind_code
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
        AND ctrct_head.lease_class          =  les_class.lease_class_code
        AND ( ctrct_line.lease_kind         IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,旧Fin
        AND   ctrct_head.lease_type         =  cv_original                            -- 原契約
        OR  (ctrct_head.lease_type          =  cv_re_lease                            -- 再リース
        AND  flv.attribute7                 =  cv_lease_cls_chk2 ))                   -- リース判定結果：2
        AND obj_head.lease_class            =  flv.lookup_code
        AND flv.lookup_type                 =  cv_xxcff1_lease_class_check
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
        AND flv.attribute7                  =  gv_lease_class_att7
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
        AND flv.language                    =  USERENV('LANG')
        AND flv.enabled_flag                =  cv_flg_y
        AND LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))) 
        AND faadds.attribute10              =  TO_CHAR(ctrct_line.contract_line_id)
        AND faadds.asset_id                 =  fb.asset_id
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--        AND fb.book_type_code               IN (les_kind.book_type_code, les_kind.book_type_code_ifrs)
        AND fb.book_type_code               = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
        AND fb.date_ineffective             IS NULL
        AND fb.asset_id                     =  fadist_hist.asset_id
        AND fb.book_type_code               =  fadist_hist.book_type_code
        AND fadist_hist.date_ineffective    IS NULL
        AND fadist_hist.code_combination_id =  gcc.code_combination_id
-- 2018/03/29 Ver1.11 Otsuka MOD End
        ;
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
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN les_trn_trnsf_cur;
    -- データの一括取得
    FETCH les_trn_trnsf_cur
    BULK COLLECT INTO  g_contract_header_id_tab -- 契約内部ID
                      ,g_contract_line_id_tab   -- 契約明細内部ID
                      ,g_object_header_id_tab   -- 物件内部ID
                      ,g_contract_date_tab      -- リース契約日
                      ,g_department_code_tab    -- 管理部門
                      ,g_owner_company_tab      -- 本社工場区分
                      ,g_quantity_tab           -- 数量
                      ,g_lease_class_tab        -- リース種別
                      ,g_asset_number_tab       -- 資産番号
                      ,g_book_type_code_tab     -- 資産台帳名
                      ,g_deprn_acct_tab         -- 減価償却勘定
                      ,g_deprn_sub_acct_tab     -- 減価償却補助勘定
                      ,g_trnsf_from_comp_cd_tab -- 振替元会社コード
                      ,g_trnsf_to_comp_cd_tab   -- 振替先会社コード
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
                      ,g_trnsf_from_dep_cd_tab  -- 振替元管理部門
                      ,g_trnsf_from_cust_cd_tab -- 振替元顧客コード
                      ,g_customer_code_tab      -- 顧客コード
                      ,g_vd_cust_flag_tab       -- VD顧客フラグ
                      ,g_dept_tran_flg_tab      -- 部門振替フラグ
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
                      ,g_location_ccid_tab      -- 事業所CCID
                      ,g_deprn_ccid_tab         -- 減価償却費勘定CCID
-- 2018/03/29 Ver1.11 Otsuka ADD Start
                      ,g_fully_retired_tab      -- 全部除売却
-- 2018/03/29 Ver1.11 Otsuka ADD End
    ;
-- 2017/03/29 Ver.1.10 Y.Shoji DEL Start
--    -- 対象件数カウント
--    gn_les_trnsf_target_cnt := g_contract_header_id_tab.COUNT;
-- 2017/03/29 Ver.1.10 Y.Shoji DEL End
    -- カーソルクローズ
    CLOSE les_trn_trnsf_cur;
--
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--    IF ( gn_les_trnsf_target_cnt = 0 ) THEN
    IF ( g_contract_header_id_tab.COUNT = 0 ) THEN
-- 2017/03/29 Ver.1.10 Y.Shoji MOD END
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_013a20_t_032) -- リース取引（振替）情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (les_trn_trnsf_cur%ISOPEN) THEN
        CLOSE les_trn_trnsf_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (les_trn_trnsf_cur%ISOPEN) THEN
        CLOSE les_trn_trnsf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (les_trn_trnsf_cur%ISOPEN) THEN
        CLOSE les_trn_trnsf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_les_trn_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : update_ctrct_line_acct_flag
   * Description      : リース契約明細履歴 会計IFフラグ更新 (A-10)
   ***********************************************************************************/
  PROCEDURE update_ctrct_line_acct_flag(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ctrct_line_acct_flag'; -- プログラム名
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
    --リース物件履歴更新
    --==============================================================
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT
      UPDATE xxcff_object_histories
      SET
             accounting_if_flag     = cv_if_aft                 -- 会計ifフラグ 2(連携済)
            ,last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,last_update_date       = cd_last_update_date       -- 最終更新日
            ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,request_id             = cn_request_id             -- 要求ID
            ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
            ,program_id             = cn_program_id             -- コンカレントプログラムID
            ,program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE
            object_header_id     =  g_object_header_id_tab(ln_loop_cnt)
        AND object_status        =  cv_obj_move   -- 移動
        AND accounting_if_flag   =  cv_if_yet    -- 未送信
        AND accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
      ;
--
    --==============================================================
    --リース契約明細履歴更新
    --==============================================================
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
      UPDATE xxcff_contract_histories
      SET
             accounting_if_flag     = cv_if_aft                 -- 会計ifフラグ 2(連携済)
            ,last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,last_update_date       = cd_last_update_date       -- 最終更新日
            ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,request_id             = cn_request_id             -- 要求ID
            ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
            ,program_id             = cn_program_id             -- コンカレントプログラムID
            ,program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE
             contract_line_id       =  g_contract_line_id_tab(ln_loop_cnt)
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--         AND contract_status    IN (cv_ctrt_ctrt,cv_ctrt_info_change)  -- 契約,情報変更
         AND contract_status    IN (cv_ctrt_ctrt, cv_ctrt_re_lease ,cv_ctrt_info_change)  -- 契約,再リース,情報変更
-- 2018/03/29 Ver1.11 Otsuka MOD 
         AND accounting_if_flag =  cv_if_yet                           -- 未送信
         AND accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
      ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_ctrct_line_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_les_trn_add_data
   * Description      : リース取引(追加)登録 (A-9)
   ***********************************************************************************/
  PROCEDURE insert_les_trn_add_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_les_trn_add_data'; -- プログラム名
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
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    lt_deprn_method          fa_category_book_defaults.deprn_method%TYPE;     -- 償却方法
--    lt_life_in_months        fa_category_book_defaults.life_in_months%TYPE;   -- 計算月
--    -- メッセージ用文字列(契約明細内部ID)
--    lv_str_ctrt_line_id VARCHAR2(50);
--    -- メッセージ用文字列(資産カテゴリCCID)
--    lv_str_cat_ccid     VARCHAR2(50);
--    -- エラーキー情報
--    lv_error_key        VARCHAR2(5000);
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
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
    IF (gn_les_add_target_cnt > 0) THEN
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
--        INSERT INTO xxcff_fa_transactions (
--           fa_transaction_id                 -- リース取引内部ID
--          ,contract_header_id                -- 契約内部ID
--          ,contract_line_id                  -- 契約明細内部ID
--          ,object_header_id                  -- 物件内部ID
--          ,period_name                       -- 会計期間
--          ,transaction_type                  -- 取引タイプ
--          ,book_type_code                    -- 資産台帳名
--          ,description                       -- 摘要
--          ,category_id                       -- 資産カテゴリCCID
--          ,asset_category                    -- 資産種類
--          ,asset_account                     -- 資産勘定
--          ,deprn_account                     -- 償却科目
--          ,lease_class                       -- リース種別
--          ,dprn_code_combination_id          -- 減価償却費勘定CCID
--          ,location_id                       -- 事業所CCID
--          ,department_code                   -- 管理部門コード
--          ,owner_company                     -- 本社工場区分
--          ,date_placed_in_service            -- 事業供用日
--          ,original_cost                     -- 取得価額
--          ,quantity                          -- 数量
--          ,deprn_method                      -- 償却方法
--          ,payment_frequency                 -- 計算月数(支払回数)
--          ,fa_if_flag                        -- FA連携フラグ
--          ,gl_if_flag                        -- GL連携フラグ
--          ,created_by                        -- 作成者
--          ,creation_date                     -- 作成日
--          ,last_updated_by                   -- 最終更新者
--          ,last_update_date                  -- 最終更新日
--          ,last_update_login                 -- 最終更新ﾛｸﾞｲﾝ
--          ,request_id                        -- 要求ID
--          ,program_application_id            -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--          ,program_id                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--          ,program_update_date               -- ﾌﾟﾛｸﾞﾗﾑ更新日
--        )
--        VALUES (
--           xxcff_fa_transactions_s1.NEXTVAL       -- リース取引内部ID
--          ,g_contract_header_id_tab(ln_loop_cnt)  -- 契約内部ID
--          ,g_contract_line_id_tab(ln_loop_cnt)    -- 契約明細内部ID
--          ,g_object_header_id_tab(ln_loop_cnt)    -- 物件内部ID
--          ,gv_period_name                         -- 会計期間
--          ,1                                      -- 取引タイプ(追加)
--          ,g_book_type_code_tab(ln_loop_cnt)      -- 資産台帳名
--          ,g_comments_tab(ln_loop_cnt)            -- 摘要
--          ,g_category_ccid_tab(ln_loop_cnt)       -- 資産カテゴリCCID
--          ,g_asset_category_tab(ln_loop_cnt)      -- 資産種類
--          ,g_les_asset_acct_tab(ln_loop_cnt)      -- 資産勘定
--          ,g_deprn_acct_tab(ln_loop_cnt)          -- 償却科目
--          ,g_lease_class_tab(ln_loop_cnt)         -- リース種別
--          ,g_deprn_ccid_tab(ln_loop_cnt)          -- 減価償却費勘定CCID
--          ,g_location_ccid_tab(ln_loop_cnt)       -- 事業所CCID
--          ,g_department_code_tab(ln_loop_cnt)     -- 管理部門コード
--          ,g_owner_company_tab(ln_loop_cnt)       -- 本社工場区分
--          ,g_contract_date_tab(ln_loop_cnt)       -- 事業供用日
--          ,g_original_cost_tab(ln_loop_cnt)       -- 取得価額
--          ,g_quantity_tab(ln_loop_cnt)            -- 数量
--          ,g_deprn_method_tab(ln_loop_cnt)        -- 償却方法
--          ,g_payment_frequency_tab(ln_loop_cnt)   -- 計算月数(支払回数)
--          ,cv_if_yet                              -- FA連携フラグ
--          ,cv_if_yet                              -- GL連携フラグ
--          ,cn_created_by                          -- 作成者
--          ,cd_creation_date                       -- 作成日
--          ,cn_last_updated_by                     -- 最終更新者
--          ,cd_last_update_date                    -- 最終更新日
--          ,cn_last_update_login                   -- 最終更新ﾛｸﾞｲﾝ
--          ,cn_request_id                          -- 要求ID
--          ,cn_program_application_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--          ,cn_program_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--          ,cd_program_update_date                 -- ﾌﾟﾛｸﾞﾗﾑ更新日
--        );
----
--       --成功件数カウント
--       gn_les_add_normal_cnt := SQL%ROWCOUNT;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--      <<inert_loop>>
--      FOR ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT LOOP
--        -- 日本基準連携の場合
--        IF (g_fin_coop_tab(ln_loop_cnt) = cv_flg_y) THEN
--          BEGIN
--            SELECT
--               cat_deflt.deprn_method   AS deprn_method     -- 償却方法
--              ,cat_deflt.life_in_months AS life_in_months   -- 計算月数
--            INTO
--               lt_deprn_method                     -- 償却方法
--              ,lt_life_in_months                   -- 計算月数
--            FROM
--              fa_categories_b            cat       -- 資産カテゴリマスタ
--             ,fa_category_book_defaults  cat_deflt -- 資産カテゴリ償却基準
--            WHERE
--                 cat.category_id           = g_category_ccid_tab(ln_loop_cnt)
--            AND  cat.category_id           = cat_deflt.category_id
--            AND  cat_deflt.book_type_code  = gv_fin_lease_books
--            AND  cat_deflt.start_dpis     <= g_contract_date_tab(ln_loop_cnt)
--            AND  NVL(cat_deflt.end_dpis,
--                    g_contract_date_tab(ln_loop_cnt))  >= g_contract_date_tab(ln_loop_cnt)
--            ;
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              --メッセージ用文字列取得
--              lv_str_ctrt_line_id := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                                      ,cv_msg_013a20_t_027) -- トークン(契約明細内部ID)
--                                                                      ,1
--                                                                      ,5000);
--              lv_str_cat_ccid := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                                  ,cv_msg_013a20_t_028) -- トークン(資産カテゴリCCID)
--                                                                  ,1
--                                                                  ,5000);
--              --エラーキー情報作成(文字列結合)
--              lv_error_key :=         lv_str_ctrt_line_id ||'='|| g_contract_line_id_tab(ln_loop_cnt)
--                        ||','|| lv_str_cat_ccid     ||'='|| g_category_ccid_tab(ln_loop_cnt);
----
--              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                            ,cv_msg_013a20_m_013  -- 償却方法取得エラー
--                                                            ,cv_tkn_table         -- トークン'TABLE_NAME'
--                                                            ,cv_msg_013a20_t_026  -- 償却方法
--                                                            ,cv_tkn_info          -- トークン'INFO'
--                                                            ,lv_error_key)        -- エラーキー情報
--                                                            ,1
--                                                            ,5000);
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--          END;
----
--          INSERT INTO xxcff_fa_transactions (
--             fa_transaction_id                 -- リース取引内部ID
--            ,contract_header_id                -- 契約内部ID
--            ,contract_line_id                  -- 契約明細内部ID
--            ,object_header_id                  -- 物件内部ID
--            ,period_name                       -- 会計期間
--            ,transaction_type                  -- 取引タイプ
--            ,book_type_code                    -- 資産台帳名
--            ,description                       -- 摘要
--            ,category_id                       -- 資産カテゴリCCID
--            ,asset_category                    -- 資産種類
--            ,asset_account                     -- 資産勘定
--            ,deprn_account                     -- 償却科目
--            ,lease_class                       -- リース種別
--            ,dprn_code_combination_id          -- 減価償却費勘定CCID
--            ,location_id                       -- 事業所CCID
--            ,department_code                   -- 管理部門コード
--            ,owner_company                     -- 本社工場区分
--            ,date_placed_in_service            -- 事業供用日
--            ,original_cost                     -- 取得価額
--            ,quantity                          -- 数量
--            ,deprn_method                      -- 償却方法
--            ,payment_frequency                 -- 計算月数(支払回数)
--            ,fa_if_flag                        -- FA連携フラグ
--            ,gl_if_flag                        -- GL連携フラグ
--            ,created_by                        -- 作成者
--            ,creation_date                     -- 作成日
--            ,last_updated_by                   -- 最終更新者
--            ,last_update_date                  -- 最終更新日
--            ,last_update_login                 -- 最終更新ﾛｸﾞｲﾝ
--            ,request_id                        -- 要求ID
--            ,program_application_id            -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--            ,program_id                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--            ,program_update_date               -- ﾌﾟﾛｸﾞﾗﾑ更新日
--          )
--          VALUES (
--             xxcff_fa_transactions_s1.NEXTVAL       -- リース取引内部ID
--            ,g_contract_header_id_tab(ln_loop_cnt)  -- 契約内部ID
--            ,g_contract_line_id_tab(ln_loop_cnt)    -- 契約明細内部ID
--            ,g_object_header_id_tab(ln_loop_cnt)    -- 物件内部ID
--            ,gv_period_name                         -- 会計期間
--            ,1                                      -- 取引タイプ(追加)
--            ,gv_fin_lease_books                     -- FINリース台帳
--            ,g_comments_tab(ln_loop_cnt)            -- 摘要
--            ,g_category_ccid_tab(ln_loop_cnt)       -- 資産カテゴリCCID
--            ,g_asset_category_tab(ln_loop_cnt)      -- 資産種類
--            ,g_les_asset_acct_tab(ln_loop_cnt)      -- 資産勘定
--            ,g_deprn_acct_tab(ln_loop_cnt)          -- 償却科目
--            ,g_lease_class_tab(ln_loop_cnt)         -- リース種別
--            ,g_deprn_ccid_tab(ln_loop_cnt)          -- 減価償却費勘定CCID
--            ,g_location_ccid_tab(ln_loop_cnt)       -- 事業所CCID
--            ,g_department_code_tab(ln_loop_cnt)     -- 管理部門コード
--            ,g_owner_company_tab(ln_loop_cnt)       -- 本社工場区分
--            ,g_contract_date_tab(ln_loop_cnt)       -- 事業供用日
--            ,g_original_cost_tab(ln_loop_cnt)       -- 取得価額
--            ,g_quantity_tab(ln_loop_cnt)            -- 数量
--            ,lt_deprn_method                        -- 償却方法
--            ,lt_life_in_months                      -- 計算月数
--            ,cv_if_yet                              -- FA連携フラグ
--            ,cv_if_yet                              -- GL連携フラグ
--            ,cn_created_by                          -- 作成者
--            ,cd_creation_date                       -- 作成日
--            ,cn_last_updated_by                     -- 最終更新者
--            ,cd_last_update_date                    -- 最終更新日
--            ,cn_last_update_login                   -- 最終更新ﾛｸﾞｲﾝ
--            ,cn_request_id                          -- 要求ID
--            ,cn_program_application_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--            ,cn_program_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--            ,cd_program_update_date                 -- ﾌﾟﾛｸﾞﾗﾑ更新日
--          );
--            --成功件数カウント
--            gn_les_add_normal_cnt := gn_les_add_normal_cnt + 1;
--        END IF;
----
--        -- IFRS連携の場合
--        IF (g_ifrs_coop_tab(ln_loop_cnt) = cv_flg_y) THEN
--          BEGIN
--            SELECT
--               cat_deflt.deprn_method   AS deprn_method     -- 償却方法
--              ,cat_deflt.life_in_months AS life_in_months   -- 計算月数
--            INTO
--               lt_deprn_method                     -- 償却方法
--              ,lt_life_in_months                   -- 計算月数
--            FROM
--              fa_categories_b            cat       -- 資産カテゴリマスタ
--             ,fa_category_book_defaults  cat_deflt -- 資産カテゴリ償却基準
--            WHERE
--                 cat.category_id           = g_category_ccid_tab(ln_loop_cnt)
--            AND  cat.category_id           = cat_deflt.category_id
--            AND  cat_deflt.book_type_code  = gv_ifrs_lease_books
--            AND  cat_deflt.start_dpis     <= g_contract_date_tab(ln_loop_cnt)
--            AND  NVL(cat_deflt.end_dpis,
--                    g_contract_date_tab(ln_loop_cnt))  >= g_contract_date_tab(ln_loop_cnt)
--            ;
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              --メッセージ用文字列取得
--              lv_str_ctrt_line_id := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                                ,cv_msg_013a20_t_027) -- トークン(契約明細内部ID)
--                                                                ,1
--                                                                ,5000);
--              lv_str_cat_ccid := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                            ,cv_msg_013a20_t_028) -- トークン(資産カテゴリCCID)
--                                                            ,1
--                                                            ,5000);
--              --エラーキー情報作成(文字列結合)
--              lv_error_key :=         lv_str_ctrt_line_id ||'='|| g_contract_line_id_tab(ln_loop_cnt)
--                        ||','|| lv_str_cat_ccid     ||'='|| g_category_ccid_tab(ln_loop_cnt);
----
--              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                      ,cv_msg_013a20_m_013  -- 償却方法取得エラー
--                                                      ,cv_tkn_table         -- トークン'TABLE_NAME'
--                                                      ,cv_msg_013a20_t_026  -- 償却方法
--                                                      ,cv_tkn_info          -- トークン'INFO'
--                                                      ,lv_error_key)        -- エラーキー情報
--                                                      ,1
--                                                      ,5000);
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--          END;
----
--          INSERT INTO xxcff_fa_transactions (
--             fa_transaction_id                 -- リース取引内部ID
--            ,contract_header_id                -- 契約内部ID
--            ,contract_line_id                  -- 契約明細内部ID
--            ,object_header_id                  -- 物件内部ID
--            ,period_name                       -- 会計期間
--            ,transaction_type                  -- 取引タイプ
--            ,book_type_code                    -- 資産台帳名
--            ,description                       -- 摘要
--            ,category_id                       -- 資産カテゴリCCID
--            ,asset_category                    -- 資産種類
--            ,asset_account                     -- 資産勘定
--            ,deprn_account                     -- 償却科目
--            ,lease_class                       -- リース種別
--            ,dprn_code_combination_id          -- 減価償却費勘定CCID
--            ,location_id                       -- 事業所CCID
--            ,department_code                   -- 管理部門コード
--            ,owner_company                     -- 本社工場区分
--            ,date_placed_in_service            -- 事業供用日
--            ,original_cost                     -- 取得価額
--            ,quantity                          -- 数量
--            ,deprn_method                      -- 償却方法
--            ,payment_frequency                 -- 計算月数(支払回数)
--            ,fa_if_flag                        -- FA連携フラグ
--            ,gl_if_flag                        -- GL連携フラグ
--            ,created_by                        -- 作成者
--            ,creation_date                     -- 作成日
--            ,last_updated_by                   -- 最終更新者
--            ,last_update_date                  -- 最終更新日
--            ,last_update_login                 -- 最終更新ﾛｸﾞｲﾝ
--            ,request_id                        -- 要求ID
--            ,program_application_id            -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--            ,program_id                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--            ,program_update_date               -- ﾌﾟﾛｸﾞﾗﾑ更新日
--          )
--          VALUES (
--             xxcff_fa_transactions_s1.NEXTVAL       -- リース取引内部ID
--            ,g_contract_header_id_tab(ln_loop_cnt)  -- 契約内部ID
--            ,g_contract_line_id_tab(ln_loop_cnt)    -- 契約明細内部ID
--            ,g_object_header_id_tab(ln_loop_cnt)    -- 物件内部ID
--            ,gv_period_name                         -- 会計期間
--            ,1                                      -- 取引タイプ(追加)
--            ,gv_ifrs_lease_books                    -- IFRSリース台帳
--            ,g_comments_tab(ln_loop_cnt)            -- 摘要
--            ,g_category_ccid_tab(ln_loop_cnt)       -- 資産カテゴリCCID
--            ,g_asset_category_tab(ln_loop_cnt)      -- 資産種類
--            ,g_les_asset_acct_tab(ln_loop_cnt)      -- 資産勘定
--            ,g_deprn_acct_tab(ln_loop_cnt)          -- 償却科目
--            ,g_lease_class_tab(ln_loop_cnt)         -- リース種別
--            ,g_deprn_ccid_tab(ln_loop_cnt)          -- 減価償却費勘定CCID
--            ,g_location_ccid_tab(ln_loop_cnt)       -- 事業所CCID
--            ,g_department_code_tab(ln_loop_cnt)     -- 管理部門コード
--            ,g_owner_company_tab(ln_loop_cnt)       -- 本社工場区分
--            ,g_contract_date_tab(ln_loop_cnt)       -- 事業供用日
--            ,g_original_cost_tab(ln_loop_cnt)       -- 取得価額
--            ,g_quantity_tab(ln_loop_cnt)            -- 数量
--            ,lt_deprn_method                        -- 償却方法
--            ,lt_life_in_months                      -- 計算月数
--            ,cv_if_yet                              -- FA連携フラグ
--            ,cv_if_yet                              -- GL連携フラグ
--            ,cn_created_by                          -- 作成者
--            ,cd_creation_date                       -- 作成日
--            ,cn_last_updated_by                     -- 最終更新者
--            ,cd_last_update_date                    -- 最終更新日
--            ,cn_last_update_login                   -- 最終更新ﾛｸﾞｲﾝ
--            ,cn_request_id                          -- 要求ID
--            ,cn_program_application_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--            ,cn_program_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--            ,cd_program_update_date                 -- ﾌﾟﾛｸﾞﾗﾑ更新日
--          );
--          --成功件数カウント
--          gn_les_add_ifrs_cnt := gn_les_add_ifrs_cnt + 1;
--        END IF;
--      END LOOP;
---- 2018/03/29 Ver1.11 Otsuka MOD End
      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
        INSERT INTO xxcff_fa_transactions (
           fa_transaction_id                 -- リース取引内部ID
          ,contract_header_id                -- 契約内部ID
          ,contract_line_id                  -- 契約明細内部ID
          ,object_header_id                  -- 物件内部ID
          ,period_name                       -- 会計期間
          ,transaction_type                  -- 取引タイプ
          ,book_type_code                    -- 資産台帳名
          ,description                       -- 摘要
          ,category_id                       -- 資産カテゴリCCID
          ,asset_category                    -- 資産種類
          ,asset_account                     -- 資産勘定
          ,deprn_account                     -- 償却科目
          ,lease_class                       -- リース種別
          ,dprn_code_combination_id          -- 減価償却費勘定CCID
          ,location_id                       -- 事業所CCID
          ,department_code                   -- 管理部門コード
          ,owner_company                     -- 本社工場区分
          ,date_placed_in_service            -- 事業供用日
          ,original_cost                     -- 取得価額
          ,quantity                          -- 数量
          ,deprn_method                      -- 償却方法
          ,payment_frequency                 -- 計算月数(支払回数)
          ,fa_if_flag                        -- FA連携フラグ
          ,gl_if_flag                        -- GL連携フラグ
          ,created_by                        -- 作成者
          ,creation_date                     -- 作成日
          ,last_updated_by                   -- 最終更新者
          ,last_update_date                  -- 最終更新日
          ,last_update_login                 -- 最終更新ﾛｸﾞｲﾝ
          ,request_id                        -- 要求ID
          ,program_application_id            -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          ,program_id                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          ,program_update_date               -- ﾌﾟﾛｸﾞﾗﾑ更新日
        )
        VALUES (
           xxcff_fa_transactions_s1.NEXTVAL       -- リース取引内部ID
          ,g_contract_header_id_tab(ln_loop_cnt)  -- 契約内部ID
          ,g_contract_line_id_tab(ln_loop_cnt)    -- 契約明細内部ID
          ,g_object_header_id_tab(ln_loop_cnt)    -- 物件内部ID
          ,gv_period_name                         -- 会計期間
          ,1                                      -- 取引タイプ(追加)
          ,gv_book_type_code                      -- 資産台帳名
          ,g_comments_tab(ln_loop_cnt)            -- 摘要
          ,g_category_ccid_tab(ln_loop_cnt)       -- 資産カテゴリCCID
          ,g_asset_category_tab(ln_loop_cnt)      -- 資産種類
          ,g_les_asset_acct_tab(ln_loop_cnt)      -- 資産勘定
          ,g_deprn_acct_tab(ln_loop_cnt)          -- 償却科目
          ,g_lease_class_tab(ln_loop_cnt)         -- リース種別
          ,g_deprn_ccid_tab(ln_loop_cnt)          -- 減価償却費勘定CCID
          ,g_location_ccid_tab(ln_loop_cnt)       -- 事業所CCID
          ,g_department_code_tab(ln_loop_cnt)     -- 管理部門コード
          ,g_owner_company_tab(ln_loop_cnt)       -- 本社工場区分
          ,g_contract_date_tab(ln_loop_cnt)       -- 事業供用日
          ,g_original_cost_tab(ln_loop_cnt)       -- 取得価額
          ,g_quantity_tab(ln_loop_cnt)            -- 数量
          ,g_deprn_method_tab(ln_loop_cnt)        -- 償却方法
          ,g_payment_frequency_tab(ln_loop_cnt)   -- 計算月数(支払回数)
          ,cv_if_yet                              -- FA連携フラグ
          ,cv_if_yet                              -- GL連携フラグ
          ,cn_created_by                          -- 作成者
          ,cd_creation_date                       -- 作成日
          ,cn_last_updated_by                     -- 最終更新者
          ,cd_last_update_date                    -- 最終更新日
          ,cn_last_update_login                   -- 最終更新ﾛｸﾞｲﾝ
          ,cn_request_id                          -- 要求ID
          ,cn_program_application_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          ,cn_program_id                          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          ,cd_program_update_date                 -- ﾌﾟﾛｸﾞﾗﾑ更新日
        );
--
       --成功件数カウント
       gn_les_add_normal_cnt := SQL%ROWCOUNT;
--
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_les_trn_add_data;
--
  /**********************************************************************************
   * Procedure Name   : get_deprn_method
   * Description      : 償却方法取得 (A-8)
   ***********************************************************************************/
  PROCEDURE get_deprn_method(
     it_contract_line_id   IN  xxcff_contract_histories.contract_line_id%TYPE  -- 1.契約明細ID
    ,it_category_ccid      IN  fa_categories.category_id%TYPE                  -- 2.資産カテゴリCCID
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    ,it_lease_kind         IN  xxcff_contract_histories.lease_kind%TYPE        -- 3.リース種類
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
    ,it_contract_date      IN  xxcff_contract_headers.contract_date%TYPE       -- 4.リース契約日
    ,ot_deprn_method       OUT fa_category_book_defaults.deprn_method%TYPE     -- 5.償却方法
-- T1_0759 2009/04/23 ADD START --
    ,ot_life_in_months     OUT fa_category_book_defaults.life_in_months%TYPE   -- 6.計算月数
-- T1_0759 2009/04/23 ADD END   --
    ,ov_errbuf             OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode            OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg             OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deprn_method'; -- プログラム名
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
    -- メッセージ用文字列(契約明細内部ID)
    lv_str_ctrt_line_id VARCHAR2(50);
    -- メッセージ用文字列(資産カテゴリCCID)
    lv_str_cat_ccid     VARCHAR2(50);
    -- エラーキー情報
    lv_error_key        VARCHAR2(5000);
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    -- 資産台帳名
--    lt_book_type_code xxcff_lease_kind_v.book_type_code%TYPE;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
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
    BEGIN
      SELECT
             cat_deflt.deprn_method   AS deprn_method     -- 償却方法
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--            ,les_kind.book_type_code  AS book_type_code   -- 資産台帳名
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- T1_0759 2009/04/23 ADD START --
            ,cat_deflt.life_in_months AS life_in_months   -- 計算月数
-- T1_0759 2009/04/23 ADD END   --
      INTO
             ot_deprn_method                     -- 償却方法
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--            ,lt_book_type_code                   -- 資産台帳名
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- T1_0759 2009/04/23 ADD START --
            ,ot_life_in_months                   -- 計算月数
-- T1_0759 2009/04/23 ADD END   --
      FROM
             fa_categories_b            cat       -- 資産カテゴリマスタ
            ,fa_category_book_defaults  cat_deflt -- 資産カテゴリ償却基準
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--            ,xxcff_lease_kind_v         les_kind  -- リース種類ビュー
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
      WHERE
             cat.category_id           = it_category_ccid
        AND  cat.category_id           = cat_deflt.category_id
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--        AND  cat_deflt.book_type_code  = les_kind.book_type_code
--        AND  les_kind.lease_kind_code  = it_lease_kind
        AND  cat_deflt.book_type_code  = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
        AND  cat_deflt.start_dpis     <= it_contract_date
        AND  NVL(cat_deflt.end_dpis,
                   it_contract_date)  >= it_contract_date
        ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --メッセージ用文字列取得
        lv_str_ctrt_line_id := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                                ,cv_msg_013a20_t_027) -- トークン(契約明細内部ID)
                                                                ,1
                                                                ,5000);
        lv_str_cat_ccid := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                            ,cv_msg_013a20_t_028) -- トークン(資産カテゴリCCID)
                                                            ,1
                                                            ,5000);
        --エラーキー情報作成(文字列結合)
        lv_error_key :=         lv_str_ctrt_line_id ||'='|| it_contract_line_id
                        ||','|| lv_str_cat_ccid     ||'='|| it_category_ccid;
--
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_013a20_m_013  -- 償却方法取得エラー
                                                      ,cv_tkn_table         -- トークン'TABLE_NAME'
                                                      ,cv_msg_013a20_t_026  -- 償却方法
                                                      ,cv_tkn_info          -- トークン'INFO'
                                                      ,lv_error_key)        -- エラーキー情報
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_deprn_method;
--
  /**********************************************************************************
   * Procedure Name   : proc_les_trn_add_data（ループ部）
   * Description      : リース取引(追加)データ処理 (A-5)～(A-10)
   ***********************************************************************************/
  PROCEDURE proc_les_trn_add_data(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード                    --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_les_trn_add_data'; -- プログラム名
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
-- T1_0759 2009/04/23 ADD START --
    ln_lease_period  NUMBER(4);
-- T1_0759 2009/04/23 ADD END   --
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
    lt_m_owner_company    xxcff_object_histories.m_owner_company%TYPE;   -- 移動元本社/工場
    lt_m_department_code  xxcff_object_histories.m_department_code%TYPE; -- 移動元管理部門
    lt_customer_code      xxcff_object_histories.customer_code%TYPE;     -- 修正前顧客コード
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2018/03/29 Ver1.11 Otsuka ADD Start
    lv_lease_class VARCHAR2(2);    -- リース種別
-- 2018/03/29 Ver1.11 Otsuka ADD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    lt_life_in_months   fa_category_book_defaults.life_in_months%TYPE;
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --==============================================================
    --メインループ処理①
    --==============================================================
    <<les_trn_add_loop>>
    FOR ln_loop_cnt IN 1 .. g_contract_header_id_tab.COUNT LOOP
--
      --==============================================================
      --資産カテゴリCCID取得 (A-5)
      --==============================================================
-- T1_0759 2009/04/23 ADD START --
      --リース期間を算出する
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--      ln_lease_period := g_payment_frequency_tab(ln_loop_cnt)  / cv_months;
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--      IF (g_lease_class_tab(ln_loop_cnt) = cv_lease_class_vd) THEN
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--      --リース区分が’再リース’でかつ、リース判別結果が'2'である場合は、頻度を確認し、
--      -- 「年」指定の場合はエラーとする。
--      IF  ( g_lease_type_tab(ln_loop_cnt) = cv_re_lease
--        AND g_lease_cls_chk_tab(ln_loop_cnt) = cv_lease_cls_chk2 ) THEN
--        AND gv_lease_class_att7 = cv_lease_cls_chk2 ) THEN
--        --「月」指定の場合
--        IF (g_payment_type_tab(ln_loop_cnt) = cv_payment_type0 ) THEN
--          ln_lease_period := g_payment_frequency_tab(ln_loop_cnt)  / cv_months;
--        --「年」指定の場合エラー
--        ELSE
--          lv_lease_class := g_lease_class_tab(ln_loop_cnt);
--          RAISE payment_type_expt;
--        END IF;
--      -- 原契約で自販機の場合
--      ELSIF (g_lease_class_tab(ln_loop_cnt) = cv_lease_class_vd) THEN
      -- 自販機の場合
      IF (g_lease_class_tab(ln_loop_cnt) = cv_lease_class_vd) THEN
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2018/03/29 Ver1.11 Otsuka MOD End
        ln_lease_period := 8;
      -- 自販機以外の場合
      ELSE
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--        ln_lease_period := g_payment_frequency_tab(ln_loop_cnt)  / cv_months;
        -- 支払回数を年数で取得、割り切れない場合切り上げ
        ln_lease_period := CEIL(g_payment_frequency_tab(ln_loop_cnt)  / cv_months);
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
      END IF;
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
-- T1_0759 2009/04/23 ADD END   --
      xxcff_common1_pkg.chk_fa_category(
         iv_segment1      => g_asset_category_tab(ln_loop_cnt) -- 資産種類
-- T1_1428 MOD START 2009/06/16 Ver1.5 by Yuuki Nakamura
--      ,iv_segment3      => g_les_asset_acct_tab(ln_loop_cnt) -- 資産勘定
        ,iv_segment3      => NULL                              -- 資産勘定
-- T1_1428 MOD END 2009/06/16 Ver1.5 by Yuuki Nakamura
        ,iv_segment4      => g_deprn_acct_tab(ln_loop_cnt)     -- 償却科目
-- T1_0759 2009/04/23 MOD START --
--      ,iv_segment5      => g_life_in_months_tab(ln_loop_cnt) -- 耐用年数
        ,iv_segment5      => ln_lease_period                   -- リース期間
-- T1_0759 2009/04/23 MOD END   --
        ,iv_segment7      => g_lease_class_tab(ln_loop_cnt)    -- リース種別
        ,on_category_id   => g_category_ccid_tab(ln_loop_cnt)  -- 資産カテゴリCCID
        ,ov_errbuf        => lv_errbuf                         -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode       => lv_retcode                        -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg                         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --事業所CCID取得 (A-6)
      --==============================================================
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
      -- 物件履歴取得
      get_obj_hist_data(
         it_object_header_id   => g_object_header_id_tab(ln_loop_cnt) -- 1.物件ID
        ,ot_m_owner_company    => lt_m_owner_company                  -- 2.移動元本社/工場
        ,ot_m_department_code  => lt_m_department_code                -- 3.移動元管理部門
        ,ot_customer_code      => lt_customer_code                    -- 4.顧客コード
        ,ov_errbuf             => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode            => lv_retcode                          -- リターン・コード             --# 固定 #
        ,ov_errmsg             => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- 該当の履歴が存在する場合
      g_department_code_tab(ln_loop_cnt) := NVL(lt_m_department_code ,g_department_code_tab(ln_loop_cnt));
      g_owner_company_tab(ln_loop_cnt)   := NVL(lt_m_owner_company   ,g_owner_company_tab(ln_loop_cnt));
      g_customer_code_tab(ln_loop_cnt)   := NVL(lt_customer_code     ,g_customer_code_tab(ln_loop_cnt));
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
      xxcff_common1_pkg.chk_fa_location(
         iv_segment2      => g_department_code_tab(ln_loop_cnt) -- 管理部門
        ,iv_segment5      => g_owner_company_tab(ln_loop_cnt)   -- 本社工場区分
        ,on_location_id   => g_location_ccid_tab(ln_loop_cnt)   -- 事業所CCID
        ,ov_errbuf        => lv_errbuf                          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode       => lv_retcode                         -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg                          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --減価償却費勘定CCID取得 (A-7)
      --==============================================================
--
      -- セグメント値配列設定(SEG1:会社)
      IF g_owner_company_tab(ln_loop_cnt) = gv_own_comp_itoen THEN
        -- 本社コード設定
        g_segments_tab(1) := gv_comp_cd_itoen;
      ELSE
        -- 工場コード設定
        g_segments_tab(1) := gv_comp_cd_sagara;
      END IF;
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
      -- セグメント値配列設定(SEG2:部門コード)
      -- 部門振替フラグが'Y'の時
      IF ( g_dept_tran_flg_tab(ln_loop_cnt) = cv_flg_y ) THEN
        -- 管理部門
        g_segments_tab(2) := g_department_code_tab(ln_loop_cnt);
      -- 部門振替フラグが'Y'以外の時
      ELSE
        -- XXCFF: 部門コード_調整部門
        g_segments_tab(2) := gv_dep_cd_chosei;
      END IF;
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
      -- セグメント値配列設定(SEG3:勘定科目)
      g_segments_tab(3) := g_deprn_acct_tab(ln_loop_cnt);
      -- セグメント値配列設定(SEG4:補助科目)
      g_segments_tab(4) := g_deprn_sub_acct_tab(ln_loop_cnt);
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
      -- セグメント値配列設定(SEG5:顧客コード)
      -- VD顧客フラグが'Y'の時
      IF ( g_vd_cust_flag_tab(ln_loop_cnt) = cv_flg_y ) THEN
        -- 顧客コード
        g_segments_tab(5) := g_customer_code_tab(ln_loop_cnt);
      -- VD顧客フラグが'Y'以外の時
      ELSE
        -- XXCFF: 顧客コード_定義なし
        g_segments_tab(5) := gv_ptnr_cd_dammy;
      END IF;
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
      -- 減価償却費勘定CCID取得
      get_deprn_ccid(
         iot_segments     => g_segments_tab                  -- セグメント値配列
        ,ot_deprn_ccid    => g_deprn_ccid_tab(ln_loop_cnt)   -- 減価償却費勘定CCID
        ,ov_errbuf        => lv_errbuf                       -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode       => lv_retcode                      -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --償却方法取得 (A-8)
      --==============================================================
-- 2018/03/29 Ver1.11 Otsuka DEL Start
--      get_deprn_method(
--         it_contract_line_id  => g_contract_line_id_tab(ln_loop_cnt)  -- 契約明細内部ID
--        ,it_category_ccid     => g_category_ccid_tab(ln_loop_cnt)     -- 資産カテゴリCCID
--        ,it_lease_kind        => g_lease_kind_tab(ln_loop_cnt)        -- リース種類
--        ,it_contract_date     => g_contract_date_tab(ln_loop_cnt)     -- リース契約日
--        ,ot_deprn_method      => g_deprn_method_tab(ln_loop_cnt)      -- 償却方法
-- T1_0759 2009/04/23 ADD START --
--        ,ot_life_in_months    => g_payment_frequency_tab(ln_loop_cnt) -- 計算月数
-- T1_0759 2009/04/23 ADD END   --
--        ,ov_errbuf            => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
--        ,ov_retcode           => lv_retcode                          -- リターン・コード             --# 固定 #
--        ,ov_errmsg            => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      IF (lv_retcode <> ov_retcode) THEN
--        RAISE global_api_expt;
--      END IF;
-- 2018/03/29 Ver1.11 Otsuka DEL End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
      get_deprn_method(
         it_contract_line_id  => g_contract_line_id_tab(ln_loop_cnt)  -- 契約明細内部ID
        ,it_category_ccid     => g_category_ccid_tab(ln_loop_cnt)     -- 資産カテゴリCCID
        ,it_contract_date     => g_contract_date_tab(ln_loop_cnt)     -- リース契約日
        ,ot_deprn_method      => g_deprn_method_tab(ln_loop_cnt)      -- 償却方法
        ,ot_life_in_months    => lt_life_in_months                    -- 計算月数
        ,ov_errbuf            => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode           => lv_retcode                          -- リターン・コード             --# 固定 #
        ,ov_errmsg            => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    -- IFRS台帳以外の場合
    IF ( gv_book_type_code <> gv_ifrs_lease_books ) THEN
      g_payment_frequency_tab(ln_loop_cnt) := lt_life_in_months;
    END IF;
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
    END LOOP les_trn_add_loop;
--
    -- =========================================
    -- リース取引(追加)登録 (A-9)
    -- =========================================
    insert_les_trn_add_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- =========================================
    -- リース契約明細履歴 会計IFフラグ更新 (A-10)
    -- =========================================
    update_ctrct_line_acct_flag(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
-- 2018/03/29 Ver1.11 Otsuka ADD Start
    -- *** 頻度チェックエラーハンドラ ***
    WHEN payment_type_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_019  -- 頻度指定チェックエラー
                                                    ,cv_tkn_ls_cls        -- トークン'LEASE_CLASS'
                                                    ,lv_lease_class )     -- リース種別
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- 2018/03/29 Ver1.11 Otsuka ADD End
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_les_trn_add_data;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_add_data
   * Description      : リース取引(追加)登録データ抽出 (A-4)
   ***********************************************************************************/
  PROCEDURE get_les_trn_add_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_add_data'; -- プログラム名
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース取引(追加)カーソル
    CURSOR les_trn_add_cur
    IS
      SELECT
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--             /*+ LEADING(ctrct_hist ctrct_head obj_head)
--                 USE_NL(ctrct_hist ctrct_head obj_head les_class.ffvs les_class.ffv les_class.ffvt) */
             /*+ LEADING(ctrct_hist ctrct_head)
                 USE_NL(ctrct_hist ctrct_head obj_head)
                 USE_NL(obj_head les_class.ffvs les_class.ffv les_class.ffvt)
                 INDEX(ctrct_hist XXCFF_CONTRACT_HISTORIES_N02)
                 INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK)
                 INDEX(obj_head XXCFF_OBJECT_HEADERS_PK)
                 INDEX(les_class.ffv FND_FLEX_VALUES_N1) */
-- 2018/03/29 Ver1.11 Otsuka MOD End
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
             ctrct_hist.contract_header_id AS contract_header_id  -- 契約内部ID
            ,ctrct_hist.contract_line_id   AS contract_line_id    -- 契約明細内部ID
            ,obj_head.object_header_id     AS object_header_id    -- 物件内部ID
            ,ctrct_hist.history_num        AS history_num         -- 変更履歴No
            ,ctrct_head.lease_class        AS lease_class         -- リース種別
            ,ctrct_hist.lease_kind         AS lease_kind          -- リース種類
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--            ,les_kind.book_type_code       AS book_type_code      -- 資産台帳名
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
            ,ctrct_hist.asset_category     AS asset_category      -- 資産種類
            ,ctrct_head.comments           AS comments            -- 件名
            ,ctrct_head.payment_years      AS payment_years       -- 年数(リース期間)
            ,ctrct_hist.life_in_months     AS life_in_months      -- 法定耐用年数
-- T1_0893 2009/05/29 MOD START --
--          ,ctrct_head.contract_date      AS contract_date       -- リース契約日
            ,ctrct_head.lease_start_date   AS contract_date       -- リース開始日
-- T1_0893 2009/05/29 MOD END   --
            ,ctrct_hist.original_cost      AS original_cost       -- 取得価格
            ,1                             AS quantity            -- 数量
            ,obj_head.department_code      AS department_code     -- 管理部門
            ,obj_head.owner_company        AS owner_company       -- 本社工場区分
            ,les_class.les_asset_acct      AS les_asset_acct      -- 資産勘定
            ,les_class.deprn_acct          AS deprn_acct          -- 減価償却勘定
            ,les_class.deprn_sub_acct      AS deprn_sub_acct      -- 減価償却補助勘定
            ,ctrct_head.payment_frequency  AS payment_frequency   -- 支払回数
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
            ,obj_head.customer_code        AS customer_code       -- 顧客コード
            ,les_class.vd_cust_flag        AS vd_cust_flag        -- VD顧客フラグ
            ,flv.attribute1                AS dept_tran_flg       -- 部門振替フラグ
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
            ,NULL                          AS category_ccid       -- 資産カテゴリCCID
            ,NULL                          AS location_ccid       -- 事業所CCID
            ,NULL                          AS deprn_ccid          -- 減価償却費勘定CCID
            ,NULL                          AS deprn_method        -- 償却方法
-- 2018/03/29 Ver1.11 Otsuka ADD Start
            ,ctrct_head.lease_type         AS lease_type          -- リースタイプ
            ,ctrct_head.payment_type       AS payment_type        -- 頻度(0:「月」、1:「年」）
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--            ,flv.attribute4                AS fin_coop            -- 日本基準連携
--            ,flv.attribute5                AS ifrs_coop           -- IFRS連携
--            ,flv.attribute7                AS lease_cls_chk       -- リース判別結果
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
      FROM
            xxcff_contract_histories  ctrct_hist
           ,xxcff_contract_headers    ctrct_head
           ,xxcff_object_headers      obj_head
           ,xxcff_lease_class_v       les_class
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--           ,xxcff_lease_kind_v        les_kind
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
           ,fnd_lookup_values         flv           -- 参照表
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
      WHERE
            ctrct_hist.object_header_id   =   obj_head.object_header_id
        AND ctrct_head.lease_class        =   les_class.lease_class_code
        AND ctrct_hist.contract_header_id =   ctrct_head.contract_header_id
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--        AND ctrct_hist.contract_status    =   cv_ctrt_ctrt                            -- 契約
--        AND ctrct_hist.lease_kind         IN  (cv_lease_kind_fin, cv_lease_kind_lfin) -- Fin,旧Fin
--        AND ctrct_hist.lease_kind         =   les_kind.lease_kind_code
--        AND ctrct_hist.accounting_if_flag =   cv_if_yet                               -- 未送信
--        AND ctrct_head.first_payment_date <=  LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
---- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
--        AND obj_head.lease_class          =   flv.lookup_code
--        AND flv.lookup_type               =   cv_xxcff1_lease_class_check
--        AND flv.language                  =   USERENV('LANG')
--        AND flv.enabled_flag              =   cv_flg_y
--        AND LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
--                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
---- 2017/03/29 Ver.1.10 Y.Shoji ADD End
        AND ctrct_hist.accounting_if_flag =  cv_if_yet                                -- 未送信
        AND ctrct_head.first_payment_date <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
        AND obj_head.lease_class          =  flv.lookup_code
        AND flv.lookup_type               =  cv_xxcff1_lease_class_check
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
        AND flv.attribute7                = gv_lease_class_att7                       -- リース判定処理
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Emd
        AND flv.language                  =  USERENV('LANG')
        AND flv.enabled_flag              =  cv_flg_y
        AND LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--        AND ctrct_hist.lease_kind         =  les_kind.lease_kind_code
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
        AND (  (ctrct_hist.contract_status  =  cv_ctrt_ctrt                               -- 契約
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--            AND ctrct_hist.lease_kind       IN (cv_lease_kind_fin, cv_lease_kind_lfin)) -- Fin,旧Fin
            AND ctrct_hist.lease_kind       = gv_lease_kind)                            -- リース種類
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
          OR  ( ctrct_hist.contract_status  =  cv_ctrt_re_lease                         -- 再リース
            AND flv.attribute7              =  cv_lease_cls_chk2 ))                     -- リース判定結果：'2'
-- 2018/03/29 Ver1.11 Otsuka MOD End
        FOR UPDATE OF ctrct_hist.contract_header_id
        NOWAIT
      ;
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
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN les_trn_add_cur;
    -- データの一括取得
    FETCH les_trn_add_cur
    BULK COLLECT INTO  g_contract_header_id_tab -- 契約内部ID
                      ,g_contract_line_id_tab   -- 契約明細内部ID
                      ,g_object_header_id_tab   -- 物件内部ID
                      ,g_history_num_tab        -- 変更履歴No
                      ,g_lease_class_tab        -- リース種別
                      ,g_lease_kind_tab         -- リース種類
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--                      ,g_book_type_code_tab     -- 資産台帳名
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
                      ,g_asset_category_tab     -- 資産種類
                      ,g_comments_tab           -- 件名
                      ,g_payment_years_tab      -- 年数(リース期間)
                      ,g_life_in_months_tab     -- 法定耐用年数
                      ,g_contract_date_tab      -- リース契約日
                      ,g_original_cost_tab      -- 取得価格
                      ,g_quantity_tab           -- 数量
                      ,g_department_code_tab    -- 管理部門
                      ,g_owner_company_tab      -- 本社工場区分
                      ,g_les_asset_acct_tab     -- 資産勘定
                      ,g_deprn_acct_tab         -- 減価償却勘定
                      ,g_deprn_sub_acct_tab     -- 減価償却補助勘定
                      ,g_payment_frequency_tab  -- 支払回数
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
                      ,g_customer_code_tab      -- 顧客コード
                      ,g_vd_cust_flag_tab       -- VD顧客フラグ
                      ,g_dept_tran_flg_tab      -- 部門振替フラグ
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
                      ,g_category_ccid_tab      -- 資産カテゴリCCID
                      ,g_location_ccid_tab      -- 事業所CCID
                      ,g_deprn_ccid_tab         -- 減価償却費勘定CCID
                      ,g_deprn_method_tab       -- 減価償却方法
-- 2018/03/29 Ver1.11 Otsuka ADD Start
                      ,g_lease_type_tab         -- リース区分
                      ,g_payment_type_tab       -- 頻度(0:「月」、1:「年」）
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--                      ,g_fin_coop_tab           -- 日本基準連携
--                      ,g_ifrs_coop_tab          -- IFRS連携
--                      ,g_lease_cls_chk_tab      -- リース判別結果
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End

    ;
    --対象件数カウント
    gn_les_add_target_cnt := g_contract_header_id_tab.COUNT;
    -- カーソルクローズ
    CLOSE les_trn_add_cur;
--
    IF ( gn_les_add_target_cnt = 0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_013a20_t_031) -- リース取引（追加）情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      -- カーソルクローズ
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_013a20_m_012  -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,cv_msg_013a20_t_023) -- リース契約明細履歴
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_les_trn_add_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : 会計期間チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- プログラム名
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
    -- 資産台帳名
    lv_book_type_code VARCHAR(100);
--
    -- *** ローカル・カーソル ***
    CURSOR period_cur
    IS
      SELECT
             fdp.deprn_run        AS deprn_run      -- 減価償却実行フラグ
            ,fdp.book_type_code   AS book_type_code -- 資産台帳名
        FROM
             fa_deprn_periods     fdp   -- 減価償却期間
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--            ,xxcff_lease_kind_v   xlk   -- リース種類ビュー
--       WHERE
--             xlk.lease_kind_code IN (cv_lease_kind_fin, cv_lease_kind_lfin)
---- 2018/03/29 Ver1.11 Otsuka MOD Start
----         AND fdp.book_type_code  =  xlk.book_type_code
--         AND (fdp.book_type_code  =  xlk.book_type_code
--          OR  fdp.book_type_code  =  xlk.book_type_code_ifrs )
---- 2018/03/29 Ver1.11 Otsuka MOD Start
         WHERE
             fdp.book_type_code  =  gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
         AND fdp.period_name     =  gv_period_name
           ;
--
    -- *** ローカル・レコード ***
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
    -- カーソルオープン
    OPEN period_cur;
    -- データの一括取得
    FETCH period_cur
    BULK COLLECT INTO  g_deprn_run_tab      -- 減価償却実行フラグ
                      ,g_book_type_code_tab -- 資産台帳名
    ;
    -- カーソルクローズ
    CLOSE period_cur;
--
    -- 会計期間の取得件数がゼロ件⇒エラー
    IF g_deprn_run_tab.COUNT = 0 THEN
      RAISE chk_period_expt;
    END IF;
--
    <<chk_period_loop>>
    FOR ln_loop_cnt IN 1 .. g_deprn_run_tab.COUNT LOOP
--
      -- 減価償却が実行されている⇒エラー
      IF g_deprn_run_tab(ln_loop_cnt) = 'Y' THEN
        lv_book_type_code := g_book_type_code_tab(ln_loop_cnt);
        RAISE chk_period_expt;
      END IF;
--
    END LOOP chk_period_loop;
--
  EXCEPTION
--
    -- *** 会計期間チェックエラーハンドラ ***
    WHEN chk_period_expt THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_011  -- 会計期間チェックエラー
                                                    ,cv_tkn_bk_type       -- トークン'BOOK_TYPE_CODE'
                                                    ,lv_book_type_code    -- 資産台帳名
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- プログラム名
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
    -- XXCFF:会社コード_本社
    gv_comp_cd_itoen := FND_PROFILE.VALUE(cv_comp_cd_itoen);
    IF (gv_comp_cd_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_010) -- XXCFF:会社コード_本社
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:会社コード_相良会計
    gv_comp_cd_sagara := FND_PROFILE.VALUE(cv_comp_cd_sagara);
    IF (gv_comp_cd_sagara IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_011) -- XXCFF:会社コード_相良会計
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:部門コード_調整部門
    gv_dep_cd_chosei := FND_PROFILE.VALUE(cv_dep_cd_chosei);
    IF (gv_dep_cd_chosei IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_012) -- XXCFF:部門コード_調整部門
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:顧客コード_定義なし
    gv_ptnr_cd_dammy := FND_PROFILE.VALUE(cv_ptnr_cd_dammy);
    IF (gv_ptnr_cd_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_013) -- XXCFF:顧客コード_定義なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:企業コード_定義なし
    gv_busi_cd_dammy := FND_PROFILE.VALUE(cv_busi_cd_dammy);
    IF (gv_busi_cd_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_014) -- XXCFF:企業コード_定義なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:予備1コード_定義なし
    gv_project_dammy := FND_PROFILE.VALUE(cv_project_dammy);
    IF (gv_project_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_015) -- XXCFF:予備1コード_定義なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:予備2コード_定義なし
    gv_future_dammy := FND_PROFILE.VALUE(cv_future_dammy);
    IF (gv_future_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_016) -- XXCFF:予備2コード_定義なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:資産カテゴリ_償却方法
    gv_cat_dprn_lease := FND_PROFILE.VALUE(cv_cat_dprn_lease);
    IF (gv_cat_dprn_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_017) -- XXCFF:資産カテゴリ_償却方法
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:申告地_申告なし
    gv_dclr_place_no_report := FND_PROFILE.VALUE(cv_dclr_place_no_report);
    IF (gv_dclr_place_no_report IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_018) -- XXCFF:申告地_申告なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:事業所_申告なし
    gv_mng_place_dammy := FND_PROFILE.VALUE(cv_mng_place_dammy);
    IF (gv_mng_place_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_019) -- XXCFF:事業所_申告なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:場所_申告なし
    gv_place_dammy := FND_PROFILE.VALUE(cv_place_dammy);
    IF (gv_place_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_020) -- XXCFF:場所_申告なし
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:按分方法_月初
    gv_prt_conv_cd_st := FND_PROFILE.VALUE(cv_prt_conv_cd_st);
    IF (gv_prt_conv_cd_st IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_021) -- XXCFF:按分方法_月初
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:按分方法_月末
    gv_prt_conv_cd_ed := FND_PROFILE.VALUE(cv_prt_conv_cd_ed);
    IF (gv_prt_conv_cd_ed IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_022) -- XXCFF:按分方法_月末
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:本社工場区分_本社
    gv_own_comp_itoen := FND_PROFILE.VALUE(cv_own_comp_itoen);
    IF (gv_own_comp_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_024) -- XXCFF:本社工場区分_本社
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:本社工場区分_工場
    gv_own_comp_sagara := FND_PROFILE.VALUE(cv_own_comp_sagara);
    IF (gv_own_comp_sagara IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_025) -- XXCFF:本社工場区分_工場
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2018/03/29 Ver1.11 Otsuka ADD Start
    -- XXCFF:台帳名_FINリース台帳
    gv_fin_lease_books := FND_PROFILE.VALUE(cv_fin_lease_books);
    IF (gv_fin_lease_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_035) -- XXCFF:台帳名_FINリース台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:台帳名_IFRSリース台帳
    gv_ifrs_lease_books := FND_PROFILE.VALUE(cv_ifrs_lease_books);
    IF (gv_ifrs_lease_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_036) -- XXCFF:台帳名_IFRSリース台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2018/03/29 Ver1.11 Otsuka ADD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    -- XXCFF:IFRS帳簿ID
    gn_set_of_books_id_ifrs := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_books_id_ifrs));
    IF (gn_set_of_books_id_ifrs IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_037) -- XXCFF:IFRS帳簿ID
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- IFRSリース台帳の場合
    IF ( gv_book_type_code = gv_ifrs_lease_books ) THEN
      -- リース判定処理=2
      gv_lease_class_att7 := cv_lease_cls_chk2;
      -- リース種類=Finリース
      gv_lease_kind := cv_lease_kind_fin;
    -- FINリース台帳の場合
    ELSIF ( gv_book_type_code = gv_fin_lease_books ) THEN
      -- リース判定処理=1
      gv_lease_class_att7 := cv_lease_cls_chk1;
      -- リース種類=Finリース
      gv_lease_kind := cv_lease_kind_fin;
    -- 上記以外の場合
    ELSE
      -- リース判定処理=1
      gv_lease_class_att7 := cv_lease_cls_chk1;
      -- リース種類=Opリース
      gv_lease_kind := cv_lease_kind_lfin;
    END IF;
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_profile_values;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    -- 初期値情報の取得
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- 初期値情報
      ,ov_errbuf   => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(出力の表示)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(ログ)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.会計期間名
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    iv_book_type_code IN VARCHAR2,    -- 2.台帳名
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
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
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    gn_target_cnt            := 0;
    gn_normal_cnt            := 0;
    gn_error_cnt             := 0;
    gn_warn_cnt              := 0;
    gn_les_add_target_cnt    := 0;
    gn_les_add_normal_cnt    := 0;
    gn_les_add_error_cnt     := 0;
    gn_les_trnsf_target_cnt  := 0;
    gn_les_trnsf_normal_cnt  := 0;
    gn_les_trnsf_error_cnt   := 0;
    gn_les_retire_target_cnt := 0;
    gn_les_retire_normal_cnt := 0;
    gn_les_retire_error_cnt  := 0;
    gn_fa_oif_target_cnt     := 0;
    gn_fa_oif_error_cnt      := 0;
    gn_add_oif_ins_cnt       := 0;
    gn_trnsf_oif_ins_cnt     := 0;
    gn_retire_oif_ins_cnt    := 0;
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    gn_les_add_ifrs_cnt      := 0;
--    gn_les_trnsf_ifrs_cnt    := 0;
--    gn_les_retire_ifrs_cnt   := 0;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- INパラメータ(会計期間名)をグローバル変数に設定
    gv_period_name := iv_period_name;
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    -- INパラメータ(台帳名)をグローバル変数に設定
    gv_book_type_code := iv_book_type_code;
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- プロファイル値取得 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 会計期間チェック (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD Start
--
    -- ==============================================
    -- リース月次締め期間更新 (A-27)
    -- ==============================================
    update_lease_close_period(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD End
--
    -- =========================================
    -- リース取引(追加)登録データ抽出 (A-4)
    -- =========================================
    get_les_trn_add_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- リース取引(追加)データ処理 (A-5)～(A-10)
    -- =========================================
    proc_les_trn_add_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- リース取引(振替)登録データ抽出 (A-11)
    -- =========================================
    get_les_trn_trnsf_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- リース取引(振替)データ処理 (A-12)～(A-16)
    -- =========================================
    proc_les_trn_trnsf_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- リース取引(解約)登録データ抽出 (A-17)
    -- =========================================
    get_les_trn_retire_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- リース取引(解約)登録 (A-18)
    -- =========================================
    insert_les_trn_ritire_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- リース契約明細履歴 会計IFフラグ更新 (A-19)
    -- ==============================================
    update_ritire_data_acct_flag(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- FAOIF登録データ抽出 (A-20)
    -- =========================================
    get_les_trns_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 追加OIF登録 (A-21)
    -- =========================================
    insert_add_oif(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 振替OIF登録 (A-22)
    -- =========================================
    insert_trnsf_oif(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 除・売却OIF登録 (A-23)
    -- =========================================
    insert_retire_oif(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- リース取引 FA連携フラグ更新 (A-24)
    -- ==============================================
    update_les_trns_fa_if_flag(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--    iv_period_name IN  VARCHAR2       -- 1.会計期間名
    iv_period_name    IN  VARCHAR2,   -- 1.会計期間名
    iv_book_type_code IN  VARCHAR2    -- 2.台帳名
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
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
       iv_period_name    -- 1.会計期間名
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
      ,iv_book_type_code -- 2.台帳名
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --エラー時の出力件数設定
    --===============================================================
    IF (lv_retcode <> cv_status_normal) THEN
      -- 成功件数をゼロにクリアする
      gn_les_add_normal_cnt    := 0;
      gn_les_trnsf_normal_cnt  := 0;
      gn_les_retire_normal_cnt := 0;
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--      gn_les_add_ifrs_cnt      := 0;
--      gn_les_trnsf_ifrs_cnt    := 0;
--      gn_les_retire_ifrs_cnt   := 0;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
      gn_add_oif_ins_cnt       := 0;
      gn_trnsf_oif_ins_cnt     := 0;
      gn_retire_oif_ins_cnt    := 0;
      -- エラー件数に対象件数を設定する
      gn_les_add_error_cnt    := gn_les_add_target_cnt;
      gn_les_trnsf_error_cnt  := gn_les_trnsf_target_cnt;
      gn_les_retire_error_cnt := gn_les_retire_target_cnt;
      gn_fa_oif_error_cnt     := gn_fa_oif_target_cnt;
    END IF;
--
    --===============================================================
    --リース取引(追加)登録処理における件数出力
    --===============================================================
    --リース取引(追加)作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_014
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_add_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_021
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2018/03/29 Ver1.11 Otsuka MOD End
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_add_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    --
--    --成功件数出力(IFRS)
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_022
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_les_add_ifrs_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_add_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --===============================================================
    --リース取引(振替)登録処理における件数出力
    --===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --リース取引(振替)作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_015
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_023
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2018/03/29 Ver1.11 Otsuka MOD End
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    --
--    --成功件数出力(IFRS)
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_024
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_ifrs_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --リース取引(解約)登録処理における件数出力
    --===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --リース取引(解約)作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_016
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_retire_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_025
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2018/03/29 Ver1.11 Otsuka MOD End
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_retire_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    --
--    --成功件数出力(IFRS)
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_026
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_les_retire_ifrs_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_retire_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --FAOIF登録処理における件数出力
    --===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --FAOIF作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_017
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_fa_oif_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_add_oif_ins_cnt + gn_trnsf_oif_ins_cnt + gn_retire_oif_ins_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_fa_oif_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
END XXCFF013A20C;
/
